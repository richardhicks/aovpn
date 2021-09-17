<#

.SYNOPSIS
    Configures the trusted root certification authority (CA) to be used for IKEv2 VPN connections on Windows Server Routing and Remote Access Service (RRAS) servers.

.PARAMETER Thumbprint
    Certificate thumbprint of the trusted root CA used for IKEv2 VPN connections.

.PARAMETER Eku
    Enhanced Key Usage (EKU) Object Identifier (OID) to be used for machine certificate EKU filtering.

.PARAMETER EnableCertificateAuthentication
    Enables machine certificate authentication for IKEv2 VPN connections.

.PARAMETER Clear
    Clears the currently configured root CA and machine certificate EKU filtering settings.

.PARAMETER Restart
    Restarts the RemoteAccess service.

.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Clear

    Running this command will clear the existing root CA and machine certificate EKU filtering settings.

.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Thumbprint '71899A67BF33AF31BEFDC071F8F733B183856332'

    Running this command will configure RRAS to use this CA as the exclusive trusted CA for all IKEv2 VPN connections.

.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Thumbprint '71899A67BF33AF31BEFDC071F8F733B183856332' -Eku '1.3.6.1.5.5.7.3.2'

    Running this command will configure RRAS to use this CA as the exclusive trusted CA for all IKEv2 VPN connections and accept only certificates with the 1.3.6.1.5.5.7.3.2 EKU.
    
.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Thumbprint '71899A67BF33AF31BEFDC071F8F733B183856332' -EnableCertificateAuthentication

    Running this command will configure RRAS to use this certification authority as the exclusive trusted CA for all IKEv2 VPN connections. Including the -EnableCertificateAuthentication switch will automatically add Certificate authentication to the list of accepted user authentication protocols (a prerequisite for setting root CA certificate).

.DESCRIPTION
    Use this script to configure the trusted root CA and machine certificate EKU filter settings for IKEv2 VPN connections.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.4
    Creation Date:  August 2, 2019
    Last Updated:   September 17, 2021
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com/

#>

[CmdletBinding()]

Param (

    [string]$Thumbprint,
    [string]$Eku,
    [switch]$EnableCertificateAuthentication, 
    [switch]$Clear,
    [switch]$Restart

)

# // Clear current root certificate configuration
If ($Clear) {

    Write-Verbose 'Clearing existing root certificate and EKU configuration...'
    Set-VpnAuthProtocol -RootCertificateNameToAccept $Null | Out-Null
    Set-VpnAuthProtocol -CertificateEKUsToAccept $Null | Out-Null

    If ($Restart) {

        Write-Verbose 'Restarting the RemoteAccess Service...'
        Restart-Service RemoteAccess -PassThru
        
    }

    ElseIf (-Not $Restart) {
        
        Write-Warning 'The RemoteAccess service must be restarted for these changes to take effect.'
    }

    Exit

}

# // Get current user authentication protocol configuration
$VpnAuthProtocol = (Get-VpnAuthProtocol | Select-Object -ExpandProperty UserAuthProtocolAccepted)

# // Ensure that certificate authentication is enabled
If ($VpnAuthProtocol -like '*certificate*') {

    Write-Verbose 'Certificate authentication is enabled.'

}

ElseIf (-Not $EnableCertificateAuthentication) {

    Write-Warning 'Certificate authentication not enabled. Use the -EnableCertificateAuthentication parameter to configure it.'
    Exit

}

# // Assign root CA certificate 
$RootCACert = (Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $Thumbprint } | Select-Object -First 1)

# // Create user authentication protocol array
$Protocols = @()
$Protocols = { $Protocols }.Invoke()

ForEach ($Protocol in $VpnAuthProtocol) {

    $Protocols.Add($Protocol)

}

# // Add the Certificate authentication protocol if required
If ($EnableCertificateAuthentication) {

    $Protocols.Add('Certificate')

}

Set-VpnAuthProtocol -UserAuthProtocolAccepted $Protocols -RootCertificateNameToAccept $RootCACert | Out-Null

If ($Eku) {

    Write-Verbose "Using $Eku for the Machine Certificate EKU filter..."
    Set-VpnAuthProtocol -CertificateEKUsToAccept $Eku | Out-Null
    Write-Warning 'Ignore the Machine Certificate EKU filter is invalid warning. This is a bug.'

}

# // Validate correct root CA certificate configured

$ConfiguredThumbprint = (Get-VpnAuthProtocol | Select-Object -ExpandProperty RootCertificateNameToAccept).Thumbprint

If ($ConfiguredThumbprint -ne $Thumbprint) {

    Write-Warning "Specified root CA certificate $Thumbprint does not match configured certificate $ConfiguredThumbprint. Check root CA certificate store for old certificates."

}

If ($Restart) {
    
    Write-Verbose 'Restarting the RemoteAccess service...'
    Restart-Service RemoteAccess -PassThru

}

Else {

    Write-Warning 'The RemoteAccess service must be restarted for these changes to take effect.'

}

# SIG # Begin signature block
# MIIZ1wYJKoZIhvcNAQcCoIIZyDCCGcQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5bjtPR5CpPHMIyrIyP4NraLc
# 742gghTlMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
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
# f+MsJ6fnDD6zLHzck5bRdAwwNVcwDQYJKoZIhvcNAQEBBQAEggEALGETCsj3ubal
# twoksKGmY18qgutGDu/BIqamge3IehDFpm0Dr1c2RZQhQjqi0qJQ5VJNdBz+PDNz
# kpt2BvGq/xSC43qs7QLXIMjsVxQ8uWfS9+yF46vOAdwuTZTVCIWRp6VWxO6sFMey
# ycGogdlgDoHtlef9Ebo+dc73MkhQ5DHuQ6njJ0YDrGV6XVBZ0u06n7V1MKk/Ooiy
# 7+zi/17KHPpq5wVNTl6oFHUd3OO31qKcVeo3mmMI8lbcQSjxsadVyxoXQwcmrugC
# BPCSVF3hv68/boMcjQhatn7g926rsrqSpmivOW1tf/gX74ol5nfrYz8QmPeY3JzY
# YV3MYMB0v6GCAjAwggIsBgkqhkiG9w0BCQYxggIdMIICGQIBATCBhjByMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGlt
# ZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDdMA0GCWCGSAFlAwQCAQUAoGkw
# GAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjEwOTE3
# MTc0NjI3WjAvBgkqhkiG9w0BCQQxIgQgfbDxOyQwSV4nvdIhh0OJCYx1UygLtsyH
# PEL1sVtAbOswDQYJKoZIhvcNAQEBBQAEggEAfDXP7ccRfsVBan/EJRZprid2sckj
# JYdNO29Dar580NpIDU30lHRFndXJtdlHPtuqZ+ZivTKd64kIzkn4yWy0eNUxC3H6
# 0ti4oXoQu4cPBe/7CGnTozPzVXSdLorPHicGjK/PeXvL0CwEni4hEK7KX49bG1Qc
# zzopqUZeeH+BEzM7TRADfRP/TjfTjy+xMBFZWrrWIun7PBlNZufJGVAAAYa/2KDl
# TtJKN7E/s8bb3gEpe7MIZv9FUcEvbwR+m5/6eIr7OZnwXK8+DuupM5Ko6kdPTzv3
# msSIw+NrD98ZjBKm2V0W8tLKdE7N3JQAuVUpXOuYeeJUBfLIQecpoyxHtA==
# SIG # End signature block
