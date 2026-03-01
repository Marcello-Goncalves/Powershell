using namespace System

# HISTORY ------------------------------------------------------------------------------
if ( $null -eq $env:PS_HISTORY ) {

    $env:PS_HISTORY = "$PSScriptRoot\History\PSHistory.log"

    if ( -not (Test-Path -Path $env:PS_HISTORY)) {
        New-Item -ItemType File -Path $env:PS_HISTORY
    }
}

# STYLING ------------------------------------------------------------------------------
$readLineOptions = @{
    DingTone           = 0
    BellStyle          = 'None'
    DingDuration       = 0
    HistorySavePath    = $env:PS_HISTORY
    ContinuationPrompt = ""
    Colors             = @{
        Command   = 'Blue'
        Parameter = 'DarkCyan'
        Comment   = 'DarkGray'
        Emphasis  = 'White'
        Error     = 'Red'
        Keyword   = 'Magenta'
        Number    = 'DarkYellow'
        Member    = 'DarkBlue'
        Operator  = 'Cyan'
        Variable  = 'DarkRed'
        String    = 'Green'
        Type      = 'Magenta'
    }
}

Set-PSReadLineOption @readLineOptions -ErrorAction SilentlyContinue

# PS7 SPECIFIC
if ($PSVersionTable.PSVersion.Major -like 7) {

    $PSStyle.FileInfo.Extension.Keys | ForEach-Object {
        $PSStyle.FileInfo.Extension[$_] = $PSStyle.Foreground.White
    }

    $PSStyle.FileInfo.SymbolicLink  = $PSStyle.Foreground.BrightMagenta
    $PSStyle.FileInfo.Executable    = $PSStyle.Foreground.BrightBlue
    $PSStyle.FileInfo.Directory     = $PSStyle.Foreground.Yellow

    $PSStyle.Formatting.CustomTableHeaderLabel  = $PSStyle.Foreground.Blue
    $PSStyle.Formatting.TableHeader             = $PSStyle.Foreground.Blue
    $PSStyle.Formatting.Verbose                 = $PSStyle.Foreground.Cyan
    $PSStyle.Formatting.Debug                   = $PSStyle.Foreground.Magenta
}
# GLOBALS ------------------------------------------------------------------------------
Set-Variable -Name DebugPreference  -Value 'Continue'   -Scope Global
Set-Variable -Name PROMPTTAG        -Value $null        -Scope Global
Set-Variable -Name PROMPTTAGCOLOR   -Value 'DarkYellow' -Scope Global

# PROMPT -------------------------------------------------------------------------------
function Prompt {
    $version    = ">_ $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor) "
    $timestamp  = "[ $(Get-Date -Format "HH:mm:ss") ] "

    $location = Get-Location

    $path = $location | Split-Path -NoQualifier

    $promptWidth = ($version + $global:PROMPTTAG + $timestamp + $location.Drive + $path).Length

    if ( $promptWidth -ge [int]($Host.UI.RawUI.WindowSize.Width * 0.75) ) {

        $bar = [IO.Path]::DirectorySeparatorChar

        $folders = $path.Split($bar) | Where-Object { $_ }

        $path = "$bar...$bar" + $( ( $folders | Select-Object -Last 2 ) -join $bar )

        if (!$location.Drive) {
            $path = "$bar$bar" + $( ( $folders | Select-Object -First 2 ) -join $bar ) + $path
        }
    }

    if ($global:PROMPTTAG) {
        Write-Host $global:PROMPTTAG -NoNewline -ForegroundColor $global:PROMPTTAGCOLOR
        Write-Host " - "             -NoNewline -ForegroundColor DarkGray
    }

    Write-Host $version         -NoNewline -ForegroundColor Blue
    Write-Host $timestamp       -NoNewline -ForegroundColor DarkGray
    Write-Host $location.Drive  -NoNewline -ForegroundColor Gray
    Write-Host $path            -NoNewline -ForegroundColor Gray

    return "`n"
}

function Set-PromptTag {
    param (
        [string]
        $Tag = $null,

        [ConsoleColor]
        $Color = 'DarkYellow'
    )

    if ($Tag) {
        Set-Variable -Name PROMPTTAG        -Value $Tag     -Scope Global
        Set-Variable -Name PROMPTTAGCOLOR   -Value $Color   -Scope Global
    }
    else {
        Set-Variable -Name PROMPTTAG        -Value $null     -Scope Global
    }
}

# FUNCTIONS -----------------------------------------------------------------------------
function Set-EnvironmentVariable {
    param (
        [string]$VariableName,
        [string]$Value,
        [ValidateSet('Machine', 'Process', 'User')]
        [EnvironmentVariableTarget]$Target = 'Process'
    )

    [Environment]::SetEnvironmentVariable($VariableName, $Value, $Target)
}

function Get-ConsoleColors {
    return [Enum]::GetValues([ConsoleColor])
}

function Write-ConsoleColors {
    Get-ConsoleColors | ForEach-Object { Write-Host $_ -ForegroundColor $_}
}

function Enter-VSCode( [string[]]$Params ) { 
    $cmd = if ($IsWindows) { 'code.cmd' } else { 'code' } 
    $codePath = Get-Command -Name $cmd | Select-Object -ExpandProperty Source
    return & "$codePath" $Params | Out-Null
}

function Update-Profile {
    Import-Module "$PSScriptRoot\PSProfile.psm1" -Force -Global
}
function Get-ChildItemListAll { Get-ChildItem -Force }

# ALIASES ------------------------------------------------------------------------------
Set-Alias colors    -Value Write-ConsoleColors  -Scope Global
Set-Alias alias     -Value Get-CustomAlias      -Scope Global
Set-Alias code      -Value Enter-VSCode         -Scope Global
Set-Alias wh        -Value Write-Host           -Scope Global
Set-Alias ll        -Value Get-ChildItem        -Scope Global
Set-Alias la        -Value Get-ChildItemListAll -Scope Global

# EXPORT -------------------------------------------------------------------------------
Export-ModuleMember -Function '*' -Cmdlet '*' -Alias '*'
