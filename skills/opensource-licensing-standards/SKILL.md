---
name: opensource-licensing-standards
description: Use when a dependency's license is a hard engineering constraint — checking a LICENSE, COPYING, NOTICE or LICENSES/ file before adding a package, SPDX identifiers and expressions (MIT, BSD-3-Clause, Apache-2.0, Apache-2.0 WITH LLVM-exception, MPL-2.0, LGPL-3.0-only, GPL-2.0-only, GPL-3.0-or-later, AGPL-3.0-only, EPL-2.0, CDDL-1.0, CC-BY-NC-SA-4.0), source-available and fair-source terms (BUSL-1.1, Elastic License 2.0, SSPL-1.0, RSALv2, PolyForm Shield/Noncommercial, Functional Source License FSL, Fair Core License FCL, Monospace Sustainable Core License), a dependency that relicensed under you and the community fork that followed (Pekko, OpenTofu, OpenBao, Valkey, OpenSearch, Railroader), static versus dynamic linking and whether a SaaS distributes, AGPL network copyleft, Apache-2.0 patent grant and its GPL-2.0 incompatibility, dual licensing with a proprietary ee/ directory, an allowed/review/forbidden license policy and the CI gate that enforces it (dependency-review-action allow-licenses, cargo-deny deny.toml, go-licenses, pip-licenses, liccheck, license-checker, ORT, ScanCode Toolkit, FOSSology, Syft, Trivy), REUSE compliance and reuse lint, generating and consuming an SBOM in SPDX or CycloneDX, EU Cyber Resilience Act SBOM duties, a THIRD-PARTY-NOTICES attribution file, CLA versus DCO and Signed-off-by, or the license of a model, dataset or generated artifact.
---

# Estándares de licenciamiento de código abierto y cumplimiento

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**La licencia es una restricción de ingeniería, y se verifica en el momento de añadir la
dependencia — no cuando llega el cliente preguntando.** Una licencia incompatible descubierta
en el `git log` de hace dos años no es un hallazgo legal: es una **deuda de arquitectura** que
ya está en producción, en el instalador del cliente y en la imagen que firmaste. El coste de
comprobarla es de segundos en el PR; el de descubrirla en una *due diligence*, un rediseño.

Corolario operativo, y es la tesis entera de este documento: **el gate va en el PR que añade
la dependencia**. Un escaneo trimestral de todo el árbol produce informes; un gate en el PR
produce decisiones. Si solo puedes tener uno, ten el gate.

**Aviso de alcance — esto NO es asesoramiento jurídico.** Aquí hay criterio de ingeniería y de
cumplimiento: qué se verifica, qué bloquea el build, qué se registra y quién aprueba una
excepción. **La interpretación de una cláusula, la evaluación de riesgo contractual y cualquier
decisión con exposición legal se remiten a asesoría jurídica cualificada** — señaladamente:
vinculación con copyleft fuerte en producto distribuido, obligaciones de un contrato de
proveedor, cláusulas de no competencia de licencias *source-available*, propiedad del trabajo
de un empleado o contratista, y cualquier respuesta a una reclamación de cumplimiento. Este
documento dice **cuándo hay que preguntar a un abogado**; no responde por él.

Cubre: qué es y qué no es código abierto (OSD de la OSI y el debate *source-available* /
*fair-source*); familias de licencia y lo que obligan de verdad; compatibilidad y dirección de
las combinaciones; las distinciones que causan casi todos los errores (enlace estático vs.
dinámico, distribución vs. uso interno, contenedor vs. binario, SaaS); **SPDX** como
identificador canónico; **SBOM** y su obligación regulatoria real; el **proceso**: política,
gate en CI, escaneo, inventario, excepciones y atribución; qué hacer cuando una dependencia
**relicencia**; contribuir hacia fuera (CLA vs. DCO); y licencia de modelos, datasets y
contenido.

Triggers: `LICENSE`, `LICENSE.md`, `LICENSE.txt`, `COPYING`, `NOTICE`, `LICENSES/`,
`REUSE.toml`, `.reuse/dep5`, `THIRD-PARTY-NOTICES`, `deny.toml`, `.licenserc`,
`dependency-review-action`, `allow-licenses`, `deny-licenses`, `cargo deny check licenses`,
`go-licenses`, `pip-licenses`, `liccheck`, `license-checker`, `reuse lint`, `scancode`,
`FOSSology`, ORT (`.ort.yml`, `evaluator.rules.kts`); identificadores SPDX (`MIT`,
`Apache-2.0`, `MPL-2.0`, `GPL-3.0-or-later`, `AGPL-3.0-only`, `LGPL-3.0-only`, `EPL-2.0`,
`CDDL-1.0`, `BSD-3-Clause`, `WITH LLVM-exception`, `LicenseRef-*`); expresiones SPDX
(`AND`, `OR`, `WITH`); *source-available* (`BUSL-1.1`, ELv2, SSPL, RSALv2, PolyForm, FSL, FCL,
MSCL); `SPDX-License-Identifier:` en cabecera de fichero; SBOM (`bom.json`, `*.spdx.json`,
CycloneDX, `syft`, `trivy sbom`); CRA; CLA, DCO, `Signed-off-by:`; relicencia, bifurcación.

### Esta skill es la DUEÑA TRANSVERSAL del asunto

**Todas las skills del catálogo verifican la licencia de las herramientas que fijan** — y
varias lo han hecho encontrando sorpresas (§3.6). Eso está bien y debe seguir así. Pero
**la política de licencias, el gate que la impone y el proceso de excepción viven AQUÍ, y solo
aquí**. Una skill de lenguaje decide *qué linter usar*; **no** decide si AGPL es aceptable en
el producto. Si otra skill del catálogo contradice la política de §5.1, **manda esta**.

> **Precedente que justifica el procedimiento de §6, verificado en esta serie**: en **YottaDB** el
> fichero llamado `LICENSE` **no contiene la licencia** —es texto explicativo de copyright—; la
> licencia real (**AGPLv3**) está en `COPYING`. Y **GnuCOBOL** es GPLv3 en el compilador pero
> **LGPLv3 en el runtime**, con la trampa añadida de que su backend ISAM por Berkeley DB arrastra
> condiciones de Oracle. Consecuencia operativa: **no basta con leer el fichero que se llama
> `LICENSE`; hay que leer el que contiene la licencia**, y comprobar si compilador y runtime van
> por separado.
>
> **Variantes del mismo fallo, todas confirmadas en el catálogo** — cualquier verificación mecánica
> que asuma `raw.../main/LICENSE` produce **falsos negativos**: fichero con **otro nombre**
> (`COPYING` en YottaDB), **otra extensión** (`LICENSE.txt` en NetBox, `LICENSE.md` en Traefik),
> **otra capitalización** (`License.txt` en Lucee, `license.txt` en BoxLang) y **otra rama por
> defecto** (`master` en Angie, `7.0` en Lucee, `development` en BoxLang). Y un aviso extra:
> **la clasificación automática de licencia de GitHub se equivoca** — marca BoxLang como
> `NOASSERTION` por llevar un preámbulo comercial delante de un texto Apache-2.0 perfectamente
> válido. **La API no sustituye a leer el fichero.**

**No aplica**: ver `vulnerability-management-standards` (**frontera fina y recíproca: el mismo
SBOM sirve a los dos y por eso se confunden**. El SBOM se genera una vez y se consume dos
veces: *para CVEs* —triaje, EPSS/KEV, VEX, SLA de parcheo— **es suyo**; *para obligaciones de
licencia* —qué puedo combinar, qué debo publicar, qué debo atribuir— **es de aquí**. Regla:
si la pregunta es "¿esto me puede comprometer?", es suya; si es "¿esto me obliga a algo?", es
de aquí), `cicd-standards` (**la pipeline ejecuta el gate**: el runner, el job, el caché, el
OIDC y la firma del artefacto son suyos; **el umbral, la lista permitida y qué rompe el build
son de aquí**), `grc-compliance-standards` (**el marco normativo corporativo, el registro de
riesgo, la aceptación formal y la evidencia de auditoría son suyos**; aquí el control técnico
que los alimenta y el inventario de licencias), `secrets-management-standards` (una clave de
licencia comercial —Directus, gitleaks-action— **es un secreto y se gestiona allí**; que la
necesites es un hecho de licencia y es de aquí), `appsec-standards` (clases de vulnerabilidad
y selección de SAST/DAST; **que Brakeman no sea libre es de aquí**), `ai-governance-standards`
(**la gobernanza del uso de IA —inventario de sistemas, AI Act, evaluación de impacto— es
suya; la licencia del artefacto —pesos, dataset, término de uso del proveedor— es de aquí**),
`ai-agent-workflow-standards` (**ya escrita**: la licencia y autoría del código generado por un
agente **está declarada allí como cuestión NO RESUELTA**. Se respeta: esta skill **no inventa
una respuesta**, solo fija el procedimiento de §6.4 —trazabilidad y verificación de
procedencia— que es válido con independencia de cómo se resuelva), `git-workflow-standards`
(**el fichero de licencia del repositorio, el `Signed-off-by` y la firma del commit son
suyos**; qué licencia poner y por qué exigir DCO en vez de CLA es de aquí), y las skills de
lenguaje —`python-standards`, `go-standards`, `rust-standards`, `typescript-standards`,
`java`/`jvm-spring-standards`, etc.— (**el gestor de paquetes concreto, su fichero de bloqueo
y el comando de escaneo de su ecosistema son suyos**; la política que ese comando aplica es de
aquí). Con `green-it-standards`: **la licencia de las herramientas de medición de carbono se
rige por esta skill**. **Aquí solo la licencia *libre***: la **licencia comercial propietaria** y
la **auditoría de fabricante** —usuario nombrado, acceso indirecto, medición y declaración anual—
son de `erp-sap-standards` y `crm-salesforce-standards`.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Ámbito | Default | Motivo / alternativa justificable |
|---|---|---|
| Licencia de lo que publicas (librería) | **Apache-2.0** | Es la permisiva con **concesión de patentes explícita** (§3.2). MIT/BSD-3 solo si el ecosistema lo impone (npm, Go). En Rust, el idiom es `Apache-2.0 OR MIT` — el `OR` existe precisamente para dar salida a la incompatibilidad con GPL-2.0 |
| Licencia de aplicación interna no distribuida | **Propietaria / sin licencia pública** | No publicar no es un descuido; publicar sin decidirlo sí. Un repo sin `LICENSE` **no es open source**: sin concesión expresa rigen los derechos reservados por defecto |
| Identificador | **Expresión SPDX** en `LICENSE`, en metadatos del paquete y en cabecera (`SPDX-License-Identifier:`) | Único formato parseable por un gate. Prosa libre = revisión manual |
| Listado de licencias | **SPDX License List** — verificar versión vigente (§8) | Es el vocabulario del gate. Lo no listado va como `LicenseRef-...` y **entra en revisión manual por definición** |
| Especificación SPDX | **3.0.1** (dic-2024) como versión publicada; 3.1 en *release candidate* desde ene-2026 | No confundir versión de **especificación** (3.0.1) con versión del **listado** (3.x independiente, en 3.28.0 a feb-2026). Verificar ambas por separado (§8) |
| Formato de SBOM | **CycloneDX** para consumo interno; **SPDX** cuando lo exija el cliente o el regulador | Verifica la versión que tu consumidor admite antes de generar: hay consumidores que rechazan la última menor. Este criterio de versión se coordina con `vulnerability-management-standards` |
| Generación de SBOM | **Syft** (o `trivy sbom`) en el pipeline de build, sobre el **artefacto**, no sobre el repo | El SBOM del repo no describe lo que despliegas. Verificar licencia y estado de la herramienta (§8) |
| Detección de licencia (profunda) | **ScanCode Toolkit** (Apache-2.0) | Escanea texto real de ficheros, no el manifiesto. Es la única forma de detectar los casos de §3.6 |
| Flujo de *clearance* y revisión | **FOSSology** (GPL-2.0) si hay obligación formal de auditoría | Verificar licencia de la herramienta antes de integrarla en producto: FOSSology es copyleft fuerte, lo cual **es irrelevante para usarla y relevante si la embebes** |
| Orquestación en CI | **ORT (OSS Review Toolkit)**, Apache-2.0 | Ejecuta ScanCode + evalúa contra tu política + genera atribución. Es el único de la lista que hace las tres cosas. Coste: es un proyecto en sí mismo |
| Gate en PR (GitHub) | **`dependency-review-action` con `allow-licenses`** — **nunca** `deny-licenses` | `deny-licenses` está **deprecada** y prevista para eliminación en la próxima mayor. Y el argumento de fondo es correcto: una lista de prohibidas siempre olvidará una (el clásico: prohíbes `GPL-2.0` y entra `CC-BY-SA-4.0`). **Lista blanca o no hay gate** |
| Gate por ecosistema | **La herramienta nativa**: `cargo-deny` (Rust), `go-licenses` (Go), `pip-licenses`/`liccheck` (Python), `license-checker` (npm), `dependency-license-report` (JVM) | `dependency-review-action` solo ve las dependencias **que cambian en el PR**; el gate nativo ve el grafo entero. **Se necesitan los dos**, y ambos como *required status check* |
| Marcado de autoría en el repo | **REUSE** (`LICENSES/`, cabeceras `SPDX-License-Identifier`, `reuse lint` en CI) | Verificar versión vigente de la especificación (§8; había 3.3 de nov-2024 con indicios de 3.4 posterior — **declarar la discrepancia**, ver §8). Aviso práctico: GitHub identifica la licencia con `licensee`, que **no** entiende REUSE — deja un `LICENSE` en la raíz además del directorio |
| Atribución al distribuir | **`THIRD-PARTY-NOTICES.txt` generado en el build**, versionado junto al artefacto | Generado, no escrito a mano: un fichero manual está desactualizado el día 2. Ver §5.4 |
| Contribuciones entrantes | **DCO** (`Signed-off-by:`) | Menos fricción y suficiente para la mayoría de proyectos. **CLA** solo si necesitas relicenciar o vender excepciones — y entonces di en voz alta que ese es el motivo (§6.1) |

## 3. Qué es open source, qué no, y qué obliga cada familia

### 3.1 La definición y el borde

La **Open Source Definition** (OSI) abre, **verbatim**:

> «Open source doesn't just mean access to the source code. The distribution terms of
> open source software must comply with the following criteria:»

y enumera diez criterios, cuyos títulos son, **verbatim**: *Free Redistribution*; *Source
Code*; *Derived Works*; *Integrity of The Author's Source Code*; *No Discrimination Against
Persons or Groups*; *No Discrimination Against Fields of Endeavor*; *Distribution of License*;
*License Must Not Be Specific to a Product*; *License Must Not Restrict Other Software*;
*License Must Be Technology-Neutral*. El documento se identifica como **«Version 1.9, last
modified, 2007-03-22»**.

**Regla dura**: el criterio 6 (*No Discrimination Against Fields of Endeavor*) es el que
descarta a casi todo lo *source-available*. Una cláusula que dice «no puedes ofrecer esto como
servicio competidor» o «no para uso comercial» **discrimina un campo de actividad** y por tanto
**no es open source**, por mucho que el repositorio esté en GitHub y ponga «open» en la portada.

Estado a ago-2026 de las licencias que más confusión causan — **ninguna aprobada por la OSI**:

| Licencia | Qué es | Nota |
|---|---|---|
| **SSPL-1.0** | *source-available*, copyleft extendido al *stack* de servicio | MongoDB la retiró de la solicitud a la OSI en 2019; en ene-2021 la OSI declaró que **no cumple la OSD** por discriminar campos de actividad, y la calificó de *«fauxpen» source* |
| **Elastic License 2.0 (ELv2)** | *source-available*, prohíbe ofrecerlo como servicio gestionado | La propia Elastic la describe como **no aprobada por la OSI** |
| **BUSL-1.1 / BSL** | no competencia + **conversión a open source diferida** (por defecto 4 años) | «BSL is not an OSI approved license» — declaración de la propia Elastic. La *Additional Use Grant* es **variable por proyecto**: hay que leer la del proyecto concreto, no «la BUSL» |
| **RSALv2** | *source-available* de Redis | — |
| **PolyForm Shield / Noncommercial / Perimeter** | *source-available* con cláusula anticompetencia o no comercial | — |
| **FSL** (Functional Source License) | *fair source*: no competencia + conversión a Apache-2.0 o MIT **a los 2 años** | Creada por Sentry como simplificación de la BUSL, fijando sus variables |
| **FCL** (Fair Core License) | variante de FSL «que incluye soporte de clave de licencia» (fair.io, verbatim) | Añade limitaciones derivadas de ELv2 |
| **MSCL** (Monospace Sustainable Core License) | derivada de FCL, usada por Directus v12 | Ver §3.6 |

**Fair Source** se define en torno a tres condiciones: código legible públicamente, uso /
modificación / redistribución con restricciones mínimas, y **publicación diferida como open
source (DOSP)**. fair.io reconoce, verbatim: **FSL** («A simple non-compete license with
eventual Open Source conversion after two years»), **FCL** («A variant of FSL that includes
license key support») y **BUSL/BSL** («A complex non-compete license with eventual Open Source
conversion after a certain amount of time, usually four years»). *Fair source* **no es open
source y no lo pretende**; el conflicto es de nomenclatura, no de honestidad.

**Discrepancia declarada**: la propia OSI es fuente del concepto de *Delayed Open Source
Publication* que sustenta la designación *fair source*, y a la vez miembros de su junta
sostienen públicamente que estas licencias **no son open source** porque sus libertades no
alcanzan a todos y la no competencia es «legalmente difusa». **Ambas cosas son ciertas a la
vez**: la OSI reconoce el *mecanismo* (DOSP) y rechaza la *etiqueta*. No cites una sin la otra.

**Consecuencia operativa de la conversión diferida** — y esto casi nadie lo explota: en una
licencia con DOSP, **cada versión concreta tiene su propia fecha de conversión**. Akka pasó a
BSL en 2022 y sus versiones revierten a Apache-2.0 **36 meses después de su publicación**;
Akka 2.7.0 ya revirtió. Regla: **una licencia con DOSP no se evalúa como licencia, se evalúa
como calendario** — anota en el inventario la versión, su fecha de publicación y su fecha de
conversión, porque la respuesta cambia con el tiempo sin que nadie toque nada.

### 3.2 Familias y lo que obligan de verdad

**Permisivas — MIT, BSD-2/3-Clause, ISC, Apache-2.0.** Obligan a **conservar el aviso de
copyright y la licencia** al redistribuir. Eso ya es una obligación real y es la que más se
incumple (§5.4). **La razón técnica para preferir Apache-2.0 sobre MIT no es el copyleft: es la
concesión expresa de patentes** y su cláusula de terminación —si demandas por patentes a un
usuario del software, pierdes la licencia de patente—. MIT y BSD guardan silencio sobre
patentes, y el silencio no es una concesión. Apache-2.0 añade además la obligación del fichero
`NOTICE`: si el proyecto trae uno, **lo propagas**.

**Copyleft débil.**
- **LGPL (2.1 / 3.0)**: el copyleft alcanza a la librería, no a tu aplicación, **a condición de
  que el usuario final pueda sustituir la librería por otra versión**. Con **enlace dinámico**
  eso es trivial; con **enlace estático** obliga a entregar objetos o fuentes que permitan
  reenlazar. LGPL-3.0 añade además la cláusula anti-*tivoization* heredada de GPL-3.0.
  **Precedente real del catálogo: Pa11y es LGPL-3.0**, no MIT.
- **MPL-2.0**: el copyleft es **por fichero, no por proyecto**. Modificas un `.js` cubierto →
  ese fichero sigue siendo MPL y publicas ese fichero modificado. Tu código nuevo en ficheros
  nuevos **no queda contaminado**. Esto la hace apta para combinar con propietario, y es la
  razón de que sea la elección de tanta herramienta de desarrollo. **Precedentes reales:
  axe-core, StyLua, selene, Lightning CSS y `data.table` son MPL-2.0**; OpenBao también.
- **EPL-2.0**: copyleft de alcance de «módulo», con obligaciones de *source availability* y una
  cláusula de patentes propia. Punto fino: **EPL-2.0 admite designar la GPL como licencia
  secundaria** — si el proyecto lo ha hecho, la respuesta de compatibilidad cambia. **Léelo en
  el fichero, no lo asumas.**

**Copyleft fuerte.**
- **GPL-2.0 vs. GPL-3.0**: no son la misma decisión. GPL-3.0 añade anti-*tivoization*
  (obligación de entregar la información de instalación en hardware de consumo), concesión de
  patentes expresa y compatibilidad con Apache-2.0. **`GPL-2.0-only` y `GPL-2.0-or-later` son
  licencias distintas y el gate debe distinguirlas**: `-or-later` te deja subir a 3.0 y
  resolver incompatibilidades; `-only` no. **Precedente real: perltidy es GPL-2.0.**
- **AGPL-3.0 — el disparador de «uso en red», y es el que mata un SaaS.** GPL obliga a entregar
  fuentes **al distribuir**; AGPL obliga además a ofrecer el *Corresponding Source* **a los
  usuarios que interactúan con el programa a través de una red**, aunque nunca distribuyas un
  binario. **Esto convierte «no distribuimos, luego no nos aplica» —el razonamiento correcto
  para GPL en un SaaS— en falso.** El alcance es el programa modificado y su *Corresponding
  Source*, no todo tu *stack* (eso es SSPL, y por eso SSPL no es open source). **Precedentes
  reales: k6, Pyroscope, Slither, Echidna y Medusa son AGPL-3.0**; y Elasticsearch (2024) y
  Redis 8 (2025) volvieron a la OSD **por la vía AGPL**, precisamente porque disuade la reventa
  como servicio sin salir de la definición.
- **CDDL-1.0 — aparece donde nadie la espera.** Copyleft por fichero (como MPL-1.1, de la que
  desciende) y **considerada incompatible con la GPL por la FSF**, entre otras cosas por sus
  cláusulas de jurisdicción. Es el motivo del eterno problema de ZFS en el kernel Linux.
  **Precedente real del catálogo: FlameGraph es CDDL**, y aparece en cualquier flujo de
  perfilado sin que nadie lo mire.

**Excepciones (`WITH`).** Una excepción SPDX **cambia el resultado**: `Apache-2.0 WITH
LLVM-exception` (Wasmtime, y todo el ecosistema LLVM) existe justamente para evitar
obligaciones de atribución en binarios enlazados y facilitar la combinación. Tratar
`Apache-2.0 WITH LLVM-exception` como `Apache-2.0` a secas es un error de análisis, no un
matiz. **El gate debe entender el operador `WITH`**; si tu herramienta lo colapsa, tienes un
falso resultado y no lo sabes.

### 3.3 Compatibilidad: es direccional, no simétrica

**La pregunta correcta nunca es «¿son compatibles A y B?», sino «¿bajo qué licencia queda la
obra combinada, y puedo aceptarla?».** La compatibilidad tiene sentido de circulación:

- **Apache-2.0 → GPL-3.0**: se combinan, y **el resultado es GPL-3.0**. Al revés no: el código
  GPL-3.0 no puede entrar en un proyecto Apache.
- **Apache-2.0 ↔ GPL-2.0-only**: **incompatibles**. La FSF sostiene que todas las versiones de
  la Apache License son incompatibles con GPL v1 y v2, por las cláusulas de patentes e
  indemnización. Este es el conflicto más común y más silenciado del ecosistema real, y la
  razón de que Rust se publique como `Apache-2.0 OR MIT` (eliges MIT y el problema desaparece)
  y de que LLVM redactara su excepción.
- **MPL-2.0 → GPL/LGPL**: MPL-2.0 se diseñó explícitamente para ser compatible (a diferencia de
  MPL-1.1), salvo que el proyecto haya marcado el fichero como *Incompatible With Secondary
  Licenses*. **Ese aviso está en la cabecera del fichero: si no lo has leído, no has verificado
  la compatibilidad.**
- **CDDL ↔ GPL**: **incompatibles** según la FSF.
- **Permisiva → propietaria**: siempre posible, con la obligación de atribución intacta.

**Regla del gate**: la compatibilidad no se razona en el PR, se **decide una vez** en la
política de §5.1 y el PR solo comprueba pertenencia a la lista. Razonar compatibilidad en cada
PR garantiza que un día se razone mal, con prisa, un viernes.

### 3.4 Las cuatro distinciones que causan casi todos los errores

1. **Enlace estático vs. dinámico.** Determina si LGPL te obliga a permitir el reenlazado
   (§3.2). Un binario Go es **siempre estático**: en Go, «enlazamos dinámicamente» no es una
   opción disponible y ese argumento no existe. Un contenedor `FROM scratch` con un binario
   estático dentro tampoco te salva.
2. **Distribución vs. uso interno.** El copyleft clásico (GPL, LGPL, MPL, EPL) se dispara al
   **distribuir**, no al usar. Software GPL usado internamente y nunca entregado a un tercero
   **no genera obligación de publicar**. Ese razonamiento es correcto **y AGPL lo anula** (§3.2)
   — y también lo anula un cliente al que le entregas una máquina virtual, un `.deb`, una
   imagen o un dispositivo.
3. **Contenedor vs. binario.** Entregar una imagen de contenedor **es distribución de todo lo
   que hay dentro**: la imagen base, sus paquetes de sistema y sus librerías, no solo tu
   aplicación. Tu SBOM del código fuente no cubre eso. **Por eso el SBOM se genera del
   artefacto** (§2). Una imagen base con un paquete GPL que tú no invocas **sigue siendo
   distribución de ese paquete**.
4. **¿Un SaaS distribuye?** Bajo GPL/LGPL/MPL, la respuesta operativa por defecto es **no**: dar
   acceso a un servicio no es entregar copias. **Bajo AGPL, sí en la práctica**: se dispara la
   obligación hacia los usuarios en red. Y hay dos fugas frecuentes que rompen el «no
   distribuimos»: **el código que envías al navegador del usuario** (tu bundle de JavaScript
   *sí* se distribuye, a todos y cada uno) y **cualquier agente, CLI o SDK que instale el
   cliente**. Un backend que no distribuye con un frontend que sí es el caso normal, no la
   excepción.

### 3.5 SPDX y el fichero

Identificador canónico, en tres sitios y los tres obligatorios cuando publicas:
`LICENSE`/`LICENSES/` con el **texto completo**; el campo de licencia del manifiesto con la
**expresión SPDX**; y `SPDX-License-Identifier: <expr>` en la **cabecera de cada fichero**
(REUSE). Expresiones: `AND` (cumples ambas), `OR` (eliges una — **y hay que registrar cuál
eliges**, porque `Apache-2.0 OR MIT` sin elección declarada es una decisión pendiente), `WITH`
(excepción). Lo que no tenga identificador listado va como `LicenseRef-...` y **entra en
revisión manual por definición** — nunca se autoaprueba un `LicenseRef` ni un `NOASSERTION`.

### 3.6 Por qué el campo `license` del manifiesto MIENTE

**Este apartado es el núcleo de la skill y su motivo de existir.** Durante la construcción de
este catálogo, **verificando el fichero `LICENSE` en crudo**, aparecieron los siguientes casos —
todos con documentación de terceros afirmando lo contrario:

| Caso | Lo que dice casi todo el mundo | Lo que dice el fichero |
|---|---|---|
| **Brakeman** | «MIT, es el escáner estándar de Rails» | **Brakeman Public Use License**, propietaria de Synopsys. Código anterior a 15-jun-2018: MIT. Posterior: no libre. **Escanear tu propio código está permitido; embeberlo en un producto o servicio comercial requiere acuerdo comercial.** Fork libre del código pre-adquisición: **Railroader** |
| **Directus** | «CMS headless open source» | Desde **v12 (may-2026): Monospace Sustainable Core License**, derivada de FCL. Uso comercial gratuito solo mediante **Open Innovation Grant**, con límite de **<5 M$ de ingresos anuales y <50 empleados**; conversión a **GPLv3 a los 4 años**; **clave de software** obligatoria (adiós al sistema de honor). Los SDK siguen MIT. **El paquete y el producto no comparten licencia** |
| **WebPageTest** | «herramienta open source de rendimiento web» | **PolyForm Shield**: *source-available* con cláusula anticompetencia |
| **FlameGraph** | «script de perfilado, MIT seguro» | **CDDL** — incompatible con GPL (§3.2) |
| **k6, Pyroscope** | «open source» (cierto) | **AGPL-3.0** — cierto y **relevante si los embebes en un servicio** |
| **Slither, Echidna, Medusa** | «herramientas de Trail of Bits» | **AGPL-3.0** |
| **Pa11y** | «MIT como el resto de npm» | **LGPL-3.0** |
| **axe-core, StyLua, selene, Lightning CSS, `data.table`** | «MIT / permisiva» | **MPL-2.0** (copyleft por fichero) |
| **perltidy** | — | **GPL-2.0** |
| **Playwright** | — | **Apache-2.0** (no MIT) |
| **Extism** | — | **BSD-3-Clause** |
| **Wasmtime** | «Apache-2.0» | **Apache-2.0 WITH LLVM-exception** — la excepción cambia el análisis (§3.2) |
| **Tolgee, Strapi** | «open source» | **Duales, con directorio `ee/` propietario en el mismo repositorio**. El repo tiene una licencia; **partes del repo tienen otra** |
| **gitleaks** | «MIT» | El **escáner** es MIT y su autor lo declaró *feature complete* (solo parches de seguridad; sucesor: Betterleaks). La **acción de GitHub `gitleaks-action`** es **propietaria desde v2.0.0** y **exige clave de licencia para escanear repositorios de una organización** (gratuita vía formulario, con tiers de pago por número de repos). **Dos artefactos, dos licencias, mismo nombre** |
| **Infracost** | «Apache-2.0, gratis» | El **CLI** es Apache-2.0; **la API de precios alojada de la que depende tiene cuota y plan de pago**. Licencia libre ≠ funcionamiento gratuito |
| **Akka** | «Apache-2.0» | **BSL desde 2.7.x** (2022), con umbral comercial declarado en el entorno de ~25 M$ de ingresos y **reversión automática a Apache-2.0 a los 36 meses por versión**. Bifurcación: **Apache Pekko** (desde 2.6.x, graduada en la ASF) |
| **Vault** | «open source» | **BUSL desde 2023**. Bifurcación: **OpenBao** (MPL-2.0, Linux Foundation) |
| **Trivy** | «Apache-2.0 de siempre» | **Cambió de licencia** — verificar la del artefacto y versión que uses (§8) |
| **Elasticsearch** | «volvió a ser open source» | **Añadió AGPL-3.0 (2024) junto a SSPL y ELv2 para el código fuente**. **Hueco abierto: la licencia de los binarios distribuidos por Elastic** — hay indicios de que las *releases* siguen bajo Elastic License aunque el fuente sea triple. **No se cierra aquí: ver §8** |

**Las cinco reglas que se derivan, y son la política:**

1. **El campo `license` del manifiesto es una declaración del empaquetador, no un hecho
   verificado.** Se lee el fichero `LICENSE` **de la versión concreta que vas a usar**.
2. **Un repositorio puede tener más de una licencia.** El directorio `ee/`, `enterprise/` o
   `pro/` es el patrón estándar del *open core*; el manifiesto raíz **no lo refleja**.
3. **Un proyecto puede tener más de un artefacto con licencias distintas** (gitleaks vs.
   gitleaks-action; Directus core vs. SDK; Elasticsearch fuente vs. binario). **La unidad de
   análisis es el artefacto que instalas, no el proyecto que lo publica.**
4. **La licencia se ata a la versión.** «X es MIT» es una afirmación sin sentido sin versión.
5. **Licencia libre ≠ gratis en operación** (Infracost) y **licencia libre ≠ mantenido**
   (gitleaks). Verifica las tres cosas: licencia, coste operativo y estado del proyecto.

## 4. Calidad del gate: qué se comprueba y qué rompe el build

En orden de coste creciente. Los tres primeros son obligatorios; el cuarto depende de si
distribuyes.

1. **Precondición — fichero de bloqueo.** Sin `uv.lock` / `package-lock.json` / `go.sum` /
   `Cargo.lock` / `poetry.lock` el grafo no es determinista y **cualquier escaneo describe una
   resolución que no volverá a ocurrir**. Sin bloqueo no hay gate: hay teatro.
2. **Gate en el PR (segundos).** `dependency-review-action` con `allow-licenses`. Falla si la
   dependencia **nueva** trae una licencia fuera de la lista blanca. Nota práctica: `OTHER` no
   es un identificador SPDX válido y se traduce a `LicenseRef-clearlydefined-OTHER` — úsalo en
   esa forma en la lista o tendrás falsos verdes.
3. **Gate del grafo completo (minutos, en cada build de `main`).** Herramienta nativa del
   ecosistema. **Rompe el build.** Aviso concreto: `cargo-deny` **eliminó** `deny`, `copyleft`,
   `allow-osi-fsf-free` y `unlicensed` — ahora **todo se deniega salvo lo explícitamente
   permitido**, que es exactamente el modelo correcto; un `deny.toml` viejo con esos campos
   **falla con error**, no se degrada en silencio. Y comprueba el alcance: por defecto excluye
   *dev-dependencies* e **incluye *build-dependencies***, porque estas sí influyen en el
   artefacto.
4. **Escaneo profundo de texto (nocturno o por *release*).** ScanCode/ORT sobre el artefacto.
   Es el único que detecta ficheros con cabecera distinta a la del proyecto, código copiado y
   directorios `ee/`. **No bloquea el PR; abre un ticket con SLA.**
5. **`reuse lint`** si publicas: falla si algún fichero carece de información de licencia.

**Qué rompe el build (no negociable):**
- ❌ Licencia fuera de la lista permitida (§5.1).
- ❌ Licencia **desconocida**, `NOASSERTION`, `LicenseRef-*` sin excepción aprobada. **Lo
  desconocido se trata como prohibido**, no como pendiente: «pendiente» significa que se
  fusiona y nadie vuelve.
- ❌ Copyleft fuerte (GPL/AGPL) en un artefacto que se distribuye o en un servicio en red, sin
  excepción registrada.
- ❌ Cambio de licencia de una dependencia **ya existente** entre dos versiones — es el evento
  de §6.2 y debe alertar aunque la nueva licencia también esté permitida.
- ❌ Ausencia de SBOM del artefacto en un build de *release*.

**Falsos positivos y negativos, con honestidad**: la detección por manifiesto tiene un falso
negativo estructural (§3.6) y la detección por texto tiene falsos positivos abundantes (un
`LICENSE` de ejemplo dentro de un directorio de tests dispara alertas). **Toda supresión de un
hallazgo se registra con motivo y caduca** — el mismo modelo que un VEX en
`vulnerability-management-standards`. Una supresión sin fecha es una excepción permanente
disfrazada.

## 5. Política, inventario y obligaciones

### 5.1 Las tres listas

La política tiene **exactamente tres categorías**, y la lista se publica en el repo, no en una
wiki que nadie lee:

| Categoría | Contenido típico | Regla |
|---|---|---|
| **Permitidas** | MIT, BSD-2/3-Clause, ISC, Apache-2.0, Apache-2.0 WITH LLVM-exception, Unlicense, CC0-1.0, Zlib | Autoaprobadas. El gate no pregunta |
| **Con revisión** | MPL-2.0, EPL-2.0, LGPL-*, CDDL-1.0, GPL-* con `-or-later`, duales con `ee/`, cualquier `LicenseRef-*` | Se aprueban **por dependencia y por caso de uso** (distribuido / interno / red), con dueño y fecha. La aprobación **no es transitiva a otro proyecto** |
| **Prohibidas** | AGPL-* en producto distribuido o SaaS, SSPL, ELv2, BUSL, RSALv2, PolyForm, FSL, FCL, MSCL, CC-*-NC-*, «sin licencia» | Rompe el build. Levantarlo exige excepción formal (§5.3) |

Estas listas **son un punto de partida y dependen de tu modelo de negocio**: si no distribuyes
software y no ofreces un servicio en red, AGPL puede ser perfectamente aceptable; si vendes un
producto instalado en casa del cliente, LGPL con enlace estático ya es un problema.
**Prohibición explícita: no copies estas tres listas sin declarar el modelo de distribución al
que aplican.** Una política de licencias sin un modelo de distribución declarado no se puede
aplicar, solo obedecer a ciegas.

### 5.2 Inventario

Se mantiene **por artefacto desplegable**, no por repositorio, y se deriva del SBOM: nombre,
versión, expresión SPDX **verificada** (no la del manifiesto), origen del dato (manifiesto /
texto escaneado / revisión manual), fecha de verificación, y **si es DOSP, la fecha de
conversión** (§3.1). Se regenera en cada *release*; un inventario mantenido a mano es un
inventario falso a los tres meses.

### 5.3 Excepciones

Nombre de la dependencia, **versión**, licencia, motivo, **alternativa evaluada y por qué se
descartó**, alcance (proyecto y modo de distribución concretos), aprobador, y **fecha de
caducidad obligatoria**. Sin caducidad no es una excepción, es un cambio de política por la
puerta de atrás. La **aceptación formal del riesgo residual** se registra donde manda
`grc-compliance-standards`; aquí vive el control técnico que la hace exigible.

### 5.4 Atribución: la obligación que casi nadie cumple

**Casi todas las licencias permisivas obligan a conservar el aviso de copyright y el texto de
la licencia al redistribuir.** Es la obligación más incumplida del sector, precisamente porque
es la más fácil: nadie audita un `THIRD-PARTY-NOTICES` hasta que lo audita un cliente grande.

- Se **genera en el build** desde el SBOM (ORT lo hace; también los generadores nativos) y se
  versiona con el artefacto.
- Se incluye **en el propio artefacto** cuando se distribuye: en la imagen, en el paquete, en
  el «Acerca de» de la aplicación. Un fichero en el repositorio no acompaña al binario.
- Apache-2.0: **el `NOTICE` de la dependencia se propaga**, no basta el texto de la licencia.
- Copyleft: además hay que ofrecer el **código fuente correspondiente** — con una oferta válida
  y un canal que exista de verdad. Una oferta escrita que apunta a un servidor apagado es un
  incumplimiento, no un formalismo.

### 5.5 SBOM: generarlo no es usarlo

**Generar un SBOM y no consumirlo es una casilla marcada, no un control.** El SBOM sirve si:
(a) el gate de licencias lo lee, (b) el triaje de CVEs lo lee
(`vulnerability-management-standards`), (c) la atribución se genera de él, y (d) puedes
responder «¿qué versiones desplegadas contienen el componente X?» en minutos. Si no lo
consumes en al menos (a) y (b), no lo generes todavía: arréglalo primero.

**Obligación regulatoria — Cyber Resilience Act (UE), Reglamento (UE) 2024/2847.** Fechas
verificadas (§8): entrada en vigor **10-dic-2024**; **11-jun-2026** aplicación del Capítulo IV
(notificación de organismos de evaluación de la conformidad); **11-sep-2026** aplicación de las
**obligaciones de notificación** —vulnerabilidades activamente explotadas e incidentes graves,
con alerta temprana en **24 h** y notificación en **72 h**, a través de la plataforma única de
ENISA (art. 16)—; **11-dic-2027** aplicación **plena**, incluidos requisitos esenciales,
evaluación de conformidad, documentación técnica, marcado CE y **SBOM**. La exigencia de SBOM
del Anexo I, Parte II, punto 1 requiere identificar y documentar los componentes «en un formato
de uso común y legible por máquina», **cubriendo al menos las dependencias de nivel superior**.
Sanciones de hasta **15 M€ o el 2,5 % de la facturación mundial anual**, la mayor.

**Consecuencia que la fecha oculta**: aunque el SBOM sea exigible en dic-2027, **desde sep-2026
tienes 24 horas para notificar una vulnerabilidad explotada**, y en 24 horas no se investiga a
mano qué componentes lleva un producto enviado hace tres años. **El SBOM es prerrequisito
operativo de la obligación de 2026, no de la de 2027.**

**EE. UU.**: la exigencia de SBOM en compra pública federal viene de la EO 14028 (2021) y su
desarrollo (guías NIST, *minimum elements* de NTIA, memorandos de la OMB sobre atestación del
proveedor). **Hueco: el estado exacto de estas órdenes y memorandos a ago-2026 no se ha
verificado en esta redacción — ver §8. No se cita ninguna fecha estadounidense aquí.**

**Regla de alcance, y es la frontera con la skill de vulnerabilidades:** el CRA es sobre todo
una obligación de **seguridad**; su gestión de riesgo, notificación y triaje pertenece a
`vulnerability-management-standards` y a `grc-compliance-standards`. Aquí queda **el SBOM como
artefacto: qué formato, cuándo se genera, de qué se genera y qué campos de licencia lleva**.

## 6. Ciclo de vida: relicencias, contribuciones y artefactos de IA

### 6.1 Contribuir hacia fuera

- **DCO** (`Signed-off-by:`, verificado en CI): el contribuyente certifica que tiene derecho a
  aportar. Sin cesión de derechos, sin fricción legal. **Default.**
- **CLA**: cede o licencia derechos al proyecto. Solo tiene un motivo real — **poder relicenciar
  después o vender excepciones propietarias**. Es legítimo, pero **exigir CLA y presentarse
  como comunitario sin explicar por qué es donde empieza la desconfianza**. Si lo pides, dilo.
- **Señal de riesgo para el consumidor**: un proyecto con CLA de cesión total **puede
  relicenciar mañana sin pedirle permiso a nadie**. No es motivo para descartarlo; es motivo
  para ponerlo en el radar de §6.2. Casi todas las relicencias de §3.6 ocurrieron en proyectos
  con CLA y un único propietario corporativo. **La combinación «un solo propietario corporativo
  + CLA de cesión» es el mejor predictor disponible de una relicencia futura.**
- **Trabajo del empleado y del contratista**: la titularidad depende del contrato y de la
  jurisdicción, y contribuir a un proyecto externo con cuenta personal desde el portátil de la
  empresa no la cambia por sí solo. **Que exista una política interna de contribución es
  requisito; su redacción es asunto de asesoría legal** (§1).

### 6.2 Cuando una dependencia relicencia bajo tus pies

Cuatro pasos, en orden, y ninguno es opcional:

1. **Detección.** El gate del grafo completo debe **comparar la licencia contra la registrada en
   el inventario** y alertar ante cualquier cambio, **aunque la nueva también esté permitida**.
   Detectar esto leyendo Hacker News es el estado por defecto del sector y no es un proceso.
2. **Evaluación de impacto.** Tres preguntas, y solo tres: ¿**distribuimos** el artefacto que la
   contiene? ¿La ofrecemos **en red**? ¿Superamos el **umbral** de la concesión gratuita
   —ingresos, empleados, número de repos, número de servidores— hoy **y en 18 meses**? Los
   umbrales de §3.6 (5 M$/50 empleados de Directus, ~25 M$ de Akka) son la parte que crece
   contigo: **una dependencia hoy gratuita puede dejar de serlo sin cambiar de versión, solo
   porque la empresa creció.** Añade el umbral al inventario junto a la versión.
3. **Decidir entre cuatro salidas** (y **no** la quinta, que es no decidir):
   - **Pagar la licencia comercial.** Es una opción legítima y a menudo la más barata. Sale más
     cara migrar por principios que pagar por una herramienta que funciona.
   - **Migrar a la bifurcación comunitaria.** Es una opción **real y probada**, no teórica:
     **OpenTofu** (Terraform→BUSL; en la CNCF desde abr-2025, mismos binarios de proveedor,
     compatibilidad total, y ya con funcionalidad divergente propia como el cifrado nativo de
     estado), **OpenBao** (Vault→BUSL; MPL-2.0, API compatible, adoptado por Nvidia),
     **Apache Pekko** (Akka→BSL; graduada en la ASF, **pero con incompatibilidad deliberada de
     paquetes, configuración y puertos — no es un cambio de coordenada Maven**), **Valkey**
     (Redis→RSALv2/SSPL, bajo la Linux Foundation), **OpenSearch** (Elasticsearch→SSPL/ELv2,
     transferida a la Linux Foundation), **Railroader** (Brakeman). **El mejor predictor de que
     una bifurcación sobreviva es que tenga casa neutral** (ASF, LF, CNCF); las que se quedan en
     el repositorio personal del bifurcador rara vez pasan del primer año.
   - **Sustituir por otra herramienta.** Coste alto y honesto.
   - **Fijar la última versión bajo la licencia antigua.** Es la única medida **temporal** de la
     lista y **exige fecha de caducidad en el ticket desde el minuto uno**. Deja de recibir
     parches de seguridad: **es una excepción de `vulnerability-management-standards` tanto
     como una de aquí**. Sin fecha, esta opción es la trampa: nadie vuelve a mirarla hasta que
     hay un CVE crítico sin parche disponible.
4. **Registrar la decisión** como ADR, con el análisis de los cuatro puntos. La relicencia se
   repetirá, y el siguiente equipo necesita saber por qué se eligió lo que se eligió.

**Y el reverso, que se olvida**: revisa también las **reversiones**. Elasticsearch (AGPL, 2024)
y Redis 8 (AGPL, 2025) volvieron a la OSD; el reloj DOSP de Akka ya devolvió versiones a
Apache-2.0. **Una prohibición basada en una relicencia de hace tres años puede estar
prohibiendo software que hoy es libre**, y eso también es un fallo de la política. Revisa la
lista de prohibidas al menos anualmente.

### 6.3 Modelos, datasets y contenido

- **Los pesos de un modelo casi nunca llegan bajo licencia OSI.** «Open weights» ≠ «open
  source». Llama, Gemma y similares llevan **licencias de comunidad con restricciones de uso y
  umbrales**; parte de la familia Qwen y las publicaciones MIT de DeepSeek sí alinean la
  licencia, pero con divulgación **parcial** de datos de entrenamiento. Un modelo se evalúa en
  **tres ejes independientes**: licencia de los pesos, licencia/procedencia del dataset, y
  términos de uso de la salida generada. **Los tres se registran en el inventario; los tres
  pueden ser distintos y normalmente lo son.**
- **La OSI publicó la Open Source AI Definition 1.0** (oct-2024), que exige código de
  entrenamiento e inferencia bajo licencia aprobada, parámetros bajo términos que permitan uso,
  estudio, modificación y redistribución, y **«data information»** suficiente para que una
  persona competente pueda recrear sustancialmente el sistema. **La discrepancia está viva y
  hay que declararla**: la OSAID **no exige publicar los datos de entrenamiento**, solo
  describirlos cuando no sean compartibles, y por eso la Software Freedom Conservancy sostiene
  que «erosiona el significado de open source» al no exigir reproducibilidad pública del
  proceso científico. **La OSI no certifica modelos individuales**: cualquier lista de
  «modelos conformes» es discusión, no registro. **Cita la OSAID como referencia y su crítica a
  la vez; no la presentes como consenso.**
- **Datasets**: licencias no-OSI (CC-BY-NC, «research only», términos de la fuente original) y
  procedencia frecuentemente opaca. **Un dataset sin licencia declarada no es un dataset
  permisivo; es un dataset sin licencia.**
- **Contenido**: la familia CC no es intercambiable. **CC-BY-NC-* no es libre** (criterio 6 de
  la OSD) y **CC-BY-SA es copyleft**. **CC0/CC-BY para documentación no es lo mismo que la
  licencia del código, y ambas se declaran por separado.**

### 6.4 Código generado por agentes

**La licencia y la titularidad del código generado por un modelo son una cuestión NO RESUELTA**,
y así queda declarada en `ai-agent-workflow-standards`. **Esta skill no inventa una respuesta**
y prohíbe que se afirme una. Lo que sí fija, porque es válido con cualquier respuesta futura:

- **Trazabilidad**: se declara en el commit que hubo generación asistida, según la convención de
  `git-workflow-standards`.
- **Verificación de procedencia**: un bloque de código que aparece completo y no se puede
  explicar **se verifica contra el original antes de fusionarse** — la comprobación es la misma
  que para copiar de Stack Overflow o de un repositorio, porque el riesgo es el mismo.
- **El gate de licencias se aplica igual**: si el agente añadió una dependencia, pasa por §4 sin
  trato especial.

## 7. Sostenibilidad y prohibiciones

**Cadencia**: gate en cada PR; escaneo profundo por *release*; **revisión de la política de las
tres listas y de las fechas DOSP, semestral**; revisión de excepciones caducadas, mensual;
regeneración del inventario, en cada *release*.

**Deprecación**: `deny-licenses` de `dependency-review-action` está deprecada — migrar a
`allow-licenses` **ahora**, no cuando la eliminen. Campos eliminados de `cargo-deny` (`deny`,
`copyleft`, `allow-osi-fsf-free`, `unlicensed`): migrados. Todo `deny.toml` o config de gate
sin revisar en más de un año se trata como no verificado.

**PROHIBIDO:**

- ❌ **Añadir una dependencia sin comprobar su licencia.** Sin excepción, sin «es solo para un
  prototipo» y sin «lo miramos luego». Los prototipos llegan a producción; las comprobaciones
  aplazadas, no.
- ❌ **Fiarse del campo `license` del manifiesto, del badge del README o del listado de un
  agregador.** Se lee el `LICENSE` de la versión concreta. Precedentes: Directus, Brakeman,
  WebPageTest, FlameGraph, Tolgee, Strapi (§3.6).
- ❌ **Asumir MIT por defecto.** «Está en npm/PyPI, será MIT» ha fallado ya trece veces
  documentadas en este catálogo. La ausencia de dato es dato desconocido, y lo desconocido se
  trata como prohibido (§4).
- ❌ **Usar AGPL en un SaaS —o en cualquier servicio accesible por red— sin decisión explícita,
  registrada y aprobada.** No es que esté prohibido: es que **no puede ocurrir por accidente**.
- ❌ **Copiar fragmentos de código sin verificar su procedencia** — de un blog, de Stack
  Overflow, de otro repositorio o de la salida de un modelo. Un fragmento sin origen conocido
  es un fragmento sin licencia conocida.
- ❌ **Tratar «desconocida», `NOASSERTION` o `LicenseRef-*` como aprobado provisionalmente.**
- ❌ **Usar una lista de licencias prohibidas en vez de una lista blanca.** Siempre falta una.
- ❌ **Aprobar una excepción sin fecha de caducidad**, o fijar una versión antigua por
  relicencia sin ticket con fecha.
- ❌ **Distribuir sin fichero de atribución generado**, o generarlo a mano.
- ❌ **Llamar «open source» a software con licencia no aprobada por la OSI** en documentación,
  marketing, README o respuesta a un cliente. *Source-available* y *fair source* tienen nombre
  propio; usarlos no es una concesión, es exactitud.
- ❌ **Publicar un repositorio sin fichero `LICENSE`** y suponer que «público» implica
  permiso de uso. No lo implica.
- ❌ **Reutilizar la aprobación de una dependencia en otro proyecto o en otro modo de
  distribución.** La aprobación es por dependencia **y por caso de uso**.
- ❌ **Generar un SBOM que nadie consume** y presentarlo como control de cumplimiento.
- ❌ **Emitir una conclusión jurídica.** Aquí se decide qué bloquea el build; la interpretación
  de la cláusula y el riesgo contractual son de asesoría legal (§1).

## 8. Verificación web obligatoria

Este dominio cambia por decisiones empresariales, no por ciclos técnicos: **una licencia puede
cambiar cualquier martes** y no hay *release notes* que lo anuncien con claridad.

**Comprobar siempre, antes de fijar nada:**

1. **El fichero `LICENSE` en crudo de la versión concreta** de cada dependencia que fijes, en el
   repositorio, y **también el de sus subdirectorios** (`ee/`, `enterprise/`, `pro/`). **Nunca
   el badge, el agregador ni el manifiesto.** Y **el artefacto distribuido puede diferir del
   fuente** (caso Elasticsearch).
2. **Estado de la OSD** (versión y fecha del documento) y de la **lista de licencias aprobadas**
   por la OSI. Qué licencias *source-available* / *fair-source* ha rechazado explícitamente y
   con qué palabras — **citar verbatim**.
3. **Estado de la Open Source AI Definition** (¿sigue en 1.0? ¿hay 1.1?) y del debate abierto.
4. **Versión vigente de la especificación SPDX y del listado**, por separado: a ago-2026 la
   spec publicada era **3.0.1** con **3.1 en RC** desde ene-2026, y el listado en **3.28.0**
   (feb-2026), con *builds* de previsualización posteriores. Verificar ambas.
5. **CRA**: confirmar las fechas de §5.5 contra el texto del Reglamento (UE) 2024/2847 y la
   guía práctica publicada por la Comisión (jul-2026), y el estado de las normas armonizadas y
   de la plataforma única de notificación de ENISA. **Citar el Anexo I verbatim si la exigencia
   concreta de SBOM importa para una decisión.**
6. **Estado de las bifurcaciones**: OpenTofu, OpenBao, Valkey, OpenSearch, Pekko, Railroader —
   ¿vivas, con casa neutral, con compatibilidad real? Y **relicencias y reversiones recientes**.
7. **Estado y licencia de las herramientas** que fijes: ScanCode, FOSSology, ORT, Syft, Trivy,
   `cargo-deny`, `reuse`, `dependency-review-action`, `licensee`. **Trivy ya cambió de licencia
   una vez** y `gitleaks` está *feature complete*: no des por buena ninguna.
8. **Umbrales de las concesiones gratuitas** (Directus, Akka, gitleaks-action y cualquier
   licencia con umbral): **cambian, y tu empresa también crece**.

**Huecos abiertos en esta redacción — no se rellenan sin verificar:**

- **Licencia de los binarios distribuidos por Elastic**: el fuente de Elasticsearch/Kibana es
  triple (AGPL-3.0 / SSPL / ELv2) desde 2024, pero hay indicios de que **las *releases*
  binarias siguen bajo Elastic License**. **No se afirma nada aquí**: verificar en el fichero
  de licencia del artefacto descargado antes de decidir.
- **Estado a ago-2026 de las órdenes ejecutivas y memorandos de EE. UU. sobre SBOM** (EO 14028
  y desarrollo posterior, *minimum elements* de NTIA/CISA, atestación de proveedor de la OMB):
  **no verificado en esta redacción. Ninguna fecha estadounidense citada. Verificar antes de
  usarlo en un compromiso contractual.**
- **Versión vigente de la especificación REUSE**: había **3.3** (nov-2024) y aparecen
  referencias del tooling a una **3.4** posterior. **Discrepancia declarada** — confirmar en
  `reuse.software` cuál es la publicada antes de fijarla en un `REUSE.toml`.
- **Umbral de ingresos de la BSL de Akka**: la cifra de ~25 M$ procede de fuentes de terceros,
  **no del texto de la Additional Use Grant**. Leer la concesión del proyecto.
- **Cifras de coste de licencias comerciales** (Synopsys/Brakeman, tiers de gitleaks-action,
  cuotas de la API de Infracost): **no se fija ninguna** — sin presupuesto verificado no se
  escribe un precio.

**Cuando una fuente se contradiga consigo misma** —el caso normal aquí: la portada dice «open
source» y el `LICENSE` dice otra cosa— **manda el `LICENSE`**, y se declara la contradicción en
el inventario para que el siguiente que mire no repita el trabajo.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
