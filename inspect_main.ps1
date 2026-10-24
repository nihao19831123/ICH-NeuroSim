$ErrorActionPreference = 'Stop'
$url = 'https://g.alicdn.com/code/npm/@ali/tongyi-app-share/26.1023.161641/js/main.js'
$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$wc.Headers.Add('User-Agent', 'Mozilla/5.0')
$js = $wc.DownloadString($url)

Write-Host "main.js length: " $js.Length

$matches = [regex]::Matches($js, '["''](/api/[^"'']+|https://chat[^"'']+)["'']')
$seen = @{}
foreach ($m in $matches) {
    $val = $m.Groups[1].Value
    if (-not $seen.ContainsKey($val)) {
        $seen[$val] = $true
        Write-Host $val
    }
}
