<#PSScriptInfo

.VERSION 1.5.2

.GUID 6bbfa956-167f-4729-9aae-259d50dd29ad

.AUTHOR Richard Hicks

.COMPANYNAME Richard M. Hicks Consulting, Inc.

.COPYRIGHT Copyright (C) 2024 Richard M. Hicks Consulting, Inc. All Rights Reserved.

.LICSENE Licensed under the MIT License. See LICENSE file in the project root for full license information.

.LICENSEURI https://github.com/richardhicks/aovpn/blob/master/LICENSE

.PROJECTURI https://github.com/richardhicks/aovpn/blob/master/Get-EapConfiguration.ps1

.TAGS EAP, NPS, Authentication, AOVPN

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
    Version:        1.5.2
    Creation Date:  May 27, 2019
    Last Updated:   December 3, 2024
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Website:        https://www.richardhicks.com/

#>

Function Get-EapConfiguration {

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

}

# SIG # Begin signature block
# MIInFQYJKoZIhvcNAQcCoIInBjCCJwICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXF0V3JXX4qkdQ9Mc4iVo4T0n
# kzaggiC9MIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0B
# AQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz
# 7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS
# 5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7
# bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfI
# SKhmV1efVFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jH
# trHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14
# Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2
# h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt
# 6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPR
# iQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ER
# ElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4K
# Jpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAd
# BgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SS
# y4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAC
# hjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRV
# HSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyh
# hyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO
# 0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo
# 8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++h
# UD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5x
# aiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGrjCCBJag
# AwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIw
# MzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQg
# UlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCw
# zIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34V6gCff1DtITaEfFz
# sbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ
# 7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7
# QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/teP
# c5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCY
# OjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9K
# oRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6
# dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM
# 1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbC
# dLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbEC
# AwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1N
# hS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9P
# MA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcB
# AQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggr
# BgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAI
# BgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7Zv
# mKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI
# 2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/ty
# dBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVP
# ulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQeJsG33irr9p6xeZmB
# o1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc
# 6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3c
# HXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0d
# KNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZP
# J/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLe
# Mt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDy
# Divl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBrAwggSYoAMCAQICEAitQLJg0pxM
# n17Nqb2TrtkwDQYJKoZIhvcNAQEMBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UE
# AxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIxMDQyOTAwMDAwMFoXDTM2
# MDQyODIzNTk1OVowaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2lnbmluZyBS
# U0E0MDk2IFNIQTM4NCAyMDIxIENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
# AgoCggIBANW0L0LQKK14t13VOVkbsYhC9TOM6z2Bl3DFu8SFJjCfpI5o2Fz16zQk
# B+FLT9N4Q/QX1x7a+dLVZxpSTw6hV/yImcGRzIEDPk1wJGSzjeIIfTR9TIBXEmtD
# mpnyxTsf8u/LR1oTpkyzASAl8xDTi7L7CPCK4J0JwGWn+piASTWHPVEZ6JAheEUu
# oZ8s4RjCGszF7pNJcEIyj/vG6hzzZWiRok1MghFIUmjeEL0UV13oGBNlxX+yT4Us
# SKRWhDXW+S6cqgAV0Tf+GgaUwnzI6hsy5srC9KejAw50pa85tqtgEuPo1rn3MeHc
# reQYoNjBI0dHs6EPbqOrbZgGgxu3amct0r1EGpIQgY+wOwnXx5syWsL/amBUi0nB
# k+3htFzgb+sm+YzVsvk4EObqzpH1vtP7b5NhNFy8k0UogzYqZihfsHPOiyYlBrKD
# 1Fz2FRlM7WLgXjPy6OjsCqewAyuRsjZ5vvetCB51pmXMu+NIUPN3kRr+21CiRshh
# WJj1fAIWPIMorTmG7NS3DVPQ+EfmdTCN7DCTdhSmW0tddGFNPxKRdt6/WMtyEClB
# 8NXFbSZ2aBFBE1ia3CYrAfSJTVnbeM+BSj5AR1/JgVBzhRAjIVlgimRUwcwhGug4
# GXxmHM14OEUwmU//Y09Mu6oNCFNBfFg9R7P6tuyMMgkCzGw8DFYRAgMBAAGjggFZ
# MIIBVTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBRoN+Drtjv4XxGG+/5h
# ewiIZfROQjAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8B
# Af8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYIKwYBBQUHAQEEazBpMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKG
# NWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290
# RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMBwGA1UdIAQVMBMwBwYFZ4EMAQMw
# CAYGZ4EMAQQBMA0GCSqGSIb3DQEBDAUAA4ICAQA6I0Q9jQh27o+8OpnTVuACGqX4
# SDTzLLbmdGb3lHKxAMqvbDAnExKekESfS/2eo3wm1Te8Ol1IbZXVP0n0J7sWgUVQ
# /Zy9toXgdn43ccsi91qqkM/1k2rj6yDR1VB5iJqKisG2vaFIGH7c2IAaERkYzWGZ
# gVb2yeN258TkG19D+D6U/3Y5PZ7Umc9K3SjrXyahlVhI1Rr+1yc//ZDRdobdHLBg
# XPMNqO7giaG9OeE4Ttpuuzad++UhU1rDyulq8aI+20O4M8hPOBSSmfXdzlRt2V0C
# FB9AM3wD4pWywiF1c1LLRtjENByipUuNzW92NyyFPxrOJukYvpAHsEN/lYgggnDw
# zMrv/Sk1XB+JOFX3N4qLCaHLC+kxGv8uGVw5ceG+nKcKBtYmZ7eS5k5f3nqsSc8u
# pHSSrds8pJyGH+PBVhsrI/+PteqIe3Br5qC6/To/RabE6BaRUotBwEiES5ZNq0RA
# 443wFSjO7fEYVgcqLxDEDAhkPDOPriiMPMuPiAsNvzv0zh57ju+168u38HcT5uco
# P6wSrqUvImxB+YJcFWbMbA7KxYbD9iYzDAdLoNMHAmpqQDBISzSoUSC7rRuFCOJZ
# DW3KBVAr6kocnqX9oKcfBnTn8tZSkP2vhUgh+Vc7tJwD7YZF9LRhbr9o4iZghurI
# r6n+lB3nYxs6hlZ4TjCCBrwwggSkoAMCAQICEAuuZrxaun+Vh8b56QTjMwQwDQYJ
# KoZIhvcNAQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2
# IFRpbWVTdGFtcGluZyBDQTAeFw0yNDA5MjYwMDAwMDBaFw0zNTExMjUyMzU5NTla
# MEIxCzAJBgNVBAYTAlVTMREwDwYDVQQKEwhEaWdpQ2VydDEgMB4GA1UEAxMXRGln
# aUNlcnQgVGltZXN0YW1wIDIwMjQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC+anOf9pUhq5Ywultt5lmjtej9kR8YxIg7apnjpcH9CjAgQxK+CMR0Rne/
# i+utMeV5bUlYYSuuM4vQngvQepVHVzNLO9RDnEXvPghCaft0djvKKO+hDu6ObS7r
# JcXa/UKvNminKQPTv/1+kBPgHGlP28mgmoCw/xi6FG9+Un1h4eN6zh926SxMe6We
# 2r1Z6VFZj75MU/HNmtsgtFjKfITLutLWUdAoWle+jYZ49+wxGE1/UXjWfISDmHuI
# 5e/6+NfQrxGFSKx+rDdNMsePW6FLrphfYtk/FLihp/feun0eV+pIF496OVh4R1Tv
# jQYpAztJpVIfdNsEvxHofBf1BWkadc+Up0Th8EifkEEWdX4rA/FE1Q0rqViTbLVZ
# Iqi6viEk3RIySho1XyHLIAOJfXG5PEppc3XYeBH7xa6VTZ3rOHNeiYnY+V4j1XbJ
# +Z9dI8ZhqcaDHOoj5KGg4YuiYx3eYm33aebsyF6eD9MF5IDbPgjvwmnAalNEeJPv
# IeoGJXaeBQjIK13SlnzODdLtuThALhGtyconcVuPI8AaiCaiJnfdzUcb3dWnqUnj
# XkRFwLtsVAxFvGqsxUA2Jq/WTjbnNjIUzIs3ITVC6VBKAOlb2u29Vwgfta8b2ypi
# 6n2PzP0nVepsFk8nlcuWfyZLzBaZ0MucEdeBiXL+nUOGhCjl+QIDAQABo4IBizCC
# AYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1Ud
# IwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSfVywDdw4oFZBm
# pWNe7k+SH3agWzBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5n
# Q0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1w
# aW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQA9rR4fdplb4ziEEkfZQ5H2Edub
# Tggd0ShPz9Pce4FLJl6reNKLkZd5Y/vEIqFWKt4oKcKz7wZmXa5VgW9B76k9NJxU
# l4JlKwyjUkKhk3aYx7D8vi2mpU1tKlY71AYXB8wTLrQeh83pXnWwwsxc1Mt+FWqz
# 57yFq6laICtKjPICYYf/qgxACHTvypGHrC8k1TqCeHk6u4I/VBQC9VK7iSpU5wlW
# jNlHlFFv/M93748YTeoXU/fFa9hWJQkuzG2+B7+bMDvmgF8VlJt1qQcl7YFUMYgZ
# U1WM6nyw23vT6QSgwX5Pq2m0xQ2V6FJHu8z4LXe/371k5QrN9FQBhLLISZi2yemW
# 0P8ZZfx4zvSWzVXpAb9k4Hpvpi6bUe8iK6WonUSV6yPlMwerwJZP/Gtbu3CKldMn
# n+LmmRTkTXpFIEB06nXZrDwhCGED+8RsWQSIXZpuG4WLFQOhtloDRWGoCwwc6ZpP
# ddOFkM2LlTbMcqFSzm4cd0boGhBq7vkqI1uHRz6Fq1IX7TaRQuR+0BGOzISkcqwX
# u7nMpFu3mgrlgbAW+BzikRVQ3K2YHcGkiKjA4gi4OA/kz1YCsdhIBHXqBzR0/Zd2
# QwQ/l4Gxftt/8wY3grcc/nS//TVkej9nmUYu83BDtccHHXKibMs/yXHhDXNkoPId
# ynhVAku7aRZOwqw6pDCCBwIwggTqoAMCAQICEAFmchIElUK4sup54tMHrEQwDQYJ
# KoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2lnbmluZyBS
# U0E0MDk2IFNIQTM4NCAyMDIxIENBMTAeFw0yMTEyMDIwMDAwMDBaFw0yNDEyMjAy
# MzU5NTlaMIGGMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQG
# A1UEBxMNTWlzc2lvbiBWaWVqbzEkMCIGA1UEChMbUmljaGFyZCBNLiBIaWNrcyBD
# b25zdWx0aW5nMSQwIgYDVQQDExtSaWNoYXJkIE0uIEhpY2tzIENvbnN1bHRpbmcw
# ggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDqy+tWoFEFtrMSSuaG3PuH
# TksQEgenx8aVXX2djaCkEueQNHwzP8T2LVy7Sx2OJ4LgPj9a0jj816JHmJ20GC11
# 6Tl6J5GM9yfyD1mmXz0oiXw03LVSU5Y1XvSPPOpnYJiI/8/lgZnA/LwvHmsgA5hM
# kzoQUMG9k22LtpGLMTuWpVcEM3PJ4eF9dg8HFpBXYi36xaorSxpOPSg0DYi72pJh
# oVAsUfjlWmV60qnt153YUUm/Y8qZivNi1rHjzHNRCratELkE3b+fvvvU0N8nS3y5
# 1GFQGpMQjlnWrMzPhFRV+CYY9P4JoTnk3IGfJjr8Db/spIiw5g5xODNCE7iMuaNM
# FnaRmosI5qo9tKar9K60wQYdjUxTvGtZQRCKdzONTOZsYbDtXztcj2yfwRxZfvU8
# S8jYa2vVMl+dP1t61cMme3bWa6SKguxRSl2VGYxufbeiv9UfMTo2/srPH60DWwF1
# Z0LcyTNrD8ybdfxZzvK2G1cYFwuYFqCkwYIJQ6To4lkCAwEAAaOCAgYwggICMB8G
# A1UdIwQYMBaAFGg34Ou2O/hfEYb7/mF7CIhl9E5CMB0GA1UdDgQWBBTEXt2j54gb
# 3CcRRWNyRn0yxtn7iTAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUH
# AwMwgbUGA1UdHwSBrTCBqjBToFGgT4ZNaHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNB
# MS5jcmwwU6BRoE+GTWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMD4GA1Ud
# IAQ3MDUwMwYGZ4EMAQQBMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNl
# cnQuY29tL0NQUzCBlAYIKwYBBQUHAQEEgYcwgYQwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBcBggrBgEFBQcwAoZQaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2
# U0hBMzg0MjAyMUNBMS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOC
# AgEAS8e384pqVHKwdB3HgJdI5yChrK4VdY3CL9UVwWvYQrfsarvUbgC11VxY0u77
# CGFjN8JUA0GdtNr2+yTnXmtMzTp7HPRC4zDKDT2aj5XFnyuo4EfPffFnIKhO3D/4
# P9JDGI7y5BHQ6Kx9vUxQc+oNDr0VM2ohAX9HMLbPNSflqAcVQuFvLzBuNB9S3YVc
# JGUVQs/O+nv/4lLhAAmcpermZgu+ilax2RsGfnYqr6WXx5+uPUriIxGGndrSfZ5E
# t62oomM6pPffkRqnJ0HgCemEfZYxAEceuiHmf9+/ft0IJphqqj0mUWdEisdTukcE
# ESlQZ/J5wWRwoXCw+IdcTUepAkI+Yxu891X1mC1aa5pEPQRBbXcnMPKhB0nFBlJc
# mEMMv5VIVLxJE0+1AU+KxlrYg7nx3UK9/kbyIrVEkc39DHjXeWPYlJLWjfCA0zdD
# l48VhdxDSI/GMViVFg8BoPHy3eiWD+1UryxKlioVgX30hGoE2LGGTLEDJUKTq4sE
# uDAT16AmDUAWgcR0B5psaBPYLSE7LPnk82gNm61kHrsb5Y3yQa0VhQsGWhEockmI
# WfjZu9d9rQmDWNnjUACwxzktQ2WouEiP9EUuKcMf2XhhvR10PjBBWwgUNWUmAM9c
# D0TVKfxUqtYTgjSxfjFdQWCN+5V91w2T1D7iwknVgdgabAsxggXCMIIFvgIBATB9
# MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UE
# AxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcgUlNBNDA5NiBTSEEz
# ODQgMjAyMSBDQTECEAFmchIElUK4sup54tMHrEQwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFA3z
# lG3zP7wCdEHjc4u2sl3EqUHIMA0GCSqGSIb3DQEBAQUABIIBgFhDGvtaKM+Ky6Ie
# qJd+XMiZsXTTiUsGHR1bOUnkmSj6kKgJge6YvyA8dQ01M3VZe0Y4mDb3TMLyj0Q4
# eNn74Snv4F8nfwzQV/kwma6MDocuT6tUsshy4aw3pVJlP6svnVzkiN7m09AmO350
# tGQQum+nUdHofcfp3mhO3J5Jz2vvxVQejjsJ7251hA3iMfEE8ML1HDFyiIu0/CDq
# u0tK/RbYcx5PahNW+PIOiWBEyr8+q8ki98ooH7GHWdat1hZiWlK4cC1baVz3thZh
# VH22WO86UWBH+7RmE1MBdj/YaaO6VmOpq3qYkE6JSuR6Z/alrgbIc8Ne9hySMO0m
# x9+albCf9UP8g61rY604q7KI39nI5VNvU9f9q+lF3hikF+slHOM9diTqNzsKoFWD
# jECzvqammh7qok3YIFFEABpgyq6vCY8QfBrilhSiDAugz5uMOIj6b+omJKu8SdYM
# 6iDiYwMfzNFzAn6WG2f7W1YF0phID+0YZelejT58i5BfYvPbQKGCAyAwggMcBgkq
# hkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5E
# aWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0
# MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAuuZrxaun+Vh8b56QTjMwQwDQYJ
# YIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3
# DQEJBTEPFw0yNDEyMDMyMDE4NTNaMC8GCSqGSIb3DQEJBDEiBCBkOAoKTTopZTlX
# ait6/FU3BfPWYogWIKX5JhL3A255ZDANBgkqhkiG9w0BAQEFAASCAgB0FwU2omMl
# 6cXE0sO4NhovWBHLufv//Ta2FFr7tRCZ/eT6w+XIOF/2X46OHSKsbVeLumdc/Aer
# UWuWVviAgyr7Em2FifzsdwPNKJQQtNK9BinUrMMkkxqMUQKHRLj/3+ECK7BAjfv9
# BbTJpRYmGVaBrNw3m1AZ2G2rFuEsVfxjiOB/Tv8rxj1xuf5YxHnZl3dX0wSdRGLX
# bTwjnp4qvfIROYhygz3z3FSHHEGuu61awrHNKKVehSxPHIwS9CuDfk1m28c+MVSL
# U39kll/+ESc5mXCo7bbSyou5T3vbnn3ff4cgwTqxJFSUMU82ILSCvNf5wE9CI6Dy
# B71Vuc0LIPAXXZCB1FN7UQoCJRqWcqes18cGWnLTA5YiH3ccFTs4qfHNkm6zIbxu
# Exb93EyLyVaUA2KG346RJYiFFTlsNAPXRC/nRkAgFl4C5F+wiFPXOk+DRoNuA9bS
# yk44srqWPtxtfbzzR21RbYM5vlKxYp9QSl8GOvcOt9Doo8txLc3uJnmQtFDECCnE
# ylSOpWy37SJatN8oDUeBxqrQ5Ox9m4nX3IHQzHzjJtZVl9OgEWINAlH0fOpN6Bja
# fLnYpivXvjo0gtGNxFJhU7/C6+1m0RQ1MCF2AXX0BFblmPvFQ9uk727cveZbrfDb
# 95B6lhA+Sj1Rwqy4CobYa13TzAn5iVjRJQ==
# SIG # End signature block
