#!/usr/bin/env pwsh
#Requires -Version 5
#Requires -RunAsAdministrator
#Requires -Modules CimCmdlets

using namespace System;
using namespace System.Management;

Set-StrictMode -Version 'Latest';

Import-Module 'CimCmdlets';

[CimInstance] $softwareService = Get-CimInstance -Namespace 'root/cimv2' -QueryDialect 'WQL' -Query 'select * from SoftwareLicensingService';
$softwareService | Invoke-CimMethod -MethodName 'InstallProductKey' -Arguments @{ ProductKey = $softwareService.OA3xOriginalProductKey };
$softwareService | Invoke-CimMethod -MethodName 'RefreshLicenseStatus';