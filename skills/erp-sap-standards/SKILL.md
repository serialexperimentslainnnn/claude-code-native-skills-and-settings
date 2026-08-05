---
name: erp-sap-standards
description: SAP as a commercial and platform decision - the maintenance clock, the deployment model and the licence audit. Use when facing SAP ECC / Business Suite 7 end of mainstream maintenance, extended maintenance 2028-2030 or customer-specific maintenance, choosing between brownfield conversion, greenfield reimplementation, selective data transition or third-party support (Rimini Street, Spinnaker), RISE with SAP or GROW with SAP contracts, SAP Cloud ERP Private (formerly S/4HANA Cloud private edition) versus SAP Cloud ERP public, SAP ERP private edition transition option, compatibility packs and their expiry, SAP named user licensing (Professional, Limited Professional, Functional, Self-Service, Developer), indirect access and digital access document licensing, the Digital Access Adoption Program, the annual licence declaration with USMM, LAW / SLAW2 and STAR, an SAP audit notice, SAP Diageo or Rimini Street licensing precedent, IDoc / BAPI / RFC / OData / Event Mesh integration choices around an ERP, SAP master data governance and MDG, SAP Activate phases, or SAP Solution Manager / Cloud ALM landscape and programme-level environment strategy.
---

# Estándares de ERP SAP (decisión de negocio, plataforma y licencia)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

SAP **como decisión de empresa**, no como lenguaje: el calendario de mantenimiento que fuerza la
mano, las cuatro salidas reales ante ese calendario, el modelo de despliegue y el reparto de
responsabilidad que trae, **el licenciamiento y la auditoría anual**, la integración con el resto
del paisaje, el gobierno del dato maestro y el gobierno de entornos a nivel de programa.

Triggers: fin de mantenimiento de ECC / Business Suite 7, mantenimiento extendido, *customer-specific
maintenance*, *brownfield* / *greenfield* / *selective data transition*, soporte de terceros (Rimini
Street, Spinnaker), **RISE with SAP**, **GROW with SAP**, SAP Cloud ERP Private / SAP Cloud ERP,
*transition option*, *compatibility packs*, usuarios nombrados, **acceso indirecto**, **digital
access**, DAAP, `USMM`, `SLAW2`/LAW, `STAR`, declaración anual de licencia, notificación de auditoría,
Diageo, IDoc, BAPI, RFC, OData, Event Mesh, MDG, SAP Activate, Solution Manager, Cloud ALM.

**El eje de esta skill: en SAP, la factura no la genera el código, la genera el contrato.** Un
proyecto SAP se decide por tres variables —fecha de fin de mantenimiento, modelo de despliegue y
métrica de licencia— y las tres están fuera del control del equipo técnico. La consecuencia
operativa que ordena todo el documento: **cualquier decisión de arquitectura que cambie *cómo* o
*quién* crea documentos en el ERP es una decisión de coste, y debe pasar por quien gestiona el
contrato antes de construirse.** Un intermediario técnico impecable puede duplicar la factura.

**No aplica**: ver `abap-sap-standards` (**frontera crítica y dueña del código**: ABAP clásico y ABAP
Cloud, ADT/Eclipse, SE38/SE80/SE24/SE11, CDS view entities, AMDP, RAP, SEGW, BAdI y *enhancements*,
paquetes y órdenes de transporte SE09/SE10/STMS, abapGit, ATC, ABAP Unit, SNOTE, el **clean core**
como doctrina de extensibilidad y la **conversión técnica** a S/4HANA. Regla de arbitraje en una
línea: **si la respuesta se escribe en un objeto del repositorio, es suya; si se firma en un contrato
o se declara en una medición, es de aquí**), `migration-projects-standards` (la ejecución del corte:
ensayo, ventana, cuadre del dato, convivencia, marcha atrás y apagado del origen),
`legacy-modernization-standards` (el paraguas de estrategia frente al sistema heredado y las "R"),
`enterprise-architecture-standards` (el inventario de aplicaciones, el modelo TIME y el encaje del
ERP en la cartera), `project-management-standards` (la gestión del programa: compromiso, estimación,
RAID, interesados), `itsm-itil-standards` (el ERP como servicio, SLA y proceso de cambio),
`oracle-dba-standards` / `sqlserver-dba-standards` (la base de datos bajo un SAP AnyDB: tuning,
backup, HA), `data-platform-standards` y `analytics-bi-standards` (la analítica fuera del ERP),
`data-governance-quality-standards` (propiedad del dato, catálogo y dimensiones de calidad; aquí solo
el dato maestro **como restricción de la conversión**), `api-design-standards` (el contrato de la API
de integración), `identity-access-management-standards` (SSO, federación y ciclo joiner-mover-leaver;
aquí solo la **cuenta como unidad de licencia**), `grc-compliance-standards` (marco de control y
evidencia de auditoría **normativa**; aquí la auditoría **de licencia**, que no es lo mismo y no la
lleva la misma gente), `opensource-licensing-standards` (**recíproca declarada**: allí las licencias
de **software libre** —SPDX, copyleft, gates de CI, SBOM—; aquí licencias **comerciales
propietarias**, donde el riesgo no es la obligación de publicar fuente sino la **liquidación
retroactiva**. No comparten método: una se automatiza en el PR, la otra se negocia en una sala),
`finops-standards` (coste cloud por unidad económica), `privacy-engineering-standards` (dato personal
dentro del ERP), `appsec-standards` (metodología de amenazas).

## 2. Decisiones por defecto

> Verificar por web antes de fijarlo (§8): el calendario, los nombres de producto y las métricas de
> licencia de SAP se mueven, y los precios **no se publican**.

| Decisión | Por defecto | Nota |
|---|---|---|
| Punto de partida del proyecto | **Auditoría de licencia y medición limpia ANTES del diseño** | §3.4; el resultado cambia la arquitectura |
| Ruta a S/4HANA con ECC muy personalizado y datos sucios | *Selective data transition* | §3.1 |
| Ruta con ECC estándar y procesos que se quieren rehacer | *Greenfield* | §3.1 |
| Ruta con ECC sano, procesos válidos y plazo corto | *Brownfield* (conversión) | §3.1 |
| Modelo de despliegue por defecto en cliente grande con procesos propios | **RISE / SAP Cloud ERP Private** | §3.2 |
| Modelo por defecto en empresa mediana sin procesos singulares | **GROW / SAP Cloud ERP público** | §3.2 |
| Nuevo consumo por sistema externo | **Digital access**, dimensionado antes de construir | §3.3 |
| Tipo de usuario por defecto al alta | El **más bajo** que permita la tarea, con rol técnico que lo impida escalar | §3.3 |
| Integración nueva | Contrato desacoplado (evento/API), **no** RFC punto a punto | §3.5 |
| Dato maestro | Dueño de negocio nombrado por objeto **antes** de la conversión | §3.6 |
| Soporte tras 2030 sin haber migrado | Decisión explícita y fechada, no deriva | §3.1 |

## 3. Estructura y convenciones

### 3.1 El reloj, y las cuatro salidas

Datos verificados (ago-2026, fuentes en §8). **Ninguno se cita de memoria en un comité: se re-verifica
contra SAP el día que se presenta.**

- **SAP Business Suite 7 / SAP ERP 6.0 (ECC)**: *mainstream* hasta **fin de 2027** para las tres
  últimas *enhancement packages* (**EhP 6-8**). Con **EhP 1-5 el mantenimiento terminó el 31-dic-2025**:
  un ECC en EhP5 hoy ya está fuera, y eso rara vez aparece en la diapositiva del proveedor.
- **Mantenimiento extendido opcional 2028-2030**: tres años, con un recargo de **dos puntos
  porcentuales** sobre la base de mantenimiento, y **alcance reducido** respecto al *mainstream*.
  Requiere addendum contractual: no se activa solo.
- **Quien no lo contrata** cae en **customer-specific maintenance**: **mismo precio, alcance
  significativamente menor**. Es el peor cuadrante económico del calendario y se llega a él por
  inacción. Ponerlo por escrito ante el comité es media decisión tomada.
- **S/4HANA no te saca del reloj, te cambia de reloj**: compromiso de innovación hasta **fin de 2040**
  (anuncio del 4-feb-2020) = *siempre habrá al menos una release en mantenimiento*, no *tu release
  vivirá hasta 2040*. Desde la **release 2023**: cadencia **bienal** (2023 → 2025 → 2027 prevista) y
  **7 años de mainstream por release** (antes 5) → 2023 hasta **dic-2030**, 2025 hasta **fin de 2032**.
- **`SAP ERP, private edition, transition option`** (anunciado feb-2025): **no es una prórroga de
  mantenimiento**. Es una **suscripción cloud centrada en ECC**, comprable **desde 2028** y **usable
  de 2031 a fin de 2033**, que exige haber movido los sistemas a *private edition* **antes de fin de
  2030** y tener contrato RISE. SAP dice explícitamente que **no incluye el alcance completo de
  Business Suite 7**. Traducción operativa: **la puerta de 2033 se cierra en 2030**, y quien la vea
  como "tenemos hasta 2033" ya perdió la ventana.

**Las cuatro salidas, con el criterio que las separa** (no es una preferencia; es una función del
estado del ECC):

| Salida | Cuándo es la correcta | Lo que cuesta de verdad |
|---|---|---|
| **Brownfield** (conversión) | ECC sano, procesos válidos, plazo corto | Te llevas la deuda: el Z que impide actualizar viaja contigo |
| **Greenfield** (implantación nueva) | Procesos que hay que rehacer; ECC irrecuperable | Gestión del cambio y **migración de histórico**, que es donde encalla |
| **Selective data transition** | Paisaje multi-sistema, quiero procesos nuevos y datos viejos | Herramienta y socio propietarios: **dependencia de un tercero** |
| **Quedarse + soporte de terceros** | Decisión deliberada de exprimir el activo | Sin cambios legales de SAP, sin notas nuevas, y **riesgo jurídico del proveedor** |

Sobre la cuarta: **existe y es legítima, pero no es gratis en riesgo.** El litigio Oracle-Rimini
Street es el precedente que hay que leer entero antes de firmar, no el titular: el Noveno Circuito
(caso 23-16038, **16-dic-2024**) **anuló** partes sustanciales de la sentencia y del interdicto de
*Rimini II* —incluido el criterio de obra derivada aplicado por el juzgado de distrito— y devolvió el
asunto; en el bloque de desacato previo se confirmaron cargos y se **anuló la cuantía** de la sanción
para recálculo. Lectura correcta para un comprador: **la cuestión no está cerrada y el proveedor de
soporte de terceros pleitea desde hace más de una década**. Exige en el contrato indemnidad por
propiedad intelectual, y planifica qué haces si tu proveedor pierde.

**Cifra famosa que NO se cita sin matizar**: el "55-75 % de los proyectos ERP fracasan". Es folclore
con núcleo real: se atribuye a Gartner y a Panorama Consulting con citación circular; **los datos
propios de Panorama en varios años dan cifras muy inferiores** (del orden del 22-26 % de fracaso
duro) y su muestra es autoseleccionada entre candidatos a rescate. Existe además una **predicción**
de Gartner (>70 % de las iniciativas ERP recientes no alcanzarán del todo sus objetivos de negocio
para 2027) que se recicla como si fuera una **medición histórica**: no lo es. Lo defendible es más
aburrido y más útil: **la mayoría sobrepasa plazo o presupuesto en algún grado y una minoría
significativa no entrega el valor prometido.** Si alguien usa el 75 % para justificar un gasto,
pídele la metodología (§8 de `project-management-standards` sobre el CHAOS Report: mismo patrón).

### 3.2 Despliegue: la pregunta no es dónde corre, es quién responde

On-premise, nube privada gestionada (RISE), nube pública (GROW) y alojamiento propio en un
hiperescalar **no son cuatro puntos de una escala de modernidad**: son cuatro repartos distintos de
responsabilidad. **Antes de elegir, se rellena esta tabla con el contrato en la mano** — y si una
celda queda vacía, esa es la incidencia de las 03:00 que nadie atenderá:

| Responsabilidad | On-prem | RISE / Cloud ERP Private | GROW / Cloud ERP público |
|---|---|---|---|
| Infraestructura y disponibilidad | Tú | SAP (bajo SLA único) | SAP |
| Aplicación de parches y upgrade | Tú, cuando quieras | SAP, en ventana **contractual** | SAP, **automático** (2 releases/año) |
| Decidir *cuándo* se actualiza | Tú | Negociado, acotado | **No decides** |
| Personalización profunda | Sí | Sí, con límites | **No**: alcance preconfigurado |
| Backup, DR y su prueba | Tú | Contractual — **pide el RTO/RPO por escrito** | Contractual |
| Salida del proveedor (exit) | N/A | **Cláusula a negociar antes de firmar** | Ídem |

Puntos que deciden y que casi nunca están en la propuesta:
- **RISE es "una oferta, un contrato"**: la simplicidad comercial es real y el riesgo también —
  **agrupa productos** (ERP, plataforma, Signavio, Business Network) y al renovar se renegocia el
  bloque, no la pieza. Exige el desglose de precio por componente **antes de firmar**, aunque la
  factura sea única; sin él no puedes reducir alcance en la renovación.
- **GROW es solo nube pública** y solo un **subconjunto** de los procesos disponibles en privada. El
  criterio honesto: si tu diferencial competitivo está en un proceso del ERP, la pública te obliga a
  moverlo fuera o a renunciar a él. Ambas cosas son decisiones de negocio, no técnicas.
- **Trampa de nomenclatura (ago-2026)**: SAP renombró la familia —*S/4HANA Cloud private edition* →
  **SAP Cloud ERP Private**, *public edition* → **SAP Cloud ERP**— y reutilizó "SAP Business Suite"
  como paraguas de la oferta cloud, que **no es** el Business Suite 7 que caduca. **En cualquier
  documento, escribe siempre versión y edición completas.**
- **Compatibility packs**: derecho de uso temporal de funciones de ECC dentro de S/4HANA. On-premise
  vencieron y bajo RISE llegan más lejos (nota 2269324; verificar fechas vigentes en §8). Lo que
  importa aquí: **es un derecho de uso, no un bloqueo técnico — la transacción sigue arrancando
  después de expirar.** Eso es exactamente lo que aparece en la siguiente medición.

### 3.3 Licenciamiento: el corazón

**Dos métricas coexisten y se suman: personas y documentos.**

**(a) Usuarios nombrados.** Cada cuenta se clasifica en un tipo (Professional, Limited Professional,
Functional, Self-Service/Productivity, Developer, Test/Platform según lista de precios contractual) y
la clasificación la fija **la tarea más alta que el usuario puede ejecutar**, no la que ejecuta
habitualmente. Reglas duras:
- **Regla del máximo**: un usuario que hace el 95 % de tareas básicas y una sola de nivel Professional
  se licencia como Professional. No se negocia con una hoja de cálculo: **se impide con el rol**.
- **Cuenta creada = cuenta contada.** El usuario del proveedor que dejó el proyecto en 2019 y sigue
  activo se factura. Bloquear no siempre basta: revisa el criterio de la lista de precios vigente.
- Corolario de diseño, y es la única palanca estructural: **el control de licencia se implementa en
  el rol de autorización**, de forma que un usuario de tipo bajo sea **técnicamente incapaz** de
  ejecutar una transacción de tipo alto. Todo lo demás es reclasificar después de que te midan.
- **La cuenta técnica de integración es una cuenta.** Su tipo y su tratamiento se pactan por escrito;
  no se asume.

**(b) Digital access (acceso indirecto): por qué te factura un pedido que creó otro sistema.** Cuando
un sistema externo —portal, CRM, RPA, IoT, un *middleware*— **crea** documentos en SAP sin que haya
una persona con licencia detrás, SAP no cobra por la persona: cobra por el **documento**. Se cuentan
**nueve tipos** (venta, factura, compra, servicio y mantenimiento, fabricación, gestión de calidad,
gestión de tiempos, material, financiero), unos por documento y otros por línea, con **material y
financiero ponderados a 0,2** (cinco líneas = un documento). **Solo cuenta la creación inicial**: leer
y actualizar después no vuelve a cobrar, y el encadenamiento de documentos derivados de un mismo
evento externo no se factura N veces. Se vende en bloques anuales. *(Esta lista y sus pesos proceden
de consultoras de licenciamiento coincidentes entre sí; SAP no la publica en abierto sin login —
**hueco declarado en §8**: la definición que gobierna en una disputa es la de tu contrato y las notas
citadas en él.)*

**El precedente que hay que conocer, verificado**: *SAP UK Ltd v Diageo Great Britain Ltd*
**[2017] EWHC 189 (TCC)**, 16-feb-2017, Mrs Justice O'Farrell (TCC, caso HT-2015-000340). Diageo
construyó sobre Salesforce dos sistemas —*Gen2* (fuerza de ventas) y *Connect* (portal de clientes)—
que hablaban con mySAP ERP a través de **SAP PI**, que Diageo **ya pagaba por volumen de mensajes**.
El tribunal resolvió que esa interacción **constituía uso/acceso** al software: la definición
contractual de *Named User* cubría el acceso "directa o indirectamente (p. ej. vía Internet o
mediante un dispositivo o sistema de un tercero)", y los clientes de *Connect* **no encajaban en
ninguna categoría de usuario existente**. SAP prosperó por **más de 54,5 millones de libras** en
licencias y mantenimiento adicionales. Lecturas correctas, y son tres:
1. **Pagar el middleware no compra el derecho de acceso al ERP.** Son dos licencias distintas.
2. El fallo depende **de las cláusulas concretas de ese contrato**, se centró en uso **por personas**
   y no resolvió muchos escenarios automatizados: **no es una regla universal, es una advertencia**.
3. El modelo de *digital access* nació después, precisamente para sustituir la reclamación por
   usuarios por una métrica contable. **Que exista una métrica no elimina el riesgo: lo hace medible.**

**Criterio de arquitectura que se deriva, y es el más importante del documento**: **antes de diseñar
una integración que escriba en SAP, se estima el volumen anual de documentos por tipo y se valora
contra el precio de bloque.** Un rediseño que agrupe, deduplique o mueva la creación del documento
fuera del ERP es barato en la pizarra y carísimo después. Y la conversión al modelo documental **no
siempre sale a cuenta**: quedarse en usuarios nombrados puede ser más barato según el perfil. La
comparación se hace con números propios, no con la diapositiva del comercial. Si existe un programa
de adopción con crédito (DAAP) vigente, se valora — pero **verifica su vigencia y condiciones**, no
las supongas.

### 3.4 La auditoría anual: un evento planificable, no una sorpresa

Con contrato de soporte vigente, **la medición anual es una obligación contractual**, no una
iniciativa de SAP. Que la vivas como sorpresa es un fallo de proceso propio.

Secuencia obligatoria, y el orden importa:
1. **Calendario**: la declaración anual está en el calendario corporativo con dueño nombrado, igual
   que un cierre contable. Se prepara con semanas, no con el aviso.
2. **Medir en interno primero**: `USMM` en cada sistema productivo (clasificación de usuarios +
   medición de motores), consolidación con **LAW / `SLAW2`** para deduplicar el mismo humano en varios
   sistemas, y la estimación de *digital access* con la herramienta de SAP (`STAR` / nota vigente).
3. **Verificar la lista de precios que usa la medición**: si `USMM` mide contra una lista que no es la
   de tu contrato (ERP vs. S/4HANA vs. Private Cloud), el resultado no significa nada.
4. **Remediar antes de enviar**: reclasificar a la baja lo que el uso real no sostiene, cerrar cuentas
   muertas, y **corregir el rol** para que la reclasificación no se deshaga sola el mes siguiente.
5. **Enviar solo el resultado depurado.** Lo enviado es una declaración; lo no depurado se convierte
   en el punto de partida de la negociación **en tu contra**.
6. **Métricas grises**: hay motores que no se autodeclaran y exigen introducir un recuento a mano.
   Omitirlos no es prudencia, es una infradeclaración con tu firma.
7. **Ante una notificación de auditoría**: acusar recibo, **fijar el alcance contra el contrato**
   —qué sistemas, qué periodo, qué métricas—, medir en interno y solo después entregar. No se
   conceden accesos ni scripts fuera de alcance, y no se responde en caliente.

**Disparadores que adelantan una auditoría** (planifica en consecuencia): una renovación, una
conversión a S/4HANA, una fusión o adquisición, y **cualquier integración nueva grande**. Que el
proyecto de integración y la renovación caigan el mismo trimestre no es casualidad: es el patrón.

**Cifras de consultoras sobre "sobreconteo del 20-40 %" en la primera medición**: circulan mucho, las
publican empresas que venden defensa de auditoría y **no traen metodología ni muestra**. Úsalas como
motivo para medir tú, **nunca como cifra en un informe**.

### 3.5 Integración: no acoples el paisaje al ERP

Mecanismos disponibles y cuándo usarlos: **IDoc** (documento de negocio asíncrono, estándar y
auditable — sigue siendo la opción sensata en B2B y logística), **BAPI/RFC** (síncrono, acoplado; el
que más deuda genera), **OData** (exposición de servicio para consumo externo), **Event Mesh /
mensajería** (publicación de eventos, el único que desacopla de verdad). Criterio:

- **El ERP es un sistema de registro, no un bus.** Todo lo que se cuelgue de él en línea le hereda la
  ventana de mantenimiento y el reloj de §3.1. Prohibido por defecto: RFC síncrono punto a punto
  desde una aplicación de cara al cliente.
- **Cada integración declara su impacto en licencia** (§3.3) en el mismo documento de diseño, con
  volumen anual estimado por tipo de documento. Sin esa línea, el diseño no se aprueba.
- **Idempotencia y reproceso** en todo lo asíncrono: un IDoc reenviado no puede crear un segundo
  documento — es corrección funcional **y** ahorro de licencia.
- Cuenta técnica **por integración**, con permisos mínimos y trazable a un dueño. Una cuenta
  compartida por seis interfaces hace imposible atribuir consumo y responsabilidad.

### 3.6 Dato maestro: lo que decide si la conversión encalla

El dato maestro (material, cliente, proveedor, plan de cuentas, centro de coste) es donde mueren los
proyectos, y su síntoma llega tarde. Reglas:
- **Cada objeto maestro tiene un dueño de negocio nombrado antes de empezar**, no un "equipo de datos".
- **La limpieza se hace en el origen y antes del corte**, con reglas de calidad medidas y una fecha:
  "limpiaremos durante la migración" es cómo se pierde el plazo.
- **Business partner**: la unificación de cliente/proveedor en S/4HANA es requisito de conversión y es
  un proyecto de datos con su propio dueño, no un paso técnico.
- **Lo que no se migra se declara**: histórico que se queda en un archivo consultable, con su período
  de retención y su base legal (cruza con `privacy-engineering-standards`).

### 3.7 Entornos y transportes a nivel de programa

Aquí, **no** la mecánica del transporte (es de `abap-sap-standards`), sino el gobierno:
- Paisaje mínimo **DEV → QAS → PRD** con una vía única de promoción y **ningún cambio nacido en PRD**.
- **Congelación de transportes** declarada alrededor del corte y de cada cierre, con dueño que la
  levanta.
- **Convivencia**: durante una conversión hay dos paisajes vivos. Se define por escrito **dónde se
  hace el mantenimiento correctivo** y cómo se replica al otro. Sin esa regla, se pierde una
  corrección regulatoria en producción.
- **Datos de producción en entornos no productivos**: por defecto **no**, o anonimizados. Una copia de
  PRD en un sandbox es una brecha, y además **se mide** en la clasificación de usuarios.

## 4. Calidad y verificación

Coste creciente, y el orden es el que sostiene un programa:
1. **Inventario de interfaces y de Z** con dueño y uso real medido: lo que nadie usa no se migra.
   Es el mayor ahorro disponible y el que nadie hace.
2. **Regresión de proceso de negocio de extremo a extremo**, no de transacción: pedido→entrega→factura→
   cobro. Automatizada donde se pueda; el catálogo de casos lo firma negocio, no TI.
3. **Cuadre contable y de existencias contra el origen**, con tolerancia definida **antes** del corte.
   Es el criterio de aborto, y es de `migration-projects-standards`: no lo redefinas aquí.
4. **Prueba de carga con volumen real** en los procesos de cierre y de pico, no con el juego de datos.
5. **Ensayo del corte completo**, cronometrado, incluida la marcha atrás.
6. **Medición de licencia sobre el sistema convertido antes del arranque**: descubrir el desajuste en
   producción es descubrirlo tarde y sin margen de negociación.

## 5. Seguridad del stack

- **Segregación de funciones (SoD)** como requisito de diseño de roles, no como hallazgo de auditoría
  posterior. Los conflictos se detectan en la construcción del rol; su remediación tras el arranque
  cuesta órdenes de magnitud más.
- **El ERP no se expone a Internet.** El acceso externo va por una capa de integración con su propia
  autenticación y su propio control de tasa. Interfaz de usuario y servicios administrativos, jamás.
- **Cuentas estándar y contraseñas por defecto**: cambiadas y verificadas como parte del alta del
  sistema, en todos los mandantes, incluidos los que "no se usan".
- **Notas de seguridad**: cadencia mensual con dueño y SLA por criticidad. El triaje sigue
  `vulnerability-management-standards`; la aplicación técnica, `abap-sap-standards`.
- **Cifrado en tránsito** en todas las conexiones, también las internas RFC entre sistemas del
  paisaje. "Está en la red interna" no es un control (zero-trust, `networking-standards`).
- **Registro de acceso a datos personales y de auditoría** con retención definida y fuera del alcance
  de un administrador del propio sistema.
- **Riesgo específico de RISE/GROW**: el proveedor tiene acceso privilegiado a tu ERP. **Exige por
  escrito** el modelo de acceso de su personal, su registro y tu capacidad de auditarlo. Que sea SAP
  no lo convierte en un control.

## 6. Rendimiento y operabilidad

- **Cierre mensual y anual son el pico real** del sistema, no el día medio. Se dimensiona y se ensaya
  contra ese pico.
- **Interfaces con contrapresión y reintento con backoff**: un sistema externo que reintenta en bucle
  contra el ERP es, a la vez, una caída y una factura de *digital access*.
- **Observabilidad del proceso de negocio**, no solo de la infraestructura: pedidos atascados, IDocs
  en error, colas de salida. La métrica que importa es la del documento parado, no la CPU.
- **Ventanas de mantenimiento en cloud público: las fija el proveedor.** Si el negocio no puede
  aceptarlas, la nube pública está descartada — y eso se descubre **antes** de firmar, no después.
- **Salida (exit)**: cómo recuperas tus datos, en qué formato, en cuánto tiempo y a qué coste.
  Cláusula negociada antes de la firma; después no hay palanca.

## 7. Sostenibilidad y prohibiciones

- ❌ **PROHIBIDO llegar a 2028 sin una decisión escrita, fechada y aprobada** sobre las cuatro salidas
  de §3.1. La no-decisión es una decisión: es *customer-specific maintenance* al mismo precio y con
  menos alcance.
- ❌ **PROHIBIDO diseñar una integración que escriba en SAP sin estimar su consumo de documentos.**
  Es la causa número uno de facturas retroactivas del dominio.
- ❌ **PROHIBIDO enviar a SAP una medición sin haberla depurado en interno primero.**
- ❌ **PROHIBIDO** asumir que pagar un middleware (PI/PO, Integration Suite, un ESB de terceros)
  cubre el derecho de acceso al ERP. Ver Diageo, §3.3.
- ❌ **PROHIBIDO** dar de alta usuarios con tipo alto "por comodidad" o dejar cuentas de proyecto
  abiertas tras el fin del contrato del proveedor.
- ❌ **PROHIBIDO** el cambio nacido en producción y el mantenimiento correctivo sin doble vía durante
  la convivencia (§3.7).
- ❌ **PROHIBIDO** citar tasas de fracaso de proyectos ERP ("70 %", "75 %") sin metodología y muestra.
  Ver §3.1.
- ❌ **PROHIBIDO** copiar producción a un entorno no productivo sin anonimizar.
- ❌ **PROHIBIDO** firmar RISE/GROW sin desglose de precio por componente, sin RTO/RPO por escrito y
  sin cláusula de salida.
- ❌ **PROHIBIDO** planificar contando con una prórroga del calendario de SAP. Se movió una vez (2025
  → 2027, feb-2020) y eso **no** es un compromiso de que se vuelva a mover.
- ❌ **PROHIBIDO** tratar el soporte de terceros como decisión puramente económica: exige indemnidad
  por PI y un plan por si el proveedor pierde en juicio (§3.1).
- **Anti-patrón dominante del sector, y merece nombre propio**: **la personalización que impide
  actualizar.** Cada modificación del estándar es una hipoteca que se paga en cada upgrade, y el
  interés se cobra justo cuando hay prisa. La doctrina de **clean core** que lo evita es de
  `abap-sap-standards`; lo que corresponde aquí es la consecuencia de gobierno: **toda desviación del
  estándar se aprueba por un comité con dueño de negocio, se registra con motivo y fecha, y se revisa
  en cada upgrade con opción de retirarla.** Sin registro, en cinco años nadie sabe por qué existe y
  nadie se atreve a quitarla.
- **Cadencia**: revisión anual del inventario de Z e interfaces con uso medido, revisión anual de
  clasificación de usuarios, y revisión del contrato **seis meses antes** de la renovación — que es el
  único momento en que existe capacidad real de negociación.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en una decisión real:

1. **Calendario de mantenimiento**: fechas de Business Suite 7 por EhP, mantenimiento extendido y su
   recargo, *customer-specific maintenance*, fechas de fin por release de S/4HANA, y las condiciones
   del `SAP ERP, private edition, transition option`. Fuente: SAP (**hueco declarado**: en ago-2026
   `support.sap.com` y `sap.com` devolvieron **403** a la recuperación automatizada; las fechas de
   este documento se contrastaron con `news.sap.com` en verbatim para el *transition option* y con
   fuentes secundarias coincidentes para el resto. **Verifícalas contra las notas SAP citadas en tu
   contrato antes de usarlas**).
2. **Licenciamiento**: lista y ponderación de los tipos de documento de *digital access*, tipos de
   usuario nombrado vigentes y las reglas de clasificación. **SAP no publica precios ni descuentos:
   "no publicado" es el dato — el único precio que existe es el de tu contrato.** La lista de nueve
   tipos de §3.3 procede de consultoras coincidentes, no de SAP: **trátala como orientación, no como
   contrato**.
3. **Nombres de producto**: cambian y se reutilizan (Cloud ERP Private, Cloud ERP, "Business Suite").
   Verifica el nombre exacto vigente antes de escribirlo en un documento contractual.
4. **Compatibility packs**: fechas vigentes de derecho de uso on-premise y bajo RISE (nota 2269324).
5. **Precedentes**: *SAP UK Ltd v Diageo GB Ltd* [2017] EWHC 189 (TCC) —el texto íntegro está en
   BAILII, que en ago-2026 devolvió **403** a la recuperación automatizada; los datos de §3.3 vienen
   de fuentes secundarias coincidentes sobre esa sentencia—; y el estado actual de Oracle v. Rimini
   Street tras la devolución del Noveno Circuito de dic-2024, **que sigue vivo**.
6. **Programas comerciales** (DAAP y equivalentes): existencia, vigencia y condiciones.
7. **CVEs y notas de seguridad** del release concreto, y estado de soporte de la base de datos y del
   sistema operativo subyacentes, que tienen su propio calendario.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
