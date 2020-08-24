<#

.SYNOPSIS
    Creates an Always On VPN user or device tunnel connection.

.PARAMETER xmlFilePath
    Path to the ProfileXML configuration file.

.PARAMETER ProfileName
    Name of the VPN profile to be created.

.PARAMETER DeviceTunnel
    Option to create an Always On VPN device tunnel profile.

.PARAMETER AllUserConnection
    Option to create the Always On VPN user tunnel profile in the all users profile.

.EXAMPLE
    .\New-AovpnConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML_User.xml' -ProfileName 'Always On VPN'

    Creates an Always On VPN user tunnel profile named "Always On VPN" for the user Rick Deckard.

.EXAMPLE
    .\New-AovpnConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML_User.xml -ProfileName 'Always On VPN' -AllUserConnection

    Creates an Always On VPN user tunnel profile named "Always On VPN" for all users.

.EXAMPLE
    .\New-AovpnConnection.ps1 -xmlFilePath 'C:\Users\rdeckard\desktop\ProfileXML_Device.xml -DeviceTunnel

    Creates an Always On VPN device tunnel profile named "Always On VPN Device Tunnel".

.DESCRIPTION
    This script will create an Always On VPN user or device tunnel on supported Windows 10 devices. 

.LINK
    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections#bkmk_fullscript

.NOTES
    Version:            4.0
    Creation Date:      May 28, 2019
    Last Updated:       August 23, 2020
    Special Note:       This script adapted from guidance originally published by Microsoft.
    Original Author:    Microsoft Corporation
    Original Script:    https://docs.microsoft.com/en-us/windows-server/remote/remote-access/vpn/always-on-vpn/deploy/vpn-deploy-client-vpn-connections#bkmk_fullscript
    Author:             Richard Hicks
    Organization:       Richard M. Hicks Consulting, Inc.
    Contact:            rich@richardhicks.com
    Web Site:           https://directaccess.richardhicks.com/

#>

[CmdletBinding(SupportsShouldProcess)]

Param (

    [Parameter(Mandatory, HelpMessage = 'Enter the path to the ProfileXML file.')]
    [ValidateNotNullOrEmpty()]
    [string]$xmlFilePath,
    [Parameter(HelpMessage = 'Enter a name for the VPN profile.')]        
    [Alias("Name", "ConnectionName")]
    [string]$ProfileName,
    [switch]$DeviceTunnel,
    [switch]$AllUserConnection

)

# // Set default profile name
If ($ProfileName -eq '') {

    If ($DeviceTunnel) {

        $ProfileName = 'Always On VPN Device Tunnel'
    
    }

    Else {
        
        $ProfileName = 'Always On VPN'
        
    }

}

# // Check for existing connection. Exit if exists.
If ($AllUserConnection -or $DeviceTunnel) {

    # // Script must be running in the context of the SYSTEM account to extract ProfileXML from a device tunnel connection. Validate user, exit if not running as SYSTEM.
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    If ($CurrentPrincipal.Identities.IsSystem -ne $true) {

        Write-Warning 'This script is not running in the SYSTEM context, as required. Exiting script.'
        Exit

    }

    # // Check for existing connection. Exit if exists.
    If (Get-VpnConnection -Name $ProfileName -AllUserConnection -ErrorAction SilentlyContinue) {

        Write-Warning "The VPN profile ""$ProfileName"" already exists. Exiting script."
        Exit

    }

}

Else {

    If (Get-VpnConnection -Name $ProfileName -ErrorAction SilentlyContinue) {

        Write-Warning "The VPN profile ""$ProfileName"" already exists. Exiting script."
        Exit
    
    }

}

# // Validate XML for user or device tunnel connections
[xml]$Xml = Get-Content $xmlFilePath

If ($DeviceTunnel) {

    If (($Xml.VPNProfile.DeviceTunnel -eq 'False') -or ($Null -eq $Xml.VPNProfile.DeviceTunnel)) {

        Write-Warning 'ProfileXML is not configured for a device tunnel. Exiting script.'
        Exit 

    }

}

If (!$DeviceTunnel) {

    If ($Xml.VPNProfile.DeviceTunnel -eq 'True') {

        Write-Warning 'ProfileXML is not configured for a user tunnel. Exiting script.'
        Exit

    }

}

# // Import ProfileXML
$ProfileXML = Get-Content $xmlFilePath

# // Escape spaces in profile name
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

# // OMA URI information
$NodeCSPURI = './Vendor/MSFT/VPNv2'
$NamespaceName = 'root\cimv2\mdm\dmmap'
$ClassName = 'MDM_VPNv2_01'

# // Registry clean-up

Write-Verbose "Cleaning up registry artifacts for VPN connection ""$ProfileName""..."

# // Remove registry artifacts from ERM\Tracked

Write-Verbose "Searching for profile $ProfileNameEscaped..."
    
$BasePath = "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked"
$Tracked = Get-ChildItem -Path $BasePath
    
ForEach ($Item in $Tracked) {

    Write-Verbose "Processing $(Convert-Path $Item.PsPath)..."
    $Key = Get-ChildItem $Item.PsPath -Recurse | Where-Object { $_ | Get-ItemProperty -Include "Path*" }
    $PathCount = ($Key.Property -Match "Path\d+").Count
    Write-Verbose "Found a total of $PathCount Path* entries."

    # // There may be more than 1 matching key
    ForEach ($K in $Key) {

        $Path = $K.Property | Where-Object { $_ -Match "Path\d+" }
        $Count = $Path.Count
        Write-Verbose "Found $Count Path* entries under $($K.Name)."

        ForEach ($P in $Path) {

            Write-Verbose "Testing $P..."
            $Value = $K.GetValue($P)

            If ($Value -Match "$($ProfileNameEscaped)$") {

                Write-Verbose "Removing $Value under $($K.Name)..."
                $K | Remove-ItemProperty -Name $P
                
                # // Decrement count
                $Count--

            }

        } # // ForEach $P in $Path

        #  // Update count
        Write-Verbose "Setting count to $Count..."
        $K | Set-ItemProperty -Name Count -Value $Count

    } # // ForEach $K in $Key

} # // ForEach $Item in $Tracked

# // Remove registry artifacts from NetworkList\Profiles
$Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\'
Write-Verbose "Searching $path for VPN profile ""$ProfileName""..."
$Key = Get-Childitem -Path $Path | Where-Object { (Get-ItemPropertyValue $_.PsPath -Name Description) -eq $ProfileName }

If ($Key) {

    Write-Verbose "Removing $($Key.Name)..."
    $Key | Remove-Item

}

Else {

    Write-Verbose "No profiles found matching ""$ProfileName"" in the network list."

}

# // Create the VPN connection

#If (!($AllUserConnection)) {
If (!$AllUserConnection -and !$DeviceTunnel) {

    Try {

        # // Identify current user
        $UserName = Get-WmiObject -Class Win32_ComputerSystem | Select-Object UserName
        $User = New-Object System.Security.Principal.NTAccount($UserName.UserName)
        $Sid = $User.Translate([System.Security.Principal.SecurityIdentifier])
        $SidValue = $Sid.Value
        Write-Verbose "User SID is $SidValue."
    
    }
    
    Catch [Exception] {
    
        Write-Warning "$_"
        Write-Warning "Unable to get user SID. User may be logged on over Remote Desktop. Exiting script."
        Exit
    
    }

}

$Session = New-CimSession

Try {

    $NewInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $ClassName, $NamespaceName
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ParentID', "$nodeCSPURI", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('InstanceID', "$ProfileNameEscaped", 'String', 'Key')
    $NewInstance.CimInstanceProperties.Add($Property)
    $Property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ProfileXML', "$ProfileXML", 'String', 'Property')
    $NewInstance.CimInstanceProperties.Add($Property)

    If (!$AllUserConnection -and !$DeviceTunnel) {

        $Options = New-Object Microsoft.Management.Infrastructure.Options.CimOperationOptions
        $Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Type', 'PolicyPlatform_UserContext', $False)
        $Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Id', "$SidValue", $False)
        $Session.CreateInstance($NamespaceName, $NewInstance, $Options)

    }

    Else {

        $Session.CreateInstance($NamespaceName, $NewInstance)
        
    }
    
    Write-Output "Always On VPN user tunnel profile ""$ProfileName"" created successfully."

}

Catch [Exception] {

    Write-Output "Unable to create ""$ProfileName"" profile: $_"
    Exit

}

# SIG # Begin signature block
# MIINbAYJKoZIhvcNAQcCoIINXTCCDVkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUStzBzW1nxLu9zhzBDPg+EXOX
# jbCgggquMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFgMToaJZ9C4+QsN8/sAJzY/X1UCMA0G
# CSqGSIb3DQEBAQUABIIBADoOdwlV/9vVhn0WmWnzvCe88boLuGLALkZcOZOeoTyR
# cpIO7usrX/VPgRmD6NB7ZGbWTHbrD67UZw37uz3uaGAbQ7xK8QsWhxVRd+bkjpLC
# MCTo5vU97FHFG3r7RozIFkEYNeZqTFh5X6H+k6yTA24wO+MavlCZ/b7yR86VRPXa
# H+sgiyhHc2Dd+neZOM//fh6B0ErXn1rOOuthAMyMLuflB68/FrsfIEh32l6rWFpn
# 8muOIDr+tSFvSIeuwMbC71pIe/f+Safu4vAN1ktjjJ3jXGBGT7zLq0JznVsjC9Hs
# aUgdHDOmqKsrCT/66Xy3E2Kts9/Buel0+xX6Rgv8uOU=
# SIG # End signature block
