# // Enable IKEv2 fragmentation suport for Windows Routing and Remote Access Service (RRAS)
# // Requires Windows Server 2019 (does not work with Windows Server 2016 or Windows Server 2012/R2)

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\Ikev2\" -Name EnableServerFragmentation -PropertyType DWORD -Value 1 -Force
