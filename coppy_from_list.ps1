$pliki = Get-Content C:\Temp\lista.txt
$dest  = 'C:\Temp\pliki'
# $do_skopiowania = Get-ChildItem \\btsevlev01.se.ad.banctec.com\Save\OCFileReceiver\FF -Recurse
foreach ($plik in $pliki) {
    $do_skopiowania = Get-ChildItem \\btsevlev01.se.ad.banctec.com\Infloden\CIPS\FTP\OCFileReceiver\FF\in\ -Filter "*$plik*" -Recurse | ForEach-Object { $_.FullName }
    foreach ($item in $do_skopiowania) {
        Copy-Item $item $dest
    }
}