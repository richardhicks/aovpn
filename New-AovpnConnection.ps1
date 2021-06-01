<#

.SYNOPSIS
    Creates an Always On VPN user or device tunnel connection.

.PARAMETER xmlFilePath
    Path to the ProfileXML configuration file.

.PARAMETER ProfileName
    Name of the VPN profile to be created.

.PARAMETER DeviceTunnel
    Option to create an Always On VPN device tunnel profile.

.PARAMETER AllUserConnection
    Option to create the Always On VPN user tunnel profile in the all users profile.

.EXAMPLE
    .\New-AovpnConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML_User.xml' -ProfileName 'Always On VPN'

    Creates an Always On VPN user tunnel profile named "Always On VPN" for the user Rick Deckard.

.EXAMPLE
    .\New-AovpnConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML_User.xml -ProfileName 'Always On VPN' -AllUserConnection

    Creates an Always On VPN user tunnel profile named "Always On VPN" for all users.

.EXAMPLE
    .\New-AovpnConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML_Device.xml -DeviceTunnel

    Creates an Always On VPN device tunnel profile named "Always On VPN Device Tunnel".

.DESCRIPTION
    This script will create an Always On VPN user or device tunnel on supported Windows 10 devices. 

.LINK
    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections#bkmk_fullscript

.NOTES
    Version:            4.11
    Creation Date:      May 28, 2019
    Last Updated:       June 1, 2021
    Special Note:       This script adapted from guidance originally published by Microsoft.
    Original Author:    Microsoft Corporation
    Original Script:    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections#bkmk_fullscript
    Author:             Richard Hicks
    Organization:       Richard M. Hicks Consulting, Inc.
    Contact:            rich@richardhicks.com
    Web Site:           https://directaccess.richardhicks.com/

#>

[CmdletBinding(SupportsShouldProcess)]

Param (

    [Parameter(Mandatory, HelpMessage = 'Enter the path to the ProfileXML file.')]
    [ValidateNotNullOrEmpty()]
    [string]$xmlFilePath,
    [Parameter(HelpMessage = 'Enter a name for the VPN profile.')]        
    [Alias("Name", "ConnectionName")]
    [string]$ProfileName,
    [switch]$DeviceTunnel,
    [switch]$AllUserConnection

)

# // Set default profile name
If ($ProfileName -eq '') {

    If ($DeviceTunnel) {

        $ProfileName = 'Always On VPN Device Tunnel'
    
    }

    Else {
        
        $ProfileName = 'Always On VPN'
        
    }

}

# // Check for existing connection. Exit if exists.
If ($AllUserConnection -or $DeviceTunnel) {

    # // Script must be running in the context of the SYSTEM account to extract ProfileXML from a device tunnel connection. Validate user, exit if not running as SYSTEM.
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    If ($CurrentPrincipal.Identities.IsSystem -ne $true) {

        Write-Warning 'This script is not running in the SYSTEM context, as required. Exiting script.'
        Exit

    }

    # // Check for existing connection. Exit if exists.
    If (Get-VpnConnection -Name $ProfileName -AllUserConnection -ErrorAction SilentlyContinue) {

        Write-Warning "The VPN profile ""$ProfileName"" already exists. Exiting script."
        Exit

    }

}

Else {

    If (Get-VpnConnection -Name $ProfileName -ErrorAction SilentlyContinue) {

        Write-Warning "The VPN profile ""$ProfileName"" already exists. Exiting script."
        Exit
    
    }

}

# // Validate XML for user or device tunnel connections
[xml]$Xml = Get-Content $xmlFilePath

If ($DeviceTunnel) {

    If (($Xml.VPNProfile.DeviceTunnel -eq 'False') -or ($Null -eq $Xml.VPNProfile.DeviceTunnel)) {

        Write-Warning 'ProfileXML is not configured for a device tunnel. Exiting script.'
        Exit 

    }

}

If (!$DeviceTunnel) {

    If ($Xml.VPNProfile.DeviceTunnel -eq 'True') {

        Write-Warning 'ProfileXML is not configured for a user tunnel. Exiting script.'
        Exit

    }

}

# // Import ProfileXML
$ProfileXML = Get-Content $xmlFilePath

# // Escape spaces in profile name
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

# // OMA URI information
$NodeCSPURI = './Vendor/MSFT/VPNv2'
$NamespaceName = 'root\cimv2\mdm\dmmap'
$ClassName = 'MDM_VPNv2_01'

# // Registry clean-up
Write-Verbose "Cleaning up registry artifacts for VPN connection ""$ProfileName""..."

# // Remove registry artifacts from ERM\Tracked
Write-Verbose "Searching for profile $ProfileNameEscaped..."
    
$BasePath = "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked"
$Tracked = Get-ChildItem -Path $BasePath
    
ForEach ($Item in $Tracked) {

    Write-Verbose "Processing $(Convert-Path $Item.PsPath)..."
    $Key = Get-ChildItem $Item.PsPath -Recurse | Where-Object { $_ | Get-ItemProperty -Include "Path*" }
    $PathCount = ($Key.Property -Match "Path\d+").Count
    Write-Verbose "Found a total of $PathCount Path* entries."

    # // There may be more than 1 matching key
    ForEach ($K in $Key) {

        $Path = $K.Property | Where-Object { $_ -Match "Path\d+" }
        $Count = $Path.Count
        Write-Verbose "Found $Count Path* entries under $($K.Name)."

        ForEach ($P in $Path) {

            Write-Verbose "Testing $P..."
            $Value = $K.GetValue($P)

            If ($Value -Match "$($ProfileNameEscaped)$") {

                Write-Verbose "Removing $Value under $($K.Name)..."
                $K | Remove-ItemProperty -Name $P
                
                # // Decrement count
                $Count--

            }

        } # // ForEach $P in $Path

        #  // Update count
        Write-Verbose "Setting count to $Count..."
        $K | Set-ItemProperty -Name Count -Value $Count

    } # // ForEach $K in $Key

} # // ForEach $Item in $Tracked

# // Remove registry artifacts from NetworkList\Profiles
$Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\'
Write-Verbose "Searching $path for VPN profile ""$ProfileName""..."
$Key = Get-Childitem -Path $Path | Where-Object { (Get-ItemPropertyValue $_.PsPath -Name Description) -eq $ProfileName }

If ($Key) {

    Write-Verbose "Removing $($Key.Name)..."
    $Key | Remove-Item

}

Else {

    Write-Verbose "No profiles found matching ""$ProfileName"" in the network list."

}

# // Remove registry artifacts from RasMan\Config
$Path = 'HKLM:\System\CurrentControlSet\Services\RasMan\Config\'
$Name = 'AutoTriggerDisabledProfilesList'

Write-Verbose "Searching $Name under $Path for VPN profile called ""$ProfileName""..."

Try {

    # // Get the current registry values as an array of strings
    [string[]]$Current = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop

}

Catch {

    Write-Verbose "$Name does not exist under $Path. No action required."

}

If ($Current) {

    #// Create ordered hashtable
    $List = [Ordered]@{}
    $Current | ForEach-Object { $List.Add("$($_.ToLower())", $_) }

    # //Search hashtable for matching VPN profile and remove if present
    If ($List.Contains($ProfileName)) {

        Write-Verbose "Profile found. Removing entry..."
        $List.Remove($ProfileName)
        Write-Verbose "Updating the registry..."
        Set-ItemProperty -Path $Path -Name $Name -Value $List.Values

    }
   
}

Else {

    Write-Verbose "No profiles found matching ""$ProfileName""."

}

# // Create the VPN connection

If (!$AllUserConnection -and !$DeviceTunnel) {

    Try {

        # // Identify current user
        $UserName = Get-WmiObject -Class Win32_ComputerSystem | Select-Object UserName
        $User = New-Object System.Security.Principal.NTAccount($UserName.UserName)
        $Sid = $User.Translate([System.Security.Principal.SecurityIdentifier])
        $SidValue = $Sid.Value
        Write-Verbose "User SID is $SidValue."
    
    }
    
    Catch [Exception] {
    
        Write-Warning "$_"
        Write-Warning "Unable to get user SID. User may be logged on over Remote Desktop. Exiting script."
        Exit
    
    }

}

$Session = New-CimSession

Try {

    $NewInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $ClassName, $NamespaceName
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ParentID', "$nodeCSPURI", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('InstanceID', "$ProfileNameEscaped", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ProfileXML', "$ProfileXML", 'String', 'Property')
    $NewInstance.CimInstanceProperties.Add($Property)

    If (!$AllUserConnection -and !$DeviceTunnel) {

        $Options = New-Object Microsoft.Management.Infrastructure.Options.CimOperationOptions
        $Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Type', 'PolicyPlatform_UserContext', $False)
        $Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Id', "$SidValue", $False)
        $Session.CreateInstance($NamespaceName, $NewInstance, $Options)

    }

    Else {

        $Session.CreateInstance($NamespaceName, $NewInstance)
        
    }
    
    Write-Output "Always On VPN profile ""$ProfileName"" created successfully."

}

Catch [Exception] {

    Write-Output "Unable to create ""$ProfileName"" profile: $_"
    Exit

}

# SIG # Begin signature block
# MIIZ1wYJKoZIhvcNAQcCoIIZyDCCGcQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbHH+nZmIg96mHGx67VfuNbYW
# rs6gghTlMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
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
# SS89S5PoNaIPZmEVA2Y0A5EXi48wDQYJKoZIhvcNAQEBBQAEggEANGEnLSNFhLj6
# yOFxyhEBjG/fydFYeh5XXDvYcZDW2i1kBR5YsAhxjq1LHi313S+tgThrv1kFKzJ/
# NJ1Tax3fEHyX3xCNWebEyZlJgYoV+Gi4jDYsuvyOpSHpR8LQi0AIbNlzvgtqgU9Y
# 1j3APxBOHo2xget1H1eQuLGFCtTLU4vvS4xTJD4vpWBfHGB1uiLxR1ZExczrKg6i
# FCSMWuRgXNdGeP++C3lmdAXrq22Ev/6bZmksHaiN6UgF1rsi34LNQFtEpMGvV3Jk
# ehBrpl5lAo1CNnjh4G0aNweLMy/A9da6i5qGT9mOY9uU/XDWCsjlHH2CmRjW3heZ
# WyiM/IJAb6GCAjAwggIsBgkqhkiG9w0BCQYxggIdMIICGQIBATCBhjByMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGlt
# ZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDdMA0GCWCGSAFlAwQCAQUAoGkw
# GAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjEwNjAx
# MTcyODQyWjAvBgkqhkiG9w0BCQQxIgQgLMgp4/wdxgPLlmMhElR0ipgaYGakDKWc
# neTe6NUz1AkwDQYJKoZIhvcNAQEBBQAEggEATJyaoLlF1LDrhyl5bwSpURtOPKcC
# kXFdK/tD06SrENmWeOx2gHVm3LSysHc/BShUspEAib7Ru5WZM3ppMEa0rvJmN2ZC
# W1KJ/vJ4P+VF1wEmkGs6JUspCOuK1P+JSttikcJd3OqecGke+tk+B4PxejhCIcYn
# G4pZykSKPhKoVq9X5FPx7amR0Z+BDRFNiwaW2cGmR3So7YkJxf72GQDGvngCmnl/
# Rfkon1LdXJ287HuJmVqQjsE0EhwYqKW5XBBIwjAVcpYcAzvMF0f1VvM+pLbV/wwB
# vAjNEAt07S2N8Wnyu0q6aXbnK/8m2n1YwYbl6i/GRgQh7/NmO9svt+pgkA==
# SIG # End signature block
