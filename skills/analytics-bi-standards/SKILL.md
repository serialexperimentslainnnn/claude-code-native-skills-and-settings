---
name: analytics-bi-standards
description: Use when data reaches a human for a decision — deciding whether a dashboard changes any decision at all and retiring dead ones, choosing or operating a BI tool (Power BI and Fabric F-SKU capacity versus Pro/PPU per-user licensing, Tableau Creator/Explorer/Viewer seats, Looker platform fee and LookML, Metabase, Apache Superset, Lightdash, Evidence, Preset), .pbix/.pbip/.twb/.twbx/.lkml/model.lkml/explore.lkml files, dashboard and report design driven by audience and decision, self-service tiers and certified versus exploratory content, extracts and imports versus direct/live query, pre-aggregates, caching and refresh schedules as a cost pattern, report certification, per-report ownership and periodic pruning, row-level and column-level security and whether to enforce it in the warehouse or in the tool, spreadsheet export as a governance leak, scheduled report delivery, data alerts, embedded analytics, and showing data freshness or staleness inside the report itself.
---

# Estándares de analítica y BI

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a la **capa de consumo**: informes, cuadros de mando, autoservicio, distribución y
analítica empotrada. Todo lo que ocurre entre el almacén y la persona que decide.

Disparadores: `.pbix`, `.pbit`, `.pbip`, `.twb`, `.twbx`, `.tds`, `.hyper`, `.lkml`,
`model.lkml`, `explore.lkml`, `view.lkml`, `manifest.lkml`, `dashboards/*.yml` de Lightdash,
`pages/*.md` con bloques SQL de Evidence, `superset_config.py`, `metabase.db`, "dashboard",
"cuadro de mando", "informe", "KPI", "drill-down", "extracto", "actualización programada",
"suscripción", "alerta de datos", "embedded analytics", "RLS", "seguridad a nivel de fila",
"exportar a Excel", y las frases que delatan un problema de esta capa: **"los dos informes dan
números distintos"**, "el informe tarda dos minutos en abrir", "esto lo mira alguien todavía?",
"necesito que se refresque cada 5 minutos", "¿por qué falta el día de ayer?".

**No aplica**: ver
- `data-warehouse-modeling-standards` (**dueña de la definición de métrica**): **la definición
  canónica de una métrica y la capa semántica son suyas**, viven en el repositorio junto al modelo,
  versionadas y con propietario. **Esta skill las consume; no las define, no las redefine y no las
  duplica.** Grano, dimensiones, SCD y qué desgloses son legales, también suyos. Si la pregunta es
  "¿cómo se calcula ingreso neto?" o "¿por qué al sumar sale el doble?", es suya.
- `dataviz` (**skill sin sufijo `-standards`; el diseño visual del gráfico es suyo, sin excepción**):
  elección del tipo de marca, paleta y color por serie, ejes, escalas, leyendas, *tooltips*,
  paletas secuenciales y divergentes, fichas de estadística, *sparklines*, mapas de calor y
  accesibilidad del gráfico. **Léela antes de escribir la primera línea de código de un gráfico.**
  Aquí se decide **si el cuadro de mando debe existir, para quién, con qué dato y quién responde
  por él**; allí, **cómo se dibuja**. No dupliques ni una regla de color.
- `data-governance-quality-standards` (**hermana; frontera declarada en ambos lados**): **el
  gobierno decide si el dato es confiable y de quién es; el BI lo presenta para decidir.** Dueño
  del conjunto de datos, contrato, SLA de frescura, clasificación, catálogo, glosario e incidente
  de dato son suyos. **Un cuadro de mando sobre dato sin dueño es un incidente esperando**: si no
  hay dueño aguas arriba, el informe no se certifica. El gobierno del **propio BI** (certificación
  del informe, dueño por informe, poda) es de aquí, y hereda sus reglas de propiedad y
  clasificación.
- `data-engineering-standards`: el pipeline que llena las tablas, su frescura instrumentada y su
  coste de escaneo. Aquí solo el consumo: qué consulta el informe, cuánto cuesta esa consulta y
  qué se muestra cuando el dato aún no ha llegado.
- `lakehouse-standards`: formato de tabla y catálogo técnico; el control de acceso del formato es
  suyo. Aquí dónde se **aplica** el filtro que ve el usuario.
- `data-platform-standards` (madre), `privacy-engineering-standards` (**dato personal,
  minimización, retención y borrado; un informe que expone PII a quien no debe es un incidente de
  privacidad, y la política es suya**), `grc-compliance-standards` (**marco, riesgo y evidencia de
  auditoría**), `ai-governance-standards` (**gobierno de sistemas de IA**: un asistente de
  "pregunta a tus datos" empotrado en la herramienta de BI **es un sistema de IA y cae en su
  inventario**, aunque el dato que consume sea de esta capa).
- `identity-access-management-standards`: **identidad, SSO, SCIM y grupos son suyos**; aquí solo
  cómo la identidad se propaga hasta el filtro de fila.
- `observability-standards` (telemetría del sistema), `incident-management-standards` (el proceso
  del incidente), `api-design-standards`, `cicd-standards` (el despliegue del artefacto de BI),
  `iac-standards`, `secrets-management-standards`, `mlops-standards`,
  `llm-app-engineering-standards` y `rag-standards` (**el producto conversacional sobre datos es
  suyo**), `nosql-standards`, `search-engines-standards`,
  `aws-standards`/`azure-standards`/`gcp-standards` (QuickSight, Fabric/Power BI Service y Looker
  **como servicios gestionados**: aprovisionamiento, red, IAM y facturación son suyos).
- `streaming-cdc-standards`: la captura y el procesado en movimiento. Aquí solo el consumo: **un
  cuadro de mando "en tiempo real" sin nadie que actúe en esa latencia es gasto, no capacidad**.
- `product-discovery-standards`: **el cuadro de mando, la definición canónica de la
  métrica y su gobierno son de aquí**; **decidir qué se construye a partir de ese número es suyo**,
  igual que el diseño del experimento que lo mueve. Aviso que ambas comparten: **una métrica se
  degrada en cuanto se convierte en objetivo** —ley de Goodhart—, y por eso una métrica de negocio
  necesita métricas de guardia, no solo un umbral.
- `r-standards` y `julia-standards`: **sustituir un cuadro de mando por un
  informe de Quarto/R Markdown o por una app de Shiny es una decisión de esta skill** —quién
  consume, con qué latencia, quién mantiene la definición de la métrica y qué pasa cuando el autor
  se va—; **el código de ese informe o de esa app** —`renv`, estructura, tests, despliegue y su
  seguridad— es de `r-standards`. Aviso que ambas comparten: **una app de Shiny en producción es
  una aplicación web**, con su superficie de ataque y su coste de operación, no un informe.
- `timeseries-db-standards`,
  `message-brokers-standards`, `oracle-dba-standards`, `sqlserver-dba-standards`,
  `mysql-mariadb-dba-standards`, `caching-cdn-standards`: sus motores y su operación.

### La pregunta previa

**¿Este cuadro de mando cambia alguna decisión?** Es la única pregunta que hay que contestar antes
de construir nada, y hay que contestarla nombrando **quién** decide **qué** y **cuándo**. Si la
respuesta es "para tener visibilidad", "porque el director lo pidió" o "para monitorizar el
negocio", no hay decisión: hay **coste de mantenimiento disfrazado de valor**. Cada cuadro de mando
publicado es una consulta recurrente que se paga, un artefacto que se rompe cuando cambia el
modelo, una superficie de acceso que auditar y una fuente potencial de contradicción con otro
informe.

**Corolario que casi nadie aplica: el ciclo de vida incluye retirar.** Ninguna organización tiene
un problema de "faltan cuadros de mando"; todas tienen un problema de cementerio. Un BI maduro se
reconoce por lo que **borra**, no por lo que publica. Si en el último año no has retirado ningún
informe, tu catálogo de informes está mintiendo sobre lo que la organización usa.

## 2. Decisiones por defecto

> Verificar por web licencia, estado y **modelo de precio** antes de fijar nada (§2.2 es la
> sección que más cambia y la que decide la elección) (§8).

### 2.1 Antes de elegir herramienta

| Necesidad real | Solución más simple | Cuándo deja de servir |
|---|---|---|
| Un número que alguien mira una vez al mes | **Un informe programado por correo** o una consulta guardada | Cuando hay que cruzar, filtrar o comparar |
| Una tabla que un equipo consulta | **Vista o consulta guardada** en el almacén | Cuando el consumidor no sabe SQL |
| Un puñado de gráficos versionados junto al código | **BI como código** (Evidence, Lightdash) | Cuando el consumidor necesita construir lo suyo |
| Exploración libre de un modelo por gente de negocio | **Herramienta de BI completa** | — |
| Analítica dentro de un producto que vendes | **Empotrado** — es otro producto, otro precio y otro modelo de seguridad (§5.4) | — |

Ningún cuadro de mando es gratis. El coste no es construirlo: es mantenerlo alineado con un modelo
que cambia, durante años, mientras quien lo pidió cambia de puesto.

### 2.2 Elección de herramienta

**El criterio que decide es el modelo de precio, no la lista de funcionalidades**, porque las
funcionalidades convergieron hace años y el precio no. Y hay un segundo criterio, estructural:
**la herramienta se cambia cada pocos años; el modelo de datos sobrevive a todas.** De ahí la regla
más importante del dominio: **no metas lógica de negocio en la herramienta.** Toda transformación,
regla y métrica que vive dentro del `.pbix`, del `.twb` o del LookML es trabajo que se tira al
migrar, y mientras tanto es una definición que nadie fuera de la herramienta puede auditar.

| Herramienta | Licencia (verificado ago-2026) | Modelo de precio | Cuándo es la respuesta |
|---|---|---|---|
| **Power BI / Fabric** | Comercial | **Doble**: por usuario (Pro, Premium Per User) **o por capacidad** (SKU `F` de Fabric, facturación por segundo, reservable). Los SKU `P` heredados están siendo retirados hacia `F`. **A partir de cierto nivel de capacidad los visores dejan de necesitar licencia individual** — ese umbral es el punto de inflexión económico de toda la plataforma | Organizaciones ya en Microsoft 365. **Modela el coste con tu reparto real de autores/visores antes de firmar**: por debajo del umbral pagas por cabeza, por encima pagas capacidad fija |
| **Tableau** | Comercial (Salesforce) | **Por usuario con roles**: Creator / Explorer / Viewer, facturación anual, con niveles Cloud (Standard/Enterprise) que cambian sustancialmente el precio. Server admite además licencia **por núcleo** | Cultura visual fuerte y muchos autores. **La palanca de coste es la mezcla de roles**: sobreaprovisionar Creator a quien solo consulta es el desperdicio clásico |
| **Looker** | Comercial (Google) | **Cuota de plataforma elevada + usuarios + capacidad** (límites de llamadas de consulta y de API por edición). Precio **no público, negociado**. Metering de IA anunciado con inicio de facturación en oct-2026 | Cuando quieres una capa de modelado gobernada (LookML) y puedes pagar la entrada. **Coste oculto real: LookML es una práctica de ingeniería con personal dedicado**, no una configuración |
| **Metabase** | **OSS: AGPL-3.0**; el directorio `enterprise/` está bajo *Metabase Commercial License* (**verificado verbatim en `LICENSE.txt`**). Versiones `0.x` = OSS, `1.x` = comercial | OSS gratuito autoalojado; comercial por plan | **Default cuando la necesidad es "que la gente se conteste sus preguntas" sin proyecto.** Ojo con AGPL si vas a empotrarlo o modificarlo y distribuirlo |
| **Apache Superset** | **Apache-2.0** (verificado verbatim en `LICENSE.txt`), proyecto **top-level de la ASF** | Gratis; el coste es operarlo (o pagar Preset, el proveedor comercial dominante) | Cuando necesitas licencia permisiva y tienes capacidad de plataforma. **Política de soporte: solo dos versiones mayores a la vez** — un despliegue viejo se queda sin parches rápido |
| **Lightdash** | **MIT**, excepto `packages/backend/src/ee` bajo licencia comercial (**verificado verbatim en `LICENSE`**) | Autoalojado gratis; Cloud por planes **sin cargo por asiento** | BI sobre dbt con la métrica definida aguas arriba. **Encaja bien con la regla de oro** de §2.3 |
| **Evidence** | **MIT** | OSS gratis; Cloud/Studio por asiento + créditos de IA | Informes versionados en Git, revisados por PR, sin edición por arrastre. ⚠️ **Verificado: el repositorio OSS no registra commits en `main` desde feb-2026** mientras el esfuerzo va a la plataforma comercial "Studio"; el equipo declara que seguirá desarrollando la versión abierta. **Señal de riesgo a vigilar, no descalificación** |

Reglas de elección:
- **Coste por usuario frente a coste por capacidad**: el modelo por usuario es predecible y penaliza
  la difusión (cada visor nuevo cuesta); el de capacidad es fijo y penaliza la infrautilización
  (pagas el pico aunque nadie mire). **Modela ambos con tu reparto real de autores y visores y con
  tu crecimiento a 3 años**; el punto de cruce es el número que decide, y casi nunca está donde
  intuyes. Si el modelo por capacidad "sale más barato" solo asumiendo un número de visores que hoy
  no tienes, estás comprando una previsión, no una herramienta.
- **Coste oculto sistemático**: formación, personal de modelado (LookML, semántica, DAX), migración
  de los informes existentes y **el cómputo del almacén que la herramienta dispara**, que no aparece
  en ninguna comparativa de precios y a menudo supera a la licencia.
- **Una herramienta, no tres.** Dos herramientas de BI en la misma organización garantizan dos
  definiciones de la misma métrica. Si hay dos por historia, hay plan de convergencia con fecha.
- **Desconfía de toda comparativa escrita por un competidor**: en este segmento son casi todas.

### 2.3 La regla de oro: la métrica se define una vez, aguas arriba

**La lógica de negocio no vive en la herramienta de BI.** Vive en el modelo, versionada, con
propietario y con pruebas — y esa es competencia de `data-warehouse-modeling-standards`, que es su
dueña.

El clásico **"dos informes, dos números"** casi nunca es un fallo del dato: es una consecuencia
mecánica de haber permitido que cada informe implemente su propia versión de la regla. Basta con
que dos autores filtren distinto los pedidos cancelados, o que uno use la fecha de pedido y otro la
de facturación, para que las cifras diverjan de forma indetectable y perfectamente explicable a
posteriori. Cuando esto ocurre tres veces, la organización aprende que **los datos son opinables**,
y esa lección no se desaprende con un *hotfix*.

- **En la herramienta solo puede vivir**: la selección de la métrica ya definida, el filtrado, el
  desglose por dimensiones declaradas legales y la presentación.
- **Prohibido en la herramienta**: cálculos que redefinen la métrica, uniones que replican el
  modelo, campos calculados que implementan reglas de negocio, y transformaciones de limpieza.
- **Test de la migración**: si cambiar de herramienta obligaría a reimplementar reglas de negocio,
  la lógica estaba en el sitio equivocado. Es el mismo argumento por el que la herramienta no debe
  ser el sitio: **es la pieza más volátil del stack**.
- **Si la herramienta ofrece capa semántica propia** (modelo tabular, LookML, modelos de Metabase),
  úsala como **proyección** de la definición canónica, no como su origen. Y consúmela desde una sola
  fuente.

## 3. Diseño del cuadro de mando

**El diseño visual del gráfico es de la skill `dataviz`.** Aquí solo lo que la precede: para quién,
para qué decisión y con qué estructura.

### 3.1 Audiencia y decisión primero

Antes de abrir la herramienta, por escrito y en el propio artefacto:

1. **Quién** lo va a mirar (rol concreto, no "dirección").
2. **Qué decisión** toma con él y **con qué cadencia** (diaria, semanal, trimestral). La cadencia de
   la decisión determina la de actualización, no al revés (§4.3).
3. **Qué acción** se dispara cuando el número está mal. Si no hay acción, no hay cuadro de mando:
   hay una consulta.
4. **Qué dato** lo alimenta y **quién es su dueño** (si no hay dueño, no se certifica; ver
   `data-governance-quality-standards`).

Tres audiencias, tres artefactos distintos, y confundirlas es el error de diseño más común:

| Audiencia | Artefacto | Regla |
|---|---|---|
| **Dirección** | Pocos indicadores, comparación contra objetivo o periodo anterior, sin exploración | Si no cabe en una pantalla sin desplazar, no es un cuadro de mando de dirección |
| **Operación** | Estado actual y desviaciones accionables, con detalle suficiente para actuar hoy | Debe permitir llegar hasta el registro sobre el que se actúa |
| **Análisis** | Exploración libre sobre un modelo gobernado | **No es un cuadro de mando**: es una capa de exploración. No lo publiques como si fuera lo mismo |

### 3.2 Estructura

- **Jerarquía descendente**: la conclusión arriba, el desglose después, el detalle al final. Quien
  entra debe saber en cinco segundos si algo va mal.
- **Contexto obligatorio en todo número**: comparación (objetivo, periodo anterior) y unidad. Un
  número solo no es información, es trivia.
- **Un cuadro de mando, un tema.** Si necesita pestañas por área, son varios artefactos con dueños
  distintos.
- **Filtros por defecto sensatos y visibles.** El filtro oculto con un valor preseleccionado es la
  causa silenciosa de la mitad de las discrepancias entre dos personas mirando "el mismo" informe.
- **Todo artefacto lleva metadatos visibles**: dueño, fecha del dato (§6), definición o enlace a la
  definición de las métricas, y estado de certificación.
- **Nombres estables y explícitos.** "Informe de ventas v3 (final) copia" es una decisión de
  gobierno, no un descuido estético.

## 4. Gates

### 4.1 Gates de publicación (todo informe certificado)

1. **Decisión declarada**: audiencia, decisión, cadencia y acción, escritas en el artefacto. Sin
   esto no se publica.
2. **Dueño nominal del informe** (persona, no equipo) y dueño del dato aguas arriba existente y
   verificado.
3. **Cero lógica de negocio en la herramienta**: la revisión comprueba que las métricas provienen
   de la definición canónica y que no hay cálculos que la reimplementen. **Gate de revisión.**
4. **Cuadre contra la fuente canónica**: la cifra principal del informe coincide con la del modelo,
   con tolerancia declarada. Un informe que no cuadra el día que se publica no cuadrará nunca.
5. **Frescura visible en el propio artefacto** (§6).
6. **Acceso revisado**: quién lo ve, y si el dato es confidencial o restringido, que el filtro esté
   **aguas arriba** (§5.1).
7. **Coste estimado**: consulta por apertura × aperturas previstas + refrescos programados. Si nadie
   lo ha estimado, se estimará solo en la factura.
8. **Estado explícito**: `certificado` o `no certificado`. **No existe el estado intermedio**, y
   todo lo no certificado debe verse como tal en la interfaz.

### 4.2 Gates de revisión periódica (trimestral)

9. **Uso medido por informe.** La herramienta lo registra; si no lo registra, es un defecto de la
   herramienta.
10. **Sin uso en un trimestre → se comunica al dueño y se retira** (archivar, no borrar). El
    silencio del dueño es consentimiento a la retirada. **Sin este gate no hay ciclo de vida, hay
    acumulación.**
11. **Informes duplicados detectados y fusionados**: dos informes con la misma métrica y distinto
    resultado es un incidente de dato, no una molestia estética.
12. **Recertificación**: la certificación **caduca**. Un informe certificado hace dos años sobre un
    modelo que cambió es una mentira con sello oficial.
13. **Revisión de accesos y de suscripciones programadas** (§5.3).

### 4.3 Gates de rendimiento y coste

14. **Presupuesto de tiempo de apertura** declarado (regla práctica: unos pocos segundos en el
    primer render). Un informe que tarda un minuto no se usa: se pide por correo a un analista, que
    es exactamente el trabajo que el informe venía a evitar.
15. **La cadencia de refresco la justifica la cadencia de la decisión.** **El cuadro de mando que se
    refresca cada 5 minutos porque alguien marcó una casilla** es el patrón de gasto más extendido y
    menos cuestionado del dominio: multiplica el cómputo del almacén por 288 al día para alimentar a
    nadie. Refresco intradía solo con una acción documentada que ocurra intradía.
16. **Consultas del BI etiquetadas** (por informe o por usuario) para poder atribuir el coste. Sin
    atribución, el coste del BI es un agujero negro en la factura del almacén.

## 5. Acceso, seguridad y autoservicio

### 5.1 Seguridad a nivel de fila y de columna: aguas arriba, casi siempre

**Regla por defecto: el filtro se aplica en el almacén, no en la herramienta de BI.** El motivo es
de arquitectura, no de preferencia: la regla que vive en la herramienta **solo protege el camino
que pasa por esa herramienta**, y hoy hay muchos más caminos — un cuaderno, una consulta directa,
una segunda herramienta de BI, una integración, un agente que genera SQL. Cuanto más lejos está la
regla del dato, más servicios tienen que ser dignos de confianza para que se cumpla.

- **Suelo de aplicación**: políticas nativas del almacén (políticas de acceso a fila,
  enmascaramiento de columna, vistas autorizadas). El BI **pasa la identidad**, no decide.
- **Consulta viva (direct query) para dato sensible**, para que la política se aplique en cada
  consulta. **Un extracto materializado en la herramienta puede saltarse la política del almacén
  por completo** — es el fallo de diseño más habitual y el más silencioso.
- **La seguridad en la herramienta es complemento de usabilidad**, no frontera. Úsala para acotar
  lo que se ve, nunca como único control de lo que se puede ver.
- **Define las políticas antes de abrir la herramienta**: si alguien consulta la tabla antes de que
  exista la regla, el autoservicio nace con un agujero.
- **Rendimiento**: una política de fila con *joins*, transformaciones de texto o búsquedas anidadas
  convierte cada consulta en un problema de planificación. Precalcula la tabla de asignaciones de
  permisos y filtra con predicados directos sobre columnas existentes. La dimensión que determina
  la visibilidad **tiene que existir en el modelo** (decisión de
  `data-warehouse-modeling-standards`; si se añade después, es una migración del histórico).
- **Excepción legítima y única**: multi-tenancy en analítica empotrada donde el filtro depende de la
  sesión de la aplicación — y aun así el filtro se **empuja al almacén** como predicado, no se
  resuelve solo en la capa de presentación (§5.4).

### 5.2 Autoservicio: qué se abre y qué no

El autoservicio es una **negociación entre democratizar y crear un pantano de informes
contradictorios**, y hay que resolverla explícitamente, no dejarla a la deriva.

| Capa | Quién | Qué puede hacer | Garantía |
|---|---|---|---|
| **Certificada** | Todos | Consumir, filtrar, desglosar por dimensiones legales | **La organización responde de estos números** |
| **Exploratoria** | Analistas con formación | Construir sobre el modelo gobernado, publicar en su espacio | Marcado visiblemente como no certificado; **no se comparte fuera del área sin certificar** |
| **Libre (SQL)** | Perfiles técnicos con permiso | Consulta directa al almacén | Sin garantía; sujeto a la seguridad del almacén (§5.1) |

- **Se abre el modelo, no las tablas crudas.** Autoservicio sobre la capa cruda produce análisis
  plausibles y equivocados, y nadie lo detecta.
- **La promoción de exploratorio a certificado es un proceso con revisión**, no un cambio de
  carpeta.
- **La formación no es opcional**: quien no sabe qué representa una fila producirá cifras infladas
  con total sinceridad. El autoservicio sin formación es delegar el error.
- **La alternativa al autoservicio gobernado no es el orden: es la hoja de cálculo.** Si el acceso
  gobernado es incómodo, la gente exportará. Por eso el equilibrio se resuelve haciendo cómodo lo
  correcto, no prohibiendo lo incorrecto.

### 5.3 Exportación a hoja de cálculo: donde se evapora el gobierno

En el momento en que un usuario exporta a CSV o a Excel, **todo se pierde a la vez**: la seguridad
de fila, la clasificación, la frescura, la definición de la métrica, el linaje y la capacidad de
corregir. El fichero se reenvía, se edita, se combina con otro y vuelve a la organización como
"dato" tres semanas después, ya incorrecto y sin trazabilidad. Es, sin discusión, la mayor fuga de
gobierno de la capa de consumo.

Postura realista (prohibirlo no funciona y empuja a capturas de pantalla y copiar-pegar):

- **Permitido por defecto en dato interno**; **restringido o desactivado** en informes con dato
  confidencial o restringido (la clasificación es de `data-governance-quality-standards` y **viaja
  con la copia**).
- **Marca de agua en la exportación**: fecha del dato, filtros aplicados, informe de origen y
  aviso de caducidad. Un CSV sin contexto es indistinguible de un CSV inventado.
- **Registrar las exportaciones** de informes con dato sensible, y revisar el registro: la
  exportación masiva y repetida es a la vez una señal de exfiltración y el síntoma de que **el
  informe no da lo que el usuario necesita**. Trátala como requisito no cubierto antes que como
  delito.
- **La exportación programada a un directorio compartido es un pipeline de datos no gobernado.** Si
  existe, se convierte en un conjunto de datos con dueño y contrato, o se elimina.

### 5.4 Distribución y analítica empotrada

- **Informes programados (suscripciones)**: útiles y baratos, pero **caducan igual que los cuadros
  de mando** y nadie los revisa nunca. Toda suscripción tiene dueño y fecha de revisión; la que
  nadie abre se cancela. Un correo diario que todo el mundo archiva sin leer no es distribución: es
  ruido con coste de cómputo.
- **Alertas sobre datos**: se alerta por **umbral con acción definida**, no por variación
  interesante. Toda alerta lleva **quién actúa y qué hace**. Y una regla que se olvida siempre:
  **la alerta que no se dispara porque el dato no llegó es un falso negativo silencioso** — vigila
  la frescura además del umbral (§6).
- **Analítica empotrada**: es **otro producto**, con otro modelo de precio (habitualmente por
  capacidad o por sesiones, no por asiento), otro modelo de aislamiento entre clientes y otro nivel
  de exigencia de disponibilidad. Requisitos duros: aislamiento por inquilino **verificado con
  pruebas** (no confiado a un parámetro), filtro empujado al almacén, credenciales de servicio que
  **jamás** llegan al navegador, y límites de consulta por inquilino para que un cliente no degrade
  a los demás.
- **Un asistente conversacional sobre los datos** dentro de la herramienta de BI **es un sistema de
  IA**: entra en el inventario de `ai-governance-standards`, y su salida se trata como no fiable
  (ver `llm-app-engineering-standards`). No lo certifiques como fuente.

## 6. Rendimiento, coste y calidad percibida

### 6.1 Rendimiento y coste

- **Agrega aguas arriba, no en la herramienta.** Si un cuadro de mando escanea el hecho atómico en
  cada apertura, falta un agregado en el modelo. La herramienta no es el sitio para arreglar un
  problema de modelado.
- **Extracto/importación frente a consulta viva** — decisión consciente, con consecuencias:

| Modo | Ventaja | Coste real |
|---|---|---|
| **Consulta viva** | Un solo sitio con la verdad; **la seguridad del almacén se aplica siempre**; sin duplicación | Latencia dependiente del almacén; cada apertura se paga; concurrencia real sobre el motor |
| **Extracto / importación** | Rápido y barato de servir; independiente de la carga del almacén | **Duplica el dato y puede saltarse las políticas de acceso** (§5.1); introduce desfase; se convierte en un almacén paralelo sin gobierno |

Default: **consulta viva sobre un agregado bien modelado**; extracto solo para dato no sensible con
un problema de rendimiento medido y con frescura declarada en el propio informe.
- **Caché con TTL alineado al SLA de frescura del dato.** Cachear más que la frescura no aporta
  nada; menos, malgasta cómputo. Y un caché que sirve un dato ya corregido es un incidente
  encubierto: la invalidación forma parte del arreglo.
- **Los refrescos programados se solapan y se acumulan**: docenas de informes actualizándose a las
  8:00 producen el pico que hace lento todo lo demás. Escalona, y revisa la lista completa de
  programaciones al menos una vez al año — está llena de artefactos muertos que siguen consumiendo.
- **Atribuye el coste al informe y publícalo con su dueño.** Es lo único que convierte el gasto en
  una decisión en vez de en una queja.

### 6.2 Calidad percibida: cuando el dato falta o llega tarde

El usuario no distingue "dato mal" de "informe mal": para él, **el BI ha fallado**. La confianza se
gestiona aquí o se pierde aquí.

- **Muestra la frescura en el propio informe, siempre y de forma visible**: "datos hasta
  `<fecha/hora>`", no un pie de página en gris claro. Que el usuario descubra por su cuenta que
  falta el día de ayer es el peor resultado posible.
- **Estado explícito cuando el dato no ha llegado**: un aviso claro de dato incompleto o retrasado.
  **Nunca muestres un gráfico que cae a cero porque falta la última partición**: el usuario leerá
  una caída del negocio, actuará sobre ella, y habrás convertido un retraso en un incidente de
  decisión. Un hueco declarado es infinitamente mejor que un cero falso.
- **Marca el informe como sospechoso mientras dura un incidente de dato** (coordinado con
  `data-governance-quality-standards` §4.3), **en el punto de consumo**, no en un canal que el
  consumidor no lee.
- **Comunicar la corrección forma parte del arreglo.** Si el número cambió retroactivamente, se
  dice. La confianza se pierde por silencio, no por errores.
- **Cifras parciales del periodo en curso, etiquetadas como tales.** El mes actual comparado con
  meses completos es la comparación engañosa más frecuente de todos los cuadros de mando.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisión trimestral de uso y poda (§4.2); revisión anual del modelo de precio
  contratado frente al uso real (los modelos por capacidad y por asiento se desalinean rápido); y
  revisión de las versiones soportadas de la herramienta autoalojada.
- **ADR obligatorio** para: elección o cambio de herramienta de BI, adopción de un segundo producto
  de BI, decisión extracto frente a consulta viva sobre dato sensible, dónde se aplica la seguridad
  de fila, y abrir autoservicio a un colectivo nuevo.
- **Plan de salida escrito** al contratar: cómo se exportan las definiciones, cuánto trabajo cuesta
  reimplementar los informes y qué queda atrapado. Si la respuesta es "muchísimo", la lógica estaba
  en el sitio equivocado (§2.3).
- **Artefactos de BI versionados** siempre que la herramienta lo permita (LookML, Lightdash,
  Evidence, formatos de proyecto de Power BI). Un informe que solo existe dentro de una interfaz web
  no tiene historia, ni revisión, ni recuperación.

**PROHIBIDO**
- ❌ **Construir un cuadro de mando sin decisión, audiencia y acción declaradas.**
- ❌ **Definir o redefinir una métrica dentro de la herramienta de BI** — la definición canónica es
  de `data-warehouse-modeling-standards`.
- ❌ Lógica de negocio, limpieza o uniones que replican el modelo dentro del artefacto de BI.
- ❌ La misma métrica publicada con dos valores distintos: es un incidente, no una discrepancia.
- ❌ Duplicar aquí las reglas de diseño del gráfico: **son de `dataviz`**.
- ❌ Publicar un informe sobre un conjunto de datos **sin dueño** aguas arriba.
- ❌ Informe sin dueño nominal, o cuya certificación no caduca nunca.
- ❌ Catálogo de informes sin poda: sin uso medido en un trimestre, se retira.
- ❌ Estado ambiguo: o certificado o marcado visiblemente como no certificado.
- ❌ **Seguridad a nivel de fila implementada solo en la herramienta de BI** cuando el dato es
  confidencial o restringido.
- ❌ Extracto materializado de dato sensible que se salta las políticas del almacén.
- ❌ Credenciales de servicio o secretos de conexión accesibles desde el cliente/navegador.
- ❌ **Refresco intradía sin una acción documentada que ocurra intradía.**
- ❌ Informe publicado sin estimación de coste ni atribución de sus consultas.
- ❌ Mostrar un gráfico que cae a cero porque falta la última partición.
- ❌ Informe sin indicación visible de la fecha del dato.
- ❌ Comparar un periodo en curso con periodos completos sin etiquetarlo.
- ❌ Alerta sin umbral, sin acción o sin responsable; alerta ciega al dato que no llegó.
- ❌ Exportación programada a un directorio compartido tratada como algo distinto de un pipeline sin
  gobierno.
- ❌ Exportación libre de informes con dato confidencial o restringido, o exportación sin contexto
  (fecha, filtros, origen).
- ❌ Autoservicio sobre la capa cruda, o sin formación sobre qué representa una fila.
- ❌ Dos herramientas de BI en producción sin plan de convergencia con fecha.
- ❌ Comprar una herramienta sin modelar el coste con el reparto real de autores y visores y sin
  plan de salida.
- ❌ Fijar licencias, versiones o modelos de precio de memoria (§8).

## 8. Verificación web obligatoria

Los datos de §2 son de **agosto de 2026**, y **el modelo de precio es lo que más cambia y lo que
decide la elección**. Antes de fijar nada en un entregable, verifica:

1. **Power BI / Fabric**: precios vigentes de Pro y Premium Per User, catálogo de SKU `F`, estado de
   la retirada de los SKU `P` y —lo decisivo— **el nivel de capacidad a partir del cual los visores
   dejan de necesitar licencia individual**, en la página oficial de Microsoft, no en comparativas.
2. **Tableau**: precios de Creator/Explorer/Viewer por edición (Standard/Enterprise), estado de la
   licencia por núcleo de Server y qué incluye el nivel superior.
3. **Looker**: cuotas de plataforma vigentes por edición, límites de llamadas de consulta y de API,
   y **el metering de IA cuya facturación estaba anunciada para octubre de 2026** (comprueba si
   entró en vigor y a qué tarifas).
4. **OSS**: licencia vigente de **Metabase** (a ago-2026, AGPL-3.0 fuera de `enterprise/`,
   verificado verbatim; `0.x` OSS / `1.x` comercial), **Superset** (Apache-2.0, ASF; **versión
   estable actual y política de soporte de dos majors**), **Lightdash** (MIT salvo
   `packages/backend/src/ee`) y **Evidence** (MIT) — y sus modelos de precio de la versión
   gestionada.
5. **Actividad real de los proyectos OSS** medida en commits y releases, no en la web del proyecto.
   En concreto **Evidence**: si el repositorio abierto ha vuelto a registrar actividad en `main`
   (parado desde feb-2026) o si el desarrollo se ha desplazado definitivamente a la plataforma
   comercial.
6. **Seguridad a nivel de fila/columna** en tu motor concreto (Snowflake, BigQuery, Databricks,
   Fabric, Redshift): sintaxis, límites, coste de la política y cómo se propaga la identidad desde
   la herramienta.
7. **Cadena de suministro** de cualquier componente que despliegues (imágenes de Superset/Metabase,
   paquetes de Evidence/Lightdash): compromisos recientes y CVEs. Precedentes vivos en el
   ecosistema de datos: `elementary-data` (abr-2026), `trivy` y LiteLLM (mar-2026), `durabletask`
   (may-2026).

**Huecos declarados de esta revisión** (no rellenar de memoria):
- **Todas las cifras de precio**: verificados los **modelos** (por usuario, por capacidad, cuota de
  plataforma, por asiento + créditos); **los importes concretos no se fijan aquí** porque las
  fuentes disponibles eran comparativas de terceros y de competidores, con contradicciones entre
  ellas. No cites importes sin la página oficial del proveedor.
- **Power BI**: no verificado en fuente oficial el **valor exacto del umbral de capacidad** que
  libera a los visores de licencia individual (las fuentes secundarias coinciden en que existe y en
  que es el punto de inflexión, pero difieren en cifras de coste).
- **Apache Superset**: **versión estable actual no verificada en fuente ASF**. Las fuentes
  disponibles (blog del proveedor comercial) apuntan a una 6.1.0 en may-2026; el feed de etiquetas
  del repositorio solo devolvió etiquetas del chart de Helm. Verifica en `superset.apache.org`.
- **Metabase**: verificada la licencia verbatim; **no verificados los planes ni los precios
  vigentes** de la edición comercial.
- **Looker**: no verificadas las tarifas ni si el metering de IA entró en vigor.
- **Evidence**: verificado MIT y la ausencia de commits en `main` desde feb-2026; **no verificado**
  qué compromiso público existe sobre el futuro de la versión abierta.
- **Preset, QuickSight, Sigma, Hex, Omni y Zoho** no evaluados en esta revisión.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
