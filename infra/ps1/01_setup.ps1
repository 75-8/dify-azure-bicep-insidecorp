param (
    [string]$ResourceGroupName = "",
    [switch]$SkipDeploy
)

# Resolve paths relative to this script so it works from any current directory
$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = Split-Path -Parent $scriptRoot
$parametersPath = Join-Path $scriptRoot "parameters.json"
$templateFilePath = Join-Path $scriptRoot ("main" + ".bicep")

# Set default resource group at the beginning of the script (after parameter declaration)
$env:AZURE_DEFAULTS_GROUP = $ResourceGroupName

# If resource group name is not specified, retrieve it from parameters file
if (Test-Path $parametersPath) {
    $params = Get-Content $parametersPath | ConvertFrom-Json
    if ($ResourceGroupName -eq "") {
        $location = $params.parameters.location.value
        $rgPrefix = $params.parameters.resourceGroupPrefix.value
        $ResourceGroupName = "$rgPrefix-$location"
    }
    Write-Host "Resource Group Name: $ResourceGroupName"
    $env:AZURE_DEFAULTS_GROUP = $ResourceGroupName

    $pgsqlUser = $params.parameters.pgsqlUser.value
    $pgsqlPassword = $params.parameters.pgsqlPassword.value

} else {
    Write-Error "parameters.json file not found. Please specify a resource group name."
    exit 1
}

# Check Azure CLI sign-in status
$loginStatus = az account show --query "name" -o tsv 2>$null
if (-not $loginStatus) {
    Write-Host "Logging in to Azure CLI..." -ForegroundColor Yellow
    az login
}