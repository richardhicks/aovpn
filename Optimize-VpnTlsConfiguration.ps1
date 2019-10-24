<#

.SYNOPSIS
    Optimizes TLS configuration for SSTP VPN connections.

.PARAMETER Performance
    TLS cipher suites optimized for performance. AES-256 ciphers removed.

.PARAMETER <parameter>
    TLS cipher suites optimized for security. AES-256 ciphers are included.

.EXAMPLE
    .\Optimize-VpnTlsConfiguration.ps1 -Performance

    Running this command will optimize TLS configuration for better performance. Cipher suites using AES-256 are not included in this configuration.

.EXAMPLE
    .\Optimize-VpnTlsConfiguration.ps1 -Security

    Running this command will optimize TLS configuration for better security. Cipher suites using AES-256 are included and preferred over AES-128 ciphers.

.DESCRIPTION
    Use this script to optimize TLS configuration to improve security and performance for SSTP VPN connections. TLS cipher suites are configured and optimized, TLS 1.0 and TLS 1.1 are disabled, and support for RC4 ciphers is disabled.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.0
    Creation Date:  October 24, 2019
    Last Updated:   October 24, 2019
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
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_128_GCM_SHA256'
    
    }

    If ($Security) {

        Write-Verbose 'Using security optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256'

    }

}

# Windows Server 2019, Windows Server 1809, 1903, or 1909
If ($OSVersion -Like '*17763*' -or $OSVersion -Like '*17763*' -or $OSVersion -Like '*18362*' -or $OSVersion -Like '*18363*') {

    Write-Verbose 'Detected Windows Server 2019 or SAC release.'
    
    If ($Performance) {
    
        Write-Verbose 'Using performance optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_128_GCM_SHA256'
    
    }

    If ($Security) {

        Write-Verbose 'Using security optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256'
    
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

$writable = $true
$key = (get-item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $writable).CreateSubKey('RC4 128/128')
$key.SetValue('Enabled', '0', 'DWORD')

$key = (get-item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $writable).CreateSubKey('RC4 56/128')
$key.SetValue('Enabled', '0', 'DWORD')

$key = (get-item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $writable).CreateSubKey('RC4 40/128')
$key.SetValue('Enabled', '0', 'DWORD')

Write-Verbose 'Done.'
Write-Warning 'The server must be restarted for these changes to take effect.'

# SIG # Begin signature block
# MIINRAYJKoZIhvcNAQcCoIINNTCCDTECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoPB7wZgwcLZ8TD9bCJGEqBQe
# j2CgggqGMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# T8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHvMIIFTjCC
# BDagAwIBAgIQDRySYKw7OlG2XJ5gdgi+ETANBgkqhkiG9w0BAQsFADByMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29k
# ZSBTaWduaW5nIENBMB4XDTE4MTIxOTAwMDAwMFoXDTE5MTIyMzEyMDAwMFowgYox
# CzAJBgNVBAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNTWlzc2lvbiBWaWVq
# bzEqMCgGA1UEChMhUmljaGFyZCBNLiBIaWNrcyBDb25zdWx0aW5nLCBJbmMuMSow
# KAYDVQQDEyFSaWNoYXJkIE0uIEhpY2tzIENvbnN1bHRpbmcsIEluYy4wggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDUHjzuLxgClv+gWiUDH0+9f5AOxNlM
# P1NukiHgYChzeuSTWsHEkx+PsdMqUJCpRtzxYupKrSVLiTp0NDcgbsrenVDR3iXa
# dKrhjaOHovAjmg+KMPkCCj7qkiBsrBHAZD0ooTwVLXKOhgbJk4Cdar6ttgPUVmZy
# 3rMuk9EjOKcd+Gbc9T0kBId3ZRCQUV7Wd/V4yzCxIcm4Vn/2KpZ2abuTeRJ6nYGE
# fKZoTpH3XCus95DypF36Bvg8virD5O8e07cOXk/8qpRetjNhCWc4y5vHWQC+k6Yj
# Coqk6TopQ59a+M/fNcqicbPMnvqNNPTDNJ3zEJLH1n01AVdA16+1CospAgMBAAGj
# ggHFMIIBwTAfBgNVHSMEGDAWgBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAdBgNVHQ4E
# FgQUC8RAAtkGb09tnKvrEQH4/M39pzAwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGGL2h0dHA6Ly9jcmwzLmRpZ2lj
# ZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWgM6Axhi9odHRwOi8vY3Js
# NC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDBMBgNVHSAERTBD
# MDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2Vy
# dC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEEeDB2MCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYBBQUHMAKGQmh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJBc3N1cmVkSURDb2RlU2ln
# bmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQDwrBWt
# OLyXkZ5jW/Y1GjxZlpNzBfswqNObyvwrg1xyNSAjVzo8lrswcqMfg/mMMr/Rx4C/
# 5y+JEJLCuR6+nuLNY8qQ5V57MtLm5/QhuwWsqMOjA7msIK67HZz8JB5QiVRaBKOg
# j6Tse+lZMkzFDGo5muwEXUKCkFBl8bXYOPne8Sd9m3mgQ+XhCbGy/f5yabKFHb9o
# JgwwaScbNAYBE0VpWLIuO8uLGmSJdezW1uGYgs1PmErPd4VBR6i4q9gJD9bnAyud
# RGwP8bLsJdP24eqXJRE+ulm+TyG9r/jL78161wXb5f0Cva1wFz808xUeagzOybS/
# qPK28b1JAJ4jpGCTMYICKDCCAiQCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8G
# A1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQQIQ
# DRySYKw7OlG2XJ5gdgi+ETAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUYqRqaQMR9HfiHxlSPVKp
# 8ARy8AMwDQYJKoZIhvcNAQEBBQAEggEAFipCN5mC5+kA9K10g6VasWCo2ejPWNBb
# nzBzP+NH01M2z6M5vpBvRO1jGqRo2HP70euXXx1I+3IgDcLbq7Ku8okabG0UzGlZ
# g7CQDMaoO8xUhYjc8Tp9sGdZ+KQljs8OE2CLBOeKNOF+X2CkY0BDxo9s4edEquRR
# 4Oz9isL1wvG3rZV09jJ0HP4ZrlhV1Ki2o+Dc8S6g4jYJ/fqo237ijdHl4CPeiLVH
# 9U/FQrhdwcbLI02pH8D1D+vuxEyTrxZiODpEOalthUUpTorm5YVI0uQA/oZqm1hJ
# SRm47LhGOG4PRULZC76dv+n7I0/LfG+otaAEi7a0p3T7zfEsmohnjA==
# SIG # End signature block
