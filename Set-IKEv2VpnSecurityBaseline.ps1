# // Configure IKEv2 VPN baseline security on Windows Server Routing and Remote Access (RRAS) servers

Set-VpnServerConfiguration -RevertToDefault | Out-Null
Set-VpnServerConfiguration -CustomPolicy -AuthenticationTransformConstants SHA256128 -CipherTransformConstants AES128 -DHGroup Group14 -EncryptionMethod AES128 -IntegrityCheckMethod SHA256 -PFSgroup PFS2048 -SALifeTimeSeconds 28800 -SADataSizeForRenegotiationKilobytes 102400
Restart-Service RemoteAccess -PassThru
