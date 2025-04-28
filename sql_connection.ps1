# $cred = Get-Credential
# $password = 'Welcome12345678'
# $secpwd = ConvertTo-SecureString $password -AsPlainText -Force



# $ConnectionString = "server='btsevcipssql01.se.ad.banctec.com';database='internportal';user id='btec\masmolins';password='Welcome12345678';trusted_connection=true;"

# $Connection = New-Object System.Data.SQLClient.SQLConnection($ConnectionString)


#$cred = Get-Credential
# this will prompt for username and password, fill them in
# use this in your connection string
# $secpwd = ConvertTo-SecureString $password -AsPlainText -Force

# SQLServer

# $SqlConnection.ConnectionString = "Server='btsevcipssql01.se.ad.banctec.com'; Database='internportal'; User ID='masmolins; Password=Welcome12345678"

Get-SqlDatabase -ServerInstance btsevcipssql01.se.ad.banctec.com -credential $secpwd

Import-Module SqlServer
$instance = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"
$table = "OCFileReceiver"
$plik = "*emailreceiving-invoice_10_4290105540F6472C84FDC7A5A7A417AAsiP3.zip*"

Read-SqlTableData -serverInstance $instance -DatabaseName $Database -SchemaName "Stats" -TableName $table -TopN 100 -ColumnName SourceFile, Direction | Where-Object { $_.SourceFile -like '*4290105540F6472C84FDC7A5A7A417AAsiP3*' }


$results = Invoke-Sqlcmd -ServerInstance "mySqlServer" -Database "myDatabase" -Query "SELECT * FROM MyTable"
Invoke-Sqlcmd -ServerInstance "btsevcipssql01.se.ad.banctec.com" -Database "internportal" -Query "
use internportal

SELECT Top (10)

SourceFile
--count(SourceFile) as Count
  FROM [internportal].[Stats].[OCFileReceiver]
  
"
$plik = "emailreceiving-invoice_10_4290105540F6472C84FDC7A5A7A417AAsiP3.zip"
$toDate = get-date -DisplayHint date
$fromDate = (get-date).AddDays(-3).ToString("yyyy-MM-dd")

$Query = "
use internportal
declare @fromDate as DATE, @toDate as DATE;
set @fromDate = '$fromDate';
set @toDate = '$toDate';
SELECT
--SourceFile,
count(SourceFile) as Count
  FROM [internportal].[Stats].[OCFileReceiver] br
  where 
  DateReceived between @fromDate and @toDate
  and Direction like 'IN'
  and status like 'OK'
  and br.DestinatinFile not like '%.error'
  and SourceFile like '%$plik%'
  and DestinatinFile like '%.tiff'
 group by SourceFile
"
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"
Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query

# Invoke-Sqlcmd -Query $Query -ConnectionString ("Server=" + $Server + ";Database=" + $Database + ";UID=" + $Username + ";PWD=" + $Password + ";Integrated Security=true;") 

$pliczki = Get-Content C:\Temp\email.txt
$toDate = get-date -DisplayHint date
$fromDate = (get-date).AddDays(-3).ToString("yyyy-MM-dd")
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"
Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query

foreach ($email in $pliczki) {
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
      and SourceFile like '%$email%'
      and DestinatinFile like '%.tiff'
     group by SourceFile
    "
    Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query

}