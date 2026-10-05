# Setup of PowerShell and the Dotfiles Repository

1. Clone `dotfiles-windows` wherever you keep your repositories.
2. Use `code $PROFILE` to open the existing PowerShell profile in VS Code.
3. Source the active `.ps1` file from `dotfiles-windows` in the existing PowerShell profile by replacing it with:

    ```powershell
    . "C:\path\to\dotfiles-windows\PowerShell\Microsoft.PowerShell_profile.ps1"
    ```

4. Reload the terminal.
5. Prefer `.\Install-Dotfiles.ps1` for new hosts because it creates the loader and profile loaders for you.

\#TODO - integrate this setup documentation with README.md
