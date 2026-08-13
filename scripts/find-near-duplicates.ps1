<#
Finds near-duplicate photos that survived a `--by-hash` dedupe pass — files whose
CONTENT differs (different bytes: resized, recompressed, re-exported) but whose
NAME follows the same "human caption + noise suffix" pattern.

Evidence for the pattern (2026-08-11, 20_Photos): every observed noise suffix is
exactly 8 hex characters (e.g. "_5911ea84", "_a6f07a75") - almost certainly a
CRC32 an old upload tool appended on a same-name/different-bytes collision. If
the bytes had matched, that tool would have overwritten instead of renaming -
so anything still clustered by name after --by-hash has ALREADY run is, by
construction, genuinely different content. This script cannot and does not
claim otherwise: it is a fuzzy pass, not a hash-match, and per the project's
100%-match deletion rule it never deletes anything itself.

Usage:
  .\find-near-duplicates.ps1 -Remote "onedrive:20_Photos"
  .\find-near-duplicates.ps1 -Remote "onedrive:20_Photos" -BuildDeleteList

-BuildDeleteList additionally writes a ready `--files-from` candidate list.
Recommended for low-stakes personal photo trees only. Do NOT use it against
30_Portfolio or anything else marked P1/archive - review those clusters by
eye in the CSV and decide by hand; the "keep largest" heuristic below is a
proxy for "least reprocessed," not a guarantee of which version is wanted.
#>
param(
  [Parameter(Mandatory)] [string]$Remote,
  [switch]$BuildDeleteList
)

$work = "$env:USERPROFILE\Desktop\near-dupe-review"
New-Item -ItemType Directory -Force -Path $work | Out-Null

Write-Host "Listing $Remote (metadata only, no download) ..." -ForegroundColor Cyan
$files = rclone lsjson $Remote -R --files-only 2>$null | ConvertFrom-Json
if (-not $files -or $files.Count -eq 0) { Write-Host "No files returned - check the remote path." -ForegroundColor Red; return }
Write-Host "  $($files.Count) files"

function Get-ClusterKey($path) {
  $dir  = [IO.Path]::GetDirectoryName($path)
  $name = [IO.Path]::GetFileNameWithoutExtension($path)
  $name = $name -replace '\s*\(\d+\)$', ''          # Windows collision counter: " (2)"
  $name = $name -replace '_[0-9a-fA-F]{6,10}$', ''  # upload-conflict hash/CRC suffix
  $name = $name.Trim().ToLowerInvariant()
  "$dir|$name"
}

$clusters = $files | Group-Object { Get-ClusterKey $_.Path } | Where-Object Count -gt 1
Write-Host "`n$($clusters.Count) name-clusters with 2+ files (survived hash-dedupe - content genuinely differs)" -ForegroundColor Yellow

$report = foreach ($c in $clusters) {
  $sorted = $c.Group | Sort-Object Size -Descending
  $keepPath = $sorted[0].Path
  foreach ($f in $sorted) {
    [pscustomobject]@{
      Cluster    = $c.Name
      Path       = $f.Path
      SizeMB     = [math]::Round($f.Size / 1MB, 2)
      ModTime    = $f.ModTime
      Suggestion = if ($f.Path -eq $keepPath) { 'KEEP (largest)' } else { 'review' }
    }
  }
}

$report | Sort-Object Cluster, SizeMB -Descending | Format-Table Cluster, Path, SizeMB, ModTime, Suggestion -AutoSize |
  Out-String -Width 300 | Tee-Object "$work\clusters.txt" | Out-Null
$report | Export-Csv "$work\clusters.csv" -NoTypeInformation

$potentialMB = ($report | Where-Object Suggestion -eq 'review' | Measure-Object SizeMB -Sum).Sum
Write-Host "`nReport: $work\clusters.csv ($($work)\clusters.txt for a quick read)" -ForegroundColor Cyan
Write-Host ("Potential reclaim if every 'review' item is confirmed and deleted: {0:N1} MB" -f $potentialMB) -ForegroundColor Cyan
Write-Host "This is a SUGGESTION based on file size, not a hash match. Eyeball the CSV before deleting anything." -ForegroundColor Yellow

if ($BuildDeleteList) {
  $delPaths = $report | Where-Object Suggestion -eq 'review' | Select-Object -ExpandProperty Path
  [IO.File]::WriteAllLines("$work\delete-candidates.txt", [string[]]$delPaths)
  Write-Host "`nWrote $($delPaths.Count) candidate paths to $work\delete-candidates.txt" -ForegroundColor Yellow
  Write-Host "Review clusters.csv FIRST. Then, only once satisfied:" -ForegroundColor Yellow
  Write-Host "  rclone delete `"$Remote`" --files-from `"$work\delete-candidates.txt`" --dry-run"
  Write-Host "  rclone delete `"$Remote`" --files-from `"$work\delete-candidates.txt`""
}
