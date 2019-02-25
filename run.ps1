#!/usr/bin/env pwsh
#Requires -Version 5.0
#Requires -Module Pester, Microsoft.PowerShell.Management, Microsoft.PowerShell.Utility

using namespace System;
using namespace System.IO;


[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Name of the script the test is in')]
    [string] $Test = 'SQLCluster',
    [Parameter(Mandatory = $false, HelpMessage = 'Optional flag for running a single test')]
    [string] $Tag = 'Current',
    [switch] $All,
    [Parameter(ParameterSetName = 'Coverage', Mandatory = $false, HelpMessage = 'Optional flag for running a single describe block')]
    [string] $Func,
    [Parameter(ParameterSetName = 'Coverage')]
    [switch] $CodeCoverage,
    [Parameter(ParameterSetName = 'Coverage', Mandatory = $false)]
    [switch] $WithMetrics,
    [Parameter(ParameterSetName = 'Debug')]
    [switch] $WithDebug,
    [Parameter(ParameterSetName = 'Debug', Mandatory = $true)]
    [int] $Line
);

Set-StrictMode -Version 'Latest';

Import-Module 'Pester';
Import-Module 'Microsoft.PowerShell.Utility';
Import-Module 'Microsoft.PowerShell.Management';

# Parse module information from the buildconfig file
Set-Variable -Name 'module' -Option 'ReadOnly' -Value (
    [File]::ReadAllText("$($PSScriptRoot)/buildconfig.json") | ConvertFrom-Json | Select-Object -ExpandProperty 'powershellModuleName'
);

if ($null -eq (Get-Variable -Name 'Is*')) {
    # Check if the script is being run on Windows
    [bool] $script:IsWindows = (-not (Get-Variable -Name 'IsWindows' -ErrorAction 'Ignore')) -or $IsWindows;
}

if ($script:IsWindows) {
    # Warn the user of that Windows doesnt support ANSI escape color codes so they may see ugly log messages.
    Write-Warning -Message "Your platform doesn't support embedded ansi color codes...Please ignore any ANSI escape code you notice";
}

# Platform metadata
Write-Information -Message @"
    `e[90m
        ⚡︎Running $($PSVersionTable.PSEdition) v$($PSVersionTable.PSVersion) on $($PSVersionTable.Platform) ⚡︎
            Pester: v$((Get-Module -Name 'Pester' -ListAvailable | Select-Object -ExpandProperty 'Version') -as [string])
            OS: $($PSVersionTable.OS)
            PWD: $($PWD.Path.Replace('C:', '').Replace('\', '/'))
    `e[0m
"@ -Tags @('Metadata') -InformationAction 'Continue';


try {
    if ($All.IsPresent) {
        # Run through all of the tests for the module
        Write-Information -Message "`e[035m Starting pester tests.... `e[0m" -InformationAction 'Continue';
        [FileInfo[]] $sourceFiles = Get-ChildItem -Path $module -Include @('*.ps1', '*.psm1') -Exclude @('*.Tests.ps1') -Recurse -File;
        # NOTE: This might take a while depending on the module size
        Invoke-Pester `
            "$($module).Test" `
            -CodeCoverage ($sourceFiles | Select-Object -ExpandProperty 'FullName') `
            -OutputFile 'cov.xml' `
            -OutputFormat NUnitXml;
    } elseif ($CodeCoverage.IsPresent) {
        # Write coverage information to stdout
        Write-Information -Message "`e[035m Starting tests with code coverage for $($Test).... `e[0m" -InformationAction 'Continue';
        if (($null -ne $Tag -and ![string]::IsNullOrEmpty($Tag)) -and ($null -ne $Func -and ![string]::IsNullOrEmpty($Func))) {
            Invoke-Pester -Script "$($module).Test/$($Test).Tests.ps1" -Tag $Tag -CodeCoverage @{
                Path = "$($module)/$($Test).ps1"
                Function = $Func
            };
        } else {
            Invoke-Pester -Script "$($module).Test/$($Test).Tests.ps1" -CodeCoverage @{ Path = "$($module)/$($Test).ps1" };
        }
    } elseif ($WithMetrics.IsPresent) {
        # Generate a NUnit 'cov.xml' file containing code coverage metrics
        Write-Information -Message "`e[035m Starting tests for $($Test).... `e[0m" -InformationAction 'Continue';
        Invoke-Pester `
            -Script "$($module).Test/$($Test).Tests.ps1" `
            -CodeCoverage @{ Path = "$($module).Test/$($Test).Tests.ps1" } `
            -OutputFile 'cov.xml' `
            -OutputFormat NUnitXml
    } elseif ($WithDebug.IsPresent) {
        # Debug the scripts
        Write-Information -Message "`e[035m Debugging $($Test)....`e[0m" -InformationAction 'Continue';
        Set-PSBreakpoint -Line $Line -Script $Test;
        Invoke-Pester -Script "$($module).Test/$($Test).Tests.ps1" -Debug;
    } else {
        Write-Information -Message "`e[035m Starting tests for $($Test).... `e[0m" -InformationAction 'Continue';
        if ($null -ne $Tag -and ![string]::IsNullOrEmpty($Tag)) {
            Invoke-Pester -Script "$($module).Test/$($Test).Tests.ps1" -Tag $Tag;
        } else {
            Invoke-Pester -Script "$($module).Test/$($Test).Tests.ps1";
        }
    }
} catch {
    # Write a non-terminating error to the error stream.
    Write-Error -Exception $PSItem -RecommendedAction 'Try again' -ErrorAction 'Continue';
} finally {
    if ($WithDebug.IsPresent) {
        # Remove any leftover breakpoints
        Get-PSBreakpoint -Script "$($module).Test/$($Test).Tests.ps1" | Remove-PSBreakpoint;
    }
}

Write-Verbose -Message "Completed tests for $($module)";

# Ensure the script exists with the exit code
exit $LASTEXITCODE;
