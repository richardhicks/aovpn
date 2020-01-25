<#

.SYNOPSIS
    Optimizes TLS configuration for SSTP VPN connections.

.PARAMETER Performance
    TLS cipher suites optimized for performance. AES-256 ciphers are removed.

.PARAMETER Security
    TLS cipher suites optimized for security. AES-256 ciphers are included.

.EXAMPLE
    .\Optimize-VpnTlsConfiguration.ps1

    Running this command will optimize TLS configuration for performance. Cipher suites using AES-256 are not included in this configuration.

.EXAMPLE
    .\Optimize-VpnTlsConfiguration.ps1 -Performance

    Running this command will optimize TLS configuration for performance. Cipher suites using AES-256 are not included in this configuration.

.EXAMPLE
    .\Optimize-VpnTlsConfiguration.ps1 -Security

    Running this command will optimize TLS configuration for security. Cipher suites using AES-256 are included and preferred over AES-128 ciphers.

.DESCRIPTION
    Use this script to optimize TLS configuration to improve security and performance for SSTP VPN connections. TLS cipher suites are configured and optimized, TLS 1.0 and TLS 1.1 are disabled, and support for RC4 ciphers is disabled.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.11
    Creation Date:  October 24, 2019
    Last Updated:   January 25, 2020
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param (

    [switch]$Security,
    [switch]$Performance = [switch]::Present

)

# Override default performance configuration is highest level of security is required
If ($Security) {

    $Performance = $false

}

# Determine OS version
$OSVersion = (Get-CimInstance 'Win32_OperatingSystem').Version
Write-Verbose "OS Version is $OSVersion."

# Windows Server 2012/R2
If ($OSVersion -Like '6.*') {

    Write-Verbose 'Detected Windows Server 2012 or 2012R2.'

    If ($Performance) {
        
        Write-Verbose 'Using performance optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256,TLS_RSA_WITH_AES_128_GCM_SHA256'

    }

    If ($Security) {
        
        Write-Verbose 'Using security optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256'

    }

}

# Windows Server 2016 or SAC release
If ($OSVersion -Like '*14393*' -or $OSVersion -Like '*17134 *') {

    Write-Verbose 'Detected Windows Server 2016 or SAC release.'

    If ($Performance) {

        Write-Verbose 'Using performance optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'
    
    }

    If ($Security) {

        Write-Verbose 'Using security optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'

    }

}

# Windows Server 2019, Windows Server 1809, 1903, or 1909
If ($OSVersion -Like '*17763*' -or $OSVersion -Like '*17763*' -or $OSVersion -Like '*18362*' -or $OSVersion -Like '*18363*') {

    Write-Verbose 'Detected Windows Server 2019 or SAC release.'
    
    If ($Performance) {
    
        Write-Verbose 'Using performance optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'
    
    }

    If ($Security) {

        Write-Verbose 'Using security optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'
    
    }

}

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002\'
    Name         = 'Functions'
    PropertyType = 'String'
    Value        = $CipherSuiteOrder

}

# Update registry settings
Write-Verbose 'Updating TLS cipher suite configuration...'
New-ItemProperty @Parameters -Force

# Disable TLS 1.1
Write-Verbose 'Disabling TLS 1.1...'

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Disable TLS 1.0
Write-Verbose 'Disabling TLS 1.0...'

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Disable SSL 3.0
Write-Verbose 'Disabling SSL 3.0...'

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

#  Disable RC4 ciphers
Write-Verbose 'Disable RC4 ciphers...'

$Writeable = $true
$Key = (Get-Item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $Writeable).CreateSubKey('RC4 128/128')
$Key.SetValue('Enabled', '0', 'DWORD')

$Key = (Get-Item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $Writeable).CreateSubKey('RC4 56/128')
$Key.SetValue('Enabled', '0', 'DWORD')

$Key = (Get-Item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $Writeable).CreateSubKey('RC4 40/128')
$Key.SetValue('Enabled', '0', 'DWORD')

Write-Verbose 'Script complete.'
Write-Warning 'The server must be restarted for these changes to take effect.'

# SIG # Begin signature block
# MIINbAYJKoZIhvcNAQcCoIINXTCCDVkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2R81GZU/1BktFWvt60cb497F
# KiGgggquMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFi4F5HVDTPKsSXmqRh4mDZITCQEMA0G
# CSqGSIb3DQEBAQUABIIBAHkhWCcNQKlFYLWIgQdaW7/95fG0Z/bxjfOW2hIrmhY1
# sb2oBZ85xD91CsvYmKT+FoP88nsVBuS/T4ZaOiYV6qoaEbBpUAbt51imaa9EjOTz
# tRFhO0RGWaaipza4WLFZOQPtFcWX5PhoTSOuJ4NqhF6d5P1zQYUIF0K6XuA8PoGt
# xpveNLb5PCRYpe/Bp9JR3SGobp/QmVtAzaUAh5FX0Vwt41cvoO/dqnmN6TZecItC
# pGZLBz52f4fwrz7g9lPx1S3y7VCfT2NpLOTxzrSa+3KpJre1Nnr3/QwaZCVirUuO
# 2JHRwNQpt+LY2Z7jVftOcnb7Z0eS9JCdaYzJo7DgSP8=
# SIG # End signature block
