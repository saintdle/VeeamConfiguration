#Read in powershell variables file
$Path = "P:\powershell_variables.txt"
$values = Get-Content $Path | Out-String | ConvertFrom-StringData


#Variable Decalration
$isoImg = "P:\${values.isoImg}"

#Mount ISO and Gather Drive Letter
Mount-DiskImage -ImagePath $isoImg -PassThru | Out-Null