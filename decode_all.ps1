$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json', [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

$rec = $data.data.session.record_list[0]

$out = @()
$out += "=== USER QUERY ==="
foreach ($rq in $rec.request_messages) {
    $out += $rq.content
}

$out += "`n=== ASSISTANT RESPONSES ==="
for ($i = 0; $i -lt $rec.response_messages.Count; $i++) {
    $r = $rec.response_messages[$i]
    $out += "--- RESPONSE ITEM $i (mime: $($r.mime_type), status: $($r.status)) ---"
    if ($r.content) {
        $out += $r.content
    }
    if ($r.meta_data) {
        # Check if there is text or video or search results in meta_data
        $metaStr = $r.meta_data | ConvertTo-Json -Depth 10
        $out += "META_DATA:"
        $out += $metaStr
    }
}

[System.IO.File]::WriteAllLines('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\decoded_chat.txt', $out, [System.Text.Encoding]::UTF8)
Write-Host "Wrote decoded_chat.txt"
