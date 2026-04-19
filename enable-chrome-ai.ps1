# Enable Chrome AI - Windows PowerShell script
# Main logic: patch Chrome Local State for region and AI flags

$ErrorActionPreference = "Stop"

# --- Logging helpers ---
function Write-InfoLog ($Message) { Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-SuccessLog ($Message) { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-ErrorLog ($Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-WarnLog ($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Stage ($Title) {
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor DarkCyan
    Write-Host ("          [ STAGE ] {0}" -f $Title) -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor DarkCyan
}

function Format-ValueForLog($Value) {
    if ($null -eq $Value) { return "<null>" }
    if ($Value -is [string]) { return "'$Value'" }
    return ($Value | ConvertTo-Json -Compress)
}

# --- Recursive patch helper ---
# Walk the JSON tree and force every is_glic_eligible to true.
function Update-GlicEligible($item, $changeStats) {
    $updatedCount = 0

    if ($null -eq $item) { return }
    
    if ($item -is [PSCustomObject]) {
        foreach ($prop in $item.PSObject.Properties) {
            if ($prop.Name -eq "is_glic_eligible") {
                $oldValueText = Format-ValueForLog $item.is_glic_eligible
                if ($item.is_glic_eligible -ne $true) {
                    $item.is_glic_eligible = $true
                    if (-not $changeStats.GlicChanged.ContainsKey($oldValueText)) {
                        $changeStats.GlicChanged[$oldValueText] = 0
                    }
                    $changeStats.GlicChanged[$oldValueText]++
                    $updatedCount++
                }
                else {
                    $changeStats.GlicAlreadyTrue++
                }
            }
            # Recursively process child values.
            $updatedCount += Update-GlicEligible $prop.Value $changeStats
        }
    }
    elseif ($item -is [System.Collections.IEnumerable] -and $item -isnot [string]) {
        foreach ($child in $item) {
            $updatedCount += Update-GlicEligible $child $changeStats
        }
    }

    return $updatedCount
}

# --- Process management ---
function Confirm-ChromeStop {
    $procs = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
    if (-not $procs) {
        Write-InfoLog "No running Chrome process was detected."
        return $true
    }

    Write-WarnLog "Detected running Chrome processes: $($procs.Count)"
    $answer = Read-Host "Terminate Chrome now? [y/n]"
    if ($answer -ine "y") {
        Write-WarnLog "User chose not to stop Chrome. Exiting without changes."
        return $false
    }

    Write-InfoLog "Stopping Chrome processes..."
    Stop-Process -Name "chrome" -Force
    Start-Sleep -Seconds 2
    Write-SuccessLog "Chrome processes stopped."
    return $true
}

# --- Patch config file ---
function Update-LocalStateFile ($filePath) {
    Write-Stage "PROCESSING FILE"
    Write-InfoLog "Processing: $filePath"
    $changedFields = New-Object System.Collections.Generic.List[string]
    $alreadyCompliantFields = New-Object System.Collections.Generic.List[string]
    $changeStats = [ordered]@{
        GlicChanged = @{}
        GlicAlreadyTrue = 0
    }
    
    # 1. Create backup
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupPath = "$filePath.backup.$timestamp"
    Copy-Item -Path $filePath -Destination $backupPath
    Write-InfoLog "Backup created: $backupPath"
    
    # 2. Read JSON
    $content = Get-Content -Raw -Path $filePath -Encoding UTF8
    $json = $content | ConvertFrom-Json
    
    # 3. Force region to US
    $oldVariationsCountry = Format-ValueForLog $json.variations_country
    if ($json.variations_country -ne "us") {
        $json.variations_country = "us"
        $changedFields.Add("variations_country: $oldVariationsCountry -> 'us'") | Out-Null
    }
    else {
        $alreadyCompliantFields.Add("variations_country already 'us'") | Out-Null
    }

    $currentConsistencyCountryValue = $json.variations_permanent_consistency_country
    $oldConsistencyCountry = if ($null -eq $currentConsistencyCountryValue) { "<null>" } else { $currentConsistencyCountryValue | ConvertTo-Json -Compress }
    $consistencyCountryUpdated = $false

    if ($null -eq $currentConsistencyCountryValue) {
        $json.variations_permanent_consistency_country = @($null, "us")
        $consistencyCountryUpdated = $true
    }
    elseif ($currentConsistencyCountryValue -is [string]) {
        $json.variations_permanent_consistency_country = @($currentConsistencyCountryValue, "us")
        $consistencyCountryUpdated = $true
    }
    elseif ($currentConsistencyCountryValue -is [System.Collections.IList] -or $currentConsistencyCountryValue.GetType().IsArray) {
        $newConsistencyCountryValue = @($currentConsistencyCountryValue)
        if ($newConsistencyCountryValue.Count -lt 2) {
            while ($newConsistencyCountryValue.Count -lt 2) {
                $newConsistencyCountryValue += $null
            }
        }

        if ($newConsistencyCountryValue[1] -ne "us") {
            $newConsistencyCountryValue[1] = "us"
            $json.variations_permanent_consistency_country = $newConsistencyCountryValue
            $consistencyCountryUpdated = $true
        }
    }
    else {
        $json.variations_permanent_consistency_country = @($currentConsistencyCountryValue, "us")
        $consistencyCountryUpdated = $true
    }

    if ($consistencyCountryUpdated) {
        $newConsistencyCountry = $json.variations_permanent_consistency_country | ConvertTo-Json -Compress
        $changedFields.Add("variations_permanent_consistency_country: $oldConsistencyCountry -> $newConsistencyCountry") | Out-Null
    }
    else {
        $alreadyCompliantFields.Add("variations_permanent_consistency_country already has country 'us' in slot 2") | Out-Null
    }
    
    # 4. Recursively enable AI eligibility flags
    $glicUpdatedCount = Update-GlicEligible $json $changeStats
    if ($glicUpdatedCount -gt 0) {
        foreach ($oldValue in $changeStats.GlicChanged.Keys | Sort-Object) {
            $changedFields.Add("is_glic_eligible: $oldValue x$($changeStats.GlicChanged[$oldValue]) -> true") | Out-Null
        }
    }
    if ($changeStats.GlicAlreadyTrue -gt 0) {
        $alreadyCompliantFields.Add("is_glic_eligible already true x$($changeStats.GlicAlreadyTrue)") | Out-Null
    }
    
    # 5. Save file
    $jsonContent = $json | ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText($filePath, $jsonContent)
    
    Write-InfoLog "Processing results as follows:"
    if ($alreadyCompliantFields.Count -gt 0) {
        Write-InfoLog "Already compliant fields:"
        foreach ($field in $alreadyCompliantFields) {
            Write-Host "  - $field"
        }
    }
    else {
        Write-InfoLog "Already compliant fields: none"
    }

    if ($changedFields.Count -gt 0) {
        Write-SuccessLog "Changed fields:"
        foreach ($field in $changedFields) {
            Write-Host "  - $field"
        }
    }
    else {
        Write-InfoLog "Changed fields: none. Target values were already present."
    }

    Write-SuccessLog "Patch complete."
}

# --- Main ---
Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "         Enable Chrome AI - Auto Config Tool" -ForegroundColor Cyan
Write-Host "=========================================================`n"

$localAppData = $env:LOCALAPPDATA
$chromePaths = @(
    "$localAppData\Google\Chrome\User Data\Local State",
    "$localAppData\Google\Chrome Beta\User Data\Local State",
    "$localAppData\Google\Chrome SxS\User Data\Local State",
    "$localAppData\Google\Chrome Dev\User Data\Local State"
)

# Find existing files
$foundPaths = $chromePaths | Where-Object { Test-Path $_ }

if ($null -eq $foundPaths -or $foundPaths.Count -eq 0) {
    Write-ErrorLog "Chrome Local State was not found. Make sure Chrome is installed and has been launched at least once."
    exit
}

Write-InfoLog "Found Chrome Local State paths: $($foundPaths.Count)"
foreach ($foundPath in $foundPaths) {
    Write-InfoLog " - $foundPath"
}

Write-Stage "PROCESS CHECK"
if (-not (Confirm-ChromeStop)) {
    exit 1
}

foreach ($path in $foundPaths) {
    try {
        Update-LocalStateFile $path
    } catch {
        Write-ErrorLog "Failed to process $path : $($_.Exception.Message)"
    }
}

Write-Stage "COMPLETED"
Write-SuccessLog "All operations completed."


# --- next steps ---
Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "                      NEXT STEPS" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-InfoLog "1. Restart Chrome and check Gemini in the sidebar or settings."
Write-InfoLog "   If not work, modify Chrome settings according to the guidelines in the README.md file."
Write-InfoLog "2. To restore, replace Local State with the generated .backup file."
Write-WarnLog "   Each run creates a new .backup file. Keep the latest backup file and use it if you need to restore Local State."
