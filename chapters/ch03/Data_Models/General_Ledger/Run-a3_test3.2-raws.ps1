#Requires -Version 5.1
<#
.SYNOPSIS
    Run a3_test3.2_raw01.sql through a3_test3.2_raw11.sql via sqlcmd.

.DESCRIPTION
    Executes each raw file in order against the target SQL Server/database.
    Results are written to timestamped .txt files in the output directory.
    Empty SQL files are reported but skipped.

.PARAMETER ServerInstance
    SQL Server instance. Default: Crunch2018

.PARAMETER Database
    Database name. Default: Crunch0626

.PARAMETER SqlFilesDirectory
    Directory containing a3_test3.2_raw*.sql files.
    Default: the same directory as this script.

.PARAMETER OutputDirectory
    Directory for result .txt files.
    Default: sub-directory .\raw-results\yyyyMMdd_HHmmss

.PARAMETER UseIntegratedAuth
    Use Windows integrated security (-E). Default: true.

.PARAMETER SqlCmdPath
    Full path to sqlcmd.exe. If not provided, the script searches PATH.

.EXAMPLE
    .\Run-a3_test3.2-raws.ps1

.EXAMPLE
    .\Run-a3_test3.2-raws.ps1 -ServerInstance "MyServer" -Database "MyDb" -OutputDirectory "C:\temp\results"
#>
[CmdletBinding()]
param (
    [string]$ServerInstance = 'Crunch2018',
    [string]$Database = 'Crunch0626',
    [string]$SqlFilesDirectory = $PSScriptRoot,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'raw-results' (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [switch]$UseIntegratedAuth = $true,
    [string]$SqlCmdPath
)

# Locate sqlcmd.exe
if (-not $SqlCmdPath) {
    $sqlCmd = Get-Command sqlcmd.exe -ErrorAction SilentlyContinue
    if (-not $sqlCmd) {
        $commonPaths = @(
            'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe',
            'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\sqlcmd.exe',
            'C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\sqlcmd.exe',
            'C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe'
        )
        foreach ($candidate in $commonPaths) {
            if (Test-Path -LiteralPath $candidate) {
                $SqlCmdPath = $candidate
                break
            }
        }
    } else {
        $SqlCmdPath = $sqlCmd.Source
    }
}

if (-not $SqlCmdPath -or -not (Test-Path -LiteralPath $SqlCmdPath)) {
    throw "sqlcmd.exe not found. Install SQL Server command-line utilities or pass -SqlCmdPath."
}

Write-Host "Using sqlcmd: $SqlCmdPath" -ForegroundColor Cyan
Write-Host "Target: $ServerInstance.$Database" -ForegroundColor Cyan
Write-Host "Output: $OutputDirectory" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

# Build common sqlcmd argument list
$sqlCmdArgs = @(
    '-S', $ServerInstance,
    '-d', $Database,
    '-b',                       # terminate batch on error
    '-I'                        # enable quoted identifiers
)
if ($UseIntegratedAuth) {
    $sqlCmdArgs += '-E'
}

# Discover raw files in numeric order
$rawFiles = 1..11 | ForEach-Object {
    $num = $_.ToString('D2')
    Join-Path $SqlFilesDirectory "a3_test3.2_raw$num.sql"
}

$summary = [System.Collections.Generic.List[object]]::new()

foreach ($file in $rawFiles) {
    $name = Split-Path -Leaf $file
    if (-not (Test-Path -LiteralPath $file)) {
        Write-Host "NOT FOUND : $name" -ForegroundColor Yellow
        $summary.Add([pscustomobject]@{
            File      = $name
            Status    = 'NOT FOUND'
            ExitCode  = $null
            ResultFile = $null
        })
        continue
    }

    if ((Get-Item -LiteralPath $file).Length -eq 0) {
        Write-Host "EMPTY     : $name" -ForegroundColor DarkGray
        $summary.Add([pscustomobject]@{
            File      = $name
            Status    = 'EMPTY SKIPPED'
            ExitCode  = $null
            ResultFile = $null
        })
        continue
    }

    $outFile = Join-Path $OutputDirectory ($name -replace '\.sql$', '.txt')
    Write-Host "RUNNING   : $name" -ForegroundColor Green

    $processArgs = $sqlCmdArgs + @('-i', $file)

    # Use Start-Process to avoid the "open with" dialog and capture streams.
    $stdOutFile = Join-Path $OutputDirectory ($name -replace '\.sql$', '.stdout.tmp')
    $stdErrFile = Join-Path $OutputDirectory ($name -replace '\.sql$', '.stderr.tmp')

    $proc = Start-Process -FilePath $SqlCmdPath -ArgumentList $processArgs `
        -RedirectStandardOutput $stdOutFile `
        -RedirectStandardError $stdErrFile `
        -Wait -NoNewWindow -PassThru

    $stdout = if (Test-Path -LiteralPath $stdOutFile) { Get-Content -Raw -LiteralPath $stdOutFile } else { '' }
    $stderr = if (Test-Path -LiteralPath $stdErrFile) { Get-Content -Raw -LiteralPath $stdErrFile } else { '' }

    $combined = @()
    $combined += "/* FILE: $name */"
    $combined += "/* SERVER: $ServerInstance  DATABASE: $Database */"
    $combined += "/* EXIT CODE: $($proc.ExitCode) */"
    $combined += ""
    if ($stdout) { $combined += $stdout }
    if ($stderr) {
        $combined += ""
        $combined += "/* STDERR */"
        $combined += $stderr
    }
    $combined -join [Environment]::NewLine | Set-Content -Path $outFile -NoNewline

    Remove-Item -LiteralPath $stdOutFile -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $stdErrFile -ErrorAction SilentlyContinue

    if ($proc.ExitCode -eq 0) {
        Write-Host "OK        : $name" -ForegroundColor Green
        $status = 'OK'
    } else {
        Write-Host "FAILED    : $name (exit $($proc.ExitCode))" -ForegroundColor Red
        $status = 'FAILED'
    }

    $summary.Add([pscustomobject]@{
        File       = $name
        Status     = $status
        ExitCode   = $proc.ExitCode
        ResultFile = $outFile
    })
}

# Write summary
$summaryFile = Join-Path $OutputDirectory 'summary.csv'
$summary | Export-Csv -Path $summaryFile -NoTypeInformation

Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Cyan
$summary | Format-Table -AutoSize
Write-Host "Results saved to: $OutputDirectory" -ForegroundColor Cyan
