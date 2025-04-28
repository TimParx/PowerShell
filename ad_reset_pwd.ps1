
Invoke-Command { $users = Read-Host 'User account'


    $input = $users.Split(",").Trim()


    foreach ($user in $input) {

        if ($user -match '[a-z]{2}[0-9]{4}') {
            try {
                Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "Abc12345" -Force)
                Set-ADUser -Identity $user -ChangePasswordAtLogon $false -PasswordNeverExpires $true
                Unlock-ADAccount -Identity $user
                Write-Host "$user - Password has been changed. Account has been unlocked"
                
            }
            catch {
                Write-Host "User $user doesn't exist"
            }

        }
        else {
            # Get-ADUser -Filter "Name -like '*$user*'" | Format-Table Name, SamAccountName -A do poprawki jeszcze trzeba check zrobić
            $b = Get-ADUser -Filter "Name -like '*$user*'" 
           
            if ($b) {
                Write-Host "User $user found in AD"
                $b | Select-Object Name, SamAccountName
                $user2 = Read-Host 'Please provide the UserID'

                try {
                    Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "Abc12345" -Force)
                    Set-ADUser -Identity $user -ChangePasswordAtLogon $false -PasswordNeverExpires $true
                    Unlock-ADAccount -Identity $user
                    Write-Host "$user2 - Password has been changed. Account has been unlocked"
                
                }
                catch {
    
                    Write-Host "Problem with $user2 account"
    
                }

            }
            Else {
                Write-Host "$user1 not found"
            }

        }

    }

} -computername BTSEVPRGDC01.prg.se -credential prg\administrator

if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}

# $test = "ab1244, hg2432,hg2103,    d2jsaqk"

# $test.Split(",").Trim()