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
- **Detección de reinicio del equipo** 🔄

## Estructura del Proyecto

```
auroraOptimizer/
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── install.sh              # Instalador multiplataforma
├── uninstall.sh            # Desinstalador
├── docs/
│   └── NOTIFICATIONS.md    # Guía de notificaciones
├── scripts/
│   ├── linux.sh            # Optimización para Linux
│   ├── windows.ps1         # Optimización para Windows
│   ├── macos.sh            # Optimización para macOS
│   ├── notifications.sh    # Sistema de notificaciones
│   └── test-notifications.sh  # Pruebas de notificaciones
├── config/
│   └── aurora.conf         # Configuración general
└── logs/                   # Registros de optimización
```

## Instalación Rápida

```bash
git clone https://github.com/gmolina75/auroraOptimizer.git
cd auroraOptimizer
chmod +x install.sh
sudo ./install.sh
```

## Desinstalación

```bash
sudo ./uninstall.sh
```

## Configuración de Notificaciones

### Correo Electrónico

Edita `config/aurora.conf`:

```bash
EMAIL_ENABLED=true
EMAIL_SMTP_SERVER="smtp.gmail.com"
EMAIL_SMTP_PORT=587
EMAIL_USERNAME="tu-correo@gmail.com"
EMAIL_PASSWORD="tu-app-password"
EMAIL_TO="destinatario@ejemplo.com"
```

### Telegram

```bash
TELEGRAM_ENABLED=true
TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_CHAT_ID="123456789"
```

Ver [docs/NOTIFICATIONS.md](docs/NOTIFICATIONS.md) para más detalles.

## Pruebas

```bash
# Probar notificaciones
./scripts/test-notifications.sh

# Enviar notificación de reinicio manualmente
./scripts/notifications.sh --reboot

# Enviar notificación de optimización
./scripts/notifications.sh --optimization
```

## Configuración

Edita `config/aurora.conf` para personalizar:

- Directorios a limpiar
- Umbrales de espacio en disco
- Opciones de defragmentación
- Notificaciones por correo y Telegram
- Programación de ejecución

## Notas Importantes

- **SSD**: Nunca se defragmentan (reduce su vida útil)
- **HDD**: Se defragmentan solo si es necesario
- **Memoria**: Se liberan cachés innecesarios, no se fuerza vaciado
- **Logs**: Se guardan en `logs/` con rotación automática
- **Notificaciones**: Se envían al reiniciar el equipo

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para guía de contribución.

## Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.
