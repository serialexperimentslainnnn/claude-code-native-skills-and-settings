---
name: homelab-standards
description: Homelab and self-hosting standards for a personal lab. Use for docker-compose.yml stacks, Podman Quadlet .container units, single-node k3s or Talos, restic/Kopia/borgmatic backups, btrfs snapshots, Proxmox lab hosts, home.arpa/.internal naming, NUT/UPS, lab power budget, or self-host-versus-SaaS decisions.
---

# Estándares de homelab y self-hosting

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, montar, operar o revisar un **laboratorio personal**:
- Decisión **self-host vs. SaaS** y qué merece la pena mantener.
- Organización de stacks (Docker Compose / Podman Quadlet), naming y repo del lab.
- Reverse proxy con TLS y **SSO delante de cada app**; DNS interno y PKI del lab.
- **Acceso remoto sin abrir puertos** (Tailscale/Headscale, WireGuard, túnel, bastión).
- Kubernetes de un nodo (k3s, Talos, MicroK8s) **vs.** Compose: cuándo compensa la complejidad.
- Backup con presupuesto ajustado y **restore probado**; snapshots btrfs/ZFS y su límite.
- UPS, consumo eléctrico, ruido, selección de hardware y economía del material *enterprise* usado.
- Estrategia de actualización, *blast radius*, monitorización proporcional y documentación
  pensada para el yo de dentro de seis meses.
- **Criterio de proporcionalidad** (§6): qué práctica *enterprise* sí aplica en casa y cuál es
  sobreingeniería. Esta es la aportación central de la skill.

**No aplica**: ver onprem-standards (para **producción/empresa con rigor de datacenter**: HA con
fencing, DR con RTO/RPO comprometidos, hardening CIS auditado, flota gestionada), y con ella
kubernetes-standards, iac-standards, networking-standards (diseño de red y routing),
identity-access-management-standards (diseño de OIDC/SAML/RBAC), cryptography-pki-standards (ACME,
step-ca, elección de algoritmos), observability-standards (OTel, PromQL, alertas) y
vulnerability-management-standards (triaje de CVEs). También `ctf-lab-standards` (el laboratorio
**de seguridad**: VMs desechables y aisladas para detonar binarios de reto o muestras, plataformas
de entrenamiento y sus ToS — la frontera es el propósito y el aislamiento, no el hardware: si el
lab comparte red o credenciales con los servicios del homelab, está mal diseñado) y
`offensive-security-standards` (ejercicio autorizado contra sistemas de terceros: nada de lo que se
practica en casa se aplica fuera sin autorización escrita), `developer-workstation-standards`
(**Ola 6**: **la máquina con la que se trabaja no es el laboratorio**. El puesto se aprovisiona
como código, se endurece y se reconstruye; el laboratorio existe para romperse. **Prohibido usar
la estación de trabajo como servidor del laboratorio**: mezcla los dos modelos de amenaza y hace
que un experimento roto te deje sin herramienta de trabajo).

**Frontera en las dos direcciones, explícita:**
- Si el sistema tiene **usuarios ajenos a tu casa, datos de terceros, SLA, obligación regulatoria o
  alguien que cobra por su disponibilidad** → es producción: usa **onprem-standards** y las skills
  técnicas, aunque el hardware esté en tu salón.
- Si es tu lab personal, sin terceros y sin SLA → **manda esta skill**: aplicar el rigor completo de
  datacenter a cuatro servicios es la sobreingeniería que esta skill existe para frenar.
- Zona gris (Home Assistant, DNS, Immich familiar): **no tienen SLA pero sí usuarios reales**.
  Trátalos como el tier alto del lab: backup verificado, dependencia mínima y plan de fallo — no
  como producción con HA.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Ámbito | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| Runtime de contenedores | **Podman rootless + Quadlet** (`.container`/`.pod`/`.network` en `/etc/containers/systemd/`, ≥ Podman 4.4) en hosts Fedora/RHEL: unidades systemd reales, journald, `AutoUpdate=registry` con `podman-auto-update.timer` | `podman generate systemd` (deprecado); `podman-compose` como base de un stack estable |
| Stacks multi-servicio | **Docker Compose v2** cuando el proyecto upstream lo publica y hay dependencias entre servicios: un fichero, versionado, diffeable | Traducir a mano a Quadlet un compose upstream que cambia cada release |
| Orquestador | **Compose/Quadlet en un host.** k3s (línea **1.36**, may-2026) o **Talos** (1.13.x) **solo si operar Kubernetes es el objetivo del lab**, no el medio | Kubernetes para cuatro servicios "porque es lo que se lleva": multiplica piezas, upgrades y modos de fallo sin dar nada a cambio |
| Reverse proxy | **Traefik v3.7.x** con proveedor Docker/Podman (descubrimiento automático) o **Caddy 2.11.x** si prefieres config-as-code mínima | **Nginx Proxy Manager**: config en SQLite (no versionable ni diffeable) y CVE-2026-40519 (inyección de comandos autenticada) afectando 2.9.14-2.15.1 — verificar release corregida antes de plantearlo |
| TLS del lab | **ACME DNS-01 con wildcard** (`*.lab.tudominio.tld`) sobre un dominio propio: certificados públicos válidos **sin exponer nada a Internet** | PKI interna propia (Vault PKI, step-ca, Dogtag de FreeIPA) solo si necesitas emitir a máquinas/servicios fuera de ACME: implica distribuir la CA a cada dispositivo |
| Naming interno | Subdominio de **dominio propio** (`lab.tudominio.tld`) con **split-horizon**; sin dominio propio, `home.arpa` (RFC 8375) o `.internal` (reservado por ICANN, jul-2024) | ❌ `.local` (colisiona con mDNS) y ❌ `.lan`, `.home`, inventados: rompen resolución y no admiten cert público ni DNSSEC |
| SSO | **Authelia 4.39.x** (ligero, *forward-auth* + OIDC) delante del proxy por defecto; **Authentik 2026.5.x** si necesitas SAML/SCIM/LDAP o *outposts*; **Pocket ID** si solo quieres OIDC con passkeys | Duplicar el directorio: si ya hay **FreeIPA**, es el backend LDAP/Kerberos y el IdP se apoya en él. ❌ Exponer una app sin authn propia esperando que "nadie la encuentre" |
| Acceso remoto | **Tailscale** (plan Personal desde abr-2026: 6 usuarios, dispositivos de usuario ilimitados, ~50 *tagged resources*) o **Headscale** si quieres el plano de control propio; **WireGuard** puro si prefieres cero dependencias | **Cloudflare Tunnel** solo para lo que deba ser realmente público. ❌ Port-forward de SSH, RDP, paneles de gestión o cualquier app: el lab **no abre puertos entrantes** |
| Backup | **restic 0.19.x** o **Kopia 0.23.x** (ambos con línea estable activa), cifrado cliente y dedup; **borgmatic/Borg 1.4.x** si ya lo usas | ❌ **Borg 2.0**: sigue en beta (2.0.0b22, jul-2026) y rompe compatibilidad de repositorio — no en datos que importan |
| Destino offsite | **3-2-1 barato**: Hetzner Storage Box (egress gratis, SSH/rsync/restic) o **Backblaze B2** (~6 $/TB-mes) / rsync.net; segunda copia local en disco externo rotado | ❌ Copia única, o offsite en la misma casa. Vigila el **coste de egress y de operaciones** antes de elegir (R2 penaliza escrituras pequeñas) |
| Snapshots | **btrfs (snapper/btrbk) o ZFS** para rollback instantáneo y ventana corta | ❌ Snapshot ≠ backup: vive en el mismo pool y muere con él (borrado, ransomware, controladora) |
| Hipervisor | **Proxmox VE 9.x** (turnkey: UI, backup, cluster, firewall) | **Incus** si prefieres un daemon sobre tu distro; ESXi gratuito reapareció pero con límites y sin recorrido |
| Monitorización | **Proporcional**: Uptime Kuma (disponibilidad + notificaciones) + Beszel (agente ~10-15 MB, recursos por host) cubre un lab pequeño | Prometheus + Grafana (+ Alloy, sustituto de Grafana Agent, deprecado) **solo** si quieres PromQL, correlación de logs o ya operas >5-10 hosts. Netdata: 200-500 MB RAM por host, cóbrale el precio |
| Secretos | **Vault** (si ya lo tienes, con procedimiento de *unseal* escrito y claves fuera del lab) o **sops+age** en el repo | ❌ Secretos en `docker-compose.yml`, en `.env` sin cifrar o en el historial de git |
| MFA | **FIDO2/WebAuthn (YubiKey)** en el IdP y en SSH (`ed25519-sk`); **dos llaves** registradas siempre | ❌ Una sola llave sin respaldo: perderla es perder el lab |

## 3. Estructura y convenciones

**Un repo, toda la verdad.** Nada de configuración que exista solo en el host: si se borra el
disco, el lab se reconstruye del repo más el backup de datos.

```
homelab/
├─ hosts/<hostname>/            # lo específico de cada máquina
├─ stacks/<servicio>/           # compose.yaml + .env.sops + README.md
├─ quadlet/                     # *.container, *.network, *.volume
├─ ansible/                     # bootstrap y config de hosts
├─ backup/                      # políticas restic/kopia + jobs de restore-test
├─ docs/
│  ├─ servicios.md              # qué es, por qué existe, quién lo usa, cómo se restaura
│  ├─ red.md                    # VLANs, IPAM, DNS, diagrama
│  └─ decisiones.md             # 3 líneas por decisión: qué, por qué, qué descarté
└─ .sops.yaml
```

**Checklist de servicio nuevo** (si falla uno, no entra en el lab):
① ¿qué datos genera y **están en el backup**? · ② ¿va detrás de SSO o tiene authn propia decente? ·
③ ¿TLS válido? · ④ ¿en qué VLAN y con qué salida a Internet? · ⑤ ¿imagen **pineada por digest**? ·
⑥ ¿dos líneas en `docs/servicios.md` con cómo se restaura? · ⑦ ¿de qué depende para arrancar?

**Naming**: `<servicio>.lab.<dominio>` para el acceso, hostname por rol+índice para las máquinas,
una VLAN por zona de confianza. IPAM en `docs/red.md`; **ningún dato de red de memoria**.

## 4. Gates de calidad proporcionales

Cuatro, automatizados, sin CI de empresa:
1. **Pre-commit**: `yamllint`, `shellcheck`, escáner de secretos (cuál, en
   `secrets-management-standards`) y verificación de que nada sin cifrar entra
   en el repo. Barato y evita el 90% de los desastres tontos.
2. **Restore test mensual, automatizado — EL gate del lab**: restaurar un fichero concreto *y* un
   servicio completo en una VM desechable, verificar que arranca y notificar el resultado
   (ntfy/Healthchecks). Complementado con `restic check --read-data-subset` periódico (verifica el
   repositorio, no que tus datos sean recuperables: son pruebas distintas).
3. **Arranque en frío**, una vez al año: apagar todo y encender. Es la única forma de descubrir las
   **dependencias circulares** (el DNS que vive en el cluster que necesita DNS, el IdP que necesita
   la base de datos que necesita el almacenamiento que necesita el DNS) y el Vault sellado.
4. **Actualización con marcha atrás**: snapshot btrfs/Proxmox **antes**, un cambio por ventana, y
   comprobación de que el servicio responde de verdad (no que systemd diga `active`).

## 5. Seguridad

- **Cero puertos entrantes**. El ingreso es por overlay (Tailscale/WireGuard) o túnel saliente. Si
  algo debe ser público: VLAN aislada, sin credenciales compartidas con el resto, sin acceso lateral
  y asumiendo que caerá.
- **SSO delante de todo** lo que no tenga autenticación seria propia; MFA FIDO2 en el IdP; SSH con
  claves `ed25519`/`ed25519-sk`, sin contraseña ni root remoto.
- **Segmentación mínima realista**: gestión (Proxmox/IPMI/switch) · servicios · **IoT** · invitados.
  El IoT no habla con gestión y sale a Internet solo donde haga falta. Los cacharros baratos son la
  vía de entrada más probable de un lab doméstico.
- **Contenedores**: rootless donde se pueda, nunca `--privileged` por costumbre, y ❌ **jamás montar
  el socket del daemon** (`/var/run/docker.sock`) en una app — es root en el host regalado.
- **Actualizaciones de seguridad del SO automáticas**; imágenes pineadas por digest y actualizadas
  a propósito (Renovate te dice qué cambia antes de cambiarlo).
- **Backups cifrados con la clave custodiada fuera del lab** (gestor de contraseñas, papel en otro
  sitio): backup cifrado sin clave recuperable = pérdida total. Al menos una copia **inmutable u
  offline**; el ransomware doméstico borra primero lo que está montado.
- **Plano de gestión aparte**: IPMI/iDRAC y UI del hipervisor solo por VPN, con credenciales únicas
  y firmware al día. Es lo primero que se olvida en un lab y lo peor que se puede perder.

## 6. Proporcionalidad — el criterio central

| Práctica *enterprise* | ¿En un homelab? | Por qué |
|---|---|---|
| Backup 3-2-1 con **restore probado** | **SÍ, innegociable** | Es la única práctica cuyo fallo es irreversible. Todo lo demás se rehace |
| TLS en todo + ACME automatizado | **SÍ** | Cuesta una tarde y elimina para siempre avisos, MITM en la wifi y excepciones de navegador |
| No exponer puertos / acceso por overlay | **SÍ** | El coste es cero y evita el 100% del escaneo masivo de Internet |
| Config versionada en git + secretos cifrados | **SÍ** | Es lo que convierte "se me murió el disco" en una tarde en vez de un mes |
| Segmentación VLAN (al menos IoT) | **SÍ** | Barato en cualquier switch decente; el IoT es el eslabón débil real |
| Monitorización básica con alerta al móvil | **SÍ, pero solo accionable** | Disco lleno, backup fallido, restore-test fallido, SMART, certificado por caducar. Nada más |
| Documentar decisiones (3 líneas) | **SÍ** | El yo de dentro de seis meses es literalmente otra persona sin contexto |
| Inventario de qué corre y por qué | **SÍ** | Sin él, el lab acumula servicios zombis que nadie usa y todos parchean |
| **HA de 3 nodos, quórum, Ceph** | **NO** (salvo que aprender HA *sea* el objetivo) | Triplica coste, consumo, ruido y complejidad para un SLA que no existe. Un nodo con backup probado se restaura antes que un cluster mal entendido se repara |
| **GitOps (Argo/Flux) para 4 servicios** | **NO** | El repo + `podman auto-update`/Compose ya te da versionado y reproducibilidad. Argo añade un componente crítico más que mantener |
| Service mesh, mTLS este-oeste | **NO** | Resuelve un problema (confianza en red compartida multiinquilino) que tu lab no tiene |
| SIEM completo, correlación, retención larga | **NO** | Logs centralizados con retención corta y búsqueda decente cubren el caso real: entender qué pasó anoche |
| SLOs con *error budget*, postmortems formales | **NO** | El SLI real es "¿se quejó alguien de casa?". Una línea en `docs/decisiones.md` cierra el incidente |
| Entorno de staging permanente | **NO** | Una VM desechable + snapshot previo cubre lo mismo sin coste fijo |

**Energía y ruido — el coste que se olvida al comprar.**
`coste_anual ≈ W_medios × 8,76 × €/kWh`. Con el precio doméstico español de ago-2026 (≈0,10-0,20
€/kWh según tarifa y tramo; **verificar**), cada vatio permanente cuesta del orden de 1-2 €/año.
Un mini-PC N100/N150 en idle ronda 5-10 W (≈8-20 €/año); un servidor *enterprise* de segunda mano
(R730, DL380 Gen9) parte de 100-200 W idle: **cientos de euros al año**, más ruido de aeropuerto y
un rack que no cabe. La regla: **suma tres años de electricidad al precio de compra** antes de
decidir. El hierro usado gana cuando necesitas RAM ECC barata, muchos discos o lanes PCIe; pierde
en casi todo lo demás.

**UPS**: dimensionar para **apagado ordenado**, no para aguantar el corte. NUT (o apcupsd)
configurado, integrado con Proxmox/hosts, y el apagado **probado tirando del cable** — una UPS que
no apaga nada es un pisapapeles caro.

**Documentar el lab que olvidarás**: cada stack con un README de cuatro líneas (qué es, por qué
está, cómo se restaura, qué se rompe si lo apago), un diagrama de red que se actualiza cuando
cambia la red, y `docs/decisiones.md` con el **porqué** — el qué se lee del código, el porqué no.

## 7. Sostenibilidad y prohibiciones

**Cadencia y *blast radius***
- Seguridad del SO: automática. Apps: mensual, en ventana elegida por ti (no cuando la casa está
  viendo Jellyfin). *Majors*: leyendo release notes, uno por sesión.
- **Ley del lab: un cambio, una noche.** Nunca tocar el mismo día DNS, IdP, proxy o almacenamiento
  junto con otra cosa: son las cuatro dependencias de todo lo demás y depurar dos cambios a la vez
  cuesta el triple.
- Snapshot antes, plan de vuelta atrás escrito **antes** de empezar. Traefik solo da soporte a la
  última minor: presupuesta upgrades frecuentes o elige Caddy.
- Poda semestral: servicio que nadie ha usado en seis meses se apaga (y se borra un mes después, si
  nadie lo reclama). Un lab crece por acumulación hasta que deja de mantenerse.

**PROHIBIDO**
- ❌ Abrir puertos entrantes en el router hacia paneles, SSH, RDP o apps "solo un momento".
- ❌ `latest` en cualquier imagen que guarde datos; actualizar sin saber qué versión venía antes.
- ❌ Montar el socket del daemon de contenedores en una app; `--privileged` por defecto.
- ❌ Secretos en compose, en `.env` en claro o en el historial de git.
- ❌ Llamar backup a un snapshot, a un RAID o a una sincronización (Syncthing propaga el borrado).
- ❌ Backup sin **restore probado**, o con la clave de cifrado guardada únicamente dentro del lab.
- ❌ Dependencias circulares en el arranque (DNS/IdP/secretos dentro de lo que necesitan para vivir).
- ❌ Hacer del lab un SPOF de servicios que usa la familia sin plan de fallo ni aviso (el DNS de la
  casa y Home Assistant son los reincidentes).
- ❌ Comprar hardware sin calcular consumo, ruido y a dónde va físicamente.
- ❌ `.local`/`.lan`/TLDs inventados para el DNS interno.
- ❌ "Lo documento luego" y "lo arreglo luego" sin una nota fechada en el repo.
- ❌ Copiar una arquitectura de empresa (HA, mesh, GitOps, SIEM) sin poder explicar **qué fallo
  concreto de tu lab** evita.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión o dato, **búscalo — no lo recuerdes**. Este ecosistema se mueve
por semanas:
- Última estable de: **k3s / Talos** (y qué Kubernetes empaquetan), **Traefik / Caddy** (y qué
  minors siguen soportadas), **Authentik / Authelia**, **restic / Kopia / Borg** (¿sigue Borg 2.0
  en beta?), **Podman** (Quadlet), **Proxmox VE**, **NUT**, **Uptime Kuma / Beszel**.
- **CVEs abiertos** del servicio que vas a exponer o poner en el camino crítico (proxy, IdP, panel)
  antes de desplegarlo — con especial atención a NPM (CVE-2026-40519) y a cualquier UI de gestión.
- **Novedades de ACME/Let's Encrypt**: perfiles (`shortlived`, 160 h, GA ene-2026), certificados
  para direcciones IP, y el fin del aviso de caducidad por email (jun-2025) — si dependías de esos
  correos para enterarte, ya no llegan: monitoriza tú la caducidad.
- **Planes y límites de Tailscale/Cloudflare/Headscale**: cambiaron en abr-2026 y volverán a cambiar.
- **Precios de almacenamiento offsite** (Hetzner, B2, rsync.net, R2) y su política de egress y de
  operaciones antes de calcular el coste mensual.
- **Precio del kWh** vigente y consumo medido con enchufe medidor antes de justificar una compra de
  hardware por eficiencia.

Si no puedes verificar, dilo explícitamente en vez de suponer.
Si la web contradice este documento, **manda la web** y señala la discrepancia.
