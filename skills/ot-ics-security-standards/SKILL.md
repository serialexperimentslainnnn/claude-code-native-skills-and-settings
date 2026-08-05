---
name: ot-ics-security-standards
description: Securing industrial control and operational technology where availability and physical safety outrank confidentiality. Use when working with PLCs, RTUs, HMIs, DCS, SCADA masters, historians or a Safety Instrumented System (SIS), the Purdue/ISA-95 level model and an industrial DMZ at Level 3.5, ISA/IEC 62443 parts (62443-2-1, 62443-3-2 zones and conduits and its ZCR workflow, 62443-3-3 system requirements, 62443-4-1 and 62443-4-2 component requirements, SL-T/SL-C/SL-A security levels, the seven foundational requirements), NIST SP 800-82r3 and its OT overlay, IEC 62351 and NERC CIP, unauthenticated field protocols (Modbus TCP port 502, DNP3 / IEEE 1815 Secure Authentication SAv5, EtherNet/IP and CIP, PROFINET, S7comm, IEC 60870-5-104, BACnet), OPC UA SecurityPolicy selection (Aes256_Sha256_RsaPss, Aes128_Sha256_RsaOaep, Basic256Sha256, SecurityMode None) and deprecated Basic128Rsa15/Basic256, passive monitoring with a TAP or SPAN and why an active scan crashes a controller, a data diode or unidirectional gateway, vendor and OEM remote access into the plant, engineering workstations and project files, twenty-year asset lifecycles and unsupported Windows that cannot be patched, or ICS-specific malware such as Stuxnet, Industroyer, TRITON, PIPEDREAM and FrostyGoop.
---

# Estándares de seguridad OT/ICS — industrial, con la seguridad física por delante

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, revisar u operar la seguridad de un sistema que **actúa sobre el mundo
físico**: proceso continuo o discreto, energía, agua, transporte, edificios, sanidad,
manufactura. Cubre: inversión de prioridades frente a IT, modelo de referencia (Purdue /
ISA-95) y su uso real, **zonas y conductos** de IEC 62443-3-2, niveles de seguridad SL-T /
SL-C / SL-A, DMZ industrial y diodo de datos, protocolos de campo sin autenticación,
monitorización **pasiva**, acceso remoto de fabricante, ciclo de vida de 20 años y activos
sin parche posible, gestión de cambio con el proceso en marcha, y el marco regulatorio
(NIS2, CRA, NERC CIP, IEC 62443 como eje normativo).

Triggers: PLC, RTU, IED, HMI, DCS, SCADA, historian, SIS, `Modbus/TCP` (502), DNP3 /
IEEE 1815, IEC 60870-5-104, IEC 61850 (MMS/GOOSE/SV), EtherNet/IP y CIP, PROFINET, S7comm,
BACnet, OPC UA / OPC DA, ISA-95, "nivel 3.5", "diodo de datos", "ventana de parada",
"engineering workstation", "firmware del controlador", ANSI/ISA-62443, NIST SP 800-82r3,
IEC 62351, NERC CIP, ENS para operadores críticos.

**Postura estrictamente defensiva.** Cualquier prueba activa sobre equipo real exige alcance
y autorización **por escrito**, ventana acordada con operaciones y plan de parada; por
defecto se prueba en banco/gemelo, no en planta.

**No aplica**: ver `networking-standards` (diseño de red, VLAN, routing, DNS — **la
topología y el direccionamiento son suyos; qué zona existe y qué SL exige, de aquí**),
`firewall-policy-standards` (**la regla como artefacto**: default-deny, matriz de flujos,
ciclo de vida y aprobación de la regla — **aquí se decide qué conducto existe entre zonas y
qué protocolo industrial puede atravesarlo, allí se escribe y se gobierna la regla**),
`vpn-standards` (túnel y concentrador como servicio — **aquí el gobierno del acceso de
fabricante y el broker/jump host industrial**), `detection-engineering-standards` (**la regla
de detección**; aquí solo qué telemetría OT existe y cómo se obtiene sin tocar el proceso),
`soc-operations-standards` (turno, cola y triaje — **un SOC IT sin escalado a operaciones no
sirve para OT**), `incident-response-forensics-standards` (respuesta e investigación; aquí
solo por qué "apagar y aislar" puede ser el peor movimiento), `vulnerability-management-standards`
(triaje CVSS/EPSS/KEV y SLA — **aquí por qué ese SLA no aplica y qué compensa el parche que
no se pondrá**), `endpoint-security-standards` (**Ola 7, hermana**: EDR, control de
aplicaciones y cifrado del endpoint IT — **aquí el endpoint industrial que no admite agente
y por qué**), `grc-compliance-standards` (marco, SoA, aceptación de riesgo),
`identity-access-management-standards` (IdP, MFA, ciclo de vida de cuentas),
`windows-server-ad-standards` y `linux-hardening-standards` (el dominio y el baseline del SO
en el centro de control), `routing-switching-standards` (switching, MLAG, 802.1X),
`bcdr-standards` (BIA, RTO/RPO), `backup-recovery-standards` (copia y restore),
`onprem-standards` (plataforma física), `offensive-security-standards` (ejercicio ofensivo
autorizado; esta skill no lo ejecuta), `threat-intelligence-standards` (indicador y actor),
`air-gapped-standards` (**arbitraje, recíproco desde su §1**: el aislamiento **del proceso
físico** —Purdue, DMZ de nivel 3.5, zonas y conductos, diodo— es de aquí; **el enclave aislado
como modo de operación general —datos, servidores, espejo interno, tiempo y PKI sin salida— es
suyo**), `robotics-ros-standards` (**el robot industrial**: ROS 2, QoS y middleware, y la
seguridad de máquina del brazo son suyos; aquí la celda como zona dentro del proceso).

## 2. Decisiones por defecto

> Verificar por web antes de fijar nada en un proyecto real (§8). Las ediciones de IEC 62443
> y el estado de transposición de NIS2 cambian; no los escribas de memoria.

| Decisión | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| Orden de prioridades | **Safety → Disponibilidad → Integridad → Confidencialidad** | Ajuste por zona documentado en el análisis de riesgo | Aplicar el orden CIA de IT sin más |
| Marco técnico | **ISA/IEC 62443** (zonas, conductos, SL) | NIST SP 800-82r3 + su *OT overlay* de SP 800-53r5 como complemento | Un baseline IT genérico como único marco |
| Arquitectura | Segmentación por **zonas y conductos** sobre el mapa Purdue | Microsegmentación cuando el activo no encaja en un nivel | Red plana de planta; "un firewall en el borde y ya" |
| Frontera IT/OT | **DMZ industrial (nivel 3.5)** sin tráfico que la atraviese de extremo a extremo | Diodo de datos / gateway unidireccional donde el flujo sea solo de salida | Conexión directa nivel 2 ↔ nivel 4; historian corporativo consultando el PLC |
| Descubrimiento e inventario | **Pasivo** (TAP, o SPAN asumiendo pérdida) | Consulta activa **solo** con protocolo del fabricante, banco previo y ventana | `nmap`/escáner de vulnerabilidades contra niveles 0-2 |
| Acceso de fabricante | **Broker con jump host, MFA, sesión grabada, bajo demanda y con aprobación** | VPN dedicada a una zona concreta, con caducidad | Túnel permanente del OEM, TeamViewer/AnyDesk en la HMI, módem 4G "temporal" |
| Protocolo con seguridad | **OPC UA** con `SignAndEncrypt` y `Aes256_Sha256_RsaPss` | `Aes128_Sha256_RsaOaep` o `Basic256Sha256` si el otro extremo no llega | `SecurityMode None`, anónimo, `Basic128Rsa15`/`Basic256` (obsoletas, SHA-1) |
| Protocolo heredado | **Compensar en la red** (zona, conducto, lista de funciones permitidas) | DNP3 SAv5 (IEEE 1815-2012 cl. 7) o IEC 62351 donde ambos extremos lo soporten | Asumir que Modbus/TCP "va autenticado" porque hay VPN |
| Parcheo del controlador | **Ventana de parada planificada**, tras validación en banco y con rollback | Compensación (segmentación, monitorización, control de escritura) si no hay ventana | Parchear un PLC en producción "porque el CVE es 9.8" |
| Cripto en el enlace | TLS 1.2+/1.3 donde el equipo lo soporte de verdad | Túnel externo (gateway, IPsec) si el equipo no puede | Cripto propia del fabricante sin documentación ni auditoría |

## 3. La inversión de prioridades, y por qué el parche puede ser el riesgo mayor

- En IT el peor caso es la fuga de datos. En OT el peor caso es **una persona muerta o el
  proceso fuera de control**. Todo el resto del documento se deriva de esa frase.
- **El sistema instrumentado de seguridad (SIS) es una zona propia, aislada y sin ruta desde
  el DCS.** TRITON/TRISIS (2017, Schneider Triconex) es el precedente: malware escrito para
  manipular la última barrera antes del accidente.
- **La disponibilidad no es un SLA, es física.** Un reinicio de PLC no es "un minuto de
  downtime": es parada de proceso con arranque de horas, producto perdido y, según el
  proceso, riesgo para personas.
- **Por eso el parche puede ser el riesgo mayor.** Firmware nuevo implica reinicio,
  revalidación funcional y —en farma, nuclear o aviación— recertificación. La decisión
  correcta es a menudo **no parchear y compensar**, pero se documenta como aceptación formal
  de riesgo (`grc-compliance-standards`), nunca por omisión.
- Triaje: CVSS 9.8 en un PLC **no** significa "parchear en 15 días". Pregunta primero si el
  activo es alcanzable desde una zona menos confiable; si no lo es, el hallazgo es trabajo de
  arquitectura, no de mantenimiento.
- **El escaneo activo tumba controladores.** Atienden una cosa a la vez, con pila TCP/IP
  mínima y servidores HTTP embebidos frágiles; un escáner probando condiciones TLS los
  reinicia. CISA documentó en AA22-103A capacidades de adversario tipo *packet of death* que
  dejan el PLC inoperativo hasta ciclo de potencia y recuperación de configuración — un
  barrido no autorizado se aproxima al mismo resultado **por accidente**. Regla: **niveles
  0-2 son zona sin escaneo por defecto**; el escaneo autenticado se reserva a 3.5 y arriba.

## 4. Purdue, zonas y conductos

- **Purdue (derivado de PERA/ISA-95) sigue vigente como vocabulario, no como plano.** "Nivel
  1", "nivel 3.5" son lenguaje común entre plantas y fabricantes, y eso vale. Lo que ya no se
  sostiene es la jerarquía estricta: IIoT, telemetría a la nube y operación remota crean
  rutas de nivel 0/1 a nivel 4-5 que el diagrama no muestra. Uso correcto: **Purdue como mapa
  de alto nivel, IEC 62443-3-2 (zonas y conductos) como la segmentación que se implementa y
  se audita**. Toda ruta que salte niveles se documenta como conducto explícito con su SL, o
  no existe.
- Flujo de IEC 62443-3-2 (**ZCR 1-7**): identificar el sistema bajo consideración (SuC) →
  evaluación inicial de riesgo → particionar en zonas y conductos → comparar con el riesgo
  tolerable → evaluación detallada → documentar requisitos, supuestos y restricciones →
  aprobación del propietario del activo. **ZCR 3.2** exige separar los activos IACS de los
  de negocio; **ZCR 3.6** recomienda agrupar en zona propia los dispositivos que entran por
  red externa (el acceso remoto **no** vive dentro del SuC); **ZCR 5.6** exige asignar un SL
  a cada zona y conducto.
- **DMZ industrial (3.5)**: el historian réplica, el servidor de parches, el repositorio de
  antivirus y el broker de acceso remoto viven ahí. Ningún flujo la atraviesa de extremo a
  extremo: cada lado termina en la DMZ y el otro lado inicia la suya.
- **Diodo de datos / gateway unidireccional** cuando el requisito real es "sacar datos sin
  dejar entrar nada". Es hardware, no una regla de firewall — y ese es su valor: no admite
  excepción por configuración errónea. Coste: cualquier escritura futura hacia dentro exige
  rediseño.
- Las estaciones de ingeniería (EWS) son **el activo más peligroso de la planta**: tienen el
  software que programa el controlador y los ficheros de proyecto. Zona propia, sin
  navegación ni correo, sin USB, con control de aplicaciones.

## 5. IEC 62443: el eje normativo (citas)

- Partes de referencia: **62443-2-1** (programa de seguridad del propietario del activo;
  **edición 2.0 de 2024**, sustituye a la de 2010, reestructurada en elementos de programa
  —SPE— con modelo de madurez), **62443-3-2** (evaluación de riesgo, zonas y conductos),
  **62443-3-3** (requisitos técnicos de sistema, SR y RE), **62443-4-1** (proceso de
  desarrollo seguro del fabricante) y **62443-4-2** (requisitos de componente, CR).
  Verifica edición vigente de cada parte antes de citarla (§8).
- **Siete requisitos fundamentales (FR)**, definidos en IEC 62443-1-1 y estructura de 3-3 y
  4-2: **FR 1 – Identification and authentication control**, **FR 2 – Use control**,
  **FR 3 – System integrity**, **FR 4 – Data confidentiality**, **FR 5 – Restricted data
  flow**, **FR 6 – Timely response to events**, **FR 7 – Resource availability**.
- **Niveles de seguridad (verbatim, IEC 62443-3-3):**
  - **SL 1**: *"Protection against casual or coincidental violation."*
  - **SL 2**: *"Protection against intentional violation using simple means with low
    resources, generic skills and low motivation."*
  - **SL 3**: *"Protection against intentional violation using sophisticated means with
    moderate resources, IACS specific skills and moderate motivation."*
  - **SL 4**: *"Protection against intentional violation using sophisticated means with
    extended resources, IACS specific skills and high motivation."*
- El SL **no es un número global**: es un **vector de siete elementos**, uno por FR (Anexo A
  de 62443-3-3). Una zona puede exigir SL 3 en FR 1-3 y FR 7 y SL 1 en FR 4 (confidencialidad)
  — p. ej. `SL = (3,3,3,1,2,1,3)`. Quien te venda "somos SL 2" sin vector ni alcance está
  vendiendo marketing.
- Distingue siempre **SL-T** (objetivo, sale del análisis de riesgo y es requisito de
  diseño), **SL-C** (capacidad que el producto o sistema puede soportar; lo declara el
  fabricante sobre 62443-4-2) y **SL-A** (alcanzado, lo que hay de verdad). La auditoría
  compara **SL-A frente a SL-T**; SL-C no demuestra nada por sí solo.
- Tensión a resolver explícitamente: 62443-1-1 asigna el objetivo por probabilidad y
  consecuencia, 3-3 describe los niveles por **capacidad del adversario**. Documenta la
  traducción; si no, el SL-T acaba poniéndolo el proveedor.
- **NIST SP 800-82 Rev. 3** (sep-2023, vigente; nota de planificación de jul-2024 anticipa
  erratas) es el complemento: ampliación de ICS a OT, adaptación de controles de SP 800-53r5
  y **OT overlay** con baselines de impacto bajo/medio/alto. Verifica erratas o revisión (§8).
- **Framework operativo mínimo**: los *Five ICS Cybersecurity Critical Controls* (SANS, Lee
  y Conway) — plan de respuesta a incidentes específico de ICS, arquitectura defendible,
  visibilidad y monitorización de red, acceso remoto seguro y gestión de vulnerabilidades
  basada en riesgo. Se mapean sobre 62443 y son la lista corta cuando no hay programa.

## 6. Protocolos, monitorización y acceso remoto

- **Sin autenticación por diseño, no por descuido**: Modbus/TCP (502) no tiene TLS, ni
  cabecera de autenticación, ni concepto de usuario — el *unit identifier* del MBAP es campo
  de enrutado, no identidad. Igual DNP3 base, IEC 60870-5-104, EtherNet/IP–CIP, PROFINET,
  S7comm y BACnet: el modelo original asumía que **la red era la frontera de seguridad**, y
  esa premisa murió. Consecuencia: **quien alcanza el puerto, controla**, y el control
  compensatorio es de arquitectura, no de protocolo.
- Extensiones que sí existen: **DNP3 Secure Authentication v5** (IEEE 1815-2012, cláusula 7,
  basada en IEC/TS 62351-5): reto-respuesta con clave simétrica, autenticidad e integridad y
  anti-replay, **sin confidencialidad**; el hueco reconocido es la **gestión de claves**, que
  el estándar deja en gran parte sin especificar y cada fabricante resuelve a su manera —
  verifica cómo se aprovisionan y rotan antes de darlo por seguro. **IEC 62351** securiza la
  familia TC57 (parte 3 = TLS sobre TCP/IP; parte 5 = DNP3/60870-5). Verifica ediciones (§8).
- **OPC UA es la excepción**: seguridad en el propio protocolo. Exige `SignAndEncrypt`,
  política **`Aes256_Sha256_RsaPss`** (preferente), `Aes128_Sha256_RsaOaep` o
  `Basic256Sha256` como caída, y usuario nominal en lugar de anónimo. **Prohibidas**
  `Basic128Rsa15` y `Basic256`: obsoletas desde la especificación 1.04 por SHA-1, deben venir
  deshabilitadas por defecto (open62541 las retiró del código desde 1.4.6). Trampa habitual:
  la política del **token de usuario** es independiente de la del canal — un canal fuerte con
  el usuario cifrado bajo `Basic256` no es una configuración segura. Lista de confianza de
  certificados **gestionada**, no "aceptar el primero que llegue".
- **Monitorización pasiva por defecto**: TAP (copia física, independiente de la carga del
  switch) antes que SPAN (mirror: añade carga y pierde paquetes en pico). Da inventario,
  línea base del proceso y detección por comportamiento — una estación que solo leía y de
  pronto **escribe** en el PLC, un cambio de modo, una descarga de lógica fuera de ventana.
  Límite honesto: **no confirma si un parche está puesto**, no ve activos apagados o
  silenciosos y genera mucho más volumen que un escaneo; se compensa con inventario
  documental del fabricante y consulta activa **por protocolo nativo**, probada en banco.
- **El acceso remoto de fabricante es el vector principal.** Ha de ser: bajo demanda (no
  permanente), aprobado por operaciones, contra un **broker/jump host en la DMZ industrial**,
  con MFA, con la sesión grabada, limitado a la zona y al activo del contrato, y **cortable
  desde planta con un interruptor físico o de política**. Un OEM con túnel permanente es una
  cuenta de administrador de dominio que no gestionas tú.
- Incidentes como argumento (verificados, sin recetario): **Stuxnet** (lógica manipulada en
  el controlador y vista del operador falsificada); **Industroyer/CrashOverride** (2016) e
  **Industroyer2** (2022), con protocolos eléctricos implementados nativamente;
  **TRITON/TRISIS** (2017) contra el SIS; **PIPEDREAM/INCONTROLLER** (2022), *toolkit*
  modular; **FrostyGoop** (Dragos, descubierto abr-2024; Golang, Modbus/TCP 502, escribe
  *holding registers*) — en el ataque a una empresa municipal de calefacción de **Lviv del
  22-23 de enero de 2024** entraron por un **router MikroTik expuesto**, degradaron el
  firmware de los controladores ENCO de las versiones 51/52 a la **50** (pérdida de
  visibilidad) y dejaron sin calefacción a **más de 600 bloques** casi dos días bajo cero.
  **Matiz obligatorio: Dragos evalúa que FrostyGoop fue *probablemente* el empleado, no lo da
  por probado**, y no atribuye a un grupo. El fallo estructural: router, servidores de
  gestión y controladores **sin segmentar**. Dragos reportó además ~46 000 dispositivos ICS
  expuestos a internet hablando Modbus.
- La lección repetida no es el malware: **el 96 % de los incidentes OT se originan en un
  compromiso de la red IT** (Dragos, 2025 — verifica la cifra y el año del informe, §8). La
  frontera IT/OT es donde se gana o se pierde.

## 7. Ciclo de vida, sostenibilidad y prohibiciones

- **Horizonte de 20-30 años**: el activo sobrevive a varias generaciones de IT, al fabricante
  del software y, con frecuencia, al ingeniero que lo puso. Diseña asumiendo que **el equipo
  no se podrá actualizar** y que el control compensatorio tendrá que durar décadas.
- Windows fuera de soporte en HMI y EWS es la norma, no la excepción: suele estar atado a la
  validación del proceso o a un driver que no existe para nada moderno. Tratamiento: zona
  propia, sin salida a internet, sin correo, control de aplicaciones en modo lista blanca,
  medios extraíbles bloqueados, y **fecha de sustitución en el plan de inversión** — no un
  "pendiente" perpetuo. Contrato de soporte extendido si el fabricante lo ofrece; si no, la
  aceptación de riesgo va firmada por quien la paga.
- **Copia y restauración probadas de lo que no está en ningún backup de IT**: proyectos de
  PLC, lógica, configuración de HMI, recetas, parametrización de variadores y **firmware
  exacto en uso**. Un restore de servidor no devuelve una planta a producción. Custodia del
  código del integrador con cláusula de *escrow* en contrato.
- Regulación: **NIS2** (Directiva UE 2022/2555) aplica a entidades esenciales e importantes,
  con deberes de gestión de riesgo, cadena de suministro y notificación. **En España la
  transposición seguía sin cerrar en 2026**: Anteproyecto de Ley de Coordinación y Gobernanza
  de la Ciberseguridad aprobado en Consejo de Ministros el **14-ene-2025** y aún en
  tramitación; dictamen motivado de la Comisión el **7-may-2025** y segundo requerimiento el
  **19-may-2026** (expediente INFR(2024)0270). **Verifica si ya se publicó en el BOE antes de
  citar plazos (§8)** — las obligaciones de fondo vienen de la directiva y no esperan a la
  ley. Añade **CRA** (Reglamento UE 2024/2847) para el producto que compras: IEC 62443-4-1/4-2
  van camino de armonizarse (CENELEC TC65X WG3) pero **a agosto de 2026 no son normas
  armonizadas todavía** — no prometas presunción de conformidad. Y **NERC CIP** si operas en
  el sistema eléctrico norteamericano.
- Cadencia: revisión de zonas y conductos ante **todo cambio de proceso**; revisión de
  inventario y de reglas de conducto al menos anual; ejercicio de respuesta OT (con
  operaciones y con el fabricante en la sala) al menos anual.

**PROHIBIDO**
- ❌ Escanear activamente niveles 0-2 (`nmap`, escáner de vulnerabilidades, agente que sondea)
  sin banco previo, ventana y autorización escrita.
- ❌ Instalar agentes de IT (EDR, inventario, gestión de parches) en un controlador, en un
  panel de operador o en cualquier equipo cuya validación funcional lo impida.
- ❌ Túnel de fabricante permanente, escritorio remoto de terceros en la HMI, módem/router 4G
  colgado del cuadro "para mantenimiento".
- ❌ Aplicar el SLA de parcheo de IT a activos OT, o parchear un controlador en producción.
- ❌ Ruta directa entre nivel 4/5 y niveles 0-2; historian corporativo consultando el PLC.
- ❌ SIS en la misma zona que el DCS, o alcanzable desde ella.
- ❌ OPC UA con `SecurityMode None`, usuario anónimo o políticas `Basic128Rsa15`/`Basic256`.
- ❌ Asumir que un protocolo industrial autentica algo porque va por VPN o por una VLAN.
- ❌ Credenciales compartidas de planta, cuentas de fabricante genéricas, contraseñas en el
  proyecto del PLC o pegadas en el armario.
- ❌ USB sin control entre la EWS y cualquier cosa; portátil del integrador conectado directo
  a la red de proceso.
- ❌ **Publicar credenciales por defecto de fabricantes, payloads listos o bypasses concretos
  de producto.** Esta skill es metodología y gobernanza, no recetario ofensivo; el ejercicio
  ofensivo va con alcance y autorización por escrito (`offensive-security-standards`).
- ❌ Declarar "cumplimos 62443 SL 2" sin vector por FR, sin alcance y sin distinguir
  SL-T/SL-C/SL-A.

## 8. Verificación web obligatoria

Antes de fijar norma, edición, cifra o fecha en un entregable:

1. **Edición vigente de cada parte de IEC 62443** que cites (2-1, 3-2, 3-3, 4-1, 4-2) y su
   adopción nacional (ANSI/ISA, EN IEC); las citas de SL y FR se piden **verbatim**.
2. **NIST SP 800-82**: revisión vigente (Rev. 3 a agosto de 2026) y si hay errata publicada.
3. **NIS2 en España**: si la Ley de Coordinación y Gobernanza de la Ciberseguridad se publicó
   en el BOE, plazos de registro y de notificación, y estado del expediente INFR(2024)0270.
4. **CRA (UE 2024/2847)**: fechas de aplicación y si EN IEC 62443-4-1/4-2 ya figuran como
   normas armonizadas.
5. **Avisos de fabricante y CISA ICS advisories** de los modelos concretos en planta, y su
   ciclo de vida y fin de soporte.
6. **Estado de OPC UA**: políticas de seguridad vigentes y obsoletas en
   `profiles.opcfoundation.org`, y qué soporta de verdad la versión de firmware instalada.
7. **Informes anuales de amenaza OT** (Dragos, Claroty, Waterfall) para actualizar cifras;
   **cita año e informe o no uses la cifra**.

**Hueco declarado**: las citas de SL 1-4 y de los siete FR se han contrastado contra fuentes
secundarias coincidentes, no contra el PDF de pago de IEC 62443-3-3; **verifica contra el
texto oficial antes de usarlas en un documento contractual o de auditoría.**

Si la web contradice este documento, **manda la web** y señala la discrepancia.
