$skull = Get-Content 'vr_client/skull_mesh.json' -Raw | ConvertFrom-Json
$v = $skull.vertices
$minX=1e9; $maxX=-1e9; $minY=1e9; $maxY=-1e9; $minZ=1e9; $maxZ=-1e9
$sumX=0; $sumY=0; $sumZ=0; $n = $v.Count / 3
for ($i=0; $i -lt $v.Count; $i+=3) {
    $x=$v[$i]; $y=$v[$i+1]; $z=$v[$i+2]
    if($x -lt $minX){$minX=$x}; if($x -gt $maxX){$maxX=$x}
    if($y -lt $minY){$minY=$y}; if($y -gt $maxY){$maxY=$y}
    if($z -lt $minZ){$minZ=$z}; if($z -gt $maxZ){$maxZ=$z}
    $sumX+=$x; $sumY+=$y; $sumZ+=$z
}
Write-Output "Skull Vertices: $n"
Write-Output "Skull X: [$minX, $maxX], Mean=$($sumX/$n)"
Write-Output "Skull Y: [$minY, $maxY], Mean=$($sumY/$n)"
Write-Output "Skull Z: [$minZ, $maxZ], Mean=$($sumZ/$n)"

$hem = Get-Content 'vr_client/hematoma_mesh.json' -Raw | ConvertFrom-Json
$hv = $hem.vertices
$hminX=1e9; $hmaxX=-1e9; $hminY=1e9; $hmaxY=-1e9; $hminZ=1e9; $hmaxZ=-1e9
$hsumX=0; $hsumY=0; $hsumZ=0; $hn = $hv.Count / 3
for ($i=0; $i -lt $hv.Count; $i+=3) {
    $x=$hv[$i]; $y=$hv[$i+1]; $z=$hv[$i+2]
    if($x -lt $hminX){$hminX=$x}; if($x -gt $hmaxX){$hmaxX=$x}
    if($y -lt $hminY){$hminY=$y}; if($y -gt $hmaxY){$hmaxY=$y}
    if($z -lt $hminZ){$hminZ=$z}; if($z -gt $hmaxZ){$hmaxZ=$z}
    $hsumX+=$x; $hsumY+=$y; $hsumZ+=$z
}
Write-Output "Hematoma Vertices: $hn"
Write-Output "Hematoma X: [$hminX, $hmaxX], Mean=$($hsumX/$hn)"
Write-Output "Hematoma Y: [$hminY, $hmaxY], Mean=$($hsumY/$hn)"
Write-Output "Hematoma Z: [$hminZ, $hmaxZ], Mean=$($hsumZ/$hn)"
