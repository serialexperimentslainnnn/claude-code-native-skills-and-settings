# Plan — Catálogo exhaustivo de skills IT

## Contexto

Hoy existen **17 skills** en `~/.claude/skills/` (`<dominio>-standards/SKILL.md`), creadas con arquitectura de dos capas: el `CLAUDE.md` global fija principios transversales y las skills aportan criterio profundo por dominio, cargándose solo cuando la tarea las dispara.

El objetivo es **cobertura total del mundo IT**, de lo más legacy a lo más moderno, sin filtro por nicho. Tres agentes de diseño (seguridad/redes/infra, lenguajes/plataformas, datos/IA/verticales) han propuesto ~380 skills que, tras deduplicar el solape entre ellos, quedan en **~250 skills nuevas** (~267 totales).

Los tres agentes coincidieron de forma independiente en un diagnóstico incómodo: **el catálogo actual tiene agujeros en el núcleo profesional del usuario**. No existe ni una skill de seguridad, redes, observabilidad, SRE, bash o diseño de APIs — pese a que el `CLAUDE.md` tiene doctrina extensa de todas ellas. Se cubrieron 8 lenguajes y 3 clouds antes que el trabajo diario.

## Restricción real de diseño

El coste de contexto **no** es el limitante (250 descripciones ≈ 20k tokens/turno, asumible). El limitante es la **colisión de triggers**: con 250 skills, varias competirán por "servidor Linux" o "seguridad" y la selección degradará. Mitigaciones obligatorias:

1. **Descripciones de 25-40 palabras** (varias actuales pasan de 60) y disparadores por **artefacto concreto**, no por concepto: `CIS/OpenSCAP/auditd` → hardening; `systemd/journalctl/fstab` → administración; `dnf5/rpm-ostree/bootc` → familia RHEL.
2. **Frontera explícita en §1 de cada skill**: línea `**No aplica**: ver skill X / Y`. Hoy solo `iac-standards` lo hace; es el patrón a replicar.
3. **Fecha de referencia** en la primera línea del cuerpo de todas (ya la usan `cicd`, `onprem`, `python`, `typescript`).

## Fase 0 — Prerrequisitos (bloqueante, antes de escribir ninguna skill nueva)

1. **Congelar plantilla** en `~/.claude/skills/_template/SKILL.md`. Hoy hay deriva: unas usan "Toolchain por defecto", otras "Decisiones por defecto", `aws`/`azure`/`gcp` numeran hasta 9 secciones. Referencias: `onprem-standards` (la más completa), `microservices-architecture-standards` (plantilla para dominios de criterio sin toolchain), `python-standards` (plantilla con toolchain y versiones).
2. **Formato corto (80-120 líneas)** para skills de nicho y legacy: en `mainframe-zos` o `x25` la sección "gates de CI" es artificial.
3. **Refactor de `onprem-standards`** → skill paraguas. Hoy colisiona con ~12 skills nuevas (hardening, virtualización, ZFS, backups, DR, red, monitorización, HA). Mantiene los principios ("sin telemetría no hay producción", "backup sin restore probado no existe", "HA sin fencing es corrupción diferida") y delega a las profundas.
4. **Ajustes menores de frontera**: `kubernetes-standards` cede runtime security y CNI; `cicd-standards` absorbe supply chain (no crear skill aparte); `data-platform-standards` delimita con las de bases de datos nuevas.
5. **Escribir `claude-code-skills-standards` primero** y usarlo como lint del resto: es el meta-skill que gobierna la calidad de las 250 siguientes.

## Taxonomía consolidada

| Familia | Skills | Ejemplos representativos |
|---|---|---|
| Ciberseguridad | ~35 | appsec, offensive-security (alcance autorizado), detection-engineering, incident-response-forensics, IAM, cryptography-pki, secrets-management, vulnerability-management, grc-compliance, privacy-engineering, hardening, SELinux, container/cloud security, OT/ICS, threat-intel, post-quantum |
| Redes | ~30 | networking (troncal), routing-switching, firewall-policy, DNS, VPN/zero-trust, wireless, load-balancing, network-automation, vendors (Cisco/Juniper/Arista/MikroTik), datacenter fabric (VXLAN/EVPN), telco/5G, WAN legacy |
| Sistemas e infraestructura | ~45 | linux-administration, rhel-fedora, windows-server-ad, macos-fleet, unix legacy (AIX/Solaris/HP-UX/BSD), web/app/mail/file servers, proxmox, libvirt-kvm, vmware, hyper-v, xen, zfs, ceph, linux-storage, object-storage, backup-recovery, bcdr, HA-clustering, os-provisioning, cmdb/netbox, server-hardware, datacenter-facilities, hpc, gpu-infra, edge, podman-systemd, homelab, air-gapped, migration |
| Observabilidad y SRE | ~7 | observability, opentelemetry, sre-practice, incident-management, chaos-engineering, performance-load-testing, technical-documentation |
| Lenguajes modernos | ~30 | c, cpp, bash-scripting, powershell, sql, ruby, elixir-erlang, scala, clojure, haskell-fp, ocaml-fsharp, zig, nim, crystal, lua, r, julia, dart, perl, groovy, objective-c, assembly, webassembly, solidity |
| Lenguajes y plataformas legacy | ~20 | mainframe-zos-cobol, ibm-i-rpg, fortran, pascal-delphi, vb6, vbnet, dotnet-framework-legacy, abap-sap, plsql-oracle-forms, coldfusion, classic-asp, jsp-struts, actionscript, ada, smalltalk, lisp, prolog, mumps, legacy-modernization |
| Frontend y web | ~8 | frontend-web-platform, accessibility-wcag, web-performance, vue/svelte/angular/solid/qwik/astro, PWA, WebGL-WebGPU, design-systems, CMS-jamstack |
| Desarrollo especializado | ~12 | game-development, embedded-iot, home-automation, kernel-drivers, compilers-dsl, operating-systems, robotics-ros, xr, cross-platform-desktop, rpa-workflow-automation |
| Datos | ~20 | data-engineering, lakehouse, data-warehouse-modeling, data-governance-quality, analytics-bi, nosql, graph-db, vector-db, timeseries-db, search-engines, streaming-cdc, message-brokers, oracle-dba, sqlserver-dba, mysql-mariadb-dba, caching-cdn |
| IA y ML | ~15 | llm-app-engineering, rag, ai-agents, mcp, llm-evaluation, mlsecops, local-inference, gpu-computing, mlops, classical-ml, deep-learning, computer-vision, nlp, multimodal-genai, model-finetuning, ai-governance |
| Verticales y nichos | ~20 | erp-sap, crm-salesforce, lowcode-governance, e-commerce, fintech-payments, healthtech-fhir, govtech-eidas, blockchain-web3, quantum-computing, telecom, industrial-ot, safety-critical, gis-geoespacial, streaming-multimedia, gaming-infrastructure |
| Gestión y proceso | ~12 | finops, platform-engineering, itsm-itil, opensource-licensing, green-it, tech-leadership, technical-hiring, project-management, enterprise-architecture, knowledge-management, product-discovery |
| Craft de ingeniería | ~10 | git-workflow, api-design, testing-qa, performance-engineering, code-review, software-architecture-patterns, refactoring-tech-debt, i18n, developer-workstation, ai-agent-workflow |

## Olas de implementación

**Ola 0 — Cerrar los agujeros del núcleo (13).** Nada más hasta terminar esta.
`appsec` · `networking` · `observability` · `sre-practice` · `bash-linux-scripting` · `identity-access-management` · `cryptography-pki` · `vulnerability-management` · `grc-compliance` · `api-design` · `git-workflow` · `homelab` · `claude-code-skills` (meta-skill, primero)

**Ola 1 — Seguridad avanzada y operación (12).**
`offensive-security` + `ctf-lab` (juntas, comparten cláusula de alcance autorizado) · `detection-engineering` · `incident-response-forensics` + `incident-management` (juntas, para escribir la frontera de una vez) · `secrets-management` · `privacy-engineering` · `linux-hardening` · `selinux` · `container-runtime-security` · `windows-server-ad` · `bcdr`

**Ola 2 — Infra y plataforma (14).** `linux-administration`, `rhel-fedora`, `zfs`, `backup-recovery`, `proxmox-ve`, `libvirt-kvm`, `podman-systemd-containers`, `linux-storage`, `object-storage`, `ha-clustering`, `dns`, `firewall-policy`, `vpn`, `network-troubleshooting`

**Ola 3 — IA (10).** `llm-app-engineering`, `rag`, `ai-agents`, `mcp`, `llm-evaluation`, `mlsecops`, `local-inference`, `gpu-computing`, `mlops`, `ai-governance`

**Ola 4 — Datos (16).** El bloque de datos completo.

**Ola 5 — Lenguajes modernos (30).** Por lotes de afinidad (sistemas/BEAM/funcionales/científicos).

**Ola 6 — Craft, frontend, gestión (25).**

**Ola 7 — Legacy y verticales (~120).** Formato corto, por lotes temáticos (todo el Unix legacy junto, todo el WAN legacy junto): comparten estructura y fuentes de verificación.

## Método de escritura (idéntico al de las 17 actuales)

- Subagentes en paralelo, 2 skills por agente, con **verificación web obligatoria** del estado real antes de fijar cualquier versión, EOL o nombre de herramienta. Este método ya corrigió errores míos de memoria (Spring Boot 3.x EOL, JUnit 6 en vez de 5, bulo de "tokio 2.0").
- Frontmatter: `name` slug + `description` en inglés de una línea con triggers concretos.
- Cuerpo en español, 8 secciones fijas (o formato corto en nicho/legacy), con lista de prohibiciones y §8 de verificación web.
- Las skills ofensivas fijan en §1 la precondición de **alcance y autorización por escrito**, y en §7 prohíben explícitamente incluir payloads listos, bypasses concretos de producto o credenciales por defecto de terceros: metodología y gobernanza, no recetario.

## Verificación

1. `ls -d ~/.claude/skills/*/` y `grep -c '^name:' ~/.claude/skills/*/SKILL.md` — todas con frontmatter válido.
2. Medir el listado inyectado: `awk` sobre las `description` para confirmar que ninguna pasa de 40 palabras y que el total se mantiene bajo control.
3. **Test de colisión**: para cada par de skills de la misma familia, comprobar que las descripciones no comparten más de N términos disparadores; la línea `No aplica` de §1 debe existir en ambos lados.
4. `/security-review` sobre cada lote nuevo, como se hizo con las 17.
5. Prueba funcional real: abrir un fichero de cada dominio y confirmar que se activa la skill correcta y solo esa.
