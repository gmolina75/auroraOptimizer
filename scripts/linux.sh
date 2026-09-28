#!/bin/bash
# ============================================
# Aurora Optimizer - Script para Linux
# ============================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Rutas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/config/aurora.conf"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/aurora-$(date +%Y%m%d-%H%M%S).log"

# Cargar configuración
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Error: No se encontró el archivo de configuración"
    exit 1
fi

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Función de logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Detectar tipo de disco
detect_disk_type() {
    local disk="$1"
    if [[ -d /sys/block/$(basename "$disk")/queue/rotational ]]; then
        local rotational=$(cat /sys/block/$(basename "$disk")/queue/rotational 2>/dev/null || echo "1")
        if [[ "$rotational" == "0" ]]; then
            echo "SSD"
        else
            echo "HDD"
        fi
    else
        echo "UNKNOWN"
    fi
}

# Limpiar memoria y cachés
clean_memory() {
    log "INFO" "Iniciando limpieza de memoria..."

    # Mostrar memoria antes
    local mem_before=$(free -m | awk '/^Mem:/{print $3}')
    log "INFO" "Memoria en uso antes: ${mem_before}MB"

    # Limpiar caché de página
    sync
    if [[ $EUID -eq 0 ]]; then
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        echo 2 > /proc/sys/vm/drop_caches 2>/dev/null || true
    else
        log "WARN" "No se pudo limpiar caché de página (requiere root)"
    fi

    # Mostrar memoria después
    local mem_after=$(free -m | awk '/^Mem:/{print $3}')
    log "INFO" "Memoria en uso después: ${mem_after}MB"
    log "INFO" "Memoria liberada: $((mem_before - mem_after))MB"
}

# Limpiar archivos temporales
clean_temp_files() {
    log "INFO" "Iniciando limpieza de archivos temporales..."

    local dirs_to_clean=("/tmp" "/var/tmp" "$HOME/.cache" "$HOME/Descargas/.tmp")
    local total_freed=0

    for dir in "${dirs_to_clean[@]}"; do
        if [[ -d "$dir" ]]; then
            local size_before=$(du -sm "$dir" 2>/dev/null | cut -f1)
            size_before=${size_before:-0}
            find "$dir" -type f -mtime +${TEMP_FILE_AGE_DAYS:-7} -delete 2>/dev/null || true
            find "$dir" -type d -empty -delete 2>/dev/null || true
            local size_after=$(du -sm "$dir" 2>/dev/null | cut -f1)
            size_after=${size_after:-0}
            local freed=$((size_before - size_after))
            total_freed=$((total_freed + freed))
            log "INFO" "Limpiado $dir: ${freed}MB liberados"
        fi
    done

    log "INFO" "Total liberado: ${total_freed}MB"
}

# Defragmentar HDD (nunca SSD)
defragment_disk() {
    local disk="$1"
    local disk_type=$(detect_disk_type "$disk")

    if [[ "$disk_type" == "SSD" ]]; then
        log "INFO" "Disco $disk es SSD - NO se defragmenta (reduciría su vida útil)"
        return 0
    fi

    if [[ "$disk_type" == "HDD" ]]; then
        log "INFO" "Disco $disk es HDD - Verificando fragmentación..."

        # Verificar si e4defrag está disponible (para ext4)
        if command -v e4defrag &> /dev/null; then
            local frag_percent=$(e4defrag -c "$disk" 2>/dev/null | grep -oP 'Fragmentation score: \K\d+' || echo "0")
            if [[ "$frag_percent" -gt 10 ]]; then
                log "INFO" "Fragmentación: ${frag_percent}% - Defragmentando..."
                e4defrag "$disk" 2>/dev/null || log "WARN" "No se pudo defragmentar $disk"
            else
                log "INFO" "Fragmentación: ${frag_percent}% - No requiere defragmentación"
            fi
        else
            log "WARN" "e4defrag no disponible - Instalar e2fsprogs"
        fi
    fi
}

# Verificar espacio en disco
check_disk_space() {
    log "INFO" "Verificando espacio en disco..."

    df -h | grep -E '^/dev/' | while read line; do
        local usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        local mount=$(echo "$line" | awk '{print $6}')
        local device=$(echo "$line" | awk '{print $1}')

        if [[ "$usage" -gt "${DISK_ALERT_THRESHOLD:-85}" ]]; then
            log "WARN" "⚠️  $mount ($device): ${usage}% usado - ¡Espacio bajo!"
        else
            log "INFO" "✓ $mount ($device): ${usage}% usado"
        fi
    done
}

# Limpiar logs antiguos
clean_old_logs() {
    log "INFO" "Limpiando logs antiguos..."
    find "$LOG_DIR" -name "*.log" -type f | sort -r | tail -n +$((MAX_LOG_FILES + 1)) | xargs rm -f 2>/dev/null || true
}

# Notificación del sistema
send_notification() {
    local title="$1"
    local message="$2"

    if [[ "${NOTIFICATIONS:-true}" == "true" ]]; then
        if command -v notify-send &> /dev/null; then
            notify-send "$title" "$message" 2>/dev/null || true
        fi
    fi
}

# ============================================
# GENERAR ESTADÍSTICAS
# ============================================
generate_stats() {
    if [[ "${STATS_ENABLED:-true}" != "true" ]]; then
        return 0
    fi

    log "INFO" "Generando estadísticas..."

    local stats_file="${STATS_FILE:-$LOG_DIR/stats.json}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local mem_total=$(free -m | awk '/^Mem:/{print $2}')
    local mem_used=$(free -m | awk '/^Mem:/{print $3}')
    local disk_total=$(df -m / | awk 'NR==2{print $2}')
    local disk_used=$(df -m / | awk 'NR==2{print $3}')
    local cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')

    # Crear directorio si no existe
    mkdir -p "$(dirname "$stats_file")"

    # Crear JSON de estadísticas
    echo "{\"timestamp\":\"$timestamp\",\"memory\":{\"total\":$mem_total,\"used\":$mem_used},\"disk\":{\"total\":$disk_total,\"used\":$disk_used},\"cpu\":\"$cpu_usage\"}" >> "$stats_file"

    log "INFO" "Estadísticas guardadas en $stats_file"
}

# ============================================
# CREAR BACKUP
# ============================================
create_backup() {
    if [[ "${BACKUP_ENABLED:-true}" != "true" ]]; then
        return 0
    fi

    log "INFO" "Creando backup..."

    local backup_dir="${BACKUP_DIR:-$PROJECT_DIR/backups}"
    mkdir -p "$backup_dir"

    local backup_file="$backup_dir/backup-$(date +%Y%m%d-%H%M%S).tar.gz"

    # Backup de configuración
    if [[ "${BACKUP_CONFIG:-true}" == "true" ]]; then
        tar -czf "$backup_file" -C "$PROJECT_DIR" config/ 2>/dev/null || true
        log "INFO" "Backup creado: $backup_file"
    fi

    # Limpiar backups antiguos
    find "$backup_dir" -name "backup-*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS:-30} -delete 2>/dev/null || true
}

# ============================================
# VERIFICAR ALERTAS POR UMBRALES
# ============================================
check_alerts() {
    if [[ "${ALERT_THRESHOLDS:-true}" != "true" ]]; then
        return 0
    fi

    log "INFO" "Verificando alertas por umbrales..."

    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if [[ "${cpu_usage%.*}" -gt "${ALERT_CPU_THRESHOLD:-90}" ]]; then
        log "WARN" "⚠️  ALERTA: Uso de CPU alto: ${cpu_usage}%"
    fi

    # Memoria
    local mem_usage=$(free | awk '/^Mem:/{printf "%.0f", $3/$2*100}')
    if [[ "$mem_usage" -gt "${ALERT_MEMORY_THRESHOLD:-90}" ]]; then
        log "WARN" "⚠️  ALERTA: Uso de memoria alto: ${mem_usage}%"
    fi

    # Disco
    local disk_usage=$(df / | awk 'NR==2{print $5}' | tr -d '%')
    if [[ "$disk_usage" -gt "${ALERT_DISK_THRESHOLD:-85}" ]]; then
        log "WARN" "⚠️  ALERTA: Espacio en disco bajo: ${disk_usage}%"
    fi
}

# ============================================
# EJECUCIÓN PRINCIPAL
# ============================================

# stats: generación de estadísticas
# backup: creación de backups
# alert: verificación de alertas por umbrales

main() {
    log "INFO" "=========================================="
    log "INFO" "Aurora Optimizer - Iniciando optimización"
    log "INFO" "Fecha: $(date)"
    log "INFO" "Usuario: $(whoami)"
    log "INFO" "=========================================="

    # Enviar notificación de reinicio
    if [[ "${NOTIFICATIONS:-true}" == "true" ]]; then
        bash "$SCRIPT_DIR/notifications.sh" --reboot 2>/dev/null || true
    fi

    # Verificar si se ejecuta como root para ciertas operaciones
    if [[ $EUID -ne 0 ]]; then
        log "WARN" "Ejecutando como usuario normal - algunas operaciones requerirán root"
    fi

    # 1. Verificar espacio en disco
    check_disk_space

    # 2. Limpiar memoria
    if [[ "${CLEAN_MEMORY:-true}" == "true" ]]; then
        clean_memory
    fi

    # 3. Limpiar archivos temporales
    if [[ "${CLEAN_TEMP:-true}" == "true" ]]; then
        clean_temp_files
    fi

    # 4. Defragmentar si aplica
    if [[ "${DEFRAG_HDD:-true}" == "true" ]]; then
        for disk in /dev/sda1 /dev/nvme0n1p1 /dev/mmcblk0p1; do
            if [[ -b "$disk" ]]; then
                defragment_disk "$disk"
            fi
        done
    fi

    # 5. Limpiar logs antiguos
    clean_old_logs

    # Generar estadísticas
    generate_stats

    # Crear backup
    create_backup

    # Verificar alertas por umbrales
    check_alerts

    log "INFO" "=========================================="
    log "INFO" "Optimización completada exitosamente"
    log "INFO" "=========================================="

    send_notification "Aurora Optimizer" "Optimización del sistema completada"
}

# Ejecutar
main "$@"
