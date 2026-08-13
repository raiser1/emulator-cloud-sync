<#
Finds near-duplicate photos that survived a `--by-hash` dedupe pass - files whose
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

CONFIDENCE GATING (added 2026-08-12, after a real false positive): matching on
base name is only safe when the base name is itself a unique identifier - e.g.
a capture timestamp like "20180113_170527", which can only ever refer to one
shutter click. It is NOT safe for hand-typed captions like "mesmerized" or
"invite" - those get reused across genuinely different photos in the same
album (proven: 20_Photos/2000 had "mesmerized_42df60c5.jpg", the couple
embracing, clustered against "mesmerized_454746f5.jpg", an unrelated blown-out
white frame - a real photo would have been deleted). No regex fixes this; the
underlying assumption "same normalized name = same photo" is simply false for
caption-named albums. So every cluster is scored:
  - HIGH confidence: the core name (after stripping noise) contains a run of
    6+ consecutive digits - a date/timestamp/ID pattern strong enough to be
    treated as a near-unique key.
  - LOW confidence: no such digit run - a bare word or phrase. Reported for
    human comparison only. NEVER included in the delete-candidate list,
    regardless of -BuildDeleteList.

Usage:
  .\find-near-duplicates.ps1 -Remote "onedrive:20_Photos"
  .\find-near-duplicates.ps1 -Remote "onedrive:20_Photos" -BuildDeleteList

-BuildDeleteList writes a ready `--files-from` candidate list containing ONLY
high-confidence clusters. Recommended for low-stakes personal photo trees
only. Do NOT use it against 30_Portfolio or anything else marked P1/archive -
review those clusters by eye in the CSV and decide by hand; even within a
high-confidence cluster, "keep largest" is a proxy for "least reprocessed,"
not a guarantee of which version is wanted.
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

function Get-CoreName($path) {
  $name = [IO.Path]::GetFileNameWithoutExtension($path)
  $name = $name -replace '\s*\(\d+\)$', ''          # Windows collision counter: " (2)"
  $name = $name -replace '_[0-9a-fA-F]{6,10}$', ''  # upload-conflict hash/CRC suffix
  $name.Trim().ToLowerInvariant()
}

function Get-ClusterKey($path) {
  $dir = [IO.Path]::GetDirectoryName($path)
  "$dir|$(Get-CoreName $path)"
}

function Test-HighConfidence($path) {
  # A run of 6+ consecutive digits (date/timestamp/ID) is strong enough that
  # the name is very unlikely to have been independently reused for a
  # different photo. Anything weaker is a caption, and captions get reused.
  (Get-CoreName $path) -match '\d{6,}'
}

$clusters = $files | Group-Object { Get-ClusterKey $_.Path } | Where-Object Count -gt 1
Write-Host "`n$($clusters.Count) name-clusters with 2+ files (survived hash-dedupe - content genuinely differs)" -ForegroundColor Yellow

$report = foreach ($c in $clusters) {
  $sorted = $c.Group | Sort-Object Size -Descending
  $keepPath = $sorted[0].Path
  $highConf = ($c.Group | ForEach-Object { Test-HighConfidence $_.Path }) -notcontains $false
  foreach ($f in $sorted) {
    [pscustomobject]@{
      Cluster    = $c.Name
      Path       = $f.Path
      SizeMB     = [math]::Round($f.Size / 1MB, 2)
      ModTime    = $f.ModTime
      Confidence = if ($highConf) { 'HIGH (timestamp/ID-like name)' } else { 'LOW (caption - verify by eye)' }
      Suggestion = if ($f.Path -eq $keepPath) { 'KEEP (largest)' } else { 'review' }
    }
  }
}

$report | Sort-Object Confidence, Cluster, SizeMB -Descending |
  Format-Table Cluster, Path, SizeMB, ModTime, Confidence, Suggestion -AutoSize |
  Out-String -Width 300 | Tee-Object "$work\clusters.txt" | Out-Null
$report | Export-Csv "$work\clusters.csv" -NoTypeInformation

$highCount = ($report | Where-Object Confidence -like 'HIGH*' | Select-Object -ExpandProperty Cluster -Unique).Count
$lowCount  = ($report | Where-Object Confidence -like 'LOW*'  | Select-Object -ExpandProperty Cluster -Unique).Count
$potentialMB = ($report | Where-Object { $_.Suggestion -eq 'review' -and $_.Confidence -like 'HIGH*' } | Measure-Object SizeMB -Sum).Sum

Write-Host "`nReport: $work\clusters.csv ($($work)\clusters.txt for a quick read)" -ForegroundColor Cyan
Write-Host "$highCount high-confidence cluster(s) (timestamp/ID-like names), $lowCount low-confidence (captions - eyeball these)" -ForegroundColor Cyan
Write-Host ("Potential reclaim from HIGH-confidence 'review' items only: {0:N1} MB" -f $potentialMB) -ForegroundColor Cyan
Write-Host "LOW-confidence clusters are report-only. Never auto-deleted, regardless of -BuildDeleteList." -ForegroundColor Yellow

if ($BuildDeleteList) {
  $delPaths = $report | Where-Object { $_.Suggestion -eq 'review' -and $_.Confidence -like 'HIGH*' } |
    Select-Object -ExpandProperty Path
  [IO.File]::WriteAllLines("$work\delete-candidates.txt", [string[]]$delPaths)
  Write-Host "`nWrote $($delPaths.Count) HIGH-confidence candidate path(s) to $work\delete-candidates.txt" -ForegroundColor Yellow
  if ($lowCount -gt 0) {
    Write-Host "$lowCount low-confidence cluster(s) were left OUT of the delete list - check clusters.csv and remove them by hand if you confirm they're true duplicates." -ForegroundColor Yellow
  }
  Write-Host "Review clusters.csv FIRST. Then, only once satisfied:" -ForegroundColor Yellow
  Write-Host "  rclone delete `"$Remote`" --files-from `"$work\delete-candidates.txt`" --dry-run"
  Write-Host "  rclone delete `"$Remote`" --files-from `"$work\delete-candidates.txt`""
}
