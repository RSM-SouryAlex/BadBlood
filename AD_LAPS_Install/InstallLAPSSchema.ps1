
$scriptPath = Get-Location

Copy-Item -Path ($scriptpath + "\admpwd.ps") -Destination "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
Get-ChildItem -Path ($scriptpath + "\admpwd.ps") -Recurse | Foreach-object {
    Copy-Item -LiteralPath $_.fullname -Destination "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\admpwd.ps"
}
Copy-Item -Path ($scriptpath + "\AdmPwd.admx") -Destination "C:\Windows\PolicyDefinitions"
Copy-Item -Path ($scriptpath + "\AdmPwd.adml") -Destination "C:\Windows\PolicyDefinitions\en-US"

Import-Module ADMPwd.ps
Update-AdmPwdADSchema
Set-AdmPwdComputerSelfPermission -OrgUnit (Get-ADDomain).distinguishedname