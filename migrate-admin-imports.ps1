param([string]$Path = "functions\src", [switch]$DryRun, [switch]$NoBackup)
$ErrorActionPreference = "Stop"
$svcMap = @{
  "firestore" = @{ Fn="getFirestore"; Module="firebase-admin/firestore" }
  "messaging" = @{ Fn="getMessaging"; Module="firebase-admin/messaging" }
  "auth"      = @{ Fn="getAuth";      Module="firebase-admin/auth" }
  "storage"   = @{ Fn="getStorage";   Module="firebase-admin/storage" }
}
$report = @(); $n = 0
foreach ($f in (Get-ChildItem -Recurse -Path $Path -Filter *.ts | Where-Object { $_.Name -notlike "*.d.ts" })) {
  $orig = Get-Content -Raw -LiteralPath $f.FullName
  if ($orig -notmatch 'import \* as admin from "firebase-admin"') { continue }
  $t = $orig; $need = @{}; $notes = @()
  $ms = [regex]::Matches($t, 'admin\.firestore\.([A-Z][A-Za-z0-9_]*)')
  foreach ($m in $ms) {
    $k = "firebase-admin/firestore"
    if (-not $need.ContainsKey($k)) { $need[$k] = @{} }
    $need[$k][$m.Groups[1].Value] = $true
  }
  if ($ms.Count -gt 0) {
    $t = [regex]::Replace($t, 'admin\.firestore\.([A-Z][A-Za-z0-9_]*)', '$1')
    $notes += "$($ms.Count) static/type ref(s)"
  }
  foreach ($s in $svcMap.Keys) {
    $hits = [regex]::Matches($t, "admin\.$s\(\)")
    if ($hits.Count -gt 0) {
      $fn = $svcMap[$s].Fn; $mod = $svcMap[$s].Module
      if (-not $need.ContainsKey($mod)) { $need[$mod] = @{} }
      $need[$mod][$fn] = $true
      $t = [regex]::Replace($t, "admin\.$s\(\)", "$fn()")
      $notes += "$($hits.Count) admin.$s()"
    }
  }
  foreach ($pair in @(@('admin\.initializeApp\(','initializeApp(','initializeApp'),
                      @('admin\.apps\b','getApps()','getApps'),
                      @('admin\.app\(\)','getApp()','getApp'))) {
    if ($t -match $pair[0]) {
      $mod = "firebase-admin/app"
      if (-not $need.ContainsKey($mod)) { $need[$mod] = @{} }
      $need[$mod][$pair[2]] = $true
      $t = $t -replace $pair[0], $pair[1]
      $notes += $pair[2]
    }
  }
  $rel = $f.FullName.Replace((Get-Location).Path + "\", "")
  $left = [regex]::Matches($t, 'admin\.[A-Za-z]')
  if ($left.Count -gt 0) {
    $report += [pscustomobject]@{ File=$rel; Status="NEEDS MANUAL REVIEW"; Detail="$($left.Count) unrecognised admin.* ref(s)" }
    continue
  }
  $lines = foreach ($mod in ($need.Keys | Sort-Object)) {
    "import { " + (($need[$mod].Keys | Sort-Object) -join ", ") + " } from `"$mod`";"
  }
  if ($lines) { $t = $t.Replace('import * as admin from "firebase-admin";', ($lines -join "`r`n")) }
  else { $t = $t -replace 'import \* as admin from "firebase-admin";\r?\n', '' }
  if ($t -eq $orig) { continue }
  $report += [pscustomobject]@{ File=$rel; Status=$(if($DryRun){"would change"}else{"changed"}); Detail=($notes -join "; ") }
  if (-not $DryRun) {
    if (-not $NoBackup) { Copy-Item -LiteralPath $f.FullName -Destination "$($f.FullName).bak" -Force }
    Set-Content -LiteralPath $f.FullName -Value $t -NoNewline -Encoding UTF8
  }
  $n++
}
$report | Format-Table -AutoSize -Wrap
Write-Host ""
if ($DryRun) { Write-Host "DRY RUN - nothing written. $n file(s) would change." -ForegroundColor Cyan }
else { Write-Host "$n file(s) rewritten (.bak kept alongside). Now: cd functions; npm run build" -ForegroundColor Green }
