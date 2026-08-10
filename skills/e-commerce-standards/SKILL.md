---
name: e-commerce-standards
description: Use when building or operating an online store as a system — choosing between Shopify, WooCommerce, Magento Open Source / Adobe Commerce, PrestaShop, Saleor, Medusa, commercetools and VTEX, SaaS versus self-hosted total cost including per-transaction fees, monolith versus composable MACH, product catalog with variants SKUs and attributes, stock reservation and the oversell race condition, cart and guest session, price lists and EU VAT with OSS and IOSS, shipping rates and returns, checkout funnel and guest checkout, order and fulfillment state machines, product SEO with canonical URLs and schema.org Product structured data, URL migration and 301 redirect maps at replatform, faceted navigation and crawl traps, promotions coupon stacking and discount abuse, scalping bots and inventory hoarding, card-not-present fraud screening, Black Friday traffic peaks and capacity, European Accessibility Act duties for e-commerce services, Consumer Rights Directive withdrawal and the order-with-obligation-to-pay button, Omnibus prior-price rules, GPSR, and consent-aware commerce analytics.
---

# Estándares de comercio electrónico

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, elegir plataforma para, o revisar una **tienda online como sistema**:
catálogo, inventario, carrito, precio, impuestos, envío, checkout, pedido, devolución,
promociones, búsqueda de producto, SEO de catálogo, picos de tráfico y abuso. Cubre también
la decisión previa —**si conviene montar tienda propia**— y la de replataforma.

Triggers: SKU, variante, atributo de producto, catálogo, *stock*, reserva de inventario,
sobreventa, carrito, checkout, invitado frente a registro, pedido, `order state machine`,
*fulfillment*, envío, devolución, RMA, IVA, OSS, IOSS, cupón, promoción, `schema.org/Product`,
JSON-LD, `canonical`, redirección 301, mapa de redirecciones, facetas, `noindex`, `sitemap.xml`,
`robots.txt`, Black Friday, *scalping*, *bot*, CNP, `Shopify`, `WooCommerce`, `Magento`,
`Adobe Commerce`, `PrestaShop`, `Saleor`, `Medusa`, `commercetools`, `VTEX`, *headless*,
*composable*, MACH.

**Tesis de la skill**: **una tienda es un sistema de inventario y contabilidad con una web
delante**. La web se rehace cada tres años; el catálogo, el stock, el histórico de pedidos y el
mapa de URLs sobreviven a todas las modas — y son lo que se rompe en cada replataforma. Diseña
para eso, no para el tema visual.

Segunda tesis: **casi todos los "problemas de tienda" son problemas de concurrencia o de
identidad de URL disfrazados.** El sobrevendido es una condición de carrera; el cupón acumulado
hasta el 100 % es una condición de carrera con lógica de negocio; la caída de tráfico tras una
migración es un mapa de redirecciones incompleto. Ninguna de las tres se arregla con más *cache*.

**No aplica**: ver `fintech-payments-standards` (**skill hermana de este lote y dependencia
dura**: alcance PCI DSS y elección de SAQ, tokenización, SCA/PSD2 y sus exenciones, 3-D Secure,
máquina de estados de autorización y captura, idempotencia del cobro, conciliación y
liquidación, *chargebacks*, contabilidad en unidades mínimas y libro mayor inmutable.
**Frontera exacta: el importe a cobrar se decide aquí; desde `POST /payments` en adelante es
suyo.** Regla que evita duplicar: *cuánto y por qué → esta skill; qué le pasa a ese importe →
pagos*), `gaming-infrastructure-standards` y `game-development-standards` (**la tienda de un juego
es una tienda y entra aquí**: catálogo, precio, moneda virtual como SKU, impuesto y carrito, con
el cobro delegado igual que cualquier otro en `fintech-payments-standards`. Lo que no es de aquí:
la validación del recibo **en el servidor de juego** y la verificación por firma de su *webhook*,
que son suyas porque el cliente miente), `web-performance-standards` (**la medición y el presupuesto de rendimiento son
suyos**: Core Web Vitals, datos de campo, percentil 75, presupuestos en CI. Aquí solo **dónde
duele en una tienda** —ficha de producto y checkout— y qué se prioriza cuando hay que elegir.
No dupliques métricas ni umbrales: delégalos), `caching-cdn-standards` (política de caché,
clave, purga y CDN; aquí solo **qué es cacheable en una tienda y qué nunca lo es**: catálogo
sí, carrito y precio personalizado no), `search-engines-standards` (**motor de búsqueda,
indexación, relevancia, sinónimos y facetas técnicas son suyos**; aquí qué se espera de la
búsqueda de producto y por qué la faceta mal expuesta genera una trampa de rastreo),
`accessibility-standards` (**criterio técnico WCAG/EN 301 549, auditoría y herramientas son
suyos**; aquí solo **que el comercio electrónico es servicio obligado** por la Directiva
(UE) 2019/882 y qué implica para el proyecto — §3.10), `appsec-standards` (modelado de
amenazas y OWASP; aquí solo el abuso propio del dominio: cupones, *scalping*, enumeración de
catálogo), `privacy-engineering-standards` (base legal, consentimiento, retención y derechos;
aquí solo el punto de fricción concreto con la analítica de comercio — §3.11),
`analytics-bi-standards` (**el cuadro de mando y su gobierno son suyos**; aquí qué evento de
comercio hay que emitir y por qué el embudo se mide en el servidor), `cms-jamstack-standards`
(**modelado y edición de contenido editorial, CMS *headless*, previsualización y revalidación
tras publicar**; aquí el catálogo como dato transaccional, que no es contenido),
`frontend-web-platform-standards` y `frontend-frameworks-standards` (la construcción del
escaparate), `i18n-standards` (idioma, formato de precio y fecha, `hreflang`, catálogo
multi-mercado), `data-warehouse-modeling-standards` (el hecho `pedido` para analítica),
`message-brokers-standards` (eventos de pedido e inventario y su entrega *at-least-once*),
`microservices-architecture-standards` (**el criterio de cuándo trocear** — clave para juzgar
el argumentario *composable* de §3.2), `sre-practice-standards` y `observability-standards`
(SLO, telemetría, capacidad y la preparación del pico de campaña), `opensource-licensing-standards`
(**la licencia de la plataforma decide qué puedes hacer con tu propia tienda**: OSL-3.0 de
Magento y PrestaShop no es MIT y tiene condiciones de copyleft y de red — §3.1),
`grc-compliance-standards` (obligaciones de consumo, marketplace y sanciones como programa),
`ai-governance-standards` (recomendador y precio dinámico: transparencia y clasificación).

## 2. Decisiones por defecto

> Verificar por web precios, licencias, versiones y estado normativo antes de fijarlos en un
> proyecto real (§8). Datos de **agosto de 2026**.

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| ¿Tienda propia? | **No, si vendes pocas referencias o el canal es un marketplace** | §3.1 |
| Plataforma inicial | **SaaS** (Shopify o equivalente) salvo requisito que lo impida | El coste de operar una tienda autoalojada se paga en incidentes, no en licencias |
| Arquitectura | **Monolito de la plataforma**; *composable* solo con caso demostrado | §3.2 |
| Pago | **Delegado al PSP con campos alojados** | Lo fija `fintech-payments-standards`: el alcance PCI manda |
| Precio e importe | **Entero en unidades mínimas + ISO 4217** | Idem |
| Inventario | **Reserva con decremento atómico y condición en la escritura**; nunca leer-comprobar-escribir | §3.4 |
| Carrito | **Servidor**, con identidad estable para invitado | Un carrito solo en el navegador se pierde y no se mide |
| Checkout | **Invitado por defecto**, registro opcional al final | §3.7 |
| Impuestos | **Motor de impuestos por destino**, no una tasa fija en configuración | §3.6 |
| URL de producto | **Estable e independiente del nombre**, con `canonical` explícito | §3.9 |
| Facetas | **`noindex` por defecto**, se abre a indexación caso por caso | Trampa de rastreo garantizada si no (§3.9) |
| Búsqueda | **Motor dedicado** cuando el catálogo pasa de lo trivial | Delegado a `search-engines-standards` |
| Promociones | **No acumulables por defecto**, con tope y validación en servidor | §3.8 |
| Analítica | **Eventos de servidor como fuente de verdad**, cliente como complemento | Bloqueadores y consentimiento hacen el cliente incompleto por diseño (§3.11) |
| Replataforma | **Mapa de redirecciones antes de escribir una línea de la tienda nueva** | §3.9 |

### 2.1 Plataformas: licencia y modelo de coste

Licencias **verificadas del fichero `LICENSE` en crudo** (agosto de 2026); precios **de la
página del proveedor**:

| Plataforma | Modelo | Licencia / precio verificado |
|---|---|---|
| **Shopify** | SaaS | Precios EUR de `shopify.com/pricing` (la página se declara *"accurate as of August 4, 2026"*): Basic **€32/mes** mensual o **€22/mes** anual, Grow **€92 / €62**, Advanced **€384 / €289**, Plus **desde €2.100/mes**. **Comisión por pasarela de terceros: 2 % / 1 % / 0,6 % / 0,2 %** según plan; tarifas de tarjeta online con Shopify Payments desde **2,1 % + €0,30** (Basic) hasta **1,3 % + €0,30** (Plus). **Ese porcentaje por usar otro PSP es la partida que decide la comparativa** y la que casi nadie mete en la hoja de cálculo |
| **WooCommerce** | Autoalojado (plugin de WordPress) | **GPL v3 o posterior**, verbatim del `license.txt`. Gratis; el coste es *hosting*, mantenimiento, y el ecosistema de extensiones de pago |
| **Magento Open Source** / **Adobe Commerce** | Autoalojado / licencia comercial | **OSL 3.0** (`LICENSE.txt` de `magento/magento2`) — **no es permisiva**: tiene copyleft y cláusula de uso externo. Ciclo de vida (Adobe, actualizado 2-6-2026): **2.4.9 publicada el 12-5-2026**; soporte regular de 2.4.8 hasta **11-4-2028**, de 2.4.7 hasta **9-4-2027**, de 2.4.6 hasta **11-8-2026**. Adobe Commerce se cotiza; sin precio público |
| **PrestaShop** | Autoalojado | **Core OSL-3.0, módulos AFL-3.0**, verbatim del `LICENSE.md`: *"PrestaShop Core is licensed under OSL-3.0 and PrestaShop Modules are licensed under AFL-3.0"* |
| **Saleor** | Autoalojado / cloud | **BSD 3-Clause** (`LICENSE` de `saleor/saleor`). Verificar aparte la licencia del dashboard y de los componentes comerciales |
| **Medusa** | Autoalojado / cloud | **MIT** (`LICENSE` de `medusajs/medusa`) |
| **commercetools** | SaaS *composable* | Sin precio público: la página declara modelo **por pedidos**, no por GMV. **Hueco: no hay cifra publicada** |
| **VTEX** | SaaS | Sin precio público: el formulario segmenta por **rango de GMV anual**, lo que indica modelo ligado a facturación. **Hueco: no hay cifra publicada** |

**Regla de comparación honesta**: el coste total es *cuota + comisión por transacción +
extensiones + hosting + personas*. Una plataforma "gratis" con 0,5 puntos más de comisión es
más cara que una de pago desde un volumen sorprendentemente bajo — **haz la cuenta con tu ticket
medio y tu volumen antes de elegir**, no con la tabla de características.

## 3. Criterio técnico

### 3.1 Cuándo NO montar una tienda propia

Casos en los que la tienda es la respuesta equivocada, dichos sin diplomacia:

- **Menos de una decena de referencias y sin recurrencia**: un enlace de pago del PSP resuelve
  el 100 % del problema con el 2 % del código.
- **El canal real es un marketplace**: si tus ventas vienen de un tercero, tu tienda propia es
  un coste fijo con tráfico de vanidad. La decisión es de negocio y hay que tomarla explícita.
- **Producto digital o suscripción pura**: el problema es facturación y derechos de acceso, no
  catálogo ni logística.
- **No hay quien opere**: una tienda es un sistema en producción 24×7 con dinero. Sin alguien
  responsable de parches, incidentes y descuadres, el autoalojado es una brecha con fecha.
- **B2B con precio negociado y pedido por representante**: eso es un ERP con portal, no una
  tienda.

Y la trampa de licencia que se descubre tarde: **OSL-3.0 (Magento, núcleo de PrestaShop) no es
MIT**. Antes de asumir que puedes distribuir un fork, empaquetar un SaaS multi-tienda o
publicar módulos derivados, pasa la decisión por `opensource-licensing-standards`.

### 3.2 Monolito frente a *composable* / MACH

El argumentario *composable* es real pero se vende mal. Criterio honesto:

**El monolito de plataforma gana** cuando el catálogo cabe en el modelo estándar, el equipo es
pequeño, y la ventaja competitiva no está en el escaparate. Un tema bien hecho sobre una
plataforma madura resuelve el 90 % de las tiendas.

***Composable* se justifica** cuando: hay varios canales o mercados con reglas distintas y el
mismo catálogo; el modelo de producto no encaja en el estándar (configuradores, precio por
contrato, unidades de medida); hay equipos separados que necesitan desplegar sin bloquearse; o
la plataforma actual es el cuello de botella **medido**, no sospechado.

**Coste que se omite en la presentación**: cada pieza tiene su contrato, su versión, su
facturación, su latencia y su modo de fallo — y **la consistencia entre catálogo, precio y
stock deja de ser una transacción de base de datos para convertirse en un problema
distribuido**. Ese salto es exactamente el de `microservices-architecture-standards`: si no
estás dispuesto a pagar *outbox*, idempotencia y consistencia eventual, no estás listo para
*composable*. **Trocear una tienda no la hace más rápida; la hace más difícil de dejar
incoherente sin darte cuenta.**

### 3.3 Catálogo, variantes y atributos

- **Distingue producto y variante desde el modelo**: el producto es lo que se describe y se
  posiciona; la **variante (SKU) es lo que tiene precio, stock y peso**. Modelarlos como una
  sola entidad es el error estructural que obliga a rehacer el catálogo.
- **El SKU es un identificador de negocio, opaco y estable**. No codifiques atributos dentro
  (`CAM-ROJ-XL` se convierte en mentira el día que cambia el color).
- **Atributos tipados** (número con unidad, booleano, enumeración), no cadenas libres: de ellos
  salen las facetas, los filtros y el *feed* de producto. Un atributo de texto libre no es
  filtrable ni comparable.
- **La media también es catálogo**: un identificador estable por imagen, con variantes de
  tamaño generadas, no subidas a mano.
- **Versionado del esquema de atributos**: añadir un atributo obligatorio a un catálogo vivo es
  una migración, con su valor por defecto y su plan de relleno.

### 3.4 Inventario: la condición de carrera que define el dominio

**"Comprobar y luego restar" es un bug garantizado bajo concurrencia.** Este patrón, en
cualquier lenguaje, sobrevende:

```
stock = SELECT quantity FROM inventory WHERE sku = ?
if stock >= n:  ->  UPDATE inventory SET quantity = quantity - n WHERE sku = ?
```

Entre el `SELECT` y el `UPDATE` cabe otra petición. No es improbable: en un lanzamiento, es lo
normal. Alternativas correctas, en orden de preferencia:

1. **Decremento condicional atómico**: la comprobación viaja **dentro** de la escritura, y la
   base de datos garantiza que solo una gana. `UPDATE ... SET quantity = quantity - :n WHERE
   sku = :sku AND quantity >= :n`, y **si afecta a cero filas, no hay stock**. Una sola
   sentencia, sin lectura previa, sin bloqueo explícito.
2. **Reserva con caducidad**: para checkouts largos, el stock se **reserva** al entrar al
   checkout y se convierte en consumo al confirmar, o expira. Exige un proceso que libere
   reservas caducadas — y ese proceso es parte del diseño, no un extra.
3. **Restricción en la base de datos como red de seguridad**: `CHECK (quantity >= 0)`. No
   sustituye a lo anterior; convierte un sobrevendido silencioso en un error visible.

Decisiones asociadas:

- **La reserva es una decisión de negocio, no técnica**: reservar al añadir al carrito protege
  al comprador y permite el acaparamiento por bots (§3.8); reservar al pagar maximiza la venta
  y produce cancelaciones. Elige explícitamente, con caducidad.
- **Sobreventa controlada** (aceptar pedido sin stock, reponer) es una estrategia legítima si es
  **explícita y comunicada**, con su plazo. Sobreventa accidental es un incidente de atención
  al cliente y de reputación.
- **Una sola fuente de verdad de stock**. Si el ERP y la tienda tienen cada uno su número, la
  pregunta no es cuál está bien, sino cuál manda y con qué latencia. Escríbelo.
- **Multi-almacén** cambia el problema: el stock disponible depende del destino y del método de
  envío. No lo modeles como un entero global si vas a necesitarlo.

### 3.5 Carrito, pedido y sus estados

- **El carrito vive en el servidor** con un identificador propio, ligado al usuario cuando lo
  hay y a una cookie de primera parte cuando no. Fusionar carrito de invitado con carrito de
  usuario al iniciar sesión es un caso que hay que decidir y probar (¿se suma?, ¿gana el más
  reciente?), no dejar al azar.
- **El precio se recalcula en el servidor en el momento de confirmar.** Todo importe que llegue
  del cliente es una sugerencia hostil. Es la vulnerabilidad de tienda más antigua que existe y
  sigue apareciendo.
- **El pedido es inmutable una vez confirmado**; los cambios son eventos posteriores
  (modificación, cancelación parcial, devolución), no ediciones. Esto es lo que permite explicar
  a un cliente —o a un inspector— por qué se le cobró lo que se le cobró.
- **Máquina de estados explícita**, con transiciones permitidas declaradas: `creado → pagado →
  preparado → enviado → entregado`, más `cancelado` y `devuelto` con sus reglas. Una columna
  `status` de texto libre sin transiciones válidas acaba con pedidos en estados imposibles.
- **El estado del pedido no es el estado del pago** (`fintech-payments-standards`, §3.4). Un
  pedido pagado y no enviado y un pedido enviado y no cobrado son ambos posibles y ambos
  necesitan representación.

### 3.6 Precio, impuestos e IVA en la UE

- **Precio con y sin impuestos, separados en el modelo**, con el criterio de presentación
  decidido por mercado (B2C con impuestos incluidos, B2B habitualmente sin).
- **El destino manda.** En la UE, para ventas a distancia a consumidores, el lugar de
  tributación es el del cliente. El umbral está en el Art. 59c de la Directiva del IVA
  (introducido por la Directiva (UE) 2017/2455), verbatim: la excepción solo aplica si *"the
  total value, exclusive of VAT, of the supplies referred to in point (b) does not in the
  current calendar year exceed EUR 10 000"* — y también el año anterior. **Por encima de 10 000
  € totales intracomunitarios, se aplica el tipo del país de destino.**
- **OSS** (ventanilla única) permite declarar todo eso en un solo Estado miembro en lugar de
  registrarse en cada uno. **IOSS** cubre las importaciones: aplica a envíos *"in consignments
  of an intrinsic value not exceeding EUR 150"* (Art. 369l, verbatim). Por encima, declaración
  aduanera completa.
- **Consecuencia de ingeniería**: el tipo de IVA es función de *(categoría de producto, país de
  destino, fecha)*. Una tasa fija en configuración es correcta exactamente hasta la primera
  venta transfronteriza. Y **los tipos cambian**: guarda el tipo aplicado en el pedido, no lo
  recalcules desde la configuración actual al reimprimir una factura de hace dos años.
- **Rebajas**: la Directiva (UE) 2019/2161 introdujo el Art. 6a en la Directiva 98/6/CE,
  verbatim: *"Any announcement of a price reduction shall indicate the prior price applied by
  the trader"*, y *"The prior price means the lowest price applied by the trader during a period
  of time not shorter than 30 days prior to the application of the price reduction."*
  Traducción a producto: **necesitas el histórico de precios de 30 días como dato consultable**,
  no como registro de auditoría enterrado. Si tu plataforma no lo guarda, lo tienes que añadir.
- **Verificar en §8** tipos, umbrales y transposición nacional: esta skill fija la mecánica, no
  las tasas.

### 3.7 Checkout: donde se pierde el dinero

- **Invitado por defecto.** Obligar a registrarse antes de pagar es la fricción autoinfligida
  más cara del embudo. Ofrece crear cuenta *después* de confirmar, con la contraseña como único
  campo extra.
- **Menos campos y menos pasos**, con validación en línea y mensajes que digan cómo corregir.
  Autocompletado del navegador funcionando (`autocomplete` correcto en cada campo) vale más que
  cualquier rediseño.
- **Coste total visible pronto.** Los gastos de envío que aparecen en el último paso son la
  causa de abandono que aparece en todos los estudios; también es lo que exige el Art. 8(3) de
  la Directiva 2011/83/UE (indicar restricciones de entrega y medios de pago aceptados **al
  inicio del proceso de pedido**).
- **Botón de confirmación con obligación de pago.** Art. 8(2), verbatim: *"the button or
  similar function shall be labelled in an easily legible manner only with the words 'order with
  obligation to pay' or a corresponding unambiguous formulation"*, y **si no se cumple, "the
  consumer shall not be bound by the contract or order"**. Un botón que ponga "Continuar" en el
  paso final no es un detalle de copia: **puede invalidar el contrato**.
- **Nada de extras preseleccionados.** Art. 22, verbatim: si el comerciante infiere el
  consentimiento *"by using default options which the consumer is required to reject"*, el
  consumidor tiene derecho al reembolso de ese importe. Seguros, envíos premium y donaciones
  marcadas por defecto son ilegales, no agresivas.
- **Rendimiento**: la ficha de producto y el checkout son las dos rutas donde el rendimiento se
  convierte en dinero — pero **cómo se mide y qué umbral se exige lo fija
  `web-performance-standards`**. Aquí solo la prioridad: si hay que elegir dónde gastar el
  presupuesto de rendimiento, se gasta ahí, no en la portada.
- **Cifras que NO debes citar** (§4 de higiene intelectual, y ver §8):
  - **"Cada 100 ms de latencia cuestan un 1 % de ventas"**. Procede de una entrada de blog de
    Greg Linden (2006) y de una diapositiva suya posterior sobre un experimento **interno de
    Amazon nunca publicado**: no hay diseño experimental, ni tamaño de muestra, ni definición de
    "ventas". Se repite desde entonces por citación circular, con la cifra aplicada a bases de
    ingresos que difieren en cuatro órdenes de magnitud. **Es folclore, no evidencia.** Mide tu
    embudo.
  - **"El 70 % de los carritos se abandonan"**. Baymard publica el **70,22 %** como **media
    aritmética de 50 estudios de terceros** (2006-2025), con valores individuales entre ~55 % y
    ~84 %, de proveedores distintos y **sin definición común de "carrito abandonado"**. La
    metodología está publicada y es honesta *en lo que dice ser*: una media de medias. Usarla
    como objetivo de tu tienda es un error de categoría.
  - **"La conversión media del sector es X %"**: depende del tipo de producto, del ticket, del
    canal de tráfico y de si cuentas sesiones o usuarios. **Sin esas cuatro variables la cifra
    no significa nada.** Compárate contigo mismo.

### 3.8 Promociones, abuso y bots

**Los cupones son la vulnerabilidad de negocio más rentable que existe**, porque no requiere
explotar nada: basta con que las reglas se compongan de una forma que nadie modeló.

Defensas, todas en servidor:

- **No acumulables por defecto.** La acumulación es una excepción que se habilita por regla, con
  orden de aplicación **definido y determinista** (¿el porcentaje se aplica antes o después del
  importe fijo? La respuesta cambia el resultado).
- **Tope duro por pedido**: descuento máximo absoluto y porcentaje máximo, aplicados **después**
  de combinar todo. Es la red que atrapa lo que la lógica no previó.
- **El descuento nunca puede hacer negativo un importe** — ni la línea, ni el envío, ni el
  total. Comprueba también el caso de la devolución parcial de un pedido con cupón: cuánto se
  devuelve de un descuento repartido es una decisión, no un cálculo obvio.
- **Límite de usos por cupón y por cliente**, aplicado con la misma disciplina atómica del
  stock (§3.4): un contador leído y luego incrementado se salta con peticiones concurrentes.
- **Códigos no adivinables** para cupones personales; los códigos secuenciales o basados en el
  nombre de la campaña se enumeran en minutos.
- **Registro de cada aplicación de descuento** con su regla y su importe, para poder explicar
  después qué pasó y cuánto costó.

**Bots y reventa (*scalping*)**: en lanzamientos limitados, el atacante no rompe nada — usa tu
tienda más rápido que una persona. Postura defensiva:

- **La reserva al añadir al carrito es la munición del acaparador.** Si reservas, pon caducidad
  corta y límite por identidad.
- **Límite por unidad de identidad** (cuenta, método de pago, dirección de envío), sabiendo que
  cada uno se puede multiplicar y que el límite por IP molesta a usuarios legítimos con NAT.
- **Cola de espera** para lanzamientos: convierte una carrera en un orden, y de paso protege la
  capacidad.
- **Detección por comportamiento**, no por *user-agent*: tiempo hasta el carrito, ausencia de
  navegación previa, patrones de reintento. Alimenta a la telemetría, no bloquees a ciegas.
- **Métrica honesta**: la tasa de falsos positivos. Un antibot que bloquea clientes reales
  cuesta más que la reventa que evita.

**Fraude sin tarjeta presente**: el cribado, la puntuación de riesgo y el traslado de
responsabilidad son de `fintech-payments-standards`. Lo que aporta esta skill: **las señales de
comercio son las mejores entradas del modelo** (disparidad entre facturación y envío, pedido
muy por encima del ticket medio, cuenta recién creada, prisa por el envío exprés, artículos de
alta reventa). Expórtalas al motor de fraude en vez de reimplementarlo.

### 3.9 SEO de catálogo y la migración de URLs

**La migración de URLs es la forma más común de destruir un negocio online**, y es
completamente evitable. En una replataforma:

1. **Exporta el inventario completo de URLs vivas ANTES de tocar nada**: rastreo del sitio
   actual + `sitemap.xml` + registros del servidor de los últimos meses + páginas con enlaces
   entrantes o tráfico orgánico. Los logs son la fuente que nadie mira y la que contiene las
   URLs que aún reciben visitas.
2. **Mapa 1:1 de origen a destino**, revisado a mano en las de más tráfico. Una redirección a
   la portada **no es una redirección**: es una pérdida.
3. **`301` (permanente), no `302`**, y **sin cadenas**: origen → destino final, en un salto.
4. **Verificación automatizada post-despliegue**: recorrer todo el mapa y comprobar código y
   destino. Es una prueba, y se ejecuta en CI.
5. **Los parámetros también migran**: filtros, paginación e identificadores de campaña.
6. **Mantén las redirecciones para siempre.** Retirarlas "porque ya nadie las usa" es repetir la
   migración un año después.

Resto del criterio de catálogo:

- **`canonical` explícito en toda página de producto**, apuntando a la URL de referencia. El
  mismo producto accesible desde varias categorías es duplicado si no lo declaras.
- **Facetas: `noindex` por defecto.** Cada combinación de filtros es una URL; N filtros generan
  crecimiento combinatorio y una trampa de rastreo que consume presupuesto de rastreo y
  produce contenido casi idéntico. Se abren a indexación **casos concretos** con demanda de
  búsqueda demostrada.
- **Producto agotado o descatalogado**: la peor opción es `404`. Mantén la página con estado
  claro y alternativas, o redirige al producto sucesor o a su categoría. Borrar acumula
  errores y tira el posicionamiento ganado.
- **Datos estructurados** `schema.org/Product` con oferta, precio, divisa y disponibilidad, en
  JSON-LD. **Deben coincidir con lo que ve el usuario**: marcar un precio distinto del real es
  motivo de penalización, no una optimización. **Verifica los requisitos vigentes del buscador
  en §8**: cambian y no avisan.
- **Paginación e infinito**: si el listado es infinito, garantiza que existe una ruta rastreable
  equivalente. El contenido que solo aparece tras interacción, para un rastreador no existe.

### 3.10 Accesibilidad y obligaciones de consumo

**El comercio electrónico es un servicio expresamente cubierto** por la Directiva (UE) 2019/882
(Acta Europea de Accesibilidad): el Art. 2(2)(f) lista *"e-commerce services"* entre los
servicios prestados a consumidores **después del 28 de junio de 2025**, y el Art. 31(2) fija esa
fecha de aplicación. Dos matices verificados que evitan afirmaciones falsas en ambos sentidos:

- **Exención de microempresas** (Art. 4(5), verbatim): *"Microenterprises providing services
  shall be exempt from complying with the accessibility requirements referred to in paragraph 3
  […]"*. Microempresa se define en el Art. 3(23): **menos de 10 personas y volumen de negocio o
  balance anual no superior a 2 millones de euros**. La exención cubre servicios, no productos.
- **Régimen transitorio** (Art. 32): los Estados miembros prevén un periodo **hasta el 28 de
  junio de 2030** durante el cual se pueden seguir prestando servicios con productos ya
  utilizados legalmente antes; y los contratos de servicio acordados antes del 28-6-2025 pueden
  continuar sin alteración hasta expirar, con un máximo de cinco años.

**El criterio técnico de conformidad —WCAG, EN 301 549, auditoría, herramientas— es de
`accessibility-standards`.** Lo que aporta esta skill: **es obligatorio y afecta al checkout,
que es exactamente donde peor suele estar** (mensajes de error no anunciados, foco perdido tras
validar, temporizadores de reserva sin aviso, selectores de variante inaccesibles por teclado).

Otras obligaciones de consumo que condicionan el diseño (Directiva 2011/83/UE, verbatim en
§3.7): **derecho de desistimiento de 14 días** en contratos a distancia (Art. 9(1)), con sus
excepciones tasadas del Art. 16 —bienes personalizados, bienes precintados abiertos por higiene,
bienes perecederos, contenido digital ya ejecutado con consentimiento expreso—. Y el Reglamento
(UE) 2023/988 (**GPSR**), aplicable desde el **13 de diciembre de 2024**, que impone
obligaciones de información y trazabilidad de producto a vendedores en línea y mercados. **La
implementación concreta y las transposiciones se verifican en §8**; aquí solo su existencia y
su efecto sobre el modelo de datos: **necesitas datos de fabricante y de responsable en la UE
como atributos de producto**, no como texto suelto en la descripción.

### 3.11 Analítica, consentimiento y datos personales

- **El embudo se mide en el servidor.** Los eventos de cliente están sistemáticamente
  incompletos por bloqueadores, rechazo de consentimiento y fallos de red — y el sesgo **no es
  aleatorio**, con lo que las tasas calculadas solo con datos de cliente están desviadas de una
  forma que no puedes corregir. Los eventos de servidor (pedido creado, pago confirmado, envío)
  son completos por construcción.
- **Sin consentimiento no hay analítica no esencial.** El diseño correcto es: la tienda funciona
  entera sin consentimiento, y la analítica es aditiva. Si tu embudo se rompe cuando el usuario
  dice que no, el problema es de arquitectura. **La base legal, el diseño del consentimiento y
  la retención son de `privacy-engineering-standards`.**
- **Minimiza lo que guardas del pedido.** Dirección de envío y contacto son necesarios;
  reconstruir un perfil de comportamiento indefinido no lo es. Y ojo: **la retención contable y
  fiscal obligatoria convive mal con el derecho de supresión** — esa colisión se resuelve
  separando el dato transaccional obligatorio del dato de comportamiento, y se documenta.
- **El recomendador y el precio dinámico son decisiones automatizadas con impacto**: consúltalo
  con `ai-governance-standards` antes de personalizar precios, que es donde está el riesgo
  regulatorio y reputacional real.

## 4. Calidad y pruebas

- **Prueba de concurrencia sobre stock**: N compras simultáneas de la última unidad ⇒ **una**
  venta y N−1 rechazos. En paralelo real, contra la base de datos real. Es la prueba que define
  si el sistema es correcto.
- **Prueba de concurrencia sobre cupón de uso único**: mismo patrón.
- **Prueba de composición de promociones**: combinación de reglas que intente llevar el total
  por debajo de cero o por encima del tope; debe fallar de forma controlada.
- **Prueba de manipulación de precio**: petición con importe alterado desde el cliente ⇒
  rechazo.
- **Prueba de impuestos por matriz** (categoría × país × fecha), con al menos un caso de cambio
  de tipo y uno de reimpresión de factura antigua.
- **Prueba del mapa de redirecciones** tras cada despliegue que toque URLs: cada origen devuelve
  `301` al destino esperado, en un salto.
- **Prueba de datos estructurados** contra el validador del buscador y contra el precio real
  renderizado.
- **Prueba de accesibilidad automatizada sobre ficha y checkout** como *gate*, con auditoría
  manual del checkout — la automática no ve lo que rompe un checkout (delegado a
  `accessibility-standards`).
- **Prueba de carga del flujo completo de compra** antes de cada campaña, no del catálogo solo.
- **Gates de CI**, coste creciente: *linters* y tipos → pruebas unitarias de precio, impuesto y
  descuento → pruebas de concurrencia de stock y cupón → validación del mapa de redirecciones →
  accesibilidad automatizada → presupuesto de rendimiento (`web-performance-standards`) →
  integración con el *sandbox* del PSP.

## 5. Seguridad del stack

- **Todo importe y toda regla se validan en el servidor.** Precio, descuento, portes, impuesto,
  cantidad. Sin excepción.
- **Autorización de objeto en todo recurso de cliente**: pedido, factura, dirección, devolución.
  `GET /orders/{id}` sin comprobar propiedad expone historiales de compra completos, y es el
  hallazgo más repetido en tiendas.
- **Cadena de suministro del *frontend***: cada *script* de terceros en la página de pago es un
  riesgo de *skimming* de tarjeta (**y un requisito PCI DSS**, ver `fintech-payments-standards`
  §3.2). Inventario, CSP y control de integridad; **el marketing no añade píxeles al checkout
  sin revisión**.
- **Ecosistema de extensiones**: en plataformas autoalojadas, el plugin de terceros es el vector
  dominante. Política: número mínimo, origen conocido, actualizadas, y ninguna abandonada.
  Trátalas como dependencias con SCA (`appsec-standards`).
- **Enumeración**: identificadores de pedido no secuenciales; limitación de tasa en búsqueda,
  login, recuperación de contraseña y validación de cupón.
- **Toma de cuentas**: el histórico de pedidos, las direcciones y el método de pago guardado son
  el botín. MFA disponible, aviso por correo ante cambio de dirección o de contraseña, y
  reautenticación antes de operaciones sensibles.
- **Devoluciones y reembolsos como control de negocio**: quién puede emitir uno, hasta qué
  importe y con qué segunda firma. El fraude interno vive aquí.
- **Datos de tarjeta**: nunca en tu sistema. Delegado y no negociable
  (`fintech-payments-standards` §3.1).

## 6. Rendimiento y operabilidad

- **Qué es cacheable**: catálogo, ficha de producto, listados y recursos estáticos, sí — con las
  reglas de `caching-cdn-standards`. **Carrito, precio personalizado, disponibilidad exacta y
  cualquier página de sesión, no.** Cachear una respuesta personalizada en el borde es una fuga
  de datos, no una optimización.
- **Disponibilidad publicada frente a stock exacto**: la ficha puede servir un valor cacheado
  con granularidad gruesa ("disponible" / "pocas unidades"), y **la verdad se comprueba al
  reservar**. Intentar servir el número exacto en tiempo real desde el catálogo es lo que
  tumba la base de datos en campaña.
- **SLI de tienda**: tasa de conversión por paso del embudo, tasa de error del checkout, latencia
  del cálculo de portes e impuestos (dependencias externas), tasa de fallo del proveedor de
  envío, antigüedad del pedido más viejo sin procesar, tasa de sobrevendidos.
- **Picos de campaña**: el patrón es **catálogo × 20, checkout × 5, y todo concentrado en
  minutos**. Preparación: prueba de carga con el perfil real, cola de espera activable, límites
  de tasa acordados con PSP y transportista, plan de degradación (desactivar recomendaciones y
  personalización antes que el pago), y **congelación de despliegues** durante la ventana.
- **Dependencias externas con timeout y alternativa**: si el cálculo de portes en tiempo real no
  responde, sirve una tarifa de respaldo; **no bloquees el checkout esperando a un tercero**.
- **Trabajo asíncrono**: correos, *feeds* de marketplace, sincronización con el ERP e
  indexación de búsqueda van en cola, nunca en la petición de compra.
- **Un pedido nunca se pierde por un fallo posterior al pago.** Persistirlo es la operación que
  no puede fallar; todo lo demás es reintentables.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: parches de la plataforma y de las extensiones dentro de su ventana de soporte
  (ver fechas de ciclo de vida en §2.1 y verificarlas en §8); revisión anual del catálogo de
  extensiones para retirar lo no usado; revisión del mapa de redirecciones en cada cambio de
  estructura de URLs.
- **Salida planificada**: antes de casarte con una plataforma, comprueba **cómo se exportan
  catálogo, clientes, pedidos y tokens de pago**. Una tienda sin ruta de salida es rehén.
- **ADR** para: elección de plataforma, arquitectura monolito/composable, política de reserva de
  stock, política de acumulación de promociones, y estrategia de URLs.

Prohibiciones:

- ❌ **PROHIBIDO el patrón leer-comprobar-restar sobre stock, saldo o contador de cupón.** La
  condición va dentro de la escritura atómica.
- ❌ **PROHIBIDO confiar en cualquier importe, cantidad, descuento o impuesto enviado por el
  cliente.**
- ❌ **PROHIBIDO tocar el PAN.** Ver `fintech-payments-standards` §3.1.
- ❌ **PROHIBIDO migrar de plataforma sin mapa de redirecciones verificado**, y **prohibido
  redirigir todo a la portada**.
- ❌ **PROHIBIDO borrar la URL de un producto descatalogado** dejando un `404`.
- ❌ **PROHIBIDO exponer facetas indexables sin control**: es una trampa de rastreo.
- ❌ **PROHIBIDO un botón de confirmación de pedido que no exprese la obligación de pago**, y
  **prohibidos los extras preseleccionados** (Art. 8(2) y Art. 22 de la Directiva 2011/83/UE).
- ❌ **PROHIBIDO anunciar una rebaja sin el precio anterior más bajo de los 30 días previos.**
- ❌ **PROHIBIDO cachear en el borde cualquier respuesta que dependa de la sesión.**
- ❌ **PROHIBIDO obligar a registrarse para comprar** sin una justificación de negocio escrita.
- ❌ **PROHIBIDO añadir *scripts* de terceros a la página de pago sin revisión** — es un requisito
  de PCI DSS, no una preferencia.
- ❌ **PROHIBIDO justificar una decisión con "el 100 ms cuesta un 1 %" o "el 70 % abandona el
  carrito"** sin la medición de tu propio embudo (§3.7).
- ❌ **PROHIBIDO que el embudo deje de medirse cuando el usuario rechaza el consentimiento**: eso
  significa que dependes del cliente para datos que debían ser de servidor.
- ❌ **PROHIBIDO instalar una extensión abandonada** en una plataforma autoalojada.

## 8. Verificación web obligatoria

Comprobar **antes** de fijar nada:

1. **Precios y comisiones de plataforma**: página oficial de cada proveedor, con fecha. Los de
   §2.1 son de `shopify.com/pricing` en **EUR** (la propia página se fecha el **4-8-2026**) y
   varían por país y por moneda. **Huecos declarados: commercetools y VTEX no publican cifras**
   — sus páginas remiten a ventas; cualquier número que encuentres en un blog es una filtración
   sin verificar.
2. **Licencias**: fichero `LICENSE`/`LICENSE.md` **en crudo del repositorio**, nunca la etiqueta
   de GitHub ni un artículo. Verificado así: Magento OSL-3.0, PrestaShop OSL-3.0 + AFL-3.0 para
   módulos, Saleor BSD-3-Clause, Medusa MIT, WooCommerce GPL-3.0-or-later. **Vuelve a
   comprobarlo**: en este catálogo van dieciséis suposiciones de licencia desmentidas.
3. **Ciclo de vida de Adobe Commerce / Magento**: página de versiones publicadas de Adobe
   (última actualización verificada: 2-6-2026). Las fechas de fin de soporte se mueven.
4. **IVA UE**: umbral del Art. 59c (10 000 €), límite IOSS (150 €), tipos por país y categoría
   y estado del paquete **ViDA** — que modifica el régimen y cuyo calendario **no se afirma
   aquí**. Fuente primaria: EUR-Lex y el portal de fiscalidad de la Comisión.
5. **Derechos de consumo**: Directiva 2011/83/UE (Arts. 8, 9, 16, 22), Directiva (UE) 2019/2161
   (Art. 6a de la Directiva 98/6/CE) y **su transposición nacional**, que es la que te aplica.
6. **Accesibilidad**: Directiva (UE) 2019/882 (Arts. 2, 3(23), 4(5), 31, 32) y **la ley nacional
   de transposición**, más la norma armonizada vigente. En España la referencia es la Ley
   11/2023 — **verifícala, esta skill no la ha comprobado en crudo** (hueco declarado).
7. **GPSR**: Reglamento (UE) 2023/988, aplicable desde el 13-12-2024, y su guía de aplicación.
8. **Datos estructurados**: requisitos vigentes del buscador para fichas de producto
   (propiedades obligatorias, políticas de precio y disponibilidad). Cambian sin aviso y una
   ficha que ayer cumplía hoy puede no cumplir.
9. **Cifras del sector**: **desconfía por defecto.** Antes de citar una tasa de abandono, de
   conversión o de impacto de la latencia, exige metodología publicada. Las dos más repetidas
   están desmontadas en §3.7: la de los 100 ms **no tiene fuente primaria** (entrada de blog y
   diapositiva de 2006 sobre un experimento interno no publicado) y la del 70 % es una **media
   de 50 estudios de proveedor** con rango de ~55 % a ~84 % y sin definición común.
10. **PCI DSS** aplicado a la página de pago (requisitos 6.4.3 y 11.6.1, elegibilidad de SAQ A):
    **verificarlo en `fintech-payments-standards` §8**, que es donde vive esa comprobación.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
