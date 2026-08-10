---
name: technical-hiring-standards
description: A hiring process is a measuring instrument and is judged by its validity and reliability. Use when writing a role definition or job description before interviewing, building a scoring rubric and scorecard before seeing the first candidate, choosing between a work sample, a walkthrough of the candidate's own code, live problem solving, a system design interview or a structured behavioural interview, setting a take-home exercise and its time limit or deciding to pay for it, running an interview loop and a debrief, calibrating interviewers, citing predictive validity of selection methods (Schmidt & Hunter 1998, Sackett Zhang Berry & Lievens 2022), replacing "culture fit" with observable values, offering reasonable adjustments and alternative formats to a candidate, publishing stages, timelines and feedback, designing a technical test when candidates use AI assistants, screening applicants with an automated employment decision tool or a resume screener, NYC Local Law 144 bias audits, Illinois HB 3773 or the Colorado AI Act, pay transparency under Directive (EU) 2023/970 and salary ranges in job ads, retaining or deleting candidate data, or measuring hiring by post-hire performance and retention rather than time-to-fill.
---

# Estándares de contratación técnica

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **el diseño y la ejecución del proceso de selección técnica como instrumento de medida**:
definición del puesto, rúbrica, elección de formatos de evaluación y su evidencia, estructura de la
entrevista, calibración de entrevistadores, decisión, experiencia del candidato, uso de IA por ambas
partes, y la incorporación como última etapa del proceso.

Triggers: "descripción del puesto", "job description", "rúbrica", "scorecard", "criterios de
evaluación", "muestra de trabajo", "work sample", "prueba técnica", "take-home", "tarea para casa",
"pair programming en entrevista", "entrevista de diseño de sistemas", "entrevista de
comportamiento", "STAR", "entrevista estructurada", "calibración de entrevistadores", "debrief",
"encaje cultural", "culture fit", "ajustes razonables", "experiencia del candidato", "feedback al
candidato", "IA en la entrevista", "cribado automático de CV", "ATS", "AEDT", "bias audit", "AI
Act empleo", "transparencia salarial", "banda salarial en la oferta", "datos del candidato",
"onboarding", "time to fill", "permanencia".

**Principio rector**: **un proceso de contratación es un instrumento de medida, y como tal se evalúa
por su validez y su fiabilidad, no por lo bien que se siente.** *Validez*: ¿mide lo que predice el
desempeño en **este** puesto? *Fiabilidad*: ¿dos entrevistadores distintos, o el mismo en dos días
distintos, llegan a la misma conclusión? **Un proceso que no puede responder a esas dos preguntas no
está seleccionando: está registrando impresiones y llamándolas datos.** Test falsable aplicable a
cualquier etapa propuesta: **nombra qué señal produce, con qué rúbrica se puntúa, y qué decisión
cambiaría si esa etapa no existiera.** Lo que no lo supere, se elimina — cada etapa cuesta tiempo
del equipo y candidatos que abandonan.

**Aviso de alcance — léase antes de aplicar nada de este documento.** Contratar tiene **obligaciones
legales reales**: no discriminación, protección de los datos personales de los candidatos y
**normativa específica sobre el uso de IA en decisiones de empleo**. Este documento fija **criterio
de ingeniería y de proceso**; **no es asesoramiento jurídico ni de recursos humanos**. Toda decisión
con efecto jurídico —redacción de ofertas, preguntas admisibles, bases legales de tratamiento,
despliegue de una herramienta de cribado automatizado, política retributiva— **se contrasta con
asesoría legal y con la función de RR. HH. de la organización antes de aplicarse**, y en la
jurisdicción concreta. Las referencias normativas de §5 son un mapa de por dónde preguntar, no un
dictamen.

**No aplica**:
- `tech-leadership-standards` (**ya escrita**): **recíproca y estricta**. Allí se decide **qué perfil
  hace falta, por qué, qué hueco del equipo cubre y qué nivel de la escala corresponde**; aquí,
  **cómo se mide a un candidato contra esa definición**. Frontera de una frase: **el liderazgo
  define el puesto; este proceso es el instrumento de medida.** También son suyos el desarrollo
  posterior, la evaluación de desempeño y la salida del equipo.
- `privacy-engineering-standards`: **los datos personales de candidatos son suyos** — base legal,
  minimización, plazos de conservación, derechos del interesado, borrado y DPIA. Aquí solo la
  obligación de que el proceso los respete y **la prohibición de guardar lo que no se va a usar**
  (§5).
- `grc-compliance-standards`: **el marco normativo aplicable y la evidencia formal** — qué norma
  obliga, cómo se demuestra el cumplimiento ante un auditor, registro de riesgos regulatorios.
- `ai-governance-standards`: **el uso de IA en decisiones que afectan a personas y su clasificación
  de riesgo son suyos** — inventario de sistemas, condición de proveedor o responsable del
  despliegue, evaluación de impacto en derechos fundamentales, supervisión humana significativa.
  Aquí, **la práctica concreta del proceso de selección** (§5): qué se puede automatizar, qué exige
  persona, y qué se le dice al candidato.
- `accessibility-standards` (**ya escrita**): **conformidad y ajustes son suyos** — WCAG, EN 301 549,
  formatos accesibles. Aquí, la obligación de ofrecerlos en cada etapa y de no penalizar por
  pedirlos (§3.7).
- `identity-access-management-standards`: **altas y bajas de acceso** en la incorporación y en la
  salida — provisión, mínimo privilegio, revocación con fecha. Aquí solo que el plan de
  incorporación las incluya y que la revocación sea verificable (§6).
- `knowledge-management-standards`: **la documentación que hace posible una
  incorporación rápida** — dónde vive, quién la mantiene, cómo se detecta que está obsoleta. Aquí
  solo que la primera semana de un recién incorporado es el mejor auditor que tendrá esa
  documentación (§6).
- `code-review-standards`: el criterio de revisión de un diff real. Se **reutiliza** al evaluar el
  código de un candidato, no se reinventa aquí.
- `project-management-standards`: la contratación como proyecto con plazos y partes interesadas.
- `ai-agent-workflow-standards` (**ya escrita**): la política de equipo sobre agentes de codificación
  en el trabajo diario. Aquí, **qué implica para el diseño de la prueba** que el candidato use uno
  (§5.1).

## 2. Decisiones por defecto

> Verificar por web el estado de las fuentes y de la normativa citadas antes de aplicarlas (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Antes de publicar la oferta | **Definición escrita del puesto**: problema que resuelve, evidencia que lo demostraría, nivel de la escala (§3.1) | — |
| Rúbrica | **Escrita y acordada antes de ver al primer candidato** (§3.2) | Nunca "después de las primeras entrevistas, cuando sepamos qué buscamos" |
| Estructura de la entrevista | **Estructurada**: mismas preguntas, mismo orden, misma escala, para todos los candidatos del mismo puesto | — |
| Formato de evaluación principal | **Muestra de trabajo** o **recorrido del código propio del candidato** (§3.3) | Resolución de problemas en vivo con enunciado realista |
| Acertijos de algoritmos con pizarra | **No se usan** salvo que el puesto los requiera de hecho (§3.3, §7) | — |
| Tarea para casa | **≤ 2-3 h declaradas y respetadas**, o **se paga** (§3.4) | Sustituirla por sesión guiada de la misma duración |
| Diseño de sistemas | Solo si el puesto diseña sistemas; con un problema del dominio real | — |
| Comportamiento / experiencia | **Entrevista estructurada de comportamiento** con preguntas fijas y ancla conductual | — |
| "Encaje cultural" | **Prohibido como criterio** (§3.6, §7). Se sustituye por **valores y comportamientos observables** con ancla | — |
| Puntuación | **Cada entrevistador escribe su evidencia y su nota ANTES del debate** (§3.5) | — |
| Decisión | **Contra la rúbrica, con evidencia citada**; empate = no se contrata y se revisa el proceso | — |
| Número de etapas | **El mínimo que produce señal distinta en cada una** (por defecto ≤ 3-4 contactos) | Más etapas solo con señal nueva demostrable |
| Cribado con IA | **Nunca decide**: como mucho ordena o etiqueta, con persona que revisa y registro (§5.2) | — |
| Transparencia salarial | **Banda publicada en la oferta** (§5.3) | — |
| Métrica de cabecera | **Desempeño y permanencia posteriores** (§6), no tiempo hasta cubrir | — |

### Evidencia sobre métodos de selección: las dos fuentes, y por qué hacen falta las dos

**Este es el punto donde más se cita mal en toda la ingeniería.** Hay un meta-análisis clásico muy
citado y una revisión posterior que corrigió sus cifras **a la baja**. Citar solo el primero es
citar una estimación que sus propios sucesores consideran inflada; citar solo el segundo, sin la
crítica que lo motiva, es dar un número sin su historia.

**(A) El clásico.** **Frank L. Schmidt y John E. Hunter, "The validity and utility of selection
methods in personnel psychology: Practical and theoretical implications of 85 years of research
findings", *Psychological Bulletin* 124(2):262-274 (1998)**, DOI 10.1037/0033-2909.124.2.262.
Sintetiza la validez de **19 procedimientos** para predecir desempeño en el puesto y en formación.
Valores más citados: **capacidad mental general ≈ .51**, **entrevista estructurada ≈ .51**,
**entrevista no estructurada ≈ .38**; combinación de entrevista estructurada + capacidad ≈ .63.
**Método, que es lo que casi nunca se cita**: son correlaciones **corregidas** por error de medida
en el criterio (normalmente valoraciones del supervisor) y por **restricción de rango**. Esa
corrección es exactamente lo que se puso en cuestión después.

**(B) La revisión que las corrigió a la baja.** **Paul R. Sackett, Charlene Zhang, Christopher M.
Berry y Filip Lievens, "Revisiting meta-analytic estimates of validity in personnel selection:
Addressing systematic overcorrection for restriction of range", *Journal of Applied Psychology*
107(11):2040-2068 (2022)**, DOI 10.1037/apl0000994 (en línea 30-dic-2021). **Verbatim del resumen**,
extraído del PDF, no de un comentario: *"After outlining and critiquing five approaches that have
commonly been used to create and apply range restriction artifact distributions, we conclude that
each has significant issues that often result in substantial overcorrection and that therefore the
validity of many selection procedures for predicting job performance has been substantially
overestimated. Revisiting prior meta-analytic conclusions produces revised validity estimates. Key
findings are that most of the same selection procedures that ranked high in prior summaries remain
high in rank, but with mean validity estimates reduced by .10–.20 points. Structured interviews
emerged as the top-ranked selection procedure. […] We conclude that our selection procedures remain
useful, but selection predictor–criterion relationships are considerably lower than previously
thought."*

Estimaciones revisadas de validez operativa **extraídas del propio artículo** (con su método al
lado, porque sin él la cifra no significa nada):

| Método | Sackett et al. (2022) | Procedencia declarada en el artículo |
|---|---|---|
| **Entrevista estructurada** | **.42** | Media ponderada por N de McDaniel et al. (1994) y Huffcutt et al. (2014), corregida solo por fiabilidad del criterio (.60), **sin corrección por restricción de rango** |
| Entrevista **no** estructurada | **.19** | Igual procedencia |
| Test de conocimiento del puesto | **.40** | Dye et al. (1993), subconjunto de tests específicos del puesto; corrección solo por fiabilidad |
| Capacidad mental general | **≈ .31** | Validez observada media .236; sin corrección por restricción de rango considerada defendible |
| Test de juicio situacional (SJT) | **.26** | McDaniel et al. (2007); .20 observada, corregida por fiabilidad .60 |
| Test de integridad | **.31** | **Media ponderada de dos meta-análisis irreconciliables (ver discrepancia)** |

Cambio agregado, **verbatim del artículo**: *"The mean across Schmidt and Hunter's top five was .49,
while the mean across our top five is .37."* La reordenación importa: **la entrevista estructurada
pasa a ser el predictor más fuerte** —Schmidt-Hunter situaba la capacidad cognitiva como predictor
focal— y *"the strongest predictors in our re-analysis (structured interviews, job knowledge tests,
empirically keyed biodata, and work samples) are all job-specific measures"*.

**Discrepancias declaradas, tal como el propio artículo las declara:**
- **Tests de integridad**: dos meta-análisis de alta calidad dan **.44 y .18**. Sackett y Schmitt
  (2012) intentaron reconciliarlos y **no lo consiguieron**; los datos brutos de uno de ellos no
  están disponibles. El **.31** de la tabla es una **media ponderada de dos resultados que nadie
  sabe reconciliar**, no un consenso. Consecuencia práctica: **no se apoya una decisión de proceso
  en tests de integridad**.
- **La media no aplica a tu organización.** El artículo insiste en ello: publica una desviación
  típica residual precisamente como *"an essential reminder that a given employer cannot count on
  the mean value as applicable to their organization"*. **Una validez media de .42 no significa que
  tu entrevista estructurada valga .42**; significa que el método puede llegar ahí si está bien
  construido.
- **Validez y diversidad no van juntas.** El artículo empareja validez con diferencias medias entre
  subgrupos: dentro de su "top cinco", **muestras de trabajo, tests de conocimiento y tests
  cognitivos presentan diferencias sustanciales**, mientras que **entrevista estructurada, biodata e
  integridad las presentan mucho menores**. Trabajo relacionado de los mismos autores concluye que
  **excluir los tests cognitivos apenas afecta a la validez y reduce sustancialmente el impacto
  adverso**. Esto es criterio de diseño del proceso, no una nota al pie.
- **Muestras de trabajo**: siguen en el "top cinco" y bajan respecto de Schmidt-Hunter, pero **el
  valor exacto revisado no se extrajo en esta verificación** — hueco declarado en §8. **No se
  escribe una cifra para muestras de trabajo hasta confirmarla en el artículo.**
- **Actualización intermedia**: Schmidt, Oh y Shaffer (2016) ya rebajaba las muestras de trabajo
  respecto de 1998 y añadía predictores nuevos. Existe además Sackett et al. (2023), *Industrial and
  Organizational Psychology* 16(3):283-300, con las implicaciones aplicadas.

**Cómo se usan estas cifras, y esto es lo único que importa operativamente:**
1. **Como orden de preferencia entre métodos**, no como predicción de resultado. La conclusión
   robusta a través de ambas fuentes: **estructurar la entrevista es el cambio de mayor impacto
   disponible** — el mismo formato, estructurado o no, va de ~.42 a ~.19 (2022) o de ~.51 a ~.38
   (1998). **Ninguna otra intervención barata mueve tanto.**
2. **Nunca como número en una oferta, una diapositiva o una discusión con dirección** sin su año, su
   corrección y su intervalo. Una correlación de .42 explica una fracción modesta de la varianza:
   **un proceso excelente sigue equivocándose a menudo**, y un proceso que promete lo contrario
   miente.
3. **Prohibido citar solo Schmidt-Hunter 1998.** Sus propias cifras están corregidas a la baja por
   la literatura posterior (§7).

### Cifras famosas: qué NO se usa como dato

- ❌ **"El coste de una mala contratación es 1,5 veces el salario"** (y sus variantes: 30 % de las
  retribuciones del primer año "según el Departamento de Trabajo de EE. UU.", 213 %, 240.000 $).
  **No hay estudio primario localizable.** Lo que hay es deriva de citación: datos de la SBA sobre
  el coste de **contratar** (1,25-1,4× la base) convertidos en coste de una **mala** contratación;
  rangos de SHRM citados de forma inconsistente entre sí (½-2×, 50-200 %, tramos por nivel); un 30 %
  atribuido al DOL **sin título de informe, año ni metodología**; el 213 % que en realidad procede de
  un meta-análisis del Center for American Progress (2012) sobre **rotación**, no sobre malas
  contrataciones; una encuesta autodeclarada de CareerBuilder (2011); y una cifra de 240.000 $ que
  es **la estimación de un reclutador**. Añádase que casi todas las fuentes que la difunden **venden
  servicios de contratación**. **No se escribe.** Si hace falta un número para decidir, **se
  construye de abajo arriba con datos propios**: gasto de selección, salario pagado, tiempo de rampa
  y coste de repetir el proceso.
- ❌ **Porcentajes de rotación atribuidos a "mal jefe"** y **"la gente deja jefes, no empresas"**:
  descartados con su refutación en `tech-leadership-standards` §2.
- ❌ **Cualquier cifra de "los mejores ingenieros son 10x"** usada para justificar una banda salarial
  o un listón de contratación: la cifra fundacional está desmontada
  (`tech-leadership-standards` §2, Prechelt 1999).
- ❌ **Estadísticas de conversión y de "candidatos por oferta" de proveedores de ATS** sin muestra ni
  método publicados.

**Regla general**: **cifra con fuente primaria, año, muestra y método, o no se escribe.**

## 3. Estructura y convenciones

### 3.1 Definir el puesto antes de entrevistar

**No se abre un proceso sin este documento.** Tres preguntas, respondidas por escrito por quien
lidera técnicamente (`tech-leadership-standards`):

1. **¿Qué problema resuelve esta persona en los próximos 12 meses?** Concreto y verificable. *"Hacer
   que el servicio de cobros pueda cambiarse sin miedo: hoy concentra 3 de cada 7 incidentes"*, no
   *"reforzar el equipo de backend"*.
2. **¿Qué evidencia demostraría que sabe hacerlo?** De aquí salen las etapas del proceso. Si una
   etapa propuesta no produce evidencia de esta lista, **sobra**.
3. **¿Qué nivel de la escala publicada es, y en qué banda retributiva?** Decidido **antes** de
   conocer candidatos. Ajustar el nivel al candidato que apareció es cómo se construyen agravios
   internos y desigualdades retributivas que después hay que auditar.

Reglas:
- **Separar requisitos de deseos.** Un requisito es algo sin lo cual la persona **no puede** hacer el
  trabajo desde el primer mes. Todo lo demás es deseable y **no filtra**. Las listas infladas de
  requisitos reducen el conjunto de candidatos de forma asimétrica y sin ganar señal.
- **Prohibido pedir años de experiencia como sustituto de competencia** (§7). "5 años de X" no es
  una habilidad; es un dato que se correlaciona mal y que excluye trayectorias no lineales. Se pide
  la capacidad y se mide.
- **Prohibido pedir experiencia en una tecnología por más tiempo del que esa tecnología existe**
  — el error clásico, y es un indicador fiable de que nadie leyó la oferta.
- **La oferta declara**: banda salarial (§5.3), modalidad de trabajo, etapas del proceso con su
  duración, y quién decide. **La ausencia de banda es una señal para el candidato, y es la correcta.**

### 3.2 La rúbrica: escrita antes del primer candidato

**Si no hay rúbrica escrita antes de ver al primer candidato, no se está midiendo competencia: se
está midiendo impresión personal, y después se buscará justificación.** No es una opinión sobre
estilo: es la diferencia entre entrevista estructurada y no estructurada, que es el factor con más
efecto documentado sobre la validez (§2).

Formato mínimo por competencia:

```yaml
competencia: Diseño de sistemas bajo restricciones reales
por_que_importa: "El puesto define interfaces entre 3 equipos; un mal contrato cuesta trimestres"
se_evalua_en: [ejercicio de diseño, recorrido del código propio]
escala:
  1_no_cumple:  "Propone una solución sin preguntar por restricciones ni volumen"
  2_parcial:    "Pregunta por restricciones; no razona sobre fallo ni sobre evolución"
  3_cumple:     "Declara supuestos, razona sobre fallo y coste, propone una alternativa y la descarta con motivo"
  4_supera:     "Además identifica el compromiso que el enunciado ocultaba y propone cómo validarlo barato"
evidencia_requerida: "Cita textual o descripción de lo que la persona hizo o dijo. Sin cita, la nota no computa"
```

- **Anclas conductuales, no adjetivos.** "Buena comunicación" no es una ancla. "Explicó una decisión
  técnica a alguien sin contexto y comprobó que se había entendido" sí lo es.
- **Escala par (1-4)** para forzar decisión; el punto medio de una escala impar absorbe la mitad de
  las notas y destruye la señal.
- **La rúbrica es la misma para todos los candidatos del puesto**, y se archiva con el proceso.
- **Cambiar la rúbrica a mitad de proceso invalida las comparaciones anteriores.** Si hay que
  cambiarla, se declara, y los candidatos ya evaluados se reevalúan o se descartan del conjunto de
  comparación — **no se mezclan**.
- **Cada entrevistador sabe qué competencias le tocan y cuáles no.** Dos entrevistadores midiendo lo
  mismo es una etapa desperdiciada; una competencia sin dueño es un hueco que se rellenará con
  intuición.

### 3.3 Formatos: para qué sirve cada uno

| Formato | Qué mide realmente | Cuándo se usa | Fallo típico |
|---|---|---|---|
| **Muestra de trabajo** (tarea representativa del puesto, en entorno realista) | Capacidad de hacer el trabajo | Casi siempre; es el formato con mejor correspondencia conducta-criterio | Se convierte en un examen artificial y deja de ser una muestra |
| **Recorrido del código propio del candidato** (o de un proyecto suyo) | Criterio técnico, capacidad de explicar decisiones, honestidad sobre compromisos | **Excelente alternativa cuando la persona tiene material propio**; coste casi nulo para el candidato | Penaliza a quien no puede enseñar código (NDA, sector, sin tiempo libre): **debe existir alternativa equivalente** |
| **Resolución de problemas en vivo** sobre un enunciado realista, con acompañamiento | Cómo piensa cuando no sabe, cómo pregunta, cómo depura | Cuando importa el proceso más que el resultado | Se convierte en examen con público; el entrevistador habla más que el candidato |
| **Diseño de sistemas** | Razonamiento sobre restricciones, fallo, evolución y coste | Solo si el puesto diseña sistemas | Se puntúa por coincidir con la solución del entrevistador en vez de por la calidad del razonamiento |
| **Entrevista estructurada de comportamiento** (situaciones pasadas, preguntas fijas, ancla conductual) | Conducta pasada en situaciones análogas | Siempre; es el formato mejor situado en la evidencia revisada (§2) | Se desestructura sobre la marcha y vuelve a ser charla |
| **Acertijo de algoritmos en pizarra** | **Mayormente preparación específica para ese tipo de examen** | **Solo si el puesto exige de hecho ese trabajo** (compiladores, motores, cripto, sistemas embebidos) | Se usa por defecto para todo, filtra por tiempo libre para prepararse y por familiaridad con el formato, no por capacidad |

Reglas transversales:
- **El enunciado se parece al trabajo.** Cuanto más se aleja la prueba de la tarea real, más mide
  otra cosa — y esa otra cosa suele correlacionar con acceso, tiempo libre y familiaridad cultural
  con el formato.
- **Se permite consultar documentación**, como en el trabajo real. Prohibir buscar mide memoria,
  que no es la habilidad del puesto.
- **La misma prueba para todos los candidatos del puesto.** Cambiar la dificultad "según se ve al
  candidato" destruye la comparabilidad y es la vía silenciosa por la que entra el sesgo.
- **Nadie entrevista sin haber hecho la prueba** que va a poner. Descubrir que la prueba de "45
  minutos" lleva dos horas debe pasarle al entrevistador, no al candidato.
- **Los acertijos de algoritmos no se prohíben por ser difíciles**, sino porque **miden
  mayoritariamente preparación específica**: el mismo candidato puntúa muy distinto antes y después
  de dos meses practicando un formato que no volverá a usar. Eso es exactamente lo contrario de un
  instrumento válido para el puesto.

### 3.4 Tareas para casa: el límite de tiempo es una cuestión ética

Una tarea para casa traslada el coste del proceso al candidato, que ya está trabajando en otro
sitio. Es admisible **con condiciones duras**:

1. **Límite de tiempo declarado y real** (por defecto **2-3 horas**), **verificado por alguien del
   equipo que la ha hecho**. Si el equipo tarda tres horas, el candidato tardará más.
2. **El límite se respeta al evaluar.** Prohibido premiar al que se pasó del límite: hacerlo
   convierte el límite en una trampa y **selecciona por disponibilidad de tiempo libre**, que
   discrimina por cuidados, salud, segundo empleo y situación económica.
3. **Alcance acotado y enunciado cerrado.** "Haz lo que puedas" no se puede puntuar y garantiza que
   cada candidato entregue algo incomparable.
4. **Alternativa siempre disponible**: sesión guiada de la misma duración con el equipo, o recorrido
   del código propio (§3.3). **Nunca una única vía.**
5. **Si la tarea supera unas pocas horas, se paga a tarifa de mercado**, con contrato o factura.
   **No hay tercera opción**: o es corta, o se paga. Un ejercicio largo no remunerado es trabajo
   gratis para un desconocido.
6. **PROHIBIDO usar trabajo de candidatos en producción**, aunque no se contrate. Si el enunciado
   resuelve un problema real del producto, ya no es una prueba: es un encargo.
7. **Se devuelve feedback** sobre la tarea. Quien ha invertido tres horas tiene derecho a saber qué
   falló, aunque sea en tres líneas.

### 3.5 Estructura, calibración y decisión

**Entrevista estructurada frente a no estructurada: el cambio de mayor impacto disponible** (§2). Y
es barato — no requiere herramienta, presupuesto ni consultora, solo escribir las preguntas antes.

- **Estructurada** significa las cuatro cosas a la vez: **mismas preguntas**, **mismo orden**, **misma
  escala con anclas**, y **notas escritas con evidencia**. Faltando una, no es estructurada.
- **Preguntas de seguimiento acotadas**: se permite profundizar, pero desde una lista preparada. El
  seguimiento libre es la puerta por la que la entrevista se desestructura sin que nadie lo note.

**Calibración de entrevistadores** — sin esto la rúbrica es un documento, no un instrumento:
- **Nadie entrevista solo antes de haber acompañado** varias entrevistas y haber sido acompañado
  puntuando en paralelo.
- **Ejercicio de calibración periódico**: dos o tres entrevistadores puntúan la **misma** grabación o
  el mismo ejercicio y comparan. **Divergencia sistemática de un entrevistador = se recalibra o sale
  del panel.** Es literalmente la fiabilidad entre observadores del instrumento.
- **Panel diverso en la medida de lo posible**, y **siempre más de una persona por decisión**.

**Decisión — la regla que más resultados cambia y la más incumplida:**
> **Cada entrevistador escribe su evidencia y su puntuación ANTES de la reunión de debate y sin ver
> la de los demás.**

Sin esto, el debate no agrega información: la primera opinión enunciada arrastra a las demás y el
resultado es **una opinión con formato de consenso**. Reglas del debate:
- Se discuten **desacuerdos**, no se recorre todo. Un desacuerdo obliga a citar la evidencia
  concreta que sostiene cada nota.
- **Un "no" con evidencia contra la rúbrica pesa más que tres "sí" sin ella.** Y al revés: un "no"
  sin evidencia **no bloquea**.
- **Empate o duda razonable → no se contrata**, y **se revisa qué etapa no produjo señal**. Contratar
  en la duda es cómo se llega a la separación difícil y cara seis meses después.
- **La decisión se registra** con la evidencia citada: es lo que permite defenderla, revisarla y —
  si algún día hace falta — demostrar que el criterio fue el mismo para todos.
- **Prohibido reabrir la decisión por presión de calendario** ("llevamos tres meses buscando"). La
  urgencia de cubrir un puesto no es evidencia sobre el candidato.

### 3.6 Sesgo, y la trampa del "encaje cultural"

- **"Encaje cultural" es la vía de entrada del sesgo mejor documentada y la más socialmente
  aceptada**, porque no suena a discriminación: suena a criterio. En la práctica se puntúa
  similitud —origen, clase, aficiones, forma de hablar, escuela— y se etiqueta como cultura. Efecto:
  homogeneiza el equipo y reduce exactamente la diversidad cognitiva que se dice buscar. **Se
  prohíbe como criterio** (§7).
- **Se sustituye por valores y comportamientos observables**, con ancla y con evidencia, igual que
  cualquier otra competencia. Ejemplos utilizables: *"describe una vez que cambiaste de opinión ante
  un dato"* (evidencia: cita el dato y qué hizo después); *"cuenta un desacuerdo técnico y cómo
  terminó"* (evidencia: procedimiento, no desenlace favorable). **Lo que se mide es la conducta, no
  la afinidad.**
- **Si el equipo quiere medir "aporta algo que no tenemos"**, eso se llama *culture add* y **también
  necesita ancla escrita**, o es el mismo sesgo con nombre nuevo.
- **Otras entradas de sesgo con contramedida concreta**:
  - *Efecto halo* de un nombre de empresa o universidad en el CV → **cribado sin esos campos** cuando
    el proceso lo permita, y rúbrica que no los puntúa.
  - *Anclaje* por la primera impresión → puntuación escrita antes del debate (§3.5).
  - *Sesgo de similitud* → panel diverso y anclas conductuales.
  - *Prueba desigual* → mismo enunciado y mismo tiempo para todos.
- **Preguntas ilegales o irrelevantes**: edad, origen, situación familiar, embarazo, salud,
  discapacidad, religión, orientación, afiliación sindical, y **el salario anterior** (§5.3).
  **Prohibidas**, también "por conversación informal" y también en el café previo (§7). Si un
  entrevistador no sabe qué puede preguntar, no entrevista hasta que lo sepa: la formación es
  responsabilidad de quien monta el panel, en coordinación con RR. HH.

### 3.7 Accesibilidad e inclusión del proceso

El criterio de conformidad es de `accessibility-standards`. **Aquí, las obligaciones del proceso:**
- **Ofrecer ajustes razonables de forma proactiva y en cada etapa**, en el mensaje de invitación, no
  solo si el candidato pregunta. Redacción operativa: *"Si necesitas algún ajuste de formato, tiempo
  o herramienta, dínoslo y lo organizamos; no influye en la evaluación."*
- **PROHIBIDO que pedir un ajuste influya en la evaluación**, y prohibido registrarlo en la ficha de
  evaluación: es dato de salud (§5.4, `privacy-engineering-standards`).
- **Formatos alternativos por defecto**, no como excepción: tarea para casa ↔ sesión guiada; código
  propio ↔ ejercicio; entrevista por vídeo ↔ por voz o por escrito.
- **La plataforma de evaluación también se evalúa.** Un editor de código online que no funciona con
  lector de pantalla, o un test cronometrado sin posibilidad de tiempo extra, excluye candidatos
  antes de medir nada. Se comprueba antes de adoptarlo.
- **Neurodivergencia**: las señales que muchos entrevistadores puntúan sin declararlo —contacto
  visual, fluidez social, respuesta rápida bajo presión— **no están en la rúbrica y no son el
  trabajo**. Puntuarlas es medir otra cosa. Enviar las preguntas o el enunciado por adelantado
  mejora la señal para todo el mundo y **no es una ventaja injusta**: es reducir ruido.

### 3.8 Experiencia del candidato

Un candidato es un profesional del sector que hablará del proceso con sus colegas. **El coste de un
proceso interminable es reputacional y se paga en las contrataciones siguientes**, no en esta.

- **Etapas y duración publicadas** en la oferta, y respetadas. Si cambian, se avisa.
- **Plazos comprometidos**: respuesta tras cada etapa en un plazo declarado (por defecto ≤ 5 días
  laborables). **Superarlo sin avisar es incumplir un compromiso, no un descuido administrativo.**
- **Nadie queda sin respuesta.** El silencio tras una prueba de tres horas es el fallo de proceso más
  citado por candidatos y el más barato de corregir.
- **Retroalimentación específica a quien completó una prueba**, aunque sea breve. Prohibido el
  "hemos decidido continuar con otros perfiles" a quien invirtió horas.
- **Número de etapas acotado.** Cada etapa adicional debe producir **señal distinta** (§1); si no,
  solo produce abandono, y el abandono no es aleatorio: se van antes los que tienen alternativas.
- **La persona que decide aparece en el proceso.** Un candidato que nunca habla con quien será su
  responsable no puede evaluar la oferta, y la evaluación es mutua.

## 4. Calidad del instrumento: controles verificables

*(Esta sección sustituye a la §4 canónica de testing: aquí lo que se somete a control **es el propio
proceso de selección**.)*

Controles auditables sobre el proceso, con cadencia fija. **Su fallo detiene el proceso o abre
trabajo con dueño; no genera un informe.**

| Control | Falla si | Acción |
|---|---|---|
| Puesto sin definir | no existe el documento de §3.1 antes de publicar | No se publica la oferta |
| Rúbrica tardía | la rúbrica no existía antes del primer candidato | Se detiene el proceso y se reevalúa a los ya vistos |
| Etapa sin señal | una etapa no puntúa ninguna competencia de la rúbrica | Se elimina la etapa |
| Nota sin evidencia | una puntuación sin cita ni descripción de conducta | No computa |
| Contaminación del debate | alguien puntúa después de oír a otros | La nota se descarta |
| Entrevistador no calibrado | entrevista en solitario sin haber calibrado | Se retira del panel |
| Divergencia sistemática | un entrevistador se desvía persistentemente del panel | Recalibración obligatoria |
| Prueba desigual | dos candidatos del mismo puesto con enunciado o tiempo distintos | Se anula la comparación |
| Tarea sobre el límite | la tarea excede el tiempo declarado medido por el equipo | Se recorta o se paga |
| Ajuste no ofrecido | la invitación no menciona ajustes razonables | Se corrige la plantilla |
| Plazo incumplido | respuesta fuera del plazo publicado sin aviso | Se avisa y se registra como fallo del proceso |
| Criterio prohibido | aparece "encaje cultural", "actitud", "energía" o similar en una ficha | Se anula esa nota y se recalibra al entrevistador |
| Cribado automatizado sin persona | un candidato descartado sin revisión humana | Se revierte y se revisa la herramienta (§5.2) |
| Datos fuera de plazo | CV o notas conservados más allá del plazo declarado | Borrado y registro del incidente |
| Sin dato posterior | no se mide desempeño ni permanencia a 6-12 meses | El proceso no se puede mejorar: se instrumenta (§6) |

**Prueba de fiabilidad del instrumento, ejecutable literalmente**: dar el mismo material (grabación,
ejercicio entregado) a dos entrevistadores independientes. **Si sus notas no coinciden dentro de un
punto de la escala, el problema no es el candidato: es la rúbrica o la calibración.**

## 5. IA en la contratación, régimen legal y datos de candidatos

**Sección obligatoria y con fecha de caducidad corta.** El marco legal se mueve; §8 obliga a
reverificarlo antes de aplicarlo.

### 5.1 Candidatos que usan asistentes de IA en la prueba técnica

**Punto de partida realista: prohibirlo no es aplicable ni deseable.** No se puede verificar de forma
fiable sin vigilancia intrusiva —que tiene su propio problema legal y de datos— y además **prohíbe
la herramienta que la persona usará el primer día de trabajo**.

Consecuencias para el **diseño** de la prueba, que es lo que sí se controla:
- **Si la prueba la resuelve un modelo de propósito general en dos minutos, la prueba estaba midiendo
  lo que ya no hace falta medir.** No es un problema de trampas: es un problema de validez del
  instrumento, y se arregla cambiando la prueba.
- **Se desplaza la señal hacia lo que el asistente no aporta**: **juicio** (por qué esta opción y no
  la otra), **crítica de la salida** (dado este código, qué está mal y qué falta), **restricciones
  del dominio real** (el enunciado que exige preguntar), **depuración de un fallo no evidente**, y
  **capacidad de explicar y defender lo entregado**.
- **Formato robusto por defecto**: entrega + **conversación sobre la entrega**. Quien no puede
  explicar una decisión de su propio código, no la tomó. Es la prueba más barata y no requiere
  vigilancia de nada.
- **Política declarada al candidato, por escrito y por adelantado**: si se permite usar asistentes
  (recomendado), se dice; si en alguna etapa concreta no —y debe haber motivo—, se dice **antes**.
  **PROHIBIDO evaluar en secreto si el candidato usó IA**, y prohibido descartar por sospecha sin
  evidencia (§7).
- ❌ **PROHIBIDA la vigilancia remota intrusiva del candidato** (control del escritorio, captura de
  pantalla continua, seguimiento ocular, análisis biométrico). Además de su régimen legal, mide
  ansiedad y equipamiento, no competencia.

### 5.2 Uso de IA para cribar candidatos, y su régimen legal

**Regla de proceso, que es independiente de la jurisdicción: un modelo puede ordenar o etiquetar;
no descarta.** Todo descarte lo confirma una persona con nombre, contra la rúbrica y con registro.
Sin validación local y sin supervisión humana efectiva, una herramienta de cribado es un sesgo
histórico automatizado y escalado.

**Unión Europea — Reglamento de IA (AI Act).** El empleo es **caso de alto riesgo**: el **Anexo III,
punto 4** cubre los sistemas de IA destinados a la contratación o selección (entre otros, publicar
anuncios dirigidos, analizar y filtrar solicitudes y evaluar candidatos), así como decisiones de
promoción, extinción, asignación de tareas y seguimiento del desempeño.

**Fechas de aplicación — verificadas y con la corrección que casi nadie ha incorporado:**
- Calendario **original**: obligaciones de alto riesgo del **Anexo III desde el 2-ago-2026**; Anexo I
  (IA embebida en productos regulados) desde el **2-ago-2027**.
- **Ese calendario se ha aplazado.** Tras la propuesta de la Comisión de **19-nov-2025** (*Digital
  Omnibus* sobre IA), hubo **acuerdo político entre Consejo y Parlamento el 7-may-2026** y
  confirmación del Consejo el **29-jun-2026**: **Anexo III (incluido empleo) pasa al 2-dic-2027**
  (prórroga de 16 meses) y **Anexo I al 2-ago-2028** (12 meses).
- **Lo que NO se ha movido**: las **prácticas prohibidas del artículo 5** y el deber de
  **alfabetización en IA del artículo 4**, aplicables **desde el 2-feb-2025**; las obligaciones de
  modelos de propósito general **desde el 2-ago-2025**; y las obligaciones de transparencia del
  **artículo 50**.
- **Prohibición directamente relevante para la selección: el artículo 5 prohíbe los sistemas de
  reconocimiento de emociones en el lugar de trabajo y en centros educativos, salvo por razones
  médicas o de seguridad.** Consecuencia práctica: **el análisis de expresión facial, tono de voz o
  "engagement" en una entrevista en vídeo está en terreno prohibido o en su frontera inmediata**, y
  la delimitación exacta respecto de un candidato externo es una cuestión jurídica que **se consulta
  con asesoría legal antes de contratar la herramienta**, no después.
- **Advertencia de estado — no es un dato cerrado**: el aplazamiento requiere **adopción formal y
  publicación en el DOUE** para producir efectos. `ai-governance-standards` lo referencia como
  **Reglamento (UE) 2026/1744**. **Antes de planificar contra la fecha de dic-2027, confirmar la
  publicación en el DOUE y el número de reglamento** (§8): si no llegó a publicarse antes del
  2-ago-2026, aplica el calendario original tal como estaba escrito.
- **Postura de ingeniería, independientemente de la fecha**: 16 meses más son **margen, no
  cancelación**. Las obligaciones —gestión de riesgos, documentación técnica, registro de eventos,
  supervisión humana, evaluación de conformidad y registro del sistema— **llegan igual**, con menos
  tiempo si se aparcan.

**Estados Unidos — normas locales ya vigentes**, relevantes si se contrata allí:
- **Nueva York, Local Law 144** (en vigor 1-ene-2023, aplicación desde 5-jul-2023): **auditoría de
  sesgo del AEDT realizada como máximo un año antes de su uso**, **publicación del resumen de la
  auditoría** en la web, y **aviso al candidato con al menos 10 días hábiles** de antelación
  indicando que se usará, cómo y qué datos se recogen. Sanciones de **500 a 1.500 $ por día**.
  **Dato incómodo y verificado**: una auditoría del Contralor del Estado de **2-dic-2025** concluyó
  que la aplicación de la ley por el DCWP era **ineficaz**; y un estudio publicado (*Null
  Compliance*, arXiv) encontró que **de 391 empleadores examinados solo 18 publicaron el informe de
  auditoría y 13 el aviso de transparencia**. **Lectura correcta: baja probabilidad de sanción no es
  cumplimiento, y el escrutinio va a subir.**
- **Illinois, HB 3773** (enmienda a la *Human Rights Act*), firmada 9-ago-2024, **en vigor
  1-ene-2026**: aviso al candidato cuando se usa IA en decisiones de empleo, prohibición de usar el
  código postal como aproximación de una característica protegida, y prohibición de usos con
  resultado discriminatorio. **El reglamento de desarrollo está inestable**: el IDHR publicó
  propuesta el 15-may-2026 y **la retiró temporalmente**, cancelando la audiencia de 10-jun-2026.
  **Las obligaciones legales siguen vigentes** pese a ello.
- **Colorado**: la ley original (SB 24-205) quedó **con la aplicación suspendida por orden judicial**
  (27-abr-2026) y ha sido **sustituida por SB 26-189**, firmada el 14-may-2026, con efecto
  **1-ene-2027** y requisitos recortados. **El empleo sigue cubierto en ambas.** Es el marco más
  volátil de los tres: **no se planifica contra él sin verificar el estado del mes en curso.**

**España**, además del AI Act:
- **Artículo 64.4.d) del Estatuto de los Trabajadores** (introducido por la *Ley Rider*, **Ley
  12/2021**, con origen en el RDL 9/2021). **Verbatim del derecho reconocido a la representación
  legal**: *"ser informado por la empresa de los parámetros, reglas e instrucciones en los que se
  basan los algoritmos o sistemas de inteligencia artificial que afectan a la toma de decisiones que
  pueden incidir en las condiciones de trabajo, el acceso y mantenimiento del empleo, incluida la
  elaboración de perfiles"*. **"Acceso al empleo" y "elaboración de perfiles" alcanzan de lleno al
  cribado de candidatos.** Hay pronunciamiento judicial que ha considerado que **no informar vulnera
  el derecho fundamental de libertad sindical**, con indemnización; se cita como indicio de que el
  derecho es exigible, **no como doctrina consolidada** — su alcance exacto se consulta con asesoría
  laboral.
- **Decisiones automatizadas y RGPD** (art. 22) e información al interesado:
  `privacy-engineering-standards`.

### 5.3 Transparencia salarial

- **Banda salarial en la oferta, por defecto.** No es solo cumplimiento: reduce el número de procesos
  que terminan en desencuentro económico tras cinco etapas, que es puro coste para ambas partes.
- **Directiva (UE) 2023/970**, de 10-may-2023, sobre refuerzo de la igualdad retributiva mediante
  transparencia. Publicada en el DOUE el **17-may-2023**, en vigor el **6-jun-2023**, **plazo de
  transposición hasta el 7-jun-2026** (arts. 34 y 36). Entre sus exigencias: **información sobre la
  retribución inicial o su banda a los candidatos antes de la entrevista**, **prohibición de
  preguntar al candidato por su salario anterior**, derecho de la plantilla a conocer niveles
  retributivos medios desglosados por sexo, y **evaluación retributiva conjunta cuando la brecha
  supera el 5 % sin justificación**.
- **Estado en España a ago-2026: NO transpuesta.** El plazo del 7-jun-2026 **venció sin
  transposición**; el Ministerio de Trabajo abrió consulta pública previa del real decreto de
  transposición, cerrada el **8-may-2026**, sin pasos posteriores conocidos. España parte del **Real
  Decreto 902/2020** de igualdad retributiva (registro retributivo obligatorio y auditoría
  retributiva), que **sí está vigente**. **El retraso no elimina el principio de igualdad
  retributiva**, ya reconocido en el ordenamiento.
- **Calendario de reporte anunciado** (según fuentes secundarias, **contrastar con el texto de la
  directiva antes de planificar**, §8): empresas de **≥ 250 personas**, anual, **primer informe antes
  del 7-jun-2027**; **150-249**, cada tres años, primer informe también en jun-2027; **100-149**, más
  adelante.
- **Criterio de ingeniería, aplicable ya y con independencia de la transposición**: **banda publicada,
  no preguntar por el salario anterior, y oferta construida sobre el nivel del puesto (§3.1), no
  sobre lo que la persona ganaba antes.** Anclar la oferta al salario previo **importa desigualdades
  de otras organizaciones** y las perpetúa dentro de la propia.

### 5.4 Datos de candidatos

El criterio completo —base legal, minimización, plazos, derechos y borrado— es de
`privacy-engineering-standards`. **Reglas que este proceso debe cumplir sí o sí:**
- **Base legal declarada** para tratar los datos, y **plazo de conservación declarado al candidato**
  desde el primer contacto. Conservar un CV "por si acaso" sin base ni plazo es tratamiento sin
  amparo.
- **Consentimiento separado y verificable** para conservar la candidatura para procesos futuros, con
  **plazo y borrado automático al vencer**. Un consentimiento sin fecha de caducidad no es un
  consentimiento: es un archivo permanente.
- **Minimización**: no se piden fecha de nacimiento, foto, estado civil, nacionalidad ni datos de
  salud. Si el ATS los pide por defecto, **se configura para que no lo haga**.
- **Las notas de entrevista son datos personales** y son accesibles al interesado. Corolario
  operativo: **se escriben como si el candidato fuera a leerlas** — evidencia conductual, sin juicios
  sobre la persona. Es además la mejor disciplina de rúbrica que existe.
- **PROHIBIDO** almacenar datos de candidatos en hojas de cálculo personales, canales de chat o
  unidades compartidas fuera del sistema con control de acceso y traza.
- **Los ajustes solicitados (§3.7) son datos de salud**: tratamiento restringido, fuera de la ficha
  de evaluación, y borrado cuando dejan de ser necesarios.
- **Verificación de referencias**: solo con conocimiento del candidato y sobre hechos verificables
  relacionados con el puesto. **Prohibido contactar con su empleador actual sin permiso explícito.**

## 6. Incorporación y la métrica correcta

*(La §6 canónica —rendimiento y operabilidad— no aplica a un dominio de proceso; **se sustituye
declarándolo** por la última etapa del proceso y por su medición.)*

**La incorporación es parte del proceso de contratación, no lo que viene después.** Un proceso que
selecciona bien y luego abandona a la persona ha desperdiciado su propio resultado.

- **Todo se prepara antes del primer día**: accesos y equipos (`identity-access-management-standards`,
  con **mínimo privilegio desde el día uno**, no "todo y ya lo iremos quitando"), persona de
  referencia nombrada, y **una primera contribución realista para la primera semana**.
- **Objetivos escritos a 30 / 60 / 90 días**, acordados y revisados en el 1:1
  (`tech-leadership-standards` §3.9).
- **El recién incorporado es el mejor auditor de la documentación que tendrá el equipo**, y solo lo
  es una vez: **su lista de "esto no estaba escrito" se convierte en tickets el mismo mes**
  (`knowledge-management-standards`). Desaprovechar esa ventana es tirar el único punto de
  vista externo disponible.
- **Métrica de la incorporación**: **tiempo hasta la primera contribución en producción** y **tiempo
  hasta la primera guardia en autonomía** (si el equipo tiene guardia). Ambas dicen más del sistema
  de la organización que de la persona.
- **Revocación verificable a la salida**: accesos, credenciales, dispositivos y llaves, con lista y
  fecha (`identity-access-management-standards`). Una salida sin revocación registrada es una cuenta
  huérfana con permisos.

**La métrica del proceso de contratación, y esta es la corrección que hay que sostener ante quien
mide otra cosa:**

| Métrica | Qué es | Uso |
|---|---|---|
| ❌ **Tiempo hasta cubrir el puesto** (*time to fill*) | Velocidad del proceso | **No es medida de calidad.** Se optimiza bajando el listón; es la métrica que empeora el resultado más rápido |
| ❌ Número de candidatos entrevistados, CV recibidos | Actividad | Ruido |
| ✅ **Desempeño posterior** a 6-12 meses, evaluado contra la rúbrica original | Validez del instrumento | **La medida principal.** Es la única que cierra el bucle |
| ✅ **Permanencia** a 12 y 24 meses, y **motivo declarado de salida** | Validez y honestidad de la oferta | Salidas tempranas concentradas = el proceso vendió otra cosa, o midió otra cosa |
| ✅ **Correlación entre la nota del proceso y el desempeño posterior** | Validez predictiva **local** | Es lo que convierte la evidencia general de §2 en un dato propio |
| ✅ Fiabilidad entre entrevistadores (§4) | Fiabilidad del instrumento | Se corrige con calibración |
| ✅ Tasa de abandono por etapa | Coste que el proceso impone | Una etapa con abandono alto se rediseña |
| ✅ % de ofertas aceptadas y motivo del rechazo | Competitividad y experiencia | Con motivo, o es un número sin acción |

- **Cerrar el bucle es obligatorio.** Una organización que no compara la nota del proceso con el
  desempeño posterior **no sabe si su proceso funciona**, lleve veinte años usándolo o dos. Es
  exactamente la validación local que §2 exige y que ninguna cifra de meta-análisis sustituye.
- **Muestra pequeña, conclusiones prudentes.** Con 10 contrataciones al año no hay potencia
  estadística: **sirve para detectar fallos gruesos** (una etapa que nunca discrimina, un
  entrevistador que siempre diverge), no para afinar coeficientes. **Decirlo en voz alta evita el
  siguiente error**, que es tratar el dato propio con más confianza de la que soporta.

## 7. Sostenibilidad a largo plazo y prohibiciones

**Cadencia**: rúbrica revisada al abrir cada proceso; calibración de entrevistadores al menos
semestral y siempre que entre alguien nuevo al panel; etapas y su señal, semestral (test de §1);
plazos de conservación de datos, trimestral; **régimen legal de IA en empleo y transparencia
salarial, antes de cada cambio de herramienta y como mínimo semestral** (§8) — es lo que más se
mueve.

**Deprecación**: toda etapa se introduce con la condición que la haría innecesaria. Un proceso crece
por acumulación —una etapa por cada mala contratación recordada— y **nadie retira nunca nada**, hasta
que el proceso dura dos meses y solo lo terminan quienes no tienen alternativas.

PROHIBIDO:
- ❌ **Entrevistar sin rúbrica escrita antes del primer candidato.** Sin ella no se mide competencia,
  se mide impresión y luego se justifica.
- ❌ **Decidir por impresión**: "buenas vibraciones", "actitud", "energía", "no me convence" sin
  evidencia conductual citada contra la rúbrica.
- ❌ **Usar el "encaje cultural" como criterio** (§3.6). Se sustituye por valores y comportamientos
  observables con ancla.
- ❌ **Puntuar después de oír a los demás.** La evidencia y la nota se escriben antes del debate.
- ❌ **Pruebas de más de un límite razonable de tiempo sin pagarlas** (§3.4), y **premiar a quien se
  pasó del límite declarado**.
- ❌ **Usar el trabajo de un candidato en producción.**
- ❌ **Preguntas ilegales o irrelevantes**: edad, origen, situación familiar, embarazo, salud,
  discapacidad, religión, orientación, afiliación sindical — y **el salario anterior**. Tampoco "en
  confianza" ni fuera de la sala.
- ❌ **Cribar con un modelo sin validación local ni supervisión humana efectiva**, ni descartar a
  nadie sin que una persona con nombre lo confirme contra la rúbrica (§5.2).
- ❌ **Análisis de emociones, expresión facial, tono de voz o "engagement" del candidato**: prohibido
  en el lugar de trabajo por el artículo 5 del AI Act y, en todo caso, sin validez demostrada para
  el puesto (§5.2).
- ❌ **Vigilancia remota intrusiva durante una prueba** (captura continua de pantalla, seguimiento
  ocular, biometría).
- ❌ **Evaluar en secreto si el candidato usó IA**, o descartarlo por sospecha sin evidencia (§5.1).
- ❌ **Acertijos de algoritmos como filtro por defecto** para puestos que no hacen ese trabajo:
  miden mayoritariamente preparación específica para el formato (§3.3).
- ❌ **Cambiar la prueba o su dificultad según el candidato**: destruye la comparabilidad y es la vía
  silenciosa del sesgo.
- ❌ **Citar Schmidt-Hunter (1998) sin la corrección posterior**, o **dar una cifra de validez sin su
  año, su corrección y la advertencia de que la media no aplica a tu organización** (§2).
- ❌ **Usar "el coste de una mala contratación es 1,5× el salario"** o cualquier variante: sin estudio
  primario localizable (§2).
- ❌ **Optimizar el proceso por tiempo hasta cubrir el puesto** (§6). Se mejora bajando el listón.
- ❌ **Contratar en la duda por presión de calendario.** El empate es un "no", y una señal sobre el
  proceso.
- ❌ **Dejar candidatos sin respuesta**, o incumplir los plazos publicados sin avisar.
- ❌ **Guardar datos de candidatos sin base legal y sin plazo declarado**, o fuera del sistema con
  control de acceso.
- ❌ **Que pedir un ajuste razonable influya en la evaluación**, o quede registrado en la ficha.
- ❌ **Contactar con el empleador actual del candidato sin permiso explícito.**
- ❌ **Anclar la oferta al salario anterior del candidato** en lugar de al nivel del puesto (§5.3).
- ❌ **Publicar una oferta sin banda salarial** cuando la banda existe internamente.
- ❌ **Entrevistar sin haber hecho antes la prueba que se pone.**
- ❌ **Aplicar este documento como si fuera asesoramiento jurídico o de RR. HH.** (§1). Lo que tiene
  efecto legal se contrasta con asesoría legal y con RR. HH. antes de aplicarse.

## 8. Verificación web obligatoria

Antes de fijar cualquiera de estos puntos en un proceso real:

1. **AI Act y su aplazamiento — el punto más volátil.** Confirmar en **EUR-Lex / DOUE**: (a) que el
   *Digital Omnibus* se **publicó formalmente** y su número exacto de reglamento
   (`ai-governance-standards` lo referencia como **Reglamento (UE) 2026/1744**: **verificar**);
   (b) que la fecha de aplicación del **Anexo III, punto 4 (empleo)** es efectivamente el
   **2-dic-2027** y la del **Anexo I** el **2-ago-2028**; (c) que **artículo 5 (prohibiciones) y
   artículo 4 (alfabetización) siguen aplicándose desde el 2-feb-2025**. **Si el aplazamiento no
   llegó a publicarse antes del 2-ago-2026, rige el calendario original.** Citar siempre el texto
   del reglamento, **no un resumen de despacho**.
2. **Reconocimiento de emociones y frontera del artículo 5**: si las **directrices de la Comisión
   sobre prácticas prohibidas** se han actualizado, y **cómo delimitan "lugar de trabajo" respecto de
   un candidato externo**. Es la duda concreta que decide si una herramienta de vídeo-entrevista es
   legal: **se resuelve con asesoría legal, no con este documento.**
3. **Transparencia retributiva**: estado de la **transposición española** de la **Directiva (UE)
   2023/970** (a ago-2026: **plazo vencido el 7-jun-2026 sin transponer**, con consulta pública
   previa cerrada el 8-may-2026). Verificar si se ha aprobado el real decreto, si se ha abierto
   procedimiento de infracción, y **contrastar el calendario de reporte por tamaño de empresa contra
   el texto de la directiva**, no contra artículos de despacho — las fechas de §5.3 proceden de
   fuentes secundarias.
4. **Normas locales sobre IA en empleo**, si se contrata fuera de la UE: **NYC Local Law 144**
   (auditoría de sesgo, publicación, aviso de 10 días hábiles; y si el DCWP ha endurecido la
   aplicación tras la auditoría del Contralor de dic-2025), **Illinois HB 3773** (vigente desde
   1-ene-2026; estado del reglamento del IDHR, retirado en may-2026) y **Colorado** (SB 24-205
   suspendida judicialmente; **SB 26-189 con efecto 1-ene-2027**). **Este bloque caduca rápido:
   verificar el estado del mes en curso antes de cualquier despliegue.**
5. **España**: vigencia y redacción del **art. 64.4.d) ET** y estado de la jurisprudencia sobre el
   derecho de información algorítmica; y el **RD 902/2020** de igualdad retributiva.
6. **Validez predictiva — hueco declarado.** El **valor revisado de las muestras de trabajo** en
   Sackett et al. (2022) **no se extrajo en esta verificación** y por eso **no aparece cifrado en
   §2**. Obtenerlo de la **Tabla 3 del artículo original** antes de usarlo. Verificar igualmente si
   ha aparecido meta-análisis posterior a 2022-2023 que revise de nuevo estas estimaciones, y si el
   debate sobre la corrección por restricción de rango ha producido réplica publicada. **Nunca dar
   una cifra sin su método y su año.**
7. **Cualquier cifra sobre coste de contratación, rotación o productividad**: localizar estudio
   primario, año, muestra y método. Si no aparece, o si la cadena de citas termina en un blog
   comercial (caso del "1,5×" y del "30 % del DOL", §2), **no se usa**.
8. **Herramientas**: ATS y plataformas de evaluación — dónde alojan los datos, subencargados,
   transferencias internacionales, si realizan cribado automatizado y si publican auditoría de
   sesgo; accesibilidad real de la plataforma de código (§3.7). Para lo *open source*, **leer el
   `LICENSE` en crudo del repositorio**.
9. **Marco laboral y de no discriminación** de la jurisdicción concreta (en España, Estatuto de los
   Trabajadores, LO 3/2007 y convenio aplicable): qué preguntas son admisibles, qué obligaciones de
   igualdad aplican por tamaño de empresa y qué debe registrarse. **Con asesoría legal y con RR. HH.,
   siempre** (§1).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
