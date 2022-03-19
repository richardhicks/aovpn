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
    Version:        1.21
    Creation Date:  August 23, 2020
    Last Updated:   September 23, 2021
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

# // Escape spaces in profile name
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'

# // OMA URI information
$NodeCSPURI = './Vendor/MSFT/VPNv2'
$NamespaceName = 'root\cimv2\mdm\dmmap'
$ClassName = 'MDM_VPNv2_01'

If ($AllUserConnection) {

    # // Script must be running in the context of the SYSTEM account. Validate user, exit if not running as SYSTEM
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    If ($CurrentPrincipal.Identities.IsSystem -ne $true) {

        Write-Warning 'This script is not running in the SYSTEM context, as required. Exiting script.'
        Exit

    }

}

If (!$CleanUpOnly) {  
    # // Remove VPN profile-
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

    Try {
        $Session = New-CimSession

        If (!$AllUserConnection -and !$DeviceTunnel) {
            $deleteInstances = $session.EnumerateInstances($namespaceName, $className, $options)
        } else {
            $deleteInstances = $session.EnumerateInstances($namespaceName, $className)
        }  
        foreach ($deleteInstance in $deleteInstances)
        {
            $InstanceId = $deleteInstance.InstanceID
            if ("$InstanceId" -eq "$ProfileNameEscaped")
            {
                $session.DeleteInstance($namespaceName, $deleteInstance, $options)
                Write-Verbose "Removing VPN connection ""$ProfileName"" profile ""$InstanceId"" ..."
            } else {
                Write-Verbose "Ignoring existing VPN profile $InstanceId"
            }
        }
    }
    catch [Exception]
    {
        Write-Warning "$_"
        $Message = "Unable to remove existing outdated instance(s) of $ProfileName profile"
        Write-Host "$Message"
        exit
    }
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

# // Remove registry artifacts from RasMan\Config
$Path = 'HKLM:\System\CurrentControlSet\Services\RasMan\Config\'
$Name = 'AutoTriggerDisabledProfilesList'

Write-Verbose "Searching $Name under $Path for VPN profile called ""$ProfileName""..."

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

        Write-Verbose "Profile found. Removing entry..."
        $List.Remove($ProfileName)
        Write-Verbose "Updating the registry..."
        Set-ItemProperty -Path $Path -Name $Name -Value $List.Values

    }
   
}

Else {

    Write-Verbose "No profiles found matching ""$ProfileName""."

}
