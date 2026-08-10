---
name: datacenter-fabric-standards
description: The data centre network as a routed Clos fabric, not one big switched network. Use when designing or reviewing a leaf-spine (Clos) topology, oversubscription ratio and spine count, eBGP-per-leaf with private ASNs or IS-IS as the underlay, BGP unnumbered with IPv6 link-local next hops (RFC 8950), RFC 7938 large-scale DC routing, VXLAN encapsulation (RFC 7348) or Geneve (RFC 8926), EVPN control plane (RFC 7432, RFC 8365) replacing flood-and-learn, EVPN route types 1-5, IMET, ESI and RFC 9136 type-5 IP prefix routes, symmetric versus asymmetric IRB (RFC 9135), anycast distributed gateway, L3VNI/L2VNI and VRF multi-tenancy, EVPN multihoming with ESI-LAG and RFC 9746 split-horizon versus proprietary MLAG/vPC, jumbo frames and encapsulation MTU overhead, ARP/ND suppression and proxy-ARP (RFC 9161), BUM traffic handling (RFC 9572), configuring lossless Ethernet on the switch with PFC (802.1Qbb), ETS (802.1Qaz), DCBX, ECN (RFC 3168) and DCQCN, DCI and the danger of stretching layer 2, or deciding that two switches and plain routing are enough and EVPN is not needed.
---

# Estándares de malla de centro de datos — Clos, EVPN y cuándo no hacer nada de esto

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **diseñar, dimensionar y operar la red interna de un centro de datos**: topología Clos
hoja-espina, sobresuscripción y escalado, protocolo de la malla (*underlay*), superposición
VXLAN/EVPN (*overlay*), enrutado integrado y pasarela distribuida, multi-inquilino con VRF, MTU de
encapsulación, multihoming de servidores, red sin pérdidas para almacenamiento y RDMA, interconexión
entre centros de datos, y **el criterio para no construir una malla EVPN**.

Triggers: "leaf-spine", "Clos", "spine", "leaf", "border leaf", "superspine", "oversubscription",
`vxlan`/`vni`/`vtep`/`nve`, `evpn`, `l2vpn evpn`, `route-type 2`/`type-5`, `esi`, `anycast-gateway`,
`irb`, `l3vni`/`l2vni`, `vrf`, "BGP unnumbered", "underlay/overlay", `mtu 9216`/"jumbo", `pfc`,
`802.1Qbb`, `dcbx`, `ets`, `ecn`, `wred`, `dcqcn`, "lossless", "RoCE", "DCI", "VXLAN stretch",
"MLAG", "vPC", "ESI-LAG".

**No aplica** — cada skill **decide** una cosa distinta:
`networking-standards` (**troncal, madre**: decide **direccionamiento e IPAM, qué VLAN existe,
fundamentos de BGP/OSPF, MTU/MSS de diseño, proxies y overlays de host, NetBox como SoT**; aquí no se
reabre nada de eso, aquí se decide **la topología y el plano de control de la malla**);
`routing-switching-standards` (**decide campus y borde**: STP, MLAG de campus, VRRP, IGP de sede,
**política BGP hacia el exterior**, RPKI, QoS, CoPP y plano de gestión — aquí sólo BGP como protocolo
de malla interna, no la política de Internet); `network-troubleshooting-standards` (**decide el método
reactivo** cuando la malla ya falla); `network-automation-standards` (**decide cómo se genera, se
prueba y se aplica** esta configuración, y su telemetría); `high-speed-interconnect-standards`
(**ya escrita**: **InfiniBand y RoCE como interconexión de cómputo son suyos**; aquí sólo la
Ethernet que los transporta); `datacenter-facilities-standards` (**la planta
física es suya** — energía, refrigeración, racks, cableado); `kubernetes-standards` (**decide lo que va
por encima**: CNI, Service, Ingress, NetworkPolicy, service mesh); `firewall-policy-standards`
(**decide qué flujo se permite entre inquilinos y zonas**); `finops-standards` (coste por puerto,
óptica y transceptor). También frontera: `onprem-standards` (paraguas), `iac-standards`,
`observability-standards`, `sre-practice-standards`, `secrets-management-standards`,
`linux-hardening-standards`, `vulnerability-management-standards`,
`identity-access-management-standards`, `offensive-security-standards` (**esta skill es defensiva**),
`vpn-standards`, `dns-standards`, `network-vendors-standards`, `telco-5g-standards` y
`wan-legacy-standards`.

**Principio rector**: **el centro de datos moderno se diseña como una malla enrutada, no como una red
conmutada grande.** La capa 2 se reduce al mínimo y se transporta encapsulada sobre routing; el
caudal escala horizontalmente; y **la latencia predecible vale más que el pico de ancho de banda**.

## 2. Decisiones por defecto

> Verificar por web estado, versión y RFC antes de fijar nada (§8). Los RFC de esta tabla están
> verificados uno a uno contra la API JSON de `rfc-editor.org`.

| Decisión | Por defecto | Alternativa justificable / vetado |
|---|---|---|
| Topología | **Clos hoja-espina de dos niveles**; tres niveles sólo cuando las hojas superan el radio de las espinas | ❌ Núcleo-distribución-acceso con VLAN extendidas en DC nuevo; ❌ anillo o árbol con STP |
| Conectividad | **Cada hoja a todas las espinas; ninguna hoja a otra hoja, ninguna espina a otra espina.** Más caudal = una espina más | Enlaces hoja-hoja: rompen el camino uniforme y la predictibilidad |
| Sobresuscripción | **Declararla explícitamente** por rol de rack (1:1 o 2:1 en almacenamiento/IA, 3:1–4:1 en cómputo general) | ❌ No calcularla y descubrirla en producción; ❌ mismo ratio para todos los racks |
| Underlay | **eBGP, ASN privada por hoja**, espinas con ASN común, ECMP a todas. **RFC 7938** (Informational) como referencia | **IS-IS** si se prefiere IGP puro y el equipo lo domina; OSPF es la peor de las tres aquí |
| Direccionamiento del underlay | **BGP unnumbered**: siguiente salto IPv6 link-local sobre enlaces sin numerar — **RFC 8950** (nov-2020, **obsoleta RFC 5549**) | Numerar cada `/31`: funciona, pero es inventario que se automatiza mal |
| Detección de fallo | **BFD** en cada sesión del underlay, con ECMP recalculando | Temporizadores BGP agresivos: castigan la CPU y convergen peor |
| Encapsulación | **VXLAN — RFC 7348** (Informational, ago-2014) por soporte universal en hardware | **Geneve — RFC 8926** (Proposed Standard) es técnicamente superior pero su soporte en ASIC es desigual: **verificar por plataforma** |
| Plano de control del overlay | **EVPN — RFC 7432** con **RFC 8365** (EVPN sobre NVO/VXLAN) | ❌ **Flood-and-learn con VXLAN multicast**: aprende inundando, depende de multicast en el underlay y no escala |
| IRB | **Simétrico — RFC 9135** (oct-2021). Default moderno: cada VTEP sólo necesita sus VLAN locales y el tránsito va por un **L3VNI** común | **Asimétrico** exige que **todas** las VNI existan en **todos** los VTEP: más simple de entender, no escala |
| Pasarela | **Distribuida anycast**: misma IP y MAC en todas las hojas; el primer salto nunca cruza la malla | ❌ Pasarela centralizada: convierte una malla en topología radial y añade *tromboning* |
| Multi-inquilino | **VRF por inquilino mapeada a L3VNI**; prefijos IP con **RFC 9136** (type-5); fugas entre VRF sólo por política escrita | ❌ Espacio de enrutado único "porque son todos nuestros" |
| MTU | **Jumbo en toda la malla (≥ 9000 de payload)**, uniforme y verificada extremo a extremo. **No negociable** | ❌ MTU 1500 con VXLAN encima; ❌ MTU distinta en un solo enlace |
| Multihoming de servidor | **EVPN multihoming (ESI-LAG)**: estándar, sin enlace de par, activo-activo, N hojas. Split-horizon actualizado por **RFC 9746** (mar-2025) | **MLAG/vPC propietario** sólo si el hardware no soporta EVPN-MH: ata a un fabricante y añade estado compartido |
| Elección de DF | Algoritmo de *designated forwarder* **explícito** — **RFC 8584** (abr-2019) hizo el marco extensible | Dejarlo al default y descubrirlo con tráfico BUM duplicado |
| Red sin pérdidas | **Sólo donde el protocolo lo exija** (RDMA/RoCE, algún almacenamiento). **ECN (RFC 3168) primero, PFC como último recurso**, en una sola clase | ❌ PFC habilitado "por si acaso" en toda la malla |
| DCI | **Interconexión enrutada (L3) por defecto** | Extensión L2 entre DC **sólo** con requisito escrito, dominio de fallo acotado y fecha de retirada |

## 3. Decisiones de diseño

**EVPN: qué resuelve realmente**
VXLAN sin plano de control **inunda y aprende**, como un switch. EVPN sustituye eso por **BGP
anunciando lo que cada VTEP conoce**, y con ello desaparecen la dependencia de multicast en el
underlay, la inundación de unicast desconocido y buena parte del ARP/ND en el cable.

- **Tipo 1 — Ethernet Auto-Discovery**: descubrimiento por ESI; sostiene el multihoming (convergencia
  rápida al caer un enlace, *aliasing* para balancear hacia un servidor multihomed).
- **Tipo 2 — MAC/IP Advertisement**: MAC y, opcionalmente, IP del host. Es lo que hace posible la
  **supresión de ARP/ND** (aspectos operativos de proxy ARP/ND en **RFC 9161**).
- **Tipo 3 — IMET**: construye el árbol de réplica del tráfico BUM. Procedimientos actualizados por
  **RFC 9572** (may-2024).
- **Tipo 4 — Ethernet Segment**: descubre quién comparte segmento y **elige el designated forwarder**
  que reenvía BUM hacia él (evita duplicados y bucles).
- **Tipo 5 — IP Prefix (RFC 9136)**: prefijos IP sin MAC; conectividad externa, resumen, VRF.
- **Regla de lectura**: problema de alcance L2 dentro de una VNI → tipos 2 y 3; multihoming o tráfico
  duplicado → tipos 1 y 4; conectividad entre VRF o hacia fuera → tipo 5.

**MTU: el requisito no negociable**
- La encapsulación **añade cabecera** (VXLAN sobre UDP/IP añade decenas de bytes; Geneve más, y
  **variable** por opciones). Si la malla no transporta la trama del inquilino **más** esa cabecera,
  se rompe.
- **Qué se rompe si falta**: el ping funciona, el handshake TCP funciona y la transferencia se cuelga.
  Los paquetes grandes con DF desaparecen y, sin ICMP *fragmentation needed* / *packet too big* de
  vuelta, PMTUD muere en silencio. **Síntoma canónico: "conecta pero se cuelga al transferir"** — la
  demostración es de `network-troubleshooting-standards`; **el arreglo es de aquí y es de diseño**.
- **Uniforme significa uniforme**: un solo enlace con MTU menor hace el problema intermitente y
  dependiente del camino ECMP. Se verifica como gate (§4), no por inspección visual.

**Multihoming de servidor**
- **EVPN-MH (ESI-LAG)** es el default: estándar, sin enlace de par entre hojas, admite más de dos
  hojas, sin estado compartido propietario. Se decide explícitamente el valor y unicidad del **ESI**,
  el algoritmo de **DF election** (RFC 8584) y el comportamiento ante pérdida del único uplink de una
  hoja.
- **MLAG/vPC** sigue siendo válido donde el hardware manda, pero **arrastra a la malla los modos de
  fallo del campus** (*split brain*, keepalive, actualización del par) que en EVPN-MH no existen. Si
  lo eliges, se prueban esos tres casos en laboratorio (criterio en `routing-switching-standards`).

**Almacenamiento y RDMA: la red sin pérdidas mal hecha propaga la congestión**
- **PFC (IEEE 802.1Qbb, hoy incorporado a 802.1Q)** pausa por prioridad en el enlace, y su efecto es
  **empujar la congestión hacia atrás**: si el receptor no drena, la pausa se propaga salto a salto y
  detiene tráfico que no tenía nada que ver (*congestion spreading*). Con ciclos de dependencia de
  buffer puede producir **deadlock por PFC**, del que la red no sale sola.
- **Por eso el orden es ECN primero**: marcado ECN (**RFC 3168**) con umbrales por cola y control de
  tasa extremo a extremo (**DCQCN** en RoCEv2, que combina ECN y realimentación al emisor). PFC queda
  como red de seguridad de última instancia, no como mecanismo principal.
- Requisitos si se despliega: **una sola clase sin pérdidas**, ETS (**IEEE 802.1Qaz**) repartiendo el
  resto, mapeo de prioridad **coherente en todos los saltos** (una discrepancia rompe la garantía),
  *headroom* de buffer dimensionado, y **monitorización de tramas de pausa y de marcado ECN**: si
  nadie mira los contadores de PFC, no sabes que estás pausando.
- **InfiniBand frente a RoCE** es de `high-speed-interconnect-standards` (**ya escrita**).

**DCI: el peligro de extender capa 2**
- **Por defecto, los DC se interconectan por capa 3.** Extender capa 2 crea **un único dominio de
  fallo con latencia de por medio**: tormenta, bucle o fallo de control plane se propagan a los dos
  sitios a la vez, y la alta disponibilidad que motivó la extensión desaparece justo en el escenario
  que la justificaba.
- Si el requisito es real, se acota: sólo las VNI necesarias, con control de BUM y de MAC, dominios de
  fallo separados a ambos lados y **fecha de retirada escrita**. Una extensión "temporal" sin fecha es
  permanente. La alternativa correcta casi siempre es **arreglar la aplicación** que asume adyacencia
  L2 y trata la IP como identidad.

**Cuándo NO hace falta una malla EVPN — la sección que más valor aporta**
- **Un rack, dos ToR y enrutado simple bastan.** Con dos conmutadores, un par de VLAN, LACP hacia los
  servidores y pasarela redundante, EVPN no aporta nada y añade un plano de control entero que hay que
  saber operar, diagnosticar y actualizar.
- **Umbrales honestos para plantearlo**: más de un puñado de racks; necesidad real de mover una subred
  entre racks; multi-inquilino con solapamiento de direcciones; multihoming estándar a más de dos
  hojas. **Ninguno es "queremos VXLAN porque es lo moderno".**
- **Coste que hay que aceptar antes**: personal capaz de diagnosticar BGP con familias L2VPN, NOS con
  soporte maduro, laboratorio para probar cambios, y automatización (no se opera a mano). Si falta
  cualquiera de los cuatro, **una malla EVPN es una fuente de incidentes, no una mejora**.
- **Alternativas legítimas**: routing puro con ECMP y sin overlay cuando cada rack es una subred;
  overlay **en el host** (Kubernetes o el hipervisor ya lo hacen, `kubernetes-standards`) dejando la
  red física como transporte tonto y rápido.
- **Regla**: **la complejidad del plano de control se justifica por un requisito escrito, no por el
  catálogo del fabricante.**

## 4. Gates de calidad

- **Verificación de MTU extremo a extremo** como gate automático tras cada cambio: prueba con paquete
  grande y bit DF entre VTEP y entre hosts de VNI distintas, no inspección de configuración.
- **Prueba de fallo con tráfico real y medición** antes de producción: caída de una espina (debe ser
  transparente), de un uplink de hoja, de una hoja en un servidor multihomed, y **la recuperación de
  cada una** (la vuelta falla más que la ida).
- **Prueba negativa de aislamiento entre inquilinos**: verificar que las VRF **no** se alcanzan entre
  sí. Un multi-inquilino probado sólo por el camino feliz no está probado.
- **Coherencia entre pares del mismo rol**: la malla es regular por diseño, así que **una hoja distinta
  de las demás es un hallazgo**. Diff automático.
- **Laboratorio virtual con las mismas versiones de NOS** antes de cualquier cambio de EVPN, underlay o
  política de VRF (herramientas en `network-automation-standards`).
- Con red sin pérdidas: validar que la clase está mapeada igual en **todos** los saltos y ejecutar
  prueba de carga observando contadores de PFC y ECN.

## 5. Operación y seguridad

- **Plano de gestión OOB para toda la malla**, separado del tráfico de datos, con AAA centralizado y
  SSH/SNMPv3 (criterio completo en `routing-switching-standards`). Es lo que te deja arreglar el
  cambio de underlay que aisló una hoja.
- **La malla no es una zona de confianza.** Compartir fabric no autoriza tráfico: la política
  este-oeste es de `firewall-policy-standards`. **La VRF segrega enrutado, no aplica política.**
- **VXLAN no cifra ni autentica nada**: quien pueda inyectar en el underlay puede inyectar en una VNI.
  El underlay debe estar físicamente acotado y el tráfico sensible protegido por encima (mTLS, IPsec,
  MACsec en enlaces que salgan del recinto).
- **Señales que se vigilan siempre**: sesiones BGP de underlay y overlay, rutas EVPN por tipo, entradas
  MAC y ARP/ND por VTEP **frente al límite de la tabla del ASIC** (agotarla es un fallo silencioso y
  brutal), descartes y errores por interfaz, **balanceo real del ECMP** (un hash desequilibrado satura
  un enlace con la malla al 40%), contadores de PFC/ECN, y óptica.
- **Actualizaciones**: una a una, por rol, **drenando el nodo antes** (retirarlo del ECMP) y verificando
  entre pasos. Actualizar espinas y hojas a la vez es cómo se pierde un centro de datos.
- **Rendimiento específico de la malla**: el valor de Clos es que todos los pares hoja-hoja están a la
  misma distancia y el percentil alto de latencia es estable — un diseño que mejora el pico a costa de
  caminos desiguales es peor para aplicaciones distribuidas, que esperan al más lento. **ECMP con hash
  por flujo, nunca por paquete**; vigila la entropía real (pocos flujos grandes desequilibran ECMP
  aunque sobre capacidad). El buffer del ASIC es finito y compartido: la mayoría de los descartes
  inexplicables son *incast*, que no se arregla con más ancho de banda.
- **Capacidad**: el ratio de sobresuscripción se revisa con datos reales por rack, no con el del diseño
  original. Coste por puerto y óptica en `finops-standards`.

## 6. Rendimiento

**Sección omitida a propósito**: la telemetría, sus umbrales y sus alertas son de
`observability-standards`; el diagnóstico reactivo, de `network-troubleshooting-standards`; y lo
específico de rendimiento de la malla está integrado en §5, donde se opera. Duplicarlo aquí sería
relleno.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: NOS revisado por trimestre y ante CVE explotable; **rama estable con soporte EVPN
  maduro** frente a la última funcionalidad. Un bug de EVPN es un incidente de todo el DC.
- **Deprecación**: VNI, VRF y ESI retirados se eliminan de configuración, SoT y documentación.
- **Fin de soporte del hardware inventariado**: la malla se sustituye por generaciones, y el plan
  empieza antes de que el fabricante lo anuncie.

**PROHIBIDO**
- ❌ Diseñar un DC nuevo como red conmutada grande con VLAN extendidas y STP como convergencia.
- ❌ Enlaces hoja-hoja o espina-espina en un Clos.
- ❌ VXLAN **flood-and-learn** (sin EVPN) en un despliegue nuevo.
- ❌ Malla con MTU 1500, o con MTU distinta en algún enlace.
- ❌ Pasarela centralizada en lugar de anycast distribuida, sin requisito escrito.
- ❌ IRB asimétrico por defecto en una malla que crecerá.
- ❌ Extender capa 2 entre centros de datos sin requisito escrito, sin acotar el dominio de fallo y sin
  fecha de retirada.
- ❌ PFC en toda la malla "por si acaso"; o red sin pérdidas sin ECN, sin mapeo coherente en todos los
  saltos y sin monitorizar contadores de pausa.
- ❌ Tratar la malla como zona de confianza y saltarse la política este-oeste.
- ❌ Construir una malla EVPN para un rack, o sin personal, laboratorio y automatización para operarla.
- ❌ Actualizar varias hojas o espinas a la vez, o sin drenar el nodo antes.
- ❌ Configuración divergente entre equipos del mismo rol, o hecha a mano fuera del SoT.
- ❌ No declarar el ratio de sobresuscripción por rol de rack.
- ❌ ECMP con hash por paquete.
- ❌ Poner en producción una malla sin haber probado y **medido** caída de espina, uplink y hoja con
  tráfico real.

## 8. Verificación web obligatoria

**Metodología**: los RFC se verificaron **uno a uno** contra la API JSON de `rfc-editor.org` (título,
estado, fecha, `obsoletes`/`obsoleted_by`/`updated_by`), no contra resúmenes HTML.

**RFC verificados ago-2026**. **VXLAN = RFC 7348** (ago-2014, **Informational** — no es Standards
Track; citarlo como "estándar" es incorrecto); **Geneve = RFC 8926** (nov-2020, Proposed Standard).
**EVPN = RFC 7432** (feb-2015), actualizado por **8584, 9161, 9572, 9573 y 9746**; **EVPN sobre
NVO/VXLAN = RFC 8365** (mar-2018), actualizado por **9746**. **IRB simétrico/asimétrico = RFC 9135** y
**prefijos IP / type-5 = RFC 9136** (ambos oct-2021). **Marco de elección de DF = RFC 8584** (abr-2019,
actualizado por 9722 y 9785). **Split-horizon en multihoming EVPN = RFC 9746** (mar-2025), que
**actualiza 7432 y 8365**. **Proxy ARP/ND = RFC 9161** (ene-2022); **BUM = RFC 9572** (may-2024).
**BGP en DC a gran escala = RFC 7938** (ago-2016, **Informational**). **Siguiente salto IPv6 para NLRI
IPv4 ("BGP unnumbered") = RFC 8950** (nov-2020), que **obsoleta RFC 5549** — citar 5549 hoy es un error
de hecho. **ECN = RFC 3168**, actualizado por 4301, 6040, 8311 y 9768. **IEEE**: PFC = **802.1Qbb** y
QCN = **802.1Qau**, ambos **incorporados a la base 802.1Q** (revisión vigente 802.1Q-2022); ETS =
**802.1Qaz**; DCBX es extensión de LLDP (802.1AB).

**Discrepancia declarada**: **RFC 7432 tiene un sucesor en curso.** `draft-ietf-bess-rfc7432bis` está
en revisión **-14** con actividad el **2-mar-2026** y **aún no es RFC** (`rfc: null` en datatracker,
sin *intended std level* declarado en el registro consultado). La referencia normativa vigente sigue
siendo **RFC 7432**, pero está en sustitución: verifica si ya se publicó antes de citarlo en un
documento de arquitectura.

**Huecos declarados — NO rellenar de memoria**:
1. **Bytes exactos de sobrecarga de VXLAN y Geneve** y la MTU mínima concreta resultante: **no
   verificados byte a byte**. Geneve es **variable** por sus opciones. Calcúlalo y **pruébalo**.
2. **Soporte de Geneve en ASIC** por plataforma y generación: **no verificado**, y es el criterio que
   decide VXLAN frente a Geneve.
3. **Límites de tabla del ASIC** (MAC, ARP/ND, rutas, VTEP, VNI): **no verificados**. Son el techo real
   de la malla y varían por modelo y perfil de reenvío.
4. **Versiones y estado de soporte de EVPN por NOS** (incluidos NOS abiertos tipo SONiC y basados en
   FRR): **no verificados**. Comprobar versión, mantenimiento y **licencia en crudo** antes de fijar
   cualquiera como default.
5. **Umbrales de ECN, *headroom* de PFC y parámetros de DCQCN**: **no verificados** y muy dependientes
   del hardware y del perfil de tráfico. Parten de la guía del fabricante y se validan con carga.
6. **Deadlock por PFC en topologías Clos concretas** y sus mitigaciones vigentes: criterio general aquí,
   **no contrastado** contra literatura reciente.
7. **Ratios de sobresuscripción típicos por carga** (IA frente a cómputo general): son criterio de
   ingeniería, **no medidas verificadas**.
8. **`high-speed-interconnect-standards` ya existe**: InfiniBand, RoCE v2, iWARP, el gestor de
   subred, el bloqueo mutuo por PFC visto desde el interconector y NVMe over Fabrics **son suyos**.
   `datacenter-facilities-standards` **también existe**: la planta física —energía, refrigeración,
   cableado— es suya. No la improvises aquí.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
