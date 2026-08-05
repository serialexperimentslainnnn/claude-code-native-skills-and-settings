---
name: load-balancing-standards
description: Load balancing as a failure-handling decision, not just traffic sharing — health checks, draining and TLS termination are where the value is. Use when designing or reviewing a load balancer or reverse proxy, haproxy.cfg with backend/server/option httpchk/http-check/observe/agent-check, nginx.conf upstream blocks with proxy_pass, keepalive and max_fails, an Envoy bootstrap or xDS cluster with outlier detection and panic threshold, Traefik static and dynamic configuration with healthCheck and serversTransport, a Caddyfile reverse_proxy with lb_policy and health_uri, an AWS ALB/NLB target group, Azure Application Gateway or Front Door, GCP backend service, choosing between layer 4 and layer 7, round-robin versus least-connections versus consistent hashing and maglev, session affinity and sticky cookies, shallow versus deep health check endpoints and a health check that queries the database, rise and fall thresholds, connection draining and graceful shutdown during a rolling deploy, TLS termination, re-encryption, mTLS to backends or TCP passthrough with SNI routing, HTTP/2 and HTTP/3 (RFC 9114) on the proxy and its effect on balancing, keepalive versus idle timeouts, listen backlog and ephemeral port exhaustion, X-Forwarded-For and Forwarded (RFC 7239) trust and spoofing, PROXY protocol, rate limiting and SYN flood protection, VRRP (RFC 9568) or keepalived for the balancer itself, or stateless balancing with ECMP and anycast.
---

# Estándares de balanceo de carga — repartir es fácil; fallar bien, no

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **diseñar, configurar y operar un balanceador o proxy inverso**: elección de capa,
algoritmo de reparto, comprobación de salud, drenaje y despliegue sin caída, terminación TLS,
protocolos HTTP, alta disponibilidad del propio balanceador, balanceo sin estado, y protección del
borde de servicio.

Triggers: `haproxy.cfg`, `nginx.conf` (`upstream`, `proxy_pass`), bootstrap/xDS de Envoy,
`traefik.yml`, `Caddyfile` (`reverse_proxy`), `keepalived.conf`, `ipvsadm`, "target group", "backend
service", "health check", "readiness", "drain", "sticky session", "consistent hashing", "maglev",
"PROXY protocol", "X-Forwarded-For", "SNI passthrough", "ECMP", "anycast", "outlier detection".

**No aplica** — el catálogo ya reparte esto: `networking-standards` es la **troncal** (proxies y
balanceo como principio, VLAN, MTU, direccionamiento) y **ya delega la profundidad**, mientras
`routing-switching-standards` posee el campus, la política BGP y la seguridad del plano de control
—**incluido el anuncio BGP que hace posible el anycast**—, `datacenter-fabric-standards` posee la
malla, VXLAN/EVPN y la Ethernet sin pérdidas, y `network-automation-standards` la configuración como
código. Hacia fuera: **la caché y el CDN son de `caching-cdn-standards`**, **la malla de servicios y
el descubrimiento de `microservices-architecture-standards`**, **Service, Ingress y Gateway API de
`kubernetes-standards`**, el filtrado de `firewall-policy-standards`, la identidad y el OIDC de
`identity-access-management-standards`, TLS y PKI de `cryptography-pki-standards`, métricas y paneles
de `observability-standards`, el SLO de `sre-practice-standards`, **la metodología de medir y el
modelo de carga de `performance-engineering-standards`**, el método reactivo de
`network-troubleshooting-standards`, y el paraguas de `onprem-standards` (junto a
`datacenter-facilities-standards` y `hpc-standards`). Entre las tres
hermanas de esta tanda: `wireless-standards` es la **red de acceso**, ésta la **red de servicio** y
`high-speed-interconnect-standards` la **red de cómputo**; **el error del dominio es aplicarles el
mismo criterio**.

**Principio rector**: **balancear es decidir qué pasa cuando algo falla.** El reparto es la parte
trivial; **casi todo el valor está en la comprobación de salud y en el drenaje**. Un balanceador con
un buen algoritmo y una mala comprobación de salud reparte tráfico hacia servidores rotos con
precisión ejemplar.

## 2. Decisiones por defecto

> Verificar versión, mantenimiento y **licencia en crudo** antes de fijar cualquiera (§8).

| Decisión | Por defecto | Alternativa justificable / vetado |
|---|---|---|
| Capa | **L7 (HTTP)** cuando se necesita enrutar por ruta/cabecera, reintentar, terminar TLS u observar peticiones | **L4** cuando manda el caudal, el protocolo no es HTTP o el cifrado debe llegar intacto al backend |
| Algoritmo | **Menos conexiones** (o menos peticiones) como default sensato en L7 | Round-robin sólo con backends homogéneos y peticiones uniformes; **hash consistente** cuando hay estado o caché por backend |
| Persistencia | **Ninguna**: servicios sin estado y sesión externalizada | Cookie de afinidad sólo como parche con fecha de retirada; ❌ afinidad por IP de origen (NAT y móviles la rompen) |
| Comprobación de salud | **Endpoint propio, superficial y barato**, separado de la salud de negocio | Comprobación profunda **sólo** con umbral distinto y sin tumbar todo el pool; ❌ TCP connect como única señal en HTTP |
| Drenaje | **Obligatorio**: sacar del reparto, esperar a que terminen las peticiones en curso, luego parar | ❌ Matar el proceso y confiar en el reintento del cliente |
| TLS | **Terminar en el balanceador y recifrar hacia el backend** | Passthrough cuando el backend debe ver el certificado de cliente o el cumplimiento lo exige; mTLS interno si la malla no lo cubre |
| Proxy L7 autogestionado | **HAProxy** (núcleo GPL-2.0, cabeceras LGPL) por observabilidad y control de tráfico; **Envoy** (Apache-2.0) cuando se necesita xDS dinámico | **nginx**/**Angie** (ambos BSD-2-Clause) por familiaridad; **Traefik** (MIT) en entornos dinámicos; **Caddy** (Apache-2.0) cuando el valor es ACME automático |
| L4 de alto caudal | **IPVS** en el núcleo para lo clásico; **Cilium/XDP** con hash tipo Maglev y DSR para escala grande | **Katran** sólo si asumes que es un espejo de bajo ritmo del código interno de Meta; ❌ proxy L7 como cortafuegos de caudal |
| HA del balanceador | **VRRP (RFC 9568) / keepalived** con failover **probado**; **ECMP + anycast** cuando el volumen lo justifica | ❌ Un balanceador sin par, o un par cuyo failover nunca se ejercitó |
| HTTP hacia el cliente | **HTTP/2 activado; HTTP/3 sólo tras verificar el estado exacto en tu proxy y versión** | ❌ Asumir que HTTP/3 está listo porque existe la directiva |
| HTTP hacia el backend | **HTTP/1.1 con keepalive** salvo motivo; H2 hacia backends **cambia el reparto** (§3) | ❌ Sin `keepalive` hacia el backend y luego culpar a la red |

## 3. Criterio de diseño

**L4 frente a L7 — qué se gana y qué se pierde**
- **L4** reparte conexiones sin entenderlas: coste por byte mínimo, cualquier protocolo, cifrado
  intacto. **Pierdes** enrutado por ruta o cabecera, reintento por petición, salud con semántica de
  aplicación y **toda la observabilidad de HTTP**. **L7** te da todo eso, pero **pagas** CPU, latencia
  y un componente que forma parte de la semántica de tu aplicación (y de su superficie de ataque).
- **Regla**: L4 para tráfico no HTTP y caudal bruto; L7 en cuanto la decisión dependa del contenido.
  Mezclar capas en cascada (L4 delante, L7 detrás) es legítimo y a menudo lo correcto.

**Algoritmos**
- **Round-robin**: sólo con backends idénticos y peticiones de coste similar; si no, concentra las
  caras en el mismo sitio. **Menos conexiones**: default razonable porque aproxima "quién está menos
  ocupado", con **arranque lento** obligatorio (el backend recién reiniciado tiene cero conexiones y
  se lleva una avalancha). **Aleatorio de dos opciones** es barato y muy bueno con listas grandes.
- **Hash consistente (Maglev, ketama)**: **obligatorio** cuando el backend tiene estado útil por
  clave —caché local, particiones, sesiones largas, conexiones por inquilino— y **cuando el conjunto
  cambia con frecuencia**: un hash módulo-N reasigna *todas* las claves al añadir o quitar un nodo; el
  consistente sólo su fracción. Es lo que permite repartir igual desde varios balanceadores.

**Persistencia de sesión: es un olor**
- La afinidad ata a un usuario a un servidor: rompe el drenaje, sesga el reparto, convierte cada
  despliegue en pérdida de sesión y esconde el bug real, que es **estado en memoria del proceso**. Si
  existe, es deuda con dueño y fecha; la solución es sacar la sesión fuera. Excepción legítima:
  conexiones largas (WebSocket, SSE), donde la afinidad es de la conexión, no una cookie.

**Comprobaciones de salud — la sección que decide todo**
- **Superficial** (`/healthz`, sin dependencias externas) frente a **profunda** (¿mis dependencias
  responden?): útil, pero **con consecuencias distintas**.
- **El peligro capital**: una comprobación que consulta la base de datos hace que, cuando ésta hipa,
  **todo el pool se marque enfermo a la vez** y el balanceador retire el 100% del servicio por un
  problema que sólo degradaba una parte —la caída total la provoca la comprobación, no el fallo—.
  Mitigaciones: **separar liveness de readiness**, no meter dependencias compartidas en la
  comprobación que gobierna el reparto, y **umbral de pánico** (si más del X% del pool está enfermo,
  ignorar la salud y repartir a todos: degradado es mejor que apagado).
- **Asimetría de umbrales**: bajar rápido (pocos fallos), subir despacio (varios éxitos), para no
  oscilar. Intervalos, timeouts y umbrales se declaran, no se heredan del default; el **timeout debe
  ser menor que el intervalo** o se solapan y falsean el estado; y la comprobación va **por el mismo
  camino** que el tráfico real (mismo puerto, mismo TLS).
- **La aplicación decide cuándo está lista**: `/readyz` debe pasar a fallar **antes** de que el
  proceso empiece a cerrarse. Ése es el mecanismo real del drenaje.

**Drenaje y despliegue sin caída**
- Secuencia obligatoria: marcar como no disponible → **esperar a que el balanceador lo note** (≥ un
  ciclo completo de comprobación) → dejar de aceptar conexiones nuevas → terminar las en curso con
  plazo → cerrar. Saltarse la espera es la causa habitual de los 502 durante los despliegues. El
  plazo de gracia supera la petición más larga legítima; las conexiones largas se cierran con señal
  ordenada (GOAWAY en H2). **Reintentos sólo sobre lo idempotente** y con presupuesto: reintentar
  todo bajo carga convierte una degradación en una tormenta.

**TLS**
- **Terminar en el balanceador** simplifica certificados y da visibilidad; **recifrar hacia el
  backend** es el default cuando el tramo interno no es de confianza física —"es la red interna" no
  es un argumento—, y **mTLS** cuando el balanceador debe demostrar quién es.
- **Passthrough** cuando el backend necesita el certificado de cliente o el cumplimiento prohíbe
  desencriptar: se enruta por **SNI** y se pierde todo lo demás. Es una decisión, no un default. Al
  terminar se pierde la IP real: **PROXY protocol** en L4, cabeceras en L7 (§5).

**HTTP/2 y HTTP/3 en el balanceador**
- **H2 hacia el cliente** es el default. **H2 hacia el backend cambia el reparto**: multiplexa muchas
  peticiones en pocas conexiones, así que balancear por conexión deja de repartir —hace falta
  balanceo **por petición**, y aun así unas pocas conexiones persistentes concentran carga—. Es la
  causa clásica del "balanceo desigual" tras activar H2 interno.
- **H3/QUIC va sobre UDP**: cambia el firewall, el ECMP (hash sobre UDP y **Connection ID**), la
  contabilidad de conexiones y la migración entre redes. **Verifica el estado exacto por proxy y
  versión** (§8): la madurez difiere entre el sentido cliente-proxy y el proxy-backend.

**HA del propio balanceador**
- **El balanceador es el punto único de fallo por excelencia**: concentra todo el tráfico y todo el
  estado de conexión. Par con VRRP (**RFC 9568**, que obsoleta la 5798) o equivalente, con failover
  **ejercitado**, sabiendo que **corta las conexiones en curso** salvo con sincronización de estado.
- **ECMP + anycast escala mejor**: N balanceadores idénticos anunciando la misma VIP, sin par
  activo-pasivo, sin estado compartido y con capacidad que crece añadiendo nodos. El precio: **un
  cambio en el conjunto rebaraja el hash ECMP** y rompe conexiones, salvo que los nodos usen hash
  consistente hacia los backends. Es lo que hay que conocer antes de comprar un aparato más grande.

## 4. Gates de calidad

- **Validar la configuración antes de aplicar** (`haproxy -c -f`, `nginx -t`, `envoy --mode validate`
  o el equivalente del producto). Config que no valida no llega ni a staging.
- **Prueba de fallo de backend con tráfico real**: matar un backend y **medir** cuántas peticiones se
  pierden y en cuánto se retira. Si nadie lo ha medido, el número es desconocido, no cero.
- **Prueba de despliegue sin caída** bajo carga con **cero 5xx** como criterio de aceptación (detecta
  un drenaje mal hecho), y **prueba negativa de salud**: degradar la dependencia compartida y
  verificar que **no** se retira todo el pool — el gate que evita la caída total.
- **Prueba de failover del balanceador**, incluida la **vuelta** (falla más que la ida), y **prueba
  de cabeceras de reenvío**: `X-Forwarded-For` falsificado desde fuera y la aplicación no lo cree.
  Config en repo y por automatización; un balanceador distinto de su par es un hallazgo.

## 5. Seguridad

- **`X-Forwarded-For` sin recortar es una vulnerabilidad.** Es una lista que **cualquiera puede
  prefijar**: si la aplicación toma el primer valor, el atacante elige su propia IP y evade listas
  negras, límites de tasa, geolocalización y auditoría. Regla: el balanceador de borde
  **sobrescribe** (no añade), o se cuenta un número **fijo y conocido** de proxies de confianza desde
  la derecha. Igual con `Forwarded` (**RFC 7239**), `X-Forwarded-Proto/-Host` y `X-Real-IP`.
- **Elimina en el borde toda cabecera interna** que la aplicación use para decidir (roles, "es
  interno", identidad ya autenticada): un `X-Authenticated-User` que sobrevive desde fuera es un
  bypass de autenticación completo.
- **Límite de tasa en el balanceador** por IP real y por credencial/ruta, con 429 y cabeceras de
  límite: protege incluso con la aplicación saturada. Los límites por IP se saltan tras NAT o CGNAT;
  combínalos con límites por identidad.
- **Protección de inundación**: SYN cookies, límites de conexiones por origen, timeouts agresivos de
  handshake y de cabeceras (Slowloris se mata con timeout de lectura de cabeceras), tamaño máximo de
  cuerpo y cabecera, y límites de tramas/streams en H2 (*rapid reset* es agotamiento, no caudal).
- **Superficie del propio balanceador**: estadísticas y API de administración **nunca** expuestas;
  certificados con renovación automática y **alerta de expiración** (cifras y TLS, en
  `cryptography-pki-standards`). Y contra la **desincronización de peticiones** (*request
  smuggling*), que nace de que proxy y backend interpretan distinto
  `Content-Length`/`Transfer-Encoding`: rechaza peticiones ambiguas, normaliza en el proxy y **mantén
  versiones al día en ambos extremos**.

## 6. Rendimiento y operabilidad

- **Señales que se vigilan siempre**: peticiones por segundo y por código, latencia en **percentiles
  altos** separando cola del balanceador y tiempo del backend, backends sanos frente a configurados,
  conexiones activas y su **reparto real** por backend, reintentos y 502/503/504 por causa.
- **Desbordamiento y colas**: la cola de aceptación (`backlog`) y su límite del núcleo convierten una
  ráfaga en pérdida de conexiones; se dimensiona y se **monitoriza el desbordamiento**. Un `backlog`
  grande sin capacidad detrás sólo cambia errores por latencia.
- **Agotamiento de puertos efímeros**: abrir una conexión nueva por petición hacia pocos backends
  agota el rango de puertos de origen y falla de forma intermitente. Solución: **keepalive hacia el
  backend** con pool dimensionado, varias IP de origen si hace falta, y vigilar `TIME_WAIT`.
- **Coherencia de timeouts**: el de inactividad del balanceador debe ser **menor** que el keepalive
  del backend; si el backend cierra primero, se reutiliza una conexión muerta y salen 502
  esporádicos —el fallo más difícil de reproducir del dominio. Escríbelos en una tabla (cliente,
  balanceador, backend, base de datos) y verifica que decrecen. **Capacidad**: dimensiona por
  percentiles reales y por **conexiones concurrentes**; TLS y H2 consumen memoria por conexión.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: ramas **LTS/estables** frente a la última minor; revisión trimestral y ante CVE con
  KEV/EPSS relevante. El balanceador está expuesto: es de los primeros en parchear.
- **Ecosistema nginx** (dato que decide): nginx es de **F5** desde 2019; en 2024 su desarrollador
  principal lo bifurcó en **freenginx** por desacuerdos de gobernanza, y desde 2022 existe **Angie**,
  de antiguos desarrolladores del núcleo. **Los tres comparten configuración y ambos forks son
  BSD-2-Clause**; nginx sigue activo (copyright hasta 2026), así que no es una emergencia, pero si
  eliges nginx **decide también a quién sigues** y verifica el ritmo de publicación de cada uno.
- **Deprecación**: cada backend, regla y certificado retirado desaparece de la configuración y del
  inventario. Un `server` comentado no es documentación.

**PROHIBIDO**
- ❌ Balanceador sin comprobación de salud activa, o con TCP connect como única señal para HTTP.
- ❌ Comprobación de salud que consulta la base de datos u otra dependencia compartida y puede
  marcar enfermo todo el pool a la vez, sin umbral de pánico.
- ❌ Desplegar sin drenaje: retirar del reparto y matar el proceso sin esperar un ciclo de salud.
- ❌ Afinidad de sesión permanente sin dueño ni fecha de retirada; afinidad por IP de origen.
- ❌ Confiar en `X-Forwarded-For` o `Forwarded` recibido del cliente sin sobrescribir ni recortar.
- ❌ Dejar pasar hacia el backend cabeceras internas de confianza o de identidad.
- ❌ Un solo balanceador para algo que importa; o un par cuyo failover nunca se ha probado.
- ❌ Reintentar peticiones no idempotentes, o reintentar sin presupuesto máximo.
- ❌ Activar HTTP/3 sin verificar su estado en la versión concreta ni ajustar firewall y ECMP a UDP.
- ❌ Backends sin `keepalive` (y luego culpar a la red del agotamiento de puertos efímeros), o
  timeout de inactividad del balanceador mayor que el keepalive del backend (502 fantasma).
- ❌ Exponer la página de estadísticas o la API de administración del balanceador.
- ❌ Hash módulo-N sobre un conjunto de backends que cambia; consistente o nada.
- ❌ Terminar TLS y hablar en claro con el backend "porque es red interna", sin decisión escrita.
- ❌ Poner en producción sin haber **medido** cuántas peticiones se pierden al caer un backend.

## 8. Verificación web obligatoria

**Metodología**: los RFC, **uno a uno** contra el JSON de `rfc-editor.org`; las licencias, **leyendo
el fichero en crudo** del repositorio, no la etiqueta de GitHub.

**RFC verificados ago-2026**: **HTTP/3 = RFC 9114** (jun-2022, Proposed Standard, sin obsoletos);
**HTTP/2 = RFC 9113** (jun-2022, Proposed Standard, **obsoleta 7540 y 8740** — citar RFC 7540 hoy es
un error de hecho); **cabecera `Forwarded` = RFC 7239** (jun-2014, Proposed Standard); **VRRPv3 =
RFC 9568** (may-2024, Proposed Standard, **obsoleta RFC 5798**).

**Licencias verificadas en crudo ago-2026**: **HAProxy** — su `LICENSE` declara núcleo **GPL v2** con
la intención explícita de permitir módulos externos, y desarrolla el esquema de cabeceras bajo LGPL:
**no es "GPL a secas" ni MIT**. **nginx** — BSD de **2 cláusulas**, aviso "Copyright (C) 2011-2026
Nginx, Inc." (repositorio activo). **Angie** — el mismo texto BSD-2 más "Copyright (C) 2022-2026 Web
Server LLC": **fork con licencia idéntica**, y su `LICENSE` está en la rama **`master`, no `main`**
(la ruta habitual da 404 y aparenta falta de licencia). **Envoy** y **Caddy** — **Apache-2.0**.
**Traefik** — **MIT**, en `LICENSE.md`, no `LICENSE`.

**Discrepancia declarada**: las fuentes divergen sobre la madurez de HTTP/3 en Envoy — el sentido
descendente (cliente→proxy) se describe como listo y el ascendente (proxy→backend) como alfa.
Trátalo como no resuelto y verifica la documentación de **tu** versión exacta.

**Huecos declarados — NO rellenar de memoria**:
1. **Versiones estables vigentes y ventanas de soporte** de HAProxy, nginx, Angie, freenginx, Envoy,
   Traefik y Caddy: **no fijadas aquí a propósito**; en particular, el **ritmo de publicación y la
   salud de freenginx** no están verificados.
2. **Estado exacto de HTTP/3 por proxy y versión**, con sus dependencias de biblioteca TLS con QUIC y
   la migración de conexión: **no verificado producto a producto**.
3. **Balanceadores gestionados de nube** (ALB/NLB, Application Gateway/Front Door, backend services):
   límites, drenaje, semántica de salud y HTTP/3 **no verificados aquí**; son de `aws/azure/gcp`.
4. **Katran** es activo pero de bajo ritmo y espejo de código interno de Meta; **Cilium/XDP e IPVS no
   fijados por versión**. Y los **valores concretos** de `backlog`, umbrales de salud, plazos de
   gracia y tamaños de pool son criterio de ingeniería, **no medidas**: se derivan midiendo.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
