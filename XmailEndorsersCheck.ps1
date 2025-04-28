# removing variables - mandatory when using Powershell ISE to run script many times in the same session
Remove-Variable -Name SqlData, SqlTable, Item, Endorsers -ErrorAction SilentlyContinue

$SqlHost = "btsevcipssql01.se.ad.banctec.com"
$SqlHostDb = "internportal"
$SqlHostLogin = "GENERIC_DB_ReadOnly_SQL"
$SqlHostPass = "ZMwTuUFa7c"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$ScriptPath = "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\XmailInputToMailroom"
$Endorsers = Get-Content "$ScriptPath\input.txt" | Where-Object { $_.trim() -ne "" }
$SqlQueryTemplate = "
    use internportal
    SELECT
    Endorser,
    DCN,
    BatchName,
    Timestamp,
    d.Status,
    Customer,
    ProdDate,
    Source
    FROM [internportal].[Stats].[BatchDocumentStats] d right join [internportal].[Stats].[BatchStats] b on b.id = d.batchid
    where
    Endorser like "

Write-Host Checking Endorsers...

$SqlData = foreach ($Item in $Endorsers) {
    $SqlTable = Invoke-Sqlcmd -ServerInstance $SqlHost -Database $SqlHostDb -Query $SqlQueryTemplate"`'$Item`%`'" -Username $SqlHostLogin -Password $SqlHostPass

    [PSCustomObject]@{
        XmailEndorser = $Item
        DCN           = $SqlTable.DCN
        BatchName     = $SqlTable.BatchName
        TimeStamp     = $SqlTable.TimeStamp
        Status        = $SqlTable.Status
        Customer      = $SqlTable.Customer
        ProdDate      = $SqlTable.ProdDate
        Source        = $SqlTable.Source
    }
}

Write-Host Exporting to csv...
Start-Sleep -s 1
$SqlReport = "$ScriptPath\output\$Timestamp.csv"
$SqlData | Export-Csv $SqlReport -NoTypeInformation

Write-Host "Report has been exported to $SqlReport file"
Invoke-Item $SqlReport

if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}