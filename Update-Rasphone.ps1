<#

.SYNOPSIS
    PowerShell script to update common settings in the Windows remote access phonebook configuration file.

.PARAMETER AllUserConnection
    Identifies the VPN connection is configured for all users.

.PARAMETER DisableIkeMobility
    Setting to disable IKE mobility.

.PARAMETER InterfaceMetric
    Defines the interface metric to be used for the VPN connection.

.PARAMETER NetworkOutageTime
    Defines the network outage time when IKE mobility is enabled.

.PARAMETER ProfileName
    The name of the VPN connection to update settings for.

.PARAMETER RasphonePath
    Specifies the path to the rasphone.pbk file. This parameter may be required when running this script using SCCM or other systems management tools that deploy software to the user but run in the SYSTEM context.

.PARAMETER SetPreferredProtocol
    Defines the preferred VPN protocol.

.PARAMETER UseRasCredentials
    Enables or disables the usage of the VPN credentials for SSO against systems behind the VPN.

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
    Version:        1.3
    Creation Date:  April 9, 2020
    Last Updated:   June 19, 2020
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com/

#>

[CmdletBinding(SupportsShouldProcess)]

Param(

    [Parameter(Mandatory, HelpMessage = 'Enter the name of the VPN profile to update.')]    
    [string]$ProfileName,
    [ValidateSet('IKEv2', 'IKEv2Only', 'SSTP', 'SSTPOnly', 'Automatic')]
    [string]$SetPreferredProtocol,
    [string]$InterfaceMetric,
    [switch]$DisableIkeMobility,
    [ValidateSet('60', '120', '300', '600', '1200', '1800')]
    [string]$NetworkOutageTime,
    [string]$RasphonePath,
    [ValidateSet('True', 'False')]
    [string]$UseRasCredentials,
    [switch]$UseWinlogonCredential,
    [switch]$AllUserConnection

)

# // Exit script if options to disable IKE mobility and define a network outage time are both enabled
If ($DisableIkeMobility -And $NetworkOutageTime) {

    Write-Warning 'The option to disable IKE mobility and set a network outage time are mutually exclusive. Please choose one and run this command again.'
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

        IKEv2 { $Value = '14' }
        IKEv2Only { $Value = '7' }
        SSTP { $Value = '6' }
        SSTPOnly { $Value = '5' }
        Automatic { $Value = '0' }

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

# // Define use of VPN credentials for SSO to on-premises resources (helpful for non-domain joined clients)
If ($UseRasCredentials) {

    Switch ($UseRasCredentials) {

        true { $Value = '1' }
        false { $Value = '0' }

    }

    $Settings.Add('UseRasCredentials', $Value)

}

# // Define use of logged on user's Windows credentials for automatic VPN logon (helpful when MS-CHAP v2 authentication is configured)
If ($UseWinlogonCredential) {

    Switch ($UseWinlogonCredential) {

        true { $Value = '1' }
        false { $Value = '0' }

    }

    $Settings.Add('AutoLogon', $Value)

}

# // Function to update rasphone.pbk settings
Function Update-Rasphone {

    [CmdletBinding(SupportsShouldProcess)]

    Param(
    
        [string]$Path,
        [string]$ProfileName,
        [hashtable]$Settings
    
    )
    
    $RasphoneProfiles = (Get-Content $Path -Raw) -split "\[" | Where-Object { $_ -match "\w+" } # "`n\s?`n\["
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
    
            If ($Entry.Name -Match "^$Name$") {
    
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

# SIG # Begin signature block
# MIINbAYJKoZIhvcNAQcCoIINXTCCDVkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoMbKcgVm7byiFp0NeIM5FnLy
# QlugggquMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
# AQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAwWhcNMjgxMDIyMTIwMDAwWjByMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQg
# Q29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# +NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/5aid2zLXcep2nQUut4/6kkPApfmJ
# 1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH03sjlOSRI5aQd4L5oYQjZhJUM1B0
# sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxKhwjfDPXiTWAYvqrEsq5wMWYzcT6s
# cKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5Ng2Q7+S1TqSp6moKq4Tz
# rGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi6CxR93O8vYWxYoNzQYIH5DiLanMg
# 0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCCAckwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMweQYIKwYBBQUH
# AQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYI
# KwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFz
# c3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaG
# NGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0
# dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCgYIYIZIAYb9bAMwHQYDVR0OBBYE
# FFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6en
# IZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+7A1aJLPzItEVyCx8JSl2qB1dHC06
# GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbRknUPUbRupY5a4l4kgU4QpO4/cY5j
# DhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7uq+1UcKNJK4kxscnKqEpKBo6cSgC
# PC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7qPjFEmifz0DLQESlE/DmZAwlCEIy
# sjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPas7CM1ekN3fYBIM6ZMWM9CBoYs4Gb
# T8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHvMIIFdjCC
# BF6gAwIBAgIQDOTKENcaCUe5Ct81Y25diDANBgkqhkiG9w0BAQsFADByMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29k
# ZSBTaWduaW5nIENBMB4XDTE5MTIxNjAwMDAwMFoXDTIxMTIyMDEyMDAwMFowgbIx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1NaXNz
# aW9uIFZpZWpvMSowKAYDVQQKEyFSaWNoYXJkIE0uIEhpY2tzIENvbnN1bHRpbmcs
# IEluYy4xHjAcBgNVBAsTFVByb2Zlc3Npb25hbCBTZXJ2aWNlczEqMCgGA1UEAxMh
# UmljaGFyZCBNLiBIaWNrcyBDb25zdWx0aW5nLCBJbmMuMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAr+wmqY7Bpvs6EmNV227JD5tee0m+ltuYmleTJ1TG
# TCfibcWU+2HOHICHoUdSF4M8L0LoonkIWKoMCUaGFzrvMFjlt/J8juH7kazf3mEd
# Z9lzxOt6GLn5ILpq+8i2xb4cGqLd1k8FEJaFcq66Xvi2xknQ3r8cDJWBXi4+CoLY
# 0/VPNNPho2RTlpN8QL/Xz//hE+KB7YzaF+7wYCVCkR/Qn4D8AfiUBCAw8fNbjNGo
# Q/v7xh+f6TidtC7Y5B8D8AR4IJSok8Zbivz+HJj5wZNWsS70D8HnWQ7hM/7nAwQh
# teh0/kj0m6TMVtsv4b9KCDEyPT71cp5g4JxMO+x3UZh0CQIDAQABo4IBxTCCAcEw
# HwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0OBBYEFB6Bcy+o
# ShXw68ntqleXMwE4Lj1jMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEF
# BQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# c2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2NybDQuZGlnaWNl
# cnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUwQzA3BglghkgB
# hv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
# UzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUFBzAChkJodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25pbmdDQS5j
# cnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAcJWSNtlE7Ml9VLf/
# 96z8tVbF05wZ/EkC4O9ouEdg5AmMx/5LdW2Tz4OrwAUCrRWgIRsC2ea4ZzsZli1i
# 7TdwaYmb2LGKMpq0z1g88iyjIdX6jCoUqMQq1jZAFaJ9iMk7Gn2kHrlcHvVjxwYE
# nf3XxMeGkvvBl8CBkV/fPQ2rrSyKeGSdumWdGGx6Dv/OH5log+x6Qdr6tkFC7byK
# oCBsiETUHs63z53QeVjVxH0zXGa9/G57XphUx18UTYkgIobMN4+dRizxA5sU1WCB
# pstchAVbAsM8OhGoxCJlQGjaXxSk6uis2XretUDhNzCodqdz9ul8CVKem9uJTYjo
# V6CBYjGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERp
# Z2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0ECEAzkyhDXGglH
# uQrfNWNuXYgwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAw
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMLJ4QJBRoM36Kx8fJSBsDsh7LzkMA0G
# CSqGSIb3DQEBAQUABIIBAI6swQSWqSgizhvEOY+dt/caMLLNl5/PRIkX/miITmfS
# gui0l/y2Pg4FRzj8HEQs5dVc2J4E/kjVdPZVFh+dut6Uq/RJWYCAyOv8B7IJAyJv
# TTixa/uA4nMXcjIaYkdbD3lzrIxMmMCKEs9CyeXKelK659ex+2Ah0blHPXuoYBli
# ZcyWD6xritSybdfk+eD2j5a8K2Ha/hZ3jBkqV90eKByRc1gSBhe0Cpv0C+yL4dtX
# NsQn0M+rkPSh0nlP08NNBrk0vXcIJITg5bERN7uFAZq17QwQROx2IDIK7lfy4h9s
# aMYsjhyN3hch2zIiitSXdqEQ4JGJMPJgivqDej4JG1U=
# SIG # End signature block
