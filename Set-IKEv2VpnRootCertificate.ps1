Function Set-IKEv2VpnRootCertificate {

    [cmdletbinding(SupportsShouldProcess)]
    [Outputtype("None", "Microsoft.Management.Infrastructure.CimInstance#VpnAuthProtocol")]

    Param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, HelpMessage = "Enter the name of the remote RRAS server.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Computername = $env:computername,
        [Parameter(Position = 1, Mandatory, HelpMessage = "Enter the  root certificate thumbprint to use for the VPN connection. This should be a certificate found in CERT:\LocalMachine\Root.", ValueFromPipelineByPropertyName)]
        [ValidateNotNullorEmpty()]
        #The hash value must be 40 characters long
        [ValidateScript( {$_.length -eq 40})]
        [alias("hash")]
        [string]$Thumbprint,
        [switch]$Restart,
        [Parameter(HelpMessage = "Enter an optional credential in the form domain\username or machine\username")]
        [PSCredential]$Credential,
        [ValidateSet('Default', 'Basic', 'Credssp', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
        [ValidateNotNullorEmpty()]
        [string]$Authentication = "default",
        [switch]$UseSSL,
        [switch]$Passthru
    )

    Begin {
        Write-Verbose "Starting $($myinvocation.mycommand)"

        #display some meta information for troubleshooting
        Write-Verbose "PowerShell version: $($psversiontable.psversion)"
        Write-Verbose "Operating System: $((Get-Ciminstance -class win32_operatingsystem -property caption).caption)"
        
        $sb = {

            Param([string]$Thumbprint, [bool]$Restart, [bool]$Passthru)

            Try {
                $VerbosePreference = $using:verbosepreference
            }
            catch {
                Write-Verbose "Using local Verbose preference"
            }
            Try {
                $whatifpreference = $using:whatifpreference
            }
            Catch {
                Write-Verbose "Using local Whatif preference"
            }

            Write-Verbose "WhatIf = $whatifpreference"
            Write-verbose "Verbose = $VerbosePreference"
            Write-Verbose "Retrieving certificate with a thumbprint of $Thumbprint"
            $RootCACert = (Get-ChildItem -Path cert:\LocalMachine\root | Where-Object {$_.Thumbprint -eq $Thumbprint})
            if ($RootCACert) {
                Write-Verbose "Setting IKEv2 root certificate using certificate thumbprint $thumbprint."
                $setParams = @{
                    RootCertificateNameToAccept = $RootCACert
                    Passthru                    = $Passthru
                    ErrorAction                 = "Stop"
                }
                $setParams | Out-String | Write-Verbose
                Try {
                    Set-VpnAuthProtocol @setParams
                }
                Catch {
                    Write-Warning "Set-VpnAuthProtocol failed. $($_.exception.message)"
                }
            }
            else {
                Write-Warning "Failed to find a certificate with a thumbprint of $thumbprint."
                #bail out of the command
                Return
            }
            if ($Restart -AND (-Not $whatifpreference)) {
                Write-Verbose "Restarting RemoteAccess service on $env:Computername"
                Restart-Service -name RemoteAccess -force -PassThru:$Passthru
            }
            else {
                $msg = @"

You must restart the RemoteAccess service before any changes take effect.

PS C:\> Get-Service RemoteAccess -computername $env:computername | Restart-Service -force

Or use PowerShell Remoting:

PS C:\> invoke-command {Restart-Service RemoteAccess -force} -computername $env:computername

"@
                Write-Warning $msg
            }

        } #close scriptblock

        #define a set of parameter values to splat to Invoke-Command
        $icmParams = @{
            Scriptblock  = $sb
            ArgumentList = ""
            ErrorAction  = "Stop"
        }

    } #Begin

    Process {

        foreach ($computer in $computername) {

            $icmParams.ArgumentList = @($Thumbprint, $restart, $passthru)
            #only use -Computername if querying a remote computer
            if ($Computername -ne $env:computername) {
                Write-Verbose "Using remote parameters"
                $icmParams.Computername = $computer
                $icmParams.HideComputername = $True
                $icmParams.Authentication = $Authentication

                if ($pscredential.username) {
                    Write-Verbose "Adding an alternate credential for $($pscredential.username)"
                    $icmParams.Add("Credential", $PSCredential)
                }
                if ($UseSSL) {
                    Write-Verbose "Using SSL"
                    $icmParams.Add("UseSSL", $True)
                }
                Write-Verbose "Using $Authentication authentication."
            }
            $icmParams | Out-String | Write-verbose

            Write-Verbose "Modifying $($computer.toUpper())"
            Try {
                #display result without the runspace ID
                Invoke-Command @icmParams | Select-Object -Property * -ExcludeProperty RunspaceID,*PSComputer*
            }
            Catch {
                Throw $_
            }
        } #foreeach
    } #process

    End {
        Write-Verbose "Ending $($myinvocation.MyCommand)"
    }
} #end function