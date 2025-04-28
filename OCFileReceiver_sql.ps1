Write-Host "Processing..."
# $toDate = get-date -DisplayHint date
# $fromDate = (get-date).AddDays(-3).ToString("yyyy-MM-dd")
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"
$log_catalog = "\\btsevlev01.se.ad.banctec.com\Logs\OCFileReceiver"
$main_catalog = "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\OCFileReceiver"
$logfile = Get-ChildItem $log_catalog -filter *error* | ForEach-Object { Get-Content $_.FullName }
Write-Host 'Importing data from log file...'
# $logfile = Get-Content C:\Temp\service.error.log
$emailRegex = [regex] 'emailreceiving-invoice_\d{2}_[A-Z0-9]{32}siP\d{1}.zip|externalscanning-invoice_\d{2}_[A-Z0-9]{32}siP\d{1}.zip'

$logfile_checked = $emailRegex.Matches($logfile) | Select-Object Value -Unique
# $emailRegex.Matches($pliczek) | Select-Object Value -Unique | Out-File c:\temp\ddd.txt

$logfile_array = @()
foreach ($emailbatch in $logfile_checked) {
    $logfile_array += $emailbatch.value

}

$processed = @(Get-Content "$main_catalog\processed.txt")
$processed_count = $processed.Count
Write-Host "There are $processed_count files already checked"
Start-Sleep -s 1

$emailbatch_list = $logfile_array | Where-Object { $_ -notin $processed }
$emailbatch_list_count = $emailbatch_list.Count
Start-Sleep -s 2

if ($emailbatch_list_count -eq 0) {
    Write-Host 'No new batches found to be checked'
}
elseif ($emailbatch_list_count -eq 1) {
    Write-Host "Found $emailbatch_list_count new batch to be checked"
}
else {
    Write-Host "Found $emailbatch_list_count new batches to be checked "
}


$issue_array = @()
# $issue = Get-Content "$main_catalog\issue.txt"
Write-Host 'Checking the files...'
foreach ($item in $emailbatch_list) {
    
    $Query = "
    use internportal
    SELECT
    --SourceFile,
    count(SourceFile) as Count
      FROM [internportal].[Stats].[OCFileReceiver] br
      where 
      Direction like 'IN'
      and status like 'OK'
      and br.DestinatinFile not like '%.error'
      and SourceFile like '%$item%'
      --and DestinatinFile like '%.tiff'
     group by SourceFile
    "
    # $numerek = $item.IndexOf("_") -as [int32]
    # $count_docs = $item.Substring(23, 2) -as [int32]
    $count_docs = $item.Substring($item.IndexOf("_") + 1, 2) -as [int32]
    # $item.Value.Substring(23,2) -as [int32]
    $baza = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query
    $baza2 = ($baza.Count -as [int32]) / 2
    $test = $count_docs * 2 -eq $baza.Count

    # $test2 = $emailbatch_list.Contains($item)

    # e={if($dokumenty -eq $baza) {Write-Host 'OK'}Else {Write-Host 'Not OK'}}
    if ($test) {
        $item | Out-File -Append "$main_catalog\processed.txt"

    }
    Else {
        $issue_array += $item
    }

    $item | Select-Object @{n = "EmailBatch"; e = { $_ } }, @{n = "Documents"; e = { $count_docs } }, @{n = "Database"; e = { $baza2 } }, @{n = "Status"; e = { $test } }

}
$issue_array | Out-File "$main_catalog\issue.txt"

if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}