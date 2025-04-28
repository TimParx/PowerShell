$pliki = Get-Content C:\Temp\lista.txt




$data = foreach ($plik in $pliki) {
     $ciecie = $plik.Split("_", 4)[-1] #Karcher
    # $ciecie = $plik.Split("_", 3)[-1] #Ikea
     $plik_log = '20' + $ciecie.substring(0,6) + '-sysaxservd.log'
     $szukany = Select-String -path E:\logs\$plik_log -pattern $plik | Select-String downloaded | out-string
     $szukany2 = Select-String -path E:\logs\$plik_log -pattern $plik | Select-String "Upload completion status" | out-string
     $szukany_data = $szukany.split(":", 4)[-1]
     $szukany2_data = $szukany2.Split(":", 4)[-1]
     $szukany_data_extracted = $szukany_data.substring(0, 22)
     $szukany2_data_extracted = $szukany2_data.substring(0, 22)
        
        [PSCustomObject]@{
        Time           = $plik
        UploadedbyEthos = $szukany2_data_extracted
        DownloadedbyOC = $szukany_data_extracted

        }

    }

    $export_file = "c:\temp\kst.csv"
    $data | Export-Csv $export_file -delimiter ";" -NoTypeInformation 