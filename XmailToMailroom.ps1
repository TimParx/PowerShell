#clearing variables
Remove-Variable -Name baza_array, data, server, Database, main_catalog, input, question, query, query2, file, export_file, username_db, pwd_db -ErrorAction SilentlyContinue

#setting sql server
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"
$username_db = "GENERIC_DB_ReadOnly_SQL"
$pwd_db = "bZKD19+2=4!!"

$main_catalog = "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\XmailInputToMailroom"
$input_list = Get-Content "$main_catalog\input.txt" | Where-Object { $_.trim() -ne "" }

$time_stamp = Get-Date -Format "yyyy-MM-dd_HH.mm"

Write-Host Database searching...

$data = foreach ($file in $input_list) {
        
    $query = "

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
    --Count(*) as Documents
    FROM [internportal].[Stats].[BatchDocumentStats] d right join [internportal].[Stats].[BatchStats] b on b.id = d.batchid
    where
    --(d.status = 'SENT TO FF' or d.status <> 'SCN CREATED')
    --Timestamp between @fromDate and DateAdd(D, 1, @toDate)
    --and Timestamp > '2019-08-28 00:00:00'
    --and Customer like 'OCS%'
     Endorser like '%$file%'
        "
        
    $baza = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query -Username $username_db -Password $pwd_db
    # $baza_array += $baza

    [PSCustomObject]@{
        XmailEndorser = $file
        DCN           = $baza.DCN
        BatchName     = $baza.BatchName
        TimeStamp     = $baza.TimeStamp
        Status        = $baza.d.Status
        Customer      = $baza.Customer
        ProdDate      = $baza.ProdDate
        Source        = $baza.Source
    }
    
}

Write-Host Exporting to csv...
Start-Sleep -s 1
$export_file = "$main_catalog\output\$time_stamp.csv"
$data | Export-Csv $export_file -NoTypeInformation

Write-Host "Data has been exported to $export_file file"
Invoke-Item $export_file

if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}