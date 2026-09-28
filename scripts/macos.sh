#!/bin/bash
# ============================================
# Aurora Optimizer - Script para macOS
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

# Limpiar memoria
clean_memory() {
    log "INFO" "Iniciando limpieza de memoria..."

    # Mostrar memoria antes
    local mem_before=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
    log "INFO" "Memoria activa antes: ${mem_before} páginas"

    # Limpiar caché de disco
    sync

    # Purgar memoria inactiva
    purge 2>/dev/null || log "WARN" "No se pudo purgar memoria (requiere permisos)"

    # Mostrar memoria después
    local mem_after=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
    log "INFO" "Memoria activa después: ${mem_after} páginas"
    log "INFO" "Limpieza de memoria completada"
}

# Limpiar archivos temporales
clean_temp_files() {
    log "INFO" "Iniciando limpieza de archivos temporales..."

    local dirs_to_clean=("/tmp" "/var/tmp" "$HOME/Library/Caches" "$HOME/Downloads/.tmp")
    local total_freed=0

    for dir in "${dirs_to_clean[@]}"; do
        if [[ -d "$dir" ]]; then
            local size_before=$(du -sm "$dir" 2>/dev/null | cut -f1 || echo "0")
            find "$dir" -type f -mtime +${TEMP_FILE_AGE_DAYS:-7} -delete 2>/dev/null || true
            find "$dir" -type d -empty -delete 2>/dev/null || true
            local size_after=$(du -sm "$dir" 2>/dev/null | cut -f1 || echo "0")
            local freed=$((size_before - size_after))
            total_freed=$((total_freed + freed))
            log "INFO" "Limpiado $dir: ${freed}MB liberados"
        fi
    done

    # Limpiar cachés de usuario
    log "INFO" "Limpiando cachés de usuario..."
    rm -rf "$HOME/Library/Caches/"* 2>/dev/null || true

    log "INFO" "Total liberado: ${total_freed}MB"
}

# Verificar espacio en disco
check_disk_space() {
    log "INFO" "Verificando espacio en disco..."

    df -h | grep -E '^/dev/' | while read line; do
        local usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        local mount=$(echo "$line" | awk '{print $9}')
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
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
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
    local mem_total=$(vm_stat | awk '/Pages free/ {print $3}' | tr -d '.')
    local disk_total=$(df -m / | awk 'NR==2{print $2}')
    local disk_used=$(df -m / | awk 'NR==2{print $3}')
    local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}')

    # Crear JSON de estadísticas
    cat >> "$stats_file" << EOF
{"timestamp":"$timestamp","memory":{"total":$mem_total,"used":0},"disk":{"total":$disk_total,"used":$disk_used},"cpu":"$cpu_usage"}
EOF

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
    local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
    if [[ "${cpu_usage%.*}" -gt "${ALERT_CPU_THRESHOLD:-90}" ]]; then
        log "WARN" "⚠️  ALERTA: Uso de CPU alto: ${cpu_usage}%"
    fi

    # Memoria
    local mem_usage=$(memory_pressure | awk '/System-wide memory free percentage/ {print $5}' | tr -d '%')
    if [[ "${mem_usage%.*}" -gt "${ALERT_MEMORY_THRESHOLD:-90}" ]]; then
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
    log "INFO" "Sistema: $(sw_vers -productName) $(sw_vers -productVersion)"
    log "INFO" "=========================================="

    # Enviar notificación de reinicio
    if [[ "${NOTIFICATIONS:-true}" == "true" ]]; then
        bash "$SCRIPT_DIR/notifications.sh" --reboot 2>/dev/null || true
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

    # 4. Limpiar logs antiguos
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
