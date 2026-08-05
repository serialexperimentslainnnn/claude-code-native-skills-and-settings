---
name: bsd-systems-standards
description: FreeBSD, OpenBSD and NetBSD as deliberate production choices, and their derivatives. Use when working with FreeBSD (freebsd-update, pkg install/upgrade with quarterly or latest branches, ports tree and make.conf, /etc/rc.conf, sysrc, service(8), bectl boot environments, zfs and zpool on FreeBSD, jail(8) and /etc/jail.conf, ezjail, iocage, BastilleBSD, AppJail, vnet jails, bhyve and vm-bhyve, pf.conf and pfctl, CARP, netgraph, dtrace on FreeBSD, kldload, loader.conf, FreeBSD RELEASE/STABLE/CURRENT branches), OpenBSD (syspatch, sysupgrade, pkg_add, /etc/pf.conf and pfctl -sr, pledge(2) and unveil(2), relayd, httpd, smtpd, iked, doas and doas.conf, rcctl, W^X, KARL, retguard, errata patches, signify), NetBSD (pkgsrc, bmake, npf.conf, sysinst, rump kernels), and their derivatives pfSense CE or Plus, OPNsense, TrueNAS CORE, FreeNAS, HardenedBSD, GhostBSD or DragonFly BSD — including deciding which BSD to use, or whether to use one at all.
---

# Estándares de sistemas BSD

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**BSD no es legacy: es una familia viva que se elige por razones concretas**, y esta skill existe
para fijar cuáles. Confundirla con el Unix propietario heredado es el error de encuadre: aquí nadie
"se quedó" en BSD — alguien lo eligió, y hay que poder defender por qué.

Las tres tienen releases nuevas en 2026, políticas de soporte **distintas entre sí** (§2) y un caso
de uso propio y estrecho:

- **FreeBSD** — la de propósito general: **ZFS de primera clase, jails, `bhyve` y `pf`**. Su caso
  fuerte es **almacenamiento y red**: un servidor de ficheros ZFS, un cortafuegos con estado, un
  encaminador, un servidor de virtualización pequeño. Fuera de ahí compite de tú a tú con Linux y
  suele perder por ecosistema (§7).
- **OpenBSD** — la de superficie mínima: **seguro por defecto**, `pledge`/`unveil`, y **origen de
  `pf`**. Su caso fuerte es el **cortafuegos/VPN y el servicio expuesto y pequeño** (relay, DNS
  autoritativo, correo, salto SSH). No es una plataforma de aplicación general y no pretende serlo.
- **NetBSD** — la portable. **Acótalo**: su argumento es correr en arquitecturas que nadie más
  cubre y `pkgsrc` como árbol de paquetes multiplataforma. En un centro de datos x86/ARM corriente
  **no hay ninguna razón para elegir NetBSD sobre FreeBSD**; decirlo es parte del criterio.

Cubre: estado y política de soporte de cada una (§2); convenciones de FreeBSD que deciden la
operación (§3); jails frente a contenedores Linux y `pf` frente a `nftables` (§4); qué enseña
OpenBSD aunque no lo despliegues (§5); operabilidad y el ecosistema derivado —pfSense, OPNsense,
TrueNAS— (§6); y **cuándo no elegir BSD** (§7).

**No aplica**:
- `linux-administration-standards`, `rhel-fedora-standards`, `linux-hardening-standards`,
  `linux-storage-standards` y `zfs-standards` (**ya escritas**): **Linux y ZFS son suyos** — el
  diseño de `zpool`, RAIDZ, snapshots, replicación y ajuste de ARC es de `zfs-standards`; **aquí
  solo lo específico de ZFS en FreeBSD** (entornos de arranque, ZFS como raíz, integración con
  jails).
- `firewall-policy-standards` (**ya escrita**): **suya la política de filtrado** —qué se permite,
  zonas, default-deny, revisión de reglas—; aquí solo **`pf` como motor** y qué implica elegirlo.
- `networking-standards`, `vpn-standards`, `dns-standards` (los protocolos y su diseño).
- `onprem-standards` (**paraguas de plataforma con la tabla de enrutado**), `homelab-standards`
  (**suyo el laboratorio doméstico**, donde pfSense/OPNsense y TrueNAS son vecinos naturales; aquí
  el criterio de sistema operativo y licencia), `ha-clustering-standards`,
  `backup-recovery-standards`, `bcdr-standards`, `os-provisioning-standards`,
  `server-hardware-standards`, `identity-access-management-standards`,
  `secrets-management-standards`, `vulnerability-management-standards`,
  `detection-engineering-standards` (**suya la detección en el endpoint y sus reglas**),
  `endpoint-security-standards`, `grc-compliance-standards`, `iac-standards`,
  `legacy-modernization-standards` y `migration-projects-standards`.
- `podman-systemd-containers-standards` y `kubernetes-standards`: **el ecosistema de contenedores
  es suyo**; aquí solo la comparación honesta con jails (§4).
- `aix-solaris-hpux-standards` y `macos-fleet-standards`: **BSD no es Unix propietario** —no se
  hereda, se elige, y no tiene contrato de proveedor detrás— **y macOS no es una flota de
  servidores**, aunque comparta ascendencia BSD. El nombre "Unix" las junta y no comparten casi
  nada operativo.

## 2. Estado y política de soporte verificados

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Sistema | Vigente a ago-2026 | Política de soporte (verificada) |
|---|---|---|
| **FreeBSD** | **15.1-RELEASE** (16-jun-2026); 14.4-RELEASE (10-mar-2026) | *"Each minor release is only supported for three months after the next minor release within the same major version"*. **`stable/15` hasta 31-dic-2029; `stable/14` hasta 30-nov-2028.** Desde FreeBSD 15: *"each stable branch is explicitly supported for 4 years from its dot-zero release"* (antes eran 5) |
| FreeBSD — fechas cortas | 15.0 termina **30-sep-2026**; 14.4 termina **31-dic-2026**; 15.1 termina **31-mar-2027** | **La release menor caduca rápido**: se planifica actualizar dentro de la rama cada pocos meses, no cada año |
| **OpenBSD** | **7.9** (actual) y **7.8** (anterior) | **Solo las dos últimas releases reciben errata**; `-stable` se mantiene un año. Cadencia semestral ⇒ **una actualización de sistema cada seis meses, obligatoria y sin excepción** |
| **NetBSD** | **11.0** (ago-2026); rama 10.x mantenida | Una release mayor deja de estar soportada **un mes después de la segunda mayor posterior**. NetBSD 8 y anteriores, EOL |

**Lo que decide de esa tabla**: FreeBSD tiene ramas largas (4 años) pero releases menores muy
cortas; OpenBSD no tiene rama larga en absoluto y **te obliga a una cadencia de seis meses**. Si tu
organización no puede sostener dos actualizaciones al año de un sistema, **OpenBSD está descartado
antes de mirar sus virtudes**. Ese es el filtro real, no la lista de mitigaciones.

**Ecosistema derivado, con licencia leída en crudo:**

| Producto | Licencia | Estado |
|---|---|---|
| **pfSense CE** | **Apache License 2.0** — verificado leyendo el `LICENSE` del repositorio en crudo (encabezado literal: *"Apache License / Version 2.0, January 2004"*) | Base FreeBSD. **Marca registrada restringida por Netgate**: la licencia del código no te autoriza a redistribuir bajo el nombre |
| **pfSense Plus** | **Propietario, sin código fuente público** | Producto distinto, no una edición del anterior. Gratis sobre hardware Netgate; sobre hardware de terceros exige suscripción (§8: precio no verificado en fuente oficial) |
| **OPNsense** | **BSD 2-Clause** — verificado leyendo el `LICENSE` del repositorio `opnsense/core` en crudo | Base FreeBSD, mantenido por Deciso. **Todo el código, incluida la interfaz y los plugins, bajo la misma licencia**; la *Business Edition* es el mismo código con soporte y rama conservadora |
| **TrueNAS** | — | **Dejó de ser un producto BSD.** La línea viva es Linux (25.10 "Goldeye"); **TrueNAS CORE está en sostenimiento**, sin base FreeBSD 14, última entrega 13.3-U1.2 (abr-2025) y **sin fecha de fin de vida anunciada** |

**Consecuencia de criterio, no de nostalgia**: **pfSense CE y OPNsense no son equivalentes en
licencia**, y la diferencia importa cuando hay auditoría, derecho a bifurcar o reventa. **Y TrueNAS
ya no es un argumento a favor de FreeBSD**: si eliges FreeBSD para almacenamiento hoy, lo eliges tú
y lo montas tú, no lo hereda de TrueNAS.

## 3. Convenciones de FreeBSD que deciden

- **ZFS como raíz, siempre**, y **entornos de arranque (`bectl`) como mecanismo de actualización**:
  se actualiza sobre un BE nuevo y la vuelta atrás es un reinicio. Es la razón operativa principal
  para elegir FreeBSD; renunciar a ella es tirar la ventaja. (El diseño del pool es de
  `zfs-standards`.)
- **Elige rama de paquetes conscientemente**: `quarterly` para servidores (cambios acotados,
  correcciones de seguridad portadas) y `latest` solo donde necesites versiones frescas. **Mezclar
  `pkg` con `ports` compilados a mano en la misma máquina es la fuente número uno de dependencias
  rotas**; si necesitas opciones propias, monta un repositorio propio (poudriere) y sirve
  paquetes, no compiles en producción.
- **Configuración en `/etc/rc.conf` gestionada con `sysrc`**, versionada y aplicada por
  automatización. **Ninguna configuración editada a mano en producción sin quedar en el
  repositorio** — el punto de contacto con `iac-standards`.
- **Jails "thin"** con plantilla común y sistema de ficheros de solo lectura compartido; jails
  `vnet` cuando cada servicio necesita su propia pila de red. Elige **una** herramienta de gestión
  (Bastille, AppJail, iocage) y una sola: la mezcla de gestores de jails deja huérfanos.
- **`bhyve` es suficiente para virtualización modesta**, y solo eso: sin migración en vivo
  comparable a un hipervisor de gama, sin ecosistema de gestión. Si necesitas una plataforma de
  virtualización, esa decisión es de `onprem-standards`, no de aquí.
- **`freebsd-update` para binarios en RELEASE.** Correr `-CURRENT` en producción está vetado (§7);
  `-STABLE` solo con compilación propia y una razón escrita.

## 4. Jails frente a contenedores, y `pf` frente a `nftables`

> *(Sustituye a la sección de "calidad y testing" del formato, que aquí sería artificial: no hay
> toolchain de pruebas propio que fijar. Lo que decide en su lugar son estas dos comparaciones.)*

**Jails**: aislamiento de sistema completo, muy barato, con integración nativa de ZFS y de red. Lo
que **se gana** frente a un contenedor Linux: madurez, superficie pequeña, límites claros, y que un
jail es un sistema, no un proceso empaquetado. Lo que **se pierde**, y es mucho: **no hay imágenes
OCI, ni registro, ni ecosistema de herramientas, ni orquestador**. Un jail no se reconstruye desde
un `Containerfile` que alguien más entienda ni se despliega desde tu pipeline sin trabajo propio.

Regla: **jails para servicios de larga vida gestionados como máquinas** (almacenamiento, red,
servicios de infraestructura). **Contenedores para cargas de aplicación con ciclo de entrega
continuo.** No conviertas jails en un sustituto artesanal de Kubernetes: acabarás manteniendo un
orquestador propio que nadie más sabe operar.

**`pf` frente a `nftables`**: `pf` gana en legibilidad —el conjunto de reglas se lee como una
política y se revisa en una revisión de código— y trae `pfsync`/CARP para pares con estado
sincronizado. `nftables` gana en integración: es lo que hay bajo Kubernetes, contenedores y las
herramientas de automatización de red del mundo Linux. **Elige el motor por dónde vive el resto de
tu infraestructura, no por elegancia de sintaxis.** La **política** de filtrado —zonas,
denegación por defecto, egress, revisión— es idéntica en ambos casos y vive en
`firewall-policy-standards`.

## 5. Seguridad: qué enseña OpenBSD aunque no lo despliegues

OpenBSD es **la referencia de mitigaciones**, y su valor para el resto del catálogo es doctrinal:

- **Seguro por defecto de verdad**: instalación mínima, casi nada escuchando, servicios en `chroot`
  desde el primer arranque. La lección transferible: **la postura correcta es "nada expuesto salvo
  lo declarado"**, no "endurecer después".
- **`pledge(2)` y `unveil(2)`**: el programa **declara qué llamadas al sistema y qué rutas
  necesita** y el kernel lo mata si se sale. Es privilegio mínimo aplicado dentro del proceso, y es
  el modelo mental correcto para escribir perfiles seccomp, políticas SELinux o unidades systemd
  endurecidas en Linux. **Si un servicio no puede enumerar los ficheros que necesita, el problema
  es el servicio.**
- **Mitigaciones de explotación por defecto** (W^X, ASLR, kernel reordenado en cada arranque,
  protecciones de retorno, `malloc` con detección de abusos): no son opciones que se activan, son
  el sistema. La lección: **las mitigaciones que hay que recordar activar no se activan.**
- **`syspatch`/`signify`**: parches firmados, binarios, aplicables sin compilar. **Un sistema cuya
  actualización de seguridad requiere compilar no se actualiza.**
- **Honestidad sobre el alcance**: OpenBSD protege el sistema base. **El código de terceros que
  instales encima (`pkg_add`) no hereda ese nivel de revisión** y sigue siendo tu superficie de
  ataque; su gestión de vulnerabilidades es de `vulnerability-management-standards`.
- **`doas` en lugar de `sudo`**: menos superficie y una configuración que cabe en la cabeza.
  Trasladable como criterio: la herramienta de elevación se elige por lo pequeña que es su
  configuración, no por costumbre.

## 6. Operabilidad y ecosistema derivado

- **Hardware y controladores son el riesgo operativo real de BSD**, no la estabilidad. Antes de
  comprometer una plataforma: verifica la lista de compatibilidad para tu NIC, HBA y plataforma de
  gestión concreta, y comprueba si hay agente de tu proveedor de copias, de monitorización y de
  seguridad de endpoint. **Muchos productos corporativos no tienen agente para BSD**: eso solo
  decide de un plumazo.
- **pfSense CE frente a OPNsense** como aparato de cortafuegos: mismo linaje, licencias distintas
  (§2) y cadencia de actualización distinta. Criterio: **si necesitas garantía de código abierto
  íntegro, derecho a bifurcar o auditoría del fuente, OPNsense**; si ya operas hardware Netgate con
  soporte contratado, pfSense Plus es coherente **asumiendo que es software propietario**. Lo que
  no es defendible es elegir uno creyendo que el otro es lo mismo con otro nombre.
- **Un aparato de cortafuegos sigue siendo un servidor**: inventario, ciclo de parcheo, copia de la
  configuración y registro centralizado; configuración exportada y versionada como mínimo.
- **Almacenamiento**: FreeBSD + ZFS sigue siendo excelente, pero **hoy la montas tú** (§2). Si
  quieres un aparato, evalúa la línea Linux de TrueNAS o un diseño ZFS propio sobre Linux — la
  decisión de plataforma no es sentimental.
- **Actualizaciones como calendario, no como reacción**: FreeBSD, ventana por release menor (caducan
  en meses, §2); OpenBSD, dos al año en fecha fija. Si no está en el calendario, no ocurre.

## 7. Cuándo NO elegir BSD, y prohibiciones

**No elijas BSD cuando:**

- **El ecosistema de aplicaciones no está**: plataformas de datos, agentes propietarios,
  controladores de GPU y suites comerciales que solo publican para Linux. Motivo número uno, y no
  se resuelve con voluntad. **O la carga es de contenedores**: si el destino natural es
  OCI/Kubernetes, BSD te deja fuera del camino trillado (§4).
- **Necesitas soporte comercial con SLA sobre el sistema operativo.** Existe (Deciso, Netgate,
  proveedores especializados) pero **no es comparable en cobertura al de una distribución Linux
  empresarial**, y esa comparación honesta es parte de la decisión.
- **No hay gente.** Contratar y sustituir a quien opera BSD es medible y peor que en Linux: **un
  sistema que solo una persona sabe operar es un riesgo de continuidad**.
- **Ya operas una flota Linux homogénea** y esto añade un segundo sistema operativo con su parcheo,
  inventario, agentes y conocimiento, por una mejora marginal.

**Prohibiciones:**

- ❌ **PROHIBIDO** usar `-CURRENT` en producción, o una release menor de FreeBSD ya caducada — que
  caducan **en meses**, no en años (§2).
- ❌ Correr OpenBSD sin comprometerse a la actualización semestral. **Sin esa cadencia, OpenBSD es
  menos seguro que un Linux mantenido**, no más.
- ❌ Mezclar paquetes binarios y ports compilados a mano en la misma máquina, o compilar ports en
  producción.
- ❌ Actualizar FreeBSD sin entorno de arranque nuevo y vuelta atrás probada.
- ❌ Tratar **pfSense CE y pfSense Plus** como la misma cosa: uno es Apache-2.0, **el otro es
  propietario sin fuente**. Ni citar la licencia de un derivado sin haber leído su `LICENSE` en
  crudo.
- ❌ Redistribuir o rebautizar pfSense apoyándose solo en la licencia del código: la **marca** está
  restringida aparte.
- ❌ Presentar TrueNAS como argumento de que "FreeBSD tiene ecosistema de almacenamiento": la línea
  viva es Linux (§2).
- ❌ Elegir NetBSD para una plataforma x86/ARM corriente sin una razón de portabilidad escrita.
- ❌ Reinventar un orquestador sobre jails para cargas que pedían contenedores (§4).
- ❌ Desplegar BSD sin haber verificado antes controladores, agente de copias y agente de
  seguridad de endpoint (§6).
- ❌ Dejar el aparato de cortafuegos fuera del inventario, del parcheo o del registro centralizado.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web —y con **cita literal**, nunca con un
resumen automático:

1. **FreeBSD**: página oficial de seguridad, tabla de ramas soportadas y fechas. Las de §2 están
   tomadas literalmente de ahí a ago-2026; **la fecha de la release menor que uses caduca en
   meses**.
2. **OpenBSD**: release vigente y su página de errata; confirma que sigues dentro de las **dos
   últimas**.
3. **NetBSD**: rama vigente tras 11.0 y estado real de 10.x.
4. **pfSense y OPNsense**: **lee el `LICENSE` en crudo del repositorio** antes de afirmar nada — no
   la etiqueta que muestre la portada de GitHub, y no el feed de releases, que no es la fuente de
   verdad si el proyecto se muda. Verificado así a ago-2026: **pfSense CE = Apache-2.0**,
   **OPNsense = BSD 2-Clause**. **Hueco declarado: los precios** (suscripción TAC de pfSense Plus,
   *Business Edition* de OPNsense) **no fueron verificados en la página de tarifas oficial** — no
   los cites de aquí. **Hueco declarado**: tampoco se verificó en fuente oficial el alcance exacto
   de la política de marca de Netgate.
5. **TrueNAS**: si sigue habiendo entregas de CORE y si iXsystems ha anunciado por fin una fecha de
   fin de vida. A ago-2026 **no la había**: sostenimiento sin fecha, que a efectos de planificación
   se trata como fin de vida no anunciado.
6. **Compatibilidad de hardware** de tu modelo concreto y disponibilidad de agentes de terceros
   (§6): es lo que descarta la plataforma, más que cualquier consideración de diseño.
7. **CVEs** del sistema base y **de los paquetes de terceros por separado**: son dos flujos de
   avisos distintos con calendarios distintos.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
