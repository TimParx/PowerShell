This is what I use to reset-passwords. I load the function when powershell loads so i just type

reset-password -user <username> -password <password> -changePasswordatLogon <true or false>

Powershell
Function Verify-Account {
    [CmdLetBinding()]
     Param ([Parameter(Mandatory=$true)]
           [System.String]$user,
           [System.String]$domain = $null)
        
    $idrefUser = $null
    $strUsername = $user
    If ($domain) {
        $strUsername += [String]("@" + $domain)
    }
        
    Try {
        $idrefUser = ([System.Security.Principal.NTAccount]($strUsername)).Translate([System.Security.Principal.SecurityIdentifier])
    }
    Catch [System.Security.Principal.IdentityNotMappedException] {
        $idrefUser = $null
    }
           
    If ($idrefUser) {
        return $true
    }
    Else {
        return $false
    }
}

<#
.Synopsis
   This will reset a users password.
.DESCRIPTION
   This will reset a Users Password
   Unlock the Users Account
   Ask User to change password on next log in
.PARAMETER User
   Enter the username you want to change the password for
.PARAMETER Password
   Enter the (One - Time) use password.
.EXAMPLE
   Reset-Password -user bob.smith -password 12345
#>

Function Reset-Password
{
    [CmdLetBinding()]    
    Param (
        [Parameter(Mandatory=$True)]
        [string]$user,
        [string]$password,
        [string]$changeNextLogon
    )
    
    Begin {
        #Verifies the User Account Exists
        $result = Verify-Account -user $user

        #Imports the Active Directory Module
        #$ADsession = New-PSSession -Computername dc2 -Credential $cred
        #Invoke-Command -Session $ADsession {Import-Module ActiveDirectory}
        #Import-PSSession -Session $ADsession -Module ActiveDirectory | Out-Null
    }

    Process {
       If ($result -eq "True"){
           #Checks for Password Never Expires $True
           $expires = Get-Aduser $user -Properties PasswordNeverExpires| Select PasswordNeverExpires
            If ($expires.PasswordNeverExpires -eq $true) {
            #Changes Password Never Expires to False                     
            Set-ADUser $user -PasswordNeverExpires $false -Credential $cred
            }

        #Resets Username / Password & Unlocks Account if needed        
        Set-ADAccountPassword $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force) -Credential $cred
        #Sets Change PasswordAtLogon to True
            If ($changeNextLogon -eq "true") {
            Set-ADUser $user -ChangePasswordAtLogon $true -Credential $cred
            } Else {
            Set-ADUser $user -ChangePasswordAtLogon $false -Credential $cred
            }
        #Unlocks Users Account if needed
        Unlock-ADAccount $user -Credential $cred
        Write-Host "$user's password has been changed and account has been unlocked!" -ForegroundColor Green
        } Else {
            Write-Warning "Username: $user is Not Found. Please Try Again!" 
        }                      
    } 

    End {
        #Remove-PSSession -Session $ADsession
    }
} # End Function