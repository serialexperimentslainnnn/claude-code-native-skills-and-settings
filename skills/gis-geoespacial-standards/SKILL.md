---
name: gis-geoespacial-standards
description: Geospatial data as an engineering discipline — coordinate reference systems, formats and spatial SQL. Use when working with EPSG codes (EPSG:4326, EPSG:3857, EPSG:25830, EPSG:4258), WGS84 versus ETRS89 versus ITRF datums, map projection choice and distortion, .shp/.shx/.dbf/.prj shapefiles and their 2 GB and 10-character limits, GeoPackage .gpkg, GeoJSON and RFC 7946 CRS84, FlatGeobuf .fgb, GeoTIFF and Cloud Optimized GeoTIFF (OGC 21-026), GeoParquet, Zarr, PMTiles, COPC, STAC catalogs, PostGIS (ST_Intersects, ST_DWithin, ST_IsValid, ST_MakeValid, ST_Transform, ST_SetSRID, ST_Simplify, ST_Area, ST_Buffer, geography versus geometry, GiST and SP-GiST indexes, spatial_ref_sys), SpatiaLite, DuckDB spatial, GDAL/OGR with ogr2ogr, gdalwarp, gdal_translate and gdalinfo, PROJ and proj.db grid shifts, OGC WMS/WFS/WMTS/WCS and the OGC API - Features/Tiles/Maps family, vector and raster tiles, GeoServer, MapServer, pg_tileserv, TiTiler, Leaflet, OpenLayers, MapLibre GL JS versus the Mapbox GL JS licence change, OpenStreetMap ODbL share-alike, Copernicus/Sentinel imagery, or Spanish IGN, Catastro and Real Decreto 1071/2007 reference systems.
---

# Estándares de GIS y datos geoespaciales

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al dato con posición: **sistemas de referencia y proyecciones**, formatos vectoriales
y ráster, bases de datos espaciales y SQL espacial, servicios OGC y teselas, clientes de
mapa, y la **licencia del dato** — que en este dominio decide más arquitecturas que la
tecnología.

**La premisa que gobierna todo lo demás**: en GIS el error no se manifiesta como excepción,
sino como **resultado plausible y falso**. Un CRS mal asignado no lanza un `NullPointerException`:
devuelve un polígono en el golfo de Guinea, un área en "grados cuadrados" o una distancia con
un 40 % de error, y el mapa se pinta igual de bonito. Por eso el gasto de verificación va
**en los bordes de entrada del dato** (¿qué CRS?, ¿geometría válida?, ¿qué unidades?) y no en
el debugging posterior: no hay traza que seguir cuando el sistema no ha fallado, solo ha
mentido.

Triggers: `.shp`/`.shx`/`.dbf`/`.prj`/`.cpg`, `.gpkg`, `.geojson`, `.fgb`, `.tif`/`.tiff` con
claves GeoTIFF, `.parquet` con metadatos `geo`, `.pmtiles`, `.mbtiles`, `.laz`/`.copc.laz`,
códigos `EPSG:*`, `SRID`, `spatial_ref_sys`, funciones `ST_*`, `ogr2ogr`, `gdalwarp`,
`gdalinfo`, `proj.db`, `cs2cs`, `WMS`/`WFS`/`WMTS`/`WCS`, `GetCapabilities`, `OGC API`,
`STAC`, `catalog.json`, `tippecanoe`, `GeoServer`, `MapServer`, `mapfile`, `pg_tileserv`,
`TiTiler`, `Leaflet`, `OpenLayers`, `MapLibre`, `mapbox-gl`, `osm.pbf`, `Overpass`,
`Sentinel-2`, `Catastro`, `IGN`, `PNOA`.

**No aplica**: ver `data-platform-standards` (**operación de PostgreSQL**: tuning, réplicas,
HA, PITR, backups — aquí solo lo que PostGIS añade encima), `sql-standards` (SQL general,
planes de ejecución y migraciones; aquí el **predicado espacial y su coste**),
`data-engineering-standards` (orquestación, ingesta incremental y backfill de los pipelines
que mueven este dato), `lakehouse-standards` (tablas Iceberg/Delta y su capa de metadatos —
aquí solo **cómo se guarda la geometría dentro**), `data-warehouse-modeling-standards`
(modelado dimensional), `nosql-standards` y `timeseries-db-standards` (índices geo de
MongoDB/Redis o series de sensores: la trayectoria temporal es suya; **la geometría, de
aquí**), `analytics-bi-standards` (el mapa dentro de un cuadro de mando y si cambia alguna
decisión), `object-storage-standards` (bucket, clases de almacenamiento, coste de egress y
peticiones de rango HTTP que hacen viable el COG), `caching-cdn-standards` (`Cache-Control`,
purga y CDN delante de un servidor de teselas), `web-performance-standards` (presupuesto de
LCP/INP de la página que embebe el mapa), `frontend-frameworks-standards` (React/Vue
alrededor del componente de mapa), `computer-vision-standards` (**modelos sobre imagen**:
detección, segmentación, calidad de etiquetado — aquí la **georreferenciación y el formato**
de esa imagen), `deep-learning-standards` y `gpu-computing-standards` (entrenamiento y
hardware), `hpc-standards` (Slurm y filesystem paralelo para procesado masivo de ráster),
`privacy-engineering-standards` (**la coordenada como dato personal**: minimización,
DPIA, k-anonimato, retención — aquí solo la señal de alarma y la técnica de generalización
espacial), `grc-compliance-standards` (INSPIRE y obligaciones formales de publicación como
control auditable), `opensource-licensing-standards` (**metodología de licencias**, SPDX,
SBOM y el gate de CI — aquí solo el hecho de que ODbL es *share-alike* sobre datos y qué
implica), `api-design-standards` (diseño de una API HTTP propia; los servicios OGC son
contratos ya definidos que **no se reinventan**), `embedded-iot-standards` (el GNSS del
dispositivo que produce la coordenada).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Datos de
> ago-2026.

| Ámbito | Default | Motivo / alternativa justificable |
|---|---|---|
| Base de datos espacial | **PostGIS sobre PostgreSQL**. Rama estable **3.6.x**; **3.7.0beta1** el 2026-07-21 ("Best Served with PostgreSQL 19 Beta2"). Licencia **GPL-2.0-or-later** (`LICENSE.TXT` en crudo: *"PostGIS may be distributed and/or modified under the conditions of the GNU General Public License, either version 2 or (at your option) any later version"*) | Es la opción por defecto salvo motivo fuerte. **No usar beta en producción.** Requisitos del manual 3.6: **PostgreSQL 12–18**, **GEOS ≥ 3.8.0** (3.14+ para todas las funciones nuevas), **PROJ ≥ 6.1**, **GDAL 3+** para ráster. La GPL de PostGIS no contamina tu aplicación: hablas con ella por red, no la enlazas |
| Alternativa embebida | **SpatiaLite** sobre SQLite. Última versión **5.1.0 (2023-08-04)**, tri-licencia **MPL 1.1 / GPL 2.0+ / LGPL 2.1+** | Para un fichero único portable o un cliente offline. Cadencia de releases baja: verificar mantenimiento antes de apostar |
| Alternativa analítica | **DuckDB `spatial`** (`GEOMETRY` con modelo Simple Features) | Analítica ad-hoc sobre ficheros (GeoParquet, GPKG, shapefile) sin montar servidor. **No** es sustituto de PostGIS para carga transaccional ni concurrencia |
| Librería base | **GDAL/OGR 3.13.2 (2026-07-22)** + **PROJ** | Toda conversión, reproyección y lectura de formato pasa por aquí. Escribir un parser de shapefile propio es un antipatrón: 30 años de casos límite |
| Vector de intercambio | **GeoPackage (OGC 12-128r19, v1.4.0)** | Un fichero, SQLite, sin límite práctico de tamaño, nombres de campo largos, tipos ricos, multi-capa, ráster opcional. Es el reemplazo correcto del shapefile |
| Vector de análisis a escala | **GeoParquet**. Última spec de la comunidad: **v2.0.0** (`README`: *"The community has agreed on this release, but it is still pending OGC approval"*), alineada con los tipos lógicos geoespaciales de Parquet | Columnar, comprimido, con *predicate pushdown*. **v2.0.0 aún no es estándar OGC aprobado**: fijar versión de spec y de librería en el proyecto |
| Vector de streaming | **FlatGeobuf** (`.fgb`), **BSD-2-Clause** | Lectura por rango HTTP con índice espacial empaquetado; ideal para servir un dataset grande desde almacenamiento de objetos sin servidor |
| Vector por API/web | **GeoJSON (RFC 7946)** solo como formato de intercambio en API, nunca de almacenamiento | Texto, sin índice, sin tipos: se hincha y no escala. Ver la restricción dura de CRS en §3 |
| Ráster | **GeoTIFF**, y **Cloud Optimized GeoTIFF** si vive en almacenamiento de objetos. COG es **estándar OGC 21-026 v1.0** (aprobado y publicado en 2023) | COG = *tiles* internos + *overviews* + orden de bytes pensado para peticiones de rango HTTP. Convierte el bucket en servidor sin desplegar nada |
| Ráster multidimensional | **Zarr v3 (core spec v3.1)** | Cubos N-dimensionales (tiempo × banda × y × x), series climáticas y salidas de modelo. No es competencia del COG: resuelve otro problema |
| Nubes de puntos | **COPC** (LAZ organizado en octree, legible por rango) sobre LAS/LAZ plano | Mismo patrón que COG aplicado a LiDAR |
| Teselas empaquetadas | **PMTiles v3** (implementaciones de referencia **BSD-3**; *"The PMTiles specification itself is public domain, or CC0 where applicable"*) | Un solo objeto en S3 servido por rangos HTTP: cero servidor de teselas, cero base de datos. Alternativa: **MBTiles** (SQLite) si el consumidor ya lo soporta |
| Servidor OGC completo | **GeoServer**, **GPL-2.0-or-later** con excepción para EMF/XSD/OSHI (`LICENSE.md`: *"either version 2 of the License, or (at your option) any later version… As an exception to the terms of the GPL, you may copy, modify, propagate, and distribute a work formed by combining GeoServer with the EMF, XSD and OSHI Libraries"*) | Cuando se necesitan WMS/WFS/WMTS/WCS completos y administración por interfaz. **Alternativa**: **MapServer** (licencia **MIT**, `LICENSE.md` en crudo con la cláusula *"Permission is hereby granted, free of charge… without restriction"*), más ligero y configurado por *mapfile* |
| Servidor mínimo | **`pg_tileserv`** (**Apache-2.0**) para teselas vectoriales desde PostGIS; **TiTiler** (**MIT**, *"Copyright (c) 2019 Development Seed"*) para ráster/COG dinámico | Un binario o un contenedor, sin la superficie de GeoServer. Preferible cuando la fuente ya es PostGIS o un bucket de COGs |
| Cliente web | **MapLibre GL JS** (**BSD-3-Clause**, *"Copyright (c) 2023, MapLibre contributors"*) para mapas vectoriales; **OpenLayers** (**BSD-2-Clause**) cuando hacen falta proyecciones arbitrarias y clientes WMS/WFS; **Leaflet** (**BSD-2-Clause**) para lo simple | Ver §5: **Mapbox GL JS ≥ v2 no es open source** |
| Datos base | **OpenStreetMap** bajo **ODbL** — decisión legal, no técnica (§5) | Alternativa sin *share-alike*: datos oficiales (IGN/PNOA, Catastro, Copernicus) según su propia nota legal |

## 3. Estructura y convenciones

### 3.1 El CRS es el contrato — lo que rompe todo si se ignora

**Regla dura: ningún dataset entra al sistema sin CRS declarado y verificado.** Un fichero
sin `.prj`, sin `SRID` o con `SRID=0` es un dataset **desconocido**, no un dataset en 4326.

- **Geográfico ≠ proyectado.** `EPSG:4326` (WGS 84, lat/lon en **grados**) es un sistema
  *geográfico* sobre un elipsoide. `EPSG:3857` (Web Mercator) y `EPSG:25830` (ETRS89 / UTM
  30N) son *proyectados*, en **metros**. Consecuencia práctica: `ST_Area` y `ST_Distance`
  sobre `geometry` en 4326 devuelven números en **grados y grados cuadrados**, que no son
  áreas ni distancias. Un buffer de "1000" en 4326 son mil grados.
- **Nunca mezclar 4326 y 3857 en la misma operación.** Un `ST_Intersects` entre geometrías de
  CRS distintos o bien falla, o bien —si alguien "arregló" el SRID con `ST_SetSRID` en vez de
  `ST_Transform`— compara coordenadas incompatibles y produce errores de **kilómetros**
  silenciosos. `ST_SetSRID` **etiqueta**, `ST_Transform` **convierte**: confundirlas es el
  bug más caro y más común del dominio.
- **Web Mercator es para pintar, no para medir.** Distorsiona el área brutalmente con la
  latitud (Groenlandia del tamaño de África). Cualquier estadística por área calculada en
  3857 está mal. Se usa porque es el CRS de las teselas web, y para nada más.
- **Datum: WGS84 y ETRS89 divergen con el tiempo.** ETRS89 se definió coincidente con ITRS en
  la época 1989.0 y **fijado a la parte estable de la placa euroasiática**, que deriva a
  ~**2,5 cm/año**; WGS84 sigue a ITRF. La separación acumulada es ya del orden de decímetros
  y **crece**. A precisión de metro da igual; a precisión topográfica o catastral, no.
  **Verificar la cifra acumulada y la realización concreta (ETRF2000 vs ETRF2014) en EUREF
  antes de usarla en un entregable** — este documento no la fija (§8).
- **En España el sistema oficial es ETRS89** por el **Real Decreto 1071/2007** (art. 3:
  *"Se adopta el sistema ETRS89 … como sistema de referencia geodésico oficial en España"*),
  con **REGCAN95 en Canarias**; proyección **ETRS-Transverse Mercator** para escalas grandes y
  **ETRS-Lambert Conformal Conic** para 1:500.000 y menores (art. 5). Códigos habituales:
  `EPSG:4258` (ETRS89 geográfico), `EPSG:258xx` (ETRS89/UTM). El sistema anterior **ED50**
  (`EPSG:230xx`) sigue apareciendo en datos históricos y difiere del actual en **centenares
  de metros**: reproyectar, no renombrar.
- **La reproyección de datum necesita rejilla, no solo Helmert.** ED50↔ETRS89 y
  NAD27↔NAD83 requieren ficheros de rejilla instalados en PROJ (`proj-data`). Sin ellos PROJ
  aplica una aproximación peor **sin avisar**. Verificar con `projinfo -s A -t B --spatial-test`
  y comprobar qué operación eligió.
- **Orden de ejes**: la autoridad EPSG define `EPSG:4326` como **lat, lon**; casi todo el
  software y GeoJSON usan **lon, lat**. Es una fuente perenne de coordenadas en el mar. En
  servicios OGC, WMS 1.3.0 respeta el orden de la autoridad y WMS 1.1.1 no: **fijar la versión
  del servicio explícitamente**.

### 3.2 La proyección es una decisión, no un ajuste

No existe proyección sin distorsión: se elige **qué se preserva**.

| Necesidad | Propiedad | Familia típica |
|---|---|---|
| Estadística por superficie, coropletas | Equivalente (área) | Albers, Lambert Azimuthal Equal-Area (`EPSG:3035` para Europa) |
| Navegación, formas locales, catastro | Conforme (ángulos/forma) | UTM zonal, Lambert Conformal Conic |
| Distancias desde un punto | Equidistante | Azimutal equidistante centrada |
| Pintar teselas web | Ninguna, es convención | Web Mercator (`EPSG:3857`) |

Elegir la zona UTM correcta importa: fuera de su huso de 6° el error crece rápido. Un
dataset nacional que cruza husos (España cruza el 29, 30 y 31) o se guarda en geográficas y
se proyecta al vuelo, o se define una proyección única nacional — no se fuerza todo al huso
30 sin decirlo.

### 3.3 Formatos: qué usar y por qué el shapefile sigue vivo

**Shapefile** es de 1998 y sus límites son reales y documentados por ESRI:
- *"There is a 2 GB size limit for any shapefile component file, which translates to a
  maximum of roughly 70 million point features."*
- *"Field names cannot be longer than 10 characters."* — los nombres se truncan y **colisionan**
  en silencio (`poblacion_2024` → `poblacion_`).
- *"The maximum number of fields is 255."*
- *"Null values are not supported in shapefiles."* — los nulos numéricos se convierten en `0`
  o en `-1.7976931348623158e+308`, contaminando cualquier media.
- *"Date fields only support date. They do not support time."*
- No es un fichero: son **como mínimo tres** (`.shp`, `.shx`, `.dbf`) más `.prj` (sin el cual
  no hay CRS) y `.cpg` (sin el cual la codificación de texto es una lotería). Copiar solo el
  `.shp` es el clásico de destruir un dataset.

**Y aun así sigue vivo**, y hay que aceptarlo: es el único formato que **todo** software GIS
lee y escribe sin excepción, incluidos sistemas municipales, ERPs y clientes que no van a
cambiar. Criterio: **acéptalo en la frontera de entrada/salida, no lo uses como formato
interno ni de archivo**. Convertir a GeoPackage en la ingesta y volver a shapefile solo en la
exportación al que lo pide.

**GeoJSON: el CRS está fijado por la norma.** RFC 7946 §4: *"The coordinate reference system
for all GeoJSON coordinates is a geographic coordinate reference system, using the World
Geodetic System 1984 (WGS 84) datum, with longitude and latitude units of decimal degrees…
equivalent to … `urn:ogc:def:crs:OGC::CRS84`"*, y *"The first two elements are longitude and
latitude … precisely in that order"*. El miembro `"crs"` de la especificación de 2008 **fue
eliminado** por problemas de interoperabilidad. Corolario: **un GeoJSON en UTM es un fichero
inválido**, por mucho que tu librería lo escriba. Además los anillos deben cumplir la regla
de la mano derecha (*"exterior rings are counterclockwise, and holes are clockwise"*), cosa
que la mitad de los generadores ignora y algunos consumidores sí validan.

### 3.4 Convenciones de proyecto

```
data/
  raw/            # tal cual llegó, inmutable, con su fichero de procedencia
  interim/        # reproyectado y validado (GeoPackage)
  processed/      # listo para consumo (GeoParquet / COG / PMTiles)
  METADATA.md     # origen, licencia, fecha de captura, CRS, escala/resolución
```

- **Metadato mínimo obligatorio por dataset**: origen, **licencia**, fecha de captura, CRS
  (código EPSG completo, no "WGS84"), resolución o escala de captura, y persona responsable.
  Sin esto el dato es inutilizable a los seis meses y **legalmente indefendible** a los doce.
- **Un CRS interno único** para todo el sistema, decidido y documentado. Todo lo que entra se
  reproyecta en la ingesta. Los CRS heterogéneos conviviendo en la misma base de datos son
  deuda garantizada.
- **La escala de captura no se puede mejorar**. Un dato capturado a 1:50.000 no vale para
  decisiones a 1:1.000 por mucho que el sistema pinte con precisión de milímetro. La
  precisión aparente de un `double` no es exactitud.
- **Nombres de columna geométrica**: `geom` (proyectada) / `geog` (esférica), con tipo,
  dimensión y SRID declarados en la definición de la columna, no inferidos.

## 4. Calidad y testing

### 4.1 La geometría inválida es la causa nº1 de resultados absurdos

Autointersecciones, anillos no cerrados, agujeros fuera del polígono, vértices duplicados,
polígonos de área cero. Los predicados espaciales sobre geometría inválida devuelven
resultados **arbitrarios pero sin error**: un `ST_Intersects` que dice `false` sobre
polígonos que claramente se solapan, un `ST_Union` que pierde superficie.

Gate obligatorio en la ingesta:

```sql
-- 1. Detectar (nunca "corregir a ciegas" sin mirar qué falla)
SELECT id, ST_IsValidReason(geom)
FROM capa WHERE NOT ST_IsValid(geom);

-- 2. Corregir de forma explícita y auditable
UPDATE capa SET geom = ST_MakeValid(geom) WHERE NOT ST_IsValid(geom);

-- 3. Restringir a futuro
ALTER TABLE capa ADD CONSTRAINT capa_geom_valida CHECK (ST_IsValid(geom));
ALTER TABLE capa ADD CONSTRAINT capa_geom_srid  CHECK (ST_SRID(geom) = 25830);
```

`ST_MakeValid` **puede cambiar el tipo de geometría** (un polígono inválido puede salir como
`GeometryCollection` o `MultiPolygon`): comprobarlo después, no asumirlo. Y `ST_MakeValid`
toma una decisión sobre datos que quizá estaban mal capturados: en datos catastrales o
legales, corregir en silencio puede ser peor que rechazar el registro.

Otras comprobaciones de ingesta, como tests automáticos que rompen el pipeline:
- Todas las geometrías con el **SRID esperado** y **no nulas**.
- **Extensión (`ST_Extent`) dentro del bounding box plausible** del ámbito. Este único test
  atrapa la mayoría de errores de CRS: si tu capa de Andalucía tiene coordenadas cerca de
  (0,0), el CRS está mal.
- **Sin duplicados geométricos** exactos y sin geometrías vacías (`ST_IsEmpty`).
- Coherencia topológica cuando el modelo la exige (parcelas que no se solapan, tramos de red
  conectados): validar con `ST_Overlaps`/`ST_Touches` sobre el conjunto, no confiar en el
  origen.
- **Conteo y superficie total comparados con el dataset anterior**: una variación del 30 %
  entre versiones es un incidente, no un dato.

### 4.2 Orden de operaciones por coste

Los predicados espaciales son caros; el índice solo ayuda si la consulta lo puede usar.

- **Filtrar barato antes que caro**: atributos indexados → *bounding box* (`&&`, que usa el
  índice) → predicado exacto (`ST_Intersects`) → operación pesada (`ST_Intersection`,
  `ST_Union`, `ST_Buffer`).
- **`ST_DWithin(a, b, d)` en lugar de `ST_Distance(a,b) < d`**: la primera usa índice, la
  segunda fuerza recorrido completo. Es la optimización de mayor retorno del dominio.
- **Nunca envolver la columna indexada en una función**: `ST_Transform(geom, 4326)` en el
  `WHERE` inutiliza el índice. Reproyectar el **parámetro**, no la columna; o mantener una
  columna adicional indexada.
- **Índice GiST** por defecto sobre la columna geométrica; `SP-GiST` puede ganar en nubes de
  puntos muy densas; `BRIN` solo si los datos están físicamente ordenados por posición.
  Un GiST sobre polígonos enormes y solapados degrada: considerar subdividir con
  `ST_Subdivide`.
- **`ANALYZE` tras cada carga masiva**: el planificador de PostgreSQL usa estadísticas
  espaciales; sin ellas elige planes malos.
- **Simplificar con criterio**: `ST_Simplify` puede romper la topología (huecos y solapes
  entre polígonos vecinos); `ST_SimplifyPreserveTopology` la preserva **dentro de una
  geometría**, no entre geometrías. Para simplificar un mosaico de polígonos sin abrir huecos
  hace falta simplificación topológica (`ST_CoverageSimplify` en PostGIS reciente, o
  `mapshaper`). La tolerancia va **en las unidades del CRS**: 0,001 en 4326 son ~100 m.

### 4.3 Distancias y áreas: elipsoide vs plano

- **`geometry` en CRS proyectado**: rápido, plano; correcto solo dentro del ámbito de validez
  de la proyección y con su distorsión.
- **`geography`**: cálculo sobre el elipsoide, resultados en **metros** reales a escala
  global, más lento y con menos funciones disponibles.
- Regla: **ámbito local o nacional → proyectado**; **ámbito continental/global o distancias
  largas → `geography`** (o `ST_DistanceSpheroid`). Calcular una distancia Madrid–Buenos
  Aires en Web Mercator da un número sin significado físico.
- La longitud de una línea recta en un CRS proyectado **no es** la geodésica. Para rutas y
  aviación, esto no es un matiz.

## 5. Seguridad del stack y licencia del dato

### 5.1 La licencia del dato es la decisión de arquitectura

- **OpenStreetMap está bajo ODbL** (`openstreetmap.org/copyright`: *"OpenStreetMap is open
  data, licensed under the Open Data Commons Open Database License (ODbL)"*), con
  atribución **y share-alike**: *"If you alter or build upon our data, you may distribute the
  result only under the same license."* Consecuencia real: si mezclas OSM con tu base de
  datos propietaria y **distribuyes** el resultado como base de datos derivada, la ODbL
  alcanza a la derivada. Los *produced works* (un mapa renderizado, un PNG, un informe) no
  quedan bajo ODbL pero **sí exigen atribución**. La frontera "trabajo producido" vs "base de
  datos derivada" es donde se pierden los proyectos: **decidirlo por escrito antes de
  ingerir OSM, no después**, y con criterio legal si el producto se comercializa. Consultar
  las *Community Guidelines* de la OSMF para el caso concreto y verificar su redacción
  vigente (§8).
- **Sentinel/Copernicus**: acceso *"free, full and open"* gobernado por la *Legal Notice on
  the use of Copernicus Sentinel Data and Service*; la nota legal exige reconocimiento por
  crédito. **Leerla en crudo** antes de redistribuir: no es dominio público sin condiciones.
- **IGN/PNOA y Catastro (España)**: cada uno tiene su propia condición de uso y su exigencia
  de cita. No asumir "es público, es libre".
- **Regla transversal**: la licencia **se lee del fichero o de la nota legal oficial**, no se
  deduce del hecho de que el dato sea descargable sin registro.

### 5.2 Mapbox GL JS: el cambio de licencia que originó MapLibre

`mapbox-gl-js` v1.13 y anteriores eran **BSD-3-Clause**. A partir de **v2.0** el `LICENSE.txt`
del repositorio dice literalmente: *"The software and files in this repository (collectively,
'Software') are licensed under the Mapbox TOS for use only with the relevant Mapbox
product(s)"*, con terminación automática si la cuenta deja de estar en buen estado,
prohibición de modificar el código de facturación/telemetría y recogida de datos de uso.
**Eso no es software libre**: es una licencia propietaria atada a un proveedor y a una
cuenta. **MapLibre GL JS** es el fork comunitario de la última versión BSD y sigue bajo
**BSD-3-Clause**. Criterio: **MapLibre por defecto**; Mapbox GL JS solo como decisión
consciente de acoplarse a Mapbox, con su coste y su riesgo de terminación documentados.

### 5.3 Superficie de ataque específica

- **Servicios OGC = SSRF y XXE de manual**. WMS `GetMap` con `SLD` remoto y WFS con filtros
  XML aceptan **URLs y XML controlados por el cliente**: desactivar entidades externas,
  restringir egress del servidor de mapas y no permitir SLD remoto arbitrario. GeoServer ha
  acumulado CVEs críticos de ejecución remota (incluido abuso de expresiones en peticiones
  OGC): mantenerlo parcheado, nunca exponer `/geoserver/web` a Internet y separar la instancia
  de publicación de la de administración.
- **SQL espacial con entrada de usuario**: consultas parametrizadas siempre. Un WKT o un
  GeoJSON concatenado en un `ST_GeomFromText` es inyección SQL con extra de parser.
- **Bomba geométrica como DoS**: un polígono con millones de vértices, un `ST_Buffer` sobre él
  o un `ST_Union` sobre toda la tabla tumban el servidor. Límites duros: número máximo de
  vértices aceptados en la entrada, `statement_timeout` en la conexión de la API, extensión
  máxima de la petición y nivel de zoom mínimo servible.
- **Fuga por servicio abierto**: un WFS sin control publica **la tabla entera** — filas,
  atributos y todo. Publicar vistas explícitas con las columnas necesarias, nunca la tabla
  base. Lo mismo con `pg_tileserv`: expone lo que la conexión pueda leer, así que la
  conexión va con un rol de solo lectura y permisos mínimos.
- **Claves de API de proveedores de mapas en el frontend**: son públicas por definición.
  Restringirlas por dominio/referrer y con cuota, y monitorizar consumo — el abuso se paga
  en factura.

### 5.4 Coordenadas como dato personal

Una traza GPS o la posición del domicilio **es dato personal**, y con frecuencia permite
reidentificar aunque se hayan quitado los identificadores directos: los patrones de
movilidad son casi únicos por individuo. Señales de alarma: histórico de posiciones por
usuario, geocodificación de direcciones de clientes, mapas de calor con poca población en la
celda, "anonimizado" por truncar decimales (**no lo es**: 4 decimales siguen siendo ~11 m).
Técnicas: agregación a unidad territorial con umbral mínimo de individuos, *geo-masking*
con desplazamiento aleatorio documentado, retención corta del histórico crudo. **El criterio,
la DPIA y el umbral de reidentificación son de `privacy-engineering-standards`** — aquí solo
la obligación de detectarlo y de no llamar "anonimizado" a un redondeo.

## 6. Rendimiento y operabilidad

- **Teselas: precalcular vs al vuelo.** Precalcular (tippecanoe → PMTiles/MBTiles) para datos
  que cambian a diario o menos; generar al vuelo (`pg_tileserv`, TiTiler) para datos vivos,
  siempre con CDN delante y `Cache-Control` explícito. El coste dominante no es la CPU, es la
  invalidación: definir la estrategia de purga **antes** de publicar.
- **El zoom decide el detalle, no el dato completo.** Servir geometría completa a z5 es el
  error de rendimiento clásico: pirámide de generalización por nivel de zoom, con
  simplificación y filtrado de entidades pequeñas.
- **COG + almacenamiento de objetos elimina el servidor de ráster** en muchos casos: el
  cliente pide rangos HTTP. Requisito: *overviews* internos generados y **el bucket con
  peticiones de rango y CORS habilitados**. Sin *overviews* el COG no es COG, es un TIFF caro.
- **STAC** como catálogo cuando hay más de un puñado de escenas: sin catálogo, el
  descubrimiento acaba siendo un `ls` sobre millones de objetos.
- **Vacuum y bloat**: las tablas espaciales con actualizaciones frecuentes de geometría se
  hinchan rápido (las geometrías son grandes y van a TOAST). Monitorizar bloat y coste de
  `REINDEX` del GiST.
- **Observabilidad propia del dominio**: latencia p95 por nivel de zoom, ratio de acierto de
  caché de teselas, tiempo de las consultas espaciales más caras, y **antigüedad del dato**
  publicada junto al mapa. Un mapa no avisa de que está sirviendo datos de hace ocho meses.
- **El procesado masivo se paraleliza por partición espacial** (teselas, cuadrículas,
  provincias), no por filas: el coste es proporcional al solape, no al número de registros.

## 7. Sostenibilidad a largo plazo

- Cadencia: PostGIS sigue el ciclo de PostgreSQL — planificar la actualización de la extensión
  **junto con** el mayor de PostgreSQL, y probar `ALTER EXTENSION postgis UPDATE` en una copia
  antes. GDAL/PROJ suben rápido y sus cambios de comportamiento en reproyección son sutiles:
  fijar versión en contenedor y revisar el CHANGELOG de PROJ en cada salto.
- Los datos base (OSM, catastro, ortofoto) tienen su propio ciclo de actualización: definir
  quién lo dispara, cómo se valida y qué se hace si el proveedor cambia el esquema.

**Prohibiciones explícitas:**

- ❌ **PROHIBIDO** cargar un dataset sin CRS declarado y verificado, o "arreglarlo" con
  `ST_SetSRID` cuando lo que hacía falta era `ST_Transform`.
- ❌ **PROHIBIDO** calcular áreas, longitudes o buffers sobre `geometry` en `EPSG:4326`. Los
  grados no son metros.
- ❌ **PROHIBIDO** usar `EPSG:3857` para cualquier medida o estadística por superficie.
- ❌ **PROHIBIDO** el shapefile como formato interno, de archivo o de intercambio entre
  componentes propios. Solo en la frontera con terceros que no aceptan otra cosa.
- ❌ **PROHIBIDO** emitir GeoJSON en un CRS distinto de CRS84 / WGS 84 lon-lat: RFC 7946 no lo
  permite y el consumidor no lo va a adivinar.
- ❌ **PROHIBIDO** publicar un servicio WFS/WMS sobre tablas base con todas sus columnas, o con
  un rol de base de datos que pueda escribir.
- ❌ **PROHIBIDO** ingerir datos OSM en un producto distribuible sin haber resuelto por escrito
  el alcance del *share-alike* de la ODbL.
- ❌ **PROHIBIDO** introducir Mapbox GL JS ≥ v2 tratándolo como open source, o copiar código de
  la v2 a un proyecto libre.
- ❌ **PROHIBIDO** ejecutar predicados espaciales sobre geometrías no validadas.
- ❌ **PROHIBIDO** llamar "anonimizado" a un dato de posición porque se hayan truncado
  decimales o quitado el nombre.
- ❌ **PROHIBIDO** aceptar geometría arbitraria del usuario sin límite de vértices, extensión y
  `statement_timeout`.
- ❌ **PROHIBIDO** presentar un resultado con más precisión de la que permite la escala de
  captura del dato original.
- ❌ **PROHIBIDO** escribir un parser propio de shapefile, GeoTIFF o GeoPackage existiendo
  GDAL/OGR.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **PostGIS**: última estable de la rama 3.6/3.7 y su estado (3.7.0 estaba en **beta1** el
   2026-07-21), matriz de compatibilidad con PostgreSQL y mínimos de GEOS/PROJ/GDAL —
   `postgis.net/documentation/` y las notas de release. **No** desplegar la beta.
2. **GDAL/PROJ**: versión estable (3.13.2 el 2026-07-22) y cambios de comportamiento en
   reproyección; disponibilidad de las rejillas de datum necesarias en `proj-data`.
3. **GeoParquet**: si la **v2.0.0 ya es estándar OGC aprobado** — a ago-2026 el propio
   `README` decía *"still pending OGC approval"*. Y qué versión de spec escriben de verdad
   GDAL, GeoPandas y DuckDB, que no siempre coinciden.
4. **OGC API**: qué partes son estándar aprobado y cuáles siguen en borrador. A ago-2026,
   *Features* Parts 1 (1.0.1), 2 (1.0.1) y 3 (1.0.0) figuraban como aprobadas y las Parts 4
   y 5 como **draft**. Comprobar también el estado de *Tiles*, *Maps*, *Coverages*, *Records*
   y *Processes*, que evolucionan por separado.
5. **Divergencia ETRS89 / WGS84**: la separación acumulada actual y la realización vigente
   (ETRF2000 vs ETRF2014) **en fuente EUREF/IGN**. Este documento fija solo el mecanismo
   (~2,5 cm/año de deriva de la placa euroasiática desde la época 1989.0) y **declara como
   hueco la cifra acumulada**: la única fuente que la dio en esta verificación fue un resumen
   de búsqueda, no un documento normativo en crudo. **No usarla sin comprobarla.**
6. **Licencias**: releer en crudo `LICENSE` de MapLibre, GeoServer, MapServer, PostGIS,
   TiTiler y `pg_tileserv` antes de un despliegue comercial, y la nota legal vigente de
   Copernicus, IGN, PNOA y Catastro. Las condiciones de dato público cambian sin aviso.
7. **ODbL y OSM**: redacción vigente de las *Community Guidelines* de la OSM Foundation sobre
   base de datos derivada frente a trabajo producido, y la fórmula de atribución exigida.
8. **CVEs**: GeoServer y GeoTools acumulan vulnerabilidades críticas explotadas activamente;
   consultar el aviso de seguridad del proyecto y el catálogo KEV antes de exponer nada.
9. **Códigos EPSG**: verificar el código exacto en el registro EPSG oficial, nunca de memoria
   ni de un blog. La versión del EPSG Dataset y su fecha **no se pudieron verificar en esta
   pasada** (`epsg.org` devolvió 403): comprobarlas al fijar cualquier dependencia sobre la
   base de datos EPSG.
10. **SpatiaLite**: si sigue mantenido — la última versión verificada era **5.1.0 (2023-08-04)**,
    con cadencia baja.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
