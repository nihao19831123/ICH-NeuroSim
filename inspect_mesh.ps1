$json = Get-Content 'vr_client/skull_mesh.json' -Raw | ConvertFrom-Json
$v = $json.vertices
$minX = 99999; $maxX = -99999; $minY = 99999; $maxY = -99999; $minZ = 99999; $maxZ = -99999;
for ($i = 0; $i -lt $v.Count; $i += 3) {
    $x = $v[$i]; $y = $v[$i+1]; $z = $v[$i+2]
    if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
    if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
    if ($z -lt $minZ) { $minZ = $z }; if ($z -gt $maxZ) { $maxZ = $z }
}
Write-Output "Skull: N=$($v.Count/3) X=[$minX, $maxX] Y=[$minY, $maxY] Z=[$minZ, $maxZ]"

$hjson = Get-Content 'vr_client/hematoma_mesh.json' -Raw | ConvertFrom-Json
$hv = $hjson.vertices
$hminX = 99999; $hmaxX = -99999; $hminY = 99999; $hmaxY = -99999; $hminZ = 99999; $hmaxZ = -99999;
for ($i = 0; $i -lt $hv.Count; $i += 3) {
    $x = $hv[$i]; $y = $hv[$i+1]; $z = $hv[$i+2]
    if ($x -lt $hminX) { $hminX = $x }; if ($x -gt $hmaxX) { $hmaxX = $x }
    if ($y -lt $hminY) { $hminY = $y }; if ($y -gt $hmaxY) { $hmaxY = $y }
    if ($z -lt $hminZ) { $hminZ = $z }; if ($z -gt $hmaxZ) { $hmaxZ = $z }
}
Write-Output "Hematoma: N=$($hv.Count/3) X=[$hminX, $hmaxX] Y=[$hminY, $hmaxY] Z=[$hminZ, $hmaxZ]"
