@{             
    AllNodes = @(             
        @{             
            Nodename = "localhost"       
            Role = "Subordinate CA"
			PSDscAllowDomainUser = $true			
            PsDscAllowPlainTextPassword = $true
        }
    )             
}
