﻿function Find-TssSecret {
    <#
    .SYNOPSIS
    Find a secret

    .DESCRIPTION
    Find secrets using the filter parameters provided

    .EXAMPLE
    PS C:\> $session = New-TssSession -SecretServer https://alpha -Credential $ssCred
    PS C:\> Find-TssSecret -TssSession $session -FolderId 50 -RpcEnabled

    Return secrets found in folder 50 where RPC is enabled on the secret templates

    .NOTES
    Requires TssSession object returned by New-TssSession
    #>
    [cmdletbinding(DefaultParameterSetName = "filter")]
    [OutputType('TssSecretLookup')]
    param(
        # TssSession object created by New-TssSession for auth
        [Parameter(Mandatory,
            ValueFromPipeline,
            Position = 0)]
        [TssSession]$TssSession,

        # Secret ID to retrieve
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [Alias("SecretId")]
        [int]
        $Id,

        # Return only secrets within a certain folder
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "folder")]
        [int]
        $FolderId,

        # Include secrets in subfolders of the specified FolderId
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "folder")]
        [Alias('IncludeSubFolder')]
        [switch]
        $IncludeSubFolders,

        # Field to filter on
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "field")]
        [string]
        $Field,

        # Text of the field to filter on
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "field")]
        [string]
        $FieldText,

        # Match the exact text of the FieldText
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "field")]
        [switch]
        $ExactMatch,

        # Field-slug to search
        # This overrides the Field filter
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "field")]
        [string]
        $FieldSlug,

        # Secret Template fields to return
        # Only exposed fields can be returned
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "field")]
        [Alias('ExtendedFields')]
        [string[]]
        $ExtendedField,

        # Return only secrets matching a certain extended type
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "field")]
        [int]
        $ExtendedTypeId,

        # Return only secrets matching a certain template
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [Alias('TemplateId')]
        [int]
        $SecretTemplateId,

        # Return only secrets within a certain site
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [int]
        $SiteId,

        # Return only secrets with a certain heartbeat status
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [ValidateSet('Failed','Success','Pending','Disabled','UnableToConnect','UnknownError','IncompatibleHost','AccountLockedOut','DnsMismatch','UnableToValidateServerPublicKey','Processing','ArgumentError','AccessDenied')]
        [string]
        $HeartbeatStatus,

        # Include inactive/disabled secrets
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [switch]
        $IncludeInactive,

        # Exclude active secrets
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [switch]
        $ExcludeActive,

        # Secrets where template has RPC Enabled
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [switch]
        $RpcEnabled,

        # Secrets where you are not the owner and secret is explicitly shared with your user
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [switch]
        $SharedWithMe,

        # Secrets matching certain password types
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [int[]]
        $PasswordTypeIds,

        # Filter based on permission (List, View, Edit or Owner)
        [Parameter(ParameterSetName = "filter")]
        [ValidateSet('List','View','Edit','Owner')]
        [string]
        $Permission,

        # Filter All Secrets, Recent or Favorites
        [Parameter(ParameterSetName = "filter")]
        [ValidateSet('All','Recent','Favorites')]
        [string]
        $Scope,

        # Exclude DoubleLocks from search results
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [Alias('ExcludeDoubleLocks')]
        [switch]
        $ExcludeDoubleLock,

        # Include only secrets with a specific DoubleLock ID assigned
        [Parameter(ParameterSetName = "filter")]
        [Parameter(ParameterSetName = "secret")]
        [int]
        $DoubleLockId,

        # Output the raw response from the REST API endpoint
        [switch]
        $Raw
    )
    begin {
        $tssParams = . $GetParams $PSBoundParameters 'Find-TssSecret'
        $filterParams = . $GetParams $PSBoundParameters 'Find-TssSecret'
        $invokeParams = @{ }

        $filterParams.Remove('Raw')
        $filterParams.Remove('TssSession')
    }

    process {
        Write-Verbose "Provided command parameters: $(. $GetInvocation $PSCmdlet.MyInvocation)"
        if ($tssParams.Contains('TssSession') -and $TssSession.IsValidSession()) {
            if ($tssParams['Id']) {
                $uri = $TssSession.ApiUrl + ("secrets/lookup", $Id -join '/')
            } else {
                $uri = $TssSession.ApiUrl, "secrets/lookup" -join '/'
                $uri += "?take=$($TssSession.Take)"
                $uri += "&filter.includeRestricted=true"

                $filters = @()
                $filterEnum = $filterParams.GetEnumerator()
                foreach ($f in $filterEnum) {
                    switch ($f.Name) {
                        'Field' {
                            $filters += "filter.searchField=$($f.Value)"
                        }
                        'FieldSlug' {
                            $filters += "filter.searchFieldSlug=$($f.Value)"
                        }
                        'FieldText' {
                            $filters += "filter.searchText=$($f.Value)"
                        }
                        'ExactMatch' {
                            $filters += "filter.isExactmatch=$($f.Value)"
                        }
                        'ExtendedField' {
                            foreach ($v in $f.Value) {
                                $filters += "filter.extendedField=$v"
                            }
                        }
                        'PasswordTypeIds' {
                            foreach ($v in $f.Value) {
                                $filters += "filter.passwordTypeIds=$v"
                            }
                        }
                        'Permission' {
                            $filters += switch ($Permission) {
                                'List' { "filter.permissionRequired=1" }
                                'View' { "filter.permissionRequired=2" }
                                'Edit' { "filter.permissionRequired=3" }
                                'Owner' { "filter.permissionRequired=4" }
                            }
                        }
                        'Scope' {
                            $filters += switch ($Permission) {
                                'All' { "filter.scope=1" }
                                'Recent' { "filter.scope=2" }
                                'Favorit' { "filter.scope=3" }
                            }
                        }
                        'RpcEnabled' {
                            $filters += "filter.onlyRPCEnabled=$($f.Value)"
                        }
                        'SharedWithMe' {
                            $filters += "filter.onlySharedWithMe=$($f.Value)"
                        }
                        'ExcludeDoubleLock' {
                            $filters += "filter.allowDoubleLocks=$($f.Value)"
                        }
                        'ExcludeActive' {
                            $filters += "filter.includeActive=$($f.Value)"
                        }
                        default {
                            $filters += "filter.$($f.name)=$($f.Value)"
                        }
                    }
                }
                $uriFilter = $filters -join '&'
                Write-Verbose "Filters: $uriFilter"
                $uri = $uri, $uriFilter -join '&'
            }


            $invokeParams.Uri = $uri
            $invokeParams.PersonalAccessToken = $TssSession.AccessToken
            $invokeParams.Method = 'GET'
            Write-Verbose "$($invokeParams.Method) $uri"
            try {
                $restResponse = Invoke-TssRestApi @invokeParams
            } catch {
                Write-Warning "Issue on search request"
                $err = $_.ErrorDetails.Message
                Write-Error $err
            }

            if ($tssParams['Raw']) {
                return $restResponse
            }
            if ($tssParams['Id']) {
                . $GetTssSecretLookupObject $restResponse -IsId
            } else {
                if ($restResponse.records.Count -le 0 -and $restResponse.records.Length -eq 0) {
                    Write-Warning "No secrets found"
                }
                if ($restResponse) {
                    . $GetTssSecretLookupObject $restResponse.records
                }
            }
        } else {
            Write-Warning "No valid session found"
        }
    }
}