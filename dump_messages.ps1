$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json', [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

$msgs = $data.data.chat.messages
Write-Host "Total messages: " $msgs.Count

foreach ($m in $msgs) {
    Write-Host "=========================================================="
    Write-Host "CONTENT TYPE: " $m.content_type
    Write-Host "USER ACTION / ROLE: " $m.user_action
    
    # check contents
    if ($m.contents) {
        foreach ($c in $m.contents) {
            Write-Host "--- subcontent (mime: $($c.mime_type), status: $($c.status)) ---"
            if ($c.content) {
                Write-Host $c.content
            }
            if ($c.meta_data) {
                Write-Host "META_DATA: " ($c.meta_data | ConvertTo-Json -Depth 5)
            }
        }
    }
}
