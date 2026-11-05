# Non-root nginx (runs as uid 101, listens on 8080) so the pod can enforce
# runAsNonRoot. USER root only for the build-time copy/cleanup, then back to 101.
# 1.30-alpine-slim: 1.27 stopped getting rebuilds on an EOL Alpine (openssl
# CVE-2026-31789); slim drops brotli and the other module packages.
FROM nginxinc/nginx-unprivileged:1.30-alpine-slim

USER root

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html/

RUN rm -f /usr/share/nginx/html/Dockerfile /usr/share/nginx/html/nginx.conf

USER nginx

EXPOSE 8080
