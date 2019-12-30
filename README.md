# Local System Health Reporting
This is a Windows health reporting system built to be automated with Task Scheduler. The script runs a full report on your computer at logon. Once complete, the script compiles a HTML file with the current Date and Time of that report and a HTML file to navigate the reports.

# Screenshots:
![Imgur](https://i.imgur.com/3LTpLDQ.png?1)

# Features:
- Lightweight, Configurable, and Expandable.
- Automatically creates HTML pages for navigating and viewing reports.
- Fully written in Powershell. No need to install anything!
- Built for Task Scheduler.

# What's in the report:
System Information
- Computer Name
- Operating System
- Build + Service Pack Version
- Last Boot Time
- Up Time
- CPU usage at time of report.
- Memory usage at time of report.
- Internet Connectivity by making system ping an external address and returning result.

Network Information
- IPv4 Addressing
- IPv6 Addressing
- RAW Address
- Address Family

Hardware Information
- Chassis: Manufacturer, Model, BIOS Version, and Service Tag
- Processor: Name, and Socket Designation
- Memory: Slot ID, Part Number, Speed, and Capacity
- Storage Controller: Manufacturer, Name, DriverName
- Disk: Drive Letter, Volume Name, Size, Free Space, Free (%)

Application Event Log

System Event Log

Running Services

Installed Programs

Hotfixes

# To use:
- Download and Extract HealthReports folder to desktop.
- Run Powershell as Administator.
- Navigate through shell to the HealthReports folder and execute Installer.ps1. (Must be done in PS)
- The files will be moved to "C:\Users\UserName\Documents\SystemHealthReports"
- A task in task scheduler will be created to run MainExec.ps1 hidden at logon.

 To view health reports:
 Goto "C:\Users\UserName\Documents\SystemHealthReports" and open index.html.

# Notes:
- MainExec.ps1 will produce an error if the system's Event Logs are cleared. This is nothing to worry about.
- Reports older than 30 days will auto delete.
- - Change this under MainExec.ps1 > Line 33: $Daysback = "-30"
- Feel free to update the CSS in the CreateHTML and GetSystemReport scripts.

