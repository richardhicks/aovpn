<#

.SYNOPSIS
    PowerShell script to remove Always On VPN connections.

.PARAMETER ProfileName
    Specifies the name of the VPN connection to remove.

.PARAMETER AllUserConnection
    Use this parameter when the VPN profile is a device tunnel, or a user tunnel provisioned for all users.

.PARAMETER CleanUpOnly
    Use this switch to perform registry clean up for a VPN connection that was previously removed.

.EXAMPLE
    .\Remove-AovpnConnection.ps1 -ProfileName 'Always On VPN' 

    Removes an Always On VPN user tunnel connection named "Always On VPN".

.EXAMPLE
    .\Remove-AovpnConnection.ps1 -ProfileName 'Always On VPN Device Tunnel' -DeviceTunnel

    Removes an Always On VPN device tunnel connection named "Always On VPN Device Tunnel".

.EXAMPLE
    .\Remove-AovpnConnection.ps1 -ProfileName 'Always On VPN' -CleanUpOnly

    Removes registry artifacts for an Always On VPN connection named 'Always On VPN' when the connection was removed manually.

.DESCRIPTION
    Removing an Always On VPN device tunnel or user tunnel connection requires more than just removing the connection itself. There are several locations in the registry that contain references to Always On VPN connections that are not removed when using the PowerShell Remove-VpnConnection command. This removes the VPN connection including all associated registry entries.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.1
    Creation Date:  August 23, 2020
    Last Updated:   October 27, 2020
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com/

#>

[CmdletBinding(SupportsShouldProcess)]

Param (

    [Parameter(Mandatory, HelpMessage = 'Enter the name of the VPN profile to remove.')]
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "ConnectionName")]
    [string]$ProfileName,
    [Alias("DeviceTunnel")]
    [switch]$AllUserConnection,
    [switch]$CleanUpOnly

)

If ($AllUserConnection) {

    # // Script must be running in the context of the SYSTEM account. Validate user, exit if not running as SYSTEM
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    If ($CurrentPrincipal.Identities.IsSystem -ne $true) {

        Write-Warning 'This script is not running in the SYSTEM context, as required. Exiting script.'
        Exit

    }

}

If (!$CleanUpOnly) {

    # // Get VPN connection
    If ($AllUserConnection) {

        $Connection = Get-VpnConnection -Name $ProfileName -AllUserConnection -ErrorAction SilentlyContinue
        
    }
        
    Else {
        
        $Connection = Get-VpnConnection -Name $ProfileName -ErrorAction SilentlyContinue
        
    }

    # // Exit script if VPN connection does not exist
    If ($Null -eq $Connection) {

        Write-Warning "The VPN connection ""$ProfileName"" does not exist. Exiting script."
        Exit

    }

    # // Escape spaces in profile name
    $ProfileNameEscaped = $ProfileName -Replace ' ', '%20'

    # // Get VPN profile
    $CimInstance = Get-CimInstance -Namespace 'root\cimv2\mdm\dmmap' -ClassName 'MDM_VPNv2_01' -Filter "ParentID='./Vendor/MSFT/VPNv2' and InstanceID='$ProfileNameEscaped'"

    # // Remove VPN profile
    Write-Verbose "Removing VPN connection ""$ProfileName""..."
    Remove-CimInstance -CimInstance $CimInstance

}

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

# SIG # Begin signature block
# MIINbAYJKoZIhvcNAQcCoIINXTCCDVkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmOit5KnsMKw47pNNHhyeDksy
# SOWgggquMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFO7/sJGw5VyRtIzZlOCty1l9i1P5MA0G
# CSqGSIb3DQEBAQUABIIBAH4XJnevqT1xZSTvKHhU1UBPF8I0LKIhXRrG+axPSqL9
# PSPnvKATPKnniF+d3p0S/EvBPjVJscgAaYBjEz1i80lMMFYzG42qXSFDmXyqaA6z
# HN3KGyjuOeQm8WoooYXAWJwgSQKGcBWWkT7LAVUjNQkzr/6h/yk6nIEkzwEpGsKk
# B/1FHZv3COum1uIesTL4z6R5TfUzwmxaaiKluV7gUa0rnA8tZ+uc4PmhZO+K0E/n
# cTxn3uTX9uGSAPtNW86s5TB1HuSSM4PMJBCpXoU8AYnocnXUTaoiN47B5ZvgPkDr
# 8D379VhYBDGkvMQuD3O6DWIh4XzBXw650oeOIGqP/iI=
# SIG # End signature block
