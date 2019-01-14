$Logfile = "D:\DNSUpdate.log"

# replace these dummy values with the correct ones...
# CloudFlare domain that I want to manage
$cloudflareBase = "base.url"
# Specific DNS entry in that domain
$cloudflareURL = "target.base.url"
# API key and Email
$cloudFlareAPIkey = "abcdef123456abcdef123456"
$cloudFlareEmail = "email@base.url"
# SmartDNSProxy API key for updates
$sdpAPIKey = "1234abcd1234abcd"

# mine are imported from here
. "$PSScriptRoot\my_params.ps1"

Function LogWrite
{
	Param ([string]$logstring)
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$Line = "$Stamp $logstring`n"

	if (!(Test-Path $Logfile))
    {
		# no logfile, so create a new one
    	New-Item -path $Logfile -type "file" -value $line
   	} else {
		# write log to temp file, then grab old log and append it (truncate at 10k) so most recent entry is always at top
		Add-Content "$LogFile.tmp" -value $line
		$oldfile = Get-Content $Logfile -Raw
		if ($oldfile.Length -gt 0) {
			$oldfile = $oldfile.substring(0,[System.Math]::Min(10240, $oldfile.Length))
		} else {
			$oldfile = ""
		}
    	Add-Content -Path "$LogFile.tmp" -Value $oldfile
    	Remove-Item $Logfile
    	Move-Item -path "$LogFile.tmp" -destination $Logfile
    }
}

$wc = new-object System.Net.WebClient
$ipaddr = $wc.DownloadString("http://myexternalip.com/raw").replace("`n","")

$ip_address = $null
# fun hack to validate the IP address
$a = [System.Net.IPAddress]::TryParse($ipaddr, [ref]$ip_address)
if ($ip_address -ne $null) {

	$headers = @{
		'X-Auth-Key' = $cloudFlareAPIkey
		'X-Auth-Email' = $cloudFlareEmail
        'Content-Type' = 'application/json'
	}

	$baseurl = "https://api.cloudflare.com/client/v4/zones"
	$zoneurl = "$baseurl/?name=$cloudflareBase"

	$cfzone = Invoke-RestMethod -Uri $zoneurl -Method Get -Headers $headers 
	$zoneid = $cfzone.result[0].id

	$recordurl = "$baseurl/$zoneid/dns_records/?name=$cloudflareURL"
	$dnsrecord = Invoke-RestMethod -Headers $headers -Method Get -Uri $recordurl
	$cfipaddr = $dnsrecord.result.content 
	if ($cfipaddr -eq $ipaddr) {
		#LogWrite("Current IP $ipaddr, No updates required")
	} else {
		LogWrite("IP has changed from $cfipaddr to $ipaddr, initiating update")

        $recordid = $dnsrecord.result.id
		$dnsrecord.result | Add-Member "content"  $ipaddr -Force 
		$body = $dnsrecord.result | ConvertTo-Json
		$updateurl = "$baseurl/$zoneid/dns_records/$recordid" 

		$result = Invoke-RestMethod -Headers $headers -Method Put -Uri $updateurl -Body $body -ContentType "application/json"
		$newip = $result.result.content
		LogWrite("Cloudflare: $result")

		# note this string is split, but of  akludge around the parameter substitution
		$updateurl = "http://www.globalapi.net/sdp/api/IP/update/$sdpAPIKey"+"?ip=$ipaddr"
		$result = Invoke-RestMethod -Headers $headers -Method Get -Uri $updateurl -ContentType "application/json"
	
		$newip = $result.result.content
		LogWrite("SmartDNSProxy: $result")
	}
} else {
	LogWrite("IP Lookup returned something weird: $ipaddr")
}