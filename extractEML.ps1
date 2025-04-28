# Path to the folder containing EML files
$folderPath = "C:\temp\eml\emails"

# Base path for attachments
$attachmentsBasePath = "C:\temp\eml\files"

# Get the current timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create a new subfolder with the timestamp in the attachments folder
$attachmentsPath = Join-Path $attachmentsBasePath $timestamp
if (!(Test-Path -Path $attachmentsPath)) {
    New-Item -ItemType Directory -Path $attachmentsPath -Force | Out-Null
}

# Initialize Outlook application
try {
    $outlook = New-Object -ComObject Outlook.Application
} catch {
    Write-Error "Nie można zainicjalizować aplikacji Outlook. Upewnij się, że Outlook jest zainstalowany i skonfigurowany."
    exit 1
}

# Function to clean up COM objects
function Release-OutlookObject {
    param ([ref]$object)
    if ($object.Value -ne $null) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($object.Value) | Out-Null
        $object.Value = $null
    }
}

# Iterate through each .eml file in the folder
Get-ChildItem -Path $folderPath -Filter *.eml | ForEach-Object {
    $emlFile = $_.FullName
    Write-Host "Przetwarzanie pliku: $emlFile"
    try {
        # Sprawdź, czy plik jest dostępny do odczytu
        if (!(Test-Path $emlFile -PathType Leaf)) {
            Write-Warning "Plik niedostępny: $emlFile"
            return
        }

        # Open the EML file as a MailItem using OpenSharedItem
        try {
            $mailItem = $outlook.Session.OpenSharedItem($emlFile)
        } catch {
            throw "Nie można otworzyć pliku EML za pomocą OpenSharedItem. Upewnij się, że używasz odpowiedniej wersji Outlooka."
        }

        if ($mailItem -eq $null) {
            Write-Warning "Nie udało się otworzyć pliku EML: $emlFile"
            return
        }

        # Check if the email contains attachments
        if ($mailItem.Attachments.Count -gt 0) {
            foreach ($attachment in $mailItem.Attachments) {
                try {
                    # Get the attachment's file name
                    $attachmentName = $attachment.FileName

                    # Sanitize the attachment name to avoid invalid characters
                    $sanitizedAttachmentName = [System.IO.Path]::GetInvalidFileNameChars() | 
                        ForEach-Object { $attachmentName -replace [regex]::Escape($_), "_" }

                    $outputFilePath = Join-Path $attachmentsPath $sanitizedAttachmentName

                    # Save the attachment
                    $attachment.SaveAsFile($outputFilePath)
                    Write-Host "Załącznik zapisany: $outputFilePath"
                } catch {
                    Write-Warning "Nie udało się zapisać załącznika z pliku: $emlFile. Błąd: $_"
                }
            }
        }
        else {
            Write-Host "Brak załączników w pliku: $emlFile"
        }

        # Clean up MailItem object
        Release-OutlookObject -object ([ref]$mailItem)
    }
    catch {
        Write-Warning "Błąd podczas przetwarzania pliku: $emlFile. Błąd: $_"
    }
}

# Clean up Outlook COM object
Release-OutlookObject -object ([ref]$outlook)

Write-Host "Proces ekstrakcji załączników zakończony. Załączniki zapisane w: $attachmentsPath"
