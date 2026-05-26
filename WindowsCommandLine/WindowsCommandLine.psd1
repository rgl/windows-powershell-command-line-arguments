@{
    RootModule = 'WindowsCommandLine.psm1'
    ModuleVersion = '0.0.0'
    GUID = '0d835a0a-0563-4435-9725-38d94bfcccc9'
    Author = 'Rui Lopes'
    CompanyName = 'ruilopes.com'
    Copyright = '(c) 2026'
    Description = 'Convert a Windows Command Line to and from an array of Arguments'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'ConvertTo-WindowsCommandLine'
        'ConvertTo-WindowsCommandLineCommandAndArguments'
        'ConvertTo-WindowsCommandLineArguments'
    )
}
