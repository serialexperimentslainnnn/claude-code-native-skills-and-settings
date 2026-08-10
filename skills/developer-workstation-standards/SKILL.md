---
name: developer-workstation-standards
description: Use when provisioning, hardening or rebuilding the machine a developer works on — versioned dotfiles and a bootstrap script, chezmoi/yadm/GNU stow, Homebrew Brewfile and brew bundle, winget import/export and winget configuration, Nix flake.nix, home-manager, devenv.nix and direnv .envrc, mise with mise.toml and .tool-versions, asdf, nvm/pyenv/rbenv/rustup/uv, .devcontainer/devcontainer.json and the devcontainer CLI, GitHub Codespaces or a cloud dev environment, .editorconfig and formatter/linter config committed to the repo instead of the machine, .vscode/settings.json and .vscode/tasks.json from an untrusted repo, VS Code or Open VSX extension supply chain and malicious extension incidents, curl | sh installers, full-disk encryption with FileVault/BitLocker/LUKS, screen lock and MFA on the workstation, SSH keys in hardware with ed25519-sk or ecdsa-sk and resident or verify-required options, gpg.format ssh and a signing key held on a YubiKey, credential.helper store writing plaintext to ~/.git-credentials, tokens in ~/.netrc or in shell history, pre-commit secret scanning, unattended OS updates, coding agents' filesystem and credential scope on the workstation, build times and RAM as an opportunity cost, or a laptop being used as a server.
---

# Estándares de estación de trabajo del desarrollador

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**La máquina del desarrollador es infraestructura de producción de software.** Es donde vive el
código antes de existir en ningún sitio, donde se guardan las credenciales que abren
producción y donde se ejecuta código de terceros con los permisos de una persona con acceso.
Se trata como infraestructura: **se aprovisiona como código, se endurece y se puede
reconstruir**. Los tres verbos son la tesis, y el tercero es el que se comprueba.

Corolario operativo: ***"funciona en mi máquina" no es una excusa: es un fallo de
aprovisionamiento**, y tiene dueño.* Si el entorno que hace funcionar el proyecto no está
descrito en el repositorio, no existe.

Triggers: *dotfiles*, `chezmoi`, `yadm`, GNU `stow`, script de *bootstrap*, `Brewfile`,
`brew bundle`, `winget import`/`export`, `winget configure`, `flake.nix`, `home-manager`,
`devenv.nix`, `.envrc`, `direnv allow`, `mise.toml`, `.mise.toml`, `.tool-versions`, `mise`,
`asdf`, `nvm`, `pyenv`, `rbenv`, `rustup`, `uv`, `volta`, `.devcontainer/devcontainer.json`,
`devcontainer` CLI, Codespaces, `.editorconfig`, `.vscode/settings.json`,
`.vscode/extensions.json`, `.vscode/tasks.json`, extensiones de VS Code / Open VSX, `curl | sh`,
FileVault, BitLocker, LUKS, `ed25519-sk`, `ecdsa-sk`, `-O resident`, `-O verify-required`,
`ssh-agent`, `gpg.format ssh`, `user.signingkey`, `credential.helper store`,
`~/.git-credentials`, `~/.netrc`, `_netrc`, historial del *shell*, tiempo de *build*, agente de
código en local.

**No aplica**: ver `macos-fleet-standards` (**frontera crítica sobre el mismo hardware**:
**la flota corporativa es suya** —inscripción automatizada y supervisión, MDM y gestión declarativa,
custodia de la clave de FileVault, TCC preconfigurado, política de actualización impuesta, catálogo
de software y cumplimiento CIS/mSCP—; **aquí el puesto de quien programa**, que se aprovisiona como
código, se endurece y se reconstruye. Son dos problemas distintos y el conflicto entre ambos es
real: **una política de flota bien hecha rompe herramientas de desarrollo si no se preconfiguran
los permisos**, y esa negociación se resuelve nombrando a las dos partes, no ignorando una), `linux-administration-standards` y `rhel-fedora-standards` (**el servidor y
la flota gestionada son suyos**: init, paquetes del sistema, parcheo masivo, gestión de
configuración de servidores; **aquí la máquina de trabajo de una persona**, que ni se gestiona
igual ni se apaga igual), `linux-hardening-standards` (**la línea base CIS de servidor y el
endurecimiento del sistema operativo son suyos**; **aquí el endurecimiento del puesto de
trabajo**: cifrado del portátil, bloqueo de pantalla, custodia de claves, código de terceros que
el editor ejecuta), `homelab-standards` (**el laboratorio personal es suyo**: cacharreo,
servicios domésticos, aprender rompiendo. **Aquí la herramienta con la que se cobra**; la
frontera es dura y va en las dos direcciones — §7 prohíbe usar el portátil de trabajo como
servidor del laboratorio), `secrets-management-standards` (**dueña de la elección de gestor de
secretos y de escáner de secretos**, de la política de rotación y del proceso ante una fuga.
**Aquí solo dónde NO pueden estar las credenciales en esta máquina** y que el escaneo ocurra
**antes** del *commit*), `identity-access-management-standards` (SSO, MFA corporativo, ciclo de
vida de la cuenta, acceso privilegiado; aquí su aterrizaje en el puesto),
`git-workflow-standards` (**la firma de *commits* como política del repositorio es suya**:
exigirla, verificarla, `CODEOWNERS`, ramas protegidas. **Aquí la custodia de la clave con la
que se firma** — que viva en hardware y no en `~/.ssh` en claro), `cicd-standards`
(**la paridad entre lo que corre en local y lo que corre en CI se define allí**; **aquí la
obligación de que la máquina local pueda reproducirla**: mismas versiones de runtime, mismos
formateadores, mismos *hooks*. Un *lint* que pasa en local y falla en CI es un fallo de esta
skill), `container-runtime-security-standards` y `podman-systemd-containers-standards` (el
runtime de contenedores y su endurecimiento; aquí solo su uso como entorno de desarrollo),
`endpoint-security-standards` (**el EDR de terceros y la postura del protector de cifrado en
flota** —qué producto, qué se le exige y cómo se mide la cobertura— **son suyos**; aquí el
cifrado y las claves de esta máquina como decisión de quien la usa),
`ai-agent-workflow-standards` (**recíproco ya declarado desde su lado**: **el proceso de trabajo
con agentes de código es suyo** — qué se le pide, cómo se revisa su salida, cómo se integra en
el flujo, la inyección indirecta de instrucciones, la rendición de cuentas del diff.
**Aquí solo el endurecimiento**: qué permisos, qué alcance del sistema de ficheros y qué
credenciales alcanza el agente desde esta máquina, §5.7), `claude-code-skills-standards` (la
autoría de skills), `bash-linux-scripting-standards` y `powershell-standards` (**la calidad del
script de *bootstrap*** — `set -euo pipefail`, `shellcheck`, idempotencia — es suya; aquí qué
tiene que hacer ese script), `iac-standards` (IaC de infraestructura real) y
`performance-engineering-standards` (**skill hermana de esta ola**: el rendimiento del
**producto**. **Aquí el rendimiento de la máquina**, que es tiempo del equipo, no latencia del
usuario — §6).

## 2. Decisiones por defecto

> Verificar la última versión y la licencia por web antes de fijarla (§8).

### 2.1 Aprovisionamiento

| Necesidad | Por defecto | Licencia / estado verificado | Cuándo se justifica otra cosa |
|---|---|---|---|
| Paquetes del sistema (macOS) | **Homebrew** con `Brewfile` versionado + `brew bundle` | BSD-2-Clause (`LICENSE.txt` en crudo) | MacPorts en entornos con requisitos de compilación propios |
| Paquetes del sistema (Windows) | **`winget`** con manifiesto exportado (`winget export`/`import`) | winget-cli: MIT (`LICENSE` en crudo) | Scoop o Chocolatey si ya hay inversión; **no mezclar tres gestores** |
| Paquetes del sistema (Linux) | El gestor de la distribución (`linux-administration-standards`) | — | Nix si se busca reproducibilidad real (abajo) |
| Reproducibilidad estricta | **Nix** (`flake.nix`, `home-manager`) o **`devenv`** | `devenv`: Apache-2.0 (`LICENSE` en crudo) | Solo si el equipo lo sostiene: la curva es real y el coste de mantenimiento también |
| Versiones de runtime por proyecto | **`mise`** (`mise.toml`, entiende `.tool-versions`) | MIT (`LICENSE` en crudo) — v2026.8.1 (ago-2026), cadencia de release muy alta | `asdf` si ya está desplegado; los nativos (`rustup`, `uv`, `nvm`) si el equipo es de un solo lenguaje |
| Variables de entorno por directorio | **`direnv`** (`.envrc`) | MIT (`LICENSE` en crudo) | `mise` cubre parte del caso y evita una herramienta |
| Entorno de desarrollo contenedorizado | **Dev Containers** (`.devcontainer/devcontainer.json`) | Spec: CC BY 4.0 (Microsoft). CLI de referencia `devcontainers/cli`: **MIT**, activa (ago-2026) | Adopción multi-proveedor real (VS Code, JetBrains, servicios en la nube), **con paridad de características desigual entre implementaciones** |
| *Dotfiles* | **`chezmoi`** (plantillas y secretos por máquina) o `stow` si no hay divergencia entre máquinas | Verificar licencia antes de fijar (§8) | `yadm` si el equipo ya lo usa |

**`mise` frente a `asdf`, estado verificado a ago-2026** — la comparación ha cambiado y las
guías viejas mienten:

- **`asdf` se reescribió en Go en la 0.16.0** (antes era Bash). Es un binario, es mucho más
  rápido que la versión Bash, y **eliminó comandos** de la era Bash (`asdf global`,
  `asdf local`, `asdf shell`). Versión verificada: **v0.20.0** (7-jul-2026). **Cualquier
  documentación o script interno que use `asdf global`/`asdf local` está roto**, y ese es el
  coste real de migrar, no el rendimiento.
- **El argumento de rendimiento se ha desinflado**: la documentación de `mise` reconoce que,
  frente a `asdf` en Go, la diferencia de velocidad es ya un motivo *menor*; los motivos que
  quedan son la seguridad de suministro, la ergonomía y no depender de *shims*.
- **`mise` está retirando los plugins de `asdf` por motivos de cadena de suministro**: su
  documentación indica que los plugins de `asdf` se consideran heredados y que **no se aceptan
  plugins nuevos de `asdf` ni de `vfox` en su registro**, dirigiendo a los *backends* `aqua`
  (preferido) o `github`. **Esto es un criterio de seguridad, no de gusto**: un plugin de
  `asdf` es un script de shell de un tercero que se ejecuta en cada cambio de directorio.
- **Regla dura**: **una sola herramienta de versiones por máquina.** `mise` y `asdf` inyectan
  *hooks* en el *shell* y **entran en conflicto** si están las dos.

**Criterio de elección, corto**: `mise` por defecto para un equipo políglota; los gestores
nativos si el equipo es de un lenguaje; Nix/`devenv` solo si alguien lo mantiene de verdad.

### 2.2 La escalera de reproducibilidad — subir solo hasta donde haga falta

| Nivel | Qué garantiza | Coste | Cuándo compensa |
|---|---|---|---|
| 0. Nada (README con pasos) | Nada | 0 | Nunca. Es el estado por defecto y es un fallo |
| 1. *Dotfiles* + manifiesto de paquetes + versiones de runtime por proyecto | Máquina reconstruible en horas; runtime idéntico entre personas | Bajo | **Suelo obligatorio de esta skill** |
| 2. Dev Container | Dependencias del sistema y del servicio iguales para todos, aisladas del anfitrión | Medio (E/S y arranque, sobre todo fuera de Linux) | Proyecto con dependencias del sistema, o equipo con sistemas operativos mezclados |
| 3. Nix / `devenv` | Reproducibilidad hasta el árbol de dependencias | Alto y **permanente** | Solo con dueño declarado. Sin él, cae en la primera semana de vacaciones |
| 4. Entorno remoto o efímero en la nube | Máquina desechable, datos que nunca tocan el portátil | **Coste directo por hora y dependencia de la red** | Abajo |

**Cuándo compensa el entorno remoto o efímero**, y cuándo no:
- **Sí**: cuando la compilación necesita más máquina de la que cabe en un portátil; cuando hay
  que aislar el código o los datos del dispositivo (contratistas, cumplimiento, datos
  regulados); cuando la incorporación de gente nueva es frecuente y el coste de montar una
  máquina domina; cuando el proyecto necesita una topología imposible en local.
- **No**: cuando el equipo trabaja con red mala o intermitente (una latencia de tecleo mala
  destruye más productividad de la que compensa cualquier CPU); cuando el trabajo es
  interactivo con GUI o dispositivos locales; cuando nadie ha calculado la factura.
- **Siempre**: **el coste es por hora y corre mientras nadie mira.** Apagado automático por
  inactividad **desde el primer día**, no como mejora posterior. Y **el entorno remoto no exime
  de endurecer el portátil**: sigue teniendo las credenciales que abren el entorno remoto.

### 2.3 Configuración del editor: en el repositorio, no en la máquina

- **`.editorconfig` en el repositorio, siempre.** Es lo único que entienden todos los editores.
- **La configuración del formateador y del linter va en el repositorio** (`.prettierrc`,
  `biome.json`, `ruff.toml` en `pyproject.toml`, `.clang-format`, `rustfmt.toml`, `.golangci.yml`),
  **con la versión de la herramienta fijada**. La herramienta concreta la elige la skill del
  lenguaje; **el criterio de aquí es dónde vive la configuración y que la versión esté fijada**.
- **Un formateador cuya versión no está fijada produce diffs distintos por persona** y convierte
  cada PR en ruido. Es el fallo de configuración compartida más común.
- **Nunca se depende de "formatear al guardar" del editor de cada uno** como garantía: la
  garantía es el *hook* de pre-commit y el gate de CI. La configuración del editor es
  comodidad; **el gate es el contrato** (`cicd-standards`).
- **`.vscode/extensions.json` recomienda; no instala en silencio.** Se revisa como código, con
  las mismas dudas que cualquier dependencia (§5.6).

## 3. Estructura: qué está versionado

```
dotfiles/                     # repositorio propio, público o privado según contenga
├── install.sh                # bootstrap idempotente, ejecutable N veces sin romper
├── Brewfile / winget.json    # manifiesto de paquetes por sistema
├── shell/                    # config de shell SIN secretos
├── git/                      # gitconfig con includeIf por contexto (personal/trabajo)
├── ssh/config                # config SÍ; claves privadas NUNCA
└── README.md                 # qué hace y qué NO hace

<proyecto>/
├── .editorconfig
├── mise.toml                 # versiones de runtime del proyecto
├── .envrc                    # variables NO secretas; referencias al gestor de secretos
├── .devcontainer/            # si aplica
├── .vscode/                  # settings y tasks compartidos, revisados en PR
└── .pre-commit-config.yaml   # o equivalente: formato, lint, escaneo de secretos
```

**Reglas duras**:
- **El repositorio de *dotfiles* no contiene secretos.** Ni claves privadas, ni tokens, ni
  ficheros `.env` reales, ni historiales. Referencias al gestor de secretos, sí.
- **El script de *bootstrap* es idempotente y no interactivo por defecto.** Un *bootstrap* que
  solo funciona la primera vez no sirve para el caso que importa: la reconstrucción con prisa.
- **La configuración de Git separa contextos** (`includeIf gitdir:`): identidad, correo y clave
  de firma personales y de trabajo **no se mezclan**. Firmar un *commit* de trabajo con la
  identidad personal es una fuga de datos personales, además de un lío.
- **`~/.ssh/config` versionado, claves privadas jamás.** Ni cifradas, ni "es privado el repo".

## 4. La prueba que valida todo esto: la reconstrucción

**Un aprovisionamiento que no se ha probado no existe.** Es el mismo criterio que un backup sin
restauración probada.

- **Ejercicio de reconstrucción periódico**: montar la máquina desde cero —o una VM limpia, o
  un contenedor— con el *bootstrap*, y **cronometrar**. El objetivo se fija por equipo (§8: esta
  skill no inventa un número), pero el **criterio es binario**: al final, ¿se puede clonar el
  repositorio principal, construir, pasar los tests y desplegar? Si falta un paso manual no
  documentado, **el fallo es del aprovisionamiento y se corrige ahí**, no en el wiki.
- **Cadencia mínima**: cada vez que entra alguien nuevo (su incorporación *es* la prueba, y su
  fricción es el resultado), y ante cualquier cambio mayor del sistema operativo.
- **Paridad con CI, comprobada**: las versiones de runtime que declara `mise.toml` /
  `.tool-versions` son **las mismas** que usa la *pipeline*. Se verifica automáticamente, no
  por costumbre. Un `lint` verde en local y rojo en CI significa que la paridad se rompió y es
  un fallo que se arregla, no una molestia que se tolera. La *pipeline* es de
  `cicd-standards`; **la obligación de reproducirla en local es de aquí**.
- **La máquina no es una mascota.** Si perderla duele por algo más que el tiempo de
  reconstrucción, hay estado no versionado que debería estarlo. **Ese estado se identifica y se
  saca de la máquina.**

## 5. Seguridad de la estación — la sección crítica

La estación es **el objetivo de mayor rentabilidad** de la cadena de suministro: tiene el código
antes de la revisión, las credenciales de producción y la confianza de todos los sistemas a los
que se conecta. Y la evidencia de 2025-2026 es que se ataca por ahí (§5.6).

### 5.1 Base no negociable

- **Cifrado de disco completo activado y verificado**: FileVault, BitLocker (con TPM y PIN o
  contraseña de arranque), LUKS. **Verificado**, no "activado durante el alta": se comprueba su
  estado. Un portátil sin cifrar es una filtración esperando a un taxi.
- **Custodia de la clave de recuperación** fuera de la propia máquina, en el gestor corporativo.
- **Bloqueo de pantalla automático** con temporizador corto y bloqueo al cerrar la tapa.
- **MFA resistente a *phishing*** (FIDO2/WebAuthn) en la cuenta corporativa, la del sistema
  operativo y las del control de versiones y la nube. **SMS y TOTP no son equivalentes**: el
  criterio y su despliegue son de `identity-access-management-standards`.
- **Actualizaciones del sistema y del navegador automáticas**, con ventana máxima acordada para
  los reinicios. **Prohibido posponer indefinidamente**: es la vulnerabilidad más barata de
  cerrar y la más aplazada.
- **Cuenta de uso sin privilegios administrativos permanentes**; elevación puntual.
- **Copia de seguridad cifrada de lo irremplazable** (`backup-recovery-standards`).

### 5.2 Claves SSH y de firma: en hardware

- **La clave privada no debe poder copiarse.** Con una clave en fichero, un solo malware —o una
  extensión de editor, §5.6— la exfiltra sin dejar rastro y sin que nadie se entere hasta que
  se usa.
- **Claves SSH respaldadas por FIDO2, estado verificado**: OpenSSH añadió el soporte en la
  **8.2 (14-feb-2020)** con los tipos de clave **`ecdsa-sk`** y **`ed25519-sk`**. Verbatim de
  las notas de esa versión: *"This release adds support for FIDO/U2F hardware authenticators to
  OpenSSH... In OpenSSH FIDO devices are supported by new public key types 'ecdsa-sk' and
  'ed25519-sk'"* y *"FIDO tokens also generally require the user explicitly authorise operations
  by touching or tapping them."* Opciones relevantes y **en qué versión aparecieron**:
  - `-O resident` — clave residente en el token, recuperable en una máquina nueva: **8.2**.
  - `-O verify-required` — exige **PIN** además del toque: **8.4** (`authorized_keys` admite
    `verify-required` desde la misma versión).
  - `no-touch-required` — **relaja** la exigencia de toque: **8.2**. **Se usa solo con motivo
    escrito**; el toque es precisamente la defensa contra el uso silencioso de la clave por
    malware con acceso al agente.
  - Referencia de versión actual verificada: **OpenSSH 10.4 / 10.4p1 (6-jul-2026)**.
  - **`ed25519-sk` no lo soportan todos los tokens**; `ecdsa-sk` es el respaldo más
    universal. Se comprueba **antes** de comprar el hardware, no después.
- **Dos tokens, siempre.** Uno principal y uno de respaldo registrado en los mismos servicios,
  guardado en otro sitio. **Un solo token es un punto único de fallo con forma de llavero**, y
  el día que se pierde no se entra a arreglar nada.
- **Firma de *commits* con clave en hardware**: Git admite firma con SSH desde **2.34** —
  verbatim de sus notas de versión: *"In addition to GnuPG, ssh public crypto can be used for
  object and push-cert signing. Note that this feature cannot be used with ssh-keygen from
  OpenSSH 8.7, whose support for it is broken. Avoid using it unless you update to OpenSSH
  8.8."* Configuración: `gpg.format = ssh` + `user.signingkey` apuntando a la **pública** del
  token. **La política de exigir firma es de `git-workflow-standards`; aquí solo que la clave
  esté en hardware.** Detalle operativo que hace fallar la verificación en GitHub: la clave debe
  añadirse **como clave de firma**, no (solo) como clave de autenticación — son dos entradas
  distintas aunque sea el mismo material.
- **Alternativa keyless para automatización**: `gitsign` (Sigstore) firma con identidad OIDC
  efímera y registro de transparencia. **No es sustituto** de la clave en hardware para el
  trabajo humano diario, y **GitHub no muestra sus firmas como "Verified"** igual que las SSH o
  GPG: es otra postura, verificable con su propia herramienta. Verificar estado (§8).
- **GPG**: si se usa, en tarjeta inteligente (OpenPGP card / YubiKey), nunca en fichero.
- **El agente**: `ssh-agent` con tiempo de vida acotado y **sin reenvío de agente** por defecto
  (`ForwardAgent`). Reenviar el agente a un host es dar a ese host el uso de tus claves mientras
  dure la sesión; si es imprescindible, `ProxyJump` en su lugar.

### 5.3 Credenciales: dónde NO pueden estar

**PROHIBIDO, sin excepciones y sin "es temporal":**

- ❌ **Token en `~/.netrc` o `_netrc`.** Texto plano, leído por multitud de herramientas, sin
  ámbito y sin caducidad.
- ❌ **`git config credential.helper store`.** Su propia documentación lo dice verbatim:
  *"Using this helper will store your passwords unencrypted on disk, protected only by
  filesystem permissions."* Alternativas que la propia documentación señala: `cache` (memoria,
  efímero) o un ayudante integrado con el almacén seguro del sistema operativo.
- ❌ **Secretos en ficheros de configuración del *shell* versionados** (`.zshrc`, `.bashrc`,
  `.profile`). Es la fuga clásica: el repositorio de *dotfiles* se hace público un martes.
- ❌ **Secretos en el historial del *shell*.** Un `export TOKEN=...` o un `curl -H "Authorization: ..."`
  queda en `~/.zsh_history` para siempre. Mitigación mínima: espacio inicial con
  `HIST_IGNORE_SPACE`/`HISTCONTROL=ignorespace`, y **leer el secreto de un fichero o del gestor,
  nunca escribirlo en la línea de órdenes**.
- ❌ **Secretos en variables de entorno globales y permanentes.** Cualquier proceso hijo los ve:
  el agente de código, el *linter*, el plugin del editor, el script de `postinstall` de una
  dependencia. **El ámbito se acota por proyecto y por sesión.**
- ❌ **`.env` real fuera del `.gitignore`**, o un `.env.example` que trae valores reales.

**Lo que sí**: el gestor de secretos y el escáner —incluida su elección— son de
`secrets-management-standards`. **El criterio propio de esta skill es de ubicación y de
momento**: credenciales en el llavero del sistema o en el gestor; **de vida corta y con ámbito
mínimo** (OIDC en vez de tokens estáticos siempre que exista); e **inyectadas al proceso que las
necesita, cuando las necesita**.

**Escaneo de secretos antes del *commit*, no después.** Un secreto que llega al historial de Git
**ya está comprometido**: reescribir la historia no lo desincrusta de los clones, los *forks*,
los *runners* de CI ni las cachés. La única respuesta correcta a un secreto ya empujado es
**rotarlo**. Por eso el *hook* local de pre-commit es obligatorio, **y el escaneo del lado del
servidor también** — el *hook* local se salta con `--no-verify` y **se saltará**. La herramienta
concreta la elige `secrets-management-standards`.

### 5.4 `curl | sh`: el mismo riesgo que se prohíbe en CI

**El argumento entero cabe en una frase**: *ejecutar un script remoto sin fijar versión ni
verificar procedencia es exactamente lo que `cicd-standards` prohíbe en la pipeline —y en la
estación hay más credenciales que en el runner*. Quien exige *pinning* por digest y verificación
de firma en CI y luego instala su herramental con `curl | sh` no tiene una política de cadena de
suministro: tiene una para las máquinas de otros.

Los modos de fallo, concretos:
- **El servidor sirve lo que quiere, a quien quiere.** El contenido de la URL no está fijado ni
  firmado, y puede cambiar entre dos ejecuciones sin que nadie lo note.
- **Detección de la tubería**: el servidor puede detectar que se está canalizando a `sh` —por la
  contrapresión de lectura del intérprete— y **servir un contenido distinto** del que se
  obtendría al descargarlo para leerlo. Es decir: **inspeccionar la URL en el navegador no
  demuestra nada.**
- **Ejecución parcial**: un corte de red a mitad deja el sistema en un estado indefinido, con
  medio script ejecutado.
- ⚠ **Un `sha256` publicado en el mismo origen que el script no aporta casi nada**: quien
  controla el origen controla los dos. Lo que aporta es una **firma** (Sigstore/cosign, GPG del
  proveedor) verificada contra una clave conocida por otra vía.

**Criterio, en orden de preferencia**:
1. **Paquete del gestor del sistema** (Homebrew, `winget`, la distribución, Nix). Es la opción
   por defecto y la que casi siempre existe.
2. **Artefacto versionado con firma verificada** (o, en su defecto, con *checksum* obtenido de
   un canal distinto), fijado a una **versión concreta**, nunca a `latest`/`master`.
3. **Script descargado a fichero, leído y fijado por versión**, ejecutado después. No es
   equivalente al punto 2, pero es honesto.
4. `curl | sh` a ciegas: **PROHIBIDO** (§7).

### 5.5 Ejecución automática de configuración de proyecto

**Clonar un repositorio no debería ejecutar nada. En la práctica, ejecuta bastante.**

- **`direnv`**: `.envrc` es **código de shell arbitrario** que se ejecuta al entrar en el
  directorio. Que exija `direnv allow` es la defensa, y **funciona solo si se lee el fichero
  antes de autorizarlo**. Autorizar por reflejo es peor que no tener `direnv`, porque además da
  sensación de control. **Se re-autoriza y se re-lee en cada cambio del fichero.**
- **`.vscode/tasks.json` y `settings.json` de un repositorio ajeno**: pueden apuntar a
  intérpretes, formateadores y binarios **dentro del propio repositorio**, que el editor
  ejecutará. Abrir un repositorio desconocido en el editor de trabajo es una decisión de
  seguridad. **Los modos de confianza del espacio de trabajo se usan; no se desactivan por
  molestos.**
- **Scripts de ciclo de vida de las dependencias** (`postinstall` de npm y equivalentes) se
  ejecutan al instalar. El endurecimiento del instalador es de la skill del lenguaje
  (`frontend-web-platform-standards`, `python-standards`…); **aquí la regla es que el primer
  `install` de un repositorio desconocido no se hace en la máquina de trabajo**, sino en un
  contenedor o una VM desechable.
- **Los *hooks* de Git del repositorio** no se ejecutan solos al clonar, pero cualquier
  herramienta que los instale sí los activa. Se revisan igual.
- **Regla que resuelve el 90 % de los casos**: **repositorio no confiable → contenedor
  desechable o Dev Container, nunca el anfitrión.** Y el contenedor **sin** montar `~/.ssh`, ni
  el llavero, ni el socket del agente.

### 5.6 Extensiones del editor y plugins del *shell*: código de terceros con tus permisos

**Una extensión de editor corre con los permisos del usuario, sin aislamiento significativo, con
acceso al código, a `~/.ssh`, a las variables de entorno y a la red, y con actualización
automática.** Es, en superficie de ataque, equivalente a instalar un binario de un desconocido y
darle permiso de auto-actualizarse. **Hay incidentes documentados y recientes** — esto no es
teoría:

- **GlassWorm** (documentado inicialmente por Koi Security en **oct-2025**, con oleadas
  posteriores): familia de malware **auto-propagante** en extensiones de editor, con presencia
  tanto en **Open VSX** como en el Marketplace de Visual Studio. Usa **caracteres Unicode
  invisibles** para ocultar el código malicioso a la vista en el editor. Roba credenciales de
  npm, GitHub, Open VSX y Git para **comprometer más paquetes** —cada víctima es un nuevo vector
  de infección—, drena carteras de criptomonedas y convierte la máquina en infraestructura de
  proxy. Verbatim de la cobertura de mar-2026: *"Socket said it discovered at least 72 additional
  malicious Open VSX extensions since January 31, 2026, targeting developers"*, y abusa de
  `extensionPack` / `extensionDependencies` para que un paquete de aspecto inocente **arrastre
  después** la extensión maliciosa, una vez ganada la confianza. Los señuelos imitan *linters*,
  formateadores y **asistentes de código con IA**.
- **GitHub, may-2026 — el caso que cierra el debate**: una versión comprometida de **Nx Console**
  (`nrwl.angular-console` v18.95.0), extensión con **más de 2 millones de instalaciones**, se
  publicó en el Marketplace con credenciales de publicación robadas. Una **única estación de
  trabajo** de un empleado de GitHub, con la actualización automática de extensiones activada,
  fue comprometida; a partir de los tokens, secretos y **claves SSH** recogidos de esa máquina,
  el atacante exfiltró **~3.800 repositorios internos** de GitHub. GitHub confirmó públicamente
  el acceso el **19-may-2026**. **La cadena entera —extensión → estación → repositorios
  internos— es exactamente el modelo de amenaza de esta sección.**
- Otros casos del periodo referidos por prensa especializada: extensiones con marca de IA y
  ~1,5 M de instalaciones acumuladas capturando ficheros y modificaciones de código
  (ene-2026), e infostealers publicados en el registro de Microsoft (dic-2025).

**Reglas duras, y son incómodas a propósito**:
- **Inventario de extensiones instaladas, revisado.** Lo que no se usa se desinstala: cada
  extensión es superficie permanente.
- **Se instala por necesidad concreta, no por descubrimiento.** Antes de instalar: quién la
  publica, cuánto tiempo lleva, qué permisos pide, y si hace algo que ya hace el editor.
- **La popularidad no es una garantía**: Nx Console tenía millones de instalaciones. **El número
  de descargas se puede inflar y la cuenta del editor legítimo se puede robar** — que es
  exactamente lo que pasó.
- ⚠ **La actualización automática de extensiones es el vector.** En el caso de GitHub, la
  máquina se comprometió porque la extensión **se actualizó sola** a la versión maliciosa
  durante una ventana de ~11 minutos. **Criterio**: en máquinas con acceso a producción o a
  código privado, **desactivar la auto-actualización de extensiones y actualizar por lotes tras
  una ventana de espera**. Cuesta comodidad; la alternativa cuesta 3.800 repositorios.
- **Lo mismo aplica a los plugins del *shell*** (`oh-my-zsh` y su ecosistema, gestores de
  plugins, temas): son **shell arbitrario que se ejecuta en cada sesión interactiva**, a menudo
  instalados con `curl | sh` (§5.4) y actualizados desde `main`. **Se fijan por versión o no se
  instalan.** Un tema de prompt bonito no justifica ejecución remota permanente.
- **La misma regla para los plugins del gestor de versiones** (§2.1): por eso `mise` ha dejado
  de aceptar plugins de `asdf` en su registro.
- **Ante sospecha de compromiso de una extensión, la respuesta es rotar**, no desinstalar: se
  asumen comprometidos todos los tokens, secretos y **claves SSH que estuvieran en disco**. Las
  claves que vivían en hardware (§5.2) son precisamente las que **no** hay que rotar. Ese es el
  argumento entero a favor del token, resumido.

### 5.7 Agentes de código en la estación

El **proceso** de trabajo con agentes es de `ai-agent-workflow-standards`, que **ya declara desde
su lado que el endurecimiento de la máquina es de aquí**. **Aquí solo el
endurecimiento**, y el marco es simple: **un agente de código es un proceso local que ejecuta
órdenes con los permisos del usuario y con una entrada controlada en parte por terceros** —el
contenido del repositorio, la salida de una herramienta, una página web, una respuesta de una
API. Se le aplica el modelo de amenaza de §5.6, no el de una herramienta de escritorio.

- **Alcance del sistema de ficheros acotado al proyecto.** Sin acceso al directorio personal
  completo, y **explícitamente sin** `~/.ssh`, el llavero, los ficheros de configuración de la
  nube (`~/.aws`, `~/.kube`, `~/.config/gcloud`) ni el repositorio de *dotfiles*.
- **Credenciales por ámbito y de vida corta**, inyectadas al proceso del agente y solo a él.
  **Nunca** las credenciales personales de larga vida ni las de producción.
- **Aprobación humana para acciones irreversibles**: escritura fuera del proyecto, `git push`,
  publicación de paquetes, cualquier orden contra infraestructura real, instalación de
  dependencias.
- **Sin credenciales de producción en la estación** (§7): la regla general de esta skill se
  vuelve crítica cuando hay un proceso autónomo ejecutando órdenes.
- **El trabajo de riesgo va en contenedor desechable**, no en el anfitrión — mismo criterio que
  §5.5 para repositorios no confiables.
- **La salida del agente se revisa como código de un tercero**, con la misma revisión que
  cualquier PR (`code-review-standards`). Aquí solo importa que **el agente no es una identidad
  con confianza propia**.

## 6. Rendimiento de la máquina: el argumento económico

**El tiempo de espera del desarrollador es coste de oportunidad, y es el argumento que gana
presupuestos** — pero solo si se mide en vez de sentirse.

**Método, y hay que hacerlo con datos propios**:
1. **Medir**, no estimar: tiempo de *build* incremental y limpio, tiempo de la suite de tests
   que se ejecuta antes de cada *commit*, tiempo de arranque del entorno, tiempo de indexado del
   editor.
2. **Multiplicar** por la frecuencia real diaria (cuántas veces al día se compila de verdad) y
   por el número de personas.
3. **Convertir** a horas al año y valorarlas con el coste interno del equipo.
4. **Comparar** con el precio del hardware. Si el cálculo sale a favor, no es una petición de
   comodidad: es una inversión con retorno calculado, y así se presenta.

**Esta skill no fija cifras de ahorro ni multiplicadores** (§8): circulan por la web sin fuente
primaria contrastable. **Los números se sacan de la propia máquina y del propio equipo.**

Restricciones concretas que suelen dominar:
- **La RAM es el techo duro.** Cuando el sistema empieza a intercambiar a disco, todo lo demás
  da igual. Un editor con indexado, un navegador, contenedores y un servicio local compiten por
  la misma memoria.
- **El disco**: SSD NVMe con **espacio libre suficiente**. Un disco casi lleno degrada el
  rendimiento y **hace fallar los builds** de forma que parece otro problema durante horas.
- **La CPU importa por núcleos en compilación** y por rendimiento monohilo en el resto; no es
  la misma decisión de compra.
- ⚠ **Los contenedores de desarrollo fuera de Linux pagan un impuesto de E/S** en los directorios
  montados desde el anfitrión. Es la causa habitual de que un Dev Container "vaya lento". Se mide
  antes de culpar a la herramienta; a veces la solución es un volumen nativo en vez de un *bind
  mount*, y a veces es no usar contenedor para ese proyecto.
- **El antivirus corporativo escaneando el directorio de *builds* puede duplicar el tiempo de
  compilación.** Es un caso real y frecuente. Se mide, y se negocia una exclusión **con
  seguridad**, con ámbito acotado y por escrito — **no se desactiva por cuenta propia** (§7).
- **Higiene de espacio**: cachés de dependencias, imágenes de contenedor y artefactos de build
  crecen sin límite. Limpieza programada, no cuando el disco se llena a las once de la noche.

## 7. Sostenibilidad y prohibiciones

- **La configuración de la estación se revisa como código**: los *dotfiles* del equipo, en un
  repositorio, con revisión. Un cambio en el *bootstrap* compartido es un cambio de
  infraestructura.
- **Cadencia**: revisar el inventario de extensiones y de plugins **cada trimestre** (§5.6);
  revisar versiones de runtime cuando cambie la *pipeline*; ejercicio de reconstrucción al menos
  con cada incorporación (§4).
- **Herramienta nueva = decisión con coste de mantenimiento.** Cada capa de aprovisionamiento
  (`mise` + `direnv` + Nix + Dev Container a la vez) es otra cosa que puede romperse y otra
  documentación que puede quedarse vieja. **Sube en la escalera de §2.2 solo con motivo.**
- **Baja del empleado**: procedimiento escrito para la retirada de la máquina — borrado seguro,
  revocación de claves (incluidas las de hardware registradas en los servicios) y rotación de lo
  que hubiera podido tocar. Es de `identity-access-management-standards`; **aquí la parte del
  dispositivo**.

Prohibiciones explícitas:

- ❌ **Instalar con `curl | sh` sin fijar versión ni verificar procedencia** (§5.4). **PROHIBIDO**
  hacerlo con privilegios de administrador (`curl ... | sudo sh`) en cualquier circunstancia.
- ❌ **Clave privada SSH o GPG en fichero** en una máquina con acceso a producción o a código
  privado, teniendo hardware disponible (§5.2).
- ❌ **Token en `~/.netrc`, en `credential.helper store`, en el `.zshrc`/`.bashrc` versionado o
  en el historial del *shell*** (§5.3).
- ❌ **Datos de producción en la máquina local.** Ni un volcado "para depurar", ni un CSV de
  clientes, ni una réplica de la base de datos con datos reales, ni logs con datos personales.
  Un portátil no tiene los controles de acceso, cifrado, registro ni retención que exige ese
  dato — y su pérdida es un incidente notificable
  (`privacy-engineering-standards`, `grc-compliance-standards`). Si hace falta depurar con datos
  reales, se depura **donde viven**, con acceso auditado. **Datos anonimizados o sintéticos para
  todo lo demás.**
- ❌ **Credenciales de producción de larga vida en la estación.** Acceso puntual, de vida corta y
  auditado.
- ❌ **El portátil de trabajo como servidor.** Nada que otros necesiten debe depender de una
  máquina que se cierra, se lleva en una mochila, se actualiza y pierde el wifi: ni un servicio
  compartido, ni un *runner* de CI, ni un túnel que otros usan, ni un cron que alguien espera.
  Un portátil no tiene disponibilidad, ni respaldo, ni ventana de mantenimiento, ni sucesor. Va
  a `homelab-standards` (si es personal) o a infraestructura de verdad (si es de trabajo). **Un
  servicio con un dueño que se va de vacaciones con él en la mochila no es un servicio.**
- ❌ **Desactivar el cifrado de disco, el bloqueo de pantalla, el antivirus corporativo o las
  actualizaciones automáticas** por comodidad o por rendimiento. Las exclusiones de rendimiento
  se negocian con seguridad, con ámbito acotado y por escrito (§6).
- ❌ **Instalar una extensión de editor sin revisar quién la publica**, o mantener la
  auto-actualización de extensiones en una máquina con acceso a producción o a código privado
  (§5.6).
- ❌ **`direnv allow` sin haber leído el `.envrc`** (§5.5).
- ❌ **Abrir un repositorio desconocido en el editor de trabajo** o ejecutar su `install` en el
  anfitrión: contenedor desechable (§5.5).
- ❌ **Reenvío del agente SSH (`ForwardAgent`) por defecto** (§5.2).
- ❌ **Dos gestores de versiones de runtime a la vez** (`mise` y `asdf`): sus *hooks* de shell
  entran en conflicto (§2.1).
- ❌ **Formateador o linter cuya versión no está fijada en el repositorio**, o que solo existe en
  la configuración del editor de una persona (§2.3).
- ❌ **Un paso manual no documentado en el aprovisionamiento.** Si hace falta preguntarle a
  alguien para montar la máquina, el aprovisionamiento está roto (§4).
- ❌ **Dar a un agente de código acceso al directorio personal completo, a `~/.ssh` o a las
  credenciales de la nube** (§5.7).
- ❌ **"Funciona en mi máquina" como conclusión.** Es el enunciado de un fallo de
  aprovisionamiento, y tiene dueño.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un equipo real:

1. **Gestores de versiones de runtime**: verificado a ago-2026 — **`mise` v2026.8.1**
   (cadencia de release muy alta: **cualquier versión que se escriba aquí caduca en días**) y
   **`asdf` v0.20.0** (7-jul-2026), ya reescrito en Go desde la **0.16.0**, que **eliminó
   `asdf global`, `asdf local` y `asdf shell`**. Confirmar el estado de la **retirada de los
   plugins de `asdf`** en el registro de `mise` (documentada como motivo de cadena de
   suministro) y si `asdf` ha implementado ya el bloqueo de versiones de plugin, que **no
   tenía**.
2. **Dev Containers**: verificado — especificación bajo **CC BY 4.0** (Microsoft), CLI de
   referencia `devcontainers/cli` bajo **MIT** y con actividad reciente (jul-2026). **Comprobar
   la paridad de características** de la implementación concreta que se vaya a usar (VS Code,
   JetBrains, servicio en la nube): **es desigual entre ellas** y es donde se pierde el tiempo.
3. **OpenSSH y claves FIDO2**: verificado en las notas oficiales — soporte FIDO/U2F desde
   **8.2 (14-feb-2020)** con `ecdsa-sk` y `ed25519-sk`; `-O resident` y `no-touch-required` en
   **8.2**; **`verify-required` (PIN) en 8.4**; versión actual verificada **10.4 / 10.4p1
   (6-jul-2026)**. Comprobar si el token concreto soporta `ed25519-sk` **antes de comprarlo**.
4. **Firma de *commits* con SSH**: verificado en las notas de **Git 2.34**, incluida la
   advertencia verbatim de que **no funciona con `ssh-keygen` de OpenSSH 8.7** y hay que estar
   en 8.8+. Git en la 2.55.0 a ago-2026. Confirmar en la documentación de la *forja* que la
   clave debe registrarse **como clave de firma**, no de autenticación, para que la verificación
   salga como válida.
5. ***Passkeys* y firma**: **hueco declarado**. No se ha encontrado a ago-2026 un mecanismo
   estándar de firma de *commits* con *passkeys* discoverable equivalente al de las claves
   `-sk`; lo verificado es que las claves SSH respaldadas por FIDO2 son el camino maduro.
   `gitsign` (Sigstore) es otra postura —identidad OIDC efímera con registro de transparencia—
   y **sus firmas no se muestran como "Verified"** en GitHub igual que las SSH/GPG. Verificar
   estado y versión antes de adoptarlo.
6. **Incidentes de extensiones — reconfirmar antes de citarlos**: los hechos de §5.6 proceden de
   prensa especializada e informes de proveedores de seguridad (Koi Security, Socket, Aikido) y
   **no de fuentes primarias leídas íntegras en esta verificación**, salvo la confirmación
   pública de GitHub del **19-may-2026**. Datos a reconfirmar: la cifra de **≥72 extensiones
   maliciosas en Open VSX desde el 31-ene-2026** (Socket, verbatim en la cobertura),
   los **~3.800 repositorios internos** de GitHub, la versión **`nrwl.angular-console` 18.95.0**
   y la ventana de exposición de **~11 minutos**. **Comprobar además si hay incidentes nuevos**:
   la cadencia de este vector en 2025-2026 hace previsible que los haya.
7. **Licencias verificadas en `LICENSE` en crudo a ago-2026**: Homebrew **BSD-2-Clause**,
   `winget-cli` **MIT**, `mise` **MIT**, `asdf` **MIT**, `direnv` **MIT**, `devenv`
   **Apache-2.0**, `devcontainers/cli` **MIT**. **`chezmoi` queda sin verificar en esta
   pasada**: leer su `LICENSE` en crudo antes de fijarlo (§2.1). Recordar que **el feed de
   releases de GitHub no es la fuente de verdad**: contrastar con la web oficial del proyecto,
   que en varios casos del catálogo publica en otro registro.
8. **`git credential-store`**: la advertencia citada es verbatim de su documentación oficial
   (*"store your passwords unencrypted on disk, protected only by filesystem permissions"*).
   Comprobar qué ayudante integrado con el almacén seguro del sistema operativo está disponible
   en la plataforma concreta.
9. **Hueco declarado — cifras de productividad**: este documento **no fija** ningún número de
   horas ahorradas, de retorno por gigabyte de RAM ni de coste del cambio de contexto. Circulan
   muchas y **no se ha encontrado fuente primaria contrastable**. El cálculo de §6 se hace con
   mediciones propias o no se hace.
10. **Hueco declarado — objetivo de tiempo de reconstrucción**: no se fija aquí un número
    ("máquina operativa en N horas"). Se acuerda por equipo a partir de la primera medición real
    (§4); el criterio que sí es de esta skill es **binario** (¿se puede construir, testear y
    desplegar al terminar?).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
