BeforeAll {
    $ModuleRootPath = Resolve-Path "$PSScriptRoot\..\WindowsCommandLine\WindowsCommandLine.psd1"
    Import-Module $ModuleRootPath
}

Add-Type @"
using System;
using System.Diagnostics;
using System.Text;
using System.Threading.Tasks;

public class ProcessRunner
{
    public static ProcessResult Run(string fileName, string arguments, int timeoutMilliseconds = 30000)
    {
        var result = new ProcessResult();

        using (var process = new Process())
        {
            process.StartInfo.FileName = fileName;
            process.StartInfo.Arguments = arguments;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.StandardOutputEncoding = Encoding.UTF8;
            process.StartInfo.StandardErrorEncoding = Encoding.UTF8;

            var outputBuilder = new StringBuilder();
            var errorBuilder = new StringBuilder();

            using (var outputWaitHandle = new System.Threading.AutoResetEvent(false))
            using (var errorWaitHandle = new System.Threading.AutoResetEvent(false))
            {
                process.OutputDataReceived += (sender, e) =>
                {
                    if (e.Data == null)
                        outputWaitHandle.Set();
                    else
                        outputBuilder.AppendLine(e.Data);
                };

                process.ErrorDataReceived += (sender, e) =>
                {
                    if (e.Data == null)
                        errorWaitHandle.Set();
                    else
                        errorBuilder.AppendLine(e.Data);
                };

                try
                {
                    process.Start();
                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();

                    if (process.WaitForExit(timeoutMilliseconds))
                    {
                        process.WaitForExit();
                        outputWaitHandle.WaitOne(timeoutMilliseconds);
                        errorWaitHandle.WaitOne(timeoutMilliseconds);

                        result.ExitCode = process.ExitCode;
                        result.StandardOutput = outputBuilder.ToString().TrimEnd();
                        result.StandardError = errorBuilder.ToString().TrimEnd();
                    }
                    else
                    {
                        try
                        {
                            process.Kill();
                        }
                        catch
                        {
                            // ignore.
                        }

                        result.ExitCode = -1;
                        result.StandardError = string.Format("Process timed out after {0} ms", timeoutMilliseconds);
                        result.TimedOut = true;
                    }
                }
                catch (Exception ex)
                {
                    result.ExitCode = -1;
                    result.StandardError = ex.Message;
                }
            }
        }

        return result;
    }
}

public class ProcessResult
{
    public int ExitCode { get; set; }
    public string StandardOutput { get; set; }
    public string StandardError { get; set; }
    public bool TimedOut { get; set; }
}
"@

Describe 'WindowsCommandLine Module Tests' {
    It "Should be running in PowerShell 5.1" {
        $currentVersion = $PSVersionTable.PSVersion
        $currentVersion.Major | Should -Be 5
        $currentVersion.Minor | Should -Be 1
    }

    It 'Create simple command line' {
        $arguments = @("example.exe", "arg 1", "arg 2", "arg 3")
        $result = ConvertTo-WindowsCommandLine $arguments
        $result | Should -Be 'example.exe "arg 1" "arg 2" "arg 3"'
        $commandLineArguments = ConvertTo-WindowsCommandLineArguments $result
        $commandLineArguments | Should -Be $arguments
    }

    It 'Create simple command line command and arguments' {
        $result = ConvertTo-WindowsCommandLineCommandAndArguments @("example 1.exe", "arg 1", "arg 2", "arg 3")
        $result.Command | Should -Be '"example 1.exe"'
        $result.Arguments | Should -Be '"arg 1" "arg 2" "arg 3"'
    }

    It 'Execute and dump the command and arguments' {
        $commandLine = ConvertTo-WindowsCommandLine @("example 1.exe", "arg 1", "arg 2", "arg 3")
        $dumpCommandAndArguments = ConvertTo-WindowsCommandLineCommandAndArguments @(
            "PowerShell.exe",
            "-File", "$PSScriptRoot\dump.ps1",
            "-commandLine", $commandLine,
            "-message", "hello, world!",
            "the ", " end")
        $result = [ProcessRunner]::Run(
            $dumpCommandAndArguments.Command,
            $dumpCommandAndArguments.Arguments)
        $result.ExitCode | Should -Be 0
        $j = $result.StandardOutput | ConvertFrom-Json
        $j.commandLine | Should -Be $commandLine
        $j.message | Should -Be 'hello, world!'
        $j.args | Should -Be @('the ', ' end')
    }
}
