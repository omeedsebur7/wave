$count = 0
$folders = @("lib", "test", "integration_test", "functions", "tools")
foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Get-ChildItem -Path $folder -Recurse -Include *.dart, *.ts, *.js, *.mjs -File | ForEach-Object {
            $path = $_.FullName
            $bytes = [System.IO.File]::ReadAllBytes($path)
            if ($bytes.Length -gt 0 -and $bytes[$bytes.Length - 1] -ne 10) {
                $fs = [System.IO.File]::OpenWrite($path)
                $fs.Position = $fs.Length
                $fs.WriteByte(10)
                $fs.Close()
                Write-Host "FIXED: $($_.Name)"
                $count++
            }
        }
    }
}
Write-Host "Done. Fixed $count files."