---
name: networking-standards
description: Network engineering standards. Use when working with IP addressing and VLANs, BGP/OSPF (FRR, BIRD), nftables/firewalld rules, DNS (BIND, Unbound, CoreDNS, Pi-hole), Kea DHCP, HAProxy/nginx/Traefik/Caddy proxies, WireGuard/Tailscale/NetBird overlays, MTU/MSS, tcpdump/Wireshark, NetBox, OPNsense/VyOS/RouterOS.
---

# Estándares de redes — diseño, operación y seguridad

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, configurar, revisar o diagnosticar: direccionamiento IP y subnetting,
IPAM, VLAN y segmentación, routing (estático, OSPF, BGP, filtrado de prefijos, RPKI, ECMP),
switching (STP, LACP, MLAG), política de firewall stateful, NAT, arquitectura DNS y DHCP,
balanceo L4/L7 y reverse proxies, VPN y overlays, ZTNA, IPv6 y dual stack, QoS, MTU/MSS,
hardening de equipos de red y plano de gestión OOB, 802.1X/NAC, diagnóstico por capas,
telemetría de flujos y automatización de red.

Triggers: `nft`/`nftables.conf`, `firewalld`, `frr.conf`, `bird.conf`, `named.conf`,
`unbound.conf`, `Corefile`, `kea-dhcp4.conf`, `haproxy.cfg`, `nginx.conf`, `Caddyfile`,
`wg0.conf`, `netplan`/`systemd-networkd`/NetworkManager, `tcpdump`, `mtr`, `ss`, NetBox,
containerlab (`*.clab.yml`), OPNsense/pfSense/VyOS/RouterOS/UniFi, "VLAN", "BGP", "MTU",
"DNS", "subnet", "peering", "MSS clamping".

**No aplica**: ver `onprem-standards` (firewall y VLAN a nivel de host/servidor,
monitorización básica de flota), `aws-standards`/`azure-standards`/`gcp-standards` (VPC,
Security Groups/NSG, balanceadores y DNS gestionados del proveedor),
`kubernetes-standards` (CNI, NetworkPolicy, Service/Ingress, service mesh),
`observability-standards` (métricas, logs, trazas y alertas de la red),
`sre-practice-standards` (SLO y error budget), `detection-engineering-standards` (telemetría de
seguridad, SIEM y reglas de detección — las firmas Suricata/Zeek se gobiernan allí, el sensor y su
colocación en la red, aquí), `incident-response-forensics-standards` (captura y preservación de
tráfico durante un compromiso), `linux-hardening-standards` (firewall **de host** y baseline del
SO frente al diseño de red que se fija aquí),
`firewall-policy-standards` (**qué flujo se permite entre zonas y con qué gobierno**: diseño del
ruleset nftables/firewalld, dueño, aprobación y caducidad de cada regla, filtrado de egress,
revisión de reglas sombreadas y huérfanas), `dns-standards` (**el servidor DNS, su zona y sus
datos**: SOA y TTL, DNSSEC, registros de correo, DoT/DoH, secuestro de dominio), y
`vpn-standards` y `network-troubleshooting-standards` (túneles y
diagnóstico). Esta skill conserva **topología, direccionamiento y VLAN, routing y BGP, MTU/MSS de
diseño, proxies y balanceo, overlays, plano de gestión OOB y elección de plataforma de perímetro**,
más el gobierno de la red como código.

**Delegación de profundidad** — esta skill es la **troncal**: fija el criterio
general y **entrega el detalle** a tres skills que sí lo cubren. Si la respuesta exige más que el
principio, es de ellas:
- `routing-switching-standards`: **campus y borde en profundidad** — STP y acceso enrutado, MLAG,
  redundancia de primer salto, y sobre todo **la política BGP completa** (atributos, comunidades,
  filtrado de salida, **RPKI/ROV e IRR**, BCP 38/84, BFD, CoPP, 802.1X, MACsec).
- `datacenter-fabric-standards`: **la malla del centro de datos** — Clos hoja-espina, VXLAN con
  EVPN, IRB simétrico, multihoming por ESI, MTU de encapsulación y Ethernet sin pérdidas.
- `network-automation-standards`: **la red como código** — fuente de verdad e IPAM operativo,
  NETCONF/RESTCONF/YANG y gNMI frente a la CLI, laboratorio virtual, validación previa y posterior,
  despliegue por lotes con reversión probada, y telemetría de flujo continuo frente a sondeo SNMP.
  **Lo que esta skill dice sobre "red como código" es el principio; el procedimiento es suyo.**
- `wireless-standards`: **la red inalámbrica corporativa como sistema de radio** — estudio de sitio,
  espectro y capacidad, plan de canal, itinerancia, WPA3 y 802.1X con validación de certificado en el
  cliente. **La prohibición de esta skill sobre la PSK compartida sigue valiendo; el diseño que la
  sustituye es suyo.**
- `high-speed-interconnect-standards`: **InfiniBand, RoCE v2 y el RDMA de cómputo y almacenamiento**,
  que es **una red distinta de la de datos** y no se diseña con el mismo criterio.
- `load-balancing-standards`: **el balanceador y el proxy inverso** — comprobaciones de salud,
  drenaje, terminación TLS y alta disponibilidad del propio balanceador. **Los productos que esta
  skill fija en §2 (HAProxy, nginx, Traefik, Caddy) se eligen y se operan allí.**

**Principio rector**: la red es **default-deny y documentada como código**. Todo flujo
permitido existe porque alguien lo justificó y quedó escrito; lo que no está en el SoT no
existe, y lo que no se puede diagnosticar por capas no está en producción.

## 2. Decisiones por defecto

> Versiones verificadas ago-2026. **Verificar la última estable por web antes de fijarla en
> un proyecto real** (§8): este stack rota cada trimestre.

| Ámbito | Por defecto | Prohibido / alternativa |
|---|---|---|
| Firewall en Linux | **nftables** (Fedora 44: nftables 1.1.4, firewalld 2.4.0 con backend nftables desde firewalld 0.6). Una sola tabla `inet` con IPv4+IPv6 | `iptables-legacy`; mezclar reglas nft y comandos `iptables` (la shim `iptables-nft` traduce en silencio). `iptables-nft`/`ipset` deprecados desde RHEL 9 y ya no son opción documentada en RHEL 10 |
| Router/firewall de perímetro | **OPNsense 26.7 "Xenial Xenops"** (base FreeBSD 15.1; ciclo semestral ene/jul) o **VyOS** para red-como-código | pfSense CE 2.8.1 (última CE, sep-2025; cadencia CE lenta) solo si ya está en casa. MikroTik **RouterOS 7.23** stable / **7.21.5** long-term |
| Imágenes VyOS | **Stream** (2026.03, trimestral, gratis) para lab/no crítico; **LTS** requiere suscripción de pago o de contribuidor | Rolling/nightly en producción |
| Routing dinámico | **FRR 10.7.0** (jul-2026) en hosts/routers Linux; **BIRD 3.3.1** (LTS 3.1.x) en route servers e IXP | Rutas estáticas en topologías con más de un camino; redistribución sin filtros |
| VPN sitio-a-sitio | **WireGuard** in-kernel; IPsec IKEv2 solo por interoperabilidad con terceros | PPTP, L2TP sin IPsec, SSLVPN propietaria sin parcheo |
| Overlay con control plane | **NetBird ≥ 0.65** (control plane 100% open source y self-hostable, binario unificado) o **Tailscale**; **Headscale 0.29.x** (beta) si se quiere el cliente Tailscale sin su coordinador | Malla WireGuard manual con más de ~10 nodos (no escala la distribución de claves) |
| DNS recursivo interno | **Unbound 1.24.2** o **Knot Resolver**, con validación DNSSEC activada | `systemd-resolved` y `dnsmasq` como validadores DNSSEC (fallos documentados en evaluación independiente de SIDN) |
| DNS autoritativo | **Knot DNS 3.5.4** o **BIND 9.20.x ESV** (9.20.26 con parches DNSSEC críticos) | BIND **9.18 (EOL jun-2026)**; ramas 9.21/9.23 de desarrollo en producción |
| Filtrado DNS lab/hogar | **Pi-hole v6** (FTL 6.7 / Core 6.4.3, jul-2026) o AdGuard Home | Pi-hole como único resolver sin redundancia |
| DHCP | **Kea** (sucesor oficial de ISC); reservas y opciones desde el SoT | ISC `dhcpd` en despliegues nuevos (sin mantenimiento activo — confirmar estado, §8) |
| Proxy inverso / LB L7 | **HAProxy 3.2.x LTS** (soporte a 2030-Q2) o 3.4.0 LTS; **nginx 1.30.x stable**; **Traefik v3.7.x** en entornos dinámicos; **Caddy 2.11.x** cuando el valor es ACME automático | nginx mainline en prod; Traefik v2 (solo parches); LB sin health checks activos |
| IPAM y fuente de verdad | **NetBox 4.6.7** como SoT de **intención** (no de descubrimiento) | Hojas de cálculo; auto-poblar NetBox desde escaneo de la red como si fuera intención |
| IPv6 | **Dual stack por defecto** en diseños nuevos (IPv6 hacia Google superó el 50% en mar-2026) | Desplegar IPv4-only "porque ya llegará"; NAT66 por costumbre |
| Diagnóstico | `tcpdump`/Wireshark, `mtr`, `ss`, `ip`, `nft list ruleset` | `netstat`, `ifconfig`, `route` (obsoletos, ocultan estado) |
| Telemetría de flujos | **IPFIX/NetFlow v9** (sFlow si el hardware solo lo soporta) a colector (Akvorado/pmacct/GoFlow2) | Red sin visibilidad de flujos: no se puede investigar ni dimensionar |

## 3. Estructura y convenciones

**Direccionamiento e IPAM**
- Plan jerárquico y **agregable** por sitio → zona → rol, con espacio de crecimiento
  reservado; sin solapamientos entre sedes, VPN y nubes (RFC 1918 se agota rápido en
  fusiones — asigna bloques grandes y documentados).
- Enlaces punto a punto: `/31` en IPv4 y `/127` en IPv6. Loopbacks `/32` y `/128` como
  identidad estable del equipo (router-id, terminación de sesiones BGP, gestión).
- IPv6: **GUA** para todo lo que rutea, ULA (`fc00::/7`) solo para lo que nunca sale;
  SLAAC para clientes, direccionamiento estático o DHCPv6 para servidores. Nada de
  direcciones de interfaz basadas en MAC en servidores (rompen firewall y DNS).
- **NetBox contiene la intención**; la red debe converger hacia él. Cerrar el bucle en
  ambos sentidos: tras cada cambio, el SoT queda actualizado o el cambio no está terminado.

**Segmentación**
- Zonas mínimas: gestión (OOB) / servidores / usuarios / IoT / DMZ / almacenamiento y
  replicación / invitados. **La zonificación industrial no es una de estas zonas y no se diseña
  con este criterio**: niveles Purdue, conductos con nivel de seguridad, DMZ de nivel 3.5 y el
  aislamiento del SIS son de `ot-ics-security-standards`, y allí *Safety* manda sobre
  disponibilidad. Meter la planta en una VLAN "IoT-OT" de esta lista es el error clásico. Una VLAN = un dominio de broadcast = una subred = una zona de
  política. **Default-deny entre zonas**, cada flujo permitido con dueño y motivo escrito.
- Microsegmentación este-oeste donde el dato lo justifique (NIST SP 800-207 y SP 800-215
  como marco): la ubicación en la red no otorga confianza.

**Routing**
- OSPF para el interior (áreas reales, no todo en area 0); BGP para multihoming, DC fabric
  (eBGP hoja-espina) y overlays. iBGP con route reflectors solo cuando la malla completa
  deje de ser razonable.
- **En todo eBGP**: prefix-list o route-map de entrada y salida (deny por defecto),
  `maximum-prefix` con acción, AS-path filtering, y RPKI **ROV** con validador propio
  (Routinator/rpki-client) — invalid = reject. Cobertura ROA global 67,4% (jun-2026), pero
  solo ~12,3% de los AS aplican ROV completo: firmar ROAs no protege a nadie si no se valida.
- Complementa con **RFC 9234 (Only-to-Customer)** contra route leaks. **ASPA sigue siendo
  draft IETF** (`draft-ietf-sidrops-aspa-verification`), no producto terminado: útil,
  no confiable como control único.
- ECMP con hashing por flujo (no por paquete: reordena y destroza TCP). uRPF y BCP 38
  antispoofing en el borde.

**Switching**
- Agregación **LACP** (activo, no `static`) contra stack/MLAG; nunca un solo uplink en
  algo que importe.
- STP: RSTP/MSTP con **root bridge fijado explícitamente** y prioridad del secundario;
  `bpduguard` + `rootguard` + `portfast/edge` en puertos de acceso. STP con root elegido
  por MAC es una topología que nadie controla.

**MTU, MSS y fragmentación** — causa habitual del "SSH va pero SCP se cuelga":
```
MSS = MTU − 40 (IPv4)      # 20 IP + 20 TCP;  −60 en IPv6
WireGuard sobre Ethernet 1500 → MTU 1420 → clamp MSS 1380
WireGuard sobre PPPoE  (1492) → MTU 1412 → clamp MSS 1372
```
- Ajusta la MTU del túnel **y además** haz MSS clamping; no son alternativas.
- `--clamp-mss-to-pmtu` cuando el path MTU es desconocido; valor explícito cuando se conoce.
- **No bloquees ICMP tipo 3 código 4** (fragmentation needed): sin él, PMTUD muere y los
  paquetes grandes desaparecen en silencio. Esto no es un agujero: es diagnóstico.
- Revisa el offload (GRO/GSO) en interfaces de túnel: agrega paquetes por encima de la MTU
  y los descarta con DF activo.

**Esqueleto nftables (host y router)**
```nft
table inet filter {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iif lo accept
    ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded } accept
    ip6 nexthdr icmpv6 accept                       # ICMPv6 es obligatorio, no opcional
    tcp dport 22 ip saddr @mgmt_nets accept
  }
  chain forward {
    type filter hook forward priority filter; policy drop;
    tcp flags syn tcp option maxseg size set rt mtu  # MSS clamping a PMTU
    ct state established,related accept
    # cada regla de permiso: origen, destino, puerto y comentario con el motivo
  }
  chain output { type filter hook output priority filter; policy drop; }  # egress filtrado
}
```

## 4. Gates de calidad obligatorios

- **Validación sintáctica antes de aplicar**, siempre: `nft -c -f ruleset.nft`,
  `named-checkconf`/`named-checkzone`, `unbound-checkconf`, `haproxy -c -f`, `nginx -t`,
  `vtysh -C`, `kea-dhcp4 -t`. Config que no valida no llega ni a staging.
- **Red de seguridad en todo cambio remoto de firewall/routing**: `commit-confirm` (VyOS),
  safe mode (RouterOS), rollback temporizado o consola OOB abierta. Sin ella, no se toca.
- **Laboratorio antes de producción** para topologías o protocolos nuevos: containerlab o
  VMs con las mismas versiones de imagen que producción.
- **Pruebas negativas obligatorias**: verifica que lo permitido funciona **y que lo
  prohibido está prohibido**. Un firewall solo probado por el camino feliz no está probado.
- **Test post-cambio por capas**: enlace y errores de interfaz → ARP/ND → ruta →
  conectividad → MTU con DF (`ping -M do -s`) → DNS → aplicación real (no solo ping).
- **Detección de drift como gate**: diff periódico entre la config running y el SoT
  (NetBox + plantillas). Una diferencia es un hallazgo con dueño, no una curiosidad.
- Cambios de red por PR revisada en el repo (plantillas, playbooks, reglas), nunca por CLI
  ad hoc en producción; backup de configuración de cada equipo, versionado y restaurable.

## 5. Seguridad

**Política de filtrado**
- **Default-deny en entrada y en salida**. El egress filtering es lo que frena C2 y
  exfiltración; un perímetro que solo mira hacia dentro está medio construido.
- Firewall stateful: cuidado con **rutas asimétricas**, que rompen el seguimiento de estado
  y producen fallos intermitentes imposibles de diagnosticar desde la aplicación.
- Rate limiting, protección anti-DDoS y WAF delante de lo expuesto; superficie mínima
  publicada, y lo publicado, inventariado.

**DNS como control de seguridad y como canal de fuga**
- Todos los clientes resuelven **solo** contra el resolver corporativo: bloquea `udp/tcp 53`
  hacia el exterior y `853` (DoT) en el borde.
- Neutraliza el DoH no controlado: política de navegador (`DnsOverHttpsMode` = off en
  Chrome, `network.trr.mode` = 5 en Firefox), bloqueo de IPs de resolvers DoH públicos en
  443, y DoH propio *pinneado* si quieres cifrado en tránsito. DoH de aplicación es el
  bypass real de todo filtrado DNS.
- **Registra el 100% de las consultas** del resolver y analiza longitud de etiqueta,
  entropía, número de subdominios, volumen y tasa de NXDOMAIN: la exfiltración por DNS vive
  ahí. Asume que la detección puramente de red no cierra el DoH-en-HTTPS: respáldala con EDR.
- DNSSEC: validación en el recursivo (siempre) y firma de las zonas propias.
  `HTTPS`/`SVCB` (RFC 9460) y ECH cambian lo que se ve en el cable: tenlo en el modelo.

**Plano de gestión y equipos**
- Gestión **out-of-band**, en VLAN dedicada sin ruta desde redes de usuario, accesible solo
  vía bastión/VPN. Es el objetivo número uno tras el primer compromiso.
- SSH con claves, **SNMPv3** únicamente, AAA centralizado (RADIUS/TACACS+) con cuentas
  nominales, `enable`/local solo de emergencia en gestor de secretos. Sin telnet, sin HTTP,
  sin SNMP v1/v2c, sin credenciales de fábrica, servicios innecesarios apagados.
- Hardening según CIS del fabricante; firmware con revisión trimestral y ante CVE explotable.

**Acceso y confianza**
- **ZTNA por aplicación** frente a VPN full-tunnel que da acceso a "la red"; identidad
  fuerte (OIDC/MFA) y postura de dispositivo antes que ubicación.
- 802.1X en acceso cableado y WiFi (WPA3-Enterprise), con VLAN dinámica y red de
  cuarentena; `port-security` donde 802.1X no llegue. MACsec en enlaces entre armarios o
  campus cuando el medio no sea de confianza.
- mTLS o IPsec para tráfico este-oeste sensible; TLS 1.2+ / 1.3 en todo lo publicado.

## 6. Rendimiento y operabilidad

- **Señales de red que se vigilan siempre**: latencia y jitter (RTT por salto), pérdida de
  paquetes, errores/descartes por interfaz, utilización y saturación de enlace, tamaño de
  la tabla de rutas y estado de sesiones BGP/OSPF, expiración de certificados y leases DHCP.
- **Flujos (IPFIX/NetFlow/sFlow)** para saber quién habla con quién: sin ellos no hay
  investigación de incidente ni dimensionamiento con datos. Complementa con gNMI/OpenConfig
  (streaming telemetry) donde el equipo lo soporte, en lugar de polling SNMP masivo.
- **Diagnóstico por capas, en orden y sin saltos**: física (luz, errores CRC, negociación)
  → enlace (VLAN, MAC/ARP/ND, STP) → red (ruta, MTU, ICMP) → transporte (`ss`, retransmisiones,
  handshake en captura) → aplicación (DNS, TLS, HTTP). Saltar capas es cómo se pierden horas.
- **QoS**: `fq_codel`/CAKE en el borde resuelve el bufferbloat, que es el 90% del "la red va
  lenta" real. DSCP solo sirve si se marca, se respeta y no se borra extremo a extremo;
  marcar sin acuerdo entre todos los saltos es decorativo. L4S es emergente: no lo asumas.
- **Capacidad con datos**: planifica sobre percentiles de utilización real, con umbral de
  acción en torno al 70% sostenido; no dimensiones por intuición ni por pico anecdótico.
- **HA sin SPOF**: doble uplink por caminos distintos, VRRP/CARP con failover **probado**,
  redundancia de resolvers DNS y DHCP, alimentación y switches diversificados. Un failover
  no ejercitado no cuenta.
- Runbooks por escenario: pérdida de uplink, caída de un firewall, fuga de rutas, agotamiento
  de pool DHCP, envenenamiento/caída de DNS, bucle de capa 2. Versionados y con dueño.

## 7. Sostenibilidad y prohibiciones

- **Red como código**: topología, direccionamiento, reglas y baselines en repo, revisadas
  por PR; automatización idempotente (Ansible network collections) alimentada por NetBox;
  containerlab para validar antes de tocar hierro.
- **Cadencia**: firmware/IOS/RouterOS y NOS revisados cada trimestre y ante CVE con
  KEV/EPSS relevante; ramas LTS de HAProxy/BIND/FRR frente a la última minor; ninguna
  versión EOL en producción sin plan de salida fechado (BIND 9.18 EOL jun-2026 es el
  recordatorio del trimestre).
- Deprecación con plan: cada regla, VPN o VLAN retirada se elimina de verdad (config, SoT y
  documentación), no se queda "por si acaso" acumulando superficie.

**PROHIBIDO**
- ❌ `any/any` permanente, reglas sin comentario de motivo, o `0.0.0.0/0` en entrada sin
  justificación escrita.
- ❌ Firewall sin egress filtering; "es red interna, no hace falta filtrar".
- ❌ Mezclar `iptables` y `nftables` en el mismo host; `iptables-legacy` en sistemas nuevos.
- ❌ Bloquear ICMP indiscriminadamente (mata PMTUD y el diagnóstico) o ICMPv6 en IPv6 (rompe ND).
- ❌ Cambiar firewall/routing en remoto sin commit-confirm, rollback temporizado ni consola OOB.
- ❌ eBGP sin filtros de prefijo, sin `maximum-prefix` y sin RPKI ROV.
- ❌ Interfaces de gestión (switches, firewalls, BMC, hipervisores) accesibles desde redes de
  usuario o desde Internet.
- ❌ Telnet, HTTP de gestión, SNMP v1/v2c, credenciales por defecto, cuentas compartidas.
- ❌ Permitir DNS saliente a cualquier resolver, o dejar el DoH del navegador sin política.
- ❌ Resolver, DHCP o firewall único sin redundancia en algo que importe.
- ❌ VLAN plana "porque es más fácil"; IoT/OT en la misma zona que servidores o usuarios.
- ❌ Túneles sin ajustar MTU ni MSS y luego culpar a la aplicación.
- ❌ Configuración manual no reflejada en el SoT/repo (snowflakes) y drift sin corregir.
- ❌ VPN full-tunnel que concede acceso a toda la red en lugar de acceso por aplicación.
- ❌ Wi-Fi corporativo con PSK compartida en vez de WPA3/802.1X.
- ❌ Poblar NetBox por descubrimiento automático y llamarlo "intención".

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, flag o dato concreto, **búscalo — no lo recuerdes**.
Verificado ago-2026 (caduca rápido): nftables 1.1.4 / firewalld 2.4.0 en Fedora 44;
OPNsense 26.7 (FreeBSD 15.1); pfSense CE 2.8.1; RouterOS 7.23 stable / 7.21.5 long-term;
VyOS Stream 2026.03; FRR 10.7.0; BIRD 3.3.1 (LTS 3.1.x); BIND 9.20.26 ESV (9.18 EOL
jun-2026); Unbound 1.24.2; Knot DNS 3.5.4; Pi-hole FTL 6.7 / Core 6.4.3; HAProxy 3.2.x y
3.4.0 LTS; nginx 1.30.x stable / 1.31.x mainline; Traefik v3.7.10; Caddy 2.11.4;
NetBox 4.6.7; NetBird 0.65+; Headscale 0.29.x (beta).

1. Última estable y **EOL** de cada componente que vayas a instalar (endoflife.date + notas
   de la versión del fabricante), muy en especial BIND, nginx, HAProxy y el NOS del equipo.
2. **CVEs activos con KEV/EPSS** antes de decidir la urgencia de un parche — 2026 ha sido un
   año denso en nginx y BIND.
3. Estado de `iptables`/`nftables` en la distro **exacta** del proyecto (RHEL 10, Fedora,
   Debian) antes de escribir reglas: la capa de compatibilidad cambia entre versiones.
4. Estado de **Kea** e ISC `dhcpd`, y de containerlab, FreeRADIUS, Wireshark, Akvorado y
   UniFi Network Application — no verificados en este documento.
5. Estado de **RPKI/ASPA** (ASPA sigue en draft), adopción de ROV y cifras de IPv6
   (Google/APNIC): son datos que cambian cada trimestre.
6. Política de imágenes de VyOS (LTS solo con suscripción o contribución) y ciclo de
   release de OPNsense/pfSense CE antes de comprometer una plataforma.
7. RFC exacto antes de citarlo (SVCB/HTTPS, DoQ, OTC, L4S, IPv6-mostly): número y estado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
