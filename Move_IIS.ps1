 
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
    }