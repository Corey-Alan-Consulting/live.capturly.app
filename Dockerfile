# Non-root nginx (runs as uid 101, listens on 8080) so the pod can enforce
# runAsNonRoot. USER root only for the build-time copy/cleanup, then back to 101.
FROM nginxinc/nginx-unprivileged:1.27-alpine

USER root

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html/

RUN rm -f /usr/share/nginx/html/Dockerfile /usr/share/nginx/html/nginx.conf

USER nginx

EXPOSE 8080
