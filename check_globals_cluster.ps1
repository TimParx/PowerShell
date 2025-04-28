$rootFolderPath = 'E:\FTP\Kunder\Opus\FF_OC_GLO_PROD\PROD\OPUS\INVOICES'
$excludeDirectories = ("PROCESSED", "OUT");

function globale
{
    process
    {
        $allowThrough = $true
        foreach ($directoryToExclude in $excludeDirectories)
        {
            $directoryText = "*\" + $directoryToExclude
            $childText = "*\" + $directoryToExclude + "\*"
            if (($_.FullName -Like $directoryText -And $_.PsIsContainer) `
                -Or $_.FullName -Like $childText)
            {
                $allowThrough = $false
                break
            }
        }
        if ($allowThrough)
        {
            return $_
        }
    }
}

Clear-Host
 
Get-ChildItem $rootFolderPath -Recurse -filter *.zip `
    | globale | Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-1) }
Get-ChildItem $rootFolderPath -Recurse -filter *.tmp