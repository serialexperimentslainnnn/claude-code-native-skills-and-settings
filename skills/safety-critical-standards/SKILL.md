---
name: safety-critical-standards
description: Functional safety and certification evidence for software whose failure can injure or kill. Use when working to IEC 61508 (SIL 1-4, systematic capability, route 1S/2S), ISO 26262 (ASIL A-D, HARA with severity/exposure/controllability, ASIL decomposition, freedom from interference, ISO 21448 SOTIF), DO-178C/ED-12C with its supplements DO-330, DO-331, DO-332 and DO-333, DAL/FDAL/IDAL assigned by ARP4754B and ARP4761A, DO-326A/ED-202A and DO-356A airworthiness security, EN 50128 or EN 50716:2023 and EN 50126/EN 50129 railway software, IEC 62304 software safety classes A/B/C with ISO 14971 risk management, ISO/SAE 21434 and UN R155/R156, a hazard log or safety case (GSN), FMEA/FMEDA, fault tree analysis, HAZOP, requirement-to-design-to-code-to-test traceability matrices, structural coverage (statement, decision, MC/DC) and dead or deactivated code, tool qualification (TQL-1..TQL-5, tool criteria 1/2/3, TCL1-3, T1/T2/T3), MISRA C or MISRA C++ or SPARK/Ada subsets, Ferrocene qualified Rust, WCET and stack analysis, ARINC 653 or MMU-based partitioning, watchdogs and safe degraded states, or assembling evidence for an assessor, DER or notified body.
---

# Estándares de software crítico para la seguridad (*safety-critical*)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando **un fallo del software puede herir o matar a alguien**, o destruir algo cuya pérdida
mata: un coche, un tren, un avión, un ventilador, una bomba de infusión, una prensa, una turbina.
El objeto de esta skill **no es escribir el código**: es **producir la evidencia** de que ese
código se desarrolló bajo un proceso que una autoridad, un organismo notificado o un assessor
independiente aceptará. En este dominio, **código sin evidencia no existe**.

**La distinción que ordena todo el documento:**

- ***Safety***: que el sistema **no haga daño** cuando falla o cuando el mundo se comporta de forma
  inesperada. Adversario: el azar, el desgaste, el error de diseño, el operador confundido.
  Métrica: probabilidad de fallo peligroso por hora, y rigor del proceso.
- ***Security***: que **nadie consiga** que el sistema haga daño. Adversario: una persona
  inteligente, con recursos, que **elige** el peor momento y el peor camino.

Son disciplinas con matemáticas distintas: *safety* razona con tasas de fallo aleatorio y con
independencia estadística; *security* razona con un atacante que **rompe deliberadamente esa
independencia** —el modo común de fallo lo provoca él—. Por eso el cálculo de un árbol de fallos no
sirve para un ataque, y por eso una redundancia 2oo3 de tres canales con el mismo firmware **no
compra nada** frente a un adversario aunque compre mucho frente al azar.

**Y hoy no se pueden separar, por hecho normativo, no por opinión**: la propia regulación las ha
soldado. Automoción: **UN R155** exige un sistema de gestión de ciberseguridad (CSMS) como
condición de **homologación de tipo**, y **UN R156** un sistema de gestión de actualizaciones de
software (SUMS) — obligatorios para nuevos tipos de vehículo desde **julio de 2022** y para todos
los vehículos nuevos desde **julio de 2024** (verificar por país, §8). Aviónica: el conjunto
**DO-326A/ED-202A** + **DO-356A/ED-203A** + **DO-355/ED-204** trata la seguridad de la información
como **proceso de aeronavegabilidad**, con AMC 20-42 de EASA como medio aceptable de cumplimiento.
Industrial: la revisión de **IEC 61508** en curso incorpora la ciberseguridad alineada con
**IEC 62443**. Ferroviario: **EN 50716:2023** incorpora explícitamente consideraciones de
ciberseguridad que EN 50128 no tenía.

**Regla de la casa**: *un análisis de peligros que no considera la causa intencionada está
incompleto, y un análisis de amenazas que no cuantifica la consecuencia física está desconectado.*
Se hacen los dos, se cruzan, y el resultado entra **en el mismo registro de riesgo**.

Cubre: qué norma aplica por sector y qué nivel de integridad se asigna y cómo; ciclo de vida en V y
sus artefactos; trazabilidad como el artefacto que de verdad se audita; cobertura estructural;
análisis de seguridad (FMEA, FTA, HAZOP, HARA); cualificación de herramientas; lenguaje y
subconjuntos; determinismo, WCET, particionado y estado seguro; y el encaje con la seguridad
informática.

**Nota de verificación que condiciona todo el documento**: **IEC, ISO, RTCA, SAE y CENELEC venden
sus normas.** Su texto **no** se ha podido leer verbatim aquí. Lo que este documento afirma del
*contenido* de esas normas procede de fuentes secundarias (fabricantes de herramientas, notas de
organismos) y **está marcado como tal en §8**. Lo verificado en fuente primaria accesible —fichas
de catálogo del IEC, fechas de CENELEC, documentación del proveedor— se cita con su dato exacto.
**Antes de comprometer un plan de certificación, se compra la norma y se lee.** Un objetivo mal
citado aquí cuesta un ciclo de auditoría.

**No aplica**: ver `ada-standards` (**el lenguaje Ada, SPARK y su toolchain son suyos** —niveles
Stone→Platinum, `gnatprove`, perfiles Ravenscar/Jorvik, `gnatcov`, distribuciones de GNAT y su
excepción de runtime—; **aquí qué criterio de cobertura y qué evidencia exige la norma para el
nivel asignado**, que es lo que esa skill delega explícitamente), `rust-standards` (**el Rust y su
toolchain son suyos**; aquí solo el estado de cualificación de la cadena, §2), `c-standards` y
`cpp-standards` (**dueños de MISRA C / MISRA C++ / CERT C, los sanitizers y el hardening del
binario**; aquí solo *que* se exige un subconjunto y con qué desviaciones documentadas),
`embedded-iot-standards` (**el objetivo físico es suyo**: silicio, arranque, device tree, memoria,
consumo, imagen de firmware y su actualización en campo; aquí el proceso de aseguramiento del
software que corre encima), `kernel-drivers-standards` (código en modo supervisor y su proceso
upstream), `ot-ics-security-standards` (**la planta industrial y su seguridad son suyas**:
IEC 62443, zonas y conductos, modelo Purdue, protocolos de campo, SIS como activo operado —
**frontera declarada: el *desarrollo* del software del SIS bajo IEC 61508/IEC 61511 es de aquí; su
*operación*, segmentación y monitorización, suyas**), `grc-compliance-standards` (marco de gestión,
SoA, aceptación formal de riesgo corporativo y evidencia de auditoría **general**; aquí el
expediente técnico de seguridad funcional, que es otro artefacto y va a otro auditor),
`appsec-standards` (STRIDE y clases de vulnerabilidad de aplicación),
`vulnerability-management-standards` (triaje CVSS/EPSS/KEV — **y el aviso recíproco: un SLA de
parcheo de IT no es aplicable a un equipo homologado**), `cryptography-pki-standards` (algoritmos,
curvas y ciclo de vida de claves, incluida la firma del firmware), `testing-qa-standards`
(**estrategia de prueba general y pirámide**; aquí el criterio de cobertura **que impone la norma**,
que no se negocia con el equipo), `cicd-standards` (la pipeline que ejecuta los gates de §4),
`healthtech-fhir-standards` (**hermana, frontera declarada**: **suyo** el software sanitario como
producto de información —FHIR, HL7 v2, terminologías, historia clínica— y **la clasificación
regulatoria MDR/IVDR de si un software es producto sanitario**; **de aquí** el proceso de ciclo de
vida IEC 62304 y la gestión de riesgo ISO 14971 de ese producto una vez clasificado),
`ai-governance-standards` (AI Act, clasificación de riesgo de IA y rendición de cuentas — **aquí el
problema, sin resolver, de que un componente aprendido no tiene requisitos trazables línea a
línea**, §7), `incident-management-standards` (gobierno del incidente),
`bcdr-standards`, `observability-standards`, `offensive-security-standards` (**esta skill es
defensiva**).

## 2. Decisiones por defecto

> Verificar la edición vigente y su fecha de retirada por web antes de fijarla en un proyecto real (§8).

### 2.1 Qué norma manda, por sector

| Sector | Norma de software | Escala de integridad | Verificado a ago-2026 |
|---|---|---|---|
| Genérico / industrial (E/E/PE) | **IEC 61508-3** | **SIL 1 – SIL 4** (4 = más exigente) | Edición **2.0, publicada 2010-04-30, en vigor, fecha de estabilidad 2027** (ficha del IEC, verbatim). **Edición 3 en CDV**, publicación esperada ~2027: **no planifiques contra ella** |
| Proceso continuo | **IEC 61511** (aplicación sectorial de 61508) | SIL 1–3 en la práctica | Fuera del alcance detallado de esta skill; ver `ot-ics-security` para su operación |
| Automoción | **ISO 26262-6** (software) | **ASIL A – ASIL D** (**D = más exigente**) + **QM** | Serie 2018. **ISO 21448 (SOTIF)** cubre lo que 26262 **no**: fallos de *función prevista* sin avería |
| Aviónica | **DO-178C / ED-12C** | **DAL A – DAL E** (**A = más exigente**, E = sin efecto en seguridad) | Los **DAL los asigna ARP4754B/ARP4761A**, no DO-178C (§2.2) |
| Ferroviario | **EN 50716:2023** | SIL 0 – SIL 4 | **Título verbatim: "Railway Applications - Requirements for software development"**. Publicada **2023-11-16**; **sustituye a EN 50128:2011 (+AC:2014, +A1:2020, +A2:2020) y EN 50657:2017 (+A1:2023)**; **DoW 30-10-2026** — la fecha viva de este dominio |
| Dispositivo médico | **IEC 62304** | **Clase A / B / C** | Clase A: no es posible lesión; B: lesión no grave; C: muerte o lesión grave (fuente secundaria, §8). **Edición 2 en proyecto** con **dos niveles de rigor** en vez de tres clases: no verificado en fuente IEC (§8) |
| Gestión de riesgo de producto sanitario | **ISO 14971** | — | Proceso, no escala. Alimenta la clasificación de IEC 62304 |
| Espacio | ECSS-Q-ST-80C / ECSS-E-ST-40C | Criticidad A–D | ECSS publica sus normas **en abierto**: úsalo, es el único cuerpo normativo de este dominio que puedes leer verbatim sin pagar |

**El mapeo cruzado SIL ↔ ASIL ↔ DAL que circula en tablas de blog NO es normativo.** No lo publica
ninguna de las tres normas como equivalencia, y las escalas ni siquiera miden lo mismo: **SIL es
probabilístico** (tasa de fallo peligroso por hora / probabilidad de fallo bajo demanda), **ASIL es
cualitativo** (matriz S/E/C), **DAL es una categoría de condición de fallo** asignada a nivel de
sistema. Consecuencia operativa, sin excepciones: **un componente certificado SIL 3 no se declara
ASIL D ni DAL B por analogía**; se hace un *gap analysis* documentado, se identifica la evidencia
que falta y se produce. Quien venda un componente "SIL 3 / equivalente a ASIL D" está vendiendo un
argumento comercial, no una evidencia. `ada-standards` sostiene esta misma prohibición.

### 2.2 El matiz de aviónica que casi todo el mundo cita mal

**DO-178C no asigna el DAL.** El nivel sale del proceso de seguridad **a nivel de sistema y de
aeronave**: la evaluación funcional de peligros y el análisis de seguridad de **ARP4761A**
determinan la severidad de la condición de fallo, y **ARP4754B** asigna el **FDAL** (nivel de
función) y deriva el **IDAL** (nivel de elemento) a los elementos que la implementan. **DO-178C
define los objetivos de aseguramiento que hay que cumplir *dado* ese nivel**, y cuáles son "con
independencia".

**ARP4754B y ARP4761A se publicaron el mismo día, 2023-12-20** (SAE; armonizadas con ED-79B y
ED-135 de EUROCAE), y el reparto entre ambas cambió: el detalle de las actividades de evaluación de
seguridad se trasladó a ARP4761A. **Si tu plan de certificación cita ARP4754A, comprueba qué
revisión acepta tu autoridad** antes de reescribir nada.

Suplementos de DO-178C, y **cuándo aplica cada uno** (no son opcionales si usas la técnica):

| Suplemento | Aplica si | Efecto |
|---|---|---|
| **DO-330 / ED-215** | Usas **cualquier herramienta** cuya salida no verificas por otro medio | Define el proceso de cualificación (§2.3) |
| **DO-331** | Desarrollo basado en modelos (el modelo *es* el requisito o el diseño) | Modifica objetivos y qué significa "revisión del modelo" |
| **DO-332** | Orientación a objetos y técnicas relacionadas | Añade objetivos por herencia, polimorfismo, gestión dinámica de memoria |
| **DO-333** | Métodos formales **como sustituto** de una actividad de verificación | Permite reemplazar prueba por prueba matemática **con condiciones** |

### 2.3 Cualificación de herramientas — la regla en una frase

**Una herramienta cuya salida no verificas por otro medio, hay que cualificarla.** El corolario que
ahorra dinero es el inverso y se olvida: **si verificas la salida de forma independiente, no hace
falta cualificarla**. La cualificación existe para *sustituir* trabajo humano, no para añadirse a él.

- **DO-178C §12.2 / DO-330**: tres **criterios** de herramienta — **Criterio 1**, la herramienta
  puede **insertar** un error en el software embarcado; **Criterio 2**, herramienta de verificación
  que puede **no detectar** un error **y** se usa para reducir otra actividad; **Criterio 3**,
  herramienta de verificación que puede no detectar un error **y no** reduce otra actividad. El
  criterio cruzado con el DAL del software da el **TQL, de TQL-5 (menos exigente) a TQL-1 (rigor
  cercano a DAL A)** en la Tabla 12-1 (fuente secundaria, §8).
- **ISO 26262-8, cl. 11**: se determina **TI** (impacto de la herramienta) y **TD** (confianza en su
  detección de errores) y de ahí sale el **TCL 1–3**; TCL1 no requiere medidas de cualificación.
- **IEC 61508-3 / EN 50716**: clases **T1 / T2 / T3** — T1 no genera salida que afecte al ejecutable,
  T2 puede no detectar un error, T3 genera salida que forma parte del ejecutable.

**Lo que esto decide en la práctica**: el compilador es Criterio 1 / T3 / TI alto. Por eso una
cadena de compilación **cualificada** es una decisión de proyecto con presupuesto propio, y por eso
`ada-standards` insiste en el estado exacto de Ferrocene.

### 2.4 Lenguaje y subconjunto

| Opción | Cuándo | Estado a ago-2026 |
|---|---|---|
| **C con MISRA C** | Lo instalado, y lo que casi toda herramienta cualificada soporta | Reglas y desviaciones documentadas una a una; el subconjunto y su tooling son de `c-standards` |
| **C++ con MISRA C++** o subconjunto acordado | Cuando el diseño lo justifica y con **DO-332** en aviónica | Sin excepciones, sin RTTI, sin asignación dinámica tras inicialización |
| **Ada / SPARK** | Máxima integridad; prueba formal de ausencia de error de ejecución y de propiedades | Cadena madura y aceptada por autoridades desde hace décadas (`ada-standards`) |
| **Rust con Ferrocene** | Sistemas nuevos, cuando el nivel exigido cae dentro de lo cualificado | **Verificado en ferrocene.dev, verbatim**: *"The compiler is TÜV SÜD-qualified for use in safety-critical development according to ISO 26262 (ASIL D)"*, y también **IEC 61508 (SIL 3)** e **IEC 62304 (Class C)**; *"A certified core subset is available for ISO 26262 (ASIL B) and IEC 61508 (SIL 2)"*. Para **SIL 4** y **DO-178C (DAL C)** el texto dice **"supports customer certification efforts"** — **soporte al esfuerzo del cliente, NO cualificación a ese nivel**. Hay literatura, incluida académica, que lo cita mal |

**Prohibición transversal de esta sección**: **no se declara un nivel de cualificación de cadena que
no aparezca en el certificado del organismo**. Se lee el certificado, no la nota de prensa.

## 3. Ciclo de vida, trazabilidad y artefactos

### 3.1 El ciclo en V, y por qué sobrevive

Las cuatro normas describen un ciclo en V —requisitos → arquitectura → diseño → código, y su rama
derecha de verificación espejo— **no por conservadurismo, sino porque la evidencia que se audita es
la correspondencia entre las dos ramas**. Ágil es compatible: EN 50716:2023 admite explícitamente
ciclos iterativos. Lo que **no** es negociable es que **cada rama izquierda tenga su verificación
en la derecha, y que ambas estén enlazadas**. Un sprint que produce código sin requisito trazable
produce código que hay que tirar.

### 3.2 La trazabilidad es el producto

Lo que un assessor abre primero no es el código: es la **matriz de trazabilidad**. Debe cerrarse
**bidireccionalmente** en toda la cadena:

```
Peligro (hazard log)
  → Requisito de seguridad (con su SIL/ASIL/DAL/Clase heredado)
    → Requisito de software de alto nivel
      → Arquitectura / diseño (requisito de bajo nivel)
        → Código fuente (fichero, función, línea)
          → Caso de prueba (basado en requisito, no en código)
            → Resultado de ejecución (con versión de build y de entorno)
              → Evidencia de cobertura estructural
```

Reglas duras:
1. **Sin huérfanos hacia arriba**: código o test sin requisito que lo justifique = código no
   solicitado. En aviónica esto es exactamente el hallazgo de **código muerto** (§4.3).
2. **Sin huérfanos hacia abajo**: requisito sin diseño, sin código o sin prueba = objetivo abierto.
3. **La trazabilidad se genera desde la herramienta de gestión de requisitos, nunca a mano en una
   hoja de cálculo.** Una matriz mantenida a mano está desactualizada el día que se entrega.
4. **La verificación tiene que ser posible**: un requisito no verificable ("el sistema será
   robusto") es un defecto de requisito, y se rechaza en revisión.
5. Los **casos de prueba se derivan del requisito**, no del código. Un test escrito leyendo la
   implementación demuestra que el código hace lo que hace.

### 3.3 El caso de seguridad (*safety case*)

Un argumento estructurado de por qué el sistema es aceptablemente seguro **en su contexto de uso
declarado**, con: reclamación → argumento → evidencia. **GSN** (Goal Structuring Notation) es la
notación habitual y es abierta. Se escribe **al principio**, no al final: un caso de seguridad
redactado tras la implementación es una racionalización, y el assessor lo huele.

**Y el corolario honesto que cierra el documento (§7): un caso de seguridad demuestra que se siguió
un proceso, no que no haya fallos.**

## 4. Calidad, análisis y verificación

### 4.1 Análisis de peligros — cuál, para qué

| Técnica | Dirección | Uso |
|---|---|---|
| **HAZOP** | Exploratoria, guiada por palabras clave (*no, más, menos, inverso, otro que*) | Sistemas de proceso; encuentra peligros que nadie había enunciado |
| **FMEA / FMEDA** | **Inductiva**: del modo de fallo del componente al efecto de sistema | Bottom-up; FMEDA añade el dato de diagnóstico y alimenta la cobertura de diagnóstico y el SIL de hardware |
| **FTA** (árbol de fallos) | **Deductiva**: del evento peligroso a sus combinaciones de causas | Top-down; da la estructura para cuantificar y para encontrar **modos de fallo de causa común** |
| **HARA** (ISO 26262-3) | Clasificación de riesgo automoción | Salida: metas de seguridad, cada una con su ASIL |
| **STPA** | Basada en teoría de control: peligros por **interacciones**, no por fallo de componente | Lo que FMEA/FTA no ven: software correcto que en conjunto produce un accidente |

**La determinación del ASIL** (fuente secundaria, §8): por cada *evento peligroso* se puntúan tres
parámetros y su combinación da el ASIL en una matriz — **Severidad S0–S3** (S0 sin lesiones, S3
potencialmente mortales), **Exposición E0–E4** (frecuencia de la **situación de operación**, no del
fallo interno), **Controlabilidad C0–C3** (capacidad del conductor u otro usuario de la vía de
controlar la situación). El extremo **S3 + E4 + C3 da ASIL D**; cualquier parámetro en 0 degrada a
**QM** (fuera del alcance de la norma). Dos consecuencias que se olvidan:
- **La exposición es de la situación, no del fallo.** Puntuarla con la tasa de avería es el error
  más común y baja artificialmente el ASIL.
- **La controlabilidad no acredita las contramedidas técnicas del propio ítem.** Si el argumento es
  "el conductor puede corregirlo porque el sistema le avisa", el argumento es circular.
- Ante duda justificada, **se elige la clase superior** y se documenta el porqué. Un ASIL rebajado
  sin justificación trazable es el hallazgo más caro de una auditoría.

**Descomposición ASIL** (ISO 26262-9) permite repartir un ASIL alto entre elementos redundantes
**solo si se demuestra independencia**; sin *freedom from interference* demostrada (memoria,
temporal, intercambio de información), la descomposición no es válida y **todo el conjunto hereda
el ASIL más alto**. Lo mismo, con otro nombre, en IEC 62304: la clase del sistema es la más alta de
sus ítems salvo independencia arquitectónica demostrada.

### 4.2 Cobertura estructural — qué exige cada nivel

**No es una métrica de calidad, es una comprobación de que la prueba basada en requisitos ejercitó
toda la estructura.** Se mide sobre pruebas derivadas de requisitos; **una prueba escrita para subir
cobertura invalida el argumento**.

| Criterio | Qué exige | DO-178C (fuente secundaria, §8) |
|---|---|---|
| **Sentencia** | Cada sentencia ejecutada al menos una vez | **DAL C** y superiores |
| **Decisión** | Cada punto de decisión toma ambos resultados | **DAL B** y superiores |
| **MC/DC** | Además, **cada condición demuestra afectar independientemente al resultado** de la decisión | **DAL A** |
| — | Sin requisito de cobertura estructural | DAL D y DAL E |

**MC/DC en DO-178C admite las formas *masking* y *short-circuit*, además de la *unique-cause* de
DO-178B** (cambio respecto de DO-178B, fuente secundaria). Es lo que hace que MC/DC sea alcanzable
en código real: exige `n+1` casos para `n` condiciones en vez de `2^n`.

En IEC 61508-3, ISO 26262-6 y EN 50716 el criterio equivalente aparece como **método recomendado
(R) o altamente recomendado (HR) por nivel**, no como número absoluto; el nivel de rigor sube con
SIL/ASIL. **La norma fija el criterio, no el equipo** — y esa frase es literalmente la frontera que
`ada-standards` delega aquí.

### 4.3 Código muerto y código desactivado — no son lo mismo

- **Código muerto** (*dead code*): no ejecutable y **sin requisito**. Es un **defecto**: se
  **elimina**, y se re-verifica lo que se toca. No se justifica, no se comenta, no se deja "por si
  acaso".
- **Código desactivado** (*deactivated code*): existe **con requisito**, y está intencionadamente
  inactivo en esta configuración (una variante, un modo de fábrica). Se **justifica**, se documenta
  el mecanismo que garantiza que no puede activarse, y se verifica **ese mecanismo**.
  Confundirlos es el hallazgo clásico de una auditoría de cobertura.

### 4.4 Gates que rompen el build, en orden de coste creciente

1. **Compilación sin avisos**, con los flags exactos del entorno cualificado. Un binario con avisos
   no se entrega.
2. **Análisis estático del subconjunto** (MISRA / reglas del proyecto) con **cero desviaciones no
   aprobadas**. Cada desviación tiene ficha: regla, motivo, alcance, análisis de impacto, aprobador.
3. **Análisis estático de errores de ejecución** (desbordamiento, división por cero, acceso fuera
   de rango) o **prueba formal** donde el lenguaje lo permita.
4. **Pruebas basadas en requisitos**, incluidas **robustez y casos de error** — valores fuera de
   rango, entradas corruptas, fallo del canal redundante. En este dominio **los casos de error no
   son "bordes": son el requisito**.
5. **Cobertura estructural al criterio del nivel**, con análisis de cada hueco (no con una
   excepción global).
6. **Análisis temporal (WCET) y de pila** (§6).
7. **Verificación de la trazabilidad completa** como job de CI: cualquier huérfano rompe el build.
8. **Reproducibilidad del build**: el binario entregado se reconstruye bit a bit desde el
   repositorio en el entorno declarado. **Un binario que no se puede reconstruir no se puede
   certificar** ni parchear dentro de diez años.

## 5. Seguridad del stack (donde *safety* y *security* se tocan)

- **Un análisis de amenazas obligatorio, con la consecuencia física como impacto.** STRIDE es de
  `appsec-standards`; lo propio de aquí es que **el impacto no es "fuga de datos", es "el freno no
  actúa"**. En automoción, el TARA de **ISO/SAE 21434** es el artefacto; en aviónica, la evaluación
  de riesgo de **DO-326A**; en industrial, la evaluación de **IEC 62443-3-2**.
- **La superficie de ataque es una decisión de arquitectura de seguridad funcional**: cada
  interfaz añadida (diagnóstico, telemetría, OTA, bus compartido) es un camino nuevo al elemento
  crítico y **hay que argumentar su aislamiento en el caso de seguridad**, no solo en el de
  seguridad informática.
- **Actualización de campo**: firmware **firmado y verificado antes de ejecutar**, con anti-rollback
  y arranque a una imagen buena conocida si falla. En un producto homologado, **una actualización
  puede invalidar la homologación**: el proceso de cambio (impacto en la evidencia, re-verificación,
  notificación a la autoridad u organismo notificado) se define **antes** de la primera OTA, no en
  la primera vulnerabilidad. UN R156 existe precisamente por esto.
- **Puertos de depuración**: JTAG/SWD/consola deshabilitados o bloqueados criptográficamente en
  producción; su estado es un requisito verificable con su prueba, no una tarea de fabricación.
- **Gestión de vulnerabilidades**: el SLA de parcheo de IT **no se puede aplicar** a un equipo
  homologado con años de ciclo de re-verificación. Lo que sí se exige: **SBOM del árbol embarcado**,
  vigilancia activa de CVE sobre él, **análisis de explotabilidad real en el contexto del producto**
  (VEX) y **controles compensatorios documentados** para lo que no se parcheará. `ot-ics-security`
  sostiene el mismo criterio para la planta.
- **Segregación de dominios**: lo crítico no comparte núcleo, memoria ni bus con lo no crítico sin
  un mecanismo de partición demostrado (§6.3). Un infotainment y un control de tracción en el mismo
  SoC **es una decisión de seguridad funcional**, y hay que defenderla.

## 6. Determinismo, tiempo y estado seguro

### 6.1 Determinismo antes que rendimiento

En este dominio, **el peor caso es el único caso que importa**. Consecuencias de diseño, no
recomendaciones:

- ❌ **Sin asignación dinámica de memoria tras la fase de inicialización.** Todo lo que hay se
  reserva al arrancar; el *heap* no es analizable y su fragmentación no es acotable.
- ❌ **Sin recursión no acotada** (y con la acotación demostrada, no supuesta).
- ❌ **Sin bucles de límite no demostrable.**
- **Tamaño de pila calculado y verificado**, no estimado. El desbordamiento de pila es el fallo
  silencioso clásico de este dominio.

### 6.2 WCET — y su honestidad

El **tiempo de ejecución de peor caso** se **analiza**, no se mide con un `benchmark`: la medición
da el peor caso *observado*, que no es el peor caso. Los métodos habituales son análisis estático
del binario, medición híbrida sobre el hardware real, o ambos. **Y el aviso que decide arquitectura:
en un multinúcleo con cachés y buses compartidos, el WCET de una tarea depende de lo que hagan las
demás**; sin control de interferencia (particionado de caché, presupuesto de ancho de banda de
memoria), un análisis WCET por tarea aislada no es válido. En aviónica esto tiene guía propia
(CAST-32A / AMC 20-193, verificar el estado por autoridad, §8).

### 6.3 Particionado

Si conviven criticidades distintas en un mismo procesador, hay que demostrar **independencia
espacial y temporal**: MMU/MPU para memoria, planificación con presupuesto para tiempo, y control de
los canales compartidos (caché, DMA, bus, interrupciones). **ARINC 653** es el modelo de referencia
en aviónica; en automoción, la *freedom from interference* de ISO 26262-6 anexo D. Sin esa
demostración, **todo el software del núcleo hereda el nivel más alto** — que suele ser
económicamente inviable, y por eso el particionado se decide al principio o no se decide.

### 6.4 Estado seguro y degradación

- **Todo diseño declara su estado seguro** y el **intervalo de tiempo tolerable a fallo** (FTTI en
  ISO 26262): cuánto puede estar el sistema en fallo antes de que el peligro se materialice. Todo el
  presupuesto de detección + reacción tiene que caber ahí.
- **"Apagarse" no siempre es seguro.** Un tren se detiene con seguridad; un avión en vuelo, no; un
  ventilador tampoco. **El estado seguro es específico del dominio y se justifica en el análisis de
  peligros**, no se asume.
- **Watchdog externo al procesador que vigila**, con ventana (mínimo y máximo), alimentado por una
  comprobación de progreso real y no por un temporizador que hace *kick* pase lo que pase. Un
  watchdog alimentado desde una interrupción independiente de la aplicación no vigila nada.
- **Modo degradado explícito y probado**: qué funciones se pierden, cómo se informa al operador, y
  cómo se sale. Un modo degradado no probado es un modo desconocido.
- **Registro para investigación posterior**: qué se registra, dónde sobrevive a un corte, y cómo se
  extrae. En un accidente, la evidencia que no exista no se podrá reconstruir.

## 7. Sostenibilidad, honestidad y prohibiciones

**Ciclo de vida largo**: estos productos viven 15–30 años. Consecuencias que se deciden hoy:
congelar y **archivar el entorno de build completo** (compilador exacto, versión, parches, sistema
operativo, herramientas y sus certificados) de forma reproducible; mantener la trazabilidad de la
evidencia con el producto, no en el portátil de quien se marchó; y presupuestar la **re-verificación
por cambio** desde el primer día — en este dominio, **el coste de un cambio es el coste de volver a
demostrar**, no el de escribirlo.

**Transición de norma**: EN 50716 tiene **DoW el 30-10-2026**; IEC 61508 Ed. 3 se espera ~2027;
IEC 62304 Ed. 2 está en proyecto. **Un proyecto plurianual elige su edición de referencia y la
documenta**; cambiar de edición a mitad es un cambio de alcance, con su análisis de impacto.

**El componente aprendido (ML) es el problema abierto de este dominio.** No tiene requisitos
trazables línea a línea, su cobertura estructural no significa nada, y su comportamiento fuera de
distribución no es demostrable con los métodos de §4. Existen guías emergentes (ISO 21448 SOTIF para
el fallo de función prevista, trabajos de EASA y de la industria automotriz), pero **a día de hoy no
hay un camino aceptado universalmente para certificar una función crítica implementada con
aprendizaje**. Si tu diseño depende de uno, el argumento tiene que ser **arquitectónico** —un
monitor determinista y verificable que acota lo que el modelo puede hacer— no estadístico. El
gobierno del sistema de IA es de `ai-governance-standards`; **el argumento de seguridad es de aquí, y
hoy es duro**.

**La honestidad final, y es la frase que hay que decirle a quien firma el cheque: la certificación
no demuestra la ausencia de fallos. Demuestra que se siguió un proceso reconocido con un rigor
proporcional al riesgo, y que existe evidencia de ello.** Sistemas certificados han matado gente.
Tratar el certificado como garantía de corrección es exactamente el error que produce el siguiente
accidente; tratarlo como lo que es —una reducción disciplinada de la probabilidad de error
sistemático— es lo que hace que el proceso valga su coste.

**Prohibiciones:**

- ❌ **PROHIBIDO presentar el mapeo SIL↔ASIL↔DAL como normativo**, o reutilizar un componente entre
  normas sin *gap analysis* documentado (§2.1). `ada-standards` prohíbe lo mismo.
- ❌ **PROHIBIDO afirmar el contenido de una norma que no has leído.** Si no tienes la copia, dilo y
  cita la fuente secundaria como tal.
- ❌ Decir que "DO-178C asigna el DAL". Lo asignan ARP4754B/ARP4761A (§2.2).
- ❌ Confundir "cualificado para X" con "da soporte a esfuerzos de certificación hacia X" en una
  cadena de herramientas (§2.4). Es el error de citación más frecuente sobre Ferrocene.
- ❌ Usar una herramienta cuya salida no verificas **sin cualificarla** — y también su inverso:
  cualificar una herramienta cuya salida **sí** verificas independientemente, pagando por nada.
- ❌ Escribir pruebas **para subir la cobertura**. Invalida el argumento entero de §4.2.
- ❌ Dejar **código muerto** justificándolo como "desactivado" (§4.3).
- ❌ Asignación dinámica de memoria tras la inicialización, recursión no acotada, bucles sin límite
  demostrable (§6.1).
- ❌ Declarar un WCET medido con un benchmark, o un WCET por tarea aislada en un multinúcleo con
  recursos compartidos sin control de interferencia (§6.2).
- ❌ Mezclar criticidades en un procesador **sin demostrar** particionado espacial y temporal (§6.3).
- ❌ Watchdog alimentado por un temporizador ciego, o interno al elemento que vigila.
- ❌ Un modo degradado que no se ha probado, o un "estado seguro" que se asumió sin salir del
  análisis de peligros.
- ❌ Puertos de depuración activos en producción.
- ❌ Un binario entregable que no se puede reconstruir bit a bit desde el repositorio (§4.4).
- ❌ Matriz de trazabilidad mantenida a mano en hoja de cálculo (§3.2).
- ❌ Un caso de seguridad escrito después de la implementación.
- ❌ Aplicar un SLA de parcheo de IT a un producto homologado, y su inverso: **usar la homologación
  como excusa para no vigilar CVEs ni mantener SBOM** (§5).
- ❌ Desplegar una OTA sin haber definido antes el impacto del cambio sobre la evidencia y sobre la
  homologación (§5).
- ❌ Tratar el certificado como prueba de que el software no tiene fallos (§7).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **La edición vigente de tu norma y su fecha de retirada**, en el catálogo del organismo:
   ficha del **IEC** (accesible y fiable: la de **IEC 61508-3:2010, ed. 2.0, 2010-04-30, en vigor,
   estabilidad 2027**, está verificada aquí), catálogo **CENELEC** para EN 50716 (**publicada
   2023-11-16, DoW 30-10-2026**, verificado) y **iso.org** — aviso: **iso.org devuelve 403 a la
   obtención automática**; usa el catálogo de tu organismo nacional de normalización (UNE/AENOR,
   DIN, BSI).
2. **Estado de las revisiones en curso**: **IEC 61508 Ed. 3** (en CDV, publicación esperada ~2027) e
   **IEC 62304 Ed. 2** (proyecto, con el cambio a **dos niveles de rigor** en vez de tres clases).
   **Ambos datos proceden de fuentes secundarias y NO se han verificado en fuente IEC: hueco
   declarado.** No planifiques contra una edición no publicada.
3. **El contenido normativo citado en §2, §4.1 y §4.2 —clases de IEC 62304, matriz S/E/C de ASIL,
   cobertura estructural por DAL, TQL/Tabla 12-1 de DO-178C, criterios T1/T2/T3— procede de fuentes
   secundarias (fabricantes de herramientas y consultoras), porque IEC, ISO, RTCA, SAE y CENELEC no
   publican el texto. Hueco declarado: contrástalo contra la copia comprada de la norma antes de
   comprometerlo en un plan de certificación.**
4. **Revisión de ARP4754/ARP4761 que acepta tu autoridad**: **ARP4754B y ARP4761A se publicaron el
   2023-12-20** (verificado como fecha; el contenido, no). Muchos planes vivos siguen citando
   ARP4754A y la autoridad puede aceptar ambas.
5. **Estado de cualificación de tu cadena de herramientas**, leído **en el certificado del
   organismo**, no en la web comercial. Para Ferrocene, la distinción **cualificado** (ISO 26262
   ASIL D, IEC 61508 SIL 3, IEC 62304 Clase C; subconjunto `core` certificado para ASIL B y SIL 2)
   frente a **"supports customer certification efforts"** (IEC 61508 SIL 4, DO-178C DAL C) está
   verificada verbatim en `ferrocene.dev` a ago-2026 — **compruébala de nuevo, cambia con cada
   release**, y coordínalo con `ada-standards`, que sostiene el mismo dato.
6. **Guía de multinúcleo de tu autoridad** (CAST-32A, AMC 20-193 de EASA y su equivalente FAA): su
   estado y qué exige exactamente sobre interferencia. **No verificado aquí: hueco declarado.**
7. **Fechas regulatorias del sector**: UN R155/R156 (nuevos tipos jul-2022, todos los vehículos
   nuevos jul-2024 en la UE, según fuente secundaria y la agencia británica VCA — **verifícalo en
   el texto de UNECE y en tu jurisdicción**), estado de la ciberseguridad en aviónica (AMC 20-42 de
   EASA, reglamentación FAA en curso), y **Cyber Resilience Act** con `embedded-iot-standards`.
8. **Normas ECSS**: se publican en abierto en `ecss.nl`. Si tu dominio es espacio, es el único
   corpus de este documento que puedes leer verbatim sin pagar — úsalo.
9. **CVEs del árbol embarcado** (RTOS, pila de red, criptografía, librerías C), con
   `vulnerability-management-standards`, y estado de mantenimiento de cada componente de terceros
   con evidencia de seguridad ("SEooC", *safety element out of context*) que hayas comprado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
