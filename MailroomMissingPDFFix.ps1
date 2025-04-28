Import-Module SqlServer

#dummy source file
$Source = "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\KarcherBatchError\whitepage.pdf"

#credentials using on exse-vffefi01.se.ad.banctec.com
$Username = "se\masmolins"
$password = ConvertTo-SecureString "Abc12345" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($Username, $password)

$targetComputerName = "exse-vffefi01.se.ad.banctec.com"

#command to use on remote session. Moving XMLs from error to index1
$scriptBlock = {
    move-item -Path E:\Data\Email\error\*.xml -Destination E:\Data\Email\index1
}

#setting sql server
$server = "btsevcipssql01.se.ad.banctec.com"
$Database = "internportal"

$query = "
declare @today as date;
------date----------------
set @today = GETDATE() + 1;

SELECT DISTINCT
customer,
BatchName,
EmailID,
CONCAT(EmailID, '.pdf') as FileName,
CONCAT('\\exse-vffefi01.se.ad.banctec.com\e$\Data\Email\images\', BatchName, '\', EmailID, '.pdf') as TargetFile,
CONCAT('\\exse-vffefi01.se.ad.banctec.com\e$\Data\Email\images\', BatchName) as TargetPath,
b.status,
d.Status
,ReceivedDate
FROM [internportal].[Stats].[BatchStats] as b with (nolock) join [internportal].[Stats].[BatchDocumentStats] as d  with (nolock) on b.id = d.batchid
where
(
customer like '%EXAKDE1%'
or customer like '%EXAFDE0%'
or customer like '%EXAKDE%'
or customer like '%EXAFUS0%'
or customer like '%EXATRD0%'
or customer like '%EXPSKS0%'
or customer like '%EXA%'


)
--BatchName like 'EXA-KDE1BE10.kaercher.invoice_FF_EMAIL_20230406_5884'
and b.status like 'ERROR'
and Source like 'EMAIL%'
and Started between DateAdd(D, -5, @today) and @today

"

$baza = Invoke-Sqlcmd -ServerInstance $server -Database $Database -Query $Query

# $n = -1

foreach ($file in $baza) {
        # Sprawdzenie, czy plik istnieje i czy jego rozmiar jest większy niż 0
        if (Test-Path $file -PathType Leaf -ErrorAction SilentlyContinue) {
            $rozmiar = (Get-Item $baza).Length
            if ($rozmiar -gt 0) {
                Write-Output "Plik $file jest OK."
            }
            else {
                # $file.TargetFile
                Write-Host "To fix" $file.TargetFile

                #openning session to exse-vffefi01.se.ad.banctec.com
                $Session = New-PSSession $targetComputerName -Credential $cred

                # #coppying files to temp folder on local computer
                $OutPutFile = "C:\temp\karcher\" + $file.EmailID + ".pdf"
                Copy-Item -Path $Source -Destination $OutPutFile -Force

                # #coppying file to remote path from local temo folder
                $DestinationPath = "E:\Data\Email\images\" + $file.BatchName
                Copy-Item -Path $OutPutFile -ToSession $Session -Destination $DestinationPath

                #closing session
                $Session | Remove-PSSession

                # Moving XMLs from error to index1
                Invoke-Command -ScriptBlock $scriptBlock -ComputerName $targetComputerName -Credential $cred

            }
        }
        else {
            # Copy-Item -Path $sciezkaDoZdefiniowanegoPliku -Destination $sciezkaDoPliku -Force
            Write-Output "plik nie istnieje lub ma 0 KB."

            # $file.TargetFile
            Write-Host "To fix" $file.TargetFile

            #openning session to exse-vffefi01.se.ad.banctec.com
            $Session = New-PSSession $targetComputerName -Credential $cred
            
            # #coppying files to temp folder on local computer
            $OutPutFile = "C:\temp\karcher\" + $file.EmailID + ".pdf"
            Copy-Item -Path $Source -Destination $OutPutFile -Force
            
            # #coppying file to remote path from local temo folder
            $DestinationPath = "E:\Data\Email\images\" + $file.BatchName
            Copy-Item -Path $OutPutFile -ToSession $Session -Destination $DestinationPath
            
            #closing session
            $Session | Remove-PSSession
            
            # Moving XMLs from error to index1
            Invoke-Command -ScriptBlock $scriptBlock -ComputerName $targetComputerName -Credential $cred
        }
    }




