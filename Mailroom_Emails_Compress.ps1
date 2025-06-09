param (
    [string]$SelectedClient = ""
)

# === Ustawienia ===
$rootFolder = "F:\Email\Archive"
$logFolder = "C:\Skrypty\Logi"
$today = Get-Date -Format "yyyy-MM-dd"
$logFile = Join-Path $logFolder "Compression_$today.log"

# === Tworzenie folderu logów, jeśli nie istnieje ===
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

# === Czyszczenie logów starszych niż 30 dni ===
Get-ChildItem -Path $logFolder -File | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-30)
} | Remove-Item -Force

# === Bieżący miesiąc i rok ===
$currentMonth = (Get-Date).Month
$currentYear = (Get-Date).Year

# === Wybranie klienta lub wszystkich klientów ===
$clientFolders = if ($SelectedClient -ne "") {
    $selectedPath = Join-Path $rootFolder $SelectedClient
    if (Test-Path $selectedPath) {
        Get-Item $selectedPath
    } else {
        Write-Host "❌ Podany klient '$SelectedClient' nie istnieje." -ForegroundColor Red
        exit 1
    }
} else {
    Get-ChildItem -Path $rootFolder -Directory
}

# === Przetwarzanie klientów ===
foreach ($clientFolder in $clientFolders) {
    $clientName = $clientFolder.Name
    $clientPath = $clientFolder.FullName

    # Szukanie katalogów w formacie YYYYMMDD
    $dateFolders = Get-ChildItem -Path $clientPath -Directory | Where-Object {
        $_.Name -match '^\d{8}$'
    }

    # Filtrowanie katalogów starszych niż bieżący miesiąc
    $filteredDateFolders = $dateFolders | Where-Object {
        $name = $_.Name
        $year = $name.Substring(0, 4) -as [int]
        $month = $name.Substring(4, 2) -as [int]
        ($year -lt $currentYear) -or ($year -eq $currentYear -and $month -lt $currentMonth)
    }

    # Grupowanie po YYYY.MM
    $groups = $filteredDateFolders | Group-Object {
        $name = $_.Name
        $year = $name.Substring(0, 4)
        $month = $name.Substring(4, 2)
        "$year.$month"
    }

    foreach ($group in $groups) {
        $month = $group.Name
        $zipName = "$month.zip"
        $zipPath = Join-Path $clientPath $zipName

        # Tymczasowy folder do kompresji (lokalnie u klienta)
        $tempFolder = Join-Path $clientPath ".tmp-$month"
        if (Test-Path $tempFolder) {
            Remove-Item -Path $tempFolder -Recurse -Force
        }
        New-Item -ItemType Directory -Path $tempFolder | Out-Null

        # Kopiowanie katalogów do tymczasowego
        foreach ($folder in $group.Group) {
            $targetPath = Join-Path $tempFolder $folder.Name
            Copy-Item -Path $folder.FullName -Destination $targetPath -Recurse
        }

        # Zliczanie plików EML w tymczasowym folderze
        $emlCount = (Get-ChildItem -Path $tempFolder -Recurse -Filter *.eml -File).Count

        # Kompresja
        Compress-Archive -Path (Join-Path $tempFolder '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force

        if (Test-Path $zipPath) {
            foreach ($folder in $group.Group) {
                Remove-Item -Path $folder.FullName -Recurse -Force
            }
            Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $clientName - Spakowano $emlCount plików .eml do $zipName"
        } else {
            Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $clientName - ❌ Błąd podczas kompresji $zipName"
        }

        # Sprzątanie tymczasowego folderu
        Remove-Item -Path $tempFolder -Recurse -Force
    }
}
