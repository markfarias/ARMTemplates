<#
.Synopsis
    Moves the Default IIS Directory to another drive
.DESCRIPTION
    Moves the Default IIS Directory to another drive
    Configure-IISMove IIS based on these three links:
    https://technet.microsoft.com/en-us/library/jj635855(v=ws.11).aspx
    http://blogs.iis.net/thomad/moving-the-iis7-inetpub-directory-to-a-different-drive
    https://support.microsoft.com/en-nz/kb/2752331
.EXAMPLE
   Configure-IISMove  -Drive H
.EXAMPLE
   
#>
<#
PLEASE BE AWARE: SERVICING (I.E. HOTFIXES AND SERVICE PACKS) WILL STILL REPLACE FILES 
IN THE ORIGINAL DIRECTORIES. THE LIKELIHOOD THAT FILES IN THE INETPUB DIRECTORIES HAVE 
TO BE REPLACED BY SERVICING IS LOW BUT FOR THIS REASON DELETING THE ORIGINAL DIRECTORIES
IS NOT POSSIBLE. 
#>
 
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Drive,
		[Parameter(Mandatory=$true)]
		[string]
		$applicationRoot
 
 
    )
 
    Begin
    {
    $DoesDriveExist= $null
    #Lets see if the drive exists and the drive is not a mapped drive
    $DoesDriveExist = get-psdrive | where {($_.name -eq $drive) -and ($_.root -eq ($drive+":\"))}
    if ($DoesDriveExist ) #If it exists and the drive is not a mapped drive carry on , otherwise error
        {
        Write-Verbose "$drive drive exists"    
        }
    else
        {
        Write-error "$drive drive does not exist or may be a mapped drive  "
        exit
        }
    #Lets backup the web Configuration before we do anything
    Write-Verbose "Backing up IIS configuration"
    Backup-WebConfiguration -Name "Backup Before IIS Hardening"
    
    }
    Process
    {
    #Stop IIS services
    #Because stopping these service also stops the services that depend on them check the dependant services on each service and stop them first
    #e.g. get-service iisadmin | format-list -property name, dependentservices
    stop-service w3logsvc
    stop-service W3SVC
    <#
    REM Copy all content 
    REM /O - copy ACLs
    REM /E - copy sub directories including empty ones
    REM /I - assume destination is a directory
    REM /Q - quiet
    REM echo on, because user will be prompted if content already exists.
    #>
    xcopy $($env:SystemDrive+"\inetpub") $($Drive+":\inetpub") /O /E /I /Q
   <#
    #Move AppPool isolation directory 
    #>
    Write-Verbose "Creating Registry entries" 
    push-location
    #reg add HKLM\System\CurrentControlSet\Services\WAS\Parameters /v ConfigIsolationPath /t REG_SZ /d d:\inetpub\temp\appPools /f
    Set-Location "HKLM:\System\CurrentControlSet\Services\WAS\Parameters"
    set-ItemProperty . -name ConfigIsolationPath $($Drive+":\inetpub\temp\appPools")
    #REM Make sure Service Pack and Hotfix Installers know where the IIS root directories are
    Set-Location "HKLM:\Software\Microsoft\inetstp"
    #reg add HKLM\Software\Microsoft\inetstp /v PathWWWRoot /t REG_SZ /d %MOVETO%inetpub\wwwroot /f 
    set-ItemProperty . -name PathWWWRoot $($Drive+":\inetpub\wwwroot")
    #reg add HKLM\Software\Microsoft\inetstp /v PathFTPRoot /t REG_SZ /d %MOVETO%inetpub\ftproot /f
    set-ItemProperty . -name PathWWWRoot $($Drive+":\inetpub\ftproot")
    #REM Do the same for x64 directories
    Set-Location "HKLM:\Software\Wow6432Node\Microsoft\inetstp"
    #if not "%ProgramFiles(x86)%" == "" reg add HKLM\Software\Wow6432Node\Microsoft\inetstp /v PathWWWRoot /t REG_EXPAND_SZ /d %MOVETO%inetpub\wwwroot /f 
    set-ItemProperty . -name PathWWWRoot $($Drive+":\inetpub\wwwroot")
    #if not "%ProgramFiles(x86)%" == "" reg add HKLM\Software\Wow6432Node\Microsoft\inetstp /v PathFTPRoot /t REG_EXPAND_SZ /d %MOVETO%inetpub\ftproot /f
    set-ItemProperty . -name PathWWWRoot $($Drive+":\inetpub\ftproot")
    pop-location
    #Move logfile directories
    #%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.traceFailedRequestsLogging.directory:"%MOVETO%inetpub\logs\FailedReqLogFiles"
    set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name traceFailedRequestsLogging.directory -value $($Drive+":\inetpub\logs\FailedReqLogFiles")
    #%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.logfile.directory:"%MOVETO%inetpub\logs\logfiles"
    set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory -value $($Drive+":\inetpub\logs\logfiles")
    #%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/log -centralBinaryLogFile.directory:"%MOVETO%inetpub\logs\logfiles"
    set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter  "system.applicationHost/log" -name centralBinaryLogFile.directory  -value $($Drive+":\inetpub\logs\logfiles")
    #%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/log -centralW3CLogFile.directory:"%MOVETO%inetpub\logs\logfiles"
    set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter  "system.applicationHost/log" -name centralW3CLogFile.directory  -value $($Drive+":\inetpub\logs\logfiles")
    #%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.ftpServer.logFile.directory:"%MOVETO%inetpub\logs\logfiles"
    set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name ftpServer.logfile.directory -value $($Drive+":\inetpub\logs\LogFiles")
    #%windir%\system32\inetsrv\appcmd set config -section:system.ftpServer/log -centralLogFile.directory:"%MOVETO%inetpub\logs\logfiles"
    set-WebConfigurationProperty "/system.ftpServer/log" -name centralLogFile.directory -value $($Drive+":\inetpub\logs\LogFiles")
    #REM Move config history location, temporary files, the path for the Default Web Site and the custom error locations
    #%windir%\system32\inetsrv\appcmd set config -section:system.applicationhost/configHistory -path:%MOVETO%inetpub\history
    set-WebConfigurationProperty "/system.applicationhost/configHistory" -name path -value $($Drive+":\inetpub\history")
    #%windir%\system32\inetsrv\appcmd set config -section:system.webServer/asp -cache.disktemplateCacheDirectory:"%MOVETO%inetpub\temp\ASP Compiled Templates"
    set-WebConfigurationProperty "system.webServer/asp" -name cache.disktemplateCacheDirectory -value $($Drive+":\inetpub\temp\ASP Compiled Templates")
    #%windir%\system32\inetsrv\appcmd set config -section:system.webServer/httpCompression -directory:"%MOVETO%inetpub\temp\IIS Temporary Compressed Files"
    set-WebConfigurationProperty "system.webServer/httpCompression" -name directory -value $($Drive+":\inetpub\temp\IIS Temporary Compressed Files")
    #%windir%\system32\inetsrv\appcmd set vdir "Default Web Site/" -physicalPath:%MOVETO%inetpub\wwwroot
    set-ItemProperty 'IIS:\Sites\Default Web Site\' -Name physicalPath -Value $($Drive+":\inetpub\wwwroot\"+$applicationRoot)
    
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='401'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='401']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='403'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='403']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='404'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='404']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='405'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='405']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='406'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='406']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='412'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='412']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='500'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='500']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='501'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='501']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    #%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='502'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
    set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='502']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
 
        
    }
    End
    {
    #Start the Services again
    start-service W3SVC
    start-service w3logsvc
    <#
    echo Moved IIS7 root directory from %systemdrive%\ to %MOVETO%.
    echo.
    echo Please verify if the move worked.
    echo If something went wrong you can restore the old settings via 
    echo     "APPCMD restore backup beforeRootMove" 
    echo and 
    echo     "REG delete HKLM\System\CurrentControlSet\Services\WAS\Parameters\ConfigIsolationPath"
    echo You also have to reset the PathWWWRoot and PathFTPRoot registry values
    echo in HKEY_LOCAL_MACHINE\Software\Microsoft\InetStp.
    echo ===============================================================================
    #>   
    }