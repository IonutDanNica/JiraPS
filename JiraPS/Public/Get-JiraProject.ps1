
function Get-JiraProject {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [String[]]
        $Project,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop
        $resourceURi = "$server/rest/api/2/project{0}?expand=description,lead,issueTypes,url,projectKeys"
        
        if ($Credential -and ($Credential -ne [System.Management.Automation.PSCredential]::Empty)) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using credential authentication..."
            $parameter = @{
                Method     = "GET"
                Credential = $Credential
            }    
        }

        $Headers = (Get-JiraSession).WebSession.headers
        if (-not ($Headers)) {
            Write-Error "Unable to obtain authentication headers of the established Jira Session, function exit"
            return
        }
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using bearer authentication..."
        $parameter = @{
            Method     = "GET"
            Headers    = $Headers
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $value = $($resourceURi -f "")
                $parameter["URI"] = $value

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter
        
                Write-Output (ConvertTo-JiraProject -InputObject $result)
            }
            '_Search' {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_project [$_project]"
                    $value = $resourceURi -f "/$($_project)"
                    $parameter["URI"] = $value

                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter
            
                    Write-Output (ConvertTo-JiraProject -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
