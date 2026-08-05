---
name: groovy-standards
description: Use when writing or reviewing Groovy code - .groovy and .gvy files, Jenkinsfile (declarative or scripted), Jenkins Shared Libraries with vars/ and src/, @NonCPS annotations and Script Security sandbox approvals, build.gradle and settings.gradle in the Groovy DSL versus build.gradle.kts, gradle init defaults, Spock specifications in src/test/groovy, @CompileStatic/@TypeChecked/@DelegatesTo, AST transforms, GString interpolation, or codenarc.
---

# Estándares Groovy (referencia: agosto 2026)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Groovy hoy es sobre todo un lenguaje de configuración de otras herramientas, no de aplicación.** Casi
todo el Groovy que se escribe en 2026 es un `Jenkinsfile`, un `build.gradle` o una especificación de
Spock. Escribir un backend en Groovy es una decisión que hay que justificar frente a Java o Kotlin, y
casi nunca sobrevive a la justificación (§7). Esta skill está estructurada por caso de uso.

Triggers: `.groovy`, `.gvy`, `Jenkinsfile`, `vars/*.groovy`, `src/**/*.groovy` de una Shared Library,
`build.gradle`, `settings.gradle`, `gradle.properties`, `@NonCPS`, `@CompileStatic`, `@DelegatesTo`,
`codenarc`, specs de Spock en `src/test/groovy`.

**No aplica**:
- **`jvm-spring-standards` (frontera crítica)**: **la JVM, el JDK, el GC, el tuning de memoria, Spring
  y el modelo de aplicación son suyos**. El **lenguaje Groovy** y los **DSL de Gradle y Jenkins** son
  de aquí. Si la pregunta es "qué JDK y con qué flags", es suya; si es "cómo escribo este
  `build.gradle`", es de aquí.
- **`cicd-standards` (frontera crítica, en las dos direcciones)**: **la estrategia de pipeline, los
  gates, la firma de artefactos, el SBOM, OIDC, la seguridad y el aislamiento del runner son suyos**.
  **Cómo se escribe el `Jenkinsfile` como código Groovy** — declarativo vs *scripted*, CPS, `@NonCPS`,
  Shared Libraries, sandbox de Script Security — **es de aquí**. Un problema de "el pipeline no
  aprueba el gate" es suyo; uno de "el pipeline no serializa y falla en el paso 3" es de aquí.
- `scala-standards` y `clojure-standards` (los otros lenguajes de la JVM), `iac-standards`,
  `container-runtime-security-standards` (el aislamiento del contenedor donde corre el agente),
  `lua-standards` y `perl-standards` (nada en común), `appsec-standards`,
  `vulnerability-management-standards`, `secrets-management-standards`, `sql-standards`,
  `observability-standards`.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

**Apache Groovy está vivo y mantenido activamente** — dato relevante porque a menudo se asume lo
contrario. Es proyecto de la **Apache Software Foundation** (Apache-2.0) y a ago-2026 mantiene **tres
líneas en paralelo**, con releases de la misma semana:

| Línea | Estado verificado (ago-2026) |
|---|---|
| **Groovy 5.0.x** | **Estable actual**. 5.0.8 (2026-07-29) |
| Groovy 4.0.x | Mantenida. 4.0.33 (2026-07-29) |
| Groovy 6.0.0 | **BETA-1 (2026-08-01)**. No usar en producción |

**Requisitos de JDK de Groovy 5** (release notes oficiales): *JDK17+ para **construir** Groovy* y
**JDK 11 es la versión mínima de JRE soportada**; probado sobre JDK 11–25. En la práctica: la versión
de Groovy no la eliges tú si trabajas dentro de Gradle o de Jenkins — **la impone la herramienta**,
que embebe su propio Groovy. Comprueba cuál antes de usar una característica del lenguaje.

| Pieza | Elección | Verificado | Licencia (LICENSE en crudo) |
|---|---|---|---|
| Lenguaje | Apache Groovy 5.0.x | 5.0.8 | **Apache-2.0** |
| Build | Gradle 9.x | 9.6.1 (2026-06-26); 9.7 en RC | **Apache-2.0** |
| CI | Jenkins LTS | línea 2.568.x; *weekly* 2.575 | **MIT** |
| Tests | **Spock** | **2.4** (2025-12-11), estable tras una larga serie de *milestones* | **Apache-2.0** |
| Lint | CodeNarc | ver §8 (no verificado) | ver §8 |

### Gradle: `build.gradle` frente a `build.gradle.kts`

Criterio real hoy, sin ambigüedad:

- **Proyecto nuevo → Kotlin DSL (`.kts`).** Es lo que Gradle genera por defecto. Verbatim de las notas
  de la versión 8.2: *"Kotlin DSL is now the default option when generating a new project with the
  init task."* Motivo de ingeniería, no de moda: tipado estático, autocompletado y navegación reales
  en el IDE, y errores en tiempo de compilación del propio build. El Groovy DSL es dinámico y su
  "API" son metaprogramación y delegación: el IDE adivina.
- **El Groovy DSL NO está deprecado** y sigue soportado. No hay presión de fin de vida.
- **`build.gradle` existente → no lo migres por gusto.** La migración de un build grande es un
  proyecto con riesgo real (plugins, `ext`, closures con delegación implícita, lógica ad-hoc en
  `.gradle` sueltos) y su beneficio es *developer experience*, no funcionalidad. Criterio: migra si ya
  vas a tocar el build a fondo, si el build es lo bastante complejo como para que la falta de tipos
  cueste tiempo real, o si vas a moverlo a `buildSrc`/*convention plugins* (donde el Kotlin DSL gana
  mucho más). Si no, se queda y se mantiene bien escrito.
- Sea cual sea el DSL: **lógica del build fuera del script**. `buildSrc/` o un *included build* con
  *convention plugins*; `build.gradle(.kts)` debe ser declarativo. Version catalog
  (`gradle/libs.versions.toml`) como fuente única de versiones. **Gradle Wrapper committeado, con
  `gradle-wrapper.properties` apuntando a una distribución con `distributionSha256Sum`** — un wrapper
  sin checksum es ejecución de código descargado sin verificar.

## 3. Jenkins: el `Jenkinsfile` no es Groovy normal

Esta es la sección que más incidentes evita. **Un `Jenkinsfile` parece Groovy y no se comporta como
Groovy.**

- **Transformación CPS**: Jenkins compila el pipeline con el parser de Groovy pero **no ejecuta su
  bytecode**: un `CompilationCustomizer` reescribe casi todas las operaciones a estilo
  *continuation-passing*, y un intérprete propio las ejecuta. Motivo: **el estado completo del
  programa se serializa a disco** (`program.dat` en el directorio del build) en cada operación
  asíncrona, para que el build sobreviva a un reinicio de Jenkins y continúe donde estaba.
- **Consecuencias que hay que interiorizar**:
  - Toda variable viva en el punto de una llamada a un *step* **debe ser serializable**. Un `Matcher`
    de regex, un `InputStream`, un `File` → `NotSerializableException` en un punto aparentemente
    aleatorio. Regla: los objetos no serializables viven y mueren dentro de un `@NonCPS`, o se
    descartan (`m = null`) antes del siguiente step.
  - **Es lento**, y la documentación oficial es explícita: no está pensado para ser eficiente y debe
    limitarse a *glue code* de alto nivel, con la lógica real en programas externos vía `sh`/`bat`.
    **Un bucle sobre 10.000 elementos dentro de un pipeline es un error de diseño.** Además hay
    construcciones de Groovy que el intérprete no cubre bien (closures sobre colecciones, herencia).
- **`@NonCPS`**: marca un método para que se compile y ejecute con semántica Groovy nativa (salvo las
  comprobaciones del sandbox). Reglas duras:
  - **No puedes llamar a métodos CPS ni a *steps* del pipeline desde un `@NonCPS`.** Su único uso
    correcto es cálculo puro: entra dato serializable, sale resumen serializable.
  - No aceptes ni devuelvas ni almacenes valores no serializables desde un `@NonCPS`.
  - Los `@Override` de métodos de clases binarias (`toString()`, `equals()`) **deben** ir `@NonCPS`,
    porque el código binario los llamará desde contexto no-CPS.
  - Jenkins detecta el error más común (llamar a código CPS desde contexto no-CPS) y lo avisa en el
    log; ese aviso **es un fallo, no ruido**.
- **Declarativo por defecto.** `pipeline { agent … stages { … } }` es la forma correcta para el 95% de
  los casos: estructura fija, validable, con `post`, `options`, `environment` y `matrix` nativos, y
  mucho menos Groovy suelto que serializar. **Scripted** (`node { … }`) solo para flujos de control
  que el declarativo no expresa, y aun así se prefiere un bloque `script { }` acotado dentro del
  declarativo antes que un pipeline entero *scripted*.
- **Shared Libraries** para todo lo que se repita entre repos: `vars/` (steps globales, un fichero por
  step, con `call()`) y `src/` (clases Groovy normales, aquí sí se puede tipar y testear). La librería
  es **un repo versionado con tags**, y los pipelines la referencian **por tag o por commit**, nunca
  por rama móvil: `@Library('mylib@v3.2.0')`. Una librería referenciada por `master` es un cambio
  global sin revisión que se aplica a todos los pipelines a la vez.
  - Se testea: las clases de `src/` con Spock, en su propio build. Un pipeline cuyo único entorno de
    pruebas es producción no es código, es una apuesta.
- **`Jenkinsfile` corto por diseño**: orquesta, no implementa. Cualquier lógica de más de unas líneas
  baja a un script en el repo (`bash`/`python`) o a la Shared Library. Beneficio doble: se puede
  ejecutar y testear en local sin Jenkins, y no pasa por CPS.

## 4. El lenguaje: qué usar y qué evitar

- **`@CompileStatic` siempre que se pueda; `@TypeChecked` como mínimo.** Groovy dinámico paga cada
  llamada por *dispatch* en runtime y no detecta un typo de método hasta que la línea se ejecuta — en
  un pipeline, eso es "falla en el minuto 40 del build". Aplícalo a nivel de clase en toda la lógica
  de una Shared Library (`src/`) y en cualquier código Groovy de aplicación.
  - Límite real y por qué no se aplica en todas partes: **los DSL de Gradle y Jenkins dependen de la
    metaprogramación dinámica** (delegación, `methodMissing`, `propertyMissing`), así que el script
    del pipeline y el `build.gradle` **no pueden ser `@CompileStatic`**. Esa es exactamente la razón
    por la que la lógica debe salir del script y bajar a clases que sí lo sean.
- **Closures y delegación** son el mecanismo de los DSL: `delegate`, `owner`, `resolveStrategy`.
  Cuando escribas un DSL propio, anota **`@DelegatesTo`** en el parámetro closure — sin eso, ni el IDE
  ni `@CompileStatic` pueden resolver nada dentro del bloque, y tu DSL es intocable.
- **AST transforms**: `@Immutable`, `@Canonical`, `@Builder`, `@Memoized`, `@Slf4j` son útiles y
  legítimos. Escribir **AST transforms propios** es un veto salvo caso extraordinario: son código que
  corre en el compilador, casi imposible de depurar y que rompe con cada versión de Groovy.
- **GString y su trampa de interpolación** — dos incidentes clásicos, ambos vetados:
  - **En SQL**: `sql.execute("SELECT * FROM t WHERE id = $id")` con `groovy.sql.Sql` **sí**
    parametriza el GString (es un caso especial deliberado), pero
    `sql.execute("SELECT * FROM t WHERE id = ${id}".toString())` **no**: al convertir a `String`
    pierdes la parametrización y tienes inyección. Cualquier concatenación o `.toString()` sobre un
    GString destinado a SQL es un veto. Usa placeholders explícitos y lista de parámetros.
  - **En logs**: `log.debug("payload: $obj")` **evalúa la interpolación siempre**, incluso si el nivel
    DEBUG está apagado. Coste en caliente y, peor, **filtración**: en un pipeline eso puede volcar un
    objeto de credenciales al log del build. Usa la forma con placeholders del logger, y nunca
    interpoles objetos de credenciales ni mapas de entorno.
- `?.` (*safe navigation*) y `?:` (Elvis) son idiomáticos y correctos; `?.` encadenado en profundidad
  no es robustez, es esconder un `null` que no debería existir — falla pronto en el borde.
- `def` frente a tipos: con `@CompileStatic`, tipos explícitos en firmas públicas siempre. `def` solo
  para locales obvias.
- Groovy verdad: `0`, `""`, `[]`, `[:]` y `null` son falsos. **No es Java ni Lua**; una comprobación
  `if (x)` sobre un número o una colección no significa "no es null".

## 5. Seguridad: Groovy es ejecución de código arbitraria en la JVM

**Punto de partida sin matices: un `Jenkinsfile` o un `build.gradle` de un repositorio no confiable
ejecuta lo que quiera dentro de tu runner, con la identidad de tu runner.** No es un fichero de
configuración; es un programa. Todo lo que sigue deriva de ahí.

- **Gradle**: `./gradlew build` sobre un repo desconocido ejecuta su código de build antes de compilar
  nada. Un PR que modifica `build.gradle`, `settings.gradle` o `buildSrc/` es un PR que modifica lo
  que ejecuta tu CI. Consecuencia: **los workflows que corren builds de forks nunca reciben secretos
  ni tokens con permisos de escritura**; los plugins de Gradle se fijan por versión exacta desde el
  version catalog y se resuelven desde un repositorio propio o un espejo, nunca desde un repositorio
  arbitrario declarado en el propio script; el wrapper lleva `distributionSha256Sum`.
- **Jenkins Script Security**: el sandbox de Groovy es lo que impide que un pipeline tome control del
  controlador. Su modelo es una allowlist de métodos, con **aprobación manual** (*In-process Script
  Approval*) para lo que queda fuera. Dos reglas:
  - **PROHIBIDO desactivar el sandbox.** El runtime de Pipeline tiene acceso a los internos de
    Jenkins: recuperar credenciales cifradas, disparar despliegues, borrar artefactos. Un pipeline sin
    sandbox es control total del controlador para quien pueda escribir en el repo.
  - **Aprobar un método es una decisión de seguridad, no un desbloqueo administrativo.** Aprobar cosas
    como `getClass`, `getDeclaredMethods`, cualquier cosa de reflexión o `System.*` equivale a
    desactivar el sandbox por la puerta de atrás. Si un pipeline necesita algo que el sandbox no
    permite, **la solución correcta es bajarlo a una Shared Library aprobada o a un plugin**, no
    aprobar el método.
  - Ha habido y habrá **CVEs de bypass del sandbox** (casts implícitos del runtime de Groovy,
    expresiones de parámetros por defecto en métodos CPS, rebuild de un script no aprobado). Corolario:
    el sandbox es **contención, no frontera**. La frontera es quién puede escribir en el repo y qué
    puede alcanzar el agente.
- **Higiene del controlador y del agente**: nada se compila ni se ejecuta en el controlador — todo en
  agentes efímeros. La consola de script de Jenkins (`/script`) es ejecución arbitraria como el
  usuario de Jenkins: acceso restringido y auditado.
- **Secretos**: por el binding de credenciales (`withCredentials`), nunca en el `Jenkinsfile`, en
  `gradle.properties` del repo ni en variables de entorno globales. `set -x` en un `sh` y una
  interpolación GString son las dos vías habituales de que un secreto acabe en el log del build.
- **Cadena de suministro del runner** — el control que sí corta. Precedente ya establecido en este
  catálogo y verificado: en 2026 se documentaron **paquetes maliciosos publicados con atestaciones
  SLSA Build L3 criptográficamente válidas** (el gusano sobre 42 paquetes `@tanstack` en mayo de 2026,
  y la oleada sobre `@redhat-cloud-services` en junio), porque los atacantes secuestraron la
  *pipeline legítima* y la procedencia describió correctamente un build comprometido. **La procedencia
  firmada ya no basta**: dice de dónde salió el artefacto, no que sea seguro. Lo que sí corta el
  vector, aplicado al mundo Groovy/CI:
  - **Fijar por SHA o por digest todo lo que entra al runner**: acciones de GitHub por SHA de commit
    (no por tag), imágenes de agente por digest, distribución de Gradle por `distributionSha256Sum`,
    plugins y dependencias por versión exacta con verificación de checksum/firma
    (`gradle/verification-metadata.xml`), Shared Libraries por tag inmutable o commit.
  - **Ninguna resolución de dependencias desde un repositorio arbitrario** declarado en el propio
    script del build.
  - Runner efímero, sin credenciales de larga vida, con egress acotado, y confianza OIDC ligada a un
    **workflow y una rama protegida concretos**, no a "el repositorio". La estrategia completa vive en
    `cicd-standards`; lo que es de aquí es que **el fichero Groovy es el vector**.

## 6. Rendimiento y operabilidad

- En un pipeline el coste dominante casi siempre es el intérprete CPS: la palanca no es optimizar
  Groovy, es **sacar trabajo del pipeline** hacia `sh`/scripts en el agente.
- Gradle: build cache y configuration cache activados; `--scan`/Develocity para saber dónde se va el
  tiempo antes de tocar nada. Tareas propias con entradas/salidas declaradas (si no, no son
  incrementales ni cacheables). Nada de lógica en la fase de configuración.
- Jenkins: `timeout` en cada stage (**un pipeline sin timeout es un agente bloqueado para siempre**),
  `retry` solo en pasos idempotentes, `disableConcurrentBuilds()` donde haya estado compartido, y
  `buildDiscarder` — los `program.dat` y artefactos llenan discos.
- Observabilidad del CI como servicio: duración por stage, tasa de fallo y de *flakiness*, tiempo en
  cola. Un pipeline sin métricas no se puede mejorar (la telemetría, en `observability-standards`).
- El mismo comando debe correr en local y en CI. Si un build solo funciona en el agente, es un bug del build.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: Gradle sigue una cadencia rápida — actualiza el wrapper con regularidad y lee las
  *release notes* antes (los saltos de mayor de Gradle sí rompen plugins). Jenkins: usar la **línea
  LTS**, con actualización mensual y **actualización de plugins como tarea recurrente**, no anual: la
  mayoría de los avisos de seguridad de Jenkins son de plugins.
- Un plugin de Jenkins sin releases y sin mantenedor es deuda de seguridad: se sustituye o se retira.
  Auditar la lista de plugins instalados una vez al trimestre y **borrar lo que no se usa** (cada
  plugin es superficie de ataque en el controlador).
- Deprecaciones propias en una Shared Library: versionadas con tags y con ventana de retirada; los
  pipelines que apuntan a un tag antiguo son deuda visible, que es justo lo que se quiere.

**Lista de prohibiciones (veto):**
- ❌ **PROHIBIDO** desactivar el sandbox de Script Security de Jenkins.
- ❌ **PROHIBIDO** aprobar métodos de reflexión, `System.*`, `getClass`/`getDeclaredMethods` o similares
  en el *script approval*. Si hace falta eso, el diseño está mal.
- ❌ **PROHIBIDO** ejecutar builds de forks o de repos no confiables con acceso a secretos o a
  credenciales con permisos de escritura.
- ❌ Referenciar una Shared Library, una acción o una imagen por rama o tag móvil. Tag inmutable, commit
  o digest.
- ❌ Wrapper de Gradle sin `distributionSha256Sum`; dependencias sin verificación de checksum/firma.
- ❌ Lógica no trivial dentro del `Jenkinsfile` o del `build.gradle`: baja a Shared Library,
  `buildSrc`/convention plugin, o script ejecutable en el agente.
- ❌ Bucles sobre colecciones grandes o cómputo real dentro de un pipeline CPS.
- ❌ Llamar a *steps* del pipeline desde un método `@NonCPS`; mantener objetos no serializables vivos
  a través de un step.
- ❌ GString convertido a `String` en una consulta SQL; interpolación de objetos de credenciales o del
  entorno en logs.
- ❌ Groovy dinámico (sin `@CompileStatic`) en código de aplicación o en `src/` de una Shared Library.
- ❌ AST transforms propias salvo justificación extraordinaria por escrito.
- ❌ Migrar un `build.gradle` grande y sano a `.kts` sin más motivo que la moda.
- ❌ Ejecutar código en el controlador de Jenkins en vez de en agentes efímeros.
- ❌ Pipeline sin `timeout` ni `buildDiscarder`.
- ❌ **Elegir Groovy para código de aplicación nuevo.** Groovy es la elección correcta en tres sitios:
  un `build.gradle` que ya existe, un `Jenkinsfile`, y una suite de **Spock** (que sigue siendo un
  framework de test excelente y un uso plenamente legítimo, incluso para probar código Java o Kotlin).
  Fuera de ahí, un servicio nuevo en la JVM se escribe en Java o Kotlin — tipado estático, tooling,
  rendimiento, contratación y ecosistema juegan todos en contra de Groovy, y el propio proyecto se
  posiciona como lenguaje de *scripting* y DSL, no como plataforma de aplicación.

## 8. Verificación web obligatoria

Antes de fijar versiones o APIs, **verifica online** (WebSearch/WebFetch y los feeds Atom
`https://github.com/OWNER/REPO/releases.atom`; `api.github.com` devuelve 403 sin autenticar):
1. **Groovy**: última 5.0.x y estado de **Groovy 6** (a ago-2026 en `6.0.0-BETA-1`: **no producción**),
   y la matriz de JDK de la versión que vayas a usar en `groovy-lang.org/releasenotes/`. Verificado a
   ago-2026 para Groovy 5: **JDK 11 mínimo de JRE, JDK 17+ para construir Groovy, probado hasta JDK 25**.
2. **Qué Groovy embebe tu herramienta** (Gradle y Jenkins traen el suyo, normalmente más antiguo que
   la última estable): es lo que decide qué características del lenguaje puedes usar.
3. **Gradle**: última estable (9.6.1 a ago-2026, con 9.7 en RC) y las notas de la versión antes de
   subir el wrapper. Confirma que el Groovy DSL sigue **soportado y no deprecado**.
4. **Jenkins**: número de la LTS vigente y, sobre todo, los **avisos de seguridad** de Jenkins y de
   sus plugins (`jenkins.io/security/advisories`) — incluidos los *bypass* del sandbox de Groovy.
5. **Spock**: última estable (2.4 a ago-2026) y su compatibilidad declarada con tu versión de Groovy
   y de JUnit Platform.
6. CVEs de Groovy, Gradle y los plugins de Jenkins en uso (osv.dev / GitHub Advisories).

**Huecos no verificados a ago-2026** (no rellenar de memoria):
- **CodeNarc**: versión actual, licencia y estado de mantenimiento **no verificados**. Antes de fijarlo
  como linter por defecto en un proyecto, comprueba su última release y su `LICENSE` en crudo. Si está
  parado, el gate de calidad de Groovy se apoya en `@CompileStatic` + la compilación + los tests, que
  es donde está el valor real de todos modos.

**Discrepancia declarada**: la página *What's new in Gradle 9* de gradle.org sitúa la adopción del
Kotlin DSL como opción recomendada en **"abril de 2023 (Gradle 8.2)"**, mientras que las notas de la
versión 8.2 en `docs.gradle.org` **no muestran fecha de publicación** que lo confirme y la fecha real
de 8.2 no queda verificada. Lo que sí está verificado verbatim en las notas de la 8.2 es la afirmación
sustantiva: *"Kotlin DSL is now the default option when generating a new project with the init task."*
Usa la afirmación, no la fecha.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
