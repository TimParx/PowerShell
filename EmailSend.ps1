$mailfrom = "exelasetest@euprod.exelaonline.com"
$mailto = "timo-ai.helpdesk@xbpeurope.com"

$subject = "test"
$body = "test"
$smtpserver = "10.34.110.180"

Send-MailMessage -From $mailfrom -To $mailto -Subject $subject -Body $body -BodyAsHtml -SmtpServer $smtpserver