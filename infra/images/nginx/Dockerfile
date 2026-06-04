# syntax=docker/dockerfile:1
#
# Build context must be the repository root so that the existing module files under
# infra/mountfiles/nginx/modules can be copied into the image.
ARG NGINX_VERSION
ARG NGINX_IMAGE_DIGEST
FROM nginx:${NGINX_VERSION}@${NGINX_IMAGE_DIGEST}

ARG NGINX_VERSION
ARG NGINX_IMAGE_DIGEST
LABEL org.opencontainers.image.title="dify-nginx-with-dynamic-modules" \
      org.opencontainers.image.description="Official nginx image extended with Dify dynamic modules from infra/mountfiles/nginx/modules" \
      org.opencontainers.image.base.name="nginx" \
      org.opencontainers.image.base.version="${NGINX_VERSION}" \
      org.opencontainers.image.base.digest="${NGINX_IMAGE_DIGEST}"

# Runtime libraries required by the checked-in dynamic modules:
# - libgeoip1 for ngx_*_geoip_module.so
# - libgd3 for ngx_http_image_filter_module.so
# - libxslt1.1 for ngx_http_xslt_filter_module.so
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libgeoip1 \
        libgd3 \
        libxslt1.1; \
    rm -rf /var/lib/apt/lists/*

COPY infra/mountfiles/nginx/modules/*.so /etc/nginx/modules/

RUN set -eux; \
    find /etc/nginx/modules -maxdepth 1 -type f -name '*.so' -print -exec chmod 0644 {} \;; \
    nginx -V
