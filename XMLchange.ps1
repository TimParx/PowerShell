$directoryPath = "C:\temp\NL"

# listing plików
$xmlFiles = Get-ChildItem -Path $directoryPath -Filter *.xml

foreach ($file in $xmlFiles) {
    [xml]$xmlContent = Get-Content -Path $file.FullName

    $nodesToChange = $xmlContent.SelectNodes("//*[@Processed='1']")
    
    foreach ($node in $nodesToChange) {
        $node.SetAttribute("Processed", "0")
    }
    
    #save
    $xmlContent.Save($file.FullName)
    
    Write-Host "Zmieniono:" $file.FullName
}