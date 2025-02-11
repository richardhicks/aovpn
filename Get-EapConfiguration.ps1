<#PSScriptInfo

.VERSION 1.5.3

.GUID 82e0c1b0-dfa0-4d00-ad4c-d9e239c249cd

.AUTHOR Richard Hicks

.COMPANYNAME Richard M. Hicks Consulting, Inc.

.COPYRIGHT Copyright (C) 2025 Richard M. Hicks Consulting, Inc. All Rights Reserved.

.LICENSE Licensed under the MIT License. See LICENSE file in the project root for full license information.

.LICENSEURI https://github.com/richardhicks/aovpn/blob/master/LICENSE

.PROJECTURI https://github.com/richardhicks/aovpn/blob/master/Get-EapConfiguration.ps1

.TAGS EAP, Authentication, VPN, NPS, NPAS, RADIUS, Microsoft, Windows, AOVPN

#>

<#

.SYNOPSIS
    Extract EAP configuration from existing Windows VPN connection.

.PARAMETER ConnectionName
    The name of the VPN connection to extract the EAP configuration from.

.PARAMETER xmlFilePath
    The full path and name of the file to export EAP configuration to.

.EXAMPLE
    Get-EapConfiguration -ConnectionName 'Test VPN Connection'

    Extracts the EAP configuration from a VPN connection named "Test VPN Connection". The file will be automatically saved as eapconfig.xml in the location where the script was executed from.

.EXAMPLE
    Get-EapConfiguration -ConnectionName 'Test VPN Connection' -AllUserConnection

    Extracts the EAP configuration from a VPN connection named "Test VPN Connection" that is configured in the "all users" context. The file will be automatically saved as eapconfig.xml in the location where the script was executed from.

.EXAMPLE
    Get-EapConfiguration -ConnectionName 'Test VPN Connection' -xmlFilePath 'C:\temp\eapconfig.xml'

    Extracts the EAP configuration from a VPN connection named "Test VPN Connection" and the file is saved to a custom location.

.DESCRIPTION
    Use this command to extract the EAP configuration from an existing VPN connection. The output XML can be copied and pasted in to ProfileXML for configuring Windows Always On VPN connections.

.LINK
    https://github.com/richardhicks/aovpn/blob/master/Get-EapConfiguration.ps1

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.5.3
    Creation Date:  May 27, 2019
    Last Updated:   February 11, 2025
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Website:        https://www.richardhicks.com/

#>

[CmdletBinding()]

Param (

    [Parameter(Mandatory, ValueFromPipelineByPropertyName, HelpMessage = 'Enter the name of the VPN template connection')]
    [Alias('Name')]
    [string]$ConnectionName,
    [string]$xmlFilePath = '.\eapconfig.xml',
    [switch]$AllUserConnection

)

Process {

    # Validate VPN connection
    If ($AllUserConnection) {

        $Vpn = Get-VpnConnection -Name $ConnectionName -AllUserConnection -ErrorAction SilentlyContinue

    }

    Else {

        $Vpn = Get-VpnConnection -Name $ConnectionName -ErrorAction SilentlyContinue

    }

    If ($Null -eq $Vpn) {

        Write-Warning "The VPN connection `"$ConnectionName`" does not exist."
        Return

    }

    # Create EAP configuration object
    Write-Verbose "Extracting EAP configuration from template connection $ConnectionName..."
    $EapConfig = $Vpn.EapConfigXmlStream.InnerXml

    # Validate EAP authentication is configured
    If ($Null -eq $EapConfig) {

        Write-Warning "The VPN connection `"$ConnectionName`" is not configured to use EAP authentication."
        Return

    }

    # Format XML
    Function Format-XML ([xml]$Xml, $Indent = 3) {

        $StringWriter = New-Object System.IO.StringWriter
        $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
        $XmlWriter.Formatting = "Indented"
        $XmlWriter.Indentation = $Indent
        $Xml.WriteContentTo($XmlWriter)
        $XmlWriter.Flush()
        $StringWriter.Flush()
        Write-Output $StringWriter.ToString()

    } # Format-XML

    # Convert text stream to XML format
    Write-Output "EAP configuration saved to $xmlFilePath."
    Format-XML $EapConfig | Out-File $xmlFilePath

}

# SIG # Begin signature block
# MIIfeAYJKoZIhvcNAQcCoIIfaTCCH2UCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEUcMneX1dQJ1T2iB2Fvby73+
# rQagghpiMIIDWTCCAt+gAwIBAgIQD7inQLkVjQNRQ7xZ2fBAKTAKBggqhkjOPQQD
# AzBhMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9v
# dCBHMzAeFw0yMTA0MjkwMDAwMDBaFw0zNjA0MjgyMzU5NTlaMGQxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE8MDoGA1UEAxMzRGlnaUNlcnQg
# R2xvYmFsIEczIENvZGUgU2lnbmluZyBFQ0MgU0hBMzg0IDIwMjEgQ0ExMHYwEAYH
# KoZIzj0CAQYFK4EEACIDYgAEu7SsJ6VIDaJTX48ugT4vU3a4CJSimqqKi5i1sfD8
# KhW7ubOlIi/9asC94lVoYGuXNMFmU3Ej/BrVyiAPAkCio0paRqORUyuV8gPpq6bT
# h3Yv52SfnjVR/MNjNXh25Ph3o4IBVzCCAVMwEgYDVR0TAQH/BAgwBgEB/wIBADAd
# BgNVHQ4EFgQUm1+wNrqdBq4ZJ73AoCLAi4s4d+0wHwYDVR0jBBgwFoAUs9tIpPmh
# xdiuNkHMEWNpYim8S8YwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMHYGCCsGAQUFBwEBBGowaDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEAGCCsGAQUFBzAChjRodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRHbG9iYWxSb290RzMuY3J0MEIGA1UdHwQ7MDkwN6A1oDOGMWh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RHMy5jcmww
# HAYDVR0gBBUwEzAHBgVngQwBAzAIBgZngQwBBAEwCgYIKoZIzj0EAwMDaAAwZQIw
# eL1JlWVxAdBGV2hlDmip3DYIwe791I7bQGU/Df+Tr8KuY4ajfsu0kVp47AcDZwd8
# AjEA558f8QdbrDTGOLy1pVDO5uo4fj55kOSkW6sCDegH/FamWords1Cy3fL6ZnSe
# 0BZjMIID/jCCA4SgAwIBAgIQDUo02oaQj8ATLLyBN5OvJDAKBggqhkjOPQQDAzBk
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xPDA6BgNVBAMT
# M0RpZ2lDZXJ0IEdsb2JhbCBHMyBDb2RlIFNpZ25pbmcgRUNDIFNIQTM4NCAyMDIx
# IENBMTAeFw0yNDEyMDYwMDAwMDBaFw0yNzEyMjQyMzU5NTlaMIGGMQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQGA1UEBxMNTWlzc2lvbiBWaWVq
# bzEkMCIGA1UEChMbUmljaGFyZCBNLiBIaWNrcyBDb25zdWx0aW5nMSQwIgYDVQQD
# ExtSaWNoYXJkIE0uIEhpY2tzIENvbnN1bHRpbmcwWTATBgcqhkjOPQIBBggqhkjO
# PQMBBwNCAARQm7XKqXO7xhjOIVTO/VPu39LSs6PAQBjCf9BOyVMCiX8jCY/Y7Aja
# aetfpgTXU8IqxJvytFc9Nr2pNBbXG/98o4IB8zCCAe8wHwYDVR0jBBgwFoAUm1+w
# NrqdBq4ZJ73AoCLAi4s4d+0wHQYDVR0OBBYEFCiDJFZHyEjVMkCe28Ly5vbAiJMY
# MD4GA1UdIAQ3MDUwMwYGZ4EMAQQBMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cu
# ZGlnaWNlcnQuY29tL0NQUzAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwgasGA1UdHwSBozCBoDBOoEygSoZIaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0R2xvYmFsRzNDb2RlU2lnbmluZ0VDQ1NIQTM4NDIwMjFDQTEu
# Y3JsME6gTKBKhkhodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRHbG9i
# YWxHM0NvZGVTaWduaW5nRUNDU0hBMzg0MjAyMUNBMS5jcmwwgY4GCCsGAQUFBwEB
# BIGBMH8wJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBXBggr
# BgEFBQcwAoZLaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xv
# YmFsRzNDb2RlU2lnbmluZ0VDQ1NIQTM4NDIwMjFDQTEuY3J0MAkGA1UdEwQCMAAw
# CgYIKoZIzj0EAwMDaAAwZQIwTDrAW/NKsehOktpZ5x2n7smNqWqA7T43H3XSmgdR
# ypwMu1i2hFXO/MQAvOIlt5ehAjEA4Tjw+SR7cGMRB+g8VQ5XuaSyn7skB4mNYtCP
# T60p9aZT1HmQ052CpprNT+upwbwpMIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21Di
# CEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtE
# aWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzEx
# MTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBU
# cnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/
# 5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QNxDAf8xuk
# OBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpz
# MpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7Fsa
# vOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463JT17lNecxy9qT
# XtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRz
# Km6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRc
# Ro9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADk
# RSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMY
# RJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4m
# rLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C
# 1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYD
# VR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYD
# VR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkG
# CCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmww
# EQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+g
# o3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0
# /4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnL
# nU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU9
# 6LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ
# 9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9X
# ql4o4rmUMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0B
# AQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVk
# IFJvb3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lD
# ZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKR
# N6mXUaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZz
# lm34V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1Oco
# LevTsbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH
# 92GDGd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRA
# p8ByxbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+g
# GkcgQ+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU
# 8lKVEStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/
# FDTP0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwj
# jVj33GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQ
# EgN9XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUae
# tdN2udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAw
# HQYDVR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LS
# cV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEF
# BQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYy
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5j
# cmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEB
# CwUAA4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftw
# ig2qKWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalW
# zxVzjQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQm
# h2ySvZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScb
# qyQeJsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLaf
# zYeHJLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbD
# Qc1PtkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0K
# XzM5h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm
# 8heZWcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9
# gdkT/r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8a
# pIUP/JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBrwwggSk
# oAMCAQICEAuuZrxaun+Vh8b56QTjMwQwDQYJKoZIhvcNAQELBQAwYzELMAkGA1UE
# BhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2Vy
# dCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTAeFw0y
# NDA5MjYwMDAwMDBaFw0zNTExMjUyMzU5NTlaMEIxCzAJBgNVBAYTAlVTMREwDwYD
# VQQKEwhEaWdpQ2VydDEgMB4GA1UEAxMXRGlnaUNlcnQgVGltZXN0YW1wIDIwMjQw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC+anOf9pUhq5Ywultt5lmj
# tej9kR8YxIg7apnjpcH9CjAgQxK+CMR0Rne/i+utMeV5bUlYYSuuM4vQngvQepVH
# VzNLO9RDnEXvPghCaft0djvKKO+hDu6ObS7rJcXa/UKvNminKQPTv/1+kBPgHGlP
# 28mgmoCw/xi6FG9+Un1h4eN6zh926SxMe6We2r1Z6VFZj75MU/HNmtsgtFjKfITL
# utLWUdAoWle+jYZ49+wxGE1/UXjWfISDmHuI5e/6+NfQrxGFSKx+rDdNMsePW6FL
# rphfYtk/FLihp/feun0eV+pIF496OVh4R1TvjQYpAztJpVIfdNsEvxHofBf1BWka
# dc+Up0Th8EifkEEWdX4rA/FE1Q0rqViTbLVZIqi6viEk3RIySho1XyHLIAOJfXG5
# PEppc3XYeBH7xa6VTZ3rOHNeiYnY+V4j1XbJ+Z9dI8ZhqcaDHOoj5KGg4YuiYx3e
# Ym33aebsyF6eD9MF5IDbPgjvwmnAalNEeJPvIeoGJXaeBQjIK13SlnzODdLtuThA
# LhGtyconcVuPI8AaiCaiJnfdzUcb3dWnqUnjXkRFwLtsVAxFvGqsxUA2Jq/WTjbn
# NjIUzIs3ITVC6VBKAOlb2u29Vwgfta8b2ypi6n2PzP0nVepsFk8nlcuWfyZLzBaZ
# 0MucEdeBiXL+nUOGhCjl+QIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAI
# BgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WM
# aiCPnshvMB0GA1UdDgQWBBSfVywDdw4oFZBmpWNe7k+SH3agWzBaBgNVHR8EUzBR
# ME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# RzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSB
# gzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsG
# AQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVz
# dGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEB
# CwUAA4ICAQA9rR4fdplb4ziEEkfZQ5H2EdubTggd0ShPz9Pce4FLJl6reNKLkZd5
# Y/vEIqFWKt4oKcKz7wZmXa5VgW9B76k9NJxUl4JlKwyjUkKhk3aYx7D8vi2mpU1t
# KlY71AYXB8wTLrQeh83pXnWwwsxc1Mt+FWqz57yFq6laICtKjPICYYf/qgxACHTv
# ypGHrC8k1TqCeHk6u4I/VBQC9VK7iSpU5wlWjNlHlFFv/M93748YTeoXU/fFa9hW
# JQkuzG2+B7+bMDvmgF8VlJt1qQcl7YFUMYgZU1WM6nyw23vT6QSgwX5Pq2m0xQ2V
# 6FJHu8z4LXe/371k5QrN9FQBhLLISZi2yemW0P8ZZfx4zvSWzVXpAb9k4Hpvpi6b
# Ue8iK6WonUSV6yPlMwerwJZP/Gtbu3CKldMnn+LmmRTkTXpFIEB06nXZrDwhCGED
# +8RsWQSIXZpuG4WLFQOhtloDRWGoCwwc6ZpPddOFkM2LlTbMcqFSzm4cd0boGhBq
# 7vkqI1uHRz6Fq1IX7TaRQuR+0BGOzISkcqwXu7nMpFu3mgrlgbAW+BzikRVQ3K2Y
# HcGkiKjA4gi4OA/kz1YCsdhIBHXqBzR0/Zd2QwQ/l4Gxftt/8wY3grcc/nS//TVk
# ej9nmUYu83BDtccHHXKibMs/yXHhDXNkoPIdynhVAku7aRZOwqw6pDGCBIAwggR8
# AgEBMHgwZDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTww
# OgYDVQQDEzNEaWdpQ2VydCBHbG9iYWwgRzMgQ29kZSBTaWduaW5nIEVDQyBTSEEz
# ODQgMjAyMSBDQTECEA1KNNqGkI/AEyy8gTeTryQwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFByv
# Na9Nq0msS8XQ/7iXL573p8sxMAsGByqGSM49AgEFAARHMEUCIQCm4EAneLaxDaIi
# K5/WKl26a58TjCQYjFgGncENQf0a+gIgI+M2awqCqTEAsqGTJbDZj4pK2nk+qbvD
# WtG1eNz0X4ehggMgMIIDHAYJKoZIhvcNAQkGMYIDDTCCAwkCAQEwdzBjMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lD
# ZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAL
# rma8Wrp/lYfG+ekE4zMEMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsG
# CSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjUwMjExMTUyMjUzWjAvBgkqhkiG
# 9w0BCQQxIgQgxnlqHA1vUv5B2a1oMzkVCNgxY5+7TZ4K+V7AhuEeHOYwDQYJKoZI
# hvcNAQEBBQAEggIAhg5ZXYXV22DdVIGUNjz+EXF6KcEGOUYdrqnLZsi0lkcuBCva
# lbzAq1LRLfACMRRct1qZVJHnFH5Mndf8jAUWknydETtAe0HPNg0ywWjMgkUBtAoS
# f1hBhFBODFlVXAvj8EKowub21HAAJ81b8B3/V+3dUIiMZrSRDceCAgjWbc21K742
# OOsqN1ZPqrSV3x/WIMwPVRxLdsygGLOs0Fz9UIGiTedS134+mQ4HyxP4QK9jJ6vi
# 5TzVVChY/SHnt+TJJkmg60NFmImeWNdQR6uYfECh6VHkBitfFZkfzZifkljdtFrk
# JjzqwcwH+WUil+bi3lIQYUrzyd+mjlRsNsz7k2mfricRqW44PVOs5CadPEgQk3EY
# 5muf65AYd4xb6PIow5OQJ849QzG0ABMx8JxRNg0KeYfqaN4KvlKHxpJPxh2s+85u
# yEZqQ0y4AVH2IOyTcPVuxohTfKk6vbJZNocI/o7Cf3oTvxFYUOFE4ufEP3YdGPkq
# b1ByPxGIH3zvof8igXxUkE8QbAwyH9gwaJFlp/3VfhOOqOsrrh5PyR93+Sb8OCVM
# glqMQoewZnF7V6pMPBGHChJ2z96OatMvhAzI18rCDq/AP2tOG0eAJQ3QygYjPMDr
# 1HuQi8VzxMC1wug2qqMe174plPQlwSMPLibk3LlSce6m0o+hWxry2q1Lk44=
# SIG # End signature block
