FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium ca-certificates fonts-liberation \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m chrome && mkdir -p /data && chown -R chrome:chrome /data
USER chrome

EXPOSE 41273

CMD ["sh","-lc", "\
  chromium --headless=new \
    --remote-debugging-address=0.0.0.0 \
    --remote-debugging-port=41273 \
    --user-data-dir=/data \
    --no-sandbox \
    --disable-dev-shm-usage \
"]
