# Path to the folder containing EML files
$folderPath = "C:\temp\eml\emails"

# Path to the folder where attachments will be saved
$attachmentsPath = "C:\temp\eml\files"

# Ensure the attachments folder exists
if (!(Test-Path -Path $attachmentsPath)) {
    New-Item -ItemType Directory -Path $attachmentsPath -Force | Out-Null
}

# Path to the MimeKit DLL (update version if different)
$mimeKitPath = "C:\Users\<YourUsername>\.nuget\packages\mimekit\3.5.0\lib\netstandard2.0\MimeKit.dll"

# Load MimeKit
Add-Type -Path $mimeKitPath

# Iterate through each .eml file in the folder
Get-ChildItem -Path $folderPath -Filter *.eml | ForEach-Object {
    $emlFile = $_.FullName
    try {
        # Load the EML message
        $message = [MimeKit.MimeMessage]::Load($emlFile)

        # Check if the message contains attachments
        $attachments = $message.Attachments
        if ($attachments.Count -gt 0) {
            foreach ($attachment in $attachments) {
                # Determine the attachment's file name
                $fileName = $attachment.ContentDisposition?.FileName ?? $attachment.ContentType.Name
                if ([string]::IsNullOrEmpty($fileName)) {
                    # Generate a unique file name if no name is found
                    $fileName = [System.IO.Path]::GetRandomFileName()
                }

                # Path where the attachment will be saved
                $outputFilePath = Join-Path $attachmentsPath $fileName

                # Save the attachment
                if ($attachment -is [MimeKit.MimePart]) {
                    $attachment.Content.DecodeTo($outputFilePath)
                }
                elseif ($attachment -is [MimeKit.MessagePart]) {
                    $attachment.Message.WriteTo($outputFilePath)
                }

                Write-Host "Attachment saved: $outputFilePath"
            }
        }
        else {
            Write-Host "No attachments found in file: $emlFile"
        }
    }
    catch {
        Write-Warning "Error processing file: $emlFile. Error: $_"
    }
}

Write-Host "Attachment extraction process completed. Attachments saved in: $attachmentsPath"
