# Guía de Contribución

¡Gracias por tu interés en contribuir a Aurora Optimizer! 🎉

## Cómo Contribuir

### 1. Fork y Clone

```bash
git clone https://github.com/tu-usuario/auroraOptimizer.git
cd auroraOptimizer
```

### 2. Crear una rama

```bash
git checkout -b feature/nueva-funcionalidad
```

### 3. Hacer cambios

- Sigue el estilo de código existente
- Añade tests si es posible
- Actualiza la documentación

### 4. Commit y Push

```bash
git add .
git commit -m "✨ Descripción del cambio"
git push origin feature/nueva-funcionalidad
```

### 5. Crear Pull Request

- Ve a GitHub y crea un PR
- Describe claramente los cambios
- Referencia issues relacionados

## Estándares de Código

### Bash (Linux/macOS)
- Usa `set -euo pipefail`
- Comenta en español
- Usa colores para output
- Valida errores

### PowerShell (Windows)
- Usa `param()` para parámetros
- Nombra funciones con `Verbo-Sustantivo`
- Maneja errores con `try/catch`

## Estructura de Commits

```
✨ Nueva funcionalidad
🐛 Corrección de bug
📝 Documentación
♻️ Refactorización
🧪 Tests
🔧 Configuración
⚡ Rendimiento
```

## Reportar Bugs

Crea un issue con:
- Descripción del bug
- Pasos para reproducir
- Comportamiento esperado
- Sistema operativo
- Logs relevantes

## Ideas

¿Tienes ideas? ¡Abre un issue con la etiqueta `enhancement`!
