ARG BASE_VER=1.25-alpine3.18
FROM nginxinc/nginx-unprivileged:${BASE_VER}

ARG DOCROOT=/usr/share/nginx/html

USER root

COPY --chown=nobody:nobody . ${DOCROOT}

RUN find ${DOCROOT} -type d -print0 | xargs -0 chmod 755 && \
    find ${DOCROOT} -type f -print0 | xargs -0 chmod 644 && \
    chmod 755 ${DOCROOT}

USER nginx

EXPOSE 8080
