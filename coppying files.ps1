#kopiowanie z listy
$file_list = Get-Content C:\kopiowanie\lista.txt
#$search_folder = "H:\Save\OCFileReceiver\FF\in"
#$search_folder = "\\btsepnascl01.se.ad.banctec.com\FFDelivery\OCFileDelivery"
$search_folder = "\\btsevlev01.se.ad.banctec.com\save\OCFileDelivery\save"



#$destination_folder = "C:\kopiowanie\files\1"

$destination_folder = "C:\kopiowanie\files\1"
if(!(Test-Path -Path $destination_folder )){
    New-Item -ItemType directory -Path $destination_folder
    Write-Host "New folder created"
}
else
{
  Write-Host "Folder already exists, try another one"
}

foreach ($file in $file_list)
{
    $file_to_move = Get-ChildItem -Path $search_folder -Filter $file -Recurse -ErrorAction SilentlyContinue -Force | ForEach-Object { $_.FullName}
    
    if ($file_to_move) 
    
    {
        Write-Host $File "Coppied"
        Copy-Item $file_to_move $destination_folder
    } 

    Else

    {

    Write-Host $File "Missing"
    }
}