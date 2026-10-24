$skull = Get-Content 'vr_client/skull_mesh.json' -Raw | ConvertFrom-Json
$v = $skull.vertices
Write-Output "Total vertices: $($v.Count/3)"
Write-Output "Total indices: $($skull.indices.Count)"

# Let's check slices of vertices in Z
$zBins = @{}
for ($i=0; $i -lt $v.Count; $i+=3) {
    $z = [Math]::Round($v[$i+2], 0)
    if (-not $zBins.ContainsKey($z)) { $zBins[$z] = 0 }
    $zBins[$z]++
}
Write-Output "Z Distribution:"
$zBins.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Output "Z=$($_.Name): $($_.Value) vertices"
}
