---
name: firewall-policy-standards
description: Firewall policy as a governed engineering artifact. Use when writing or reviewing nftables rulesets (nftables.conf, nft -c -f, tables/chains/hooks/priorities, sets, maps, verdict maps, ct state, meters), firewalld zones, services, policies and rich rules (firewall-cmd), ufw profiles, DOCKER-USER chains and Docker firewall-backend published-port bypass, kube-proxy nftables mode, cloud security group and NSG rule sets as filtering policy, egress allow-listing, zone-to-zone flow matrices, rule ownership, expiry dates and change approval, shadowed, duplicate, orphaned or any/any rule review, conntrack table exhaustion and asymmetric-routing state loss, MSS clamping and NAT interaction with filtering, deny logging volume and forwarding, or IPv6 rule parity with IPv4.
---

# Estándares de política de firewall — la regla como artefacto de ingeniería

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **diseñar, escribir, aprobar, desplegar, revisar y retirar política de filtrado**:
default-deny en entrada y salida, matriz de flujos entre zonas, ciclo de vida de la regla (quién
la pide, quién la aprueba, por qué existe, cuándo caduca), política como código y su despliegue
por CI, deriva frente al SoT, implementación en `nftables`/`firewalld`/`ufw`, firewall de red
frente a firewall de host, trampas del filtrado *stateful*, revisión y limpieza del ruleset,
registro de denegaciones, y los casos especiales que reescriben tus reglas (contenedores,
Kubernetes, nubes) y el olvido crónico de IPv6.

Triggers: `nftables.conf`, `/etc/nftables.d/*.nft`, `nft list ruleset`, `nft -c -f`,
`table inet`, `hook prerouting|input|forward|output|postrouting`, `policy drop`, `ct state`,
`define`/`set`/`map`/`vmap`, `firewall-cmd`, `firewalld.conf`, `/etc/firewalld/zones/*.xml`,
`rich rule`, `ufw allow|deny|status`, `iptables-save`/`iptables-nft`/`iptables-legacy`,
`DOCKER-USER`, `daemon.json` con `iptables`/`firewall-backend`, `conntrack -L`,
`nf_conntrack_max`, `security group` / `NSG` / `network ACL` como política, "matriz de flujos",
"regla temporal", "any/any", "abrir un puerto", "revisión de reglas", "el firewall bloquea".

**Principio rector** (hereda literalmente el de `networking-standards`: *la red es default-deny y
documentada como código; lo que no está en el SoT no existe*): **una regla es un compromiso con
dueño, motivo y fecha de caducidad**. Un ruleset es la suma de decisiones vivas, no el sedimento
de peticiones antiguas: si nadie sabe por qué existe una regla, la regla ya es una vulnerabilidad
administrativa, independientemente de lo que permita.

**No aplica**: ver `networking-standards` (**madre**: diseño de red, direccionamiento e IPAM,
VLAN y segmentación, routing/BGP, RPKI, MTU/MSS a nivel de diseño, proxies y balanceadores,
overlays, plano OOB — **la topología y las zonas las define ella; qué flujo se permite entre
zonas, con qué gobierno y con qué prueba, es de aquí**), `linux-hardening-standards` (**el
firewall *de host* como control del baseline CIS/STIG y su medición con `oscap`/Lynis**: que el
host tenga default-deny de entrada, egress filtrado y ruleset versionado es un control **suyo**
y se audita como parte del baseline; **cómo se diseña, aprueba, expresa y gobierna esa política
—incluida la sintaxis nftables y su ciclo de vida— es de aquí**. En la práctica: ellos exigen y
puntúan, esta skill decide el contenido),
`dns-standards` (**existe**: el servicio DNS, sus zonas y su telemetría — **ella define qué
resolver es legítimo y qué registra; tú escribes y gobiernas la regla** que permite `53`/`853`
hacia ese resolver, bloquea el DNS saliente a cualquier otro y filtra el egress),
`detection-engineering-standards` (**qué se hace con tus logs**: las reglas de detección, la
normalización ECS/OCSF y las analíticas sobre `deny` son suyas; **la telemetría que generas —qué
se loguea, con qué campos, con qué tasa y hacia dónde— es tuya**),
`observability-standards` (métricas, dashboards y alertas del firewall como servicio),
`selinux-standards` (MAC como control ortogonal: el filtrado de red no sustituye al confinamiento
del proceso), `kubernetes-standards` (`NetworkPolicy`, CNI y política dentro del clúster;
**aquí sólo la interacción de kube-proxy/CNI con el ruleset del nodo**),
`container-runtime-security-standards` (aislamiento y escape del contenedor),
`aws-standards`/`azure-standards`/`gcp-standards` (Security Groups, NSG, NACL y firewalls
gestionados como **servicio del proveedor**: su modelo, límites y IaC son suyos; **el criterio de
default-deny, propiedad y caducidad de la regla es de aquí y aplica igual**),
`iac-standards` (Terraform/Ansible que despliegan la política: estructura de módulos, Molecule,
lint), `cicd-standards` (el pipeline que valida y aplica), `grc-compliance-standards` (la revisión
periódica de reglas como control auditable ante ENS/ISO 27001/NIS2/PCI),
`incident-response-forensics-standards` (el log de firewall como evidencia y el bloqueo de
contención durante un compromiso), `identity-access-management-standards` (identidad del bastión
y elevación JIT frente al acceso por IP), `onprem-standards` (paraguas de plataforma),
`homelab-standards` (laboratorio propio: la frontera es el rigor exigido, no el tamaño),
`bcdr-standards` (restauración del ruleset como parte de la recuperación),
`offensive-security-standards` (validación ofensiva de la política, con alcance y autorización),
`ot-ics-security-standards` (**qué conducto puede existir entre zonas industriales lo decide ella**
—zonas y conductos IEC 62443-3-2, DMZ de nivel 3.5, diodo de datos—; **aquí se escribe, se aprueba
y se gobierna la regla que lo implementa**).

Además:
`vpn-standards` (**el túnel es suyo; la política que filtra el tráfico que sale del túnel es
tuya** — un `wg0` que entra en `forward` sin reglas es una VPN sin firewall),
`network-troubleshooting-standards` (**diagnóstico**: tú fijas cuál es la política correcta y
demuestras que lo denegado se deniega; él averigua **por qué** un paquete concreto no llega —
cuando el síntoma es "esto no conecta", la respuesta "falta una regla" es de aquí y la respuesta
"se pierde el estado por ruta asimétrica" se diagnostica allí y se corrige aquí),
`linux-administration-standards`, `ha-clustering-standards`, `proxmox-ve-standards`.

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión y el estado en la **distro exacta** del proyecto antes de fijar nada
> (§8): la capa de compatibilidad `iptables`↔`nftables` cambia entre versiones y entre distros.

| Ámbito | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| Motor de filtrado en Linux | **nftables** nativo, una sola tabla `inet` con IPv4+IPv6 (upstream 1.1.6, 05-dic-2025; Fedora 44 empaqueta 1.1.4) | `firewalld` (**2.5.0**, 08-jul-2026, backend nftables) cuando hay zonas dinámicas, interfaces que aparecen y desaparecen, o integración con NetworkManager/Podman/libvirt | `iptables-legacy`; **mezclar** comandos `iptables` y reglas `nft` en el mismo host |
| Capa de compatibilidad | `iptables-nft` **sólo como shim de terceros** que aún no hablan nft | Convivencia temporal documentada y con fecha de salida | Escribir política nueva en sintaxis iptables |
| Host sencillo, un solo administrador | **nftables directo** con fichero versionado | `ufw` sólo en un host de perfil trivial (`allow 22`, `allow 443`) | `ufw` como política corporativa: **no tiene backend nft nativo**, sólo `backend_iptables.py` sobre `iptables-nft`, y compite por la propiedad del ruleset con cualquier otro gestor |
| Perímetro | Plataforma de la organización (OPNsense/VyOS/appliance) gobernada como código — la elección de plataforma, en `networking-standards` | — | Reglas escritas a mano en la GUI sin reflejo en el SoT |
| Fuente de verdad | **Repo Git fuera del dispositivo**; el dispositivo es un destino de despliegue, no la fuente | Exportación del dispositivo como *evidencia* comparada contra el repo | La config running como única copia de la política |
| Objeto de la regla | **Sets y maps con nombre** (`@mgmt_nets`, `@web_ports`) y `vmap` para el enrutado de veredictos | Literales sólo en reglas verdaderamente únicas | Cientos de reglas casi iguales que deberían ser un set (fuente estructural de duplicidad y sombreado) |
| Aplicación | `nft -f` (**atómico**: se aplica el ruleset entero o ninguno) desde CI | `firewall-cmd --permanent` + `--reload` | Reglas incrementales interactivas en producción |
| Kubernetes | `kube-proxy` en modo **nftables** (GA en 1.33, requiere kernel ≥5.13) en clústeres grandes | modo `iptables` (**sigue siendo el default upstream**, sin fecha anunciada de cambio) | `IPVS` en despliegues nuevos (**deprecado en 1.35**) |
| Docker | `DOCKER-USER` como punto de inserción de política con el backend iptables | Backend **nftables experimental** (Docker Engine 29, `"firewall-backend": "nftables"` en `daemon.json`) sólo en lab | `DOCKER_INSECURE_NO_IPTABLES_RAW=1` en producción |
| Kernel | Fijar mínimo **≥6.18.10 / 6.19**, o backports **5.15.200, 6.1.163, 6.6.124, 6.12.70** | Kernel de la distro con el CVE ya backporteado (verificar, no suponer) | Kernel sin el parche de **CVE-2026-23111** (UAF en `nf_tables`, LPE local, CVSS 7.8) con user namespaces sin privilegios habilitados |

## 3. Estructura y convenciones

### 3.1 Default-deny en serio: entrada **y** salida

- `policy drop` en `input`, `forward` **y `output`**. Una política que sólo mira hacia dentro está
  medio construida: **el filtrado de egress es lo que corta C2, exfiltración y descarga de segunda
  etapa**, y es exactamente lo que casi nadie hace porque duele durante dos semanas.
- **Egress por lista de permitidos, por destino y por origen**: qué hosts pueden salir, a dónde y
  a qué puerto. Casos que hay que resolver explícitamente antes de activarlo: DNS (sólo hacia el
  resolver corporativo — ver `dns-standards` para cuál es legítimo), NTP, repositorios de paquetes
  y de imágenes, telemetría, ACME, correo saliente, y actualizaciones del propio SO.
- **Estrategia de adopción sin cortar el servicio**: (1) `output` en modo registro con regla final
  `log prefix "EGRESS-WOULD-DROP " counter` y `accept`; (2) analizar el log durante uno o dos
  ciclos de negocio completos (incluye cierre de mes y ventanas de backup); (3) escribir las
  reglas con dueño; (4) invertir a `drop` con la sesión de rescate abierta. **Saltarse el paso 2
  es cómo se rompe producción un viernes.**
- Egress vía **proxy explícito** cuando el destino es HTTP(S): filtrar por IP en la era del CDN es
  perseguir un blanco móvil. El proxy da nombre, no sólo dirección (la elección y despliegue de
  proxies, en `networking-standards`).
- **Excepción que no es excepción**: ICMP e ICMPv6. No bloquees `destination-unreachable` /
  `fragmentation needed` (mata PMTUD) ni ICMPv6 en general (rompe ND y con ello IPv6).

### 3.2 Ciclo de vida de una regla

Toda regla tiene, en el repo, **seis campos obligatorios**; sin ellos el PR no se aprueba:

| Campo | Significado |
|---|---|
| `id` | Identificador estable, citable en tickets y en la revisión |
| `owner` | **Persona o equipo**, no "infraestructura". Cuando esa persona se va, la regla se reasigna o se retira |
| `justification` | El **motivo de negocio o técnico**, no la descripción de la regla ("permite tcp/5432" no es una justificación) |
| `requested_by` / `approved_by` | Quién pidió y quién aprobó. Riesgo alto (egress amplio, entrada desde Internet, `any`) exige aprobación de seguridad, no sólo de red |
| `expires` | **Fecha de caducidad obligatoria.** Permanente es un valor explícito y excepcional, no el default |
| `review` | Fecha de la última revisión y su resultado |

- **Una regla sin dueño ni fecha es deuda permanente.** El default del sistema debe ser la
  caducidad: lo que hay que justificar es la permanencia, no el vencimiento.
- **Reglas que caducan solas**: acceso temporal de proveedor, ventana de mantenimiento,
  depuración, migración. Se implementan con **timeout nativo** (elemento de set nftables con
  `timeout 4h`, que el kernel expira solo) o con un job de CI que reconstruye el ruleset desde el
  repo y deja fuera lo vencido. Preferir **siempre** el mecanismo automático: la disciplina humana
  no revierte reglas a las 3 de la madrugada.
- **El "any/any temporal" que lleva cuatro años** es el anti-patrón central de este documento.
  Su origen es siempre el mismo: incidente + prisa + "lo afinamos mañana" + sin fecha. La defensa
  no es cultural, es mecánica: **toda regla de emergencia nace con `expires` a ≤72 h** y su
  renovación requiere PR nuevo con justificación. Si al vencer nadie la reclama, se cae sola —y
  ese es precisamente el resultado deseado.
- **Retirada**: eliminar una regla incluye retirarla del repo, del dispositivo, del inventario de
  flujos y de la documentación. Una regla "comentada por si acaso" sigue siendo una decisión
  pendiente; se borra, que para eso está el historial de Git.

### 3.3 Diseño por zonas y matriz de flujos

- Las zonas las define la topología (`networking-standards`); **la matriz es de aquí**: una tabla
  origen × destino donde cada celda permitida enumera protocolo, puerto, dirección de inicio,
  dueño, justificación y caducidad. Toda celda no listada es `deny`.
- **La matriz es el documento aprobado**; el ruleset es su compilación. Se revisa con negocio y
  con seguridad, se versiona, y se usa como evidencia de auditoría.
- **Microsegmentación este-oeste**: la mayor parte del tráfico de un datacenter nunca cruza el
  perímetro. Filtrar sólo norte-sur deja el movimiento lateral sin control. La ubicación en la red
  no otorga confianza (NIST SP 800-207).
- **Direcciones y grupos con nombre**: la matriz habla de roles (`web`, `db`, `mgmt`), no de IPs.
  Los sets traducen rol→direcciones y se alimentan del IPAM/SoT.

### 3.4 Firewall de host **y** firewall de red: los dos

- **No son alternativas, son capas.** El de red aplica política entre zonas y sobrevive al
  compromiso del host; el de host aplica política **por servicio**, ve el tráfico que nunca cruza
  un router (mismo segmento, mismo hipervisor, mismo nodo) y es la única defensa contra el
  movimiento lateral dentro de una VLAN. Quien dice "ya lo filtra el perímetro" está afirmando que
  su VLAN es una zona de confianza plana.
- El firewall de host es además **el control medible del baseline** (`linux-hardening-standards`):
  ellos exigen que exista y lo puntúan; **su contenido y gobierno se deciden aquí**, con el mismo
  ciclo de vida, el mismo repo y los mismos gates que la política de red.
- **Coherencia obligatoria**: host y red se generan del **mismo** SoT de flujos. Dos políticas
  escritas por separado divergen en semanas y producen el peor de los diagnósticos ("funciona
  desde aquí pero no desde allí").

### 3.5 Stateful y sus trampas

- **`ct state established,related accept` primero, `ct state invalid drop` siempre.** Sin la
  segunda, paquetes fuera de estado atraviesan reglas pensadas para conexiones nuevas.
- **Rutas asimétricas**: si la ida y la vuelta pasan por firewalls distintos (o por uno solo en un
  sentido), el estado no existe para el retorno y el tráfico se cae de forma **intermitente y no
  reproducible**. Síntoma clásico: "va bien un rato y luego se corta". Es un problema de diseño de
  camino, no de regla: se corrige fijando el enrutado simétrico o sincronizando estado entre el par
  (`conntrackd`/pfsync), nunca añadiendo un `accept` amplio para "que funcione".
- **Agotamiento de conntrack**: `nf_conntrack_max` alcanzado ⇒ descartes silenciosos y una línea
  en `dmesg` que nadie mira. **Monitoriza ocupación de la tabla como métrica de primera clase**
  (§6), dimensiónala con la memoria del equipo y revisa los timeouts: `tcp_timeout_established`
  por defecto es de días y guarda flujos muertos que sostienen NAT y llenan la tabla. Un balanceador
  o un servidor con muchísimas conexiones cortas puede justificar `notrack` selectivo en tráfico
  que no lo necesita —decisión consciente, documentada, y nunca sobre tráfico filtrado por estado.
- **UDP y "estado" son una ficción útil**: conntrack infiere flujos UDP por timeout. Ajusta
  timeouts de UDP y considera el impacto en NAT de aplicaciones con keepalive largo.
- **MTU/MSS y fragmentación**: el fragmento no lleva puertos, así que sólo el primero casa con
  reglas L4. Aplica **MSS clamping** en `forward` sobre túneles (`tcp flags syn tcp option maxseg
  size set rt mtu`) — los valores y el diseño de MTU, en `networking-standards`. Un firewall que
  descarta fragmentos sin más rompe DNS grande, IPsec y VPN.
- **NAT y filtrado se evalúan en momentos distintos**: el DNAT ocurre en `prerouting`, antes de
  `forward`, de modo que las reglas de filtrado ven la **IP interna ya traducida**, no la
  publicada. Escribir la regla contra la IP pública es el error de novato que abre lo que creías
  cerrar. Ordena: `prerouting` traduce, `forward` decide. Y el SNAT/masquerade no filtra nada:
  ocultar no es proteger, y con IPv6 esa ilusión desaparece.

### 3.6 Esqueleto de referencia (nftables, tabla `inet` única)

```nft
# SoT: repo/firewall/base.nft — desplegado por CI con `nft -f` (atómico). No editar en el host.
table inet policy {
  set mgmt_nets   { type ipv4_addr; flags interval; elements = { 10.0.10.0/24 } }
  set mgmt_nets6  { type ipv6_addr; flags interval; elements = { 2001:db8:10::/64 } }
  set temp_access { type ipv4_addr; flags timeout; }        # altas con `timeout`, expiran solas

  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iif lo accept
    ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded } accept
    icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-advert,
                  echo-request, packet-too-big, time-exceeded, parameter-problem } accept
    # id=FW-001 owner=plataforma expires=2027-01-31 just="administración por bastión"
    ip  saddr @mgmt_nets  tcp dport 22 accept
    ip6 saddr @mgmt_nets6 tcp dport 22 accept
    limit rate 10/second burst 20 packets log prefix "IN-DENY " level info counter
  }

  chain forward {
    type filter hook forward priority filter; policy drop;
    tcp flags syn tcp option maxseg size set rt mtu     # MSS clamping en túneles
    ct state established,related accept
    ct state invalid drop
    limit rate 10/second burst 20 packets log prefix "FWD-DENY " level info counter
  }

  chain output {
    type filter hook output priority filter; policy drop; # egress filtrado, no decorativo
    ct state established,related accept
    # id=FW-010 owner=plataforma expires=permanent just="resolución interna (ver dns-standards)"
    ip daddr @resolvers udp dport 53 accept
    ip daddr @resolvers tcp dport { 53, 853 } accept
    limit rate 10/second burst 20 packets log prefix "OUT-DENY " level info counter
  }
}
```

Notas de forma que son criterio, no estilo: **una sola tabla `inet`** (IPv4 e IPv6 en las mismas
reglas evita la divergencia); **comentario con `id`, `owner`, `expires` y justificación en cada
regla de permiso**; **sets con nombre** en lugar de literales repetidos; `counter` en las reglas
que quieras poder auditar por uso; y el `log` de denegación **siempre limitado en tasa**.

## 4. Gates de calidad obligatorios

En orden de coste creciente. Los cinco primeros rompen el build o el despliegue.

1. **Validación sintáctica**: `nft -c -f ruleset.nft` (y `firewall-cmd --check-config` donde
   aplique) en cada PR. Una política que no valida no llega ni a staging.
2. **Lint de política** en CI, con fallo duro:
   - Ninguna cadena base sin `policy drop`.
   - Ninguna regla de permiso sin `id`, `owner`, `justification` y `expires`.
   - **Ninguna regla vencida** (`expires` en el pasado) y aviso a 30 días.
   - Ningún `any`/`0.0.0.0/0`/`::/0` en origen **y** destino a la vez sin la etiqueta de excepción
     aprobada.
   - **Paridad IPv6**: toda regla IPv4 tiene su equivalente IPv6 o una exención justificada. Este
     gate existe porque **el olvido de IPv6 es el fallo más común del oficio**: el servicio escucha
     en `::`, el atacante llega por IPv6 y la política sólo cubría IPv4.
   - Ninguna regla huérfana: todo `id` existe en la matriz de flujos aprobada.
3. **Prueba en entorno equivalente antes de producción**: aplicar el ruleset en un host o VM
   gemelo y ejecutar el conjunto de pruebas de conectividad. Cambios de topología o de protocolo
   nuevos, en laboratorio (containerlab) antes de tocar hierro.
4. **Aplicación con red de seguridad — sin excepciones.** Todo cambio remoto de firewall se hace
   con **sesión de rescate abierta o consola OOB disponible**, y con reversión temporizada:
   `commit-confirm` (VyOS), safe mode (RouterOS), o en Linux un `at`/`systemd-run --on-active`
   que restaura el ruleset anterior en N minutos salvo confirmación explícita. Sin eso, **no se
   toca**. Bloquearse fuera del firewall es el incidente más previsible y más evitable que existe.
5. **Pruebas negativas obligatorias**: verificar que lo permitido funciona **y que lo denegado se
   deniega**, desde el origen real y contra el destino real. Barrido de puertos desde una zona
   hacia otra que confirme que sólo responde lo previsto (con autorización interna;
   `offensive-security-standards` para la validación formal). Un firewall probado sólo por el
   camino feliz **no está probado**: no sabes si tu regla funciona o si es que el servicio ya
   estaba caído.
6. **Detección de deriva**: comparación periódica y automática entre `nft list ruleset` (o el
   export del dispositivo) y el artefacto generado desde el repo. Toda diferencia es un hallazgo
   con dueño. La deriva es la métrica de si tu gobierno es real o teatro.
7. **Revisión periódica del ruleset** (trimestral en perímetro, semestral en interno) que produce
   un informe con: reglas **vencidas**, **sin dueño**, **sin uso** (contador a cero durante todo
   el período), **sombreadas** (nunca se alcanzan por una regla anterior), **duplicadas**,
   **redundantes** (subconjunto de otra), **generalizadas** y **excesivamente permisivas**. Cada
   hallazgo se cierra con una acción, no con un "revisado". Este informe es evidencia directa para
   `grc-compliance-standards`.
8. **Verificación de alcanzabilidad antes del merge** en topologías complejas (varios firewalls en
   camino): modelar el cambio y comprobar qué abre y qué cierra realmente, incluidas las reglas de
   otros dispositivos del camino. Es la única forma de detectar el sombreado *entre* equipos.

## 5. Seguridad

### 5.1 Registro y observabilidad de la política

- **Se loguean los `deny`, y son más importantes que los `allow`.** Un `allow` esperado no
  informa; una denegación repetida es o un ataque, o un cambio no comunicado, o una regla que
  falta. Los tres casos requieren acción.
- **Formato y campos**: prefijo estable e identificable por cadena (`IN-DENY`, `FWD-DENY`,
  `OUT-DENY`), con IP origen/destino, puertos, protocolo, interfaz y marca temporal. El prefijo es
  contrato: `detection-engineering-standards` construye reglas encima y romperlo rompe sus
  detecciones.
- **Volumen y coste son un problema de diseño, no un accidente**: un `log` sin `limit` en una
  cadena `drop` de cara a Internet es una autodenegación de servicio y una factura de SIEM. Usa
  `limit rate` siempre, agrega por `counter` lo que sólo necesitas contar, y decide qué se envía
  al SIEM y qué se queda en almacenamiento barato. Loguear todo con la misma prioridad equivale a
  no loguear nada.
- **Egress denegado es la señal de oro**: un host interno intentando salir a un destino no
  permitido es, casi siempre, o software mal configurado o algo que no debería estar ahí. Esa
  señal sólo existe si hay política de salida.
- **Contadores por regla** como fuente de la revisión de reglas sin uso (§4.7) y del
  dimensionamiento. Sin contadores, "esta regla ya no hace falta" es una opinión.

### 5.2 Contenedores: el clásico de publicar un puerto y saltarse el firewall

- **El fallo**: al publicar un puerto (`-p 5432:5432`), Docker inserta sus propias reglas de NAT
  en `prerouting` y de reenvío en `forward`. El tráfico entrante hacia el contenedor **nunca
  atraviesa `input`**, que es donde vive la política de `ufw` y de la mayoría de rulesets de host.
  Resultado: "el puerto está bloqueado" y "el puerto está abierto" son ciertos a la vez, y el
  servicio queda expuesto a la red creyendo lo contrario. **Clase de riesgo: exposición no
  intencionada por bypass de la cadena de filtrado**, no vulnerabilidad de producto.
- **Mitigaciones, en orden de preferencia**:
  1. **No publicar lo que no debe ser público**: bind explícito a loopback (`127.0.0.1:5432:5432`)
     y un proxy inverso como única superficie. La mayoría de estos incidentes se resuelven aquí.
  2. **Política en `DOCKER-USER`**, que Docker evalúa **antes** de sus propias reglas de
     aceptación: es el punto de inserción soportado con el backend iptables, y sobrevive a los
     reinicios del demonio y a la recreación de contenedores.
  3. Redes `internal` para lo que no debe salir, y `expose` en lugar de `publish` cuando basta la
     comunicación entre contenedores.
  4. Persistir tus reglas con una unidad systemd que se ejecute **después** de Docker; verificar
     con un escaneo **desde otra máquina**, nunca desde el propio host.
- **Qué ha cambiado (verificado ago-2026)**: **Docker Engine 28.0** endureció el comportamiento
  por defecto — el tráfico entrante no solicitado hacia la IP interna de un contenedor se
  descarta salvo que el puerto se haya publicado explícitamente, cerrando el caso de contenedores
  alcanzables desde la LAN con `FORWARD` en `ACCEPT`. **Sigue habiendo bypass de `input`** para
  los puertos que sí publicas: el patrón fundamental **no** ha desaparecido.
  `DOCKER_INSECURE_NO_IPTABLES_RAW=1` desactiva reglas de la tabla `raw` y **reabre** parte de ese
  endurecimiento (incluida la protección de puertos publicados en 127.0.0.1): vetado en producción.
- **Docker Engine 29** introduce backend **nftables experimental**
  (`"firewall-backend": "nftables"`), que crea sus propias tablas `ip docker-bridges` /
  `ip6 docker-bridges`, **no** crea cadena `DOCKER-USER` y **no** soporta Swarm. Traducción
  operativa: si lo activas, tu punto de inserción de política cambia y tus reglas actuales dejan
  de aplicarse. Sólo en laboratorio hasta que deje de ser experimental.
- **Trampa de distribución** (Debian 13 y equivalentes): un contenedor cuya imagen trae
  `iptables-legacy` escribiendo reglas mientras el host usa `iptables-nft` deja esas reglas en
  tablas que el kernel **no consulta**. Fallan en silencio: el operador cree que ha filtrado.
- **Kubernetes**: `kube-proxy` y el CNI generan y regeneran cadenas propias en el nodo. **No
  edites sus cadenas**; escribe tu política en tablas/prioridades propias que se evalúen antes, y
  usa `NetworkPolicy` para lo que es política de pod (`kubernetes-standards`). `kube-proxy` en
  modo nftables es GA desde 1.33 pero **iptables sigue siendo el default**, y ambos modos
  coexisten en una flota heterogénea: tu ruleset de nodo debe tolerar los dos.
- Podman/netavark: el driver nftables es el camino soportado y el de iptables está en retirada;
  verifica cuál está activo antes de escribir reglas alrededor.

### 5.3 Nubes: grupos de seguridad como equivalente lógico

- Security Groups, NSG y NACL **son política de filtrado** y les aplica **todo** este documento:
  default-deny, dueño, justificación, caducidad, revisión periódica, paridad IPv6 y despliegue por
  código. El modelo concreto y sus límites, en `aws-standards`/`azure-standards`/`gcp-standards`.
- Diferencias que cambian el diseño y que hay que tener presentes: los SG suelen ser **stateful y
  sólo de permitir** (no existe "deny explícito", lo que elimina el sombreado pero también la
  capacidad de excepcionar), las NACL son **stateless** (hay que abrir el retorno y los puertos
  efímeros a mano, error habitual), y hay **límites duros de reglas por grupo** que empujan a
  agrupar por rol —que es, además, el diseño correcto.
- **El SG no sustituye al firewall de host**: dentro del mismo grupo, el tráfico suele estar
  permitido de forma implícita. Y el `0.0.0.0/0` en un SG es exactamente el mismo hallazgo que en
  un firewall físico.

### 5.4 Plano de gestión

- La administración del firewall llega **sólo** desde la red OOB/bastión, con MFA y cuentas
  nominales; el propio firewall no expone su plano de gestión a redes de usuario ni a Internet
  (diseño OOB en `networking-standards`, identidad en
  `identity-access-management-standards`).
- **Regla de oro anti-bloqueo**: la regla que permite tu acceso de gestión es la primera que se
  escribe, la última que se toca y la que nunca depende de un cambio en curso.
- Todo cambio queda **atribuido a una persona**: aplicado por CI a partir de un PR firmado. Un
  cambio aplicado a mano en el dispositivo es, por definición, un cambio sin autor verificable.
- **Kernel y motor al día**: el propio netfilter es superficie. **CVE-2026-23111** (UAF en
  `nf_tables`, escalada local a root vía user namespaces, CVSS 7.8, publicado 13-feb-2026) exige
  kernel ≥6.18.10/6.19 o los backports 5.15.200 / 6.1.163 / 6.6.124 / 6.12.70. Mitigación
  complementaria mientras se parchea: restringir `user namespaces` sin privilegios y el acceso a
  `CAP_NET_ADMIN` (detalle de baseline en `linux-hardening-standards`).

## 6. Rendimiento y operabilidad

- **Métricas de primera clase**: ocupación de la tabla de conntrack frente a `nf_conntrack_max`
  (alerta al 70-80%: es un corte silencioso anunciado), tasa de paquetes descartados por cadena,
  contadores por regla, CPU del *softirq* de red, y latencia añadida en el camino. Recogida,
  umbrales y alertas, en `observability-standards`.
- **Coste de un ruleset mal escrito**: la evaluación es lineal por cadena. Miles de reglas
  secuenciales cuando un **set** o un **map** resolvería en tiempo constante es un problema de
  rendimiento *y* de mantenibilidad. Los sets y maps de nftables no son azúcar sintáctico: son la
  diferencia entre revisar 40 reglas y revisar 4.000.
- **Orden por frecuencia, no por estética**: `ct state established,related accept` la primera,
  siempre; lo más común, antes; lo excepcional, después. Y con `vmap` en lugar de cadenas largas
  de comparaciones cuando el criterio es un valor discreto.
- **HA**: par de firewalls con sincronización de estado (`conntrackd`/pfsync/VRRP) y failover
  **ejercitado**. Sin sincronización, cada failover corta todas las sesiones activas —a veces es
  aceptable, pero debe ser una decisión, no una sorpresa.
- **Recuperación**: el ruleset se restaura desde el repo en un equipo limpio en minutos, y eso se
  prueba (`bcdr-standards`). El backup de la configuración del dispositivo es evidencia, no
  fuente.
- **Runbooks con dueño**: bloqueo accidental del acceso de gestión, conntrack agotado, caída de un
  nodo del par HA, regla vencida que corta un servicio en producción, tráfico legítimo denegado
  tras un despliegue, apertura de emergencia (con su caducidad de ≤72 h ya incluida en la
  plantilla).

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisión de reglas trimestral en perímetro y semestral en interno (§4.7); revisión
  de versión de motor (nftables/firewalld) y de CVE de kernel/netfilter mensual; migración de todo
  lo que quede en sintaxis iptables con fecha de salida escrita.
- **Simplificación continua**: cada revisión debe **reducir** el número de reglas o justificar por
  qué crece. Un ruleset que sólo crece es un ruleset que nadie entiende ya, y un ruleset que nadie
  entiende no se puede auditar ni cambiar con seguridad.
- **Propiedad única del ruleset**: un solo gestor por host. `ufw` + `firewalld` + reglas nft
  propias + Docker peleando por el mismo ruleset produce política efectiva impredecible. Decide
  quién manda y desactiva el resto explícitamente.

**PROHIBIDO**
- ❌ Cadena base sin `policy drop`; "default-allow y ya iremos cerrando".
- ❌ Firewall sin filtrado de **egress**; "es red interna, no hace falta filtrar la salida".
- ❌ Regla sin dueño, sin justificación de negocio o sin fecha de caducidad.
- ❌ `any/any` (o `0.0.0.0/0`↔`::/0`) "temporal" sin `expires` y sin aprobación de seguridad.
- ❌ Cambiar el firewall en remoto sin sesión de rescate, consola OOB ni reversión temporizada.
- ❌ Dar por buena una política sin **prueba negativa** de que lo denegado se deniega.
- ❌ Editar reglas a mano en el dispositivo en vez de por PR + CI; dejar la deriva sin corregir.
- ❌ La configuración *running* como fuente de verdad de la política.
- ❌ Mezclar `iptables` y `nftables` en el mismo host; escribir política nueva en sintaxis iptables;
  `iptables-legacy` en sistemas nuevos.
- ❌ Varios gestores compitiendo por el ruleset (`ufw` + `firewalld` + nft + Docker).
- ❌ **Política IPv4 sin su equivalente IPv6** (el olvido más común y más explotado).
- ❌ Bloquear ICMP indiscriminadamente (mata PMTUD y el diagnóstico) o ICMPv6 (rompe ND).
- ❌ `log` sin `limit rate` en cadenas de descarte expuestas.
- ❌ No registrar las denegaciones, o no enviarlas a la ingeniería de detección.
- ❌ Filtrar contra la IP pública en reglas que se evalúan **después** del DNAT.
- ❌ Ignorar `ct state invalid`, o añadir un `accept` amplio para tapar una ruta asimétrica.
- ❌ No monitorizar la ocupación de conntrack.
- ❌ Publicar puertos de contenedor sin comprobar la exposición real **desde otra máquina**.
- ❌ `DOCKER_INSECURE_NO_IPTABLES_RAW=1` en producción; editar a mano las cadenas de Docker,
  `kube-proxy` o el CNI.
- ❌ Tratar los Security Groups del cloud como algo distinto de política de firewall.
- ❌ Confiar en NAT/masquerade como control de seguridad.
- ❌ Plano de gestión del firewall accesible desde redes de usuario o desde Internet.
- ❌ Kernel sin el parche de CVE-2026-23111 en hosts multiusuario o con contenedores no confiables.
- ❌ Cientos de reglas casi idénticas donde correspondía un set o un map.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, comportamiento o límite, **búscalo — no lo recuerdes**.
Verificado ago-2026:

- **nftables**: última upstream **1.1.6 (05-dic-2025)**; anteriores 1.1.5 (27-ago-2025) y
  1.1.4 (06-ago-2025). **firewalld 2.5.0 (08-jul-2026)**, backend nftables.
- **Migración iptables→nftables**: nftables es el framework por defecto en todas las distros
  principales; **`iptables-nft` sigue existiendo como shim** en RHEL 9/10, Debian 13 (trixie) y
  Ubuntu — **no se ha confirmado su eliminación en ninguna de ellas**, sólo su deprecación.
  Verificar en la distro **exacta** del proyecto. Trampa confirmada: contenedores con
  `iptables-legacy` sobre host `iptables-nft` escriben reglas que el kernel ignora.
- **ufw**: **no tiene backend nftables nativo**; sólo `backend_iptables.py` sobre `iptables-nft`.
  El mantenedor declara mantenimiento continuado pero sin prioridad para `backend_nft.py`.
- **Docker**: Engine **28.0** descarta tráfico entrante no solicitado a IPs de contenedor salvo
  puerto publicado; el bypass de `input` para puertos publicados **persiste**;
  `DOCKER_INSECURE_NO_IPTABLES_RAW=1` desaconsejado. Engine **29** añade
  `"firewall-backend": "nftables"` **experimental** (tablas `ip docker-bridges`/`ip6
  docker-bridges`, **sin `DOCKER-USER`**, **sin Swarm**).
- **Kubernetes**: `kube-proxy` modo nftables **GA en 1.33**, requiere kernel ≥5.13, **no es el
  default** (iptables lo sigue siendo, sin fecha anunciada de cambio); **IPVS deprecado en 1.35**.
- **CVE**: **CVE-2026-23111** — UAF en `nf_tables` (`nft_map_catchall_activate()`, comprobación
  invertida), LPE local vía user namespaces, **CVSS 7.8 (AV:L/AC:L/PR:L/UI:N/C:H/I:H/A:H)**,
  publicado 13-feb-2026. Parcheado en **≥6.18.10 y 6.19**, backports **5.15.200, 6.1.163,
  6.6.124, 6.12.70**. Re-verificar CVE de netfilter del mes en curso antes de fijar mínimo.

**Huecos declarados — NO rellenar de memoria, verificar antes de usar**:
1. **Versión de nftables empaquetada por distro**: sólo consta 1.1.4 en Fedora 44 (heredado de
   `networking-standards`, no re-verificado). Las versiones en RHEL 10, Debian 13 y Ubuntu LTS
   **no están verificadas**.
2. **Versión concreta de `ufw`** vigente en 2026: **no obtenida**. Comprobar con `ufw --version`
   o en la página del paquete de la distro.
3. **Herramientas de auditoría de ruleset**: existe `audit-springbok` (taxonomía de anomalías:
   sombreado, redundancia, generalización, correlación) y Batfish para verificación de
   alcanzabilidad pre-merge, pero **no se ha encontrado ningún analizador de sombreado/redundancia
   nativo para nftables**, y **el mantenimiento y la versión actual de ambas herramientas no están
   verificados**. No las recomiendes como producto sin comprobarlo; la taxonomía de anomalías de
   §4.7 sí es válida como criterio.
4. **Detalle del modelo de Security Groups/NSG/NACL** (límites de reglas, semántica exacta de
   stateful, soporte IPv6): descrito a nivel de criterio, **no verificado contra la documentación
   vigente de cada proveedor**. Contrastar con `aws-standards`/`azure-standards`/`gcp-standards`.
5. **Estado del driver iptables en Podman/netavark** (¿deprecado o ya eliminado?, en qué versión):
   sólo consta la intención declarada por un mantenedor. Verificar antes de afirmarlo.
6. **Sintaxis exacta y disponibilidad de `--check-config` en firewalld 2.5.0**: citada de memoria,
   **no verificada**.
7. **Estado de conntrackd/pfsync y de las opciones de sincronización de estado** en las
   plataformas de perímetro concretas: no verificado en esta pasada.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
