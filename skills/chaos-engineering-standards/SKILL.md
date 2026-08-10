---
name: chaos-engineering-standards
description: Deliberate fault injection as an engineering discipline. Use when designing or reviewing chaos experiments with a steady-state hypothesis, blast radius and abort conditions, running game days, injecting faults with Chaos Mesh (PodChaos, NetworkChaos, IOChaos CRDs), LitmusChaos (ChaosEngine, ChaosHub, chaosctl), Gremlin, AWS Fault Injection Service (FIS experiment templates, aws fis start-experiment, AZ availability scenarios), Azure Chaos Studio (experiments.json, chaos targets and capabilities), Toxiproxy toxics (latency, bandwidth, timeout, slicer) in integration tests, Netflix chaosmonkey/SimianArmy, or deciding whether to experiment in production versus staging.
---

# Estándares de ingeniería del caos

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **experimento deliberado de resiliencia**: formular la hipótesis de estado estable,
elegir e inyectar el fallo (proceso, red, recurso, dependencia, zona, región), acotar el *blast
radius*, definir condiciones de aborto, ejecutar *game days* y convertir lo aprendido en
arreglos con dueño. Cubre la elección de herramienta de inyección y el criterio de
producción vs staging.

**Tesis**: un experimento de caos **no es romper cosas**: es un experimento controlado con
hipótesis falsable ("si cae X, el usuario no lo nota porque Y"), medición del estado estable
antes/durante/después, y parada automática. Si no hay hipótesis escrita ni condición de aborto,
no es ingeniería del caos: es vandalismo con presupuesto.

Triggers: "experimento de caos", "game day", hipótesis de estado estable, *blast radius*,
`PodChaos`/`NetworkChaos`/`StressChaos`/`IOChaos` (Chaos Mesh), `ChaosEngine`/`ChaosResult`/
ChaosHub (Litmus), plantillas de experimento de AWS FIS y `aws fis`, Azure Chaos Studio,
Gremlin, Toxiproxy y sus *toxics*, "¿qué pasa si se cae la AZ?", "matar pods aleatoriamente".

**No aplica**: ver `ot-ics-security-standards` y `safety-critical-standards` (**el límite duro de
esta skill, §7**: donde el fallo llega a un proceso físico o a una función de seguridad, no se
inyecta nada — se prueba en banco o gemelo y manda su criterio, con *Safety* por delante de la
disponibilidad), `gaming-infrastructure-standards` (**carga con estado no interrumpible**: el
experimento se acota a los servidores libres y a la ruta de reposición, nunca a los `Allocated`),
`sre-practice-standards` (**los SLO, el error budget y los game days como
práctica de fiabilidad son suyos**; aquí el diseño y la mecánica del experimento que el game day
ejecuta — el SLI del servicio es precisamente la métrica de estado estable de aquí),
`testing-qa-standards` (el testing determinista de bordes y errores en CI es suyo; Toxiproxy en
un test de integración vive en la frontera: el *toxic* se configura con criterio de aquí, el
test y sus gates son suyos), `incident-management-standards` (el incidente real y su proceso;
si un experimento se convierte en incidente, se aborta y manda aquella),
`incident-response-forensics-standards` (incidente de seguridad), `bcdr-standards` (**el drill
de DR completo —failover de sitio, RTO/RPO— es suyo**; el experimento de resiliencia continuo y
acotado es de aquí), `kubernetes-standards` (la plataforma donde corren los CRDs; RBAC y
admission del clúster), `performance-engineering-standards` (load testing y perfilado: inyectar
carga para medir capacidad no es caos; combinar carga + fallo sí lo es, y la parte de carga es
suya), `observability-standards` (la instrumentación con la que se observa el experimento).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión y el estado de mantenimiento por web antes de fijarla en un
> proyecto real (§8). Estado verificado a ago-2026:

| Decisión | Por defecto | Alternativa justificable | Motivo |
|---|---|---|---|
| Caos en Kubernetes | **LitmusChaos** (CNCF incubating, cadencia mensual de releases en 2026) o **Chaos Mesh** (CNCF incubating; v2.7.x, cadencia ~semestral "por falta de mantenedores" según su propia guía de release) | — | Ambos vivos; Litmus con más momento comunitario en 2026, Chaos Mesh más simple de operar y el que integra Azure Chaos Studio para AKS |
| Caos en AWS gestionado | **AWS Fault Injection Service (FIS)** | Gremlin | Escenarios prefabricados de AZ/región (incl. "gray failures": *AZ Application Slowdown*, *Cross-AZ Traffic Slowdown*, nov-2025), integración con Resilience Hub (ago-2026) y *safety controls* nativos |
| Caos en Azure | **Azure Chaos Studio** | Chaos Mesh directo en AKS | Servicio gestionado; *Workspaces/Scenarios* en public preview (jul-2026, GA prevista finales de 2026 — verificar) |
| Plataforma comercial multi-nube | **Gremlin** (activo e independiente a ago-2026; lanzó "Reliability Intelligence" en 2025) | Harness Chaos Engineering (basado en Litmus) | Soporte, agentes fuera de Kubernetes, biblioteca de escenarios |
| Fallo de red en tests de integración | **Toxiproxy** (Shopify; v2.12.0, mar-2025, MIT, repo activo) | tc/netem a mano | Determinista, scriptable, corre en CI |
| Terminación aleatoria de instancias | **No usar Netflix chaosmonkey**: SimianArmy archivado (2021) y `Netflix/chaosmonkey` sin push desde ene-2025 y acoplado a Spinnaker — de facto sin mantenimiento | La acción equivalente de FIS/Litmus/Gremlin | "Chaos Monkey" es hoy un concepto, no una herramienta recomendable |
| Primer experimento | **Staging, un solo objetivo, en horario laboral, con el equipo mirando** | — | Se gana confianza antes de ampliar radio |
| Producción | **Sí, como meta explícita del programa** — staging no tiene el tráfico, los datos ni la topología reales | Nunca, si el servicio no tiene SLO ni observabilidad | Un sistema solo demuestra resiliencia donde importa; pero producción exige los prerrequisitos de §3 |

## 3. Estructura y convenciones

Todo experimento se escribe **antes** de ejecutarse, versionado en el repo, con este contrato:

```
Hipótesis:        estado estable (SLI + umbral) que NO debe romperse
Fallo inyectado:  qué, dónde, magnitud, duración
Blast radius:     alcance máximo (n pods / 1 AZ / x% del tráfico) — empezar mínimo
Abort conditions: umbrales medibles que detienen el experimento AUTOMÁTICAMENTE
Rollback:         cómo se revierte la inyección y quién verifica que se revirtió
Resultado:        hipótesis confirmada / refutada + acciones con dueño y fecha
```

- **Prerrequisitos duros para producción**: SLO definido y medido, alerta de burn rate
  funcionando, observabilidad del camino afectado, mecanismo de aborto probado, aviso previo a
  on-call y a los equipos dependientes, y ventana acordada (nunca durante un incidente activo,
  una campaña o un freeze).
- **Radio incremental**: instancia → grupo → AZ → región; staging → canario → producción. No se
  salta un escalón porque el anterior "obviamente pasaría".
- **Game day**: ejercicio programado donde el equipo ejecuta 1-3 experimentos con roles (quien
  inyecta, quien observa, quien puede abortar) y acta de resultados. Es la vía de entrada de la
  práctica; su encaje en el programa de fiabilidad → `sre-practice-standards`.
- **El experimento más rentable suele ser el más aburrido**: matar la caché (¿sobrevive el
  origen?), degradar una dependencia con latencia (¿saltan los timeouts y el circuit breaker?),
  perder un pod (¿el usuario lo nota?). Antes que simular la caída de una región, verificar que
  los timeouts, reintentos y *health checks* hacen lo que dicen.

## 4. Calidad y testing

Se omite como sección propia: el experimento **es** el test. Dos reglas: los resultados
(ChaosResult, informe de FIS, acta de game day) se archivan versionados junto a la hipótesis; y
un experimento que refuta la hipótesis genera acciones rastreadas — repetir el experimento tras
el arreglo es el test de regresión de resiliencia. Los experimentos automatizables (Toxiproxy en
integración, Litmus en pipeline) entran en CI solo cuando ya pasaron ejecución supervisada.

## 5. Seguridad del stack

- Las herramientas de caos son **capacidad de destrucción con credenciales**: un agente que mata
  pods, corta red o para instancias es exactamente lo que un atacante quiere. Mínimo privilegio
  estricto (RBAC por namespace en Chaos Mesh/Litmus, rol IAM por plantilla en FIS con
  `Condition` sobre tags de objetivo), sin comodines en los selectores de objetivo, y su plano
  de control **nunca expuesto** (los dashboards de Chaos Mesh/Litmus sin autenticación han sido
  hallazgo recurrente de pentest).
- Auditoría: toda ejecución queda registrada (quién, qué, cuándo, sobre qué) — es también lo que
  distingue un experimento de un incidente en el postmortem.
- Vigilar CVEs de la propia plataforma de caos (Litmus parcheó CVE-2026-33186 en 2026): corre
  con privilegios altos, su ventana de parcheo es corta.
- Experimentos sobre sistemas con datos personales o regulados: el fallo inyectado no debe
  provocar pérdida o exposición de datos reales; si el experimento puede degradar un control de
  seguridad (p. ej. tirar el servicio de authz), se trata como cambio sensible con aprobación.

## 6. Rendimiento y operabilidad

Se omite como sección propia (una línea): la operabilidad del experimento ya está en §3
(observabilidad como prerrequisito, aborto automático, rollback verificado); la del servicio
objetivo pertenece a `sre-practice-standards` y `observability-standards`.

## 7. Cuándo NO / Prohibiciones

**Cuándo NO practicar caos**: sin SLO ni observabilidad (primero eso — no puedes refutar una
hipótesis que no puedes medir); durante un incidente, freeze o pico de negocio; sobre un sistema
que ya se sabe frágil (arregla lo conocido antes de buscar lo desconocido); en producción sin
haber pasado por staging y sin mecanismo de aborto probado.

**Límite duro: si el fallo puede herir a alguien, aquí no se inyecta.** Sistemas de control
industrial y proceso físico (OT/ICS, PLC, DCS y sobre todo **SIS**), dispositivo médico,
automoción, ferroviario, aviación y cualquier función de seguridad certificada quedan **fuera de
esta skill sin excepción**: su orden de prioridades es *Safety → Disponibilidad → Integridad →
Confidencialidad* y no admite el trueque que el caos da por bueno. El equivalente legítimo allí
es la prueba en **banco o gemelo**, con el criterio de `ot-ics-security-standards` y
`safety-critical-standards`, nunca sobre la planta. La regla en una frase: **el blast radius se
mide en peticiones, no en personas**; si se mide en personas, no es un experimento, es un riesgo.

- ❌ Experimento **sin hipótesis escrita, sin blast radius acotado o sin condición de aborto
  automática**. "A ver qué pasa" no es un experimento.
- ❌ Aleatoriedad no anunciada en producción estilo Chaos Monkey clásico **como primera
  iniciativa** del programa: la aleatoriedad continua es la graduación, no el inicio.
- ❌ Caos en producción **sorpresa para el on-call** o sin registro auditable. Un experimento no
  anunciado es indistinguible de un ataque.
- ❌ Herramienta de caos con permisos de clúster/cuenta amplios o selectores comodín
  (`namespace: *`). El blast radius se acota también en el IAM/RBAC, no solo en el YAML.
- ❌ Recomendar `Netflix/chaosmonkey` o SimianArmy en un diseño nuevo (§2: sin mantenimiento).
- ❌ Vender un load test como experimento de caos, o un experimento de caos como sustituto del
  drill de DR (`bcdr-standards`) o del test determinista (`testing-qa-standards`).
- ❌ Ejecutar y no cerrar: un experimento que refuta la hipótesis y no genera acción con dueño
  es coste sin retorno; uno que la confirma y no se re-ejecuta periódicamente caduca.
- ❌ Usar técnicas de inyección de fallo contra sistemas ajenos o sin autorización: esto es
  disciplina defensiva sobre sistemas propios, con permiso y registro.
- ❌ Inyectar fallos sobre **carga con estado, de vida corta y no interrumpible** como si fuera
  un microservicio sin estado. El caso canónico es el servidor de partida
  (`gaming-infrastructure-standards`): matar un pod `Allocated` no refuta ninguna hipótesis —
  destruye la sesión de gente real y el SLI que se venía a proteger. El experimento se acota a
  los recursos **libres** y a la ruta de reposición, no a los ocupados.

## 8. Verificación web obligatoria

1. **Chaos Mesh**: versión y ramas soportadas en `chaos-mesh.org/supported-releases/` y
   `api.github.com/repos/chaos-mesh/chaos-mesh/releases` (a ago-2026: 2.7.x documentada, 2.8 en
   preparación); confirmar que sigue CNCF incubating y su cadencia real de releases.
2. **LitmusChaos**: releases en `api.github.com/repos/litmuschaos/litmus/releases` y los
   updates trimestrales en el blog de CNCF (último verificado: Q1-Q2 2026, ago-2026).
3. **AWS FIS**: catálogo vigente de acciones y escenarios en la FIS Actions reference de
   `docs.aws.amazon.com` (los escenarios de fallo parcial son de nov-2025; la integración con
   Resilience Hub, de ago-2026) y precios.
4. **Azure Chaos Studio**: estado de *Workspaces/Scenarios* (a ago-2026 **public preview**, GA
   "prevista finales de 2026" — es dato en movimiento), regiones y faults soportados en
   `learn.microsoft.com`.
5. **Toxiproxy**: última release en `api.github.com/repos/Shopify/toxiproxy/releases/latest`
   (v2.12.0, 2025-03-18) y actividad del repo.
6. **chaosmonkey**: estado del repo en `api.github.com/repos/Netflix/chaosmonkey` (verificado
   ago-2026: `archived: false` pero último push 2025-01-06 — confirmar antes de citarlo).
7. **CVEs** de la plataforma de caos elegida (avisos del proyecto/CNCF).
8. **Huecos declarados** (no verificados — no rellenar de memoria): precios y tiers de Gremlin;
   versión exacta y licencia de Harness Chaos Engineering; fecha exacta de GA de Azure Chaos
   Studio Workspaces; versión mínima de Litmus que corrige CVE-2026-33186 (visto en resumen del
   blog CNCF, no en el aviso del proyecto).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
