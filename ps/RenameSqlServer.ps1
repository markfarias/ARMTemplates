$newname = $env:COMPUTERNAME
Start-Sleep -s 45
$command = @"
    sp_dropserver @@servername; 
    GO
    sp_addserver '{0}',local;
    GO
"@ -f $newname

 

Invoke-Sqlcmd -ServerInstance "." -Query $command