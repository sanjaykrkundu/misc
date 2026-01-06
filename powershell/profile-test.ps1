# ==================================================
#  PowerShell 5.1 SAFE STARSHIP-STYLE PROFILE
# ==================================================

# ---------- CONFIG ----------
$PromptTheme = 'Dark'    # Dark | Light
$CompactMode = $true   # false = multiline | true = one-line
# $TimeFormat = 'HH:mm:ss' # 24-hour 
$TimeFormat = 'hh:mm:ss tt' # 12-hour

$PromptModules = @{
    User  = $true
    Path  = $true
    Time  = $true
    ExeTime  = $true
    Exit  = $false
    Admin = $true
}

# ---------- THEMES ----------
$Themes = @{
    Dark = @{
        User  = 'Cyan'
        Path  = 'Yellow'
        Time  = 'DarkCyan'
        Exit  = 'Red'
        Admin = 'Red'
        Symbol = 'DarkGray'
    }
    Light = @{
        User  = 'Blue'
        Path  = 'DarkYellow'
        Time  = 'DarkBlue'
        Exit  = 'DarkRed'
        Admin = 'DarkRed'
        Symbol = 'Gray'
    }
}

# ---------- SAFE SYMBOLS ----------
$Symbols = @{
    Top   = [char]0x250C  # ┌
    Mid   = [char]0x2502  # │
    Bot   = [char]0x2514  # └
    Line  = [char]0x2500  # ─
    Arrow = [char]0x276F  # ❯
    LRound = [char]0xE0B6
    RRound = [char]0xE0B4

    FolderOpen = [char]0xF07C
    Windows     = [char]0xF17A
    Linux       = [char]0xF17C
    Clock       = [char]0xF017
}


# ---------- Declaration ----------
$global:LastCommandStart = Get-Date
$global:LastCommandDuration = $null
$global:user = [Environment]::UserName
$global:IsFirstPrompt = $true

Register-EngineEvent PowerShell.OnCommandPreExecution -Action {
    $global:LastCommandStart = Get-Date
} | Out-Null

Register-EngineEvent PowerShell.OnCommandPostExecution -Action {
    $global:LastCommandDuration = (Get-Date) - $global:LastCommandStart
} | Out-Null

# ---------- HELPERS ----------
function Get-SmartPath {
    $p = (Get-Location).Path.Replace($HOME, '~')
    $parts = $p -split '[\\/]'
    if ($parts.Count -le 3) { return $p }

    $out = $parts[0]
    for ($i = 1; $i -lt $parts.Count - 1; $i++) {
        $out += '\' + $parts[$i][0]
    }
    return $out + '\' + $parts[-1]
}

function Get-ShortPath {
    $p = (Get-Location).Path.Replace($HOME, "~")
    if ($p.Length -gt 45) {
        return "..." + $p.Substring($p.Length - 42)
    }
    return $p
}

function Get-ExitStatus {
    if ($global:IsFirstPrompt) {
        $global:IsFirstPrompt = $false
        return
    }

    if ($LASTEXITCODE -ne 0) {
        return 'exit:' + $LASTEXITCODE
    }
}

function Get-ExecutionTime {
    if ($global:LastCommandDuration -and
        $global:LastCommandDuration.TotalMilliseconds -gt 150) {

        if ($global:LastCommandDuration.TotalSeconds -ge 1) {
            return ('{0:N1}s' -f $global:LastCommandDuration.TotalSeconds)
        }
        return ([int]$global:LastCommandDuration.TotalMilliseconds).ToString() + 'ms'
    }
}

function Is-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Is-SshSession {
    return ($env:SSH_CONNECTION -or $env:SSH_CLIENT -or $env:SSH_TTY)
}

function Get-CurrentTime {
    return (Get-Date).ToString($TimeFormat)
}

function Write-Rounded {
    param($Text, $Bg, $Fg, $First, $Last)
    if ($First){
        Write-Host $Symbols.LRound -ForegroundColor $Bg -BackgroundColor Black -NoNewline
     }
    Write-Host " $Text " -ForegroundColor $Fg -BackgroundColor $Bg -NoNewline
    if ($Last) {
        Write-Host $Symbols.RRound -ForegroundColor $Bg -BackgroundColor Black -NoNewline
    }
    # Write-Host " " -NoNewline
}

# ---------- PROMPT ----------
function prompt {

    $C = $Themes[$PromptTheme]
    $hostN = $env:COMPUTERNAME
    $path  = Get-ShortPath
    $exit  = Get-ExitStatus
    $exetime  = Get-ExecutionTime
    $admin = if (Is-Admin) { 'ADMIN' }
    $OsSymbol = $Symbols.Windows
    $time = Get-CurrentTime

    if (Is-SshSession) {
        $OsSymbol = $Symbols.Linux
    }

    # ---- COMPACT MODE ----
    if ($CompactMode) {
        $path  = Get-SmartPath
        if ($PromptModules.User) {
            # Write-Host ($OsSymbol + ' ' + $user + '@' + $hostN + ' ') -NoNewline -ForegroundColor $C.User
            Write-Rounded ($OsSymbol + ' ' + $user + '@' + $hostN + '') DarkGray $C.User -First $true
        }
        if ($PromptModules.Admin -and $admin) {
            Write-Host ($admin + ' ') -NoNewline -ForegroundColor $C.Admin
        }
        if ($PromptModules.Path) {
            # Write-Host ($Symbols.FolderOpen + ' ' + $path + ' ') -NoNewline -ForegroundColor $C.Path
            Write-Rounded ($Symbols.FolderOpen + ' ' + $path + '') Blue Black
        }
        if ($PromptModules.Time -and $time) {
            # Write-Host ($Symbols.Clock + ' ' + $time + ' ') -NoNewline -ForegroundColor $C.Time
            Write-Rounded ($Symbols.Clock + ' ' + $time + ' ') Yellow Black 
        }

        Write-Rounded ('') DarkGray $C.User -Last $true

        Write-Host (' ' + $Symbols.Arrow + ' ') -NoNewline -ForegroundColor $C.User
        return ' '
    }

    # ---- MULTI-LINE MODE ----

    Write-Host ($Symbols.Top + $Symbols.Line + ' ') -NoNewline -ForegroundColor $C.Symbol
    Write-Host ($OsSymbol + ' ' + $user + '@' + $hostN + ' ') -NoNewline -ForegroundColor $C.User
    Write-Host ($Symbols.FolderOpen + ' ' + $path) -NoNewline -ForegroundColor $C.Path
    Write-Host ''

    Write-Host ($Symbols.Mid + '  ') -NoNewline -ForegroundColor $C.Symbol
    if ($PromptModules.Time -and $time) {
        Write-Host ($Symbols.Clock + ' ' + $time + ' ') -NoNewline -ForegroundColor $C.Time
    }
    if ($PromptModules.ExeTime -and $exetime) {
        Write-Host ($exetime + ' ') -NoNewline -ForegroundColor $C.Time
    }
    if ($PromptModules.Admin -and $admin) {
        Write-Host ($admin + ' ') -NoNewline -ForegroundColor $C.Admin
    }
    if ($PromptModules.Exit -and $exit) {
        Write-Host ($exit + ' ') -NoNewline -ForegroundColor $C.Exit
    }
    Write-Host ''

    Write-Host ($Symbols.Bot) -NoNewline -ForegroundColor $C.Symbol
    Write-Host ($Symbols.Arrow) -NoNewline -ForegroundColor $C.User
    return ' '
}

# ---------- COMMANDS ----------
function reload {
    try {
        . $PROFILE
        # Write-Host 'Profile reloaded' -ForegroundColor Green
    }
    catch {
        # Write-Host 'Profile reload FAILED' -ForegroundColor Red
        Write-Host $_
    }
}

function unzip {
    param (
        [Parameter(Mandatory = $true)] 
        $File
    )

    $DestinationPath = Split-Path -Path $file
    if ([string]::IsNullOrEmpty($DestinationPath)) {
        $DestinationPath=$PWD
    }

    if (Test-Path ($File)) {
        Write-Output "Extracting $File to $DestinationPath"
        Expand-Archive -Path $File -DestinationPath $DestinationPath
    } else {
        $FileName=Split-Path $File -leaf
        Write-Output "File $FileName does not exist"
    }  

}

function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

function trash($path) {
    $fullPath = (Resolve-Path -Path $path).Path

    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath

        if ($item.PSIsContainer) {
            # Handle directory
            $parentPath = $item.Parent.FullName
        } else {
            # Handle file
            $parentPath = $item.DirectoryName
        }

        $shell = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

        if ($item) {
            $shellItem.InvokeVerb('delete')
            Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
        } else {
            Write-Host "Error: Could not find the item '$fullPath' to trash."
        }
    } else {
        Write-Host "Error: Item '$fullPath' does not exist."
    }
}

# Enhanced Listing
function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }


# ---------- Compact mode ----------
function compact-on  { $global:CompactMode = $true }
function compact-off { $global:CompactMode = $false }

# ---------- Themes ----------
function theme-dark { $global:PromptTheme = 'Dark' }
function theme-light { $global:PromptTheme = 'Light' }

# ---------- ALIASES ----------
Set-Alias ll Get-ChildItem
Set-Alias grep Select-String
Set-Alias touch New-Item

# ---------- ALIASES for commands ----------
Set-Alias td theme-dark
Set-Alias tl theme-light
Set-Alias off theme-dark
Set-Alias on theme-light
Set-Alias short compact-on
Set-Alias long compact-off

Set-Alias -Name sudo -Value admin


# ---------- STARTUP ----------
Clear-Host
Write-Host 'Welcome'$user -ForegroundColor DarkGreen
