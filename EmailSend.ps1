$mailfrom = "maciej.smolinski@xbpeurope.com"
$mailto = "servicedesk@xbpeurope.com"

$subject = "test"
$body = "test"
$smtpserver = "relay.banctec.se"

Send-MailMessage -From $mailfrom -To $mailto -Subject $subject -Body $body -BodyAsHtml -SmtpServer $smtpserver