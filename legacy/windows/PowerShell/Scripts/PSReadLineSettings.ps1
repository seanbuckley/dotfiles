# Content from:
# https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
#
# What:     Command-line editing: history search, predictions, key bindings.
# Loaded:   eagerly by the profile; does nothing without a real console.
# Fate:     port (P4.01).

if (-not (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue)) {
    return
}

# Skip PSReadLine tuning when PowerShell is running without a real interactive console.
if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {
    return
}

if ($Host.Name -notin @("ConsoleHost", "Visual Studio Code Host")) {
    return
}

# Add auto complete (requires PSReadline 2.2.0-beta1+ prerelease)
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -EditMode Windows

try {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction Stop
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
}
catch {
    # Older hosts and redirected output do not support predictive UI features.
}

# ListView redraws the prediction block in place on every keystroke, and it works out
# which rows to erase from how many lines it believes the prompt occupies. Multi-line
# prompts (our oh-my-posh powerlevel10k_rainbow theme is two lines) break that maths, so
# stale prediction rows accumulate below the input instead of being overwritten.
# ExtraPromptLineCount tells PSReadLine about the lines above the input line.
# Override with DOTFILES_PROMPT_EXTRA_LINES if a local theme is a different height.
$extraPromptLines = 1
$extraPromptLinesOverride = [System.Environment]::GetEnvironmentVariable("DOTFILES_PROMPT_EXTRA_LINES")
if (-not [string]::IsNullOrWhiteSpace($extraPromptLinesOverride)) {
    $parsedExtraPromptLines = 0
    if ([int]::TryParse($extraPromptLinesOverride.Trim(), [ref]$parsedExtraPromptLines) -and $parsedExtraPromptLines -ge 0) {
        $extraPromptLines = $parsedExtraPromptLines
    }
}

Set-PSReadLineOption -ExtraPromptLineCount $extraPromptLines

# Set-PSReadLineKeyHandler -Key Tab -Function ForwardWord

# Disbled the key settings below as Oh My Posh or other was already handeling them in a manner I prefer.
# Settings below will not cylce all history if you've already started typing.
#Set-PSReadLineOption -HistorySearchCursorMovesToEnd
#Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
#Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Clipboard interaction is bound by default in Windows mode, but not Emacs mode.
Set-PSReadLineKeyHandler -Key Ctrl+C -Function Copy
Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# PSReadLine auto add quotes
Set-PSReadLineKeyHandler -Chord '"', "'" `
    -BriefDescription SmartInsertQuote `
    -LongDescription "Insert paired quotes if not already on a quote" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line.Length -gt $cursor -and $line[$cursor] -eq $key.KeyChar) {
        # Just move the cursor
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
    else {
        # Insert matching quotes, move cursor to be in between the quotes
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)" * 2)
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
    }
}
