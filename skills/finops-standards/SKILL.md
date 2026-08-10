---
name: finops-standards
description: Cost as an engineering metric, not a monthly invoice report. Use when defining a unit-economics metric (cost per request, per active user, per GB processed, per token), building a tag or label policy and the IaC/admission gate that enforces it, designing account/subscription/project layout as an allocation boundary, splitting shared and platform cost, deciding commitment coverage for reserved instances, savings plans or committed-use discounts, normalizing billing data with FOCUS (focus.finops.org, BilledCost, EffectiveCost, ContractedCost, ListCost, ChargeCategory, CommitmentDiscountId, AllocatedResourceId, ConsumedUnit, SkuId), reading a cost and usage export in a warehouse, wiring cost anomaly alerts and budget thresholds, choosing showback versus chargeback, running OpenCost or IBM Kubecost for Kubernetes cost allocation, adding infracost breakdown or infracost diff to a pull request, hunting idle resources, orphaned volumes, unattached public IPs, load balancers, non-production environments and data-egress or observability bills, tracking AI inference and token spend, or applying the FinOps Framework phases, domains, capabilities and Scopes.
---

# Estándares de FinOps

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**FinOps es la disciplina de decidir con el coste como métrica de ingeniería, no un informe
mensual de la factura.** Un informe describe el pasado y no cambia nada; una métrica de ingeniería
entra en la revisión de diseño, en el PR y en la alerta, y **bloquea o desbloquea decisiones**. Si
el coste solo aparece en una diapositiva a fin de mes, aquí no hay práctica de FinOps: hay
contabilidad.

**Restricción dura de esta skill: se queda el MÉTODO y cede el SERVICIO concreto.** El criterio de
coste de un servicio determinado —qué clase de instancia, qué nivel de almacenamiento, qué modelo
de facturación tiene esa base de datos gestionada, qué flag lo abarata— **ya vive en
`aws-standards`, `azure-standards` y `gcp-standards`**, y allí se decide. Aquí se decide **cómo se
mide, cómo se asigna, quién responde y qué gate lo impone**, con independencia del proveedor.
Si esta skill y una de nube dan una cifra sobre el mismo servicio, **manda la skill de nube**.

Cubre: marco FinOps y su vocabulario (fases, dominios, capacidades, Scopes), **unidad económica**,
asignación (etiquetado y su gobierno, jerarquía de cuentas, coste compartido), compromisos y
descuentos, orden de impacto de las palancas, catálogo de costes ocultos, previsión y presupuesto,
anomalías, *showback*/*chargeback*, normalización de datos de facturación con **FOCUS**, coste en
Kubernetes, coste de inferencia de IA y herramientas (`OpenCost`, `Kubecost`, `Infracost`).

**No aplica**: ver `aws-standards`, `azure-standards`, `gcp-standards` (**el servicio concreto, su
modelo de precio y su configuración son suyos**; aquí el método, la unidad económica, la asignación
y el gobierno), `kubernetes-standards` (*requests*, límites, *autoscaling* y programación; **aquí
solo el coste que producen y su reparto entre inquilinos**), `iac-standards` (**el etiquetado se
impone en el código: la herramienta, el módulo y el estado son suyos; la política de etiquetas —qué
claves, qué valores, qué es obligatorio— es de aquí**), `data-platform-standards`,
`lakehouse-standards` y `data-engineering-standards` (**el coste de escaneo y el particionado como
decisión de coste ya viven allí**: esta skill no vuelve a decidir un layout de Parquet ni una
clave de partición, solo exige que ese coste tenga dueño y unidad), `gpu-computing-standards`
(**la GPU como recurso caro que se comparte, se mide y se planifica ya es suya**; aquí el coste de
inferencia como categoría de gasto y su unidad), `caching-cdn-standards` (egreso, *hit ratio* y
facturación del CDN), `object-storage-standards` (clases, ciclo de vida y coste por petición),
`sre-practice-standards` (**fiabilidad frente a coste es un trade-off explícito y el *error budget*
es suyo**: ninguna optimización de coste se aprueba aquí si consume presupuesto de error sin
decisión registrada allí), `green-it-standards` (huella de carbono y
eficiencia energética; coste y emisiones **correlacionan pero no son la misma métrica** —§6.4),
`grc-compliance-standards` (control interno, auditoría y segregación de funciones sobre el gasto),
`platform-engineering-standards` (**el coste de la plataforma interna es una unidad económica más y
se mide con el método de aquí**; los gates de etiquetado se implantan en su camino pavimentado y en
su capa de admisión), `enterprise-architecture-standards` (**el coste por aplicación que produce esta skill es
una de las entradas de su decisión de ciclo de vida** —tolerar, invertir, migrar, eliminar—; el
inventario, la criticidad y el gobierno del estándar son suyos. Una aplicación cara y sin dueño no
es un problema de coste, es un problema de cartera), `green-it-standards` (**frontera recíproca
porque las dos comparten palancas y no comparten métrica**: apagar lo ocioso, dimensionar y elegir
región reducen coste **y** carbono, y por eso se confunden. **La unidad económica es de aquí; la
unidad de carbono es suya.** Divergen más de lo que parece: **la huella incorporada del hardware
hace que alargar la vida útil de un equipo pese más que optimizar su consumo**, lo que puede
contradecir una decisión de renovación tomada solo por coste; y una región barata no es
necesariamente una región de baja intensidad de carbono. **Cuando las dos métricas apuntan en
sentidos opuestos, se declaran las dos y decide el negocio** — ninguna de las dos skills recorta a
la otra en silencio).

## 2. Decisiones por defecto

> Verificar la última versión y el estado de las fuentes citadas por web antes de fijar nada (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Marco de referencia | **FinOps Framework** de la FinOps Foundation (programa de la Linux Foundation), edición **2026** | Ninguna: no hay otro marco con vocabulario compartido con los proveedores |
| Formato de datos de facturación | **FOCUS**, versión **1.4** (ratificada el **4-jun-2026**) como esquema de destino | 1.3 / 1.2 si el proveedor aún no emite 1.4; **nunca** el esquema propietario como capa de consumo |
| Métrica de éxito | **Coste por unidad de negocio** (unidad económica) | Coste absoluto **solo** para tesorería y compromiso, nunca para evaluar ingeniería |
| Asignación | **Cuenta/suscripción/proyecto** como frontera primaria + etiquetas como dimensión secundaria | Solo etiquetas si la jerarquía no se puede tocar — asumiendo la fuga que implica |
| Gobierno de etiquetas | **Gate en IaC (obligatorio) + gate en admisión (Kubernetes)**; política declarada como código | Barrido correctivo posterior **solo** como transición con fecha de fin |
| Modelo de reparto | **Showback** por defecto | **Chargeback** solo con presupuesto real por equipo y capacidad de actuar (§6.5) |
| Coste de Kubernetes | **OpenCost** (Apache-2.0, CNCF *Incubating*) | **IBM Kubecost** si se necesita retención larga o soporte comercial (§2.1) |
| Coste antes del despliegue | **Infracost** en el PR (`infracost breakdown` / `infracost diff`) | Cálculo propio sobre la API de precios del proveedor si Infracost no cubre el recurso |
| Anomalías | Detección nativa del proveedor + **una alerta accionable con dueño**, no un correo a una lista | Detección propia sobre el export FOCUS en el almacén, si se necesita dimensión de negocio |

### 2.1 Estado y licencia de las herramientas (verificado en crudo)

| Herramienta | Licencia (leída del `LICENSE`) | Estado / propiedad | Modelo de precio |
|---|---|---|---|
| **OpenCost** | **Apache-2.0** (`opencost/opencost`) | **CNCF**: aceptado el 17-jun-2022, **Incubating desde el 25-oct-2024**. Mantenido por IBM Kubecost, Randoli y comunidad | Gratis; se paga la infraestructura que lo sostiene (Prometheus/almacenamiento) |
| **Kubecost** | Producto propietario (el núcleo abierto es OpenCost) | **Adquirido por IBM** (anuncio del **17-sep-2024**), integrado en la suite FinOps de IBM junto a Cloudability y Turbonomic; su web redirige a `apptio.com` | Nivel **Foundations "Always free"**: *"Unlimited clusters up to 250 cores"*, *"15-day metric retention"*. **Enterprise Self-hosted y Enterprise Cloud: precio no publicado** — hay que pedirlo |
| **Infracost** | **Apache-2.0** (`infracost/infracost` y el nuevo `infracost/cli`) | Vivo; código refactorizado en repos separados (`infracost/cli` es ahora el núcleo) | **Free: 1000 runs/mes** · **Starter: $250/mo, 10.000 runs** · **Cloud: $1.000/mo** · **Enterprise: a consultar**. La API de precios alojada es servicio **separado del código**: se puede autohospedar (`INFRACOST_PRICING_API_ENDPOINT`) para saltarse el límite |

**Trampa de licencia, la que más se falla**: que el CLI sea Apache-2.0 **no** hace gratis el
servicio. Infracost es el caso canónico: código permisivo, **API de precios alojada con cuota**.
La decisión de compra se toma sobre el servicio, no sobre el `LICENSE`. Antes de fijar cualquiera
de estas tres como default de un proyecto: **leer su `LICENSE` en crudo y su página de precios el
mismo día** (§8).

### 2.2 El marco FinOps, edición 2026 (verificado)

Definición vigente, **verbatim** de `finops.org`: *"FinOps is an operational framework and cultural
practice which maximizes the business value of technology, enables timely data-driven decision
making, and creates financial accountability through collaboration between engineering, finance,
and business teams."* (publicada el **19-mar-2026**).

- **Fases** (verbatim): `Inform` · `Optimize` · `Operate`. Madurez, verbatim: *"A FinOps approach of
  'Crawl, Walk, Run' enables organizations to start small, and grow in scale, scope, and
  complexity."*
- **4 dominios y 22 capacidades** (verbatim de la página del marco):
  - **Understand Usage & Cost**: Data Ingestion · Allocation · Reporting & Analytics · Anomaly Management
  - **Quantify Business Value**: Planning & Estimating · Forecasting · Budgeting · KPIs & Benchmarking · **Unit Economics**
  - **Optimize Usage & Cost**: Architecting & Workload Placement · Usage Optimization · Rate Optimization · Licensing & SaaS · Sustainability
  - **Manage the FinOps Practice**: **Executive Strategy Alignment** · FinOps Practice Operations · Governance, Policy & Risk · FinOps Education & Enablement · Invoicing & Chargeback · FinOps Assessment · Automation, Tools & Services · Intersecting Disciplines
- **Cambios de la edición 2026** (esto sí se ha revisado y ampliado, no asumir la edición anterior):
  **`Executive Strategy Alignment` es capacidad nueva** en `Manage the FinOps Practice`; se
  profundiza el constructo de **Scopes** con más *Technology Category pages*; se añade la
  convergencia con disciplinas adyacentes; y se actualiza la definición. El renombrado de
  *"Optimize Cloud Usage and Cost"* a **"Optimize Usage & Cost"** viene de la edición **2025**,
  que fue la que introdujo **Scopes** como elemento del marco.
- **Scope**, verbatim: *"A FinOps Scope is a defined segment of technology-related spending –
  aligned to business constructs such as products, cost centers, or environments."* La consecuencia
  operativa: **el marco ya no es solo de nube pública** — SaaS, licencias, centro de datos y **IA**
  son categorías tecnológicas de pleno derecho.
- **La FinOps Foundation es un programa de la Linux Foundation** y actualizó su misión, verbatim:
  *"from 'Advancing the People who manage the value of Cloud' to 'Advancing the People who manage
  the Value of Technology.'"*

**No usar el marco como plantilla organizativa.** Es un vocabulario común para que ingeniería,
finanzas y negocio digan lo mismo con las mismas palabras, y un mapa de capacidades para detectar
huecos. Montar un comité por cada capacidad es la forma habitual de fracasar con él.

## 3. Estructura y convenciones

### 3.1 La unidad económica es el único indicador que importa

Regla dura: **todo sistema con coste relevante declara una unidad económica antes de que se le
apruebe una acción de optimización.** Sin denominador no hay optimización, hay recorte.

```
unidad_económica = coste_asignado_del_sistema / unidad_de_valor_del_sistema
```

La unidad de valor la fija el dueño del producto, no ingeniería, y es **una** por sistema:
coste por **transacción**, por **usuario activo (DAU/MAU)**, por **petición servida**, por **GB
procesado**, por **pedido**, por **documento indexado**, por **token** o **por caso de uso
resuelto** en IA.

**Por qué el gasto total absoluto es una métrica engañosa en un sistema que crece**: un servicio que
pasa de 100.000 € a 130.000 € al mes mientras triplica el tráfico ha **mejorado un 57 %** su
eficiencia, y en el informe aparece como un +30 % de desviación. La consecuencia práctica es peor
que la estadística: penalizar el absoluto **premia no crecer** y castiga al equipo que absorbió
demanda. Y a la inversa: un total plano con tráfico cayendo es un empeoramiento silencioso.
Corolario: **una alerta de presupuesto sobre valor absoluto no es una alerta de eficiencia**; sirve
para tesorería y para el techo de gasto, no para evaluar ingeniería.

Reglas de la métrica:
- Se publica **junto a la métrica de negocio que la denomina**, en el mismo panel. Una cifra de
  coste sin su denominador visible no se publica.
- Se compara **contra sí misma en el tiempo**, no contra otro equipo ni contra un *benchmark* de
  proveedor. Un objetivo válido se escribe como *"coste por pedido ≤ X € a fecha Y"*, no como
  *"reducir un 20 % el gasto"*.
- Se recalcula cuando cambia el denominador (cambio de definición de "usuario activo") y el cambio
  se anota en la serie: una serie temporal con la definición cambiada a mitad **es una mentira**.
- Un sistema sin unidad de valor identificable (herramienta interna, plataforma) usa **coste por
  equipo servido** o **coste por servicio desplegado** — pero declara una.

### 3.2 Asignación: etiquetas, jerarquía y coste compartido

**Una política de etiquetas sin gate que la imponga no existe.** Es la regla central de esta
sección: el documento de nomenclatura que nadie puede incumplir mecánicamente produce, a los seis
meses, una fracción de gasto no asignable que crece sola. Por tanto:

1. **Política declarada como código**, no en una wiki. Conjunto mínimo obligatorio, con valores de
   dominio cerrado donde sea posible:

   | Clave | Obligatoria | Valores | Para qué decide |
   |---|---|---|---|
   | `owner` | Sí | Identificador de equipo del directorio, **no** un correo personal | A quién se le pregunta y quién apaga |
   | `cost-center` | Sí | Lista cerrada de finanzas | Reparto contable |
   | `service` | Sí | Nombre del catálogo de servicios | Unir coste con la unidad económica |
   | `environment` | Sí | `prod` / `staging` / `dev` / `sandbox` | Barrido de no producción (§3.5) |
   | `data-classification` | Sí si hay datos | Clases de `grc-compliance-standards` | Cruce coste/retención |
   | `expires` | Sí en `sandbox` y efímeros | Fecha ISO-8601 | Apagado automático |

2. **Gate 1 — IaC**: el recurso no se crea sin las claves obligatorias. La *herramienta* (política
   como código en el plan, módulos con etiquetas por defecto, *default tags* del proveedor) la
   decide `iac-standards`; **la lista de claves y sus valores válidos la decide esta skill.**
3. **Gate 2 — admisión**: en Kubernetes, el objeto sin las etiquetas obligatorias se rechaza en el
   *admission controller* (implantación: `platform-engineering-standards`).
4. **Gate 3 — detección**: informe semanal de gasto no etiquetable, con **umbral duro**: si el gasto
   no asignable supera el **5 % del total**, la asignación no es fiable y **no se toman decisiones
   de reparto** hasta corregirlo. Ese 5 % es un umbral de gobierno propuesto aquí, **no un dato
   empírico de la industria**: ajústalo al tamaño de la cuenta, pero fija uno y escríbelo.

**Límite conocido del etiquetado, no negociable**: hay costes que **no llevan etiqueta** por
construcción (soporte, cuotas de plataforma, tráfico entre zonas, servicios sin dimensión de
recurso, descuentos de compromiso a nivel de organización). Por eso:

**La jerarquía de cuentas/suscripciones/proyectos es la frontera primaria de asignación, y las
etiquetas la dimensión secundaria.** Motivo: la frontera de cuenta se impone sola, no depende de
que alguien la escriba bien y sobrevive a los recursos que no aceptan etiquetas. Regla de diseño:
**una cuenta/proyecto por (equipo × entorno)** como grano por defecto; agrupar más solo con
justificación escrita, porque cada agrupación convierte coste directo en coste compartido.

**Coste compartido y su reparto.** Categorías: plataforma (clúster, malla, CI), observabilidad,
red y salida a Internet, seguridad, licencias, soporte y descuentos de compromiso. Método por
defecto, en este orden:
1. **Métrica de consumo real** si existe y es barata de obtener (CPU·hora y GiB·hora reservados en
   Kubernetes; GB ingeridos en logs; peticiones en la API interna).
2. **Proporcional al coste directo** del consumidor, si no hay métrica.
3. **Reparto fijo por cabeza/equipo** solo para lo irreducible (soporte, licencias corporativas).

**Por qué el reparto perfecto no compensa**: el reparto tiene un coste de ingeniería y un coste
político que crecen mucho más rápido que su precisión. Criterio operativo: **se refina el modelo de
reparto solo mientras un cambio de reparto pueda cambiar una decisión.** Si afinar del 90 % al 97 %
de precisión no hace que ningún equipo actúe distinto, el trabajo es puro teatro contable —
declárese `no asignado`, repártase de forma simple y documentada, y dedíquese ese esfuerzo a la
unidad económica. Un modelo de reparto **estable y comprensible** vale más que uno exacto que nadie
entiende ni puede impugnar.

### 3.3 FOCUS: normalizar antes de analizar

FOCUS (*FinOps Open Cost and Usage Specification*) es **la pieza más accionable del dominio** y el
único punto donde un estándar abierto sustituye a N esquemas propietarios. Estado verificado:
**versión 1.4, ratificada por el FOCUS Steering Committee el 4-jun-2026**; versiones anteriores
1.3, 1.2 (29-may-2025), 1.1 (7-nov-2024), 1.0.

Criterio: **la capa de consumo (paneles, alertas, unidad económica, reparto) se construye contra
columnas FOCUS, no contra el esquema propietario del proveedor.** El export nativo se ingiere tal
cual y se transforma a FOCUS en la capa de modelado; nadie escribe una consulta de negocio contra
un nombre de columna que solo existe en un proveedor. Beneficio real y comprobable: la misma
consulta responde en las tres nubes y una migración no reescribe los cuadros de mando.

Columnas que hay que saber distinguir (nombres exactos de la especificación):

| Columna | Qué es | Cuándo se usa |
|---|---|---|
| `ListCost` | Precio de tarifa antes de descuentos | Medir el descuento conseguido; **nunca** para reparto |
| `ContractedCost` | Precio tras descuentos **negociados** | Negociación con el proveedor |
| `BilledCost` | Vista **de caja**: lo facturado por el emisor | Conciliación con finanzas y tesorería |
| `EffectiveCost` | Coste **reconocido al consumir** (amortiza compromisos) | **La única válida para unidad económica y reparto** |

Regla derivada, la que más se incumple: **usar `BilledCost` para la unidad económica produce
escalones falsos** — el mes en que se compra una reserva la eficiencia se hunde y el siguiente
parece milagrosa. Unidad económica y *showback* van siempre con `EffectiveCost`; la conciliación
contable, con `BilledCost`.

Otras columnas de decisión: `ChargeCategory` (`Usage`/`Purchase`/`Tax`/`Credits`/`Adjustments`) para
separar consumo de compra; `ChargeClass` para aislar correcciones; `CommitmentDiscountId`,
`CommitmentDiscountType` y `CommitmentDiscountStatus` para medir cobertura y utilización (§3.4);
`SkuId`, `ConsumedQuantity`, `ConsumedUnit`, `PricingQuantity`, `PricingUnit`; `ServiceCategory`;
`Tags`; `InvoiceId`.

Novedades de 1.3 y 1.4 que cambian criterio:
- **1.3** (ratificada el **4-dic-2025**) añadió las columnas de **reparto explícito de coste
  compartido** — `AllocatedResourceId`, `AllocatedResourceName`, `AllocatedMethodId`,
  `AllocatedMethodDetails` — y el *dataset* **Contract Commitment**, además de marcas de recencia y
  completitud del dato. Consecuencia directa: **el método de reparto deja de ser un secreto de una
  hoja de cálculo y pasa a viajar con el dato**; exígelo a tus generadores.
- **1.4** añade los *datasets* **Invoice Detail** y **Billing Period** y ~17 columnas de compromiso,
  de forma que la conciliación con cuentas por pagar se hace **contra los mismos datos** que usa
  ingeniería. Los cuatro *datasets* de 1.4: `Cost and Usage` (obligatorio), `Billing Period`,
  `Contract Commitment` e `Invoice Detail`.
- **Discrepancia declarada**: sobre la fecha de ratificación de 1.3, la página de la especificación
  da **4-dic-2025** y hay fuentes secundarias que dicen 5-dic-2025, con el anuncio público el
  11-dic-2025. Se usa la fecha de la especificación; si importa contractualmente, verifícalo en el
  changelog del repositorio.
- **Cobertura desigual**: la adopción por proveedor va por detrás de la especificación (hay
  anuncios de disponibilidad general de **1.2** conviviendo con la publicación de 1.3/1.4).
  **Nunca asumir que tu proveedor emite la última versión**: compruébalo antes de diseñar el modelo.
  Existe además un programa de **certificación de conformidad** para generadores de datos anunciado
  para 2026: verificar su estado antes de exigirlo por contrato (§8).

### 3.4 Compromisos y descuentos

Instancias reservadas, planes de ahorro, descuentos por uso comprometido y sus equivalentes en
otros proveedores. **Comprometerse es apostar sobre la arquitectura futura**, no es una
optimización: se cambia flexibilidad por descuento, y quien firma acepta el riesgo de que el
sistema al que se compromete deje de existir antes que el compromiso.

Criterio de decisión, en orden:
1. **Primero se dimensiona, luego se compromete.** Comprometerse sobre una flota sobredimensionada
   compra el error a tres años. Prohibido invertir el orden.
2. **Cobertura objetivo sobre el suelo estable de consumo**, nunca sobre el pico ni sobre la media.
   El suelo se calcula con el percentil bajo del consumo diario de los últimos meses, y **el objetivo
   de cobertura se escribe como decisión propia del equipo, con su ventana y su percentil**. Aquí no
   se fija un porcentaje universal: quien te dé un "80 % de cobertura" como verdad de la industria
   no está mirando tu perfil de carga. Lo que sí es regla: **la cobertura se decide sobre una serie
   histórica documentada, no sobre una intuición**.
3. **Dos métricas obligatorias, y son distintas**: **cobertura** (qué fracción del consumo elegible
   está bajo compromiso) y **utilización** (qué fracción del compromiso comprado se está usando).
   Cobertura alta con utilización baja es dinero quemado; utilización 100 % con cobertura baja es
   descuento sin explotar. Ambas se sacan de `CommitmentDiscountId`/`Status` en FOCUS.
4. **El plazo se elige por la vida esperada de la arquitectura, no por el descuento.** Regla
   falsable: **si el equipo no puede escribir por qué ese servicio seguirá existiendo con esa forma
   al final del plazo, el plazo es demasiado largo.**
5. **Preferir el compromiso más fungible** (el que cubre familias/regiones/servicios amplios) sobre
   el más específico, salvo que la diferencia de descuento esté cuantificada y el consumo sea
   rígido y demostrado.
6. **Dueño y fecha de revisión**: cada compromiso tiene un responsable nominal y una revisión antes
   del vencimiento. Un compromiso que se renueva solo por inercia es un error que se duplica.
7. **Mercado secundario y cancelación**: antes de firmar, verificar si el compromiso concreto se
   puede vender, intercambiar o cancelar y con qué penalización — **eso lo decide la skill de la
   nube correspondiente**, pero **no firmes sin haberlo mirado**.

### 3.5 Las palancas, por orden de impacto real

El orden importa porque el esfuerzo se gasta casi siempre en el sitio equivocado. De mayor a menor
retorno por hora de ingeniería:

1. **Apagar lo que no se usa.** Es el único que da ahorro del 100 % del recurso y no tiene riesgo
   arquitectónico. Objetivos: entornos de no producción fuera de horario, recursos huérfanos
   (volúmenes sin adjuntar, instantáneas antiguas, IP públicas reservadas sin uso, balanceadores sin
   destinos, direcciones y NAT sin tráfico), *sandboxes* caducados (`expires`), clústeres de prueba,
   datos en clases calientes que nadie lee, y **servicios enteros que ya nadie llama** — cruzar
   coste con tráfico observado, no con la opinión del equipo.
2. **Dimensionar.** Ajustar a demanda observada (no a la solicitada), autoescalado, escalado a cero
   donde el modelo lo permita. Riesgo controlado: se cambia margen por coste, y ese margen **es
   fiabilidad** → coordinado con `sre-practice-standards`.
3. **Elegir el modelo de precio correcto.** Bajo demanda / capacidad puntual (*spot*) / comprometido,
   clases de almacenamiento y ciclo de vida, licencia incluida frente a propia. Es la palanca de
   mejor relación esfuerzo/ahorro **una vez que 1 y 2 están hechos**, y la que peor sale si se hace
   antes (§3.4, regla 1).
4. **Arquitectura.** Cambiar el patrón: eliminar el trasiego de datos entre zonas, cambiar sondeo
   por eventos, mover cómputo junto al dato, sustituir un servicio gestionado caro por otro más
   barato con el mismo SLO, cambiar el formato o la compresión.

**Por qué la optimización de arquitectura llega tarde si no se pensó al diseñar**: cuando el sistema
está en producción con clientes, cambiar el patrón implica migración de datos, coexistencia,
reescritura de clientes y ventana de riesgo — un trabajo de meses cuyo ahorro se compara contra el
de apagar recursos ociosos en una tarde. El coste de una arquitectura **queda fijado en la revisión
de diseño**, y ahí es donde hay que meter la estimación. De ahí el gate de §4.2: **la estimación de
coste es un entregable del diseño, no del post-mortem de la factura.**

### 3.6 El catálogo de coste oculto

Lo que aparece en la factura y nadie previó. Se revisa **entero** en cada revisión de diseño:

| Categoría | Por qué sorprende | Qué hacer |
|---|---|---|
| **Transferencia de datos y egreso** | No se ve en el diseño: es la consecuencia de dónde pusiste las cosas. Incluye salida a Internet, **entre zonas de disponibilidad** e inter-región | Dibujar el flujo de datos con volúmenes **antes** de construir; contarlo como línea propia del presupuesto |
| **Peticiones a almacenamiento de objetos** | Se presupuesta el GB almacenado y factura el número de operaciones. Un patrón de muchos ficheros pequeños puede costar más en peticiones que en almacenamiento | Medir operaciones/mes, no solo GB; ver `object-storage-standards` |
| **IP públicas, balanceadores y NAT** | Cuestan por existir, no por usarse; se quedan tras eliminar lo que servían | Inventario periódico de recursos sin destino ni tráfico |
| **Logs, métricas, trazas y APM** | **La telemetría puede costar más que lo observado.** El coste crece con la cardinalidad y con la retención, y ambas crecen solas si nadie las gobierna | Presupuesto explícito de observabilidad como porcentaje del sistema observado; retención por clase de dato; muestreo de trazas; control de cardinalidad de etiquetas. Ver `observability-standards` |
| **No producción olvidada** | Ningún cliente se queja de un `staging` caro; nadie lo mira | Apagado programado por defecto, `expires` obligatorio en `sandbox`, y **coste de no producción como métrica reportada aparte** |
| **Datos que solo crecen** | Sin política de retención, el almacenamiento es un pasivo perpetuo | Ciclo de vida y retención decididos con `grc-compliance-standards` (obligación legal) y `data-platform-standards` |
| **Inferencia de IA** | Categoría nueva (§3.7) | Ver abajo |
| **SaaS y licencias** | Fuera del radar del equipo de nube; el marco 2026 las trae dentro | Inventario, asientos activos frente a comprados, fecha de renovación con dueño |
| **Soporte y cuotas de plataforma** | Porcentaje sobre el gasto: crecen automáticamente con todo lo demás | Contabilizar como compartido y repartir (§3.2) |
| **Egreso de salida del proveedor** | Impedimento económico a migrar | **Marco legal en la UE**: EU Data Act, Art. 29(1), verbatim: *"From 12 January 2027, providers of data processing services shall not impose any switching charges on the customer for the switching process."* Art. 29(2): en el periodo *"From 11 January 2024 to 12 January 2027"* pueden imponerse cargos reducidos, que según 29(3) *"shall not exceed the costs incurred by the provider ... that are directly linked to the switching process"*. Los cargos de egreso están dentro de la definición de *switching charges*. **Consecuencia**: no renovar automáticamente contratos con cláusulas de migración anteriores a esa fecha; revisar antes del vencimiento |

### 3.7 El coste de la inferencia de IA

Categoría nueva y ya de primer orden: el marco la trata como **Technology Category propia (*FinOps
for AI*)** dentro de Scopes, y la encuesta anual la sitúa como la prioridad de futuro declarada por
los practicantes (§6.6, con su advertencia de metodología).

Criterio:
- **Unidad económica obligatoria y de negocio, no técnica.** El **coste por token** sirve como
  métrica normalizadora entre modelos —la guía del marco lo define como
  `Cost Per Token = Total Cost / Number of Tokens Used`— pero **no es la métrica de decisión**: la
  métrica de decisión es **coste por caso de uso resuelto** (consulta atendida, documento resumido,
  ticket cerrado). El coste por token puede bajar mientras el coste por caso resuelto sube, porque
  el sistema reintenta más o razona más largo. Si solo mides tokens, no ves eso.
- **Desglosar el token**: entrada frente a salida, **en caché frente a sin caché**, y por modelo.
  Son precios distintos y palancas distintas; agregarlos oculta la única optimización barata que
  existe (caché de prompt y elección de modelo por tarea).
- **Medir reintentos y errores**: un fallo que se reintenta se paga dos veces y no produce valor.
  Coste de reintento como línea propia.
- **Separar entrenamiento/ajuste (lote, planificable, apto para capacidad puntual) de inferencia
  (interactiva, con SLO)**. Son perfiles de compra opuestos.
- **GPU dedicada frente a API por token**: el punto de equilibrio depende de la utilización real de
  la GPU, y la GPU se paga esté o no ocupada. **El dimensionamiento, la compartición y la medida de
  utilización de GPU son de `gpu-computing-standards`**; aquí solo la regla: **no se compra ni se
  reserva GPU sin una serie de utilización medida**.
- **FOCUS ya lo cubre sin columnas especiales**: los generadores expresan el consumo de IA con
  `SkuId` de cargo por token y `ConsumedUnit`/`ConsumedQuantity` en tokens. No inventes un esquema
  paralelo.
- Ver `llm-app-engineering-standards`, `rag-standards` y `local-inference-standards` para las
  palancas técnicas (caché, enrutado de modelo, cuantización); aquí solo su contabilidad.

## 4. Calidad y gates

### 4.1 Los gates, en orden de coste creciente

| # | Gate | Momento | Rompe |
|---|---|---|---|
| 1 | **Etiquetas obligatorias presentes y con valor de dominio válido** | Validación de IaC en el PR | Sí |
| 2 | **Etiquetas obligatorias en admisión** (Kubernetes) | *Admission controller* | Sí |
| 3 | **Estimación de coste del cambio en el PR** (`infracost diff` o equivalente) | PR | **Comentario informativo por defecto**; rompe si supera el umbral del repo (§4.2) |
| 4 | **Presupuesto/umbral por cuenta o proyecto** con alerta a dueño nominal | Continuo | Notifica; **no** rompe despliegues |
| 5 | **Detección de anomalías** con dueño y runbook | Diario | Abre incidencia |
| 6 | **Barrido de recursos huérfanos y `expires` vencidos** | Semanal | Apaga en no producción; abre ticket en producción |
| 7 | **Revisión de cobertura/utilización de compromisos** | Mensual | Decisión documentada |
| 8 | **Revisión de la unidad económica por sistema** | Mensual, con el dueño del producto | Acción o justificación escrita |

### 4.2 El gate de coste en el PR: cómo se hace bien

- **Empieza informando, no bloqueando.** Un gate que bloquea desde el día uno con estimaciones que
  el equipo no entiende se desactiva en dos semanas. Secuencia: comentario → umbral alto que rompe →
  umbral ajustado.
- **El umbral es sobre el delta mensual estimado, no sobre el total**, y lo fija el repositorio.
  Escribirlo en el repo; no heredarlo de un default de la herramienta.
- **Estimación ≠ factura.** La estimación no conoce el uso (peticiones, egreso, escalado). Se
  compara con la realidad al menos una vez por trimestre en los sistemas grandes; si la desviación
  es sistemática, se corrige el modelo o se deja de usar el número para decidir.
- **Un cambio de arquitectura con impacto de coste no se aprueba sin cifra estimada en la
  descripción del PR o en el ADR.** Es el gate que más ahorra y el único que actúa a tiempo (§3.5).

### 4.3 Cómo se prueba que el dato de coste es correcto

Cubriendo camino feliz **y bordes**, porque un modelo de coste roto es peor que no tenerlo: da
confianza falsa.
- **Conciliación**: la suma de `BilledCost` del periodo cuadra con la factura del proveedor, con
  tolerancia declarada. Sin esto, todo lo demás es decorativo.
- **Cierre de asignación**: `Σ (coste asignado) + no asignado = total`, y `no asignado ≤` umbral
  (§3.2). Prueba automática, no revisión visual.
- **Bordes que hay que probar explícitamente**: créditos y descuentos promocionales (`ChargeCategory
  = Credits`) que enmascaran el coste real; correcciones retroactivas (`ChargeClass`) que reescriben
  meses cerrados; cambio de moneda; meses de 28/31 días comparados sin normalizar; compras
  puntuales (`ChargeCategory = Purchase`) contaminando la serie de consumo; recursos creados y
  destruidos dentro del mismo periodo; impuestos.
- **Prueba de la propia serie**: un panel que cambia de forma cuando cambia la definición de la
  unidad económica y no lo anota **está roto**. Anotación obligatoria de cambios de definición.

## 5. Seguridad y gobierno del dato de coste

- **El dato de facturación es información de negocio sensible**: revela volumen, clientes,
  crecimiento y arquitectura. Se clasifica al menos como interno, con control de acceso por rol y
  auditoría de consultas. Un panel de coste abierto a toda la organización es una decisión, no un
  descuido.
- **Credenciales de las herramientas de coste: solo lectura, siempre.** OpenCost/Kubecost/agentes de
  terceros no necesitan permisos de escritura. Un agente FinOps con permiso de apagado es un
  interruptor de denegación de servicio con acceso a toda la cuenta.
- **La automatización que apaga recursos es una acción destructiva**: entorno no productivo
  únicamente, lista de exclusión explícita, aviso previo al dueño, y **nunca borrado** — apagado o
  cambio de clase reversible. El borrado lo autoriza una persona.
- **SaaS de FinOps de terceros**: recibe el export de facturación completo, que es un mapa de tu
  infraestructura. Due diligence de proveedor, mínimo privilegio, cifrado y salida del contrato
  documentada antes de firmar (`grc-compliance-standards`).
- **La optimización de coste no puede degradar controles de seguridad ni de cumplimiento sin
  decisión registrada**: retención de logs de auditoría, copias de seguridad, cifrado, alta
  disponibilidad y multi-región **no son grasa**. Si una acción de coste toca una de estas, va a
  ADR y la firma quien responde del riesgo, no quien responde del presupuesto.
- **Fraude y abuso**: un pico de coste puede ser un incidente de seguridad (minería tras un
  compromiso de credenciales, exfiltración masiva que dispara el egreso). **La alerta de anomalía de
  coste se enruta también a seguridad**, no solo a finanzas — es uno de los detectores más rápidos y
  baratos que existen (`incident-response-forensics-standards`).

## 6. Operación: previsión, presupuesto y reparto

### 6.1 Anomalías

- Una alerta de anomalía **sin dueño nominal y sin runbook no se crea**. El correo a una lista de
  distribución es ruido con coste de atención.
- La detección se hace sobre **la serie con la granularidad en la que alguien puede actuar** (por
  servicio y cuenta), no sobre el total de la organización: en el total, todo se compensa y no se ve
  nada.
- **Umbral doble obligatorio**: relativo (desviación sobre lo esperado) **y** absoluto mínimo. Sin
  el absoluto, un recurso de 3 € que se dobla genera la misma alerta que uno de 30.000 €.
- Toda anomalía se cierra con **causa** (cambio de código, cambio de tráfico, cambio de precio del
  proveedor, error, incidente de seguridad), no con "resuelto".

### 6.2 Previsión frente a compromiso

Son dos cosas distintas y confundirlas es el error caro: la **previsión** es una estimación con
incertidumbre que sirve para planificar; el **compromiso** es una obligación contractual firmada
(§3.4). **No se firma un compromiso con el escenario central de una previsión, se firma con su suelo
conservador.** La previsión se publica con su intervalo y con sus supuestos escritos (crecimiento de
tráfico, lanzamientos previstos, cambios de precio conocidos); una previsión sin supuestos escritos
no es auditable y no sirve para negociar.

### 6.3 Presupuesto

- El presupuesto se fija sobre la **unidad de asignación que tiene dueño** (cuenta/proyecto/equipo),
  no sobre etiquetas frágiles.
- Umbrales escalonados con **acción distinta en cada uno** (aviso al dueño → revisión con finanzas →
  congelación de creación de recursos nuevos en no producción). Un umbral sin acción asociada es
  decoración.
- **PROHIBIDO** que un presupuesto excedido pare despliegues de producción de forma automática: eso
  convierte una desviación contable en un incidente de disponibilidad. Aplica también a la **cuota
  en admisión** que implanta `platform-engineering-standards`: puede frenar recursos nuevos y
  entornos efímeros, **no el rollout de un servicio ya en producción**.
- **Renegociar un SLO a la baja porque no cabe en el presupuesto es una decisión legítima y
  reglada, no un recorte silencioso.** Procedimiento, acordado con `sre-practice-standards`:
  esta skill aporta el coste por nueve —cuánto cuesta la redundancia, la multi-zona o la
  retención que sostienen el objetivo—; **el objetivo solo lo cambia quien responde del SLO**, por
  ADR firmado, con el impacto en el usuario declarado y comunicado a quien dependa del servicio.
  Sin ese ADR no hay renegociación: hay un recorte que se descubrirá en la próxima caída.

### 6.4 Coste y sostenibilidad

**Correlacionan pero no son la misma métrica** y tratarlas como una sola lleva a decisiones falsas:
apagar recursos ociosos mejora las dos; mover una carga a una región más barata **puede empeorar**
la huella si esa región tiene una mezcla energética peor, y a la inversa. Regla: si una decisión se
justifica por sostenibilidad, se mide con su propia métrica y se declara el efecto sobre el coste, y
viceversa. **El criterio de huella, factores de emisión y metodología es de
`green-it-standards`**; aquí solo la advertencia de no usar el coste como aproximación de la huella.
El marco FinOps sí tiene `Sustainability` como capacidad del dominio `Optimize Usage & Cost`: úsese
como punto de encaje, no como fuente de metodología de cálculo.

### 6.5 Showback frente a chargeback

| | Showback | Chargeback |
|---|---|---|
| Qué es | Se muestra al equipo su coste; **no se mueve dinero** | El coste se imputa al presupuesto del equipo |
| **Default** | **Sí** | No |
| Cuándo | Siempre, desde el primer día | Solo si se cumplen **las tres**: (a) asignación fiable (§3.2, umbral de no asignado cumplido), (b) el equipo tiene presupuesto propio y capacidad real de decidir, (c) el equipo **puede actuar** sobre lo que se le imputa |
| Riesgo | Que nadie mire | Que se optimice contra la métrica y no contra el negocio: rechazar trabajo útil, evitar redundancia, discutir el reparto en vez de reducir el consumo |

**Regla dura**: imputar a un equipo un coste sobre el que no tiene control (una decisión de
plataforma, un servicio compartido que no eligió) **no es chargeback, es un impuesto** — genera
disputa contable y cero ahorro. Si no se cumplen las tres condiciones, se queda en *showback*.

### 6.6 Métricas de la práctica

Se mide la práctica por lo que cambia decisiones:
- **Cobertura de asignación** (% de gasto con dueño identificable) — el habilitador de todo lo demás.
- **Unidades económicas declaradas** sobre sistemas con gasto relevante (%).
- **Tendencia de cada unidad económica**, por sistema.
- **Tiempo desde la anomalía hasta su causa identificada.**
- **Cobertura y utilización de compromisos** (§3.4).
- **Coste de no producción** como fracción del total.
- **Desviación de la previsión** frente a lo real, y si esa desviación se está reduciendo.

**Prohibido** medir la práctica por el **ahorro absoluto acumulado**: es la métrica que se puede
inventar (basta con inflar el precio de referencia contra el que se compara), no distingue ahorro
real de crecimiento evitado, y premia el recorte de una vez sobre la eficiencia sostenida. Si hay
que reportar ahorro, se reporta **con la línea base, la fecha y el método de cálculo escritos**, y
se marca su caducidad.

**Sobre cifras de la industria — advertencia de método.** El *State of FinOps* de la FinOps
Foundation (edición **2026**, publicada el **19-feb-2026**) es la fuente pública más citada:
**1.192 respondentes**, y titulares como *"98% are managing AI spend"* (frente al 31 % dos años
antes), *"Nine of 10 practitioners are now being asked to manage SaaS"*, *"64% manage licensing"* y
*"48% manage data centers"*, sobre organizaciones que representan más de 83.000 M$ de gasto anual en
nube. **Es una encuesta de autoselección entre practicantes ya afiliados a la comunidad**, y el sitio
público **no documenta el rango de fechas del campo, el marco muestral ni el criterio de limpieza o
deduplicación**; además circula una cifra alternativa de 966 respuestas "deduplicadas" en análisis
de terceros — **discrepancia declarada**. Úsese como **señal de hacia dónde va la práctica, jamás
como base de un caso de negocio ni como *benchmark* comparativo.** Toda cifra de ahorro publicada
por un proveedor de herramientas (del tipo "30-50 % de ahorro") **se descarta**: sin línea base,
muestra ni método, no es un dato.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisar la edición del **FinOps Framework** y la versión de **FOCUS** al menos
  **anualmente** (ambas se han movido en los últimos doce meses); revisar el estado, la licencia y
  el precio de las herramientas de §2.1 **antes de cada renovación** y ante cualquier cambio de
  propiedad.
- **Deprecación**: un panel de coste que nadie ha abierto en un trimestre se retira. Un informe que
  no ha cambiado ninguna decisión en dos trimestres se retira. La práctica de FinOps acumula
  artefactos muertos más rápido que cualquier otra.

Prohibiciones:

- ❌ **Recortar coste rompiendo fiabilidad sin decisión explícita.** Reducir redundancia, retención
  de copias, multi-zona, capacidad de reserva o cobertura de observabilidad **exige ADR firmado por
  quien responde del SLO** y consumo declarado de *error budget* (`sre-practice-standards`). El
  ahorro que se paga con una caída no fue ahorro.
- ❌ **Optimizar sin unidad económica.** Sin denominador no se puede saber si el sistema mejoró; se
  está recortando a ciegas.
- ❌ **Comprometerse a 3 años sobre una arquitectura de 6 meses.** Y en general: firmar un plazo que
  el equipo no puede justificar por escrito (§3.4, regla 4).
- ❌ **Medir el éxito en ahorro absoluto** (§6.6), o comparar el gasto total mes contra mes sin
  normalizar por la unidad de negocio ni por los días del periodo.
- ❌ **Política de etiquetas sin gate.** Publicar la convención y confiar en la disciplina. Si no hay
  gate en IaC y en admisión, la política no existe.
- ❌ **Usar `BilledCost` para unidad económica o reparto** (§3.3): produce escalones falsos.
- ❌ **Construir la capa de análisis contra el esquema propietario** del proveedor pudiendo usar FOCUS.
- ❌ **Chargeback sin las tres condiciones de §6.5.** Imputar coste no controlable es un impuesto.
- ❌ **Automatización que borra recursos** por criterio de coste. Apagar y degradar sí; borrar lo
  autoriza una persona.
- ❌ **Dar permisos de escritura a herramientas de coste**, propias o de terceros.
- ❌ **Perseguir el reparto perfecto del coste compartido** cuando ningún reparto alternativo cambia
  una decisión (§3.2).
- ❌ **Parar despliegues de producción automáticamente** por presupuesto excedido (§6.3).
- ❌ **Presentar una cifra de ahorro sin línea base, fecha y método**, o citar el porcentaje de
  ahorro de un proveedor como dato (§6.6).
- ❌ **Duplicar aquí el criterio de coste de un servicio concreto** que ya vive en `aws-standards`,
  `azure-standards` o `gcp-standards`: dos fuentes de verdad sobre el mismo precio garantizan que
  una esté caducada.
- ❌ **Usar el coste como aproximación de la huella de carbono** (§6.4).

## 8. Verificación web obligatoria

Antes de fijar cualquier cosa de este documento en un proyecto real:

1. **FinOps Framework**: edición vigente en `finops.org/framework`, la definición de FinOps, el
   número de capacidades y los cambios respecto a la edición 2026 (marzo de 2026). Se ha movido en
   2025 y 2026 en años consecutivos: **asumir que ha vuelto a moverse**.
2. **FOCUS**: versión ratificada actual y su fecha en `focus.finops.org/focus-specification/`
   (a ago-2026: **1.4, ratificada el 4-jun-2026**), el changelog del repositorio, y **qué versión
   emite realmente cada proveedor que uses** — van por detrás. Estado del **programa de
   certificación de conformidad** anunciado para 2026.
3. **Herramientas de §2.1**: `LICENSE` **en crudo** (`raw.githubusercontent.com`, no la etiqueta de
   la interfaz de GitHub ni la documentación de terceros) de OpenCost, Infracost (`infracost/cli`
   **y** `infracost/infracost`), y la **página de precios el mismo día**. Comprobar si alguna ha
   cambiado de licencia, de propietario o ha entrado en mantenimiento. Recordatorio: **el feed de
   releases de GitHub no es la fuente de verdad**; contrastar con la web oficial del proyecto.
4. **Kubecost**: su web redirige a `apptio.com` tras la compra por IBM; **los precios de los niveles
   de pago no están publicados** — hay que pedirlos. Verificar los límites vigentes del nivel
   gratuito (a ago-2026: *"Unlimited clusters up to 250 cores"*, *"15-day metric retention"*).
5. **Coste de IA**: la página de la categoría tecnológica `FinOps for AI` del marco y su guía de
   métricas; los precios por token cambian con cada versión de modelo, y **ningún precio de modelo
   se escribe de memoria**. Para lo relativo a Claude/Anthropic, la fuente canónica es la skill
   `claude-api`, no esta.
6. **EU Data Act**: confirmar el texto y las fechas de los artículos 29 y 34 en EUR-Lex (fuente
   primaria) antes de apoyarse en ellos contractualmente, y si la Comisión ha adoptado actos
   delegados sobre el mecanismo de seguimiento previsto en el 29(7).
7. **State of FinOps**: edición vigente y **su metodología publicada** antes de citar cualquier
   porcentaje. Sin metodología, la cifra no se escribe.
8. **Huecos declarados de este documento** (no se rellenaron por falta de fuente con metodología, no
   por olvido):
   - **No hay aquí un objetivo numérico de cobertura de compromisos**: depende del perfil de carga y
     ninguna fuente con metodología publicada justifica un número universal (§3.4).
   - **No hay aquí un porcentaje de referencia del coste de observabilidad sobre el total** ni de
     coste de no producción: no se localizó una fuente con muestra y método. Fija el tuyo con tu
     propia serie histórica y anótalo (§3.6).
   - **El umbral del 5 % de gasto no asignable de §3.2 es un criterio de gobierno propuesto en este
     documento**, no un dato de la industria: está marcado como tal en el texto.
   - **Precios de Kubecost de pago: no publicados** (punto 4).
   - **No hay cifras de ahorro típico de ninguna palanca**: todas las que circulan son de proveedor
     y sin metodología (§6.6).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
