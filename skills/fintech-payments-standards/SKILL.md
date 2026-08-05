---
name: fintech-payments-standards
description: Use when software takes money — PCI DSS v4.0.1 scope and SAQ A / SAQ A-EP / SAQ D selection, hosted fields, iframes and the PAN never touching your servers, cardholder data environment and segmentation, sensitive authentication data and the ban on storing CVV/CVC/CAV2/CID after authorization, PSP tokenization and EMVCo network tokens, PSD2 strong customer authentication and the Regulation (EU) 2018/389 exemptions (TRA, low value, trusted beneficiary, MIT and recurring), EMV 3-D Secure 2.x, liability shift, authorize/capture/partial capture/void/refund state machines, Idempotency-Key and double-charge prevention, settlement and reconciliation against acquirer payout files, chargebacks and representment, SEPA credit transfer, SEPA Direct Debit mandates and Regulation (EU) 2024/886 instant payments, open banking pay-by-bank, MiCA duties for crypto payments, AML/KYC and fraud screening hooks, ISO 4217 minor units, integer minor-unit amounts instead of floats, and immutable double-entry ledgers.
---

# Estándares de pagos y fintech

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando el software **mueve dinero de un tercero**: cobros con tarjeta, transferencias,
domiciliaciones, monederos, suscripciones y reembolsos. Cubre la decisión que domina todo el
proyecto —**el alcance PCI DSS**—, el ciclo de vida de una transacción, la autenticación
reforzada, la conciliación con el dinero que realmente llega, las disputas y la contabilidad
del importe.

Triggers: PCI DSS, CDE, PAN, SAD, CVV/CVC2/CAV2/CID, SAQ A, SAQ A-EP, SAQ D, ROC, AOC, QSA,
ASV, tokenización, *network token*, PSP, adquirente, emisor, esquema de tarjeta, PSD2, SCA,
RTS (UE) 2018/389, TRA, MIT, CIT, 3-D Secure, EMV 3DS, *liability shift*, `authorize`,
`capture`, `void`, `refund`, `Idempotency-Key`, *settlement*, *payout*, `chargeback`,
*representment*, *pre-arbitration*, SEPA, SCT, SCT Inst, SDD Core, SDD B2B, mandato, `IBAN`,
`pain.001`, `camt.053`, ISO 20022, *open banking*, PIS/AIS, MiCA, KYC, AML, ISO 4217,
*minor units*, libro mayor, asiento, `Stripe`, `Adyen`, `Redsys`, `Mollie`, `Braintree`.

**Tesis de la skill**: **el alcance PCI es una decisión de arquitectura, no de cumplimiento.**
Se decide el primer día, con una sola pregunta: *¿el PAN pasa alguna vez por un sistema mío?*
Si la respuesta es sí —aunque sea un `POST` que solo reenvía, aunque sea un JavaScript propio
que lee el `<input>`— el proyecto cambia de categoría: de una decena de controles a ciento
cincuenta o más, con auditoría externa, escaneos trimestrales y segmentación de red. **Tocar
el PAN una vez cuesta más que todo el resto del producto.**

Segunda tesis, igual de cara de aprender tarde: **autorización no es cobro, y lo cobrado no es
lo que ingresas.** Entre "aprobado" en la pasarela y el euro en tu banco hay captura,
liquidación, comisiones, retenciones, conversión de divisa y disputas. Un sistema que asume
`status == "approved"` ⇒ *dinero* tiene un descuadre garantizado (§3.6).

**No aplica**: ver `e-commerce-standards` (**skill hermana de este lote**: catálogo, carrito,
inventario, checkout como embudo, impuestos de venta y OSS/IOSS, envíos y devoluciones,
promociones. Frontera exacta: **el carrito y el precio son suyos; desde `POST /payments` hasta
el asiento contable, míos**. La regla que evita la duplicación: *quién decide cuánto se cobra →
`e-commerce`; qué pasa con ese importe una vez enviado al PSP → esta skill*),
`appsec-standards` (modelado de amenazas, OWASP/ASVS, triaje de vulnerabilidades de la
aplicación; aquí solo las clases propias del dominio de pago), `api-design-standards`
(**contrato HTTP y semántica de `Idempotency-Key`, `409`, `Retry-After` y firma de webhooks
son suyos**; aquí **por qué en pagos la idempotencia no es opcional** y qué se usa como clave),
`cryptography-pki-standards` (TLS, HSM/KMS, gestión de claves, cifrado en reposo; aquí solo qué
dato hay que proteger y por qué), `identity-access-management-standards` (OAuth 2.1/OIDC,
FAPI, mTLS y *client credentials* contra la API del banco; **la SCA de PSD2 es una obligación
regulatoria de pago y vive aquí**, el motor de autenticación y los factores viven allí),
`privacy-engineering-standards` (base legal, minimización, retención y derechos del
interesado sobre los datos de pago; **atención al conflicto real**: la retención contable
obligatoria gana al derecho de supresión, y esa colisión se resuelve allí),
`grc-compliance-standards` (**el programa de cumplimiento entero es suyo**: ISO 27001, SOC 2,
DORA, AML/KYC como obligación corporativa, aceptación de riesgo, relación con el auditor.
Aquí solo el control técnico y quién lo tiene que implementar), `solidity-standards` (contratos
EVM; aquí solo qué implica regulatoriamente aceptar cripto), `ai-governance-standards`
(un modelo antifraude que deniega pagos puede ser sistema de alto riesgo del Reglamento de IA
y exige supervisión humana: la clasificación es suya), `detection-engineering-standards` y
`soc-operations-standards` (detección y respuesta sobre la telemetría de fraude),
`incident-management-standards` (gestión del incidente cuando el descuadre o la brecha ya
ocurrió), `data-warehouse-modeling-standards` (**el modelado analítico del hecho `pago` es
suyo**; el libro mayor transaccional e inmutable es de aquí), `sql-standards` (**tipos
exactos**: `NUMERIC`/`DECIMAL` frente a `float`, restricciones y transacciones),
`observability-standards` y `sre-practice-standards` (plataforma de métricas, SLO y presupuesto
de error; aquí qué SLI de pago exportar), `message-brokers-standards` (entrega *at-least-once*
y por qué obliga a consumidores idempotentes), `microservices-architecture-standards`
(*outbox*, sagas y propiedad del dato entre servicios), `i18n-standards` (formateo del importe
y de la divisa para el usuario; **aquí el importe se almacena y transmite en unidades mínimas,
nunca formateado**), `accessibility-standards` (el formulario de pago accesible),
`opensource-licensing-standards` (licencia de los SDK de PSP y del software de *ledger*).

## 2. Decisiones por defecto

> Verificar por web la versión vigente de cada norma, las fechas y las comisiones antes de
> fijarlas en un proyecto real (§8). Datos de **agosto de 2026**.

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| ¿Tocar el PAN? | **Nunca.** Campos alojados o `iframe` del PSP; el navegador habla directo con el PSP | Es la única decisión que reduce el coste de cumplimiento en un orden de magnitud (§3.1) |
| Cuestionario objetivo | **SAQ A** | Se fija como requisito de producto **antes** de elegir tecnología, no después (§3.2) |
| Almacenar tarjeta | **Token del PSP**, nunca el PAN | Y para tarjeta guardada, evaluar *network token* con el PSP (§3.3) |
| CVV/CVC tras autorizar | **PROHIBIDO almacenarlo**, en cualquier forma, cifrado incluido | Requisito PCI DSS 3.3.1.2, citado verbatim en §3.3 |
| Importes | **Entero en unidades mínimas** (`amount_minor`) + **código ISO 4217** | Coma flotante en dinero es un bug, no una decisión (§3.7) |
| Idempotencia | **Clave de idempotencia obligatoria** en toda operación que mueva dinero | Sin ella, un *timeout* de red es un doble cobro (§3.5) |
| Autorización y captura | **Separadas** cuando hay envío físico o verificación posterior | Capturar antes de poder servir es cobrar por algo que quizá no entregues (§3.4) |
| SCA | **Delegar el 3DS al PSP** y decidir las exenciones con datos, no por defecto | Quién pide la exención y quién asume el fraude no siempre coinciden (§3.9) |
| Reintentos | **Backoff exponencial con *jitter* + clave de idempotencia + tope duro** | Un reintento sin clave es una transacción nueva |
| Conciliación | **Diaria y automática** contra el fichero de liquidación del PSP/adquirente | El descuadre se detecta el día 1, no en el cierre trimestral (§3.6) |
| Contabilidad | **Partida doble, asientos inmutables, corrección por contra-asiento** | `UPDATE` sobre un asiento destruye la auditoría (§3.7) |
| Webhooks del PSP | **Verificar firma + tratar como pista, no como verdad**; releer el estado por API | Un webhook se puede perder, duplicar y desordenar (§3.8) |
| Cripto como medio de pago | **No**, salvo decisión de negocio explícita con licencia MiCA verificada | §3.11 |
| Datos de tarjeta en logs | **PROHIBIDO**, con filtro en la capa de logging, no en la disciplina del programador | §5 |

## 3. Criterio técnico

### 3.1 El alcance lo decide dónde vive el PAN

PCI DSS se aplica al **CDE** (*cardholder data environment*): todo sistema que almacena,
procesa o transmite datos de titular, **más todo sistema conectado a ellos o que pueda afectar
a su seguridad**. Esa segunda mitad es la que sorprende: un servidor de logs, un bastión, un
agente de despliegue o un servicio de configuración que llega al CDE **entra en el alcance**.

Consecuencia práctica: la arquitectura de pago se elige por su alcance resultante.

| Integración | El PAN pasa por | Alcance típico |
|---|---|---|
| Redirección completa al PSP | Solo por el PSP | El más pequeño; sin criterio de *script* aplicable (§3.2) |
| `iframe` / campos alojados del PSP | Solo por el PSP; el DOM padre es tuyo | Pequeño, **pero la página contenedora no queda automáticamente fuera** |
| Formulario propio + `POST` directo al PSP desde el navegador (*direct post*, JS propio) | Tu JavaScript lo toca | Grande: es SAQ A-EP |
| API servidor-a-servidor con el PAN | Tus servidores | Máximo: SAQ D / ROC, segmentación, escaneos, pentest |

**Regla dura**: si algún elemento de la página de pago se origina en tu servidor, no estás en
el escenario mínimo. Y **la página contenedora del `iframe` sigue importando**: un botón "Pagar"
alojado por ti, un *script* de analítica comprometido o una cabecera manipulada pueden
redirigir al usuario antes de que llegue al `iframe`. El `iframe` protege el campo, no el
recorrido.

### 3.2 SAQ A frente a SAQ A-EP frente a SAQ D

Estado verificado a agosto de 2026: la versión vigente es **PCI DSS v4.0.1** (revisión limitada
publicada en junio de 2024; v4.0 retirada el 31-12-2024). Los **51 requisitos "*future-dated*"**
que hasta entonces eran buena práctica **pasaron a ser obligatorios el 31 de marzo de 2025** —
ya no hay periodo de gracia y el evaluador los prueba como cualquier otro. **Verificar ambos
datos y el número exacto de requisitos en §8**: el conteo circula mal citado.

Dos de esos requisitos son los que definen hoy el e-commerce:

- **6.4.3** — inventario, autorización y control de integridad de **todo *script* cargado en la
  página de pago**.
- **11.6.1** — mecanismo de **detección de manipulación** que alerte ante cambios no
  autorizados en las cabeceras HTTP y en el contenido de la página de pago.

Ambos existen para frenar el *skimming* de cliente (familia Magecart): el servidor está
limpio, el PAN se exfiltra desde el navegador.

Cambio de 2025 que se cita mal con frecuencia: en **SAQ A** se **retiraron los ítems 6.4.3,
11.6.1 y 12.3.1** y se añadió un **criterio de elegibilidad** — el comercio debe confirmar que
su sitio *no es susceptible a ataques de scripts que puedan afectar a sus sistemas de comercio
electrónico*. **No es una exención**: los requisitos siguen vigentes en el estándar, en SAQ A-EP,
en SAQ D y en el ROC. Es un traslado de forma, no de fondo, y se satisface implementando la
protección o **obteniendo confirmación escrita del PSP** de que su solución la incluye. Con
redirección completa el criterio no aplica; con `iframe`, sí. (FAQ 1588 del PCI SSC, 28-02-2025.)

**Verificar en §8**: la elegibilidad, el conteo de ítems de cada SAQ y la interpretación
"sitio entero frente a página de pago" — este último punto no está cerrado y **lo decide tu QSA
y tu adquirente, no un documento genérico**.

### 3.3 Datos de titular y datos sensibles de autenticación

Dos categorías con reglas opuestas:

- **Datos de titular** (PAN, nombre, caducidad, código de servicio): se pueden almacenar si hay
  necesidad de negocio, con el PAN ilegible allá donde se guarde.
- **SAD** (contenido de pista, código de verificación, PIN/bloque de PIN): **no se almacenan
  después de la autorización**, punto. Solo emisores y quien da soporte a emisión tienen
  excepción.

Texto de los requisitos de PCI DSS v4.0.1 (reproducción de tercero, §8 declara el hueco de la
fuente primaria):

> **3.3.1.1** The full contents of any track are not stored upon completion of the
> authorization process.
> **3.3.1.2** The card verification code is not stored upon completion of the authorization
> process.
> **3.3.1.3** The personal identification number (PIN) and the PIN block are not stored upon
> completion of the authorization process.

Y del propio PCI SSC (FAQ 1280), sobre el caso que siempre se intenta:

> "These values are not needed for card-on-file or recurring transactions, and storage for
> these purposes is prohibited […] However, it is not permitted to retain card verification
> codes/values once the specific purchase or transaction for which it was collected has been
> authorized."

Lo que esto implica y suele ignorarse:

- **Cifrar el CVV no lo permite.** El requisito prohíbe *almacenar*, no *almacenar en claro*.
  Cripto-borrado tampoco: sigue almacenado.
- **Un log, una traza, un `crash dump`, un backup o una fila de auditoría cuentan como
  almacenamiento.** La guía del estándar enumera explícitamente logs de transacción,
  depuración y error, ficheros de histórico y de traza, esquemas y contenidos de base de
  datos —local y en nube— y volcados de memoria.
- Retenerlo brevemente en **memoria no persistente** tras la autorización se contempla solo
  con necesidad de negocio legítima, garantías de no persistencia y borrado inmediato. No es
  una puerta trasera para "guardarlo un ratito".
- Recogerlo **antes** de autorizar no está prohibido. Retenerlo después, sí.

**Tokenización**: el token del PSP sustituye al PAN en tus sistemas y es el mecanismo estándar
para tarjeta guardada y suscripciones. **Un token de PSP es específico de ese PSP**: cambiar de
proveedor exige una migración de tokens negociada — pregúntalo *antes* de firmar, es una de las
formas más duras de dependencia de proveedor del catálogo.

**Network tokens** (tokenización de esquema, especificación EMVCo): el token lo emite la red
—no el PSP— y se actualiza solo cuando la tarjeta se renueva o se reemplaza. Beneficio real y
medible: menos declinaciones por tarjeta caducada en suscripciones. Coste: depende del PSP y
del esquema, y **no todos los flujos lo soportan** — verificar cobertura por país y esquema.

### 3.4 La máquina de estados de una transacción con tarjeta

`autorizar → (capturar | anular) → [liquidar] → (reembolsar | disputar)`

- **Autorización**: el emisor reserva el importe y devuelve un código. **No hay movimiento de
  dinero.** Tiene caducidad (días, y depende del esquema y del tipo de comercio): si no
  capturas a tiempo, la autorización expira y hay que volver a pedirla.
- **Captura**: la instrucción de cobrar. Puede ser **total, parcial o múltiple** según el PSP y
  el esquema. Captura parcial es la respuesta correcta cuando envías medio pedido: **no
  captures el total y reembolses la diferencia** — genera una comisión y un movimiento
  innecesario en el extracto del cliente.
- **Anulación (`void`)**: cancela una autorización **no capturada**. Es limpia y suele no dejar
  rastro para el cliente. Deja de ser posible en cuanto capturas.
- **Reembolso**: movimiento **nuevo** en sentido contrario, sobre una captura ya hecha. Tarda
  días en verse, **normalmente no devuelve las comisiones de adquirencia**, y puede fallar por
  sí mismo.
- **Reversal / *auth reversal***: liberar una autorización que no vas a capturar es una cortesía
  con impacto real —libera el crédito del cliente— y evita reclamaciones de soporte. Hazlo
  explícitamente; no confíes en la expiración.

**Consecuencia de diseño**: el estado de un pedido y el estado de un pago son **dos máquinas de
estados distintas** que se sincronizan. Fundirlas en una columna `status` es la causa raíz de la
mayoría de los descuadres.

### 3.5 Idempotencia: requisito, no optimización

Toda operación que mueve dinero se ejecuta sobre una red que **falla en el peor momento**: el
`timeout` que no sabes si llegó. Si el cliente reintenta y el servidor no distingue "es la
misma" de "es otra", cobras dos veces.

Reglas:

1. **La clave la genera el cliente**, no el servidor, y viaja en la petición
   (`Idempotency-Key`). Debe ser un identificador único de *intención de negocio*: por ejemplo,
   un UUID generado al crear el intento de pago — **nunca** un hash del cuerpo ni el ID de
   pedido a secas (dos pagos legítimos del mismo pedido existen: reintento tras fallo, pago
   parcial).
2. **Se persiste antes de llamar al PSP**, en la misma transacción de base de datos que crea el
   registro de intento. Persistirla después es una carrera contra el reintento.
3. **La respuesta se almacena y se reenvía tal cual** ante una repetición, con el mismo código
   de estado. Reintentar una clave ya usada **con un cuerpo distinto** es un error del cliente:
   respóndelo como conflicto, no lo ejecutes.
4. **Ventana de retención explícita** (típicamente 24 h en los PSP; verifica la de tu
   proveedor) y purga posterior.
5. **Los consumidores de eventos también son idempotentes.** Los brokers entregan
   *at-least-once*: procesar dos veces el evento "pago capturado" es duplicar un asiento.
6. **Idempotencia extremo a extremo**: tu API es idempotente hacia tu cliente *y* propagas
   clave hacia el PSP. Solo una de las dos capas no basta.

Aviso de fuente: **`Idempotency-Key` no es un estándar IETF**. El borrador
`draft-ietf-httpapi-idempotency-key-header` está **expirado** (versión 07, última revisión
2025-10-15, marcada como expirada en abril de 2026). Es convención de industria bien asentada
—Stripe, Adyen, PayPal y otros la implementan— pero no hay RFC: **verifica la semántica exacta
en la documentación de tu PSP**, no la asumas.

### 3.6 Liquidación y conciliación: el dinero que llega nunca es el que cobraste

Entre la captura y el ingreso hay: **comisión del PSP y del adquirente**, *interchange* y tasa
de esquema, **retenciones** (*reserve*, *rolling reserve*) del adquirente, **conversión de
divisa** con su margen, reembolsos y disputas del periodo, e impuestos sobre las comisiones.
Además, **una liquidación agrupa N transacciones** de varios días y no cuadra 1:1 con nada.

En la UE, los **topes de tasa de intercambio** están fijados por el Reglamento (UE) 2015/751
para operaciones con tarjeta de consumidor (verbatim, Art. 3(1)): *"Payment service providers
shall not offer or request a per transaction interchange fee of more than 0,2 % of the value of
the transaction for any debit card transaction"* — y **0,3 %** para crédito (Art. 4). Aplican
desde el 9-12-2015. **No cubren tarjetas comerciales ni las de esquemas de tres partes**, ni
son tu comisión total: el *interchange* es un componente, no el precio.

Diseño mínimo de conciliación:

- Ingesta **automática y diaria** del fichero de liquidación / *payout report* del PSP.
- **Casación por identificador de transacción**, no por importe: los importes coinciden por
  casualidad y la casación por importe produce falsos positivos.
- **Todo movimiento del extracto tiene su contrapartida** en el libro mayor: bruto, comisión,
  retención, diferencia de cambio. Si registras solo el neto, has perdido la comisión como
  gasto y el bruto como ingreso.
- **Alerta sobre partidas huérfanas** en ambos sentidos: cobros sin liquidar pasado el plazo
  esperado, y líneas de liquidación sin transacción local. Una partida huérfana **envejece**;
  el SLI útil es la antigüedad de la más vieja, no el conteo.
- **La conciliación no se "arregla" editando el pasado**: se corrige con un asiento nuevo.

### 3.7 Dinero en el código

- **Importe = entero en unidades mínimas + código ISO 4217.** `amount_minor: 1999, currency:
  "EUR"`. Nunca `float`/`double`; nunca `19.99` como número. En base de datos, entero o
  `NUMERIC` con escala explícita — jamás un tipo binario de coma flotante.
- **No todas las divisas tienen dos decimales.** JPY y KRW tienen cero; algunas (p. ej. las de
  la familia del dinar) tienen tres. Un `* 100` incrustado en el código es un error a la espera
  de una expansión internacional. **El número de decimales se consulta en la tabla ISO 4217, no
  se asume** (§8: iso.org bloquea la descarga automática; usa la lista mantenida por tu
  biblioteca de i18n y verifica).
- **El redondeo se decide una vez y se documenta** (impuestos, prorrateos, división de un
  descuento entre líneas). Prorratear sin repartir el resto produce descuadres de un céntimo
  que nadie encuentra.
- **Nunca conviertas divisa por tu cuenta para contabilizar.** Registra el importe original, el
  liquidado y el tipo aplicado por quien lo aplicó.
- **Libro mayor de partida doble, solo-append.** Cada movimiento es un asiento con débito y
  crédito que suman cero; nada se actualiza ni se borra; una corrección es un contra-asiento.
  El saldo es una proyección derivada, no una columna editable. Esto es lo que hace posible
  reconstruir "por qué el saldo es este" seis meses después — y lo que hace auditable el
  sistema (evidencia para `grc-compliance-standards`).
- **Reloj y zona**: todo instante en UTC con desplazamiento explícito. El corte contable de un
  día es una decisión de negocio, no la que decida el servidor.

### 3.8 Webhooks y estado

El webhook del PSP **se puede perder, duplicar, llegar tarde y llegar desordenado**. Reglas:

- **Verifica la firma** con el secreto compartido, con comparación en tiempo constante, y
  **rechaza marcas de tiempo antiguas** (defensa contra repetición).
- **Responde `2xx` rápido y procesa en segundo plano.** Un webhook que tarda se reintenta y se
  duplica.
- **Trátalo como una notificación de "algo cambió", no como el dato.** Ante un evento, **relee
  el estado por API**. Es la diferencia entre un sistema que aguanta el desorden y uno que se
  cree el último mensaje que llegó.
- **Ten un plan B por sondeo**: un trabajo periódico que reconcilie los pagos en estado no
  terminal. Los webhooks fallan y nadie se entera hasta el cierre.
- **Idempotencia por identificador de evento**, no por contenido.

### 3.9 SCA, exenciones y 3-D Secure

La **autenticación reforzada de cliente** (PSD2) exige dos factores independientes de
categorías distintas —conocimiento, posesión, inherencia— con vínculo dinámico al importe y al
beneficiario. Las exenciones están tasadas en el **Reglamento Delegado (UE) 2018/389**
(verbatim de EUR-Lex, CELEX 32018R0389):

| Exención | Art. | Umbral literal |
|---|---|---|
| Pago a distancia de bajo importe | 16 | ≤ **EUR 30**; y acumulado desde la última SCA ≤ **EUR 100** *o* ≤ **cinco** operaciones consecutivas |
| Contactless en punto de venta | 11 | ≤ **EUR 50**; y acumulado ≤ **EUR 150** *o* ≤ **cinco** consecutivas |
| Terminal desatendido de transporte/aparcamiento | 12 | Sin umbral |
| Beneficiario de confianza | 13 | La **creación o modificación de la lista sí exige SCA** |
| Operaciones recurrentes | 14 | **Mismo importe y mismo beneficiario**; la primera exige SCA |
| Transferencia entre cuentas propias en el mismo proveedor | 15 | — |
| Procesos corporativos dedicados | 17 | Solo pagadores no consumidores, con visto bueno de la autoridad |
| Análisis de riesgo de la transacción (TRA) | 18 | Ver tabla siguiente |

**TRA** (Art. 18): solo si la tasa de fraude del proveedor está por debajo de la referencia del
Anexo *y* el importe no supera el umbral de exención (ETV) *y* el análisis en tiempo real no
detecta ninguno de los seis indicadores del Art. 18(2)(c). Tabla del Anexo, verbatim:

| ETV | Pagos a distancia con tarjeta | Transferencias a distancia |
|---|---|---|
| EUR 500 | 0,01 % | 0,005 % |
| EUR 250 | 0,06 % | 0,01 % |
| EUR 100 | 0,13 % | 0,015 % |

Y la parte que decide arquitectura: **la exención no la aplica el comercio, la aplica un
proveedor de servicios de pago** — y el Art. 20 obliga a **cesar** el uso de TRA en un tramo si
la tasa de fraude supera la referencia **dos trimestres consecutivos**, sin poder reutilizarla
hasta volver a estar por debajo un trimestre. Consecuencia: **pedir la exención es apostar tu
tasa de fraude**. El emisor puede además rechazar la exención y exigir *challenge*.

**EMV 3-D Secure 2.x** es el protocolo que transporta los datos de contexto al emisor para que
decida entre flujo sin fricción (*frictionless*) y desafío. Estado verificado (emvco.com,
agosto de 2026): la línea publicada es **v2.2.0–2.3.1.1**; existe un **borrador v2.4.0.0** cuyo
periodo de comentarios terminó el 1 de julio de 2026. **Verificar la versión que soporta
realmente tu PSP y tus emisores objetivo**, que va por detrás de la especificación.

**Traslado de responsabilidad** (*liability shift*): una operación autenticada con 3DS traslada
al emisor la responsabilidad por fraude en la mayoría de escenarios de comercio electrónico.
**Los detalles —qué códigos de resultado protegen, qué motivos de disputa quedan excluidos,
qué pasa con las operaciones con exención— los fijan las reglas de cada esquema (Visa,
Mastercard), no la normativa europea.** Esas reglas son contractuales y su versión vigente se
verifica con tu adquirente. **Hueco declarado en §8**: no afirmes porcentajes ni garantías de
traslado de responsabilidad sin el documento de reglas en la mano.

**PSD3 / PSR — estado real**: **no están aprobados**. Verificado en el Observatorio Legislativo
del Parlamento Europeo (agosto de 2026): PSD3 = procedimiento **2023/0209(COD)**, PSR =
**2023/0210(COD)**; ambos con último evento *"05/05/2026 — Approval in committee of the text
agreed at early 2nd reading interinstitutional negotiations"*, estado **"Awaiting Council's 1st
reading position"** y **fecha indicativa de pleno 14/12/2026**. No hay acto final ni publicación
en el DOUE. **No planifiques contra un calendario de aplicación que aún no existe**: lo que
aplica hoy sigue siendo PSD2 y su RTS.

### 3.10 Disputas, *chargebacks* y fraude

Un *chargeback* es una reversión iniciada por el emisor a petición del titular. Flujo general:
**disputa → aportación de pruebas (*representment*) → pre-arbitraje → arbitraje**, con plazos
por etapa y coste fijo por caso, se gane o se pierda. Además, **la tasa de disputas está
vigilada por los esquemas**: superar sus umbrales mete al comercio en programas de
monitorización con multas y, en el extremo, pérdida de la capacidad de cobrar.

Los **plazos y umbrales concretos son reglas de esquema y cambian**: no los escribas de
memoria, consíguelos de tu adquirente. Lo que sí es criterio estable:

- **Conserva la evidencia desde el primer día**: IP y huella de dispositivo, marca de tiempo,
  registro de consentimiento, prueba de entrega, comunicaciones y resultado de 3DS. Reunirla
  cuando llega la disputa es tarde.
- **Descriptor del extracto reconocible**: buena parte de las disputas por "no reconozco el
  cargo" es fraude amistoso causado por un descriptor críptico. Mejor relación coste/beneficio
  del área. Y **cancelar es más barato que disputar**: la fricción para reembolsar se convierte
  en *chargeback*, que cuesta más.
- **Antifraude**: reglas + puntuación, con **umbrales que son decisión de negocio** (cada punto
  de fraude bloqueado cuesta ventas legítimas). Mide **ambas** tasas: fraude y falsos positivos;
  un modelo sin medida de rechazo legítimo optimiza una sola cara.
- **AML/KYC**: identidad, cribado de sanciones y PEP, monitorización y reporte. **La obligación
  y su gobierno son de `grc-compliance-standards`**; aquí solo que los puntos de enganche van
  desde el diseño — añadirlos después es rehacer el flujo de alta.

### 3.11 Fuera de la tarjeta

- **SEPA SCT / SCT Inst**: transferencia en euros. El Reglamento (UE) 2024/886 fija (verbatim)
  que los PSP de la zona euro ofrecen **recepción** de transferencias inmediatas **desde el
  9-1-2025** y **envío desde el 9-10-2025**; fuera de la zona euro, **9-1-2027** y **9-7-2027**.
  Con el envío llega la obligación del **servicio de verificación del beneficiario** (*VoP*):
  contrastar nombre e IBAN antes de que el pagador autorice. Efecto de producto: **el nombre del
  beneficiario deja de ser decorativo** y un desajuste genera fricción real en el flujo.
- **SEPA SDD**: la domiciliación se basa en un **mandato** firmado por el deudor, con
  identificador único, referencia del acreedor y prueba de consentimiento conservada. Dos
  esquemas: **Core** (consumidores, con derecho de devolución sin motivo dentro de un plazo, y
  ampliado si no hubo mandato válido) y **B2B** (solo entre empresas, sin ese derecho, con
  verificación previa del mandato por el banco del deudor). **Los plazos exactos los publica el
  EPC y cambian entre versiones del rulebook**: verifícalos (§8). Diseño: guarda el mandato como
  entidad de primera clase con su histórico; un mandato caducado por inactividad es la causa
  clásica de la devolución masiva.
- **Open banking / pago por transferencia** (PIS bajo PSD2): el usuario autoriza en su banco;
  no hay tarjeta, no hay *chargeback*, comisión típicamente menor y **el riesgo se desplaza al
  fraude por manipulación del pagador**, que ninguna SCA detiene. Sin reversión disponible, la
  política de reembolsos es tuya, entera. Ojo también a la disponibilidad: **dependes de la
  API del banco del usuario**, con su ventana de mantenimiento y su tasa de error.
- **Criptoactivos**: en la UE aplica **MiCA, Reglamento (UE) 2023/1114** — aplicable desde el
  **30-12-2024** (títulos III y IV desde el 30-6-2024), con el régimen transitorio del **Art.
  143(3)** verbatim: los proveedores que ya prestaban servicios *"may continue to do so until 1
  July 2026 or until they are granted or refused an authorisation pursuant to Article 63,
  whichever is sooner"*, y con potestad de los Estados miembros para acortarlo. **Ese periodo ya
  ha vencido**: a agosto de 2026, prestar servicios de criptoactivos en la UE sin autorización
  está fuera de la ley. Corolario de ingeniería: **aceptar cripto no es "añadir un método de
  pago", es entrar en un régimen de autorización** — o delegar íntegramente en un proveedor
  autorizado y verificar su registro. Añade además volatilidad, irreversibilidad y trazabilidad
  AML. **Verificar el estado del registro del proveedor en §8.**

## 4. Calidad y pruebas

- **Todo se prueba contra el *sandbox* del PSP**, con sus tarjetas de test, códigos de
  declinación y escenarios 3DS. Un simulacro propio prueba tu simulacro.
- **Casos obligatorios** además del camino feliz: declinación por fondos y por sospecha de
  fraude, autorización expirada, `timeout` sin respuesta (el caso de la idempotencia), webhook
  duplicado, desordenado y con firma inválida, captura parcial, reembolso parcial, reembolso
  mayor que la captura, divisa de cero decimales, cambio de divisa, disputa recibida.
- **Propiedad del libro mayor**: para cualquier secuencia, débitos = créditos y saldo derivado =
  saldo recalculado desde cero.
- **Concurrencia real**: N peticiones simultáneas con la misma clave de idempotencia producen
  **un** cargo. En paralelo de verdad, no en secuencia.
- **Conciliación con fichero real anonimizado**, incluyendo partida huérfana y comisión negativa.
- **Prueba negativa de logs**: ejecuta un pago y **falla si el volcado contiene algo que parezca
  un PAN o un CVV**. Es lo único que hace que la prohibición de §5 no dependa de la memoria.
- **Gates de CI**, coste creciente: análisis estático que **prohíbe `float`/`double` en tipos
  monetarios** y detecta patrones de PAN/CVV → *secret scanning* → unitarias del *ledger* →
  contrato con el PSP (grabación/reproducción) → SCA → integración con *sandbox*.

## 5. Seguridad del stack

- **Nunca registres** PAN completo, CVV, pista, PIN ni la respuesta cruda del PSP. El filtro va
  **en la capa de logging** (redactor por lista de permitidos), no en cada `logger.info`. Los
  escapes más frecuentes son trazas de APM, reportes de error y volcados de excepción.
- **Skimming de cliente (Magecart)** es el vector dominante y **no toca tu servidor**: minimiza
  *scripts* de terceros en la página de pago, CSP restrictiva, SRI, inventario y autorización de
  *scripts* (6.4.3) y detección de manipulación (11.6.1). El *frontend* es superficie de pago.
- **Autorización de objeto**: `GET /payments/{id}` sin comprobar propiedad es el IDOR del
  dominio, con impacto de datos financieros. Y **quién puede reembolsar, hasta cuánto y con qué
  segunda aprobación** es control de negocio, no de interfaz — el fraude interno vive ahí, igual
  que en la separación entre quien fija precios y quien aprueba abonos masivos.
- **Secretos del PSP** en gestor con rotación, claves distintas por entorno; **prohibida** la
  clave de producción fuera de producción. TLS moderno extremo a extremo; **fijar el certificado
  del PSP solo si tienes proceso de rotación** — si no, es un incidente programado.
- **Card testing**: validar tarjetas robadas con microcargos contra tu formulario. Se detecta por
  **tasa de declinación anómala**, no por volumen. Sin limitación de tasa por tarjeta, cuenta e
  IP, tu endpoint es el validador de otro y las autorizaciones las pagas tú.
- **Enumeración**: identificadores de pago no adivinables (UUID/ULID), nunca secuenciales.
- **Retención**: define y **aplica** el borrado. Un dato de tarjeta que no guardas no se filtra.

## 6. Rendimiento y operabilidad

- **SLI que importan**: tasa de autorización aprobada (por PSP, método, país y BIN), latencia
  p95/p99 y tasa de error del PSP, retraso del webhook, antigüedad de la partida no conciliada
  más vieja, tasa de disputa y de reembolso, coste efectivo por transacción.
- **La caída de la tasa de aprobación es un incidente** que ningún monitor de infraestructura
  ve: todo verde y el dinero no entra. Alerta por desviación de la línea base **por segmento**,
  no por umbral absoluto.
- **Timeouts explícitos y cortos** hacia el PSP, con clave de idempotencia lista para reintentar.
  Sin timeout, un PSP lento es tu caída.
- **Degradación**: si el PSP no responde, **no adivines el resultado**. Pago en "pendiente de
  confirmación", mensaje que no promete, y resolución por conciliación. El peor diseño posible
  es asumir fallo y dejar que el usuario reintente sobre un cargo que sí se hizo.
- **Multi-PSP** es resiliencia y coste, no adorno: dos integraciones, dos conciliaciones, dos
  modelos de token y una capa de enrutado. Justificable con volumen alto o dependencia
  geográfica; **prematuro casi siempre**.
- **Picos**: la campaña golpea el pago al final del embudo, con el usuario ya comprometido.
  Prueba de carga del flujo de pago completo y límites de tasa acordados con el PSP por
  adelantado.
- **Trazabilidad**: un identificador de correlación que atraviese pedido → intento → llamada al
  PSP → webhook → asiento → línea de liquidación. Sin él, un céntimo perdido cuesta días.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisión del alcance PCI **ante cada cambio de la página de pago**, y en todo
  caso anual; validación anual (SAQ/ROC) y escaneos ASV trimestrales cuando apliquen;
  seguimiento de las versiones de API del PSP y de sus fechas de retirada — **los PSP retiran
  versiones de API y no esperan**.
- **Registro de decisiones (ADR)** para: elección de PSP, arquitectura de integración y SAQ
  objetivo, política de captura, política de exenciones SCA, política de reembolso.

Prohibiciones:

- ❌ **PROHIBIDO almacenar CVV/CVC2/CAV2/CID, contenido de pista o PIN tras la autorización**,
  en base de datos, log, caché, cola, backup, hoja de cálculo o ticket de soporte. Cifrado
  incluido.
- ❌ **PROHIBIDO representar dinero con coma flotante.** Ni en la API, ni en el dominio, ni en la
  base de datos, ni en JSON.
- ❌ **PROHIBIDO un `UPDATE` o `DELETE` sobre un asiento contable ya escrito.** Se corrige con
  contra-asiento.
- ❌ **PROHIBIDO llamar al PSP sin clave de idempotencia** en cualquier operación que mueva
  dinero.
- ❌ **PROHIBIDO tratar un webhook como fuente de verdad** sin releer el estado por API, y
  **prohibido procesarlo sin verificar la firma**.
- ❌ **PROHIBIDO reenviar el PAN a través de tu servidor "solo de paso"**. Ese *proxy* de una
  línea convierte todo el servicio en CDE.
- ❌ **PROHIBIDO capturar antes de poder entregar**, salvo modelo de negocio que lo justifique y
  se comunique.
- ❌ **PROHIBIDO deducir el estado de un pago del código HTTP de una respuesta perdida.** Un
  `timeout` no es un fallo: es un desconocido.
- ❌ **PROHIBIDO desactivar la SCA "porque convierte peor"** sin exención aplicable y sin quien
  la aplique legítimamente.
- ❌ **PROHIBIDO un endpoint de pago sin limitación de tasa** (es un validador de tarjetas
  robadas para otro, y las autorizaciones las pagas tú).
- ❌ **PROHIBIDO registrar solo el importe neto liquidado.** Bruto, comisión, retención y cambio,
  cada uno con su asiento.
- ❌ **PROHIBIDO copiar de este documento un plazo de disputa, una comisión o un umbral de
  esquema sin verificarlo con tu adquirente.**
- ❌ **PROHIBIDO recolectar datos de tarjeta por correo, chat, teléfono grabado o ticket de
  soporte.** Es el atajo que convierte a atención al cliente en parte del CDE.

## 8. Verificación web obligatoria

Comprobar **antes** de fijar nada:

1. **PCI DSS**: versión vigente (a agosto de 2026, **v4.0.1**), estado de los requisitos que
   dejaron de ser buena práctica el **31-03-2025**, y su número exacto. Fuente primaria:
   `pcisecuritystandards.org` → Document Library. **Hueco declarado**: el PDF de PCI DSS v4.0.1
   devuelve **HTTP 403** a la descarga automatizada (requiere aceptar el acuerdo de licencia);
   el texto de los requisitos 3.3.1.1/3.3.1.2/3.3.1.3 citado en §3.3 procede de una
   **reproducción de tercero** (`sammy.codific.com`), no de la fuente primaria. **Contrástalo
   con el PDF oficial antes de usarlo como evidencia de auditoría.** El único texto del PCI SSC
   citado aquí de origen directo es la FAQ 1280 del blog oficial.
2. **SAQ A / A-EP / D**: criterios de elegibilidad vigentes, la FAQ 1588 y su revisión, y el
   número de ítems de cada cuestionario. Y por encima de todo, **lo que exijan tu adquirente y
   tu QSA**, que mandan sobre cualquier lectura genérica.
3. **PSD2 / SCA**: Reglamento Delegado **(UE) 2018/389** en EUR-Lex (CELEX 32018R0389) y las
   directrices y opiniones de la **EBA**, que son las que fijan la interpretación operativa
   (delegación de SCA, MIT frente a recurrente, alcance del *one-leg*).
4. **PSD3 / PSR**: estado en el Observatorio Legislativo del PE —**2023/0209(COD)** y
   **2023/0210(COD)**— y en EUR-Lex. A agosto de 2026 **no hay acto final publicado**; la fecha
   indicativa de pleno es 14/12/2026. Cualquier fuente que los dé por aprobados o que fije
   fechas de aplicación está adelantándose.
5. **MiCA**: Reglamento (UE) **2023/1114**, fin de los regímenes transitorios nacionales
   (Art. 143(3)) y **registro de proveedores autorizados de ESMA** para verificar a tu
   contraparte.
6. **SEPA**: rulebooks vigentes del **EPC** (SCT, SCT Inst, SDD Core, SDD B2B) — plazos de
   devolución, presentación y validez de mandato cambian entre versiones — y el Reglamento
   (UE) **2024/886**.
7. **EMV 3DS**: versión publicada y borradores en `emvco.com`, y **qué versión soporta de
   verdad tu PSP** (va por detrás).
8. **Reglas de esquema (Visa, Mastercard)**: plazos y motivos de disputa, umbrales de programas
   de monitorización, condiciones exactas del traslado de responsabilidad. **Hueco declarado**:
   el PDF público de reglas de Visa devuelve **HTTP 403** a la descarga automatizada; consíguelo
   por tu adquirente. **No se afirma aquí ningún plazo ni porcentaje de esas reglas.**
9. **Tasas de intercambio**: Reglamento (UE) **2015/751** (0,2 % débito / 0,3 % crédito de
   consumidor) y sus exclusiones; y el **precio real de tu PSP**, que se cita de su página de
   precios con fecha o no se cita.
10. **`Idempotency-Key`**: estado del borrador IETF (a agosto de 2026, **expirado**) y la
    semántica concreta —ventana, conflicto, alcance de la clave— **en la documentación de tu
    PSP**.
11. **ISO 4217**: número de decimales por divisa. `iso.org` bloquea la descarga automatizada
    (**HTTP 403**): usa la lista mantenida de tu biblioteca de i18n y verifica los casos
    concretos con los que vas a operar.
12. **Tu PSP**: versión de API vigente y calendario de retirada, cambios en el flujo 3DS,
    condiciones de portabilidad de tokens ante un cambio de proveedor.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
