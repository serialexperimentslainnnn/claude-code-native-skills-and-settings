---
name: threat-intelligence-standards
description: Cyber threat intelligence as a production discipline — producing, scoring, ageing out and retiring knowledge about the adversary. Use when running the intelligence cycle, writing Priority Intelligence Requirements (PIR) and an intelligence collection plan, splitting strategic / operational / tactical products, modelling data in STIX 2.1 (indicator, malware, intrusion-set, threat-actor, campaign, attack-pattern, relationship, sighting, marking-definition, confidence) and exchanging it over TAXII 2.1 collections and channels, operating MISP (events, attributes, objects, galaxies, taxonomies, warninglists, sightings, feeds, sync servers, PyMISP) or OpenCTI (connectors, pycti, Community versus Enterprise Edition), evaluating an OSINT or commercial feed for volume, uniqueness, latency, accuracy and false-positive rate, assigning indicator confidence and a mandatory expiry, applying the Pyramid of Pain to decide what is worth tracking, mapping to MITRE ATT&CK technique and tactic IDs and surviving version migrations (v18 Detection Strategies and Analytics, v19 Stealth TA0005 and Defense Impairment TA0112), applying TLP 2.0 (TLP:RED, TLP:AMBER+STRICT, TLP:AMBER, TLP:GREEN, TLP:CLEAR) and PAP markings, joining an ISAC/ISAC-like sharing community or a CERT/CSIRT trust group, writing an attribution assessment with analytic confidence language, or deciding whether a paid intelligence subscription changes any decision you take.
---

# Estándares de Threat Intelligence (CTI)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **producir, evaluar, distribuir y caducar conocimiento sobre el adversario**: requisitos
de inteligencia, recolección, procesamiento, análisis, difusión y retroalimentación; modelado e
intercambio (STIX/TAXII, MISP, OpenCTI); calidad de fuentes; ciclo de vida del indicador; mapeo a
ATT&CK; marcado y compartición; y la evaluación de atribución.

**Principio rector: la inteligencia se juzga por la decisión que cambia, no por el volumen que
produce.** Un informe que nadie usa para decidir dónde mirar, qué parchear primero o qué detección
escribir es una suscripción, no inteligencia. Corolarios que ordenan todo el documento:

1. **Sin PIR no hay CTI**, solo curiosidad cara. El requisito precede a la recolección.
2. **Un IoC sin fecha de caducidad es deuda**, no un control. Envenena la detección durante años y
   genera falsos positivos que se pagan en horas de analista (§3).
3. **La atribución casi nunca decide nada operativo** (§5). Es interesante; rara vez accionable.

Disparadores: los del frontmatter. Regla de arbitraje en una línea: **si el entregable es
conocimiento con confianza, fuente y caducidad, es de aquí; si es una regla, un turno, un caso o un
parche, es de la skill vecina.**

**No aplica**: ver
- `detection-engineering-standards`: **la regla se escribe allí**. Aquí se produce la hipótesis, el
  indicador y el mapeo ATT&CK que la alimentan; el ciclo de vida de la regla, sus tests, su tuning y
  su cobertura son suyos. **Frontera bidireccional**: la detección devuelve *sightings* que aquí
  puntúan y caducan indicadores. Un flujo de CTI que no recibe *feedback* de detección está ciego.
- `soc-operations-standards`: **el turno, la cola y el triaje**. El enriquecimiento de una alerta
  consume lo que aquí se produce; atender, arreglar o retirar una alerta es decisión suya.
- `incident-response-forensics-standards`: **el caso vivo**. La investigación consume CTI y produce
  indicadores nuevos que **vuelven aquí a normalizarse, marcarse y caducar** — no se quedan en el
  ticket.
- `vulnerability-management-standards`: **EPSS, KEV, CVSS y el SLA de parcheo son suyos**, sin
  excepción. Aquí solo el aporte propio —*este actor explota esto contra este sector*— que se le
  entrega como entrada de priorización. **No se duplica su modelo de riesgo.**
- `incident-management-standards` (gobierno del incidente), `offensive-security-standards`
  (emulación de adversario con alcance y autorización por escrito; **esta skill es defensiva** y
  produce el perfil de TTP que el ejercicio emula), `observability-standards` (pipeline y retención
  de la telemetría), `grc-compliance-standards` (obligación de notificar, evidencia de auditoría y
  el marco NIS2/DORA), `privacy-engineering-standards` (**dato personal dentro de la inteligencia**:
  un indicador puede ser una IP de una persona, y compartirlo tiene base jurídica o no la tiene),
  `identity-access-management-standards`, `email-security-standards` (phishing como canal con
  controles propios), `finops-standards` (coste de la suscripción como unidad económica),
  `ai-governance-standards` y `llm-app-engineering-standards` (si se usa un LLM para resumir o
  clasificar informes: **el resumen inventado es un fallo de inteligencia, no de producto**).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada |
|---|---|---|
| Modelo de datos e intercambio | **STIX 2.1 + TAXII 2.1**, sin alternativa | Ambos son **OASIS Standard desde el 10-jun-2021** (STIX v2.1 CS03, TAXII v2.1 CS01). **No hay STIX 2.2 publicado a ago-2026**; el trabajo del CTI TC se sigue en `oasis-tcs/cti-stix2`. Diseñar contra un formato propietario del proveedor es aceptar el bloqueo |
| Plataforma de compartición | **MISP** si el centro de gravedad es *compartir con una comunidad* | Serie 2.5 activa en 2026 (2.5.32 ene, 2.5.35 mar, 2.5.37 abr, 2.5.38 may…). Licencia verificada **leyendo el `LICENSE` en crudo**: *"GNU AFFERO GENERAL PUBLIC LICENSE / Version 3, 19 November 2007"* → **AGPLv3** |
| Plataforma de correlación | **OpenCTI** si el centro de gravedad es *modelar y relacionar conocimiento* | **Licencia leída en crudo — y desmiente lo que "todo el mundo sabe"**: el `LICENSE` dice *"The OpenCTI Community Edition is licensed under the Apache License, Version 2.0"* y *"The OpenCTI Enterprise Edition is licensed under the OpenCTI Enterprise Edition License"*. **No es AGPL.** Es *open core*: funciones de empresa (p. ej. SSO OIDC/LDAP/SAML) quedan bajo licencia propietaria — verifica **qué necesitas** antes de diseñar |
| MISP y OpenCTI a la vez | **Legítimo y frecuente**, no redundante | MISP como bus de intercambio con la comunidad; OpenCTI como grafo de conocimiento interno. Lo que **no** es legítimo es tener dos sin decidir cuál es la fuente de verdad de cada objeto |
| Marco de TTP | **MITRE ATT&CK**, con la **versión anotada en cada producto** | **v18 (28-oct-2025) retiró *Data Sources* y las *Detections* clásicas y las sustituyó por *Detection Strategies* (`DETxxxx`) y *Analytics* (`ANxxxx`)** — ~691 estrategias y >1.700 analíticas. **v19 (28-abr-2026) partió *Defense Evasion* en Enterprise: *Stealth* hereda `TA0005` y *Defense Impairment* es el nuevo `TA0112`**; `T1562` se fusionó en `T1685`. **Cambio solo de Enterprise**: Mobile e ICS mantienen Defense Evasion |
| Migración de versión ATT&CK | **Planificada, con el crosswalk oficial** | MITRE publicó un *crosswalk* del split en JSON y CSV. **Trampa medida**: las reglas y paneles que referencian `TA0005` **siguen casando pero contra un conjunto más estrecho** — la cobertura cae en silencio, no da error |
| Marcado | **TLP 2.0, verbatim y sin dialectos locales** | Versión 2.0 autoritativa desde **agosto de 2022**. Etiquetas: `TLP:RED` *"For the eyes and ears of individual recipients only, no further disclosure"*; `TLP:AMBER+STRICT` (solo la organización, sin clientes); `TLP:AMBER` *"…need-to-know basis within their organization and its clients"*; `TLP:GREEN` *"…spread this within their community"*; `TLP:CLEAR` *"…spread this to the world, there is no limit on disclosure"*. **`TLP:WHITE` es TLP 1.0 y está retirado**: si aparece, el emisor no ha actualizado |
| Modelo de priorización de indicadores | **Pyramid of Pain** (Bianco) | Hash y IP están en la base: baratos para el atacante, caducan en horas. **TTP en la cima: caro cambiarlas, y por eso es donde se invierte.** Un programa que solo produce hashes e IPs es un programa que el adversario derrota cambiando de servidor |
| Feeds | **Ninguno se ingiere sin evaluación previa (§4)** | Evidencia académica: *Reading the Tea Leaves* (USENIX Security '19) midió solapamiento y precisión de feeds públicos y comerciales y encontró **limitaciones significativas**; entre ellas, que **la mayoría de indicadores de IP aparecen una sola vez** (37 de 47 feeds con >80 % de indicadores únicos). **Consecuencia: el solapamiento entre feeds es bajo, así que "comprar más feeds" no converge en cobertura, y ninguno se puede tratar como verdad** |
| Suscripción comercial | **Se justifica por PIR cubierto, no por catálogo** | Ver §4: criterio de cuándo no aporta nada |

## 3. El ciclo, los niveles y el ciclo de vida del indicador

**Ciclo de inteligencia** — se recorre entero o no es inteligencia: **requisitos → recolección →
procesamiento → análisis → difusión → retroalimentación**. El paso que se salta siempre es el
último, y es el único que dice si sirvió de algo.

- **PIR (Priority Intelligence Requirements)**: entre 3 y 10, escritos, con dueño de negocio y
  **revisados al menos anualmente**. Un PIR es una pregunta que alguien usará para decidir ("¿qué
  actores atacan a nuestro sector con ransomware y por qué vector inicial?"), no un tema
  ("ransomware"). **Sin PIR, la recolección la define el vendedor.**
- **Plan de recolección**: cada PIR se mapea a las fuentes que lo responden y a los huecos que nadie
  cubre. **El hueco declarado es un entregable**; taparlo con un feed genérico es autoengaño.
- **Tres niveles, tres productos, tres audiencias** — mezclarlos es el error de formato más común:
  **estratégico** (tendencias, riesgo sectorial, intención; audiencia dirección, sin IoC ni jerga,
  con implicación de inversión); **operacional** (campañas, TTP, infraestructura; audiencia SOC,
  detección e IR — **el nivel de más valor y el más descuidado**, por ser el más caro de producir);
  y **táctico** (indicadores atómicos; audiencia máquinas — **se consume automatizado o no se
  consume**: un IoC copiado a mano a un SIEM ya llegó tarde).

**Ciclo de vida del indicador (regla dura):**

- **Todo indicador nace con: fuente, fecha de observación, confianza, `valid_until` y el contexto
  que lo hace accionable.** Sin los cinco, no entra en la plataforma. El campo que la gente omite es
  siempre `valid_until`, y es el que decide si el sistema envejece bien.
- **Caducidad por tipo, no uniforme**: hash de fichero puede vivir años; IP de C2 en hosting
  compartido vive días y luego es un falso positivo garantizado; dominio, en medio. **Un decaimiento
  automático configurado (MISP tiene modelos de *decay*) es obligatorio, no opcional.**
- **Warninglists / allowlists antes de publicar**: rangos de nube, resolvers públicos, CDN, dominios
  de servicios legítimos. **La IP de un CDN publicada como IoC es una interrupción de servicio con
  origen conocido.**
- **Los *sightings* son el mecanismo de calidad**: un indicador que nadie ve nunca en meses se
  degrada; uno que dispara solo falsos positivos se retira **y se informa al emisor**. Sin el bucle
  de vuelta a `detection-engineering`, la puntuación es teoría.
- **Precisión sobre volumen, siempre.** El número de indicadores en la plataforma no es una métrica
  de programa: es una métrica de acumulación.

**Mapeo a ATT&CK:**
- Todo producto operacional lleva **técnica, subtécnica, táctica y la versión de ATT&CK usada**.
  Sin la versión, el producto no es comparable dentro de dos releases (§2).
- **Mapea lo que has observado, no lo que el informe del proveedor dice.** El mapeo copiado infla la
  cobertura aparente y no soporta una revisión.
- **`TA0005` cambió de significado en v19.** Todo mapeo anterior a abr-2026 se revisa con el
  crosswalk antes de reutilizarse en una métrica de cobertura.

## 4. Calidad de la fuente y del producto

**Evaluar un feed antes de ingerirlo — cinco ejes, medidos, no prometidos:**

1. **Volumen** y su distribución en el tiempo (un pico es un evento, no una tendencia).
2. **Unicidad**: cuánto aporta que no tengas ya. Con el bajo solapamiento medido en la literatura
   (§2), **hay que medirlo contra tus fuentes actuales**, no asumirlo.
3. **Latencia** entre observación y publicación: un feed con 30 días de retraso es historia.
4. **Precisión / tasa de falsos positivos**, medida contra tu propio tráfico en modo observación.
5. **Contexto**: ¿trae actor, campaña, TTP y confianza, o es una lista de cadenas? Una lista sin
   contexto no se puede triar ni caducar con criterio.

**Prueba obligatoria antes de comprar o de bloquear**: ingesta en modo *no-block* durante un periodo
acordado, midiendo los cinco ejes. **Ningún feed pasa directamente a bloqueo.**

**Cuándo un feed comercial no aporta nada — criterios de rechazo:** repite lo que ya tienes de
fuentes abiertas; su unicidad es alta pero **irrelevante para tus PIR**; no cubre tu sector,
geografía ni pila; entrega volumen sin contexto ni caducidad (te transfiere el análisis cobrándotelo);
solo da indicadores atómicos y ningún análisis de TTP; **no puedes evaluarlo** —sin prueba con tus
datos ni metodología publicada, **un proveedor que no permite la prueba está diciendo el
resultado**—; o **el equipo no tiene capacidad de consumirlo**, que es la forma más cara de no
hacer CTI.

**Métricas del programa** (pocas, y que cambien decisiones): **PIR cubiertos frente a huecos
declarados**; **productos que provocaron una acción trazable** (regla nueva, parche priorizado,
control cambiado, caza iniciada) —la única que justifica el equipo—; tasa de falso positivo por
fuente; y **edad media del indicador activo** (si sube, el decaimiento no funciona).
❌ **No son métricas**: número de indicadores, de informes leídos ni de feeds.

## 5. Seguridad, marcado y atribución

- **TLP se aplica verbatim y se propaga a todo derivado.** Reetiquetar a la baja un producto ajeno
  es una ruptura de confianza que expulsa de la comunidad de compartición, y esa expulsión es
  permanente. Ante duda de nivel, **se pregunta al emisor**.
- **PAP (Permissible Actions Protocol) es distinto de TLP y hay que respetarlo por separado**:
  regula qué acciones puedes ejecutar con el dato (resolver un dominio, escanear una IP, detonar una
  muestra) sin avisar al adversario. **Consultar la infraestructura del atacante desde tu IP
  corporativa es contrainteligencia gratis para él.**
- **OPSEC del propio equipo de CTI**: infraestructura de investigación separada de la corporativa,
  identidades de investigación gestionadas, sin credenciales corporativas en fuentes hostiles,
  y sandbox de detonación aislado (`ctf-lab-standards` para el laboratorio).
- **La plataforma de CTI es un objetivo de alto valor**: contiene lo que sabes del adversario y, por
  tanto, lo que no sabes. MISP/OpenCTI **nunca expuestos a Internet sin autenticación fuerte y
  segmentación**; y ojo con las CVEs de la propia plataforma (verificado: MISP publicó en 2026
  correcciones de inyección SQL, escalada de privilegios y RCE — es software de seguridad, no
  software seguro).
- **Dato personal**: un indicador puede ser una IP o un correo de una persona identificable.
  Compartirlo necesita base jurídica y minimización (`privacy-engineering-standards`). **"Es un
  IoC" no es una base legal.**
- **Atribución — la sección que hay que decir sin adornos**:
  - **Casi nunca cambia una decisión defensiva.** Saber que el actor es "APT-loquesea" no altera qué
    parcheas, qué detectas ni cómo contienes. Lo que sí lo altera es su **TTP**, y esa se obtiene sin
    atribuir.
  - Se escribe con **lenguaje de confianza analítica explícito** ("evaluamos con confianza
    moderada…"), separando **observación**, **inferencia** y **suposición**. Nunca una afirmación
    plana.
  - **Los indicadores de atribución son falsificables por diseño**: infraestructura reutilizada,
    huella de idioma, horario de compilación, herramientas filtradas y públicas. Las *false flags*
    son una técnica documentada, no una hipótesis exótica.
  - **La atribución con consecuencias legales, diplomáticas o de seguro no la hace un equipo de
    CTI corporativo.** Se escala; no se publica.

## 6. Operación

- **Automatiza la ingesta y la caducidad; no automatices el análisis.** Volumen frente a criterio.
- **Sincronización MISP entre organizaciones**: define y revisa en qué dirección fluye cada
  distribución — una regla de sync mal puesta publica hacia fuera lo que era interno, y es el
  incidente clásico de esta herramienta.
- **Presupuesto de ingesta**: cada indicador enviado al SIEM cuesta almacenamiento y correlación
  (`finops-standards`, `soc-operations-standards`). Enviar la plataforma entera al SIEM rompe el
  presupuesto sin mejorar una detección.
- **Retención**: el indicador caducado **no se borra, se archiva** — sirve para *hunting*
  retrospectivo y para el forense. Caducar ≠ olvidar.
- **Continuidad**: la plataforma se respalda y su restauración se prueba (`backup-recovery`); el
  grafo de conocimiento acumulado no se reconstruye.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: la versión de ATT&CK se revisa cada release y la migración se planifica (§2); las
  plataformas se parchean con SLA de software expuesto, no de herramienta interna.
- **Todo producto tiene fecha de revisión y dueño.** Un perfil de actor de hace tres años sin
  revisar es desinformación con tu logo.

- ❌ **PROHIBIDO publicar o ingerir un indicador sin fecha de caducidad.** Regla número uno.
- ❌ Bloquear con un feed que no ha pasado una prueba en modo observación (§4).
- ❌ Enviar la plataforma de CTI completa al SIEM "por si acaso".
- ❌ Reetiquetar TLP a la baja, o usar `TLP:WHITE` (retirado en TLP 2.0) y dialectos locales.
- ❌ Ignorar el PAP: consultar, escanear o detonar infraestructura del adversario desde
  infraestructura corporativa atribuible.
- ❌ Publicar una atribución como hecho, o dejarla influir en la respuesta técnica (§5).
- ❌ Copiar el mapeo ATT&CK del informe de un proveedor y presentarlo como cobertura propia.
- ❌ Usar métricas de volumen (nº de IoC, feeds o informes) como salud del programa.
- ❌ Comprar un feed sin PIR que lo justifique, o que el equipo no pueda consumir.
- ❌ Escribir detecciones aquí (`detection-engineering-standards`) o duplicar el modelo de
  priorización de vulnerabilidades: **EPSS y KEV son de `vulnerability-management-standards`**.
- ❌ Exponer MISP/OpenCTI a Internet sin segmentación, MFA y parcheo al día.
- ❌ Compartir indicadores con dato personal sin base jurídica ni minimización.
- ❌ Dar por buena la licencia de una plataforma de CTI por lo que dice su web: **se lee el
  `LICENSE` en crudo** (§2 — OpenCTI **no** es AGPL).
- ❌ Tratar un resumen generado por LLM de un informe de amenazas como producto de inteligencia sin
  verificación humana contra la fuente.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Versión vigente de MITRE ATT&CK** en `attack.mitre.org/resources/updates/` (a ago-2026: **v19,
   publicada el 28-abr-2026**, con datos v19.0 y v19.1 en MITRE/CTI) y **qué cambió respecto a la
   que usan tus mapeos**. Los dos cambios que rompen cosas en silencio: **v18** (Data Sources y
   Detections → **Detection Strategies `DET…` + Analytics `AN…`**) y **v19** (**`TA0005` = Stealth**,
   **`TA0112` = Defense Impairment**, `T1562`→`T1685`, solo Enterprise). **Usa el crosswalk oficial
   del split, no una conversión propia.**
2. **STIX/TAXII**: que 2.1 sigue siendo la versión OASIS Standard vigente y si hay trabajo hacia 2.2
   (`oasis-tcs/cti-stix2`). A ago-2026 no consta 2.2 publicado.
3. **TLP**: versión vigente en `first.org/tlp` y **el texto exacto de cada etiqueta** (verificado:
   TLP 2.0, autoritativa desde ago-2022). Si tu documentación cita TLP 1.0, está caducada.
4. **MISP**: release vigente en `misp-project.org` (**la web del proyecto, no el feed de GitHub**) y
   **los avisos de seguridad de la plataforma**, que en 2026 incluyeron SQLi, escalada de
   privilegios y RCE. Licencia verificada en crudo: **AGPLv3**.
5. **OpenCTI**: versión vigente y, sobre todo, **qué funciones quedan en Enterprise Edition** —
   cambia entre releases y decide si el proyecto es viable con la Community. Licencia verificada en
   crudo: **Community = Apache-2.0; Enterprise = licencia propietaria de Filigran**. Consulta
   `opensource-licensing-standards` antes de comprometer arquitectura.
   - **Hueco declarado**: OpenCTI usa un esquema de versión por fecha (serie 7.26xxxx en 2026) y
     **no pude fijar por web con garantías el número exacto de la release vigente ni las condiciones
     de la licencia LTS**; se verifica en `docs.opencti.io` antes de planificar una actualización.
6. **Feeds que uses**: estado, cadencia y condiciones de uso — muchos feeds abiertos cambian de
   licencia o desaparecen sin aviso, y su URL sobrevive devolviendo datos viejos.
7. **Marco regulatorio de compartición** aplicable (NIS2, DORA, obligaciones sectoriales del ISAC en
   el que participes): lo fija `grc-compliance-standards`, pero **verifica que el nivel de marcado
   que usas es compatible con tu obligación de notificar**.
8. **Estudios de calidad de feeds**: la referencia usada aquí es *Reading the Tea Leaves* (USENIX
   Security '19). **Es de 2019: busca medición más reciente antes de citarla como estado del arte** —
   el mecanismo (bajo solapamiento, alta rotación de IPs) sigue siendo válido; las cifras concretas
   pueden no serlo.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
