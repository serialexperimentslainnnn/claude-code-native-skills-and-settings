---
name: kubernetes-standards
description: Kubernetes and container standards (staff/principal level). Use when writing or reviewing Dockerfiles/Containerfiles, OCI images, Kubernetes manifests (*.yaml with apiVersion/kind), Helm charts (Chart.yaml, values.yaml, templates/), Kustomize overlays (kustomization.yaml), GitOps configs (Argo CD Application, Flux Kustomization/HelmRelease), admission policies (Kyverno, OPA/Gatekeeper), image signing (cosign) or SBOM tooling. Also for Windows nodes and Windows containers (Server Core, Nano Server, ltsc2022/ltsc2025 base images, host/image version compatibility, runAsUserName, HostProcess, gMSA and GMSACredentialSpec) and for batch scheduling on Kubernetes (job queues, gang scheduling, Kueue, Volcano, ResourceQuota).
---

# Estándares Kubernetes y contenedores

## 1. Alcance y triggers

Aplica al crear o revisar: `Dockerfile`/`Containerfile`, manifiestos K8s (`*.yaml` con `apiVersion`/`kind`), charts Helm (`Chart.yaml`, `templates/`), `kustomization.yaml`, recursos de Argo CD/Flux, políticas Kyverno/OPA, pipelines que construyen/firman/despliegan imágenes. No aplica a Compose local de desarrollo (usa criterio proporcional).

**No aplica**: ver `iac-standards` (aprovisionamiento del cluster y de la infraestructura con Terraform/OpenTofu y Ansible; la frontera se decide allí: **cluster y plataforma con TF/Tofu, workloads vía GitOps**), `aws-standards`/`azure-standards`/`gcp-standards` (el control plane gestionado —EKS/AKS/GKE—, su integración con IAM/VPC y su coste; aquí lo que corre dentro), `container-runtime-security-standards` (lo que pasa **después de que el Pod arranca**: seccomp, elección y pinning del runtime, escape de contenedor, detección en runtime con Falco/Tetragon/eBPF, drift y forense de nodo; aquí admisión, políticas Kyverno, Pod Security Standards, `securityContext` declarativo y firma verificada en admisión), `selinux-standards` (el MAC del contenedor: `container_t`, MCS, `:z`/`:Z`, `udica`, perfiles AppArmor), `networking-standards` (red física, VLAN, BGP y MTU subyacentes; aquí Services, Gateway API y NetworkPolicy), `cicd-standards` (la pipeline que construye y firma la imagen y dispara el despliegue; aquí el manifiesto resultante y la verificación en admisión), `observability-standards` (Prometheus, OTel Collector y sus reglas; aquí solo probes, recursos y el `ServiceMonitor`), `sre-practice-standards` (SLO, capacidad y on-call), `appsec-standards` (código de la aplicación), `vulnerability-management-standards` (triaje y SLA de los CVE que reporten Grype/Syft), `cryptography-pki-standards` (gestión de claves de firma y PKI interna; aquí solo el uso de cosign y cert-manager), `identity-access-management-standards` (IdP y federación; aquí RBAC del cluster y ServiceAccounts), `homelab-standards` y `onprem-standards` (k3s/Talos de un nodo y el hardware/SO por debajo), `air-gapped-standards` (**el registro/espejo interno y el aislamiento de red del clúster sin ruta a Internet son suyos**: cómo entra y se verifica la imagen dentro del recinto, el parcheo sin feeds, el tiempo y la PKI interna; aquí el clúster, su admisión y sus manifiestos), `finops-standards` (los `requests`/`limits`, el escalado y la programación son de aquí; **su coste y el reparto entre equipos que comparten nodo, suyos** — el problema de asignación en Kubernetes es real y lo resuelve su método), `platform-engineering-standards` (**el clúster y su operación son de aquí**; **la abstracción que se le ofrece encima al equipo de producto es suya** — si el desarrollador escribe YAML de Kubernetes a mano, la plataforma no ha hecho su trabajo, y esa es una decisión suya, no de esta skill), `windows-server-ad-standards` (**la cuenta gMSA en el directorio es suya**: KDS root key, `New-ADServiceAccount`, `PrincipalsAllowedToRetrieveManagedPassword`, SPN, unión del nodo al dominio; **su consumo desde el Pod —CRD, RBAC y `gmsaCredentialSpecName`— es de aquí**), `dotnet-framework-legacy-standards` (si la app se puede portar a .NET moderno y a qué coste: esa decisión es suya y **manda sobre la de contenerizar**; aquí solo cómo se ejecuta el contenedor Windows si la respuesta es que no se porta) y `legacy-modernization-standards` (la estrategia rehost/replatform/rewrite del monolito), `hpc-standards` (**el criterio de cuándo el batch no debe correr en Kubernetes y se queda en Slurm es suyo**; aquí las colas y el gang scheduling *dentro* del clúster) y `gpu-computing-standards`/`mlops-standards` (la GPU, su device plugin y el pipeline de entrenamiento; aquí cómo se encola y se programa el lote), `webassembly-standards` (Wasm se vende a veces como sustituto del contenedor: **el runtime del nodo, la admisión, el aislamiento y la programación del workload siguen siendo de aquí**, incluidos los *shims* tipo runwasi/`containerd-shim-spin`; **el módulo Wasm, su host, sus importaciones y sus límites de combustible y memoria son suyos**. La frontera importa porque **el sandbox de Wasm no sustituye al aislamiento del nodo**: solo acota lo que el módulo puede pedir).

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

### Nodos y contenedores Windows

Todo lo anterior asume Linux. En un nodo Windows **los invariantes canónicos de §3 no se degradan: son inaplicables o falsos**, y el modo de fallo caro es que el manifiesto los declare, pase admisión y no proteja nada. Escenario típico: monolito .NET Framework sobre IIS que se contenerizan sin poder portarse.

**Compatibilidad host↔imagen (la regla dura).** La build del SO del host y la de la imagen base **deben coincidir**; solo las revisiones (4.º dígito) pueden diferir desde 1809 en adelante. Microsoft ofrece Hyper-V isolation como escape para versiones dispares, pero **Kubernetes no lo soporta** ("Kubernetes does not support running Windows containers with Hyper-V isolation") — en un clúster ese escape **no existe**: la imagen simplemente no arranca (`0xc0370101`, `ContainerCannotRun` → `CrashLoopBackOff`).

| Host | Imágenes que arrancan en K8s (process isolation) |
|---|---|
| Windows Server 2025 | ltsc2025, ltsc2022 |
| Windows Server 2022 | ltsc2022 |
| Windows Server 2019 | ltsc2019 (pero WS2019 ya no es nodo soportado) |

- **Kubernetes 1.36 soporta como nodo Windows Server 2022 y 2025, nada más.** WS2022 sale de mainstream el **2026-10-14** (extended hasta 2031-10-15) y *"Containers released with Windows Server 2022 follow the same lifecycle dates"* → nodo e imagen nuevos van a **ltsc2025**; un nodo WS2022 hoy nace con dos meses de vida útil de soporte pleno.
- Etiqueta automática `node.kubernetes.io/windows-build`: **WS2022 = `10.0.20348`**, **WS2025 = `10.0.26100`**. Con dos versiones de Windows en el clúster es obligatoria en el `nodeSelector`, no opcional.

**Imagen base: no hay distroless, ni `scratch`, ni nada parecido.** Tamaños medidos sobre los manifiestos de MCR (comprimido en registry, ago-2026):

| Imagen | Tamaño | Qué trae |
|---|---|---|
| `windows/nanoserver:ltsc2025` | **0,19 GB** | Sin PowerShell, sin WMI, **sin servicing stack, sin .NET Framework**. Solo .NET moderno |
| `windows/servercore:ltsc2025` | **2,3 GB** | La **única** que ejecuta .NET Framework e IIS |
| `windows/server:ltsc2025` | **6,55 GB** | API completa, GPU, sin límite de conexiones IIS. Solo si Server Core no llega |

- Un monolito IIS **va a Server Core**: es un dato de la plataforma, no una elección. Parte de `mcr.microsoft.com/dotnet/framework/aspnet:4.8.1-windowsservercore-ltsc2025` en vez de instalar IIS a mano.
- Sin tag `latest` desde 2019-04-16 en estas imágenes; el pin por digest de §3 aplica igual, y ahora pesa 12-30× más en pull y en disco de nodo.
- **Un proceso por contenedor no se cumple**: Server Core arranca el Service Control Manager y IIS corre como servicio (`w3wp`). No lo intentes forzar; monitoriza el servicio, no el PID 1.
- **`USER 65532:65532` es imposible**: Windows no tiene UID/GID, la identidad es un SID. El equivalente es `USER ContainerUser` en el Dockerfile o `securityContext.windowsOptions.runAsUserName` en el Pod (`ContainerUser`, `ContainerAdministrator`, `NT AUTHORITY\NETWORK SERVICE`…).
- **El usuario por defecto no es non-root**: verificado sobre el config blob en MCR, `servercore` y `windows/server` **no fijan `USER`** → el proceso corre como `ContainerAdministrator`; solo `nanoserver` fija `USER ContainerUser` (ltsc2022 y ltsc2025). Es decir, **la imagen que necesita el monolito IIS es exactamente la que arranca como administrador**: fijar `runAsUserName` es obligatorio, no higiene.

**`securityContext` que se ignora en silencio — el fallo peligroso.** Con `.spec.os.name: windows`, el API server **rechaza** el Pod que fije `hostPID`, `hostIPC`, `shareProcessNamespace`, `seLinuxOptions`, `seccompProfile`, `fsGroup`, `fsGroupChangePolicy`, `sysctls`, `supplementalGroups`, `runAsUser`, `runAsGroup`, `capabilities`, `readOnlyRootFilesystem`, `privileged`, `allowPrivilegeEscalation` o `procMount`. **Sin `.spec.os.name`, el mismo manifiesto se admite y esos campos no hacen absolutamente nada.** El `securityContext` canónico de §3 sobre un nodo Windows pasa CI, pasa admisión, pasa la checklist — y da cero protección.

- → **`.spec.os.name` es obligatorio en todo Pod** (`windows` y también `linux`): es el único mecanismo que convierte ese silencio en un rechazo. Gate de Kyverno para exigirlo.
- A nivel de Pod solo funcionan `securityContext.runAsNonRoot` y `securityContext.windowsOptions`. Aquí `runAsNonRoot: true` significa "no `ContainerAdministrator`", no "UID≠0".
- `readOnlyRootFilesystem` **no es implementable** en Windows ("write access is required"): no lo pidas, no lo audites, no lo pongas en la excepción.
- **PSS `restricted` deja de aplicar la mitad**: privilege escalation, seccomp y capabilities son controles *Linux only* desde 1.25 (`spec.os.name != windows`). Lo que queda vivo: `runAsNonRoot`, no HostProcess, no host namespaces, no hostPath. Un namespace mixto etiquetado `restricted` **no significa lo mismo para cada mitad** — documenta qué controla de verdad en cada una.
- **No hay contenedores privilegiados en Windows**; el equivalente es **HostProcess** (`windowsOptions.hostProcess: true`, estable desde 1.26), que corre en el host con sus privilegios. Trátalo como `privileged`: prohibido salvo excepción firmada para agentes de nodo.

**Programación en clúster mixto.**
- `nodeSelector: kubernetes.io/os: windows` en todo workload Windows; `.spec.os.name` **no afecta a la programación**.
- **Taint en los nodos Windows** (`--register-with-taints='os=windows:NoSchedule'`) + toleration en el Pod. Sin taint, cualquier Deployment de Linux sin selector aterriza en un nodo Windows.
- **Un DaemonSet de Linux sin `nodeSelector` se rompe por definición**: un DaemonSet va a *todos* los nodos que toleren sus taints, y muchos agentes (CNI, logs, node-exporter, escáner de runtime, CSI) traen tolerations amplias que anulan el taint. **Revisa todos los DaemonSets del clúster antes de añadir el primer nodo Windows**, no después del incidente.
- `RuntimeClass` con `scheduling.nodeSelector` + `tolerations` encapsula el par cuando hay muchos workloads.
- El kubelet en Windows **no impone límites de memoria ni CPU**: `--kube-reserved`/`--system-reserved` solo restan de `NodeAllocatable`, `PIDPressure` no está implementado y no hay desalojo por OOM. Los `limits` no protegen el nodo como en Linux → dimensiona con holgura y alerta sobre memoria **del nodo**. Tampoco hay `kubectl exec` completo, métricas de pod, HPA, ResourceQuota ni preemption del scheduler con la misma semántica: no des por hecho ninguna pieza de §6 sin comprobarla en Windows.

**gMSA: identidad de dominio del Pod** (lo que casi siempre necesita un monolito IIS para autenticación integrada contra AD).
- CRD `GMSACredentialSpec`, grupo `windows.k8s.io`, **`apiVersion: windows.k8s.io/v1`** (`v1alpha1` deprecada y no-storage), más los dos webhooks de `kubernetes-sigs/windows-gmsa` (**v0.13.0**, Apache-2.0, verificado en crudo): uno *mutating* que expande el nombre al credspec completo, uno *validating* que comprueba la autorización.
- Autorización = RBAC sobre el credspec: `apiGroups: ["windows.k8s.io"]`, `resources: ["gmsacredentialspecs"]`, `verbs: ["use"]`, `resourceNames: [<credspec>]`, bindeado a la ServiceAccount del workload. Sin ese binding el webhook rechaza. **Un credspec por aplicación**, nunca uno compartido: es una identidad de dominio, no un ConfigMap.
- Consumo: `securityContext.windowsOptions.gmsaCredentialSpecName`, a nivel de Pod o de contenedor.
- **La contraseña nunca está en el clúster**: la recupera el **nodo** de Active Directory. Consecuencia de diseño: el nodo Windows es un principal de dominio y **cualquier pod autorizado en ese nodo actúa como la cuenta de servicio** — el compromiso del nodo es compromiso de la cuenta. Un nodo Windows unido al dominio dentro de un clúster multi-tenant es una decisión de riesgo, no un detalle de instalación.
- Frontera: la cuenta en el directorio es de `windows-server-ad-standards` (§1).

**Parcheo acoplado (impacto operativo real).** La imagen base Windows **no tiene servicing stack**: no se parchea dentro, se **reconstruye**. Microsoft republica las bases el **segundo martes de cada mes** ("B release") y esa es *"the only regular release that include new security fixes"*.
- **Rebuild mensual obligatorio** de toda imagen Windows aunque la app no cambie, alineado con el ciclo B — no "cuando toque". El rebuild programado de §7 aquí tiene fecha fija impuesta desde fuera.
- El host se parchea en la misma ventana y con la misma cadencia: **el calendario de parcheo del nodo manda sobre el de despliegue de la app**, al revés que en Linux.
- Host e imagen no necesitan la misma revisión (1809+), pero sí la misma build. Un upgrade de nodo WS2022→WS2025 obliga a reconstruir **todas** las imágenes a ltsc2025 antes, no después.

**Cuándo NO contenerizar Windows** (criterio honesto, se decide antes de escribir el Dockerfile):
- Instalador interactivo, GUI, drivers, acceso a hardware o al registro del host, o estado local que debe sobrevivir al reinicio → **VM**. No hay atajo.
- Si el destino real es .NET moderno: **portar a .NET 8+ y contenedor Linux suele ser menos trabajo total** que contenerizar el Framework, y el resultado sí obtiene los invariantes de §3 (distroless, non-root, read-only, PSS íntegro). Esa comparación la decide `dotnet-framework-legacy-standards`.
- Si no hay ya nodos Windows en producción, el coste no es la imagen: es un **segundo pool de nodos** con licencias, parcheo mensual acoplado, imágenes de 2-6,5 GB, y todo el ecosistema de DaemonSets, observabilidad y seguridad duplicado y verificado en Windows. Para 1-3 aplicaciones rara vez sale.
- Una app que se despliega dos veces al año no gana nada de Kubernetes: lo que se gana es escalado y despliegue frecuente. Si no los necesitas, la VM es más barata y más simple.
- Contenerizar Windows es válido como **paso intermedio con fecha de salida**, no como destino permanente. Si no hay fecha, es una VM cara con más piezas.

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

### Colas batch y gang scheduling

Todo §6 asume servicios de larga vida. Para lotes (entrenamiento distribuido, simulación, ETL masivo) el clúster **no trae lo que hace falta** y hay que añadirlo explícitamente.

**Lo que el scheduler por defecto no hace.** `kube-scheduler` *"selects an optimal node to run newly created or not yet scheduled (unscheduled) pods"* en dos fases, *filtering* y *scoring*, y asigna **Pod a Pod**. No hay cola de trabajos, no hay prioridad de servicio entre lotes, no hay semántica de grupo: ni la doc del scheduler ni la de `Job` mencionan gang, encolado ni all-or-nothing.

**Qué rompe eso.** Un job que necesita sus N pods **a la vez** (entrenamiento sincronizado, MPI, cualquier cosa con comunicación pod-a-pod) puede quedarse con N-1 pods corriendo y ocupando recursos, esperando indefinidamente al último. Con dos jobs así compitiendo, cada uno bloquea al otro: **deadlock de recursos**. Verbatim de la doc de Kueue: *"a pair of such jobs may deadlock if the physical availability of resources do not match the configured quotas in Kueue. The same pair of jobs could run to completion if their pods were scheduled sequentially."* Nadie lo detecta ni lo rompe: la señal es utilización baja con pods `Pending` eternos y un clúster que "está lleno". Fuera de un test de carga real no aparece; en producción, sí.

**`ResourceQuota`/`LimitRange` no son la solución** y confundirlos con ella es el error habitual. `ResourceQuota` *"provides constraints that limit aggregate resource consumption per namespace"*, y al violarse *"the control plane rejects that request with HTTP status code `403 Forbidden`"*: es **rechazo en admisión, no encolado** — sin orden de servicio, sin reintento, sin "entra cuando haya sitio". Además actúa objeto a objeto, así que nada impide admitir N-1 pods del job y rechazar el último. `LimitRange` solo fija defaults y mín/máx por objeto. Son barandillas de consumo; **no son un planificador**.

`schedulingGates` (Pod Scheduling Readiness, **GA en 1.30**) y `Job.spec.suspend` son los *ganchos* sobre los que se construye un gestor de colas — retienen pods u objetos individuales para que decida un integrador externo. No aportan semántica de grupo por sí mismos.

**Las dos opciones reales** (verificado ago-2026; ambas Apache-2.0 leído en crudo):

| | **Kueue** | **Volcano** |
|---|---|---|
| Qué es | Gestor de colas **a nivel de job** sobre el scheduler por defecto | **Scheduler batch completo**, sustituto/añadido al por defecto |
| Versión | **v0.19.0** (2026-07-22) | **v1.15.1** (2026-07-30) |
| Gobernanza | `kubernetes-sigs`, **subproyecto oficial de SIG Scheduling** | **CNCF Incubating** (aceptado 2020-04-09, incubating 2022-03-21) |
| API | `kueue.x-k8s.io/**v1beta2**` (v1beta1 deprecada, no-storage). **No hay v1 GA** | `scheduling.volcano.sh/v1beta1` (PodGroup, Queue) y `batch.volcano.sh/**v1alpha1**` (Job) |
| CRDs | ClusterQueue, Cohort, AdmissionCheck, Topology (cluster) · LocalQueue, Workload (namespaced) | PodGroup (ns), Queue (cluster), Job (ns) |
| All-or-nothing | `waitForPodsReady` en la Configuration del controlador | plugin `gang` sobre `PodGroup.minMember`/`minResources` |
| Requisito | K8s ≥ 1.29 | — |

- **Kueue** suspende y encola el Workload hasta que hay cuota; `waitForPodsReady` (timeout 30 min por defecto, `recoveryTimeout`, `requeuingStrategy` con backoff) desaloja y reencola el job si no arrancan todos sus pods. Con `blockAdmission: true` admite **secuencialmente** para romper el deadlock — a costa de serializar arranques aunque haya sitio de sobra. Es una mitigación, no gang scheduling estricto.
- **Volcano** sí hace gang de verdad: `minMember` — *"if there's not enough resources to start all tasks, the scheduler will not start anyone"* — más fair-share entre `Queue`s y políticas de planificación (binpack, NUMA, topología). El precio: **un segundo scheduler en el clúster** y una API de Job todavía en `v1alpha1` pese a los años en incubación. Pésalo.
- **Criterio**: si lo que falta son **colas, cuotas por equipo y admisión de jobs**, Kueue (mantienes un solo scheduler y encaja con `Job`, JobSet y los operadores de entrenamiento). Si necesitas **gang estricto y políticas de planificación**, Volcano. **Uno por organización, no los dos**: dos planificadores decidiendo sobre el mismo pool de nodos es un incidente esperando; si conviven, particiona por taints y sé explícito sobre qué nodos administra cada uno.
- **JobSet** (`jobset.x-k8s.io/v1alpha2`, v0.12.0, sig-apps) agrupa varios `Job` como unidad para HPC/ML. Sigue en **alpha**: complementa a Kueue, no lo sustituye.
- **Prohibido simular gang a mano**: `initContainers` que esperan a sus compañeros, `podAffinity` creativa o sleeps de arranque son el mismo deadlock con más pasos y sin observabilidad.

**Cuándo la respuesta correcta es no usar Kubernetes.** Si el lote es HPC clásico —MPI apretado, interconexión de baja latencia, reserva de nodos enteros, contabilidad por horas·CPU, usuarios que envían con `sbatch`— **la respuesta suele ser Slurm, no un clúster de Kubernetes con dos operadores encima**. Ese criterio es de `hpc-standards` y se consulta allí antes de montar nada aquí. La frontera práctica: si lo que ya tienes vive en Kubernetes y lo único que falta son colas, Kueue/Volcano; si lo que tienes es un centro de cálculo, no lo reimplementes en YAML.

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
- Clúster mixto Linux/Windows con Pods sin `.spec.os.name`, sin `nodeSelector` de `kubernetes.io/os` o con nodos Windows sin taint; DaemonSet de Linux sin selector tras añadir el primer nodo Windows.
- Dar por buena la protección de un `securityContext` de Linux (seccomp, capabilities, `readOnlyRootFilesystem`, `allowPrivilegeEscalation`) en un workload Windows: no protege, se ignora.
- Imagen Windows sin rebuild mensual alineado con la "B release"; imagen base cuya build no coincide con la del nodo.
- Gang scheduling simulado con `initContainers`, afinidades o esperas; dos schedulers batch sobre el mismo pool de nodos sin particionar.

### Checklist de revisión rápida (todo PR de workload a prod)

- [ ] Imagen por digest, firmada, con SBOM; base distroless/mínima y non-root numérico.
- [ ] requests/limits, readiness probe, PDB (si >1 réplica), topología multi-AZ.
- [ ] securityContext restricted completo; namespace con PSS `restricted` + NetworkPolicy default-deny.
- [ ] Sin secretos en claro; ServiceAccount dedicada con RBAC mínimo y token no montado si no se usa.
- [ ] Render validado (kubeconform) + políticas de admission pasadas en CI; diff del YAML visible en el PR.
- [ ] Métricas/logs/trazas expuestos; SIGTERM manejado; rollback ensayado o plan expand/contract si hay migración.
- [ ] Si es Windows: `.spec.os.name: windows`, `nodeSelector`+toleration, build de la imagen igual a la del nodo (`node.kubernetes.io/windows-build`), `runAsUserName` fijado, sin campos de `securityContext` de Linux, y rebuild mensual planificado.
- [ ] Si es batch multi-pod: gestor de colas (Kueue o Volcano) declarado y semántica all-or-nothing configurada — no `ResourceQuota` como sustituto.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, API (`apiVersion`), flag o feature en entregables:
1. **WebSearch/WebFetch** de la release oficial y endoflife.date del componente (K8s, Helm, Argo CD/Flux, Kyverno, cosign) — el ecosistema rota cada trimestre y este documento envejece.
2. Verifica deprecations de API de K8s del salto de versión objetivo (release notes oficiales + Pluto).
3. Cosign: confirma si v4 ya salió (elimina flags deprecados de v3) antes de escribir pipelines de firma.
4. **Windows**: re-verifica en MS Learn (`version-compatibility`, `container-base-images`, `update-containers`) la matriz host↔imagen y el lifecycle antes de elegir base — es donde más información caducada circula. Comprueba en `kubernetes.io/docs/concepts/windows/intro` qué versiones de Windows Server son nodo soportado en tu minor de K8s (a 1.36: **solo 2022 y 2025**) y si la lista de campos de `securityContext` no soportados ha cambiado. **WS2022 sale de mainstream el 2026-10-14**: a partir de esa fecha esta tabla ya no describe una opción viable para nodos nuevos. Los tamaños de imagen se midieron sobre los manifiestos de MCR en ago-2026 y cambian cada "B release": vuelve a medirlos (`/v2/<img>/manifests/<tag>` → suma de `layers[].size`), no los cites de aquí.
5. **Batch**: re-verifica versión y madurez de **Kueue** (¿sigue en `v1beta2` o ya hay `v1` GA?) y de **Volcano** (¿sigue Incubating en CNCF o ha graduado? ¿su `Job` sigue en `v1alpha1`?), y el estado de **JobSet** (alpha a ago-2026). Contrasta la web oficial del proyecto con `api.github.com`, no con el feed de releases.
6. Si no puedes verificar, dilo explícitamente en la entrega en lugar de suponer.

**Huecos declarados (ago-2026), pendientes de verificar antes de usarlos como dato**:
- Los tamaños en disco (descomprimidos) de las imágenes Windows **no se midieron**: las cifras de la tabla son el comprimido del registry. En disco de nodo son sensiblemente mayores.
- La página oficial de instalación de Kueue (`kueue.sigs.k8s.io/docs/installation/`) **no se pudo obtener**: v0.19.0 está respaldado por `api.github.com` + feed Atom + fuente del repo en el tag, pero **sin confirmación desde la web del proyecto**.
- De los CRDs de Kueue se leyeron los manifiestos de ClusterQueue, AdmissionCheck, Topology y Workload; **`LocalQueue` y `ResourceFlavor` se asumen con el mismo patrón `v1beta1` deprecada / `v1beta2` storage por extrapolación**, no por lectura directa.
- De la Volcano `Job` se confirmó grupo, kind y versión `v1alpha1`, pero **no los booleanos `served`/`storage`** del manifiesto. La cadena `Job.minAvailable` → `PodGroup.minMember` es inferencia razonada: el CRD no documenta ese campo.
- El TAG de la CNCF al que pertenece Volcano **no se verificó** contra fuente primaria actual.
- La versión **v0.13.0** de `windows-gmsa` viene de `api.github.com`; el proyecto no publica una web propia con la que contrastarla.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
