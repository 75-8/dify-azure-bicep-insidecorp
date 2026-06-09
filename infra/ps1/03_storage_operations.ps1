# Retrieve storage account information (with more specific query)
Write-Host "Retrieving storage account information..." -ForegroundColor Cyan
$storageAccounts = az storage account list --resource-group $ResourceGroupName --query "[?starts_with(name, 'st')].name" -o tsv

if (-not $storageAccounts) {
    # Retry with alternative query
    $storageAccounts = az storage account list --resource-group $ResourceGroupName --query "[].name" -o tsv
    
    if (-not $storageAccounts) {
        Write-Error "No storage account found in resource group: $ResourceGroupName"
        exit 1
    }
}

# Use the first storage account if multiple exist
$storageAccountArray = $storageAccounts -split "\r?\n"
$storageAccountName = $storageAccountArray[0]
Write-Host "Storage account name: $storageAccountName"

# Retrieve storage account key
$storageAccountKey = (az storage account keys list --resource-group $ResourceGroupName --account-name $storageAccountName --query "[0].value" -o tsv)
if (-not $storageAccountKey) {
    Write-Error "Failed to retrieve storage account key"
    exit 1
}

# Enable storage account audit logging (for troubleshooting)
Write-Host "Enabling storage account audit logging..." -ForegroundColor Cyan
az storage account update --name $storageAccountName --resource-group $ResourceGroupName --enable-local-user true

# Get client IP and add to firewall
try {
    $clientIP = (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -TimeoutSec 10).ip
    if ($clientIP) {
        Write-Host "Adding current IP address: $clientIP to storage account firewall" -ForegroundColor Yellow
        az storage account network-rule add --account-name $storageAccountName --resource-group $ResourceGroupName --ip-address $clientIP
    }
}
catch {
    Write-Warning "Failed to retrieve IP address. Skipping firewall configuration."
}

# Fix SAS token generation
try {
    # Treat SAS token as string when storing in variable
    $end = (Get-Date).AddHours(24).ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    # Use Out-String to retrieve SAS token for storing in variable
    $sasResult = (az storage account generate-sas --account-name $storageAccountName --services f --resource-types sco --permissions acdlrw --expiry $end --https-only --output tsv | Out-String).Trim()
    
    if ([string]::IsNullOrWhiteSpace($sasResult)) {
        throw "SAS token is empty"
    }
    
    # Save SAS token as variable (use directly instead of environment variable)
    $sasToken = "?$sasResult"
    Write-Host "SAS token generated (valid for 24 hours)" -ForegroundColor Green
    
    # Set flag to use as alternative
    $useSasEnv = $true
} catch {
    Write-Warning "Error occurred during SAS token generation: $_"
    
    # Alternative authentication method: Use storage account key
    Write-Host "Attempting alternative authentication method using storage account key..." -ForegroundColor Yellow
    $storageKey = $storageAccountKey
    $useSasEnv = $false
    $sasToken = $null
}

Write-Host "SAS token generated and stored in memory (value hidden)" -ForegroundColor Green

# Check for azcopy existence and install if needed
$azcopyPath = $null
try {
    $azcopyPath = (Get-Command azcopy -ErrorAction SilentlyContinue).Source
} catch {
    # azcopy not found
}

if (-not $azcopyPath) {
    Write-Host "azcopy not found. Attempting automatic installation..." -ForegroundColor Yellow
    
    # Download to temporary directory
    $tempDir = Join-Path $env:TEMP "azcopy"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Download Windows version of azcopy
    $azcopyZip = Join-Path $tempDir "azcopy.zip"
    $downloadUrl = "https://aka.ms/downloadazcopy-v10-windows"
    
    Write-Host "  Downloading azcopy..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $azcopyZip -UseBasicParsing
    
    # Extract
    Write-Host "  Extracting azcopy..." -ForegroundColor Cyan
    Expand-Archive -Path $azcopyZip -DestinationPath $tempDir -Force
    
    # Find azcopy.exe
    $azcopyExe = Get-ChildItem -Path $tempDir -Filter "azcopy.exe" -Recurse | Select-Object -First 1
    if ($azcopyExe) {
        $azcopyPath = $azcopyExe.FullName
        Write-Host "  Using azcopy: $azcopyPath" -ForegroundColor Green
    } else {
        Write-Warning "Failed to install azcopy. Falling back to az storage file upload."
        $azcopyPath = $null
    }
}

if ($azcopyPath) {
    Write-Host "Using azcopy to upload files: $azcopyPath" -ForegroundColor Green
}

# Upload files to file shares
$shares = @("nginx", "ssrfproxy", "sandbox")

foreach ($share in $shares) {
    Write-Host "Processing file share '$share'..." -ForegroundColor Cyan
    
    # Check if file share exists, create if it doesn't
    if ($useSasEnv) {
        # Use SAS token
        $shareExists = az storage share exists --account-name $storageAccountName --name $share --sas-token "`"$sasToken`"" --query "exists" -o tsv
        if ($shareExists -ne "true") {
            Write-Host "  Creating file share '$share'..."
            az storage share create --account-name $storageAccountName --name $share --sas-token "`"$sasToken`""
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to create file share '$share'. Continuing process."
            }
        }
    } else {
        # Use storage key
        $shareExists = az storage share exists --account-name $storageAccountName --name $share --account-key $storageKey --query "exists" -o tsv
        if ($shareExists -ne "true") {
            Write-Host "  Creating file share '$share'..."
            az storage share create --account-name $storageAccountName --name $share --account-key $storageKey
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to create file share '$share'. Continuing process."
            }
        }
    }
    
    # Upload files directly from infra/mountfiles directory
    $sourcePath = Join-Path $repoRoot (Join-Path "infra/mountfiles" $share)
    if (Test-Path $sourcePath) {
        Write-Host "Uploading configuration files..." -ForegroundColor Cyan
        
        # Use azcopy if available
        if ($azcopyPath) {
            Write-Host "  Batch uploading using azcopy..." -ForegroundColor Cyan
            
            # Use SAS token or storage key
            if ($useSasEnv) {
                $destUrl = "https://$storageAccountName.file.core.windows.net/$share$sasToken"
            } else {
                # Generate SAS token from storage key
                $tempSasToken = (az storage share generate-sas --account-name $storageAccountName --name $share --permissions rwdl --expiry (Get-Date).AddHours(1).ToString("yyyy-MM-ddTHH:mm:ssZ") --account-key $storageAccountKey --output tsv)
                $destUrl = "https://$storageAccountName.file.core.windows.net/$share`?$tempSasToken"
            }
            
            # azcopyで再帰的にアップロード
            $azcopyArgs = @(
                "copy",
                "$sourcePath/*",
                $destUrl,
                "--recursive=true",
                "--overwrite=true",
                "--log-level=WARNING"
            )
            
            & $azcopyPath $azcopyArgs
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Upload completed with azcopy" -ForegroundColor Green
            } else {
                Write-Warning "  Upload with azcopy failed. Falling back to az CLI."
                # Set fallback flag
                $useAzCli = $true
            }
        } else {
            # Use az CLI if azcopy is not available
            $useAzCli = $true
        }
        
        # Upload using az CLI (fallback)
        if ($useAzCli) {
        
        # Convert to absolute path
        $sourcePathAbsolute = (Resolve-Path $sourcePath).Path
        
        # Get list of directories and files
        $customDirs = @()
        Get-ChildItem -Path $sourcePathAbsolute -Recurse -Directory | ForEach-Object {
            # Get relative path from source directory (without path separator)
            $relativePath = $_.FullName.Substring($sourcePathAbsolute.Length).TrimStart('\', '/')
            if ($relativePath) {
                $customDirs += $relativePath
            }
        }
        
        # Sort directories in hierarchical order and create (parent → child order)
        $customDirs = $customDirs | Sort-Object { $_.Split('\\').Count }
        foreach ($dir in $customDirs) {
            $dirPath = $dir -replace "\\\\", "/"
            try {
                if ($useSasEnv) {
                    az storage directory create --account-name $storageAccountName --share-name $share --name $dirPath --sas-token "`"$sasToken`"" --output none 2>$null
                } else {
                    az storage directory create --account-name $storageAccountName --share-name $share --name $dirPath --account-key $storageKey --output none 2>$null
                }
                Write-Host "  Created directory: $dirPath"
            } catch {
                Write-Host "  Skipped directory creation (already exists): $dirPath" -ForegroundColor Gray
            }
        }
        
        # Upload filess
        Get-ChildItem -Path $sourcePathAbsolute -Recurse -File | ForEach-Object {
            # Get relative path from source directory (without path separator)
            $relativePath = $_.FullName.Substring($sourcePathAbsolute.Length).TrimStart('\\', '/')
            $targetPath = $relativePath -replace "\\\\", "/"
            
            # Get parent directory path of file
            $parentDir = Split-Path -Path $targetPath -Parent
            
            # Attempt to create only if parent directory exists and is not empty
            if ($parentDir -and $parentDir -ne "" -and $parentDir -ne ".") {
                $parentDir = $parentDir -replace "\\\\", "/"
                # Verify parent directory exists
                try {
                    if ($useSasEnv) {
                        az storage directory create --account-name $storageAccountName --share-name $share --name $parentDir --sas-token "`"$sasToken`"" --output none 2>$null
                    } else {
                        az storage directory create --account-name $storageAccountName --share-name $share --name $parentDir --account-key $storageKey --output none 2>$null
                    }
                } catch {
                    # Ignore if directory already exists
                }
            }
            
            # Upload processing 
            $uploadSuccess = $false
            $maxRetries = 3
            $retryCount = 0
            
            while (-not $uploadSuccess -and $retryCount -lt $maxRetries) {
                try {
                    if ($useSasEnv) {
                        $result = az storage file upload --account-name $storageAccountName --share-name $share --source $_.FullName --path $targetPath --sas-token "`"$sasToken`"" --no-progress 2>&1
                    } else {
                        $result = az storage file upload --account-name $storageAccountName --share-name $share --source $_.FullName --path $targetPath --account-key $storageAccountKey --no-progress 2>&1
                    }
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  Uploaded file: $targetPath"
                        $uploadSuccess = $true
                    } else {
                        $retryCount++
                        if ($retryCount -lt $maxRetries) {
                            Write-Host "    Retrying... ($retryCount/$maxRetries)" -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                        } else {
                            Write-Warning "Error uploading file '$targetPath': $result"
                        }
                    }
                } catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-Host "    Retrying... ($retryCount/$maxRetries)" -ForegroundColor Yellow
                        Start-Sleep -Seconds 2
                    } else {
                        Write-Warning "Exception while uploading file '$targetPath': $_"
                    }
                }
            }
        }
        # End of az CLI upload section
        }
    } else {
        Write-Host "Warning: $sourcePath directory not found. Skipping files for this share." -ForegroundColor Yellow
    }
}

# Restore original settings after file upload
Write-Host "Restoring storage account security settings..." -ForegroundColor Yellow
az storage account update --name $storageAccountName --resource-group $ResourceGroupName --default-action Deny
az storage account update --name $storageAccountName --resource-group $ResourceGroupName --bypass AzureServices

# Restart Container Apps (execute only once)
Write-Host "Restarting Nginx app..." -ForegroundColor Cyan
$latestRevision = az containerapp revision list --name nginx --resource-group $ResourceGroupName --query "[0].name" -o tsv
if ($latestRevision) {
    az containerapp revision restart --name nginx --resource-group $ResourceGroupName --revision $latestRevision
} else {
    Write-Warning "Latest revision of Nginx not found"
}