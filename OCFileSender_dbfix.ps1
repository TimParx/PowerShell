Import-Module SqlServer
#clearing variables
Remove-Variable -Name server, Database, password, zapytanie -ErrorAction SilentlyContinue
Remove-Variable -name query, date, batchName, deliveryID, query_exec, row  -ErrorAction SilentlyContinue

#setting sql server
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"

$zapytanie = "
use internportal
declare @fromDate as DATE, @toDate as DATE;
------date----------------
set @fromDate = DATEADD(DAY, -90, GETDATE());
set @toDate = DATEADD(DAY, -1, GETDATE());
--------------------------
select 
convert(varchar, TimeStamp, 112) as TimeStamp,
dbo.getFilename(DestinationFile) as BatchName,
fh.DeliveryRunID
--os.Filename,
--os.Status

from ftpBatManager_FileHistory fh with(nolock) 
	LEFT JOIN [internportal].[Stats].[OCFileSender] os on dbo.getFilename(DestinationFile) = dbo.getFilename(Filename)
	where
		Action like '%UPLOAD%'
		and JobName like '%OCFileDelivery%'
		and cast(TimeStamp AS date) BETWEEN @fromDate AND @todate
		and DestinationFile LIKE '%.zip%' 
		and os.Status is NULL
"
$query = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $zapytanie

foreach ($row in $query) {
    $date = $row.TimeStamp
    $batchName = $row.BatchName
    $deliveryID = $row.DeliveryRunID
    $query_exec = "
    exec [stats].[AddOCFile]
    @DestinationFile='\\btsevlev01.se.ad.banctec.com\save\OCFileDelivery\save\$date\$batchName',
    @DeliveryRunId='$deliveryID'"
    $batchName
    # Write-host $query_exec
    Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $query_exec
}
   