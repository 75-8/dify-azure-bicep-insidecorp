# Get Container Apps endpoints
try {
    $apiUrl = az containerapp show --name api --resource-group $ResourceGroupName --query "properties.configuration.ingress.fqdn" -o tsv
    $webUrl = az containerapp show --name web --resource-group $ResourceGroupName --query "properties.configuration.ingress.fqdn" -o tsv
    $nginxUrl = az containerapp show --name nginx --resource-group $ResourceGroupName --query "properties.configuration.ingress.fqdn" -o tsv
    
    Write-Host "Dify Endpoints:" -ForegroundColor Cyan
    Write-Host "Main UI (Nginx): https://$nginxUrl" -ForegroundColor Green
    Write-Host "API: https://$apiUrl" -ForegroundColor Green
    Write-Host "Web: https://$webUrl" -ForegroundColor Green
} catch {
    Write-Warning "Failed to retrieve endpoint information: $_"
}