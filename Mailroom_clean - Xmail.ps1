
Remove-Variable -Name server, Database, location, temp, xml_batches, duplicates, xml_batch, obrazy, batch, rozmiar, endorsery, query, baza, question, lista -ErrorAction SilentlyContinue
Remove-Variable -Name LogTime, logTime2, plik, xml, endorsery_duplicate, plik2, node, username_db, pwd_db  -ErrorAction SilentlyContinue
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"
$username_db = "GENERIC_DB_ReadOnly_SQL"
$pwd_db = "ZMwTuUFa7c"

$location = '\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\input'
$temp = '\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\temp'
$xml_batches = (Get-ChildItem $location).Name
$duplicates = @()
$LogTime = Get-Date -Format "yyyy-MM-dd_HH-mm"
$logTime2 = Get-Date -Format "yyyy-MM-dd"
 
#clean temp/output folder
Write-host 'Processing...'
Remove-Item "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\temp\*.*"
Remove-Item "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\output\*.*"

if ($xml_batches.count -gt 0) {

    foreach ($xml_batch in $xml_batches) {

        [xml]$file = Get-content $location\$xml_batch
        $obrazy = @()
        foreach ($batch in $file.Data.Batch.Page) {
        
            If ($batch.path.Length -gt 0) {
                $rozmiar = $batch.path.LastIndexOf("\")
                $obrazy += $batch.path.Substring($rozmiar + 1, 12)
            }
        }
        $endorsery = $obrazy | Select-Object -Unique
        # $obrazy | Select-Object -Unique >> "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\output\$xml_batch.txt"
        Write-host $xml_batch -ForegroundColor yellow
        foreach ($endorser in $endorsery) {
    
            $query = "
                use internportal
                SELECT
                Endorser,
                BatchName,
                DCN,
                convert(varchar, TimeStamp, 120) AS SentToFirefly,
                --FFBatchID,
                --ProcessName,
                d.Status,
                Customer
                --ProdDate,
                FROM [internportal].[Stats].[BatchDocumentStats] d right join [internportal].[Stats].[BatchStats] b on b.id = d.batchid
                where
                endorser like '$endorser%'
                --and (d.status = 'SENT TO FF' or d.status <> 'SCN CREATED')
                and d.Status like 'SENT TO FF%'
    
            "
            $baza = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query -Username $username_db -Password $pwd_db
            # $endorser | Select-Object @{n = "Endorser"; e = { $_ } }, @{n = "Batch"; e = { $baza.BatchName } }
            # $duplicates += $endorser | Select-Object @{n = "Endorser"; e = { $_ } }, @{n = "Batch"; e = { $baza.BatchName } }
    
            if ($baza.BatchName.count -gt 0) {
                Write-Host "$endorser | duplicate" "|" $baza.customer.Trim() "|" $baza.SentToFirefly "|" $baza.BatchName  
                $endorser >> $temp\$xml_batch
                $duplicates += $endorser | Select-Object @{n = "Endorser"; e = { $_ } }, @{n = "Customer"; e = {$baza.Customer.Trim()} }, @{n = "SentToFirefly"; e = {$baza.SentToFirefly} }, @{n = "Batch"; e = { $baza.BatchName } }
            }
            else {
                Write-Host "$endorser new"
            }
        }
    
        if ([IO.Directory]::Exists("\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\logs\$logTime")) {
            #Do Nothing!!
            # Write-Host 'Directory with date' $dir 'already exist'
            Start-Sleep -s 1
        }
        else {
            New-Item -ItemType directory -Path "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\logs\$logTime" | Out-Null
            Write-Host $logTime 'Directory has been created in logs catalog' -ForegroundColor Green
        }
        
        $duplicates | Export-Csv "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\logs\$logTime\$xml_batch.txt" -NoTypeInformation
    }
    
    $question = Read-Host -Prompt 'Do you want to clean the batches? y[yes], n[No]'
    
    If ($question -eq 'y') {
        Write-Host 'Cleaning in progress...'
        $lista = (Get-ChildItem "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\input").name
    
        foreach ($plik in $lista) {
            [xml]$xml = Get-Content "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\input\$plik"
            $endorsery_duplicate = Get-Content "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\temp\$plik" -ErrorAction SilentlyContinue
        
            foreach ($plik2 in $endorsery_duplicate) {
                $node = $xml.SelectSingleNode("//Data/Batch/Page[contains(@*,'$plik2')]")
                while ($null -ne $node) {
                    $node.ParentNode.RemoveChild($node)
                    $node = $xml.SelectSingleNode("//Data/Batch/Page[contains(@*,'$plik2')]")
                }
        
            }
        
            $xml.save("\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\output\$plik ")
    
        }
        Write-Host "Cleaning input catalog..."
        if ([IO.Directory]::Exists("\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\archive\$LogTime2\")) {
            #Do Nothing!!
            
        }
        else {
            New-Item -ItemType directory -Path "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\archive\$logTime2" | Out-Null
            Get-ChildItem $location | ForEach-Object { $PSItem.MoveTo("\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\MailroomDuplicates\archive\$LogTime2\" + $PSItem.name) }
        }
        
    }
    else {
        #Answer is No (or other) Do nothing
        Write-Host "Nothing has been cleaned"
    }
    
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to continue..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    }


}
else {
    Write-Host 'Nothing to process'
    
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to continue..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    }
}

