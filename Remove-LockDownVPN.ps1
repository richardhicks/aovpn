# // Remove LockDown VPN Connection
# // This script MUST be run in the context of the SYSTEM account using the Systinternals tool psexec.exe which can be downloaded here - https://rmhci.co/2D0zEIG.
# // syntax example - .\psexec.exe -i -s C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe

$Namespace = "root\cimv2\mdm\dmmap"
$ClassName = "MDM_VPNv2_01"

$obj = Get-CimInstance -Namespace $Namespace -ClassName $ClassName

If ($obj -eq $null) {
    Write-Output "LockDown VPN connection not found."
}
Else {
    Write-Output "Removing LockDown VPN Connection..."
    Remove-CimInstance -CimInstance $obj
}
