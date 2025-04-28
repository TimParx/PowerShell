# Ścieżki do plików
$tokensFile = "C:\Users\MaSmolins.BTEC\My Drive\aws-token-folder\latest_tokens.txt"
$credentialsFile = "C:\Users\MaSmolins.BTEC\.aws\credentials"

# Wczytaj tokeny z pliku txt
$tokenContent = Get-Content $tokensFile -Raw

# Parsuj tokeny do hashtable
$tokenBlocks = ($tokenContent -split "\[") | Where-Object { $_ -match "_OP-DevOps\]" }

$updates = @{}

foreach ($block in $tokenBlocks) {
    if ($block -match "(\d+)_OP-DevOps\]\s+aws_access_key_id\s*=\s*(\S+)\s+aws_secret_access_key\s*=\s*(\S+)\s+aws_session_token\s*=\s*(\S+)") {
        $id = $matches[1]
        $updates["$id"] = @{
            AccessKey = $matches[2]
            SecretKey = $matches[3]
            SessionToken = $matches[4]
        }
    }
}

# Wczytaj obecny plik credentials jako linie
$lines = Get-Content $credentialsFile

# Nowe linie po modyfikacji
$newLines = @()
$currentSection = ""
foreach ($line in $lines) {
    if ($line -match "^\[(\d+)_OP-Admin\]") {
        $currentSection = $matches[1]
        $newLines += $line
        continue
    }

    if ($currentSection -ne "" -and $updates.ContainsKey($currentSection)) {
        if ($line -match "^aws_access_key_id") {
            $newLines += "aws_access_key_id = $($updates[$currentSection].AccessKey)"
            continue
        }
        elseif ($line -match "^aws_secret_access_key") {
            $newLines += "aws_secret_access_key = $($updates[$currentSection].SecretKey)"
            continue
        }
        elseif ($line -match "^aws_session_token") {
            $newLines += "aws_session_token = $($updates[$currentSection].SessionToken)"
            continue
        }
    }

    $newLines += $line
}

# Nadpisz oryginalny plik
$newLines | Set-Content $credentialsFile -Encoding UTF8

Write-Host "Plik credentials został zaktualizowany."
