# === Sekcja 1: Konfiguracja ===

# Foldery źródłowe i docelowe
$rootFolder = "D:\Klienci"
$archiveRoot = "D:\Archiwum"

# Ścieżka do logów
$logFolder = "C:\Skrypty\Logi"
if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder | Out-Null }

# Nazwa logu na dzisiejszy dzień
$logFile = Join-Path $logFolder ("Archiwum_" + (Get-Date -Format "yyyy-MM-dd") + ".log")

# Usuń logi starsze niż 30 dni
Get-ChildItem -Path $logFolder -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force

# Lista podsumowująca dla e-maila
$summary = @()

# === Sekcja 2: Funkcja do logowania ===

function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp`t$Message"
}

# === Sekcja 3: Przetwarzanie klientów ===

$clientFolders = Get-ChildItem -Path $rootFolder -Directory

foreach ($client in $clientFolders) {
    $clientFolder = $client.FullName
    $clientName = $client.Name
    $clientArchiveFolder = Join-Path $archiveRoot $clientName

    $movedCount = 0

    # Pobierz katalogi datowe
    $dateFolders = Get-ChildItem -Path $clientFolder -Directory

    foreach ($dateDir in $dateFolders) {
        $dateString = $dateDir.Name
        $parsed = $false

        # Przykład z czystym PowerShellem
        $year = $dateString.Substring(0, 4)
        $month = $dateString.Substring(4, 2)
        $day = $dateString.Substring(6, 2)

        try {
            $folderDate = Get-Date -Year $year -Month $month -Day $day -ErrorAction Stop
            $parsed = $true
        } catch {
            $parsed = $false
        }

        # Alternatywa z .NET (zakomentowana)
        # if ([datetime]::TryParseExact($dateString, "yyyyMMdd", $null, [System.Globalization.DateTimeStyles]::None, [ref]$null)) {
        #     $folderDate = [datetime]::ParseExact($dateString, "yyyyMMdd", $null)
        #     $parsed = $true
        # }

        if ($parsed -and $folderDate -lt (Get-Date).AddDays(-30)) {
            $destPath = Join-Path $clientArchiveFolder $dateString
            if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath | Out-Null }

            $emlFiles = Get-ChildItem -Path $dateDir.FullName -Filter *.eml -File -Recurse
            foreach ($file in $emlFiles) {
                $relativePath = $file.FullName.Substring($dateDir.FullName.Length).TrimStart("\")
                $destinationFile = Join-Path $destPath $relativePath

                $destinationDir = Split-Path -Path $destinationFile -Parent
                if (-not (Test-Path $destinationDir)) { New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null }

                Move-Item -Path $file.FullName -Destination $destinationFile -Force
                $movedCount++
            }

            Write-Log "[$clientName] Przeniesiono katalog $($dateDir.Name) do archiwum"
        }
        elseif (-not $parsed) {
            Write-Log "Nie udało się sparsować daty katalogu: $($dateDir.FullName), pomijam"
        }
    }

    if ($movedCount -gt 0) {
        $summary += "[$clientName] Przeniesiono $movedCount plików EML"
        Write-Log "[$clientName] Przeniesiono $movedCount plików EML"
    } else {
        Write-Log "[$clientName] Brak plików do przeniesienia"
    }
}

# === Sekcja 4: Wysyłka e-maila ===

# if ($summary.Count -gt 0) {
#     $body = $summary -join "`r`n"

#     Send-MailMessage -From "skrypt@twojafirma.pl" `
#                      -To "admin@twojafirma.pl" `
#                      -Subject "Podsumowanie archiwizacji EML - $(Get-Date -Format yyyy-MM-dd)" `
#                      -Body $body `
#                      -SmtpServer "smtp.twojafirma.pl"
# }
