# Definicja mapowania polskich znaków specjalnych na zwykłe odpowiedniki
$replaceChars = @{
    'ó'='o'
   
}

# Funkcja usuwająca polskie znaki specjalne z tekstu
function Remove-SpecialChars {
    param([string]$text)
    foreach ($key in $replaceChars.Keys) {
        $text = $text -replace $key, $replaceChars[$key]
    }
    return $text
}

# Funkcja usuwająca linie zaczynające się od spacji
function Remove-LinesStartingWithSpace {
    param([string[]]$lines)
    return $lines | Where-Object { $_ -notmatch '^\s' }
}

# Przejście przez wszystkie podkatalogi i przetwarzanie plików
$directory = Get-Location  # Pobiera bieżący katalog, w którym uruchomiono skrypt

Get-ChildItem -Path $directory -Recurse -Filter *.txt | ForEach-Object {
    $filePath = $_.FullName
    $content = Get-Content $filePath
    
    # Usuwanie linii zaczynających się od spacji
    $content = Remove-LinesStartingWithSpace $content
    
    # Usuwanie polskich znaków specjalnych
    $content = $content | ForEach-Object { Remove-SpecialChars $_ }
    
    # Zapis zmodyfikowanej treści do tego samego pliku
    Set-Content -Path $filePath -Value $content
}

Write-Host "Zakończono przetwarzanie plików."