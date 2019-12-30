$dpath = [Environment]::GetFolderPath("MyDocuments")
$fpath = "$dpath\SystemHealthReports"

Write-Host "Initizalizing System Report."
Write-Host "-------------------------------"
#Run system report script.
.("$fpath\GetSystemReport.ps1")

Write-Host "Done."
Write-Host "-------------------------------"

Write-Host "Writing Reports to Collection."
Write-Host "-------------------------------"
#Add Files to Text Document.

Get-childitem -path "$fpath\Reports\" -rec -file | Sort-Object LastWriteTime -Descending | select-object -expandproperty name | out-file "$fpath\FileList.txt"

Write-Host "Done."
Write-Host "-------------------------------"

Write-Host "Updating Reports Page."
Write-Host "-------------------------------"
#Run HTML script.
.("$fpath\CreateHTML.ps1")

Write-Host "-------------------------------"
Write-Host "Done."
Write-Host "-------------------------------"

#Delete old reports.
Write-Host "Deleting Reports older than 30days."
Write-Host "-------------------------------"
$Daysback = "-30" 
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
Get-ChildItem "$fpath\Reports" | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
Write-Host "Done."
Write-Host "-------------------------------"
Pause