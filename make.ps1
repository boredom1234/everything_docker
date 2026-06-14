# Thin PowerShell wrapper mirroring make.sh for native Windows users.
# Usage: .\make.ps1 <target> <tool>
# Example: .\make.ps1 build coderabbit

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("build","up","down","shell","rebuild","ps","clean","help")]
    [string]$Target,

    [Parameter(Position=1)]
    [ValidateSet("coderabbit","codex")]
    [string]$Tool = "coderabbit"
)

if ($Target -eq "help") {
    Write-Host "Usage: .\make.ps1 <target> <tool>  (env: WORKSPACE)"
    Write-Host ""
    Write-Host "Targets: build | up | down | shell | rebuild | ps | clean"
    Write-Host "Tools:   coderabbit | codex"
    Write-Host ""
    Write-Host "Current env: WORKSPACE=$env:WORKSPACE"
    exit 0
}

if (-not $env:WORKSPACE) {
    Write-Host "ERROR: WORKSPACE not set."
    Write-Host '       Set it like:  $env:WORKSPACE = "D:\Projects\my-app"'
    exit 1
}

# Normalize Windows path to forward slashes for Docker Desktop for Windows.
$ws = $env:WORKSPACE -replace '\\', '/'
$env:WORKSPACE = $ws

$compose = "docker compose -f $Tool/docker-compose.yml"

switch ($Target) {
    "build"   { Invoke-Expression "$compose build" }
    "up"      { Invoke-Expression "$compose up -d" }
    "down"    { Invoke-Expression "$compose down" }
    "shell"   { Invoke-Expression "$compose exec $Tool bash" }
    "rebuild" { Invoke-Expression "$compose build --no-cache" }
    "ps"      { Invoke-Expression "$compose ps" }
    "clean"   { Invoke-Expression "$compose down --rmi local -v" }
}
