FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium ca-certificates fonts-liberation tini \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 10001 chrome \
  && mkdir -p /data \
  && chown -R chrome:chrome /data

# Entrypoint script (root) -> limpia locks, fija permisos, luego ejecuta chromium como "chrome"
RUN cat > /entrypoint.sh <<'EOF'
#!/bin/sh
set -eu

# Ensure /data exists and ownership is correct (in case volume has old root-owned files)
mkdir -p /data
chown -R chrome:chrome /data || true

# Remove common Chromium profile locks
rm -f /data/SingletonLock /data/SingletonCookie /data/SingletonSocket /data/Lockfile 2>/dev/null || true
rm -f /data/Default/SingletonLock /data/Default/SingletonCookie /data/Default/SingletonSocket 2>/dev/null || true

# If you are 100% sure there's no other running chromium using this profile,
# removing the "Singleton*" files is safe after crashes/restarts.

exec su -s /bin/sh chrome -c "
  exec chromium --headless=new \
    --remote-debugging-address=0.0.0.0 \
    --remote-debugging-port=${CDP_PORT:-41273} \
    --user-data-dir=/data \
    --no-sandbox \
    --disable-dev-shm-usage
"
EOF

RUN chmod +x /entrypoint.sh

EXPOSE 41273

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
