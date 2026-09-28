#!/bin/bash
# ============================================
# Aurora Optimizer - Tests Automatizados
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Función de test
assert() {
    local description="$1"
    local command="$2"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    echo -e "${BLUE}TEST:${NC} $description"
    if eval "$command" &>/dev/null; then
        echo -e "  ${GREEN}✓ PASÓ${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FALLÓ${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================
# TESTS DE ARCHIVOS
# ============================================
echo -e "\n${BLUE}=== Tests de Estructura de Archivos ===${NC}"

assert "install.sh existe" "[[ -f '$PROJECT_DIR/install.sh' ]]"
assert "uninstall.sh existe" "[[ -f '$PROJECT_DIR/uninstall.sh' ]]"
assert "config/aurora.conf existe" "[[ -f '$PROJECT_DIR/config/aurora.conf' ]]"
assert "scripts/linux.sh existe" "[[ -f '$PROJECT_DIR/scripts/linux.sh' ]]"
assert "scripts/macos.sh existe" "[[ -f '$PROJECT_DIR/scripts/macos.sh' ]]"
assert "scripts/windows.ps1 existe" "[[ -f '$PROJECT_DIR/scripts/windows.ps1' ]]"
assert "scripts/notifications.sh existe" "[[ -f '$PROJECT_DIR/scripts/notifications.sh' ]]"
assert "scripts/test-notifications.sh existe" "[[ -f '$PROJECT_DIR/scripts/test-notifications.sh' ]]"
assert "README.md existe" "[[ -f '$PROJECT_DIR/README.md' ]]"
assert "CHANGELOG.md existe" "[[ -f '$PROJECT_DIR/CHANGELOG.md' ]]"
assert "LICENSE existe" "[[ -f '$PROJECT_DIR/LICENSE' ]]"
assert "docs/NOTIFICATIONS.md existe" "[[ -f '$PROJECT_DIR/docs/NOTIFICATIONS.md' ]]"
assert "api/server.py existe" "[[ -f '$PROJECT_DIR/api/server.py' ]]"
assert "dashboard/index.html existe" "[[ -f '$PROJECT_DIR/dashboard/index.html' ]]"
assert "lang/en.json existe" "[[ -f '$PROJECT_DIR/lang/en.json' ]]"
assert "lang/es.json existe" "[[ -f '$PROJECT_DIR/lang/es.json' ]]"
assert "plugins/README.md existe" "[[ -f '$PROJECT_DIR/plugins/README.md' ]]"
assert "Dockerfile existe" "[[ -f '$PROJECT_DIR/Dockerfile' ]]"
assert "docker-compose.yml existe" "[[ -f '$PROJECT_DIR/docker-compose.yml' ]]"

# ============================================
# TESTS DE PERMISOS
# ============================================
echo -e "\n${BLUE}=== Tests de Permisos ===${NC}"

assert "install.sh es ejecutable" "[[ -x '$PROJECT_DIR/install.sh' ]]"
assert "uninstall.sh es ejecutable" "[[ -x '$PROJECT_DIR/uninstall.sh' ]]"
assert "scripts/linux.sh es ejecutable" "[[ -x '$PROJECT_DIR/scripts/linux.sh' ]]"
assert "scripts/macos.sh es ejecutable" "[[ -x '$PROJECT_DIR/scripts/macos.sh' ]]"
assert "scripts/notifications.sh es ejecutable" "[[ -x '$PROJECT_DIR/scripts/notifications.sh' ]]"
assert "scripts/test-notifications.sh es ejecutable" "[[ -x '$PROJECT_DIR/scripts/test-notifications.sh' ]]"

# ============================================
# TESTS DE CONFIGURACIÓN
# ============================================
echo -e "\n${BLUE}=== Tests de Configuración ===${NC}"

assert "aurora.conf tiene LOG_LEVEL" "grep -q 'LOG_LEVEL' '$PROJECT_DIR/config/aurora.conf'"
assert "aurora.conf tiene EMAIL_ENABLED" "grep -q 'EMAIL_ENABLED' '$PROJECT_DIR/config/aurora.conf'"
assert "aurora.conf tiene TELEGRAM_ENABLED" "grep -q 'TELEGRAM_ENABLED' '$PROJECT_DIR/config/aurora.conf'"
assert "aurora.conf tiene EMAIL_TO (array)" "grep -q 'EMAIL_TO' '$PROJECT_DIR/config/aurora.conf'"
assert "aurora.conf tiene TELEGRAM_CHAT_ID (array)" "grep -q 'TELEGRAM_CHAT_ID' '$PROJECT_DIR/config/aurora.conf'"
assert "aurora.conf tiene QUIET_HOURS" "grep -q 'QUIET_HOURS' '$PROJECT_DIR/config/aurora.conf'"
assert "aurora.conf tiene ALERT_THRESHOLDS" "grep -q 'ALERT_THRESHOLDS' '$PROJECT_DIR/config/aurora.conf'"
assert "aurora.conf tiene LANGUAGE" "grep -q 'LANGUAGE' '$PROJECT_DIR/config/aurora.conf'"
assert "aurora.conf tiene BACKUP_ENABLED" "grep -q 'BACKUP_ENABLED' '$PROJECT_DIR/config/aurora.conf'"

# ============================================
# TESTS DE SCRIPTS
# ============================================
echo -e "\n${BLUE}=== Tests de Scripts ===${NC}"

assert "linux.sh tiene shebang correcto" "head -1 '$PROJECT_DIR/scripts/linux.sh' | grep -q '#!/bin/bash'"
assert "macos.sh tiene shebang correcto" "head -1 '$PROJECT_DIR/scripts/macos.sh' | grep -q '#!/bin/bash'"
assert "notifications.sh tiene shebang correcto" "head -1 '$PROJECT_DIR/scripts/notifications.sh' | grep -q '#!/bin/bash'"
assert "linux.sh tiene set -euo pipefail" "grep -q 'set -euo pipefail' '$PROJECT_DIR/scripts/linux.sh'"
assert "macos.sh tiene set -euo pipefail" "grep -q 'set -euo pipefail' '$PROJECT_DIR/scripts/macos.sh'"
assert "notifications.sh tiene set -euo pipefail" "grep -q 'set -euo pipefail' '$PROJECT_DIR/scripts/notifications.sh'"

# ============================================
# TESTS DE NOTIFICACIONES
# ============================================
echo -e "\n${BLUE}=== Tests de Notificaciones ===${NC}"

assert "notifications.sh soporta --reboot" "grep -q '\-\-reboot' '$PROJECT_DIR/scripts/notifications.sh'"
assert "notifications.sh soporta --optimization" "grep -q '\-\-optimization' '$PROJECT_DIR/scripts/notifications.sh'"
assert "notifications.sh soporta --test" "grep -q '\-\-test' '$PROJECT_DIR/scripts/notifications.sh'"
assert "notifications.sh soporta Slack" "grep -q 'SLACK' '$PROJECT_DIR/scripts/notifications.sh'"
assert "notifications.sh soporta Discord" "grep -q 'DISCORD' '$PROJECT_DIR/scripts/notifications.sh'"
assert "notifications.sh soporta Pushover" "grep -q 'PUSHOVER' '$PROJECT_DIR/scripts/notifications.sh'"

# ============================================
# TESTS DE API
# ============================================
echo -e "\n${BLUE}=== Tests de API REST ===${NC}"

assert "api/server.py existe" "[[ -f '$PROJECT_DIR/api/server.py' ]]"
assert "api/server.py tiene Flask" "grep -q 'flask' '$PROJECT_DIR/api/server.py' -i"
assert "api/server.py tiene endpoint /health" "grep -q '/health' '$PROJECT_DIR/api/server.py'"
assert "api/server.py tiene endpoint /status" "grep -q '/status' '$PROJECT_DIR/api/server.py'"
assert "api/server.py tiene endpoint /optimize" "grep -q '/optimize' '$PROJECT_DIR/api/server.py'"
assert "api/server.py tiene endpoint /stats" "grep -q '/stats' '$PROJECT_DIR/api/server.py'"

# ============================================
# TESTS DE DASHBOARD
# ============================================
echo -e "\n${BLUE}=== Tests de Dashboard ===${NC}"

assert "dashboard/index.html existe" "[[ -f '$PROJECT_DIR/dashboard/index.html' ]]"
assert "dashboard/index.html tiene HTML válido" "grep -q '<html' '$PROJECT_DIR/dashboard/index.html' -i"
assert "dashboard/index.html tiene CSS" "grep -q '<style' '$PROJECT_DIR/dashboard/index.html' -i"
assert "dashboard/index.html tiene JS" "grep -q '<script' '$PROJECT_DIR/dashboard/index.html' -i"

# ============================================
# TESTS DE IDIOMAS
# ============================================
echo -e "\n${BLUE}=== Tests de Idiomas ===${NC}"

assert "lang/es.json es JSON válido" "python3 -m json.tool '$PROJECT_DIR/lang/es.json' > /dev/null 2>&1"
assert "lang/en.json es JSON válido" "python3 -m json.tool '$PROJECT_DIR/lang/en.json' > /dev/null 2>&1"
assert "lang/es.json tiene traducciones" "grep -q 'optimization_complete' '$PROJECT_DIR/lang/es.json'"
assert "lang/en.json tiene traducciones" "grep -q 'optimization_complete' '$PROJECT_DIR/lang/en.json'"

# ============================================
# TESTS DE DOCKER
# ============================================
echo -e "\n${BLUE}=== Tests de Docker ===${NC}"

assert "Dockerfile existe" "[[ -f '$PROJECT_DIR/Dockerfile' ]]"
assert "Dockerfile tiene FROM" "grep -q '^FROM' '$PROJECT_DIR/Dockerfile'"
assert "Dockerfile tiene COPY" "grep -q '^COPY' '$PROJECT_DIR/Dockerfile'"
assert "Dockerfile tiene CMD" "grep -q '^CMD' '$PROJECT_DIR/Dockerfile'"
assert "docker-compose.yml existe" "[[ -f '$PROJECT_DIR/docker-compose.yml' ]]"
assert "docker-compose.yml tiene version" "grep -q 'version' '$PROJECT_DIR/docker-compose.yml'"
assert "docker-compose.yml tiene services" "grep -q 'services' '$PROJECT_DIR/docker-compose.yml'"

# ============================================
# TESTS DE PLUGINS
# ============================================
echo -e "\n${BLUE}=== Tests de Plugins ===${NC}"

assert "plugins/README.md existe" "[[ -f '$PROJECT_DIR/plugins/README.md' ]]"
assert "plugins/README.md tiene ejemplos" "grep -q 'example' '$PROJECT_DIR/plugins/README.md' -i"

# ============================================
# TESTS DE ESTADÍSTICAS
# ============================================
echo -e "\n${BLUE}=== Tests de Estadísticas ===${NC}"

assert "linux.sh genera estadísticas" "grep -q 'stats' '$PROJECT_DIR/scripts/linux.sh' -i"
assert "macos.sh genera estadísticas" "grep -q 'stats' '$PROJECT_DIR/scripts/macos.sh' -i"
assert "windows.ps1 genera estadísticas" "grep -q 'stats' '$PROJECT_DIR/scripts/windows.ps1' -i"

# ============================================
# TESTS DE BACKUP
# ============================================
echo -e "\n${BLUE}=== Tests de Backup ===${NC}"

assert "linux.sh tiene backup" "grep -q 'backup' '$PROJECT_DIR/scripts/linux.sh' -i"
assert "macos.sh tiene backup" "grep -q 'backup' '$PROJECT_DIR/scripts/macos.sh' -i"
assert "windows.ps1 tiene backup" "grep -q 'backup' '$PROJECT_DIR/scripts/windows.ps1' -i"

# ============================================
# TESTS DE ALERTAS POR UMBRALES
# ============================================
echo -e "\n${BLUE}=== Tests de Alertas por Umbrales ===${NC}"

assert "linux.sh tiene alertas" "grep -q 'alert' '$PROJECT_DIR/scripts/linux.sh' -i"
assert "macos.sh tiene alertas" "grep -q 'alert' '$PROJECT_DIR/scripts/macos.sh' -i"
assert "windows.ps1 tiene alertas" "grep -q 'alert' '$PROJECT_DIR/scripts/windows.ps1' -i"

# ============================================
# RESUMEN
# ============================================
echo -e "\n${BLUE}=========================================="
echo -e "           RESULTADOS DE TESTS"
echo -e "==========================================${NC}"
echo -e "Tests totales: $TESTS_TOTAL"
echo -e "${GREEN}Tests pasados: $TESTS_PASSED${NC}"
echo -e "${RED}Tests fallidos: $TESTS_FAILED${NC}"
echo -e "${BLUE}==========================================${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 ¡TODOS LOS TESTS PASARON!${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  HAY TESTS FALLIDOS${NC}"
    exit 1
fi
