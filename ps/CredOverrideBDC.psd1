@{             
    AllNodes = @(             
        @{             
            Nodename = "localhost"       
            Role = "Backup DC"
			PSDscAllowDomainUser = $true			
            PsDscAllowPlainTextPassword = $true
        }
    )             
}
