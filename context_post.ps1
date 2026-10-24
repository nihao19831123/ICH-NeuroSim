$ErrorActionPreference = 'Stop'
$url = 'https://g.alicdn.com/code/npm/@ali/tongyi-app-share/26.1023.161641/js/main.js'
$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$wc.Headers.Add('User-Agent', 'Mozilla/5.0')
$js = $wc.DownloadString($url)

$idx = $js.IndexOf('method:"POST"')
if ($idx -ge 0) {
    Write-Host $js.Substring($idx, 600)
}
