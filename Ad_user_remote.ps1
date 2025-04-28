

Write-Host 'Importing csv file...'
Start-Sleep -s 1
$home_folder = "\\btsevlev03.se.ad.banctec.com\Program\Servicedesk\ActiveDirectory"
$countfiles1 = Get-Content "$home_folder\input\lista.csv" | Measure-Object -Line
$countfilesInteger1 = $countfiles1.Lines - 1

$lista = Import-Csv "$home_folder\input\lista.csv" -Delimiter ';'

Write-Host "You are about to add $countfilesInteger1 accounts"
$question = Read-Host "Do you want to proceed y[Yes], n[No]"

if ($question -eq "y") {

    Write-Host 'Connecting to the Active Directory server...'
    Start-Sleep -s 1
    
    Invoke-Command { 

        # Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        Remove-Variable -Name example, path, grupa, dnsroot, user, username -ErrorAction SilentlyContinue
    
        $username = Read-Host 'Enter UserId to coppy from'
    
        try {
            Get-ADUser $username -ErrorAction Stop | Out-Null
            $example = $username
        } 
        Catch { "$username does not exist in AD" }
        ##########
        
        if ($example) {
            
            #password
            $defpassword = (ConvertTo-SecureString "Abc12345" -AsPlainText -force)
            #OU path
            $path = (Get-AdUser $example).distinguishedName.Split(',', 2)[1]
            #Groups    
            $grupa = (Get-ADUser $example -Properties MemberOf).MemberOf
            # Get domain DNS suffix
            $dnsroot = '@' + (Get-ADDomain).dnsroot
            # Import the file with the users. You can change the filename to reflect your file
            $users = $using:lista
            Write-Host "New accounts:"
            foreach ($user in $users) {
                # $orgunit = $user.OrganizationalUnit
                # $memberof = $user.GroupMember
                # Write-Host $fname
                #Write-Host $memberof
                #New-AdUser -name $fullname -GivenName $fname -Surname $lname -UserPrincipalName $userid
                try {
                
                    New-ADUser -SamAccountName $user.UserID -Name ($user.FirstName + " " + $user.LastName) `
                        -DisplayName ($user.FirstName + " " + $user.LastName) -GivenName $user.FirstName -Surname $user.LastName `
                        -EmailAddress ($user.UserID + $dnsroot) -UserPrincipalName ($user.UserID + $dnsroot) `
                        -Title 'user' -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires  $true `
                        -AccountPassword $defpassword -PassThru `
                        -Path $path `
                    
                    #setting groups
                    $grupa | Add-ADGroupMember -Members $user.UserID
                }
                catch [System.Object] {
                    Write-Output "Could not create user $($user.UserID), $_"
                } 
            }
        
        }
    
    } -computername BTSEVPRGDC01.prg.se -credential prg\administrator
}

Else {

    write-host 'Nothing to do'
}
if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
