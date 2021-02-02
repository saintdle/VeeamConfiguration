#Enable PowerShell Remote
Enable-PSRemoting -Force

#Read in powershell variables file
$Path = "$PSScriptRoot\powershell_variables.txt"
$values = Get-Content $Path | Out-String | ConvertFrom-StringData

#Share User creds
$User = $values.ShareUser
$PWord = ConvertTo-SecureString -String $values.SharePword -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

#Disable Local Firewall
Set-NetFirewallProfile -Profile * -Enabled False

#Restart WinRM Service
Restart-Service WinRM

#Powershell security setting so we can run our scripts
set-executionpolicy bypass -Force

#Create Veeam Service Account
New-LocalUser -AccountNeverExpires:$true -Password ( ConvertTo-SecureString -AsPlainText -Force $values.vbrserverpass) -Name $values.vbrserveraccount | Add-LocalGroupMember -Group administrators

#Mount remote shares for scripts
New-PSDrive -Name "P" -Root $values.pdrive -Persist -PSProvider "FileSystem" -Credential $cred
New-PSDrive -Name "V" -Root $values.vdrive -Persist -PSProvider "FileSystem" -Credential $cred

Powershell.exe -file V:\MountVBR_ISO.ps1

Powershell.exe -Command V:\Install_Veeam.ps1 -InstallOption VBRServerInstall
Write-Progress -Activity "Import Module" 
Start-Sleep -s 600

Import-Module Veeam.Backup.PowerShell

Get-VBRserver

Powershell.exe -file V:\VeeamConfiguration.ps1
