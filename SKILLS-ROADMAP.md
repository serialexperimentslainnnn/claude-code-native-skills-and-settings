# Catálogo de skills — estado y hoja de ruta

> Fichero de continuidad del proyecto de catálogo exhaustivo de skills IT.
> Última actualización: **2026-08-10**. Plan completo en `~/.claude/plans/validated-swimming-treehouse.md`.
> **CATÁLOGO COMPLETO: 218/218.** Ver "PUNTO DE CONTINUACIÓN — 2026-08-10" más abajo.

## Estado histórico: 82 de ~267 skills (2026-08-02)

**Ola 0 — agujeros del núcleo: COMPLETA (13/13).**
**Pasada de revisión de la Ola 0: COMPLETA** (ver "Pasada de revisión" abajo).
**Ola 1 — seguridad avanzada y operación: COMPLETA (12/12).**

Hechas en la Ola 1: `offensive-security` · `ctf-lab` · `linux-hardening` · `selinux` ·
`detection-engineering` · `secrets-management` · `incident-management` ·
`incident-response-forensics` · `container-runtime-security` · `windows-server-ad` ·
`privacy-engineering` · `bcdr`.

**Ola 2 — infra y plataforma: COMPLETA (14/14).**

Hechas: `linux-administration` · `rhel-fedora` · `zfs` · `linux-storage` · `dns` ·
`firewall-policy` · `proxmox-ve` · `libvirt-kvm` · `backup-recovery` · `object-storage` ·
`podman-systemd-containers` · `ha-clustering` · `vpn` · `network-troubleshooting`.

**Deuda de `onprem` cerrada** (era la Fase 0 del plan, completada del todo el 2026-08-02):
las 20 filas de su §1.2 están en estado *existe*, ya no queda criterio provisional en el cuerpo
(systemd, hardening, respaldo, HA y red delegan a su dueño) y la `description` soltó los triggers
que ahora tienen destinatario (systemd, KVM/libvirt, Proxmox, ZFS/RAID, HA cluster). Efecto
medido: `onprem` **desaparece del test de colisión** — antes compartía 6 términos con `proxmox-ve`.

**Ola 4 — datos: COMPLETA (16/16).**

Hechas: `data-engineering` · `data-warehouse-modeling` · `lakehouse` · `streaming-cdc` ·
`data-governance-quality` · `analytics-bi` · `nosql` · `graph-db` · `vector-db` ·
`timeseries-db` · `search-engines` · `message-brokers` · `oracle-dba` · `sqlserver-dba` ·
`mysql-mariadb-dba` · `caching-cdn`.

**Ola 5 — lenguajes modernos: EN CURSO** (~24-30 skills, por lotes de afinidad).

**Ola 5 — lenguajes modernos: COMPLETA (23/23).**

Hechas: `c` · `cpp` · `powershell` · `sql` · `haskell-fp` · `ocaml-fsharp` · `scala` · `clojure` ·
`ruby` · `elixir-erlang` · `zig` · `nim` · `crystal` · `r` · `julia` · `lua` · `perl` · `groovy` ·
`dart` · `webassembly` · `objective-c` · `assembly` · `solidity`.

**Test de colisión tras la ola (105 skills)**: la `STOP` original daba **140 pares**, casi todo
ruido del tokenizador — el gate era inservible. Ampliada con ~90 términos genéricos (verbos
auxiliares, `cost`/`data`/`time`/`whether`, y sustantivos de dominio compartidos por toda la
familia de datos). Resultado: **21 pares**, todos interpretables. Único solape **real y nuevo**:
`powershell` ↔ `windows-server-ad` compartía `jea, logging, powershell, script, signing`.
**Resuelto igual que la deuda de `onprem` tras la Ola 2**: `windows-server-ad` **cede los triggers
de PowerShell** (remoting 5.1 vs 7, JEA, *script block logging*) a su dueño, que ya existe; su §1
conserva la frontera escrita en las dos direcciones. Solapes restantes ya aceptados como
inherentes: las tres nubes, la familia de IA/seguridad por nombres de norma (`nist`, `owasp`,
`mitre`, `att`), y `oracle`↔`sqlserver` por vocabulario de motor propietario.

**Coste de índice**: 105 descripciones = **8.518 palabras** (~12k tokens por turno). Decisión del
usuario ya cerrada: se acepta, no volver a plantearla.

- **Flutter/Dart: el feed Atom de `dart-lang/sdk` está dominado por builds `-dev`** y no sirve para
  saber la estable; la fuente que zanja es `releases_linux.json` de Flutter (stable Flutter 3.44.8
  / Dart 3.12.2, 23-jul-2026). Quinto caso del patrón "el feed de GitHub no es la fuente".
- **`dart compile wasm` está "currently under development"** según la doc oficial, mientras
  `flutter build web --wasm` sí es camino soportado: **no son lo mismo**. Y **WasmGC no es
  universal**: Firefox lo anunció pero *"currently doesn't work"*, Safari con bug, **iOS no funciona
  en ningún navegador**.
- **El Component Model está en Phase 1** del proceso del CG de WebAssembly — no es un estándar
  consolidado, pese al discurso habitual. **Threads: Phase 4** (no entró en Wasm 3.0);
  *shared-everything threads*: Phase 1. Es donde más información falsa circula.
- **WASI 0.3.0 salió el 11-jun-2026** (release estable por voto del subgrupo), pero los toolchains
  de invitado seguían *in progress* y el target `wasm32-wasip3` de Rust es **Tier 3**. El target
  `wasm32-wasi` **ya no existe**.
- **Extism es BSD-3-Clause**, no MIT/Apache como se asume; **Wasmtime es Apache-2.0 WITH
  LLVM-exception**. Quinta y sexta licencia mal supuesta de la ola.

**Deuda cerrada el 2026-08-03 — cierre canónico de §8.** Un barrido mecánico sobre las 101 con
fichero detectó **13 skills preexistentes sin la frase de arbitraje** que la plantilla exige
(`Si la web contradice este documento, **manda la web** y señala la discrepancia.`): seis
terminaban en viñeta, sin cierre alguno (`python`, `typescript`, `dotnet`, `jvm-spring`,
`kubernetes`, `iac`), y siete tenían una redacción equivalente pero distinta. Todas normalizadas.
**Ahora el gate es mecánico**: `grep -L "manda la web" */SKILL.md` debe salir vacío. Sin esa frase,
una skill con un dato caducado gana la discusión contra la web, que es justo lo contrario de la
doctrina del catálogo.

**Criterio aplicado a las recíprocas** (para no inflar el catálogo): se escribe la línea recíproca
solo donde **dos skills compiten de verdad por el mismo artefacto**. Un cruce como
`r-standards` ↔ `rag-standards` no compite y **no** lleva línea; sí la llevan `mlops` (ciclo de vida
del modelo frente a lenguaje), `analytics-bi` (Shiny/Quarto frente a cuadro de mando),
`data-engineering` y `lakehouse` (Spark plataforma frente a código), `dotnet` ↔ `ocaml-fsharp`,
`jvm-spring` ↔ los tres JVM, `message-brokers` ↔ `elixir`, `iac` ↔ `ruby` (Chef/Puppet),
`ruby` ↔ `crystal`, `rust` ↔ los tres de nicho y `c`/`cpp` ↔ `zig`/`nim`.

**Fronteras recíprocas de los pares 1 y 2: cerradas por mí el 2026-08-03** (los agentes las
reportaron, no las escribieron — regla: un agente **no edita** skills que no son suyas).
Tocadas: `data-platform`, `mysql-mariadb-dba`, `oracle-dba`, `sqlserver-dba`,
`data-warehouse-modeling`, `data-engineering`, `lakehouse`, `appsec`, `rust`, `python`,
`gpu-computing`, `bash-linux-scripting`, `windows-server-ad`, `dotnet`, `offensive-security`,
`secrets-management`, `cicd`, `iac`.

### Hallazgos de la Ola 5 (verificados por web; re-verificar antes de usar)

- **C23 es el modo por defecto desde GCC 15** (antes `-std=c17`, de GCC 8 a 14). Clang lo acepta
  desde la 18 pero su soporte es **parcial papel a papel**: no hay paridad GCC/Clang.
- **MISRA vigente es MISRA C:2025**, y **desaplica la regla histórica de punto único de salida**.
- **Los perfiles de seguridad NO entraron en C++26**: `[[profiles::enforce]]` se aplazó a **C++29**.
  Sí entraron contratos, biblioteca estándar endurecida (P3471), reflexión y `std::execution`.
  **Safe C++ (P3390) no fue rechazado formalmente**: SG23 votó priorizar perfiles y su autor dejó
  de continuarlo en jun-2025. El matiz importa.
- **`import std` sigue experimental en CMake** y el GUID de `CMAKE_EXPERIMENTAL_CXX_IMPORT_STD`
  **cambia entre releases**; solo Ninja. "Los módulos ya están listos" es falso.
- **MSVC no tiene `/std:c++23` final**: `/std:c++23preview` o `/std:c++latest`.
- **ASan + TSan/MSan no es "desaconsejado": el compilador lo rechaza con error duro.**
- **CISA/FBI: la fecha del 1-ene-2026 de la hoja de ruta de memory safety es guía voluntaria**,
  con exención para productos cuyo soporte acaba antes del 1-ene-2030. No hay sanción.
- **PowerShell 7.6 es el LTS actual** (GA 18-mar-2026, EOS 14-nov-2028, sobre .NET 10);
  **7.4 y 7.5 mueren ambos el 10-nov-2026**. La página oficial se contradice: llama "Stable" a la
  7.5.9 y "LTS" a la 7.6.4, con el *stable* más viejo que el LTS.
- **Windows PowerShell 5.1 no está deprecado formalmente**; lo retirado fue **PowerShell 2.0**, de
  Windows Server 2025, con la actualización de sept-2025.
- **AppLocker no figura como deprecado**, pero Microsoft declara que **no cumple los criterios de
  servicing de característica de seguridad del MSRC**, mientras App Control sí.
- **Pester 6.0 salió GA el 07-jul-2026** y **v5 pasó a mantenimiento**: dos rupturas de sintaxis
  encadenadas (v4→v5 y v5→v6).
- **`MERGE` no existe en MySQL/MariaDB ni en SQLite.** La tabla *caniuse* de modern-sql.com induce
  al error: sus columnas son *última versión probada*, no *versión desde la que existe*.
- **`GROUP BY ALL` no está en PostgreSQL 18** (committed para 19). **`JSON_TABLE` es de PG 17**,
  no 15 (se revirtió en 15).
- **`sqlfmt` se instala como `shandy-sqlfmt`**; el `sqlfmt` de PyPI es un paquete ajeno al autor.

**Lección de método nueva (nº 10)**: una tabla comparativa de terceros puede tener una **semántica
de columna distinta de la que aparenta**. Contrastar siempre con la documentación del proveedor
antes de afirmar soporte de una característica.

- **Ruby 4.0 existe** (25-dic-2025; no hubo 3.5). Trae **ZJIT**, que las notas oficiales describen
  como **más lento que YJIT** y no recomendado en producción: YJIT sigue siendo la opción real.
  **Ruby 3.2 ya está EOL** (31-mar-2026). **Rails 7.2 muere el 09-ago-2026 y 8.0 el 07-nov-2026.**
- **Brakeman NO es MIT**: su `LICENSE.md` es la *Brakeman Public Use License* de **Synopsys**, con
  uso comercial de pago. Es el escáner por defecto de medio ecosistema Ruby y casi nadie lo sabe.
  **Sidekiq es LGPL-3.0.** → Lección: **leer el `LICENSE` en crudo incluso de lo "obviamente MIT"**.
- **Solid Queue/Cache/Cable, Propshaft y Kamal 2 son defaults de Rails 8.0, no de 8.1.**
- **RubyGems sufrió cuatro incidentes en 2026** (inundación masiva de may-2026 que forzó suspender
  registros nuevos; ataque a runners de CI; *dead drop* de jun-2026; "SleeperGem" en jul-2026).
- **Elixir 1.20 (jun-2026) tiene tipado gradual real**: el compilador infiere y comprueba tipos de
  todo el programa **sin anotaciones**, pero **no hay firmas de usuario ni API pública** todavía.
  Consecuencia: `--warnings-as-errors` pasa a ser un *type gate* de verdad.
- **Política de soporte de Elixir, verbatim**: *"Elixir applies bug fixes only to the latest minor
  branch. Security patches are available for the last 5 minor branches"*. **OTP 26 murió el
  26-may-2026.**
- **`:safe` en `binary_to_term` no cubre funciones** (verbatim de la doc): lo correcto es
  `Plug.Crypto.non_executable_binary_to_term/2`.
- **Interop Scala 2.13↔3 dejó de ser bidireccional en Scala 3.8**: el lector TASTy de 2.13 nunca
  podrá consumir artefactos de 3.8+. **3.9 será la nueva LTS** (RC a ago-2026), no 3.8.
  `-Xfatal-warnings` está **deprecado** desde 3.8: se usa `-Werror`.
- **Akka, verbatim del anuncio (07-sep-2022)**: *"The new license for Akka is the Business Source
  License (BSL) v1.1"* y *"After 3 years, the BSL license indefinitely reverts to an Apache 2.0
  license"*. **Apache Pekko es TLP de la ASF desde el 16-may-2024** y está vivo (1.6.0 + 2.0.0-Mx).
- **`core.async` ya no es el default de concurrencia en Clojure**: desde la línea 1.9 los bloques
  `go` se reimplementan sobre **hilos virtuales** con Java 21+. **`spec 2` sigue sin release** y
  Clojure 1.13 saca spec del artefacto core → **Malli** para código nuevo.
- **Leiningen no está abandonado: se mudó a Codeberg**; GitHub se autodescribe como *"temporary
  convenience mirror"* y la 2.13.0 **solo aparece allí**. Segundo caso de la ola.
- **GHC tiene LTS desde 9.14** (primera release LTS, jul-2025). **`GHC2021` sigue siendo el
  default**, no `GHC2024`. **`head`/`tail` no están deprecadas**: llevan `WARNING` de categoría
  `x-partial` desde base-4.19, y la CLC excluyó explícitamente deprecarlas → **el compilador no es
  el gate**; `init` y `last` ni siquiera están marcadas.
- **Los efectos de OCaml 5 siguen sin tipar**, verbatim del manual: *"effect handlers in OCaml do
  not provide effect safety; the compiler does not statically ensure that all the effects performed
  by the program are handled."*
- **Dos CVEs de OCaml que fijan mínimos**: over-read en `Marshal`/`intern.c` (fix en 5.4.1 y
  4.14.3) y **escape del sandbox de opam vía symlinks** (fix en **opam 2.5.2**). El aviso deja
  constancia de que `Marshal.from*` e `input_value` **siguen siendo inseguros** por diseño.
- **No existe `opam audit`** a ago-2026: está propuesto, no entregado.
- **`api.github.com` devuelve 403 sin autenticar**: los feeds `/releases.atom` son la vía fiable.

- **Zig se mudó de GitHub a Codeberg (nov-2025)** y su feed Atom de GitHub está **congelado en
  0.15.2**: la estable real es **0.16.0** según `ziglang.org`. **Tercer caso de la ola** tras
  Leiningen (Codeberg) y `styler` (publica en CRAN, no en GitHub Releases). El patrón ya no es
  anécdota: **el feed de GitHub miente por omisión con proyectos que se han mudado.**
- **Zig no detecta use-after-free en ningún modo de build**: lo detecta el *asignador*
  (`DebugAllocator`) y solo para su propio heap. `GeneralPurposeAllocator` se renombró a
  `DebugAllocator` en 0.14, y **0.16 reescribió toda la E/S alrededor de `std.Io`**.
- **Nim: `--threads` está activado por defecto desde 2.0** y `--mm:arc` **fuga memoria con el
  `async` de la stdlib** (crea ciclos) → con async, `orc` obligatorio. **`nimble.lock` no basta**
  para reproducibilidad: Nim añade todo `~/.nimble/pkgs2` al path de build.
- **Crystal 1.21 (jul-2026)**: los *execution contexts* ya vienen habilitados (fin de
  `-Dpreview_mt`), pero **el paralelismo por defecto es 1** y **las fibras ya no están ancladas a
  un hilo ni siquiera con paralelismo 1**. Windows sigue en **Tier 3** ("major limitations").
- **R no tiene LTS** y **R 4.6.0 rompió compatibilidad binaria** (API gráfica 16→17): los paquetes
  compilados ya instalados dejan de cargar. Al subir de minor hay que **reinstalar toda la
  librería compilada**.
- **`data.table` es MPL-2.0, no MIT.** Segunda licencia mal supuesta de la ola.
- **Modelo comercial de Posit**: el paquete `shiny` es MIT, pero **Shiny Server open source es
  AGPL-3.0**, **Shiny Server Pro se discontinuó el 31-mar-2026** y en Posit Connect **el acceso
  público anónimo a contenido interactivo es un *entitlement* de pago**. Decide el despliegue.
- **Julia: la LTS sigue siendo 1.10**, estable 1.12, **1.11 ya EOL** y 1.13 no era final a ago-2026.
  La caché de código nativo que arregló la latencia es **de la 1.9**, no reciente: casi todo lo que
  circula sobre "time to first plot" está caducado en un sentido o en el otro.
- **Ni R ni Julia tienen auditoría de dependencias equivalente a `pip-audit`**: `oysteR` existe pero
  su propio proyecto declara que **no está soportado por Sonatype**; Julia tiene
  `SecurityAdvisories.jl` (IDs `JLSEC`, formato OSV) y un Security WG, pero no un `Pkg.audit`.

- **Lua 5.5.0 existe** (22-dic-2025). **LuaJIT está vivo**: commits en `v2.1` en ago-2026, modelo
  de *rolling release* sin tags — el tag `v2.1.ROLLING` (2023) marca el **cambio de modelo**, no el
  código actual; **fijarlo por ese tag es el error clásico**.
- **StyLua y selene son MPL-2.0**, no MIT. **perltidy es GPL-2.0**, no "same terms as Perl".
  Tercera y cuarta licencia mal supuesta de la ola.
- **Perl 7 murió**: anunciado en jun-2020, tumbado por compatibilidad y proceso; derivó en
  `perlgov` y el Steering Council. `perlpolicy` a ago-2026 **ni lo menciona**. Estable: 5.44.0
  (15-jul-2026); `use feature 'class'` **sigue experimental**.
- **Para módulos de Perl la fuente de verdad es MetaCPAN, no GitHub Releases** (Perl::Critic:
  v1.154 en GitHub, **1.156** en CPAN). Cuarto caso del patrón de la ola.
- **Groovy está muy vivo**: 5.0.8 y 4.0.33 el mismo día (29-jul-2026) y **6.0.0-BETA-1** el
  01-ago-2026 — tres líneas en paralelo. La suposición de "proyecto ASF en mantenimiento" era falsa.
- **Gradle, verbatim de las notas de la 8.2**: *"Kotlin DSL is now the default option when
  generating a new project with the init task."* **El DSL Groovy no está deprecado.**
- **Precedente SLSA, ahora con datos**: may-2026, gusano sobre 42 paquetes `@tanstack` con
  atestaciones **SLSA Build L3 válidas**; jun-2026, oleada `@redhat-cloud-services`. Sostiene la
  regla de `cicd-standards`: **la procedencia firmada no basta; corta el pin por SHA/digest**.

- **Solidity ya no vive en `ethereum/solidity`**: el compilador se mantiene en
  **`argotorg/solidity`** (Argot Collective, escisión de la Ethereum Foundation, jun-2026).
  **Sexto caso** del patrón "repo movido ≠ abandonado" en una sola ola.
- **solc 0.8.36 eliminó el backend experimental de EOF** y EOF fue descartado de Fusaka: cualquier
  criterio que lo asuma está obsoleto. El **default de `evm_version` es `osaka`** desde 0.8.31.
- **EIP-7907 fue RETIRADO de Fusaka** (ACDE #216) — el límite de código sigue en los 24 KiB de
  EIP-170, pese a que varias listas de terceros aún lo incluyen. **Se lee el meta-EIP, no listas.**
- **Slither, Echidna, Medusa y halmos son AGPL-3.0**, no MIT. **El Certora Prover es GPL-3.0 y
  auto-hospedable desde feb-2025**: dejó de ser solo comercial. Séptima tanda de licencias mal
  supuestas.
- **Mythril lleva sin release desde marzo de 2024** → no puede ser un control de seguridad.
- **La causa dominante de pérdidas en cadena no es un bug de Solidity**: el **compromiso de clave
  privada explica más del 25 % de los robos y cuatro de los diez mayores**; el mayor incidente
  registrado fue de firma/UI. Reordena el énfasis: la custodia de claves pesa más que el lenguaje.

**Lección de método nº 12**: **la licencia se lee en crudo siempre**, incluso la de una herramienta
que "todo el mundo sabe" que es permisiva. Brakeman lo desmiente. Va ya en los prompts de la ola.

**Lección de método nº 13 — la regla que más veces salvó la ola**: **el feed de releases de GitHub
no es la fuente de verdad de un proyecto.** Seis casos confirmados en la Ola 5: Zig (se fue a
Codeberg), Leiningen (Codeberg), `styler` (publica en CRAN), los módulos de Perl (MetaCPAN),
Dart (su Atom está dominado por builds `-dev`) y **Solidity** (el compilador se mudó a
`argotorg/solidity`). Procedimiento obligatorio: **contrastar siempre con la web oficial del
proyecto** antes de fijar una versión o de declarar algo abandonado.

**Lección de método nº 11**: un repo de GitHub congelado **no implica proyecto abandonado** —
CMocka publica en `cmocka.org` con el espejo de GitHub parado en 2019, y las C++ Core Guidelines
no tienen releases desde 2017 porque son documento vivo. Medir salud por *releases* de GitHub
produce falsos abandonos.

## Lección de método nº 15 — el techo de concurrencia es de VERACIDAD, no de cobertura (2026-08-04)

Se creía que lanzar más de 3 agentes a la vez solo agotaba el presupuesto de WebSearch y degradaba
la **cobertura** de verificación, con el agente declarando huecos en §8 — un fallo seguro. **Es
falso.** Cuando WebSearch se agota, **el agente cae en WebFetch**, que es justo el componente
documentado como no fiable: inventa años y **ha llegado a invertir el sentido de un artículo
normativo** (el art. 31 de la European Accessibility Act). Es decir: **más concurrencia no produce
menos datos, produce más datos plausibles y falsos** — el fallo caro y el que no se ve.

**Matiz que salva la herramienta**: WebFetch **sí es fiable cuando no resume** — fichero en crudo
(`raw.githubusercontent.com`), feed Atom, o extracción **verbatim** de un fragmento citado
literalmente. Lo que falla es su resumidor.

**Regla operativa, obligatoria en todos los prompts de agente a partir de ahora:**
> Si te quedas sin presupuesto de WebSearch, **NO uses el resumen de WebFetch como fuente de un
> hecho**. O lo obtienes en crudo/verbatim, o **declaras el hueco en §8**. Un hueco declarado es
> barato; una fecha de fin de soporte equivocada hace que alguien planifique mal una migración.

**Concurrencia práctica: 4 agentes.** Por encima, la probabilidad de tocar el techo sube y con ella
la de que un dato entre por el resumidor sin que se note en el informe.

## Lección de método nº 14 — VALIDADA EN PRODUCCIÓN (2026-08-04)

**"Escribe cada fichero en cuanto esté listo" dejó de ser una recomendación y pasó a ser dato.**
La sesión se cortó **tres veces** durante la Ola 6. Resultado medido, sin ambigüedad:

- Los agentes que habían **guardado su primer fichero** lo conservaron íntegro las tres veces
  (`opensource-licensing`, `tech-leadership`, `software-architecture-patterns`, `green-it`).
- Los que **acumulaban para el final** perdieron el turno entero, incluidas todas sus búsquedas.

Corolario operativo: al reanudar con `SendMessage`, **decirle al agente qué hay en disco y qué
falta**, y **cambiarle la prioridad a "guarda primero, investiga después"**. Con eso, un agente
reanudado dos veces acabó entregando las dos skills. **Relanzarlo de cero habría tirado toda la
investigación web ya pagada.**

## PUNTO DE CONTINUACIÓN — actualizado 2026-08-10 (leer esto primero)

**Estado: 218 skills, 80.388 líneas — EL CATÁLOGO ESTÁ COMPLETO (218/218).** Los tres gates
mecánicos en verde (`./check.sh`, EXIT=0). Coste de índice: 25.383 palabras/turno. Nada quedó
a medias en disco. **Sin commitear**: ~130 ficheros modificados + 3 skills nuevas (el usuario
no ha pedido commit; identidad Lain + GPG YubiKey, verificar `git config user.email` antes).

### Hecho en la sesión del 2026-08-10

1. **Lote 28 ESCRITO — cierra la Ola 7 y el catálogo**: `chaos-engineering-standards` (161),
   `streaming-multimedia-standards` (180), `gaming-infrastructure-standards` (179). Un solo
   agente, verificación web completa. Hallazgos que invalidan criterio previo:
   - **Unity Multiplay deprecado el 1-abr-2026** (continuidad solo vía "Multiplay by Rocket
     Science"); **Agones en CNCF Sandbox** (aceptado 2025-12-21), v1.58.0, K8s 1.33-1.35;
     **Open Match parado de facto** (última release soporta K8s 1.24/1.25; `open-match2` con
     actividad baja); **GameLift cambió su modelo de coste en 2026** (ancho de banda gratis
     gen 6+, scale-to-zero) — toda comparativa anterior invalidada.
   - **Codecs**: Access Advance absorbió el pool HEVC/VVC de Via LA (dic-2025, "VCL Advance");
     los pools de **distribución** cobran ya al servicio de streaming; **Dolby demandó a Snap
     (mar-2026) por patentes de AV1** — "AV1 royalty-free" ya no es un hecho cerrado. AV2 spec
     final may-2026, sin parque.
   - **Netflix chaosmonkey sin push desde ene-2025** (SimianArmy archivado 2021) → vetado.
     **ffmpeg 9.0** (2026-08-04); MediaMTX v1.20.0 (MIT) con MoQ; **MoQ sigue en draft-17**.
   - Huecos §8: precios Gremlin/Wowza/Ant Media/Edgegap, tarifas por unidad de los pools de
     patentes, matriz `cbcs`/`cenc` por plataforma, CVE-2026-33186 de Litmus.
2. **Tercera pasada de marcas de ola: COMPLETA y mucho más ancha que lo previsto** — no eran
   3 ficheros sino **~200 sitios en ~90 ficheros**. Eliminadas TODAS las variantes:
   `(**Ola N, planificada/s**)`, `(**Ola N, escrita/s**)`, `(**Ola N, en curso**)`,
   `(**Ola N, hermana**)`, `(Ola N)` a secas, `(**existe, Ola N**)`, `(**ya escrita**)`,
   "puede estar escribiéndose ahora". Los bloques *"Planificadas — hasta que existan, esta
   skill es criterio provisional"* de `dns`, `firewall-policy`, `selinux`,
   `linux-administration`, `linux-hardening` y `rhel-fedora` reescritos a "Además:". El gate 3
   del meta-skill (`claude-code-skills-standards`) actualizado: ya no admite "planificadas",
   exige que **todas** las citadas existan. **Verificado: `grep 'Ola [0-9]' skills/*/SKILL.md`
   devuelve cero**; los ~22 restos de "planificad*" son prosa legítima (mantenimiento
   planificado, switchover, etc.), revisados línea a línea.
3. **Citas del lote 28 normalizadas**: `game-development:57` y `xr:76` ya apuntan a
   `gaming-infrastructure-standards` con nombre completo y sin marca.
4. **Fronteras recíprocas del lote 28 escritas por el orquestador** (los agentes solo
   reportan): `sre-practice`, `bcdr` y `testing-qa` → `chaos-engineering`; `caching-cdn` y
   `frontend-web-platform` → `streaming-multimedia`; `load-balancing` y `edge-computing` →
   `gaming-infrastructure`. **Decisión tomada**: `webgl-webgpu` → `streaming-multimedia` NO se
   escribe (no compiten por el mismo artefacto; el criterio anti-inflación manda).
5. De paso, limpiados restos históricos: `bcdr` ya no marca `windows-server-ad` como
   "en curso", `incident-*` sin bloques "Planificadas", `mcp`/`ai-agents` sin "existe, Ola 3".

6. **Test de colisión de disparadores: EJECUTADO Y CERRADO (2026-08-10).** La `STOP` original
   daba **420 pares** sobre 218 skills — el gate estaba inservible. Ampliada con ~220 términos
   genéricos (dos iteraciones: primero el vocabulario de las olas 5-7, después el ruido que
   quedaba) → **41 pares**. De ellos, **8 solapes reales**, corregidos **estrechando la
   `description` de la vecina, nunca el cuerpo** (el patrón de siempre, ahora con 8 casos más):
   - `onprem` → cede hardware físico, BMC/IPMI/iDRAC/iLO, warranty, y sala (UPS, cooling, rack)
     a `server-hardware` y `datacenter-facilities`. **Tercera poda de `onprem`**; su description
     queda como paraguas de enrutado, flota e invariantes. Bajó de 9 y 6 términos a ruido.
   - `dns` → cede SPF/DKIM/DMARC/MTA-STS/TLS-RPT a `email-security` (que ya era su dueña
     declarada desde `mail-servers`). Conserva zona, DNSSEC, TLSA/DANE, resolvers.
   - `datacenter-fabric` ↔ `high-speed-interconnect`: **reparto por capa**, no por tema. La
     configuración de Ethernet sin pérdidas en el switch (PFC/ETS/DCBX/ECN/DCQCN) es de la
     fabric; el transporte RDMA, su diagnóstico y el *deadlock* visto desde el interconector
     son suyos. `fabric` soltó `RDMA`, `interconnect` soltó `PFC deadlock` y `oversubscription`.
   - `abap-sap` ↔ `erp-sap`: la **conversión a S/4HANA como proyecto** (brownfield/greenfield/
     selective, licencias, mantenimiento) es de `erp-sap`; `abap-sap` se queda con **qué rompe
     esa conversión en el código custom**. `erp-sap` soltó `OData`, que es desarrollo.
   - `edge-computing` → cede RAUC/SWUpdate/Mender/hawkBit y la identidad por TPM/secure element
     a `embedded-iot`; conserva rpm-ostree/bootc/greenboot/balenaOS, que son Linux completo.
   - `os-provisioning` → cede `bootc-image-builder` y `rpm-ostree` a `rhel-fedora`; conserva la
     instalación a disco de un host *image mode*, Kickstart, PXE, Cobbler/Foreman/MAAS.
   - `game-development` → cede `matchmaking` a `gaming-infrastructure` (cesión ya pactada al
     escribir el lote 28); conserva el flujo de lobby y *party* en el cliente.
   Resultado: **35 pares, ninguno ≥8**, todos justificados como inherentes y **documentados en
   §4.3 del meta-skill**: tres nubes, familia de seguridad por nombre de norma, **familia de
   obligación legal europea** (`act`/`directive`/`omnibus`/`decreto`), cripto
   (`tls`/`1.3`/`ikev2`/RFC 9370), motores de juego, orquestadores de datos, y el homónimo
   `escrow` (BitLocker frente a FileVault). **La `STOP` ampliada está guardada dentro del
   script de §4.3**: el gate vuelve a ser reproducible y da 35 exactos al reejecutarlo.
7. **Grafo de delegación: LIMPIO (2026-08-10).** 4.741 aristas sobre 218 nodos. Corregido el
   único **destino muerto** (`claude-code-skills` citaba `technical-documentation-standards`,
   que no existe → `knowledge-management-standards`) y las dos **huérfanas** de dominio, que
   ahora tienen entrada por su frontera real: `gis-geoespacial` ← `data-platform` (PostGIS y el
   dato espacial frente al motor que lo hospeda) y `govtech-eidas` ← `cryptography-pki` (**una
   firma técnicamente válida no es una firma cualificada**: el régimen eIDAS es suyo, la cripto
   de debajo es de PKI). Queda una sola huérfana, `project-map`, y es correcto: es skill de
   procedimiento y se invoca desde el `CLAUDE.md`, no desde otra skill. De paso se cerró el
   último resto de marca obsoleta: la §1 de `data-platform` decía que los motores fuera de
   PostgreSQL/Redis/Kafka *"tendrán skill propia"* — ya existen las nueve y ahora las enruta.
   Los nodos más citados (`observability` 141, `vulnerability-management` 126, `cicd` 125) son
   destinos transversales legítimos, no monopolios de disparador.

8. **Repaso de composición: EJECUTADO (2026-08-10).** 4 agentes, 8 escenarios multidominio
   (K8s con datos personales y SLO; AS/400→SAP; clúster GPU multi-nodo; sede electrónica
   española; ransomware con AD comprometido; monolito .NET Framework→contenedores; juego
   multijugador con pagos y directo; fábrica OT con ML predictivo). Los agentes **no editan,
   reportan**; las correcciones las aplicó el orquestador. **Es la fase que más defectos ha
   encontrado de todo el proyecto, y ninguno lo veían los gates mecánicos.** Aplicado:

   **Falsedades de hecho (lo más grave, porque el agente las obedece):**
   - `gpu-computing` declaraba en §1 y §8 que **InfiniBand/RoCE "no tiene dueño en el catálogo"**
     y que había que improvisar — cuando `high-speed-interconnect-standards` existe desde la Ola 7
     y la citan `hpc`, `networking`, `datacenter-fabric` y `datacenter-facilities`. Era el único
     "sin dueño" falso de las 218. Corregido en los dos sitios.
   - `claude-code-skills` citaba `technical-documentation-standards`, que no existe.
   - `data-platform` decía que nueve motores *"tendrán skill propia"*; ya existen las nueve.

   **Contradicciones entre co-activadas** (una fija un default que la otra veta):
   - **`chaos-engineering` no excluía OT/ICS ni sistemas con función de seguridad.** Su §7 daba
     producción como "meta explícita" y ninguna de sus seis exclusiones era *"el fallo hiere
     personas"*. **Es el hallazgo más caro del repaso**: la skill nueva autorizaba inyectar
     fallos en una planta con SIS. Añadido límite duro (proceso físico, OT/ICS, SIS, dispositivo
     médico, automoción, ferroviario, aviación → banco o gemelo, nunca planta) y la frontera
     recíproca en `ot-ics-security`. Regla que lo resume: **el blast radius se mide en
     peticiones, no en personas**.
   - `chaos-engineering` ↔ `gaming-infrastructure`: PodChaos sobre una flota Agones mata pods
     `Allocated`, que es exactamente lo que la otra prohíbe. Acotado a `Ready` + ruta de
     reposición, escrito en ambos lados.
   - `finops` prohíbe que un presupuesto pare despliegues de producción; `platform-engineering`
     imponía cuota de coste en admisión, que es justo eso. Repartido: la cuota frena **recursos
     nuevos y efímeros**, nunca el rollout de un servicio ya en producción.
   - `observability` calculaba el *burn rate* sobre **30 días** y `sre-practice` fija **28
     rolling**: misma alerta, número distinto. Y `observability` ofrecía *"relajar el SLO"* como
     mitigación de poco tráfico, en un dominio que su propia §1 cede a SRE. Ambas corregidas.
   - `networking` listaba una zona "IoT-OT" entre sus zonas mínimas, con criterio de TI, mientras
     `ot-ics-security` exige zonas y conductos Purdue con SL. Corregido y enrutado.
   - `timeseries-db` autoriza bajar la resolución del histórico antes que comprar disco; eso
     **destruye el dataset de entrenamiento** que `mlops` exige poder reconstruir. Escrita la
     comprobación previa en ambos lados.
   - `data-governance` metía **secretos y dato personal en el mismo nivel** de clasificación,
     contra la frontera que declaran `privacy` y `secrets-management` (*un dato personal no es un
     secreto*). Los secretos salen de la escala: no se clasifican, se custodian.
   - `project-management` clasificaba *"una migración"* como indivisible, contra el default por
     olas de `migration-projects`. Lo indivisible es **el corte**, no el proyecto.
   - `testing-qa` prohíbe datos personales reales en pruebas *sin excepción*, y
     `migration-projects` exige ensayo con datos reales **enmascarados**. Escrita la excepción
     única del catálogo, con su condición.
   - `ibm-i-rpg` se contradecía en dos viñetas: cartera → `legacy-modernization` en una, "R" → EA
     en la otra. Fijados los tres niveles: **cartera = EA, sistema = `legacy-modernization`,
     plataforma = aquí**.

   **Huecos por delegación cruzada** (A cede a B, B cede a A, nadie decide):
   - **Retención de logs**: `privacy` la enviaba a `observability` y `observability` a `privacy`.
     Ahora hay números por defecto en `observability` (trazas 7 d, logs 30 d, métricas 13 meses)
     y el plazo normativo se delega en `grc-compliance`.
   - **Renegociar a la baja un SLO por coste**: `finops` exigía una firma que no podía obtener y
     `sre` solo contemplaba el caso contrario. Escrito el procedimiento en ambas: FinOps aporta
     el coste por nueve, **el objetivo lo cambia quien responde del SLO**, por ADR y comunicado.
   - **La ventana de retención del respaldo** la reclamaban `bcdr` y `backup-recovery` a la vez,
     y `privacy` enrutaba a la equivocada. Corregido el puntero de `privacy`.
   - **La tienda de un juego**: `gaming-infrastructure` la cedía *"si la reclama"* (única cesión
     condicional del catálogo) y `e-commerce` no la reclamaba → el PCI DSS nunca se activaba.
     Cesión ahora firme en ambos lados.
   - **Subtítulos y audiodescripción**: `accessibility` fija el requisito, `streaming-multimedia`
     no los mencionaba y no se citaban. Escrita la mecánica de entrega (WebVTT/TTML/IMSC,
     CEA-608/708, declaración en el manifiesto) con la regla que ambas sostienen: **una pista que
     el empaquetador no declara no existe para el usuario**.
   - **Grabación de sesión**: `privacy` mandaba el detalle a `observability`, que no lo cubre. Es
     analítica de producto, no telemetría de operación; corregido.

   **Punteros obsoletos y reciprocidades que faltaban**: `caching-cdn` enviaba proxy y *health
   checks* a `networking`, que ya se los había cedido a `load-balancing`; `ot-ics-security` no
   citaba a ninguna de las cuatro que le ceden (`embedded-iot`, `edge-computing`,
   `safety-critical`, `physical-security`); `observability` no citaba a `timeseries-db`,
   `finops` ni `platform-engineering`; `refactoring-tech-debt` no citaba a
   `legacy-modernization` ni a `migration-projects` pese a ser **la árbitro de la reescritura**
   invocada desde ellas; `routing-switching` no advertía que **la red de planta no es un campus**
   y sus defaults de acceso rompen un anillo PROFINET; `grc-compliance` no citaba a
   `govtech-eidas`; `vmware` y `hyper-v` no enrutaban el caso *"el hipervisor es la víctima"*.
   Todo escrito.

   **Duplicación de fuente**: los plazos de notificación (RGPD 72 h, NIS2 24/72/1 mes, DORA
   4/24/72/1 mes, ENS) están en **tres** skills con los mismos números. Hoy coinciden; la primera
   actualización parcial los rompe. Declarada **fuente única `grc-compliance-standards`** en las
   otras dos, sin borrar las tablas, y añadido a su `description` el disparador de notificación
   de brecha —que no tenía, así que no se activaba en un escenario de ransomware—.

9. **Los dos huecos aprobados por el usuario: ESCRITOS (2026-08-10).** Decisión suya en ambos
   casos: **sección dentro de la skill existente, no skill nueva** — el catálogo se queda en 218.
   - **`bcdr-standards` §3.6 — el entorno de recuperación aislado (IRE / *clean room*)**, que
     cuatro skills exigían y ninguna especificaba. Fija los **tres aislamientos** —red, identidad
     y **gestión**— con el aviso de cuál se hace mal: *"una red separada impecable administrada
     con el DA de siempre"*, y *"si el plano de gestión es el mismo, no hay aislamiento, por
     muchas VLAN que se dibujen"*. Más: de qué medio se restaura (inmutable/offline en solo
     lectura, binarios del fabricante, **nunca del share del entorno caído**), orden interno
     *identity-first*, seis afirmaciones exigibles para declararlo limpio con **tres firmas
     distintas** (seguridad, negocio, director de crisis), qué es preaprovisionable y qué no, y
     tres niveles de coste con el mínimo aceptable definido. Verificado contra Microsoft Learn
     (*AD Forest Recovery*, texto completo) y DORA art. **12(3)** —*"physically and logically
     segregated from the source ICT system"*, en fuente secundaria: declarado como pendiente de
     contraste con EUR-Lex—. **Hueco declarado que importa: no existe norma pública que
     especifique el IRE**; el término es de fabricante, así que se usa como criterio de
     ingeniería, no como requisito citable. La CISA #StopRansomware Guide dio **403 en cisa.gov y
     en los espejos**, así que no se cita ninguna de sus frases (séptimo caso del patrón de 403).
     Enrutado aplicado después en las tres vecinas: `backup-recovery` §3.7, `windows-server-ad`
     §3.9 —**alineando el término: un laboratorio protege al mundo de lo que corre dentro; un IRE
     protege a lo que corre dentro del mundo**— e `incident-response-forensics`, con la frontera
     en las dos direcciones: *aquella produce el punto limpio, el IRE lo consume*. De paso se
     corrigió una referencia rota que ya existía: `ai-governance` apuntaba a `bcdr` §3.7 para
     dependencia de proveedor, que está en §5.
   - **`kubernetes-standards` §3 — nodos y contenedores Windows** y **§6 — colas batch y gang
     scheduling**, con §7 y §8 ampliadas y triggers nuevos en la `description`. Todo verificado
     contra **fuente primaria en crudo** (`raw.githubusercontent.com` del repo de la doc,
     `api.github.com`, la API de manifiestos de MCR y los `LICENSE`), no contra el resumidor.
     Hallazgos que cambian criterio:
     - **Kubernetes no soporta el aislamiento Hyper-V**, así que el "escape de contenedor
       Windows" del que se habla no existe en clúster: el proceso comparte kernel con el host.
     - **Solo WS2022 y WS2025** son versiones de nodo soportadas, y la **matriz host↔imagen es
       dura**: la incompatibilidad se manifiesta como `0xc0370101`, no como un aviso.
     - **`servercore` no fija `USER`** → corre como `ContainerAdministrator`; `nanoserver` sí fija
       `ContainerUser` (medido en el *config blob* de MCR, no supuesto). Tamaños medidos:
       nanoserver 0,19 GB / servercore 2,3 GB / server 6,55 GB.
     - **Buena parte del `securityContext` de Linux se ignora en silencio** en Windows y el PSS
       `restricted` queda mutilado (seccomp, capabilities y privesc son *Linux only*): aplicar el
       invariante de Linux allí da una falsa sensación de endurecimiento. Es el fallo peligroso.
     - **WS2022 termina soporte mainstream el 14-oct-2026** y *"containers follow the same
       lifecycle dates"*; el parcheo es **rebuild mensual**, sin *servicing stack*.
     - **Kueue v0.19.0 sigue en `v1beta2`** (no hay v1 GA) y **Volcano es CNCF *Incubating***, no
       graduado. `ResourceQuota` **rechaza con 403, no encola**: por eso no sustituye a una cola.
     - Dos fallos del instrumental confirmados otra vez: **WebFetch inventó una URL**
       (`kueae.sigs.k8s.io`) y **el feed Atom de Volcano da un `updated` de v1.15.0 posterior al
       de v1.15.1**, que llevaría a concluir que la vieja es la nueva. Ambos evitados por crudo.
     Cerrados con esto **dos huecos declarados** que arrastraban `hpc-standards` §8 y
     `gpu-computing` §8 (*"estado, madurez y licencia de Volcano y Kueue: no verificados"*), y
     enrutados ambos a `kubernetes-standards` §6. Sigue abierto lo de Slinky/Slurm-en-K8s.
10. **Correcciones estructurales del repaso: APLICADAS (2026-08-10).**
    - **`edge-computing` renumerada a la convención**: usaba §4 y §5 para prohibiciones y
      verificación, y era **la única del catálogo que rompía el esquema** — con el agravante de
      que sus propias referencias internas ya apuntaban a §8, que no existía. Ahora §7 y §8, con
      la omisión de §4 y §6 declarada como pide la plantilla.
    - **La imagen A/B ya no la reclaman dos skills.** Corte espejado en ambos lados y por lo que
      hay debajo, no por dónde está la caja: **imagen de firmware** (MCUboot, RAUC, SWUpdate,
      Mender, hawkBit, ranuras con contador de rollback) → `embedded-iot`; **imagen de SO
      completo** (rpm-ostree, bootc, greenboot, balenaOS) → `edge-computing`. Y lo que no cambia
      de lado: **la campaña sobre la flota** —olas, *kill switch*, criterio de parada— es de
      `edge-computing` con cualquier mecanismo, porque es un problema de flota, no de placa.
    - **Una sola taxonomía de "R".** `enterprise-architecture` añade `rebuild` al final de su
      orden obligatorio y declara la equivalencia con `legacy-modernization` (*replace* = 
      `repurchase`); ésta declara que usa la misma lista. Y se resuelve el conflicto de fondo:
      **el orden de evaluación es de cartera, no de sistema** — la skill de la plataforma puede
      invertirlo *con justificación escrita*, y a veces debe (en IBM i, modernizar dentro suele
      ser mucho más barato que comprar, y casi nadie agota esa vía antes de migrar).
    - **"Congelación" tenía tres significados incompatibles** en `legacy-modernization`,
      `migration-projects` y `erp-sap`. Desambiguadas en los tres sitios: congelar *un sistema*
      (años, con contención) ≠ congelación *de cambios* alrededor de un corte (días, **con fecha
      de fin publicada**) ≠ congelación de transportes SAP (el caso anterior en un paisaje SAP).
      `erp-sap` no exigía fecha de fin, que es justo lo que `migration-projects` prohíbe.

11. **Los tres huecos de contenido del repaso: CERRADOS (2026-08-10).** Escritos por agente con
    verificación web; el enrutado recíproco lo aplicó después el orquestador.
    - **`ibm-i-rpg` §3.4 — dónde vive la lógica de negocio en IBM i y cómo se localiza.** Era el
      hueco más grave del escenario AS/400→SAP: `legacy-modernization` hace de la caracterización
      **el gate de todo el proyecto** y cedía la técnica a `refactoring-tech-debt`, que cede a la
      plataforma, que no lo cubría — cesión circular a un vacío. Ahora enumera los **ocho sitios**
      donde se esconde la regla (RPG fijo con ciclo e indicadores, CL, *triggers* y restricciones
      que se ejecutan sin que nadie los llame, validación declarada en DDS **que solo se aplica
      pasando por pantalla, no por ODBC/SQL/DFU**, la propia secuencia 5250 como control de
      proceso, puntos de salida, `*QRYDFN` de Query/400 y las hojas de cálculo colgadas por ODBC
      donde suele estar el cálculo real), con las herramientas y **sus puntos ciegos declarados**
      (llamadas dinámicas, SQL dinámico, `*LIBL`), el filtro regla-frente-a-fontanería y los
      entregables del gate.
    - **`ibm-i-rpg` §3.5 — Db2 for i como origen de migración/CDC.** Diarios y receptores como
      equivalente del binlog, con las trampas que rompen una carga **en silencio**:
      `MNGRCV(*SYSTEM)` borrando receptores no procesados, la **caché de diario (opción 42) que
      oculta entradas a `DSPJRN`/`RCVJRNE` y al diario remoto**, campos empaquetados con nibbles
      inválidos, fechas numéricas con ventana de siglo implícita, **ficheros multi-miembro de los
      que SQL lee solo el primero y parece correcto**, y CCSID 65535. Todo contra `ibm.com/docs`.
    - **`erp-sap` §3.8 — primera implantación desde un legacy no-SAP.** Toda la §3.1 asumía un ECC
      previo, así que el caso "llego a SAP desde un AS/400" no tenía criterio. Se numeró al final
      **para no romper ~15 referencias cruzadas internas**, con puntero desde §3.1. Fija: por qué
      sin sistema SAP de origen **no hay línea base** (ni Readiness Check ni USMM), *fit-to-standard*
      con la **carga de la prueba sobre la desviación**, big bang frente a fases con la prohibición
      de fasear por módulo dentro de la misma sociedad, **toda interfaz de convivencia nace con
      fecha de apagado y dueño**, nunca dos escritores del mismo objeto maestro, sizing por FUE sin
      histórico, y siete señales de **cuándo SAP no es la respuesta** con regla de parada. Cierra
      diciendo que **no hay tasa de fracaso citable**: son criterio, no estadística.
    Verificaciones que conviene retener: **sap.com respondió esta vez** y dio verbatim el
    *fit-to-standard* de Explore; **la responsabilidad de una *customer local version* es del
    cliente o su partner**, verbatim; y **SAP se contradice consigo mismo** sobre si el Cloud
    Localization Toolkit está en *early adopter* o GA. Nada de precios entró al documento: las
    cifras que aparecieron eran estimaciones de partner sin metodología.
    Enrutado recíproco aplicado: `streaming-cdc` ↔ `ibm-i-rpg` (**su catálogo de mecanismos no
    incluía Db2 for i**, y de ahí no debe inferirse que no tiene captura por log: la tiene, y es
    de las más antiguas), `legacy-modernization` → `ibm-i-rpg` §3.4, `erp-sap` ↔ `ibm-i-rpg`,
    `migration-projects` → `erp-sap` y `project-management` → `erp-sap` (**cuando el proyecto es
    implantar un paquete, tres de sus cinco variables dejan de ser negociables**). Corrección al
    informe del agente de SAP: afirmaba que `ibm-i-rpg` no citaba `migration-projects`, y sí lo
    hacía. El test de colisión subió a 37 por las descriptions ampliadas y volvió a **35** tras
    meter siete genéricos más en la `STOP`; el par `ibm-i-rpg` ↔ `mainframe-zos-cobol` (`db2`,
    `ebcdic`, `packed`) queda documentado como **inherente**: es vocabulario de fabricante, y las
    dos declaran expresamente que son plataformas distintas que la gente mete en el mismo saco.

### LO SIGUIENTE AL RETOMAR, en este orden

1. **Decidir sobre los huecos de cobertura que el repaso dejó sin dueño** — son decisión del
   usuario porque implican crecer el catálogo o declarar deuda: **trust & safety / moderación de
   contenido y DSA** (aparece solo en `gaming-infrastructure`, y `grc-compliance` no lo
   menciona), **mantenimiento predictivo como disciplina** (RUL, censura, coste asimétrico del
   falso negativo: cero coincidencias en 218 skills, y es el corazón del escenario de fábrica),
   **MES/ISA-95 nivel 3 y gemelo digital** (cero, y `ot-ics` usa el gemelo como default de
   pruebas), **modelo de tenencia de clúster para carga regulada** (`kubernetes` no contiene la
   palabra "tenant"), **SFU/WebRTC conversacional a escala**, y **TCO de capex on-prem**
   (`finops` es íntegramente de nube).
2. **Cuestión de diseño pendiente, también del usuario**: las 218 `description` están en inglés y
   enumeran artefactos; los enunciados reales en español y en lenguaje de negocio **no activan
   skills clave** (`observability` no salta con "SLO comprometido", `secrets-management` ni
   `identity-access-management` con "servicio nuevo con datos personales", `classical-ml` no
   salta con "mantenimiento predictivo" — cero coincidencias en el catálogo). Añadir una frase de
   escenario a esas descriptions choca con la regla *"disparadores por artefacto, cero
   conceptos"* del meta-skill: **hay que decidir si esa regla se matiza**, midiendo antes el
   coste de índice.
3. **`./install.sh`** — modelo *planchar* validado con `--dry-run` pero **NO ejecutado**:
   `~/.claude/skills` sigue siendo copia vieja y divergente. Tras ejecutarlo, la sesión
   siguiente ya carga las 218.
4. **Commit** cuando el usuario lo pida (no lo ha pedido).
5. Después: **pasada de sinergia `CLAUDE.md` ↔ catálogo** (BACKLOG punto 1, con su límite
   duro: las premisas personales NO se tocan).

## PUNTO DE CONTINUACIÓN ANTERIOR — 2026-08-05 (histórico)

**Estado: 215 skills, 79.848 líneas.** Los tres gates mecánicos en verde (`./check.sh`, EXIT=0).
Coste de índice: **25.150 palabras/turno**. Sesión cerrada por el usuario; nada quedó a medias en
disco (un agente murió antes de escribir su primer fichero, sin pérdida de trabajo escrito).

**Ola 7: 27 de 28 lotes COMPLETOS.** Escritos en esta sesión (83 skills): lotes 4, 5, 6, 10, 11, 12,
15, 17, 18, 21, 22, 23, 24, 25, 26, 27, el cierre de los parciales 9/16/20, y las dos pasadas de
reciprocidad.

### LO PRIMERO AL RETOMAR, en este orden

1. **Lote 28 — es lo único que falta para cerrar el catálogo.** `chaos-engineering-standards` +
   `streaming-multimedia-standards` + `gaming-infrastructure-standards`. **Los tres directorios NO
   existen: no hay nada que reaprovechar.** El encargo detallado (contenido, fronteras y avisos) está
   redactado y es recuperable del historial de la sesión; si no, re-derivarlo de la tabla del plan de
   lanzamiento. Dos skills ya lo citan y esperan de él: `game-development:58` y `xr-standards:76`
   reclaman `gaming-infrastructure-standards` con la frontera *"toda la infra de servidores de partida
   y matchmaking-como-servicio"*.
2. **Tercera pasada de marcas de ola obsoletas — deuda detectada y NO cerrada.** El mismo defecto que
   ya se corrigió dos veces, pero con **otra redacción que el `grep 'Ola 7, planificada'` no caza**:
   `linux-hardening` §1 tiene un bloque *"Planificadas — hasta que existan, esta skill es criterio
   provisional"* con **cinco skills que ya existen** (`container-runtime-security`,
   `detection-engineering`, `bcdr`, `linux-administration`, `rhel-fedora`); lo mismo en `ctf-lab`
   (4 skills, marcadas "Ola 1") y en `linux-administration` (bloque "Ola 2"). **Buscar por
   *"hasta que exista"*, *"criterio provisional"*, *"planificada"* y *"Ola N"*, no solo por la cadena
   larga.**
3. **Test de colisión de disparadores**: no se ejecuta desde las 132 skills y ahora hay 215. Script en
   `claude-code-skills-standards` §4.3; hay que **ampliar la `STOP`** con el vocabulario nuevo
   (verticales regulados, redes de operador, hardware). Sospechas concretas a arbitrar:
   `cloud-security-posture` ↔ las tres nubes, `physical-security` ↔ `datacenter-facilities` (CCTV y
   control de acceso los reclamaban ambas), `rpa-workflow-automation` ↔ `lowcode-governance`
   (Power Automate), `erp-sap` ↔ `abap-sap`, `blockchain-web3` ↔ `solidity`.
4. **Repaso final de composición** (ver BACKLOG punto 3): escenarios multidominio + grafo de
   delegación sin ciclos ni destinos muertos. Es el gate que cierra el catálogo.
5. **`./install.sh`** — reescrito esta sesión al modelo *planchar* (copia repo → `~/.claude`, no
   symlink), validado con `--dry-run` pero **NO ejecutado todavía**. `~/.claude/skills` sigue siendo
   una copia vieja y divergente. La memoria del proyecto **sí** quedó enlazada al repo.
6. **Commit**: hay ~101 ficheros sin commitear. El usuario no pidió commit; recordar la identidad
   (Lain + GPG de la YubiKey) y verificar `git config user.email` antes.

### Fronteras arbitradas a mano en esta sesión (no repetir el análisis)
- **`cryptography-pki` cedió la transición post-cuántica** a `post-quantum-crypto-standards`: sección
  reducida a puntero, `description` sin el trigger `post-quantum migration`, y frontera en §1. Se
  quedó la agilidad criptográfica y el CBOM, que son cripto aplicada y no transición.
- **`onprem` §1.2 ganó 10 filas** (facilities, server-hardware, os-provisioning, cmdb, hpc, edge,
  file-servers, web-app-servers, mail-servers) y su §1.1 dejó de reclamar hardware físico y BMC.
- **`gpu-computing` ↔ `datacenter-facilities`**: no se pudo ceder entero porque `gpu-computing` ya
  reclamaba densidad y refrigeración líquida en un arbitraje **explícito contra `green-it`**. Repartido
  por capa: la **sala** (densidad por rack, distribución eléctrica, CDU) a facilities; el **TDP y el
  requisito térmico del acelerador** se quedan en `gpu-computing` y se entregan como dato. Cederlo del
  todo obliga a tocar también la cláusula de `green-it`: **decisión pendiente, no es cirugía**.
- **`macos-fleet` ↔ `endpoint-security`**: `macos-fleet` ya reclamaba la custodia de la clave de
  FileVault vía MDM y `developer-workstation` se lo reconocía por escrito. Reparto final:
  `endpoint-security` **exige y mide** la postura; `macos-fleet` aplica el perfil MDM y custodia la
  clave.

### Hallazgo de método nº 16 — el resumidor de WebFetch FABRICA articulado normativo (2026-08-05)
Ya estaba documentado que inventa años y que invierte frases. **Esto es peor y es nuevo**: al pedir el
**art. 9 del RGPD** a EUR-Lex devolvió un texto inventado — **omitía "biometric data"**, insertaba
*"criminal convictions and offences"* (que es el **art. 10**) y atribuía a la letra (i) el contenido de
la (g). Solo salió correcto al **forzar reproducción carácter a carácter contra una página corta**.
Consecuencias operativas, ya incorporadas a los prompts y a la memoria del proyecto:
- Para articulado, **"pide verbatim" no basta**: hay que pedir la **página corta** (el artículo suelto,
  no el reglamento consolidado — **EUR-Lex trunca los documentos grandes**) y reproducción literal.
- **El 403 es la norma, no la excepción**, y no se combate insistiendo. Confirmados en esta sesión:
  `iso.org`, `etsi.org`, `cisa.gov`, `media.defense.gov`, `sap.com`, `bailii.org`,
  `health.ec.europa.eu`, `unrealengine.com` (+429 en la copia archivada), `salesforce.com/pricing`,
  `pcisecuritystandards.org` (PDF), `epsg.org`, `ibm.com/quantum`. Ante bloqueo: otra vía o **hueco
  declarado**.
- **Funcionó de sobra**: un agente escribió 4 skills con **cero WebSearch**, todo WebFetch en crudo.

### Cifras folclóricas desmentidas en esta sesión (con su origen)
No volver a citarlas; están desmentidas dentro de las skills correspondientes.
- **"100 ms de latencia = 1 % de ventas"**: blog de 2006 + diapositiva sobre un experimento **interno
  de Amazon nunca publicado**. Sin diseño, sin muestra, sin definir "ventas".
- **"La MFA bloquea el 99,9 %"**: dato **observacional** de 2019 con adopción del ~11 % (sesgo de
  denominador). El propio Microsoft publica hoy **">99,2 %"**.
- **"El 99 % de los fallos en la nube serán culpa del cliente"**: *predicción* de Gartner que en
  circulación pasó a hecho y cambió "responsabilidad compartida" por "error del usuario".
- **"55-75 % de proyectos ERP fracasan"**: los datos propios de la consultora citada dan **~22-26 %**,
  sobre muestra autoseleccionada entre candidatos a rescate.
- **"84 % de migraciones de datos fracasan"**: Bloor 2007, medía *overrun or aborted* — una semana de
  retraso y un proyecto abortado en el mismo cubo.
- **"70 % de carritos abandonados"**: media de 50 estudios de proveedor, rango 55-84 %, sin definición
  común.
- **Ahorro de SD-WAN frente a MPLS**: **no existe** estudio independiente con metodología transparente.
- **65.000 TPS de Solana**: su whitepaper dice **710k teóricos** en análisis sobre red de 1 Gbps.
- **Supremacía cuántica de Sycamore**: **refutada experimentalmente** (1.432 GPUs, 7× más rápido).

## PUNTO DE CONTINUACIÓN ANTERIOR — 2026-08-04 (histórico)

**Estado: 132 de ~267 skills. Olas 0-6 COMPLETAS. Solo queda la Ola 7.**
53.098 líneas. Los tres gates mecánicos en verde: `name` == directorio, `**No aplica**` presente,
y `grep -L "manda la web" */SKILL.md` vacío.

**Ola 6 — craft, frontend y gestión: COMPLETA (27/27).**
`frontend-web-platform` · `frontend-frameworks` · `accessibility` · `web-performance` ·
`design-systems` · `cms-jamstack` · `pwa` · `webgl-webgpu` · `testing-qa` · `code-review` ·
`software-architecture-patterns` · `refactoring-tech-debt` · `performance-engineering` ·
`developer-workstation` · `i18n` · `ai-agent-workflow` · `finops` · `platform-engineering` ·
`itsm-itil` · `project-management` · `opensource-licensing` · `green-it` · `tech-leadership` ·
`technical-hiring` · `enterprise-architecture` · `knowledge-management` · `product-discovery`.

**Test de colisión tras la Ola 6**: la `STOP` se amplió con ~60 términos de gestión
(`team`, `role`, `adoption`, `evidence`, `metric`, `framework`, `documentation`…). Resultado:
**62 pares**, casi todo ruido del tokenizador. **Dos solapes reales corregidos estrechando la
`description`, no el cuerpo**:
- `microservices-architecture` ↔ `software-architecture-patterns` (compartían `monolith`,
  `bounded`, `contexts`, `modular`, `event-driven`). **`microservices` cedió los triggers del
  diseño interno y de la decisión previa de distribuir**, y su descripción pasa a declarar que
  cubre *"sistemas ya repartidos por la red"*. Es el mismo patrón que `onprem` en la Ola 2 y
  `windows-server-ad` en la Ola 5: **cuando nace la skill dueña, la vecina suelta el trigger**.
- `ai-governance` ↔ `technical-hiring` (compartían `act`, `annex`, `omnibus`, `iii`,
  `transparency`). **`technical-hiring` cedió el encuadre normativo**; conserva el caso de uso
  (cribado automatizado, LL144, HB 3773, Colorado) y delega el AI Act a su dueña.

Solapes restantes **aceptados como inherentes**: las tres nubes; la familia de IA y seguridad por
nombres de norma (`nist`, `owasp`, `mitre`); `oracle`↔`sqlserver` por vocabulario de motor
propietario; `platform-engineering`↔`tech-leadership` por *Team Topologies* y DORA, que ambas citan
legítimamente desde ángulos distintos.

**Coste de índice: 132 descripciones = 12.313 palabras (~17k tokens por turno).** Decisión del
usuario cerrada: se acepta.

**Siguiente y última: Ola 7** (~120 skills, legacy y verticales, formato corto por lotes
temáticos). **No tiene plan de lanzamiento derivado**: hay que sacar los lotes de la taxonomía del
plan (`~/.claude/plans/validated-swimming-treehouse.md`, tabla de familias) antes de lanzar nada.
Familias implicadas: lenguajes y plataformas legacy (~20), desarrollo especializado (~12),
verticales y nichos (~20), y el resto de sistemas, redes, seguridad y datos que quedó fuera de las
olas anteriores.

**Deuda declarada y no cerrada** (arrastrada desde antes):
1. Hueco de la licencia de los **binarios** de Elasticsearch (§8 de `search-engines-standards`).
2. ~~InfiniBand/RoCE sin dueño~~ — **CERRADA el 2026-08-04** con `high-speed-interconnect-standards`
   (Ola 7, lote 14). Cubre InfiniBand, RoCE v2, iWARP, gestor de subred, el bloqueo mutuo por PFC
   desde la óptica del interconector, NVMe over Fabrics y **el criterio de cuándo NVMe/TCP basta y
   no hace falta RDMA**. `datacenter-fabric-standards` ya no la declara como hueco.
3. **La prueba funcional de activación nunca se ha hecho** — abrir un fichero real de cada dominio
   y comprobar que salta la skill correcta. Todo el trabajo de fronteras está validado
   *mecánicamente* pero jamás *funcionalmente*. Es la deuda más importante de las tres.

## BACKLOG — al cerrar el catálogo (decisión del usuario, 2026-08-05)

1. **Pasada de sinergia `CLAUDE.md` ↔ catálogo.** Cuando estén escritas todas las skills, hay que
   **reescribir el `CLAUDE.md` para que encaje con el catálogo, no para que lo repita**. Hoy el
   `CLAUDE.md` lleva doctrina extensa de dominios que **ya tienen skill dueña** (seguridad, redes,
   DevOps/SRE, DevSecOps, arquitectura, testing, agile): eso se escribió cuando no existía ninguna
   de las ~267. Criterio de la pasada, análogo al que ya se aplicó cinco veces dentro del catálogo
   (*cuando nace la skill dueña, la vecina suelta el trigger*): el `CLAUDE.md` **se queda con lo
   transversal e invariante** —cómo se trabaja, cómo se responde, qué se verifica, quién es el
   usuario, el norte de calidad y KISS— y **cede el criterio de dominio** a su skill, que se carga
   sola cuando la tarea la dispara. Ganancia doble: menos contexto fijo por turno y una sola fuente
   de verdad por tema. **Riesgo a vigilar: no dejar huérfano ningún criterio** — antes de borrar un
   bloque, comprobar que su skill dueña existe y lo cubre de verdad. Hacerlo **bloque a bloque, con
   el catálogo cerrado**, nunca a mitad de una ola.

   **LÍMITE DURO, fijado por el usuario el 2026-08-05: no se tocan las premisas personales.** Lo
   que se cede son los bloques de **criterio técnico de dominio** que ya tienen skill dueña. Lo que
   **no se toca jamás**: idioma, norte de calidad, KISS, estilo de respuesta, quién es el usuario y
   cómo interpretarlo, método de trabajo, disciplina a alta velocidad, rendimiento, e identidad y
   firma de commits. No son doctrina duplicable en una skill: son el contrato de trabajo, y ninguna
   skill de dominio los cubre. **Ante la duda sobre si un bloque es premisa o criterio de dominio,
   no se borra: se pregunta.** La cláusula está también al principio del propio `CLAUDE.md`, para
   que no dependa de que alguien lea este backlog.
2. **Skill `project-map`** (creada el 2026-08-05, fuera del patrón `-standards` porque es de
   procedimiento, no de dominio): genera y mantiene `PROJECTMAP.md` en cualquier repo. La directriz
   que obliga a crearlo y sostenerlo ya está en el `CLAUDE.md` (§ Método de trabajo). **Pendiente de
   validación en uso real**: comprobar en un repo ajeno que el mapa ahorra exploración de verdad y
   que la regla de mantenimiento "en el mismo turno" se sostiene sin recordatorio.

3. **Repaso final de composición: que se active el CONJUNTO correcto y que se pueda trabajar con
   él** (decisión del usuario, 2026-08-05). Es la fase que cierra el catálogo, y **corrige el
   criterio de la deuda nº3 de arriba**, que estaba mal formulado: decía *"que salte la skill
   correcta **y solo esa**"*. Para una tarea real eso es falso — un despliegue toca a la vez código,
   SRE, redes, seguridad, datos y coste, que es exactamente el principio de **cohesión entre roles**
   del `CLAUDE.md`. El objetivo no es que gane una skill: es que **se active el conjunto pertinente
   y que ese conjunto sea utilizable a la vez**.

   Cuatro defectos a cazar, ninguno detectable por los gates mecánicos actuales:
   - **Contradicción entre co-activadas**: dos skills que se cargan juntas y mandan cosas
     incompatibles (una fija un default que la otra veta). Hoy nada lo comprueba.
   - **Bucle de delegación**: `A` dice "esto es de `B`", `B` dice "esto es de `A`". La frontera
     existe en ambos lados y aun así nadie decide. Detectable en parte de forma mecánica siguiendo
     las líneas `**No aplica**` como grafo dirigido y buscando ciclos.
   - **Hueco por delegación cruzada**: `A` y `B` se lo ceden mutuamente a `C`, y `C` no lo cubre.
     El grafo también lo destapa: destino inexistente o sin la sección correspondiente.
   - **Monopolio de disparador**: una skill demasiado golosa que se activa siempre y desplaza a las
     que de verdad tocaban. El síntoma es que aparece en escenarios de dominios ajenos.

   Método propuesto (ejecutar con el catálogo cerrado, no antes): **escenarios de tarea realistas y
   multidominio**, no ficheros sueltos —"desplegar un servicio nuevo en Kubernetes con datos
   personales y presupuesto ajustado", "migrar un AS/400 a un ERP moderno", "montar un clúster de
   entrenamiento multi-nodo"—, y para cada uno anotar **qué conjunto debería activarse**, qué se
   activa de verdad, y **leer juntas las co-activadas buscando contradicción explícita**. Lo que
   falle se arregla como siempre: **estrechando la `description` de la vecina, no engordando el
   cuerpo**. Es el patrón que ya funcionó cinco veces (`onprem`, `windows-server-ad`,
   `microservices`, `technical-hiring`, `cryptography-pki`).

   Salida esperada: un gate nuevo en `claude-code-skills-standards` §4 —**grafo de delegación sin
   ciclos ni destinos muertos**— y la tabla de escenarios con su conjunto esperado, para poder
   reejecutar el repaso cuando el catálogo crezca. Sin esa tabla, el repaso no es repetible y habrá
   que re-derivarlo entero la próxima vez.

### Plan de lanzamiento de la Ola 7 (derivado el 2026-08-04; ejecutar sin re-derivarlo)

**~100 skills en 28 lotes temáticos**, formato corto (**80-180 líneas**; se omiten §4 y §6 cuando
resulten artificiales, declarándolo). 3-4 skills por agente porque comparten fuentes de
verificación. Escalonar de 3 en 3.

**Legacy de lenguajes y plataformas (6 lotes, 19 skills)**
| # | Lote | Nota |
|---|---|---|
| 1 | `mainframe-zos-cobol` + `ibm-i-rpg` + `mumps` | Mainframe y midrange; licencias y formación son el riesgo real |
| 2 | `vb6` + `vbnet` + `dotnet-framework-legacy` + `classic-asp` | Legacy Microsoft; frontera con `dotnet-standards` |
| 3 | `abap-sap` + `plsql-oracle-forms` + `coldfusion` + `jsp-struts` | Aplicación empresarial legacy; cruza con `oracle-dba` y `erp-sap` |
| 4 | `fortran` + `ada` + `pascal-delphi` | Científico y seguridad funcional; Ada cruza con `safety-critical` |
| 5 | `lisp` + `prolog` + `smalltalk` + `actionscript` | Simbólicos y muertos; el valor está en §7, cuándo NO |
| 6 | `legacy-modernization` | **Paraguas**: tabla de enrutado a las 18 anteriores, como `onprem` |

**Sistemas e infraestructura (6 lotes, 16 skills)**
| 7 | `aix-solaris-hpux` + `bsd-systems` + `macos-fleet` | Unix legacy y flota Apple |
| 8 | `vmware` + `hyper-v` + `xen` | Hipervisores; **VMware/Broadcom es dato de licencia crítico** |
| 9 | `web-app-servers` + `mail-servers` + `file-servers` | Servicios clásicos; correo es el más denso |
| 10 | `os-provisioning` + `cmdb-inventory` + `server-hardware` | PXE/Kickstart, NetBox, ciclo de vida del hierro |
| 11 | `datacenter-facilities` + `hpc` + `edge-computing` | Instalación física, Slurm, cómputo distribuido en el borde |
| 12 | `ceph` + `air-gapped` + `migration-projects` | Ceph cruza con `object-storage` y `proxmox-ve` |

**Redes (3 lotes, 9 skills)**
| 13 | `routing-switching` + `datacenter-fabric` + `network-automation` | VXLAN/EVPN; cruza con `networking` |
| 14 | `wireless` + `load-balancing` + `high-speed-interconnect` | **`high-speed-interconnect` cierra la deuda de InfiniBand/RoCE** |
| 15 | `network-vendors` + `telco-5g` + `wan-legacy` | Cisco/Juniper/Arista/MikroTik; MPLS y SD-WAN |

**Seguridad (3 lotes, 9 skills)**
| 16 | `soc-operations` + `threat-intelligence` + `email-security` | SOC cruza con `detection-engineering` e `incident-management` |
| 17 | `ot-ics-security` + `post-quantum-crypto` + `endpoint-security` | **PQC: verificar el estado real de la migración NIST** |
| 18 | `cloud-security-posture` + `identity-threat-detection` + `physical-security` | CSPM/CNAPP cruza con las tres nubes |

**IA y ML (2 lotes, 6 skills)**
| 19 | `classical-ml` + `deep-learning` + `model-finetuning` | Lo que NO es un LLM de terceros |
| 20 | `computer-vision` + `nlp` + `multimodal-genai` | `nlp` debe ceder casi todo a las skills de LLM |

**Desarrollo especializado (3 lotes, 10 skills)**
| 21 | `embedded-iot` + `kernel-drivers` + `operating-systems` | Cruzan con `c`, `cpp`, `rust`, `assembly` |
| 22 | `game-development` + `xr` + `robotics-ros` | Presupuesto de fotograma cruza con `webgl-webgpu` |
| 23 | `compilers-dsl` + `cross-platform-desktop` + `rpa-workflow-automation` + `home-automation` | |

**Verticales (5 lotes, 15 skills)**
| 24 | `erp-sap` + `crm-salesforce` + `lowcode-governance` | **Licencias y auditoría de licencia son el eje** |
| 25 | `e-commerce` + `fintech-payments` | PCI DSS, PSD2 y su sucesor: verificar estado |
| 26 | `healthtech-fhir` + `govtech-eidas` + `safety-critical` | Regulado: normas verbatim obligatorias |
| 27 | `blockchain-web3` + `quantum-computing` + `gis-geoespacial` | `blockchain-web3` cede EVM a `solidity` |
| 28 | `streaming-multimedia` + `gaming-infrastructure` + `chaos-engineering` | |

**Reglas específicas de esta ola** (además de las heredadas):
- **Formato corto de verdad.** El valor de una skill legacy está en §1 (cuándo se activa), §2
  (qué versión sigue soportada y qué no) y **§7 (cuándo NO usarlo y cuándo migrar)**. Todo lo demás
  es opcional.
- **El dato caro del legacy es el soporte y la licencia**, no la sintaxis: fechas de fin de soporte,
  coste de licencia por core o por usuario, y disponibilidad de gente que lo mantenga.
- **Honestidad sobre la muerte**: varias de estas tecnologías no se recomiendan para nada nuevo.
  Debe decirse en §1, no esconderse en §7.

## PUNTO DE CONTINUACIÓN ANTERIOR — sesión del 2026-08-03 (histórico)

**Estado al cerrar: 124 de 127 directorios con fichero.** Olas 0-5 completas; **Ola 6 en curso**.

**Hechas en la Ola 6 (22)**: `frontend-web-platform` · `frontend-frameworks` · `accessibility` ·
`web-performance` · `testing-qa` · `code-review` · `design-systems` · `cms-jamstack` ·
`performance-engineering` · `developer-workstation` · `i18n` · `ai-agent-workflow` · `finops` ·
`platform-engineering` · `itsm-itil` · `project-management` · `pwa` · `webgl-webgpu` ·
`opensource-licensing` · `software-architecture-patterns` · `refactoring-tech-debt` (los dos
últimos, **verificar que el fichero existe**: el agente seguía en vuelo al cerrar).

**Tareas exactas al retomar, en este orden:**

1. **Verificar los tres directorios que quedaron sin fichero** — `green-it-standards`,
   `tech-leadership-standards`, `technical-hiring-standards`. Sus agentes seguían en vuelo al
   cerrar la sesión. **Un directorio sin `SKILL.md` no es una skill a medias: es un directorio
   vacío que hay que rellenar o borrar.** Si faltan, relanzar con el mismo prompt (los tres
   encargos están descritos en el plan de lanzamiento de abajo, pares 11 y 12).
2. **Lanzar el par 13, que nunca se lanzó**: `enterprise-architecture` + `knowledge-management` +
   `product-discovery`. Es lo único que falta para cerrar la Ola 6 (27/27).
3. **Pasada de reciprocidad pendiente** de las skills cuyos informes se perdieron al cerrar:
   `opensource-licensing`, `software-architecture-patterns`, `refactoring-tech-debt`, `green-it`,
   `tech-leadership`, `technical-hiring`. Criterio de siempre: **solo donde dos skills compiten de
   verdad por el mismo artefacto**. Candidatas seguras: `vulnerability-management` y `cicd` hacia
   `opensource-licensing`; `microservices-architecture` hacia `software-architecture-patterns`;
   `testing-qa` y `code-review` hacia `refactoring-tech-debt`; `finops` hacia `green-it`.
4. **Reejecutar el test de colisión** (script en `claude-code-skills-standards` §4.3) y **ampliar
   la `STOP` con el vocabulario nuevo de gestión** — la Ola 6 mete muchos términos genéricos
   (`process`, `team`, `decision`, `policy`, `adoption`, `evidence`) que van a producir ruido.
   Sospechas concretas a arbitrar: `performance-engineering` ↔ `web-performance`,
   `itsm-itil` ↔ `incident-management`, `platform-engineering` ↔ `cicd`, `code-review` ↔
   `git-workflow` (ya arbitrada, comprobar que el solape bajó).
5. Después, **Ola 7** (~120, formato corto). **No tiene plan de lanzamiento derivado**: hay que
   sacar los lotes temáticos de la taxonomía del plan antes de lanzar nada.

**Deuda declarada y no cerrada**: el hueco de la licencia de los binarios de Elasticsearch (§8 de
`search-engines-standards`); InfiniBand/RoCE sigue sin dueño en el catálogo; y **nunca se ha hecho
la prueba funcional de activación** (abrir un fichero real de cada dominio y comprobar que salta la
skill correcta) — sigue pendiente desde la Ola 0.

### Plan de lanzamiento de la Ola 6 (derivado el 2026-08-03; ejecutar sin re-derivarlo)

**27 skills** = frontend y web (8) + craft de ingeniería (8, descontando `git-workflow` y
`api-design` que ya existen de la Ola 0) + gestión y proceso (11).

| # | Par | Nota de frontera |
|---|---|---|
| 1 | `frontend-web-platform` + `frontend-frameworks` | La más densa. Plataforma (navegador, HTML/CSS, red) frente a elección de framework |
| 2 | `accessibility` + `web-performance` | WCAG 2.2 y Core Web Vitals; ambas cruzan con `frontend-web-platform` |
| 3 | `design-systems` + `cms-jamstack` | Tokens y componentes; CMS headless y generación estática |
| 4 | `pwa` + `webgl-webgpu` | Service workers y offline; gráficos y cómputo en GPU del navegador |
| 5 | `testing-qa` + `code-review` | **Riesgo alto de colisión**: toda skill de lenguaje tiene §4 de testing. Deben quedarse la **estrategia** y ceder el *runner* concreto |
| 6 | `software-architecture-patterns` + `refactoring-tech-debt` | Frontera dura con `microservices-architecture` (topología) y con `enterprise-architecture` |
| 7 | `performance-engineering` + `developer-workstation` | **Colisión triple** a arbitrar: `web-performance` (navegador), `sre-practice` (SLO y producción) y esta (metodología de perfilado) |
| 8 | `i18n` + `ai-agent-workflow` | `ai-agent-workflow` cruza con `claude-code-skills` (autoría de skills) y `ai-agents` (construir sistemas agénticos): aquí **trabajar con agentes de código en equipo** |
| 9 | `finops` + `platform-engineering` | FinOps ya está repartido por las tres nubes: **se queda el método, cede el servicio** |
| 10 | `itsm-itil` + `project-management` | Cruzan con `incident-management` (incidente técnico) y `sre-practice` |
| 11 | `opensource-licensing` + `green-it` | Licencias: **la ola 5 dejó siete tandas de licencias mal supuestas**; esta skill es su dueña metodológica |
| 12 | `tech-leadership` + `technical-hiring` | Rol de liderazgo técnico; contratación y evaluación |
| 13 | `enterprise-architecture` + `knowledge-management` + `product-discovery` | Trío de gobierno y producto |

**Riesgo específico de esta ola**: es la más propensa a **prosa sin decisión**. Los dominios de
gestión y de craft tientan a escribir tutorial y opinión genérica. El prompt debe exigir
**decisiones falsables y prohibiciones concretas**, y las skills de gestión deben apoyarse en
**marcos y normas verificables** (ITIL 4, WCAG 2.2, SPDX, CSRD, ISO) en vez de en consejos.

### Plan de lanzamiento de la Ola 5 (ejecutado; se conserva como referencia de formato)

Emparejamientos por afinidad, 2 skills por agente, **escalonar de 3 en 3**:

| # | Par | Nota de frontera |
|---|---|---|
| 1 | `c` + `cpp` | La más densa. C++ moderno ≠ C con clases; memoria y UB son el eje |
| 2 | `powershell` + `sql` | PowerShell cruza con `windows-server-ad`; SQL cruza con **todas** las de datos: **cede modelado y tuning, se queda el lenguaje** |
| 3 | `ruby` + `elixir-erlang` | Rails frente a BEAM/OTP; `phoenix` y supervisión |
| 4 | `scala` + `clojure` | Ambas JVM: **frontera con `jvm-spring-standards`** (build, JDK, tooling) |
| 5 | `haskell-fp` + `ocaml-fsharp` | F# cruza con `dotnet-standards` |
| 6 | `zig` + `nim` + `crystal` | Trío de nicho: formato más corto |
| 7 | `lua` + `perl` + `groovy` | Lua embebido (nginx, Neovim, juegos); Perl legacy vivo; Groovy en Gradle/Jenkins |
| 8 | `r` + `julia` | Científicos: frontera con `mlops` y `data-engineering` |
| 9 | `dart` + `webassembly` | Dart cruza con `mobile-standards` (Flutter) |
| 10 | `objective-c` + `assembly` | Obj-C cruza con `mobile-standards`; ensamblador, formato corto |
| 11 | `solidity` | Va sola o con la vertical blockchain de la Ola 7 |

**Reglas heredadas obligatorias en todos los prompts** (ver "Método" y "Aviso metodológico"):
no delegar la investigación y esperar; escribir cada fichero en cuanto esté listo; versiones por
`api.github.com` o feeds Atom (nunca del resumidor de HTML); licencias verbatim del `LICENSE`;
citar los precedentes de cadena de suministro; y **declarar el hueco antes que inventar**.

**Ola 3 — IA: COMPLETA (10/10).**

Hechas: `llm-app-engineering` · `rag` · `ai-agents` · `mcp` · `local-inference` ·
`gpu-computing` · `llm-evaluation` · `mlsecops` · `mlops` · `ai-governance`.

**Frontera crítica de esta ola: la skill `claude-api`** (instalada, **fuera** del catálogo
`-standards`). Es la referencia canónica del lado Anthropic — IDs de modelo, precios,
`thinking`/`effort`, caché de prompt, tool use, MCP, Managed Agents, migración de modelo. Las
skills de la Ola 3 son **agnósticas de proveedor** y deben declararla en §1 sin repetirla ni
contradecirla. **Ningún dato de modelos Claude se escribe de memoria**: sale de esa skill.
Dato comprobado al invocarla: la línea actual es **Opus 5 / Sonnet 5 / Fable 5**, el *thinking*
es adaptativo y `budget_tokens` está **retirado** (400) — el conocimiento de memoria sobre
esto estaba desactualizado.

Hechas en la Ola 0: `claude-code-skills`, `sre-practice`, `appsec`, `vulnerability-management`,
`networking`, `observability`, `bash-linux-scripting`, `identity-access-management`,
`cryptography-pki`, `api-design`, `git-workflow`, `grc-compliance`, `homelab`.

**Siguiente paso: Ola 1** (12 skills), previa pasada de revisión de la Ola 0 (ver deuda técnica).

Preexistentes (17): `python`, `typescript`, `jvm-spring`, `dotnet`, `go`, `rust`, `php`,
`mobile`, `aws`, `azure`, `gcp`, `kubernetes`, `iac`, `cicd`, `onprem`,
`microservices-architecture`, `data-platform`.

## Olas pendientes

| Ola | Contenido | Skills |
|---|---|---|
| 2 | Infra y plataforma: `linux-administration`, `rhel-fedora`, `zfs`, `backup-recovery`, `proxmox-ve`, `libvirt-kvm`, `podman-systemd-containers`, `linux-storage`, `object-storage`, `ha-clustering`, `dns`, `firewall-policy`, `vpn`, `network-troubleshooting` | 14 |
| 3 | IA: `llm-app-engineering`, `rag`, `ai-agents`, `mcp`, `llm-evaluation`, `mlsecops`, `local-inference`, `gpu-computing`, `mlops`, `ai-governance` | 10 |
| 4 | Datos | 16 |
| 5 | Lenguajes modernos | 30 |
| 6 | Craft, frontend, gestión | 25 |
| 7 | Legacy y verticales (formato corto, por lotes temáticos) | ~120 |

Taxonomía detallada por familia: ver el plan.

## Método (no improvisar, está validado)

1. **Plantilla canónica**: `~/.claude/SKILL-TEMPLATE.md`. Fuera de `skills/` a propósito:
   cualquier directorio con `SKILL.md` se registra como skill activable.
2. **Subagentes en paralelo, 2 skills por agente.** Prompt debe incluir: rutas exactas,
   contenido a cubrir, **verificación web obligatoria** con los puntos calientes concretos,
   y las **fronteras** a declarar en §1.
3. **Regla de oro**: ningún dato de versión, EOL o nombre de feature se fija de memoria.
   Si el agente se queda sin presupuesto de búsqueda, **deja el hueco marcado en §8**, no
   rellena. Esto ya funcionó: varios agentes corrigieron errores míos (Spring Boot 3.x EOL,
   JUnit 6, bulo de "tokio 2.0", OAuth 2.1 sigue en draft).
4. **Escalonar lanzamientos**: 6 agentes a la vez agotaron el presupuesto de WebSearch
   (200/200) y mataron subagentes de investigación. Lanzar de 3 en 3.
5. Longitud por **densidad**, no por cuota. El cuerpo no cuesta índice.
6. **Prohibir al agente que delegue la investigación y espere**: si un subagente lanza a su
   vez agentes de búsqueda y se queda esperando, termina el turno sin escribir nada (pasó en
   la Ola 1 con `linux-hardening`+`selinux`; se recuperó con un mensaje de continuación).
   El prompt debe decir: busca tú, y si te quedas sin presupuesto, marca el hueco en §8.
7. **Verificar siempre que los ficheros existen** al recibir la notificación de fin: un
   agente puede reportar "completado" sin haber escrito.
8. **Exigir que escriba cada fichero en cuanto esté listo**, nunca los dos al final. En la
   Ola 2 se agotó el límite de sesión con tres agentes investigando y los tres murieron
   justo antes de escribir: se perdió la mitad del trabajo (`linux-storage`,
   `firewall-policy`). Los que ya habían escrito el primer fichero lo conservaron.
9. **Un agente cortado se recupera con `SendMessage`**, no relanzándolo: mantiene su
   transcripción y con ella toda la investigación web ya hecha. Dile qué hay en disco y qué
   falta, y que no repita búsquedas.

## Pasada de revisión de la Ola 0 (hecha 2026-08-02)

1. **Fronteras recíprocas**: las 17 originales ya declaran `**No aplica**` en §1. Criterio
   aplicado: la frontera se escribe por **qué decide cada skill**, no por tema (p. ej.
   nube = *qué* servicio, `iac` = *cómo* se escribe el código que lo crea; lenguaje =
   implementación, `api-design` = contrato). Las skills planificadas se citan marcadas
   con su ola: `X-standards` (**Ola N, planificada**).
2. **`onprem-standards` refactorizada a paraguas**: §1.1 qué decide, **§1.2 tabla de
   enrutado** a 20 skills profundas (existentes + Ola 1/2), §1.3 **invariantes** de
   plataforma. Las secciones cuyo contenido migrará llevan aviso de "criterio provisional
   hasta que exista X". La `description` cedió los triggers que ya tienen destinatario
   (CIS/hardening, backups, VLAN/firewall, Prometheus/Grafana) y **retiene** los que aún no
   lo tienen (systemd, KVM/libvirt, Proxmox, ZFS). → **Deuda: segunda poda de triggers de
   `onprem` cuando aterrice la Ola 2.**
3. **Test de colisión de triggers**: script mecánico incorporado como gate en
   `claude-code-skills-standards` §4.3. Resultado: único solape ≥4 términos = las tres
   nubes (`*.tf`, `terraform`, `iac`, `finops`), **inherente y aceptado** — se desambiguan
   por nombre de servicio y `provider aws|azurerm|google`. go↔rust solo comparten
   boilerplate. Catálogo sano.
4. **Revisión de seguridad del lote**: `/security-review` no aplica (no es repo git); hecha
   la revisión equivalente al criterio de §4.6/§5 del meta-skill. Escaneo mecánico de las 13
   (secretos, IPs/rutas internas, inyección de prompt, ejecución encubierta, comandos
   destructivos, payloads listos) + lectura íntegra de las 4 de mayor riesgo (`appsec`,
   `cryptography-pki`, `bash-linux-scripting`, `identity-access-management`). **Sin
   hallazgos**: todas las coincidencias son prohibiciones, en la dirección correcta.
5. **Corrección de contradicción interna**: el gate "descripción ≤40 palabras" de
   `claude-code-skills-standards` §4.2 contradecía su propia §3 ("sin límite duro; prohibido
   recortar por cuota destruyendo triggers") y la plantilla. Sustituido por el gate real
   (cero relleno) + el script de colisión.
6. **Referencias caducadas**: `grc-compliance-standards` ya no se cita como "aún
   inexistente" (`appsec`, `vulnerability-management`); `detection-engineering` pasa a
   citarse con su nombre `-standards` y marca de ola en `networking` y `observability`.

## Hallazgos de la Ola 1 que afectan a TODO el catálogo

Verificados por web durante la ola; corrigen datos que se habrían afirmado de memoria.
**Re-verificar antes de usarlos: caducan igual que el resto.**

- **`gitleaks` se declaró *feature complete*** (solo parches de seguridad) y su README apunta a
  **Betterleaks**; además `gitleaks-action` dejó MIT en v2.0.0 y **exige licencia comercial** para
  organizaciones, con la v2 dejando de funcionar el **16-sep-2026**. Era un default del catálogo
  tras la retirada de Trivy. **Resuelto**: las 8 skills que lo citaban delegan ahora la elección
  del escáner y su licencia en `secrets-management-standards`, que es su dueño. De paso se corrigió
  un resto de Trivy en la §4 de `kubernetes-standards` que contradecía su propia §2.
- **`SOPS` tiene una issue abierta de salud en la CNCF** (`cncf/toc#2098`) que evalúa relicenciarlo
  o archivarlo: no recomendarlo sin plan B.
- **ECS no fue donado a OCSF, sino a OpenTelemetry**, y la convergencia sigue incompleta: **no hay
  esquema de referencia único** hoy.
- **MITRE ATT&CK v19** partió `Defense Evasion` en `Stealth` + `Defense Impairment`, y **v18**
  sustituyó Data Sources por Detection Strategies/Analytics: todo mapeo anterior necesita migración.
- **YARA clásico está en modo mantenimiento** (sucesor: YARA-X); **Volatility 2, deprecada**.
- **NIST SP 800-61 va por Rev. 3** (abr-2025), reestructurada sobre CSF 2.0.
- **AI Act**: el *Digital Omnibus* movió el alto riesgo del Anexo III a **2-dic-2027**.
- **La transposición española de NIS2 seguía sin publicarse en BOE** en ago-2026.
- **NTLM está deprecado (jul-2024), no eliminado**; el default a *enforce* de `BlockNTLMv1SSO`
  llega en **oct-2026**.
- **Vault sigue en BUSL** tras la compra por IBM; **OpenBao está en Sandbox de la OpenSSF**.
- Cadena de suministro: además de Trivy/TeamPCP, **CanisterWorm generó atestaciones SLSA L3
  válidas para paquetes maliciosos** — procedencia válida ≠ seguro.

## Hallazgos de la Ola 3 (verificados por web; re-verificar antes de usar)

- **MCP: la revisión vigente es `2026-07-28` y el núcleo pasó a ser *stateless*** — desaparecen
  las sesiones de protocolo y `Mcp-Session-Id`, el handshake `initialize`, `ping`,
  `logging/setLevel` y la reanudación de stream. Aparecen `server/discover` (obligatorio),
  cabeceras `Mcp-Method`/`Mcp-Name`, `resultType`, `ttlMs`/`cacheScope`.
- **Sampling, roots y logging están deprecadas** (SEP-2577) y **elicitation ya no existe**:
  la sustituye el patrón **MRTR** (`resultType: "input_required"` + `inputRequests`).
- **El transporte es Streamable HTTP**; HTTP+SSE quedó formalmente *Deprecated*.
- **DCR (RFC 7591) deprecado** en MCP a favor de **Client ID Metadata Documents**; nuevo:
  validación obligatoria de `iss` (RFC 9207). El servidor MCP es **solo resource server**.
- **El registro oficial de MCP sigue en preview**, sin garantías de durabilidad de datos.
- **OWASP**: el **Top 10 for LLM Applications sigue en la edición 2025** (no hay 2026); la lista
  agéntica es **Top 10 for Agentic Applications 2026 (`ASI01`–`ASI10`)**, que **extiende**, no
  sustituye. **NIST AI RMF 1.0 en revisión**; el perfil GenAI **AI 600-1 sigue siendo el de 2024**.
- **AutoGen/AG2 en modo mantenimiento**; convergió con Semantic Kernel en **Microsoft Agent
  Framework 1.0** (abr-2026). LangChain/LangGraph **1.0 GA** desde oct-2025 (`langgraph.prebuilt`
  deprecado). **Pydantic AI serie 2.x**. **Haystack 3.0** y **Milvus 3.0** (jul-2026).
- **`LiteLLM` tuvo un backdoor en PyPI (marzo 2026)**: CI que ejecutaba **Trivy sin fijar versión**
  → `.pth` que se ejecuta en cada arranque de Python. Enlaza con el precedente de Trivy del
  catálogo y es el caso didáctico de cadena de suministro de IA.
- **CVE-2026-3172 en pgvector** (HNSW paralelo; corregido en 0.8.2).
- **Licencias que deciden un despliegue**: Weaviate core es **BSD-3** (no Apache); los pesos de
  **Jina reranker son CC-BY-NC** (no comercial); BGE y mixedbread, Apache-2.0.
- **RAGAS lleva ~7 meses sin release** (0.4.3, ene-2026). **MTEB contaminado** y su v2 no es
  comparable con v1: señal, no verdad.
- **La inyección de prompt sigue sin resolver** (confirmado, no suavizado), y *context rot* /
  *lost in the middle* son el límite real de las ventanas de 1M que sostiene el caso de RAG.
- **TGI (Hugging Face) está en mantenimiento**: última release dic-2025, último commit mar-2026.
  Vetado para proyecto nuevo.
- **CUDA 13.x exige driver ≥580** (12.x ≥525, 11.x ≥450); los **open kernel modules de NVIDIA son
  el default desde la serie 560**. **DRA es GA en Kubernetes 1.34 pero el driver de NVIDIA sigue
  en *technology preview*** — no es el default.
- **`--api-key` de vLLM protege solo `/v1`**: `/invocations` queda fuera y el plano distribuido es
  *insecure by default* (cita oficial). Corrige la creencia de "pon `--api-key` y ya".
- **`utilization.gpu` mide tiempo con algún kernel residente, no trabajo**: inútil como métrica de
  capacidad o de FinOps.
- **"Modelo grande cuantizado > pequeño en FP16" solo se sostiene hasta ~4 bits** y se invierte por
  debajo; la evidencia controlada es escasa. Queda como hipótesis de partida, no como conclusión.
- **CVEs verificados en NVD** para llama.cpp (GGUF), NVIDIA Container Toolkit (varios escapes de
  contenedor, el último CVE-2026-24260 en jul-2026), driver NVIDIA (CVE-2026-24187, con **R570 EOL
  sin parche**), vLLM y Ollama.

- **`Azure/PyRIT` está archivado** (mar-2026); el repo activo es **`microsoft/PyRIT`**. `openai/evals`
  está estancado (sin releases). **RAGAS** lleva ~7 meses sin release → referencia conceptual, no
  dependencia de CI.
- **MITRE ATLAS separó su versionado** en v2026.05: el contenido va por `YYYY.MM.N` y el **formato**
  por SemVer (v6.0.0, con campo `platforms` que incluye `Agentic AI`). El cambio **rompe el tooling**
  que consuma el `ATLAS.yaml` antiguo.
- **Los escáneres de pesos han sido evadidos** (0-days en picklescan, nullifAI, ShadowPickle: ~63 %
  de evasión sobre 10 escáneres) y **Hugging Face marca "unsafe" pero no bloquea**. `safetensors`
  frente a todo lo respaldado por pickle; `trust_remote_code=True` es RCE.
- **"SPDX es ISO" no prueba madurez del AIBOM**: ISO/IEC 5962:2021 codifica SPDX **2.2.1**, no la
  versión con perfil de IA. CycloneDX va por 1.7 (ECMA-424).
- **Extracción de modelo e inferencia de pertenencia no son la misma amenaza**: hay campañas reales
  de extracción divulgadas (feb-2026), mientras la inferencia de pertenencia **apenas supera el azar**
  en preentrenamiento de ~1 época. La **marca de agua es forense, no preventiva**.
- **Benchmarks**: 29 de 60 saturados; **SWE-bench Verified contaminado** (parches reproducidos
  literalmente). Para LLM-as-judge: **κ ≥ 0,6 y reportar siempre el acuerdo humano↔humano al lado**;
  el acuerdo bruto engaña con clases desbalanceadas.
- **Cadena completa del backdoor de LiteLLM**: Trivy Actions comprometido el 19-mar por **tags
  mutables** → token de PyPI → versiones 1.82.7/1.82.8 el 24-mar con un `.pth` ejecutado por
  `site.py` **antes de cualquier import**. **No afectó a quien fijaba dependencias.**
- **Fecha efectiva del art. 15 del AI Act: en disputa** (2026-08-02 original frente a posible
  desplazamiento por el *Digital Omnibus*). No comprometer fechas sin verificar.

## Hueco de cobertura detectado (candidato a skill futura)

**InfiniBand / RoCE no tiene dueño** en el catálogo: ni `networking-standards` ni
`gpu-computing-standards` lo cubren. Relevante en cuanto haya entrenamiento multi-nodo.

## Hallazgos de la Ola 2 (verificados por web; re-verificar antes de usar)

- **MinIO en modo mantenimiento**: AGPLv3, UI de administración retirada de Community (feb-2025),
  producto comercial AIStor, y **~9,5 meses sin release** (última `RELEASE.2025-10-15`).
  Descartado como default de object storage auto-alojado. Ninguna otra skill lo citaba.
- **Garage no implementa versionado de bucket** (`GetBucketVersioning` es stub) → **no hay Object
  Lock**. No sirve como repositorio inmutable de backups, que es justo para lo que se elige.
- **SeaweedFS**: issue abierto de que su modo *compliance* **no impide el borrado** → de ahí el
  gate "prueba de inmutabilidad ejecutada", no "configurada".
- **PBS con backend S3 (soportado desde 4.2) no soporta Object Lock ni versionado**, y activarlo
  en el bucket puede dañar el datastore. Contradice la intuición de "S3 = copia inmutable".
  **Fuente de terceros: pendiente de confirmar contra documentación oficial.**
- **BorgBackup 2.0 sigue en beta** (2.0.0b22); el estable es 1.4.x. Vetado en producción.
- **Bareos**: el código es AGPLv3 pero **los binarios del repo de release exigen suscripción**.
- **`goofys` está abandonado** (última release abr-2020): vetado.
- **Velero migró de repo** a `velero-io/velero`.
- **S3 aplica CRC-64/NVME por defecto** (no CRC32), y las partes multipart incompletas **se
  facturan y no aparecen en `aws s3 ls`**.
- **XFS sigue sin poder reducirse** y no está en el roadmap upstream.
- **El bitmap de mdadm no cierra el write hole** (eso es PPL, solo RAID5, −30/40 % escritura).
- **`iptables-nft` no ha sido eliminado**, solo deprecado; **`ufw` no tiene backend nftables**.
- **Docker**: el bypass del filtro de entrada para puertos publicados **sigue vivo** en Engine 28,
  y el backend nftables experimental de Engine 29 **no crea `DOCKER-USER`**, invalidando la
  mitigación estándar.
- **DMARCbis es RFC 9989** (may-2026, obsoleta la 7489). **DANE**: ~30 dominios con TLSA sobre
  5,5 M escaneados, frente a ~16.000 con MTA-STS.
- **CVE-2026-53359 "Januscape"** (shadow MMU x86, Intel y AMD): **parchearlo solo no basta**,
  requiere también CVE-2026-46113.
- **Veeam CVE-2026-44963** (CVSS v4 9.4): RCE por cualquier usuario de dominio autenticado, solo
  en instalaciones unidas al dominio. Sostiene la regla de sacar el respaldo del dominio.

## Hallazgos de la Ola 4 (verificados por web; re-verificar antes de usar)

- **Prefect adquirió Dagster: anunciado el 13-jul-2026** (marca combinada desde ago-2026; Dagster
  conserva nombre, precio y hoja de ruta). **Corrección de un error propagado dentro de este
  proyecto**: un agente de la Ola 3 lo fechó en marzo-2026 —probablemente por el *timestamp*
  erróneo de The New Stack— y yo lo repetí en el brief de la Ola 4. Corregido en `mlops-standards`.
  **Lección: un dato no verificado se propaga entre olas a través de mis propios prompts.**
- **dbt**: fusión con Fivetran completada el 1-jun-2026. dbt Core sigue **Apache 2.0**; el binario
  **Fusion es propietario** (dbt Product Licensing Agreement, ya no ELv2) y dbt Core v2 está en alpha.
- **SQLMesh fue donado a la Linux Foundation** (mar-2026) por Fivetran, que había adquirido Tobiko
  Data en sep-2025: mismo dueño que dbt, pero **mejor gobernanza**.
- **Airflow 2 llegó a EOL el 22-abr-2026**; la línea viva es 3.3.x.
- **Airbyte es ELv2 (*source-available*), no open source OSI.**
- **`elementary-data` 0.23.3 comprometida (24-abr-2026)**: infostealer inyectado vía GitHub Actions
  desde un comentario de PR, con *payload* en un `.pth` que se ejecuta al arrancar el intérprete;
  robaba perfiles de dbt y credenciales de Snowflake/BigQuery/Redshift/AWS/GCP/Azure. Corregido en
  0.23.4. **Mismo patrón `.pth` que el backdoor de LiteLLM**: es la técnica de persistencia de moda
  en la cadena de suministro de Python.
- **MetricFlow se relicenció a Apache 2.0** (oct-2025) y **OSI fue donado a la ASF**: hoy es
  **Apache Ossie (incubating)**.
- **No hay 4.ª edición de Kimball**: sigue la 3.ª de 2013 (Kimball Group cerró en 2016).
- **Parquet sigue sin sucesor productivo**: Vortex incuba en LF AI & Data; Lance y Nimble son piloto.
- **Licencias de motores NoSQL/grafo — el dato que decide, y donde más se falla de memoria**:
  **ArangoDB pasó a BUSL-1.1 en 3.12** (antes Apache-2.0) con tope de 100 GiB en la Community;
  **ScyllaDB dejó de ser AGPL en dic-2024** (6.2 fue la última OSS) y su free tier tiene tope
  verbatim de **10 TB y 50 vCPU por organización**; **FalkorDB es SSPLv1**; **Memgraph CE es
  BSL 1.1** con licencia por volumen que **bloquea escrituras** al alcanzar el límite; Couchbase
  es BSL con CE limitada a 5 nodos / 4 cores y sin XDCR; **MongoDB sigue en SSPL** y **no ha
  vuelto a licencia OSI** a diferencia de Elastic y Redis.
- **MongoDB: las *rapid releases* (8.1/8.2/8.3) solo tienen soporte en Atlas**, no on-prem →
  autogestionado significa **8.0 LTS** (EOL 2029-10-31), no "la última".
- **Neo4j Community no tiene clustering, RBAC ni backup en caliente** y se limita a una base de
  datos de usuario; GDS Community está topada a 4 núcleos.
- **GQL (ISO/IEC 39075, abr-2024) no tiene certificación independiente**: la conformidad es
  autodeclarada y Neo4j publica su propia lista de *features* obligatorias no soportadas.
- **MongoBleed (CVE-2025-14847) está en el catálogo KEV de CISA.**
- **DocumentDB de la Linux Foundation** (MIT, extensiones sobre PostgreSQL) — no confundir con
  Amazon DocumentDB. Sostiene la tesis de "justifícalo contra PostgreSQL primero".
- **Motores de búsqueda y vectoriales: vienen abiertos de fábrica** (citas verbatim de su propia
  documentación): **Qdrant** — *"By default, all self-deployed Qdrant instances are not secure"*;
  **Weaviate** — `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED` *"Defaults to true"*; **Milvus** — usuario
  `root` con contraseña `Milvus` de fábrica y auth desactivada salvo `authorizationEnabled`;
  **Solr** — sin auth por defecto y escuchando en todas las interfaces. **Elasticsearch** autoconfigura
  seguridad desde 8.0 **pero solo si el nodo no se une a un cluster existente y no hay ajustes
  incompatibles**. Es el dato de seguridad más valioso de ese par de skills.
- **Milvus CVE-2025-64513: bypass total de autenticación *sin autenticar*** en el Proxy
  (corregido en 2.4.24 / 2.5.21 / 2.6.5).
- **Meilisearch ya no es MIT a secas**: `MIT AND BUSL-1.1`, con Enterprise Edition bajo BSL cuyo uso
  en producción exige contrato. **Manticore es GPL-3.0** (no 2.0). **Quickwit está vivo** y pasó a
  Apache-2.0 tras la adquisición por Datadog.
- **Elasticsearch es triple licencia (AGPLv3 / SSPL / ELv2) desde 8.16**, pero hay reportes
  consistentes de que **los binarios oficiales se entregan bajo ELv2**. Declarado como hueco: la
  narrativa de "Elastic volvió a ser open source" **no es automáticamente cierta para el binario**.
- **OpenSearch está bajo la OpenSearch Software Foundation** (Linux Foundation) desde sep-2024,
  con la propiedad transferida por Amazon.
- **Mini Shai-Hulud (CVE-2026-45321), desde finales de abr-2026: gusano npm/PyPI que extrae tokens
  OIDC de la memoria del runner de GitHub Actions y FALSIFICA ATESTACIONES SLSA NIVEL 3.**
  Consecuencia directa para todo el catálogo: **la procedencia firmada ya no es prueba suficiente**.
  Refuerza —y agrava— lo que la Ola 3 anotó sobre CanisterWorm. Revisar la §5 de `cicd-standards`
  y de `mlsecops-standards` a la luz de esto.
- **IBM completó la adquisición de Confluent el 17-mar-2026** (~11 B$). Kafka no se ve afectado
  (es de la ASF), pero la **Confluent Community License sigue sin ser OSI**.
- **Iceberg ganó como *lingua franca*** del formato de tabla; la spec **v3 ya está en producción**
  (Snowflake may-2026, Databricks DBR 18+, AWS desde nov-2025) y **v2 no lee v3**. El árbol de
  metadatos común *Iceberg v4 / Delta 5.0* es **propuesta de Databricks, no decisión de comunidad**.
- **Unity Catalog OSS no incluye linaje, federación, RLS ni enmascaramiento**: adoptarlo "porque es
  open source" es un error documentado.
- **Hive Metastore sin deprecación formal pero empujado fuera** (Starburst retira su imagen en el
  LTS de ago-2026). Vetado en despliegues nuevos.
- **La versión vigente de Oracle no es 23ai: es Oracle AI Database 26ai** (GA on-prem Linux
  x86-64 el 27-ene-2026), con RU numeradas **23.26.x**. No existen 23.10/23.11.
- **Oracle añadió una vía de parcheo mensual nueva en 2026 (CSPU, desde el 28-may-2026)** además
  del CPU trimestral. Decir "solo hay CPU trimestral" ya es falso.
- **Oracle 19c: desde el 1-may-2027 quedan excluidos del soporte TDE, TLS, Native Network
  Encryption, `DBMS_CRYPTO`, Java, BSAFE y FIPS.** El horizonte real de un sistema 19c que cifre
  es 2027, no 2029/2032.
- **SQL Server 2025 subió Standard de 24 a 32 núcleos y de 128 a 256 GB de buffer pool**, y movió
  **Resource Governor a Standard**. Es el dato que más cambia un diseño y el más fácil de dar mal.
  SQL Server 2016 agotó soporte extendido el **14-jul-2026**.
- **Dos contradicciones internas en la propia documentación de Microsoft**, detectadas y **no
  resueltas** (declaradas como hueco): tamaño máximo de base en Express (50 GB en la página de
  Windows frente a 10 GB en la de Linux, misma versión) y número de réplicas síncronas en
  Enterprise (5 frente a 2). Cuando la fuente primaria se contradice, se declara — no se elige.
- **MySQL 8.0 murió el 30-abr-2026.** La LTS vigente es **9.7** (EOL 2034), y a partir de ahí
  Oracle pasa a **CalVer `YY.M`**. Ruta de actualización **8.0 → 8.4 → 9.7 sin saltos**.
  **MariaDB 10.6 murió el 6-jul-2026**; la LTS vigente es 12.3.
- **`XtraBackup` no sirve para MariaDB** (hay que usar `mariabackup`): produce **corrupción
  silenciosa**. Y **no existe Percona Server 9.7**.
- **Galera/wsrep CVE-2026-49261, CVSS 10.0**: RCE vía `wsrep_notify_cmd`.
- **nginx CVE-2026-42945 explotado en el mundo real.**
- **MySQL y MariaDB ya no son intercambiables, con hechos**: los formatos de GTID son incompatibles
  → **replicación cruzada imposible**; el JSON de MySQL es binario indexable y el de MariaDB un
  alias de `LONGTEXT` reparseado; Group Replication y Galera no se mezclan; en vectores, MariaDB
  11.8 trae `VECTOR INDEX` HNSW nativo mientras en MySQL 9.7 el índice ANN vive en HeatWave.
- **`stale-if-error` no lo implementa ningún navegador** (es directiva de CDN) y **Safari no honra
  `stale-while-revalidate`**. **Google Cloud CDN no soporta `stale-if-error`.** La **purga por
  etiqueta sigue sin estándar** (`draft-ietf-httpbis-cache-groups`, borrador).
- **MariaDB plc es propiedad de K1 Investment Management** desde sep-2024; la Foundation sigue
  independiente. Riesgo a registrar en un ADR, no veto.
- **CVE-2026-35554 en `kafka-clients` (CVSS 8.7, abr-2026): una carrera en el pool de buffers
  entrega mensajes al *topic equivocado*, en silencio.** Sin corrección en las ramas 2.8-3.8.
  Es el CVE más peligroso del lote: no cae el sistema, corrompe el dato sin avisar.
- **RabbitMQ 4.0 eliminó las colas espejadas clásicas** y **4.3 dejó Khepri como único almacén de
  metadatos** (Mnesia desapareció); soporte comunitario de la 4.3 hasta el 30-nov-2026.
- **NATS: el conflicto de gobernanza se resolvió a favor de la CNCF** (may-2025) — Synadia intentó
  pasar a BSL y reclamar la marca; hoy las marcas están en la Linux Foundation y el núcleo
  garantizado Apache 2.0.
- **InfluxDB 3 Core es de un solo nodo y sin HA**; la compactación para consultas históricas de
  rango largo está en Enterprise. La etiqueta `latest` de Docker pasa a apuntar a Core el 15-sep-2026.
- **Timescale se renombró a TigerData** (jun-2025) y la TSL figura como *Tiger Data License*;
  **no hubo relicenciamiento en 2026** (hipótesis desmentida por la verificación).
- **Redpanda es BSL 1.1** con una concesión que **excluye explícitamente ofrecer un "Streaming or
  Queuing Service"**; *Change Date* a 4 años por versión.
- **PostgreSQL 18: el parámetro nuevo es `idle_replication_slot_timeout`** (no `inactive_timeout`),
  invalida en el *checkpoint* y no aplica a slots `synced`. **`max_slot_wal_keep_size` viene en `-1`
  (ilimitado)** y, al superarse, **invalida el slot** → obliga a reinstantánea.

## Aviso metodológico (dos agentes lo reportaron por separado)

**El resumidor de WebFetch inventa el año al leer el HTML de GitHub Releases.** Toda fecha de
GitHub debe salir de `api.github.com` o de los feeds Atom, nunca del render HTML. Incluir este
aviso en los prompts de las olas siguientes.

**Y no solo fechas: invierte el sentido de frases normativas.** En la Ola 2 devolvió
*"non-versioned machine type"* donde la documentación de QEMU dice *"non-deprecated"* — la
recomendación contraria. Regla añadida a los prompts: **cualquier cita normativa que decida algo
se pide verbatim, no resumida.**

## DECISIÓN TOMADA: el coste de índice se acepta (usuario, 2026-08-02)

**No volver a plantearlo.** El usuario aceptó explícitamente la opción (1): descripciones densas
en todo el catálogo, con el coste de índice que conlleve. La regla operativa sigue siendo la del
meta-skill — **cero relleno**: cada término debe ser un disparador real. Lo que queda prohibido es
recortar por cuota destruyendo disparadores legítimos, no la longitud en sí.

La medición de abajo se conserva como referencia para volver a medirla en olas futuras, no como
problema abierto.

## Medición de referencia del coste de índice

Medición real a 66 skills (gate §6 del meta-skill, ejecutado 2026-08-02):

| | Palabras |
|---|---|
| Total de las 66 `description` | **5.093** (~7.100 tokens por turno) |
| Media | **77** |
| Ola 0 (referencia original) | ~35 |
| Olas 2-3 | **77-173** (máximo: `mlsecops` 173, `ai-governance` 170) |

**Extrapolación**: a 267 skills con la media actual, el índice ronda los **29k tokens por turno**,
frente a los **~20k** que estimó el plan. La deriva viene de que las olas recientes enumeran
muchos artefactos por descripción — cada término *es* un disparador legítimo (la regla del
meta-skill es "cero relleno", no una cuota), así que **no es relleno: es cobertura**.

**Extrapolación**: a 267 skills con la media actual, ~**29k tokens por turno**. Aceptado.

## Deuda técnica pendiente

- **Pasada de reciprocidad de la Ola 2**: hecha parcialmente (`networking`↔`firewall-policy`/`dns`,
  `zfs`↔`linux-administration`, tabla §1.2 de `onprem` al día). Queda revisar si las 14 nuevas
  aparecen citadas desde las skills antiguas que deberían enrutarlas.
- **Revisión de seguridad: hecha sobre las 82** (secretos, IPs/rutas internas, inyección de prompt,
  ejecución encubierta, comandos destructivos, recetario ofensivo). **Sin hallazgos** en las cinco
  olas: todas las coincidencias son prohibiciones o números de versión.
- **Revisión de SLSA tras Mini Shai-Hulud: hecha.** `cicd-standards` §2 lleva ahora un aviso
  explícito de que **la atestación es necesaria pero ya no suficiente**, con el control que sí
  corta esa clase (pin por SHA/digest de todo lo que entra al runner, minimizar su alcance,
  credenciales de CI rotables en cualquier momento). `mlsecops-standards` delega la procedencia
  en `cicd`, así que queda cubierta por esa vía.
- **Pasada de reciprocidad de la Ola 1: HECHA.** `onprem` (tabla §1.2 actualizada con 8 filas
  nuevas), `kubernetes`↔`container-runtime-security`/`selinux`, `iam`↔`windows-server-ad`,
  `grc`↔`privacy`/`bcdr`, `data-platform`↔`privacy`/`bcdr`, `observability`/`networking`↔
  `detection-engineering`, `appsec`/`vulnerability-management`/`homelab`↔`offensive-security`/
  `ctf-lab`, `bash-linux-scripting`↔`linux-hardening`/`selinux`. `sre-practice` la corrigió el
  propio agente de incidentes (su frontera citaba un slug inexistente y su `description`
  reclamaba 6 términos de `incident-management`).
- **Frontera de arbitraje a respetar en la Ola 2**: `bcdr` ↔ `backup-recovery` (Ola 2) está
  escrita como *"¿cómo se hace la copia?" → `backup-recovery`; "¿cuánto podemos perder, en qué
  orden lo levantamos y quién lo decide?" → `bcdr`"*. Es la colisión más probable de la ola.
- **Huecos marcados en `cryptography-pki`**: fechas del ballot SC-081 (47 días), calendario
  CNSA 2.0, versiones de Keycloak/step-ca/cert-manager. Cerrar con presupuesto de búsqueda nuevo.
- **Prueba funcional real** (gate 4 del meta-skill): abrir un fichero de cada dominio y
  confirmar que se activa la skill correcta y solo esa. Sin hacer para ningún lote.

## Correcciones ya aplicadas (no repetir)

- **Trivy**: retirado como escáner por defecto en `iac-standards` y `kubernetes-standards`
  tras el compromiso de cadena de suministro de marzo 2026 (tag poisoning de `trivy-action`
  y `setup-trivy`, robo de secretos de CI). Defaults ahora: checkov + OSV-Scanner/Grype + gitleaks.
