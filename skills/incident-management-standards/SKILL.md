---
name: incident-management-standards
description: Use when running or designing the incident process itself — declaring an incident, severity matrix (SEV1-SEV4, impact x urgency), Incident Commander, operations lead, communications lead and scribe roles, incident channel and status page cadence, stakeholder and customer update templates, mitigate-before-diagnose calls, rollback decisions, command handover in long incidents, incident closure, blameless postmortem with owned action items, time-to-declare and time-to-mitigate metrics and MTTR pitfalls, ITIL major incident and problem management, game days and tabletop exercises, vendor outage and third-party or data-breach incidents.
---

# Estándares de gestión de incidentes — el proceso, sea cual sea la causa

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **proceso de gestión de un incidente de extremo a extremo, con independencia de su causa**:
criterios de detección y declaración, clasificación por severidad, activación de roles de mando,
comunicación interna y externa, decisión de mitigación bajo incertidumbre, escalado, cierre,
postmortem sin culpa y la cadena de aprendizaje que convierte incidentes en cambios. Cubre por igual
el incidente de fiabilidad, el de seguridad, el de calidad del dato, el de un proveedor caído y el que
no es técnico (brecha de datos personales, fallo de un tercero crítico, fraude operativo).

Triggers: "declarar incidente", "severidad", "SEV1/SEV2", "P1/P2", "incident commander", "IC",
"comms lead", "scribe", "canal de incidente", "status page", "war room", "actualización a
interesados", "portavoz", "mitigar", "rollback", "traspaso de mando", "handoff de IC", "cierre del
incidente", "postmortem", "acciones de seguimiento", "MTTR", "tiempo hasta declaración", "major
incident", "problem management", "tabletop", "game day", "proveedor caído".

**Principio rector**: el incidente se gestiona con **una estructura de mando explícita, no con la
suma de buenas voluntades**. El fallo dominante de las organizaciones no es técnico: es que nadie
declaró, nadie coordinaba y nadie hablaba con quien tenía que hablar. Corolario: **declarar es
barato, no declarar es caro**. Un SEV2 abierto y degradado a los 10 minutos cuesta una notificación;
una hora sin coordinación cuesta el incidente entero.

**No aplica**:
- `sre-practice-standards` (**frontera crítica**, arbitraje en §3): la **fiabilidad del servicio**
  como disciplina — SLI/SLO, error budget y su política, alertas por burn rate, diseño y
  dimensionado de la rotación de guardia, PRR, toil, capacity planning, DORA. Su tratamiento de
  mando de incidente y postmortem es el **resumen aplicado a un incidente de fiabilidad**; la
  versión canónica del proceso es esta skill. Si ambas divergen, **manda esta**.
- `incident-response-forensics-standards`: la **respuesta técnica y la investigación** de un
  incidente de seguridad — contención sin destruir evidencia, adquisición de memoria y disco,
  cadena de custodia, análisis, erradicación y recuperación, playbooks de ransomware/identidad.
  Un incidente de seguridad **usa las dos**: esta lo gobierna (quién manda, quién habla, cómo se
  decide), aquella lo investiga (qué pasó, cómo entró, qué tocó, qué se preserva).
- `observability-standards`: telemetría con la que se detecta y se diagnostica, y su retención.
- `grc-compliance-standards`: marco normativo, evidencia de auditoría y aceptación formal de riesgo;
  aquí solo el **disparo** de la obligación de notificar y su coordinación operativa.
- `vulnerability-management-standards`: el CVE **antes** de que se explote (triaje, SLA, VEX).
- `appsec-standards`: modelado de amenazas y clases de vulnerabilidad en código propio.
- `identity-access-management-standards`: break-glass, revocación de sesiones y tokens.
- `onprem-standards`, `kubernetes-standards`, `networking-standards`, `cicd-standards`,
  `data-platform-standards`, `aws-standards`/`azure-standards`/`gcp-standards`, `homelab-standards`:
  la mitigación concreta en cada plataforma.
- **Planificadas**: `bcdr-standards` (**Ola 1**; la frontera es la **escala** — cuando el incidente
  deja de ser recuperable dentro del servicio y activa el plan de continuidad, deja de gestionarse
  como incidente y pasa a ser DR: el IC entrega el mando al director de crisis y se declara
  explícitamente el cambio de régimen), `detection-engineering-standards` (**Ola 1**: la detección
  que **dispara** la declaración), `privacy-engineering-standards` (**Ola 1**: brecha de datos
  personales, evaluación de riesgo para los interesados y comunicación a los afectados),
  `offensive-security-standards` (deconfliction: un ejercicio autorizado no debe consumir el proceso
  de incidente, y un hallazgo real durante el ejercicio sí lo activa),
  `secrets-management-standards` (**Ola 1**), `backup-recovery-standards` (**Ola 2**),
  `tech-leadership-standards` (**Ola 6**: **el postmortem sin culpa como proceso —formato, plazos,
  acciones con dueño— es de aquí**; **defenderlo cuando la dirección pide un responsable es una
  obligación de liderazgo y es suya**. La cultura sin culpa no se sostiene con un documento: se
  sostiene con alguien que absorbe esa presión),
  `itsm-itil-standards` (**Ola 6 — frontera con solape real que hay que arbitrar**: **el incidente
  técnico en vivo es de aquí** —declaración de severidad, mando, coordinación, comunicación durante
  la caída y postmortem sin culpa—; **el proceso de servicio que lo envuelve es suyo**: registro y
  categorización del ticket, catálogo, SLA contractual y su régimen de créditos, escalado
  jerárquico y relación con el cliente. La **gestión de problemas** —eliminar la causa una vez
  restaurado el servicio, con su base de errores conocidos— **es suya**; aquí termina cuando el
  servicio está restaurado y el postmortem tiene acciones con dueño. Y la distinción que ninguna de
  las dos debe borrar: **un SLA contractual no es un SLO**, que es de `sre-practice-standards`).

## 2. Decisiones por defecto

> Verificar por web el estado de los marcos y referencias antes de fijarlos en un proyecto real (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Marco de mando | **ICS adaptado** (IMAG de Google / PagerDuty Incident Response) | Cualquiera, si define un mando único e inequívoco |
| Escala de severidad | **SEV1-SEV4**, definida por **impacto observable en el usuario**, no por componente ni por equipo | P1-P4 si ya está implantada; nunca dos escalas conviviendo |
| Criterio de declaración | **Umbral explícito y automático** (SLO en riesgo, indicio de compromiso, dato incorrecto publicado, proveedor crítico caído) | Declaración discrecional **siempre permitida**: cualquiera puede declarar, nadie necesita permiso |
| Regla de duda | **Declara alto y degrada** | — |
| Roles mínimos | **IC** + **Ops lead** + **Comms lead** + **Scribe** | En SEV3-4 el IC acumula Comms y Scribe; **nunca** acumula Ops |
| Quién es IC | Quien **coordina**, no quien más sabe. Rol rotado y entrenado, independiente del área afectada | El que declara asume IC hasta traspaso formal |
| Canal | **Uno solo por incidente**, escrito, persistente y auditable; puente de voz opcional colgado del canal | Voz como principal solo si el canal escrito no es viable — con scribe obligatorio |
| Cadencia de comunicación | Fija por severidad (SEV1 cada 15-30 min) **aunque no haya novedad** | — |
| Portavoz externo | **Único**, el Comms lead; nadie más habla con clientes, prensa ni reguladores | — |
| Orden de trabajo | **Mitigar > diagnosticar > corregir**, salvo excepción de evidencia (§3) | — |
| Opción por defecto ante cambio reciente | **Rollback** | Fix forward solo con criterio explícito del IC y riesgo acotado |
| Postmortem | **Obligatorio** en SEV1-SEV2, en toda recurrencia y en todo incidente de seguridad, sin culpa, con acciones con **dueño y fecha** | — |
| Taxonomía de causas | **Cerrada y revisada**, aplicada en el cierre de cada incidente | — |
| Métrica de cabecera | **Tiempo hasta declaración** y **tiempo hasta mitigación** | MTTR solo como distribución segmentada por severidad (§6) |
| Ejercicios | **Tabletop trimestral** + **game day** con inyección real (ver `sre-practice-standards`) | — |
| Encuadre ITSM | Toma de ITIL 4 el **major incident** y **problem management**; deja fuera CAB y flujo de peticiones | — |

## 3. El ciclo de vida como proceso de ingeniería

### Arbitraje de frontera (léelo antes de enrutar)

- "¿Cuánto puede fallar este servicio, qué lo mide y quién está de guardia?" → `sre-practice-standards`.
- "¿Quién manda ahora mismo, qué se comunica y cómo se decide?" → **esta skill**.
- "¿Qué hizo el atacante, qué tocó y qué se preserva?" → `incident-response-forensics-standards`.
- Duplicación **aceptada y declarada**: severidades, rol de IC y postmortem aparecen en las tres.
  La fuente de verdad del **proceso** es esta; las otras lo aplican a su dominio.

### 3.1 Detección y declaración

- La declaración es un **acto explícito y con marca temporal**, no un estado de ánimo. Se registra
  quién declara, cuándo, con qué severidad y por qué.
- **Cualquiera puede declarar**, incluido soporte, un cliente interno o un becario de guardia. Exigir
  aprobación para declarar es el mecanismo más eficaz de convertir un SEV3 en un SEV1.
- **Umbrales automáticos** que declaran solos (o al menos proponen): quema de error budget por encima
  del umbral de page, indicio de compromiso confirmado por detección, pérdida o corrupción de datos,
  caída de un proveedor crítico, fuga de datos personales sospechada.
- El **reloj regulatorio empieza en el "conocimiento" del incidente, no en el diagnóstico** (§6):
  registrar la hora de detección con precisión es una obligación operativa, no un detalle.

### 3.2 Clasificación: severidad con criterios observables

La severidad se decide en **≤ 60 segundos** con una tabla que un humano cansado a las 03:00 lee sin
interpretar. Se fija por **impacto × urgencia**, con impacto expresado en lenguaje de usuario:

| | Urgencia alta (empeora / irreversible) | Urgencia media | Urgencia baja (estable, contenido) |
|---|---|---|---|
| **Impacto crítico** (journey principal caído para todos, dato perdido, compromiso confirmado, obligación legal disparada) | SEV1 | SEV1 | SEV2 |
| **Impacto alto** (journey degradado, subconjunto grande, workaround costoso) | SEV1 | SEV2 | SEV3 |
| **Impacto medio** (funcionalidad secundaria, workaround viable) | SEV2 | SEV3 | SEV3 |
| **Impacto bajo** (cosmético, interno, sin usuario afectado) | SEV3 | SEV4 | SEV4 |

Reglas duras de la clasificación:

- Cada nivel define **respuesta**, no prestigio: quién se despierta, cadencia de comunicación,
  obligatoriedad de postmortem, necesidad de status page.
- **Todo indicio de compromiso, exfiltración o dato personal expuesto entra como SEV1 o SEV2 por
  defecto**, y solo baja tras evaluación — nunca al revés.
- La severidad se **revisa continuamente** y puede subir o bajar; el cambio se anuncia en el canal
  con motivo. Lo que no se hace es negociarla a la baja por sus consecuencias.
- Un incidente que dispara notificación regulatoria **no puede** ser inferior a SEV2.

### 3.3 Roles: quién manda y quién habla

- **Incident Commander**: decide, prioriza, delega, mantiene el estado y corta las discusiones. **No
  depura, no teclea, no investiga.** Su valor es el ancho de banda de coordinación, no el
  conocimiento del sistema — por eso el mejor experto es normalmente el **peor** IC: en cuanto se
  mete en el problema, deja de haber IC. Si el IC tiene las manos en el teclado, no hay IC.
- **Operations lead**: única persona autorizada a ejecutar cambios sobre producción durante el
  incidente, o a delegarlos nominalmente. Evita la mitigación simultánea de tres personas pisándose.
- **Communications lead**: interno (dirección, soporte, comercial, legal) y externo (status page,
  clientes). Traduce a lenguaje de usuario y protege al Ops lead de las interrupciones.
- **Scribe**: timeline en vivo con marcas de tiempo — hechos, hipótesis, decisiones y quién las tomó.
  Reconstruir el timeline a posteriori es el 90 % del coste del postmortem y el 100 % de sus errores.
- **Expertos (SME)**: entran, aportan, salen. El canal no es una sala de espectadores; el IC tiene
  potestad explícita de **expulsar a quien no aporta, incluido cualquier directivo**.
- **Escalado por tiempo, no por heroísmo**: si en N minutos no hay mitigación ni hipótesis, se
  escala. Los umbrales están escritos, no implícitos.
- **Traspaso de mando en incidentes largos**: turnos máximos (2-4 h por IC), traspaso **explícito y
  anunciado en el canal** ("IC pasa de A a B a las 04:12"), con briefing de estado: qué se sabe, qué
  se descarta, qué está en vuelo, qué se ha comunicado y a quién, qué decisiones están pendientes.
  Un incidente de 12 horas con un solo IC termina en decisiones malas por agotamiento.

### 3.4 Comunicación

- **Canal único**, con nombre predecible (`#inc-YYYYMMDD-<slug>`), persistente y exportable. Prohibido
  coordinar por DM: el contexto en privado es contexto perdido.
- **Plantilla de actualización** (misma estructura siempre, para que se lea en diagonal):
  `[SEV<n>] <servicio> — <impacto en lenguaje de usuario> · Estado: investigando|identificado|mitigando|monitorizando|resuelto · Acción actual: <qué> · Próxima actualización: <hora>`.
- **Cadencia fija aunque no haya novedad**. "Sin novedad, seguimos" es información: evita que cinco
  personas entren a preguntar y rompan la respuesta.
- **Lenguaje**: describe **impacto**, no arquitectura. Ni pánico ni eufemismo: prohibido "problemas
  intermitentes" cuando el servicio está caído, y prohibido especular con la causa antes de tenerla.
  Nunca prometas una hora de resolución que no controlas; promete la hora de la **próxima
  actualización**, que sí controlas.
- **Status page** para impacto externo, con criterio escrito de cuándo se publica (no "cuando alguien
  se acuerde"). El primer mensaje sale antes de saber la causa. La ausencia de status page durante
  una caída no la oculta: la convierte en incidente de confianza además de técnico.
- **En incidente de seguridad**: la comunicación externa se coordina con legal/DPO **antes** de
  publicar, y el detalle técnico se omite (§5 y skill hermana). Además, si se sospecha que el atacante
  tiene acceso al canal corporativo, la coordinación se traslada a un canal fuera de banda.

### 3.5 Decisión bajo incertidumbre

- **Mitigar antes que entender.** El usuario no cobra en explicaciones. Palancas por orden: rollback,
  desactivar feature flag, drenar tráfico, degradar funcionalidad, escalar capacidad, failover.
- **Excepción que hay que decir en voz alta**: cuando hay sospecha de compromiso, la mitigación
  destructiva (reinstalar, recrear, apagar) **destruye la evidencia y con ella la capacidad de saber
  si el atacante sigue dentro**. En ese caso se coordina con `incident-response-forensics-standards`:
  se preserva primero (memoria y disco), se aísla en vez de destruir, y el IC deja constancia de la
  decisión y de quién la tomó. Un servicio restaurado sobre un sistema aún comprometido es un
  incidente que se reabre peor.
- **Rollback es la opción por defecto** ante cualquier cambio reciente correlacionado. Fix forward
  exige justificación explícita del IC y un límite de tiempo tras el cual se revierte igualmente.
- **Timeboxing de hipótesis**: cada línea de investigación tiene tiempo asignado; agotado, se
  reporta y se cambia de vía. Sin esto, tres personas persiguen la misma corazonada durante una hora.
- **Cuándo parar**: el incidente se declara mitigado cuando el impacto de usuario cesa y está
  verificado con telemetría, no cuando "parece que va bien". Se pasa a **monitorización** durante una
  ventana definida antes de cerrar.

### 3.6 Cierre y aprendizaje

- **Cierre** con: hora de mitigación y de resolución (distintas), impacto cuantificado (usuarios,
  peticiones, tiempo, dinero si se puede), causa clasificada según taxonomía, acciones abiertas,
  obligaciones regulatorias disparadas y su estado.
- **Postmortem sin culpa** en ≤ 5 días laborables. Contenido mínimo: impacto, timeline, factores
  contribuyentes (en plural — nunca *la* causa raíz singular), qué funcionó, qué no, **por qué la
  detección tardó lo que tardó**, y acciones. La pregunta correcta es "¿qué hizo que esta acción
  pareciera razonable en ese momento?", no "¿quién se equivocó?".
- **Sin culpa no es impunidad**: el error honesto en un sistema que lo permitió se trata en el
  postmortem; la actuación deliberada o negligente se trata por otro canal y no se diluye aquí.
- **Acciones**: dueño nominal (persona, no equipo), fecha, y en el **mismo backlog** que el producto.
  Cada acción se clasifica por eficacia: eliminar la clase de fallo > automatizar > detectar antes >
  documentar > "tener cuidado" (esta última no es una acción, es un deseo — no se acepta).
- **Revisión de ejecución, no de redacción**: revisión mensual del estado de las acciones abiertas.
  La métrica del proceso es el **porcentaje de acciones cerradas en plazo**; si es bajo, el
  postmortem es teatro y hay que dejar de escribirlos o empezar a ejecutarlos.
- **Problem management** (ITIL 4): los incidentes que comparten factores contribuyentes se agregan en
  un *problem* con dueño propio y presupuesto de ingeniería. Tres incidentes iguales no son tres
  incidentes: son uno sin resolver.
- **Revisión de tendencias trimestral**: distribución por taxonomía de causa, por servicio y por hora
  del día; recurrencias; incidentes detectados por el cliente antes que por la telemetría (métrica
  de calidad de la detección, se devuelve a `observability-standards` y a
  `detection-engineering-standards`).

## 4. Calidad del proceso (los gates)

Se audita el **proceso**, no a las personas. Gates, en orden de coste creciente:

1. **¿Se declaró, y a tiempo?** Diferencia entre primera señal (alerta, ticket, tuit) y declaración.
   Si el patrón es "se declaró cuando ya lo sabía el cliente", el problema está en el umbral de
   declaración o en el miedo a declarar, no en el equipo de guardia.
2. **¿Hubo IC nombrado y anunciado?** Un incidente sin IC identificable en el canal es un fallo de
   proceso aunque el resultado técnico fuera bueno.
3. **¿Se respetó la cadencia de comunicación?** Contable sobre el canal: huecos > 2× la cadencia son
   hallazgo.
4. **¿Hay timeline escrito en vivo?** Un postmortem reconstruido de memoria a los 3 días es ficción
   con marcas de tiempo.
5. **¿El postmortem tiene acciones con dueño nominal y fecha, y se cerraron?** Ver §3.6.
6. **¿La severidad asignada resistió la revisión posterior?** Tanto el sobredimensionado crónico
   (todo es SEV1 → nada lo es) como el infradimensionado sistemático son bugs de la tabla.
7. **Ejercicios**: tabletop trimestral (mesa, sin sistemas: decisiones, roles y comunicación —
   incluye un escenario de seguridad y uno de proveedor caído) y game day con inyección real. Todo
   ejercicio produce hallazgos con dueño; un ejercicio que no puede fallar es una demostración.
8. **Prueba de la cadena de notificación regulatoria**: simular un incidente con datos personales y
   cronometrar cuánto tarda la organización en tener la información mínima para notificar. Si tarda
   más que el plazo, el plazo no se cumplirá el día real (§6).

## 5. Seguridad del proceso

- **Las herramientas de incidente son objetivo de primer nivel**: paging, chat, status page y
  documentación de runbooks. Quien las controla, controla la respuesta. MFA, control de acceso propio
  y **una vía alternativa probada** para el caso de que el proveedor de chat sea precisamente lo caído.
- **Plan fuera de banda**: lista de contactos, puente de voz y canal alternativos, accesibles sin el
  SSO corporativo y **probados** (una lista de teléfonos que vive en el wiki caído no existe).
  Coordina con `identity-access-management-standards` para el break-glass.
- **Compartimentación en incidentes de seguridad**: el canal de gestión general puede estar
  comprometido y la investigación puede necesitar sigilo. El IC decide qué se dice en el canal amplio
  y qué en el canal restringido de IR; se documenta la decisión.
- **Comunicación sin fugas**: la status page describe impacto, no arquitectura ni versiones; los
  postmortems públicos se sanean de PII, rutas internas y detalle explotable.
- **Datos personales en el canal**: prohibido pegar volcados con PII en el canal de incidente.
  Referencia identificadores; el canal se archiva y se replica en más sitios de los que crees.
- **Obligación de notificar**: la decide legal/DPO con la información que aporta la gestión del
  incidente, y **no se pospone hasta tener el diagnóstico completo** — se notifica con lo que se sabe
  y se amplía después (§6). Esto no es asesoramiento jurídico: el criterio legal lo fija legal/DPO.

## 6. Operabilidad: métricas, plazos y carga

### Métricas que sirven

- **Tiempo hasta declaración** (primera señal → declaración): mide el proceso, es accionable y casi
  nadie lo mide. La métrica más infravalorada del dominio.
- **Tiempo hasta mitigación** (declaración → cese del impacto): es lo que el usuario nota.
- **Porcentaje de acciones de postmortem cerradas en plazo**: mide si el aprendizaje existe.
- **Incidentes detectados por el cliente antes que por la telemetría**: mide la detección.
- **Recurrencia por taxonomía de causa**: mide si se ataca la clase de fallo o el síntoma.
- **Carga de incidente por persona y por turno**: mide la sostenibilidad del proceso.

### Trampas del MTTR (no lo uses a ciegas)

- Es una **media sobre una distribución de cola larga**: un incidente de 20 h y nueve de 5 min dan un
  "MTTR de 2 h" que no describe ninguno. Usa **mediana y p90 segmentados por severidad**, o la
  distribución completa.
- Es **fácil de manipular**: cerrando pronto, no declarando los pequeños, o reclasificando a la baja.
- Mezcla fases distintas (detectar, declarar, diagnosticar, mitigar, resolver): agregado, oculta
  exactamente el cuello de botella que buscas.
- **Nunca** como objetivo individual, de equipo ni de bonus: se optimiza el número, no el servicio.

### Plazos regulatorios (verifica cada cifra en §8 — no los cites de memoria)

Datos verificados en agosto de 2026; **el criterio legal es de legal/DPO, no de ingeniería**:

- **RGPD art. 33**: notificación a la autoridad de control (AEPD en España) **sin dilación indebida
  y como máximo en 72 h** desde el **conocimiento** de la brecha, salvo que sea improbable que
  suponga riesgo para derechos y libertades; comunicación a los **afectados** si el riesgo es alto
  (art. 34). El encargado notifica al responsable sin dilación indebida. Se admite notificación
  **progresiva** (parcial en plazo, ampliación después). Documentar **toda** brecha, se notifique o no.
- **NIS2**: **alerta temprana en 24 h**, **notificación en 72 h**, **informe final en 1 mes** desde el
  conocimiento del incidente significativo; informe intermedio si lo pide la autoridad. En España, el
  CSIRT de referencia es **INCIBE-CERT** (privado), **CCN-CERT** (sector público) y ESPDEF-CERT
  (defensa). **La transposición española (Ley de Coordinación y Gobernanza de la Ciberseguridad)
  seguía sin publicarse en el BOE en agosto de 2026** — verifica el estado antes de afirmar nada.
- **DORA** (entidades financieras): notificación inicial de incidente **grave** en **4 h desde la
  clasificación como grave y en todo caso ≤ 24 h desde la detección**, informe intermedio ≤ 72 h e
  informe final ≤ 1 mes desde el último intermedio. Plantillas de los RTS aplicables desde marzo 2025.
- **ENS (RD 311/2022)**: notificación al CCN-CERT vía LUCIA, con plazos escalonados por impacto según
  la guía CCN-STIC 817. Los plazos concretos por nivel proceden de guías divulgativas: **contrástalos
  con el texto vigente antes de usarlos** (§8).
- **Concurrencia**: un mismo incidente puede disparar RGPD + NIS2 + DORA + ENS + contrato con cliente
  simultáneamente, con relojes distintos que arrancan en momentos distintos. Se gestiona con **una
  sola matriz de obligaciones por tipo de incidente, preparada antes**, no improvisada a las 03:00.

### On-call sostenible (óptica de proceso)

El dimensionado, la compensación y la higiene de alertas viven en `sre-practice-standards`. Desde el
proceso de incidente:

- **La carga de incidentes es una métrica del proceso**, no del individuo: si una persona lleva tres
  SEV1 en un mes, el problema es el sistema.
- **Fatiga de alertas** = incidentes no declarados. Es la forma más común de que el proceso falle
  silenciosamente.
- **Tras un SEV1 nocturno hay descanso compensado**; un IC agotado toma decisiones caras.
- **Nadie es IC y Ops a la vez en SEV1-SEV2**. Si no hay gente para separar los roles, el incidente ya
  te está diciendo el tamaño real de tu capacidad de respuesta.

### Incidentes que no son técnicos

- **Proveedor / SaaS caído**: sigue siendo tu incidente frente a tu usuario. Roles idénticos; el Ops
  lead gestiona el workaround y el escalado **contractual** con el proveedor (ten el canal de soporte
  y el número de contrato **antes**, no durante). Documenta el impacto para la revisión de riesgo de
  terceros (`grc-compliance-standards`).
- **Brecha de datos personales**: activa a legal/DPO **en la declaración**, no en el cierre; el reloj
  de 72 h corre en paralelo a la mitigación. La evaluación de riesgo para los interesados y la
  comunicación a los afectados no la decide ingeniería.
- **Fallo de dato / cálculo incorrecto publicado**: el impacto es reputacional y a veces regulatorio,
  y la mitigación incluye **corregir hacia atrás** lo ya emitido. Coordina con
  `data-platform-standards`.
- **Crisis que excede al servicio** (pérdida de sitio, indisponibilidad prolongada): traspaso formal
  al plan de continuidad; ver `bcdr-standards` (planificada, Ola 1).

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: tabla de severidades y matriz de obligaciones regulatorias revisadas al menos
  anualmente y tras cualquier incidente donde generaran duda; plantillas de comunicación revisadas
  tras cada SEV1; taxonomía de causas revisada al cerrar cada trimestre.
- **El proceso se adopta incrementalmente**: empieza por severidades + IC + canal único + postmortem.
  Un proceso de 40 páginas que nadie lee produce cero incidentes bien gestionados.
- **Lo que no se usa durante un incidente, se borra**. La documentación de incidentes se mide por su
  uso a las 03:00, no por su completitud.
- **Formación real**: nadie es IC sin haber acompañado a otro IC y haber pasado por un tabletop. El
  rol se entrena, no se asigna por antigüedad.

**PROHIBIDO**
- ❌ No declarar "para no hacer ruido", o esperar a estar seguro antes de declarar.
- ❌ Exigir aprobación jerárquica para declarar un incidente.
- ❌ Negociar la severidad a la baja por sus consecuencias (política, SLA, cliente, informe mensual).
- ❌ Bajar la severidad de un posible compromiso o de una posible brecha antes de la evaluación.
- ❌ Incidente sin IC nombrado, o IC que depura, teclea o investiga.
- ❌ IC y Ops lead en la misma persona en SEV1-SEV2.
- ❌ Coordinar por DM, por hilos paralelos o en tres canales; incidente sin timeline escrito en vivo.
- ❌ Turno de IC indefinido en un incidente largo, o traspaso de mando no anunciado en el canal.
- ❌ Buscar la causa raíz mientras el usuario está afectado, teniendo un rollback disponible.
- ❌ Mitigar destruyendo evidencia (reinstalar, recrear, apagar) ante sospecha de compromiso, sin
  coordinar con `incident-response-forensics-standards`.
- ❌ Silencio externo durante una caída visible, o "problemas intermitentes" cuando está caído.
- ❌ Prometer una hora de resolución; especular públicamente sobre la causa; múltiples voces hablando
  hacia fuera.
- ❌ Detalle técnico explotable o PII en status page, postmortem público o canal de incidente.
- ❌ Postmortem con culpables, con "error humano" como conclusión, o con *la* causa raíz en singular.
- ❌ Postmortem sin acciones con dueño nominal y fecha, o acciones en una lista aparte que nadie
  prioriza ni revisa.
- ❌ Acciones del tipo "tener más cuidado", "formar al equipo" o "revisar mejor" como remedio único.
- ❌ Cerrar el incidente sin verificar la mitigación con telemetría.
- ❌ Usar MTTR (o el conteo de incidentes) como objetivo individual, de equipo o de bonus.
- ❌ Retrasar la notificación regulatoria hasta tener el diagnóstico completo.
- ❌ Improvisar el mapa de obligaciones legales durante el incidente.
- ❌ Tabletops y game days anunciados como demostración; si no puede fallar, no es un ejercicio.
- ❌ Convertir el proceso en burocracia ITSM: CAB, formularios y aprobaciones dentro del incidente.

## 8. Verificación web obligatoria

Antes de fijar cualquier cifra, plazo o referencia, **búscalo — no lo recuerdes**. Los plazos legales
son donde más caro sale inventar:

1. **RGPD art. 33-34 y guía de la AEPD** sobre notificación de brechas: plazo, canal de la sede
   electrónica y criterios de riesgo. Verificado ago-2026: 72 h desde el conocimiento, notificación
   progresiva admitida.
2. **NIS2 (Directiva 2022/2555) y su transposición española**: 24 h / 72 h / 1 mes confirmados a
   ago-2026; **pendiente**: la Ley de Coordinación y Gobernanza de la Ciberseguridad seguía sin
   publicarse en BOE — confirma su estado, el destinatario exacto y si la revisión de NIS2 propuesta
   por la Comisión (enero 2026, con reporte de detalles de rescate en ransomware) ya está en vigor.
3. **DORA**: 4 h / 24 h / 72 h / 1 mes y los RTS de reporte (Reglamento 2025/301 y sus anexos).
   Existen fuentes que describen un modelo de cuatro hitos en lugar de tres: **contrasta**.
4. **ENS (RD 311/2022) y guía CCN-STIC 817**: plazos por nivel de impacto (24 h / 72 h / 5 días
   circulan en guías divulgativas). **No verificado contra la fuente primaria** — confírmalo antes de
   usarlo.
5. **ITIL**: ITIL 4 sigue operativo; PeopleCert anunció **ITIL v5 en febrero de 2026** con
   publicaciones aún pendientes. Verifica el estado antes de citar guía normativa de ITSM.
6. **Referencias de mando de incidente**: `response.pagerduty.com` (roles, entrenamiento de IC) y la
   guía de gestión de incidentes de Google (`sre.google`, IMAG, capítulo 9 del SRE Workbook).
   Comprueba si han cambiado antes de citarlas como canon.
7. **Postura sobre el pago de rescate**: verificado ago-2026 — el **Reino Unido** avanza una
   prohibición para sector público y CNI más deber de notificación previa al pago; la **UE y España**
   no prohíben pagar y regulan por transparencia y sanciones/AML. Cambia rápido: verifícalo, y la
   decisión de pagar **no es técnica** (ver `incident-response-forensics-standards`).
8. **Herramientas de gestión** (paging, status page, incident bots) que vayas a recomendar: estado,
   licencia y cualquier incidente de seguridad reciente del proveedor.

**Hueco declarado**: los plazos del ENS por nivel de impacto (§6) y el detalle exacto del modelo de
hitos de DORA no se han contrastado contra la fuente primaria en esta revisión. No los uses sin
verificarlos.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
