# Użyj bieżącego katalogu, w którym skrypt jest uruchamiany
$folderPath = $PSScriptRoot

# Znajdź wszystkie pliki o nazwie 'error.lck' w folderze i podfolderach, w tym ukryte i systemowe
Get-ChildItem -Path $folderPath -Recurse -Filter "error.lck" -Force | ForEach-Object {
    try {
        # Usuń plik z użyciem przełącznika -Force
        Remove-Item -Path $_.FullName -Force
        Write-Host "Usunięto plik:" $_.FullName
    } catch {
        Write-Host "Błąd podczas usuwania pliku:" $_.FullName
    }
}
