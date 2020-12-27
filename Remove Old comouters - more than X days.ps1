
#check AD for stale computer objects based on date logon criteria and disable / delete

$1year = (Get-Date).AddDays(-100) # The 100 is the number of days from today since the last logon.
$1y1m = (Get-Date).AddDays(-100)

# Disable computer objects and move to disabled OU (Older than 1 year):
Get-ADComputer -Property Name,lastLogonDate -Filter {lastLogonDate -lt $1year} | Set-ADComputer -Enabled $false
Get-ADComputer -Property Name,Enabled -Filter {Enabled -eq $False} | Move-ADObject -TargetPath "DC=XXXX,DC=local"


# Delete Older Disabled computer objects:
Get-ADComputer -Property Name,lastLogonDate -Filter {lastLogonDate -lt $1y1m} | Remove-ADComputer