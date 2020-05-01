$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "F:"'
$drv.DriveLetter = "Y:"
$drv.Put() | Out-Null

$drv = Get-WmiObject win32_volume -Filter 'DriveLetter = "E:"'
$drv.DriveLetter = "F:"
$drv.Put() | Out-Null