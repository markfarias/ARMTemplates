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
Start-Sleep -s 45
$newname = $env:userdomain
$command = @"
       sp_dropserver @@servername; 
       GO
       sp_addserver '{0}',local;
       GO

declare @CodeNameString  nvarchar(max)
set @CodeNameString = null
SELECT @CodeNameString = Coalesce(@CodeNameString + '; ', '') + 'IF NOT EXISTS (SELECT * FROM master.sys.server_principals WHERE [name] = ''' + [name] + ''')
CREATE LOGIN [{0}\' + right(name, len(name) - charindex('\', name) ) + '] FROM WINDOWS WITH DEFAULT_DATABASE=[' + 
        default_database_name + '], DEFAULT_LANGUAGE=[us_english]'
FROM master.sys.server_principals
where type_desc In ('WINDOWS_GROUP', 'WINDOWS_LOGIN')
AND [name] not like 'BUILTIN%'
and [NAME] not like 'NT %'
and [name] not like '%\SQLServer%'
SELECT @CodeNameString = Coalesce(@CodeNameString + '; ', '') + 'ALTER SERVER ROLE [' + r.name + '] ADD MEMBER [{0}\' + right(l.name, len(l.name) - charindex('\', l.name) ) + ']' 
from master.sys.server_role_members rm
join master.sys.server_principals r on r.principal_id = rm.role_principal_id
join master.sys.server_principals l on l.principal_id = rm.member_principal_id
where l.[name] not in ('sa')
AND l.[name] not like 'BUILTIN%'
and l.[NAME] not like 'NT %'
exec sp_executesql @CodeNameString
"@ -f $newname

Invoke-Sqlcmd -ServerInstance "." -Query $command 
