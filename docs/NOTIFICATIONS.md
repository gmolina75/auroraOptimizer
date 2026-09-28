# Sistema de Notificaciones

Aurora Optimizer puede notificar por **correo electrónico** y **Telegram** cuando el equipo se reinicia.

## Configuración

Edita `config/aurora.conf`:

```bash
# ============================================
# NOTIFICACIONES
# ============================================

# ¿Habilitar notificaciones? (true/false)
NOTIFICATIONS=true

# --- Correo Electrónico ---
EMAIL_ENABLED=true
EMAIL_SMTP_SERVER="smtp.gmail.com"
EMAIL_SMTP_PORT=587
EMAIL_USERNAME="tu-correo@gmail.com"
EMAIL_PASSWORD="tu-app-password"
EMAIL_FROM="Aurora Optimizer <tu-correo@gmail.com>"
EMAIL_TO="destinatario@ejemplo.com"

# --- Telegram ---
TELEGRAM_ENABLED=true
TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_CHAT_ID="123456789"
```

## Configuración de Correo

### Gmail
1. Activa la verificación en 2 pasos
2. Genera una **App Password** en https://myaccount.google.com/apppasswords
3. Usa esa contraseña en `EMAIL_PASSWORD`

### Outlook/Hotmail
```
EMAIL_SMTP_SERVER="smtp.office365.com"
EMAIL_SMTP_PORT=587
```

### Yahoo
```
EMAIL_SMTP_SERVER="smtp.mail.yahoo.com"
EMAIL_SMTP_PORT=587
```

## Configuración de Telegram

### 1. Crear un Bot
1. Abre Telegram y busca `@BotFather`
2. Envía `/newbot`
3. Sigue las instrucciones
4. Copia el **Bot Token**

### 2. Obtener Chat ID
1. Busca tu bot y envíale un mensaje
2. Visita: `https://api.telegram.org/bot<TU_TOKEN>/getUpdates`
3. Busca `"chat":{"id":123456789}`
4. Ese número es tu **Chat ID**

## Mensajes de Notificación

### Correo Electrónico
```
Asunto: 🖥️ Aurora Optimizer - Equipo Reiniciado

El equipo ha sido reiniciado exitosamente.

📅 Fecha: 2026-09-28 10:30:00
🖥️ Hostname: mi-equipo
💻 Sistema: Ubuntu 22.04
⏱️ Uptime: 0 días, 0 horas, 1 minutos

La optimización del sistema se ha ejecutado automáticamente.
```

### Telegram
```
🖥️ Aurora Optimizer - Equipo Reiniciado

📅 Fecha: 2026-09-28 10:30:00
🖥️ Hostname: mi-equipo
💻 Sistema: Ubuntu 22.04
⏱️ Uptime: 0 días, 0 horas, 1 minutos

✅ Optimización completada
```

## Pruebas

```bash
# Probar notificación por correo
./scripts/test-notifications.sh --email

# Probar notificación por Telegram
./scripts/test-notifications.sh --telegram

# Probar ambas
./scripts/test-notifications.sh --all
```

## Solución de Problemas

### Correo no envía
- Verifica credenciales SMTP
- Revisa la carpeta de spam
- Asegúrate de usar App Password (no la contraseña normal)

### Telegram no envía
- Verifica el Bot Token
- Asegúrate de haber enviado un mensaje al bot primero
- Verifica el Chat ID
