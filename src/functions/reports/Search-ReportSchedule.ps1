﻿function Search-ReportSchedule {
    <#
    .SYNOPSIS
    Search report schedule

    .DESCRIPTION
    Search for report schedule(s)

    .EXAMPLE
    $session = New-TssSession -SecretServer https://alpha -Credential $ssCred
    Search-TssReportSchedule -TssSession $session -ReportId 50

    Return all schedules found associated with Report ID 50.

    .EXAMPLE
    $session = New-TssSession -SecretServer https://alpha -Credential $ssCred
    Search-TssReportSchedule -TssSession $session -IncludeDeleted

    Returns list of all report schedules, including those that were deleted

    .LINK
    https://thycotic-ps.github.io/thycotic.secretserver/commands/Search-TssReportSchedule

    .NOTES
    Requires TssSession object returned by New-TssSession
    #>
    [cmdletbinding(DefaultParameterSetName = "filter")]
    [OutputType('TssReportScheduleSummary')]
    param (
        # TssSession object created by New-TssSession for auth
        [Parameter(Mandatory,
            ValueFromPipeline,
            Position = 0)]
        [TssSession]$TssSession,

        # Include deleted reports
        [switch]
        $IncludeDeleted,

        # Report ID
        [int]
        $ReportId,

        # Sort by specific property, default Name
        [string]
        $SortBy = 'Name'
    )
    begin {
        $tssParams = $PSBoundParameters
        $invokeParams = . $GetInvokeTssParams $TssSession

        $reportSchedParams = $PSBoundParameters
        $reportSchedParams.Remove('TssSession')
        $reportSchedParams.Remove('Raw')
    }

    process {
        Write-Verbose "Provided command parameters: $(. $GetInvocation $PSCmdlet.MyInvocation)"
        if ($tssParams.ContainsKey('TssSession') -and $TssSession.IsValidSession()) {
            $uri = $TssSession.ApiUrl, 'reports', 'schedules' -join '/'
            $uri += "?sortBy[0].direction=asc&sortBy[0].name=$SortBy&take=$($TssSession.Take)"

            $filters = @()
            if ($reportSchedParams.ContainsKey('IncludeDeleted')) {
                $filters += "filter.includeDeleted=$IncludeDeleted"
            }
            if ($reportSchedParams.ContainsKey('ReportId')) {
                $filters += "filter.reportId=$ReportId"
            }

            if ($filters) {
                $uriFilter = $filters -join '&'
                Write-Verbose "Filters: $uriFilter"
                $uri = $uri, $uriFilter -join '&'
            }

            $invokeParams.Uri = $uri

            $invokeParams.Method = 'GET'
            Write-Verbose "$($invokeParams.Method) $uri"
            try {
                $restResponse = Invoke-TssRestApi @invokeParams
            } catch {
                Write-Warning "Issue on search request"
                $err = $_
                . $ErrorHandling $err
            }

            if ($restResponse.records.Count -le 0 -and $restResponse.records.Length -eq 0) {
                Write-Warning "No report schedules found"
            }
            if ($restResponse.records) {
                . $TssReportScheduleSummaryObject $restResponse.records
            }
        } else {
            Write-Warning "No valid session found"
        }
    }
}