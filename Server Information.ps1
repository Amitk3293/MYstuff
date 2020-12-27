<######################################################################
SysAdmin Script
This PowerShell Script will fetch the below reports.

CPU Utlization
Memory Utilization
Pagefile Utilization
Uptime
Disk Utilization
System Reboot Logs
Automatic Services in Stopped State
Hardware Information
Share Information
Local Users & Admins

.NOTES    
Name: SysAdmin.ps1
Author: Sanjay Paul
Updated: 2018-09-25
Version: 1.0

.EXAMPLE 
SysAdmin.ps1
######################################################################>
Function LAdmin{
	#Connect to the server and get the Local Administrators account
	$Server = Read-Host "Enter Server Name"
	cls
	$group = [ADSI]("WinNT://$Server/Administrators,group")  
	$LocalAdmin = $group.psbase.invoke("Members")
	$Local = $LocalAdmin | ForEach-Object {$GName = $_.GetType().InvokeMember("Name",'GetProperty', $null, $_, $null)
	"$GName" }
	#| Out-File $Members -encoding ASCII -append
	Write-Host "Local Administrators"
	Write-Host "--------------------"
	$Local
	Write-Host "--------------------"

	$adsi = [ADSI]"WinNT://$Server"
	$adsi.psbase.children | where {$_.psbase.schemaClassName -match "user"} | select @{n="Local Users";e={$_.name}}
	Write-Host "-----------"
}
Function Mem{
	#Connect to server and fetch memory utilization (10 samples) and provide average Mem utilization
	$Server = Read-Host "Enter Server Name"
	cls
	Write-Host "Memory utlization of $Server" -f yellow
	Write-Host "-----------------------------------" -f yellow
	$SystemInfo = Get-WmiObject -Class Win32_OperatingSystem -computername $Server | Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory 
	$TotalRAM = $SystemInfo.TotalVisibleMemorySize 
	$TRam = [Math]::Round(($TotalRAM / (1024*1024)), 2)
	$FreeRAM = $SystemInfo.FreePhysicalMemory 
	$FRam = [Math]::Round(($FreeRAM / (1024*1024)), 2)
	$URAM = $TRAM - $FRAM 
	$RAMPercentUsed = ($URAM / $TRAM) * 100 
	$RAMPercentUsed = [Math]::Round($RAMPercentUsed, 2) 
	Write-Host "Total Memory    : $TRam GB"
	Write-Host "Used Memory     : $URAM GB"
	Write-Host "Free Memory     : $FRAM GB "
	Write-Host "Percentage Used : $RAMPercentUsed %"
}
Function Shares{
	$Server = Read-Host "Enter Server Name"
	cls
	$Shares = Get-WmiObject -Class Win32_Share -Computername $Server | where-object {$_.Description -ne "Default Share"}
	Write-Host "      Share Information of $Server "
	Write-Host "------------------------------------------------------------" -f yellow
	$Shares
	Write-Host "------------------------------------------------------------" -f yellow
}
Function CPU{
	$Server = Read-Host "Enter Server Name"
	cls
	$CPUs = Get-WmiObject win32_processor -ComputerName saai-mssqp03 | select -exp LoadPercentage
	$tCPU = 0
	$nCPU = 0
	foreach ($CPU in $CPUs){
		$tCPU = $tCPU + $CPU
		$nCPU = $nCPU + 1
	}
	$aCPU = $tCPU / $nCPU
	$avgCPU = [math]::Round($aCPU)
	Write-Host ""
	Write-Host "Average CPU Utilization of $Server : $AvgCpu %" -f Green
}

Function PageFile{
	$Server = Read-Host "Enter Server Name"
	cls
	$colItems = get-wmiobject -class "Win32_PageFileUsage" -namespace "root\CIMV2" -computername $Server
	Write-Host "Page file information of $Server"
	foreach ($objItem in $colItems) { 
		write-host 
		$Per = $objItem.CurrentUsage * 100 / $objItem.AllocatedBaseSize
		$Base = [Math]::Round(($objItem.AllocatedBaseSize / (1024*1)), 2)
		$Curr = [Math]::Round(($objItem.CurrentUsage / (1024*1)), 2)
		$Peak = [Math]::Round(($objItem.PeakUsage / (1024*1)), 2)
		$Per = [Math]::Round($per, 2)
		write-host "Name / Path         : " $objItem.Name
		write-host "Allocated Base Size : " $Base "GB"
		write-host "Current Usage       : " $Curr "GB"
		write-host "Percent Usage       : " $Per "%"
		write-host "Peak Usage          : " $Peak "GB"
		write-host "Temporary Page File : " $objItem.TempPageFile 
		write-host 
	}
}
Function Uptime{
	$Server = Read-Host "Enter Server Name"
	cls
	$wmi = gwmi Win32_OperatingSystem -computer $Server
    $LBTime = $wmi.ConvertToDateTime($wmi.Lastbootuptime) 
    [TimeSpan]$uptime = New-TimeSpan $LBTime $(get-date) 
	Write-host "  Uptime of Server $Server" -f yellow
    Write-host "  $($uptime.days) days $($uptime.hours) hrs $($uptime.minutes) mins $($uptime.seconds) secs" -f yellow
}
Function Logging{
	$Server = Read-Host "Enter Server Name"
	cls
	Write-Host "Please wait, while checking System logs..." -f cyan
	$Logs = get-eventlog system -computername $Server | where-object {$_.source -eq "user32"} | where-object {$_.eventid -eq 1074} | select -first 4
	cls
	Write-Host "System Reboot Events of $Server" -f cyan
	Write-Host "----------------------------------------------------------------------------" -f cyan
	Write-Host " "
	foreach($Log in $Logs){
		$User = $Log.Username
		$Time = $Log.TimeWritten
		$Mess = $Log.Message
		Write-Host "Time    :" $Time "    ###    User :" $User 
		Write-Host "Message : $Message "
		Write-Host "----------------------------------------------------------------------------" -f cyan    
	}
}
Function Disk{
	$Server = Read-Host "Enter Server Name"
	cls
	$disks = Get-WmiObject -Class win32_logicaldisk -Computername $server
	Write-Host ""
	Write-Host "Disk information of Server : $Server" -f green
	Write-Host "-----------------------------------------------"
	foreach ($disk in $disks) {
	if($disk.size -gt 0){
		$Drive = $disk.DeviceID
		$Size = [math]::Round($disk.size / 1gb,2)
		$Free = [math]::Round($disk.freespace / 1gb,2)
		$Freeper = [math]::Round(($disk.freespace/$disk.size)*100,2) 
        Write-host "Drive = $Drive" -f yellow -nonewline
        Write-host "  Total Size = $Size GB" -f yellow -nonewline
        Write-host "  Free Space = $Free GB" -f yellow -nonewline
        Write-host "  Free = $Freeper % " -f yellow
        }
	}
}
Function Hardware{
	$Server = Read-Host "Enter Server Name"
	cls
	$BIOS = Get-WMIObject Win32_BIOS -computername $Server
	$Net = Get-WMIObject Win32_NetworkAdapterConfiguration -computername $Server -filter ipenabled="true"
	$Sys = Get-WmiObject -Class Win32_ComputerSystem -computername $Server
	$OSys = Get-WmiObject -Class Win32_OperatingSystem -computername $Server
	Write-Host ""
	Write-Host "Hardware information : $Server" -f green
	Write-Host "-----------------------------------------------"
	Write-Host "Server Name    : " $Sys.Name 
	Write-Host "Domain         : " $Sys.Domain 
	Write-Host "Manufacturer   : " $Sys.Manufacturer 
	Write-Host "Model          : " $Sys.Model 
	Write-Host "Processors     : " $Sys.NumberOfProcessors 
	Write-Host "OS Name        : " ($OSys).caption 
	Write-Host "Architect      : " ($OSys).OSArchitecture 
	Write-Host "Service Pack   : " $OSys.ServicePackMajorVersion 
	Write-Host "Install Date   : " $OSys.InstallDate.substring(0,8) 
	Write-Host "NIC            : " $Net.Description 
	Write-Host "IP Address     : " $Net.IpAddress 
	Write-Host "Gateway        : " $Net.DefaultIPgateway
}
Function AutoServ{
	$Server = Read-Host "Enter Server Name"
	cls
	$Stop = Get-WmiObject Win32_Service -Computername $server | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } | select Name, state
	Write-Host ""
	Write-Host "Automatic Services in Stopped state on $Server" -f green
	Write-Host "-----------------------------------------------"
	$Stop
}

Function List{
	Start-Sleep -s 5
	Write-Host ""
	Write-Host ""
	Write-Host "=================================================" -f Cyan 
	Write-Host "      Wintel System Admin Script  " -f Green 
	Write-Host "=================================================" -f Cyan 
	Write-Host "	1. CPU Utlization " -f Green 
	Write-Host "	2. Memory Utilization " -f Green 
	Write-Host "	3. Pagefile Utilization " -f Green 
	Write-Host "	4. Uptime " -f Green
	Write-Host "	5. Disk Utilization " -f Green
	Write-Host "	6. System Reboot Logs " -f Green
	Write-Host "	7. Automatic Services in Stopped State " -f Green
	Write-Host "	8. Hardware Information " -f Green
	Write-Host "	9. Share Information " -f Green
	Write-Host "	A. Local Users & Admins " -f Green
	Write-Host "	0. Exit (Zero)" -f Green 
	Write-Host "=================================================" -f CYan 
}

cls
While($Exit -ne "Yes")
{
	List
	$Choice = Read-Host "   Please enter your Choice :"
	cls
	Write-Host ""
	switch ($Choice)
	{ 
		1 {
		CPU
		}       
		2 {
		Mem
		}
		3 {
		PageFile
		} 
		4 {
		Uptime
		}
		5 {
		Disk
		}
		6 {
		Logging
		}
		7 {
		AutoServ
		} 
		8 {
		Hardware
		}
		9 {
		Shares
		}
		A {
		LAdmin
		}
		0 { 
		Write-Host "Exiting.... "
		$Exit = "Yes"
		}
		default {
		Write-Host "Please enter correct choice. " -nonewline
		Write-Host "'$Choice' " -f cyan -nonewline
		Write-Host "is not correct choice !!! "
		}
	}
}
Write-Host "Thank you. :)" -f cyan