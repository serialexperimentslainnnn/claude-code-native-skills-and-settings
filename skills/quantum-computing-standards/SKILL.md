---
name: quantum-computing-standards
description: Quantum computing as an R&D decision with honest expectations — what today's hardware can and cannot do. Use when evaluating a quantum proposal or vendor pitch, reading qubit-count and quantum-advantage claims and separating physical from logical qubits, fidelity and error rates, NISQ limits, decoherence and T1/T2, surface codes and qLDPC error correction and the physical-to-logical overhead, gate-based versus quantum annealing (D-Wave) and why they are not interchangeable, algorithms with a proven speedup (Shor factoring, Grover's quadratic search, quantum phase estimation, Hamiltonian simulation of chemistry and materials) versus QAOA/VQE heuristics with no proven advantage, resource estimation for a quantum attack, writing circuits with Qiskit, Cirq, PennyLane, Q#/QDK, Braket or OpenQASM, buying cloud quantum access (IBM Quantum Platform, Amazon Braket, Azure Quantum), quantum-inspired classical algorithms, or budgeting quantum R&D and training. Also covers "quantum" marketing claims in a procurement or board setting.
---

# Estándares de computación cuántica

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers: qué se puede hacer hoy y qué no

Esta skill existe para **una sola cosa**: que nadie comprometa presupuesto, arquitectura o
promesa de producto sobre una capacidad que no existe. El contenido técnico es secundario
respecto al criterio de §1 y a las prohibiciones de §7.

### 1.1 Lo que NO se puede hacer hoy

- **No se puede romper RSA ni la criptografía de curva elíptica.** No hay ninguna máquina
  cerca de ello. Referencia de coste, verbatim del propio artículo de Craig Gidney
  (arXiv:2505.15917, 21-may-2025): *"In Gidney+Ekerå 2019, I co-published an estimate stating
  that 2048 bit RSA integers could be factored in eight hours by a quantum computer with 20
  million noisy qubits. In this paper, I substantially reduce the number of qubits required.
  I estimate that a 2048 bit RSA integer could be factored in less than a week by a quantum
  computer with less than a million noisy qubits."* Bajo supuestos explícitos: *"a uniform
  gate error rate of 0.1%, a surface code cycle time of 1 microsecond, and a control system
  reaction time of 10 microseconds"*. **Menos de un millón de qubits físicos ruidosos, y las
  máquinas actuales tienen del orden de cientos.** Nótese además la dirección del dato: la
  estimación **bajó de 20 millones a menos de 1 millón en seis años**, no por mejor hardware,
  sino por mejores algoritmos. Esa es la razón de que el plazo de la amenaza sea incierto.
- **No hay ventaja demostrada en optimización empresarial, machine learning ni finanzas.**
  Los algoritmos variacionales (VQE, QAOA) son heurísticas: **no tienen prueba de ventaja
  asintótica**, y en la práctica compiten mal contra un buen solver clásico. Cualquier
  presentación que prometa "optimizar la ruta de reparto" con cuántica está vendiendo una
  heurística sin garantías contra otra que ya funciona.
- **No hay ordenador cuántico tolerante a fallos.** Nadie ejecuta hoy un algoritmo largo con
  corrección de errores completa. Lo que hay son demostraciones de que la corrección
  **empieza** a funcionar.
- **No se puede usar en producción.** Ni por capacidad, ni por disponibilidad, ni por coste,
  ni por reproducibilidad de resultados.

### 1.2 Lo que sí se puede hacer hoy

- **Experimentar, formar equipo y estimar recursos.** Escribir circuitos, ejecutarlos en
  simulador y en hardware real por nube, y sobre todo **calcular cuántos qubits lógicos y
  cuántas puertas necesitaría tu problema** — que es el resultado más útil, porque casi
  siempre demuestra que el problema no es candidato.
- **Simulación cuántica de química y materiales**: el caso de uso más creíble a medio plazo,
  porque es el problema para el que la máquina está estructuralmente indicada (simular un
  sistema cuántico con un sistema cuántico) y donde existen algoritmos con ventaja
  exponencial demostrada para tareas concretas. Sigue sin ser producción.
- **Aprovechar los algoritmos "quantum-inspired"**: varios avances clásicos han salido de
  intentar simular algoritmos cuánticos. Ese retorno es real y se cobra hoy, sin hardware.

### 1.3 NISQ, ruido y la distancia entre qubit físico y lógico

Estamos en la era **NISQ** (*Noisy Intermediate-Scale Quantum*): pocos qubits, ruidosos y sin
corrección de errores efectiva. Un qubit pierde su estado por **decoherencia** en microsegundos
a milisegundos, y cada puerta introduce error. Con un error por puerta del orden de 10⁻³, un
circuito de unos pocos miles de puertas ya produce ruido en lugar de resultado. **Ese es el
techo real, no el número de qubits.**

La **corrección cuántica de errores** codifica un **qubit lógico** en muchos **qubits
físicos**. El hito de referencia es Google Quantum AI, *"Quantum error correction below the
surface code threshold"* (arXiv:2408.13687, ago-2024; Nature 638, 2025), con estos números
verbatim: código de **distancia 7 sobre 101 qubits físicos**, *"The logical error rate of our
larger quantum memory is suppressed by a factor of Λ = 2.14 ± 0.02 when increasing the code
distance by two"*, error lógico de *"0.143% ± 0.003% error per cycle"*, y una memoria lógica
*"exceeding its best physical qubit's lifetime by a factor of 2.4 ± 0.3"*.

**Cómo se lee ese resultado, que es lo que importa**: es un hito científico de primer orden —
demuestra que añadir qubits físicos ahora **reduce** el error en lugar de aumentarlo, que es
la precondición de todo lo demás. Y a la vez: **101 qubits físicos para UN qubit lógico de
memoria**, con un factor de mejora de 2,4× sobre el mejor qubit físico. No es un qubit lógico
computando, es un qubit lógico **recordando**. Extrapolar de ahí a "romper RSA" salta unos
cuatro órdenes de magnitud y varias capacidades que aún no existen (puertas lógicas de alta
fidelidad, destilación de estados mágicos a escala, decodificación en tiempo real sostenida).

**Regla de lectura de cualquier anuncio**: un número de qubits sin **fidelidad de puerta de
dos qubits**, sin **conectividad** y sin decir si son **físicos o lógicos** es publicidad, no
una especificación.

**No aplica**: ver **`post-quantum-crypto-standards`** (**frontera dura**: *harvest now,
decrypt later*, inventario criptográfico y CBOM, elección de ML-KEM/ML-DSA/SLH-DSA, híbridos
en TLS/SSH/IPsec, agilidad criptográfica y **todo el calendario normativo** —NIST IR 8547,
SP 800-131A, CNSA 2.0—. **La única consecuencia práctica y urgente hoy de esta disciplina es
esa migración, y es enteramente suya**: aquí solo se explica *por qué* existe la amenaza y se
enlaza), `cryptography-pki-standards` (algoritmos clásicos, PKI y custodia de claves),
`hpc-standards` (clúster, planificador Slurm, MPI y entorno de software del cómputo clásico
con el que compite y contra el que hay que comparar), `gpu-computing-standards` (aceleradores
y su aprovisionamiento — **los simuladores cuánticos corren aquí**), `deep-learning-standards`
y `classical-ml-standards` (el baseline clásico que cualquier propuesta "quantum ML" debe
batir **antes** de considerarse), `ai-governance-standards` (gobernanza de reclamaciones
tecnológicas y diligencia debida sobre proveedores), `grc-compliance-standards` (aceptación
formal de riesgo tecnológico y evidencia), `tech-leadership-standards` (decisión de
*build-vs-buy* y de invertir en I+D no productiva), `python-standards` (el lenguaje de
Qiskit, Cirq y PennyLane), `blockchain-web3-standards` (Ola 7: el "riesgo cuántico" sobre
firmas de cadena se trata allí como riesgo, y su remedio en `post-quantum-crypto`),
`llm-app-engineering-standards` y `mlsecops-standards` (**nada que ver**: "quantum" en
marketing de IA no es esto).

## 2. Decisiones por defecto

> Verificar por web antes de fijar nada (§8). Este dominio cambia de titular cada trimestre y
> la mitad de los titulares se corrigen después.

| Decisión | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| ¿Invertir? | **I+D y formación, con presupuesto acotado y objetivo de aprendizaje** | Investigación aplicada si el negocio es química, materiales o farma | Proyecto de producción con fecha de entrega |
| Primer entregable | **Estimación de recursos** de tu problema en qubits lógicos y puertas | Prototipo en simulador | Ejecutar en hardware real "a ver qué sale" |
| Baseline | **Siempre el mejor algoritmo clásico disponible**, medido | — | Comparar contra fuerza bruta clásica para inflar la ventaja |
| Acceso a hardware | **Nube por horas** (IBM Quantum Platform, Amazon Braket, Azure Quantum) | Convenio con centro de investigación | **Comprar hardware**: obsoleto antes de amortizarse |
| SDK | **Qiskit** (**Apache-2.0**, `LICENSE.txt`: *"Copyright 2017 IBM and its contributors / Apache License Version 2.0"*) si el objetivo es IBM; **Cirq** (**Apache-2.0**) para Google; **PennyLane** (**Apache-2.0**) para variacional y diferenciación automática; **Q#/QDK** (**MIT**, *"Copyright (c) Microsoft Corporation"*) para el ecosistema Microsoft | Escribir/exportar a **OpenQASM** para no atarse al SDK | Diseñar sobre un SDK propietario de un fabricante único |
| Modelo | **Puertas** para cualquier algoritmo con ventaja demostrada | **Annealing** (D-Wave) **solo** para optimización combinatoria formulable como QUBO/Ising, y comparado contra un solver clásico | Presentar annealing y puertas como lo mismo |
| Cripto | **Ir a `post-quantum-crypto-standards` y ejecutar su plan** | — | Esperar a "cuando llegue el ordenador cuántico" |

## 3. Modelos y algoritmos: dónde hay ventaja y dónde no

### 3.1 Puertas frente a *annealing* — no son lo mismo

- **Modelo de puertas** (IBM, Google, Quantinuum, IonQ…): universal. Es el único que puede
  ejecutar Shor, Grover, estimación de fase o simulación hamiltoniana. Es donde vive toda la
  teoría de ventaja demostrada.
- **Annealing cuántico** (D-Wave): **no es universal**. Resuelve una familia concreta de
  problemas de optimización (formulables como QUBO/Ising) buscando el estado fundamental de
  un hamiltoniano. Tiene muchos más qubits, y esa cifra **no es comparable** con la de una
  máquina de puertas: son unidades distintas. **No puede ejecutar Shor.** La ventaja del
  annealing frente a los mejores heurísticos clásicos sigue siendo objeto de disputa, y varias
  demostraciones han sido igualadas o superadas por métodos clásicos.

Confundir ambos modelos, o comparar sus recuentos de qubits, es el error de lectura más común
en material comercial y en prensa.

### 3.2 Algoritmos con ventaja demostrada

| Algoritmo | Ventaja | Estado real |
|---|---|---|
| **Shor** (factorización, log discreto) | **Exponencial** | Demostrada en teoría. Irrealizable con el hardware actual (§1.1) |
| **Grover** (búsqueda no estructurada) | **Cuadrática** (√N) | Real pero modesta; el coste de cargar los datos suele comerse la ventaja |
| **Estimación de fase / simulación hamiltoniana** | Exponencial para ciertos sistemas | El caso de uso más creíble: química cuántica y materiales |
| **VQE / QAOA** (variacionales) | **Ninguna demostrada** | Heurísticas. Sufren *barren plateaus*. Compiten mal con solvers clásicos |
| **"Quantum machine learning"** | **Ninguna demostrada** en datos clásicos | El cuello de botella es cargar datos clásicos en estados cuánticos |

### 3.3 Grover NO rompe la criptografía simétrica — dilo explícitamente

Es la confusión más extendida y la que más presupuesto desvía. **La ventaja de Grover es
cuadrática, no exponencial**: reduce una búsqueda de 2ⁿ a 2^(n/2). Sobre AES-128 eso equivale
a un ataque de ~2⁶⁴ operaciones cuánticas **secuenciales**, que no es una amenaza práctica —
y sobre AES-256 no queda ni cerca.

NIST IR 8105, *Report on Post-Quantum Cryptography* (abril 2016), §2, verbatim:

> *"Grover's algorithm provides a quadratic speed-up for quantum search algorithms in
> comparison with search algorithms on classical computers. We don't know that Grover's
> algorithm will ever be practically relevant, but if it is, doubling the key size will be
> sufficient to preserve security. Furthermore, it has been shown that an exponential speed up
> for search algorithms is impossible, suggesting that symmetric algorithms and hash functions
> should be usable in a quantum era."*

Y su Tabla 1: **AES → "Larger key sizes needed"**; **SHA-2, SHA-3 → "Larger output needed"**;
**RSA, ECDSA/ECDH, DSA → "No longer secure"**.

Conclusión operativa: **el problema es exclusivamente la criptografía de clave pública.**
AES-256 y SHA-384 siguen valiendo. Quien te venda "sustituir tu cifrado simétrico por cuántico"
no ha leído esto. **El plan de sustitución de la clave pública es de
`post-quantum-crypto-standards`.**

### 3.4 "Harvest now, decrypt later": lo único urgente hoy

El tráfico y los datos cifrados **hoy** con clave pública clásica pueden estar siendo
capturados y almacenados para descifrarlos cuando exista la máquina. Si tu dato debe seguir
siendo confidencial dentro de 10-20 años (historia clínica, secreto industrial, información
clasificada, datos personales de larga vida), **la exposición ya está ocurriendo**, con
independencia de cuándo llegue el hardware.

**Y aquí termina esta skill**: el criterio de priorización por vida útil del dato, el
inventario criptográfico, la elección de algoritmo, los híbridos y el calendario normativo
son **enteramente de `post-quantum-crypto-standards`**. No se duplica nada aquí. Si la
pregunta es "qué hago", la respuesta es ir allí.

## 4. Ventaja cuántica: el patrón dominante es la refutación

**Toda reclamación de ventaja cuántica debe tratarse como provisional hasta que sobreviva a
varios años de mejora de los algoritmos clásicos.** No es escepticismo: es el historial.

Caso de referencia. Google reclamó en 2019 supremacía cuántica con Sycamore (53 qubits, 200
segundos frente a un estimado de 10.000 años clásicos). En 2024-2025, *"Leapfrogging Sycamore:
harnessing 1432 GPUs for 7× faster quantum random circuit sampling"* (*National Science
Review*, colección de marzo de 2025), abstract verbatim: *"Here we report an energy-efficient
classical simulation algorithm, using 1432 GPUs to simulate quantum random circuit sampling
that generates uncorrelated samples with a higher linear cross-entropy score and is 7× faster
than the Sycamore 53-qubit experiment."* Y su conclusión, también verbatim: *"Our work
provides the first unambiguous experimental evidence to refute Sycamore's claim of quantum
advantage, and redefines the boundary of quantum computational advantage using random circuit
sampling."*

Es decir: **la demostración de supremacía más famosa de la historia del campo fue refutada
clásicamente**, no por mejor hardware sino por mejor software, sobre GPUs disponibles
comercialmente. El mismo patrón se ha repetido con varias reclamaciones de *boson sampling*.

Consecuencias de método:
- El listón "esto es clásicamente imposible" se mueve **hacia abajo** con el tiempo. Una
  ventaja demostrada este año puede ser un cálculo de clúster el que viene.
- **Las tareas de las demostraciones de ventaja no son útiles.** *Random circuit sampling* y
  *boson sampling* se eligen precisamente porque son duras de simular, no porque resuelvan
  nada. Ventaja ≠ utilidad.
- Reclamaciones más recientes (Google presentó en octubre de 2025 un experimento llamado
  *Quantum Echoes* sobre un subconjunto de 65 qubits de Willow, descrito como la primera
  ventaja cuántica **verificable**, con un factor citado de ~13.000×) **no se pudieron
  verificar en fuente primaria en esta pasada** y deben tratarse como afirmación del
  fabricante pendiente de réplica independiente (§8).

**Cifras de qubits de hoja de ruta**: los planes de los fabricantes (p. ej. IBM anunciando un
sistema tolerante a fallos con **200 qubits lógicos y 100 millones de puertas para 2029**)
son **objetivos comerciales**, no capacidad entregada, y esa cifra entró aquí por búsqueda
web y **no por fuente primaria** (el sitio de IBM devolvió 403). Tratar toda hoja de ruta como
lo que es: una intención, con historial de deslizamiento en todo el sector.

## 5. Coste y cuándo tiene sentido invertir

- **La inversión que casi siempre tiene sentido**: formación de dos o tres personas, un
  presupuesto pequeño de tiempo de nube, y **una estimación de recursos** para los problemas
  candidatos del negocio. Coste bajo, retorno principal: **saber decir que no** con criterio
  cuando llegue el proveedor.
- **La inversión que casi nunca tiene sentido**: comprar hardware, comprometer una fecha de
  producto, o financiar un piloto de optimización empresarial sin baseline clásico medido.
- **Filtro de tres preguntas para cualquier propuesta**:
  1. ¿Cuál es el **problema formulado matemáticamente** y qué algoritmo cuántico concreto lo
     resuelve?
  2. ¿Cuántos **qubits lógicos** y cuántas puertas requiere, y cuándo estarán disponibles
     según la estimación de recursos?
  3. ¿Qué hace el **mejor algoritmo clásico** hoy con el mismo problema, medido?
  Si falta cualquiera de las tres, la respuesta es no.
- **El baseline clásico se mide, no se supone.** Muchos "problemas cuánticos" desaparecen
  cuando alguien perfila el código clásico existente.
- **Reproducibilidad**: el hardware cuántico es ruidoso y cambiante. Un resultado sin número
  de *shots*, sin calibración del dispositivo del día, sin semilla y sin la estrategia de
  mitigación de errores usada **no es reproducible ni comparable**.

## 6. Prácticas de ingeniería (si aun así vas a experimentar)

- **Circuitos en control de versiones**, con exportación a **OpenQASM** además del SDK, para
  no depender de un fabricante.
- **Simulador primero, siempre.** Si el circuito no funciona sin ruido, no va a funcionar con
  ruido. El simulador es determinista y barato; el hardware, ni una cosa ni la otra.
- **Registrar por ejecución**: dispositivo, fecha, calibración, número de *shots*,
  transpilación aplicada y método de mitigación de errores. Sin eso el resultado no se puede
  defender.
- **La transpilación cambia el circuito**: el mapeo a la conectividad real inserta puertas
  SWAP y puede multiplicar la profundidad. Medir el circuito **transpilado**, no el escrito.
- **Coste de nube acotado por presupuesto duro**: el tiempo de QPU se factura por ejecución y
  un barrido de parámetros mal planteado se come el presupuesto del trimestre.
- **Datos sensibles**: la ejecución en nube cuántica es ejecución en un tercero. Aplican las
  mismas reglas de clasificación de datos que a cualquier SaaS.

## 7. Sostenibilidad y prohibiciones

Cadencia: revisar el estado del campo **una vez al año**, no cada titular. Lo que cambia de
verdad —fidelidad de puerta, qubits lógicos operativos, coste de recursos de Shor— se mueve
en años. Lo que cambia cada semana es el marketing.

**Prohibiciones explícitas:**

- ❌ **PROHIBIDO** vender, prometer o presupuestar "ventaja cuántica" en un proyecto de negocio
  **sin un problema formulado matemáticamente**, sin el algoritmo concreto que lo resuelve y
  sin la estimación de recursos que diga cuándo sería ejecutable.
- ❌ **PROHIBIDO** citar cifras de qubits **sin distinguir físicos de lógicos** y sin la
  fidelidad de puerta de dos qubits y la conectividad. Un número de qubits solo no significa
  nada.
- ❌ **PROHIBIDO** presentar una hoja de ruta de fabricante como capacidad disponible.
- ❌ **PROHIBIDO** afirmar que la computación cuántica "rompe el cifrado" sin precisar que se
  refiere **solo a la clave pública**, y que Grover **no** rompe la simétrica (§3.3).
- ❌ **PROHIBIDO** comparar recuentos de qubits entre *annealing* y modelo de puertas, o
  presentarlos como la misma tecnología.
- ❌ **PROHIBIDO** citar una reclamación de ventaja cuántica sin comprobar si ha sido igualada
  o refutada clásicamente. El caso Sycamore es el precedente, no la excepción.
- ❌ **PROHIBIDO** proponer un piloto de optimización o de "quantum machine learning" sin un
  baseline clásico **medido** con el mejor solver disponible.
- ❌ **PROHIBIDO** justificar una compra de hardware cuántico con argumentos de posicionamiento
  o de imagen.
- ❌ **PROHIBIDO** publicar un resultado de hardware cuántico sin *shots*, calibración,
  transpilación y método de mitigación de errores.
- ❌ **PROHIBIDO** duplicar aquí criterio de migración post-cuántica: algoritmos, plazos e
  inventario son de `post-quantum-crypto-standards`.
- ❌ **PROHIBIDO** aplazar la migración post-cuántica alegando que "la máquina no existe": el
  modelo de amenaza es de captura hoy y descifrado después (§3.4).

## 8. Verificación web obligatoria

Antes de fijar nada:

1. **Estado de la corrección de errores**: número de **qubits lógicos operativos** (no de
   memoria) y su tasa de error, en publicación revisada por pares. Lo verificado aquí:
   Google, distancia 7 sobre **101 qubits físicos**, Λ = 2,14 ± 0,02, 0,143 % de error lógico
   por ciclo, vida 2,4 ± 0,3× la del mejor qubit físico (arXiv:2408.13687, verbatim del
   abstract). Comprobar qué ha cambiado desde entonces.
2. **Coste de un ataque a RSA/ECC**: la estimación vigente. La última verificada es Gidney
   2025: *"less than a week … with less than a million noisy qubits"* para RSA-2048, bajo
   supuestos explícitos de tasa de error y tiempos de ciclo. **Esta cifra ha bajado 20× en
   seis años por mejoras algorítmicas: volver a comprobarla es obligatorio, no opcional.**
3. **Reclamaciones de ventaja cuántica**: si la que te citan sigue en pie. Verificado aquí:
   Sycamore 2019 **refutada** por simulación clásica sobre 1432 GPUs (*National Science
   Review*, verbatim). **Hueco declarado**: el experimento *Quantum Echoes* de Google
   (oct-2025, ~65 qubits, ~13.000×, "verifiable quantum advantage") **entró por WebSearch y no
   se pudo confirmar en fuente primaria** — el blog de Google devolvió 404 y el identificador
   de arXiv probado correspondía a otro artículo. **No usarlo sin verificarlo.**
4. **Hojas de ruta de fabricante**: IBM Starling (200 qubits lógicos, 100 M de puertas, 2029),
   Nighthawk y Loon **entraron por WebSearch**: `ibm.com/roadmaps/quantum` y el blog de IBM
   Quantum devolvieron 403. **Hueco declarado**: confirmar en fuente primaria antes de citar
   cualquiera de esos números, y tratarlos siempre como objetivo, no como capacidad.
5. **SDKs**: versión actual y licencia. Verificadas en crudo: **Qiskit Apache-2.0**, **Cirq
   Apache-2.0**, **PennyLane Apache-2.0**, **Q#/QDK MIT**. Comprobar además si el SDK sigue
   activo y si el fabricante ha cambiado el modelo de acceso a hardware.
6. **NIST IR 8105** es de **abril de 2016**: su tabla sobre el impacto por algoritmo sigue
   siendo correcta conceptualmente, pero **el calendario y los algoritmos concretos están
   superados** por FIPS 203/204/205 y por NIST IR 8547 — todo eso vive en
   `post-quantum-crypto-standards`, que es donde hay que ir.
7. **D-Wave y annealing**: si la reclamación de ventaja que se cite ha sido igualada por
   métodos clásicos. Ha ocurrido varias veces.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
