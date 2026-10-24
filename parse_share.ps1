$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json', [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

Write-Host "Title: " $data.data.title
Write-Host "Share Info: " ($data.data | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name })

if ($data.data.chat_history) {
    foreach ($msg in $data.data.chat_history) {
        Write-Host "===================="
        Write-Host "ROLE: " $msg.role
        Write-Host "CONTENT: "
        Write-Host $msg.content
    }
} elseif ($data.data.messages) {
    foreach ($msg in $data.data.messages) {
        Write-Host "===================="
        Write-Host "ROLE: " $msg.role
        Write-Host "CONTENT: "
        Write-Host $msg.content
    }
} else {
    Write-Host "Top level data structure:"
    $data.data | ConvertTo-Json -Depth 4
}
