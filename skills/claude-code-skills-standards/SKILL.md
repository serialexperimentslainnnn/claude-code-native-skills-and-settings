---
name: claude-code-skills-standards
description: Use when authoring, reviewing or debugging Claude Code Agent Skills — SKILL.md files, frontmatter fields, description triggers, skill activation problems, catalog organization, or deciding whether something belongs in a skill, CLAUDE.md or a subagent.
---

# Claude Code skill authoring standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when creating, reviewing, debugging or reorganising skills: `SKILL.md` files, frontmatter,
`description` design, activation problems ("the skill doesn't fire" / "the wrong one
fires"), and the decision of where a rule lives.

**Not applicable**: `update-config` (harness configuration in `settings.json`, hooks and
permissions), `knowledge-management-standards` (documentation for humans: ADR, runbooks, README),
`ai-agent-workflow-standards` (how agents are used safely, not how their skills are
written).

## 2. Default decisions

> Verify the current specification on the web before pinning frontmatter fields (§8):
> the Agent Skills standard and the Claude Code extensions diverge and keep evolving.

| Decision | Default | Reason |
|---|---|---|
| Location | `~/.claude/skills/<slug>/SKILL.md` (global) or `.claude/skills/` (project) | Automatic filesystem discovery; the project one wins on a name collision |
| Frontmatter fields | Only `name` + `description` | They are the only indispensable ones; everything else adds surface and, in some cases, permission friction |
| `allowed-tools` | **Do not use without demonstrated need** | Marked experimental in the standard; there is an open report that it is parsed but **not enforced**, and its presence requires user approval on first use. Do not rely on it as a security control |
| `disable-model-invocation` | Only in skills that must be exclusively manual (`/name`) | A skill that never self-activates pays index cost without giving any automatic benefit |
| Language | `description` in **English**, body in the working language | Routing is done over the description; English is the language of technical triggers |
| Body length | **Dictated by the content, not by a quota** | The body is not loaded until activation: going long costs no index. The real limit is **density** — every line pins a decision, a prohibition or a verification. A dense domain can ask for 400+ lines; a niche one, 80 |
| Auxiliary files | `references/`, `scripts/` next to the `SKILL.md` when the content doesn't fit | They are loaded on demand from the body, not in the index |

**Golden rule of the catalogue**: the `description` is paid on **every turn**; the body only
when the skill activates. Optimise the description for routing, the body for use.

## 3. Structure and conventions

- **Directory = slug = `name`**. Suffix `-standards` for domain-criteria skills.
- Do not put templates or reference files inside `~/.claude/skills/`: any
  directory with a `SKILL.md` gets registered and pollutes the index. Outside the tree.
- Body with the 8 canonical sections (see `~/.claude/SKILL-TEMPLATE.md`).
- **Explicit boundary in §1** (`**Not applicable**: see `knowledge-management-standards` (clean boundary, easy to confuse:
**documentation for humans is theirs** —Diátaxis, docs as code, README, runbook, onboarding
guide, owner and review date—; **skill authoring here**, which are instructions for
a model with an index cost and an activation criterion of their own. A skill is not documentation
and is not written as such: it does not explain, it decides), X, Y`) on **both sides** of every pair
  that could compete. Without this, two neighbouring skills tread on each other and routing becomes chance.
- Reference date on the first line of the body.

### `description` design (the most important part of the file)

- **No hard word limit.** The rule is *zero filler, zero overlap with siblings*:
  a long description is justified if every term is a distinct trigger (service
  names of a cloud, for instance); a short but conceptual one is worse than a long and
  concrete one. Trimming to a quota destroys legitimate triggers.
- Start with `Use when …` and enumerate **concrete artifacts**: extensions (`.tf`, `.rs`),
  files (`pyproject.toml`, `Chart.yaml`), binaries (`nft`, `cosign`), frameworks.
- **Forbidden** to describe by abstract concept: `for best practices and quality` fires
  nothing because it matches no token of a real task.
- **Mandatory collision test**: before adding a skill, compare its description with
  those of its family. If they share more than 2-3 trigger terms, either the
  triggers get narrowed or the skills get merged.

## 4. Quality and verification

Gates before calling a skill good:

1. **Valid frontmatter**: `grep -c '^name:'` and `name` == directory name.
2. **Description without filler**: there is no word quota (§3) — the gate is that **every term
   is a trigger**. If a description is long because it enumerates services or extensions,
   that's fine; if it is long because of conceptual prose, that prose gets trimmed, never the triggers.
3. **Declared boundary**: the `**Not applicable**` line exists and every skill it cites exists.
   Mechanical catalogue test — trigger-term overlap between pairs of the same family:
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
