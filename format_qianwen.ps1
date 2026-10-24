$raw = [System.IO.File]::ReadAllText('C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_share_data.json', [System.Text.Encoding]::UTF8)
$data = $raw | ConvertFrom-Json

$rec = $data.data.session.record_list[0]

$md = @()
$md += "# 用户在通义千问中的原始对话记录"
$md += ""
$md += "## 用户提问："
foreach ($rq in $rec.request_messages) {
    $md += "> **" + $rq.content + "**"
}

$md += ""
$md += "## 千问回复内容："

foreach ($r in $rec.response_messages) {
    if ($r.content) {
        $md += $r.content
    }
    if ($r.meta_data -and $r.meta_data.multi_load) {
        foreach ($ml in $r.meta_data.multi_load) {
            if ($ml.type -eq "common_video") {
                $md += ""
                $md += "### 📹 推荐视频卡片：" + $ml.content.title
                $md += "- **时长/标识**: " + $ml.content.video_id
                $md += "- **描述**: " + $ml.content.description
                if ($ml.content.video_res_id) {
                    $md += "- **资源ID**: " + $ml.content.video_res_id
                }
            }
        }
    }
}

$target = 'C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\qianwen_chat_readable.md'
[System.IO.File]::WriteAllLines($target, $md, [System.Text.Encoding]::UTF8)
Write-Host "Written to $target"
