---
name: mumps-standards
description: MUMPS/M language and globals-based systems, almost exclusively healthcare. Use when working with .m routine files, M routines and labels, globals (^GLOBAL subscripted nodes, SET/KILL/MERGE/$ORDER/$QUERY/$DATA/$GET, LOCK, TSTART/TCOMMIT), one-letter command abbreviations (S, W, D, Q, K, I, F, X) and indirection (@), namespaces and routine packages, InterSystems IRIS or Caché (ObjectScript .cls classes, %SYS, Studio, Terminal, Management Portal, iris session, csession, CACHE.DAT, IRIS.DAT), YottaDB or GT.M (ydb, mumps -run, gtmprofile, ydb_gbldir, global directory .gld, region and journal configuration, MUPIP, DSE, LKE), VistA (FileMan, RPC Broker, KIDS builds, routine namespacing by package prefix), Epic Chronicles, M-to-outside integration through HL7 v2 messages or FHIR facades, or deciding whether to migrate, encapsulate or freeze a MUMPS core system.
---

# Estándares de MUMPS (M)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**MUMPS sobrevive casi en exclusiva en sanidad, y ahí es infraestructura crítica**: sistemas de
historia clínica y de laboratorio en producción continua, con décadas de reglas clínicas y
regulatorias dentro. También hay bolsas en banca (el motor GT.M sostiene aplicaciones bancarias),
pero el centro de gravedad es clínico.

**La particularidad que hay que decir sin rodeos: lo caro de MUMPS no es su edad, es que su modelo
de datos y su lenguaje son radicalmente distintos a todo lo demás.** Un *global* es un array
disperso, jerárquico, multidimensional y persistente indexado por subíndices ordenados; no es una
tabla ni un documento. El lenguaje no tiene tipos, tiene ámbito por pila y permite **indirección**
(construir y ejecutar código en tiempo de ejecución). Consecuencias prácticas:

- **No hay equivalencia mecánica** entre un global y un esquema relacional o documental: la
  traducción exige reconstruir la semántica que está *implícita en la posición de los subíndices* y
  a menudo solo en el código.
- **El análisis estático es limitado por diseño**: con indirección y `XECUTE`, saber qué toca un
  programa puede requerir ejecutarlo.
- **Código y dato viven en el mismo sistema**, lo que rompe casi todas las suposiciones de una
  cadena de CI/CD estándar (§4).

Postura honesta de partida:
- **Ningún sistema nuevo se escribe en MUMPS.** No es un juicio sobre el lenguaje: es que su
  ecosistema, su mercado laboral y su tooling no sostienen una elección nueva.
- **Y aun así, migrar un núcleo MUMPS existente fracasa más que ninguna otra migración legacy**
  (§7). La respuesta correcta suele ser **encapsular y congelar**, no reescribir.
- **Escribir código nuevo *dentro* de un sistema MUMPS existente sí es normal y legítimo**, y ahí
  esta skill fija criterio.

Cubre: dónde vive realmente (VistA, Epic, InterSystems); estándar frente a implementaciones (IRIS/
Caché vs. YottaDB/GT.M) y sus licencias; globals y su relación con las capas relacional y de
documento; disciplina de lenguaje (abreviaturas, ámbito, indirección); rutinas, paquetes y
espacios de nombres; integración real (HL7 v2 y FHIR, no SQL); pruebas y control de versiones; y la
decisión de migrar o no.

**No aplica**:
- `legacy-modernization-standards` (**skill paraguas de este bloque**): suya
  la estrategia de modernización, el análisis de cartera y la decisión de invertir, migrar o
  retirar; **aquí el criterio técnico de esta plataforma**.
- `migration-projects-standards`: suya la **ejecución del corte** — ensayo, ventana, convivencia con
  el sistema clínico nuevo y su reconciliación, cuadre del dato, rollback y apagado del origen.
- `healthtech-fhir-standards` (**Ola 7, planificada**): **suyo todo el criterio de
  interoperabilidad clínica** — perfiles FHIR, recursos, terminologías (SNOMED CT, LOINC),
  IHE y el detalle de HL7 v2. Aquí solo **por qué el dato clínico sale por ahí y no por SQL** (§6).
- `enterprise-architecture-standards` (**ya escrita**): inventario, modelo **TIME** y las **"R"**.
- `tech-leadership-standards` y `project-management-standards` (cómo se financia y se decide).
- `refactoring-tech-debt-standards` (**suyos** *strangler fig*, rama por abstracción y
  caracterización de código sin tests; aquí solo lo específico de la plataforma).
- `testing-qa-standards` (estrategia de prueba), `cicd-standards` (la pipeline),
  `git-workflow-standards` (ramas, commits, releases).
- `sql-standards`, `data-platform-standards`, `nosql-standards` (motores y lenguajes de propósito
  general; aquí el global y la proyección SQL de IRIS solo en lo que decide sobre el programa).
- `dotnet-standards`, `jvm-spring-standards`, `python-standards`, `go-standards` (destinos de una
  reescritura o de la capa de servicios: **la calidad del código destino es suya**).
- `grc-compliance-standards` y `privacy-engineering-standards` (**marco de cumplimiento y de
  protección de datos personales**: aquí solo su aterrizaje técnico, §5),
  `identity-access-management-standards`, `bcdr-standards`, `backup-recovery-standards`,
  `observability-standards`, `vulnerability-management-standards`.
- `offensive-security-standards`: **esta skill es defensiva**.
- `mainframe-zos-cobol-standards` y `ibm-i-rpg-standards`: **son tres plataformas distintas que la
  gente mete en el mismo saco de "legacy" y que no comparten casi nada** — MUMPS no tiene JCL, ni
  tiers de licencia por core, ni un motor relacional debajo; su problema es el modelo de datos. No
  extrapoles criterio entre ellas.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada |
|---|---|---|
| Estándar del lenguaje | Existe, pero **no es la referencia práctica**: manda la implementación | Último ANSI: **X11.1-1995**; internacional **ISO/IEC 11756:1999** (define el lenguaje como "M"), **reafirmado por ISO en 2020**. La acreditación ANSI decayó al disolverse la M Technology Association el 1-ene-2002; la revisión de 1998 del MDC nunca se presentó a ANSI |
| Implementación comercial | **InterSystems IRIS** (y *IRIS for Health*) | Versión **2026.1** en GA, marcada como release **EM (Extended Maintenance)**. Modelo comercial: **licencia propietaria de suscripción/soporte negociada con el fabricante — no publica tarifas** (§8) |
| Caché / Ensemble | **En fin de vida: hay que salir** | Las **últimas releases de mantenimiento de Caché y Ensemble están previstas para Q1-2027**. Un proyecto que hoy siga en Caché tiene una migración a IRIS por delante con fecha |
| Implementación libre | **YottaDB** para despliegues nuevos o rehosting | Última release verificada en el feed del repositorio oficial (GitLab): **r2.06, publicada el 27-abr-2026**, que corrige un bug del compilador de **r2.04** (30-mar-2026) — **usar r2.06, no r2.04** |
| Licencia de YottaDB | **Verificada leyendo el árbol en crudo** | `COPYING` = *"GNU AFFERO GENERAL PUBLIC LICENSE / Version 3, 19 November 2007"* → **AGPLv3**. El fichero `LICENSE` **no es el texto de la licencia**, sino notas de copyright y aclaraciones sobre obras derivadas: no lo confundas |
| GT.M | El original del que YottaDB es fork; **mantenido por FIS**, orientado a su producto bancario | **AGPLv3 en Linux**, con opción propietaria (doble licencia). Cadencia y visibilidad públicas menores que YottaDB |
| Implicación de AGPL | **Decisión de arquitectura, no trámite** | AGPLv3 alcanza el uso en red: si modificas el motor y lo ofreces como servicio, hay obligación de fuente. **Usarlo sin modificar, con tu aplicación M encima, es el caso normal — pero confírmalo con asesoría legal, no con esta tabla.** Ver `opensource-licensing-standards` |
| Dónde vive | **VistA** (sector público sanitario), **Epic** (Chronicles), aplicaciones de laboratorio y banca sobre GT.M | Determina qué puedes tocar: en un producto comercial cerrado, el margen de ingeniería propia es la capa de integración, no el núcleo |

## 3. Estructura y convenciones

- **Los globals son la base de datos, y su forma es el esquema.** El significado de cada subíndice
  —qué identifica, en qué orden, con qué tipo— **debe estar documentado fuera del código**, con
  dueño. Un sistema M sin diccionario de globals mantenido es un sistema cuya migración ya es
  imposible de estimar. En VistA, ese diccionario es **FileMan** y es la vía correcta de acceso; en
  IRIS, las clases y su *storage definition*. **Acceder al global por debajo del diccionario salta
  toda la validación y la lógica de negocio: se hace solo con motivo escrito.**
- **IRIS expone encima estructuras relacionales y de documento** (proyección SQL de las clases,
  JSON, tablas particionadas en 2026.1). Úsalas para lectura, informes e integración; **no
  confundas la proyección con el modelo**: los globals siguen siendo la verdad, y una tabla
  proyectada puede ocultar que el dato real es disperso, jerárquico y con reglas de subíndice.
- **Abreviaturas de comando: decisión de mantenibilidad, no de estilo.** El lenguaje permite
  `S X=1 I X D ^RTN`; se escribe `SET`, `IF`, `DO`. La compresión nació de una restricción de
  memoria que **no existe desde hace décadas** y hoy solo compra ilegibilidad: es una causa material
  de que estos sistemas sean caros. **Todo lo nuevo y todo lo que se toque: comandos completos, una
  sentencia por línea, comentario de propósito.** Sin reescrituras masivas de expansión sin test de
  caracterización.
- **`NEW` explícito** para toda variable local: sin él, la variable es visible hacia abajo en la
  pila y una rutina llamada puede pisarla. **Es el bug clásico y solo se evita por disciplina.**
- **Indirección (`@`) y `XECUTE`: prohibidos en código nuevo salvo justificación escrita.** Cada
  uso destruye el análisis estático, la búsqueda de referencias y la refactorización segura — para
  ti y para cualquier herramienta de migración futura.
- **`LOCK` y transacciones**: la concurrencia es responsabilidad explícita del programador. Todo
  bloqueo con timeout y liberación garantizada; toda actualización multi-global bajo
  `TSTART`/`TCOMMIT`. Un `LOCK` sin timeout en un sistema clínico es un incidente con fecha.
- **Nombres**: respeta los prefijos por paquete/espacio de nombres (en VistA, el namespace asignado
  al paquete). Colisionar en rutinas o globals no da error de compilación: da corrupción silenciosa.

## 4. Pruebas, versionado y CI (código y dato en la misma instancia)

- **El fuente canónico vive en Git, fuera del sistema**: rutinas `.m` y clases exportadas a
  ficheros con importación/exportación automatizada. Que el sistema edite y compile en caliente
  **no lo convierte en el repositorio**.
- **Problema estructural**: código y dato comparten instancia, así que un entorno de test **es otra
  instancia** con su propio conjunto de globals. Sin ella no hay pruebas reales. Y **datos de
  prueba enmascarados siempre**: copiar globals clínicos a test es la vulneración más frecuente de
  esta plataforma.
- **Pruebas**: marco de unidad de la implementación (IRIS, o el de la comunidad YottaDB) sobre
  rutinas con entrada y salida explícitas — razón práctica para no pasar parámetros por variables
  de pila. Para el núcleo heredado, **caracterización por comparación de globals antes/después**.
- **Despliegue**: paquete versionado, reproducible y **reversible** (build KIDS en VistA, paquete
  de clases/rutinas en IRIS). Importar rutinas a mano no es reversible: no llega a producción.
- **Gate de CI mínimo**: compila sin avisos, la suite pasa contra instancia limpia con datos
  sintéticos, y ninguna rutina se edita en producción.

## 5. Seguridad y protección de datos

- **Aquí la seguridad es requisito legal antes que técnico** (datos de salud, categoría especial).
  El marco —base jurídica, evaluación de impacto, retención, derechos, encargados, notificación de
  brechas— lo fijan **`grc-compliance-standards` y `privacy-engineering-standards`**; aquí solo su
  aterrizaje en la plataforma.
- **La autorización efectiva está en la aplicación, no en el motor**, y el acceso directo al global
  la elude. Cuentas de acceso directo (terminal, `iris session`, `mumps -direct`, DSE/MUPIP)
  **nominativas, mínimas, auditadas y con MFA**; cero credenciales compartidas de mantenimiento.
- **Auditoría de accesos a la historia clínica** activada y exportada fuera de la instancia:
  "quién consultó a este paciente" es exigible legalmente y es la primera pregunta del incidente.
- **Cifrado** en reposo y en tránsito para toda interfaz, **incluido HL7 v2 por MLLP sobre TCP**,
  que históricamente viaja en claro dentro del hospital. **Red interna no es canal de confianza.**
- **La superficie de ataque son las interfaces** (MLLP, servicios web, sesiones de terminal,
  transferencias por fichero), no el lenguaje.
- **Journaling y copias**: el *journal* es lo que permite recuperar; verifica retención,
  replicación fuera de la instancia y **restauración probada** (`backup-recovery-standards`,
  `bcdr-standards`).

## 6. Integración: por qué el dato sale por HL7 v2 y FHIR

- **La vía clínica no es SQL, y no por limitación técnica sino semántica**: un `SELECT` sobre una
  proyección devuelve filas sin el contexto (identidad del paciente, unidades, codificación, estado
  del documento, quién y cuándo) que el receptor necesita para usar el dato con seguridad. **HL7
  v2** es lo instalado en hospitales; **FHIR**, el destino de toda integración nueva.
- **Criterio**: todo consumidor externo entra por interfaz clínica estándar, nunca leyendo globals
  ni tablas proyectadas; la proyección SQL se reserva a informes internos bajo control.
- **El detalle de recursos, perfiles, terminologías y conformidad es de `healthtech-fhir-standards`
  (Ola 7, planificada).** La fachada es además **el desacople que hace posible congelar el núcleo**
  (§7): los consumidores pasan a depender de un contrato, no de la forma del global.

## 7. Migrar, no migrar y prohibiciones

**Por qué la migración de MUMPS fracasa más que ninguna otra** (mecanismos, no estadística):

1. **No hay destino natural del modelo de datos.** El global no mapea a tablas ni a documentos sin
   una decisión de diseño por cada estructura, y esas decisiones son cientos.
2. **La semántica está en el código, no en el esquema.** Los subíndices no se autodescriben; el
   significado vive en rutinas escritas por gente que ya no está.
3. **La indirección impide la traducción automática fiable**: lo que no se puede analizar
   estáticamente no se puede convertir con garantías.
4. **El sistema no se puede parar.** Es asistencia sanitaria: la migración es en caliente, con
   doble escritura y reconciliación, durante años.
5. **Las reglas clínicas y regulatorias incrustadas** no están especificadas en ningún sitio salvo
   el propio código, y equivocarse tiene consecuencias asistenciales, no solo económicas.
6. **En productos comerciales (Epic, y buena parte de VistA integrada) el núcleo no es tuyo**: la
   migración no es un proyecto de ingeniería, es una sustitución de proveedor.

**Sobre porcentajes de fracaso**: circulan cifras de fracaso de migraciones clínicas sin estudio
primario localizable. **No las uses.** Argumenta con los seis mecanismos de arriba y con el
inventario de tu sistema.

**Qué se hace en su lugar — la estrategia por defecto:**

1. **Encapsular**: toda la lógica de acceso queda detrás de rutinas/servicios con contrato
   explícito; nadie nuevo lee globals directamente.
2. **Exponer por FHIR**: los consumidores externos se enganchan a la fachada, no al núcleo.
3. **Congelar el núcleo**: se corrige y se cumple normativa, pero la funcionalidad nueva se
   construye fuera, contra la fachada (*strangler fig*, de `refactoring-tech-debt-standards`).
4. **Documentar el diccionario de globals** como activo con dueño: es el único trabajo que hace la
   migración futura estimable, y **hay que hacerlo aunque nunca se migre**.
5. **Sustituir por dominios**, si se sustituye: laboratorio, farmacia, facturación — nunca el
   sistema entero de una vez.

**Prohibiciones:**

- ❌ **PROHIBIDO** planificar una reescritura *big bang* del núcleo. Sin excepción y sin importar
  qué prometa el proveedor de herramientas de conversión.
- ❌ Traducción automática de rutinas M a otro lenguaje presentada como modernización: hereda la
  estructura del original y añade una capa que nadie entiende.
- ❌ Escribir código nuevo con abreviaturas de una letra, sin `NEW`, o con indirección/`XECUTE`.
- ❌ Acceder a un global por debajo del diccionario (FileMan, clases de IRIS) sin motivo escrito.
- ❌ `LOCK` sin timeout; actualizaciones multi-global sin transacción.
- ❌ Editar rutinas directamente en producción, o tratar la instancia como repositorio de código.
- ❌ **Copiar globals clínicos de producción a un entorno de test sin enmascarar.**
- ❌ Integrar a un consumidor externo leyendo globals o tablas proyectadas en vez de por interfaz
  clínica estándar (§6).
- ❌ Interfaces HL7 v2 por MLLP en claro "porque es red interna".
- ❌ Quedarse en **Caché/Ensemble sin plan de salida**: hay fecha de última release de
  mantenimiento (§2).
- ❌ Asumir la licencia de un motor M por lo que dice su web o un fichero llamado `LICENSE`:
  **se lee el `COPYING` en crudo** (§2, §8).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **InterSystems IRIS**: versión vigente (a ago-2026, **2026.1**, release EM), calendario de
   soporte de la que uses y plataformas retiradas en cada release. **Hueco declarado: InterSystems
   no publica tarifas ni el detalle del modelo de licencia**; cualquier cifra de coste tiene que
   venir de tu oferta contractual, no de esta skill.
2. **Caché/Ensemble**: confirmar el calendario de fin de mantenimiento (verificado a ago-2026:
   últimas releases de mantenimiento previstas para **Q1-2027**) antes de comprometer un plan de
   migración.
3. **YottaDB**: última release **en el repositorio oficial de GitLab** (a ago-2026, **r2.06** del
   27-abr-2026; **r2.04 tiene un bug de compilador corregido en r2.06**) y licencia leída en crudo
   (`COPYING` = AGPLv3). **Aviso: el espejo de GitHub y su feed de releases no son la fuente de
   verdad; el proyecto vive en GitLab.**
4. **GT.M**: release vigente y estado de mantenimiento por FIS, y su doble licencia (AGPLv3 en
   Linux / propietaria). **Discrepancia declarada**: la última release documentada públicamente que
   pude fechar es de dic-2024, con anuncios públicos escasos; **eso no prueba abandono** —el motor
   sostiene aplicaciones bancarias en producción— pero sí que **su calendario no es verificable
   desde fuera**. Si dependes de GT.M, exige el calendario por contrato.
5. **Estándar del lenguaje**: ISO/IEC 11756:1999 y su estado de reafirmación; y sobre todo **qué
   extensiones propietarias usa tu código**, que es lo que decide la portabilidad real entre
   implementaciones.
6. **Alcance de AGPLv3 en tu despliegue** (uso en red, modificaciones, distribución): consúltalo
   con asesoría legal y con `opensource-licensing-standards`; no lo resuelvas con esta tabla.
7. CVEs y avisos de seguridad de la implementación y de los componentes de integración (motores
   HL7, gateways web).
8. **Estado de `healthtech-fhir-standards`** (planificada en la Ola 7): cuando exista, **todo el
   criterio de interoperabilidad clínica es suyo** y esta skill solo lo referencia.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
