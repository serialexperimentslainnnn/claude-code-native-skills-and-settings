---
name: r-standards
description: Use when writing, reviewing or productionizing R code - .R/.Rmd/.qmd/.Rproj files, DESCRIPTION, NAMESPACE, renv.lock, .Rprofile, .lintr, _pkgdown.yml, testthat tests, roxygen2 blocks, tidyverse/dplyr/ggplot2 or data.table pipelines, non-standard evaluation with {{ }} and .data, CRAN/Bioconductor/Posit Package Manager repositories, Shiny apps (app.R, server.R, ui.R), Plumber APIs (plumber.R), Quarto or R Markdown reports, Rcpp/cpp11 native code, or rocker/r-base container images.
---

# Estándares R (referencia: agosto 2026)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo trabajo en R: análisis exploratorio, paquetes, informes reproducibles, APIs, apps Shiny,
empaquetado y despliegue. Triggers: `.R`, `.Rmd`, `.qmd`, `DESCRIPTION`, `NAMESPACE`, `renv.lock`,
`.Rprofile`, `.lintr`, `app.R`, `plumber.R`, `tests/testthat/`, `src/*.cpp` con Rcpp/cpp11.

**El eje de esta skill**: R es un lenguaje de *análisis* que acaba en producción sin haber sido
diseñado para ello. Un script que empezó en el portátil de un analista termina sirviendo un endpoint,
un informe programado o un cuadro de mando. Este documento fija cómo se hace ese salto **con red**:
entorno reproducible, código empaquetado, tests, y frontera de confianza explícita. El fallo
característico de R en producción no es el rendimiento: es que **nadie puede reconstruir el entorno
que produjo el número**.

**No aplica**: ver `mlops-standards` (**el ciclo de vida del modelo es suyo**: registro y versionado
de modelos, *feature store*, servicio y despliegue del modelo, monitorización de deriva,
reentrenamiento, *train/serve skew* — **cómo se escribe el R que entrena o puntúa es de aquí**),
`data-engineering-standards` (la plataforma de datos: ingesta, orquestación, idempotencia, *backfill*,
Parquet, SLA de frescura; el código de análisis que consume esa plataforma es de aquí),
`analytics-bi-standards` (el cuadro de mando como artefacto de decisión y su gobierno —
**un informe Quarto o una app Shiny que sustituye a una herramienta de BI es una decisión suya**;
el código de ese informe o esa app, de aquí), `data-warehouse-modeling-standards` (la forma del
modelo analítico: grano, estrella, SCD), `lakehouse-standards` (formato de tabla y catálogo tras
`arrow`/`duckdb`), `sql-standards` (**el SQL que `dbplyr` genera o que escribes en `DBI::dbGetQuery`
está sujeto a su criterio**), `python-standards` (§7 fija cuándo la respuesta correcta es Python),
`julia-standards` (rendimiento numérico; ver §7), `gpu-computing-standards` (la GPU como recurso que
se aprovisiona, comparte, monitoriza y paga; el código R que la usa, de aquí),
`llm-app-engineering-standards` y `rag-standards` (capa de aplicación de IA), `ai-governance-standards`
(gobernanza del modelo y cumplimiento normativo), `c-standards`/`cpp-standards` (**el código nativo
al otro lado de `Rcpp`/`cpp11`**: memoria, UB, sanitizers, flags del compilador; la frontera con R
—`SEXP`, protección de GC, empaquetado— es de aquí), `cicd-standards` (la pipeline que ejecuta los
gates de §4), `kubernetes-standards` (despliegue de la imagen), `appsec-standards` (modelado de
amenazas agnóstico; aquí solo los *sinks* de R), `vulnerability-management-standards` (triaje y SLA
del hallazgo; aquí solo el escaneo del proyecto), `secrets-management-standards`,
`observability-standards` (pipeline OTel/Prometheus; aquí solo la instrumentación en el código),
`api-design-standards` (el **contrato** de una API Plumber: recursos, códigos, paginación, versionado).

## 2. Toolchain por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Verificado a ago-2026 | Por qué |
|---|---|---|---|
| Runtime | **R** de la serie estable actual | 4.6.1 (2026-06-24); 4.6.0 salió 2026-04-24 | Minor **una vez al año, en primavera**; parches cuando hacen falta |
| Versión "conservadora" | Último parche de la serie anterior | 4.5.3 (2026-03-11) | R Core publica un parche final de la serie previa poco antes del x.y.0 siguiente. **R no tiene LTS**: lo más parecido es esa última patch, nunca >1 año de antigüedad |
| Entorno/reproducibilidad | **`renv`** | 1.2.3 (2026-05-16), MIT | **No negociable**: `renv.lock` versionado o el proyecto no es reproducible |
| Repositorio | **Posit Package Manager (P3M)** con snapshot por fecha | `https://packagemanager.posit.co/cran/YYYY-MM-DD` | Snapshots diarios (días laborables) desde 2017-10-10; binarios Linux. CRAN puro no da reproducibilidad temporal |
| Bioconductor | Solo si el dominio lo exige | 3.23 (2026-04-29) ↔ R 4.6 | **Ciclo acoplado a R**: 2 releases/año; la versión de Bioc fija la versión de R, no al revés |
| Manipulación de datos | `dplyr`/`tidyverse` **o** `data.table` — elegir uno por proyecto | dplyr 1.2.1 (2026-04-03), MIT; data.table 1.18.4 (2026-05-06), MPL-2.0 | Ver criterio abajo |
| Estilo | **`styler`** | 1.11.0 (2025-10-13), MIT | El repo GitHub no publica *release* desde 2024 pero **CRAN sí**: no está abandonado, publica por CRAN |
| Lint (gate CI) | **`lintr`** | 3.4.0 (2026-07-16) | Config en `.lintr` versionado |
| Tests | **`testthat` 3ª edición** | 3.3.2 (2026-01-12) | Se activa **explícitamente**: `Config/testthat/edition: 3` en `DESCRIPTION`. No es el default |
| Documentación | **`roxygen2`** | 8.0.0 (2026-05-01) | Mayor reciente: revisar breaking changes antes de subir |
| Informes | **Quarto** | quarto-cli 1.11.1 (2026-07-28) | Sustituye a R Markdown en proyecto nuevo; Rmd solo en legacy |
| API HTTP | **`plumber`** | 1.3.3 (2026-01-28), MIT | — |
| App interactiva | **`shiny`** (paquete R) | MIT | El **paquete** es MIT; el hosting no (ver §5/§7) |
| Datos que no caben | `arrow` + `duckdb` | — | Empuja el trabajo fuera de la RAM de R antes de reescribir en otro lenguaje |
| Nativo | `cpp11` en código nuevo; `Rcpp` en legacy | — | `cpp11` no usa macros de C++ pesadas y compila más rápido; `Rcpp` sigue siendo el ecosistema mayoritario |
| Contenedor | Imágenes **Rocker** (`rocker/r-ver:<version>`) | — | `r-ver` fija versión de R **y** snapshot de repositorio |

**Trampa de compatibilidad binaria (verificada)**: R 4.6.0 cambió cabeceras y la versión de la API del
motor gráfico (16 → 17); paquetes **compilados** ya instalados dejaron de cargar (casos reportados:
`data.table`, `RSQLite`). Regla: al subir de minor de R, **reinstala toda la librería de paquetes
compilados**, no reutilices el `.libPaths()` anterior. `renv::rebuild()` o imagen nueva.

**Criterio tidyverse vs data.table vs base R** (es un criterio, no un bando):
- **tidyverse** cuando el código lo van a leer y mantener analistas, cuando el proyecto ya es
  tidyverse, y cuando el volumen cabe holgado en RAM. Coste: árbol de dependencias grande y API que
  evoluciona (deprecaciones con ciclo, pero evoluciona).
- **data.table** cuando el rendimiento o la memoria mandan (agregaciones sobre millones de filas,
  *updates by reference*), o cuando quieres **una sola dependencia**. Su API es
  extraordinariamente estable — argumento real para código de larga vida. Coste: sintaxis densa.
- **base R** para paquetes con `Imports` mínimo y para utilidades de infraestructura. Coste:
  verbosidad y trampas (§3).
- Prohibido **mezclar los tres estilos en el mismo fichero**. Un paquete puede tener módulos
  distintos con estilos distintos; una función, no.

## 3. Estructura y convenciones

**Script suelto vs paquete — el criterio que define esta skill.** Un análisis deja de ser un script y
se convierte en **paquete** en cuanto ocurre cualquiera de: (a) una función se usa desde dos ficheros,
(b) alguien más lo va a ejecutar, (c) el resultado alimenta una decisión recurrente, (d) hay que
testearlo. Convertirlo en paquete es lo que da, gratis, todo lo que un análisis en producción necesita:
espacio de nombres, dependencias declaradas en `DESCRIPTION`, documentación con `roxygen2`, tests con
`testthat`, y `R CMD check` como gate. **No hace falta publicar en CRAN para empaquetar.**

```
proyecto/
  DESCRIPTION          # deps declaradas: Imports (uso real), Suggests (opcional), Depends casi nunca
  NAMESPACE            # generado por roxygen2 — nunca a mano
  renv.lock            # versionado SIEMPRE
  .Rprofile            # activa renv; sin lógica de negocio
  R/                   # funciones; nada de código con efectos al cargar
  tests/testthat/
  inst/                # scripts de entrada, plantillas
  analysis/ o vignettes/  # Quarto/Rmd que LLAMAN a R/, no que contienen la lógica
  src/                 # cpp11/Rcpp si aplica
```

- `library()` y `setwd()` **prohibidos dentro de `R/`**: en un paquete las dependencias se declaran en
  `DESCRIPTION` y se usan con `pkg::fun()` o `@importFrom`. Rutas con `here::here()` o `system.file()`.
- Ningún efecto secundario al cargar: nada de `library()`, `options()` globales, conexiones a BD ni
  lectura de ficheros en el cuerpo de `R/*.R`. Lo que necesite estado va en `.onLoad`/función explícita.
- Un informe Quarto/Rmd **no es el sitio de la lógica**: `.qmd` orquesta y narra; las funciones viven
  en `R/` y se testean. Un informe con 300 líneas de transformación embebidas es deuda por defecto.
- Nombres: funciones `snake_case` verbales; sin `df`, `df2`, `tmp`; sin `.` como separador (choca con
  el despacho S3). Sin `utils.R` cajón de sastre.
- **Objetos S3 por defecto**; S4 solo si el dominio ya lo exige (Bioconductor) o hace falta despacho
  por múltiples argumentos; R5/RC prácticamente nunca. **S7** existe pero verifica su madurez (§8)
  antes de fijarlo en un proyecto nuevo.
- `options(stringsAsFactors)` ya no existe como trampa: desde R 4.0.0 el default es `FALSE`. Pero el
  código heredado que **asumía** factores sigue existiendo — al tocar código pre-4.0, comprueba si
  dependía de la coerción. Los factores se crean **explícitamente**, con `levels` fijados a mano
  cuando el orden importa; un factor con niveles inferidos de los datos de hoy rompe mañana.

**Trampas del lenguaje que son bugs de primera clase** (tratarlas como tales, no como folclore):
- **Reciclado silencioso de vectores**: `x + y` con longitudes distintas no siempre avisa. Valida
  longitudes en los bordes; en aritmética crítica, `stopifnot(length(x) == length(y))`.
- **`NA` se propaga**: `sum(x)` sin `na.rm` da `NA`; `if (NA)` es error; `x == NA` es `NA`, se usa
  `is.na()`. Decide **explícitamente** por columna qué significa `NA` — nunca `na.rm = TRUE` por
  reflejo, porque cambia la semántica del resultado sin dejar rastro.
- `[` sobre `data.frame` con un solo resultado colapsa a vector: usa `drop = FALSE` o tibbles.
- `sapply()` devuelve tipos distintos según los datos: en código de producción, `vapply()` con
  `FUN.VALUE` explícito o las variantes tipadas de `purrr` (`map_dbl`, `map_chr`).
- Comparación de flotantes con `==`: `all.equal()` / tolerancia.
- Evaluación perezosa de argumentos: `force()` cuando capturas argumentos en clausuras.

**Non-standard evaluation (NSE)**. La evaluación *tidy* es lo que hace `dplyr` legible **y lo que
rompe la programación defensiva**: dentro de `filter(datos, x > 1)`, `x` no es una variable del
entorno, es una columna, y si la columna no existe R puede coger silenciosamente un objeto del
entorno con ese nombre. Reglas duras:
- En **funciones de paquete**, referencia siempre columnas con el pronombre `.data$col` (o
  `.data[[var]]`) — así el fallo es "columna inexistente", no "cogió tu variable global".
- Para pasar nombres de columna desde los argumentos de tu función: `{{ arg }}` (*embracing*); para
  varios, `...` pasado tal cual. `!!sym(chr)` solo si el nombre llega como cadena.
- `aes_string()`, `filter_()`, `mutate_()` y el resto de variantes `_` están **retiradas**: no se usan.
- Declara `.data` (y los nombres de columna que uses en NSE) para que `R CMD check` no genere el
  clásico "no visible binding for global variable" — con `utils::globalVariables()` como último recurso,
  no como norma.

**Errores y condiciones**:
- `stop()`/`warning()` con mensaje accionable; en paquetes nuevos, `rlang::abort()` con **clase de
  condición** para que el llamante pueda capturar por clase (`tryCatch(err_datos_vacios = ...)`) en
  lugar de por `grepl` sobre el mensaje.
- **Fallar es correcto; devolver un resultado a medias no.** Prohibido `try(..., silent = TRUE)` sin
  inspeccionar el resultado, y `suppressWarnings()` a granel sobre un bloque entero.
- `on.exit(add = TRUE)` para liberar conexiones, ficheros y `options()` modificadas — el `defer` de R.
- `warning()` no interrumpe: nada crítico se señala con `warning`.

## 4. Calidad: formato, lint, tests, documentación

- **Formato**: `styler` (tidyverse style guide) aplicado a todo el repo; una única configuración.
- **Lint**: `lintr` con `.lintr` versionado, ejecutado en CI como gate. Mínimo: longitud de línea fija,
  `object_name_linter`, `seq_linter` (`1:n` es un bug cuando `n == 0` → `seq_len(n)`),
  `undesirable_function_linter` (veta `attach`, `setwd`, `sapply`, `library` en `R/`),
  `T`/`F` prohibidos (son variables reasignables; usa `TRUE`/`FALSE`).
- **Tests con `testthat` 3ª edición** (`Config/testthat/edition: 3`):
  - Un fichero de test por fichero de `R/`; `expect_*` con AAA y un motivo de fallo por test.
  - Cubrir camino feliz **y bordes**: vector vacío, `NA`, `NULL`, columna ausente, tipo inesperado,
    factor con nivel no visto, fecha en otra zona horaria, duplicados.
  - Snapshot tests (`expect_snapshot`) para mensajes de error y salidas formateadas; revisar el
    `_snaps/` en el PR como código.
  - Aleatoriedad: `set.seed()` explícito en el test, o `withr::local_seed()`. Nada de tests que
    dependan del `RNGkind` global del entorno.
  - Nada de red pública ni de escribir en el directorio del usuario: `withr::local_tempdir()`.
  - Todo bug arreglado deja test de regresión. Flaky = se arregla o se borra.
- **Documentación**: `roxygen2` para toda función exportada (`@param`, `@return`, `@examples`
  ejecutables). Un `@export` sin documentación es un fallo de revisión. `pkgdown` si el paquete lo
  consumen terceros.
- **Gates de CI** (bloquean el merge, lo barato primero):
  1. `renv::status()` — falla si el lock no está sincronizado.
  2. `styler` en modo comprobación + `lintr::lint_package()`.
  3. `R CMD check --as-cran` (o `devtools::check()`): **cero ERROR, cero WARNING**; los NOTE se
     justifican por escrito o se arreglan.
  4. `testthat` con cobertura (`covr`); umbral acordado — la cobertura es señal, no meta.
  5. Auditoría de dependencias (§5) y build de la imagen.
- **Matriz de CI**: la versión de R fijada en producción, más la anterior si soportas usuarios
  externos. Fijar el snapshot P3M en CI para que un release de CRAN no rompa un build de ayer.

## 5. Seguridad del stack

**`readRDS()` / `load()` / `unserialize()` sobre entrada no confiable es ejecución de código.** Un
objeto serializado de R puede llevar entornos, promesas y clases con métodos que se ejecutan al
imprimirse o al restaurarse. Regla: **nunca** deserialices un `.rds`/`.RData` que venga de fuera de tu
frontera de confianza; para intercambio usa formatos de datos puros (Parquet, CSV, JSON) validados al
leerlos. `load()` además contamina el entorno global — prohibido en código de paquete.

- **`eval(parse(text = ...))` sobre entrada de usuario: PROHIBIDO.** Es el `eval` de R y es la
  vulnerabilidad clásica de Shiny. Tampoco `parse()`, `str2lang()`, `source()` de rutas construidas
  con input, ni `do.call(nombre_como_texto, ...)` sin allowlist.
- **Shiny expone R a internet.** Todo `input$*` es entrada hostil:
  - Valida **en el servidor**, no en la UI: la restricción de un `selectInput` no existe en el
    protocolo, un cliente puede enviar cualquier valor. `validate()`/`req()` no son validación de
    seguridad.
  - Nunca uses `input$*` para construir SQL, rutas de fichero, nombres de objeto ni comandos
    (`system()`, `system2()`). Allowlist de valores permitidos, no *blacklist*.
  - `fileInput`: límite de tamaño (`shiny.maxRequestSize`), tipo verificado por contenido, y el
    fichero se procesa en un temporal — jamás se sirve de vuelta ni se deserializa.
  - HTML: `HTML()`, `tags$script`, `htmltools::HTML` y `renderText` con `escape = FALSE` son XSS si
    entra input. Por defecto, texto escapado.
  - Autenticación: **Shiny Server open source no trae autenticación** — se resuelve por delante
    (proxy inverso con OIDC) o con un producto que la incluya. No implementes login en el propio
    `server()`.
- **SQL**: `DBI::dbGetQuery` con `params = list(...)` o `glue::glue_sql()`; `paste0()` de input en una
  consulta es veto absoluto. Con `dbplyr`, revisa el SQL generado (`show_query()`) — su criterio es
  de `sql-standards`.
- **`install.packages()` en tiempo de ejecución: PROHIBIDO en producción.** Instalar desde el
  contenedor arrancado o desde el `server()` de una app significa que el artefacto no es inmutable,
  que el build depende de la red y que la versión que corre hoy no es la que se testeó. Todas las
  dependencias se instalan en el build, desde un snapshot fijado. Lo mismo para `remotes::install_github()`
  fuera de un `Dockerfile` con commit fijado por SHA.
- **CRAN no audita seguridad.** CRAN comprueba que el paquete *funciona*, no que sea seguro ni que su
  mantenedor siga vivo. Antes de añadir una dependencia: mantenimiento reciente, número de
  mantenedores, licencia, y si arrastra un `SystemRequirements` que amplía la superficie del contenedor.
  Un paquete puede ejecutar código arbitrario en la instalación (`configure`, `.onLoad`).
- **Auditoría de dependencias**: el ecosistema R **no tiene un equivalente maduro a `pip-audit`**.
  Lo que hay: **`oysteR`** (CRAN 0.1.4, 2025-10-09, Apache-2.0), que consulta Sonatype OSS Index;
  el propio proyecto declara que **no está soportado por Sonatype** (contribución de comunidad) y que
  el uso intensivo cae en *rate limiting*. Úsalo como señal (`audit_renv_lock()` en CI, no bloqueante
  al principio), complementado con OSV/GitHub Advisories sobre el `renv.lock`, y **asume cobertura
  incompleta**: la ausencia de hallazgos en R no es evidencia de ausencia de vulnerabilidades.
  Verifica en §8 si ha aparecido algo mejor.
- **Secretos**: nunca en `.Rprofile`, `.Renviron` versionado, `renv.lock`, código ni informes. Env
  vars o gestor; `.Renviron` local en `.gitignore`. Cuidado con los `.RData` guardados al salir:
  desactiva el guardado automático de la sesión (`--no-save`, `--no-restore` en cualquier ejecución
  no interactiva) — un `.RData` con credenciales en el repo es un incidente clásico.
- **Informes**: un Quarto/Rmd renderizado incrusta lo que imprimas. Revisa que no salgan cadenas de
  conexión, tokens ni datos personales en las salidas ni en los mensajes de aviso.
- **Contenedores**: imagen basada en `rocker/r-ver` con versión de R y snapshot fijados, non-root,
  multi-stage. **El problema real de R en contenedores son las dependencias de sistema**: muchos
  paquetes compilan contra librerías del SO (`libcurl`, `libxml2`, `libssl`, `libgdal`, `libproj`,
  `libgit2`). Instálalas explícitamente en el `Dockerfile` (P3M expone los `SystemRequirements`);
  no confíes en que "estaban en la imagen base". Y no las dejes en la imagen final si solo hacían
  falta para compilar.

## 6. Rendimiento y operabilidad

- **Orden de ataque**, en este orden y no otro: (1) mide (`profvis`, `bench::mark`) — nunca optimices
  por intuición; (2) vectoriza y elimina el crecimiento de objetos en bucle (`x <- c(x, i)` es
  cuadrático: preasigna o usa `vapply`); (3) `data.table` para agregación/joins pesados; (4) empuja el
  cálculo a `arrow`/`duckdb` o a la base de datos cuando el dato no cabe en RAM; (5) `cpp11`/`Rcpp`
  solo para el bucle que realmente no se puede vectorizar, y solo tras 1-4.
- **R copia al modificar** y el pico de memoria es el problema, no la CPU. `data.table` modifica por
  referencia (`:=`) — potente y una fuente de bugs si el objeto se comparte: documenta cuándo una
  función muta su argumento, o devuelve copia explícita.
- Paralelismo: `future`/`furrr` o `parallel`. `multicore` (fork) **no es seguro en un servidor Shiny/
  Plumber ni en Windows**: usa `multisession` o procesos externos. Nunca lances más *workers* que
  núcleos asignados al contenedor — R no ve el límite de cgroup por sí solo.
- **Plumber**: es **monohilo**. Un request lento bloquea a todos. Escala con múltiples procesos tras
  un balanceador, timeouts explícitos en cada llamada saliente (`httr2::req_timeout`), y trabajo
  pesado fuera del request. Endpoints `/healthz` y `/readyz`; logging estructurado con *correlation id*.
- **Shiny en producción**: cada sesión es estado en el servidor y un proceso de R sirve N sesiones en
  **un solo hilo**. Consecuencias: cualquier cálculo largo en `server()` congela a todos los usuarios
  de ese proceso (mueve a `future`/cola de trabajos o precalcula); el estado de sesión no sobrevive a
  la caída del proceso ni migra entre réplicas (**afinidad de sesión obligatoria** en el balanceador,
  y una app que "se reinicia sola" es un usuario perdiendo su trabajo); reactividad mal aislada = fugas
  de datos entre sesiones si pones estado en el entorno global. Dimensiona por **sesiones concurrentes
  y RAM por sesión**, no por peticiones/segundo. Objetos grandes compartidos y de solo lectura: cárgalos
  una vez fuera de `server()` (se comparten entre sesiones del mismo proceso), nunca datos por usuario.
- Conexiones a BD: *pool* (`pool`) con límites; una conexión por sesión de Shiny se agota sola.
  Cierra siempre con `on.exit`.
- Informes programados: idempotentes, con parámetros explícitos y salida versionada. Un informe que
  falla debe **fallar ruidosamente**, no publicar la versión de ayer.
- Semilla y versiones en el artefacto: todo informe/modelo publica versión de R, `renv.lock` (o su
  hash) y semilla. Sin eso, un número no es reproducible aunque el código esté en git.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: R minor una vez al año (primavera) — planifícalo como evento, con reinstalación de
  paquetes compilados y ejecución completa de la suite. Parches de R, aplicar. Snapshot de P3M:
  **avanzarlo deliberadamente** (trimestral, con la suite verde) en lugar de flotar o de congelarlo
  durante años; un snapshot de 3 años es tan peligroso como no tener ninguno, porque el día que haya
  que moverlo el salto es imposible.
- Bioconductor arrastra la versión de R: si dependes de él, tu calendario **es el suyo** (dos releases
  al año), no al revés.
- Deprecaciones: tidyverse avisa con ciclos largos pero avisa; `lifecycle` badges y `DeprecationWarning`
  se tratan como deuda con issue, no se silencian. `data.table` casi no rompe API — es su valor.
- Una dependencia sin release en >2 años o con mantenedor único se revisa; si está en la ruta crítica
  de producción, se vendoriza la función que usas o se sustituye.
- **Deuda del análisis que se convierte en servicio**: cuando un script pasa a servir tráfico,
  **se reescribe como paquete con tests** antes de exponerlo, no después. "Lo envolvemos en Plumber y
  ya" es la deuda más cara de este ecosistema: nadie sabe qué entradas acepta, no hay tests, el estado
  vive en el entorno global y el primer incidente es a las 3 de la mañana. Si no hay presupuesto para
  la reescritura, no hay presupuesto para el servicio: publícalo como informe programado.

**Cuándo NO elegir R** (honestidad primero):
- ❌ R como lenguaje de *aplicación* de propósito general (backend transaccional, CLI de sistema,
  microservicio con lógica de negocio): usa Python, Go o TypeScript.
- ❌ R para orquestación de pipelines o infraestructura: eso es `data-engineering-standards`.
- ❌ R porque "el analista lo sabe": si el artefacto es un servicio con SLA y nadie del equipo mantiene
  R en producción, la elección correcta es portarlo.
- ✅ **R sí es la respuesta correcta** frente a Python en: modelado estadístico serio (modelos mixtos,
  supervivencia, series temporales, inferencia bayesiana, diseño experimental), bioestadística y
  Bioconductor, gráficos publicables (`ggplot2`), e informes reproducibles donde la narrativa y el
  cálculo van juntos. Ahí el ecosistema de paquetes especializados de R no tiene equivalente.
- ✅ **Python** (ver `python-standards`) cuando el trabajo es *engineering* alrededor del análisis:
  servicio, integración, ML de producción, orquestación, o cuando el equipo que lo mantendrá es de
  ingeniería. Frontera pragmática: si el resultado es un número o un informe, R; si el resultado es un
  sistema, Python.
- ✅ **Julia** (ver `julia-standards`) solo cuando el cuello es un bucle numérico que no se vectoriza.
  La elección casi nunca es "R o Julia": R es estadística y comunicación de resultados, Julia es
  rendimiento numérico. Comparten el nicho de "lenguaje científico que no es Python" y poco más.

**Lista de prohibiciones (veto):**
- ❌ Proyecto en producción sin `renv.lock` versionado, o con repositorio CRAN sin snapshot fijado.
- ❌ `install.packages()` / `remotes::install_github()` en tiempo de ejecución en producción.
- ❌ `readRDS()`/`load()`/`unserialize()` sobre entrada no confiable. `load()` dentro de un paquete.
- ❌ `eval(parse(text = ...))` con input de usuario. `source()` de ruta construida con input.
- ❌ `setwd()`, `attach()`, `library()` dentro de `R/`; `rm(list = ls())` como "reinicio".
- ❌ Confiar en el `.RData` guardado de la sesión: ejecuta siempre con `--no-save --no-restore`.
- ❌ SQL por `paste0`. Input de Shiny hacia `system()`, rutas o nombres de objeto sin allowlist.
- ❌ `T`/`F` en lugar de `TRUE`/`FALSE`. `1:n` donde `n` puede ser 0. `sapply()` en código de producción.
- ❌ `na.rm = TRUE` por reflejo, sin decidir qué significa el `NA` en esa columna.
- ❌ `suppressWarnings()`/`try(silent = TRUE)` a granel; capturar y tragar sin log ni re-raise.
- ❌ Variantes NSE retiradas (`aes_string`, `*_` con guion bajo) en código nuevo.
- ❌ Lógica de negocio dentro de un `.qmd`/`.Rmd` en vez de en `R/` con tests.
- ❌ `R CMD check` con WARNING "ya lo miraremos"; NOTE sin justificar por escrito.
- ❌ Estado de usuario en el entorno global de una app Shiny (fuga entre sesiones).
- ❌ Subir de minor de R reutilizando la librería de paquetes compilados anterior (ver §2).
- ❌ Cálculo largo síncrono dentro de `server()` de Shiny o de un endpoint Plumber.

## 8. Verificación web obligatoria

Antes de fijar versiones o decisiones, **verifica online** (WebSearch/WebFetch; para versiones, feeds
Atom de GitHub Releases y las páginas de CRAN — no el resumidor sobre HTML de GitHub):
1. Última estable de R y del último parche de la serie previa (`cran.r-project.org/src/base/R-4/`,
   `developer.r-project.org`). A ago-2026: **4.6.1 (2026-06-24)** y **4.5.3 (2026-03-11)**.
   **R no tiene LTS declarada** — no lo afirmes.
2. Versión de Bioconductor y la versión de R a la que está acoplada
   (`bioconductor.org/about/release-announcements/`). A ago-2026: **3.23 ↔ R 4.6**.
3. Estado de Posit Package Manager (URL de snapshot, cobertura de binarios por distro, disponibilidad
   del servicio público y sus términos de uso). Los snapshots públicos existen desde 2017-10-10 y solo
   en días laborables.
4. Versiones y **licencias** de `renv`, `styler`, `lintr`, `testthat`, `roxygen2`, `plumber`,
   `data.table` (MPL-2.0, no MIT), `shiny`. Comprueba **CRAN además de GitHub**: `styler` no publica
   *release* en GitHub desde 2024 pero su última versión CRAN es 1.11.0 (2025-10-13) — repo quieto
   ≠ paquete abandonado.
5. **Modelo comercial de Posit** (dato caro y cambiante): el paquete `shiny` es MIT y **Shiny Server
   open source es AGPL-3.0**, pero **Shiny Server Pro fue discontinuado el 2026-03-31** y Posit dirige
   a **Posit Connect**, comercial y con licencia por usuarios activos; el acceso público anónimo a
   contenido interactivo es un **entitlement de pago** (licencia Enhanced/Advanced). Verifica antes de
   diseñar hosting: precios no publicados, alternativas ShinyProxy (open source) y
   Connect Cloud/shinyapps.io. **Discrepancia declarada**: no he encontrado ninguna declaración
   oficial de Posit que ponga Shiny Server open source en modo mantenimiento, pero su último *release*
   en GitHub es de **2024-09-30**; trata su futuro como riesgo abierto, no como hecho.
6. Auditoría de vulnerabilidades: estado de `oysteR` y si existe ya alternativa mantenida (posconsulta:
   a ago-2026 no la hay). **Hueco no verificado a ago-2026**: la cobertura real de CRAN en OSV/OSS
   Index (qué porcentaje de paquetes tiene advisories) no la he podido cuantificar — no la afirmes.
7. **Hueco no verificado a ago-2026**: madurez de **S7** como sistema de objetos por defecto y si ya
   ha entrado en base R; y estado de `cpp11` frente a `Rcpp` tras el cambio de cabeceras de R 4.6.0.
8. Breaking changes de `roxygen2` 8.x y de la serie 4.6 de R (API gráfica 16→17, cabeceras) desde el
   `NEWS` oficial antes de cualquier upgrade — nunca de blogs de terceros sin contrastar.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
