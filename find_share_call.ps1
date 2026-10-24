$ErrorActionPreference = 'Stop'
$url = 'https://g.alicdn.com/code/npm/@ali/tongyi-app-share/26.1023.161641/js/main.js'
$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$wc.Headers.Add('User-Agent', 'Mozilla/5.0')
$js = $wc.DownloadString($url)

$matches = [regex]::Matches($js, '.{0,100}/api/v1/share/[^{}"'';]+.{0,100}')
foreach ($m in $matches) {
    Write-Host $m.Value
}
