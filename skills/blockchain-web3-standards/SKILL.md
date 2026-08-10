---
name: blockchain-web3-standards
description: Blockchain and web3 as infrastructure, custody and regulation — not as smart-contract code. Use when justifying whether a distributed ledger is needed at all versus a signed append-only database, evaluating permissioned ledgers (Hyperledger Fabric, LF Decentralized Trust, R3 Corda, Besu, Quorum), running or outsourcing nodes and JSON-RPC endpoints (geth, erigon, reth, nethermind, lighthouse, Infura, Alchemy, QuickNode, eth_call rate limits, archive versus full node, state growth, snap sync), choosing L1 versus L2 rollups and reading their trust assumptions (L2Beat stages, sequencer centralisation, 7-day optimistic challenge window, forced inclusion, escape hatch), cross-chain bridges and wrapped assets as a loss vector, key custody and signing process (hardware wallet, HSM, multisig, Safe, threshold MPC, seed phrase handling, signing ceremony, key compromise as the dominant theft cause), oracles and price-feed manipulation, MEV, sandwiching and private order flow at the application level, indexing and reorg-safe event ingestion (The Graph, subgraphs, block confirmations, finality), stablecoin and payment rails operations, wallet UX and address poisoning, or the regulatory constraints MiCA (Regulation (EU) 2023/1114), the Transfer of Funds Regulation (EU) 2023/1113 travel rule, AML/KYC on-ramps, accounting and tax treatment.
---

# Estándares de blockchain y web3 (infraestructura, custodia y regulación)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

### 1.1 La pregunta previa y obligatoria: ¿necesitas una blockchain?

**Esta sección se responde antes que ninguna otra decisión técnica, y por escrito.** La
respuesta correcta en la gran mayoría de casos empresariales es **no**.

Una blockchain solo aporta algo cuando se cumplen **todas** estas condiciones a la vez:

1. **Hay varias partes que escriben**, no una sola organización con departamentos.
2. **Esas partes no se fían entre sí** — ni de un intermediario que pudiera arbitrar.
3. **No existe (ni puede existir) una autoridad común aceptada** que opere el registro: ni un
   notario, ni un regulador, ni un consorcio con un tercero de confianza contratado.
4. **Se necesita resistencia a la censura o a la reversión**, no solo trazabilidad.
5. **Los participantes no son conocidos ni permanentes**, o el conjunto cambia sin permiso de
   nadie.

Si falla **cualquiera** de las cinco, la respuesta es: **base de datos relacional con registro
de auditoría inmutable, firma digital por parte y sellado de tiempo**. Eso da integridad,
no repudio y trazabilidad verificable a una fracción del coste, con transacciones ACID,
consultas SQL, borrado por GDPR y un DBA que sabe restaurar el backup.

Corolario incómodo: **la "blockchain privada o permisionada" casi siempre es una base de
datos cara.** Si un consorcio decide quién puede escribir, quién valida y quién actualiza el
software, ya existe la autoridad común cuya ausencia justificaba la cadena — y se ha pagado
por replicación bizantina que nadie necesita. Hyperledger Fabric y Corda son piezas de
ingeniería serias (ambas **Apache-2.0**, `LICENSE` en crudo), y su valor real cuando se usan
bien es el **modelo de datos y de identidad compartido entre organizaciones**, no el
consenso. Antes de adoptarlas: comprobar el estado real del proyecto y su cadencia (§8), y
qué pasa con la operación si el consorcio se disuelve.

Segundo corolario: **la cadena no valida el mundo físico.** Anclar en un registro inmutable
un dato que introduce un humano no lo hace verdadero — lo hace *inmutablemente falso*. El
problema del "oráculo" no es técnico, es epistemológico, y ninguna cadena lo resuelve.

### 1.2 Qué cubre esta skill

Infraestructura (nodos, RPC, L1/L2, puentes, indexación), **custodia de claves y proceso
humano de firma**, oráculos, MEV a nivel de aplicación, y las restricciones regulatorias,
contables y fiscales que condicionan el diseño.

Triggers: `geth`, `erigon`, `reth`, `nethermind`, `lighthouse`, `prysm`, `eth_call`,
`eth_getLogs`, `JSON-RPC`, `Infura`, `Alchemy`, `QuickNode`, `archive node`, `snap sync`,
`reorg`, `finality`, `L2Beat`, `sequencer`, `rollup`, `challenge period`, `bridge`,
`wrapped`, `Safe`, `multisig`, `MPC`, `seed phrase`, `hardware wallet`, `Ledger`, `Trezor`,
`HSM`, `oracle`, `price feed`, `MEV`, `mempool`, `The Graph`, `subgraph`, `Fabric`,
`chaincode`, `Corda`, `Besu`, `MiCA`, `travel rule`, `VASP`, `CASP`.

**No aplica**: ver **`solidity-standards`** (**frontera dura y no negociable**: el **contrato
inteligente**, el **compilador `solc`**, la **EVM**, `pragma`, `evm_version`, proxies y
actualizabilidad, reentrada, tests de invariantes, fuzzing, verificación formal, auditoría de
código y gas. **Todo lo que se escribe en `.sol` y todo lo que se despliega es suyo, sin
excepción**; aquí solo dónde se ejecuta, quién firma, con qué llave y bajo qué norma),
`cryptography-pki-standards` (elección de algoritmo, curvas, gestión y ciclo de vida de clave
en HSM/KMS — aquí solo el **proceso operativo de custodia y firma** aplicado a una clave que
controla valor directamente), `post-quantum-crypto-standards` (**toda** la migración PQC y su
calendario; la amenaza cuántica sobre ECDSA no se trata aquí), `secrets-management-standards`
(Vault/KMS, credenciales efímeras, rotación), `identity-access-management-standards`
(federación, OIDC, JWT y la gobernanza de identidad corporativa),
`fintech-payments-standards` (**pagos, cuentas, conciliación, PSD2/SEPA y la operación de una
entidad financiera**; los criptoactivos como medio de pago se coordinan con ella — **no se
duplica**), `grc-compliance-standards` (marco de riesgo, SoA, evidencia y auditoría; aquí
solo la traducción a requisito de diseño), `privacy-engineering-standards` (**el conflicto
estructural entre inmutabilidad y derecho de supresión**: es suyo el criterio, aquí la
prohibición de escribir datos personales en cadena), `appsec-standards` (metodología STRIDE,
OWASP y triaje de hallazgos), `incident-response-forensics-standards` (gestión del incidente,
trazado de fondos y coordinación con exchanges), `offensive-security-standards` (pruebas
ofensivas con alcance y autorización; **esta skill es defensiva**), `observability-standards`
(plataforma de telemetría y SLOs), `data-engineering-standards` y `streaming-cdc-standards`
(los pipelines que ingieren eventos de cadena a un almacén analítico),
`vulnerability-management-standards` (triaje de CVE del cliente de nodo),
`opensource-licensing-standards` (licencias del stack), `rust-standards` / `go-standards` /
`typescript-standards` (el lenguaje de los servicios que hablan con la cadena),
`quantum-computing-standards` (nada que ver con "web3 cuántico").

## 2. Decisiones por defecto

> Verificar por web antes de fijar nada (§8). Los datos regulatorios y de versión de este
> dominio caducan en meses.

| Decisión | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| ¿Blockchain? | **No.** BD relacional + log de auditoría firmado + sellado de tiempo | Cadena pública si se cumplen las cinco condiciones de §1.1 | Adoptarla porque un stakeholder la pidió por nombre |
| Si hay cadena | **Cadena pública establecida** con historial de disponibilidad y ecosistema de auditores | Permisionada **solo** con consorcio real, gobernanza escrita y plan de salida | Cadena nueva porque tiene comisiones bajas |
| Nodos | **Nodo propio full** para lectura crítica + proveedor RPC como *fallback* | Solo proveedor si la operación tolera su caída y su censura | **Un único proveedor RPC** como dependencia dura |
| Confirmaciones | Esperar **finalidad** del protocolo, no "N bloques" copiado de un blog | Menos confirmaciones para UX no financiera, documentado | Considerar una transacción firme al minarse |
| L2 | Elegir por **supuestos de confianza documentados** (L2Beat stage), no por TPS | L1 directo si el coste lo permite: menos supuestos | Tratar un L2 en *stage 0* como si fuera Ethereum |
| Puentes | **Evitarlos.** Diseñar para no cruzar cadenas | Puente canónico del propio rollup, nunca uno de terceros, con límites de exposición | Puentes de terceros custodiando valor material (§5.2) |
| Custodia | **Multifirma con umbral (Safe) o MPC**, firmantes en dispositivos distintos y personas distintas | HSM certificado si la operación es institucional | **Una sola clave caliente** con poder de mover fondos |
| Datos en cadena | **Solo hashes y compromisos.** El dato vive fuera | Datos públicos por naturaleza y ya publicados | Cualquier dato personal, ni cifrado (§5.5) |
| Oráculo | **Feed descentralizado y agregado**, con validación de rango, *staleness* y circuit breaker | Oráculo propio firmado si el consumidor eres tú y asumes el riesgo | Precio *spot* de un único DEX (§5.3) |
| Regulación | Determinar **antes de diseñar** si la actividad cae bajo MiCA y si eres CASP | — | Diseñar primero y consultar a legal después |

## 3. Infraestructura: lo que cuesta de verdad

### 3.1 Nodos

- **Un nodo no es un contenedor que se levanta y ya.** Es una máquina con SSD NVMe grande y
  creciente, ancho de banda constante, sincronización inicial de horas o días, y **estado que
  crece de forma monótona**. La capacidad se planifica con la tasa de crecimiento del estado,
  no con el tamaño de hoy.
- **Nodo *full* vs *archive***: el *full* responde al estado reciente; el *archive* guarda
  todos los estados históricos y multiplica el almacenamiento por un orden de magnitud. Casi
  nadie necesita *archive*: si la respuesta es "para consultas históricas", el sitio correcto
  es un **índice propio en una base de datos analítica**, no un archive node.
- **Diversidad de cliente**: la documentación de Ethereum lo dice explícitamente —
  *"Multiple client implementations can make the network stronger by reducing its dependency
  on a single codebase. The ideal goal is to achieve diversity without any client dominating
  the network, thereby eliminating a potential single point of failure."* Si operas varios
  nodos, **no todos con el mismo cliente**.
- **Actualizaciones de protocolo (*hard forks*) son ventanas de indisponibilidad
  planificadas**: un nodo sin actualizar a tiempo se queda en una cadena minoritaria y sirve
  datos falsos sin dar error. Suscribirse a los anuncios del cliente y del protocolo es
  operación, no interés personal.

### 3.2 La ironía del proveedor RPC

La descentralización de la aplicación media termina en **dos o tres proveedores de RPC**. Un
frontend "descentralizado" que apunta a un único endpoint gestionado tiene exactamente el
mismo SPOF que cualquier SaaS, más la falsa sensación de no tenerlo. Y además el proveedor
**ve** todas las direcciones y consultas de tus usuarios: es un punto de correlación y de
censura, no solo de disponibilidad.

Criterio: al menos **dos proveedores independientes con conmutación automática**, y para
lectura crítica (saldos, confirmación de pagos, liquidaciones) **un nodo propio como fuente
de verdad**. Todo lo que devuelve un RPC ajeno es una **afirmación de un tercero**, no una
verdad criptográfica, salvo que verifiques pruebas.

### 3.3 L1, L2 y rollups: leer los supuestos de confianza

- Un rollup **hereda la seguridad del L1 solo en la medida en que sus mecanismos de salida
  funcionen sin permiso**. Comprobar antes de desplegar: ¿el secuenciador es único y
  centralizado? ¿existe **inclusión forzada** desde L1? ¿hay **escotilla de salida** si el
  operador desaparece? ¿quién puede actualizar los contratos del puente canónico y con qué
  *timelock*? ¿hay pruebas de fraude/validez **activas**, o desactivadas "de momento"?
- **El periodo de retirada de los rollups optimistas es un riesgo operativo real, no un
  detalle.** La documentación de OP Stack: *"mainnet messages sent from Layer 2 to Layer 1
  cannot be relayed for at least 7 days"*. La de Arbitrum menciona *"a 6.4-day challenge
  period"* para mensajes L2→L1 y *"a seven-day challenge period to safeguard withdrawals"* en
  el puente canónico. L2Beat exige *"a ≥7 days challenge period for all Optimistic Rollups to
  be considered Stage 1"*.
  **Consecuencia de tesorería**: el capital en el L2 es **ilíquido durante una semana** por la
  vía canónica. Las alternativas rápidas son puentes de liquidez de terceros — que sustituyen
  el retraso por **riesgo de contraparte**. Si tu modelo financiero asume liquidez inmediata,
  está mal. Modelar el peor caso: retirada canónica + congestión del L1.
- **Clasificación L2Beat como herramienta de decisión**, con su criterio explícito para Stage
  1: *"The only way (other than bugs) for a rollup to indefinitely block an L2→L1 message
  (e.g. a withdrawal) or push an invalid L2→L1 message (e.g. an invalid withdrawal) is by
  compromising ≥75% of the Security Council"*, y *"Users are able to exit without the help of
  the permissioned operators"*. Verificar el *stage* actual de la cadena concreta antes de
  comprometer fondos (§8).

### 3.4 Indexación y reorganizaciones

- **Nunca leer el estado de la aplicación consultando la cadena en caliente.** Se indexa a una
  base de datos propia y se sirve desde ahí. Consultar `eth_getLogs` en la ruta caliente es
  lento, caro y frágil.
- **El indexador debe ser reorg-safe**: los bloques recientes pueden desaparecer. Diseño
  correcto: marcar los eventos por número de bloque y hash, y **revertir** los eventos de
  bloques huérfanos; no consumir eventos por debajo del umbral de finalidad como definitivos.
- **Idempotencia obligatoria** en el consumidor: el mismo evento se reprocesará. Clave de
  deduplicación = (hash de transacción, índice de log).
- El *backfill* histórico y el *tail* en vivo son dos caminos de código con fallos distintos:
  probar ambos, y probar el reinicio a mitad de *backfill*.

## 4. Custodia de claves: el eje del dominio

**El dato que ordena las prioridades**: Chainalysis, informe de crimen 2025 (datos de 2024):
*"Private key compromises accounted for the largest share (43.8%) of stolen crypto in 2024"*,
sobre unos *"$2.2 billion"* robados. En la actualización de mitad de 2025: *"With over $2.17
billion stolen from cryptocurrency services so far in 2025…"* y *"At $1.5 billion, this
single incident not only represents the largest crypto theft in history, but also accounts
for approximately 69% of all funds stolen from services this year"* (Bybit). Caveat de
metodología del propio informe: los datos *"include only known stolen fund events… They are
therefore not a comprehensive view"* — son **cota inferior**.

Lectura de ingeniería: **el fallo dominante no está en el contrato, está en la clave y en el
humano que firma.** Un presupuesto que gasta todo en auditoría de código y nada en custodia
está mal repartido.

### 4.1 Reglas duras

- **Ninguna clave con poder de mover fondos vive en un servidor de aplicación, en una variable
  de entorno, en un `.env`, en un gestor de secretos genérico ni en el CI.** Si el proceso que
  atiende peticiones HTTP puede firmar, un RCE es una pérdida total e irreversible.
- **Multifirma con umbral (m-de-n) por defecto** para tesorería y para cualquier rol
  privilegiado en cadena. Los firmantes: **personas distintas, dispositivos distintos,
  ubicaciones distintas, con al menos un firmante fuera del alcance de un compromiso del
  proveedor cloud**.
- **MPC/umbral** como alternativa cuando se necesita una única firma en cadena (privacidad,
  coste, cadenas sin multifirma nativa). No es "mejor" que la multifirma: mueve el riesgo del
  contrato al proveedor de la biblioteca y a su ceremonia de generación de claves.
- **HSM** cuando hay requisito institucional o de certificación. Un HSM protege la clave del
  robo, **no de la firma indebida**: si la aplicación puede pedirle que firme, el atacante que
  controla la aplicación también. El control es la **política de aprobación**, no el hardware.
- **Frío ≠ hardware wallet en un cajón.** Frío significa: clave generada offline, respaldo
  de la semilla en material resistente y en custodia física con control dual, procedimiento de
  recuperación **ensayado** y registro de quién tiene qué. Una semilla escrita en papel en la
  caja fuerte del CTO sin ensayo de restauración es una pérdida futura.
- **El respaldo se prueba.** Recuperar en un dispositivo nuevo, con la ceremonia real, al
  menos una vez al año. Un respaldo no restaurado no existe.

### 4.2 El proceso humano de firma

El eslabón que se rompe es la **firma a ciegas**. Un firmante que ve un blob hexadecimal y
pulsa "aprobar" no está aprobando nada: está delegando en el que preparó la transacción.

Procedimiento mínimo para cualquier transacción de valor material:

1. **Preparación** por una persona, **revisión independiente** por otra, con la *intención* de
   la operación escrita en lenguaje natural.
2. **Verificación fuera de banda** de la dirección de destino y del importe por un canal
   distinto del que trajo la petición. El fraude de suplantación de proveedor vive aquí.
3. **Simulación previa** de la transacción contra un fork del estado actual, comprobando qué
   saldos cambian realmente — no qué dice el frontend que cambian.
4. **Verificación en el dispositivo de firma**: lo que se aprueba es lo que muestra la
   pantalla del hardware, **no la del ordenador**, que puede estar comprometido.
5. **Aprobaciones independientes** de los firmantes del umbral, sin que uno prepare y firme
   dos veces con dos dispositivos suyos.
6. **Registro** de quién aprobó qué y por qué, retenido como evidencia.

Las aprobaciones ilimitadas a contratos (`approve` por el máximo) son deuda permanente:
**aprobar el importe exacto y revocar lo que ya no se usa**, con revisión periódica de
aprobaciones vivas.

### 4.3 Envenenamiento de direcciones y errores de destino

Las direcciones se parecen entre sí y **las transferencias son irreversibles**. Controles:
lista blanca de destinos con alta en dos pasos y periodo de espera, verificación de los
caracteres completos (no solo primeros y últimos cuatro), transacción de prueba de importe
mínimo antes de un envío grande, y detección de direcciones "parecidas" a las del historial —
el ataque consiste precisamente en sembrar el historial con transferencias de valor cero
desde una dirección casi idéntica.

## 5. Riesgos específicos

### 5.1 Superficie del stack

- **Endpoint RPC propio expuesto**: nunca abierto a Internet. Los métodos administrativos
  (`admin_*`, `personal_*`, `debug_*`) desactivados; `eth_*` solo tras un proxy con
  autenticación, límite de tasa y de coste por consulta. Un `eth_getLogs` sin rango acotado es
  un DoS gratis.
- **Frontend**: el mayor incidente recurrente no es el contrato, es el **secuestro del DNS o
  del bucket del frontend** para servir una interfaz que hace firmar otra cosa. Controles:
  registrar el dominio con bloqueo de transferencia y MFA, DNSSEC, despliegue inmutable y
  firmado, **SRI** en los scripts de terceros y monitorización de integridad del bundle
  servido.
- **Dependencias JavaScript de la cadena de firma**: una librería comprometida en `npm` que
  altere la dirección de destino antes de firmar es el ataque de cadena de suministro más
  rentable que existe. Fijar por *digest*, revisar cada actualización de la ruta de firma, y
  minimizar el número de paquetes que tocan la transacción.

### 5.2 Puentes: el peor historial documentado de pérdidas

Chainalysis, agosto de 2022: *"$2 billion in cryptocurrency has been stolen across 13 separate
cross-chain bridge hacks"*, y *"Attacks on bridges account for 69% of total funds stolen in
2022 so far"*. Un puente concentra custodia de activos de varias cadenas bajo un conjunto de
claves o un contrato de verificación, y no tiene la liquidez ni el escrutinio del L1 que
imita.

Criterio: **diseñar para no necesitar puente**. Si es inevitable — puente canónico del propio
rollup antes que uno de terceros, **límite duro de exposición** (importe máximo en tránsito y
en el contrato del puente), monitorización de eventos anómalos, y aceptación explícita del
riesgo por escrito de quien responde del dinero. Los activos "envueltos" son un **pagaré de
un tercero**, no el activo original: contabilizarlos como tal.

### 5.3 Oráculos

Todo precio en cadena es manipulable con capital suficiente si su fuente es superficial. El
patrón de ataque estándar es mover el precio de un pool poco líquido dentro de la misma
transacción que consume ese precio. Defensas: **agregación de múltiples fuentes
independientes**, uso de medias ponderadas en el tiempo cuando el caso lo permita,
**validación de rango y de antigüedad (*staleness*)** en el consumidor, y **circuit breaker**
que detenga la operación ante una desviación anómala en lugar de operar con un dato absurdo.
Un oráculo caído debe **parar el sistema**, no devolver el último valor conocido en silencio.
La implementación en el contrato es de `solidity-standards`; aquí la exigencia de que el
diseño la contemple.

### 5.4 MEV a nivel de aplicación

La mempool pública es un **tablón de anuncios de tus intenciones**. Cualquier operación cuyo
resultado dependa del precio en el momento de ejecución puede ser adelantada o sandwicheada.
Mitigaciones de diseño (no de contrato): **límites de deslizamiento estrictos y explícitos**
por defecto en el cliente, **plazos de validez cortos**, envío por **flujo de órdenes privado**
para operaciones grandes, y trocear la operación. Y una regla de producto: si tu UX pone un
deslizamiento por defecto alto "para que no falle", estás pagando la diferencia a un tercero.

### 5.5 Inmutabilidad frente a protección de datos

**Nada de datos personales en cadena. Ni cifrados, ni con hash.** Una cadena pública es
inmutable, replicada globalmente e imborrable: incumple por construcción el derecho de
supresión y de rectificación, y el cifrado de hoy es descifrable mañana. Un hash de un dato
personal de dominio pequeño (un DNI, un email) es **reversible por fuerza bruta** y por tanto
sigue siendo dato personal. Patrón correcto: el dato fuera, en un sistema con borrado real; en
cadena solo un compromiso con sal secreta, y el borrado de la sal como mecanismo de
*crypto-shredding*. **El criterio, la DPIA y el análisis de reidentificación son de
`privacy-engineering-standards`.**

## 6. Regulación, contabilidad y operación

### 6.1 MiCA (UE)

**Reglamento (UE) 2023/1114** — *"REGULATION (EU) 2023/1114 … of 31 May 2023 on markets in
crypto-assets, and amending Regulations (EU) No 1093/2010 and (EU) No 1095/2010 and Directives
2013/36/EU and (EU) 2019/1937"*. Comisión Europea: *"29 June 2023 … The Markets in
Crypto-assets Regulation (MiCA) came into force."* Resumen oficial de EUR-Lex sobre su
aplicación: *"It will apply from 30 December 2024. However, rules on asset-referenced tokens
(Title III) and e-money tokens (Title IV) have applied since 30 June 2024."*

Régimen transitorio: ESMA describe la cláusula de *grandfathering* del artículo 143 por la que
entidades que prestaban servicios de criptoactivos conforme a derecho nacional antes del
30 de diciembre de 2024 podían continuar **hasta el 1 de julio de 2026 o hasta que se les
conceda o deniegue la autorización MiCA**, con periodos que varían por Estado miembro.
**Verificar el estado actual y el plazo del Estado miembro concreto antes de asumir nada
(§8).**

Consecuencia de diseño, no de cumplimiento a posteriori: **determinar antes de escribir código
si la actividad convierte a la entidad en emisor o en proveedor de servicios de criptoactivos
(CASP)**. Custodiar claves de clientes, cambiar por dinero fiduciario, ejecutar órdenes,
operar una plataforma de negociación o transferir por cuenta de terceros son actividades
reguladas. La diferencia entre "custodio las claves de mis usuarios" y "el usuario custodia
las suyas" no es una decisión de UX: **es la que decide si necesitas una autorización**.

### 6.2 Travel rule

**Reglamento (UE) 2023/1113** — *"REGULATION (EU) 2023/1113 … of 31 May 2023 on information
accompanying transfers of funds and certain crypto-assets and amending Directive (EU)
2015/849 (recast)"*. Impone acompañar las transferencias de criptoactivos con información de
ordenante y beneficiario. Requisito **de arquitectura**: si tu sistema mueve criptoactivos por
cuenta de clientes, necesita transportar, validar y conservar esos datos, y decidir qué hace
cuando la contraparte no los envía o el destino es una dirección autocustodiada. Eso no se
añade al final. **Verificar la fecha de aplicación y las guías de la EBA (§8): no la fija este
documento.**

### 6.3 AML/KYC y rampas

Las rampas fiat↔cripto son el punto donde entra la regulación con más fuerza: identificación
del cliente, cribado de sanciones, monitorización de transacciones y comunicación de
operaciones sospechosas. Diseño: **la rampa se delega en un proveedor autorizado** salvo que
la entidad quiera ser ella la regulada, con la diligencia debida sobre ese proveedor
documentada. Cribado de direcciones contra listas de sanciones **antes** de enviar, no
después.

Postura de esta skill: **defensiva y de cumplimiento**. No se documentan técnicas de
ofuscación de flujos, elusión de controles ni evasión regulatoria.

### 6.4 Contabilidad y fiscalidad como restricción de diseño

- **Cada transacción es un hecho contable y con frecuencia un hecho imponible.** El sistema
  debe registrar, por operación: fecha y hora, contraparte, importe en cripto **y su
  contravalor en moneda funcional en ese momento**, comisiones (incluida la comisión de red,
  que a menudo es un gasto deducible), y la referencia en cadena.
- **El tipo de cambio necesita una fuente definida y estable** (qué mercado, qué momento, qué
  redondeo) y auditable a posteriori. Cambiar de criterio a mitad de ejercicio es un problema.
- **La conciliación entre el libro contable y el estado en cadena debe ser automática y
  diaria**, y su descuadre es una alerta operativa. Descubrirlo en la auditoría anual es
  demasiado tarde.
- Añadir esto al final es una reescritura: **si el registro contable no se diseñó con el
  sistema, no se puede reconstruir** — la cadena tiene los importes, pero no el contravalor
  del momento ni la intención de la operación.

### 6.5 Operación

- **Observabilidad propia del dominio**: saldo de las cuentas operativas y alerta por umbral
  bajo (una cuenta de gas vacía detiene el servicio), retraso respecto a la cabeza de cadena,
  transacciones pendientes por antigüedad, coste de comisiones por día, y desviación entre el
  estado indexado y el de la cadena.
- **Gestión de comisiones**: precio de gas volátil, transacciones atascadas y necesidad de
  reemplazo con comisión superior. Un servicio que envía transacciones necesita política de
  reintento, límite de gasto y detección de transacción atascada — no un `send()` y esperanza.
- **Nonces**: dos procesos firmando con la misma cuenta se pisan los nonces y se anulan entre
  sí. Un único emisor serializado por cuenta, o cuentas separadas por proceso.
- **Runbook de incidente en cadena** escrito **antes** del incidente: quién puede pausar,
  quién convoca a los firmantes, cómo se comunica, y qué se hace en las primeras dos horas.
  El plan de respuesta es de `incident-response-forensics-standards`; el mecanismo en cadena,
  de `solidity-standards`.

## 7. Sostenibilidad a largo plazo

- Actualizar clientes de nodo con la cadencia del protocolo, no con la del equipo: los *hard
  forks* tienen fecha y no la negocias.
- Revisar anualmente: firmantes activos del multisig (una salida de la empresa sin revocar
  firma es un agujero abierto), aprobaciones de contratos vivas, exposición en puentes, y
  vigencia de la calificación de la L2 usada.
- Plan de salida documentado por dependencia: proveedor RPC, custodio, puente, L2 y consorcio.
  "¿Qué hacemos si mañana desaparece?" debe tener respuesta escrita.

**Prohibiciones explícitas:**

- ❌ **PROHIBIDO** adoptar una blockchain sin haber respondido por escrito, y de forma
  negativa, a las cinco condiciones de §1.1.
- ❌ **PROHIBIDO** presentar una cadena permisionada como "descentralizada" cuando existe un
  consorcio que decide quién escribe, quién valida y quién actualiza.
- ❌ **PROHIBIDO** que una clave capaz de mover fondos exista en un servidor de aplicación,
  en el CI, en un `.env` o en un repositorio. Sin excepciones "temporales".
- ❌ **PROHIBIDO** firmar a ciegas: transacción de valor material sin simulación previa,
  revisión independiente y verificación en la pantalla del dispositivo de firma.
- ❌ **PROHIBIDO** depender de un único proveedor RPC para lectura crítica, y tratar su
  respuesta como verdad verificada.
- ❌ **PROHIBIDO** modelar tesorería asumiendo retiradas instantáneas desde un rollup
  optimista: el periodo de disputa es de días, no de minutos.
- ❌ **PROHIBIDO** escribir datos personales en cadena, ni cifrados ni con hash.
- ❌ **PROHIBIDO** consumir el precio de un único pool como oráculo, o seguir operando con un
  precio obsoleto sin *circuit breaker*.
- ❌ **PROHIBIDO** conceder aprobaciones ilimitadas por comodidad, o dejar aprobaciones vivas
  sin revisión periódica.
- ❌ **PROHIBIDO** citar cifras de TPS de fabricante como capacidad operativa (§8).
- ❌ **PROHIBIDO** diseñar el sistema y consultar después si la actividad cae bajo MiCA o
  requiere autorización.
- ❌ **PROHIBIDO** documentar o implementar técnicas de ofuscación de flujos, elusión de
  sanciones, de KYC o de obligaciones de información. Postura defensiva y de cumplimiento.
- ❌ **PROHIBIDO** duplicar aquí criterio de código de contrato: eso es de `solidity-standards`.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real:

1. **MiCA**: estado del régimen transitorio del art. 143 **en el Estado miembro concreto** —
   ESMA describía la continuidad *"until 1 July 2026 or until they are granted or refused a
   MiCA authorisation"*, plazo que a ago-2026 ya ha vencido o está venciendo. Consultar ESMA,
   la lista de CASP autorizados y el supervisor nacional (CNMV/Banco de España en España).
   **Fuente de las fechas de aplicación**: resumen oficial de EUR-Lex, verbatim; el texto
   íntegro del art. 149 **no se pudo obtener en crudo** (EUR-Lex truncaba el documento) — su
   redacción exacta llegó por **WebSearch** y debe confirmarse contra el diario oficial.
2. **Reglamento (UE) 2023/1113 (travel rule)**: su fecha de aplicación y las directrices de la
   EBA sobre umbrales y transferencias a direcciones autocustodiadas **no se verificaron
   verbatim** en esta pasada (EUR-Lex truncó el texto antes del artículo final). **Hueco
   declarado**: confirmar antes de usarlas.
3. **Cifras de robos**: reverificar el informe de Chainalysis vigente. Lo verificado aquí:
   43,8 % por compromiso de clave privada en 2024 sobre 2.200 M$ (informe 2025), 2.170 M$
   robados a servicios en la primera mitad de 2025 y Bybit 1.500 M$ ≈ 69 % de ese total. Todas
   son **cotas inferiores** por metodología declarada del propio informe. La afirmación de que
   el compromiso de clave explica *cuatro de los diez mayores robos* proviene de verificación
   previa del catálogo y **no se re-verificó aquí**.
4. **TPS: folclore desmentido.** El famoso número de Solana sale de su propio *white paper*
   (v0.8.13, Yakovenko), literalmente: *"The protocol is analyzed on a 1 gbps network, and
   this paper shows that throughput up to 710k transactions per second is possible with todays
   hardware."* Es un **análisis teórico del fabricante sobre una red de 1 Gbps**, no una
   medida en producción. Toda cifra de TPS publicada por un proyecto sobre su propia cadena
   está medida en laboratorio, con transacciones triviales y sin contención de estado: **no
   sirve para dimensionar**. Si necesitas una cifra, mídela tú con tu carga, o no la uses.
5. **L2**: el *stage* actual de la cadena en L2Beat, quién controla el secuenciador, si las
   pruebas están activas, el *timelock* de actualización del puente y la duración exacta del
   periodo de disputa. Cambian, y la última verificación no vale para el trimestre siguiente.
6. **Hyperledger Fabric / Corda**: versión estable actual y política LTS —a ago-2026 la rama
   LTS documentada en el `README` de Fabric era **v2.5.x**, mientras la documentación
   mencionaba notas de release de **v3.1.5**: **discrepancia sin resolver**, confirmar cuál es
   la recomendada. Verificar también la gobernanza actual (Hyperledger se integró en LF
   Decentralized Trust: **no se pudo confirmar la fecha del cambio en fuente primaria**) y la
   salud real del proyecto: número de mantenedores, cadencia de releases y despliegues vivos.
   Ambos proyectos **Apache-2.0** según sus `LICENSE` en crudo.
7. **CVEs y avisos**: del cliente de nodo que operes y de las librerías de firma. Un fallo en
   la generación de nonces o en la derivación de claves es una pérdida total.
8. **Fiscalidad y contabilidad**: el tratamiento aplicable en la jurisdicción concreta y el
   ejercicio en curso. Este documento **no fija ningún criterio fiscal**: exige que exista y
   que el sistema lo soporte.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
