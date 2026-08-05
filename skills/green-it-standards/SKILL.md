---
name: green-it-standards
description: Use when the carbon or energy footprint of IT has to be a number someone can defend — Software Carbon Intensity and ISO/IEC 21031, the SCI formula (E × I + M) per R and choosing a functional unit, GHG Protocol scopes 1/2/3 and the scope 2 market-based versus location-based split, the GHG Protocol scope 2 revision with hourly matching and deliverability, grid carbon intensity data per region and hour (Electricity Maps, WattTime marginal MOER, Ember, CO2 Signal, Carbon Aware SDK, grid-intensity CLI), carbon-aware scheduling and region or time shifting, embodied versus operational emissions and hardware lifetime extension, PUE, WUE, ERF and REF under ISO/IEC 30134-2 and the EU data centre reporting scheme (Energy Efficiency Directive 2023/1791, Delegated Regulation 2024/1364, the European Database on Data Centres and its 15 May deadline), CSRD and ESRS E1 after the Omnibus Directive (EU) 2026/470, cloud provider carbon tools (AWS Sustainability console and the deprecated Customer Carbon Footprint Tool, Google Cloud Carbon Footprint, Microsoft Emissions Impact Dashboard) and why their numbers are not comparable, Cloud Carbon Footprint, Kepler, Scaphandre, RAPL and powercap energy readings, offsets versus real reduction, 100% renewable claims by certificate versus hourly matching, idle and zombie resource elimination, e-waste, WEEE, Ecodesign Regulation 2019/424 for servers and right to repair, or the energy cost of training and inference.
---

# Estándares de TI sostenible (Green IT)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**La sostenibilidad de TI se mide o no existe.** No hay tercera opción, y este documento no
concede ninguna. Una afirmación de sostenibilidad sin **línea base**, **método declarado**,
**frontera del sistema** y **unidad funcional** no es una afirmación débil: **es una afirmación
vacía**, y se trata como tal — se rechaza en revisión igual que se rechazaría un *benchmark* sin
condiciones de ejecución.

Y la segunda mitad de la tesis, que es la incómoda: **la mayor parte de lo que se publica sobre
Green IT no es medible**. «Optimizamos el código para reducir la huella», «migramos a la nube y
somos más verdes», «nuestra región es 100 % renovable» — ninguna de las tres es verificable tal
como está escrita, y las tres son frases reales de material corporativo. Esta skill es
deliberadamente **severa con la prosa vacía**: si una frase no lleva número, método y fuente, no
entra en un documento, en un informe ni en un PR.

**Regla de arranque, y ordena todo lo demás**: *primero apaga, luego dimensiona, luego coloca,
y solo entonces —si la escala lo justifica— optimiza el código* (§3.4). Casi todo el trabajo de
Green IT que se publica ataca el último paso, que es el de menor impacto y mayor coste. **Un
servidor apagado tiene intensidad de carbono cero con certeza absoluta y coste de ingeniería
cero.** Ninguna optimización compite con eso.

Cubre: qué se puede medir de verdad y qué no; **SCI / ISO/IEC 21031** y la elección de unidad
funcional; **GHG Protocol** y por qué el alcance 3 concentra el impacto **y** la incertidumbre;
**huella incorporada vs. operativa** y la consecuencia contraintuitiva sobre la vida útil del
equipo; **intensidad de carbono de la red por región y hora** y sus fuentes de datos; el orden
real de las palancas; la relación —y la **divergencia**— con FinOps; **greenwashing** y
contabilidad creativa; regulación (**CSRD** tras el Omnibus, **EED** y el esquema de informe de
centros de datos, ecodiseño y **WEEE**); residuos electrónicos y ciclo de vida; y herramientas,
con su fiabilidad real.

Triggers: SCI, `E × I + M`, unidad funcional, ISO/IEC 21031, ISO/IEC 30134-2, PUE, WUE, ERF,
REF, GHG Protocol, alcance 1/2/3, *market-based* / *location-based*, *hourly matching*,
*deliverability*, MOER, intensidad de carbono marginal vs. media, Electricity Maps, WattTime,
Ember, CO2 Signal, Carbon Aware SDK, `grid-intensity`, Cloud Carbon Footprint, Kepler,
Scaphandre, RAPL, `powercap`, `intel-rapl`, Redfish, AWS Sustainability console, Customer Carbon
Footprint Tool, Google Cloud Carbon Footprint, Emissions Impact Dashboard, huella incorporada,
*embodied carbon*, LCA, ISO 14040/14044, PCF, CSRD, ESRS E1, Directiva (UE) 2026/470,
Directiva (UE) 2023/1791, Reglamento Delegado (UE) 2024/1364, European Database on Data Centres,
Reglamento (UE) 2019/424, WEEE, RAEE, derecho a reparar, compensaciones, REC/GO/PPA,
*carbon-aware scheduling*, recursos ociosos, *zombie*.

**No aplica**: ver `finops-standards` (**ya escrita — frontera importante y recíproca, y la más
fácil de confundir**: las palancas son casi las mismas —apagar lo ocioso, dimensionar, elegir
región, comprometer capacidad— pero **la métrica no lo es**. **La unidad económica —coste por
petición, por usuario, por GB, por token— es suya; la unidad de carbono —gCO2e por esa misma
unidad funcional— es de aquí.** Se comparten los datos de uso y **se comparte el inventario de
recursos ociosos**, pero cuando coste y carbono divergen —y divergen, §3.5— **ninguna de las dos
gana automáticamente: la divergencia se declara y decide un humano con las dos cifras
delante**), `onprem-standards` y `homelab-standards` (**el centro de datos físico es suyo**:
refrigeración, distribución eléctrica, UPS, contención de pasillos, generación in situ,
dimensionado del rack. **Aquí solo la contabilidad de lo que consumen y qué métricas de ese
centro de datos son reportables**), `gpu-computing-standards` (**densidad, TDP, refrigeración
líquida y planificación de la GPU ya son suyos**; aquí **la contabilidad de su huella**,
operativa e incorporada), `aws-standards` / `azure-standards` / `gcp-standards` (**los datos, la
herramienta y la metodología de cada proveedor son suyos**, junto con la elección concreta de
región y servicio; aquí **por qué esos números no son comparables entre proveedores** y qué se
puede afirmar con ellos), `kubernetes-standards` (**utilización, *requests*/*limits*, escalado y
consolidación de nodos son suyos**; aquí el hecho de que la utilización es la palanca de carbono
de mayor impacto y cómo se contabiliza), `grc-compliance-standards` (**el informe de
sostenibilidad corporativo, su aseguramiento, el doble análisis de materialidad y la evidencia de
auditoría son suyos**; aquí el dato técnico que lo alimenta y su método), `local-inference-
standards` y `mlops-standards` (**el coste energético del entrenamiento y de la inferencia —qué
modelo, qué cuantización, qué batch, qué acelerador— es suyo**; aquí cómo se convierte ese
consumo en gCO2e y con qué incertidumbre), `performance-engineering-standards` (**ya escrita**:
**la metodología de medir y optimizar —perfilado, generador de carga, estadístico, reproducción
del experimento— es suya, sin excepción**; aquí **la métrica de carbono** que se le acopla.
Corolario: *una optimización de rendimiento se valida con su método, no con el mío*; esta skill
no vuelve a decidir cómo se perfila nada), `opensource-licensing-standards` (**la licencia de
las herramientas de medición de carbono se rige por esa skill** — y hay motivo: los datos de
intensidad de red tienen condiciones de uso que varían de CC BY 4.0 a «no comercial», §2).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Ámbito | Default | Motivo / alternativa justificable |
|---|---|---|
| Métrica de software | **SCI** — `SCI = (E × I + M) per R` (verbatim de la GSF) | **Es una *tasa*, no un total**: por eso no se puede reducir creciendo menos ni comprando nada. Es la única propiedad que la hace útil para ingeniería |
| Norma de referencia | **ISO/IEC 21031:2024** (SCI) | La GSF la describe como «The only ISO-accredited carbon measurement standard for software». Verificar edición vigente (§8) |
| Marco de contabilidad corporativa | **GHG Protocol** (Corporate Standard + Scope 2 Guidance + Scope 3 Standard) | Es el lenguaje que exigen CSRD, CDP y SBTi. **No es intercambiable con SCI** (§3.1) |
| Alcance 2 | **Reportar SIEMPRE las dos: *location-based* y *market-based*** | CSRD las exige ambas, y **la diferencia entre ellas es la medida directa de tu greenwashing potencial** (§3.6). Publicar solo la *market-based* es la señal de alarma número uno |
| Datos de intensidad de red | **Ember** (CC BY 4.0) como base redistribuible; **Electricity Maps** o **WattTime** para granularidad horaria | Ember es abierta y con licencia clara, pero **mensual/anual**: no sirve para decidir *a qué hora*. Los otros dos: capa gratuita **de una sola zona**, y **no comercial** en el caso de Electricity Maps (§2 de `opensource-licensing-standards`) |
| Señal media vs. marginal | **Media (*average*) para contabilidad; marginal (MOER) para decisiones de desplazar carga** | **No son intercambiables y confundirlas es el error más común del dominio.** La media responde «cuánto emitió lo que consumí»; la marginal, «cuánto cambia si consumo más o menos ahora». Usar la media para justificar un desplazamiento de carga es un resultado inválido |
| Medición de energía en host | **RAPL / `powercap`** vía Kepler o Scaphandre | Es lo único disponible sin BMC. **Es del *paquete*, no de tu proceso**: la atribución a contenedor o proceso es un **modelo de reparto**, no una medida (§4.2). Muestreo ≥10 ms: por debajo aumenta el coste sin mejorar la precisión |
| Energía a nivel de máquina física | **Redfish / BMC / PDU medida** cuando exista acceso | Es la única medida real de la máquina. **En nube pública no la tienes**, y ese es el límite duro de todo lo demás |
| Herramienta en Kubernetes | **Kepler** (CNCF sandbox, Apache-2.0), **≥ 0.10.0** | 0.10.0 es una **reescritura completa** que descubre dinámicamente la estructura del medidor de potencia del host, en vez de asumir una topología RAPL fija —el diseño anterior **atribuía datos a una realidad inexistente**—. La línea 0.9.x está **congelada**: sin correcciones ni funcionalidades. **La migración no es transparente** |
| Estimación multinube | **Cloud Carbon Footprint** (Apache-2.0) solo para **comparación normalizada interna** | Usa constantes medias: **estima, no mide**. Y su cadencia de publicación es baja (el repositorio de coeficientes está archivado). **No usarlo como fuente para un informe regulado** |
| Dato de nube para informe externo | **La herramienta del propio proveedor** | Es la única que el proveedor respalda. Verificar por proveedor si el dato está **verificado por un tercero** (§3.6): a ago-2026 no todos lo están |
| Vida útil de hardware en el cálculo | **Declarar la asumida siempre** (4-5 años es lo habitual; CCF asume 4) | **Cambiar 4 por 6 años altera el resultado más que cualquier optimización de código.** Si no está declarada, la cifra no es interpretable |
| Compensaciones (*offsets*) | **Fuera del cálculo de reducción** | Se reportan **por separado y después**, nunca restando de la cifra bruta. Ver §7 |

## 3. Qué se puede medir, qué se estima y qué no se sabe

### 3.1 SCI: una tasa, y la diferencia con la contabilidad corporativa

`SCI = (E × I + M) per R`, donde **E** = energía consumida, **I** = intensidad de carbono de esa
energía, **M** = emisiones incorporadas del hardware, **R** = unidad funcional.

Tres consecuencias operativas que hay que entender antes de usarla:

1. **Es una tasa, y eso es deliberado.** No baja porque el negocio encoja, ni porque compres
   certificados. Solo baja si haces **más trabajo con menos**, o el mismo trabajo con energía
   más limpia. **Es la única métrica de esta skill que un equipo de ingeniería puede mover.**
2. **La unidad funcional `R` es la decisión que determina si la métrica sirve.** Debe ser algo
   que el equipo *produce*: petición, usuario activo, transacción, *build*, token, trabajo de
   entrenamiento. **`R` = «por servidor» o «por mes» convierte el SCI en un total disfrazado y
   lo inutiliza.** Se elige una vez, se documenta y **no se cambia sin recalcular la serie
   histórica** — cambiar `R` a mitad de camino es la forma más limpia de fabricar una mejora
   que no existe.
3. **SCI usa un enfoque *consecuencial*** —cuantificar el cambio marginal que provoca una
   decisión— frente al enfoque **atribucional** de la contabilidad corporativa, basado en datos
   medios. **Un SCI y un inventario GHG no se suman, no se comparan y no se validan entre
   sí.** Presentarlos como si fueran la misma cifra es un error de método, no de redondeo.

**Estado normativo**: publicada como **ISO/IEC 21031:2024**. **Discrepancia declarada**: la
página de la GSF sitúa la acreditación ISO en **abril de 2024**, mientras que otras fuentes dan
la publicación en **marzo de 2024** y su adopción en **mayo de 2024**; la especificación de la
GSF iba por la **v1.1** (oct-2024). Los tres datos conviven en fuentes distintas. **Antes de
citar una fecha en un documento formal, verificar en el catálogo de ISO** (§8).

### 3.2 GHG Protocol: dónde está el impacto y dónde la incertidumbre

- **Alcance 1**: combustión directa. En TI, prácticamente solo generadores de respaldo y
  refrigerantes fugados. **Marginal, y bien medido.**
- **Alcance 2**: electricidad comprada. **Dos métodos obligatorios y no equivalentes**:
  *location-based* (intensidad real de la red donde consumes) y *market-based* (refleja los
  certificados, GdO y PPA contratados). **Bien medido y fácil de maquillar** (§3.6).
- **Alcance 3**: todo lo demás de la cadena de valor — **fabricación del hardware, servicios en
  la nube que compras, el ciclo de vida completo del equipo, los dispositivos de tus usuarios**.

**En TI, el alcance 3 concentra a la vez casi todo el impacto y casi toda la incertidumbre, y
eso no es casualidad: es el mismo hecho visto dos veces.** Es grande porque incluye todo lo que
no controlas, y es incierto **exactamente por eso**: depende de datos de fabricantes con
metodologías distintas, de factores de emisión sectoriales medios, y de modelos económicos
*input-output* que convierten euros gastados en kg de CO2e con márgenes de error enormes. Que
una empresa reporte alcance 3 con dos decimales no significa que lo conozca con dos decimales.

**Regla dura**: **una cifra de alcance 3 se acompaña siempre de su método de cálculo**
(LCA basada en proceso, extrapolación, media de categoría, o *input-output* económico) y **de la
incertidumbre asociada**. Sin eso, no es un dato: es una estimación presentada como dato. Y una
prohibición que se deriva: **nunca compares dos cifras de alcance 3 calculadas con métodos
distintos** — la diferencia que veas será la diferencia entre los métodos, no entre las
empresas.

**Revisión en curso de la Scope 2 Guidance (2015) — afecta a decisiones que estás tomando hoy.**
Estado verificado: la consulta pública se abrió el **20-oct-2025**, cerró el **31-ene-2026** con
más de **400 respuestas**, y se espera una **segunda consulta durante 2026** con **publicación
final prevista en 2027** (algunas fuentes secundarias dicen **2027-2028** — **discrepancia
declarada**). El borrador **mantiene los dos métodos** y añade al *market-based*: **casación
horaria** (*hourly matching*) de los instrumentos contractuales, **requisito de entregabilidad**
(*deliverability*, un vínculo geográfico creíble con el generador) y una métrica complementaria
de **impacto marginal de emisiones**. La junta independiente aprobó llevarlo a consulta por
**10-1** en ambos métodos. Incluye exenciones para organizaciones pequeñas (**cuya definición
sigue sin cerrar**), cláusula heredada para contratos existentes e implantación por fases.

**Consecuencia para hoy, y es la parte accionable**: **la casación anual de certificados tiene
fecha de caducidad conocida**. Un PPA o una cartera de certificados que solo cuadra en el total
anual **va a dejar de sostener una declaración de energía limpia**. Si vas a firmar un contrato
plurianual de energía en 2026, **evalúalo contra el criterio horario, no contra el actual**.
Y no confundas ámbitos: esto **cambia la contabilidad, no el objetivo de compra**; no implica un
objetivo de casación horaria el año que viene.

### 3.3 Huella incorporada vs. operativa: la consecuencia contraintuitiva

El reparto entre **emisiones incorporadas** (fabricación, transporte, fin de vida) y
**operativas** (electricidad de uso) es el dato que más se cita mal del dominio, porque **no
existe un número único**: existe un rango que depende de tres variables que casi nunca se
declaran.

Lo que sí está documentado, con su fuente y su método:

- Un estudio sistemático (SCARIF) recopiló **96 informes de huella de producto de Dell, HP y
  Lenovo**, de servidores publicados **entre 2014 y 2022**, todos ellos elaborados con el flujo
  de la herramienta **PAIA**. Resultado de la **fase de fabricación** sobre el total del ciclo
  de vida: **Dell 9,5 %-27,7 %; HP 5,4 %-28,4 %; Lenovo 2,9 %-59,5 %**.
- Un estudio de 2025 sobre hardware de IA, *cradle-to-grave*, con vida útil de **4-5 años**, da
  el complemento operativo: **70 %-90 %** (2 servidores Dell), **66 %-94 %** (2 HP),
  **39 %-97 %** (2 Lenovo).
- El caso extremo publicado por el propio fabricante: un servidor de rack de Dell con
  **5.960 kg CO2eq de fase de uso, más del 90 % del total** en 4 años de operación continua.

**Las tres variables que producen ese rango — y son las tres que hay que declarar siempre:**

1. **Intensidad de carbono de la red.** En una red muy limpia, **la proporción se invierte**: la
   literatura señala que con electricidad eólica la fracción incorporada de un procesador x86
   pasaría a rondar el **80 %**. **En una región descarbonizada, tu problema es la fabricación,
   no el consumo.** Es exactamente lo contrario de lo que asume el discurso habitual.
2. **Configuración.** En la LCA del Dell R740, **cerca del 80 % de la huella incorporada se
   atribuye a los SSD**, y crece linealmente con la capacidad. **Sobredimensionar el
   almacenamiento es una decisión de carbono incorporado, no de coste.**
3. **Vida útil asumida.** Cloud Carbon Footprint asume **4 años**. Cambiar ese supuesto mueve
   el resultado más que cualquier optimización que vayas a hacer.

Y el fin de vida es pequeño: **el procesado de fin de vida no suele superar el 5 %** del ciclo
completo, y la LCA de Dell estima que el reciclaje reduce la huella incorporada en torno a
**1,8 %**. **Esto no es un argumento contra reciclar** —el reciclaje importa por materias
primas críticas y toxicidad, no por CO2e (§3.7)—; es un argumento contra **presentar el
reciclaje como una palanca de carbono**, que es donde acaba la mayoría de los informes.

**La consecuencia contraintuitiva, y es la conclusión más accionable de esta skill:**
**alargar la vida útil del equipo suele pesar más que optimizar su consumo.** La huella
incorporada es un **pago único** que se amortiza sobre la vida del equipo: pasar de 4 a 6 años
reduce la parte incorporada anualizada en **un tercio**, sin escribir una línea de código y sin
comprar nada. Ninguna optimización de eficiencia energética que vayas a conseguir se acerca a
esa magnitud. **La excepción que hay que comprobar, no asumir**: si el equipo nuevo es
sustancialmente más eficiente **y** operas en una red sucia, el cambio puede compensar. Es una
cuenta concreta —incorporada anualizada del equipo nuevo vs. exceso de operativa del viejo— y
**hay que hacerla, no invocarla**. En una red limpia casi nunca sale a favor de renovar.

**Trampa de método que invalida informes enteros**: la **LCA** (ISO 14040/14044) permite
**amortizar** la huella incorporada sobre la vida útil de la unidad funcional; el **GHG Protocol
Corporate Standard NO permite amortizar** las emisiones de bienes de capital sobre la vida del
hardware. **La misma flota produce dos cifras distintas y ambas son correctas en su marco.**
Mezclarlas —lo habitual— produce un número que no significa nada. Declara siempre en qué marco
estás.

### 3.4 El orden real de las palancas

Por impacto decreciente y coste de ingeniería creciente. **El orden es la regla; saltárselo es
la prohibición de §7.**

1. **Apagar lo ocioso.** Entornos de no producción fuera de horario, instancias huérfanas,
   volúmenes sin adjuntar, IP públicas reservadas sin uso, balanceadores sin *backend*, clústeres
   de pruebas de hace dos trimestres. **Reducción exacta y verificable: el 100 % de lo que
   consumían.** Es la única palanca con un resultado que no requiere estimar nada. El inventario
   es literalmente el mismo que usa `finops-standards`; **se hace una vez y sirve a las dos**.
2. **Dimensionar y consolidar.** Un servidor al 10 % de utilización consume una fracción muy
   alta de su potencia máxima: **la potencia no es proporcional a la carga**, y por eso
   consolidar dos máquinas al 20 % en una al 40 % ahorra energía real y **evita una unidad de
   huella incorporada**, que es el ahorro grande. La utilización es la palanca de carbono más
   potente que existe en `kubernetes-standards`.
3. **Alargar la vida útil del hardware** (§3.3). Barata, medible y de las de mayor magnitud.
4. **Elegir región.** La diferencia de intensidad de carbono entre regiones de un mismo
   proveedor es de **más de un orden de magnitud** entre las mejores y las peores. Es una
   decisión de despliegue de coste casi nulo — **con la restricción de que la región también es
   una decisión de latencia, soberanía de datos y coste**, y esas tres mandan sobre esta.
5. **Elegir hora** (*carbon-aware scheduling*). Aplica **solo a carga diferible**: *batch*,
   entrenamiento, *builds* nocturnos, compactaciones, copias. **No aplica a carga interactiva**,
   y proponerlo para carga interactiva es el error clásico. **Se decide con señal marginal, no
   media** (§2). Y su beneficio se **estima**; no lo declares como medido.
6. **Eficiencia del código.** **Solo cuando la escala lo justifica.** Un servicio con 100 rps no
   justifica un reescritura por carbono: el carbono del trabajo de ingeniería y de las horas de
   CI supera el ahorro. A escala de millones de peticiones, sí. **El umbral se calcula, no se
   intuye**, y la metodología para medir la mejora es de `performance-engineering-standards`, sin
   excepción.

**El PUE no está en esta lista**, y es intencionado: **el PUE no mide tu software** (§4.1).

### 3.5 FinOps y carbono: correlacionan, no son la misma métrica

Correlacionan porque comparten palancas: **apagar lo ocioso baja las dos, siempre**; dimensionar
también. Por eso el inventario, la asignación por etiquetas y la detección de recursos ociosos
**se comparten con `finops-standards` y no se duplican**.

**Pero divergen, y hay que nombrarlo con casos concretos:**

- **Instancias reservadas y planes de ahorro**: reducen el coste **y no cambian un gramo de
  CO2e**. Es la divergencia más pura que existe: **descuento puro sin efecto físico**. Una
  cobertura de compromiso del 90 % es una excelente noticia de FinOps y **una no-noticia** de
  carbono.
- **Instancias *spot*** abaratan mucho **y pueden empeorar el carbono**: una interrupción obliga
  a reejecutar trabajo, y **el trabajo repetido es energía repetida**. Barato ≠ eficiente.
- **Colocar carga en la región más limpia** puede ser **más caro** que la región barata, y
  además tener peor latencia. Ahí divergen las tres cosas a la vez.
- **Desplazar carga en el tiempo** para pillar la ventana limpia puede caer en una franja de
  precio alto de energía o de tarifa del proveedor.
- **Alargar la vida del hardware** reduce carbono y **puede aumentar el coste operativo**:
  equipos viejos consumen más por unidad de trabajo, ocupan más rack y fallan más.
- **Hardware nuevo y más eficiente** mejora el coste por unidad de trabajo **y añade una huella
  incorporada nueva de golpe** (§3.3).

**Regla de arbitraje**: cuando coste y carbono divergen, **ninguna métrica gana por defecto**.
Se presentan **las dos cifras con su método** y decide un humano con criterio de negocio. Y la
prohibición correspondiente: **no se presenta un ahorro de coste como si fuera un ahorro de
carbono**, ni al revés. Son dos números y se dicen los dos.

### 3.6 Greenwashing y contabilidad creativa

Los cuatro patrones que hay que saber detectar, porque los vas a encontrar **en tu propia
organización** antes que en la ajena:

1. **Compensar en vez de reducir.** Una compensación es una transacción financiera sobre
   emisiones de un tercero; **no reduce ni un gramo de las tuyas**. Se reporta **por separado y
   después** de la cifra bruta de reducción, nunca restándola. **Prohibición dura de §7.**
2. **«100 % renovable» por certificados.** Comprar GdO/REC suficientes para cubrir el consumo
   anual permite reportar cero en *market-based* **mientras la red que te alimenta quema gas a
   las tres de la mañana**. Es contablemente correcto hoy y **es exactamente lo que la revisión
   de la Scope 2 Guidance quiere corregir con la casación horaria y la entregabilidad**
   (§3.2). **La *location-based* es la que no se puede maquillar comprando nada.** Regla:
   **reporta ambas y publica la diferencia**; esa diferencia es la métrica honesta de cuánto de
   tu «cero» es contrato y cuánto es física.
3. **Fronteras del sistema móviles.** Migrar a la nube «reduce» tu alcance 2 porque **lo
   convierte en alcance 3 de otro** — el consumo eléctrico no ha cambiado; ha cambiado de
   casilla. Lo mismo con externalizar. **Un cambio de frontera no es una reducción, y
   presentarlo como tal es la forma más común de greenwashing involuntario.**
4. **Cifras sin método.** Un porcentaje de reducción sin línea base, sin frontera y sin método
   no es comparable ni con su propia serie histórica.

**Por qué los datos de los proveedores de nube NO son comparables entre sí.** Verificado a
ago-2026:

| Proveedor | Qué publica | Restricciones que impiden comparar |
|---|---|---|
| **AWS** | **AWS Sustainability console** (anunciada 31-mar-2026), con **MBM y LBM**, desglose por región, servicio y alcance 1/2/3. Metodología basada en GHG Protocol e ISO 14064, con guía sectorial TIC. Alcance 3 (oct-2025) cubre FERA, hardware, edificios, equipamiento y transporte; el hardware se estima con **cuatro vías distintas** (LCA por proceso, extrapolación, media de categoría, *input-output* económico). API programática (`sustainability`, `get_estimated_carbon_emissions`) y tabla `CARBON_EMISSIONS` en Data Exports | **El *Customer Carbon Footprint Tool* queda deprecado el 30-jun-2026**: cualquier cuadro de mando o script apuntando a él deja de servir. Granularidad de servicio históricamente limitada (EC2, S3, CloudFront; el resto agregado en «Other»). **Cuatro vías de cálculo para el mismo alcance 3 significa que dos servicios tuyos pueden no ser comparables entre sí** |
| **Google Cloud** | **Carbon Footprint**, según GHG Protocol; reparte sus alcances 1, 2 y 3 a los clientes por uso; datos por proyecto vía BigQuery | **Los datos específicos de cliente NO están verificados ni asegurados por un tercero.** Y a partir de los datos de **enero de 2026** cambió el modelo para asignar a los servicios las emisiones de inferencia de IA antes no asignadas: **las cifras reportadas suben sin que haya cambiado nada en tu uso** — una ruptura de serie que hay que anotar en la línea base |
| **Microsoft Azure** | **Emissions Impact Dashboard**, con MBM y LBM | Metodología menos accesible que la de Google (PDF frente a documentación web) |

**Regla dura, y no admite excepción**: **no compares cifras de carbono entre proveedores.**
Difieren la frontera del sistema, el método de asignación al cliente, el tratamiento del alcance
3, la granularidad temporal, el desfase de publicación y el estado de verificación
independiente. La única comparación defendible entre proveedores es **con una herramienta
tercera aplicando el mismo modelo a todos** (Cloud Carbon Footprint) — y entonces **estás
comparando el modelo, no la realidad**, y hay que decirlo así en el informe. La comparación
**intra-proveedor y a lo largo del tiempo sí es válida**, siempre que anotes las rupturas de
serie como la de Google de enero de 2026.

### 3.7 Residuos electrónicos y ciclo de vida

- **Jerarquía, en este orden y sin saltos**: *no comprar* > **alargar** (§3.3) > **reutilizar**
  (venta o donación con borrado certificado) > **reacondicionar** > **reciclar** > desechar.
  El reciclaje es el **penúltimo** recurso, no el primero, y su beneficio principal es la
  recuperación de **materias primas críticas y el control de tóxicos**, no el CO2e (§3.3).
- **Baja de equipo**: borrado o destrucción certificada con evidencia — es un requisito de
  seguridad **antes** que de sostenibilidad, y por eso el criterio manda desde
  `linux-hardening-standards` / `grc-compliance-standards`; aquí solo la exigencia de que
  **el borrado certificado sea la vía que habilita la reutilización**, en vez de la trituradora
  por defecto.
- **Cadena de custodia del reciclador**: gestor autorizado y trazabilidad documental. Sin
  certificado de tratamiento, **la exportación de residuo se convierte en tu problema legal**,
  no en el de nadie más.
- **Compra**: exige la **huella de producto (PCF) del fabricante** con su metodología, y
  requisitos de reparabilidad y disponibilidad de repuestos en el pliego. **La compra es el
  único momento en que puedes influir en la huella incorporada** — después ya está gastada.

## 4. Medición: qué es un dato y qué es una estimación

### 4.1 Métricas de instalación, y por qué el PUE no basta

**PUE** (ISO/IEC 30134-2) compara la potencia total de la instalación con la entregada al equipo
de TI. **Mide el centro de datos, no tu software**, y esto no es una crítica externa: **está en
la propia norma**, verbatim:

> «In order to determine the overall resource effectiveness or efficiency of a data centre, a
> holistic suite of metrics is required.»

Cuatro límites que hay que tener presentes antes de citar un PUE:

1. **Un servidor al 5 % de utilización y otro a plena carga útil son idénticos para la
   métrica.** El consumo de TI es el **denominador**, y la norma no evalúa si ese consumo hace
   algo útil. **Un PUE excelente es compatible con un desperdicio total.**
2. **La serie no fija límites ni objetivos** para ningún KPI, ni contempla agregar varios en una
   puntuación global. Citar un PUE como nota de sostenibilidad es un uso que la norma
   explícitamente no ampara — aunque otros esquemas (EN 50600-4-2, el Código de Conducta de la
   UE) sí fijen umbrales.
3. **Las categorías de medición rompen la comparabilidad**: PUE0 son estimaciones sin medida
   directa; PUE1 mide tras el SAI; PUE2 tras las PDU. **Dos instalaciones citando «PUE» en
   categorías distintas no son comparables** — y la categoría casi nunca aparece en el material
   comercial.
4. La norma evita deliberadamente llamarlo *efficiency*: usa **«effectiveness»**, reservando
   *efficiency* para cocientes con las mismas unidades arriba y abajo.

Existe **edición de 2026** de ISO/IEC 30134-2, con guía para edificios de uso mixto (variante
**mPUE**), requisitos de medición actualizados y mayor claridad sobre energía no contabilizada y
generación in situ. **Verificar cuál está vigente y en qué edición se apoya tu obligación
regulatoria** (§8). Para la eficiencia del lado TI, las métricas están en otras partes de la
misma serie (ITEUsv / ITEEsv y las de trabajo por energía).

### 4.2 Medición en host: qué es medida y qué es reparto

- **RAPL / `powercap`** reporta energía **a nivel de paquete/nodo**. Lo que Kepler o Scaphandre
  te dan **por contenedor, pod o proceso es un modelo de reparto** —típicamente proporcional a
  la utilización de CPU—, **no una medida**. Se dice así en el informe, siempre. Scaphandre y
  similares usan modelos de ratio con escalado lineal respecto a la utilización: **válido para
  facturación interna y tendencia; inválido para atribuir consumo a nivel de método o función**.
- **Aviso concreto sobre Kepler**: hasta 0.9.x asumía una estructura de potencia fija (núcleo,
  DRAM, otros) que **no corresponde a la topología real de muchos hosts** — es decir,
  **atribuía datos a una realidad inexistente**. Desde **0.10.0** descubre la estructura del
  medidor en tiempo de ejecución. **Si tienes 0.9.x en producción, tus series históricas
  arrastran ese sesgo** y no son comparables con las nuevas. Y hay crítica académica publicada
  de que Kepler **«has not been assessed for its accuracy and therefore fitness for purpose»**:
  **cítalo con esa cautela, no como verdad instrumentada.**
- **Muestreo**: las lecturas RAPL son estables a intervalos de **10 ms o más gruesos**; por
  debajo del milisegundo solo añades sobrecarga sin ganar precisión.
- **En nube pública no hay RAPL fiable ni acceso a BMC/Redfish.** Ahí **todo es estimación**, y
  la única fuente defendible ante un auditor es la del proveedor.
- **La medición tiene su propio coste energético.** Un agente por nodo, con su *scrape*, su
  almacenamiento de series y sus paneles, consume. **Instrumentar más de lo que vas a usar para
  decidir es una pérdida neta, también en carbono.**

### 4.3 Qué se le exige a una afirmación para ser aceptada

Estos son los **gates de revisión**. Una afirmación de sostenibilidad que no los cumpla **se
rechaza en revisión, igual que un test sin aserción**:

- ❌ **Sin línea base explícita** (periodo, alcance, frontera del sistema).
- ❌ **Sin método declarado** (SCI / GHG Protocol / LCA — y cuál de sus vías).
- ❌ **Sin unidad funcional**, cuando se afirma una eficiencia.
- ❌ **Sin fuente y versión del factor de emisión** y de la intensidad de red usada.
- ❌ **Sin declarar si es medida, estimada o modelada.** Casi todo es estimado: decirlo no
  debilita el resultado, lo hace utilizable.
- ❌ **Sin declarar la vida útil asumida**, cuando interviene huella incorporada.
- ❌ **Sin declarar si la señal de red es media o marginal** (§2).
- ❌ **Con cambio de unidad funcional, de frontera o de modelo del proveedor a mitad de serie**,
  sin recalcular el histórico o anotar la ruptura.

## 5. Regulación y datos de terceros

**No es asesoramiento jurídico.** Estas fechas y umbrales son criterio de ingeniería para saber
qué datos hay que poder producir y cuándo; la obligación concreta de tu entidad la determina
asesoría cualificada y `grc-compliance-standards`.

### 5.1 CSRD tras el paquete de simplificación (Omnibus)

**Cambió de forma sustancial y mucha documentación de 2024-2025 ya es falsa.** Verificado a
ago-2026:

- La directiva «Omnibus» se publicó en el DOUE el **26-feb-2026** tras su adopción por el
  Consejo el **24-feb-2026** (el Parlamento había aprobado el acuerdo el **16-dic-2025**). Es la
  **Directiva (UE) 2026/470**, en vigor desde el **18-mar-2026**.
- **Umbrales muy elevados**: desde el ejercicio **2027** (informe en **2028**) la CSRD aplica a
  grandes empresas cotizadas de la UE, empresas de la UE con **más de 1.000 empleados y más de
  450 M€ de cifra de negocio neta**, y empresas de fuera de la UE con **más de 450 M€** de
  facturación en la UE con filial o sucursal que supere **200 M€**. PYME cotizadas y sociedades
  holding financieras quedan **exentas**.
- **Alrededor del 90 % de las empresas antes en el ámbito (unas 42.000) quedan fuera.**
- **Aseguramiento limitado**: se mantiene; **se elimina** el paso previsto a aseguramiento
  razonable. Se **descartan** las ESRS sectoriales. **Desaparece** la obligación de preparar un
  plan de transición climática compatible con el Acuerdo de París.
- **Transposición**: **19-mar-2027** para las modificaciones de la Directiva Contable/CSRD y
  **26-jul-2028** para la CSDDD. Hay cláusula de revisión de umbrales.

**Consecuencia de ingeniería, y es la única que importa aquí**: **es muy probable que tu
organización haya salido del ámbito**. Eso **no elimina la necesidad del dato**: sigue llegando
por **la cadena de valor** (tus clientes en ámbito te lo pedirán como su alcance 3), por
contratación pública, por financiación y por la EED (§5.2), que **no depende de la CSRD**. **No
desmontes la instrumentación porque haya caído la obligación de reporte**: cambió quién firma el
informe, no quién necesita el número.

### 5.2 Centros de datos: la EED y el esquema de informe de la UE

Esta obligación **no la tocó el Omnibus** y es la que más directamente afecta a quien opera
infraestructura propia.

- Base: **Directiva de Eficiencia Energética (UE) 2023/1791** y **Reglamento Delegado (UE)
  2024/1364** (adoptado en marzo de 2024, **en vigor el 6-jun-2024**), primera fase del esquema
  común de calificación de centros de datos de la Unión.
- **Umbral**: todo centro de datos con **potencia de TI instalada ≥ 500 kW** informa
  **anualmente** a la **European Database on Data Centres**, a través del sistema nacional de
  cada Estado miembro. Exentos defensa y protección civil. Cubre centros **de empresa,
  *colocation* y *co-hosting***.
- **Plazos**: el primer informe (año 2023) venció el **15-sep-2024**; **desde 2025 el plazo es
  el 15 de mayo** del año siguiente al reportado — **15-may-2026 para el año natural 2025**.
- **Contenido**: **24 puntos de datos** de energía y sostenibilidad, capacidad TIC y tráfico. Se
  calculan y publican cuatro indicadores: **PUE, WUE, ERF y REF**. **El informe de equipamiento
  TIC solo concierne al instalado después del 6-jun-2024**.
- **Lo que viene**: se espera un **segundo reglamento delegado en junio de 2026** con el esquema
  formal de calificación y etiquetado; y **desde el 15-ago-2027**, y anualmente, la base de
  datos europea generará automáticamente una **etiqueta electrónica** para los centros que hayan
  informado, válida de 15 de agosto a 15 de agosto. **Verificar (§8): son fechas previstas.**
- **Fricción real declarada**: a principios de 2025 solo unos pocos Estados miembros habían
  implantado el sistema nacional de reporte (Alemania y Austria entre ellos). **Comprueba el de
  tu jurisdicción antes de asumir que existe un canal.**

### 5.3 Ecodiseño, residuos y reparación

- **Reglamento (EU) 2019/424** — requisitos de ecodiseño para servidores y productos de
  almacenamiento de datos: eficiencia mínima de fuente de alimentación y de estado activo,
  eficiencia material (desmontaje de determinados componentes) e información de clase de
  condiciones de operación. **Está en revisión y se espera revisado en 2026**; el borrador
  conocido **elimina exenciones** para *server appliances*, servidores grandes y servidores
  totalmente tolerantes a fallos. **Verificar antes de escribir un pliego de compra** (§8).
- **WEEE (Directiva 2012/19/UE)** — en revisión. La Comisión publicó su evaluación el
  **2-jul-2025** con cinco deficiencias mayores; se espera **propuesta formal en el 3T de 2026**
  dentro de la Circular Economy Act, con la posibilidad de **elevarla de Directiva a Reglamento**
  (aplicabilidad directa, sin transposición). **Hueco: la forma jurídica final no está decidida
  — no lo des por hecho** (§8).
- **Derecho a reparar — Directiva (UE) 2024/1799**: obligaciones aplicables en la UE desde el
  **31-jul-2026**. Afecta a categorías de producto especificadas (disponibilidad de repuestos e
  información de reparación) y al diseño orientado a reparabilidad. **Verifica si tu
  equipamiento entra en el ámbito antes de invocarla.**

### 5.4 Datos de intensidad de red: licencia antes que integración

| Fuente | Granularidad | Señal | Condiciones (verificar, §8) |
|---|---|---|---|
| **Ember** | Mensual / anual, 215 países | Media | **CC BY 4.0**, abierta y redistribuible. API REST propia. **La única sin restricción práctica para uso comercial** |
| **Electricity Maps** | **Horaria, tiempo real**, 200+ zonas | **Media** (no marginal) | Capa gratuita: **una sola zona**, **50 peticiones/hora**, **uso no comercial**, **sin previsión**. Acceso académico ampliado con correo institucional |
| **WattTime** | Horaria | **Marginal (MOER)** | Capa gratuita: **una región**. El MOER absoluto gratuito solo en `CAISO_NORTH`; el resto requiere suscripción. Cobertura ampliada a ~210 países |

**Aviso de método documentado**: se reportó contra el *Carbon Aware SDK* que documentaba
proporcionar «intensidad marginal» cuando **Electricity Maps entrega señal media**. **Verifica
qué señal te da tu proveedor antes de construir una decisión encima**: la etiqueta de la
librería no es garantía.

**Regla operativa**: la licencia de estas fuentes se decide con
`opensource-licensing-standards`. Una capa gratuita **no comercial** en un servicio de producción
es un incumplimiento de licencia, no un detalle de facturación — **y es exactamente el tipo de
caso que §3.6 de esa skill documenta**.

## 6. Operación y observabilidad de la métrica

- **Una serie temporal, no un informe anual.** El carbono se instrumenta como cualquier otra
  señal: se exporta a la misma pila de `observability-standards`, con la misma retención y las
  mismas etiquetas de asignación que usa `finops-standards`. **Un dato que solo existe en un PDF
  anual no ha cambiado ninguna decisión.**
- **Etiquetado compartido, no duplicado.** El carbono se asigna con **exactamente el mismo**
  esquema de etiquetas que el coste. Dos taxonomías paralelas garantizan que ninguna cuadre.
- **Panel mínimo, y bastan cinco cosas**: kWh por entorno; gCO2e *location-based* y
  *market-based* por separado; SCI por unidad funcional; **inventario de recursos ociosos**;
  utilización media de la flota. Todo lo demás es adorno hasta que alguien lo use para decidir.
- **Alertar sobre lo accionable**, que en este dominio significa **una cosa**: recursos ociosos
  o infrautilizados apareciendo. Alertar sobre gCO2e absolutos produce ruido: sube cuando el
  negocio crece, y eso no es un incidente.
- **Rupturas de serie con dueño**: cambio de modelo del proveedor (Google, ene-2026), cambio de
  herramienta (Kepler 0.9→0.10), cambio de factor de emisión, cambio de vida útil asumida.
  **Se anotan en la propia serie**, no en un correo. Una serie con una ruptura no documentada es
  una serie inútil retroactivamente.
- **La medición debe ganarse su sitio.** Si un agente de energía por nodo no ha cambiado una
  decisión en dos trimestres, se retira. **La instrumentación sin decisión es consumo con
  coartada.**

## 7. Sostenibilidad a largo plazo y prohibiciones

**Cadencia**: revisión de recursos ociosos, **mensual** (compartida con FinOps); revisión de
factores de emisión y de la fuente de intensidad de red, **anual**; revisión de la vida útil
asumida y del plan de renovación de flota, **anual**; verificación de fechas y umbrales
regulatorios, **semestral** — este dominio se movió entero entre 2025 y 2026 y volverá a
moverse.

**Deprecaciones activas a vigilar**: el *Customer Carbon Footprint Tool* de AWS **deja de existir
el 30-jun-2026** (migrar a la consola de Sustainability y su API); **Kepler 0.9.x está
congelada**; el modelo de Google cambió con los datos de **enero de 2026**. Cualquier cuadro de
mando, *script* o política de IAM apuntando a un origen deprecado es deuda con fecha conocida.

**PROHIBIDO:**

- ❌ **Afirmar una reducción sin línea base y sin método declarado.** Es la prohibición matriz:
  todas las demás son casos particulares.
- ❌ **Usar compensaciones como sustituto de reducir**, o restarlas de la cifra bruta. Se
  reportan aparte y después.
- ❌ **Comparar cifras de carbono de proveedores de nube distintos** (§3.6). Fronteras, métodos
  de asignación, granularidad y estado de verificación son incomparables por construcción.
- ❌ **Optimizar código por sostenibilidad sin haber apagado antes lo ocioso.** Saltarse el
  orden de §3.4 es la definición operativa de teatro de sostenibilidad: máximo esfuerzo, mínimo
  efecto, máxima visibilidad.
- ❌ **Publicar solo la cifra *market-based* del alcance 2.** Ambas o ninguna.
- ❌ **Presentar un cambio de frontera del sistema como una reducción** (migrar a la nube,
  externalizar, mover a *colocation*).
- ❌ **Presentar un ahorro de coste como un ahorro de carbono, o al revés.** Compromisos y
  reservas son el contraejemplo canónico: coste abajo, carbono igual.
- ❌ **Usar señal media de intensidad de red para justificar un desplazamiento de carga.** Eso
  requiere señal marginal, y usar la media da un resultado inválido, no aproximado.
- ❌ **Presentar como medida una cifra que es un reparto modelado** (energía por contenedor
  desde RAPL, cualquier dato de nube pública, cualquier salida de Cloud Carbon Footprint).
- ❌ **Citar un PUE como indicador de la eficiencia de tu software**, o comparar PUE de
  categorías de medición distintas.
- ❌ **Mezclar cifras amortizadas de LCA con cifras de bienes de capital del GHG Protocol**
  (§3.3).
- ❌ **Cambiar la unidad funcional del SCI sin recalcular la serie histórica.**
- ❌ **Renovar hardware invocando la eficiencia sin haber hecho la cuenta** de huella
  incorporada anualizada frente a exceso de consumo (§3.3).
- ❌ **Escribir una cifra sin fuente y sin metodología.** En este documento no hay ninguna; en
  los tuyos, tampoco.
- ❌ **Desmontar la instrumentación porque el Omnibus te sacó del ámbito de la CSRD** (§5.1).
- ❌ **Integrar una fuente de datos de intensidad de red sin verificar su licencia** — varias
  capas gratuitas son de uso no comercial.

## 8. Verificación web obligatoria

Este dominio combina lo peor de dos mundos: **regulación con fechas que se mueven** y
**herramientas de bajo mantenimiento**. Todo lo de abajo caduca.

**Comprobar siempre:**

1. **SCI / ISO/IEC 21031**: edición vigente en el catálogo de ISO y versión de la especificación
   de la GSF. **Discrepancia declarada** (§3.1): la GSF sitúa la acreditación en **abril de
   2024**, otras fuentes dan **marzo de 2024** como publicación y **mayo de 2024** como
   adopción. **Confirmar en ISO antes de citar una fecha en un documento formal.**
2. **Revisión de la Scope 2 Guidance del GHG Protocol**: si la segunda consulta ya cerró, si hay
   texto final y qué pasó con la definición de «organización pequeña» exenta. **Discrepancia
   declarada**: publicación final prevista en **2027** según el GHG Protocol, **2027-2028**
   según fuentes secundarias.
3. **CSRD / Omnibus**: confirmar umbrales, fechas y transposición de la **Directiva (UE)
   2026/470** en su texto del DOUE, **no en resúmenes de consultoras** — casi todo el material
   de 2024-2025 sobre CSRD está obsoleto y sigue circulando.
4. **EED y centros de datos**: si el **segundo reglamento delegado** (calificación y etiquetado,
   previsto jun-2026) ya se publicó; si el sistema nacional de reporte de tu jurisdicción
   existe; y **si la fecha de la primera etiqueta electrónica sigue en 15-ago-2027**.
5. **Ecodiseño (UE) 2019/424** revisado, y **forma jurídica final de la revisión WEEE**
   (¿Directiva o Reglamento?, propuesta prevista 3T-2026). **Hueco abierto: no decidido.**
6. **ISO/IEC 30134-2**: qué edición está vigente (hay **2016** y **2026**) y cuál referencia tu
   obligación regulatoria — pueden no ser la misma.
7. **Herramientas**: estado y licencia de **Cloud Carbon Footprint** (Apache-2.0, cadencia de
   publicación baja, repositorio de coeficientes archivado — **verificar si sigue vivo**),
   **Kepler** (CNCF sandbox, Apache-2.0, ≥0.10.0) y **Scaphandre** (Apache-2.0). Y la fecha de
   deprecación del **CCFT de AWS (30-jun-2026)**: si ya pasó, la migración no es opcional.
8. **Fuentes de intensidad de red**: límites y **licencia** exactos de las capas gratuitas de
   Electricity Maps y WattTime, que **ya se restringieron una vez** (de multizona a zona única),
   y si la API de Ember cubre la granularidad que necesitas.
9. **Metodología de cada proveedor de nube**: qué cambió desde tu última línea base y si los
   datos de cliente están **verificados por un tercero** — a ago-2026 los de Google **no lo
   estaban**.

**Huecos declarados — no se rellenan sin verificar:**

- **No se fija ninguna cifra de intensidad de carbono por región**: cambian por hora y por año, y
  una cifra escrita aquí sería falsa en semanas. Se leen de la fuente en el momento de decidir.
- **No se fija ningún porcentaje único de huella incorporada**: solo el rango publicado con su
  estudio, su muestra y su método (§3.3). **Cualquier «los servidores son 20/80» sin declarar
  vida útil, configuración e intensidad de red se rechaza.**
- **No se fija ningún ahorro esperado del *carbon-aware scheduling***: la magnitud depende
  enteramente de la región, la ventana y la flexibilidad de la carga, y no se ha verificado un
  estudio con metodología replicable para esta redacción.
- **No se fija ningún precio ni coste** de herramientas, suscripciones de datos ni servicios de
  aseguramiento: sin presupuesto verificado no se escribe una cifra.
- **Umbral de tamaño para que la optimización de código compense** (§3.4, palanca 6): no hay
  fuente con metodología replicable. **Se calcula en tu caso; no se hereda.**

Y la regla que gobierna todas las anteriores: **una cifra sin fuente y sin metodología no se
escribe.** Si al verificar no aparece la metodología, **el hueco se declara** — no se rellena con
la cifra que más circula.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
