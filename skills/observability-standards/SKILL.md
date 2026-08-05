---
name: observability-standards
description: Observability standards. Use when working with OpenTelemetry SDKs/Collector configs, Prometheus scrape configs and recording/alerting rules, Alertmanager routing, Grafana dashboards as code, Loki, Tempo, Mimir, Pyroscope, structured logging, trace sampling, metric cardinality, or exporters and PromQL.
---

# Estándares de observabilidad — telemetría, dashboards y alertas

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al instrumentar, desplegar o revisar: OpenTelemetry (SDK, auto-instrumentación,
convenciones semánticas, Collector y diseño de pipeline receivers/processors/exporters),
logging estructurado y correlación, propagación de contexto W3C, estrategia de muestreo,
tipos de métrica, naming, diseño de labels y control de cardinalidad, exemplars, RED/USE,
Prometheus (exporters, scrape, recording rules, retención, remote write), almacenamiento a
largo plazo, Grafana y dashboards como código, backends de logs y trazas, profiling
continuo, Alertmanager y el **coste** de la telemetría.

Triggers: `prometheus.yml`, `rules/*.yml`, `alertmanager.yml`, `otel-collector-config.yaml`,
`config.alloy`, `loki-config.yaml`, `tempo.yaml`, `mimir.yaml`, `grafana.ini`,
`provisioning/`, `dashboard.json`, `OTEL_*` env vars, PromQL/LogQL/TraceQL, `promtool`,
`amtool`, `otelcol`, `weaver`, "cardinalidad", "exemplar", "tail sampling", "trace_id".

**No aplica**: ver `sre-practice-standards` (SLO, error budget, on-call, postmortems: aquí
solo la mecánica de la alerta y su ruteo), `onprem-standards` (node_exporter y
monitorización básica de flota), `kubernetes-standards` (Prometheus Operator,
ServiceMonitor y despliegue del stack en el clúster), `networking-standards` (telemetría de
flujos NetFlow/IPFIX y señales de red), `dataviz` (diseño visual del gráfico: tipo de marca,
color, ejes, leyendas), `aws-standards`/`azure-standards`/`gcp-standards` (CloudWatch,
Azure Monitor, Cloud Monitoring), `detection-engineering-standards` (telemetría de seguridad,
SIEM y reglas de detección; la frontera es el propósito, no la herramienta — el mismo log alimenta
ambas, aquí para diagnosticar, allí para detectar), `incident-management-standards` (declaración
del incidente, mando y comunicación, una vez la alerta ha disparado),
`privacy-engineering-standards` (PII que se cuela en logs, trazas y métricas, y su retención),
`web-performance-standards` (**Ola 6**: **la plataforma de telemetría, el pipeline OTel y las
alertas son de aquí**; **qué métrica de experiencia real de usuario se recoge, en qué percentil se
decide y con qué umbral** es suya — el RUM entra por esta plataforma pero lo interpreta ella),
`performance-engineering-standards` (**Ola 6, en curso**: el perfilado continuo se ingiere y se
almacena aquí; **qué se perfila y cómo se lee un *flame graph*** es suyo).

**Principio rector**: sin telemetría no hay producción, pero **el coste es una restricción
de diseño de primera clase**, no una sorpresa de facturación. La telemetría que nadie
consulta se paga igual que la que salva un incidente: se decide qué se emite **antes** de
emitirlo, y toda señal existe para responder una pregunta concreta.

## 2. Decisiones por defecto

> Versiones verificadas ago-2026. **Verificar la última estable por web antes de fijarla en
> un proyecto real** (§8): este stack publica cada pocas semanas.

| Ámbito | Por defecto | Prohibido / alternativa |
|---|---|---|
| Instrumentación | **OpenTelemetry** (spec 1.59.0): trazas API/SDK/protocolo **estables**, logs estables (Bridge API), métricas API y protocolo estables con **SDK "mixed"**, **profiles en Development** | Depender de *profiles* en producción; instrumentación propietaria del vendor que ate el código al backend |
| Métricas | **Prometheus 3.13 LTS** (3.13.2, jul-2026, EOL jul-2027) | Prometheus 3.5 LTS (**EOL jul-2026**, ya vencida); minor no-LTS en prod si no vas a actualizar cada 6 semanas |
| Recolección/pipeline | **OTel Collector v0.157.0** (`v1.63.0/v0.157.0`) en patrón **agent (DaemonSet) → gateway** | Un único Collector para toda la plataforma; componentes `alpha` en el camino crítico |
| Alternativa de agente | **Grafana Alloy 1.18.0** si ya vives en el ecosistema Grafana | **Promtail: EOL 2-mar-2026** — migración a Alloy obligatoria, no opcional |
| Logs | **Loki 3.7.4** con schema v13 y `structured_metadata` habilitado | Elastic/OpenSearch sin necesidad real de búsqueda full-text (coste y operación muy superiores) |
| Trazas | **Tempo 3.0.2** (TraceQL) | Jaeger **v2.20.0** solo si ya está desplegado; Zipkin en proyectos nuevos |
| Métricas a largo plazo | **Mimir 3.1.4** cuando un Prometheus deje de bastar | Thanos o VictoriaMetrics son alternativas válidas y justificables; **desplegar cualquiera de los tres "por si acaso"** con un solo Prometheus por delante, no (KISS) |
| Dashboards | **Grafana 13.1.x** (13.1.1, jun-2026); 12.4 (EOL may-2027) si necesitas ciclo más largo | Dashboards creados solo por UI y sin versionar |
| Dashboards como código | **Git Sync** (GA abr-2026) + **Grafana Foundation SDK** (Go/TS/Python/Java/PHP) | **Grafonnet: no soportado oficialmente** — no empezar nada nuevo ahí. Perses (CNCF Sandbox) solo si quieres una capa de dashboards pura sin alertas ni almacenamiento |
| Alertas | **Alertmanager 0.33.1** (o Grafana Alerting unificado, uno de los dos, no ambos) | Dos sistemas de alerta en paralelo: nadie sabe cuál despertó a quién |
| Profiling continuo | **Pyroscope 2.2.0** en servicios con problemas de CPU/memoria recurrentes | Profiling continuo en toda la flota "por completitud" (coste sin pregunta que responder) |
| Formato de log | **JSON estructurado** con `trace_id`, `span_id`, `service.name`, nivel y timestamp ISO-8601 UTC | Logs de texto libre parseados con regex en el backend |
| Propagación de contexto | **W3C `traceparent`/`tracestate`** en HTTP, gRPC y cabeceras de mensajes | Cabeceras propietarias (B3, X-Request-ID sueltos) sin puente a W3C |

## 3. Estructura y convenciones

**Correlación: la propiedad que hace útil al conjunto**
- Los tres pilares valen por su **correlación**, no por existir: `trace_id` en todos los
  logs, **exemplars** en histogramas para saltar de la métrica a la traza, enlace de traza
  a logs y a perfil. Una traza que no se puede alcanzar desde el gráfico donde ves el
  problema no se usará nunca.
- Exemplars: habilitar `storage.exemplars.max_exemplars` (Prometheus/Mimir) y el enlace
  interno al datasource de trazas en Grafana. Los histogramas nativos mapean sin pérdida a
  los *exponential histograms* de OTLP y conservan exemplars.

**Convenciones semánticas y naming**
- Usa las **semantic conventions de OpenTelemetry**; no inventes atributos que ya existen.
  Si necesitas atributos propios, decláralos en un registry con **Weaver** y valida en CI
  (`weaver check`): la telemetría es una API pública, con versión y política de cambios.
- Dos convenciones de naming coexisten y **hay que elegir una por plataforma y escribirla**:
  Prometheus (unidades base, sufijos `_total`, `_seconds`) frente a OTel (puntos y unidades
  UCUM). La traducción OTLP→Prometheus se controla con `translation_strategy`, cuyo valor
  por defecto es `UnderscoreEscapingWithSuffixes`; `NoTranslation` exige UTF-8 habilitado, y
  **cualquier estrategia sin sufijos permite colisiones** entre métricas del mismo nombre
  con distinto tipo o unidad.
- Métrica sin unidad en el nombre, o con unidad distinta de la base, es un bug de contrato.

**Diseño de labels y control de cardinalidad** (la decisión con más impacto en la factura)
- **Nunca** como label/atributo de métrica: `user_id`, `request_id`, `trace_id`, email, URL
  con parámetros de ruta, nombre de pod con hash, IP, timestamp. Son dimensiones ilimitadas.
- Regla: un label debe tener valores **acotados y conocidos de antemano**, y alguien debe
  agrupar o filtrar por él en un dashboard o alerta real. Si no, no es un label.
- Coste: cada serie activa ocupa del orden de **1-8 KiB** en el *head block* (las
  estimaciones varían mucho por fuente; mide, no supongas) y el RSS real puede duplicar el
  cálculo. Vigila `prometheus_tsdb_head_series` y planifica antes de la presión de memoria.
- Diagnóstico: `/api/v1/status/tsdb?limit=50`, `promtool tsdb analyze /prometheus`,
  `topk(10, count by (__name__)({__name__=~".+"}))` y churn con
  `topk(20, increase(scrape_series_added[1h]))`. Comprueba también el doble scrape (mismo
  target vía servicio y vía pods): duplica series sin aportar nada.
- Contención: `sample_limit` por scrape, `metric_relabel_configs` para tirar lo que no se
  usa. Ojo: el drop ocurre **antes** del almacenamiento y es irreversible — confirma que
  nadie lo usa en dashboards ni alertas antes de aplicarlo.
- **Loki tiene la misma disciplina con otro nombre**: pocos labels estáticos (límite por
  defecto 15) y todo lo de alta cardinalidad pero buscable a **structured metadata**
  (requiere `allow_structured_metadata: true` y schema ≥ v13).

**Qué medir: RED y USE, no "todo"**
- **RED** para servicios y peticiones: *Rate*, *Errors*, *Duration*.
- **USE** para recursos (CPU, memoria, disco, colas, pools): *Utilization*, *Saturation*,
  *Errors*.
- En sistemas de mensajería, el **lag del consumidor** y la profundidad de la DLQ son SLI de
  primera clase, no métricas secundarias.

**Pipeline del Collector — el orden de los processors no es cosmético**
```yaml
processors:
  memory_limiter:            # SIEMPRE el primero: aplica backpressure antes del OOM
    check_interval: 1s
    limit_mib: 1600          # ~70-80% de la memoria del contenedor; GOMEMLIMIT al 80% de esto
    spike_limit_mib: 320     # ~20% del límite duro
  k8sattributes: {}          # enriquecer antes de filtrar, si el filtro usa esos atributos
  filter: {}                 # tirar ruido...
  tail_sampling: {}          # ...y muestrear ANTES de batchear
  batch:                     # último: no batchees lo que vas a descartar
    timeout: 5s
    send_batch_size: 8192
```
- El límite de memoria del contenedor debe ser **mayor** que el del `memory_limiter`, o el
  orquestador matará el proceso antes de que pueda aplicar backpressure.
- `sending_queue` grande + batches grandes pueden superar el techo bajo un pico: se
  dimensionan juntos.

## 4. Gates de calidad obligatorios

- **Validación en CI**: `promtool check config`, `promtool check rules`, `amtool check-config`,
  validación del YAML del Collector y `weaver check` del registry de convenciones propio.
- **Unit tests de reglas de alerta** (`promtool test rules`): toda alerta nueva llega con un
  test que demuestra que dispara con la serie que debe dispararla y **no** con la que no.
- **Toda alerta lleva `runbook_url`, dueño y severidad**; sin runbook no se mergea.
- **Revisión de instrumentación en PR**: nombre, unidad, tipo y **labels acotados**. Un
  label nuevo de cardinalidad desconocida es un bloqueo, no un comentario.
- **Gate de cardinalidad** antes de producción: medir series añadidas por el cambio en
  staging y rechazar lo que crezca sin explicación.
- **Dashboards y alertas versionados** (Git Sync + Foundation SDK) y desplegados por
  pipeline; lo creado a mano en la UI se pierde o diverge.
- **Prueba de propagación extremo a extremo** en el test de integración: una petición genera
  una traza completa, con `trace_id` presente en los logs de todos los saltos. Si se rompe
  en el primer salto, la observabilidad distribuida no existe.

## 5. Seguridad y privacidad

- **Sin PII en telemetría**: ni en labels, ni en atributos de span, ni en mensajes de log.
  La redacción se hace **en el borde** (processor `transform`/`filter` del agente), no
  confiando en que el backend lo oculte al pintar.
- Riesgos habituales que se cuelan solos: URLs con tokens en query string, cabeceras
  `Authorization`, cuerpos de petición y respuesta, mensajes de error con datos de negocio,
  y stack traces con rutas y credenciales internas.
- **Cardinalidad como vector de DoS**: si un label toma su valor de una entrada del usuario
  (path, user-agent, parámetro), un atacante puede tumbar el TSDB. Acota en el código, no
  en el backend.
- OTLP siempre con **TLS y autenticación**; el endpoint del Collector es un punto de entrada
  a la red interna, no un buzón abierto. Mínimo privilegio en los exportadores y credenciales
  desde gestor de secretos, jamás en el YAML del repo.
- **Retención por finalidad y minimización** (GDPR): la telemetría operativa no es un
  almacén de datos personales. Define retención corta por defecto y justifica cada excepción.
- Grafana: RBAC por equipo, acceso anónimo desactivado, credenciales de datasource
  provisionadas por secreto (nunca embebidas en JSON de dashboard exportado).
- Los **logs de auditoría/seguridad se separan** de la telemetría operativa: integridad,
  retención y control de acceso distintos (y su destino natural es el SIEM, no Loki).

## 6. Rendimiento, coste y operabilidad

**El coste manda en el diseño**
- Primero entiende **qué unidad te cobran**, porque define qué optimizar: hosts + métricas
  custom + GB/eventos indexados (Datadog), **series activas** + GB de logs/trazas (Grafana
  Cloud), eventos (Honeycomb), GB ingeridos + usuarios (New Relic). Autohospedado también se
  paga: RAM del head block, disco y almacenamiento de objetos.
- Palancas, **en este orden** (de más a menos efectiva):
  1. **No generar** lo que nadie consulta (la reducción más barata siempre).
  2. **Agregar antes de ingerir**: stream aggregation (VictoriaMetrics), Adaptive Metrics
     (Grafana Cloud), agregación en el Collector. Reducciones típicas del 20-50%.
  3. **Drop en el scrape** por `metric_relabel_configs`.
  4. **Recording rules** para consultas caras — pero ojo: se calculan sobre datos ya
     almacenados, así que **pagas la cardinalidad primero**; no son reducción de ingesta.
  5. **Retención escalonada** a object storage.
  6. **Muestreo** de trazas.
- Antes de agregar o tirar algo, comprueba su uso real (dashboards, alertas, queries). Y
  asume el precio: agregado es irreversible hacia atrás.

**Muestreo de trazas**
- **Head sampling** (`parentbased_traceidratio`): barato, decidido al inicio, escala trivial
  — pero no puede quedarse con el error raro porque aún no ha ocurrido.
- **Tail sampling**: decide con la traza completa (quédate errores y colas de latencia),
  pero exige que **todos los spans de una traza lleguen al mismo Collector**: capa de
  balanceo con `load_balancing` exporter, `routing_key: traceID`, backends estables
  (StatefulSet + headless service) y una segunda capa que muestrea. Misma restricción para
  `spanmetrics` y `servicegraph`.
- **Sesgo, el error que se paga tarde**: si solo guardas errores y peticiones lentas, todo
  lo derivado de trazas (percentiles, conteos) miente. Genera las métricas antes de
  muestrear, no después.
- En volumen extremo, combina: head sampling ligero en el borde para proteger el pipeline y
  tail sampling después. Usa *consistent probability sampling* (claves `th`/`rv` en el
  `tracestate` de OTel) para que la decisión sea coherente entre servicios y re-ponderable.

**Alertas que no queman a nadie**
- Alerta sobre **síntomas** (golden signals y SLO), no sobre causas internas. Cada alerta
  responde a: ¿hay impacto en el usuario y hay algo que hacer **ahora**? Si no, no es página.
- **Multi-window multi-burn-rate** sobre el error budget (SRE Workbook, cap. 5): ventana
  corta y larga que deben cumplirse a la vez, con varios niveles (p. ej. 14,4× en 1h+5m para
  el 2% del presupuesto de 30 días, y niveles más lentos para el desgaste sostenido). La
  ventana larga es lo que evita despertar a alguien por un pico de 5 minutos ya resuelto.
- Limitación conocida: con **poco tráfico** el burn rate pierde señal (pocas muestras en la
  ventana). Mitiga agrupando servicios, con tráfico sintético o relajando el SLO — no
  fingiendo que la alerta funciona.
- Alertmanager: árbol de rutas por equipo/severidad, `group_by` con las etiquetas que
  definen *un* incidente (no `...`), `inhibit_rules` para que la causa raíz silencie a los
  derivados, `mute_time_intervals` para ventanas conocidas, y **silencios siempre con
  caducidad**.
- **Higiene**: alerta que se ignora sistemáticamente o que no tiene acción posible **se
  borra**. Revisión periódica de alertas disparadas vs. acciones tomadas.

**Dashboards por audiencia** (el diseño visual es de `dataviz`; aquí, el contenido)
- Uno **de servicio** en una pantalla con RED y estado del SLO; uno **de recursos** con USE;
  uno **de negocio** si hay quien lo mire. Nada de muros de 60 paneles que nadie lee en un
  incidente. Cada panel responde a una pregunta y su ausencia se nota.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: seguir la línea **LTS** de Prometheus (3.13 hasta jul-2027); Grafana con
  major cada ~6 meses leyendo breaking changes; el Collector publica muy rápido — **fija la
  versión por tag/digest** y actualiza de forma planificada.
- **Migraciones vivas que no admiten aplazamiento**: Promtail EOL (mar-2026) → Alloy;
  schema de Loki a v13 para structured metadata; plugins Angular retirados en Grafana.
- La telemetría se **retira** como se añade: una métrica, dashboard o alerta que deja de
  usarse se elimina con la misma PR que la deja huérfana.

**PROHIBIDO**
- ❌ Labels o atributos de métrica de cardinalidad ilimitada (`user_id`, `request_id`,
  `trace_id`, IP, URL con parámetros, nombre de pod con hash).
- ❌ Emitir telemetría "por si acaso" sin pregunta que responda ni presupuesto asignado.
- ❌ Logs de texto libre sin estructura, o logs sin `trace_id` en un sistema distribuido.
- ❌ Alerta sin runbook, sin dueño o que no requiere acción humana inmediata.
- ❌ Silencios permanentes o sin caducidad; alertas ruidosas mantenidas "por si acaso".
- ❌ Alertar sobre causas (CPU al 90%) en lugar de síntomas con impacto (SLO quemándose).
- ❌ Tail sampling sin capa de balanceo por `traceID`: produce trazas fragmentadas y
  decisiones incorrectas en silencio.
- ❌ Derivar métricas (percentiles, conteos) **después** de muestrear y presentarlas como
  exactas.
- ❌ `memory_limiter` que no sea el primer processor, o `batch` antes del filtrado/muestreo.
- ❌ Dashboards y alertas que solo existen en la UI, sin versionar ni provisionar.
- ❌ PII, secretos o cabeceras de autorización en logs, spans o labels.
- ❌ Exponer OTLP sin TLS ni autenticación.
- ❌ Empezar dashboards nuevos en Grafonnet (sin soporte oficial) o seguir con Promtail (EOL).
- ❌ Desplegar Thanos/Mimir/VictoriaMetrics antes de que un Prometheus se quede corto.
- ❌ Ejecutar versiones EOL del stack (Prometheus 3.5 LTS venció en jul-2026) sin plan fechado.
- ❌ Dos sistemas de alerta en paralelo (Alertmanager + Grafana Alerting) sobre las mismas reglas.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión o estado de feature, **búscalo — no lo recuerdes**.
Verificado ago-2026 (caduca rápido): Prometheus **3.13.2 LTS** (jul-2026, EOL jul-2027) y
3.5 LTS **ya EOL**; Grafana **13.1.1** (13.0.4, y 12.4.x con EOL may-2027); OTel spec
**1.59.0**; OTel Collector **v1.63.0/v0.157.0**; Grafana Alloy **1.18.0**; Loki **3.7.4**;
Tempo **3.0.2**; Mimir **3.1.4**; Pyroscope **2.2.0**; Alertmanager **0.33.1**;
Jaeger **v2.20.0**; Git Sync GA desde abr-2026; Promtail EOL 2-mar-2026.

1. **Estado por señal de OpenTelemetry** en `opentelemetry.io/docs/specs/status/`: trazas
   estables, logs estables (Bridge API), métricas con SDK "mixed", **profiles en
   Development**. No prometas lo que aún no es estable.
2. **Estabilidad del componente concreto** del Collector que vayas a usar (el core es
   "mixed"): está en el README de cada componente, no en la versión del binario.
3. **Última LTS y EOL** de Prometheus y Grafana (endoflife.date) antes de fijar versión.
4. Estado de features que cambian de sitio: native histograms, remote write 2.0, receptor
   OTLP y UTF-8 en Prometheus; bloom filters y schema en Loki; TraceQL en Tempo.
5. Versiones y estado de VictoriaMetrics, Thanos, Parca, OBI/Beyla y el operador de
   OpenTelemetry — **no verificados en este documento**.
6. **Modelo y unidad de cobro vigentes** del backend gestionado antes de comprometer un
   diseño: la unidad facturable cambia lo que hay que optimizar, y los precios rotan.
7. Convenciones semánticas: qué grupos están ya estables para tu dominio (HTTP, base de
   datos, mensajería, gen-ai) antes de inventar atributos propios.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
