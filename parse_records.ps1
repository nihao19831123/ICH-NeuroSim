$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json', [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine("=== TITLE ===")
[void]$sb.AppendLine($data.data.title)
[void]$sb.AppendLine("Total records: " + $data.data.session.record_list.Count)

foreach ($rec in $data.data.session.record_list) {
    [void]$sb.AppendLine("--------------------------------------------------------------------------------")
    [void]$sb.AppendLine("RECORD ID: " + $rec.id + " | Pos: " + $rec.pos)
    if ($rec.contents) {
        foreach ($c in $rec.contents) {
            [void]$sb.AppendLine("[MIME: " + $c.mime_type + "]")
            if ($c.content) {
                [void]$sb.AppendLine($c.content)
            }
            if ($c.meta_data) {
                [void]$sb.AppendLine("META: " + ($c.meta_data | ConvertTo-Json -Depth 6))
            }
        }
    }
}

[System.IO.File]::WriteAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\records_parsed.txt', $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Done writing records_parsed.txt"
