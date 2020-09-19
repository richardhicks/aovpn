<#

.SYNOPSIS
    Optimizes the DirectAccess/Routing and Remote Access Service (RRAS) inbox accounting database.

.EXAMPLE
    .\Optimize-InboxAccountingDatabase.ps1

.DESCRIPTION
    The RemoteAccess inbox accounting database is missing a crucial index on one of the tables in the database. This can cause high CPU utilization for very busy DirectAccess/RRAS VPN servers. Running this script will add the missing index and improve performance.

.LINK
    https://technet.microsoft.com/en-us/library/mt693376(v=ws.11).aspx

.NOTES
    Version:         1.2
    Creation Date:   December 15, 2019
    Last Updated:    September 19, 2020
    Special Note:    This script adapted from published guidance provided by Microsoft.
    Original Author: Microsoft Corporation
    Original Script: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/mt693376(v=ws.11)
    Author:          Richard Hicks
    Organization:    Richard M. Hicks Consulting, Inc.
    Contact:         rich@richardhicks.com
    Web Site:        https://directaccess.richardhicks.com/

#>

[CmdletBinding()]

Param (

)

# // Validate DirectAccess or VPN role is installed - exit script if neither is present
If ((Get-RemoteAccess | Select-Object -ExpandProperty DAStatus) -eq 'Uninstalled' -and (Get-RemoteAccess | Select-Object -ExpandProperty VpnStatus) -eq 'Uninstalled') {

    Write-Warning 'The DirectAccess or VPN role is not installed on this server. Exiting script.'
    Exit    

}

# // Validate inbox accounting enabled - exit script if not configured

If ((Get-RemoteAccessAccounting).InboxAccountingStatus -eq 'Disabled') {

    Write-Warning 'Inbox accounting is not configured. Exiting script.'
    Exit

}

# // Verify missing table index
$Connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$Connection.ConnectionString = 'Server=np:\\.\pipe\Microsoft##WID\tsql\query;Database=RaAcctDb;Trusted_Connection=True;'
$Command = $Connection.CreateCommand()
$Command.CommandText = "SELECT name from sys.indexes where name like 'IdxSessionTblState'"
$Adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $Command
$Dataset = New-Object -TypeName System.Data.DataSet
$Adapter.Fill($DataSet) | Out-Null
$Connection.Close()

If ($DataSet.Tables[0].Name -eq 'IdxSessionTblState') {

    Write-Warning 'Remote Access inbox accounting database already optimized. Exiting script.'
    Exit 

}
 
# // Optimize inbox accounting database
Write-Verbose 'Optimizing inbox accounting database...'
$Connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$Connection.ConnectionString = 'Server=np:\\.\pipe\Microsoft##WID\tsql\query;Database=RaAcctDb;Trusted_Connection=True;'
$Command = $Connection.CreateCommand()
$Command.CommandText = "CREATE INDEX IdxSessionTblState ON [RaAcctDb].[dbo].[SessionTable] ([SessionState]) INCLUDE ([ConnectionId])"
$Connection.Open()
$Command.ExecuteNonQuery() | Out-Null
$Connection.Close()

Write-Verbose 'Inbox accounting database optimization complete.'

# SIG # Begin signature block
# MIINbAYJKoZIhvcNAQcCoIINXTCCDVkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnM+TVYHP2s0mDG3s4caUxkQm
# EV6gggquMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFIbxUe20fo8APp2MtERgCu1uSbBbMA0G
# CSqGSIb3DQEBAQUABIIBAAbE19RppEPdQ9RlKR7M8bLrMPUYsAnDvewxROttsalU
# zIIZErirDYKk5SUigT/AF2NTMZ5Bxbzb0x1Yscg93j7NuFfWQ80zZ9Yj+7mxhxnU
# trGBlS/t2dEcUA8WxRnjsbVk5O8TSRlFoT5UehDkxa2CtlT1etzc/EFba8pl1oBv
# MdsVQZZqkmxyqtDgsqWlff4So9xD6cjOhWcpY0pGwFk+9i5049fiseWYxt+XFCfM
# diOHYzJz1BvfXC3eHepFSK8HXB2FpsfCCyPXP8e75JiNwCVVnfDWE8xn5BF0hlzR
# XEOD92C06Hv/vzvVsqb4bpPZ8sYg+QqYZ/e06oTnpj8=
# SIG # End signature block
