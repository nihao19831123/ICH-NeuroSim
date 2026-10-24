$raw = [System.IO.File]::ReadAllText("C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_raw_utf8.json", [System.Text.Encoding]::UTF8)

$matches = [regex]::Matches($raw, 'https?://[a-zA-Z0-9_\-\.:/]+')
$seen = @{}
foreach ($m in $matches) {
    $u = $m.Value
    if (-not $seen.ContainsKey($u) -and ($u -match 'bilibili|video|quark|youtube|douyin|sina')) {
        $seen[$u] = $true
        Write-Host $u
    }
}
