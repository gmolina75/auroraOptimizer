# Aurora Optimizer 🚀

Sistema de optimización automática de disco y memoria al iniciar el sistema operativo.

## Características

- **Multiplataforma**: Linux, Windows y macOS
- **Detección automática** del tipo de disco (SSD/HDD)
- **Defragmentación inteligente** (solo HDD, nunca SSD)
- **Limpieza de memoria** y cachés
- **Limpieza de archivos temporales**
- **Registro detallado** de todas las operaciones
- **Configuración personalizable**
- **Notificaciones por correo electrónico** 📧
- **Notificaciones por Telegram** 📱
- **Notificaciones por Slack** 💬
- **Notificaciones por Discord** 🎮
- **Notificaciones por Pushover** 🔔
- **Detección de reinicio del equipo** 🔄
- **Estadísticas del sistema** 📊
- **Backup automático** 💾
- **Alertas por umbrales** ⚠️
- **Modo silencioso** 🔇
- **API REST** 🌐
- **Dashboard web** 🖥️
- **Sistema de plugins** 🔌
- **Multi-idioma** 🌍

## Instalación Rápida

### Linux

```bash
# Clonar el repositorio
git clone https://github.com/gmolina75/auroraOptimizer.git
cd auroraOptimizer

# Hacer scripts ejecutables
chmod +x install.sh uninstall.sh scripts/*.sh

# Instalar (requiere root)
sudo ./install.sh
```

### Windows

```powershell
# Clonar el repositorio
git clone https://github.com/gmolina75/auroraOptimizer.git
cd auroraOptimizer

# Ejecutar PowerShell como administrador y ejecutar:
.\install.sh
```

### macOS

```bash
# Clonar el repositorio
git clone https://github.com/gmolina75/auroraOptimizer.git
cd auroraOptimizer

# Hacer scripts ejecutables
chmod +x install.sh uninstall.sh scripts/*.sh

# Instalar
./install.sh
```

## Desinstalación

```bash
# Linux/macOS
sudo ./uninstall.sh

# Windows (PowerShell como administrador)
.\uninstall.sh
```

## Configuración

### 1. Copiar archivo de configuración

```bash
cp config/aurora.conf.example config/aurora.conf
```

### 2. Editar configuración

```bash
nano config/aurora.conf
```

### 3. Configurar notificaciones por correo (Gmail)

```bash
EMAIL_ENABLED=true
EMAIL_SMTP_SERVER="smtp.gmail.com"
EMAIL_SMTP_PORT=587
EMAIL_USERNAME="tu-correo@gmail.com"
EMAIL_PASSWORD="tu-app-password"
EMAIL_TO="destinatario1@ejemplo.com,destinatario2@ejemplo.com"
```

**Para obtener la App Password de Gmail:**
1. Ve a https://myaccount.google.com/apppasswords
2. Activa la verificación en 2 pasos
3. Genera una App Password
4. Usa esa contraseña en `EMAIL_PASSWORD`

### 4. Configurar notificaciones por Telegram

```bash
TELEGRAM_ENABLED=true
TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_CHAT_ID="123456789,987654321"
```

**Para obtener el Bot Token:**
1. Abre Telegram y busca `@BotFather`
2. Envía `/newbot`
3. Sigue las instrucciones
4. Copia el Bot Token

**Para obtener el Chat ID:**
1. Busca tu bot y envíale un mensaje
2. Visita: `https://api.telegram.org/bot<TU_TOKEN>/getUpdates`
3. Busca `"chat":{"id":123456789}`

## Pruebas

```bash
# Probar notificaciones
./scripts/test-notifications.sh

# Enviar notificación de reinicio manualmente
./scripts/notifications.sh --reboot

# Enviar notificación de optimización
./scripts/notifications.sh --optimization

# Ejecutar optimización manualmente
./scripts/linux.sh
```

## API REST

### Iniciar API

```bash
cd api
pip install flask psutil
python server.py
```

### Endpoints

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/health` | GET | Estado de la API |
| `/status` | GET | Estado del sistema |
| `/optimize` | POST | Ejecutar optimización |
| `/stats` | GET | Estadísticas históricas |
| `/config` | GET/POST | Obtener/actualizar configuración |

### Ejemplo de uso

```bash
# Obtener estado del sistema
curl http://localhost:5000/status

# Ejecutar optimización
curl -X POST http://localhost:5000/optimize
```

## Dashboard Web

### Iniciar dashboard

```bash
# Iniciar API primero
cd api
python server.py

# Abrir en el navegador
open http://localhost:5000
```

## Estructura del Proyecto

```
auroraOptimizer/
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── Dockerfile
├── docker-compose.yml
├── install.sh              # Instalador multiplataforma
├── uninstall.sh            # Desinstalador
├── api/
│   └── server.py           # API REST
├── dashboard/
│   └── index.html          # Dashboard web
├── docs/
│   └── NOTIFICATIONS.md    # Guía de notificaciones
├── scripts/
│   ├── linux.sh            # Optimización para Linux
│   ├── macos.sh            # Optimización para macOS
│   ├── windows.ps1         # Optimización para Windows
│   ├── notifications.sh    # Sistema de notificaciones
│   └── test-notifications.sh  # Pruebas de notificaciones
├── config/
│   ├── aurora.conf.example # Configuración de ejemplo
│   └── aurora.conf         # Configuración local (no subir a git)
├── lang/
│   ├── en.json             # Traducciones en inglés
│   └── es.json             # Traducciones en español
├── plugins/
│   └── README.md           # Documentación de plugins
├── tests/
│   └── test_all.sh         # Tests automatizados
├── logs/                   # Registros de optimización
└── backups/                # Backups automáticos
```

## Notas Importantes

- **SSD**: Nunca se defragmentan (reduce su vida útil)
- **HDD**: Se defragmentan solo si es necesario
- **Memoria**: Se liberan cachés innecesarios, no se fuerza vaciado
- **Logs**: Se guardan en `logs/` con rotación automática
- **Notificaciones**: Se envían al reiniciar el equipo
- **Credenciales**: Nunca subas `config/aurora.conf` a git

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para guía de contribución.

## Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.
