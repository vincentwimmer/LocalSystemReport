$dpath = [Environment]::GetFolderPath("MyDocuments")
$fpath = "$dpath\SystemHealthReports"

$Style = "
<style>
    #header {
        position: relative;
        background-color: #403d4e;
        border: none;
        color: #FFFFFF;
        padding: 30px;
        text-align: center;
    }

    #section {
    	position: relative;
        outline: 1px solid #3d3b46;
        padding: 4px;
    }

    #warning {
    	background-image: linear-gradient(to top right, #fc9a21, #ffbc69);
    }

    #error {
        background-image: linear-gradient(to top right, #e62117, #ff6159);
    }

    #running {
        background-image: linear-gradient(to top right, #11d11a, #61ff68);
    }

    BODY {
        background-color: #292533;
        color: #a9a6b7;
        font-family: Arial, Helvetica, sans-serif;
        max-width: 950px;
        margin: auto;
        margin-top:0px;
    }

    TABLE {
        border-collapse: collapse;
        margin: auto;
        max-width: 950px;
    }

    TH {
        background-color: #3d3b46;
        font-size: 14px;
        text-align: left;
        margin: auto;
        border-bottom-style: solid;
        border-bottom-color: #5c586d;
        border-bottom-width: 1px;
        width: 550px;
    }

    TD {
        padding: 3px;
        margin: auto;
        border-top-style: solid;
        border-top-color: #5c586d;
        border-top-width: 1px;
    }

    tr:nth-child(odd) {
        background-color: #3d3b46;
    }

    tr:nth-child(even) {
        background-color: #3d3b46;
    }

    h1 {
        color: #fafafa;
    }

    h2 {
        color: #fafafa;
    }

    h3 {
        color: #fafafa;
    }

    h4 {
        font-size: 28px;
        margin-top: 0px;
        margin-bottom: 15px;
    }

    hr { 
        margin-top: 0px;
        margin-bottom: 15px;
        margin-left: 35%;
        margin-right: 35%;
        border-style: solid;
        border-width: 1px;
    }

    warncolor {
        font-size: 14px;
        color: #d67600;
    }

    errcolor {
        font-size: 14px;
        color: #c30a00;
    }

    runcolor {
        font-size: 14px;
        color: #00af09;
    }
</style>
"
$newline = "<br>"
$closediv = "</div>"
$StatusColor = @{Stopped = ' id="error" align="center"><errcolor>Stopped</errcolor><'; Running = ' id="running" align="center"><runcolor>Running</runcolor><'; }
$EventColor = @{Error = ' id="error" align="center"><errcolor>Error</errcolor><'; Warning = ' id="warning" align="center"><warncolor>Warning</warncolor><'; }
$ReportHeadPre = ConvertTo-HTML -AS Table -Fragment -PreContent '<div id="header"><H4>' | Out-String
$ReportHeadPost = ConvertTo-HTML -AS Table -Fragment -PreContent ' - Health Report</H4><hr>' | Out-String
$OSHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<br><div id="section"><H2>System Information</H2>' | Out-String  
$NetHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<br><div id="section"><H2>Network Information</H2>' | Out-String  
$HardwareInfoHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<br><div id="section"><H2>Hardware Information</H2>' | Out-String
$HardwareChassisHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<H3>Chassis Information</H3>' | Out-String
$HardwareProcHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<H3>Processor Information</H3>' | Out-String
$HardwareMemHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<H3>Memory Information</H3>' | Out-String
$HardwareRAIDHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<H3>Controller Information</H3>' | Out-String
$HardwareDiskHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<H3>Disk Information</H3>' | Out-String   
$AppLogHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<br><div id="section"><H2>Application Log Information</H2>' | Out-String
$SysLogHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<br><div id="section"><H2>System Log Information</H2>' | Out-String
$ServHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<br><div id="section"><H2>Services Information</H2>' | Out-String
$HotFixHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<br><div id="section"><H2>Hotfix Information</H2>' | Out-String
$InstalledAppsHead = ConvertTo-HTML -AS Table -Fragment -PreContent '<br><div id="section"><H2>Installed Programs Information</H2>' | Out-String


$TimestampAtBoot = Get-WmiObject Win32_PerfRawData_PerfOS_System |
Select-Object -ExpandProperty systemuptime
$CurrentTimestamp = Get-WmiObject Win32_PerfRawData_PerfOS_System |
Select-Object -ExpandProperty Timestamp_Object
$Frequency = Get-WmiObject Win32_PerfRawData_PerfOS_System |
Select-Object -ExpandProperty Frequency_Object
$UptimeInSec = ($CurrentTimestamp - $TimestampAtBoot) / $Frequency
$Time = (Get-Date) - (New-TimeSpan -seconds $UptimeInSec) 
$CurrentDate = Get-Date
$CurrentDate = $CurrentDate.ToString('MM-dd-yyyy')
$CurrentTime = Get-Date -DisplayHint Time
$CurrentTime = $CurrentTime.ToString('hhmmss')
$Date = (Get-Date) - (New-TimeSpan -Day 1)
$CurrentDateFull = Get-Date -Format "dddd MM/dd/yyyy HH:mm:ss"

Function Get-RemoteProgram {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,
        [Parameter(Position = 0)]
        [string[]]
        $Property,
        [switch]
        $ExcludeSimilar,
        [int]
        $SimilarWord
    )

    begin {
        $RegistryLocation = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
        'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
        $HashProperty = @{ }
        $SelectProperty = @('ProgramName', 'ComputerName')
        if ($Property) {
            $SelectProperty += $Property
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $Computer)
            $RegistryLocation | ForEach-Object {
                $CurrentReg = $_
                if ($RegBase) {
                    $CurrentRegKey = $RegBase.OpenSubKey($CurrentReg)
                    if ($CurrentRegKey) {
                        $CurrentRegKey.GetSubKeyNames() | ForEach-Object {
                            if ($Property) {
                                foreach ($CurrentProperty in $Property) {
                                    $HashProperty.$CurrentProperty = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
                                }
                            }
                            $HashProperty.ComputerName = $Computer
                            $HashProperty.ProgramName = ($DisplayName = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayName'))
                            if ($DisplayName) {
                                New-Object -TypeName PSCustomObject -Property $HashProperty |
                                Select-Object -Property $SelectProperty
                            } 
                        }
                    }
                }
            } | ForEach-Object -Begin {
                if ($SimilarWord) {
                    $Regex = [regex]"(^(.+?\s){$SimilarWord}).*$|(.*)"
                }
                else {
                    $Regex = [regex]"(^(.+?\s){3}).*$|(.*)"
                }
                [System.Collections.ArrayList]$Array = @()
            } -Process {
                if ($ExcludeSimilar) {
                    $null = $Array.Add($_)
                }
                else {
                    $_
                }
            } -End {
                if ($ExcludeSimilar) {
                    $Array | Select-Object -Property *, @{
                        name       = 'GroupedName'
                        expression = {
                            ($_.ProgramName -split $Regex)[1]
                        }
                    } |
                    Group-Object -Property 'GroupedName' | ForEach-Object {
                        $_.Group[0] | Select-Object -Property * -ExcludeProperty GroupedName
                    }
                }
            }
        }
    }
}

function Get-ComputerReport {

            Write-Host "Starting report"

            New-Item -path $fpath\Reports -type Directory -ErrorAction Ignore

            $Freespace = 
            @{
                Expression = { [int]($_.Freespace / 1GB) }
                Name       = 'Free Space (GB)'
            }
            $Size = 
            @{
                Expression = { [int]($_.Size / 1GB) }
                Name       = 'Size (GB)'
            }
            $PercentFree = 
            @{
                Expression = { [int]($_.Freespace * 100 / $_.Size) }
                Name       = 'Free (%)'
            }

            $computer = Get-WmiObject -class Win32_OperatingSystem| Select-Object -expandproperty CSName

            $OS = Get-WmiObject -class Win32_OperatingSystem| Select-Object -property CSName, Caption, BuildNumber, ServicePackMajorVersion, @{n = 'LastBootTime'; e = { $_.ConvertToDateTime($_.LastBootUpTime) } } | ConvertTo-HTML -Fragment

            $DiskHardware = Get-WmiObject -Class Win32_LogicalDisk | Select-Object -Property DeviceID, VolumeName, $Size, $Freespace, $PercentFree | ConvertTo-HTML -Fragment

            $NetworkInfo = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4'}) | Select-Object -Property PrefixOrigin, AddressFamily, InterfaceAlias, IPAddress | ConvertTo-HTML -Fragment

            $CPUInfo = Get-WmiObject Win32_Processor | Select-Object Name, SocketDesignation | ConvertTo-HTML -Fragment
            function Get-ComputerBootTime {

                $SystemInfo = &systeminfo | Select-String "System Boot Time"
                
                if ($SystemInfo -match "[\d/]+,\s+\S+") {
                    return (Get-Date $matches[0])
                }
            }

            $BootTime = Get-ComputerBootTime

            $UpTime = ( "" + ((Get-Date) - $BootTime).Days + " Days : " + ((Get-Date) - $BootTime).Hours + " Hrs : " + ((Get-Date) - $BootTime).Minutes + " Min")

            $cpu = (Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Foreach { $_.Average })

            #Weird powershell fix.
            $avg = "" + $cpu + "%"

            $mem = Get-WmiObject win32_operatingsystem |
            Foreach { "{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) * 100) / $_.TotalVisibleMemorySize) }

            $net = if ([bool](Test-Connection -ComputerName google.com -Count 1 -ErrorAction SilentlyContinue)) { $netresult = "Connected" } else { $netresult = "Disconnected" }

            $AddInfo = [pscustomobject] [ordered] @{ 'Up Time' = $UpTime; 'AverageCpu' = $avg; 'MemoryUsage' = $mem + '%'; 'Internet' = $netresult } | ConvertTo-Html -Fragment

            $ProcessorHardware = Get-WmiObject Win32_Processor | Select-Object Name, SocketDesignation | ConvertTo-Html -Fragment

            $MemoryHardware = Get-WmiObject Win32_PhysicalMemory | Select-Object DeviceLocator, PartNumber, Speed, @{name = 'Capacity (GB)'; expr = { [int]($_.Capacity / 1GB) } } | ConvertTo-Html -Fragment

            $RAIDHardware = Get-WmiObject Win32_SCSIController | Select-Object Manufacturer, Name, DriverName | ConvertTo-Html -Fragment

            $ChassisManufacturer = Get-WmiObject Win32_ComputerSystem| Select-Object -ExpandProperty Manufacturer

            $ChassisModel = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Model

            $ChassisBios = Get-WmiObject Win32_Bios | Select-Object -ExpandProperty SMBIOSBIOSVersion

            $ChassisSerial = Get-WmiObject Win32_Bios | Select-Object -ExpandProperty SerialNumber

            $ChassisInfo = [pscustomobject] [ordered] @{ "Manufacturer" = $ChassisManufacturer; "Model" = $ChassisModel; "BIOS Version" = $ChassisBios; "Service Tag" = $ChassisSerial } | ConvertTo-Html -Fragment

            $AppEvent = Get-EventLog -LogName Application -EntryType "Error", "Warning"-after $Time | Select-Object -property EventID, EntryType, Source, TimeGenerated, Message | ConvertTo-HTML -Fragment

            $SysEvent = Get-EventLog -LogName System -EntryType "Error", "Warning" -After $Time | Select-Object -property EventID, EntryType, Source, TimeGenerated, Message | ConvertTo-HTML -Fragment

            $Service = Get-WmiObject win32_service | Select-Object DisplayName, Name, StartMode, State | sort StartMode, State, DisplayName | ConvertTo-HTML -Fragment 

            $InstalledApps = Get-RemoteProgram | Select-Object ProgramName | sort ProgramName | ConvertTo-Html -Fragment

            $Hotfix = gwmi Win32_QuickFixEngineering | ? { $_.InstalledOn } | where { (Get-date($_.Installedon)) -gt $Time } | Select-Object HotFixID, Caption, InstalledOn | sort InstalledOn, HotFixID | ConvertTo-HTML -Fragment 

            $StatusColor.Keys | foreach { $Service = $Service -replace ">$_<", ($StatusColor.$_) }
            $EventColor.Keys | foreach { $AppEvent = $AppEvent -replace ">$_<", ($EventColor.$_) }
            $EventColor.Keys | foreach { $SysEvent = $SysEvent -replace ">$_<", ($EventColor.$_) }

            ConvertTo-HTML -Head $Style -PostContent "$ReportHeadPre $computer $ReportHeadPost $CurrentDateFull $closediv $OSHead $OS $newline $AddInfo $closediv $NetHead $NetworkInfo $closediv $HardwareInfoHead $HardwareChassisHead $ChassisInfo $HardwareProcHead $ProcessorHardware $HardwareMemHead $MemoryHardware $HardwareRAIDHead $RAIDHardware $HardwareDiskHead $DiskHardware $closediv $AppLogHead $AppEvent $closediv $SysLogHead $SysEvent $closediv $ServHead $Service $closediv $InstalledAppsHead $InstalledApps $closediv $HotFixHead $HotFix $closediv" -Title "System Health Check Report" | Out-File "$fpath\Reports\$computer $CurrentDate $CurrentTime.html"
        }

Get-ComputerReport