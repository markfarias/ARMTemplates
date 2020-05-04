@{             
    AllNodes = @(             
        @{             
            Nodename = "localhost"       
            Role = "Primary DC"
			PSDscAllowDomainUser = $true			
            PsDscAllowPlainTextPassword = $true
        },
        @{             
            Nodename = "localhost"       
            Role = "Backup DC"
			PSDscAllowDomainUser = $true			
            PsDscAllowPlainTextPassword = $true
        }
    )             
}