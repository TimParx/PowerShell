param (
    [string]$txtFilePath
)

Import-Module SqlServer

# Function to validate the identifiers
function Validate-EmailID ($EmailID) {
    if ($EmailID -match '^FF[PT]\d{11}$') {
        return $true
    }
    else {
        return $false
    }
}

# Check if the txtFilePath parameter was provided
if ($txtFilePath) {
    if (-not (Test-Path $txtFilePath)) {
        Write-Host "The provided file path is not valid." -ForegroundColor Red
        exit
    }
    
    # Reading the identifiers from the file
    $EmailIDs = Get-Content -Path $txtFilePath

    if ($EmailIDs.Count -eq 0) {
        Write-Host "The file is empty." -ForegroundColor Red
        exit
    }

    # Finding duplicates
    $UniqueEmailIDs = $EmailIDs | Select-Object -Unique
    $DuplicateEmailIDs = $EmailIDs | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name

    # Inform about duplicates if any are found
    if ($DuplicateEmailIDs.Count -gt 0) {
        Write-Host "The following duplicate EmailIDs were found and will be skipped:" -ForegroundColor Yellow
        $DuplicateEmailIDs | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    }

    # Using unique identifiers
    $EmailIDs = $UniqueEmailIDs

    foreach ($EmailID in $EmailIDs) {
        if (-not (Validate-EmailID $EmailID)) {
            Write-Host "Invalid EmailID found in file: $EmailID" -ForegroundColor Red
            exit
        }
    }
}
else {
    $EmailID = Read-Host 'Please provide EmailID'
    if (-not $EmailID) {
        Write-Host "EmailID is required." -ForegroundColor Red
        exit
    }

    if (-not (Validate-EmailID $EmailID)) {
        Write-Host "Invalid EmailID format: $EmailID" -ForegroundColor Red
        exit
    }

    $EmailIDs = @($EmailID)
}

# SQL Server settings
$server = "10.34.43.160,2001"
$Database = "EmailArchive"

# Variable to track if the folder has already been opened
$folderOpened = $false
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$temp_catalog = "c:\temp\emailarchive\$timestamp"

# Create the timestamp folder
New-Item -ItemType Directory -Path $temp_catalog -Force | Out-Null

# Path to the single CSV file
$csvFilePath = Join-Path -Path $temp_catalog -ChildPath "$timestamp.csv"
$firstWrite = $true  # Flag to write headers only once

foreach ($EmailID in $EmailIDs) {
    Write-Host "Searching for $EmailID in the database..."
    
    $query = "
    declare @today as date;

    ------date----------------
    set @today = GETDATE() + 1;
    --------------------------
    SELECT distinct
        convert(varchar(10), receivedDate, 120) AS Date,
        a.[emailID],
        a.[serviceID],
        convert(varchar, a.[receivedDate], 120) as ReceivedDate,
        convert(varchar, a.[createdDate], 120) as CreatedDate,
        a.[receivedBy],
        a.[account],
        CASE
            WHEN LEFT(a.[messageFile], 4) = '\\ex'
            THEN a.[messageFile]
            ELSE concat('\\exse-vffefi01.se.ad.banctec.com\e$', RIGHT(a.[messageFile],LEN(a.messageFile) -2))
        end as 'EMLpath',
        a.[sender],
        a.[subject],
        a.[status],
        a.[attachments],
        a.[ignoredAttachments],
        a.[lastProcessedBy],
        a.[returnAddress],
        a.[returnedOn],
        a.[rejectReason]
    FROM [EmailArchive].[dbo].[EmailArchive] a 
    LEFT JOIN [EmailArchive].[dbo].[EmailAttachments] b 
    ON a.emailID = b.fkEmailID
    WHERE
    [receivedDate] BETWEEN DateAdd(D, -130, @today) AND @today
    AND a.[emailID] LIKE '%$EmailID%'
    ORDER BY [receivedDate]
    "

    $baza = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $query

    if ($baza.emailID.Count -gt 0) {
        $baza

        # Open the folder only once when the first file is found
        if (-not $folderOpened) {
            Invoke-Item $temp_catalog  # Opens the folder when the first file is found
            $folderOpened = $true
        }

        # Copy the files
        foreach ($emlPath in $baza.EMLpath) {
            if (Test-Path $emlPath) {
                Copy-Item -Path $emlPath -Destination $temp_catalog
            }
            else {
                Write-Host "File not found: $emlPath" -ForegroundColor Yellow
            }
        }

        # Exporting results to the single CSV file
        if ($firstWrite) {
            $baza | Export-Csv -Path $csvFilePath -NoTypeInformation
            $firstWrite = $false  # Headers have been written, set the flag to false
        }
        else {
            $baza | Export-Csv -Path $csvFilePath -NoTypeInformation -Append
        }

        Write-Host "Results for $EmailID have been added to $csvFilePath" -ForegroundColor Green
    }
    else {
        Write-Host "$EmailID not found in DB" -ForegroundColor Red
    }
}

if ($Host.Name -eq "ConsoleHost") {
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
