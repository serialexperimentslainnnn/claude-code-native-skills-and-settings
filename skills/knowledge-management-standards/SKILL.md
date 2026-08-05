---
name: knowledge-management-standards
description: Documentation as infrastructure with a maintenance cost, for human readers. Use when deciding what to document and what to delete, applying the Diataxis framework (tutorial, how-to guide, reference, explanation) and splitting a document that mixes them, running docs-as-code with docs/ in the repository reviewed in the PR and built in CI, adding a broken-link gate with lychee or a prose linter with Vale, choosing or migrating a documentation stack (MkDocs Material, Docusaurus, Sphinx, Antora, Read the Docs, BookStack, Wiki.js, Outline, Confluence, Notion) and checking its licence and per-user price, generating reference from the source of truth (OpenAPI, JSON Schema, CLI --help, database schema) instead of writing it by hand, writing a README, a runbook nobody has executed, a design document, an onboarding guide or a postmortem write-up, setting a per-document owner and review-by date and deleting stale pages, fixing discoverability and search when three wikis exist, measuring bus factor and turning one person's undocumented knowledge into an artifact, using documentation as context for coding agents, or reviewing LLM-generated documentation that is plausible and wrong.
---

# Estándares de gestión del conocimiento y documentación

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**La documentación es infraestructura con coste de mantenimiento.** No es un entregable que se
termina: es un sistema que se degrada si nadie lo opera. De ahí la regla que gobierna el documento:
**la documentación que no se mantiene es peor que no tenerla, porque miente con autoridad**. Un
lector que no encuentra nada busca a una persona; un lector que encuentra un procedimiento obsoleto
lo ejecuta.

Consecuencia operativa inmediata: **crear un documento es asumir una obligación recurrente**. Si
nadie acepta el dueño y la fecha de revisión (§4.1), **no se escribe**. Y **borrar documentación
obsoleta es trabajo de mantenimiento, no pérdida de patrimonio**.

Cubre: el criterio de qué se documenta, Diátaxis como estructura por defecto, *docs as code*,
caducidad y propiedad, generación desde la fuente, los tipos de documento con plantilla y criterio
(README, runbook, postmortem, documento de diseño, guía de incorporación), el conocimiento no
escrito y el *bus factor*, búsqueda y descubribilidad, herramientas, y documentación en presencia de
LLM y agentes.

**Cobertura declarada**: **no existe una skill `technical-documentation` en el catálogo; esta la
cubre.**

**No aplica**:
- `ai-agent-workflow-standards` (**suyos** los ficheros de instrucciones del repositorio —
  `AGENTS.md`, `CLAUDE.md`, `.cursorrules`— y el trabajo con agentes de codificación; **aquí la
  documentación para personas**. Punto de contacto en §6.3: la documentación humana es contexto del
  agente, pero **no se escribe para el agente**).
- `claude-code-skills-standards` (**la autoría de skills es suya**: frontmatter, disparadores,
  activación).
- `code-review-standards` y `git-workflow-standards` (el diff, el mensaje de commit y su historia;
  **aquí que el cambio de comportamiento lleve el cambio de documentación en el mismo PR**).
- `incident-management-standards` (**el postmortem como proceso es suyo**: severidad, roles,
  acciones, seguimiento; **aquí su formato, dónde vive y cuánto se conserva**).
- `sre-practice-standards` (**el runbook operativo y su contenido son suyos**: qué alerta, qué
  comprobar, qué mitigar; **aquí el criterio de que exista, tenga dueño y esté probado** — §5.2).
- `itsm-itil-standards` (**la base de conocimiento del servicio y los errores conocidos son suyos**,
  con su ciclo de vida y su público de soporte).
- `technical-hiring-standards` (**Ola 6**: contratación y **la incorporación** de la persona; **aquí
  el artefacto de incorporación y su prueba**, §5.5).
- `api-design-standards` (**la documentación de la API se genera del contrato, que es suyo**: aquí
  solo la obligación de generarla y no reescribirla a mano).
- `i18n-standards` (documentación multilingüe: qué se traduce, cómo se sincroniza y qué pasa cuando
  la traducción se queda atrás).
- `software-architecture-patterns-standards` y `tech-leadership-standards` (**el criterio de
  decisión del ADR es suyo**; aquí que el ADR exista, sea inmutable y sea localizable).
- `enterprise-architecture-standards` y `product-discovery-standards`. **El paisaje decide qué
  sistemas existen; el descubrimiento, qué se construye; la documentación es lo que queda escrito de
  ambas decisiones.**

## 2. Decisiones por defecto

> Verificar versión, licencia y precio por web antes de fijarlo en un proyecto real (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Estructura | **Diátaxis** (tutorial / guía / referencia / explicación), CC BY-SA 4.0 (§2.1) | Estructura propia **escrita**, si el producto no encaja |
| Ubicación | **`docs/` en el mismo repositorio que el código** | Repositorio de documentación aparte solo para producto multi-repo |
| Formato | **Markdown** (o AsciiDoc si se necesita composición avanzada) | Nunca formato binario propietario para lo versionable |
| Revisión | **En el mismo PR que el cambio de comportamiento** | Ninguna |
| Publicación | **CI construye y despliega**; nadie sube a mano | — |
| Gate de CI | **Enlaces rotos rompen el build** (lychee, Apache-2.0/MIT) | — |
| Sitio | **MkDocs Material** (MIT) | **Docusaurus** (MIT) si hay React y versionado de docs; **Sphinx** (BSD 2 cláusulas) en Python; **Antora** para multi-repo AsciiDoc |
| Wiki no técnica | **BookStack** (MIT) autoalojado | Confluence si ya se paga y la empresa vive ahí (§2.3) |
| Referencia | **Generada de la fuente** (OpenAPI, JSON Schema, `--help`, esquema de BD) | Escrita a mano: **PROHIBIDO** si es generable (§4.3) |
| Estilo | **Vale** (MIT) con un estilo mínimo, en modo aviso antes que bloqueante | — |
| Dueño | **Persona por documento** + fecha de revisión en el frontmatter | Equipo con rotación nombrada |

### 2.1 Diátaxis: fuente, licencia y el error más común

- **Autoría**: **Daniele Procida**. Sitio: `diataxis.fr`; fuente en `github.com/evildmp/
  diataxis-documentation-framework`. **Licencia: CC BY-SA 4.0** (atribución + compartir igual).
  **Consecuencia práctica: aplicar el marco es libre; copiar o adaptar su texto en tu documentación
  arrastra atribución y ShareAlike sobre esa obra derivada.** Escribe el tuyo con tus palabras y
  enlaza la fuente. (Precedente del marco en el trabajo del autor durante su etapa en Divio,
  2014-2021, que él mismo matiza como parcialmente superado.)
- Los cuatro tipos y su prueba de pertenencia:

| Tipo | El lector… | Prueba de que está bien colocado |
|---|---|---|
| **Tutorial** | aprende haciendo, sin decidir nada | Si el lector debe elegir entre opciones, no es tutorial |
| **Guía (how-to)** | ya sabe qué quiere y busca los pasos | Si explica por qué, sobra ahí |
| **Referencia** | consulta un dato exacto | Si narra, no es referencia |
| **Explicación** | quiere entender el porqué | Si contiene pasos ejecutables, no es explicación |

- **El fallo más común es mezclar los cuatro en un documento**, y no es cuestión de estética: **cada
  tipo tiene un lector con una necesidad y un momento distintos**. Un tutorial con opciones y
  advertencias detiene al principiante; una referencia con narrativa obliga a leer tres párrafos
  para sacar un valor por defecto; una guía con teoría se abandona a mitad, y una explicación con
  comandos se ejecuta sin contexto. El resultado es un documento que **no sirve a ninguno de los
  cuatro** y que además caduca cuatro veces más rápido.
- **Regla de corte**: si un documento no se puede etiquetar con **uno** de los cuatro tipos, **se
  parte**. Se etiqueta en el frontmatter y se ordena la navegación por tipo.

### 2.2 Herramientas de sitio y wiki: licencias verificadas en crudo

| Herramienta | Licencia (verificada) | Nota que decide |
|---|---|---|
| **MkDocs Material** | **MIT** | Existe edición *Insiders* por patrocinio: funciones diferidas. Verificar qué necesitas antes de asumirlo |
| **Docusaurus** | **MIT** | Versionado e i18n de serie; arrastra tooling React |
| **Sphinx** | **BSD de 2 cláusulas** (verbatim en `LICENSE.rst`: *"all code in the Sphinx project is licenced under the two clause BSD licence"*) | Por defecto en Python; reStructuredText o MyST |
| **BookStack** | **MIT** | Wiki autoalojada, jerarquía estante/libro/capítulo/página |
| **Wiki.js** | **AGPL-3.0** | **La AGPL aplica al servicio ofrecido por red**: si se modifica, hay obligaciones → `opensource-licensing-standards` |
| **Outline** | **Business Source License 1.1** (licenciante General Outline, Inc.; *Additional Use Grant* que **prohíbe usarlo para prestar un "Document Service"**) | **No es open source**. Suposición habitual y equivocada; verificado en crudo |
| **Vale** | **MIT** — repositorio en `vale-cli/vale` | El antiguo `errata-ai/vale` **redirige**: el feed del repositorio antiguo no es la fuente |
| **lychee** | **Apache-2.0** (dual con MIT en el repositorio) | Comprobador de enlaces para el gate de CI |

### 2.3 Herramientas de pago: lo que hay y lo que no se puede afirmar

- **Confluence Cloud**: plan **gratuito limitado a 10 usuarios y 2 GB** en las fuentes consultadas;
  planes Standard y Premium de pago por usuario. **Discrepancia declarada: los rastreadores de
  terceros dan cifras distintas para el mismo plan** (Standard ~5,4 / ~6,05 / ~6,40 USD por usuario
  y mes; Premium ~10,4 / ~12,3), y varios mencionan **mínimo de facturación de 10 usuarios** y
  créditos de IA limitados. **No he verificado ninguna de esas cifras contra la página oficial de
  Atlassian: precio → hueco en §8.** No presupuestar con estos números.
- **Regla de compra**: la herramienta no es el problema. **Migrar de wiki no arregla documentación
  sin dueño**; solo cambia de sitio el desorden y añade una migración. Antes de comparar productos,
  comprobar que existen dueño, revisión y gate de CI (§4).

## 3. Qué se documenta y qué no

Criterio **coste-beneficio por lector y por vida útil**, aplicable documento a documento:

| Escribir siempre | Escribir con dueño y caducidad | **No escribir** |
|---|---|---|
| Por qué se tomó una decisión irreversible (ADR) | Guía de una tarea que se repite y no es obvia | Lo que el código ya dice (§7) |
| Cómo se arranca el proyecto desde cero (README) | Runbook de una alerta que pagina | Referencia generable a mano (§4.3) |
| Qué falló y qué se cambió (postmortem) | Incorporación de un rol concreto | Procedimiento de una interfaz en rediseño |
| Contrato de una interfaz entre equipos | Explicación de un concepto propio del dominio | Captura de pantalla de una UI que cambia (§7) |

Preguntas que deciden, en orden:

1. **¿Quién es el lector y qué está intentando hacer?** Sin lector identificable, no se escribe.
2. **¿Cuánto vive esto?** Un procedimiento que cambia cada dos semanas se automatiza o se pone en el
   código, no se documenta.
3. **¿Se puede generar desde la fuente?** Si sí, **se genera** (§4.3).
4. **¿Se puede eliminar la necesidad?** Un error con mensaje claro, un valor por defecto sensato o
   una comprobación automática eliminan páginas enteras. **La mejor documentación es la que deja de
   ser necesaria.**
5. **¿Cuántas personas lo leerán al año?** Un documento con un lector al año es una conversación,
   no un documento.

## 4. Docs as code, caducidad y generación

*(Sección 4 de la plantilla —calidad y testing— aplicada al dominio: aquí "el build" es la
documentación y los gates son sus controles de calidad.)*

### 4.1 Propiedad y caducidad: el problema real

- **Frontmatter obligatorio en cada documento**: `owner` (persona), `last_review` (fecha),
  `review_every` (periodo), `type` (tipo Diátaxis), `status` (`active` | `deprecated`).
- **Ciclo**: al vencer `last_review + review_every` se abre automáticamente una tarea al dueño. Sin
  respuesta en 30 días → el documento se marca **obsoleto de forma visible en la cabecera** (no se
  borra en silencio); a los 90 días se archiva.
- **Banner de obsolescencia > borrado inmediato**: el lector que llega por un enlace antiguo necesita
  saber que llegó tarde. **Un documento sin fecha visible se lee como vigente**: la fecha de última
  revisión se muestra al lector, no solo en el repositorio.
- **La documentación cambia en el mismo PR que el comportamiento.** Si el PR toca una interfaz, un
  flag, un procedimiento o un contrato y no toca `docs/`, el revisor lo dice
  (→ `code-review-standards`). **Documentar después es documentar nunca.**

### 4.2 Pipeline mínima (gates en orden de coste creciente)

1. **Build de la documentación**: si no compila, rompe.
2. **Enlaces rotos** (lychee o equivalente): **rompe el build**; enlaces externos con lista de
   excepciones y reintento, para no volver el gate inestable.
3. **Ejemplos de código ejecutables**: los fragmentos que se puedan probar se prueban (doctest,
   compilación del snippet). **Un ejemplo que no compila es un fallo, no una errata.**
4. **Lint de prosa** (Vale) con un estilo mínimo —términos prohibidos, nombres de producto,
   consistencia de mayúsculas—. **Aviso, no bloqueo**, salvo el vocabulario de marca. Un linter de
   prosa bloqueante convierte la documentación en un peaje y la gente deja de escribir.
5. **Vista previa por PR** (despliegue efímero): revisar Markdown en el diff no detecta la
   navegación rota.

### 4.3 Generar desde la fuente — **lo generado no miente**

- **Obligatorio generar, no escribir a mano**: referencia de API (del OpenAPI/proto → contrato de
  `api-design-standards`), opciones de CLI (de `--help`), esquemas y modelos de datos, variables de
  configuración, matriz de compatibilidad de versiones, índice de ADR.
- **Regla dura**: si un dato existe en el código o en un esquema, **la documentación lo referencia o
  lo genera; no lo copia.** Todo dato copiado a mano diverge; es cuestión de cuándo.
- Lo generado **no sustituye** a la explicación: una referencia generada dice *qué* hay; la
  explicación de *por qué* y *cuándo* la escribe una persona. **No generar tutoriales ni
  explicaciones de un esquema**: salen correctos y vacíos.
- El generador va **en CI**: si la documentación generada difiere de la comprometida, **rompe el
  build**.

## 5. Tipos de documento, plantilla y criterio

### 5.1 README

Responde exactamente a: **qué es esto (una frase), para quién, cómo se arranca desde cero, cómo se
prueba, dónde está el resto**. Reglas: **los comandos de arranque se ejecutan tal cual en una máquina
limpia** (si requieren tres pasos no escritos, el README está roto), enlaza y no duplica, y **cabe
en una pantalla**; lo demás va a `docs/`.

### 5.2 Runbook — **un runbook que no se ha ejecutado es ficción**

- Contenido y ámbito operativo → `sre-practice-standards`. **Aquí las condiciones de existencia**:
  dueño nombrado, fecha de última **ejecución** (no de última edición), y enlace desde la alerta que
  lo dispara.
- **Se prueba**: en un *game day*, en una prueba de restauración o en la primera incidencia real, y
  **quien lo ejecuta lo corrige en el momento**. Un runbook con más de 12 meses sin ejecutar se marca
  como no verificado en su cabecera.
- **PROHIBIDO** el runbook que empieza en "contacta con Fulano": eso es un teléfono, no un
  procedimiento.

### 5.3 ADR y documento de diseño

- **El criterio de cuándo hace falta un ADR y cómo se decide es de
  `software-architecture-patterns-standards` y `tech-leadership-standards`.** Aquí: **inmutabilidad**
  (un ADR no se edita: se supersede con otro que lo referencia), numeración estable, ubicación fija
  (`docs/adr/`), índice generado, y **estado explícito** (propuesto / aceptado / sustituido).
- Documento de diseño: es **pre-decisión** y **caduca al implementarse**. Al cerrarse, o se convierte
  en ADR + documentación viva, o **se archiva marcado como histórico**. Un documento de diseño que
  se queda como "la documentación del sistema" es la causa más común de documentación que miente.

### 5.4 Postmortem

- **El proceso es de `incident-management-standards`.** Aquí: **formato estable y conservación**.
  Secciones fijas —impacto con cifras, cronología con horas, factores contribuyentes, qué funcionó,
  acciones con dueño y fecha—, **sin nombres de personas asociados a la culpa**, y **público dentro
  de la organización por defecto**: un postmortem que solo ve el equipo afectado no enseña nada a
  nadie.
- **Se conservan indefinidamente y se indexan**: su valor es que alguien encuentre dentro de tres
  años el incidente parecido. Un postmortem no localizable es esfuerzo tirado.

### 5.5 Guía de incorporación

- **Se valida ejecutándola**: **la siguiente persona que entra la sigue desde cero y corrige lo que
  falla, en el mismo día**; ese es su mantenimiento. Nadie más la revisa.
- Métrica falsable: **tiempo hasta el primer cambio en producción** de la persona nueva. Si sube
  entre incorporaciones, la guía está caducando.
- **PROHIBIDO** dar acceso "cuando lo pida": la lista de accesos por rol es parte de la guía y se
  tramita antes del primer día (→ `identity-access-management-standards`).

### 5.6 El conocimiento que no está escrito

- **Bus factor**: número de personas que pueden desaparecer antes de que un sistema quede sin nadie
  que lo entienda. **Bus factor 1 en un sistema crítico es un riesgo operativo**, se registra como
  tal (riesgo con dueño, no anécdota) y se ataca.
- Cómo se convierte en artefacto, en orden de eficacia:
  1. **Que la persona única no sea quien lo escriba sola**: alguien más ejecuta el procedimiento
     mientras el experto observa; **quien no sabe redacta**, porque el experto omite lo que le parece
     obvio —y lo obvio es justo lo que falta.
  2. **Rotación de guardia y de tareas**: la rotación es un mecanismo de documentación, no solo de
     descanso.
  3. **Pair / mob en el área concentrada**, acotado y con objetivo escrito.
  4. **Documentación dentro de la definición de hecho** del trabajo que toca el área.
- **No funciona**: pedirle a la persona única "que documente todo" en una semana antes de irse. Se
  obtiene un volcado sin lector, imposible de mantener y que caduca en el primer cambio.

## 6. Descubribilidad, y documentación en presencia de IA

### 6.1 **La documentación que no se encuentra no existe**

- Cuando hay volumen, **el problema deja de ser escribir y pasa a ser encontrar**. Señal de alarma:
  la gente pregunta en el chat algo que está documentado. **Eso no es pereza del lector: es un fallo
  de búsqueda**, y se trata como un fallo.
- **El coste de tener tres wikis**: nadie sabe cuál manda, la búsqueda devuelve tres versiones
  distintas, la más antigua suele estar mejor posicionada y **el lector deja de confiar en todas**.
  Regla: **un destino canónico por tipo de contenido** (código→repo, operación→runbooks,
  proceso→wiki corporativa) y **redirecciones desde los demás**; nunca copias.
- **Taxonomía mínima**: producto/servicio, tipo Diátaxis, estado. **Tres ejes y ninguno libre.**
  Una taxonomía con quince etiquetas libres se vuelve ruido en un trimestre.
- **Buscar antes que estructurar**: la búsqueda a texto completo con buenos títulos gana a cualquier
  jerarquía. **El título es el 80 % de la búsqueda**: se escribe con las palabras que usaría quien
  busca, no con las del autor.
- Consolidación: **la única migración que merece la pena es la que borra**. Migrar 4 000 páginas a
  una herramienta nueva sin podar es pagar dos veces por el mismo desorden.

### 6.2 Métricas (ninguna cuenta páginas)

| Métrica | Señal |
|---|---|
| % de documentos con dueño y revisión vigente | Salud del sistema |
| Páginas nunca visitadas en 12 meses | Candidatas a borrar |
| Preguntas en chat resueltas con un enlace existente | Fallo de descubribilidad (§6.1) |
| Tiempo hasta el primer cambio en producción de una persona nueva | Calidad de la incorporación |
| Runbooks ejecutados en los últimos 12 meses / total | Ficción operativa |
| Antigüedad mediana de los documentos **consultados** | Si lo vivo está actualizado |

**PROHIBIDA** la métrica "número de páginas creadas": premia exactamente el fallo de §1.

### 6.3 IA y documentación

- **La documentación es contexto para agentes de codificación.** Consecuencia práctica: un
  `docs/` limpio, con títulos explícitos y sin contradicciones, mejora el trabajo del agente; una
  wiki con tres versiones de la misma verdad lo empeora, porque **el agente no puede saber cuál está
  vigente y elegirá una**. Los ficheros de instrucciones del repositorio (`AGENTS.md`, `CLAUDE.md`) y
  su gobierno son de `ai-agent-workflow-standards`: **aquí no se duplican**. La única regla propia:
  **el fichero de instrucciones enlaza a la documentación canónica; no la reescribe**, o habrá dos
  fuentes divergentes.
- **Generación con LLM: revisión humana obligatoria y con nombre.** Un texto generado se publica solo
  si una persona **con conocimiento del sistema** lo ha verificado línea a línea contra la fuente.
  **Quien pulsa "aprobar" es el autor a todos los efectos** (misma regla de responsabilidad que un
  diff generado, → `ai-agent-workflow-standards`, `code-review-standards`).
- **El riesgo específico es la documentación plausible y falsa a escala.** Es distinta de la
  documentación caducada: está bien escrita, bien estructurada, es coherente y **describe un sistema
  que no existe** —una opción que no está, un flag con otro nombre, un comportamiento por defecto
  inventado—. **Es más creíble que la buena** y sobrevive a la revisión superficial. Reglas:
  - Generar **preferentemente lo verificable**: guías con comandos que se ejecutan en CI (§4.2),
    resúmenes de contenido existente que se pueden contrastar.
  - **PROHIBIDO** generar referencia (opciones, parámetros, valores por defecto): eso se genera de la
    fuente, que sí es autoridad (§4.3).
  - **Prohibido publicar en lote**: si el volumen generado supera lo que un humano puede verificar,
    ese es el límite del lote.
  - **Marcar el origen** en el frontmatter (`generated_by`, `reviewed_by`) para poder auditar después
    qué se generó cuando aparezca el primer error sistemático.
- **La IA no arregla la documentación sin dueño**: acelera su producción, que es exactamente la
  parte barata. El coste está en el mantenimiento, y ese no baja solo.

## 7. Sostenibilidad a largo plazo y prohibiciones

- **Poda con cadencia**: revisión semestral de páginas no visitadas y de documentos vencidos. **Una
  campaña de borrado al año es un síntoma; el mantenimiento continuo es la cura.**
- **Migraciones**: solo con inventario previo, poda antes de mover y **redirecciones desde las URL
  antiguas**. Enlaces rotos masivos destruyen la confianza más rápido que la documentación obsoleta.
- **Deprecación de un documento**: banner visible con enlace al sustituto y fecha de archivado; nunca
  el borrado silencioso.
- Prohibiciones:
  - ❌ **Documentar lo que el código ya dice** (comentar getters, describir la firma que la firma ya
    declara, "esta función suma dos números"). Duplica la verdad y caduca al primer refactor.
  - ❌ **Wiki sin dueño.** Un espacio compartido de todos es de nadie, y su vida media es un año.
  - ❌ **Captura de pantalla como documentación de una interfaz que cambia.** Caduca en silencio y
    nadie la revisa. Se describe la acción; la captura solo para lo que no cambia o para explicar
    un concepto visual.
  - ❌ **Documentación de incorporación que nadie ejecuta desde cero** (§5.5).
  - ❌ **Runbook nunca ejecutado presentado como procedimiento válido** (§5.2).
  - ❌ **Documento sin dueño ni fecha de revisión** (§4.1).
  - ❌ **Copiar a mano un dato que existe en un esquema, un contrato o un `--help`** (§4.3).
  - ❌ **Dos fuentes canónicas del mismo tema.** Una manda y la otra redirige.
  - ❌ **Publicar documentación generada por LLM sin revisor humano con nombre** (§6.3).
  - ❌ **Editar un ADR ya aceptado** en lugar de sustituirlo (§5.3).
  - ❌ **Medir la documentación por número de páginas** (§6.2).
  - ❌ **Mezclar los cuatro tipos de Diátaxis en un documento** (§2.1).
  - ❌ **Copiar texto de Diátaxis (o de cualquier fuente CC BY-SA) sin atribución y sin asumir
    ShareAlike** en la obra derivada.

## 8. Verificación web obligatoria

Comprobar antes de fijar nada:

1. **Diátaxis**: autoría (Daniele Procida), sitio `diataxis.fr`, repositorio `evildmp/
   diataxis-documentation-framework` y **licencia CC BY-SA 4.0**. Re-verificar la licencia antes de
   reutilizar texto: condiciona tu obra derivada.
2. **Licencias de herramientas** — verificadas en crudo a ago-2026: MkDocs Material **MIT**,
   Docusaurus **MIT**, BookStack **MIT**, Wiki.js **AGPL-3.0**, Vale **MIT** (repositorio actual
   `vale-cli/vale`; el antiguo `errata-ai/vale` **redirige** — el feed del repositorio antiguo no es
   la fuente de verdad), lychee **Apache-2.0/MIT**, Sphinx **BSD 2 cláusulas** (verbatim en
   `LICENSE.rst`), **Outline: BUSL-1.1 con restricción de "Document Service" — no es open source**.
   Re-leer el `LICENSE` en crudo antes de fijar cualquiera: cambian.
3. **Precios** → **hueco declarado**: Confluence Cloud (plan gratuito limitado a 10 usuarios / 2 GB
   según fuentes secundarias; **cifras de Standard y Premium discrepantes entre rastreadores y no
   verificadas contra Atlassian**), Notion y Read the Docs. **Consultar la página oficial del
   fabricante antes de presupuestar; no usar las cifras de terceros de este documento.**
4. **MkDocs Material Insiders**: qué funciones están tras patrocinio en el momento de decidir.
5. **Generadores**: versiones y compatibilidad de OpenAPI/Sphinx/Antora antes de fijar la cadena de
   generación.
6. **Cifras sobre documentación** ("los desarrolladores pierden X % de su tiempo buscando
   información", "el Y % de la documentación está obsoleta"): **no se usan sin estudio primario y
   metodología accesible**. No he localizado ninguno fiable para este dominio: **hueco declarado**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
