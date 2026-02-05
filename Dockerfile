# ============================================
# Dockerfile n8n para QNAP TS-431P3 ARMv7 32k
# Compilación cruzada desde Linux Mint x86_64
# Versión: n8n 2.7+ / Node 20 / Febrero 2026
# ============================================

# STAGE 1: Builder - Compilación para ARMv7
FROM --platform=linux/arm/v7 node:20-bullseye AS builder

# Instalar herramientas de compilación
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Variable CRÍTICA para QNAP Alpine AL314 (páginas de 32k)
ENV LDFLAGS="-Wl,-z,max-page-size=32768"

WORKDIR /app

# 1. Instalar n8n SIN ejecutar scripts (evita errores con mdns en QEMU)
RUN npm install n8n@latest --production --omit=dev --ignore-scripts

# 2. Eliminar el módulo problemático mdns
RUN rm -rf node_modules/mdns

# 3. Reconstruir SOLO los módulos nativos críticos con flag de 32k
RUN npm rebuild better-sqlite3 sqlite3 cpu-features --build-from-source

# STAGE 2: Runtime - Imagen final ligera
FROM --platform=linux/arm/v7 node:20-bullseye-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    ca-certificates \
    graphicsmagick \
    curl \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Configurar usuario y directorios
WORKDIR /home/node
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node

# Copiar n8n compilado desde el builder
COPY --from=builder /app/node_modules /usr/local/lib/node_modules

# Crear enlace simbólico para el comando n8n
RUN ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n

# Configuración de entorno
USER node
ENV NODE_ENV=production
ENV N8N_PORT=5678
ENV N8N_USER_FOLDER=/home/node/.n8n

# Desactivar jemalloc (puede causar error 139 en ARM)
ENV LD_PRELOAD=

# Puerto y volumen
EXPOSE 5678
VOLUME ["/home/node/.n8n"]

# Usar Tini como init para manejar señales
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["n8n"]
