$dpath = [Environment]::GetFolderPath("MyDocuments")
New-Item -Path $dpath -Name "SystemHealthReports" -ItemType "directory"
$fpath = "$dpath\SystemHealthReports"
Get-ChildItem -Path "." -Recurse | Move-Item -destination $fpath
write-host "Files Moved!"
$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-windowstyle hidden -File "'+$fpath+'\MainExec.ps1"')
$Trigger = New-ScheduledTaskTrigger -AtLogon
$Settings = New-ScheduledTaskSettingsSet
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings
Register-ScheduledTask -TaskName 'SystemHealthReports' -InputObject $Task
write-host "Task Scheduled!"
pause