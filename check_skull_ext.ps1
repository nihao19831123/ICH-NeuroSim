$skull = Get-Content 'vr_client/skull_mesh.json' -Raw | ConvertFrom-Json
$v = $skull.vertices
# Let's find extreme points
$ext = [PSCustomObject]@{
    MinX_point = $null; MaxX_point = $null
    MinY_point = $null; MaxY_point = $null
    MinZ_point = $null; MaxZ_point = $null
}
$minX=1e9; $maxX=-1e9; $minY=1e9; $maxY=-1e9; $minZ=1e9; $maxZ=-1e9
for ($i=0; $i -lt $v.Count; $i+=3) {
    $x=$v[$i]; $y=$v[$i+1]; $z=$v[$i+2]
    if ($x -lt $minX) { $minX=$x; $ext.MinX_point = "($x, $y, $z)" }
    if ($x -gt $maxX) { $maxX=$x; $ext.MaxX_point = "($x, $y, $z)" }
    if ($y -lt $minY) { $minY=$y; $ext.MinY_point = "($x, $y, $z)" }
    if ($y -gt $maxY) { $maxY=$y; $ext.MaxY_point = "($x, $y, $z)" }
    if ($z -lt $minZ) { $minZ=$z; $ext.MinZ_point = "($x, $y, $z)" }
    if ($z -gt $maxZ) { $maxZ=$z; $ext.MaxZ_point = "($x, $y, $z)" }
}
Write-Output "Extreme Points:"
$ext | Format-List

# In slice 00 vs slice 15 vs slice 25:
Write-Output "Near Z=0 (mid head):"
$midZ = @()
for ($i=0; $i -lt $v.Count; $i+=3) {
    if ([Math]::Abs($v[$i+2]) -lt 2) {
        $midZ += [PSCustomObject]@{X=$v[$i]; Y=$v[$i+1]; Z=$v[$i+2]}
    }
}
$midMinY = 1e9; $midMaxY = -1e9; $midMinX = 1e9; $midMaxX = -1e9
foreach ($p in $midZ) {
    if ($p.Y -lt $midMinY) { $midMinY = $p.Y }
    if ($p.Y -gt $midMaxY) { $midMaxY = $p.Y }
    if ($p.X -lt $midMinX) { $midMinX = $p.X }
    if ($p.X -gt $midMaxX) { $midMaxX = $p.X }
}
Write-Output "Mid Z range: X=[$midMinX, $midMaxX], Y=[$midMinY, $midMaxY]"
