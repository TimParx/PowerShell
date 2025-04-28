
while ($true) {
    Remove-Variable -Name server, Database, username_db, pwd_db, nack_array_fixed, search_folder, destination_catalog, query, query2, baza, baza2 -ErrorAction SilentlyContinue
    Remove-Variable -Name nack_file, position_trigger, nack_fixed, length_trigger, nack_array_fixed, input_array, nack_fileDB, file_to_resend, file_to_move, godzina -ErrorAction SilentlyContinue
    #setting sql server
    $server = "btsevcipssql01.se.ad.banctec.com"
    $Database = "internportal"
    $username_db = "GENERIC_DB_ReadOnly_SQL"
    $pwd_db = "ZMwTuUFa7c"
    $nack_array_fixed = @()
    $search_folder = "\\btsevlev01.se.ad.banctec.com\Save\OCFileDelivery\save"
    $destination_catalog = "\\btsevlev02.se.ad.banctec.com\Leverans\OCFileDelivery\Nack_IncompleteFile\output"
    
    $query = "
    /****** Script for SelectTopNRows command from SSMS  ******/
    use internportal
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    declare @fromDate as DATE, @toDate as DATE;
    ------date----------------
    set @fromDate = DateAdd(DAY, -10, GETDATE());
    set @toDate = GETDATE();
    --------------------------
    SELECT
         convert(varchar, DateSent, 120) AS DateSent,
         --dbo.getFilename(Filename) as BatchName,
         Filename,
         convert(varchar, [NackReceived], 120) AS NackReceived,
         Message,
		 CASE
		 WHEN NackReceived is NULL and AckReceived is Null then 'Missing confirmation since ' + CONVERT(varchar(10), (datediff (mi, Datesent, convert(datetime, CURRENT_TIMESTAMP, 120)))/60)  + ' hours'
		 ELSE Message
		 END as Status
    
      FROM [internportal].[Stats].[OCFileSender]
      where
	  (
		  Filename like '%.zip'
		  and 
		  (
			  Message like 'Incomplete file detected'
			  or Message like '%The received batch is empty%'
			  or Message like '%The received batch do not contain the defined number of transactions%'
			  or Message like '%The received batch contains files with no corespondning data file%'
		  )
		  AND cast([DateSent] AS date) BETWEEN @fromDate AND @todate
		  and AckReceived is NULL
	  )
	  or
	  (
		Filename like '%.zip'
		--and Message not like 'OK'
		AND cast([DateSent] AS date) BETWEEN @fromDate AND @todate
		and AckReceived is NULL
		and NackReceived is NULL
		and datediff (mi, Datesent, convert(datetime, CURRENT_TIMESTAMP, 120)) > 150

	  )


    "
    Write-Host 'Checking NackFiles...'
    Start-sleep -s 3
    
    $baza = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query -Username $username_db -Password $pwd_db
    
    if ($baza.FileName.Count -gt 0) {

        Write-Host 'Found files:'

        foreach ($nack_file in $baza) {
    
            $position_trigger = $nack_file.Filename.LastIndexOf("/")
            $length_trigger = $nack_file.FileName.Length
            $nack_array_fixed += $nack_file.Filename.substring($position_trigger + 1, ($length_trigger - $position_trigger) - 1)
            $nack_fixed = $nack_file.Filename.substring($position_trigger + 1, ($length_trigger - $position_trigger) - 1)
            Write-Host $nack_fixed $nack_file.Status
            
        }
        # Write-Host 'Nack files found:'
        # $nack_array_fixed

        $input_array = @()
    
        Write-Host 'Checking FTPBatManagerHistory'
        foreach ($nack_fileDB in $nack_array_fixed) {
        
            $query2 = "
        
                    use internportal
                    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
                    declare @fromDate as DATE, @toDate as DATE;
                    ------date----------------
                    set @fromDate = DateAdd(DAY, -10, GETDATE());
                    set @toDate = GETDATE();
                    --------------------------
                    select 
                    JobName,
                    TimeStamp
                    from ftpBatManager_FileHistory fh with(nolock) 
                    where 
        
                    SourceFile like '%$nack_fileDB%' --> customer
                    AND cast(TimeStamp AS date) BETWEEN @fromDate AND @todate
                    and (
                    JobName like '%OCFileDelivery_NACK_IncompleteFile%'
                    or JobName like '%OCFileDelivery_ManualResend%'
                    )
                    and Action like 'UPLOAD'
                    order by
                    TimeStamp desc
        
                "
            $baza2 = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $query2 -Username $username_db -Password $pwd_db
            If ($baza2.TimeStamp.Count -eq 0) {
                $input_array += $nack_fileDB
                Write-host $nack_fileDB 'Sent once'
            }
            Else {
                Write-host $nack_fileDB 'Already resent'
            }
        }
    
        if ($input_array -gt 0) {
            Write-Host 'Coppying file from archive...'
            foreach ($file_to_resend in $input_array) {
                $file_to_move = Get-ChildItem -Path $search_folder -Filter $file_to_resend -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName }
        
                if ($file_to_move) {
                    
        
                    if (!(Test-Path "$destination_catalog\$file_to_resend")) {
                        Copy-Item $file_to_move $destination_catalog 
                        Write-Host $file_to_resend "Coppied" -ForegroundColor Green
                    }
                    else {
                        Write-Host $file_to_move 'File already exist in output location'
                    }
                            
                } 
        
                Else {
                    Write-Host $file_to_resend "Missing" -ForegroundColor Red
                }
            }
    
        }
        else {
            Write-Host 'Nothing To Resend'
        }
        
    }
    else {
        Write-Host 'Not found NackFiles in DB'
    }
    $godzina = Get-Date -format "HH:mm:ss"
    Write-Host $godzina 'done'
    Write-host 'sleeping...'
    Start-Sleep -s 300
    



}




