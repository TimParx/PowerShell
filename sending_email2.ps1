# Put up some environment variables for the mail sending later on
$mailfrom = "donotreply-se@exelaonline.com"
#$mailto = "pldl_pl_teamleaders_nearshoring@exelaonline.com"
$mailto = "tomas.skoglund@exelaonline.com"
#$mailcc = "sefrosonmanageroperations@exelaonline.com"
$subject = "Tempfiles in FF_OC_GLO_PROD"
$body = "Hi!<br><br>Attached files contain a list of temporary files left in account FF_OC_GLO_PROD.<br><br><br>Br, Skogis"
$attachment54 = "E:\Scripts\FF_OC_GLO_PROD.txt"
#$attachment55 = "E:\Transfer\kolla_5.5_ehi.txt"
$smtpserver = "10.34.110.200"

# Let's wait a while (2 minutes) to make sure all textfiles have completed
Start-Sleep -Second 120

# Send the csv files to intended recipiants
Send-MailMessage -From $mailfrom -To $mailto -Cc $mailcc -Subject $subject -Body $body -BodyAsHtml -Attachments $attachment54 -SmtpServer $smtpserver

# Remove the csv file after it have been sent with mail.
Remove-Item E:\Scripts\FF_OC_GLO_PROD.txt
#Remove-Item E:\Transfer\kolla_5.5_ehi.txt
