<#

.SYNOPSIS
    Enable IKEv2 fragmentation support on Windows Server 1803 and later operating systems.

.EXAMPLE
    Enable-IKEv2VPNFragmentation.ps1

.DESCRIPTION
    Create a registry entry to enable IKEv2 fragmentation support on Windows Server 1803 and later operating systmes.

.LINK
    https://directaccess.richardhicks.com/2019/02/11/always-on-vpn-and-ikev2-fragmentation/

.NOTES
    Version:        1.0
    Creation Date:  August 3, 2019
    Last Updated:   August 3, 2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param (

)

$OSVersion = (Get-CimInstance 'Win32_OperatingSystem').Version

# Must be running Windows Server 1803 or later to support IKEv2 fragmentation. Abort script if earlier release is detected.
If ($OSVersion -lt '10.0.17134') {

    Write-Warning 'IKEv2 VPN fragmentation is only supported on Windows Server 1803 (10.0.17134) or later operating systems. Exiting script.'
    Exit

}

# Registry settings
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\Ikev2\'
    Name         = 'EnableServerFragmentation'
    PropertyType = 'DWORD'
    Value        = '1'

}

Write-Verbose 'Adding registry entry to enable IKEv2 fragmentation support...'

New-ItemProperty @Parameters -Force

Write-Warning 'The server must be restarted for these changes to take effect!'

# SIG # Begin signature block
# MIINRAYJKoZIhvcNAQcCoIINNTCCDTECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUeh5GWKlFu176deLyiDQhLf6J
# Q++gggqGMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUAh3RBrEoVNjMFtnQyGj8
# EH0MnU4wDQYJKoZIhvcNAQEBBQAEggEAJQOA49ZxLHeiI6G/1eCwYyzpg/E5WleQ
# KZEq2oMmZHGzUf1Xzwmh1MupjpekP49cRYW2du7dpJZQFIJjGkvjZaX3jZZIEki3
# sQzbIuZdYfD2L3YED5ZIViLE19L0+V1ZMN68kRTtv99dhylTUDVMyz8SHC616l7T
# vW7cvT0x6ql2wcQR7wTZxhqul+k9LVbk3QELXTQZbkSPnl+Gi/q067sYhyOYuJ1I
# h/oPK5OOcDrACpiknrqPEDPqWj6WiNt78/kLmpSBdHMdnlY6VkxFqf5/FiqEYI+D
# wuPsGwxnZYZlSjq01dha3FO0Nd3T+RFKmkE39MFPyrn0lwjuteYDCQ==
# SIG # End signature block
