---
name: ibm-i-rpg-standards
description: IBM i (AS/400, iSeries, System i) application engineering on Power. Use when working with RPG sources (.rpgle, .sqlrpgle, RPG III/RPGLE, **FREE fully free-form, /COPY and /INCLUDE prototypes), CL programs (.clle, CRTBNDCL, CL commands like WRKACTJOB, WRKSPLF, DSPFFD), DDS physical and logical files and display files (.pf, .lf, .dspf, .prtf), ILE modules, service programs, binding directories and activation groups (CRTRPGMOD, CRTSRVPGM, CRTPGM, ACTGRP), IFS and QSYS.LIB objects, library lists and *LIBL, Db2 for i with embedded SQL, SQL stored procedures, Run SQL Scripts, ACS, and IBM i Services SQL views (QSYS2, SYSTOOLS), record-level access opcodes (CHAIN, SETLL, READE, WRITE, UPDATE), journaling and commitment control, IBM i Access Client Solutions, Rational Developer for i (RDi), VS Code with Code for IBM i, Merlin, Integrated Web Services (IWS), 5250 green-screen modernization, user profiles and adopted authority (USRPRF *OWNER, *ALLOBJ), QSECURITY system value, Technology Refresh levels, or IBM i release upgrades and per-core subscription licensing tiers.
---

# Estándares de IBM i y RPG

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**IBM i (AS/400) es la plataforma legacy que mejor envejece y peor se entiende desde fuera.** No
está congelada: tiene releases nuevos, *Technology Refresh* periódicos, hardware nuevo (Power11) y
hoja de ruta pública (§2). La compatibilidad hacia atrás es real: un programa RPG de los años 90
compila y corre hoy. Eso es una virtud de ingeniería, no un síntoma de abandono.

Lo que sí es cierto —y hay que decirlo aquí— es lo siguiente:
- **Es una plataforma de proveedor único.** Sistema operativo, base de datos, hardware y buena
  parte del tooling salen de IBM. No hay salida parcial: se está o no se está.
- **El modelo de licencia se ha movido a suscripción** (§2), lo que convierte un coste antes
  amortizado en un coste recurrente. Ese es el cambio económico relevante de los últimos años, no
  la sintaxis del lenguaje.
- **Escribir aplicaciones nuevas en RPG solo tiene sentido dentro de una base RPG existente que se
  va a conservar**, y en ese caso se escribe en **formato totalmente libre** (§3), sin excepción.
- **La deuda real de casi todas estas casas no es el lenguaje: es el estilo** — programas
  monolíticos con acceso nativo por registro, sin ILE, sin control de versiones y con la lógica
  atada a la pantalla 5250.

Cubre: releases y soporte; economía de licencia; RPG y la regla de formato libre; **ILE** (módulos,
programas de servicio, grupos de activación); **Db2 for i** y SQL frente a acceso nativo;
herramientas modernas y control de versiones real; integración (IWS, servicios web, **IBM i
Services**); modernización de pantallas; y seguridad de perfiles y autoridades.

**No aplica**:
- `legacy-modernization-standards` (**skill paraguas de este bloque**): suya
  la estrategia de modernización, el análisis de cartera y la decisión de invertir, migrar o
  retirar; **aquí el criterio técnico de esta plataforma**.
- `migration-projects-standards`: suya la **ejecución del corte** — ensayo, ventana, convivencia y
  reconciliación entre IBM i y el destino, criterio de rollback y descomisionado.
- `enterprise-architecture-standards` (**ya escrita**): suyos el inventario de aplicaciones, el
  modelo **TIME** y las **"R"**; aquí qué implica técnicamente cada opción *en IBM i*.
- `tech-leadership-standards` y `project-management-standards` (cómo se financia y se decide).
- `refactoring-tech-debt-standards` (**suyos** *strangler fig*, rama por abstracción y
  caracterización de código sin tests; aquí solo lo específico de la plataforma).
- `testing-qa-standards` (estrategia de prueba), `cicd-standards` (la pipeline),
  `git-workflow-standards` (ramas, commits, releases).
- `sql-standards` y `data-platform-standards` (el lenguaje SQL y el diseño de datos genérico;
  **aquí Db2 for i solo en lo que decide sobre el programa**), `oracle-dba-standards` y
  `sqlserver-dba-standards` (otros motores).
- `dotnet-standards`, `jvm-spring-standards`, `python-standards`, `go-standards` (destinos de una
  reescritura: **la calidad del código destino es suya**).
- `grc-compliance-standards`, `privacy-engineering-standards`,
  `identity-access-management-standards`, `bcdr-standards`, `backup-recovery-standards`,
  `observability-standards`, `vulnerability-management-standards`.
- `offensive-security-standards`: **esta skill es defensiva**.
- `mainframe-zos-cobol-standards` y `mumps-standards`: **son tres plataformas distintas que la
  gente mete en el mismo saco de "legacy" y que no comparten casi nada** — IBM i no es un
  mainframe, no cobra por MSU, no usa JCL y su base de datos es parte del sistema operativo. No
  extrapoles criterio entre ellas.
- `aix-solaris-hpux-standards` (**Ola 7 — la confusión más frecuente de todas, porque comparten
  hardware**): **AIX e IBM i corren sobre Power y pueden convivir como particiones del mismo
  servidor, pero son sistemas operativos distintos y no comparten nada del criterio de aplicación.**
  AIX es Unix —`smit`, LVM, JFS2, `mksysb`, shell y binarios— y es de esa skill; IBM i tiene objetos,
  bibliotecas, ILE y Db2 integrado en el sistema operativo, y es de aquí. **Lo que sí comparten y
  vive allí**: PowerVM, LPAR, VIOS y la HMC, el ciclo de vida del hardware Power y el contrato de
  soporte. Regla corta: **si la respuesta cambia al cambiar de partición, es de la skill del sistema
  operativo; si es del hipervisor o del hierro, es de la de Unix propietario.**

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada |
|---|---|---|
| Release objetivo | **IBM i 7.6** para hardware nuevo; **7.5** si hay Power9 en el parque | 7.6: anunciada 8-abr-2025, **GA 18-abr-2025**; requiere **Power10 o superior**. 7.5 disponible desde may-2022 |
| Release a abandonar | **7.4** | Retirada de comercialización 30-abr-2026; **cambio de nivel de servicio 30-sep-2026**; extensión de pago hasta 30-sep-2029 (política *Enhanced*: 5 años + 3 de extensión). GA de 7.4: 21-jun-2019 |
| Techo por hardware | El release lo limita la generación Power, no el software | Power8 → 7.4 es el último; Power9 → 7.5 es el último; Power10/11 → 7.5 y 7.6 |
| Cadencia | Aplicar **Technology Refresh** con calendario propio | Un TR trae funciones nuevas, no solo correcciones; quedarse en un TR viejo cierra puertas (IBM i Services, open source) |
| Licencia | **Por *tier* de procesador (P05/P10/P20/P30) y, en tiers bajos, por usuarios** | P05/P10: procesador + usuarios (con opción ilimitada); **P20 y superiores: solo por core**. Verificado en el documento de *software tiers* de IBM |
| Modelo comercial | **Suscripción**: la perpetua está en retirada | Perpetuas P05/P10 retiradas 7-may-2024; **P20/P30 retiradas con efecto 1-ene-2026**; en Power11 las licencias IBM i son **solo por suscripción** |
| Lenguaje | **RPG en formato totalmente libre (`**FREE`)** para todo lo nuevo | Ver §3 |
| Acceso a datos | **SQL embebido (`.sqlrpgle`) por defecto** | Ver §3.2 |
| Arquitectura de programa | **ILE**: módulos + programas de servicio + directorio de vinculación | Ver §3.1 |
| IDE | **VS Code + Code for IBM i** como opción por defecto; **RDi** si ya está licenciado | Code for IBM i: repo `codefori/vscode-ibmi`, **licencia MIT** (verificada en el `package.json` del repo), publicado en el Marketplace por HalcyonTech. **No es un producto IBM ni tiene soporte IBM** |
| RDi | Vigilar su calendario | RDi **9.8 discontinúa soporte el 30-abr-2026**; **9.9** publicada el 5-dic-2025. RDi es producto IBM desarrollado y soportado por Fortra |
| Administración | **IBM i Services** (vistas y procedimientos SQL en `QSYS2`/`SYSTOOLS`) | Ver §3.3 |
| SCM | **Git**, con el fuente en el **IFS** (no en miembros de fuente) | Ver §4 |

**Discrepancia declarada**: la terminología de IBM cambió — lo que antes se llamaba *end of
standard support* ahora se anuncia como *date change for service level*. Fuentes de terceros lo
publican como "fin de soporte de 7.4 el 30-sep-2026", pero **no es fin de vida**: hay extensión de
pago hasta 2029. No cites "EOL 2026" sin ese matiz.

**Sobre la comparación de coste perpetua vs. suscripción**: circulan porcentajes (del orden de
+20 %/+40 % a siete años) procedentes de análisis de prensa especializada, no de tarifas
publicadas. **IBM no publica precios en las cartas de anuncio**: cualquier cifra que uses tiene que
venir de tu propia oferta de partner. Ver §8.

## 3. Estructura y convenciones

### 3.1 ILE es la línea que separa mantenible de no mantenible

- **Nada de programas monolíticos nuevos.** Lógica en **módulos** (`CRTRPGMOD`), agrupados en
  **programas de servicio** (`CRTSRVPGM`) y enlazados por **directorio de vinculación**. El
  programa de entrada solo orquesta.
- **Prototipos y `/COPY` de interfaz**: la firma de cada procedimiento exportado vive en un fuente
  de copia compartido; nadie llama a un procedimiento con una firma escrita a mano.
- **Grupos de activación**: elección deliberada y documentada. `*NEW` por llamada es un coste de
  arranque; `*CALLER` propaga; un grupo con nombre por aplicación es lo habitual. **`*DFTACTGRP` es
  compatibilidad con OPM: no en código nuevo.** El grupo de activación determina el ámbito del
  control de compromiso y de los ficheros abiertos: equivocarse aquí produce bugs de transacción,
  no de rendimiento.
- **Firma del programa de servicio**: gestiona el fichero de exportación con control de versiones.
  Añadir exportaciones al final es compatible; reordenarlas obliga a recompilar a todos los
  clientes. Es un contrato binario.

### 3.2 SQL frente a acceso nativo por registro

- **SQL embebido es el default moderno**, y no por moda: el optimizador (SQE) trabaja sobre
  conjuntos, aprovecha índices que no tienes que abrir a mano, y **el código dice qué quiere, no
  cómo recorrerlo**. Un `CHAIN`/`READE` dentro de un bucle es un *join* escrito a mano y sin
  estadísticas.
- Lo que hay que reponer al dejar los *opcodes* nativos: control explícito del bloqueo de registro
  y el "leer una fila por clave" (cursor o `SELECT INTO`). Ninguna de las dos cosas justifica
  escribir la aplicación entera en acceso nativo.
- **Regla dura**: código nuevo con SQL; el antiguo se convierte **solo** cuando toque por otra
  razón y con test que compare resultados. **No hay campaña de conversión masiva que salga bien.**
- **DDS en modo mantenimiento para datos**: tablas, vistas e índices nuevos **con SQL DDL**, no
  PF/LF. DDS sigue siendo lo que hay para pantallas (DSPF) e impresos (PRTF).
- **Journaling y control de compromiso activados** en todo fichero de negocio: es el prerequisito
  de la recuperación y de la replicación, y se descubre tarde.
- La **`*LIBL`** es resolución dinámica y fuente inagotable de incidentes: **la lista de
  bibliotecas de un job de producción es configuración versionada**, no un ajuste de sesión.

### 3.3 Administrar con SQL, no con pantallas

**IBM i Services** (vistas y procedimientos SQL en `QSYS2`/`SYSTOOLS`) son **la vía moderna de
administrar**: objetos, PTFs, jobs, autoridades, usuarios y red se consultan con `SELECT`, lo que
es automatizable, comparable entre entornos y auditable — un `WRKxxx` no deja evidencia. Todo
control periódico (autoridades públicas excesivas, perfiles inactivos, PTFs pendientes) se escribe
como consulta guardada en el repositorio, no como procedimiento manual.

## 4. Calidad, control de versiones y CI

- **El fuente vive en Git, en el IFS** (`.rpgle`/`.sqlrpgle`/`.clle`/`.sql`), **no en miembros de
  `QSYS.LIB`**: un miembro con fecha de modificación no es historia y no permite ramas, diff ni
  revisión. **Es el cambio con más retorno de toda la modernización, y es previo a los demás.**
- **Build reproducible**: script versionado (utilidades del ecosistema Code for IBM i, o CL propio)
  que reconstruye desde cero en una biblioteca limpia. Si nadie sabe recompilar todo, no hay
  entrega: hay parcheo.
- **Entornos separados por biblioteca y `*LIBL`**, con datos de test propios y **enmascarados**.
- **Pruebas**: unidad sobre procedimientos ILE (lo hace posible el diseño de §3.1) y regresión por
  comparación de salidas en batch. Un programa monolítico que solo se prueba por 5250 es, en la
  práctica, no testeable: eso es lo primero que hay que romper.
- **Gate de CI mínimo**: compila limpio sin ignorar avisos, la suite pasa, y **ningún objeto se
  crea a mano en producción**.

## 5. Seguridad del stack

- **`QSECURITY` 40 como mínimo**; 50 en entornos regulados. Por debajo de 40 la integridad del
  sistema no está garantizada; subirlo es un proyecto, pero **quedarse en 30 no es defendible**.
- **`*ALLOBJ` es el problema.** Todo perfil con `*ALLOBJ`/`*SECOFR` es administrador total del
  sistema y de los datos. Inventaría quién lo tiene —incluido por perfil de grupo—, justifícalo uno
  a uno y elimina el resto: aquí aparecen perfiles de aplicación y usuarios de servicio con
  autoridad total.
- **Autoridad pública**: `*EXCLUDE` en objetos de datos y concesión por lista de autorización.
  `*PUBLIC *CHANGE` en bibliotecas de negocio es el hallazgo de auditoría garantizado.
- **Autoridad adoptada (`USRPRF(*OWNER)`)** da acceso solo mientras corre el programa, y es riesgo
  si el programa permite llegar a línea de comandos. Adopta desde el objeto más pequeño posible,
  controla la propagación (`USEADPAUT`), y **ningún programa que adopta autoridad ofrece entrada de
  comandos**.
- **La puerta trasera no es el 5250**: son las interfaces abiertas (FTP, ODBC/JDBC, DRDA, DDM,
  REST). Un usuario limitado por menú puede leer todas las tablas por ODBC si no hay programas de
  salida ni autoridad a nivel de objeto. **La seguridad va en el objeto, no en el menú.**
- **MFA nativa**: 7.6 incorpora TOTP en el sistema operativo, aplicable a todos los puntos de
  autenticación (5250, FTP) y a perfiles SST/DST, sin coste adicional — razón suficiente, por sí
  sola, para planificar el salto. 7.6 añade además cifrado del ASP del sistema (SYSBAS): verifica
  el impacto operativo antes de activarlo.
- **`QAUDJRN` activado y exportado al SIEM**: si el journal de auditoría no sale de la máquina, es
  una zona ciega.

## 6. Integración y modernización de la interfaz

- **Servicios web**: **IWS** expone un programa o procedimiento como REST/SOAP sin salir de la
  plataforma; para consumo, cliente HTTP nativo o funciones SQL. Con volumen o integración compleja,
  la alternativa es un servicio externo que hable Db2 for i por SQL.
- **La trampa habitual: envolver la pantalla 5250 en web sin rediseñar el flujo.** Sale la misma
  secuencia de pantallas con CSS, con su navegación paso a paso, su validación campo a campo y su
  sesión conversacional: **se gana aspecto, no usabilidad ni desacoplamiento**. Requisito previo a
  cualquier interfaz nueva: que la lógica esté en procedimientos ILE invocables sin pantalla
  (§3.1). Mientras viva en el programa de la DSPF, la capa web es maquillaje.
- **API antes que pantalla**: la unidad de reutilización es el procedimiento, no el programa
  interactivo.

## 7. Cuándo quedarse, cuándo migrar y prohibiciones

**Quedarse es correcto —y lo es más veces de lo que se cree— cuando:**
- La aplicación cubre el negocio, el coste total (licencia + soporte + personal) es conocido y
  competitivo, y hay hardware Power en soporte con camino a 7.5/7.6.
- La operación es lo que la plataforma hace excepcionalmente bien: batch fiable, base de datos
  integrada, muy poca administración por transacción, disponibilidad alta con equipo pequeño.
- Se puede modernizar *dentro*: ILE, SQL, Git, CI, APIs. **Esa ruta es dramáticamente más barata
  que reescribir y casi nadie la agota antes de plantear la migración.**

**Migrar tiene sentido cuando** el proveedor único es un riesgo aceptado por dirección, cuando el
coste de suscripción deja de ser competitivo frente al valor, cuando la funcionalidad se compra ya
hecha (ERP), o cuando no hay ni habrá personal — **medido en tu casa, no en un artículo**.

**Prohibiciones:**

- ❌ **PROHIBIDO** escribir código nuevo en RPG de formato fijo (columnas), en RPG III/OPM o con
  indicadores numéricos como lógica. Todo lo nuevo: **`**FREE`**, procedimientos, variables con
  nombre.
- ❌ Programas monolíticos nuevos sin ILE, o `DFTACTGRP(*YES)` en código nuevo.
- ❌ Acceso nativo por registro para lógica de conjunto nueva (bucles `CHAIN`/`READE` que son un
  *join*).
- ❌ Definir tablas nuevas con DDS en lugar de SQL DDL.
- ❌ **Miembros de fuente de `QSYS.LIB` como control de versiones.** El fuente va a Git, en el IFS.
- ❌ Compilar o crear objetos a mano en producción.
- ❌ `QSECURITY` por debajo de 40; `*ALLOBJ` repartido; `*PUBLIC *CHANGE` en bibliotecas de datos.
- ❌ Programas que adoptan autoridad y permiten línea de comandos.
- ❌ Confiar la seguridad al menú 5250 dejando ODBC/FTP/DDM sin controlar.
- ❌ Presentar como modernización un envoltorio web de las mismas pantallas 5250 (§6).
- ❌ Planificar un upgrade de release sin comprobar antes el techo que impone la generación Power.
- ❌ Citar cifras de coste perpetua-vs-suscripción o de cuota de mercado de IDE sin nombrar la
  fuente y su método (§8).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Release vigente de IBM i y su calendario**: a ago-2026, soportadas 7.6, 7.5 y 7.4 (esta última
   con cambio de nivel de servicio el 30-sep-2026 y extensión hasta 30-sep-2029). **Hueco
   declarado: IBM no había anunciado fechas de fin de soporte para 7.5 ni 7.6.** No las infieras
   como si fueran anuncio; consulta la página oficial de soporte de releases de IBM i (PID
   5770-SS1).
2. **Matriz release ↔ generación Power** y nivel mínimo de firmware antes de comprometer un
   upgrade.
3. **Modelo de licencia vigente**: qué tiers siguen teniendo perpetua, condiciones de la
   suscripción y del *5250 Enterprise Enablement*. **Precios no se documentan aquí: IBM no los
   publica en las cartas de anuncio y solo son fiables vía oferta de partner.**
4. **Estado y licencia de Code for IBM i**: a ago-2026, `codefori/vscode-ibmi`, **licencia MIT**
   verificada en el repositorio; proyecto **comunitario, sin soporte de IBM**. Verifica también si
   sigue siendo el repositorio activo antes de apoyar una decisión en él — el feed de releases de
   GitHub no es la fuente de verdad si el proyecto se muda.
5. **Estado de RDi**: 9.8 con discontinuación de soporte el 30-abr-2026; 9.9 publicada el
   5-dic-2025. Verifica el calendario de 9.9 y quién la soporta (IBM contrata a Fortra).
6. **Nivel de Technology Refresh** vigente para tu release y qué IBM i Services añade: la lista de
   vistas SQL crece en cada TR y determina qué puedes automatizar.
7. Boletines de seguridad de IBM i, PTFs de seguridad acumulativos y CVEs de los componentes open
   source portados (que llegan con su propio calendario).
8. **Cifras de adopción de herramientas** (encuestas de mercado tipo Fortra): son encuestas de
   autoinforme con muestra no publicada; **úsalas como señal de tendencia, nunca como dato duro**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
