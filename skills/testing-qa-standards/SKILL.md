---
name: testing-qa-standards
description: Test strategy across languages - deciding what to test and in what proportion, not which runner to use. Use when writing or reviewing a test plan or test pyramid/trophy split, a coverage threshold in CI (codecov.yml, .coveragerc, jacoco check, --cov-fail-under), a mutation testing run (Stryker, PIT/pitest, cargo-mutants, mutmut, stryker.conf.json), Testcontainers-based integration tests, consumer-driven contract tests with Pact (pact_broker, can-i-deploy, pacts/*.json), end-to-end suites in Playwright, Cypress or Selenium, property-based tests (Hypothesis, fast-check, jqwik, proptest) or fuzzing harnesses, snapshot/golden files, load and performance test scripts (k6, Gatling, Locust, JMeter, .jmx), test fixtures and factories or synthetic test data, flaky-test quarantine policy, test environment parity, testing in production (canary, feature flags, shadow traffic), or the QA role versus team-owned quality.
---

# Estándares de estrategia de prueba y calidad

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al decidir **qué se prueba, en qué proporción, con qué criterio de calidad y qué rompe el
build**: reparto entre niveles de prueba, política de cobertura y de mutación, criterio de elección
entre prueba de integración con contenedores y doble de prueba, contrato *consumer-driven*, E2E,
*property-based*, *fuzzing*, *snapshot*, carga, datos de prueba, dobles, política de tests
inestables, presupuesto de tiempo de la suite, paridad de entornos y prueba en producción.

**Esta skill NO elige el *runner* ni sus convenciones de fichero.** Cada skill de lenguaje ya fija
su framework de test en su §4 y ahí se queda: `python-standards` (pytest), `typescript-standards`
(Vitest + Playwright), `go-standards` (`go test`), `rust-standards` (`cargo test`),
`jvm-spring-standards` (JUnit), `dotnet-standards` (xUnit), `php-standards`, `ruby-standards`
(RSpec), `elixir-erlang-standards` (ExUnit), `scala-standards`, `clojure-standards`,
`haskell-fp-standards`, `ocaml-fsharp-standards`, `c-standards`, `cpp-standards`,
`solidity-standards` (`forge test`), `mobile-standards` (XCTest), `dart-standards`,
`sql-standards`, `bash-linux-scripting-standards` (bats), `powershell-standards` (Pester),
`groovy-standards` (Spock). Si aquí aparece escrito "usa pytest", está pisando `python-standards`:
es un error de esta skill, no de aquella.

**Regla de arbitraje, sin ambigüedad**:

| Pregunta | Dueño |
|---|---|
| ¿Con qué binario/librería se escribe y ejecuta el test? ¿Cómo se nombra el fichero? ¿Qué *matcher*, *fixture* o anotación se usa? ¿Cómo se paraleliza en ese ecosistema? | **Skill del lenguaje** |
| ¿Qué comportamiento hay que cubrir? ¿Cuántos tests de cada nivel? ¿Qué umbral rompe el build? ¿Se acepta este test como prueba o es ruido? ¿Qué se hace con un test inestable? | **Esta skill** |
| Conflicto entre ambas | Gana la skill del lenguaje **en la mecánica**; gana esta **en el criterio de aceptación**. Si el conflicto es real (p. ej. la del lenguaje fija un umbral de cobertura distinto), se resuelve por ADR y se corrige la que esté desactualizada. |

**No aplica**: ver las skills de lenguaje citadas arriba (framework, sintaxis y configuración del
*runner*), `cicd-standards` (**la pipeline y sus gates son suyos**: jobs, orden, cachés, runners,
matriz; aquí **qué debe comprobar cada gate y con qué umbral**), `git-workflow-standards` (tamaño
de PR y mecánica del PR), `code-review-standards` (qué se revisa en el diff de un test y cómo se
comenta), `appsec-standards` (modelado de amenazas y triaje de hallazgos; aquí solo el *fuzzing* y
las pruebas negativas como **generadores** de esos hallazgos), `sre-practice-standards`
(**coordinación obligatoria**: fiabilidad en producción, SLO y *error budget* — las pruebas en
producción y el despliegue progresivo se diseñan aquí como pruebas y se **operan** allí),
`observability-standards` (la telemetría que esas pruebas leen), `performance-engineering-standards`
y `web-performance-standards` (**las pruebas de carga se diseñan aquí**;
**los umbrales de latencia y la metodología de optimización son suyos**),
`chaos-engineering-standards` (**la inyección deliberada de fallos con hipótesis de estado
estable es suya**; aquí el test determinista — un *toxic* de Toxiproxy en un test de integración
se configura con su criterio, y el test y sus gates son de aquí), `accessibility-standards`
(el criterio de conformidad WCAG es suyo; aquí solo automatizarlo como prueba que rompe
el build), `privacy-engineering-standards` (**la política de datos personales es suya**; aquí la
prohibición operativa de meterlos en un entorno de prueba), `incident-management-standards`
(postmortem sin culpa; aquí el test de regresión que todo bug arreglado deja obligatoriamente),
`llm-evaluation-standards` (evaluación de salidas no deterministas de un modelo: no es esta skill),
`ai-agents-standards` y `ai-agent-workflow-standards` (trabajo con agentes),
`data-governance-quality-standards` (aserciones de calidad **sobre datos en producción**, no sobre
código), `kubernetes-standards` e `iac-standards` (pruebas de manifiestos y de infraestructura),
`refactoring-tech-debt-standards` (**esta skill es su precondición y conviene decirlo en
las dos direcciones**: **qué se prueba, en qué proporción y con qué criterio de calidad es de
aquí**; **la exigencia de cubrir el comportamiento observable ANTES de tocar la estructura, y las
pruebas de caracterización sobre código heredado sin tests, son suyas**. La regla que ambas
sostienen: **sin tests no se refactoriza, se reescribe a ciegas**).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Criterio de aceptación de un test | Prueba **comportamiento observable** por un contrato público (API, función exportada, evento, fila persistida) | Test de implementación **solo** en algoritmos con invariantes internas caras de observar, y documentado |
| Reparto de niveles | **Trofeo** en servicios con E/S dominante: mayoría integración con dependencias reales en contenedor, unitarios en la lógica pura, E2E mínimo | **Pirámide clásica** cuando la lógica de dominio pesa más que la E/S (motores de cálculo, compiladores, librerías) |
| Dependencias en pruebas de integración | **Testcontainers** (MIT, contenedor real de la dependencia) | Servicio compartido de entorno **solo** si el contenedor es inviable (mainframe, licencia por host) |
| Contrato entre servicios | **Pact** *consumer-driven* + Pact Broker (**ambos MIT**) para HTTP/mensajería interna | Esquema compartido versionado (OpenAPI/protobuf) + verificación en CI si no hay control del consumidor |
| Navegador / E2E | **Playwright** (Apache-2.0) | **Cypress** (MIT) solo en suite existente que ya funciona; **Selenium** (Apache-2.0) cuando hace falta una rejilla de navegadores/SO reales o *bindings* fuera de JS |
| Generación de casos | **Property-based** en parsers, serializadores, invariantes y estructuras de datos; la librería la fija la skill del lenguaje | Tabla de casos escrita a mano cuando el espacio es pequeño y enumerable |
| Entradas no confiables | **Fuzzing continuo** de todo *parser* de entrada externa | *Fuzzing* puntual por campaña si el binario no es un servicio expuesto |
| Carga | **k6** (**AGPL-3.0**, Grafana Labs; serie 2.x) por defecto | **Gatling** (Apache-2.0) en equipos JVM/Scala; **Locust** (MIT) si el escenario necesita Python arbitrario |
| Mutación | Sí, **incremental sobre el diff**, nunca sobre todo el repo | Sin mutación en código sin lógica de decisión (DTOs, mapeos) |
| Cobertura | **Señal, se mide y se publica; el umbral global no es el gate principal** (§4.2) | Umbral duro **solo** en código con requisito normativo o de seguridad funcional |
| Datos de prueba | **Factories** en código (construyen el objeto válido mínimo y exponen solo lo relevante al test) | *Fixtures* declarativas en datos de referencia estables (catálogos, tarifas) |
| Aislamiento entre tests | Estado creado y destruido por el propio test; **prohibido el orden implícito** | Base sembrada de solo lectura, compartida y nunca mutada |
| Reloj, azar y red | **Inyectados** (reloj falso, semilla fija, red simulada en el borde) | — |
| Test inestable | **Cuarentena inmediata con dueño y fecha**; se arregla o se borra (§4.4) | — |

**Estado verificado de las herramientas** (ago-2026, ver §8):

- **Pact**: `pact-js` v17.0.1 (jul-2026), `pact_broker` **MIT** (`LICENSE.txt` en crudo), `pact-js`
  **MIT**. El proyecto está bajo el modelo **"SmartBear supported"**. Verbatim de `docs.pact.io`:
  el compromiso original era *"As a policy, we commit at least 10% of our engineering time toward
  open source development"*, y la propia página lo declara insuficiente — *"that commitment is not
  enough"*, *"the % itself is irrelevant"* — al *"transitioning to a new model we are calling
  'SmartBear supported' that aims a little higher than simply a minimum resource allocation"*.
  **Discrepancia declarada**: el núcleo sigue siendo OSS y MIT, pero **PactFlow / API Hub for
  Contract Testing es comercial** y funciones como la generación de contratos asistida por IA
  **no están en el OSS ni hay plan de abrirlas**. Consecuencia de criterio: **el Broker
  autoalojado (MIT) es el default**; PactFlow es una decisión de compra, no de ingeniería.
- **k6**: **AGPL-3.0** (`LICENSE.md` en crudo, no Apache-2.0 como suele asumirse). Propiedad de
  **Grafana Labs desde 2021** (antes Load Impact); **no se ha localizado ningún cambio de
  propiedad ni de licencia en 2026**: el "cambio de manos" es el de 2021 y sigue vigente. Serie
  actual **2.x** (v2.1.0, jun-2026). La AGPL importa solo si **modificas** k6 y lo expones por red.
- **JMeter**: última release **5.6.3, enero de 2024** — **más de dos años sin versión** a ago-2026,
  corroborado por dos fuentes (`jmeter.apache.org/download_jmeter.cgi` y el feed de tags de
  `apache/jmeter`). **PROHIBIDO elegir JMeter para un proyecto nuevo**; en suites existentes,
  plan de salida.
- **Gatling**: Apache-2.0, v3.15.1 (may-2026), activo. **Locust**: MIT, 2.46.x (ago-2026), activo.
- **Testcontainers**: MIT. **AtomicJar fue adquirida por Docker (2023)**; Docker patrocina las
  implementaciones de los lenguajes más usados y **el resto son *community-driven***.
  `testcontainers-java` 2.x (2.0.5, abr-2026). **No se ha localizado cambio de licencia ni
  donación a fundación**. Riesgo real a vigilar: **Testcontainers Desktop exige cuenta Docker** y
  **Testcontainers Cloud es de pago** — la librería es OSS, el tooling de alrededor no.
- **E2E**: Playwright v1.62.x (Apache-2.0), Cypress v15.x (MIT), Selenium 4.46.x (Apache-2.0);
  los tres activos. **Cypress.io NO ha sido adquirida**: la noticia de la compra por John Deere
  es una broma del 1 de abril de 2025 — no se cita como motivo de migración.
- **Mutación**: Stryker (JS/TS, .NET, Scala) v9.6.x; PIT/pitest (JVM) 1.25.x (jul-2026);
  `cargo-mutants` (Rust) v27.x; `mutmut` (Python) 3.7.0 (jul-2026). Todas con release reciente;
  el estado por lenguaje se re-verifica antes de fijarla en CI (§8).

## 3. Qué es un test que aporta y qué es ruido

### 3.1 Reglas de forma

- **AAA**: *arrange / act / assert*, en ese orden y visualmente separados. Si el *arrange* ocupa
  más que el resto, el diseño del sujeto está mal, no el test.
- **Un motivo de fallo por test.** Varios asserts están bien si todos describen el **mismo**
  comportamiento; están mal si el test puede fallar por dos razones no relacionadas.
- **Cero lógica en el test**: sin `if`, sin bucles que decidan, sin recalcular el resultado
  esperado con la misma fórmula del sujeto. El valor esperado se escribe literal.
- El nombre del test enuncia el **comportamiento y la condición**, no el método invocado:
  `rechaza_transferencia_si_saldo_insuficiente`, no `test_transfer_2`.
- Un test que falla debe decir **qué comportamiento se rompió** sin abrir el código.
- **Determinismo obligatorio**: mismo resultado en la máquina del autor, en CI, en paralelo y en
  orden aleatorio. Ejecutar la suite en orden aleatorio al menos en el job nocturno.

### 3.2 Ruido a borrar en cuanto se detecte

- Tests que solo ejercitan *getters*, *setters*, constructores triviales o mapeos generados.
- Tests que reimplementan el sujeto en el `assert`.
- Tests que verifican **llamadas a un doble** cuando el comportamiento observable ya es
  verificable: eso prueba el doble, no el sistema (§3.4).
- Tests con `sleep`/*polling*: se sustituyen por espera sobre condición o reloj controlado.
- Tests que dependen del orden, del *test* anterior o de datos residuales.
- Tests desactivados sin ticket, sin dueño y sin fecha (§4.4).

### 3.3 Reparto entre niveles: criterio real, no dogma

La pirámide (muchos unitarios, pocos E2E) optimiza **coste y velocidad**. Sus críticas — el
*trofeo* (más peso en integración) y el *panal* (poco unitario, mucha integración, poco E2E) —
son correctas para un tipo de sistema concreto, no universales. El criterio operativo:

- **El reparto lo dicta dónde vive el riesgo, no una figura geométrica.** Cuenta las últimas 20
  incidencias reales: si la mayoría venían de E/S, esquemas, transacciones o integración entre
  servicios, la pirámide clásica te está haciendo escribir tests en la capa equivocada.
- **Servicio con E/S dominante** (CRUD, orquestación, glue): peso en **integración con dependencia
  real en contenedor**. Un unitario que mockea el repositorio no prueba nada que falle en producción.
- **Lógica de dominio densa** (cálculo, reglas, algoritmos, parsers): peso en **unitario**; ahí el
  unitario es rápido, expresivo y encuentra el fallo real.
- **E2E**: número **fijo y pequeño** de flujos críticos de negocio (autenticación, pago, alta,
  el CRUD principal). No se replica en E2E lo que ya cubre una capa inferior. Cada E2E nuevo se
  justifica por escrito o no entra.
- Cada nivel prueba **lo que solo él puede probar**. Duplicar un caso en dos niveles duplica el
  coste de mantenimiento sin añadir señal.

### 3.4 Dobles de prueba

- **Mockea fronteras, no todo.** Frontera = proceso ajeno, red que no controlas, reloj, azar,
  sistema de ficheros, servicio de terceros de pago o con efectos irreversibles.
- **PROHIBIDO mockear un tipo propio del mismo módulo** para no arrancar una dependencia que
  Testcontainers levanta en segundos.
- **El mock que replica la implementación es un test que solo prueba el mock**: si al refactorizar
  sin cambiar comportamiento el test rompe, ese test es deuda, no red de seguridad.
- Un doble de una dependencia **externa** solo es válido si su fidelidad está verificada: por un
  test de contrato (§3.5) o por un test de integración real contra el proveedor en el job nocturno.
- Preferir el doble más simple que funcione: valor real > *stub* > *fake* > *mock* con
  verificación de interacción (último recurso, y solo cuando la interacción **es** el
  comportamiento: p. ej. "se publicó exactamente un evento").

### 3.5 Contrato *consumer-driven*

- Obligatorio en cuanto **dos equipos distintos** despliegan a distinto ritmo a ambos lados de una
  interfaz. Con un solo equipo dueño de los dos lados, un test de integración basta.
- El **consumidor** escribe la expectativa; el **proveedor** la verifica en su propia CI. Un
  contrato escrito por el proveedor no es contrato, es documentación.
- El gate de despliegue del proveedor consulta al Broker (`can-i-deploy`) **antes** de desplegar:
  si rompe a un consumidor con versión desplegada, no sale.
- El contrato **no** sustituye a las pruebas de comportamiento del proveedor: verifica forma y
  compatibilidad, no que la lógica sea correcta.
- El diseño del contrato HTTP/gRPC en sí es de `api-design-standards`; aquí solo su verificación.

### 3.6 Property-based y fuzzing: lo infrautilizado que más rinde

- **Property-based obligatorio** donde exista una invariante enunciable: round-trip
  (`decode(encode(x)) == x`), idempotencia, conmutatividad, orden total, conservación de suma,
  monotonía. Un solo *property test* sustituye decenas de casos de ejemplo y encuentra el borde
  que nadie escribió.
- Todo contraejemplo encontrado se **congela como test de regresión determinista** con su semilla y
  su valor reducido. Sin eso, la propiedad se vuelve a romper y nadie se entera.
- Semilla **aleatoria en el job nocturno** y **fija en el gate de PR**: el PR no puede fallar por
  un caso nuevo no relacionado con el cambio.
- **Fuzzing obligatorio** en todo *parser* de entrada no confiable (formatos binarios,
  deserialización, protocolos, ficheros subidos por usuarios). Corpus versionado en el repo,
  campaña continua fuera del PR, y **cada crash entra como test de regresión antes del arreglo**.
- El *fuzzing* es también control de seguridad: los hallazgos se triazan por `appsec-standards`.

### 3.7 Snapshot testing y su degeneración

- Válido solo cuando la salida es **grande, estable y legible por humanos** y el diff es revisable:
  HTML renderizado, respuesta JSON de contrato, salida de CLI, plan de infraestructura.
- **Degeneración típica y prohibida**: `--update-snapshots` como reflejo ante cualquier fallo.
  Ese comando convierte la suite en un registro de lo que el código hace hoy, no de lo que debe
  hacer, y **aprueba regresiones automáticamente**.
- Reglas duras: el fichero de *snapshot* **se revisa como código** en el PR; un *snapshot*
  ilegible o de miles de líneas se sustituye por asserts explícitos; **nunca** se actualiza un
  *snapshot* en el mismo commit que cambia el comportamiento sin explicarlo en la descripción.
- Los valores volátiles (fechas, IDs, hashes) se normalizan antes de serializar, no se toleran.

## 4. Gates de calidad: qué rompe el build

### 4.1 Orden de coste creciente (el gate barato va primero)

1. Formateador y linter (los fija la skill del lenguaje) — **rompe**.
2. Tipos / análisis estático — **rompe**.
3. Unitarios — **rompe**.
4. Integración con Testcontainers — **rompe**.
5. Contrato: verificación del proveedor + `can-i-deploy` — **rompe el despliegue**, no el PR.
6. E2E del conjunto crítico contra un despliegue de vista previa — **rompe**.
7. Mutación incremental sobre el diff — **avisa**; rompe solo en los módulos declarados críticos.
8. Carga y a11y — **fuera del PR** (nocturno o previo a release), rompen la release.

La ejecución, el orden real y el cacheo de esos pasos son de `cicd-standards`; **lo que aquí se
fija es cuál rompe qué**.

### 4.2 Cobertura: señal, no meta

- **La cobertura mide qué código se ejecutó, no qué comportamiento se verificó.** Una suite sin un
  solo `assert` puede alcanzar cobertura alta. Por eso el umbral global es un gate débil.
- **Se mide siempre y se publica siempre**; se prohíbe *bajar* la cobertura sin justificación
  escrita en el PR. El gate útil es **diferencial sobre el diff** (líneas y ramas nuevas o
  modificadas), no el porcentaje global del repositorio.
- Evidencia disponible, con fuente: en *Code Coverage at Google* (Ivanković, Petrović, Just,
  Fraser — **ESEC/FSE 2019**, pp. 955-963, DOI 10.1145/3338906.3340459) la cobertura se calcula a
  diario sobre mil millones de líneas en siete lenguajes, y **la palanca de accionabilidad es
  aplicarla al nivel del *changeset* y de la revisión de código**, con **umbrales que los
  proyectos adoptan voluntariamente**, no impuestos globalmente. Los **valores numéricos exactos**
  de la tabla de umbrales del artículo **no se han podido verificar en esta pasada** (§8):
  **no se escriben aquí**.
- **No se ha localizado ninguna fuente primaria** que respalde un umbral concreto de cobertura
  (80 %, 90 %) como óptimo. **Por tanto no se fija ninguno en esta skill.** Quien lo fije en su
  proyecto lo hace como convención de equipo, y así se declara.
- Ramas y condiciones > líneas. Cobertura de líneas al 100 % con ramas al 40 % es una métrica
  mentirosa.
- Excluir de la métrica lo generado, los DTOs y el código de arranque; **PROHIBIDO** excluir
  ficheros para maquillar el número.

### 4.3 Mutación: lo que la cobertura no mide

- La mutación responde a la pregunta que la cobertura no responde: **si cambio el código, ¿falla
  algún test?** Un mutante superviviente en código con cobertura alta es un test sin `assert` útil.
- **Siempre incremental sobre el diff** y con límite de mutantes por línea y por revisión: la
  mutación completa del repositorio no es viable ni informativa.
- Evidencia, con fuente: en *Practical Mutation Testing at Scale* (Petrović, Ivanković, Fraser,
  Just — arXiv 2102.11378, evaluación sobre casi 17 millones de mutantes y 760.000 cambios, con
  2 millones de mutantes mostrados durante revisión de código), los desarrolladores clasificaron
  inicialmente el **85 % de los mutantes como improductivos**, y el filtrado y la supresión por
  contexto **elevaron la proporción de mutantes productivos del 15 % al 89 %**. Consecuencia
  directa de criterio: **mutación sin filtrado de mutantes improductivos se abandona sola** — si
  la actives sin filtro, el equipo la apaga en dos semanas.
- Se aplica donde hay lógica de decisión. En mapeos y DTOs es ruido.

### 4.4 Tests inestables (*flaky*): política dura

- **Detección, no intuición**: un test es inestable cuando produce resultados distintos con el
  **mismo** commit. Se detecta con (a) reejecución sistemática de la suite en `main` sin cambios,
  (b) registro histórico por test de la tasa de fallo, (c) ejecución en orden aleatorio y en
  paralelo, (d) marcar como sospechoso todo test cuyo fallo desaparece al reintentar.
- Magnitud del problema, con fuente — *Flaky Tests at Google and How We Mitigate Them*, John
  Micco, Google Testing Blog, mayo 2016, verbatim: *"across our entire corpus of tests, we see a
  continual rate of about 1.5% of all test runs reporting a 'flaky' result"*; *"Almost 16% of our
  tests have some level of flakiness associated with them!"*; *"about 84% of the transitions we
  observe from pass to fail involve a flaky test"*. Ese último dato es el que fija la política:
  **si la mayoría de los fallos rojos son ruido, el equipo deja de mirar el rojo** — y entonces
  la suite ya no protege nada.
- **Política**: cuarentena **inmediata** (fuera del gate, sigue ejecutándose y registrándose),
  **ticket con dueño nombrado y fecha límite**. Vencido el plazo: **se arregla o se borra**. No
  existe la tercera opción.
- **PROHIBIDO el reintento automático como solución.** Un reintento oculta el fallo, y el
  siguiente que lo pague será producción. Reintento admisible **solo** como instrumentación que
  marca el test como inestable y dispara la cuarentena, nunca como forma de poner el build en verde.
- Techo explícito de la suite: si la cuarentena supera el umbral que el equipo declare, **se para
  el trabajo de producto hasta bajarla**. Una suite con inestabilidad crónica es una suite muerta.

### 4.5 Tiempo de la suite como requisito funcional

- **Una suite lenta deja de ejecutarse**, y una suite que no se ejecuta no existe. El tiempo es un
  requisito, no una consecuencia.
- Presupuestos por defecto (ajustables por ADR, no por resignación): **unitarios de un módulo en
  local < 10 s**; **gate completo de PR < 10 min**; **E2E crítico < 15 min**. Superado el
  presupuesto, la acción no es "quitar tests": es paralelizar, mover casos al nivel correcto y
  borrar duplicados entre niveles.
- Se mide y se publica el tiempo por test; los 20 más lentos se revisan periódicamente.
- La suite completa (incluye nocturnos, carga, mutación) puede durar lo que haga falta **fuera**
  del camino crítico del PR.

### 4.6 Regresión obligatoria

- **Todo bug arreglado deja un test que falla antes del arreglo y pasa después.** Sin ese test, el
  arreglo no se aprueba (`code-review-standards`). El postmortem del incidente es de
  `incident-management-standards`; el test es de aquí y es innegociable.
- TDD donde aporta: lógica compleja y **siempre** en *bugfix* — primero el test que reproduce.

## 5. Seguridad y datos de prueba

- **PROHIBIDO copiar datos personales de producción a cualquier entorno de prueba**, incluido el
  de "preproducción idéntica". Aunque el entorno esté cerrado: cambia el ámbito del tratamiento,
  multiplica los accesos y rompe la minimización. La política y su base legal son de
  `privacy-engineering-standards`; **aquí la prohibición es operativa y no admite excepción por
  urgencia**.
- Alternativas, en orden: **datos sintéticos generados por factories**; datos derivados con
  anonimización **irreversible** verificada frente a reidentificación (la técnica y su validación
  las fija `privacy-engineering-standards`); *subset* mínimo de datos no personales.
- El *seed* de un entorno de prueba se versiona en el repo y se genera; nunca se restaura un
  volcado de producción.
- **PROHIBIDO usar credenciales reales, tokens de producción o claves vivas en tests.** Los
  secretos de test son ficticios y no se parecen a los reales. Si un secreto de test se puede
  usar contra un sistema real, es un secreto de producción (`secrets-management-standards`).
- Las pruebas **no** apuntan a producción, salvo las pruebas en producción explícitamente
  diseñadas (§6.3), con datos marcados como sintéticos y aislados de la analítica y la facturación.
- **Pruebas negativas obligatorias** en toda frontera: entrada malformada, sobredimensionada,
  con tipos erróneos, con autorización ajena y sin autenticación. El camino feliz no es un
  criterio de aceptación por sí solo. Las clases de vulnerabilidad y su triaje son de
  `appsec-standards`.
- La suite de test es superficie de ataque de la cadena de suministro: imágenes de Testcontainers
  **fijadas por digest**, dependencias de test tratadas con el mismo rigor que las de producción,
  y el *runner* de CT sin credenciales de producción (`cicd-standards`).

## 6. Entornos, prueba en producción y automatización de a11y y rendimiento

### 6.1 Paridad de entornos: el problema, dicho sin eufemismos

- **Ningún entorno de prueba es igual a producción**, y perseguir esa igualdad es un gasto sin
  final: difieren en datos, volumen, concurrencia, latencia real, versiones de dependencias
  gestionadas, topología de red y perfil de fallo.
- Se declara **explícitamente qué dimensiones tienen paridad** y cuáles no: versión mayor del
  motor de base de datos y del *runtime* **sí**; volumen de datos y tráfico real **no**. Lo que no
  tiene paridad, **no se valida ahí**: se valida con despliegue progresivo en producción (§6.3).
- Entorno **efímero por PR** > entorno compartido de larga vida. Un entorno compartido acumula
  estado, se convierte en *snowflake* y sus fallos dejan de ser información.
- El entorno se crea con el **mismo** código de infraestructura que producción
  (`iac-standards`); si no, su verde no significa nada.

### 6.2 Qué prueba cada entorno

- Local y CI: unitarios, integración con contenedores, contrato.
- Vista previa por PR: E2E crítico, a11y automatizada, *smoke*.
- Preproducción: migraciones de datos contra un volumen realista **sintético**, ensayo de
  *rollback*.
- Producción: lo que solo ahí existe (§6.3).

### 6.3 Prueba en producción

- No es una excusa para no probar antes: es la única forma de validar **tráfico real, datos
  reales y escala real**. Se diseña como prueba y se opera con `sre-practice-standards`; el
  mecanismo de despliegue es de `cicd-standards`.
- **Canary**: porcentaje inicial pequeño, **criterio de aborto definido antes de desplegar** sobre
  señales de síntoma (latencia, errores, saturación), y **rollback automático**. Un canary sin
  criterio de aborto automatizado no es un canary: es un despliegue con testigos.
- **Feature flags**: desacoplan *deploy* de *release* y permiten activar por cohorte. Toda flag
  nace con **dueño y fecha de retirada**; una flag permanente es una rama muerta en producción.
- **Shadow traffic** (espejo del tráfico real contra la versión nueva sin devolver su respuesta):
  la vía para validar rendimiento y compatibilidad con datos reales. **Obligatorio verificar que
  la ruta espejada no produce efectos laterales**: nada de escrituras, cobros, correos ni eventos
  de dominio. Si no puedes garantizarlo, no la actives.
- **Migraciones de datos**: compatibles hacia atrás (*expand/contract*), ensayadas sobre copia con
  volumen realista, con *rollback* probado. Es el cambio que más incidentes graves produce y el
  que menos se prueba.
- Toda prueba en producción exige **telemetría previa** (`observability-standards`): sin señal, no
  hay prueba, hay apuesta.

### 6.4 Accesibilidad y rendimiento como pruebas automatizables

- **Accesibilidad**: la conformidad la define `accessibility-standards`. Aquí: la
  comprobación automatizada se ejecuta en el gate de PR sobre las pantallas críticas y **rompe el
  build** ante violación nueva. Regla de honestidad obligatoria: **el análisis automático cubre
  una fracción de los criterios**; el verde automático **no** es conformidad, y la skill de
  accesibilidad fija qué requiere revisión manual.
- **Carga**: se diseña aquí (escenarios, perfil de llegada, datos, duración, criterio de parada);
  **los umbrales de latencia y percentiles y la metodología de optimización son de
  `performance-engineering-standards` / `web-performance-standards`**.
  Reglas propias de esta skill: la prueba de carga **nunca** va en el gate de PR (es lenta y
  ruidosa); se ejecuta contra un entorno de tamaño declarado; sus resultados solo son comparables
  entre ejecuciones con el **mismo** entorno y **mismos** datos; y una prueba de carga sin
  hipótesis previa ("¿aguanta X req/s con p99 < Y?") es un consumo de recursos, no una prueba.

## 7. Sostenibilidad y prohibiciones

- La suite es código de producción: se refactoriza, se borra lo muerto y se revisa igual
  (`code-review-standards`). Un test sin mantener miente antes que fallar.
- Revisión periódica: tests más lentos, tests que nunca han fallado en un año (candidatos a
  borrado si duplican otro nivel), tests en cuarentena, mutantes supervivientes recurrentes.
- Actualización de herramientas de test con la misma cadencia que las de producción; una
  herramienta de test abandonada bloquea el *upgrade* del lenguaje.
- **El QA como rol no es el dueño de la calidad**: la calidad es responsabilidad del equipo que
  entrega. Un rol de QA aporta cuando diseña la estrategia, construye instrumentación, prueba
  exploratoriamente lo que la automatización no ve y cuestiona los criterios de aceptación.
  **PROHIBIDO el modelo "QA al final del sprint que valida lo que ya está hecho"**: convierte la
  calidad en un filtro externo, retrasa la señal y desresponsabiliza a quien escribió el código.
  **Nadie aprueba su propio criterio de aceptación** y **nadie externo firma la calidad de un
  código que no revisó**.

### Prohibiciones explícitas

- ❌ **PROHIBIDO** fijar aquí el *runner* o la sintaxis de test de un lenguaje: es de su skill (§1).
- ❌ **PROHIBIDO** mergear con tests desactivados, comentados o marcados como *skip* sin ticket,
  dueño y fecha.
- ❌ **PROHIBIDO** el reintento automático para poner el build en verde (§4.4).
- ❌ **PROHIBIDO** usar la cobertura como objetivo de equipo o como métrica de desempeño
  individual; genera tests sin `assert` de forma inmediata y predecible.
- ❌ **PROHIBIDO** excluir ficheros del cálculo de cobertura para subir el número.
- ❌ **PROHIBIDO** `--update-snapshots` como reacción a un fallo sin revisar el diff (§3.7).
- ❌ **PROHIBIDO** datos personales reales en entornos de prueba, sin excepción por urgencia (§5).
  **Única excepción del catálogo, y no la concede esta skill**: el **ensayo de corte** de una
  migración se hace con datos reales **enmascarados** sobre infraestructura equivalente, porque su
  objetivo es medir duración y cuadre, no probar código — el criterio es de
  `migration-projects-standards` y el enmascarado, de `privacy-engineering-standards`. Enmascarado
  significa transformado de forma irreversible antes de salir del origen, no "copiado a un entorno
  con menos gente mirando".
- ❌ **PROHIBIDO** credenciales, tokens o claves reales en tests o en *fixtures*.
- ❌ **PROHIBIDO** `sleep`/*polling* como sincronización en un test.
- ❌ **PROHIBIDO** que un test dependa del orden de ejecución o del estado dejado por otro.
- ❌ **PROHIBIDO** mockear componentes internos propios para evitar levantar una dependencia que
  Testcontainers arranca en segundos.
- ❌ **PROHIBIDO** arreglar un bug sin test de regresión que falle antes del arreglo (§4.6).
- ❌ **PROHIBIDO** E2E como red de seguridad principal: lento, inestable y con diagnóstico pobre.
- ❌ **PROHIBIDO** *shadow traffic* sobre rutas con efectos laterales (§6.3).
- ❌ **PROHIBIDO** elegir JMeter para un proyecto nuevo mientras siga sin releases (§2).
- ❌ **PROHIBIDO** declarar conformidad de accesibilidad por el verde de un escáner automático.
- ❌ **PROHIBIDO** una prueba de carga sin hipótesis, sin entorno declarado y sin datos comparables.

## 8. Verificación web obligatoria

Antes de fijar cualquiera de estos puntos en un proyecto real, comprobar online:

1. **Pact**: licencia en el `LICENSE` en crudo de `pact-foundation/pact_broker` y del *binding* que
   uses; estado del modelo **"SmartBear supported"** y qué ha quedado exclusivo de PactFlow /
   API Hub for Contract Testing. Verificado a ago-2026: núcleo MIT; **hueco**: no hay compromiso
   público cuantificado que sustituya al antiguo "10% of our engineering time".
2. **k6**: sigue en **AGPL-3.0** y bajo Grafana Labs; versión de la serie 2.x y si aparece algún
   cambio de licencia o de propiedad posterior a ago-2026.
3. **JMeter**: si ha salido una versión posterior a **5.6.3 (ene-2024)**. Si sale, revisar esta
   prohibición. **Hueco**: no se ha localizado declaración oficial del proyecto sobre su estado de
   mantenimiento — la conclusión aquí es inferida de la ausencia de releases, no declarada.
4. **Gatling / Locust**: última versión y licencia; y si la separación OSS/Enterprise de Gatling
   ha movido funciones al lado comercial.
5. **Testcontainers**: licencia (MIT) y gobernanza tras la adquisición de AtomicJar por Docker;
   qué módulos siguen siendo *community-driven*; requisitos de cuenta de Testcontainers Desktop.
   **Hueco**: no se ha localizado una página oficial de gobernanza del proyecto (mantenedores,
   proceso de decisión) — solo documentación de producto.
6. **Playwright / Cypress / Selenium**: última versión, licencia y actividad. No dar por buena
   ninguna noticia de adquisición sin fuente primaria (precedente: la "compra de Cypress.io por
   John Deere" es una broma del 1-abr-2025).
7. **Mutación**: estado por lenguaje de Stryker, PIT, `cargo-mutants`, `mutmut` y equivalentes en
   Go, PHP y .NET; y si hay soporte de mutación incremental sobre el diff (sin eso, no se activa).
8. **Cobertura**: valores exactos de la tabla de umbrales de *Code coverage at Google* (ESEC/FSE
   2019) — **hueco declarado, no verificados en esta pasada**; y si existe evidencia publicada
   posterior sobre umbrales óptimos de cobertura, que a ago-2026 **no se ha localizado**.
9. **Coste de encontrar un defecto tarde**: la cifra folclórica del "10x/100x por fase" **no se
   escribe en esta skill** porque no se ha localizado su estudio primario. **Hueco declarado**:
   si se encuentra la fuente original y su metodología, revisar.
10. Cualquier herramienta de esta skill que cambie de licencia o entre en mantenimiento
    (precedentes del catálogo: Trivy cambió de licencia; gitleaks se declaró *feature complete*;
    Brakeman resultó ser de pago pese a la creencia general). Fuente: el `LICENSE` en crudo y la
    web oficial del proyecto, **no** el feed de GitHub por sí solo — un proyecto que se muda de
    organización aparenta abandono en el feed.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
