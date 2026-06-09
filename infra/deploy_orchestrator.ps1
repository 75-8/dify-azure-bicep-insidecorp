param (
    [string]$ResourceGroupName = "",
    [switch]$SkipDeploy
)
# Orchestrator script for Dify deployment on Azure
# Calls modular scripts in sequence: setup, bicep deployment, storage operations, database init, endpoint retrieval

# Set error preference to stop on errors
$ErrorActionPreference = 'Stop'

# Source the modular scripts
. "$PSScriptRoot/ps1/01_setup.ps1"
. "$PSScriptRoot/ps1/02_deploy_bicep.ps1"
. "$PSScriptRoot/ps1/03_storage_operations.ps1"
. "$PSScriptRoot/ps1/04_database_init.ps1"
. "$PSScriptRoot/ps1/05_get_endpoints.ps1"

Write-Host "Deployment completed!" -ForegroundColor Green