---
name: vpn-standards
description: VPN tunnels and remote access as a designed, operated service. Use when writing or reviewing wg0.conf and its AllowedIPs, PersistentKeepalive, Endpoint, PresharedKey or Table= keys, running wg genkey/pubkey/show/setconf or wg-quick up/down, choosing wg-quick versus systemd-networkd [WireGuard]/[WireGuardPeer] or NetworkManager wireguard profiles, swanctl.conf and ipsec.conf/ipsec.secrets with charon, IKEv2 proposals and esp/ah rekeying, phase-2 proposal mismatch, MOBIKE, ke1_mlkem768 and RFC 9370 hybrid key exchange, client.ovpn and server.conf with tls-crypt, tls-auth, dev tun, redirect-gateway and the ovpn-dco kernel module, tailscale up --advertise-routes/--exit-node and tailnet ACL grants, netbird up, headscale nodes/preauthkeys, nebula-cert sign and lighthouse config, zerotier-cli join, rosenpass psk exchange, split tunneling and DNS-leak decisions, short-lived client certificates versus permanent keys, overlapping site subnets, concentrator redundancy and session logging, or hardening an internet-facing remote-access appliance.
---

# Estándares de VPN — túneles y acceso remoto

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **elegir, diseñar, desplegar, operar y retirar un túnel cifrado y el acceso remoto que
se apoya en él**: decisión entre sitio-a-sitio, acceso remoto de usuario y malla; el desplazamiento
del mercado hacia ZTNA; WireGuard y su modelo de claves; mallas con plano de control (Tailscale,
NetBird, Netmaker, ZeroTier, Nebula, Headscale) y el riesgo de delegar ese plano; IPsec/IKEv2 por
interoperabilidad; OpenVPN donde sigue justificado; postura del cliente y ciclo de vida del acceso;
operación del túnel (MTU/MSS, resolución dentro del túnel, rutas y solapamientos, redundancia y
capacidad del concentrador); y la seguridad del concentrador como activo expuesto y como fuente de
evidencia forense.

Triggers: `wg0.conf`, `[Interface]`/`[Peer]`, `AllowedIPs`, `PersistentKeepalive`, `Endpoint`,
`PresharedKey`, `Table=`, `wg genkey|pubkey|show|setconf|syncconf`, `wg-quick up|down`,
`systemd-networkd` `.netdev` con `[WireGuard]`/`[WireGuardPeer]`, perfiles `wireguard` de
NetworkManager, `swanctl.conf`, `ipsec.conf`, `ipsec.secrets`, `charon`, `strongswan`,
`ke1_mlkem768`, `ppk=yes`, `client.ovpn`, `server.conf`, `tls-crypt`, `redirect-gateway`,
`ovpn-dco`/`win-dco`, `tailscale up`, `--advertise-routes`, `--exit-node`, ACL/`grants` del tailnet,
`netbird up`, `headscale nodes|preauthkeys`, `nebula-cert`, `lighthouse`, `zerotier-cli join`,
`rosenpass`, "split tunneling", "fuga de DNS", "solapamiento de subredes", "concentrador VPN",
"acceso remoto", "always-on VPN".

**Principio rector** (hereda el de `networking-standards`: *la red es default-deny y documentada
como código; lo que no está en el SoT no existe*): **el túnel transporta, no autoriza**. Un paquete
que sale de `wg0` es un paquete no confiable que acaba de entrar en tu red: estar dentro de la VPN
no es una credencial, no es una autorización y no sustituye a ninguna política. Todo túnel tiene
dueño, alcance escrito, caducidad y una regla de filtrado que lo recibe.

**No aplica**: ver `networking-standards` (**madre**: topología y direccionamiento/IPAM que evita
los solapamientos, VLAN y segmentación, routing y BGP para anunciar los prefijos del túnel,
**MTU/MSS como criterio de diseño de red**, proxies y balanceo, **elección de la plataforma de
perímetro** —OPNsense/VyOS/appliance—, plano de gestión OOB y ZTNA como principio de arquitectura),
`firewall-policy-standards` (**la política que filtra el tráfico que sale del túnel**: matriz de
flujos, `forward` con `policy drop`, egress, dueño/caducidad de cada regla, MSS clamping como regla,
conntrack — un `wg0` que entra en `forward` sin reglas es una VPN sin firewall; **aquí se decide qué
túnel existe y cómo se opera, allí qué atraviesa**),
`network-troubleshooting-standards` (**diagnóstico reactivo**: "la VPN conecta pero no navego" es
**suyo** —es MTU/PMTU y se demuestra con captura en ambos extremos—, igual que "se cae a los 5
minutos", "resuelve mal dentro del túnel" o "va bien un rato"; **aquí se fija el valor correcto de
MTU/keepalive/DNS y por qué**, allí se averigua cuál está mal en un caso concreto),
`identity-access-management-standards` (**la identidad**: IdP, OIDC/SAML, MFA resistente a phishing,
passkeys, SSO, SCIM y desprovisión, PAM/JIT y cuentas break-glass — **el usuario y su autenticación
son suyos, el túnel y su terminación son de aquí**),
`cryptography-pki-standards` (**los algoritmos, la PKI y los certificados del túnel**: suites,
tamaños de clave, emisión y revocación de certificados de cliente y de gateway, CRL/OCSP, ACME,
custodia de la CA, criterio de migración post-cuántica — **aquí sólo qué se configura en el túnel y
con qué vida útil**), `secrets-management-standards` (custodia y rotación de las claves privadas,
PSK y tokens de enrolamiento; nunca en el repo ni en el fichero de config),
`dns-standards` (**el servicio DNS y sus datos**: qué resolver es legítimo, split-horizon, zonas
internas; **aquí sólo qué resolver se empuja al cliente y cómo se evita que consulte fuera**),
`detection-engineering-standards` (reglas y analítica sobre los logs de sesión VPN: geolocalización
imposible, fuerza bruta, sesiones concurrentes),
`incident-response-forensics-standards` (el compromiso del concentrador como incidente: contención,
imagen del appliance, cadena de custodia, rotación masiva de credenciales),
`vulnerability-management-standards` (triaje y SLA de parcheo de los CVE de concentrador con
KEV/EPSS — **aquí el argumento de exposición, allí la cadencia formal**),
`observability-standards` (métricas, dashboards y alertas del túnel como servicio),
`sre-practice-standards` (SLO del acceso remoto y presupuesto de error),
`incident-management-standards` (mando y comunicación cuando la caída de la VPN es un incidente
declarado), `linux-hardening-standards` (baseline del host que termina el túnel, `sysctl` de
reenvío, sandboxing systemd del demonio), `selinux-standards` (confinamiento del proceso),
`linux-administration-standards` (unidades systemd, `systemd-networkd`, `resolvectl` y la
resolución **desde el host**), `bash-linux-scripting-standards` (scripts de automatización),
`kubernetes-standards` (service mesh y mTLS entre pods: **no** es una VPN),
`microservices-architecture-standards` (mTLS este-oeste entre servicios),
`aws-standards`/`azure-standards`/`gcp-standards` (Site-to-Site VPN, Virtual Network Gateway, Cloud
VPN y sus ZTNA gestionados como servicio del proveedor), `iac-standards`/`cicd-standards` (el código
y el pipeline que despliegan la config), `onprem-standards` (paraguas de plataforma),
`homelab-standards` (túnel doméstico: la frontera es el rigor exigido, no el tamaño),
`grc-compliance-standards` (el acceso remoto como control auditable ante ENS/ISO/NIS2/DORA),
`bcdr-standards` (el acceso remoto como dependencia crítica de la recuperación: si el DR depende de
la VPN, la VPN es parte del DR), `offensive-security-standards` (validación ofensiva del acceso
remoto, con alcance y autorización).

También existen y son frontera: `ha-clustering-standards` (el par de concentradores como recurso de
clúster: VIP, quórum, fencing y failover — **la mecánica de HA es suya, el estado del túnel que debe
sobrevivir al failover es de aquí**) y `podman-systemd-containers-standards` (el demonio del túnel o
el agente de malla ejecutado como contenedor con Quadlet: unidad, red y privilegios son suyos).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión y el estado del proyecto **por web** antes de fijar nada (§8).
> Fechas de release obtenidas de `api.github.com` y del git upstream, no de páginas HTML.

| Ámbito | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| Protocolo de túnel | **WireGuard** in-kernel (Linux ≥5.6; `wireguard-tools` **1.0.20260223**, 23-feb-2026) | IPsec/IKEv2 con **strongSwan 6.0.7** (08-jun-2026) cuando hay que interoperar con equipo de terceros o exigen FIPS/PQC estandarizado | PPTP, L2TP sin IPsec, SSL-VPN propietaria sin parcheo, cualquier cripto negociable con suites débiles |
| WireGuard en userspace | Sólo donde **no** hay implementación en kernel (macOS, Windows, contenedor sin privilegios): `wireguard-go` | — | `wireguard-go` en un Linux moderno "porque ya funciona": copia por paquete y coste fijo de context switch |
| Gestión de la interfaz WG | **`systemd-networkd`** (`.netdev` con `[WireGuard]`/`[WireGuardPeer]` + `.network`) en servidores | `wg-quick` en hosts sencillos y clientes; NetworkManager en escritorio | Scripts propios que reimplementan `wg-quick` a medias |
| Malla con plano de control | **NetBird** (control plane 100% open source y self-hostable, binario unificado desde 0.65; **0.76.1**, 31-jul-2026) o **Headscale 0.29.3** (29-jul-2026) si quieres cliente Tailscale sin su coordinador | **Tailscale** cuando el valor es el producto gestionado y aceptas el modelo; **Nebula 1.11.0** (23-jul-2026, MIT, basado en certificados, sin SaaS) para sitios aislados o desconectados | Malla WireGuard manual con más de ~10 nodos: la distribución de claves no escala |
| Acceso remoto de usuario | **ZTNA por aplicación** con identidad del IdP (`identity-access-management-standards`) sobre el túnel | VPN de concentrador cuando el acceso es a red heredada no publicable por aplicación | VPN full-tunnel que concede "la red" y llamarlo control de acceso |
| SSL-VPN sobre TCP/443 | **OpenVPN 2.7.5** (02-jul-2026) sólo para redes hostiles que bloquean UDP y para clientes heredados | 2.6.21 (02-jul-2026) donde 2.7 aún no esté empaquetado | OpenVPN como default nuevo por costumbre; TCP-sobre-TCP como modo habitual |
| Aceleración OpenVPN | **DCO**: módulo `ovpn` **upstream en Linux 6.16**, `win-dco` por defecto en Windows | `ovpn-backports` en kernels anteriores; `tap-windows6` sólo para lo que `win-dco` no cubre | `wintun` en Windows (**eliminado en 2.7**) |
| Post-cuántico | **strongSwan ≥6.0.x con RFC 9370** (`ke1_mlkem768`) + PPK (RFC 8784) cuando el requisito es real y estandarizado | Rosenpass sobre WireGuard (**pre-1.0**: v0.2.3, 03-ago-2026) en escenarios donde asumas software pre-1.0 | Prometer "quantum-safe": **WireGuard no trae PQC de serie**; sólo el hueco de PSK |
| Terminación | Host Linux dedicado y minimalista, o plataforma de perímetro de la casa | Appliance comercial si ya es el estándar, con el parcheo de §5 aceptado como compromiso | Concentrador comercial sin ventana de parcheo de emergencia comprometida por escrito |
| Autenticación de máquina | Clave pública WireGuard registrada + PSK opcional; o certificado X.509 de **vida corta** en IPsec/OpenVPN | — | Clave o certificado permanente sin caducidad ni revocación probada |
| Autenticación de usuario | **MFA resistente a phishing** (passkeys/WebAuthn, FIDO2) delegada en el IdP | TOTP sólo como paso intermedio con fecha de salida | SMS, push sin *number matching*, o "el certificado ya identifica al usuario" |
| Filtrado del tráfico del túnel | `forward` con `policy drop` y matriz de flujos (`firewall-policy-standards`) | — | `wg0` en `forward` sin reglas |

**Criterio de elección, no de gusto.** WireGuard si controlas ambos extremos. IPsec si el otro
extremo lo impone o hay requisito de certificación. OpenVPN si el camino es hostil y necesitas
TCP/443. Malla gestionada si tienes clientes móviles, NAT por todas partes y ACL por identidad.
ZTNA si lo que necesitas publicar es **una aplicación**, no una red.

## 3. Estructura y convenciones

### 3.1 La decisión de partida: qué modelo resuelve tu problema

| Modelo | Qué resuelve | Qué **no** resuelve |
|---|---|---|
| **Sitio a sitio** | Unir dos redes con enrutado estable, pocos extremos, direcciones conocidas | Identidad de usuario, movilidad, granularidad por aplicación |
| **Acceso remoto de concentrador** | Meter un portátil "dentro" para alcanzar servicios heredados | Autorización: da red, no aplicaciones. Escala mal y concentra riesgo |
| **Malla (mesh)** | Muchos extremos móviles tras NAT, conectividad directa peer-to-peer, ACL por identidad | El plano de control se convierte en tu nueva raíz de confianza |
| **ZTNA / proxy por aplicación** | Publicar una aplicación concreta a una identidad concreta, sin dar red | Protocolos que no son publicables por aplicación; dependencia del proveedor |

- **El desplazamiento del mercado es real y tiene causa técnica, no de moda**: la VPN de
  concentrador otorga acceso *de red* tras una única autenticación, y ese modelo se rompió por dos
  vías simultáneas — (1) el concentrador se convirtió en el objetivo preferente y explotado (§5.1),
  y (2) el perímetro dejó de existir con SaaS y teletrabajo. NIST SP 800-207 lo dice sin rodeos: la
  ubicación en la red no otorga confianza.
- **Traducción operativa, no eslogan**: no hay que "quitar la VPN". Hay que (a) **dejar de usar el
  túnel como autorización** —cada acceso se autoriza por identidad, dispositivo y aplicación—, y
  (b) reducir la VPN al transporte de lo que aún no se puede publicar por aplicación, con alcance
  mínimo y caducidad. La VPN sobrevive como **capa de transporte**, muere como **capa de confianza**.
- **Criterio de migración**: publica primero lo que es HTTP(S) (proxy/ZTNA), después lo que habla un
  protocolo con identidad propia (SSH con certificados, RDP tras broker), y deja en el túnel el
  resto —con inventario y fecha de revisión. Una VPN que "se queda para todo lo demás" sin lista es
  la VPN de siempre con nombre nuevo.

### 3.2 WireGuard: lo que hay que entender antes de escribir un `wg0.conf`

- **Cripto fija y sin negociación**: ChaCha20-Poly1305, Curve25519, BLAKE2s, HKDF. No hay suites que
  elegir, no hay downgrade que negociar y no hay "phase 1/phase 2" que descuadrar. Ese es su valor
  principal frente a IPsec y no se toca; si tu requisito exige agilidad criptográfica o algoritmo
  certificado concreto, **WireGuard no es tu protocolo** (ver `cryptography-pki-standards`).
- **UDP y silencio por diseño**: no responde a quien no presenta una clave válida. Un escaneo no lo
  ve. Eso reduce superficie, pero también significa que **el fallo de conexión no te dice nada**:
  el diagnóstico es asimétrico y necesita captura en ambos extremos
  (`network-troubleshooting-standards`).
- **`AllowedIPs` es enrutado *y* control de acceso a la vez — el error conceptual más común.**
  - En **salida**: define qué destinos se encaminan por ese peer (`wg-quick` crea la ruta).
  - En **entrada**: es *cryptokey routing* — un paquete que llega por el túnel con origen **fuera**
    del `AllowedIPs` de ese peer **se descarta**. Es la única autorización que WireGuard tiene.
  - Consecuencia práctica: **`AllowedIPs = 0.0.0.0/0, ::/0` en un peer cliente del servidor
    significa "este peer puede suplantar cualquier origen"**. Cada peer lleva **exactamente** su
    `/32` (y su `/128`), o el prefijo del sitio que legítimamente enruta, y nada más.
  - `0.0.0.0/0` es legítimo **sólo en el lado cliente hacia el servidor** (full-tunnel) o en un peer
    que es de verdad la salida por defecto.
  - Esto **no** sustituye al firewall: WireGuard valida el origen, no el destino ni el puerto.
- **Claves**: una clave privada por dispositivo, generada **en el dispositivo** (`wg genkey`),
  nunca reutilizada entre nodos ni entre entornos, `umask 077`, fichero `0600`, y nunca en el repo
  (`secrets-management-standards`). La clave pública es un identificador de dispositivo, no de
  persona: **no hay identidad de usuario en WireGuard**.
- **Rotación**: WireGuard no rota claves solo. La rotación es una operación coordinada (añadir el
  nuevo peer, migrar, retirar el viejo) y por eso, más allá de unos pocos nodos, se automatiza o no
  se hace — que es exactamente el argumento para una malla gestionada (§3.3). Fija una cadencia
  (anual como suelo, inmediata ante baja o sospecha) y **prueba la retirada**: un peer eliminado del
  servidor pierde el acceso al instante; comprobarlo es el gate.
- **`PresharedKey`**: capa simétrica adicional por par de peers. Su uso previsto es **resistencia
  post-cuántica** (§3.6), no "más seguridad" genérica. Si se usa, es un secreto más que custodiar y
  rotar por par.
- **`PersistentKeepalive`**: **25 s** es el valor de referencia para el peer que está tras NAT o
  firewall stateful, y sirve para que la asociación de NAT no expire. Reglas: lo pone **el lado que
  está detrás del NAT**, no el servidor público; ponerlo en todos los peers de una malla es tráfico
  y batería a cambio de nada. Sin él, el síntoma es el clásico "funciona cuando yo inicio, no cuando
  inician ellos" y "se cae cuando dejo de usarlo".
- **Roaming**: WireGuard actualiza el `Endpoint` del peer al recibir un paquete autenticado desde
  una IP nueva. Es su gran virtud móvil, y también el motivo por el que **filtrar por IP de origen
  del cliente no funciona** como control.
- **Límites reales que hay que decir en voz alta**: sin gestión de identidad, sin autenticación de
  usuario, sin MFA, sin distribución de claves, sin ACL más allá de `AllowedIPs`, sin NAT traversal
  propio (necesita un extremo alcanzable o un relé), sin revocación centralizada. Todo eso lo pone
  otra capa; si no la pones tú, no está.
- **`Table = off`** cuando quieres controlar el enrutado a mano (routing dinámico sobre el túnel,
  policy routing); con `Table` automático y `AllowedIPs = 0.0.0.0/0`, `wg-quick` instala reglas de
  política que pueden romper el acceso de gestión del propio host. Cambio remoto ⇒ ventana de
  rescate abierta (§4).

### 3.3 Mallas gestionadas: qué compras y qué entregas

**Qué aportan sobre WireGuard puro** (y por qué a partir de cierto tamaño no es opcional):
identidad federada contra tu IdP, distribución y rotación automática de claves, **ACL por identidad
y no por IP**, NAT traversal (STUN/UPnP/hole punching) con **relés de respaldo** cuando el punch
falla —DERP en Tailscale/Headscale, relés propios en NetBird—, DNS de malla, altas y bajas
inmediatas, y visibilidad de qué nodo habla con cuál.

**Qué entregas: el plano de control es la nueva raíz de confianza.**
- Quien controla el coordinador **distribuye claves, ACL y rutas**. Su compromiso no es "una fuga de
  metadatos": es la capacidad de introducir un nodo en tu red o de reescribir quién puede hablar con
  quién. Trátalo con el mismo criterio que tu IdP o tu CA, no como una herramienta de red.
- **Evidencia de que el cliente y el plano son superficie real, no teórica** — boletines propios de
  Tailscale de 2026 (verbatim de su página de boletines): **TS-2026-004** (04-jun) *Tailscale SSH
  Unix socket forwarding did not respect symlink permissions*; **TS-2026-005** (03-jun) *Tailscale
  Serve Unix socket proxy targets were not restricted to `root`*; **TS-2026-006** (11-jun) *Tailscale
  SSH allowed users to be addressed by numeric UID, bypassing `root` user restrictions*;
  **TS-2026-007** (10-jul) *Insufficient inbound packet filtering in Services permitted access to
  loopback-bound listeners*; **TS-2026-008** (13-jul) *A single malformed HTTP request to a node
  running Tailscale Serve or Funnel could pin a CPU core indefinitely*; **TS-2026-009** (13-jul)
  *Insecure command line argument handling in Tailscale SSH permitted `root` user access in
  violation of ACLs*. Léelo como lo que es: **agente con privilegios en todos tus nodos**, con
  funciones que exponen servicios y que se saltan ACL cuando fallan. Suscríbete a los boletines del
  proveedor que elijas y trata su parcheo como parcheo de agente privilegiado, no de app.
- **Preguntas que se responden por escrito antes de adoptar**: ¿el plano de control es
  self-hostable? ¿el proveedor puede añadir un nodo a tu red sin tu consentimiento? ¿los relés ven
  tráfico en claro (no deberían: el cifrado es extremo a extremo) o sólo lo reenvían? ¿dónde vive el
  plano y bajo qué jurisdicción? ¿qué pasa con la red si el proveedor cae —los túneles ya
  establecidos sobreviven, las altas no? ¿qué historial de boletines tiene? ¿qué licencia y qué
  modelo de negocio, y qué pasa si cambian?
- **El modelo de negocio cambia y te afecta**: en 2026 hubo movimiento de precios y licencias en
  este espacio (Tailscale hacia precio por asiento; ZeroTier endureciendo el controlador
  autohospedado; NetBird formalizando su edición autohospedada). **No fijes de memoria ninguna de
  esas condiciones** — verifica la vigente antes de comprometer una plataforma (§8).
- **Criterio de salida escrito desde el día uno**: qué haces si el proveedor cambia licencia, sube
  precio o desaparece. La opción "todo el plano en casa" (Headscale/NetBird self-hosted/Nebula) es
  precisamente el seguro contra eso, con el coste de operarlo tú.
- **Nebula** es la elección distinta: basado en **certificados** con CA propia, sin llamada a casa,
  sin SaaS; a cambio, la operación de la CA y el `lighthouse` son tuyas
  (`cryptography-pki-standards`).

### 3.4 IPsec/IKEv2: cuándo y con qué disciplina

- **Se usa cuando el otro extremo lo impone** (appliance de un tercero, operador, requisito de
  certificación) o cuando necesitas PQC estandarizado (§3.6). Es más complejo y con más superficie
  —el historial de CVE de strongSwan de 2026 lo confirma (§8)—, pero sigue vivo porque es el único
  denominador común entre fabricantes.
- **IKEv2 siempre**; IKEv1, agresivo, XAUTH y PSK de grupo, vetados.
- **El clásico *mismatch* de fase 2**: la fase 1 (IKE_SA) levanta, la fase 2 (CHILD_SA) no, y el log
  no lo dice claro. Causas por orden de frecuencia: propuestas ESP que no coinciden (cifrado, MAC,
  grupo PFS), **selectores de tráfico** (`local_ts`/`remote_ts`) que no son idénticos y espejados en
  ambos lados, y modo túnel vs. transporte. **Regla**: la propuesta se acuerda **por escrito** con
  el tercero antes de configurar, se escribe **explícita** en ambos extremos (nada de listas largas
  "por si acaso", que enmascaran el desacuerdo y negocian a la baja), y los selectores se comparan
  literalmente. Un lado con `0.0.0.0/0` y el otro con `/24` es la causa nº1 de "levanta y se cae".
- **Rekeying**: define vidas de IKE_SA y CHILD_SA coherentes en ambos extremos y con márgenes
  distintos, o tendrás cortes periódicos exactos (síntoma: "se cae cada 8 horas"). Sospecha del
  rekey ante cualquier caída con periodicidad regular.
- **MOBIKE (RFC 4555)** para clientes móviles: permite cambiar de IP/interfaz sin renegociar. Es lo
  que hace usable IKEv2 en un portátil que salta de WiFi a 4G. Actívalo o asume reconexiones.
- **Fragmentación IKE**: los mensajes con certificados o con claves PQC superan la MTU. Activa
  fragmentación IKEv2 (RFC 7383) y **no bloquees ICMP**; si no, el túnel "a veces no levanta" según
  qué certificado use el cliente.
- **NAT-T (UDP/4500)**: necesario en casi todo escenario real. `strongswan` moderno se configura con
  `swanctl.conf`; `ipsec.conf`/`starter` es la vía heredada y en retirada.
- **DPD (dead peer detection)** activo en ambos lados, o un túnel muerto seguirá "arriba" en la
  tabla y el tráfico caerá en un agujero negro.

### 3.5 OpenVPN: dónde sigue justificado

- **Justificaciones válidas y sólo esas**: el camino bloquea UDP y necesitas **TCP/443** para
  parecer tráfico web; hay clientes heredados o plataformas sin cliente WireGuard aceptable;
  necesitas autenticación de usuario integrada (PAM, LDAP, plugins) sin montar otra capa.
- **TCP-sobre-TCP es una penalización real** (*TCP meltdown*): úsalo como plan B, no como default.
  Si UDP está disponible, UDP.
- **Config mínima no negociable**: `tls-crypt` (mejor que `tls-auth`: además de autenticar, cifra el
  canal de control y oculta la huella de OpenVPN), certificados de servidor **y** de cliente con
  `remote-cert-tls`, CRL activa y probada, cifrado AEAD (AES-GCM/ChaCha20-Poly1305), TLS ≥1.2 con
  1.3 preferido, y `verify-x509-name` para que un certificado de cliente no pueda hacerse pasar por
  el servidor.
- **DCO cambia el rendimiento y el modelo de despliegue**: módulo `ovpn` **upstream desde Linux
  6.16** (sustituye al out-of-tree `ovpn-dco-v2`; `ovpn-backports` para kernels anteriores), y en
  Windows `win-dco` es el default con `tap-windows6` como respaldo — `wintun` **fue eliminado** en
  2.7. Si dependías de `wintun`, es un cambio de despliegue, no un detalle.
- **`redirect-gateway`** convierte el cliente en full-tunnel: es una **decisión de riesgo**
  (§3.7), no un valor por defecto.

### 3.6 Post-cuántico: lo que hay hoy y lo que no

- **WireGuard no trae PQC de serie.** Su cripto es fija; el único punto de extensión es el
  `PresharedKey`, y por diseño (el propio proyecto lo documenta como uso previsto del hueco).
  **Prohibido vender un despliegue WireGuard como "quantum-safe"**.
- **Vía WireGuard**: **Rosenpass** ejecuta un intercambio PQ aparte e inyecta el resultado en el
  hueco de PSK, refrescándolo periódicamente; el protocolo WireGuard queda intacto. Estado real:
  **pre-1.0** (v0.2.3, 03-ago-2026). Adóptalo sabiendo que es software pre-1.0 y que su
  despliegue es **todo-o-nada por peer** salvo modo permisivo. NetBird lo integra como opción.
- **Vía IPsec**: **RFC 9370** (múltiples intercambios de clave en IKEv2, con `IKE_INTERMEDIATE` para
  que las claves grandes no revienten el `IKE_SA_INIT`) + **RFC 8784** (PPK) es la ruta
  estandarizada. strongSwan la soporta desde 6.0.0 (`ke1_mlkem768`, `ppk=yes`). Es la opción
  defendible si el requisito es formal/certificable.
- **Criterio**: el modelo de amenaza es *harvest now, decrypt later*. Si tu tráfico tiene valor a
  10+ años, el híbrido (clásico **+** PQ, nunca PQ solo) es hoy razonable en IPsec y experimental en
  WireGuard. Los algoritmos, su estado de estandarización y el plan de migración se deciden en
  `cryptography-pki-standards`, no aquí.

### 3.7 Acceso remoto de usuario: el ciclo completo

- **Identidad primero**: autenticación contra el IdP corporativo con **MFA resistente a phishing**
  (passkeys/FIDO2). Nada de secreto compartido, nada de "el certificado ya es el usuario", nada de
  SMS. La política y el IdP, en `identity-access-management-standards`.
- **Credenciales de vida corta > claves permanentes.** El objetivo es que la credencial del cliente
  caduque sola: certificado de vida corta emitido tras autenticar en el IdP, o token/perfil que
  expira. Una clave permanente en un portátil perdido es acceso permanente hasta que alguien se
  acuerde de revocarlo. Si usas claves permanentes (WireGuard puro), **la revocación es un proceso
  con dueño y con prueba**, no una intención.
- **Split tunneling: decisión de riesgo explícita y documentada**, nunca un default heredado.
  - *Full tunnel*: todo el tráfico pasa por la organización — inspección, filtrado y registro
    completos; a cambio, latencia, coste de ancho de banda, capacidad del concentrador y un SPOF de
    conectividad para el usuario.
  - *Split tunnel*: sólo lo corporativo entra al túnel — rendimiento y coste mejores; a cambio,
    pierdes visibilidad del resto del tráfico del dispositivo y aceptas que el endpoint está
    expuesto a Internet mientras está "dentro".
  - **Criterio**: si tu control de contenido y tu telemetría viven en el endpoint (EDR + resolución
    DNS forzada + proxy), el split tunnel es defendible; si viven en el perímetro, el split tunnel
    los desactiva. Decide, escríbelo y **revísalo**; el híbrido (split por destino, con lo sensible
    y el DNS forzados al túnel) es el punto de equilibrio habitual.
  - Lo que **nunca** es aceptable: split tunneling que deje la resolución DNS fuera del túnel
    (§3.8) o que permita al cliente actuar de puente entre Internet y la red corporativa.
- **Postura del dispositivo** como condición de acceso: dispositivo gestionado e inventariado,
  disco cifrado, EDR vivo y actualizado, SO parcheado, y **reevaluación continua**, no sólo en la
  conexión. Un portátil que cumplía al conectar y deja de cumplir a la hora debe perder el acceso.
  BYOD sin postura ⇒ ZTNA por aplicación, jamás túnel de red.
- **Desprovisión el mismo día** — y "el mismo día" es un compromiso medible: la baja en el IdP
  revoca el acceso VPN, revoca el certificado, elimina el peer del concentrador y **corta las
  sesiones activas**. La mayoría de los despliegues fallan en ese último punto: bloquear el login
  no expulsa a quien ya está dentro. Prueba la desprovisión trimestralmente con una cuenta de
  ensayo (§4).
- **Always-on con excepción de portal cautivo**: el cliente levanta el túnel al arrancar y sólo
  permite tráfico fuera de él para el portal de la red visitada, con caducidad corta.

### 3.8 Operación del túnel: lo que rompe en la práctica

- **MTU y MSS: la causa nº1 de "la VPN conecta pero algunas webs no cargan"** — el handshake TCP
  (paquetes pequeños) funciona, la transferencia (paquetes grandes con DF) se cuelga.
  - Ajusta la **MTU del túnel** *y además* haz **MSS clamping** en `forward`: son medidas
    complementarias, no alternativas. Los valores de referencia y el cálculo, en
    `networking-standards`; la regla nft que lo aplica, en `firewall-policy-standards`.
  - **No bloquees ICMP tipo 3 código 4** (*fragmentation needed*) ni ICMPv6 *packet-too-big*: sin
    ellos PMTUD muere y el fallo es silencioso e intermitente.
  - Vigila el offload (GRO/GSO/TSO) en la interfaz del túnel: agrega por encima de la MTU y
    descarta con DF activo.
  - El **diagnóstico** de un caso concreto es de `network-troubleshooting-standards`; aquí se fija
    que el valor debe estar puesto, probado con paquete grande y DF, y documentado.
- **DNS dentro del túnel y fugas de DNS**: el cliente debe usar el resolver corporativo para lo
  corporativo. Las fugas típicas son (a) el cliente conserva el resolver del DHCP local, (b) el SO
  consulta a varios resolvers en paralelo y gana el de fuera, (c) el navegador usa **DoH propio** y
  se salta el resolver del sistema entero, y (d) mDNS/NetBIOS resolviendo por fuera. Controles:
  empujar el resolver y los dominios de búsqueda desde el túnel, política de navegador que
  desactive el DoH no controlado, y **verificación activa** de que la consulta sale por donde debe.
  Qué resolver es legítimo y cómo se diseña: `dns-standards`.
- **Rutas y solapamiento de direccionamiento** — el clásico de fusionar dos sedes con
  `192.168.1.0/24`: **no hay arreglo elegante**, sólo tres salidas, en orden de preferencia:
  (1) **renumerar** uno de los lados (correcto, doloroso, definitivo); (2) **NAT 1:1** del prefijo
  solapado en el túnel, con un rango "espejo" documentado en el IPAM —funciona, rompe todo lo que
  lleve IPs embebidas en el protocolo o en configuración, y multiplica el coste de diagnóstico;
  (3) publicar sólo servicios concretos por proxy/ZTNA y no unir las redes. La prevención es de
  `networking-standards`: **plan de direccionamiento con bloques grandes y sin solapes desde el
  día uno**, porque las fusiones llegan.
- **Rutas anunciadas con criterio**: un peer que anuncia `0.0.0.0/0` a la malla se convierte en la
  salida de todo el mundo sin que nadie lo decida. Las rutas del túnel se aprueban como cualquier
  otro cambio de routing, y se filtran (`AllowedIPs` en WireGuard, ACL de rutas en la malla,
  `--advertise-routes` que requiere aprobación explícita en Tailscale/Headscale/NetBird).
- **Redundancia y capacidad del concentrador**: par activo/pasivo o activo/activo con nombre DNS o
  IP virtual, failover **ejercitado**, y dimensionado por **usuarios concurrentes en el peor día**
  (no por plantilla) con margen para el escenario de continuidad —marzo de 2020 enseñó que el
  concentrador dimensionado al 30% de la plantilla es un incidente de negocio. Si el DR depende de
  la VPN, la VPN es infraestructura crítica de DR (`bcdr-standards`).
- **El túnel se monitoriza como servicio, no como interfaz**: "el peer está configurado" no es
  "el túnel funciona". Ver §6.

## 4. Gates de calidad obligatorios

En orden de coste creciente. Los cinco primeros bloquean el despliegue.

1. **Validación de configuración antes de aplicar**: `wg-quick strip` / `wg setconf` contra la
   config candidata, `swanctl --load-all` en modo prueba, `openvpn --config ... --test-crypto`,
   `networkctl` para las unidades. Config que no valida no llega ni a staging.
2. **Revisión de `AllowedIPs` como gate de seguridad, no de red**: ningún peer con más alcance del
   que le corresponde; `0.0.0.0/0`/`::/0` sólo en el lado que legítimamente lo requiere y con
   justificación escrita. Este gate es el equivalente WireGuard del "any/any" del firewall.
3. **Ventana de rescate abierta en todo cambio remoto** que toque túnel, rutas o acceso remoto:
   consola OOB, segundo camino de administración o reversión temporizada
   (`systemd-run --on-active` que restaura la config anterior salvo confirmación). Cambiar el túnel
   por el propio túnel sin red de seguridad es el autobloqueo más previsible del oficio.
4. **Prueba negativa obligatoria**: (a) un peer retirado **pierde** el acceso de inmediato;
   (b) un origen fuera de su `AllowedIPs` se descarta; (c) el tráfico entre dos clientes VPN está
   denegado si así lo dice la política; (d) el concentrador no expone nada más que su puerto de
   túnel. Un túnel probado sólo por el camino feliz no está probado.
5. **Prueba de MTU extremo a extremo con paquete grande y bit DF**, no sólo `ping` por defecto, y
   con la aplicación real (transferencia grande, no un `curl` a una página de una línea). Este es el
   gate que evita el 90% de los tickets de "la VPN va rara".
6. **Prueba de fuga de DNS y de rutas** tras cada cambio de cliente o de perfil: la resolución sale
   por donde debe, el tráfico que debe ir al túnel va al túnel, y el que no, no. Con split tunneling
   activo esta prueba es obligatoria en **cada** cambio de perfil.
7. **Ensayo de desprovisión trimestral**: cuenta de ensayo dada de baja en el IdP ⇒ se comprueba que
   pierde el acceso **y que su sesión activa se corta**. Documentar el tiempo real hasta el corte.
8. **Ensayo de failover del concentrador** en ventana: los túneles sitio-a-sitio se restablecen, los
   clientes reconectan, y se mide cuánto tarda. Un secundario nunca ejercitado no es redundancia.
9. **Prueba de carga antes de la temporada alta o del evento de continuidad**: usuarios concurrentes
   objetivo con tráfico realista, midiendo CPU de cifrado, sesiones y ancho de banda.
10. **Revisión periódica del inventario de túneles y peers** (trimestral): cada túnel y cada peer con
    dueño, motivo, alcance y última actividad; los inactivos se retiran. Un peer de un proveedor que
    terminó el contrato hace un año es un acceso permanente que nadie recuerda.

## 5. Seguridad

### 5.1 El concentrador VPN es un objetivo de primer orden — con datos, no con retórica

**Evidencia (catálogo KEV de CISA, versión 2026.07.29, 1.656 entradas; consultado directamente del
JSON de CISA, no de una nota de prensa).** Vulnerabilidades **activamente explotadas** en
dispositivos de acceso remoto y perímetro añadidas desde ene-2025:

| Añadido | CVE | Producto |
|---|---|---|
| 2025-01-08 | CVE-2025-0282 | Ivanti Connect Secure / Policy Secure / ZTA Gateways — desbordamiento de pila |
| 2025-01-24 | CVE-2025-23006 | SonicWall SMA1000 — deserialización |
| 2025-02-18 | CVE-2024-53704 | SonicWall SonicOS **SSLVPN** — autenticación incorrecta |
| 2025-04-04 | CVE-2025-22457 | Ivanti Connect Secure / Policy Secure / ZTA Gateways — desbordamiento de pila |
| 2025-04-16 | CVE-2021-20035 | SonicWall SMA100 — inyección de comandos (CVE **de 2021**, explotado en 2025) |
| 2025-05-01 | CVE-2023-44221 | SonicWall SMA100 — inyección de comandos |
| 2025-06-30 | CVE-2025-6543 | Citrix NetScaler ADC/Gateway — desbordamiento de búfer |
| 2025-07-10 | CVE-2025-5777 | Citrix NetScaler ADC/Gateway — lectura fuera de límites |
| 2025-08-26 | CVE-2025-7775 | Citrix NetScaler — desbordamiento de memoria |
| 2025-09-25 | CVE-2025-20333 y CVE-2025-20362 | Cisco Secure Firewall ASA / FTD |
| 2025-12-17 | CVE-2025-40602 | SonicWall SMA1000 — autorización ausente |
| 2026-02-25 | CVE-2026-20127 | Cisco Catalyst SD-WAN Controller/Manager — bypass de autenticación |
| 2026-03-30 | CVE-2026-3055 | Citrix NetScaler — lectura fuera de límites |
| 2026-05-29 | CVE-2026-0257 | Palo Alto Networks PAN-OS — bypass de autenticación |
| 2026-06-08 | CVE-2026-50751 | Check Point Security Gateway — autenticación incorrecta |
| 2026-07-14 | CVE-2026-15409 y CVE-2026-15410 | SonicWall SMA1000 — SSRF y **inyección de código** (encadenables) |
| 2026-07-22 | CVE-2026-16232 | Check Point SmartConsole — autenticación incorrecta |
| 2026-07-27 | CVE-2025-68686 | Fortinet FortiOS — exposición de información |
| 2026-07-27 | CVE-2026-16812 | Arista VeloCloud Orchestrator |

**Lectura obligatoria de esa tabla** (clase de riesgo, nunca procedimiento de explotación):
- **La familia dominante es el bypass de autenticación pre-auth**, no la ejecución tras
  autenticarse. El control "sólo usuarios válidos" no protege a un dispositivo cuyo fallo está
  *antes* de esa comprobación.
- **La explotación llega en días, a veces horas**, y los grupos que la usan buscan persistencia en el
  propio appliance —donde tu EDR no llega y tu inventario de software no mira.
- **El CVE viejo mata**: CVE-2021-20035 se explotaba activamente en 2025. Un appliance sin ventana de
  parcheo acumula deuda explotable durante años.
- **Ningún fabricante está limpio.** La elección de marca no es un control de seguridad; el proceso
  de parcheo sí.

**Consecuencias de diseño — esto es lo que hay que hacer con ese dato**:
- **Exposición mínima**: sólo el puerto del túnel a Internet. El **plano de gestión del concentrador
  nunca** se publica (ni HTTPS de administración, ni SSH, ni API) — llega por OOB o por bastión
  (`networking-standards`). Buena parte de los CVE de la tabla afectan a interfaces de gestión o de
  portal expuestas.
- **Ventana de parcheo de emergencia comprometida por escrito** antes de comprar: horas, no
  semanas, para un KEV en el dispositivo de borde. La cadencia formal y el SLA por riesgo, en
  `vulnerability-management-standards`.
- **Superficie mínima por diseño**: un demonio WireGuard en un host Linux minimalista, endurecido y
  parcheable en minutos tiene órdenes de magnitud menos superficie que un appliance con portal web,
  SSO integrado, antivirus y consola de gestión. Cuando puedas elegir, elige lo pequeño.
- **Asume el compromiso del concentrador en el modelo de amenaza**: segmenta lo que hay detrás,
  filtra la salida del túnel, no guardes credenciales de dominio en el appliance y ten decidido de
  antemano cómo lo aíslas y lo reconstruyes desde imagen limpia
  (`incident-response-forensics-standards`). Un appliance comprometido **no se limpia, se
  reconstruye**.
- **Vigila el fabricante activamente**: suscripción a sus avisos, y revisión del KEV como disparador
  operativo. Que un producto tuyo entre en KEV es un incidente, no una tarea de mantenimiento.

### 5.2 Higiene criptográfica y de claves

- **Sin negociación es mejor que con negociación**: donde puedas elegir, prefiere protocolo de
  suite fija (WireGuard). Donde negocies (IPsec/TLS), la propuesta es **explícita y corta**; listas
  largas "por compatibilidad" son un downgrade esperando ocurrir.
- **Ninguna clave privada sale del dispositivo que la usa.** Generación local, permisos `0600`,
  fuera del repo y fuera de las copias de seguridad en claro (`secrets-management-standards`).
- **Revocación probada**: CRL/OCSP funcionando y verificado con un certificado revocado de verdad;
  eliminación de peer verificada. Una revocación no probada no existe.
- **PSK y tokens de enrolamiento**: caducidad corta, un solo uso donde se pueda, y rotación. Un
  token de enrolamiento de malla es una llave para entrar en tu red.
- Algoritmos, longitudes, PKI y plan post-cuántico: `cryptography-pki-standards`.

### 5.3 El túnel no autoriza: filtrado y segmentación de lo que sale de él

- **`forward` con `policy drop` y matriz de flujos** para el tráfico que entra desde el túnel, igual
  que para cualquier otra zona (`firewall-policy-standards`). La zona VPN es una zona más y suele
  ser la **menos** confiable: dispositivos que no controlas del todo, en redes que no controlas nada.
- **Aislamiento entre clientes VPN** salvo requisito explícito: por defecto, un cliente no habla con
  otro cliente.
- **Egress del túnel filtrado**: un cliente comprometido con full-tunnel usa tu salida a Internet
  con tu reputación.
- **Acceso por aplicación, no por red**, siempre que el protocolo lo permita. El concentrador es el
  transporte; la autorización la pone la identidad.

### 5.4 Registro de sesiones y forense

- **Se registra, como mínimo**: identidad autenticada, dispositivo, IP pública de origen y su
  geolocalización, IP asignada en el túnel, marca temporal de inicio y fin, motivo de la
  desconexión, bytes, y **el resultado de la evaluación de postura**. Sin la asociación
  *IP-del-túnel ↔ usuario ↔ ventana temporal*, ninguna investigación posterior puede atribuir nada.
- **Retención** al menos igual a la ventana de investigación de la organización, con integridad
  protegida y **fuera del propio concentrador** (si el appliance cae, sus logs caen con él — y si lo
  comprometen, los borran). Envío al SIEM en tiempo casi real.
- **Señales que la ingeniería de detección explota** (las reglas son de
  `detection-engineering-standards`): viaje imposible, sesiones concurrentes desde geografías
  distintas, autenticación desde ASN de hosting/VPN comercial, ráfagas de fallos seguidas de éxito,
  primer acceso de un usuario a una hora insólita, y volumen de salida anómalo por sesión.
- **Preparación forense del appliance**: ten documentado de antemano cómo se obtiene una imagen o un
  volcado de estado del concentrador y qué logs sobreviven a un reinicio —muchos appliances lo
  ponen difícil, y eso se descubre en mitad del incidente si no se ha probado antes.

## 6. Rendimiento y operabilidad

- **Métricas de primera clase** (recogida, umbrales y alertas, en `observability-standards`):
  - **`latest handshake` por peer** en WireGuard — es la única señal fiable de "el túnel está vivo";
    la interfaz existe siempre, esté el peer arriba o abajo. Alerta por handshake más viejo de lo
    esperado, no por estado de interfaz.
  - Estado de CHILD_SA e IKE_SA en IPsec; sesiones activas y rechazadas en OpenVPN.
  - Sesiones concurrentes frente a la capacidad licenciada/dimensionada, **con umbral de aviso muy
    por debajo del límite**: el día que se llena es siempre el peor día.
  - CPU de cifrado y throughput por túnel (el cifrado satura CPU antes que el enlace en hardware
    modesto; comprueba si hay aceleración disponible).
  - Retransmisiones, pérdida y RTT **dentro** del túnel frente a fuera —un túnel que añade pérdida
    es un túnel mal dimensionado o con MTU mal puesta.
  - Caducidad de certificados de gateway y de cliente, y vencimiento de licencias.
- **Prueba sintética extremo a extremo**: un sondeo que atraviese el túnel y toque **una aplicación
  real** al otro lado, no un `ping` al gateway. La mitad de las averías de VPN son "el túnel está
  arriba y el servicio no responde".
- **Capacidad**: dimensiona por percentil de concurrencia real con margen para el escenario de
  continuidad (todo el mundo en remoto a la vez). Si el concentrador es también el firewall, el
  cifrado compite con el filtrado por CPU.
- **Coste y latencia del full-tunnel**: todo el tráfico del usuario pasa por tu enlace. Es una
  decisión de capacidad y de factura, no sólo de seguridad.
- **Runbooks con dueño**: caída del concentrador primario, túnel sitio-a-sitio que no levanta tras
  cambio del tercero, certificado de gateway caducado, cliente que conecta pero no navega (→
  MTU, `network-troubleshooting-standards`), sospecha de compromiso del concentrador (aislamiento +
  rotación masiva), pico de concurrencia por evento de continuidad, y **desbloqueo del administrador
  que se autoexcluyó** cambiando reglas por el propio túnel.
- **Recuperación**: la config del túnel se restaura desde el repo y las claves desde su custodia, en
  un equipo limpio, en minutos — y eso se prueba (`bcdr-standards`). El backup del appliance es
  evidencia, no fuente.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisión de CVE del concentrador y del cliente **mensual** y ante entrada en KEV
  (disparo inmediato); revisión de versión de WireGuard/strongSwan/OpenVPN y del agente de malla
  trimestral; revisión del inventario de túneles y peers trimestral (§4.10); revisión de la decisión
  full-tunnel vs. split y de la lista de "lo que aún no se puede publicar por aplicación" anual.
- **Cliente al día**: el agente de malla o el cliente VPN es **software privilegiado en todos los
  endpoints**. Su parcheo tiene la misma prioridad que el del navegador, no la de una utilidad.
- **Retirada real**: dar de baja un túnel incluye borrar el peer, revocar el certificado, retirar la
  ruta, borrar la regla de firewall, quitar la entrada del IPAM y archivar el registro. Un túnel
  "apagado pero configurado" vuelve a levantarse solo el día menos oportuno.
- **Sin proyectos abandonados**: cualquier componente sin release de seguridad en 12 meses o con la
  rama EOL se descarta antes de la discusión técnica.

**PROHIBIDO**
- ❌ Tratar "estar dentro de la VPN" como autorización, o dar acceso a la red entera cuando bastaba
  una aplicación.
- ❌ `AllowedIPs` más amplio de lo que el peer legítimamente enruta; `0.0.0.0/0` en el peer cliente
  del lado servidor.
- ❌ `wg0` (o cualquier interfaz de túnel) en `forward` sin reglas de filtrado.
- ❌ PPTP, L2TP sin IPsec, IKEv1, modo agresivo, XAUTH, PSK de grupo compartida.
- ❌ Acceso remoto de usuario sin MFA, o con MFA por SMS / push sin *number matching*.
- ❌ Claves o certificados de cliente **permanentes** sin caducidad ni revocación probada.
- ❌ Clave privada generada en un sitio y distribuida a los dispositivos; clave en el repo, en el
  ticket o en el chat.
- ❌ Reutilizar la misma clave o el mismo certificado en varios dispositivos.
- ❌ Publicar a Internet el plano de gestión del concentrador (portal admin, SSH, API).
- ❌ Appliance de acceso remoto sin ventana de parcheo de emergencia comprometida por escrito.
- ❌ Considerar un concentrador comprometido "limpiable": se reconstruye desde imagen limpia.
- ❌ Split tunneling adoptado por defecto, sin análisis de riesgo escrito, o dejando el DNS fuera del
  túnel.
- ❌ Túnel sin ajustar MTU **y** MSS, y luego culpar a la aplicación.
- ❌ Bloquear ICMP tipo 3 código 4 o ICMPv6 *packet-too-big* (mata PMTUD y el diagnóstico).
- ❌ Unir dos redes con direccionamiento solapado a base de NAT sin documentarlo en el IPAM y sin
  plan de renumeración.
- ❌ Cambiar rutas, reglas o config del túnel en remoto **por el propio túnel** sin ventana de
  rescate.
- ❌ Concentrador único sin redundancia, o failover nunca ejercitado.
- ❌ Dimensionar la concurrencia por plantilla en lugar de por el peor día.
- ❌ Baja de un usuario que no corta sus **sesiones activas**.
- ❌ Peers, túneles o cuentas de proveedor sin dueño, sin caducidad y sin revisión.
- ❌ Adoptar una malla gestionada sin responder por escrito qué pasa si su plano de control cae o se
  compromete, y sin plan de salida.
- ❌ Tratar el agente de malla como una app más y no como software privilegiado en todos los nodos.
- ❌ Vender un despliegue como "quantum-safe" (WireGuard **no** trae PQC de serie).
- ❌ Logs de sesión que viven **sólo** en el concentrador.
- ❌ `wireguard-go` en Linux con kernel moderno "porque ya funciona".
- ❌ Listas largas de propuestas criptográficas "por compatibilidad" en IPsec/TLS.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, fecha, CVE o condición de licencia, **búscalo — no lo recuerdes**.
**Metodología**: las versiones y fechas de este documento se obtuvieron de `api.github.com/repos/…`,
del git upstream (`git.zx2c4.com`) y del **JSON oficial del catálogo KEV de CISA**, no de páginas
HTML resumidas. Repite ese método: el resumen de una página de releases inventa años.

Verificado ago-2026:

- **WireGuard**: `wireguard-tools` **v1.0.20260223** (23-feb-2026), del repositorio oficial
  `git.zx2c4.com/wireguard-tools` — **GitHub es sólo un espejo y su página de releases está
  desactualizada** (última etiqueta allí, v1.0.20210914). Implementación en kernel Linux desde 5.6;
  `wireguard-go` es funcionalmente equivalente en protocolo pero con coste de copia por paquete y
  context switch: recomendación upstream explícita de usar el módulo del kernel en Linux.
  Proyecto en modo mantenimiento estable, autoría de Jason A. Donenfeld.
- **strongSwan**: **6.0.7** (08-jun-2026); 6.0.6 (22-abr-2026) corrigió **siete** CVE
  (CVE-2026-35328 a CVE-2026-35334, incl. bypass de *name constraints* en el plugin `constraints` y
  posible RCE en `libsimaka`); 6.0.5 (23-mar-2026) corrigió CVE-2026-25075 (eap-ttls, DoS
  pre-autenticación). PQC vía **RFC 9370** (`ke1_mlkem768`) desde 6.0.0, con PPK (RFC 8784).
- **OpenVPN**: **2.7.5** (02-jul-2026) y **2.6.21** (02-jul-2026); 2.7.0 salió en feb-2026.
  **DCO**: módulo `ovpn` **upstream en Linux 6.16** (sustituye a `ovpn-dco-v2`), `ovpn-backports`
  para kernels anteriores; en Windows `win-dco` por defecto y **`wintun` eliminado**. Otras
  novedades de 2.7: multi-socket, mbedTLS 4, `PUSH_UPDATE`.
- **Mallas** (releases vía `api.github.com`): NetBird **v0.76.1** (31-jul-2026), Netmaker **v1.6.0**
  (12-jun-2026), Headscale **v0.29.3** (29-jul-2026), Nebula **v1.11.0** (23-jul-2026),
  ZeroTierOne **1.16.2** (28-may-2026), Rosenpass **v0.2.3** (03-ago-2026, **pre-1.0**).
- **Boletines de seguridad de Tailscale en 2026** (verbatim de su página de boletines): TS-2026-004
  y TS-2026-005 (03/04-jun), TS-2026-006 (11-jun), TS-2026-007 (10-jul), TS-2026-008 y TS-2026-009
  (13-jul) — SSH, Serve/Funnel y filtrado de paquetes entrantes.
- **KEV de CISA**: catálogo **2026.07.29**, **1.656** entradas, **172 añadidas en 2026** (Cisco 13,
  Fortinet 6, Ivanti 5 entre los fabricantes de red más frecuentes). La tabla de §5.1 procede de ese
  JSON. **Re-descárgalo** (`https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json`)
  antes de usar cualquier dato de explotación: cambia cada semana.
- **Post-cuántico**: WireGuard **no** tiene PQC nativa; sólo el hueco de `PresharedKey`.
  Rosenpass sigue **pre-1.0** y usa Classic McEliece + Kyber-512 (pre-FIPS). IKEv2 con RFC 9370 y
  ML-KEM es la vía estandarizada.

**Huecos declarados — NO rellenar de memoria, verificar antes de usar**:
1. **Condiciones de licencia y precio vigentes** de Tailscale, ZeroTier, NetBird y Netmaker: sólo se
   obtuvieron señales de fuentes secundarias (movimiento de Tailscale a precio por asiento,
   endurecimiento del controlador autohospedado de ZeroTier, nivel autohospedado de NetBird). **No
   verificado contra las páginas oficiales de precios/licencia.** Confírmalo antes de comprometer
   plataforma.
2. **CVE con identificador formal en NetBird, Netmaker, Headscale, Nebula y ZeroTier**: no
   localizados en esta pasada. Sólo constan los boletines propios de Tailscale (TS-2026-00x) y,
   como antecedente histórico, el aviso de Pulse Security sobre ZeroTier (2021). Consulta la base
   de avisos de GitHub por repositorio antes de afirmar que un proyecto está limpio.
3. **CVE-2026-47895 en strongSwan** (doble liberación en clonado de identidades, posible RCE, desde
   4.3.3): citado por un aviso de distribución; **no verificado** contra el aviso oficial de
   strongSwan ni contra NVD. Comprobar si 6.0.7 lo incluye antes de fijar versión mínima.
4. **Versión empaquetada por distro** de `wireguard-tools`, strongSwan y OpenVPN en RHEL 10,
   Fedora, Debian 13 y Ubuntu LTS: **no verificada**. Lo que importa operativamente es la del
   paquete, no la upstream.
5. **Valores concretos de MTU/MSS por tipo de encapsulación**: se delegan en `networking-standards`
   y **no se han re-verificado** aquí. Recalcúlalos para tu encapsulación real (WireGuard sobre
   Ethernet, sobre PPPoE, sobre IPv6, IPsec con NAT-T) en vez de copiar un número.
6. **Estado de MOBIKE, fragmentación IKEv2 y DPD** en implementaciones concretas de terceros
   (Fortinet, Palo Alto, Cisco): descrito como criterio, **no verificado** contra la documentación
   vigente de cada fabricante.
7. **Números de RFC citados** (4555 MOBIKE, 7383 fragmentación IKEv2, 8784 PPK, 9370 múltiples
   intercambios de clave, 800-207 de NIST): **no contrastados contra rfc-editor** en esta pasada.
   Verifícalos antes de citarlos como autoridad.
8. **Capacidad y modelo de los relés/DERP** (si ven o no tráfico, límites de ancho de banda,
   ubicación): descrito por diseño esperado, **no verificado** contra la documentación de cada
   proveedor.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
