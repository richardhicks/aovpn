<#

.SYNOPSIS
    Performs a disk backup of the DirectAccess/Routing and Remote Access Service (RRAS) inbox accounting database.

.PARAMETER SourcePath
    The location of the inbox accounting database file RaAcctDb.mdf. The default location is C:\Windows\DirectAccess\db\.

.PARAMETER BackupPath
    The location to store the inbox accounting database backup. The default location is C:\Windows\DirectAccess\db\.

.PARAMETER Overwrite
    Overwrites an existing backup file if it exists.

.EXAMPLE
    .\Backup-InboxAccountingDatabase.ps1

    Run this command to back up the inbox accounting database in the default location of C:\Windows\DirectAccess\db\.

.EXAMPLE
    .\Backup-InboxAccountingDatabase.ps1 -Overwrite

    Run this command to back up the inbox accounting database and overwrite an existing backup file.

.EXAMPLE
    .\Backup-InboxAccountingDatabase.ps1 -BackupPath 'C:\Backups\'

    Run this command to back up the inbox accounting database to the C:\Backups\ folder.

.EXAMPLE
    .\Backup-InboxAccountingDatabase.ps1 -SourcePath 'D:\DirectAccess\db\' -BackupPath 'D:\Backups\'

    Run this command to backup the inbox accounting database from the non-default location D:\DirectAccess\ddb\RaAcctDb.mdf to D:\Backups\.

.DESCRIPTION
    PowerShell script to perform a disk backup of the Remote Access inbox accounting database.

.LINK
    https://technet.microsoft.com/en-us/library/mt693376(v=ws.11).aspx

.NOTES
    Version:         1.0
    Creation Date:   September 19, 2020
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

    [string]$SourcePath = 'C:\Windows\DirectAccess\db\',
    [string]$BackupPath = 'C:\Windows\DirectAccess\db\',
    [switch]$Overwrite

)

$Database = Join-Path $SourcePath -ChildPath 'RaAcctDb.mdf'
$BackupFile = Join-Path $BackupPath -ChildPath 'RaAcctDb.bak'

# // Validate inbox accounting database location. Exit if it doesn't exist
If (!(Test-Path $Database)) {

    Write-Warning "Inbox accounting database does not exist in $SourcePath. Existing script."
    Exit

}

# // Check for existing backup file. Overwrite or exit as needed
If (Test-Path $BackupFile) {

    If ($Overwrite) {

        Write-Warning "$BackupFile already exists. File will be overwritten."
        Remove-Item $BackupFile

    }
    
    Else {

        Write-Warning "Backup file already exists. Existing script."
        Exit
    
    }
    
}

# // Create backup folder if it does not exist
If (!(Test-Path $BackupPath)) {

    Write-Verbose "Backup folder $BackupPath does not exist. Creating it..."
    New-Item -ItemType Directory -Path $BackupPath | Out-Null

}

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

# // Backup inbox accounting database
Write-Verbose 'Backing up inbox accounting database...'

$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$connection.ConnectionString = 'Server=np:\\.\pipe\Microsoft##WID\tsql\query;Database=RaAcctDb;Trusted_Connection=True;'
$command = $connection.CreateCommand()
$command.CommandText = "BACKUP database RaAcctDb TO DISK='$BackupFile' WITH DESCRIPTION = 'Full backup before removing inbox accounting database.'"
$connection.Open()
$command.ExecuteNonQuery() | Out-Null
$connection.close()

Write-Output "Inbox accounting database backed up to $BackupFile."

# SIG # Begin signature block
# MIINbAYJKoZIhvcNAQcCoIINXTCCDVkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzJGB1TbTkrv5pASjkkpNKXSw
# qv+gggquMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNNEcKjJdgqdnz766BsYx8TJ7D9SMA0G
# CSqGSIb3DQEBAQUABIIBAHJ5CCTZbvIYHvyIXsW3s8kw8I25IoU/UjRjWVD0pG/t
# 4Q+MwltDVff1WTldDkQW+HSriHLYFDY+5t7swdztTYTP/q1+hu3ZF/cgE2wVYQn/
# B9DJpjVX+UEWaWCC7A/jN8zh8fwrXK7PxuQNHoIktvKYXMRJrw9xX9iBIsynnKoh
# incqxHNugNcFRvQJU2/rU0q4bNW2ZX53QVT37mTs6Snw0aCIhkszbmaaOTLczkuH
# gSs0+Y7JlknSCyMwOsCUJpcUh9P1V/BgkF98+k7qFT2Y3W86saLtIqicp53eZYmY
# +jc75ExcCiS5S5SX9pJFgGaYy/gvdwQVhq2IDYXbCGo=
# SIG # End signature block
