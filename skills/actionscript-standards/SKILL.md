---
name: actionscript-standards
description: ActionScript, Flash and AIR - a dead runtime, its surviving artifacts and the exit route. Use when working with .as, .fla, .swf, .swc, .flv, .f4v, .abc (ActionScript Byte Code), .mxml or .air files, ActionScript 2 versus ActionScript 3 and AVM1/AVM2, the Flex SDK and Apache Flex, Apache Royale as the Flex migration path, mxmlc/compc/asc2 compilers, air-sdk-description.xml and AIR application descriptors, ADT packaging and adl, HARMAN Adobe AIR SDK licensing tiers and air.system.License, Adobe Animate documents and HTML5 Canvas export, Flash Player projectors and the standalone player, ExternalInterface, crossdomain.xml, allowScriptAccess, Ruffle emulation of AVM1/AVM2 content, or auditing, archiving, isolating or removing Flash content from an estate.
---

# Estándares de ActionScript, Flash y AIR

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Flash está muerto. No es una opinión ni una previsión: es un hecho con dos fechas de Adobe, citadas
verbatim de su página de fin de vida:**

> *"Adobe stopped supporting Flash Player beginning December 31, 2020 ("EOL Date")"*
> *"Adobe blocked Flash content from running in Flash Player beginning January 12, 2021"*

**Encuadre de seguridad, que es el que manda esta skill: un `.swf` servido y un runtime de Flash
instalado en una red corporativa en 2026 no son "legacy tolerable", son un hallazgo de
vulnerabilidad.** El runtime lleva más de cinco años sin parches, su historial de explotación era el
peor de la industria (fue durante una década el vector preferido de los *exploit kits*), y las
versiones que siguen funcionando **son precisamente las que alguien desactivó el bloqueo o instaló
desde una fuente no oficial** — es decir, un binario sin procedencia. Trátalo como tal: inventario,
riesgo, plan de retirada con fecha.

**Entonces, ¿por qué existe esta skill? Por lo que sigue existiendo:**
1. **Artefactos**: `.swf`, `.fla`, `.as`, `.swc` en repositorios, intranets, material formativo,
   cursos SCORM, sistemas SCADA/HMI y quioscos. Hay que **saber leerlos para decidir qué se hace con
   ellos**, y a menudo para reconstruir el contenido que representan.
2. **Adobe AIR**, que **no murió con Flash**: HARMAN lo mantiene y lo licencia (§2). Hay aplicaciones
   de escritorio y móviles en producción escritas en ActionScript 3 sobre AIR, y sus dueños necesitan
   criterio de soporte y de coste, no un sermón.
3. **Preservación y archivo**: contenido cultural, histórico e institucional que solo existe en `.swf`
   y que se conserva con emulación (§7), no con el runtime original.

**Nada nuevo se escribe en ActionScript para la web.** Para AIR, mantener y actualizar una aplicación
existente es legítimo; empezar una nueva no lo es (§7).

**No aplica**: ver `frontend-web-platform-standards` (**el destino por defecto de todo contenido
Flash interactivo**: HTML, CSS, APIs del navegador, Canvas, presupuesto de carga y seguridad del
cliente), `webgl-webgpu-standards` (**el destino de lo que era gráfico acelerado o Stage3D**: canvas,
pipeline de GPU y presupuesto de fotograma), `webassembly-standards` (**el destino de los motores
portados y el runtime de Ruffle**: el módulo, su sandbox y su tamaño son suyos),
`frontend-frameworks-standards` y `typescript-standards` (**el lenguaje y el framework destino de
una reescritura**: ActionScript 3 y TypeScript comparten ancestro —ECMAScript 4— y eso hace la
traducción *engañosamente* fácil, pero el modelo de display list, los eventos y el ciclo de vida no
tienen equivalente: no es un port, es una reescritura), `mobile-standards` (**si el destino de una
app AIR es nativo iOS/Android**), `dart-standards` (**Flutter como destino multiplataforma**),
`vulnerability-management-standards` (**el proceso de inventario, triaje y SLA de retirada es suyo**;
aquí por qué este activo entra en él con prioridad), `appsec-standards` (modelado de amenazas y
clases de vulnerabilidad), `detection-engineering-standards` y `soc-operations-standards` (detectar
ejecución de Flash en el parque), `linux-hardening-standards`, `macos-fleet-standards` y
`windows-server-ad-standards` (**la retirada del runtime del parque es suya**),
`knowledge-management-standards` (preservación documental), `refactoring-tech-debt-standards`
(*strangler fig* y caracterización), `enterprise-architecture-standards` (cartera y decisión de
retirar), `legacy-modernization-standards` (**skill paraguas**: qué "R" se elige para el activo
Flash/AIR —congelar y contener, reescribir o retirar— y el coste fechado de no hacer nada) y
`migration-projects-standards` (**la ejecución del corte** una vez decidido: ensayo, ventana,
marcha atrás y fecha de descomisionado del contenido y del runtime),
`opensource-licensing-standards` (licencias; aquí la de AIR, §2),
`jsp-struts-standards`, `classic-asp-standards`, `coldfusion-standards` y `vb6-standards` (**otras
tecnologías muertas o congeladas del catálogo, con problemas distintos**: allí el servidor sigue
ejecutando; **aquí el problema es que el cliente ya no puede ejecutar nada**, y eso cambia toda la
estrategia — no se extrapola criterio entre ellas).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada (ago-2026) |
|---|---|---|
| Flash Player | **Retirar del parque. Sin excepciones ni "hasta que migremos"** | Sin soporte desde el **31-dic-2020**; contenido bloqueado desde el **12-ene-2021** (citas verbatim en §1). Cualquier reproductor que aún funcione está fuera del canal oficial |
| Contenido `.swf` que hay que seguir viendo | **Ruffle**, emulador en Rust/Wasm, **aislado** | **Muy activo** (compilaciones *nightly* diarias, la última del 5-ago-2026) y **sin release estable**: se consume por nightly, con lo que eso implica para reproducibilidad. **Compatibilidad parcial y hay que decirlo**: su propia página declara **AVM1 (AS1/AS2): lenguaje 99 %, API 82 %**; **AVM2 (AS3): lenguaje 90 %, API 80 %**, con *"decent support for AVM 2 … most games will work well enough to be played"*. **No es un sustituto transparente del reproductor**: es una vía de acceso y de preservación |
| Adobe AIR | **Vivo, bajo HARMAN, y de pago** | Sigue mantenido y actualizado para SO actuales. **Modelo de licencia por suscripción anual con cuatro niveles —`enterprise`, `professional`, `basic`, `free`— verificados en la referencia oficial del API `air.system.License`**, que además expone `expiryDate`, `numberOfSeats` y `checkDetailsOnline`: **el propio runtime comprueba la licencia**. El nivel gratuito impone **pantalla de arranque con marca HARMAN/Adobe** y no da soporte. **Los precios son bajo consulta: el coste de licencia y su renovación es el dato caro de esta skill** |
| Versión del AIR SDK | **Serie 51.x** | **Hueco declarado: no pude verificarla en la fuente oficial** — el sitio de HARMAN es una SPA que no sirve el dato en HTML. Consúltala en su portal autenticado; **no la fijes desde una fuente secundaria** (§8) |
| Aplicaciones Flex | **Apache Royale** es la vía de migración documentada (compila MXML y AS3 a JavaScript) | **Último release verificado: 0.9.12, del 11-dic-2024** — más de año y medio sin publicar, y aún en `0.x` tras años. **Es una vía de salida, no una plataforma de destino**: úsala para reducir el coste de convertir una base Flex grande, con el compromiso explícito de acabar en HTML/TS |
| Apache Flex / Flex SDK | **Fin de camino** | Solo para compilar y analizar lo existente. Nada nuevo |
| AS2 (AVM1) frente a AS3 (AVM2) | **Son lenguajes y máquinas virtuales distintos**, no dos versiones | AS2 es débilmente tipado, con `_root`/`_global`, *timeline scripting* y `on(...)` en clips: no hay migración mecánica a AS3. AS3 tiene clases, paquetes, tipado, `Event`/`EventDispatcher` y display list. **AS2 solo se toca para archivar** |
| `.fla` | **Formato propietario de Adobe Animate**, no de texto | No es versionable ni revisable en Git. El código vive en `.as` externos; el `.fla` es el activo de diseño. **Adobe Animate sigue existiendo y exporta a HTML5 Canvas/WebGL: es la ruta para el contenido de animación** — verifica su estado y su licencia antes de comprometer (§8) |
| `.swf` como formato | **Especificación pública y binario decompilable** | Un `.swf` **no protege nada**: bytecode ABC decompilable con herramientas comunes. Si contiene una clave, un endpoint interno o lógica de negocio sensible, **eso ya está expuesto** (§5) |

## 3. Seguridad del stack

*(Esta skill sustituye la §5 canónica por este bloque: en una tecnología muerta, la seguridad **es** el
criterio, no una sección más.)*

- **Postura obligatoria: el runtime de Flash se retira; el contenido se aísla o se convierte.** No
  hay "actualizar a una versión parcheada": no existe.
- **Un `.swf` alojado es un activo a inventariar**, aunque nadie lo pueda ejecutar ya: se sirve, se
  indexa y **se puede descargar y decompilar**. Antes de archivarlo o publicarlo, revísalo en busca
  de **credenciales, tokens, endpoints internos, rutas y lógica de autorización embebidos** — es un
  hallazgo frecuentísimo, porque durante años se dio por hecho que el `.swf` era opaco.
- **`crossdomain.xml` es una política de origen cruzado que sigue viva en tu servidor.** Un
  `crossdomain.xml` con `allow-access-from domain="*"` en la raíz de un dominio autenticado es una
  vulnerabilidad **que no depende de que Flash exista**: otros clientes la respetan y sigue
  documentando tu superficie. **Bórralo si ya no sirve a nada**, y jamás con comodín.
- **`allowScriptAccess`, `allowDomain`, `ExternalInterface`** describen un puente bidireccional entre
  contenido no confiable y el DOM. Si queda contenido embebido, ese puente es un XSS con pasos extra.
- **Ruffle no elimina el riesgo, lo acota**: es un emulador que ejecuta contenido no confiable, y su
  superficie es la de un intérprete escrito en Rust y compilado a Wasm. Sirve **contenido archivado y
  conocido**, desde un **origen aislado** (subdominio propio, sin cookies de sesión, con CSP
  restrictiva), nunca desde el dominio de la aplicación autenticada. Su criterio de sandbox y de
  límites es de `webassembly-standards`.
- **Reproductores "portables", *projectors* y parches para saltar el bloqueo de Adobe: prohibidos.**
  Son binarios de procedencia desconocida distribuidos precisamente para reactivar un runtime
  bloqueado por su fabricante. Detéctalos en el parque y elimínalos (`detection-engineering-standards`).
- **AIR**: la aplicación empaquetada **incluye el runtime**. Actualizar AIR significa **reempaquetar y
  redistribuir la aplicación**; si no lo haces, tus usuarios corren un runtime viejo aunque HARMAN
  haya publicado la corrección. Cadencia de reempaquetado explícita, y firma de la aplicación con
  certificado vigente y rotado.

*§4 y §6 se omiten deliberadamente*: no hay una práctica viva de testing ni de operabilidad que fijar
para una plataforma retirada. Lo que se aplica —tests y CI de la aplicación AIR que sigas
manteniendo, y del destino de la migración— es de `testing-qa-standards`, `cicd-standards` y de la
skill del lenguaje destino.

## 7. Ruta de salida y prohibiciones

**No hay estrategia de "mantener": hay ruta de salida.** Elige por tipo de contenido:

| Qué es | Destino |
|---|---|
| Animación o material formativo | Reexportar desde el `.fla` original a **HTML5 Canvas/WebGL** (Animate) o rehacer en vídeo si es lineal. **Sin el `.fla`, es reconstrucción, no conversión** |
| Juego o aplicación interactiva | Reescritura sobre **Canvas/WebGL** (`frontend-web-platform-standards`, `webgl-webgpu-standards`), o motor moderno; si el motor original es C/C++, **WebAssembly** |
| Aplicación Flex de empresa | **Apache Royale** como puente para reducir coste, **con compromiso escrito de destino final en HTML/TS** (§2); o reescritura directa por dominios |
| Aplicación AIR de escritorio/móvil viva | Mantener bajo licencia HARMAN mientras el coste lo justifique, **con cifra de licencia y de renovación por escrito**, o migrar a nativo/Flutter/web |
| Contenido histórico sin dueño | **Preservación**: conservar el `.swf` como objeto de archivo con metadatos, y servirlo con **Ruffle en origen aislado** (§3). Es la única vía honesta cuando no hay fuente |
| Contenido sin valor identificado | **Retirar.** La mayor parte del `.swf` de un parque cae aquí, y es la opción más barata y más segura |

**Regla de decisión**: si no aparece dueño ni valor en el inventario, **se borra**; la carga de la
prueba está en quien quiere conservarlo, no en quien lo retira.

**Prohibiciones:**
- ❌ **PROHIBIDO** instalar, reactivar o mantener Flash Player en cualquier equipo del parque, o
  distribuir reproductores/*projectors* de terceros para saltarse el bloqueo del 12-ene-2021.
- ❌ **PROHIBIDO** escribir contenido nuevo en ActionScript para la web, o arrancar un proyecto nuevo
  sobre AIR.
- ❌ `crossdomain.xml` con comodín, o dejado en el servidor "por si acaso".
- ❌ Servir contenido `.swf` (aunque sea vía Ruffle) desde el origen de una aplicación autenticada.
- ❌ Tratar un `.swf` como contenedor seguro: **claves, tokens o endpoints internos dentro de un
  `.swf` se consideran comprometidos** y se rotan (§3).
- ❌ Migración automática AS2 → AS3, o AS3 → TypeScript, presentada como conversión: son reescrituras
  (§2).
- ❌ Redistribuir una aplicación AIR sin reempaquetar con un SDK actualizado, o con certificado de
  firma caducado.
- ❌ Comprometerse con el nivel gratuito de HARMAN sin asumir la pantalla de marca y la ausencia de
  soporte; o presupuestar cualquier nivel comercial sin cifra escrita de licencia **y renovación**.
- ❌ Presentar Ruffle como compatibilidad total: su AVM2 está al **90 % de lenguaje y 80 % de API**
  según el propio proyecto (§2).
- ❌ Dejar `.swf` sin dueño en un inventario indefinidamente. Tienen fecha de retirada o tienen dueño.

## 8. Verificación web obligatoria

1. **Las dos fechas de Adobe** (31-dic-2020 fin de soporte; 12-ene-2021 bloqueo del contenido) en su
   página oficial de fin de vida de Flash Player. **Cítalas verbatim; no las parafrasees ni las
   redondees a "2021".**
2. **AIR SDK de HARMAN — hueco declarado**: la versión vigente (serie 51.x según fuentes secundarias)
   **no es verificable desde su web pública**, que es una SPA. Consúltala en el portal del producto.
   **Los niveles de licencia sí están verificados** en la referencia oficial `air.system.License`
   (`enterprise`/`professional`/`basic`/`free`, con `expiryDate` y `numberOfSeats`).
3. **Precio de AIR — hueco estructural**: HARMAN no publica tarifas; son bajo consulta y por umbral
   de ingresos. Cualquier cifra tiene que salir de una oferta contractual, y hay que preguntar
   explícitamente por la **renovación** y por las condiciones de auditoría.
4. **Ruffle**: estado de compatibilidad AVM2 en su página de compatibilidad (a ago-2026: lenguaje
   90 %, API 80 %) y si ha aparecido una release estable — a ago-2026 solo publica *nightlies*
   (última verificada, 5-ago-2026). Verifica también sus CVEs: es un intérprete de contenido hostil.
5. **Apache Royale**: si hay release posterior a **0.9.12 (11-dic-2024)** y si ha salido de `0.x`.
   Un puente de migración sin releases es un riesgo que hay que poner por escrito.
6. **Adobe Animate**: estado del producto, su modelo de licencia y qué exporta hoy (HTML5 Canvas,
   WebGL), antes de comprometer una conversión con él.
7. CVEs históricos de Flash Player y de AIR asociados a lo que aún tengas desplegado, y CVEs del
   propio Ruffle si lo despliegas.
8. Estado de bloqueo de Flash en los navegadores y sistemas de tu parque, para confirmar que **nadie
   ha reactivado nada** (es lo que suele encontrar la auditoría).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
