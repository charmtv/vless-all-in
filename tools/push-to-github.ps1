#Requires -Version 5.1
# Auto-retry: git push origin main. Run from repo root:
#   powershell -ExecutionPolicy Bypass -File .\tools\push-to-github.ps1
# Env: GIT_PUSH_RETRIES (default 8), GIT_PUSH_DELAY_SEC (default 4)
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$remote = "origin"
$branch = "main"
if ($env:GIT_PUSH_RETRIES) { $maxAttempts = [int]$env:GIT_PUSH_RETRIES } else { $maxAttempts = 8 }
if ($env:GIT_PUSH_DELAY_SEC) { $delaySec = [int]$env:GIT_PUSH_DELAY_SEC } else { $delaySec = 4 }

$st = git status --porcelain 2>$null
if ($st) {
    Write-Host "[push] Uncommitted changes: staging and commit..."
    git add -A
    git diff --cached --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        $msg = "chore: sync " + (Get-Date -Format "yyyy-MM-dd HH:mm")
        git commit -m $msg 2>&1 | Write-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[push] commit failed; fix and retry."
            exit 1
        }
    }
}

for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "[push] attempt $i of ${maxAttempts}: git push ${remote} ${branch}"
    git push $remote $branch 2>&1 | Write-Host
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[push] OK."
        exit 0
    }
    Write-Host "[push] failed; sleep ${delaySec}s..."
    Start-Sleep -Seconds $delaySec
}

Write-Host "[push] giving up. Try VPN or: git remote set-url origin git@github.com:charmtv/vless-all-in.git"
exit 1
