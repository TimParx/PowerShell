Remove-Variable -Name lista, inputfile, filename, outputFile, keep, main_catalog, removed_array, removed_outputFile -ErrorAction SilentlyContinue


$main_catalog = '\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\CleanTXTFile'
$file = Get-ChildItem $main_catalog\input
$fileName = $file.Name
$inputFile = Get-Content $main_catalog\input\$fileName
$lista = Get-Content $main_catalog\list.txt | Where-Object { $_.trim() -ne "" }
$outputFile = "$main_catalog\output\$fileName"
$removed_outputFile = "$main_catalog\output\" + 'removed_' + $fileName
$removed_array = @()

#loop for every row in list.txt
Write-Host 'Processing...'
foreach ($line in $lista) {
    
    $keep = $true
    # $line
    $inputFile = $inputFile | ForEach-Object {
        if ($_ -like "*$line*") {
            $keep = $false
            #add deleted transfer row to array
            $removed_array += $_
        }
        elseif ($_ -notlike "*$line*") {
            $keep = $true
        }

        #add transfer row to variable $inputFile
        if ($keep) {
            $_
        }
            
    }
        
}

#creating output files
Set-Content -Path $outputFile -Value $inputFile
Set-Content -Path $removed_outputFile -Value $removed_array

Write-Host "Rows removed: " $removed_array.count
Write-Host "Rows left   : " $inputFile.count

if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}