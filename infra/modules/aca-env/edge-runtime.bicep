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

@description('Nginx image with the checked-in dynamic modules baked in')
param nginxImage string

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
        external: true
        targetPort: 80
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
          image: nginxImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
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
            'cp -rf /custom-nginx/conf.d /custom-nginx/*.conf /custom-nginx/*_params /custom-nginx/mime.types /etc/nginx/ && nginx -g "daemon off;"'
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
