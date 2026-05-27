# Repository Directory Structure

このファイルは、リポジトリ配下の主要ファイル/ディレクトリ構成を一覧化したものです。

```text
/workspace/dify-azure-bicep-insidecorp
├── README.md
├── deploy.ps1
├── docs
│   ├── agent-ci.md
│   ├── aoai-entra-auth-spec.md
│   ├── current-architecture-spec.yaml
│   ├── dify-azure-infra.drawio
│   ├── directory.md
│   ├── security_guardrails.md
│   └── task_list.md
├── main.bicep
├── modules
│   ├── aca-env.bicep
│   ├── fileshare.bicep
│   ├── network.bicep
│   ├── postgresql.bicep
│   ├── redis-cache.bicep
│   ├── storage.bicep
│   └── vnet.bicep
├── mountfiles
│   ├── nginx
│   │   ├── conf.d
│   │   │   └── default.conf
│   │   ├── fastcgi_params
│   │   ├── mime.types
│   │   ├── modules
│   │   │   ├── ngx_http_geoip_module-debug.so
│   │   │   ├── ngx_http_geoip_module.so
│   │   │   ├── ngx_http_image_filter_module-debug.so
│   │   │   ├── ngx_http_image_filter_module.so
│   │   │   ├── ngx_http_js_module-debug.so
│   │   │   ├── ngx_http_js_module.so
│   │   │   ├── ngx_http_xslt_filter_module-debug.so
│   │   │   ├── ngx_http_xslt_filter_module.so
│   │   │   ├── ngx_stream_geoip_module-debug.so
│   │   │   ├── ngx_stream_geoip_module.so
│   │   │   ├── ngx_stream_js_module-debug.so
│   │   │   └── ngx_stream_js_module.so
│   │   ├── nginx.conf
│   │   ├── proxy.conf
│   │   ├── scgi_params
│   │   └── uwsgi_params
│   ├── sandbox
│   │   └── python-requirements.txt
│   └── ssrfproxy
│       ├── conf.d
│       │   ├── debian.conf
│       │   └── rock.conf
│       ├── errorpage.css
│       └── squid.conf
├── parameters.example.json
└── terraform_old
    ├── README.md
    ├── aca-env.tf
    ├── fileshare.tf
    ├── fileshare_module
    │   ├── share.tf
    │   └── variables.tf
    ├── postgresql.tf
    ├── provider.tf
    ├── redis-cache.tf
    ├── var.tf
    └── vnet.tf
```
