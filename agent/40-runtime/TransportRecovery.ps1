function Get-AgentTransportRecoveryPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot
    )

    $path = Join-Path $RepositoryRoot 'config\agent-transport-recovery-policy.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Transport recovery policy is missing: $path"
    }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-AgentTransportRecoveryHash {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Value
    )

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes([string]$Value)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Get-AgentTransportRecoverySignal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Policy,
        [AllowNull()]
        [string]$ErrorText,
        [string]$Component = 'unknown',
        [switch]$BeforeCompletion
    )

    $text = [string]$ErrorText
    $matched = New-Object System.Collections.Generic.List[object]
    if ($BeforeCompletion -and -not [string]::IsNullOrWhiteSpace($text)) {
        foreach ($pattern in @($Policy.detection.fatal_patterns)) {
            try {
                if ($text -match [string]$pattern.pattern) {
                    $matched.Add([ordered]@{
                        id = [string]$pattern.id
                        classification = [string]$pattern.classification
                    })
                }
            }
            catch {
                # A malformed optional pattern must not block the host error path.
            }
        }
    }

    $detected = $matched.Count -gt 0
    $classification = if ($detected) { [string]$matched[0].classification } else { 'not-transport-failure' }
    $prompt = if ($detected) { [string]$Policy.user_prompt.message } else { $null }
    return [ordered]@{
        schema_version = 1
        detected = $detected
        restart_required = $detected
        retry_allowed = (-not $detected)
        classification = $classification
        component = if ([string]::IsNullOrWhiteSpace($Component)) { 'unknown' } else { $Component }
        matched_pattern_ids = @($matched | ForEach-Object { [string]$_.id })
        error_sha256 = Get-AgentTransportRecoveryHash $text
        before_completion = [bool]$BeforeCompletion
        preserve_session = [bool]$Policy.recovery.preserve_session
        preserve_pending_writes = [bool]$Policy.recovery.preserve_pending_writes
        automatic_retry = if ($detected) { [string]$Policy.recovery.automatic_retry } else { 'normal_error_path' }
        status = if ($detected) { [string]$Policy.recovery.state_status } else { 'not-applicable' }
        exit_type = if ($detected) { [string]$Policy.recovery.exit_type } else { $null }
        user_message = $prompt
        next_action = if ($detected) { [string]$Policy.recovery.resume_boundary } else { 'continue normal error handling' }
    }
}
