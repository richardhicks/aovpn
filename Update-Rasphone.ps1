<#

.SYNOPSIS
    PowerShell script to update common settings in the Windows remote access phonebook configuration file.

.PARAMETER AllUserConnection
    Identifies the VPN connection is configured for all users.

.PARAMETER DisableClassBasedDefaultRoute
    Enables or disable the class-based default route.

.PARAMETER DisableCredentialCaching
    Enable or disable credential caching.

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

.PARAMETER UseWinlogonCredential
    Enables or disables the usage of the user's credentials used to log on to Windows for VPN authentication.

.PARAMETER UseWinlogonCredential
    Enables or disables the registration of the VPN clients IP address in internal DNS.

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
    Version:        2.22
    Creation Date:  April 9, 2020
    Last Updated:   September 24, 2021
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com/

#>

[CmdletBinding(SupportsShouldProcess)]

Param (

    [Parameter(Mandatory, HelpMessage = 'Enter the name of the VPN profile to update.')]    
    [string]$ProfileName,
    [string]$RasphonePath,
    [ValidateSet('IKEv2', 'IKEv2Only', 'SSTP', 'SSTPOnly', 'Automatic')]
    [string]$SetPreferredProtocol,
    [string]$InterfaceMetric,
    [ValidateSet('True', 'False')]
    [string]$DisableIkeMobility,
    [ValidateSet('60', '120', '300', '600', '1200', '1800')]
    [string]$NetworkOutageTime,
    [ValidateSet('True', 'False')]
    [string]$UseRasCredentials,
    [ValidateSet('True', 'False')]
    [string]$UseWinlogonCredential,
    [ValidateSet('True', 'False')]
    [string]$DisableClassBasedDefaultRoute,
    [ValidateSet('True', 'False')]
    [string]$DisableCredentialCaching,
    [ValidateSet('True', 'False')]
    [string]$RegisterDNS,
    [Alias("DeviceTunnel")]
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
    $RasphoneBackupPath = Join-Path 'C:\ProgramData\Microsoft\Network\Connections\Pbk\' -ChildPath "rasphone_$(Get-Date -Format FileDateTime).bak"

}

ElseIf (-Not $RasphonePath) {

    $RasphonePath = "$env:appdata\Microsoft\Network\Connections\Pbk\rasphone.pbk"
    $RasphoneBackupPath = Join-Path "$env:appdata\Microsoft\Network\Connections\Pbk\" -ChildPath "rasphone_$(Get-Date -Format FileDateTime).bak"

}

# // Ensure that rasphone.pbk exists
If (!(Test-Path $RasphonePath)) {

    Write-Warning "The file $RasphonePath does not exist. Exiting script."
    Exit

}

# // Create backup of rasphone.pbk
Write-Verbose "Backing up existing rasphone.pbk file to $RasphoneBackupPath..."
Copy-Item $RasphonePath $RasphoneBackupPath

# // Create empty VPN profile settings hashtable
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

    Switch ($DisableIkeMobility) {

        True { $Value = '1'}
        False { $Value = '0'}

    }

    $Settings.Add('DisableMobility', $Value)
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

        True { $Value = '1' }
        False { $Value = '0' }

    }

    $Settings.Add('UseRasCredentials', $Value)

}

# // Define use of logged on user's Windows credentials for automatic VPN logon (helpful when MS-CHAP v2 authentication is configured)
If ($UseWinlogonCredential) {

    Switch ($UseWinlogonCredential) {

        True { $Value = '1' }
        False { $Value = '0' }

    }

    $Settings.Add('AutoLogon', $Value)

}

# // Enable or disable the class-based default route
If ($DisableClassBasedDefaultRoute) {

    Switch ($DisableClassBasedDefaultRoute) {

        True { $Value = '1' }
        False { $Value = '0' }

    }

    $Settings.Add('DisableClassBasedDefaultRoute', $Value)

}

# // Enable or disable credential caching
If ($DisableCredentialCaching) {

    Switch ($DisableCredentialCaching) {

        True { $Value = '0' }
        False { $Value = '1' }

    }

    $Settings.Add('CacheCredentials', $Value)

}

# // Enable or disable VPN adapter DNS registration
If ($RegisterDNS) {

    Switch ($RegisterDNS) {

        True { $Value = '1' }
        False { $Value = '0' }

    }

    $Settings.Add('IpDnsFlags', $Value)

}

# // Function to update rasphone.pbk
Function Update-RASPhoneBook {

    [CmdletBinding(SupportsShouldProcess)]

    Param (

        [string]$Path,
        [string]$ProfileName,
        [hashtable]$Settings

    )

    $pattern = "(\[.*\])"
    $c = Get-Content $path -Raw
    $p = [System.Text.RegularExpressions.Regex]::Split($c, $pattern, "IgnoreCase") | Where-Object { $_ }

    # // Create a hashtable of VPN profiles
    Write-Verbose "Initializing a hashtable for VPN profiles from $path..."
    $profHash = [ordered]@{}

    For ($i = 0; $i -lt $p.count; $i += 2) {

        Write-Verbose "Adding $($p[$i]) to VPN profile hashtable..."
        $profhash.Add($p[$i], $p[$i + 1])

    }

    # // An array to hold changed values for -Passthru
    $pass = @()

    Write-Verbose "Found the following VPN profiles: $($profhash.keys -join ',')."

    $compare = "[$Profilename]"
    
    Write-Verbose "Searching for VPN profile $compare..."
    # // Need to make sure to get the exact profile
    $SelectedProfile = $profHash.GetEnumerator() | Where-Object { $_.name -eq $compare }

    If ($SelectedProfile) {

        Write-Verbose "Updating $($SelectedProfile.key)"
        $pass += $SelectedProfile.key

        $Settings.GetEnumerator() | ForEach-Object {

            $SettingName = $_.name
            Write-Verbose "Searching for setting $Settingname..."
            $Value = $_.Value
            $thisName = "$SettingName=.*\s?`n"
            $thatName = "$SettingName=$value`n"
            If ($SelectedProfile.Value -match $thisName) {

                Write-Verbose "Setting $SettingName = $Value."
                $SelectedProfile.value = $SelectedProfile.value -replace $thisName, $thatName
                $pass += ($ThatName).TrimEnd()
                # // Set a flag indicating the file should be updated
                $ChangeMade = $True

            }

            Else {

                Write-Warning "Could not find an entry for $SettingName under [$($SelectedProfile.key)]."

            }

        } #ForEach setting

        If ($ChangeMade) {

            # // Update the VPN profile hashtable
            $profhash[$Selectedprofile.key] = $Selectedprofile.value

        }

    } #If found

    Else {

        Write-Warning "VPN Profile [$profilename] not found."

    }

    # // Only update the file if changes were made
    If (($ChangeMade) -AND ($pscmdlet.ShouldProcess($path, "Update RAS PhoneBook"))) {

        Write-Verbose "Updating $Path"
        $output = $profHash.Keys | ForEach-Object { $_ ; ($profhash[$_] | Out-String).trim(); "`n" }
        $output | Out-File -FilePath $Path -Encoding ascii

    } #Whatif

} #close function

Update-RasphoneBook -Path $RasphonePath -ProfileName $ProfileName -Settings $Settings

# SIG # Begin signature block
# MIIZ1wYJKoZIhvcNAQcCoIIZyDCCGcQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUOrCakSFDH93ka9fffyGnCcb
# d3SgghTlMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAwMDAwMFoXDTMxMDEw
# NjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HXOhFCvQp1dU2UtAxQ
# tSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB+in43Stwhd4CGPN4
# bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPhLxs6t2HWc+xObTOK
# fF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizVI9r0TXhG4wODMSlK
# XAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKbaYK02/xWVLwfoYer
# vnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQECAwEAAaOCAbgwggG0
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYIKwYBBQUHAgEWG2h0
# dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAWgBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ23eNqerwwcQYDVR0f
# BGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJl
# ZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRpbWVzdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucgDo5nRv1CclF0CiNH
# o6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1ppA/2uHDPYuj1UUp4
# eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18jUmmDgvoaU+2QzI2h
# F3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFcz8QRcucbZEnYIpp1
# FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub9y4bTxMd90oNcX6X
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBTAwggQY
# oAMCAQICEAQJGBtf1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4X
# DTEzMTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEx
# MC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBD
# QTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsx
# SRnP0PtFmbE620T1f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawO
# eSg6funRZ9PG+yknx9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJ
# RdQtoaPpiCwgla4cSocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEc
# z+ryCuRXu0q16XTmK/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whk
# PlKWwfIPEvTFjg/BougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8l
# k9ECAwEAAaOCAc0wggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQD
# AgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARI
# MEYwOAYKYIZIAYb9bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdp
# Y2VydC5jb20vQ1BTMAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg
# +S32ZXUOWDAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG
# 9w0BAQsFAAOCAQEAPuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/E
# r4v97yrfIFU3sOH20ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3
# nEZOXP+QsRsHDpEV+7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpo
# aK+bp1wgXNlxsQyPu6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW
# 6Fkd6fp0ZGuy62ZD2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ
# 92JuoVP6EpQYhS6SkepobEQysmah5xikmmRR7zCCBTEwggQZoAMCAQICEAqhJdbW
# Mht+QeQF2jaXwhUwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTE2MDEwNzEyMDAw
# MFoXDTMxMDEwNzEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIFRpbWVzdGFtcGluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAL3QMu5LzY9/3am6gpnFOVQoV7YjSsQOB0Uz
# URB90Pl9TWh+57ag9I2ziOSXv2MhkJi/E7xX08PhfgjWahQAOPcuHjvuzKb2Mln+
# X2U/4Jvr40ZHBhpVfgsnfsCi9aDg3iI/Dv9+lfvzo7oiPhisEeTwmQNtO4V8CdPu
# XciaC1TjqAlxa+DPIhAPdc9xck4Krd9AOly3UeGheRTGTSQjMF287DxgaqwvB8z9
# 8OpH2YhQXv1mblZhJymJhFHmgudGUP2UKiyn5HU+upgPhH+fMRTWrdXyZMt7HgXQ
# hBlyF/EXBu89zdZN7wZC/aJTKk+FHcQdPK/P2qwQ9d2srOlW/5MCAwEAAaOCAc4w
# ggHKMB0GA1UdDgQWBBT0tuEgHf4prtLkYaWyoiWyyBc1bjAfBgNVHSMEGDAWgBRF
# 66Kv9JLLgjEtUYunpyGd823IDzASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB
# /wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYI
# KwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3
# aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2Ny
# bDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBQBgNV
# HSAESTBHMDgGCmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cu
# ZGlnaWNlcnQuY29tL0NQUzALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggEB
# AHGVEulRh1Zpze/d2nyqY3qzeM8GN0CE70uEv8rPAwL9xafDDiBCLK938ysfDCFa
# KrcFNB1qrpn4J6JmvwmqYN92pDqTD/iy0dh8GWLoXoIlHsS6HHssIeLWWywUNUME
# aLLbdQLgcseY1jxk5R9IEBhfiThhTWJGJIdjjJFSLK8pieV4H9YLFKWA1xJHcLN1
# 1ZOFk362kmf7U2GJqPVrlsD0WGkNfMgBsbkodbeZY4UijGHKeZR+WfyMD+NvtQEm
# tmyl7odRIeRYYJu6DC0rbaLEfrvEJStHAgh8Sa4TtuF8QkIoxhhWz0E0tmZdtnR7
# 9VYzIi8iNrJLokqV2PWmjlIwggV2MIIEXqADAgECAhAM5MoQ1xoJR7kK3zVjbl2I
# MA0GCSqGSIb3DQEBCwUAMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lD
# ZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwHhcNMTkxMjE2MDAw
# MDAwWhcNMjExMjIwMTIwMDAwWjCBsjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNh
# bGlmb3JuaWExFjAUBgNVBAcTDU1pc3Npb24gVmllam8xKjAoBgNVBAoTIVJpY2hh
# cmQgTS4gSGlja3MgQ29uc3VsdGluZywgSW5jLjEeMBwGA1UECxMVUHJvZmVzc2lv
# bmFsIFNlcnZpY2VzMSowKAYDVQQDEyFSaWNoYXJkIE0uIEhpY2tzIENvbnN1bHRp
# bmcsIEluYy4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCv7CapjsGm
# +zoSY1XbbskPm157Sb6W25iaV5MnVMZMJ+JtxZT7Yc4cgIehR1IXgzwvQuiieQhY
# qgwJRoYXOu8wWOW38nyO4fuRrN/eYR1n2XPE63oYufkgumr7yLbFvhwaot3WTwUQ
# loVyrrpe+LbGSdDevxwMlYFeLj4KgtjT9U800+GjZFOWk3xAv9fP/+ET4oHtjNoX
# 7vBgJUKRH9CfgPwB+JQEIDDx81uM0ahD+/vGH5/pOJ20LtjkHwPwBHgglKiTxluK
# /P4cmPnBk1axLvQPwedZDuEz/ucDBCG16HT+SPSbpMxW2y/hv0oIMTI9PvVynmDg
# nEw77HdRmHQJAgMBAAGjggHFMIIBwTAfBgNVHSMEGDAWgBRaxLl7KgqjpepxA8Bg
# +S32ZXUOWDAdBgNVHQ4EFgQUHoFzL6hKFfDrye2qV5czATguPWMwDgYDVR0PAQH/
# BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGGL2h0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWg
# M6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcx
# LmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRw
# czovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEE
# eDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYB
# BQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJB
# c3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3
# DQEBCwUAA4IBAQBwlZI22UTsyX1Ut//3rPy1VsXTnBn8SQLg72i4R2DkCYzH/kt1
# bZPPg6vABQKtFaAhGwLZ5rhnOxmWLWLtN3BpiZvYsYoymrTPWDzyLKMh1fqMKhSo
# xCrWNkAVon2IyTsafaQeuVwe9WPHBgSd/dfEx4aS+8GXwIGRX989DautLIp4ZJ26
# ZZ0YbHoO/84fmWiD7HpB2vq2QULtvIqgIGyIRNQezrfPndB5WNXEfTNcZr38bnte
# mFTHXxRNiSAihsw3j51GLPEDmxTVYIGmy1yEBVsCwzw6EajEImVAaNpfFKTq6KzZ
# et61QOE3MKh2p3P26XwJUp6b24lNiOhXoIFiMYIEXDCCBFgCAQEwgYYwcjELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENv
# ZGUgU2lnbmluZyBDQQIQDOTKENcaCUe5Ct81Y25diDAJBgUrDgMCGgUAoHgwGAYK
# KwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU
# Bxzi2gNDi0vcB//KgUoBbNUr99kwDQYJKoZIhvcNAQEBBQAEggEAJkBWkI2WCNYF
# XPurqhcRZKIOeXsY2YQLWn/pEeryWx8q/TAmk3NwF1rI66RvnG6rjhtg+QJS2xvP
# OLJ5OMutxsSCGQAAe3DrO04uC9gt9sPVJd3W43rJUO2kdPCLEgkLSM4BP0WVzpNe
# uczMQhVnJ0LqwqQLmY741UrgGq/eXC5oFNToqY4Q9z9SGGIOTAqXysSYPe71zwsY
# HrqVoFDZynVAhLLYw+Z0XQmGu5a5CCkdLJfcarCQ/2ixqKsD4hpk8H/rGc9tFide
# GEQoRJ/S8X+gmBHTA0msS9GD7WCeEfhcawJBDZ+D9ECfHMcZf/sapjkIu1Y3s831
# F1yV91dpKqGCAjAwggIsBgkqhkiG9w0BCQYxggIdMIICGQIBATCBhjByMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGlt
# ZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDdMA0GCWCGSAFlAwQCAQUAoGkw
# GAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjEwOTI0
# MjAyMDQ0WjAvBgkqhkiG9w0BCQQxIgQgWCnygB5b/VlMjfEkuLcusxuyvhPnpAE0
# +QIr/UdGKtwwDQYJKoZIhvcNAQEBBQAEggEAIZAbDO5ZJ0rt7D/QBL92rVHQVQzF
# jJmaMAIyek2/7CiMOxIYTkrRVu2wWc7PMLSC17lIqCEfoowxaLlIlUmanlmlLJZv
# M4dCF1nxYHEYfW6yyq7rDDdkJyCGJ7TCCaL8zuFfYHAC6/ErWYTBb8Lqtp5IlMvL
# l1rpaN/er+MFE7pg5Q5Gk4Je9B7Try9IixUmjdYE0atZ+IGVyk4R/TKIruia21D2
# LjXKdVSq9xAukO5+8CSPloicr80zbM4DrB8SlaLgS4qmoPAyueBr7KBWpHKg2PLM
# mUkzKWgCWI/GpeFakQ/VOFlx3NqcWP7A6idudLkEB3zLx+p+i2NLIz77gA==
# SIG # End signature block
