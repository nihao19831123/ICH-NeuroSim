$url = 'https://chat2-api.qianwen.com/api/v1/share/info?pr=qwen&fr=mac'
$headers = @{
    'Content-Type' = 'application/json'
    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    'Origin' = 'https://qianwen.my.cn'
    'Referer' = 'https://qianwen.my.cn/share/chat/cb995af8053a421baa852f751a7d5cab?biz_id=ai_qwen&env=prod&qwcontainer=qk&la=zh-CN&tq=SD&ch=tongyi%40store_free_oppo&lang=zh-CN'
}
$body = @{
    share_id = 'cb995af8053a421baa852f751a7d5cab'
    biz_id = 'ai_qwen'
} | ConvertTo-Json

try {
    $res = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    $json = $res | ConvertTo-Json -Depth 10
    $outPath = 'C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json'
    [System.IO.File]::WriteAllText($outPath, $json, [System.Text.Encoding]::UTF8)
    Write-Host "Success! Saved to $outPath"
    Write-Host "Keys: " ($res | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name })
} catch {
    Write-Host "Error: " $_.Exception.Message
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Response body: " $reader.ReadToEnd()
    }
}
