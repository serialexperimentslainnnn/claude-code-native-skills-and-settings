---
name: wan-legacy-standards
description: The inherited wide-area network that is still carrying production traffic, and the replace-or-keep decision. Use when working with an MPLS L3VPN or L2VPN/VPLS service, VRF-lite and route distinguishers, route targets and import/export policy, a CE-PE handover and the contractual class-of-service and SLA that justifies the price, pseudowires, martini circuits, Carrier Ethernet EVPL/EPL and MEF service definitions, DIA versus a leased line versus broadband with a tunnel, a hybrid WAN or an SD-WAN migration and its cloud control plane dependency, Cisco Catalyst SD-WAN / Viptela vManage, Versa, Silver Peak, VeloCloud, Frame Relay DLCI and LMI, ATM PVC and AAL5, X.25, ISDN BRI/PRI and backup dial, leased serial lines, E1/T1, G.703, V.35, RS-232 and RS-485 telemetry circuits, a PSTN/POTS or copper switch-off notice, WLR withdrawal and stop sell, analogue modems and dial-up for out-of-band access, point-to-point circuits feeding SCADA and telecontrol, LLQ/CBWFQ and shaping on a slow link, compression and fragmentation-and-interleave, or a circuit whose only job is to serve equipment nobody is allowed to touch.
---

# Estándares de WAN heredada — MPLS, circuitos antiguos y la decisión de sustituir

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **la red de área extensa que ya existe y que no se diseñó ayer**: servicios MPLS de
operador (L3VPN, L2VPN/VPLS) y su contrato; circuitos dedicados, Carrier Ethernet y acceso a
Internet dedicado; la sustitución por **SD-WAN** y su coste real; la **tecnología de circuito
heredada** que sigue viva (Frame Relay, ATM, RDSI/ISDN, X.25, líneas serie, módems); los
**calendarios regulatorios de apagado** de cobre y de RTC/PSTN, que son el disparador forzoso de
la mayoría de estas migraciones; la QoS en enlaces lentos; y el criterio de **sustituir frente a
mantener** cuando el circuito sirve a algo que no se puede tocar.

Triggers: `VRF`, `route-target`, `route-distinguisher`, `mpls`, `xconnect`, `pseudowire`, VPLS,
`DLCI`, `LMI`, `PVC`, `AAL5`, `BRI`/`PRI`, `X.25`, `V.35`, `G.703`, E1/T1, RS-232/RS-485;
vManage/Catalyst SD-WAN, Versa, VeloCloud, Silver Peak; "WLR withdrawal", "stop sell", "apagado
del cobre", "switch-off RTC/PSTN", "all-IP"; `service-policy`, `shape average`, `priority`, LLQ,
CBWFQ, LFI; "backup por RDSI", "línea de telecontrol", "circuito punto a punto".

**No aplica** — el catálogo ya reparte esto: `networking-standards` es la **troncal**
(direccionamiento, VLAN, MTU/MSS, proxies, overlays, plano OOB) y **ya delega la profundidad**;
`routing-switching-standards` decide la **política BGP** hacia el exterior, el IGP de sede, RPKI y
la QoS de campus (**aquí sólo la QoS del enlace lento de WAN y el CE-PE**);
`datacenter-fabric-standards` decide la malla interna y **el peligro de estirar capa 2** por DCI
(**aquí, VPLS como servicio contratado, no como diseño de DC**); `vpn-standards` decide el **túnel
y el concentrador** (WireGuard, IPsec/IKEv2, OpenVPN) — aquí sólo **cuándo un túnel sobre Internet
sustituye a un circuito contratado y qué se pierde**; `firewall-policy-standards` (qué atraviesa);
`network-automation-standards` (cómo se aplica el cambio); `network-troubleshooting-standards`
(método reactivo); `load-balancing-standards`, `dns-standards`;
`network-vendors-standards` (**modelo operativo, licencias, EoS y riesgo del fabricante del CPE —
incluida la dependencia del plano de control SD-WAN como bloqueo de proveedor**);
`telco-5g-standards` (red del operador vista desde dentro: 5G SA/NSA, slicing, APN, NB-IoT/LTE-M y
**el 5G FWA como acceso**). Hacia fuera: **`ot-ics-security-standards` posee la seguridad del
sistema industrial** —zonas y conductos ISA/IEC 62443, protocolos de campo, el SIS— y aquí sólo se
decide **qué circuito lo transporta y cómo se sustituye sin parar el proceso**;
`bcdr-standards` (RTO/RPO que justifican el enlace de respaldo), `finops-standards` (coste
recurrente del circuito), `observability-standards` (telemetría del enlace),
`edge-computing-standards`, `offensive-security-standards` (**esta skill
es defensiva**).

## 2. Decisiones por defecto

> Verificar por web el estado real del servicio, su fin de comercialización y **el calendario
> regulatorio del país concreto** antes de fijar nada (§8). Las fechas de apagado **cambian y se
> retrasan**, y difieren por país y por operador.

| Situación | Por defecto | Alternativa justificable |
|---|---|---|
| Sede nueva, tráfico mayoritario a SaaS/cloud | **Acceso a Internet dedicado (DIA) + túnel cifrado**, doble operador | MPLS si hay requisito contractual de SLA extremo a extremo |
| Sede con tráfico interactivo crítico entre sedes propias | MPLS L3VPN **o** SD-WAN sobre dos accesos con SLA de acceso | Enlace dedicado punto a punto si la latencia es el requisito duro |
| Respaldo de sede | **Segundo acceso de medio distinto** (fibra + móvil), no segundo circuito del mismo operador por la misma canalización | Sólo un acceso, si el RTO lo permite por escrito |
| Circuito heredado que sirve a un sistema intocable | **Mantener y aislar** hasta que exista ventana de parada del proceso | Sustituir sólo con plan de reversión probado y ventana acordada con operaciones |
| Migración forzada por apagado regulatorio | Empezar **24 meses antes** de la fecha firme | — |
| Extender capa 2 entre sedes (VPLS/EPL) | **Evitar**. Enrutar | Sólo si una aplicación lo exige y está documentado el dominio de fallo |
| Módem analógico / RDSI como acceso de rescate | **Sustituir por módem celular en red de gestión OOB** | — |

## 3. Estructura y convenciones

### MPLS: qué se compra realmente

Lo que un operador vende como "MPLS" es **casi siempre L3VPN (RFC 4364)**: el CE entrega rutas al
PE por un protocolo de enrutado (eBGP, OSPF o estático), el PE las mete en una **VRF** identificada
por un *route distinguisher*, y la pertenencia a la VPN se controla con **route targets** de
importación y exportación. El cliente no ve la etiqueta MPLS: ve una nube que enruta.

- **El RD desambigua, el RT decide la pertenencia.** Confundirlos produce topologías VPN mal
  formadas (hub-and-spoke que resulta ser malla, extranets que filtran). En el lado cliente esto
  importa cuando se piden topologías no triviales: **exigir al operador el diseño de RT por escrito**.
- **L2VPN / VPLS** entrega Ethernet: pseudowires punto a punto (EPL/EVPL en lenguaje MEF) o un
  dominio de difusión multipunto. Se compra "porque es transparente", y esa transparencia es el
  problema: **un bucle o una tormenta en una sede se propaga a todas**. Si se contrata, va con
  control de tormenta, límite de MAC y una razón escrita.
- **MTU**: el encapsulado del operador reduce la MTU útil. Negociar **MTU de 1600+ en el acceso** o
  asumir MSS clamping y fragmentación. Es la causa raíz clásica de "todo va bien menos las
  transferencias grandes".

**Lo que justifica el precio y no lo da Internet** — es el único argumento honesto a favor de MPLS:

1. **SLA contractual extremo a extremo con penalización**: disponibilidad, latencia, *jitter* y
   pérdida **entre sedes**, medidos por el operador y con crédito por incumplimiento. En Internet
   sólo se contrata el **acceso**; el trayecto entre operadores no lo garantiza nadie.
2. **Clases de servicio respetadas en el núcleo del operador**, no sólo en el CPE. Marcar DSCP en
   Internet es marcar para nadie.
3. **Un único responsable** cuando falla: no hay reparto de culpa entre dos ISP.
4. **Entrega privada** sin exposición a Internet (aunque **el tráfico no va cifrado por defecto**:
   MPLS aísla, no cifra — véase §5).

**Criterio**: si el requisito no se puede escribir como cláusula con penalización, **no hay caso de
negocio para MPLS**. Si sí se puede, el precio compra algo real.

### SD-WAN: qué resuelve y qué compra a cambio

Lo que resuelve **de verdad**, y es bastante:

- Usar **varios accesos heterogéneos simultáneamente** con selección de camino por aplicación y por
  medición activa (pérdida/latencia/jitter), no por métrica estática.
- **Salida directa a Internet/SaaS** desde la sede en vez de retorno al datacenter, con la política
  aplicada en el borde.
- **Aprovisionamiento de sede** en horas en vez de en el plazo de instalación de un circuito.
- Política y plantillas centralizadas en vez de configuración por equipo.

Lo que añade, y suele omitirse en la decisión:

- **Dependencia del plano de control**, habitualmente en la nube del fabricante (orquestador y
  controladores). Preguntar por escrito: ¿qué pasa en la sede si el orquestador es inalcanzable
  durante horas? ¿Y durante días? ¿El túnel sobrevive? ¿Se puede recuperar sin él? La respuesta
  correcta es "el plano de datos sigue con la última política"; **hay que verificarla en laboratorio,
  no creerla**.
- **Bloqueo de proveedor fuerte**: CPE, licencias por sede, orquestador y modelo de política son
  propietarios y no intercambiables. Es una decisión de bloqueo (`network-vendors-standards`), no
  una compra de cajas.
- **Superficie nueva**: el orquestador es un objetivo de alto valor. Los controladores SD-WAN han
  acumulado vulnerabilidades críticas de autenticación (véase `vpn-standards` §historial). Va tras
  MFA, aislado y parcheado con la misma urgencia que un IdP.
- **Migración de la responsabilidad del SLA al cliente**: con dos accesos de Internet, el que
  responde por la calidad extremo a extremo eres tú.

**Cuándo NO migrar** — el criterio honesto:

- Cuando el requisito real es un **SLA contractual entre sedes** con penalización (véase arriba).
- Cuando hay **pocas sedes** (menos de ~10–15): el coste de licencias, orquestador e implantación no
  se amortiza contra el ahorro de circuito.
- Cuando el tráfico sigue siendo **mayoritariamente entre sedes propias y sensible a jitter** (voz
  interna, aplicaciones de terminal, protocolos industriales) y no a SaaS.
- Cuando el operador de acceso alternativo **es el mismo y por la misma canalización**: entonces no
  hay diversidad, sólo dos facturas.
- Cuando el equipo no tiene capacidad de operar el nuevo modelo. Un SD-WAN mal operado es peor que
  un MPLS aburrido que lleva ocho años funcionando.

> **Cifras de ahorro: folclore de fabricante.** Las cifras publicadas de ahorro de SD-WAN frente a
> MPLS van del **20 % al 90 %** según la fuente, y **no se localizó ningún estudio independiente con
> metodología transparente**. Los defectos son estructurales y repetidos: (a) atribuyen a SD-WAN
> ahorros que vienen de **consolidar proveedores a la vez**; (b) comparan una factura MPLS "todo
> incluido" contra **sólo la línea de ancho de banda** del diseño nuevo, omitiendo licencias, CPE,
> implantación y gestión; (c) omiten costes únicos (implantación e instalación por sede); (d)
> extrapolan desde parques de cientos de sedes; (e) presentan **modelos ilustrativos** como
> resultados medidos. Como contrapunto útil, una consultora independiente del sector documentó un
> caso real donde el ahorro en ancho de banda fue del **10 %** y aun así recomendó la migración por
> resiliencia y caudal. **Regla: no citar un porcentaje de ahorro que no salga de la propia
> factura.** El caso de negocio se construye con los precios ofertados a tu empresa, para tu número
> de sedes, con los costes únicos dentro.

### Lo que sigue vivo, y por qué

| Tecnología | Estado | Dónde sobrevive y por qué |
|---|---|---|
| **Frame Relay** (DLCI, LMI) | Retirado por los grandes operadores hace años; listados residuales/*grandfathered* en tarifas mayoristas | Islas heredadas con interworking FR↔ATM. **No se contrata nada nuevo** |
| **ATM** (PVC, AAL5) | Igual: residual | Backhaul heredado y algún acceso empresarial antiguo |
| **X.25** | Prácticamente extinto en red pública | Terminales financieros y de telecontrol muy antiguos, casi siempre **emulado sobre IP (XOT)**, no nativo |
| **RDSI/ISDN** (BRI/PRI) | Se apaga con la RTC: **la RDSI depende de la misma infraestructura** | Cabeceras de telefonía antiguas, respaldo dial y ascensores. **PRI se sustituye por SIP trunk** |
| **Líneas serie / E1-T1, V.35, G.703** | Se contratan aún como circuito dedicado, cada vez peor | Telecontrol, protección de subestación, sincronía |
| **RS-232 / RS-485 punto a punto** | Vivo y sano en planta | Telecontrol y campo. Se extiende con conversores serie-Ethernet, **que es exactamente donde se cuela el riesgo** (§5) |
| **Módem analógico / dial-up** | Muere con la RTC | Acceso de rescate OOB. **Sustituir por celular**, no por "otro módem" |

### El apagado del cobre y de la RTC — dato duro, y varía por país

**Es el disparador forzoso**: no es una modernización opcional, es una fecha con la que se pierde el
servicio. Verificar **siempre** el calendario del país y del operador (§8).

- **España — completado.** La CNMC lo publica sin ambigüedad: *"27 de mayo de 2025. Hoy se completa
  en España el proceso de cierre de las centrales de cobre"*, apagándose *"las últimas (661
  centrales, distribuidas por toda la geografía)"* (blog de la CNMC, 27-05-2025). El parque total
  fueron 8 532 centrales; las dos primeras se cerraron en 2014. El cierre lo supervisó la CNMC por
  el procedimiento de los análisis de mercados mayoristas, **con fecha en firme por central
  comunicada con antelación**. Consecuencia práctica: en España **no queda ADSL sobre par de cobre
  de Telefónica, ni RTC, ni RDSI sobre esa red**. Si un plan de proyecto español todavía asume una
  línea analógica o un PRI de cobre, está mal.
- **Reino Unido — en curso, con fecha desplazada.** El *stop sell* de WLR es de septiembre de 2023 y
  el apagado de PSTN/WLR se retrasó desde el 31-12-2025 a **enero de 2027**. **Dato tomado de
  fuentes secundarias del sector, no de Openreach en primera fuente: verificar (§8)**; hay
  circulación simultánea de "diciembre de 2027", que parece incorrecta. ISDN2/ISDN30 caen con ello, y
  el ADSL asociado a una WLR muere con la línea aunque nadie use el teléfono.
- **Alemania — completada la migración a all-IP** en el entorno de 2020 (la migración mayorista de
  líneas de datos se declaró completa en mayo de 2020; las líneas de voz pura y RDSI multiterminal
  se arrastraron después). **Las fuentes discrepan sobre la fecha final exacta: verificar en las
  notas de prensa de Deutsche Telekom si el dato decide algo (§8).**
- **Estados Unidos — acelerado por regulación en 2026.** La FCC adoptó en marzo de 2026 una orden
  que facilita la retirada del cobre: permite *grandfathering* de servicios heredados (se mantienen
  a clientes existentes pero **no se venden a nuevos** y se pueden discontinuar antes), elimina
  requisitos de notificación de cambio de red y simplifica la discontinuación por transición
  tecnológica, aunque **sigue haciendo falta autorización de la FCC** cuando la retirada implica
  discontinuar el servicio. **No se pudo obtener cita verbatim del documento oficial (§8).**
  Consecuencia: en EE. UU. el riesgo inmediato no es el apagado, es **quedarse sin poder trasladar
  ni contratar** un circuito TDM heredado.

**Criterio operativo**: por cada país donde haya sedes, mantener una **tabla con la fecha firme, la
fecha de *stop sell* y la fecha de fin de traslados**. El *stop sell* llega mucho antes que el
apagado y es el que rompe los proyectos: impide dar de alta o mover un circuito que el plan daba por
disponible.

### QoS en enlaces lentos

Sigue existiendo, y la mayoría de la doctrina moderna de QoS **no aplica** a un enlace de 2 Mbps:

- **Modelar (*shape*) al caudal contratado**, no al del interfaz físico. Si el operador entrega
  10 Mbps sobre un puerto Gigabit, sin *shaping* la cola está en el operador y la QoS del CPE no
  hace nada. **Este es el error más frecuente de la WAN.**
- **Una sola cola de prioridad estricta (LLQ), acotada**, para voz/control. Si todo es prioritario,
  nada lo es.
- **Fragmentación e intercalado (LFI)** deja de ser necesario por encima de ~768 kbps; por debajo,
  sin él un paquete grande introduce un retardo de serialización que arruina la voz.
- La marca sólo vale **dentro de un dominio que la respete**. Marcar hacia Internet no hace nada;
  hacia un PE de MPLS hace lo que diga el contrato de clase de servicio (que hay que leer: el mapeo
  DSCP→clase del operador rara vez coincide con el interno).

## 4. Calidad y verificación

- **Prueba de aceptación del circuito antes de ponerlo en producción**: caudal en ambos sentidos,
  latencia y jitter en carga, pérdida sostenida, y **comportamiento en fallo del enlace primario**
  (tiempo real de conmutación, no el del folleto). Se documenta y se archiva: es la línea base contra
  la que se reclamará el SLA.
- **Probar el respaldo de verdad, con corte real del primario y en horario acordado.** Un enlace de
  respaldo nunca probado no existe, exactamente igual que un backup nunca restaurado
  (`bcdr-standards`).
- **Verificar la diversidad física**, no la lógica. Pedir al operador confirmación escrita de que
  los dos accesos no comparten canalización, arqueta ni central. Es habitual descubrir que sí.
- **Antes de tocar un circuito de telecontrol**: inventario de qué depende de él, ventana acordada
  con operaciones/planta, y **plan de reversión probado**. La aceptación la firma quien opera el
  proceso, no la red.

## 5. Seguridad

- ❌ **MPLS no cifra.** Es aislamiento por etiquetado y confianza en el operador, no
  confidencialidad. **Todo tráfico sensible va cifrado también sobre MPLS** (IPsec o MACsec según
  el caso). Que el operador diga "es una red privada" no es un control criptográfico.
- **Un CE es un equipo expuesto**: el PE del operador está fuera de tu dominio de confianza.
  Filtrado en el CE, autenticación de la sesión de enrutado (BGP con TCP-AO o MD5 según soporte),
  límite de prefijos recibidos, y ninguna gestión escuchando hacia el lado WAN.
- **Circuitos serie y telecontrol**: no tienen autenticación ni integridad. **El control compensatorio
  es físico y de segmentación** —la zona y el conducto los decide `ot-ics-security-standards`—; lo que
  se decide aquí es que **poner un conversor serie-Ethernet en una red rutable convierte un riesgo
  físico en un riesgo remoto**. Si se hace: red dedicada, sin salida a Internet, sin exposición de la
  gestión del conversor, y con el cambio aprobado por el dueño del proceso.
- **RDSI y módems de rescate**: un módem que descuelga es un acceso sin autenticación fuerte y sin
  registro. Si existe uno en el parque, es un hallazgo, no una feature. Sustituir por acceso OOB
  celular con MFA y registro (`vpn-standards`, `identity-access-management-standards`).
- **La migración es el momento de mayor exposición**: convivencia de dos caminos, reglas duplicadas y
  temporales que se quedan, y política que se relaja "hasta que estabilice". Toda excepción de
  migración lleva **fecha de caducidad escrita** (`firewall-policy-standards`).
- **Al retirar un circuito**: baja formal ante el operador, retirada de reglas asociadas,
  actualización del inventario y **borrado seguro del CPE devuelto** (contiene claves, certificados y
  configuración completa de tu red).

## 6. Operabilidad

- **Medir el enlace de forma independiente del operador**: sondas activas extremo a extremo
  (latencia, jitter, pérdida) y disponibilidad medida por ti. Sin medición propia, la reclamación de
  SLA es una discusión de opiniones. Qué se instrumenta y con qué umbral es de
  `observability-standards`; **lo que decide esta skill es que se mide, y que la métrica pactada en
  el contrato es la que se instrumenta**.
- **Leer el SLA como ingeniero**: qué se mide, dónde se mide, cómo se calcula la disponibilidad
  mensual, qué se excluye (mantenimiento programado, causas de fuerza mayor, fallo del acceso
  radioeléctrico), cuál es el MTTR comprometido y **cómo se reclama el crédito**. Un SLA con crédito
  del 5 % de la cuota no es un incentivo: es decorativo.
- **Inventario de circuitos como dato de primera clase**: identificador del operador, ubicación,
  caudal, fecha de alta, fecha de renovación, penalización por cancelación anticipada, contacto de
  incidencias y **a qué sistemas sirve**. La mitad del gasto en WAN heredada es de circuitos que
  nadie sabe para qué son y nadie se atreve a cortar.
- **Método para cortar lo que no se sabe qué es**: instrumentar el tráfico, comprobar utilización
  durante un ciclo de negocio completo (incluidos cierres mensuales y anuales), avisar, **apagar de
  forma reversible** (bloqueo administrativo, no baja contractual) y esperar. Sólo después, la baja.

## 7. Sostenibilidad y prohibiciones

- Revisar el parque de WAN **anualmente** contra los calendarios de apagado y contra las fechas de
  renovación contractual. La renovación automática a tres años de un circuito obsoleto es cómo se
  paga cobre en 2029.
- Todo circuito heredado que se mantiene por decisión lleva **fecha de revisión y motivo escrito**
  ("sirve al PLC de la línea 3, sin ventana de parada hasta la parada anual de agosto"). Deuda
  consciente, no olvido.
- Documentar en ADR la decisión MPLS/SD-WAN/Internet con la condición que la reabriría (fin de
  contrato, apertura de sedes, cambio del perfil de tráfico a SaaS).

Prohibiciones:

- ❌ **PROHIBIDO** citar un porcentaje de ahorro de SD-WAN que no proceda de las ofertas y facturas
  reales del proyecto. Las cifras publicadas (20–90 %) son material comercial sin metodología.
- ❌ **PROHIBIDO** planificar una migración forzada por apagado regulatorio con menos de 24 meses, o
  ignorando la fecha de ***stop sell***, que llega mucho antes y es la que bloquea altas y traslados.
- ❌ **PROHIBIDO** escribir de memoria una fecha de apagado de cobre, RTC o RDSI. **Varía por país,
  por operador y se retrasa** (§8).
- ❌ **PROHIBIDO** tratar MPLS como transporte cifrado.
- ❌ **PROHIBIDO** contratar dos accesos "redundantes" sin confirmación escrita de diversidad física.
- ❌ **PROHIBIDO** dar por bueno un enlace de respaldo que no se ha conmutado nunca con corte real.
- ❌ **PROHIBIDO** exponer a una red rutable un conversor serie-Ethernet o una pasarela de telecontrol
  sin aprobación del dueño del proceso y sin segmentación dedicada.
- ❌ **PROHIBIDO** dejar un módem analógico o RDSI de rescate en el parque como acceso de emergencia.
- ❌ **PROHIBIDO** aplicar QoS en el CPE sin *shaping* al caudal contratado: la cola queda en el
  operador y la política no hace nada.
- ❌ **PROHIBIDO** estirar capa 2 entre sedes (VPLS/EPL) sin una razón escrita y sin límite de MAC y
  control de tormenta.
- ❌ **PROHIBIDO** devolver un CPE al operador sin borrado seguro de su configuración y sus claves.
- ❌ **PROHIBIDO** dar de baja un circuito que sirve a un sistema industrial sin ventana acordada con
  operaciones y plan de reversión probado.

## 8. Verificación web obligatoria

Comprobar **siempre**, en fuente primaria (regulador nacional, operador incumbente, contrato):

1. **Calendario de apagado del cobre y de la RTC/PSTN del país concreto** y del operador
   incumbente, más la **fecha de *stop sell*** y la fecha de fin de traslados. Es el dato que más
   se afirma mal y **cambia por país**. España: CNMC (completado 27-05-2025). Reino Unido:
   Openreach (**cifra de enero de 2027 tomada de prensa sectorial, no de Openreach — verificar**).
   Alemania: Deutsche Telekom (fuentes discrepantes sobre la fecha final). EE. UU.: órdenes de la
   FCC sobre retirada de cobre y discontinuación §214.
2. **Fin de comercialización y de soporte** del servicio concreto en el catálogo del operador
   (Frame Relay, ATM, PRI, líneas serie): pedirlo por escrito, no deducirlo.
3. **Texto del SLA vigente**: métricas, puntos de medida, exclusiones, MTTR y procedimiento de
   crédito. Y el **mapeo DSCP → clase de servicio** del operador.
4. **Penalización por cancelación anticipada** y fecha de renovación automática de cada circuito.
5. **Modelo de fallo del plano de control SD-WAN** del fabricante candidato: qué sobrevive en la
   sede sin orquestador y durante cuánto tiempo. Y sus **avisos de seguridad abiertos** para el
   orquestador y los controladores (`network-vendors-standards`).
6. **Estado de la propuesta regulatoria europea** que afecte a proveedores de alto riesgo si el CPE
   o el equipo de acceso es de un fabricante restringido (`network-vendors-standards` §5).

**Huecos declarados**: (a) la fecha de apagado PSTN del Reino Unido y la fecha final exacta del
apagado RDSI en Alemania proceden de resúmenes de búsqueda y de prensa sectorial, no de la fuente
primaria — **no usar sin verificar**. (b) No se obtuvo cita verbatim de la orden de la FCC de marzo
de 2026: el PDF oficial (`docs.fcc.gov`) no se pudo convertir a texto legible; el contenido descrito
procede de resúmenes. (c) No se localizó **ningún** estudio independiente y metodológicamente
transparente sobre ahorro de SD-WAN frente a MPLS; por eso esta skill prohíbe citar porcentajes.
(d) No se verificó el estado de comercialización de Frame Relay/ATM operador por operador: sólo
consta que las retiradas son mayoritariamente históricas y que quedan listados residuales.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
