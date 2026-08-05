---
name: perl-standards
description: Use when working with Perl code - .pl/.pm/.t/.psgi files, "#!/usr/bin/perl" scripts, cpanfile, cpanfile.snapshot, Makefile.PL/Build.PL, .perlcriticrc, .perltidyrc, dist.ini, cpanm/carton/local::lib/perlbrew/plenv, Moose/Moo/Object::Pad or the native class feature, Try::Tiny and eval/$@ error handling, prove and Test2::V0 or Test::More suites, taint mode -T, DBI, Mojolicious, Dancer2, or maintaining and deciding whether to rewrite a legacy Perl codebase.
---

# Estándares Perl (referencia: agosto 2026)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**El caso real de Perl hoy es legacy vivo**: código de 10 o 20 años que factura, que nadie quiere
tocar y que no tiene tests. La mayor parte del trabajo aquí es **mantener, contener y decidir**, no
crear. Este documento está escrito desde ahí: primero no romper, después mejorar, y solo con criterio
explícito reescribir. Perl no es la respuesta para código nuevo salvo que el equipo ya lo mantenga
(§7).

Triggers: `.pl`, `.pm`, `.t`, `.psgi`, `cpanfile`, `cpanfile.snapshot`, `Makefile.PL`, `Build.PL`,
`.perlcriticrc`, `.perltidyrc`, `dist.ini`, `cpanm`, `carton`, `perlbrew`, `plenv`, `prove`,
`Moose`/`Moo`/`Object::Pad`, `DBI`, `Mojolicious`, `Dancer2`, `-T`.

**No aplica**: ver `bash-linux-scripting-standards` (**frontera recíproca y muy real**: Perl fue el
sucesor histórico del shell cuando un script se pasaba de listo, y esa regla sigue viva **solo en
sentido inverso** — hoy el destino de un script de shell que crece es `python-standards`, no Perl.
Un `.sh` que necesita estructuras de datos no se convierte en `.pl`), `python-standards` (**destino
natural de una reescritura**: cuando §7 dice "reescribir", dice ahí), `linux-administration-standards`
y `rhel-fedora-standards` (**el Perl del sistema, sus paquetes RPM/DEB y las herramientas del SO que
dependen de él**), `lua-standards` y `groovy-standards` (nada en común), `appsec-standards`
(metodología; aquí solo los sinks concretos de Perl), `sql-standards` (el SQL que pasa por `DBI`),
`vulnerability-management-standards`, `secrets-management-standards`, `observability-standards`.

## 2. Decisiones por defecto: intérprete y dependencias

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

**Versiones y soporte** (`perlpolicy`, verificado a ago-2026):

| Serie | Estado |
|---|---|
| **5.44.x** | Estable actual, publicada el **2026-07-15**. *Full support* |
| **5.42.x** | Estable anterior (desde 2025-07-03). *Full support* |
| 5.40.x | Desde 2024-06-09. **Security fixes only** |
| 5.45.x | Serie **de desarrollo** (X impar). **Nunca en producción** |

Política citada verbatim: *"To the best of our ability, we will provide 'critical' security patches /
releases for any major version of Perl whose 5.x.0 release was within the past three years."* Numeración:
X par = estable, X impar = desarrollo.

**"Perl 7" no existe y no va a existir como se anunció.** Historia necesaria porque sigue generando
confusión: se anunció en junio de 2020 (Sawyer X) como "Perl 5 con defaults modernos"; el rechazo por
proceso y por compatibilidad hacia atrás lo paró, derivó en una crisis de gobernanza que produjo el
`perlgov` y el Perl Steering Council, y la idea original murió. **La serie 5.x continúa sin
interrupción**; `perlpolicy` a ago-2026 no menciona Perl 7. Si alguien planifica sobre "cuando salga
Perl 7", el plan está mal.

**PROHIBIDO tocar el Perl del sistema.** En RHEL/Fedora y Debian/Ubuntu el intérprete y sus módulos
son parte del SO: los usan el gestor de paquetes, herramientas de arranque, `debconf`, scripts de
mantenimiento. Instalar módulos con `cpan`/`cpanm` como root sobre `/usr/lib/perl5`, o sustituir el
binario, **rompe el sistema operativo** y deja una máquina no reproducible y no parcheable. Reglas:
- Módulos que necesita el SO → **paquete de la distro** (`perl-*`), nunca CPAN sobre el árbol del sistema.
- Aplicaciones propias → intérprete propio con **`perlbrew`** o **`plenv`**, o al menos un árbol de
  módulos aislado con **`local::lib`**. Cada aplicación con su árbol; nunca compartido.
- En contenedor: imagen con su Perl y su `cpanfile.snapshot`; nada de `cpanm` en runtime.

**Dependencias**:

| Pieza | Elección | Verificado (MetaCPAN, ago-2026) |
|---|---|---|
| Instalador | **`cpanm`** (App-cpanminus) | 1.7049 (2026-03-17) |
| Declaración | **`cpanfile`** con rangos acotados | — |
| Lock + reproducibilidad | **`Carton`** (`cpanfile.snapshot`, `carton install --deployment`) | v1.0.35, **2022-05-07** |
| Aislamiento | `local::lib` | 2.000029, **2022-04-20** |
| Formato | **perltidy** | 20260705, licencia **GPL-2.0** (no "same as Perl") |
| Lint | **Perl::Critic** | **1.156** (2024-10-23) |
| Tests | **Test2::V0** + `prove` / `yath` | ver §8 (discrepancia declarada) |
| Cobertura | `Devel::Cover` | 1.52 (2026-03-07) |
| Auditoría | **`CPAN::Audit`** / `cpan-audit` | 20260622.001 (2026-06-22) |

`Carton` y `local::lib` llevan años sin release: **funcionan y son el estándar de facto, pero no son
software mantenido activamente** — dato a declarar, no a esconder. `Carmel` es la alternativa del
mismo autor y está aún más parada. Criterio: `cpanfile` + `cpanfile.snapshot` **committeados**, e
instalación reproducible desde el snapshot; si el equipo puede permitírselo, congelar el árbol de
módulos en la imagen del contenedor es más robusto que confiar en resolver desde CPAN en cada build.

## 3. El lenguaje: línea cero y lo que rompe

**Línea cero, no negociable, en todo fichero `.pl`, `.pm` y `.t`:**

```perl
use strict;
use warnings;
```

Sin `strict` no hay refactor posible: un typo crea un símbolo global nuevo en silencio. Es la
diferencia entre "Perl mantenible" y "Perl de leyenda". Alternativa aceptable: `use Modern::Perl` o
`use v5.36;` o superior — **`use VERSION` con 5.36+ activa `strict`, `warnings` y `signatures`
automáticamente** y es la forma preferida en código nuevo. Aviso de migración: Perl 5.40 avisó de que
**declaraciones `use VERSION` repetidas dejan de permitirse en 5.44**.

- **Sigilos y contexto son la fuente de bug número uno.** `$x`, `@x` y `%x` son variables distintas, y
  el sigilo indica **lo que obtienes**, no lo que la variable es (`$array[0]`, `$hash{k}`). Sobre todo:
  **contexto escalar vs lista**. `my ($x) = f();` toma el primer elemento de la lista; `my $x = f();`
  pone la función en contexto escalar (para un array, su longitud). Una lista vacía da `undef` en
  escalar y **desaparece** al interpolarse en otra lista. Regla: toda función que devuelva colecciones
  **devuelve una referencia** (`\@result`), salvo contrato de lista deliberado y documentado. Es el
  único modo de que el contexto deje de morderte.
- **Referencias**: estructuras anidadas solo con referencias (`$h->{a}[0]{b}`). Cuidado con la
  **autovivificación**: leer `$h->{a}{b}` crea `$h->{a}`; usa `exists` si la creación importa.
- **`my` / `our` / `local`**: `my` es léxico y cubre el 99%. `our` es un alias al paquete: solo
  constantes y `$VERSION`. **`local` no es local**: es un valor dinámico temporal sobre una global
  (`local $/;`); necesario para variables especiales, veneno para cualquier otra cosa.
- **Sistemas de objetos**, criterio explícito:
  - **`class` nativo en el core**: existe desde **5.38** (proyecto "Corinna"), y **sigue siendo
    experimental a 5.44** (avisos de categoría `experimental::class`; el perldelta de 5.44 añade una
    entrada en `perlexperiment` para "New object system and `class` syntax"). Traducción operativa:
    **es el futuro y ya se puede usar en un proyecto interno que controle su intérprete, pero no en
    una distribución de CPAN ni en un sistema que no pueda absorber un cambio de sintaxis.**
  - **`Object::Pad`** (0.825, 2026-03) es el laboratorio del que salió `class`, activamente mantenido:
    el puente si quieres esa sintaxis hoy y aceptas seguir sus cambios.
  - **`Moo`** (2.005005, **2023-01**): ligero, sin XS, arranque rápido; estable pero sin release en años.
    **`Moose`** (2.4000, 2025-07): completo (roles, *type constraints*, MOP) con coste real de arranque
    y memoria — solo si ya lo usas o necesitas el MOP de verdad.
  - **Criterio**: base que ya usa Moose → Moose. Base nueva y controlada → `class` nativo asumiendo su
    estado experimental, o `Moo` si quieres estabilidad hoy. **Nunca `bless` a mano** en código nuevo,
    ni dos sistemas de objetos en el mismo proyecto.
- **Errores**: `eval { }; if ($@) { }` es correcto **de forma sutil y frágil**. Trampas reales: `$@`
  puede ser pisado por el destructor de un objeto que se libera al salir del `eval`; `$@` falso pero
  con error ocurrido si la excepción fue el string `"0"`; y `eval` sin bloque (`eval EXPR`) es otra
  cosa completamente distinta. **Usa `Try::Tiny`** (o `feature 'try'` si tu intérprete lo tiene y
  aceptas su estado) y comprueba siempre el **valor de retorno** de `eval`, no solo `$@`. Objetos de
  excepción (clase propia o `Throwable`) por encima de strings: un error que solo es texto no se puede
  clasificar ni reintentar.
- **Expresiones regulares: el punto fuerte de Perl y su mayor riesgo.**
  - Precompila con `qr//` lo que se use en bucle; usa `/x` en cualquier patrón de más de una línea
    (con comentarios) — un regex denso sin `/x` es código no revisable.
  - Nombres, no números: `(?<name>...)` y `$+{name}`. `$1`, `$2`… se rompen al reordenar.
  - **ReDoS es real**: el motor de Perl hace retroceso (*backtracking*) y un patrón con cuantificadores
    anidados (`(a+)+`) sobre entrada de usuario se lleva la CPU. Sobre entrada no confiable: acota la
    longitud del sujeto, evita cuantificadores anidados y alternancias solapadas, prefiere clases de
    caracteres negadas a `.*`, y **nunca aceptes un patrón proporcionado por el usuario**.
  - `/e` (evalúa el reemplazo como código) sobre datos externos es `eval STRING` disfrazado: vetado.

## 4. Calidad: formato, lint, tests

- **Formato**: `perltidy` con `.perltidyrc` committeado; `perltidy -b` en local y **`perltidy` en modo
  comprobación como gate**. Sin discusión de estilo.
- **Lint**: `Perl::Critic` con `.perlcriticrc` en el repo. Criterio de severidad:
  - Código nuevo o módulo ya saneado: **severity 3** (`--severity 3`, "harsh") como gate.
  - Legacy que entra en el pipeline por primera vez: **severity 5** (`gentle`) como gate y bajar un
    nivel por trimestre. Poner severity 1 sobre un legacy de 100k líneas no produce calidad, produce
    un `## no critic` en cada fichero y el abandono del linter.
  - Políticas obligatorias sea cual sea la severidad: `RequireUseStrict`, `RequireUseWarnings`,
    `ProhibitTwoArgOpen`, `ProhibitStringyEval`, `ProhibitBacktickOperators`.
  - `## no critic (PolicyName)` **siempre con la política nombrada y un motivo**; nunca desnudo.
  - Aviso: Perl::Critic no publica release desde 2024-10 (1.156) — sigue siendo la herramienta, pero
    su cadencia es lenta.
- **Tests**:
  - `Test2::V0` para suites nuevas; `Test::More` es aceptable y omnipresente en legacy, **no lo
    migres por gusto**. Ejecutor: `prove -lr t/` (o `yath`), en paralelo (`-j`) solo si los tests son
    de verdad independientes.
  - Cubrir camino feliz, **bordes y errores**: entradas vacías, `undef`, codificación (Perl y UTF-8 es
    un campo de minas: decide dónde decodificas y prueba con no-ASCII), errores de DB, timeouts.
  - `Devel::Cover` para medir, **no** como umbral religioso. En legacy sin tests, la cobertura útil se
    construye por el borde: primero un test de caracterización que fije el comportamiento observable
    actual (aunque sea absurdo), luego se toca.
  - Todo bugfix deja test de regresión. Test inestable: se arregla o se borra.
- **Gates de CI** (bloquean merge, de barato a caro):
  1. `perl -c` sobre todos los ficheros modificados (compila).
  2. `perltidy` en modo comprobación.
  3. `Perl::Critic` a la severidad acordada.
  4. `prove` completo.
  5. `cpan-audit` sobre el `cpanfile.snapshot`.
- La suite corre contra **la misma versión del intérprete que producción**, instalada con perlbrew/plenv
  o en el contenedor. "En mi máquina con el Perl del sistema pasa" no es una señal.

## 5. Seguridad

- **Taint mode (`-T`)**: activa el marcado de datos externos (argumentos, entorno, ficheros, red) y
  hace fatal su uso en operaciones peligrosas; se activa **automáticamente** en scripts setuid. Sigue
  documentado en `perlsec` como característica viva y **sigue siendo la única red de seguridad
  sistémica de Perl** para código que procesa entrada externa con privilegios. Criterio: **actívalo en
  cualquier script de red, CGI o con privilegios**; en legacy grande, actívalo en los puntos de entrada
  nuevos. Consciencia obligatoria de dos límites: (a) el *untainting* se hace con una captura de regex,
  o sea que **la seguridad la pone tu patrón**, no Perl — un `=~ /(.*)/s` es untaint sin validación y no
  vale nada; (b) hay un plan de larga duración para hacer el soporte de taint una opción de compilación
  y quizá retirarlo (ver hueco en §8): **no diseñes una arquitectura cuya única defensa sea taint**.
- **Ejecución de comandos — la forma de lista frente a la de cadena.** `system("cmd $x")`,
  `exec("cmd $x")` y los backticks `` `cmd $x` `` pasan la cadena **por el shell**: inyección directa.
  Usa **siempre la forma de lista**: `system('cmd', $x)` / `open(my $fh, '-|', 'cmd', $x)`, que hace
  `exec` sin shell. Si necesitas capturar salida con argumentos variables, `IPC::Run3`/`IPC::Run` con
  lista de argumentos. Comprueba **siempre** el estado de salida (`$?`): un `system` sin comprobar es
  un fallo silencioso.
- **`open` de dos argumentos: PROHIBIDO.** `open(FH, $file)` interpreta metacaracteres en `$file`: un
  nombre que empieza por `>` escribe, y uno que acaba en `|` **ejecuta un comando**. Siempre tres
  argumentos con modo explícito y *lexical filehandle*: `open(my $fh, '<', $file) or die ...`. Y
  siempre comprobar el retorno de `open`, `close`, `print` y `unlink`.
- **`eval STRING`: PROHIBIDO** con cualquier dato que provenga de fuera. `eval { BLOCK }` (manejo de
  excepciones) es otra construcción y sí es legítima. Igual de vetados: `/e` en sustituciones sobre
  datos externos, y `sprintf`/`printf` con formato que venga del usuario.
- **Deserialización**: **`Storable` es inseguro sobre entrada no confiable** — `thaw`/`retrieve` sobre
  datos que no has generado tú es ejecución de código y corrupción de memoria; su propia documentación
  lo advierte. Vetado como formato de intercambio con terceros; aceptable solo para datos que tu propio
  proceso escribió en un almacén de confianza. Alternativas: **JSON** (`JSON::PP`/`Cpanel::JSON::XS`,
  sin *blessed objects*, con `max_depth`/`max_size`), y **YAML solo con un cargador seguro**
  (`YAML::PP` en modo seguro / `YAML::XS` con `$YAML::XS::LoadBlessed = 0`) — un cargador YAML que
  instancia objetos es un `eval` remoto.
- **SQL**: solo *placeholders* de DBI (`$dbh->prepare("... WHERE id = ?")` + `execute($id)`).
  Interpolar una variable en SQL es veto absoluto; los identificadores que no admiten placeholder
  (nombres de tabla/columna) se validan contra una **allowlist**, nunca se citan a mano.
- **Rutas y ficheros**: canonicaliza (`Cwd::realpath`) y comprueba que la ruta sigue dentro del
  directorio permitido antes de abrir; temporales con `File::Temp`, nunca nombres predecibles.
- **Secretos** fuera del código, del `cpanfile` y de los logs; `DBI` con credenciales de entorno; el
  `Dumper` de una estructura de conexión lleva la contraseña.
- **SCA**: `cpan-audit` sobre el `cpanfile.snapshot` como gate de CI. CPAN tiene módulos abandonados y
  sin sucesor: toda dependencia sin release en >5 años que toque red, cripto o parseo se revisa.
- **Criptografía**: nada casero. Password hashing con `Crypt::Argon2` o `Crypt::Bcrypt`; **jamás**
  `crypt()`, MD5 ni SHA-1 para contraseñas. TLS con `IO::Socket::SSL` **con verificación de certificado
  activada** (`SSL_verify_mode => SSL_VERIFY_PEER`) — desactivarla es un veto.

## 6. Rendimiento y operabilidad

- Antes de optimizar, perfila (`Devel::NYTProf`). En Perl, el coste suele estar en I/O, en regex mal
  escritas, en `DBI` haciendo N+1 y en cargar medio CPAN al arrancar (`Moose` frente a `Moo` importa en
  procesos de vida corta como CGI o cron).
- Procesos de larga vida (PSGI/Plack, demonios): **fugas por referencias circulares** — el contador de
  referencias no las libera; rompe el ciclo con `Scalar::Util::weaken`. Vigila RSS: crecimiento
  monótono = ciclo o caché sin límite.
- Despliegue web: **PSGI/Plack** con Starman/uWSGI tras un proxy. CGI se mantiene si ya existe; no se elige.
- Timeouts explícitos en todo cliente HTTP (`LWP::UserAgent`, `HTTP::Tiny`) y de DB; reintentos con
  backoff solo en operaciones idempotentes.
- Logs estructurados (`Log::Any`/`Log::Log4perl` con salida JSON) e id de correlación; `warn`/`die`
  llegan al log con contexto. `print STDERR` disperso no es observabilidad. En proceso supervisado,
  autoflush activado (o pierdes los últimos logs al morir) y `SIGTERM` manejado para cerrar limpio.
- Codificación: decide la frontera (`binmode`, `:encoding(UTF-8)`, `use open`) una sola vez y
  documéntala; el *mojibake* en Perl es casi siempre una frontera no declarada.

## 7. Sostenibilidad: mantener, contener, y cuándo reescribir

- **Cadencia**: sigue la serie estable de Perl con un salto de versión mayor al año como máximo, y
  nunca dejes el intérprete fuera del soporte de seguridad (ventana de 3 años). Actualizar el Perl de
  una aplicación legacy es un proyecto con su plan de pruebas, no un `perlbrew install`.
- Dependencias: revisión trimestral con `cpan-audit`; una dependencia abandonada que toca la
  superficie de ataque se sustituye o se vendoriza y se asume su mantenimiento por escrito.
- **Documenta el sistema mientras lo tocas**: en legacy sin tests, un README con "qué hace, quién lo
  llama, qué rompe si muere" vale más que un refactor.

**Cuándo se reescribe y cuándo no** (criterio honesto):
- **No se reescribe** un Perl que funciona, está en producción y **no tiene tests**. Reescribir sin
  tests es cambiar un **riesgo conocido y acotado** (código feo que lleva 15 años funcionando,
  con todos sus casos límite ya descubiertos por la realidad) por un **riesgo desconocido** (código
  bonito que aún no ha encontrado ninguno). El coste no es el que se estima: lo caro es la lista
  invisible de comportamientos que nadie documentó y que alguien depende de que sigan pasando.
- **Se contiene primero**: fija el intérprete, mete el repo en CI, añade `strict`/`warnings` fichero a
  fichero, escribe tests de caracterización sobre las entradas y salidas reales, aísla el módulo por
  una interfaz estable. Ese trabajo tiene valor aunque nunca reescribas — y **es un prerequisito** si
  reescribes, porque los tests de caracterización son el criterio de aceptación de la reescritura.
- **Se reescribe** cuando concurre al menos una condición dura, no una estética: nadie en el equipo
  puede mantenerlo y no se puede contratar; depende de una versión de Perl o de módulos ya sin
  soporte de seguridad y sin ruta de actualización; el cambio de negocio exige tocar el núcleo cada
  sprint; o el coste de incidentes ya supera el de la reescritura, **medido**.
- **Cómo se reescribe**: por trozos, con la vieja y la nueva conviviendo tras una interfaz (estrangulamiento),
  con los tests de caracterización como oráculo, y con destino declarado — normalmente Python (ver
  `python-standards`). *Big bang* nunca.

**Lista de prohibiciones (veto):**
- ❌ Cualquier fichero sin `use strict; use warnings;` (o `use v5.36;`+). Ni scripts de una línea.
- ❌ **PROHIBIDO** instalar módulos CPAN sobre el Perl del sistema o sustituir su binario en RHEL/Debian.
- ❌ **PROHIBIDO** `open` de dos argumentos.
- ❌ **PROHIBIDO** `eval STRING` sobre datos externos; `/e` con input; `sprintf` con formato de usuario.
- ❌ **PROHIBIDO** `system`/`exec`/backticks en forma de cadena con datos variables. Forma de lista siempre.
- ❌ **PROHIBIDO** `Storable::thaw`/`retrieve` sobre entrada no confiable; YAML con cargador que instancie objetos.
- ❌ SQL por interpolación; `IO::Socket::SSL` sin verificación de certificado; `crypt`/MD5/SHA-1 para contraseñas.
- ❌ Patrones regex proporcionados por el usuario; cuantificadores anidados sobre entrada no acotada.
- ❌ `## no critic` sin política nombrada y motivo; `$@` como única señal de fallo de un `eval`.
- ❌ `bless` a mano o dos sistemas de objetos en el mismo proyecto.
- ❌ Devolver listas desde funciones que devuelven colecciones (devuelve referencias) sin contrato documentado.
- ❌ Desplegar sin `cpanfile.snapshot` o instalando desde CPAN en el arranque del servicio.
- ❌ Ejecutar la suite contra una versión de Perl distinta de la de producción.
- ❌ Reescribir un legacy sin tests de caracterización previos.
- ❌ **Elegir Perl para código nuevo.** Salvo un caso: que el equipo ya mantenga Perl, ya tenga el
  intérprete, la experiencia y las librerías internas, y el trabajo nuevo sea una extensión natural de
  ese sistema. Fuera de ahí, la contratación, el ecosistema y la cadencia de las herramientas juegan en
  contra: el destino por defecto es Python.

## 8. Verificación web obligatoria

Antes de fijar versiones o APIs, **verifica online** (WebSearch/WebFetch; MetaCPAN
`https://fastapi.metacpan.org/v1/release/<Dist>` para versiones y licencias de CPAN — **para módulos
Perl la fuente de verdad es CPAN, no las releases de GitHub**, que a menudo están desactualizadas o no
existen):
1. `perldoc.perl.org/perlpolicy`: series soportadas hoy (a ago-2026: **5.44 y 5.42 full support, 5.40
   solo seguridad**) y si 5.46 ya está fuera. Nunca despliegues una serie X impar.
2. `perldelta` de la versión destino antes de cualquier salto de serie: 5.44 hizo fatales cosas que
   antes avisaban (`goto` a un bloque, "Attempt to call undefined ... method") y retiró las
   declaraciones `use VERSION` repetidas.
3. **Estado de `use feature 'class'`**: a ago-2026 **sigue experimental** (categoría de aviso
   `experimental::class`); comprueba el issue de seguimiento del core y el `perlexperiment` de tu
   versión antes de apostar por ella en algo publicable.
4. Versiones y licencias en CPAN de: Perl::Critic (1.156, sin release desde 2024-10), perltidy
   (**GPL-2.0**), Carton (**sin release desde 2022**), local::lib (**2022**), Moo (**2023-01**),
   Moose (2.4000), Object::Pad (0.825), Try::Tiny (MIT), Devel::Cover, CPAN::Audit.
5. Vulnerabilidades: `cpan-audit` actualizado + osv.dev/GitHub Advisories para los módulos con XS.
6. Si el proyecto es web: versión y estado de Mojolicious (9.48 a ago-2026, Artistic-2.0), Dancer2, DBI y su DBD.

**Huecos no verificados a ago-2026** (no rellenar de memoria; comprobar antes de decidir):
- **Estado real del *taint mode*.** Está documentado como vivo en `perlsec` y hay un plan público de
  larga duración para hacerlo opcional en tiempo de compilación (`-Utaint_support`, introducido hacia
  5.36) y eventualmente retirarlo. **No queda verificado si el default ha cambiado en 5.42/5.44 ni si
  hay fecha de retirada**: consúltalo en el `perldelta` de tu versión y en el issue tracker del core
  antes de basar un diseño en `-T`.

**Discrepancias declaradas**:
- El feed de releases de GitHub `Perl-Critic/Perl-Critic` muestra **v1.154 (2024-10-21)** mientras
  MetaCPAN da **1.156 (2024-10-23)** para la misma distribución. Vale MetaCPAN (CPAN es el canal de
  publicación); el feed de GitHub está incompleto.
- La API de MetaCPAN resuelve el módulo **`Test2::V0` a la distribución `Test-Simple` 1.302222**
  (2026-06-15), no a `Test2-Suite`, y la consulta directa de la release `Test2-Suite` no devolvió
  datos. **No queda verificado** en qué distribución vive hoy `Test2::V0`: compruébalo en MetaCPAN
  antes de escribirlo en un `cpanfile`.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
