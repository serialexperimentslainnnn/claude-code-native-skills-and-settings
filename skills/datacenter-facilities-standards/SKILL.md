---
name: datacenter-facilities-standards
description: The physical plant of a data centre or server room — everything bolted to the rack but not inside the server. Use when sizing A/B utility feeds and per-phase load balance, specifying UPS topology (double conversion, line-interactive, eco mode) and real autonomy at measured load, running a generator load bank test or a black-building test, choosing switched and metered PDUs and reading per-outlet current, discovering that two PSUs share one circuit, planning hot/cold aisle containment, CRAC/CRAH versus in-row versus rear-door heat exchangers, direct-to-chip liquid cooling and immersion at high kW/rack, ASHRAE TC 9.9 Thermal Guidelines classes A1-A4 and H1 and the recommended versus allowable envelope, rack density in kW and floor loading on a raised floor, structured cabling and labelling (ANSI/TIA-568, ANSI/TIA-606), fire detection and suppression under NFPA 75, NFPA 76, NFPA 2001 and NFPA 855, VESDA aspirating detection and lithium battery off-gassing, physical access control mantraps and CCTV retention, Uptime Institute Tier I-IV and TCDD/TCCF/TCOS certification, EN 50600 and ISO/IEC 22237 availability classes, ANSI/TIA-942 ratings, PUE under ISO/IEC 30134-2, comparing colocation versus an own room versus cloud on cost, or writing the preventive maintenance and testing calendar for power and cooling plant.
---

# Estándares de planta física de centro de datos

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **la instalación física que sostiene al hierro**: energía desde la acometida hasta la
regleta, refrigeración desde el enfriador hasta la entrada de aire del servidor, el espacio
(rack, suelo, peso, cableado), la protección contra incendios, el control de acceso físico y
el **mantenimiento y las pruebas** que hacen que todo eso sea verdad y no un diagrama.

**Frontera en una línea, acordada con `server-hardware-standards`: si va atornillado al rack
pero no dentro del servidor, es de aquí.** El chasis, la PSU, el BMC y el disco son suyos; el
circuito que alimenta esa PSU, el SAI que lo respalda, la PDU donde se enchufa, el aire que le
entra y la baldosa que lo aguanta son de aquí.

**Principio rector**: **la redundancia se demuestra quitando cosas, no dibujándolas.** Un
esquema con dos de todo no es redundante hasta que se apaga una rama con carga real y el
servicio no se entera. Casi todos los fallos caros de planta son *redundancia de papel*: dos
fuentes en un mismo circuito, dos ramas de UPS con un único cuadro aguas arriba, un grupo
electrógeno que arranca en vacío todos los meses y nunca ha visto la carga.

Triggers: acometida A/B, "¿qué autonomía tiene el SAI?", grupo electrógeno, prueba con banco de
carga (*load bank*), *black building test*, conmutador de transferencia (ATS/STS), PDU
conmutada/medida, "reparto entre fases", desequilibrio de fase, "las dos fuentes en la misma
regleta", pasillo frío/caliente, contención, CRAC/CRAH, in-row, puerta trasera refrigerada
(RDHx), CDU, *direct-to-chip*, inmersión monofásica/bifásica, ASHRAE TC 9.9, clases A1–A4/H1,
*recommended* vs. *allowable*, kW por rack, kg por baldosa, suelo técnico, ANSI/TIA-568,
ANSI/TIA-606, etiquetado de latiguillos, NFPA 75/76/2001/855, VESDA, *off-gassing* de litio,
esclusa/*mantrap*, retención de CCTV, Tier I–IV, TCDD/TCCF/TCOS, EN 50600, ISO/IEC 22237,
ANSI/TIA-942, PUE, ISO/IEC 30134-2, "¿colo o sala propia?", plan de mantenimiento preventivo.

**No aplica**: ver `server-hardware-standards` (**dentro del chasis**: PSU, BMC, firmware,
garantía; aquí el circuito que la alimenta y la exigencia de que sean dos distintos),
`onprem-standards` (**paraguas de plataforma y su tabla de enrutado §1.2**: esta skill es la
capa física que le faltaba; sus invariantes de §1.3 mandan),
`cmdb-inventory-standards` (**el registro**: rack, U, circuito y PDU son *datos de inventario*
y viven en el DCIM — aquí se decide qué significan y cuáles hay que mantener),
`os-provisioning-standards` (el recorrido del servidor **desde que hay corriente e IP**),
`datacenter-fabric-standards` (la malla Clos/EVPN que corre por ese cableado),
`high-speed-interconnect-standards` (InfiniBand/RoCE y la longitud de enlace que impone la
topología física), `networking-standards` y `routing-switching-standards` (direccionamiento,
VLAN, campus), `network-automation-standards` (la configuración como código),
`gpu-computing-standards` (**la GPU como recurso**: TDP, DCGM, *throttling*; aquí el kW/rack y
el circuito de líquido que se lo lleva), `hpc-standards` (el clúster y su planificador; aquí la
sala donde vive), `green-it-standards` (**la métrica y el informe**: SCI, GHG Protocol, WUE,
CUE, ERF/REF, EED y el esquema europeo de informe de centros de datos, calor residual como
huella — aquí PUE solo como **decisión de diseño y operación**, no como reporte regulatorio),
`bcdr-standards` (**RTO/RPO, sitio alterno y declaración de desastre**; aquí la resiliencia del
sitio, no la estrategia de continuidad), `ha-clustering-standards` (redundancia de servicio),
`linux-storage-standards` y `zfs-standards` (el dato), `kubernetes-standards` (lo que corre
encima), `finops-standards` (coste en nube y su comparación),
`homelab-standards` (**proporcionalidad**: en casa la planta es un SAI de 1500 VA y una
ventana; nada de este documento se aplica literalmente allí),
`grc-compliance-standards` (el control de seguridad física como evidencia de auditoría
ISO 27001 A.7 / ENS), `identity-access-management-standards` (identidad lógica; aquí la
tarjeta y el torno), `incident-management-standards` (la gestión del incidente cuando la sala
se cae), `vulnerability-management-standards`, `iac-standards`, `observability-standards`,
`sre-practice-standards`, y `embedded-iot-standards` (el sensor y su
firmware; aquí qué hay que medir en sala).

## 2. Decisiones por defecto

> Verificar por web edición vigente de cada norma, capacidades de producto y precios antes de
> fijar nada (§8). Las citas normativas de este documento se piden **verbatim** a la fuente.

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Sala propia vs. colocation | **Colocation** salvo escala o requisito de soberanía | Construir planta redundante real (2 acometidas, grupo, refrigeración N+1, incendios, guardia 24×7) tiene un coste fijo que no se amortiza por debajo de decenas de racks. La sala propia se justifica por latencia a un proceso local, por control regulatorio o porque ya existe amortizada |
| Colocation vs. nube | **Se decide con carga medida, no con lista de precios** | La nube gana en carga variable y proyecto corto; la colocation gana en carga estable 24×7 de varios años con hardware propio. **El comparativo honesto incluye personal, transporte, refresco de hardware y salida de datos** — omitir cualquiera invalida el número |
| Alimentación al rack | **Dos ramas (A/B) en circuitos, cuadros y SAI distintos** | Es *el* invariante de la skill. Cada rama dimensionada para llevar el 100 % de la carga sola |
| Carga por rama | **≤ 40–45 % del nominal del circuito en operación normal** | Si cada rama va al 80 %, perder una rama dispara el magnetotérmico de la otra. La redundancia 2N exige que **cada rama tenga hueco para toda la carga**, no la mitad |
| PDU | **Conmutada y medida por toma**, con ambas ramas en racks distintos | Sin medida por toma no hay reparto de fases posible ni detección de deriva. La conmutación evita el desplazamiento físico para un ciclo de energía |
| Topología de SAI | **Doble conversión (VFI)** en sala de producción | El modo *eco* / *line-interactive* mejora el PUE a costa de un tiempo de transferencia y de exponer la carga a la calidad de red. Se acepta solo con carga tolerante demostrada |
| Autonomía de SAI | **La que cubre arranque y toma de carga del grupo, con margen medido** | Los minutos de catálogo son a carga nominal y con baterías nuevas. **La autonomía real se mide con banco de carga al perfil actual**, y decae con la edad de la batería |
| Grupo electrógeno | **Con contrato de combustible y prueba periódica con carga real** | Un grupo probado en vacío no prueba nada: no calienta, no revela el *wet stacking* ni la capacidad del ATS bajo escalón de carga |
| Refrigeración | **Pasillo frío/caliente con contención** como línea base | La contención es la mejora de eficiencia con mejor relación coste/beneficio de toda la sala y no depende del proveedor |
| Redundancia de frío | **N+1 en unidades y en bombas, con distribución concurrente** | Perder una unidad no puede exigir bajar la carga IT. Ojo: N+1 de máquinas con una única tubería sigue siendo un punto único |
| Temperatura de consigna | **Envolvente *recommended* de ASHRAE (18–27 °C a la entrada de la máquina)** | Ver §3.3: se mide en la **entrada del equipo**, no en el retorno ni en el ambiente |
| Refrigeración líquida | **No, hasta que la densidad la obligue** (§3.4) | Introduce agua/dieléctrico, CDU, mantenimiento nuevo y personal nuevo. Se adopta por densidad medida, no por moda |
| Clasificación del sitio | **EN 50600 / ISO/IEC 22237** si hay que declarar un nivel; **Uptime Tier** solo si de verdad se va a certificar | Ver §3.7: "somos Tier III" sin certificado no significa nada |
| Extinción | **Detección temprana por aspiración + agente limpio o preacción**, según NFPA 75 y evaluación de riesgo | Ver §5.3. El agente concreto y la concentración los fija NFPA 2001 y el ingeniero de protección contra incendios, no esta skill |
| Métrica de eficiencia | **PUE anualizado, con categoría de medida declarada (ISO/IEC 30134-2)** | Un PUE sin categoría, sin frontera y sin periodo es marketing (§6.2) |

## 3. Estructura y convenciones

### 3.1 Energía: la cadena completa y dónde se rompe

La cadena es: **acometida → cuadro general → SAI → cuadro de distribución → circuito de rack →
PDU → toma → PSU**. La redundancia solo existe si **todos** los eslabones están duplicados.
El fallo clásico no es que falte un SAI: es que las dos ramas se juntan en un punto que nadie
dibujó (un cuadro compartido, un único ATS, un único cuarto eléctrico).

- **Dos fuentes en el mismo circuito no son redundancia.** Son dos fuentes. Cubren el fallo de
  una PSU y **ninguna otra cosa**: ni el magnetotérmico, ni la PDU, ni el cuadro, ni el SAI, ni
  el mantenimiento de esa rama. Es el error más repetido del dominio y se detecta con una sola
  pregunta al inventario: *¿qué circuito alimenta a cada PDU de este rack?* Si el DCIM no lo
  sabe, no se sabe.
- **Reparto entre fases.** En distribución trifásica, cada rama se reparte entre L1/L2/L3. Un
  desequilibrio alto sobrecarga una fase y el neutro mientras el total parece holgado. Se
  mide en la PDU y se corrige moviendo tomas, no ignorándolo.
- **Factor de simultaneidad.** La suma de las etiquetas de las PSU **no** es la carga real; la
  carga real medida suele quedar muy por debajo. Dimensionar por etiqueta desperdicia
  capacidad; dimensionar por medida sin margen de pico y de arranque dispara protecciones.
  Se dimensiona por **medida sostenida + pico observado + margen de crecimiento fechado**.
- **Corriente de arranque.** Encender un rack entero a la vez tras un corte tiene un pico muy
  superior al régimen. El arranque escalonado es requisito de diseño, no una cortesía.

### 3.2 Refrigeración: aire, contención y agua

- **El objetivo es la temperatura de entrada al equipo**, no la de la sala. Todo lo demás
  (retorno, ambiente, salida del CRAC) es instrumentación intermedia.
- **Contención**: pasillo frío o pasillo caliente, más **paneles ciegos en toda U vacía** y
  sellado de pasos de cable. Sin eso, el aire frío recircula, el CRAC trabaja contra sí mismo y
  el rack de arriba se cuece con la sala entera "a 21 °C".
- **Agua a la puerta**: puertas traseras refrigeradas (RDHx) son el escalón intermedio entre
  aire de sala y líquido al chip. Traen agua al rack sin tocar el servidor.
- **Punto de rocío y humedad**: importa el límite superior de punto de rocío para no condensar
  sobre tubería fría, y el inferior por electrostática. Ver §3.3.

### 3.3 ASHRAE TC 9.9 — lo que dice de verdad

Referencia: *Thermal Guidelines for Data Processing Environments*, **5.ª edición (2021)**,
ASHRAE Datacom Series Book 1 — **verificar por web si hay 6.ª edición antes de citarla** (§8).

Distinción que casi siempre se cuenta mal, en palabras del propio ASHRAE Journal (mayo 2022,
columna de TC 9.9, verbatim):

> "The recommended range is likely the most important range for data center designers and
> operators. Facilities should be designed and operated to target the recommended range for
> most hours of the year."
> "ITE, on the other hand, should be designed to operate within the extremes of the applicable
> allowable environmental classes."

Y el punto de medida, verbatim de la misma fuente:

> "Note that the temperature/humidity ranges listed in this column refer to the ITE inlet
> conditions and should not be confused with 'space' conditions, discharge air conditions from
> cooling equipment or return air conditions to cooling equipment."

Consecuencias operativas:

- **Recomendada (A1–A4): 64.4 °F–80.6 °F (18–27 °C)**, sin cambios desde la 2.ª edición (2008).
  "Subir la sala a 27 °C" no es una herejía: es el extremo de la envolvente recomendada.
- **Permitida por clase** (temperatura seca, entrada del equipo): **A1 59–89.6 °F (15–32 °C)**,
  **A2 50–95 °F (10–35 °C)**, **A3 41–104 °F (5–40 °C)**, **A4 41–113 °F (5–45 °C)**. A3 y A4
  se añadieron en la 3.ª edición precisamente para permitir refrigeración sin refrigeración
  mecánica.
- **Clase H1**, añadida en la 5.ª edición para equipo **de alta densidad refrigerado por aire**
  (aceleradores, HPC): su envolvente es **más fría**, no más caliente — recomendada
  **64.4–71.6 °F (18–22 °C)**. Contraintuitivo y decisivo: **la densidad alta revierte la
  tendencia a subir la temperatura de sala**.
- **Quién decide la clase**: el fabricante del equipo. No se deduce del aspecto del servidor.
- La clase de un equipo es **límite de garantía**, no objetivo de operación. Operar
  permanentemente en el borde de *allowable* traslada riesgo de fallo y consumo de ventilador
  al servidor.

### 3.4 Densidad y refrigeración líquida: cuándo deja de ser opcional

**Dato contra el folclore** (Uptime Institute, *Global Data Center Survey 2025*, autodeclarado
por operadores): la densidad **modal** media ronda los **9 kW/rack** y **más del 80 % de los
operadores declara no tener ningún rack por encima del umbral de alta densidad**. La sala
media del mundo no es una sala de GPU. **Diseñar toda la sala para 100 kW/rack porque el
sector habla de IA es sobredimensionar por titulares.**

Criterio, con la disciplina de que **el umbral exacto depende del equipo y del proyecto**:

- Hasta ~**10–15 kW/rack**: aire de sala con contención, bien hecho, basta.
- ~**15–40 kW/rack**: zona de transición — contención estricta, refrigeración en fila o puerta
  trasera refrigerada. Aquí el problema ya no es el frío, es el **caudal de aire y el ruido**.
- Por encima de ~**40–50 kW/rack**: **el aire deja de ser viable en la práctica** y se pasa a
  líquido directo al chip (*direct-to-chip*, con CDU y circuito primario/secundario).
- **Inmersión** (monofásica o bifásica): nicho. Resuelve densidades altísimas y elimina
  ventiladores, pero cambia el modelo de mantenimiento por completo (extraer un servidor de un
  tanque no es sustituir un disco en caliente) y arrastra restricciones de fluido, de
  garantía del fabricante y de normativa de incendios.
- **El límite real suele ser eléctrico, no térmico**: una sala diseñada para 5–10 kW/rack de
  media no admite racks de 50 kW aunque se resuelva el frío, porque no hay circuito, ni
  cuadro, ni SAI, ni acometida. **Antes de discutir el enfriador, se comprueba la acometida.**
- Adoptar líquido **añade un modo de fallo nuevo dentro de la sala** (fuga) y un plan de
  mantenimiento nuevo (calidad del fluido, filtros, detección de fugas, purga). No se adopta
  sin ese plan escrito.

### 3.5 Espacio: rack, peso y suelo

- **Peso**: un rack lleno de almacenamiento o de GPU se acerca a límites estructurales. Se
  verifica **carga puntual sobre baldosa y carga distribuida sobre forjado** contra la ficha
  del suelo técnico y del edificio, **y el recorrido de transporte** (montacargas, rampa,
  puertas) — que es donde se descubre tarde.
- **Suelo técnico**: si se usa como pleno de impulsión, cada baldosa perforada mal colocada y
  cada paso de cable sin sellar es una fuga de presión. Un suelo técnico usado solo como
  canalización de cables es una decisión legítima y más simple.
- **Profundidad y pasillos**: la profundidad del rack la fijan los servidores más largos y la
  gestión de cable trasera; los pasillos, la normativa de evacuación y la extracción de equipo.
- **Reserva de U**: no se llena un rack al 100 % de U ni al 100 % de su circuito. Ambas
  reservas se registran en el DCIM.

### 3.6 Cableado y etiquetado

- **Estructurado y documentado**, según ANSI/TIA-568 (componentes y clases) y
  **ANSI/TIA-606 (administración y etiquetado)** — verificar la revisión vigente de ambas (§8).
- **Regla operativa**: **todo latiguillo se etiqueta en los dos extremos** con un identificador
  que existe en el inventario. Un cable sin etiqueta es un cable que nadie se atreve a quitar,
  y así nacen las marañas que sobreviven a tres generaciones de servidores.
- **Longitud por recorrido, no aleatoria**: el sobrante bloquea el aire trasero y es causa real
  de puntos calientes. Potencia y datos por bandejas separadas; fibra con su radio de curvatura.
- **Retirada**: quitar el cable es parte de la retirada del equipo. Si no está en el
  procedimiento, no ocurre.

### 3.7 Uptime Institute Tier — qué significa y qué no

**Es de los datos que más se afirman mal.** Definiciones **verbatim** del propio Uptime
Institute (*Explaining the Uptime Institute's Tier Classification System*):

> **Tier I:** "A Tier I data center provides dedicated site infrastructure to support
> information technology beyond an office setting."
> **Tier II:** "Tier II facilities include redundant critical power and cooling components to
> provide select maintenance opportunities."
> **Tier III:** "A Tier III data center requires no shutdowns for equipment replacement and
> maintenance."
> **Tier IV:** "Tier IV site infrastructure builds on Tier III, adding the concept of Fault
> Tolerance to the site infrastructure topology."

Y la distinción entre los tres certificados, que es donde se miente más (misma fuente,
verbatim):

> **Diseño (TCDD):** "Uptime Institute consultants review 100% of the design documents,
> ensuring each subsystem among electrical, mechanical, monitoring, and automation meet the
> fundamental concepts."
> **Instalación construida (TCCF):** "During a TCCF, a team of Uptime Institute consultants
> conducts a site visit, identifying discrepancies between the design drawings and installed
> equipment."
> **Sostenibilidad operativa (TCOS):** "Uptime Institute will assess the operational plans and
> parameters for any Tier Certified data center, and help the client understand where issues
> may occur."

Reglas que se derivan y que hay que aplicar en cualquier pliego o comparativa:

- **Un certificado de diseño (TCDD) no dice nada de lo construido.** Es el reclamo comercial
  más común: "Tier III certificado" a secas suele ser TCDD. Se pide el **tipo** de certificado,
  el **número de premio** y la **fecha**.
- **TCDD es prerrequisito de TCCF, y ambos lo son de TCOS.** No hay atajo.
- **Uptime usa numeración romana (Tier I–IV).** "Tier 3", "Tier 3+" y "Tier 4 ready" **no son
  designaciones de Uptime**: son marketing y no se aceptan como requisito contractual.
- **El Tier es topología, no una lista de componentes.** Los mismos N chillers y N UPS dan
  Tier II o Tier III según cómo estén distribuidos.
- **Alternativas para especificar sin certificar**: **EN 50600** y su hermana internacional
  **ISO/IEC 22237** (clases de disponibilidad 1–4, más una clase de protección separada, y
  aplicadas por subsistema: energía, clima, telecomunicaciones) y **ANSI/TIA-942**
  (*ratings* 1–4). Verificar por web las partes y ediciones vigentes de cada una (§8).

## 4. Aceptación y pruebas — la sección que hace real todo lo anterior

**Un grupo electrógeno sin prueba con carga es un adorno.** Esta sección es el equivalente de
"tests" en una skill de software: sin ella, §3 es documentación.

Escalera de pruebas, de menor a mayor coste y confianza:

1. **Inspección y termografía** del cuadro eléctrico: conexiones flojas y puntos calientes.
   Barata, anual, encuentra fallos antes de que sean incendios.
2. **Arranque en vacío del grupo** (semanal/mensual): solo prueba que arranca. **No cuenta como
   prueba.**
3. **Prueba con banco de carga** (*load bank*): el grupo asume carga real, alcanza temperatura y
   revela *wet stacking*, refrigeración, escape y regulación. **Anual como mínimo.**
4. **Prueba de autonomía del SAI a carga real medida**, no a nominal de catálogo. Es la única
   forma de saber los minutos que hay.
5. **Prueba de conmutación**: abrir cada rama de alimentación por separado, con carga, y
   comprobar que nada cae. Esto es lo que valida el "dos circuitos distintos" de §3.1 y lo que
   destapa el rack con dos PSU en la misma rama.
6. **Black building test**: corte total simulado de la acometida, con carga de producción o
   equivalente. Es la prueba definitiva y la que más miedo da; por eso casi nadie la hace, y
   por eso los fallos aparecen el día real.

Reglas:

- **Toda prueba se planifica con ventana, plan de retorno y criterio de aborto por escrito**, y
  deja un informe con medidas. Una prueba sin informe no ocurrió.
- **Se prueba antes de necesitarlo**: la aceptación del sitio (*commissioning*, niveles L1–L5)
  se hace **antes** de meter carga de producción, no después.
- **Baterías**: la prueba de impedancia/descarga es el único indicador honesto de su estado; la
  edad de la batería es una estimación, no una medida.
- **Registro de mantenimiento preventivo** por activo, con fecha de la última prueba y de la
  siguiente, **en el inventario** (`cmdb-inventory-standards`), no en un Excel de alguien.

## 5. Seguridad de la instalación

### 5.1 Acceso físico

- **Mínimo privilegio también aquí**: acceso por rol y por ventana temporal, no permanente;
  revisión periódica de la lista y **baja inmediata al salir de la organización** (una tarjeta
  activa de un ex-empleado es el equivalente físico de una cuenta huérfana). Doble factor en la
  puerta (tarjeta + PIN o biometría) y esclusa/*mantrap* donde el riesgo lo justifique.
- **Acompañamiento de terceros** (mantenimiento, obra, operadora) registrado y no delegable.
- **Racks con cerradura** y, en colocation, **jaula propia**: el vecino no es de confianza.
- **CCTV** con retención definida, **y esa retención es dato personal**: plazo, base legal y
  acceso se documentan (ver `privacy-engineering-standards`).
- **Registro de entradas y salidas de material**: un servidor que sale de la sala sin registro
  es una fuga de datos potencial. La retirada incluye borrado o destrucción certificada del
  soporte antes de que el equipo salga del control físico.

### 5.2 Superficie que se olvida

- **La sala eléctrica, la de baterías y el patio del grupo son parte del perímetro.** Cortar la
  alimentación desde fuera es más fácil que entrar en la sala.
- **BMS/DCIM/SCADA de planta**: la gestión de clima y energía es una red industrial conectada,
  a menudo con credenciales por defecto y sin parches. **Va en su propia VLAN, sin salida a
  Internet y sin acceso desde la red de usuarios.**
- **Botón de parada de emergencia (EPO)**: obligatorio por normativa en muchos sitios y causa
  documentada de caídas accidentales. Se protege físicamente contra pulsación involuntaria.
- **Sensores de fuga** bajo suelo y en el circuito de líquido; **detección de agua** en toda
  sala con tubería.

### 5.3 Incendios

- Marco: **NFPA 75** (protección de equipo de TI) y **NFPA 76** (instalaciones de
  telecomunicaciones de red pública); el sistema de agente limpio en sí lo rige **NFPA 2001**;
  el almacenamiento de energía con baterías, **NFPA 855**. Verificar ediciones vigentes (§8):
  la **edición 2024 de NFPA 75** trasladó los requisitos de baterías de litio a NFPA 855 y
  **añadió requisitos para equipo de refrigeración por inmersión y para detección de
  *off-gassing***.
- **Detección temprana por aspiración (VEWFD/VESDA)** en sala: detecta la combustión antes de
  que haya llama, que es cuando todavía se puede intervenir sin descargar nada.
- **Preacción de doble enclavamiento** frente a rociador húmedo sobre racks; agente limpio
  cuando el riesgo de daño por agua lo justifica.
- **Baterías de litio**: el riesgo no es el mismo que el del plomo. *Off-gassing*, fuga térmica
  y reignición cambian la estrategia de detección y de compartimentación.
- **Descarga acústica**: la descarga de agente por boquilla genera niveles de ruido capaces de
  **dañar discos duros**. Es un fallo real y documentado, y se mitiga en diseño.
- El diseño concreto (agente, concentración, tiempo de retención, estanqueidad) lo firma un
  ingeniero de protección contra incendios. **Esta skill exige que exista y esté probado, no
  lo diseña.**

## 6. Operación y eficiencia

### 6.1 Instrumentación mínima

Sin estas medidas la sala se opera a ciegas, y son exactamente las que faltan cuando hay un
incidente:

- **Energía**: por acometida, por SAI, por cuadro, **por circuito de rack y por toma de PDU**.
- **Clima**: temperatura **en entrada de rack** (arriba, medio, abajo — el gradiente vertical
  es la señal de recirculación), humedad, punto de rocío, presión diferencial en pleno.
- **Estado**: SAI (carga, autonomía estimada, estado de batería, bypass), grupo (nivel de
  combustible, horas, fallo de arranque), enfriadoras, detección de agua, puertas.
- **Alertas sobre síntoma**: rama de alimentación perdida, circuito por encima del umbral de
  conmutación, temperatura de entrada fuera de envolvente, SAI en bypass, grupo en fallo.
  **Todo lo demás es ruido.**

### 6.2 PUE — por qué el número del proveedor casi nunca es comparable

Norma: **ISO/IEC 30134-2**. Verificado: la **edición 2 es ISO/IEC 30134-2:2026, publicada el
16 de enero de 2026**, y sustituye a la 30134-2:2016 (retirada) y a su Amd 1:2018. **Cualquier
documento que cite "ISO/IEC 30134-2:2016" está desactualizado** — verificar antes de citar (§8).

PUE = energía total de la instalación / energía del equipo de TI. Es una división trivial, y
por eso mismo se manipula sin mentir:

- **Frontera del sistema**: ¿entra la oficina? ¿la iluminación? ¿la pérdida del transformador
  de media tensión? ¿la refrigeración de la sala eléctrica? Distinta frontera, distinto número.
- **Categoría de medida**: la norma define categorías según **dónde** se mide la energía de TI
  (salida del SAI, salida de la PDU, entrada del equipo) y con qué granularidad temporal. **Un
  PUE sin categoría declarada no es comparable con ninguno.**
- **Periodo**: PUE anualizado ≠ PUE instantáneo del mejor día de invierno. El *design PUE* de un
  folleto es una simulación, no una medida.
- **Carga parcial**: una sala al 20 % de ocupación tiene un PUE malísimo por física, no por mala
  operación. Comparar PUE entre sitios con ocupación distinta no dice nada.
- **Clima**: un sitio nórdico gana por geografía. No es mérito de ingeniería.
- **Cifra de referencia, con su metodología y sus límites**: Uptime Institute (*Global Data
  Center Survey 2025*) reporta una **media ponderada de 1,54**, sexto año consecutivo
  esencialmente plana, sobre **n≈681 respuestas autodeclaradas** a la pregunta por **el mayor
  centro de datos de la organización**. Es **autodeclarada, no auditada y no ponderada por
  carga**, así que no representa una media mundial: los hiperescalares están infrarrepresentados.
  **Se cita con esas cuatro salvedades o no se cita.**
- **Lo que PUE no mide**: nada de lo que hace el equipo de TI. Apagar servidores zombis
  **empeora** el PUE y mejora todo lo demás. Por eso PUE se acompaña de energía total y de
  trabajo útil, nunca solo.
- **Métricas hermanas** (WUE de agua, CUE de carbono, ERF/REF de reutilización de calor) y todo
  el reporte regulatorio son de `green-it-standards`. Aquí solo se decide **medirlas** y **no
  optimizar PUE a costa de disparar el consumo de agua**, que es el intercambio silencioso de
  la refrigeración evaporativa.

### 6.3 Calor residual

La reutilización del calor deja de ser anecdótica cuando hay líquido: **el agua caliente de un
circuito directo al chip es mucho más aprovechable que el aire tibio de un pasillo caliente**.
La decisión es de urbanismo y de contrato con un consumidor de calor cercano, no de ingeniería
de sala; la contabilidad (ERF/REF) es de `green-it-standards`.

## 7. Sostenibilidad a largo plazo y prohibiciones

**Cadencia mínima**: revisión anual del plan de mantenimiento preventivo y de la matriz de
pruebas; revisión de capacidad (kW, U, toneladas de frío, puertos) trimestral con datos del
DCIM; revisión de la lista de acceso físico al menos semestral; revisión de ediciones de norma
citadas en pliegos, anual (§8).

**Curva de capacidad**: la sala se llena por **el primer recurso que se agote** — casi siempre
energía o frío, casi nunca espacio en U. Se proyecta con la medida, con fecha, y **se decide
qué hacer al 70 % de ocupación, no al 95 %**, porque ampliar planta lleva meses o años.

Prohibiciones:

- ❌ **Dos fuentes del mismo servidor en el mismo circuito** y llamarlo redundante.
- ❌ **Declarar un grupo electrógeno operativo sin prueba con carga documentada** en el último
  año. Arrancarlo en vacío no cuenta.
- ❌ **Declarar la autonomía del SAI a partir de la ficha del fabricante** en lugar de una
  medida al perfil de carga actual.
- ❌ **Poner en producción una sala sin *commissioning* documentado**, o meter carga antes de
  las pruebas de aceptación.
- ❌ **Racks sin paneles ciegos** y pasos de cable sin sellar en sala con contención: se está
  pagando frío para recircularlo.
- ❌ **Cargar ambas ramas por encima del punto en que una sola no aguanta el total.** Es
  redundancia contable, no eléctrica.
- ❌ **Latiguillos sin etiqueta en ambos extremos**, o etiquetas que no existen en el inventario.
- ❌ **Afirmar un Tier sin certificado**, confundir TCDD con TCCF, o usar "Tier 3+" / "Tier IV
  ready" como si fuera una designación de Uptime Institute.
- ❌ **Publicar o comparar un PUE sin frontera, categoría de medida (ISO/IEC 30134-2) y periodo.**
- ❌ **Citar una temperatura de sala sin decir dónde se mide.** Solo cuenta la entrada al equipo.
- ❌ **Operar de forma permanente en el extremo *allowable* de la clase ASHRAE** como si fuera el
  objetivo de diseño.
- ❌ **Adoptar refrigeración líquida sin plan de detección de fugas, de mantenimiento de fluido y
  de intervención**, ni verificar antes que la acometida y el cuadro dan esa potencia.
- ❌ **BMS/DCIM en la red corporativa o expuesto a Internet**, con credenciales por defecto o sin
  ciclo de parcheo.
- ❌ **Sacar un servidor de la sala sin registrar la salida** y sin borrado o destrucción
  certificada del soporte.
- ❌ **Citar cifras de vida útil de servidor ("5 años") o de PUE medio del sector como hechos.**
  Si no traen metodología, muestra y frontera, se citan como estimación o no se citan.
- ❌ **Diseñar toda la sala para densidades de IA sin carga que las justifique.** La densidad se
  mide; la reserva se planifica por zonas, no aplicando el peor caso a todo el edificio.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un pliego, un diseño o un informe:

1. **ASHRAE TC 9.9, *Thermal Guidelines for Data Processing Environments***: confirmar que la
   **5.ª edición (2021)** sigue siendo la vigente y que no hay 6.ª. Las envolventes de §3.3
   están tomadas **verbatim** de la columna de TC 9.9 en *ASHRAE Journal*, mayo de 2022 (Quirk,
   Davidson, Schmidt), que reproduce las tablas de la 5.ª edición. **Hueco declarado**: el
   libro de ASHRAE es de pago y no se ha podido leer en crudo; las cifras se han contrastado
   contra esa columna publicada por ASHRAE, no contra el libro.
2. **Uptime Institute**: las definiciones de Tier I–IV y de TCDD/TCCF/TCOS de §3.7 son
   **verbatim** de *Explaining the Uptime Institute's Tier Classification System*
   (journal.uptimeinstitute.com). **Hueco declarado**: el documento normativo *Tier Standard:
   Topology* no es de acceso libre; no se ha leído en crudo. Antes de contratar, pedir al
   proveedor el certificado concreto y verificarlo con Uptime.
3. **ISO/IEC 30134-2**: verificado que la edición vigente es **ISO/IEC 30134-2:2026 (edición
   2.0, publicada el 16 de enero de 2026)** — confirmado en la ficha del IEC Webstore
   (publicación 111538) — y que la 2016 y su Amd 1:2018 están retiradas. **Hueco declarado**:
   `iso.org` devuelve 403 y el texto de la norma es de pago; **no se ha leído el articulado**,
   así que la definición exacta de las categorías de medida debe consultarse en la norma antes
   de declarar una en un informe. Nota de frontera: `green-it-standards` cita esta norma sin
   año; conviene comprobar si su texto asume la edición de 2016.
4. **EN 50600 / ISO/IEC 22237 / ANSI/TIA-942 / ANSI/TIA-568 / ANSI/TIA-606**: comprobar partes
   publicadas y revisión vigente de cada una. La serie ISO/IEC 22237 estaba **incompleta** en
   las fuentes consultadas; no se ha verificado parte por parte. **Hueco declarado.**
5. **NFPA 75 / 76 / 2001 / 855**: verificar edición vigente (NFPA reedita en ciclos de ~3–4
   años). Confirmado que **NFPA 75 edición 2024** existe y que trasladó los requisitos de
   baterías de litio a NFPA 855 y añadió requisitos de inmersión y de *off-gassing*; **hueco
   declarado**: el texto de NFPA es de pago y no se ha leído en crudo.
6. **Umbrales de densidad para líquido (§3.4)**: **no hay una cifra normativa**. El rango
   40–50 kW/rack procede de guías de fabricante, que discrepan entre sí (se han visto umbrales
   desde ~35 kW). Se usa como orden de magnitud, **nunca como criterio de aceptación**; el
   número que manda es el de la ficha del equipo concreto.
7. **Cifras de sector**: cualquier media de PUE, de densidad o de vida útil se cita con
   fuente, año, tamaño de muestra y método de recogida. La de §6.2 es autodeclarada.
8. **Producto y precio**: capacidades de SAI, PDU, CDU y enfriadoras, plazos de entrega
   (críticos y muy variables para equipo eléctrico) y tarifas de colocation se verifican
   contra el fabricante y el proveedor, nunca de memoria.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
