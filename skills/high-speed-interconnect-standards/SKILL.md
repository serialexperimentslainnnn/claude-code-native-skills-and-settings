---
name: high-speed-interconnect-standards
description: RDMA interconnects for HPC, AI and storage — InfiniBand, RoCE v2 and iWARP as a separate network from the data network. Use when designing or debugging an InfiniBand fabric with opensm or a vendor subnet manager, LIDs, GUIDs, P_Key partitions, SHARP in-network reduction, ibstat, ibstatus, ibnetdiscover, ibdiagnet, perfquery, ibping, iblinkinfo and port error counters, RoCE v2 on Ethernet with rdma-core, ibv_devinfo, rdma link, mlx5 or irdma drivers, RoCE priority and DSCP mapping and end-to-end validation, out-of-sequence and CNP counters, iWARP (RFC 5040, RFC 5044), Ultra Ethernet UEC 1.0 as an emerging alternative, choosing between InfiniBand and Ethernet for a GPU or HPC cluster, fat-tree and dragonfly topologies for compute clusters, libibverbs and verbs programming, UCX, MPI over RDMA (Open MPI, MPICH, UCX transports), NCCL or RCCL collectives and their network backend, GPUDirect RDMA, NVMe over Fabrics with RoCE, TCP or Fibre Channel, nvme connect and nvme discover, SMB Direct, NFS over RDMA (RFC 8166), deciding that NVMe/TCP is good enough and no RDMA is needed, or diagnosing an RDMA fabric where the symptom is collapsed throughput rather than packet loss.
---

# Estándares de interconexión de alta velocidad — RDMA, InfiniBand y RoCE

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **diseñar, desplegar, validar y diagnosticar la red de cómputo y de almacenamiento de alto
rendimiento**: RDMA como modelo, elección de transporte (InfiniBand, RoCE v2, iWARP), gestión de
subred y particiones, topologías de cómputo y su sobresuscripción, pila de software (verbs, UCX, MPI,
colectivas de GPU), almacenamiento sobre RDMA, y **el criterio para no usar RDMA en absoluto**.

Triggers: `ibstat`, `ibnetdiscover`, `ibdiagnet`, `perfquery`, `iblinkinfo`, `opensm`, "subnet
manager", "LID", "P_Key", "SHARP", `rdma-core`, `ibv_devinfo`, `rdma link`, `mlx5`, `irdma`, "RoCE
v2", "iWARP", "GPUDirect", "verbs", "UCX", "NCCL"/"RCCL", "MPI", "fat-tree", "dragonfly", "NVMe-oF",
`nvme connect`, "SMB Direct", "NFS over RDMA", "Ultra Ethernet"/"UEC".

**No aplica** — el catálogo ya reparte esto: `networking-standards` es la **troncal** (VLAN,
direccionamiento, MTU, plano de gestión) y **ya delega la profundidad**, mientras
`datacenter-fabric-standards` **posee la Ethernet que transporta RoCE** — Clos, VXLAN/EVPN y **toda
la mecánica de la red sin pérdidas: PFC, ETS, DCBX, ECN y DCQCN, con sus umbrales y su
monitorización** (aquí sólo **qué exige el interconector y cómo se valida extremo a extremo**),
`routing-switching-standards` posee el campus, la política BGP y la seguridad del plano de control, y
`network-automation-standards` la configuración como código. Hacia fuera: **la GPU y su cómputo son
de `gpu-computing-standards`**, **el planificador de trabajos y el dimensionado del clúster, de
`hpc-standards`**, el sistema de ficheros y el bloque local de
`linux-storage-standards`, el objeto de `object-storage-standards`, la metodología de medir y el
modelo de carga de `performance-engineering-standards`, métricas y alertas de
`observability-standards`, el SLO de `sre-practice-standards`, el método reactivo de
`network-troubleshooting-standards`, el filtrado de `firewall-policy-standards`, la identidad de
`identity-access-management-standards`, la malla de `microservices-architecture-standards`, la caché
de `caching-cdn-standards`, los contenedores de `kubernetes-standards`, y el paraguas de
`onprem-standards` (con `datacenter-facilities-standards`, dueña de la planta física).
Entre las tres hermanas de esta tanda: `wireless-standards` es la **red de acceso**,
`load-balancing-standards` la **red de servicio** y ésta la **red de cómputo**; **el error del
dominio es aplicarles el mismo criterio**.

**Principio rector**: **la red de cómputo y de almacenamiento no es la red de datos.** Otro modelo de
fallo (el síntoma no es pérdida, es colapso de rendimiento), otro criterio de sobresuscripción, otro
plano de gestión y otro personal. Tratarla como "una VLAN más" es el error caro del dominio.

## 2. Decisiones por defecto

> Verificar estado del ecosistema, tasas vigentes, versiones y **licencia en crudo** antes de fijar
> nada (§8).

| Decisión | Por defecto | Alternativa justificable / vetado |
|---|---|---|
| ¿RDMA sí o no? | **No, por defecto.** Se justifica con un requisito medido que TCP no alcanza | ❌ RDMA "porque es más rápido" sin número objetivo ni equipo capaz de operarlo |
| Transporte de cómputo | **InfiniBand** cuando el clúster es de entrenamiento o HPC clásico y hay presupuesto y personal | **Ethernet con RoCE v2** cuando manda el ecosistema abierto, el multi-uso o el coste; **iWARP**, en retirada de facto |
| Transporte de almacenamiento | **NVMe/TCP** salvo requisito medido | NVMe-oF/RoCE con red sin pérdidas validada; FC-NVMe si ya existe SAN de fibra |
| Red sin pérdidas para RoCE | **Obligatoria y validada extremo a extremo**, en **una sola clase**, con ECN primero y PFC como último recurso (mecánica en `datacenter-fabric-standards`) | ❌ Desplegar RoCE sin control de congestión validado extremo a extremo |
| Sobresuscripción en cómputo | **1:1 (no bloqueante)** en la red de entrenamiento/HPC | 2:1 sólo con perfil de tráfico medido; ❌ importar los 3:1-4:1 de una malla de cómputo general |
| Topología | **Fat-tree (Clos) no bloqueante** como default | **Dragonfly** a gran escala por coste de cable, asumiendo enrutado adaptativo y más complejidad |
| Gestión de subred (IB) | **Un SM primario y al menos uno de reserva**, con configuración versionada | ❌ SM único; ❌ dos SM "maestros" compitiendo por descubrimiento accidental |
| Aislamiento (IB) | **Particiones (P_Key)** declaradas por inquilino/servicio | ❌ Todo en la partición por defecto y llamarlo segmentación |
| Pila de usuario | **rdma-core / libibverbs** como base y **UCX** como transporte de MPI y colectivas; **NCCL/RCCL** con GPUDirect RDMA verificado | ❌ Reimplementar transporte sobre verbs; ❌ suponer GPUDirect activo porque la tarjeta lo soporta |
| Plano de gestión | **Fuera de banda y separado del fabric**, como cualquier equipo de red | ❌ Gestionar los switches del fabric por el propio fabric |

## 3. Criterio de diseño

**RDMA: qué es y qué exige**
- **Acceso directo a memoria remota**: la tarjeta lee y escribe memoria del otro extremo **sin copias
  intermedias y sin pasar por el núcleo** en el camino de datos. De ahí las tres ganancias reales:
  latencia baja y **predecible**, cero copia y CPU liberada.
- **Lo que exige de la aplicación**: registrar y anclar memoria (coste no trivial y límites de
  `memlock`), gestionar colas y compleciones, y **asumir otro modelo de fallo** — la conexión fiable
  aborta la *queue pair* ante error y la recuperación es de la aplicación. **Una aplicación que no
  habla verbs no gana nada por poner tarjetas RDMA**: es una decisión de arquitectura, no un ajuste
  de red, y si el software no está portado el proyecto es de desarrollo.

**InfiniBand frente a RoCE v2 frente a iWARP — criterio honesto**
- **InfiniBand**: pila coherente de extremo a extremo, control de flujo por créditos **en el propio
  protocolo**, gestión centralizada por SM y agregación en red. Menor riesgo técnico en entrenamiento
  y HPC. **El precio**: ecosistema muy concentrado —la especificación es de la IBTA, pero el mercado
  de adaptador y conmutador lo domina un fabricante desde la compra de Mellanox por NVIDIA—, coste
  alto y personal que hay que formar o contratar.
- **RoCE v2**: RDMA en UDP/IP, luego **enrutable** y sobre conmutadores de cualquiera; ecosistema
  abierto y personal que ya tienes. **El precio**: **la red pasa a ser responsabilidad tuya**, y es
  donde se rompe (§ siguiente).
- **iWARP**: RDMA sobre TCP (**RFC 5040** y **RFC 5044**), sin exigir red sin pérdidas. Suena ideal y
  **en la práctica ha perdido el mercado**: soporte de tarjetas escaso y adopción en declive. No lo
  elijas para algo nuevo sin verificar que existe hardware que quieras comprar.
- **Ultra Ethernet (UEC)** es el movimiento a vigilar: especificación **1.0 publicada en jun-2025**,
  con transporte RDMA moderno, reparto por múltiples caminos y reordenación en la tarjeta, justo para
  arreglar lo que RoCE v2 hace mal. **Aún no es el default seguro**: verifica hardware real primero.
- **Regla de elección**: ¿tienes equipo capaz de operar y **diagnosticar** una Ethernet sin pérdidas?
  Si no, o InfiniBand o NVMe/TCP y nada de RDMA. La peor combinación es **RoCE operado por gente que
  no sabe que lo está operando**.

**RoCE necesita una red sin pérdidas: qué exige el interconector**
- **La mecánica es de `datacenter-fabric-standards`** (PFC 802.1Qbb, ETS 802.1Qaz, DCBX, ECN y
  DCQCN). Aquí sólo lo que el interconector impone:
  1. **Una única clase sin pérdidas**, con la prioridad de RoCE mapeada **idénticamente en todos los
     saltos y en las dos tarjetas**: una discrepancia en un solo salto anula la garantía.
  2. **Coherencia entre DSCP y prioridad L2** (RoCE v2 es UDP/IP: la marca que sobrevive al enrutado
     es DSCP), y **MTU y jumbo coherentes** en todo el camino.
  3. **Control de congestión configurado también en la tarjeta** (DCQCN o equivalente), no sólo en la
     red: es **extremo a extremo**, y media configuración es ninguna.
- **Por qué una red sin pérdidas mal configurada empeora las cosas**: PFC no descarta, **pausa**, y la
  pausa **empuja la congestión hacia atrás** hasta detener tráfico ajeno (*congestion spreading*);
  con ciclos de dependencia de buffer aparece el **bloqueo mutuo por PFC (deadlock)**, del que la red
  **no sale sola** y que se ve como una parte del clúster parada sin errores obvios. Has cambiado
  "perder paquetes" por "parar a todo el mundo": si el control de congestión extremo a extremo no
  funciona, has empeorado el fallo, no lo has quitado.
- **Validación extremo a extremo, obligatoria**: carga real entre pares distantes observando
  **contadores de pausa PFC, marcas ECN y CNP en tarjetas y conmutadores**. Si nadie mira los
  contadores, no sabes si estás pausando. Es un gate (§4).

**Gestión: el gestor de subred y por qué Ethernet no tiene equivalente**
- En InfiniBand, el **Subnet Manager** descubre la topología, **asigna los LID**, programa las
  **tablas de reenvío** de cada conmutador y mantiene el estado. **Sin SM el fabric no pasa de "link
  up": no reenvía nada.** Consecuencias: **SM primario y de reserva**, configuración versionada, y
  conciencia de que un SM ajeno en la subred puede reprogramarla. **El reencaminamiento es una
  operación observable** que conviene provocar en laboratorio. Las **particiones (P_Key)** son el
  aislamiento nativo: por inquilino o servicio, no todo en la partición por defecto.
- **En Ethernet no hay nada de esto**: no existe entidad central que programe el reenvío. Su
  equivalente funcional son **protocolos distribuidos** (BGP/EVPN, ECMP) más tu automatización — es
  decir, **lo que en InfiniBand es un componente, en Ethernet es un proyecto**. Ése es el coste
  oculto real de elegir RoCE.

**Topologías y sobresuscripción en cómputo**
- **Fat-tree no bloqueante** es el default: caminos iguales entre cualquier par y latencia
  predecible. **Dragonfly** reduce cable y coste a gran escala a cambio de caminos desiguales y
  dependencia del **enrutado adaptativo**; sólo con equipo que sepa operarlo.
- **La sobresuscripción se decide con otro criterio que en una malla de centro de datos**: allí el
  tráfico son muchos flujos independientes y 3:1 es razonable; aquí una colectiva síncrona hace que
  **todo el trabajo avance al ritmo del enlace más lento**, así que no degrada un poco: degrada el
  trabajo entero. Default **1:1**; otra cosa es decisión escrita y medida. Y el ***incast* de las
  colectivas** (muchos emisores a un receptor) rompe buffers: no se arregla con más ancho de banda,
  sino con control de congestión y agregación en red.

**Software**
- **verbs / rdma-core** es la base; casi nadie debería programar ahí directamente. **UCX** es la capa
  de transporte que usan MPI y otras bibliotecas: si algo va mal en MPI, el diagnóstico suele estar en
  UCX —transporte seleccionado, dispositivo elegido, memoria registrada—, no en el conmutador. **MPI**
  (Open MPI, MPICH) y el planificador son de `hpc-standards`.
- **Colectivas de GPU (NCCL/RCCL)**: el entrenamiento distribuido depende de que elijan el transporte
  correcto y de que **GPUDirect RDMA** esté realmente activo (tarjeta y GPU en un dominio PCIe/NUMA
  razonable). **Verifícalo, no lo supongas**: la degradación silenciosa habitual es caer a un camino
  que copia por CPU. La GPU en sí es de `gpu-computing-standards`.

**Almacenamiento sobre RDMA — la sección más útil, porque la mayoría no necesita RDMA**
- **NVMe over Fabrics** tiene tres transportes vivos: **RoCE** (menor latencia, exige red sin
  pérdidas), **TCP** (cualquier NIC, cualquier switch, cualquier topología enrutada) y **Fibre
  Channel** (natural si ya tienes SAN).
- **NVMe/TCP es suficiente para la inmensa mayoría** y evita todo lo anterior: sin red sin pérdidas,
  sin PFC, sin mapeo de prioridades, sin personal especializado. El coste es latencia y CPU, y buena
  parte se recupera con descarga en la tarjeta.
- **Criterio**: empieza en NVMe/TCP; pasa a NVMe-oF/RoCE **sólo** con un requisito de latencia
  **medido** que TCP no cumple **y** equipo capaz de mantener la Ethernet sin pérdidas. Si ya tienes
  InfiniBand por el cómputo, NVMe-oF sobre él es natural. **SMB Direct** y **NFS over RDMA** (RPC
  sobre RDMA, **RFC 8166**) arrastran el mismo requisito: sin la red debajo hay incidentes, no
  ganancia.

## 4. Gates de calidad

- **Validación de la red antes que de la aplicación**: latencia y caudal con herramientas de nivel de
  tarjeta **entre todos los pares relevantes**, no entre dos vecinos. Un fabric probado sólo en un
  rack no está probado.
- **Gate de RoCE**: carga con observación simultánea de **PFC, ECN/CNP, reordenaciones y reintentos**
  en tarjeta y conmutador. **Cero pausas sostenidas** o el diseño no pasa. Y **coherencia de la clase
  sin pérdidas en todos los saltos** por diff automático: un conmutador distinto de sus pares es un
  hallazgo.
- **Prueba de fallo real**: caída de un enlace, de un conmutador y (en IB) **del SM primario**,
  midiendo reconfiguración e impacto en un trabajo en curso. La vuelta también.
- **Prueba de la colectiva real** a la escala objetivo, no sólo punto a punto: es donde aparecen la
  sobresuscripción y el incast. Con **GPUDirect RDMA verificado activo** y el camino elegido por la
  biblioteca de colectivas comprobado, y con **firmware, driver y NOS homogéneos** en toda la flota
  (la mezcla de versiones en RDMA produce fallos que parecen de red).

## 5. Seguridad

- **RDMA no autentica ni cifra por defecto** y el camino de datos **evita el núcleo**: los controles
  de host (firewall local, inspección) **no ven ese tráfico**, y quien pueda inyectar en el fabric
  puede leer y escribir memoria remota registrada. Consecuencia: **el fabric es un dominio de
  confianza físico y acotado**, protegido por **aislamiento** (P_Key en IB, VLAN/VRF y filtrado en el
  borde de la Ethernet de RoCE), no por reglas en el camino de datos (la política de zonas es de
  `firewall-policy-standards`).
- **No enrutes RoCE fuera de su dominio** ni lo lleves por enlaces compartidos con tráfico general
  sin decidirlo: rompe la garantía sin pérdidas y amplía la superficie.
- **Plano de gestión OOB** para conmutadores del fabric y para el SM, con AAA y sin credenciales de
  fábrica: un SM comprometido reprograma el reenvío de todo el clúster. Si el dato exige
  confidencialidad y el recinto no es de confianza, cifrado **de enlace o de aplicación**
  (`cryptography-pki-standards`), no suponer que "va por otra red".

## 6. Rendimiento y diagnóstico

- **Aquí el síntoma no es pérdida de paquetes: es colapso de rendimiento.** El trabajo tarda el
  triple, la colectiva se ralentiza, y `ping` responde perfectamente. Buscar "paquetes perdidos" es
  la vía muerta clásica del dominio.
- **Contadores que se vigilan siempre**, en tarjeta y conmutador: errores de símbolo y de enlace,
  enlaces caídos y renegociados, tasa de error de bit y estado de la óptica, **tramas de pausa PFC**,
  **paquetes con ECN y CNP**, paquetes fuera de secuencia, reintentos y `retry exceeded`, y
  compleciones con error. El **contador que sube donde no debería** es el diagnóstico, no la captura.
- **Un solo enlace degradado envenena el clúster**: con colectivas, un puerto con errores de símbolo
  baja el rendimiento global sin caerse nunca; el barrido periódico de contadores y calidad de enlace
  es rutina, no reacción a incidente.
- **Ubicación importa**: la afinidad NUMA y PCIe entre tarjeta, GPU y proceso cambia el resultado más
  que cualquier ajuste del conmutador. Y se mide con la carga real —la colectiva objetivo—, no con
  sintéticos punto a punto (metodología en `performance-engineering-standards`).

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: firmware, driver y NOS por trimestre y ante CVE explotable, **como conjunto probado**
  (tarjeta + driver + NOS + biblioteca), no pieza a pieza. En RDMA las combinaciones no soportadas
  dan rendimiento raro, no error claro.
- **Generaciones**: el fabric se sustituye por generaciones completas y las tasas se duplican cada
  pocos años cambiando óptica, conector y presupuesto de potencia; mezclarlas funciona por
  negociación a la baja, así que **planifícalo, no lo descubras**. Particiones, nodos y clases
  retirados desaparecen de configuración y documentación.

**PROHIBIDO**
- ❌ Desplegar **RoCE sin control de congestión extremo a extremo configurado y validado** (tarjeta
  **y** red), con prueba de carga y contadores observados. Sin eso, no entra en producción.
- ❌ Elegir RDMA sin un requisito de rendimiento **medido** que TCP no cumpla, o RoCE sin equipo capaz
  de operar y diagnosticar una Ethernet sin pérdidas.
- ❌ Habilitar PFC en más de una clase, o con mapeo de prioridad/DSCP distinto en algún salto.
- ❌ Operar sin monitorizar contadores de pausa, ECN/CNP y errores de enlace.
- ❌ InfiniBand con un único gestor de subred, o con su configuración fuera de control de versiones.
- ❌ Dejar todo el fabric InfiniBand en la partición por defecto y llamarlo segmentación.
- ❌ Tratar el fabric como zona de confianza extensible, o enrutar RoCE fuera de su dominio.
- ❌ Gestionar los conmutadores del fabric a través del propio fabric.
- ❌ Importar a la red de cómputo la sobresuscripción de una malla de cómputo general.
- ❌ Suponer que GPUDirect RDMA está activo sin haberlo verificado.
- ❌ Firmware, driver y NOS heterogéneos en la flota del fabric.
- ❌ Diagnosticar buscando pérdida de paquetes cuando el síntoma es colapso de rendimiento.
- ❌ Poner NVMe-oF/RoCE donde NVMe/TCP cumple, o diseñar sobre Ultra Ethernet sin verificar
  disponibilidad real de hardware.

## 8. Verificación web obligatoria

**Metodología**: los RFC, **uno a uno** contra el JSON de `rfc-editor.org`; el estado de los
ecosistemas, contra fuentes primarias (IBTA, UEC, NVM Express).

**RFC verificados ago-2026**: **iWARP — RDMAP = RFC 5040** (oct-2007, Proposed Standard, actualizado
por 7146) y **MPA = RFC 5044** (oct-2007, actualizado por 6581 y 7146); **NFS/RPC sobre RDMA v1 =
RFC 8166** (jun-2017, **obsoleta RFC 5666** — citar 5666 hoy es un error de hecho). La red sin
pérdidas y sus referencias IEEE/ECN están verificadas en `datacenter-fabric-standards`: **no las
dupliques ni las recuerdes desde aquí**.

**Estado verificado ago-2026**: **IBTA** publicó las especificaciones iniciales de **XDR** en
oct-2023 (Vol. 1 rel. 1.7), con **XDR = 800 Gb/s por puerto** sobre 200 Gb/s por carril, y hoja de
ruta hacia **GDR (1600G)** y **LDR (3200G)**; la escalera vigente es EDR 100G → HDR 200G → NDR 400G →
XDR 800G. **Ultra Ethernet Consortium publicó la especificación 1.0 el 11-jun-2025**, con transporte
RDMA propio, reparto por múltiples caminos y reordenación en el extremo. **NVM Express publicó el
conjunto 2.4 el 4-ago-2026**, con **NVMe over RDMA Transport 1.3** y **NVMe over TCP Transport 1.3**.
**iWARP está en declive de adopción** según las fuentes consultadas.

**Discrepancia declarada**: sobre la posición de mercado de InfiniBand frente a Ethernet las fuentes
no coinciden — unos sostienen que el Ethernet especializado del propio fabricante de InfiniBand ya
envía más volumen que su InfiniBand, y otros presentan InfiniBand como estándar de facto del
entrenamiento. **Es análisis de mercado, no dato técnico**: no lo uses como argumento de diseño.

**Huecos declarados — NO rellenar de memoria**:
1. **Tasas efectivas y latencias por generación** (más allá de la nominal por puerto) y
   **disponibilidad real de hardware XDR/GDR**: no verificadas.
2. **Soporte de iWARP por fabricante y modelo** y **disponibilidad e interoperabilidad de hardware
   conforme a UEC 1.0**: **no verificados**, y son lo que decide si cada uno es opción hoy.
3. **Versiones, mantenimiento y licencia en crudo** de `rdma-core`, **UCX** (sólo se leyó su cabecera
   de copyright, no el clausulado), Open MPI, MPICH, NCCL/RCCL y `opensm`: **no verificadas**.
4. **Parámetros de DCQCN, umbrales ECN y *headroom* de PFC**, y **números de sobresuscripción por
   tipo de carga**: criterio de fabricante y de ingeniería, no medidas (en
   `datacenter-fabric-standards` también constan como no verificados).
5. **Cifras de latencia de NVMe/TCP frente a NVMe/RoCE**: las fuentes dan rangos, no medidas
   reproducibles. Mide en tu hardware antes de justificar RDMA con ellas.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
