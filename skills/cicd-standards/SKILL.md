---
name: cicd-standards
description: CI/CD standards for GitHub Actions and GitLab CI. Use when creating or reviewing pipelines, workflows, .github/workflows/*.yml, .gitlab-ci.yml, runners, deploy/release automation, OIDC cloud auth, SBOM/signing (cosign, SLSA), or CI security gates.
---

# Estándares CI/CD — GitHub Actions y GitLab CI

Criterios verificados contra el estado del ecosistema en **agosto de 2026**. Ante cualquier dato
concreto (versión de action, flag, claim OIDC), **verifica en la web antes de fijarlo** (sección 8).

## 1. Alcance y triggers

Aplica al crear, modificar o revisar:
- `.github/workflows/*.yml`, actions compuestas/reutilizables, `dependabot.yml`, rulesets.
- `.gitlab-ci.yml`, templates/`include`, GitLab Runners.
- Cualquier pipeline de build, test, release o deploy; scripts invocados desde CI.
- Configuración de runners (self-hosted o gestionados) y su endurecimiento.
- **Cadena de suministro del artefacto**: SBOM, firma (cosign/Sigstore), procedencia SLSA y su
  verificación antes de desplegar. No hay skill aparte de supply chain: vive aquí.

**No aplica**: ver `git-workflow-standards` (estrategia de rama, Conventional Commits, tamaño de PR,
CODEOWNERS, protección de rama, SemVer y CHANGELOG: esta skill asume el repo ya gobernado por
aquella y arranca donde el evento dispara el pipeline), `iac-standards` (cómo se escribe el código
Terraform/Ansible que el pipeline aplica), `kubernetes-standards` (el `Dockerfile`, el manifiesto y
la política de admisión que verifica la firma en el destino), `aws-standards`/`azure-standards`/
`gcp-standards` (qué rol/identidad federada existe al otro lado del OIDC y qué permisos lleva),
`appsec-standards` (metodología y triaje de los hallazgos que producen los gates SAST/DAST/SCA;
aquí solo su **ejecución** y umbral de rotura), `vulnerability-management-standards` (SLA de
remediación y VEX de esos hallazgos), `cryptography-pki-standards` (elección de algoritmos, custodia
y rotación de las claves de firma; aquí solo su uso desde el pipeline),
`identity-access-management-standards` (diseño del IdP; aquí la identidad efímera del job),
`sre-practice-standards` (estrategia de despliegue desde la óptica de fiabilidad: canary, error
budget, rollback como decisión operativa), `bash-linux-scripting-standards` y `powershell-standards` (los scripts que el
pipeline invoca; el segundo, además, en runners Windows y en el paso `pwsh`),
`groovy-standards` (**frontera crítica con Jenkins, espejada desde su §1**: **la estrategia de
pipeline, los gates, la firma, el SBOM, OIDC y la seguridad del runner se deciden aquí**; **cómo se
escribe el `Jenkinsfile` como código Groovy** —declarativo frente a *scripted*, CPS y `@NonCPS`,
Shared Libraries, el sandbox de Script Security y la aprobación de scripts— **es suyo**. La regla
que no se negocia por ninguna de las dos partes: **PROHIBIDO desactivar el sandbox**), `observability-standards` (métricas DORA y telemetría del propio pipeline), `opensource-licensing-standards` (**Ola 6**: **la pipeline ejecuta el gate de licencias** —el
runner, el job, la caché y la firma del artefacto son de aquí—; **el umbral, la lista de licencias
permitidas, el proceso de excepción y qué rompe el build son suyos**. Y el SBOM que esta skill ya
genera para firma y procedencia **tiene un segundo consumidor**: las obligaciones de licencia),
`platform-engineering-standards` (**Ola 6**: **el diseño de la pipeline concreta, sus gates y su
seguridad son de aquí**; **que exista una plantilla de pipeline en el camino pavimentado, quién la
mantiene y cómo se deprecia, es suyo**), `finops-standards` (**Ola 6**: el coste del propio CI
—minutos de runner, cachés, artefactos— es una unidad económica más y se mide con su método),
`developer-workstation-standards` (**Ola 6** — **la paridad entre lo que corre en local y lo que
corre aquí**: la misma versión de runtime, el mismo formateador y el mismo linter, fijados en el
repositorio y no en la máquina. **Si el gate solo falla en CI, el problema es de aprovisionamiento
del puesto, no de la pipeline**), `ai-agent-workflow-standards` (**Ola 6**: **el agente que corre
en un job es una identidad más y se le acota el token y el alcance aquí**; qué tarea se le delega y
cómo se revisa su cambio, allí), `testing-qa-standards` (**Ola 6**: **la pipeline y el umbral que rompe el build son de aquí**;
**qué se prueba, en qué proporción y con qué criterio de calidad, allí**), `code-review-standards`
(**Ola 6**: lo que comprueba una máquina antes del merge es de aquí; **lo que revisa una persona y
con qué criterio, allí** — y la regla que ambas comparten: **si se discute formato en una revisión,
falta un formateador en esta pipeline**), `accessibility-standards` y `web-performance-standards`
(**Ola 6**: el gate se ejecuta aquí; **el criterio de conformidad y el umbral los fijan ellas**),
`solidity-standards`
(**Ola 5**: la pipeline y sus gates genéricos son de aquí; **el gate específico de despliegue de un
contrato es suyo y es más duro que el de cualquier otro artefacto** — no se despliega sin tests
invariantes, sin auditoría externa y sin plan de incidente en cadena escrito **antes**, porque no
existe el rollback).

## 2. Decisiones por defecto

> Nota: cada versión/feature citada aquí caduca. Verificado ago-2026; re-verificar en la web
> antes de codificarlo en un pipeline nuevo (sección 8).

| Decisión | Por defecto | Prohibido |
|---|---|---|
| Autenticación a cloud | **OIDC/workload identity federation** (GH: `id-token: write`; GitLab: `id_tokens`) | Credenciales estáticas (`AWS_ACCESS_KEY_ID`, SA keys JSON) en variables/secrets |
| Referencias a actions | **Pin por SHA completo de commit** + comentario con la versión; Dependabot/Renovate para actualizarlas | `@main`, `@master`, tags mutables sin política de SHA pinning |
| Artefactos GH | `actions/upload-artifact`/`download-artifact` **v4+** (v6/v7 con runtime Node 24; v3 falla desde 2025-01-30) | v3 o anteriores |
| Runtime de actions | **Node 24** (Node 20 eliminado de runners el 2026-09-16) | Actions ancladas a Node 16/20 sin plan de migración |
| Firma de artefactos | **cosign v3.x** (bundle Sigstore por defecto, `--bundle` obligatorio; instalar con `cosign-installer` **v4**) | cosign v2 en pipelines nuevos; firmas sin verificación posterior |
| Provenance | **SLSA Build L3**: GH Artifact Attestations (`actions/attest-build-provenance`) desde **reusable workflow**; verificación con `gh attestation verify` o `slsa-verifier`. **La atestación es necesaria pero ya NO es suficiente** (ver aviso abajo) | Publicar sin attestation; "generar y no verificar"; **tratar una atestación válida como prueba de que el artefacto es benigno** |
| SBOM | **Syft** (CycloneDX 1.6 JSON o SPDX 3.0.1) + **Grype** para matching de CVEs | SBOM decorativo no archivado ni escaneado |

> ⚠️ **La procedencia firmada ya no prueba que el artefacto sea benigno** (verificado ago-2026).
> **Mini Shai-Hulud (CVE-2026-45321)**, activo desde finales de abr-2026, extrae tokens OIDC de la
> **memoria del runner** de GitHub Actions y **emite atestaciones SLSA L3 válidas para paquetes
> maliciosos**: si el runner está comprometido, la firma certifica una construcción que sí ocurrió
> ahí, y eso es exactamente lo que el atacante quería. Precedentes del mismo patrón: **CanisterWorm**,
> el compromiso de **Trivy** (mar-2026), el backdoor de **LiteLLM** en PyPI y `elementary-data`
> (abr-2026), los tres con persistencia vía `.pth` o vía CI sin *pin*.
> **Consecuencia operativa**: la atestación sigue siendo obligatoria —demuestra *dónde* se construyó—
> pero el control que de verdad corta esta clase es **fijar por SHA/digest todo lo que entra al
> runner**, minimizar lo que el runner puede alcanzar, y **poder rotar cualquier credencial de CI en
> cualquier momento**. No la trates como el último eslabón de la cadena de confianza.
| GitLab OIDC | `id_tokens` con `aud` explícito; trust policy por **`project_id`/`namespace_id`** (claims estables, gitlab.com) además de `sub` | `CI_JOB_JWT*` (eliminados en GitLab 17.0); trust policies solo por path (vulnerables a rename) |
| OIDC subject GH | Repos nuevos (post 2026-07-15) emiten **sub inmutable** `repo:org@id/repo@id`; para repos existentes, opt-in tras actualizar trust policies | Trust policies con wildcard amplio (`repo:org/*`) o sin filtro de branch/environment |
| Permisos workflow | `permissions:` top-level **read-only** (`contents: read`); elevar solo por job | `permissions: write-all` o permisos por defecto sin declarar |

Precaución activa (ago-2026): hay reportes de compromisos de supply chain en **Trivy**; antes de
usarlo como gate, verifica su estado actual. Syft+Grype es la alternativa por defecto.

## 3. Estructura y convenciones

- **Pipelines como código**, versionados y revisados por PR/MR con **CODEOWNERS sobre
  `.github/workflows/` / `.gitlab-ci.yml`** — un workflow es código privilegiado.
- Un workflow = un propósito (ci / release / deploy). Lógica compleja fuera del YAML: scripts
  versionados (`ci/` o `scripts/`) invocados desde steps, testeables en local.
- Reutilización: GH **reusable workflows** (que además habilitan SLSA L3) y composite actions
  propias; GitLab `include:` de templates centralizados con ref fijada (tag/SHA, no branch).
- **`concurrency`** con `cancel-in-progress` en CI de PRs; nunca en jobs de deploy (usa cola).
- `timeout-minutes` explícito en todo job. Sin timeout no hay presupuesto de fallo.
- Config fuera del artefacto: mismo binario/imagen para todos los entornos, configuración por
  entorno inyectada en deploy (env vars/config store), jamás horneada en build.
- Nombres de jobs/steps descriptivos y estables (los gates de branch protection referencian por
  nombre; renombrar un job rompe el gate en silencio).

## 4. Gates de calidad obligatorios

Todos bloquean el merge (required checks / `allow_failure: false`). Main siempre verde.

1. **Formato** (formatter en modo check) y **lint**.
2. **Type-check** estricto cuando el lenguaje lo permita.
3. **Tests** unitarios + integración, deterministas; un test flaky se arregla o se borra.
4. **SAST** (CodeQL / GitLab SAST / Semgrep).
5. **SCA** de dependencias (Dependabot/Renovate + Grype u OSV-Scanner) — rompe build en crítico/alto explotable.
6. **Secret scanning** (GH secret scanning + push protection / Gitleaks) — hallazgo = build roto + rotación del secreto, no solo borrado del commit.
7. **Escaneo de IaC** (Checkov/KICS/tfsec) y de **imágenes** (Grype) antes de push a registry.
8. **Policy as code** cuando haya cluster: verificación de firma+provenance en admisión (Sigstore Policy Controller / Kyverno).

Severidad de corte definida por escrito (p. ej. CRITICAL+HIGH con fix disponible rompen; el resto,
issue con SLA). Excepciones solo vía allowlist versionada con motivo y caducidad.

## 5. Seguridad

**Cadena de suministro**
- Build once: el artefacto se construye **una vez**, se identifica por **digest** (no tag) y se
  **promociona** el mismo digest dev→staging→prod. Rebuild por entorno = artefactos distintos = prohibido.
- Cada release: **SBOM archivado + firma cosign keyless (OIDC) + SLSA provenance**; el deploy
  **verifica** firma y procedencia (builder esperado, repo, ref) antes de ejecutar.
- **Releases inmutables** de GitHub activadas (tag y assets no modificables, release attestations).
- Imágenes base y dependencias **pinadas por digest**; lockfiles committeados y verificados en CI
  (`npm ci`, `--frozen-lockfile`, `pip install --require-hashes`…).
- Política de organización GH: **SHA pinning enforcement** y allowlist/bloqueo de actions
  (disponible desde ago-2025); en GitLab, allowlist de imágenes de job por registry propio.

**Runners endurecidos**
- Preferencia: runners **efímeros** (GH-hosted, o self-hosted autoscalados de un solo uso).
  Self-hosted persistentes solo para necesidades justificadas, **jamás** para repos públicos.
- En GH-hosted: **Harden-Runner** (StepSecurity) con política de egress en workflows sensibles;
  filtrado de salida = control anti-exfiltración, no opcional en jobs con secretos.
- Self-hosted: aislados por grupo/etiqueta y por nivel de confianza, non-root, sin credenciales
  de larga vida en disco, mínimo IAM del host, parcheados con cadencia (sección 7).
- Cache: consciente del **cache poisoning** — no compartas cache entre triggers no confiables
  (GH ya emite tokens de cache read-only para triggers sin permiso de escritura desde jun-2026);
  nunca cachees directorios que contengan secretos.

**Secretos y privilegio**
- Cero secretos estáticos hacia clouds: OIDC con trust policies estrechas (repo+ref/environment;
  claims inmutables/estables donde existan). Secretos residuales: gestor central (Vault/KMS),
  cortos y rotados, scoping por **environment** con required reviewers para prod.
- `pull_request_target`, `workflow_run` y triggers sobre código de forks: sin acceso a secretos
  ni checkout del código del fork con permisos elevados. Revisión explícita en el diff de
  cualquier cambio en estos triggers.
- Ningún secreto en logs (masking no es garantía: no hagas `echo`/`env` de bloques completos).

## 6. Operabilidad

- **Despliegue seguro por defecto**: canary o blue/green con health checks automáticos sobre
  métricas (error rate, latencia) y **rollback automatizado y probado** — un rollback que nunca
  se ha ejecutado no existe. Rolling solo para servicios stateless de bajo riesgo.
- **Feature flags** para desacoplar deploy de release; el deploy de código oscuro es la vía
  normal de integrar trabajo grande.
- **Migraciones expand/contract**: toda migración de datos compatible hacia atrás; el código N
  y N-1 conviven con el mismo esquema. `expand` (deploy) → migrar datos → `contract` (release
  posterior). Nunca migración destructiva en el mismo deploy que el código que la requiere.
- Pipeline observable: duración y tasa de fallo por job como métricas; deploy events anotados
  en Grafana/APM; logs de CI retenidos y correlacionables con releases (digest+commit+run id).
- **Runbook por pipeline de deploy**: cómo pausar, cómo hacer rollback, a quién avisar. Enlazado
  desde el propio workflow (comentario/summary).
- Entornos GitLab (`environment:`) / GH Environments declarados: dan trazabilidad de qué digest
  corre dónde y aplican protecciones (reviewers, wait timers) en prod.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Semanal: Dependabot/Renovate para actions, imágenes base y dependencias (con
  `enable-beta-ecosystems` si hace falta para pins por SHA en GH).
- Mensual: revisión de deprecations de plataforma (changelog GH Actions / release notes GitLab)
  — el ritmo 2025-2026 (artifacts v3, Node 20, cache v2, JWT GitLab) demuestra que "no tocar" rompe solo.
- Por release de plataforma: GitLab self-managed a la última minor soportada; runners self-hosted
  actualizados en ventana fija.

**PROHIBIDO**
- Deploy con CI roja o saltándose gates (`--no-verify`, skip de checks, merge admin sin gate).
- Credenciales estáticas de cloud en CI (access keys, SA JSON, tokens de larga vida).
- Actions/templates referenciados por branch o tag mutable sin política de pinning.
- Rebuild por entorno; promocionar por tag mutable; `latest` en prod.
- Secretos en claro en YAML, logs, artefactos o cache; secretos accesibles a triggers de forks.
- Runners self-hosted persistentes para repos públicos o PRs de terceros.
- Cambios manuales en lo que el pipeline gestiona (snowflake deploys, hotfix por SSH).
- Migraciones destructivas acopladas al deploy del código; deploy sin rollback definido.
- Tests flaky reintentados como norma (`retry` para tapar inestabilidad).
- Desactivar un gate "temporalmente" sin issue, motivo y fecha de caducidad.

## 8. Verificación web obligatoria

Antes de fijar en un pipeline cualquier dato concreto, **búscalo — no lo recuerdes**:
- Versiones/SHAs de actions y major vigente (`actions/checkout`, `upload-artifact`, `cache`,
  `cosign-installer`): releases en GitHub + changelog `github.blog/changelog`.
- Formato vigente de claims OIDC (GH sub inmutable en rollout desde jul-2026; GitLab
  `project_id`/`namespace_id`) antes de escribir una trust policy.
- Estado de seguridad de cada herramienta de terceros que metas en el pipeline (¿compromisos
  recientes? caso Trivy 2026) y deprecations activas de GH/GitLab.
- Versiones estables de cosign, Syft, Grype, slsa-verifier y sintaxis actual de sus flags
  (cosign v3 cambió flags de verificación respecto a v2).

Si no puedes verificar, dilo explícitamente en vez de suponer.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
