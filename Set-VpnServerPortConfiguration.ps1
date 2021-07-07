<#

.SYNOPSIS
    PowerShell script to configured SSTP and IKEv2 VPN ports on a Windows Server Routing and Remote Access Service (RRAS) server.

.PARAMETER SstpPorts
    Specifies the number of SSTP ports to provision on the RRAS VPN server.

.PARAMETER Ikev2Ports
    Specifies the number of IKEv2 ports to provision on the RRAS VPN server.

.PARAMETER Restart
    Restarts the RasMan and RemoteAccess services to apply the changes.

.EXAMPLE
    .\Set-VpnPortConfiguration.ps1 -SstpPorts 2000 -Ikev2Ports 2000

    Running this PowerShell command will configure 2000 SSTP and IKEv2 ports.

.DESCRIPTION
    This script is used to quickly configure SSTP and IKEv2 VPN ports. It also disables the GRE, PPPOE, PPTP, and L2TP legacy VPN protocols.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.42
    Creation Date:  February 13, 2020
    Last Updated:   July 7, 2021
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com/

#>

[CmdletBinding()]

Param (

    [Parameter(Mandatory, HelpMessage = "Enter the number of IKEv2 ports to enable.")]
    [string]$Ikev2Ports = '128',
    [Parameter(Mandatory, HelpMessage = "Enter the number of SSTP ports to enable.")]
    [string]$SstpPorts = '128',
    [switch]$Restart

)

# // Disable PPPOE ports
Write-Verbose 'Disabling PPPOE ports...'
Invoke-Command -ScriptBlock { netsh.exe ras set wanports device = "WAN Miniport (PPPOE)" ddoutonly = disabled maxports = 1 } | Out-Null

# // Disable GRE ports
Write-Verbose 'Disabling GRE ports...'
Invoke-Command -ScriptBlock { netsh.exe ras set wanports device = "WAN Miniport (GRE)" rasinonly = disabled ddinout = disabled ddoutonly = disabled maxports = 0 } | Out-Null

# // Disable L2TP ports
Write-Verbose 'Disabling L2TP ports...'
Invoke-Command -ScriptBlock { netsh.exe ras set wanports device = "WAN Miniport (L2TP)" rasinonly = disabled ddinout = disabled ddoutonly = disabled maxports = 0 } | Out-Null

# // Disable PPTP ports
Write-Verbose 'Disabling PPTP ports...'
Invoke-Command -ScriptBlock { netsh.exe ras set wanports device = "WAN Miniport (PPTP)" rasinonly = disabled ddinout = disabled ddoutonly = disabled maxports = 1 } | Out-Null

# // Configure SSTP ports
If ($SstpPorts -eq '0') {

    Write-Verbose "Disabling SSTP ports..."
    Invoke-Command -ScriptBlock { netsh.exe ras set wanports device = "WAN Miniport (SSTP)" rasinonly = disabled ddinout = disabled ddoutonly = disabled maxports = 0 } | Out-Null

}

Else {

    Write-Verbose "Configuring $SstpPorts SSTP ports..."
    Invoke-Command -ScriptBlock { netsh.exe ras set wanports device = "WAN Miniport (SSTP)" rasinonly = enabled ddinout = disabled ddoutonly = disabled maxports = $SstpPorts } | Out-Null

}

# // Configure IKEv2 ports
If ($Ikev2Ports -eq '0') {

    Write-Verbose "Disabling IKEv2 ports..."
    Invoke-Command -ScriptBlock { netsh.exe ras set wanports device = "WAN Miniport (IKEv2)" rasinonly = disabled ddinout = disabled ddoutonly = disabled maxports = 0 } | Out-Null

}

Else {

    Write-Verbose "Configuring $Ikev2Ports IKEv2 ports..."
    Invoke-Command -ScriptBlock { netsh.exe ras set wanports device = "WAN Miniport (IKEv2)" rasinonly = enabled ddinout = disabled ddoutonly = disabled maxports = $Ikev2Ports } | Out-Null

}

If ($Restart) {

    Write-Verbose 'Restarting the RasMan and RemoteAccess services...'
    Restart-Service RasMan -Force -PassThru

}

Else {

    Write-Warning 'The RasMan and RemoteAccess services must be restarted for these changes to take effect.' 

}

# SIG # Begin signature block
# MIIZ1wYJKoZIhvcNAQcCoIIZyDCCGcQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQKD0Ap3Pe2ScftBmRks0a8r2
# +aWgghTlMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
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
# pkmn40z27YE06VDz+XvFdVW/grgwDQYJKoZIhvcNAQEBBQAEggEAiga6c2rHSQ2N
# pC/bEpbT/IbA1D54dYwicOkddtP7NG6JBygrAVPmxZs/vlkrPOdl31Mf1NvB/o6y
# IxZiipeHMgx4Jmc6yNknvwfUqiu0m8RvCcUGOeKKfxuhTljsZvBXS3rctFvJ3/nz
# EKC/D+r3DZr0xQfizv9AV7JmfuHiuXvZ+Vdtr542tG1jwtDyJgbP33V9zpmOmfpR
# L2JTy+hA4/QT8kpoX68biccUcZfYr+7wDFvJ/3DGf+6Ks0pZYOl5qPGJFBAqiE76
# htsRevVKx77B8VLu24//6Ce7sDWM+dHlLVe396RD9xi8SJpODTRN+JZ2VWxZwaEG
# Qli/zWzhZ6GCAjAwggIsBgkqhkiG9w0BCQYxggIdMIICGQIBATCBhjByMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGlt
# ZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDdMA0GCWCGSAFlAwQCAQUAoGkw
# GAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjEwNzA3
# MjIzMDQwWjAvBgkqhkiG9w0BCQQxIgQgQUk7dlvM0PnuW9410x5eZ8g8jgb6PAEV
# Z6ROQqscqcAwDQYJKoZIhvcNAQEBBQAEggEAY+ld0KGdN/kFGsMccZUToHJ5mn4p
# bq77s60BTHceXx7JmTlns+/DqlWeyn/ma54q6OvvVMkb7tMqCbJwg3Pmy63nXKxJ
# NDxTk5GQxj8eoCxLiGH2lyuB1rxgvfbzoLee5YXq1dB/AHkdeYHqww9MX/0+VXix
# dbpROKXmw+LqfyZtE+6F/qiC1rOmQzsDIlORTIF7xUKojiWjE9DwVHOPO36R/8Hf
# AYc2K/rLy/dFuiDvw+ImTKXgs1727F7i43wiavjSwnXcEr4YsqJB0SmMze39blPf
# CBFQfzz+UsQvVQjbNQ09XV53Z3FA+J24AxktG9OGaX3WXgUjc393zFzoaQ==
# SIG # End signature block
