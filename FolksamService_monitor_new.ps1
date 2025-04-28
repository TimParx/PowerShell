


$password = ConvertTo-SecureString "Abc12345" -AsPlainText -Force
$login = "se\masmolins"
$user = "$login"
$cred = New-Object System.Management.Automation.PSCredential ($user, $password)
$server = "btsevlev02.se.ad.banctec.com"
$log_file = "c:\temp\monitor.log"

Invoke-Command {

    Remove-Variable -name ServiceName, ProcessName, arrService, godzina, godzina2, godzina3, procesID, arrService2, procesIDNew, data_down  -ErrorAction SilentlyContinue

    #setting variables - processName, serviceName
    $ServiceName = 'Spooler'
    $ProcessName = 'Print Spooler'
    $arrService = Get-Service -Name $ServiceName
    
    #if service is not running
    if ($arrService.status -ne 'Running') {
        $data_down = get-date -Format "yyyy-MM-dd_HH.mm"
        $godzina = get-date -Format HH:mm
        write-host "$godzina Service is now stopped!" -ForegroundColor white -BackgroundColor red
        "$data_down Service is stopped" >> $using:log_file
        
        #starting the service
        try {
            #start service
            Start-Service $ServiceName
            write-host "Starting $ServiceName ..."
        }
        catch {
            Write-Host "Problem with starting service $ServiceName"
        }
        Start-Sleep -s 2
        $arrService.Refresh()

        #check if servive is up again
        if ($arrService.status -eq 'Running') {
            $PID_process = Get-Process -name $ProcessName | Select-Object -expand id -ErrorAction SilentlyContinue
            $godzina3 = get-date -Format HH:mm
            write-host "$godzina3 Service is up again. PID: $PID_process"
            Get-Service -Name $ServiceName
            Write-Host ''
        }
        else {
            Write-host 'Manual actions required'
        }

    }
    #if service is running
    else {
        $godzina2 = get-date -Format HH:mm
        Write-Host "$godzina2 Service is up and Running"
        # Write-Host 'Checking engines...'
        write-host 'Service is up'
    }

    $arrService.Refresh()
    # Start-Sleep -s 10

} -computername $server -credential $cred