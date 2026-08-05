---
name: home-automation-standards
description: Engineering a home that keeps working when the internet, the vendor or the hub goes down. Use when designing or reviewing a smart home built on Home Assistant (configuration.yaml, automations.yaml, scripts.yaml, secrets.yaml, templates and Jinja2 triggers, HACS custom components, Home Assistant OS versus Container installs, add-ons/apps, the monthly 20XX.M release train and its backward-incompatible changes), openHAB, Node-RED, Zigbee2MQTT and its coordinator firmware, ZHA, ESPHome YAML device configs, MQTT and Mosquitto topics and retained state, choosing between Zigbee, Z-Wave, Thread and Matter (commissioning, border routers, fabrics, multi-admin) versus cloud-only Wi-Fi devices, putting IoT devices on their own VLAN with egress filtering, an abandoned device whose vendor stopped shipping firmware, cameras, microphones and presence detection inside a home, voice assistants and local speech processing, robust versus fragile automations (state versus event triggers, the automation that locks someone out or leaves the house cold), physical switch fallback, or backing up and rebuilding the whole configuration from scratch.
---

# Estándares de domótica

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **automatizar una vivienda**: elegir dispositivos y protocolos, montar la plataforma de
control, segmentar la red, escribir automatizaciones que no hagan daño, mantener el conjunto cuando
un fabricante desaparece, y proteger la privacidad de las personas que viven dentro.

Triggers: `configuration.yaml`, `automations.yaml`, `scripts.yaml`, `secrets.yaml`, plantillas Jinja2
de Home Assistant, HACS, *add-ons*/apps, Home Assistant OS frente a Container, openHAB, Node-RED,
Zigbee2MQTT, ZHA, firmware del coordinador Zigbee, ESPHome y su YAML de dispositivo, MQTT/Mosquitto,
*retained*, Zigbee, Z-Wave, Thread, Matter, *border router*, *fabric*, *multi-admin*, "el dispositivo
necesita la nube", "el fabricante ha cerrado el servicio", VLAN de IoT, cámara, micrófono, detección
de presencia, asistente de voz, "la automatización me dejó fuera de casa", "se apagó la calefacción",
copia de seguridad de la configuración.

**Principio rector, y es un criterio de aceptación, no una preferencia: la casa tiene que seguir
funcionando cuando internet, el fabricante o el servidor de automatización se caen.** Una vivienda no
es un servicio con SLA; es el sitio donde alguien tiene que poder encender la luz, abrir la puerta y
no pasar frío a las tres de la mañana. De ahí salen tres reglas absolutas:

1. **El interruptor físico no se sustituye jamás.** Toda carga controlada mantiene un control manual
   que funciona con la plataforma apagada. Un relé inteligente detrás del interruptor de pared, no en
   lugar de él; una bombilla "inteligente" alimentada por un interruptor que la gente puede apagar es
   un fallo de diseño, no una integración.
2. **Control local por defecto.** Un dispositivo que necesita salir a internet para encender una luz
   introduce una dependencia externa en una función doméstica básica. El criterio de compra es
   "¿funciona con el rúter desconectado?", y se prueba **antes** de instalar el segundo.
3. **La degradación es un requisito.** Con la plataforma caída, la casa queda en un estado seguro y
   operable a mano: luces encendibles, cerraduras abribles, clima funcionando con su termostato.

**Segunda tesis: el dispositivo barato conectado es el eslabón más débil de tu red**, y no por
opinión — es un ordenador con Linux antiguo, credenciales embebidas y un fabricante que dejará de
publicar firmware antes de que tú lo tires. Por eso §3.2 (segmentación) no es paranoia: es la única
mitigación que sigue funcionando cuando el fabricante abandona el producto.

**No aplica**: ver `homelab-standards` (**el servidor y el laboratorio son suyos**: el hardware, el
hipervisor, Docker/Podman, el proxy inverso con TLS, el SSO delante de las aplicaciones, el acceso
remoto sin abrir puertos, el SAI, la política de backup del lab y el criterio de proporcionalidad.
**Frontera limpia: dónde corre Home Assistant es suyo; qué dispositivo entra en la casa, con qué
protocolo, y qué automatización se escribe, es de aquí**), `embedded-iot-standards` (**fabricar el
dispositivo es suyo**: silicio, RTOS, bootloader, actualización OTA del firmware, identidad por
dispositivo, CRA/EN 18031. Aquí el dispositivo **como producto que compras y despliegas**, y qué
haces cuando su fabricante deja de actualizarlo), `edge-computing-standards` (flota de nodos y
actualización A/B a escala; una casa no es una flota), `ot-ics-security-standards` (**edificio
industrial, BMS, KNX/BACnet en instalación profesional, seguridad de personas en proceso físico**:
suyo. Una vivienda unifamiliar es de aquí; un edificio con mantenimiento contratado y sistemas de
seguridad certificados, suyo), `networking-standards` (**diseño de la red, VLAN, direccionamiento,
enrutado, mDNS entre segmentos**: suyo) y `firewall-policy-standards` (**la regla como artefacto**:
default-deny, matriz de flujos, ciclo de vida. **Aquí se decide qué segmento existe y qué tiene que
poder hablar con qué; allí se escribe y se gobierna la regla**), `wireless-standards` (Wi-Fi, canales,
cobertura y coexistencia con 2,4 GHz — que es la causa real de la mitad de los problemas Zigbee),
`dns-standards` (resolución interna, `home.arpa`), `vpn-standards` (acceso remoto a la casa: WireGuard,
Tailscale — **aquí solo la prohibición de abrir puertos**), `privacy-engineering-standards`
(**minimización, retención y derechos son suyos**; aquí la decisión de qué sensor entra en qué
habitación y qué sale de casa), `backup-recovery-standards` (mecánica de la copia y prueba de
restauración), `vulnerability-management-standards` (triaje de CVEs), `observability-standards`
(telemetría como plataforma), `local-inference-standards` (**servir un modelo en local**, si el
asistente de voz usa LLM: motor, cuantización y dimensionado son suyos),
`ai-agents-standards` (un agente que actúa sobre la casa: bucle, topes y aprobación humana),
`physical-security-standards` (alarma certificada, control de acceso profesional, videovigilancia con
obligaciones legales — **una cámara doméstica que enfoca la vía pública deja de ser un asunto
doméstico**), `green-it-standards` (consumo y eficiencia energética como disciplina).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión, licencia y estado por web antes de fijarlos (§8).

### 2.1 Plataforma

| Plataforma | Licencia (leída en crudo) | Cuándo |
|---|---|---|
| **Home Assistant** | **Apache-2.0** (`LICENSE.md` de `home-assistant/core`) | **Por defecto.** Mayor catálogo de integraciones, control local real, comunidad activa. A ago-2026: **2026.8**, publicada el **5-ago-2026** |
| **openHAB** | **EPL-2.0** (`LICENSE` de `openhab-core`) | Alternativa madura basada en JVM; reglas más formales, comunidad menor |
| **Node-RED** | **Apache-2.0** (`LICENSE`) | **Complemento, no sustituto**: flujos visuales para lógica compleja o de integración, junto a HA |
| **Zigbee2MQTT** | **GPL-3.0** (`LICENSE`) | Puente Zigbee → MQTT independiente del hub. A ago-2026: **2.13.0** (1-ago-2026) |
| **ESPHome** | **Doble y por extensión de fichero**: el propio `LICENSE` dice que *"The ESPHome License is made up of two base licenses: MIT and the GNU"* — **GPLv3 para el código C++/runtime** (`.c`, `.cpp`, `.h`, `.hpp`, `.tcc`, `.ino`) y **MIT para el resto** | Dispositivos propios y **recuperar dispositivos de fabricantes abandonados** reflasheándolos |

**Cadencia de Home Assistant, que es un compromiso operativo**: **un major al mes** (`AAAA.M`) y
parches semanales —la nota de la 2026.8 lo dice: *"Our goal is to release a patch release once a
week, aiming for Friday"*—, y **cada release trae una sección de *"Backward-incompatible changes"***
en la que el propio proyecto reconoce que *"sometimes it is inevitable"*. Consecuencias:

- **Leer las notas de versión antes de actualizar no es opcional**, y ese es el único momento en que
  el sistema te avisa de que una integración va a dejar de funcionar.
- **No actualices el día de la release.** Espera a los primeros parches salvo que la actualización
  cierre una vulnerabilidad.
- **Nunca actualices sin copia de seguridad reciente y probada** (§7.1).
- Las deprecaciones se anuncian con **más de un año de margen** en el blog de desarrolladores (a
  jul-2026, varias apuntaban a Core 2027.7/2027.8). Ese margen existe para que lo uses, no para que
  lo ignores.

**Instalación**: a ago-2026 la documentación oficial presenta **Home Assistant OS** (con apps/add-ons,
actualizaciones de un clic y copias) y **Home Assistant Container** (tú traes el sistema y gestionas
las actualizaciones), y avisa de que *"Home Assistant Container installations don't have access to
apps"*, lo que deja fuera integraciones controladas por apps como **Thread y Z-Wave**. Si vas a usar
Thread o Z-Wave, **esa frase decide tu método de instalación**. (Verificar §8: el catálogo de métodos
y su nomenclatura han cambiado.)

### 2.2 Protocolos

| Protocolo | Banda / topología | Veredicto |
|---|---|---|
| **Zigbee** | 2,4 GHz, malla | **Opción por defecto** para sensores y luces. Barato, local, ecosistema enorme. **Colisiona con Wi-Fi en 2,4 GHz**: la elección de canal es obligatoria, no opcional (§6.2). Los dispositivos alimentados hacen de repetidor; los de pila, no |
| **Z-Wave** | Sub-GHz (868 MHz en Europa), malla | Menos interferencia y mejor penetración; catálogo menor y **más caro**. Buena elección para cerraduras y sensores críticos. Z-Wave Long Range para alcance |
| **Thread** | 2,4 GHz, malla IPv6 | **Transporte, no ecosistema**: necesita *border router* y, en la práctica, Matter encima. Spec vigente **1.4.1** (verificar §8) |
| **Matter** | Sobre Thread, Wi-Fi o Ethernet | **La zona con más humo del sector.** Ver §2.3 |
| **Wi-Fi** | 2,4/5 GHz, estrella | Solo con **firmware local** (ESPHome, Tasmota, WLED) o control local documentado. **Cada dispositivo Wi-Fi es un cliente más saturando la red y un punto de presencia en tu LAN** |
| **BLE** | 2,4 GHz | Sensores de proximidad y balizas; alcance corto, necesita *proxies* repartidos |
| **RF propietario 433/868 MHz** | Punto a punto | Barato y **sin ninguna seguridad**: la mayoría son códigos fijos, clonables con hardware de 20 €. **Jamás para cerraduras, garajes ni alarmas** |
| **KNX / cableado** | Bus cableado | Instalación profesional, fiabilidad muy superior, coste y obra. En reforma integral, la mejor opción para lo que no debe fallar |

### 2.3 Matter: qué funciona de verdad

Matter resolvió el problema de la **puesta en marcha** y la **interoperabilidad básica** entre
ecosistemas (Apple, Google, Amazon, Samsung), y ese logro es real: un dispositivo Matter se pone en
marcha con un código QR y se puede compartir con varios controladores (*multi-admin*). Lo que **no**
resolvió, y conviene decirlo antes de comprar:

- **El soporte del tipo de dispositivo va por versión de la especificación, y tu controlador va por
  detrás.** A ago-2026 la CSA publica hasta **Matter 1.6** (con 1.5.1, 1.5 y la serie 1.4 aún
  disponibles). Que la spec soporte una categoría **no significa** que tu app o tu hub la soporten.
- **Las funciones avanzadas del fabricante siguen fuera de Matter.** El dispositivo funciona en lo
  básico y para lo demás te pide su app —y su nube—. Comprar Matter **no** te libera del fabricante.
- **Matter sobre Wi-Fi no es control local garantizado**: el control local es del *fabric*, pero el
  dispositivo puede seguir hablando con su nube en paralelo. Se comprueba en el cortafuegos (§3.2),
  no en el folleto.
- **Thread necesita un *border router*** y tener varios de fabricantes distintos ha sido, de forma
  reiterada, fuente de problemas de red. Uno bien puesto vale más que tres repartidos.
- **Regla práctica**: Matter es excelente para **estandarizar la puesta en marcha** y para no quedar
  atado a un ecosistema. **No lo compres por lo anunciado; compra el dispositivo que ya funciona hoy
  con tu controlador**, y verifícalo en la lista de compatibilidad antes de pagar.

## 3. Estructura y convenciones

### 3.1 Configuración como código

- **Toda la configuración en Git**, con `secrets.yaml` **fuera** del repositorio (o cifrado con
  SOPS/`git-crypt`). Sin esto no hay diff, no hay revert y no hay reconstrucción.
- **Convención de nombres estable y por función, no por marca**:
  `<dominio>.<planta>_<estancia>_<función>` (`light.pb_salon_principal`). Los identificadores del
  fabricante cambian al reemplazar el aparato; el nombre funcional no. **Renombrar entidades después
  rompe todas las automatizaciones que las citan**, así que se decide el día uno.
- **Áreas, dispositivos y etiquetas** bien puestas: permiten escribir automatizaciones por zona en
  vez de por lista de entidades, que es lo que sobrevive a un cambio de bombilla.
- **Plantillas y lógica compleja fuera de la automatización** (scripts, *blueprints*, o Node-RED si
  el flujo lo pide). Una automatización con 60 líneas de Jinja2 es código sin tests.

### 3.2 Red: la segmentación es requisito

- **VLAN propia para IoT**, sin excepciones, con **default-deny** hacia la red de confianza. Diseño
  de red y regla: `networking-standards` y `firewall-policy-standards`. Aquí, los flujos que hay que
  permitir y nada más:
  - IoT → controlador (HA/MQTT): **solo los puertos necesarios**.
  - Controlador → IoT: lo necesario para el control.
  - IoT → internet: **filtrado de salida**, y por defecto **bloqueado**. Muchos dispositivos
    funcionan perfectamente sin salida; los que no, se documenta a dónde salen y por qué.
  - Confianza → IoT: iniciado desde el lado de confianza, no al revés.
- **El descubrimiento (mDNS/SSDP) no cruza VLANs solo**: hace falta un reflector/proxy mDNS acotado a
  los servicios concretos. Abrir el reflector "para todo" anula la segmentación.
- **Wi-Fi de invitados aislado** y **PSK distinta para la SSID de IoT**. Un dispositivo comprometido
  no debe poder ver el NAS.
- **Acceso remoto: nunca abriendo puertos.** VPN (WireGuard/Tailscale) o túnel de salida. **PROHIBIDO
  publicar la interfaz del controlador en internet**, con o sin contraseña.
- **La salida bloqueada es también la mitigación del dispositivo abandonado** (§7.2): cuando el
  fabricante deje de parchear, el aparato seguirá funcionando en local y sin poder ser alcanzado ni
  llamar a casa.

### 3.3 Automatizaciones robustas frente a frágiles

La diferencia entre una casa que ayuda y una que castiga:

- **Dispara por estado, no por evento.** Un evento se pierde si la plataforma estaba reiniciando; el
  estado se vuelve a evaluar. Regla: **el objetivo de una automatización es que el mundo quede en el
  estado deseado**, no que se ejecute una acción. Tras un reinicio, el sistema debe converger.
- **Idempotencia**: ejecutar la automatización dos veces produce el mismo resultado. "Alternar"
  (*toggle*) es el antipatrón: si se pierde un evento, el estado queda invertido para siempre.
- **Condiciones explícitas de anulación humana.** Si alguien encendió la luz a mano, la
  automatización **no** la apaga a los cinco minutos. Un sensor de presencia con temporizador que
  ignora la acción manual es el motivo número uno de que la gente desinstale la domótica.
- **Nada de valores acoplados a la hora del reloj** cuando lo que importa es la luz o la presencia:
  usa el sensor, no la hora.
- **Prueba el fallo del sensor**: ¿qué hace la automatización si el sensor de presencia lleva 6 horas
  sin reportar porque se le acabó la pila? La respuesta correcta casi nunca es "asumir que no hay
  nadie".
- **Un cambio, una automatización.** Varias automatizaciones que escriben sobre la misma entidad
  producen oscilaciones que nadie diagnostica. Si hay dos, hay una tercera que arbitra.

### 3.4 El fallo doméstico que sí importa

No es la luz que no se enciende. Es esto, y cada uno lleva una barrera de diseño:

| Fallo | Barrera obligatoria |
|---|---|
| **Alguien encerrado dentro o fuera** | Cerradura con **llave física funcional** siempre. Nunca una automatización que eche el cerrojo sin condición de presencia verificada. Apertura manual desde dentro, sin electricidad |
| **A oscuras** | Iluminación de emergencia o al menos una luz por planta fuera del control automático. Nunca "apagar todo" sin excepciones por estancia ocupada |
| **Sin calefacción / sin refrigeración** | El termostato conserva su lógica propia y sus límites; el controlador **sugiere**, no gobierna. **Suelo mínimo antihielo** y techo máximo, impuestos en el termostato, no en la automatización |
| **Bomba, riego o válvula atascada en abierto** | Temporizador de seguridad **en el dispositivo**, no en el software. Caudalímetro o corte por tiempo máximo |
| **Alarma / humo / CO** | **Detectores autónomos certificados y alimentados por red o pila**, independientes de la domótica. La domótica **notifica**; no es el sistema de detección |
| **Corte eléctrico** | El estado tras recuperar corriente está **decidido**: cada relé configurado a "último estado" o "encendido" según la carga. Un congelador detrás de un enchufe que arranca apagado es una avería cara |

## 4. Calidad y testing

Escalado a lo que es —una casa, no un banco—, pero estos cinco no se saltan:

1. **Validación de configuración antes de recargar** (`hass --script check_config` o equivalente) y
   linter de YAML. Un YAML mal indentado deja el sistema sin arrancar.
2. **Prueba manual de cada automatización nueva, incluido el camino de error**, antes de darla por
   buena. Y **prueba del reinicio**: recargar la plataforma y comprobar que el estado converge.
3. **Instancia de pruebas** para cambios grandes (actualización mayor, cambio de integración de
   Zigbee, migración de coordinador). Con Home Assistant es una copia restaurada en una VM: barato y
   evita el fin de semana perdido.
4. **Restauración probada, no solo copia hecha** (§7.1). Una copia sin restaurar no existe →
   `backup-recovery-standards`.
5. **Revisión de las notas de versión antes de cada actualización mayor**, buscando específicamente
   la sección de cambios incompatibles y las integraciones que usas.

## 5. Seguridad y privacidad

### 5.1 La casa como superficie

- **Segmentación (§3.2) primero**; es la que sigue funcionando cuando todo lo demás falla.
- **Credenciales**: contraseña única por servicio, **MFA activado en el controlador**, y **cuentas
  separadas por persona** — no una cuenta compartida "de casa". Los invitados no reciben la del
  administrador.
- **Sin puertos abiertos hacia internet.** Ni el controlador, ni la cámara, ni el NVR, ni "solo el
  8123 con una contraseña buena".
- **Integraciones de terceros (HACS y equivalentes) son código sin revisar que corre con los
  permisos del controlador.** Se instalan las mínimas, de repositorios con actividad y con la
  licencia leída; se actualizan; y se retiran cuando el autor abandona. Es una cadena de suministro,
  aunque sea la de tu casa.
- **Actualizaciones**: controlador y puentes (Zigbee2MQTT, ESPHome) al día; firmware de dispositivos
  también, **pero de uno en uno y con capacidad de volver atrás**, porque un firmware malo puede
  dejar un dispositivo inservible y muchos no permiten *downgrade*.

### 5.2 Cámaras, micrófonos y presencia

Es la parte de la domótica que trata datos íntimos de personas que **no han firmado nada**:
convivientes, menores, visitas, personal doméstico.

- **Cámaras: grabación local (NVR/HA), sin nube por defecto.** Si el modelo exige nube para funcionar,
  no entra. Retención corta y explícita.
- **Ninguna cámara ni micrófono en dormitorios ni baños.** No es una recomendación: es el límite.
- **Consentimiento e información a quien convive y a quien visita.** Y si alguna cámara capta vía
  pública o zona común, **deja de ser un asunto doméstico** y entra en obligaciones legales →
  `physical-security-standards`, `privacy-engineering-standards`.
- **Asistentes de voz: local siempre que se pueda** (procesado local de voz, o modelo propio →
  `local-inference-standards`). Si es de nube, se acepta explícitamente que **el audio de tu salón
  sale de casa**, y se pone donde eso sea aceptable.
- **La detección de presencia es un registro de vida**: quién está en casa, a qué hora, en qué
  habitación. Se guarda lo mínimo y con retención acotada; **el histórico infinito de presencia es la
  base de datos más sensible de la casa** y casi nadie la trata como tal.
- **Cuentas cloud del fabricante**: antes de crear una, la pregunta es qué se lleva. Si el fabricante
  desaparece, la cuenta se lleva el dispositivo con ella — otra razón para exigir control local.

## 6. Rendimiento y operabilidad

### 6.1 Latencia y fiabilidad percibida

**El listón es el interruptor de pared: por debajo de ~200 ms desde la pulsación hasta la luz, o la
gente vuelve al interruptor.** Un mando físico que pasa por Zigbee → puente → MQTT → automatización →
Zigbee y encima sale a la nube no llega. **Vinculación directa** (*binding* Zigbee, asociación
Z-Wave) entre mando y luz cuando exista: funciona aunque el controlador esté apagado, que es
justamente el requisito de §1.

### 6.2 Radio

- **Canal Zigbee elegido para no solapar con el canal Wi-Fi de 2,4 GHz**, y documentado. Este único
  ajuste resuelve la mayoría de los "a veces no responde".
- **Coordinador Zigbee separado del ordenador por un alargador USB** y lejos de USB 3.0 y de fuentes
  de alimentación: la interferencia de USB 3 sobre 2,4 GHz es real y desconcierta durante meses.
- **La malla la sostienen los dispositivos alimentados**, no los de pila. Una casa con solo sensores
  de pila no tiene malla, tiene una estrella con mal alcance.
- **Registro del coordinador y su firmware**, y **copia de la red Zigbee/Z-Wave** (claves de red): sin
  ella, cambiar de coordinador significa volver a emparejar cada dispositivo, uno a uno, subido a una
  escalera.

### 6.3 Vigilancia proporcionada

Lo que hay que monitorizar en una casa es corto y concreto:

- **Batería baja** de cada sensor, con umbral y aviso con antelación.
- **Dispositivo que lleva N horas sin reportar** — es el aviso de un sensor muerto, y sin él la
  automatización sigue "funcionando" con datos de ayer.
- **Controlador caído** (aviso desde fuera del propio controlador; si se avisa a sí mismo, no avisa).
- **Cortes de corriente y estado del SAI** → `homelab-standards`.
- **Copia de seguridad más reciente y su antigüedad.**
- Todo lo demás es opcional. Un panel con 200 gráficas en casa es un pasatiempo, no observabilidad.

## 7. Sostenibilidad a largo plazo

### 7.1 Copia y reconstrucción

La pregunta que ordena esta sección: **si el disco del controlador muere hoy, ¿cuánto tardas en tener
la casa funcionando otra vez?** Si la respuesta es "un fin de semana", el diseño ha fallado.

- **Copia automática y periódica**, **fuera del propio equipo** (3-2-1 doméstico: local + NAS + fuera
  de casa cifrada) → `backup-recovery-standards`.
- **Incluye lo que no está en el YAML**: base de datos si te importa el histórico, claves de red
  Zigbee/Z-Wave, `secrets.yaml`, configuraciones de ESPHome, *flows* de Node-RED, y el inventario de
  dispositivos.
- **Restauración probada al menos una vez al año** en una VM. Es el único modo de saber si la copia
  sirve.
- **Documento de reconstrucción de una página**: qué hardware, qué se instala, en qué orden, dónde
  están las claves. Escrito para alguien que no eres tú —incluido el caso en el que no estés—.

### 7.2 El dispositivo que el fabricante abandona

Pasa siempre, y el plan se hace antes de comprar, no después:

- **Criterio de compra**: ¿funciona sin nube? ¿se puede integrar localmente? ¿es reflasheable
  (ESPHome/Tasmota)? ¿hay comunidad? Un dispositivo que falla las cuatro es alquilado, no comprado.
- **Cuando el fabricante lo abandona**, en este orden: (a) reflashear con firmware libre si el
  hardware lo permite; (b) mantenerlo **sin salida a internet** y controlado localmente; (c)
  sustituirlo. **Lo que no se hace es dejarlo enchufado, con firmware sin parchear y con acceso a
  internet.**
- **La segmentación con egress bloqueado (§3.2) es lo que convierte (b) en una opción defendible**, y
  por eso se monta desde el principio, no cuando llega la mala noticia.

### 7.3 Prohibiciones

- ❌ **PROHIBIDO** eliminar o inutilizar el control manual de cualquier carga.
- ❌ **PROHIBIDO** que una función doméstica básica (luz, cerradura, clima) dependa de internet o de
  la nube de un fabricante.
- ❌ **PROHIBIDO** dispositivos IoT en la misma VLAN que ordenadores, NAS o teléfonos.
- ❌ **PROHIBIDO** exponer el controlador, una cámara o un NVR directamente a internet, con o sin
  contraseña; el acceso remoto va por VPN o túnel.
- ❌ **PROHIBIDO** permitir salida a internet por defecto desde la VLAN de IoT.
- ❌ **PROHIBIDO** RF propietario de 433 MHz con código fijo en cerraduras, garajes o alarmas.
- ❌ **PROHIBIDO** cámaras o micrófonos en dormitorios y baños; y prohibido instalarlos sin informar a
  quien convive.
- ❌ **PROHIBIDO** guardar histórico de presencia sin retención definida.
- ❌ **PROHIBIDO** actualizar la plataforma sin leer los cambios incompatibles y sin copia reciente.
- ❌ **PROHIBIDO** actualizar firmware de varios dispositivos a la vez.
- ❌ **PROHIBIDO** automatizaciones basadas en *toggle* o en eventos no reevaluables.
- ❌ **PROHIBIDO** una automatización que eche el cerrojo, apague toda la luz o corte la calefacción
  sin condición de presencia y sin límite de seguridad en el propio dispositivo.
- ❌ **PROHIBIDO** confiar la detección de humo, CO o intrusión a la domótica: detectores autónomos
  certificados, y la domótica solo notifica.
- ❌ **PROHIBIDO** dejar en la red un dispositivo abandonado por su fabricante con salida a internet.
- ❌ **PROHIBIDO** una configuración que no esté en Git, y prohibido `secrets.yaml` dentro del
  repositorio.
- ❌ **PROHIBIDO** dar por buena una copia de seguridad que nunca se ha restaurado.
- ❌ **PROHIBIDO** comprar por la etiqueta "Matter" sin comprobar que **ese** dispositivo funciona
  con **tu** controlador hoy (§2.3).

## 8. Verificación web obligatoria

- **Home Assistant**: versión actual y sus **cambios incompatibles** (a ago-2026, **2026.8**, del
  5-ago-2026; majors mensuales y parches semanales los viernes). Blog de desarrolladores para
  deprecaciones anunciadas. **Métodos de instalación vigentes y su nomenclatura**, que han cambiado:
  a ago-2026 la página oficial presenta **OS** y **Container**, y advierte de que Container **no tiene
  acceso a apps**, lo que afecta a **Thread y Z-Wave**.
- **Licencias en crudo** (`LICENSE`, `LICENSE.md`, `COPYING`; ojo con `master` frente a `main`).
  Verificadas para este documento: Home Assistant **Apache-2.0**, openHAB core **EPL-2.0**, Node-RED
  **Apache-2.0**, Zigbee2MQTT **GPL-3.0**, y **ESPHome con licencia doble por extensión de fichero**
  (MIT + GPLv3 para el código C++/runtime) — si vas a redistribuir algo derivado, esa es la que hay
  que leer entera.
- **Matter**: versión de la especificación publicada por la CSA (a ago-2026, **1.6** disponible junto
  a 1.5.1, 1.5 y la serie 1.4) **y, por separado, qué versión implementa tu controlador**. No son lo
  mismo y esa diferencia es la fuente del humo.
- **Thread**: versión vigente de la especificación (a ago-2026, **1.4.1**) y compatibilidad de tus
  *border routers*.
- **Zigbee**: revisión del núcleo (a ago-2026 la CSA publica **R23.2**) y firmware recomendado de tu
  coordinador.
- **Zigbee2MQTT / ESPHome**: versión actual (Zigbee2MQTT **2.13.0**, 1-ago-2026) y compatibilidad con
  la versión de Home Assistant antes de actualizar cualquiera de los dos.
- **Fin de soporte de dispositivos y servicios de fabricante**: buscar activamente si el fabricante ha
  anunciado cierre de servicio o fin de firmware, **antes** de comprar y **al menos una vez al año**
  después.
- **CVEs** del controlador, de los puentes y de los modelos de dispositivo instalados →
  `vulnerability-management-standards`.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
