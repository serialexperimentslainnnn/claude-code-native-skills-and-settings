---
name: i18n-standards
description: Use when a product must work in more than one language, script, region or time zone — messages.json, .po/.pot, .xliff/.xlf, .arb, .resx, .properties or .ftl catalogs, ICU MessageFormat and MessageFormat 2.0, CLDR plural categories (zero/one/two/few/many/other), Intl.NumberFormat/DateTimeFormat/Collator/PluralRules/Segmenter/ListFormat/RelativeTimeFormat/DisplayNames, Temporal, tzdata/IANA time zone identifiers and UTC storage, Unicode normalization NFC/NFD, locale-dependent case mapping and the Turkish dotless i, collation versus code-point sort, grapheme versus code point versus byte length, libphonenumber and E.164 parsing, ISO 4217 currency minor units, personal name and postal address field design, BCP 47 tags and Accept-Language negotiation, i18next/FormatJS/react-intl/gettext/Fluent/Rails i18n, Weblate/Tolgee/Crowdin/Lokalise/Transifex, pseudolocalization, missing-translation CI gates, RTL and bidi layout, or machine and LLM translation review policy.
---

# Estándares de internacionalización (i18n)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**La internacionalización es una decisión de arquitectura que se toma al principio o se paga
entera después.** No es una capa que se añada: determina el esquema de la base de datos (qué
campos existen para un nombre y una dirección, qué tipo guarda un instante, qué colación tiene
una columna), el contrato de la API (formato de fecha e importe), la unidad de texto del código
(cadena formateada vs. mensaje con parámetros) y el flujo de entrega (quién traduce y cuándo).
Retrofitarla es reescribir esas cuatro cosas a la vez, con datos ya en producción. **Corolario
operativo: un producto monolingüe se diseña i18n-ready aunque nunca se traduzca** — el coste
incremental antes del primer despliegue es bajo; después es una migración de datos.

Tres términos, una línea cada uno, y no se vuelve sobre ellos:
- **i18n**: preparar el sistema para que *pueda* adaptarse a cualquier locale sin tocar código.
- **l10n**: adaptarlo a un locale concreto (traducir, formatear, ajustar contenido y legales).
- **g11n**: la decisión de negocio de operar en un mercado — l10n + fiscal, legal, pago, soporte.

Triggers: catálogos `messages.json`, `.po`/`.pot`, `.xliff`/`.xlf`, `.arb`, `.resx`,
`.properties`, `.ftl`, `.strings`/`.xcstrings`; `ICU MessageFormat`, `MessageFormat 2.0`;
categorías plurales de CLDR; `Intl.*`; `Temporal`; `tzdata`/`zoneinfo`; identificador IANA de
zona; NFC/NFD; `toLocaleUpperCase`; colación e `ICU`; `libphonenumber`; E.164; ISO 4217;
BCP 47 y `Accept-Language`; `i18next`, `FormatJS`/`react-intl`, `gettext`, `Fluent`,
`rails-i18n`; Weblate, Tolgee, Crowdin, Lokalise, Transifex; pseudolocalización; RTL/bidi.

**No aplica**: ver
`frontend-web-platform-standards` (**el CSS y las APIs del navegador son suyos**: propiedades
lógicas `margin-inline`/`padding-block`/`inset-*`, `writing-mode`, `text-wrap`, y el estado
*Baseline* de cualquier `Intl.*` o de `Temporal`. Aquí **qué exige la i18n de ese CSS y de esa
API**: que no haya un `margin-left` que rompa en árabe, que el formateo lo haga la plataforma y
no una concatenación);
`accessibility-standards` (**cede completo**: el atributo `lang` del documento y de cada
fragmento, `dir`, el idioma como criterio de conformidad WCAG y **cómo lo consume la tecnología
asistiva** son criterios *suyos*, no de aquí. Si la pregunta es "¿el lector de pantalla lo
pronuncia en el idioma correcto?", es suya. Si es "¿existe la traducción y está bien
formateada?", es de aquí);
`design-systems-standards` (el componente que debe sobrevivir a RTL y a un
texto un 40 % más largo se construye y se audita ahí, una sola vez — no en cada pantalla. Aquí
el criterio que ese componente debe cumplir, no su API ni su versionado);
`api-design-standards` (**el contrato es suyo**: ISO 8601/RFC 3339 en el campo de fecha,
importes en unidades mínimas con su código ISO 4217, negociación de idioma en la cabecera. Aquí
la consecuencia en el cliente y en el catálogo);
`data-platform-standards` y `sql-standards` (**la colación y la ordenación en el motor son
suyas**: `COLLATE`, `ICU` como proveedor, `lc_collate`, reindexado tras cambio de versión de
colación. Aquí solo la consecuencia visible — que una lista ordenada por el motor puede no
coincidir con la que ordena el cliente, y que hay que elegir dónde se ordena);
`privacy-engineering-standards` (**datos personales**: un catálogo con nombres o direcciones
reales de ejemplo es un tratamiento; base legal, minimización y retención son suyas);
`grc-compliance-standards` (**requisito legal de idioma**: en qué lengua deben estar contrato,
etiquetado, aviso de privacidad o interfaz en cada jurisdicción — es una obligación normativa,
no una decisión de producto. Aquí solo la capacidad técnica de cumplirla);
`mobile-standards` y `dart-standards` (i18n de app nativa y de Flutter: `.arb`, `.xcstrings`,
recursos por *qualifier*, y el locale del sistema como fuente de verdad);
`ai-agent-workflow-standards` (**frontera fina**: la traducción automática con LLM aparece en
las dos. **El flujo de trabajo con el modelo es suyo** — qué tarea se le da, cómo se revisa,
qué permisos tiene. **El criterio de calidad lingüística y de dónde es inaceptable una
traducción sin revisar humana es de aquí**);
`python-standards`, `typescript-standards`, `dotnet-standards`, `jvm-spring-standards`,
`ruby-standards`, `php-standards`, `go-standards`, `rust-standards` (**la librería concreta de
i18n de cada stack es de su skill**; aquí el criterio que esa librería debe satisfacer),
`frontend-frameworks-standards` (enrutado por locale y carga de datos),
`web-performance-standards` (el coste en bytes de servir catálogos),
`cicd-standards` (la pipeline que ejecuta los gates de §4).

## 2. Decisiones por defecto

> Verificar la última versión y el estado de cada componente por web antes de fijarlo (§8).
> CLDR, ICU y `tzdata` publican varias veces al año y **`tzdata` cambia por decisión política,
> no por calendario**.

| Decisión | Por defecto | Alternativa justificable / motivo |
|---|---|---|
| Fuente de datos de locale | **CLDR** (vía ICU o vía `Intl` de la plataforma) | Nada más. Cualquier tabla propia de meses, monedas o plurales es deuda garantizada |
| Formateo de número, fecha, lista, unidad | **`Intl.*` de la plataforma** | Librería solo si el runtime no lo trae o si necesitas `skeleton` de ICU no expuesto. `Intl.NumberFormat`/`DateTimeFormat`/`Collator` están en todos los motores desde hace años (§2.1) |
| Sintaxis de mensaje | **ICU MessageFormat 1** hoy | **MF2 es estable en CLDR desde CLDR 47, pero la API de plataforma no**: `Intl.MessageFormat` sigue en **Stage 1** de TC39 y la adopción en herramientas es marginal (§2.2). MF2 solo con *polyfill* y con decisión consciente |
| Instantes | **UTC en almacenamiento, zona IANA del usuario en presentación** | Ver §3.5. Nunca *offset* fijo como sustituto de zona |
| Tipo de fecha | **Distinguir instante / fecha civil / fecha+hora sin zona** | Una fecha de nacimiento **no es un instante**: guardarla como *timestamp* la mueve un día al cruzar zona |
| API de fecha en JS | `Temporal` **solo tras comprobar el runtime**; si no, librería con soporte de zona | `Temporal` es ES2026 y va sin *flag* en Node 26, pero **no es Baseline**: falta Safari (§2.1) |
| Zona horaria | **Identificador IANA** (`Europe/Madrid`), nunca abreviatura (`CET`, `IST` es ambigua) | — |
| Teléfono | **`libphonenumber` (Apache-2.0)**, guardado en **E.164** | Nunca regex propia. En Node, envoltorio de terceros (§2.3) |
| Moneda | **Entero en unidad mínima + código ISO 4217**, formateo con `Intl.NumberFormat` | Nunca `float`. El número de decimales **depende de la moneda** (JPY 0, TND 3): no asumir 2 |
| Identificador de locale | **BCP 47** (`es-ES`, `zh-Hans-CN`, `sr-Latn`) | Nunca códigos de dos letras a secas para decidir formato: el script y la región importan |
| Negociación | `Accept-Language` como **valor por defecto**, preferencia explícita del usuario como ganadora, persistida | Nunca geolocalización por IP como única señal: el país no es el idioma |
| Normalización Unicode | **NFC al entrar** (borde de validación), comparación sobre la forma normalizada | NFD solo si el dominio lo exige (macOS histórico, algunos corpus). Lo prohibido es *no decidir* |
| Plataforma de traducción | **Weblate** autoalojado si hay equipo que lo opere; **Tolgee** si el flujo es de desarrollador; SaaS si no se quiere operar nada (§2.4) | — |
| Pseudolocalización | **Obligatoria**, generada y probada en CI (§4.2) | — |
| Traducción automática/LLM | Permitida **solo** con revisión humana antes de publicar, y **prohibida** en las clases de §5.3 | — |

### 2.1 Estado verificado de la plataforma JS (ago-2026)

Datos de `@mdn/browser-compat-data` **8.0.9** (`timestamp: 2026-08-03T15:35:50Z`) y de
`nodejs.org/dist/index.json`:

| API | Chrome | Firefox | Safari | Safari iOS | Node |
|---|---|---|---|---|---|
| `Temporal` | 144 | 139 | **`preview`, tras *runtime flag* `useTemporal`** | **no** | 26.0.0 |
| `Intl.Segmenter` | 87 | 125 | 14.1 | 14.5 | 16.0.0 |
| `Intl.DurationFormat` | 129 | 136 | 16.4 | 16.4 | 23.0.0 |
| `Intl.ListFormat` | 72 | 78 | 14.1 | 14.5 | 12.0.0 |
| `Intl.PluralRules` | 63 | 58 | 13 | 13 | 10.0.0 |
| `Intl.Collator` / `NumberFormat` | 24 | 29 | 10 | 10 | 0.12.0 |

- **`Temporal` no es Baseline.** MDN lo marca *verbatim*: «Limited availability — This feature
  is not Baseline because it does not work in some of the most widely-used browsers.» Alcanzó
  Stage 4 (ES2026) y Node 26 lo trae sin *flag*, pero **en web sigue exigiendo polyfill o
  detección**. Node 26 es *Current*, **no LTS**: en `dist/index.json` `v26.6.0` (2026-08-03)
  tiene `lts: false`; el LTS activo es la línea 24 (`Krypton`).
- **Node < 13 traía *small-icu*** (solo datos de `en-US`) — anotado en el propio BCD para
  `PluralRules`, `ListFormat`, `RelativeTimeFormat`, `Collator` y `NumberFormat`. En cualquier
  runtime o build minimizado, **verificar que hay ICU completo antes de confiar en `Intl`**: sin
  datos, `Intl` no falla, *degrada en silencio* a inglés. Ese es el modo de fallo peligroso.

### 2.2 MessageFormat 2 — dos estados que no coinciden

- **Especificación**: MF2 pasó a **Stable en CLDR 47** y es parte normativa de UTS #35 (LDML).
  En CLDR 48, `:currency` y `:percent` pasaron a Stable. Partes del espacio `u:` siguen *Draft*.
- **Plataforma**: `tc39/proposal-intl-messageformat` declara *verbatim* `Stage: 1`, campeones
  «Eemeli Aro (Mozilla/OpenJS Foundation), Ujjwal Sharma (Igalia)», con el hilo abierto del
  propio repositorio titulado **«This proposal is stuck»**.
- **Regla**: un estándar estable con API de plataforma parada y adopción marginal en TMS y
  frameworks **no es un default**. Se adopta MF2 cuando la cadena completa (catálogo → TMS →
  runtime) lo soporte, no cuando lo soporte solo el papel. `messageformat@4.0.0` (Apache-2.0)
  es el camino con *polyfill*.

### 2.3 Teléfonos

- `google/libphonenumber` está **vivo y con cadencia quincenal declarada**; última etiqueta en
  el feed de releases: `v9.0.36`. **Licencia verificada en el `LICENSE` en crudo del repo:
  Apache-2.0** (no BSD, no MIT).
- **No hay paquete npm oficial de Google** (el port JS está acoplado a Closure). Dos caminos, y
  **no son el mismo software**:
  - `google-libphonenumber` (envoltorio del port oficial; npm declara `(MIT AND Apache-2.0)`,
    `3.2.46`) — mismo comportamiento, **peso alto**.
  - `libphonenumber-js` (**reimplementación independiente**, npm declara `MIT`, `1.13.10`) —
    mucho más ligera, **no es equivalente en cobertura**: si validas números de todo el mundo
    con requisitos legales, verifica la diferencia antes de elegir.
- **Guardar E.164** (`+34600000000`) y, si el dominio lo pide, guardar aparte el país de origen.
  Formatear para mostrar; **nunca guardar el formato bonito**.

### 2.4 Plataformas de gestión de traducción (verificado en la página oficial, ago-2026)

| Plataforma | Licencia del software | Autoalojable | Plan gratuito (dato de la página oficial) |
|---|---|---|---|
| **Weblate** | **GPLv3+** (`LICENSE` en crudo: GNU GPL v3; pie de la web: «Licensed GNU GPLv3+») | Sí | **Libre plan gratis** para proyectos libres: «It has the same limits as the 160k plan, and is only for public projects». Cloud desde 47 €/mes (plan 10k). Soporte de autoalojado: 53 €/mes básico, 106 €/mes extendido. Release vigente en el feed: `Weblate 2026.8` |
| **Tolgee** | **Apache-2.0 con excepción**: el `LICENSE` dice que «All content that resides under the "ee/" and "/webapp/src/ee" directory […] is licensed under the license defined in "ee/LICENSE"» — **el núcleo es Apache-2.0, la parte *enterprise* no**. Llamarlo "Apache-2.0" a secas es incorrecto | Sí | Free 0 €: **500 claves, 3 asientos**. Team 49 €/mes, Business 179 €/mes, Advanced 499 €/mes (anual) |
| **Crowdin** | Propietario | No | **Gratis para código abierto bajo solicitud**: «If you want to use Crowdin for an Open Source project, sign up for a free account, set up your project and send us a request». Precio general por *hosted words* mediante calculadora; prueba de 14 días del plan Team |
| **Lokalise** | Propietario | No | **No hay plan gratuito.** Entrada: Explorer 144 $/mes; Growth 375 $/mes; Advanced 999 $/mes; Enterprise a medida. Solo prueba de 14 días |
| **Transifex** | Propietario | No | Starter / Growth / Enterprise+, precio por *hosted words*. **Gratis para proyectos de código abierto sin modelo de ingresos ni financiación** |

- **Corrección de suposición frecuente**: los directorios de comparación de software (GetApp,
  Vendr y agregadores) listan "free version" para Lokalise y precios de entrada fijos para
  Crowdin y Transifex. **La página oficial contradice ambas cosas**: Lokalise no publica plan
  gratuito y los otros dos cotizan por volumen de palabras alojadas. Precio de directorio =
  dato no verificado.
- **Criterio de elección, en este orden**: (1) ¿el flujo lo conducen desarrolladores o
  traductores? Weblate y Pontoon están orientados a traductor; Tolgee, a desarrollador.
  (2) ¿hay quien opere la instancia? Autoalojar añade parches, respaldo y disponibilidad.
  (3) ¿hay colaboradores externos? Entonces §5.1 es obligatorio. (4) Coste de salida: **exige
  exportación completa a un formato estándar antes de firmar** — el bloqueo aquí es del catálogo.

## 3. El catálogo de suposiciones falsas

Cada entrada es una suposición que **rompe sistemas en producción**. La regla general: si el
modelo de datos codifica una costumbre local, el sistema no es internacionalizable.

### 3.1 Nombres de persona

- ❌ `first_name` + `last_name`. **No hay descomposición universal**: hay culturas con dos
  apellidos (España), con el apellido delante (Hungría, gran parte de Asia oriental), con
  patronímico (Islandia, Rusia), con nombre único sin apellido (Indonesia, partes de India) y
  con partículas que no son parte del apellido a efectos de ordenación.
- ✅ **Un campo obligatorio `full_name` (nombre completo tal como la persona lo escribe)** y, si
  el negocio lo exige, un `display_name`/`preferred_name` opcional para el saludo. Cualquier
  descomposición adicional es **opcional y nunca obligatoria**.
- ❌ Longitud máxima "segura". No existe. Si hay que poner un límite, que sea **alto y por
  grafemas** (§3.4), y que esté justificado por el almacenamiento, no por el diseño del formulario.
- ❌ Restringir a `[A-Za-z ]`, a ASCII, o rechazar apóstrofos, guiones, espacios múltiples,
  puntos, caracteres no latinos o nombres de una sola letra. Todo eso existe.
- ❌ Asumir que el nombre no cambia (matrimonio, transición, corrección legal). El nombre es un
  campo **mutable con historial**, no una clave.
- ❌ Derivar género, tratamiento o pronombre del nombre. Si hace falta, **se pregunta**, es
  opcional y admite "prefiero no decirlo".
- Referencias a contrastar antes de diseñar el formulario: W3C *Personal names around the world*
  y el clásico *Falsehoods programmers believe about names* (§8).

### 3.2 Direcciones y códigos postales

- ❌ Campos fijos `calle` / `número` / `ciudad` / `provincia` / `CP`. El orden, la existencia y la
  obligatoriedad de cada componente **dependen del país** (Irlanda no tuvo código postal
  nacional hasta Eircode; Hong Kong no tiene; en Japón el orden va de mayor a menor).
- ✅ **Formulario cuyo conjunto y orden de campos se deriva del país seleccionado**, con un
  `address_lines[]` libre como respaldo, y el país como **primer** campo del formulario.
- ❌ Validar el código postal con una regex universal, o asumir numérico, o asumir longitud fija.
  Reino Unido, Países Bajos y Canadá son alfanuméricos con espacio significativo.
- ❌ "Estado/provincia" obligatorio. Muchos países no tienen esa subdivisión.
- ❌ Deducir el país por la IP y no dejar cambiarlo.
- Estándar a consultar para el formato postal internacional: **UPU S42** (§8). Para el código de
  país: **ISO 3166-1 alfa-2**, con la advertencia de que **la lista cambia** y de que algunas
  entradas son políticamente sensibles; no *hardcodear* la lista, tomarla de CLDR.

### 3.3 Teléfonos, monedas y decimales

- ❌ Regex de teléfono, longitud fija, asumir prefijo nacional o que un número identifica un país
  de residencia. Ver §2.3.
- ❌ Asumir dos decimales. **ISO 4217 define las unidades mínimas por moneda**: JPY 0, la mayoría
  2, TND/KWD/BHD 3. Un importe se guarda como **entero en unidad mínima + código de moneda**.
- ❌ `float`/`double` para dinero. Nunca.
- ❌ Asumir el separador decimal, el de millares, su presencia, o que el símbolo va delante.
  `Intl.NumberFormat` lo resuelve; una plantilla `"$" + x.toFixed(2)` no.
- ❌ Asumir que el símbolo de moneda identifica la moneda (`$` es al menos veinte monedas
  distintas). **Mostrar código ISO junto al símbolo cuando haya ambigüedad real.**
- ❌ Convertir divisa con un tipo cacheado sin fecha ni fuente. El tipo es un dato con marca
  temporal y con proveedor; un importe convertido **no sustituye** al importe original.

### 3.4 Texto: Unicode, normalización, mayúsculas, colación y longitud

- **Normalización**: `"é"` puede ser un punto de código (NFC, U+00E9) o dos (NFD, U+0065 U+0301).
  Se ven iguales, **no son iguales byte a byte**, y un índice único, un `WHERE`, un
  comparador de contraseñas y un nombre de fichero los tratan como distintos. **Regla: normalizar
  a NFC en el borde de entrada, antes de validar, indexar o comparar.** Documentar la elección.
- **Mayúsculas dependientes del idioma — el caso canónico es el turco `i`**: en `tr`/`az`,
  `"i".toUpperCase()` es `"İ"` (I con punto) y `"I".toLowerCase()` es `"ı"` (i sin punto). Por
  eso **`toUpperCase()`/`toLowerCase()` sin locale es un bug latente** y `toUpperCase()` para
  comparar identificadores rompe la autenticación en un dispositivo con locale turco. Además el
  cambio de caja **no conserva la longitud**: `"ß".toUpperCase()` da `"SS"`.
  - ✅ Para **presentación**: `toLocaleUpperCase(locale)` con locale explícito.
  - ✅ Para **comparar**: *case folding* independiente de locale (`toUpperCase` con locale raíz o
    la función de *case folding* de la librería ICU del stack), **nunca** el de la interfaz.
  - ❌ Escribir mayúsculas en el catálogo o forzarlas con `text-transform` como sustituto de
    tener la cadena correcta: hay idiomas sin distinción de caja y otros donde la mayúscula
    inicial cambia el significado (alemán) o no se usa igual (español en títulos y meses).
- **Ordenación**: ordenar por punto de código **no es orden alfabético en ningún idioma**. `"Z"`
  va antes que `"a"`, `"ñ"` cae tras `"z"`, y en sueco `"ä"` va al final del alfabeto mientras en
  alemán va junto a `"a"`. ✅ **Colación CLDR/ICU** (`Intl.Collator` en JS, `COLLATE` con
  proveedor ICU en el motor). **Decidir dónde se ordena** — si pagina el servidor, ordena el
  servidor; ordenar la página en el cliente produce una lista globalmente incorrecta.
  - `Intl.Collator` con `sensitivity` explícita para búsqueda y `numeric: true` para listas con
    números incrustados. La comparación *natural* de cadenas también es una decisión de locale.
- **Longitud: `.length` miente.** Tres unidades distintas y **ninguna es intercambiable**:
  - **Bytes** — lo que ocupa (límite de columna, de cabecera, de payload).
  - **Puntos de código** — lo que cuenta `.length` en Python; en JS `.length` cuenta **unidades
    UTF-16**, así que un emoji fuera del BMP cuenta 2.
  - **Grafemas** — lo que una persona percibe como "un carácter". Un emoji con modificador de
    tono o una familia con ZWJ es **un grafema y muchos puntos de código**.
  - ✅ Límite de interfaz y truncado: **por grafemas** (`Intl.Segmenter` con
    `granularity: 'grapheme'`). Límite de almacenamiento: **por bytes**, y validado en el borde.
    Truncar por índice de unidad de código **parte grafemas y produce texto corrupto**.
  - Segmentar por palabras con `split(' ')` es incorrecto en chino, japonés y tailandés:
    `Intl.Segmenter` con `granularity: 'word'`.

### 3.5 Fechas y zonas horarias — el otro gran generador de bugs

- **Regla base**: **instante en UTC en el almacenamiento; zona IANA del usuario en la
  presentación**; la zona se guarda como preferencia del usuario, no se infiere en cada petición.
- **Un `offset` no es una zona.** `+02:00` no permite calcular la hora de un evento futuro
  porque no sabe cuándo cambia el horario de verano. Guardar `Europe/Madrid`.
- **Fechas sin hora no son instantes.** Cumpleaños, fecha de factura, día festivo y fecha de
  vencimiento son **fechas civiles**. Guardarlas como `timestamp` las desplaza un día al cruzar
  zona. Tipo `DATE` o cadena `YYYY-MM-DD`, y aritmética civil, no aritmética de instantes.
- **Eventos futuros recurrentes** (una alarma a las 09:00) se guardan como **hora local + zona +
  regla de recurrencia**, no como instante UTC precalculado: si cambia la regla de la zona, el
  instante calculado queda mal.
- **`tzdata` es una dependencia que se actualiza y que cambia por decisión política**, no por
  calendario. Verificado en el `NEWS` de IANA, *verbatim*, release **2026c (2026-07-08)**:
  «Alberta moved to permanent -06 on 2026-06-18.» y «Morocco moves to permanent +00 on
  2026-09-20.» Consecuencia operativa dura: **un sistema con `tzdata` viejo calcula mal horas
  futuras y no da ningún error**. Actualizar `tzdata` es tarea de parcheo con la misma urgencia
  que un CVE de disponibilidad, y afecta a la imagen base del contenedor, al JDK, al runtime, a
  la base de datos y a la copia embebida de la librería de fechas — **son cinco copias distintas
  y se desincronizan**.
- Trampas restantes, todas reales: horas que **no existen** (el salto de primavera) y horas que
  **ocurren dos veces** (el retroceso de otoño) — toda aritmética local debe decidir qué hace en
  ambos casos; **días que no tienen 24 horas**; **`tzdata` cambia identificadores y los sustituye
  por enlaces** (`Europe/Kyiv` vs. `Europe/Kiev`); calendarios no gregorianos en presentación
  (islámico, hebreo, japonés por eras, budista) — `Intl.DateTimeFormat` con `calendar` explícito;
  y semanas cuyo **primer día depende del locale** (no siempre lunes, no siempre domingo).
- ❌ Aritmética de fechas sumando milisegundos. ❌ `new Date("dd/mm/yyyy")`: el parseo de cadenas
  no ISO **depende de la implementación**. ❌ Confiar en la zona del servidor: fijar `UTC` en el
  proceso y ser explícito en cada conversión.

### 3.6 Pluralización, género y la concatenación como antipatrón central

- **La concatenación de cadenas es el antipatrón central de i18n.** `"Tienes " + n + " mensajes"`
  asume orden de palabras, asume que el plural es una `s`, no deja mover el número dentro de la
  frase y no permite concordar género. **Cualquier fragmento de frase en el código es un bug de
  i18n**: la unidad traducible es **la frase completa con parámetros**, nunca sus trozos.
- **Las categorías plurales de CLDR no son "singular/plural"**: son hasta **seis** —
  `zero`, `one`, `two`, `few`, `many`, `other` — y **qué números caen en cada una lo decide
  CLDR por idioma**, no el traductor ni el desarrollador. El inglés usa dos; el árabe usa las
  seis; el polaco y el ruso usan `one`/`few`/`many`/`other`; el japonés usa solo `other`.
  Además, **`one` no significa "uno"**: en francés el 0 va en `one`.
  - ✅ El catálogo declara las categorías que el idioma **destino** necesita; la herramienta las
    genera a partir de CLDR. ❌ Una clave `_plural` binaria: rompe en cuanto entra un idioma con
    tres o más formas.
  - ✅ `Intl.PluralRules` para seleccionar en runtime cuando no se use un motor ICU completo.
  - **Ordinales son otra regla** (`type: 'ordinal'`): `1st/2nd/3rd/4th` no sigue las cardinales.
  - **Rangos** ("3–5 elementos") tienen su propia selección (`selectRange`).
- **Género**: no se resuelve con `select` improvisado en el código. ICU MessageFormat tiene
  `select` para eso, y **la variable de género debe llegar al mensaje como parámetro**, no
  decidirse fuera. Hay idiomas donde el verbo, el artículo y el adjetivo concuerdan; una interfaz
  que dice "Bienvenido" no es traducible sin ese dato.
- **Expansión de texto**: la traducción del alemán o del finés puede ser bastante más larga que
  el inglés y la del chino mucho más corta. **Ningún diseño puede depender de la longitud del
  texto original**; se prueba con pseudolocalización (§4.2), no con estimaciones.

## 4. Calidad, testing y gates de CI

En orden de coste creciente. Los tres primeros **rompen el build**.

### 4.1 Gates estáticos (segundos)

1. **Cadena literal sin clave en el código** → *build roto*. Regla de lint del stack
   (`i18next/no-literal-string`, `formatjs/no-literal-string-in-jsx`, `rubocop-i18n`,
   equivalente en cada lenguaje). Sin este gate, el catálogo se degrada solo.
2. **Clave usada y no declarada** → *build roto*. Es un error en tiempo de ejecución diferido; el
   extractor lo detecta en segundos.
3. **Clave declarada y no usada** → aviso, y **borrado** en la limpieza periódica. Un catálogo con
   claves muertas paga traducción de texto que nadie ve.
4. **Sintaxis ICU inválida en cualquier idioma** → *build roto*. Un traductor puede romper un
   `{count, plural, ...}`; se detecta compilando el catálogo, no en producción.
5. **Placeholders no coincidentes entre origen y traducción** (falta uno, sobra otro, cambia el
   nombre) → *build roto*. Es la causa más común de excepción en runtime por traducción.
6. **Cobertura de traducción por idioma**: umbral explícito por idioma. Un idioma **debajo de su
   umbral no se ofrece en el selector**; mostrar media interfaz en inglés es peor que no ofrecerla.
7. **Normalización del catálogo**: los ficheros se guardan en **NFC** y con orden estable de
   claves; si no, cada exportación del TMS produce un diff ilegible.

### 4.2 Pseudolocalización — prueba automática, no juego

Se genera un locale sintético (`en-XA` o equivalente) desde el catálogo origen, aplicando a la
vez: **expansión** (alargar la cadena un porcentaje fijo), **acentuación** de todos los
caracteres (para detectar texto no extraído: lo que se lea normal, está *hardcodeado*),
**delimitadores** en los extremos (para detectar truncado y desbordamiento) y, en una segunda
variante, **inversión bidi** para el ensayo de RTL.

- ✅ Se despliega en un entorno accesible y **se pasan las pruebas E2E existentes sobre él**: si
  un selector depende del texto visible, el pseudolocale lo rompe — y eso también es un hallazgo.
- ✅ Captura visual de las pantallas clave en pseudolocale, comparada como regresión visual.
- Detecta, sin traductor y sin coste: cadena no extraída, contenedor que desborda, texto
  truncado, concatenación (aparece un trozo sin acentuar en medio) y layout que no sobrevive RTL.

### 4.3 Pruebas de comportamiento (no de implementación)

- **Formateo**: fijar locale y zona **explícitos** en cada test. Un test que pasa en la máquina
  del desarrollador y falla en CI por locale del entorno es un test mal escrito. ❌ Assertar la
  cadena exacta que devuelve `Intl` — **CLDR cambia entre versiones de ICU y el test se rompe
  solo**; assertar propiedades (contiene el número, usa el separador del locale) o fijar la
  versión de ICU del runtime en la imagen.
- **Bordes obligatorios**: 0, 1, 2, 5, 11, 21, 100 en un idioma con `few`/`many` (ruso o polaco)
  y en árabe; nombre con apóstrofo y con caracteres no latinos; texto con emoji ZWJ para el
  truncado; fecha en el instante del cambio de horario de verano en ambos sentidos; importe en
  JPY (0 decimales) y en KWD (3); cadena en NFD comparada contra la misma en NFC.
- **Casos de error**: falta la traducción → *fallback* definido y **registrado**, nunca la clave
  cruda en pantalla; catálogo corrupto → arranque fallido, no degradación silenciosa.

### 4.4 Flujo de trabajo de traducción

- **Clave semántica, jamás el texto inglés como clave.** `checkout.payment.error.card_declined`,
  no `"Your card was declined"`. Con el texto como clave: cualquier corrección de una coma en el
  original invalida todas las traducciones, no se puede distinguir dos usos del mismo texto que
  se traducen distinto (`Open` como verbo y como estado), y la clave se vuelve ilegible en un
  idioma no inglés.
- **Contexto obligatorio en cada clave**: descripción de para qué sirve, dónde aparece, límite de
  longitud si lo hay, y **qué es cada placeholder**. Una cadena sin contexto se traduce mal y el
  error solo se ve en producción. Si el formato lo soporta (`.po` con comentarios extraídos,
  XLIFF con `<note>`), el contexto viaja en el fichero, no en un documento aparte.
- **Captura de pantalla como contexto** cuando la plataforma lo soporte: es lo que más sube la
  calidad por unidad de esfuerzo.
- **El original nunca se edita en el TMS**: se edita en el repositorio y fluye hacia la
  plataforma. El repositorio es la fuente de verdad del texto origen; la plataforma, la de las
  traducciones.
- **Congelar el original antes de traducir.** Traducir texto que aún cambia multiplica coste.
- **Glosario y guía de estilo por idioma** (tratamiento formal/informal, terminología de
  producto, qué **no** se traduce). Sin esto, cada traductor decide y el producto habla con
  varias voces.

## 5. Seguridad

### 5.1 Una traducción es entrada no confiable

**Si el catálogo lo pueden editar colaboradores externos, la cadena traducida es entrada
controlada por un tercero y entra directamente en la interfaz.** Vectores reales:

- **XSS por interpolación en HTML**: la cadena traducida acaba en un `dangerouslySetInnerHTML`,
  `v-html`, `innerHTML` o `Html.Raw` porque el original llevaba un `<b>`. ✅ **El catálogo no
  contiene HTML**: el marcado se pasa como *componente/función* al mensaje (`<b>{x}</b>` resuelto
  por el runtime de i18n, no concatenado), y si es inevitable, **lista blanca de etiquetas y
  saneado en el borde**, con CSP que impida el `script` en línea.
- **Inyección de formato**: una traducción que introduce un placeholder inexistente o un
  `{count, plural}` malformado provoca excepción o fuga del objeto de parámetros. Gate de §4.1.
- **Redirección abierta y *phishing***: URL dentro de una cadena traducible. ✅ **Las URL no van
  en el catálogo**: van como parámetro desde el código.
- **Suplantación por Unicode**: caracteres bidi de control (`U+202E` y familia) y homoglifos en
  una traducción alteran visualmente lo que se lee sin cambiar el texto lógico. ✅ **Rechazar
  caracteres de control bidi en el catálogo** salvo justificación explícita, y normalizar.
- **Control de cambios**: si hay colaboración abierta, **revisión obligatoria antes de fusionar
  al idioma publicado** y separación entre "sugerido" y "aprobado". El mismo criterio que un PR.
- **La plataforma de traducción es un tercero con acceso a texto del producto y a las cuentas de
  quienes traducen**: entra en el inventario de proveedores, con SSO y con revocación.

### 5.2 Datos personales en las cadenas

- ❌ Nombres, correos, teléfonos o identificadores reales como **texto de ejemplo** en el
  catálogo o en las capturas de contexto. Es un tratamiento de datos personales exportado a un
  tercero (el TMS) y a personas externas. Datos sintéticos, siempre.
- ❌ Volcar contenido del usuario a la plataforma de traducción "para dar contexto".
- Los datos personales que sí se tratan (nombre, dirección, teléfono) heredan el criterio de
  `privacy-engineering-standards`: minimización, base legal, retención. Aquí solo la regla dura:
  **el catálogo no es un lugar donde puedan acabar datos personales**.

### 5.3 Traducción automática y LLM en el flujo

- **Aceptable, con revisión humana antes de publicar**: contenido de gran volumen y bajo riesgo
  — documentación de ayuda, descripciones de catálogo, contenido generado por usuarios,
  primer borrador de cadenas de interfaz no crítica.
- **PROHIBIDO publicar sin revisión de un profesional humano competente en el idioma destino**:
  - Texto **legal o contractual** (condiciones, aviso de privacidad, consentimiento).
  - Texto con **consecuencia médica, de seguridad o financiera** (dosis, advertencias, importes,
    instrucciones de emergencia).
  - **Interfaz crítica**: confirmación de acción irreversible, mensajes de error que guían una
    decisión, flujos de pago, autenticación y recuperación de cuenta.
  - Cualquier texto sujeto a **requisito normativo de idioma** (ver `grc-compliance-standards`).
- Regla transversal: **la traducción automática sin revisar se marca como tal en el sistema**
  (estado en el TMS) y **nunca se promueve a "aprobada" por una máquina**. Un LLM puede proponer
  y puede detectar inconsistencias; no puede firmar.
- El LLM traduce **el mensaje completo con su contexto y su glosario**, no cadenas sueltas; y se
  le pasa la restricción de longitud y las categorías plurales del idioma destino como parte del
  encargo, o devolverá cadenas que rompen §4.1.

## 6. Rendimiento y operabilidad

- **Un catálogo por idioma, cargado por idioma.** ❌ Servir todos los idiomas al cliente. La
  división por ruta o por vista solo si el catálogo es grande de verdad; medir antes.
- **Datos de ICU en el cliente**: si se usa una librería que empaqueta CLDR, **es el mayor coste
  en bytes de la i18n**. Usar `Intl` de la plataforma elimina ese coste por completo — es la
  razón operativa por la que `Intl` es el default de §2.
- **Renderizado en servidor**: el locale debe resolverse **antes** de renderizar; si el servidor
  renderiza en un idioma y el cliente hidrata en otro, hay desajuste de hidratación y parpadeo.
  El locale forma parte de la **clave de caché** (y de `Vary`, ver `caching-cdn-standards`).
- **Observabilidad mínima**: métrica de **claves faltantes por idioma y por versión** (una subida
  indica despliegue de código sin catálogo), métrica de idiomas realmente usados (para retirar
  los que nadie usa), y registro de *fallback* aplicado. Sin esto, la degradación es invisible.
- **Versión de ICU/CLDR del runtime en producción como dato observable**: dos réplicas con ICU
  distinto formatean distinto y ordenan distinto. Fijarla en la imagen.
- **Cadencia de actualización**: `tzdata` con cada release de IANA (varias al año, §3.5); ICU y
  CLDR con la del runtime, verificando que los cambios de colación no invalidan índices en el
  motor (eso lo gobierna `sql-standards`, pero **se detecta aquí**).

## 7. Sostenibilidad y prohibiciones

- **Diseño i18n-ready desde el primer día aunque el producto sea monolingüe.** Lo caro no es
  traducir: es descubrir que el esquema, la API y las plantillas asumen un solo idioma.
- **Deuda declarada**: si se toma un atajo (campo de nombre partido, formateo manual), queda un
  `TODO` con el motivo y una incidencia, no un comentario.
- **Revisión periódica del catálogo**: claves muertas fuera, cobertura por idioma revisada, y
  retirada explícita de un idioma que nadie usa (con aviso, no en silencio).

Prohibido, sin excepción:

- ❌ **Concatenar fragmentos de frase** para construir un mensaje. Incluye construir la frase con
  plantillas de dos trozos y meter el verbo por variable.
- ❌ **Usar el texto en inglés como clave** del catálogo.
- ❌ `toUpperCase()` / `toLowerCase()` **sin locale explícito** para presentación, y usar el de la
  interfaz para comparar (el turco `i`, §3.4).
- ❌ **Ordenar cadenas por punto de código** y llamarlo orden alfabético.
- ❌ Truncar o limitar texto **por unidad de código** en lugar de por grafema.
- ❌ **Regex propia** para validar teléfono, código postal, nombre o correo internacionalizado.
- ❌ `float` para importes; asumir **dos decimales** en cualquier moneda.
- ❌ Guardar un **offset** en lugar de un identificador IANA de zona.
- ❌ Guardar una **fecha civil como instante** (cumpleaños, vencimiento, festivo).
- ❌ Enviar una imagen de contenedor o un runtime a producción **sin `tzdata` actualizado**.
- ❌ **HTML dentro del catálogo** de traducción, y **URL dentro del catálogo**.
- ❌ Publicar traducción automática **sin revisión humana** en las clases de §5.3.
- ❌ Aceptar traducción de colaborador externo **sin revisión** en un idioma publicado.
- ❌ Un plural **binario** (`singular`/`plural`) en el catálogo o en el código.
- ❌ Asumir que **RTL es el mismo diseño invertido**: los iconos direccionales se espejan
  (flecha de "siguiente", "deshacer") pero **los que no son direccionales no** (reloj, logotipo,
  algunos medios); los números y el código embebido siguen leyéndose de izquierda a derecha
  dentro del párrafo RTL; los gráficos, el progreso y las tablas cambian de origen; y **hay que
  probarlo en árabe o hebreo reales**, no solo con `dir="rtl"` sobre texto latino. La
  implementación con propiedades lógicas de CSS la fija `frontend-web-platform-standards`.
- ❌ Fijar el idioma por **geolocalización de IP** sin permitir cambiarlo y sin persistir la
  elección.
- ❌ Assertar en un test la **cadena exacta** producida por `Intl`/ICU sin fijar la versión de ICU.
- ❌ Desplegar código con claves nuevas **sin el catálogo correspondiente** (rompe §4.1 y llega a
  producción como clave cruda en pantalla).

## 8. Verificación web obligatoria

Comprobar **antes de fijar nada** en un proyecto real:

1. **CLDR**: versión vigente y fecha. Verificado: CLDR 48 (2025-10-29), 48.1 (2026-01-08), 48.2
   (2026-03-17), y un parche JSON 48.2.1 por `tzdb` 2026c. **CLDR 49 + ICU 79 estaban anunciados
   para octubre de 2026.** *Discrepancia declarada*: el directorio
   `https://www.unicode.org/Public/cldr/49/` **ya existe** en el listado público pero solo
   contiene `README.html` — **la existencia del directorio no es una release**; comprobar
   `cldr.unicode.org/index/downloads` y el blog de Unicode antes de afirmar que CLDR 49 salió.
2. **ICU**: versión vigente de ICU4C/ICU4J y la que trae tu runtime. *Discrepancia declarada*: el
   feed Atom de `unicode-org/icu` **mezcla etiquetas de ICU4X** (`icu4x/2026-07-01/79.x`) con
   releases de ICU (`ICU 78.3`, `ICU 78.2`, `ICU 78.1`); **el número más alto del feed no es la
   versión de ICU**. Contrastar con `icu.unicode.org`.
3. **Unicode**: 17.0 salió el 2025-09-09; **18.0 estaba planificado para el 2026-09-15** —
   verificar si ya salió y qué versión de Unicode implementa tu runtime (no siempre la última).
4. **`tzdata`**: última release en `data.iana.org/time-zones/tzdb/NEWS` (verificado: **2026c,
   2026-07-08**) y, sobre todo, **qué versión tiene cada copia en tu sistema**: imagen base, JDK,
   runtime, base de datos y librería de fechas embebida.
5. **`Temporal`**: estado en `@mdn/browser-compat-data` y en MDN (verificado: **no Baseline**,
   Safari solo en *preview* tras el flag `useTemporal`, Safari iOS no). Verificar también si Node
   26 ya entró en LTS (en ago-2026 era *Current*, `lts: false`).
6. **`Intl`**: soporte real de la API concreta que vayas a usar en tus objetivos de navegador y
   runtime, y **si el runtime lleva ICU completo o *small-icu***.
7. **MessageFormat 2**: estado en CLDR/UTS #35 **y por separado** el estado de
   `tc39/proposal-intl-messageformat` (verificado: `Stage: 1`) y el soporte real en tu TMS y en
   tu librería. No confundir estándar estable con API disponible.
8. **`libphonenumber`**: última etiqueta (verificado `v9.0.36`) y **licencia leída del `LICENSE`
   en crudo** (verificado Apache-2.0). Si usas un envoltorio npm, verificar que sigue mantenido y
   que su cobertura es la que necesitas.
9. **Plataformas de traducción**: precio, límites del plan gratuito, condiciones del plan de
   código abierto y **licencia real leída del `LICENSE` del repositorio**, no del *marketing*.
   Verificado en ago-2026 (§2.4). **Advertencia**: los directorios de comparación de software
   dieron datos incorrectos para Lokalise (listaban plan gratuito; la web oficial no lo tiene) y
   precios de entrada fijos para Crowdin y Transifex, que cotizan por volumen. **Fuente = página
   oficial y `LICENSE` en crudo.**
10. **ISO 4217** (unidades mínimas por moneda) e **ISO 3166-1** (lista de países): tomarlos de
    CLDR, no de una copia; ambos cambian.
11. **UPU S42** para formato de dirección internacional, y las referencias de nombres del §3.1
    (W3C *Personal names around the world*; *Falsehoods programmers believe about names*) —
    verificar que siguen accesibles y si hay versión más reciente.
12. **Hueco declarado (sin presupuesto de verificación en esta pasada)**: no se ha verificado el
    estado, licencia ni límites de otras plataformas relevantes (**Phrase, Pontoon, Locize,
    Localazy, Weglot, Smartling**) ni el detalle de los créditos de traducción automática del
    plan gratuito de Tolgee (la página no lo publica en cifras). **No se rellena por analogía**:
    si el proyecto las considera, verificarlas en su página oficial y en su `LICENSE`.
13. **Hueco declarado**: no se ha localizado ningún estudio con metodología publicada sobre el
    impacto de la pseudolocalización o de la revisión humana en la tasa de defectos de
    localización. Las cifras que circulan en material comercial de vendedores de TMS
    («X % menos defectos», «Y % de ahorro») **no tienen metodología publicada y se descartan
    deliberadamente**: aquí no hay número porque no hay fuente.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
