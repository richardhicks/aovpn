<#

.SYNOPSIS
    Optimizes TLS configuration for SSTP VPN connections.

.PARAMETER Performance
    TLS cipher suites optimized for performance. AES-256 ciphers removed.

.PARAMETER Security
    TLS cipher suites optimized for security. AES-256 ciphers are included.

.EXAMPLE
    .\Optimize-VpnTlsConfiguration.ps1

    Running this command will optimize TLS configuration for performance. Cipher suites using AES-256 are not included in this configuration.

.EXAMPLE
    .\Optimize-VpnTlsConfiguration.ps1 -Performance

    Running this command will optimize TLS configuration for performance. Cipher suites using AES-256 are not included in this configuration.

.EXAMPLE
    .\Optimize-VpnTlsConfiguration.ps1 -Security

    Running this command will optimize TLS configuration for security. Cipher suites using AES-256 are included and preferred over AES-128 ciphers.

.DESCRIPTION
    Use this script to optimize TLS configuration to improve security and performance for SSTP VPN connections. TLS cipher suites are configured and optimized, TLS 1.0 and TLS 1.1 are disabled, and support for RC4 ciphers is disabled.

.LINK
    https://directaccess.richardhicks.com/

.NOTES
    Version:        1.1
    Creation Date:  October 24, 2019
    Last Updated:   November 25, 2019
    Author:         Richard Hicks
    Organization:   Richard M. Hicks Consulting, Inc.
    Contact:        rich@richardhicks.com
    Web Site:       www.richardhicks.com

#>

[CmdletBinding()]

Param (

    [switch]$Security,
    [switch]$Performance = [switch]::Present

)

# Override default performance configuration is highest level of security is required
If ($Security) {

    $Performance = $false

}

# Determine OS version
$OSVersion = (Get-CimInstance 'Win32_OperatingSystem').Version
Write-Verbose "OS Version is $OSVersion."

# Windows Server 2012/R2
If ($OSVersion -Like '6.*') {

    Write-Verbose 'Detected Windows Server 2012 or 2012R2.'

    If ($Performance) {
        
        Write-Verbose 'Using performance optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256,TLS_RSA_WITH_AES_128_GCM_SHA256'

    }

    If ($Security) {
        
        Write-Verbose 'Using security optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256'

    }

}

# Windows Server 2016 or SAC release
If ($OSVersion -Like '*14393*' -or $OSVersion -Like '*17134 *') {

    Write-Verbose 'Detected Windows Server 2016 or SAC release.'

    If ($Performance) {

        Write-Verbose 'Using performance optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'
    
    }

    If ($Security) {

        Write-Verbose 'Using security optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'

    }

}

# Windows Server 2019, Windows Server 1809, 1903, or 1909
If ($OSVersion -Like '*17763*' -or $OSVersion -Like '*17763*' -or $OSVersion -Like '*18362*' -or $OSVersion -Like '*18363*') {

    Write-Verbose 'Detected Windows Server 2019 or SAC release.'
    
    If ($Performance) {
    
        Write-Verbose 'Using performance optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'
    
    }

    If ($Security) {

        Write-Verbose 'Using security optimized TLS configuration.'
        $CipherSuiteOrder = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'
    
    }

}

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002\'
    Name         = 'Functions'
    PropertyType = 'String'
    Value        = $CipherSuiteOrder

}

# Update registry settings
Write-Verbose 'Updating TLS cipher suite configuration...'
New-ItemProperty @Parameters -Force

# Disable TLS 1.1
Write-Verbose 'Disabling TLS 1.1...'

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Disable TLS 1.0
Write-Verbose 'Disabling TLS 1.0...'

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Disable SSL 3.0
Write-Verbose 'Disabling SSL 3.0...'

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

# Create registry key
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server\' -Force

# Define registry parameters
$Parameters = @{

    Path         = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server\'
    Name         = 'Enabled'
    PropertyType = 'DWORD'
    Value        = '0'

}

# Update registry settings
New-ItemProperty @Parameters -Force

#  Disable RC4 ciphers
Write-Verbose 'Disable RC4 ciphers...'

$Writeable = $true
$Key = (Get-Item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $Writeable).CreateSubKey('RC4 128/128')
$Key.SetValue('Enabled', '0', 'DWORD')

$Key = (Get-Item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $Writeable).CreateSubKey('RC4 56/128')
$Key.SetValue('Enabled', '0', 'DWORD')

$Key = (Get-Item HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\).OpenSubKey('Ciphers', $Writeable).CreateSubKey('RC4 40/128')
$Key.SetValue('Enabled', '0', 'DWORD')

Write-Verbose 'Script complete.'
Write-Warning 'The server must be restarted for these changes to take effect.'
