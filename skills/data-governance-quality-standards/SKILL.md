---
name: data-governance-quality-standards
description: Use when data must be trustworthy and owned — naming a data owner and data steward per dataset versus the platform team, federated ownership and data mesh honesty, choosing or operating a data catalog (DataHub, OpenMetadata, Amundsen, Apache Atlas, Unity Catalog OSS, Collibra, Alation, Atlan), technical versus business metadata, column-level lineage and impact analysis, a business glossary where two teams define "active customer" differently, data contracts as schema plus semantics plus SLA plus owner (Open Data Contract Standard, Bitol ODCS/ODPS, datacontract.yaml) and what happens when one breaks, the quality dimensions (completeness, uniqueness, validity, consistency, timeliness, accuracy) turned into executable assertions, where to check them (source, pipeline, consumption), quality tooling (Great Expectations/GX Core, Soda, Elementary, Evidently), severity of a data incident and notifying the consumers who already decided with bad numbers, data classification tiers (public/internal/confidential/restricted) and their link to access control, dataset retention and decommissioning, or program metrics like contract coverage, time to detect and time to resolve.
---

# Estándares de gobierno del dato y calidad

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando la pregunta es **de quién es el dato, si se puede confiar en él y quién responde
cuando no**: propiedad, catálogo, glosario, linaje, contratos de datos, programa de calidad,
incidentes de dato, clasificación y ciclo de vida.

Disparadores: `datacontract.yaml`, `odcs.yaml`, `contract.yml`, `great_expectations/`,
`gx/`, `expectations/*.json`, `soda/checks.yml`, `soda-cl`, `elementary/`, `edr report`,
`schema.yml` con `tests:`/`data_tests:`, `owner:`/`owner_email`, `tags: [pii, confidential]`,
`glossary`, `lineage`, `datahub`/`recipe.yml` de ingesta de metadatos, `openmetadata`,
`atlas`, `unitycatalog`, "¿de quién es esta tabla?", "¿esto es fiable?", "¿qué se rompe si
cambio esta columna?", "los dos informes dan cifras distintas", "llevamos tres semanas con
datos viejos y nadie se enteró", "¿qué es un cliente activo?", "¿cuánto tiempo guardamos esto?".

**No aplica**: ver
- `analytics-bi-standards` (**hermana; frontera declarada en ambos lados**): **el gobierno decide
  si el dato es confiable y de quién es; el BI lo presenta para que alguien decida.** Certificar
  un informe, retirarlo, elegir herramienta, rendimiento del cuadro de mando y exportación a hoja
  de cálculo son suyos; el dueño del conjunto de datos que hay debajo, su contrato, su frescura
  comprometida y su clasificación son de aquí. **Un cuadro de mando sobre dato sin dueño es un
  incidente esperando**, y el gobierno del propio BI (dueño por informe, poda) es suyo pero
  hereda estas reglas de propiedad.
- `data-warehouse-modeling-standards`: **la definición canónica de una métrica y la capa semántica
  son suyas** (§3.7 de esa skill), igual que las pruebas estructurales del modelo (unicidad del
  grano, integridad referencial, SCD2). Aquí el **glosario de negocio** —el término y su
  significado acordado— y el **programa** que hace que esas pruebas existan, tengan dueño y se
  revisen. Regla de corte: *"¿cómo se calcula ingreso neto?"* es suya; *"¿quién decide qué
  significa cliente activo y quién responde cuando dos áreas discrepan?"* es de aquí.
- `data-engineering-standards`: **ella ejecuta las aserciones y el gate de frescura dentro del
  pipeline** (bloqueante frente a aviso, retries, backfill, observabilidad del dato como
  instrumentación). Aquí se decide **qué se comprueba, con qué severidad, quién es el dueño de la
  regla y qué pasa cuando falla**. La mecánica es suya; el programa es de aquí.
- `data-platform-standards` (**madre**): motores, cifrado en reposo, backups, PITR.
- `privacy-engineering-standards`: **dato personal, minimización, base legal, retención y borrado
  del sujeto, seudonimización y DPIA son suyos, sin excepción.** Aquí la clasificación **general**
  del dato (incluida la categoría "restringido" que suele contener dato personal) y el ciclo de
  vida del conjunto de datos como activo. Si la pregunta menciona un interesado, un derecho o una
  base legal, es suya.
- `grc-compliance-standards`: **marco normativo, riesgo corporativo, SoA, evidencia de auditoría y
  mapeo control-norma son suyos.** Aquí el control operativo del dato; que ese control **sirva
  como evidencia** ante ISO 27001, NIS2 o DORA lo decide ella.
- `ai-governance-standards` (**frontera directa, declarada en ambos lados**): **el gobierno de los
  sistemas de IA es suyo** —inventario de sistemas, AI Act, clasificación de riesgo, FRIA,
  supervisión humana—. **El gobierno del dato es de aquí.** Se cruzan exactamente en un punto: el
  dato que alimenta un modelo. Regla de corte: la **procedencia, propiedad, calidad, contrato y
  clasificación del conjunto de entrenamiento o de recuperación son de aquí**; qué se puede hacer
  con el sistema resultante, quién lo autoriza y qué obligación regulatoria genera es suya. Ambas
  comparten la misma tesis: **el gobierno que no cambia decisiones es teatro.**
- `incident-management-standards`: **el proceso del incidente es suyo** —declaración, severidad,
  Incident Commander, comunicación, postmortem sin culpa—. Aquí solo lo específico del dato: qué
  hace incidente a un dato malo, cómo se avisa a quien ya decidió con él, y por qué el fallo
  silencioso no encaja en la matriz de severidad estándar.
- `observability-standards`: telemetría **del sistema** (OTel, métricas, trazas). **La
  observabilidad del dato —frescura, volumen, esquema, distribución— es de aquí como programa y de
  `data-engineering-standards` como instrumentación.** Línea: si la señal describe el proceso, es
  suya; si describe el dato, no.
- `identity-access-management-standards`: **quién accede y con qué identidad es suyo**; aquí solo
  la **clasificación que determina qué merece qué control**.
- `sre-practice-standards` (SLO y guardia como práctica), `backup-recovery-standards`,
  `bcdr-standards`, `cicd-standards`, `iac-standards`, `api-design-standards`,
  `object-storage-standards`, `mlops-standards`, `rag-standards`,
  `llm-app-engineering-standards`, `python-standards`,
  `aws-standards`/`azure-standards`/`gcp-standards` (Purview, Dataplex, DataZone/SageMaker
  Catalog **como servicios gestionados**: aprovisionamiento, IAM y coste son suyos; el criterio de
  gobierno encima es de aquí).
- `lakehouse-standards`: **el formato de tabla y el catálogo técnico son suyos** —Iceberg/Delta,
  REST Catalog, Polaris, Nessie, snapshots, *time travel*, mantenimiento—, incluido el control de
  acceso a nivel de tabla/fila/columna del formato y el borrado dentro de un formato inmutable.
  Aquí el **catálogo de gobierno** (dueño, glosario, certificación, linaje de negocio), que es otra
  cosa aunque comparta la palabra: un *catálogo técnico* resuelve dónde están los ficheros; uno de
  gobierno, si puedes fiarte de ellos.
- Motores concretos: `nosql-standards`, `graph-db-standards`, `vector-db-standards`,
  `search-engines-standards`, `streaming-cdc-standards` (**los eventos de cambio y su contrato de
  transporte son suyos**; el contrato de datos del conjunto resultante es de aquí), y **Ola 4,
  planificadas**: `timeseries-db-standards`, `message-brokers-standards`,
  `oracle-dba-standards`, `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`,
  `caching-cdn-standards`.

### Tesis del dominio

**La calidad del dato es un problema de propiedad, no de herramienta.** Sin una persona nombrada
por conjunto de datos, ninguna herramienta arregla nada: el catálogo se llena de tablas sin
descripción, las aserciones fallan en rojo permanente y nadie las mira, y el glosario documenta
términos que nadie usa. Con dueño, casi cualquier herramienta funciona. Comprar catálogo antes de
nombrar dueños es la secuencia invertida más cara y más frecuente del sector.

**Corolario, el mismo criterio que `ai-governance-standards`: el gobierno que no cambia decisiones
es teatro.** Un control que solo produce una diapositiva no es un control. Antes de añadir
cualquier pieza al programa, responde: *¿qué decisión cambia esto y quién la toma?* Si la
respuesta es "nos permite enseñar que lo gobernamos", bórralo. Este dominio acumula más teatro por
metro cuadrado que ningún otro de la disciplina: comités que aprueban lo que ya está en
producción, políticas que nadie lee, catálogos con el 90 % de las entradas autogeneradas y vacías,
y cuadros de mando de calidad cuyo porcentaje verde es una función de qué reglas se escribieron,
no de si el dato sirve.

## 2. Decisiones por defecto

> Verificar por web estado, licencia y propietario antes de fijar nada en un proyecto real (§8).
> Este segmento consolidó fuerte en 2025-2026 y **al menos dos piezas cambiaron de licencia o de
> dueño sin cambiar de nombre**.

### 2.1 Secuencia del programa (orden no negociable)

| Paso | Entregable | Por qué antes que el siguiente |
|---|---|---|
| 1 | **Inventario de los conjuntos de datos que importan** (los que alimentan decisiones o sistemas, no todos) | Gobernar todo es no gobernar nada |
| 2 | **Dueño nombrado por conjunto de datos**, persona con nombre y rol, publicado | Sin esto, el resto es decoración |
| 3 | **Contrato mínimo** de los conjuntos publicados: esquema, semántica, SLA de frescura, dueño | Convierte expectativas tácitas en compromiso verificable |
| 4 | **Aserciones ejecutables** derivadas del contrato | Un contrato que no se comprueba es una promesa |
| 5 | **Proceso de incidente de dato** con severidad y comunicación | Sin esto, detectar no sirve de nada |
| 6 | **Catálogo** | Es el escaparate del trabajo anterior, no un sustituto de él |
| 7 | **Glosario de negocio** de los términos en disputa (no del diccionario entero) | Solo tiene valor donde hay desacuerdo real |

**Instalar el catálogo primero es el error canónico del dominio.** Da la sensación de progreso
—hay una web, hay tablas, hay un buscador— sin cambiar ninguna decisión. Un catálogo poblado
automáticamente sobre datos sin dueño es un inventario del pantano.

### 2.2 Catálogo y descubrimiento

Un catálogo resuelve **exactamente dos preguntas**, y hay que exigirle esas dos y ninguna más:

1. **Encontrar el dato** que necesito sin preguntar a un humano.
2. **Saber si puedo confiar en él**: quién es el dueño, cuándo se actualizó por última vez, si
   está certificado, si sus comprobaciones están en verde y de dónde viene.

Todo lo demás que venden los catálogos (flujos de aprobación, campañas de *stewardship*,
puntuaciones de calidad agregadas) es opcional y, en la práctica, lo primero que se abandona.

| Opción | Licencia y gobernanza (verificado ago-2026) | Estado real | Veredicto |
|---|---|---|---|
| **OpenMetadata** | Apache-2.0; empresa detrás: Collate | **Muy activo**: rama 1.13.x con releases en jul-2026 y **2.0.0-rc1** (jul-2026) | **Default OSS** para catálogo de propósito general |
| **DataHub** | Apache-2.0; empresa detrás: Acryl Data / DataHub Cloud | **Activo**: v1.6.0 (may-2026), *release candidates* en ago-2026 | Correcto cuando importa la escala del grafo de metadatos y la ingesta por eventos; **más coste operativo** |
| **Unity Catalog (OSS)** | Apache-2.0; **sandbox** en LF AI & Data (nivel de entrada, no incubación ni graduado) | 0.5.1 (jul-2026). **APIs declaradas como no estables** | **No es el Unity Catalog de Databricks.** Lo abierto es la especificación REST y un servidor de referencia; linaje, calidad, ABAC, tablas de sistema y auditoría **son del producto comercial**. Útil como capa de metadatos interoperable; **no lo vendas como catálogo de gobierno** |
| **Apache Atlas** | Apache-2.0, ASF | Vivo pero lento: 2.5.0 (abr-2026), 2.6.0-rc0 (ago-2026) | Solo si ya vives en el ecosistema Hadoop/Ranger. No es una elección nueva |
| **Amundsen** | Apache-2.0, LF AI & Data | **Efectivamente parado**: último release **v1.0.0 (jun-2025)**; último commit en `main` **abr-2025** | ❌ **No lo adoptes en 2026.** Si lo tienes, planifica salida |
| **Collibra / Alation / Informatica / Atlan** | Comercial, precio negociado (orden de magnitud publicado por analistas: **cientos de miles de € al año** en despliegue empresarial) | Los cuatro figuran como líderes del cuadrante de Gartner de plataformas de gobierno de datos y analítica de 2026, que ya evalúa **gobierno de modelos de IA** como criterio | Se justifican cuando hay obligación regulatoria formal, miles de activos y un equipo de gobierno dedicado. **No los compres para resolver "no sabemos de quién es esta tabla" en 200 tablas** |

**Linaje: la funcionalidad que más se paga y menos se mantiene.** Es la que cierra la venta y la
que se degrada en silencio. Motivos concretos: el linaje a nivel de columna solo es fiable donde
el motor lo emite o el parser de SQL lo entiende, y basta un procedimiento almacenado, un job en
Python, una exportación a hoja de cálculo o un `CREATE TABLE AS` generado dinámicamente para
partir el grafo. El resultado típico es un grafo **parcial que se presenta como completo**, que es
peor que no tenerlo: alguien decide que "nada depende de esta tabla" y la borra.

Reglas de linaje:
- **Exige que el linaje se derive de la ejecución real** (logs de consulta, metadatos del motor,
  eventos del orquestador), no de documentación introducida a mano. El linaje manual caduca en
  semanas.
- **Mide y publica la cobertura** ("el linaje cubre el 70 % de los activos de la capa de consumo").
  Un grafo sin cobertura declarada invita a conclusiones falsas.
- **Su único uso que justifica el coste es el análisis de impacto**: *"¿qué se rompe si cambio
  esto?"* y *"¿a quién aviso de que este dato estaba mal?"*. Si nadie lo usa para eso, no lo pagues.

**Metadatos técnicos frente a de negocio**: los técnicos (esquema, tipos, tamaño, frescura,
linaje) se **recolectan automáticamente y son gratis**; los de negocio (qué significa, quién lo
usa, para qué decisión, qué reglas se le aplicaron) **se escriben a mano y son los únicos que
tienen valor**. Un catálogo con el 100 % de metadatos técnicos y el 5 % de negocio ha
automatizado lo que no importaba. Corolario operativo: **no pobles el catálogo entero**. Empieza
por los activos certificados y deja lo demás visible pero explícitamente no gobernado.

### 2.3 Herramientas de calidad

| Herramienta | Licencia y estado (verificado ago-2026) | Uso correcto |
|---|---|---|
| **Tests del motor de transformación** (dbt tests / SQLMesh audits) | Parte de la herramienta que ya usas | **Default.** La primera línea de aserciones vive donde vive la transformación, no en un sistema aparte |
| **Soda Core** | ⚠️ **Elastic License 2.0** — *source-available*, **no OSI open source** (verificado verbatim en el fichero `LICENSE` del repo). Activo: 4.19.0 (jul-2026) | Legítimo para uso interno. **Descartado si tu política exige licencia OSI**, o si vas a empotrarlo en un producto que ofreces a terceros |
| **Great Expectations (GX Core)** | Apache-2.0. **GX Cloud fue adquirido por FICO y dejó de estar disponible públicamente**; **Fivetran anunció el 13-may-2026 que asume la tutela (*stewardship*) de la comunidad y de GX Core**. `CloudDataContext` ahora lanza excepción | Solo si necesitas su catálogo de *expectations* o validación fuera de SQL (Pandas/Spark). **GX 1.0 (ago-2024) rompió la API respecto a 0.x**: cualquier material de 0.x es inservible |
| **Elementary** | OSS + SaaS. Activo (0.25.1, jul-2026). ⚠️ **Ver §5: la versión 0.23.3 fue publicada comprometida el 24-abr-2026** | Observabilidad sobre proyectos dbt. Adóptalo **con la disciplina de fijado por hash de §5**, no sin ella |
| **Evidently** | OSS activo; **licencia no verificada en crudo en esta revisión (§8)** | **Es una herramienta de deriva de distribución, no un motor de aserciones de negocio.** Correcto para vigilar deriva de datos que alimentan modelos (frontera con `mlops-standards`); incorrecto como sustituto de reglas de validez |
| **dbt-expectations** (Calogica) | ❌ **No mantenido** (repo declarado sin soporte activo) | No lo introduzcas en proyectos nuevos |

**Criterio de elección, en una línea**: la mejor herramienta de calidad es **la que ya está en el
pipeline**. Un sistema de calidad separado añade otro despliegue, otras credenciales del almacén
(§5), otro cuadro de mando y otro sitio donde mirar. Se justifica cuando necesitas comprobar dato
que **no pasa por tu transformación** (ficheros de terceros, la fuente antes de ingerirla, un
sistema operacional ajeno).

### 2.4 Contratos de datos

Un contrato de datos es **cuatro cosas o no es nada**:

1. **Esquema**: columnas, tipos, nulabilidad, valores admitidos.
2. **Semántica**: qué significa cada campo y qué representa una fila (el grano lo declara
   `data-warehouse-modeling-standards`; el contrato lo **publica**).
3. **SLA**: frescura comprometida, ventana de corrección, disponibilidad. **Frescura y
   disponibilidad son distintas** y confundirlas es el error habitual.
4. **Dueño** y canal de contacto.

Un "contrato" que solo tiene esquema es una definición de esquema con nombre pomposo.

- **Dónde viven**: **en el repositorio, versionados, junto al código que produce el dato**, y
  revisados por *pull request*. Nunca en una wiki, nunca solo dentro del catálogo. Que el contrato
  esté en Git es lo que permite que romperlo rompa una CI.
- **Especificación**: **Open Data Contract Standard (ODCS)**, bajo el proyecto **Bitol** de LF AI &
  Data, es hoy la de mayor tracción, junto a la Data Contract Specification (`datacontract.com`),
  con trabajo declarado de armonización entre ambas. Verifica la versión antes de fijarla: a
  ago-2026 la documentación publica **v3.1.0** mientras el `main` del repositorio declara **v3.0.2**
  (discrepancia real, ver §8). Las cifras de adopción que circulan (114 organizaciones a
  31-may-2026) provienen de un **registro interno del propio proyecto y son autodeclaradas**:
  úsalas como señal de dirección, no como cuota de mercado.
- **Adopta la especificación por higiene, no por portabilidad.** Su valor inmediato es tener un
  formato acordado y validable; el ecosistema de herramientas que lo consumen todavía es delgado.
- **Contrato del productor, no del consumidor.** Lo firma quien produce el dato. Un contrato
  redactado por el equipo de datos sobre un sistema que no controla es una lista de deseos.

**Qué pasa cuando se rompe** — es la única parte que importa y la que casi nunca se define:

| Tipo de ruptura | Efecto exigido | Quién decide |
|---|---|---|
| **Compatible** (columna nueva, valor nuevo en un catálogo abierto) | Se anuncia; no bloquea | Productor |
| **Incompatible** (columna eliminada o renombrada, tipo cambiado, grano cambiado, semántica cambiada) | **Rompe la CI del productor.** No se publica sin migración expand/contract, aviso a los consumidores conocidos y periodo de convivencia | **Productor y consumidores afectados; el dueño del dato arbitra** |
| **Ruptura del SLA** (llega tarde, llegan 0 filas, fuera de banda) | Incidente de dato (§4.3) | Guardia de datos |

Regla dura: **si romper un contrato no rompe nada, no había contrato.** Y el corolario que evita
el teatro: **quien se entera tiene que ser quien puede arreglarlo**, no una lista de distribución.

### 2.5 Propiedad y modelo organizativo

Tres roles distintos, que se confunden constantemente:

| Rol | Qué decide | Qué NO es |
|---|---|---|
| **Data owner** (dueño) | Persona **del negocio** responsable del activo: qué significa, quién puede acceder, cuánto se retiene, si un cambio es aceptable, y **arbitra cuando dos áreas discrepan** | No es quien mantiene la tabla. No es un equipo. No es "el área de datos" |
| **Data steward** (custodio) | Ejecuta y mantiene: documenta, define y mantiene las reglas de calidad, atiende dudas, cura el catálogo | No decide política ni acceso |
| **Equipo de plataforma** | Provee el sustrato: catálogo, motores de comprobación, linaje, permisos, telemetría. **Hace posible que los demás hagan su trabajo** | **No es el dueño de los datos de nadie**, y en el momento en que lo es, la organización deja de gobernar |

**Regla dura: propiedad nominal, no de departamento.** "Es de Finanzas" no es un dueño; es una
manera educada de decir que no hay ninguno.

**Modelo federado (malla de datos), con honestidad y sin venta.** La retrospectiva de 2026 es
razonablemente clara y conviene decirla entera:

- **Lo que sobrevivió**: la propiedad por dominio, el **producto de dato** como unidad de gobierno,
  el gobierno federado con estándares comunes y el equipo central como **facilitador, no como
  guardián**. Las implantaciones maduras acotan el gobierno estricto a un número **pequeño** de
  productos de dato críticos (del orden de decenas) y dejan el resto consultable pero
  **explícitamente no certificado** — patrón excelente, adóptalo se llame como se llame.
- **Lo que no sobrevivió**: la descentralización maximalista. Thoughtworks, origen del concepto,
  describe 2026 como madurez ganada a pulso junto a "un cementerio silencioso de proyectos
  estancados"; Gartner llegó a proyectar que quedaría obsoleto antes de alcanzar meseta. Ambas
  cosas pueden ser ciertas: el diagnóstico era bueno, la prescripción se pasó de frenada.
- **Lo que exige de verdad**: dominios con capacidad de ingeniería propia, presupuesto de producto
  (no de proyecto, y este es el factor que más implantaciones ha matado) y una plataforma
  self-service que exista **antes** de repartir responsabilidad. **Sin las tres, federar es
  externalizar el problema a equipos que no pueden resolverlo**, y el resultado es peor que la
  centralización de la que huías.

Criterio: **centraliza por defecto en organizaciones de menos de ~50 personas de datos**; federa
solo donde el dominio ya sostiene su propio software en producción. Y no llames "malla" a repartir
tablas sin repartir capacidad.

### 2.6 Glosario de negocio

Su valor no es documentar; es **resolver desacuerdos**. El problema real no es que "cliente" no
esté definido: es que Ventas y Finanzas llaman **"cliente activo"** a cosas distintas, ambas
tienen razón en su contexto, y nadie lo ha escrito.

- **Solo entra en el glosario el término que está en disputa o que aparece en un informe de
  dirección.** Un glosario de 800 términos es un cementerio; uno de 30 se lee.
- **Si dos áreas necesitan definiciones distintas, son dos términos con dos nombres**
  (`cliente_activo_ventas`, `cliente_activo_facturacion`), no un término ambiguo. Forzar una
  definición única donde el negocio tiene dos realidades produce una definición que nadie usa.
- **Cada término tiene dueño de negocio y fecha de acuerdo.**
- **El glosario se enlaza con las columnas y las métricas reales.** Un término que no apunta a
  ningún activo es una opinión.
- **La definición canónica de la métrica calculable vive en el modelo**
  (`data-warehouse-modeling-standards`), no aquí. El glosario dice **qué significa**; el modelo
  dice **cómo se calcula**. Duplicar el cálculo en el glosario garantiza que diverjan.

## 3. Dimensiones de calidad y dónde se comprueban

### 3.1 Las seis dimensiones y su aserción

Solo sirven si se traducen a algo ejecutable. La que no se traduce, se borra del programa.

| Dimensión | Pregunta | Aserción ejecutable típica |
|---|---|---|
| **Completitud** | ¿Está todo lo que debería? | No nulos en columnas críticas; recuento de filas dentro de banda; **0 filas es fallo, no éxito**; ausencia de huecos en la serie de particiones |
| **Unicidad** | ¿Hay duplicados? | Unicidad de la clave declarada (la del grano; ver `data-warehouse-modeling-standards`) |
| **Validez** | ¿Los valores son admisibles? | Tipos, rangos, formatos (correo, IBAN, código postal), valores dentro del catálogo permitido |
| **Consistencia** | ¿Cuadra entre sitios? | Integridad referencial; suma agregada = suma del detalle; la misma métrica calculada por dos caminos coincide |
| **Oportunidad** | ¿Está a tiempo? | Antigüedad del dato más reciente frente al SLA de frescura del contrato |
| **Exactitud** | ¿Refleja la realidad? | **La única que no se comprueba sola**: exige reconciliación con el sistema origen o con una fuente externa, y muestreo humano. No la finjas con reglas sintácticas |

**La exactitud es la dimensión honesta.** Todas las demás se pueden verificar dentro del sistema;
la exactitud solo se verifica contra el mundo. Un cuadro de mando de calidad en verde no dice que
el dato sea correcto: dice que pasa las reglas que alguien escribió.

### 3.2 Dónde se comprueba

Tres puntos, y los tres hacen falta:

1. **En el origen** (validación de entrada en el sistema que genera el dato). **El más barato y el
   más ignorado**, porque exige negociar con un equipo que no es el tuyo. Un campo obligatorio en
   el formulario evita diez reglas aguas abajo y una corrección imposible tres años después.
2. **En el pipeline** (aserciones bloqueantes antes de publicar). Es donde se **detiene** el dato
   malo. **La mecánica es de `data-engineering-standards`**; aquí la política: qué es bloqueante,
   qué es aviso y quién puede cambiar esa clasificación.
3. **En el consumo** (reconciliaciones y cuadres sobre lo publicado). Detecta lo que las reglas no
   previeron y lo que se rompió entre capas.

**Comprobar solo al final es descubrir tarde, y tarde significa después de que alguien decidiera.**
El coste de un dato malo crece con la distancia desde el origen: en el origen se corrige; en el
pipeline se detiene; en el consumo ya se ha usado, y hay que avisar, recalcular y explicar.

### 3.3 Disciplina de las reglas

- **Cada aserción tiene dueño y motivo.** Una regla sin motivo escrito no se puede jubilar, porque
  nadie sabe si sigue haciendo falta.
- **Dos severidades, no cinco**: **bloqueante** (detiene la publicación) o **aviso** (se contabiliza
  y se revisa). Cinco niveles solo sirven para que nadie sepa qué hacer.
- **La regla de aviso que nadie mira se borra.** El ruido de calidad entrena al equipo a ignorar
  las alertas de calidad, y esa es una pérdida permanente.
- **Rojo permanente = regla rota o dato roto; ninguna de las dos se tolera.** Una comprobación en
  rojo aceptada durante un mes ha dejado de ser una comprobación.
- **Prohibido el "porcentaje de calidad" como cifra de gestión**: es una media de reglas
  heterogéneas que sube escribiendo reglas fáciles. Mide cobertura de contratos y tiempos (§6).

## 4. Gates

Estos gates rompen el build o bloquean la publicación. En orden de coste creciente.

### 4.1 Gates de CI (repositorio)

1. **Todo conjunto de datos publicado tiene dueño declarado en el código** (`owner:` en el
   metadato del modelo o del contrato). Sin dueño, no mergea.
2. **Todo conjunto de datos publicado tiene clasificación declarada** (§5.1).
3. **El contrato valida contra su esquema** (ODCS u homólogo) y **coincide con el esquema real**
   del artefacto que produce.
4. **Cambio incompatible de contrato** (columna eliminada/renombrada, tipo cambiado, grano
   cambiado, semántica cambiada) **rompe el build** salvo aprobación registrada del dueño y de los
   consumidores conocidos.
5. **Toda regla de calidad nueva declara dueño, severidad y motivo.**
6. **Términos del glosario referenciados existen** y apuntan a un activo real.
7. **Dependencias fijadas por hash** en cualquier entorno con credenciales del almacén (§5.2).

### 4.2 Gates de ejecución (publicación)

8. **Aserciones bloqueantes en verde** antes de publicar la capa de consumo. **Publicar datos
   malos es peor que no publicar** — la ejecución de estas comprobaciones es de
   `data-engineering-standards`; que existan y con qué severidad, de aquí.
9. **Frescura dentro del SLA del contrato**, comprobada **antes** de transformar y **después** de
   publicar.
10. **Recuento dentro de banda**, con **0 filas tratado explícitamente como fallo**.
11. **Cuadre de la métrica canónica** entre el hecho atómico y cualquier agregado publicado.

### 4.3 Gate de proceso — incidentes de dato

12. **Todo conjunto de datos con SLA publicado tiene guardia asignada.** Si nadie responde fuera
    de horario, **no se publica un SLA fuera de horario**: un SLA sin guardia es una mentira
    documentada.
13. **Todo incidente de dato de severidad alta produce notificación a los consumidores conocidos**
    (el linaje sirve para esto o no sirve para nada) y **postmortem sin culpa** con acciones con
    dueño y fecha. El proceso es de `incident-management-standards`; lo específico del dato es:

**Severidad de un incidente de dato** — la matriz genérica de incidentes no encaja, porque aquí el
sistema está verde:

| Sev | Criterio |
|---|---|
| **1** | Dato incorrecto **ya consumido** para una decisión externa, regulatoria o financiera; o publicado a clientes |
| **2** | Dato incorrecto o ausente en un activo certificado, aún no consumido para una decisión conocida |
| **3** | Incumplimiento de SLA de frescura sin corrupción del dato |
| **4** | Degradación en activo no certificado |

**El fallo silencioso es peor que la caída.** Una caída se ve, se escala sola y genera urgencia; una
tabla que lleva tres semanas sirviendo datos de hace tres semanas se descubre en un comité de
dirección, y para entonces se han tomado decisiones sobre ella. Consecuencias operativas
obligatorias:

- **Alerta por ausencia, no solo por error**: "no ha llegado nada" tiene que disparar igual que
  "ha fallado".
- **Comunicar la corrección es parte del arreglo.** Corregir en silencio un dato que alguien ya usó
  es la forma más eficiente de destruir la confianza en la plataforma. **La confianza se pierde por
  silencio, no por errores.**
- **Marcar el dato como sospechoso mientras dura el incidente**, visible en el punto de consumo
  (ver `analytics-bi-standards` §"calidad percibida"), no en un canal que el consumidor no lee.

## 5. Seguridad, clasificación y ciclo de vida

### 5.1 Clasificación

Cuatro niveles, no más. Cinco niveles producen debates y ninguna decisión:

| Nivel | Definición operativa | Consecuencia de control |
|---|---|---|
| **Público** | Puede publicarse fuera sin daño | Ninguna restricción |
| **Interno** | Por defecto de todo lo corporativo | Acceso autenticado; sin restricción por rol |
| **Confidencial** | Su divulgación causa daño (comercial, contractual, competitivo) | Acceso por rol justificado; cifrado; auditoría de acceso |
| **Restringido** | Dato personal sensible, secretos, dato regulado | Mínimo privilegio estricto, acceso nominal y auditado, seguridad a nivel de fila/columna, retención acotada |

Reglas:
- **La clasificación es un atributo del dato, no del sistema.** Copiarlo a otro sitio no lo
  desclasifica; **la clasificación viaja con la copia**, incluidos extractos de BI y hojas de
  cálculo — que es exactamente donde se evapora (ver `analytics-bi-standards`).
- **Clasificar es un acto de negocio, lo hace el dueño**, no el equipo de plataforma ni un
  clasificador automático. La detección automática de PII **propone**; el dueño **decide**.
- **La clasificación determina el control de acceso, no al revés.** Si el nivel no cambia ningún
  permiso, no estás clasificando: estás etiquetando.
- **Sin clasificar = interno como mínimo**, nunca "público por defecto".
- El dato personal hereda además todo `privacy-engineering-standards`; **la base legal, el
  tratamiento, la DPIA y el borrado del sujeto son suyos, no de aquí.**

### 5.2 Seguridad del propio programa de calidad

Las herramientas de calidad son **el objetivo más rentable de la cadena de suministro de datos**,
porque por definición tienen credenciales de lectura de todo el almacén.

- **Precedente vivo, no hipótesis**: `elementary-data` **0.23.3** se publicó en PyPI el
  **24-abr-2026** con un *infostealer*, tras una inyección de script en un workflow de GitHub
  Actions disparado por comentario de PR. El *payload* iba en un fichero `.pth`, que Python ejecuta
  **al arrancar el intérprete**, y robaba claves SSH, credenciales de AWS/GCP/Azure, secretos de
  Kubernetes y ficheros de configuración. Se publicó también imagen en GHCR con etiqueta `latest`.
  **Corregido en 0.23.4.** Mismo patrón en `trivy` (mar-2026), LiteLLM (mar-2026) y
  `durabletask` (may-2026).
- **Derivas obligatorias**: fijado por hash y por *digest* de imagen; **nunca `latest`**; ventana de
  cuarentena de días antes de adoptar una versión recién publicada en entornos con credenciales de
  producción; el ejecutor de la herramienta de calidad **no tiene credenciales de más de un
  entorno**; identidad de solo lectura, por esquema, distinta de la del pipeline.
- **Los resultados de calidad son datos sensibles**: un mensaje de fallo que imprime la fila
  infractora es una fuga de PII en un log que suele estar menos protegido que el almacén. Registra
  la clave o el recuento, **nunca el contenido**.
- **El catálogo es un mapa del tesoro**: contiene nombres de tablas, columnas, descripciones y
  perfiles estadísticos (a veces valores de ejemplo). Trátalo como sistema de nivel confidencial,
  con autenticación corporativa y sin acceso anónimo interno.

### 5.3 Retención y ciclo de vida

- **Todo conjunto de datos tiene periodo de retención declarado en su contrato.** "Para siempre" es
  una decisión válida que alguien tiene que firmar, no un valor por defecto.
- **Particiona por fecha para poder borrar.** Una retención que exige un `DELETE` masivo sobre una
  tabla de miles de millones de filas no se aplicará nunca.
- **La retención del dato personal, el borrado del sujeto y las excepciones legales son de
  `privacy-engineering-standards`.** Aquí solo el ciclo de vida del activo: creación, certificación,
  degradación, retirada.
- **Retirada activa**: conjunto de datos sin consumo medido durante un trimestre → se marca, se
  comunica y se retira. **El inventario de datos crece por acumulación por defecto**, y cada tabla
  viva es superficie de brecha, coste de almacenamiento y una fuente más de contradicción.
- **La copia no gobernada es el fallo real**: extractos, `SELECT *` a CSV, hojas de cálculo
  compartidas y bases de datos "temporales" de análisis. Ningún catálogo las ve. La mitigación no
  es tecnológica: es dar acceso gobernado suficientemente cómodo para que copiar no compense.

## 6. Métricas del programa

Solo métricas que cambian una decisión. Cada una lleva umbral y responsable.

| Métrica | Qué decide | Trampa |
|---|---|---|
| **Cobertura de propiedad** (% de activos certificados con dueño nominal) | Dónde falta lo único imprescindible | Contar "el equipo X" como dueño |
| **Cobertura de contratos** (% de activos publicados con contrato completo: esquema+semántica+SLA+dueño) | Prioridad de trabajo del trimestre | Contar contratos que solo tienen esquema |
| **Tiempo de detección** (incidente → alguien lo sabe) | Si tus comprobaciones sirven. **Si el consumidor lo detecta antes que tú, la métrica es "infinito"** y ese es el número honesto | Medirlo solo sobre los que detectó el sistema |
| **Tiempo de resolución** (detección → dato correcto publicado **y comunicado**) | Dimensionamiento del equipo y de la guardia | Cerrar el incidente antes de comunicar |
| **Incidentes por consumidor afectado** | Prioriza por daño real, no por número de fallos | Ignorar que un activo con 200 consumidores pesa distinto que uno con 2 |
| **Incumplimientos de SLA de frescura por activo** | Si el SLA prometido es realista o hay que renegociarlo | Bajar el SLA en vez de arreglar el pipeline y llamarlo mejora |
| **Reglas de aviso ignoradas** (en rojo >30 días sin acción) | Qué borrar del programa | Dejarlas "por si acaso" |

**Métricas explícitamente prohibidas por vanidad**: número de activos catalogados, número de
términos del glosario, número de reglas de calidad, "porcentaje de calidad" agregado, número de
usuarios del catálogo. Todas suben trabajando y ninguna cambia una decisión.

**Prueba definitiva del programa**, que ninguna herramienta contesta: *¿cuánto tarda una persona
nueva en encontrar el dato correcto y saber si puede fiarse de él, sin preguntar a nadie?* Si son
días, no tienes gobierno: tienes documentación.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisión trimestral de licencias y propiedad de las piezas del *stack* de calidad
  y catálogo (este segmento cambia de dueño y de licencia sin cambiar de nombre); revisión
  semestral de la lista de activos certificados y de los contratos vigentes.
- **ADR obligatorio** para: adoptar catálogo, adoptar herramienta de calidad separada del pipeline,
  federar la propiedad, adoptar una especificación de contrato, y fijar los niveles de
  clasificación.
- **Lo que se gobierna se acota deliberadamente**: define el conjunto de activos certificados y
  deja el resto visible pero marcado como no certificado. Prometer gobierno sobre todo el
  patrimonio de datos es la promesa que hunde los programas.

**PROHIBIDO**
- ❌ **Comprar o desplegar un catálogo antes de nombrar dueños.** Secuencia invertida canónica.
- ❌ Dueño que es un departamento, un equipo o "el área de datos" en lugar de una persona.
- ❌ Que el equipo de plataforma figure como dueño de los datos de negocio.
- ❌ Contrato de datos que solo tiene esquema, o que no vive versionado en el repositorio.
- ❌ Contrato cuya ruptura no rompe nada.
- ❌ Publicar un SLA de frescura sin guardia detrás.
- ❌ Tratar "0 filas" como ejecución correcta.
- ❌ Corregir en silencio un dato ya consumido; cerrar un incidente sin comunicar a los consumidores.
- ❌ Regla de calidad sin dueño, sin motivo o en rojo permanente tolerado.
- ❌ Más de dos severidades de aserción.
- ❌ "Porcentaje de calidad" agregado como métrica de gestión.
- ❌ Métricas de vanidad (activos catalogados, términos de glosario, reglas escritas).
- ❌ Linaje introducido a mano, o presentar un linaje parcial como completo y decidir borrados con él.
- ❌ Glosario enciclopédico; o el mismo término con dos significados y un solo nombre.
- ❌ Duplicar el **cálculo** de una métrica en el glosario o en el catálogo: la definición canónica es
  de `data-warehouse-modeling-standards`.
- ❌ Activo publicado sin clasificación, o "público" como valor por defecto.
- ❌ Clasificación que no cambia ningún permiso: eso es etiquetar, no clasificar.
- ❌ Federar la propiedad sin plataforma self-service previa ni capacidad de ingeniería en el dominio.
- ❌ Llamar "malla de datos" a repartir tablas sin repartir presupuesto ni capacidad.
- ❌ **Amundsen en despliegues nuevos** (sin releases desde jun-2025, sin commits en `main` desde
  abr-2025).
- ❌ Presentar Unity Catalog OSS como equivalente al Unity Catalog de Databricks.
- ❌ Introducir Soda Core donde la política exige licencia OSI (es **ELv2**, *source-available*).
- ❌ `dbt-expectations` en proyectos nuevos (sin mantenimiento).
- ❌ Dependencias sin fijar por hash/digest, o etiqueta `latest`, en cualquier entorno con
  credenciales del almacén (§5.2).
- ❌ Imprimir filas infractoras en logs de calidad.
- ❌ Conjunto de datos sin retención declarada; capa cruda "para siempre" sin firma.
- ❌ Comité de gobierno que solo produce diapositivas: si no cambia decisiones, se disuelve.
- ❌ Fijar versiones, licencias, propiedad o cifras de adopción de memoria (§8).

## 8. Verificación web obligatoria

Los datos de §2 y §5 son de **agosto de 2026**. Antes de fijar nada en un entregable, verifica:

1. **Catálogos**: actividad real (releases y commits, no la web del proyecto) de **OpenMetadata**
   (1.13.x y el estado de la 2.0), **DataHub** (v1.6.x), **Apache Atlas** (2.6.0 estaba en rc) y
   **Amundsen** (parado desde 2025 — confirma antes de descartarlo definitivamente). **Unity
   Catalog OSS**: nivel en LF AI & Data (era *sandbox*), estabilidad de API y qué capacidades de
   gobierno siguen siendo exclusivas del producto Databricks.
2. **Calidad**: tutela de **GX Core** por Fivetran tras el anuncio de may-2026 y qué implica para
   la licencia y la hoja de ruta; estado post-adquisición de **GX Cloud** por FICO; licencia
   vigente de **Soda Core** (ELv2 verificado verbatim en su `LICENSE`; comprueba si ha vuelto a
   cambiar); actividad de **Elementary**; y **la licencia y el posicionamiento de Evidently**.
3. **Cadena de suministro**: antes de añadir **cualquier** paquete a un entorno con credenciales del
   almacén, comprueba compromisos recientes (precedentes: `elementary-data` abr-2026, `trivy`
   mar-2026, LiteLLM mar-2026, `durabletask` may-2026) y publicaciones de las últimas 72 horas.
4. **Contratos**: versión vigente de **ODCS** (a ago-2026 la documentación decía v3.1.0 y el
   repositorio v3.0.2 — resuelve la discrepancia contra el repositorio, no contra un blog), estado
   de **ODPS**, y si la armonización con la Data Contract Specification ha producido algo real.
5. **Malla de datos**: si ha aparecido evidencia nueva —a favor o en contra— más allá del material
   de proveedor y de las retrospectivas de 2026.
6. **Proveedores comerciales**: movimientos de Collibra, Alation, Informatica y Atlan (adquisiciones
   y cambios de modelo son frecuentes) y la edición vigente del cuadrante de Gartner si vas a
   citarlo.

**Huecos declarados de esta revisión** (no rellenar de memoria):
- **Evidently**: **licencia no verificada en crudo** (no se leyó su `LICENSE`) ni su modelo
  comercial actual. No afirmes "Apache 2.0" sin comprobarlo.
- **DataHub**: no verificada su **gobernanza formal** (si está bajo fundación o es proyecto de
  empresa) ni el reparto exacto OSS/Cloud de funcionalidades de gobierno.
- **OpenMetadata 2.0**: solo verificado que existe un `2.0.0-rc1` de jul-2026; **no verificado** si
  ha llegado a estable ni si trae cambios incompatibles.
- **Soda**: verificada la licencia ELv2 del código; **no verificado** su modelo de precio comercial
  ni la fecha exacta del relicenciamiento (las fuentes secundarias dan 2023, 2024 y ene-2026 —
  contradictorias entre sí).
- **Collibra / Alation / Atlan / Informatica**: **precios no verificados**; las cifras que circulan
  proceden de comparativas escritas por competidores. No cites importes.
- **ODCS**: las cifras de adopción son **autodeclaradas por el propio proyecto**; no hay dato
  independiente. No verificado el número de herramientas con soporte real de importación/exportación.
- **Apache Atlas 2.6.0**: verificado solo como *release candidate*; no verificada su publicación
  final.
- No verificados **Purview, Dataplex ni SageMaker/DataZone Catalog** en esta revisión.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
