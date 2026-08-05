---
name: powershell-standards
description: Use when writing or reviewing PowerShell — .ps1/.psm1/.psd1/.ps1xml files, pwsh vs powershell.exe, Set-StrictMode, CmdletBinding, SupportsShouldProcess with -WhatIf/-Confirm, ValidateSet, ValueFromPipeline, $ErrorActionPreference, PSScriptAnalyzer and PSScriptAnalyzerSettings.psd1, Pester *.Tests.ps1, PSResourceGet/Install-PSResource and PowerShell Gallery publishing, SecretManagement and SecretStore, Set-ExecutionPolicy, Authenticode script signing, JEA .pssc session configurations, Constrained Language Mode, ScriptBlock Logging, transcription and AMSI, PSRemoting over WinRM or SSH, or PowerShell steps in CI.
---

# Estándares PowerShell

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo código PowerShell: scripts de automatización, módulos publicables, funciones avanzadas,
pasos de PowerShell en pipelines y su empaquetado, firma y distribución.
Triggers: `.ps1`, `.psm1`, `.psd1`, `.ps1xml`, `.pssc`, `*.Tests.ps1`, `PSScriptAnalyzerSettings.psd1`,
`pwsh`/`powershell.exe`, `Install-PSResource`, `Invoke-Pester`, `Enter-PSSession`, `New-PSSessionConfigurationFile`.
Fija **criterio** (qué usar, qué está vetado, qué verificar), no tutoriales.

**No aplica**: ver
- `windows-server-ad-standards` (**el qué se administra es suyo**: bosque, dominio, OU, GPO, Kerberos/NTLM,
  gMSA/dMSA, Tier 0, PAW, roles de Windows Server. **Aquí solo cómo se escribe el script** que llama al
  módulo `ActiveDirectory`. Regla de corte: si la decisión la toma el directorio, es suya; si la toma el
  código, es de aquí. **Prohibido duplicar aquí criterio de AD.**).
- `bash-linux-scripting-standards` (**frontera recíproca**): shell POSIX/bash es suya, PowerShell es de
  aquí. Criterio de elección en multiplataforma: **si el objetivo es un host Linux, sus binarios y su
  texto por tuberías, se escribe en bash**; si el objetivo es Windows, un API que devuelve objetos
  (.NET, Graph, Az, Exchange, VMware) o hay que manipular estructuras con propiedades, **PowerShell**.
  Su umbral de escape sigue vigente aquí: pasado el punto en que el script es una aplicación, se va a
  `python-standards`/`go-standards`, no a un `.ps1` de 800 líneas.
- `dotnet-standards` (**PowerShell corre sobre .NET, y eso no lo convierte en .NET**): si el problema
  pide una **aplicación** —servicio, API, worker, binario distribuible, rendimiento medido— es .NET;
  si pide **automatización administrativa** —orquestar cmdlets, tocar sistemas, empaquetar un módulo—
  es PowerShell. Cmdlets binarios en C# y el `.csproj` que los compila son de allí; el manifiesto y el
  contrato del módulo, de aquí.
- `iac-standards` (Terraform/OpenTofu y Ansible: **si Ansible o el provider lo hace de forma
  idempotente, no se escribe un script**; PowerShell DSC y `Invoke-DscResource` se decide allí),
  `cicd-standards` (la pipeline que ejecuta los gates de §4, su OIDC y el pinning de acciones),
  `secrets-management-standards` (**dueño de la elección de gestor de secretos**: Vault/KMS/gestor cloud,
  rotación y política. Aquí solo **cómo el script consume** el secreto sin filtrarlo, y `SecretManagement`
  como fachada),
- `identity-access-management-standards` (diseño del IdP, OAuth 2.1/OIDC, PAM/JIT; aquí solo cómo el
  script se autentica sin secreto estático),
- `appsec-standards` (metodología y clases de vulnerabilidad agnósticas; aquí los sinks concretos de
  PowerShell: `Invoke-Expression`, deserialización, inyección de argumentos),
- `offensive-security-standards` (**pentest/red team autorizado, con alcance por escrito**. PowerShell
  es herramienta ofensiva habitual y **esta skill es estrictamente defensiva**: ver la prohibición dura
  de §7 — aquí no se escriben bypasses de AMSI, ofuscación, descargadores ni evasión de logging).

## 2. Toolchain y decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Estado 2026-08 | Motivo |
|---|---|---|---|
| Runtime objetivo | **PowerShell 7.6 (LTS)** | GA 18-mar-2026, fin de soporte **14-nov-2028**, sobre .NET 10 | Es el LTS vigente y el default de todo greenfield |
| Runtime a abandonar | PowerShell 7.4 (LTS) y 7.5 | **ambos mueren el 10-nov-2026** | Migrar ya; no queda margen |
| Windows PowerShell 5.1 | **Solo compatibilidad**, nunca destino | Componente del SO, soporte por el ciclo de vida de **Windows**, no por el de PowerShell; sigue siendo la shell por defecto de Windows Server 2025 | **Congelado en funcionalidad**: no recibe features, solo servicing. Escribir *para* 5.1 es escribir para un runtime muerto en vida |
| Compatibilidad hacia atrás | Declararla, no suponerla: `#Requires -Version 7.4` y `CompatiblePSEditions` en el manifiesto | — | Windows PowerShell 2.0 fue **retirado de Windows Server 2025 con la actualización de sept-2025**; el patrón se repite |
| Linter (gate) | **PSScriptAnalyzer** 1.25.x (MIT) | última release 2026-03 | Único gate de estilo/seguridad estándar del ecosistema |
| Formato | `Invoke-Formatter` de PSScriptAnalyzer con `PSScriptAnalyzerSettings.psd1` versionado | — | No hay `black`/`ruff format` en PowerShell: la consistencia se fija por settings, no por gusto |
| Tests | **Pester 6.x** (Apache-2.0) | **6.0.0 GA 07-jul-2026**, 6.0.1 actual; **v5 pasa a mantenimiento** (solo bugs críticos y seguridad) | v6 corre sobre 5.1 y 7.4+; nueva familia de aserciones, cobertura por profiler, runner paralelo experimental |
| Gestor de módulos | **Microsoft.PowerShell.PSResourceGet** 1.2.x (MIT) — `Install-PSResource`, `Save-PSResource` | Inbox desde PowerShell 7.4 | Sustituye a PowerShellGet 2.x: más rápido, con `-TrustRepository` y verificación explícita |
| PowerShellGet | Solo como **capa de compatibilidad** (v3 mapea la sintaxis v2 sobre PSResourceGet) o v2.2.5 heredado | 7.4 **no** trajo la capa de compatibilidad; ambos módulos conviven | Código nuevo: cmdlets `*-PSResource`. **Verificar qué versión trae tu runtime antes de asumir** |
| Secretos en scripts | **Microsoft.PowerShell.SecretManagement** + extensión del gestor real (Vault, Key Vault, KeePass) | verificar versión (§8) | `SecretStore` local solo para estación de trabajo o CI de un solo nodo; nunca como bóveda corporativa |
| Editor/LSP | Extensión PowerShell de VS Code (usa PSScriptAnalyzer por debajo) | — | El gate manda es CI, no el editor |

**Regla de versión objetivo**: un módulo declara *una* superficie de compatibilidad y la prueba. Soportar
5.1 **y** 7.x a la vez es una decisión con coste (matriz de CI doble, APIs .NET divergentes, sin operadores
modernos): se toma con ADR, no por inercia.

## 3. Estructura y convenciones

- **Nomenclatura de comandos**: `Verbo-Sustantivo`, verbo **de la lista aprobada** (`Get-Verb`) y sustantivo
  **en singular**, con prefijo de módulo para evitar colisión (`Get-AcmeUser`, no `Get-Users`). Un verbo no
  aprobado es un warning de PSScriptAnalyzer y rompe el descubrimiento por `Get-Command -Verb`.
- **Casing**: `PascalCase` en funciones, parámetros y propiedades; `camelCase` en variables locales;
  constantes en `PascalCase`. Cuatro espacios, nunca tabuladores.
- **Alias PROHIBIDOS en script o módulo** (`?`, `%`, `ls`, `cat`, `select`, `where`, `gci`, `curl`/`wget`
  como alias de `Invoke-WebRequest`): sólo en la consola interactiva. Parámetros siempre por nombre completo.
- **Layout de módulo**:
  ```
  MiModulo/
    MiModulo.psd1          # manifiesto: única fuente de verdad de versión y contrato
    MiModulo.psm1          # dot-source de Public/Private + Export-ModuleMember
    Public/Get-Cosa.ps1    # una función pública por fichero, mismo nombre
    Private/ConvertTo-X.ps1
    Tests/Get-Cosa.Tests.ps1
    en-US/                 # ayuda externa (MAML) si aplica
  ```
- **Manifiesto `.psd1` obligatorio** y completo: `ModuleVersion` (SemVer), `RootModule`, `GUID`,
  `PowerShellVersion`, `CompatiblePSEditions`, `RequiredModules` con versión, y **`FunctionsToExport`,
  `CmdletsToExport`, `AliasesToExport` y `VariablesToExport` enumerados explícitamente** — nunca `'*'`:
  el comodín destruye el rendimiento del descubrimiento de comandos y filtra API interna.
- **Toda función pública es una función avanzada**: `[CmdletBinding()]`, bloques `begin/process/end`,
  parámetros tipados, y `[OutputType()]` declarado.
- **Parámetros**: tipado explícito siempre; `[Parameter(Mandatory)]` en lo obligatorio (nunca `Read-Host`
  para pedirlo); `ValidateSet`, `ValidateRange`, `ValidatePattern`, `ValidateNotNullOrEmpty` en el borde
  —la validación va en el atributo, no en un `if` dentro del cuerpo—; `ParameterSetName` en vez de flags
  mutuamente excluyentes comprobadas a mano.
- **Pipeline**: `ValueFromPipeline` / `ValueFromPipelineByPropertyName` en el parámetro de entidad, y la
  lógica **en `process`**, no en `end`. Una función que acepta pipeline y procesa todo en `end` es un bug.
- **`SupportsShouldProcess` obligatorio en toda función que cambie estado**: `[CmdletBinding(SupportsShouldProcess,
  ConfirmImpact='High')]` + `if ($PSCmdlet.ShouldProcess($target, $action))`. `-WhatIf` debe ser real y
  propagarse a las llamadas internas. Destructivo sin `ShouldProcess` = veto.
- **Salida = objetos, nunca texto**: emite `[pscustomobject]` con propiedades estables (o una clase
  `class`/tipo con `.ps1xml` de formato). `Write-Host` **solo** para interacción con un humano en consola;
  jamás como canal de datos ni de log. Formatear (`Format-Table`, `Out-String`) es cosa del consumidor final,
  nunca de una función que otro va a consumir.
- **Streams con propósito**: `Write-Output` datos, `Write-Verbose` traza opcional, `Write-Debug`
  diagnóstico, `Write-Warning` anomalía recuperable, `Write-Error` error no terminante, `Write-Information`
  mensaje estructurado. Un `return` que devuelve un string formateado en vez de un objeto es deuda.
- **`Set-StrictMode -Version Latest` como default**, en la primera línea del módulo o script, junto a
  `$ErrorActionPreference = 'Stop'`. Sin strict mode, una propiedad mal escrita devuelve `$null` en
  silencio y el script continúa: es la clase de bug más cara del lenguaje.
- **Rutas**: `Join-Path`, `$PSScriptRoot`, `[System.IO.Path]`; nunca concatenación con `\` (rompe en
  Linux/macOS). Sin `cd` implícito: los cmdlets aceptan `-Path`.
- **`#Requires`** en scripts: `-Version`, `-Modules`, `-RunAsAdministrator` — declarar la precondición,
  no descubrirla a mitad de ejecución.
- **Comment-based help** en toda función pública: `.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`, `.OUTPUTS`.
  Es API pública, no documentación opcional.

## 4. Calidad: lint, análisis y tests

- **PSScriptAnalyzer como gate que rompe el build**: `Invoke-ScriptAnalyzer -Path . -Recurse -Settings
  ./PSScriptAnalyzerSettings.psd1 -Severity Error,Warning`, y **fallar el job si hay hallazgos**. El fichero
  de settings se versiona; las supresiones van con `[Diagnostics.CodeAnalysis.SuppressMessageAttribute]`
  **con regla concreta y `Justification` escrita** — supresión global o `ExcludeRules` masivo es veto.
  Reglas que no se suprimen nunca: `PSAvoidUsingPlainTextForPassword`,
  `PSAvoidUsingConvertToSecureStringWithPlainText`, `PSUsePSCredentialType`, `PSAvoidUsingInvokeExpression`,
  `PSUseShouldProcessForStateChangingFunctions`, `PSAvoidUsingCmdletAliases`.
- **Compatibilidad como comprobación automática**, no como creencia: reglas
  `PSUseCompatibleCmdlets`/`PSUseCompatibleSyntax`/`PSUseCompatibleCommands` configuradas con los perfiles
  de las plataformas realmente soportadas.
- **Pester 6** para todo módulo con más de una función:
  - Estructura `Describe`/`Context`/`It`, un motivo de fallo por test, AAA. Fichero `*.Tests.ps1` junto al
    módulo, configuración por objeto `New-PesterConfiguration` (nunca parámetros sueltos dispersos por CI).
  - **Cubrir camino feliz, bordes y errores**: parámetros inválidos, entrada vacía por pipeline, objeto
    inexistente, permiso denegado, timeout, `-WhatIf` (que **no** debe tocar nada).
  - `Mock` en las **fronteras** (cmdlets que tocan sistemas: `Invoke-RestMethod`, `Get-ADUser`,
    `Set-Content`), nunca del código bajo test. Verificación con `Should -Invoke` /`Should-Invoke`.
  - **Ruptura v4 → v5** (aún viva en repos legacy): en v4 las variables y el código dentro de `Describe`
    se ejecutaban al vuelo; v5 partió la ejecución en **Discovery** y **Run**, de modo que el código suelto
    dentro de `Describe`/`Context` corre en Discovery y **el setup debe ir en `BeforeAll`/`BeforeEach`**;
    `-TestCases` se resuelve en Discovery. Migrar de v4 no es cambiar la versión: es reescribir el setup.
  - **Ruptura v5 → v6** (verificada en la guía oficial de migración, §8): descubrimiento y ejecución pasan a
    ser **por fichero** (habilita el runner paralelo; cada fichero debe traer su propio setup de discovery);
    `Assert-MockCalled` y `Assert-VerifiableMock` **eliminados**; `-ForEach`/`-TestCases` vacío o `$null`
    ahora **falla** salvo `-AllowNullOrEmptyForEach`; bloques `BeforeAll`/`AfterAll` duplicados en el mismo
    ámbito prohibidos; cobertura basada en profiler por defecto y salida `CoverageGutters` retirada. Soporte
    limitado a Windows PowerShell 5.1 y PowerShell 7.4+.
  - Cero `Start-Sleep` como sincronización en tests. Flaky = se arregla o se borra. Todo bug deja regresión.
- **Gates de CI, en orden de coste creciente** (todos bloquean el merge):
  1. Parseo/sintaxis (`[System.Management.Automation.Language.Parser]::ParseFile`) y `Test-ModuleManifest`.
  2. `Invoke-ScriptAnalyzer` con settings del repo.
  3. `Invoke-Pester` unitarios con cobertura.
  4. Tests de integración contra un sistema real o contenedor, **en matriz de plataformas** (Windows +
     Linux si el módulo se declara multiplataforma; y 5.1 sólo si de verdad lo soportas).
  5. Firma Authenticode del artefacto y publicación.
- Mismo comando en local y en CI. Si CI hace algo irreproducible en local, es un bug del pipeline.
- Cobertura: señal, no meta. Umbral acordado por equipo, main siempre verde.

## 5. Seguridad

**Errores** (la base de todo lo demás):
- `$ErrorActionPreference = 'Stop'` al inicio. PowerShell distingue **errores terminantes** (abortan el
  pipeline, capturables por `try/catch`) de **no terminantes** (van a `$Error` y **el script sigue**): un
  `Remove-Item` fallido sin `-ErrorAction Stop` no lanza excepción y el script continúa creyendo que borró.
- `try/catch/finally` con `catch` **tipado** (`catch [System.IO.FileNotFoundException]`) antes del genérico.
  `finally` para liberar recursos (sesiones, ficheros, `Dispose`), siempre.
- `throw` para abortar el flujo propio; `Write-Error` para reportar un fallo por elemento sin abortar el
  lote (con `-ErrorAction Stop` en la llamada si el consumidor quiere que aborte). `$PSCmdlet.ThrowTerminatingError()`
  en funciones avanzadas cuando el error es del cmdlet, no del elemento.
- **PROHIBIDO** `-ErrorAction SilentlyContinue` para ocultar un fallo que no se ha entendido, y `catch {}`
  vacío. Silenciar solo con comentario que explique por qué ese error es esperado.

**Ejecución y política**:
- **`Set-ExecutionPolicy` NO es un control de seguridad**. Es una barrera contra la ejecución accidental,
  documentada como tal, y se salta trivialmente por diseño (`-EncodedCommand`, canalizar por stdin, copiar
  y pegar el contenido). Tratarla como control en un diseño, un informe de auditoría o una excepción de
  riesgo es un error técnico. `RemoteSigned` es el default razonable en servidores; **`Bypass`/`Unrestricted`
  permanentes están vetados**.
- **El control real es App Control for Business (WDAC)** con política firmada: bajo ella, sólo el código
  autorizado corre en `FullLanguage` y **todo lo demás cae a `ConstrainedLanguage`**, donde el acceso
  arbitrario a .NET y COM desaparece. AppLocker **no está formalmente deprecado a 2026-02** pero Microsoft
  declara que **no cumple los criterios de servicing de característica de seguridad** del MSRC, mientras
  que App Control sí: no lo uses como único mecanismo de CLM. **Verificar el estado antes de fijarlo (§8).**
- **Firma Authenticode** de todo script y módulo que se distribuya, con certificado de firma de código de
  una CA (interna o pública) y **clave en HSM/almacén no exportable**; sello de tiempo (`-TimestampServer`)
  obligatorio para que la firma sobreviva a la caducidad del certificado. Verificar con `Get-AuthenticodeSignature`
  en el destino, no confiar en el origen.

**Logging y detección** (se configuran, no se evitan):
- **Module Logging**, **Script Block Logging** (registra el bloque real, incluida la desofuscación) y
  **transcripción** (`Start-Transcript`/GPO, a un recurso central de sólo-escritura) activos en todos los
  hosts administrados, con los eventos reenviados al SIEM. **AMSI** activo: PowerShell somete cada bloque
  al antimalware antes de ejecutarlo.
- Consecuencia para el que escribe: **todo lo que ejecutes queda registrado, incluidos los secretos que
  pases en línea de comandos**. Nunca un secreto como argumento (`ps`, historial, logs de bloque de script,
  transcripción, `Get-History`).

**Credenciales**:
- `[PSCredential]` y `[SecureString]` como tipos de transporte en memoria; el parámetro de credencial se
  declara `[PSCredential]` con `[System.Management.Automation.Credential()]`.
- **PROHIBIDO** `ConvertTo-SecureString -AsPlainText -Force` con un secreto escrito en el fichero, y
  `ConvertFrom-SecureString` a fichero como "almacén" (en Windows depende de DPAPI del usuario; **en Linux
  y macOS no cifra nada**, es texto plano ofuscado). `SecureString` **no es un control de protección**:
  documentado por Microsoft como no recomendado para nuevo código multiplataforma. Es reducción de
  exposición accidental, no cifrado.
- El secreto se obtiene en **tiempo de ejecución** del gestor (`Get-Secret` de SecretManagement sobre la
  extensión de Vault/Key Vault) o de una identidad federada (managed identity, OIDC del runner de CI).
  **Preferir no tener secreto**: la elección del gestor y la política de rotación son de
  `secrets-management-standards`.
- Nunca secretos en `.psd1`, en `PrivateData`, en el repo, en variables de entorno persistidas, ni en logs.

**Inyección y entrada no confiable**:
- **`Invoke-Expression` está vetado** sin excepción práctica: es el `eval` de PowerShell y es la vía de
  inyección número uno. Alternativas: llamada directa, *splatting* (`@params`), `& $comando @args`,
  `[scriptblock]` construido en código propio.
- Nada de construir línea de comandos concatenando entrada de usuario para `Start-Process`/`cmd /c`:
  pasar argumentos como array (`-ArgumentList @(...)`).
- SQL desde PowerShell: **solo consultas parametrizadas** (`Invoke-Sqlcmd -Variable`, o `SqlCommand` con
  `Parameters.AddWithValue`). Concatenar es veto — ver `sql-standards`.
- Deserialización: **`Import-Clixml` sobre datos no confiables está vetado** (reconstruye tipos y es un
  vector de ejecución). Para datos externos, `ConvertFrom-Json` (y `-AsHashtable` cuando aplique) con
  validación posterior del esquema.
- Descarga de código: `Invoke-WebRequest`/`Invoke-RestMethod` con TLS verificado; **PROHIBIDO**
  `-SkipCertificateCheck` y cualquier manipulación de `ServerCertificateValidationCallback` fuera de un
  laboratorio. Jamás `iwr ... | iex`.

**Remoting y superficie**:
- **PowerShell Remoting sobre SSH** es el default en escenarios nuevos y multiplataforma (autenticación por
  clave, sin la superficie de WinRM). **WinRM** solo en dominio, con Kerberos (nunca Basic ni credenciales
  en claro), HTTPS, y restringido por firewall a los orígenes de administración.
- **JEA (Just Enough Administration)** para toda delegación operativa: configuración de sesión
  (`.pssc` + `RoleCapabilities` `.psrc`) con `SessionType = 'RestrictedRemoteServer'`, ejecutada bajo una
  **cuenta virtual o gMSA**, con lista blanca de cmdlets y parámetros. El operador no necesita ser admin
  para reiniciar un servicio. JEA sin transcripción activada está incompleto.
- Superficie mínima: no habilites PSRemoting en hosts que no lo necesitan; `Enable-PSRemoting` no es parte
  de una plantilla base por defecto.

## 6. Rendimiento y operabilidad

- **El pipeline es el mecanismo, no un adorno**: filtra en el origen (`Get-ChildItem -Filter`,
  `Get-ADUser -Filter`, `-Query` del servidor) antes de traer todo y filtrar con `Where-Object`. Traer 100k
  objetos para descartar 99k es el antipatrón de rendimiento más común.
- **Nunca `$array += $item` en bucle**: recrea el array completo en cada iteración (O(n²)). Usa
  `[System.Collections.Generic.List[T]]`, o deja que el pipeline recoja la salida.
- Cadenas: `-join` o `StringBuilder`, no `$s += "..."` en bucle.
- **Concurrencia**: `ForEach-Object -Parallel -ThrottleLimit` (7.x) para I/O; `Start-ThreadJob` para trabajo
  con estado compartido controlado; `Start-Job` (proceso completo) solo cuando hace falta aislamiento.
  Cuidado con `$using:` y con el coste de serialización — medir antes de paralelizar.
- **Timeouts explícitos** en toda llamada de red (`Invoke-RestMethod -TimeoutSec`, `-OperationTimeoutSeconds`,
  `-ConnectionTimeoutSeconds`) y en las sesiones remotas: el default puede ser demasiado permisivo o
  demasiado agresivo, pero nunca debe ser implícito.
- **Reintentos** con backoff en operaciones **idempotentes** (`-MaximumRetryCount`/`-RetryIntervalSec` en
  `Invoke-RestMethod`; propio con jitter en lo demás). Reintentar un `POST` no idempotente es duplicar datos.
- **Idempotencia**: un script de automatización se ejecuta dos veces sin daño, o no es de automatización.
  Comprobar estado antes de cambiar; `-WhatIf` como modo de ensayo real.
- **Códigos de salida**: `exit 0` en éxito y no-cero en fallo, siempre — CI y planificadores dependen de él.
  `$LASTEXITCODE` se comprueba tras llamar a binarios nativos (`$?` no basta); en 7.4+ existe
  `$PSNativeCommandUseErrorActionPreference` para integrar el exit code de nativos con `ErrorAction`:
  **verificar el default de tu versión antes de confiar en él (§8)**.
- **Logging estructurado**: emitir objetos y dejar que el consumidor decida, o `Write-Information` con
  objeto; en producción, salida JSON (`ConvertTo-Json -Depth` explícito — el default trunca a 2 niveles y
  ha mordido a todo el mundo). Correlation id en operaciones de larga duración. Nunca datos personales ni
  secretos en el log.
- **Progreso y cancelación**: `Write-Progress` en operaciones largas interactivas (y desactivable en CI con
  `$ProgressPreference = 'SilentlyContinue'`, que además acelera notablemente `Invoke-WebRequest`);
  `finally` que limpie sesiones y ficheros temporales ante `Ctrl+C`.
- Módulos pesados: importa lo que uses (`Import-Module -Name X -Function Y`); el autoloading con
  `FunctionsToExport = '*'` degrada cada arranque de sesión.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: seguir el LTS de PowerShell (que sigue al de .NET) y planificar la migración **antes** de la
  fecha de fin de soporte, no después. A 2026-08 el reloj crítico es **7.4 y 7.5 muriendo el 10-nov-2026**.
- Módulos propios versionados con **SemVer** en el manifiesto, con `CHANGELOG` y publicación desde CI
  (nunca `Publish-PSResource` desde un portátil con una API key personal). Deprecar con warning + ventana.
- Dependencias de PSGallery: **fijar versión** (`RequiredVersion`/`MinimumVersion` en `RequiredModules`),
  registrar el repositorio como `-Trusted` de forma explícita y consciente, y preferir un **feed interno
  con espejo** (Azure Artifacts, ProGet, Nexus) en entorno corporativo: la Galería es un registro público
  sin curación fuerte y el *typosquatting* de nombres de módulo es real. Un módulo sin release en >18 meses
  se revisa o se reemplaza.
- Migración 5.1 → 7.x: inventariar los módulos que sólo existen en Windows PowerShell y probar
  `Import-Module -UseWindowsPowerShell` como puente **temporal y con coste** (proxy por remoting local,
  objetos deserializados sin métodos), nunca como arquitectura final.
- Deuda consciente: atajo = TODO con motivo e issue enlazada.

**Lista de prohibiciones (veto):**
- ❌ `Invoke-Expression` (y `iex`) sobre cualquier cosa que no sea literal propio. Nunca `iwr | iex`.
- ❌ Alias en scripts y módulos; parámetros posicionales en llamadas no triviales.
- ❌ Script o módulo sin `Set-StrictMode -Version Latest` y sin `$ErrorActionPreference = 'Stop'`.
- ❌ `catch {}` vacío, `-ErrorAction SilentlyContinue` como forma de ignorar un fallo no entendido.
- ❌ Función que cambia estado sin `SupportsShouldProcess`/`ShouldProcess`, o con `-WhatIf` decorativo.
- ❌ `Write-Host` como canal de datos o de log. Devolver strings formateados en vez de objetos.
- ❌ `ConvertTo-SecureString -AsPlainText -Force` con el secreto en el fichero; secretos en `.psd1`, en
  parámetros de línea de comandos, en el historial o en variables de entorno persistidas.
- ❌ `-SkipCertificateCheck`, deshabilitar validación TLS, o fijar `[Net.ServicePointManager]::SecurityProtocol`
  a protocolos obsoletos.
- ❌ `Import-Clixml` sobre datos externos. `ConvertFrom-Json` sin validar lo deserializado.
- ❌ `FunctionsToExport = '*'` en un manifiesto publicado.
- ❌ `$array += ...` dentro de un bucle sobre colecciones no triviales.
- ❌ `Set-ExecutionPolicy Bypass` persistente, o presentar la execution policy como control de seguridad.
- ❌ WinRM con autenticación Basic, o sobre HTTP fuera de un laboratorio aislado.
- ❌ **Técnicas de evasión: bypass o parcheo de AMSI, desactivación o manipulación de Script Block Logging
  y transcripción, ofuscación de scripts, descargadores (*stagers*) y cargadores en memoria.** Esta skill es
  **defensiva**: aquí se configuran y se verifican esos controles, no se rodean. Todo trabajo ofensivo
  —incluido el legítimo— vive en `offensive-security-standards`, con alcance y autorización por escrito, y
  **no se documenta aquí**.
- ❌ Escribir código nuevo dirigido exclusivamente a Windows PowerShell 5.1 sin ADR que lo justifique.

## 8. Verificación web obligatoria

Antes de fijar versiones o afirmaciones en un proyecto, **verifica online** (WebSearch/WebFetch), preferiendo
`api.github.com/repos/OWNER/REPO/releases/latest` o los feeds `/releases.atom` sobre el HTML de releases:
1. **Ciclo de vida de PowerShell** en la página oficial de *support lifecycle*: ¿sigue 7.6 siendo el LTS?
   ¿salió 7.7 (sobre .NET 11) y con qué fecha? Confirmar que 7.4/7.5 ya han muerto (previsto 10-nov-2026).
2. **Estado de Windows PowerShell 5.1** y del Windows Server actual (a 2026-08, Windows Server 2025 es la
   última versión; hay una *vNext* en preview sin nombre de producto): ¿algún anuncio formal de deprecación,
   o cambio en la shell por defecto?
3. **Pester**: ¿6.1 ya es estable? Releasear la guía oficial `pester.dev/docs/migrations/v5-to-v6` antes de
   migrar; a 2026-08 v5 está en mantenimiento (solo bugs críticos y seguridad).
4. **PSScriptAnalyzer** (1.25.0 a 2026-03, MIT): ¿versión nueva, reglas nuevas, cambios de severidad por
   defecto que rompan el gate? Fijar versión exacta en CI.
5. **PSResourceGet vs PowerShellGet**: qué versión trae **tu** runtime (`Get-Module -ListAvailable`), y si la
   capa de compatibilidad PowerShellGet v3 ya es estable y viene inbox. No asumirlo.
6. **SecretManagement / SecretStore**: versión actual y estado de mantenimiento — **no verificado a ago-2026**,
   confirmar antes de fijar versión.
7. **App Control for Business vs AppLocker**: comprobar la lista oficial de *deprecated features* de Windows
   antes de afirmar el estado de AppLocker (a 2026-02 **no** figuraba como deprecado, pero Microsoft declara
   que no cumple los criterios de servicing de seguridad del MSRC). Verificar también el estado de
   `WldpCanExecuteFile` y el comportamiento de CLM en la build de Windows en uso.
8. **JEA**: estado y limitaciones documentadas en la versión de PowerShell objetivo — **no verificado en
   detalle a ago-2026**.
9. Defaults que cambian con la versión: `$PSNativeCommandUseErrorActionPreference`, features experimentales
   (`Get-ExperimentalFeature`), y CVEs del runtime (GitHub Advisories / MSRC) antes de fijar una versión.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
