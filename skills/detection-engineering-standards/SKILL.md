---
name: detection-engineering-standards
description: Security detection engineering — building and governing SIEM detections as code. Use when writing or tuning Sigma rules (sigma-cli, pySigma, sigma correlations), YARA or YARA-X rules, Elastic detection-rules TOML, KQL, SPL, EQL or YARA-L analytics, Suricata and Zeek signatures, Wazuh decoders and rules, ATT&CK Navigator coverage layers, DeTT&CT, Chainsaw or Hayabusa triage, alert runbooks and false-positive rates, detection unit tests in CI, OCSF or ECS log normalization, or onboarding a new log source into a SIEM.
---

# Estándares de ingeniería de detección

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, escribir, probar, desplegar, medir y **retirar** contenido de detección:
backlog e hipótesis de detección, modelo de datos y onboarding de fuentes, normalización de
esquema (OCSF, ECS), autoría de reglas en cualquier formato (Sigma, YARA/YARA-X, KQL, SPL,
EQL, YARA-L, Suricata, Zeek, Wazuh, Falco), pipeline de detección como código (repo, CI,
tests, despliegue, versionado), mapa de cobertura frente a MITRE ATT&CK, enriquecimiento y
deduplicación, umbrales y severidad, gestión del falso positivo, runbook por alerta,
validación adversaria de la detección, uso de threat intelligence, y las métricas del
programa (MTTD, cobertura por fuente, FP por regla, alertas por analista y hora).

Triggers: `*.yml` de Sigma con `detection:`/`logsource:`, `sigma-cli`/`sigmac`, `pySigma`,
`*.yar`/`*.yara`, `yr` (YARA-X), `rules/**/*.toml` de `elastic/detection-rules`,
`detection_rules test`, `contentctl`/`contentctl-ng`, `panther_analysis_tool`, `suricata.yaml`
y `*.rules`, scripts `*.zeek`, `local_rules.xml`/`decoders` de Wazuh, `falco_rules.local.yaml`,
capas `.json` de ATT&CK Navigator, `chainsaw`, `hayabusa`, `atomic-red-team`, "regla de
detección", "caso de uso de SIEM", "falso positivo", "tuning", "cobertura ATT&CK", "MTTD".

**Principio rector**: la detección es un **producto de ingeniería con ciclo de vida**, no un
catálogo de alertas compradas. Se rige por tres invariantes: **(1) sin la fuente correcta no
hay detección** — el modelo de datos precede a la regla; **(2) toda regla se prueba con el
ataque real que dice detectar** antes de creerle; **(3) una alerta sin acción posible no es
una alerta, es ruido con dueño**. Corolario incómodo: **cobertura ≠ detección**. "Cubrimos
300 técnicas" casi siempre significa "tenemos 300 reglas que nadie ha ejecutado contra un
ataque".

**No aplica**: ver `observability-standards` (telemetría para **diagnosticar**: OpenTelemetry,
Prometheus, Loki, cardinalidad, coste, Alertmanager — **la frontera es el propósito, no la
herramienta**: el mismo log alimenta ambas, allí para explicar una caída, aquí para descubrir
a un adversario; el pipeline, la retención y la integridad de la telemetría son suyos, el
contenido analítico es mío), `sre-practice-standards` (on-call, SLO, error budget, burn rate,
postmortems), `incident-management-standards` (**gobierno del incidente que mi alerta
dispara**: declaración, severidad, IC, comunicación — mi entregable termina exactamente en el
handoff, y su retro me devuelve trabajo), `incident-response-forensics-standards` (**respuesta
técnica e investigación**: contención, imaging, timeline, erradicación — frontera
**bidireccional**: allí se investiga lo que yo detecto, y **toda investigación debe volver
convertida en regla nueva**; el uso de YARA para *hunting* forense y triaje de evidencia es
suyo, la **autoría y gobierno de la regla** es mía), `offensive-security-standards` (purple
team, emulación de adversario, Atomic Red Team y Caldera como **generadores** del ataque
autorizado y su deconfliction con el SOC — **ellos generan la actividad, yo escribo y valido
la detección**), `container-runtime-security-standards` (**qué señal de runtime importa** —
shell inesperada, escritura en binarios, socket del runtime, drift— y el despliegue del
agente eBPF: **la regla Falco nace allí y se gobierna aquí**, con mi ciclo de vida, mis tests
y mi cobertura), `linux-hardening-standards` y `selinux-standards` (baseline CIS, `auditd` y
AVC de SELinux **como fuente**: la configuración del ruleset de auditoría es suya, convertir
esos eventos en detección es mío), `windows-server-ad-standards` (qué evento de AD importa y
por qué), `networking-standards` (segmentación, NetFlow/IPFIX y la red que Suricata/Zeek
observan), `appsec-standards` (**A09 Security Logging and Alerting Failures**: qué eventos
debe **emitir** la aplicación — authn, authz denegada, cambio de privilegios; yo consumo esa
emisión, no la diseño), `vulnerability-management-standards` (CVE, CVSS/EPSS/KEV y SLA de
parcheo), `privacy-engineering-standards` (PII dentro de los logs de seguridad, minimización
y límites de retención por finalidad), `secrets-management-standards` (custodia y rotación de
secretos — **frontera compartida**: un secreto filtrado o un secreto usado desde un origen
anómalo es un **caso de detección mío**, alimentado por su telemetría de gestor y de
escaneo), `grc-compliance-standards` (el control normativo que exige monitorización y su
evidencia), `identity-access-management-standards` (diseño del IdP, políticas de acceso
condicional y flujos OAuth — yo detecto su abuso, no los configuro),
`threat-intelligence-standards` (**frontera bidireccional**: la hipótesis, el indicador y su
caducidad son suyos, la regla es mía — y **el retorno de *sightings* es suyo**: un indicador que
caduca por falta de avistamientos se retira allí, con su criterio, no aquí).

## 2. Decisiones por defecto

> Datos verificados ago-2026. **Verificar la última versión, licencia y estado por web antes
> de fijarlo en un proyecto real (§8)**: este ecosistema rota en meses y varios proyectos
> cambiaron de gobernanza en 2025-2026.

| Ámbito | Por defecto | Alternativa justificable / vetado |
|---|---|---|
| Formato de autoría portable | **Sigma** — spec **v2.1.0** (sep-2025, formaliza *correlations* y *meta-rules*), `pySigma` **1.5.0**, `sigma-cli` **3.1.0**, reglas `SigmaHQ/sigma` **r2026-07-01** | Escribir directamente en el lenguaje del SIEM **solo** cuando la traducción pierde semántica (§3). **Mínimo duro: pySigma ≥ 1.3.0** — las versiones anteriores ejecutaban código vía *template vars* (hoy tras `--enable-template-vars` y Jinja2 sandboxed) |
| Ficheros y memoria | **YARA-X 1.19.0** | YARA clásico **4.5.8** solo por compatibilidad de motor de terceros: VirusTotal lo declaró en **maintenance mode** al publicar YARA-X 1.0.0 (jun-2025) y los módulos nuevos (`macho`, `lnk`) solo llegan a YARA-X. Migrar validando el ruleset (≈99 % compatible a nivel de regla) |
| Marco de referencia de amenaza | **MITRE ATT&CK v19.1** (abr-2026) + **Navigator 5.3.2** | Ninguna. Es la lengua franca. Ojo a dos rupturas: **v18.0** sustituyó las *Detections* por **Detection Strategies (`DETxxxx`) + Analytics (`ANxxxx`)** y deprecó las *Data Sources* legacy; **v19** partió **Defense Evasion** en **Stealth (TA0005)** y **Defense Impairment (TA0112)** — usa el *crosswalk* oficial, no renumeres a mano |
| Medición de cobertura | **DeTT&CT 2.2.0** sobre capas de Navigator, puntuando **calidad de la fuente de datos**, no solo presencia de regla | Hoja de cálculo propia (se desincroniza sola). **Vetado**: presentar "técnicas con regla" como cobertura sin puntuar visibilidad |
| Validación adversaria | **Atomic Red Team** (MIT, modelo *rolling* sin tags) para pruebas atómicas por técnica | **Apache Caldera** para cadenas y emulación de campaña — **cambió de gobernanza: MITRE lo contribuyó al Apache Incubator el 20-may-2026**, repo canónico `apache/caldera`. **Mínimo duro ≥ 5.1.0** por **CVE-2025-27364** (CVSS 10.0, RCE preauth en compilación de agentes) |
| Esquema de normalización | **El del motor que consumes**, declarado explícitamente: **ECS 9.4.0** en el mundo Elastic/Sigma; **OCSF 1.8.0** (Linux Foundation desde nov-2024) en lago de datos e interoperabilidad multi-vendor | **No hay ganador único hoy.** Corrección frecuente: **ECS no fue donado a OCSF, sino a OpenTelemetry (abr-2023)**, y esa convergencia sigue **incompleta**. Elegir uno por plataforma y escribirlo; traducir en el borde, no en la regla |
| SIEM autoalojado de bajo coste | **Wazuh 4.14.7** (GPLv2) | **Mínimo duro 4.14.4+**. Wazuh tiene historial serio: **CVE-2025-24016** (CVSS 9.9, deserialización en DAPI, fix 4.9.1) fue **explotada activamente por botnets Mirai**. Es un servidor expuesto a agentes: trátalo como Tier 0 |
| SIEM comercial | El que ya tengas; la portabilidad la da Sigma, no el producto | **Elastic Security 9.4.x** (licencia **triple**: AGPLv3 / SSPL / Elastic License — verifica cuál aplica a tu despliegue); **Microsoft Sentinel**; **Google SecOps** (antes Chronicle) con **YARA-L 2.0**; **Splunk ES** |
| Red — IDS/IPS | **Suricata** (8.0.6 y 7.0.17 en paralelo, GPLv2) para firma y detección de protocolo | **Zeek 8.0.9** (BSD) para **metadatos y contexto** de red: no compiten, se complementan. Zeek te da el `conn.log`/`ssl.log` que hace investigable la alerta de Suricata |
| Runtime de contenedor | **Falco 0.44.1** (Apache-2.0, CNCF **graduado** desde feb-2024) | La elección del agente y el *qué vigilar* es de `container-runtime-security-standards`; aquí el ciclo de vida del contenido |
| Triaje offline de EVTX | **Hayabusa 3.10.0** (AGPL-3.0, ATT&CK v19) o **Chainsaw 2.16.2** (GPL-3.0) — ambos ejecutan Sigma sobre evidencia | Parseo manual de EVTX. Útiles además como **motor de test** de reglas Sigma de Windows en CI |
| Contenido de terceros como base | **SigmaHQ** (reglas), **elastic/detection-rules**, **splunk/security_content (ESCU 6.3.0, Apache-2.0)**, **panther-analysis 3.112.0** (Apache-2.0), **Nextron `signature-base`** (licencia **DRL 1.1** — revisa antes de usar en producto comercial) | Consumir el paquete entero sin calibrar (§7). **Vetado**: reglas de proveedor cerradas cuya lógica no puedes leer ni versionar |

**Proyectos a no elegir en 2026** (verificado): **Matano** — sin commits desde ene-2025;
**DetectionLab** — declarado muerto por su autor desde 2023. **Panther**: Databricks anunció
acuerdo de adquisición el 16-jun-2026 y **la nota no dice nada sobre el futuro del OSS** —
`panther-analysis` sigue Apache-2.0 y activo, pero es una apuesta con riesgo de gobernanza.
Mención por si aplica al sector público europeo: **OpenTIDE** (Comisión Europea, EUPL 1.2,
org `OpenTideHQ`) es hoy el marco de detection-as-code formal más completo de fuente abierta.

## 3. Estructura y convenciones

### 3.1 El ciclo de vida (una regla es un artefacto de software, no un ticket)

`idea/hipótesis → fuente de datos → regla → test → despliegue por CI → medición → tuning → retiro`

- **Idea/hipótesis**: toda regla nace de una hipótesis escrita (`"un atacante con credenciales
  válidas registrará un dispositivo nuevo en Entra tras el phishing de device code"`), con
  técnica ATT&CK, actor o campaña de referencia, y **valor esperado**. Sin hipótesis no hay
  criterio para saber si la regla funciona ni para retirarla.
- **Fuente antes que regla** (§3.2): si el evento no llega, la regla es teatro.
- **Regla**: en el repo, con metadatos completos (§3.4), revisada en PR por alguien distinto
  del autor.
- **Test**: unitario obligatorio (§4), más validación adversaria antes de subir la severidad.
- **Despliegue por CI**: nunca a mano en la consola del SIEM. La consola es *read-only* para
  contenido; lo editado ahí se pierde en la siguiente sincronización o produce *drift*
  invisible.
- **Medición**: FP rate, disparos, acciones tomadas. Una regla sin telemetría de sí misma no
  se puede gobernar.
- **Retiro**: la regla que no ha disparado nada útil en su ventana de revisión **se borra o
  se degrada a informativa**, en la misma PR que lo constata. El coste de una regla muerta no
  es cero: consume cómputo, ensucia la cobertura y desgasta al analista que la triaja.

**Estructura de repo de referencia** (adáptala, pero que exista una):

```
detections/
  rules/<plataforma>/<tactica>/<id>.yml     # Sigma u origen del motor
  pipelines/<plataforma>.yml                # pySigma processing pipelines
  tests/<id>/{positive,negative}.jsonl      # eventos que DEBEN y NO deben disparar
  runbooks/<id>.md                          # obligatorio (§3.5)
  coverage/navigator-*.json                 # capas generadas, no editadas a mano
  deprecated/                               # con motivo y fecha, no borrado silencioso
```

### 3.2 Modelo de datos y telemetría: la parte que casi nadie hace

- **El onboarding de una fuente es un proyecto, no un checkbox.** Por cada fuente:
  *qué eventos concretos* (por ID/categoría, no "los logs del AD"), *cómo se transportan*,
  *cómo se normalizan*, *cuánto se retienen*, *cuánto cuesta* y *qué detecciones habilita*.
  Si no habilita ninguna, no se ingiere.
- **Coste y retención son restricciones de diseño de primera clase**, exactamente igual que en
  `observability-standards`. Patrón sano: **retención caliente corta (búsqueda interactiva) +
  retención fría larga y barata (investigación y cumplimiento)**. Regla práctica: la ventana
  fría debe cubrir el *dwell time* que asumes, no el que te gustaría.
- **Normaliza en el borde, no en la regla.** Una regla que trocea strings para reconstruir un
  campo que el pipeline debía haber normalizado es deuda que se paga en cada fuente nueva.
- **Mide la salud de la fuente como si fuera un SLI**: latencia de ingesta, volumen por hora
  con banda esperada, y **alerta por ausencia de eventos** — el silencio de una fuente es
  indistinguible de "no ha pasado nada", y es exactamente lo que produce un atacante que
  desactiva el agente. *Detection of missing detection* es la primera regla que se escribe.
- **Integridad**: los logs de seguridad se separan de la telemetría operativa (control de
  acceso, retención e **inmutabilidad** distintos). El SIEM es el registro que un atacante
  querrá borrar.

**Prioridad de fuentes hoy** (por relación valor/coste, no por tradición):
1. **Identidad y plano de control cloud** — es la superficie principal (§3.7).
2. **Endpoint/EDR** (proceso, línea de comandos, padre/hijo, carga de módulos).
3. **Autenticación y directorio** (AD, Entra, IdP).
4. **CI/CD y registro de artefactos** (§5).
5. **Red** (DNS, proxy/egress, `conn.log`): imprescindible para investigar, mediocre para
   detectar en solitario.

### 3.3 Cobertura ATT&CK con honestidad

- La cobertura se puntúa por **calidad de visibilidad × calidad de la detección**, no por
  conteo de reglas. Escala mínima por técnica: `sin telemetría` → `telemetría sin regla` →
  `regla no validada` → `regla validada contra ejecución real` → `regla validada y con
  procedimiento de respuesta`. Solo los dos últimos cuentan como cobertura.
- **Una técnica cubierta por una sola variante no está cubierta.** ATT&CK enumera
  comportamientos, no comandos: si la regla solo casa el binario que usó el atomic test, has
  cubierto la herramienta, no la técnica.
- Prioriza por **amenaza relevante** (perfil de adversario, sector, superficie real), no por
  llenar la matriz. Una matriz verde uniforme es señal de que se ha optimizado el color.
- **Genera las capas de Navigator desde el repo en CI.** Un mapa de cobertura editado a mano
  miente en cuanto se mergea la siguiente PR.
- Al saltar de versión de ATT&CK, **usa el crosswalk oficial** (la partición de Defense
  Evasion en v19 invalida mapeos previos) y trata la migración como un cambio con PR y
  revisión, no como un `sed`.

### 3.4 Anatomía de una regla que se puede gobernar

Metadatos obligatorios, sin excepción: `id` estable (UUID, nunca reutilizado), `title`
accionable, `status` (`experimental` → `test` → `stable` → `deprecated`), `description` con
la hipótesis, `author`/`owner` (equipo, no persona), `date`/`modified`, `level` justificado,
`tags` ATT&CK con versión del framework, `falsepositives` **poblado con casos reales
observados**, `references` y **enlace al runbook**.

- **La severidad se gana, no se declara.** Una regla nace en `experimental` con severidad
  informativa; sube solo con datos: N días en producción, FP rate medido, y validación
  adversaria superada. Subir la severidad "porque la técnica es grave" es la vía directa a la
  fatiga de alertas.
- **Contexto accionable en el propio evento**: quién (identidad resuelta, no un GUID), qué
  activo (con dueño y criticidad), qué pasó (comando/campos crudos relevantes), qué se espera
  del analista. Una alerta que obliga a abrir cuatro consolas para saber si importa ya ha
  fallado.
- **Enriquecimiento en el pipeline, no en la cabeza del analista**: inventario de activos,
  criticidad, propietario, geolocalización, reputación, y **si esa actividad estaba
  autorizada** (ventana de cambio, ejercicio de red team deconflictado).
- **Deduplicación y agrupación**: la unidad de trabajo es el **incidente**, no la alerta. Se
  agrupa por las entidades que definen *un mismo caso* (identidad, host, sesión, campaña) con
  ventana temporal. Las **correlations de Sigma v2** (`event_count`, `value_count`,
  `temporal`) son el mecanismo portable para expresar cadenas y umbrales sin atarse al motor.
- **Portabilidad con límite declarado**: Sigma es el formato de autoría; el backend traduce.
  Cuando la semántica no sobrevive a la traducción (correlación compleja, joins, funciones
  propias del motor, análisis de secuencia), **se escribe en el lenguaje nativo y se declara
  la excepción en la regla** — no se fuerza un Sigma que traduce a algo que no es lo que dice.
- **Frescura de los backends de pySigma: verifícala, no confíes en la etiqueta.** El
  directorio oficial marca como *stable* backends abandonados (`sentinelone` sin publicar
  desde 2023, `ibm-qradar-aql` e `insightidr` igualmente rezagados). Antes de apostar una
  plataforma a un backend, mira la fecha del último release, no el badge.

### 3.5 Runbook obligatorio: la regla sin acción no se despliega

Cada alerta lleva runbook versionado **en el mismo repo y en la misma PR**, con: qué significa
el disparo, **cómo se verifica en 5 minutos** (consultas concretas, no "investigar"), qué es
benigno conocido, qué acción inmediata corresponde (contener, revocar sesión, aislar,
escalar), a quién se escala y con qué severidad, y qué datos preservar antes de tocar nada
(la preservación es de `incident-response-forensics-standards`; el enlace es obligatorio).

**Si no sabes escribir el runbook, no sabes qué detecta la regla: no se mergea.**

### 3.6 Validación adversaria y detección de regresiones

- **Ninguna regla sube de `experimental` sin haber disparado contra la ejecución real de la
  técnica.** El generador del ataque es de `offensive-security-standards`; la evidencia de
  disparo es entregable mío.
- **Purple team ≠ red team**: el valor no es "nos entraron", es la **matriz ejecutada
  vs. detectada vs. alertada vs. respondida** por técnica. Toda ejecución no detectada abre un
  ítem de backlog con dueño y fecha.
- **Regresiones**: una regla que funcionaba deja de funcionar sola cuando cambia el agente,
  el esquema del proveedor, la versión del SO o la ruta de un binario. Ejecución **programada
  y automática** de un subconjunto de atomics contra un entorno controlado, con alerta si la
  detección esperada no aparece. Ejemplo real y reciente de por qué esto no es teórico: el
  esquema de *advanced hunting* de Defender renombró `AADSignInEventsBeta` a
  `EntraIdSignInEvents` y **eliminó las tablas legacy el 9-dic-2025**, y el 25-feb-2026 los
  booleanos pasaron de `1`/`0` a `True`/`False` — cada uno de esos cambios rompe reglas en
  silencio.
- Toda ejecución adversaria se **deconflicta con el SOC** antes: un ejercicio que consume el
  proceso de incidente real es un fallo de proceso, no una prueba superada.

### 3.7 Identidad y nube: donde está hoy la detección que importa

El perímetro es la identidad. Las fuentes mínimas, con **nombres exactos** (verificar §8):

- **Entra ID**: `SigninLogs` (interactivos), `AADNonInteractiveUserSignInLogs`,
  `AADServicePrincipalSignInLogs`, `AADManagedIdentitySignInLogs`, `AuditLogs` y
  **`MicrosoftGraphActivityLogs`** (requiere P1/P2). En 2026 se añadieron **Agent logs** para
  *Entra Agent ID*, y `AADNonInteractiveUserSignInLogs` ya trae columna `Agent`: las
  identidades de agente de IA son superficie nueva y hay que ingerirlas desde el día uno.
- **AWS CloudTrail**: hoy son **cuatro** categorías, no dos — *Management*, *Data*, ***Network
  activity*** (`eventCategory = NetworkActivity`; único `errorCode` válido
  `VpceAccessDenied`, sirve para ver credenciales ajenas a tu organización usando tus VPC
  endpoints) e *Insights*. **Solo management está activo por defecto**: los eventos de datos
  y de red se habilitan explícitamente y se presupuestan.
- **GCP**: `cloudaudit.googleapis.com%2Factivity` (Admin Activity, siempre),
  `%2Fdata_access` (**deshabilitado por defecto** salvo BigQuery), `%2Fsystem_event`,
  `%2Fpolicy`. Para abuso de consentimiento en Workspace, el log clave es el **OAuth Token
  Audit** (`applicationName=token`, eventos `authorize`/`revoke`, con `scope_data`,
  `client_id`, `app_name`); retención por defecto **6 meses** — si tu ventana de
  investigación es mayor, expórtalo.
- **GuardDuty Extended Threat Detection** está activo por defecto y sin coste extra, con
  ventana móvil de 24 h. **Trampa operativa verificada: ignora los findings archivados,
  incluidos los archivados por tus propias suppression rules** — un tuning agresivo te ciega
  la correlación de secuencias de ataque.

**Casos de uso obligatorios en identidad** (cadena ATT&CK defendible:
`T1566.002 → T1528 → T1550.001 → T1098.005 / T1098.001`; **no existe sub-técnica dedicada al
device code phishing** — quien lo menciona explícitamente es T1566.002, no T1528):

- **Device code phishing**: el campo decisivo en Entra es `AuthenticationProtocol == "deviceCode"`.
  Es la técnica de **Storm-2372** (Microsoft, feb-2025; **reclasificado el 31-jul-2026 como
  sub-cluster de Midnight Blizzard/SVR**), que pivotó al client ID
  `29d9ed98-a469-4536-ade2-f981bc1d605e` (*Microsoft Authentication Broker*) para obtener un
  **PRT** y registrar dispositivo. Control preventivo: condición **"Authentication flows"** de
  Acceso Condicional. Aviso de planificación: Microsoft despliega una **política gestionada
  "Block device code flow"** que crea en *report-only* y **activa sola tras un mínimo de 45
  días**, avisando 28 días antes; audítala filtrando `AuditLogs` por el iniciador
  `Microsoft Managed Policy Manager`. Caveat crítico: **una política de CA dirigida a usuarios
  no cubre a los service principals**.
- **Registro de dispositivo y de credencial nueva**: alta o cambio de credenciales en
  *service principals* y *app registrations*. Es exactamente el patrón del caso
  **Commvault/Metallic** (CISA, may-2025, **CVE-2025-3928** en KEV): robo de *client secrets*
  de una app cross-tenant.
- **Abuso de token OAuth de integración de terceros**: el caso **Salesloft Drift / UNC6395**
  (ago-2025) exfiltró datos de Salesforce con tokens OAuth legítimos, buscando con SOQL
  masivo cadenas como `AKIA`, `Snowflake`, `password`, `secret`, y **borrando los registros de
  los query jobs**. Señales: eventos `UniqueQuery` de Salesforce Event Monitoring, UA
  `Salesforce-Multi-Org-Fetcher/1.0`. Lección de diseño: **el consentimiento de una app de
  terceros es una llave permanente sin MFA** — inventaría y vigila los consentimientos como
  vigilas los administradores.
- **Viaje imposible y anomalía de sesión**: útil, pero **solo como enriquecimiento o señal de
  baja severidad**. En una plantilla con VPN corporativa y móviles genera FP masivo; nunca
  como página en solitario.
- **Correlación Graph↔sign-in** (patrón canónico verificado):
  `MicrosoftGraphActivityLogs | join ... on $left.SignInActivityId == $right.UniqueTokenIdentifier`
  — es lo que convierte "un token hizo cosas" en "esta sesión, de este usuario, desde este
  origen, hizo estas cosas".

### 3.8 Threat intelligence: pirámide del dolor, no lista de la compra

- **Los IoC caducan; los TTP no.** Hash y IP se rotan en horas y su valor es casi solo
  retrospectivo; herramientas y TTP cuestan al adversario y sobreviven meses o años. El
  esfuerzo de ingeniería va **arriba** de la pirámide; los IoC se automatizan y se olvidan.
- **Todo IoC entra con caducidad y procedencia.** Un feed sin fecha de expiración es una
  fuente de FP que crece sola. Los feeds gratuitos indiscriminados generan más triaje del que
  ahorran: se miden como cualquier regla (§6) y se cortan si no rinden.
- **Retro-hunt sistemático**: cada IoC nuevo se busca **hacia atrás** en la retención fría, no
  solo hacia delante. Ahí es donde el IoC sí vale.
- El objetivo final de la TI no es la lista: es **priorizar el backlog de detección** por
  adversario relevante.

## 4. Gates de calidad (rompen el build)

En orden de coste creciente. Los cuatro primeros son bloqueantes en toda PR de detección.

1. **Lint y esquema**: la regla parsea, valida contra el esquema del formato (Sigma spec 2.1,
   TOML de `detection-rules`, esquema del motor) y **compila con el backend de destino**
   (`sigma convert`). Una regla que no traduce no existe.
2. **Metadatos completos**: `id` único y no reutilizado, dueño, `status`, tags ATT&CK
   **existentes en la versión declarada** del framework, `falsepositives` no vacío.
3. **Runbook presente y enlazado.** Sin runbook, sin merge (§3.5). No negociable.
4. **Test unitario con positivos y negativos**: al menos un evento que **debe** disparar y
   varios que **no deben** (los FP conocidos de la propia regla). Motores válidos:
   `detection_rules test` (Elastic), `panther_analysis_tool test`, Hayabusa/Chainsaw sobre
   EVTX de muestra, o el runner del backend. **Una regla sin test negativo no está probada:
   está declarada.**
5. **Test de no-regresión de esquema**: los eventos de prueba se validan contra el esquema
   vigente (ECS/OCSF/tabla del proveedor), de modo que un renombrado de campo rompa el build
   y no la detección en silencio (§3.6).
6. **Cobertura**: la capa de Navigator se **regenera en CI** y el diff se revisa. Añadir una
   regla que no mueve la cobertura declarada es señal de duplicado.
7. **Validación adversaria** antes de promover a `stable` o de subir severidad: ejecución
   atómica real y evidencia del disparo adjunta a la PR.
8. **Despliegue por pipeline** con versionado y rollback: `Sentinel repositories` (GA
   mar-2026), `elastic/detection-rules` con *version lock* por rama de stack, o el mecanismo
   equivalente. **Prohibido el despliegue manual en consola.**

**Regla de promoción medible** (ajusta los números, pero fija unos): `experimental` → `test`
tras compilar y pasar tests; `test` → `stable` tras ≥ 2 semanas en producción con **FP rate
medido y < 20 %** y validación adversaria superada. **Se mide antes de subir la severidad,
nunca después.**

## 5. Seguridad del propio programa de detección

- **La cadena de suministro del tooling de seguridad es un objetivo de primer orden, y 2026
  lo demostró.** El compromiso de **Trivy** por el actor *TeamPCP* (**CVE-2026-33634**, CVSS
  9.4, en **CISA KEV** desde el 26-mar-2026) llegó a **force-pushear 76 de 77 tags** de
  `trivy-action` y los 7 de `setup-trivy`, con payload que **leía la memoria del proceso
  `Runner.Worker` para extraer secretos enmascarados**; la misma campaña secuestró los 35 tags
  de `Checkmarx/kics-github-action`. Precedente análogo: `tj-actions/changed-files`
  (**CVE-2025-30066**). Consecuencias operativas, sin excepción:
  - **Pin por SHA de commit** de toda GitHub Action del pipeline de detección; **pin por
    digest** de toda imagen; verificación de firma y checksum de los binarios de detección.
  - **Immutable releases** activadas en tus propios repos de contenido.
  - **No confundas procedencia con bondad**: la variante *CanisterWorm* llegó a **generar
    atestaciones SLSA Build L3 válidas vía Sigstore para paquetes maliciosos**. La firma
    prueba **quién** lo construyó, no **qué** hace.
  - El detalle del endurecimiento del pipeline es de `cicd-standards`; aquí es requisito de
    entrada.
- **Verificado ago-2026: ninguna de las herramientas de detección recomendadas (Sigma,
  YARA/YARA-X, Atomic Red Team, Caldera, Falco, Suricata, Zeek, Wazuh, Elastic) aparece como
  víctima de compromiso de repositorio en 2025-2026.** El vector, sin embargo, les aplica
  igual: no lo trates como descartado, sino como no ocurrido todavía.
- **El SIEM y sus reglas son datos sensibles.** El ruleset revela exactamente qué ves y qué
  no: control de acceso al repo de detección, revisión de quién puede desactivar o modificar
  reglas, y **alerta sobre la modificación o el silenciamiento del propio contenido**. La
  desactivación de una regla es un evento de seguridad.
- **Nunca embebas secretos en reglas ni en consultas** (tokens de API, credenciales de
  enriquecimiento, claves de webhook). Van al gestor de secretos
  (`secrets-management-standards`).
- **PII y minimización**: los logs de seguridad contienen datos personales por definición.
  Base legal, retención por finalidad y control de acceso son de
  `privacy-engineering-standards`; el requisito aquí es que **la regla y su enriquecimiento no
  amplíen el conjunto de datos personales** más allá de lo necesario para decidir.
- **Integridad y no repudio** de la evidencia: logs append-only, reloj sincronizado y
  verificado (una deriva de reloj destruye cualquier correlación temporal y cualquier
  timeline forense) y control de quién puede purgar.

## 6. Operabilidad, coste y métricas del programa

**Métricas que se publican (y qué las corrompe)**

| Métrica | Qué mide | Cómo se corrompe |
|---|---|---|
| **MTTD** | Tiempo desde la actividad del adversario hasta la detección | Medir desde la ingesta, no desde el evento; excluir lo que nunca se detectó (sesgo de supervivencia). Solo es honesta con purple team, donde conoces el `t0` real |
| **Cobertura por fuente** | % de activos de cada clase que reportan la fuente esperada | Contar fuentes configuradas en vez de fuentes **que envían eventos ahora** |
| **FP rate por regla** | Disparos cerrados como benignos / disparos totales | No registrar la disposición del analista; entonces no hay dato y el tuning es opinión |
| **Alertas por analista y hora** | Carga real de triaje | Contar alertas en vez de **incidentes agrupados**. Umbral de alarma del programa, no del turno |
| **Reglas huérfanas** | Sin dueño, sin disparos, sin runbook, sin revisión en su ventana | Ninguna: es la métrica más difícil de maquillar y la que mejor predice el colapso del programa |
| **% de reglas validadas adversarialmente** | Cobertura real | Contar reglas escritas |

- **La fatiga de alertas es el fallo modal del dominio.** Si el analista ignora la cola, la
  detección no existe aunque las reglas sean perfectas. Prioridad de trabajo cuando la cola
  se desborda: **reducir el ruido antes que añadir cobertura**, siempre.
- **Tuning ≠ desactivar.** El orden correcto es: (1) arreglar el dato o el enriquecimiento,
  (2) acotar la condición de la regla, (3) excepción **estrecha, documentada y con
  caducidad**, (4) degradar a informativa, (5) retirar. Una supresión amplia y permanente es
  un agujero de detección con forma de tuning — y en AWS, además, ciega la correlación de
  GuardDuty (§3.7).
- **Coste**: el SIEM se paga por ingesta, por retención o por cómputo de consulta según
  producto — **averigua tu unidad de cobro antes de diseñar**, porque decide qué optimizar.
  Palancas en orden: no ingerir lo que no habilita detección; filtrar y agregar en el borde;
  retención escalonada a almacenamiento barato; consultas programadas eficientes. Ingerir "por
  si acaso" es la forma más cara de no detectar nada.
- **Rendimiento de la regla**: consultas programadas con ventana y frecuencia coherentes
  (ventana ≥ frecuencia + latencia de ingesta, o pierdes eventos en el borde), sin joins
  sobre todo el histórico, sin regex catastróficas. Una regla que no termina dentro de su
  intervalo no detecta: se salta ejecuciones.
- **Cambio de plataforma con fecha dura**: si usas **Microsoft Sentinel**, el producto ya está
  GA en el portal de Defender (ene-2026) y **deja de estar soportado en el portal de Azure
  después del 31-mar-2027**. Es un proyecto de migración con fecha, no un cambio de UI.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisión de ATT&CK y remapeo en cada release mayor del framework (~semestral;
  v18 y v19 trajeron rupturas estructurales); revisión de todo el ruleset **trimestral** con
  poda explícita; actualización de `pySigma`/backends y del ruleset comunitario mensual;
  revisión de fuentes y de su salud, continua.
- **Toda excepción y toda supresión llevan caducidad y dueño.** Sin fecha, se convierten en
  agujeros permanentes que nadie recuerda haber abierto.
- El contenido de terceros se **calibra al adoptarlo**, no "algún día": entra al repo, pasa
  los gates de §4 y se le asigna dueño, o no entra.
- Cuando un proyecto cambia de gobernanza (Caldera → Apache Incubator; Panther → Databricks),
  **revísalo como riesgo de plataforma**, no como nota de prensa: licencia, cadencia de
  releases y quién responde a un CVE.

**PROHIBIDO**
- ❌ Desplegar una regla **sin test unitario** (positivo **y** negativo).
- ❌ Desplegar una regla **sin runbook** con acción concreta.
- ❌ **Subir la severidad sin haber medido** el FP rate en producción.
- ❌ Crear o editar contenido **directamente en la consola** del SIEM, sin repo ni PR.
- ❌ Habilitar el paquete de reglas por defecto del producto **sin calibrar** — el anti-patrón
  central del dominio: un SIEM lleno de reglas que nadie ha tocado no es cobertura, es una
  cola de ruido que garantiza que la alerta buena pase desapercibida.
- ❌ Presentar **conteo de reglas o de técnicas** como cobertura sin puntuar visibilidad y
  validación.
- ❌ Reglas sin dueño, sin `id` estable, sin tags de versión de ATT&CK o con `falsepositives`
  vacío.
- ❌ Escribir reglas para una fuente que **no está confirmada en ingesta**, o dejar sin alerta
  la **ausencia de eventos** de una fuente.
- ❌ Supresiones amplias, permanentes o sin dueño; silenciar una regla en lugar de arreglarla.
- ❌ Alertar sobre IoC sin caducidad ni procedencia, o construir el programa sobre IoC en vez
  de sobre TTP.
- ❌ Viaje imposible (u otras heurísticas de anomalía pura) como alerta de página en solitario.
- ❌ Consumir GitHub Actions o imágenes del pipeline de detección **por tag mutable** en vez de
  por SHA/digest, o tratar una atestación SLSA como prueba de que el artefacto es benigno.
- ❌ Ejecutar validación adversaria **sin deconfliction** previa con el SOC.
- ❌ Secretos o credenciales embebidos en reglas, consultas o pipelines de enriquecimiento.
- ❌ Empezar algo nuevo sobre **Matano** o **DetectionLab** (sin mantenimiento), o sobre YARA
  clásico pudiendo usar YARA-X.
- ❌ Ejecutar Wazuh o Caldera en versiones anteriores a los mínimos de §2 (CVEs críticas, una
  de ellas explotada en masa).
- ❌ Traducir a la fuerza a Sigma una lógica que el backend no soporta y confiar en el
  resultado.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, licencia, estado de proyecto o nombre de tabla/campo,
**búscalo — no lo recuerdes**. Datos verificados ago-2026 (caducan rápido): Sigma spec
**v2.1.0**, pySigma **1.5.0**, sigma-cli **3.1.0**, reglas SigmaHQ **r2026-07-01**; ATT&CK
**v19.1** (abr-2026) y Navigator **5.3.2**; ATT&CK Workbench **4.10.0**; OCSF **1.8.0** (LF
desde nov-2024); ECS **9.4.0**; Elasticsearch **9.3.0** / Elastic Security **9.4.4**; Wazuh
**4.14.7**; Suricata **8.0.6** y **7.0.17**; Zeek **8.0.9**; Falco **0.44.1** (CNCF graduado
feb-2024); YARA-X **1.19.0** y YARA **4.5.8**; Splunk ESCU **6.3.0**; `panther-analysis`
**3.112.0**; Chainsaw **2.16.2**; Hayabusa **3.10.0**; DeTT&CT **2.2.0**.

1. **Versión vigente de ATT&CK y su changelog**, incluido el *crosswalk* de la partición de
   Defense Evasion (v19) y el modelo Detection Strategies/Analytics (v18) — **antes** de
   remapear nada.
2. **Frescura real del backend de pySigma** que vayas a usar: fecha del último release en el
   `pySigma-plugin-directory`, no el badge `stable`.
3. **Gobernanza y salud** de Caldera (Apache Incubator desde may-2026, **versión actual no
   verificada aquí**) y de Panther (adquisición por Databricks anunciada jun-2026, **futuro
   del OSS no declarado**).
4. **Nombres exactos de tablas, campos y logs** del proveedor antes de escribir la consulta:
   los esquemas de Defender/Entra, CloudTrail y Cloud Audit Logs cambiaron en 2025-2026 y
   siguen cambiando.
5. **Fechas duras de plataforma**: fin de soporte de Sentinel en el portal de Azure
   (31-mar-2027, verificar), estado de las migraciones de contenido en curso.
6. **Advisories y CVEs** de tu SIEM y de tus agentes (Wazuh y Elastic han tenido críticas
   recientes) y del tooling que ejecutas en CI.
7. **Compromisos de cadena de suministro** de cualquier action, imagen o binario nuevo del
   pipeline de detección antes de adoptarlo (§5).

**Huecos declarados — no verificados en este documento, verifícalos tú antes de usarlos**:
- **Versión actual de Apache Caldera (incubating)**.
- **Versión de Splunk Enterprise Security** y novedades del producto tras la adquisición por
  Cisco (la documentación oficial no fue accesible durante la verificación).
- **Fechas EOL formales de las ramas Suricata 7.0 y 8.0**, y si existe o está planificada una
  release 9.0 (la guía de upgrade la menciona; no hay release publicada).
- **Estado del soporte de OCSF en Elastic Security y en Splunk** en 2026.
- **Que Red Canary (mantenedor de Atomic Red Team) sea hoy parte de Zscaler** — fuente
  secundaria, sin confirmar contra nota primaria.
- **Fechas de GA** de la condición "Authentication flows" de Acceso Condicional, de los
  *network activity events* de CloudTrail y de GuardDuty Extended Threat Detection.
- **IDs ATT&CK secundarios** citados en literatura de identidad (T1621, T1539, T1550.004,
  T1078.004, T1098.002/.003, T1606.002): no verificados individualmente contra el sitio.
- **Si los proyectos de detección recomendados consumían** `trivy-action` o
  `tj-actions/changed-files` durante sus ventanas de exposición: no descartado, solo no
  encontrado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
