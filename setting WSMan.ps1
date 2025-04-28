
#changing Public network to Private
if (Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -match "Private" }){
Write-host changing Public network to Private
Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -match "Public" } | Set-NetConnectionProfile -NetworkCategory Private
}
Else{
Write-Host No found public network
}

#setting PSRemoting
Write-Host setting PSRemoting
Try{
test-wsman -ErrorAction stop | Out-Null

} catch{
    Enable-PSRemoting -SkipNetworkProfileCheck -force
}

#setting winRm
Write-Host setting winRm
winrm quickconfig -force
#setting TrustedHosts
Write-Host setting TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value btsepeng04.se.ad.banctec.com -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value btsepeng01.se.ad.banctec.com -Concatenate -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value btsepeng02.se.ad.banctec.com -Concatenate -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value btseveng15.se.ad.banctec.com -Concatenate -Force
#checking TrustedHosts
Write-Host checking TrustedHosts
Get-Item WSMan:\localhost\Client\TrustedHosts 