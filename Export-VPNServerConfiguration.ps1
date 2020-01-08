<#

.SYNOPSIS
    PowerShell script to export Windows Server Routing and Remote Access Service (RRAS) configuration to text file.

.PARAMETER Path
    File name and path for the RRAS configuration export file.

.EXAMPLE
    .\Export-VPNServerConfiguration.ps1 -Path C:\Backup\RRAS.txt

.DESCRIPTION
    This script will export the Windows Server RRAS configuration to text file. The output file can be imported to restore the configuration.

.LINK
    https://directaccess.richardhicks.com/2019/07/22/error-importing-windows-server-rras-configuration/

.NOTES
    Version:        1.0
    Creation Date:  January 8, 2020
    Last Updated:   January 8, 2020
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param(

    [string]$Path = "$env:computername.txt"

)

# Check for existing configuration file. Delete if it exists.
Write-Verbose 'Checking for existing backup file...'
If (Test-Path $Path) {

    Write-Verbose "Deleting existing configuration file $Path."
    Remove-Item $Path
}

$Parameters = @{

    ScriptBlock = { netsh ras dump }
    
}

# Export RRAS configuration to text file.
Write-Verbose "Exporting VPN server configuration to $Path..."
Invoke-Command @Parameters | Out-File $Path.ToLower() -Encoding ASCII

# Remind administrator about missing NPS shared secret
Write-Warning 'This backup file does NOT include RADIUS shared secrets. Those must be added manually, if required.'
Write-Output "Script complete. RRAS configuration saved in $Path."
