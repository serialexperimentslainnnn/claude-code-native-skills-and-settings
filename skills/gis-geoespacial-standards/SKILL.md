---
name: gis-geoespacial-standards
description: Geospatial data as an engineering discipline — coordinate reference systems, formats and spatial SQL. Use when working with EPSG codes (EPSG:4326, EPSG:3857, EPSG:25830, EPSG:4258), WGS84 versus ETRS89 versus ITRF datums, map projection choice and distortion, .shp/.shx/.dbf/.prj shapefiles and their 2 GB and 10-character limits, GeoPackage .gpkg, GeoJSON and RFC 7946 CRS84, FlatGeobuf .fgb, GeoTIFF and Cloud Optimized GeoTIFF (OGC 21-026), GeoParquet, Zarr, PMTiles, COPC, STAC catalogs, PostGIS (ST_Intersects, ST_DWithin, ST_IsValid, ST_MakeValid, ST_Transform, ST_SetSRID, ST_Simplify, ST_Area, ST_Buffer, geography versus geometry, GiST and SP-GiST indexes, spatial_ref_sys), SpatiaLite, DuckDB spatial, GDAL/OGR with ogr2ogr, gdalwarp, gdal_translate and gdalinfo, PROJ and proj.db grid shifts, OGC WMS/WFS/WMTS/WCS and the OGC API - Features/Tiles/Maps family, vector and raster tiles, GeoServer, MapServer, pg_tileserv, TiTiler, Leaflet, OpenLayers, MapLibre GL JS versus the Mapbox GL JS licence change, OpenStreetMap ODbL share-alike, Copernicus/Sentinel imagery, or Spanish IGN, Catastro and Real Decreto 1071/2007 reference systems.
---

# GIS and geospatial data standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to data with a position: **reference systems and projections**, vector and raster
formats, spatial databases and spatial SQL, OGC services and tiles, map clients,
and the **data licence** — which in this domain decides more architectures than the
technology does.

**The premise that governs everything else**: in GIS the error does not show up as an exception,
but as a **plausible and false result**. A wrongly assigned CRS does not throw a `NullPointerException`:
it returns a polygon in the Gulf of Guinea, an area in "square degrees" or a distance with
a 40 % error, and the map draws just as prettily. That is why the verification spend goes
**on the data's input edges** (which CRS? valid geometry? which units?) and not on
later debugging: there is no trace to follow when the system has not failed, it has only
lied.

Triggers: `.shp`/`.shx`/`.dbf`/`.prj`/`.cpg`, `.gpkg`, `.geojson`, `.fgb`, `.tif`/`.tiff` with
GeoTIFF keys, `.parquet` with `geo` metadata, `.pmtiles`, `.mbtiles`, `.laz`/`.copc.laz`,
`EPSG:*` codes, `SRID`, `spatial_ref_sys`, `ST_*` functions, `ogr2ogr`, `gdalwarp`,
`gdalinfo`, `proj.db`, `cs2cs`, `WMS`/`WFS`/`WMTS`/`WCS`, `GetCapabilities`, `OGC API`,
`STAC`, `catalog.json`, `tippecanoe`, `GeoServer`, `MapServer`, `mapfile`, `pg_tileserv`,
`TiTiler`, `Leaflet`, `OpenLayers`, `MapLibre`, `mapbox-gl`, `osm.pbf`, `Overpass`,
`Sentinel-2`, `Catastro`, `IGN`, `PNOA`.

**Not applicable**: see `data-platform-standards` (**PostgreSQL operation**: tuning, replicas,
HA, PITR, backups — here only what PostGIS adds on top), `sql-standards` (general SQL,
execution plans and migrations; here the **spatial predicate and its cost**),
`data-engineering-standards` (orchestration, incremental ingestion and backfill of the pipelines
that move this data), `lakehouse-standards` (Iceberg/Delta tables and their metadata layer —
here only **how the geometry is stored inside**), `data-warehouse-modeling-standards`
(dimensional modelling), `nosql-standards` and `timeseries-db-standards` (geo indexes in
MongoDB/Redis or sensor series: the temporal trajectory is theirs; **the geometry, ours
here**), `analytics-bi-standards` (the map inside a dashboard and whether it changes any
decision), `object-storage-standards` (bucket, storage classes, egress cost and
HTTP range requests that make the COG viable), `caching-cdn-standards` (`Cache-Control`,
purge and CDN in front of a tile server), `web-performance-standards` (the
LCP/INP budget of the page that embeds the map), `frontend-frameworks-standards` (React/Vue
around the map component), `computer-vision-standards` (**models over imagery**:
detection, segmentation, labelling quality — here the **georeferencing and the format**
of that imagery), `deep-learning-standards` and `gpu-computing-standards` (training and
hardware), `hpc-standards` (Slurm and parallel filesystem for massive raster processing),
`privacy-engineering-standards` (**the coordinate as personal data**: minimisation,
DPIA, k-anonymity, retention — here only the alarm signal and the spatial generalisation
technique), `grc-compliance-standards` (INSPIRE and formal publication obligations as an
auditable control), `opensource-licensing-standards` (**licence methodology**, SPDX,
SBOM and the CI gate — here only the fact that ODbL is *share-alike* over data and what
that implies), `api-design-standards` (design of your own HTTP API; OGC services are
already-defined contracts that **are not reinvented**), `embedded-iot-standards` (the GNSS of the
device that produces the coordinate).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8). Data from
> Aug 2026.

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Spatial database | **PostGIS on PostgreSQL**. Stable branch **3.6.x**; **3.7.0beta1** on 2026-07-21 ("Best Served with PostgreSQL 19 Beta2"). Licence **GPL-2.0-or-later** (`LICENSE.TXT` raw: *"PostGIS may be distributed and/or modified under the conditions of the GNU General Public License, either version 2 or (at your option) any later version"*) | It is the default option barring a strong reason. **Do not use a beta in production.** Requirements from the 3.6 manual: **PostgreSQL 12–18**, **GEOS ≥ 3.8.0** (3.14+ for all the new functions), **PROJ ≥ 6.1**, **GDAL 3+** for raster. PostGIS's GPL does not contaminate your application: you talk to it over the network, you do not link it |
| Embedded alternative | **SpatiaLite** on SQLite. Latest version **5.1.0 (2023-08-04)**, tri-licensed **MPL 1.1 / GPL 2.0+ / LGPL 2.1+** | For a single portable file or an offline client. Low release cadence: verify maintenance before betting on it |
| Analytical alternative | **DuckDB `spatial`** (`GEOMETRY` with a Simple Features model) | Ad-hoc analytics over files (GeoParquet, GPKG, shapefile) without standing up a server. It is **not** a substitute for PostGIS for transactional load or concurrency |
| Base library | **GDAL/OGR 3.13.2 (2026-07-22)** + **PROJ** | Every conversion, reprojection and format read goes through here. Writing your own shapefile parser is an antipattern: 30 years of edge cases |
| Interchange vector | **GeoPackage (OGC 12-128r19, v1.4.0)** | One file, SQLite, no practical size limit, long field names, rich types, multi-layer, optional raster. It is the correct replacement for the shapefile |
| Vector for analysis at scale | **GeoParquet**. Latest community spec: **v2.0.0** (`README`: *"The community has agreed on this release, but it is still pending OGC approval"*), aligned with Parquet's geospatial logical types | Columnar, compressed, with *predicate pushdown*. **v2.0.0 is not yet an approved OGC standard**: pin the spec version and the library version in the project |
| Streaming vector | **FlatGeobuf** (`.fgb`), **BSD-2-Clause** | HTTP range reads with a packed spatial index; ideal for serving a large dataset from object storage with no server |
| Vector over API/web | **GeoJSON (RFC 7946)** only as an interchange format in an API, never for storage | Text, no index, no types: it bloats and does not scale. See the hard CRS restriction in §3 |
| Raster | **GeoTIFF**, and **Cloud Optimized GeoTIFF** if it lives in object storage. COG is **OGC standard 21-026 v1.0** (approved and published in 2023) | COG = internal *tiles* + *overviews* + byte ordering designed for HTTP range requests. It turns the bucket into a server without deploying anything |
| Multidimensional raster | **Zarr v3 (core spec v3.1)** | N-dimensional cubes (time × band × y × x), climate series and model outputs. It does not compete with COG: it solves a different problem |
| Point clouds | **COPC** (LAZ organised into an octree, readable by range) over flat LAS/LAZ | The same pattern as COG applied to LiDAR |
| Packaged tiles | **PMTiles v3** (reference implementations **BSD-3**; *"The PMTiles specification itself is public domain, or CC0 where applicable"*) | A single object in S3 served by HTTP ranges: zero tile server, zero database. Alternative: **MBTiles** (SQLite) if the consumer already supports it |
| Full OGC server | **GeoServer**, **GPL-2.0-or-later** with an exception for EMF/XSD/OSHI (`LICENSE.md`: *"either version 2 of the License, or (at your option) any later version… As an exception to the terms of the GPL, you may copy, modify, propagate, and distribute a work formed by combining GeoServer with the EMF, XSD and OSHI Libraries"*) | When full WMS/WFS/WMTS/WCS and administration through a UI are needed. **Alternative**: **MapServer** (**MIT** licence, `LICENSE.md` raw with the clause *"Permission is hereby granted, free of charge… without restriction"*), lighter and configured via a *mapfile* |
| Minimal server | **`pg_tileserv`** (**Apache-2.0**) for vector tiles from PostGIS; **TiTiler** (**MIT**, *"Copyright (c) 2019 Development Seed"*) for dynamic raster/COG | A binary or a container, without GeoServer's surface. Preferable when the source is already PostGIS or a bucket of COGs |
| Web client | **MapLibre GL JS** (**BSD-3-Clause**, *"Copyright (c) 2023, MapLibre contributors"*) for vector maps; **OpenLayers** (**BSD-2-Clause**) when arbitrary projections and WMS/WFS clients are needed; **Leaflet** (**BSD-2-Clause**) for the simple case | See §5: **Mapbox GL JS ≥ v2 is not open source** |
| Base data | **OpenStreetMap** under **ODbL** — a legal decision, not a technical one (§5) | Alternative without *share-alike*: official data (IGN/PNOA, Catastro, Copernicus) subject to its own legal notice |

## 3. Structure and conventions

### 3.1 The CRS is the contract — what breaks everything if ignored

**Hard rule: no dataset enters the system without a declared and verified CRS.** A file
without `.prj`, without `SRID` or with `SRID=0` is an **unknown** dataset, not a dataset in 4326.

- **Geographic ≠ projected.** `EPSG:4326` (WGS 84, lat/lon in **degrees**) is a
  *geographic* system on an ellipsoid. `EPSG:3857` (Web Mercator) and `EPSG:25830` (ETRS89 / UTM
  30N) are *projected*, in **metres**. Practical consequence: `ST_Area` and `ST_Distance`
  over `geometry` in 4326 return numbers in **degrees and square degrees**, which are neither
  areas nor distances. A buffer of "1000" in 4326 is a thousand degrees.
- **Never mix 4326 and 3857 in the same operation.** An `ST_Intersects` between geometries in
  different CRSs either fails, or —if someone "fixed" the SRID with `ST_SetSRID` instead of
  `ST_Transform`— compares incompatible coordinates and produces silent **kilometre-scale**
  errors. `ST_SetSRID` **labels**, `ST_Transform` **converts**: confusing them is the
  most expensive and most common bug in the domain.
- **Web Mercator is for drawing, not for measuring.** It distorts area brutally with
  latitude (Greenland the size of Africa). Any area-based statistic computed in
  3857 is wrong. It is used because it is the CRS of web tiles, and for nothing else.
- **Datum: WGS84 and ETRS89 diverge over time.** ETRS89 was defined coincident with ITRS at
  epoch 1989.0 and **fixed to the stable part of the Eurasian plate**, which drifts at
  ~**2.5 cm/year**; WGS84 follows ITRF. The accumulated separation is already on the order of decimetres
  and **growing**. At metre precision it does not matter; at surveying or cadastral precision, it does.
  **Verify the accumulated figure and the specific realisation (ETRF2000 vs ETRF2014) with EUREF
  before using it in a deliverable** — this document does not pin it (§8).
- **In Spain the official system is ETRS89** under **Real Decreto 1071/2007** (art. 3:
  *"Se adopta el sistema ETRS89 … como sistema de referencia geodésico oficial en España"*),
  with **REGCAN95 in the Canary Islands**; **ETRS-Transverse Mercator** projection for large scales and
  **ETRS-Lambert Conformal Conic** for 1:500,000 and smaller (art. 5). Common codes:
  `EPSG:4258` (ETRS89 geographic), `EPSG:258xx` (ETRS89/UTM). The previous system **ED50**
  (`EPSG:230xx`) still shows up in historical data and differs from the current one by **hundreds
  of metres**: reproject, do not rename.
- **Datum reprojection needs a grid, not just Helmert.** ED50↔ETRS89 and
  NAD27↔NAD83 require grid files installed in PROJ (`proj-data`). Without them PROJ
  applies a worse approximation **without warning**. Verify with `projinfo -s A -t B --spatial-test`
  and check which operation it picked.
- **Axis order**: the EPSG authority defines `EPSG:4326` as **lat, lon**; almost all
  software and GeoJSON use **lon, lat**. It is a perennial source of coordinates in the sea. In
  OGC services, WMS 1.3.0 respects the authority order and WMS 1.1.1 does not: **pin the service
  version explicitly**.

### 3.2 The projection is a decision, not a setting

There is no projection without distortion: you choose **what is preserved**.

| Need | Property | Typical family |
|---|---|---|
| Area-based statistics, choropleths | Equal-area | Albers, Lambert Azimuthal Equal-Area (`EPSG:3035` for Europe) |
| Navigation, local shapes, cadastre | Conformal (angles/shape) | Zonal UTM, Lambert Conformal Conic |
| Distances from a point | Equidistant | Centred azimuthal equidistant |
| Drawing web tiles | None, it is convention | Web Mercator (`EPSG:3857`) |

Picking the right UTM zone matters: outside its 6° zone the error grows fast. A
national dataset that crosses zones (Spain crosses 29, 30 and 31) is either stored in geographic
coordinates and projected on the fly, or a single national projection is defined — you do not force
everything into zone 30 without saying so.

### 3.3 Formats: what to use and why the shapefile is still alive

**Shapefile** is from 1998 and its limits are real and documented by ESRI:
- *"There is a 2 GB size limit for any shapefile component file, which translates to a
  maximum of roughly 70 million point features."*
- *"Field names cannot be longer than 10 characters."* — names are truncated and **collide**
  silently (`poblacion_2024` → `poblacion_`).
- *"The maximum number of fields is 255."*
- *"Null values are not supported in shapefiles."* — numeric nulls turn into `0`
  or into `-1.7976931348623158e+308`, contaminating any average.
- *"Date fields only support date. They do not support time."*
- It is not a file: it is **at least three** (`.shp`, `.shx`, `.dbf`) plus `.prj` (without which
  there is no CRS) and `.cpg` (without which the text encoding is a lottery). Copying only the
  `.shp` is the classic way to destroy a dataset.

**And even so it is still alive**, and that has to be accepted: it is the only format that **every**
GIS software reads and writes without exception, including municipal systems, ERPs and clients that are not going to
change. Criteria: **accept it at the input/output boundary, do not use it as an internal
or archival format**. Convert to GeoPackage at ingestion and go back to shapefile only in the
export to whoever asks for it.

**GeoJSON: the CRS is pinned by the standard.** RFC 7946 §4: *"The coordinate reference system
for all GeoJSON coordinates is a geographic coordinate reference system, using the World
Geodetic System 1984 (WGS 84) datum, with longitude and latitude units of decimal degrees…
equivalent to … `urn:ogc:def:crs:OGC::CRS84`"*, and *"The first two elements are longitude and
latitude … precisely in that order"*. The `"crs"` member of the 2008 specification **was
removed** because of interoperability problems. Corollary: **a GeoJSON in UTM is an invalid
file**, however much your library writes it. Rings must also comply with the right-hand
rule (*"exterior rings are counterclockwise, and holes are clockwise"*), something
half the generators ignore and some consumers do validate.

### 3.4 Project conventions

```
data/
  raw/            # exactly as it arrived, immutable, with its provenance file
  interim/        # reprojected and validated (GeoPackage)
  processed/      # ready for consumption (GeoParquet / COG / PMTiles)
  METADATA.md     # origin, licence, capture date, CRS, scale/resolution
```

- **Minimum mandatory metadata per dataset**: origin, **licence**, capture date, CRS
  (full EPSG code, not "WGS84"), capture resolution or scale, and the responsible person.
  Without this the data is unusable in six months and **legally indefensible** in twelve.
- **A single internal CRS** for the whole system, decided and documented. Everything that comes in is
  reprojected at ingestion. Heterogeneous CRSs coexisting in the same database are
  guaranteed debt.
- **Capture scale cannot be improved**. Data captured at 1:50,000 is not valid for
  decisions at 1:1,000 however much the system draws with millimetre precision. The
  apparent precision of a `double` is not accuracy.
- **Geometry column names**: `geom` (projected) / `geog` (spherical), with type,
  dimension and SRID declared in the column definition, not inferred.

## 4. Quality and testing

### 4.1 Invalid geometry is the no. 1 cause of absurd results

Self-intersections, unclosed rings, holes outside the polygon, duplicate vertices,
zero-area polygons. Spatial predicates over invalid geometry return
**arbitrary but error-free** results: an `ST_Intersects` that says `false` for
polygons that clearly overlap, an `ST_Union` that loses area.

Mandatory gate at ingestion:

```sql
-- 1. Detect (never "fix blindly" without looking at what is failing)
SELECT id, ST_IsValidReason(geom)
FROM capa WHERE NOT ST_IsValid(geom);

-- 2. Fix explicitly and auditably
UPDATE capa SET geom = ST_MakeValid(geom) WHERE NOT ST_IsValid(geom);

-- 3. Constrain going forward
ALTER TABLE capa ADD CONSTRAINT capa_geom_valida CHECK (ST_IsValid(geom));
ALTER TABLE capa ADD CONSTRAINT capa_geom_srid  CHECK (ST_SRID(geom) = 25830);
```

`ST_MakeValid` **can change the geometry type** (an invalid polygon can come out as a
`GeometryCollection` or `MultiPolygon`): check it afterwards, do not assume it. And `ST_MakeValid`
makes a decision about data that may have been badly captured: in cadastral or
legal data, correcting silently can be worse than rejecting the record.

Other ingestion checks, as automated tests that break the pipeline:
- All geometries with the **expected SRID** and **not null**.
- **Extent (`ST_Extent`) within the plausible bounding box** of the area. This single test
  catches most CRS errors: if your Andalusia layer has coordinates near
  (0,0), the CRS is wrong.
- **No exact geometric duplicates** and no empty geometries (`ST_IsEmpty`).
- Topological coherence when the model requires it (parcels that do not overlap, network segments
  that connect): validate with `ST_Overlaps`/`ST_Touches` over the whole set, do not trust the
  source.
- **Count and total area compared with the previous dataset**: a 30 % variation
  between versions is an incident, not a data point.

### 4.2 Order of operations by cost

Spatial predicates are expensive; the index only helps if the query can use it.

- **Filter cheap before expensive**: indexed attributes → *bounding box* (`&&`, which uses the
  index) → exact predicate (`ST_Intersects`) → heavy operation (`ST_Intersection`,
  `ST_Union`, `ST_Buffer`).
- **`ST_DWithin(a, b, d)` instead of `ST_Distance(a,b) < d`**: the former uses the index, the
  latter forces a full scan. It is the highest-return optimisation in the domain.
- **Never wrap the indexed column in a function**: `ST_Transform(geom, 4326)` in the
  `WHERE` kills the index. Reproject the **parameter**, not the column; or keep an
  additional indexed column.
- **GiST index** by default on the geometry column; `SP-GiST` can win on very dense point
  clouds; `BRIN` only if the data is physically ordered by position.
  A GiST over huge overlapping polygons degrades: consider subdividing with
  `ST_Subdivide`.
- **`ANALYZE` after every bulk load**: the PostgreSQL planner uses spatial
  statistics; without them it picks bad plans.
- **Simplify with judgement**: `ST_Simplify` can break topology (gaps and overlaps
  between neighbouring polygons); `ST_SimplifyPreserveTopology` preserves it **within a
  geometry**, not between geometries. To simplify a mosaic of polygons without opening gaps
  you need topological simplification (`ST_CoverageSimplify` in recent PostGIS, or
  `mapshaper`). The tolerance is **in the CRS units**: 0.001 in 4326 is ~100 m.

### 4.3 Distances and areas: ellipsoid vs plane

- **`geometry` in a projected CRS**: fast, planar; correct only within the projection's area of
  validity and with its distortion.
- **`geography`**: computation on the ellipsoid, results in real **metres** at global
  scale, slower and with fewer functions available.
- Rule: **local or national scope → projected**; **continental/global scope or long
  distances → `geography`** (or `ST_DistanceSpheroid`). Computing a Madrid–Buenos
  Aires distance in Web Mercator gives a number with no physical meaning.
- The length of a straight line in a projected CRS **is not** the geodesic. For routing and
  aviation, this is not a nuance.

## 5. Stack security and data licence

### 5.1 The data licence is the architecture decision

- **OpenStreetMap is under ODbL** (`openstreetmap.org/copyright`: *"OpenStreetMap is open
  data, licensed under the Open Data Commons Open Database License (ODbL)"*), with
  attribution **and share-alike**: *"If you alter or build upon our data, you may distribute the
  result only under the same license."* Real consequence: if you mix OSM with your proprietary
  database and **distribute** the result as a derivative database, the ODbL
  reaches the derivative. *Produced works* (a rendered map, a PNG, a report) do not
  fall under ODbL but **do require attribution**. The "produced work" vs "derivative
  database" boundary is where projects get lost: **decide it in writing before
  ingesting OSM, not afterwards**, and with legal judgement if the product is commercialised. Consult
  the OSMF *Community Guidelines* for the specific case and verify their current
  wording (§8).
- **Sentinel/Copernicus**: *"free, full and open"* access governed by the *Legal Notice on
  the use of Copernicus Sentinel Data and Service*; the legal notice requires acknowledgement by
  credit. **Read it raw** before redistributing: it is not public domain without conditions.
- **IGN/PNOA and Catastro (Spain)**: each has its own usage condition and its citation
  requirement. Do not assume "it is public, it is free".
- **Cross-cutting rule**: the licence **is read from the file or from the official legal notice**, it is not
  inferred from the fact that the data is downloadable without registration.

### 5.2 Mapbox GL JS: the licence change that spawned MapLibre

`mapbox-gl-js` v1.13 and earlier were **BSD-3-Clause**. From **v2.0** onwards the repository's `LICENSE.txt`
says literally: *"The software and files in this repository (collectively,
'Software') are licensed under the Mapbox TOS for use only with the relevant Mapbox
product(s)"*, with automatic termination if the account stops being in good standing,
a prohibition on modifying the billing/telemetry code and collection of usage data.
**That is not free software**: it is a proprietary licence tied to a provider and to an
account. **MapLibre GL JS** is the community fork of the last BSD version and remains under
**BSD-3-Clause**. Criteria: **MapLibre by default**; Mapbox GL JS only as a conscious
decision to couple to Mapbox, with its cost and its termination risk documented.

### 5.3 Domain-specific attack surface

- **OGC services = textbook SSRF and XXE**. WMS `GetMap` with a remote `SLD` and WFS with XML
  filters accept **client-controlled URLs and XML**: disable external entities,
  restrict the map server's egress and do not allow arbitrary remote SLD. GeoServer has
  accumulated critical remote-execution CVEs (including abuse of expressions in OGC
  requests): keep it patched, never expose `/geoserver/web` to the Internet and separate the
  publication instance from the administration one.
- **Spatial SQL with user input**: parameterised queries always. A WKT or a
  GeoJSON concatenated into an `ST_GeomFromText` is SQL injection with a parser bonus.
- **Geometric bomb as DoS**: a polygon with millions of vertices, an `ST_Buffer` over it
  or an `ST_Union` over the whole table take the server down. Hard limits: maximum number of
  vertices accepted on input, `statement_timeout` on the API connection, maximum request
  extent and minimum serviceable zoom level.
- **Leak through an open service**: a WFS without controls publishes **the entire table** — rows,
  attributes and everything. Publish explicit views with the necessary columns, never the base
  table. The same with `pg_tileserv`: it exposes whatever the connection can read, so the
  connection goes with a read-only role and minimal permissions.
- **Map provider API keys in the frontend**: they are public by definition.
  Restrict them by domain/referrer and with a quota, and monitor consumption — abuse is paid
  on the invoice.

### 5.4 Coordinates as personal data

A GPS track or a home position **is personal data**, and it frequently allows
re-identification even with direct identifiers removed: mobility patterns
are almost unique per individual. Alarm signals: per-user position history,
geocoding of customer addresses, heat maps with little population in the
cell, "anonymised" by truncating decimals (**it is not**: 4 decimals are still ~11 m).
Techniques: aggregation to a territorial unit with a minimum threshold of individuals, *geo-masking*
with a documented random offset, short retention of the raw history. **The criteria,
the DPIA and the re-identification threshold belong to `privacy-engineering-standards`** — here only
the obligation to detect it and not to call a rounding "anonymised".

## 6. Performance and operability

- **Tiles: precompute vs on the fly.** Precompute (tippecanoe → PMTiles/MBTiles) for data
  that changes daily or less; generate on the fly (`pg_tileserv`, TiTiler) for live data,
  always with a CDN in front and an explicit `Cache-Control`. The dominant cost is not CPU, it is
  invalidation: define the purge strategy **before** publishing.
- **Zoom decides the detail, not the full data.** Serving full geometry at z5 is the
  classic performance error: a generalisation pyramid per zoom level, with
  simplification and filtering of small features.
- **COG + object storage removes the raster server** in many cases: the
  client requests HTTP ranges. Requirement: internal *overviews* generated and **the bucket with
  range requests and CORS enabled**. Without *overviews* the COG is not a COG, it is an expensive TIFF.
- **STAC** as a catalog when there is more than a handful of scenes: without a catalog,
  discovery ends up being an `ls` over millions of objects.
- **Vacuum and bloat**: spatial tables with frequent geometry updates
  bloat fast (geometries are large and go to TOAST). Monitor bloat and the cost of
  `REINDEX` on the GiST.
- **Domain-specific observability**: p95 latency per zoom level, tile cache hit
  ratio, time of the most expensive spatial queries, and **data age**
  published next to the map. A map does not warn you that it is serving data from eight months ago.
- **Bulk processing is parallelised by spatial partition** (tiles, grids,
  provinces), not by rows: the cost is proportional to overlap, not to the number of records.

## 7. Long-term sustainability

- Cadence: PostGIS follows the PostgreSQL cycle — plan the extension upgrade
  **together with** the PostgreSQL major, and test `ALTER EXTENSION postgis UPDATE` on a copy
  first. GDAL/PROJ move fast and their behaviour changes in reprojection are subtle:
  pin the version in the container and review the PROJ CHANGELOG at every jump.
- Base data (OSM, cadastre, orthophoto) has its own update cycle: define
  who triggers it, how it is validated and what is done if the provider changes the schema.

**Explicit prohibitions:**

- ❌ **FORBIDDEN** to load a dataset without a declared and verified CRS, or to "fix it" with
  `ST_SetSRID` when what was needed was `ST_Transform`.
- ❌ **FORBIDDEN** to compute areas, lengths or buffers over `geometry` in `EPSG:4326`. Degrees
  are not metres.
- ❌ **FORBIDDEN** to use `EPSG:3857` for any area-based measurement or statistic.
- ❌ **FORBIDDEN** the shapefile as an internal, archival or inter-component interchange format
  between your own components. Only at the boundary with third parties that accept nothing else.
- ❌ **FORBIDDEN** to emit GeoJSON in a CRS other than CRS84 / WGS 84 lon-lat: RFC 7946 does not
  allow it and the consumer is not going to guess it.
- ❌ **FORBIDDEN** to publish a WFS/WMS service over base tables with all their columns, or with
  a database role that can write.
- ❌ **FORBIDDEN** to ingest OSM data into a distributable product without having resolved in writing
  the scope of the ODbL *share-alike*.
- ❌ **FORBIDDEN** to introduce Mapbox GL JS ≥ v2 treating it as open source, or to copy code from
  v2 into a free project.
- ❌ **FORBIDDEN** to run spatial predicates over unvalidated geometries.
- ❌ **FORBIDDEN** to call a position data point "anonymised" because decimals have been truncated
  or the name removed.
- ❌ **FORBIDDEN** to accept arbitrary user geometry without limits on vertices, extent and
  `statement_timeout`.
- ❌ **FORBIDDEN** to present a result with more precision than the original data's capture
  scale allows.
- ❌ **FORBIDDEN** to write your own shapefile, GeoTIFF or GeoPackage parser when
  GDAL/OGR exists.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **PostGIS**: latest stable of the 3.6/3.7 branch and its status (3.7.0 was in **beta1** on
   2026-07-21), compatibility matrix with PostgreSQL and GEOS/PROJ/GDAL minimums —
   `postgis.net/documentation/` and the release notes. Do **not** deploy the beta.
2. **GDAL/PROJ**: stable version (3.13.2 on 2026-07-22) and behaviour changes in
   reprojection; availability of the necessary datum grids in `proj-data`.
3. **GeoParquet**: whether **v2.0.0 is already an approved OGC standard** — as of Aug 2026 the
   `README` itself said *"still pending OGC approval"*. And which spec version GDAL, GeoPandas and
   DuckDB actually write, which do not always match.
4. **OGC API**: which parts are approved standards and which are still draft. As of Aug 2026,
   *Features* Parts 1 (1.0.1), 2 (1.0.1) and 3 (1.0.0) were listed as approved and Parts 4
   and 5 as **draft**. Also check the status of *Tiles*, *Maps*, *Coverages*, *Records*
   and *Processes*, which evolve separately.
5. **ETRS89 / WGS84 divergence**: the current accumulated separation and the current realisation
   (ETRF2000 vs ETRF2014) **from an EUREF/IGN source**. This document pins only the mechanism
   (~2.5 cm/year of Eurasian plate drift since epoch 1989.0) and **declares the accumulated
   figure a gap**: the only source that gave it in this verification was a search
   summary, not a raw normative document. **Do not use it without checking it.**
6. **Licences**: re-read raw the `LICENSE` of MapLibre, GeoServer, MapServer, PostGIS,
   TiTiler and `pg_tileserv` before a commercial deployment, and the current legal notice of
   Copernicus, IGN, PNOA and Catastro. Public data conditions change without warning.
7. **ODbL and OSM**: current wording of the OSM Foundation *Community Guidelines* on
   derivative database versus produced work, and the required attribution formula.
8. **CVEs**: GeoServer and GeoTools accumulate critical vulnerabilities actively exploited;
   consult the project's security advisory and the KEV catalog before exposing anything.
9. **EPSG codes**: verify the exact code in the official EPSG registry, never from memory
   or from a blog. The EPSG Dataset version and its date **could not be verified in this
   pass** (`epsg.org` returned 403): check them when pinning any dependency on the
   EPSG database.
10. **SpatiaLite**: whether it is still maintained — the last verified version was **5.1.0 (2023-08-04)**,
    with a low cadence.

If the web contradicts this document, **the web wins** — flag the discrepancy.
