<#

.SYNOPSIS
    Configures the trusted root certification authority to be used for IKEv2 VPN connection on Windows Server Routing and Remote Access Service (RRAS) servers.

.PARAMETER Thumbprint
    Certificate hash of the trusted root certification authority used for IKEv2 VPN connections.

.PARAMETER EnableCertificateAuthnetication
    Enables machine certificate authentication for IKEv2 VPN connections.

.PARAMETER Clear
    Clears the currently configured root certification authority.

.PARAMETER Restart
    Restarts the RemoteAccess service.

.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Clear

    Running this command will clear the existing root certification authority configuration.

.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Thumbprint '71899A67BF33AF31BEFDC071F8F733B183856332' -Restart

    Running this command will configure RRAS to use this certification authority as the exclusive trusted CA for all IKEv2 VPN connections. Including the -Restart swtich restarts the RemoteAccess service for changes to take effect.
    
.EXAMPLE
    .\Set-IKEv2VPNRootCertificate.ps1 -Thumbprint '71899A67BF33AF31BEFDC071F8F733B183856332' -EnableCertificateAuthentication

    Running this command will configure RRAS to use this certification authority as the exclusive trusted CA for all IKEv2 VPN connections. Including the -EnableCertificateAuthentication switch will automatically add Certificate authentication to the list of accepted user authentication protocols (prerequisite for setting root CA cert).

.DESCRIPTION
    Use this script to configure the trusted root certification authority for IKEv2 VPN connections.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.11
    Creation Date:  August 2, 2019
    Last Updated:   October 29, 2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param (
    
    [string]$Thumbprint,
    [switch]$EnableCertificateAuthentication,
    [switch]$Clear,
    [switch]$Restart

)

# Clear current root certificate configuration
If ($Clear) {

    Write-Verbose 'Clearing existing root certificate configuration...'
    Set-VpnAuthProtocol -RootCertificateNameToAccept $Null

    If ($Restart) {

        Write-Verbose 'Restarting the RemoteAccess Service...'
        Restart-Service RemoteAccess -PassThru
        
    }

    ElseIf (-Not $Restart) {
        
        Write-Warning 'The RemoteAccess service must be restarted for these changes to take effect.'
    }

    Exit

}

# Get current user authentication protocol configuration
$VpnAuthProtocol = (Get-VpnAuthProtocol | Select-Object -ExpandProperty UserAuthProtocolAccepted)

# Ensure that certificate authentication is enabled
If ($VpnAuthProtocol -like '*certificate*') {

    Write-Verbose 'Certificate authentication enabled.'

}

ElseIf (-Not $EnableCertificateAuthentication) {

    Write-Warning 'Certificate authentication not enabled. Use the -EnableCertificateAuthentication parameter to configure it.'
    Exit

}

# Assign root certificate 
$RootCACert = (Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $Thumbprint } | Select-Object -First 1)

# Create user authentication protocol array
$Protocols = @()
$Protocols = { $Protocols }.Invoke()

ForEach ($Protocol in $VpnAuthProtocol) {

    $Protocols.Add($Protocol)

}

# Add the Certificate authentication protocol is required
If ($EnableCertificateAuthentication) {

    $Protocols.Add('Certificate')

}

Write-Verbose 'Updating trusted root certificate information...'
Set-VpnAuthProtocol -UserAuthProtocolAccepted $Protocols -RootCertificateNameToAccept $RootCACert -PassThru

If ($Restart) {
    
    Write-Verbose 'Restarting the RemoteAccess service...'
    Restart-Service RemoteAccess -PassThru

}

Else {

    Write-Warning 'The RemoteAccess service must be restarted for these changes to take effect.'

}

# SIG # Begin signature block
# MIIeXgYJKoZIhvcNAQcCoIIeTzCCHksCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYx543wRuwl9qj
# dDpbXngFTtLwDnMbm32Sb1T/oCMU66CCGC0wggTQMIIDuKADAgECAgEHMA0GCSqG
# SIb3DQEBCwUAMIGDMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEG
# A1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20sIEluYy4xMTAv
# BgNVBAMTKEdvIERhZGR5IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIw
# HhcNMTEwNTAzMDcwMDAwWhcNMzEwNTAzMDcwMDAwWjCBtDELMAkGA1UEBhMCVVMx
# EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoT
# EUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQLEyRodHRwOi8vY2VydHMuZ29kYWRk
# eS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMTKkdvIERhZGR5IFNlY3VyZSBDZXJ0
# aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBALngyxDUr3a91JNi6zBkuIEIbMME2WIXji//PmXPj85i5jxSHNoWRUtV
# q3hrY4NikM4PaWyZyBoUi0zMRTPqiNyeo68r/oBhnXlXxM8u9D8wPF1H/JoWvMM3
# lkFRjhFLVPgovtCMvvAwOB7zsCb4Zkdjbd5xJkePOEdT0UYdtOPcAOpFrL28cdmq
# bwDb280wOnlPX0xH+B3vW8LEnWA7sbJDkdikM07qs9YnT60liqXG9NXQpq50BWRX
# iLVEVdQtKjo++Li96TIKApRkxBY6UPFKrud5M68MIAd/6N8EOcJpAmxjUvp3wRvI
# dIfIuZMYUFQ1S2lOvDvTSS4f3MHSUvsCAwEAAaOCARowggEWMA8GA1UdEwEB/wQF
# MAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBRAwr0njsw0gzCiM9f7bLPw
# tCyAzjAfBgNVHSMEGDAWgBQ6moUHEGcotu/2vQVBbiDBlNoP3jA0BggrBgEFBQcB
# AQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmdvZGFkZHkuY29tLzA1BgNV
# HR8ELjAsMCqgKKAmhiRodHRwOi8vY3JsLmdvZGFkZHkuY29tL2dkcm9vdC1nMi5j
# cmwwRgYDVR0gBD8wPTA7BgRVHSAAMDMwMQYIKwYBBQUHAgEWJWh0dHBzOi8vY2Vy
# dHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQELBQADggEBAAh+
# bJMQyDi4lqmQS/+hX08E72w+nIgGyVCPpnP3VzEbvrzkL9v4utNb4LTn5nliDgyi
# 12pjczG19ahIpDsILaJdkNe0fCVPEVYwxLZEnXssneVe5u8MYaq/5Cob7oSeuIN9
# wUPORKcTcA2RH/TIE62DYNnYcqhzJB61rCIOyheJYlhEG6uJJQEAD83EG2LbUbTT
# D1Eqm/S8c/x2zjakzdnYLOqum/UqspDRTXUYij+KQZAjfVtL/qQDWJtGssNgYIP4
# fVBBzsKhkMO77wIv0hVU7kQV2Qqup4oz7bEtdjYm3ATrn/dhHxXch2/uRpYoraEm
# fQoJpy4Eo428+LwEMAEwggYWMIIE/qADAgECAghbZ4Hi0Ob70zANBgkqhkiG9w0B
# AQsFADCBtDELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcT
# ClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQL
# EyRodHRwOi8vY2VydHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMT
# KkdvIERhZGR5IFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjAeFw0x
# OTExMTgxNDQ4NTlaFw0yMjExMTgxNDQ4NTlaMFgxCzAJBgNVBAYTAkNIMREwDwYD
# VQQIEwhGcmlib3VyZzEQMA4GA1UEBxMHRmxhbWF0dDERMA8GA1UEChMIQ09NRVQg
# QUcxETAPBgNVBAMTCENPTUVUIEFHMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAqqM1W7t7X8710SojpXCWWr8i2GkK9yOuXUZROyz535JcbA/HnrlhIOrX
# AF8f/mY64ComkbJZX+lvJ4i0Db3gp1VQ+y5POoDPduPuWe8wLnZxZ+LMoYrpvBwE
# co5g+RdeJ9/FsSql4ZitfFd4JHf7ZUb4diDmaoUYRvqkFkU/ZvWEDeFQYfR1AoLa
# LJqZkRtSfYNsI0XIGU6P5fqaMRzHwKpl4HMsxBC1FF8UkdmIjF22QyU5FAv5PDZ3
# 0bozWtH9CrnVZYQm5Q/ZUkHlNrCB9kv/ZCOS1qUGFSWshJp5TDaz1+Za7C3HU5Ug
# cqr/SRa+ZVWUwaPPfX3TPfxEBkNJEQfQ6WK7yUnSoi8sf4jqgsZBBpm5IWTOocuH
# 2G5qXq6d8IkPuNPCyGomaxRF2vz1GN0LSvgs+g65RGt8RHN+PWwACaSsy6EuI+8O
# t1Gr5E3DA0wzxXoOzBl81E42aUR/Zqrrqk6kIHXVF+G1hDoNMKpNNkXbm5Wnz+oz
# FQqwPB9cJi5tRXbN/YxMWgEctCgvYv55mpljYJWqt0sv8pwOgPGKdHJMgAhXMyOf
# aYCJ7G3lWGlO19Jn8O67y0lqLpML3xOnwQ93LuC/MAqPnAxuUX6gawo3e9ChKUSH
# +2N347UnnRSI4Wg5oeVsgG+Qydqbggf71wmw82lto4JvZPLXUGECAwEAAaOCAYUw
# ggGBMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/
# BAQDAgeAMDUGA1UdHwQuMCwwKqAooCaGJGh0dHA6Ly9jcmwuZ29kYWRkeS5jb20v
# Z2RpZzJzNS01LmNybDBdBgNVHSAEVjBUMEgGC2CGSAGG/W0BBxcCMDkwNwYIKwYB
# BQUHAgEWK2h0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9y
# eS8wCAYGZ4EMAQQBMHYGCCsGAQUFBwEBBGowaDAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZ29kYWRkeS5jb20vMEAGCCsGAQUFBzAChjRodHRwOi8vY2VydGlmaWNh
# dGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvZ2RpZzIuY3J0MB8GA1UdIwQYMBaA
# FEDCvSeOzDSDMKIz1/tss/C0LIDOMB0GA1UdDgQWBBSDrfzKd5ZIsfu+ulqHmwNt
# UBwy/jANBgkqhkiG9w0BAQsFAAOCAQEAMTJTOkuKOa0Z36qY/dy+DRJ3sLFZiLT+
# ea1HNC7mTUrnGEJg/0/JLh9EcAoUjVqvKrQWs5ZHozbbLMjD6e9dKWXV5F2E7caB
# nE+wpfM3GaJU+B0lg23zgP1DmeO7RSxxVqT18Zb4ULmuk0zgSHi02gCFJvtVFxAt
# X6X1qSh29I7k2JJaZhQBtQc0KgHPdl9LR1r0doHw922B5naU/TsMNQE8CVK7SlyK
# frbO3AVX+voRgNjuVHe88aVQAralJJR1pBfrQJp6Aj6f/fF3kEo0biHCpkz48yCY
# f7ptJk2xUNG40t8rPNLq7uLF3KcPA22ne35DfOg132x0UEJauvwgBDCCBmowggVS
# oAMCAQICEAMBmgI6/1ixa9bV6uYX8GYwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMB4XDTE0
# MTAyMjAwMDAwMFoXDTI0MTAyMjAwMDAwMFowRzELMAkGA1UEBhMCVVMxETAPBgNV
# BAoTCERpZ2lDZXJ0MSUwIwYDVQQDExxEaWdpQ2VydCBUaW1lc3RhbXAgUmVzcG9u
# ZGVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo2Rd/Hyz4II14OD2
# xirmSXU7zG7gU6mfH2RZ5nxrf2uMnVX4kuOe1VpjWwJJUNmDzm9m7t3LhelfpfnU
# h3SIRDsZyeX1kZ/GFDmsJOqoSyyRicxeKPRktlC39RKzc5YKZ6O+YZ+u8/0SeHUO
# plsU/UUjjoZEVX0YhgWMVYd5SEb3yg6Np95OX+Koti1ZAmGIYXIYaLm4fO7m5zQv
# MXeBMB+7NgGN7yfj95rwTDFkjePr+hmHqH7P7IwMNlt6wXq4eMfJBi5GEMiN6ARg
# 27xzdPpO2P6qQPGyznBGg+naQKFZOtkVCVeZVjCT88lhzNAIzGvsYkKRrALA76Tw
# iRGPdwIDAQABo4IDNTCCAzEwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAw
# FgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwggG/BgNVHSAEggG2MIIBsjCCAaEGCWCG
# SAGG/WwHATCCAZIwKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNv
# bS9DUFMwggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYA
# IAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkA
# dAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAA
# RABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAA
# UgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAA
# dwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4A
# ZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkA
# bgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMB8GA1Ud
# IwQYMBaAFBUAEisTmLKZB+0e36K+Vw0rZwLNMB0GA1UdDgQWBBRhWk0ktkkynUoq
# eRqDS/QeicHKfTB9BgNVHR8EdjB0MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNybDA4oDagNIYyaHR0cDovL2Ny
# bDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcmwwdwYIKwYB
# BQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w
# QQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRENBLTEuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQCdJX4bM02yJoFc
# m4bOIyAPgIfliP//sdRqLDHtOhcZcRfNqRu8WhY5AJ3jbITkWkD73gYBjDf6m7Gd
# JH7+IKRXrVu3mrBgJuppVyFdNC8fcbCDlBkFazWQEKB7l8f2P+fiEUGmvWLZ8Cc9
# OB0obzpSCfDscGLTYkuw4HOmksDTjjHYL+NtFxMG7uQDthSr849Dp3GdId0UyhVd
# kkHa+Q+B0Zl0DSbEDn8btfWg8cZ3BigV6diT5VUW8LsKqxzbXEgnZsijiwoc5ZXa
# rsQuWaBh3drzbaJh6YoLbewSGL33VVRAA5Ira8JRwgpIr7DUbuD0FAo6G+OPPcqv
# ao173NhEMIIGzTCCBbWgAwIBAgIQBv35A5YDreoACus/J7u6GzANBgkqhkiG9w0B
# AQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMjExMTEwMDAwMDAwWjBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTEw
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDogi2Z+crCQpWlgHNAcNKe
# VlRcqcTSQQaPyTP8TUWRXIGf7Syc+BZZ3561JBXCmLm0d0ncicQK2q/LXmvtrbBx
# MevPOkAMRk2T7It6NggDqww0/hhJgv7HxzFIgHweog+SDlDJxofrNj/YMMP/pvf7
# os1vcyP+rFYFkPAyIRaJxnCI+QWXfaPHQ90C6Ds97bFBo+0/vtuVSMTuHrPyvAwr
# mdDGXRJCgeGDboJzPyZLFJCuWWYKxI2+0s4Grq2Eb0iEm09AufFM8q+Y+/bOQF1c
# 9qjxL6/siSLyaxhlscFzrdfx2M8eCnRcQrhofrfVdwonVnwPYqQ/MhRglf0HBKIJ
# AgMBAAGjggN6MIIDdjAOBgNVHQ8BAf8EBAMCAYYwOwYDVR0lBDQwMgYIKwYBBQUH
# AwEGCCsGAQUFBwMCBggrBgEFBQcDAwYIKwYBBQUHAwQGCCsGAQUFBwMIMIIB0gYD
# VR0gBIIByTCCAcUwggG0BgpghkgBhv1sAAEEMIIBpDA6BggrBgEFBQcCARYuaHR0
# cDovL3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQG
# CCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMA
# IABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMA
# IABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMA
# ZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkA
# bgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgA
# IABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUA
# IABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAA
# cgBlAGYAZQByAGUAbgBjAGUALjALBglghkgBhv1sAxUwEgYDVR0TAQH/BAgwBgEB
# /wIBADB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6oDig
# NoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNybDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDAdBgNVHQ4EFgQUFQASKxOYspkH7R7for5XDStn
# As0wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQEF
# BQADggEBAEZQPsm3KCSnOB22WymvUs9S6TFHq1Zce9UNC0Gz7+x1H3Q48rJcYaKc
# lcNQ5IK5I9G6OoZyrTh4rHVdFxc0ckeFlFbR67s2hHfMJKXzBBlVqefj56tizfuL
# LZDCwNK1lL1eT7EF0g49GqkUW6aGMWKoqDPkmzmnxPXOHXh2lCVz5Cqrz5x2S+1f
# wksW5EtwTACJHvzFebxMElf+X+EevAJdqP77BzhPDcZdkbkPZ0XN1oPt55INjbFp
# jE/7WeAjD9KqrgB87pxCDs+R1ye3Fu4Pw718CqDuLAhVhSK46xgaTfwqIa1JMYNH
# lXdx3LEbS0scEJx3FMGdTy9alQgpECYxggWHMIIFgwIBATCBwTCBtDELMAkGA1UE
# BhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAY
# BgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQLEyRodHRwOi8vY2VydHMu
# Z29kYWRkeS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMTKkdvIERhZGR5IFNlY3Vy
# ZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMgIIW2eB4tDm+9MwDQYJYIZIAWUD
# BAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkq
# hkiG9w0BCQQxIgQg+MfbkT/2BZMZ5zYoEa8SAFvCfh2b1f8ppCPwQ8bRksMwDQYJ
# KoZIhvcNAQEBBQAEggIAdMuVYRu5VYpYMUtxXY2/ONdHCDXZfZme1n1NnkAEfyBw
# oZEiYPQstivDpAVzrF0DE4hfhSm99CNdrnjdwmbew4e6um4P60JnTGQvBU3qqnl9
# ZZ1SmpcjCwspYA/g/RvTG5yFZqhnZsgry5BdGskkTdZwcZ8SDXQGTpJFjMd4D7jj
# X7FYapco9xVYzI6TQfiGgHkhBrzza9cDT8apxGXZgyFmkxoZ3gGqqh6tHatzV5Q+
# IEzEbKzpBIo/WGtJlQx2Oac6VI64DenRH+t6JbfDNugWW5xqYZaBxfp5g3ymtVk3
# AI594fo6tAXlyNjuiBZOZqwXqOjdaMp6sdLjlnvzVdOcRReL16ShNCTzQ1b1ytRR
# Ldc2pTVYXmkAV1DD9oacCIQBzTgIMNqlDfChTm7I8MGP9h3azRLWsTN8SMlE1wl/
# 6jhjtdqph6UoEQI0bBKV2/5boUBHfyuGN6M/B5zHInMsuqFcxNfb0FP76FECIFjL
# pSb5zUPWDkkEFv99vqay7PIgEjo4TaG6Y0s/82l5A31OaBxTZsbx02zLC2m0J8sr
# 9NwN4gwVavlDYrW+/EH1Gg+vj3VH7cHnVaP1NSYaOQitLPvJU+Gy0l0QfIaE8aKo
# Tczim07sh9IA/Bv9Q1Aq1ObArS+gPNSrJFYxoivrPJeGKcqwm1KNWtOmBFTt63Gh
# ggIPMIICCwYJKoZIhvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ixa9bV
# 6uYX8GYwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJ
# KoZIhvcNAQkFMQ8XDTIwMDYyOTIwNTA0MFowIwYJKoZIhvcNAQkEMRYEFNAGOvtd
# 6j67rgpHAneYU0Nx5k+UMA0GCSqGSIb3DQEBAQUABIIBAHPvnyWxYmlK7B7XAFpP
# 0XqhcJdvyVkJZmiFsVftP6HAqEqfYuPfaaJA8lqX2MmPIx6dco7ynnourDpXDzGV
# xdxAPu59wtJsLd5oZaQS2YKMEc3M6aY+8t/EktJ4LSZOvwKGk+ZWI/k24RLSltzC
# aO6gLiwTrpjnTezReH7rmxqhOG0Zmns0xTCHAkt6n+8uibGrCuoymHQPd/DGIbZ4
# W64jBDRv5mSIPWNMrmgGSdPuTE9ZerfPdLgLeePnnSxQZkVsRMtr8hCwOTLvMntw
# bz3ET2LQgd+/abIUBjC26k9HLC9aHfVksachSzemjznLG2v6+tGaJbx8pki1JoRA
# x8A=
# SIG # End signature block
