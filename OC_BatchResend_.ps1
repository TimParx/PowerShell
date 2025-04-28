#clearing variables
 
Remove-Variable -Name search_folder, LogTime, dir, dir2, destination_folder, destination_folder2, found, missing, coppied, checked, corrupted -ErrorAction SilentlyContinue
Remove-Variable -name user, LogFile1, LogFile2, LogFile3, LogFile4, LogFile5 -ErrorAction SilentlyContinue
Remove-Variable -Name input_file, pattern, input_file_proper, file, file_to_move -ErrorAction SilentlyContinue
Remove-Variable -Name zipInputFolder, zipOutPutFolder, corrupted_array, corrupted_output, proper_array, zipFile, zipFiles, zipOutPutFolderExtended -ErrorAction SilentlyContinue
Remove-Variable -Name catalog_list, list_batches_ok, catalog, lista_pliki, plik -ErrorAction SilentlyContinue
Remove-Variable -Name new_array, file_corrupted, corrupted_list, file_to_delete -ErrorAction SilentlyContinue
Remove-Variable -Name countfiles1, countfilesInteger1, countfiles2, countfilesInteger2, countfiles4, countfilesInteger4, countfiles5, countfilesInteger5 -ErrorAction SilentlyContinue
Remove-Variable -Name question, exePath, search_folder2, output_folder, to_coppy, file2, file_to_coppy, countfiles_coppied, countfilesCoppiedInteger, isRunning -ErrorAction SilentlyContinue
 
#searching folder. OpusCapita delivery archive
$search_folder = "\\btsevlev01.se.ad.banctec.com\Save\OCFileDelivery\save"

#setting file/catalog names
$LogTime = Get-Date -Format "yyyy-MM-dd_HH-mm"
$dir = Get-Date -Format "yyyy-MM-dd"
$dir2 = Get-Date -Format "yyyy-MM-dd_HH.mm"
#setting the whole direction for output files
$main_folder = "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\ResendBatchToOC"
$destination_folder = "$main_folder\output\$dir"
$destination_folder2 = "$main_folder\output\$dir\$dir2"

#set log files
$found = 'found_'
$missing = 'missing_'
$coppied = 'coppied_'
$checked = 'checked_'
$corrupted = 'corrupted_'
$user = $env:UserName
$LogFile1 = "$main_folder\logs\" + $found + $LogTime + ".log"
$LogFile2 = "$main_folder\logs\" + $missing + $LogTime + ".log"
$LogFile3 = "$main_folder\logs\" + $coppied + $LogTime + '_' + $user + ".log"
$LogFile4 = "$main_folder\logs\" + $checked + $LogTime + '_' + $user + ".log"
$LogFile5 = "$main_folder\logs\" + $corrupted + $LogTime + '_' + $user + ".log"

#input file
$input_file = Get-Content "$main_folder\input.txt" | Where-Object { $_.trim() -ne "" }
# [regex]$pattern = "^(202[0-7]|200[0-9]|[0-1][0-9]{3})(1[0-2]|0[1-9])(3[01]|[0-2][1-9]|[12]0)-([0-1]?\d|2[0-3])([0-5]?\d)?([0-5]?\d)?_(ERIN|PAPR)_[a-z0-9]{10}_(?:[1-9]|0[1-9]|10)_BT[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}0001.zip$"
# [regex]$pattern = "^(202[0-7]|200[0-9]|[0-1][0-9]{3})(1[0-2]|0[1-9])(3[01]|[0-2][1-9]|[12]0)-([0-1]?\d|2[0-3])([0-5]?\d)?([0-5]?\d)?_(ERIN|PAPR|ESPI)_([a-z0-9]{10}|[a-z0-9]{18})_(?:[1-9]|0[1-9]|10)_BT[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}0001.zip$"
[regex]$pattern = "^(202[0-7]|200[0-9]|[0-1][0-9]{3})(1[0-2]|0[1-9])(3[01]|[0-2][1-9]|[12]0)-([0-1]?\d|2[0-3])([0-5]?\d)?([0-5]?\d)?_(ERIN|PAPR|ESPI)_([a-zA-z0-9]{10}|[a-zA-z0-9]{18})_(?:[1-9]|0[1-9]|10)_BT[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}0001.zip$"

$input_file_proper = $input_file | Where-Object { $_.trim() -ne "" } | Where-Object { $pattern.IsMatch($_) }

#####do testów
# [regex]$pattern2 = "(202[0-7]|200[0-9]|[0-1][0-9]{3})(1[0-2]|0[1-9])(3[01]|[0-2][1-9]|[12]0)-([0-1]?\d|2[0-3])([0-5]?\d)?([0-5]?\d)?_(ERIN|PAPR)_[a-z0-9]{10}_(?:[1-9]|0[1-9]|10)_BT[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}0001.zip"
# $pattern2.Matches($input_file).Value
# $input_file | Where-Object {$_ -notmatch $pattern2}

#checking the input file
Write-Host Analyzing input.txt...
Start-Sleep -s 2
Write-Host Imported rows: $input_file_proper.count
Start-Sleep -s 1
Write-Host Incorect rows: ($input_file | Where-Object { $_.trim() -ne "" } | Where-Object { -not $pattern.IsMatch($_) }).count
$input_file | Where-Object { $_.trim() -ne "" } | Where-Object { -not $pattern.IsMatch($_) }
Start-Sleep -s 2
IF ($input_file_proper.count -gt 0) {
    Write-Host "Process has been started"
    Start-Sleep -s 1
    #   start...
    #  Destination (date) file catalog check:
    Write-Host Checking output directory...
    Start-Sleep -s 2
    if ([IO.Directory]::Exists($destination_folder)) {
        #Do Nothing!!
        Write-Host 'Directory with date' $dir 'already exist'
        Start-Sleep -s 1
    }
    else {
        New-Item -ItemType directory -Path "$main_folder\output\$dir" | Out-Null
        Write-Host $dir 'Directory has been created' -ForegroundColor Green
    }

    #coppying files to temporary location in \\btsevlev02.se.ad.banctec.com\Leverans\OCFileDelivery\ManualResend\ToResend\output\
    Write-Host 'Searching files...'
    New-Item -ItemType directory -Path "$main_folder\output\$dir\$dir2" | Out-Null # cza dodac jeszcze usuwanie folderu jak nic nie znajdzie
    $licznik = 0
    $licznik2 = $input_file_proper.count
    foreach ($file in $input_file_proper) {
        $file_to_move = Get-ChildItem -Path $search_folder -Filter $file -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName }
        $numer = $licznik += 1
        $numer2 = ($numer - $licznik2) * (-1)
        if ($file_to_move) {
            
            Write-Host $numer"." $File "Found" -ForegroundColor Green "($numer2 left)"
            Copy-Item $file_to_move $destination_folder2
            #New-Item -itemType Directory -Path c:\kopiowanie\logs -Name $FolderName
            #$File >> C:\kopiowanie\logs\$folderName\coppied.txt
            $File >> $LogFile1
                        
        } 

        Else {
            Write-Host $numer"." $File "Missing" -ForegroundColor Red "($numer2 left)"
            $File >> $LogFile2
        }
    }


    #####FOUND SOMETHING##########
    #############testing archives#########

    if (Test-Path -Path $LogFile1) {

        #input variables
        $zipInputFolder = "$main_folder\output\$dir\$dir2"
        $zipOutPutFolder = "$main_folder\temp\$dir\$dir2"
        $corrupted_array = @()
        $corrupted_output = "$main_folder\corrupted\$dir\$dir2"
        $proper_array = @()
        #start
        $zipFiles = Get-ChildItem $zipInputFolder -Filter *.zip

        Write-Host 'Extracting archives...'
        Start-Sleep -s 1
        foreach ($zipFile in $zipFiles) {
            #unzipping files
            try {
                $zipOutPutFolderExtended = $zipOutPutFolder + "\" + $zipFile
                Expand-Archive -Path $zipFile.FullName -DestinationPath $zipOutPutFolderExtended -Force
                $proper_array += $zipFile.name

                # Write-Host $zipFile
            }
            #problem with unzip file
            catch {
                if (Test-Path -Path  $corrupted_output) {
                    Write-Host $zipFile.name Corrupted archive... moved to corrupted catalog
                    $corrupted_array += $zipFile.name
                    Start-Sleep -s 2
                    Remove-Item $zipOutPutFolderExtended
                    Move-Item $zipfile.FullName $corrupted_output -Force

                }
                else {
                    New-Item -ItemType directory -Path $corrupted_output | Out-Null
                    Write-Host $zipFile.name Corrupted archive... moved to corrupted catalog
                    $corrupted_array += $zipFile.name
                    Start-Sleep -s 2
                    Remove-Item $zipOutPutFolderExtended
                    Move-Item $zipfile.FullName $corrupted_output -Force

                }

            }

        }
        #sprawdzanie czy sie cos rozpakowalo
        if ($proper_array.count -gt 0) {
            
        }
        Else { }

        #checking the content of zip batches
        Write-Host 'checking the files...'
        Start-Sleep -s 2

        # ls $zipOutPutFolderExtended | Select-Object @{n="Name";e={$_.name.Length}}
        #    ls $zipOutPutFolder -Recurse -Property PSIsContainer -EQ -value $false| Select-Object FullName, @{n="Dlusosc";e={$_.name.Length}}
        #    Get-ChildItem $zipOutPutFolder -Recurse | Where-Object { ! $_.PSIsContainer } | Select-Object Name, @{n="Dlusosc";e={$_.name.Length}}

        # $zipOutPutFolder = "C:\we\unzip"

        $catalog_list = Get-ChildItem $zipOutPutFolder -recurse | Where-Object { $_.PSIsContainer } 
        $list_batches_ok = @()
        #  $lista_pliki = Get-ChildItem ($zipOutPutFolder + "\" + $catalog) | Where-Object { ! $_.PSIsContainer } 

        # [regex]$paper = "^PAPR_[0-9]{14}_[a-z0-9]{18}_PAPER.(tif|xml)$"
        # [regex]$erin = "^ERIN_[0-9]{14}_[a-z0-9]{18}_[A-Z0-9]{32}siP[0-9]{1}.(tif|xml)$"
        # [regex]$erin_rej = "^ERIN_[0-9]{14}_[a-z0-9]{18}_[A-Z0-9]{32}siP[0-9]{1}.ack.xml$"

        foreach ($catalog in $catalog_list) {
            Write-host $catalog.name -ForegroundColor Yellow
            # Write-host 'poczatek petli'
            $lista_pliki = Get-ChildItem ($zipOutPutFolder + "\" + $catalog) | Where-Object { ! $_.PSIsContainer } 
            foreach ($plik in $lista_pliki) {
                Start-Sleep -m 100
                #Paper documents
                IF ($plik.name.Length -eq '48') {
                
                    if ($plik.name -match '^PAPR_[0-9]{14}_[a-z0-9]{18}_PAPER.(tif|xml)$') {
                        Write-Host $plik.Name ...FILE OK
                        $list_batches_ok += $catalog.Name
                    }
                    else {
                        Write-Host $plik.name ...FILE NOT OK
                        $corrupted_array += $catalog.Name
                    }
                    # Write-Host $plik.Name ...FILE NAME OK
                
                }

                #paper documents/rejects

                elseif ($plik.name.Length -eq '52') {
                    
                    if ($plik.name -match '^PAPR_[0-9]{14}_[a-z0-9]{18}_PAPER.ack.xml$') {
                        Write-Host $plik.Name ...FILE OK
                        $list_batches_ok += $catalog.Name
                    }
                    else {
                        Write-Host $plik.name ...FILE NOT OK
                        $corrupted_array += $catalog.Name
                    }

                }
                #Email documents /ERIN, ESPI
                elseif ($plik.name.length -eq '79') {
                
                    # if ($plik.Name.substring($plik.Name.LastIndexOf("_") + 1, 36) -match '^[A-Z0-9]{32}siP[0-9]{1}$') {
                    if ($plik.Name -match '^(ERIN_|ESPI_)[0-9]{14}_[a-z0-9]{18}_[A-Z0-9]{32}siP[0-9]{1}.(tif|xml)$') {
                        # if($erin.IsMatch($plik.name)){
                        Write-Host $plik.Name ...FILE OK
                        $list_batches_ok += $catalog.Name
                    }
                    else {
                        Write-Host $plik.Name ...FILE NOT OK
                        # $tablica += $catalog.Name
                        $corrupted_array += $catalog.Name
                    }
                }
                #Email documents /ERIN, ESPI Rejected
                elseif ($plik.name.length -eq '83') {
                
                    if ($plik.Name -match '^(ERIN_|ESPI_)[0-9]{14}_[a-z0-9]{18}_[A-Z0-9]{32}siP[0-9]{1}.ack.xml$') {
                        Write-Host $plik.Name ...FILE OK
                        $list_batches_ok += $catalog.Name
                    }
                    else {
                        Write-Host $plik.Name ...FILE NOT OK
                        # $tablica += $catalog.Name
                        $corrupted_array += $catalog.Name
                    }
                }
                # #external scanning /ESPI
                # elseif ($plik.name.length -eq '79') {
                
                #     # if ($plik.Name.substring($plik.Name.LastIndexOf("_") + 1, 36) -match '^[A-Z0-9]{32}siP[0-9]{1}$') {
                #     if ($plik.Name -match '^ESPI_[0-9]{14}_[a-zA-Z0-9]{18}_[A-Z0-9]{32}siP[0-9]{1}.(tif|xml)$') {
                #         # if($erin.IsMatch($plik.name)){
                #         Write-Host $plik.Name ...FILE OK
                #         $list_batches_ok += $catalog.Name
                #     }
                #     else {
                #         Write-Host $plik.Name ...FILE NOT OK
                #         # $tablica += $catalog.Name
                #         $corrupted_array += $catalog.Name
                #     }
                # }
                # #external scanning /ESPI Rejected
                # elseif ($plik.name.length -eq '83') {
                
                #     if ($plik.Name -match '^ESPI_[0-9]{14}_[a-zA-Z0-9]{18}_[A-Z0-9]{32}siP[0-9]{1}.ack.xml$') {
                #         Write-Host $plik.Name ...FILE OK
                #         $list_batches_ok += $catalog.Name
                #     }
                #     else {
                #         Write-Host $plik.Name ...FILE NOT OK
                #         # $tablica += $catalog.Name
                #         $corrupted_array += $catalog.Name
                #     }
                # }
                #Number of chatacters is not matched to the mask
                
                else {
                    Write-Host $plik.Name ...FILE NOT OK -ForegroundColor red
                    # $tablica += $catalog.Name
                    $corrupted_array += $catalog.Name
                }
                #    Write-Host 'koniec petli'
            
            }
        
        }
        #export data to log file and clear variables
        # if ($tablica.count -gt 0){
        #     $tablica | sort-object -unique | Out-File $LogFile5 #corrupted batches
        # }
        #new array with proper batches
        $new_array = $list_batches_ok | Where-Object { $corrupted_array -notcontains $_ }
        # Write-Host $new_array
        ###
        if ($corrupted_array.count -gt 0) {
            $corrupted_array | sort-object -unique | Out-File $LogFile5 #corrupted batches
        }
        
        # $tablica | sort-object -unique | Out-File $LogFile5 #corrupted batches
        if ($new_array.count -gt 0) {
            $new_array | sort-object -unique | Out-File $LogFile4 #corrupted batches
        }

        # $list_batches_ok | sort-object -unique | Out-File $LogFile4 #ok batches
    
        

        #removing corrupted batches from output

        if (Test-Path -Path $LogFile5) {
            Write-Host Cleaning Output catalog...
            $corrupted_list = Get-Content $LogFile5


            if (Test-Path -Path  $corrupted_output) {
                #do nothing yet

            }
            else {
                New-Item -ItemType directory -Path $corrupted_output | Out-Null
                #create a corrupted catalog
                Write-Host Corrupted directory has been created

            }

            

            foreach ($file_corrupted in $corrupted_list) {
        
                $file_to_delete = Get-ChildItem $destination_folder2 -Filter $file_corrupted -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName }
                if ($file_to_delete) {
                
                    Move-Item $file_to_delete $corrupted_output -Force
                    Write-Host $file_corrupted moved to corrupted directory

                } 
        
                Else {

                }
            }

        }
        else {
            Write-Host All batches OK -ForegroundColor blue -BackgroundColor Green
        }
        ######
    }
    #####NO FILES FOUND##########
    else {
        Write-Host 'Script End. Nic nie znalazlo'
        #Nothing Found. Do nothing

        #usuwanie pustego katalogu output
        if ((Get-ChildItem $destination_folder -Filter *.zip -Recurse).count -eq 0) {
            Remove-Item -Path $destination_folder -Force -Recurse
            # Write-Host do usuniecia folder
        }
        else {
            if (Test-Path -path $LogFile1) {
                Write-Host sa pliki w $destination_folder2
            }
            else {
                Write-Host folder byl pysty
                Remove-Item -Path $destination_folder2
            }
            Write-Host sa pliki w $destination_folder
        }
        #####END SCRIPT########
        ########################

        # If running in the console, wait for input before closing.
        if ($Host.Name -eq "ConsoleHost") {
            Write-Host "Press any key to continue..."
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
        }
        
    }

    ######################################################
    ######SUMMARY############
    if (Test-Path -Path $LogFile1) {
        $countfiles1 = Get-Content $LogFile1 | Measure-Object -Line
        $countfilesInteger1 = $countfiles1.Lines
        Write-Host "FOUND FILES: $countfilesInteger1" -ForegroundColor Yellow

        if (Test-Path -Path $LogFile2) {
            $countfiles2 = Get-Content $LogFile2 | Measure-Object -Line
            $countfilesInteger2 = $countfiles2.Lines
            Write-Host "MISSING FILES: $countfilesInteger2" -ForegroundColor Yellow
        }
        else {
            Write-Host "MISSING FILES: 0" -ForegroundColor Yellow
        }

        if (Test-Path -Path $LogFile4) {
            $countfiles4 = Get-Content $LogFile4 | Measure-Object -Line
            $countfilesInteger4 = $countfiles4.Lines
            Write-Host "PROPER FILES: $countfilesInteger4" -ForegroundColor Yellow
        }
        else {
            Write-Host "PROPER FILES: 0" -ForegroundColor Yellow
        }
        
        if (Test-Path -Path $LogFile5) {
            $countfiles5 = Get-Content $LogFile5 | Measure-Object -Line
            $countfilesInteger5 = $countfiles5.Lines
            Write-Host "CORRUPTED FILES: $countfilesInteger5" -ForegroundColor Yellow
        }
        else {
            Write-Host "CORRUPTED FILES: 0" -ForegroundColor Yellow
        }
        
    }
    else {
        Write-Host "FOUND FILES: 0" -ForegroundColor Yellow
        if (Test-Path -Path $LogFile2) {
            $countfiles2 = Get-Content $LogFile2 | Measure-Object -Line
            $countfilesInteger2 = $countfiles2.Lines
            Write-Host "MISSING FILES: $countfilesInteger2" -ForegroundColor Yellow
        }
        else {
            Write-Host "MISSING FILES: 0" -ForegroundColor Yellow
        }
        Write-Host "PROPER FILES: 0" -ForegroundColor Yellow
        Write-Host "MISSING FILES: 0" -ForegroundColor Yellow
    }

    ##could be added in if statement with #logfile1
    ## Get-Content log files, launch FTPBatManager
    #checking if the foundlog file exist
    if (Test-Path -Path $LogFile4) {

        $question = Read-Host -Prompt 'Do you want to move them to ManualResend output folder? y[yes], n[No]'


        If ($question -eq 'y') {
                
            $exePath = '\\btsevlev02.se.ad.banctec.com\FtpBatManagerService\FTPBatManager\FTP Bat Manager.exe'
            Write-Host 'Processing files...'
                
            #coppying files to \\btsevlev02.se.ad.banctec.com\Leverans\OCFileDelivery\ManualResend\output
            $search_folder2 = "$main_folder\output\$dir\$dir2"
            $output_folder = "\\btsevlev02.se.ad.banctec.com\Leverans\OCFileDelivery\ManualResend\output"
            $to_coppy = Get-Content $LogFile4
                
            foreach ($file2 in $to_coppy) {
                $file_to_coppy = Get-ChildItem -Path $search_folder2 -Filter $file2 -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName }
        
                if ($file_to_coppy) {

                    #Write-Host $file2 "Coppied" -ForegroundColor Green
                    Copy-Item $file_to_coppy  $output_folder
                    $file2 >> $LogFile3
                        
                } 

                Else {
                    #Do nothing
                }
            }
            #end coppying

            #check how many files have been coppied
            $countfiles_coppied = Get-Content $LogFile3 | Measure-Object -Line
            $countfilesCoppiedInteger = $countfiles_coppied.Lines

            Write-Host $countfilesCoppiedInteger 'Files have been coppied'

            #check if FTPBatManager is running
            $isRunning = (get-wmiobject win32_process | Where-Object { 
                    $_.Path -eq $exePath
                } | measure-object | ForEach-Object { $_.Count }) -gt 0
                
            if ($isRunning) { 
                #If yes do nothing
                Write-Host 'FTPBatManager is already running'
            }
                
            Else {
                & $exePath  #launch FTPBatManager
                Write-Host "FTPBatManager has been launched"
            }
            Invoke-Item $output_folder
        }
            
        else {
            #Answer is No (or other) Do nothing
            Write-Host "Nothing has been Coppied"
            Write-Host "Files will be available in $destination_folder2"   
        
        }
    }

    Else {
        # Write-Host 'Nothing found'
        #Nothing Found. Do nothing
    
        # If running in the console, wait for input before closing.
        if ($Host.Name -eq "ConsoleHost") {
            Write-Host "Press any key to continue..."
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
        }

    }

    # If running in the console, wait for input before closing.
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to continue..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    }



}
else {
    #no proper files detected in input.txt. End script
    Write-Host No files detected 

    # If running in the console, wait for input before closing.
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to continue..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    }
}