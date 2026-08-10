---
name: claude-code-skills-standards
description: Use when authoring, reviewing or debugging Claude Code Agent Skills — SKILL.md files, frontmatter fields, description triggers, skill activation problems, catalog organization, or deciding whether something belongs in a skill, CLAUDE.md or a subagent.
---

# Estándares de autoría de skills de Claude Code

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al crear, revisar, depurar o reorganizar skills: ficheros `SKILL.md`, frontmatter,
diseño de `description`, problemas de activación ("la skill no salta" / "salta la que no
es"), y la decisión de dónde vive una regla.

**No aplica**: `update-config` (configuración del harness en `settings.json`, hooks y
permisos), `knowledge-management-standards` (documentación para personas: ADR, runbooks, README),
`ai-agent-workflow-standards` (cómo se usan agentes de forma segura, no cómo se escriben
sus skills).

## 2. Decisiones por defecto

> Verificar la especificación vigente por web antes de fijar campos de frontmatter (§8):
> el estándar Agent Skills y las extensiones de Claude Code divergen y evolucionan.

| Decisión | Por defecto | Motivo |
|---|---|---|
| Ubicación | `~/.claude/skills/<slug>/SKILL.md` (global) o `.claude/skills/` (proyecto) | Descubrimiento automático por filesystem; el de proyecto gana ante colisión de nombre |
| Campos de frontmatter | Solo `name` + `description` | Son los únicos imprescindibles; todo lo demás añade superficie y, en algunos casos, fricción de permisos |
| `allowed-tools` | **No usar salvo necesidad demostrada** | Marcado experimental en el estándar; hay reporte abierto de que se parsea pero **no se aplica**, y su presencia exige aprobación del usuario en el primer uso. No confiar en él como control de seguridad |
| `disable-model-invocation` | Solo en skills que deban ser exclusivamente manuales (`/nombre`) | Una skill que nunca se autoactiva paga coste de índice sin dar beneficio automático |
| Idioma | `description` en **inglés**, cuerpo en el idioma de trabajo | El enrutado se hace sobre la descripción; el inglés es el idioma de los triggers técnicos |
| Longitud del cuerpo | **La dicta el contenido, no una cuota** | El cuerpo no se carga hasta la activación: extenderse no cuesta índice. El límite real es la **densidad** — cada línea fija una decisión, prohibición o verificación. Un dominio denso puede pedir 400+ líneas; uno de nicho, 80 |
| Ficheros auxiliares | `references/`, `scripts/` junto al `SKILL.md` cuando el contenido no cabe | Se cargan bajo demanda desde el cuerpo, no en el índice |

**Regla de oro del catálogo**: la `description` se paga en **cada turno**; el cuerpo solo
cuando la skill se activa. Optimiza la descripción para el enrutado, el cuerpo para el uso.

## 3. Estructura y convenciones

- **Directorio = slug = `name`**. Sufijo `-standards` para skills de criterio de dominio.
- No poner plantillas ni ficheros de referencia dentro de `~/.claude/skills/`: cualquier
  directorio con `SKILL.md` se registra y contamina el índice. Fuera del árbol.
- Cuerpo con las 8 secciones canónicas (ver `~/.claude/SKILL-TEMPLATE.md`).
- **Frontera explícita en §1** (`**No aplica**: ver `knowledge-management-standards` (frontera limpia y fácil de confundir:
**la documentación para personas es suya** —Diátaxis, docs as code, README, runbook, guía de
incorporación, dueño y fecha de revisión—; **aquí la autoría de skills**, que son instrucciones para
un modelo con un coste de índice y un criterio de activación propios. Una skill no es documentación
y no se escribe como tal: no explica, decide), X, Y`) en **ambos lados** de cada par
  que pueda competir. Sin esto, dos skills vecinas se pisan y el enrutado se vuelve azar.
- Fecha de referencia en la primera línea del cuerpo.

### Diseño de `description` (lo más importante del fichero)

- **Sin límite duro de palabras.** La regla es *cero relleno, cero solape con hermanas*:
  una descripción larga se justifica si cada término es un disparador distinto (nombres de
  servicio de un cloud, por ejemplo); una corta pero conceptual es peor que una larga y
  concreta. Recortar por cuota destruye triggers legítimos.
- Empezar por `Use when …` y enumerar **artefactos concretos**: extensiones (`.tf`, `.rs`),
  ficheros (`pyproject.toml`, `Chart.yaml`), binarios (`nft`, `cosign`), frameworks.
- **Prohibido** describir por concepto abstracto: `for best practices and quality` no
  dispara nada porque no coincide con ningún token de una tarea real.
- **Test de colisión obligatorio**: antes de añadir una skill, comparar su descripción con
  las de su familia. Si comparten más de 2-3 términos disparadores, o se estrechan los
  triggers o se fusionan las skills.

## 4. Calidad y verificación

Gates antes de dar una skill por buena:

1. **Frontmatter válido**: `grep -c '^name:'` y que `name` == nombre del directorio.
2. **Descripción sin relleno**: no hay cuota de palabras (§3) — el gate es que **cada término
   sea un disparador**. Si una descripción es larga porque enumera servicios o extensiones,
   está bien; si lo es por prosa conceptual, se recorta esa prosa, nunca los triggers.
3. **Frontera declarada**: existe la línea `**No aplica**` y todas las skills citadas existen.
   Test mecánico del catálogo — solape de términos disparadores entre pares de la misma familia:
   ```bash
   python3 - <<'EOF'
   import re,glob,itertools
   STOP=set("""use when working with or and the a an for of to in on writing reviewing designing
   standards engineering apply any code project service services files file level staff principal via
   targeting provider security architecture work like from than rather that this these under over
   into out system state model mapping source config configuring extension trigger triggers editing
   options profiles new real also both per each all more most other their your you we they what how
   why between across within without running versus its it choosing instead backing debugging
   diagnosing server exit mode access block control design rules production pools volumes deciding
   belongs whole end one every
   are was were be been being has have had does did not must should can may will would
   cost data time whether before after first already inside where who which while until
   query queries schema metrics management operating managed self-hosted major-version upgrades
   decision decisions impact business core standard enterprise licence license tiers retention
   storage capacity sizing lifecycle versioning replication partition partitioning snapshot
   snapshots restore backup index indexes indexing key keys log logs engine engines platform
   pipeline api cli sql postgresql apache open public deep long late two them their
   human framework governance policy policies audit incident process vendor approval change
   content ownership owned severity customer contract lineage catalog metadata coverage
   analysis compression deduplication topology plan plans isolation limits store stored
   task success building against picking measuring judging reading writes fields field
   team teams people person individual role roles owner ownership adoption evidence practice
   review reviewing reviewer deciding choosing writing running applying setting measured
   report reporting metric metrics target targets threshold thresholds budget budgets
   organization organizational internal external corporate enterprise product delivery
   framework frameworks method methods model models standard standards guide guidance
   licence licensing cost costs price pricing plan planning scope quality risk risks
   documentation docs document documents page pages content contents
   standards. code. decision. it. all. network. own itself about someone nobody covers
   application app apps applications component components module modules package packages library
   libraries plugin plugins tool tools suite suites stack layer layers
   migration migrating migrate legacy modernization rewrite replacing replacement
   evaluating checking check checks validation verifying tracking managing manager
   configuration setup provisioning deployment deploying deployed environment environments
   runtime native custom dynamic static shared distributed hybrid remote offline online live
   support supported unsupported maintenance updates update refresh release releases freeze
   version versions edition editions
   test tests testing gate gates rule ruleset criteria constraint constraints
   error errors failure failures problem problems issue issues
   node nodes host hosts cluster clusters server servers instance instances machine machines
   disk memory cpu port ports path paths directory root
   user users group groups identity credential credentials token tokens secret secrets
   certificate certificates encryption signing rotation trust
   traffic route routes egress ingress exposure
   image images container containers registry
   agent agents automation automated scripts script scheduling
   event events session sessions channel channels protocol protocols format formats
   inventory assets asset record records tree naming named set sets lists list
   type types classes classification
   compliance regulation regulations iso iso/iec nist rfc
   availability recovery rollback hardening telemetry monitoring observability
   third-party saas proprietary vendor-managed training weights inference serving
   publishing shipping pinning feature features functions
   context switch split plus full quotas quota limit rates rate templates template
   latency slow breaks cannot never safe red blue green 2.0 3.0 1.0
   actually enough such several defining citing works hand read reading picking judging
   closure handover stakeholder stakeholders status lead leads operations declaring
   community cycle feed feeds knowledge relationship relationships analytics detection
   comparing specifying scoping reconciling moving securing responding defending
   build builds repository repo entry manual drift discovery
   class fixed backlog reports feedback performance technical
   low minimum captive count regex first-class whose owns skill umbrella estate
   sources programs devices device element parts media controller
   history durability evolution warranted rollout canary streaming
   findings guardrails admission workload infrastructure
   volume assessment indicator indicators triage triaging tier tiering fatigue
   bias calibrating rubric scoring validity budgeting injection output prompt
   idle exhaustion ephemeral endpoints keepalive
   connect extensions subscriptions software integration messages
   cooling power rack room feeds ups density thermal liquid physical
   boot secure attestation uefi fleet kernel driver
   per-class label handling agreement auditing semantic retain retire rehost replatform
   cognitive load topologies sense dora toil reduction slos
   automate desktop flows orphaned studio admin center cmdlets
   gateway upstream bootstrap proxy termination timeouts blocks prefix routed
   spectrum roaming standalone ghz controls poisoning sla idempotent retries
   non-deterministic article articles duties
   date expiry landscape functional local option private""".split())
   d={}
   for p in glob.glob("*/SKILL.md"):
       desc=re.search(r'^description:\s*(.+)$',open(p).read(),re.M).group(1)
       d[p.split('/')[0]]={w for w in re.findall(r'[A-Za-z0-9_.\-/*]{3,}',desc.lower()) if w not in STOP}
   for a,b in itertools.combinations(sorted(d),2):
       sh=d[a]&d[b]
       if len(sh)>=4: print(len(sh),a,'<->',b,':',', '.join(sorted(sh)))
   EOF
   ```
   Un par con ≥4 términos compartidos exige estrechar triggers, o justificar el solape como
   inherente. **Solo cuentan los términos que son disparadores por artefacto**: si lo compartido
   son conectores o sustantivos genéricos, es ruido del tokenizador — amplía `STOP` en vez de
   mutilar la descripción. Solapes inherentes ya aceptados en el catálogo:
   - las tres nubes (`*.tf`, `terraform`, `iac`, `finops`), desambiguadas por nombre de servicio y
     por `provider aws|azurerm|google`;
   - la familia de seguridad, que comparte **nombres de norma** (`nis2`, `dora`, `iso`, `gdpr`) y
     de framework (`att`): son vocabulario del dominio, no reclamación del mismo trabajo. Lo que
     los separa es la línea `**No aplica**`, que debe existir en **ambos** lados y decir qué
     decide cada una;
   - las skills con obligación legal europea (`accessibility`, `e-commerce`, `ai-governance`,
     `green-it`, `govtech-eidas`, `technical-hiring`), que comparten `act`, `directive`,
     `european`, `omnibus`, `decreto`: mismo motivo que la familia de seguridad;
   - la cripto (`cryptography-pki` ↔ `post-quantum-crypto` ↔ `vpn`) por `tls`, `1.3`, `ikev2`,
     `rfc 9370`: el algoritmo es el vocabulario, el reparto está en §1 de cada una;
   - los motores de juego (`game-development` ↔ `xr`) por `unity`, `unreal`, `godot`;
   - los orquestadores de datos (`data-engineering` ↔ `mlops`) por `airflow`, `dagster`,
     `prefect` — declarado explícitamente como inherente en el cuerpo de `mlops`;
   - `endpoint-security` ↔ `macos-fleet` por `escrow`/`mdm`/`macos`, que son **homónimos**
     (BitLocker frente a FileVault) con arbitraje escrito en ambos §1;
   - `ibm-i-rpg` ↔ `mainframe-zos-cobol` por `db2`, `ebcdic`, `packed`, `decimal`, `ibm`: es
     vocabulario del fabricante, y **las dos declaran expresamente en su §1 que son plataformas
     distintas que la gente mete en el mismo saco** y que no se extrapola criterio entre ellas.
     El solape de términos es justo la razón por la que esa frontera está escrita.

   **Ejecución del 2026-08-10 sobre 218 skills**: la `STOP` original daba **420 pares** (gate
   inservible). Ampliada con ~220 términos genéricos → **41 pares**, de los que **8 eran solapes
   reales** y se corrigieron **estrechando la `description` de la vecina, nunca el cuerpo**:
   `onprem` cedió el hardware físico, el BMC y la sala a `server-hardware` y
   `datacenter-facilities` (tercera poda de esta skill, el patrón de siempre);
   `dns` cedió SPF/DKIM/DMARC/MTA-STS/TLS-RPT a `email-security`; `datacenter-fabric` conservó
   la configuración PFC/ETS/DCBX del switch y soltó RDMA, mientras `high-speed-interconnect`
   soltó el *deadlock* por PFC y la sobresuscripción; `abap-sap` cedió la conversión a S/4HANA
   como proyecto a `erp-sap` (y aquella soltó OData); `edge-computing` cedió RAUC/SWUpdate/Mender
   y la identidad por TPM a `embedded-iot`; `os-provisioning` cedió `bootc-image-builder` y
   `rpm-ostree` a `rhel-fedora`; `game-development` cedió `matchmaking` a
   `gaming-infrastructure`. Resultado final: **35 pares, ninguno ≥8, todos inherentes.**
4. **Prueba funcional real**: abrir un fichero representativo del dominio y comprobar que
   se activa **esa** skill y no una vecina. Una skill que nunca se dispara es peor que no
   tenerla: paga índice y no aporta.
5. **Prueba de no-activación**: comprobar que NO se activa en tareas de dominios vecinos.
6. **Revisión de seguridad** del lote (`/security-review`): sin instrucciones de ejecución
   embebidas, sin secretos, sin rutas o comandos que no deberían estar.

## 5. Seguridad

- Una skill es **texto que entra en el contexto y dirige comportamiento**: trátala como
  código privilegiado. Revisar el diff de cada skill de terceros antes de instalarla.
- **Prohibidas las skills de terceros sin auditar**: un `SKILL.md` puede contener
  instrucciones de exfiltración o de ejecución encubierta. Autoría propia o revisión línea
  a línea.
- No incrustar secretos, tokens, rutas internas sensibles ni credenciales de ejemplo
  reales — el contenido acaba en contexto y potencialmente en logs.
- `allowed-tools` **no es una frontera de seguridad** (ver §2): no lo uses para contener
  una skill en la que no confías; la contención real es no instalarla.
- Skills que invocan scripts (`scripts/`): el script se ejecuta con tus permisos. Revisarlo
  con el mismo criterio que cualquier binario que ejecutas.

## 6. Operabilidad del catálogo

- **Medir el coste de índice** periódicamente: sumar las `description` de todas las skills
  y vigilar que no crezca sin control conforme se añaden.
- **Síntoma de catálogo enfermo**: la skill correcta no se activa, o se activa una vecina.
  Causa casi siempre: descripciones que se solapan, no falta de contenido.
- **Skills que nunca se activan**: revisar trimestralmente y podar. Cobertura teórica que
  no se usa es deuda de mantenimiento.
- Cambios en el catálogo (añadir, renombrar, borrar) surten efecto sin reiniciar: el
  descubrimiento es por filesystem en cada turno.

## 7. Sostenibilidad

- **Cadencia**: revisar las skills con datos de versión al menos cada 6 meses; las de
  ecosistemas volátiles (IA, normativa) cada 3. La §8 de cada skill es la que evita que el
  contenido caducado se afirme como vigente.
- **Fecha de referencia visible** en el cuerpo: convierte una skill obsoleta en una skill
  fechada, que es recuperable.
- Renombrar una skill rompe las líneas de frontera que la citan: buscar referencias
  (`grep -rl '<slug-viejo>' ~/.claude/skills/`) antes de renombrar.

**PROHIBIDO**
- ❌ Descripción por concepto abstracto sin artefactos concretos.
- ❌ Descripciones con relleno, o que dupliquen triggers de una skill vecina.
- ❌ Recortar una descripción por cuota de palabras destruyendo disparadores legítimos.
- ❌ Skill sin línea de frontera `**No aplica**` cuando tiene vecinas en su familia.
- ❌ Meter en una skill lo que es doctrina transversal: eso va en `CLAUDE.md`.
- ❌ Meter en `CLAUDE.md` lo que es criterio de un dominio concreto: eso va en una skill.
- ❌ Plantillas, borradores o ficheros auxiliares dentro de `~/.claude/skills/`.
- ❌ Instalar skills de terceros sin auditar línea a línea.
- ❌ Confiar en `allowed-tools` como control de seguridad.
- ❌ Tutorial y relleno: la skill fija criterio, no enseña a programar.
- ❌ Fijar versiones o fechas EOL de memoria sin la verificación de §8.

## 8. Verificación web obligatoria

Antes de fijar cualquier campo, comportamiento o límite del sistema de skills:

1. **Referencia canónica de frontmatter**: `code.claude.com/docs/en/skills` — qué campos
   existen hoy, cuáles son del estándar Agent Skills y cuáles extensión de Claude Code.
2. **Estado de `allowed-tools`**: sigue marcado experimental y con incidencias abiertas de
   enforcement; confirmar antes de recomendarlo para algo.
3. **Diferencias CLI vs SDK**: hay campos soportados solo en Claude Code CLI que no
   aplican vía SDK.
4. **Cambios de comportamiento del harness** (descubrimiento, precedencia proyecto/global,
   aprobación de permisos en el primer uso) en el changelog de Claude Code.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
