---
name: telco-5g-standards
description: Mobile operator networks from the point of view of whoever integrates or buys them, including private cellular. Use when deciding between 5G Non-Standalone and Standalone (NSA option 3x versus SA option 2) and which features actually exist in each, working with 5G core network functions AMF, SMF, UPF, AUSF, UDM, NRF, NSSF, PCF and the service-based interface, gNB / CU / DU / RU functional split, Open RAN and the fronthaul, network slicing and S-NSSAI, SST and SD values, a slice SLA and GSMA GST/NEST templates, a private or campus 4G/5G network and its spectrum regime (licensed, locally assigned, shared, CBRS, Bundesnetzagentur 3.7-3.8 GHz local assignments, the Spanish CNAF and autoprestación), deciding between private cellular and enterprise wireless LAN, ETSI MEC and a local UPF breakout, SIM, eUICC and eSIM remote provisioning with GSMA SGP.22 or SGP.32 and an eIM, IMSI/SUPI/SUCI and device identity, IMEI, cellular IoT with NB-IoT, LTE-M or RedCap and 2G/3G sunset dates, a private APN, static IP SIMs and roaming agreements, SS7, SIGTRAN and Diameter interconnect exposure, SEPP and the N32 interface with PRINS (3GPP TS 33.501), or someone proposing that a SIM card counts as application authentication.
---

# Estándares de red de operador y 5G — lo que se contrata, lo que se integra y lo que no existe

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando hay que **integrar, contratar, dimensionar o asegurar conectividad celular**, ya sea
de un operador público o de una red privada propia: elección entre NSA y SA y sus consecuencias
reales; el núcleo 5G (5GC) y sus funciones; *network slicing* y qué garantiza contractualmente;
**redes privadas 4G/5G** y su régimen de espectro; MEC y la ruptura local del plano de usuario;
identidad del dispositivo (SIM/eSIM/eUICC, IMSI/SUPI); IoT celular (NB-IoT, LTE-M, RedCap) y los
apagados de 2G/3G; APN privados, IP fija y *roaming*; y la **seguridad del modelo de confianza del
operador**.

Triggers: `5GC`, `AMF`, `SMF`, `UPF`, `AUSF`, `UDM`, `NRF`, `NSSF`, `PCF`, `SBI`, `gNB`, `CU`/`DU`/
`RU`, `N2`/`N3`/`N6`/`N32`, `S-NSSAI`, `SST`, `SD`, `SUPI`, `SUCI`, `SUPI ocultado`, `IMSI`,
`eUICC`, `SGP.22`, `SGP.32`, `eIM`, `SEPP`, `PRINS`, `NB-IoT`, `LTE-M`, `RedCap`, `CBRS`, `APN`,
`URLLC`, `eMBB`, `mMTC`, ETSI MEC; "red privada 5G", "campus network", "autoprestación",
"apagado 2G/3G", "SIM con IP fija".

**No aplica** — fronteras duras: **el radioenlace Wi-Fi es de `wireless-standards`** (802.11ax/be,
6 GHz, encuesta de sitio, WPA3, 802.1X sobre WLAN — aquí sólo **cuándo una privada celular gana o
pierde frente a Wi-Fi**); **el cómputo en el borde es de `edge-computing-standards`**
(aquí sólo el UPF local y qué habilita MEC, no cómo se opera la plataforma de
cómputo); **el dispositivo embebido es de `embedded-iot-standards`**
(firmware, consumo, actualización OTA del dispositivo). Además: `networking-standards`
(**troncal**: direccionamiento, VLAN, MTU, la red IP donde aterriza el APN),
`wan-legacy-standards` (MPLS, SD-WAN, circuitos heredados y **el acceso móvil como respaldo de
sede o FWA**), `network-vendors-standards` (modelo operativo, licencias, EoS y **riesgo
regulatorio del fabricante de RAN**), `routing-switching-standards`, `firewall-policy-standards`
(la política que filtra lo que sale del APN), `vpn-standards` (el túnel que **sí** autentica al
dispositivo), `identity-access-management-standards` (**la identidad de aplicación y su
autenticación — la SIM no es eso, §5**), `ot-ics-security-standards` (el sistema industrial que
usa la privada), `observability-standards`, `high-speed-interconnect-standards`,
`offensive-security-standards` (**esta skill es defensiva**).

## 2. Decisiones por defecto

> Verificar por web el estado de despliegue del operador, la disponibilidad real de cada prestación
> **en la cobertura concreta**, y el **régimen de espectro del país** antes de fijar nada (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Conectividad de sede | Fija (fibra/DIA) como primaria; **celular como respaldo de medio distinto** | FWA 5G como primaria sólo donde no hay fibra, con SLA leído |
| Cobertura industrial interior de datos | **Wi-Fi** bien diseñado (`wireless-standards`) | Privada celular si se cumple el checklist de §3 |
| Arquitectura celular a exigir en pliego | **SA**, si se necesita slicing, latencia acotada, IP fija o UPF local | NSA es aceptable para banda ancha sin más |
| Identidad del dispositivo IoT | **eSIM/eUICC con provisión remota** (SGP.22 consumo / SGP.32 IoT) | SIM física soldada (MFF2) en entornos sin gestión remota |
| Tecnología IoT celular | **LTE-M** si hay movilidad, voz o latencia; **NB-IoT** si es telemetría estática de bajo caudal | RedCap para gama media si el operador y el módulo lo soportan |
| Salida a datos del dispositivo | **APN privado con entrega a red propia** y filtrado en el borde | APN público **sólo** con túnel cifrado extremo a extremo |
| Autenticación de la aplicación sobre celular | Certificado de cliente / mTLS / token, **independiente de la SIM** | — (no hay alternativa: §5) |

## 3. Arquitectura — qué es cada cosa y qué decide

### NSA frente a SA: la diferencia decide qué prestaciones existen

- **NSA (Non-Standalone, opción 3x)**: la radio 5G (gNB) se ancla en un **eNB LTE** y en el
  **núcleo EPC de 4G**. Da más caudal y poco más. **No hay 5GC**, luego **no hay slicing, ni
  URLLC, ni ruptura local del plano de usuario, ni las funciones de seguridad nuevas del 5G**.
- **SA (Standalone, opción 2)**: gNB contra un **5GC** completo. Es donde existen de verdad el
  *slicing*, el UPF distribuible, la ocultación del identificador permanente (SUCI) y las
  prestaciones de baja latencia.

**Consecuencia práctica y no negociable**: si una oferta comercial promete *slicing*, latencia
determinista o ruptura local, **hay que exigir por escrito que la cobertura de las ubicaciones
concretas es SA**, no que "el operador tiene 5G SA". La mayoría del despliegue mundial sigue siendo
NSA: según datos de GSA recogidos en 2026, del orden de **95 operadores** habían lanzado 5G SA
frente a **~390 operadores con 5G lanzado** — aproximadamente **una cuarta parte**. Las cifras
varían por edición del informe (85/89/95 según fecha y si se cuentan lanzamientos blandos): **citar
la edición exacta y verificar (§8)**.

### 5GC: qué hace cada función y por qué importa al que integra

- **AMF** — gestión de acceso y movilidad; es el punto de terminación de la señalización del
  terminal (N1/N2). Es **plano de control**: si cae, no se registran ni se mueven dispositivos.
- **SMF** — gestión de sesión: establece la sesión PDU, asigna dirección IP y **controla al UPF**.
- **UPF** — **el único elemento del plano de usuario**. Es el que se puede **distribuir**: ponerlo
  cerca de la sede es lo que da latencia baja y lo que permite que el tráfico **no salga** a la red
  del operador. Sin SA no hay UPF que colocar.
- **AUSF / UDM / UDR** — autenticación y datos de suscripción (el equivalente evolucionado del HSS).
- **NRF** — registro y descubrimiento de funciones; **NSSF** — selección de *slice*; **PCF** —
  política (QoS, caudal, tarificación).
- **SBI** — las funciones se hablan por **HTTP/2 + JSON con API REST**, no por protocolos de
  telecomunicación clásicos. Consecuencia enorme: **el núcleo móvil es hoy una arquitectura de
  microservicios**, con sus mismos problemas (autorización entre servicios, gestión de certificados,
  descubrimiento) y sus mismas herramientas. Un ingeniero de plataformas entiende un 5GC mejor de lo
  que espera.
- **RAN**: gNB partido en **CU / DU / RU**. Open RAN abre esas interfaces (fronthaul). Para el
  integrador esto sólo importa si va a operar RAN propia; en una privada gestionada, no.

### Network slicing: qué garantiza y qué no

- Un *slice* se identifica con **S-NSSAI** = **SST** (tipo de servicio: eMBB, URLLC, mMTC…) + **SD**
  (diferenciador opcional). El terminal pide un *slice*; la red decide si lo concede.
- **Lo que el slicing es de verdad**: aislamiento lógico de recursos de núcleo y política de QoS
  diferenciada, con la **radio como recurso compartido salvo que se reserve explícitamente**.
- ❌ **Lo que no es**: una garantía física. Si el contrato no fija **caudal mínimo, latencia máxima,
  disponibilidad, punto de medida y penalización**, el *slice* es un ajuste de prioridad con nombre
  de marketing.
- **Qué exigir por escrito**: los parámetros del *slice* (GSMA usa plantillas GST/NEST como
  vocabulario común — verificar la versión aplicable, §8), **dónde se mide**, con qué periodicidad,
  qué ocurre en congestión, y **si la reserva alcanza al recurso radio o sólo al núcleo**. Sin eso,
  no hay SLA, hay una etiqueta.
- Un *slice* **no sustituye al cifrado**: es segmentación del operador, exactamente igual que MPLS
  (`wan-legacy-standards` §5).

### Redes privadas 4G/5G: espectro y criterio de decisión

**El espectro es el primer filtro, y es nacional.** Modelos que conviven:

- **Espectro asignado localmente al usuario final** — el modelo que hace viable la privada de
  verdad. Alemania es el precedente maduro: la Bundesnetzagentur asigna localmente **3 700–3 800
  MHz** para redes propias, por finca o recinto empresarial, con tasa calculada por **superficie y
  años de asignación**; los titulares publicados incluyen industria pesada, automoción, logística
  portuaria y agrícola. **El número actual de asignaciones no se verificó** (§8), y la lista
  publicada es incompleta por secreto comercial: sólo aparecen quienes consintieron.
- **España** — el nuevo **Cuadro Nacional de Atribución de Frecuencias (CNAF)**, actualizado por
  orden ministerial en **julio de 2026**, reasigna la banda **3 800–4 200 MHz** (antes de servicio
  fijo por satélite) a uso móvil local, distinguiendo **concesión** (prestada por operador) y
  **autoprestación** (red propia). Reparto informado: **3 800–3 920 MHz** banda ancha local de baja
  y media potencia, en concesión o autoprestación; **3 920–4 020 MHz** Defensa; **3 920–4 120 MHz**
  periodismo electrónico en autoprestación; **4 020–4 120 MHz** autoprestación de banda ancha local.
  Existe además reserva previa para autoprestación en 26 GHz. **Las condiciones exactas (potencias,
  procedimiento, tasas, coordinación con Defensa y con satélite) están en el texto del BOE y en la
  nota UN del CNAF; no se verificaron aquí (§8) y son las que deciden si un despliegue concreto es
  viable.**
- **Espectro compartido** — modelo CBRS (EE. UU., banda 3,5 GHz con coordinación por SAS). Régimen
  distinto y **no extrapolable** a Europa.
- **Espectro del operador** — la privada la despliega y opera el operador sobre su licencia
  (*private network as a service*). Más rápida de contratar; **no es autonomía**: se vuelve a
  depender del operador, y el modelo de continuidad hay que leerlo.

**Cuándo una privada celular gana a Wi-Fi 6E/7** — sólo si se cumplen **varias** de estas:

1. **Cobertura exterior amplia o movilidad real** (puerto, mina, campus grande, AGV que atraviesan
   naves): el traspaso entre celdas celular es de otra categoría que el itinerancia Wi-Fi.
2. **Entorno radioeléctrico hostil** (metal, obstrucción, multitrayecto severo) donde el enlace
   celular con potencia y planificación licenciada se comporta mejor.
3. **Requisito de determinismo con SLA interno**, no "baja latencia" a ojo.
4. **Espectro licenciado disponible** en el país y en la ubicación: sin esto, no hay conversación.
5. **Densidad de dispositivos con perfil de tráfico predecible** y ciclo de vida largo.

**Cuándo es sobreingeniería carísima** — y es el caso mayoritario:

- Oficinas, almacenes cubiertos convencionales, cobertura interior de datos genéricos: **Wi-Fi bien
  diseñado es más barato, más flexible y lo sabe operar más gente**.
- Cuando **los dispositivos no tienen módem celular** ni pueden llevarlo: cada terminal necesita
  módulo y SIM. El coste por dispositivo, multiplicado, suele decidir el proyecto.
- Cuando no hay nadie que vaya a operar un núcleo móvil. Una privada trae RAN, núcleo, gestión de
  SIM, actualizaciones y espectro. **Es una operadora en miniatura**, con su plantilla implícita.
- Cuando el problema real era un mal diseño de Wi-Fi. **Antes de proponer privada celular, exigir
  el estudio de sitio y los datos de la WLAN actual** (`wireless-standards`): la mayoría de las
  quejas de "Wi-Fi que no va" son capacidad, itinerancia o *driver* de cliente, no tecnología.

### MEC y ruptura local

**ETSI MEC** define la plataforma de aplicaciones en el borde del operador; lo que lo hace útil en
red es el **UPF local**: colocar el plano de usuario en la sede o en el borde del operador para que
el tráfico **no atraviese el núcleo central**. Eso es lo que reduce latencia de verdad y lo que
mantiene el dato dentro del recinto.

- Requiere **SA**. En NSA no existe.
- **Qué preguntar**: ¿dónde está físicamente el UPF? ¿La ruptura local es a mi red o a Internet del
  operador? ¿Quién opera la plataforma y con qué SLA? ¿Qué pasa si el enlace al núcleo central cae?
- La operación de la plataforma de cómputo del borde es de `edge-computing-standards`.
  Aquí sólo se decide **la topología del plano de usuario**.

> **Cifras de latencia: folclore de fabricante.** El "1 ms del 5G" es un **objetivo de interfaz
> radio bajo condiciones específicas** de la especificación URLLC (del orden de 1 ms con fiabilidad
> 10⁻⁵ para paquetes pequeños), **no una latencia de aplicación extremo a extremo**. La visión
> NGMN/3GPP situaba el objetivo general en torno a **10 ms extremo a extremo**, con 1 ms reservado a
> casos extremos, y el tramo aire es sólo una parte del total: el núcleo aporta el resto. Las
> medidas independientes en redes comerciales sitúan lo alcanzable en **milisegundos de una cifra en
> el mejor caso** (una evaluación de terceros reporta hasta ~6 ms extremo a extremo) y en la
> práctica de una a dos cifras. El **sub-milisegundo medido se ha observado en capa física, en
> despliegues privados de ondas milimétricas con línea de vista**, no en macro pública. **Regla: no
> citar una latencia que no se haya medido en la ubicación y con el terminal reales.**

## 4. Calidad y verificación

- **Prueba de aceptación en la ubicación real, con el terminal real**: nivel y calidad de señal
  (RSRP/RSRQ/SINR), caudal en ambos sentidos en hora punta, latencia y *jitter* sostenidos,
  comportamiento en movilidad y **tiempo de reconexión tras pérdida de cobertura**. La cobertura del
  mapa comercial no es un dato de ingeniería.
- **Verificar SA de forma independiente**: comprobar en el terminal que registra contra 5GC (no
  ancla LTE) en las ubicaciones concretas. Un pliego que compra SA y recibe NSA es un caso frecuente
  y sólo se detecta midiendo.
- **Probar la degradación**: qué hace el dispositivo cuando el *slice* no está disponible, cuando cae
  a 4G o cuando entra en zona sin cobertura. Un sistema que asume conectividad permanente sobre
  celular está mal diseñado. Reintentos con retardo exponencial y *jitter*, encolado local y
  operación degradada.
- **Prueba de traslado de perfil eSIM** antes de desplegar flota: descargar, activar, desactivar y
  restaurar un perfil en el dispositivo real. **La provisión remota que no se ha ejercitado no
  existe** — y en IoT el fallo típico es un dispositivo que se queda sin perfil activo y sin forma
  de recuperarse por radio.

## 5. Seguridad

### La SIM no es autenticación de aplicación

Es la afirmación más peligrosa de este dominio, y aparece constantemente en diseños IoT.

- La SIM/eUICC autentica **la suscripción frente a la red del operador**. Prueba que ese abonado
  puede usar la red. **No prueba** qué dispositivo es, ni que el firmware sea legítimo, ni que quien
  abre la conexión TCP sea la aplicación esperada.
- Una SIM se **extrae y se pone en otro dispositivo**. Un APN privado es una red, y **cualquier cosa
  dentro de esa red alcanza al servidor**. Un IMSI o una IP de APN **no son credenciales**.
- ❌ **PROHIBIDO** autorizar por IP de origen del APN, por IMSI, por IMEI o por "está en nuestra
  red privada". Todo dispositivo autentica con **credencial de aplicación propia y rotable**
  (certificado de cliente con mTLS, o token con vida corta), y el servidor autoriza por esa
  identidad. La conectividad celular es **transporte**, no identidad.
- El IMEI es un identificador **declarado por el terminal**: sirve para inventario, nunca para
  control de acceso.

### El modelo de confianza de la red del operador

- El plano de usuario **no va cifrado extremo a extremo** por el hecho de ser celular. El cifrado
  radio protege el tramo aire; dentro del operador el tráfico es visible para el operador. **Todo
  dato sensible va cifrado por encima** (TLS o túnel), también sobre APN privado y también sobre
  *slice*.
- **APN privado**: reduce exposición (el tráfico no sale a Internet y aterriza en tu red), y por eso
  mismo **desplaza el perímetro a tu lado**. Se filtra en el punto de entrega con default-deny
  (`firewall-policy-standards`), no se asume limpio.
- **IP fija por SIM**: útil para inventario y correlación. **No es un control de acceso** (véase
  arriba).

### SS7, Diameter e interconexión: la superficie histórica

- La señalización de interconexión heredada —**SS7/SIGTRAN** en 2G/3G y **Diameter** en 4G— se
  diseñó bajo el supuesto de que todos los operadores interconectados eran de confianza. Ese
  supuesto es falso desde hace más de una década: la interconexión se ha explotado para
  localización, interceptación de SMS y fraude. **Consecuencia directa y accionable**: ❌ **el SMS y
  la llamada de voz no son un segundo factor fuerte**. Cualquier diseño que dependa de OTP por SMS
  hereda la superficie del interconectado más débil del planeta (véase
  `identity-access-management-standards`).
- **5G lo aborda de forma estructural** con el **SEPP** (Security Edge Protection Proxy) en la
  frontera de cada red y la interfaz **N32** (3GPP TS 33.501): **N32-c** para gestionar la conexión
  y **N32-f** para los mensajes protegidos. Dos modos: **TLS directo entre SEPP** cuando no hay
  intermediarios, y **PRINS** (*PRotocol for N32 INterconnect Security*) cuando hay proveedores IPX
  en el camino — el mensaje va protegido con **JWE** (RFC 7516) y las modificaciones del IPX se
  añaden como objetos **JWS** (RFC 7515) firmados, que el SEPP receptor valida y aplica. La
  política de modificación se acuerda con el IPX y se intercambia en la negociación N32-c.
- **La letra pequeña que decide**: la GSMA advierte en sus guías de *roaming* 5G que el modelo de
  concentración salto a salto con protección de enlace **no está especificado por 3GPP y no da
  seguridad extremo a extremo entre redes**, sólo TLS entre saltos. Es decir: **tener SEPP no
  garantiza protección extremo a extremo**; depende del modelo desplegado. Si el *roaming* importa
  para el caso de uso, **se pregunta explícitamente por el modelo N32 y se pide por escrito**.
- **Traducción para quien integra, no para quien opera un núcleo**: el diseño no debe depender de
  que la red del operador sea confiable. Cifrado extremo a extremo, autenticación de aplicación
  propia, y ningún secreto que viaje por SMS.

### Identidad y provisión de la SIM

- En 5G SA el identificador permanente (**SUPI**) se transmite **ocultado** (**SUCI**, cifrado con la
  clave pública de la red doméstica), lo que corta el rastreo por IMSI que era trivial en 4G — pero
  **sólo en SA y sólo si está bien configurado**. En NSA no aplica.
- **eSIM/eUICC**: `SGP.22` es el perfil de consumo (asume que hay un usuario que acepta);
  **`SGP.32` es el de IoT** e introduce el **eIM** (*eSIM IoT remote Manager*), que dispara la
  descarga, activación, desactivación o borrado de perfiles **sin usuario presente**. Versiones
  publicadas: 1.0 (2023), 1.1 (2024), 1.2 como línea base de certificación, y **1.3 publicada en
  mayo de 2026** — las fuentes discrepan sobre cuál es la base de certificación vigente:
  **verificar en la página de especificaciones de la GSMA (§8)**.
- **El eIM es una plataforma que puede dejar sin conectividad a la flota entera.** Se trata como un
  sistema de identidad crítico: MFA, mínimo privilegio, registro de auditoría de cada operación de
  perfil, y **procedimiento probado de recuperación** de un dispositivo sin perfil activo.
- ❌ **PROHIBIDO** desplegar flota con provisión remota cuyo procedimiento de recuperación no se haya
  ejercitado sobre hardware real.

## 6. Operabilidad y ciclo de vida

- **Apagados de 2G/3G**: son el mayor riesgo operativo del IoT celular desplegado, y **el calendario
  es por país y por operador**. Un parque de medidores, alarmas, ascensores o dispositivos eCall con
  módem 2G/3G deja de funcionar en una fecha concreta que **el propietario del parque suele
  desconocer**. **Se verifica y se tabula por país y operador (§8); no se escribe de memoria.**
  El 3G se retira antes que el 2G en casi todos los mercados, porque el 2G se conserva para M2M y
  voz de respaldo.
- **NB-IoT y LTE-M no son tecnología moribunda**: 3GPP las mantiene evolucionando **dentro de las
  especificaciones 5G** y **conservando la forma de onda LTE** — no hay migración a NR prevista, y
  están soportadas contra núcleo 5G. Coexisten con NR. Release 17 añadió eficiencia, **RedCap**
  (gama media, antes "NR-Light") y un primer soporte de redes no terrestres para NR, NB-IoT y LTE-M.
  Despliegue del orden de **115 redes LTE-M y 137 NB-IoT** a mediados de 2025 según GSMA
  (**verificar edición y fecha, §8**). **Pero**: hay operadores que han anunciado retirada de sus
  redes NB-IoT/LTE-M; **la longevidad de la tecnología no garantiza la del servicio de tu operador
  en tu país**. Ese es el dato a exigir por contrato.
- **Cobertura ≠ servicio**: NB-IoT y LTE-M se dimensionan por presupuesto de enlace en interiores
  profundos (sótanos, arquetas). Se valida midiendo en la ubicación peor, no en el mapa.
- **Roaming para IoT**: leer si es *roaming* permanente (prohibido o limitado en varias
  jurisdicciones), qué redes visitadas se garantizan, y **qué pasa cuando la red visitada apaga la
  tecnología**. Un dispositivo en itinerancia permanente con un solo acuerdo es un punto único de
  fallo contractual.
- **Coste**: el modelo de tarificación de IoT celular (por SIM, por dato, por evento) domina el TCO
  frente al hardware. Se modela con el perfil de tráfico real medido, no con el estimado
  (`finops-standards`).

## 7. Sostenibilidad y prohibiciones

- Revisar **anualmente** el parque celular contra: calendarios de apagado (2G/3G y, más adelante,
  4G), fin de soporte de los módulos, versiones de las especificaciones de eSIM y vigencia del
  acuerdo con el operador.
- Todo dispositivo celular desplegado lleva registrado en inventario: tecnología radio soportada,
  banda, operador, tipo de SIM (física/eUICC), versión de especificación de provisión, APN y fecha
  de fin de soporte del módulo. **Sin este inventario no se puede responder a un anuncio de
  apagado.**
- Documentar en ADR la decisión privada-celular-frente-a-WLAN con las condiciones que la reabrirían
  (cambio de espectro disponible, ampliación de cobertura exterior, nuevo requisito de determinismo).

Prohibiciones:

- ❌ **PROHIBIDO** tratar la SIM, el IMSI, el IMEI, la IP del APN o la pertenencia a una red privada
  como autenticación o autorización de aplicación.
- ❌ **PROHIBIDO** usar SMS o llamada de voz como segundo factor de autenticación en un sistema con
  valor. La superficie de interconexión heredada lo desaconseja desde hace más de una década.
- ❌ **PROHIBIDO** enviar datos sensibles sin cifrado extremo a extremo por confiar en el APN
  privado, en el *slice* o en "es una red del operador".
- ❌ **PROHIBIDO** comprar *slicing*, URLLC, IP fija o ruptura local sin confirmación escrita de que
  **las ubicaciones concretas están cubiertas por SA**.
- ❌ **PROHIBIDO** aceptar un *slice* sin parámetros medibles, punto de medida, comportamiento en
  congestión y penalización por escrito. Sin eso es una etiqueta de prioridad.
- ❌ **PROHIBIDO** citar "1 ms" o cualquier cifra de latencia 5G que no se haya medido en la
  ubicación y con el terminal reales.
- ❌ **PROHIBIDO** proponer una red privada celular sin (a) confirmar el régimen de espectro del país
  y su disponibilidad en la ubicación, (b) el estudio de la WLAN actual descartando que el problema
  sea de diseño Wi-Fi, y (c) el modelo de operación con dueño nombrado.
- ❌ **PROHIBIDO** desplegar flota IoT celular sin tabla verificada de fechas de apagado 2G/3G por
  país y operador.
- ❌ **PROHIBIDO** desplegar provisión remota de eSIM sin procedimiento de recuperación probado sobre
  hardware real.
- ❌ **PROHIBIDO** escribir de memoria una versión de especificación 3GPP o GSMA, una banda de
  frecuencia, un régimen de licencia o una fecha regulatoria (§8).
- ❌ **PROHIBIDO** incluir aquí técnicas de explotación de SS7/Diameter, capturadores de IMSI o
  material equivalente. Esta skill fija postura defensiva y criterio de compra; el trabajo ofensivo
  exige alcance y autorización escritos (`offensive-security-standards`).

## 8. Verificación web obligatoria

Comprobar **siempre**, en fuente primaria (3GPP, GSMA, regulador nacional, boletín oficial, contrato
del operador):

1. **Régimen de espectro para redes privadas del país concreto**, con el texto normativo: en España,
   la orden ministerial del **CNAF** (julio de 2026) publicada en el **BOE** y la **nota UN**
   aplicable — potencias, procedimiento, tasas y coordinación con Defensa y satélite **no se
   verificaron aquí**. En Alemania, la Verwaltungsvorschrift de la **Bundesnetzagentur** para
   3 700–3 800 MHz, su tasa y el **número actual de asignaciones** (**no verificado**).
2. **Estado de despliegue SA del operador en las ubicaciones concretas**, y la edición y fecha del
   informe GSA del que salga cualquier cifra de operadores SA/NSA (las cifras varían por edición).
3. **Calendario de apagado de 2G y 3G por país y por operador**, y de retirada de NB-IoT/LTE-M si
   la hay. **Es el dato que más se afirma mal.** En España, la hoja de ruta la trabaja el Ministerio
   para la Transformación Digital: **las fechas por operador que circulan en prensa son
   inconsistentes y no se verificaron en fuente primaria.**
4. **Versión vigente de las especificaciones GSMA de eSIM** (SGP.22 y SGP.32) y **cuál es la línea
   base de certificación** — hay discrepancia entre v1.2 y v1.3 (publicada 28-05-2026) en las
   fuentes consultadas.
5. **Versión aplicable de 3GPP TS 33.501** y de las guías de *roaming* 5G de la GSMA (NG.113) antes
   de citar cualquier cláusula de seguridad de interconexión.
6. **Plantillas de slice** (GST/NEST de GSMA) y su versión, si el contrato las referencia.
7. **Estado regulatorio del fabricante de RAN** en el país de despliegue si es un proveedor sujeto a
   restricción (`network-vendors-standards` §5).
8. **Cualquier cifra de latencia, caudal, ahorro o cuota**: exigir metodología y punto de medida. Si
   no la hay, **no se cita**.

**Huecos declarados**: (a) no se verificó el texto del BOE ni la nota UN del CNAF español — el
reparto de la banda 3 800–4 200 MHz procede de prensa técnica que cita la orden, no de la orden. (b)
No se obtuvo el número actual de asignaciones locales de 3,7 GHz de la Bundesnetzagentur. (c) Las
fechas de apagado 2G/3G en España no se pudieron fijar en fuente primaria: las fuentes secundarias
se contradicen y **no se escriben aquí**. (d) Las cifras de operadores 5G SA proceden de resúmenes
de informes GSA con variación entre ediciones (85/89/95). (e) La cifra de 115 redes LTE-M / 137
NB-IoT procede de una cita de GSMA a mediados de 2025, sin verificar el informe original. (f) No se
verificaron los planes de retirada de NB-IoT/LTE-M de operadores concretos.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
