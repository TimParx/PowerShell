
$password = ConvertTo-SecureString "Abc12345" -AsPlainText -Force
$login = "se\masmolins"
$user = "$login"
$cred = New-Object System.Management.Automation.PSCredential ($user, $password)
$server = "btsevcipsapp01.se.ad.banctec.com"

# Enter-pssession -ComputerName $server –credential $cred
Invoke-Command {
    Select-String -path E:\jboss-4.2.2.GA\server\efp30\log\server.log -Pattern 'started in' | Out-String
} -computername $server -credential $cred
