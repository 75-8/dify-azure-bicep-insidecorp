@description('Resource location')
param location string

@description('ACA environment ID')
param acaEnvId string

@description('Nginx ACA storage resource name')
param nginxStorageName string

@description('SSRF proxy ACA storage resource name')
param ssrfProxyStorageName string

@description('Whether to provide a custom certificate')
param isProvidedCert bool = false

@description('Dify custom domain')
param acaDifyCustomerDomain string = ''

@description('Dify certificate resource ID')
param difyCertificateId string = ''

@description('ACA app minimum instance count')
param acaAppMinCount int = 0

@description('Allowed CIDR blocks for nginx ingress')
param allowedIngressCidrs array = [
  '10.0.0.0/8'
]

@description('OAuth2 Proxy container image')
param oauth2ProxyImage string = 'quay.io/oauth2-proxy/oauth2-proxy:v7.7.1'

@description('OAuth2 Proxy client ID (Entra App Registration)')
param oauth2ProxyClientId string

@description('OAuth2 Proxy client secret (Entra App Registration)')
@secure()
param oauth2ProxyClientSecret string

@description('OAuth2 Proxy tenant ID')
param oauth2ProxyTenantId string

@description('OAuth2 Proxy cookie secret')
@secure()
param oauth2ProxyCookieSecret string

var nginxAllowIpSecurityRestrictions = [for (cidr, i) in allowedIngressCidrs: {
  name: 'corp-allow-${i}'
  description: 'Allow corporate network CIDR ${cidr}'
  ipAddressRange: cidr
  action: 'Allow'
}]

// Change Nginx app resource definition
resource nginxApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'nginx'
  location: location
  properties: {
    environmentId: acaEnvId
    configuration: {
      ingress: {
        external: false
        targetPort: 4180
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        ipSecurityRestrictions: concat(nginxAllowIpSecurityRestrictions, [
          {
            name: 'deny-all'
            description: 'Deny all non-corporate sources'
            ipAddressRange: '0.0.0.0/0'
            action: 'Deny'
          }
        ])
        customDomains: isProvidedCert ? [
          {
            name: acaDifyCustomerDomain
            certificateId: difyCertificateId
          }
        ] : []
      }
    }
    template: {
      containers: [
        {
          name: 'nginx'
          image: 'nginx:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          volumeMounts: [
            {
              volumeName: 'nginxconf'
              mountPath: '/custom-nginx' // Change mount point
            }
          ]
          command: [
            '/bin/bash'
            '-c'
            'rm -rf /etc/nginx/modules && cp -rf /custom-nginx/* /etc/nginx/ && nginx -g "daemon off;"'
          ]
        }
        {
          name: 'oauth2-proxy'
          image: oauth2ProxyImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'OAUTH2_PROXY_PROVIDER'
              value: 'oidc'
            }
            {
              name: 'OAUTH2_PROXY_OIDC_ISSUER_URL'
              value: 'https://login.microsoftonline.com/${oauth2ProxyTenantId}/v2.0'
            }
            {
              name: 'OAUTH2_PROXY_CLIENT_ID'
              value: oauth2ProxyClientId
            }
            {
              name: 'OAUTH2_PROXY_CLIENT_SECRET'
              value: oauth2ProxyClientSecret
            }
            {
              name: 'OAUTH2_PROXY_COOKIE_SECRET'
              value: oauth2ProxyCookieSecret
            }
            {
              name: 'OAUTH2_PROXY_UPSTREAMS'
              value: 'http://localhost:80/'
            }
            {
              name: 'OAUTH2_PROXY_HTTP_ADDRESS'
              value: '0.0.0.0:4180'
            }
            {
              name: 'OAUTH2_PROXY_REDIRECT_URL'
              value: 'https://${acaDifyCustomerDomain}/oauth2/callback'
            }
            {
              name: 'OAUTH2_PROXY_EMAIL_DOMAINS'
              value: '*'
            }
            {
              name: 'OAUTH2_PROXY_COOKIE_SECURE'
              value: 'true'
            }
            {
              name: 'OAUTH2_PROXY_SET_XAUTHREQUEST'
              value: 'true'
            }
            {
              name: 'OAUTH2_PROXY_PASS_ACCESS_TOKEN'
              value: 'true'
            }
            {
              name: 'OAUTH2_PROXY_SKIP_PROVIDER_BUTTON'
              value: 'true'
            }
          ]
        }
      ]
      scale: {
        minReplicas: acaAppMinCount
        maxReplicas: 10
        rules: [
          {
            name: 'nginx'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
      volumes: [
        {
          name: 'nginxconf'
          storageType: 'AzureFile'
          storageName: nginxStorageName
        }
      ]
    }
  }
}

// Deploy SSRF proxy app
resource ssrfProxyApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'ssrfproxy'
  location: location
  properties: {
    environmentId: acaEnvId
    configuration: {
      ingress: {
        external: false
        targetPort: 3128
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'ssrfproxy'
          image: 'ubuntu/squid:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          volumeMounts: [
            {
              volumeName: 'ssrfproxy'
              mountPath: '/etc/squid'
            }
          ]
        }
      ]
      scale: {
        minReplicas: acaAppMinCount
        maxReplicas: 10
        rules: [
          {
            name: 'ssrfproxy'
            tcp: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
      volumes: [
        {
          name: 'ssrfproxy'
          storageType: 'AzureFile'
          storageName: ssrfProxyStorageName
        }
      ]
    }
  }
}

output difyAppUrl string = nginxApp.properties.configuration.ingress.fqdn
