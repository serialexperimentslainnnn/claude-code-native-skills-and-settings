---
name: itsm-itil-standards
description: Use when IT runs as a service with a customer on the other side — writing or reviewing a service catalogue entry with a named service owner, separating request fulfilment from incident from problem records in a ticket tool, defining request categories and a request catalogue, standard pre-approved changes versus a CAB and the change record that satisfies an auditor, change freeze and blackout windows, writing an SLA, OLA or underpinning contract with service hours, response and resolution targets, credits and exclusions, distinguishing a contractual SLA from an engineering SLO, service desk tiering, escalation matrices and follow-the-sun coverage, CMDB and CI relationships, discovery versus manual maintenance, configuration item ownership and drift, known error database and workarounds, ITIL 4 practices and ITIL Version 5, PeopleCert and AXELOS licensing of ITIL material, ISO/IEC 20000-1 certification scope, FitSM, YaSM or VeriSM as license-free alternatives, service reporting and first-contact resolution, or operating ServiceNow, Jira Service Management, Freshservice, GLPI, iTop, Zammad, OTOBO or Znuny.
---

# Estándares de ITSM / ITIL — el contrato de servicio con el negocio

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre la **gestión de servicios de TI como compromiso explícito con un cliente**: qué servicios existen
y quién responde de cada uno, cómo entra el trabajo (petición, incidente, problema, cambio), qué se
promete por escrito (SLA/OLA/contrato de apoyo), qué se registra como evidencia y qué se mide.

Triggers: "catálogo de servicios", "dueño del servicio", "petición de servicio", "request", "incidente
vs. problema", "known error", "workaround", "gestión del cambio", "CAB", "cambio estándar", "ventana de
cambio", "congelación", "RFC", "SLA", "OLA", "underpinning contract", "penalización por SLA", "mesa de
servicio", "L1/L2/L3", "escalado", "CMDB", "CI", "descubrimiento", "ITIL", "ITIL 4", "ITIL v5",
"ISO 20000", "FitSM", "ServiceNow", "Jira Service Management", "GLPI", "iTop", "Zammad", "OTOBO".

**Principio rector**: **ITSM es el contrato de servicio con el negocio, no la burocracia que lo rodea.**
El fallo típico de una implantación de ITSM no es la falta de proceso: es el **proceso que existe para
protegerse en lugar de para entregar** — el comité que aprueba para repartir culpa, el ticket que se
cierra para no incumplir el SLA, la CMDB que se mantiene para el auditor. Test falsable a aplicar a
cualquier proceso propuesto: **nombra la decisión que toma y quién la toma; si no toma ninguna decisión
que cambie el resultado para el cliente, se elimina.**

Corolario operativo: **un proceso sin dueño nombrado no existe** — existe la plantilla.

**No aplica**:
- `incident-management-standards` (**frontera crítica**): la **gestión del incidente técnico en vivo**
  — declaración, severidad, Incident Commander, comunicación de crisis, status page, decisión de
  mitigación, postmortem sin culpa y sus acciones. Aquí, en cambio, **el proceso de servicio que lo
  rodea**: el registro y la categorización del ticket, el SLA contractual que se está consumiendo, el
  escalado **jerárquico** (avisar a quien responde ante el cliente, no a quien arregla), la relación
  con el cliente y la conversión del incidente en problema. Regla de arbitraje: mientras el servicio
  está caído manda `incident-management-standards`; el registro, el compromiso contractual y el
  seguimiento posterior mandan aquí. **Ambas escrituras deben coexistir en el mismo ticket sin
  duplicar el mando.**
- `sre-practice-standards`: **SLI, SLO, error budget, política de quema, guardia y fiabilidad** son
  suyos. Aquí el **SLA contractual**. **Un SLA no es un SLO** (§3): confundirlos produce una de dos
  patologías — comprometer con el cliente el objetivo interno (compromisos imposibles) o derivar el
  objetivo interno del contrato (objetivos sin sentido de ingeniería). Las métricas DORA son suyas.
- `cicd-standards`: el **despliegue automatizado y sus gates** (pruebas, aprobaciones en pipeline,
  firma, promoción de artefacto). Aquí el **registro del cambio y su evidencia**: qué se desplegó,
  quién lo autorizó, contra qué CI y con qué plan de reversión.
- `grc-compliance-standards`: el **marco normativo y la evidencia de auditoría** (ISO 27001, ENS,
  DORA-UE, NIS2), el mapeo de controles y la aceptación formal de riesgo. Aquí solo el proceso de
  servicio que **genera** esa evidencia.
- `bcdr-standards`: continuidad, BIA, RTO/RPO y activación de DR. Un incidente que escala a desastre
  sale de este proceso.
- `observability-standards`: la telemetría con la que se detecta y se diagnostica.
- `onprem-standards`, `homelab-standards`: la plataforma sobre la que corre el servicio.
- `knowledge-management-standards`: la **base de conocimiento** — autoría,
  revisión, caducidad y curación de artículos. Aquí solo su **enganche al proceso**: el KEDB y el
  artículo obligatorio en el cierre de un problema.
- `platform-engineering-standards`: el portal interno de desarrollador y el
  catálogo de *software templates*. La frontera es el cliente: **plataforma sirve a equipos internos
  con autoservicio; ITSM sirve a un cliente con un compromiso**. El portal no sustituye al catálogo
  de servicios ni al revés.
- `enterprise-architecture-standards`: el **inventario de aplicaciones y
  capacidades**. Se cruza con la CMDB y el catálogo de servicios: el inventario de aplicaciones es la
  vista de arquitectura (ciclo de vida, capacidad de negocio, *fit*), la CMDB es la vista operativa
  (qué está desplegado y de qué depende). **Un mismo objeto, dos vistas: si se mantienen dos fuentes
  de verdad sin dueño único, ambas se degradan** — nombrar cuál es autoritativa por atributo.
- `cmdb-inventory-standards`: **el modelo de datos del CI, su identificador estable, el
  descubrimiento, la reconciliación entre fuentes y la frescura del registro son suyos**. Aquí el
  proceso que lo consume y la decisión de servicio que se toma con él.
- `project-management-standards`: la **entrega** del servicio nuevo o cambiado. Recíproca:
  **el proyecto entrega, el servicio opera**; el traspaso es un artefacto con criterios de aceptación
  (§3) y **un proyecto que entrega algo que nadie puede operar no ha terminado**.

## 2. Decisiones por defecto

> Verificar por web el estado de marcos, ediciones y precios antes de fijarlos en un proyecto real (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Marco de referencia | **FitSM** como esqueleto citable (libre, sin licencia por usuario) + vocabulario ITIL donde el cliente lo exija | ITIL 4 / ITIL (Version 5) si el contrato o el cliente lo imponen; ISO/IEC 20000-1 si se busca certificación |
| Material normativo en documentos internos | **Solo FitSM o ISO** citados con referencia; **nunca pegar texto de ITIL** | — (restricción legal, no de gusto) |
| Certificación formal | **No, salvo requisito de cliente o licitación** | ISO/IEC 20000-1 cuando lo exige un pliego |
| Tipos de registro | **Cuatro tipos separados y no fusionables**: petición, incidente, problema, cambio | — |
| Aprobación de cambio | **Cambio estándar preaprobado + revisión por pares en el PR** como ruta normal | CAB **solo** para cambio mayor/no estándar |
| Frecuencia de CAB | **Bajo demanda** (convocado por un cambio que lo requiere) | Cadencia fija solo si el volumen de cambio mayor lo justifica; nunca semanal por defecto |
| Compromiso publicado al cliente | **SLA con umbral peor que el SLO interno**, con margen explícito | — |
| CMDB | **Poblada por descubrimiento automático**; alcance mínimo viable | Registro manual solo para atributos que ninguna herramienta puede descubrir (dueño, criticidad, contrato) |
| Estructura de la mesa | **Enjambre (swarming) sobre un pool con la competencia**, con un único punto de entrada | L1/L2/L3 clásico solo con volumen alto y trabajo genuinamente repetitivo en L1 |
| Herramienta | La **que ya se usa**, si cubre los cuatro tipos de registro; en verde: GLPI o iTop autoalojado (GPL/AGPL) | ServiceNow / Jira Service Management / Freshservice cuando lo impone el tamaño o la integración |
| Métrica de cabecera | **Tiempo hasta restauración percibida por el usuario** y **% de peticiones resueltas sin intervención humana** | — |

**Estado real de los marcos (verificado ago-2026, re-verificar §8)**:
- **ITIL es propiedad comercial**. La marca la posee hoy **PeopleCert**, que **completó la adquisición
  de AXELOS Limited en julio de 2021** (anuncio del acuerdo el 21-jun-2021). Antes, AXELOS era una
  *joint venture* del Cabinet Office británico y Capita. Consecuencia práctica: **el material de ITIL
  es de pago y su texto no se puede reproducir en documentación interna ni en un repositorio**; la
  página oficial de ITIL Foundation (Version 5) de PeopleCert lista paquetes de examen **de 483 € a
  1213 € (IVA incl.)** en el momento de la verificación. Un proceso interno **se escribe con
  vocabulario propio o con una fuente libre**, no copiando ITIL.
- **Versión vigente**: PeopleCert publica **ITIL (Version 5)**; su página de anuncio dice literalmente
  *"ITIL 4 remains available for those who wish to continue their current certification journey"* y
  *"Your existing ITIL knowledge and certifications continue to hold their value as ITIL evolves"*.
  **Discrepancia declarada**: la fecha exacta de lanzamiento (**12-feb-2026** para Foundation) y el
  calendario de módulos aparecen en **proveedores de formación, no en la página oficial**, que no
  muestra fecha; tratar la fecha como no confirmada hasta verla en peoplecert.org (§8). **ITIL 4
  define 34 prácticas** (14 generales, 17 de servicio, 3 técnicas); la reorganización en Version 5 hay
  que verificarla contra la fuente oficial antes de citarla — **no se escribe de memoria**.
- **ISO/IEC 20000-1:2018** (3.ª edición) sigue vigente, con **Amd 1:2024 "Climate action changes"**,
  cambio menor sobre contexto y partes interesadas. Es **certificable** y **de pago** (la enmienda se
  distribuye sin coste; la norma base no).
- **FitSM**: libre y citable. Mantenido por el grupo de trabajo FitSM de **ITEMO e.V.**; núcleo
  FitSM-0/1/2/3 (+ FitSM-6 de madurez), versión **3.0** (edición 2021, alineada con ISO/IEC 20000:2018).
  **Discrepancia declarada sobre la licencia**: fuentes de terceros dicen CC BY 4.0, pero el PDF
  oficial de FitSM-1 V3.0 enlaza **Creative Commons Attribution-NoDerivatives 4.0 (CC BY-ND 4.0)**.
  **ND importa**: se puede redistribuir y citar íntegro, **no adaptar ni publicar una versión
  modificada**. Verificar la licencia impresa en el PDF concreto que se descargue antes de derivar
  material.
- **YaSM**: modelo comercial de plantillas (19 procesos) con wiki público gratuito; útil como mapa,
  **no es un estándar**. **VeriSM**: sin señales de desarrollo reciente más allá de formación; **no es
  un estándar y no certifica organizaciones**. Ninguno de los dos se usa como base normativa.

**Regla de citabilidad**: en un documento interno, en un repositorio o en una respuesta a un pliego,
**cita FitSM o ISO/IEC 20000-1**. ITIL se menciona como vocabulario común, nunca se transcribe.

## 3. Estructura y convenciones

### Servicio, sistema y componente

Tres niveles, tres dueños, tres lenguajes. Confundirlos es la causa raíz de los catálogos inútiles.

| Nivel | Definición operativa | Se nombra en | Dueño |
|---|---|---|---|
| **Servicio** | Lo que el cliente compra o consume y puede describir sin saber de TI ("facturación", "correo") | Catálogo de servicios, SLA | **Service owner** (persona, no equipo) |
| **Sistema** | Conjunto desplegable que implementa parte de un servicio (una app, un clúster) | Inventario de aplicaciones, CMDB | Equipo propietario |
| **Componente / CI** | Unidad gestionable con ciclo de vida propio (VM, base de datos, certificado, contrato) | CMDB | Equipo o proveedor |

**Regla**: un SLA se firma **sobre un servicio**, jamás sobre un componente. Prometer disponibilidad de
una VM no significa nada para el cliente y genera el peor de los resultados: se cumple el SLA mientras
el servicio está caído.

### Catálogo de servicios (artefacto obligatorio)

Fichero versionado en Git (YAML/Markdown), no una tabla en la wiki. Campos **mínimos y obligatorios**
por entrada — una entrada a la que le falte cualquiera de ellos **no se publica**:

```yaml
- id: svc-facturacion
  nombre: Facturación a clientes
  descripcion_negocio: Emisión y envío de facturas mensuales   # sin jerga de TI
  service_owner: nombre.apellido                                # persona, no equipo
  criticidad: 1                                                 # tier 1..4, deriva de BIA (bcdr)
  horario_servicio: L-V 07:00-21:00 Europe/Madrid
  sla: sla-facturacion-v3.md                                    # o "sin SLA formal", explícito
  soporta_proceso_negocio: [cierre_mensual, cobro]
  sistemas: [billing-api, billing-batch]                        # enlace a CMDB
  dependencias_externas: [pasarela-pagos-x]                     # con contrato de apoyo
  peticiones_publicadas: [alta-usuario, reemision-factura]
  revision: 2026-06-01                                          # caduca a los 12 meses
```

**Revisión anual obligatoria con caducidad dura**: una entrada sin revisar en 12 meses se marca
`OBSOLETO` automáticamente y deja de dar cobertura contractual. Un catálogo sin caducidad se convierte
en ficción en dos años.

### Los cuatro tipos de registro (definición operativa, no doctrinal)

| Tipo | Objetivo | Termina cuando | Métrica propia |
|---|---|---|---|
| **Petición** | Entregar **trabajo previsto** ya autorizado (alta de usuario, cuota, acceso) | El usuario tiene lo que pidió | % automatizado, tiempo de entrega |
| **Incidente** | **Restaurar el servicio** lo antes posible | El servicio funciona (aunque sea con *workaround*) | Tiempo hasta restauración |
| **Problema** | **Eliminar la causa** de uno o varios incidentes | La causa está eliminada **o** aceptada formalmente como riesgo | Incidentes evitados, edad del problema |
| **Cambio** | Modificar el entorno con riesgo controlado y evidencia | Está desplegado y verificado, o revertido | Tasa de fallo del cambio, lead time |

**Por qué mezclarlos rompe las métricas** — es aritmético, no filosófico:
- Una petición metida como incidente **infla el volumen de incidentes** y hunde el tiempo medio: se
  celebra una mejora de MTTR que solo significa que se han dado más altas de usuario.
- Un incidente cerrado con *workaround* **sin abrir problema** hace desaparecer el trabajo pendiente:
  el mismo fallo se paga N veces y no aparece en ningún indicador.
- Un problema tratado como incidente permanente mantiene un ticket abierto meses y **destruye
  cualquier medida de tiempo de resolución**.

**Regla dura**: un incidente **nunca** se convierte en problema; se **cierra** al restaurar y se **crea**
un problema vinculado. Cerrar el incidente no es ocultar el trabajo: el problema lo hereda.

**Regla de auto-servicio**: toda petición que se repita **>10 veces al mes** y no requiera juicio humano
se automatiza o se elimina del catálogo. Una petición manual recurrente es deuda operativa medida.

### Gestión del cambio: la evidencia importa, el comité no

**Dato verificado y su consecuencia.** DORA (Google) documenta en *Streamlining change approval*
(actualizado 30-oct-2025) que las aprobaciones externas pesadas **no aportan estabilidad**:

> "DORA's research shows that these approaches have a negative impact on software delivery performance."

> "Further, no evidence was found to support the hypothesis that a more formal, external review process
> was associated with lower change fail rates."

Y la alternativa que la misma fuente prescribe para el requisito de segregación de funciones:

> "Use peer review to meet the goal of segregation of duties, with reviews, comments, and approvals
> captured in the team's development platform as part of the development process."

Origen del hallazgo: **State of DevOps Report 2019** (citado por la propia página). **Cautela declarada**:
la formulación fuerte que circula por blogs — *"peor que no tener ningún proceso de aprobación"*,
*"2,6 veces más probable ser* low performer*"* — **no aparece en la página de dora.dev verificada**;
proviene de la síntesis en el libro *Accelerate* y del informe 2019. **Cítese solo lo verbatim de
arriba**; si se necesita la cifra, sacarla del informe original y citarla con su año y muestra, nunca
de un blog.

**Consecuencia práctica, escrita como política**:

1. **Cambio estándar** (por defecto): riesgo bajo, procedimiento conocido, reversible y con pipeline.
   **Preaprobado** por el service owner mediante una **plantilla de cambio estándar** con criterios de
   elegibilidad explícitos. No pasa por comité. La autorización es **la revisión por pares del PR**.
2. **Cambio normal**: no encaja en ninguna plantilla estándar. Aprueba el service owner + el dueño
   técnico. Comité **solo** si toca varios servicios de tier 1 o hay ventana negociada con el cliente.
3. **Cambio de emergencia**: se ejecuta primero, se registra **antes de 24 h** con la misma evidencia.
   Un proceso de emergencia que se use en >10 % de los cambios significa que el proceso normal está
   roto: se corrige el normal, no se restringe la emergencia.

**Reconciliación con DevOps/SRE — el nudo real del dominio.** El auditor no pide un comité: pide
demostrar **autorización, segregación de funciones, trazabilidad y capacidad de reversión**. Todo eso lo
produce el pipeline mejor que una reunión. Evidencia mínima que satisface a un auditor **sin frenar la
entrega**, generada automáticamente y enlazada en el registro de cambio:

- **Autorización**: PR aprobado por alguien distinto del autor (segregación de funciones), con
  identidad verificable — protección de rama que lo imponga, no una norma escrita (`git-workflow-standards`).
- **Trazabilidad**: commit → artefacto firmado → despliegue, con digest inmutable (`cicd-standards`).
- **Prueba de control**: resultado de los gates de CI (tests, SCA, IaC scan) adjunto al registro.
- **Reversión**: identificador de la versión anterior y método de vuelta atrás, probado.
- **Registro**: el ticket de cambio **se crea desde el pipeline por API**, no a mano. Si un humano
  teclea el registro de cambio, se llenará tarde, mal o nunca.

**Ventanas y congelaciones**: una congelación es una decisión de negocio con fecha de fin y dueño, y
**debe declarar qué se sigue permitiendo** (siempre: parches de seguridad críticos y reversiones). Una
congelación indefinida acumula un lote grande y **empeora** el riesgo que pretendía evitar.

### Acuerdos: SLA ≠ OLA ≠ contrato de apoyo ≠ SLO

| Objeto | Entre | Dueño | Naturaleza | Consecuencia de incumplir |
|---|---|---|---|---|
| **SLA** | Proveedor ↔ **cliente** | Gestor del servicio / comercial | **Contractual** | Penalización, crédito, escalado ejecutivo |
| **OLA** | Equipos **internos** | Service owner | Interno, vinculante | Escalado interno; **nunca** se muestra al cliente |
| **Contrato de apoyo (UC)** | Proveedor ↔ **tercero** | Gestor de proveedor | Contractual con el tercero | Reclamación al proveedor |
| **SLO** | **Ingeniería consigo misma** | Equipo dueño del servicio | Objetivo técnico con error budget | Congelar features, priorizar fiabilidad |

**Un SLA no es un SLO.** Reglas duras:
- El **SLA se publica peor que el SLO** con margen explícito (p. ej. SLO 99,9 % → SLA 99,5 %). El margen
  es el colchón para que un mal trimestre no sea un incumplimiento contractual.
- **Prohibido derivar el SLO del SLA**: el objetivo de ingeniería nace del impacto en el usuario, no de
  lo que se firmó. Un SLO igual al SLA convierte cada consumo normal de error budget en un riesgo legal.
- La cadena tiene que cerrar: **SLA ≤ mínimo(OLAs) ≤ mínimo(UCs)**. Prometer 99,95 % apoyándose en un
  proveedor con 99,9 % contractual es un incumplimiento programado. **Comprobarlo por escrito antes de
  firmar** — es aritmética, no negociación.
- Todo SLA declara: **horario de servicio, exclusiones (mantenimiento planificado, causas del cliente,
  fuerza mayor), método de medición y quién mide**. Un SLA sin método de medición acordado se
  disputará en el primer incidente.
- **Métrica de disponibilidad medida desde el usuario** (petición correcta / petición total con
  sondeo externo), no desde el ping al servidor.

### Mesa de servicio y escalado

- **Un único punto de entrada** por canal publicado; el "canal informal" (mensaje directo al ingeniero)
  no existe como vía de trabajo: se reconduce siempre a un registro.
- **El escalado por niveles es una fuente de latencia** y hay que tratarlo como tal. Cada salto L1→L2→L3
  añade una cola, una recontextualización y una pérdida de información. Regla: **si el 30 % o más de los
  tickets de una categoría acaban en L3, esa categoría no debería pasar por L1** — se enruta directa.
- **Escalado jerárquico ≠ escalado funcional**. El funcional busca competencia técnica; el jerárquico
  busca autoridad para decidir (gastar, parar, comunicar al cliente). **Se disparan por criterios
  distintos y se documentan por separado.**
- **Umbral temporal explícito por severidad y por categoría**, automático: el escalado no depende de que
  alguien se acuerde. Si el sistema no escala solo, el proceso es la buena voluntad del técnico.
- **Turno / follow-the-sun**: el traspaso es un artefacto escrito (estado, hipótesis descartadas, próximo
  paso, quién es el dueño ahora), no una conversación.

### CMDB: qué justifica su coste

Una CMDB **solo se justifica si responde preguntas que se hacen de verdad y con frecuencia**. Las cuatro
canónicas: *¿a qué servicio afecta este componente?*, *¿de qué depende este servicio?*, *¿quién responde
de esto?*, *¿qué cambió antes del fallo?*. **Si no se van a hacer, no se construye una CMDB.**

- **Descubrimiento automático como principio, mantenimiento manual como excepción justificada**. La
  razón de que la mayoría de las CMDB se degrade no es la pereza: es que el entorno cambia más rápido
  que el ritmo humano de actualización, y una CMDB con un 20 % de datos falsos **se deja de consultar**,
  tras lo cual se degrada al 100 % sin que nadie lo note.
- **Alcance mínimo viable**: solo CI cuya relación con un servicio se necesita para decidir. Modelar
  cada paquete instalado es garantía de abandono.
- **Atributos manuales permitidos** (los que ninguna herramienta descubre): dueño, criticidad, servicio
  al que pertenece, contrato, fecha de fin de soporte. Todo lo demás, descubierto.
- **Métrica de salud obligatoria y publicada**: % de CI con descubrimiento en las últimas 24 h, % con
  dueño válido (persona existente), y **nº de consultas reales al mes**. La tercera es la que decide si
  la CMDB sigue viva: **una CMDB que nadie consulta se apaga, no se mejora**.
- Se **reconcilia contra el inventario de aplicaciones** de arquitectura declarando fuente autoritativa
  por atributo; dos inventarios sin reconciliación producen dos mentiras.

### Traspaso a operación (frontera con proyecto)

Artefacto de aceptación firmado por el service owner **antes** del cierre del proyecto. Sin estos ítems,
**el servicio no entra en producción soportada** (y el proyecto no está terminado):

1. Entrada en el catálogo de servicios publicada, con dueño y criticidad.
2. SLA/OLA acordados, o declaración explícita de "sin SLA formal" firmada por el negocio.
3. Runbooks de las tres operaciones más frecuentes + procedimiento de reversión probado.
4. Alertas accionables con destino de guardia definido (`observability-standards`).
5. Backup con **restauración probada** y fecha de la prueba (`backup-recovery-standards`).
6. Peticiones publicadas en el catálogo y categorías de ticket creadas en la herramienta.
7. CI en la CMDB con descubrimiento funcionando.
8. Formación registrada de quien va a soportarlo, y periodo de *hypercare* con fecha de fin.

## 4. Calidad del proceso y verificación

El equivalente a los tests aquí son **controles automáticos sobre los datos del proceso**. Se ejecutan
programados y su fallo abre trabajo, no un informe.

| Control | Falla si | Acción |
|---|---|---|
| Entradas de catálogo caducadas | revisión > 12 meses | Marcar `OBSOLETO`, avisar al owner |
| Servicios sin dueño persona | `service_owner` vacío o inexistente en el directorio | Bloquear publicación |
| Cadena de acuerdos | SLA > mín(OLA) o > mín(UC) | Bloquear firma |
| CI huérfanos | CI sin servicio asociado | Purgar o asignar en 30 días |
| CI obsoletos | sin descubrimiento > 30 días | Marcar `stale`, excluir de informes |
| Reapertura de tickets | > 5 % de los cerrados | Auditar criterio de cierre (síntoma de cierre para cumplir SLA) |
| Incidentes recurrentes sin problema | ≥ 3 incidentes de la misma categoría en 30 días sin problema abierto | Abrir problema de oficio |
| Cambios de emergencia | > 10 % del total | Revisar el proceso de cambio normal |
| Cambios sin evidencia enlazada | registro sin PR, sin artefacto o sin plan de reversión | Marcar no conforme |

**Métricas de servicio y las que se manipulan solas.** Toda métrica que un humano pueda mejorar sin
mejorar el servicio se degrada al usarse como objetivo:
- ❌ **Tiempo de cierre de ticket** como objetivo: se optimiza cerrando antes, no resolviendo antes.
  Su síntoma es la tasa de reapertura; medir siempre **cierre y reapertura juntos, o ninguno**.
- ❌ **Tickets cerrados por técnico**: premia trocear el trabajo y castiga automatizar.
- ❌ **Cumplimiento de SLA en verde permanente**: mide el margen del contrato, no la experiencia.
- ✅ **Tiempo hasta restauración percibida por el usuario**, **% de peticiones sin intervención humana**,
  **incidentes repetidos por causa conocida**, **edad de los problemas abiertos**, **coste por petición**.
- **CSAT/encuesta**: solo con tasa de respuesta publicada junto al valor. Un CSAT de 4,8 con 4 % de
  respuesta no es un dato, es un ruido.

**Revisión de servicio**: reunión trimestral con el cliente sobre datos publicados de antemano. Si la
revisión es la primera vez que el cliente ve los números, la relación ya está rota.

## 5. Seguridad del proceso

- **La herramienta de ITSM es un objetivo de alto valor**: contiene el mapa de la infraestructura, la
  cadena de aprobación y a menudo credenciales pegadas en tickets. Trátese como sistema tier 1: SSO con
  MFA, RBAC por rol de proceso, y registro de auditoría inalterable de aprobaciones y cambios de estado.
- **Prohibido pegar secretos en tickets o en la CMDB**. Añadir escaneo de secretos sobre los campos de
  texto de los tickets, no solo sobre el repositorio (`secrets-management-standards`). Un secreto en un
  ticket es un secreto compartido con toda la mesa de servicio y con su histórico de exportaciones.
- **La mesa de servicio es el vector de ingeniería social por excelencia** (restablecimiento de
  contraseña, alta de MFA, cambio de dispositivo). Procedimiento de verificación de identidad
  **escrito, obligatorio y sin excepción por urgencia o jerarquía**; los reseteos de credencial
  privilegiada exigen verificación fuera de banda (`identity-access-management-standards`).
- **La automatización del cumplimiento de peticiones necesita mínimo privilegio**: la cuenta que crea
  usuarios no puede además poder crear administradores. Una petición automatizada con permisos
  excesivos es una escalada de privilegios con formulario.
- **Retención y datos personales**: los tickets contienen datos personales y a veces categorías
  especiales. Política de retención con borrado efectivo, y adjuntos incluidos
  (`privacy-engineering-standards`). Los adjuntos son el punto ciego habitual.
- **Portal externo**: si el cliente abre tickets, el portal es superficie expuesta con autenticación,
  aislamiento multi-tenant y control de acceso a adjuntos. Un fallo de IDOR en el portal expone la
  operación completa del cliente vecino.

## 6. Operación y capacidad del propio proceso

- **Dimensionado por demanda medida, no por intuición**: volumen por categoría × tiempo medio de manejo,
  con margen para picos conocidos (cierre de mes, inicio de curso, campaña). Publicar el supuesto.
- **Coste por contacto como dato de gestión**: sin él no se puede justificar automatizar ni argumentar
  el autoservicio. Es la cifra que convierte una discusión de opinión en una decisión.
- **Cola de trabajo con WIP limitado**: una mesa con 40 tickets "en curso" por técnico no tiene 40 en
  curso, tiene 39 parados y un informe optimista.
- **El proceso también se degrada**: revisión semestral de cada proceso con el criterio de §1 — qué
  decisión toma, quién la toma, qué pasaría si se elimina. Lo que no sobrevive a esa pregunta se retira.
- **Integración herramienta ↔ pipeline por API** en ambos sentidos, con reintentos idempotentes: crear
  el registro de cambio desde CI y cerrar el ticket desde el despliegue. Si el enlace se hace a mano,
  se dejará de hacer.
- **La herramienta de ITSM no puede depender del servicio que gestiona**: si el ticketing cae con el
  SSO, no hay cómo gestionar la caída del SSO. Ruta de escalado alternativa documentada y probada.

## 7. Sostenibilidad y prohibiciones

**Cadencia**: catálogo revisado anualmente por entrada; acuerdos revisados en cada renovación
contractual y tras cualquier cambio de arquitectura que altere las dependencias; procesos revisados
semestralmente; plantillas de cambio estándar revisadas tras cada cambio fallido de ese tipo.

**Deprecación**: retirar un servicio es un proyecto con su propio traspaso (comunicación al cliente,
migración de datos, fin de soporte, borrado de CI y entrada de catálogo). Un servicio "apagado" que
sigue en el catálogo genera tickets y expectativas contractuales durante años.

PROHIBIDO:
- ❌ **Proceso sin dueño nombrado** (persona, no equipo ni comité). Sin dueño no hay proceso, hay documento.
- ❌ **CAB semanal fijo aprobando cambios de bajo riesgo**. Contradice la evidencia publicada (§3),
  añade latencia, agranda los lotes y no reduce la tasa de fallo. Cambio de bajo riesgo → estándar
  preaprobado + revisión por pares.
- ❌ **Aprobador que no puede rechazar de facto** (comité que aprueba el 100 %): es un sello, y un sello
  es latencia disfrazada de control. O toma decisiones o se elimina.
- ❌ **CMDB que nadie consulta**. Se apaga. Mantener datos que no se leen es coste puro y falsa seguridad.
- ❌ **Medir el rendimiento por tickets cerrados** o por tiempo de cierre aislado. Premia trocear y
  cerrar en falso, castiga automatizar.
- ❌ **Cerrar un incidente sin abrir problema cuando se restauró con *workaround***.
- ❌ **Registrar peticiones como incidentes** (o al revés) para cuadrar un indicador.
- ❌ **SLA sobre un componente** en lugar de sobre un servicio.
- ❌ **SLA igual o más exigente que el SLO interno**; y **derivar el SLO del SLA**.
- ❌ **Firmar un SLA más exigente que el contrato de apoyo del proveedor** del que se depende.
- ❌ **Copiar texto de ITIL en documentación interna o en un repositorio**: es material propietario de
  PeopleCert. Se cita FitSM o ISO/IEC 20000-1.
- ❌ **Congelación de cambios indefinida o sin dueño**, o que bloquee parches críticos y reversiones.
- ❌ **Vía informal de trabajo** (petición por mensaje directo que no genera registro): destruye la
  medición, el dimensionado y la trazabilidad, y concentra el conocimiento en una persona.
- ❌ **Secretos, credenciales o volcados de datos personales en tickets, comentarios o adjuntos**.
- ❌ **Comprar una herramienta para arreglar un proceso sin dueño**: se obtiene el mismo desorden, con
  factura anual y un proyecto de migración.
- ❌ **Certificarse en ISO/IEC 20000 sin necesidad de negocio**: coste recurrente y proceso de papel.

## 8. Verificación web obligatoria

Antes de fijar cualquiera de estos puntos en un proyecto real:

1. **ITIL**: versión vigente y calendario real de ITIL (Version 5) **en peoplecert.org** — la fecha
   12-feb-2026 procede de proveedores de formación y **no está confirmada en la página oficial**
   (discrepancia declarada en §2). Verificar también la estructura de prácticas de Version 5 frente a
   las 34 de ITIL 4, y la vigencia/caducidad de las certificaciones ITIL 4.
2. **Propiedad y licencia de ITIL**: PeopleCert completó la compra de AXELOS en jul-2021 — comprobar que
   no ha vuelto a cambiar de manos y revisar los términos de uso de marca y material antes de citarlo.
3. **ISO/IEC 20000**: si -1:2018 sigue siendo la edición vigente o hay 4.ª edición en curso; estado de
   Amd 1:2024 y de las partes -2, -3, -6 y -10; precio y adopción nacional (UNE/BS).
4. **FitSM**: versión actual (¿sigue V3.0?) y **licencia exacta impresa en el PDF** — CC BY-ND 4.0
   según el PDF oficial de FitSM-1 V3.0, CC BY 4.0 según terceros. **ND prohíbe obras derivadas**:
   confirmarlo antes de adaptar el texto.
5. **VeriSM y YaSM**: comprobar si siguen mantenidos antes de mencionarlos siquiera como alternativa.
6. **Evidencia sobre CAB**: releer `dora.dev/capabilities/streamlining-change-approval/` (última
   actualización vista: 30-oct-2025) y el informe DORA/State of DevOps más reciente. **Citar verbatim**;
   las formulaciones fuertes que circulan por blogs ("2,6×", "peor que no tener proceso") **no están en
   esa página**: si se usan, sacarlas del informe original con año y muestra.
7. **Herramientas**: estado, versión y modelo de precio actuales de ServiceNow (por *fulfiller*, por
   módulo, sin tarifa pública), Jira Service Management (por agente; Atlassian ha reorganizado su
   oferta en *Service Collection* y está retirando Data Center — verificar fechas y precios en
   atlassian.com), Freshservice (por agente, con IA como *add-on* en planes bajos). Las cifras de
   ServiceNow y Freshservice que circulan proceden de blogs de terceros: **no se citan como precio**,
   solo el modelo de licenciamiento. Para las de código abierto (GLPI, iTop, Zammad, OTOBO, Znuny),
   **leer el `LICENSE` en crudo del repositorio** y comprobar qué queda fuera del núcleo libre
   (plugins certificados, ediciones "Network"/enterprise).
8. **Marco normativo aplicable** (DORA-UE, NIS2, ENS) por si impone requisitos de gestión de cambio,
   registro de incidentes o notificación con plazos — cruzar con `grc-compliance-standards`.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
