$ErrorActionPreference = 'Stop'
$url = 'https://g.alicdn.com/code/npm/@ali/tongyi-app-share/26.1023.161641/js/async/chat-share-route.js'
$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$wc.Headers.Add('User-Agent', 'Mozilla/5.0')
$js = $wc.DownloadString($url)

Write-Host "JS length: " $js.Length

$matches = [regex]::Matches($js, '["'']([^"'']*(?:share|api|chat)[^"'']*)["'']')
$seen = @{}
foreach ($m in $matches) {
    $val = $m.Groups[1].Value
    if ($val.Length -gt 4 -and $val.Length -lt 80 -and -not $seen.ContainsKey($val)) {
        $seen[$val] = $true
        Write-Host $val
    }
}
