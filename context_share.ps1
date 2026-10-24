$ErrorActionPreference = 'Stop'
$url = 'https://g.alicdn.com/code/npm/@ali/tongyi-app-share/26.1023.161641/js/main.js'
$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$wc.Headers.Add('User-Agent', 'Mozilla/5.0')
$js = $wc.DownloadString($url)

$idx = $js.IndexOf('/api/v1/share/info')
if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 200)
    $len = [Math]::Min($js.Length - $start, 800)
    Write-Host $js.Substring($start, $len)
}
