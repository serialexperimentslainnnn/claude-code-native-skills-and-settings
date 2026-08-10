---
name: sre-practice-standards
description: SRE practice standards for service reliability. Use when defining SLIs, SLOs, error budgets, multi-window burn-rate alerts, on-call rotation sizing, paging and handover, toil measurement and reduction, production readiness reviews, change risk classification, reliability game days, capacity planning or DORA metrics.
---

# Estándares de práctica SRE — fiabilidad como disciplina de ingeniería

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al definir, revisar o corregir la **práctica de fiabilidad** de un servicio: elección de SLI desde
user journeys, definición de SLO y ventanas, error budgets y la política que disparan, alertas por burn
rate, diseño de rotación de guardia y paging, mando de incidente y severidades, comunicación durante
caídas, postmortems sin culpa y seguimiento de acciones, identificación y reducción de toil, production
readiness reviews, clasificación de riesgo del cambio, capacity planning, game days y simulacros, métricas
DORA y la negociación fiabilidad vs. velocidad.

Principio rector: **la fiabilidad es una decisión de producto expresada en un número, no una aspiración**.
Sin SLO acordado con el dueño del servicio no hay error budget; sin error budget no hay criterio objetivo
para decidir entre enviar features y arreglar la plataforma, y la discusión degenera en quién grita más.
Corolario: 100 % no es el objetivo — el objetivo es el nivel de fiabilidad que el usuario nota y el negocio
paga; el resto del presupuesto se gasta deliberadamente en velocidad.

**No aplica**: ver `observability-standards` (instrumentación, métricas, trazas, logs y su pipeline —
aquí se decide *qué* se mide y *qué* despierta a alguien, no *cómo* se instrumenta),
`incident-management-standards` (**el proceso de gestión del incidente**, agnóstico de causa y
canónico: criterios de declaración, matriz de severidad, roles y traspaso de mando, comunicación y
portavoz, cierre, postmortem como artefacto, métricas del proceso, incidentes de proveedor o de dato.
Lo que esta skill contiene sobre mando de incidente y postmortem es el **resumen aplicado a un
incidente de fiabilidad**: si ambas divergen, manda aquella),
`incident-response-forensics-standards` (incidente de **seguridad**: contención sin destruir
evidencia, adquisición, cadena de custodia, erradicación y recuperación, notificación regulatoria),
`bcdr-standards` (continuidad y DR como programa: RTO/RPO, sitios alternos,
ejercicios de recuperación completa), `chaos-engineering-standards` (**el diseño y la mecánica
del experimento de caos son suyos** —hipótesis de estado estable, herramienta de inyección,
*blast radius*, condiciones de aborto—; **el game day como práctica de fiabilidad y el SLO que
sirve de estado estable son de aquí**), `itsm-itil-standards` (proceso de servicio: catálogo, CAB, gestión de
peticiones, cumplimiento contractual), `web-performance-standards` (**el SLO del
servicio y su error budget son de aquí**; **la experiencia percibida en el navegador** —Core Web
Vitals, RUM al percentil 75— **es suya**. Un servicio puede cumplir su SLO de disponibilidad y
latencia de servidor y aun así ser lento para el usuario: son dos medidas distintas y ninguna
sustituye a la otra), `performance-engineering-standards` (*"¿cuánta latencia
podemos permitirnos y qué hacemos si la superamos?"* es de aquí; *"¿por qué es lenta y qué la
arregla?"* es suya), `knowledge-management-standards` (**el contenido del runbook —qué comprueba, qué comando
se ejecuta, qué se escala— es de aquí**; **que exista, tenga dueño, fecha de revisión y se haya
ejecutado al menos una vez es criterio suyo**. La regla que ambas sostienen: **un runbook que nadie
ha ejecutado es ficción**, y descubrirlo durante un incidente es la peor forma de averiguarlo),
`tech-leadership-standards` (**las métricas DORA y los SLO son de aquí y miden
sistemas y equipos**; **la prohibición de usarlas para evaluar personas se refuerza allí**, porque
esa presión llega de la línea de gestión y no del equipo. Ninguna de las dos skills acepta un
"DORA por ingeniero"), `finops-standards` (**fiabilidad frente a coste es un trade-off explícito**: la
redundancia, el sobredimensionado y el multi-AZ se deciden aquí con el error budget como árbitro;
**cuánto cuesta esa decisión y en qué unidad económica se expresa, allí**. Ninguna de las dos
recorta a la otra sin decisión declarada), `platform-engineering-standards` (**la
plataforma interna también es un servicio y se le aplican SLO, on-call y error budget de aquí**; su
diseño como producto, su camino pavimentado y su adopción son suyos), `itsm-itil-standards`
(**un SLA contractual no es un SLO** — el SLA y su régimen de créditos son suyos, el SLO
y su error budget son de aquí, y confundirlos produce compromisos imposibles u objetivos internos
sin sentido), `testing-qa-standards` (canary, *feature flags* y *shadow traffic*
**se diseñan allí como tipo de prueba**; la decisión de desplegar así, por fiabilidad y error
budget, es de aquí).

## 2. Decisiones por defecto

> Verificar la última versión y el estado de las referencias por web antes de fijarlas en un proyecto real (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Origen del SLI | **Critical user journey** medido lo más cerca posible del usuario (borde/cliente) | Métrica de servidor si no hay telemetría de cliente — documentar el sesgo |
| Nº de SLO por servicio | **2-3** (disponibilidad + latencia; frescura si hay pipeline) | Más solo en servicios con modos de fallo realmente distintos |
| Ventana de SLO | **28 días rolling** | Trimestre natural si el ciclo de negocio lo exige; nunca "mes natural" para paging |
| Objetivo inicial | Derivado del **rendimiento histórico**, no del deseo: mide 4 semanas y fija justo por debajo | — |
| Alerta de budget | **Multi-window multi-burn-rate** (§6) | Solo si el tráfico es suficiente; en tráfico bajo, sondas sintéticas o SLO agregado |
| Política de error budget | **Escrita, firmada por producto e ingeniería, con consecuencia automática** | — |
| Severidades | **SEV1-SEV4** con definición por impacto de usuario, no por componente | Cualquier escala, si es inequívoca en 10 segundos |
| Mando de incidente | Roles **IC / Comms / Ops** separados (ICS); IC no depura | En incidentes pequeños, IC puede acumular Comms |
| Postmortem | **Obligatorio en SEV1-SEV2 y en toda recurrencia**, sin culpa, con acciones con dueño y fecha | — |
| Carga de guardia | **≤ 2 páginas accionables por turno**; rotación de **≥ 6 personas** (ideal 8) | Follow-the-sun si hay equipos en 2+ regiones |
| Techo de toil | **≤ 50 %** del tiempo del equipo, medido, con objetivo de reducción trimestral | — |
| Lanzamiento a producción | **PRR superada** (§4) antes de tráfico real de usuarios | — |
| Métricas de entrega | **DORA, 5 métricas** (§6): frecuencia de despliegue, lead time, change failure rate, tiempo de recuperación y **rework rate** | — |

## 3. Estructura y convenciones

### Del user journey al SLI

1. Enumera los **critical user journeys** (CUJ) del servicio en lenguaje de usuario: "el cliente completa el
   pago", "el informe nocturno está disponible a las 07:00". Si no puedes nombrar el journey, el SLO que
   escribas medirá una máquina, no un usuario.
2. Para cada CUJ elige el tipo de SLI del menú, no lo inventes:
   - **Petición/respuesta**: disponibilidad (proporción de peticiones válidas servidas OK), **latencia**
     (proporción de peticiones más rápidas que un umbral) y calidad/corrección.
   - **Pipeline / procesamiento de datos**: frescura, corrección, cobertura (proporción de datos procesados).
   - **Almacenamiento**: durabilidad, latencia de lectura.
3. Formula el SLI **siempre como proporción de eventos buenos sobre eventos válidos** (`buenos/válidos`), no
   como media. Las medias esconden la cola; la cola es el usuario enfadado.
4. Define explícitamente qué es un "evento válido": qué códigos, qué rutas, qué tráfico se excluye (health
   checks, bots, peticiones abortadas por el cliente). Esa exclusión es parte del contrato.

**Latencia**: umbral + proporción (`99 % de las peticiones < 300 ms`), no "p99 = 300 ms" como objetivo — un
percentil como objetivo no es componible ni sumable en un budget. Usa dos umbrales cuando el journey lo
merezca (rápido / tolerable).

### Especificación del SLO

Todo SLO se escribe como artefacto versionado en el repo del servicio (SLO as code, revisado en PR) con:
nombre del CUJ, SLI exacto (numerador, denominador, fuente de datos), objetivo, ventana, dueño de negocio,
consecuencias (política de budget) y fecha de la próxima revisión. Un SLO sin dueño de negocio es una
métrica de vanidad.

### Política de error budget (el artefacto que da valor al SLO)

Escrita **antes** de agotar el presupuesto, no durante la bronca. Contenido mínimo:

- **Umbral de agotamiento** y qué se dispara: congelación de cambios no relacionados con fiabilidad,
  reasignación de un porcentaje de la capacidad del equipo a trabajo de fiabilidad, revisión obligatoria
  con producto.
- **Excepciones** nombradas (parches de seguridad, cambios que reducen riesgo) y quién puede aprobarlas.
- **Quién decide** el desbloqueo y con qué evidencia.
- **Escape hatch**: qué pasa si el budget se agota por causa externa (proveedor cloud) — se documenta, no se
  ignora; si ocurre repetidamente es una decisión de arquitectura, no mala suerte.
- Una política que nunca ha frenado nada no es una política: es decoración.

### Guardia y escalado

- Rotación **≥ 6 personas** por turno primario (con 6 el suelo estructural de toil ya es ~33 %; con menos,
  la guardia se come al equipo). Turnos con solape y **handover escrito** en canal compartido — nunca por DM.
- El handover incluye: incidentes abiertos, hipótesis a medias, cambios en vuelo, alertas silenciadas y su
  caducidad. El contexto no puede vivir en la cabeza de una persona.
- **Escalado por tiempo, no por heroísmo**: si el on-call primario no reconoce en N minutos, escala solo; si
  no hay mitigación en M minutos, entra el secundario/IC. Los umbrales están escritos, no implícitos.
- Compensación y descanso reglados; un turno con noche rota descuenta del día siguiente. La guardia sin
  descanso compensado es deuda de personas y termina en rotación de plantilla.
- **Todo page enlaza runbook**; alerta sin runbook y sin acción posible se elimina, no se silencia para siempre.

### Mando de incidente

- Declara pronto y **degrada con libertad**: es barato abrir un SEV2 y bajarlo; es caro descubrir a la hora
  que nadie estaba coordinando.
- **IC coordina y decide, no depura.** Si el IC tiene las manos en el teclado, no hay IC.
- Roles: **IC** (decisión, prioridad, delegación), **Comms** (estado a interesados y status page), **Ops**
  (manos). Un canal único por incidente, con timeline escrito en vivo — la reconstrucción posterior es el
  90 % del coste del postmortem.
- **Mitigar antes que entender**: rollback, feature flag, drenar tráfico, escalar capacidad. La causa raíz
  se investiga después; el usuario no cobra en explicaciones.
- Comunicación externa: cadencia fija por severidad (p. ej. SEV1 cada 15-30 min) **aunque no haya novedad**;
  impacto en lenguaje de usuario, sin causa técnica especulativa ni detalles que faciliten un ataque (§5).

## 4. Calidad y verificación

Gates que rompen el lanzamiento o el cambio, en orden de coste creciente:

1. **Production Readiness Review (PRR)** antes de recibir tráfico real. Checklist mínima: SLO definido y
   acordado; dashboards de golden signals; alertas conectadas a un on-call **nombrado**; runbook con los 3-5
   modos de fallo conocidos; plan y **prueba de rollback**; límites y timeouts en dependencias; capacidad
   dimensionada con datos de carga; backups/restauración verificados si tiene estado; propietario y ruta de
   escalado. Sin PRR superada, no hay tráfico de usuario — sin excepción "temporal".
2. **Clasificación de riesgo del cambio** (§6) aplicada en el PR/pipeline; los cambios de riesgo alto exigen
   canary con criterio de abortado automático.
3. **Revisión de acciones de postmortem** con dueño y fecha, seguidas en el mismo backlog que el producto
   hasta su cierre. Métrica de salud del proceso: **porcentaje de acciones cerradas en plazo** — si es bajo,
   los postmortems son teatro.
4. **Game days trimestrales**: fallo inyectado en un entorno realista con la guardia real respondiendo. Se
   evalúa detección (¿alertó?), diagnóstico (¿sirvió el runbook?) y mitigación (¿funcionó el rollback?). Todo
   hallazgo entra al backlog como acción con dueño.
5. **Simulacro de DR** con la periodicidad que fije el programa de continuidad (ver `bcdr-standards`); desde
   SRE se aporta el criterio de SLO durante la degradación y la validación de runbooks.
6. **Revisión trimestral de SLO**: ¿el objetivo sigue reflejando lo que el usuario nota? ¿Hubo budget quemado
   sin quejas (objetivo demasiado estricto) o quejas sin budget quemado (SLI mal elegido)? Ambos son bugs del
   SLO, no del servicio.

## 5. Seguridad del proceso operativo

- **Acceso de emergencia (break-glass)**: cuenta/rol de elevación con MFA, uso registrado, alerta automática
  al usarse y revisión posterior obligatoria. La urgencia justifica el acceso, nunca su falta de auditoría.
- Herramientas de incidente (paging, chat de incidente, status page) con autenticación fuerte y control de
  acceso propio; son objetivo de primer nivel — quien las controla controla la respuesta.
- **Un incidente de fiabilidad puede ser un incidente de seguridad**: define el criterio de reclasificación
  (indicio de intrusión, exfiltración, datos alterados) y el traspaso inmediato al proceso de seguridad
  (`incident-response-forensics`). En cuanto se sospecha compromiso, **preservar evidencia antes de mitigar**
  destruyendo estado (no reinstalar el host "para que vuelva").
- **Comunicación sin fugas**: la status page describe impacto, no arquitectura interna; los postmortems
  públicos se saneen de PII, rutas internas, versiones exactas y detalles explotables.
- Postmortems internos con datos de usuario: minimiza, referencia identificadores en vez de copiar datos, y
  aplica la retención del resto de artefactos con PII.
- La cultura sin culpa **no es impunidad**: aplica a error honesto en un sistema que lo permitió. La
  actuación deliberada o negligente se trata por otro canal — no se diluye en el postmortem.

## 6. Operabilidad: alertas, capacidad y velocidad

### Golden signals y alertas

- Instrumenta y vigila los cuatro: **latencia, tráfico, errores, saturación** (colas/lag y utilización en
  sistemas de trabajo). Son la base del diagnóstico; **no todos son motivo de page**.
- **Se pagina sobre síntoma de usuario (SLO en riesgo), se diagnostica sobre causa.** CPU alta no despierta a
  nadie; el CUJ degradado, sí.
- **Alerta multi-window multi-burn-rate** como default (Google SRE Workbook, cap. "Alerting on SLOs",
  iteración 6). Tabla de partida — verificar y **ajustar por servicio**:

  | Budget consumido | Ventana larga | Ventana corta | Burn rate | Acción |
  |---|---|---|---|---|
  | 2 % | 1 h | 5 min | 14.4 | **Page** |
  | 5 % | 6 h | 30 min | 6 | **Page** |
  | 10 % | 3 días | 6 h | 1 | Ticket |

  Regla: ventana corta = 1/12 de la larga; la corta garantiza que la alerta se apaga poco después de la
  mitigación y puede volver a disparar si recae.
- **Prohibido usar `for`/duración** como criterio en alertas de SLO: una serie de picos cortos de error nunca
  alcanza la duración y consume el presupuesto igual.
- **Tráfico bajo rompe el modelo**: con pocas peticiones el ratio es ruido. Alternativas: sondas sintéticas
  que generen volumen conocido, agregar varios servicios en un SLO común, o alargar ventanas y aceptar
  detección más lenta — decidido explícitamente, no por defecto silencioso.
- Higiene de alertas cada trimestre: toda alerta que no haya provocado una acción en 90 días se elimina o se
  degrada a canal no-paginante. Agrupa las cascadas: un fallo de BD es **un** hilo de respuesta, no doce pages.

### Toil

- Definición operativa (todas a la vez): manual, repetitivo, automatizable, táctico, sin valor duradero y que
  **escala linealmente con el servicio**. Trabajo aburrido pero de ingeniería no es toil.
- **Mídelo antes de atacarlo**: 2-3 semanas de registro por categoría, ranking por horas. Sin medición, se
  automatiza lo divertido, no lo caro.
- Orden de ataque: **eliminar** la necesidad (cambiar el diseño o rechazar la tarea) > **autoservicio** para
  quien la pide > **automatizar** el procedimiento. Automatizar un proceso que no debería existir es toil
  con más pasos.
- Objetivo numérico por trimestre (p. ej. "de 30 % a 20 % del tiempo del equipo"), revisado como cualquier
  otro objetivo de ingeniería.

### Capacidad y riesgo del cambio

- **Capacity planning con dos entradas**: demanda orgánica prevista (tendencia + estacionalidad + eventos de
  negocio conocidos) y demanda inorgánica (lanzamientos, campañas). Se traduce a recursos vía un **modelo de
  carga validado con pruebas**, no por regla de tres sobre la CPU media.
- Prueba de carga antes de comprometer un SLO nuevo y antes de picos previstos; conoce el punto de saturación
  y el modo de degradación (¿se degrada o se cae?).
- **Clasificación de riesgo del cambio** — determina el rigor del despliegue:
  - *Bajo*: reversible, sin cambio de esquema ni de contrato, tras feature flag → rolling automático.
  - *Medio*: toca camino crítico o dependencias → canary con métricas de abortado y rollback probado.
  - *Alto*: migración de datos, cambio de contrato, irreversible en la práctica → expand/contract, ventana
    acordada, plan de vuelta atrás escrito y ensayado, comunicación previa.
- **El cambio es la causa dominante de incidentes**: si no sabes qué cambió, empieza por ahí. Todo despliegue
  deja marca correlacionable con la telemetría.

### Métricas DORA

Cinco métricas vigentes (DORA amplió las cuatro clásicas con **rework rate**): frecuencia de despliegue, lead
time para cambios, change failure rate, tiempo de recuperación y rework rate. Úsalas para **diagnosticar el
sistema de entrega**, nunca para evaluar personas ni comparar equipos entre sí. Throughput y estabilidad se
leen **juntos**: subir despliegues mientras crece el change failure rate no es mejora, es deuda acelerándose.

### Negociar fiabilidad frente a velocidad

- El error budget es el mecanismo de negociación: mientras haya presupuesto, **producto decide**; cuando se
  agota, decide la política acordada. Eso convierte un conflicto político en una regla.
- Si el equipo nunca consume budget, **está siendo demasiado conservador**: sobra fiabilidad y falta
  velocidad — sube el ritmo o baja el objetivo (y ahorra el coste).
- **Bajar el objetivo porque el coste no lo sostiene**: es la contraparte legítima del punto
  anterior y **se decide aquí, no en la hoja de coste**. `finops-standards` aporta cuánto cuesta
  cada nueve; **la firma es de quien responde del SLO**, va en un ADR con el impacto en el usuario
  declarado, y se comunica a quien consume el servicio. Un objetivo que baja para que deje de
  sonar la alerta —o para cuadrar un presupuesto sin decirlo— no es una renegociación: es un
  compromiso roto en silencio.
- Fiabilidad extra por encima del SLO no se vende: cada nueve adicional multiplica el coste y los usuarios ya
  no lo perciben (su red, su móvil y sus dependencias imponen un techo). Dilo con números en la discusión.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: SLO revisados trimestralmente; política de error budget revisada al menos anualmente o tras
  cualquier incidente en que se ignorase; runbooks revisados cuando el game day demuestre que fallan.
- **Deprecación de alertas y SLO**: se retiran con el servicio; un SLO huérfano genera páginas sin dueño.
- **Documentación viva mínima**: por servicio, SLO + runbook + diagrama de dependencias + ruta de escalado.
  Lo que no se usa durante un incidente, se borra.
- La práctica SRE se **adopta incrementalmente**: empieza por el servicio más crítico con 1 SLO y su política;
  extender a 40 servicios a la vez produce 40 SLO ignorados.

**PROHIBIDO**
- ❌ SLO de 100 %, o SLO sin error budget, o error budget sin política escrita con consecuencia.
- ❌ Fijar el objetivo por deseo o por copiar a otro equipo, en vez de por medición histórica + necesidad de usuario.
- ❌ SLI medido sobre una métrica de máquina cuando existe telemetría del journey de usuario.
- ❌ Percentil como objetivo de SLO (`p99 = X`) en vez de proporción sobre umbral.
- ❌ Paginar sobre causas (CPU, memoria, reinicio de pod) en vez de sobre síntoma de usuario.
- ❌ Alerta sin runbook, sin dueño o sin acción posible; silencios permanentes sin fecha de caducidad.
- ❌ Alertas de SLO con `for`/duración, o de ventana única.
- ❌ Rotación de guardia por debajo de 6 personas sostenida en el tiempo, o guardia sin compensación ni descanso.
- ❌ IC que depura, incidente sin timeline escrito, o incidente coordinado por DM en vez de canal común.
- ❌ Buscar causa raíz antes de mitigar cuando el usuario está afectado.
- ❌ Postmortem con nombres propios como conclusión ("error humano"), o sin acciones con dueño y fecha.
- ❌ Acciones de postmortem en una lista aparte que nadie prioriza.
- ❌ Lanzar a producción sin PRR: sin SLO, sin runbook, sin on-call nombrado o sin rollback probado.
- ❌ Declarar automatizado un proceso cuyo fallo obliga igualmente a intervención manual no documentada.
- ❌ Usar DORA (o el conteo de incidentes) como métrica de rendimiento individual o ranking entre equipos.
- ❌ Congelar cambios indefinidamente como respuesta a un incidente: es lo contrario de la política de budget.
- ❌ Game days y simulacros anunciados como demostración; si no puede fallar, no es un ejercicio.

## 8. Verificación web obligatoria

Antes de fijar cualquier cifra, nombre o referencia de este documento, **búscalo — no lo recuerdes**:

1. **Tabla de burn rates y ventanas** vigente en el SRE Workbook (`sre.google/workbook/alerting-on-slos/`):
   los factores 14.4/6/1 y sus ventanas son el punto de partida publicado, no una constante universal.
2. **Estado de los libros de Google SRE**: verificado ago-2026 — siguen siendo tres (*SRE* 2016, *SRE
   Workbook* 2018, *Building Secure & Reliable Systems* 2020), sin nueva edición anunciada; `sre.google`
   publica actualizaciones por capítulo y material nuevo (p. ej. operación fiable de sistemas de IA).
   Comprobar si ha salido una edición nueva antes de citar.
3. **DORA**: verificado ago-2026 — el informe se renombró a *State of AI-assisted Software Development*
   (edición 2025) y el conjunto oficial pasó de 4 a **5 métricas** (añade *rework rate*); el modelo de
   niveles de rendimiento se sustituyó por arquetipos de equipo. Confirmar en `dora.dev` si ya hay edición
   2026 y si los benchmarks han cambiado antes de usarlos.
4. **Herramientas de SLO as code** que vayas a recomendar (Sloth, OpenSLO, slo-generator, Pyrra…): estado de
   mantenimiento, soporte real de MWMB y compatibilidad con tu stack — varían por versión.
5. **Benchmarks del sector** para el objetivo (disponibilidad típica del tipo de servicio) antes de proponer
   un número al negocio.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
