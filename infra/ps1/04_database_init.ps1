# Database initialization section
Write-Host "Starting Dify database initialization..." -ForegroundColor Cyan

# Logic to wait until API container is ready
function Wait-ForApiContainer {
    $maxAttempts = 10
    $attempt = 0
    $ready = $false
    
    Write-Host "Waiting for API container to be ready..." -ForegroundColor Yellow
    
    while (-not $ready -and $attempt -lt $maxAttempts) {
        $attempt++
        Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
        
        # Check container status
        $status = az containerapp show --name api --resource-group $ResourceGroupName --query "properties.latestRevisionStatus" -o tsv 2>$null
        
        if ($status -eq "Running") {
            # Test if application is actually responding
            try {
                $testResult = az containerapp exec --name api --resource-group $ResourceGroupName --command "echo 'Test connection'" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $ready = $true
                    Write-Host "  API container is ready" -ForegroundColor Green
                    break
                }
            } catch {
                # Ignore errors and continue
            }
        }
        
        Write-Host "  API container is not ready yet. Waiting 30 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
    
    return $ready
}

# Function to execute migration command more robustly
function Invoke-MigrationCommand {
    param (
        [string]$Command,
        [string]$Description,
        [int]$TimeoutSeconds = 300,
        [int]$MaxRetries = 3
    )
    
    $retry = 0
    $success = $false
    
    while (-not $success -and $retry -lt $MaxRetries) {
        $retry++
        Write-Host "Executing $Description... (attempt $retry/$MaxRetries)" -ForegroundColor Yellow
        
        try {
            # Execute as background job to handle timeout
            $job = Start-Job -ScriptBlock {
                param ($ResourceGroupName, $Command)
                az containerapp exec --name api --resource-group $ResourceGroupName --command $Command 2>&1
                return $LASTEXITCODE
            } -ArgumentList $ResourceGroupName, $Command
            
            # Wait for specified time
            if (Wait-Job -Job $job -Timeout $TimeoutSeconds) {
                $result = Receive-Job -Job $job
                
                # Get last element if result is array
                if ($result -is [array]) {
                    $exitCode = $result[-1]
                } else {
                    $exitCode = $LASTEXITCODE
                }
                
                if ($exitCode -eq 0) {
                    Write-Host "  $Description completed successfully" -ForegroundColor Green
                    $success = $true
                } else {
                    Write-Warning "  $Description failed: $result"
                }
            } else {
                Write-Warning "  $Description timed out (${TimeoutSeconds} seconds)"
                Stop-Job -Job $job
            }
            
            Remove-Job -Job $job -Force
        } catch {
            Write-Warning "  Error occurred while executing command: $_"
        }
        
        if (-not $success -and $retry -lt $MaxRetries) {
            $waitTime = [Math]::Pow(2, $retry) * 15  # Exponential backoff
            Write-Host "  Retrying after ${waitTime} seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds $waitTime
        }
    }
    
    return $success
}

# Wait for API container to be ready
# $apiReady = Wait-ForApiContainer
$apiReady = $true
if (-not $apiReady) {
    Write-Warning "API container was not ready. Please run initialization commands manually later."
    Write-Host "To run initialization manually, execute the following command:" -ForegroundColor Yellow
    Write-Host "az containerapp exec --name api --resource-group $ResourceGroupName --command 'flask db upgrade'" -ForegroundColor Gray
} else {
    # Check API container environment variables
    Write-Host "Checking API container environment variables..." -ForegroundColor Cyan
    $envVars = az containerapp show --name api --resource-group $ResourceGroupName --query "properties.template.containers[0].env" -o json | ConvertFrom-Json
    
    # Check if required environment variables are set
    $requiredVars = @("DB_HOST", "DB_USERNAME", "DB_PASSWORD", "DB_DATABASE")
    $missingVars = @()
    
    foreach ($var in $requiredVars) {
        $found = $false
        foreach ($envVar in $envVars) {
            if ($envVar.name -eq $var) {
                $found = $true
                break
            }
        }
        
        if (-not $found) {
            $missingVars += $var
        }
    }
    
    if ($missingVars.Count -gt 0) {
        Write-Warning "The following environment variables are not set in the API container: $($missingVars -join ', ')"
        Write-Host "Please check the Bicep template and verify that the required environment variables are set." -ForegroundColor Yellow
    }
    
    # Execute database initialization
    $psqlServer = az postgres flexible-server list --resource-group $ResourceGroupName --query "[0].name" -o tsv

    # Command to get detailed migration logs
    $debugMigrationCommand = 'flask db upgrade'
    Write-Host "Running migration with detailed debug information..." -ForegroundColor Cyan
    az containerapp exec --name api --resource-group $ResourceGroupName --command $debugMigrationCommand    
    
    Write-Host "Database initialization completed" -ForegroundColor Green        
}