---
name: ai-governance-standards
description: Use when an organization must account for the AI it uses — building an AI system inventory and surfacing shadow AI, classifying systems into the EU AI Act tiers (prohibited practices, high-risk Annex I and Annex III, Article 50 transparency, minimal), deciding whether you are provider or deployer under Article 25 and when fine-tuning or repurposing turns you into a provider, GPAI duties under Articles 53-55 and the Code of Practice, the Regulation (EU) 2026/1744 Digital Omnibus dates, an internal acceptable-use policy and use-case approval process that does not drive staff into shadow AI, the Article 27 fundamental rights impact assessment and how it complements a DPIA, meaningful human oversight versus automation bias, synthetic content marking and disclosure, AI vendor due diligence (training on your data, retention, subprocessors, audit rights, exit), Article 73 serious incident reporting, an ISO/IEC 42001 AI management system with ISO/IEC 42005 and 42006, NIST AI RMF as a governance framework, AESIA and national supervisory authorities, or governance metrics that change decisions instead of filling a report.
---

# Estándares de gobierno de la IA

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **No es asesoramiento jurídico.** Esta skill fija **criterio de ingeniería y de gestión** para
> construir sistemas y procesos que puedan cumplir, y para saber qué preguntar. La calificación
> legal de un caso concreto, la interpretación de un artículo y la decisión de notificar son de
> **legal / DPO / la autoridad competente**. Cuando una fecha o una obligación decida algo,
> **se verifica en la fuente oficial** (§8), no aquí y no de memoria.

## 1. Alcance y triggers

Aplica cuando una organización tiene que **saber qué IA usa, decidir qué puede hacer con ella y
responder por el resultado**. Es la capa de **decisión y rendición de cuentas**, no la de
construcción: inventario de sistemas de IA, clasificación por riesgo, reparto de roles y
obligaciones, política de uso interno y aprobación de casos, evaluación de impacto, supervisión
humana, transparencia, adquisición y terceros, incidentes, marcos de gestión y métricas.

Triggers: "inventario de sistemas de IA", "IA en la sombra", "shadow AI", "¿esto es alto riesgo?",
"Anexo III", "Anexo I", "proveedor o responsable del despliegue", "deployer", "¿el fine-tuning me
convierte en proveedor?", "GPAI", "modelo de propósito general", "riesgo sistémico", "Código de
buenas prácticas", "art. 50", "marca de agua", "contenido sintético", "EIDF", "FRIA", "evaluación
de impacto en derechos fundamentales", "supervisión humana", "human in the loop", "sesgo de
automatización", "política de uso de IA", "¿puedo meter esto en ChatGPT?", "aprobar un caso de
uso", "cláusula de IA en el contrato", "¿entrenan con nuestros datos?", "incidente grave de IA",
"notificar a la autoridad", "ISO 42001", "SGIA", "AIMS", "NIST AI RMF", "AESIA", "delegado de IA",
"comité de IA", "AI Act", "Reglamento (UE) 2024/1689", "Reglamento (UE) 2026/1744".

**Tesis del dominio — se aplica en todo el documento**: **el gobierno que no cambia ninguna
decisión es teatro.** Un control que produce un documento y nunca detiene, modifica ni retrasa un
despliegue no es un control: es coste con apariencia de diligencia. El test de cada mecanismo de
esta skill es el mismo — *¿alguna vez ha dicho que no, o ha cambiado cómo se hace algo?* Si la
respuesta es no en doce meses, el mecanismo está roto o es innecesario. Corolario incómodo: la
mayoría de los "comités de IA" y de las "políticas de IA" existentes fallan este test.

**No aplica**:

- **`grc-compliance-standards`** — *frontera principal, regla de arbitraje en una línea*: **el
  sistema de gestión general es suyo; la extensión específica de IA es mía.** Suyo: ISO/IEC
  27001:2022 y su Anexo A, la metodología de riesgo corporativo (ISO 27005, MAGERIT/PILAR, FAIR),
  la **Declaración de Aplicabilidad**, el registro de riesgos, la evidencia de auditoría y su
  mapeo control→evidencia, NIST CSF 2.0, CIS, SOC 2, ENS, NIS2, DORA, el TPRM genérico y la
  jerarquía documental. Mío: **ISO/IEC 42001 como SGIA, el AI Act, el inventario de sistemas de
  IA, la clasificación por riesgo de IA, la supervisión humana y las obligaciones específicas de
  proveedor/desplegador.** Consecuencia operativa: **el riesgo de IA se integra en el registro de
  riesgos corporativo de `grc`, no vive en un registro paralelo**; y el SGIA se implanta como
  extensión del SGSI existente, no como un sistema duplicado (§3.7).
- **`privacy-engineering-standards`** — *se cruzan de verdad, y aquí está la línea*: **suyo el
  dato personal y su ingeniería** — base de licitud del entrenamiento, minimización, retención y
  borrado, derechos del interesado, **DPIA/EIPD**, seudonimización y anonimización,
  **memorización del modelo** y extracción de datos de entrenamiento, transferencias
  internacionales, PII en telemetría. **Mío**: la **evaluación de impacto en derechos
  fundamentales (art. 27)**, la **clasificación de riesgo del AI Act**, el reparto de roles
  proveedor/desplegador y las obligaciones que de ahí derivan. **Se cruzan en el art. 27(4)**: la
  FRIA *complementa* la DPIA, no la sustituye — el diseño conjunto está en §3.5. **Sus plazos del
  AI Act son fuente y no se contradicen**: los de esta skill se han verificado
  independientemente contra el DOUE y **coinciden**; si alguna vez divergen, gana la fuente
  oficial y se corrigen ambas skills.
- **`mlops-standards`**: **opera; aquí se decide y se
  responde.** El **registro de modelos** —artefactos que tu organización entrena y sirve, con su
  linaje, métricas y promoción— es suyo. El **inventario de sistemas de IA** es mío y **es otra
  cosa**: incluye herramientas SaaS de terceros que tú no operas, IA embebida en productos que ya
  compraste, y la IA en la sombra que nadie registró. **Un modelo puede estar en su registro y no
  en mi inventario (y al revés), y ambos casos son un fallo.** Además: el *fairness* como
  **número medido** es suyo (su §6.5); **qué disparidad es aceptable, quién lo firma y qué pasa
  si se supera, es mío**.
- **`mlsecops-standards`**: seguridad del ciclo de vida y de la cadena de
  suministro del modelo — procedencia y firma de pesos, envenenamiento, *backdoors*, extracción,
  inversión, *red teaming*, AIBOM, MITRE ATLAS, OWASP GenAI. Vocabulario compartido inevitable:
  ambos citamos **NIST AI RMF** y artículos del **AI Act**. La línea: **allí el RMF y el art. 15
  se usan para elegir e implantar controles técnicos frente a un adversario; aquí para
  estructurar la rendición de cuentas de la organización.** Si la pregunta es "¿qué control
  técnico pongo?", es suya; si es "¿quién responde, con qué evidencia y ante quién?", es mía.
  Un **incidente de seguridad** de un sistema de IA puede ser a la vez incidente técnico (suyo) e
  **incidente grave notificable del art. 73** (§3.8, mío).
- `llm-evaluation-standards`: **la medición de calidad es suya**. Aquí se
  **exige** evaluación documentada como condición de aprobación de un caso de uso, pero la
  metodología (eval sets, jueces, calibración, significancia) vive allí.
- `llm-app-engineering-standards`, `rag-standards`, `ai-agents-standards`, `mcp-standards`,
  `local-inference-standards`, `gpu-computing-standards`: **construcción**.
  Aquí no se dice cómo se escribe un prompt ni cómo se acota un bucle de agente; se dice qué casos
  de uso están permitidos, quién lo aprueba y qué hay que poder demostrar después.
- **`claude-api`** (sin sufijo `-standards`, **skill instalada, referencia canónica del lado
  Anthropic**): IDs de modelo, precios, parámetros, retención y comportamiento de la API. Si una
  decisión de gobierno depende de un dato concreto de Anthropic —qué se retiene, qué se usa para
  entrenar, qué límites hay—, **sale de ahí o del contrato**, nunca de memoria.
- `incident-management-standards`: **el proceso de gestión del incidente** — declaración,
  severidad, roles, comunicación, postmortem. Aquí solo **qué cuenta como incidente grave de IA y
  a quién hay que notificarlo** (§3.8): el proceso que lo gestiona es suyo y no se duplica.
- `incident-response-forensics-standards` (respuesta técnica y forense),
  `identity-access-management-standards` (quién accede a qué herramienta de IA y con qué
  identidad — **el control técnico que hace cumplir la política de §3.4**),
  `secrets-management-standards`, `vulnerability-management-standards`, `appsec-standards`,
  `bcdr-standards` (**dependencia de un proveedor de IA como riesgo de continuidad**, §5),
  `data-platform-standards`, `observability-standards`, `sre-practice-standards`,
  `cicd-standards`, `kubernetes-standards`, `offensive-security-standards`.
- **`technical-hiring-standards`** — *cruce con obligación legal real*: **mío el
  encuadre normativo** —clasificación del sistema de cribado como alto riesgo del Anexo III punto 4,
  papel de proveedor frente a desplegador, evaluación de impacto en derechos fundamentales,
  supervisión humana significativa, registro en el inventario de sistemas de IA—; **suyo el diseño
  del proceso de selección**: rúbrica, formatos de entrevista, validez predictiva y qué evidencia se
  acepta para decidir. Dos avisos que ninguna de las dos debe suavizar: **las fechas del Anexo III
  para empleo se aplazaron a diciembre de 2027**, pero **las prohibiciones del artículo 5 se aplican
  desde febrero de 2025** — y entre ellas está el **reconocimiento de emociones en el lugar de
  trabajo**, lo que alcanza al análisis automatizado de vídeo-entrevistas.

## 2. Decisiones por defecto

> Verificar en fuente oficial antes de fijar cualquier fecha, artículo o edición de norma (§8).
> **En este dominio una fecha mal citada es el peor error posible**: decide presupuestos,
> contratos y exposición sancionadora.

| Decisión | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| Marco de gestión certificable | **ISO/IEC 42001:2023** (1.ª edición, vigente) como SGIA, **integrado** con el SGSI de ISO 27001 | Montar un SGIA independiente y paralelo: duplica cláusulas 4-10, gobierno y auditoría, y garantiza divergencia |
| Certificación acreditada del SGIA | Posible: **ISO/IEC 42006:2025** fija los requisitos de las entidades que auditan y certifican SGIA | Aceptar un "certificado 42001" de una entidad no acreditada: verificar la acreditación, no el logotipo |
| Evaluación de impacto del sistema de IA | **ISO/IEC 42005:2025** como guía metodológica | **No es certificable ni sustituye a la FRIA del art. 27 ni a la DPIA**: es método, no cumplimiento |
| Marco de riesgo no regulatorio / interlocución técnica | **NIST AI RMF 1.0** (AI 100-1, ene-2023) con el perfil de IA generativa **NIST AI 600-1** (26-jul-2024) | Ambos siguen siendo las versiones vigentes: **no hay revisión publicada** a ago-2026. Citar un "AI RMF 2.0" es inventarlo |
| Marco regulatorio aplicable en la UE | **Reglamento (UE) 2024/1689 (AI Act)**, modificado por el **Reglamento (UE) 2026/1744** (*Digital Omnibus on AI*) | Trabajar con el texto original de 2024 sin las modificaciones de 2026: los plazos ya no son esos (§3.3) |
| Punto de partida del programa | **Inventario primero** (§3.1). Sin inventario, todo lo demás es hipótesis | Empezar por la política: se escribe sobre un mundo imaginario y nadie la cumple |
| Postura frente a la IA en la sombra | **Legalizar y encauzar**: una vía aprobada, rápida y usable | **Prohibición general sin alternativa**: no reduce el riesgo, lo hace invisible (§3.4) |
| Alcance del gobierno | **Todo sistema de IA que toque decisión, dato o persona**, sea propio, comprado o embebido | Gobernar solo lo que construye el equipo de datos: es la minoría del inventario real |
| Documentación del sistema | **Model card / ficha del sistema obligatoria** como condición de alta en el inventario | Documentación técnica que solo existe cuando la pide un auditor |
| Autoridad nacional (España) | **AESIA** (RD 729/2023, sede en A Coruña) como autoridad central; **AEPD**, **Banco de España** y **CGPJ** como autoridades de vigilancia sectoriales | **Régimen sancionador nacional: aún en tramitación** (§3.3). No afirmar que existe ni que no existe sin comprobarlo |

## 3. Estructura y convenciones

### 3.1 Inventario de sistemas de IA — no se gobierna lo que no se sabe que existe

Es el artefacto fundacional. Sin él no hay clasificación, ni evaluación, ni supervisión, ni
respuesta a una autoridad. **Alcance**: no solo modelos propios. Entra en el inventario:

1. Modelos entrenados o afinados por la organización (los del registro de `mlops-standards`).
2. **Aplicaciones que consumen un modelo de terceros** por API.
3. **Funcionalidad de IA embebida en software que ya compraste** — la categoría más olvidada, y a
   menudo la más numerosa: el CRM que ahora puntúa leads, el ATS que ordena currículums, el
   antifraude del proveedor de pagos, el asistente del suite ofimático.
4. **Herramientas usadas por empleados**, aprobadas o no (§3.2).

**Campos mínimos por entrada** (si un campo no se puede rellenar, eso *es* el hallazgo):
dueño de negocio nombrado · propósito y decisión que influye · **rol de la organización**
(proveedor / responsable del despliegue / ambos, §3.2) · clasificación de riesgo y su
justificación escrita · datos que trata (con enlace al RoPA si hay personales) · proveedor y
contrato · **naturaleza y punto de la supervisión humana** · evaluación realizada y fecha ·
fecha de revisión · estado del ciclo de vida.

**El inventario se mantiene con telemetría, no con encuestas.** Un inventario que depende de que
la gente lo declare mide honestidad, no realidad. Fuentes contrastables: CASB/proxy de salida y
logs DNS (dominios de herramientas de IA), gasto en tarjetas corporativas y facturación SaaS,
concesiones OAuth a aplicaciones de terceros en el IdP, extensiones de navegador, e inventario de
software. Revisión con cadencia fija y **dueño**; sin dueño, caduca en un trimestre.

### 3.2 IA en la sombra — el punto de partida real

**Ningún programa de gobierno empieza en cero: empieza con IA en la sombra ya instalada.** Las
encuestas de 2026 convergen en un rango amplio pero inequívoco —del ~45 % al ~81 % de empleados
usando herramientas de IA no aprobadas según metodología, con una fracción sustancial
introduciendo dato de cliente o interno— y coinciden en dos hallazgos incómodos: **la dirección
es tan infractora como la plantilla o más**, y **la mayoría prefiere no preguntar antes que
arriesgarse a un "no"**. (Cifras concretas: verificar en §8; varían mucho por estudio y no se
citan aquí como dato duro.)

Lectura operativa, no moral: **la IA en la sombra es una señal de demanda no atendida.** Se
combate con una vía aprobada que sea *más rápida* que la no aprobada, no con un bloqueo. Y se
mide: la métrica útil no es "incidentes de shadow AI" sino **cuánto tarda un empleado en
conseguir una herramienta aprobada** (§6.1).

**Roles: proveedor frente a responsable del despliegue.** Es la distinción que decide qué
obligaciones te tocan, y casi todo el mundo se autoclasifica mal a la baja. Texto literal del
**art. 25(1)** del AI Act — un distribuidor, importador, responsable del despliegue u otro
tercero pasa a considerarse **proveedor** de un sistema de alto riesgo cuando:

> (a) "they put their name or trademark on a high-risk AI system already placed on the market or
> put into service";
> (b) "they make a substantial modification to a high-risk AI system that has already been placed
> on the market or has already been put into service in such a way that it remains a high-risk AI
> system";
> (c) "they modify the intended purpose of an AI system, including a general-purpose AI system,
> which has not been classified as high-risk and has already been placed on the market or put into
> service in such a way that the AI system concerned becomes a high-risk AI system".

**Consecuencia práctica que hay que decir en voz alta**: coger un modelo de propósito general y
**afinarlo o reorientarlo hacia un uso del Anexo III** —cribar candidatos, puntuar solvencia—
encaja de lleno en la letra (c) y **te convierte en proveedor**, con documentación técnica,
sistema de gestión de riesgos, evaluación de conformidad y registro. Marcar el propio logo sobre
un sistema de alto riesgo ajeno (letra a) hace lo mismo. **Ninguna de las dos cosas parece una
decisión regulatoria cuando se toma**: parecen decisiones de producto o de marca. Por eso el rol
se determina **en el alta del inventario**, con legal, y se re-evalúa en cada cambio de propósito.

### 3.3 Clasificación por riesgo y calendario — verificado

Cuatro niveles del AI Act: **prácticas prohibidas** (art. 5) · **alto riesgo** (Anexo I, sistemas
embebidos en productos ya regulados; Anexo III, casos de uso autónomos) · **riesgo limitado** con
obligaciones de **transparencia** (art. 50) · **mínimo** (sin obligaciones específicas). Encima,
un eje transversal: los modelos de **propósito general (GPAI)**, arts. 53-55.

**Calendario efectivo verificado contra el DOUE (ago-2026).** El *Digital Omnibus on AI* es el
**Reglamento (UE) 2026/1744, de 8 de julio de 2026**, que modifica los Reglamentos (UE) 2024/1689,
2018/1139 y 2023/1230; votado por el Parlamento el **16-jun-2026**, aprobado por el Consejo el
**29-jun-2026**, publicado en el DOUE el **24-jul-2026** y **en vigor el 27-jul-2026**. Reescribe
el párrafo tercero del art. 113 del AI Act.

| Fecha | Qué aplica | Estado |
|---|---|---|
| **2-feb-2025** | Prácticas **prohibidas** (art. 5) y alfabetización en IA (art. 4) | **Sin cambios** por el Omnibus |
| **2-ago-2025** | Obligaciones de **GPAI** (arts. 53-55); gobernanza; techos sancionadores del art. 99 | **Sin cambios**. Modelos ya en el mercado antes de esa fecha: transitorio hasta **2-ago-2027** |
| **27-jul-2026** | Arts. 102-110 del AI Act (modificaciones de legislación sectorial), por el nuevo punto (d) del art. 113 párr. 3 | Entrada en vigor del Omnibus |
| **2-ago-2026** | **Transparencia del art. 50** y fecha general de aplicación. Salvedad: el **art. 50(2) no aplica** a sistemas ya introducidos en el mercado a esa fecha. Inicio de la **ejecución** por la Comisión sobre GPAI | **Sigue vigente** — el Omnibus **no** la movió |
| **3-ago-2026** | Supervisión nacional del art. 4 (alfabetización, reescrito como deber de *tomar medidas para apoyar* su desarrollo) | Nuevo |
| **2-dic-2026** | **Art. 50(2)** (marcado de contenido sintético por proveedores) + **nuevas prohibiciones del art. 5**: imágenes íntimas no consentidas generadas por IA y material de abuso sexual infantil | Nuevo |
| **2-ago-2027** | Los Estados miembros deben tener al menos un **sandbox regulatorio** nacional (aplazado desde 2-ago-2026) | Aplazado |
| **2-dic-2027** | **Alto riesgo del Anexo III** (autónomos): antes 2-ago-2026. Afecta a las **Secciones 1, 2 y 3 del Capítulo III, excluido el art. 6(5)** | **Aplazado 16 meses** |
| **2-ago-2028** | **Alto riesgo del Anexo I** (embebido en producto regulado): antes 2-ago-2027 | **Aplazado** |

**Estas son fechas de respaldo absolutas**, independientes de que existan o no normas armonizadas.
Dos advertencias de criterio: **(1)** el aplazamiento del alto riesgo **no es una moratoria del
AI Act** — prohibiciones, GPAI y transparencia siguen su curso, y el RGPD y la normativa sectorial
aplican íntegros con AI Act o sin él; **(2)** un aplazamiento de 16 meses **no es tiempo libre**:
la documentación técnica, la gestión de riesgos y la evaluación de conformidad de un sistema de
alto riesgo tardan más que eso si se empiezan tarde.

**GPAI**: las obligaciones de los arts. 53-55 **están en aplicación desde ago-2025** y el Omnibus
**no las tocó**. El **Código de buenas prácticas** para modelos de propósito general fue publicado
por la Oficina de IA el **10-jul-2025** y su **adecuación fue confirmada** por la Comisión y el
Consejo de IA el **1-ago-2025**; tres capítulos (transparencia, derechos de autor, y seguridad
para modelos con riesgo sistémico). Matiz que decide arquitectura contractual: **adherirse al
Código es un medio voluntario adecuado de demostrar cumplimiento, pero NO es presunción de
conformidad en sentido técnico** — esa figura está reservada por el art. 40 a las normas
armonizadas europeas, cuya adopción bajo el mandato CEN-CENELEC sigue en curso. El no firmante
debe demostrar cumplimiento por otros medios adecuados y, en la práctica, soporta más
requerimientos de información.

**España**: la **AESIA** existe desde el **RD 729/2023** (sede en A Coruña) y fue la primera
autoridad nacional de este tipo en la UE. El **Proyecto de Ley Orgánica** para el buen uso y la
gobernanza de la IA —que designa autoridades y establece el **régimen sancionador nacional**— fue
aprobado en Consejo de Ministros el **26-may-2026** y sigue en **tramitación parlamentaria**: a la
fecha de verificación **no estaba aprobado definitivamente ni en vigor**. Reparto de supervisión
previsto: AESIA como organismo central, **AEPD** (datos), **Banco de España** (sistema
financiero), **CGPJ** (justicia); los productos ya regulados sectorialmente conservan su autoridad.
**No des por hecho el estado de esta ley en ninguna dirección: verifícalo (§8).**

### 3.4 Política de uso interno y aprobación de casos

Una política de IA útil responde a **una pregunta concreta que un empleado se hace a las 16:00**:
*¿puedo meter esto en esa herramienta?* Se responde con una matriz **dato × herramienta**, no con
principios:

- **Clasificación de dato** reutilizada de la que ya existe (`grc-compliance-standards`), no una
  nueva inventada para IA.
- **Niveles de herramienta**: aprobada con contrato empresarial (y qué dato admite cada una),
  aprobada solo para dato público, y **prohibida**.
- Reglas que **no dependen del criterio del empleado**: "no metas nada confidencial" no es una
  regla, es un traslado de responsabilidad. "Dato de cliente solo en la herramienta X, en el
  tenant Y" sí lo es.
- La política se **hace cumplir con controles técnicos** (IdP, proxy de salida, DLP,
  aprovisionamiento SSO) —ver `identity-access-management-standards`— porque una política que solo
  vive en un PDF firmado en el onboarding no gobierna nada.

**Aprobación de casos de uso**: proporcional al riesgo y con **SLA publicado**. Vía rápida
(días, autoservicio con registro) para casos de riesgo mínimo con dato no sensible; revisión
completa para lo demás. **Si aprobar tarda semanas, has diseñado un generador de IA en la sombra**
(§3.2). El expediente de aprobación contiene: propósito, dato, rol (§3.2), clasificación de riesgo
y su motivo, evaluación realizada, diseño de la supervisión humana, criterio de retirada y dueño.

### 3.5 Evaluación de impacto — FRIA y su relación con la DPIA

**Precisión que casi todo el mundo se salta: la FRIA del art. 27 NO obliga a todo desplegador de
alto riesgo.** Texto literal del **art. 27(1)**:

> "Prior to deploying a high-risk AI system […] deployers that are **bodies governed by public
> law**, or are **private entities providing public services**, and deployers of high-risk AI
> systems referred to in **points 5(b) and (c) of Annex III**, shall perform an assessment of the
> impact on fundamental rights […]"

Es decir: sector público, privados que prestan servicios públicos, y los dos casos concretos del
punto 5 del Anexo III. Un desplegador privado de un sistema de alto riesgo fuera de ese perímetro
**no tiene la obligación del art. 27** (lo que no le exime del resto de deberes del desplegador).
Afirmar lo contrario infla el alcance y quema credibilidad del programa.

**Relación con la DPIA** — texto literal del **art. 27(4)**:

> "If any of the obligations laid down in this Article is already met through the data protection
> impact assessment conducted pursuant to Article 35 of Regulation (EU) 2016/679 […] the
> fundamental rights impact assessment […] shall **complement** that data protection impact
> assessment."

**Complementa, no sustituye, y no al revés**: son evaluaciones de objeto distinto —la DPIA mira el
riesgo para el dato personal y el interesado; la FRIA, el impacto en derechos fundamentales de las
personas afectadas por el uso del sistema—. Diseño recomendado: **un procedimiento único con dos
secciones y un disparador común**, ejecutado por el mismo equipo, con la DPIA gobernada por
`privacy-engineering-standards` y la sección de derechos fundamentales por esta skill. **Dos
procesos separados producen dos documentos que se contradicen.** Si no hay dato personal, puede
haber FRIA sin DPIA; si hay dato personal y no es alto riesgo, DPIA sin FRIA.

Disparadores de re-evaluación: cambio de propósito, de población afectada, de proveedor o de
modelo subyacente; y **cambio de versión del modelo del proveedor**, que ocurre sin avisarte y es
el disparador que nadie tiene automatizado.

### 3.6 Supervisión humana significativa — donde el gobierno se vuelve diseño

Es el punto donde una obligación de papel se convierte en un requisito de producto, y donde más
programas fracasan. **Un humano que aprueba en masa no es supervisión: es una firma.**

El **sesgo de automatización** —la tendencia a aceptar la recomendación de la máquina, más fuerte
cuanto mayores son la carga de trabajo, la presión de tiempo y la aparente precisión del
sistema— no se corrige con formación ni con un aviso en pantalla. Se corrige con **diseño**.
Condiciones mínimas para que la supervisión sea real, todas necesarias:

1. **Información**: el supervisor ve la entrada, la salida **y por qué** (factores, incertidumbre,
   casos similares). Una puntuación sin contexto no es supervisable.
2. **Tiempo**: el ritmo de trabajo permite revisar de verdad. Si el objetivo de productividad se
   fijó asumiendo que se acepta la recomendación, la supervisión ya es ficticia por diseño.
3. **Autoridad real para revertir**, sin coste personal: la desviación no penaliza en la
   evaluación de desempeño y no exige justificar más que la aceptación. **Si contradecir al
   sistema es más caro que aceptarlo, nadie lo contradice.**
4. **Competencia**: el supervisor entiende el dominio y las limitaciones del sistema.
5. **Medición**: se registra la **tasa de anulación** (*override*) y se investiga. Una tasa
   cercana a cero **no es una buena noticia**: o el modelo es perfecto, o la supervisión no
   existe — y casi siempre es lo segundo. Una tasa muy alta indica que el modelo no aporta.

Trata la tasa de anulación y su distribución como **SLI del control**, con revisión periódica y
un dueño. Es la métrica más honesta de todo este documento.

### 3.7 Terceros, adquisición y dependencia

Casi toda la IA de una organización es de otro. Lo que hay que exigir **por contrato**, con
respuesta escrita antes de firmar:

- **Uso de tus datos para entrenar o mejorar el modelo**: por defecto **no**, y por escrito. Que
  no esté activado hoy en la consola no es un compromiso contractual.
- **Retención**: cuánto se guardan entradas y salidas, dónde, y si hay retención por revisión de
  abuso o por requerimiento legal. Es el dato que suele romper la evaluación de privacidad.
- **Subencargados y ubicación** del tratamiento y de la inferencia; régimen de transferencias
  internacionales (`privacy-engineering-standards`).
- **Evaluaciones y documentación**: qué evaluó el proveedor, sobre qué población, con qué
  resultado. Un *system card* de marketing no es documentación técnica.
- **Derecho de auditoría** o, en su defecto, certificación acreditada equivalente (ISO 42001 con
  entidad acreditada bajo 42006, SOC 2) y su informe completo, no el resumen público.
- **Notificación de cambios**: cambio de modelo subyacente, de versión o de comportamiento, con
  preaviso. Sin esto, tu evaluación caduca en silencio.
- **Notificación de incidentes** en plazo compatible con tus propias obligaciones (§3.8): si el
  proveedor te avisa en 30 días, no puedes cumplir un plazo de 2.
- **Salida**: portabilidad de datos y de configuración, y qué pasa con tus *prompts*, *embeddings*
  y ajustes al terminar.

**Dependencia como riesgo de continuidad**, no solo de coste: un proveedor puede retirar un
modelo, cambiar precios, cambiar comportamiento o desaparecer. Si un proceso de negocio depende de
un modelo concreto, el **plan de degradación** —a otro proveedor, a un modelo abierto, a una regla,
o a decisión humana— se diseña y se prueba (`bcdr-standards`). El TPRM genérico —tiering,
cuestionarios, registro de proveedores— es de `grc-compliance-standards`: **aquí solo lo específico
de IA**.

### 3.8 Incidentes de IA

Un fallo de modelo con impacto se gestiona con el proceso de `incident-management-standards`. Lo
específico de aquí es **qué cuenta como grave y a quién se notifica**.

El **art. 3(49)** define *incidente grave* como un incidente o defecto de funcionamiento de un
sistema de IA que directa o indirectamente cause: **(a)** el fallecimiento o daño grave a la salud
de una persona; **(b)** una perturbación grave e irreversible de la gestión u operación de
infraestructuras críticas; **(c)** la infracción de obligaciones del Derecho de la Unión
destinadas a proteger derechos fundamentales; **(d)** daños graves a la propiedad o al medio
ambiente.

**Art. 73(1)**: *"Providers of high-risk AI systems placed on the Union market shall report any
serious incident to the market surveillance authorities of the Member States where that incident
occurred."* Plazos, literales:

| Supuesto | Plazo |
|---|---|
| General (art. 73(2)) | *"not later than **15 days** after the provider or, where applicable, the deployer, becomes aware of the serious incident"* |
| Infracción generalizada o incidente grave del art. 3(49)(b) (art. 73(3)) | *"not later than **two days** after […] becomes aware of that incident"* |
| Fallecimiento (art. 73(4)) | *"not later than **10 days** after the date on which […] becomes aware of the serious incident"* |

Vía paralela y distinta: los proveedores de **GPAI con riesgo sistémico** notifican incidentes
graves **a la Oficina de IA** conforme al **art. 55(1)(c)**, sin demora indebida. La Comisión
publicó **guía en borrador sobre la notificación del art. 73 (26-sep-2025)**; verificar si ya hay
versión definitiva (§8).

**Implicación de ingeniería, que es lo que aporta esta skill**: un plazo de **dos días** es
incompatible con descubrir el impacto revisando registros a mano. Exige, *antes* del incidente:
logging suficiente y retenido del sistema de IA, capacidad de reconstruir qué versión de modelo
sirvió qué decisión y a quién afectó, un canal de detección que no dependa de una queja de cliente,
y un procedimiento con dueño de guardia. **La notificación se prepara en tiempo de diseño; en
tiempo de incidente ya es tarde.** La decisión de notificar es de legal/DPO; **poder hacerlo es
tuya**.

### 3.9 Transparencia y contenido sintético

- **Informar de que se interactúa con una IA** (art. 50): en el punto de interacción, no enterrado
  en los términos de servicio. Aplica desde **2-ago-2026**.
- **Marcado de contenido sintético** por el proveedor (art. 50(2)): desde **2-dic-2026**, y **no**
  aplica a sistemas ya introducidos en el mercado a 2-ago-2026. **Honestidad técnica obligatoria**:
  las marcas de agua en texto son frágiles y las de imagen se pierden con recorte, recompresión o
  reedición; los metadatos de procedencia (esquemas de firma de contenido) son verificables pero
  se eliminan trivialmente y su verificación depende de que el consumidor la implemente. **Es una
  medida de trazabilidad, no un control anti-abuso**: no la vendas internamente como lo segundo.
  Verificar el estado real de la interoperabilidad de estos esquemas antes de comprometerse (§8).
- **Documentación técnica y model card** como condición de alta en el inventario (§3.1) — no como
  entregable de auditoría. Ver `mlops-standards` §3.3 para el contenido del artefacto.

## 4. Gates de gobierno

Controles que **bloquean**, en orden de coste creciente. Si ninguno ha bloqueado nada en doce
meses, revisa si son reales (§1).

1. **Alta en el inventario** antes del primer uso productivo. Sistema no inventariado = no
   autorizado. Es el gate más barato y el que más cosas atrapa.
2. **Determinación del rol** (proveedor / desplegador, §3.2) con legal, registrada. Bloquea hasta
   estar decidida.
3. **Clasificación de riesgo** documentada **con su motivo**. "Riesgo mínimo" sin justificación
   escrita no pasa: es la casilla que se marca por defecto para no hacer el trabajo.
4. **Evaluación de impacto** (DPIA y/o FRIA, §3.5) completada cuando se dispare, **antes** del
   despliegue, no en paralelo.
5. **Diseño de la supervisión humana** revisado contra las cinco condiciones de §3.6. Un "hay un
   humano revisando" sin las cinco no pasa.
6. **Evidencia de evaluación de calidad y de sesgo** (metodología en `llm-evaluation-standards` y
   `mlops-standards`) dentro de los umbrales acordados.
7. **Cláusulas contractuales de §3.7** cerradas antes de que el dato salga de la organización.
8. **Capacidad de notificación** verificada (§3.8): logging, trazabilidad de versión y dueño de
   guardia, probados.
9. **Fecha de revisión y criterio de retirada** asignados. Un sistema sin fecha de caducidad de la
   evaluación es un sistema que se auditará solo cuando falle.

**Evidencia**: cada gate deja registro con fecha, decisión, motivo y quién decidió, en el sistema
de evidencia de `grc-compliance-standards` — **no en un directorio compartido**. Auditoría interna
del SGIA con cadencia y revisión por la dirección con acta y decisiones: si el acta no contiene
ninguna decisión, la revisión no ocurrió.

## 5. Riesgos específicos que el gobierno debe cubrir

- **Fuga de dato por herramienta no aprobada** (§3.2): el vector más frecuente y el menos
  sofisticado. Control: identidad, salida de red y una alternativa aprobada usable.
- **Decisión automatizada sin base ni recurso**: si el sistema decide sobre personas, hay que
  poder explicar la decisión concreta y ofrecer revisión humana. El régimen del art. 22 RGPD y
  el AI Act se superponen; coordinar con `privacy-engineering-standards` y legal.
- **Sesgo con impacto en derechos**: se mide (`mlops-standards` §6.5), tiene umbral acordado y
  dueño, y se re-mide en producción. Sin umbral escrito, la medición no gobierna nada.
- **Reclasificación silenciosa**: el sistema de riesgo mínimo que alguien reorienta hacia un caso
  del Anexo III y **te convierte en proveedor** (§3.2, art. 25(1)(c)) sin que nadie lo note. El
  control es el disparador de re-evaluación por cambio de propósito (§3.5).
- **Cambio de modelo del proveedor** que invalida tu evaluación sin que cambies una línea de
  código.
- **Deriva del alcance del SGIA**: si el sistema de gestión cubre tres sistemas y el inventario
  tiene ochenta, el certificado no significa lo que la gente cree.

## 6. Métricas de gobierno

### 6.1 Las que sirven

| Métrica | Qué revela |
|---|---|
| **% del inventario descubierto por telemetría y no declarado** | Calidad real del proceso de alta; si es alto, el inventario es voluntarista |
| **Tiempo desde solicitud hasta herramienta/caso aprobado** | El predictor nº 1 de IA en la sombra (§3.4). Si sube, la sombra crece |
| **Tasa de anulación humana** (§3.6), por sistema y por operador | Si es ~0, la supervisión probablemente no existe |
| **Nº de casos **rechazados o modificados** por el proceso de aprobación** | Si es 0, el proceso es un sello |
| **Sistemas con evaluación caducada** | Deuda de gobierno acumulada, medible |
| **Tiempo desde detección de un fallo de modelo hasta decisión de notificar** | Capacidad real frente a los plazos del art. 73 (§3.8) |
| **Cobertura del inventario sobre el gasto en IA** | Contraste contra facturación: encuentra lo que nadie declaró |

### 6.2 Las que solo llenan un informe

Número de políticas publicadas · empleados que hicieron el curso · reuniones del comité de IA ·
sistemas "conformes" sin criterio de conformidad definido · un porcentaje de cumplimiento que
nunca baja. Todas comparten el mismo defecto: **suben aunque el riesgo suba**.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: este dominio se revisa cada **3 meses**. En 2025-2026 se movieron plazos legales,
  cambió el texto del Reglamento y se publicaron normas de apoyo. **La §8 es lo que separa este
  documento de una fuente de errores caros.**
- **Integración sobre duplicación**: SGIA dentro del SGSI, riesgo de IA en el registro corporativo,
  FRIA junto a la DPIA, incidentes en el proceso de incidentes existente. Cada estructura paralela
  que crees divergirá y habrá que auditarla dos veces.
- **Proporcionalidad**: el peso del gobierno escala con el riesgo del caso. Un clasificador interno
  de tickets no lleva el mismo expediente que un sistema de cribado de candidatos. Un programa
  que trata todo igual se ignora entero.

**PROHIBIDO**
- ❌ Citar una fecha, un artículo o un plazo del AI Act **de memoria**. Siempre fuente oficial.
- ❌ Afirmar que el aplazamiento del alto riesgo es una moratoria del AI Act, o que el RGPD espera.
- ❌ Presentar esta skill —o cualquier análisis derivado— como asesoramiento jurídico.
- ❌ Empezar el programa por la política en vez de por el inventario.
- ❌ Prohibición general de herramientas de IA sin ofrecer una alternativa aprobada y rápida.
- ❌ Inventario mantenido solo con encuestas y declaraciones voluntarias.
- ❌ Clasificar como "riesgo mínimo" sin justificación escrita.
- ❌ Autoclasificarse como desplegador tras afinar o reorientar un modelo hacia un caso del
  Anexo III — es art. 25(1)(c) y te convierte en **proveedor**.
- ❌ Extender la obligación de FRIA a todo desplegador de alto riesgo: el art. 27(1) delimita el
  perímetro (§3.5). Inflar el alcance quema el programa.
- ❌ Sustituir la DPIA por la FRIA o al revés: se complementan (art. 27(4)).
- ❌ Llamar supervisión humana a un botón de aprobar sin información, sin tiempo y sin autoridad
  para revertir; o celebrar una tasa de anulación cercana a cero.
- ❌ Firmar con un proveedor de IA sin respuesta escrita sobre entrenamiento con tus datos,
  retención, subencargados, notificación de cambios y de incidentes, y salida.
- ❌ Tratar el marcado de contenido sintético como control anti-abuso: es trazabilidad frágil.
- ❌ Presentar la adhesión al Código de buenas prácticas GPAI como presunción de conformidad.
- ❌ Aceptar un "certificado ISO 42001" sin comprobar la acreditación de la entidad (ISO 42006).
- ❌ Confundir el **registro de modelos** de `mlops-standards` con el **inventario de sistemas de
  IA**: el segundo incluye lo que tú no operas.
- ❌ Un SGIA cuyo alcance cubre una fracción del inventario, presentado como si cubriera todo.
- ❌ Métricas que suben mientras el riesgo sube (§6.2).
- ❌ Mantener un control que en doce meses no ha cambiado ninguna decisión.

## 8. Verificación web obligatoria

**Ninguna fecha legal, artículo ni edición de norma se fija sin comprobarla en la fuente oficial.**
Un plazo mal citado aquí es el peor error posible del catálogo.

1. **Texto consolidado del AI Act**: Reglamento (UE) 2024/1689 **tal como quedó modificado por el
   Reglamento (UE) 2026/1744** (*Digital Omnibus on AI*, DOUE L de 24-jul-2026, en vigor
   27-jul-2026). Comprobar en EUR-Lex si hay modificaciones posteriores. **Las citas literales de
   los arts. 25, 27 y 73 de este documento se pidieron verbatim; re-verificarlas antes de usarlas
   para decidir.**
2. **Calendario del art. 113**: confirmar 2-ago-2026 (art. 50 y aplicación general), 2-dic-2026
   (art. 50(2) y nuevas prohibiciones), 2-ago-2027 (sandboxes; transitorio GPAI preexistentes),
   **2-dic-2027 (Anexo III)** y **2-ago-2028 (Anexo I)**.
3. **GPAI**: estado del Código de buenas prácticas, lista actualizada de firmantes en el sitio de
   la Comisión, y avance de las **normas armonizadas CEN-CENELEC** (son las que dan presunción de
   conformidad del art. 40).
4. **Guía de la Comisión sobre el art. 73**: si el borrador de 26-sep-2025 ya tiene versión
   definitiva, y si cubre la vía del art. 55(1)(c) para GPAI.
5. **España**: estado de tramitación del Proyecto de Ley Orgánica de gobernanza de la IA
   (BOE/Congreso), competencias efectivas de **AESIA** y régimen sancionador nacional.
6. **ISO/IEC**: edición vigente de 42001 (a ago-2026, la **1.ª de 2023**; "EN ISO/IEC 42001:2026"
   es la **adopción europea del contenido de 2023**, no una segunda edición), y estado de 42005,
   42006, 42007, 12792, TS 6254 y TR 20226. Comprobar si hay revisión de 42001 en curso mirando
   **el código de etapa** en la ficha del proyecto de ISO o el programa de trabajo de JTC 1/SC 42.
7. **NIST**: si sigue vigente AI RMF 1.0 (AI 100-1) y AI 600-1 (jul-2024), o si ya hay revisión
   publicada; y el estado de los perfiles y borradores en curso (infraestructura crítica,
   ciberseguridad para IA, iniciativa de estándares de agentes de CAISI).
8. **Marcado de contenido sintético**: estado real de interoperabilidad y adopción de los esquemas
   de procedencia antes de comprometer una obligación contractual o un requisito de producto.

**Huecos declarados (no rellenados de memoria):**
- **Régimen sancionador nacional español**: en tramitación a la fecha de verificación; **no se ha
  confirmado su aprobación ni su entrada en vigor**. No se afirma en ninguna dirección.
- **Guía definitiva del art. 73**: solo se ha verificado la existencia de un **borrador**
  (26-sep-2025). Estado final no confirmado.
- **Revisión de ISO/IEC 42001**: no se ha podido consultar la ficha oficial de ISO (HTTP 403); la
  existencia de una segunda edición en curso **no está confirmada ni descartada**.
- **Firmantes del Código de buenas prácticas GPAI**: no se ha obtenido la lista vigente.
- **Cifras de IA en la sombra**: los estudios de 2026 divergen ampliamente (~45 %–81 %) por
  metodología. En §3.2 se usa el rango, **no un dato concreto**; si necesitas una cifra para un
  informe, cita el estudio y su método, no este documento.
- **Normas armonizadas CEN-CENELEC para IA**: estado de adopción no verificado en detalle.
- **Esquemas de procedencia de contenido**: adopción e interoperabilidad reales no verificadas;
  por eso §3.9 no nombra ninguno como recomendado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
