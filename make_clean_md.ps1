$raw = [System.IO.File]::ReadAllText("C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_raw_utf8.json", [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

$rec = $data.data.session.record_list[0]

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Qianwen Share Content Analysis")
$lines.Add("")
$lines.Add("## Query:")
foreach ($rm in $rec.request_messages) {
    $lines.Add("> " + $rm.content)
}

$lines.Add("")
$lines.Add("## Response:")
foreach ($rm in $rec.response_messages) {
    if ($rm.content) {
        $lines.Add($rm.content)
    }
    if ($rm.meta_data -and $rm.meta_data.multi_load) {
        foreach ($ml in $rm.meta_data.multi_load) {
            if ($ml.type -eq "common_video") {
                $lines.Add("")
                $lines.Add("### Video Card: " + $ml.content.title)
                $lines.Add("- Video ID: " + $ml.content.video_id)
                $lines.Add("- Description: " + $ml.content.description)
                if ($ml.html -and $ml.html.sc_html) {
                    # extract poster or link
                    if ($ml.html.sc_html -match 'poster="([^"]+)"') {
                        $lines.Add("- Poster: " + $matches[1])
                    }
                    if ($ml.html.sc_html -match 'time-display[^>]*>([^<]+)<') {
                        $lines.Add("- Duration: " + $matches[1])
                    }
                }
            }
        }
    }
}

[System.IO.File]::WriteAllLines("C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_clean.md", $lines, [System.Text.Encoding]::UTF8)
Write-Host "Done writing qianwen_clean.md"
