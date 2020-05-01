@{             
    AllNodes = @(             
        @{             
		Nodename = "localhost"       
		Role = "Primary DC"
		PSDscAllowDomainUser = $true			
		PsDscAllowPlainTextPassword = $true
	}     
    )          
}
