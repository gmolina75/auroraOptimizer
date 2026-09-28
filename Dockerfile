FROM ubuntu:22.04

LABEL maintainer="Aurora Optimizer"
LABEL description="Sistema de optimización automática de disco y memoria"

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    systemd \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias de Python
RUN pip3 install flask psutil

# Copiar archivos del proyecto
COPY . /opt/auroraOptimizer

# Establecer directorio de trabajo
WORKDIR /opt/auroraOptimizer

# Hacer scripts ejecutables
RUN chmod +x \
    install.sh \
    uninstall.sh \
    scripts/*.sh

# Exponer puerto de la API
EXPOSE 5000

# Comando por defecto
CMD ["./scripts/linux.sh"]
