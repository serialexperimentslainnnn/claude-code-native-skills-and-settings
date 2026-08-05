---
name: git-workflow-standards
description: Git branching, commit and release process standards. Use when working with branching strategy, Conventional Commits, rebase vs merge, PR size limits, CODEOWNERS, protected branches or rulesets, SemVer tagging, CHANGELOG, release-please/changesets/semantic-release/goreleaser, git-filter-repo, Git LFS, or GPG/SSH commit signing.
---

# Estándares de Git y proceso de release

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al definir o revisar cómo se usa el repositorio y cómo sale una versión: estrategia de ramas, naming y vida de ramas, mensajes de commit y `commitlint.config.*`, política rebase/merge/squash, tamaño de PR y checklist de revisión, `CODEOWNERS`, ramas protegidas y rulesets, `.gitattributes`/`.gitignore`, tags y versionado semántico, `CHANGELOG.md`, configuración de `release-please`/`changesets`/`semantic-release`/`.goreleaser.yaml`, monorepo vs polyrepo y su tooling, higiene de historia (`git-filter-repo`, BFG, Git LFS), firma de commits y tags, `git bisect`/`blame`, y procedimientos de hotfix, revert y rollback.

Principio rector: **la historia de Git es infraestructura de diagnóstico y de auditoría**, no un registro accidental de lo que pasó. Se diseña para que dentro de dos años alguien pueda responder "por qué está esta línea así" con `blame` y "qué commit lo rompió" con `bisect`; todo lo demás (estilo de merge, formato de mensaje, tamaño de PR) es consecuencia de eso.

**No aplica**: ver `cicd-standards` (la pipeline en sí — jobs, runners, OIDC, SBOM, firma y verificación de artefactos, despliegue: asume el repo ya gobernado por esta skill), `api-design-standards` (versionado del **contrato** de la API, que es independiente del SemVer del paquete), `appsec-standards` (triaje de los hallazgos que produzcan los escáneres), `cryptography-pki-standards` (elección de algoritmos, gestión de claves y ciclo de vida de la PKI; aquí solo la aplicación concreta a commits y tags), las skills de lenguaje (publicación en el registro del ecosistema: npm, PyPI, crates.io, Maven), `developer-workstation-standards` (**Ola 6**: **la política de firma —qué se firma, con qué formato y qué se exige en las ramas protegidas— es de aquí**; **dónde vive la clave y cómo se custodia es suyo**: clave en hardware, `verify-required`, y la versión mínima de OpenSSH que la firma SSH de Git exige), `code-review-standards` (**Ola 6 — frontera fina, regla de arbitraje**: **aquí manda todo lo mecánico y configurable del repositorio** —estrategia de ramas, formato de commit, `CODEOWNERS`, ramas protegidas y *rulesets*, número de aprobaciones exigidas, el límite de tamaño de PR como regla—; **allí manda el criterio humano**: qué se busca al revisar y en qué orden, cómo se redacta un comentario y qué lo hace bloqueante o sugerencia, qué cambios exigen revisor especialista, y cómo se revisa un diff generado por IA. En una frase: **el número lo pone esta skill, el juicio lo pone la suya**. Lo que esta skill dice sobre tamaño de PR, SLA de revisión, el prefijo `nit:` y "aprobar sin haber leído es una firma falsa" se conserva como convención del repo, pero **su criterio vive allí y allí manda si hay discrepancia**).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Modelo de ramas | **Trunk-based**: `main` siempre desplegable + ramas de vida corta | GitHub Flow (equivalente con PR obligatorio); **GitFlow solo** con releases versionadas y varias versiones mayores soportadas en paralelo (software instalable, firmware) |
| Vida máxima de rama | **≤ 2 días**, idealmente < 1 | Hasta 1 semana con rebase diario documentado |
| Integración de trabajo grande | **Feature flags** + merge continuo a `main` | Rama larga solo con ADR que lo justifique |
| Política de merge a `main` | **Squash** (una unidad lógica por PR) con título Conventional Commit | Rebase + fast-forward si los commits del PR ya son atómicos y limpios; merge commit en repos con integración de ramas de release |
| Formato de mensaje | **Conventional Commits 1.0.0** | Formato propio solo si no usas automatización de release |
| Versionado | **SemVer 2.0.0**, tags `vX.Y.Z` anotados y firmados | CalVer en productos sin API pública (servicios internos, infra) |
| Automatización de release | **release-please** (políglota, monorepo, PR de release revisable) | `changesets` en monorepos JS/TS; `semantic-release` para publicación totalmente automática; `goreleaser` para artefactos Go |
| Firma | **SSH con clave `ed25519-sk` en YubiKey** (§5) | GPG con applet OpenPGP si necesitas revocación real o cadena de confianza existente |
| Protección de `main` | **Rulesets** de GitHub (aplican a admins por defecto) | Branch protection clásica solo en repos ya configurados con ella |
| Estrategia de repo | **Polyrepo** por defecto; monorepo cuando los cambios cruzan sistemáticamente varios repos | — |
| Reescritura de historia | **git-filter-repo** | — |
| Binarios grandes | **Git LFS** con `.gitattributes` versionado | — |

## 3. Ramas, commits y revisión

### 3.1 Ramas

- Naming: `<tipo>/<id-ticket>-<slug-corto>` (`feat/PROJ-412-cursor-pagination`, `fix/PROJ-508-null-etag`). Minúsculas, guiones, sin nombres personales (`juan/pruebas`) ni genéricos (`temp`, `wip`, `test2`).
- **Una rama = una unidad de valor revisable**. Si al describirla necesitas una "y", son dos ramas.
- Sincronización con `main` **a diario** por rebase mientras la rama no esté publicada/compartida. Una rama que lleva una semana sin rebase ya no se está integrando: se está bifurcando.
- Borrado automático de la rama al mergear. Las ramas muertas en el remoto son ruido y confunden el `bisect`.
- `main` protegida; ramas de release (`release/1.x`) solo en el modelo GitFlow y con la misma protección.

### 3.2 Commits

- **Atómicos**: un commit compila, pasa tests y hace *una* cosa. Refactor y cambio de comportamiento **siempre en commits separados** — mezclarlos hace la revisión imposible y el `bisect` inútil.
- Conventional Commits 1.0.0: `<tipo>[ámbito opcional]: <descripción>`. La spec solo exige `feat` y `fix`; el resto (`docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) es convención del equipo y **no** afecta al bump de versión salvo que lleve breaking change. Breaking: `!` tras el tipo/ámbito **o** footer `BREAKING CHANGE:` — mapea a mayor.
- Asunto en imperativo, ≤ 72 caracteres, sin punto final. **El cuerpo explica el porqué**, no el qué (el diff ya dice el qué): contexto, alternativas descartadas, consecuencias. Footer con referencia al ticket y `Co-authored-by:` cuando aplique.
- Prohibido: `wip`, `fix`, `.`, `asdf`, "arreglos varios". Si el commit necesita ese mensaje, aún no está terminado — usa `git commit --fixup`/`--squash` + `rebase --autosquash`, o `git history fixup` si tu versión de Git lo trae (experimental desde 2.55).
- Commits generados o asistidos: la autoría real se refleja en `Co-authored-by`; el mensaje sigue siendo responsabilidad de quien firma.

### 3.3 Rebase vs merge

- **Rebase** para poner al día una rama propia no publicada y para limpiar la historia antes del PR.
- **PROHIBIDO rebase/force-push sobre ramas compartidas o publicadas** (incluida `main`). Si hay que corregir algo ya publicado: `git revert`, nunca reescritura. Excepción única: eliminación de un secreto o de datos personales (§5.3), y con coordinación explícita de todo el equipo.
- Si necesitas force-push en tu propia rama, **`--force-with-lease`** (idealmente `--force-if-includes`), nunca `--force` a secas.
- Squash al mergear: mantiene `main` legible y con un commit por unidad de valor. Consecuencia obligatoria: **el título del PR debe cumplir Conventional Commits** y se lintea en CI, porque es el mensaje que queda en la historia.
- Con `--first-parent` en `log`/`bisect`, `main` con squash es una secuencia lineal de cambios completos: es lo que hace `git bisect` barato.

### 3.4 Pull requests y revisión

- **Tamaño**: objetivo ≤ 400 líneas de diff neto, máximo duro ~800 salvo cambios mecánicos (generados, renombrados masivos, lockfiles) declarados en la descripción. Por encima, la revisión deja de detectar defectos y pasa a ser un trámite. PR grande ⇒ trocearlo o revisar por commits atómicos.
- Descripción con: qué cambia y por qué, cómo se ha verificado, riesgo y plan de rollback, capturas o salidas si aplica. Enlace al ticket. Un PR que no explica el porqué no está listo para revisión.
- Checklist del revisor: corrección y bordes; seguridad (entradas, authz, secretos, dependencias nuevas); tests significativos que cubran el fallo, no solo el camino feliz; observabilidad del cambio; migraciones compatibles hacia atrás; documentación y ADR si la decisión es one-way.
- **Etiqueta y SLA**: primera respuesta en **≤ 1 día laborable** (el PR bloqueado es inventario que se deprecia). Comentarios sobre el código, no sobre la persona; distingue lo bloqueante de la sugerencia (prefijo `nit:`); si son más de 3 idas y vueltas, la conversación pasa a síncrono. Aprobar sin haber leído es una firma falsa.
- **CODEOWNERS** en `.github/CODEOWNERS` para las zonas críticas: workflows de CI, IaC, migraciones, autenticación, contratos de API. La última regla que casa es la que manda — el orden importa. Revisión de owner obligatoria en esas rutas.

### 3.5 Ramas protegidas y rulesets

En `main` (y en las ramas de release), como mínimo:
- PR obligatorio con ≥ 1 aprobación (2 en código sensible), revisión de CODEOWNERS donde aplique, y descarte de aprobaciones al hacer push nuevo.
- **Required status checks** con la lista explícita de jobs, y "up to date before merging" o merge queue. Ojo: los checks se referencian **por nombre**; renombrar un job en CI desactiva el gate en silencio.
- Historia lineal requerida (coherente con squash/rebase), sin force-push, sin borrado de la rama.
- **Commits firmados obligatorios** (§5.1). Matiz verificado: con rulesets, al crear una rama solo se comprueban los commits no alcanzables desde otras ramas; la branch protection clásica no verifica firmas al crear rama salvo que restrinjas quién puede crearlas.
- Prefiere **rulesets** a la protección clásica: aplican a los administradores por defecto, se pueden definir a nivel de organización y son evaluables/auditables en conjunto.

## 4. Versionado, release y monorepo

### 4.1 SemVer y changelog

- SemVer 2.0.0 sobre el **contrato público** del artefacto: mayor = ruptura, menor = funcionalidad compatible, patch = corrección. `0.x` es explícitamente "sin garantías" — sal de `0.x` cuando haya consumidores reales.
- Tags **anotados y firmados** (`git tag -s vX.Y.Z -m`), inmutables. **Prohibido mover un tag publicado**: si la release está mal, se publica `X.Y.Z+1` y se marca la anterior como *yanked* en el registro.
- `CHANGELOG.md` **generado** desde los commits (Keep a Changelog como formato), nunca escrito a mano en paralelo. Sección de breaking changes con instrucciones de migración: un breaking change sin guía de migración es una release incompleta.
- La release incluye: tag firmado, notas, artefactos y su verificación. La construcción, firma y publicación de esos artefactos es `cicd-standards`.

### 4.2 Herramientas

- **release-please**: lee Conventional Commits, abre un **PR de release** (checkpoint humano), soporta múltiples ecosistemas y monorepos con versionado independiente o enlazado. Default cuando quieres revisar antes de publicar.
- **changesets**: fichero de cambio escrito por el contribuidor (no deducido del commit) — encaja en monorepos JS/TS con muchos paquetes y colaboración externa. Limitado al ecosistema JS.
- **semantic-release**: publica directamente desde CI sin checkpoint. Solo con suite de tests fiable y equipo cómodo con release continua.
- **goreleaser**: artefactos Go (binarios multiplataforma, Homebrew, contenedores). **No crea tags**: se combina con release-please/semantic-release/`svu` para la versión.
- Sin enforcement de Conventional Commits, estas herramientas **ignoran en silencio** los commits que no cumplen: el cambio se queda sin publicar. El lint del mensaje es parte del sistema de release, no cosmética.

### 4.3 Monorepo vs polyrepo

- **Polyrepo por defecto**. Monorepo cuando los cambios cruzan repos de forma sistemática (cambio atómico multi-paquete), o cuando compartes tooling y quieres un único grafo de dependencias. El monorepo cambia el problema de coordinación por un problema de tooling de build.
- Si monorepo: build con grafo y caché (Nx, Turborepo, Bazel/Buck2 según escala), ejecución **solo de lo afectado** en CI, `CODEOWNERS` por directorio, versionado por paquete (independiente o enlazado) y `sparse-checkout`/`--filter=blob:none` para clones parciales en repos grandes. Sin "solo lo afectado" y sin caché, el monorepo es un impuesto sobre cada PR.
- La decisión es **one-way en la práctica** (migrar cuesta meses): ADR obligatorio.

## 5. Seguridad e higiene del repositorio

### 5.1 Firma con SSH respaldada por YubiKey (configuración concreta)

Requisitos verificados: Git ≥ 2.34 (firma SSH), OpenSSH ≥ 8.2 (claves FIDO2 `-sk`), ≥ 8.4 para `-O verify-required`. YubiKey serie 5/Bio/Security Key; las claves *resident* exigen PIN FIDO2 configurado.

```bash
ssh-keygen -t ed25519-sk -O resident -O application=ssh:git -O verify-required \
  -C "dev@digitalexperiments.dev git signing"
```

```gitconfig
[user]
    signingKey = ~/.ssh/id_ed25519_sk.pub
[gpg]
    format = ssh
[gpg "ssh"]
    allowedSignersFile = ~/.config/git/allowed_signers
    revocationFile     = ~/.config/git/revoked_signers
[commit]
    gpgsign = true
[tag]
    gpgsign = true
```

`~/.config/git/allowed_signers` (formato documentado en `ssh-keygen(1)`, sección ALLOWED SIGNERS):

```
dev@digitalexperiments.dev namespaces="git" valid-after="20260101" sk-ssh-ed25519@openssh.com AAAA...
```

Reglas y trampas concretas:
- **No generes la clave con `-O no-touch-required`**: hay verificadores (GitLab, y GitHub vía la librería `ssh_data`) que marcan como *unverified* las firmas de claves `-sk` con esa opción. El *touch* por commit es el precio de la resistencia a extracción; si molesta, agrupa con `--fixup` + `rebase --autosquash` en vez de desactivarlo.
- En GitHub la clave debe subirse con tipo **Signing Key** — es un registro distinto del de Authentication Key, aunque sea el mismo material. Además, el email del **committer** debe ser un email verificado de la cuenta o el badge no aparece. Y ojo: la firma verifica al *committer*, no al *author*.
- **Rotación y revocación**: GitHub no revoca claves de firma SSH (la verificación queda registrada y persiste). Localmente, `valid-after`/`valid-before` en `allowed_signers` invalida a partir de una fecha manteniendo válida la historia previa; `revocationFile` invalida **también los commits históricos** — úsalo solo ante compromiso real de la clave.
- Verificación local: `git log --show-signature`, `git verify-commit <sha>`, `git verify-tag <tag>`. Sin `allowedSignersFile` configurado, `verify-commit` falla con error de configuración, no con "firma inválida": no confundas ambos.
- Segunda YubiKey de respaldo enrolada **desde el principio** (una llave perdida sin backup = identidad de firma perdida) y ambas claves públicas en `allowed_signers` y en el forge.
- Alternativa GPG con applet OpenPGP de la YubiKey: válida y con revocación real (certificado de revocación offline), a costa de gestionar `gpg-agent`, pinentry y touch policy con `ykman` (verifica sintaxis exacta, §8). No mezcles ambos formatos en el mismo repo.
- **gitsign/Sigstore** (firma keyless por OIDC, ideal para bots en CI): mantenido y con releases recientes, pero **GitHub no muestra sus firmas como Verified** — su raíz no está en el trust root del forge. Úsalo para trazabilidad en CI, no para el badge.
- Del lado del servidor: rulesets con "require signed commits" en GitHub; en GitLab, push rule **Reject unsigned commits** (Premium/Ultimate) — que además bloquea los commits desde el Web IDE salvo que un admin desactive el feature flag correspondiente, y que ha dado falsos rechazos con firmas de bots.

### 5.2 Secretos

- **Prevención primero**: secret scanning con push protection en el forge + hook local + gate en CI. El scanning es la última red, no la política. La **elección del escáner y su licencia** son de `secrets-management-standards` (a ago-2026 `gitleaks` está *feature complete* y su action de GitHub exige licencia comercial para organizaciones: verifica antes de fijarlo); el **procedimiento tras la fuga** también vive allí — el secreto está quemado aunque reescribas el historial: se rota primero y se limpia después.
- Un secreto que llegó al repo **está comprometido**: el orden es *rotar → revocar → invalidar → después limpiar la historia*. Borrar el commit sin rotar es teatro: hay forks, clones, caché del forge y logs de CI.
- Nada de `.env` con valores reales versionado; `.env.example` con claves vacías, `.gitignore` que cubra artefactos, credenciales y dumps, y `.gitattributes` para evitar mangling de binarios.

### 5.3 Reescritura de historia y ficheros grandes

- **`git-filter-repo`** es la herramienta (Git desaconseja oficialmente `filter-branch`: lento, lleno de trampas y con manglings no obvios). BFG sigue publicado pero sin releases recientes; su continuación comunitaria es `bfg-ish`.
- Reescribir historia publicada es una operación coordinada: aviso previo, ventana acordada, todos reclonan (`git pull --rebase` no basta), forks del forge invalidados y soporte del proveedor contactado para purgar caché y PRs viejos.
- Binarios y ficheros grandes: **Git LFS** con `.gitattributes` versionado, decidido **antes** del primer commit (migrar después implica reescritura). Alternativa: no versionarlos y publicarlos como artefactos de release. Un repo que arrastra binarios es un repo que nadie clona en menos de 10 minutos.
- Git LFS: usa **≥ 3.7.1**, que corrige CVE-2025-26625 (escritura fuera del working tree por colisión de symlinks/hardlinks con rutas LFS en `checkout` y `pull`).

## 6. Diagnóstico y procedimientos de emergencia

- **`git bisect`** es la razón por la que exiges commits atómicos y verdes. `git bisect start/bad/good` + `git bisect run <script>` automatiza la búsqueda; con `main` lineal (squash) y `--first-parent`, el espacio de búsqueda es una unidad de valor por paso.
- **`git blame`** útil requiere no contaminar la historia con reformateos: los cambios masivos de formato van en su propio commit y ese SHA se registra en `.git-blame-ignore-revs` (+ `blame.ignoreRevsFile` en la config del repo).
- Útiles al depurar: `git log -S<cadena>` (pickaxe, cuándo apareció/desapareció un texto), `git log -L` (evolución de un rango de líneas), `git reflog` (recuperar lo que creías perdido: casi nada se pierde de verdad en 90 días).
- **Revert**: `git revert <sha>` es el mecanismo por defecto para deshacer en `main`. Si el commit era un merge, `-m 1`; documenta en el mensaje qué se revierte y por qué, y abre el ticket de la corrección — un revert no es el arreglo, es la contención.
- **Hotfix**: rama desde el tag de producción (no desde `main` si `main` ha avanzado), cambio mínimo, mismos gates de CI (nunca `--no-verify` ni merge de admin saltándose checks), tag de patch firmado, y **backport a `main` en el mismo día** con verificación de que existe. El hotfix que nunca vuelve a `main` reaparece en la siguiente release.
- **Rollback** de producción es un evento de despliegue (promoción del artefacto anterior), no de Git; revertir el commit sin desplegar no arregla nada. Ver `cicd-standards`.
- Postmortem sin culpa cuando la causa fue de proceso (rama larga, PR gigante, gate desactivado): la acción de seguimiento es un cambio en estas reglas, no un aviso a una persona.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Semanal: revisión de PRs abiertos > 3 días y de ramas sin actividad > 1 semana (se cierran o se rescatan).
- Mensual: revisión de reglas de protección y required checks (¿siguen existiendo esos jobs con ese nombre?), y de la versión del tooling de release.
- Trimestral: `git maintenance` / `gc` en repos grandes, revisión del tamaño del repo y de patrones LFS, auditoría de claves de firma activas y de accesos con permiso de escritura.
- Por versión de Git: los defaults van a cambiar en **Git 3.0** (SHA-256 por defecto en repos nuevos, reftable como backend de referencias, rama por defecto `main`, `safe.bareRepository=explicit`, Rust obligatorio; eliminación de grafts, `git-pack-redundant`, `git whatchanged`, `name-rev --stdin`). Sin fecha anunciada: no dependas de comportamientos que ya están marcados para cambiar.

**PROHIBIDO**
- ❌ Push directo a `main` (incluidos admins y bots) o merge saltándose gates.
- ❌ `--no-verify`, `[skip ci]` o desactivar un check "temporalmente" sin issue, motivo y fecha de caducidad.
- ❌ Rebase o force-push sobre ramas compartidas; `--force` sin `--force-with-lease`.
- ❌ Reescribir historia publicada salvo por secretos o datos personales, y sin coordinación explícita.
- ❌ Mover, reutilizar o borrar un tag ya publicado.
- ❌ Ramas de vida larga sin ADR; ramas de release paralelas "porque sí".
- ❌ Commits que mezclan refactor y cambio de comportamiento; commits que no compilan o rompen tests.
- ❌ Mensajes vacíos de contenido (`wip`, `fix`, `.`) en `main`.
- ❌ PR sin descripción, sin verificación declarada o por encima del límite de tamaño sin justificar.
- ❌ Aprobar un PR sin revisarlo, o autoaprobación en rutas con CODEOWNERS.
- ❌ Secretos, credenciales, dumps de datos o binarios grandes versionados sin LFS.
- ❌ Borrar un secreto de la historia **sin rotarlo** antes.
- ❌ Commits o tags sin firmar en repos con firma obligatoria; claves `-sk` con `no-touch-required`; clave de firma sin respaldo enrolado.
- ❌ `CHANGELOG.md` escrito a mano en paralelo al generado.
- ❌ Release manual desde el portátil de alguien (sin tag firmado, sin pipeline, sin trazabilidad).
- ❌ `git filter-branch` en repos nuevos (usa `git-filter-repo`).
- ❌ Hotfix que no vuelve a `main`.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento, **búscalo — no lo recuerdes**:

1. **Versión de Git** vigente y sus release notes (a ago-2026, la doc oficial de `BreakingChanges` referenciaba **2.55.0**, jun-2026; 2.54 introdujo `git history` experimental con `reword`/`split` y hooks por configuración, y 2.55 añadió `git history fixup`). Comprueba `git-scm.com/docs/BreakingChanges` para el estado real de Git 3.0 y sus defaults.
2. **CVEs de Git y Git LFS** y versión mínima parcheada antes de fijar un requisito de versión (Git LFS ≥ 3.7.1 por CVE-2025-26625).
3. **Firma**: soporte y matices actuales de claves `-sk` como *signing key* en GitHub y GitLab, comportamiento de `no-touch-required`, y la sintaxis exacta de `ykman openpgp keys set-touch` si vas por la vía GPG. Versión estable de OpenSSH y GnuPG.
4. **Rulesets vs branch protection** en GitHub: nombres exactos de las reglas disponibles, estado de la protección clásica (a ago-2026 documentada como activa, no formalmente deprecada) y estado de merge queue. En GitLab, si "Reject unsigned commits" sigue siendo Premium/Ultimate y el estado del feature flag del Web IDE.
5. **Tooling de release**: versión y salud de `release-please`, `changesets` (`@changesets/cli` 2.x), `semantic-release` (24.x; su documentación se movió a `semantic-release.org`, la de GitBook está discontinuada) y `goreleaser` (línea 2.x, con edición Pro de pago).
6. **Specs**: Conventional Commits (1.0.0 vigente en `conventionalcommits.org`) y SemVer (2.0.0 en `semver.org`).
7. **Monorepo**: versiones y **licencias** vigentes de Nx, Turborepo y Bazel antes de comprometer una elección — no asumas que siguen siendo las de tu última lectura.
8. **Higiene**: última versión de `git-filter-repo` (2.47.x en jun-2026) y estado de mantenimiento de BFG/`bfg-ish`; límites vigentes de tamaño de fichero y repo del forge que uses.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
