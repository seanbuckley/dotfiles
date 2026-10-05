# dotfiles-windows UI Helpers
# Standardized functions for consistent visual feedback
#
# What:     Write-Success / Write-Info / Write-Header / Write-Task* etc., so every
#           script prints the same symbols and colours (DECISIONS.md 1).
# Loaded:   first, by the profile; standalone scripts load it themselves.
# Gotchas:  contains emoji. Windows PowerShell 5.1 reads UTF-8 files without a
#           BOM as the local code page, so the symbols may look garbled there.
# Fate:     port (P4.01).

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-WarningMessage {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("--- {0} ---" -f $Title.ToUpper()) -ForegroundColor Blue
}

function Write-TaskStart {
    param([string]$Description)
    Write-Host -NoNewline ("[....] {0}" -f $Description).PadRight(45)
}

function Write-TaskComplete {
    Write-Host "✅" -ForegroundColor Green
}

function Write-TaskError {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Title)
    $line = "=" * 50
    Write-Host "`n$line" -ForegroundColor Blue
    Write-Host ("  {0}" -f $Title.ToUpper()) -ForegroundColor White
    Write-Host "$line`n" -ForegroundColor Blue
}
