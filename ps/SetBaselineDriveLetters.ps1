$drv1 = Get-WmiObject win32_volume -Filter 'DriveLetter = "F:"'
if($drv1) {
    $drv1.DriveLetter = "Y:"
    $drv1.Put() | Out-Null
}
$drv2 = Get-WmiObject win32_volume -Filter 'DriveLetter = "E:"'
if($drv2) {
    $drv2.DriveLetter = "F:"
    $drv2.Put() | Out-Null
}
