---
name: network-automation-standards
description: Network as code — source of truth, generation, validation and safe rollout of device configuration. Use when driving devices from Ansible network collections (ansible.netcommon, cisco.ios, arista.eos, junipernetworks.junos, nokia.srlinux), Nornir with nornir-napalm or nornir-netmiko, NAPALM get_facts/compare_config/commit_config, netmiko send_config_set, scrapli or scrapli-netconf, Jinja templates rendering device config, NetBox as source of truth with pynetbox, custom fields, config contexts, config templates or the NetBox Ansible/Nornir inventory plugin, YAML intent data and schema validation, NETCONF (RFC 6241), RESTCONF (RFC 8040), YANG 1.1 (RFC 7950), NMDA (RFC 8342), candidate datastores and confirmed-commit, gNMI Get/Set/Subscribe with gnmic or pygnmi, OpenConfig versus IETF versus native YANG models, streaming telemetry replacing SNMP polling, containerlab .clab.yml topologies, netlab, vrnetlab or GNS3/EVE-NG virtual labs, pre-checks and post-checks, config diff and dry-run, drift detection against intent, batched canary rollout with tested rollback, commit-confirm timers, Batfish or pyATS/Genie operational-state validation, or storing device configs and credentials in a git repository.
---

# Estándares de automatización de red — la red como código

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **automatizar la configuración y la verificación de equipos de red**: fuente de verdad y su
gobierno, modelo de datos de intención, generación de configuración, interfaces del dispositivo (CLI,
NETCONF/RESTCONF, gNMI), pruebas y validación de estado operativo, laboratorio virtual, CI/CD de red
con despliegue por lotes y reversión probada, detección de deriva, telemetría de flujo continuo, y la
**custodia de las credenciales que dan acceso a toda la flota**.

Triggers: `*.clab.yml`, `containerlab`, `netlab`, `vrnetlab`, `nornir_config.yaml`, `hosts.yaml`,
`groups.yaml`, `napalm`, `netmiko`, `scrapli`, `pynetbox`, `ansible.netcommon`,
`cisco.ios`/`arista.eos`/`junipernetworks.junos`/`nokia.srlinux`, `gnmic`, `pygnmi`, `ncclient`,
`pyang`, `batfish`, `pyats`/`genie`, `*.j2` de configuración de red, "config context",
"config template", "source of truth", "drift", "pre-check"/"post-check", "commit-confirm",
"streaming telemetry", "dial-in"/"dial-out".

**No aplica** — cada skill **decide** una cosa distinta:
`networking-standards` (**troncal, madre**: decide **direccionamiento e IPAM, las VLAN, los
fundamentos de routing, MTU/MSS y que NetBox es el SoT de intención**; aquí no se repite eso, aquí se
decide **cómo se modela esa intención, cómo se genera la configuración y cómo llega al equipo sin
romper nada**); `routing-switching-standards` (**decide qué debe decir la configuración de campus y
borde**: STP, LACP, MLAG, IGP, política BGP, RPKI, CoPP, AAA); `datacenter-fabric-standards`
(**decide qué debe decir la configuración de la malla**: Clos, EVPN, VRF, MTU, red sin pérdidas).
**Esas dos diseñan; esta automatiza lo que ellas diseñan.**
`network-troubleshooting-standards` (**decide el método reactivo** cuando el cambio automatizado rompió
algo); `iac-standards` (**decide Terraform y Ansible como herramientas y cómo se escriben** —aquí sólo
lo específico de red); `secrets-management-standards` (**decide el gestor de secretos**, rotación y
credenciales efímeras); `observability-standards` (**decide la plataforma, los umbrales y las
alertas** — aquí sólo de dónde sale el dato del equipo y por qué protocolo); `cicd-standards`
(**decide el motor de pipeline**); `firewall-policy-standards` (**decide la política de filtrado y su
gobierno**, aunque se aplique con estas herramientas); `opensource-licensing-standards` (**decide la
licencia aceptable** de cada herramienta que se adopte). También frontera: `sre-practice-standards`,
`dns-standards`, `vpn-standards`, `kubernetes-standards`, `onprem-standards` (paraguas),
`identity-access-management-standards`, `linux-hardening-standards`,
`vulnerability-management-standards`, `finops-standards`, `offensive-security-standards` (**esta skill
es defensiva**), y `network-vendors-standards`, `wan-legacy-standards`, `telco-5g-standards`,
`high-speed-interconnect-standards` y `datacenter-facilities-standards` (**Ola 7, planificadas**).

**Principio rector**: **automatizar una red mal diseñada la rompe más rápido y en más sitios a la
vez.** La automatización no arregla el diseño: lo multiplica. Por eso el orden es **primero leer y
comprobar, después generar, y sólo al final aplicar**, y por eso la regla dura es que **un cambio de
red se revierte solo o no se aplica**.

## 2. Decisiones por defecto

> Versiones y licencias verificadas ago-2026 contra la **API JSON de PyPI**, los **feeds Atom de
> releases** y el fichero **`LICENSE` en crudo**. Re-verificar antes de fijar nada (§8).

| Ámbito | Por defecto | Alternativa justificable / vetado |
|---|---|---|
| Fuente de verdad | **NetBox 4.6.7** (30-jul-2026; **Apache-2.0**, verificado en `LICENSE.txt` en crudo) como SoT de **intención** | ❌ Hoja de cálculo; ❌ la configuración del equipo como SoT; ❌ poblarlo por descubrimiento y llamarlo intención |
| Modelo de datos | **Intención declarativa versionada** (YAML u objetos de NetBox) **con esquema validado en CI** | ❌ Intención incrustada en las plantillas; ❌ datos sin esquema |
| Orquestador general | **Ansible** (`ansible-core` 2.21.2, **GPL-3.0-or-later**) con colecciones de red, si ya es el estándar de la casa | Modelo de ejecución lento en flotas grandes y gestión de errores por host tosca |
| Framework en Python | **Nornir 3.6.0** (2-ago-2026, **Apache-2.0**) cuando hace falta lógica real, concurrencia y tests | Nornir es framework, no caja de herramientas: aporta inventario y paralelismo, **los drivers los pones tú** (`nornir-napalm` 0.6.0, `nornir-netmiko`) |
| Abstracción multi-fabricante | **NAPALM 5.2.0** (27-jul-2026, **Apache-2.0**) por `get_*` normalizados, `compare_config` y commit con confirmación | Cobertura de plataformas limitada y desigual: **verifica el driver de tu NOS antes de diseñar sobre él** |
| Transporte CLI | **netmiko 4.7.0** (12-may-2026, **MIT**) como opción segura; **scrapli** (**MIT**) por rendimiento, asincronismo o NETCONF | **scrapli está en transición** (§8): la última no-prerelease en PyPI es `2026.2.20` y la reescritura 2.0 va por *release candidate*. **No la fijes como default aún** |
| Plantillas | **Jinja 3.1.6** (**BSD-3-Clause**), con **plantillas tontas y datos ricos** | ❌ Lógica de negocio en la plantilla: código sin tests |
| Interfaz al equipo | **gNMI** para telemetría y, con soporte sólido, para configuración; **NETCONF (RFC 6241)** para configuración transaccional | **CLI** sólo cuando no hay modelo de datos; **RESTCONF (RFC 8040)** donde sea lo único disponible |
| Cliente gNMI | **`gnmic` 0.46.0** (14-may-2026, **Apache-2.0**, bajo la organización **openconfig**); **`pygnmi`** (BSD-3-Clause) desde Python | Escribir un cliente gRPC propio sin necesidad |
| Modelos YANG | **OpenConfig** primero en entorno multi-fabricante; **IETF** para lo básico (interfaces, IP, routing); **nativos** sólo para lo que ninguno cubre | ❌ Diseñar toda la automatización sobre modelos nativos: es CLI con otra sintaxis |
| Laboratorio virtual | **containerlab v0.77.0** (28-jun-2026; **BSD-3-Clause**, copyright **Nokia**, verificado en crudo) | **netlab** (paquete `networklab` 26.7, **MIT**) por encima; GNS3/EVE-NG y `vrnetlab` si sólo hay imágenes de VM. **Las imágenes de NOS tienen licencia propia y restricciones de redistribución: es un problema legal** |
| Validación | **Pre-checks y post-checks de estado operativo**, más análisis estático de configuración y validación de intención | ❌ Validar sólo que la configuración quedó escrita |
| Telemetría | **Streaming telemetry (gNMI `Subscribe`)** donde el NOS lo soporte; **SNMP como respaldo** | ❌ Sondeo SNMP masivo como única telemetría en flota grande |

## 3. El orden correcto y su estructura

**El orden, y no se salta ningún paso**
1. **Leer y comprobar** — inventario, estado actual, deriva contra el SoT. Todo lo de sólo lectura se
   automatiza primero: aporta valor sin riesgo y construye la confianza y el conocimiento del parque
   real antes de tocar nada.
2. **Generar** — configuración renderizada desde la intención, en un artefacto revisable. **El diff
   es el objeto que se revisa**, no la plantilla.
3. **Aplicar** — sólo al final, por lotes, con reversión armada.

**La fuente de verdad, decidida antes que la herramienta**
- **SoT de intención y SoT de descubrimiento son cosas distintas y no se mezclan.** NetBox contiene
  **lo que debe ser**; el descubrimiento produce **lo que hay**; la diferencia es **deriva**, y la
  deriva es un hallazgo con dueño. Autopoblar el SoT desde la red borra justamente esa señal.
- **Dónde vive cada cosa** (lo que `networking-standards` no decide): datos y relaciones en **NetBox**
  (sitios, dispositivos, interfaces, prefijos, VLAN, circuitos); parámetros que modulan la plantilla en
  **config contexts** jerárquicos; renderizado en **config templates** o en el repositorio Git. Regla
  de reparto: **si dos sistemas pueden responder a la misma pregunta con respuestas distintas, uno
  sobra.**
- **Todo dato de intención tiene esquema y se valida en CI**: un YAML sin esquema es un fallo en
  producción esperando al primer error tipográfico. Falla en el pipeline, no en el equipo.
- **El SoT se cierra en ambos sentidos**: tras cada cambio, el SoT refleja la realidad pretendida o el
  cambio no está terminado.

**Interfaces del dispositivo: el modelo de datos es lo que hace portable la automatización**
- **CLI por *screen-scraping*** funciona en todo y **se rompe con cualquier cosa**: un cambio de formato
  en una versión menor, un banner, un aviso, una salida paginada. No hay contrato, ni transacción, ni
  validación; y el parseo (TextFSM, TTP, plantillas propias) es código a mantener por plataforma y por
  versión.
- **NETCONF (RFC 6241) con YANG (RFC 7950)** aporta lo que la CLI no tiene: **datastore candidato,
  transacción, validación previa y commit confirmado**. Con **NMDA (RFC 8342)** la separación entre
  configuración pretendida, aplicada y estado operativo deja de ser ambigua — que es exactamente la
  distinción que permite verificar intención frente a realidad.
- **gNMI/gRPC** es la mejor opción para **telemetría** (suscripción, alta frecuencia, eficiente) y cada
  vez más válida para configuración; **su punto débil declarado es la transacción**, donde es más
  limitado que NETCONF.
- **El modelo de datos es la portabilidad**: escribir contra **OpenConfig** o modelos IETF significa que
  el mismo código sirve para otro fabricante; contra modelos nativos o CLI, significa reescribirlo en la
  siguiente compra. **El realismo es híbrido**: OpenConfig es operacionalmente completo, no exhaustivo,
  y la interoperabilidad real entre fabricantes sigue siendo imperfecta. Diseña con modelo estándar y
  **aísla en un adaptador** lo que exija modelo nativo o CLI.

**Plantillas**: datos ricos, plantillas tontas — toda decisión que se pueda tomar en el dato se toma en
el dato. Una plantilla por rol, componible por bloques, con **renderizado determinista** (mismo dato →
mismo texto, byte a byte) para que el `diff` signifique algo.

## 4. Pruebas, validación y CI/CD de red

- **Laboratorio virtual con las mismas versiones de NOS que producción**, y con la topología
  **generada desde el mismo SoT**: si el laboratorio se describe a mano, prueba otra red.
- **Pipeline de red, por coste creciente**: (1) lint y **validación de esquema** de la intención;
  (2) renderizado y **`diff` de configuración** como artefacto revisable en el PR; (3) análisis
  estático de la configuración renderizada (alcanzabilidad, política, errores de diseño) donde la
  herramienta lo permita; (4) despliegue en **laboratorio** y pruebas funcionales; (5) **lote canario**
  en producción con post-checks; (6) resto de la flota **por lotes**, con criterio de aborto entre lotes.
- **Pre-checks y post-checks sobre estado operativo, no sobre configuración**: lo que importa no es que
  la línea esté escrita, sino que **las adyacencias siguen arriba, los prefijos esperados siguen ahí,
  las interfaces no acumulan errores y el tráfico de aplicación pasa**. Se capturan antes, se comparan
  después, y la comparación es automática.
- **Validación de intención como gate continuo**: comprobación periódica de que la red se comporta como
  dice el SoT (rutas, vecinos, VLAN, deriva cero). Un fallo aquí es un hallazgo con dueño.
- **La regla dura: un cambio de red se revierte solo o no se aplica.** Reversión temporizada
  (`commit-confirm` o equivalente) armada **antes** del cambio, con ventana ajustada al tiempo de
  verificación, y el plan de reversión **probado en laboratorio** como parte del cambio: una reversión
  no ensayada no es un plan, es una esperanza. Siempre con consola OOB disponible.
- **Idempotencia comprobada**: la segunda ejecución no cambia nada. Si cambia, el playbook miente sobre
  el estado y no sirve para detectar deriva.

## 5. Seguridad: la automatización tiene las credenciales de toda la red

Es el riesgo dominante de esta skill: **quien controla el sistema de automatización controla todos los
equipos a la vez, con cambios que además parecen legítimos.**

- **Ninguna credencial en el repositorio ni en el inventario**: se obtienen en ejecución del gestor de
  secretos (`secrets-management-standards`); en CI, **OIDC/identidad de carga de trabajo** frente a
  claves estáticas de larga vida.
- **Cuentas de servicio nominadas, con mínimo privilegio**: una de **sólo lectura** para inventario,
  deriva y telemetría —que es la mayoría del trabajo— y otra distinta, de escritura, sólo para el paso
  de aplicación. **TACACS+ permite autorización por comando**: úsala para acotar qué puede hacer la
  cuenta de automatización (`routing-switching-standards`, `identity-access-management-standards`).
- **Credenciales efímeras y rotación**; nunca una contraseña compartida entre humanos y automatismos,
  porque destruye la trazabilidad de quién cambió qué.
- **Registro de cada cambio correlacionable extremo a extremo**: quién lo pidió, qué PR lo aprobó, qué
  ejecución lo aplicó, a qué dispositivos y con qué diff. Si los logs del dispositivo y los del
  automatismo no se cruzan, un cambio malicioso es indistinguible de uno rutinario.
- **El repositorio de configuración de red es un objetivo de alto valor**: contiene topología,
  direccionamiento, política de filtrado y —si alguien se descuidó— credenciales. Acceso restringido,
  revisión obligatoria, **firma de commits**, protección de rama y **escaneo de secretos como gate que
  rompe el build**. Un secreto que llegó al histórico está comprometido: se **rota**.
- **Configuraciones respaldadas: cifradas y saneadas** — contienen hashes de contraseñas, claves
  precompartidas, comunidades SNMP y certificados.
- **El sistema de automatización es infraestructura crítica**: red de gestión, superficie mínima,
  parcheo al día, MFA para quien lo opera, y plan de recuperación propio (si cae, no puedes ni cambiar
  ni revertir).
- **Cadena de suministro**: colecciones, paquetes de PyPI e imágenes de NOS **fijados por versión o
  digest**, con SCA en CI. Una colección comprometida ejecuta contra toda la flota.

## 6. Telemetría y operabilidad

- **Streaming frente a sondeo**: la suscripción (gNMI `Subscribe`, dial-in o dial-out) da mayor
  frecuencia, menor coste de CPU en el equipo y datos ya estructurados según el modelo YANG. El sondeo
  SNMP masivo escala mal y pierde los eventos cortos. **Criterio**: streaming donde el NOS lo soporte,
  **SNMP como respaldo** para el parque antiguo y lo que el modelo no exponga — no se apaga por dogma.
  La plataforma que recibe, almacena y alerta es de `observability-standards`.
- **Señales propias de la automatización**: tasa de éxito por ejecución y por dispositivo, **deriva
  detectada** (número y antigüedad), tiempo desde el commit hasta el cambio aplicado, número de
  reversiones, y **dispositivos no gestionados** — esos últimos son los que rompen los despliegues.
- **Cobertura declarada**: qué porcentaje del parque está automatizado y qué queda fuera, con motivo.
  Un parque medio automatizado es más peligroso que uno manual si nadie sabe cuál es cuál.
- **Toil**: tarea manual repetida tres veces es candidata a automatizar; y automatización que requiere
  intervención manual habitual está mal hecha (`sre-practice-standards`).

## 7. Sostenibilidad y prohibiciones

- **Empieza por lectura**: inventario, deriva y telemetría primero. Valor inmediato, riesgo nulo, y
  construye lo que hace viable la fase de escritura.
- **Cadencia**: revisar versión, **estado de mantenimiento y licencia** cada trimestre; fijar versiones
  y actualizar deliberadamente. **Una herramienta que cambia de licencia o entra en modo mantenimiento
  es una decisión de arquitectura**, no una nota al pie (`opensource-licensing-standards`).
- **Deprecación**: plantillas, playbooks y scripts sin uso se borran — el código muerto se ejecuta por
  accidente algún día.

**PROHIBIDO**
- ❌ **Aplicar a toda la flota sin lote de prueba.** Canario primero, lotes después, con criterio de
  aborto escrito entre lotes.
- ❌ **Automatizar sin inventario fiable**: sin SoT completo y correcto, se propagan errores a escala.
- ❌ **Guardar configuraciones con credenciales en claro en el repositorio** (o secretos en inventarios,
  variables de grupo, plantillas o logs de ejecución).
- ❌ **Confiar en la CLI cuando hay modelo de datos** disponible en la plataforma.
- ❌ Aplicar un cambio sin reversión armada y **probada**, o sin consola OOB disponible.
- ❌ Cambiar configuración a mano en producción "y ya lo meteré en el repo luego".
- ❌ Poblar el SoT por descubrimiento automático y llamarlo intención.
- ❌ Datos de intención sin esquema ni validación en CI.
- ❌ Lógica de negocio dentro de las plantillas Jinja.
- ❌ Revisar la plantilla en el PR en lugar del **diff de configuración renderizada**.
- ❌ Post-checks que sólo verifican que la configuración quedó escrita.
- ❌ Ejecutar con una cuenta de administrador compartida, o con la misma credencial para lectura y
  escritura.
- ❌ Credenciales de larga vida en CI pudiendo usar OIDC/identidad de carga de trabajo.
- ❌ Colecciones, paquetes o imágenes sin fijar versión ni digest.
- ❌ Automatizar una red cuyo diseño no está resuelto: se arregla el diseño primero
  (`routing-switching-standards`, `datacenter-fabric-standards`).
- ❌ Playbook no idempotente usado como detector de deriva.
- ❌ Redistribuir imágenes de NOS de un laboratorio virtual sin comprobar su licencia.

## 8. Verificación web obligatoria

**Metodología**: versiones desde la **API JSON de PyPI** y los **feeds Atom de releases de GitHub**
(`api.github.com` devuelve 403 sin autenticar); **licencias leídas del fichero `LICENSE` en crudo**, no
de la etiqueta que muestra la interfaz de GitHub ni de un resumen.

**Verificado ago-2026 (versión | fecha | licencia comprobada en crudo)**. **NetBox 4.6.7** |
30-jul-2026 | **Apache-2.0** (`LICENSE.txt` en `main` y `master`; `LICENSE` a secas **da 404** — la
ruta importa al verificar), con `v4.6.8-rc2` en vuelo (4-ago-2026). **Nornir 3.6.0** | 2-ago-2026 |
**Apache-2.0** (cadencia lenta pero viva: 3.5.0 era de ene-2025). **NAPALM 5.2.0** | 27-jul-2026 |
**Apache-2.0**. **netmiko 4.7.0** | 12-may-2026 | **MIT**. **Jinja2 3.1.6** | **BSD-3-Clause**.
**ansible-core 2.21.2** | **GPL-3.0-or-later**. **pygnmi 0.8.15** | **BSD-3-Clause**.
**gnmic 0.46.0** | 14-may-2026 | **Apache-2.0**, y **vive bajo la organización `openconfig`**, no bajo
el repositorio personal original: proyecto **mudado**, y buscar el repo viejo da falsa impresión de
abandono. **containerlab v0.77.0** | 28-jun-2026 | **BSD-3-Clause con copyright de Nokia** (leído en
`LICENSE` en crudo): **no es Apache-2.0**, que es la suposición habitual. **netlab** = paquete PyPI
**`networklab` 26.7** | **MIT** (ipspace y colaboradores), CalVer, y **el nombre del paquete no
coincide con el del proyecto**.

**Discrepancia declarada — scrapli**: **GitHub y PyPI dan versiones distintas para lo mismo.** El feed
Atom muestra `v2.0.0-rc.16` (20-jul-2026); PyPI publica ese artefacto como `2026.7.20rc16` y declara
como versión actual **`2026.2.20`** (feb-2026), porque bajo PEP 440 la CalVer ordena por encima de
`2.0.0rc`. **Conclusión operativa**: la reescritura 2.0 está en *release candidate*, un
`pip install scrapli` sin `--pre` instala la línea CalVer de feb-2026, y **fijar scrapli 2.0 como
default hoy es prematuro**.

**Estado de OpenConfig/gNMI (cualitativo)**: proyecto activo (gnmic, ygot, ygnmi, gNOI y
`featureprofiles` con actividad en 2026). Los modelos se escriben en **YANG 1.0** y son
"operacionalmente completos", no exhaustivos; **la interoperabilidad real entre fabricantes sigue
siendo imperfecta**, y gNMI es **más débil que NETCONF para configuración transaccional** (aunque la
especificación exige que un `SetRequest` que abarque varios *origins* se trate como una transacción con
rollback). **No se encontró ningún dato autoritativo de cuota de adopción**: trata cualquier cifra sobre
adopción de OpenConfig o gNMI como no verificada.

**RFC verificados uno a uno contra `rfc-editor.org`**: NETCONF **RFC 6241** (jun-2011, actualizado por
7803 y 8526); RESTCONF **RFC 8040** (feb-2017, actualizado por 8527); YANG 1.1 **RFC 7950** (ago-2016,
actualizado por 8342 y 8526); NMDA **RFC 8342** (mar-2018); YANG Library **RFC 8525** (mar-2019,
obsoleta RFC 7895).

**Huecos declarados — NO rellenar de memoria**:
1. **Versiones y estado de las colecciones de red de Ansible** (`ansible.netcommon`, `cisco.ios`,
   `arista.eos`, `junipernetworks.junos`, `nokia.srlinux`): **no verificadas**; su cadencia es
   independiente de `ansible-core`.
2. **Cobertura real de NAPALM por plataforma y versión de NOS**: **no verificada**, y es lo que decide
   si NAPALM sirve en tu parque.
3. **Estado, versión y licencia de Batfish y de pyATS/Genie**: **no verificados**; se mencionan como
   categoría, **no como default fijado**.
4. **Estado y licencia de GNS3, EVE-NG y `vrnetlab`**: **no verificados**. EVE-NG tiene ediciones
   comerciales: comprueba la edición concreta.
5. **Licencia y redistribución de las imágenes de NOS** de laboratorio: **específicas de cada
   fabricante y no verificadas**. Es cuestión legal (`opensource-licensing-standards`).
6. **Soporte de gNMI y NETCONF por plataforma y versión de NOS**, y los modelos concretos expuestos:
   **no verificado**. Compruébalo con `Capabilities` en el equipo real.
7. **Relación entre NetBox Community (Apache-2.0) y las ofertas comerciales de NetBox Labs** y qué
   funcionalidad queda fuera de la edición abierta: **no verificada**.
8. **`ncclient`, `pyang`, TextFSM/`ntc-templates` y TTP**: versión, mantenimiento y licencia **no
   verificados**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
