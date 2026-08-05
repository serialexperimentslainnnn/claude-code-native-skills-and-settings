---
name: kubernetes-standards
description: Kubernetes and container standards (staff/principal level). Use when writing or reviewing Dockerfiles/Containerfiles, OCI images, Kubernetes manifests (*.yaml with apiVersion/kind), Helm charts (Chart.yaml, values.yaml, templates/), Kustomize overlays (kustomization.yaml), GitOps configs (Argo CD Application, Flux Kustomization/HelmRelease), admission policies (Kyverno, OPA/Gatekeeper), image signing (cosign) or SBOM tooling.
---

# Estándares Kubernetes y contenedores

## 1. Alcance y triggers

Aplica al crear o revisar: `Dockerfile`/`Containerfile`, manifiestos K8s (`*.yaml` con `apiVersion`/`kind`), charts Helm (`Chart.yaml`, `templates/`), `kustomization.yaml`, recursos de Argo CD/Flux, políticas Kyverno/OPA, pipelines que construyen/firman/despliegan imágenes. No aplica a Compose local de desarrollo (usa criterio proporcional).

**No aplica**: ver `iac-standards` (aprovisionamiento del cluster y de la infraestructura con Terraform/OpenTofu y Ansible; la frontera se decide allí: **cluster y plataforma con TF/Tofu, workloads vía GitOps**), `aws-standards`/`azure-standards`/`gcp-standards` (el control plane gestionado —EKS/AKS/GKE—, su integración con IAM/VPC y su coste; aquí lo que corre dentro), `container-runtime-security-standards` (lo que pasa **después de que el Pod arranca**: seccomp, elección y pinning del runtime, escape de contenedor, detección en runtime con Falco/Tetragon/eBPF, drift y forense de nodo; aquí admisión, políticas Kyverno, Pod Security Standards, `securityContext` declarativo y firma verificada en admisión), `selinux-standards` (el MAC del contenedor: `container_t`, MCS, `:z`/`:Z`, `udica`, perfiles AppArmor), `networking-standards` (red física, VLAN, BGP y MTU subyacentes; aquí Services, Gateway API y NetworkPolicy), `cicd-standards` (la pipeline que construye y firma la imagen y dispara el despliegue; aquí el manifiesto resultante y la verificación en admisión), `observability-standards` (Prometheus, OTel Collector y sus reglas; aquí solo probes, recursos y el `ServiceMonitor`), `sre-practice-standards` (SLO, capacidad y on-call), `appsec-standards` (código de la aplicación), `vulnerability-management-standards` (triaje y SLA de los CVE que reporten Grype/Syft), `cryptography-pki-standards` (gestión de claves de firma y PKI interna; aquí solo el uso de cosign y cert-manager), `identity-access-management-standards` (IdP y federación; aquí RBAC del cluster y ServiceAccounts), `homelab-standards` y `onprem-standards` (k3s/Talos de un nodo y el hardware/SO por debajo), `air-gapped-standards` (**el registro/espejo interno y el aislamiento de red del clúster sin ruta a Internet son suyos**: cómo entra y se verifica la imagen dentro del recinto, el parcheo sin feeds, el tiempo y la PKI interna; aquí el clúster, su admisión y sus manifiestos), `finops-standards` (**Ola 6**: los `requests`/`limits`, el escalado y la programación son de aquí; **su coste y el reparto entre equipos que comparten nodo, suyos** — el problema de asignación en Kubernetes es real y lo resuelve su método), `platform-engineering-standards` (**Ola 6**: **el clúster y su operación son de aquí**; **la abstracción que se le ofrece encima al equipo de producto es suya** — si el desarrollador escribe YAML de Kubernetes a mano, la plataforma no ha hecho su trabajo, y esa es una decisión suya, no de esta skill), `webassembly-standards` (**Ola 5** — Wasm se vende a veces como sustituto del contenedor: **el runtime del nodo, la admisión, el aislamiento y la programación del workload siguen siendo de aquí**, incluidos los *shims* tipo runwasi/`containerd-shim-spin`; **el módulo Wasm, su host, sus importaciones y sus límites de combustible y memoria son suyos**. La frontera importa porque **el sandbox de Wasm no sustituye al aislamiento del nodo**: solo acota lo que el módulo puede pedir).

## 2. Toolchain por defecto

> **Verificación web obligatoria**: estas versiones se comprobaron en **agosto 2026**. Antes de fijar versiones en un proyecto real, re-verifica con WebSearch (releases oficiales + endoflife.date). No fijes de memoria.

| Herramienta | Línea estable (2026-08) | Criterio |
|---|---|---|
| Kubernetes | **1.36.x** (1.37 sale 2026-08-26); soportadas N-2: 1.34–1.36 | Nunca operar una minor fuera de soporte upstream/managed |
| Helm | **4.2.x** (Helm 3 EOL: fixes hasta 2026-09, seguridad hasta 2027-02) | Proyectos nuevos en Helm 4; planificar migración de charts v2 |
| Argo CD | **3.4.x** (3.5 en RC: mTLS interno, verificación de firma de commits) | Solo 3 minors reciben parches: mantén cadencia trimestral |
| Flux | **2.8.x** | Alternativa válida; elige uno por organización, no ambos |
| Kyverno | **1.18.x** | Admission por defecto (CEL + `ImageValidatingPolicy`); OPA/Gatekeeper solo si ya hay Rego |
| cosign | **3.x** (bundle format por defecto; v4 eliminará flags deprecados) | No usar flags deprecados de v2 en pipelines nuevos |
| **Grype + Syft** (imagen y SBOM), **checkov**/**kubescape** (manifiestos) | última estable | Default tras el **compromiso de cadena de suministro de Trivy (marzo 2026)**: tag poisoning de `trivy-action`/`setup-trivy` con robo de secretos de CI. Si usas Trivy, **pin por SHA/digest**, verifica firma y sigue sus advisories — el escáner corre en CI con acceso a secretos por diseño |

- **Ingress NGINX está retirado** (sin releases ni parches desde 2026-03-24): prohibido en despliegues nuevos; migra a Gateway API (Envoy Gateway, Cilium, ingress del proveedor).
- Gateway API sobre Ingress para tráfico norte-sur nuevo.

## 3. Estructura y convenciones

### Dockerfile / imagen OCI
- **Multi-stage siempre**: stage de build con toolchain completo, stage final mínimo. El artefacto final no contiene compiladores, shells de paquetes ni caches.
- **Base mínima**: distroless (`gcr.io/distroless/*`), chainguard o `scratch` para binarios estáticos. Alpine solo si necesitas shell y lo justificas.
- **Pin por digest** en la imagen base: `FROM registry/image:tag@sha256:...` (el tag es documentación; el digest es el contrato). Renovate/Dependabot actualiza los digests.
- **Non-root**: `USER` numérico (`USER 65532:65532`), nunca `USER app` (un nombre no verifica UID en admission).
- Un proceso por contenedor; `ENTRYPOINT` en forma exec (`["binario"]`), señales bien propagadas (PID 1 correcto o tini).
- `.dockerignore` obligatorio; sin secretos en build args ni en capas (usa `--mount=type=secret` de BuildKit).
- Etiquetas OCI (`org.opencontainers.image.source|revision|version`) para trazabilidad.

Esqueleto canónico:

```dockerfile
FROM golang:1.24-bookworm@sha256:<digest> AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/app

FROM gcr.io/distroless/static-debian12:nonroot@sha256:<digest>
COPY --from=build /out/app /app
USER 65532:65532
ENTRYPOINT ["/app"]
```

### Manifiestos K8s (todo workload de prod)
- **`resources.requests` y `limits` siempre**: requests realistas (base de scheduling y HPA); limit de memoria = request (evita OOM sorpresa); limit de CPU opcional y justificado (throttling).
- **Probes**: `readinessProbe` obligatoria; `livenessProbe` solo si el proceso puede colgarse sin morir (mal usada mata pods sanos); `startupProbe` para arranques lentos.
- **`securityContext` explícito** (pod y contenedor): `runAsNonRoot: true`, `readOnlyRootFilesystem: true` (+ `emptyDir` para tmp), `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`.
- **Pod Security Standards `restricted`** aplicado por namespace (labels `pod-security.kubernetes.io/enforce: restricted`); excepciones documentadas por workload, nunca `privileged` a nivel de namespace de apps.
- **PDB** para todo Deployment/StatefulSet con >1 réplica (`maxUnavailable: 1` como default sano). Sin PDB, un drain de nodo es un incidente.
- **NetworkPolicy default-deny** (ingress y egress) por namespace + allowlist explícita por flujo. DNS (53/UDP+TCP hacia kube-dns) es la única salida implícita permitida.
- `topologySpreadConstraints` o anti-affinity multi-AZ para réplicas; `priorityClassName` definida.
- ≥2 réplicas en prod; HPA sobre métricas reales, no solo CPU si el cuello es otro.
- Prohibido `:latest` y tag mutable en `image:`; prohibido `imagePullPolicy: Always` como parche de tags mutables.

`securityContext` canónico de contenedor (el default, no la excepción):

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities: { drop: ["ALL"] }
  seccompProfile: { type: RuntimeDefault }
```

NetworkPolicy default-deny base por namespace (ingress+egress, DNS permitido):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny }
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
  egress:
    - to: [{ namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: kube-system } } }]
      ports: [{ port: 53, protocol: UDP }, { port: 53, protocol: TCP }]
```

### Helm / Kustomize
- **Helm** para software distribuible/parametrizable; **Kustomize** para overlays de entorno propios. Patrón recomendado: chart base + overlays por entorno, o valores por entorno en Git (`values-<env>.yaml`).
- Charts: `values.yaml` con defaults seguros (el chart renderiza seguro sin overrides), `values.schema.json` obligatorio, `helm-docs` para README, versionado SemVer del chart independiente de `appVersion`.
- Nada de lógica compleja en templates: si necesitas más de un `if/range` anidado, sube la decisión a values o a un helper.
- Charts publicados en **registry OCI** (no repos HTTP legacy), firmados con cosign.

### GitOps (Argo CD / Flux)
- **Git es la única vía a prod**: todo cambio de estado del cluster pasa por PR. `kubectl apply`/`edit`/`scale` manual contra prod está prohibido salvo break-glass documentado (y se reconcilia después).
- Patrón **app-of-apps** (Argo) o `Kustomization` jerárquica (Flux); un repo/dir de "deploy" separado del código de la app (o directorio dedicado con CODEOWNERS).
- `syncPolicy.automated` con `prune: true` y `selfHeal: true` en entornos no productivos; en prod, auto-sync solo con gates (health checks + ventanas) o sync manual aprobado — decisión explícita por organización.
- Drift = alerta: `selfHeal` o notificación, nunca drift silencioso.
- Promoción entre entornos = promoción del **mismo digest de imagen** por Git (image updater o PR automatizado), jamás rebuild por entorno.

## 4. Calidad y testing (gates de CI)

Pipeline mínimo que **rompe el build**:
1. **Lint**: `hadolint` (Dockerfile), `yamllint`, `helm lint` + render (`helm template` sin errores), `kustomize build` de cada overlay.
2. **Validación de esquema**: `kubeconform` (con CRDs schemas) sobre el YAML renderizado de **todos** los entornos.
3. **Políticas en CI (shift-left)**: `kyverno apply` / `conftest` con las mismas políticas del admission del cluster — lo que rompe en admission debe romper antes en CI.
4. **Tests de charts**: `helm unittest` para lógica de templates; `chart-testing` (`ct lint`/`ct install`) contra kind/k3d en PRs de charts.
5. **Escaneo**: **Grype + Syft** sobre imagen (CVEs y SBOM, gate en CRITICAL/HIGH con triaje documentado) y **checkov**/**kubescape** sobre manifiestos — no Trivy por defecto (§2), y si se usa, pineado por digest y con sus advisories seguidos. Secret scanning: el escáner y su licencia los fija `secrets-management-standards` (a ago-2026 `gitleaks` está *feature complete* y su action de GitHub exige licencia comercial para organizaciones: verifica antes de fijarlo).
6. **Diff visible en PR**: render del YAML resultante (argocd diff / flux diff / helm diff) como comentario — se revisa lo que se va a aplicar, no solo el template.

## 5. Seguridad

### Cadena de suministro
- **Firma con cosign (keyless, OIDC del CI)** de toda imagen y chart que llega a prod; **verificación en admission** (Kyverno `ImageValidatingPolicy`/verifyImages): imagen sin firma válida no se ejecuta.
- **SBOM** (syft, formato SPDX o CycloneDX) generado en build, adjunto como attestation (`cosign attest`), no como fichero suelto.
- Procedencia SLSA (provenance attestation del builder) verificada donde el registry/CI lo soporte.
- Registry privado con pull-through cache; prohibido pull directo de Docker Hub en prod (rate limits + supply chain).
- Renovate/Dependabot para bases e imágenes: actualizar digest es un PR, no un evento manual.

### Runtime y cluster
- Admission con Kyverno en modo `Enforce` para el baseline (non-root, no privileged, digests, registries permitidos, requests/limits, probes); `Audit` solo como fase de introducción, con fecha de paso a Enforce.
- RBAC mínimo: nada de `cluster-admin` para humanos ni ServiceAccounts de apps; `automountServiceAccountToken: false` salvo necesidad.
- **Secretos nunca en claro en Git**: External Secrets Operator contra Vault/Secrets Manager (preferido) o SOPS+age si no hay gestor. Prohibido `Secret` en YAML plano o en values de Helm sin cifrar.
- Cifrado de Secrets at-rest en etcd (KMS provider) y mTLS este-oeste (mesh o Cilium) donde el perfil de riesgo lo pida.

## 6. Operabilidad

- **Observabilidad no negociable**: métricas Prometheus (`/metrics`), logs estructurados JSON a stdout, trazas OTLP. Sin telemetría, no hay despliegue en prod.
- Health endpoints reales: readiness refleja dependencias críticas (con criterio: no tumbar el pod por una dependencia degradada que tiene fallback).
- **Despliegue seguro**: rolling update con `maxUnavailable: 0` como default; canary/blue-green (Argo Rollouts o Flagger) para servicios críticos, con análisis automático sobre métricas.
- **Rollback probado**: `helm rollback`/revert de Git ensayado en staging; una migración de datos incompatible hacia atrás bloquea el rollback — usa expand/contract.
- `terminationGracePeriodSeconds` acorde al drain real de la app; la app maneja SIGTERM.
- Alertas sobre síntomas (golden signals) + estado GitOps (app OutOfSync/Degraded, reconcile fallido), no sobre cada restart.

## 7. Sostenibilidad y prohibiciones

- **Cadencia de upgrades**: K8s publica 3 minors/año y soporta N-2 → planifica **mínimo 2 upgrades de minor al año**; nunca más de una minor por detrás del soporte del proveedor gestionado. Antes de subir: leer deprecations (`kubectl api-resources`, Pluto para APIs retiradas), actualizar charts/operadores, ensayar en staging.
- Argo CD/Flux/Kyverno: mantente dentro de las 3 minors soportadas (cadencia trimestral de revisión).
- Renueva imágenes base aunque la app no cambie (rebuild programado semanal/mensual: los CVEs llegan solos).

**PROHIBIDO** (gate automático donde sea posible):
- `:latest` o tags mutables en prod; imágenes sin digest.
- `kubectl apply`/`edit`/`scale`/`port-forward` manual contra prod fuera de break-glass documentado.
- Contenedores root, `privileged`, `hostNetwork`/`hostPID`/`hostPath` sin excepción firmada.
- Secretos en claro en Git, en values, en env del manifiesto o en logs.
- Workloads sin requests/limits, sin readiness probe o sin PDB (multi-réplica) en prod.
- Namespaces de apps sin NetworkPolicy default-deny ni PSS `restricted`.
- Imagen sin firmar o sin SBOM en el camino a prod.
- Ingress NGINX en despliegues nuevos (proyecto retirado, sin parches de seguridad).
- Helm 2/3 en proyectos nuevos; charts sin `values.schema.json`.
- Drift tolerado: recursos en el cluster que no existen en Git.

### Checklist de revisión rápida (todo PR de workload a prod)

- [ ] Imagen por digest, firmada, con SBOM; base distroless/mínima y non-root numérico.
- [ ] requests/limits, readiness probe, PDB (si >1 réplica), topología multi-AZ.
- [ ] securityContext restricted completo; namespace con PSS `restricted` + NetworkPolicy default-deny.
- [ ] Sin secretos en claro; ServiceAccount dedicada con RBAC mínimo y token no montado si no se usa.
- [ ] Render validado (kubeconform) + políticas de admission pasadas en CI; diff del YAML visible en el PR.
- [ ] Métricas/logs/trazas expuestos; SIGTERM manejado; rollback ensayado o plan expand/contract si hay migración.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, API (`apiVersion`), flag o feature en entregables:
1. **WebSearch/WebFetch** de la release oficial y endoflife.date del componente (K8s, Helm, Argo CD/Flux, Kyverno, cosign) — el ecosistema rota cada trimestre y este documento envejece.
2. Verifica deprecations de API de K8s del salto de versión objetivo (release notes oficiales + Pluto).
3. Cosign: confirma si v4 ya salió (elimina flags deprecados de v3) antes de escribir pipelines de firma.
4. Si no puedes verificar, dilo explícitamente en la entrega en lugar de suponer.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
