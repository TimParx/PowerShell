Import-Module SqlServer
#clearing variables
Remove-Variable -Name server, Database, main_catalog, archive_path, input, date_today, time_stamp, days_limit, cutoff_day -ErrorAction SilentlyContinue
Remove-Variable -name LogTime, LogFile, email_archive, fullTIFF, batch_path, file, query, baza, position_trigger, batch_name, batch -ErrorAction SilentlyContinue
Remove-Variable -Name date_received_year, date_received_month, date_received_day, date_path, data_odbioru -ErrorAction SilentlyContinue
Remove-Variable -Name path, batch_path, temp_content, zipOutPutFolder, zipfiles, zipFile, zipOutPutFolderExtended, batch_type, InputFile -ErrorAction SilentlyContinue
Remove-Variable -Name tiff_file, file_to_coppy, size, image, temp_count, logFile, batch_path_array, not_found_array, log_array, question, final_input, logfile_array, ocguid  -ErrorAction SilentlyContinue

#setting sql server
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"

$main_catalog = "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\OCSearchInput"
$archive_path = "\\btsevlev01.se.ad.banctec.com\Save\OCFileReceiver\IN\emailreceiving-invoice"
$input = Get-Content "$main_catalog\input.txt" | Where-Object { $_.trim() -ne "" }

#extracting OCGUID if needed
# $OCGUID_regex = [regex]'[A-Z0-9]{32}siP[0-9]{1}'
$OCGUID_regex = [regex]'\S{32}si(P|p){1}[0-9]{1}'
$final_input = $OCGUID_regex.matches($input) | Select-Object Value -Unique
$logfile_array = @()
foreach ($ocguid in $final_input) {
    $logfile_array += $ocguid.value
}

# $date_today = Get-Date -Format "yyyy-MM-dd"
$time_stamp = Get-Date -Format "yyyy-MM-dd_HH.mm"
$days_limit = 30
$cutoff_day = (Get-Date).AddDays(-$days_limit)

# $LogTime = Get-Date -Format "yyyy-MM-dd_HH-mm"
# $LogFile = "$main_catalog\logs\" + "emailreceiving_" + $LogTime + ".log"
$email_archive = "$main_catalog\emailarchive"

$fullTIFF = @()
$batch_path_array = @()
$not_found_array = @()
$log_array = @()
#clean temp folder
Remove-Item "$main_catalog\temp\*.*"

##################################################################################################################

Write-Host Database searching...
$baza_array = @()
# $cos_array = @()
foreach ($file in $logfile_array) {
    #search database

    $query = "
    use internportal
    select 
    --[status],
    [Stats].GetOCGUID(DestinatinFile) as OCGUID, 
    DateReceived,
    dbo.getFilename(SourceFile) as EmailBatch,
    CASE
    WHEN LEFT(dbo.getFilename(SourceFile), 5) = 'email' THEN 'emailreceiving'
    ELSE 'externalscanning'
    END as Type,
    SourceFile,
    dbo.getFilename(DestinatinFile) as TIFF,
    convert(varchar, TimeStamp, 120) as SentToProduction
    from [stats].OCFileReceiver oc with(nolock) where 
    --SourceFile like '%B34034C1FA604BADB8C4CCBDB24B7B94siS1%'
    DestinatinFile like '%$file%'
    and DateReceived > '$cutoff_day'
    and Direction like 'IN'
    and 
    (
    DestinatinFile like '%.tiff'
    or DestinatinFile like '%.pdf'
    )
    "

    $baza = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query
    $baza_array += Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query

    #check if found in database
    if ($baza) {

        #extracting email batch name from database
        
        if ($baza.EmailBatch.count -gt 1) {
            # $position_trigger = $baza[0].SourceFile.lastIndexOf("\")
            # $batch_name = $baza.SourceFile[0].Substring($position_trigger + 1, 66)
            $batch_type = $baza.Type[0]
            $InputFile = $baza.TIFF[0]
            $batch_name = $baza.EmailBatch[0]
            $batch = $batch_name + ".done"
            $date_path = $baza.DateReceived[0].ToString("yyyyMMdd")
        
        }
        else {
            # $position_trigger = $baza.SourceFile.lastIndexOf("\")
            # $batch_name = $baza.SourceFile.Substring($position_trigger + 1, 66)
            $batch_type = $baza.Type
            $InputFile = $baza.TIFF
            $batch_name = $baza.EmailBatch
            $batch = $batch_name + ".done"
            $date_path = $baza.DateReceived.ToString("yyyyMMdd")

        }
        #extracting receiving date from the database
        # $date_received_year = $baza.DateReceived.ToString().substring(0, 4)
        # $date_received_month = $baza.DateReceived.ToString().substring(5, 2)
        # $date_received_day = $baza.DateReceived.ToString().substring(8, 2)
 
        # $data_odbioru = $baza.DateReceived.ToString().substring(0, 10)
        # Write-host $file

        #displaying data
        # $cos_array += $file | Select-Object @{n = "OCGUID"; e = { $_ } }, @{n = "EmailBatch"; e = { $batch_name } }, @{n = "DateReceived"; e = { $data_odbioru } }, @{n = "SentToProduction"; e = { $baza.SentToProduction } }
        $file | Select-Object @{n = "BatchType"; e = { $batch_type } }, @{n = "OCGUID"; e = { $_ } }, @{n = "InputFile"; e = { $InputFile } }, @{n = "EmailBatch"; e = { $batch_name } }, @{n = "DateReceived"; e = { $baza.DateReceived } }, @{n = "SentToProduction"; e = { $baza.SentToProduction } }, @{n = "EmailReceivedCount"; e = { $baza.EmailBatch.count } } | format-list  
        # if ($logfile_array.Count -gt 1) {
        #     $file | Select-Object @{n = "OCGUID"; e = { $_ } }, @{n = "EmailBatch"; e = { $batch_name } }, @{n = "DateReceived"; e = { $baza.DateReceived } }, @{n = "SentToProduction"; e = { $baza.SentToProduction } }, @{n = "EmailReceivedCount"; e = { $baza.EmailBatch.count } } | Format-Table -AutoSize
        # }
        # else {
        #     $file | Select-Object @{n = "OCGUID"; e = { $_ } }, @{n = "EmailBatch"; e = { $batch_name } }, @{n = "DateReceived"; e = { $baza.DateReceived } }, @{n = "SentToProduction"; e = { $baza.SentToProduction } }, @{n = "EmailReceivedCount"; e = { $baza.EmailBatch.count } } | format-list  
        # }
        
        #coppying email batch from archive to temp folder
        # Copy-Item -Path "$archive_path\$date_path\$batch" -Destination "$main_catalog\temp"
        # $path = "$archive_path\$date_path\$batch"



        if($batch_type -eq 'externalscanning' ) {

            $batch_path_array += "\\btsevlev01.se.ad.banctec.com\Infloden\CIPS\FTP\OCFileReceiver\in\externalscanning-invoice\done\$batch"
        }
        else {

            if ($date_path -eq (get-date -Format 'yyyyMMdd' )) {
                $batch_path_array += "\\btsevlev01.se.ad.banctec.com\Infloden\CIPS\FTP\OCFileReceiver\in\emailreceiving-invoice\done\$batch"
            
            }
            else {
                $batch_path_array += "$archive_path\$date_path\$batch"
            }
        }




        # $batch_path_array += "$archive_path\$date_path\$batch"
        # $batch >> $LogFile
        $log_array += $batch -replace '.done', ''
        $fullTIFF += $baza.TIFF 

    }
    else {
        #value not found in database
        $not_found_array += $file
        # write-host $file not found in the database
    }

}

if ($not_found_array.Count -gt 0) {
    Write-Host ''
    Write-host 'Not found in the database:'
    $not_found_array | Format-Table
}

##################################################################################################################

#check if found in the database
if ($fullTIFF.count -gt 0 ) {

    ###################
    Write-Host ''
    $question = Read-Host -Prompt 'Would you like to examine tiff files? y[yes], n[No]'
    Write-Host ''

    if ($question -eq 'y') {
        Write-Host 'Searching files in emailbatch archive...'
        Start-Sleep -s 1
        foreach ($batch_to_coppy in $batch_path_array) {
            #coppying files to temp folder

            try {

                Copy-Item -Path $batch_to_coppy -Destination "$main_catalog\temp"
                #removing "done" from the file and log file
                get-childitem "$main_catalog\temp" -filter *.done | rename-item -newname { $_.name -replace '.done', '' } -Force
            
            }
            catch {

                Write-Host $batch_to_coppy not found

            }

            #coppying files to "$main_catalog\emailarchive"
            #Move-Item "$main_catalog\temp" -filter *.zip -Destination "$main_catalog\emailarchive"     
            # $log_array = $batch_to_coppy -replace '.done', ''

        }

        # #unpacking email batches to output folder
        ##################################################################################################################
        # #unpacking email batches to output folder
        $temp_count = (Get-ChildItem "$main_catalog\temp" -Filter *.zip | Measure-Object).count

        if ($temp_count -gt 0) {
            Write-Host 'Coppying to emailarchive...'
            Copy-Item -Path "$main_catalog\temp\*.zip" -Destination $email_archive -Force
            #extracting batches

            $zipOutPutFolder = "$main_catalog\output\$time_stamp"
            # $zipfiles = Get-Content $LogFile
            Write-Host 'Extracting...'
            foreach ($zipFile in $log_array) {
                #unzipping files
                try {
    
                    if (Test-Path -Path  $zipOutPutFolder) {
                        $zipOutPutFolderExtended = $zipOutPutFolder + "\" + $zipFile
                        Expand-Archive -Path "$main_catalog\temp\$zipFile" -DestinationPath $zipOutPutFolderExtended -Force
    
                    }
                    Else {
                        New-Item -ItemType directory -Path  $zipOutPutFolder | Out-Null
    
                        $zipOutPutFolderExtended = $zipOutPutFolder + "\" + $zipFile
                        Expand-Archive -Path "$main_catalog\temp\$zipFile" -DestinationPath $zipOutPutFolderExtended -Force
                    }
    
                    # Write-Host $zipFile
                }
                #problem with unzip file
                catch {
    
                    Write-Host cos poszlo nie tak
    
                }
    
            }
    
            # #searching and copyying tif files
    
            foreach ($tiff_file in $fullTIFF) {
    
                $file_to_coppy = Get-ChildItem -Path "$main_catalog\output\$time_stamp" -Filter $tiff_file -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName }
                if ($file_to_coppy) {
                    try {
                        Copy-Item $file_to_coppy "$main_catalog\output\$time_stamp" -ErrorAction SilentlyContinue -force
                        # Write-Host Coppied $tiff_file
                    }
            
                    catch {
                        Write-Host $tiff_file run into a problem
                    }
                        
                } 
    
            }
    
            #Checking properties of file
            Function Format-FileSize() {
                Param ([int]$size)
                If ($size -gt 1TB) { [string]::Format("{0:0.00} TB", $size / 1TB) }
                ElseIf ($size -gt 1GB) { [string]::Format("{0:0.00} GB", $size / 1GB) }
                ElseIf ($size -gt 1MB) { [string]::Format("{0:0.00} MB", $size / 1MB) }
                ElseIf ($size -gt 1KB) { [string]::Format("{0:0.00} kB", $size / 1KB) }
                ElseIf ($size -gt 0) { [string]::Format("{0:0.00} B", $size) }
                Else { "" }
            }

            Write-Host 'Checking...'
            [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
            Get-ChildItem -Path "$main_catalog\output\$time_stamp" -Filter *.tiff | ForEach-Object {
                $image = [System.Drawing.Image]::FromFile($_.FullName)
         
                New-Object PSObject -Property @{
                    Name   = $_.Name
                    Height = $image.Height
                    Width  = $image.Width
                    Size   = Format-FileSize $_.Length
                    # fullname = $_.Fullname
                    # date = $_.LastWriteTime
                    # }
                }
            } | Format-Table name, height, width, Size -AutoSize
            Invoke-Item "$main_catalog\output\$time_stamp"
        }

    }

    Else {
        Exit
        #nothing to do
    }

}
else {
    #nothing found in the database. Do nothing
}



if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
