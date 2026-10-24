$url = "https://chat2-api.qianwen.com/api/v1/share/info?pr=qwen&fr=mac"
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("Content-Type", "application/json")
$wc.Headers.Add("User-Agent", "Mozilla/5.0")
$wc.Headers.Add("Origin", "https://qianwen.my.cn")

$body = '{"share_id":"cb995af8053a421baa852f751a7d5cab","biz_id":"ai_qwen"}'
$bytes = $wc.UploadData($url, "POST", [System.Text.Encoding]::UTF8.GetBytes($body))
$utf8Str = [System.Text.Encoding]::UTF8.GetString($bytes)
[System.IO.File]::WriteAllText("C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_raw_utf8.json", $utf8Str, [System.Text.Encoding]::UTF8)
Write-Host "Downloaded raw UTF8 bytes, length: " $utf8Str.Length
