#Requires -Version 7.4
<#
.SYNOPSIS
Instala esta configuración de Claude Code en Windows: el equivalente de install.sh.

.DESCRIPTION
Plancha el CLAUDE.md global, el catálogo de skills y los workflows sobre ~/.claude, y deja puesto el
hook que reinyecta el método en cada turno.

El repositorio es la ÚNICA fuente de verdad. Instalar es un acto explícito que COPIA el estado
actual del repo sobre ~/.claude: así una skill a medio escribir no queda activa en la sesión hasta
que se decide instalarla.

Dirección única: repo -> ~/.claude. Lo que hubiera en el destino y no esté en el repo se elimina,
previo respaldo con marca de tiempo. Nunca se borra nada sin copia.

Excepción deliberada: la memoria del proyecto se ENLAZA (junction, que no pide administrador ni modo
desarrollador), no se copia. Claude Code la escribe en ~/.claude/projects/<slug>/memory durante la
sesión y queremos que eso caiga dentro del repo.

.PARAMETER Uninstall
Quita lo instalado y explica cómo restaurar el último respaldo.

.EXAMPLE
pwsh -File .\install.ps1 -WhatIf
Enseña lo que haría, sin tocar nada.

.EXAMPLE
pwsh -File .\install.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $IsWindows) { throw 'Este instalador es para Windows; en Linux y macOS usa ./install.sh.' }

$Repo = $PSScriptRoot
$ClaudeHome = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME '.claude' }
$Backup = Join-Path $ClaudeHome "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Lo que se plancha: <ruta en el repo> = <ruta bajo ~/.claude>. Nada más; el porqué de cada pieza
# está en la cabecera de install.sh.
$Files = [ordered]@{ 'CLAUDE.md' = 'CLAUDE.md'; 'hook/how-to-work.md' = 'how-to-work.md' }
$Dirs = [ordered]@{ 'skills' = 'skills'; 'workflows' = 'workflows' }

# Restos jubilados en el destino. Un tipo de agente en ~/.claude/agents/ recarga en caliente: dejarlo
# mantendría vivo en la sesión un circuito que el repo ya no tiene.
$Retired = @('core-directives.md', 'agents')

$Settings = Join-Path $ClaudeHome 'settings.json'
. (Join-Path $Repo 'hook/settings.ps1')

# Claude Code nombra el directorio del proyecto sustituyendo por '-' todo carácter que no sea letra
# ASCII o dígito: C:\Users\ana\repo -> C--Users-ana-repo.
$MemoryTarget = Join-Path $ClaudeHome 'projects' ($Repo -replace '[^A-Za-z0-9]', '-') 'memory'

function Write-Log([string] $Message) { Write-Host "  $Message" }

function Assert-Repository {
    $missing = @(@($Files.Keys) + @($Dirs.Keys) |
            Where-Object { -not (Test-Path -LiteralPath (Join-Path $Repo $_)) })
    foreach ($path in $missing) { Write-Warning "FALTA en el repo: $path" }
    if ($missing.Count) { throw 'Repositorio incompleto; abortando.' }
}

function Backup-Item([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    New-Item -ItemType Directory -Force -Path $Backup | Out-Null
    Write-Log "respaldo: $Path -> $Backup\"
    Copy-Item -LiteralPath $Path -Destination $Backup -Recurse -Force
}

function Remove-WithBackup([string] $Path, [string] $Label) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    Backup-Item $Path
    Write-Log "${Label}: $Path"
    Remove-Item -LiteralPath $Path -Recurse -Force
}

# Borra el enlace, nunca lo enlazado: Delete() sin recursión sobre una junction solo quita la junction.
function Remove-Link([System.IO.FileSystemInfo] $Link) {
    if (-not $WhatIfPreference) { $Link.Delete() }
}

# robocopy sale con 0-7 cuando va bien y con 8 o más cuando falla; con -WhatIf solo lista (/L).
function Invoke-Robocopy([string] $Source, [string] $Destination, [string[]] $Flags) {
    $PSNativeCommandUseErrorActionPreference = $false
    $mode = if ($WhatIfPreference) { '/L' } else { '/NFL' }
    robocopy $Source $Destination @Flags /NJH /NJS /NP /NDL $mode | ForEach-Object { "    $_" }
    if ($LASTEXITCODE -ge 8) { throw "robocopy falló ($LASTEXITCODE): $Source -> $Destination" }
}

function Install-MemoryLink {
    $memory = Join-Path $Repo 'memory'
    New-Item -ItemType Directory -Force -Path $memory, (Split-Path $MemoryTarget) | Out-Null
    # Que no exista es el caso normal en la primera instalación.
    $current = Get-Item -LiteralPath $MemoryTarget -Force -ErrorAction Ignore
    if ($current -and $current.LinkType -and $current.Target -eq $memory) {
        Write-Log "memoria ya enlazada: $MemoryTarget"
        return
    }
    if ($current -and $current.LinkType) {
        Write-Log "quitando enlace ajeno: $MemoryTarget -> $($current.Target)"
        Remove-Link $current
    } elseif ($current -and $current.PSIsContainer) {
        # Un directorio real con contenido no se tira: se respalda y se rescata al repo.
        if (Get-ChildItem -LiteralPath $MemoryTarget -Force) {
            Backup-Item $MemoryTarget
            Write-Log "memoria con contenido propio: rescatando a $memory antes de enlazar"
            Invoke-Robocopy $MemoryTarget $memory @('/E', '/XC', '/XN', '/XO')
        }
        Remove-Item -LiteralPath $MemoryTarget -Recurse -Force
    } elseif ($current) {
        Remove-WithBackup $MemoryTarget 'quitando fichero'
    }
    Write-Log "enlace: $MemoryTarget -> $memory"
    New-Item -ItemType Junction -Path $MemoryTarget -Target $memory | Out-Null
}

function Install-Configuration {
    Assert-Repository
    Write-Host "Instalando desde $Repo en $ClaudeHome"
    New-Item -ItemType Directory -Force -Path $ClaudeHome | Out-Null

    foreach ($pair in $Files.GetEnumerator()) {
        $source = Join-Path $Repo $pair.Key
        $dest = Join-Path $ClaudeHome $pair.Value
        if ((Test-Path -LiteralPath $dest) -and
            (Get-FileHash -LiteralPath $source).Hash -eq (Get-FileHash -LiteralPath $dest).Hash) {
            Write-Log "sin cambios: $dest"
            continue
        }
        Backup-Item $dest
        Write-Log "copia: $dest <- $source"
        Copy-Item -LiteralPath $source -Destination $dest -Force
    }

    foreach ($pair in $Dirs.GetEnumerator()) {
        $source = Join-Path $Repo $pair.Key
        $dest = Join-Path $ClaudeHome $pair.Value
        Backup-Item $dest
        Write-Log "espejo: $dest <- $source   (se elimina lo que sobre en el destino)"
        Invoke-Robocopy $source $dest @('/MIR')
    }

    Install-MemoryLink
    Install-PromptHook
    foreach ($name in $Retired) { Remove-WithBackup (Join-Path $ClaudeHome $name) 'quitando jubilado' }

    Write-Host "`nHecho. Abre el proyecto en el IDE o una sesión con:  cd '$Repo'; claude"
    if (Test-Path -LiteralPath $Backup) { Write-Host "Lo anterior quedó en: $Backup" }
    Write-Host 'Comprueba los gates con:     ./check.sh   (Git Bash o WSL)'
    Write-Host "Confirma el hook con:        (Get-Content '$Settings' | ConvertFrom-Json).hooks"
}

function Uninstall-Configuration {
    Write-Host "Desinstalando de $ClaudeHome"
    foreach ($name in @($Files.Values) + @($Dirs.Values)) {
        Remove-WithBackup (Join-Path $ClaudeHome $name) 'quitando'
    }
    $link = Get-Item -LiteralPath $MemoryTarget -Force -ErrorAction Ignore
    if ($link -and $link.LinkType) {
        Write-Log "quitando enlace: $MemoryTarget"
        Remove-Link $link
    }

    Uninstall-PromptHook
    foreach ($name in $Retired) { Remove-WithBackup (Join-Path $ClaudeHome $name) 'quitando jubilado' }

    if (-not (Test-Path -LiteralPath $ClaudeHome)) { return }
    $last = Get-ChildItem -LiteralPath $ClaudeHome -Directory -Filter 'backup-*' |
        Sort-Object -Property Name | Select-Object -Last 1
    if ($last) {
        Write-Host "`nHay un respaldo en $($last.FullName). Para restaurarlo:"
        Write-Host "  Copy-Item -Recurse -Force '$($last.FullName)\*' '$ClaudeHome'"
    }
}

if ($Uninstall) { Uninstall-Configuration } else { Install-Configuration }
exit 0
