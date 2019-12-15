<#

.SYNOPSIS
    Optimizes the DirectAccess/Routing and Remote Access Service (RRAS) inbox accounting database.

.EXAMPLE
    .\Optimize-InboxAccountingDatabase.ps1

.DESCRIPTION
    The DirectAccess/RRAS inbox accounting database is missing a crucial index on one of the tables in the database. This can cause high CPU utilization for very busy DirectAccess/RRAS VPN servers. Running this script will add the missing index and improve performance.

.LINK
    https://technet.microsoft.com/en-us/library/mt693376(v=ws.11).aspx

.NOTES
    Version:         1.0
    Creation Date:   December 15, 2019
    Last Updated:    December 15, 2019
    Special Note:    This script adapted from published guidance provided by Microsoft.
    Original Author: Microsoft Corporation
    Original Script: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/mt693376(v=ws.11)
    Author:          Richard Hicks
    Organization:    Richard M. Hicks Consulting, Inc.
    Contact:         rich@richardhicks.com
    Web Site:        www.richardhicks.com

#>

[CmdletBinding()]

Param(


)

$Connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$Connection.ConnectionString = 'Server=np:\\.\pipe\Microsoft##WID\tsql\query;Database=RaAcctDb;Trusted_Connection=True;'
$Command = $Connection.CreateCommand()
$Command.CommandText = "CREATE INDEX IdxSessionTblState ON [RaAcctDb].[dbo].[SessionTable] ([SessionState]) INCLUDE ([ConnectionId])"
$Connection.Open()
$Command.ExecuteNonQuery()
$Connection.close()

# SIG # Begin signature block
# MIINRAYJKoZIhvcNAQcCoIINNTCCDTECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUALHZdvBXulBFddbfpHCw4BbG
# lw+gggqGMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUURpOhnZVHLsoe0u9PsDQ
# rsuwYokwDQYJKoZIhvcNAQEBBQAEggEANg3UG4axNHedg6Qkd7NsyZZiKV5/ZRPd
# mgkDgFyJ2Hj8N/3+N2a9PSEEAPIBgyKfQePt9VQ95l1zOhixg9zP7Sx2EICDXrQd
# Cm1LqwQJ6Q1O+Z7M1gw8hCxFgpYL5XLhHYp5VxTk4PT0wgjO3r+PvtfIiZWhfxZk
# G04D0aNbeOyUKGXYYQCHL++P+N8sO3uaxABsHiDJ70NtEhUobC3qp/lZNo87mEA6
# kLE6sJcWu2udxvdeQeJsH8EFtCeCXru+RqkrBmV3nLIAP9c789RONDIfRcOyrH3Q
# 9CvD5fMEUaBS/wQoEb1iBhZJCeoyHKE9R6Jaqi/p2jqgTA/jHLdP+w==
# SIG # End signature block
