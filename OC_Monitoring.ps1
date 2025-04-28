Import-Module SqlServer
#clearing variables
Remove-Variable -Name server, Database, ReceivedEmails_query, SentToProduction_query, ReceivedFromFF_query, SentToOC_query, Confirmations_query, Confirmations_query_received, SentToOC_batches_query -ErrorAction SilentlyContinue
Remove-Variable -name n, query1_array1, query2_array, query3_array, query4_array, query5_array, query1, query2, query3, query4, query5, godzina, query6, query7, query6_array, query7_array -ErrorAction SilentlyContinue
Remove-Variable -Name MyObject, MyObject2 -ErrorAction SilentlyContinue


#setting sql server
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"

$ReceivedEmails_query = "
use internportal

declare @fromDate as DATE, @toDate as DATE;
set @fromDate = GETDATE();
set @toDate = GETDATE();

SELECT 
  COUNT(Distinct SourceFile) as ReceivedEmails
   --SourceFile
  FROM [internportal].[Stats].[OCFileReceiver]
  where 
  DateReceived between @fromDate and @toDate
  and Direction like 'IN'
  --and status like 'OK'
  and SourceFile like '%.zip'
  --and DestinatinFile like '%.tiff' -- from email batch
  --and DestinatinFile not like '%.error'
"

$SentToProduction_query = "

use internportal

declare @fromDate as DATE, @toDate as DATE;
set @fromDate = GETDATE()
set @toDate = GETDATE();

SELECT 
  COUNT(DestinatinFile) as SentToProduction
  FROM [internportal].[Stats].[OCFileReceiver]
  where 
  DateReceived between @fromDate and @toDate
  and Direction like 'IN'
  and status like 'OK'
  and 
  (
  DestinatinFile like '%.tiff' -- from email batch
  or DestinatinFile like '%.pdf' -- from email batch
  )
  and DestinatinFile not like '%.error'

"

$ReceivedFromFF_query = "

use internportal

declare @fromDate as DATE, @toDate as DATE;
set @fromDate = GETDATE();
set @toDate = GETDATE();

SELECT 
	COUNT (SourceFile) as ReceivedFromFF
  FROM [internportal].[Stats].[OCFileReceiver]
  where 
	DateReceived between @fromDate and @toDate
	and Direction like 'OUT'
	and status like 'OK'
	and DestinatinFile like '%.tif' -- from email batch

"

$SentToOC_query = "
use internportal
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
declare @fromDate as DATE, @toDate as DATE;
set @fromDate = GETDATE();
set @toDate = GETDATE();

SELECT
COUNT (SourceFile) as SentToOC

FROM ftpBatManager_FileHistory with(nolock)

		LEFT JOIN [stats].OCFileSender s with(nolock) ON dbo.getFilename(DestinationFile) = dbo.getFilename([Filename]) AND
		[filename] LIKE '%zip' AND
		cast(DateSent AS date) BETWEEN @fromDate AND @todate
WHERE 
	JobName like 'OCFileDelivery%' AND
	[ACTION] = 'ZIP' AND
	SourceFile LIKE '%tif'	-->> search only TIFF document
	AND
	cast([TimeStamp] AS date) BETWEEN @fromDate AND @todate

"

$Confirmations_query = "
use internportal
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
declare @fromDate as DATE, @toDate as DATE;
set @fromDate = GETDATE();
set @toDate = GETDATE();

SELECT  
COUNT(FileName) as Confirmations
FROM [internportal].[Stats].[OCFileSender]
where
cast([DateSent] AS date) BETWEEN @fromDate AND @todate
and FileName like '%ack'

"

$Confirmations_query_received = "
use internportal

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
declare @fromDate as DATE, @toDate as DATE;
set @fromDate = GETDATE();
set @toDate = GETDATE();

select 
COUNT(*) as Confirmations_received
from 
	FileProcessor.FileHistory
where
	SourceFile like '%ack' --file from scanning or email
	and Action like 'DOWNLOAD'
	and JobName like 'Opus Capita acknowledgement'
	and cast(TimeStamp AS date) BETWEEN @fromDate AND @todate

"

$SentToOC_batches_query = "
use internportal

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
declare @fromDate as DATE, @toDate as DATE;
set @fromDate = GETDATE();
set @toDate = GETDATE();

SELECT 
COUNT(*) as BatchesSent
FROM [internportal].[Stats].[OCFileSender]
where
	cast(DateSent AS date) BETWEEN @fromDate AND @todate
	and Filename like '%.zip'

"




$n = 0
$query1_array = @()
$query2_array = @()
$query3_array = @()
$query4_array = @()
$query5_array = @()
$query6_array = @()
$query7_array = @()

while ($true) {
   
  $query1 = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $ReceivedEmails_query
  $query2 = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $SentToProduction_query 
  $query3 = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $ReceivedFromFF_query
  $query4 = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $SentToOC_query
  $query5 = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Confirmations_query
  $query6 = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Confirmations_query_received
  $query7 = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $SentToOC_batches_query

  $query1_array += $query1.ReceivedEmails
  $query2_array += $query2.SentToProduction
  $query3_array += $query3.ReceivedFromFF
  $query4_array += $query4.SentToOC
  $query5_array += $query5.Confirmations
  $query6_array += $query6.Confirmations_received
  $query7_array += $query7.BatchesSent

  $godzina = get-date -Format HH:mm

  $myObject = [PSCustomObject]@{
    Time            = $godzina
    ReceivedEmails  = $query1.ReceivedEmails
    '   ......'     = ''
    AckNackSent     = $query5.Confirmations
    '    .....'     = ''
    SentToProd      = $query2.SentToProduction
    '     ....'     = ''
    ReceivedFromFF  = $query3.ReceivedFromFF
    '      ...'     = ''
    SentTIFFsToOC   = $query4.SentToOC
    '       ..'     = ''
    SentBatchesToOC = $query7.BatchesSent
    '        .'     = ''
    AckNackReceived = $query6.Confirmations_received
    '         '     = ''

  }

  $myObject2 = [PSCustomObject]@{
    Time            = $godzina
    ReceivedEmails  = $query1.ReceivedEmails
    '   ......'     = ($query1_array[-1] - $query1_array[-2])
    AckNackSent     = $query5.Confirmations
    '    .....'     = ($query5_array[-1] - $query5_array[-2])
    SentToProd      = $query2.SentToProduction
    '     ....'     = ($query2_array[-1] - $query2_array[-2])
    ReceivedFromFF  = $query3.ReceivedFromFF
    '      ...'     = ($query3_array[-1] - $query3_array[-2])
    SentTIFFsToOC   = $query4.SentToOC
    '       ..'     = ($query4_array[-1] - $query4_array[-2])
    SentBatchesToOC = $query7.BatchesSent
    '        .'     = ($query7_array[-1] - $query7_array[-2])
    AckNackReceived = $query6.Confirmations_received
    '         '     = ($query6_array[-1] - $query6_array[-2])

  }



  if ($n -gt 0) {
    
    ($myObject2 | Format-Table * -HideTableHeaders | Out-String).Trim()
    
  }
  Else {
    
    ($myObject | Format-Table * | Out-String).Trim()
  }

  $n++
  Start-Sleep -Seconds 900
} 