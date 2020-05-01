@{             
    AllNodes = @(             
        @{             
            Nodename = "localhost"       
            Role = "Primary DC"
            DomainName = "medchartcloud.gov"
		PSDscAllowDomainUser = $true			
            PsDscAllowPlainTextPassword = $true
        }            
    )             
}
