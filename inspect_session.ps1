$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json', [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

Write-Host "Title: " $data.data.title
Write-Host "Session properties: " ($data.data.session | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name })

$msgs = $data.data.session.messages
Write-Host "Messages count: " $msgs.Count

foreach ($m in $msgs) {
    Write-Host "========================================="
    Write-Host "ID: $($m.id), type: $($m.content_type)"
    if ($m.contents) {
        foreach ($c in $m.contents) {
            Write-Host "MIME: $($c.mime_type)"
            if ($c.content) {
                Write-Host "CONTENT: "
                Write-Host $c.content
            }
            if ($c.meta_data) {
                Write-Host "METADATA: " ($c.meta_data | ConvertTo-Json -Depth 6)
            }
        }
    }
}
