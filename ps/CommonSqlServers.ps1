## Move the drive letters to the correct mapping
# Move DVD from L to Y
$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "L:"'
if($drv) {
    $drv.DriveLetter = "Y:"
    $drv.Put() | Out-Null
}
# Move SQLAudit from I to L
$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "I:"'
if($drv) {
    $drv.DriveLetter = "L:"
    $drv.Put() | Out-Null
}
# Move SQLLogs from H to I
$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "H:"'
if($drv) {
    $drv.DriveLetter = "I:"
    $drv.Put() | Out-Null
}
# Move SQLConfiguration from K to H
$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "K:"'
if($drv) {
    $drv.DriveLetter = "H:"
    $drv.Put() | Out-Null
}
# Move SQLInstall from J to K
$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "J:"'
if($drv) {
    $drv.DriveLetter = "K:"
    $drv.Put() | Out-Null
}
# Move SQLSystemDBs from G to J
$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "G:"'
if($drv) {
    $drv.DriveLetter = "J:"
    $drv.Put() | Out-Null
}
# Move SQLData from F to G
$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "F:"'
if($drv) {
    $drv.DriveLetter = "G:"
    $drv.Put() | Out-Null
}
# Move SQLData from E to F
$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "E:"'
if($drv) {
    $drv.DriveLetter = "F:"
    $drv.Put() | Out-Null
}

## Rename the SQL Server instance computer name
$newname = $env:COMPUTERNAME
Start-Sleep -s 45
$command = @"
    sp_dropserver @@servername; 
    GO
    sp_addserver '{0}',local;
    GO
"@ -f $newname

Invoke-Sqlcmd -ServerInstance "." -Query $command