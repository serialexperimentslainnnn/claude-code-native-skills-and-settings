---
name: network-troubleshooting-standards
description: Reactive network fault diagnosis method — bisecting the path, forming a falsifiable hypothesis and proving root cause. Use when something "doesn't connect", is intermittent, slow or hangs mid-transfer and you are reaching for ping, traceroute, mtr --report, ss -tin, ip route get, ip neigh, arping, ethtool -S, tshark or dumpcap, capturing pcap simultaneously at both endpoints, curl -v --resolve, openssl s_client, nc -zv, socat, iperf3 -R with -P and -u, /proc/net/nf_conntrack and ephemeral port exhaustion, PMTU blackhole with ICMP fragmentation-needed filtered, TIME_WAIT and listen-backlog overflow, keepalive versus middlebox idle timeout, IP address conflict or MAC flapping, broadcast storms and layer-2 loops, ARP/ND caches, IPv6 preferred over working IPv4 and Happy Eyeballs, TLS-inspecting proxies, tail-latency percentiles versus averages, bpftrace, bcc tools, pwru, hubble observe, kubectl debug --image=nicolaka/netshoot across pod and node netns, or VPC flow logs — and when you must record what was tried, what it proved and why the fix was the fix.
---

# Estándares de diagnóstico de red — el método, no los comandos

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando **algo ya no funciona y hay que averiguar por qué**: método por capas y por
bisección, formulación de hipótesis falsables, secuencia canónica de comprobación
(resolución → ida → vuelta → aceptación por la aplicación), elección de herramienta por pregunta y
**qué mentira cuenta cada una**, catálogo de sospechosos habituales con su síntoma característico,
medición honesta de latencia/pérdida/jitter, diagnóstico en contenedores, Kubernetes, nubes y
overlays, y la disciplina de registro y cierre con **causa raíz demostrada**.

Triggers: "no conecta", "va lento", "intermitente", "se cae cada X minutos", "funciona desde aquí
pero no desde allí", "se cuelga al transferir", "conecta pero no carga", `ping`, `traceroute`,
`mtr --report`, `ss -tin`/`ss -s`, `ip route get`, `ip neigh`, `ip -s link`, `arping`,
`ethtool -S`/`ethtool -a`, `tshark`, `dumpcap`, `.pcap`, `curl -v --resolve`, `openssl s_client`,
`nc -zv`, `socat`, `iperf3 -R -P -u`, `/proc/net/nf_conntrack`, `/proc/net/sockstat`,
`net.ipv4.ip_local_port_range`, `somaxconn`, `TIME_WAIT`, `bpftrace`, `pwru`, `hubble observe`,
`kubectl debug`, `nicolaka/netshoot`, `tcp_retries2`, "flow logs".

**Principio rector** (hereda el de `networking-standards`: *la red es default-deny y documentada
como código; lo que no está en el SoT no existe*): **el diagnóstico termina en una causa raíz
demostrada, no en "se arregló solo"**. Cada paso responde a una hipótesis falsable escrita antes de
teclear, cambia **una** variable, y deja evidencia guardada. Un problema que desaparece sin
explicación no está resuelto: está esperando.

**No aplica**: ver `networking-standards` (**madre**: el **diseño** —topología, direccionamiento,
VLAN, routing/BGP, valores correctos de MTU/MSS, proxies, overlays, plano OOB—; **ella dice cómo
debería ser la red, tú averiguas por qué hoy no lo es**; la corrección estructural vuelve a ella),
`observability-standards` (**la telemetría permanente y sus alertas**: métricas, logs, trazas,
dashboards, SLI/SLO, muestreo, retención y el diseño de qué se instrumenta **antes** de que haya un
problema — **es suya toda la vigilancia continua; tú eres el diagnóstico reactivo cuando la alerta
ya saltó**. La línea exacta: si la pregunta es "¿qué se mide y con qué umbral se avisa?", es suya;
si es "esto está roto ahora, ¿por qué?", es tuya. Y la evidencia que tú necesitas y no existe es un
hallazgo **para** ella: todo diagnóstico a ciegas termina en un requisito de instrumentación),
`incident-management-standards` (**el proceso del incidente declarado**: severidad, Incident
Commander, canal, comunicación, mitigar-antes-de-diagnosticar, postmortem — **el mando y la
comunicación son suyos; el diagnóstico técnico dentro del incidente es tuyo**. Cuando el IC pide
mitigar ya, mitigas y **anotas** lo que sacrificas en evidencia),
`firewall-policy-standards` (**la política**: cuando el diagnóstico concluye "falta una regla" o
"sobra una regla", el arreglo, su aprobación y su prueba negativa son suyos; **la demostración de
que el paquete muere en el filtro es tuya**),
`dns-standards` (**el servicio de nombres y sus datos**: zona, TTL, DNSSEC, resolver legítimo,
delegación; **tú demuestras que la resolución es la causa y qué responde quién**, ellos deciden
cuál es la respuesta correcta), `vpn-standards` (**el túnel**: diseño, claves, MTU y keepalive
correctos, redundancia del concentrador; **"la VPN conecta pero no navego" es tuyo** —es
PMTU y se prueba con captura en ambos extremos—, igual que "se cae a los 5 minutos" y "resuelve
mal dentro del túnel"), `linux-administration-standards` (`resolvectl`, `systemd-resolved`,
`nsswitch.conf`, unidades systemd y la resolución **desde el host**; `dmesg` y el arranque),
`linux-storage-standards` (cuando "la red va lenta" resulta ser I/O: `iostat`, `fio`),
`kubernetes-standards` (CNI, `NetworkPolicy`, `Service`/`Ingress`, service mesh: su **diseño**),
`container-runtime-security-standards` (aislamiento del contenedor y privilegios del agente eBPF —
un pod de depuración privilegiado es una decisión de seguridad, no un atajo),
`detection-engineering-standards` (analítica sobre la telemetría de red; **una captura de tráfico
hecha para investigar un compromiso, no una avería, es de ellos y de**
`incident-response-forensics-standards` —cadena de custodia y preservación—),
`sre-practice-standards` (SLO, error budget, gestión del *toil* del diagnóstico repetido),
`aws-standards`/`azure-standards`/`gcp-standards` (flow logs, Reachability Analyzer/Network Watcher
y equivalentes: la herramienta del proveedor y su configuración),
`data-platform-standards` (latencia que resulta ser del motor de base de datos, no de la red),
`microservices-architecture-standards` (timeouts, reintentos y circuit breakers como **diseño** de
la aplicación; aquí sólo se demuestra que el fallo viene de ahí),
`appsec-standards` (fallo que resulta ser de la aplicación), `onprem-standards` (paraguas),
`homelab-standards` (laboratorio propio), `offensive-security-standards` (**escanear una red que no
es tuya, o el barrido activo sin autorización, no es diagnóstico**), y las tres skills de diseño y
operación proactiva a las que **vuelve la causa una vez encontrada**: si la avería
se explica por el diseño de campus o por una política BGP, la corrección estructural es de
`routing-switching-standards`; si aparece MTU de encapsulación, ECMP asimétrico o EVPN, es de
`datacenter-fabric-standards`; y **si la respuesta a "¿qué cambió?" es un despliegue de
configuración, la reversión y el gate que debió impedirlo son de `network-automation-standards`**.
Aquí termina el trabajo cuando la causa está probada; el arreglo permanente vive allí.

También existen y son frontera: `ha-clustering-standards` (*split brain*, fencing y la red de
clúster: **el comportamiento esperado del clúster ante partición es suyo; demostrar que hubo
partición de red y por qué, es tuyo**) y `podman-systemd-containers-standards` (redes rootless con
`netavark`/`pasta` y su resolución: su **configuración** es suya, el diagnóstico del paquete que se
pierde entre namespaces es de aquí).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión y el estado de mantenimiento por web antes de fijar nada (§8).
> Fechas obtenidas de `api.github.com` y del sitio del proyecto, no de páginas HTML resumidas.

| Pregunta que respondes | Herramienta por defecto | Alternativa | Vetado |
|---|---|---|---|
| ¿Qué hay configurado en esta máquina? | `ip addr`/`ip link`/`ip route`/`ip neigh`/`ip -s link` (**iproute2**) | `nmcli`/`networkctl` según el gestor | `ifconfig`, `route`, `arp`, `netstat` (**net-tools**: sin release desde 2001, sin mantenimiento; **ocultan** namespaces, políticas de enrutado, múltiples tablas y estado moderno de sockets) |
| ¿Qué ruta usaría **este** paquete? | `ip route get <dst> from <src>` | `ip rule show` para policy routing | Leer la tabla principal y suponer |
| ¿Qué sockets y en qué estado? | `ss -tanp`, `ss -tin` (RTT, cwnd, retransmisiones), `ss -s` | `/proc/net/sockstat` | `netstat -an` |
| ¿Llega el paquete y vuelve? | **`tshark`/`dumpcap` capturando en AMBOS extremos a la vez** | Captura en cada salto intermedio si el camino tiene varios | Capturar sólo en un extremo y deducir |
| ¿Análisis de la captura? | **Wireshark 4.6.x** (GUI) para analizar; `tshark` para filtrar y automatizar | `capinfos`, `editcap`, `mergecap` | Analizar 2 GB de pcap a ojo en vez de filtrar |
| ¿Dónde se pierde y cuánto? | `mtr --report --report-cycles 100 -w` (**v0.96**; repo con actividad jun-2026) | `traceroute -T -p 443` cuando ICMP/UDP está filtrado | `ping` como única medida de calidad |
| ¿Capa 1-2 sana? | `ethtool <if>` (negociación), `ethtool -S` (contadores de error/descarte), `ethtool -a` (pausa) | `ip -s link` para errores agregados | Diagnosticar capa 3 sin haber mirado errores de interfaz |
| ¿Estado del filtrado y del NAT? | `nft list ruleset` con `counter`; `/proc/net/nf_conntrack` y `nf_conntrack_count` vs `nf_conntrack_max` (**conntrack-tools 1.4.9**) | `nft monitor trace` para seguir un paquete por las cadenas | Suponer que "el firewall está abierto" porque alguien lo dijo |
| ¿La aplicación acepta? | `curl -v` con **`--resolve`** (aísla DNS de conectividad), `openssl s_client -connect -servername` | `nc -zv` para puerto crudo; `socat` para relés y pruebas de protocolo | `telnet host puerto` como prueba de TLS |
| ¿Cuánto ancho de banda hay de verdad? | **`iperf3 3.21`** (09-abr-2026) con `-P` (paralelo), `-R` (sentido inverso) y series largas | `iperf3 -u -b` para UDP con caudal fijado, midiendo pérdida y jitter | Medir 10 s en un sentido y llamarlo *baseline* |
| ¿Dónde muere el paquete **dentro** del kernel? | **`pwru` v1.0.12** (13-jul-2026, kernel ≥5.3; `--output-skb` ≥5.9) | `bpftrace 0.26.1` (02-jun-2026) y herramientas de `bcc 0.37.0` (02-jul-2026) para casos a medida | Adivinar entre `nftables`, routing y el driver |
| ¿Y en Kubernetes? | `hubble observe --verdict DROPPED` (Cilium **1.20.0**, 29-jul-2026); `kubectl debug --image=nicolaka/netshoot` con `--target` | `kubectl debug node/<n>` para el netns del nodo; Retina donde el CNI no sea Cilium | `kubectl exec` a un contenedor *distroless* y rendirse |
| ¿Y en la nube? | **Flow logs** del proveedor + su analizador de alcanzabilidad | Captura en la instancia si el proveedor no la ofrece gestionada | Concluir "es la nube" sin mirar los flow logs |

**Sobre eBPF (`pwru`, `bpftrace`, `bcc`, Hubble): recomendables, pero no como primer paso.**
Son la respuesta a "el paquete entra en la máquina y no sale, y ninguna herramienta clásica me dice
dónde" — un problema real y frecuente en hosts con contenedores, y donde la captura clásica no
alcanza porque el descarte ocurre entre puntos de captura. Requisitos y coste que hay que aceptar
antes: kernel moderno con **BTF** y `CONFIG_KPROBES`/`CONFIG_BPF`, privilegios altos en el host
(decisión de seguridad, ver `container-runtime-security-standards`), y sobrecarga no nula en
producción. **Criterio**: capa 1-2, `ss`, captura en ambos extremos y contadores de firewall
primero; eBPF cuando esos cuatro no cierran el caso.

## 3. El método

### 3.1 Antes de teclear nada: cuatro preguntas

1. **¿Qué cambió?** — La causa es el último cambio hasta que se demuestre lo contrario. El
   diagnóstico **empieza en el control de cambios**: despliegues, cambios de firewall o de routing,
   parcheo, renovación de certificado, cambio de proveedor, actualización de firmware, expiración de
   algo. Si nadie sabe qué cambió, ese es el primer hallazgo (y un problema de gobierno, no de red).
2. **¿Qué es exactamente "no funciona"?** — Reproduce el síntoma con precisión: qué origen, qué
   destino, qué puerto, qué protocolo, qué cliente, a qué hora, con qué mensaje de error literal.
   "La red va mal" no es un síntoma; "desde el host A, `curl` a B:443 se queda colgado tras el
   handshake TLS, en el 30% de los intentos, desde las 09:14" sí lo es.
3. **¿Cuál es el alcance?** — ¿Un usuario o todos? ¿Un destino o todos? ¿Un protocolo o todos?
   ¿Una VLAN, un nodo, una zona de disponibilidad? El alcance **descarta más hipótesis en 30
   segundos que una hora de capturas**: un fallo que afecta a un solo cliente no está en el
   servidor, y uno que afecta a todos los destinos no está en el destino.
4. **¿Funcionó alguna vez?** — "Nunca funcionó" es un problema de **configuración o de diseño**;
   "funcionaba y dejó de funcionar" es un problema de **cambio o de agotamiento de un recurso**. Son
   dos investigaciones distintas y confundirlas cuesta horas.

### 3.2 Bisección: dividir el camino, no recorrerlo

- **No se recorre el camino salto a salto.** Se **parte por la mitad**: elige un punto intermedio
  con visibilidad (un router, un balanceador, un nodo) y determina si el problema está antes o
  después. Repite. Con 8 saltos, la bisección son 3 pruebas; el recorrido lineal, 8 — y con más
  ocasiones de equivocarse.
- **La bisección también se aplica a las dimensiones no espaciales**: dos clientes (uno que falla,
  uno que no) → ¿qué difiere?; dos destinos; dos protocolos; dos momentos; IPv4 vs. IPv6. El corte
  es por *variable*, no sólo por *lugar*.
- **Una variable cada vez.** Cambiar dos cosas y que funcione no es un diagnóstico: es una
  coincidencia con la que tendrás que volver a lidiar. Si la presión obliga a cambiar varias a la
  vez para mitigar, se **anota** y se revierte una a una después para identificar cuál era.
- **Hipótesis falsable antes de teclear**: escribe "si la causa es X, entonces al hacer Y veré Z;
  si veo W, X queda descartado". Una prueba que no puede refutar tu hipótesis no es una prueba, es
  una ceremonia. Esto es lo que separa el diagnóstico de "lanzar comandos".
- **El sesgo de confirmación es el enemigo principal**: en cuanto tienes un sospechoso, todas las
  pruebas parecen confirmarlo. Antídoto: define de antemano **qué resultado te haría abandonar** esa
  hipótesis, y bísala explícitamente.

### 3.3 La secuencia canónica

Cuatro preguntas, en orden. Cada una tiene una respuesta binaria y elimina medio universo.

**1) ¿Resuelve el nombre — y a lo correcto?**
- Aísla el DNS del resto **desde el primer minuto**: `curl -v --resolve host:443:<ip>` compara
  directamente "no resuelve" contra "no conecta". Si con `--resolve` funciona, el problema es de
  resolución y no de red.
- Pregunta a **cada** resolvedor por separado y compáralos, y **compáralo con lo que usa realmente
  el proceso**: el sistema puede tener un stub local, un caché, un `search` que completa el nombre,
  un `/etc/hosts` olvidado o una biblioteca que ni siquiera pasa por el resolvedor del SO. La
  resolución "desde el shell" y "desde la aplicación" **no son la misma**.
- Caché negativa y TTL explican el clásico "a mí me funciona y a ti no" y "tardó una hora en
  arreglarse solo". El diseño de zona, TTL y resolvedores, en `dns-standards`.

**2) ¿Llega el paquete al destino?**
- Captura **en el destino**, filtrando por origen y puerto. Si no aparece, el paquete muere en el
  camino: firewall, ruta, NAT, VLAN, capa 1-2.
- Comprueba en el origen que **sale** y por qué interfaz: `ip route get <dst> from <src>` responde
  la pregunta real (incluye policy routing y tabla efectiva), no la tabla principal.
- Si sale y no llega, bisecciona el camino y revisa los contadores de las reglas de filtrado en cada
  salto: un `counter` que sube en la regla de descarte es una prueba, no una sospecha.

**3) ¿Vuelve la respuesta? — la mitad olvidada del problema**
- **La respuesta se pierde tanto como la ida, y casi nadie la mira.** Si en el destino ves el `SYN`
  y sale el `SYN/ACK`, pero el origen no lo recibe, el problema es del **camino de vuelta** y todo
  lo que estabas mirando era irrelevante.
- Causas típicas del fallo asimétrico: el retorno toma un camino distinto (multihoming, rutas
  específicas, VPN parcial, VRF); un firewall stateful que sólo ve un sentido y descarta el otro
  por falta de estado —**síntoma inconfundible: funciona un rato y se corta, o falla de forma
  intermitente y no reproducible**—; NAT en un sentido y no en el otro; uRPF descartando por
  camino inverso inválido.
- **Regla operativa**: en todo caso difícil, captura simultánea en ambos extremos **con reloj
  sincronizado**, y compara. Esto resuelve el 90% de lo que parece imposible: te dice en qué mitad
  del camino desaparece el paquete y con eso la investigación se reduce a la mitad de la red. Si
  además el camino tiene un intermediario (proxy, balanceador, NAT), captura en sus dos lados.
- La corrección de la asimetría es de diseño (`networking-standards`) o de política
  (`firewall-policy-standards`): **nunca** se arregla añadiendo un `accept` amplio.

**4) ¿Lo acepta la aplicación?**
- El paquete llega, el `SYN/ACK` vuelve, y el fallo sigue: mira si el proceso **escucha** (`ss
  -tanp`), en qué dirección (`0.0.0.0` vs `127.0.0.1` vs `::` — un servicio en loopback es
  inalcanzable desde fuera y parece un firewall), y si la cola de aceptación está llena
  (`ss -lt` muestra `Send-Q` como backlog y `Recv-Q` como pendientes: si se satura, el kernel
  descarta `SYN` y el cliente ve *timeouts* con el servidor "vivo").
- Fallos que **parecen** de red y son de la aplicación o de su borde: `RST` inmediato (nadie escucha
  o el proxy rechaza), handshake TLS que falla por SNI, certificado, versión o cadena
  (`openssl s_client -servername`), redirecciones, autenticación, o *timeouts* propios de la
  aplicación más cortos que su reintento.
- **`RST` vs. *timeout* es la distinción más informativa del oficio**: `RST` = algo respondió y
  rechazó (host vivo, puerto cerrado, proxy o firewall que **rechaza**); silencio = algo descartó
  (firewall que **descarta**, ruta ausente, host caído). No son el mismo problema y no se
  diagnostican igual.

### 3.4 Qué mentira cuenta cada herramienta

Ninguna herramienta miente por malicia: todas responden una pregunta más estrecha de la que crees
estar haciendo.

- **`ping` / ICMP** — mide *que el destino responde a ICMP*, no que el servicio funcione. ICMP suele
  ir **despriorizado** en el plano de control de routers y switches, o filtrado por política. Un
  `ping` con 200 ms y pérdida hacia el equipo de red puede ser perfectamente normal mientras el
  tráfico de datos va impecable; y un `ping` perfecto no dice nada del puerto 443. **Nunca uses
  `ping` como única medida de calidad ni como prueba de servicio.**
- **`traceroute`/`mtr`** — la mentira más extendida del oficio: **la pérdida en saltos intermedios
  no significa nada**. Los routers generan las respuestas `TTL exceeded` en su CPU y las limitan por
  tasa; ver 40% de pérdida en el salto 5 y 0% en el destino significa **que ese router prioriza su
  trabajo, no que haya un problema**. Sólo cuenta: (a) la pérdida en el **último salto** (el
  destino), y (b) la pérdida que **persiste** desde un salto hasta el final. Además, ECMP hace que
  cada sonda tome un camino distinto (usa modo con flujo fijo si tu herramienta lo soporta), el
  camino de vuelta es invisible, y MPLS puede ocultar saltos por completo. Cuando ICMP/UDP está
  filtrado, `traceroute -T` sobre el puerto real de la aplicación es lo que refleja el camino que
  importa.
- **`ss`** — dice el estado **local** del socket. `ESTABLISHED` en un extremo no implica que el otro
  siga ahí: una conexión cuyo peer desapareció sin `FIN` sigue apareciendo establecida hasta que un
  keepalive o una escritura lo descubra. `ss -tin` sí da oro: RTT, `cwnd`, retransmisiones — que
  distinguen "la red pierde" de "la aplicación es lenta".
- **`tcpdump`/`tshark`** — captura donde tú estás y **después** de que el kernel haya decidido
  algunas cosas y **antes** de otras: un paquete descartado por el filtro puede aparecer o no en la
  captura según el punto de enganche, y el offload (GRO/GSO/TSO/LRO) muestra "paquetes" gigantes que
  no existen en el cable (desactívalo si vas a analizar tamaños o MTU). Con muestreo o con filtro
  mal escrito, tu "no aparece" puede ser tuyo, no de la red. Y la captura sin filtro en un enlace
  cargado se pierde a sí misma: usa filtro de captura (BPF) para lo que quieres, y filtro de
  visualización para analizar.
- **`ip route`** — muestra tablas; **`ip route get`** muestra la decisión. Con reglas de política,
  VRF o varias tablas, leer la principal y suponer es un error clásico.
- **`ip neigh`/ARP** — una entrada `STALE` o `FAILED` te dice más que una `REACHABLE`; y una entrada
  correcta con la **MAC equivocada** (duplicado de IP, proxy ARP inesperado) es un fallo silencioso
  que ninguna prueba de capa 3 delata. `arping` desde el mismo segmento revela **duplicados de IP**
  (dos respuestas, dos MAC) en un segundo, que es lo que ninguna otra herramienta hace.
- **`ethtool`** — la única que ve capa 1-2: negociación (dúplex/velocidad; un *half duplex*
  negociado mal se manifiesta como "lento e intermitente" bajo carga), errores CRC, descartes por
  falta de buffer, y contadores por cola. **Contadores acumulativos**: lo que importa es el
  **delta** durante el fallo, no el total desde el arranque.
- **`iperf3`** — mide lo que le pidas, y por defecto no es lo que crees. Errores clásicos: medir
  10 s (todo *slow start*), un solo flujo (limitado por RTT y ventana, no por el enlace), sólo en
  un sentido (`-R` mide el otro, que puede ser el roto), en UDP sin fijar caudal (`-b`) o fijándolo
  por encima de la capacidad y llamando "pérdida de red" a tu propia saturación, con el propio
  `iperf3` como cuello de botella por CPU, o midiendo contra un servidor público compartido.
  **`iperf3` mide un camino entre dos puntos en un instante; no mide "la red".**
- **`curl -v`** — sin `--resolve` mezcla DNS, conexión, TLS y HTTP en un solo resultado; con
  `--resolve` separa el primero. Sus tiempos por fase (`-w`) son un diagnóstico por sí solos: si el
  tiempo se va en el `connect`, es red; si en el `appconnect`, es TLS; si en el `starttransfer`, es
  la aplicación.
- **Los logs de la aplicación** — dicen "connection timeout" para media docena de causas
  incompatibles entre sí. Útiles para la hora exacta y el alcance; inútiles como diagnóstico.

### 3.5 Los sospechosos habituales y su síntoma característico

Tabla de reconocimiento. El síntoma es lo que te hace sospechar; la prueba es lo que lo demuestra.

| Sospechoso | Síntoma característico | Prueba que lo demuestra |
|---|---|---|
| **MTU / PMTU black hole** | **La conexión abre y se cuelga al transferir**: SSH conecta pero `scp` se para; la web carga el HTML y no las imágenes; "la VPN conecta pero no navego". Típicamente tras un túnel o un cambio de encapsulación | `ping` con paquete grande y bit DF creciente hasta encontrar el corte; captura que muestra retransmisiones del mismo segmento grande sin ACK; ausencia de ICMP *fragmentation needed* de vuelta |
| **ICMP filtrado que rompe PMTUD** | Idéntico al anterior, y **no se arregla solo nunca** | El intermediario que bloquea ICMP tipo 3 código 4 (o ICMPv6 *packet-too-big*): se ve por ausencia en la captura del lado que debería recibirlo |
| **DNS** | Intermitencias que parecen de red; "a veces tarda 5 segundos exactos" (timeout de resolvedor); funciona por IP y no por nombre | `curl --resolve` frente a `curl` normal; consulta a cada resolvedor por separado |
| **Agotamiento de puertos efímeros / NAT** | Fallos que aumentan con la carga, en el lado que **inicia** muchas conexiones (proxy, NAT, cliente de API) | Conteo de sockets frente a `net.ipv4.ip_local_port_range`; en el NAT, sesiones activas frente a su capacidad |
| **Tabla de conntrack llena** | Descartes **silenciosos** bajo carga, con una línea en `dmesg` que nadie mira | `nf_conntrack_count` frente a `nf_conntrack_max`; `dmesg` con `table full` |
| **Camino de retorno distinto** | "Va bien un rato y luego se corta"; intermitente e irreproducible; funciona en un sentido | Captura simultánea en ambos extremos: se ve la ida y la respuesta que no llega |
| **`TIME_WAIT` / backlog agotado** | *Timeouts* de conexión con el servidor vivo y con CPU baja; empeora en picos | `ss -s` (recuento por estado), `ss -lt` con `Recv-Q` creciendo, contador de `SYN` descartados |
| **Keepalive vs. *idle timeout* de un intermediario** | **"La sesión se cae exactamente a los N minutos"** de inactividad. Firewall, NAT, balanceador o nube con timeout de inactividad más corto que el keepalive del cliente | Reproducir con una sesión ociosa y cronómetro; comparar el timeout del intermediario con el keepalive de TCP/aplicación. Se corrige bajando el keepalive, no subiendo el timeout de todo el mundo |
| **Duplicado de IP** | Intermitencia inexplicable que cambia con el tiempo de vida de la caché ARP; "a veces entra en un servidor distinto" | `arping` desde el segmento: dos respuestas con MAC distintas |
| **Duplicado de MAC / *MAC flapping*** | Pérdida masiva en un segmento; el switch registra el aprendizaje de la misma MAC en puertos distintos | Log del switch; tabla de direcciones |
| **Bucle de capa 2 / tormenta de broadcast** | Toda la VLAN cae o va a rastras; CPU de los switches al 100%; empieza justo tras conectar algo | Contadores de broadcast/multicast por puerto disparados; STP con cambios de topología constantes. Es una emergencia: se aísla el puerto primero |
| **ARP/ND envejecido o incompleto** | Un host inalcanzable desde su propio segmento mientras el resto va bien | `ip neigh` en estado `FAILED`/`INCOMPLETE` |
| **IPv6 activo que falla mientras IPv4 funciona** | "Va lento" con retrasos de segundos exactos al inicio; funciona con `-4`; falla sólo en algunos clientes | Comparar `curl -4` y `curl -6`; ruta y ND en IPv6. Causa habitual: `AAAA` publicado sin conectividad IPv6 real, o firewall IPv6 sin paridad con IPv4 |
| **Happy Eyeballs enmascarando el fallo** | El fallo de IPv6 **casi** no se nota (el cliente reintenta por IPv4 tras un retardo corto), así que nadie lo arregla y la latencia inicial es peor para todos | Captura que muestra el intento IPv6 abandonado. **RFC 8305** es la especificación vigente; la v3 sigue siendo **draft** (§8) |
| **Proxy o inspección TLS en medio** | Certificado inesperado, versión de TLS forzada, ALPN reescrito, HTTP/3 que no funciona, mTLS que falla, `Server` distinto del esperado | `openssl s_client -servername` y comparar el emisor del certificado con el esperado |
| **Balanceador con un backend malo** | Falla **una fracción constante** de las peticiones (1 de N) | Repetir la prueba N+ veces registrando a qué backend va cada una |
| **Certificado caducado o cadena incompleta** | Falla a una hora exacta, para todos a la vez, sin que nadie tocara nada | `openssl s_client` mostrando la cadena y las fechas |
| **Capa 1** | Errores CRC crecientes, lento sólo bajo carga, dúplex mal negociado, óptica degradada | `ethtool -S` (delta durante el fallo), `ethtool` (negociación), potencia óptica en el equipo |
| **Saturación / bufferbloat** | Latencia que se dispara **sólo cuando hay tráfico**; el `ping` sube de 10 ms a 300 ms al empezar una descarga | Latencia bajo carga frente a en reposo; utilización del enlace por percentiles |

### 3.6 Latencia, pérdida y jitter: medirlos de verdad

- **Percentiles, nunca medias.** La media esconde exactamente lo que rompe la experiencia. Mira
  p50, p95, p99 y **el máximo**; y compara con el reposo, no con un número absoluto. Un p50 de 20 ms
  con p99 de 2 s es un sistema roto que promedia bien.
- **Distingue las tres causas de "va lento"**, porque tienen arreglos opuestos:
  - **Latencia (RTT)**: limita el caudal de un flujo TCP por ventana. Si el RTT es alto, más ancho
    de banda no arregla nada; más flujos paralelos o una ventana mayor, sí.
  - **Pérdida**: hunde el caudal TCP de forma desproporcionada (una pérdida del 1% puede costar la
    mayor parte del rendimiento en un enlace de RTT alto). Se ve en retransmisiones (`ss -tin`),
    no en el `ping`.
  - **Jitter**: irrelevante para una descarga, letal para voz y vídeo. Se mide con UDP a caudal
    fijo, no con TCP.
- **La medición ha de reproducir el caso real**: mismo par origen-destino, mismo protocolo, mismo
  tamaño de transferencia, misma hora del día. Una prueba en reposo no reproduce un problema de
  saturación, y una prueba de 10 segundos no reproduce un problema de 20 minutos.
- **Si "va lento" resulta ser I/O, CPU o base de datos, dilo y cierra el caso ahí**: la red es
  culpada por defecto, y demostrar que **no** es la red es un resultado tan válido como cualquier
  otro (con evidencia, no con una negación).

### 3.7 Entornos modernos: contenedores, Kubernetes, nubes y overlays

- **El paquete cruza varios *network namespaces*.** Antes de capturar, decide **en cuál** estás
  capturando: dentro del contenedor, en el `veth` del lado del host, en el bridge, en el netns del
  nodo, en la interfaz física, en la interfaz del overlay. "No aparece en la captura" casi siempre
  significa "capturaste en el namespace equivocado".
- **Kubernetes: orden de comprobación por capas del propio clúster** — ¿resuelve el nombre del
  `Service`? → ¿tiene el `Service` `Endpoints`/`EndpointSlice` (un `Service` sin endpoints por
  selector mal escrito es el fallo más común y no parece de red)? → ¿hay `NetworkPolicy` que lo
  deniegue (el descarte ocurre en el datapath, **antes** de llegar al pod)? → ¿el `readinessProbe`
  saca al pod de rotación? → ¿el CNI o `kube-proxy` tienen la regla? → ¿el nodo enruta?
  `hubble observe --verdict DROPPED` da el veredicto y el motivo del descarte en un paso; ojo con la
  **agregación de monitorización**, que puede ocultarte eventos individuales.
- **Contenedores *distroless* y sin herramientas**: `kubectl debug` con contenedor efímero
  (**GA desde Kubernetes 1.25**) e imagen de diagnóstico (`nicolaka/netshoot`), compartiendo el
  namespace del pod, y `kubectl debug node/<nodo>` para el netns del nodo. Dos avisos operativos:
  un contenedor efímero **no se puede eliminar** hasta que se borre el pod y **no tiene límites de
  recursos**; y para sacar una captura, **transmítela por la salida estándar** en vez de escribir el
  fichero dentro (la copia desde un contenedor efímero no funciona).
- **Nubes**: los **flow logs** de la VPC/VNet son la primera parada —dicen si el paquete fue
  aceptado o rechazado y por qué regla— seguidos del analizador de alcanzabilidad del proveedor. Sus
  límites, que hay que conocer: agregación por ventanas (no ves el paquete, ves el flujo), posible
  muestreo, retardo de minutos, y ausencia de payload. La configuración concreta, en
  `aws-standards`/`azure-standards`/`gcp-standards`.
- **Overlays y túneles** (VXLAN, GENEVE, IPsec, WireGuard): captura **dentro** del túnel y
  **fuera** —son dos preguntas distintas: "¿el tráfico entra al túnel?" y "¿el túnel llega al otro
  lado?". Y en cuanto hay encapsulación, **MTU es el primer sospechoso, siempre**.
- **Service mesh / sidecar**: el proxy puede terminar TLS, reescribir cabeceras, aplicar sus
  propios timeouts y reintentos y devolver errores que parecen de la aplicación. Sus logs de acceso
  son la fuente, no la captura.

## 4. Calidad del diagnóstico (gates)

Un diagnóstico se da por bueno cuando cumple **todo** esto. No es burocracia: es lo que impide que
el mismo incidente vuelva dentro de tres semanas.

1. **Reproducibilidad**: existe un comando o procedimiento exacto que produce el síntoma a voluntad
   (o, si es intermitente, una condición documentada que lo dispara y una tasa medida). Sin
   reproducción, no se puede validar el arreglo.
2. **Hipótesis registradas con su resultado**: qué se probó, qué se esperaba, qué se vio y qué
   hipótesis quedó descartada. Un registro de descartes vale tanto como el hallazgo, y evita que el
   siguiente turno repita las mismas pruebas.
3. **Evidencia guardada, no descrita**: capturas (`.pcap`) de **ambos** extremos con marca temporal,
   salidas de comando completas, contadores antes/después, capturas de pantalla de gráficas con su
   rango temporal. "Vimos que se perdían paquetes" no es evidencia. Guarda la evidencia **antes** de
   mitigar: la mitigación destruye el estado que la prueba.
4. **Causa raíz demostrada, no inferida** — el gate central. "Demostrada" significa que puedes
   explicar el mecanismo completo desde el cambio o la condición hasta el síntoma, **y** que puedes
   reproducir el fallo activando la causa y hacerlo desaparecer desactivándola. Correlación temporal
   no es causa: "reiniciamos y se arregló" es un dato, no una conclusión.
5. **Arreglo validado por la prueba que fallaba**, y además con la prueba negativa
   correspondiente (lo que debía seguir bloqueado sigue bloqueado). Y validado desde el **origen
   real** afectado, no desde el bastión del ingeniero.
6. **Ausencia de efectos colaterales comprobada**: lo que se tocó no rompió nada más. Los cambios
   temporales de diagnóstico (reglas abiertas, offload desactivado, `tcpdump` corriendo, timeouts
   subidos, logs a debug) **se revierten explícitamente** y se verifica que se revirtieron.
7. **Hallazgos derivados con dueño**: la deriva de configuración, la regla que faltaba, la métrica
   que no existía, el runbook que no servía, la alerta que no saltó. Cada uno se abre como trabajo
   con dueño y fecha — hacia `observability-standards`, `firewall-policy-standards`,
   `networking-standards` o quien corresponda.
8. **Si el caso se cierra sin causa raíz** (pasa, y es legítimo), se cierra **diciéndolo**: qué se
   descartó, qué instrumentación falta para diagnosticarlo la próxima vez, y qué disparador se deja
   armado para capturar evidencia cuando vuelva. Eso es un resultado; "se arregló solo" no lo es.

## 5. Seguridad del diagnóstico

- **Una captura de tráfico contiene datos personales, credenciales y contenido de negocio.** No es
  un fichero técnico inocuo. Trátala como dato clasificado: almacenamiento controlado, acceso
  restringido, retención mínima y borrado al cerrar el caso. Si vas a compartirla, anonimízala o
  recorta a las cabeceras (`-s` para limitar la captura) y quita el payload. Base legal y
  minimización, en `privacy-engineering-standards`.
- **Capturar en producción es una acción con impacto**: consume CPU y disco y puede llenar un
  sistema de ficheros. Usa filtro de captura, límite de tamaño y rotación, y ponle límite temporal
  desde el principio. Un `tcpdump` olvidado en un servidor es un incidente futuro.
- **Distingue avería de compromiso desde el primer minuto.** Si hay cualquier indicio de intrusión,
  el objetivo deja de ser "restaurar el servicio" y pasa a ser "preservar la evidencia": cambia el
  procedimiento, no reinicies, no borres, y escala a
  `incident-response-forensics-standards` (orden de volatilidad y cadena de custodia).
- **Barrer puertos, escanear o inyectar tráfico en redes que no son tuyas —o sin autorización
  interna— no es diagnóstico**: es actividad ofensiva y se gobierna en
  `offensive-security-standards`. Dentro de tu red, avisa a quien vigila para que tu prueba no
  aparezca como un ataque.
- **Privilegios**: capturar requiere `CAP_NET_RAW`/`CAP_NET_ADMIN` y eBPF requiere más. Concédelos
  **temporalmente y con nombre**, no como configuración permanente ni con un contenedor privilegiado
  que se queda ahí (`container-runtime-security-standards`). Retíralos al cerrar el caso.
- **No debilites controles para diagnosticar y lo dejes así**: abrir una regla "para probar" es la
  vía más rápida a un `any/any` permanente (`firewall-policy-standards`). Si abres, abres con
  caducidad automática.

## 6. Operabilidad: prepararse antes de que falle

- **El diagnóstico se prepara, no se improvisa.** Lo que hay que tener **antes** del incidente:
  inventario y SoT actualizados (`networking-standards`), diagrama del camino real del tráfico,
  acceso OOB, telemetría con retención suficiente (`observability-standards`), flujos, y **líneas
  base**: RTT normal, caudal normal, tasa de error normal. **Sin línea base, "está alto" es una
  opinión.**
- **Reloj sincronizado en todo lo que loguea o captura** (NTP/chrony sano). Sin ello, correlacionar
  dos capturas o dos logs es imposible, y ese es justo el método que resuelve los casos difíciles.
- **Punto de observación disponible**: SPAN/mirror, TAP, o al menos un host con acceso al segmento y
  herramientas instaladas. Si el primer paso de tu diagnóstico es "instalar `tcpdump` en el servidor
  de producción", ya llegas tarde.
- **Kit mínimo preinstalado o con imagen de diagnóstico lista**: iproute2, captura, `mtr`, `curl`,
  `nc`/`socat`, `ethtool`, `iperf3`, y una imagen de contenedor de diagnóstico para entornos sin
  herramientas.
- **Runbooks por síntoma, no por herramienta**: "no resuelve", "conecta y se cuelga al transferir",
  "intermitente", "lento sólo bajo carga", "se cae cada N minutos", "falla 1 de cada N", "funciona
  desde un host y no desde otro". Cada uno con la secuencia canónica adaptada y su criterio de
  escalado.
- **Ventana de rescate abierta al tocar acceso remoto, rutas o firewall** — regla heredada y no
  negociable (`firewall-policy-standards`, `vpn-standards`): consola OOB, segundo camino, o
  reversión temporizada. El autobloqueo durante un diagnóstico es el incidente más previsible y más
  evitable que existe.
- **Cuando el diagnóstico ocurre dentro de un incidente declarado**: el mando y la comunicación son
  de `incident-management-standards`. Tú das **hipótesis con nivel de confianza y tiempo estimado**,
  no certezas prematuras; y si el IC decide mitigar antes de entender, mitigas — pero **capturas la
  evidencia primero** y dejas escrito el diagnóstico pendiente. Mitigar no cierra la causa raíz.
- **Toil**: el mismo diagnóstico repetido tres veces es un fallo de instrumentación o de diseño, no
  mala suerte. Se convierte en alerta, en comprobación automática o en corrección estructural
  (`sre-practice-standards`).

## 7. Sostenibilidad y prohibiciones

- **El postmortem alimenta el método**: cada caso difícil deja o un runbook nuevo, o una métrica
  nueva, o un cambio de diseño. Si no deja nada, se repetirá.
- **Migración de herramientas**: `net-tools` (`ifconfig`, `netstat`, `route`, `arp`) sin
  mantenimiento desde hace años y ausente por defecto en las distribuciones modernas; scripts y
  runbooks que aún lo usan se migran a **iproute2** con fecha. No es purismo: **oculta** namespaces,
  policy routing y estado que hoy determina el diagnóstico.
- **Cadencia**: revisar versión y CVE de las herramientas de captura y análisis (Wireshark/`tshark`,
  `libpcap`/`tcpdump`) con la del resto del stack — **son parsers que procesan entrada hostil por
  definición**, y 2026 trae un aluvión de hallazgos asistidos por LLM en esa familia. Analizar una
  captura no confiable con un Wireshark sin parchear es exponerte tú.
- **Formación con casos reales**: guardar capturas y cronologías de los casos resueltos como
  material de entrenamiento del equipo vale más que cualquier curso.

**PROHIBIDO**
- ❌ **Reiniciar como primer paso.** Destruye el estado que necesitas (sockets, conntrack,
  contadores, caché ARP, logs en memoria) y convierte el problema en irreproducible. Es lo último,
  y con la evidencia ya recogida.
- ❌ Cambiar **varias cosas a la vez** y declarar victoria cuando funciona.
- ❌ Tocar producción a ciegas: cambios de diagnóstico sin hipótesis, sin registro y sin plan de
  reversión.
- ❌ **Culpar a la red sin evidencia** — y también absolverla sin evidencia. Ambas cosas son la misma
  falta.
- ❌ **Capturar sólo en un extremo** en un caso difícil, o capturar sin sincronización de reloj.
- ❌ Concluir a partir de la pérdida en **saltos intermedios** de `traceroute`/`mtr`.
- ❌ Usar `ping` como prueba de que un servicio funciona, o como única medida de calidad.
- ❌ `ifconfig`, `netstat`, `route`, `arp` (`net-tools`) en diagnóstico o en runbooks nuevos.
- ❌ Leer `ip route` y suponer, en vez de preguntar con `ip route get`.
- ❌ Medir con `iperf3` durante 10 s, un solo flujo, un solo sentido, y llamarlo *baseline*.
- ❌ Reportar medias de latencia en lugar de percentiles.
- ❌ Analizar tamaños de paquete o MTU sin desactivar el offload de la interfaz.
- ❌ Diagnosticar capa 3 sin haber mirado errores y negociación de capa 1-2.
- ❌ Cerrar el caso con "se arregló solo", "era cosa de la red" o "reiniciamos y ya va".
- ❌ Dejar puestos los cambios temporales del diagnóstico (reglas abiertas, capturas corriendo,
  offload desactivado, logs en debug, privilegios elevados, pod de depuración privilegiado).
- ❌ Abrir una regla de firewall "para probar" sin caducidad automática.
- ❌ Guardar capturas con datos personales o credenciales fuera de un almacenamiento controlado, o
  compartirlas sin recortar.
- ❌ Tratar un posible compromiso como una avería: destruir evidencia por restaurar el servicio.
- ❌ Escanear o inyectar tráfico en redes ajenas, o sin autorización interna, en nombre del
  diagnóstico.
- ❌ Cambiar rutas, reglas o acceso remoto **por el propio camino que estás tocando** sin ventana de
  rescate.
- ❌ Empezar por eBPF (o por Wireshark) antes de haber mirado interfaz, sockets, rutas y contadores.
- ❌ Repetir el mismo diagnóstico manual una y otra vez sin convertirlo en instrumentación.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, comportamiento o límite, **búscalo — no lo recuerdes**.
**Metodología**: las versiones y fechas de este documento proceden de `api.github.com/repos/…` y del
sitio del proyecto, **no** del resumen de una página HTML de releases (que inventa años).

Verificado ago-2026:

- **Captura y análisis**: `tcpdump` **4.99.6** y `libpcap` **1.10.6** (ambos 30-dic-2025; libpcap
  1.10.6 corrige CVE-2025-11961 y CVE-2025-11964, lectura y escritura fuera de límites en
  `pcap_ether_aton()`); trabajo en curso hacia tcpdump 5.0 y libpcap 1.11. **Wireshark** rama
  estable **4.6.x** (4.6.7 y 4.4.17 publicadas en 2026, con múltiples vulnerabilidades corregidas,
  atribuidas por el proyecto al aumento de reportes asistidos por IA); soporte mínimo de 18 meses
  por release; **4.6 es la última con soporte de Windows 10, RHEL 8 y Qt 5**.
- **Medición**: **iperf3 3.21** (09-abr-2026; anteriores 3.20 el 14-nov-2025 y 3.19.1 el
  25-jul-2025). **mtr**: última etiqueta **v0.96**, repositorio con actividad en jun-2026.
- **Estado**: **conntrack-tools 1.4.9** (empaquetada en Debian feb-2026, sucede a la serie 1.4.8 de
  mar-2024).
- **net-tools frente a iproute2**: `net-tools` **sin release oficial desde 2001** y sin
  mantenimiento activo; ausente por defecto en Debian ≥9, RHEL/CentOS ≥7 (con `ifconfig` fuera por
  defecto en Ubuntu 18.04+, CentOS 8+, Fedora 22+ y Arch). **Sigue desaconsejado** y el motivo es
  funcional además de higiénico: no expone el estado moderno del kernel. Mapeo: `ifconfig` →
  `ip addr`/`ip link`, `route` → `ip route`, `arp` → `ip neigh`, `netstat` → `ss`.
- **eBPF para diagnóstico**: **`pwru` v1.0.12** (13-jul-2026; kernel ≥5.3, `--output-skb` ≥5.9,
  `--backend=kprobe-multi` ≥5.18; requiere `CONFIG_DEBUG_INFO_BTF`, `CONFIG_KPROBES`,
  `CONFIG_PERF_EVENTS`, `CONFIG_BPF`), **`bpftrace` 0.26.1** (02-jun-2026), **`bcc` 0.37.0**
  (02-jul-2026), **Cilium 1.20.0** (29-jul-2026) con Hubble. **Microsoft Retina alcanzó 1.0/GA** y
  permite Hubble sin exigir Cilium como CNI, con limitaciones conocidas (mapeo IP→pod en espacio de
  usuario, sin visibilidad L7). Conclusión: **maduro y recomendable, pero como segunda línea**, no
  como primer paso.
- **Kubernetes**: contenedores efímeros y `kubectl debug` **GA desde 1.25**; `nicolaka/netshoot`
  como imagen habitual; el contenedor efímero **no se puede eliminar** hasta borrar el pod y **no
  tiene límites de recursos**; `kubectl cp` **no funciona** con contenedores efímeros (transmite la
  captura por salida estándar).
- **Happy Eyeballs**: **RFC 8305 (Happy Eyeballs v2, dic-2017) sigue siendo la especificación
  vigente**. `draft-ietf-happy-happyeyeballs-v3` está en **Internet-Draft** (revisión -03, mar-2026)
  y **actualiza** la descripción del algoritmo de RFC 8305, **no la obsoleta** todavía. No lo cites
  como RFC.

**Huecos declarados — NO rellenar de memoria, verificar antes de usar**:
1. **Versión actual de `ethtool`**: **no verificada**. Las fuentes secundarias dan 6.15 (jun-2025) y
   mencionan 6.20 en repositorios de paquetes; el índice de kernel.org no devolvió las entradas
   recientes en esta consulta. Comprueba en `kernel.org/pub/software/network/ethtool/` o en tu
   distro antes de fijar versión mínima.
2. **Número de versión exacto de Wireshark 4.6.7 y su fecha**, y el estado de la rama 4.7.x de
   desarrollo: obtenidos de fuentes secundarias, **sin fecha confirmada**. Contrastar en
   `wireshark.org/news`.
3. **CVE recientes de Wireshark/`tshark`** (identificadores y severidad): sólo consta la existencia
   de un lote corregido en 2026; **no se han enumerado ni verificado**. Consúltalos antes de fijar
   una versión mínima en un runbook.
4. **Versión empaquetada por distro** de `iproute2`, `ethtool`, `conntrack-tools`, `tcpdump` y
   `mtr` en RHEL 10, Fedora, Debian 13 y Ubuntu LTS: **no verificada**. Lo operativo es la del
   paquete, no la upstream.
5. **Fecha de release de `mtr` v0.96**: sólo consta la etiqueta en el repositorio (sin *releases*
   publicadas) y actividad de commits en jun-2026; **fecha de publicación no confirmada**.
6. **Estado de mantenimiento de `iperf2`** (proyecto separado de iperf3) y de `socat`, `nmap` y
   `ncat`: **no verificado** en esta pasada.
7. **Capacidades, retardo y muestreo exactos de los flow logs y analizadores de alcanzabilidad**
   de AWS, Azure y GCP: descritos como criterio general, **no verificados** contra la documentación
   vigente de cada proveedor. Contrastar con `aws-standards`/`azure-standards`/`gcp-standards`.
8. **Detalles de Microsoft Retina 1.0** (versión concreta, fecha de GA, matriz de compatibilidad de
   CNI): procedentes de un blog corporativo, **sin verificar** contra el repositorio ni sus
   releases.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
