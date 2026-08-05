---
name: macos-fleet-standards
description: Managing a fleet of corporate Macs — enrollment, MDM, compliance and lifecycle, not using one Mac. Use when working with Apple Business Manager or Apple School Manager, Automated Device Enrollment (ADE/DEP), supervision, MDM enrollment profiles and .mobileconfig payloads, declarative device management (DDM) declarations, activations, assets and status subscriptions, software update enforcement declarations, Jamf Pro or Jamf Connect, Kandji, Mosyle, Addigy, Workspace ONE, Intune for macOS, NanoMDM, MicroMDM, KMFDDM or NanoHUB, APNs push certificates and MDM server tokens, kernel extensions versus system extensions (DriverKit, NetworkExtension, EndpointSecurity, kmutil, systemextensionsctl), FileVault with personal or institutional recovery keys, escrow and bootstrap token, secure token, volume ownership, Secure Enclave, SIP (csrutil), Gatekeeper, notarization, spctl, XProtect and XProtect Remediator, TCC and PPPC configuration profiles, Platform SSO with Entra ID or Okta, Munki, Installomator, AutoPkg, Homebrew on a corporate Mac, productbuild/pkgutil and signed or notarized .pkg installers, profiles(1), sudo mdmclient, softwareupdate, or the CIS macOS Benchmark and the macOS Security Compliance Project (mSCP).
---

# Estándares de flota macOS corporativa

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Esto va de gestionar una flota de Mac corporativos, no de usar un Mac.** La diferencia lo es
todo: un Mac bien configurado por su dueño es un problema resuelto una vez; una flota es un
problema de **propiedad del dispositivo, inscripción, estado declarado, evidencia y ciclo de vida**,
donde nada que dependa de que alguien haga algo bien en su máquina cuenta como control.

Las tres afirmaciones que ordenan el resto:

1. **Una flota sin inscripción automatizada (ADE) no es una flota que controlas**: sin supervisión,
   con el perfil de gestión **eliminable por la persona usuaria** y sin garantía de reinscripción
   tras un borrado, es un dispositivo de confianza voluntaria.
2. **El modelo actual es declarativo (DDM), no de comandos**: las vías antiguas **ya han dejado de
   funcionar** en el ciclo 27 (§2).
3. **Lo que rompe la automatización en macOS es el consentimiento (TCC)**, no la falta de
   herramientas: lo que no se preconfigure por MDM acaba en un diálogo que alguien tiene que
   pulsar — y en una flota eso significa que no ocurre.

**No aplica**:
- `developer-workstation-standards` (**ya escrita — frontera crítica**): **suya la máquina de una
  persona que programa** (entorno, endurecimiento personal, aprovisionamiento como código,
  credenciales locales); **aquí la flota corporativa** (inscripción, MDM, línea base, cumplimiento,
  ciclo de vida del activo). **Dos problemas distintos sobre el mismo hardware, y hay que resolver
  los dos**: si el puesto de desarrollo se aprovisiona por fuera de la flota tienes una máquina no
  gestionada; si la flota no deja sitio a lo que esa skill decide, tienes a alguien trabajando en su
  portátil personal. **Ninguna manda sobre la otra.**
- `mobile-standards` (**ya escrita**): **suyas iOS e iPadOS como plataforma de aplicación**;
  **aquí la gestión del dispositivo** (ABM, ADE, MDM, DDM), común a todas las plataformas de Apple.
- `identity-access-management-standards` (**ya escrita**): **suyo el proveedor de identidad**
  (federación, MFA, ciclo de vida de cuentas); **aquí solo cómo lo consume el arranque de sesión del
  equipo** (Platform SSO, §5).
- `grc-compliance-standards` (**suyos marco de control y evidencia**; aquí la línea base técnica que
  la produce), `detection-engineering-standards` (**suyas la detección en el endpoint y sus
  reglas**), `endpoint-security-standards` (**suyo el producto de protección del puesto**: el EDR
  de terceros, su exigencia y su medida, y **la postura del protector de cifrado en flota** —qué
  se exige y cómo se mide; aquí el perfil MDM que lo aplica y custodia la clave de FileVault—),
  `secrets-management-standards`, `vulnerability-management-standards`.
- `onprem-standards` (**paraguas de plataforma con la tabla de enrutado**), `homelab-standards`,
  `linux-administration-standards`, `rhel-fedora-standards`, `linux-hardening-standards`,
  `linux-storage-standards` y `zfs-standards` (**ya escritas: Linux y ZFS son suyos**),
  `firewall-policy-standards`, `networking-standards`, `iac-standards`,
  `os-provisioning-standards`, `server-hardware-standards`, `backup-recovery-standards`,
  `bcdr-standards`, `ha-clustering-standards`, `legacy-modernization-standards`,
  `migration-projects-standards`.
- `aix-solaris-hpux-standards` y `bsd-systems-standards`: **macOS no es una flota de servidores** y
  **BSD no es Unix propietario**. El apellido "Unix" junta a las tres y no comparten casi nada
  operativo: aquí el objeto gestionado es un **puesto de trabajo con dueño humano**.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada |
|---|---|---|
| Propiedad del dispositivo | **Todo Mac corporativo, comprado a través de Apple Business Manager (o School Manager) y asignado al servidor MDM antes de entregarlo** | Es lo que hace la inscripción **automatizada y no eliminable** |
| Inscripción | **ADE obligatoria**; inscripción de usuario solo para BYOD, con expectativas reducidas | Sin ADE no hay supervisión ni garantía de reinscripción |
| Modelo de gestión | **DDM por defecto**; el comando MDM clásico solo donde no haya declaración equivalente | Apple, WWDC26, literal: *"Legacy software update management no longer functions in all 27.0 operating systems. This includes: Software update commands, Software update queries, Recommended cadence settings, Software update restrictions, like deferrals and Background Security Improvements"* |
| Versión objetivo | Línea **macOS 26 (Tahoe)** en producción; **macOS 27** en el ciclo anunciado por Apple para 2026 (§8) | macOS 26 es **la última versión compatible con Mac Intel**: eso convierte el parque Intel en un plan de retirada con fecha, no en una preferencia |
| Actualizaciones | **Declaración DDM con versión objetivo y fecha límite** | Lo que sustituye a diferimientos y comandos. El aplazamiento indefinido ya no es una opción técnica |
| MDM comercial | **Jamf Pro, Kandji o Mosyle** según tamaño y automatización necesaria; Intune si la organización ya vive en Microsoft y acepta su cobertura menor en macOS | **Precios: no verificados en tarifa oficial — hueco declarado (§8).** Todos cobran por dispositivo/mes con mínimos de compra y escalones; pídelo por escrito |
| MDM de código abierto | **NanoMDM** — licencia **MIT** (verificada leyendo el `LICENSE` en crudo de `micromdm/nanomdm`). Solo con capacidad de ingeniería propia | **MicroMDM v1 pasó a mantenimiento en jun-2025**; NanoMDM es el sucesor activo. **No es un producto**: sin interfaz, sin catálogo, sin soporte. APNs, TLS, disponibilidad y guardia son tuyos, y por debajo de cierta capacidad **cuesta más que la suscripción** |
| Extensiones, cifrado, identidad y línea base | Solo extensiones de sistema (§3.3); FileVault forzado con clave y token de arranque custodiados (§5); **Platform SSO** contra el proveedor corporativo (§5); **mSCP** como generador de la línea base (§4) | Un requisito de *kernel extension* es motivo de descarte del proveedor |

## 3. Estructura y convenciones

### 3.1 Inscripción y propiedad
- **El Mac entra en ABM antes que en la mesa de nadie**: compra por canal que alimente ABM,
  asignación al MDM y perfil de inscripción listos antes del desembalaje. Comprar en tienda para
  "resolver rápido" crea deuda permanente — **añadir a ADE después solo es posible por vías
  limitadas y con plazos**.
- **Supervisado frente a no supervisado no es un matiz**: la supervisión (que llega con ADE) es lo
  que habilita gestión no eliminable, restricciones adicionales y control del bloqueo de
  activación. Un Mac no supervisado se gestiona **con su permiso**.
- **BYOD es otro producto** (inscripción de usuario, solo lo corporativo, **ninguna expectativa de
  cumplimiento de la máquina**). Y en la baja: liberar el bloqueo de activación y **retirar el
  dispositivo de ABM** — un Mac vendido sin liberar es un ladrillo para el comprador.

### 3.2 MDM: el protocolo y sus límites
El MDM de Apple es **una cola de comandos entregada por notificación push**: el servidor pide, el
dispositivo responde cuando puede. **No es ejecución remota**: sin orden garantizado, sin tiempo
garantizado, sin shell. DDM cambia el modelo —estado deseado declarado, aplicado y reportado por el
dispositivo— pero no eso. Consecuencia: lo que no se exprese como perfil o declaración necesita un
**agente**, y cuanto más dependa tu operación del agente, peor envejece con cada versión de macOS.
**Lo que Apple sabe hacer de forma declarativa se hace declarativo.**

**Elección de MDM**, por orden: (1) cobertura real de DDM y **velocidad de soporte de la versión
nueva de macOS cada septiembre** —el criterio que más duele si falla—; (2) qué automatiza sin
programar; (3) API y gestión como código; (4) precio con mínimos y escalones; (5) salida: cómo te
llevas el inventario y cómo migras la inscripción.

### 3.3 El fin de las extensiones de kernel
- Sustituidas por **extensiones de sistema** en espacio de usuario: DriverKit (dispositivos),
  NetworkExtension (red y VPN), EndpointSecurity (seguridad). En Apple Silicon cargar un kext exige
  **bajar la política de arranque a "Seguridad reducida"** y aprobar en el equipo: degradar el
  arranque seguro de toda la máquina y tocarla físicamente.
- **Regla de compra**: si un producto exige kext, **está descartado**, y se dice en el pliego, no
  al descubrirlo en el despliegue. Lo que suele romperse: antivirus antiguos, VPN heredadas,
  virtualización, copia a bajo nivel y periféricos especializados.
- Las extensiones de sistema se **preaprueban por MDM**; si no, la instalación acaba en un diálogo
  que nadie debería tener que interpretar.

### 3.4 Actualizaciones
- **El mecanismo actual es la declaración DDM con versión objetivo y fecha límite**; comandos,
  consultas, restricciones y diferimientos **ya no funcionan en el ciclo 27** (§2, cita literal de
  Apple). Si tu política de parcheo se apoyaba en diferimientos, **ya está rota** aunque nadie haya
  avisado: los comandos se envían y el dispositivo los ignora.
- **Retrasar actualizaciones en macOS es más caro que en Windows**: (a) **una versión mayor al año**
  concentra funciones y cambios de gestión; (b) la corrección de seguridad va **acoplada a la
  versión del sistema**, navegador incluido, sin parche desacoplado; (c) **el hardware nuevo llega
  con la versión nueva y no se puede degradar**, así que quedarse atrás fragmenta el parque por
  fecha de compra; (d) el soporte de versiones anteriores es corto y desigual. **La única política
  sostenible es adoptar la versión mayor dentro del año**, por anillos: TI → voluntarios → piloto
  representativo (con puestos de desarrollo y periféricos raros) → resto, con fecha límite en cada
  uno.

### 3.5 Aplicaciones y paquetes
- **Todo software corporativo sale de un catálogo**: compras de ABM y **paquetes propios firmados y
  notarizados** (Munki para un catálogo real independiente del MDM; **Installomator** para instalar
  y actualizar descargando del proveedor). Un `.pkg` sin firmar instalado saltando Gatekeeper enseña
  a la plantilla el comportamiento exacto que un atacante necesita.
- **Homebrew instala en el espacio del usuario y fuera de la cadena de gestión**: el MDM no lo ve,
  no pasa por tu catálogo, se actualiza por decisión de cada persona y su procedencia es comunitaria.
  **No es un gestor de software corporativo.** Es legítimo y a menudo necesario en un **puesto de
  desarrollo** —decisión de `developer-workstation-standards`— y entonces se declara: qué máquinas,
  qué inventario, qué riesgo aceptado. Lo vetado es que la herramienta corporativa llegue por ahí.

## 4. Cumplimiento y evidencia

- **La línea base se genera, no se escribe a mano.** El **macOS Security Compliance Project**
  (implementación técnica de **NIST SP 800-219**) produce, a partir de la línea base elegida (CIS
  Nivel 1/2, 800-53, 800-171, STIG, CMMC), **perfiles, scripts de comprobación y remediación y
  documentación de auditoría**: control, ajuste y evidencia salen del mismo sitio. **CIS Benchmark
  para macOS** está cubierto ahí — no mantengas dos fuentes de verdad. **Trabaja sobre la rama de
  tu versión de macOS**, nunca sobre la principal (a ago-2026, *tahoe_rev2*, dic-2025, con mSCP 2.0
  en curso — §8).
- **La evidencia es la comprobación periódica en el dispositivo, no el perfil enviado.** Informe
  con **cobertura** (cuántos equipos han reportado en los últimos N días) además de porcentaje:
  **los que no reportan son el riesgo y desaparecen de la media**. El marco de control y las
  excepciones son de `grc-compliance-standards`.

## 5. Seguridad de plataforma e identidad

- **FileVault forzado y clave custodiada.** Sin custodia (escrow) **verificada**, el cifrado es una
  forma elegante de perder datos: comprueba que la clave está en el MDM, define quién puede
  recuperarla con doble control y registro, y **rótala tras cada uso**. Igual con el **token de
  arranque y la propiedad del volumen**, que es lo que permite que las actualizaciones y ciertos
  cambios de gestión funcionen sin que alguien escriba su contraseña: si faltan, se manifiesta
  mucho después como "actualizaciones que no se aplican".
- **SIP, Gatekeeper y arranque seguro completo, activos**; desactivarlos cambia la postura de toda
  la máquina. **XProtect y su remediador** al día y verificados en el inventario — no sustituyen a
  la detección corporativa (`detection-engineering-standards`, `endpoint-security-standards`).
- **TCC es el modelo de consentimiento y es lo que rompe la automatización.** Disco completo,
  grabación de pantalla, accesibilidad, cámara, micrófono, carpetas del usuario: lo que necesiten
  tu agente, tu herramienta de copia o tu producto de seguridad **se preconcede por perfil PPPC
  antes de desplegar**. Lo que Apple reserva a la persona usuaria se documenta como paso manual del
  onboarding, no se descubre en producción.
- **Borrado y bloqueo remotos probados** y coordinados con el **bloqueo de activación**: bloquear
  un equipo cuya liberación no controlas convierte un incidente en pérdida de activo.
- **La trampa de la contraseña local frente a la identidad corporativa.** La cuenta del Mac tiene
  **su propia contraseña**: no aplica la política corporativa y **no se revoca al desactivar la
  cuenta en el proveedor de identidad** — un portátil en un cajón sigue abriéndose con la
  contraseña de alguien que ya no trabaja aquí. La respuesta es **Platform SSO**, con sincronización
  de contraseña o clave respaldada por el Secure Enclave; con **macOS 26** el registro ocurre
  **durante el asistente de configuración** (*Simplified Setup*) y **la primera cuenta local se crea
  desde la identidad corporativa**. **No apiles dos mecanismos de sincronización**: entran en
  conflicto.
- **Nadie es administrador local permanente**: cuenta estándar y elevación puntual, auditada y
  temporal. La cuenta administrativa de gestión, **con contraseña única por equipo y rotada** — una
  común a toda la flota es la vulnerabilidad más cara y frecuente de este dominio.

## 6. Operación

- **Inventario con frescura** (última comunicación, versión, FileVault, cobertura de perfiles,
  XProtect): **un equipo con 45 días sin reportar es un incidente abierto**, no una fila más.
- **Septiembre es la fecha crítica del año** (versión mayor, cambios de gestión, retiradas): se
  reserva capacidad, validando en beta desde el verano MDM, seguridad, VPN y paquetes propios.
- **La configuración de la flota es código** (perfiles, líneas base, declaraciones, catálogo), con
  revisión y despliegue por anillos — el cómo, en `iac-standards`. Y **prueba de reconstrucción**
  cronometrada de un equipo desde cero: sin ella, reponer un portátil perdido es una hipótesis.

## 7. Prohibiciones

- ❌ **PROHIBIDO** un Mac corporativo **sin inscripción automatizada (ADE)** ni supervisión. Es la
  prohibición raíz: todo lo demás de este documento se apoya en ella.
- ❌ **FileVault sin custodia verificada de la clave**, custodia sin control de quién la recupera ni
  rotación tras el uso, o **bootstrap token sin custodiar**.
- ❌ **Depender de una cuenta de administrador local** —de la persona usuaria o compartida por la
  flota— como mecanismo de gestión.
- ❌ **Instalar software fuera del catálogo** o distribuir paquetes internos sin firmar y notarizar.
  **Homebrew no es el catálogo corporativo** (§3.5).
- ❌ Aceptar un producto que exija **extensión de kernel**, o dejar equipos en "Seguridad reducida"
  de forma permanente. Desactivar SIP o Gatekeeper sin excepción escrita, nominal y caducable.
- ❌ Apoyar la política de actualización en **diferimientos y comandos MDM** (ya no funcionan, §2) o
  aplazar la versión mayor más de un ciclo anual.
- ❌ Desplegar sin **preconceder por PPPC** los permisos TCC que tus herramientas necesitan.
- ❌ Tratar el BYOD inscrito por usuario como equipo gestionado; dar de baja un equipo sin liberar
  el bloqueo de activación ni sacarlo de ABM.
- ❌ Adoptar un MDM sin comprobar su cobertura de **DDM** y su histórico de soporte el día del
  lanzamiento de macOS; o montar NanoMDM "porque es gratis" sin equipo que sostenga APNs, TLS,
  disponibilidad y guardia.
- ❌ Contar como cumplimiento el porcentaje sobre los equipos que reportan, ignorando los que no
  (§4).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web —y con **cita literal**, nunca con un
resumen automático:

1. **Versiones de macOS y su soporte**: a ago-2026 macOS 26 (Tahoe) es la línea desplegada y
   **Apple documenta cambios para el ciclo 27** (iOS 27, iPadOS 27, macOS 27, tvOS 27, visionOS 27,
   watchOS 27, citados literalmente en la nota de gestión de dispositivos de WWDC26). **Hueco
   declarado: el nombre comercial y la fecha exacta de macOS 27 no fueron verificados.** Confirma
   hasta qué versión reciben parches los modelos de tu parque.
2. **Actualizaciones y DDM**: la retirada del mecanismo antiguo está verificada literalmente (§2).
   Comprueba qué declaraciones existen hoy y **qué soporta tu MDM concreto** —casi nunca es lo
   mismo—; el alcance de DDM crece cada ciclo y determina cuánto agente necesitas. Verifica también
   el calendario de retirada de **extensiones de kernel** antes de aceptar un producto que las use.
3. **mSCP**: rama de tu versión de macOS y estado del rediseño **mSCP 2.0**, en curso durante 2026.
   **No trabajes desde la rama principal.** Y versión vigente del **CIS Benchmark** para macOS.
4. **Soluciones MDM — estado, licencia y precio**. Verificado a ago-2026 leyendo el `LICENSE` en
   crudo: **NanoMDM = MIT**; **MicroMDM v1 en mantenimiento desde jun-2025**. **Hueco declarado:
   ningún precio de Jamf, Kandji, Mosyle, Addigy o Intune fue verificado en tarifa oficial** — las
   cifras que circulan proceden de agregadores. **No cites precios desde aquí: pide oferta**, con
   mínimos, escalones e incrementos de renovación. El feed de GitHub no prueba que un proyecto viva.
5. **Platform SSO**: requisitos exactos de tu proveedor (versión mínima de macOS, aplicación,
   certificados, modo de autenticación) y estado del registro durante el asistente.
6. **Apple Business Manager**: cambios de términos, identidades federadas y procedimiento vigente
   para añadir dispositivos comprados fuera de canal.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
