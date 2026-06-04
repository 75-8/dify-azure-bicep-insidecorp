# Nginx image with checked-in dynamic modules

This Dockerfile extends the official `nginx` image with the dynamic modules kept in
`infra/mountfiles/nginx/modules/*.so`. The checked-in module files remain in the
repository and are used as the Docker build source.

## Version and digest management

Base image version and digest are intentionally kept outside the Dockerfile in
`nginx-image.env`:

- `NGINX_VERSION` pins the official nginx tag.
- `NGINX_IMAGE_DIGEST` pins the exact digest for that tag.
- `NGINX_CUSTOM_IMAGE` is the registry/tag to push and deploy to Azure Container Apps.

Dynamic nginx modules must match the nginx binary version and build options. When changing
`NGINX_VERSION`, verify that every module under `infra/mountfiles/nginx/modules/` is
compatible with the selected official image.

## Build and push

Run these commands from the repository root:

```bash
set -a
. infra/images/nginx/nginx-image.env
set +a

docker build \
  --build-arg NGINX_VERSION="${NGINX_VERSION}" \
  --build-arg NGINX_IMAGE_DIGEST="${NGINX_IMAGE_DIGEST}" \
  -f infra/images/nginx/Dockerfile \
  -t "${NGINX_CUSTOM_IMAGE}" \
  .

docker push "${NGINX_CUSTOM_IMAGE}"
```

After pushing the image, set the Bicep `nginxImage` parameter to `NGINX_CUSTOM_IMAGE`
(or to a pushed image digest reference) before deploying.
