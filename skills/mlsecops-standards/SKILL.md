---
name: mlsecops-standards
description: Security of the model lifecycle and the AI supply chain. Use when verifying provenance and integrity of third-party model weights, preferring safetensors over pickle-backed formats (.pt, .bin, joblib, Keras Lambda layers) and auditing trust_remote_code, scanning weights with picklescan or modelscan and understanding their evasion limits, signing model artifacts and pinning them by digest in a model registry, triaging an AI-stack supply-chain compromise (the LiteLLM PyPI backdoor and its .pth persistence, a poisoned CI scanner, malicious models or agent skills in a public hub), producing an AIBOM or ML-BOM with CycloneDX or the SPDX AI profile, handling data and model poisoning, model backdoors, query-based extraction and unauthorized distillation, model inversion and membership inference as risk classes with indicators and mitigations, rate limiting and anomalous-use detection on a deployed inference endpoint, hardening the training pipeline and its compute isolation, running AI red teaming with garak, PyRIT or promptfoo redteam, or mapping controls to MITRE ATLAS, the OWASP GenAI Top 10 (LLM and ASI), NIST AI RMF and AI 600-1, or EU AI Act Article 15.
---

# Estándares de MLSecOps — seguridad del ciclo de vida y la cadena de suministro de IA

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **asegurar el ciclo de vida del modelo y su cadena de suministro**: procedencia e
integridad de los pesos, formatos de serialización y su capacidad de ejecución arbitraria, escaneo
y firma de artefactos de modelo, inventario (AIBOM), seguridad del pipeline de entrenamiento y del
registro de modelos, el endpoint desplegado como superficie de ataque, las clases de riesgo propias
del ciclo de vida (envenenamiento, puertas traseras, extracción, inversión, inferencia de
pertenencia, ejemplos adversarios), la metodología de red teaming **de IA**, y el mapeo a los marcos
vigentes (ATLAS, OWASP GenAI, NIST AI RMF, AI Act art. 15).

**Postura**: **defensiva y autorizada, siempre.** Los ataques se describen como **clase de riesgo,
indicador y mitigación**; nunca como procedimiento reproducible. Ver §7.

**Tesis del dominio**: **un modelo de terceros es un binario de terceros.** Un fichero de pesos
descargado de un hub público tiene el mismo perfil de confianza que un ejecutable bajado de
internet — y, en varios formatos de uso masivo, **literalmente ejecuta código al cargarse**. Todo lo
que sigue deriva de tratarlo como tal: procedencia, integridad, firma, escaneo, aislamiento.

**Segunda tesis**: **la cadena de suministro de IA es la cadena de suministro de software, más los
datos y los pesos.** No la sustituye: la extiende. Los incidentes reales de 2026 no fueron ataques
exóticos contra modelos, sino compromisos clásicos de CI y de repositorios de paquetes que llegaron
a la IA (§3.3). **El control que más riesgo de IA elimina sigue siendo fijar dependencias por
digest.**

Triggers: `.safetensors`, `.pt`, `.pth`, `.bin`, `.ckpt`, `.pkl`, `.gguf`, `.h5`/`.keras`,
`torch.load`, `weights_only`, `pickle`, `joblib.load`, `trust_remote_code=True`, `from_pretrained`,
`picklescan`, `modelscan`, "modelo malicioso", "hub público", "Hugging Face", "registro de modelos",
`MLflow`, "firmar el modelo", "AIBOM", "ML-BOM", "CycloneDX", "SPDX AI profile", "envenenamiento de
datos", "data poisoning", "puerta trasera en el modelo", "backdoor", "extracción del modelo",
"destilación no autorizada", "inversión del modelo", "inferencia de pertenencia", "membership
inference", "ejemplo adversario", "red team de IA", `garak`, `PyRIT`, `promptfoo redteam`,
`deepteam`, "MITRE ATLAS", `AML.T`, `AML.CS`, "OWASP Top 10 LLM", `ASI01`, "NIST AI RMF",
"AI 600-1", "AI Act artículo 15", "LiteLLM", "TeamPCP".

**No aplica**: ver
`llm-app-engineering-standards` (**la inyección de prompt es suya**, junto con tratar la salida del
modelo como entrada no confiable, la salida estructurada y los límites de gasto. **No la reclamo**:
aquí solo aparece como una técnica más del catálogo ATLAS cuando se mapea cobertura);
`ai-agents-standards` (contención del agente, sandbox, egress, aprobación humana de acciones
irreversibles, tríada letal, riesgos agénticos OWASP ASI01–ASI10 aplicados al diseño del bucle);
`rag-standards` (control de acceso por documento sobre los fragmentos recuperados y borrado del
índice — el envenenamiento del corpus de recuperación se **mitiga** allí; aquí es una clase de
riesgo del ciclo de vida);
`mcp-standards` (tool poisoning, rug pull, server shadowing y autorización de servidores MCP);
`claude-api` (**skill instalada, referencia canónica del lado Anthropic**: nada de modelos Claude
—id, precio, límites, parámetros— se afirma de memoria);
`appsec-standards` (**clases de vulnerabilidad de aplicación** —IDOR, SSRF, XSS, deserialización
insegura como categoría, STRIDE, ASVS— y selección de SAST/DAST/SCA. Aquí, la deserialización
insegura **aplicada al artefacto de modelo** y las clases propias del ciclo de vida de IA);
`offensive-security-standards` (**el ejercicio autorizado y su gobierno son suyos, sin excepción**:
autorización por escrito, RoE, alcance, ventana, deconfliction, condiciones de parada, informe,
retest, encuadre legal. **Frontera precisa: si la pregunta es "¿puedo atacar esto y bajo qué
papel?", es suya; si es "¿qué se prueba en un sistema de IA y con qué método?", es mía.** El red
teaming de IA de §3.7 se ejecuta **dentro** de sus RoE, nunca fuera);
`llm-evaluation-standards` (el aparato de medición. **Frontera declarada en
ambos lados: la metodología de ataque adversario es mía; el conjunto de casos, el juez, la rúbrica,
el umbral y el gate de CI con que se mide son suyos.** Un hallazgo de red team se convierte en un
caso de su eval set: ese es el handoff);
`vulnerability-management-standards` (**triaje de CVE, CVSS/EPSS/KEV, SLA de remediación y VEX. Los
CVE del stack de ML —`torch`, `transformers`, servidores de inferencia, arneses— entran por ahí**,
no por aquí);
`cicd-standards` (**SBOM, firma con cosign/Sigstore y procedencia SLSA en el pipeline son suyos**,
igual que el endurecimiento de runners y la identidad efímera por OIDC. **Aquí solo lo específico
del modelo**: qué se firma cuando el artefacto son pesos, y qué se inventaría cuando además hay
datos);
`cryptography-pki-standards` (la primitiva de firma, la elección de algoritmo y la custodia y
rotación de claves);
`secrets-management-standards` (gestor, credenciales efímeras, rotación — el incidente de §3.3 es un
caso de robo de credencial de CI, y la mitigación estructural es suya);
`container-runtime-security-standards` y `kubernetes-standards` (aislamiento del cómputo donde se
carga un modelo no confiable: seccomp, capabilities, non-root, admisión);
`detection-engineering-standards` (**autoría y ciclo de vida de la regla**: Sigma, YARA, tests,
cobertura ATT&CK. Aquí se dice **qué evento de IA debe emitirse y qué anomalía importa**; la regla se
escribe y se gobierna allí);
`incident-response-forensics-standards` (respuesta técnica y forense al compromiso, cadena de
custodia, erradicación y rotación masiva de credenciales);
`privacy-engineering-standards` (**dato personal en el entrenamiento, memorización del modelo,
desidentificación, derechos del interesado y el encaje de sistemas de IA en el RGPD/AI Act: ya lo
cubre — no se duplica aquí**. La inferencia de pertenencia aparece en §3.5 como **clase de riesgo
técnico**; su tratamiento como riesgo de privacidad es suyo);
`grc-compliance-standards` (marco de gestión, SoA, evidencia de auditoría, aceptación formal de
riesgo);
`ai-governance-standards` (AI Act como régimen, políticas, inventario de
sistemas de IA y gestión del riesgo organizativo. **Frontera: el gobierno es suyo, el control
técnico verificable es mío.** Si se responde con un documento firmado, es suyo; si se responde
ejecutando un escaneo o una verificación de firma, es mío);
`mlops-standards` (el ciclo de vida operativo de un modelo propio —versionado de
datasets con DVC/lakeFS, experimentos en MLflow/W&B, registro de modelos con *model cards*, estados y
aprobación, orquestación del entrenamiento, *feature store*, despliegue canario y rollback de pesos,
deriva y reentrenamiento—. **Esta skill es su cara de seguridad**: `mlops` define el registro y la
promoción entre entornos; yo defino cómo se protege, se firma, se aísla y se audita esa cadena. La
reproducibilidad es requisito de calidad allí y **control de seguridad aquí** (§3.10));
`local-inference-standards` (servir pesos abiertos en infraestructura propia: motor, cuantización,
dimensionado, seguridad del endpoint como puerto);
`gpu-computing-standards` (la GPU como recurso: driver, MIG/MPS, aislamiento del acelerador);
`data-platform-standards` (dónde viven los datos de entrenamiento y su cifrado en reposo);
`iac-standards`, `identity-access-management-standards`, `bcdr-standards` (infraestructura,
identidad y recuperación del entorno de ML).

## 2. Decisiones por defecto

> Verificar la última versión y el estado de mantenimiento por web antes de fijar nada (§8). Este
> ecosistema tiene alta mortalidad de herramientas y **repositorios que se archivan y se mueven**.

| Decisión | Por defecto | Motivo |
|---|---|---|
| Formato de pesos | **`safetensors`, siempre que exista** | Solo almacena tensores: sin código ejecutable ni ganchos de deserialización. Es el único formato de uso masivo diseñado para eliminar esta clase de ataque |
| Formatos con ejecución arbitraria al cargar | **Vetados sin sandbox**: pickle y todo lo que lo envuelve (`.pkl`, `.pt`/`.bin`/`.ckpt` de PyTorch clásicos, `joblib`), y modelos Keras con capas `Lambda` | La deserialización de pickle **ejecuta código por diseño**. La documentación del propio módulo lo advierte |
| `torch.load` sobre origen no plenamente confiable | **`weights_only=True`** (y verificar el default de tu versión) | Restringe lo que se puede deserializar. Mitiga, **no elimina** — hay investigación sobre evasión de cargadores restringidos |
| `trust_remote_code=True` | **PROHIBIDO por defecto** | Equivale a ejecutar un binario arbitrario de internet. Hay CVE reciente de RCE por hardcodearlo (§3.2) |
| Origen de los pesos | **Réplica interna con digest fijado**, no descarga directa del hub en runtime | Un pull en tiempo de despliegue contra un hub público es una dependencia mutable en el camino crítico |
| Identificación del artefacto | **Digest criptográfico (SHA-256), nunca un tag ni "latest"** | Mismo principio que las imágenes de contenedor. Un tag es mutable |
| Firma y verificación | **cosign/Sigstore sobre el artefacto de modelo**, verificación **antes de cargar** | Mecánica y custodia de claves: `cicd-standards` y `cryptography-pki-standards` |
| Escaneo de modelos | **`picklescan` y/o `modelscan` como gate**, con expectativas calibradas (§3.2) | Son listas de denegación: detectan lo conocido. **Necesarios, insuficientes** |
| Carga de un modelo no verificado | **Sandbox sin red ni credenciales**, usuario sin privilegios, FS de solo lectura | La carga **es** ejecución. Contención: `container-runtime-security-standards` |
| Inventario | **AIBOM/ML-BOM en CycloneDX** para el pipeline; perfil AI de SPDX cuando el destinatario es regulatorio | Ver §3.4 sobre madurez real |
| Marco de amenazas | **MITRE ATLAS** como taxonomía de referencia, **complementando ATT&CK** | §3.8 |
| Catálogo de riesgo de aplicación | **OWASP Top 10 for LLM Applications 2025** + **Top 10 for Agentic Applications 2026 (ASI01–ASI10)** | §3.8 |
| Red teaming de IA | **`garak`** (barrido amplio, CI) + **PyRIT** (campañas multi-turno) + **promptfoo redteam** (en PR) | §3.7 |

### Estado verificado de las herramientas (agosto 2026)

| Herramienta | Versión | Fecha | Notas |
|---|---|---|---|
| `garak` (NVIDIA) | 0.15.1 | 2026-06-05 | **Vivo**, repo activo. Escáner de sondas a nivel de modelo |
| **PyRIT (Microsoft)** | v1.0.1 | 2026-07-30 | ⚠️ **El repositorio se movió**: `Azure/PyRIT` está **archivado** (2026-03-27). El activo es **`microsoft/PyRIT`**. Cualquier tutorial que apunte a `Azure/PyRIT` está obsoleto |
| `promptfoo` (modo redteam) | 0.121.20 | 2026-07-31 | Vivo, cadencia alta. Gobierno: verificar la adquisición por OpenAI (§8) |
| `picklescan` | 1.0.5 | 2026-07-01 | Vivo. Integrado en el pipeline de escaneo de Hugging Face |
| `modelscan` (Protect AI) | 0.8.8 | 2026-02-18 | ⚠️ **~6 meses sin release.** Úsalo, pero pinea versión y no lo tomes como control único |
| `deepteam` | v1.0.4 | 2025-11-12 | ⚠️ **Sin releases en ~9 meses.** No adoptar para trabajo nuevo sin reevaluar |
| CycloneDX (spec) | 1.7 (2025-10-21), parches 1.7.1 (2026-06-02) | — | ECMA-424; verificar la edición vigente (§8) |
| SPDX (spec) | 3.0.1 (2024-12-17), **3.1-RC1** (2026-01-24) | — | El AI Profile vive en la línea 3.x. ISO/IEC 5962:2021 codifica **SPDX 2.2.1**, no la actual |
| MITRE ATLAS | contenido **v2026.06** (2026-06-30), formato **v6.0.0** | — | §3.8 |

## 3. Estructura y convenciones

### 3.1 El modelo como artefacto de software

Los tres controles no negociables, en orden:

1. **Procedencia**: de dónde salió, quién lo publicó, qué versión exacta, contra qué datos se
   entrenó (hasta donde sea conocible), y qué licencia lleva. Sin procedencia registrada no hay
   respuesta posible a "¿estamos afectados?" cuando el hub retira un modelo.
2. **Integridad**: digest calculado en la ingesta y verificado antes de cada carga. **Se referencia
   siempre por digest**, nunca por nombre ni por tag.
3. **Firma**: el artefacto se firma al entrar en el registro interno y **la firma se verifica antes
   de cargar**, no solo al desplegar. Una verificación que solo ocurre en el pipeline no protege
   contra la sustitución del fichero en el almacén.

**Corolario operativo**: el registro de modelos es un **activo de nivel producción**, no un cajón de
`.ckpt` en un bucket compartido. Control de acceso con mínimo privilegio, escritura auditada,
inmutabilidad de versiones publicadas, y separación de quien entrena, quien promueve y quien
despliega. Un atacante con escritura en el registro no necesita ningún ataque de IA: sustituye el
fichero.

### 3.2 Pesos de terceros = binarios de terceros

**Formatos que ejecutan código al cargar** (clase de riesgo: deserialización insegura /
ejecución arbitraria):

- **Pickle y todo lo construido encima**: `.pkl`, los `.pt`/`.bin`/`.ckpt` clásicos de PyTorch,
  `joblib`. El mecanismo es el gancho de reconstrucción del propio protocolo — no un bug, **el
  diseño**. El intérprete de pickle procesa opcodes según llegan, **sin validar antes que el fichero
  sea íntegro**, lo que habilita técnicas de evasión basadas en ficheros deliberadamente corruptos.
- **Keras/TensorFlow con capas `Lambda`**: ejecutan código Python arbitrario embebido en el modelo.
  El problema no es exclusivo de pickle.
- **`trust_remote_code=True`**: descarga y ejecuta código del repositorio del modelo. Existe CVE
  reciente (**CVE-2026-6859**, InstructLab, verificar) por hardcodearlo en un script de
  entrenamiento: bastaba un modelo malicioso en el hub para lograr RCE en cualquier usuario. **No
  requiere ninguna evasión de escáner: es la funcionalidad haciendo su trabajo.**

**Formato seguro recomendado**: **`safetensors`** — almacena únicamente datos tensoriales, sin código
ni ganchos de deserialización. Es la elección por defecto y, cuando un modelo solo se publica en
formato pickle, eso es en sí mismo una señal de riesgo a evaluar (y, si se acepta, la conversión a
safetensors se hace **dentro del sandbox**, no en la estación del ingeniero).

**Escaneo de modelos — necesario, insuficiente, y hay que decirlo:**

- `picklescan` y `modelscan` funcionan por **lista de denegación** de funciones peligrosas. Detectan
  lo conocido.
- Historial verificado de evasión: JFrog reportó **tres 0-days en `picklescan`** (corregidos en
  0.0.31, sept-2025), cada uno permitiendo evadir la detección; la técnica **nullifAI**
  (ReversingLabs) evadió el escaneo del hub con un pickle deliberadamente roto; y trabajo académico
  reciente (**ShadowPickle**) reporta evasión de **diez escáneres y cuatro hubs de modelos**.
- **Un hub público que marca un modelo como "unsafe" normalmente no lo bloquea**: te deja
  descargarlo y ejecutarlo bajo tu responsabilidad. La etiqueta no es un control.
- Consecuencia: **el escáner es un gate de higiene, no una garantía.** El control que realmente
  acota el daño es **el aislamiento en la carga** más **preferir safetensors**.

**Incidentes reales verificados** (usar como argumento, no como anécdota): se han encontrado modelos
maliciosos en hubs públicos que abren una shell inversa hacia una IP externa al cargarse; se reporta
un incremento interanual del orden de **5×** en la tasa de subida de modelos maliciosos; y en
febrero de 2026 se detectaron **341 *skills* maliciosas** en un registro público de skills de
agentes distribuyendo un infostealer. **El repositorio público de artefactos de IA es hoy un vector
de distribución de malware activo.**

### 3.3 La cadena de suministro de IA — el caso didáctico de 2026

El compromiso de **LiteLLM en PyPI (marzo de 2026)** es el ejemplo canónico de que **la cadena de
suministro de IA se rompe por donde se rompe cualquier cadena de suministro de software**. Cadena
verificada:

1. **19 de marzo**: el actor (**TeamPCP**) compromete las GitHub Actions de **Trivy** — un escáner de
   seguridad de código abierto. Como la mayoría de pipelines referencian Actions por **tag mutable
   en lugar de commit SHA fijado**, las organizaciones que ejecutaban Trivy en CI empezaron a
   ejecutar el código malicioso de inmediato.
2. Entre las credenciales cosechadas estaba el **token de publicación en PyPI de LiteLLM**, cuyo
   pipeline invocaba Trivy en un script de escaneo de secretos y CVE.
3. **24 de marzo**: se publican `litellm` **1.82.7** y **1.82.8** con payload malicioso. La 1.82.8,
   ~13 minutos después, añade **persistencia mediante un fichero `.pth`** (`litellm_init.pth`).
4. **El mecanismo `.pth` es lo que hay que entender**: el módulo `site` de Python **ejecuta** el
   contenido de cualquier `.pth` en `site-packages` durante la inicialización del intérprete —
   **antes de cualquier `import` y antes de cualquier código de aplicación**. No hace falta importar
   la librería: `python --version` basta para dispararlo. El payload iba doblemente codificado en
   base64 para reducir la visibilidad ante análisis estático básico.
5. **Payload**: cosecha de credenciales (más de 50 categorías: claves SSH, AWS con IMDSv2 y Secrets
   Manager, GCP, Azure, Kubernetes, `.env`, historial de shell, credenciales de git, registros
   Docker, estado de Terraform), **movimiento lateral en Kubernetes** (lectura de secretos en todos
   los namespaces, creación de pods privilegiados montando el filesystem del host) y backdoor
   persistente vía servicio systemd de usuario. Exfiltración cifrada (AES-256-CBC con clave de sesión
   envuelta en RSA-4096) hacia un dominio no afiliado al proyecto.
6. **Ventana**: ~40 minutos hasta la cuarentena en PyPI. Se reportan decenas de miles de
   instalaciones en ese intervalo. La campaña continuó con `telnyx` (27 de marzo) y otros registros.
7. **Quién no se vio afectado**: los despliegues que **fijaban dependencias** en un `requirements.txt`
   dentro de la imagen oficial.

**Lecciones que se convierten en control, no en anécdota:**

- **Fijar por digest/SHA, no por tag**, tanto las GitHub Actions como las dependencias y las imágenes
  base. Es el control que separó a los afectados de los no afectados.
- **Instalar un paquete es ejecutar código.** No hay "instalar y luego revisar".
- **Un escáner de seguridad en tu CI es una dependencia con credenciales.** El eslabón comprometido
  fue una herramienta *defensiva*. Aplícale el mismo criterio que a cualquier otra dependencia.
- **Credenciales de publicación efímeras** (OIDC / *trusted publishing*) en lugar de tokens estáticos
  de larga vida → `cicd-standards`, `secrets-management-standards`.
- **Un host o job de CI que instaló el artefacto comprometido se trata como exposición completa de
  credenciales**, no como "revisar si el paquete está presente": rotación masiva, búsqueda de
  persistencia y revisión de actividad en Kubernetes → `incident-response-forensics-standards`.
- El **precedente del catálogo** es coherente: los CVE y el estado de mantenimiento del stack de ML
  (`torch`, `transformers`, servidores de inferencia, arneses) se gobiernan por
  `vulnerability-management-standards`; lo específico de IA es que **los pesos y los datos son dos
  eslabones más**, y no los cubre ningún SCA clásico.

### 3.4 AIBOM / ML-BOM — estado real, sin optimismo

Un SBOM clásico no inventaría ni pesos, ni datos de entrenamiento, ni la procedencia del modelo. De
ahí el AIBOM. **Estado honesto a agosto de 2026: es un estándar emergente, no maduro.**

- **CycloneDX** soporta ML-BOM/AI-BOM y es la opción práctica para CI. Spec **1.7** publicada
  2025-10-21 (con parches 1.7.x en 2026), adoptada como **ECMA-424**. Es la línea con más tracción en
  herramientas.
- **SPDX 3.x** define un **AI Profile** y un **Dataset Profile** (tipo de modelo, método de
  entrenamiento, tratamiento de datos, explicabilidad, limitaciones, consumo energético). Estado:
  **3.0.1** (dic-2024) con **3.1-RC1** (ene-2026). **Aviso**: la norma ISO/IEC 5962:2021 codifica
  **SPDX 2.2.1**, no la versión con perfil de IA — citar "SPDX es ISO" como prueba de madurez del
  AIBOM es incorrecto.
- **Realidad de campo**: la herramienta genera lo que el modelo upstream declaró. Si el publicador no
  documentó datos ni licencia, **el AIBOM sale con huecos** — algunos generadores puntúan
  explícitamente esa incompletitud, y esa puntuación es el dato útil.

**Criterio**: genera AIBOM porque el inventario es prerrequisito de todo lo demás (y porque la
contratación empieza a exigirlo), pero **no lo trates como control de seguridad**. Es un inventario,
y un inventario con huecos declarados. El control sigue siendo digest + firma + escaneo + sandbox.

### 3.5 Ataques del ciclo de vida — clase de riesgo, indicador, mitigación

**Descritos como riesgo. Nunca como receta.**

| Clase | Riesgo | Indicadores | Mitigación |
|---|---|---|---|
| **Envenenamiento de datos** | Manipular el corpus de entrenamiento o de ajuste para degradar o sesgar el modelo | Contribuciones anómalas al dataset; deriva de calidad tras reentrenar; muestras duplicadas o casi duplicadas de un único origen | Procedencia y control de acceso del dataset; curación y revisión de fuentes externas; detección de anomalías/duplicados; **reproducibilidad para poder bisecar qué lote lo causó** |
| **Envenenamiento del modelo / puerta trasera** | Comportamiento malicioso latente que se activa con un disparador concreto | Discrepancia entre métricas agregadas (buenas) y comportamiento en casos específicos; artefacto sin procedencia | Solo modelos con procedencia y firma; evaluación con casos adversarios (§3.7 → `llm-evaluation-standards`); reentrenamiento controlado sobre datos verificados |
| **Envenenamiento del corpus de recuperación** | Insertar contenido en la base que el sistema recupera | Documentos nuevos con instrucciones embebidas; picos de recuperación de una fuente concreta | Control de acceso de escritura al corpus; tratar el contenido recuperado como no confiable → `rag-standards`, `llm-app-engineering-standards` |
| **Extracción / destilación no autorizada** | Reconstruir capacidad del modelo consultando su API masivamente | Volumen anómalo de consultas por cuenta; consultas sistemáticas o de alta entropía; **muchas cuentas nuevas con patrón común**; picos de consumo desalineados con uso de producto | Límites de tasa y cuotas por usuario/organización; detección de uso anómalo; verificación de identidad en el alta; §3.6 |
| **Inversión del modelo** | Reconstruir características del dato de entrenamiento a partir de las salidas | Consultas dirigidas a extraer memorizaciones; salidas que reproducen literalmente fragmentos de entrenamiento | Minimización del dato de entrenamiento y desidentificación → `privacy-engineering-standards`; límite de detalle en las salidas; filtrado de salida |
| **Inferencia de pertenencia** | Determinar si un registro concreto estuvo en el entrenamiento | Consultas repetidas sobre registros específicos | **Ver nota de realismo abajo.** Minimización, evitar sobreajuste, privacidad diferencial cuando el riesgo lo justifique → `privacy-engineering-standards` |
| **Ejemplos adversarios** | Entradas perturbadas que inducen una clasificación o comportamiento erróneo | Tasa de error concentrada en entradas cercanas entre sí; entradas con perturbaciones imperceptibles | Robustez como requisito (AI Act art. 15); validación en el borde; detección de entradas fuera de distribución; redundancia de decisión en usos críticos |

**Nota de realismo — laboratorio frente a producción.** Es obligatorio distinguirlos:

- **La extracción por consulta es una amenaza demostrada a escala industrial.** En febrero de 2026,
  proveedores frontera divulgaron campañas de extracción contra sus modelos (del orden de **10⁵
  prompts** en una campaña, y decenas de miles de cuentas fraudulentas generando millones de
  intercambios en otra). **Esto ya no es teórico: dimensiona los límites de tasa en consecuencia.**
- **La inferencia de pertenencia rinde mucho peor de lo que sugieren los titulares.** Trabajo
  sistemático sobre modelos preentrenados encuentra que la mayoría de ataques **apenas superan el
  azar** cuando el preentrenamiento es de ~1 época (poco sobreajuste). Es **materialmente más
  relevante sobre modelos ajustados finamente o con datos muy repetidos**. Trátalo como riesgo real
  pero **condicionado al régimen de entrenamiento**, no como amenaza universal.
- **El envenenamiento y las puertas traseras están sobradamente demostrados en laboratorio**; su
  explotación en producción exige acceso al pipeline o al artefacto — que es exactamente lo que
  protegen §3.1–§3.3. **La mitigación real es de cadena de suministro, no de ML.**

### 3.6 El modelo desplegado como superficie

- **Límites de tasa y cuotas por usuario y por organización**, no solo globales. El global no frena
  una campaña de extracción distribuida entre cuentas.
- **Detección de uso anómalo** como control de primera clase: volumen, entropía y sistematicidad de
  las consultas, altas masivas de cuentas correlacionadas, patrones de barrido. Qué se registra y qué
  alerta: §3.9; la autoría de la regla es de `detection-engineering-standards`.
- **Verificación de identidad y fricción en el alta** cuando el endpoint expone capacidad valiosa.
- **Marca de agua (watermarking): valor preventivo bajo.** Es un instrumento **forense y post hoc**:
  cuando detectas la marca, el modelo sustituto ya está entrenado. La literatura vigente la clasifica
  como herramienta de **atribución y litigio**, no de defensa, y su robustez frente a destilación
  y paráfrasis sigue siendo el problema abierto. **No la vendas internamente como protección.**
- **Protección contra destilación no autorizada**: los controles que funcionan son los aburridos —
  límites, cuotas, detección de anomalías, términos de servicio ejecutables y correlación entre
  cuentas. Las defensas técnicas (perturbación de salida, resistencia a destilación) son área activa
  de investigación, **no producto**. Con el modelo accesible públicamente, **no existe barrera
  infalible**: el objetivo realista es **encarecer y detectar**, no impedir.

### 3.7 Red teaming de IA — metodología

**Precondición dura**: se ejecuta dentro de un ejercicio autorizado. **La autorización por escrito,
las RoE, el alcance, la ventana, la deconfliction, las condiciones de parada y el informe son de
`offensive-security-standards` y no se improvisan aquí.** Lo que aporta esta skill es la metodología
específica de IA.

**Qué lo distingue del pentest clásico:**

- El objetivo no es solo la ejecución de código: es **el comportamiento del sistema**. Un fallo puede
  ser una salida, no un shell.
- **No es determinista**: un ataque que funciona una vez puede no repetirse. Un hallazgo sin tasa de
  éxito medida sobre N intentos no es un hallazgo, es una anécdota → el aparato de medición es de
  `llm-evaluation-standards`.
- La superficie incluye **datos, pesos, prompt, herramientas y memoria**, no solo red y aplicación.
- **Dos objetivos que se solapan pero no son el mismo**: *safety* (contenido dañino, violación de
  política) y *security* (exfiltración, compromiso del sistema, uso no autorizado de herramientas).
  Declara cuál persigues; los equipos, los criterios y los destinatarios del informe difieren.

**Organización recomendada** (alineada con la práctica de la industria y con el ciclo de NIST AI RMF
— *Govern, Map, Measure, Manage*):

1. **Map**: modelar el sistema y sus riesgos a partir de ATLAS y del Top 10 aplicable (LLM o ASI).
2. **Measure**: automatizar la amplitud — barrido de sondas en CI en cada despliegue de modelo.
3. **Manage**: profundidad manual y multi-turno sobre lo crítico, con periodicidad definida;
   mitigación y monitorización en producción con plan de respuesta.
4. **Handoff**: **cada hallazgo se convierte en un caso permanente del conjunto de evaluación**
   (`llm-evaluation-standards`) y, si procede, en una regla de detección
   (`detection-engineering-standards`). **Un red team cuyo resultado es solo un PDF es dinero
   quemado**: la mitad del valor está en la regresión que deja instalada.

**Herramientas vigentes** (versiones en §2):

- **`garak`** — escáner de sondas a nivel de modelo. Amplitud y regresión, barato, encaja en CI.
  Cobertura agéntica y de RAG limitada.
- **PyRIT** (`microsoft/PyRIT`, **ojo al cambio de repositorio**) — orquestación programable de
  campañas multi-turno. Profundidad sobre aplicaciones críticas.
- **`promptfoo` en modo redteam** — regresión adversaria en el PR, con presets mapeados al Top 10 de
  OWASP.
- **Nunca sustituyen a la medición sistemática.** Red teaming es exploración dirigida; la cobertura y
  el umbral son evaluación.

**Prohibido**: incluir en documentación interna payloads listos para usar, jailbreaks concretos de
producto de terceros o bypasses de guardrail específicos. Se documenta **la clase de técnica, el
indicador y la mitigación**, con referencia al identificador del marco (p. ej. la técnica ATLAS
correspondiente).

### 3.8 Marcos

- **MITRE ATLAS** — el ATT&CK de la IA. Base de conocimiento de tácticas, técnicas, mitigaciones y
  casos reales contra sistemas de IA (`AML.T*`, `AML.M*`, `AML.CS*`).
  - **Relación con ATT&CK: complementa, no sustituye.** Reutiliza el modelo y buena parte de las
    tácticas de ATT&CK y añade las propias del dominio de IA. **Se usan los dos juntos**: ATT&CK para
    la parte empresarial de la intrusión, ATLAS para la superficie de IA.
  - **Estado verificado**: desde mayo de 2026 el proyecto **separó el versionado del contenido y del
    formato**. El **contenido** sigue un esquema `YYYY.MM.N` — última release verificada
    **v2026.06** (2026-06-30). El **formato de datos** sigue SemVer, **v6.0.0**, que introdujo un
    campo `platforms` en todas las técnicas (`Predictive AI`, `Generative AI`, **`Agentic AI`**,
    `Enterprise`), esquemas Pydantic de validación y API REST. Las releases anteriores usaban SemVer
    conflacionado (v5.6.0, mayo-2026).
  - **Implicación práctica**: si tu herramienta o tu capa de Navigator consume `ATLAS.yaml` del
    formato antiguo, **el cambio a v6.0.0 te afecta**. Filtra la cobertura por `platforms` para no
    reclamar cobertura agéntica que no tienes.
  - El contenido reciente incorpora casos reales de la ola agéntica (exfiltración por inyección
    indirecta en asistentes de productividad, extracción de modelo, servicios de IA como relé de C2,
    RCE en plugins de frameworks de agentes).
- **OWASP GenAI Security Project** — **dos listas, y hay que usar la correcta**:
  - **Top 10 for LLM Applications 2025** (`LLM01:2025`–`LLM10:2025`). **Verificado: sigue siendo la
    edición vigente; no hay edición 2026.** Aplica a chatbots, copilotos y RAG.
  - **Top 10 for Agentic Applications 2026** (`ASI01`–`ASI10`): Agent Goal Hijack, Tool Misuse &
    Exploitation, Agent Identity & Privilege Abuse, **Agentic Supply Chain Compromise**, Unexpected
    Code Execution, Memory & Context Poisoning, Insecure Inter-Agent Communication, Cascading Agent
    Failures, Human-Agent Trust Exploitation, Rogue Agents. **Extiende** a la de LLM, no la
    reemplaza: ASI04 cubre la composición dinámica en runtime donde LLM03 cubría la cadena estática
    previa al despliegue. El diseño del agente frente a estos riesgos es de `ai-agents-standards`;
    aquí, la parte de cadena de suministro (ASI04) y de ejecución (ASI05).
- **NIST AI RMF** — **AI RMF 1.0** (`NIST AI 100-1`, enero 2023) sigue siendo el documento base;
  **no hay una 2.0 publicada**. El perfil de IA generativa **`NIST AI 600-1` sigue siendo el de
  julio de 2024, sin revisar**. La actividad de 2026 es **aditiva**: perfil de infraestructura
  crítica (nota de concepto, abril 2026), overlays de ciberseguridad para sistemas de IA (COSAiS,
  mono y multiagente), e iniciativa de estándares para agentes vía CAISI (febrero 2026). **Su
  utilidad práctica es el ciclo Govern/Map/Measure/Manage como esqueleto del programa**, no como
  catálogo técnico: su modelo de amenaza precede a lo agéntico.
- **AI Act (UE) — parte de seguridad, art. 15**: los sistemas de alto riesgo deben alcanzar un nivel
  apropiado de **exactitud, robustez y ciberseguridad**, con las métricas de exactitud **declaradas
  en las instrucciones de uso**, y resiliencia frente a intentos de alterar su uso, salidas o
  rendimiento — **citando explícitamente envenenamiento de datos y de modelo, ejemplos adversarios y
  brechas de confidencialidad**. El nivel exigido es **contextual** (propósito, estado del arte,
  riesgo), no un porcentaje universal. ⚠️ **El calendario está en disputa**: la fecha de aplicación
  de las obligaciones de alto riesgo (2 de agosto de 2026 bajo el texto original) puede haberse
  desplazado por el paquete *Digital Omnibus* — **verificar en fuente primaria antes de comprometer
  una fecha** (§8). **El régimen, el inventario y la clasificación de riesgo son de
  `ai-governance-standards`; aquí solo el control técnico que satisface el
  art. 15.**

### 3.9 Detección y respuesta aplicadas a IA

**Qué se registra** (mínimo, correlacionable y con retención definida):

- **Ciclo de vida del artefacto**: descarga o ingesta de un modelo (origen, digest), verificación de
  firma (éxito **y fallo**), carga de un modelo en un proceso, y **toda escritura en el registro de
  modelos**.
- **Pipeline**: quién lanzó un entrenamiento, sobre qué versión del dataset, con qué imagen, y qué
  artefacto produjo.
- **Endpoint de inferencia**: identidad del llamante, volumen, tokens, latencia, herramientas
  invocadas, rechazos de guardrail, y errores de autorización.
- **Agente**: llamadas a herramienta, destinos de red, acciones irreversibles y aprobaciones.

**Qué alerta** (síntomas, no ruido):

- Fallo de verificación de firma o **carga de un artefacto con digest desconocido**.
- Escritura en el registro de modelos fuera del pipeline autorizado.
- Patrón de consulta compatible con extracción (§3.6) o alta correlacionada de cuentas.
- Salto en la tasa de rechazos del guardrail (señal de campaña de jailbreak) **o caída súbita a cero**
  (señal de guardrail roto o evadido).
- Egress desde el proceso de inferencia o del sandbox de carga hacia un destino no permitido.
- Instalación en CI de una versión de dependencia fuera de la lista fijada.

La **autoría, prueba y ciclo de vida** de estas reglas es de `detection-engineering-standards`; la
**respuesta y el forense** al compromiso, de `incident-response-forensics-standards`.

### 3.10 Seguridad del pipeline de entrenamiento

- **Quién puede tocar los datos**: acceso mínimo y auditado al dataset; separación entre quien
  aporta datos, quien entrena y quien promueve el modelo.
- **Reproducibilidad como control de seguridad**, no solo de calidad: sin poder reproducir un
  entrenamiento no puedes bisecar qué lote de datos introdujo el comportamiento anómalo. Versiona
  dataset, código, configuración e imagen, y registra la terna en el artefacto resultante.
- **Aislamiento del cómputo**: el entrenamiento y, sobre todo, **la carga de modelos no verificados**
  corren en entornos sin credenciales de producción, sin acceso al plano de gestión y con egress
  restringido. El nodo de entrenamiento suele tener credenciales de almacenamiento muy amplias:
  es un objetivo de alto valor.
- **Cadena de custodia del artefacto** de extremo a extremo: entrenamiento → registro (firmado) →
  despliegue (verificado). Cada salto, auditado.
- **Datos personales en el entrenamiento**: base legal, minimización, retención y derechos son de
  `privacy-engineering-standards`. Aquí solo la protección del almacén y del acceso.

## 4. Calidad y gates de CI

Orden de coste creciente. Los primeros rompen el build.

1. **Fijado de dependencias verificado** (segundos, **rompe el build**): ninguna GitHub Action, imagen
   base o dependencia referenciada por tag mutable. Es el control que separó a los afectados de los
   no afectados en §3.3.
2. **Escaneo de secretos** (segundos, **rompe el build**) → `cicd-standards`,
   `secrets-management-standards`.
3. **SCA del stack de ML** (minutos, **rompe el build** en severidad crítica): dependencias de
   entrenamiento e inferencia. Triaje y SLA: `vulnerability-management-standards`.
4. **Política de formato de pesos** (segundos, **rompe el build**): ningún artefacto en formato con
   ejecución arbitraria entra en el registro sin excepción aprobada y registrada. Ningún
   `trust_remote_code=True` en el código.
5. **Escaneo del modelo** (`picklescan`/`modelscan`) sobre todo artefacto ingerido (minutos,
   **rompe el build**). Con la expectativa correcta: detecta lo conocido (§3.2).
6. **Verificación de firma y digest antes de promover y antes de cargar** (segundos, **rompe el
   despliegue**).
7. **Generación y publicación del AIBOM** como artefacto de la release (minutos): inventario, con sus
   huecos declarados.
8. **Barrido de red teaming** con `garak` en cada despliegue de modelo (minutos, **rompe la
   promoción** por umbral acordado) — el umbral y la gestión de la varianza son de
   `llm-evaluation-standards`.
9. **Campaña profunda multi-turno** (PyRIT) con periodicidad definida, dentro de las RoE
   (`offensive-security-standards`), **pre-release** para sistemas de alto riesgo.
10. **Verificación de cobertura frente a ATLAS y al Top 10 aplicable** (revisión periódica, no gate):
    filtrada por `platforms` para no reclamar cobertura agéntica inexistente.

## 5. Seguridad del stack

Además de todo lo anterior, que ya es §5 de facto:

- **Runtime de inferencia con mínimo privilegio**: non-root, FS de solo lectura, capabilities
  eliminadas, seccomp, sin credenciales de producción en el proceso que carga el modelo →
  `container-runtime-security-standards`, `kubernetes-standards`.
- **Egress filtrado** desde el nodo de entrenamiento y desde el runtime de inferencia. Es el control
  que convierte una carga maliciosa en un intento fallido, y el que corta la exfiltración.
- **Segregación por confianza**: un modelo de terceros no verificado no comparte namespace, nodo ni
  credenciales con cargas de producción.
- **Zero-trust entre servicios** (mTLS, identidad de carga de trabajo) en el plano de ML como en
  cualquier otro → `identity-access-management-standards`, `networking-standards`.
- **Guardrails de entrada y salida** en el endpoint: son mitigación en profundidad, **no un
  perímetro**. Se prueban con red teaming y se vigila su tasa de activación (§3.9).
- **Backups del registro de modelos y del dataset**, cifrados e inmutables, con restauración probada
  → `bcdr-standards`, `backup-recovery-standards`. Reentrenar desde cero puede costar más que
  cualquier otro plan de recuperación del estado.

## 6. Rendimiento y operabilidad

- **Coste del escaneo**: un artefacto de decenas o cientos de GB no se escanea en el camino crítico
  del despliegue. Escanea **en la ingesta** al registro interno, una sola vez, y **verifica digest**
  en cada uso.
- **Caché interno de artefactos verificados** con digest como clave. Elimina la descarga desde el hub
  público en runtime, que es a la vez riesgo de seguridad y de disponibilidad.
- **Presupuesto de red teaming**: el barrido en CI se dimensiona (número de sondas × coste por
  llamada) o se recortará solo. Las campañas profundas se planifican por trimestre, no por sprint.
- **Falsos positivos del escáner de modelos**: si el gate produce ruido, se documenta la excepción con
  dueño y caducidad. Una excepción permanente sin dueño es el gate desactivado con más pasos.
- **Métricas del programa**: % de artefactos con procedencia y firma, % ingeridos en formato seguro,
  tiempo desde publicación de un modelo hasta su verificación, cobertura ATLAS filtrada por
  plataforma, hallazgos de red team convertidos en casos de evaluación.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: revisar el mapeo a ATLAS y al Top 10 aplicable cada trimestre (ATLAS publica
  contenido **mensualmente**); revisar el estado de mantenimiento de las herramientas de escaneo y
  red teaming cada semestre; reevaluar el inventario de modelos en cada release.
- **Deprecación**: un modelo que ya no se sirve se retira del registro con su AIBOM archivado, no se
  deja "por si acaso" — cada artefacto vivo es superficie.
- **Deuda consciente**: toda excepción a la política de formatos o de firma se registra con motivo,
  dueño, compensación y **fecha de caducidad**.

### PROHIBICIONES

- ❌ **PROHIBIDO cargar pesos de terceros sin verificar procedencia, digest y firma.**
- ❌ **PROHIBIDO `trust_remote_code=True`** sin excepción aprobada, sandbox y registro. Es ejecución
  de código arbitrario de terceros.
- ❌ **PROHIBIDO referenciar modelos, imágenes, Actions o dependencias por tag mutable o `latest`.**
  Digest o SHA. Es la lección directa del incidente de §3.3.
- ❌ **PROHIBIDO cargar un modelo no verificado fuera de un sandbox** sin red ni credenciales. La
  carga es ejecución.
- ❌ **PROHIBIDO tratar un escáner de modelos como garantía.** Es una lista de denegación con
  historial documentado de evasión.
- ❌ **PROHIBIDO tratar la etiqueta "unsafe" de un hub público como un bloqueo.** No lo es.
- ❌ **PROHIBIDO descargar pesos desde un hub público en tiempo de despliegue.** Réplica interna.
- ❌ **PROHIBIDO dar credenciales de producción, del plano de gestión o del registro de modelos al
  proceso que carga o entrena.**
- ❌ **PROHIBIDO usar tokens estáticos de larga vida para publicar artefactos.** OIDC / publicación
  confiable.
- ❌ **PROHIBIDO presentar la marca de agua como protección contra la destilación.** Es forense y
  post hoc; venderla como defensa es desinformar a quien acepta el riesgo.
- ❌ **PROHIBIDO ejecutar red teaming de IA sin autorización escrita y RoE** →
  `offensive-security-standards`. Sin excepción técnica ni de urgencia.
- ❌ **PROHIBIDO documentar payloads listos para usar, jailbreaks concretos de producto de terceros o
  bypasses específicos de guardrail.** Clase, indicador y mitigación.
- ❌ **PROHIBIDO reportar un hallazgo de red team sin tasa de éxito sobre N intentos.** El sistema no
  es determinista; un éxito aislado no es un hallazgo.
- ❌ **PROHIBIDO cerrar un ejercicio de red team sin convertir los hallazgos en casos permanentes de
  evaluación** (`llm-evaluation-standards`) y, cuando aplique, en reglas de detección.
- ❌ **PROHIBIDO tratar el AIBOM como control de seguridad.** Es inventario, con huecos.
- ❌ **PROHIBIDO confiar solo en límites de tasa globales** frente a extracción: la campaña se
  distribuye entre cuentas.
- ❌ **PROHIBIDO asumir que un escáner de seguridad en tu CI es confiable por ser defensivo.** El
  eslabón comprometido de 2026 fue exactamente eso.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web —y, para versiones y fechas, **por
`api.github.com`, PyPI/npm o feeds Atom, nunca por un resumidor de HTML**:

1. **MITRE ATLAS**: release de contenido vigente (verificado: **v2026.06**, 2026-06-30) y versión del
   **formato** (verificado: **v6.0.0**, con campo `platforms`). Comprobar si tu tooling consume el
   formato antiguo. **Verificar además el recuento exacto de tácticas, técnicas, mitigaciones y casos
   directamente en `atlas.mitre.org`** — ver hueco declarado abajo.
2. **OWASP GenAI**: confirmar que la lista de LLM vigente sigue siendo la **2025** (verificado: sin
   edición 2026) y el estado de la de **Agentic Applications 2026 (ASI01–ASI10)**, más cualquier
   lista nueva del proyecto (hay trabajo activo en *skills* agénticas y memoria de agentes).
3. **NIST**: si `AI 100-1` sigue en 1.0 y `AI 600-1` sigue siendo el de julio de 2024 (verificado a
   agosto de 2026); estado de los overlays **COSAiS**, del perfil de infraestructura crítica y de la
   iniciativa de estándares de agentes de CAISI.
4. **AI Act**: **fecha de aplicación vigente** de las obligaciones de alto riesgo y del artículo 15,
   en fuente primaria (EUR-Lex o el AI Act Service Desk de la Comisión). **El *Digital Omnibus* puede
   haber desplazado el calendario; no comprometas una fecha sin comprobarla.**
5. **Formatos de pesos**: si `safetensors` sigue siendo el seguro recomendado, el comportamiento por
   defecto de `weights_only` en tu versión de PyTorch, y si han aparecido nuevas clases de evasión de
   cargadores restringidos.
6. **Herramientas de escaneo y red teaming**: versión y actividad de `picklescan`, `modelscan`,
   `garak`, **`microsoft/PyRIT`** (⚠️ `Azure/PyRIT` está archivado desde 2026-03-27) y `promptfoo`.
   **Regla: más de 6 meses sin release en este ecosistema es señal de abandono, no de estabilidad.**
7. **AIBOM**: edición vigente de **CycloneDX** (verificado: 1.7 de 2025-10-21, parches 1.7.x en 2026;
   ECMA-424) y de **SPDX** (verificado: 3.0.1, con 3.1-RC1 de 2026-01-24), y qué herramienta genera
   qué versión realmente.
8. **Incidentes**: verificar en fuente primaria antes de citarlos —el aviso del propio proyecto
   LiteLLM, el de Trivy y los boletines de PyPI— y comprobar si hay incidentes posteriores de la
   misma campaña o de otros hubs de artefactos de IA.
9. **CVE del stack de ML**: no se listan aquí. Entran por `vulnerability-management-standards`.

### Huecos declarados (no verificados en esta redacción)

- **Recuento exacto de ATLAS** (tácticas, técnicas, mitigaciones, casos): la cifra que circula
  (~16 tácticas / ~170 técnicas / ~35 mitigaciones / ~57 casos) procede de **fuentes secundarias de
  blog** y **no está verificada en fuente primaria**. Las releases sí están verificadas por API. **No
  uses el recuento en un informe sin comprobarlo en `atlas.mitre.org`.**
- **CVE-2026-6859 (InstructLab, `trust_remote_code`)**: citado desde fuente secundaria; **no
  verificado en NVD**. Verificar antes de usarlo como referencia formal.
- **Cifras exactas del incidente LiteLLM** (número de instalaciones en la ventana, credenciales
  potencialmente expuestas): varían entre analistas. La **cadena de eventos y el mecanismo `.pth`**
  están corroborados por múltiples fuentes independientes, incluido el aviso del proyecto; **las
  cifras, no**. Usa el mecanismo como argumento; las cifras, con reserva.
- **Adquisición de `promptfoo` por OpenAI (marzo 2026)**: fuente secundaria, **no confirmada en
  fuente primaria**. Relevante como riesgo de gobierno si evalúas modelos rivales.
- **Estado de `gitleaks` como *feature complete*** y otros precedentes de mantenimiento del catálogo:
  **no verificados en esta redacción**. Consultar la skill correspondiente
  (`secrets-management-standards`) antes de afirmarlo.
- **Fecha de aplicación efectiva del artículo 15 del AI Act**: **en disputa** entre el calendario
  original (2026-08-02) y el posible desplazamiento por el *Digital Omnibus*. No verificado en fuente
  primaria. No fijes fechas de cumplimiento a partir de este documento.
- **Madurez de las defensas anti-destilación** más allá de límites y detección: área de investigación
  activa sin producto establecido. No se recomienda ninguna concreta a propósito.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
