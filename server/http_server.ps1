# ICH-NeuroSim High-Performance Local HTTP & Clinical API Server
param(
    [int]$Port = 8080
)

$rootDir = "C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\vr_client"
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "[SERVER STARTED] ICH-NeuroSim Live Backend running at $prefix" -ForegroundColor Green
    Write-Host "[CLINICAL TARGET] Ingested Patient 20251118000395 (33.29 mL Right Basal Ganglia ICH)" -ForegroundColor Cyan
} catch {
    Write-Host "[ERROR] Failed to start HTTP listener: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Clinical Patient Profile Data for 20251118000395
$patientData = @{
    patient_id = "20251118000395"
    pseudonym_id = "SUBJ_PAN_74F"
    patient_name = "PAN SHAN ZHEN (潘善珍)"
    patient_age = 74
    patient_sex = "Female"
    study_date = "2025-11-18"
    modality = "CT (UIH uCT 710)"
    hematoma_volume_ml = 33.29
    edema_volume_ml = 21.40
    midline_shift_mm = 4.2
    expansion_risk = "HIGH (Black Hole Sign / Heterogeneous Attenuation)"
    expansion_probability = 0.76
    surgical_indication = "STRONG_INDICATION (ENRICH 2024 NEJM Criteria: Vol > 30mL)"
    location = "Right Basal Ganglia / Internal Capsule (右侧基底节/内囊区)"
    slices_count = 26
    slice_thickness_mm = 5.0
    pixel_spacing_mm = 0.4375
    primary_trajectory = @{
        plan_id = "PLAN_20251118_MIPS_01"
        approach = "ENRICH Transsulcal MIPS (经右额叶脑沟穿束入路)"
        entry_ras = @(28.5, 65.0, 68.0)
        target_ras = @(20.5, 15.0, 22.0)
        depth_mm = 61.2
        cst_clearance_mm = 5.85
        is_safe = $true
        angle_deg = 19.4
    }
}

$patientJson = $patientData | ConvertTo-Json -Depth 5

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, HEAD, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        $isHead = ($request.HttpMethod -eq "HEAD")

        # API Router
        if ($urlPath -eq "/api/patient" -or $urlPath -eq "/api/patient/info") {
            $response.ContentType = "application/json; charset=utf-8"
            $buf = [System.Text.Encoding]::UTF8.GetBytes($patientJson)
            $response.ContentLength64 = $buf.Length
            if (-not $isHead) {
                $response.OutputStream.Write($buf, 0, $buf.Length)
            }
            $response.Close()
            continue
        }

        if ($urlPath -eq "/api/status") {
            $statusJson = @{ status = "ONLINE"; uptime = [DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss"); patient = "20251118000395" } | ConvertTo-Json
            $response.ContentType = "application/json; charset=utf-8"
            $buf = [System.Text.Encoding]::UTF8.GetBytes($statusJson)
            $response.ContentLength64 = $buf.Length
            if (-not $isHead) {
                $response.OutputStream.Write($buf, 0, $buf.Length)
            }
            $response.Close()
            continue
        }

        # Video Upload Endpoint (Supports both WeChat MP4 and WebM)
        if ($urlPath -eq "/api/save_video" -and $request.HttpMethod -eq "POST") {
            $filename = $request.QueryString["filename"]
            if ([string]::IsNullOrWhiteSpace($filename)) {
                $filename = "ICH_WeChat_Doctor_Tutorial_Video.mp4"
            }
            $filename = [System.IO.Path]::GetFileName($filename)
            $savePath = Join-Path $rootDir $filename
            $fileStream = [System.IO.File]::Create($savePath)
            $request.InputStream.CopyTo($fileStream)
            $fileStream.Close()
            
            # Ensure WeChat default video name also updated
            $defaultWechat = Join-Path $rootDir "ICH_WeChat_Doctor_Tutorial_Video.mp4"
            if ($filename.EndsWith(".mp4") -and ($savePath -ne $defaultWechat)) {
                [System.IO.File]::Copy($savePath, $defaultWechat, $true)
            }

            $response.ContentType = "application/json; charset=utf-8"
            $respJson = '{"success":true,"file":"' + $filename + '"}'
            $respBytes = [System.Text.Encoding]::UTF8.GetBytes($respJson)
            $response.ContentLength64 = $respBytes.Length
            $response.OutputStream.Write($respBytes, 0, $respBytes.Length)
            $response.Close()
            continue
        }

        # DICOM Manual Upload Endpoint (POST)
        if ($urlPath -eq "/api/dicom/upload" -and $request.HttpMethod -eq "POST") {
            $filename = $request.QueryString["filename"]
            if ([string]::IsNullOrWhiteSpace($filename)) {
                $filename = "slice_" + [DateTime]::Now.ToString("yyyyMMdd_HHmmssfff") + ".dcm"
            }
            $filename = [System.IO.Path]::GetFileName($filename)
            $uploadDir = Join-Path $rootDir "uploads\dicom"
            if (-not (Test-Path $uploadDir)) {
                New-Item -ItemType Directory -Force -Path $uploadDir | Out-Null
            }
            $savePath = Join-Path $uploadDir $filename
            $fileStream = [System.IO.File]::Create($savePath)
            $request.InputStream.CopyTo($fileStream)
            $fileStream.Close()

            $response.ContentType = "application/json; charset=utf-8"
            $respJson = '{"success":true,"filename":"' + $filename + '","path":"uploads/dicom/' + $filename + '","bytes":' + (Get-Item $savePath).Length + '}'
            $respBytes = [System.Text.Encoding]::UTF8.GetBytes($respJson)
            $response.ContentLength64 = $respBytes.Length
            $response.OutputStream.Write($respBytes, 0, $respBytes.Length)
            $response.Close()
            continue
        }

        # DICOM Preset Series Endpoint (GET / HEAD)
        if ($urlPath -eq "/api/dicom/preset" -and ($request.HttpMethod -eq "GET" -or $isHead)) {
            $eDriveDir = "E:\20251118000395\401"
            $sampleDir = Join-Path $rootDir "dicom_sample"
            $chosenDir = ""
            if (Test-Path $eDriveDir) {
                $chosenDir = $eDriveDir
            } elseif (Test-Path $sampleDir) {
                $chosenDir = $sampleDir
            }

            $fileList = @()
            if ($chosenDir -ne "") {
                $items = Get-ChildItem -Path $chosenDir -Filter "*.dcm" | Sort-Object Name
                foreach ($it in $items) {
                    $fileList += $it.Name
                }
            }

            $presetInfo = @{
                success = $true
                patient_name = "PAN SHAN ZHEN (潘善珍)"
                patient_id = "20251118000395"
                series_id = "401"
                series_description = "Axial 5.0mm Brain Parenchyma uCT 710"
                total_slices = $fileList.Count
                files = $fileList
                source_directory = $chosenDir
            } | ConvertTo-Json -Depth 3

            $response.ContentType = "application/json; charset=utf-8"
            $buf = [System.Text.Encoding]::UTF8.GetBytes($presetInfo)
            $response.ContentLength64 = $buf.Length
            if (-not $isHead) {
                $response.OutputStream.Write($buf, 0, $buf.Length)
            }
            $response.Close()
            continue
        }

        # DICOM Preset File Stream Endpoint (GET / HEAD)
        if ($urlPath -eq "/api/dicom/preset_file" -and ($request.HttpMethod -eq "GET" -or $isHead)) {
            $fName = $request.QueryString["name"]
            $fName = [System.IO.Path]::GetFileName($fName)
            $ePath = Join-Path "E:\20251118000395\401" $fName
            $samplePath = Join-Path $rootDir ("dicom_sample\" + $fName)

            $targetPath = ""
            if (Test-Path $ePath) { $targetPath = $ePath }
            elseif (Test-Path $samplePath) { $targetPath = $samplePath }

            if ($targetPath -ne "" -and (Test-Path $targetPath -PathType Leaf)) {
                $dcmBytes = [System.IO.File]::ReadAllBytes($targetPath)
                $response.ContentType = "application/dicom"
                $response.ContentLength64 = $dcmBytes.Length
                if (-not $isHead) {
                    $response.OutputStream.Write($dcmBytes, 0, $dcmBytes.Length)
                }
            } else {
                $response.StatusCode = 404
                $errMsg = [System.Text.Encoding]::UTF8.GetBytes("DICOM file not found")
                $response.ContentLength64 = $errMsg.Length
                if (-not $isHead) {
                    $response.OutputStream.Write($errMsg, 0, $errMsg.Length)
                }
            }
            $response.Close()
            continue
        }

        # Static File Handler
        $relPath = $urlPath.TrimStart('/')
        if ($relPath -eq "" -or $relPath -eq "index.html") { $relPath = "index.html" }
        $filePath = Join-Path $rootDir $relPath

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            switch ($ext) {
                ".html" { $response.ContentType = "text/html; charset=utf-8" }
                ".png"  { $response.ContentType = "image/png" }
                ".jpg"  { $response.ContentType = "image/jpeg" }
                ".js"   { $response.ContentType = "application/javascript" }
                ".json" { $response.ContentType = "application/json" }
                ".pdf"  { $response.ContentType = "application/pdf" }
                ".dcm"  { $response.ContentType = "application/dicom" }
                ".webm" { 
                    $response.ContentType = "video/webm"
                    $response.Headers.Add("Accept-Ranges", "bytes")
                }
                ".mp4"  { 
                    $response.ContentType = "video/mp4"
                    $response.Headers.Add("Accept-Ranges", "bytes")
                }
                ".md"   { $response.ContentType = "text/markdown; charset=utf-8" }
                default { $response.ContentType = "application/octet-stream" }
            }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $bytes.Length
            if (-not $isHead) {
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        } else {
            $response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.ContentLength64 = $msg.Length
            if (-not $isHead) {
                $response.OutputStream.Write($msg, 0, $msg.Length)
            }
        }
        $response.Close()
    } catch {
        # continue listening on transient errors
    }
}
