$dnsrecords = Get-DnsServerResourceRecord -ZoneName “_msdcs.c7.xglobe.net”
$deadDC = $dnsrecords | Where-Object {$_.RecordData.IPv4Address -eq “192.117.171.111” -or $_.RecordData.NameServer -eq “il3wv3991.c7.xglobe.net.” -or $_.RecordData.DomainName -eq “il3wv3991.c7.xglobe.net.”}
$deadDC | Remove-DnsServerResourceRecord -ZoneName “_msdcs.c7.xglobe.net” -force