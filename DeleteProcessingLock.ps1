# Użyj bieżącego katalogu, w którym skrypt jest uruchamiany
$folderPath = $PSScriptRoot

# Pobierz czas sprzed 10 minut
$timeThreshold = (Get-Date).AddMinutes(-10)

# Znajdź wszystkie pliki o nazwie 'processing.lck' w folderze i podfolderach, w tym ukryte i systemowe
Get-ChildItem -Path $folderPath -Recurse -Filter "processing.lck" -Force | Where-Object {
    $_.LastWriteTime -lt $timeThreshold
} | ForEach-Object {
    try {
        # Usuń plik z użyciem przełącznika -Force
        Remove-Item -Path $_.FullName -Force
        Write-Host "Usunięto plik:" $_.FullName
    } catch {
        Write-Host "Błąd podczas usuwania pliku:" $_.FullName
    }
}
