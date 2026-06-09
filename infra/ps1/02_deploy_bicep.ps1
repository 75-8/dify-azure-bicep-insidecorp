# Deploy Bicep template if not skipping
if (-not $SkipDeploy) {
    Write-Host "Deploying Bicep template..." -ForegroundColor Cyan
    az deployment sub create --location $location --template-file $templateFilePath --parameters $parametersPath
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Bicep deployment failed."
        exit 1
    }
}

# Check current Azure context
Write-Host "Checking Azure subscription information..." -ForegroundColor Cyan
$currentSubscription = az account show --query "name" -o tsv
Write-Host "Current subscription: $currentSubscription"

# Verify resource group exists
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "true") {
    Write-Host "Resource group found: $ResourceGroupName" -ForegroundColor Green
} else {
    Write-Error "Resource group does not exist: $ResourceGroupName"
    exit 1
}