﻿function Remove-Secret {
    <#
    .SYNOPSIS
    Delete a secret from Secret Server

    .DESCRIPTION
    Delete a secret from Secret Server

    .EXAMPLE
    $session = New-TssSession -SecretServer https://alpha -Credential $ssCred
    Remove-TssSecret -TssSession $session -Id 93

    Delete Secret ID 93

    .LINK
    https://thycotic.secretserver.github.io/commands/Disable-TssSecret

    .NOTES
    Requires TssSession object returned by New-TssSession
    #>
    [cmdletbinding(SupportsShouldProcess)]
    [OutputType('TssDelete')]
    param(
        # TssSession object created by New-TssSession for auth
        [Parameter(Mandatory,
            ValueFromPipeline,
            Position = 0)]
        [TssSession]$TssSession,

        # Secret ID to disable (mark inactive)
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [Alias("SecretId")]
        [int[]]
        $Id
    )
    begin {
        $tssParams = $PSBoundParameters
        $invokeParams = @{ }
    }

    process {
        Write-Verbose "Provided command parameters: $(. $GetInvocation $PSCmdlet.MyInvocation)"
        if ($tssParams.ContainsKey('TssSession') -and $TssSession.IsValidSession()) {

            foreach ($secret in $Id) {
                $uri = $TssSession.ApiUrl, "secrets", $secret.ToString() -join '/'

                $invokeParams.Uri = $Uri
                $invokeParams.PersonalAccessToken = $TssSession.AccessToken
                $invokeParams.Method = 'DELETE'

                if (-not $PSCmdlet.ShouldProcess($secret, "$($invokeParams.Method) $uri")) { return }
                Write-Verbose "$($invokeParams.Method) $uri"
                try {
                    $restResponse = Invoke-TssRestApi @invokeParams
                } catch {
                    Write-Warning "Issue disabling secret [$secret]"
                    $err = $_.ErrorDetails.Message
                    Write-Error $err
                }

                if ($restResponse) {
                    [TssDelete]@{
                        Id         = $restResponse.id
                        ObjectType = $restResponse.objectType
                    }
                }
            }
        } else {
            Write-Warning "No valid session found"
        }
    }
}