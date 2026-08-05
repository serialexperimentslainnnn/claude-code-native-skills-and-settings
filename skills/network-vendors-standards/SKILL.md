---
name: network-vendors-standards
description: What actually changes when the box has a different logo — vendor operating models, licensing, lifecycle and vendor risk. Use when working with Cisco IOS / IOS-XE / NX-OS / IOS-XR and deciding which one a platform runs, Cisco EEM applets and event manager, Smart Licensing Using Policy (SLP), SLAC authorization codes, CSSM, CSLU, "license smart url", "show license all", Catalyst Center (formerly DNA Center), Junos OS and its candidate configuration, "commit check", "commit confirmed", "rollback 3", "show | compare", "load replace", apply-groups and apply-path, Junos Evolved, Arista EOS, SysDB and NetDB, CloudVision / CVaaS / CVP and ZTP as a service, EOS extensions and "config session", MikroTik RouterOS 7 and Winbox, RouterOS package channels and "/system package update", Huawei VRP and its regulatory status as a high-risk supplier, Nokia SR Linux or SR OS, FortiOS or PAN-OS acting as a WAN router rather than a firewall, choosing single-vendor versus multivendor and pricing the lock-in, TAC and RMA contract coverage, PSIRT and security advisory subscription as a process, EoS/EoL and last-date-of-support milestones, or a vendor acquisition that changes the roadmap under you.
---

# Estándares de proveedores de red — el bloqueo está en el modelo operativo, no en el CLI

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando **la decisión depende de quién fabrica la caja**: qué sistema operativo de red corre
cada plataforma y qué implica; el modelo de configuración del vendor (transaccional frente a
inmediato) y qué operación segura permite; el **licenciamiento** y qué deja de funcionar cuando
caduca; el ciclo de vida del firmware y los hitos EoS/EoL; el consumo de avisos **PSIRT** como
proceso, no como lectura ocasional; los contratos de soporte, TAC y RMA y qué cubren de verdad;
el **riesgo de proveedor** (adquisiciones, restricciones regulatorias, discontinuación de línea); y
el criterio de **estandarizar en un vendor frente a multivendor**, con el coste real de cada opción.

Triggers: `IOS-XE`, `NX-OS`, `IOS-XR`, `Junos`, `Junos Evolved`, `EOS`, `RouterOS`, `VRP`,
`SR Linux`, `SR OS`, `FortiOS`, `PAN-OS`; `event manager applet`, `commit confirmed`,
`commit check`, `rollback`, `apply-groups`, `config session`, `show license all`,
`license smart url`, SLAC, CSSM, CSLU, Catalyst Center, CloudVision/CVaaS, Winbox, ZTP;
"EoS", "LDoS", "PSIRT", "TAC", "RMA", "renovación de licencias", "cambio de fabricante".

**No aplica** — el catálogo ya reparte esto: `networking-standards` es la **troncal**
(direccionamiento, VLAN, MTU, plano OOB, elección de plataforma de perímetro) y **ya delega la
profundidad**; `routing-switching-standards` decide **qué debe decir** la configuración de campus y
borde (STP, MLAG, VRRP, política BGP, RPKI, CoPP, AAA — aquí sólo **en qué se traduce** eso en cada
SO); `datacenter-fabric-standards` decide la malla (Clos, VXLAN/EVPN);
`network-automation-standards` decide **cómo se genera, se prueba y se aplica** un cambio (Ansible,
NAPALM, NETCONF/YANG, gNMI, containerlab, detección de drift — aquí sólo **qué expone cada vendor**
y con qué fidelidad); `firewall-policy-standards` (la política de filtrado como artefacto, incluido
FortiOS/PAN-OS **como firewall**); `wireless-standards` (WLAN y controladoras);
`load-balancing-standards`, `vpn-standards`, `dns-standards`, `network-troubleshooting-standards`
(método reactivo). Hacia fuera: `vulnerability-management-standards` (**triaje y SLA de parcheo**;
aquí sólo la **suscripción y el consumo** del feed PSIRT), `wan-legacy-standards` (MPLS, SD-WAN y
circuitos heredados), `telco-5g-standards` (equipo de operador),
`high-speed-interconnect-standards` (InfiniBand/RoCE), `edge-computing-standards`,
`finops-standards` (modelo de coste plurianual),
`opensource-licensing-standards` (licencias de software libre — **el licenciamiento de red es
contractual, no OSS**), `grc-compliance-standards` (due diligence de proveedor como control),
`offensive-security-standards` (**esta skill es defensiva**).

## 2. Decisiones por defecto

> Verificar la última versión, el estado EoS/EoL y el nombre exacto de cada producto por web antes
> de fijarlo en un proyecto real (§8). **Los nombres comerciales cambian sin cambiar el producto**:
> Cisco renombró DNA Center a **Catalyst Center** y Viptela SD-WAN a **Catalyst SD-WAN** en 2023;
> la documentación antigua sigue usando los nombres viejos.

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Criterio primario de elección | **Modelo operativo** (transaccionalidad, API, telemetría, lifecycle) | Precio de compra, sólo si el TCO a 5 años lo respalda |
| Nº de vendors en el core | **Uno**, salvo justificación explícita | Dos, si el riesgo de proveedor lo exige (§7) |
| Nº de vendors por dominio (campus / DC / WAN) | Uno por dominio, con **frontera clara** en la interconexión | Multivendor dentro de un dominio: **casi nunca compensa** |
| Interfaz de cambio | **NETCONF/YANG o gNMI** si el vendor lo soporta bien | CLI estructurada (`| display xml`, `| json`) — *screen scraping* sólo como último recurso |
| Ventana de rollback | **Commit confirmado con temporizador** siempre que el SO lo ofrezca | Fuera de banda + reload programado si no lo ofrece |
| Cadencia de firmware | Release **con soporte extendido/long-lived** del vendor, no la última | Release nueva sólo si arregla un CVE explotado o una feature contratada |
| Suscripción PSIRT | **Obligatoria** para todo vendor en producción, con dueño nombrado | — |

### Qué es cada sistema operativo (y dónde vive)

- **Cisco IOS / IOS-XE** — el linaje de campus y sucursal. IOS-XE es IOS clásico reempaquetado sobre
  un kernel Linux con separación de planos: soporta `guestshell`, contenedores de aplicación, YANG y
  telemetría. Catalyst 9000, ISR/ASR 1000, y Catalyst 8000 corren IOS-XE.
- **Cisco NX-OS** — la línea de centro de datos (Nexus). Modelo modular con procesos reiniciables,
  `feature <x>` para activar funciones, y VDC/VRF. No comparte comandos con IOS-XE más allá de la
  apariencia; **asumir que sí es el error clásico**.
- **Cisco IOS-XR** — la línea de proveedor de servicio y core (ASR 9000, NCS). **Es el único de los
  tres con modelo de configuración transaccional real**: `commit`, `commit confirmed`, `show
  configuration commit changes`, `rollback configuration`. Si el equipo viene de IOS-XE, el modelo
  mental cambia por completo.
- **Junos OS / Junos Evolved** — un solo SO en toda la gama, con el mejor modelo de configuración
  del sector (véase abajo). Evolved es la reescritura sobre Linux nativo; **la CLI se parece pero la
  paridad de features no es total**: verificar por plataforma.
- **Arista EOS** — un solo binario para toda la gama, sobre Linux estándar, con **SysDB** como base
  de datos de estado en memoria y publish/subscribe entre agentes. La consecuencia práctica: un
  agente que muere se reinicia y **relee su estado de SysDB** sin tirar el resto del sistema. CVP /
  CVaaS agrega el SysDB de toda la red (NetDB/NetDL).
- **MikroTik RouterOS 7** — Linux con una capa propia. Coste por prestación imbatible; modelo
  operativo y postura de seguridad **muy por debajo** del resto (§5).
- **Huawei VRP** — SO propio, funcionalmente competente y barato. El problema no es técnico: es
  **regulatorio y de continuidad** (§5).
- **Nokia SR Linux / SR OS**, **FortiOS**, **PAN-OS** — SR Linux es notable por su modelo abierto
  (gNMI/YANG de primera clase). FortiOS y PAN-OS **hacen de router** en sucursales; aquí sólo eso,
  su política de filtrado es de `firewall-policy-standards`.

## 3. Estructura y convenciones

### El modelo de configuración es lo que decide la operabilidad

El **candidate config + commit confirmado** de Junos es la mejor idea que ha producido la industria
de redes, y la razón es concreta: **desacopla escribir de aplicar, y aplicar de confirmar**.

- Se edita una **configuración candidata** que no afecta al equipo. Errores de sintaxis y de
  semántica se detectan antes de tocar nada (`commit check`).
- `show | compare` da el **diff exacto** de lo que va a cambiar. No hay que adivinar el estado
  resultante.
- `commit confirmed` aplica y arma un temporizador; si no se confirma con un segundo `commit`, el
  equipo **revierte solo**. **El valor por defecto son 10 minutos, configurable de 1 a 65 535**
  (Juniper, *Commit the Configuration*, CLI User Guide). Esto elimina la clase entera de incidentes
  "me cerré el acceso a mí mismo".
- **Rollback numerado**: `rollback 0..49` recupera configuraciones anteriores completas, y
  `rollback rescue` una marcada como buena. No es un backup externo: vive en el equipo.
- **Apply Groups** (`groups` + `apply-groups`, con `apply-path` para derivar listas de otra parte de
  la config) aplican configuración común por herencia. Reducen repetición, pero **oscurecen la
  configuración efectiva**: revisar siempre con `show configuration | display inheritance`.

Traducción a los demás:

| Capacidad | Junos | IOS-XR | EOS | NX-OS / IOS-XE | RouterOS |
|---|---|---|---|---|---|
| Config candidata | Sí, nativa | Sí, nativa | `configure session` | Parcial (`config replace`, `configure exclusive`) | No |
| Diff antes de aplicar | `show \| compare` | `show configuration` | `show session-config diffs` | `show archive config differences` | No |
| Commit confirmado | Sí (10 min por defecto) | Sí | `commit timer` en sesión | `configure replace` + `reload in` como sucedáneo | No |
| Rollback numerado | 0–49 + `rescue` | Sí | Instantáneas de sesión | `archive` con ficheros | Backups manuales |

**Criterio**: en un equipo sin commit confirmado, **todo cambio remoto de riesgo lleva un `reload
in <n>` armado antes de tocar nada**, y se cancela al verificar. No es opcional.

### Automatización on-box: útil, y trampa de mantenimiento

- Cisco **EEM** (`event manager applet`, con `event syslog`, `event timer`, `event none`, y
  acciones `cli`, `syslog`, `mail`) permite reaccionar a eventos en el propio equipo. Es
  legítimo para **contención inmediata** (deshabilitar un puerto que aletea) y para *self-healing*
  acotado.
- ❌ **PROHIBIDO** usar EEM (o scripts on-box equivalentes: Junos `op`/`event-options`, EOS
  extensions, RouterOS scheduler) como **sustituto de la automatización externa**. Un applet en 300
  equipos es lógica sin control de versiones, sin tests y sin inventario. Todo script on-box lleva
  dueño, se genera desde la plantilla y se audita como configuración.

### Qué se puede automatizar de verdad, por vendor

El eje real no es "¿tiene NETCONF?" sino **¿el modelo YANG cubre lo que necesito configurar, y el
estado operacional se puede leer sin parsear texto?**

- **Cobertura de modelo**: OpenConfig es la promesa; la realidad es que casi todo lo interesante
  acaba en modelos **nativos** del vendor. Verificar caso a caso qué subárbol está soportado.
- **Estado operacional**: gNMI `Subscribe` (telemetría por streaming) sustituye a SNMP; comprobar
  qué *paths* emite el equipo y a qué cadencia. Sin esto no hay observabilidad de red decente.
- **Fidelidad del `commit`**: NETCONF con `confirmed-commit` (RFC 6241) sólo vale si el equipo lo
  implementa de verdad; muchos anuncian NETCONF y por debajo hacen CLI.
- ❌ **PROHIBIDO** basar un plan de automatización en **screen scraping** de la CLI como estrategia
  de destino. Es aceptable como puente para equipo heredado, con expectativa de vida y fecha de
  salida escritas; nunca como diseño.

## 4. Calidad y verificación

- **Antes de comprar**: exigir al fabricante, por escrito, (a) la matriz de soporte YANG/gNMI de la
  plataforma exacta, (b) la fecha de EoS/LDoS del modelo, (c) el compromiso de duración de la rama
  de firmware, y (d) el SLA de RMA en la geografía real de la instalación. **Sin las cuatro, no hay
  decisión, hay apuesta.**
- **Prueba de fuego previa a estandarizar**: reproducir el cambio más peligroso que se hará en
  producción (cambio de política de borde, actualización de firmware con reinicio) en un laboratorio
  virtual del propio vendor, midiendo el tiempo de reversión real. Si el vendor no ofrece imagen
  virtual utilizable, **eso ya es un dato de la decisión**.
- **Validación de configuración**: `commit check` (Junos), `configure session` + `show session-config
  diffs` (EOS), `nft`-equivalente no existe aquí — el gate es del vendor. La verificación
  independiente (Batfish, pyATS/Genie) y los tests de la tubería son de `network-automation`.
- **Inventario de firmware como dato consultable**: modelo, versión, fecha de EoS y fecha del último
  aviso PSIRT aplicado, en la fuente de verdad. Un parque sin este inventario **no puede responder**
  a un aviso crítico en el plazo que exige `vulnerability-management-standards`.

## 5. Seguridad y riesgo de proveedor

### PSIRT como proceso, no como noticia

- Suscribirse a los canales oficiales de **todos** los fabricantes en producción y **enrutarlos a
  una cola con dueño**: Cisco Security Advisories (openVuln API), Juniper JSA, Arista Security
  Advisories, Fortinet PSIRT, Palo Alto Security Advisories, MikroTik `mikrotik.com/supportsec`.
- El disparador de acción no es la publicación: es el **triaje** (¿la plataforma está afectada? ¿la
  feature vulnerable está habilitada? ¿está expuesta?). El SLA y la priorización (CVSS + EPSS + KEV)
  son de `vulnerability-management-standards`; **el compromiso de aquí es que el aviso llegue y
  tenga dueño**.
- ❌ **PROHIBIDO** operar un equipo de red cuya rama de firmware ya no recibe correcciones de
  seguridad y que esté expuesto a una red no confiable. Si no se puede actualizar, se aísla.

### MikroTik: el mejor precio del mercado y la peor exposición

RouterOS ofrece prestaciones de gama alta a precio de gama baja, y eso lo convierte en el equipo más
desplegado por gente sin operación de red detrás. El resultado es medible:

- CISA ha emitido avisos ICS sobre RouterOS y Cloud Hosted Router en 2026 — entre otros
  **ICSA-26-211-01 (CVE-2026-14227**, expiración insuficiente de sesión en la API, con extracción de
  la clave privada de WireGuard desde una sesión de bajo privilegio) e **ICSA-26-209-05
  (CVE-2026-16347**, ausencia de protección frente a fuerza bruta en la autenticación de la API).
  **Verificar el estado de parcheo por web (§8): al recogerse este dato no constaba parche.** La
  API escucha en TCP 8728/8729.
- El patrón histórico es constante y no es de CVE: **interfaz de gestión expuesta a Internet**.
  Las campañas de botnet sobre MikroTik (Mēris y sucesoras) han reutilizado equipos comprometidos
  años antes, donde **actualizar no bastaba** porque las credenciales ya estaban robadas y quedaban
  scripts y reglas del atacante en el equipo.
- **Criterio operativo**: si se usa MikroTik, (a) gestión **sólo** por OOB o VPN, nunca expuesta;
  (b) Winbox/API/SSH/WWW restringidos por `address-list`; (c) tras cualquier sospecha de
  compromiso, **reinstalación limpia y rotación de credenciales**, no actualización; (d) revisión
  explícita de `/system scheduler`, `/system script`, usuarios y reglas NAT/firewall no reconocidas.
- ❌ **PROHIBIDO** desplegar MikroTik en un borde crítico sin dueño operativo asignado. El ahorro
  de la compra se lo come el primer incidente.

### Huawei: el riesgo no es técnico

- La UE llevaba desde 2020 con el **5G Toolbox** como recomendación **no vinculante**, aplicada de
  forma desigual: **menos de la mitad de los 27 Estados miembros** habían usado poderes legales para
  imponer restricciones. El paquete de ciberseguridad presentado por la Comisión el **20 de enero de
  2026** propone convertir esas medidas en **obligatorias**, con retirada escalonada del equipo de
  proveedores de alto riesgo y extensión del alcance más allá del 5G (fibra incluida).
  **Es una propuesta legislativa, no derecho aplicable todavía**: los plazos de adopción y de
  transposición son el dato que hay que verificar (§8), y **varían por país**.
- **Criterio**: para infraestructura con vida útil de 7–10 años, la pregunta no es si Huawei
  funciona (funciona), sino **si el marco regulatorio del país de despliegue permitirá amortizarla**.
  Un mandato de retirada convierte una compra barata en una migración no presupuestada.
- Este mismo razonamiento aplica a **cualquier** proveedor sujeto a control de exportación o a
  restricción sectorial. Es análisis de riesgo, no geopolítica.

### Adquisiciones: el roadmap cambia bajo los pies

- **HPE cerró la compra de Juniper Networks el 2 de julio de 2025**, por unos 13 400 M USD; JNPR
  dejó de cotizar. El DOJ impuso condiciones (desinversión de Instant On y subasta de licencia no
  exclusiva del código fuente de Mist AI). Juniper opera como filial y su ex-CEO dirige la división
  de red de HPE, que mantiene ambas marcas.
- **Qué significa para una decisión de compra**: Junos como SO no se evapora, pero **las líneas
  solapadas con Aruba son las candidatas naturales a racionalización**. Antes de estandarizar en una
  gama concreta, exigir por escrito el compromiso de roadmap y las fechas de EoS de **ese** modelo.
  Verificar el estado actual por web (§8): las decisiones de portfolio post-fusión se anuncian en
  goteo.
- La cláusula general: **toda estandarización en un vendor debe llevar escrito qué se hace si el
  vendor es comprado, discontinúa la línea o queda restringido**. Sin ese párrafo, la
  estandarización es una apuesta sin cobertura.

### Licenciamiento: qué deja de funcionar cuando caduca

- **Cisco Smart Licensing Using Policy (SLP)** es **obligatorio desde IOS-XE 17.3.2** (Smart
  Licensing fue obligatorio de 16.10.1a a 17.3.1, y opcional entre 16.5.1 y 16.9.8). SLP eliminó el
  PAK y el registro previo: **no se requiere registro ni generación de claves salvo para licencias
  *export-controlled* o *enforced***. Transportes: `smart` (HTTP directo a Cisco), `cslu` (mediado
  por CSLU on-premise) y offline para redes aisladas; `call-home` está en retirada y no debe usarse
  en versiones nuevas. Para licencias controladas o caudal >250 Mbps hace falta instalar un
  **SLAC**.
- **Consecuencia operativa** que se ignora hasta que duele: una red aislada necesita un plan de
  reporte de uso de licencia (CSLU o fichero offline) **desde el día uno**. Verificar `show license
  all` / `show license status` como parte del inventario, no cuando salta el aviso.
- **Regla transversal**: antes de comprar, exigir por escrito **qué funciones se degradan o se
  bloquean** al expirar la licencia o al perder conectividad con el servidor de licencias, y **cómo
  se comporta un equipo que reinicia sin poder validar**. Es la diferencia entre un aviso en el log
  y una sucursal caída.
- ❌ **PROHIBIDO** dimensionar un presupuesto de red contando sólo el CAPEX del hardware. La
  suscripción plurianual, el soporte y la renovación son parte del precio (`finops-standards`).

## 6. Operabilidad — soporte, RMA y ciclo de vida

- **Los hitos que importan** (nombres exactos varían por vendor; verificar §8): anuncio de fin de
  venta (EoS), última fecha de pedido, fin de mantenimiento de software, fin de soporte de
  vulnerabilidades y **última fecha de soporte (LDoS)**. El único que decide es el **fin de
  correcciones de seguridad**: a partir de ahí el equipo es deuda con fecha.
- **Contrato de soporte**: verificar el nivel real contratado (tiempo de respuesta ≠ tiempo de
  reposición), la cobertura geográfica del stock de RMA y si incluye acceso a descargas de software.
  **En varios fabricantes, sin contrato vigente no se puede descargar ni el parche de seguridad** —
  eso convierte la renovación en un control de seguridad, no en un gasto administrativo.
- **Repuestos**: para equipos de borde sin RMA de 4 h en la ubicación real, el repuesto frío en sitio
  suele ser más barato que subir el nivel de contrato. Decidirlo con el RTO, no con el catálogo.
- **Equipo de segunda mano / gris**: legítimo para laboratorio y repuesto frío. ❌ PROHIBIDO en
  producción crítica: sin cobertura de soporte, sin garantía de procedencia del firmware y con
  riesgo de cadena de suministro.

### Estandarizar en un vendor frente a multivendor — el coste real

| Eje | Un vendor | Multivendor |
|---|---|---|
| Coste operativo | **Menor**: una curva de aprendizaje, un modelo de commit, una tubería | Mayor: cada SO es un conjunto de plantillas, tests y modos de fallo |
| Poder de negociación | Se degrada con el tiempo; el vendor lo sabe | **Mejor**, si es creíble (hay que poder cambiar de verdad) |
| Riesgo de fallo correlacionado | **Alto**: un CVE crítico afecta al parque entero a la vez | Menor, a cambio de más superficie total |
| Riesgo de proveedor (compra, EoL, regulación) | Concentrado | Diversificado |
| Automatización | Sencilla y de alta fidelidad | Exige abstracción real (NetBox + plantillas por plataforma), no un `if vendor ==` |

**Criterio por defecto**: **un vendor por dominio** (campus, DC, WAN), con fronteras protocolares
estándar en la interconexión. Multivendor *dentro* de un dominio sólo se justifica si el segundo
vendor está **operado de verdad** — no comprado "por si acaso". Un vendor secundario que nadie sabe
configurar no diversifica riesgo: lo aumenta.

**El bloqueo de proveedor real no está en el CLI.** Cambiar de sintaxis es una semana de trabajo. Lo
que ata es todo lo demás: la fuente de verdad modelada según el modelo de datos del vendor, las
plantillas, la plataforma de gestión (Catalyst Center, CVP, Mist, Apstra) con su inventario y sus
flujos, el conocimiento operativo del equipo, los contratos plurianuales y las features propietarias
sin equivalente estándar. **Toda decisión de comprar la plataforma de gestión del vendor debe
evaluarse como decisión de bloqueo**, no como accesorio del hardware.

## 7. Sostenibilidad y prohibiciones

- Refrescar el inventario de EoS/LDoS **cada trimestre** y presupuestar la sustitución **con dos
  años de antelación** al fin de correcciones de seguridad. Descubrirlo el mismo año es cómo se
  acaba parcheando por excepción.
- Congelar la rama de firmware por dominio y actualizar por ventana planificada, no por equipo.
  Salir de esa cadencia sólo por CVE explotado o requisito contractual.
- Documentar en un ADR (`software-architecture-patterns-standards`) la decisión de vendor con su
  fecha, su alternativa descartada y **la condición que la reabriría** (adquisición, EoL de la gama,
  cambio regulatorio, subida de precio por encima de un umbral).

Prohibiciones:

- ❌ **PROHIBIDO** escribir de memoria una versión, una fecha de EoS/LDoS, un nombre de feature, un
  nivel de licencia o un identificador de CVE. Se verifica en la web del fabricante (§8).
- ❌ **PROHIBIDO** aplicar un cambio remoto de riesgo sin ventana de reversión armada (commit
  confirmado o `reload in`).
- ❌ **PROHIBIDO** exponer a Internet la gestión de un equipo de red (Winbox, HTTP/HTTPS de
  administración, API, SSH sin restricción de origen). Gestión por OOB o VPN.
- ❌ **PROHIBIDO** desplegar con credenciales, comunidades SNMP o certificados de fábrica. Y
  **prohibido documentar credenciales por defecto de terceros** en este catálogo: si hacen falta, se
  consultan en la documentación del fabricante en el momento del despliegue y se cambian.
- ❌ **PROHIBIDO** operar un vendor en producción sin suscripción PSIRT con dueño nombrado.
- ❌ **PROHIBIDO** tratar el screen scraping de CLI como arquitectura de destino de automatización.
- ❌ **PROHIBIDO** desplegar firmware descargado de un origen que no sea el fabricante, o sin
  verificar su firma/hash publicado.
- ❌ **PROHIBIDO** estandarizar en un vendor sin cláusula escrita de qué se hace ante adquisición,
  discontinuación o restricción regulatoria.
- ❌ **PROHIBIDO** citar cifras de TCO, "ahorro por automatización" o cuota de mercado procedentes
  de material comercial del fabricante sin metodología publicada. Si no hay metodología, se dice que
  no la hay.

## 8. Verificación web obligatoria

Comprobar **siempre** antes de decidir, en la fuente primaria del fabricante o del regulador:

1. **Versión y rama de firmware** recomendada para la plataforma exacta (no la familia), y si es
   rama de soporte extendido.
2. **Hitos de ciclo de vida** del modelo concreto: EoS, fin de mantenimiento de software, **fin de
   correcciones de seguridad** y LDoS. Cisco EoL Notices, Juniper EOL, Arista lifecycle policy.
3. **Avisos PSIRT abiertos** para la plataforma y la versión, y si hay parche disponible. En
   particular, **el estado de parcheo de los avisos de RouterOS citados en §5 (CVE-2026-14227,
   CVE-2026-16347): al recogerse este documento no constaba parche del fabricante.**
4. **Estado regulatorio del proveedor** en el país de despliegue: la propuesta de la Comisión de
   **20 de enero de 2026** que hace vinculante el 5G Toolbox, su estado de tramitación, sus plazos
   de retirada y **la norma nacional aplicable**, que difiere por Estado miembro.
5. **Estado del portfolio post-adquisición HPE–Juniper** (cierre: 2 de julio de 2025): qué gamas se
   mantienen, cuáles se racionalizan y con qué fechas.
6. **Modelo y política de licencias vigente**: umbral de versión donde SLP es obligatorio, qué
   requiere SLAC, qué transportes siguen soportados y **qué se degrada al expirar**.
7. **Cobertura real de YANG/gNMI** de la plataforma: matriz de modelos soportados y *paths* de
   telemetría publicados.
8. **Nombres comerciales actuales** — se renombran sin avisar (DNA Center → Catalyst Center; Viptela
   → Catalyst SD-WAN). Escribir el nombre viejo hace que la documentación no se encuentre.

**Huecos declarados**: (a) el estado de parcheo de los avisos MikroTik de julio de 2026 no se pudo
confirmar en fuente primaria — `cisa.gov` devolvió HTTP 403 al intentar la cita verbatim, y el dato
procede de resumen de búsqueda; **verificar en `mikrotik.com/supportsec` antes de actuar**. (b) Las
fechas de adopción y transposición del paquete de ciberseguridad de la UE no se verificaron en el
texto oficial: se conoce la fecha de presentación, no el calendario en vigor. (c) No se verificaron
matrices de EoS/LDoS de modelos concretos: dependen de plataforma y no se escriben de memoria.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
