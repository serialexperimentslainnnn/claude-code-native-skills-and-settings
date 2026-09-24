# Lo carga install.ps1 con `.`: aquí vive TODO lo que toca settings.json, que es del usuario (env,
# permisos, modelo). Mismo contrato que hook/settings.sh, en PowerShell: este repo gestiona una sola
# entrada, el hook UserPromptSubmit que vuelca how-to-work.md en cada turno.
#
# El hook se declara con "shell": "powershell" para que no dependa de que Git Bash esté instalado.
# La salida se fuerza a UTF-8: sin eso, la consola de Windows entrega el método con las tildes y los
# guiones rotos.
#
# Contrato con el que lo carga: $Settings, $ClaudeHome, Write-Log y Backup-Item; -WhatIf llega por
# $WhatIfPreference.

$HookFile = 'how-to-work.md'
$HookMarkers = @('how-to-work.md', 'core-directives.md')

function Get-HookCommand {
    $path = (Join-Path $ClaudeHome $HookFile).Replace("'", "''")
    "[Console]::OutputEncoding = [Text.UTF8Encoding]::new(`$false); " +
    "Get-Content -Raw -Encoding UTF8 -LiteralPath '$path'"
}

function Read-Settings {
    if (-not (Test-Path -LiteralPath $Settings)) { return [ordered]@{} }
    try {
        $data = Get-Content -Raw -LiteralPath $Settings | ConvertFrom-Json -AsHashtable
    } catch {
        throw "settings.json no es JSON válido; no lo toco. Arréglalo y reinstala. ($_)"
    }
    if ($data -isnot [System.Collections.IDictionary]) {
        throw 'settings.json no es un objeto JSON; no lo toco. Arréglalo y reinstala.'
    }
    return $data
}

# Escritura atómica: nunca queda un settings.json a medias.
function Write-Settings([System.Collections.IDictionary] $Data) {
    if ($WhatIfPreference) { return }
    $tmp = "$Settings.tmp"
    ConvertTo-Json -InputObject $Data -Depth 100 | Set-Content -LiteralPath $tmp -Encoding utf8NoBOM
    Move-Item -LiteralPath $tmp -Destination $Settings -Force
}

function Get-PromptGroup([System.Collections.IDictionary] $Data) {
    $hooks = $Data['hooks']
    if ($hooks -is [System.Collections.IDictionary]) { $hooks['UserPromptSubmit'] }
}

function Get-PromptHook([System.Collections.IDictionary] $Data) {
    foreach ($group in (Get-PromptGroup $Data)) {
        foreach ($hook in $group['hooks']) {
            if ($hook -is [System.Collections.IDictionary]) { $hook }
        }
    }
}

function Test-StaleHook([System.Collections.IDictionary] $Hook) {
    $command = [string]$Hook['command']
    foreach ($marker in $HookMarkers) {
        if ($command.Contains($marker)) { return $true }
    }
    return $false
}

# Quita de cada grupo los hooks de este repo (y los de la era anterior) y descarta los grupos vacíos.
function Select-LiveHookGroup([object[]] $Groups) {
    foreach ($group in $Groups) {
        $live = @($group['hooks'] | Where-Object {
                $_ -is [System.Collections.IDictionary] -and -not (Test-StaleHook $_)
            })
        if ($live.Count) { $group['hooks'] = $live; $group }
    }
}

function Install-PromptHook {
    $command = Get-HookCommand
    $data = Read-Settings
    if (@(Get-PromptHook $data | Where-Object { $_['command'] -eq $command }).Count) {
        Write-Log "hook: ya está en $Settings"
        return
    }
    Backup-Item $Settings
    Write-Log "hook: UserPromptSubmit -> $command   (en $Settings)"
    $entry = [ordered]@{ type = 'command'; shell = 'powershell'; command = $command; timeout = 5 }
    if ($data['hooks'] -isnot [System.Collections.IDictionary]) { $data['hooks'] = [ordered]@{} }
    $data['hooks']['UserPromptSubmit'] =
        @(Select-LiveHookGroup (Get-PromptGroup $data)) + @([ordered]@{ hooks = @($entry) })
    Write-Settings $data
}

function Uninstall-PromptHook {
    $data = Read-Settings
    if (-not @(Get-PromptHook $data | Where-Object { Test-StaleHook $_ }).Count) {
        Write-Log 'hook: no está (correcto)'
        return
    }
    Backup-Item $Settings
    Write-Log "hook: quitando la reinyección de $Settings"
    $groups = @(Select-LiveHookGroup (Get-PromptGroup $data))
    if ($groups.Count) {
        $data['hooks']['UserPromptSubmit'] = $groups
    } else {
        $data['hooks'].Remove('UserPromptSubmit')
        if ($data['hooks'].Count -eq 0) { $data.Remove('hooks') }
    }
    Write-Settings $data
}
