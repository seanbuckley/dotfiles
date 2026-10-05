# Install-MyModule.ps1
#
# What:     Install-My-Module <name>: import a module if it's installed,
#           otherwise install it from the PowerShell Gallery, then import it.
# Loaded:   lazily, on first use.
# Fate:     review; Install-PSResource covers most of this.

function Install-My-Module ($m) {

    # If module is imported say that and do nothing
    if (Get-Module | Where-Object { $_.Name -eq $m }) {
        write-host "Module $m is already imported."
        Write-Output ""
    }
    else {

        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $m }) {
            Import-Module $m -Verbose
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $m | Where-Object { $_.Name -eq $m }) {
                Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                Import-Module $m -Verbose
            }
            else {

                # If the module is not imported, not available and not in the online gallery then abort
                # (return, not EXIT - EXIT would close the interactive shell session)
                write-host "Module $m not imported, not available and not in an online gallery, exiting."
                Write-Output ""
                return
            }
        }
    }
}