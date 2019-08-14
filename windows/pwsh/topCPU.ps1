Get-CimInstance -QueryDialect 'WQL' -Query @"
    select
        *
    from
        Win32_PerfFormattedData_PerfProc_Process
    where
        PercentProcessorTime <> 0
            and Name <> '_Total'
            and Name <> 'Idle'
"@ -Namespace 'root/cimv2' | Sort-Object -Property @('PercentProcessorTime') -Descending | Select-Object -Property @(
    'Name',
    @{ Name = 'PID'; Expression = { $_.IdProcess }},
    @{ Name = "CPU %"; Expression = { [math]::Round($_.PercentProcessorTime / [Environment]::ProcessorCount) }}
) -First 10;

