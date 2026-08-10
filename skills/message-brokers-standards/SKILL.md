---
name: message-brokers-standards
description: Use when a broker is chosen, sized, secured or operated as infrastructure — deciding whether a PostgreSQL table with SELECT ... FOR UPDATE SKIP LOCKED already covers the work queue before running a distributed system, telling a distributed log (retained and re-readable) apart from a queue (consumed and gone) and from lightweight messaging, KRaft controllers and the post-ZooKeeper world (server.properties, controller.quorum.voters, kafka-storage.sh format, kafka-reassign-partitions.sh, kafka-consumer-groups.sh, --describe), replication factor with min.insync.replicas and acks=all, log.retention.ms/log.retention.bytes and cleanup.policy=compact, consumer rebalance stop-the-world pauses, tiered storage, RabbitMQ exchanges, bindings and quorum queues after classic mirrored queues were removed in 4.0, Khepri, rabbitmq.conf, rabbitmqctl, rabbitmqadmin, publisher confirms, basic.qos prefetch and unacked message growth, NATS JetStream and nats-server.conf, Redpanda rpk and its BSL terms, Apache Pulsar with BookKeeper, brokers exposed without authentication, SASL/mTLS and per-topic ACLs, multi-tenancy and quotas, offline or under-replicated partitions, rolling major-version upgrades without dropping traffic, disk and network capacity as one decision with retention, or managed versus self-hosted broker cost.
---

# Estándares de brokers de mensajería

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: **el broker se despliega, casi siempre, para cargas que aguantaría una tabla.**
> Un broker distribuido es un sistema con consenso, réplicas, particiones, disco, red, actualización
> mayor y guardia. Se adopta cuando se ha demostrado que hace falta, no cuando "vamos a
> desacoplar".

## 1. Alcance y triggers

Aplica al **broker como pieza de infraestructura**: si hace falta, cuál, cómo se dimensiona, cómo se
configura para que las garantías que promete sean ciertas, cómo se asegura, cómo se opera, cómo se
actualiza y cuánto cuesta de verdad.

Disparadores: `server.properties`, `controller.quorum.voters`, `process.roles`,
`kafka-storage.sh format`, `kafka-topics.sh`, `kafka-configs.sh`, `kafka-reassign-partitions.sh`,
`kafka-consumer-groups.sh --describe`, `min.insync.replicas`, `acks=all`, `unclean.leader.election`,
`log.retention.ms`, `log.retention.bytes`, `cleanup.policy=compact`, `segment.bytes`,
`rack.awareness`, `rabbitmq.conf`, `advanced.config`, `rabbitmqctl`, `rabbitmq-diagnostics`,
`rabbitmqadmin`, `x-queue-type=quorum`, `basic.qos`, `publisher confirms`, `Khepri`,
`nats-server.conf`, `nats stream add`, `jetstream`, `rpk`, `redpanda.yaml`, `broker.conf`,
`bookkeeper`, `mosquitto.conf`, `visibility timeout`, y las frases del dominio: "hace falta una
cola", "queremos desacoplar los servicios", "el consumidor se ha atascado", "los mensajes se
acumulan", "hay que reprocesar los mensajes de ayer", "el disco del broker está al 90 %", "¿cuántas
particiones ponemos?", "hay que subir de versión mayor sin parar".

**No aplica**: ver
- `data-platform-standards` (**madre**): **Kafka como motor de streaming de la plataforma es suyo**
  —elección por defecto, particionado, retención por topic, el **registro de esquemas** (Karapace,
  Apicurio) y el **formato de eventos** (Avro/protobuf)— igual que **PostgreSQL y su
  `SELECT ... FOR UPDATE SKIP LOCKED` para colas de trabajo**, que es la alternativa que esta skill
  refuerza en §2.1. Aquí, **la operación profunda del broker, las alternativas a Kafka y el criterio
  de elección entre familias**.
- `elixir-erlang-standards` (frontera nombrada porque es una confusión real):
  `Phoenix.PubSub` y el paso de mensajes de la BEAM **no son un broker**. Viven dentro del clúster
  de aplicación, sin durabilidad, sin reintento y sin retención: si el proceso muere, el mensaje se
  pierde. **Si el mensaje debe sobrevivir al proceso que lo emitió, hace falta un broker y manda
  esta skill**; el reparto en memoria entre procesos de la misma aplicación es suyo.
- `streaming-cdc-standards` (**hermana; su regla de corte se espeja aquí palabra por palabra**):
  *si la decisión la toma el broker, es suya; si la toma el productor, el consumidor o el
  procesador, es de aquí* — es decir, **de esta skill**. Suyos: **semántica de entrega,
  idempotencia del consumidor, orden por partición y elección de la clave, evolución de esquema,
  tiempo de evento, ventanas, marcas de agua, retraso (*lag*) del consumidor, reprocesado y colas de
  fallidos.** *"¿Cuántas particiones aguanta el clúster?"* es de aquí; *"¿qué clave de partición
  elijo y qué orden me garantiza?"* es suya. **Aquí solo la configuración del broker que hace
  posibles sus patrones** (§3.6).
- `microservices-architecture-standards`: **outbox, sagas, eventos de dominio, propiedad del dato
  por servicio y resiliencia distribuida son suyos.** Aquí, el transporte por debajo. Un broker **no
  resuelve** la atomicidad entre escribir en tu base y publicar: eso es outbox, y es suyo.
- `timeseries-db-standards` (**línea declarada en ambos lados**): **un broker
  transporta las medidas, una base de series temporales las almacena para consultarlas.** Se cruzan
  en la ingesta IoT: el broker recibe del dispositivo, un consumidor escribe por lotes en el
  almacén. **El broker no es el almacén** (§7).
- `api-design-standards`: el contrato del mensaje hacia fuera, versionado y webhooks.
- `identity-access-management-standards` (identidad de quien se conecta),
  `cryptography-pki-standards` (**TLS y mTLS: elección de algoritmos, emisión y rotación de
  certificados son suyos**; aquí solo la exigencia y su configuración en el broker),
  `secrets-management-standards` (credenciales del broker), `networking-standards` y
  `firewall-policy-standards` (segmentación y exposición de puertos),
  `kubernetes-standards` (operadores y despliegue en clúster), `iac-standards`, `cicd-standards`,
  `observability-standards` (**el backend de métricas, PromQL y los cuadros de mando son suyos**;
  aquí **qué medir** de un broker), `sre-practice-standards` (SLO, guardia),
  `incident-management-standards`, `backup-recovery-standards` (**el log del broker no es una copia
  de seguridad**), `bcdr-standards`, `vulnerability-management-standards` (CVE y EOL),
  `grc-compliance-standards`, `privacy-engineering-standards` (**un topic con retención larga es una
  copia más del dato personal**), `jvm-spring-standards` (**Kafka y Pulsar son JVM**: *build*, GC,
  tests y empaquetado de los clientes y de las aplicaciones son suyos), `python-standards`,
  `aws-standards`/`azure-standards`/`gcp-standards` (**MSK, Event Hubs, Pub/Sub, SQS/SNS y demás
  gestionados**: sus límites, cuotas, IAM y precio concretos son suyos; **aquí el criterio de cuándo
  el gestionado es la respuesta correcta**, §2.4), `caching-cdn-standards`
  (**Redis/Valkey como caché es suya**; **Redis Streams o listas usados como cola son de aquí**, y el
  criterio está en §2.3).

**Principio rector**: **un broker no es una decisión de tecnología, es una decisión de topología.**
Lo que se elige de verdad no es "Kafka o RabbitMQ", es **si el mensaje se retiene y se puede releer,
o se consume y desaparece**. Equivocarse en eso es rehacer la arquitectura; equivocarse en el
producto dentro de la familia correcta es una migración molesta.

## 2. Decisiones por defecto

> Verificar versión, licencia y **propiedad** por web antes de fijarlo en un proyecto real (§8).
> En 2026 este sector cambió de manos y de licencia: **IBM completó la adquisición de Confluent el
> 17-mar-2026** y **Synadia intentó relicenciar NATS bajo BSL en 2025**.

### 2.1 La pregunta previa: ¿necesitas un broker?

`data-platform-standards` ya lo dice —**un almacén por necesidad, no por moda**— y aquí se refuerza
sin diplomacia: **una tabla en PostgreSQL con `SELECT ... FOR UPDATE SKIP LOCKED` resuelve una cola
de trabajo sencilla sin operar un sistema distribuido más.** Y trae de regalo lo que más cuesta
construir alrededor de un broker: **la tarea y el cambio de estado del negocio en la misma
transacción**, consultas SQL sobre la cola, y respaldo, HA y monitorización que ya tienes montados.

| Necesidad | Solución más simple | Cuándo deja de servir de verdad |
|---|---|---|
| Ejecutar trabajo en diferido (correos, informes, miniaturas) con volumen moderado | **Tabla + `SKIP LOCKED`** en la base que ya tienes | Cuando la tasa satura la base, o el trabajo compite con la carga transaccional |
| Lo mismo, pero sin querer escribir la maquinaria | **Biblioteca de colas sobre la propia base** del ecosistema del lenguaje | Igual que arriba |
| Notificar a **un** servicio conocido, sin pérdida tolerable | **Llamada HTTP con reintentos y outbox** (ver `microservices-architecture-standards`) | Cuando hay muchos destinatarios o no se conocen de antemano |
| **Varios** consumidores independientes del **mismo** evento, cada uno a su ritmo | **Log distribuido** | — |
| Reparto de trabajo entre trabajadores con enrutado por criterio y reintentos por mensaje | **Cola de mensajes** | — |
| Absorber picos que la base no aguanta, o desacoplar equipos con SLA distintos | **Broker** | — |

Preguntas que zanjan la discusión:
1. **¿Cuántos mensajes por segundo, medidos en el pico?** Si son decenas o cientos, la tabla sobra.
2. **¿Alguien necesita releer lo ya procesado?** Si no, no necesitas un log; una cola basta.
3. **¿Quién opera el clúster, lo actualiza y responde de madrugada?** Si no hay respuesta, la
   respuesta es el gestionado o la tabla.

### 2.2 Las dos familias que se confunden — **la diferencia central**

| | **Log distribuido** | **Cola de mensajes** | **Mensajería ligera** |
|---|---|---|---|
| Ejemplos | Kafka, Pulsar, Redpanda | RabbitMQ, ActiveMQ, SQS | NATS (núcleo) |
| Qué le pasa al mensaje | **Se retiene por política (tiempo/tamaño) y se puede releer**; el consumidor lleva su posición | **Se consume y desaparece** al confirmar | Se entrega a quien está escuchando **ahora**; si no hay nadie, se pierde |
| Varios consumidores del mismo mensaje | Natural: cada grupo lleva su propia posición | Necesita duplicar por *exchange*/*fanout*, con una cola por consumidor | Natural (publicación/suscripción) |
| Orden | Garantizado **dentro de una partición** | Por cola, y se rompe con reparto entre varios consumidores | No garantizado |
| Reproceso desde el principio | **Sí**: es su razón de ser | **No**: lo consumido ya no está | No |
| Enrutado por criterio | Pobre: el consumidor filtra | **Rico**: *exchanges*, *bindings*, prioridades, TTL, enrutado por cabecera | Por asunto, con comodines |
| Coste de operar | **Alto** | Medio | **Bajo** |
| Fallo típico | Retención mal puesta y disco lleno | Cola que crece sin consumidor y tumba el nodo | Se asume durabilidad que no existe |

**La elección de familia es lo que hay que acertar**:
- **¿Necesitas releer, alimentar varios sistemas independientes, o reconstruir un destino nuevo
  desde el histórico?** → **log**.
- **¿Necesitas repartir trabajo con enrutado, prioridad, reintento y descarte por mensaje?** →
  **cola**.
- **¿Necesitas señalización o petición/respuesta de baja latencia entre servicios, y puedes perder
  lo que nadie escuchó?** → **mensajería ligera**.

**Elegir un log para una cola de trabajo** te obliga a construir a mano reintentos por mensaje,
prioridades y descartes, y el paralelismo te queda atado al número de particiones. **Elegir una cola
para un flujo de eventos** te deja sin reproceso el día que lo necesitas — y ese día llega. **Se
rehace la arquitectura, no la configuración.**

### 2.3 Toolchain

| Ámbito | Default | Estado verificado (ago 2026) | Cuándo elegirlo |
|---|---|---|---|
| **Ninguno** | **Tabla + `SKIP LOCKED`** | Ver `data-platform-standards` | Escalón 0. La mayoría de las "colas" |
| **Log distribuido** | **Apache Kafka 4.3.x** (4.3.1 en el sitio de distribución; ramas vivas 4.1.2, 4.2.1, 4.3.1) | **Apache 2.0, ASF.** **KRaft es el único modo desde 4.0** (18-mar-2025): ZooKeeper **eliminado**, no deprecado. **La adquisición de Confluent por IBM no afecta a la licencia de Kafka**: el proyecto es de la ASF | Default de la familia log. Ecosistema y contratación imbatibles |
| Log, alternativa compatible con la API de Kafka | **Redpanda 26.2.1** (28-jul-2026) | **No es open source**: núcleo bajo **BSL 1.1** con *Additional Use Grant* que **prohíbe usarlo para ofrecer un "Streaming or Queuing Service"**; **Change Date = 4 años desde la fecha de cada versión**, *Change License* Apache 2.0. Funciones Enterprise bajo **Redpanda Community License Agreement** aparte | Menos piezas que operar (sin JVM, sin ZooKeeper) a cambio de licencia no OSI y ecosistema menor. **ADR obligatorio** |
| Log, alternativa multi-tenant | **Apache Pulsar 4.2.4** (3-ago-2026; rama LTS **4.0.x** con 4.0.13 el mismo día; **5.0.0-M1** en jun-2026) | **Apache 2.0, ASF. Proyecto vivo**, con cadencia real y LTS | Multi-tenencia nativa, geo-replicación y separación cómputo/almacenamiento. **Coste**: dos sistemas con estado (brokers + BookKeeper) y menos gente que sepa operarlo |
| **Cola de mensajes** | **RabbitMQ 4.3.x** (4.3.0 el 23-abr-2026; 4.3.4 el 23-jul-2026) | **MPL 2.0** para el servidor y sus *plugins* de nivel 1 (*verbatim* del `LICENSE`). En 4.0 se **eliminaron las colas clásicas espejadas**; en 4.3 **Khepri es el único almacén de metadatos y Mnesia desapareció**. Erlang 27 como mínimo en la serie 4.3. **Ojo: el soporte comunitario de la serie 4.3 termina el 30-nov-2026** — la cadencia de esta rama es corta y obliga a plan de actualización | Default de la familia cola. Enrutado rico y madurez |
| **Mensajería ligera** | **NATS 2.14.4** (30-jul-2026) | **Apache 2.0** (*verbatim* del `LICENSE`). **Gobernanza resuelta**: tras el intento de Synadia de relicenciar bajo BSL y reclamar la marca (mar-abr 2025), el acuerdo con la CNCF (may-2025) **asignó las marcas a la Linux Foundation** y dejó repositorios y dominio bajo la CNCF, con el núcleo garantizado en Apache 2.0 | Baja latencia, huella mínima, borde/IoT. **JetStream** añade persistencia y flujos cuando hace falta durabilidad |
| **Gestionado del proveedor** | **La respuesta correcta más veces de las que se admite** | Servicios y límites concretos en las skills de nube | §2.4 |
| **MQTT** (borde/IoT) | Broker MQTT dedicado delante, puente hacia el log | Producto y versión **no verificados** en esta revisión (§8) | Cuando el productor es un dispositivo de campo. **No expongas el broker principal a los dispositivos** |
| **Redis/Valkey como cola** | **No** por defecto | El uso como caché es de `caching-cdn-standards` | Aceptable solo para trabajo efímero y tolerante a pérdida, **declarado como tal en ADR**, con su durabilidad y su HA evaluadas aparte. Nunca "aprovechando" la instancia de caché |

**Estado que hay que decir**: **ActiveMQ y los brokers JMS clásicos** siguen siendo válidos donde ya
existen y hay integración JMS de verdad; **no son la elección para algo nuevo** salvo requisito de
protocolo. **ZooKeeper como dependencia de Kafka ya no existe** (§3.1): cualquier guía, imagen o
`docker-compose` que lo incluya está desactualizado y es una señal de alarma sobre esa fuente.

### 2.4 Gestionado frente a autogestionado

**Si ya estás en una nube y no tienes plataforma dedicada, usa su servicio gestionado.** No es
pereza: es no montar un sistema de consenso con estado que hay que parchear, reequilibrar y
actualizar. Criterio honesto:

| Elige **gestionado** si | Elige **autogestionado** si |
|---|---|
| No tienes equipo de plataforma con guardia | Tienes equipo que ya opera sistemas con estado |
| El volumen es moderado y el pico es acotado | El volumen es alto y sostenido: **es donde el gestionado se dispara** |
| Estás en una sola nube y el coste de salida es asumible | Multi-nube, on-prem, o soberanía del dato |
| Necesitas cumplimiento y certificaciones ya hechas | Necesitas afinar el motor a fondo |

**El punto de equilibrio real es de personal, no de factura**: el gestionado sale caro por volumen,
el autogestionado sale caro por **persona-año** (§6.4). Y el coste de salida del gestionado es la
**reescritura de productores y consumidores** si el protocolo es propietario: **prefiere el
gestionado que habla el protocolo del proyecto abierto** (Kafka, AMQP) y regístralo en el ADR.

## 3. Configuración y operación

### 3.1 Kafka: la operación de verdad

Esto es lo que `data-platform-standards` no cubre y lo que decide si tu clúster aguanta.

**KRaft y el fin de ZooKeeper**
- **Desde Kafka 4.0 solo existe KRaft.** El modo ZooKeeper fue **eliminado**. Migrar desde un
  clúster con ZooKeeper exige pasar por la **versión puente 3.9** antes de subir a 4.x: **no hay
  salto directo**, y si intentas actualizar sin migrar, no arranca.
- **Los controladores son un quórum Raft**: número impar (**3 en producción; 5 solo con
  justificación**), en dominios de fallo distintos. Perder el quórum de controladores **para las
  operaciones de metadatos** de todo el clúster.
- **Controladores dedicados frente a nodos combinados**: combinados (`process.roles=broker,controller`)
  solo en laboratorio o clústeres pequeños con el riesgo asumido; **en producción, dedicados**.
- **El formateo del almacenamiento es un paso irreversible** con un identificador de clúster: si
  formateas un nodo con el identificador equivocado, no se une. Va en el procedimiento de
  aprovisionamiento, no en la memoria de nadie.

**Particiones: la decisión difícil de deshacer**
- **El número de particiones fija el paralelismo máximo de un grupo de consumidores.** Más
  consumidores que particiones = consumidores ociosos.
- **Subir particiones es fácil; bajarlas, no.** No existe una operación de reducción: se hace
  creando un topic nuevo y migrando productores y consumidores. **Y subirlas tampoco es gratis**:
  **rompe la afinidad de la clave con la partición**, así que los mensajes de una misma entidad
  dejan de ir a la misma partición y **el orden histórico se pierde** (la elección de clave y sus
  consecuencias son de `streaming-cdc-standards`).
- Regla de dimensionado: **parte del paralelismo de consumo que necesitas, con margen de
  crecimiento razonable, no de una cifra copiada de un blog.** Sobredimensionar tampoco es gratis:
  cada partición cuesta descriptores, memoria, metadatos y **tiempo de recuperación tras la caída de
  un nodo**. Miles de particiones por nodo es un problema operativo, no una virtud.
- **Vigila el sesgo**: una clave caliente satura su partición y el resto del clúster está ocioso.
- **Reasignar particiones entre nodos consume red**: hazlo con limitación de tasa (*throttle*) o
  degradarás la producción mientras dure.

**Durabilidad: `acks`, réplicas y el compromiso con la latencia**

| Configuración | Qué garantiza | Coste |
|---|---|---|
| `acks=0` | Nada. El productor no espera | **Pérdida silenciosa. Vetado** salvo telemetría desechable declarada |
| `acks=1` | El líder lo tiene; **si el líder cae antes de replicar, se pierde** | Menor latencia, pérdida real en fallo |
| **`acks=all` + `RF=3` + `min.insync.replicas=2`** | El mensaje está en al menos 2 réplicas antes de confirmar | **Default para todo dato que importe.** Más latencia de escritura |

- **`min.insync.replicas` sin `acks=all` no hace nada.** Es el error de configuración más común del
  producto: la garantía la dan **los dos juntos**.
- **`RF=3` con `min.insync.replicas=2` es el punto correcto**: tolera un nodo caído **sin dejar de
  aceptar escrituras**. Con `RF=3` y `min.insync=3`, un solo nodo caído **para las escrituras**.
- **`unclean.leader.election` desactivado**: activarlo es aceptar por escrito la pérdida de datos
  confirmados a cambio de disponibilidad. Puede ser una decisión legítima; **nunca un descuido**.
- **Reparto por dominio de fallo** (`rack awareness` o equivalente): tres réplicas en el mismo
  bastidor o zona no son tres réplicas.

**Retención y compactación**
- **Retención por tiempo y por tamaño son dos límites que actúan a la vez**, y **el que primero se
  cumple gana**. Fija **ambos**: solo por tiempo, un pico de tráfico llena el disco; solo por
  tamaño, no puedes prometer una ventana de reproceso.
- **La retención se fija por topic, nunca solo global.** Y la global por defecto es la que llena
  discos en clústeres compartidos.
- **Compactación (`cleanup.policy=compact`)**: conserva **el último valor por clave**, para tener el
  estado actual reconstruible. Úsala en **cambios de estado con clave** (tablas de referencia,
  configuración, estado por entidad). **No la uses** para flujos de eventos donde cada suceso
  importa por sí mismo: **la compactación destruye el histórico** y esa pérdida no se recupera.
  Advertencias: **no es inmediata** (depende del limpiador y de los umbrales del segmento), **exige
  clave no nula**, y **un borrado se representa con un mensaje de valor nulo** cuyo tratamiento en
  el consumidor es de `streaming-cdc-standards`.
- **Almacenamiento por niveles (*tiered storage*)** cuando quieras retención larga sin disco caro:
  verifica su estado en tu versión y **prueba la lectura desde el nivel frío**, que es donde
  aparecen las sorpresas de latencia y de coste de recuperación.

**Reequilibrios de consumidores y sus pausas**
- **Un reequilibrio pausa el consumo del grupo.** Con el protocolo clásico es una parada total del
  grupo; con el protocolo de grupo de consumidores nuevo (disponible en las series 4.x) el impacto
  es mucho menor. **Verifica qué protocolo usan tus clientes**, porque no basta con actualizar el
  clúster.
- **Causas evitables de reequilibrio**: despliegues rodantes sin identidad estable, tiempos de
  espera de sesión mal ajustados, y sobre todo **un consumidor que tarda más en procesar un lote que
  el intervalo máximo permitido** — el clúster lo da por muerto y desencadena un reequilibrio, que
  ralentiza más, que provoca otro. **Es un bucle de degradación clásico**: se corta bajando el
  tamaño del lote o subiendo el intervalo, con criterio.
- **Reduce el impacto** con pertenencia estática y reequilibrio cooperativo, y **despliega con
  cuidado**: cada reinicio de un consumidor es un reequilibrio.

**El coste de operar Kafka de verdad** — dilo antes de que alguien firme:
controladores en quórum, réplicas y su reequilibrio, disco por topic con retención, red de
replicación, actualizaciones rodantes coordinadas, versiones de protocolo entre clientes y brokers,
autenticación y ACL por principal, y **guardia**. **Kafka no es "un servicio más": es una
plataforma.** Si nadie va a dedicarle tiempo, o es gestionado, o no es Kafka.

### 3.2 RabbitMQ

- **Modelo**: el productor publica en un ***exchange***, las ***bindings*** deciden en qué colas
  entra, y el consumidor lee de la cola. **El enrutado vive en el broker**, que es justo lo que un
  log no te da. Usa `direct` para enrutado exacto, `topic` para patrones, `fanout` para difundir; y
  **declara todo por código** (`rabbitmqadmin` o definiciones exportadas), nunca a mano en la
  consola.
- **Colas quorum por defecto para cualquier cosa que importe.** Las **colas clásicas espejadas se
  eliminaron en RabbitMQ 4.0**, tras años de deprecación: si una guía o un fichero de definiciones
  las menciona, **está caducado**. Las colas clásicas siguen existiendo, pero **ya no son
  replicables**: valen para trabajo efímero de un solo nodo y poco más.
- **Colas *stream*** cuando lo que quieres es un log re-leíble dentro de RabbitMQ. **Antes de
  usarlas, pregunta si el caso es realmente de la familia log** (§2.2): a veces la respuesta es que
  el broker correcto era otro.
- **Khepri**: en la serie 4.3, **el único almacén de metadatos; Mnesia se eliminó**. Consecuencia
  operativa buena: la recuperación tras partición de red pasa a ser uniforme (semántica Raft para
  metadatos, colas quorum y *streams*). Consecuencia mala: **es un cambio con estado en la
  actualización** — ensáyalo (§4).
- **Confirmaciones, en los dos sentidos, y son obligatorias**:
  - **Del lado del productor**: *publisher confirms*. **Sin ellas, publicar es fuego y olvido y el
    mensaje se pierde en un fallo del broker**, aunque tu código no vea ningún error.
  - **Del lado del consumidor**: confirmación **manual y después de procesar**. Confirmación
    automática = pérdida silenciosa en cuanto el proceso muera a medias.
- **`prefetch` (`basic.qos`) siempre fijado, y bajo.** Sin límite, un consumidor se lleva miles de
  mensajes a memoria, los demás se quedan sin trabajo y, si muere, **todo eso vuelve a la cola de
  golpe**. Valores altos solo con mensajes muy pequeños y proceso muy rápido, medido.
- **Los mensajes sin confirmar consumen memoria del broker**: un consumidor lento con `prefetch`
  alto es una de las formas habituales de tumbar un nodo. **Vigila `messages_unacknowledged`**, no
  solo la profundidad de la cola.
- **Límites por cola** (longitud máxima, TTL de mensaje, política de descarte) declarados como
  política. **Una cola sin límite crece hasta el bloqueo del broker por presión de memoria o
  disco**, y entonces se para *todo*, no solo esa cola.

### 3.3 NATS y JetStream

- **El núcleo de NATS no es duradero**: lo que se publica sin suscriptor activo se pierde. Es un
  diseño, no un defecto, y **es exactamente el malentendido que provoca el incidente**.
- **JetStream** añade persistencia, flujos y consumidores duraderos, con retención por límites, por
  intereses o de tipo cola. **Si necesitas durabilidad, la necesitas explícitamente**: activar
  JetStream, definir el flujo, su almacenamiento, sus réplicas y su retención. Nada de eso viene
  solo.
- **Réplicas de un flujo**: 3 para tolerar fallo (Raft). Un flujo con una réplica es una
  conveniencia, no durabilidad.
- **Encaje correcto**: baja latencia, huella pequeña, borde, dispositivos, comunicación entre
  servicios con petición/respuesta. **No lo elijas como sustituto directo de un log de alto volumen
  con reproceso masivo sin haberlo probado con tu carga.**
- **Gobernanza (dato de adopción, no anécdota)**: el episodio de 2025 —intento de mover a BSL y de
  reclamar la marca, resuelto con la asignación de las marcas a la Linux Foundation y el núcleo
  garantizado en Apache 2.0— **es el motivo por el que NATS sigue siendo adoptable**. Verifícalo
  vigente (§8).

### 3.4 Pulsar y Redpanda: criterio

- **Pulsar** vale la pena si necesitas **multi-tenencia real con aislamiento y cuotas por inquilino,
  geo-replicación integrada, o separar cómputo de almacenamiento** para escalar por separado.
  **Precio**: **operas dos sistemas con estado** (brokers y BookKeeper), y hay bastante menos gente
  con experiencia. Si tu motivo es "es más moderno", el motivo no es suficiente.
- **Redpanda** vale la pena si quieres **la API de Kafka con muchas menos piezas** (sin JVM, sin
  quórum externo) y menos afinado. **Precio**: **no es open source** — BSL 1.1 con una concesión de
  uso que **excluye ofrecer un servicio de streaming o de colas**, y funciones Enterprise bajo
  licencia propia aparte. **Léelo antes de adoptarlo si tu producto es una plataforma para
  terceros**, porque ahí es donde la cláusula muerde. **ADR obligatorio** con el análisis de la
  licencia y el plan de salida (la compatibilidad con la API de Kafka es lo que lo hace viable:
  consérvala como palanca, no dependas de extensiones propias).

### 3.5 Multi-tenencia y aislamiento

- **Un clúster compartido sin cuotas es un incidente esperando**: un productor descontrolado agota
  disco, red o conexiones y afecta a todos. Fija **cuotas por cliente/principal** (tasa de
  producción, de consumo y de peticiones) desde el principio, no después del primer susto.
- **Espacios de nombres y convención de nombres de topic/cola** con dueño identificable: `dominio.entidad.evento`
  o equivalente, **decidido y escrito**. Un clúster con nombres inventados por cada equipo es
  imposible de gobernar y de retirar.
- **Separa por criticidad, no por comodidad**: el clúster que sostiene pagos no comparte destino con
  el de experimentación.

### 3.6 Lo que el broker no resuelve solo (y la parte que sí le toca)

**Los patrones —reintentos, cola de fallidos, mensaje envenenado, deduplicación e idempotencia— son
de `streaming-cdc-standards`.** Lo que corresponde a esta skill es **dejar el broker configurado
para que sean posibles**:

- **Reintentos**: el broker debe permitir **redistribuir sin bloquear la partición o la cola** —
  en el modelo de cola, con reencolado y contador de entregas; en el modelo de log, **no existe
  reintento por mensaje**, así que el reintento se implementa con topics de reintento escalonados o
  fuera del broker. **Es una diferencia de familia que hay que conocer antes de elegir** (§2.2).
- **Cola de fallidos**: es **un destino más que hay que crear, dimensionar, retener, asegurar y
  monitorizar como cualquier otro** (y contiene datos reales: control de acceso y retención
  propios). El broker no la crea solo.
- **Mensaje envenenado**: fija **un límite de entregas** o el equivalente de tu broker. Un mensaje
  que se reintenta sin fin **bloquea la partición o satura la cola**, y para el flujo entero.
- **Deduplicación**: **si tu broker ofrece deduplicación, conoce su ventana y su alcance** —suele
  ser acotada en tiempo y por productor, y **no sustituye a la idempotencia del consumidor**, que es
  la única defensa real.
- **Orden**: el broker garantiza orden **por partición o por cola sin reparto**. En el momento en
  que varios consumidores comparten una cola, **el orden se acabó**. Dilo al diseñar, no al depurar.

## 4. Calidad y testing — gates

En orden de coste creciente. **Los marcados como gate rompen el build o el despliegue.**

1. **ADR de §2.1 y §2.2**: por qué hace falta un broker frente a una tabla con `SKIP LOCKED`, y por
   qué **esa familia**. *Gate de diseño.*
2. **Topics, colas, políticas, cuotas y ACL como código**, versionados y aplicados por el pipeline.
   **Nada creado a mano en la consola de producción.** *Gate de CI.*
3. **Sin secretos en la configuración ni en los ficheros de definiciones**: credenciales desde el
   gestor de secretos. *Gate de CI.*
4. **Validación de configuración crítica en CI**: todo topic de dato importante con `RF>=3`,
   `min.insync.replicas=2`, `acks=all` en el productor, **retención por tiempo *y* por tamaño
   declaradas**, y `unclean.leader.election` desactivado. Un cambio que lo incumpla **rompe el
   build**. *Gate.*
5. **Prohibida la creación automática de topics** en producción (`auto.create.topics.enable=false`)
   y su equivalente en colas: un error tipográfico no debe crear infraestructura. *Gate.*
6. **Tests de integración contra el broker real en contenedor**, no contra dobles: **el
   comportamiento del broker es lo que se está probando**. Cubriendo bordes: **broker no disponible
   al publicar**, **consumidor que muere entre procesar y confirmar**, **mensaje que supera el
   tamaño máximo**, **cola/partición vacía**, **límite de entregas alcanzado**.
7. **Prueba de confirmación del productor**: verificar que **una publicación sin confirmación no se
   da por buena** en el código. Es el fallo silencioso más caro del lado del productor.
8. **Prueba de caída de un nodo** con tráfico en curso: se verifica que no se pierde ningún mensaje
   confirmado y se mide cuánto dura la indisponibilidad. **Antes de producción, no después.**
9. **Ensayo de actualización de versión mayor** en espejo, con datos y clientes representativos y
   **plan de vuelta atrás definido** (§6.3). Obligatorio si hay cambio del almacén de metadatos
   (Khepri) o del modo de quórum.
10. **Prueba de restauración** del estado del broker y de sus definiciones (§6.2).
11. **Dependencias, imágenes y clientes fijados por digest**, con SBOM (§5). *Gate de CI.*

## 5. Seguridad del stack

- **Ningún broker sin autenticación. Nunca.** Es el hallazgo recurrente del dominio: brokers en
  redes internas "de confianza", puertos de gestión abiertos, oyentes sin autenticación "para que se
  conecten los dispositivos". Un broker sin autenticación es **lectura y escritura de todo el flujo
  de negocio** para cualquiera que alcance el puerto.
- **Autenticación fuerte y por principal**: SASL con mecanismo moderno o **mTLS**, con identidad por
  aplicación —**no una credencial compartida por todo el departamento**— y rotación. La emisión y
  rotación de certificados es de `cryptography-pki-standards`.
- **Autorización por topic/cola y por operación**, con **denegación por defecto**. Reglas duras:
  **un productor no necesita permiso de lectura**; un consumidor de un topic no necesita permiso
  sobre los demás; **el permiso de administración no lo tiene ninguna aplicación**.
- **TLS en tránsito siempre**, también entre nodos del clúster (replicación) y en el plano de
  gestión. "Es red interna" no es un argumento.
- **La consola y la API de gestión son superficie de ataque de primera**: detrás de identidad, con
  acceso restringido por red, y **nunca expuestas a Internet**. Hay CVE de 2026 de XSS almacenado en
  la interfaz de gestión de RabbitMQ (CVE-2026-44839) precisamente ahí.
- **Cuidado con los clientes, no solo con el servidor**: **CVE-2026-35554 (CVSS 8.7, publicado el
  7-abr-2026) afecta al cliente productor Java de Kafka** —una condición de carrera en el *pool* de
  buffers que puede **entregar mensajes en el topic equivocado, en silencio y sin error**, con la
  consiguiente exposición de datos a consumidores no autorizados—. **Corregido en 3.9.2, 4.0.2,
  4.1.2 y 4.2.0 o posteriores; en las ramas 2.8-3.8 no hay corrección**. Deriva: **inventaría las
  versiones de los clientes, no solo la del clúster.**
- **Retención y dato personal**: un topic retenido es **una copia más del dato**, con su
  clasificación, su retención declarada y su control de acceso; **un borrado en el origen no borra
  los mensajes anteriores**. La política es de `privacy-engineering-standards`; **el parámetro se
  fija aquí**.
- **Nada de PII en nombres de topic, de cola o de grupo de consumidores** — acaban en métricas,
  logs y cuadros de mando.
- **Cadena de suministro**: fija imágenes, operadores y bibliotecas cliente **por digest**; SBOM;
  cuarentena de días antes de adoptar una versión recién publicada. Precedentes verificados en el
  catálogo: Trivy (mar-2026), LiteLLM (mar-2026), `elementary-data` (abr-2026) y **Mini Shai-Hulud /
  CVE-2026-45321**, que **falsifica atestaciones SLSA nivel 3**: **la procedencia ya no es prueba
  suficiente por sí sola**.
- **Riesgo de licencia y de propiedad como riesgo de seguridad del suministro**: **IBM completó la
  compra de Confluent el 17-mar-2026** (~11.000 M$, 31 $/acción, filial al 100 %, salida del
  Nasdaq). **Kafka no se ve afectado: es de la ASF.** Pero la **Confluent Community License** —que
  cubre Schema Registry, REST Proxy, ksqlDB y varios conectores— **no es OSI** y prohíbe ofrecer
  esos componentes como servicio competidor. **Registra en el ADR de qué componentes con licencia no
  OSI dependes** y prefiere alternativas Apache (criterio ya fijado en `data-platform-standards`).

## 6. Rendimiento y operabilidad

### 6.1 Qué monitorizar (el backend y los cuadros de mando son de `observability-standards`)

- **Retraso del consumidor**: es la señal principal, pero **su interpretación y su alerta son de
  `streaming-cdc-standards`**. Lo que corresponde aquí es **que el broker lo exponga y que exista**.
- **Salud del clúster, que es lo propio de esta skill**: **particiones sin líder** (`offline`) y
  **particiones sub-replicadas**, encogimiento del conjunto de réplicas sincronizadas, salud del
  quórum de controladores, y **cambios de líder** (un goteo constante es síntoma, no ruido).
- **Colas**: profundidad, **mensajes sin confirmar**, tasa de entrada frente a tasa de salida (la
  derivada, no el valor absoluto), y **colas sin consumidor** — que es una fuga de disco con forma
  de cola.
- **Recursos**: **disco por nodo y por topic con proyección de agotamiento** (la alerta útil es
  "quedan N días", no "85 % lleno"), red de replicación, descriptores de fichero, conexiones y
  memoria.
- **Alerta accionable con runbook**: qué se rompió, qué depende, cómo se recupera, cuánto tarda.
- **Un broker con compromiso de disponibilidad exige guardia.** Sin guardia, el compromiso es una
  mentira documentada (`sre-practice-standards`).

### 6.2 Respaldo y recuperación

- **El respaldo de un broker es sobre todo el de su *configuración*: definiciones de topics/colas,
  políticas, cuotas, ACL y usuarios.** Si eso está como código (§4.2), ya lo tienes; si no, lo
  primero que hay que arreglar es eso.
- **Restaurar los datos de un broker es distinto de restaurar una base de datos** y hay que decidir
  de antemano qué significa recuperación: en muchos casos, la respuesta correcta es **reconstruir
  el clúster y reproducir desde el origen**, no restaurar mensajes. **Escríbelo en el plan de DR
  antes del incidente.**
- **El log del broker no es una copia de seguridad** (§7): no tiene el modelo de recuperación, ni la
  verificación, ni el aislamiento de una (`backup-recovery-standards`).
- **Réplica geográfica** (espejado entre clústeres, replicación geográfica nativa): es una
  herramienta de continuidad **con desfase y con dolores propios** —posiciones que no se traducen
  entre clústeres, bucles de replicación, orden— y **su promesa hay que probarla con un ejercicio
  real** (`bcdr-standards`), no darla por hecha porque el producto la anuncie.

### 6.3 Actualizaciones sin parar el tráfico

- **Actualización rodante, nodo a nodo**, esperando a que las réplicas vuelvan a estar sincronizadas
  **antes de tocar el siguiente**. Saltarse esa espera es cómo se pierde datos actualizando.
- **Lee las notas de versión mayor completas** buscando tres cosas: **eliminaciones** (ZooKeeper en
  Kafka 4.0, colas espejadas en RabbitMQ 4.0, Mnesia en RabbitMQ 4.3), **cambios en el almacén de
  metadatos** y **versión mínima de la plataforma base** (Erlang 27 para RabbitMQ 4.3).
- **Comprueba si hay versión puente obligatoria**: Kafka exige pasar por **3.9** para migrar de
  ZooKeeper a KRaft antes de 4.x.
- **Clientes y clúster se actualizan por separado y en el orden correcto.** Un cliente antiguo con
  un clúster nuevo puede funcionar y aun así dejarte sin una función que creías tener (el protocolo
  de grupo de consumidores nuevo, §3.1). **Inventaría versiones de cliente por aplicación.**
- **Vigila el fin de soporte de la rama**, que en algunos productos es **corto**: la serie 4.3 de
  RabbitMQ tiene soporte comunitario **hasta el 30-nov-2026**. Planifica la siguiente actualización
  el día que terminas la anterior.
- **Nunca una `.0` en producción.** Y nunca una actualización mayor sin ensayo en espejo (§4.9).

### 6.4 Capacidad y coste

- **Disco, red y retención son la misma decisión.** El disco necesario es, en esencia:
  *tasa de entrada × factor de replicación × ventana de retención*, con margen. **Si el número no
  cabe, lo que se ajusta es la retención, no el presupuesto.** Y **la replicación multiplica también
  el tráfico de red**, que es lo que casi nadie dimensiona hasta que satura.
- **Deja margen real de disco**: un broker con el disco lleno **no degrada, se para**, y recuperarlo
  con el disco al 100 % es una operación desagradable en caliente. Alerta por días restantes.
- **El coste del autogestionado se mide en persona-año**, no en instancias: aprovisionamiento,
  parcheo, actualizaciones, reequilibrios, guardia y formación. **El coste del gestionado se mide en
  volumen** y crece con él, más el tráfico entre zonas, que sorprende a todo el mundo.
- **El punto de equilibrio real**: mientras el volumen sea moderado, **el gestionado casi siempre
  gana** porque el coste de personal es superior a la factura. A partir de un volumen alto y
  sostenido, el autogestionado empieza a compensar **si y solo si ya tienes el equipo** — no si hay
  que crearlo.
- **Retira lo muerto**: topic o cola sin tráfico ni consumidores durante un trimestre se marca y se
  retira. La acumulación silenciosa es la que llena discos y confunde a los que llegan después.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisa **cada trimestre** versión, licencia **y propiedad** del broker y **de los
  clientes**. Este sector cambió de manos y de licencia en 2025-2026 (IBM/Confluent; el intento de
  BSL en NATS; Redpanda bajo BSL desde su origen).
- **ADR obligatorio** para: introducir un broker (frente a la tabla de §2.1), **elegir familia**
  (log / cola / ligera), elegir gestionado frente a autogestionado, adoptar un producto con licencia
  no OSI, fijar la retención de un topic, y **cambiar el número de particiones de un topic con
  claves**.
- **Documento de capacidad** con la cuenta de §6.4 y el punto de agotamiento de disco previsto.

**PROHIBIDO**
- ❌ Desplegar un broker sin haber descartado por escrito la tabla con `SKIP LOCKED` y la llamada
  con reintentos.
- ❌ Elegir familia por moda: **un log para una cola de trabajo**, o **una cola para un flujo que
  habrá que releer**.
- ❌ `acks=0` para dato que importe; **`min.insync.replicas` sin `acks=all`** (no garantiza nada).
- ❌ `RF=1` en producción; tres réplicas en el mismo dominio de fallo.
- ❌ Elección de líder no limpia activada sin decisión escrita que acepte la pérdida.
- ❌ Topic sin retención declarada **por tiempo y por tamaño**; retención infinita "por si acaso".
- ❌ **Compactación en un flujo donde cada evento importa por sí mismo** (destruye el histórico).
- ❌ Creación automática de topics activada en producción.
- ❌ Cola sin límite de longitud ni política de descarte.
- ❌ Publicar sin confirmación del productor; confirmar el consumo automáticamente o antes de
  procesar.
- ❌ Consumidor sin `prefetch` acotado; ignorar los mensajes sin confirmar en la monitorización.
- ❌ Reintento sin límite de entregas: un mensaje envenenado bloquea la partición o la cola.
- ❌ **Broker sin autenticación**, o con credencial compartida por varias aplicaciones.
- ❌ Consola o API de gestión expuestas a Internet, o sin identidad delante.
- ❌ TLS opcional "porque es red interna"; replicación entre nodos en claro.
- ❌ Permisos de administración a una aplicación; productor con permiso de lectura del topic.
- ❌ Clúster compartido sin cuotas por principal; mezclar pagos y experimentación en el mismo
  clúster.
- ❌ Topics, colas o ACL creados a mano en la consola de producción.
- ❌ **Usar el broker como base de datos o como almacén consultable** (el estado vive en un almacén
  de verdad; para series temporales, ver `timeseries-db-standards`).
- ❌ **Usar el log del broker como copia de seguridad.**
- ❌ Actualizar de versión mayor sin ensayo en espejo, sin plan de vuelta atrás o saltándose la
  versión puente obligatoria.
- ❌ Inventariar solo la versión del clúster y no la de los clientes (CVE-2026-35554).
- ❌ Seguir cualquier guía, imagen o `compose` que despliegue Kafka con ZooKeeper.
- ❌ Configurar colas clásicas espejadas en RabbitMQ (**eliminadas en 4.0**).
- ❌ Asumir durabilidad en el núcleo de NATS sin JetStream, o un flujo con una sola réplica.
- ❌ Adoptar un producto con licencia no OSI sin ADR y sin leer la cláusula de uso.
- ❌ PII en nombres de topic, de cola o de grupo de consumidores.
- ❌ Fijar versiones, licencias o propiedad de un broker de memoria (§8).

## 8. Verificación web obligatoria

Los datos de §2, §3 y §5 son de **agosto de 2026**, tomados de `api.github.com` y del sitio de
distribución de la ASF (versiones y fechas) y de los ficheros de licencia en crudo (licencias).
Antes de fijar nada en un entregable, verifica:

1. **Kafka**: rama vigente (**4.3.1** en el sitio de distribución, junto a 4.2.1 y 4.1.2; **Apache
   2.0**, ASF) y que **KRaft sigue siendo el único modo** desde 4.0 (18-mar-2025), con **3.9 como
   versión puente** desde ZooKeeper. Verifica también el estado del **protocolo de grupo de
   consumidores nuevo** y del **almacenamiento por niveles** en tu versión concreta.
2. **Propiedad y licencias**: **IBM completó la adquisición de Confluent el 17-mar-2026** (~11.000
   M$, 31 $/acción, filial al 100 %, delistada del Nasdaq). Comprueba el **estado actual de la
   Confluent Community License** (no OSI) y si el modelo de precios o soporte ha cambiado bajo IBM.
3. **Redpanda**: versión (**26.2.1**, 28-jul-2026) y **los términos exactos de la BSL 1.1**
   verificados *verbatim* en `licenses/bsl.md` —concesión adicional que excluye ofrecer un
   *"Streaming or Queuing Service"*, **Change Date a 4 años de cada versión**, *Change License*
   Apache 2.0— más la **Redpanda Community License Agreement** (`licenses/rcl.md`) que rige
   Community y Enterprise.
4. **Pulsar**: **4.2.4** (3-ago-2026), rama LTS **4.0.x** (4.0.13 el 3-ago-2026) y **5.0.0-M1**
   (jun-2026). Apache 2.0, ASF. Cadencia real: proyecto vivo.
5. **RabbitMQ**: **4.3.4** (23-jul-2026; 4.3.0 el 23-abr-2026), **MPL 2.0** (*verbatim* del
   `LICENSE`), **colas clásicas espejadas eliminadas en 4.0**, **Khepri único almacén de metadatos y
   Mnesia eliminado en 4.3**, Erlang 27 mínimo, y **fin de soporte comunitario de la serie 4.3 el
   30-nov-2026**. **Confirma esa fecha y la de la serie siguiente antes de planificar.**
6. **NATS**: **2.14.4** (30-jul-2026), **Apache 2.0** (*verbatim*), y que el acuerdo CNCF-Synadia de
   may-2025 sigue vigente (marcas asignadas a la Linux Foundation, repositorios y dominio bajo CNCF,
   núcleo en Apache 2.0). **Es un dato de adopción: re-verifícalo.**
7. **CVE**: **CVE-2026-35554** en `kafka-clients` (CVSS 8.7, 7-abr-2026; corregido en 3.9.2, 4.0.2,
   4.1.2, 4.2.0+; **sin corrección en las ramas 2.8-3.8**) y **CVE-2026-44839** (XSS almacenado en
   la interfaz de gestión de RabbitMQ). Revisa la lista oficial de CVE del proyecto y las de tus
   clientes, y la evolución de **Mini Shai-Hulud (CVE-2026-45321)** en la cadena de suministro.
8. **Gestionados**: límites, cuotas, modelo de precios y **coste del tráfico entre zonas** del
   servicio de tu nube, y si habla el protocolo del proyecto abierto o uno propietario.

**Huecos declarados de esta revisión** (no rellenar de memoria):
- **Confluent Community License bajo IBM**: verificada la operación (17-mar-2026) y sus términos
  financieros; **no verificado** ningún cambio en la licencia, el precio o el soporte tras el
  cierre. **No afirmes nada sobre su futuro.**
- **Redpanda**: verificados el texto de la BSL y la existencia de la RCL; **no verificado ningún
  tope numérico** (de núcleos, nodos o volumen) para la edición libre. Si necesitas un límite
  concreto, léelo en la documentación del producto.
- **QuestDB/otros no aplica aquí**; en cambio, **el broker MQTT recomendado (Mosquitto, EMQX,
  HiveMQ, NanoMQ) no se ha verificado** en versión, licencia ni estado. No cites ninguno como
  default.
- **ActiveMQ / Artemis**: versión, licencia y estado del proyecto **no verificados**.
- **Almacenamiento por niveles de Kafka**: **no verificado** su estado de madurez ni su
  disponibilidad exacta por versión y por distribución.
- **Protocolo de grupo de consumidores nuevo (rebalance cooperativo de nueva generación)**:
  verificado que existe en la línea 4.x; **no verificado** en qué versión exacta pasó a
  disponibilidad general ni qué versiones mínimas de cliente lo soportan.
- **Cifras de coste gestionado frente a autogestionado**: **ninguna verificada**. Todas las
  comparativas públicas las publican proveedores con interés en la respuesta. Calcúlalo con tus
  precios y tu coste de personal.
- **Comparativas de rendimiento entre brokers**: publicadas por los propios fabricantes
  (Redpanda-Kafka es el caso obvio). Trátalas como marketing, no como dato.
- **CVE de Pulsar, NATS y Redpanda**: **no revisados** uno a uno en esta revisión.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
