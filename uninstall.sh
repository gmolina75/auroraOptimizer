#!/bin/bash
# ============================================
# Aurora Optimizer - Desinstalador
# ============================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║      Aurora Optimizer - Desinstalador    ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Detectar sistema operativo
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "macOS";;
        CYGWIN*|MINGW*|MSYS*) echo "Windows";;
        *)          echo "UNKNOWN";;
    esac
}

OS=$(detect_os)
echo -e "${GREEN}✓ Sistema operativo detectado: $OS${NC}"

# ============================================
# DESINSTALACIÓN PARA LINUX
# ============================================
uninstall_linux() {
    echo -e "\n${BLUE}Desinstalando de Linux...${NC}"

    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}⚠ Se requieren permisos de root${NC}"
        return 1
    fi

    # Detener y deshabilitar timer
    systemctl stop aurora-optimizer.timer 2>/dev/null || true
    systemctl disable aurora-optimizer.timer 2>/dev/null || true

    # Eliminar archivos de systemd
    rm -f /etc/systemd/system/aurora-optimizer.service
    rm -f /etc/systemd/system/aurora-optimizer.timer

    systemctl daemon-reload

    echo -e "${GREEN}✓ Servicio systemd eliminado${NC}"
}

# ============================================
# DESINSTALACIÓN PARA MACOS
# ============================================
uninstall_macos() {
    echo -e "\n${BLUE}Desinstalando de macOS...${NC}"

    LAUNCH_AGENT_FILE="$HOME/Library/LaunchAgents/com.aurora.optimizer.plist"

    # Descargar LaunchAgent
    launchctl unload "$LAUNCH_AGENT_FILE" 2>/dev/null || true
    rm -f "$LAUNCH_AGENT_FILE"

    echo -e "${GREEN}✓ LaunchAgent eliminado${NC}"
}

# ============================================
# DESINSTALACIÓN PARA WINDOWS
# ============================================
uninstall_windows() {
    echo -e "\n${BLUE}Desinstalando de Windows...${NC}"

    # Eliminar tarea programada
    schtasks /Delete /TN "AuroraOptimizer" /F 2>/dev/null || true

    echo -e "${GREEN}✓ Tarea programada eliminada${NC}"
}

# ============================================
# DESINSTALACIÓN PRINCIPAL
# ============================================

case "$OS" in
    Linux)
        uninstall_linux
        ;;
    macOS)
        uninstall_macos
        ;;
    Windows)
        uninstall_windows
        ;;
    *)
        echo -e "${RED}✗ Sistema operativo no soportado: $OS${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}╔══════════════════════════════════════════╗"
echo -e "║    ¡Desinstalación completada! ✅        ║"
echo -e "╚══════════════════════════════════════════╝${NC}"
