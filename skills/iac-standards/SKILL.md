---
name: iac-standards
description: Infrastructure as Code standards (staff/principal level). Use when writing or reviewing Terraform/OpenTofu code (*.tf, *.tfvars, *.tofu, modules, backend/state config, providers), Ansible content (playbooks, roles, inventories, ansible.cfg, molecule scenarios), IaC scanning configs (trivy, checkov), policy as code for infra (OPA/Conftest, Sentinel), or IaC CI/CD pipelines (plan/apply, drift detection).
---

# Estándares IaC (Terraform/OpenTofu y Ansible)

## 1. Alcance y triggers

Aplica al crear o revisar: `*.tf`, `*.tofu`, `*.tfvars`, módulos y root modules, configuración de backend/state, playbooks y roles Ansible (`*.yml` con tasks/hosts), inventarios, escenarios Molecule, pipelines de plan/apply, políticas de infra (Conftest/OPA) y configuración de escáneres (trivy, checkov). No aplica a manifiestos K8s/Helm (ver skill `kubernetes-standards`); el solape (providers `kubernetes`/`helm` en TF) se decide aquí: **cluster y plataforma con TF/Tofu; workloads vía GitOps**, no con `helm_release` desde Terraform.

**No aplica** (resto de fronteras): ver `aws-standards`/`azure-standards`/`gcp-standards` (**qué** servicio elegir y con qué configuración segura; aquí el **cómo** se escribe, versiona y aplica el código que lo crea — Bicep/ARM y CloudFormation/CDK viven en la skill de su nube), `cicd-standards` (el pipeline que ejecuta `plan`/`apply`, su OIDC y sus gates; aquí qué debe comprobar ese pipeline sobre el código IaC), `ruby-standards` (**Chef y Puppet están escritos en Ruby y esa cercanía confunde**: el **DSL de infraestructura** —recursos, idempotencia, convergencia, inventario— se decide aquí; el **Ruby que se escribe** —estilo, gems, tests, `rubocop`— es suyo), `bash-linux-scripting-standards` y `powershell-standards` (scripts sueltos: si Ansible puede hacerlo de forma idempotente, no se escribe un script — y si el objetivo es Windows, el script que Ansible o el `provisioner` invoque se escribe con el criterio de `powershell-standards`; **DSC y la configuración declarativa de Windows se deciden aquí**), `onprem-standards` (el servidor y el SO que Ansible configura, y su hardening), `kubernetes-standards`, `grc-compliance-standards` (marco normativo y evidencia; aquí las políticas OPA/Conftest que lo hacen verificable), `vulnerability-management-standards` (triaje de los hallazgos que produzca checkov/OSV-Scanner), `git-workflow-standards` (rama, PR y revisión del repo de IaC), `cmdb-inventory-standards` (**el `.tfstate` no es una CMDB**: describe lo que este código creó, no el activo ni su ciclo de vida — el modelo, el identificador estable, el descubrimiento y la reconciliación son suyos, y el inventario **lee** el state, no se sustituye por él), `os-provisioning-standards` (**la frontera del aprovisionamiento es el primer arranque**: PXE/HTTP Boot, instalador desatendido, `cloud-init` de primer arranque y alta del host son suyos; a partir de que la máquina existe y responde, el `apply` es de aquí), `identity-access-management-standards` (credenciales y federación de la identidad que ejecuta el `apply`), `finops-standards` (**la política de etiquetas —qué etiquetas, con qué valores permitidos y para qué unidad de asignación— es suya**; **el gate que la impone en el código y en la admisión es de aquí**. Una política de etiquetado sin este gate no existe), `platform-engineering-standards` (**el módulo de Terraform/OpenTofu y su calidad son de aquí**; **la abstracción que se ofrece encima al equipo de producto —camino pavimentado, plantilla, Crossplane o composición— y qué se le oculta, es suya**).

## 2. Toolchain por defecto

> **Verificación web obligatoria**: comprobado en **agosto 2026**. Re-verifica versiones y estado de licencias con WebSearch antes de fijar nada en un proyecto real.

| Herramienta | Línea estable (2026-08) | Criterio |
|---|---|---|
| **OpenTofu** | **1.12.x** (MPL 2.0, Linux Foundation/CNCF) | **Default para proyectos nuevos**: licencia OSI, state encryption nativo, provider `for_each`, registry OCI; mismos providers que TF |
| Terraform | 1.15.x (BSL 1.1, IBM/HashiCorp) | Válido si ya hay inversión en HCP/Terraform Enterprise o Stacks; la BSL exige revisión legal si compites con HashiCorp |
| ansible-core | **2.21.x** (Python ≥3.12); paquete community 14.x | Solo la última major del paquete community recibe mantenimiento garantizado |
| **checkov** (IaC misconfig) + **OSV-Scanner**/**Grype** (dependencias) + escáner de secretos — **verifica cuál antes de fijarlo: a ago-2026 `gitleaks` se declaró *feature complete* (solo parches de seguridad) y su README apunta a Betterleaks; además `gitleaks-action` dejó MIT en v2.0.0 y exige licencia comercial para organizaciones. El criterio lo fija `secrets-management-standards`** | última estable | Default tras el **compromiso de cadena de suministro de Trivy (marzo 2026)**: tag poisoning de `trivy-action`/`setup-trivy`, binarios e imágenes maliciosos y robo de secretos de CI. Trivy sigue siendo técnicamente bueno: si lo usas, **pin por SHA de commit** (actions) y **digest** (imágenes), verifica firma/checksum y sigue sus advisories |
| terraform-docs, tflint, ansible-lint, Molecule | última estable | Obligatorios en CI |
| Infracost | última estable | Coste visible en PR (FinOps shift-left) |

- **Estado del fork (verificado 2026-08)**: state binario compatible en ambos sentidos **salvo** si activas state encryption de OpenTofu (decisión de ida única). Adopción OpenTofu ~12% y creciendo (Fidelity migró >50k state files); Terraform mantiene la mayor cuota. Elige **un** motor por organización y documenta la decisión en un ADR; no mezcles motores sobre el mismo state.
- Fija versión de motor con `required_version` (rango pesimista `~>`) y providers con `required_providers` + lockfile (`.terraform.lock.hcl`) commiteado.

## 3. Estructura y convenciones

### Terraform/OpenTofu
- **Módulos**: estructura estándar (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md` generado con terraform-docs, `examples/`, `tests/`). Un módulo = una responsabilidad componible; ni "módulo dios" ni wrappers de un solo recurso sin lógica.
- **Root modules por entorno** (`envs/prod`, `envs/staging`) que componen módulos versionados, **con state separado por entorno y por dominio** (blast radius acotado). Workspaces solo para variantes efímeras (previews de PR), **no** para separar prod/staging: un workspace comparte backend, credenciales y versión de código — un `terraform workspace select` equivocado es un incidente.

Layout de referencia:

```
infra/
├── modules/              # módulos propios, versionados (tags SemVer)
│   └── vpc/
│       ├── main.tf  variables.tf  outputs.tf  versions.tf
│       ├── README.md         # generado con terraform-docs
│       ├── examples/basic/   # ejemplo aplicable = test de integración
│       └── tests/vpc.tftest.hcl
└── envs/
    ├── prod/             # root module: backend + composición + valores
    │   ├── backend.tf  main.tf  providers.tf  terraform.tfvars
    └── staging/          # mismo código de módulos, valores distintos
```

Backend de referencia (S3, cifrado + locking nativo):

```hcl
terraform {
  required_version = "~> 1.12"          # OpenTofu; "~> 1.15" si Terraform
  backend "s3" {
    bucket       = "org-tfstate-prod"
    key          = "network/terraform.tfstate"   # un key por dominio
    region       = "eu-west-1"
    encrypt      = true
    kms_key_id   = "alias/tfstate"
    use_lockfile = true                  # locking nativo S3 (sin DynamoDB)
  }
}
```
- **State remoto cifrado con locking, siempre**: S3+DynamoDB/lockfile nativo, GCS, Azure Blob o backend gestionado; cifrado at-rest (KMS) y acceso por rol con mínimo privilegio. Con OpenTofu, evalúa state encryption (client-side) para state con datos sensibles — documenta que rompe la compatibilidad con Terraform.
- Variables tipadas con `type` estricto y `validation`; `sensitive = true` en todo lo secreto; nada de `default` para valores que deben decidirse por entorno.
- Módulos consumidos **por versión** (tag SemVer en registry/Git, o registry OCI con OpenTofu), nunca por rama (`ref=main` prohibido).
- Nombres: `snake_case`, recursos nombrados por rol (`this` en módulos de un recurso principal), tags/labels obligatorios (owner, env, cost-center, managed-by).
- Sin `local-exec`/`null_resource` como pegamento salvo último recurso documentado con TODO/issue.

### Ansible
- **Idempotencia como contrato**: toda tarea usa módulos declarativos (`ansible.builtin.*`, colecciones certificadas); `shell`/`command` solo con `creates`/`changed_when` y justificación. Segunda ejecución = 0 changed.
- Estructura en **roles** (galaxy layout: `tasks/`, `defaults/`, `handlers/`, `templates/`, `meta/`) empaquetados en colecciones si se comparten; playbooks finos que orquestan roles.
- Inventarios por entorno (preferir inventario dinámico contra el proveedor); `group_vars`/`host_vars` versionados; **Ansible Vault o lookup a gestor de secretos** para todo dato sensible — jamás en claro.
- FQCN siempre (`ansible.builtin.copy`, no `copy`); `become` explícito y mínimo, no global.
- `ansible.cfg` versionado en el repo; ejecución reproducible vía execution environments (imagen con dependencias fijadas) en CI.
- Layout de rol de referencia:

```
roles/nginx/
├── defaults/main.yml     # única capa de defaults (documentada)
├── tasks/main.yml        # tareas idempotentes, FQCN
├── handlers/main.yml     # reinicios/reloads, nunca en tasks
├── templates/            # *.j2 con {{ ansible_managed }}
├── meta/main.yml         # deps, plataformas soportadas
└── molecule/default/     # create→converge→idempotence→verify→destroy
```

## 4. Calidad y testing (gates de CI)

**Flujo obligatorio TF/Tofu — plan en PR, apply automatizado:**
1. PR: `fmt -check` → `validate` → `tflint` → escaneo (Trivy/checkov) → **`plan` con salida publicada en el PR** (artefacto del plan guardado) → Infracost diff → revisión humana del plan (CODEOWNERS en rutas de prod).
2. Merge a main: **apply automatizado del plan aprobado** (el mismo artefacto: apply-what-you-planned, no re-plan ciego) desde el pipeline con OIDC — **nunca apply desde portátiles**.
3. **Drift detection programada** (plan nocturno/cron con `-detailed-exitcode`): drift = alerta accionable + issue; se corrige en Git (o se importa), no se ignora.

**Tests por nivel:**
- Unit/contract: `terraform test`/`tofu test` (ficheros `.tftest.hcl`) para lógica de módulos, validaciones y outputs; Terratest solo si necesitas aserciones que el framework nativo no cubre.
- Integración: `examples/` de cada módulo aplicado en cuenta/proyecto sandbox efímero en el CI del módulo (crear → verificar → destruir).
- Ansible: `ansible-lint` (profile production) como gate + **Molecule** por rol (create → converge → **idempotence** → verify → destroy) contra contenedores o VMs efímeras; el paso de idempotencia es innegociable.
- Todo repo de IaC: pre-commit hooks (fmt, lint, docs, secret scan) espejo de los gates de CI.

## 5. Seguridad

- **Secretos: nunca en código, state en claro, tfvars commiteados ni logs.** Fuente única: Vault/Secrets Manager/SSM, consumidos en runtime (data sources, lookups de Ansible) o inyectados por el CI. Recuerda: **el state de TF contiene secretos en claro** → trátalo como secreto (cifrado, acceso mínimo, sin descargas locales).
- **Credenciales efímeras**: OIDC del CI hacia el cloud (roles de corta duración); prohibidas access keys estáticas en CI o en portátiles para prod.
- **Escaneo como gate que rompe el build**: Trivy (misconfig IaC + secret scanning) y/o checkov en cada PR; hallazgos CRITICAL/HIGH bloquean con excepciones vía baseline versionado y justificado (inline skip con comentario e issue, nunca silencioso).
- **Policy as code**: OPA/Conftest (o Sentinel en HCP) sobre el plan JSON — reglas de organización verificables: regiones permitidas, cifrado obligatorio, prohibido `0.0.0.0/0` en ingress, tags obligatorios, tipos de instancia aprobados. Mismas políticas en CI y (si existe) en el TACOS.
- Providers y módulos de terceros: pin de versión + revisión de fuente; módulos externos auditados antes de adoptar (un módulo es código con tus credenciales).
- Mínimo privilegio en el rol del pipeline: el rol de plan es read-only; el de apply, acotado por dominio/state.

## 6. Operabilidad

- **Entornos idénticos por construcción**: mismo código de módulos con valores por entorno; staging valida el cambio antes que prod (promoción = mismo commit/versión de módulo).
- **Cambios destructivos visibles**: revisar `plan` buscando `destroy`/`replace`; `lifecycle.prevent_destroy` en recursos con datos (BD, buckets); `create_before_destroy` donde el reemplazo deba ser sin corte.
- **Rollback probado**: revert del commit en Git + apply es el camino estándar; para recursos con estado (datos), el rollback es restore probado de backup, no un revert de HCL — documenta RTO/RPO por recurso crítico.
- Observabilidad del pipeline: histórico de plans/applies auditable (quién, qué, cuándo, con qué plan), notificación de applies a prod, métricas de drift.
- Ansible en prod: `--check --diff` como fase previa en el pipeline; `serial` + `max_fail_percentage` para rollouts progresivos; handlers para reinicios controlados.
- Runbooks para operaciones de state (import, `state mv`, unlock): son cirugía — con backup del state previo, en pareja, y registradas.

## 7. Sostenibilidad y prohibiciones

- **Cadencia de upgrades**: motor (Tofu/TF) y providers al día con revisión **mensual** vía Renovate/Dependabot (PR automático + plan en CI como test de regresión); nunca más de una minor mayor por detrás. ansible-core: solo 3 majors reciben fixes — planifica el salto anual. Leer changelogs de providers mayores (breaking changes en majors) antes de mergear.
- Refactors de state (`moved`, `removed`, `import` en bloque) en PRs dedicados, separados de cambios funcionales.
- Un ADR por decisión estructural: motor elegido, layout de states, estrategia de entornos, TACOS (Atlantis/env0/Spacelift/Scalr) si se adopta.

**PROHIBIDO** (gate automático donde sea posible):
- **State local** o en el repo; state sin cifrar o sin locking; descargar state a un portátil.
- `apply` manual desde máquinas locales a prod; cambios de infra por consola/CLI del cloud fuera de Git (excepto break-glass documentado y reconciliado con `import`).
- Secretos en claro en `.tf`, `.tfvars`, playbooks, inventarios, vars de CI o salidas de log; tfvars con secretos commiteados.
- Credenciales cloud estáticas de larga duración en CI.
- Módulos referenciados por rama (`ref=main`) o sin versión; providers sin pin ni lockfile.
- Workspaces para separar prod/no-prod; un único state monolítico para toda la organización.
- `-auto-approve` interactivo fuera del pipeline; apply de un plan distinto al revisado.
- Ignorar drift o "arreglarlo" editando el state a mano sin runbook.
- `shell`/`command` en Ansible sin idempotencia declarada; roles sin Molecule en repos compartidos.
- Deshabilitar el escáner o saltarse un gate "temporalmente" sin excepción registrada con issue y caducidad.

### Checklist de revisión rápida (todo PR de IaC)

- [ ] `plan` publicado en el PR y revisado (atención a `destroy`/`replace` no esperados); apply usará ese mismo artefacto.
- [ ] fmt + validate + tflint/ansible-lint + Trivy/checkov + Conftest en verde; excepciones con issue y caducidad.
- [ ] Sin secretos ni credenciales estáticas; variables sensibles con `sensitive = true`/Vault; OIDC en el pipeline.
- [ ] Providers/módulos con pin de versión y lockfile actualizado; módulos por tag, no por rama.
- [ ] State correcto (backend cifrado+locking del entorno objetivo); refactors de state en PR separado.
- [ ] Coste (Infracost) revisado; tags/labels obligatorios presentes; cambio probado en staging o example/Molecule.

## 8. Verificación web obligatoria

Antes de fijar versiones, sintaxis de features recientes o recomendaciones de motor:
1. **WebSearch/WebFetch** de releases oficiales (opentofu.org, releases de HashiCorp, PyPI ansible-core) y endoflife.date — cadencias rápidas, este documento envejece.
2. **Re-verifica el estado Terraform vs OpenTofu** (licencia, features divergentes, adopción): el fork diverge activamente (state encryption, OCI registry, `terraform query`/Actions solo en TF) y la recomendación puede cambiar.
3. Confirma breaking changes de providers mayores (aws/azurerm/google) para la versión objetivo antes de escribir constraints.
4. Si no puedes verificar, dilo explícitamente en la entrega en lugar de suponer.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
