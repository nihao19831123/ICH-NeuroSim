$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\record_0.json', [System.Text.Encoding]::UTF8)
$rec = $raw | ConvertFrom-Json

$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine("=== REQUEST MESSAGES ===")
foreach ($rm in $rec.request_messages) {
    [void]$sb.AppendLine("ROLE: " + $rm.role + " | TYPE: " + $rm.content_type)
    if ($rm.contents) {
        foreach ($c in $rm.contents) {
            [void]$sb.AppendLine("[MIME: " + $c.mime_type + "]")
            [void]$sb.AppendLine($c.content)
        }
    }
}

[void]$sb.AppendLine("`n=== RESPONSE MESSAGES ===")
foreach ($rm in $rec.response_messages) {
    [void]$sb.AppendLine("ROLE: " + $rm.role + " | TYPE: " + $rm.content_type)
    if ($rm.contents) {
        foreach ($c in $rm.contents) {
            [void]$sb.AppendLine("[MIME: " + $c.mime_type + "]")
            [void]$sb.AppendLine($c.content)
            if ($c.meta_data) {
                [void]$sb.AppendLine("META: " + ($c.meta_data | ConvertTo-Json -Depth 6))
            }
        }
    }
}

[System.IO.File]::WriteAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\chat_content.txt', $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Done writing chat_content.txt"
