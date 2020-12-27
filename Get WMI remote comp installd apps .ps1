#Remote Software Installed

$computers = Get-Content C:\cy-computers.csv

$results= foreach( $computer in $computers) {

Write-Host "Processing Server $computer"

Get-WmiObject -Class Win32_Product -ComputerName $computer | Select-Object __Server, Name, Version -ErrorAction SilentlyContinue

}

$results | Export-CSV -Path C:\cy-remote-apps.csv