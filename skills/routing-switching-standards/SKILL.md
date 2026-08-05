---
name: routing-switching-standards
description: Campus and edge switching/routing design decisions that outlive the hardware. Use when choosing between RSTP/MSTP and a routed access layer, sizing a broadcast domain, configuring BPDU guard, root guard, storm control, portfast/edge, LACP bundles, MLAG/vPC/MC-LAG or a switch stack, first-hop redundancy with VRRPv3 (RFC 9568), HSRP or GLBP and its interaction with MLAG, picking OSPF versus IS-IS versus BGP as the campus IGP, writing eBGP import/export policy, route-maps, prefix-lists, as-path filters, maximum-prefix, BGP communities and large communities (RFC 8092), aggregation and no-export, RFC 8212 default-deny eBGP, RPKI route origin validation with Routinator/rpki-client/StayRTR and invalid=reject, ROAs (RFC 9582), RPKI-RTR (RFC 8210), IRR objects and as-set expansion, MANRS conformance, prefix hijacks and route leaks (RFC 9234 OTC), BCP 38/84 and uRPF (RFC 8704), BFD (RFC 5880/5881/5883), GTSM (RFC 5082), dual-stack IPv6 rollout planning, DSCP trust boundaries and queueing policy, CoPP/control-plane policing, 802.1X port-based access control, MACsec, SNMPv3 versus SNMP v1/v2c, TACACS+/RADIUS AAA on network devices, or an out-of-band management plane.
---

# Estándares de conmutación y enrutado — campus y borde

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **diseñar y operar la red conmutada y enrutada de campus, sede y borde**: dimensionado del
dominio de difusión, STP y su papel real hoy, protección de bucles, agregación y sistemas
multi-chasis, frontera capa 2/capa 3, redundancia de primer salto, elección de IGP, **política BGP en
profundidad**, higiene de enrutado global (RPKI, IRR, MANRS), despliegue IPv6, QoS con criterio, y
hardening del plano de gestión y de control.

Triggers: `spanning-tree`, `rstp`/`mstp`, `bpduguard`, `root guard`, `storm-control`,
`port-channel`/`lacp`, `mlag`/`vpc`/`stack`, `vrrp`/`hsrp`/`glbp`, `route-map`, `prefix-list`,
`as-path access-list`, `maximum-prefix`, `community`/`large-community`, `aggregate-address`,
`rpki`/`origin-validation`, `routinator`, `rpki-client`, `stayrtr`, `as-set`, `MANRS`, `bfd`,
`ttl-security`, `copp`, `dot1x`, `macsec`, `snmpv3`, `tacacs+`, "hijack", "route leak", "DSCP".

**No aplica** — cada skill **decide** una cosa distinta:
`networking-standards` (**troncal, madre**: decide **direccionamiento e IPAM, qué VLAN existe,
fundamentos de BGP/OSPF, proxies y balanceo, overlays de host, MTU/MSS y NetBox como SoT**; aquí no se
reabre nada de eso, aquí se decide **cómo converge la red conmutada y qué dice exactamente la política
BGP**); `network-troubleshooting-standards` (**decide el método reactivo** cuando algo ya está roto —
aquí el diseño y la operación proactiva, y todo hallazgo estructural suyo vuelve aquí);
`datacenter-fabric-standards` (**decide la malla de DC**: Clos, VXLAN/EVPN, red sin pérdidas);
`network-automation-standards` (**decide cómo se genera, se prueba y se aplica** un cambio — aquí, **qué
debe decir** la configuración); `firewall-policy-standards` (**decide qué flujo se permite entre zonas
y con qué gobierno**); `iac-standards` (**decide Terraform y Ansible como herramientas**);
`observability-standards` (**decide qué se mide y con qué umbral se avisa**);
`identity-access-management-standards` (**decide la identidad corporativa**; aquí sólo su consumo en AAA
de dispositivo); `finops-standards` (tránsito y puertos). También frontera: `dns-standards`,
`vpn-standards`, `onprem-standards` (paraguas), `kubernetes-standards`, `secrets-management-standards`,
`sre-practice-standards`, `linux-hardening-standards`, `vulnerability-management-standards`,
`offensive-security-standards` (**esta skill es defensiva**), y `network-vendors-standards`,
`wan-legacy-standards`, `telco-5g-standards`, `high-speed-interconnect-standards` y
`datacenter-facilities-standards`.

**Principio rector**: **una decisión de capa 2 se paga durante diez años.** Diseña para que **la
convergencia no dependa de STP** y para que **ningún prefijo salga sin autorización explícita**.

## 2. Decisiones por defecto

> Verificar por web estado y versión antes de fijar nada (§8). Los RFC de esta tabla están
> verificados uno a uno contra la API JSON de `rfc-editor.org`.

| Decisión | Por defecto | Alternativa justificable / vetado |
|---|---|---|
| Frontera L2/L3 | **Enrutado hasta el acceso**: el dominio de difusión muere en el armario y converge el IGP, no STP | Pasarela centralizada **sólo** con requisito real de movilidad L2; nunca "porque siempre se hizo así" |
| STP | **RSTP/MSTP activo como red de seguridad**, con root primario y secundario fijados | ❌ STP como **mecanismo de convergencia** de diseño; ❌ root elegido por MAC; ❌ desactivarlo "para ir más rápido" |
| Protección de bucles | `bpduguard` + `rootguard` + `portfast/edge` + `storm-control` en **todo** puerto de acceso | Sin BPDU guard, un switch doméstico bajo una mesa reconfigura tu topología |
| Agregación | **LACP activo** (IEEE 802.1AX-2020) | ❌ `static`/`on`: no detecta cableado cruzado ni miembro semi-muerto |
| Multi-chasis | **MLAG/vPC** con enlace de par y **doble** keepalive por camino distinto | Stack: **un plano de control ⇒ una actualización ⇒ un fallo**; aceptable en acceso, no en núcleo |
| Primer salto | **VRRPv3 — RFC 9568** (may-2024, **obsoleta RFC 5798**), IPv4+IPv6, prioridades y preempt explícitos | HSRP/GLBP sólo en parque mono-fabricante. Con MLAG, **pasarela activa-activa del propio MLAG**; VRRP encima duplica estado |
| IGP de campus | **OSPF** por ubicuidad y personal que lo opera | **IS-IS** (ISO 10589, RFC 1195; IPv6 en RFC 5308) por independencia de familia y escalado; **BGP** si la topología es malla enrutada. ❌ Todo en `area 0` |
| Detección de fallo | **BFD — RFC 5880**, single-hop **5881**, multihop **5883**, ligado a IGP y BGP | Depender de los hello del IGP: segundos frente a milisegundos |
| eBGP | **RFC 8212**: sin política no se anuncia ni se acepta nada. Filtro de entrada **y salida** en cada sesión | ❌ Sesión sin `prefix-list`/`route-map` en ambos sentidos, sin `maximum-prefix` con acción, sin filtro de `as-path` |
| Higiene global | **ROV con validador propio** (Routinator / rpki-client / StayRTR), **invalid = reject**; ROAs propios (perfil **RFC 9582**, obsoleta 6482); RPKI-RTR **RFC 8210** | ROV en "sólo marcar" indefinidamente. `maxLength` amplio: **RFC 9319 (BCP)** lo desaconseja |
| Antispoofing | **BCP 38 (RFC 2827)** y **BCP 84 (RFC 3704)**; uRPF estricto donde el camino es simétrico, **RFC 8704** donde no | ❌ Borde sin filtrado de origen |
| Antifugas | **RFC 9234** (roles BGP y atributo Only-to-Customer) | ASPA **sigue siendo Internet-Draft** (§8): útil, no control único |
| Protección de sesión | **GTSM (RFC 5082)** en eBGP directo, más autenticación de sesión BGP e IGP | Sesión expuesta a Internet sin GTSM ni autenticación |
| IPv6 | **Doble pila desde el día uno**, con **paridad** de filtrado, logging y monitorización | ❌ "Ya lo haremos": el retrofit cuesta más, y la falta de paridad es donde aparece el agujero |
| QoS | **Confianza sólo en el borde**: marcar/remarcar en entrada, confiar hacia el núcleo. DSCP **RFC 2474**, AF **2597**, EF **3246** | ❌ QoS como sustituto de capacidad; ❌ confiar el DSCP del usuario |
| Plano de gestión | **OOB físico**, AAA centralizado (**TACACS+** por autorización por comando; RADIUS donde no llegue), SSH con clave, **SNMPv3 authPriv** | ❌ Telnet, HTTP de gestión, SNMP v1/v2c, comunidad `public`, cuentas compartidas |

## 3. Convenciones de diseño

**Capa 2 y sus límites**
- **El dominio de difusión es el radio de explosión**: un bucle, una tormenta o una MAC duplicada
  afectan a todo lo que comparte VLAN. Dimensiona por impacto, no por comodidad.
- **STP es la red de seguridad, no el plan.** Debe estar activo y bien parametrizado, pero un diseño
  cuya convergencia depende de que STP recalcule acepta un fallo de decenas de segundos y una
  topología que nadie dibuja de memoria. La convergencia la dan enrutado al acceso, LACP y MLAG.
- **MSTP** cuando hay muchas VLAN y se reparte por instancias; entonces **región (nombre, revisión y
  mapeo VLAN→instancia) idéntica en todos los switches**: una discrepancia parte la región en
  silencio.
- **Modos de fallo de MLAG a decidir antes de comprarlo**: partición del enlace de par (*split
  brain*), pérdida de keepalive con par vivo, actualización de software del par, y sincronización de
  estado (MAC, ARP/ND, IGMP). Se verifican en laboratorio, no en el folleto.

**Elección de IGP — criterio real, no preferencia**
- **OSPF** con áreas de verdad (stub/totally stubby donde aplique) y sumarización en frontera, que es
  lo que acota el alcance de un *flap*.
- **IS-IS** si quieres un IGP indiferente a la familia de direcciones y con menos superficie (no
  corre sobre IP). Coste: menos gente sabe operarlo — criterio de diseño legítimo.
- **BGP** en campus con malla enrutada o multi-inquilino con VRF; su fuerza es la **política**, no la
  convergencia (que se compensa con BFD).
- **Un IGP para la topología, BGP para la política.** Redistribuir entre ellos sin filtros, tags ni
  control de métrica es la forma clásica de crear un bucle permanente.

**BGP: lo que hay que decidir explícitamente**
- **Orden de decisión** (verificar el exacto del fabricante): weight → `LOCAL_PREF` → originada
  localmente → `AS_PATH` → `ORIGIN` → `MED` → eBGP sobre iBGP → coste IGP al siguiente salto →
  desempate. **En la práctica se toca**: `LOCAL_PREF` para elegir salida, prepending de `AS_PATH`
  para influir la entrada (herramienta burda), `MED` sólo con un mismo vecino.
- **Comunidades como mecanismo de política, no como comentario**: el borde **marca** en la entrada
  (origen, tipo de vecino, geografía, intención de anuncio) y el resto de la política **lee** esas
  marcas. **Large communities (RFC 8092)** con ASN de 4 bytes; las estándar (RFC 1997) se quedan
  cortas. Documenta el diccionario de comunidades como contrato si haces peering.
- **Agregación**: anuncia el agregado y filtra las específicas salvo razón escrita; desagregar por
  costumbre engorda la tabla global de todos. Cuidado con el agujero negro del agregado sin descarte.
- **Filtrado hacia el exterior — la lección de los secuestros**: los incidentes de redirección de
  tráfico y sustracción de criptoactivos vía BGP no fueron ataques sofisticados, sino **un prefijo
  anunciado por quien no debía y un vecino que no filtró**. La defensa que funciona es aburrida:
  filtro de salida explícito, filtro de entrada por prefijos esperados, `maximum-prefix` con acción y
  ROV con invalid=reject. **Firmar ROAs protege a los demás; validar es lo que te protege a ti.**
- **IRR**: sigue siendo la base de la generación automática de filtros en peering, pero **su calidad
  es desigual** (objetos obsoletos, `as-set` sin autoridad que expanden a miles de prefijos, sin
  validación de titularidad). Úsalo **junto con** RPKI, prefiriendo registros del RIR y con límite
  explícito de expansión.
- **MANRS**: vivo; secretaría y operación pasaron de Internet Society a **Global Cyber Alliance**
  (2024), con ISOC manteniendo financiación y formación. Úsalo como **lista de comprobación
  auditable** (filtrado, antispoofing, coordinación, datos globales validados), no como sello.

**IPv6 y QoS**
- El plan IPv6 se hace **una vez**; rehacerlo con firewall, DNS y monitorización ya escritos cuesta un
  múltiplo (el plan concreto es de `networking-standards`). **El riesgo real no es no tener IPv6: es
  tenerlo a medias** — activo por defecto en los sistemas y sin política equivalente a IPv4.
- **QoS reparte escasez; no crea capacidad.** Si el enlace está saturado de forma sostenida, sólo
  decide a quién le va mal. Dimensiona primero, prioriza después. Sirve para tráfico sensible a
  latencia y jitter y para proteger el plano de control; marcar extremo a extremo sin acuerdo en
  todos los saltos —y el tránsito suele reescribir DSCP— es decorativo.

## 4. Gates de calidad

- **Un cambio de enrutado se prueba en laboratorio**: la política BGP y la redistribución tienen
  efectos que sólo aparecen con la topología completa, y su fallo es global y silencioso. Laboratorio
  virtual con las mismas versiones de NOS (herramientas en `network-automation-standards`).
- **Ventana con reversión temporizada y consola OOB abierta** en todo cambio remoto de enrutado o
  filtrado; criterio de aborto escrito **antes** de empezar.
- **Pruebas negativas**: tras tocar política BGP verifica **qué se anuncia** desde una vista externa
  (looking glass o colector), no sólo qué se recibe. Un filtro probado sólo por el camino feliz no
  está probado.
- **Convergencia medida**: derriba el enlace o nodo primario y mide el tiempo hasta la recuperación
  del **tráfico de aplicación**, no hasta que el protocolo diga "up". Un failover no ejercitado no
  cuenta, y la vuelta falla más que la ida.
- **Detección de drift** contra el SoT como gate periódico (mecánica en `network-automation-standards`).

## 5. Seguridad del plano de gestión y de control

- **Plano de gestión separado y fuera de banda**: VLAN/red dedicada, sin ruta desde redes de usuario,
  accesible sólo vía bastión. Es **el primer objetivo tras el compromiso inicial**, y es además lo que
  te salva cuando el cambio que rompió la red es tuyo.
- **AAA centralizado con cuentas nominales**: **TACACS+** en dispositivo de red cuando quieras
  autorización y contabilidad **por comando** (RADIUS no la da); RADIUS para 802.1X. Cuenta local de
  emergencia única, custodiada en el gestor de secretos (`secrets-management-standards`) y rotada tras
  cada uso.
- **Protocolos, sin matices**: **SSH** con claves y **SNMPv3 authPriv**. **PROHIBIDO telnet, HTTP de
  gestión y SNMP v1/v2c** (comunidad en claro = credencial en el cable; con escritura = control del
  equipo). Servicios innecesarios apagados; CDP/LLDP fuera de puertos no confiables.
- **802.1X (IEEE 802.1X-2020)** en acceso cableado y WPA3-Enterprise en inalámbrico, con VLAN dinámica,
  cuarentena y **política explícita de qué pasa si el suplicante falla**: fail-open convierte el
  control en teatro; fail-closed exige plan para impresoras y equipo sin suplicante (MAB, que es débil
  y debe ser excepción registrada). `port-security` donde 802.1X no llegue; **MACsec** en enlaces entre
  armarios o edificios cuando el medio no sea de confianza.
- **CoPP no es un extra**: política de tasa por clase hacia la CPU (enrutado, gestión, ARP/ND, ICMP,
  resto). Sin ella, cualquiera con acceso al segmento tumba el plano de control con tráfico trivial y
  el equipo deja de converger justo cuando más falta hace. Verifica los límites en laboratorio: una
  CoPP demasiado agresiva rompe el propio enrutado.
- **Ciclo de vida**: baseline CIS del fabricante, firmware revisado por trimestre y ante CVE explotable
  (`vulnerability-management-standards`), inventario con fecha de fin de soporte. Un switch fuera de
  soporte tiene plan de sustitución o es un agujero, pero no es una decisión aplazable.

## 6. Operación y capacidad

- **Señales que se vigilan siempre** (plataforma en `observability-standards`): errores y descartes por
  interfaz, utilización por percentiles, **cambios de topología STP (TCN)**, estabilidad de adyacencias
  IGP y sesiones BGP, prefijos recibidos por vecino frente a `maximum-prefix`, resultado de ROV, óptica
  y **CPU del plano de control**. Un contador de TCN que sube es un hallazgo, no ruido: detrás suele
  haber un puerto sin `portfast/edge` o un enlace intermitente.
- **Capacidad con datos**: percentiles de utilización sostenida, umbral de acción en torno al 70%, y
  horizonte mayor que el plazo de compra e instalación. Coste de puertos y tránsito en `finops-standards`.
- **Configuración como código**: vive en el repositorio y se aplica desde ahí; respaldos por equipo
  versionados y restaurables (mecánica en `network-automation-standards`).
- **Runbooks con dueño**: pérdida de uplink, bucle de capa 2, fuga de rutas propia o de un vecino,
  caída de MLAG, saturación del plano de control, expiración de certificado de gestión.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: NOS y firmware revisados trimestralmente; nada sin soporte del fabricante sin fecha de
  salida escrita; ramas estables/LTS frente a la última funcionalidad.
- **Deprecación real**: VLAN, sesión BGP o regla retirada se elimina de configuración, SoT y
  documentación. "Por si acaso" es deuda con interés compuesto.

**PROHIBIDO**
- ❌ Depender de STP para converger; o desactivarlo "porque hay MLAG".
- ❌ Puerto de acceso sin `bpduguard`, `portfast/edge` y `storm-control`.
- ❌ Extender una VLAN entre edificios o sedes por comodidad (para DCI, ver `datacenter-fabric-standards`).
- ❌ Agregación **estática** (`on`) en lugar de LACP.
- ❌ Desplegar MLAG sin probar en laboratorio *split brain*, pérdida de keepalive y actualización del par.
- ❌ Stack de chasis como única redundancia en núcleo o distribución.
- ❌ Superponer VRRP a una pasarela activa-activa de MLAG sin entender qué gana cada estado.
- ❌ Un IGP entero en `area 0`, o redistribuir sin filtro, sin tag y sin control de métrica.
- ❌ Sesión eBGP sin filtro de entrada **y de salida**, sin `maximum-prefix` con acción, o confiando en
  el default del fabricante en lugar de en RFC 8212.
- ❌ Anunciar a Internet lo aprendido de Internet (fuga de tránsito) por no tener filtro de salida.
- ❌ RPKI en "sólo marcar" de forma indefinida, o publicar ROAs y no validar.
- ❌ Generar filtros desde un `as-set` de IRR sin límite de expansión ni revisión.
- ❌ Borde sin BCP 38/84 ni uRPF.
- ❌ IPv6 sin paridad de filtrado, logging y monitorización con IPv4.
- ❌ Confiar el DSCP del usuario, o usar QoS para tapar un enlace mal dimensionado.
- ❌ Equipo de red sin CoPP.
- ❌ Telnet, HTTP de gestión, SNMP v1/v2c, comunidades por defecto, credenciales de fábrica, cuentas
  compartidas.
- ❌ Interfaz de gestión alcanzable desde red de usuario o desde Internet.
- ❌ 802.1X en fail-open permanente, o MAB generalizado sin registro de excepciones.
- ❌ Cambio de enrutado sin laboratorio previo, sin reversión temporizada y sin consola OOB.
- ❌ Declarar que un failover "funciona" sin haberlo ejercitado y **medido** con tráfico real.

## 8. Verificación web obligatoria

**Metodología**: los RFC de este documento se verificaron **uno a uno** contra la API JSON de
`rfc-editor.org` (título, estado, fecha, `obsoletes`/`obsoleted_by`), no contra resúmenes HTML.

**RFC verificados ago-2026, con las correcciones que introdujeron**. **VRRPv3 = RFC 9568** (may-2024),
que **obsoleta RFC 5798** — citar 5798 hoy es un error de hecho. **Perfil de ROA = RFC 9582**
(may-2024), que **obsoleta RFC 6482**. **RPKI-RTR v1 = RFC 8210** (sep-2017; RFC 6810 es la v0,
*updated by* 8210). **Validación de origen = RFC 6811**, actualizado por **8481** y **8893**;
**`maxLength` = RFC 9319** (BCP). **Roles BGP / OTC = RFC 9234** (may-2022). **BGP-4 = RFC 4271**
(*Draft Standard*), actualizado por doce RFC entre ellos **8212** (eBGP sin política no propaga) y
**7606**. **Comunidades = RFC 1997**; **large communities = RFC 8092**. **BFD = RFC 5880 / 5881 /
5883**. **GTSM = RFC 5082**. **BGP Ops & Security = RFC 7454** (BCP). **Antispoofing = RFC 2827
(BCP 38)** y **RFC 3704 (BCP 84)**, actualizado por **RFC 8704** (BCP). **IS-IS**: ISO/IEC 10589 con
**RFC 1195**, IPv6 en **RFC 5308**. **QoS**: **2474 / 2597 / 3246**.
**ASPA NO es RFC**: `draft-ietf-sidrops-aspa-profile` rev **-29** y `…-verification` rev **-27**, ambos
con actividad el **3-ago-2026**. **IEEE**: **802.1AX-2020** (agregación; amendment 802.1AXdz-2025,
YANG) y **802.1X-2020**; **RSTP (ex-802.1w) y MSTP (ex-802.1s) ya no son estándares independientes**,
están consolidados en 802.1Q (edición 2022 más amendments).

**Discrepancia declarada — enforcement de RPKI ROV**: las fuentes no coinciden porque **miden cosas
distintas**. `networking-standards` recoge ~12,3% de **AS** aplicando ROV completo (jun-2026); un
artículo de arXiv de mar-2026 da "menos del 30% de **direcciones de usuario** en redes que filtran
inválidos". Ambas pueden ser ciertas a la vez. Además, el **NIST RPKI Monitor**
(`rpki-monitor.antd.nist.gov`) **advierte explícitamente que no mide qué redes filtran de verdad**.
No cites una cifra única de "despliegue de ROV" sin decir qué mide.

**Huecos declarados — NO rellenar de memoria**:
1. **Cifras vigentes de cobertura de ROA y aplicación de ROV**: de segunda mano aquí; verificar en
   NIST RPKI Monitor, RIPE NCC y APNIC.
2. **Participantes de MANRS y estado de sus programas**: consta el traspaso de secretaría de ISOC a
   **Global Cyber Alliance** (2024) y "más de 1.300 participantes" citado en la reunión de comunidad
   del **17-jun-2026** en un artículo del propio MANRS; **no verificado de forma independiente**.
3. **Orden exacto del proceso de decisión BGP por fabricante**: cada implementación añade pasos
   (`weight`, `MED` entre AS distintos, multipath, bestpath determinista). Verificar en su documentación.
4. **Comportamiento de MLAG ante split brain, pérdida de keepalive y actualización del par**:
   **específico de cada implementación**, no verificado aquí. Se comprueba en laboratorio.
5. **Ediciones vigentes de IEEE 802.1Q y sus amendments**: procedente de búsqueda, **no contrastado**
   contra el catálogo de IEEE SA.
6. **Versión, mantenimiento y licencia de Routinator, rpki-client y StayRTR**: **no verificados**.
7. **Fiabilidad relativa de cada IRR** y sus políticas de validación de objetos: **no verificada**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
