Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$source = 'C:\Users\13403\Documents\Obsidian Vault'
$obsidianAppFolder = [string]::Concat([char]0x7b14, [char]0x8bb0)
$targets = @(
    'C:\Users\13403\iCloudDrive\Obsidian\ObsidianVault-iPad',
    (Join-Path (Join-Path 'C:\Users\13403\iCloudDrive\iCloud~md~obsidian' $obsidianAppFolder) 'ObsidianVault-iPad')
)
$logDir = Join-Path $source '.obsidian\sync-logs'

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logFile = Join-Path $logDir "icloud-push-$timestamp.log"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Source vault not found: $source"
}

foreach ($target in $targets) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    "[$(Get-Date -Format o)] Push start: $source -> $target" | Out-File -FilePath $logFile -Append -Encoding utf8
    $robocopyOutput = & robocopy $source $target /MIR /COPY:DAT /DCOPY:DAT /R:2 /W:2 /XJ /FFT /NP /XD '.git' 'sync-logs'
    $exitCode = $LASTEXITCODE

    $robocopyOutput | Out-File -FilePath $logFile -Append -Encoding utf8
    "[$(Get-Date -Format o)] Robocopy exit code: $exitCode" | Out-File -FilePath $logFile -Append -Encoding utf8

    if ($exitCode -ge 8) {
        throw "Robocopy failed for target '$target' with exit code $exitCode. See $logFile"
    }

    $targetLogDir = Join-Path $target '.obsidian\sync-logs'
    if (Test-Path -LiteralPath $targetLogDir) {
        Remove-Item -LiteralPath $targetLogDir -Recurse -Force
    }
}

"[$(Get-Date -Format o)] Push complete" | Out-File -FilePath $logFile -Append -Encoding utf8
