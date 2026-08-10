---
name: migration-projects-standards
description: How a platform or infrastructure migration is actually executed - the cutover, not the strategy. Use when writing a cutover runbook or pre-migration checklist, scheduling a cutover window and its dress rehearsal, defining go/no-go and abort criteria and naming who declares them, planning migration waves versus a single all-at-once switch, running dual writes and reconciling both sides, backfilling and then proving row counts, checksums and control totals match after the move, rehearsing a rollback instead of assuming one, lowering DNS TTL before a switch, declaring a change freeze and pricing what it costs, notifying users of an outage window, running the hypercare or warranty period after the switch, or setting a dated decommissioning plan for the source system that is still powered on just in case.
---

# Estándares de ejecución de migraciones

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **cómo se ejecuta el traslado**, sea el origen heredado o no: migración de un datacenter, de
hipervisor, de proveedor cloud, de motor de base de datos, de sistema de correo o identidad, de una
aplicación a otra. **El objeto de esta skill es el corte** —la transición del tráfico y del dato del
sistema origen al destino— y todo lo que lo rodea: inventario de dependencias, ensayo, ventana,
criterios de abortar, verificación, marcha atrás y descomisionado.

**Principio rector**: **una migración no termina cuando el sistema nuevo arranca; termina cuando el
viejo está apagado y el dato cuadra.** Todo lo que se declara "hecho" antes de eso es un estado
intermedio con dos sistemas vivos, y ese estado es el modo de fallo más caro y más común del dominio
(§7). Corolario falsable aplicable a cualquier plan de migración que te enseñen: **si no contiene una
fecha de apagado del origen con dueño nombrado, no es un plan de migración, es un plan de
duplicación.**

Segundo corolario, de aplicación inmediata: **"arrancó" no es un criterio de éxito.** El criterio es
que los datos cuadren contra el origen con una comprobación definida antes del corte (§4).

**No aplica**: ver `legacy-modernization-standards` (**frontera dura y recíproca**: **allí la
estrategia y qué hacer con el sistema** —qué "R", si se congela, si se reescribe, la caracterización
previa y la arqueología del build—; **aquí la ejecución del corte** una vez decidido. Regla de
arbitraje: si la pregunta es *"¿qué hacemos con este sistema?"*, es suya; si es *"¿cómo lo movemos
sin romper nada y cuándo apagamos el viejo?"*, es de aquí); `project-management-standards` (la
gestión del proyecto: enfoque de entrega, estimación, RAID, informes, interesados, cierre. **Aquí
solo los artefactos propios del corte**, que no son gestión genérica: el *runbook*, el ensayo y los
criterios de abortar); `erp-sap-standards` (**recíproca: la migración a un ERP de paquete tiene
restricciones que no vienen de la técnica sino del contrato** — el calendario de mantenimiento que
fija la fecha, la licencia que cambia con la arquitectura, el reparto de responsabilidad del modelo
de despliegue y el gobierno de transportes. Todo eso es suyo y **condiciona la ventana de corte que
se diseña aquí**; el corte en sí, su ensayo, su cuadre y su marcha atrás son de esta skill. El error
típico si no se leen juntas: fijar la ventana sin saber que el paisaje de origen está en congelación
de transportes con dueño y fecha propios); `bcdr-standards` (**RTO/RPO y desastre**: una migración es un cambio
planificado, no un desastre, y **su ventana no es un RTO**. Recíproca útil: el ensayo de un corte y
un ejercicio de DR se parecen tanto que conviene reutilizar el mismo runbook, pero el que declara la
activación y el que declara el aborto no son la misma figura); `data-engineering-standards` (los
pipelines de extracción, carga y reproceso **en sí**: orquestación, *backfill*, idempotencia. Aquí
solo lo que decide si el corte se aborta); `data-governance-quality-standards` (las dimensiones de
calidad del dato y su medición continua; aquí la comprobación puntual del corte);
`microservices-architecture-standards` (**suyo el mecanismo** de la doble escritura atómica —
*transactional outbox*, sagas, propiedad del dato—; **aquí la doble escritura como técnica de
transición y su reconciliación**, §3.4); `enterprise-architecture-standards` (qué se migra y por
qué, a nivel de cartera); `itsm-itil-standards` (la migración como **cambio** dentro del proceso de
servicio, la ventana de cambio y el traspaso a operación); `incident-management-standards` (si el
corte se convierte en incidente, manda su proceso: IC, severidad, comunicación de crisis);
`dns-standards` (registros, TTL y su mecánica); `cicd-standards` (el despliegue de la aplicación,
que no es una migración); `backup-recovery-standards` (la copia previa al corte y su restore
probado); las skills de plataforma de origen y destino, que mandan sobre **cómo** se mueve cada cosa.

## 2. Decisiones por defecto

> Tabla de criterio, no de herramienta. Verificar por web cualquier producto o límite concreto (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Forma del corte | **Por olas**, agrupadas por dependencia, con la primera ola deliberadamente pequeña y reversible | Corte único, **solo** con las condiciones de `legacy-modernization-standards` §3.2 verificadas (estado indivisible, sin costura, fecha contractual) |
| Ensayo | **Ensayo completo con datos reales enmascarados sobre infraestructura equivalente**, cronometrado | Ensayo parcial + *tabletop* del resto, si el coste del entorno equivalente es prohibitivo — **declarado como riesgo aceptado, no como equivalente** |
| Marcha atrás | **Rollback ensayado** dentro de la ventana, con su propio cronómetro | ***Fix forward*** declarado **antes** del corte, cuando el rollback es imposible por el dato ya movido. No se improvisa el día del corte |
| Convivencia de datos | **Un solo sistema de registro en cada instante**; el otro es réplica de solo lectura | **Doble escritura** con reconciliación automática (§3.4), solo si la convivencia es obligatoria y se acepta su coste |
| Ventana | **Con parada declarada** y comunicada, aunque sea corta: una parada honesta es más barata que una degradación silenciosa | Corte sin parada (*live*), solo con doble escritura probada y capacidad de conmutar tráfico gradualmente |
| Verificación | **Cuadre de dato definido y automatizado antes del corte** (§4) | Ninguna. No hay alternativa: sin criterio de cuadre no se corta |
| Congelación | **Congelación de cambios acotada y con fecha de fin publicada** desde el inicio | Congelación parcial (solo lo que toca el alcance) si el negocio no la aguanta — con el riesgo de divergencia explícito |
| Apagado del origen | **Fecha comprometida en el mismo documento que aprueba el corte** | Ninguna. "Ya lo apagaremos" no es una alternativa (§7) |

## 3. Anatomía del corte

### 3.1 Paso cero: inventario y dependencias

**Nada empieza hasta que existe el inventario de lo que se mueve y de lo que le habla.** No es el
inventario de aplicaciones de la organización (eso es `enterprise-architecture-standards`) ni la
CMDB (`itsm-itil-standards`): es **el grafo de dependencias del alcance concreto**, y se construye
con dos fuentes que hay que cruzar porque ninguna basta:

- **Lo declarado**: configuración, ficheros de conexión, DNS, reglas de firewall, documentación.
- **Lo observado**: conexiones reales durante un periodo que incluya **el cierre de mes y el proceso
  anual**, medido con flujos de red, logs de conexión de la base de datos o el propio balanceador.

Lo que aparece solo en uno de los dos lados es el hallazgo valioso: **una dependencia declarada que
nadie usa** (candidata a retirar) o **una dependencia real que nadie había declarado** (la que
rompe el corte). Salidas obligatorias: quién consume el sistema, qué consume él, **quién tiene
credenciales o IPs cableadas a mano**, qué trabajos por lote lo tocan y con qué calendario, y qué
ventana del año es intocable por negocio.

### 3.2 Ensayo previo

- **Se ensaya el corte completo, no sus piezas.** Un ensayo válido produce **tres números**: cuánto
  tardó cada paso, cuánto tardó el rollback, y cuántas diferencias encontró la verificación. Sin los
  tres, fue una reunión.
- El *runbook* de corte es un documento vivo con tarea, **secuencia, duración planificada y real,
  dueño y criterio de éxito por paso**. Referencia pública verificable (AWS Prescriptive Guidance,
  *Pre-cutover stage*, **verbatim**): *"we recommend that your cutover plan includes contingency
  plans and risk mitigation strategies for failure in the event of an unsuccessful cutover. Be sure
  to document a rollback procedure as part of the cutover plan"*, y entre los elementos a analizar
  antes: *"Impact to the business (for example, on revenue or trust) of an overrun of the allocated
  downtime window"*, *"Contingency for 'fix forward' activities in the event of unforeseen events"* y
  *"Rollback time in the event of a failure"*.
- **El ensayo descubre lo que el plan no sabía**: credenciales caducadas, un certificado atado al
  hostname viejo, un lote que solo corre los días 1 y 15, permisos que solo tiene una persona. Por eso
  se ensaya **con las mismas personas y en la misma franja horaria** que el corte real.
- **Un paso del runbook que solo sabe ejecutar una persona es un riesgo, no un detalle.** Se ensaya
  con el suplente.

### 3.3 Criterios de éxito y de abortar — antes, y con nombre

**Se escriben y se aprueban antes del corte, nunca durante.** Durante el corte, con la ventana
corriendo y gente cansada, **el sesgo es siempre a continuar**: el coste ya invertido pesa más que la
evidencia. Los criterios existen precisamente para neutralizar eso.

| Elemento | Regla |
|---|---|
| **Criterio de éxito** | Comprobación concreta y automatizable, no "funciona": cuadre de dato (§4), transacción de negocio extremo a extremo, latencia dentro de umbral, lote nocturno completado |
| **Punto de no retorno** | **Instante exacto del runbook a partir del cual el rollback deja de ser posible**, marcado en el documento. Antes de cruzarlo hay una decisión explícita go/no-go |
| **Criterio de aborto** | Condiciones objetivas y medibles: se supera el tiempo asignado a un paso crítico, la verificación falla, aparece un fallo de clase no prevista |
| **Quién lo declara** | **Una persona nombrada, con nombre y suplente**, con autoridad para abortar sin pedir permiso — y **no es quien ejecuta el corte**, que está dentro del sesgo |
| **Reloj de decisión** | Hora concreta ("a las 04:00, si X no está, se aborta"). Un criterio sin hora se pospone hasta que es tarde |

**Abortar según el criterio no es un fracaso del proyecto: es el proyecto funcionando.** Si abortar
se vive como fracaso personal, nadie abortará nunca y el criterio es decorativo. Se dice antes, por
escrito, y lo dice quien manda.

### 3.4 Doble escritura y reconciliación

- **La doble escritura no es una transacción distribuida.** Escribir en dos sistemas sin atomicidad
  produce divergencia garantizada bajo fallo parcial; el mecanismo correcto (*transactional outbox*,
  CDC desde el log) es de `microservices-architecture-standards` y `streaming-cdc-standards`. Aquí la
  consecuencia de ejecución: **la doble escritura obliga a un reconciliador, y el reconciliador es
  parte del entregable, no una tarea futura.**
- **Sentido único de la verdad en cada instante**: un sistema es el de registro y el otro sigue. La
  doble escritura bidireccional simétrica sin resolución de conflictos determinista **no se hace**.
- **El reconciliador** corre en continuo mientras dure la convivencia, compara por clave natural,
  **alerta sobre divergencia** y deja registro. Divergencia creciente = criterio de aborto (§3.3).
- **Toda escritura de migración es idempotente y reintentable**: los reintentos ocurren, y un
  *backfill* que duplica al reintentarse convierte la verificación en imposible.
- **La convivencia tiene fecha de fin desde el primer día.** Es la misma regla que el apagado del
  origen (§7) y se incumple igual de fácil.

## 4. Verificación de integridad: "cuadra", no "arrancó"

**Se define antes del corte, se automatiza y se ejecuta también en el ensayo.** Niveles, en orden de
fuerza creciente; se elige el más fuerte que sea viable, no el más cómodo:

1. **Recuento por entidad**: filas, objetos, buzones, ficheros — origen frente a destino, con la
   política explícita sobre lo que se decidió **no** migrar (histórico, borrados lógicos, ficheros
   huérfanos). Un descuadre "esperado" que no estaba escrito antes es un descuadre.
2. **Sumas de control de negocio**: totales de las magnitudes que importan (saldos, importes,
   unidades) por periodo. Detecta lo que el recuento no ve: el registro migrado con el valor mal
   convertido, el decimal truncado, la fecha desplazada por zona horaria.
3. **Hash por registro o por lote** sobre los campos que deben ser idénticos, normalizando antes lo
   que legítimamente cambia (identificadores técnicos, marcas de tiempo de carga, codificación).
   **Normalizar es una decisión que se documenta**: es donde se esconden los errores reales.
4. **Comparación funcional**: la misma consulta o el mismo informe de negocio ejecutado contra ambos
   y comparado. Es el que convence al usuario, y el único que valida la semántica.
5. **Muestreo humano dirigido** sobre los casos raros conocidos: el registro corrupto histórico, el
   cliente con caracteres no ASCII, el importe negativo, el registro de 1998.

Reglas duras:
- **Conversión de codificación, zonas horarias y precisión numérica**: las tres causas de descuadre
  silencioso más frecuentes en migraciones entre plataformas distintas. Se verifican explícitamente,
  no se asumen.
- **La verificación se ejecuta antes de liberar a los usuarios**, no después. Si solo cabe después,
  el criterio de aborto se sustituye por un criterio de **retirada** con su propio reloj.
- **Periodo de garantía (*hypercare*)**: tras el corte, guardia reforzada con dueño y duración
  declarada, y **la reconciliación sigue corriendo** durante ese periodo. Su final es una decisión
  explícita, no el día que la gente deja de mirar.
- **Lo que no se puede verificar automáticamente se declara**: es riesgo residual aceptado con firma,
  no un hueco silencioso.

## 5. Seguridad durante la migración

Una migración es una **ventana de exposición**: hay copias de datos fuera de su sitio, credenciales
nuevas, reglas de firewall temporales y gente con permisos elevados a las tres de la mañana.

- **Datos reales fuera de producción** (ensayo, entorno paralelo, extracción intermedia): enmascarado
  y base jurídica, con **fecha de borrado de las copias temporales** y comprobación de que se
  borraron. Es el residuo más común de una migración (`privacy-engineering-standards`).
- **Cifrado en tránsito y en reposo también en lo temporal**: el volcado intermedio, el bucket de
  paso y el disco USB del traslado son datos de producción.
- **Credenciales**: las del destino son nuevas y con mínimo privilegio desde el día uno; **no se
  clonan las del origen**. Los accesos elevados del corte son temporales, nominativos y con fecha de
  caducidad automática, no "ya lo quitaremos".
- **Reglas de red temporales** (aperturas para la replicación) se crean con caducidad y se verifica
  su cierre en el descomisionado (§7). Una migración deja tantas reglas huérfanas como copias.
- **El origen apagado pero no descomisionado sigue siendo superficie de ataque**, con parches que ya
  nadie aplica porque "está en migración".

## 6. Congelación y comunicación

- **La congelación de cambios tiene coste y hay que decirlo**: cuanto más dura, más diverge el origen
  del destino ya probado y más presión de excepciones, hasta que la excepción es la norma y la
  congelación es ficción. **Se declara acotada, con fecha de fin publicada desde el inicio y con un
  procedimiento de excepción con dueño único** — y toda excepción concedida **se replica en el
  destino y se vuelve a verificar** (§4), o se ha roto el ensayo.
- **La congelación no es gratis aunque nadie la pida**: durante ella el negocio acumula demanda. Ese
  coste entra en la comparación de opciones, no aparece después como sorpresa.
- **Comunicación a usuarios**: qué se para, cuándo empieza y cuándo termina la ventana, **qué se
  espera que noten después** (rutas nuevas, credenciales, rendimiento distinto), a quién avisan si
  algo falla, y **un aviso de fin real**, no solo de inicio. Se comunica también el **aborto** si
  ocurre: un silencio tras la ventana genera más tickets que la parada.
- **Terceros y proveedores integrados se avisan con su propio plazo**, que suele ser mayor que el
  interno y no siempre se puede acelerar. Aparecen en el inventario de §3.1 o no aparecen en absoluto.
- **Un canal único de estado durante el corte** (el mismo que se use en incidentes) y una persona
  dedicada a comunicar que **no** es quien ejecuta.

## 7. Descomisionado y prohibiciones

**El sistema viejo encendido "por si acaso" es el fallo más caro y más común de este dominio**, y es
un fallo silencioso: no produce incidente, produce factura, superficie de ataque y ambigüedad sobre
cuál es el sistema de registro. Plan mínimo, aprobado **en el mismo documento que aprueba el corte**:

1. **Fecha de apagado con dueño nombrado**, no "cuando estemos tranquilos".
2. **Periodo de retención en solo lectura** acotado y justificado, con el origen **degradado a
   solo lectura de verdad** (no por convención): si sigue admitiendo escrituras, sigue habiendo dos
   sistemas de registro.
3. **Apagado lógico antes que físico**: se detiene el servicio, se observa durante un plazo declarado
   quién se queja y qué se rompe (esa es la última verificación de dependencias), y **solo entonces**
   se apaga y se libera.
4. **Archivado del dato** que la normativa exige conservar, **con restauración probada** — un archivo
   que no se sabe leer dentro de cinco años no es archivado (`backup-recovery-standards`).
5. **Limpieza del rastro**: reglas de firewall temporales, registros DNS, entradas de monitorización,
   copias intermedias, cuentas de servicio, licencias y contratos de soporte. **Cancelar el contrato
   es parte del descomisionado**: es donde está el ahorro que justificó el proyecto.

**PROHIBIDO**
- ❌ Cortar **sin criterios de aborto escritos y aprobados antes**, y **sin una persona nombrada** con
  autoridad para declararlos (§3.3).
- ❌ Cortar **sin ensayo previo cronometrado**. Un plan no ensayado es una hipótesis con horario.
- ❌ Dar por buena una migración porque **el sistema arrancó**, sin cuadre de dato definido de
  antemano (§4).
- ❌ **Rollback teórico**: documentado y nunca ejecutado. Si no se ha ejecutado en el ensayo, no
  existe; se declara *fix forward* y se asume, o no se corta.
- ❌ **Terminar la migración sin fecha de apagado del origen** con dueño (§7).
- ❌ Dejar el origen encendido **admitiendo escrituras** tras el corte: dos sistemas de registro es
  corrupción de datos con fecha.
- ❌ Doble escritura **sin reconciliador automático** y sin fecha de fin de la convivencia (§3.4).
- ❌ Ensayar o migrar **con datos de producción sin enmascarar** fuera de producción (§5).
- ❌ Dejar activas credenciales elevadas, reglas de red temporales o copias intermedias tras el corte.
- ❌ Cambiar el alcance dentro de la ventana ("ya que estamos, actualizamos también…"): duplica las
  causas posibles de fallo y anula el ensayo.
- ❌ Congelación de cambios **sin fecha de fin publicada** o con excepciones sin dueño único.
- ❌ Ejecutar el corte con **una sola persona que sepa un paso crítico**, o sin canal de estado.
- ❌ Descubrir dependencias **preguntando** en vez de midiendo tráfico real durante un ciclo completo
  de negocio (§3.1).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, **búscalo — no lo recuerdes**:

1. **Límites y tiempos reales de las herramientas de replicación y traslado** que vayas a usar
   (servicio de migración del proveedor, replicación del motor de base de datos, sincronización de
   almacenamiento): ventana máxima, latencia de replicación, tipos de dato no soportados y qué hace
   ante un fallo a mitad. **La duración del corte se calcula con tu volumen medido en el ensayo, no
   con la cifra del folleto.**
2. **Matriz de compatibilidad y rutas de actualización soportadas** entre versión origen y destino:
   muchas migraciones requieren un salto intermedio y eso cambia la forma del plan.
3. **Fin de soporte y fecha de fin de contrato** del sistema origen: fija la fecha límite real del
   descomisionado y, a menudo, el coste que justifica el proyecto.
4. **Guía de corte del proveedor de destino**, si existe, para verificar que sigue vigente. Citada
   verbatim en §3.2: AWS Prescriptive Guidance, *Best practices for cutting over network traffic to
   AWS* — *Pre-cutover stage*. Confirma que la página no ha cambiado antes de apoyarte en ella.
5. **Cifras de fracaso de migraciones**: **hueco declarado, y es deliberado.** Las que circulan
   (Bloor Research 2007 y 2011, y sus derivadas del tipo "el 84 % fracasa") **miden retraso o
   sobrecoste, no fracaso**, proceden de encuesta autoseleccionada de analista comercial patrocinada
   por fabricante, y están tras formulario: **no pude leer el primario**. Las de gestión de proyectos
   en general (CHAOS/Standish, "el 70 % de las transformaciones") **ya están desmentidas en
   `project-management-standards`**. **No se usan para justificar ni para desaconsejar un corte**;
   se argumenta con el inventario y con los números del ensayo (§3.2).
6. **Ventanas y calendarios impuestos desde fuera** que no dependen de ti: cierre fiscal, campañas,
   ventanas de cambio de un tercero, festivos locales del equipo de guardia. Se comprueban, no se
   suponen.
7. **Requisitos normativos sobre traslado, residencia y retención del dato** aplicables al alcance
   antes de mover nada fuera de su jurisdicción (`grc-compliance-standards`,
   `privacy-engineering-standards`).

Si no puedes verificar, dilo explícitamente en vez de suponer.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
