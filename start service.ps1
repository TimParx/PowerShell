# start the following Windows services in the specified order:
[Array] $Services = 'Service1','Service2','Service3','Service4','Service5';

# loop through each service, if its not running, start it
foreach($ServiceName in $Services)
{
    $arrService = Get-Service -Name $ServiceName
    write-host $ServiceName
    while ($arrService.Status -ne 'Running')
    {
        Start-Service $ServiceName
        write-host $arrService.status
        write-host 'Service starting'
        Start-Sleep -seconds 60
        $arrService.Refresh()
        if ($arrService.Status -eq 'Running')
        {
          Write-Host 'Service is now Running'
        }
    }
}