<#

.SYNOPSIS
    PowerShell script to relocate the DirectAccess/Routing and Remote Access Service (RRAS) inbox accounting database.

.PARAMETER SourcePath
    The original location of the Remote Access inbox accounting database. This paramter is not required if the database files are in the default location of C:\Windows\DirectAccess\db.

.PARAMETER DestinationPath
    The target location to move the Remote Access inbox accounting database to.

.PARAMETER Computername
    The name of the computer on which to run the command. Default is the local computer.

.PARAMETER Credential
    Optional credential to run the script under.

.EXAMPLE
    .\Move-InboxAccountingDatabase.ps1 -DestinationPath 'D:\DirectAccess\db\'

    Running this command will move the Remote Access inbox accounting database from the default location of C:\Windows\DirectAccess\DB to D:\DirectAccess\DB\.'

.EXAMPLE
    .\Move-InboxAccountingDatabase.ps1 -SourcePath 'D:\DirectAccess\db\' -DestinationPath 'E:\DirectAccess\db\'

    Running this command will move the Remote Access inbox accounting database from the custom location of D:\Windows\DirectAccess\db\ to E:\DirectAccess\db\.'

.DESCRIPTION
    When DirectAccess or VPN is enabled on a Windows Server, and inbox accounting is enabled, a Windows Internal Database (WID) is created on the system drive by default. This script allows the administrator to relocate this database to another drive to increase data retention time and improve performance.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.13
    Creation Date:  February 1, 2020
    Last Updated:   January 3, 2022
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com/

#>

[CmdletBinding(SupportsShouldProcess)]

Param (

    [Parameter(HelpMessage = "Enter the path to the Direct Access database folder relative to the remote computer.")]
    [Alias("Path")]
    [string]$SourcePath = "C:\Windows\DirectAccess\db",
    [Parameter(Mandatory, HelpMessage = "Enter the target folder path to move the Direct Access database relative to the remote computer.")]
    [alias("Destination")]
    [string]$DestinationPath,
    [Parameter(HelpMessage = "Enter the name of the remote RRAS server.", ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Computername = $env:computername,
    [switch]$Passthru,
    [Parameter(HelpMessage = "Enter an optional credential in the form domain\username or machine\username.")]
    [PSCredential]$Credential,
    [ValidateSet('Default', 'Basic', 'Credssp', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
    [ValidateNotNullorEmpty()]
    [string]$Authentication = "default",
    [switch]$UseSSL

)

Begin {

    Write-Verbose "Starting $($myinvocation.mycommand)"
    # // Display some meta information for troubleshooting
    Write-Verbose "PowerShell version: $($psversiontable.psversion)"
    Write-Verbose "Operating System: $((Get-Ciminstance -class win32_operatingsystem -property caption).caption)"

    $sb = {

        [cmdletbinding()]
        Param (

            [ValidateScript( {

                    # // Write a custom error message if the database file isn't in the source path
                    If (Test-Path "$_\RaAcctDb.mdf") {

                        Return $True

                    }

                    Else {

                        Throw "The path ($_) does not appear to contain the RaAcctDB.mdf database."

                    }

                })]

            [string]$SourcePath,
            [string]$DestinationPath,
            [bool]$PassThru

        )

        $VerbosePreference = $using:verbosepreference
        $whatifpreference = $using:whatifpreference
        Write-Verbose "SourcePath = $SourcePath"
        Write-Verbose "TargetPath = $DestinationPath"
        Write-Verbose "WhatIf = $whatifpreference"
        Write-verbose "Verbose = $VerbosePreference"

        If (-Not (Test-Path $DestinationPath)) {

            Write-Verbose "Creating target $DestinationPath"
            Try {

                New-Item -ItemType Directory -Force -Path $DestinationPath -ErrorAction Stop | Out-Null

            }

            Catch {

                Write-Verbose "Failed to create target folder $DestinationPath"
                Throw $_

                # // This should terminate the command if the target folder can't be created.
                # // We will force a bailout just in case this doesn't terminate.

                Return

            }

        }

        Write-Verbose "Copying Access Control from $SourcePath to $DestinationPath..."

        If ($pscmdlet.ShouldProcess($DestinationPath, "Copy Access Control")) {

            Try {

                Write-Verbose "Get ACL..."
                $Acl = Get-Acl -Path $SourcePath -ErrorAction stop
                Write-Verbose "Set ACL..."
                Set-Acl -Path $DestinationPath -aclobject $Acl -ErrorAction stop

            }

            Catch {

                Write-Verbose "Failed to copy ACL from $SourcePath to $DestinationPath."
                Throw $_
                # //Bail out if PowerShell doesn't terminate the pipeline
                Return

            }

        } # // WhatIf copying ACL

        Write-Verbose "Stopping the RemoteAccess Management service..."

        Try {

            Get-Service RaMgmtSvc -ErrorAction Stop | Stop-Service -Force -ErrorAction Stop

        }

        Catch {

            Write-Verbose "Failed to stop the RemoteAccess Management service."
            Throw $_
            # // Bail out if PowerShell doesn't terminate the pipeline
            Return

        }

        Write-Verbose "Altering database..."
        $sqlConn = 'server=\\.\pipe\Microsoft##WID\tsql\query;Database=RaAcctDb;Trusted_Connection=True;'
        $Connection = New-Object System.Data.SQLClient.SQLConnection($sqlConn)
        Write-Verbose "Opening database connection..."
        
        If ($pscmdlet.ShouldProcess("RaAcctDB", "Open Connection")) {

            $Connection.Open()

        }

        $Command = $Connection.CreateCommand()
        $CommandText = "USE master;ALTER DATABASE RaAcctDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;EXEC sp_detach_db @dbname = N'RaAcctDb';"
        Write-Verbose $CommandText
        $Command.CommandText = $CommandText
        $Command | Out-String | Write-Verbose
        
        If ($pscmdlet.ShouldProcess("RaAcctDB", "ALTER DATABASE")) {

            Write-Verbose "Executing..."
            $rdrDetach = $Command.ExecuteReader()
            Write-Verbose "Database detached."
            $rdrDetach | Out-String | Write-Verbose

        }

        Write-Verbose "Closing the database connection..."

        If ($Connection.State -eq "Open") {

            $Connection.Close()

        }

        Write-Verbose "Moving database files from $sourcePath to $DestinationPath..."
        $Mdf = Join-Path -path $SourcePath -ChildPath "RaAcctDb.mdf"
        $Ldf = Join-Path -path $SourcePath -ChildPath "RaAcctDb_log.ldf"
        Move-Item -Path $Mdf -Destination $DestinationPath
        Move-Item -Path $Ldf -Destination $DestinationPath

        Write-Verbose "Creating new database..."
        $sqlConn = 'server=\\.\pipe\Microsoft##WID\tsql\query;Database=;Trusted_Connection=True;'
        $Connection = New-Object System.Data.SQLClient.SQLConnection($sqlConn)
        Write-Verbose "Opening database connection..."

        If ($pscmdlet.ShouldProcess("New DB", "Open Connection")) {

            $Connection.Open()

        }

        $Command = $Connection.CreateCommand()
        $targetmdf = Join-Path -Path $DestinationPath -ChildPath RaAcctDb.mdf
        $targetldf = Join-Path -Path $DestinationPath -ChildPath RaAcctDb_log.ldf
        $CommandText = "USE master CREATE DATABASE RaAcctDb ON (FILENAME = '$targetmdf'),(FILENAME = '$targetldf') FOR ATTACH;USE [master] ALTER DATABASE [RaAcctDb] SET READ_WRITE WITH NO_WAIT;"
        Write-Verbose $CommandText
        $Command.CommandText = $CommandText
        
        If ($pscmdlet.ShouldProcess($targetmdf, "CREATE DATABASE")) {

            Write-Verbose "Executing..."
            $rdrAttach = $Command.ExecuteReader()
            Write-Verbose "Database attached."
            $rdrAttach | Out-String | Write-Verbose

        }

        Write-Verbose "Closing WID connection..."

        If ($Connection.State -eq "Open") {

            $Connection.Close()

        }

        Write-Verbose "Starting the RemoteAccess Management Service..."

        Try {

            Get-Service RaMgmtSvc -ErrorAction stop | Start-Service -ErrorAction stop

        }

        Catch {

            Write-Verbose "Failed to start RemoteAccess Management service."
            Throw $_

        }

        #// Manage README.txt file
        If ($SourcePath -eq "C:\Windows\DirectAccess\db") {

            # // Create a readme.txt file in the default location if files are being moved.

            $txt = @"
The inbox accounting database and log files have been relocated to $DestinationPath.
The move was performed by $env:USERDOMAIN\$env:USERNAME on $((Get-Date).ToShortDateString()) at $((Get-Date).ToShortTimeString()).
"@

            Set-Content -Path C:\Windows\DirectAccess\DB\readme.txt -Value $txt

        }

        ElseIf ($DestinationPath -eq "C:\Windows\DirectAccess\db" -AND (Test-Path -path "C:\Windows\DirectAccess\db\readme.txt") ) {

            #// If the destination is the default location and the readme file exists, delete the file.
            Remove-Item -Path "C:\Windows\DirectAccess\db\readme.txt"

        }

        If ($Passthru) {

            Get-ChildItem -Path $DestinationPath

        }

    } #// Close scriptblock

    # // Define a set of parameter values to splat to Invoke-Command
    $icmParams = @{

        Computername     = ""
        Scriptblock      = $sb
        HideComputername = $True
        Authentication   = $Authentication
        ArgumentList     = @($SourcePath, $DestinationPath, $Passthru)
        ErrorAction      = "Stop"

    }

    If ($pscredential.username) {

        Write-Verbose "Adding an alternate credential for $($pscredential.username)..."
        $icmParams.Add("Credential", $PSCredential)

    }

    If ($UseSSL) {

        Write-Verbose "Using SSL."
        $icmParams.Add("UseSSL", $True)

    }

    Write-Verbose "Using $Authentication authentication."

} # // Begin

Process {

    ForEach ($Computer in $Computername) {

        Write-Verbose "Querying $($computer.toUpper())..."
        $icmParams.Computername = $Computer
        $icmParams | Out-String | Write-Verbose

        Try {

            # //Display result without the runspace ID
            Invoke-Command @icmParams

        }

        Catch {

            Throw $_

        }

    } #// Foreach computer

} # // Process

End {

    Write-Verbose "Ending $($myinvocation.MyCommand)"

} #end

# SIG # Begin signature block
# MIIdWQYJKoZIhvcNAQcCoIIdSjCCHUYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbFwXlReEk8uM6Ao38uzwBv8k
# cNygghfxMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
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
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBTEwggQZ
# oAMCAQICEAqhJdbWMht+QeQF2jaXwhUwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4X
# DTE2MDEwNzEyMDAwMFoXDTMxMDEwNzEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEx
# MC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIFRpbWVzdGFtcGluZyBD
# QTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL3QMu5LzY9/3am6gpnF
# OVQoV7YjSsQOB0UzURB90Pl9TWh+57ag9I2ziOSXv2MhkJi/E7xX08PhfgjWahQA
# OPcuHjvuzKb2Mln+X2U/4Jvr40ZHBhpVfgsnfsCi9aDg3iI/Dv9+lfvzo7oiPhis
# EeTwmQNtO4V8CdPuXciaC1TjqAlxa+DPIhAPdc9xck4Krd9AOly3UeGheRTGTSQj
# MF287DxgaqwvB8z98OpH2YhQXv1mblZhJymJhFHmgudGUP2UKiyn5HU+upgPhH+f
# MRTWrdXyZMt7HgXQhBlyF/EXBu89zdZN7wZC/aJTKk+FHcQdPK/P2qwQ9d2srOlW
# /5MCAwEAAaOCAc4wggHKMB0GA1UdDgQWBBT0tuEgHf4prtLkYaWyoiWyyBc1bjAf
# BgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzASBgNVHRMBAf8ECDAGAQH/
# AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB5BggrBgEF
# BQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBD
# BggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2Ny
# bDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDig
# NoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNybDBQBgNVHSAESTBHMDgGCmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYc
# aHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzALBglghkgBhv1sBwEwDQYJKoZI
# hvcNAQELBQADggEBAHGVEulRh1Zpze/d2nyqY3qzeM8GN0CE70uEv8rPAwL9xafD
# DiBCLK938ysfDCFaKrcFNB1qrpn4J6JmvwmqYN92pDqTD/iy0dh8GWLoXoIlHsS6
# HHssIeLWWywUNUMEaLLbdQLgcseY1jxk5R9IEBhfiThhTWJGJIdjjJFSLK8pieV4
# H9YLFKWA1xJHcLN11ZOFk362kmf7U2GJqPVrlsD0WGkNfMgBsbkodbeZY4UijGHK
# eZR+WfyMD+NvtQEmtmyl7odRIeRYYJu6DC0rbaLEfrvEJStHAgh8Sa4TtuF8QkIo
# xhhWz0E0tmZdtnR79VYzIi8iNrJLokqV2PWmjlIwggawMIIEmKADAgECAhAIrUCy
# YNKcTJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAf
# BgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBa
# Fw0zNjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2Vy
# dCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25p
# bmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc
# 9es0JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyA
# VxJrQ5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQ
# IXhFLqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/
# sk+FLEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na5
# 9zHh3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pg
# VItJwZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7Bzzosm
# JQayg9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQ
# okbIYViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jL
# chApQfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHM
# IRroOBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQAB
# o4IBWTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8R
# hvv+YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYD
# VR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGsw
# aTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUF
# BzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# Um9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeB
# DAEDMAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bg
# Ahql+Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7
# FoFFUP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZ
# GM1hmYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG
# 3RywYFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5U
# bdldAhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WI
# IIJw8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956
# rEnPLqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuW
# TatEQOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3
# E+bnKD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60b
# hQjiWQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOIm
# YIbqyK+p/pQd52MbOoZWeE4wggcCMIIE6qADAgECAhABZnISBJVCuLLqeeLTB6xE
# MA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2Vy
# dCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25p
# bmcgUlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjExMjAyMDAwMDAwWhcNMjQx
# MjIwMjM1OTU5WjCBhjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWEx
# FjAUBgNVBAcTDU1pc3Npb24gVmllam8xJDAiBgNVBAoTG1JpY2hhcmQgTS4gSGlj
# a3MgQ29uc3VsdGluZzEkMCIGA1UEAxMbUmljaGFyZCBNLiBIaWNrcyBDb25zdWx0
# aW5nMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA6svrVqBRBbazEkrm
# htz7h05LEBIHp8fGlV19nY2gpBLnkDR8Mz/E9i1cu0sdjieC4D4/WtI4/NeiR5id
# tBgtdek5eieRjPcn8g9Zpl89KIl8NNy1UlOWNV70jzzqZ2CYiP/P5YGZwPy8Lx5r
# IAOYTJM6EFDBvZNti7aRizE7lqVXBDNzyeHhfXYPBxaQV2It+sWqK0saTj0oNA2I
# u9qSYaFQLFH45VpletKp7ded2FFJv2PKmYrzYtax48xzUQq2rRC5BN2/n7771NDf
# J0t8udRhUBqTEI5Z1qzMz4RUVfgmGPT+CaE55NyBnyY6/A2/7KSIsOYOcTgzQhO4
# jLmjTBZ2kZqLCOaqPbSmq/SutMEGHY1MU7xrWUEQinczjUzmbGGw7V87XI9sn8Ec
# WX71PEvI2Gtr1TJfnT9betXDJnt21mukioLsUUpdlRmMbn23or/VHzE6Nv7Kzx+t
# A1sBdWdC3Mkzaw/Mm3X8Wc7ythtXGBcLmBagpMGCCUOk6OJZAgMBAAGjggIGMIIC
# AjAfBgNVHSMEGDAWgBRoN+Drtjv4XxGG+/5hewiIZfROQjAdBgNVHQ4EFgQUxF7d
# o+eIG9wnEUVjckZ9MsbZ+4kwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMIG1BgNVHR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIw
# MjFDQTEuY3JsMFOgUaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNl
# cnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDA+
# BgNVHSAENzA1MDMGBmeBDAEEATApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9DUFMwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNB
# NDA5NlNIQTM4NDIwMjFDQTEuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEL
# BQADggIBAEvHt/OKalRysHQdx4CXSOcgoayuFXWNwi/VFcFr2EK37Gq71G4AtdVc
# WNLu+whhYzfCVANBnbTa9vsk515rTM06exz0QuMwyg09mo+VxZ8rqOBHz33xZyCo
# Ttw/+D/SQxiO8uQR0Oisfb1MUHPqDQ69FTNqIQF/RzC2zzUn5agHFULhby8wbjQf
# Ut2FXCRlFULPzvp7/+JS4QAJnKXq5mYLvopWsdkbBn52Kq+ll8efrj1K4iMRhp3a
# 0n2eRLetqKJjOqT335EapydB4AnphH2WMQBHHroh5n/fv37dCCaYaqo9JlFnRIrH
# U7pHBBEpUGfyecFkcKFwsPiHXE1HqQJCPmMbvPdV9ZgtWmuaRD0EQW13JzDyoQdJ
# xQZSXJhDDL+VSFS8SRNPtQFPisZa2IO58d1Cvf5G8iK1RJHN/Qx413lj2JSS1o3w
# gNM3Q5ePFYXcQ0iPxjFYlRYPAaDx8t3olg/tVK8sSpYqFYF99IRqBNixhkyxAyVC
# k6uLBLgwE9egJg1AFoHEdAeabGgT2C0hOyz55PNoDZutZB67G+WN8kGtFYULBloR
# KHJJiFn42bvXfa0Jg1jZ41AAsMc5LUNlqLhIj/RFLinDH9l4Yb0ddD4wQVsIFDVl
# JgDPXA9E1Sn8VKrWE4I0sX4xXUFgjfuVfdcNk9Q+4sJJ1YHYGmwLMYIE0jCCBM4C
# AQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/
# BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYg
# U0hBMzg0IDIwMjEgQ0ExAhABZnISBJVCuLLqeeLTB6xEMAkGBSsOAwIaBQCgeDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEW
# BBSQVzULY/6mhRgcgQoPYwRUDPztqDANBgkqhkiG9w0BAQEFAASCAYB5gsjlamVe
# F6bOcAuieLHytKK0Lst9Rj2kpUckcyUy1nxAvXOZMYy5bIuO3+2sJo303DWs0Q5C
# ++Ulv1ShrNB8KLePlpVmbh22vxBNB6DvxAIeEPJSgJOqoFEPzV6xSUR5p6cqRbtZ
# 2JsLa+yiZbDCnn2n3qqScLgo27PKfo9aaSsNbSO3CAoRGbUu/uKB3VLgYejWoP2R
# Hr+t4lvkahAagVtzNLfu9VZvHvEvJRuGpmgYEiqHwX5qkIlBJheoKEuKyikSbxlb
# UKierOUGyY3BfVEVpUXT7sN0T7W/xFExDxoN5Pc0/WcsfUWF5DzaD3rUDWlf4uEv
# 87/Qh3OXUMuzIOys1MtIRXXjkgJMeXF+AAR4TKEu8LjZC7Fq0awTHuoQSjvTntnb
# eVJst7g4NpNU3ioENSGh1bH8nwynTpo/uUG8Tfr127kw+Dy87AJh5So2YLUPtYy6
# 7DG4MafpcomXEHYpr3B3RN9Dd5KUVwNPRHK32lNU4ViXfjTVW0K7de2hggIwMIIC
# LAYJKoZIhvcNAQkGMYICHTCCAhkCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8G
# A1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIFRpbWVzdGFtcGluZyBDQQIQ
# DUJK4L46iP9gQCHOFADw3TANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIyMDEwNzE2NTI1MFowLwYJKoZI
# hvcNAQkEMSIEIDi4YqkuYoocbwVXoj4oQxs7tEEPGBwQ74QLAnt94sWPMA0GCSqG
# SIb3DQEBAQUABIIBACoofDO56QZdSLEeB8FL23YicXurb/MZsbssppXVRlAwDHZ5
# pOzq+xmAocdWq6Gh7mL18cp7FYbzg+ApCK7AAljVjb4Dxjzx9Y/+Xf2pF5wjjIx8
# zMl5qHdK2+WABCCQXKHb5HjM7SzCghR0hC5SZXui0Y83tj9KeIWrZwcUW37UzKBe
# rg1+IogrVOCToGmw9gq1PAC3kaesL0neDt7Q9AOuGzku2GOH1VXlYkSfHl1l9oiA
# A5jN9aurl3SwJMmJjhfLlUHdzjdPJCiYj107uBYPh6QLO1HA1+nV4Z5JWRJGu5Br
# 6Tmii39ngwhNVWXJi7MsfV2HB8hzYvpQ3LXNsxg=
# SIG # End signature block
