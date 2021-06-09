<#
.SYNOPSIS
    PowerShell script to create host routes for all domain controllers in XML format for use with Always On VPN ProfileXML.

.PARAMETER InputFile
    Specifies the path and filename for IP addresses to be formatted for ProfileXML.

.PARAMETER OutputFile
    Specifies the path and filename for XML output.

.PARAMETER Discover
    Automatically collect IP addresses for all domain controllers in the organization.

.EXAMPLE
    .\Create-ProfileXMLRoutes.ps1 -Discover -OutputFile .\routes.txt

    Running this PowerShell command will generate a list of all domain controller IP addresses formatted for use with Always On VPN ProfileXML in the file .\routes.txt.

.EXAMPLE
    .\Create-ProfileXMLRoutes.ps1 -InputFile .\addresslist.txt -OutputFile .\routes.txt

    Running this PowerShell command will generate a formatted list of IP addresses from a text file for use with Always On VPN ProfileXML in the file .\routes.txt.

.DESCRIPTION
    It is recommended that host routes for all domain controllers in the enterprise be defined in ProfileXML for the Always On VPN device tunnel. This script enumerates all domain controllers in the forest and outputs their IP address in XML format. Optionally, a list of IP addresses can be provided. When using the Discover option, this script must be run on a domain controller or administrator workstation with the Active Directory PowerShell module installed. Contents of the output file can be copied/pasted in to ProfileXML.

.LINK
    https://directaccess.richardhicks.com/2019/03/25/always-on-vpn-device-tunnel-configuration-using-intune/

.LINK
    https://directaccess.richardhicks.com/2017/12/11/always-on-vpn-windows-10-device-tunnel-step-by-step-configuration-using-powershell/

.NOTES
    Version:        1.2
    Creation Date:  May 25, 2019
    Last Updated:   June 9, 2021
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com

#>

[CmdletBinding()]

Param (

    [switch]$Discover,
    [string]$InputFile,
    [string]$OutputFile = ".\routes.txt"

)

If ((!$InputFile) -and (!$Discover)) {

    Write-Warning 'No input mode chosen. Exiting script.'
    Exit

}

If ($InputFile -and $Discover) {

    Write-Warning 'Input file and automatic discovery are mutually exclusive options. Exiting script.'
    Exit

}

If ($Discover) {

    # // Check for Active Directory PowerShell module. Exit if not installed.
    Write-Verbose 'Checking for the Active Directory PowerShell module...'
    $AdModule = Get-Module -Name ActiveDirectory

    If ($Null -eq $AdModule) {

        Write-Warning 'Active Directory PowerShell module not installed. Exiting script.'
        Exit

    }

    If (Test-Path $OutputFile) {

        Write-Verbose 'Old route file found. Deleting...'
        Remove-Item $OutputFile

    }

    $DCList = @()
    $DCList = { $DCList }.Invoke()
    
    $Forest = Get-ADForest
    
    ForEach ($Domain in $Forest.Domains) {
        
        Write-Verbose "Creating list of domain controllers for $Domain..."
        $AllDCs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName

        ForEach ($DC in $AllDCs) {

            Write-Verbose "Resolving IP address for domain controller $DC..."
            $IP = Resolve-DnsName -Type A $DC | Select-Object -ExpandProperty IPAddress
            $DCList.Add($IP)

        }

    }

} # // Discover

If ($InputFile) {

    # // Validate input file exists
    If (!(Test-Path $InputFile)) {

        Write-Warning "$InputFile does not exist. Exiting Script."
        Exit
    }

    Else {
        
        $DCList = Get-Content $InputFile

    }
    
}

Write-Verbose 'Outputting domain controller IP addresses in XML format for ProfileXML...'
$Routes = @()
$Routes = { $Routes }.Invoke()

$Routes.Add("<VPNProfile>")

ForEach ($Address in $DCList) {

    $Routes.Add("<Route>")
    $Routes.Add("<Address>$Address</Address>")
    $Routes.Add("<PrefixSize>32</PrefixSize>")
    $Routes.Add("</Route>")
  
}

$Routes.Add("</VPNProfile>")

function Format-XML ([xml]$XML, $indent = 3) { 

    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented"
    $xmlWriter.Indentation = $Indent 
    $xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output $StringWriter.ToString() 

}

Format-XML $Routes | Out-File $OutputFile

If ($Discover) {

    Write-Warning 'Some domain controllers may have multiple IP addresses registered in DNS. This results in incorrectly formatted XML. Please review before implementing.'

}

# SIG # Begin signature block
# MIIZ1wYJKoZIhvcNAQcCoIIZyDCCGcQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHsTbDgJ5AEbGqEc+fxYWWMtp
# hJ6gghTlMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAwMDAwMFoXDTMxMDEw
# NjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HXOhFCvQp1dU2UtAxQ
# tSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB+in43Stwhd4CGPN4
# bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPhLxs6t2HWc+xObTOK
# fF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizVI9r0TXhG4wODMSlK
# XAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKbaYK02/xWVLwfoYer
# vnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQECAwEAAaOCAbgwggG0
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYIKwYBBQUHAgEWG2h0
# dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAWgBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ23eNqerwwcQYDVR0f
# BGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJl
# ZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRpbWVzdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucgDo5nRv1CclF0CiNH
# o6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1ppA/2uHDPYuj1UUp4
# eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18jUmmDgvoaU+2QzI2h
# F3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFcz8QRcucbZEnYIpp1
# FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub9y4bTxMd90oNcX6X
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBTAwggQY
# oAMCAQICEAQJGBtf1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4X
# DTEzMTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEx
# MC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBD
# QTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsx
# SRnP0PtFmbE620T1f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawO
# eSg6funRZ9PG+yknx9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJ
# RdQtoaPpiCwgla4cSocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEc
# z+ryCuRXu0q16XTmK/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whk
# PlKWwfIPEvTFjg/BougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8l
# k9ECAwEAAaOCAc0wggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQD
# AgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARI
# MEYwOAYKYIZIAYb9bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdp
# Y2VydC5jb20vQ1BTMAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg
# +S32ZXUOWDAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG
# 9w0BAQsFAAOCAQEAPuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/E
# r4v97yrfIFU3sOH20ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3
# nEZOXP+QsRsHDpEV+7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpo
# aK+bp1wgXNlxsQyPu6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW
# 6Fkd6fp0ZGuy62ZD2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ
# 92JuoVP6EpQYhS6SkepobEQysmah5xikmmRR7zCCBTEwggQZoAMCAQICEAqhJdbW
# Mht+QeQF2jaXwhUwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTE2MDEwNzEyMDAw
# MFoXDTMxMDEwNzEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIFRpbWVzdGFtcGluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAL3QMu5LzY9/3am6gpnFOVQoV7YjSsQOB0Uz
# URB90Pl9TWh+57ag9I2ziOSXv2MhkJi/E7xX08PhfgjWahQAOPcuHjvuzKb2Mln+
# X2U/4Jvr40ZHBhpVfgsnfsCi9aDg3iI/Dv9+lfvzo7oiPhisEeTwmQNtO4V8CdPu
# XciaC1TjqAlxa+DPIhAPdc9xck4Krd9AOly3UeGheRTGTSQjMF287DxgaqwvB8z9
# 8OpH2YhQXv1mblZhJymJhFHmgudGUP2UKiyn5HU+upgPhH+fMRTWrdXyZMt7HgXQ
# hBlyF/EXBu89zdZN7wZC/aJTKk+FHcQdPK/P2qwQ9d2srOlW/5MCAwEAAaOCAc4w
# ggHKMB0GA1UdDgQWBBT0tuEgHf4prtLkYaWyoiWyyBc1bjAfBgNVHSMEGDAWgBRF
# 66Kv9JLLgjEtUYunpyGd823IDzASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB
# /wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYI
# KwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3
# aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2Ny
# bDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBQBgNV
# HSAESTBHMDgGCmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cu
# ZGlnaWNlcnQuY29tL0NQUzALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggEB
# AHGVEulRh1Zpze/d2nyqY3qzeM8GN0CE70uEv8rPAwL9xafDDiBCLK938ysfDCFa
# KrcFNB1qrpn4J6JmvwmqYN92pDqTD/iy0dh8GWLoXoIlHsS6HHssIeLWWywUNUME
# aLLbdQLgcseY1jxk5R9IEBhfiThhTWJGJIdjjJFSLK8pieV4H9YLFKWA1xJHcLN1
# 1ZOFk362kmf7U2GJqPVrlsD0WGkNfMgBsbkodbeZY4UijGHKeZR+WfyMD+NvtQEm
# tmyl7odRIeRYYJu6DC0rbaLEfrvEJStHAgh8Sa4TtuF8QkIoxhhWz0E0tmZdtnR7
# 9VYzIi8iNrJLokqV2PWmjlIwggV2MIIEXqADAgECAhAM5MoQ1xoJR7kK3zVjbl2I
# MA0GCSqGSIb3DQEBCwUAMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lD
# ZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwHhcNMTkxMjE2MDAw
# MDAwWhcNMjExMjIwMTIwMDAwWjCBsjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNh
# bGlmb3JuaWExFjAUBgNVBAcTDU1pc3Npb24gVmllam8xKjAoBgNVBAoTIVJpY2hh
# cmQgTS4gSGlja3MgQ29uc3VsdGluZywgSW5jLjEeMBwGA1UECxMVUHJvZmVzc2lv
# bmFsIFNlcnZpY2VzMSowKAYDVQQDEyFSaWNoYXJkIE0uIEhpY2tzIENvbnN1bHRp
# bmcsIEluYy4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCv7CapjsGm
# +zoSY1XbbskPm157Sb6W25iaV5MnVMZMJ+JtxZT7Yc4cgIehR1IXgzwvQuiieQhY
# qgwJRoYXOu8wWOW38nyO4fuRrN/eYR1n2XPE63oYufkgumr7yLbFvhwaot3WTwUQ
# loVyrrpe+LbGSdDevxwMlYFeLj4KgtjT9U800+GjZFOWk3xAv9fP/+ET4oHtjNoX
# 7vBgJUKRH9CfgPwB+JQEIDDx81uM0ahD+/vGH5/pOJ20LtjkHwPwBHgglKiTxluK
# /P4cmPnBk1axLvQPwedZDuEz/ucDBCG16HT+SPSbpMxW2y/hv0oIMTI9PvVynmDg
# nEw77HdRmHQJAgMBAAGjggHFMIIBwTAfBgNVHSMEGDAWgBRaxLl7KgqjpepxA8Bg
# +S32ZXUOWDAdBgNVHQ4EFgQUHoFzL6hKFfDrye2qV5czATguPWMwDgYDVR0PAQH/
# BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGGL2h0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWg
# M6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcx
# LmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRw
# czovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEE
# eDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYB
# BQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJB
# c3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3
# DQEBCwUAA4IBAQBwlZI22UTsyX1Ut//3rPy1VsXTnBn8SQLg72i4R2DkCYzH/kt1
# bZPPg6vABQKtFaAhGwLZ5rhnOxmWLWLtN3BpiZvYsYoymrTPWDzyLKMh1fqMKhSo
# xCrWNkAVon2IyTsafaQeuVwe9WPHBgSd/dfEx4aS+8GXwIGRX989DautLIp4ZJ26
# ZZ0YbHoO/84fmWiD7HpB2vq2QULtvIqgIGyIRNQezrfPndB5WNXEfTNcZr38bnte
# mFTHXxRNiSAihsw3j51GLPEDmxTVYIGmy1yEBVsCwzw6EajEImVAaNpfFKTq6KzZ
# et61QOE3MKh2p3P26XwJUp6b24lNiOhXoIFiMYIEXDCCBFgCAQEwgYYwcjELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENv
# ZGUgU2lnbmluZyBDQQIQDOTKENcaCUe5Ct81Y25diDAJBgUrDgMCGgUAoHgwGAYK
# KwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU
# Ix0c5PeEJpTDi1jVydOoTd9HvtswDQYJKoZIhvcNAQEBBQAEggEAOq2qvQnZPdSi
# UeMgBBvgHieCYusmhLotcxhntBGFCEL88glrTm9JtmTAZ0J0K35GD78Kgu024yj8
# e3jm4x221xRS3ex3WVlgpHTD1DarCkN9yxJQjYrAVKHof3tnMh4Y7BWk8E1zHl1o
# S5LTex1Rd6YtXu2F5bGt91lDJbrIUr9hzpcw7JAqwYAtff2wG9bBrlhCaQtdL2Fq
# zkUwtzwnHk9yDuqQ8gHhvWPn0gB9s3OuSbOeglB45S3U+UdauhZNiUWEmMYXsm4O
# C4w/fIA93PdcDRfDLo94Pu2w35ycnJIWNbskqJVVelD2XUHqfpJAYs7gcRzozD+V
# BgXmdXN67aGCAjAwggIsBgkqhkiG9w0BCQYxggIdMIICGQIBATCBhjByMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGlt
# ZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDdMA0GCWCGSAFlAwQCAQUAoGkw
# GAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjEwNjA5
# MTg1ODUwWjAvBgkqhkiG9w0BCQQxIgQg7WUsUWkgct3kbscA4Y2Vjab8kfZs49GO
# aGlXpbnfx1wwDQYJKoZIhvcNAQEBBQAEggEAt8Qqw25Aef1SaZSJo+i87suGQb+m
# dqAAvIuMcB009RdhhyTn/D9To+Xz+SSEcXRqbJ9MKSJcrQbdiprOCnjBVHG3zDqg
# miN+Wvl7Ea1geOHTNBy5FQ9kERf4h86REeaaOhh9sLAggFKvA2QFJefDF+Q4P6ms
# Bq9JZrmjSE9Su3gA017Qz1+hHW03npp9eEajAWK2yxoPMOpheF/Af+LuvONmM90I
# 46wDNR6ay6EEdNCwq1tPILW4Iy4ZIhZDwoq85Epr+HFtUod8E5AZUHazi8UQRYr8
# 41yUGw/qPsUZGYkgm/yYiXluxCo5hGTqJcOuCmXe4bwsDMlR2GFoFgmMwQ==
# SIG # End signature block
