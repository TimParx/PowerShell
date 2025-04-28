
$FolderPath = "\\exse-vffefi01.se.ad.banctec.com\c$\Exela\Email\config"


if (!(Test-Path -Path $FolderPath)) {
    Write-Output "Folder does not exist."
    exit
}


$xmlFiles = Get-ChildItem -Path $FolderPath -Filter *.xml

foreach ($file in $xmlFiles) {
    try {
        # Load the XML file
        $xmlContent = [xml](Get-Content -Path $file.FullName)


        $accounts = $xmlContent.SelectNodes("//EmailReader/Platform/Account")

        foreach ($account in $accounts) {
            # Extract information
            $hostValue = $account.SelectSingleNode("Host")?.InnerText
            $usernameValue = $account.SelectSingleNode("Username")?.InnerText
            $passwordValue = $account.SelectSingleNode("Password")?.InnerText


            Write-Output "File: $($file.Name)"
            Write-Output "Host: $hostValue"
            Write-Output "Username: $usernameValue"
            Write-Output "Password: $passwordValue"
            Write-Output "---------------------------"
        }
    } catch {
        Write-Output "Error processing file $($file.Name): $_"
    }
}
