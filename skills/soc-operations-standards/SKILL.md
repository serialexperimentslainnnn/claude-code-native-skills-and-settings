---
name: soc-operations-standards
description: Running the security operations function as an operation, not a product. Use when choosing between an in-house SOC, an MSSP or MDR provider and a hybrid model, sizing 24x7 shift coverage and follow-the-sun rotations, writing shift handover notes, managing the alert queue and its backlog, automated enrichment before triage, triage and escalation criteria, structured close codes and case management (TheHive, Cortex, IRIS, Shuffle, Tines, n8n, SOAR playbooks and what must never be automated), analyst tiering and why the tier model ages badly, alert fatigue and analyst burnout, actionable-alert ratio as a service-level indicator, the rule-retirement process, SOC metrics that survive scrutiny (time to detect, time to contain, telemetry coverage) versus vanity counts of closed alerts, SIEM ingest volume as the dominant cost driver and what to keep hot, warm or cold, scheduled threat hunting with a written hypothesis and a hunt report (PEAK, hunting maturity model), purple-team scheduling and deconfliction, SOC-CMM maturity assessment, or MITRE's 11 Strategies.
---

# Estándares de operación de un SOC

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **operar la función de vigilancia**: modelo de SOC y decisión de construir, comprar o
mezclar; cobertura horaria y dimensionado del turno; roles y su evolución; el **flujo de vida
de una alerta** —enriquecimiento, triaje, escalado, cierre con motivo estructurado—; gestión
de la cola y del atraso; fatiga de alertas y salud del equipo; el proceso de **retirar o
arreglar** lo que genera ruido; las métricas del servicio y su auditoría; el coste de ingesta
como decisión operativa; automatización con SOAR y sus límites; **caza de amenazas** como
actividad programada y distinta del triaje; y la coordinación de ejercicios *purple team*.

Triggers: "SOC", "MSSP", "MDR", "centro de operaciones de seguridad", "turno", "relevo",
"handover", "guardia del SOC", "cola de alertas", "backlog de alertas", "triaje", "escalado",
"nivel 1/2/3", "tier 1", "cierre de alerta", "código de cierre", "fatiga de alertas",
"burnout del analista", "playbook de SOAR", "TheHive", "Cortex", "IRIS", "Shuffle", "Tines",
"n8n", "caso", "gestión de casos", "hipótesis de caza", "threat hunting", "PEAK", "hunting
maturity model", "purple team", "deconfliction", "SOC-CMM", "11 Strategies", "coste de
ingesta", "GB/día", "alertas por analista y hora", "tiempo hasta contener".

**Principio rector**: **un SOC es una función de operación, no una herramienta.** Se compra un
SIEM y se cree haber montado un SOC; lo que se ha montado es un almacén de logs con
facturación. Y su fallo típico es **medir actividad en vez de resultado**: cerrar 4.000
alertas al mes es una métrica que sube sola cerrando más rápido y peor, y que llega a su
máximo justo cuando el equipo ha dejado de mirar. Corolario: **el SOC no se juzga por lo que
procesa, sino por lo que habría pasado desapercibido y no pasó** — y por si la persona que
está de turno a las 4 de la mañana tiene lo necesario para decidir.

**No aplica**: la **regla de detección, su contenido analítico, la normalización del log y la
cobertura ATT&CK como ingeniería** son de `detection-engineering-standards` —aquí se decide si
una regla se atiende, se arregla o se retira, allí se escribe y se prueba—; el **incidente
confirmado, la contención que preserva evidencia y el forense** son de
`incident-response-forensics-standards`, y **el proceso del incidente** —severidad, mando,
comunicación, postmortem— es de `incident-management-standards`: el entregable del SOC
**termina exactamente en el traspaso**, y el postmortem de ellos le devuelve trabajo.
La **plataforma de telemetría** (pipeline, retención, integridad) es de
`observability-standards` y **el coste de ingesta como unidad económica** —modelo de precio,
compromiso, cálculo de coste por GB y por caso— es de `finops-standards`; aquí solo la
decisión operativa de qué se guarda, dónde y cuánto. El **ejercicio ofensivo, con alcance y
autorización por escrito**, es de `offensive-security-standards` (esta skill es **defensiva**;
el SOC aporta la *deconfliction* y el aprendizaje, no ejecuta el ataque), el **triaje y la
prioridad de parcheo** de `vulnerability-management-standards`, **el indicador, su caducidad y
el informe que lo origina** de `threat-intelligence-standards`, y **el correo como canal con
controles propios** de `email-security-standards`.
Además: `identity-access-management-standards` (el acceso privilegiado de los propios
analistas y las herramientas de identidad que vigilan), `dns-standards`,
`networking-standards` y `firewall-policy-standards` (la señal de red y el control que se pide
aplicar), `privacy-engineering-standards` (**dato personal dentro de los logs y de los casos**:
base legal, minimización y retención), `grc-compliance-standards` (marco normativo, obligación
de notificar y evidencia de auditoría), `itsm-itil-standards` (**el ticket y el SLA
contractual**, incluido el del MSSP), `sre-practice-standards` (diseño de la rotación de
guardia y salud de la operación), `mlsecops-standards` y `ai-governance-standards` (si hay IA
en la cadena de decisión), `macos-fleet-standards` y `endpoint-security-standards`
(**Ola 7, planificada**: el agente y la telemetría del puesto).

## 2. Decisiones por defecto

> Verificar por web versión, licencia y estado de cada marco o herramienta antes de fijarlo (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Modelo | **Híbrido**: MDR cubre el 24×7 de primer nivel; el equipo interno se queda triaje profundo, caza, ingeniería y relación con el negocio | Interno completo cuando hay regulación que lo exige o el conocimiento del entorno es intransferible; gestionado puro solo en organizaciones sin equipo de seguridad |
| Cobertura | **Horario extendido interno + 24×7 externo**. El 24×7 propio se justifica por el coste de una hora sin respuesta, no por prestigio | 24×7 propio con ≥3 sedes (*follow-the-sun*) y volumen suficiente |
| Organización del trabajo | **Por competencia y flujo** (triaje / investigación / ingeniería / caza), con rotación entre ellos | Niveles 1-2-3 clásicos en un SOC muy grande o en un contrato de MSSP que los exige |
| Gestión de casos | Herramienta **dedicada** con caso, línea de tiempo, artefactos y código de cierre (TheHive/IRIS o equivalente) | El ITSM corporativo si ya cumple, y **nunca** un canal de chat como sistema de registro |
| Automatización | **SOAR para enriquecer y decidir menos**, no para responder solo | Respuesta automática **acotada y reversible**, con aprobación humana en lo destructivo |
| Marco de referencia | **MITRE, *11 Strategies of a World-Class Cybersecurity Operations Center*** (2.ª ed., 2022; Knerler, Parker y Zimmerman — sucede a *Ten Strategies*, Zimmerman, 2014), descarga gratuita | **SOC-CMM** (Rob van Os) para autoevaluación de madurez, con el instrumento de descarga libre y servicios comerciales alrededor |
| Metodología de caza | **PEAK** (*Prepare, Execute, Act with Knowledge*; equipo SURGe de Splunk, Bianco y Fetterman), agnóstica de herramienta, con sus tres tipos de caza y el **Hunting Maturity Model** (HMM0-HMM4) | Cualquier método con **hipótesis escrita y resultado registrado**; sin eso no es caza, es navegar por el SIEM |
| Etiquetado de lo que se comparte | **TLP 2.0** de FIRST (autoritativo desde agosto de 2022): **cuatro etiquetas** `TLP:RED`, `TLP:AMBER` (con `TLP:AMBER+STRICT` para restringir a la organización), `TLP:GREEN`, `TLP:CLEAR` | — Las etiquetas no se traducen ni se inventan |

**El coste real de un 24×7 propio, con la aritmética a la vista**: un puesto cubierto sin
interrupción son **8.760 h/año** (365×24). Divididas entre las horas realmente productivas de
un FTE —las de tu convenio menos vacaciones, festivos, formación y absentismo— salen del orden
de **5 a 6 FTE por puesto**, y eso es el mínimo teórico **sin holgura**. Dos analistas
simultáneos son 11-12 personas antes de contar supervisión, ingeniería o bajas. Haz esa
división con tus números **antes** de la conversación, y compárala con lo que resuelve: si el
tiempo hasta contener de madrugada no cambia porque quien decide no está de guardia, has
pagado presencia, no capacidad.

## 3. El flujo de una alerta

1. **Enriquecimiento automático, siempre antes del humano.** Toda alerta llega al analista ya
   con: activo y su criticidad, dueño, usuario y su contexto (departamento, viajes, alta
   reciente), reputación y edad de los indicadores, casos previos relacionados y el **runbook
   de la regla**. Si el analista tiene que abrir cinco pestañas para empezar, el diseño está
   mal y el coste se paga en cada alerta, cada día.
2. **Triaje con criterio de parada explícito**: qué evidencia basta para descartar y qué basta
   para escalar. Sin ese criterio escrito, cada analista inventa el suyo y la métrica de FP
   deja de significar nada.
3. **Escalado por criterio, no por jerarquía**: se escala cuando hace falta una capacidad que
   no tienes (acceso, contexto, decisión de negocio, autoridad para desconectar), no cuando
   "es difícil". El traspaso a incidente se declara y se registra: es el momento en que manda
   `incident-management-standards`.
4. **Cierre con motivo estructurado y obligatorio**, de una lista corta y cerrada: *actividad
   legítima esperada*, *actividad legítima no documentada* (→ genera trabajo de inventario),
   *prueba autorizada* (→ *deconfliction*), *ajuste de regla necesario* (→ va a ingeniería de
   detección), *verdadero positivo contenido*, *escalado a incidente*, *sin datos suficientes*
   (→ va a cobertura de telemetría). **Un cierre en texto libre es un dato perdido**: el motivo
   de cierre es la materia prima de toda la mejora del proceso.
5. **Relevo de turno con formato fijo**: qué está abierto y por qué, qué está degradado, qué
   cambios hay en curso en la organización, qué se espera que pase. El relevo verbal y el
   "está todo en el chat" son la causa habitual de que un caso muera entre dos turnos.

**Por qué el modelo por niveles envejece mal**: el nivel 1 nació para que gente barata filtrara
volumen a mano. Cuando el enriquecimiento y el descarte están automatizados —que es donde debe
ir la inversión—, **lo que queda en el nivel 1 es exactamente lo que no se puede automatizar**,
o sea lo difícil. El resultado del modelo puro es predecible: se contrata a la persona con
menos experiencia para el trabajo que exige más criterio, se le prohíbe investigar y se le
mide por velocidad de cierre; rota en un año y se lleva el conocimiento. La alternativa que
funciona es **una cola con rotación por competencias**, donde quien triaja también investiga,
también caza y también arregla la regla que le molesta.

## 4. Métricas: las que dicen algo y las que se manipulan solas

- **Que sí dicen algo**: **tiempo hasta detectar** y **tiempo hasta contener** (medianas y
  percentil 90, nunca la media, que una sola cola larga destroza); **porcentaje de alertas
  accionables** sobre el total; **cobertura de fuentes de log** frente al inventario de activos
  —qué porcentaje del parque emite la telemetría que las reglas asumen—; **atraso de la cola**
  y su tendencia; **proporción de detección propia frente a aviso externo**; **tiempo desde el
  cierre de una regla ruidosa hasta su corrección**.
- **Que se manipulan solas y están prohibidas como objetivo**: número de alertas cerradas,
  número de reglas desplegadas, número de indicadores cargados, porcentaje de "cobertura
  ATT&CK" sin validación adversaria, y cualquier media sin su percentil. Todas suben trabajando
  peor.
- **La tasa de falsos positivos es un SLI del SOC, con objetivo declarado y dueño**. Se mide
  **por regla** (una sola regla mala envenena el agregado) y se revisa con cadencia fija. El
  umbral de ruido aceptable se acuerda por escrito: si una regla supera su presupuesto de FP
  durante dos ciclos, entra en el proceso de corrección **con fecha**.
- **Regla que nadie atiende: se arregla o se retira. No hay tercera opción.** Una regla que la
  cola ignora sistemáticamente es peor que no tenerla, porque aparece en el informe de cobertura
  y crea la ilusión de que ese camino está vigilado. **La retirada es una decisión normal y
  documentada**, con su motivo y su fecha; un SOC sin proceso de retirada acumula deuda hasta
  que la cola se vuelve inservible.
- **Auditar la métrica contra la realidad**: al menos una vez por trimestre, tomar una muestra
  de alertas cerradas como falso positivo y **revisarlas de nuevo a ciegas**. Es la única forma
  de saber si el número de FP mide ruido o mide cansancio.
- **Referencia externa, con su sesgo declarado**: *M-Trends 2026* (Mandiant/Google Cloud),
  construido sobre **más de 500.000 horas de investigaciones propias de 2025**, sitúa la
  **mediana global de permanencia del atacante en 14 días** (subió desde 11), en **122 días**
  para espionaje y operaciones de trabajadores IT norcoreanos, y cifra en **52 %** los casos en
  que la organización detectó por sí misma (frente al 43 % en 2024). **Sesgo que hay que decir
  en voz alta**: la muestra son los clientes que contrataron respuesta a incidentes tras una
  brecha grave — no es un censo, y comparar tu número con él sirve para orientarse, **nunca
  como objetivo**.

## 5. Automatización, SIEM y coste

- **Qué se automatiza sin discusión**: enriquecimiento, correlación de casos duplicados,
  recogida de contexto, apertura y actualización del caso, notificación, y las **acciones
  reversibles de bajo impacto** (aislar en cuarentena un correo ya entregado, pedir
  reautenticación, marcar un activo para revisión).
- **Qué no se automatiza nunca sin aprobación humana explícita**: cualquier acción
  **destructiva o que corta servicio** — apagar o aislar un servidor de producción, deshabilitar
  masivamente cuentas, bloquear un rango de red, borrar ficheros, revocar certificados. El
  criterio es doble: **¿es reversible en minutos?** y **¿cuánto daño hace si el disparador es un
  falso positivo?** Si la respuesta a la segunda es "para la fábrica", hay humano en el bucle,
  aunque sea de madrugada. Y toda automatización lleva **interruptor de parada** y registro de
  cada acción con su justificación.
- **La ingesta es el mayor gasto del SIEM y, por tanto, una decisión de arquitectura, no de
  compras.** Regla: **el log entra si alimenta una detección, una investigación o una
  obligación**; si no cumple ninguna de las tres, se queda en almacenamiento barato o no se
  recoge. Escalones: *caliente* (consultable en segundos, semanas de retención) para lo que
  usan las reglas y el triaje; *templado* para la investigación de meses; *frío/objeto* para la
  obligación regulatoria y el forense antiguo. **Filtrar en origen** —no ingerir el ruido de
  depuración— es más barato que cualquier negociación de licencia.
- **Comprar el SIEM antes de tener las fuentes es el error caro clásico**: el producto se paga
  desde el día uno y las fuentes tardan trimestres. El orden correcto es inventario de activos
  → fuentes disponibles y su valor → casos de uso → volumen estimado → plataforma.
- **Integridad y acceso**: los logs de seguridad se escriben en almacenamiento **append-only**
  y con retención inmutable para lo crítico; el propio SOC no debe poder alterarlos. El acceso
  de los analistas es privilegiado y se audita: contiene dato personal y evidencia.

## 6. Caza de amenazas y purple team

- **La caza no es triaje con otro nombre.** El triaje reacciona a una alerta; la caza busca lo
  que **ninguna alerta iba a levantar**. Si tu "caza" consiste en revisar la cola con más calma,
  no estás cazando.
- **Toda caza empieza por una hipótesis escrita** —qué comportamiento adversario esperas, en
  qué fuente se vería, qué patrón lo distinguiría del ruido legítimo— y **termina en un informe
  breve con resultado, incluido el negativo**. Una caza que no encuentra nada pero demuestra
  que la telemetría necesaria no existe es un éxito: ha convertido una suposición en un hueco
  conocido.
- **Todo resultado de caza tiene un destino obligatorio**: una regla nueva o afinada (→
  `detection-engineering-standards`), un hueco de telemetría con dueño y fecha, un control que
  cambiar, o una hipótesis descartada con su razón. **Una caza que no deja rastro accionable no
  se ha hecho.**
- **Se programa como capacidad, no como hueco libre**: horas asignadas y protegidas del turno.
  La caza es lo primero que muere cuando la cola aprieta, y por eso hay que blindarla.
- **Purple team**: el valor no está en el ataque, está en la **sesión conjunta** donde se
  ejecuta una técnica, se mira si aparece en la telemetría, se ve si genera alerta y se arregla
  en el momento lo que falta. El SOC aporta visibilidad, criterio de detección y el registro de
  qué se vio y qué no; **el ejercicio ofensivo, su alcance y su autorización por escrito son de
  `offensive-security-standards`**. Y la regla operativa que evita el desastre: **deconfliction
  previa** —el SOC sabe que hay ejercicio y tiene el canal para preguntar— con la contrapartida
  de que **un hallazgo de compromiso real durante el ejercicio lo detiene** y activa el proceso
  de incidente.

## 7. Sostenibilidad y prohibiciones

Revisión trimestral del catálogo de reglas atendidas (uso, FP, retirada), del inventario de
fuentes y de la carga por turno; autoevaluación de madurez anual; revisión del contrato del
proveedor gestionado contra lo que realmente entrega, no contra lo que promete el SLA.

- ❌ **Medir el SOC por alertas cerradas**, por tiempo medio de cierre o por cualquier contador
  que suba trabajando peor, y con más razón si va ligado a bonus.
- ❌ **Comprar un SIEM antes de tener las fuentes de log** y el inventario de activos.
- ❌ **Operar sin proceso formal de retirada de reglas**, o retirar reglas de forma tácita
  ignorándolas en la cola.
- ❌ **Automatizar una respuesta destructiva o que corta servicio sin aprobación humana**, sin
  interruptor de parada y sin registro auditable de cada acción.
- ❌ Cerrar alertas en **texto libre** o con un único código genérico tipo "falso positivo".
- ❌ Dejar que **el atraso de la cola sea la variable de ajuste**: cuando no da tiempo, se
  reduce el ruido de entrada o se amplía capacidad; **no se baja el listón en silencio**.
- ❌ **Contratar un MDR sin definir qué escala, en cuánto tiempo, con qué evidencia y a quién**,
  ni exigir la telemetría en bruto y el detalle de sus detecciones. Un proveedor que no te deja
  auditar sus cierres te está vendiendo una cifra, no un servicio.
- ❌ Tratar el **24×7 como un fin**: presencia sin autoridad para decidir ni capacidad para
  contener es coste sin resultado.
- ❌ Usar el **chat como sistema de registro** de casos, o el correo como cola.
- ❌ Poner a la persona con menos experiencia a decidir sola sobre lo que más criterio exige, y
  además medirla por velocidad.
- ❌ **Turnos que impiden dormir** (rotación hacia atrás, noches encadenadas sin descanso) o un
  turno de noche sin escalado disponible: el error de las 4 de la mañana es un fallo de diseño
  del turno, no del analista.
- ❌ Reportar **cobertura ATT&CK como si fuera detección**, sin validación adversaria.
- ❌ Ingerir "todo por si acaso" y descubrir el coste en la factura, o eliminar fuentes por
  precio sin comprobar qué detecciones dependían de ellas.
- ❌ Hacer **caza sin hipótesis escrita ni informe**, o sacrificarla en cuanto la cola aprieta.
- ❌ Ejecutar un **purple team sin deconfliction** con el turno, o continuarlo tras encontrar
  indicios de compromiso real.

## 8. Verificación web obligatoria

1. **MITRE, *11 Strategies of a World-Class Cybersecurity Operations Center***: confirmar
   edición vigente y URL de descarga gratuita (la 2.ª ed. es de 2022 y sucede a *Ten
   Strategies*, 2014). **Hueco declarado**: el PDF alojado en `mitre.org` devolvía **403**
   desde este entorno; verificar la disponibilidad y si hay edición posterior.
2. **SOC-CMM**: **hueco declarado** — no se ha podido confirmar contra fuente primaria
   accesible **la versión vigente ni los términos de licencia** del instrumento (la web sirve
   el contenido por JavaScript). Confirmado solo: creado por **Rob van Os** y hoy sostenido por
   una entidad con servicios comerciales (formación, soporte, certificación) alrededor de una
   descarga gratuita. **Verificar licencia antes de usarlo en un entregable contractual.**
3. **MITRE ATT&CK**: verificado **v19.1 (28-abr-2026)** como versión actual, con **dos cambios
   estructurales recientes** que rompen informes y capas antiguas: en **v18 (oct-2025)** las
   *Detections* se sustituyeron por **Detection Strategies** y **Analytics**, y se **deprecaron
   las Data Sources**; en **v19** la táctica *Defense Evasion* **se dividió en Stealth (conserva
   TA0005) y Defense Impairment (TA0112)**. Comprobar la versión antes de reutilizar cualquier
   capa de cobertura o mapeo.
4. **TLP**: confirmar que sigue vigente la **versión 2.0** de FIRST y sus **cuatro** etiquetas.
5. **Métricas externas**: cualquier cifra de permanencia, coste o volumen se recomprueba en la
   fuente primaria y **se cita con su metodología y su sesgo**. Verificado aquí: *M-Trends 2026*
   declara >500.000 horas de investigaciones propias de 2025 — muestra de clientes de respuesta
   a incidentes, no población general.
6. **Cifras descartadas por falta de metodología pública**: "el analista medio recibe N alertas
   al día", "el X % de las alertas no se investiga nunca", el coste medio de una brecha y las
   tasas de reducción de ruido que publica cualquier fabricante de SIEM, SOAR o MDR sobre su
   propio producto. Si quien publica el número vende la solución que ese número justifica y no
   publica muestra ni método, **no se usa**: se sustituye por la medición de tu propia cola,
   que además es la única que sirve para decidir.
7. Estado, licencia y mantenimiento de la herramienta de gestión de casos o SOAR que se
   proponga, antes de fijarla.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
