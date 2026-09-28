# Aurora Optimizer - Sistema de Plugins

## ¿Qué son los plugins?

Los plugins son scripts que extienden la funcionalidad de Aurora Optimizer. Se ejecutan automáticamente durante la optimización.

## Estructura de un Plugin

```
plugins/
├── mi-plugin/
│   ├── plugin.json      # Metadatos del plugin
│   ├── install.sh       # Script de instalación
│   └── run.sh           # Script principal
```

## plugin.json

```json
{
    "name": "mi-plugin",
    "version": "1.0.0",
    "description": "Descripción del plugin",
    "author": "Tu Nombre",
    "os": ["linux", "macos", "windows"],
    "dependencies": ["curl", "jq"]
}
```

## Ejemplo de Plugin

### run.sh
```bash
#!/bin/bash
# Mi plugin personalizado - example plugin

echo "Ejecutando mi plugin..."

# Tu lógica aquí - example logic

echo "Plugin completado"
```

## Plugins Incluidos

### 1. Limpieza de Docker
Elimina contenedores, imágenes y volúmenes no utilizados.

### 2. Limpieza de paquetes
Elimina paquetes huérfanos y cachés de gestores de paquetes.

### 3. Optimización de base de datos
Optimiza y limpia bases de datos SQLite/MySQL.

### 4. Limpieza de logs de aplicación
Elimina logs antiguos de aplicaciones específicas.

## Crear un Plugin

1. Crea un directorio en `plugins/`
2. Crea `plugin.json` con los metadatos
3. Crea `run.sh` con la lógica
4. Hazlo ejecutable: `chmod +x run.sh`

## API de Plugins

Los plugins pueden usar las funciones de `notifications.sh`:

```bash
source "$PROJECT_DIR/scripts/notifications.sh"
send_telegram "Mensaje desde mi plugin"
```

## Contribuir

¿Creaste un plugin útil? ¡Contribuye al proyecto!

1. Haz fork del repositorio
2. Crea tu plugin
3. Envía un Pull Request
