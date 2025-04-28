#kopiowanie z listy
$file_list = Get-Content C:\kopiowanie\lista.txt

#$search_folder = "H:\Save\OCFileReceiver\FF\in"

##OPUSCAPITA DELIVERY ARCHIVE##
#$search_folder = "\\btsepnascl01.se.ad.banctec.com\FFDelivery\OCFileDelivery"
#$search_folder = "\\btsevlev02.se.ad.banctec.com\Leverans\FF\Skanska_PL\save"
#$search_folder = "\\btsevlev01.se.ad.banctec.com\CIPS\OCFileReceiver\ack"
$search_folder = "\\btsevlev01.se.ad.banctec.com\Save\OCFileDelivery\save"

#$search_folder = "\\btsevlev01.se.ad.banctec.com\Save\OCFileReceiver\FF"

##set the output folder name

#
$dir = Read-Host -Prompt 'Folder name you want to create'
$folder = $dir

#setting the whole direction for output files
$destination_folder = "C:\kopiowanie\files\$folder\output"

if(!(Test-Path -Path $destination_folder ))

{
    New-Item -ItemType directory -Path $destination_folder
    Write-Host "Folder ' $folder ' created. Processing files..."
            
            foreach ($file in $file_list)
            {
                $file_to_move = Get-ChildItem -Path $search_folder -Filter $file -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName}
    
                    if ($file_to_move) 
    
                    {
                        Write-Host $File "Coppied"
                        Copy-Item $file_to_move $destination_folder
                        $File >> C:\kopiowanie\files\$folder\coppied.txt
                    } 

                    Else

                    {

                        Write-Host $File "Missing" 
                        $File >> C:\kopiowanie\files\$folder\missing.txt
                    }
            }
}

else

{
      Write-Host "Folder already exists, try another one"
  
        [console]::beep(440,500)      
        [console]::beep(440,500)
        [console]::beep(440,500)       
        [console]::beep(349,350)       
        [console]::beep(523,150)       
        [console]::beep(440,500)       
        [console]::beep(349,350)       
        [console]::beep(523,150)       
        [console]::beep(440,1000)
  
      break
}

