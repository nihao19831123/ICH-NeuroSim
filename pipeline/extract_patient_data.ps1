# Patient 20251118000395 CT Ingestion and Extraction Script
$patientDir = "E:\20251118000395\401"
$outDir = "C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\vr_client\slices"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$csharp = @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class PatientDicomProcessor {
    public static void ProcessSeries(string folderPath, string outputDir) {
        var files = Directory.GetFiles(folderPath, "*.dcm");
        var list = new List<Tuple<double, string>>();

        foreach (var f in files) {
            byte[] b = File.ReadAllBytes(f);
            double z = 0;
            string s = FindTag(b, 0x0020, 0x0032);
            if (!string.IsNullOrEmpty(s)) {
                var parts = s.Split('\\');
                if (parts.Length == 3) double.TryParse(parts[2], out z);
            }
            list.Add(new Tuple<double, string>(z, f));
        }

        list.Sort((a, b) => a.Item1.CompareTo(b.Item1));

        int minVal = 40 - 80 / 2;  // C=40, W=80
        int maxVal = 40 + 80 / 2;

        for (int i = 0; i < list.Count; i++) {
            string filePath = list[i].Item2;
            byte[] b = File.ReadAllBytes(filePath);
            int offset = b.Length - 524288;
            if (offset < 0) continue;

            byte[] rgb = new byte[512 * 512 * 3];
            for (int p = 0; p < 512 * 512; p++) {
                short raw = (short)(b[offset + p * 2] | (b[offset + p * 2 + 1] << 8));
                int hu = raw - 1024;
                byte gray = 0;
                if (hu <= minVal) gray = 0;
                else if (hu >= maxVal) gray = 255;
                else gray = (byte)((hu - minVal) * 255 / 80);

                int baseIdx = p * 3;
                int r = p / 512;
                int c = p % 512;

                // Highlight hematoma (HU 55 to 90) inside brain cavity
                if (hu >= 55 && hu <= 90 && r > 120 && r < 380 && c > 120 && c < 380) {
                    rgb[baseIdx] = (byte)(gray * 0.3);      // B
                    rgb[baseIdx + 1] = (byte)(gray * 0.3);  // G
                    rgb[baseIdx + 2] = (byte)Math.Min(255, gray + 80); // R (Red blood tint)
                } else {
                    rgb[baseIdx] = gray;
                    rgb[baseIdx + 1] = gray;
                    rgb[baseIdx + 2] = gray;
                }
            }

            string outPath = Path.Combine(outputDir, string.Format("slice_{0:D2}.png", i));
            using (Bitmap bmp = new Bitmap(512, 512, PixelFormat.Format24bppRgb)) {
                BitmapData data = bmp.LockBits(new Rectangle(0, 0, 512, 512), ImageLockMode.WriteOnly, PixelFormat.Format24bppRgb);
                Marshal.Copy(rgb, 0, data.Scan0, rgb.Length);
                bmp.UnlockBits(data);
                bmp.Save(outPath, ImageFormat.Png);
            }
        }
    }

    private static string FindTag(byte[] bytes, ushort g, ushort e) {
        for (int i = 132; i < Math.Min(bytes.Length - 10, 4096); i++) {
            if (bytes[i] == (g & 0xFF) && bytes[i+1] == ((g >> 8) & 0xFF) &&
                bytes[i+2] == (e & 0xFF) && bytes[i+3] == ((e >> 8) & 0xFF)) {
                ushort len = (ushort)(bytes[i+6] | (bytes[i+7] << 8));
                int valLen = Math.Min((int)len, 50);
                return System.Text.Encoding.ASCII.GetString(bytes, i+8, valLen).Trim();
            }
        }
        return "";
    }
}
'@

Add-Type -TypeDefinition $csharp -ReferencedAssemblies "System.Drawing" -Language CSharp
Write-Host "Extracting slices from $patientDir to $outDir..."
[PatientDicomProcessor]::ProcessSeries($patientDir, $outDir)

$count = (Get-ChildItem "$outDir\slice_*.png").Count
Write-Host "Done! Successfully generated $count patient CT slice images!"
