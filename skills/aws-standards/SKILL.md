---
name: aws-standards
description: AWS architecture, security and FinOps standards. Use when working with AWS services (Lambda, ECS, EKS, Fargate, S3, RDS, Aurora, DynamoDB, SQS, SNS, EventBridge, VPC, IAM, KMS, GuardDuty, Security Hub, CloudWatch, Organizations, Control Tower), the aws CLI, SAM, or IaC files targeting AWS (CloudFormation templates *.yaml/*.json, CDK cdk.json/*.ts/*.py, Terraform *.tf with provider aws).
---

# Estándares AWS

Este skill fija CRITERIO para diseñar, revisar y operar en AWS: qué usar por defecto, qué está
prohibido y qué verificar antes de decidir. Nivel de exigencia: Well-Architected + zero-trust +
FinOps. Ante conflicto, gana la seguridad; ante empate técnico, gana lo más simple y lo gestionado.

## 1. Alcance y triggers

Aplica a cualquier tarea que toque AWS: código IaC (CloudFormation/CDK/Terraform/SAM), comandos
`aws`, diseño de arquitectura, revisión de seguridad, estimación de costes, pipelines que
despliegan en AWS. Si la tarea es multi-cloud, combinar con los skills `azure-standards` y
`gcp-standards` y decidir por workload, no por inercia.

**No aplica**: ver `iac-standards` (el **cómo** del código Terraform/OpenTofu y Ansible: módulos,
state, backend, drift — aquí se decide el **qué**: qué servicio y con qué configuración),
`kubernetes-standards` (manifiestos, charts y workloads que corren **dentro** de EKS; aquí solo el
control plane, el data plane y su integración con IAM/VPC), `cicd-standards` (la pipeline y la
federación OIDC desde el runner), `identity-access-management-standards` (IdP de aplicación: OAuth
2.1/OIDC, SAML, passkeys, SCIM — aquí IAM/Identity Center como control de acceso a la **plataforma**),
`cryptography-pki-standards` (elección de algoritmos y ciclo de vida de claves; aquí solo KMS como
servicio), `vulnerability-management-standards` (workflow de triaje y SLA; aquí solo Security Hub /
Inspector como fuente de hallazgos), `cloud-security-posture-standards` (**lo transversal a las
tres nubes**: línea base multi-cuenta, permiso efectivo, caminos de ataque y la elección de
CSPM/CNAPP; **aquí el servicio de AWS concreto y su configuración**),
`appsec-standards` (seguridad del código de la aplicación),
`observability-standards` (OTel y Prometheus vendor-neutral; aquí solo CloudWatch y su coste),
`sre-practice-standards` (SLO, on-call, postmortems), `grc-compliance-standards` (marco normativo y
evidencia de auditoría), `networking-standards` (redes físicas, on-prem e híbridas; aquí VPC),
`data-platform-standards` (modelado, índices y tuning del motor; aquí RDS/Aurora como servicio), `finops-standards` (**Ola 6** — **frontera de método frente a servicio**: **el modelo de precio de cada servicio de AWS, su configuración y las palancas concretas —clase de almacenamiento, familia de instancia, Savings Plans— son de aquí**; **el método es suyo**: unidad económica, política de etiquetas y su gobierno, normalización con FOCUS, reparto de coste compartido, criterio de cobertura de compromisos y showback/chargeback. Regla: *si la respuesta cambia al cambiar de proveedor, es de `finops-standards`; si depende del catálogo de AWS, es de aquí*), `platform-engineering-standards` (**Ola 6**: la abstracción interna que se ofrece encima de estos servicios).

## 2. Decisiones por defecto (servicio de referencia por caso de uso)

> **Verificar disponibilidad/estado por web antes de fijar cualquier servicio**: región soportada,
> que no esté en Maintenance/Sunset en https://aws.amazon.com/products/lifecycle/ y precios vigentes.

| Caso de uso | Default | Alternativa (cuándo) |
|---|---|---|
| Cómputo event-driven / picos / <15 min | Lambda (arm64/Graviton) | ECS Fargate si throughput sostenido o >15 min |
| Contenedores sin requisito K8s | ECS + Fargate | EC2 capacity providers solo con justificación (GPU, coste sostenido) |
| Kubernetes estratégico (portabilidad, ecosistema) | EKS con Auto Mode (Karpenter) | Fargate profiles para cargas aisladas |
| API HTTP | API Gateway (HTTP API) + Lambda | ALB + Fargate para servicios always-on |
| Relacional | Aurora (PostgreSQL) / RDS PostgreSQL | Aurora Serverless v2 para carga variable |
| Clave-valor / escala masiva | DynamoDB (on-demand por defecto) | Provisioned + auto scaling si patrón estable y probado |
| Objetos | S3 (SSE por defecto, Block Public Access) | — |
| Cola / desacoplo | SQS (+ DLQ siempre) | — |
| Pub/sub y eventos | EventBridge (dominio) / SNS (fan-out simple) | Kinesis / MSK solo para streaming real con orden y replay |
| Cache | ElastiCache (Valkey/Redis OSS) | — |
| Secretos | Secrets Manager (rotación) / SSM Parameter Store (config) | — |
| Registro de contenedores | ECR (scan on push, immutable tags) | — |
| IaC nativa | CDK v2 (TypeScript/Python) sobre CloudFormation | Terraform/OpenTofu si el repo/organización ya lo usa — no mezclar en el mismo stack |
| Landing zone multi-cuenta | Organizations + Control Tower; personalización con LZA (CDK) o CfCT | Nunca cuentas sueltas sin OU ni SCP/RCP |
| CI/CD | El del repo (GitHub Actions/GitLab) con OIDC hacia AWS | CodePipeline/CodeBuild si todo-AWS es requisito |

**Deprecados/retirados — PROHIBIDO proponerlos** (cerrados a nuevos clientes desde 2024 o en
sunset, fuente: AWS Product Lifecycle): CodeCommit (→ GitHub/GitLab), Cloud9 (→ IDE local +
CloudShell), S3 Select (→ Athena), CloudSearch (→ OpenSearch), SimpleDB (→ DynamoDB), Forecast
(→ SageMaker), Data Pipeline (→ Glue/Step Functions), Kinesis Data Analytics for SQL (apagado
ene-2026 → Managed Service for Apache Flink), Inspector Classic (→ Inspector), Pinpoint (EOS
oct-2026 → SES/End User Messaging), Proton (EOS oct-2026), OpsWorks. Ante cualquier servicio
"raro", consultar la página de lifecycle antes de usarlo.

## 3. Identidad y accesos — credenciales efímeras SIEMPRE

- **Prohibidas las access keys estáticas** (IAM users con keys) para humanos, CI/CD y workloads.
  Humanos: IAM Identity Center (SSO federado con el IdP corporativo) + MFA. CI/CD: OIDC federation
  (p. ej. `token.actions.githubusercontent.com`) con roles de corta duración y `sub` restringido a
  repo/rama. Workloads: roles de instancia/tarea (instance profile, ECS task role, IRSA/Pod
  Identity en EKS). Excepción única: sistema externo sin soporte OIDC/rol — documentada, con
  rotación automática y alerta de uso.
- Mínimo privilegio real: policies con acciones y recursos concretos, condiciones
  (`aws:SourceArn`, `aws:PrincipalOrgID`, tags). Prohibido `Action: "*"`, `Resource: "*"` y
  policies gestionadas `AdministratorAccess`/`PowerUserAccess` fuera de break-glass.
- Guardrails de organización: SCPs y RCPs (deny de regiones no aprobadas, deny de desactivar
  CloudTrail/GuardDuty, deny de crear IAM users con keys). Permissions boundaries para roles
  creados por pipelines.
- Cuenta de gestión (management account): sin workloads, sin uso diario; acceso break-glass
  auditado. Cuentas separadas por entorno (prod/no-prod) y por dominio; log-archive y
  security-tooling dedicadas (las crea Control Tower).
- Verificar acceso: Access Analyzer (external + unused access) activo en todas las cuentas.

## 4. Redes — default-deny, exposición mínima

- VPC propia por workload/entorno; **no usar la VPC default** (eliminarla o dejarla sin uso).
  Subnets privadas por defecto; públicas solo para ALB/NLB/NAT. IPAM sin solapamientos (RFC1918).
- Security Groups default-deny: solo ingress imprescindible, referenciando otros SG, no CIDRs
  amplios. **Prohibido `0.0.0.0/0` en ingress salvo 443 en el borde público justificado** (y
  entonces detrás de CloudFront/WAF + Shield). Egress también restringido en cargas sensibles.
- Tráfico a servicios AWS por VPC endpoints (Gateway para S3/DynamoDB — gratis; Interface para el
  resto) con endpoint policies; evita NAT innecesario (coste) y salida a Internet (seguridad).
- TLS 1.2+ en todo (ALB security policy moderna, HSTS); mTLS entre servicios cuando el dato lo
  pida (ECS Service Connect / App Mesh sucesores — verificar estado por web). Acceso administrativo
  por SSM Session Manager, **nunca SSH abierto ni bastión con 22 público**.
- Exposición mínima: nada de IPs públicas en instancias/tareas; ALB interno salvo servicio
  realmente público. Route 53 con registros mínimos; DNSSEC donde aplique.

## 5. Datos — cifrado, backups probados, RTO/RPO

- Cifrado en reposo en TODO recurso: KMS con claves gestionadas por el cliente (CMK) para datos
  sensibles (alias por dominio, rotación anual activada, key policies mínimas); SSE-S3/claves AWS
  gestionadas como suelo mínimo. S3: Block Public Access a nivel de cuenta, versioning en buckets
  de datos, Object Lock para inmutabilidad (ransomware/compliance).
- RTO/RPO definidos ANTES de elegir motor y topología; multi-AZ por defecto en prod; multi-región
  solo si el RTO/RPO lo exige (coste).
- Backups: AWS Backup centralizado con plan por tags, vault con Vault Lock (inmutable) y copia
  cross-account/cross-region para escenario de compromiso de cuenta. **Un backup sin restore
  probado no existe**: game-day de restauración periódico y documentado.
- Ciclo de vida: S3 lifecycle a IA/Glacier según acceso real (S3 Storage Lens / Intelligent-Tiering
  para patrones desconocidos); retención y borrado conforme a GDPR (minimización, derecho al olvido).
- Migraciones de esquema expand/contract; nunca cambios destructivos en el mismo deploy.

## 6. Observabilidad y operación

- CloudTrail organizacional (todas las cuentas/regiones, logs a cuenta log-archive, integridad
  activada) — innegociable. VPC Flow Logs en VPCs de prod.
- Logs estructurados (JSON) a CloudWatch Logs con retención explícita (**nunca "Never expire" por
  defecto** — es coste y ruido); métricas con alarmas accionables sobre síntomas (golden signals),
  no sobre cada recurso; trazas con X-Ray/ADOT (OpenTelemetry preferido por portabilidad).
- SLOs con error budget para servicios de negocio; alertas → on-call, no a un buzón.
- Seguridad operativa: GuardDuty (todas las cuentas, delegated admin, protecciones S3/EKS/RDS
  según uso), Security Hub para agregación/priorización — **ojo**: desde dic-2025 "Security Hub"
  es el servicio unificado nuevo (OCSF, APIs v2) y el clásico se llama "Security Hub CSPM" (ASFF);
  verificar por web cuál aplica antes de escribir automatización, no son intercambiables.
  Inspector (el actual, no Classic) para vulnerabilidades en ECR/EC2/Lambda. AWS Config con
  conformance packs (CIS AWS Foundations v5) en todas las cuentas.
- Todo cambio por pipeline con plan/diff revisado; despliegues canary/rolling con rollback
  probado (CodeDeploy, feature flags). Runbooks y postmortems sin culpa.

## 7. FinOps — coste como atributo de calidad

- **Tagging obligatorio y verificado**: mínimo `owner`, `env`, `project`/`cost-center`,
  `managed-by` (IaC). Enforzado con tag policies + SCP/Config rule que marca no conformes.
  Recurso sin tags = recurso huérfano = candidato a borrado.
- Data Exports en formato **FOCUS** (estándar FinOps Foundation; verificar por web la versión
  soportada — 1.3 ratificada dic-2025) a S3/Athena; Budgets con alertas por cuenta/proyecto y
  Cost Anomaly Detection activado desde el día 1.
- Palancas por defecto: Graviton/arm64 donde el runtime lo soporte, Savings Plans para base
  estable (decisión con datos de ≥30 días, no de memoria), Spot para cargas tolerantes a fallo,
  scale-to-zero/off-hours en no-prod, right-sizing con Compute Optimizer.
- Coste del diseño en la decisión de arquitectura: NAT Gateway, transferencia inter-AZ/región,
  endpoints Interface, CloudWatch ingest — se estiman antes, no se descubren en factura.

## 8. Sostenibilidad, lock-in y PROHIBICIONES

- **Lock-in consciente, no accidental**: servicios propietarios (DynamoDB, EventBridge, Step
  Functions) solo con beneficio claro; contratos de la app tras interfaces propias; estándares
  portables donde no cueste (OpenTelemetry, Postgres, S3 API, contenedores OCI).
- Política de upgrades: versiones de runtime/motor dentro de soporte estándar SIEMPRE (Lambda
  runtimes, EKS N-2 como máximo, RDS con auto minor upgrade en ventana); el upgrade es trabajo
  planificado trimestral, no emergencia. Sin extended support pagado salvo decisión explícita.
- **LISTA DE PROHIBICIONES** (bloquean una review):
  - Access keys estáticas de IAM user en cualquier sitio (código, CI, `~/.aws` de servidores).
  - `0.0.0.0/0` en ingress sin justificación escrita; SSH/RDP públicos; recursos con IP pública
    innecesaria; VPC default en uso.
  - Recursos sin tags obligatorios; recursos creados por consola en prod (**clickops**) — todo
    por IaC; drift sin reconciliar.
  - S3 público o sin Block Public Access; datos sin cifrar; CMK sin rotación; secretos en código,
    env vars de texto plano en templates, o logs.
  - Desactivar CloudTrail/GuardDuty/Config; wildcard `*` en policies IAM; cuentas fuera de la
    organización.
  - Proponer servicios deprecados (lista sección 2); `latest` como tag de imagen en prod;
  - Logs sin retención definida; base de datos single-AZ en prod; backup sin restore probado.

## 9. Verificación web obligatoria

Antes de fijar en código o respuesta cualquier dato concreto de AWS, **buscar en la web** (docs
oficiales AWS primero): estado del servicio (lifecycle page), disponibilidad regional, versión de
runtime/motor soportada, límites y cuotas, precios, nombre exacto de APIs/flags (p. ej. Security
Hub v2 vs CSPM), y novedades re:Invent/re:Inforce del último año. La memoria del modelo NO es
fuente válida para: precios, fechas EOL, nombres de features recientes, disponibilidad regional.
Si no se puede verificar, decirlo explícitamente y marcar la decisión como provisional.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
