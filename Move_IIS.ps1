 
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Drive,
		[Parameter(Mandatory=$true)]
		[string]
		$applicationRoot,
		[Parameter(Mandatory=$true)]
		[string[]]
		$sites
    )
 
    Begin
    {
		Write-Verbose "Checking for target drive ($Drive)"
		$DoesDriveExist= $null
		#Lets see if the drive exists and the drive is not a mapped drive
		$DoesDriveExist = get-psdrive | where {($_.name -eq $drive) -and ($_.root -eq ($drive+":\"))}
		if ($DoesDriveExist ) #If it exists and the drive is not a mapped drive carry on , otherwise error
			{
			Write-Verbose "$drive drive exists"    
			}
		else
			{
			Write-error "$drive drive does not exist or may be a mapped drive"
			exit
			}
		#Backup the web Configuration before we do anything
		Write-Verbose "Backing up IIS configuration"
		Backup-WebConfiguration -Name "Backup Before IIS Hardening"
    }
    Process
    {
		Write-Verbose "Stopping IIS..."
		#Stop IIS services
		stop-service w3logsvc
		stop-service W3SVC
		Write-Verbose "Moving contents to target..."
		xcopy $($env:SystemDrive+"\inetpub") $($Drive+":\inetpub") /O /E /I /Q
		Write-Verbose "Creating Registry entries" 
		push-location
		Set-Location "HKLM:\System\CurrentControlSet\Services\WAS\Parameters"
		set-ItemProperty . -name ConfigIsolationPath $($Drive+":\inetpub\temp\appPools")
		#Make sure Service Pack and Hotfix Installers know where the IIS root directories are
		Set-Location "HKLM:\Software\Microsoft\inetstp"
		set-ItemProperty . -name PathWWWRoot $($Drive+":\inetpub\wwwroot")
		set-ItemProperty . -name PathFTPRoot $($Drive+":\inetpub\ftproot")
		#Do the same for x64 directories
		Set-Location "HKLM:\Software\Wow6432Node\Microsoft\inetstp"
		set-ItemProperty . -name PathWWWRoot $($Drive+":\inetpub\wwwroot")
		set-ItemProperty . -name PathFTPRoot $($Drive+":\inetpub\ftproot")
		pop-location
		#Move logfile directories
		Write-Verbose "Move logfile directories..."
		set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name traceFailedRequestsLogging.directory -value $($Drive+":\inetpub\logs\FailedReqLogFiles")
		set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory -value $($Drive+":\inetpub\logs\logfiles")
		set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter  "system.applicationHost/log" -name centralBinaryLogFile.directory  -value $($Drive+":\inetpub\logs\logfiles")
		set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter  "system.applicationHost/log" -name centralW3CLogFile.directory  -value $($Drive+":\inetpub\logs\logfiles")
		set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name ftpServer.logfile.directory -value $($Drive+":\inetpub\logs\LogFiles")
		set-WebConfigurationProperty "/system.ftpServer/log" -name centralLogFile.directory -value $($Drive+":\inetpub\logs\LogFiles")
		#Move config history location, temporary files, the path for the Default Web Site and the custom error locations
		set-WebConfigurationProperty "/system.applicationhost/configHistory" -name path -value $($Drive+":\inetpub\history")
		set-WebConfigurationProperty "system.webServer/asp" -name cache.disktemplateCacheDirectory -value $($Drive+":\inetpub\temp\ASP Compiled Templates")
		set-WebConfigurationProperty "system.webServer/httpCompression" -name directory -value $($Drive+":\inetpub\temp\IIS Temporary Compressed Files")
		set-ItemProperty 'IIS:\Sites\Default Web Site\' -Name physicalPath -Value $($Drive+":\inetpub\wwwroot\"+$applicationRoot)
		foreach($site in $sites) {
			$sitePath = 'IIS:\Sites\Default Web Site\'+$site
			Set-ItemProperty $sitePath -Name physicalPath -Value $($Drive+":\inetpub\wwwroot\"+$applicationRoot+"\"+$site)
			Write-Verbose "Changed web app directory for $site"
	}
		Write-Verbose "Moving error pages to target drive..."
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='401']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='403']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='404']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='405']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='406']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='412']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='500']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='501']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
		set-WebConfiguration -Filter "/System.WebServer/HttpErrors/Error[@StatusCode='502']" -Value @{PrefixLanguageFilePath=$($Drive+":\inetpub\custerr")}
    }
    End
    {
		#Start the Services again
		Write-Verbose "Starting IIS..."
		start-service W3SVC
		start-service w3logsvc
    }