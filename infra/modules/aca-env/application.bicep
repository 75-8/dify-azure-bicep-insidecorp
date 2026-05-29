@description('Resource location')
param location string

@description('ACA environment ID')
param acaEnvId string

@description('Storage account name')
param storageAccountName string

@description('Storage account key')
@secure()
param storageAccountKey string

@description('Storage container name')
param storageContainerName string

@description('Redis host name')
param redisHostName string = ''

@description('Redis primary key')
@secure()
param redisPrimaryKey string = ''

@description('PostgreSQL server fully qualified domain name')
param postgresServerFqdn string

@description('PostgreSQL administrator login')
param postgresAdminLogin string

@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

@description('Postgres Dify database name')
param postgresDifyDbName string

@description('Postgres Vector database name')
param postgresVectorDbName string

@description('Sandbox ACA storage resource name')
param sandboxStorageName string

@description('Plugin ACA storage resource name')
param pluginStorageName string

@description('ACA app minimum instance count')
param acaAppMinCount int = 0

@description('Dify API image')
param difyApiImage string

@description('Dify Sandbox image')
param difySandboxImage string

@description('Dify Web image')
param difyWebImage string

@description('Dify Plugin Daemon image')
param difyPluginDaemonImage string

@description('Blob endpoint')
param blobEndpoint string

// Deploy Sandbox app
resource sandboxApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'sandbox'
  location: location
  properties: {
    environmentId: acaEnvId
    configuration: {
      ingress: {
        external: false
        targetPort: 8194
        transport: 'tcp'
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
          name: 'langgenius'
          image: difySandboxImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'API_KEY'
              value: 'dify-sandbox'
            }
            {
              name: 'GIN_MODE'
              value: 'release'
            }
            {
              name: 'WORKER_TIMEOUT'
              value: '15'
            }
            {
              name: 'ENABLE_NETWORK'
              value: 'true'
            }
            {
              name: 'HTTP_PROXY'
              value: 'http://ssrfproxy:3128'
            }
            {
              name: 'HTTPS_PROXY'
              value: 'http://ssrfproxy:3128'
            }
            {
              name: 'SANDBOX_PORT'
              value: '8194'
            }
          ]
          volumeMounts: [
            {
              volumeName: 'sandbox'
              mountPath: '/dependencies'
            }
          ]
        }
      ]
      scale: {
        minReplicas: acaAppMinCount
        maxReplicas: 10
        rules: [
          {
            name: 'sandbox'
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
          name: 'sandbox'
          storageType: 'AzureFile'
          storageName: sandboxStorageName
        }
      ]
    }
  }
}

// Deploy Worker app
resource workerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'worker'
  location: location
  properties: {
    environmentId: acaEnvId
    configuration: {}
    template: {
      containers: [
        {
          name: 'langgenius'
          image: difyApiImage
          resources: {
            cpu: json('2')
            memory: '4Gi'
          }
          env: [
            {
              name: 'MODE'
              value: 'worker'
            }
            {
              name: 'LOG_LEVEL'
              value: 'INFO'
            }
            {
              name: 'SECRET_KEY'
              value: 'dify-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U'
            }
            {
              name: 'DB_USERNAME'
              value: postgresAdminLogin
            }
            {
              name: 'DB_PASSWORD'
              value: postgresAdminPassword
            }
            {
              name: 'DB_HOST'
              value: postgresServerFqdn
            }
            {
              name: 'DB_PORT'
              value: '5432'
            }
            {
              name: 'DB_DATABASE'
              value: postgresDifyDbName
            }
            {
              name: 'REDIS_HOST'
              value: redisHostName
            }
            {
              name: 'REDIS_PORT'
              value: '6379'
            }
            {
              name: 'REDIS_PASSWORD'
              value: redisPrimaryKey
            }
            {
              name: 'REDIS_USE_SSL'
              value: 'false'
            }
            {
              name: 'REDIS_DB'
              value: '0'
            }
            {
              name: 'CELERY_BROKER_URL'
              value: empty(redisHostName) ? '' : 'redis://:${redisPrimaryKey}@${redisHostName}:6379/1'
            }
            {
              name: 'STORAGE_TYPE'
              value: 'azure-blob'
            }
            {
              name: 'AZURE_BLOB_ACCOUNT_NAME'
              value: storageAccountName
            }
            {
              name: 'AZURE_BLOB_ACCOUNT_KEY'
              value: storageAccountKey
            }
            {
              name: 'AZURE_BLOB_ACCOUNT_URL'
              value: blobEndpoint
            }
            {
              name: 'AZURE_BLOB_CONTAINER_NAME'
              value: storageContainerName
            }
            {
              name: 'VECTOR_STORE'
              value: 'pgvector'
            }
            {
              name: 'PGVECTOR_HOST'
              value: postgresServerFqdn
            }
            {
              name: 'PGVECTOR_PORT'
              value: '5432'
            }
            {
              name: 'PGVECTOR_USER'
              value: postgresAdminLogin
            }
            {
              name: 'PGVECTOR_PASSWORD'
              value: postgresAdminPassword
            }
            {
              name: 'PGVECTOR_DATABASE'
              value: postgresVectorDbName
            }
            {
              name: 'INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH'
              value: '1000'
            }
            {
              name: 'PLUGIN_DAEMON_URL'
              value: 'http://plugin:5002'
            }
            {
              name: 'PLUGIN_DAEMON_KEY'
              value: 'lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi'
            }
            {
              name: 'INNER_API_KEY_FOR_PLUGIN'
              value: '-QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1'
            }
          ]
        }
      ]
      scale: {
        minReplicas: acaAppMinCount
        maxReplicas: 10
        rules: [
          {
            name: 'worker'
            tcp: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

// Deploy API app
resource apiApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'api'
  location: location
  properties: {
    environmentId: acaEnvId
    configuration: {
      ingress: {
        external: false
        targetPort: 5001
        exposedPort: 5001
        transport: 'tcp'
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
          name: 'langgenius'
          image: difyApiImage
          resources: {
            cpu: json('2')
            memory: '4Gi'
          }
          env: [
            {
              name: 'MODE'
              value: 'api'
            }
            {
              name: 'LOG_LEVEL'
              value: 'INFO'
            }
            {
              name: 'SECRET_KEY'
              value: 'dify-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U'
            }
            {
              name: 'CONSOLE_WEB_URL'
              value: ''
            }
            {
              name: 'INIT_PASSWORD'
              value: ''
            }
            {
              name: 'CONSOLE_API_URL'
              value: ''
            }
            {
              name: 'SERVICE_API_URL'
              value: ''
            }
            {
              name: 'APP_WEB_URL'
              value: ''
            }
            {
              name: 'FILES_URL'
              value: ''
            }
            {
              name: 'FILES_ACCESS_TIMEOUT'
              value: '300'
            }
            {
              name: 'MIGRATION_ENABLED'
              value: 'true'
            }
            {
              name: 'SENTRY_DSN'
              value: ''
            }
            {
              name: 'SENTRY_TRACES_SAMPLE_RATE'
              value: '1.0'
            }
            {
              name: 'SENTRY_PROFILES_SAMPLE_RATE'
              value: '1.0'
            }
            {
              name: 'DB_USERNAME'
              value: postgresAdminLogin
            }
            {
              name: 'DB_PASSWORD'
              value: postgresAdminPassword
            }
            {
              name: 'DB_HOST'
              value: postgresServerFqdn
            }
            {
              name: 'DB_PORT'
              value: '5432'
            }
            {
              name: 'DB_DATABASE'
              value: postgresDifyDbName
            }
            {
              name: 'WEB_API_CORS_ALLOW_ORIGINS'
              value: '*'
            }
            {
              name: 'CONSOLE_CORS_ALLOW_ORIGINS'
              value: '*'
            }
            {
              name: 'REDIS_HOST'
              value: redisHostName
            }
            {
              name: 'REDIS_PORT'
              value: '6379'
            }
            {
              name: 'REDIS_PASSWORD'
              value: redisPrimaryKey
            }
            {
              name: 'REDIS_USE_SSL'
              value: 'false'
            }
            {
              name: 'REDIS_DB'
              value: '0'
            }
            {
              name: 'CELERY_BROKER_URL'
              value: empty(redisHostName) ? '' : 'redis://:${redisPrimaryKey}@${redisHostName}:6379/1'
            }
            {
              name: 'STORAGE_TYPE'
              value: 'azure-blob'
            }
            {
              name: 'AZURE_BLOB_ACCOUNT_NAME'
              value: storageAccountName
            }
            {
              name: 'AZURE_BLOB_ACCOUNT_KEY'
              value: storageAccountKey
            }
            {
              name: 'AZURE_BLOB_ACCOUNT_URL'
              value: blobEndpoint
            }
            {
              name: 'AZURE_BLOB_CONTAINER_NAME'
              value: storageContainerName
            }
            {
              name: 'VECTOR_STORE'
              value: 'pgvector'
            }
            {
              name: 'PGVECTOR_HOST'
              value: postgresServerFqdn
            }
            {
              name: 'PGVECTOR_PORT'
              value: '5432'
            }
            {
              name: 'PGVECTOR_USER'
              value: postgresAdminLogin
            }
            {
              name: 'PGVECTOR_PASSWORD'
              value: postgresAdminPassword
            }
            {
              name: 'PGVECTOR_DATABASE'
              value: postgresVectorDbName
            }
            {
              name: 'CODE_EXECUTION_API_KEY'
              value: 'dify-sandbox'
            }
            {
              name: 'CODE_EXECUTION_ENDPOINT'
              value: 'http://sandbox:8194'
            }
            {
              name: 'CODE_MAX_NUMBER'
              value: '9223372036854775807'
            }
            {
              name: 'CODE_MIN_NUMBER'
              value: '-9223372036854775808'
            }
            {
              name: 'CODE_MAX_STRING_LENGTH'
              value: '80000'
            }
            {
              name: 'TEMPLATE_TRANSFORM_MAX_LENGTH'
              value: '80000'
            }
            {
              name: 'CODE_MAX_OBJECT_ARRAY_LENGTH'
              value: '30'
            }
            {
              name: 'CODE_MAX_STRING_ARRAY_LENGTH'
              value: '30'
            }
            {
              name: 'CODE_MAX_NUMBER_ARRAY_LENGTH'
              value: '1000'
            }
            {
              name: 'INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH'
              value: '1000'
            }
            {
              name: 'PLUGIN_DAEMON_URL'
              value: 'http://plugin:5002'
            }
            {
              name: 'PLUGIN_DAEMON_KEY'
              value: 'lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi'
            }
            {
              name: 'INNER_API_KEY_FOR_PLUGIN'
              value: '-QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1'
            }
          ]
        }
      ]
      scale: {
        minReplicas: acaAppMinCount
        maxReplicas: 10
        rules: [
          {
            name: 'api'
            tcp: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

// Deploy Plugin daemon app
resource pluginDaemonApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'plugin'
  location: location
  properties: {
    environmentId: acaEnvId
    configuration: {
      ingress: {
        external: false
        targetPort: 5002
        exposedPort: 5002
        transport: 'tcp'
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
          name: 'langgenius'
          image: difyPluginDaemonImage
          resources: {
            cpu: json('2')
            memory: '4Gi'
          }
          volumeMounts: [
            {
              volumeName: 'pluginstorage'
              mountPath: '/app/storage'
            }
          ]
          env: [
            {
              name: 'GIN_MODE'
              value: 'release'
            }
            {
              name: 'SERVER_PORT'
              value: '5002'
            }
            {
              name: 'SERVER_KEY'
              value: 'lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi'
            }
            {
              name: 'PLATFORM'
              value: 'local'
            }
            {
              name: 'DIFY_INNER_API_KEY'
              value: '-QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1'
            }
            {
              name: 'DIFY_INNER_API_URL'
              value: 'http://api:5001'
            }
            {
              name: 'DB_USERNAME'
              value: postgresAdminLogin
            }
            {
              name: 'DB_PASSWORD'
              value: postgresAdminPassword
            }
            {
              name: 'DB_HOST'
              value: postgresServerFqdn
            }
            {
              name: 'DB_PORT'
              value: '5432'
            }
            {
              name: 'DB_DATABASE'
              value: postgresDifyDbName
            }
            {
              name: 'REDIS_HOST'
              value: redisHostName
            }
            {
              name: 'REDIS_PORT'
              value: '6379'
            }
            {
              name: 'REDIS_PASSWORD'
              value: redisPrimaryKey
            }
            {
              name: 'REDIS_USE_SSL'
              value: 'false'
            }
            {
              name: 'REDIS_DB'
              value: '0'
            }
            {
              name: 'CELERY_BROKER_URL'
              value: empty(redisHostName) ? '' : 'redis://:${redisPrimaryKey}@${redisHostName}:6379/1'
            }
            {
              name: 'PLUGIN_STORAGE_TYPE'
              value: 'local'
            }
            {
              name: 'PLUGIN_WORKING_PATH'
              value: 'cwd'
            }
            {
              name: 'PLUGIN_INSTALLED_PATH'
              value: 'plugin'
            }
            {
              name: 'DB_SSL_MODE'
              value: 'require'
            }
            {
              name: 'PLUGIN_WEBHOOK_ENABLED'
              value: 'true'
            }
            {
              name: 'PLUGIN_REMOTE_INSTALLING_ENABLED'
              value: 'false'
            }
            {
              name: 'PLUGIN_REMOTE_INSTALLING_HOST'
              value: '127.0.0.1'
            }
            {
              name: 'PLUGIN_REMOTE_INSTALLING_PORT'
              value: '5003'
            }
          ]
        }
      ]
      scale: {
        minReplicas: acaAppMinCount
        maxReplicas: 10
        rules: [
          {
            name: 'api'
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
          name: 'pluginstorage'
          storageType: 'AzureFile'
          storageName: pluginStorageName
        }
      ]
    }
  }
}

// Deploy Web app
resource webApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'web'
  location: location
  properties: {
    environmentId: acaEnvId
    configuration: {
      ingress: {
        external: false
        targetPort: 3000
        exposedPort: 3000
        transport: 'tcp'
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
          name: 'langgenius'
          image: difyWebImage
          resources: {
            cpu: json('1')
            memory: '2Gi'
          }
          env: [
            {
              name: 'CONSOLE_API_URL'
              value: ''
            }
            {
              name: 'APP_API_URL'
              value: ''
            }
            {
              name: 'SENTRY_DSN'
              value: ''
            }
            {
              name: 'MARKETPLACE_API_URL'
              value: 'https://marketplace.dify.ai'
            }
            {
              name: 'MARKETPLACE_URL'
              value: 'https://marketplace.dify.ai'
            }
          ]
        }
      ]
      scale: {
        minReplicas: acaAppMinCount
        maxReplicas: 10
        rules: [
          {
            name: 'web'
            tcp: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}
