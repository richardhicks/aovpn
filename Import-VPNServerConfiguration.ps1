<#

.SYNOPSIS
    PowerShell script to import Windows Server Routing and Remote Access Service (RRAS) configuration from text file.

.PARAMETER Path
    File name and path for the RRAS configuration export file.

.PARAMETER Restart
    Restarts the RemoteAccess service after importing the configuration file.

.EXAMPLE
    .\Import-VPNServerConfiguration.ps1 -Path C:\Backup\RRAS.txt

.EXAMPLE
    .\Import-VPNServerConfiguration.ps1 -Path C:\Backup\RRAS.txt -Restart

.DESCRIPTION
    This script will import a previously exported Windows Server RRAS configuration file.

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

    [Parameter(Mandatory = $True)]    
    [string]$Path,
    [switch]$Restart

)

# Validate backup file
Write-Verbose "Validating backup file $Path..."
If (!(Test-Path $Path)) {

    Write-Warning "Backup file $path does not exist. Exiting script."
    Exit

}

$Parameters = @{

    ScriptBlock = { netsh exec $Path }

}

# Import VPN server configuration 
Write-Verbose "Importing VPN server configuration from $Path..."
Invoke-Command @Parameters

# Restart RemoteAccess service
If ($Restart) {

    Write-Verbose 'Restarting the RemoteAccess service...'
    Restart-Service RemoteAccess -PassThru

}

Write-Warning 'RADIUS shared secrets are not imported by default. Update manually, if required.'
