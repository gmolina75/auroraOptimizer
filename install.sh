#!/bin/bash
# ============================================
# Aurora Optimizer - Instalador Multiplataforma
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
echo "║       Aurora Optimizer - Instalador      ║"
echo "║         Multiplataforma v1.0            ║"
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
# INSTALACIÓN PARA LINUX
# ============================================
install_linux() {
    echo -e "\n${BLUE}Iniciando instalación para Linux...${NC}"

    # Hacer scripts ejecutables
    chmod +x "$PROJECT_DIR/scripts/linux.sh"
    chmod +x "$PROJECT_DIR/uninstall.sh"

    # Crear servicio systemd
    SERVICE_FILE="/etc/systemd/system/aurora-optimizer.service"
    TIMER_FILE="/etc/systemd/system/aurora-optimizer.timer"

    # Verificar si se ejecuta como root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}⚠ Se requieren permisos de root para instalar el servicio systemd${NC}"
        echo -e "${YELLOW}  Ejecuta: sudo ./install.sh${NC}"
        return 1
    fi

    # Crear servicio systemd
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Aurora Optimizer - Optimización del sistema
After=network.target

[Service]
Type=oneshot
ExecStart=$PROJECT_DIR/scripts/linux.sh
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Crear timer para ejecutar al inicio
    cat > "$TIMER_FILE" << EOF
[Unit]
Description=Ejecutar Aurora Optimizer al inicio del sistema

[Timer]
OnBootSec=1min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
EOF

    # Recargar systemd y habilitar timer
    systemctl daemon-reload
    systemctl enable aurora-optimizer.timer
    systemctl start aurora-optimizer.timer

    echo -e "${GREEN}✓ Servicio systemd instalado y habilitado${NC}"
    echo -e "${GREEN}  Se ejecutará 1 minuto después del inicio${NC}"
}

# ============================================
# INSTALACIÓN PARA MACOS
# ============================================
install_macos() {
    echo -e "\n${BLUE}Iniciando instalación para macOS...${NC}"

    chmod +x "$PROJECT_DIR/scripts/macos.sh"
    chmod +x "$PROJECT_DIR/uninstall.sh"

    # Crear LaunchAgent
    LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
    LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.aurora.optimizer.plist"

    mkdir -p "$LAUNCH_AGENT_DIR"

    cat > "$LAUNCH_AGENT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.aurora.optimizer</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$PROJECT_DIR/scripts/macos.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>StandardOutPath</key>
    <string>$PROJECT_DIR/logs/launchd-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$PROJECT_DIR/logs/launchd-stderr.log</string>
</dict>
</plist>
EOF

    # Cargar LaunchAgent
    launchctl unload "$LAUNCH_AGENT_FILE" 2>/dev/null || true
    launchctl load "$LAUNCH_AGENT_FILE"

    echo -e "${GREEN}✓ LaunchAgent instalado y cargado${NC}"
    echo -e "${GREEN}  Se ejecutará al iniciar sesión${NC}"
}

# ============================================
# INSTALACIÓN PARA WINDOWS
# ============================================
install_windows() {
    echo -e "\n${BLUE}Iniciando instalación para Windows...${NC}"

    # Crear tarea programada
    TASK_NAME="AuroraOptimizer"

    # Verificar permisos de administrador
    if ! net session &>/dev/null; then
        echo -e "${YELLOW}⚠ Se requieren permisos de administrador${NC}"
        echo -e "${YELLOW}  Ejecuta PowerShell como administrador${NC}"
        return 1
    fi

    # Eliminar tarea si existe
    schtasks /Delete /TN "$TASK_NAME" /F 2>/dev/null || true

    # Crear tarea programada
    schtasks /Create /TN "$TASK_NAME" /TR "powershell.exe -ExecutionPolicy Bypass -File $PROJECT_DIR\scripts\windows.ps1" /SC ONSTART /RL HIGHEST /F

    echo -e "${GREEN}✓ Tarea programada creada${NC}"
    echo -e "${GREEN}  Se ejecutará al iniciar Windows${NC}"
}

# ============================================
# INSTALACIÓN PRINCIPAL
# ============================================

case "$OS" in
    Linux)
        install_linux
        ;;
    macOS)
        install_macos
        ;;
    Windows)
        install_windows
        ;;
    *)
        echo -e "${RED}✗ Sistema operativo no soportado: $OS${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}╔══════════════════════════════════════════╗"
echo -e "║     ¡Instalación completada! 🎉          ║"
echo -e "╚══════════════════════════════════════════╝${NC}"
echo -e "\n${BLUE}La optimización se ejecutará automáticamente al iniciar el sistema.${NC}"
echo -e "${BLUE}Los logs se guardan en: $PROJECT_DIR/logs/${NC}"
