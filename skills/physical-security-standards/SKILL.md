---
name: physical-security-standards
description: Physical security as it applies to IT assets — the controls that matter once someone can touch the hardware. Use when designing or auditing badge and biometric access control with antipassback and escort rules, handling tailgating as the failure that actually happens, managing master keys and key custody, specifying CCTV coverage, retention and its legal basis as personal data, intrusion detection and alarm response, deciding who else can reach your cage or your neighbours' racks in a colocation facility, sanitizing or destroying storage media under NIST SP 800-88 Clear/Purge/Destroy with degaussing, cryptographic erase or shredding, demanding and checking a certificate of destruction with serial numbers, responding to a lost or stolen laptop, phone or backup tape, closing off exposed USB ports, serial consoles, debug headers and live network sockets in meeting rooms and shared areas with 802.1X as a compensating control, governing visitors, cleaners, contractors and maintenance technicians, defending against in-person social engineering and pretexting, applying ISO/IEC 27001:2022 Annex A physical controls 7.1-7.14, or judging what full-disk encryption and measured boot really compensate for when an attacker has unsupervised physical access to a machine.
---

# Estándares de seguridad física de activos de TI

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **la protección física de lo que guarda o procesa información**: control de acceso a
espacios y racks, llaves, videovigilancia, detección de intrusión, custodia y destrucción de
soportes, dispositivos perdidos o robados, puertos y consolas accesibles, gestión de visitantes y
de personal externo, ingeniería social presencial, y el modelo de amenaza que decide qué compensa
el cifrado y qué no.

Triggers: "control de acceso", "tarjeta de proximidad", "lector biométrico", "antipassback",
"esclusa", "tailgating", "colarse detrás", "llave maestra", "custodia de llaves", "CCTV",
"videovigilancia", "retención de grabaciones", "alarma de intrusión", "detector volumétrico",
"jaula en el CPD", "colocation", "quién más entra en mi pasillo", "borrado seguro", "degaussing",
"destrucción de discos", "certificado de destrucción", "NIST 800-88", "DIN 66399", "NAID AAA",
"portátil robado", "cinta de backup perdida", "puerto USB", "consola serie", "JTAG", "puerto de
red en la sala de reuniones", "802.1X", "registro de visitas", "acompañamiento", "técnico de
mantenimiento", "suplantación presencial", "acceso físico no supervisado", "evil maid",
"ISO 27001 A.7".

**Principio rector**: **quien tiene acceso físico prolongado y sin supervisión a un equipo acaba
comprometiéndolo.** No es una frase de efecto: es el supuesto de diseño. De ahí lo que ordena todo
el documento:

1. **El cifrado en reposo y el arranque medido son controles compensatorios, no sustitutos.**
   Reducen el daño de un acceso físico; no lo impiden. Un portátil cifrado y apagado es un ladrillo;
   el mismo portátil suspendido, con sesión abierta o con la clave desprotegida, no.
2. **El fallo real no es técnico, es social.** Ningún control de acceso serio se derrota
   electrónicamente: se derrota entrando detrás de alguien con las manos ocupadas. El *tailgating*
   es el vector dominante y la formación es el control, no el torno (§3.1).
3. **La seguridad física es la única capa que, al caer, deja sin efecto a todas las demás**
   simultáneamente: consola, disco, red, y credenciales en memoria.
4. **Un control sin evidencia no existe.** Un registro de accesos que nadie revisa, una cámara que
   graba en un disco lleno y un certificado de destrucción sin números de serie son teatro
   documentado.

**Postura defensiva y autorizada.** Este documento describe **controles, evidencia y gobierno**. No
contiene técnicas de apertura de cerraduras, clonado de credenciales, elusión de lectores ni
guiones de suplantación. Cualquier prueba de intrusión física requiere **alcance y autorización por
escrito, con carta de autorización en mano**, y es territorio de `offensive-security-standards`.

**No aplica**: ver `datacenter-facilities-standards` (**Ola 7, hermana; puede estar escribiéndose
ahora — citarla, no editarla**: **la planta física es suya, sin excepción** — energía desde la
acometida, SAI, grupo electrógeno, PDU, refrigeración, pasillo caliente/frío, densidad por rack,
suelo técnico, cableado estructurado y **protección contra incendios**, más Tier/EN 50600 como
clasificación del sitio. **Aquí, la parte de seguridad**: quién entra, cómo se demuestra, qué se
graba, qué pasa con el soporte y qué puerto queda expuesto. Regla de arbitraje: *si el riesgo es
que se caiga o se queme, es suya; si el riesgo es que alguien se lo lleve, lo abra o lo enchufe,
es de aquí*), `server-hardware-standards` (**el servidor y su interior**: chasis, BMC y su red de
gestión, firmware, garantía, RAID/HBA; aquí solo el hecho de que quien alcanza el chasis alcanza
esos interfaces), `endpoint-security-standards` (**el puesto como control lógico**: EDR, control de
aplicaciones, **postura de cifrado de disco, arranque seguro y medido, atestación y custodia de la
clave de recuperación**; aquí el robo o la pérdida como evento físico y qué compensa ese cifrado),
`privacy-engineering-standards` (**el dato personal como ingeniería**: base legal, minimización,
retención implementada, derechos del interesado; aquí, la videovigilancia y el registro de accesos
**como tratamientos que hay que respetar**, sin invadir su terreno — si la pregunta es cómo se
implementa el borrado o quién es el responsable del tratamiento, es suya),
`grc-compliance-standards` (**el marco y la evidencia de auditoría**: ISO 27001, SoA, ENS, registro
de riesgos; aquí el control técnico y su operación), `identity-access-management-standards`
(identidad lógica, MFA, ciclo de vida de la cuenta — **la convergencia entre la credencial física
y la lógica se decide con ellos**), `identity-threat-detection-standards` (**Ola 7, hermana**: el
ataque a la identidad digital y su detección), `windows-server-ad-standards` y
`linux-hardening-standards` (baseline del SO y de la consola), `networking-standards` y
`routing-switching-standards` (**802.1X, port-security y VLAN de invitados son controles de red
suyos**; aquí solo por qué la toma de red accesible los exige), `incident-response-forensics-standards`
(la investigación cuando el acceso físico ya ha ocurrido, y **la cadena de custodia de la evidencia
—que es el mismo concepto que la del soporte destruido, aplicado a otra cosa**),
`incident-management-standards` (gobierno del incidente), `backup-recovery-standards` (la copia y
su restauración; aquí la custodia física y el transporte del soporte), `bcdr-standards` (pérdida
del sitio como escenario de continuidad), `ot-ics-security-standards` (planta industrial, donde el
acceso físico se gobierna con otro riesgo por delante: la seguridad de las personas),
`macos-fleet-standards` y `developer-workstation-standards` (el puesto y su provisión),
`cmdb-inventory-standards` (**el registro del activo y su ubicación**: sin inventario no se puede
declarar perdido lo que nunca se supo que existía), `vmware-standards`/`proxmox-ve-standards`
(el hipervisor), `homelab-standards` (proporcionalidad: nada de esto se aplica literalmente en casa).

## 2. Decisiones por defecto

> Verificar nombres exactos de norma, versión y obligación legal por web antes de fijarlos (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Autenticación en zona crítica (CPD, sala de comunicaciones) | **Dos factores**: tarjeta + PIN o biometría | Un solo factor solo en zonas de oficina general |
| Credencial de acceso | **Tecnología con cifrado y autenticación mutua**, aprovisionada por el mismo ciclo joiner-mover-leaver que la cuenta | Nunca credencial de solo lectura de identificador, trivial de copiar |
| Zonas | **Concéntricas**: perímetro → edificio → planta/oficina → sala técnica → **rack** | Menos capas solo si el activo no lo justifica |
| Antipassback | **Activado en zona crítica** (no se puede volver a entrar sin haber salido) | Desactivado solo con justificación escrita: rompe el conteo en emergencia |
| Puerta en fallo | **Fail-safe** (abre) donde la vida está en juego; **fail-secure** donde no | La norma de evacuación manda siempre sobre la de seguridad (§6) |
| CCTV | Cobertura de **puntos de decisión** (accesos, pasillo de racks, muelle), no cobertura total | Menos cámaras y mejor colocadas, siempre |
| Retención de CCTV | **La mínima que cumple la finalidad**, y en España **un mes como máximo legal** (§3.3) | Más solo si hay que acreditar un hecho ante autoridad competente |
| Soportes retirados | **Destrucción física certificada** por defecto | Borrado criptográfico o sobrescritura verificable si el soporte se reutiliza internamente (§3.5) |
| SSD y memoria flash | **Destrucción física**; el degaussing **no funciona** sobre flash | Borrado criptográfico si el fabricante lo documenta y se verifica |
| Toma de red en zona común | **Deshabilitada por defecto**; si se habilita, **802.1X** | VLAN de invitados aislada, nunca la de producción |
| Visitantes en zona técnica | **Acompañamiento permanente**, registro y credencial visualmente distinta | Ninguna |
| Marco de referencia | **ISO/IEC 27001:2022 Anexo A, tema 7 (14 controles, A.7.1–A.7.14)** | ENS o CIS si el contexto lo exige; se mapean, no se duplican |

## 3. Estructura y convenciones

### 3.1 Control de acceso: lo que falla no es el lector

- **Tailgating (colarse detrás de alguien autorizado) es el fallo dominante**, y no es un fallo del
  sistema: es un conflicto entre la seguridad y la cortesía. Se ataja con **medidas físicas donde
  importa** (paso de una sola persona, torno, esclusa) y con **norma explícita y sin culpa**: "no
  sujetes la puerta" tiene que ser política escrita y respaldada por dirección, o el empleado que
  la aplica queda como el maleducado.
- **Antipassback** impide reutilizar una credencial para entrar dos veces sin salir — es lo que
  convierte el préstamo de tarjeta en un fallo visible. Contrapartida real: rompe el conteo de
  ocupantes si alguien sale por una puerta de emergencia, y hay que tener un procedimiento de
  reinicio.
- **La biometría no es una contraseña**: no se puede cambiar cuando se filtra. Se usa como **segundo
  factor**, con plantilla almacenada localmente y cifrada, nunca como identificador único ni
  exportable, y es **dato de categoría especial** cuando se usa para identificar (frontera con
  `privacy-engineering-standards`: la base jurídica se decide allí, no aquí).
- **Ciclo de vida de la credencial física = el de la cuenta**. La baja de un empleado que devuelve
  el portátil pero conserva la tarjeta es el caso típico. **Recertificación periódica de quién tiene
  acceso a zona crítica**, con la misma cadencia que la de accesos lógicos.
- **Registros de acceso**: se retienen, **se revisan** (accesos fuera de horario, a zona crítica, de
  personal externo) y se correlacionan. Correlación de alto valor y coste casi nulo: **credencial
  usada en el edificio mientras la cuenta se autentica desde otro país**, o **acceso a la sala sin
  ticket de cambio asociado**.
- **Llaves y llaveros maestros**: son la puerta trasera permanente. Inventario nominativo, custodia
  en depósito con registro de retirada, **prohibida la copia**, y **cambio de bombín ante pérdida** —
  no "ya aparecerá". Una llave maestra que abre todo el edificio y vive en un cajón anula el resto
  del capítulo.
- **El rack es una zona**, no un mueble: cerradura efectiva, paneles laterales puestos, puertas
  cerradas, y **registro de quién lo abre**. Un CPD con control de acceso perfecto y racks abiertos
  protege la sala, no los servidores.

### 3.2 Colocation: quién más tiene acceso físico a tu jaula

Pregunta que casi nunca se hace y que decide el modelo de amenaza en un centro compartido:

- **El personal del proveedor tiene acceso físico a tu espacio.** Es inevitable (incendio, avería,
  obra) y es correcto; lo que hay que exigir es **procedimiento**: quién puede entrar sin ti, en qué
  supuestos, con qué registro y con qué notificación posterior. Debe estar en el contrato, no en la
  buena voluntad.
- **Tus vecinos comparten pasillo.** Una jaula de malla con techo abierto es una barrera visual, no
  física. Si el activo lo justifica: jaula con techo, paneles ciegos, cerradura propia con tu
  llave y **cámara propia dentro de la jaula** (y esa cámara es tratamiento tuyo, con tus
  obligaciones).
- **Lo que hay que pedir por escrito antes de firmar**: registro de accesos a tu espacio entregable
  bajo demanda, política de acompañamiento, control de manos remotas (*remote hands*) y qué puede
  hacer sin autorización explícita, procedimiento de entrada y salida de material, y derecho de
  auditoría. **"Es un centro Tier III" no responde a ninguna de estas preguntas**: esa clasificación
  habla de disponibilidad, no de quién entra (frontera con `datacenter-facilities-standards`).
- **Manos remotas es acceso privilegiado delegado**: el técnico del proveedor que conecta un
  teclado a tu servidor está haciendo administración física con tu autorización. Se pide por canal
  autenticado, se acota a la tarea y se registra.

### 3.3 CCTV, alarmas y su condición de tratamiento de datos personales

- **Cada cámara sirve a una finalidad documentada** o se retira. La cobertura por acumulación es
  ilegal y además inútil: nadie revisa 60 flujos.
- **Base jurídica y proporcionalidad**: en el RGPD la videovigilancia de seguridad se apoya
  típicamente en interés legítimo, con **ponderación obligatoria** frente a los derechos del
  afectado y análisis de si hay medio menos intrusivo. Las **Directrices 3/2019 del EDPB sobre
  tratamiento de datos personales mediante dispositivos de vídeo** son la referencia europea.
  Prohibido en zonas de expectativa de intimidad (vestuarios, aseos, áreas de descanso), y **la
  videovigilancia no puede ser un instrumento de supervisión generalizada del trabajador**.
- **Retención — España, texto legal verbatim** (Ley Orgánica 3/2018, LOPDGDD, art. 22.3):
  > «Los datos serán suprimidos en el plazo máximo de **un mes** desde su captación, salvo cuando
  > hubieran de ser conservados para acreditar la comisión de actos que atenten contra la
  > integridad de personas, bienes o instalaciones. En tal caso, las imágenes deberán ser puestas a
  > disposición de la autoridad competente en un plazo máximo de setenta y dos horas desde que se
  > tuviera conocimiento de la existencia de la grabación.»

  Dos precisiones que se pierden al citarlo de memoria: **el plazo es "un mes", no "30 días"** —la
  paráfrasis circula por todas partes—, y **la excepción no es "guardarlo por si acaso"**, sino
  conservarlo para acreditar un hecho concreto, con entrega a la autoridad en 72 horas.
- **Cartel informativo obligatorio** en lugar visible, con responsable y forma de ejercer derechos.
- **Consecuencia de ingeniería**: el sistema debe **borrar solo** al vencer el plazo. Un NVR
  configurado a "sobrescribir cuando se llene" no cumple un plazo, cumple una capacidad de disco.
- **La grabadora es un servidor**: en la red de gestión, parcheada, sin credenciales por defecto,
  sin exposición a Internet y con su propio control de acceso. El historial de cámaras IP y NVR
  expuestos es largo y no ha mejorado.
- **Alarmas**: la detección sin **respuesta con tiempo comprometido** no es un control. Se define
  quién recibe, en cuánto responde y qué hace; se prueba periódicamente; y se mide la **tasa de
  falsas alarmas**, porque una alarma que salta a diario deja de atenderse (mismo fenómeno que la
  fatiga de alertas de `soc-operations-standards`).
- **Los sensores mienten hacia el lado cómodo**: un contacto magnético dice que la puerta está
  cerrada, no que nadie haya pasado. Se combinan tecnologías en zona crítica.

### 3.4 Puertos, consolas y cualquier cosa que se pueda enchufar

- **La toma de red accesible en zona común es una conexión no autenticada a tu red interna.**
  Control por defecto: puerto administrativamente deshabilitado; si tiene que estar activo,
  **802.1X** (o, como mínimo peor, *port-security* por MAC, que solo detiene al descuidado). El
  diseño y la operación de eso son de `networking-standards`; **aquí la exigencia de que exista**.
- **Puertos USB**: la política realista no es "pegar los puertos", es **bloqueo por software del
  almacenamiento masivo y de las clases de dispositivo no necesarias**, con excepción gestionada.
  Un puerto físico también admite dispositivos que se presentan como teclado, y contra eso el
  bloqueo por clase es el control.
- **Consola serie y KVM**: dan acceso previo al sistema operativo — cargador de arranque, firmware,
  recuperación. Se tratan como acceso de administración: en red de gestión aislada, con
  autenticación y registro. Un servidor de consolas accesible es la llave del pasillo entero.
- **Cabeceras de depuración (JTAG/SWD) y puertos de servicio** en equipamiento de red, cámaras,
  controladores de acceso y dispositivos empotrados: se asumen presentes y se protegen por
  **ubicación y detección de manipulación**, porque desactivarlos rara vez está en tus manos.
- **Botón de reinicio de fábrica**: en muchos equipos devuelve credenciales por defecto y borra la
  configuración. Es un ataque físico de un segundo y hay que contarlo en el modelo.
- **Precinto y evidencia de manipulación** en equipo desatendido o remoto: no impide nada, pero
  convierte un acceso silencioso en un hallazgo — que es exactamente lo que hace falta cuando no se
  puede impedir.

### 3.5 Soportes: custodia, borrado y destrucción

Marco técnico: **NIST SP 800-88 Rev. 1**, que define tres categorías, verbatim del documento:

> «**Clear** applies logical techniques to sanitize data in all user-addressable storage locations
> for protection against simple non-invasive data recovery techniques […]
> **Purge** applies physical or logical techniques that render Target Data recovery infeasible
> using state of the art laboratory techniques.
> **Destroy** renders Target Data recovery infeasible using state of the art laboratory techniques
> and results in the subsequent inability to use the media for storage of data.»

Cómo se decide, sin ambigüedad:
- **Clear** basta si el soporte se reutiliza **dentro** del mismo entorno de confianza.
- **Purge** si sale de tu control pero se reutiliza (venta, devolución de garantía, donación).
- **Destroy** si la clasificación del dato lo exige, si el soporte **falla** (un disco que no
  responde no se puede sobrescribir ni verificar) o si no puedes demostrar el resultado.
- **Borrado criptográfico**: destruir la clave de un soporte autocifrado es rápido y elegante, y
  **depende por completo de que el cifrado y la gestión de claves del fabricante sean correctos**.
  Vale como *Purge* cuando el fabricante lo documenta y hay verificación; no vale como acto de fe.
- **Flash y SSD**: la sobrescritura no alcanza bloques remapeados ni la sobreprovisión, y **el
  degaussing no tiene ningún efecto sobre memoria flash** — es un mito caro. Borrado criptográfico
  o destrucción física.
- **Verificación**: sin muestreo y registro del resultado, el borrado es una intención.

**El certificado de destrucción es la evidencia, y se exige con contenido**: números de serie de
cada soporte, método, fecha, responsable y trazabilidad. Un certificado que dice "10 discos
destruidos" sin números de serie no vale ante un auditor y, sobre todo, **no permite saber cuál
falta**. Referencias de mercado: la certificación **NAID AAA** (i-SIGMA) para proveedores de
destrucción, con auditorías sin previo aviso y verificación de números de serie antes y después;
y la norma alemana **DIN 66399**, que clasifica por tipo de material y nivel de protección (P para
papel, H para discos duros, etc.) y sustituyó a la antigua DIN 32757. Criterio: **el nivel se
especifica en el contrato**, no se deja al criterio del proveedor.

Además:
- **La destrucción presenciada o grabada** es la única forma de cerrar la ventana entre "sale del
  edificio" y "se destruye". El transporte es el eslabón débil.
- **Cadena de custodia desde que el soporte sale del rack**: quién lo retira, dónde se guarda
  mientras espera, quién lo entrega. Un armario con discos pendientes de destrucción es un botín
  concentrado.
- **Papel y soportes menores cuentan**: diagramas de red, listados, notas y etiquetas con nombres
  de host. La destrucción segura de papel es parte del mismo proceso, no un asunto de oficina.
- **Ciclo cerrado con el inventario**: la baja del activo solo se cierra con el certificado
  asociado (frontera con `cmdb-inventory-standards`).

### 3.6 Dispositivos perdidos o robados

- **Prerrequisito: inventario.** Sin él no se puede declarar perdido lo que no se sabía que existía,
  ni saber qué contenía.
- **Cifrado completo de disco activo y verificado en toda la flota**, con custodia de la clave de
  recuperación (la postura de cifrado y su escrow son de `endpoint-security-standards`; aquí la
  exigencia de que exista antes de que haga falta).
- **Procedimiento con reloj**: declarar → revocar credenciales y sesiones de esa identidad (§ de
  `identity-threat-detection-standards`) → borrado remoto si es posible → evaluar si hubo dato
  personal y si procede notificación (`privacy-engineering-standards` / `grc-compliance-standards`)
  → denuncia si aplica → baja en inventario.
- **El borrado remoto es un "quizá"**: exige que el dispositivo se conecte. **El cifrado es el "sí"**.
  Diseñar como si el borrado remoto no fuera a ejecutarse nunca.
- **Cultura de reporte inmediato y sin castigo.** Si perder un portátil se paga con una bronca, se
  reporta el lunes siguiente, y esas horas son las que importan.

### 3.7 Personas: visitantes, mantenimiento y suplantación presencial

- **Visitante = acompañamiento permanente** en zona técnica, credencial visualmente distinta,
  registro con hora de entrada y salida y motivo. Un registro que solo tiene entradas no es un
  registro.
- **Personal de limpieza y mantenimiento tiene, en la práctica, el acceso más amplio y menos
  vigilado del edificio**, a menudo fuera de horario y por contrata. Mismo cribado, mismo alcance
  mínimo, mismo registro. Que sea de una empresa externa no reduce el riesgo: lo reparte.
- **Técnico de un proveedor**: **cita previa confirmada por canal conocido** —no por el teléfono que
  aparece en su tarjeta—, verificación de identidad, acompañamiento y trabajo acotado a lo pactado.
  El patrón de suplantación presencial más eficaz es siempre el mismo: **uniforme, urgencia y
  autoridad**, y funciona porque frenarlo parece descortés y arriesgado para quien está en
  recepción.
- **El control es organizativo**: recepción con **autoridad explícita y respaldo escrito para
  decir que no**, un teléfono al que llamar y ninguna consecuencia por hacer esperar a alguien.
  Formar en el fallo concreto (sujetar la puerta, aceptar la urgencia, no pedir identificación)
  rinde más que cualquier charla general.
- **Mesa y pantalla despejadas** (control A.7.7): credenciales en notas, sesiones abiertas y
  documentos sobre la mesa son el botín de la visita de cinco minutos.
- **Entrega y salida de material**: nadie saca hardware sin autorización registrada. Es el control
  que convierte el robo interno en un hecho detectable.

### 3.8 El modelo de amenaza honesto

Escalones de acceso físico, con lo que cada uno concede:

| Acceso | Lo que consigue el atacante | Lo que lo compensa (parcialmente) |
|---|---|---|
| Vista de la pantalla / mesa | Credenciales, datos, contexto para suplantar | Mesa despejada, filtro de privacidad |
| Un puerto o una toma de red | Presencia en la red interna | 802.1X, bloqueo de clases USB |
| Equipo apagado, unos minutos | Disco: nada si está bien cifrado | **Cifrado completo con clave no derivable trivialmente** |
| Equipo encendido o suspendido | Claves en memoria, sesión viva, interfaces DMA | Apagar (no suspender), bloqueo, protección DMA |
| Acceso prolongado y sin supervisión | **Compromiso persistente en firmware o hardware** | Arranque seguro y medido, atestación, evidencia de manipulación |

Corolario que hay que decir en voz alta ante dirección: **contra acceso físico prolongado y sin
supervisión, no hay control lógico que garantice la integridad del equipo.** A partir de ese punto
se trabaja con **detección** (evidencia de manipulación, atestación de arranque, verificación de
firmware) y con **reducción del valor del objetivo** (que el equipo no guarde lo que no necesita).
El arranque medido y el cifrado **elevan el coste y hacen ruidoso el ataque**; no lo impiden. Quien
venda lo contrario está vendiendo.

## 4. Verificación y pruebas

- **Prueba de tailgating y de acompañamiento**, con alcance y autorización por escrito y con
  conocimiento de al menos un responsable: es la prueba que más aprendizaje da y la que más
  incomoda. Resultado esperado: no "hemos entrado", sino **cuántas personas y en qué punto tuvieron
  la oportunidad de frenarlo y no lo hicieron**, y qué cambio organizativo lo corrige.
- **Prueba de la alarma extremo a extremo**, cronometrada, incluida la respuesta humana.
- **Prueba de las grabaciones**: no "¿graba?", sino **¿se puede recuperar y ver la grabación de un
  incidente concreto de hace tres semanas, y se identifica a alguien con esa calidad?**
- **Auditoría de credenciales activas** frente al listado de personal: cada tarjeta que abre zona
  crítica con un titular vivo y vigente.
- **Auditoría de llaves** físicas: cada llave maestra localizada y firmada.
- **Muestreo del proceso de destrucción**: escoger N activos dados de baja el trimestre anterior y
  seguir su rastro hasta el número de serie en un certificado. **Aquí es donde aparecen los
  agujeros**, siempre.
- **Recorrido físico trimestral** buscando lo mundano: puertas calzadas, racks abiertos, tomas de
  red vivas en salas comunes, cajas de discos "pendientes", carteles ausentes, cámaras giradas o
  tapadas por una estantería nueva.
- **Mapeo a ISO/IEC 27001:2022 Anexo A tema 7** (A.7.1–A.7.14) como lista de comprobación de
  cobertura, **no como el trabajo**: el control A.7.4 (monitorización de seguridad física) es el
  único nuevo del tema en la revisión de 2022 y suele ser el hueco.

## 5. Seguridad del stack (los propios sistemas de seguridad física)

Los sistemas que protegen el edificio son sistemas de TI, y suelen ser los peor gestionados del
inventario:

- **Controladores de acceso, NVR, videoporteros y centrales de alarma**: en **VLAN propia
  segmentada**, sin salida a Internet, sin credenciales por defecto, con parcheo con dueño y con
  contrato de mantenimiento que incluya firmware. Muchos corren sistemas operativos antiguos que
  nadie actualiza porque "son del instalador".
- **El acceso remoto del instalador es un acceso privilegiado permanente**: se gobierna como
  cualquier acceso de tercero (bajo demanda, autenticado, registrado, revocable) y **no** como un
  túnel abierto de por vida.
- **La base de datos del sistema de accesos contiene datos personales** —quién estuvo dónde y
  cuándo— y en muchos casos biométricos. Control de acceso propio, retención definida y su base
  jurídica (`privacy-engineering-standards`).
- **La copia de seguridad de la configuración de accesos y del vídeo** existe y se prueba, o el
  primer incidente serio se queda sin evidencia.
- **Dependencia energética y de red**: qué pasa con puertas, lectores y grabación cuando cae la
  corriente o la red. Se decide y se documenta antes, no durante (§6).

## 6. Operabilidad

- **Modo de fallo de cada puerta, decidido y escrito.** *Fail-safe* (se abre al faltar corriente)
  donde hay riesgo para las personas; *fail-secure* donde no. **La normativa de evacuación manda
  siempre**: una salida que no abre en una emergencia es un problema mayor que cualquier intrusión.
  Y el corolario incómodo: **un corte de corriente puede ser un ataque al control de acceso** — hay
  que saber qué queda abierto.
- **Autonomía**: lectores, controladores, grabación y alarmas necesitan alimentación respaldada. El
  dimensionado de esa alimentación es de `datacenter-facilities-standards`; **la exigencia de que
  esos equipos estén en ella es de aquí**, y es el olvido clásico.
- **Degradación con la red caída**: un controlador que solo valida contra un servidor central deja
  de funcionar cuando cae. Se exige **validación local con caché** y sincronización posterior de los
  eventos.
- **Capacidad de grabación coherente con la retención legal**: se dimensiona por días de retención,
  no por "lo que quepa".
- **Revisión de registros con dueño y cadencia**. Sin dueño no se revisa nunca.
- **Métricas que deciden algo**: tarjetas activas sin titular vigente, tiempo medio de revocación
  tras una baja, porcentaje de activos dados de baja con certificado de destrucción asociado,
  incidentes de acceso detectados por control frente a detectados por casualidad, y tasa de falsas
  alarmas. **Nada de "número de cámaras instaladas".**

## 7. Sostenibilidad a largo plazo

- **El sistema de control de accesos dura 10–15 años y la tecnología de credencial envejece antes**:
  planificar la migración de tecnología de tarjeta como proyecto, no como emergencia el día que se
  publica que la vuestra es trivial de copiar.
- **Cada mudanza, obra o cambio de proveedor reabre todo el capítulo**: llaves nuevas, tomas nuevas,
  personal nuevo. Se trata como cambio con revisión de seguridad, no como logística.
- **Convergencia con la identidad lógica** (alta y baja únicas para credencial física y cuenta) como
  objetivo: elimina de raíz la clase de fallo "se fue y su tarjeta sigue abriendo".

**PROHIBIDO**:
- ❌ Cerraduras y sistemas con **credenciales o códigos por defecto** sin cambiar. (Y **PROHIBIDO
  incluir en este documento credenciales por defecto de productos de terceros**: metodología, no
  recetario.)
- ❌ Documentar aquí **técnicas de apertura de cerraduras, clonado de credenciales o elusión de
  lectores**, y realizar cualquier prueba de intrusión física sin alcance y autorización escritos.
- ❌ Retener grabaciones más allá del plazo legal, o "guardarlas por si acaso" fuera de la excepción
  del art. 22.3 LOPDGDD.
- ❌ Cámaras en zonas de expectativa de intimidad, o videovigilancia como supervisión generalizada
  del trabajador.
- ❌ Biometría como factor único, o plantillas biométricas exportables o centralizadas sin base
  jurídica y sin cifrar.
- ❌ Aceptar un **certificado de destrucción sin números de serie**, o dar de baja un activo sin él.
- ❌ Degaussing como método de sanitización de **SSD o memoria flash**.
- ❌ Sacar un soporte del edificio sin cadena de custodia, o acumular discos pendientes de destruir
  en un armario sin control.
- ❌ Tomas de red activas en zonas comunes sin 802.1X, y consolas serie o KVM accesibles fuera de la
  red de gestión.
- ❌ Visitantes, técnicos o personal de limpieza sin acompañamiento en zona técnica.
- ❌ Presentar el cifrado de disco o el arranque medido como si **impidieran** el compromiso con
  acceso físico prolongado: son controles compensatorios y hay que decirlo así ante dirección.
- ❌ Firmar un contrato de colocation sin resolver por escrito quién accede a tu jaula, con qué
  registro y con qué notificación.
- ❌ Dejar la red de los sistemas de seguridad física (accesos, CCTV, alarmas) sin segmentar,
  sin parchear o accesible desde Internet.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:
1. **Obligación legal aplicable a la videovigilancia en tu jurisdicción**. Lo citado aquí es España:
   **LOPDGDD art. 22.3, transcrito verbatim del texto consolidado del BOE**; y las **Directrices
   3/2019 del EDPB**. Comprobar guías vigentes de la AEPD (hay material actualizado en 2026) y, si
   el tratamiento es laboral, las reglas específicas. **Esto no es asesoramiento jurídico**: la
   interpretación la fija legal / protección de datos.
2. **NIST SP 800-88**: revisión vigente (aquí, **Rev. 1**, definiciones transcritas verbatim del PDF
   oficial) y si hay borrador posterior. **Hueco declarado**: no se comprobó si existe una revisión
   posterior en curso.
3. **ISO/IEC 27001:2022 y 27002:2022**: numeración y títulos exactos de los controles del tema 7
   (A.7.1–A.7.14) y cualquier enmienda posterior. **Los títulos aquí proceden de fuentes secundarias
   coincidentes, no del texto de la norma (que es de pago): verificar contra la norma antes de
   usarlos en un SoA.**
4. **DIN 66399** (vigencia y niveles) y **NAID AAA / i-SIGMA** (criterios y validez del certificado
   del proveedor concreto). Verificar la certificación **del proveedor que vas a contratar**, no la
   existencia del programa.
5. **Tecnología de la credencial física** que uses o vayas a comprar: estado público de su seguridad
   y si el fabricante ya ofrece sustituto. Es el dato que más envejece de este documento.
6. **Avisos y CVE de tu sistema de control de accesos, NVR y central de alarmas**: entran en el
   proceso de `vulnerability-management-standards` como cualquier otro activo, y casi nunca lo hacen.
7. **Requisitos sectoriales** que impongan controles físicos concretos (ENS, PCI DSS, sector
   sanitario o financiero) y su versión vigente.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
