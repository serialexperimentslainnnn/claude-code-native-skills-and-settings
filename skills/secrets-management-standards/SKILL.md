---
name: secrets-management-standards
description: Secrets lifecycle for already-generated credentials. Use when working with HashiCorp Vault or OpenBao (policies, dynamic secrets, seal/unseal, vault or bao CLI), Infisical, Bitwarden Secrets Manager, consuming AWS Secrets Manager, Azure Key Vault or GCP Secret Manager, External Secrets Operator (ExternalSecret, ClusterSecretStore), Secrets Store CSI Driver, sealed-secrets, SOPS with age, systemd LoadCredential= and systemd-creds, gitleaks, betterleaks or trufflehog scans, .gitleaks.toml, responding to a leaked credential, rotation runbooks, or replacing a static credential with short-lived federated identity.
---

# Estándares de gestión de secretos

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **ciclo de vida operativo de los secretos ya generados**: decisión y despliegue del
gestor, modelado de rutas y políticas, secretos dinámicos con TTL, mecanismo de inyección en
el consumidor (fichero, API, credencial de systemd, operador de Kubernetes), rotación
automática y su prueba, respuesta a la exposición de un secreto, detección de secretos en
código e historial, cifrado de secretos cuando deben vivir en el repositorio, secretos en
imágenes, capas de contenedor, artefactos de build, logs y backups, auditoría y mínimo
privilegio sobre el propio gestor, HA/sellado y comportamiento ante su caída, y la separación
entre secretos de humanos y secretos de máquinas.

Triggers: `vault`/`bao` CLI, `vault.hcl`, políticas HCL, `bao operator unseal`,
`ExternalSecret`/`ClusterSecretStore`/`PushSecret`, `SecretProviderClass`, `SealedSecret`,
`.sops.yaml`, `sops -e`, `age`/`age-keygen`, `LoadCredential=`/`LoadCredentialEncrypted=`/
`systemd-creds`, `.gitleaks.toml`/`.gitleaksignore`, `gitleaks detect`, `trufflehog git`,
`bws`, `infisical run`, `aws secretsmanager get-secret-value`, `az keyvault secret show`,
`gcloud secrets versions access`, "rotar credencial", "secreto filtrado", "push protection".

**Principio rector**: **el mejor secreto es el que no existe**. Antes de guardar una
credencial, el trabajo es **eliminarla**: identidad federada de vida corta (OIDC del CI hacia
la nube, workload identity del proveedor, SPIFFE/SPIRE entre servicios) sustituye al secreto
estático sin custodia, sin rotación y sin riesgo de filtración. El gestor de secretos es para
**lo que no se puede eliminar**, y su objetivo real no es ser una caja fuerte de contraseñas
eternas, sino **emitir credenciales dinámicas con TTL corto**. Corolario: una arquitectura
con muchos secretos guardados no es una arquitectura bien custodiada, es una arquitectura mal
diseñada.

**No aplica**: ver `cryptography-pki-standards` (**elección de algoritmos, generación de
claves, aleatoriedad, PKI y emisión de certificados, KMS/HSM como primitiva criptográfica y
envelope encryption — todo eso es suyo**; aquí solo la **custodia, distribución, rotación
operativa y consumo** del material ya generado),
`identity-access-management-standards` (**la alternativa preferida al secreto estático**: IdP,
flujos OAuth 2.1/OIDC, tokens, federación, SPIFFE/SPIRE, PAM/JIT — antes de guardar un secreto
se comprueba allí si puede no existir), `cicd-standards` (el pipeline, su OIDC, el pinning de
actions y los gates que ejecutan el escaneo), `kubernetes-standards` (el objeto `Secret`, el
cifrado en etcd, RBAC y admisión), `iac-standards` (**el state de Terraform contiene secretos
en claro** y las variables `sensitive`; el manejo del state es suyo), `aws-standards` /
`azure-standards` / `gcp-standards` (configuración, IAM y coste del servicio gestionado
concreto — aquí el criterio de uso y consumo), `data-platform-standards` (credenciales y
cifrado en reposo del motor de datos), `windows-server-ad-standards` (gMSA/dMSA, LAPS y
rotación de `krbtgt`: secretos **del directorio**), `bash-linux-scripting-standards` (el
script que consume el secreto sin filtrarlo por `ps` o por el log),
`incident-response-forensics-standards` (**la rotación masiva de credenciales durante un
compromiso**: allí el proceso del incidente, aquí el mecanismo que la hace posible en horas y
no en semanas), `incident-management-standards` (declaración, severidad y comunicación),
`detection-engineering-standards` (**frontera compartida y bidireccional**: la telemetría de
este dominio —lecturas anómalas del gestor, secreto detectado en un push, uso de una
credencial desde un origen imposible, secreto que se lee tras haber sido revocado— es una
**fuente de detección de primer orden**; el escaneo es mío, la regla que convierte el hallazgo
en alerta y su runbook son suyos), `privacy-engineering-standards` (**un dato personal no es
un secreto** y no se gestiona con estas herramientas), `grc-compliance-standards` (el control
normativo que exige custodia y rotación, y su evidencia), `bcdr-standards` (custodia de claves
de recuperación **fuera** del sistema respaldado y su papel en el plan de continuidad), y las
skills de lenguaje —entre ellas `powershell-standards`, que **delega aquí** la elección del gestor
y del escáner de secretos y se queda el criterio de código: `SecretManagement`/`SecretStore` como
front-end, y la prohibición de `ConvertTo-SecureString -AsPlainText -Force` con un secreto escrito
en el fichero—, `developer-workstation-standards` (**la elección del gestor de secretos y del escáner
son de aquí**; **la custodia en la máquina del desarrollador es suya** —clave en hardware, PIN y
toque obligatorio, `credential.helper` que **no** escriba en claro, token fuera del historial del
shell y del `~/.netrc`, y el alcance de credenciales al que llega un agente de codificación—),
y `solidity-standards` (el contrato es suyo; **la custodia de la clave de
despliegue y de la clave de `owner`/`upgrader` es de aquí** —HSM o multifirma, rotación, umbral—.
Dato que ordena la prioridad: **el compromiso de clave privada explica más del 25 % de los robos en
cadena y cuatro de los diez mayores**; un contrato actualizable traslada todo el riesgo a quien
tiene esa llave, así que **una sola clave caliente no es una arquitectura aceptable**).

## 2. Decisiones por defecto

> Datos verificados ago-2026. **Verificar versión, licencia y gobernanza por web antes de
> comprometer una plataforma (§8)**: este dominio tuvo cambios de licencia, de fundación y de
> mantenimiento en 2025-2026, y varios de ellos invalidan recomendaciones anteriores.

### 2.1 La jerarquía de decisión (en este orden, siempre)

1. **¿Puede no existir el secreto?** → OIDC/workload identity federation (CI→nube),
   SPIFFE/SPIRE (servicio→servicio), identidad gestionada del proveedor. **Sin secreto no hay
   custodia, ni rotación, ni filtración.**
2. **¿Puede ser dinámico?** → el gestor **genera** la credencial al vuelo con TTL (usuario de
   base de datos, credencial cloud temporal, certificado de vida corta). El secreto existe
   minutos, no años.
3. **¿Puede ser de vida corta y revocable?** → token con TTL y revocación efectiva.
4. **Solo entonces**: secreto estático en el gestor, con dueño, política, auditoría y
   rotación probada.

### 2.2 Gestor

| Necesidad | Por defecto | Alternativa justificable / vetado |
|---|---|---|
| Solo una nube, cargas solo en ella | **El gestor nativo** (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) | Es la opción KISS: IAM ya existe, integración nativa y cero operación. Desplegar Vault/OpenBao "por si acaso" con una sola nube es sobre-ingeniería |
| Multi-nube, on-prem o secretos dinámicos serios | **OpenBao 2.6.1** (MPL-2.0, **OpenSSF/Linux Foundation, nivel Sandbox** desde jun-2025) | **HashiCorp Vault 2.0.3** sigue siendo válido y es más maduro en replicación — pero su licencia es **BUSL 1.1 desde ago-2023 y no ha cambiado** tras el cierre de la adquisición por **IBM (27-feb-2025)**: hoy el *Licensor* del fichero LICENSE es IBM. Es una decisión de **ADR con evaluación legal**, no técnica |
| Gestor "de producto" con DX y UI | **Infisical 0.162.15** (núcleo MIT, `ee/` bajo licencia Enterprise propietaria) | Modelo *open core* honesto pero con funciones clave de pago (**los secretos dinámicos están en el tier Advanced**). Válido para equipos pequeños; verifica qué necesitas que esté en `ee/` antes de comprometerte |
| Ya usas Bitwarden para el equipo | **Bitwarden Secrets Manager** | **Aviso de licencia poco conocido**: el servidor es AGPLv3, pero el **SDK donde vive el cliente `bws` (`bitwarden/sdk-sm`) NO es open source** — licencia propietaria que prohíbe usarlo con software distinto de Bitwarden. La polémica GPL de 2024 se resolvió para el gestor de contraseñas, **no** para Secrets Manager. Su operador de Kubernetes se instala oficialmente con `--devel` (canal pre-release): madurez no declarada |
| Secretos de **humanos** (equipo) | **Gestor de contraseñas** con vaults compartidos y MFA | **No es el mismo problema ni la misma herramienta** (§3.7). Vetado: usar el gestor de secretos de servicio como caja de contraseñas del equipo, o al revés |

**Sobre la compatibilidad Vault↔OpenBao (el dato más volátil de esta skill)**: sigue siendo
**práctica en lo esencial** (API, políticas HCL, migración por snapshot Raft), pero **la
divergencia es real y se acelera** — verifícala antes de asumir portabilidad:
- OpenBao **eliminó `stored_shares`** (2.6.0) y **retira los seals integrados**
  (`awskms`, `azurekeyvault`, `gcpckms`, `ocikms`, `pkcs11`, `alicloudkms`) **en 2.7.0**,
  moviéndolos a plugins `kms` externos: es un cambio de despliegue, no cosmético.
- Sus **namespaces tienen semántica distinta** de los de Vault Enterprise (identity store por
  namespace, sin herencia de grupos; flag `unsafe_cross_namespace_identity`, por defecto
  `false`, para restaurar el comportamiento de Vault).
- A favor de OpenBao: namespaces sin coste (en Vault son Enterprise), *namespace sealing*,
  imágenes distroless y no-root, almacenamiento transaccional, plugins vía OCI. Adopción real
  verificable: **GitLab Secrets Manager está construido sobre OpenBao** y **EdgeX 4.0 lo hizo
  su secret store por defecto**, sustituyendo a Vault.
- A favor de Vault: replicación DR y de rendimiento, snapshots automatizados integrados,
  Sentinel (OpenBao ofrece CEL). *(Comparativa de fuente secundaria: confírmala.)*

### 2.3 Inyección en el consumidor — de mejor a peor

| Mecanismo | Cuándo | Nota |
|---|---|---|
| **Sin secreto**: token federado obtenido en runtime | Siempre que la plataforma lo permita | El objetivo. `identity-access-management-standards` |
| **API del gestor desde el proceso**, con caché en memoria y TTL | Aplicación que puede integrarse | Permite rotación **sin reinicio**, que es la mitad del valor de rotar |
| **Fichero en tmpfs / `$CREDENTIALS_DIRECTORY`** | Servicios systemd, contenedores | En systemd: **memoria no *swappable*, inmutable si los privilegios lo permiten, accesible solo al UID del servicio y destruido al terminar** — el mejor mecanismo del ecosistema Linux |
| **Volumen montado** (CSI driver, secret de K8s como volumen) | Kubernetes | Se **refresca** cuando cambia el secreto; las variables de entorno **no** |
| **Variable de entorno** | Último recurso defendible | Ver abajo |

**Por qué las variables de entorno son la peor opción defendible** — con el argumento
correcto, porque el que circula suele estar mal planteado:
- **`/proc/PID/environ` NO es world-readable**: su acceso se rige por una comprobación
  `PTRACE_MODE_READ_FSCREDS` (mismo UID, o root/`CAP_SYS_PTRACE`). Usar "cualquiera puede
  leerlo" como argumento es **incorrecto** y te desacredita en la discusión técnica.
- Los argumentos que **sí** se sostienen: **se heredan automáticamente por todo el árbol de
  procesos** (cualquier subproceso, incluido el que no debía verlo, y cualquier `curl` que
  lances desde ahí); **no hay control de acceso por credencial** (todo o nada); aparecen en
  **volcados y trazas de crash**; son legibles por cualquier proceso del mismo UID y por root;
  quedan expuestas en interfaces de introspección (`kubectl describe pod`, `docker inspect`);
  **no se pueden rotar sin reiniciar el proceso**; y tienen límites de tamaño y problemas con
  datos binarios. El propio documento de credenciales de systemd enumera exactamente estos
  defectos frente a su modelo, donde el acceso se comprueba en el kernel en cada uso.
- OWASP (Secrets Management Cheat Sheet) es explícito: *"using environment variables is
  therefore not recommended unless the other methods are not possible"*, y prohíbe `ENV`/`ARG`
  de Docker para secretos.

### 2.4 Herramientas de apoyo

| Ámbito | Por defecto | Nota crítica |
|---|---|---|
| Escaneo de secretos | **gitleaks 8.30.1** (MIT) como base ya integrada; **Betterleaks 1.7.3** (MIT, *drop-in*, lee `.gitleaks.toml` y `.gitleaksignore`) como sucesor | **Dato que cambia la recomendación**: gitleaks se declaró **feature complete** — *"future releases will be security patches only"* — y su propio README apunta a Betterleaks, mantenido por los mismos autores. **Y su GitHub Action es otra cosa**: `gitleaks-action` **desde v2.0.0 dejó MIT y exige licencia comercial (`GITLEAKS_LICENSE`) para organizaciones**; además **v2 deja de funcionar el 16-sep-2026**. Escanea con el **binario**, no con la action |
| Escaneo profundo / verificación de credencial viva | **trufflehog 3.96.0** (AGPL-3.0) | Su capacidad de **verificar** si la credencial sigue viva es lo que lo diferencia. Ojo con AGPL si lo integras en producto |
| Alternativas | **Kingfisher** (MongoDB, Rust), **ggshield** (requiere SaaS), **Titus** (Praetorian) | **Nosey Parker está archivado desde 2026-04-24** (remite a Titus) y **detect-secrets de Yelp lleva ~27 meses sin release**: no empieces nada nuevo en ellos |
| Cifrado de secretos en repo | **SOPS 3.13.3** (MPL-2.0, CNCF **Sandbox**, org `getsops`) con **age 1.3.1** (BSD-3) o KMS | **Riesgo de gobernanza abierto**: `cncf/toc#2098` (mar-2026) declara SOPS *"active but has some health issues"* y evalúa si puede relicenciarse fuera de MPL; si no, contempla **archivarlo o sacarlo de la CNCF**. Sigue siendo la mejor opción, pero **con vigilancia y plan B** |
| Alternativa GitOps en K8s | **sealed-secrets 0.38.4** | **Mínimo duro 0.36.0+** (CVE-2026-22728: `/v1/rotate` permitía ampliar el scope a cluster-wide). **Trampa verificada**: existe `bitnamilegacy/sealed-secrets-controller` congelado en ~0.31.0 como efecto del archivado de imágenes de Bitnami — repuntar ahí te clava en una imagen sin parches. Registry alternativo válido y firmado con cosign: `ghcr.io/bitnami/sealed-secrets-controller` |
| Sincronización a Kubernetes | **External Secrets Operator 2.8.0** | Ver §3.4: es potente pero tiene **historial de gobernanza y de CVEs críticas** que hay que conocer antes de adoptarlo |
| Montaje directo en pod | **Secrets Store CSI Driver 1.6.0** (Kubernetes SIG Auth) | Evita materializar un `Secret` de K8s. Contrapartida: **DaemonSet privilegiado con hostPath del kubelet**, y sus mantenedores piden manos públicamente (bus factor bajo). En **1.6.0 la rotación cambió** al modelo `requiresRepublish: true` y **se eliminaron los RBAC de rotación** |
| Identidad de carga | **SPIRE 1.15.2** (SPIFFE y SPIRE **graduados en CNCF** desde ago-2022) | Vault 2.0.0 ya acepta **SPIFFE JWT-SVID**; Entra ID documenta federación con SPIFFE/SPIRE |

## 3. Estructura y convenciones

### 3.1 Secretos dinámicos: el objetivo real

- **Credencial de base de datos generada al vuelo con TTL** (minutos u horas), revocada al
  expirar el lease. Elimina de golpe: la rotación manual, el secreto compartido entre
  servicios, el "no sabemos quién usa esta contraseña" y la mayor parte del impacto de una
  filtración.
- **Requisitos de diseño que la gente descubre tarde**: la aplicación debe **renovar o
  reconectar** cuando el lease caduca (un pool de conexiones con credencial caducada falla en
  el peor momento); el gestor pasa a ser **dependencia en el camino crítico** (§3.6); y el
  motor de datos debe soportar la creación/borrado de usuarios a ese ritmo.
- Aplica también a credenciales cloud temporales, certificados de vida corta y tokens de
  servicio. **Un secreto con TTL largo es una decisión, y se justifica en la PR.**
- **Los gestores de nube no rotan solos, salvo casos concretos** — verifícalo antes de
  prometerlo:
  - **AWS Secrets Manager**: *managed rotation* sin Lambda solo para Aurora/RDS/DocumentDB/
    Redshift y un conjunto de integraciones externas; el resto **sigue exigiendo tu Lambda**.
    Desde jul-2026 emite notificaciones de cambio a **EventBridge** sin coste: úsalas para
    detectar rotaciones que no ocurren.
  - **Azure Key Vault**: **no tiene rotación nativa de *secretos*** (las *claves* sí). El
    patrón oficial es evento `SecretNearExpiry` → Event Grid → Function, con esquema
    **dual-key**. Además, desde mar-2026 los vaults creados con la API `2026-02-01` usan
    **RBAC de Azure por defecto**, y **las API de control plane anteriores se retiran el
    27-feb-2027**.
  - **GCP Secret Manager**: **no rota**; emite un mensaje **`SECRET_ROTATE`** a Pub/Sub en
    `next_rotation_time` y tú creas la versión nueva. La rotación de credenciales de Cloud SQL
    está en **Preview** (jul-2026).

### 3.2 Modelado, políticas y auditoría del gestor

- **El gestor es un objetivo de altísimo valor: su compromiso es el peor día de la
  organización.** Se trata como Tier 0: red segmentada, acceso administrativo separado del
  de consumo, MFA para humanos, y su telemetría vigilada por
  `detection-engineering-standards`.
- **Rutas por dominio de fallo**, no por equipo ni por comodidad:
  `<entorno>/<servicio>/<propósito>`. Una política por identidad consumidora, con **solo
  lectura de sus propias rutas**. Nadie —ni una aplicación, ni un pipeline— lee `*`.
- **Separación de funciones**: quien administra el gestor no debería poder leer los secretos
  de negocio en claro; quien los lee no administra políticas. Toda operación con material
  raíz, auditada y con doble control.
- **Auditoría con respuesta a preguntas concretas**: quién leyó qué y cuándo, qué identidad no
  ha leído nunca un secreto que tiene concedido (permiso muerto → se retira), y qué secreto no
  se ha leído en meses (candidato a borrado). **Un secreto que nadie lee es riesgo puro.**
- **Alerta sobre el propio gestor**: pico de lecturas, lectura desde origen nuevo, cambio de
  política, desactivación de auditoría, sellado/desellado no planificado, y **fallo de
  autenticación repetido**. Sin `audit device` configurado y con destino monitorizado, no hay
  gestión de secretos: hay un almacén.
- **Verifica que el destino de auditoría no se convierta en la filtración**: precedente real
  (HCSEC-2026-09) — secretos de webhook de GitHub quedaron expuestos en base64 en una
  cabecera HTTP que acabó en logs de balanceadores, proxies y SIEM. Los logs de auditoría del
  gestor son tan sensibles como su contenido.

### 3.3 Rotación: si nunca se ha ejecutado, no existe

- **Toda credencial tiene periodo de rotación explícito y dueño.** Sin dueño no hay rotación,
  hay intención.
- **La rotación se ejecuta de verdad y de forma programada**, no "cuando toque". Un
  procedimiento de rotación documentado pero nunca ejercitado falla exactamente el día del
  incidente, que es cuando hay que ejecutarlo bajo presión y en masa.
- **Diseña para el solapamiento (dual-key / expand-contract)**: dos credenciales válidas a la
  vez durante la ventana de transición. Sin solapamiento, toda rotación es una caída
  planificada, y por eso nadie rota.
- **Métrica del programa**: *time-to-rotate-everything* — cuánto tardarías en rotar **todas**
  las credenciales de un ámbito. Si la respuesta es "semanas", tienes un incidente latente,
  igual que una PKI que no puede reemitir en 24 h.
- La rotación es un **gate de recuperación**, no solo de higiene: el plan de respuesta a
  compromiso depende de que este número sea pequeño.

### 3.4 Kubernetes: cómo llega el secreto al pod

Dos caminos válidos, y la elección se documenta:

- **External Secrets Operator (ESO)**: sincroniza desde el gestor a `Secret` de Kubernetes.
  Cómodo y compatible con todo, pero **materializa el secreto en etcd** (exige cifrado en
  reposo con proveedor KMS y RBAC estricto — `kubernetes-standards`). Antes de adoptarlo,
  conoce su historial, porque cambia la evaluación de riesgo:
  - **Ya no es `v0.x`**: 1.0 GA en nov-2025, 2.0 en feb-2026, hoy **2.8.0**. Ventana de
    soporte **muy corta**: cada minor muere al salir la siguiente.
  - **`v1beta1` no está deprecada: fue ELIMINADA en v0.17.0** (may-2025). La migración pasa
    obligatoriamente por v0.16.2, y **no existe guía oficial de migración**. Gotcha añadido:
    en 0.16.x el webhook convierte a `v1` aunque sirva ambas, produciendo **drift permanente
    en Argo CD** si Git se queda en `v1beta1`.
  - **CVEs críticas propias**: **CVE-2026-22822** (CVSS 9.3, `getSecretKey` recuperaba
    secretos **cross-namespace** con el rolebinding del controlador; fix 1.2.0),
    **CVE-2026-34984** (`getHostByName` en el motor de plantillas → exfiltración por DNS; fix
    2.3.0), **CVE-2025-55196** (`PushSecret` sin selector de namespace → lectura cluster-wide;
    fix 0.19.2). **Mínimo duro: 2.3.0+.**
  - **Salud del proyecto**: CNCF **Sandbox** desde 2022 sin promoción; en jul-2025 los
    mantenedores **pausaron todas las releases** por *burnout* y la CNCF TOC abrió una
    **revisión de salud con checklist de archivado**; se resolvió con gobernanza nueva, y la
    empresa que lo respaldaba (*External Secrets Inc.*) **cerró en nov-2025**. Es usable, pero
    entra en tu registro de riesgos con dueño.
- **Secrets Store CSI Driver**: monta el secreto como volumen sin crear un `Secret` de K8s
  (salvo que actives la sincronización, que anula la ventaja). Preferible cuando el modelo de
  amenaza incluye "quien lea etcd o tenga `get secrets` no debe ver esto".
- **sealed-secrets / SOPS**: para GitOps **sin** gestor. Son cifrado en el repo, no gestión de
  secretos: sin rotación, sin auditoría de lectura, sin TTL, sin revocación. Válidos y KISS
  para homelab y equipos pequeños; **su límite hay que declararlo**, no descubrirlo.
- **Vault/OpenBao en K8s**: **Vault Secrets Operator 1.5.0** (ojo, *breaking*: elimina
  `spec.appRole.secretIDPath`) o **Vault Agent Injector (vault-k8s) 1.7.5**. HashiCorp no
  recomienda uno sobre otro por defecto, pero la **carga sobre el gestor sí difiere**: VSO es
  la más baja (pool por nodo con caché), el CSI provider intermedia, el **Agent Injector la
  más alta** (sidecar por pod).

### 3.5 Dónde se filtran los secretos de verdad

Por orden de frecuencia observada, no de dramatismo:

- **Repositorio e historial de Git** (§3.8).
- **Variables y logs de CI**: `set -x`, `echo` de depuración, salidas de error de un cliente
  HTTP. El enmascarado del CI es **best effort**: se rompe con transformaciones (base64,
  troceado, JSON escapado) y **el payload del compromiso de Trivy leía la memoria del proceso
  del runner precisamente para saltárselo**.
- **Imágenes y capas de contenedor**: un `ARG`/`ENV` o un `COPY` de un fichero borrado en una
  capa posterior **sigue en la imagen**. Se usa `--mount=type=secret` de BuildKit
  (`kubernetes-standards`).
- **Artefactos de build y ficheros de configuración empaquetados**.
- **State de Terraform** — en claro por diseño (`iac-standards`).
- **Backups y snapshots**: si el backup contiene el secreto, el backup **es** el secreto. Su
  clave de cifrado vive fuera del sistema respaldado (`cryptography-pki-standards`,
  `bcdr-standards`).
- **Telemetría**: URLs con token en query string, cabeceras `Authorization`, cuerpos de
  petición, stack traces (`observability-standards`).
- **Y el que casi nadie modela: el consumidor comprometido.** El gusano **Shai-Hulud** usa
  **TruffleHog** dentro de la máquina de la víctima para cosechar credenciales, y su tercera
  oleada (`@bitwarden/cli` 2026.4.0 malicioso, ~93 minutos en npm, abr-2026) **vaciaba
  directamente AWS Secrets Manager, SSM Parameter Store, GCP Secret Manager y Azure Key
  Vault** con la identidad legítima del proceso. **Ningún gestor te protege de un consumidor
  comprometido**: por eso la defensa real son TTL cortos, mínimo privilegio por identidad y
  detección de lecturas anómalas — no la caja fuerte.

### 3.6 HA, sellado y la pregunta que nadie hace

**Si el gestor cae, ¿arranca tu aplicación?** Respóndelo por escrito antes de desplegarlo, no
durante la caída:

- Un gestor en el camino crítico del arranque convierte su indisponibilidad en indisponibilidad
  total. Mitigaciones: **caché en memoria con TTL** y arranque degradado con la credencial
  vigente; réplicas y despliegue multi-AZ; y **desellado automático** (auto-unseal contra
  KMS/HSM) para que un reinicio no exija a un humano de madrugada.
- El **auto-unseal traslada la confianza al KMS**: si ese KMS cae o le retiran permisos, el
  gestor no se abre. Documenta el procedimiento de **desellado manual con quórum de Shamir**,
  con las llaves custodiadas por personas distintas y **el procedimiento ensayado**. Una llave
  de recuperación que nadie ha probado a usar es una llave que no existe.
- **En OpenBao, presta atención a los cambios de sellado**: `stored_shares` eliminado en 2.6.0
  y los seals integrados **saliendo del binario en 2.7.0** hacia plugins externos.
- Backup del gestor (snapshot Raft) **cifrado, con clave fuera del propio gestor** y con
  **restore probado**. Es el único caso donde restaurar mal significa perderlo todo a la vez.
- **Vigila sus advisories como los del kernel.** Precedentes verificados de 2026: en OpenBao,
  **CVE-2026-63132** (CVSS 9.1, canal lateral temporal en *recovery mode* que permitía extraer
  el recovery token; fix 2.6.0) y escalada por *wildcards* en políticas con plantilla (fix
  2.6.0); en Vault, **CVE-2026-5051** (bypass del guard del directorio de plugins de
  auditoría), **CVE-2026-5052** (SSRF en la validación de retos ACME del motor PKI) y
  **CVE-2026-3605** (bypass de política borrando metadata KVv2 vía glob).

### 3.7 Humanos ≠ máquinas

Son dos problemas con soluciones distintas y **no se mezclan**:

| | Secretos de humanos | Secretos de máquinas |
|---|---|---|
| Herramienta | Gestor de contraseñas del equipo (vaults compartidos, MFA, recuperación) | Gestor de secretos de servicio (API, políticas, TTL, auditoría) |
| Unidad | Persona, con onboarding/offboarding | Identidad de carga, con ciclo de vida del despliegue |
| Objetivo | Que nadie reutilice ni comparta contraseñas | Que la credencial sea dinámica y de vida corta |
| Fallo típico | Contraseña compartida por chat que sobrevive a la baja de quien la creó | Token estático de hace tres años que nadie sabe quién usa |

Regla dura: **una credencial que un humano puede leer y que también usa un servicio es una
credencial que ya está comprometida a efectos de auditoría** — no puedes atribuir su uso.

### 3.8 Respuesta a la exposición: rotar primero, limpiar después

**Un secreto que ha estado en un repositorio, en un log o en un canal de chat está quemado.**
Reescribir el historial no lo des-quema: clonado, cacheado por el forjado, indexado por bots
que barren GitHub en segundos, y presente en forks y en las bases de datos de los atacantes.

Orden **no negociable**:
1. **Rotar/revocar la credencial.** Primero. Antes de investigar cómo llegó ahí.
2. **Verificar la revocación** (que la vieja ya no funciona) y **buscar uso** de la credencial
   expuesta en los logs desde el momento de la exposición — es un caso de
   `detection-engineering-standards`, y si hubo uso, un incidente de
   `incident-response-forensics-standards`.
3. **Limpiar el historial** (`git filter-repo`, `git-workflow-standards`) y coordinar el
   force-push con quien tenga clones.
4. **Arreglar la causa**: por qué el escaneo no lo cogió antes, por qué existía ese secreto
   estático, y si podía haberse eliminado por federación.

**Prohibido invertir el orden.** "Lo borro del historial y luego vemos" es la respuesta que
convierte una fuga en una brecha.

## 4. Gates de CI (rompen el build)

1. **Pre-commit local + escaneo en CI** del diff con `gitleaks`/`betterleaks` — el pre-commit
   es comodidad, **el gate de CI es el control**, porque el hook local se salta con
   `--no-verify`.
2. **Escaneo del historial completo** al menos periódicamente (y siempre al abrir un repo
   nuevo o al importarlo): el diff solo ve lo que llega hoy.
3. **Push protection del forjado activada**: en GitHub, gratis en repos públicos, pero en
   privados requiere **GitHub Secret Protection** (facturado por *active committer*) y **a
   nivel de repo/organización está desactivada por defecto** — actívala explícitamente. En
   GitLab, **Secret Push Protection es solo Ultimate** (GA en 17.5) y **omite binarios,
   ficheros > 1 MiB y pushes de más de 350 000 líneas**: conoce sus huecos, no la trates como
   red de seguridad total.
4. **Hallazgo = build roto + rotación inmediata**, no un TODO ni una excepción silenciosa.
   Toda supresión (`.gitleaksignore`, allowlist) lleva motivo, dueño y **caducidad**.
5. **Escaneo de la imagen construida y del state de IaC**, no solo del código fuente: los
   secretos aparecen en capas y en `terraform.tfstate`.
6. **Prohibición de credenciales estáticas en el pipeline**: gate que falla si aparece
   `AWS_ACCESS_KEY_ID`, una clave de service account JSON o un `client_secret` como variable
   de CI donde exista OIDC (`cicd-standards`).
7. **Test de rotación automatizado** en el entorno de preproducción: rota, comprueba que el
   servicio sigue funcionando y que la credencial antigua **ya no autentica**. Sin esto, §3.3
   es una intención.
8. **Verificación de que el secreto no aparece en la salida**: prueba que ejecuta el arranque
   del servicio y falla si un valor secreto conocido aparece en stdout/stderr o en el log
   estructurado.

## 5. Seguridad específica

- **Mínimo privilegio hasta el final**: una identidad, un conjunto de secretos, solo lectura.
  El anti-patrón universal es la política amplia "para no bloquear al equipo", que convierte
  cualquier compromiso de cualquier pod en compromiso total.
- **Nunca pases secretos por argumentos de línea de comandos** (visibles en `ps`, en el
  historial del shell y en los logs de auditoría del proceso): fichero, stdin o variable de
  entorno del propio proceso, en ese orden.
- **Nunca los pongas en la URL** (query string): acaban en logs de acceso, en el `Referer` y
  en la telemetría.
- **Un secreto por servicio y por entorno.** Compartir una credencial entre servicios destruye
  la atribución y multiplica el radio de explosión de cada rotación.
- **La cadena de suministro del propio tooling de secretos es superficie de ataque**, y el
  precedente es explícito: el compromiso de `tj-actions/changed-files` (**CVE-2025-30066**)
  volcó secretos de CI a los logs de build de más de 23 000 repositorios, y la campaña de 2026
  contra Trivy/Checkmarx robó credenciales de CI a escala. Consecuencia: **pin por SHA de toda
  action y por digest de toda imagen** que toque secretos, verificación de firma, y **egress
  restringido en los jobs que los manejan**. Verificado ago-2026: **ni gitleaks, ni trufflehog,
  ni SOPS, ni ESO, ni sealed-secrets han sufrido compromiso de cadena de suministro** — sí
  vulnerabilidades propias (§2.4, §3.4), que es otra cosa.
- **Federación OIDC: la trust policy es el control, y cambió en 2026.** GitHub Actions emite
  ahora **subject claims inmutables** (`repo:org@<id>/repo@<id>:ref:...`), aplicado
  automáticamente desde el **15-jul-2026** a repos nuevos y a los renombrados o transferidos:
  las políticas de confianza que casan por path **se rompen o, peor, dejan de casar lo que
  creías**. En GitLab, `CI_JOB_JWT*` fue **eliminado en 17.0** y la guía es confiar por
  `project_id`/`namespace_id`, no por path (que un rename cambia). En Azure, `issuer`,
  `subject` y `audience` son **case-sensitive** y hay límite de **20 credenciales federadas
  por identidad gestionada**. Nunca uses comodines amplios en el `sub`.
- **Nada de secretos en la telemetría ni en los mensajes de error.** El error de "credencial
  inválida" no imprime la credencial, ni su prefijo, ni su longitud.

## 6. Operabilidad

- **Inventario**: qué secretos existen, quién los consume, cuándo se rotaron por última vez y
  quién es el dueño. Sin inventario no hay rotación de emergencia posible, y por tanto no hay
  respuesta a compromiso.
- **Caché en el consumidor con TTL** para no convertir cada petición en una llamada al gestor
  (coste, latencia y un punto de fallo por operación). Cachea en memoria, **nunca en disco en
  claro**, y respeta el TTL como límite superior.
- **Coste real**: AWS Secrets Manager factura ~0,40 USD por secreto y mes más llamadas — un
  patrón de "un secreto por microservicio por entorno" se nota en la factura y empuja al
  anti-patrón de agrupar todo en un secreto gigante compartido. Diseña la granularidad con el
  coste y el radio de explosión sobre la mesa.
- **Observabilidad del gestor**: latencia y tasa de error de lectura, leases activos, estado
  de sellado, y **antigüedad del secreto más viejo sin rotar** como métrica publicada.
- **Retirada**: cuando un servicio muere, sus secretos y sus políticas se borran en la misma
  PR. Las credenciales huérfanas son el residuo con más rentabilidad para un atacante.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisar advisories del gestor (mensual — tiene críticas con regularidad),
  versión de ESO/CSI driver/sealed-secrets (su ventana de soporte es corta), y **auditoría de
  accesos y poda de permisos y secretos muertos, trimestral**.
- **Riesgos de gobernanza en el registro, con dueño y fecha de revisión**: la licencia BUSL de
  Vault bajo IBM, el nivel Sandbox y la revisión de salud de SOPS en la CNCF, la trayectoria
  de ESO tras el cierre de la empresa que lo respaldaba, y el estado *feature complete* de
  gitleaks. Ninguno es motivo de pánico; todos son motivo de plan B escrito.
- Toda excepción (secreto estático que no se puede eliminar, TTL largo, política amplia) lleva
  **motivo, dueño y fecha de salida**.

**PROHIBIDO**
- ❌ Guardar un secreto estático donde cabía **identidad federada de vida corta**.
- ❌ Secretos en código, en el historial de Git, en `values.yaml`, en `*.tfvars`, en el state,
  en `ENV`/`ARG` de un Dockerfile, en capas de imagen, en logs o en canales de chat.
- ❌ Secretos como **argumentos de línea de comandos** o en la query string de una URL.
- ❌ **Variables de entorno como mecanismo por defecto** de inyección (§2.3).
- ❌ **Reescribir el historial antes de rotar**: rotar primero, limpiar después. Siempre.
- ❌ Dar por seguro un secreto expuesto porque "el repo era privado" o "se borró enseguida".
- ❌ Rotación documentada pero **nunca ejecutada**; procedimiento de desellado con quórum
  nunca ensayado; backup del gestor sin restore probado.
- ❌ Una credencial compartida entre servicios, entre entornos, o entre un humano y un
  servicio.
- ❌ Políticas comodín sobre el gestor, o trust policies OIDC con `sub` comodín.
- ❌ Gestor de secretos **sin audit device configurado** y sin ese log monitorizado.
- ❌ Gestor en el camino crítico del arranque **sin haber respondido** qué pasa cuando cae.
- ❌ Tratar `sealed-secrets` o SOPS como sustituto de un gestor cuando hace falta rotación,
  revocación o auditoría de lectura.
- ❌ Usar `gitleaks-action` v2 sin conocer su **licencia comercial** y su fin de
  funcionamiento (16-sep-2026); confiar solo en el hook de pre-commit sin gate de CI.
- ❌ Apuntar sealed-secrets a `bitnamilegacy/*` (imagen congelada sin parches).
- ❌ ESO por debajo de 2.3.0, sealed-secrets por debajo de 0.36.0, o cualquier gestor con CVE
  crítica publicada sin parchear.
- ❌ Empezar algo nuevo sobre `detect-secrets` o Nosey Parker (sin mantenimiento / archivado).
- ❌ Actions o imágenes por **tag mutable** en pipelines que manejan secretos.

## 8. Verificación web obligatoria

Antes de fijar versión, licencia, gobernanza o comportamiento, **búscalo — no lo recuerdes**.
Datos verificados ago-2026 (los más volátiles del catálogo): Vault **2.0.3**, **BUSL 1.1 sin
cambio**, *Licensor* ahora **IBM** (adquisición cerrada 27-feb-2025), nuevo ciclo de soporte
IBM y **Community sin LTS**; OpenBao **2.6.1**, **MPL-2.0**, **OpenSSF/LF nivel Sandbox**;
Infisical **0.162.15**; `bws` **2.1.0**; ESO **2.8.0**; Secrets Store CSI Driver **1.6.0**;
sealed-secrets **0.38.4**; Vault Secrets Operator **1.5.0**; vault-k8s **1.7.5**; SOPS
**3.13.3** (CNCF Sandbox, health issue abierta); age **1.3.1**; gitleaks **8.30.1** (feature
complete) y Betterleaks **1.7.3**; trufflehog **3.96.0**; SPIRE **1.15.2** (SPIFFE/SPIRE
graduados en CNCF); systemd **v261**.

1. **Licencia de Vault bajo IBM** y **nivel real de OpenBao en la Linux Foundation/OpenSSF**:
   es el par de datos que más se cita mal. Léelo del fichero `LICENSE` y de la página del
   proyecto, no de un blog.
2. **Divergencia Vault↔OpenBao** antes de asumir portabilidad: seals integrados saliendo del
   binario en 2.7.0, `stored_shares`, semántica de namespaces, replicación.
3. **Advisories del gestor** (HCSEC de HashiCorp, security advisories de OpenBao): ambos
   publicaron críticas en 2026.
4. **Estado de mantenimiento** de gitleaks/Betterleaks, SOPS (issue de salud en la CNCF), ESO
   y sealed-secrets antes de apostar el pipeline a alguno.
5. **Claims OIDC y trust policies** vigentes de GitHub/GitLab hacia AWS/Azure/GCP: los subject
   claims inmutables de GitHub cambiaron el formato en 2026 y rompen políticas existentes.
6. **Mecanismo y coste de rotación** del gestor de nube concreto: ninguno de los tres rota
   todo automáticamente, y lo que cubre la rotación gestionada cambia cada trimestre.
7. **Directivas de credenciales de systemd** y su versión mínima en tu distribución antes de
   basar un despliegue en ellas (`SetCredential=`/`LoadCredential=` desde 247;
   `LoadCredentialEncrypted=`/`SetCredentialEncrypted=`/`systemd-creds` desde 250;
   `ImportCredential=` desde 254).
8. **Compromisos de cadena de suministro** de cualquier herramienta nueva del pipeline de
   secretos antes de adoptarla.

**Huecos declarados — no verificados en este documento, verifícalos tú antes de usarlos**:
- **Nivel exacto de OpenBao en la OpenSSF hoy** (Sandbox según la página del proyecto; una
  lectura del índice sugería "Incubation" y **no existe anuncio de promoción localizable**), y
  las **fechas de entrada/salida de LF Edge**.
- La comparativa de **funciones de Vault ausentes en OpenBao** (replicación DR/rendimiento,
  snapshots automatizados, Sentinel) procede de **fuente secundaria**.
- **Resultado formal de la solicitud de incubación de ESO en la CNCF** (issue cerrado, sin
  desenlace público localizado).
- **Existencia y versión de `ImportCredentialEx=`** en systemd, y el **modo/propietario exacto
  de los ficheros** de `$CREDENTIALS_DIRECTORY` (la documentación no fue accesible).
- **Fecha exacta de systemd v261**.
- **Guidance específica de CIS o NIST SP 800-190** contra las variables de entorno para
  secretos: el argumentario de §2.3 se apoya en systemd y OWASP, **no** en NIST/CIS.
- **Quién mantiene nominalmente hoy** el repositorio `gitleaks/gitleaks`, y los tiers de
  gitleaks.io.
- **Existencia de un Secret Store extension para AKS en cloud** (la documentación localizada
  cubre Arc-enabled Kubernetes; para AKS el camino soportado es el add-on del CSI driver).
- **Máximo de credenciales federadas por app registration** en Entra (el límite de 20
  verificado es por *managed identity*).
- **CVSS exactos** de varios CVE de Vault de 2026 y CVE-IDs de algunos boletines HCSEC.
- **Cualquier incidente no publicado vía GHSA** en gestores SaaS (Doppler y equivalentes no
  fueron consultados).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
