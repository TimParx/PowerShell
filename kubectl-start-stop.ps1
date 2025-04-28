$select = Read-Host "
   Kubernetes Service Control:
1. Stop
2. Start
    Choose option"
Write-Host ""

if ($select -eq '1') {
    $confirmstop = Read-Host "    This will STOP kubernetes services for DMR EU platform - proceed? (y/n)"
    if ($confirmstop -eq 'y') {
        Write-Host ""
        Write-Host "    Stopping all services..."
        kubectl scale deployment exelaauth-deployment --replicas=0
        kubectl scale deployment dmrcore-deployment --replicas=0
        kubectl scale deployment dmrregcore-deployment --replicas=0
        kubectl scale deployment efaapi-deployment --replicas=0
        kubectl scale deployment dmr-ingester-deployment --replicas=0
        #kubectl scale deployment listen-deployment --replicas=0        #not used anymore, no need for restart
        #kubectl scale deployment redis-master --replicas=0             #not used anymore, no need for restart
        Write-Host "
    Sent STOP request to all required services, checking current status..."
        kubectl get deployment -o wide
        Write-Host "    Will refresh in 5 seconds..."
        sleep 5
        kubectl get deployment -o wide
        Write-Host "    Last refresh in 5 seconds..."
        sleep 5
        kubectl get deployment -o wide
        sleep 5
        exit
    }
    Write-Host "    No confirmation - closing"
    sleep 5
    exit
}
if ($select -eq '2') {
    $confirmstart = Read-Host "    This will START kubernetes services for DMR EU platform - proceed? (y/n)"
    if ($confirmstart -eq 'y') {
        Write-Host "    OK - Starting services in order:
        "
        Write-Host "1. ExelaAuth..."
        kubectl scale deployment exelaauth-deployment --replicas=1
        while ($value -ne "Running"){
            $text = $(kubectl describe pod -l app=exelaauth-app | sls "Status:")
            $status, $value = $text -split ":"
            $value = $value.Trim()
            }
        $value = "blank"
        Write-Host "    STARTED!"
        Write-Host "2. EfaApi..."
        kubectl scale deployment efaapi-deployment --replicas=1
        while ($value -ne "Running"){
            $text = $(kubectl describe pod -l app=efaapi-app | sls "Status:")
            $status, $value = $text -split ":"
            $value = $value.Trim()
            }
        $value = "blank"
        Write-Host "    STARTED!"
        Write-Host "3. DMRCore..."
        kubectl scale deployment dmrcore-deployment --replicas=1
        while ($value -ne "Running"){
            $text = $(kubectl describe pod -l app=dmrcore-app | sls "Status:")
            $status, $value = $text -split ":"
            $value = $value.Trim()
            }
        $value = "blank"
        Write-Host "    STARTED!"
        Write-Host "4. DMRRegCore..."
        kubectl scale deployment dmrregcore-deployment --replicas=1
        while ($value -ne "Running"){
            $text = $(kubectl describe pod -l app=dmrregcore-app | sls "Status:")
            $status, $value = $text -split ":"
            $value = $value.Trim()
            }
        $value = "blank"
        Write-Host "    STARTED!"
        Write-Host "5. DMRIngester..."
        kubectl scale deployment dmr-ingester-deployment --replicas=1
        while ($value -ne "Running"){
            $text = $(kubectl describe pod -l app=dmr-ingester-app | sls "Status:")
            $status, $value = $text -split ":"
            $value = $value.Trim()
            }
        $value = "blank"
        Write-Host "    STARTED!"
        Write-Host "
    Sent START request to all required services, checking current status..."
        kubectl get deployment -o wide
        sleep 5
        exit
    }
    Write-Host "    No confirmation - closing"
    sleep 5
    exit
}
else {
    Write-Host "    Invalid selection - closing"
    sleep 5
}