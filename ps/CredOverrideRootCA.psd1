@{             
    AllNodes = @(             
        @{             
            Nodename = "localhost"       
            Role = "Root CA"
			PSDscAllowDomainUser = $true			
            PsDscAllowPlainTextPassword = $true
        }
    )             
}
