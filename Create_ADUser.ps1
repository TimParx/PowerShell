
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
Remove-Variable -Name example -ErrorAction SilentlyContinue
# set default password
# change pass@word1 to whatever you want the account passwords to be
Write-Host 'Importing csv file...'
Start-Sleep -s 1
$countfiles1 = Get-Content C:\temp\lista.csv | Measure-Object -Line
$countfilesInteger1 = $countfiles1.Lines - 1


Write-Host "You are about to add $countfilesInteger1 accounts"
# Import-Csv C:\temp\lista.csv -Delimiter ';'

###########
$username = Read-Host 'Enter UserId to coppy from'

try {
    Get-ADUser $username -ErrorAction Stop
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
    $grupa = (Get-ADUser $example –Properties MemberOf).MemberOf
    # Get domain DNS suffix
    $dnsroot = '@' + (Get-ADDomain).dnsroot
    # Import the file with the users. You can change the filename to reflect your file
    $users = Import-Csv C:\temp\lista.csv -Delimiter ';'

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


