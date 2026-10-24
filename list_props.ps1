$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json', [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

Write-Host "Data properties:"
$data.data | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }

Write-Host "Checking data.data:"
if ($data.data.chat) {
    Write-Host "chat properties:"
    $data.data.chat | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
}
