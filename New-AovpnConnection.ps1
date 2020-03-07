<#
.SYNOPSIS
    Creates an Always On VPN user tunnel connection.

.PARAMETER xmlFilePath
    Path to the ProfileXML configuration file.

.PARAMETER ProfileName
    Name of the VPN profile to be created.

.EXAMPLE
    .\New-AovpnConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML_User.xml' -ProfileName 'Always On VPN'

.DESCRIPTION
    This script will create an Always On VPN user tunnel on supported Windows 10 devices. 

.LINK
    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections#bkmk_fullscript

.NOTES
    Version:            1.1
    Creation Date:      May 28, 2019
    Last Updated:       March 6, 2020
    Special Note:       This script adapted from guidance originally published by Microsoft.
    Original Author:    Microsoft Corporation
    Original Script:    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections#bkmk_fullscript
    Author:             Richard Hicks
    Organization:       Richard M. Hicks Consulting, Inc.
    Contact:            rich@richardhicks.com
    Web Site:           https://directaccess.richardhicks.com/

#>

[CmdletBinding()]

Param(

    [Parameter(Mandatory = $True, HelpMessage = 'Enter the path to the ProfileXML file.')]    
    [string]$xmlFilePath,
    [Parameter(Mandatory = $False, HelpMessage = 'Enter a name for the VPN profile.')]        
    [string]$ProfileName = 'Always On VPN'

)

# Check for existing connection. Exit if exists.
If (Get-VpnConnection -Name $ProfileName -ErrorAction SilentlyContinue) {

    Write-Warning "The VPN profile ""$ProfileName"" already exists."
    Write-Warning "Remove the VPN connection using the following PowerShell command:"
    Write-Warning "Get-VpnConnection -Name `'$ProfileName' | Remove-VpnConnection -Force"
    Exit

}

# Import ProfileXML
$ProfileXML = Get-Content $xmlFilePath

# Escape spaces in profile name
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

# OMA URI information
$NodeCSPURI = './Vendor/MSFT/VPNv2'
$NamespaceName = 'root\cimv2\mdm\dmmap'
$ClassName = 'MDM_VPNv2_01'

try {

    $Username = Get-WmiObject -Class Win32_ComputerSystem | Select-Object username
    $User = New-Object System.Security.Principal.NTAccount($Username.Username)
    $Sid = $User.Translate([System.Security.Principal.SecurityIdentifier])
    $SidValue = $Sid.Value
    Write-Verbose "User SID is $SidValue."

}

catch [Exception] {

    Write-Output "Unable to get user SID. User may be logged on over Remote Desktop: $_"
    Exit

}

$Session = New-CimSession
$Options = New-Object Microsoft.Management.Infrastructure.Options.CimOperationOptions
$Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Type', 'PolicyPlatform_UserContext', $false)
$Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Id', "$SidValue", $false)

try {

    $NewInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $ClassName, $NamespaceName
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ParentID', "$nodeCSPURI", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('InstanceID', "$ProfileNameEscaped", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ProfileXML', "$ProfileXML", 'String', 'Property')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Session.CreateInstance($NamespaceName, $NewInstance, $Options)
    Write-Output "Always On VPN user tunnel profile ""$ProfileName"" created successfully."

}

catch [Exception] {

    Write-Output "Unable to create ""$ProfileName"" profile: $_"
    Exit

}

# SIG # Begin signature block
# MIINbAYJKoZIhvcNAQcCoIINXTCCDVkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbEE5T/H8TzfTCFF5IaL1YxEB
# pEygggquMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDql+ruiKztiUR5STVtUhW5QOVMkMA0G
# CSqGSIb3DQEBAQUABIIBAEdubnVmgfGApYjXb3xgPuEQPqEn5P55UOAbWz8NIhM5
# A1+m3rzuBToOvYRq82PZyzYUhZTT/rVnVcnrwBezB3DnDTCJ9PpSJSReVe0oTNML
# R5WciPNjIF/1skZ9sO1Db98t+qLquHZNC687s9+QzNT5sz5GXJIlSjk4cXPpoHs9
# T0lYRcv9W+wzVMEG884nprME+HLmcm6uJ9Z/Vtvpt7yhh8hJD501iZcoEbMr6M0+
# mkAsqrzSZuK0qJSQgYzYHUYyC+7bsdmWUoBLaD7g+UsQcGmOVK6OCC2tDoqYP528
# X4KeAfzl8eTtW1GeV55HCNIUzHSpCeEPHn1/GyGzC7I=
# SIG # End signature block
