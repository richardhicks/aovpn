<#

.SYNOPSIS
    Optimizes the DirectAccess/Routing and Remote Access Service (RRAS) inbox accounting database.

.EXAMPLE
    .\Optimize-InboxAccountingDatabase.ps1

.DESCRIPTION
    The DirectAccess/RRAS inbox accounting database is missing a crucial index on one of the tables in the database. This can cause high CPU utilization for very busy DirectAccess/RRAS VPN servers. Running this script will add the missing index and improve performance.

.LINK
    https://technet.microsoft.com/en-us/library/mt693376(v=ws.11).aspx

.NOTES
    Version:         1.1
    Creation Date:   December 15, 2019
    Last Updated:    December 18, 2019
    Special Note:    This script adapted from published guidance provided by Microsoft.
    Original Author: Microsoft Corporation
    Original Script: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/mt693376(v=ws.11)
    Author:          Richard Hicks
    Organization:    Richard M. Hicks Consulting, Inc.
    Contact:         rich@richardhicks.com
    Web Site:        www.richardhicks.com

#>

[CmdletBinding()]

Param(

)

# Validate DirectAccess or VPN role is installed - exit script if neither is present
If ((Get-RemoteAccess | Select-Object -ExpandProperty DAStatus) -eq 'Uninstalled' -and (Get-RemoteAccess | Select-Object -ExpandProperty VpnStatus) -eq 'Uninstalled') {

    Write-Warning 'The DirectAccess or VPN role is not installed on this server. Exiting script.'
    Exit    

}

# Verify missing table index
Write-Verbose 'Confirming missing table index on inbox accounting database. 0 = missing, 1 = present.'
$Connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$Connection.ConnectionString = 'Server=np:\\.\pipe\Microsoft##WID\tsql\query;Database=RaAcctDb;Trusted_Connection=True;'
$Command = $Connection.CreateCommand()
$Command.CommandText = "SELECT name from sys.indexes where name like 'IdxSessionTblState'"
$Adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $Command
$Dataset = New-Object -TypeName System.Data.DataSet
$Adapter.Fill($DataSet)
$Connection.Close()

If ($DataSet.Tables[0].Name -eq 'IdxSessionTblState') {

    Write-Warning 'Remote Access inbox accounting database already optimized. Exiting script.'
    Exit 

}
 
# Optimize inbox accounting database
Write-Verbose 'Optimizing inbox accounting database...'
$Connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$Connection.ConnectionString = 'Server=np:\\.\pipe\Microsoft##WID\tsql\query;Database=RaAcctDb;Trusted_Connection=True;'
$Command = $Connection.CreateCommand()
$Command.CommandText = "CREATE INDEX IdxSessionTblState ON [RaAcctDb].[dbo].[SessionTable] ([SessionState]) INCLUDE ([ConnectionId])"
$Connection.Open()
$Command.ExecuteNonQuery()
$Connection.Close()

Write-Output 'Inbox accounting database optimization complete.'
