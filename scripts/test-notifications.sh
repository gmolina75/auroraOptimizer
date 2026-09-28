#!/bin/bash
# ============================================
# Aurora Optimizer - Script de Pruebas
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════════════════╗"
echo "║    Aurora Optimizer - Pruebas de        ║"
echo "║         Notificaciones                  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Verificar configuración
CONFIG_FILE="$PROJECT_DIR/config/aurora.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Error: No se encontró $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

echo "📋 Configuración actual:"
echo "   Correo: $([[ "${EMAIL_ENABLED:-false}" == "true" ]] && echo "✅ Habilitado" || echo "❌ Deshabilitado")"
echo "   Telegram: $([[ "${TELEGRAM_ENABLED:-false}" == "true" ]] && echo "✅ Habilitado" || echo "❌ Deshabilitado")"
echo ""

# Probar correo
if [[ "${EMAIL_ENABLED:-false}" == "true" ]]; then
    echo "📧 Probando notificación por correo..."
    bash "$SCRIPT_DIR/notifications.sh" --test
    echo ""
fi

# Probar Telegram
if [[ "${TELEGRAM_ENABLED:-false}" == "true" ]]; then
    echo "📱 Probando notificación por Telegram..."
    bash "$SCRIPT_DIR/notifications.sh" --test
    echo ""
fi

echo "✅ Pruebas completadas. Revisa tu correo y Telegram."
