$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json', [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

$rec = $data.data.session.record_list[0]
Write-Host "Record properties:"
$rec | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }

$recJson = $rec | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\record_0.json', $recJson, [System.Text.Encoding]::UTF8)
Write-Host "Saved record_0.json"
