---
name: enterprise-architecture-standards
description: The application landscape of an organization, not the design of one system. Use when building or repairing an application inventory (owner, criticality, cost, lifecycle, dependencies), running application portfolio rationalization with the Gartner TIME model (tolerate, invest, migrate, eliminate), choosing a modernization strategy from the R taxonomy (rehost, relocate, replatform, repurchase, refactor/re-architect, retire, retain), adopting or refusing TOGAF (Standard 10th Edition, ADM) and ArchiMate 3.2 and checking whether its licence lets you publish the notation, evaluating Archi, Structurizr, SAP LeanIX, Ardoq or Bizzdesign as an EA repository, building a business capability map as a stable mapping axis, setting a technology standard and the exception process with a mandatory expiry date, publishing a technology radar (Build Your Own Radar, adopt/trial/assess/caution rings), deciding build versus buy versus SaaS with exit cost and vendor lock-in, governing the integration landscape (point-to-point versus bus versus event-driven), designing an architecture review body that does not become a change advisory board, reconciling the application inventory with the ITSM CMDB and the service catalogue, or defining metrics for the EA function that are not a document count.
---

# Estándares de arquitectura empresarial

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**La arquitectura empresarial existe para que las decisiones de sistemas se tomen con el paisaje
completo delante.** Su producto no es un diagrama: es que quien decide comprar, construir, migrar o
apagar sepa qué hay ya, quién lo paga, de qué depende y qué se rompe. **Su fallo típico —y el modo
de fallo por defecto de la función— es producir documentación que nadie usa**: modelos correctos,
completos, actualizados una vez y consultados nunca.

Regla de existencia, aplicable el lunes: **un artefacto de EA que no ha cambiado ninguna decisión
en los últimos 90 días se retira o se le asigna la decisión que debía informar.** Sin excepción
para "es documentación de referencia".

Cubre: el inventario de aplicaciones y su degradación, la decisión de ciclo de vida por aplicación
(TIME), las "R" de modernización, marcos (TOGAF, ArchiMate y alternativas ligeras), mapa de
capacidades de negocio, estándares tecnológicos y su proceso de excepción, radar tecnológico,
build/buy/SaaS, el paisaje de integraciones como deuda invisible, gobierno de arquitectura y sus
cuellos de botella, la bajada a decisiones de equipo y las métricas de la función.

**No aplica**:
- `software-architecture-patterns-standards` (**frontera crítica**): **suyo** el diseño interno de
  **un** sistema —estilo, límites de módulo, regla de dependencia, CQRS, ADR, C4—; **aquí** el
  paisaje de la organización, el inventario, los estándares transversales y su gobierno. Arbitraje:
  **si la pregunta es cómo se estructura este sistema, es suya; si es qué sistemas tenemos, cuáles
  sobran y cuál es el estándar, es de aquí.**
- `itsm-itil-standards` (**frontera fina, escrita con precisión**): **suyos** la CMDB, los elementos
  de configuración y el catálogo de servicios. **La CMDB inventaría elementos de configuración para
  operar** (qué se ve afectado por este cambio, qué CI falló); **el inventario de aplicaciones
  inventaría capacidades para decidir** (qué aporta esto al negocio, qué cuesta, se mantiene o se
  apaga). Distinta granularidad, distinta cadencia y distinto dueño. **Regla: una aplicación del
  inventario referencia sus CI, no los duplica** (§3.2); si acaban divergiendo, la CMDB manda sobre
  el estado operativo y el inventario sobre la decisión de cartera.
- `platform-engineering-standards` (la plataforma interna como producto y su camino pavimentado;
  **aquí el estándar que la plataforma implementa, no su implementación**).
- `lowcode-governance-standards` (**suyos el catálogo de herramientas personales y su gobierno** —
  entornos, DLP de conectores, identidad del flujo, flujos huérfanos—; **la app low-code que pasa a
  ser crítica entra en el inventario de aplicaciones de aquí**, con dueño, coste y ciclo de vida).
- `tech-leadership-standards` (la decisión de invertir, la negociación y el registro organizativo;
  aquí el criterio técnico de cartera que la alimenta).
- `project-management-standards` (cómo se entrega el programa de migración; aquí qué se migra y por
  qué).
- `finops-standards` (**recíproca dura**: el coste por aplicación se calcula con su método —
  etiquetado, asignación de compartidos, unidad económica— y **entra aquí como entrada obligatoria
  de la decisión de ciclo de vida**; §3.1).
- `grc-compliance-standards` (marco de control, auditoría y evidencia; aquí el atributo de
  cumplimiento como campo del inventario, no el programa).
- `microservices-architecture-standards` (topología distribuida de un sistema y su comunicación).
- `data-governance-quality-standards` (**suyos** la propiedad del dato, el catálogo de datos, el
  glosario y los contratos de datos; **aquí la aplicación como sistema origen, no el dato**).
- `iac-standards` (cómo se declara y despliega la infraestructura).
- `bcdr-standards` (**recíproca**: la criticidad y el RTO/RPO por aplicación se derivan de su BIA y
  **se guardan como campo del inventario**; aquí no se recalculan).
- `knowledge-management-standards` (dónde vive y cómo se mantiene lo que aquí se escribe) y
  `product-discovery-standards` (qué se construye y para quién). **El paisaje decide qué sistemas
  existen; el descubrimiento, qué se construye; la documentación es lo que queda escrito de ambas
  decisiones.**
- **Skills de plataforma heredada** (**Ola 7**): `mainframe-zos-cobol-standards`,
  `ibm-i-rpg-standards`, `mumps-standards`, `dotnet-framework-legacy-standards`,
  `aix-solaris-hpux-standards` y las demás del bloque legacy. **Aquí se decide qué se hace con una
  aplicación** —el modelo TIME, la "R" de modernización elegida, el coste y el dueño—; **allí, qué
  implica técnicamente esa decisión en esa plataforma concreta** y si es siquiera viable. La regla
  que evita el error caro: **una "R" se elige con el criterio técnico de la plataforma delante, no
  sobre una hoja de cálculo** — hay plataformas donde la reescritura automática produce código que
  nadie puede mantener y otras donde congelar y encapsular es la respuesta correcta.
  `legacy-modernization-standards` es el paraguas que enruta entre ellas.

## 2. Decisiones por defecto

> Verificar la última versión/estado/licencia por web antes de fijarlo en un proyecto real (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Artefacto raíz | **Inventario de aplicaciones** con los 8 campos obligatorios de §3.1 | Ninguna: sin inventario no hay función de EA |
| Marco | **Ninguno completo.** Tomar de TOGAF solo el ADM como guion de fases y las vistas que se usen | TOGAF Standard 10th Edition completo solo con obligación contractual/regulatoria o certificación exigida |
| Notación | **C4** para sistemas (→ `software-architecture-patterns-standards`) y **cajas nombradas con leyenda** para el paisaje | **ArchiMate 3.2** si ya hay repositorio y modeladores formados — **revisar licencia antes de publicar** (§2.2) |
| Herramienta de modelado | **Archi** (MIT) sobre repositorio git | Estructura en la herramienta de EA si ya se paga una |
| Repositorio de cartera | **Hoja/tabla versionada o base ligera con dueño y CI** hasta ~150 aplicaciones | SAP LeanIX / Ardoq / Bizzdesign por encima, con precio por número de aplicaciones (§2.3) |
| Decisión de ciclo de vida | **TIME** (tolerar, invertir, migrar, eliminar), revisada con cadencia fija | Cualquier taxonomía de 4 cuadrantes propia, **si está escrita y sus ejes definidos** |
| Modernización | **Retire y retain primero**; las demás R solo tras descartar apagar | — |
| Eje de mapeo | **Mapa de capacidades de negocio** (estable) | Nunca el organigrama como eje primario (§3.3) |
| Estándares | **Radar tecnológico** publicado, con 4 anillos y fecha | Lista de "tecnologías aprobadas" solo si tiene proceso de excepción (§4.2) |
| Excepciones | **Con fecha de caducidad obligatoria** (§4.2) | Ninguna |
| Gobierno | **Consejo asesor con revisión por umbral** (§6.1) | Comité que aprueba todo: **PROHIBIDO** (§7) |

### 2.1 TOGAF: qué se toma y qué se tira

- **Versión vigente: TOGAF Standard, 10th Edition** (The Open Group, anuncio de lanzamiento de abril
  de 2022; el bundle documental C220 incorpora una corrección técnica de 2025). No hay 11.ª edición
  a ago-2026 — **verificar en `opengroup.org/togaf`** (§8). TOGAF® es marca registrada de The Open
  Group: su uso en materiales y la certificación tienen condiciones propias.
- **Sé honesto: la mayoría de organizaciones no necesita TOGAF completo.** Lo aprovechable sin
  adoptarlo entero: el **ADM** como guion de fases (visión → negocio → sistemas de información →
  tecnología → oportunidades → migración → gobierno → gestión del cambio), el concepto de
  **arquitectura objetivo vs. de partida con análisis de brecha**, y el **repositorio de
  arquitectura**. Lo que se tira por defecto: el metamodelo completo, el catálogo exhaustivo de
  entregables y la cadena de contratos de arquitectura.
- **Criterio de adopción completa**: solo si (a) un contrato, un regulador o un cliente lo exige por
  nombre, o (b) hay ≥3 arquitectos a dedicación completa. Por debajo, adoptar TOGAF entero produce
  exactamente el fallo de §1.

### 2.2 ArchiMate y su licencia — decide si puedes publicar la notación

- **ArchiMate 3.2 Specification**, The Open Group, documento **C226**, publicada en octubre de 2022.
  ArchiMate® es marca registrada de The Open Group.
- **Licencia — el punto que decide**: la especificación **no es de libre redistribución**. The Open
  Group la publica bajo un modelo escalonado: **licencia de evaluación gratuita de 90 días** (uso
  interno, conservando avisos de copyright y marca) y, al expirar, hay que **solicitar licencia no
  comercial o comercial** o retirar el documento. **Todo uso comercial está sujeto a la licencia
  comercial anual.** **Regla operativa: modelar en ArchiMate para consumo interno es una vía
  practicable; incrustar la especificación, sus tarjetas de referencia o material derivado en
  documentación pública, formación de pago o entregables de consultoría exige comprobar la licencia
  comercial antes.** Verificar en `opengroup.org/legal/licensing` (§8) —**es una decisión legal, no
  técnica**.
- La especificación separa **conceptos del lenguaje** de la **notación**: la notación gráfica que
  publica es *una* notación por defecto, no la única válida. Corolario práctico: **si el problema es
  que nadie entiende los diagramas, cambiar la notación es legítimo y no rompe el modelo.**
- **Archi** (`archimatetool.com`) es el editor por defecto: **licencia MIT** verificada en crudo —
  `The MIT License (MIT) / Copyright (c) 2013-2026 Phillip Beauvoir, Jean-Baptiste Sarrodie, The
  Open Group`. **La herramienta MIT no licencia la especificación**: son dos cosas distintas y la
  segunda no se hereda de la primera.

### 2.3 Herramientas de cartera

- **SAP LeanIX**, **Ardoq** y **Bizzdesign**: **ninguna publica precio de lista**; LeanIX y Ardoq
  licencian **por número de aplicaciones** (usuarios ilimitados en el modelo de LeanIX). Consecuencia
  de compra: **conocer el número real de aplicaciones antes de pedir oferta**, porque es la variable
  que fija el precio y la única que hace comparables las ofertas. Precio → **hueco en §8**.
- **No se compra herramienta de EA para crear el inventario.** Se compra cuando el inventario ya
  existe, se mantiene y el cuello de botella es el volumen o la integración con CMDB/facturación.
  Comprarla antes reproduce el fallo de §1 con licencia anual.

## 3. Estructura y convenciones

### 3.1 El inventario de aplicaciones — el único artefacto que justifica la función

Campos **obligatorios**; una fila sin ellos no está en el inventario, está en una lista:

| Campo | Regla |
|---|---|
| Nombre y alias | Un nombre canónico; los alias se registran, no se discuten |
| **Dueño de negocio** (persona, no equipo) | Si nadie acepta ser dueño, la aplicación es candidata a `eliminate` por definición |
| Responsable técnico | Equipo con guardia o proveedor con contrato |
| **Criticidad y RTO/RPO** | Derivados del BIA → `bcdr-standards`; aquí solo se referencian |
| **Coste anual total** | Licencia + infraestructura + soporte + esfuerzo interno estimado → método de `finops-standards` |
| **Estado de ciclo de vida** | `invest` / `tolerate` / `migrate` / `eliminate` + fecha de la última revisión |
| Fecha de fin de soporte | Del proveedor o de la versión; vacío ≠ "no caduca" |
| Capacidades de negocio que soporta | Enlace al mapa (§3.3), 1..n |
| **Dependencias** | Aplicaciones e integraciones de las que depende y que dependen de ella (§5.1) |
| Datos que trata | Clasificación y si hay datos personales → `privacy-engineering-standards`, `data-governance-quality-standards` |
| Referencia al CI | Identificador en la CMDB; **referencia, no copia** |

**Por qué se degrada, y qué se hace contra cada causa** —esto es el trabajo real de la función:

1. **Se crea como proyecto y no como proceso.** Contra: el inventario tiene dueño con nombre y una
   revisión con fecha en el calendario, no un hito de proyecto.
2. **No está en el camino de nadie.** Un dato que solo sirve para el informe anual se pudre. Contra:
   **atarlo a un evento que ya ocurre** — alta de aplicación en el alta de proyecto, coste desde la
   facturación real, dependencias desde el descubrimiento de red/CMDB, fin de soporte desde el
   inventario de vulnerabilidades.
3. **Campos opinables sin definición.** "Criticidad alta" sin criterio produce el 60 % de las
   aplicaciones en alta. Contra: cada campo con valores cerrados y regla de asignación escrita.
4. **Captura manual de lo que ya está en otro sistema.** Contra: **generar desde la fuente y
   reconciliar**, nunca teclear dos veces (mismo principio que §4 de `knowledge-management-standards`).
5. **Nadie ve la consecuencia de mentir.** Contra: **si el coste sale del inventario, el presupuesto
   sale del inventario**; el dato que decide dinero se corrige solo.

**Métrica de salud del inventario (falsable)**: porcentaje de aplicaciones con dueño vivo y revisión
en los últimos 12 meses, y **desviación entre el coste del inventario y la factura real**. Si la
desviación supera el 10 %, el inventario no es utilizable para decidir cartera.

### 3.2 Frontera con la CMDB, sin ambigüedad

| | Inventario de aplicaciones | CMDB (`itsm-itil-standards`) |
|---|---|---|
| Pregunta que responde | ¿Esto merece existir el año que viene? | ¿Qué se ve afectado por este cambio o incidente? |
| Unidad | Aplicación / capacidad | Elemento de configuración |
| Cadencia | Revisión trimestral/anual | Continua, ligada al cambio |
| Dueño | Arquitectura + dueño de negocio | Gestión de servicio |
| Fuente de verdad en conflicto | Decisión de cartera, coste, dueño de negocio | Estado operativo, relaciones de despliegue |

**PROHIBIDO** mantener dos grafos de dependencia independientes: uno referencia al otro.

### 3.3 Capacidades de negocio como eje estable

- Se mapea contra **lo que la organización hace** (capacidades: "facturar", "originar préstamo",
  "gestionar devoluciones"), **no contra quién lo hace**. El organigrama cambia cada reorganización;
  la capacidad no. Un inventario indexado por departamento queda inservible en la siguiente
  reorganización — y eso ocurre antes que la próxima revisión de cartera.
- **Dos niveles bastan** para decidir cartera; tres solo si un nivel entero se va a externalizar o
  comprar. Un mapa con cuatro niveles y 300 hojas es un proyecto de modelado, no una herramienta.
- Uso real: colorear el mapa por **coste**, por **criticidad** y por **duplicidad** (nº de
  aplicaciones que soportan la misma capacidad). **La duplicidad en una capacidad no diferenciadora
  es el hallazgo que paga la función.**

### 3.4 Decisión de ciclo de vida: TIME

- **TIME (Tolerate, Invest, Migrate, Eliminate)** se atribuye consistentemente a **Gartner** como
  marco de racionalización de cartera de aplicaciones. **Discrepancia declarada**: no he podido
  localizar la nota de investigación primaria (identificador y año) en fuentes abiertas —las
  disponibles son secundarias, en su mayoría de fabricantes de herramientas EA—, **y sus ejes no
  coinciden entre fuentes**: unas cruzan *ajuste técnico × ajuste funcional* y otras *valor de
  negocio × ajuste técnico*. **Consecuencia operativa: si se usa TIME, se escribe en el documento
  propio qué dos ejes se usan y cómo se puntúan**; citarlo sin fijar ejes garantiza que dos personas
  clasifiquen distinto la misma aplicación. Verificar la fuente primaria antes de atribuirla en un
  documento formal (§8).
- Reglas duras que hacen la clasificación falsable:
  - `tolerate` **lleva fecha de re-revisión obligatoria**; sin ella es abandono con nombre bonito.
  - `invest` exige una capacidad diferenciadora identificada (§5.2) y presupuesto asignado.
  - `eliminate` exige **fecha de apagado, plan de datos y consumidores notificados**; una aplicación
    "eliminada" que sigue encendida sigue costando.
  - **Ninguna aplicación se queda sin clasificar**: sin clasificación explícita, el estado por
    defecto es `tolerate` con revisión a 12 meses, y así se declara.

### 3.5 Las "R" de modernización

Taxonomía de trabajo (nombres de AWS, de uso mayoritario): **rehost, relocate, replatform,
repurchase, refactor/re-architect, retire, retain**.

- **Origen, con la cadena de atribución declarada**: las fuentes secundarias sitúan el origen en
  **Gartner (2011, Richard Watson)** con **cinco** estrategias —*rehost, refactor, revise, rebuild,
  replace*—, ampliadas y renombradas después por AWS a 6 y luego a 7 R. **Divergencia detectada en
  las fuentes**: varias páginas atribuyen a Gartner la nomenclatura de AWS (*replatform*,
  *repurchase*, *retire*), que no es la lista original. **Regla: al citar la taxonomía, decir de qué
  lista se habla (Gartner 5 o AWS 7) o no citarla.** No he podido confirmar la lista de AWS
  verbatim contra su documentación oficial en esta pasada (dos intentos de recuperación fallidos);
  **verificar en la guía prescriptiva de AWS antes de usarla en un documento formal** (§8).
- **Orden de evaluación obligatorio, y esto sí es criterio**: `retire` → `retain` → `repurchase` →
  `rehost`/`relocate` → `replatform` → `refactor`. **Se evalúa apagar antes que mover, y comprar
  antes que reescribir.** Reescribir es la opción más cara y la que más a menudo se elige primero.
- `rehost` a la nube **sin plan de replatform posterior con fecha** traslada la deuda y añade
  factura: se acepta solo con motivo de plazo (cierre de CPD, fin de soporte de hardware) escrito.
- **Ninguna R se aplica a la cartera entera**: se decide por aplicación, con el coste de §3.1
  delante.

## 4. Estándares, excepciones y radar

*(Sección 4 de la plantilla —calidad y testing— sustituida: en una función de criterio, el control
de calidad equivalente es el gobierno del estándar y su verificación.)*

### 4.1 Cómo se fija un estándar tecnológico

Un estándar sin estas cinco piezas no es un estándar, es una preferencia:

1. **Ámbito**: a qué se aplica y a qué explícitamente no.
2. **Motivo**: qué problema evita (soporte, seguridad, contratación, coste), en una frase falsable.
3. **Dueño**: persona que lo mantiene y a quien se le pide la excepción.
4. **Fecha y revisión**: fecha de entrada en vigor y de próxima revisión. Un estándar sin revisión
   se convierte en el motivo por el que la gente lo esquiva.
5. **Aplicación a lo existente**: si solo aplica a lo nuevo, se dice. Migración retroactiva sin
   presupuesto es una excepción masiva no declarada.

### 4.2 El proceso de excepción — **una excepción sin fecha es un estándar nuevo**

- **Toda excepción lleva: motivo, alcance, dueño, condición de salida y fecha de caducidad.**
  **PROHIBIDA la excepción indefinida.**
- **Caducidad máxima recomendada: 12 meses.** Al vencer solo hay dos salidas: se cumple el estándar
  o **se cambia el estándar** (porque tres excepciones sobre la misma regla significan que la regla
  está mal, no que la gente sea indisciplinada).
- El registro de excepciones es público internamente y se revisa en la misma sesión que el radar.
  **Métrica**: nº de excepciones vencidas sin resolver. Si crece dos trimestres seguidos, el
  problema es el estándar.

### 4.3 Radar tecnológico como artefacto

- Formato de referencia: el **Technology Radar de Thoughtworks**, publicado **dos veces al año**,
  con cuatro cuadrantes (**Techniques, Platforms, Tools, Languages and Frameworks**) y cuatro
  anillos. **Corrección verificada: el anillo externo ya no se llama "Hold", sino "Caution"**
  (adopt / trial / assess / **caution**) — si tu plantilla o tus datos dicen `Hold`, están
  desactualizados.
- Herramienta: **Build Your Own Radar** de Thoughtworks, **AGPL-3.0** (copyright 2015 Bruno
  Trecenti; 2016 Thoughtworks). **Consecuencia de la AGPL: si se despliega modificado y se sirve por
  red, las obligaciones de la licencia aplican** → contrastar con `opensource-licensing-standards`
  antes de forkearlo.
- Reglas propias del radar interno: cada blip lleva **fecha y una frase de por qué**; un blip en
  `caution` **nombra el sustituto**; y el radar se publica **con las mismas fechas que la revisión
  de excepciones**, porque son la misma conversación.

## 5. Integración, y build/buy/SaaS

### 5.1 El paisaje de integraciones es la deuda invisible

- **Lo que impide apagar una aplicación casi nunca es la aplicación: son sus integraciones.** Por
  eso la columna de dependencias de §3.1 es obligatoria y no opcional.
- **Cada integración tiene dueño, contrato y consumidores conocidos.** Una integración sin
  consumidores identificables es la primera candidata a retirar, y su retirada es la forma más
  barata de reducir el paisaje.
- Elección de topología (**la implementación se delega**):
  - **Punto a punto**: por defecto por debajo de ~10 integraciones. Coste real = n·(n−1)/2 en el
    peor caso; se abandona cuando ese número deja de caber en una pizarra.
  - **Bus / integración centralizada**: cuando el problema es la mediación y el enrutado, no el
    volumen. **Riesgo declarado: lógica de negocio dentro del bus** — se prohíbe por escrito o el
    bus se convierte en el sistema más crítico y menos testeable de la casa.
  - **Eventos**: cuando el productor no debe conocer a los consumidores y la consistencia eventual
    es aceptable para el negocio. Implementación → `message-brokers-standards`,
    `microservices-architecture-standards`, `streaming-cdc-standards`.
- **Contrato antes que tecnología**: quién publica, qué esquema, qué compatibilidad y qué SLA →
  `api-design-standards`, `data-governance-quality-standards`.

### 5.2 Build vs. buy vs. SaaS

Se decide con cuatro preguntas, en este orden. La primera es eliminatoria:

1. **¿Es una capacidad diferenciadora?** ¿Un cliente elegiría a la organización por cómo hace esto?
   Si no, **no se construye**. Construir un ERP, un CRM o un sistema de nóminas propios es la forma
   más cara conocida de no diferenciarse.
2. **Coste total a 5 años**, no precio de licencia: licencia + integración + operación + soporte +
   personas + **coste de la versión que habrá que migrar**. El coste de construir incluye
   mantenerlo los 5 años; casi ningún caso de negocio de "build" lo incluye, y por eso casi todos
   ganan en la hoja de cálculo y pierden en la realidad.
3. **Dependencia del proveedor**: ¿el dato es exportable en formato utilizable?, ¿hay API?, ¿el
   contrato permite auditar?, ¿qué pasa si sube el precio un 40 %? → due diligence de proveedor en
   `grc-compliance-standards` y `bcdr-standards`.
4. **Salida**: **antes de firmar se escribe el plan de salida** (formato de exportación, propiedad
   del dato, plazo de devolución, coste estimado de migrar). Sin plan de salida escrito, el SaaS es
   una decisión *one-way* disfrazada de suscripción mensual.

**Regla adicional**: personalizar un producto comprado por encima de su punto de configuración
soportado convierte una compra en una construcción, con el peor perfil de coste de ambas. Si hace
falta, la respuesta correcta suele ser cambiar el proceso de negocio o cambiar de producto.

## 6. Gobierno, bajada a la entrega y métricas

### 6.1 Quién decide qué

| Tipo de decisión | Decide | Arquitectura aporta |
|---|---|---|
| Diseño interno de un sistema | El equipo | Estándar aplicable y revisión a petición |
| Adopción de tecnología fuera del radar | Equipo + dueño del estándar | Excepción con caducidad (§4.2) |
| Nueva aplicación en la cartera / compra | Dueño de negocio + arquitectura | Duplicidad, coste total, encaje en capacidades |
| Apagado de una aplicación | Dueño de negocio | Dependencias y consumidores afectados |
| Cambio de un estándar transversal | Consejo de arquitectura | Propuesta y consecuencias |

- **Umbral, no revisión universal**: se revisa lo *one-way* (gasto irreversible, dato personal,
  dependencia de proveedor a largo plazo, cambio que afecta a más de un equipo). **Todo lo demás se
  decide en el equipo y se comunica.**
- **Por qué un comité que revisa todo se convierte en cuello de botella —con la evidencia
  disponible—**: el hallazgo de DORA/*Accelerate* sobre aprobación por un cuerpo externo (CAB o
  directivo) es que **las aprobaciones externas correlacionan negativamente con lead time,
  frecuencia de despliegue y tiempo de restauración, y no correlacionan con la tasa de fallo del
  cambio**; DORA declara no haber encontrado evidencia de que el proceso formal externo reduzca los
  fallos. **La cifra "2,6× más probable ser low performer" circula atribuida al informe de 2019: no
  la uso, porque no he podido verificarla contra la fuente primaria a la que se le atribuye.** El
  argumento cualitativo se sostiene sin ella. Alternativa recomendada por DORA: **revisión por pares
  durante el desarrollo + automatización de controles** → `code-review-standards`, `cicd-standards`.
- Corolario: **un consejo de arquitectura que aprueba diseños es un CAB con otro nombre.** Su
  trabajo es fijar estándares, resolver excepciones y arbitrar conflictos entre equipos; **no
  aprobar el trabajo de nadie**.

### 6.2 La bajada a la entrega — **la arquitectura que no baja a decisiones concretas no existe**

- Todo estándar se materializa en algo ejecutable o no cuenta: una plantilla en el camino pavimentado
  (`platform-engineering-standards`), un módulo de IaC, una política de admisión, un gate de CI, un
  *fitness function* (`software-architecture-patterns-standards`). **El PDF no es un mecanismo de
  cumplimiento.**
- **El arquitecto acompaña al primer equipo que aplica un estándar nuevo.** Si nadie de arquitectura
  ha usado el estándar que escribió, el estándar no está probado.
- Enlace obligatorio con el ADR: la decisión de un equipo que se aparta de un estándar **se escribe
  como ADR y como excepción con caducidad** (mismo hecho, dos registros con dueños distintos).

### 6.3 Métricas de la función (ninguna cuenta documentos)

| Métrica | Qué diagnostica | Señal de alarma |
|---|---|---|
| % de aplicaciones con dueño vivo y revisión < 12 meses | Salud del inventario | < 80 % |
| Desviación coste inventario vs. factura | Utilidad del inventario para decidir | > 10 % |
| Nº de aplicaciones apagadas por período | Que la función también resta | 0 en un año |
| Duplicidad por capacidad no diferenciadora | Solape de cartera | Crece |
| Excepciones vencidas sin resolver | Estándar desalineado con la realidad | Crece 2 trimestres |
| Antigüedad mediana del artefacto consultado | Documentación viva vs. muerta | Nadie consulta nada |
| Tiempo de respuesta a una consulta de arquitectura | Si la función es un servicio o una aduana | Días |

## 7. Sostenibilidad a largo plazo y prohibiciones

- Cadencia mínima: **revisión de cartera trimestral** (estado TIME, altas y bajas), **radar y
  excepciones semestrales**, **mapa de capacidades anual o al cambiar el modelo de negocio** (no al
  reorganizarse).
- **Deprecación de estándares**: un estándar retirado se marca como retirado con fecha; no se borra,
  porque hay sistemas construidos contra él.
- Prohibiciones:
  - ❌ **Diagrama sin dueño ni fecha.** Un diagrama sin ambas cosas es folclore; se borra o se adopta.
  - ❌ **Estándar sin proceso de excepción.** Produce incumplimiento silencioso, que es peor que la
    excepción registrada porque no se mide.
  - ❌ **Excepción sin fecha de caducidad** (§4.2).
  - ❌ **Inventario que nadie actualiza**: si no está atado a un evento que ya ocurre (§3.1), no se
    empieza.
  - ❌ **Elegir marco antes que problema.** "Vamos a implantar TOGAF" no es un objetivo; "sabemos qué
    aplicaciones duplican la capacidad de facturación y cuánto cuestan" sí.
  - ❌ **Torre de marfil**: arquitecto que produce el objetivo y no acompaña ninguna implantación.
  - ❌ **Consejo de arquitectura que aprueba todos los diseños** (§6.1).
  - ❌ **Dos fuentes de verdad** para dependencias o para el coste (§3.2).
  - ❌ **Reescribir sin haber evaluado retire y repurchase**, y **rehost sin fecha del replatform**.
  - ❌ **Firmar SaaS sin plan de salida escrito**.
  - ❌ **Citar cifras de marco o de tasa de fracaso sin fuente primaria** en un documento de
    arquitectura: es la forma más rápida de perder credibilidad ante quien decide el dinero.
  - ❌ **Publicar notación o material derivado de ArchiMate fuera de la organización sin comprobar la
    licencia aplicable** (§2.2).

## 8. Verificación web obligatoria

Comprobar antes de fijar nada:

1. **TOGAF**: edición vigente y correcciones en `opengroup.org/togaf`; propiedad y condiciones de
   marca. Aquí: 10th Edition (2022), corrigendum 2025 en el bundle C220.
2. **ArchiMate**: versión vigente (3.2, C226, oct-2022) y **licencia aplicable a tu uso concreto**
   en `opengroup.org/legal/licensing` — evaluación 90 días / no comercial / comercial anual.
   **Decisión legal: consultar antes de publicar.**
3. **TIME**: **hueco declarado** — no localizada la nota primaria de Gartner (identificador y año) ni
   una definición de ejes consistente entre fuentes. Si se necesita atribución formal, se consulta
   la biblioteca de Gartner bajo suscripción. **No inventar la cita.**
4. **Las "R"**: confirmar la lista vigente de AWS *verbatim* en su guía prescriptiva y, si se
   atribuye a Gartner, usar la lista original de 2011 (rehost, refactor, revise, rebuild, replace).
   **No confirmado verbatim en esta pasada.**
5. **Herramientas**: estado, licencia y **precio** de LeanIX / Ardoq / Bizzdesign — **hueco: ninguna
   publica precio**; modelo por número de aplicaciones en LeanIX y Ardoq, a confirmar en oferta.
   Licencia de Archi verificada en crudo (MIT, `License.txt` del repositorio).
6. **Build Your Own Radar**: licencia **AGPL-3.0** y anillos vigentes (`caution`, no `hold`),
   confirmados a ago-2026; re-verificar antes de forkear.
7. **Evidencia sobre aprobación externa**: leer el informe DORA/*Accelerate* citado en su fuente
   primaria antes de reproducir cualquier cifra. **La cifra 2,6× queda descartada por no verificable
   contra la fuente a la que se atribuye.**
8. Cifras de "porcentaje de organizaciones que adopta X marco" y "tasa de fracaso de programas de
   transformación": **descartadas por defecto**; solo se usan con estudio primario y metodología
   accesible.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
