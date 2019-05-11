# // enable IKEv2 server fragmentation for Windows Server RRAS

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\Ikev2\" -Name EnableServerFragmentation -PropertyType DWORD -Value 1 -Force