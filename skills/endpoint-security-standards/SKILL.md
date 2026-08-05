---
name: endpoint-security-standards
description: Defending the endpoint as a control, and measuring whether the control is actually there. Use when selecting or operating an EDR/XDR agent (Microsoft Defender for Endpoint, CrowdStrike Falcon, SentinelOne, Elastic Defend) and deciding what to demand of it in a bake-off, weighing signature antivirus against behavioural telemetry, deploying application control with App Control for Business / WDAC versus AppLocker and its MSRC servicing-criteria gap, WDAC policy in audit versus enforced mode and managed installer, Attack Surface Reduction rules, LSA protection and Credential Guard, disk encryption posture with BitLocker TPM-only versus TPM+PIN, manage-bde protectors and recovery-key escrow, UEFI Secure Boot, Measured Boot and TPM PCR attestation, endpoint patch and third-party update coverage, EDR sensors on Linux (eBPF sensor versus loadable kernel module) and on macOS (Apple Endpoint Security API ceilings), the security agent itself as attack surface and as an availability risk after the July 2024 CrowdStrike Channel File 291 incident, Microsoft's Windows Endpoint Security Platform and the MVI move out of kernel mode, defensive awareness of BYOVD and userland unhooking, BYOD and MDM enrolment posture, endpoint DLP and why it leaks, or reporting real fleet agent coverage instead of licences purchased.
---

# Estándares de seguridad del endpoint

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **la defensa del puesto y su medición**: elección y exigencias reales a un EDR/XDR,
techo del antivirus por firmas, control de aplicaciones, cifrado de disco y custodia de la
clave de recuperación, arranque seguro y medido y atestación, parcheo del endpoint y del
software de terceros, endurecimiento de credenciales locales, cobertura de agente en Linux y
macOS y sus límites reales, **el propio agente como superficie de ataque y como riesgo de
disponibilidad**, política BYOD y MDM, DLP en el endpoint, y las métricas que importan.

Triggers: EDR, XDR, MDE/Defender for Endpoint, Falcon, SentinelOne, Elastic Defend,
`WDAC`/App Control for Business, `AppLocker`, `CIPolicy`/`.cip`, ASR rules, Credential Guard,
LSA protection, `manage-bde`, BitLocker TPM+PIN, clave de recuperación, Secure Boot, Measured
Boot, PCR, atestación, sensor eBPF vs módulo del kernel, Apple Endpoint Security API,
BYOVD, *unhooking*, MDM, BYOD, DLP de endpoint, "cobertura de agentes".

**Postura estrictamente defensiva.** Las técnicas de evasión se describen **para detectarlas
y para evaluar producto**, nunca como procedimiento.

**No aplica**: ver `detection-engineering-standards` (**la regla de detección y su ingeniería
son suyas, sin excepción**: Sigma, contenido del SIEM, normalización, cobertura, tests de
detección. **Aquí el sensor que produce la telemetría y si está puesto**; allí qué se hace
con ella), `soc-operations-standards` (turno, cola, triaje y cierre de la alerta que genera
tu agente), `incident-response-forensics-standards` (**el compromiso ya confirmado**:
contención, adquisición, timeline, reconstrucción — aquí solo el aislamiento como
**capacidad** que se le exige al producto y se ensaya), `macos-fleet-standards` (**la flota
Apple es suya**: ABM/ADE, MDM y DDM, perfiles, TCC/PPPC, Gatekeeper, XProtect, escrow de
FileVault, extensiones de sistema. **Aquí solo qué se le puede exigir a un EDR de terceros en
macOS y qué no, y por qué**), `developer-workstation-standards` (**el puesto de quien
programa**: dotfiles, provisión como código, cadena de suministro del editor, claves en
hardware — **frontera real: una política de endpoint mal hecha rompe herramientas de
desarrollo**, y se negocia nombrando a las dos partes), `linux-hardening-standards` (**el
baseline del sistema Linux**: CIS/STIG, `sysctl`, auditd, SSH, montajes, LUKS con desbloqueo
desatendido, medición con OpenSCAP/Lynis — aquí solo el **sensor EDR** sobre ese host y sus
límites), `windows-server-ad-standards` (el servidor, el directorio, Tier 0/PAW, LAPS y
gMSA), `container-runtime-security-standards` (**el contenedor y el escape**: seccomp,
capabilities, Falco/Tetragon, drift — un EDR de endpoint no cubre eso),
`vulnerability-management-standards` (triaje CVE y SLA de remediación; aquí solo la
**capacidad de desplegar** el parche y su cobertura), `identity-access-management-standards`
(IdP, MFA, sesiones), `cryptography-pki-standards` (algoritmos, modos, KMS y ciclo de vida de
claves; aquí solo la **postura** de cifrado del disco), `privacy-engineering-standards` (dato
personal, minimización y clasificación que el DLP presupone), `grc-compliance-standards`
(marco de control y evidencia), `email-security-standards` (el correo como canal de entrada),
`mobile-standards` (iOS/Android como plataforma de aplicación),
`ot-ics-security-standards` (**Ola 7, hermana**: el endpoint industrial que **no admite
agente** y por qué), `offensive-security-standards` (ejercicio ofensivo con alcance y
autorización por escrito; esta skill no lo ejecuta), `threat-intelligence-standards`.

## 2. Decisiones por defecto

> Verificar versión, nombre exacto de la característica y fechas por web antes de fijarlas
> (§8). Microsoft ha **renombrado** varias de estas y la documentación va desacompasada.

| Necesidad | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| Detección en el endpoint | **EDR con telemetría de proceso y respuesta remota**, con retención medida | AV gestionado + telemetría a SIEM en flotas pequeñas | AV solo por firmas como única defensa |
| Control de aplicaciones (Windows) | **App Control for Business (WDAC)** | AppLocker solo como capa de conveniencia o donde WDAC no llegue | **AppLocker como frontera de seguridad** (§3) |
| Despliegue de control de apps | **Audit primero, medido, luego enforced** por anillos | Enforcement directo solo en equipos de propósito fijo (quiosco, cajero, EWS) | Pasar a *enforce* toda la flota a la vez |
| Cifrado de disco (Windows) | **BitLocker con TPM+PIN** en portátiles y equipos que salen | TPM-only **solo** si el equipo no sale de zona controlada y hay control físico | TPM-only en un portátil; clave de recuperación sin custodia |
| Arranque | **UEFI Secure Boot activo + Measured Boot** y PCR revisados | — | Secure Boot desactivado "porque un driver no arranca" |
| Sensor en Linux | **eBPF** con suelo de versión de kernel verificado | Módulo del kernel solo si el kernel no llega y con plan de salida | Módulo propietario en kernels que el proveedor no valida |
| Sensor en macOS | Agente sobre **Apple Endpoint Security** (+ NetworkExtension) | — | Producto que aún dependa de *kexts* y exija bajar la seguridad de arranque |
| Actualización del agente | **Anillos + despliegue escalonado del contenido**, no solo del binario | — | Actualización de contenido *n-0* simultánea en toda la flota (§5) |
| Métrica de cobertura | **% de activos del inventario con agente sano y reportando en las últimas 24 h** | — | Contar licencias compradas o consolas instaladas |

## 3. Control de aplicaciones: la diferencia que decide

- **Dato duro, y es el que casi nadie cita bien**: Microsoft documenta que **App Control for
  Business (antes WDAC)** *"was designed as a security feature under the servicing criteria
  defined by the Microsoft Security Response Center (MSRC)"*, mientras que **AppLocker**
  *"doesn't meet the servicing criteria for being a security feature"*.
  **Consecuencia operativa**: un *bypass* de AppLocker **no es necesariamente** una
  vulnerabilidad que MSRC parchee; uno de App Control sí. Por eso AppLocker **no puede ser tu
  frontera de seguridad**: sirve como capa de higiene, no como control del que dependas.
  Microsoft recomienda explícitamente WDAC/App Control a quien pueda implementarlo, y AppLocker
  **solo recibe correcciones de seguridad, no mejoras funcionales**.
- Matices que hay que conocer antes de diseñar: la política de App Control aplica **a toda la
  máquina** (no por usuario; AppLocker sí distingue usuarios y grupos); sus reglas se basan en
  atributos del certificado de firma, metadatos firmados del binario o hash, **sin regla por
  ruta** (AppLocker sí la tiene, y por eso es más fácil de eludir); y **algunas
  funcionalidades de App Control usan AppLocker por debajo** — señaladamente el *managed
  installer*. No son alternativas limpias, se solapan.
- El nombre cambió (**WDAC → App Control for Business**) y la documentación de Microsoft no
  está sincronizada entre páginas: la FAQ suele ir más actualizada que las de visión general.
  **Verifica el nombre y el comportamiento vigentes antes de escribir una política (§8).**
- Regla de despliegue: **audit → medir el ruido → excepciones nominadas y con dueño →
  enforce por anillos**. Una política de control de aplicaciones desplegada en *enforce* sin
  fase de auditoría es un incidente de disponibilidad autoinfligido, y se revierte en pánico
  — que es exactamente cómo mueren estos proyectos.

## 4. Cifrado, arranque y credenciales locales

- **BitLocker en modo TPM-only libera la clave sin intervención del usuario**, y esa clave
  viaja por un bus (LPC o SPI) que se puede **esnifar con un analizador lógico barato**,
  teniendo el equipo apagado y acceso físico. Se ha demostrado en portátiles empresariales de
  varios fabricantes en minutos. La mitigación documentada por Microsoft es el protector
  **TPM+PIN** (autenticación pre-arranque): la clave no sale hasta que el usuario introduce
  el PIN, y el anti-*hammering* del TPM frena la fuerza bruta.
- **Windows 11 24H2 activa el cifrado de dispositivo por defecto** en instalación limpia con
  cuenta Microsoft, y se relajaron los requisitos de hardware (se retiraron HSTI y Modern
  Standby). **Efecto colateral que hay que asumir: el parque de volúmenes BitLocker
  *TPM-only* se ha disparado**, porque el OOBE no pide PIN. "Cifrado activo" en un informe
  no dice nada si no dice **con qué protector**.
- Límite honesto: el ataque de arranque en frío explota la remanencia de la DRAM y **no lo
  para ningún protector**; y hay investigación dirigida también a configuraciones TPM+PIN.
  TPM+PIN sube el listón, no lo cierra. Para portátiles: hibernar, no suspender.
- **Custodia de la clave de recuperación es parte del control, no un extra**: escrow en el
  directorio o en el MDM, con acceso auditado y **restauración probada**. Una clave que solo
  vive en la cuenta personal del usuario no es custodia; es una pérdida de datos pendiente.
- **Secure Boot + Measured Boot + atestación**: el arranque medido registra hashes en los PCR
  del TPM y permite **atestar remotamente** el estado antes de conceder acceso a recursos. Es
  el único control que responde a "¿este equipo arrancó lo que yo creo?" — y el que hace que
  desactivar Secure Boot deje de ser gratis. Verifica qué atestación soporta de verdad tu MDM
  o tu servicio de acceso condicional antes de prometerla.
- Credenciales locales: contraseña de administrador local **única y rotada** por herramienta
  de gestión, protección de LSA y Credential Guard donde el hardware llegue, y ningún secreto
  en scripts de despliegue. Un endpoint comprometido con credencial reutilizada convierte una
  máquina en toda la flota.

## 5. El EDR como superficie de ataque y como riesgo de disponibilidad

- **El caso que hay que citar con datos, no con anécdota — CrowdStrike, 19-jul-2024**:
  - **04:09 UTC**: se publica una actualización de configuración del sensor (**Channel File
    291**). **05:27 UTC**: identificado y revertido — **79 minutos**. El daño ya estaba hecho.
  - Alcance: **Microsoft estimó 8,5 millones de dispositivos Windows afectados, menos del 1 %
    del parque**. Vuelos cancelados, servicios de emergencia caídos, hospitales parados.
  - Causa raíz (RCA pública de CrowdStrike, ago-2024): un **Template Type** nuevo para IPC
    definía **21 campos de entrada** mientras el código que invoca al *Content Interpreter*
    aportaba **20 valores**. El desajuste pasó varias capas de validación porque en pruebas el
    campo 21 se casaba con **comodín**. El 19 de julio se desplegó una instancia con criterio
    **no comodín** para ese campo 21 → **lectura fuera de límites** → BSOD.
  - Coste de recuperación: cada máquina requería **arranque manual en modo seguro o WinRE**
    para borrar el fichero. Sin acceso físico o remoto fuera de banda, no había arreglo.
  - **No era explotable**: el propio análisis y una revisión de terceros lo confirmaron; la
    lectura fuera de límites no permite escribir memoria arbitraria ni controlar la ejecución.
  - **Lecciones que sí son tuyas, no del proveedor**: (1) **el contenido de detección se
    despliega como código**, con anillos y ventana — exige a tu proveedor control de
    despliegue escalonado del **contenido**, no solo del sensor; (2) el EDR es una dependencia
    de **disponibilidad de nivel plataforma**, y debe estar en tu BIA; (3) ten un
    procedimiento **ensayado** de recuperación masiva sin red y con cifrado de disco activo —
    ahí es donde la custodia de la clave de recuperación deja de ser burocracia.
- **Movimiento estructural del sector**: tras el incidente Microsoft lanzó la **Windows
  Resiliency Initiative** y una **Windows Endpoint Security Platform** que permite a los
  socios del programa **MVI** ejecutar antivirus y EDR **fuera del kernel**, en modo usuario.
  Preview privada anunciada para socios (CrowdStrike, Bitdefender, ESET, Trend Micro,
  SentinelOne, Trellix, WithSecure y otros) a partir de mediados de 2025. **A agosto de 2026
  seguía siendo trabajo en curso, no producto general — verifica el estado antes de
  planificar sobre ello (§8)**, y no supongas que "fuera del kernel" significa cero acceso
  privilegiado: la propuesta concede parte del acceso, no lo elimina.
- **El agente amplía tu superficie**: corre con privilegio máximo, en todas las máquinas, con
  un canal de actualización que ejecuta contenido de un tercero. Trátalo como tal: sigue sus
  CVEs con la misma prioridad que el sistema operativo, restringe quién puede desinstalarlo o
  ponerlo en modo *bypass* desde la consola (**la consola del EDR es un objetivo Tier 0**),
  exige MFA y registro de auditoría en esa consola, y separa administración de investigación.
- **Evasión, descrita para detectarla y para evaluar producto — sin recetario**:
  - **BYOVD** (*bring your own vulnerable driver*): el atacante trae un driver **firmado y
    legítimo** pero vulnerable para conseguir ejecución en kernel y cegar al agente. Defensa:
    listas de bloqueo de drivers vulnerables aplicadas y **verificadas** (no solo activadas),
    integridad de código con hipervisor donde el hardware llegue, y alerta sobre carga de
    driver inusual. Pregunta de compra: *¿tu producto sobrevive a la carga de un driver
    vulnerable conocido, y me lo demuestras en el piloto?*
  - **Unhooking** en espacio de usuario: el malware restaura las funciones que el agente había
    interceptado, dejándolo ciego sin tocar el kernel. Es la razón por la que **la telemetría
    que solo viene de *hooks* en modo usuario no es de fiar**; exige al proveedor telemetría de
    fuentes que el proceso atacado no controle.
  - Regla de evaluación derivada: en un *bake-off*, la pregunta no es "¿detecta esta muestra?"
    sino **"¿qué pasa cuando el atacante ataca al agente?"** y **"¿qué queda registrado
    cuando el agente falla?"**.

## 6. Cobertura real: Linux, macOS, BYOD y la métrica que importa

- **Linux**: el sensor moderno es **eBPF** (verificado en el kernel, sin módulo, actualizable
  sin reinicio; Defender for Endpoint en Linux lo usa por defecto desde su versión de agente
  correspondiente). Límites que hay que comprobar **antes** de prometer cobertura: **suelo de
  versión de kernel** (Falco pide 5.8 mínimo, 5.15+ recomendado), **incompatibilidades por
  distribución y kernel concretos** (hay builds documentadas que cuelgan con eBPF activo), y
  el hecho de que **el verificador de eBPF es en sí superficie de ataque** — se le han
  encontrado fallos de seguimiento de rangos en kernels antiguos. En un parque heterogéneo,
  la heterogeneidad **es** el hueco de cobertura.
- **macOS**: el agente vive **en espacio de usuario** sobre la API de **Endpoint Security**
  (más NetworkExtension), y ahí hay techos duros: **la API de ES no entrega eventos de red**
  (hacen falta sensores aparte), **Apple limita la tasa de eventos** para proteger el
  rendimiento, el **log unificado requiere una *entitlement* privada** que los EDR no tienen,
  y la instalación **no puede ser silenciosa** (aprobación de extensión de sistema, filtro de
  red, permisos). Consecuencia: **un EDR multiplataforma no ve lo mismo en macOS que en
  Windows**, y quien te diga lo contrario no ha leído la API. Producto que todavía dependa de
  *kexts* y exija reducir la seguridad de arranque: **descartado**.
- **BYOD**: decide **antes** entre gestión del dispositivo (MDM completo) y gestión solo de la
  aplicación/datos. Si el dispositivo es personal, exigir agente completo es a la vez un
  problema legal y una promesa que no se cumple. Postura defendible: acceso condicional por
  **estado del dispositivo verificable**, contenedor de trabajo separado, y **sin acceso a
  datos sensibles desde equipo no gestionado**. Cualquier cosa intermedia es teatro.
- **Windows 10 terminó soporte el 14-oct-2025.** El programa **ESU de consumo se extendió
  hasta el 12-oct-2027** (anunciado de forma discreta en la documentación, contradiciendo el
  "octubre de 2026" que casi todo el mundo repite; en el EEE se hizo gratuito por presión
  regulatoria). **Verifica las condiciones y el calendario del ESU comercial por separado
  (§8)**: no son el mismo programa ni el mismo plazo.
- **DLP en el endpoint falla, y hay que decirlo antes de comprarlo**: depende de clasificar
  bien el dato (que casi nunca está hecho), no ve dentro de canales cifrados que no
  intercepta, se sortea con capturas de pantalla, fotos con el móvil, portapapeles, formatos
  transformados y canales nuevos cada trimestre, y genera un volumen de falsos positivos que
  acaba en modo "solo auditoría" permanente. Uso defendible: **detección de fuga accidental y
  disuasión con evidencia**, no prevención de un insider motivado. Si el caso de uso es el
  insider, la respuesta es control de acceso y minimización del dato, no un agente.
- **La métrica**: **cobertura real de la flota**, definida como *activos del inventario
  autoritativo con agente instalado, sano y reportando en las últimas 24 h*. Las licencias
  compradas y los equipos en consola no son cobertura: el hueco es exactamente la diferencia
  entre el inventario y la consola, y ahí es donde entra el atacante. Métricas de apoyo: % con
  cifrado **y protector correcto**, % con control de aplicaciones en *enforce*, mediana de
  días hasta parche desplegado, y **% de agentes en modo degradado o *bypass***.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisión trimestral de cobertura y de excepciones; revisión anual del producto
  contra lo que se le exigió en la compra (no contra el cuadrante de turno); ejercicio anual de
  **recuperación masiva** y de **aislamiento de host** — la capacidad de contención se ensaya
  o no existe.
- Toda exclusión de análisis (ruta, proceso, extensión) lleva **dueño, motivo y fecha de
  revisión**. Las exclusiones son deuda de seguridad y crecen solas.
- Fin de soporte del sistema operativo **planificado con presupuesto**, no descubierto el mes
  anterior. Un equipo fuera de soporte sin ESU es una aceptación de riesgo firmada, no un
  "pendiente".

**PROHIBIDO**
- ❌ Presentar **licencias compradas o equipos en consola** como cobertura de la flota.
- ❌ Tratar **AppLocker como frontera de seguridad**: no cumple los criterios de servicing de
  característica de seguridad del MSRC.
- ❌ Desplegar control de aplicaciones en *enforce* sin fase de auditoría medida.
- ❌ **BitLocker TPM-only en equipos que salen del recinto**, o cifrado sin custodia probada
  de la clave de recuperación.
- ❌ Desactivar Secure Boot para que arranque un driver; usar productos que exijan reducir la
  seguridad de arranque en macOS.
- ❌ Exclusiones amplias del EDR (`C:\`, `*.exe`, carpetas de usuario) o excluir por comodidad
  del equipo de desarrollo sin acuerdo escrito con ese equipo.
- ❌ Consola del EDR sin MFA, sin auditoría, o con permiso de desinstalar/*bypass* repartido.
- ❌ Aceptar actualización de **contenido** del proveedor sin control de despliegue escalonado,
  y no tener procedimiento ensayado de recuperación masiva.
- ❌ Vender el DLP de endpoint como prevención frente a un insider motivado.
- ❌ Exigir agente completo en dispositivo personal como sustituto de una política BYOD real.
- ❌ **Publicar procedimientos de evasión, cargadores, drivers vulnerables concretos o
  bypasses listos de un producto.** Esta skill es metodología, criterio de compra y
  detección; el trabajo ofensivo va con alcance y autorización por escrito
  (`offensive-security-standards`).

## 8. Verificación web obligatoria

Antes de fijar producto, nombre de característica, versión o fecha en un entregable:

1. **Nombre y comportamiento vigentes** en Microsoft Learn de App Control for Business/WDAC y
   AppLocker (la FAQ suele ir por delante de las páginas de visión general), y la frase de
   **servicing criteria del MSRC** citada **verbatim**.
2. **Guía de contramedidas de BitLocker** (TPM-only vs TPM+PIN, DMA, arranque en frío) y el
   comportamiento por defecto de la versión de Windows que despliegas.
3. **Windows Endpoint Security Platform / MVI**: estado real (preview privada, general o
   producto), socios y qué se ejecuta fuera del kernel.
4. **Ciclo de vida**: fin de soporte de tu versión de Windows/macOS/distribución, y
   condiciones y calendario de **ESU de consumo y de ESU comercial por separado**.
5. **Tu EDR**: versión mínima soportada, CVEs abiertos del agente, requisitos de kernel del
   sensor eBPF por distribución, y qué eventos entrega realmente en macOS.
6. **Listas de bloqueo de drivers vulnerables**: versión vigente, cómo se distribuye y cómo se
   verifica que está aplicada (no solo activada).
7. **Resultados de evaluación independiente** (MITRE ATT&CK Evaluations, AV-Comparatives,
   AV-TEST) de la ronda **más reciente**, y leídos como datos, no como ranking — la
   interpretación del proveedor no es el resultado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
