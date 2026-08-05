---
name: cmdb-inventory-standards
description: Knowing what you actually own — asset inventory and CMDB as engineering artifacts, not audit paperwork. Use when choosing or operating NetBox (DCIM racks/devices/interfaces, IPAM prefixes/IP ranges, cables, virtual machines, custom fields, Diode ingestion, Orb discovery agent, NetBox Assurance drift), Nautobot, GLPI and the GLPI Agent, Snipe-IT, Ralph, i-doit, OCS Inventory or a ServiceNow CMDB aligned to CSDM, populating records by automated discovery (Nmap sweeps, LLDP/CDP neighbours, SNMP, osquery, cloud provider APIs, hypervisor and Kubernetes APIs, agent check-ins) versus manual entry, reconciling conflicting data from several sources and deciding which wins per attribute, picking a stable unique asset identifier that is not the hostname or the IP, modelling service dependency and CI relationships so an incident can answer "what breaks if this dies", tracking hardware and software asset lifecycle from purchase to disposal, finding the running server nobody can explain or switch off, stale record detection and inventory coverage metrics, software license entitlement and true-up audits, or asserting that Terraform state, a monitoring target list or a spreadsheet is the inventory.
---

# Estándares de inventario y CMDB

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **saber qué tienes**: el modelo de datos del activo, cómo se puebla (descubrimiento frente a
declaración), cómo se reconcilian fuentes que se contradicen, qué identificador lo hace estable en el
tiempo, qué relaciones se modelan para que el dato sirva en un incidente, y el ciclo de vida del
activo hasta su retirada. Cubre tanto el **inventario de hardware/software** (qué máquinas y qué
licencias) como la **CMDB** (qué elementos de configuración existen y cómo se relacionan).

**La distinción que decide todo el diseño**: una **CMDB registra intención** —lo que debería existir,
con su dueño, su criticidad, su contrato y sus relaciones— mientras que un **inventario descubierto
registra realidad** —lo que hoy responde en la red. **No son la misma base de datos y no se pueblan
igual.** Fusionarlas produce el fallo clásico: una CMDB mantenida a mano que **está caducada a los
tres meses**, que nadie consulta porque no se fía, y que se sigue rellenando solo para el auditor. La
arquitectura correcta es explícita: **el descubrimiento puebla la realidad; la intención se declara;
la diferencia entre ambas es un hallazgo**, no un error de datos.

Triggers: "inventario", "CMDB", "CI", "activo", "¿qué es esta máquina?", "¿esto se puede apagar?",
"¿qué se cae si apago esto?", NetBox (`dcim`, `ipam`, `tenancy`, `virtualization`, `custom_fields`,
Diode, Orb agent, Assurance), Nautobot, GLPI / `glpi-agent`, Snipe-IT, Ralph, i-doit, OCS Inventory,
`cmdb_ci`, CSDM, `osquery`/`osqueryd`, `lldpctl`, `snmpwalk`, barrido `nmap -sn`,
`aws ec2 describe-instances` como fuente de inventario, número de serie / UUID de DMI, `dmidecode -s
system-serial-number`, "true-up de licencias", "activo huérfano", "servidor que nadie apaga".

**No aplica**: ver `itsm-itil-standards` (**frontera dura y recíproca**: allí la **CMDB como práctica
ITIL** —el proceso, quién la gobierna, su relación con cambio, incidente y problema, y el criterio de
"si no responde preguntas que se hacen de verdad, no se construye"—; **aquí la ingeniería del dato**:
modelo, identificador, descubrimiento, reconciliación, métricas de frescura y automatización. Regla
de arbitraje: *"¿qué proceso la mantiene y para qué decisión de servicio?"* es de allí; *"¿de dónde
sale cada atributo, quién gana cuando dos fuentes discrepan y cómo sé que está fresco?"* es de aquí),
`iac-standards` (**el estado de Terraform/OpenTofu NO es una CMDB** — §3.5 —; allí el código y su
estado, aquí el inventario que lo consume y lo contrasta; Ansible **lee** el inventario, no lo
sustituye), `onprem-standards` (**paraguas**: su invariante *ningún dato de host de memoria — se
consulta el inventario* es precisamente lo que esta skill hace posible; y su §1.2 debería enrutar
aquí), `os-provisioning-standards` (**el alta automática del host recién instalado**: allí el gancho,
aquí el modelo donde aterriza), `server-hardware-standards` (garantía, contrato, número de serie y
ciclo de vida del **hierro**; aquí el registro de todo eso y su caducidad),
`networking-standards` (**el diseño** de direccionamiento; **el IPAM como registro** es de aquí),
`network-automation-standards` (**la red como código**: si NetBox alimenta plantillas de
configuración, generarlas y desplegarlas es suyo), `vulnerability-management-standards` (**el
inventario es su precondición**: no se prioriza lo que no se sabe que existe),
`grc-compliance-standards` (el inventario como **control** exigido por ISO 27001/ENS),
`bcdr-standards` (**el grafo de dependencias para la secuencia de recuperación** es suyo; aquí el
grafo como dato mantenido), `opensource-licensing-standards` (licencias **de dependencias** y SBOM;
aquí licencias **compradas** frente a lo instalado), `finops-standards` (coste y etiquetado en nube),
`data-governance-quality-standards` (calidad del dato como disciplina general),
`macos-fleet-standards` y `developer-workstation-standards` (**el MDM es la fuente de inventario del
endpoint**), `datacenter-facilities-standards` (**Ola 7, planificada**: rack, energía y espacio
físico — aquí solo su representación en DCIM).

## 2. Decisiones por defecto

> Verificar la última versión, licencia y estado del proyecto por web antes de fijarlo (§8).
> Licencias comprobadas leyendo el fichero en crudo (§8 declara los huecos).

| Necesidad | Por defecto | Versión / licencia verificada (ago-2026) | Alternativa justificable |
|---|---|---|---|
| Fuente de verdad de **red, IPAM y rack** | **NetBox** | v4.6.7 (30-jul-2026); **Apache-2.0** (`LICENSE.txt` en crudo) | **Nautobot** (v3.2.2, 3-ago-2026; **Apache-2.0**) si necesitas *jobs* y extensibilidad tipo plataforma de automatización |
| Inventario de **activos de TI y helpdesk** | **GLPI** + `glpi-agent` | **GPL-3.0** (`LICENSE` en crudo) | **i-doit** si el modelo de CI relacional es el eje; **Ralph** (Apache-2.0) en parques grandes de DC |
| **Gestión de activos** pura (compra, garantía, asignación a personas) | **Snipe-IT** | **AGPL-3.0** (`LICENSE` en crudo) | Módulo de activos de GLPI si ya lo tienes: **una herramienta menos vale más que la herramienta perfecta** |
| **Descubrimiento en el host** | **osquery** | **Apache-2.0 OR GPL-2.0-only** (dual, declarado en `LICENSE`) | Agente de GLPI/OCS si ya está desplegado |
| CMDB corporativa con proceso ITSM encima | **ServiceNow alineado a CSDM** | **CSDM 5.0** (may-2025): 7 dominios, *Foundation* primero | Solo si ya hay ServiceNow. **CSDM no se compra: se implanta alineando datos** |
| Descubrimiento y detección de deriva sobre NetBox | **Orb agent** (open source, *public preview*) → **Diode** → **NetBox Assurance** | Backends `network_discovery`, `device_discovery`, `snmp_discovery`, `gnmi_discovery` (beta) | Scripts propios contra APIs de hipervisor/nube: perfectamente válido y a menudo suficiente |
| Fuente para nube y virtualización | **La API del proveedor / del hipervisor**, sondeada periódicamente | — | Nunca un CSV exportado a mano |

**Regla de selección por encima de la tabla**: elige **la herramienta que puedas poblar
automáticamente el lunes siguiente**. Una CMDB con el mejor modelo de datos y sin descubrimiento
pierde contra un NetBox feo poblado por API.

## 3. Modelo de datos: lo que decide si sirve o no

### 3.1 El identificador estable

**Ni el hostname ni la IP identifican un activo.** Ambos cambian, se reutilizan y colisionan; un
inventario indexado por hostname produce activos duplicados y activos fusionados por error, que es
peor. Regla:

- **Hardware físico**: **número de serie del fabricante** (y, si el modelo lo permite, UUID de DMI).
  Es el único identificador que sobrevive al reinstall, al cambio de nombre y al traslado de rack, y
  el único que casa con la garantía y el contrato de soporte.
- **Máquina virtual / instancia**: el **UUID o ID de la plataforma** (`instance-id`, `vm.uuid`).
- **Identificador propio del inventario**: clave sintética inmutable propia (nunca reutilizada tras
  la baja), porque el serial de un chasis reemplazado en garantía **cambia**.
- El hostname, la IP y la MAC son **atributos**, buscables y con historia. Nunca claves primarias.

### 3.2 Intención frente a descubrimiento, por atributo

Cada atributo tiene **una** fuente autoritativa declarada, y el resto son observaciones. Lo
descubrible se descubre; lo que ninguna herramienta puede saber se declara y **caduca**:

| Tipo de atributo | Fuente autoritativa | Ejemplos |
|---|---|---|
| Descubrible en el sistema | Agente / API | modelo, CPU, RAM, discos, SO y versión, paquetes, servicios, IP en uso, vecinos LLDP |
| Descubrible en la plataforma | API del hipervisor/nube/K8s | estado, host físico, red, etiquetas, fecha de creación |
| **Solo declarable** | Persona, con **fecha de revisión** | **dueño**, criticidad de negocio, entorno, contrato y garantía, propósito, clasificación del dato, servicio al que pertenece |

**La fila de abajo es la que da valor y la que se pudre.** Un atributo declarado sin fecha de
revisión es un atributo falso con antigüedad desconocida: se le pone caducidad (12 meses como
máximo) y se revisa, o se elimina del modelo.

### 3.3 Reconciliación: quién gana cuando dos fuentes discrepan

- **Precedencia declarada por atributo, no por fuente global.** El hipervisor gana en "cuánta RAM
  tiene"; el agente gana en "qué SO corre"; el humano gana en "quién es el dueño". Escrito, en el
  repositorio, no en la cabeza del que montó la integración.
- **Emparejamiento en cascada**: serial → UUID → MAC → (último recurso) hostname+dominio. Un
  emparejamiento por hostname **se marca como de baja confianza** y se revisa a mano.
- **La discrepancia no se resuelve pisando el dato: se registra.** Una máquina descubierta que no
  está declarada es *shadow IT* o un despliegue fuera de proceso; una declarada que no se descubre
  es un activo muerto o un fallo de cobertura. **Ambas son hallazgos con dueño y plazo**, y ese flujo
  —no el informe— es lo que mantiene viva la base de datos.
- **NetBox es deliberadamente intención**, y esto se cita literal de su documentación porque decide
  la arquitectura: *"NetBox intends to represent the desired state of a network versus its
  operational state"* y *"All data created in NetBox should first be vetted by a human to ensure its
  integrity"*. Su documentación excluye explícitamente *"Network monitoring"*, *"DNS server"*,
  *"RADIUS server"*, *"Configuration management"* y *"Facilities management"*. Conclusión operativa:
  **volcar descubrimiento crudo dentro de NetBox rompe su modelo**; el descubrimiento entra por un
  canal de ingesta con revisión (Diode/Assurance o el tuyo) y produce *diffs*, no escrituras.

### 3.4 Relaciones: lo único que hace útil una CMDB en un incidente

Un inventario plano de 4.000 filas no responde la única pregunta que se hace de madrugada: **"si esto
se cae, ¿qué deja de funcionar, y a quién aviso?"**. Modela, como mínimo y en este orden de valor:

1. **Servicio de negocio → sistemas que lo implementan → CI de infraestructura** (la cadena que
   convierte un host caído en un impacto explicable).
2. **Dependencias entre servicios** (llama a / depende de), incluidas las **externas y SaaS**.
3. **Ubicación física y alimentación** (rack, unidad, PDU, circuito): un mantenimiento eléctrico
   necesita esta relación y no la tiene casi nadie.
4. **Dueño técnico y dueño de negocio**, nominales. Un CI sin dueño es un CI que nadie revisará.

**Profundidad mínima viable**: modela solo las relaciones que alguien va a consultar. Un grafo
completo y sin mantener miente más que un grafo parcial y fresco.

### 3.5 Por qué el estado de Terraform no es una CMDB

Razones estructurales, no de madurez: **(1)** solo contiene lo que ese código creó —el hierro, lo
manual y lo heredado no existen—; **(2)** está **fragmentado** en decenas de ficheros de estado sin
identificador común ni vista global; **(3)** no modela servicios, dueños ni criticidad; **(4)**
**contiene secretos en claro**, luego no puede tener los permisos de lectura amplios que un
inventario necesita; **(5)** su ciclo de vida es el del `apply`: un recurso destruido desaparece,
mientras el inventario debe **conservar el activo retirado con su historia**. Uso correcto: el estado
es una **fuente que alimenta** el inventario, igual que el hipervisor.

## 4. Calidad del dato: las métricas que deciden si sigue viva

> *(Se omite §6 "Rendimiento y operabilidad" del formato: en este dominio se reduce a operar una
> aplicación web y su base de datos, que no es criterio propio de la skill.)*

Publicadas en un panel visible, no en un informe trimestral:

- **Cobertura**: % de activos descubiertos que existen en el inventario, y su inverso —**activos
  declarados que llevan N días sin verse**—. La cobertura se mide contra una fuente independiente
  (barrido de red, tabla ARP/MAC del switch, facturación de nube), nunca contra sí misma.
- **Frescura**: % de CI con descubrimiento en las últimas 24 h; edad del atributo declarado más
  antiguo. **Un CI sin ver en 30 días se marca `stale` y sale de los informes**, no se borra.
- **Completitud de lo que no se descubre**: % de activos con dueño nominal, criticidad y contrato.
  Suele ser la métrica más baja y la más cara de subir; es también la que da todo el valor.
- **Uso**: consultas y llamadas a la API por semana, y **desde qué sistemas**. Es la métrica de
  supervivencia: *una CMDB que nadie consulta se apaga, no se mejora* (criterio compartido con
  `itsm-itil-standards`).
- **Gate de CI recomendado**: la automatización que consume el inventario **falla** si el registro
  del host que va a tocar está `stale` o carece de dueño. Es lo que convierte la calidad del dato en
  un problema de quien la degrada, y no del que la mantiene.

## 5. Seguridad del inventario

- **Un inventario completo es un mapa de ataque**: topología, versiones de SO, servicios y a veces
  credenciales de gestión. Sistema **de alto valor**: SSO con MFA, RBAC por ámbito, tokens de API con
  permisos mínimos y caducidad, y **auditoría de lectura**, no solo de escritura.
- **PROHIBIDO guardar secretos en el inventario** (contraseñas de BMC, comunidades SNMP, claves): van
  al gestor de secretos, aquí solo **la referencia**.
- **Las credenciales del descubrimiento son el eslabón débil**: cuenta dedicada, **solo lectura**,
  por segmento, rotada, y **jamás la misma que usa la automatización para cambiar cosas**.
- **Un barrido es tráfico que el IDS debe conocer**: acordado, con ventana y origen fijo. `nmap`
  agresivo contra OT/ICS o cabinas antiguas puede tirarlas — en esos segmentos, descubrimiento
  pasivo (LLDP, ARP, flujos) antes que activo.
- **La herramienta también tiene CVEs**: a ago-2026 NetBox corrigió **CVE-2026-29514** (ejecución
  arbitraria de código vía `environment_params` de `ExportTemplate`).
- **Baja del activo = baja de sus accesos**: la retirada dispara la revocación de credenciales,
  certificados y reglas de firewall. Sin ese enlace, documentas que el hierro se fue y dejas viva su
  identidad.

## 6. Ciclo de vida y el activo que nadie sabe qué hace

Estados mínimos y explícitos: `planificado → en aprovisionamiento → en producción → obsoleto (fin de
soporte fechado) → retirado → destruido (con certificado de borrado)`. Cada transición tiene dueño y
fecha; **"obsoleto" con fecha de fin de soporte es el dato que alimenta el plan de renovación** y el
único que evita descubrir un EOL el día que hay que parchear.

**El caso duro y universal: la máquina encendida que nadie sabe explicar.** No se apaga a ciegas y
tampoco se deja para siempre. Procedimiento con dueño y plazo:

1. **Observar antes de tocar**: durante **un ciclo completo de negocio, cierre anual incluido** —qué
   conexiones entra y salen, qué procesos, qué trabajos programados, quién se autentica—. La
   integración que nadie recuerda aparece en el cierre de ejercicio, no en abril.
2. **Buscar el dueño por evidencia, no por memoria**: quién entra por SSH, a qué correo escriben sus
   `cron`, qué certificado presenta, qué factura o contrato lo referencia, quién lo creó según la
   auditoría del hipervisor.
3. Si sigue sin dueño: **apagado reversible con aviso** —anuncio con plazo, apagado en ventana con
   plan de reversión inmediata y **el sistema conservado, no destruido**, un periodo definido (60–90
   días es lo habitual; fíjalo tú)—. Es la única forma honesta de descubrir para qué servía.
4. **Destruir solo tras el periodo de cuarentena**, con copia restaurable verificada y borrado
   certificado. Y con el registro conservado en el inventario: **el activo retirado no se borra de la
   base de datos, se archiva**.

## 7. Sostenibilidad y prohibiciones

- ❌ **PROHIBIDO** un identificador de activo basado en hostname o IP (§3.1).
- ❌ **PROHIBIDO** poblar la CMDB a mano lo que una API puede descubrir. Es la causa directa de que
  caduque en tres meses.
- ❌ Atributo declarado (dueño, criticidad, contrato) **sin fecha de revisión**.
- ❌ Volcar descubrimiento crudo sobre NetBox: rompe su modelo de intención (§3.3).
- ❌ Presentar el **estado de Terraform**, la lista de *targets* de Prometheus, el DNS o una hoja de
  cálculo como "el inventario" (§3.5).
- ❌ Dos fuentes escribiendo el mismo atributo sin precedencia declarada.
- ❌ Secretos dentro del inventario, o credenciales de descubrimiento con permisos de escritura (§5).
- ❌ Borrar el registro del activo al retirarlo: se archiva con su historia.
- ❌ Modelar un grafo de relaciones exhaustivo que nadie va a mantener (§3.4).
- ❌ Mantener una CMDB cuyo único consumidor es el auditor. **Si no responde preguntas reales, se
  apaga** — criterio compartido y no negociable con `itsm-itil-standards`.
- ❌ Apagar un servidor desconocido sin el ciclo de observación de §6 — y también dejarlo encendido
  indefinidamente "por si acaso": ambas son la misma renuncia a decidir.
- ❌ Comprar una herramienta de CMDB antes de haber decidido **qué preguntas debe responder** y
  **de qué fuente sale cada atributo**.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar por web —con cita literal, no con resumen automático:

1. **NetBox**: versión vigente (a ago-2026, **v4.6.7**, 30-jul-2026) y CVEs abiertos. **Licencia
   verificada leyendo `LICENSE.txt` en crudo: Apache-2.0** — nótese que el fichero **no** se llama
   `LICENSE`, que devuelve 404. **Hueco declarado: no se verificó el reparto exacto de funciones
   entre NetBox Community, NetBox Enterprise y NetBox Cloud de NetBox Labs**, ni si Assurance/Diode
   requieren licencia comercial. Antes de diseñar sobre Assurance, confírmalo con el fabricante.
2. **Nautobot**: v3.2.2 (3-ago-2026), **Apache-2.0** verificado en crudo. Mantiene además una rama
   2.4.x viva: comprueba cuál es la soportada para ti.
3. **GLPI (GPL-3.0)**, **Snipe-IT (AGPL-3.0)** y **Ralph (Apache-2.0)**: licencias verificadas en
   crudo. **AGPL en Snipe-IT importa** si piensas ofrecerlo como servicio a terceros o modificarlo.
   **Hueco declarado: no se verificó la versión vigente de ninguna de las tres**, ni la licencia real
   de **i-doit Open** (la comunidad la cita como AGPLv3 y el fabricante mantiene el producto —hay
   noticia de reorganización interna en ene-2026—, pero **no se leyó el fichero en crudo** y existe
   debate público sobre qué queda fuera de la edición Open). Léela antes de citarla.
4. **osquery**: **doble licencia `Apache-2.0 OR GPL-2.0-only`**, declarada en su `LICENSE`. La
   elección es tuya y tiene consecuencias si redistribuyes: no lo cites como "Apache" a secas.
5. **ServiceNow CSDM**: versión vigente del modelo (**5.0**, may-2025, 7 dominios) y su mapeo con la
   release de plataforma que tengas. **Hueco declarado: los nombres de los 7 dominios proceden de
   fuentes de partner, no del portal oficial de ServiceNow**; confírmalos ahí antes de usarlos en un
   diseño.
6. **Orb agent / Diode / Assurance**: siguen etiquetados como *public preview* en la documentación
   consultada. Verifica su madurez y su modelo de licencia antes de hacerlos dependencia.
7. **Normativa**: si el inventario es evidencia de cumplimiento (ISO 27001 A.5.9, ENS, NIS2),
   comprueba el texto vigente del control — el alcance exigido (¿incluye software? ¿SaaS? ¿datos?)
   cambia entre revisiones y es lo que fija qué debes modelar.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
