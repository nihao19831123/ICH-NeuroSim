$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\record_0.json', [System.Text.Encoding]::UTF8)
$rec = $raw | ConvertFrom-Json

Write-Host "req count: " $rec.request_messages.Count
if ($rec.request_messages.Count -gt 0) {
    Write-Host "req[0] keys: " ($rec.request_messages[0] | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name })
    $rec.request_messages[0] | ConvertTo-Json -Depth 5
}

Write-Host "resp count: " $rec.response_messages.Count
if ($rec.response_messages.Count -gt 0) {
    Write-Host "resp[0] keys: " ($rec.response_messages[0] | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name })
    $rec.response_messages[0] | ConvertTo-Json -Depth 5
}
