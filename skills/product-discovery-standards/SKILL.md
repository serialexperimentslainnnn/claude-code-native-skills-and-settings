---
name: product-discovery-standards
description: Reducing the risk of building something nobody needs, before it is built. Use when deciding how much discovery a decision deserves and whether it is reversible, addressing the four product risks (value, usability, feasibility, business viability) from Marty Cagan and SVPG, running customer interviews about past behaviour instead of future intent, building an opportunity solution tree (Teresa Torres, Continuous Discovery Habits) to trace a solution back to an outcome, writing a problem statement behind a requested feature, choosing an experiment (paper or clickable prototype, smoke test, fake door, concierge, Wizard of Oz) and its ethical and privacy limits, designing an A/B or online controlled experiment with a minimum detectable effect, power and sample-size calculation and duration fixed in advance, one primary metric plus guardrails, sample ratio mismatch checks, the peeking problem and always-valid or sequential inference, multiple-comparison correction, deciding when an A/B test is impossible (low traffic, network effects, structural change), separating outcome metrics from activity and vanity metrics, applying Goodhart's law to a target, using HEART or AARRR metric frameworks, running dual-track discovery alongside delivery, killing an idea as a successful outcome, or doing discovery for an internal product or platform with captive users.
---

# Estándares de descubrimiento de producto

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**El descubrimiento existe para reducir el riesgo de construir lo que nadie necesita.** Criterio de
existencia, aplicable el lunes: **si al terminar una actividad de descubrimiento no ha cambiado
ninguna decisión —ni el alcance, ni el orden, ni el "no lo hacemos"—, no era descubrimiento, era
teatro.** Un descubrimiento cuyo resultado posible es solo "seguimos adelante" no es un experimento:
es una ceremonia de aprobación.

Corolario que gobierna todo lo demás: **la decisión de matar una idea es el resultado más valioso
del proceso** (§6.3), y una función de descubrimiento que nunca mata nada está midiendo su propio
consenso.

Cubre: los cuatro riesgos de producto, el criterio de cuánto descubrimiento merece una decisión,
entrevistas de comportamiento, oportunidades y soluciones (árbol de oportunidades), experimentos sin
construir (prototipos, humo, concierge, mago de Oz) y su límite ético, experimentación cuantitativa
(A/B con potencia, muestra y duración fijadas antes), métricas de resultado frente a actividad,
Goodhart, dual track, y descubrimiento en producto interno.

**No aplica**:
- `project-management-standards` (**frontera limpia**: **qué se construye y por qué es de aquí; cómo
  se entrega —plan, dependencias, riesgo de ejecución, informe de estado— es suyo**).
- `analytics-bi-standards` (**suyos** el cuadro de mando, la **definición canónica de cada métrica**
  y quién decide con ella; **aquí** qué métrica merece existir y qué decisión cuelga de ella. Si una
  métrica de este documento no está definida allí, no es una métrica: es una opinión con número).
- `llm-evaluation-standards` (**la medición de un sistema no determinista es suya**: el A/B de §5 no
  aplica tal cual cuando la variante es un modelo generativo).
- `data-governance-quality-standards` (calidad, linaje y contratos del dato con el que se decide).
- `privacy-engineering-standards` (**precondición dura, no consejo**: la **base legal** del
  tratamiento de datos de usuarios en un experimento —incluidos *fake door*, concierge y mago de
  Oz— se decide con sus reglas **antes** de lanzar. Sin base legal no hay experimento, por bueno que
  sea el aprendizaje).
- `accessibility-standards` (**la conformidad no se somete a prueba A/B**: WCAG es requisito, no
  hipótesis; una variante que degrada accesibilidad se descarta aunque gane en conversión).
- `platform-engineering-standards` (**recíproca**: una plataforma interna es un producto con
  clientes que pueden no usarla; **el descubrimiento de sus necesidades se hace aquí** y su gobierno
  de adopción, allí).
- `tech-leadership-standards` (quién decide, registro de decisión y presupuesto).
- `web-performance-standards` (**el efecto medido del rendimiento sobre conversión es su territorio
  de datos**; aquí solo el diseño del experimento que lo mide).
- `enterprise-architecture-standards` y `knowledge-management-standards`. **El paisaje decide qué
  sistemas existen; el descubrimiento, qué se construye; la documentación es lo que queda escrito de
  ambas decisiones.**

## 2. Decisiones por defecto

> Verificar autoría, versión y fuente por web antes de citarlas en un documento formal (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Taxonomía de riesgo | **Cuatro riesgos**: valor, usabilidad, factibilidad, viabilidad de negocio (SVPG / Marty Cagan) | Ninguna; ampliarla exige justificar qué riesgo no cubre |
| Esfuerzo de descubrimiento | **Proporcional a la irreversibilidad y al coste** (§3.1) | Ninguna |
| Fuente primaria | **Entrevista sobre comportamiento pasado**, continua | Analítica de uso cuando la pregunta es "cuánto", no "por qué" |
| Encuesta | **Solo para dimensionar algo ya observado** | Nunca como sustituto de observación (§7) |
| Trazabilidad | **Árbol de oportunidades** (resultado → oportunidad → solución → experimento) | Cualquier trazado explícito equivalente, escrito |
| Prototipo | **La menor fidelidad que responda a la pregunta** | Alta fidelidad solo para riesgo de usabilidad |
| Cuantitativo | **A/B con muestra, potencia y duración fijadas antes** | Inferencia secuencial / *always-valid* **si se decide antes** (§5.3) |
| Métrica de éxito | **Una primaria de resultado + guardarraíles** | Nunca dos primarias |
| Cadencia | **Dual track continuo** | Ninguna: el descubrimiento no es una fase previa (§6.1) |
| Resultado admisible | **Incluye "no se construye"** | Ninguna |

### 2.1 Los cuatro riesgos y su origen

- Formulación de referencia: **Silicon Valley Product Group / Marty Cagan, ensayo *The Four Big
  Risks*** (`svpg.com/four-big-risks/`) y ***INSPIRED*, 2.ª edición**. Evolución declarada por el
  propio autor: la 1.ª edición usaba tres atributos (valioso, usable, factible) y **el valor se
  partió después en *valor* y *viabilidad de negocio*** porque la viabilidad quedaba sistemáticamente
  ignorada.
  - **Valor**: el cliente no lo comprará o el usuario no lo elegirá.
  - **Usabilidad**: el usuario no sabrá usarlo.
  - **Factibilidad**: no se puede construir con el tiempo, las capacidades y la tecnología disponibles.
  - **Viabilidad de negocio**: el resto de la organización —legal, finanzas, ventas, marketing,
    marca— no puede sostenerlo.
- **Cautela de cita**: la frase corta que circula ("Before we build, we must address four big
  risks…") **no aparece verbatim** en el ensayo consultado; es paráfrasis. **Citar el ensayo y el
  libro, no la frase.** El autor ha usado también "deseabilidad" en lugar de "valor" — si se cita,
  decir qué versión.
- **Regla operativa**: los cuatro se abordan **antes de construir**, y **el riesgo que más se salta
  es el de viabilidad de negocio** porque no tiene dueño natural en el equipo técnico. Ponerle dueño
  con nombre es parte del diseño del proceso, no un detalle.

## 3. Cuánto descubrimiento, y sobre qué

### 3.1 El criterio de esfuerzo: reversibilidad × coste

| Situación | Descubrimiento proporcionado |
|---|---|
| Reversible y barato (flag, texto, orden de una lista) | **Ninguno previo: se lanza y se mide.** Discutirlo en reunión cuesta más que probarlo |
| Reversible y caro (funcionalidad de un sprint) | Entrevistas + prototipo + criterio de éxito escrito antes |
| **Irreversible** (migración de datos, contrato plurianual, cambio de modelo de precio, API pública) | Descubrimiento formal: experimento con hipótesis, alternativa evaluada y decisión registrada (ADR / registro de decisión → `tech-leadership-standards`) |
| Regulatorio o de accesibilidad | **No se descubre: se cumple.** No es una hipótesis |

**Regla antiparálisis**: el coste del descubrimiento no puede superar el coste de equivocarse y
rectificar. Si construir el experimento cuesta más que construir la funcionalidad, **se construye la
funcionalidad detrás de un flag y se mide**.

### 3.2 Entrevistas: comportamiento pasado, no intención futura

- **"¿Usarías esto?" no aporta información** y su respuesta es sistemáticamente positiva: el
  entrevistado responde por cortesía, por imaginación y sin coste. Una respuesta que no puede ser
  "no" no es un dato.
- Se pregunta por **hechos con fecha**: *"cuéntame la última vez que tuviste que hacer X"*, *"¿qué
  hiciste exactamente?"*, *"¿cuánto tardaste?"*, *"¿qué usaste en su lugar?"*, *"¿qué pasó
  después?"*. La historia concreta contiene comportamiento; la opinión contiene deseo de agradar.
- **PROHIBIDO en una entrevista**: describir la solución antes de entender el problema, preguntar en
  hipotético, preguntar por precio en abstracto ("¿pagarías 20 €?"), y encadenar preguntas cerradas.
- Reglas de proceso: **cadencia semanal** (una entrevista semanal sostenida vale más que veinte en
  un mes muerto), **asisten las tres cabezas** (producto, diseño, ingeniería) porque el aprendizaje
  de segunda mano no cambia decisiones, y **las notas se guardan enlazadas a la oportunidad**
  (`knowledge-management-standards`).
- **Sesgo de reclutamiento**: entrevistar solo a los clientes que responden al correo produce el
  producto que quieren los clientes que responden al correo. **Los que se fueron y los que nunca
  entraron son la muestra que falta**, y su ausencia se declara.

### 3.3 Oportunidad y solución: el árbol como trazabilidad

- **Árbol de oportunidades** (*opportunity solution tree*): **Teresa Torres**, formulado en **2016**
  y desarrollado en ***Continuous Discovery Habits*** (2021, ISBN 978-1736633304); raíz intelectual
  reconocida en el trabajo de Bernie Roth (Stanford) sobre conectar soluciones deseadas con
  necesidades subyacentes. Estructura: **resultado → oportunidades → soluciones → experimentos**.
- Uso real, no decorativo: **toda solución en la hoja de ruta cuelga de una oportunidad, y toda
  oportunidad de un resultado medible.** Una solución que no cuelga de nada es una petición, no una
  decisión.
- **La trampa de la lista de funcionalidades sin problema detrás**: un backlog es una lista de
  soluciones; sin la oportunidad asociada no se puede priorizar (no hay con qué comparar), no se
  puede matar (no hay criterio) y no se puede sustituir por algo más barato que resuelva lo mismo.
  **Regla: cada elemento de la hoja de ruta lleva escrita en una frase la oportunidad que ataca y
  cómo se sabrá si la resolvió.** Sin esa frase no entra.
- **Comparar soluciones alternativas para la misma oportunidad es obligatorio**: una única opción
  evaluada no es una decisión, es una justificación.

## 4. Experimentos cualitativos y su límite ético

*(Sección 4 de la plantilla —calidad y testing— reinterpretada: el equivalente aquí es qué se puede
aprender sin construir y bajo qué condiciones el aprendizaje es legítimo.)*

| Técnica | Qué riesgo ataca | Qué **no** demuestra |
|---|---|---|
| Prototipo en papel / baja fidelidad | Usabilidad y comprensión del concepto | Que alguien lo usaría de verdad |
| Prototipo clicable de alta fidelidad | Usabilidad fina, flujo | Valor |
| **Prueba de humo / *fake door*** (anuncio o botón de algo que aún no existe) | **Valor**: intención revelada con coste | Retención ni disposición a pagar |
| Página de destino con lista de espera | Valor y mensaje | Uso |
| **Concierge** (el servicio se presta manualmente, el usuario lo sabe) | Valor y viabilidad operativa | Escalabilidad ni coste unitario a escala |
| **Mago de Oz** (parece automático, detrás hay personas) | Valor de la automatización antes de automatizarla | Factibilidad técnica |
| Prototipo técnico / *spike* | **Factibilidad** | Valor |

**Límites duros, no recomendaciones:**

- **No se engaña al usuario sobre el tratamiento de sus datos.** En concierge y mago de Oz **hay
  personas leyendo contenido del usuario**: eso es un tratamiento que debe tener base legal,
  información al interesado y control de acceso → `privacy-engineering-standards`. **La simulación
  puede ocultar la implementación; nunca quién ve los datos.**
- **Fake door**: el usuario que pulsa un botón de algo inexistente merece una respuesta honesta
  inmediata ("aún no está disponible") y **no debe pagar, ni perder trabajo, ni quedar en un estado
  inconsistente**. Un fake door en un flujo de compra o en un flujo crítico está **PROHIBIDO**.
- Un experimento que solo funciona si el usuario no se entera **no se lanza**. Prueba: si tuvieras
  que explicarlo después en público, ¿lo defenderías?
- Datos personales recogidos "por si acaso" en un experimento: **PROHIBIDO** (minimización).

## 5. Experimentación cuantitativa

### 5.1 Lo que se fija **antes** de lanzar (y se escribe)

1. **Hipótesis** en forma falsable: qué cambia, en qué métrica, en qué dirección, y **qué resultado
   haría que se descartase**.
2. **Una métrica primaria** de resultado. **Dos primarias = ninguna**, porque siempre habrá una que
   gane.
3. **Guardarraíles** que pueden matar el experimento aunque la primaria gane: errores, latencia
   (`web-performance-standards`), accesibilidad, reclamaciones, coste unitario (`finops-standards`).
4. **MDE** (efecto mínimo detectable) **decidido por su relevancia de negocio**, no por lo que salga
   significativo: ¿qué mejora justifica el coste de mantener este cambio para siempre?
5. **Cálculo de potencia y tamaño de muestra** con ese MDE (potencia 80 % y α 0,05 como punto de
   partida; se declara si se cambian).
6. **Duración fijada antes**, y **nunca menor a un ciclo semanal completo** (el comportamiento de
   lunes no es el de sábado). Si la muestra se alcanza en dos días, se completa la semana igual.
7. **Regla de decisión escrita**: qué se hace si gana, si pierde y si no es concluyente. **"No
   concluyente" es un resultado, y su acción por defecto es no lanzar.**

### 5.2 Validez: lo que invalida un resultado

- **Sample Ratio Mismatch (SRM)**: si el reparto observado se desvía del diseñado de forma
  estadísticamente improbable, **el experimento no se analiza, se depura**. Kohavi documenta el caso
  de 821 588 vs. 815 482 usuarios (50,2 % frente a 50,0 %) con p ≈ 1,8e-6 → resultado descartado.
  **Comprobación de SRM obligatoria antes de mirar la métrica primaria**, y sobre la unidad de
  aleatorización (no sobre páginas vistas ni sesiones). Referencias: Fabijan et al., *Diagnosing
  Sample Ratio Mismatch in Online Controlled Experiments*, KDD '19; Kohavi, Tang & Xu, *Trustworthy
  Online Controlled Experiments*, cap. 21.
- **Contaminación**: mismo usuario en ambas ramas (multi-dispositivo, caché, sesión anónima → login).
- **Efecto novedad y efecto primacía**: el pico de la primera semana no es el efecto.
- **Segmentación posterior sin corrección**: buscar el segmento donde el resultado sale bien es
  fabricar significancia (§5.4).

### 5.3 El *peeking* — **prohibido parar al ver significancia**

- Mirar repetidamente un test diseñado como muestra fija y parar en cuanto cruza el umbral **produce
  falsos positivos de forma sistemática**: reaplicar ingenuamente pruebas convencionales en cada
  instante acaba detectando un efecto aunque no exista (Johari, Koomen, Pekelis & Walsh, *Peeking at
  A/B Tests*, KDD '17; versión ampliada en *Operations Research*, 2021).
- **Regla**: con diseño de muestra fija, **el resultado se lee una vez, al alcanzar la muestra y la
  duración planificadas**. Punto.
- **Si se necesita mirar antes**, se decide **antes de lanzar** usar **inferencia secuencial /
  *always-valid*** (p-valores siempre válidos, mSPRT, *alpha spending*). No es gratis: **se paga en
  potencia**, y detectar efectos pequeños se vuelve más difícil. Cambiar de método a mitad del test
  invalida ambos.
- **Excepción legítima y única**: parada temprana por **daño** (guardarraíl roto, error, pérdida de
  ingresos). Se define el umbral de daño antes y se monitoriza solo eso.

### 5.4 Comparaciones múltiples

- Un test con una primaria y muchas métricas secundarias **producirá secundarias "significativas"
  por azar**: con α=0,05 y 20 métricas independientes, se espera una falsa por test.
- **Regla**: la decisión cuelga **solo** de la primaria. Las secundarias son generadoras de
  hipótesis, y **al analizarlas se aplica corrección** (Bonferroni si son pocas y la decisión es
  crítica; control de FDR tipo Benjamini-Hochberg si son muchas y exploratorias). **Declarar cuál se
  usó.**
- Lo mismo para variantes: un A/B/C/D es un problema de comparaciones múltiples, no cuatro tests.

### 5.5 Cuándo **no** se puede hacer un A/B test

- **Tráfico insuficiente**: si el cálculo de §5.1 da una duración mayor que el horizonte de la
  decisión (p. ej. > 6-8 semanas), el test no existe. Alternativas: medir un cambio mayor, usar una
  métrica más sensible aguas arriba, o decidir con cualitativo y asumirlo por escrito.
- **Efectos de red / mercados de dos lados**: la rama de control se contamina por la de tratamiento
  (marketplaces, mensajería, redes sociales). Alternativas: aleatorización por *cluster* (ciudad,
  equipo, cohorte) o experimentos por *switchback*, ambos con menos potencia y más supuestos.
- **Cambios estructurales**: rediseño completo, cambio de precios, migración de plataforma. El
  efecto medido a corto plazo será dominado por la sorpresa, no por el valor. Alternativas: lanzado
  progresivo con vigilancia de guardarraíles, cohortes en el tiempo, mercados de prueba.
- **Poblaciones pequeñas y cautivas** (producto interno, B2B con 40 clientes): **no hay test**; hay
  entrevistas, pilotos y adopción observada (§6.4).
- **Cuestiones normativas o de accesibilidad**: no se testean.
- **Cuando no se puede testear, la regla es declarar la incertidumbre y hacer el cambio reversible**
  (flag, plan de reversión), no fingir rigor con un test infrapotenciado. **Un test sin potencia no
  es evidencia débil: es ruido con apariencia de dato.**

## 6. Métricas, cadencia y contextos sin usuarios externos

### 6.1 Resultado, actividad y vanidad

| Tipo | Ejemplo | Qué le pasa cuando se convierte en objetivo |
|---|---|---|
| **Resultado** (comportamiento del cliente o efecto de negocio) | Tareas completadas por semana, retención a 30 días, tiempo hasta el primer valor | Es la única defendible; aun así requiere guardarraíles |
| **Actividad** (lo que hace el equipo) | Funcionalidades entregadas, historias cerradas, experimentos lanzados | Se infla trivialmente; no dice nada del usuario |
| **Vanidad** (crece siempre y no decide nada) | Usuarios registrados acumulados, descargas totales, páginas vistas | Nunca baja, así que nunca desmiente nada |

**Prueba de la métrica**: *¿qué decisión distinta tomaríamos si este número cayera un 20 %?* Sin
respuesta concreta, la métrica no se publica.

### 6.2 Ley de Goodhart, con su formulación original

- **Original (Charles Goodhart, 1975)**: *"Any observed statistical regularity will tend to collapse
  once pressure is placed upon it for control purposes."* (contexto: política monetaria del Reino
  Unido; recogido también en *Monetary Theory and Practice*).
- **Corrección frecuente**: la versión popular *"When a measure becomes a target, it ceases to be a
  good measure"* **no es de Goodhart**: se debe a **Marilyn Strathern (1997)**, citando la
  formulación de Keith Hoskin (1996). Si se cita la frase corta, se atribuye a Strathern. Emparentada
  con la **ley de Campbell** (formulaciones desde 1969), que probablemente le precede.
- **Uso operativo, no cita ornamental**: (a) **toda métrica primaria lleva guardarraíles** que
  detecten su forma barata de subir; (b) **la métrica que fija el objetivo del equipo no puede ser
  la misma que se usa para evaluar a las personas** (→ `tech-leadership-standards`); (c) si una
  métrica sube mientras el resultado de negocio no se mueve, **la métrica está siendo optimizada, no
  el producto**.

### 6.3 Marcos de métricas, con su origen

- **HEART** (Happiness, Engagement, Adoption, Retention, Task success) + proceso **Goals-Signals-
  Metrics**: Rodden, Hutchinson & Fu, *Measuring the User Experience on a Large Scale:
  User-Centered Metrics for Web Applications*, **CHI 2010** (Google). Orientado a **calidad de
  experiencia**.
- **AARRR "pirate metrics"** (Acquisition, Activation, Retention, Referral, Revenue): **Dave
  McClure, 2007**. Orientado al **embudo de crecimiento**. (Las fuentes discrepan sobre el evento
  exacto de presentación —Ignite Seattle o un taller de Seedcamp—; el año, 2007, es consistente.)
- **Regla de uso**: un marco de métricas **no elige la métrica, solo evita olvidos**. Se elige **una
  primaria por objetivo** y se define canónicamente en `analytics-bi-standards`. **Adoptar HEART o
  AARRR completos y reportar sus cinco casillas cada mes es actividad, no medida.**

### 6.4 Dual track: **el descubrimiento no es una fase previa**

- **Mismo equipo, mismo período, dos flujos**: descubrimiento (qué construir y por qué) y entrega
  (construirlo bien). No dos equipos, no dos fases, no "sprint 0".
- Señales de que se ha degradado a fase: la entrega espera a que "termine el descubrimiento"; existe
  un backlog de descubrimiento aprobado con meses de antelación; el equipo de entrega recibe
  especificaciones que no puede discutir.
- **Compromiso mínimo semanal**: al menos un contacto con cliente y al menos una decisión de
  descubrimiento registrada por semana. Menos que eso, no es continuo.
- **Matar una idea es el mejor resultado posible.** Para que sea posible hay que hacerlo barato:
  (a) criterio de éxito **escrito antes** —sin él nadie puede declarar el fallo—, (b) sin nombre de
  autor pegado a la idea, (c) **celebrar públicamente el ahorro**, cuantificado en semanas-persona no
  gastadas. **Métrica de la función: nº de ideas descartadas tras descubrimiento por trimestre. Si
  es 0, el proceso está validando, no descubriendo.**

### 6.5 Descubrimiento sin usuarios externos (producto interno, plataforma)

- El cliente interno **no es cautivo aunque lo parezca**: puede esquivar la herramienta, montarse la
  suya o abrir un ticket para saltársela. **La deserción es la señal**, y la adopción forzada la
  destruye (premisa de `platform-engineering-standards`).
- Ventajas que hay que explotar: **acceso ilimitado a los usuarios** (están en el edificio) y
  **telemetría real de su trabajo**. La excusa "no tenemos usuarios" es falsa en producto interno.
- Limitación real: **no hay tráfico para A/B**. Sustitutos: piloto con un equipo voluntario, uso
  observado (no encuesta de satisfacción), **tiempo hasta el primer resultado útil** y **abandono a
  los 30 días**.
- **Trampa específica**: confundir al que paga (un directivo) con el que usa (los equipos). El
  patrocinador aprueba; el usuario decide si vive. **Se entrevista al que usa.**
- Un experimento con empleados como sujetos **también** tiene requisitos de privacidad y de relación
  laboral: monitorizar el trabajo de una persona no es telemetría de producto sin más →
  `privacy-engineering-standards`.

## 7. Sostenibilidad a largo plazo y prohibiciones

- **Cadencia sostenible**: contacto semanal con clientes; revisión trimestral del árbol de
  oportunidades contra el resultado; **retirada de métricas** que ya no deciden nada (mismo criterio
  de poda que los cuadros de mando en `analytics-bi-standards`).
- **Conservación del aprendizaje**: cada experimento deja una ficha con hipótesis, diseño, resultado
  y **decisión tomada**, enlazada a la oportunidad y guardada donde se busque
  (`knowledge-management-standards`). **Un aprendizaje que no se puede recuperar se vuelve a pagar.**
- Prohibiciones:
  - ❌ **Validar una idea buscando confirmación.** Se diseña el experimento que **podría matarla**; si
    no existe resultado posible que la mate, no es un experimento.
  - ❌ **Encuesta como sustituto de la observación.** La encuesta dimensiona lo ya observado; no
    descubre.
  - ❌ **Preguntar por intención futura** ("¿usarías…?", "¿pagarías…?") y tratar la respuesta como dato.
  - ❌ **A/B test sin cálculo previo de muestra, potencia y duración.**
  - ❌ **Parar un test al ver significancia** (§5.3), salvo parada por daño definida de antemano.
  - ❌ **Cambiar la métrica primaria, el diseño o la segmentación con el test en marcha.**
  - ❌ **Reportar una secundaria significativa sin corrección por comparaciones múltiples.**
  - ❌ **"Lo pidió un cliente" como justificación única.** Una petición es una solución propuesta: hay
    que recuperar el problema, y comprobar a cuántos afecta.
  - ❌ **Descubrimiento que nunca mata nada** (§6.4).
  - ❌ **Fake door en un flujo crítico o de pago**, y cualquier experimento que engañe sobre **quién ve
    los datos del usuario** (§4).
  - ❌ **Someter a prueba A/B un requisito de accesibilidad, de privacidad o legal.**
  - ❌ **Citar tasas de fracaso de producto o de uso de funcionalidades sin fuente primaria y
    metodología** (§8): en una discusión de inversión, una cifra sin fuente destruye el argumento
    entero cuando alguien la comprueba.
  - ❌ **Hoja de ruta con fechas para elementos aún no descubiertos**: convierte el descubrimiento en
    trámite (→ `project-management-standards` para cómo se comunica un compromiso).

## 8. Verificación web obligatoria

Comprobar antes de fijar o citar nada:

1. **Cuatro riesgos**: `svpg.com/four-big-risks/` e *INSPIRED* 2.ª ed. **La frase corta que circula
   es paráfrasis, no verbatim** — verificado en esta pasada; citar ensayo/libro.
2. **Árbol de oportunidades**: Teresa Torres, 2016; *Continuous Discovery Habits* (2021). Confirmar
   en `producttalk.org` antes de atribuir variantes del diagrama.
3. **Ley de Goodhart**: formulación original de 1975 (verbatim en §6.2) y **atribución correcta de
   la versión popular a Strathern (1997), no a Goodhart**.
4. **Peeking y always-valid**: Johari et al., KDD '17 / *Operations Research* 2021. **SRM**: Fabijan
   et al., KDD '19 y Kohavi/Tang/Xu cap. 21. Verificar el método concreto que implemente la
   herramienta que uses **antes** de confiar en su "significancia".
5. **HEART**: Rodden, Hutchinson & Fu, CHI 2010. **AARRR**: McClure, 2007 (**discrepancia declarada**
   en las fuentes sobre el evento exacto de presentación).
6. **Cifras famosas — descartadas, y por qué. No usarlas:**
   - **"El 95 % de los productos nuevos fracasa"** (atribuido a Clayton Christensen): **sin estudio,
     paper ni dataset** en las fuentes localizadas; se propaga como anécdota de aula. Los trabajos
     que separan productos *lanzados* de conceptos muertos en I+D sitúan el fracaso comercial en un
     orden mucho menor. **Descartada.** Si se necesita una cifra, buscar los estudios de referencia
     de la PDMA y Castellion & Markham (*JPIM*, 2013) sobre el origen de las tasas infladas —
     **no verificados en esta pasada**.
   - **"El 80 % de las funcionalidades no se usa"**: origen concreto **Pendo, 2019 Feature Adoption
     Report**, sobre **615 suscripciones de Pendo**, midiendo **volumen de clics** de funcionalidades
     **etiquetadas por el propio cliente**. Muestra autoseleccionada, "funcionalidad" definida por
     quien etiqueta, clic como sustituto del valor y **fabricante con interés comercial en el
     hallazgo**. La estirpe Standish previa da **45 %, 64 %, 75 % y 80 %** según edición —
     inconsistencia que es en sí misma la crítica. **Se puede usar como hipótesis a comprobar en tu
     propio producto; no como hecho.**
   - **"Cuesta 5 veces más captar que retener"**: la cadena de citas lleva a Reichheld & Sasser,
     *Zero Defections* (HBR, 1990), **cuyo hallazgo documentado es el efecto de la retención sobre el
     beneficio en unas pocas empresas de servicios financieros, no un múltiplo de coste de
     adquisición generalizable**. El múltiplo circula como 5×, 6-7× y 5-25×, señal de fuente débil.
     **Descartada.**
   - **Estadísticas de adopción de marcos de producto** ("el X % de los equipos usa descubrimiento
     continuo"): **hueco declarado**, sin fuente primaria localizada. No se escriben.
7. **Precondición de privacidad**: antes de cualquier experimento con datos de usuarios, comprobar
   base legal y obligaciones vigentes con `privacy-engineering-standards` — **la normativa cambia y
   este documento no es la fuente**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
