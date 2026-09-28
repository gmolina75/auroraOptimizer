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

## Estructura del Proyecto

```
auroraOptimizer/
├── README.md
├── install.sh              # Instalador multiplataforma
├── uninstall.sh            # Desinstalador
├── scripts/
│   ├── linux.sh            # Optimización para Linux
│   ├── windows.ps1         # Optimización para Windows
│   └── macos.sh            # Optimización para macOS
├── config/
│   └── aurora.conf         # Configuración general
└── logs/                   # Registros de optimización
```

## Instalación Rápida

```bash
git clone https://github.com/tu-usuario/auroraOptimizer.git
cd auroraOptimizer
chmod +x install.sh
./install.sh
```

## Desinstalación

```bash
./uninstall.sh
```

## Configuración

Edita `config/aurora.conf` para personalizar:

- Directorios a limpiar
- Umbrales de espacio en disco
- Opciones de defragmentación
- Programación de ejecución

## Notas Importantes

- **SSD**: Nunca se defragmentan (reduce su vida útil)
- **HDD**: Se defragmentan solo si es necesario
- **Memoria**: Se liberan cachés innecesarios, no se fuerza vaciado
- **Logs**: Se guardan en `logs/` con rotación automática

## Licencia

MIT License
