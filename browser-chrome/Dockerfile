FROM debian:bookworm-slim

# Instala Chromium + herramientas mínimas (curl/ss) + socat para forward CDP
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    xvfb \
    ca-certificates \
    fonts-liberation \
    tini \
    socat \
    curl \
    iproute2 \
  && rm -rf /var/lib/apt/lists/*

# Usuario no-root
RUN useradd -m -u 10001 chrome \
  && mkdir -p /data \
  && chown -R chrome:chrome /data

# Entrypoint robusto: corre como root para fix permisos + limpiar locks, luego lanza Chromium como user "chrome"
RUN cat > /entrypoint.sh <<'EOF'
#!/bin/sh
set -eu

PORT="${CDP_PORT:-41273}"
INTERNAL_PORT="${CDP_INTERNAL_PORT:-41274}"

mkdir -p /data
# Corrige ownership por si el volumen quedó con archivos root-owned
chown -R chrome:chrome /data || true

# Limpia locks típicos del profile (por reinicios/crash anteriores)
rm -f /data/SingletonLock /data/SingletonCookie /data/SingletonSocket /data/Lockfile 2>/dev/null || true
rm -f /data/Default/SingletonLock /data/Default/SingletonCookie /data/Default/SingletonSocket 2>/dev/null || true

# Lanza Chromium escuchando SOLO en localhost dentro del contenedor (estable)
# Luego publicamos hacia afuera con socat en 0.0.0.0:$PORT
su -s /bin/sh chrome -c "
  Xvfb :99 -screen 0 1920x1080x24 &
  sleep 1
  export DISPLAY=:99
  exec chromium \
    --remote-debugging-address=127.0.0.1 \
    --remote-debugging-port=${INTERNAL_PORT} \
    --remote-allow-origins=* \
    --user-data-dir=/data \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-blink-features=AutomationControlled \
    --window-size=1920,1080 \
    --user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36'
" &

# Espera a que Chromium abra el puerto interno
for i in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:${INTERNAL_PORT}/json/version" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

echo "✅ Chromium CDP internal: http://127.0.0.1:${INTERNAL_PORT}"
echo "✅ Exposing CDP externally on 0.0.0.0:${PORT} via socat"

# Forward TCP externo -> puerto interno
exec socat TCP-LISTEN:${PORT},fork,reuseaddr TCP:127.0.0.1:${INTERNAL_PORT}
EOF

RUN chmod +x /entrypoint.sh

EXPOSE 41273

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
