---
name: search-engines-standards
description: Text search and document indexing engines as infrastructure. Use when deciding between PostgreSQL full-text and a search cluster, comparing Elasticsearch, OpenSearch, Meilisearch, Typesense, Manticore, Vespa, Solr or Quickwit and their licences (Elastic License 2.0, SSPL, AGPLv3, BUSL enterprise editions, GPL), writing elasticsearch.yml, opensearch.yml, solrconfig.xml or a managed-schema, designing an explicit index mapping instead of dynamic mapping, analyzers, tokenizers, ascii folding and per-language stemming including Spanish, keyword versus text fields, the reindex API and index aliases for zero-downtime schema change, relevance tuning with field boosting, synonyms and judgment lists, shard and replica sizing and the too-many-small-shards trap, index lifecycle management with hot/warm/cold tiers, snapshot repositories and restore, major-version upgrades that force a reindex, deep pagination with search_after, wildcard-prefix and deep-aggregation query cost, or a search endpoint exposed to the internet without authentication or TLS.
---

# Estándares de motores de búsqueda de texto

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **elegir, modelar, operar, ajustar y asegurar** un motor de búsqueda de texto e indexación
documental: la decisión previa de si hace falta uno, la elección de producto **y de licencia**, el
modelado del índice y los analizadores, la relevancia y su medición, la operación del cluster
(shards, réplicas, ciclo de vida, snapshots, upgrades) y el rendimiento de las consultas.

Triggers: "buscador interno", "búsqueda del catálogo", "autocompletado", "facetas", "el buscador
devuelve cualquier cosa", "ajustar la relevancia", "sinónimos", "stemming", "acentos y búsqueda",
"analizador en español", `elasticsearch.yml`, `opensearch.yml`, `solrconfig.xml`, `managed-schema`,
"mapeo dinámico", "mapping explícito", "`keyword` o `text`", "reindexar", "alias de índice",
"demasiados shards", "shards pequeños", "ILM", "hot/warm/cold", "snapshot repository", "restaurar un
índice", "upgrade de versión mayor", "paginación profunda", `search_after`, "comodín al principio",
"agregación profunda", "licencia de Elasticsearch", "OpenSearch", "Meilisearch", "Typesense",
"Manticore", "Vespa", "Solr", "Quickwit", "el buscador está expuesto".

**Tesis del dominio**: **un índice de búsqueda no es una tabla, y reindexar es la operación normal,
no la excepción.** Un mapeo es inmutable en lo esencial: cambiar el tipo de un campo, su analizador o
su tokenización obliga a reconstruir el índice entero. Todo lo demás de esta skill —alias, ILM,
versionado, capacidad— existe para que reindexar sea barato y aburrido. **Si reindexar te da miedo,
tu diseño está mal.**

**No aplica**:

- `data-platform-standards` — **skill madre**: PostgreSQL, **su full-text (`tsvector`, GIN,
  `websearch_to_tsquery`) y JSONB**, y el principio rector **"un almacén por necesidad, no por
  moda"**. **Arbitraje**: el criterio de si PostgreSQL te basta (§2.1) se decide aquí, pero **la
  implementación del full-text en PostgreSQL es suya**. Si la respuesta es "sí, te basta", cierras
  esta skill y trabajas allí.
- `observability-standards` — **Loki, el pipeline de logs, OTel, retención y cardinalidad son
  suyos**, y su criterio explícito es no meter Elastic/OpenSearch sin necesidad real de búsqueda
  full-text sobre logs. Aquí **solo el motor** cuando ya se ha decidido que se usa un buscador:
  modelado del índice, shards, ILM, snapshots. **La decisión de qué backend de logs usar es suya.**
- `detection-engineering-standards` — **el SIEM: reglas Sigma, detecciones, normalización ECS/OCSF,
  triaje y cobertura ATT&CK son suyos**, incluida la capa Elastic Security sobre Elasticsearch. Aquí
  el motor por debajo: cluster, índices, retención física, rendimiento. **Frontera por propósito: si
  el artefacto es una regla o una alerta, es suyo; si es un shard o un snapshot, es de aquí.**
- **`rag-standards`** — recuperación para alimentar a un LLM: chunking, embeddings, **recuperación
  híbrida densa + léxica y su fusión (RRF)**, reranking, `recall@k`. **La búsqueda híbrida cruza tres
  skills y la regla es única: el criterio de fusión vive en `rag-standards` para el caso RAG; aquí
  solo la parte léxica y la implementación de la fusión dentro del motor de texto cuando el motor la
  ofrece nativamente. No se duplica.**
- `vector-db-standards` — el motor vectorial como infraestructura: memoria del índice ANN,
  cuantización, filtrado previo/posterior, snapshots, multi-tenancy, usos no-RAG. **Varios motores de
  texto también hacen kNN**: si el cluster ya existe por su capacidad léxica, añadir vectores es de
  aquí; si el despliegue se justifica **por** los vectores, es de allí.
- `nosql-standards` — **frontera muy próxima: un motor documental y un buscador se parecen mucho por
  fuera y no son la misma pieza.** Regla: si el acceso es **por clave o por patrón conocido de
  acceso, con lectura consistente y el dato es la fuente de verdad**, es un almacén documental (suyo).
  Si el acceso es **por texto libre con ranking por relevancia, facetas y agregaciones sobre una
  proyección derivada**, es un buscador (aquí). **Un buscador no es tu base de datos primaria** (§3.1).
- `data-engineering-standards` (el pipeline que alimenta el índice), `streaming-cdc-standards`
  (**Ola 4, planificada**: CDC desde la fuente de verdad hacia el índice),
  `data-governance-quality-standards`, `analytics-bi-standards`, `lakehouse-standards`,
  `graph-db-standards`, `timeseries-db-standards`, `message-brokers-standards`,
  `caching-cdn-standards` (**Ola 4, planificadas**).
- `privacy-engineering-standards`: **dato personal dentro del índice, su retención y el derecho de
  supresión** — un índice de búsqueda es una copia más del dato (§5.4).
- `api-design-standards`: el contrato de tu API de búsqueda hacia fuera. **No expongas la query DSL
  del motor a tus clientes** (§5.2).
- `kubernetes-standards` (StatefulSets, operadores), `linux-storage-standards` (el bloque y el
  planificador de E/S bajo el motor), `object-storage-standards` (repositorio de snapshots),
  `backup-recovery-standards`, `bcdr-standards`, `sre-practice-standards`, `iac-standards`,
  `cicd-standards`.
- `identity-access-management-standards` (SSO/OIDC contra el motor y su panel),
  `secrets-management-standards`, `cryptography-pki-standards` (TLS y certificados de transporte),
  `firewall-policy-standards` (exponer el puerto), `networking-standards`,
  `vulnerability-management-standards` (CVE y EOL), `grc-compliance-standards`.
- `aws-standards` / `azure-standards` / `gcp-standards`: los servicios gestionados equivalentes.
- Skills de lenguaje: los clientes oficiales y su versionado.

## 2. Decisiones por defecto

> Verificar versión, **licencia** y estado por web antes de fijar nada (§8). **En este sector la
> licencia ha cambiado varias veces y es el dato que decide**: lo verificado aquí es de agosto de
> 2026, contra ficheros `LICENSE` de repositorio y feeds Atom de releases.

### 2.1 La pregunta previa: ¿te basta el full-text de PostgreSQL?

**Para la mayoría de catálogos, buscadores internos, documentación y back-offices, sí.** Y evita
operar un cluster entero, con su ciclo de vida, su respaldo, sus upgrades y su superficie de ataque.

| Necesidad | ¿PostgreSQL basta? |
|---|---|
| Buscar en un catálogo de miles o pocos millones de filas, con filtros SQL | **Sí.** `tsvector` + índice GIN. Y el filtro por permisos, precio o estado es un `WHERE` transaccional y consistente |
| Búsqueda que debe estar **inmediatamente** consistente con la escritura | **Sí, y es su mayor ventaja**: no hay retraso de indexación ni pipeline que se caiga |
| El dato buscable ya vive en PostgreSQL y no hay otra fuente | **Sí.** Añadir un buscador es añadir una copia, un pipeline y un modo de fallo |
| Facetas y agregaciones ligeras | **Sí**, con `GROUP BY` mientras el volumen lo permita |
| Fuzzy y sugerencias básicas | **Sí**: `pg_trgm`, `unaccent` |
| Relevancia realmente ajustable, boosting por campo, sinónimos gestionados | **No.** `ts_rank` es rudimentario y no se ajusta como BM25 |
| Facetas y agregaciones sobre decenas de millones de documentos con latencia baja | **No** |
| Volumen de consulta muy alto que compite con la carga OLTP | **No** (o réplica dedicada como paso intermedio) |
| Corpus de documentos, no de filas: PDFs, adjuntos, texto largo multilingüe | **No** |
| Autocompletado con latencia de decenas de ms y tolerancia a erratas | **No** salvo casos simples |

**Regla de decisión**: **empieza en PostgreSQL. Da el salto cuando midas que no llega** —latencia,
carga sobre el OLTP, o una necesidad de relevancia/faceting que `ts_rank` no cubre— **y escríbelo en
un ADR con el coste operativo asumido.** Hay un paso intermedio que casi nadie considera: **una
réplica de lectura de PostgreSQL dedicada a búsqueda** resuelve el problema de contención sin
introducir una pieza nueva. (Extensiones tipo ParadeDB/`pg_search` traen BM25 a PostgreSQL: son una
opción, con su propio coste de dependencia — verifícalas, §8.)

### 2.2 Elección de motor — y el lío de licencias

**Esta es la decisión principal del dominio, y es jurídica antes que técnica.** Estado verificado a
agosto de 2026:

| Motor | Versión | Licencia (verificada) | Criterio |
|---|---|---|---|
| **Elasticsearch** | **9.4.4** (jul-2026); mantenidas 9.3.8 y 8.19.19 | **Triple**, verbatim del `LICENSE.txt`: *"a triple license under the 'GNU Affero General Public License v3.0 only', 'the Server Side Public License, v 1', and the 'Elastic License 2.0'"* | Ecosistema y capacidades máximas. **AGPLv3 se añadió como tercera opción a partir de 8.16** tras el episodio SSPL/ELv2 de 2021. ⚠️ **Ver la advertencia sobre binarios abajo** |
| **OpenSearch** | **3.7.0** (jun-2026); LTS **2.19.6** | **Apache-2.0**, sin ambigüedad | **Default cuando la licencia importa.** Gobernanza: propiedad transferida de Amazon a la **OpenSearch Software Foundation**, proyecto de la **Linux Foundation**, anunciada el **16-sep-2024**. Es el motor con la gobernanza más limpia del sector |
| **Meilisearch** | **1.52.0** (ago-2026) | ⚠️ **`MIT AND BUSL-1.1`** — verbatim del `LICENSE`: la **Enterprise Edition** (ficheros bajo `enterprise_editions`) es **BSL 1.1**, uso en producción **solo con contrato comercial**; el resto MIT. Change License MIT a 4 años | Buscador de producto, muy buena experiencia de desarrollo. **Ya no es "MIT y punto": audita qué módulos usas.** Muy activo |
| **Typesense** | **30.2** (abr-2026); rama `v31` activa (jul-2026) | **GPL-3.0** | Alternativa ligera, tipada, sin JVM. **GPL-3 es una decisión consciente** si lo integras o distribuyes |
| **Manticore Search** | **28.6.6** (jul-2026) | **GPL-3.0** | Heredero de Sphinx. Muy activo, muy eficiente en recursos; ecosistema pequeño |
| **Vespa** | **8.731.x** (jul-2026) | **Apache-2.0** | Búsqueda + ranking con ML + vectores en un solo motor, a gran escala. **Curva de aprendizaje y coste operativo altos**: se justifica por relevancia avanzada, no por buscar texto |
| **Apache Solr** | **10.0.0** (mar-2026); 9.11-beta | **Apache-2.0** (ASF) | Maduro, gobernanza de fundación. Ecosistema en declive frente a ES/OS; elección razonable si ya lo operas |
| **Quickwit** | **0.9.0** (jul-2026), repo activo en ago-2026 | **Apache-2.0** | **Adquirido por Datadog (ene-2025)** y relicenciado a Apache-2.0; **no está abandonado**, sigue publicando. Nicho: búsqueda sobre object storage para **logs y trazas** — y ahí la decisión de backend es de `observability-standards` |

**⚠️ La advertencia que decide de verdad en Elasticsearch**: el `LICENSE.txt` del repositorio es
triple, pero **hay reportes consistentes de que las distribuciones binarias oficiales se entregan
bajo Elastic License 2.0**, no bajo AGPLv3. **Si tu razón para elegir Elasticsearch es "ya es open
source otra vez", verifica el fichero de licencia del artefacto concreto que descargas o de la imagen
que despliegas, no el del repositorio.** Es un hueco declarado (§8): no lo des por resuelto.

**Criterio por defecto**:

1. **No usas nada**: PostgreSQL (§2.1).
2. **Necesitas un buscador y la licencia importa** (SaaS, producto, distribución, política de
   empresa): **OpenSearch**. Apache-2.0 y fundación neutral.
3. **Necesitas el ecosistema Elastic y aceptas ELv2 en los binarios**: **Elasticsearch**.
4. **Buscador de producto, equipo pequeño, sin JVM**: **Meilisearch** (auditando la frontera BSL) o
   **Typesense** (aceptando GPL-3).
5. **Relevancia avanzada con ML a gran escala**: **Vespa**, con ADR que reconozca su coste.
6. **Ya operas Solr**: no migres sin motivo.

**Vetado sin ADR firmado**: elegir un motor sin haber leído su fichero de licencia **este
trimestre**; asumir que un motor sigue teniendo la licencia que tenía la última vez que lo miraste.

## 3. Modelado del índice

### 3.1 Reglas fundacionales

- **El buscador no es la fuente de verdad.** Es una **proyección derivada** de un almacén durable.
  Consecuencia práctica: puedes borrar el índice entero y reconstruirlo; su respaldo es una
  optimización de RTO, no una necesidad de durabilidad. **Si no puedes reconstruir tu índice desde el
  origen, tienes un problema de arquitectura, no de búsqueda.**
- **Un índice se modela por consulta, no por entidad.** Desnormaliza: incrusta lo que la consulta
  necesita mostrar y filtrar. Las uniones son caras o inexistentes.
- **Todo índice se sirve tras un alias**, nunca por su nombre real. El alias es lo que hace posible
  reindexar y conmutar sin caída, y su ausencia es lo que convierte un cambio de mapeo en una
  ventana de mantenimiento.
- **Nombra los índices con versión** (`productos_v7`) y trata el mapeo como código versionado en el
  repositorio, revisado en PR.

### 3.2 Mapeo explícito — el mapeo dinámico en producción es una bomba

**Regla dura: mapeo explícito y `dynamic: strict` (o el equivalente de tu motor) en producción.**

Lo que hace el mapeo dinámico y por qué explota:

- **El tipo lo decide el primer documento que llega.** Un campo que llega como `"1"` se mapea a
  `text`; el siguiente documento con `1` numérico puede fallar o quedar inservible para rangos y
  ordenación. **El error aparece meses después, en un documento cualquiera, y ya no se puede
  arreglar sin reindexar.**
- **Explosión de campos**: un objeto con claves dinámicas (IDs, nombres de usuario, atributos
  libres) genera un campo nuevo por clave. El mapeo crece sin límite, el estado del cluster se
  hincha y **el cluster se degrada entero**. Usa tipos pensados para esto (`flattened`, pares
  clave/valor como *nested*) o normaliza a `[{clave, valor}]`.
- **Indexas lo que no buscas**: campos que nadie consulta cuestan espacio, memoria y tiempo de
  indexación. Declara `index: false` para lo que solo se muestra, y no almacenes el documento
  original completo si ya lo tienes en la fuente de verdad.

### 3.3 `keyword` frente a `text` — el error de modelado más frecuente

- **`text` se analiza**: se trocea, se normaliza, sirve para **buscar**. **No sirve** para agrupar,
  ordenar ni facetar de forma fiable.
- **`keyword` no se analiza**: es el valor exacto. Sirve para **filtrar, facetar, agregar y
  ordenar**. No sirve para buscar dentro.
- **Casi siempre quieres los dos**: el campo como `text` y un subcampo `keyword`. Modelarlo mal es
  la causa número uno de "las facetas salen troceadas" y de "no puedo ordenar por nombre".
- **Identificadores, SKUs, códigos, enums, estados, emails, rutas y etiquetas son `keyword`**, no
  `text`. Analizarlos rompe la búsqueda exacta que es justo lo que se quiere de ellos.

### 3.4 Analizadores, tokenización y stemming — y el español

Un analizador es **tokenizador + filtros**, y **el de indexación y el de consulta deben ser
coherentes**. Un desajuste aquí no da error: da cero resultados para consultas obviamente correctas.

Criterio para el español (y aplicable a cualquier idioma flexivo):

- **Un analizador por idioma, no uno para todo.** Un campo multilingüe con analizador inglés
  destroza la recuperación en español sin emitir un solo aviso. Si el corpus es multilingüe:
  **subcampo por idioma** (`titulo.es`, `titulo.en`) y detección de idioma en la ingesta.
- **Stemming**: los *stemmers* Snowball para español son **agresivos** y sobre-derivan (raíces
  distintas colapsan en la misma), lo que mete ruido. La variante ligera (*light Spanish*) suele dar
  mejor precisión en catálogos y nombres propios. **Elige midiendo (§4.2), no por defecto.**
- **Acentos**: `asciifolding` (o `unaccent`) es casi obligatorio —el usuario escribe "arbol"— pero
  **destruye distinciones reales**: `año`/`ano`, `papa`/`papá`, `esta`/`está`. **Patrón correcto: un
  campo plegado para recuperar y un campo sin plegar con más peso para desempatar**, de modo que la
  forma acentuada correcta gane en el ranking sin dejar de encontrar la sin acentuar.
- **Stopwords**: la lista estándar del español elimina `no` y `sin`. En un corpus donde la negación
  importa (clínico, legal, especificaciones técnicas) **eso invierte el significado de la consulta**.
  Revisa la lista; a menudo lo correcto es no usarla.
- **`ñ`, diéresis, mayúsculas, guiones y apóstrofos**: normalización explícita y probada, no
  heredada del ejemplo de un blog.
- **Ojo con la tokenización de referencias**: SKUs, matrículas, versiones (`v1.2.3`) y códigos con
  guiones se parten en trozos inútiles con el tokenizador estándar. Modélalos como `keyword` (§3.3)
  o con un tokenizador propio.
- **Números, fechas y unidades**: normaliza en la ingesta, no en la consulta.

**Cambiar un analizador exige reindexar.** No es un ajuste en caliente: es la operación de §3.5.

### 3.5 Reindexar es la operación normal

El procedimiento estándar, que debe estar automatizado y ensayado **antes** de necesitarlo:

```
1. crear   productos_v8  con el mapeo nuevo
2. poblar  productos_v8  (reindex desde v7, o desde la fuente de verdad — preferible)
3. doble escritura a v7 y v8 mientras dura el proceso
4. comparar: nº de documentos, y relevancia sobre el conjunto de juicios (§4.2)
5. conmutar el alias 'productos' de v7 a v8 (atómico)
6. dejar v7 disponible N días para rollback; borrar después
```

- **Reindexar desde la fuente de verdad es mejor que reindexar desde el índice viejo**: el índice
  viejo puede haber perdido información que el analizador anterior descartó.
- **Cronometra el reindexado completo.** Es tu RTO real y el límite de cuántos cambios de mapeo
  puedes permitirte por trimestre.
- **Un cambio de mapeo sin alias y sin plan de reindexado es una incidencia programada.**

## 4. Relevancia y gates

### 4.1 Ajuste de la relevancia

- **BM25 es el ranking por defecto de todos los motores serios**, y sus parámetros (saturación de
  frecuencia de término y normalización por longitud del documento) **rara vez son el problema**:
  antes de tocarlos, revisa analizadores, campos y pesos. Tocar BM25 primero es optimizar el último
  eslabón.
- **Boosting por campo** (título pesa más que cuerpo) es la palanca más efectiva y la primera que se
  prueba. **Se ajusta midiendo, no discutiendo en una reunión.**
- **Señales de negocio** (popularidad, novedad, stock, margen) se combinan con la relevancia textual
  de forma explícita y documentada. **Sepáralas del ranking textual**: mezclarlas hasta que nadie
  sepa por qué sale lo que sale es como mueren los buscadores.
- **Sinónimos**: gestiónalos como datos versionados, no como configuración suelta. **Aplícalos en
  consulta, no en indexación**, siempre que puedas: así cambiarlos no obliga a reindexar. Cuidado con
  los multi-palabra y con los sinónimos que amplían demasiado y arruinan la precisión.
- **Búsqueda híbrida (léxica + vectorial)**: la parte léxica es de esta skill, la vectorial de
  `vector-db-standards`, y **el criterio de fusión de `rag-standards`** cuando el destino es un LLM.
  Si tu motor implementa la fusión nativamente, úsala en vez de fusionar en la aplicación. **No la
  adoptes sin medir: para muchos catálogos, léxico bien analizado gana a híbrido mal medido.**

### 4.2 Cómo se evalúa la relevancia de verdad

**"A mí me sale bien" no es una medición.** Es el sesgo del que conoce el corpus consultando lo que
ya sabe que está.

- **Lista de juicios (*judgment list*)**: consultas reales de tus usuarios etiquetadas con qué
  documentos son relevantes y en qué grado. **50-200 consultas mínimas, versionadas en el
  repositorio, revisadas en PR como cualquier otro código.** Es el activo más valioso del sistema:
  sobrevive a cambios de motor, de mapeo y de equipo.
- **Sácalas de los logs de búsqueda**: las consultas más frecuentes, y sobre todo **las que dan cero
  resultados** y **aquellas en las que el usuario no hace clic en nada**. Ahí está tu backlog de
  relevancia entero, gratis.
- **Cobertura de bordes obligatoria**: erratas, sinónimos, singular/plural, con y sin acentos,
  identificadores y SKUs exactos, consultas de una sola letra, consultas larguísimas, cada idioma del
  corpus, y **consultas cuya respuesta correcta es "no hay nada"**.
- **Métricas offline** sobre esa lista, y **online** después (tasa de cero resultados, clics en las
  primeras posiciones, abandono, reformulación). **La métrica offline te dice si has roto algo; la
  online, si has mejorado.** La maquinaria de métricas de recuperación y su interpretación está en
  `rag-standards` §4.1.
- **Ningún cambio de relevancia entra sin comparación A/B contra la configuración actual.** Un ajuste
  que mejora tres consultas y empeora treinta es el resultado por defecto de tocar a ojo.

### 4.3 Gates que rompen el build

| # | Gate | Rompe si |
|---|---|---|
| 1 | Mapeo explícito versionado; **`dynamic: strict`** en producción | Hay mapeo dinámico permisivo |
| 2 | Todo índice se sirve **tras un alias** | Se consulta el índice por su nombre real |
| 3 | Analizador de indexación y de consulta **coherentes**, con prueba que lo verifica sobre casos reales | Divergen |
| 4 | **Evaluación de relevancia sobre la lista de juicios con umbral de no-regresión** si el diff toca mapeo, analizadores, sinónimos o pesos | Regresión |
| 5 | Prueba de casos de borde del idioma (acentos, plurales, erratas, SKUs) | Falla |
| 6 | **Reindexado completo ensayado y cronometrado** al menos una vez por trimestre | No ensayado |
| 7 | **Snapshot restaurado en entorno limpio y consultado**, con tiempo registrado | No se restaura |
| 8 | **Petición anónima al endpoint devuelve `401`/`403`**, y el transporte es TLS | Devuelve `200` |
| 9 | **Aislamiento entre tenants/roles**: un usuario no recupera documentos que no le corresponden | Fuga. **Innegociable** |
| 10 | Ninguna consulta de la aplicación usa comodín inicial ni paginación por `from`/`offset` profundo (§6.3) | Aparece una |
| 11 | Número de shards por índice justificado frente al tamaño real (§6.1) | Shards enanos o gigantes |
| 12 | **Revisión de licencia del motor y de sus plugins** registrada y vigente (§2.2) | Caducada |
| 13 | CVEs y EOL del motor (§5.3) | Crítica sin mitigar |

## 5. Seguridad

### 5.1 Autenticación y TLS: históricamente desactivados, y el resultado se conoce

**Los buscadores expuestos a Internet son una fuente crónica de fugas de datos**, con más de una
década de incidentes documentados. El patrón es siempre el mismo: un índice con datos reales,
alcanzable, sin autenticación, encontrado por escaneo masivo.

Estado verificado (ago-2026):

| Motor | Estado por defecto | Nota |
|---|---|---|
| **Elasticsearch** | Seguridad **autoconfigurada desde 8.0**, verbatim de la doc: *"Elasticsearch automatically enables security features on first startup when the node is not part of an existing cluster and none of the incompatible settings have been explicitly configured"* | **Léelo con cuidado: hay casos en los que la configuración automática se salta.** Verifícalo, no lo asumas |
| **OpenSearch** | Plugin de seguridad con **configuración de demo instalada automáticamente**, incluidos **certificados de demo**; desde 2.12 exige `OPENSEARCH_INITIAL_ADMIN_PASSWORD` | Hay auth, pero **con certificados de demo que hay que sustituir**. Un cluster en producción con los certificados de demo no está protegido |
| **Apache Solr** | **Sin autenticación por defecto** y escuchando en todas las interfaces. La seguridad se activa con `security.json`; **si `blockUnknown` no aparece, vale `false`, que equivale a no exigir autenticación** | El caso más peligroso de la lista. Solr ha acumulado incidentes de exposición y RCE |
| **Meilisearch / Typesense / Manticore** | Requieren clave configurada explícitamente; sin ella la instancia queda abierta | Meilisearch **no arranca protegido si no le pasas `--master-key`/`MEILI_MASTER_KEY`** |

**Reglas**:

- **Ningún buscador se expone a Internet.** Red privada, firewall por defecto-denegar
  (`firewall-policy-standards`). Si un cliente necesita buscar, **habla con tu API, no con el
  motor** (§5.2).
- **Autenticación y TLS obligatorios en todo entorno alcanzable por red**, incluido el transporte
  entre nodos y el panel de administración. Gate 8 de §4.3.
- **Sustituye los certificados de demo** antes de que el cluster tenga un solo documento real.
- Autorización por rol/índice/campo, con el mínimo privilegio: la aplicación que consulta **no
  necesita permisos de gestión del cluster**. Identidad y federación:
  `identity-access-management-standards`; la clave, en un gestor de secretos.

### 5.2 No expongas la query DSL

Dejar que el cliente envíe una consulta arbitraria al motor equivale a dejarle ejecutar SQL: puede
leer índices y campos que no le corresponden, y puede tumbar el cluster con una agregación profunda o
un comodín inicial (§6.3). **Tu API expone parámetros acotados y construye la consulta en servidor**
(`api-design-standards`). Toda entrada de usuario se escapa según la sintaxis del motor; una consulta
construida por concatenación de texto de usuario es inyección.

### 5.3 Superficie de ataque y parcheo

- El motor entra en el ciclo de parcheo como cualquier otra pieza. Precedentes verificados en 2026:
  **CVE-2026-63140** (aserción alcanzable: un usuario **autenticado con pocos privilegios** tumba el
  nodo con una consulta preparada; en cluster, una petición por nodo) y **CVE-2026-63144** (recursión
  no controlada), **ambos corregidos en Elasticsearch 8.19.19, 9.3.8 y 9.4.4** (jul-2026), junto con
  agotamiento de recursos vía ES|QL.
- **Lección de esas CVEs**: *"solo usuarios autenticados"* no es mitigación cuando el permiso mínimo
  de lectura basta. **Reduce quién tiene permiso de búsqueda y limita la complejidad de consulta.**
- Plugins y extensiones: superficie extra y freno a los upgrades. Cada plugin necesita justificación
  y revisión de licencia.
- SBOM, imágenes por digest, y seguimiento de EOL de la versión mayor
  (`vulnerability-management-standards`).

### 5.4 Dato personal en el índice

- **El índice es una copia del dato**: entra en el inventario, en la clasificación, en la retención y
  en el derecho de supresión (`privacy-engineering-standards`).
- **El borrado debe propagarse** al índice, a las réplicas, a los snapshots vigentes según su política
  y a las cachés. Un documento borrado del origen que sigue indexado se sigue devolviendo.
- **Los snapshots contienen el dato**: su retención y su cifrado son parte del plan de borrado.
- **Filtra por permisos en la consulta al motor, no después de recibir los resultados.** Filtrar
  después rompe el top-k y cualquier camino que olvide el filtro es una fuga (criterio compartido con
  `rag-standards` §5.1).
- **Los logs de búsqueda son dato personal**: contienen lo que la gente escribe. Retención acotada.

## 6. Operación y rendimiento

### 6.1 Shards y réplicas — el error clásico

**El error clásico es tener demasiados shards pequeños.** Cada shard es un índice invertido completo
con su coste fijo de memoria, ficheros, hilos y metadatos en el estado del cluster. Un cluster con
miles de shards enanos va lento, arranca despacio y se cae por presión de memoria en el nodo maestro
— **sin que ninguna consulta concreta parezca cara**.

- **Menos shards y más grandes** es el sesgo correcto. La consulta se abanica a todos los shards y
  el p99 lo marca el más lento: más shards **no** significa más rápido.
- **El número de shards primarios de un índice se fija al crearlo.** Cambiarlo exige reindexar (§3.5)
  o dividir/encoger. Piénsalo al diseñar.
- **Réplicas**: disponibilidad y capacidad de lectura. Cada réplica es una copia completa: cuesta
  disco y memoria. **Cero réplicas en producción es pérdida de datos garantizada** ante un fallo de
  nodo.
- **Índices por tiempo** (logs, eventos) en lugar de un índice gigante: hacen barato borrar por
  retención (borrar un índice es instantáneo; borrar por consulta es carísimo) y permiten el ciclo de
  vida de §6.2. Con *rollover* por tamaño o edad, no por intuición.
- **El tamaño objetivo por shard se mide en tu hardware con tus documentos.** Las cifras que circulan
  son heurísticas de la documentación de un motor concreto, en una versión concreta.
- **Roles de nodo separados** en cualquier cluster que importe: maestros dedicados (número impar, sin
  carga de datos), nodos de datos, nodos de coordinación/ingesta. Un maestro que también sirve
  consultas se cae cuando llega el pico.

### 6.2 Ciclo de vida, snapshots y upgrades

- **Ciclo de vida por temperatura** (caliente / templado / frío / congelado) para datos con patrón
  temporal: hardware caro solo para lo reciente. **Automatizado por política, no por cron artesanal.**
  El caso concreto de logs es de `observability-standards`.
- **Snapshots incrementales a repositorio de object storage**, versionado, cifrado y con inmutabilidad
  (`object-storage-standards`, `backup-recovery-standards`). **Un snapshot sin restore probado y
  cronometrado no existe** (gate 7).
- **Compatibilidad de snapshots entre versiones mayores es limitada**: un snapshot no siempre restaura
  en la versión que tienes hoy. Anota la versión con el snapshot.
- **Actualizaciones de versión mayor**: el punto duro del dominio. Suelen soportar leer índices de la
  mayor anterior, **pero no de dos atrás**. Consecuencia: **un índice viejo obliga a reindexar antes
  de poder saltar de versión**, y si nunca reindexas acumulas deuda hasta que un upgrade se vuelve un
  proyecto. **Reindexar periódicamente no es higiene opcional: es lo que mantiene el cluster
  actualizable.**
- Ensaya el upgrade en un entorno con datos representativos, con rollback definido, y **nunca saltes a
  una `.0` en producción** (criterio heredado de `data-platform-standards`).

### 6.3 Consultas caras — las que hay que prohibir

| Patrón | Por qué es caro | Alternativa |
|---|---|---|
| **Comodín al principio** (`*texto`) | Obliga a recorrer el diccionario de términos entero | Índice invertido de sufijos, n-gramas al indexar, o campo `keyword` normalizado |
| **Paginación profunda con `from`/`offset` grande** | Cada shard debe ordenar y devolver `from+size` resultados, y el coordinador fusionarlos: coste que crece con la profundidad, y **puede tumbar el nodo** | **`search_after`** (cursor sobre la clave de ordenación) para navegación; *scroll*/PIT o *point-in-time* para exportación masiva. **La paginación profunda casi siempre es un requisito de producto mal planteado**: nadie va a la página 400 |
| **Agregaciones profundas y de alta cardinalidad** | Memoria proporcional al número de *buckets*; agrupar por un campo casi único revienta el nodo | Limitar cardinalidad, precalcular, o mover la pregunta al almacén analítico |
| **Ordenar o agregar por un campo `text`** | Requiere estructuras de datos que se construyen en memoria y son enormes | Subcampo `keyword` (§3.3) |
| **Consultas con `script` en el camino caliente** | Se ejecutan por documento | Precalcular en la ingesta |
| **Consultas sin timeout ni límite** | Una sola puede degradar el cluster para todos | Timeouts, límites, *circuit breakers* y aislamiento de cargas |

**Caché**: los motores cachean a varios niveles (consulta, filtro, petición, y el *page cache* del
sistema operativo, que suele ser el más importante). Consecuencias: **deja RAM libre para el sistema
operativo en vez de dársela toda a la JVM**, y **las consultas con timestamps precisos —`now`, ahora
mismo— no cachean**: redondea las ventanas temporales y el ratio de acierto cambia radicalmente.

### 6.4 Frescura, observabilidad y runbook

- **El índice va con retraso respecto a la fuente de verdad**, y ese retraso es un requisito de
  producto: mídelo, ponle SLO si el negocio depende de él, y **alerta cuando el pipeline de
  indexación se para** — el fallo silencioso característico es un buscador que devuelve resultados
  perfectamente creíbles pero de hace tres días.
- Instrumenta (transporte y backend: `observability-standards`): salud del cluster y shards sin
  asignar, latencia p95/p99 de búsqueda **por tipo de consulta**, retraso de indexación, presión de
  memoria y pausas de GC, uso de disco (**un nodo que cruza el umbral de espacio se pone en solo
  lectura y la escritura muere en silencio**), rechazos por cola llena, **tasa de consultas con cero
  resultados** (métrica de producto, no de infraestructura) y consultas lentas.
- Runbook mínimo: shards sin asignar tras un reinicio; disco lleno y cluster en solo lectura; pipeline
  de indexación parado; consulta que degrada el cluster; nodo maestro inestable; reindexado a medias
  con el alias en el índice equivocado; snapshot que no restaura en la versión actual; buscador
  descubierto expuesto sin autenticación (**incidente de seguridad**:
  `incident-response-forensics-standards`).

## 7. Sostenibilidad y prohibiciones

**Cadencia de revisión: 3 meses** (la licencia y los CVEs mandan; el resto se mueve más despacio).

- Revisar: **licencia del motor y de sus plugins**, versión y EOL de la mayor, CVEs, y si la lista de
  juicios sigue representando el tráfico real de búsqueda.
- **La lista de juicios y el mapeo versionado son los activos que sobreviven al motor.** Si mañana
  migras de Elasticsearch a OpenSearch, son lo único que se conserva.
- Deuda consciente registrada: mapeo dinámico pendiente de cerrar, reindexado nunca ensayado,
  relevancia sin medir, certificados de demo aún en uso.

**PROHIBIDO**

- ❌ Desplegar un cluster de búsqueda sin haber comprobado que el full-text de PostgreSQL no llegaba,
  y sin ADR con el coste operativo asumido.
- ❌ **Elegir motor sin leer su fichero de licencia**, o asumir la licencia que tenía la última vez.
- ❌ Asumir que un binario de Elasticsearch te llega bajo AGPLv3 sin comprobar el artefacto (§2.2).
- ❌ Usar módulos Enterprise de Meilisearch en producción sin contrato comercial (BSL 1.1).
- ❌ **Mapeo dinámico permisivo en producción.** Ningún objeto de claves libres sin acotar.
- ❌ Modelar identificadores, SKUs, códigos, enums o emails como `text`.
- ❌ Ordenar, facetar o agregar sobre un campo `text`.
- ❌ Consultar un índice por su nombre real en vez de por un alias.
- ❌ Un solo analizador para un corpus multilingüe.
- ❌ Aplicar `asciifolding` sin campo sin plegar que desempate, o usar la lista de stopwords estándar
  del español en un corpus donde la negación importa.
- ❌ Divergencia entre analizador de indexación y de consulta.
- ❌ Cambiar mapeo, analizadores o sinónimos **sin evaluación de relevancia** contra la lista de juicios.
- ❌ **"A mí me sale bien" como validación de relevancia.** Sin lista de juicios no hay medición.
- ❌ Tocar los parámetros de BM25 antes de revisar analizadores, campos y pesos.
- ❌ Aplicar sinónimos en indexación cuando podían aplicarse en consulta.
- ❌ **Tratar el buscador como fuente de verdad**, o no poder reconstruirlo desde el origen.
- ❌ Miles de shards pequeños; o cero réplicas en producción.
- ❌ Índice único gigante para datos con patrón temporal en lugar de índices por tiempo con retención.
- ❌ Snapshot sin restore probado y cronometrado; upgrade de versión mayor sin ensayo ni rollback;
  saltar a una `.0` en producción.
- ❌ Acumular índices sin reindexar hasta que el upgrade de versión mayor sea imposible.
- ❌ **Exponer el motor a Internet**, o **exponer su query DSL a clientes**.
- ❌ Arrancar sin autenticación ni TLS en cualquier entorno alcanzable por red; dejar los
  certificados o contraseñas de demo.
- ❌ Filtrar permisos después de recibir los resultados en vez de en la consulta al motor.
- ❌ Comodín inicial, `from`/`offset` profundo, agregaciones de alta cardinalidad sin límite, o
  consultas sin timeout, en el camino caliente.
- ❌ Usar esta skill para decidir el backend de logs (es de `observability-standards`) o para escribir
  reglas de SIEM (es de `detection-engineering-standards`).
- ❌ Duplicar aquí el criterio de fusión híbrida de `rag-standards` o el de operación del índice
  vectorial de `vector-db-standards`.
- ❌ Fijar de memoria una versión, una licencia, un tamaño de shard o una cifra de rendimiento (§8).

## 8. Verificación web obligatoria

1. **Licencia de cada motor** — el dato que decide, y el que más ha cambiado. Verificado a ago-2026
   leyendo los ficheros `LICENSE` del repositorio (no resúmenes de páginas HTML, que **inventan
   fechas y llegan a invertir el sentido de una frase**): Elasticsearch **triple AGPLv3-only / SSPL
   v1 / Elastic License 2.0**; OpenSearch **Apache-2.0**; Meilisearch **`MIT AND BUSL-1.1`** con
   Enterprise Edition bajo BSL; Typesense **GPL-3.0**; Manticore **GPL-3.0**; Vespa, Solr y Quickwit
   **Apache-2.0**. **Reverifica cada trimestre.**
2. **Versiones**, vía feeds Atom de releases: Elasticsearch **9.4.4** (jul-2026), OpenSearch **3.7.0**
   (jun-2026) y **2.19.6**, Meilisearch **1.52.0** (ago-2026), Typesense **30.2** (abr-2026, rama
   `v31` activa), Manticore **28.6.6** (jul-2026), Vespa **8.731.x**, Solr **10.0.0** (mar-2026),
   Quickwit **0.9.0** (jul-2026).
3. **Gobernanza de OpenSearch**: **OpenSearch Software Foundation**, proyecto de la **Linux
   Foundation**, propiedad transferida desde Amazon, anunciada el **16-sep-2024**. Confirma que no ha
   cambiado.
4. **Estado de proyecto**: Quickwit **adquirido por Datadog (ene-2025)**, relicenciado a Apache-2.0 y
   **con actividad confirmada en ago-2026**. Comprueba si algún otro ha sido adquirido o abandonado.
5. **CVEs y EOL**: Elasticsearch **CVE-2026-63140** y **CVE-2026-63144** corregidos en 8.19.19 / 9.3.8
   / 9.4.4 (jul-2026). Consulta los boletines del motor y de sus plugins antes de fijar versión.
6. **Autenticación por defecto** de la versión concreta que despliegas (§5.1). Verificado verbatim en
   documentación oficial para Elasticsearch, OpenSearch y Solr.
7. **Compatibilidad de snapshots y de índices entre versiones mayores** antes de planificar un
   upgrade.
8. **Analizadores de español disponibles** en la versión de tu motor y su comportamiento — los
   nombres y el comportamiento por defecto cambian entre versiones mayores.
9. **Servicios gestionados equivalentes** y su modelo de licencia y precio (`aws-standards`,
   `azure-standards`, `gcp-standards`).

**Huecos declarados — NO rellenar de memoria**:

- **Licencia efectiva de las distribuciones binarias de Elasticsearch**: **el hueco más importante de
  este documento.** El repositorio es triple, pero hay reportes consistentes de que los artefactos
  descargables y las imágenes oficiales se entregan bajo **Elastic License 2.0**. **No verificado de
  forma concluyente en esta revisión.** Si tu decisión depende de poder usar AGPLv3, comprueba el
  fichero de licencia del artefacto concreto antes de comprometerte.
- **Qué módulos concretos de Meilisearch caen bajo BSL 1.1**: el `LICENSE` remite a los ficheros
  marcados como Enterprise Edition bajo `enterprise_editions`. **La lista exacta no se fija aquí**:
  audítala en la versión que despliegues.
- **Tamaños objetivo de shard, número de shards y umbrales de memoria**: **deliberadamente no
  fijados.** Dependen del hardware, del tamaño de documento y del patrón de consulta; cualquier cifra
  concreta es la heurística de la documentación de otro motor en otra versión. Se miden.
- **Parámetros de BM25 y pesos de boosting**: no fijados. Se determinan con la lista de juicios (§4.2).
- **Benchmarks comparativos entre motores**: no fijados. Los públicos son casi siempre de proveedor.
- **Estado de auth por defecto de Vespa y Quickwit**: no verificado en esta revisión. Confírmalo en su
  documentación antes de desplegar.
- **Estado y madurez de las extensiones BM25 para PostgreSQL** (ParadeDB / `pg_search`): mencionadas
  como opción, **no verificadas** en versión ni licencia en esta revisión.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
