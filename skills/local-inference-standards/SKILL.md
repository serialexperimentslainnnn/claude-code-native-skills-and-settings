---
name: local-inference-standards
description: Use when serving open-weight LLMs on your own infrastructure — vllm serve, llama-server and llama.cpp, ollama serve with OLLAMA_HOST/OLLAMA_NUM_PARALLEL, SGLang, TGI or TensorRT-LLM, a self-hosted OpenAI-compatible /v1/chat/completions endpoint, .gguf and .safetensors weight files and their provenance, choosing AWQ/GPTQ/FP8/NVFP4/MXFP4/Q4_K_M quantization, sizing KV cache VRAM with --max-model-len, --gpu-memory-utilization and --tensor-parallel-size, prefill versus decode and TTFT/TPOT benchmarking under sustained load, open-weight model licences, or the break-even calculation of self-hosting versus a hosted inference API.
---

# Estándares de inferencia local

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando **sirves un modelo abierto en infraestructura propia** (tuya, del cliente o
alquilada como máquina desnuda) y la decisión es de plataforma de inferencia:

- Decidir **local frente a API gestionada**, y calcular el punto de equilibrio (§2.1).
- Elegir **motor** (`vllm serve`, `llama-server`, `ollama serve`, SGLang, TGI, TensorRT-LLM)
  y justificar la elección contra el patrón de carga real.
- **Cuantización**: formato, nivel y qué se pierde (`.gguf`, AWQ, GPTQ, FP8, NVFP4, MXFP4).
- **Dimensionado de memoria**: pesos + caché KV + activaciones; `--max-model-len`,
  `--gpu-memory-utilization`, `--tensor-parallel-size`, `--kv-cache-dtype`.
- **Medición**: TTFT, TPOT, tokens/s de prefill vs. decode, throughput bajo carga sostenida.
- **Compatibilidad de API**: el contrato OpenAI (`/v1/chat/completions`, `/v1/completions`,
  `/v1/embeddings`) como capa de intercambiabilidad del backend.
- **Operación**: procedencia y verificación de pesos, licencia del modelo, actualización,
  métricas del motor, consumo eléctrico por millón de tokens.
- **Seguridad del endpoint**: autenticación, exposición, aislamiento de red del plano
  distribuido.

**No aplica**: ver `gpu-computing-standards` (la GPU como recurso de infraestructura: driver,
CUDA, MIG/MPS, DCGM, XID, consumo y refrigeración — **un servidor de inferencia sin GPU, en CPU
o en Apple Silicon, sigue siendo de esta skill**), `llm-app-engineering-standards` (la
aplicación que **consume** el endpoint: prompts, salida estructurada, reintentos, inyección de
prompt — **servir es de aquí, consumir es de allí**; la frontera es el puerto HTTP),
`claude-api` (**referencia canónica de la API de Anthropic**: la alternativa gestionada a la
inferencia local vive ahí, y **ningún dato de modelos Claude —id, precio, límites— se afirma
de memoria**; consúltala antes de comparar coste contra un proveedor), `mcp-standards`
(servidores MCP y sus herramientas), `kubernetes-standards` (manifiestos, Helm, GitOps del
despliegue), `podman-systemd-containers-standards` (el motor como unidad Quadlet en un host),
`observability-standards` (OTel, PromQL, alertas — aquí solo se dice **qué** métrica del motor
importa), `firewall-policy-standards` (la regla que expone o no el puerto),
`identity-access-management-standards` (el IdP y el token que autentica al llamante),
`secrets-management-standards` (dónde vive la API key del endpoint),
`linux-storage-standards` y `zfs-standards` (**dónde viven los pesos**: ficheros de decenas o
cientos de GB, con su patrón de lectura secuencial y su presupuesto de espacio),
`backup-recovery-standards` (§6.4: casi nunca se respaldan pesos públicos),
`privacy-engineering-standards` (**la razón más común para servir en local es dato personal**:
la minimización, la base legal y la retención se deciden allí, no aquí),
`grc-compliance-standards` (evidencia de auditoría), `networking-standards`,
`onprem-standards` (paraguas de plataforma: hardware, rack, alimentación, plano de gestión —
esta skill es una capa dentro de su §1.2 y no contradice sus invariantes de §1.3),
`homelab-standards` (**inferencia en casa**: allí mandan el coste, el ruido, el consumo y la
proporcionalidad; si el servidor de inferencia es tu lab personal sin terceros ni SLA, manda
esa skill y esta aporta solo el criterio técnico), `python-standards` (código del cliente o de
scripts de evaluación), `vulnerability-management-standards` (triaje y SLA de los CVE de §5), `webgl-webgpu-standards`
(**si el modelo se ejecuta en el navegador, WebGPU es el sustrato y su criterio es
suyo** —adaptador, límites del dispositivo, pérdida de contexto, memoria de GPU y degradación a
WebGL2—; **la elección del modelo, su cuantización y el presupuesto de memoria siguen siendo de
aquí**. Aviso compartido y verificado: **WebGPU no es Baseline** —sin soporte en Firefox Android y
con restricciones por GPU en escritorio—, así que un despliegue de inferencia en navegador
necesita plan de degradación), `green-it-standards` (el dimensionado, la cuantización y
el cálculo de punto de equilibrio frente a una API alojada son de aquí; **la contabilidad
energética y de carbono de ese entrenamiento o esa inferencia es suya** — y el aviso que comparten:
**las cifras de huella que publican los proveedores de nube no son comparables entre sí**, así que
un cálculo de "self-host frente a API" en carbono no se resuelve restando dos números de fuentes
distintas).

También `rag-standards` (recuperación y embeddings — **servir el modelo de embeddings en local
es de aquí; el diseño del índice, el chunking y el reranking son de allí**) y
`ai-agents-standards` (bucle del agente, superficie de herramientas, contención).

Además: `llm-evaluation-standards` (**medir si
el modelo local es suficientemente bueno para la tarea es de allí**: esta skill mide
*rendimiento*, no *calidad*), `mlsecops-standards` (**procedencia, firma y escaneo del
artefacto de modelo: frontera compartida** — el criterio de cadena de suministro es suyo, la
regla operativa de "qué pesos acepta este servidor" es de aquí), `mlops-standards`
(entrenamiento, fine-tuning y ciclo de vida del modelo, frente a servirlo),
`ai-governance-standards` (AI Act, inventario de sistemas de IA, evaluación de impacto).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

### 2.1 La decisión de partida: local frente a API

**Razones legítimas para servir en local**

| Razón | Cuándo es real |
|---|---|
| **El dato no puede salir** | Prohibición contractual, regulatoria o de clasificación. Es la razón más sólida y la más común. Va acompañada de `privacy-engineering-standards`, no la sustituye |
| **Coste a volumen alto y sostenido** | Solo si la utilización es **alta y continua** (§2.2). Una GPU al 15% es más cara que la API |
| **Latencia** | Cuando el RTT a la nube o la variabilidad de cola del proveedor rompen el SLO. Medir antes de asumirlo |
| **Independencia de proveedor** | Un modelo con pesos en tu disco no se deprecia ni cambia de comportamiento sin que tú lo decidas. Es la ventaja más infravalorada |
| **Determinismo de versión** | El modelo congelado es reproducible; un endpoint gestionado puede cambiar bajo tus pies |
| **Experimentación y aprendizaje** | Legítima, pero **decláralo como tal** y no la disfraces de decisión de coste |
| **Sin conectividad** | Entorno aislado, borde, buque, planta industrial |

**Razones malas**

- ❌ **"Es gratis".** No lo es. El coste es hardware (amortización), electricidad (24×7, no
  solo en carga), refrigeración, espacio, red, **operación** (parcheo, guardias,
  observabilidad) y sobre todo **tiempo de ingeniería**, que es la partida mayor y la que
  nunca se presupuesta.
- ❌ **"Es más privado por definición".** Servir en local sin autenticación, sin cifrado en
  tránsito y sin retención controlada de prompts es *peor* que un proveedor con contrato de
  encargado de tratamiento. La privacidad es una propiedad del diseño, no de la ubicación.
- ❌ **"Es más seguro porque está dentro".** Ver §5: varios motores no autentican por defecto.
- ❌ **"Nos da el mismo resultado".** Eso se **mide** (`llm-evaluation-standards`), no
  se supone. Un modelo abierto que no resuelve la tarea es coste cero de API y coste total de
  infraestructura.

**Cálculo del punto de equilibrio** — hazlo explícito y por escrito antes de comprar nada:

```
Coste_local_por_1M_tokens =
    ( amortización_hardware_hora        # precio / (vida_útil_h × factor_utilización)
    + kWh_hora × precio_kWh × PUE       # GPU + host + refrigeración, no solo la TDP de la GPU
    + coste_operación_hora )            # % de FTE de plataforma / horas del mes
    ÷ tokens_por_hora_sostenidos        # medidos bajo carga real (§4), NO el pico de una demo

Coste_API_por_1M_tokens = precio_entrada × ratio_entrada + precio_salida × ratio_salida
```

Reglas del cálculo, no negociables:

1. `tokens_por_hora_sostenidos` sale del **benchmark de §4 con la concurrencia real**, no del
   número que sale en un tuit ni de una petición aislada.
2. **El divisor es la utilización, no la capacidad.** Si la carga es de oficina (8×5, con
   picos), divide por las horas *útiles*: el hardware sigue consumiendo y amortizando de noche.
3. Incluye la **redundancia**: un servidor de inferencia único es un SPOF. Si el servicio
   importa, el cálculo es con N+1, y eso duplica el numerador.
4. Precios de la API: **consúltalos por web, nunca de memoria** (para Anthropic, `claude-api`).
5. Si el resultado está dentro de ±30%, **manda la API**: el margen no cubre el riesgo
   operativo ni el coste de oportunidad del equipo.

### 2.2 Elección de motor

| Motor | Estado verificado (ago-2026) | Cuándo es la elección correcta |
|---|---|---|
| **vLLM** — `vllm serve` | **v0.26.0** (27-jul-2026), cadencia de release muy alta | **Por defecto para servir en producción con concurrencia.** PagedAttention (caché KV paginada, sin fragmentación) + *continuous batching* (encaja peticiones nuevas en cada iteración en vez de esperar al lote). Es el que convierte concurrencia en throughput |
| **llama.cpp** — `llama-server` | Build **b10241** (3-ago-2026), releases por build casi diarias | **Hardware modesto, CPU, Apple Silicon (Metal), cuantización agresiva, borde.** GGUF, un binario sin dependencias, *offloading* parcial a GPU con `-ngl`. Sirve un endpoint OpenAI-compatible |
| **Ollama** — `ollama serve` | **v0.32.5** (27-jul-2026), activo | **Desarrollo y laboratorio.** Excelente ergonomía (`ollama run`, gestión de modelos, descarga). Envoltorio sobre llama.cpp/motor propio. Ver límites abajo |
| **SGLang** | **v0.5.16** (25-jul-2026), activo | Alternativa seria a vLLM cuando la carga tiene **mucho prefijo compartido** (RadixAttention) o *grammar*/salida estructurada intensiva. Evaluar con benchmark propio, no por fe |
| **TensorRT-LLM** | **v1.3.0rc23** (31-jul-2026) — cadencia de *release candidates* | Solo cuando exprimir el último 20-30% de una GPU NVIDIA justifica el coste: compilación de motor por modelo **y por configuración de hardware**, y reconstrucción en cada cambio. **NVIDIA-only, sin ROCm** |
| **TGI** (`text-generation-inference`) | ⚠️ **v3.3.7 de dic-2025; último commit en `main`, mar-2026.** Sin releases en ~8 meses | ❌ **No elegir para proyecto nuevo.** Trátalo como en mantenimiento hasta que se demuestre lo contrario. Si ya está en producción, planifica salida a vLLM o SGLang |
| **Triton Inference Server** | **2.71.0** (jul-2026, contenedor NGC 26.07) | Cuando hay que servir **modelos que no son LLM** (visión, audio, clásicos) junto a LLM en una sola superficie de servicio, con backends heterogéneos |

**Límites de Ollama cuando se intenta usar en producción** — declararlos antes de que
alguien lo descubra en un incidente:

- **Su modelo de concurrencia no es *continuous batching* comparable al de vLLM.**
  `OLLAMA_NUM_PARALLEL` sube el paralelismo pero no cambia la arquitectura: el throughput y la
  latencia de cola se degradan mucho antes que en vLLM. Los órdenes de magnitud publicados
  (decenas de tokens/s frente a cientos, p99 de cientos de ms frente a segundos) **verifícalos
  con tu propio benchmark**: dependen del modelo, la GPU y la versión.
- **No autentica** (§5) y su superficie de API ha acumulado CVE de parseo GGUF y de
  actualización (§5.3).
- **Formato distinto**: Ollama trabaja con GGUF; vLLM sirve `safetensors` de forma nativa. La
  migración implica **volver a descargar los pesos**, no convertirlos. Cuéntalo en el plan.
- **Criterio**: si hay más de ~5-10 usuarios concurrentes reales, o hay un SLO, Ollama es la
  herramienta equivocada. En `homelab-standards` y en desarrollo, es la correcta.

### 2.3 Cuantización

**Qué se pierde de verdad.** Reducir bits por peso reduce memoria y, como el *decode* está
limitado por ancho de banda de memoria, **aumenta la velocidad de generación**. Lo que se
pierde no se reparte uniformemente: la degradación se concentra en razonamiento encadenado,
código y matemáticas, y es mucho menor en resumen y redacción. Una perplejidad casi idéntica
puede esconder una caída notable en la tarea que te importa. **Regla: mide la tarea, no la
perplejidad** (`llm-evaluation-standards`).

| Formato | Estado | Uso |
|---|---|---|
| **GGUF** (`Q4_K_M`, `Q5_K_M`, `Q6_K`, `Q8_0`) | Vigente, formato nativo de llama.cpp/Ollama | CPU, Apple Silicon, GPU modesta, offloading mixto. `Q4_K_M` es el punto dulce reconocido (cuantización mixta: no es 4 bits uniformes) |
| **AWQ** (W4A16) | Vigente y muy soportado | Peso 4 bits / activación 16 bits en vLLM y SGLang. Estándar de facto para servir 4 bits en GPU |
| **GPTQ** | Vigente | Alternativa a AWQ; en ROCm el soporte ha sido más irregular que el de AWQ — verificar |
| **FP8** (W8A8) | Vigente, hardware Hopper+ y equivalentes | Buen compromiso calidad/velocidad cuando hay hardware que lo acelera. También como **`--kv-cache-dtype fp8`**, que es donde más rinde (§2.4) |
| **NVFP4** | Vigente, **Blackwell (SM100)** | 4 bits con escalado en dos niveles y bloque de 16. Máximo throughput donde el hardware lo soporta. Verificar limitaciones vigentes (p. ej. adaptadores LoRA) |
| **MXFP4** | Vigente, multiplataforma | 4 bits microscale, menos atado a un vendedor que NVFP4 |
| **INT8 / W8A8** | Vigente | Camino conservador cuando 4 bits degrada la tarea |
| **bitsandbytes NF4** | Vigente pero **para carga rápida y experimentación**, no para servir con throughput | ❌ No es la elección de un servidor de producción |
| Cuantizaciones **< 4 bits** (`Q2_K` y similares) | Vigentes técnicamente | ❌ **Vetadas en producción.** Hay un acantilado de calidad documentado por debajo de 4 bits, con degradación de un orden distinto y, en modelos pequeños, colapso |

**Regla práctica "modelo grande cuantizado > modelo pequeño en precisión completa"** — es
**cierta en el rango habitual y con límites concretos**, no un axioma:

- Se sostiene **hasta ~4 bits**. A partir de ahí se invierte: por debajo de 4 bits, el modelo
  pequeño con más precisión gana.
- La evidencia controlada disponible es limitada en dominio y tamaño (hay estudios revisados
  en generación de código con modelos pequeños que la confirman en ese rango); el resto del
  soporte es consenso de la comunidad y perplejidad en WikiText-2, que **no es tu tarea**.
- **Cómo usarla**: como *hipótesis de partida* para elegir qué dos candidatos comparar, nunca
  como conclusión. La decisión final sale de tu evaluación sobre tu tarea.
- Cuidado con confundir niveles: `Q4_0` y `Q4_K_M` son ambos "4 bits" y no son equivalentes.
  Donde exista GGUF con `imatrix`, es preferible al mismo ancho de bits sin ella.

### 2.4 Dimensionado de memoria

```
VRAM_total ≈ pesos + caché_KV + activaciones + fragmentación/overhead del runtime

pesos_bytes            = n_parámetros × bytes_por_parámetro
                         (FP16/BF16 = 2 · FP8/INT8 = 1 · 4 bits ≈ 0,5 + escalas)

caché_KV_bytes         = 2 × n_capas × n_kv_heads × head_dim
                         × longitud_secuencia × n_secuencias_concurrentes
                         × bytes_por_elemento
```

Lecturas obligatorias del cálculo:

1. **El `2` son K y V.** El `n_kv_heads` es el de *key/value*, **no el de query**: en modelos
   con GQA es varias veces menor, y esa es la razón de que existan ventanas de contexto largas.
   Sacarlo del `config.json` del modelo, no de memoria.
2. **La caché KV es lo que te mata.** Crece **lineal** en longitud de contexto **y** lineal en
   concurrencia. Con contexto corto es ruido; con contexto largo y varias peticiones
   simultáneas **supera al propio modelo** y es lo que dispara el OOM. Un modelo que cabe al
   arrancar puede no caber al servir.
3. **Corolario operativo**: `--max-model-len` **no se deja al máximo que anuncia el modelo**.
   Se fija al contexto que tu caso realmente necesita. Cada token de ventana que no usas es
   VRAM reservada que no atiende usuarios.
4. `--gpu-memory-utilization` en vLLM controla la fracción de VRAM que el motor reserva
   (**valor por defecto 0,90 — verificar en la versión que uses**). Subirlo aumenta la caché
   KV y por tanto la concurrencia; subirlo demasiado hace fallar la asignación.
5. **`--kv-cache-dtype fp8`** es la palanca de mayor retorno con contexto largo: reduce la
   caché a la mitad. Verificar su impacto en calidad con tu evaluación antes de fijarlo.
6. **Deja margen.** Reservar el 100% de la VRAM no deja sitio para activaciones ni para picos.
7. En llama.cpp, `-ngl` decide cuántas capas van a GPU. **Offloading parcial degrada
   catastróficamente**: si la mitad del modelo vive en RAM del host, el ancho de banda PCIe se
   convierte en el cuello de botella. Cuantiza más antes que hacer offloading a medias.

### 2.5 Compatibilidad de API

- **El estándar de facto es la API de OpenAI.** vLLM, llama.cpp (`llama-server`), Ollama,
  SGLang, TGI y TensorRT-LLM exponen `/v1/chat/completions`, `/v1/completions` y, según el
  motor, `/v1/embeddings`. **Eso es lo que hace el backend intercambiable.**
- **Regla de diseño**: la aplicación habla el contrato OpenAI y el `base_url` es
  configuración. Nunca se acopla a un SDK exclusivo del motor. Así el mismo cliente sirve para
  el modelo local, para otro motor y para un proveedor gestionado — que es la única forma
  barata de tener plan B.
- **La compatibilidad no es total.** *Tool calling*, salida estructurada / *grammar*, `logprobs`
  y opciones de muestreo divergen entre motores y versiones. **Se verifica con un test de
  contrato** (§4), no se asume.

## 3. Estructura y convenciones

- **Un motor, un modelo, un proceso, un puerto.** Multiplexar modelos en un proceso complica
  el dimensionado de la caché KV y convierte cualquier OOM en un incidente compartido. Si hay
  que enrutar entre varios modelos, se pone un *router* delante (o una pasarela), no dentro.
- **Todo declarativo**: los flags del motor viven en una unidad systemd/Quadlet, un manifiesto
  o un módulo de IaC versionado (`iac-standards`, `podman-systemd-containers-standards`,
  `kubernetes-standards`). ❌ Un `vllm serve` lanzado a mano en un `tmux` no es un despliegue.
- **Pesos fuera de la imagen del contenedor.** Volumen o almacenamiento montado
  (`linux-storage-standards`, `zfs-standards`, `object-storage-standards`): son decenas o
  cientos de GB, y meterlos en la imagen destruye la caché de capas y el registro.
- **Modelo referenciado por revisión inmutable**, no por nombre ni por `main`. El nombre puede
  apuntar a otros bytes mañana; el hash de revisión, no.
- **Naming**: el nombre del servicio incluye modelo y cuantización (`vllm-qwen3-32b-awq`), no
  solo "llm": en seis meses habrá tres y nadie sabrá cuál es cuál.
- Separar **red de servicio** (el endpoint) de **red de coordinación** (NCCL/`torch.distributed`,
  transferencia de caché KV): son planos con confianza distinta (§5.2).

## 4. Calidad y gates

**Cómo medir de verdad** — una petición aislada no mide nada:

| Métrica | Qué es | Trampa |
|---|---|---|
| **TTFT** (time to first token) | Latencia hasta el primer token. Domina la percepción en interfaces conversacionales | Es coste de **prefill**: crece con el prompt y con la cola |
| **TPOT / ITL** | Tiempo entre tokens durante el *decode* | Determina la velocidad "de lectura" percibida |
| **Throughput de salida** | Tokens/s agregados del servidor | **Es la métrica del coste**, no de la experiencia |
| **Tokens/s de prefill** | Procesado del prompt; **paralelo, limitado por cómputo** | Escala bien con lotes grandes |
| **Tokens/s de decode** | Generación; **secuencial, limitado por ancho de banda de memoria** | Por eso cuantizar acelera el decode y casi nada el prefill |

- **Prefill y decode son regímenes distintos.** Un sistema con prompts largos y respuestas
  cortas (RAG, clasificación) está limitado por prefill; uno de generación larga, por decode.
  **Dimensionar con el mixto equivocado es el error de capacidad más caro.**
- **El batching mejora el throughput y empeora el TTFT y el TPOT individuales.** No hay
  configuración que optimice ambos: se elige, con un SLO escrito (`sre-practice-standards`).
- **Gate de medición**: benchmark con **carga sostenida** (varios minutos), **concurrencia
  escalonada** (1, 2, 4, 8, 16, 32…) y **distribución de longitudes representativa de la
  producción**. Se reportan **percentiles (p50/p95/p99), no medias**, y la curva
  throughput-vs-latencia. El punto de operación es donde el p95 aún cumple el SLO.
- Herramientas: el propio `vllm bench serve` / los scripts de benchmark del motor, o un
  generador de carga con trazas reales. **Verificar el nombre exacto del subcomando en la
  versión instalada** (§8).

**Gates de CI que rompen el build** (orden de coste creciente):

1. **Configuración declarativa válida**: unidad/manifiesto lintado; ningún flag suelto fuera
   del artefacto versionado.
2. **Procedencia de pesos verificada**: revisión inmutable pinneada + hash de los ficheros
   comprobado contra el manifiesto del repositorio de origen (§5.1). Sin esto no se despliega.
3. **Test de contrato de API**: el endpoint responde el subconjunto OpenAI que la aplicación
   usa (chat, streaming, y —si se usan— *tool calling* y salida estructurada), con las mismas
   aserciones contra el motor actual y contra el candidato de upgrade.
4. **Test de arranque y de dimensionado**: el servicio arranca con `--max-model-len` de
   producción y **sobrevive a una prueba de saturación de caché KV** (concurrencia objetivo ×
   contexto máximo) sin OOM. Este es el fallo que más veces llega a producción.
5. **Gate de autenticación**: una petición **sin credencial** a **cualquier** ruta de
   inferencia debe devolver 401/403. Se prueban explícitamente las rutas fuera de `/v1` (§5.2).
6. **Benchmark de regresión de rendimiento**: throughput y p95 dentro de un umbral respecto a
   la línea base; una caída de X% rompe el build. La versión del motor cambia el rendimiento.
7. **Evaluación de calidad** de la tarea al cambiar modelo, cuantización o versión de motor
   (`llm-evaluation-standards`). **Cambiar la cuantización es cambiar el modelo.**

## 5. Seguridad del stack

### 5.1 Procedencia de los pesos

**Un `.gguf` o un `.safetensors` de un desconocido es un binario de un desconocido.** El
formato importa, pero no cierra el problema:

| Formato | Riesgo de ejecución al cargar |
|---|---|
| **Pickle** (`.bin`, `.pt`, `.ckpt`, `torch.load` sin `weights_only`) | ❌ **Ejecución arbitraria por diseño**: la deserialización ejecuta código. **PROHIBIDO** cargar pesos en pickle de origen no controlado. El escaneo del repositorio es por firmas y **se ha demostrado eludible** con contenedores no estándar |
| **safetensors** | ✅ **Formato seguro recomendado hoy.** Cabecera JSON + bytes crudos: no serializa objetos Python, no ejecuta código. **No protege** contra pesos manipulados (puerta trasera en los propios valores) ni contra `trust_remote_code` |
| **GGUF** | ⚠️ No es pickle, pero su **parser binario es una fuente recurrente de RCE**. Verificado en NVD: **CVE-2025-49847** (CVSS 8.8, desbordamiento en carga de vocabulario, corregido en b5662), **CVE-2026-27940** (7.8, desbordamiento de entero en `gguf_init_from_file_impl()`, corregido en b8146, *bypass* del arreglo de CVE-2025-53630), **CVE-2026-33298** (7.8, desbordamiento de entero en `ggml_nbytes`, corregido en b7824). Además, **plantillas de chat maliciosas embebidas en los metadatos GGUF** (inyección de plantilla) y **CVE-2026-7482 / CVE-2026-65315** en el cargador GGUF de Ollama |

Reglas duras:

- **`trust_remote_code=True` está PROHIBIDO** salvo excepción documentada y revisada: es
  ejecución de código Python arbitrario del autor del modelo. Hay CVE verificados de motores
  que lo activaban **incondicionalmente** (`CVE-2026-4944`, 8.8, código hardcodeado en vLLM;
  `CVE-2026-5817`, 8.8, backend `vllm-metal` en Docker Model Runner).
- **Pinnear por revisión inmutable** y verificar el hash. Referenciar un modelo solo por
  nombre permite que te sirvan otros bytes mañana. Existe CVE por controles de *pinning*
  aplicados de forma inconsistente (`CVE-2026-47155`, 6.5, vLLM < 0.22.0) — verifica que tu
  versión lo aplica de verdad, no que lo tiene documentado.
- **Un modelo se carga en un proceso confinado**: usuario sin privilegios, sin acceso de
  escritura a nada que no sea su directorio de trabajo, capacidades reducidas, filesystem raíz
  de solo lectura, sin acceso saliente a Internet salvo el necesario para la descarga
  (`container-runtime-security-standards`, `linux-hardening-standards`,
  `firewall-policy-standards`). **La primera descarga y el primer `load` son la ventana de
  ataque.**
- **La descarga es un paso separado del arranque**: se descarga, se verifica, se escanea y se
  publica en un almacén interno. El servidor de producción **no descarga de Internet en el
  arranque** (además de seguridad, es disponibilidad: un fallo del repositorio externo tumba
  el arranque de tu servicio).
- El escaneo y la firma del artefacto de modelo son frontera compartida con `mlsecops-standards`:
  **el criterio de cadena de suministro es suyo**; aquí manda la regla
  operativa de qué acepta este servidor.

### 5.2 El endpoint

**Varios motores no autentican nada por defecto.** Exponer un endpoint de inferencia sin
autenticar es regalar cómputo (y, con *tool calling*, un punto de apoyo dentro de tu red).

- **vLLM**: la documentación oficial es explícita — `--api-key` *"provides authentication for
  vLLM's HTTP server, but **only for OpenAI-compatible API endpoints under the `/v1` path
  prefix**, and other similar `/v2`, `/inference` path prefix"*, y *"Many other sensitive
  endpoints are exposed on the same HTTP server without any authentication enforcement"*,
  citando `/invocations` (*"particularly concerning as it provides unauthenticated access to
  the same inference capabilities"*), `/pooling`, `/classify`, `/generative_scoring` y
  endpoints de control como `/pause` y `/abort_requests`. La propia doc avisa: **"Do not rely
  exclusively on `--api-key` for securing access to vLLM."**
  → **Criterio: `--api-key` NO es el control de acceso.** El control es un **proxy inverso
  delante que hace *allowlist* explícita de las rutas expuestas y bloquea todas las demás**,
  con authn, rate limiting y log — que es exactamente lo que recomienda la doc oficial.
- **Ollama**: **no tiene autenticación**. Escucha en `127.0.0.1:11434` por defecto, y el
  problema empieza cuando alguien pone `OLLAMA_HOST=0.0.0.0` para compartirlo. Se han
  reportado del orden de **cientos de miles de instancias expuestas en Internet** y campañas
  activas de secuestro de cómputo — **verificar la cifra y la campaña por web antes de citar
  números concretos** (§8). ❌ `OLLAMA_HOST=0.0.0.0` sin firewall y sin proxy delante.
- **llama-server**: verificar en la versión instalada qué ofrece (`--api-key` y equivalentes)
  y **asumir por defecto que no basta**: mismo patrón, proxy delante.
- **El plano distribuido es inseguro por diseño.** vLLM: *"All communications between nodes in
  a multi-node vLLM deployment are **insecure by default** and must be protected by placing the
  nodes on an isolated network"*, y *"From a PyTorch perspective, any use of `torch.distributed`
  should be considered insecure by default."* → **Red aislada, obligatorio.** Nada de NCCL o
  transferencia de caché KV en la misma red que el resto.
- **Nunca `--host 0.0.0.0` sin control delante.** Enlazar a loopback o a la interfaz interna;
  exponer solo a través del proxy.
- **Endpoints de depuración prohibidos en producción** (`VLLM_SERVER_DEV_MODE=1`,
  `--enable-tokenizer-info-endpoint` y equivalentes): filtran plantillas de chat y
  configuración del tokenizador.
- **Autenticación real**: token por consumidor emitido por el IdP y verificado en el proxy
  (`identity-access-management-standards`), secreto gestionado
  (`secrets-management-standards`), TLS de extremo a extremo (`cryptography-pki-standards`).
  Un token compartido por toda la empresa no es autenticación: es una contraseña.
- **Rate limiting y cuotas por consumidor** son control de disponibilidad, no de cortesía: sin
  ellos, un cliente en bucle satura la única GPU y tumba a todos los demás. Hay CVE de DoS por
  consumo no acotado verificados (`CVE-2026-5497`, 7.5, OOM en vLLM ≥ 0.8.0).
- **Prompts y respuestas son datos.** Log estructurado **sin contenido** por defecto; si hay
  que retener, base legal, minimización y retención se deciden en
  `privacy-engineering-standards`. Servir en local no borra el RGPD, solo cambia quién es
  responsable de todo.
- **La salida del modelo es entrada no confiable** para lo que venga después: eso lo gobierna
  `llm-app-engineering-standards`, y esta skill no lo duplica. Pero el operador del endpoint
  debe saber que **con *tool calling* habilitado, un endpoint abierto es ejecución remota
  mediada**.

### 5.3 Dependencias y CVE

- Los motores de inferencia son **software joven, en C++/CUDA y Python, con parseo de ficheros
  no confiables**: superficie de vulnerabilidad alta y cadencia de parche rápida. Trátalos con
  el SLA de un componente expuesto (`vulnerability-management-standards`).
- Verificado en NVD (2026): vLLM acumula CVE de inyección de tokens (`CVE-2026-44222`),
  validación ausente de tensores dispersos (`CVE-2026-56340`, 8.7), ReDoS (`CVE-2025-71379`) y
  comprobaciones de seguridad basadas en `assert` (`CVE-2026-41523`, 7.5 — recuerda que
  `python -O` elimina los `assert`). Ollama, CVE de lectura fuera de rango en el cargador GGUF
  y de actualización sin verificar integridad en Windows.
- **Pinnear versión del motor por digest** y actualizar con cadencia, no con reflejo. Cada
  versión de vLLM/SGLang cambia rendimiento y a veces comportamiento: el gate 6 de §4 existe
  para eso.

## 6. Rendimiento y operabilidad

- **Métricas del motor a Prometheus** (`observability-standards`): vLLM expone `/metrics` con,
  entre otras, peticiones en ejecución y en espera, uso de la caché KV, tasa de aciertos del
  *prefix cache*, TTFT y TPOT, y contadores de tokens de prompt y de generación. **Verificar
  los nombres exactos de métrica en la versión instalada** (§8: han cambiado entre versiones).
- **Las cuatro señales que importan**:
  1. **Uso de la caché KV** — es tu indicador de saturación real. Cerca del 100% significa que
     el motor está a punto de encolar o de rechazar.
  2. **Cola de peticiones en espera** — si crece de forma monótona, no tienes un problema de
     latencia, tienes un problema de capacidad.
  3. **TTFT p95 y TPOT p95** — contra el SLO escrito.
  4. **Tasa de aciertos del *prefix cache*** — un prompt de sistema estable y colocado al
     principio convierte prefill en cacheable, y eso es throughput gratis.
- **Métricas de GPU** (utilización real, memoria, temperatura, throttling, ECC) y su lectura:
  `gpu-computing-standards`.
- **Consumo eléctrico como métrica de primera clase**: kWh y **coste por millón de tokens**
  servidos. Es la mitad del cálculo de §2.1 y lo que convierte una discusión de opinión en una
  de números. Fijar un límite de potencia por GPU es a menudo una pérdida pequeña de
  rendimiento por una ganancia grande de eficiencia — se mide, no se supone
  (`gpu-computing-standards`).
- **Arranque en frío**: cargar decenas de GB desde disco y compilar/*warmup* de kernels tarda
  minutos. Impacta al *readiness probe*, al despliegue y al plan de recuperación. **Mídelo y
  documéntalo**; no descubras en un incidente que tu RTO era optimista.
- **Multi-GPU y multi-nodo, solo cuando hace falta**:
  - **Paralelismo de tensor** (`--tensor-parallel-size`): parte cada capa entre GPUs. Baja la
    latencia y permite modelos que no caben en una GPU, pero exige **interconexión rápida
    entre GPUs del mismo nodo** (NVLink o equivalente). Sobre PCIe la comunicación se come la
    ganancia.
  - **Paralelismo de pipeline** (`--pipeline-parallel-size`): parte por capas entre nodos.
    Tolera enlaces más lentos, pero introduce burbujas y **no baja la latencia**.
  - **Regla**: tensor dentro del nodo, pipeline entre nodos, y **solo si el modelo no cabe** o
    el SLO de latencia lo exige. Multi-nodo multiplica los modos de fallo; casi siempre es
    mejor un modelo más pequeño o más cuantizado que un despliegue distribuido.
  - **Replicar antes que paralelizar**: si el modelo cabe en una GPU, N réplicas
    independientes detrás de un balanceador dan más throughput y mejor aislamiento de fallo
    que una instancia con TP=N.
- **Respaldo de pesos**: normalmente **no se respaldan pesos públicos** — se re-descargan
  desde el almacén interno, que sí está respaldado junto con su manifiesto de hashes. **Sí se
  respaldan**: modelos ajustados propios, artefactos que ya no estén disponibles públicamente
  y el manifiesto de procedencia. Criterio y RTO/RPO en `backup-recovery-standards` y
  `bcdr-standards`; el dato de entrada es "cuánto tarda re-descargar 200 GB", que hay que
  medir.
- **Capacidad**: la GPU no se sobresuscribe como la CPU. Cuando la caché KV se llena, no hay
  degradación elegante: hay cola o hay error. Planifica con margen y con una política explícita
  de rechazo (429) antes que dejar crecer la cola sin fin.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisar versión de motor y CVE **mensualmente** (ecosistema con releases
  semanales); revisar la decisión local-vs-API **cada 6-12 meses** — el precio de las APIs baja
  y la capacidad de los modelos abiertos sube, y una decisión de 2024 puede ser hoy dinero
  quemado. Re-verificar toda esta skill cada 3 meses (§7 de `claude-code-skills-standards`).
- **Licencias de los modelos: es una decisión legal, no técnica.**
  - **"Abierto" no es "open source".** El OSI publicó la *Open Source AI Definition* v1.0, que
    exige **Data Information** (*"Sufficiently detailed information about the data used to
    train the system so that a skilled person can build a substantially equivalent system"*),
    **Code** (*"The complete source code used to train and run the system"*) y **Parameters**
    (*"The model parameters, such as weights or other configuration settings"*). **La mayoría
    de los modelos llamados "abiertos" no cumplen**: son *open weight*, con proceso de
    entrenamiento propietario.
  - Las licencias van desde permisivas reales (Apache-2.0, MIT) hasta licencias de comunidad
    con **restricciones de uso, umbrales de usuarios o de ingresos, políticas de uso prohibido,
    obligaciones de naming de derivados y cláusulas sobre el uso de las salidas para entrenar
    otros modelos**. Varias familias son **heterogéneas dentro de sí mismas**: el mismo
    "modelo" puede tener licencia distinta por tamaño o por generación.
  - **PROHIBIDO fijar en un documento o en un despliegue la licencia de un modelo concreto sin
    leer su *model card* y su fichero de licencia en ese momento.** Es donde más fácil es
    inventarse un dato, y el error es legal.
  - **Los *distills* y los *fine-tunes* heredan la licencia del modelo base.** Comprobarlo.
  - Registrar modelo, revisión, licencia y su evaluación en el inventario
    (`grc-compliance-standards`; `ai-governance-standards`).

**PROHIBIDO**

- ❌ Justificar la inferencia local con "es gratis" o "es más privado" sin el cálculo de §2.1
  y sin los controles de §5.
- ❌ Un endpoint de inferencia accesible sin autenticación, o "protegido" solo con
  `--api-key` sin *allowlist* de rutas en un proxy delante.
- ❌ `--host 0.0.0.0` / `OLLAMA_HOST=0.0.0.0` sin firewall y sin proxy.
- ❌ Tráfico NCCL / `torch.distributed` / transferencia de caché KV fuera de una red aislada.
- ❌ Cargar pesos en formato pickle de origen no controlado. `trust_remote_code=True` sin
  excepción documentada y revisada.
- ❌ Referenciar un modelo por nombre o por rama en lugar de por revisión inmutable + hash.
- ❌ Descargar pesos de Internet en el arranque del servicio de producción.
- ❌ Ollama como servidor de producción con concurrencia o con SLO.
- ❌ TGI en un proyecto nuevo (sin release desde dic-2025; verificar antes de sentenciarlo).
- ❌ Cuantización por debajo de 4 bits en producción.
- ❌ Cambiar modelo, cuantización o versión de motor sin re-evaluar la calidad de la tarea.
- ❌ `--max-model-len` al máximo del modelo "por si acaso": es VRAM quemada y OOM diferido.
- ❌ Offloading parcial a CPU como estrategia de producción (cuantiza más, o compra memoria).
- ❌ Dimensionar o presupuestar con el resultado de **una** petición en lugar de con carga
  sostenida y percentiles.
- ❌ Acoplar la aplicación a un SDK propio del motor en vez de al contrato OpenAI.
- ❌ Loguear prompts y respuestas por defecto.
- ❌ Multi-nodo antes de agotar "modelo más pequeño", "más cuantizado" y "N réplicas".
- ❌ Afirmar la licencia de un modelo, su tamaño, su ventana de contexto o su rendimiento de
  memoria — o el precio de una API — sin verificarlo en ese momento.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, número o nombre:

1. **Versión y vitalidad de cada motor**: `api.github.com/repos/<org>/<repo>/releases/latest` o
   el feed `releases.atom` (**no el HTML de la página de releases: el resumidor se inventa el
   año**). Comprobado así en ago-2026: vLLM **0.26.0** (27-jul-2026), llama.cpp build
   **b10241** (3-ago-2026), Ollama **0.32.5** (27-jul-2026), SGLang **0.5.16** (25-jul-2026),
   TensorRT-LLM **1.3.0rc23** (31-jul-2026), Triton Server **2.71.0** (jul-2026), TGI
   **3.3.7 de dic-2025** con último commit en `main` de mar-2026.
2. **Estado de TGI**: confirmar si ha vuelto a publicar releases antes de recomendarlo o de
   darlo por muerto.
3. **Flags y valores por defecto** del motor instalado: `--gpu-memory-utilization`,
   `--max-model-len`, `--kv-cache-dtype`, `--api-key`, el subcomando de benchmark y los
   **nombres exactos de las métricas de `/metrics`**. Cambian entre versiones menores.
4. **Formatos de cuantización vigentes** y su matriz de soporte por hardware en la doc del
   motor (NVFP4/MXFP4 y sus limitaciones evolucionan rápido).
5. **Seguridad de formatos de pesos**: CVE nuevos de parseo GGUF en el aviso de seguridad de
   `ggml-org/llama.cpp` y en NVD; estado del escaneo del repositorio de origen; incidentes
   recientes de modelos maliciosos.
6. **CVE de los motores** en NVD (`services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=…`)
   y en los avisos GHSA del repo. Los citados en §5 se verificaron contra NVD en ago-2026.
7. **Licencia del modelo concreto**: *model card* + fichero de licencia, en el momento de
   decidir. Y el estado de la *Open Source AI Definition* del OSI.
8. **Precio de las APIs** con las que se compara. Para Anthropic, la skill `claude-api` es la
   referencia canónica: **ningún id de modelo, precio ni límite de Claude se afirma de memoria**.
9. **Datos de dimensionado del modelo** (`n_capas`, `n_kv_heads`, `head_dim`, ventana): del
   `config.json` del modelo, nunca de memoria.

**Huecos declarados (no verificados en esta pasada, no rellenar de memoria)**

- **Cifras de rendimiento comparado Ollama vs. vLLM** (tokens/s, p99, usuarios concurrentes
  antes de OOM): citadas en la web con órdenes de magnitud coherentes entre fuentes, pero **no
  verificadas de forma independiente**. Medir en el hardware propio antes de usarlas.
- **Número de instancias de Ollama expuestas en Internet** y la campaña de secuestro asociada:
  reportado por varias fuentes con cifras dispares (rango amplio). **Verificar antes de citar
  una cifra concreta.**
- **Rendimiento y soporte de SGLang frente a vLLM** en cargas concretas: no benchmarkeado aquí.
- **Nombres exactos de las métricas Prometheus de vLLM 0.26**: no verificados uno a uno.
- **Estado exacto de la autenticación en `llama-server`** en la build actual: no verificado.
- **Nombres, tamaños, ventanas de contexto y licencias de modelos abiertos concretos**:
  **deliberadamente omitidos**. Es el dato que más rápido caduca y donde más fácil es
  inventar. Se verifica en la *model card* en el momento de decidir.
- **Impacto medido de `--kv-cache-dtype fp8` en calidad**: depende del modelo y de la tarea; no
  hay número general.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
