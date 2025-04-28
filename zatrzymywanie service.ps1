# stop the following Windows services in the specified order:
[Array] $Services = 'Spooler';

# loop through each service, if its running, stop it
foreach ($ServiceName in $Services) {
  $arrService = Get-Service -Name $ServiceName
  write-host $ServiceName
  while ($arrService.Status -eq 'Running') {
    Stop-Service $ServiceName
    write-host $arrService.status
    write-host 'Service stopping'
    Start-Sleep -seconds 60
    $arrService.Refresh()
    if ($arrService.Status -eq 'Stopped') {
      Write-Host 'Service is now Stopped'
    }
  }
}