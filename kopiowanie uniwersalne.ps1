
#kopiowanie z listy
$file_list = Get-Content C:\kopiowanie\lista.txt

#$search_folder = "H:\Save\OCFileReceiver\FF\in"

##set the output folder name

Write-Host "

## Available Archives ##

1 = Firefly Output - \\btsevlev01.se.ad.banctec.com\Save\OCFileReceiver\FF
2 = Skanska Delivery Archive - \\btsevlev02.se.ad.banctec.com\Leverans\FF\Skanska_PL\save
3 = OpusCapita ack files - \\btsevlev01.se.ad.banctec.com\CIPS\OCFileReceiver\ack
4 = OpusCapita Delivery Archive - \\btsevlev01.se.ad.banctec.com\Save\OCFileDelivery\save

" -ForegroundColor Green

Write-host "Please choose the archive folder to search through or leave empty to use custom directory"

##Defining search folder
$archive = Read-Host -Prompt 'Enter your choice'


     If ($archive -eq '1')
         {

            $search_folder = '\\btsevlev01.se.ad.banctec.com\Save\OCFileReceiver\FF'
            Write-Host 'Firefly Output' -BackgroundColor Red

         }

     ElseIf ($archive -eq '2')

         {

         $search_folder = '\\btsevlev02.se.ad.banctec.com\Leverans\FF\Skanska_PL\save'
         Write-Host 'Skanska Delivery Archive' -BackgroundColor Red

         }

     ElseIf ($archive -eq '3')

         {

            $search_folder = '\\btsevlev01.se.ad.banctec.com\CIPS\OCFileReceiver\ack' 
            Write-Host 'Skanska Delivery Archive' -BackgroundColor Red

         }

      ElseIf ($archive -eq '4')

         {

             $search_folder = '\\btsevlev01.se.ad.banctec.com\Save\OCFileDelivery\save'
             Write-Host 'OpusCapita Delivery Archive' -BackgroundColor Red

         }

     Else
         {
            $custom = Read-Host -Prompt 'Enter your custom directory'
            Write-host $custom -BackgroundColor Red

        # Break
     }
#############


 ##$search_folder =  switch ( $archive )
 ## {
 ##   1 { '\\btsevlev01.se.ad.banctec.com\Save\OCFileReceiver\FF'    }
 ##   2 { '\\btsevlev02.se.ad.banctec.com\Leverans\FF\Skanska_PL\save'    }
 ##   3 { '\\btsevlev01.se.ad.banctec.com\CIPS\OCFileReceiver\ac'   }
 ##   4 { '\\btsevlev01.se.ad.banctec.com\Save\OCFileDelivery\save' }
 ##   default { Write-Host "Wrong choice" continue}
 ## }

$dir = Read-Host -Prompt 'Folder name you want to create in c:\kopiowanie\files'
$folder = $dir


#setting the whole direction for output files
$destination_folder = "C:\kopiowanie\files\$folder\output"

if(!(Test-Path -Path $destination_folder ))

{
    New-Item -ItemType directory -Path $destination_folder -Verbose
    Write-Host "
    
 
    
    Processing files... Please wait
    
    " -ForegroundColor Red
            
            foreach ($file in $file_list)
            {
                $file_to_move = Get-ChildItem -Path $search_folder -Filter $file -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName}
    
                    if ($file_to_move) 
    
                    {
                        Write-Host $file "Coppied"
                        Copy-Item $file_to_move $destination_folder
                        $File >> C:\kopiowanie\files\$folder\coppied.txt
                    } 

                    Else

                    {

                        Write-Host $File "Missing" 
                        $File >> C:\kopiowanie\files\$folder\missing.txt
                    }
            }


            ## Get-Content log files

                if (Test-Path -Path C:\kopiowanie\files\$folder\coppied.txt)

                    {
                         Write-Host "COPPIED FILES:" -ForegroundColor Yellow
                         Get-Content C:\kopiowanie\files\$folder\coppied.txt 
   
                    }

                Else

                    {
                        Write-Host "COPPIED FILES:" -ForegroundColor Yellow
                        Write-Host "nothing coppied" -ForegroundColor red
                    }


                if(Test-Path -Path C:\kopiowanie\files\$folder\missing.txt)

                    {
                         Write-Host "MISSING FILES:" -ForegroundColor Yellow
                         Get-Content C:\kopiowanie\files\$folder\missing.txt 
   
                    }

                Else

                    {
                         Write-Host "No missing files" -ForegroundColor Yellow
             
                    }

        Invoke-Item C:\kopiowanie\files\$folder

}

#If folder exist. Stop script
else

{
      Write-Host "Folder already exists, try one more time with another one" -ForegroundColor Red -BackgroundColor White
  
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

