---
name: wireless-standards
description: Enterprise Wi-Fi as a designed radio system — site survey, spectrum and capacity, not just placing access points. Use when planning or reviewing a WLAN design, a predictive or validation site survey in Ekahau, Hamina or TamoGraph, AP placement and transmit power, channel plan and channel width (20/40/80/160/320 MHz), 2.4/5/6 GHz band selection, DFS and radar events, 6 GHz LPI and VLP power limits and AFC, Wi-Fi 6 (802.11ax), Wi-Fi 6E, Wi-Fi 7 (802.11be-2024) and multi-link operation, 802.11k neighbour reports, 802.11v BSS transition management and 802.11r fast BSS transition, band steering and sticky clients, minimum basic rate and disabling low data rates, RSSI and SNR targets, co-channel interference and airtime utilization, WPA2 versus WPA3-Personal SAE and WPA3-Enterprise, transition mode and RSN overriding, 802.1X with EAP-TLS or PEAP and server certificate validation on the client, hostapd.conf, wpa_supplicant.conf, FreeRADIUS eap.conf, guest SSID isolation and captive portals, WIDS/WIPS and rogue AP classification, controller versus cloud versus standalone AP management, or Wi-Fi complaints that turn out to be capacity, roaming or client driver problems.
---

# Estándares de Wi-Fi corporativo — diseño por radio, operación por datos

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **diseñar, validar y operar una WLAN corporativa**: estudio de sitio, espectro y plan de
canales, dimensionado por capacidad, itinerancia, autenticación y cifrado inalámbricos, segmentación
de SSID, WIDS/WIPS, y arquitectura de gestión (controladora, nube, autónomo).

Triggers: "site survey", "estudio de sitio", Ekahau/Hamina/TamoGraph/AirMagnet, "heatmap", "RSSI",
"SNR", "co-channel", "airtime", "DFS", "6 GHz", "AFC", "LPI", "VLP", 802.11ax/ac/be/bn,
"Wi-Fi 6E/7/8", "MLO", 802.11k/v/r/w, "band steering", "sticky client", "minimum basic rate",
WPA2/WPA3/SAE/OWE, 802.1X, EAP-TLS/PEAP/EAP-TTLS, `hostapd.conf`, `wpa_supplicant.conf`,
FreeRADIUS (`eap.conf`, `clients.conf`), "SSID de invitados", "captive portal", "rogue AP".

**No aplica** — el catálogo ya reparte esto: `networking-standards` es la **troncal** (VLAN,
direccionamiento, MTU, plano de gestión OOB) y **ya delega la profundidad**, mientras
`routing-switching-standards` posee el **campus cableado**, 802.1X en puerto, PoE, VRRP y la
seguridad del plano de control, `datacenter-fabric-standards` posee la malla, VXLAN/EVPN y la
Ethernet sin pérdidas, y `network-automation-standards` la configuración como código de cualquier
equipo de red, incluidos los AP. Hacia fuera: **el filtrado de lo que sale del SSID es de
`firewall-policy-standards`**, **el RADIUS como servicio de identidad, el ciclo de vida del
certificado de cliente y el MDM que lo distribuye son de `identity-access-management-standards`** (y
la PKI, de `cryptography-pki-standards`), la metodología de medir y el modelo de carga de
`performance-engineering-standards`, métricas y alertas de `observability-standards`, el SLO de
`sre-practice-standards`, el método reactivo de `network-troubleshooting-standards`, la detección de
`detection-engineering-standards`, y el paraguas de `onprem-standards` (junto a
`datacenter-facilities-standards` y `hpc-standards`). Entre las tres
hermanas de esta tanda: `wireless-standards` es la **red de acceso**,
`load-balancing-standards` la **red de servicio** y `high-speed-interconnect-standards` la **red de
cómputo**; **el error del dominio es aplicarles el mismo criterio**.

**Principio rector**: **una Wi-Fi corporativa se diseña con un estudio de sitio y se opera con
datos.** Poner puntos de acceso hasta que "haya cobertura" no es un diseño: es una apuesta que se
paga en tickets. El medio es compartido, half-duplex y no se puede sobreaprovisionar comprando más
ancho de banda al operador.

## 2. Decisiones por defecto

> Verificar por web generación, número IEEE, estado regulatorio y versión antes de fijar nada (§8).

| Decisión | Por defecto | Alternativa justificable / vetado |
|---|---|---|
| Generación objetivo | **Wi-Fi 6 / 6E (802.11ax)** como suelo; **Wi-Fi 7 (IEEE Std 802.11be-2024)** en renovación con parque de clientes moderno | ❌ Comprar Wi-Fi 7 esperando ganancia con clientes 802.11ac; **Wi-Fi 8 (802.11bn, UHR) no es desplegable en 2026**: certificación prevista 2027-2028 |
| Banda principal de datos | **5 GHz**, y **6 GHz** donde el parque lo soporte | 2,4 GHz **sólo** para IoT y legado, siempre 20 MHz |
| Ancho de canal | **20 MHz en alta densidad; 40 MHz como techo habitual en 5 GHz** | 80 MHz sólo con espectro limpio y baja concurrencia demostrados; ❌ 160/320 MHz en oficina densa |
| Objetivo de señal | **≥ −67 dBm de RSSI y ≥ 25 dB de SNR** en toda la zona útil, medido en 5/6 GHz | Umbrales más exigentes para voz/vídeo en tiempo real; ❌ diseñar mirando sólo 2,4 GHz |
| Potencia de transmisión | **Baja y uniforme**, celdas pequeñas, con margen para que el cliente responda | ❌ Potencia al máximo: crea celdas asimétricas y clientes pegados |
| Tasas básicas | **Deshabilitar las tasas bajas** (1/2/5,5/11 Mbps y las OFDM más bajas) y fijar la tasa básica mínima | ❌ Dejar 1 Mbps activo: cada trama de gestión consume aire del resto |
| Seguridad corporativa | **WPA3-Enterprise con 802.1X y EAP-TLS** (certificado de cliente) | EAP-TTLS/PEAP con MSCHAPv2 sólo transitorio y **con validación estricta del certificado del servidor**; ❌ PSK compartida corporativa |
| Seguridad en 6 GHz | **WPA3 obligatorio** y PMF (802.11w) obligatorio en la banda; sin modo de transición | ❌ Intentar extender un SSID WPA2 a 6 GHz |
| Compatibilidad con legado | **SSID separado y con fecha de retirada**, o *RSN overriding* (modo de compatibilidad de la Wi-Fi Alliance) | Modo de transición WPA3 sólo con **Transition Disable** previsto; es vulnerable a degradación |
| Itinerancia | **802.11k + 802.11v activados**; **802.11r (FT)** cuando el parque lo tolere | ❌ Activar FT a ciegas en un parque heterogéneo sin ventana de prueba |
| Invitados | **SSID aislado en VLAN propia**, aislamiento cliente-a-cliente, salida filtrada, **OWE** o portal con TLS | ❌ Invitados en la VLAN corporativa "con reglas"; ❌ PSK de invitado escrita en la pared sin caducidad |
| Gestión | **Nube o controladora**, según quién opere y qué disponibilidad de WAN haya | AP autónomos sólo en instalaciones de 1-3 AP; ❌ flota sin gestión central ni inventario |
| Estudio de sitio | **Predictivo para diseñar + validación medida obligatoria** | ❌ Predictivo sin validar; ❌ "APoD" (*AP on a stick*) como única metodología en obra nueva |

## 3. Diseño

**Qué aporta de verdad cada generación — y qué depende del cliente**
- **Wi-Fi 6 (802.11ax)**: OFDMA, MU-MIMO en subida, BSS coloring y TWT. Su valor real es **eficiencia
  en densidad**, no velocidad punta. Casi todo exige que **el cliente** lo implemente: un parque
  mayoritariamente 802.11ac no se beneficia de OFDMA aunque el AP lo anuncie.
- **Wi-Fi 6E**: es Wi-Fi 6 **en 6 GHz**. El valor es espectro limpio sin legado, no una PHY nueva.
- **Wi-Fi 7 (802.11be-2024)**: canales de 320 MHz, 4096-QAM y **MLO** (multi-enlace). El único de los
  tres que cambia el diseño es MLO, y **sólo si el cliente lo soporta y en el modo que soporta**
  (muchos hacen conmutación entre enlaces, no agregación simultánea). 320 MHz es inaplicable con los
  480 MHz de la banda inferior de 6 GHz en la UE.
- **Regla**: el techo lo pone **el peor cliente relevante**, no la hoja de datos del AP. Antes de
  justificar una compra, inventaría el parque: flujos espaciales, bandas y estado del driver.

**Espectro**
- **2,4 GHz**: 3 canales no solapados (1/6/11), ruido no Wi-Fi (Bluetooth, microondas, iluminación).
  Es una banda de compatibilidad, no de capacidad.
- **5 GHz**: la banda de trabajo. Incluye subbandas sujetas a **DFS**, donde el AP debe abandonar el
  canal ante detección de radar: con radar cercano (costa, aeropuertos, meteorología) **excluye DFS
  del plan**, y verifica qué subbandas son de interior obligatorio en tu jurisdicción (§8).
- **6 GHz**: en la **UE** sólo está armonizada la **banda inferior, 5945-6425 MHz** (480 MHz), con
  **LPI limitado a 23 dBm PIRE y uso en interiores** y **VLP** (portátiles, ~14 dBm PIRE) admitido
  también en exterior. **No hay potencia estándar con AFC en la UE**: es lo que decide el diseño —
  6 GHz **no cubre exteriores ni naves grandes** aquí, a diferencia de EE. UU. En **España** la banda
  se incorporó al CNAF con las mismas condiciones europeas. La **banda superior (6425-7125 MHz) está
  sin resolver en la UE** (mandato a CEPT, decisiones esperadas 2026-2027, con Reino Unido por otra
  vía): **no diseñes contando con ella**.
- **Por qué los canales anchos reducen capacidad en densidad**: cada duplicación del ancho **halla la
  mitad de canales reutilizables** y reparte la misma potencia en más espectro (menos SNR en el
  borde). Además la escucha previa es sobre el canal completo: **un solo subcanal de 20 MHz ocupado
  bloquea la transmisión entera**. Más ancho sube el pico de un cliente y baja el agregado del
  edificio.

**Dimensionar por capacidad, no por cobertura**
- **El error más común del dominio**: diseñar hasta que el mapa esté verde. La cobertura es el
  requisito trivial; el que falla es la **capacidad** — clientes por radio, aplicaciones y su caudal,
  y sobre todo **tiempo de aire disponible**.
- Método: censo de dispositivos por zona (no de personas) → caudal por aplicación → clientes por
  radio como presupuesto explícito → APs necesarios → **y sólo entonces** comprobar que la cobertura
  sale. Si la capacidad manda, sale más AP a menos potencia, no menos AP a más potencia.
- **Solapamiento y reutilización**: solape suficiente para itinerar y **mínima interferencia
  cocanal**; la utilización del canal es la métrica de saturación —por encima de umbrales sostenidos
  el problema es aire, no señal. Densidad alta y techos altos exigen **antenas direccionales y
  control de la propagación vertical**.

**Estudio de sitio**
- El **predictivo** (planos a escala, materiales reales, atenuaciones calibradas) es una
  **hipótesis**; la **validación medida** con el AP y la antena reales, en las bandas que se van a
  usar y con análisis de espectro para interferencia no Wi-Fi, es el resultado. Un diseño no validado
  no está entregado.
- Entregable documentado: plan de canales y potencias, ubicaciones con motivo, umbrales objetivo, y
  las zonas donde se aceptó no cumplirlos.

**Itinerancia**
- **La decisión de saltar la toma siempre el cliente.** La red informa (**802.11k**, informe de
  vecinos) y sugiere (**802.11v**, BSS Transition Management, opcionalmente con *disassociation
  imminent*); **802.11r** sólo hace **rápido** el salto una vez decidido, reutilizando material
  criptográfico. Ninguno obliga.
- Consecuencia: los **clientes pegajosos** no se arreglan en el AP, se arreglan **quitando motivos
  para quedarse** — celdas pequeñas, potencias bajas, tasas mínimas altas y solape correcto.
- 802.11r es el que más rompe parques antiguos: despliégalo por SSID y por fases, con ventana de
  prueba y plan de vuelta atrás.

## 4. Gates de calidad

- **Validación medida** contra los umbrales de §2 antes de dar por buena una instalación, en las
  bandas reales, con el cliente típico y con la aplicación real (no sólo ping).
- **Prueba de itinerancia con la aplicación crítica** (voz, terminal, escáner) recorriendo el camino
  real, midiendo cortes, no observando barras.
- **Prueba negativa de aislamiento**: desde el SSID de invitados, verificar que **no** se alcanza la
  red corporativa ni otro cliente del mismo SSID. Un invitado probado sólo por el camino feliz no
  está probado.
- **Prueba de fallo de un AP**: apagarlo y comprobar cobertura y capacidad residual de sus vecinos.
  Si el diseño no lo aguanta, está declarado o está mal.
- **Prueba de autenticación**: cliente con certificado caducado, revocado y de CA equivocada **debe
  ser rechazado**. Si conecta, el 802.1X es decorativo.
- **Config como código y diff**: la configuración de SSID, RADIUS y radio vive en repo y se aplica
  por automatización (`network-automation-standards`); un AP distinto de sus pares es un hallazgo.

## 5. Seguridad

- **WPA3 por defecto**; WPA2-Personal está muerto para uso corporativo (PSK compartida = credencial
  que nadie puede rotar ni revocar por usuario). **SAE** elimina el ataque de diccionario offline
  sobre el 4-way handshake y exige **PMF (802.11w)**.
- **El modo de transición WPA3/WPA2 es una degradación anunciada**: mientras exista, un atacante
  fuerza WPA2. Si se usa, con fecha de retirada y `Transition Disable` planificado; en 6 GHz no
  existe. Para clientes problemáticos, el **modo de compatibilidad con RSN overriding** no expone
  WPA2 a los capaces.
- **802.1X/EAP con certificados (EAP-TLS)** frente a PSK: identidad por dispositivo/usuario,
  revocable, sin secreto compartido. Con PEAP/TTLS siguen habiendo contraseñas en juego.
- **El fallo silencioso más común: el cliente no valida el certificado del servidor RADIUS.** Sin
  validación de CA **y** de nombre del servidor, un AP falso captura credenciales corporativas y
  nadie se entera. Es configuración **de cliente**, no de red: se distribuye por MDM/GPO como perfil
  obligatorio, se prohíbe "confiar" manualmente, y se verifica en el gate de §4. Un despliegue
  802.1X sin esto es peor que inútil, porque genera confianza injustificada.
- **Invitados**: VLAN propia, aislamiento cliente-a-cliente, salida filtrada y limitada, sin ruta
  hacia gestión ni servidores. Portal cautivo siempre sobre TLS con nombre propio; **OWE** cifra el
  aire sin credencial pero **no autentica**: no lo vendas como control de acceso.
- **WIDS/WIPS**: útil para inventario de AP no autorizados y ataques de desautenticación, pero
  **genera mucho ruido** y su clasificación automática de "rogue" incluye vecinos legítimos. La
  contención por radio se activa sólo sobre lo clasificado a mano y **jamás sobre espectro de
  terceros** (contraproducente y potencialmente ilegal). Sin nadie que triaje, no es un control.
- **Lo que no es un control de seguridad**: **ocultar el SSID** (el nombre viaja en las peticiones de
  los clientes y empeora su itinerancia) y **filtrar por MAC** (la MAC se falsifica en un comando, y
  la aleatorización de MAC de los clientes modernos rompe la lista de todos modos). Nombrarlos como
  medidas en un documento de seguridad es un hallazgo.
- Los AP son equipos de red: gestión OOB, sin credenciales de fábrica, firmware al día y **puerto de
  acceso con 802.1X** — un AP arrancado de la pared da acceso a su troncal.

## 6. Operación

- **Se mide con datos de cliente, no con mapas de calor teóricos.** Señales que deciden: utilización
  del canal y tiempo de aire por radio, SNR y MCS **por cliente**, reintentos, fallos de asociación y
  autenticación por causa, itinerancias y su duración, y eventos DFS. Un mapa verde con 80% de
  utilización es una red caída.
- **Correlaciona con la aplicación**: la queja "la Wi-Fi va mal" casi nunca es la Wi-Fi. Descarta en
  orden aire → cliente/driver → autenticación/RADIUS → DHCP/DNS → WAN antes de tocar el diseño.
- **Actualizaciones** de AP y controladora por fases, con ventana y vuelta atrás; los cambios de
  firmware alteran comportamiento de itinerancia y de radio. La nube actualiza sola: **fija ventana
  y anillos, o los sufrirás en horario laboral**.
- **Gestión en nube**: verifica qué pasa al caer la WAN (los AP deben seguir sirviendo y
  autenticando: RADIUS local o caché) y dónde reside la telemetría (dato personal). **La radio se
  revisa periódicamente**: cambian el mobiliario, la densidad y los vecinos; un plan de canales de
  hace tres años ya no es el plan.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: firmware de AP y controladora por trimestre y ante CVE explotable; parque de AP
  planificado por generaciones, con fin de soporte del fabricante inventariado antes de que muerda.
- **Regla de SSID**: pocos y con motivo escrito —cada SSID emite balizas en cada AP y en cada banda,
  así que la lista es un presupuesto de tiempo de aire, no un menú—, y el SSID retirado desaparece de
  verdad (configuración, RADIUS, documentación).

**PROHIBIDO**
- ❌ Desplegar AP sin estudio de sitio, o entregar un estudio predictivo sin validación medida.
- ❌ Diseñar por cobertura cuando el requisito es capacidad; "más potencia" como solución.
- ❌ Canales de 80 MHz o más en entorno denso; 40 MHz en 2,4 GHz (siempre).
- ❌ Dejar habilitadas las tasas de datos más bajas y luego quejarse de la utilización del canal.
- ❌ PSK compartida en la Wi-Fi corporativa, o PSK sin caducidad en invitados.
- ❌ WPA2 en despliegues nuevos; modo de transición WPA3 sin fecha de retirada.
- ❌ 802.1X sin validación obligatoria del certificado del servidor en el cliente (CA **y** nombre).
- ❌ Presentar SSID oculto o filtrado por MAC como control de seguridad.
- ❌ SSID de invitados sin VLAN propia, sin aislamiento cliente-a-cliente y sin filtrado de salida.
- ❌ Contención automática de WIPS sobre redes de terceros, o WIPS sin nadie que triaje sus alertas.
- ❌ Diseñar 6 GHz para exterior o para grandes distancias bajo la regulación europea vigente.
- ❌ Contar con la banda superior de 6 GHz o con AFC en la UE antes de que exista decisión.
- ❌ Activar 802.11r en toda la flota de golpe sin ventana de prueba ni vuelta atrás.
- ❌ Justificar una compra por generación sin inventariar el parque de clientes que la aprovecharía.
- ❌ Canales DFS en zonas con radar conocido, o plan de canales automático nunca revisado.

## 8. Verificación web obligatoria

**Metodología**: los números IEEE y el estado regulatorio se verifican contra la fuente primaria
(IEEE 802.11 WG, decisiones de la Comisión Europea/CEPT, CNAF publicado en el BOE), no contra blogs.

**Verificado ago-2026**: **Wi-Fi 7 = IEEE Std 802.11be-2024**, aprobado el 26-sep-2024 y **publicado
el 22-jul-2025**; **la revisión base vigente es IEEE Std 802.11-2024**, publicada el 28-abr-2025.
**Wi-Fi 6 = 802.11ax**; **Wi-Fi 8 = 802.11bn (UHR)**, con borrador 1.0 en 2025 y publicación y
certificación previstas **2027-2028**: no es una opción de compra hoy. **802.11k/v/r ya están
incorporados a la revisión base** (no son amendments vivos): cítalos por su función, no como
estándares sueltos. **WPA3 es obligatorio en toda certificación Wi-Fi Alliance nueva desde 2020 y en
6 GHz**, junto con PMF; el **modo de transición es una opción de despliegue, no un mandato, y no
existe en 6 GHz**. **6 GHz en la UE**: sólo **5945-6425 MHz** armonizada, **LPI 23 dBm PIRE e
interior**, **VLP** con potencia muy inferior también en exterior, **sin potencia estándar ni AFC**;
la banda superior **6425-7125 MHz** está bajo mandato a CEPT con decisión esperada **2026-2027**. En
**España** la banda inferior entró en el CNAF por la **Orden ETD/1449/2021** con las condiciones de
la Decisión de Ejecución (UE) 2021/1067.

**Discrepancia declarada**: las fuentes divergen en el calendario de Wi-Fi 8 — publicación IEEE en
mar-2028 según unas y finalización en may-2028 según otras, con certificación Wi-Fi Alliance situada
entre dic-2027 y ene-2028. Todas coinciden en lo que decide: **no en 2026**.

**Huecos declarados — NO rellenar de memoria**:
1. **Nota UN exacta del CNAF para 6 GHz y su redacción vigente**: la referencia se localizó en
   fuentes secundarias; **verifica el texto consolidado en el BOE** antes de citar número de nota o
   límites en un documento formal.
2. **PIRE exacta de VLP** y condiciones de VLP en exterior: no transcritas de fuente primaria.
3. **Subbandas de 5 GHz sujetas a DFS/TPC y a uso interior obligatorio** en España y en la UE: **no
   verificadas** en esta pasada. Son específicas de jurisdicción y cambian el plan de canales.
4. **Umbrales concretos de utilización del canal, clientes por radio y RSSI/SNR por aplicación**: son
   criterio de ingeniería y guía de fabricante, no medidas universales. Valídalos con carga real.
5. **Estado de MLO por cliente y modo soportado** (agregación frente a conmutación) por chipset y SO:
   **no verificado**, y es lo que decide si Wi-Fi 7 aporta.
6. **Versión, mantenimiento y licencia en crudo** de `hostapd`/`wpa_supplicant`, FreeRADIUS y de las
   herramientas de estudio de sitio, y **comportamiento de la aleatorización de MAC** por sistema
   operativo y su efecto en NAC: **no verificados**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
