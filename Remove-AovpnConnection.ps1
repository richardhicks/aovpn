<#

.SYNOPSIS
    PowerShell script to remove Always On VPN connections.

.PARAMETER ProfileName
    Specifies the name of the VPN connection to remove.

.PARAMETER AllUserConnection
    Use this parameter when the VPN profile is a device tunnel, or a user tunnel provisioned for all users.

.PARAMETER CleanUpOnly
    Use this switch to perform registry clean up for a VPN connection that was previously removed.

.PARAMETER RemoveFromRasphone
    Use this switch to remove a VPN connection from rasphone.pbk. Will try this automatically if WMI method failed.

.PARAMETER RasphonePath
    Specifies the path to the rasphone.pbk file. This parameter may be required when running this script using SCCM or other systems management tools that deploy software to the user but run in the SYSTEM context.

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
    https://github.com/richardhicks/aovpn/blob/master/Remove-AovpnConnection.ps1

.LINK
    https://directaccess.richardhicks.com/2020/08/24/removing-always-on-vpn-connections/

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        3.0
    Creation Date:  August 23, 2020
    Last Updated:   August 11, 2022
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       https://www.richardhicks.com/

#>

[CmdletBinding(SupportsShouldProcess)]

Param (

    [Parameter(Mandatory, HelpMessage = 'Enter the name of the VPN profile to remove.')]
    [ValidateNotNullOrEmpty()]
    [Alias("Name", "ConnectionName")]
    [string]$ProfileName,
    [Alias("DeviceTunnel")]
    [switch]$AllUserConnection,
    [switch]$RemoveFromRasphone,
    [string]$RasphonePath,
    [switch]$CleanUpOnly

)

# // Escape spaces in profile name
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'

# // OMA URI information
$NamespaceName = 'root\cimv2\mdm\dmmap'
$ClassName = 'MDM_VPNv2_01'

$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

If ($AllUserConnection) {

    # // Script must be running in the context of the SYSTEM account. Validate user, exit if not running as SYSTEM
    If ($CurrentPrincipal.Identities.IsSystem -ne $True) {

        Write-Warning 'This script is not running in the SYSTEM context, as required.'
        Return

    }

}

# // Function to remove profile from rasphone.pbk 
Function Remove-RASPhoneBook {

    [CmdletBinding(SupportsShouldProcess)]

    Param (

        [string]$Path,
        [string]$ProfileName

    )

    $pattern = "(\[.*\])"
    $c = Get-Content $path -Raw
    $p = [System.Text.RegularExpressions.Regex]::Split($c, $pattern, "IgnoreCase") | Where-Object { $_ }

    # // Create a hashtable of VPN profiles
    Write-Verbose "Initializing a hashtable for VPN profiles from $path..."
    $profHash = [ordered]@{}

    For ($i = 0; $i -lt $p.count; $i += 2) {

        Write-Verbose "Adding $($p[$i]) to VPN profile hashtable..."
        $profhash.Add($p[$i], $p[$i + 1])

    }

    # // An array to hold changed values for -Passthru
    $pass = @()

    Write-Verbose "Found the following VPN profiles: $($profhash.keys -join ',')."

    $compare = "[$Profilename]"
    
    Write-Verbose "Searching for VPN profile $compare..."
    # // Need to make sure to get the exact profile
    $SelectedProfile = $profHash.GetEnumerator() | Where-Object { $_.name -eq $compare }

    If ($SelectedProfile) {

        Write-Verbose "Removing $($SelectedProfile.key)"
        $profHash.Remove($SelectedProfile.key)
        $ChangeMade = $True

    } #If found

    Else {

        Write-Warning "VPN Profile [$profilename] not found."

    }

    # // Only update the file if changes were made
    If (($ChangeMade) -AND ($pscmdlet.ShouldProcess($path, "Update RAS PhoneBook"))) {

        Write-Verbose "Updating $Path"
        $output = $profHash.Keys | ForEach-Object { $_ ; ($profhash[$_] | Out-String).trim(); "`n" }
        $output | Out-File -FilePath $Path -Encoding ascii

    } #Whatif

} #close function

If (!$CleanUpOnly) {

    # // Search for and remove matching VPN profile
    Try {

        $Session = New-CimSession

        If (!$AllUserConnection -and ($CurrentPrincipal.Identities.IsSystem -eq $True)) {

            $UserName = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName

            If ($Null -eq $UserName) {

                Write-Warning "User not found. Ensure user is logged on to the console and not connected via RDP or Enhanced Session in Hyper-V."
                Return

            }

            $User = New-Object System.Security.Principal.NTAccount($UserName.UserName)
            $Sid = $User.Translate([System.Security.Principal.SecurityIdentifier])
            $SidValue = $Sid.Value
            Write-Verbose "User SID is $SidValue."

            $Options = New-Object Microsoft.Management.Infrastructure.Options.CimOperationOptions
            $Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Type', 'PolicyPlatform_UserContext', $False)
            $Options.SetCustomOption('PolicyPlatformContext_PrincipalContext_Id', "$SidValue", $False)

            $DeleteInstances = $Session.EnumerateInstances($NamespaceName, $ClassName, $Options)

        }

        Else {

            $DeleteInstances = $Session.EnumerateInstances($NamespaceName, $ClassName)

        }

        Write-Verbose "Searching for VPN profile ""$ProfileName""..."

        ForEach ($DeleteInstance in $DeleteInstances) {

            $InstanceId = $DeleteInstance.InstanceID

            If ("$InstanceId" -eq "$ProfileNameEscaped") {

                Write-Verbose "Removing VPN connection ""$ProfileName""..."
                $Session.DeleteInstance($NamespaceName, $DeleteInstance, $Options)
                $ProfileRemoved = $True

            }

            Else {

                Write-Verbose "Ignoring existing VPN profile ""$InstanceId""..."

            }

        }

    }

    Catch [Exception] {

        Write-Warning "$_"
        Write-Warning "Unable to remove VPN profile from WMI ""$ProfileName""."
        $RemoveFromRasphone = $True;  

    }
    
    If ($RemoveFromRasphone) {
        Try {

            # // Define rasphone.pbk file path
            If (-Not $RasphonePath -and $AllUserConnection) {

                $RasphonePath = 'C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk'
                $RasphoneBackupPath = Join-Path 'C:\ProgramData\Microsoft\Network\Connections\Pbk\' -ChildPath "rasphone_$(Get-Date -Format FileDateTime).bak"

            }

            ElseIf (-Not $RasphonePath) {

                $RasphonePath = "$env:appdata\Microsoft\Network\Connections\Pbk\rasphone.pbk"
                $RasphoneBackupPath = Join-Path "$env:appdata\Microsoft\Network\Connections\Pbk\" -ChildPath "rasphone_$(Get-Date -Format FileDateTime).bak"

            }

            # // Ensure that rasphone.pbk exists
            If (!(Test-Path $RasphonePath)) {

                Write-Warning "The file $RasphonePath does not exist. Exiting script."
                Exit

            }

            # // Create backup of rasphone.pbk
            Write-Verbose "Backing up existing rasphone.pbk file to $RasphoneBackupPath..."
            Copy-Item $RasphonePath $RasphoneBackupPath
    
            Remove-RASPhoneBook -Path $RasphonePath -ProfileName $ProfileName 

            $ProfileRemoved = $True

        }   
        Catch [Exception] {

            Write-Warning "$_"
            Write-Warning "Unable to remove VPN profile from rasphone.pbk ""$ProfileName""."

        } 
    }

}

If ($ProfileRemoved -or $CleanUpOnly) {

    # // Registry clean-up
    Write-Verbose "Cleaning up registry artifacts for VPN connection ""$ProfileName""..."

    # // Remove registry artifacts from ERM\Tracked
    Write-Verbose "Searching ERM\Tracked for profile ""$ProfileNameEscaped""..."

    $BasePath = "HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked"
    $Tracked = Get-ChildItem -Path $BasePath

    ForEach ($Item in $Tracked) {

        Write-Verbose "Processing $(Convert-Path $Item.PsPath)..."
        $Key = Get-ChildItem $Item.PsPath -Recurse | Where-Object { $_ | Get-ItemProperty -Include "Path*" }
        $PathCount = ($Key.Property -Match "Path\d+").Count
        Write-Verbose "Found a total of $PathCount ERM\Tracked entries."

        # // There may be more than 1 matching key
        ForEach ($K in $Key) {

            $Path = $K.Property | Where-Object { $_ -Match "Path\d+" }
            $Count = $Path.Count
            Write-Verbose "Found $Count entries under $($K.Name)."

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

    # // Remove registry artifacts from RasMan\Config
    $Path = 'HKLM:\System\CurrentControlSet\Services\RasMan\Config\'
    $Name = 'AutoTriggerDisabledProfilesList'

    Write-Verbose "Searching $Name under $Path for VPN profile ""$ProfileName""..."

    Try {

        # // Get the current registry values as an array of strings
        [string[]]$Current = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop

    }

    Catch {

        Write-Verbose "$Name does not exist under $Path. No action required."

    }

    If ($Current) {

        #// Create ordered hashtable
        $List = [Ordered]@{}
        $Current | ForEach-Object { $List.Add("$($_.ToLower())", $_) }

        # //Search hashtable for matching VPN profile and remove if present
        If ($List.Contains($ProfileName)) {

            Write-Verbose "Profile found in AutoTriggerDisabledProfilesList. Removing entry..."
            $List.Remove($ProfileName)
            Write-Verbose "Updating the registry..."
            Set-ItemProperty -Path $Path -Name $Name -Value $List.Values

        }

    }

    Else {

        Write-Verbose "No profiles found matching ""$ProfileName"" in the AutoTriggerDisabledProfilesList registry key."

    }

}

Else {

    Write-Verbose "VPN profile ""$ProfileName"" not found."

}
