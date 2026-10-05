# Personal Aliases
#
# What:     Short commands: folder jumps, Explorer, hashes, unzip, reboot,
#           profile reload, winget/eza shortcuts.
# Loaded:   eagerly by the profile (section 5).
# Gotchas:  `dev` hardcodes C:/dev and `note` hardcodes the Chocolatey Notepad++
#           path (dotfiles-windows#33). Protect-String is broken
#           (dotfiles-windows#52). `reload` calls refreshenv, which only exists
#           when Chocolatey is installed.
# Fate:     rewrite alongside the Linux aliases, with matching names (P4.01).

# Traversing directories
function cd.. { Set-Location .. }
function .. { Set-Location .. }
function cd... { Set-Location ..\.. }
function ... { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }
function .... { Set-Location ..\..\.. }
function home { Set-Location $env:USERPROFILE }
function ~ { Set-Location $env:USERPROFILE }
function dev { Set-Location C:/dev/ }
function ll { Get-ChildItem -Path $pwd -File }

# Recursive directory listings
# Does the the rough equivalent of dir /s /b. For example, dirs *.png is dir /s /b *.png
function dirs {
    if ($args.Count -gt 0) {
        Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    }
    else {
        Get-ChildItem -Recurse | Foreach-Object FullName
    }
}

# Aliases to open Explorer at the current directory or a given path. Equivalent to `ii [path]`
function Open-Here {
    param([string]$Path = '.')
    Invoke-Item $Path
}
Set-Alias e        Open-Here
Set-Alias exp      Open-Here
Set-Alias open     Open-Here
Set-Alias explore  Open-Here
Set-Alias explorer Open-Here

# Clear the terminal screen
Set-Alias -Name clr -Value "clear"

# Open the PowerShell profile in VS Code
# (must be a function - Set-Alias cannot bind a command with arguments)
function profile { code $PROFILE }

# Git
# Git aliases already set in:
# 1. .gitconfig file
# 2. git-aliases PowerShell module
# 3. Invoke-GitPullAllSubfolders.ps1
# 4. Posh-Git PowerShell module?

# VS Code
function vsc { code . }

# Start notepad
#function n { C:\Program Files\Notepad++\notepad++.exe $args }
function note { C:\ProgramData\chocolatey\bin\notepad++.exe $args }

# Compute file hashes - useful for checking successful downloads
function md5 { Get-FileHash -Algorithm MD5 $args }
function sha1 { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# Drive shortcuts
function HKLM: { Set-Location HKLM: } # Windows Registry - HKEY_LOCAL_MACHINE
function HKCU: { Set-Location HKCU: } # Windows Registry - HKEY_CURRENT_USER
function Env: { Set-Location Env: } # Environment PowerShell drive

# Unzip
function unzip ($file) {
    $fullPath = Join-Path -Path $pwd -ChildPath $file
    if (Test-Path $fullPath) {
        Write-Output "Extracting $file to $pwd"
        Expand-Archive -Path $fullPath -DestinationPath $pwd
    }
    else {
        Write-Output "File $file does not exist in the current directory"
    }
}

function ssh-copy-key {
    param(
        [parameter(Position = 0)]
        [string]$user,

        [parameter(Position = 1)]
        [string]$ip
    )
    $pubKeyPath = "~\.ssh\id_ed25519.pub"
    $sshCommand = "cat $pubKeyPath | ssh $user@$ip 'cat >> ~/.ssh/authorized_keys'"
    Invoke-Expression $sshCommand
}

# Encrypt a string with a password
# Broken: it encrypts $Password and ignores $StringToEncrypt, and the result can
# only be decrypted by this user on this PC (DPAPI). Not ported (dotfiles-windows#52).
function Protect-String {
    # Usage example Encrypt-String "String" "Password"
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$StringToEncrypt,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Password
    )
    # Convert the password to a secure string
    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    # Encrypt the string
    $encryptedString = ConvertFrom-SecureString -SecureString $securePassword
    return $encryptedString
}

# Reload the profile
# via https://stackoverflow.com/questions/17794507/reload-the-path-in-powershell
# Note: `refreshenv` requires chocolatey to be installed.
function reload { . $PROFILE; refreshenv; update-path; }

function Update-Profile {
    Backup-Profile
    Copy-Profile
    reload
}

# Update the path
function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") +
    ";" +
    [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Network Utilities
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# System Utilities
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name = 'LastBootUpTime'; Expression = { $_.ConverttoDateTime($_.lastbootuptime) } } | Format-Table -HideTableHeaders
    }
    else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

# Reboot and poweroff aliases
function Reboot-System { Restart-Computer -Force }
function Poweroff-System { Stop-Computer -Force }
Set-Alias reboot Reboot-System
Set-Alias poweroff Poweroff-System


# Winget Upgrade aliases
function Invoke-WingetUpgradeAll {
    winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity --include-unknown --include-pinned
}
Set-Alias wingetUpgradeAll Invoke-WingetUpgradeAll

# Eza (ls replacement) output in a two level file tree
function Invoke-Ezatree { eza --tree --level=2 --color=always --git --header --icons=auto }
Set-Alias ezatree Invoke-Ezatree