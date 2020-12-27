$computers = Get-Content C:\computers.csv
Get-WMIObject -ComputerName $computers  -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = $true" | Out-File C:\il-NICstatus.csv