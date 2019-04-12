<#
.Synopsis
 Generate a dump file from a process.
.Description
 Writes a dump file using the native 'MiniDumpWriteDump' method from WindowsErrorReporting.
.Parameter Process
 The process or processes to dump.
.Parameter OutputPath
 The path to write the dump file to.
.Parameter Terminate
 Optional switch to kill the process after dump.
.Inputs
 System.Diagnostics.Process
.Outputs
 System.IO.FileInfo
.Example
 Get-Process -Name '*chrome*' | Export-MiniDump -Out '/';
.Example
Export-MiniDump -Process (Get-Process -ProcessId 1234) -OutputPath '~/Desktop';
.Link
 https://docs.blackbaud.com
#>
function Export-MiniDump {
    [CmdletBinding(SupportsTransactions = $false, SupportsPaging = $false, SupportsShouldProcess = $false, RemotingCapability = 'None', HelpUri = 'https://docs.blackbaud.com')]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Processes to dump')]
        [ValidateNotNullOrEmpty()]
        [System.Diagnostics.Process] $Process,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'Path to write the dump file to')]
        [ValidateDrive('A', 'C', 'W', 'X')]
        [Alias('Path', 'Output', 'Out')]
        [string] $OutputPath,

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'Kill process after dump')]
        [switch] $Terminate
    );
    begin {
        [string] $logFile = "$([System.IO.Path]::GetTempPath())/Export-MiniDump-$((Get-Date -Format 'o') -replace ':', '.').log";
        Start-Transcript -Path $logFile -IncludeInvocationHeader | Out-Null;
        Write-Information -MessageData "Validating output path: $($OutputPath)...." -Tags @('Information');
        if (!(Test-Path -Path $OutputPath)) {
            throw 'Unable to validate output path';
        }
        Write-Information -MessageData 'Output path validated...' -Tags @('Information');
        [type] $errorReporting = [PSObject].Assembly.GetType('System.Management.Automation.WindowsErrorReporting');
        [type] $nativeMethods = $errorReporting.GetNestedType('NativeMethods', 'NonPublic');
        [System.Reflection.MethodInfo] $writeDumpFile = $nativeMethods.GetMethod('MiniDumpWriteDump', ([System.Reflection.BindingFlags]::NonPublic, [System.Reflection.BindingFlags]::Static));
    } process {
        try {
            Write-Verbose -Message "Dumping - Name: $($Process.Name) PID: $($Process.Id)...";
            [string] $fileDumpPath = [System.IO.Path]::Combine($OutputPath, "$($Process.Name).dmp");
            [System.IO.FileStream] $fileStream = [System.IO.FileStream]::new($fileDumpPath, [System.IO.FileMode]::Create);
            [object] $result = $writeDumpFile.Invoke($null, @($Process.Handle, $Process.Id, $fileStream.SafeFileHandle, (2 -as [uint32]), [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero));
            [void] $fileStream.Close();
            if (!($result)) {
                Remove-Item -Path $fileDumpPath -Force -ErrorAction 0 | Out-Null;
                throw "$([System.ComponentModel.Win32Exception]::new().Message) - $($Process.Name):$($Process.Id)";
            }
            Write-Verbose -Message "Result - $($fileDumpPath)";
        } catch [System.ComponentModel.Win32Exception] {
            Write-Error -Exception $_.Exception -Message $_.Exception.Message -Category $_.CategoryInfo.Category;
        } catch {
            Write-Warning -Message $_.Exception.Message;
        } finally {
            if ($Terminate.IsPresent) {
                Write-Verbose -Message "Attempting to stop $($Process.Name)";
                $Process | Stop-Process -Force;
            }
        }
    } end {
        Write-Information -MessageData "Transcript can be found in $($logFile)";
        Get-ChildItem -Path $OutputPath -File | Where-Object { $_.Extension -eq '.dmp' };
        Stop-Transcript | Out-Null;
    }
}
