#Read in powershell variables file
$Path = "P:\powershell_variables.txt"
$values = Get-Content $Path | Out-String | ConvertFrom-StringData

#This will check the Veeam service has started and is running 

$svc = Get-Service VeeamBackupSvc
$svc.WaitForStatus('Running')
Write-Progress -Activity "Waiting for Veeam services to start"

 
#XFSRepo_name = "TPM04-VBR-XFS-Rep01"
#XFSRepo_IP = "10.0.40.123"

#Variables
Add-VBRCredentials -User $values.vbrcredsdomain -Password $values.vbrcredsdomainpass -Description $values.vbrcredsdomaindesc
Add-VBRCredentials -type Linux -User $values.vbrcredscentos -Password $values.vbrcredscentospass -Description $values.vbrcredscentosdesc
Add-VBRCredentials -type Linux -User $values.vbrcredsubuntu -Password $values.vbrcredsubuntupass -Description $values.vbrcredsubuntudesc

$WindowsCredential = Get-VBRCredentials -name $values.vbrcredsdomain
$CentOSCredential = get-vbrcredentials | where {$_.description -like "${values.vbrcredscentosdesc}"}
$UbuntuOSCredential = get-vbrcredentials | where {$_.description -like "${$values.vbrcredsubuntudesc}"}

$vbrserver = $env:computername
$WinProxy = $values.WinProxy
$WinProxyName = $values.WinProxyyName
$LinProxy = $values.LinProxy


#Add Windows Proxy 
Add-VBRWinServer -Name $WinProxyName -Description "Windows File & VMware Proxy" -Credentials $WindowsCredential -ErrorAction Stop | Out-Null
Add-VBRViProxy -Server $WinProxyName 
Add-VBRNASProxyServer -Server $WinProxyName -ConcurrentTaskNumber 2 | Out-Null

#Add Linux Proxy 
Add-VBRLinux -Name $LinProxy -Description "Linux VMware Proxy" -Credentials $CentOSCredential -ErrorAction Stop | Out-Null 
Add-VBRViLinuxProxy -Server $LinProxy

#Add Linux Repository 
#add managed server (single access credentials) 
#add repository role with XFS and Immutable flag 

#Add vSphere Environment
Add-VBRvCenter -Name $values.vcenter -User $values.vcenteruser -Password $values.vcenterpass -Description $vallues.vcenterdesc

#Add NAS Share 
Resize-Partition -DriveLetter C -Size $(Get-PartitionSupportedSize -DriveLetter C).SizeMax
new-item c:\CacheRepository -itemtype directory
Add-VBRBackupRepository -Name "NAS Cache Repository" -Server $vbrserver -Folder "c:\CacheRepository" -Type WinLocal
$CacheRepository = Get-VBRBackupRepository -Name "NAS Cache Repository"
Add-VBRNASSMBServer -Path $values.vbrnassmbserver -AccessCredentials $WindowsCredential -CacheRepository $CacheRepository

#Create Scale Out Backup Repository
new-item c:\PerformanceTier -itemtype directory
Add-VBRBackupRepository -Name "Performance Tier" -Server $vbrserver -Folder "c:\PerformanceTier" -Type WinLocal
Add-VBRScaleOutBackupRepository -Name "Veeam Scale-Out Repository" –PolicyType Performance –Extent “Performance Tier”
$repository = Get-VBRBackupRepository -ScaleOut -Name "Veeam Scale-Out Repository"

#Add Capacity Tier
#AWS
#Azure Storage - Possibly have something on home desktop machine to test. 
#GCP

#Create Veeam VMware Backup Job 
Find-VBRViEntity -Name $values.centosvm | Add-VBRViBackupJob -Name "VMware - Web Server Backup" -BackupRepository $repository -Description "Automated VMware Web Server Backup"

#Create NAS Backup job 
$NASserver = Get-VBRNASServer -Name $values.vbrnassmbserver
$NASobject = New-VBRNASBackupJobObject -Server $NASserver -Path $values.vbrnassmbserver
Add-VBRNASBackupJob -BackupObject $NASobject -ShortTermBackupRepository $repository -Name "NAS Backup Job" -Description "Automated VMware Web Server Backup"

#Create Virtual Lab 
#Create Application Group 
#Create SureBackup Job 