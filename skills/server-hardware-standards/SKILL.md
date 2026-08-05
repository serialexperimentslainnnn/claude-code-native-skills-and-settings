---
name: server-hardware-standards
description: Choosing, sizing, securing and retiring physical servers. Use when specifying or reviewing a server BOM (socket count, DDR5 memory channels and DIMMs per channel, RDIMM versus MRDIMM, NUMA nodes and node-per-socket settings, PCIe Gen5 lanes and x8/x8 or x4/x4/x4/x4 bifurcation, drive bays, SAS expander versus direct-attach backplane, U.2/E3.S form factors, redundant PSUs on separate circuits, OCP NIC 3.0 slots), operating out-of-band management (iDRAC, iLO, XCC, BMC, ipmitool, Redfish ComputerSystem and UpdateService, KVM over IP, virtual media, serial-over-LAN, IPMI cipher zero, default BMC credentials, BMC firmware CVEs such as CVE-2024-54085 in AMI MegaRAC), managing firmware and BIOS as code (fwupd and LVFS, fwupdmgr, UEFI capsule updates, Dell DSU and Repository Manager, HPE SPP and iLO, Lenovo XCC, firmware signing and rollback), deciding RAID controller versus HBA in IT mode for ZFS or Ceph, picking drives by interface and endurance (SATA, SAS, NVMe, TBW, DWPD, SMART attributes and what they actually predict), sizing warranty and support contracts (next-business-day versus 4-hour onsite, post-year-3 renewal cost, spare parts pools), buying refurbished or second-hand enterprise gear, deciding when to refresh hardware on power draw versus on failure rate, or comparing buy versus lease versus cloud on cost.
---

# Estándares de hardware de servidor

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **el hierro como decisión de ingeniería**: qué se compra y por qué (§3), cómo se acepta antes
de ponerlo en producción (§4), cómo se gestiona su plano fuera de banda y su firmware sin abrir un
agujero (§5), y cuánto tiempo se conserva, con qué contrato y con qué criterio de renovación (§6).

**Principio rector**: **el cuello de botella de un servidor casi nunca es la frecuencia del
procesador.** Es la memoria mal poblada, el NUMA ignorado, el carril PCIe compartido, el *backplane*
que no llega a todas las bahías o la fuente única. **Segundo principio, y es el que más incidentes
evita: el BMC es un ordenador completo con acceso total al servidor, ejecutándose fuera del control
del sistema operativo. Va en una red de gestión aislada. Sin excepciones.**

Triggers: pliego o BOM de servidor, "¿cuánta RAM le pongo?", canales de memoria, DIMM por canal
(1DPC/2DPC), RDIMM/MRDIMM, NUMA / NPS, carriles PCIe Gen5, bifurcación x8/x8 o x4/x4/x4/x4, bahías
U.2/E3.S, *backplane* con expansor SAS, OCP NIC 3.0, fuentes redundantes y circuitos separados,
`ipmitool`, `racadm`, `ilorest`, `sum`, Redfish (`/redfish/v1/Systems`, `UpdateService`), KVM sobre
IP, medio virtual, SOL, `cipher zero`, `fwupdmgr`, LVFS, cápsula UEFI, Dell DSU/Repository Manager,
HPE SPP/iLO, Lenovo XCC, "¿RAID hardware o HBA?", modo IT, `smartctl`, TBW, DWPD, NBD frente a 4h,
"renovar el contrato de soporte", "servidor de segunda mano", "¿comprar o nube?".

**No aplica**: ver `onprem-standards` (**paraguas de plataforma y tabla de enrutado §1.2**: la flota
como conjunto, la elección de hipervisor y sus invariantes; **aquí la máquina individual y su
componente**), `datacenter-facilities-standards` (**todo lo que está fuera
del chasis** —rack, PDU, circuitos, UPS, refrigeración, pasillo caliente/frío, densidad por rack,
recepción y retirada física—. Frontera en una línea: *si va atornillado al rack pero no dentro del
servidor, es suyo*), `cmdb-inventory-standards` (**el registro del activo**: número de serie como
identificador estable, garantía, contrato y estado de ciclo de vida se **guardan allí**; aquí qué
significan), `os-provisioning-standards` (instalar el SO sobre este hierro; **allí Redfish/IPMI como
disparador de arranque, aquí el BMC como sistema a proteger**), `linux-storage-standards`
(multipath, LVM, planificadores de E/S, `nvme-cli`, el filesystem) y `zfs-standards` (**topología de
pool, `ashift`, ARC, scrub**; aquí solo por qué ZFS exige HBA en modo IT y no controladora RAID),
`ha-clustering-standards` (redundancia de servicio; aquí redundancia dentro del chasis),
`backup-recovery-standards` y `bcdr-standards` (**el fallo del hierro como escenario de
recuperación**: RTO real = tiempo de repuesto + tiempo de restauración), `networking-standards` y
`datacenter-fabric-standards` (**el switch, el enlace y la VLAN de gestión**; aquí solo la NIC y la
exigencia de que esa VLAN exista), `linux-hardening-standards` (baseline del SO; **el firmware y el
BMC son de aquí**), `vulnerability-management-standards` (triaje de CVE de firmware con
CVSS/EPSS/**KEV**), `green-it-standards` (huella y reporte, y el criterio de que **alargar la vida
útil suele pesar más que optimizar el consumo**), `finops-standards` (coste en nube),
`homelab-standards` (**economía del material *enterprise* usado**), `gpu-computing-standards` y
`high-speed-interconnect-standards` (aceleradores e InfiniBand/RoCE), `hpc-standards`
(nodo de cálculo y densidad), `macos-fleet-standards` y
`developer-workstation-standards` (el puesto, no el servidor).

## 2. Decisiones por defecto

> Verificar por web modelo, versión de firmware y matriz de compatibilidad antes de fijar nada (§8).

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Nº de sockets | **1 socket** salvo justificación medida | Un socket moderno llega a densidades que hace cinco años exigían dos, y **evita todo el problema NUMA de raíz**. Dos sockets solo si necesitas la memoria o los carriles PCIe, no "por si acaso" |
| Poblado de memoria | **Todos los canales poblados, 1 DIMM por canal** | Es la decisión de memoria que más rendimiento decide, por encima de la frecuencia. Medio poblado = ancho de banda proporcionalmente perdido. **2DPC baja la velocidad negociada**: si necesitas capacidad, DIMM más grandes antes que más DIMM |
| Gestión fuera de banda | **BMC en VLAN de gestión aislada**, cuenta única por host, **Redfish** para automatizar | `ipmitool` solo para lo que Redfish no cubra. **IPMI/LAN se deshabilita si Redfish basta** (§5) |
| Almacenamiento local | **NVMe** (U.2/E3.S) para datos calientes; SATA/SAS solo por capacidad o por cabina existente | El coste por IOPS de NVMe ya no justifica SAS en servidores nuevos |
| Controladora | **HBA en modo IT** (paso directo) si el consumidor es ZFS, Ceph o el propio SO | **RAID hardware** solo con arranque en espejo o cabina heredada. La controladora RAID con caché y batería es un SPOF con firmware propio, y **oculta SMART al SO** |
| Fuentes | **2 PSU, en circuitos eléctricos distintos**, dimensionadas para que **una sola aguante la carga** | Dos fuentes en la misma regleta no son redundancia: son dos fuentes. El circuito lo fija `datacenter-facilities` |
| Red | **NIC OCP 3.0 + una PCIe** para separar dominios de fallo | Doble puerto en la misma NIC no protege del fallo de la NIC |
| Firmware | **Como código**: catálogo del fabricante fijado por versión, aplicado en ventana, con `fwupd`/LVFS donde exista cobertura | **Verifica la cobertura real**: LVFS es fuerte en cliente y estación de trabajo; **el firmware de servidor sigue viniendo mayoritariamente del canal del fabricante** (iLO/SPP, DSU, XCC) |
| Garantía | **NBD** por defecto; **4h onsite** solo donde el RTO comprometido no se cubra con repuesto propio | La alternativa barata y muchas veces mejor: **stock propio de repuestos + N+1**, que además funciona fuera de horario y sin depender del proveedor |
| Compra | **Comprar** cuando la carga es estable, predecible y de vida ≥ 4 años | **Nube** para lo elástico e incierto; **alquiler/leasing** cuando el problema es el flujo de caja o el ciclo de renovación forzado, no el coste total |

## 3. Dimensionado: dónde se pierde el rendimiento

- **Memoria y canales**. Las plataformas actuales tienen **muchos canales** (a ago-2026, AMD EPYC
  9005 "Turin" declara hasta **12 canales DDR5 por socket**; Xeon 6 de línea general usa **8 canales**
  y compensa con **MRDIMM** a mayor velocidad). El error caro es comprar 4 DIMM grandes en una
  plataforma de 12 canales: se paga la CPU entera y se usa un tercio de su ancho de banda. **Puebla
  todos los canales, en 1DPC, con módulos idénticos** y comprueba en la tabla de poblado del
  fabricante la velocidad negociada resultante, que depende del modelo y del rango del módulo.
- **NUMA**. Con dos sockets —o con particionado NUMA dentro de un socket (NPS)— **la latencia de
  memoria depende de dónde se ejecute el proceso**. Consecuencia práctica: dimensiona la VM o el
  contenedor para que **quepa dentro de un nodo NUMA**, y si no cabe, sabe que estás pagando el
  cruce. Fijar afinidad es cosa del hipervisor (`libvirt-kvm`, `proxmox-ve`, `vmware`); aquí la
  decisión de **no crear el problema al comprar**.
- **PCIe: los carriles son finitos y se reparten**. Antes de firmar un BOM, suma los carriles que
  piden NIC, HBA, NVMe y aceleradores y compáralos con los que expone el socket. Dos trampas
  frecuentes: **una ranura físicamente x16 cableada a x8** (o alimentada desde el segundo socket, que
  desaparece en configuración de un socket) y la **bifurcación**, que debe soportarla la BIOS
  —x8/x8 o x4/x4/x4/x4— para que una tarjeta portadora de varios NVMe funcione. Se verifica en el
  manual de la placa, no se supone.
- **Bahías y *backplane***. El número de bahías no dice nada por sí solo: importa **cómo están
  cableadas**. Un *backplane* con expansor SAS comparte ancho de banda entre bahías; uno de conexión
  directa no. Y **las bahías NVMe suelen ser un subconjunto** de las bahías totales: "24 bahías" puede
  significar 8 NVMe y 16 SAS. Pregunta siempre por el diagrama de cableado.
- **Discos y resistencia**. Elige por **DWPD/TBW frente a la escritura diaria real medida**, no por
  categoría comercial. Un SSD de lectura intensiva bajo un journal de base de datos o bajo Ceph se
  gasta en meses. **Mezclar modelos y lotes a propósito** dentro de un grupo redundante reduce el
  riesgo de fallo correlacionado por defecto de fabricación.
- **SMART predice menos de lo que la gente cree, y esto está medido.** Google (Pinheiro, Weber &
  Barroso, *Failure Trends in a Large Disk Drive Population*, USENIX FAST '07; 100.000 discos, 5
  años) encontró que **más del 56 % de los discos que fallaron no tenían ningún recuento en las
  cuatro señales SMART fuertes** (errores de escaneo, reasignaciones, reasignaciones fuera de línea y
  recuento probatorio), y que **el 36 % no tenía ninguna señal SMART en absoluto**. Lectura correcta:
  **SMART con contadores es una buena razón para sustituir el disco; SMART limpio no es garantía de
  nada.** El diseño se hace con redundancia y copias verificadas, no con predicción. (El estudio es
  de discos mecánicos de 2007; para SSD las señales útiles son otras —resistencia consumida, bloques
  reservados, errores no corregibles— pero la conclusión estructural se mantiene.)

## 4. Aceptación del hierro antes de producción

> *(Ocupa el lugar de "calidad y testing" del formato: no hay toolchain que fijar, sí un gate.)*

Ningún servidor entra en producción sin pasar, y con evidencia archivada:

1. **Inventario y firmware**: número de serie registrado (`cmdb-inventory-standards`), firmware de
   BIOS/BMC/NIC/HBA/discos **llevado al nivel de referencia de la flota** antes de instalar nada.
   Empezar con firmware de fábrica es empezar con deuda.
2. **Configuración de BIOS aplicada desde el perfil de la flota**, no a mano por menú: perfil de
   energía, NPS, SR-IOV, Secure Boot, watchdog, orden de arranque. Exportable y comparable.
3. **Burn-in de 24–72 h** con carga de memoria, CPU y disco, **con el chasis en el rack definitivo y
   a temperatura ambiente real**. La mortalidad infantil es real y es mucho más barata de encontrar
   aquí que en producción.
4. **Prueba de redundancia física**: se **desenchufa una fuente** con el servidor cargado, y se
   desconecta un enlace de red. Un camino redundante no probado no se sabe si existe.
5. **Prueba del plano OOB**: consola remota, medio virtual, encendido/apagado y **arranque forzado
   por Redfish**, desde el bastión. Es lo que usarás a las 3 de la madrugada.
6. **Línea base de consumo eléctrico y de temperatura** anotada. Sin ella no podrás decidir la
   renovación por consumo (§6) ni detectar una degradación de ventilación años después.

## 5. Seguridad: el BMC y el firmware

**Regla dura, la más importante de esta skill: el BMC nunca se expone.** Red de gestión dedicada, sin
ruta a internet ni a la red de usuarios, alcanzable solo desde un bastión con MFA. El BMC arranca
antes que el sistema operativo, sobrevive a su reinstalación, ve la memoria y el teclado, y **ningún
control del SO lo protege**. Comprometerlo es comprometer el servidor de forma persistente e
invisible.

- **Caso verificado, y por eso la regla es dura**: **CVE-2024-54085** en AMI **MegaRAC SPx**
  —firmware de BMC presente en servidores de múltiples fabricantes—, **CVSS 10.0**, elusión completa
  de autenticación en la interfaz Redfish manipulando cabeceras HTTP; permite control remoto del
  servidor, despliegue de malware, manipulación de firmware e incluso inutilizar la placa. **CISA lo
  añadió a su catálogo KEV el 25-jun-2025** (primer fallo de BMC en entrar en KEV), con fecha límite
  de remediación 16-jul-2025. Fue descubierto por Eclypsium al analizar el arreglo de un fallo
  anterior de 2023 (CVE-2023-34329): **el segundo intento del fabricante también era elusible**.
- **Credenciales**: única por host, generada y guardada en el gestor de secretos, **nunca compartida
  entre hosts ni la de fábrica**. Cuentas por persona/servicio con rol mínimo, no una cuenta `admin`
  común. Revocación ligada a la baja del activo.
- **Protocolos**: **deshabilita IPMI sobre LAN si Redfish cubre tu automatización**. IPMI arrastra
  problemas de diseño conocidos (entre ellos `cipher zero` y la exposición de hashes de contraseña
  por RAKP) y no va a arreglarse. Si debe quedarse, restringido por origen y con `cipher zero`
  desactivado.
- **Firmware firmado y con vuelta atrás**. Solo firmware del fabricante, verificado por firma. Los
  dispositivos con **doble banco** permiten rollback y son preferibles. Un fallo durante la
  actualización deja un ladrillo: se actualiza en ventana, con consola OOB abierta y una máquina de
  la pareja HA fuera de servicio, nunca en masa y nunca a la vez en las dos.
- **Cadencia de parcheo de firmware, escrita**: revisión **trimestral** del catálogo del fabricante
  para BIOS/NIC/HBA/discos, y **fuera de ciclo ante cualquier CVE de BMC** —especialmente si entra en
  **KEV**, que es la señal de explotación real (triaje en `vulnerability-management-standards`).
- **Herramienta**: `fwupd`/LVFS cuando el fabricante publique ahí (metadatos firmados con JCat,
  verificación obligatoria en cada refresco, y `ApprovalRequired` para aprobar solo lo probado). Pero
  **verifica la cobertura para servidores**: el grueso del firmware de servidor sigue distribuyéndose
  por el canal del fabricante (Dell DSU/Repository Manager, HPE SPP/iLO, Lenovo XCC).
- **Secure Boot y el calendario de 2026**: las CA de Microsoft de 2011 están venciendo (KEK CA 2011
  expiró el **27-jun-2026**; Windows Production PCA 2011 vence en **octubre de 2026**). **Comprueba si
  tu modelo de servidor tiene firmware con las CA de 2023**: si el fabricante ya no lo publica, ese
  chasis ha entrado de hecho en su fase de retirada, decidas lo que decidas (§6).
- **Fin de vida del servidor**: **destrucción o borrado certificado de los discos** —y de la memoria
  no volátil del BMC y de la caché de la controladora RAID, que casi nadie limpia—. Restablecimiento
  a fábrica del BMC antes de que el chasis salga del edificio.

## 6. Ciclo de vida: garantía, repuestos y cuándo renovar

- **La garantía es una decisión de RTO, no de tranquilidad.** Calcula el RTO real del fallo de un
  componente: `tiempo de detección + tiempo de respuesta contractual + tiempo de sustitución +
  tiempo de restauración`. Un contrato 4h no sirve de nada si el dato tarda seis horas en restaurar,
  y NBD sobra si tienes N+1 y el servicio se mueve solo. **Lo que casi siempre gana en coste y en
  tiempo: comprar el repuesto crítico (fuente, disco, ventilador, DIMM) y tenerlo en el armario.**
- **Los años 4 y 5 son donde el contrato se vuelve caro.** La renovación posterior a la garantía
  inicial suele costar por año una fracción creciente del valor del equipo, mientras el valor
  residual cae. Regla: **cada renovación de soporte se compara por escrito contra (a) sustituir el
  equipo y (b) autoasegurarse con repuestos y N+1.** Si no hay esa comparación con fecha, no se
  firma. *(Cifras concretas: salen de tu oferta, no de aquí — ningún fabricante publica tarifas.)*
- **Cuándo renovar: dos relojes distintos y hay que mirar los dos.**
  - **Por avería**: cuando la tasa de fallos sube, el repuesto ya no se consigue en canal oficial, o
    el fabricante deja de publicar firmware (incluido el caso de Secure Boot de §5). **Un servidor
    sin firmware nuevo es un servidor sin parches de seguridad**, aunque encienda perfectamente.
  - **Por consumo**: el equipo viejo se paga a sí mismo en electricidad y en espacio de rack cuando
    su rendimiento por vatio queda muy por detrás. **Cálcúlalo, no lo cites**: `(vatios_viejo −
    vatios_nuevo × equipos_equivalentes) × 8760 h × precio_kWh × factor_PUE` frente al coste del
    equipo nuevo. Con energía cara y consolidación alta (varias máquinas viejas en una nueva) el
    retorno puede ser de 2–3 años; con energía barata y un servidor poco cargado, nunca. **La
    respuesta depende de tu precio del kWh y de tu ratio de consolidación, y por eso no hay una regla
    de "renovar cada X años" que sea honesta.** Y ojo al contrapeso de `green-it-standards`: la
    huella ya incorporada del equipo existente empuja en sentido contrario.
- **Segunda mano**: legítima y a veces excelente —laboratorio, entornos de no producción, capacidad
  de reserva, repuestos de un modelo que ya operas—. Condiciones para producción: **repuestos
  disponibles, firmware aún publicado, y que no sostenga nada cuyo RTO sea comprometido**. Verifica
  antes de comprar: horas de encendido y ciclos de los discos, ausencia de bloqueo de licencias del
  BMC (iDRAC Enterprise, iLO Advanced **se licencian y no siempre se transfieren**), y estado de
  garantía transferible.
- **Comprar frente a alquilar frente a nube**: compárense **coste total a 5 años** —equipo,
  soporte, energía, espacio, red, personal y coste del capital— contra el coste equivalente en nube
  **con el mismo perfil de utilización**. Los dos errores simétricos: comparar el precio de compra
  contra la factura mensual de nube (ignora operación y amortización), y comparar contra una nube
  dimensionada al pico (ignora la elasticidad, que es justo lo que se paga). **La decisión rara vez
  es global**: base estable propia + pico en nube gana casi siempre a los extremos puros.

## 7. Sostenibilidad y prohibiciones

- ❌ **PROHIBIDO** exponer un BMC a internet o a la red de usuarios; **PROHIBIDO** dejar credenciales
  de fábrica o compartir credenciales de BMC entre hosts (§5).
- ❌ Dejar IPMI sobre LAN habilitado "por si acaso" cuando Redfish ya cubre la automatización.
- ❌ Ignorar un CVE de BMC porque "está en red interna". La red interna es exactamente donde llega el
  atacante que ya entró; **KEV significa explotación real**.
- ❌ Comprar CPU de muchos canales y poblar la mitad de la memoria (§3).
- ❌ Dar por buena una ranura x16 sin comprobar su cableado real y la bifurcación soportada.
- ❌ Controladora RAID por delante de ZFS o Ceph. **Se exige HBA en modo IT.**
- ❌ Dos fuentes en el mismo circuito y llamarlo redundancia.
- ❌ Poner en producción un servidor sin burn-in, sin nivelar firmware y **sin haber desenchufado una
  fuente** (§4).
- ❌ Actualizar firmware simultáneamente en los dos nodos de una pareja HA, o sin consola OOB abierta.
- ❌ Confiar en SMART limpio como prueba de salud, o en la predicción SMART como sustituto de
  redundancia y copias (§3).
- ❌ Renovar soporte sin la comparación escrita contra sustituir o autoasegurarse (§6).
- ❌ Citar un "servidor se renueva cada N años" como norma. Se calcula con tu precio de la energía y
  tu ratio de consolidación.
- ❌ Meter en producción hardware de segunda mano cuyo fabricante ya no publica firmware.
- ❌ Retirar un chasis sin borrado certificado de discos, caché de RAID y configuración del BMC.
- ❌ Comprar por hoja de especificaciones sin el diagrama de cableado del *backplane* y la tabla de
  poblado de memoria del modelo concreto.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar por web —y en la documentación del **modelo concreto**, no de la
familia—, con cita literal:

1. **Manual técnico del modelo**: tabla de poblado de memoria (velocidad resultante por
   configuración y por rango), mapa de carriles PCIe por ranura y por socket, bifurcación soportada,
   y **diagrama de cableado del *backplane*** (qué bahías son NVMe y cuáles cuelgan de expansor).
   Ningún dato de estos se escribe de memoria.
2. **Plataforma de CPU**: número de canales de memoria, velocidad máxima por DPC y carriles PCIe de
   la generación vigente. A ago-2026: EPYC 9005 "Turin" hasta **12 canales DDR5** por socket; Xeon 6
   de línea general **8 canales** con opción **MRDIMM** a mayor velocidad. **Hueco declarado: las
   cifras de ancho de banda medido citadas en prensa técnica (STREAM) no se contrastaron contra el
   informe original**; no las uses para dimensionar sin repetir la medida.
3. **Redfish**: versión vigente de la especificación DMTF y del *schema bundle* (a ago-2026,
   **release 2026.1**, especificación **1.24.0**) y —lo que de verdad importa— **qué subconjunto
   implementa el BMC de tu fabricante y en qué versión de firmware**. La brecha entre el estándar y
   la implementación es donde se rompe la automatización.
4. **Avisos de seguridad de firmware** del fabricante y del proveedor del BMC (AMI, Insyde), y el
   **catálogo KEV de CISA** para saber si algo se está explotando. Confirma que **CVE-2024-54085**
   está remediado en tu nivel de firmware (AMI-SA-2025003 y el aviso equivalente de tu fabricante).
5. **Secure Boot**: disponibilidad de firmware con las CA de 2023 para tu modelo (§5). Si no existe,
   es dato de renovación.
6. **`fwupd`/LVFS**: versión vigente (a ago-2026, línea **2.1.x**) y **cobertura real de tu modelo de
   servidor**. **Hueco declarado: no se verificó qué fabricantes publican firmware de servidor —no de
   cliente— en LVFS**; las fuentes consultadas indican que HPE ProLiant sigue por iLO/SPP. Compruébalo
   antes de diseñar tu proceso de parcheo alrededor de `fwupdmgr`.
7. **Fin de vida del modelo**: fecha de fin de venta, de fin de soporte y de **fin de publicación de
   firmware** —son tres fechas distintas y la tercera es la que decide la seguridad—. Y
   disponibilidad real de repuestos, que es un dato de canal, no de catálogo.
8. **Precios**: ningún fabricante publica tarifas de soporte, ampliación ni renovación. **Ninguna
   cifra económica de §6 sale de este documento: sale de tu oferta y de tu factura eléctrica.**
9. **Discos**: TBW/DWPD y garantía del modelo exacto (varían entre capacidades de la misma familia) y
   si el firmware del disco está en la lista de compatibilidad de tu controladora.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
