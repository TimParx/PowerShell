# Put up some environment variables for the mail sending later on
$mailfrom = "dwg@xbpeurope.com"
#$mailto = "pldl_pl_teamleaders_nearshoring@exelaonline.com"
$mailto = "maciej.smolinski@xbpeurope.com"
#$mailcc = "sefrosonmanageroperations@exelaonline.com"
$subject = "test"
$body = "Hi!<br><br>test"
$attachment54 = "E:\Scripts\FF_OC_GLO_PROD.txt"
#$attachment55 = "E:\Transfer\kolla_5.5_ehi.txt"
$smtpserver = "smtp.gmail.com"

# Let's wait a while (2 minutes) to make sure all textfiles have completed
Start-Sleep -Second 120

# Send the csv files to intended recipiants
Send-MailMessage -From $mailfrom -To $mailto -Subject $subject -Body $body -BodyAsHtml -SmtpServer $smtpserver

