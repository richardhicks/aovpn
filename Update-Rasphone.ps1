<#

.SYNOPSIS
    PowerShell script to update common settings in the Windows remote access phonebook configuration file.

.PARAMETER ProfileName
    The name of the VPN connection to update settings for.

.PARAMETER SetPreferredProtocol
    Defines the preferred VPN protocol.

.PARAMETER InterfaceMetric
    Defines the interface metric to be used for the VPN connection.

.PARAMETER DisableIkeMobility
    Setting to disable IKE mobility.

.PARAMETER NetworkOutageTime
    Defines the network outage time when IKE mobility is enabled.

.PARAMETER UseRasCredentials
    Enables or disables the usage of the VPN credentials for SSO against systems behind the VPN.

.PARAMETER RasphonePath
    Specifies the path to the rasphone.pbk file. This parameter may be required when running this script using SCCM or other systems management tools that deploy software to the user but run in the SYSTEM context.

.PARAMETER AllUserConnection
    Identifies the VPN connection is configured for all users.

.EXAMPLE
    .\Update-Rasphone.ps1 -ProfileName 'Always On VPN' -SetPreferredProtocol IKEv2 -InterfaceMetric 15 -DisableIkeMobility

    Running this command will update the preferred protocol setting to IKEv2, the interface metric to 15, and disables IKE mobility on the VPN connection "Always On VPN".

.EXAMPLE
    .\Update-Rasphone.ps1 -ProfileName 'Always On VPN Device Tunnel' -InterfaceMetric 15 -NetworkOutageTime 60 -AllUserConnection

    Running this command will update the interface metric to 15 and the IKEv2 network outage time to 60 seconds for the device tunnel VPN connection "Always On VPN Device Tunnel".

.DESCRIPTION
    Always On VPN administrators may need to adjust settings for VPN connections that are not exposed in the Microsoft Intune user interface, ProfileXML, or native PowerShell commands. This script allows administrators to edit some of the commonly edited settings in the Windows remote access phonebook configuration file.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.1
    Creation Date:  April 9, 2020
    Last Updated:   April 30, 2020
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com/

#>

[CmdletBinding(SupportsShouldProcess)]

Param(

    [string]$ProfileName,
    [ValidateSet('IKEv2', 'IKEv2Only', 'SSTP', 'SSTPOnly', 'Automatic')]
    [string]$SetPreferredProtocol,
    [string]$InterfaceMetric,
    [switch]$DisableIkeMobility,
    [ValidateSet('60', '120', '300', '600', '1200', '1800')]
    [string]$NetworkOutageTime,
    [ValidateSet('true', 'false')]
    [string]$UseRasCredentials,
    [string]$RasphonePath,
    [switch]$AllUserConnection

)

# // Exit script if options to disable IKE mobility and define a network outage time are both enabled
If ($DisableIkeMobility -And $NetworkOutageTime) {

    Write-Warning 'The option to disable IKE mobility and set a network outage time are mutually exclusive. Please choose one and re-run this command.'
    Exit  

}

# // Define rasphone.pbk file path
If (-Not $RasphonePath -and $AllUserConnection) {

    $RasphonePath = 'C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk'

}

ElseIf (-Not $RasphonePath) {

    $RasphonePath = "$env:appdata\Microsoft\Network\Connections\Pbk\rasphone.pbk"

}

# // Ensure that rasphone.pbk exists
If (!(Test-Path $RasphonePath)) {

    Write-Warning "The file $RasphonePath does not exist. Exiting script."
    Exit

}

# // Create empty hashtable
$Settings = @{ }

# // Set preferred VPN protocol
If ($SetPreferredProtocol) {

    Switch ($SetPreferredProtocol) {

        IKEv2       { $Value = '14' }
        IKEv2Only   { $Value = '7'}
        SSTP        { $Value = '6' }
        SSTPOnly    { $Value = '5'}
        Automatic   { $Value = '0' }

    }
    
    $Settings.Add('VpnStrategy', $Value)

}

# // Set IPv4 and IPv6 interface metrics
If ($InterfaceMetric) {

    $Settings.Add('IpInterfaceMetric', $InterfaceMetric)
    $Settings.Add('Ipv6InterfaceMetric', $InterfaceMetric)
}

# // Disable IKE mobility
If ($DisableIkeMobility) {

    $Settings.Add('DisableMobility', '1')
    $Settings.Add('NetworkOutageTime', '0')

}

# // If IKE mobility is enabled, define network outage time
If ($NetworkOutageTime) {

    $Settings.Add('DisableMobility', '0')
    $Settings.Add('NetworkOutageTime', $NetworkOutageTime)

}

If ($UseRasCredentials) {

    Switch ($UseRasCredentials) {

        true    { $Value = '1' }
        false   { $Value = '0'}

    }

    $Settings.Add('UseRasCredentials', $Value)

}

# // Function to update rasphone.pbk settings
Function Update-Rasphone {

    [CmdletBinding(SupportsShouldProcess)]

    Param(
    
        [string]$Path,
        [string]$ProfileName,
        [hashtable]$Settings
    
    )
    
    $RasphoneProfiles = (Get-Content $Path -Raw) -split "\[" | Where-Object { $_ } # "`n\s?`n\["
    $Output = @()
    $Pass = @()
    
    # // Create a hashtable of VPN profiles
    Write-Verbose "Searching for VPN profiles..."
    $ProfileHash = [ordered]@{ }
    
    ForEach ($Profile in $RasphoneProfiles) {
    
        $RasphoneProfile = [regex]::Match($Profile, ".*(?=\])")
        Write-Verbose "Found VPN profile ""$RasphoneProfile""..."
        $ProfileHash.Add($RasphoneProfile, $profile)
    
    }
    
    $Profiles = $ProfileHash.GetEnumerator()
    
    ForEach ($Name in $ProfileName) {
    
        Write-Verbose "Searching for VPN profile ""$Name""..."
    
        ForEach ($Entry in $Profiles) {
    
            If ($Entry.Name -Match $Name) {
    
                Write-Verbose "Updating settings for ""$($Entry.Name)""..."
                $Profile = $Entry.Value
                $Pass += "[$($Entry.Name)]"
                $Settings.GetEnumerator() | ForEach-Object {
    
                    $SettingName = $_.Name
                    Write-Verbose "Searching VPN profile ""$($Entry.Name)"" for setting ""$Settingname""..."
                    $Value = $_.Value
                    $Old = "$SettingName=.*\s?`n"
                    $New = "$SettingName=$value`n"
                    
                    If ($Profile -Match $Old) {
    
                        Write-Verbose "Setting ""$SettingName"" to ""$Value""..."
                        $Profile = $Profile -Replace $Old, $New
                        $Pass += ($Old).TrimEnd()
                        
                        # // Set a flag indicating the file should be updated
                        $Changed = $True
    
                    }
    
                    Else {
    
                        Write-Warning "Could not find setting ""$SettingName"" under ""$($entry.name)""."
    
                    }
    
                } # ForEach setting
    
                $Output += $Profile -Replace '^\[?.*\]', "[$($entry.name)]"
                $Output = $Output.Trimstart()
    
            } # Name match
    
            Else {
    
                # Keep the entry
                $Output += $Entry.value -Replace '^\[?.*\]', "[$($entry.name)]"
                $Output = $output.Trimstart()
    
            }
    
        } # ForEach entry in profile hashtable
    
        If ( -Not $Changed) {
    
            Write-Warning "No changes were made to VPN profile ""$name""."
    
        }
    
    } # ForEach Name in ProfileName
    
    # // Only update the file if changes were made
    If (($Changed) -AND ($PsCmdlet.ShouldProcess($Path, "Update rasphone.pbk"))) {
    
        Write-Verbose "Updating $Path..."
        $Output | Out-File -FilePath $Path -Encoding ASCII
    
        If ($PassThru) {
    
            $Pass | Where-Object { $_ -match "\w+" }
    
        }
        
    } # Whatif

} # End Function Update-Rasphone

Update-Rasphone -Path $RasphonePath -ProfileName $ProfileName -Settings $Settings