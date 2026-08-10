---
name: gcp-standards
description: Google Cloud (GCP) architecture, security and FinOps standards. Use when working with GCP services (Cloud Run, GKE, Cloud Functions/Cloud Run functions, Cloud SQL, AlloyDB, Spanner, BigQuery, Pub/Sub, Cloud Storage, Artifact Registry, VPC, IAM, KMS, Secret Manager, Security Command Center, VPC Service Controls), the gcloud/gsutil/bq CLIs, or IaC files targeting GCP (Terraform *.tf with provider google, Infrastructure Manager).
---

# Estándares Google Cloud (GCP)

Este skill fija CRITERIO para diseñar, revisar y operar en Google Cloud: qué usar por defecto, qué
está prohibido y qué verificar antes de decidir. Marco: Google Cloud Architecture Framework +
enterprise foundations blueprint + zero-trust + FinOps. Ante conflicto, gana la seguridad; ante
empate técnico, lo más simple y gestionado.

## 1. Alcance y triggers

Aplica a cualquier tarea que toque GCP: Terraform/Infrastructure Manager, comandos
`gcloud`/`gsutil`/`bq`, diseño de organización y proyectos, IAM, revisión de seguridad, costes,
pipelines que despliegan en GCP. En tareas multi-cloud, combinar con `aws-standards` y
`azure-standards` y decidir por workload.

**No aplica**: ver `iac-standards` (el **cómo** del código Terraform/OpenTofu y Ansible: módulos,
state, backend, drift — aquí se decide el **qué**: qué servicio y con qué configuración),
`kubernetes-standards` (manifiestos, charts y workloads que corren **dentro** de GKE; aquí solo el
control plane, Autopilot y su integración con IAM/VPC), `cicd-standards` (la pipeline y la
federación OIDC/Workload Identity desde el runner), `identity-access-management-standards` (IdP de
aplicación: OAuth 2.1/OIDC, SAML, passkeys, SCIM — aquí Cloud IAM como control de acceso a la
**plataforma**), `cryptography-pki-standards` (elección de algoritmos y ciclo de vida de claves;
aquí solo Cloud KMS y Secret Manager como servicios),
`vulnerability-management-standards` (workflow de triaje y SLA; aquí solo Security Command Center
como fuente de hallazgos), `cloud-security-posture-standards` (**lo transversal a las tres nubes**:
línea base multi-proyecto, permiso efectivo, caminos de ataque y la elección de CSPM/CNAPP;
**aquí el servicio de GCP concreto y su configuración**),
`appsec-standards` (seguridad del código de la aplicación),
`observability-standards` (OTel y Prometheus vendor-neutral; aquí solo Cloud Observability y su
coste), `sre-practice-standards` (SLO, error budget, on-call y postmortems — la práctica SRE es
agnóstica aunque nazca en Google), `grc-compliance-standards` (marco normativo y evidencia de
auditoría), `networking-standards` (redes físicas, on-prem e híbridas; aquí VPC),
`data-platform-standards` (modelado, índices y tuning; aquí Cloud SQL/AlloyDB/BigQuery como
servicios), `finops-standards` (**método frente a servicio**: el modelo de precio de
cada servicio de GCP, los descuentos por uso comprometido y palancas propias como **el coste por
byte escaneado en BigQuery** son de aquí; **la unidad económica, la política de etiquetas y su
gate, la normalización con FOCUS y el reparto de coste compartido son suyos**. *Si la respuesta
cambia al cambiar de proveedor, es suya; si depende del catálogo de GCP, es de aquí*),
`platform-engineering-standards` (la abstracción interna ofrecida encima de estos
servicios).

## 2. Decisiones por defecto (servicio de referencia por caso de uso)

> **Verificar disponibilidad/estado por web antes de fijar cualquier servicio**: región, que no
> esté deprecado (Google Cloud deprecations / release notes) y precios vigentes.

| Caso de uso | Default | Alternativa (cuándo) |
|---|---|---|
| Contenedores stateless / APIs / web | **Cloud Run** (services; scale-to-zero) | — es el default salvo requisito K8s real |
| Batch/tareas containerizadas | Cloud Run jobs | Batch para HPC/colas de cómputo grandes |
| Funciones event-driven | Cloud Run functions (antes Cloud Functions — misma plataforma Cloud Run) | — |
| Kubernetes estratégico | GKE **Autopilot** (modo recomendado por Google) | GKE Standard solo con necesidad de nodos custom/DaemonSets de nodo/GPU exóticas |
| Relacional | Cloud SQL for PostgreSQL | AlloyDB si rendimiento Postgres extremo; Spanner si escala global + consistencia fuerte |
| Analítica | BigQuery | — |
| Clave-valor/documental | Firestore | Bigtable para series temporales/latencia a escala |
| Objetos | Cloud Storage (uniform bucket-level access, PAP enforced) | — |
| Mensajería/eventos | Pub/Sub (+ DLQ y retry policy siempre) | — |
| Cache | Memorystore (Valkey/Redis — verificar SKU vigente por web) | — |
| Secretos | Secret Manager (versiones, rotación, expiración) | — |
| Registro de artefactos | **Artifact Registry** (Container Registry está APAGADO desde mar-2025) | — |
| IaC | **Terraform/OpenTofu** (provider google) — es la vía canónica; Infrastructure Manager si se quiere ejecución gestionada de Terraform | Deployment Manager está RETIRADO (EOL mar-2026): prohibido |
| Base organizativa | Enterprise foundations blueprint (terraform-example-foundation) / Fabric FAST | Nunca proyectos sueltos sin folder ni org policies |
| CI/CD | El del repo (GitHub Actions/GitLab) con Workload Identity Federation; Cloud Build si todo-GCP | Cloud Deploy para progresión de releases a Cloud Run/GKE |

**Deprecados/retirados — PROHIBIDO proponerlos**: Deployment Manager (EOL 31-mar-2026 →
Infrastructure Manager/Terraform), Container Registry gcr.io (apagado mar-2025 → Artifact
Registry), service account keys como mecanismo por defecto (→ WIF, sección 3), SCC tier
Enterprise (deprecado, shutdown may-2027 → tier Premium; verificar estado por web). Ante
cualquier servicio dudoso, consultar sus release notes/deprecations antes de usarlo.

## 3. Identidad y accesos — credenciales efímeras SIEMPRE

- **Prohibidas las service account keys (JSON) exportadas** — es la postura oficial de Google y
  la de este skill. Workloads en GCP: attached service account (Cloud Run/GCE) o **Workload
  Identity Federation for GKE** (pods). CI/CD y sistemas externos: **Workload Identity
  Federation** (OIDC) con atributos restringidos (repo/rama) y, preferentemente, principal
  directo sin SA intermedia; impersonación de SA solo cuando haga falta. Humanos: Cloud Identity
  federado con el IdP + MFA/2SV obligatoria; acceso elevado vía grupos y con caducidad, no
  bindings individuales permanentes.
  Enforzar con org policy: `iam.disableServiceAccountKeyCreation` y
  `iam.disableServiceAccountKeyUpload` a nivel de organización (excepciones por proyecto,
  documentadas y con expiración).
- Mínimo privilegio: roles predefinidos concretos al scope mínimo (recurso/proyecto, no
  folder/org); **prohibidos** `roles/owner`/`roles/editor` en prod (basic roles); condiciones IAM
  (tiempo, recurso) donde aporten. Policy Intelligence/Recommender para recortar permisos no
  usados; IAM Recommender aplicado trimestralmente.
- Jerarquía: Organización → folders por entorno/dominio (según foundations blueprint) → proyectos
  como unidad de aislamiento (un workload+entorno por proyecto; el proyecto es el blast radius).
  Org Policies desde el día 1: `iam.allowedPolicyMemberDomains` (restricción de dominio),
  `compute.vmExternalIpAccess` deny, `sql.restrictPublicIp`, `storage.publicAccessPrevention`,
  `compute.requireShieldedVm`, `gcp.resourceLocations` (regiones aprobadas), y las dos de SA keys.
- Datos regulados/sensibles: **VPC Service Controls** — perímetro alrededor de los proyectos con
  APIs de datos (Storage, BigQuery, etc.) para cortar exfiltración con credenciales robadas;
  access levels con Access Context Manager; dry-run antes de enforce.

## 4. Redes — default-deny, exposición mínima

- **Prohibida la red default** (org policy `compute.skipDefaultNetworkCreation`). Shared VPC por
  entorno: proyecto host de red gestionado por plataforma, service projects para workloads;
  subnets regionales con rangos planificados (sin solapamientos RFC1918).
- Firewall default-deny: usar **network firewall policies** (jerárquicas y de red) sobre reglas
  clásicas VPC; reglas por service account/tags seguros, no por CIDR amplio; **prohibido
  `0.0.0.0/0` en ingress sin justificar** — y lo público solo detrás de External Application Load
  Balancer + **Cloud Armor** (WAF, rate limiting, protección DDoS).
- Sin IPs públicas en cómputo: Cloud NAT para egress (con logging), **Private Google Access** en
  toda subnet y Private Service Connect para APIs de Google y servicios publicados; Cloud SQL por
  IP privada (o conector con IAM auth), nunca IP pública. Cloud Run: ingress interno +
  balanceador salvo servicio realmente público; egress por Direct VPC egress.
- Acceso administrativo por **IAP** (TCP forwarding para SSH/RDP) — nunca puertos de gestión
  públicos ni bastión expuesto. TLS 1.2+ en frontales (SSL policy moderna, no la default), HSTS;
  mTLS servicio-a-servicio donde el dato lo pida (Cloud Service Mesh en GKE — verificar nombre y
  estado por web). VPC Flow Logs + Firewall Rules Logging en prod.

## 5. Datos — cifrado, backups probados, RTO/RPO

- Cifrado en reposo por defecto en toda la plataforma; **CMEK (Cloud KMS)** para datos
  sensibles/regulados (Storage, BigQuery, Cloud SQL, discos, Pub/Sub): keyring por
  entorno/región, rotación automática programada, IAM mínimo sobre claves, org policy
  `gcp.restrictNonCmekServices` donde el compliance lo exija. Autokey para simplificar a escala
  (verificar estado por web).
- RTO/RPO definidos antes de elegir topología: Cloud SQL con HA regional (standby) por defecto en
  prod; cross-region replicas/Spanner multi-region solo si el RTO/RPO lo exige (coste).
- Backups: **Backup and DR Service** o backups nativos gestionados (Cloud SQL automated backups +
  PITR activado; Backup for GKE; bucket con versioning + soft delete + bucket lock para
  inmutabilidad ransomware). Copia en proyecto/región separados para escenario de compromiso.
  **Un backup sin restore probado no existe**: ensayo periódico y documentado.
- Cloud Storage: uniform bucket-level access + public access prevention SIEMPRE; lifecycle a
  Nearline/Coldline/Archive según acceso real; retención/borrado conforme a GDPR (minimización,
  derecho al olvido). Sensitive Data Protection (DLP) para descubrimiento/clasificación de PII.
  Migraciones expand/contract.

## 6. Observabilidad y operación

- Cloud Logging con **retención explícita** por bucket de logs y sinks agregados a nivel de
  organización hacia un proyecto de logging central (audit logs inmutables, con lock). **Admin
  Activity audit logs** siempre; Data Access audit logs activados en proyectos con datos
  sensibles (coste evaluado, no excusa).
- Logs estructurados (JSON), Cloud Monitoring con alertas accionables sobre síntomas (golden
  signals) y **SLOs con error budget** (Cloud Monitoring SLO API — SRE es de la casa: úsalo);
  trazas con Cloud Trace vía OpenTelemetry (preferido por portabilidad). Alertas → on-call, no a
  un buzón.
- **Security Command Center** a nivel de organización: tier Premium (Enterprise deprecado —
  verificar por web), Security Health Analytics + Event Threat Detection activos; findings
  triados con SLA, export a SIEM. Assured Workloads si hay requisitos de compliance regional.
- Todo cambio por pipeline con `terraform plan` revisado; despliegues canary/gradual (Cloud Run
  revisions con traffic splitting; Cloud Deploy para progresión) y rollback probado; runbooks y
  postmortems sin culpa. Binary Authorization en GKE/Cloud Run para imágenes firmadas
  (cosign/attestations) en prod.

## 7. FinOps — coste como atributo de calidad

- **Labels obligatorios** en todo recurso: mínimo `owner`, `env`, `project`/`cost-center`,
  `managed-by`; enforzados vía IaC (módulos con labels requeridos) y auditados — sin labels =
  huérfano. Proyecto por workload+entorno hace la atribución casi gratis: aprovéchalo.
- Billing export a **BigQuery** (detailed usage cost) + vista **FOCUS** (verificar por web
  versión soportada — 1.3 ratificada dic-2025); budgets con alertas por proyecto y umbrales
  programáticos (Pub/Sub) desde el día 1; anomaly detection activo.
- Palancas por defecto: scale-to-zero (Cloud Run), CUDs (resource-based o flex — verificar
  ofertas vigentes, p. ej. Autopilot Flex CUDs) para base estable con ≥30 días de datos, Spot
  VMs/pods para tolerante a fallo, right-sizing con Recommender, apagado de no-prod fuera de
  horario. BigQuery: particionado+clustering, cuotas de consulta, slots/editions según patrón —
  el on-demand sin control es la factura sorpresa clásica.
- Coste del diseño en la decisión: egress inter-región/Internet, Cloud NAT, logging ingest,
  Private Service Connect — estimados antes de desplegar.

## 8. Sostenibilidad, lock-in y PROHIBICIONES

- **Lock-in consciente, no accidental**: servicios propietarios (Spanner, BigQuery, Firestore)
  solo con beneficio claro; contratos tras interfaces propias; portabilidad barata donde no
  cueste (Postgres, contenedores OCI en Cloud Run/GKE, OpenTelemetry, Terraform).
- Política de upgrades: GKE en release channel (Regular por defecto) con maintenance windows —
  nunca clusters sin canal ni versiones fuera de soporte; runtimes de Cloud Run
  functions vigentes; provider de Terraform actualizado con cadencia. Revisar deprecations de
  GCP trimestralmente; el upgrade es trabajo planificado, no emergencia.
- **LISTA DE PROHIBICIONES** (bloquean una review):
  - Service account keys JSON creadas/exportadas (org policy debe impedirlo); API keys para
    servicios que aceptan IAM; `roles/owner`/`roles/editor` en prod; bindings a usuarios
    individuales en vez de grupos.
  - Red default en uso; `0.0.0.0/0` en ingress sin justificar; IPs públicas en VMs/Cloud SQL;
    puertos de gestión expuestos (sin IAP); buckets públicos o sin public access prevention.
  - Recursos creados por consola en prod (**clickops**) — todo por Terraform; drift sin
    reconciliar; Deployment Manager; imágenes en gcr.io; `latest` en imágenes de prod.
  - Recursos sin labels obligatorios; proyectos fuera de la jerarquía de folders/org policies;
    billing sin export a BigQuery ni budgets.
  - Secretos en código/env/logs en claro (usar Secret Manager); datos sensibles sin CMEK cuando
    la clasificación lo exige; audit logs desactivados o sin sink central.
  - Prod sin HA regional (Cloud SQL single instance, GKE zonal); backup sin restore probado;
    logs sin retención definida; perímetro VPC-SC ausente en proyectos de datos regulados.

## 9. Verificación web obligatoria

Antes de fijar en código o respuesta cualquier dato concreto de GCP, **buscar en la web** (docs
cloud.google.com / release notes / deprecations primero): estado del servicio y deprecaciones
(cambian de nombre y de tier con frecuencia: SCC tiers, Memorystore SKUs, Cloud Functions → Cloud
Run functions…), disponibilidad regional, versiones GKE soportadas por canal, límites/cuotas,
precios y novedades Cloud Next del último año. La memoria del modelo NO es fuente válida para
precios, fechas EOL, nombres de features recientes ni disponibilidad regional. Si no se puede
verificar, decirlo y marcar la decisión como provisional.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
