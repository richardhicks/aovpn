<#

.SYNOPSIS
    PowerShell script to relocate the Remote Access inbox accounting database.

.PARAMETER SourcePath
    The original location of the Remote Access inbox accounting database.

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
    When DirectAccess or VPN is enabled on a Windows Server and Inbox accounting is enabled, a Windows Internal Database (WID) is created on the C: drive by default. This script allows the administrator to relocate this database to another drive to increase data retention and/or improve performance. 

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.1
    Creation Date:  February 1, 2020
    Last Updated:   September 19, 2020
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://directaccess.richardhicks.com/

#>

[cmdletbinding(SupportsShouldProcess)]

Param (

    [Parameter(HelpMessage = "Enter the path to the Direct Access database folder relative to the remote computer")]
    [Alias("Path")]
    [string]$SourcePath = "C:\Windows\DirectAccess\db",
    [Parameter(Mandatory, HelpMessage = "Enter the target folder path to move the Direct Access database  relative to the remote computer")]
    [alias("Destination")]
    [string]$DestinationPath,
    [Parameter(HelpMessage = "Enter the name of the remote RRAS server.", ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Computername = $env:computername,
    [switch]$Passthru,
    [Parameter(HelpMessage = "Enter an optional credential in the form domain\username or machine\username")]
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

                        return $True

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

                New-Item -ItemType Directory -Force -Path $DestinationPath -ErrorAction stop

            }

            Catch {

                Write-Verbose "Failed to create target folder $DestinationPath"
                Throw $_
                # // This should terminate the command if the target folder can't be created.
                # // We will force a bailout just in case this doesn't terminate.

                Return

            }

        }

        Write-Verbose "Copying Access Control from $SourcePath to $DestinationPath"

        If ($pscmdlet.ShouldProcess($DestinationPath, "Copy Access Control")) {

            Try {

                Write-Verbose "Get ACL"
                $Acl = Get-Acl -Path $SourcePath -ErrorAction stop
                Write-Verbose "Set ACL"
                Set-Acl -Path $DestinationPath -aclobject $Acl -ErrorAction stop

            }

            Catch {

                Write-Verbose "Failed to copy ACL from $SourcePath to $DestinationPath"
                Throw $_
                # //Bail out if PowerShell doesn't terminate the pipeline
                return

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

        Write-Verbose "Altering database"
        $sqlConn = 'server=\\.\pipe\Microsoft##WID\tsql\query;Database=RaAcctDb;Trusted_Connection=True;'
        $conn = New-Object System.Data.SQLClient.SQLConnection($sqlConn)
        Write-Verbose "Opening WID connection"
        
        If ($pscmdlet.ShouldProcess("RaAcctDB", "Open Connection")) {

            $conn.Open()

        }

        $cmd = $conn.CreateCommand()
        $cmdText = "USE master;ALTER DATABASE RaAcctDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;EXEC sp_detach_db @dbname = N'RaAcctDb';"
        Write-Verbose $cmdText
        $cmd.CommandText = $cmdText
        $cmd | Out-String | Write-Verbose
        
        If ($pscmdlet.ShouldProcess("RaAcctDB", "ALTER DATABASE")) {

            Write-Verbose "Executing"
            $rdrDetach = $cmd.ExecuteReader()
            Write-Verbose "Detached"
            $rdrDetach | Out-String | Write-Verbose

        }

        Write-Verbose "Closing WID connection"

        If ($conn.State -eq "Open") {

            $conn.Close()

        }

        Write-Verbose "Moving database files from $sourcePath to $DestinationPath"
        $mdf = Join-Path -path $SourcePath -ChildPath "RaAcctDb.mdf"
        $ldf = Join-Path -path $SourcePath -ChildPath "RaAcctDb_log.ldf"
        Move-Item -Path $mdf -Destination $DestinationPath
        Move-Item -Path $ldf -Destination $DestinationPath

        Write-Verbose "Creating new database"
        $sqlConn = 'server=\\.\pipe\Microsoft##WID\tsql\query;Database=;Trusted_Connection=True;'
        $conn = New-Object System.Data.SQLClient.SQLConnection($sqlConn)
        Write-Verbose "Opening WID connection"

        If ($pscmdlet.ShouldProcess("New DB", "Open Connection")) {

            $conn.Open()

        }

        $cmd = $conn.CreateCommand()
        $targetmdf = Join-Path -Path $DestinationPath -ChildPath RaAcctDb.mdf
        $targetldf = Join-Path -Path $DestinationPath -ChildPath RaAcctDb_log.ldf
        $cmdText = "USE master CREATE DATABASE RaAcctDb ON (FILENAME = '$targetmdf'),(FILENAME = '$targetldf') FOR ATTACH;USE [master] ALTER DATABASE [RaAcctDb] SET READ_WRITE WITH NO_WAIT;"
        Write-Verbose $cmdText
        $cmd.CommandText = $cmdText
        
        If ($pscmdlet.ShouldProcess($targetmdf, "CREATE DATABASE")) {

            Write-Verbose "Executing"
            $rdrAttach = $cmd.ExecuteReader()
            Write-Verbose "Attached"
            $rdrAttach | Out-String | Write-Verbose

        }

        Write-Verbose "Closing WID connection"

        If ($conn.State -eq "Open") {

            $conn.Close()

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

The RaAcctDB database and log files have been relocated to $DestinationPath

Moved by $env:USERDOMAIN\$env:USERNAME at $(Get-Date)

"@

            Set-Content -Path C:\Windows\DirectAccess\DB\Readme.txt -Value $txt

        }

        ElseIf ($DestinationPath -eq "C:\Windows\DirectAccess\DB" -AND (Test-Path -path "C:\Windows\DirectAccess\DB\readme.txt") ) {

            #// If the destination is the default location and the readme file exists, delete the file.
            Remove-Item -Path "C:\Windows\DirectAccess\DB\readme.txt"

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

        Write-Verbose "Adding an alternate credential for $($pscredential.username)"
        $icmParams.Add("Credential", $PSCredential)

    }

    If ($UseSSL) {

        Write-Verbose "Using SSL"
        $icmParams.Add("UseSSL", $True)

    }

    Write-Verbose "Using $Authentication authentication."

} # // Begin

Process {

    foreach ($computer in $computername) {

        Write-Verbose "Querying $($computer.toUpper())"
        $icmParams.Computername = $computer
        $icmParams | Out-String | Write-verbose
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
# MIINbAYJKoZIhvcNAQcCoIINXTCCDVkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUP3K58GO5nH/h11I532jky+QU
# x7mgggquMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
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
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPWqD5fgdXS6gokUVtBqvJNf/3p8MA0G
# CSqGSIb3DQEBAQUABIIBACih9f2ZQBGdKcCA2ckDauCboBvEee0ykLhSgx0D7LnW
# 8mA20SJl12Kk0R/Guz1JGOxUnpwe2i8HK59xYd8s4sp1xjerWnHQluXWmvJ2NFAb
# 7G5YZgKNr71zk7osHC2GUrm6yNf3PHYrfTnd/Cibp4XmvILTyxPsoKqovJfw7pgO
# 0+4xewtZm4uhclpZUy0RR3N7WjMMVq7CTFXLErr4aRZIaoa05NVgQeXhqnTx/URL
# HfKm/fFxQ4BwOrNtzOPp4ZCzttWfLofKxCTzmXWaa6ZZu6J8gM3dWoF8VBV9+L+O
# cZm6XQk7CyAD0sJDksOKH9JSC18zR4jxzZj6XGXnniY=
# SIG # End signature block
