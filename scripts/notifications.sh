#!/bin/bash
# ============================================
# Aurora Optimizer - Sistema de Notificaciones
# ============================================

set -euo pipefail

# Rutas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/config/aurora.conf"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/notifications-$(date +%Y%m%d-%H%M%S).log"

# Cargar configuración
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Error: No se encontró el archivo de configuración"
    exit 1
fi

mkdir -p "$LOG_DIR"

# Función de logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Obtener información del sistema
get_system_info() {
    local hostname=$(hostname)
    local os_info=""
    local uptime_info=""

    case "$(uname -s)" in
        Linux*)
            os_info=$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
            uptime_info=$(uptime -p 2>/dev/null || uptime)
            ;;
        Darwin*)
            os_info="macOS $(sw_vers -productVersion)"
            uptime_info=$(uptime)
            ;;
        CYGWIN*|MINGW*|MSYS*)
            os_info="Windows"
            uptime_info=$(uptime)
            ;;
    esac

    echo "HOSTNAME:$hostname"
    echo "OS:$os_info"
    echo "UPTIME:$uptime_info"
    echo "DATE:$(date '+%Y-%m-%d %H:%M:%S')"
}

# ============================================
# NOTIFICACIÓN POR CORREO ELECTRÓNICO
# ============================================
send_email() {
    local subject="$1"
    local body="$2"

    if [[ "${EMAIL_ENABLED:-false}" != "true" ]]; then
        log "INFO" "Notificaciones por correo deshabilitadas"
        return 0
    fi

    log "INFO" "Enviando notificación por correo..."

    # Verificar dependencias
    if ! command -v sendmail &> /dev/null && ! command -v msmtp &> /dev/null && ! command -v curl &> /dev/null; then
        log "WARN" "No se encontró sendmail, msmtp o curl. Instalando..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y msmtp-mta 2>/dev/null || true
        elif command -v yum &> /dev/null; then
            sudo yum install -y msmtp 2>/dev/null || true
        fi
    fi

    # Método 1: Usando curl con SMTP
    if command -v curl &> /dev/null; then
        local email_content="From: ${EMAIL_FROM}
To: ${EMAIL_TO}
Subject: ${subject}
Content-Type: text/plain; charset=UTF-8

${body}"

        curl -s --url "smtps://${EMAIL_SMTP_SERVER}:${EMAIL_SMTP_PORT}" \
            --ssl-reqd \
            --mail-from "${EMAIL_FROM}" \
            --mail-rcpt "${EMAIL_TO}" \
            --user "${EMAIL_USERNAME}:${EMAIL_PASSWORD}" \
            --upload-file - <<< "$email_content" 2>/dev/null

        if [[ $? -eq 0 ]]; then
            log "INFO" "✓ Correo enviado exitosamente"
            return 0
        else
            log "WARN" "No se pudo enviar el correo con curl"
        fi
    fi

    # Método 2: Usando sendmail
    if command -v sendmail &> /dev/null; then
        echo -e "Subject: ${subject}\n\n${body}" | sendmail "${EMAIL_TO}"
        log "INFO" "✓ Correo enviado con sendmail"
        return 0
    fi

    # Método 3: Usando msmtp
    if command -v msmtp &> /dev/null; then
        echo -e "Subject: ${subject}\n\n${body}" | msmtp "${EMAIL_TO}"
        log "INFO" "✓ Correo enviado con msmtp"
        return 0
    fi

    log "WARN" "No se pudo enviar el correo - verifica la configuración"
    return 1
}

# ============================================
# NOTIFICACIÓN POR TELEGRAM
# ============================================
send_telegram() {
    local message="$1"

    if [[ "${TELEGRAM_ENABLED:-false}" != "true" ]]; then
        log "INFO" "Notificaciones por Telegram deshabilitadas"
        return 0
    fi

    log "INFO" "Enviando notificación por Telegram..."

    if ! command -v curl &> /dev/null; then
        log "WARN" "curl no está disponible para enviar mensajes de Telegram"
        return 1
    fi

    local url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    local payload="chat_id=${TELEGRAM_CHAT_ID}&text=${message}&parse_mode=HTML"

    local response=$(curl -s -X POST "$url" -d "$payload" 2>/dev/null)

    if echo "$response" | grep -q '"ok":true'; then
        log "INFO" "✓ Mensaje de Telegram enviado exitosamente"
        return 0
    else
        log "WARN" "No se pudo enviar el mensaje de Telegram: $response"
        return 1
    fi
}

# ============================================
# NOTIFICACIÓN POR SLACK
# ============================================
send_slack() {
    local message="$1"

    if [[ "${SLACK_ENABLED:-false}" != "true" ]]; then
        log "INFO" "Notificaciones por Slack deshabilitadas"
        return 0
    fi

    log "INFO" "Enviando notificación por Slack..."

    if ! command -v curl &> /dev/null; then
        log "WARN" "curl no está disponible para enviar mensajes de Slack"
        return 1
    fi

    local payload="{\"channel\":\"${SLACK_CHANNEL}\",\"text\":\"${message}\"}"

    local response=$(curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" "${SLACK_WEBHOOK_URL}" 2>/dev/null)

    if [[ "$response" == "ok" ]]; then
        log "INFO" "✓ Mensaje de Slack enviado exitosamente"
        return 0
    else
        log "WARN" "No se pudo enviar el mensaje de Slack: $response"
        return 1
    fi
}

# ============================================
# NOTIFICACIÓN POR DISCORD
# ============================================
send_discord() {
    local message="$1"

    if [[ "${DISCORD_ENABLED:-false}" != "true" ]]; then
        log "INFO" "Notificaciones por Discord deshabilitadas"
        return 0
    fi

    log "INFO" "Enviando notificación por Discord..."

    if ! command -v curl &> /dev/null; then
        log "WARN" "curl no está disponible para enviar mensajes de Discord"
        return 1
    fi

    local payload="{\"content\":\"${message}\"}"

    local response=$(curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" "${DISCORD_WEBHOOK_URL}" 2>/dev/null)

    if [[ -z "$response" ]] || [[ "$response" != *"message_id"* ]]; then
        log "INFO" "✓ Mensaje de Discord enviado exitosamente"
        return 0
    else
        log "WARN" "No se pudo enviar el mensaje de Discord: $response"
        return 1
    fi
}

# ============================================
# NOTIFICACIÓN POR PUSHOVER
# ============================================
send_pushover() {
    local message="$1"

    if [[ "${PUSHOVER_ENABLED:-false}" != "true" ]]; then
        log "INFO" "Notificaciones por Pushover deshabilitadas"
        return 0
    fi

    log "INFO" "Enviando notificación por Pushover..."

    if ! command -v curl &> /dev/null; then
        log "WARN" "curl no está disponible para enviar mensajes de Pushover"
        return 1
    fi

    local response=$(curl -s \
        --form-string "token=${PUSHOVER_APP_TOKEN}" \
        --form-string "user=${PUSHOVER_USER_KEY}" \
        --form-string "message=${message}" \
        "https://api.pushover.net/1/messages.json" 2>/dev/null)

    if echo "$response" | grep -q '"status":1'; then
        log "INFO" "✓ Mensaje de Pushover enviado exitosamente"
        return 0
    else
        log "WARN" "No se pudo enviar el mensaje de Pushover: $response"
        return 1
    fi
}

# ============================================
# NOTIFICACIÓN DE REINICIO
# ============================================
notify_reboot() {
    log "INFO" "=========================================="
    log "INFO" "Enviando notificación de reinicio..."
    log "INFO" "=========================================="

    local sys_info=$(get_system_info)
    local hostname=$(echo "$sys_info" | grep "HOSTNAME:" | cut -d':' -f2)
    local os_info=$(echo "$sys_info" | grep "OS:" | cut -d':' -f2)
    local uptime_info=$(echo "$sys_info" | grep "UPTIME:" | cut -d':' -f2)
    local date_info=$(echo "$sys_info" | grep "DATE:" | cut -d':' -f2)

    # Mensaje para correo
    local email_subject="🖥️ Aurora Optimizer - Equipo Reiniciado: $hostname"
    local email_body="El equipo ha sido reiniciado exitosamente.

📅 Fecha: $date_info
🖥️ Hostname: $hostname
💻 Sistema: $os_info
⏱️ Uptime: $uptime_info

La optimización del sistema se ha ejecutado automáticamente.

---
Enviado por Aurora Optimizer"

    # Mensaje para Telegram
    local telegram_message="🖥️ <b>Aurora Optimizer - Equipo Reiniciado</b>

📅 Fecha: $date_info
🖥️ Hostname: $hostname
💻 Sistema: $os_info
⏱️ Uptime: $uptime_info

✅ Optimización completada"

    # Enviar notificaciones
    send_email "$email_subject" "$email_body"
    send_telegram "$telegram_message"
    send_slack "$telegram_message"
    send_discord "$telegram_message"
    send_pushover "$telegram_message"

    log "INFO" "=========================================="
    log "INFO" "Notificaciones enviadas"
    log "INFO" "=========================================="
}

# ============================================
# NOTIFICACIÓN DE OPTIMIZACIÓN COMPLETADA
# ============================================
notify_optimization_complete() {
    local sys_info=$(get_system_info)
    local hostname=$(echo "$sys_info" | grep "HOSTNAME:" | cut -d':' -f2)
    local date_info=$(echo "$sys_info" | grep "DATE:" | cut -d':' -f2)

    local email_subject="✅ Aurora Optimizer - Optimización Completada: $hostname"
    local email_body="La optimización del sistema ha sido completada exitosamente.

📅 Fecha: $date_info
🖥️ Hostname: $hostname

---
Enviado por Aurora Optimizer"

    local telegram_message="✅ <b>Aurora Optimizer - Optimización Completada</b>

📅 Fecha: $date_info
🖥️ Hostname: $hostname"

    send_email "$email_subject" "$email_body"
    send_telegram "$telegram_message"
    send_slack "$telegram_message"
    send_discord "$telegram_message"
    send_pushover "$telegram_message"
}

# ============================================
# MODO DE PRUEBA
# ============================================
test_notifications() {
    log "INFO" "MODO DE PRUEBA - Enviando notificaciones de prueba..."

    local sys_info=$(get_system_info)
    local hostname=$(echo "$sys_info" | grep "HOSTNAME:" | cut -d':' -f2)

    local email_subject="🧪 Aurora Optimizer - Notificación de Prueba"
    local email_body="Esta es una notificación de prueba.

🖥️ Hostname: $hostname
📅 Fecha: $(date '+%Y-%m-%d %H:%M:%S')

Si recibes este correo, la configuración es correcta."

    local telegram_message="🧪 <b>Aurora Optimizer - Notificación de Prueba</b>

🖥️ Hostname: $hostname
📅 Fecha: $(date '+%Y-%m-%d %H:%M:%S')

Si recibes este mensaje, la configuración es correcta."

    send_email "$email_subject" "$email_body"
    send_telegram "$telegram_message"
    send_slack "$telegram_message"
    send_discord "$telegram_message"
    send_pushover "$telegram_message"
}

# ============================================
# EJECUCIÓN PRINCIPAL
# ============================================

case "${1:-}" in
    --reboot)
        notify_reboot
        ;;
    --optimization)
        notify_optimization_complete
        ;;
    --test)
        test_notifications
        ;;
    *)
        echo "Uso: $0 [--reboot|--optimization|--test]"
        echo ""
        echo "Opciones:"
        echo "  --reboot       Notificar reinicio del equipo"
        echo "  --optimization  Notificar optimización completada"
        echo "  --test         Enviar notificación de prueba"
        exit 1
        ;;
esac
