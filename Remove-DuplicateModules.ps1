#!/usr/bin/env pwsh
#Requires -Version 5

using namespace System;

[CmdletBinding()] param();

Set-StrictMode -Version 'Latest';

Get-Module -ListAvailable |
    Select-Object -Property @('Name', 'Version') |
        Group-Object -Property @('Name') |
            Where-Object { $_.Count -ge 2 } |
                ForEach-Object { $_.Group | Sort-Object -Property @('Version') -Top 1 } |
                    ForEach-Object { Uninstall-Module -Name $_.Name -RequiredVersion $_.Version -Force };

