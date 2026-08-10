---
name: azure-standards
description: Azure architecture, security and FinOps standards. Use when working with Azure services (AKS, Container Apps, App Service, Functions, Entra ID, Key Vault, VNet, Private Link, Azure Policy, Defender for Cloud, Azure Monitor, Storage, SQL Database, Cosmos DB, Service Bus, Event Grid), the az CLI, azd, or IaC files targeting Azure (Bicep *.bicep, ARM templates azuredeploy.json, Terraform *.tf with provider azurerm/azapi).
---

# Estándares Azure

Este skill fija CRITERIO para diseñar, revisar y operar en Azure: qué usar por defecto, qué está
prohibido y qué verificar antes de decidir. Marco de referencia: Cloud Adoption Framework (CAF) +
Well-Architected Framework (WAF) + zero-trust + FinOps. Ante conflicto, gana la seguridad; ante
empate técnico, lo más simple y gestionado.

## 1. Alcance y triggers

Aplica a cualquier tarea que toque Azure: Bicep/ARM/Terraform, comandos `az`/`azd`, diseño de
landing zones, RBAC, revisión de seguridad, costes, pipelines que despliegan en Azure. En tareas
multi-cloud, combinar con `aws-standards` y `gcp-standards` y decidir por workload.

**No aplica**: ver `iac-standards` (el **cómo** del código Terraform/OpenTofu y Ansible: módulos,
state, backend, drift — aquí se decide el **qué**: qué servicio y con qué configuración; Bicep/ARM
sí son de esta skill), `kubernetes-standards` (manifiestos, charts y workloads que corren **dentro**
de AKS; aquí solo el control plane y su integración con Entra ID/VNet), `cicd-standards` (la
pipeline y la federación OIDC desde el runner), `identity-access-management-standards` (IdP de
aplicación: OAuth 2.1/OIDC, SAML, passkeys, SCIM, motores de autorización — aquí Entra ID como
control de acceso a la **plataforma** y sus RBAC roles), `cryptography-pki-standards` (elección de
algoritmos y ciclo de vida de claves; aquí solo Key Vault/Managed HSM como servicio),
`vulnerability-management-standards` (workflow de triaje y SLA; aquí solo Defender for Cloud como
fuente de hallazgos), `cloud-security-posture-standards` (**lo transversal a las tres nubes**:
línea base multi-suscripción, permiso efectivo, caminos de ataque y la elección de CSPM/CNAPP;
**aquí el servicio de Azure concreto y su configuración**),
`appsec-standards` (seguridad del código de la aplicación),
`observability-standards` (OTel y Prometheus vendor-neutral; aquí solo Azure Monitor y su coste),
`sre-practice-standards` (SLO, on-call, postmortems), `grc-compliance-standards` (marco normativo y
evidencia de auditoría), `networking-standards` (redes físicas, on-prem e híbridas; aquí VNet),
`dotnet-standards` (el código C# de la aplicación que se despliega encima), `finops-standards` (**método frente a servicio**: el modelo de precio de cada servicio de Azure, sus reservas y planes de ahorro y sus palancas concretas son de aquí; **la unidad económica, la política de etiquetas y su gate, la normalización con FOCUS, el reparto de coste compartido y el criterio de cobertura de compromisos son suyos**. *Si la respuesta cambia al cambiar de proveedor, es suya; si depende del catálogo de Azure, es de aquí*), `platform-engineering-standards` (la abstracción interna ofrecida encima de estos servicios).

## 2. Decisiones por defecto (servicio de referencia por caso de uso)

> **Verificar disponibilidad/estado por web antes de fijar cualquier servicio**: región, SKU, que
> no esté en retirement (Azure Updates / Microsoft Lifecycle / Azure Advisor "Service Upgrade and
> Retirement") y precios vigentes.

| Caso de uso | Default | Alternativa (cuándo) |
|---|---|---|
| Contenedores sin requisito K8s | Azure Container Apps (scale-to-zero, Dapr, KEDA) | App Service para web apps clásicas ya en esa plataforma |
| Kubernetes estratégico | AKS **Automatic** (GA sept-2025; Azure Linux, best practices por defecto) | AKS Standard solo si necesitas control de nodos/kernel/CIS a nivel nodo |
| Funciones event-driven | Azure Functions (plan Flex Consumption — verificar estado por web) | Container Apps jobs para tareas containerizadas |
| Relacional | Azure Database for PostgreSQL Flexible Server / Azure SQL Database | — (Single Server está retirado) |
| NoSQL global | Cosmos DB (API según modelo de datos) | — |
| Objetos/blobs | Storage Account (Blob, GPv2, LRS/ZRS según RTO/RPO) | — |
| Cola simple | Storage Queues | Service Bus si sesiones, orden, DLQ, transacciones |
| Mensajería empresarial | Service Bus (colas/topics + DLQ) | — |
| Eventos | Event Grid (reactivo) / Event Hubs (streaming) | — |
| Cache | Azure Managed Redis (verificar por web: sustituye a Azure Cache for Redis, en retirement) | — |
| Secretos/claves | Key Vault (RBAC-mode, soft delete + purge protection) | Managed HSM si FIPS 140-3 L3 |
| Registro de contenedores | Azure Container Registry (Premium en prod: private link, geo-replicación) | — |
| IaC nativa | **Bicep + Azure Verified Modules (AVM)** | Terraform/OpenTofu + AVM si la organización ya lo usa; ARM JSON solo generado, nunca a mano |
| Landing zone | Azure Landing Zones (CAF) vía acelerador IaC con AVM (Bicep o Terraform) | Portal accelerator solo para arranque exploratorio |
| CI/CD | El del repo (GitHub Actions/Azure DevOps) con OIDC/workload identity federation | — |

**Retirados/deprecados — PROHIBIDO proponerlos** (fuente: Microsoft Lifecycle / Azure Updates):
todo lo classic/ASM (Cloud Services classic, ASE v1/v2 — retirados ago-2024), Log Analytics agent
MMA/OMS (retirado ago-2024; la ingesta puede cortarse desde mar-2026 → **Azure Monitor Agent**),
PostgreSQL/MySQL Single Server (→ Flexible Server), Application Insights classic (→
workspace-based), el Landing Zone Accelerator de Container Apps en CAF (retirado may-2026 → guía
del Architecture Center). Comprobar en Azure Advisor los retirements que afecten a recursos vivos.

## 3. Identidad y accesos — credenciales efímeras SIEMPRE

- **Prohibidos secretos estáticos**: nada de connection strings con claves de cuenta, SAS de larga
  vida, client secrets de app registrations en workloads, ni claves en App Settings en claro.
  Workloads en Azure: **Managed Identity** (user-assigned preferida: ciclo de vida controlado) para
  TODO acceso a Storage/Key Vault/SQL/Service Bus (auth Entra ID, no access keys). CI/CD externo:
  **workload identity federation** (OIDC) contra Entra ID — prohibido el service principal con
  secreto/certificado de larga vida. Humanos: Entra ID + MFA obligatorio (Conditional Access), sin
  cuentas locales.
- Storage/SQL/Cosmos: deshabilitar auth por clave/local (`allowSharedKeyAccess: false`,
  `disableLocalAuth: true`) donde el servicio lo soporte; solo Entra ID.
- RBAC mínimo privilegio: roles built-in concretos al scope mínimo (resource group, no
  suscripción); Owner/Contributor a suscripción solo para pipelines de plataforma muy acotados.
  Roles privilegiados vía **PIM** (just-in-time, aprobación, tiempo limitado), nunca permanentes.
  Access reviews periódicas.
- Jerarquía: management groups según ALZ (Platform: identity/management/connectivity; Landing
  Zones: corp/online; Sandbox; Decommissioned); suscripción como unidad de aislamiento por
  workload+entorno. Azure Policy asignada a management groups: deny de regiones no aprobadas,
  deny de recursos con IP pública no permitida, require tags, require cifrado — governance as
  code, no wiki.

## 4. Redes — default-deny, exposición mínima

- Topología hub-spoke (o Virtual WAN a escala): hub con firewall (Azure Firewall o NVA) y
  conectividad (ExpressRoute/VPN); spokes por workload, peered, **sin tránsito directo
  spoke-a-spoke** salvo vía hub. UDR forzando egress por el firewall en cargas sensibles
  (inspección y filtrado de salida, no solo entrada).
- NSGs default-deny en toda subnet (las reglas default permiten demasiado intra-VNet: añadir
  deny explícito); reglas por Application Security Groups, no CIDRs sueltos. **Prohibido
  `0.0.0.0/0`/`Any` en inbound sin justificar** — y entonces detrás de Front Door/Application
  Gateway con WAF.
- PaaS SIEMPRE por **Private Link/Private Endpoints** (Storage, Key Vault, SQL, ACR, Cosmos…):
  `publicNetworkAccess: Disabled`. Private DNS zones centralizadas en el hub. Los service
  endpoints son legacy: solo si Private Link no existe para ese servicio (verificar por web).
- TLS 1.2+ mínimo en todo (`minimumTlsVersion`), HSTS en frontales; mTLS entre servicios cuando
  el dato lo pida. Acceso administrativo por Azure Bastion — **nunca RDP/SSH públicos**, ni
  JIT-VM-access como excusa para IP pública permanente.
- DDoS Network Protection en VNets con endpoints públicos de prod.

## 5. Datos — cifrado, backups probados, RTO/RPO

- Cifrado en reposo por defecto en toda la plataforma; **customer-managed keys (CMK) en Key
  Vault** para datos sensibles/regulados (Storage, SQL TDE, Cosmos, discos con encryption at
  host). Key Vault: RBAC-mode, soft delete + purge protection innegociables, rotación de claves
  programada, un vault por workload/entorno (blast radius).
- RTO/RPO definidos antes de elegir SKU y redundancia: zone-redundant (ZRS/zonal) por defecto en
  prod; geo-redundancia (GRS/failover groups/Cosmos multi-region) solo si el RPO/RTO lo exige.
- Azure Backup centralizado (Recovery Services/Backup vault) con política por tags, **soft delete
  + inmutabilidad activadas** (ransomware) y copia cross-region si el DR lo pide. **Un backup sin
  restore probado no existe**: ensayo de restauración periódico y documentado. Azure Site Recovery
  para DR de VMs con failover test anual mínimo.
- Lifecycle management en Blob (hot→cool→archive según acceso real); retención/borrado conforme a
  GDPR (minimización, derecho al olvido). Migraciones expand/contract.

## 6. Observabilidad y operación

- Azure Monitor + Log Analytics workspace centralizado (por región/entorno según ALZ); **Azure
  Monitor Agent** (AMA) con Data Collection Rules — MMA está muerto. Diagnostic settings en TODO
  recurso de prod (vía Azure Policy deployIfNotExists, no a mano). Retención explícita por tabla
  (coste); archive/basic logs para lo de bajo acceso.
- Application Insights workspace-based con OpenTelemetry (preferir OTel SDK/distro sobre SDKs
  clásicos — verificar estado por web); trazas correlacionadas, golden signals, SLOs con error
  budget; alertas accionables → on-call (action groups), no ruido.
- **Microsoft Defender for Cloud**: planes activados por tipo de recurso en prod (Servers,
  Storage, Containers, Databases, Key Vault…), Secure Score como métrica seguida, integración con
  el SIEM (Microsoft Sentinel) para detección y respuesta; export continuo de findings.
- **Azure Policy como gate**: initiatives (CIS/MCSB) asignadas en management groups, con deny
  para lo crítico y deployIfNotExists para lo operativo; compliance dashboard revisado, cero
  excepciones sin expiración.
- Todo cambio por pipeline con what-if/plan revisado; blue-green/canary con slots o revisiones
  (Container Apps) y rollback probado; runbooks y postmortems sin culpa.

## 7. FinOps — coste como atributo de calidad

- **Tagging obligatorio**: mínimo `owner`, `env`, `project`/`cost-center`, `managed-by`,
  enforzado con Azure Policy (require + inherit desde resource group). Sin tags = huérfano.
- Cost Management exports en formato **FOCUS** (verificar por web versión soportada — 1.3
  ratificada dic-2025) a Storage/warehouse; budgets con alertas por suscripción/RG y anomaly
  detection activos desde el día 1.
- Palancas por defecto: Reservations/Savings Plans para base estable (con ≥30 días de datos),
  Spot para tolerante a fallo, scale-to-zero (Container Apps/Functions) y auto-shutdown en
  no-prod, right-sizing con Azure Advisor. AKS: Flex CUDs/reservas según patrón — verificar
  ofertas vigentes por web.
- Coste del diseño en la decisión: Private Endpoints (por-hora+datos), Azure Firewall, egress
  inter-region, Log Analytics ingest, DDoS Protection — estimados antes de desplegar, no
  descubiertos en factura.

## 8. Sostenibilidad, lock-in y PROHIBICIONES

- **Lock-in consciente, no accidental**: servicios propietarios (Cosmos, Service Bus, Functions)
  solo con beneficio claro; contratos tras interfaces propias; portabilidad barata donde se pueda
  (PostgreSQL flexible, contenedores OCI, OpenTelemetry, Dapr en Container Apps).
- Política de upgrades: versiones en soporte SIEMPRE (AKS N-2 máximo con auto-upgrade channel,
  runtimes de Functions/App Service vigentes, API versions de ARM/Bicep actuales); revisar Azure
  Advisor retirements trimestralmente; el upgrade es trabajo planificado, no emergencia.
- **LISTA DE PROHIBICIONES** (bloquean una review):
  - Client secrets/keys estáticos donde exista Managed Identity o workload identity federation;
    access keys de Storage habilitadas sin justificación; SAS de larga vida.
  - RDP/SSH públicos; `Any`/`0.0.0.0/0` inbound sin justificar; PaaS con endpoint público
    teniendo Private Link disponible; NSG ausente en subnet de workload.
  - Recursos creados por portal en prod (**clickops**) — todo por IaC (Bicep/Terraform);
    drift sin reconciliar; ARM JSON escrito a mano.
  - Recursos sin tags obligatorios; roles Owner/Contributor permanentes a humanos; asignaciones
    RBAC a usuarios individuales en vez de grupos; roles privilegiados sin PIM.
  - Key Vault sin purge protection; secretos en app settings/código/logs; datos sin CMK cuando
    la clasificación lo exige.
  - Servicios retirados (lista sección 2); agente MMA; `latest` en imágenes de prod; recursos
    classic/ASM.
  - Logs sin retención definida; prod single-zone teniendo zonas disponibles; backup sin restore
    probado; suscripción fuera de la jerarquía de management groups.

## 9. Verificación web obligatoria

Antes de fijar en código o respuesta cualquier dato concreto de Azure, **buscar en la web** (Learn
/ Azure Updates / Lifecycle primero): estado del servicio y retirements, disponibilidad regional y
de SKU, versión de API de ARM/Bicep, nombres exactos de planes/SKUs (cambian a menudo: Flex
Consumption, AKS Automatic, Azure Managed Redis…), precios y novedades Build/Ignite del último
año. La memoria del modelo NO es fuente válida para precios, fechas de retirement, nombres de
features recientes ni disponibilidad regional. Si no se puede verificar, decirlo y marcar la
decisión como provisional.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
