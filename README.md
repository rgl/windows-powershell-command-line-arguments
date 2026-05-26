# About

[![build](https://github.com/rgl/windows-powershell-command-line-arguments/actions/workflows/build.yml/badge.svg)](https://github.com/rgl/windows-powershell-command-line-arguments/actions/workflows/build.yml)

A Windows PowerShell module to convert a windows command line to and from an array of arguments.

## Usage

Manually execute the tests:

```powershell
Install-Module -Name Pester -Scope CurrentUser -RequiredVersion 5.7.1
Import-Module Pester -Version 5.7.1
Invoke-Pester -Output Detailed
```
