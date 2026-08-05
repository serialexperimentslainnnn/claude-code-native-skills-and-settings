---
name: pascal-delphi-standards
description: Object Pascal in production - Embarcadero Delphi and Free Pascal/Lazarus, and the migrate/wrap/freeze decision. Use when working with .pas/.dpr/.dpk/.dfm/.fmx/.dproj/.groupproj Delphi files or .lpr/.lpi/.lfm/.lpk Lazarus files, the RAD Studio IDE and its Florence/Athens/Sydney/Berlin/Tokyo releases, dcc32/dcc64/msbuild command-line Delphi builds and .dcu/.bpl output, fpc and lazbuild, VCL versus FireMonkey/FMX, TForm/TDataModule/TComponent and published properties with RTTI, third-party VCL component packages and their .bpl runtime packages, string/AnsiString/UnicodeString/WideString and the Delphi 2009 Unicode break, PChar and PAnsiChar, ShortString, TStringList, BDE and IDAPI.CFG legacy data access, dbExpress, FireDAC with TFDQuery and FDConnectionDefs.ini, ADO/ODBC layers, exports and stdcall/cdecl DLL interop, COM/ActiveX with TypeLib, Delphi Community Edition eligibility and RAD Studio per-developer licensing cost, Lazarus LCL widgetset cross-compilation, or evaluating a Delphi codebase for rewrite to .NET.
---

# Estándares de Object Pascal (Delphi y Free Pascal/Lazarus)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplicaciones **Object Pascal** en producción: mantenimiento, contención y salida. Dos mundos que
comparten lenguaje y casi nada más — **Delphi** (Embarcadero, comercial, de pago por desarrollador) y
**Free Pascal + Lazarus** (libre).

**Estado honesto del dominio, aquí y no escondido en §7**: Delphi **no está muerto** —hay releases
recientes, con compilador nuevo para Windows on Arm y soporte de Android al día (§2)—, pero **su
ecosistema sí lleva décadas encogiendo**: la cuota de mercado es marginal, la contratación es difícil
y cara, el catálogo de componentes de terceros está lleno de piezas abandonadas de las que dependen
aplicaciones enteras, y **el coste de licencia por desarrollador es de cuatro cifras al año** (§2).
Del lado libre el diagnóstico es distinto y también incómodo: **la última versión estable de Free
Pascal es la 3.2.2, de mayo de 2021**, y Lazarus sigue publicando bugfixes construidos sobre ella. No
es abandono —hay actividad continua— pero **la cadencia de release del compilador libre se mide en
años**, y eso es un dato de riesgo que hay que poner sobre la mesa antes de apostar.

Traducido a criterio: **una aplicación Delphi que funciona y no crece se mantiene; una que crece
necesita un plan explícito** (§7). Y **empezar un proyecto nuevo en Delphi solo se justifica si ya
tienes equipo, licencias y una base de código que reutilizar** — nunca por elegirlo desde cero.

Cubre: versiones y licencias de ambas cadenas, tipos de fichero, VCL frente a FMX, la cicatriz de
Unicode, acceso a datos, interoperabilidad, y la decisión de migrar, envolver o congelar.

**No aplica**: ver `vb6-standards` y `classic-asp-standards` (**el legacy Microsoft de la misma
época**: comparten el patrón "app de escritorio de los 90 que sigue facturando", **no la
plataforma** — Delphi compila nativo, tiene compilador y IDE con soporte vigente y una empresa
detrás cobrando por él; VB6 no tiene ninguna de las tres cosas. **No extrapoles criterio entre
ellas**), `dotnet-framework-legacy-standards` (.NET Framework 4.x: el escalón intermedio del mundo
Microsoft), `dotnet-standards` (**el destino más habitual de una reescritura, y el dueño del
criterio del código resultante** — SDK, TFM, ASP.NET Core, EF Core, empaquetado — **no esta skill**),
`legacy-modernization-standards` (**suya la estrategia** — análisis de cartera, decisión de
invertir/migrar/retirar/congelar, secuenciación, financiación; **aquí el criterio técnico de esta
plataforma y los hechos que alimentan esa decisión**), `migration-projects-standards` (**suya la
ejecución del corte** una vez decidido: *runbook*, ensayo, ventana, criterios de abortar, rollback
ensayado y descomisionado del sistema origen),
`refactoring-tech-debt-standards` (*strangler fig*, rama por abstracción, caracterización de código
sin tests), `enterprise-architecture-standards` (inventario, modelo TIME),
`testing-qa-standards` (estrategia de prueba), `cicd-standards` (la pipeline),
`git-workflow-standards` (**y en especial el manejo de binarios y ficheros generados**),
`sql-standards` y `sqlserver-dba-standards`/`oracle-dba-standards`/`mysql-mariadb-dba-standards`
(el motor detrás de FireDAC), `api-design-standards` (el contrato del servicio que envuelva al
monolito), `appsec-standards` (modelado de amenazas), `vulnerability-management-standards`,
`opensource-licensing-standards` (**la excepción de enlace estático de la RTL de FPC es el dato que
decide si puedes distribuir cerrado**, §2), `windows-server-ad-standards`,
`vmware-standards`/`hyper-v-standards` (el host de una máquina de build congelada),
`backup-recovery-standards` (**la máquina de build y sus componentes de terceros son un activo a
respaldar**), `c-standards`/`cpp-standards` (el otro lado de una DLL nativa).

## 2. Decisiones por defecto — versiones, licencia y coste

> Verificar por web antes de fijarlo en cualquier documento con consecuencias (§8).

| Decisión | Criterio | Verificado a ago-2026 |
|---|---|---|
| Delphi comercial | **RAD Studio 13.1 "Florence"** | RAD Studio/Delphi/C++Builder **13 "Florence"** salió el **10-sep-2025**; **13.1 (Release 1)** con build actualizada el **18-mar-2026**. Novedades relevantes: **compilador Delphi nativo Arm64EC** (Windows on Arm, ABI Arm64EC → mezcla con binarios x64 existentes), **Android API 36.1** (requerido por Google Play desde ago-2026) y motor LSP con LSIF |
| **Coste por desarrollador — el dato caro** | **Cuatro cifras por puesto, y es licencia nominal** | Precios de partida de **licencia nueva** en revendedor (ComponentSource, ago-2026): **Professional ≈ 1.583 USD**, **Enterprise ≈ 3.959 USD**, **Architect ≈ 5.939 USD**. Modelo **Named User (Workstation)**: una persona, una máquina, sin uso concurrente, **válida solo en el país de compra** (salvo movilidad dentro de la UE). La suscripción exige **renovación anual** para seguir usando el producto. **Precio de lista y de revendedor difieren: pide oferta (§8)** |
| Community Edition | **Sirve para aprender y para micro-negocio; no para una empresa** | Gratuita, licencia de 1 año renovable, **hasta que los ingresos anuales del individuo o la empresa alcancen 5.000 USD** o el equipo pase de **5 desarrolladores**. El umbral es sobre **ingresos totales**, no sobre los que genere la app; una empresa que factura más **no puede usarla ni para uso interno**. **No es una versión de prueba** (para eso, el trial de 30 días). **No existe RAD Studio CE**: solo Delphi CE y C++Builder CE |
| Free Pascal | **FPC 3.2.2 — y ese es el dato incómodo** | **3.2.2 es de mayo de 2021** y sigue siendo la estable; **3.2.4 solo existe como RC** (se usa para las builds de macOS de Lazarus). La web del proyecto avisa además de que 3.2.2 no está disponible para todas las plataformas ni formatos por falta de constructores y probadores de release |
| Lazarus | **Lazarus 4.8** (bugfix) | **11-jun-2026**, *"built with FPC 3.2.2, and FPC 3.2.4RC1 for macOS"* (verbatim de la web del proyecto). Cadencia de bugfix sana, sobre un compilador cuya estable no se mueve |
| Licencia de FPC/Lazarus | **Permite producto cerrado — pero léelo, no lo asumas** | El **compilador y utilidades van bajo GPL**; la **RTL y los paquetes que acaban dentro de tu ejecutable, bajo una LGPL modificada con excepción de enlace estático**, y esa excepción es lo que hace legal distribuir binarios propietarios. **Obligaciones que quedan**: indicar de dónde se baja el fuente de la RTL, y **publicar tus modificaciones de la RTL si la modificaste**. Asesoría legal para el caso concreto |
| Elegir entre ambos | **Delphi** si ya hay código VCL grande, componentes comerciales y presupuesto; **FPC/Lazarus** si el criterio es coste cero, control de la cadena o compilación cruzada amplia | La compatibilidad de fuente es **buena pero no total** (`{$MODE DELPHI}`/`{$MODE OBJFPC}`); los componentes visuales comerciales y las partes más nuevas del RTL de Delphi **no portan** |
| Acceso a datos | **FireDAC**. **BDE vetado** | DocWiki de Embarcadero: el BDE **está deprecado y no se mejorará** — *nunca tendrá soporte Unicode* —, no se debe hacer desarrollo nuevo con él y hay que migrar a FireDAC. Desde XE7 (2014) ni siquiera se instala con el producto. Migración asistida con `reFind` y el fichero de reglas `FireDAC_Migrate_BDE.txt`; los alias pasan de `IDAPI.CFG` a `FDConnectionDefs.ini` |
| VCL frente a FMX | **VCL** para Windows de escritorio; **FMX** solo si de verdad hay multiplataforma | No son intercambiables: cambiar de framework **es reescribir toda la capa de presentación**. "Lo pasamos a FMX y ya es multiplataforma" es falso y es la promesa que más proyectos ha hundido en este dominio |

## 3. Estructura, convenciones y la cicatriz de Unicode

- **Ficheros y qué va a Git**: `.pas` (unidad), `.dpr` (programa), `.dpk` (paquete), `.dfm`/`.fmx`
  (formulario, **guardar en texto, nunca en binario** — si no, la revisión de diffs y el *merge*
  son imposibles), `.dproj`/`.groupproj` (proyecto MSBuild). En Lazarus: `.lpr`, `.lpi`, `.lfm`,
  `.lpk`. **Nunca a Git**: `.dcu`, `.ppu`, `.o`, `.exe`, `.bpl`, `.dproj.local`, `.identcache`,
  `__history/`, `__recovery/` y el directorio de salida.
- **Compilación reproducible desde línea de comandos**, no desde el IDE: `msbuild` sobre el
  `.dproj` (o `dcc32`/`dcc64` directo), `lazbuild` en Lazarus. **Un proyecto que solo compila con
  el IDE abierto en la máquina de alguien no tiene build, tiene un rito.** Y las rutas de búsqueda
  se declaran en el proyecto, relativas, no en las opciones globales del IDE de cada uno.
- **La migración ANSI→Unicode de Delphi 2009 es la cicatriz que aún parte proyectos.** Ahí `string`
  pasó de `AnsiString` a `UnicodeString` (UTF-16) y `Char` a 2 bytes. Lo que sigue mordiendo:
  **`Length(S)` ya no son bytes** (todo lo que asumía 1 byte = 1 carácter está mal: `SizeOf(Char)` o
  `TEncoding`, nunca constantes); **`PChar` pasó a ser `PWideChar`**, así que toda llamada a API de
  Windows o a DLL de terceros hay que revisarla una a una; y sobre todo **la E/S binaria y las
  estructuras persistidas**: escribir un `string` a fichero, socket o BLOB con código pre-2009 cambia
  el formato en disco — **así es como esta migración corrompe datos, en silencio**. Regla operativa:
  si el proyecto no ha cruzado 2009, **eso es un proyecto propio, con caracterización sobre ficheros
  y BLOBs reales**, no un paso dentro de otro; y `AnsiString`/`RawByteString` explícitos con codepage
  declarado allí donde el formato en disco o en cable sea de bytes.
- **Nada de lógica en el formulario**: el negocio vive en unidades sin dependencia de la VCL. Es lo
  que hace posible testear (§4) y lo que decide si una migración futura es planteable. Un `TForm` de
  8.000 líneas con SQL dentro es el patrón por defecto del dominio y **es el trabajo a deshacer**.
- **Recursos**: `try..finally` para todo objeto creado, siempre. Y en interfaces, el conteo de
  referencias actúa sobre la **interfaz**, no sobre la variable declarada como clase: mezclar ambos
  accesos al mismo objeto es la fuga clásica.
- **Componentes de terceros**: inventario escrito con versión, licencia, fuente disponible sí/no y
  estado de mantenimiento. **Un componente binario sin fuente y sin proveedor vivo es un límite
  duro de portabilidad y de versión de compilador**, y hay que saberlo antes de planificar, no
  durante.

## 4. Calidad, tests y CI

Sección deliberadamente breve: el tooling de este ecosistema es limitado y conviene no fingir lo
contrario.

- **Tests**: **DUnitX** en Delphi moderno (`FPCUnit` en Lazarus). Requisito previo real: **la lógica
  debe estar fuera de los formularios**; lo que está en el `TForm` no es testeable sin GUI y no se
  va a testear.
- **Compilación como gate**: build por línea de comandos en CI, **avisos y hints tratados como
  errores** en el código propio, y **cero avisos nuevos** como regla de merge. Es el análisis
  estático que sí tienes garantizado.
- **Análisis y estilo**: existen herramientas (formateadores del IDE, analizadores comerciales, y
  del lado libre `pas2js`/utilidades de FPC), pero **el ecosistema de linters es pobre comparado
  con cualquier stack mainstream**. No planifiques calidad apoyándote en herramientas que no vas a
  tener: apóyate en revisión y en tests.
- **Código heredado sin tests**: primero **caracterización** — capturar entradas y salidas reales
  (ficheros, informes, filas) y congelarlas como referencia — antes de tocar nada.
- **§6 (Rendimiento y operabilidad) se omite por artificial** en este dominio: no hay decisiones de
  operabilidad propias de Object Pascal que no sean del sistema operativo, del motor de datos o del
  despliegue, y ya tienen dueño. Lo único específico —el proceso de 32 bits, el instalador y el
  registro de componentes— se trata en §7.

## 5. Seguridad del stack

- **La superficie real son tres cosas**: el **SQL por concatenación** en formularios antiguos, los
  **componentes binarios de terceros sin fuente ni parches**, y el **canal** — cliente-servidor
  hablando con la base de datos por red interna sin TLS.
- **SQL siempre parametrizado** (`TFDQuery.Params`). Aquí la inyección no llega por web: llega por un
  campo de un formulario de escritorio conectado directamente a la base de datos.
- **Credenciales**: fuera del `.dfm`, del ejecutable y del `.ini` en claro junto al `.exe`. **Y la
  aplicación no se conecta con un usuario privilegiado compartido** — ese patrón heredado es el que
  convierte cualquier fallo en compromiso total.
- **Componentes de terceros abandonados**: no hay parches. Si uno maneja formato de fichero,
  criptografía o protocolo de red, **es una vulnerabilidad sin fecha de arreglo**: envolver,
  sustituir o aislar (`vulnerability-management-standards`). Nada de criptografía casera ni de
  componentes de cifrado de los 2000 (`cryptography-pki-standards`).
- **Validación en la frontera**, incluidos ficheros de configuración e importaciones: un
  `TStringList.LoadFromFile` sobre un fichero de un directorio compartido es entrada no confiable.

## 6. — omitida

Ver la nota al final de §4.

## 7. Migrar, envolver o congelar — y prohibiciones

**Los tres caminos, con el criterio para elegir:**

1. **Congelar**. La app funciona, no cambia y el negocio no le pide nada. Se blinda: build
   reproducible desde línea de comandos, máquina de build (con IDE, licencias y componentes de
   terceros instalados) **respaldada como imagen y con restauración probada**, dependencias
   inventariadas, y cambios solo por corrección o normativa. **Es la opción correcta más veces de
   las que se admite**, y no es rendirse: es dejar de pagar por evolucionar algo que no lo necesita.
2. **Envolver**. La app funciona pero hay que integrarla o darle interfaz nueva. Se expone la lógica
   como servicio (HTTP/REST desde el propio Delphi, o DLL/COM consumida desde .NET) y **todo lo
   nuevo se construye fuera** contra ese contrato — *strangler fig*, de
   `refactoring-tech-debt-standards`. **Requisito previo: la lógica tiene que estar fuera de los
   formularios** (§3); si no lo está, ese es el primer trabajo, y es el que rentabiliza cualquier
   camino posterior.
3. **Migrar**. Solo cuando hay razón de negocio real (el escritorio Windows ya no sirve, no hay a
   quién contratar, el coste de licencias no se sostiene) **y** presupuesto para reescribir la capa
   de presentación entera. **Por dominios, nunca de golpe.**

**Sobre los conversores automáticos Delphi→.NET**: producen código C# con la estructura de un
programa Object Pascal orientado a formularios, sin idiomática de destino y sin las bibliotecas
equivalentes. **No es una migración, es una traducción que hay que mantener.** Si se usa, es como
andamio con reescritura posterior planificada, y el resultado se rige por `dotnet-standards`.

**Señales duras de que hay que salir** (no opiniones, hechos comprobables): la app depende de un
componente binario de terceros sin fuente cuyo proveedor no existe; solo compila en una máquina
concreta que nadie sabe reinstalar; sigue en 32 bits contra un driver que ya no existe en 64;
no ha cruzado la barrera Unicode y hay que internacionalizar; o **no queda nadie en plantilla que
sepa mantenerla y el coste de contratar supera el de reescribir**.

**Prohibiciones:**

- ❌ **PROHIBIDO** desarrollo nuevo con **BDE**: deprecado por el fabricante, sin Unicode y sin
  futuro (§2). Migración a FireDAC.
- ❌ Guardar `.dfm`/`.lfm` en formato binario.
- ❌ Commitear `.dcu`, `.ppu`, `.exe`, `.bpl` o directorios `__history`/`__recovery`.
- ❌ Proyectos que solo compilan desde el IDE, o que dependen de rutas absolutas y de las opciones
  globales del IDE de un desarrollador concreto.
- ❌ SQL por concatenación de cadenas; credenciales en el `.dfm`, en el binario o en un `.ini` en
  claro; usuario de base de datos privilegiado compartido por la aplicación.
- ❌ Asumir que `Length(S)` son bytes, o persistir `string` a fichero/BLOB/socket sin codificación
  explícita (§3).
- ❌ Prometer multiplataforma cambiando VCL por FMX sin presupuestar la reescritura de la capa de
  presentación.
- ❌ Añadir un componente de terceros **sin fuente** o sin proveedor vivo a una aplicación que
  esperas mantener más de dos años.
- ❌ Meter lógica de negocio nueva en un `TForm`.
- ❌ Traducción automática a C# presentada como modernización.
- ❌ **Usar Community Edition en una empresa que factura más de 5.000 USD al año**, aunque sea para
  uso interno o como sustituto del trial: incumple la licencia (§2).
- ❌ Planificar sobre precios de licencia sacados de un blog: se piden por escrito (§8).
- ❌ Perder la máquina de build sin imagen respaldada y restauración probada.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Versión vigente de RAD Studio/Delphi** (a ago-2026: **13.1 "Florence"**, con build actualizada
   el 18-mar-2026) y qué aporta frente a la que usas.
2. **Precio real por desarrollador y condiciones de la licencia**: las cifras de §2 son **precios de
   partida de revendedor** (Professional ≈ 1.583 USD, Enterprise ≈ 3.959 USD, Architect ≈ 5.939 USD)
   y **el precio de lista de Embarcadero y el de volumen/upgrade/académico difieren**. **Hueco
   declarado**: pide oferta por escrito; no planifiques con estas cifras. Verifica también la
   naturaleza *Named User*, la restricción de país y la **obligación de renovación anual**.
3. **Elegibilidad de Community Edition** en el EULA vigente: umbral de ingresos (5.000 USD/año),
   límite de 5 desarrolladores y las exclusiones. **El EULA manda sobre cualquier resumen.**
4. **Soporte y fin de vida de las versiones de Delphi**: **hueco declarado — Embarcadero no publica
   un calendario de EOL comparable al de otros fabricantes**; el soporte va ligado a la suscripción
   de actualización vigente. Si necesitas una fecha para un plan, pídela por contrato.
5. **Free Pascal**: si sigue siendo **3.2.2 (mayo-2021)** la estable o si 3.2.4/3.4 ya salió — es el
   indicador de salud del lado libre. Y **Lazarus** (a ago-2026: **4.8**, 11-jun-2026, sobre FPC
   3.2.2 y FPC 3.2.4RC1 en macOS).
6. **Licencia de FPC/Lazarus leída en crudo** antes de distribuir cerrado: GPL para el compilador,
   **LGPL modificada con excepción de enlace estático** para la RTL y paquetes, más la obligación de
   publicar tus modificaciones de la RTL. Con `opensource-licensing-standards` y asesoría legal.
7. **Estado de cada componente de terceros del inventario**: última versión, compatibilidad con tu
   versión de Delphi, licencia, disponibilidad de fuente y si el proveedor sigue existiendo. **Es el
   trabajo de verificación que más cambia el plan y el que sistemáticamente no se hace.**
8. **CVEs** de las librerías nativas enlazadas, de los drivers de base de datos y de los componentes
   de red/criptografía de terceros.
9. **Estado de `legacy-modernization-standards`**: **la estrategia de migración es suya** —y la
   ejecución del corte, de `migration-projects-standards`— y esta skill solo aporta los hechos
   técnicos de la plataforma.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
