---
name: gaming-infrastructure-standards
description: Multiplayer game hosting infrastructure. Use when orchestrating dedicated game servers with Agones (GameServer, Fleet, FleetAutoscaler CRDs, agones-sdk), running session-based servers on Kubernetes, matchmaking as a service (Open Match / open-match2, matchmaker tickets and backfill), managed backends (Amazon GameLift Servers, Azure PlayFab Multiplayer Servers, Unity Multiplay, Epic Online Services, Nakama/Heroic Labs, Edgegap), fleet scaling and cost per CCU or per session, UDP DDoS protection for game traffic, server browser and session allocation, or in-game voice/chat services and their compliance.
---

# Estándares de infraestructura de juego

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a la **infraestructura que aloja el multijugador**: hosting y orquestación de servidores
dedicados de partida, asignación y ciclo de vida de sesiones, escalado y coste de flota,
matchmaking como servicio, backends gestionados, protección del tráfico UDP y los servicios de
voz/chat con su cumplimiento. Esta skill existe por cesión pactada: `game-development-standards`
le cede **servidores dedicados, orquestación de sesiones, escalado y coste de flota, transporte,
matchmaking como servicio**, y `xr-standards` le cede **servidores y sesiones multiusuario**.

**Tesis**: un servidor de partida **no es un microservicio**. Es un proceso **con estado, de
vida corta y no interrumpible**: no se balancea por petición, no se drena en segundos, no se
mata en un rolling update sin echar a los jugadores. Toda la disciplina de la skill deriva de
ahí: asignación de sesión en lugar de balanceo, apagado solo cuando la partida termina, escalado
que protege las sesiones vivas, y coste medido por sesión/CCU porque la flota ociosa es el
coste dominante.

Triggers: `GameServer`, `Fleet`, `GameServerAllocation`, `FleetAutoscaler`, agones-sdk,
`Allocated`/`Ready` states; Open Match tickets/backfill; GameLift (`fleet`, `game session`,
FlexMatch), PlayFab MPS (build, pool, allocation), Multiplay, EOS, Nakama, Edgegap; "cuánto nos
cuesta cada partida", "el autoscaler mata partidas vivas", "nos tiran el servidor por UDP flood",
server browser, voz de proximidad.

**No aplica**: ver `game-development-standards` (**el protocolo y el modelo de autoridad del
juego son suyos**: netcode, predicción/reconciliación, lockstep, anticheat, validación en
servidor — aquí el proceso servidor ya existe y se trata como carga que alojar),
`xr-standards` (la experiencia XR y su presupuesto de confort; aquí sus sesiones multiusuario),
`kubernetes-standards` (el clúster como plataforma: RBAC, upgrades, nodos — aquí lo específico
de la carga de juego sobre él), `load-balancing-standards` (el balanceador clásico L4/L7; la
asignación de sesión de aquí es precisamente **no** balancear), `edge-computing-standards` (la
plataforma de borde en general; aquí solo el criterio de colocar servidores cerca del jugador),
`e-commerce-standards` y `fintech-payments-standards` (**la tienda del juego es una tienda**: el
catálogo, el precio, el impuesto y el carrito son de la primera; **desde el cobro en adelante
—pasarela, PCI DSS, SCA, reembolso y contracargo— es de la segunda**, y el hecho de que la moneda
sea virtual no lo cambia. Lo que sí es de aquí: que el servidor valide el recibo y que el
*webhook* de la tienda se verifique por firma, porque el cliente miente),
`streaming-multimedia-standards` (**la retransmisión de partidas es un pipeline de vídeo y es
suyo**: ingesta, transcodificación, empaquetado, latencia y el modo espectador como entrega;
**aquí solo la voz en partida** y el hecho de que se compra antes que construirse),
`chaos-engineering-standards` (**el experimento de resiliencia es legítimo aquí, con un límite**:
se acota a los servidores `Ready` y a la ruta de reposición, nunca a los `Allocated` — §7),
`networking-standards`
(la red como disciplina; aquí el perfil UDP del tráfico de juego), `finops-standards` (unidad
económica y gobierno de coste; aquí la métrica de dominio: coste por sesión/CCU),
`sre-practice-standards` (SLO y guardia; aquí qué SLI son los del dominio).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión y el estado comercial por web antes de fijar nada (§8). **Este
> mercado se movió fuerte en 2025-2026** (Multiplay deprecado, Agones a CNCF, GameLift cambió
> su modelo de coste): casi todo lo que circula está caducado. Estado verificado a ago-2026:

| Decisión | Por defecto | Alternativa justificable | Motivo |
|---|---|---|---|
| ¿Backend gestionado u orquestación propia? | **Gestionado**, salvo escala/soberanía que lo justifique en ADR | Agones sobre Kubernetes propio | El on-call de una flota global 24/7 es el coste oculto; propio solo con equipo de plataforma real |
| Orquestación propia | **Agones** (CNCF Sandbox desde dic-2025, donado por Google; v1.58.x, cadencia ~6 semanas, SDKs Go/C++/C#/Unity/Unreal/Python) | Kubernetes a pelo con StatefulSets: **no** — reimplementa mal el ciclo Ready/Allocated | Único orquestador de game servers con comunidad real (Google+Ubisoft de origen, 800+ contribuidores) |
| Gestionado en AWS | **Amazon GameLift Servers** | Contenedores propios en EKS+Agones | Modelo de coste renovado en 2026: **ancho de banda gratis desde jun-2026 (instancias gen 6+)** y **scale-to-zero (ene-2026)** — re-presupuestar, las comparativas antiguas ya no valen |
| Gestionado en Azure / consola Xbox | **PlayFab Multiplayer Servers** (activo, sin retirada anunciada; "Foundation Mode" GDC 2026) | — | Integración Xbox y LiveOps |
| Unity Multiplay | **NO para diseño nuevo: deprecado el 1-abr-2026** (sin nuevas allocations; continuidad solo para quien migró a "Multiplay by Rocket Science") | GameLift, Edgegap, Agones | Aviso de cierre con ~3 meses: lección sobre riesgo de proveedor único |
| Backend social/ligero (auth, leaderboards, matchmaking simple, salas) | **Nakama** (Heroic Labs; servidor Apache-2.0, clientes Apache-2.0; Heroic Cloud como gestionado) o **Epic Online Services** (gratuito, multiplataforma) | PlayFab | Para juegos sin servidor dedicado de simulación, esto basta y evita toda la flota |
| Matchmaking como servicio | El del backend elegido (FlexMatch, PlayFab, Nakama, EOS) | **Open Match, solo con cautela**: el 1.x original (Apache-2.0) no está archivado pero su última release soporta Kubernetes 1.24/1.25 — mantenimiento de facto parado; existe `open-match2` con actividad baja. **No es base sólida para diseño nuevo sin evaluación fresca** (§8) | Un matchmaker propio es un sistema distribuido con colas, estado y picos: se compra salvo requisito de diseño de matching propio |
| Colocación geográfica | Regiones según latencia medida de la base de jugadores; borde (Edgegap y similares) solo si el percentil de RTT lo justifica | — | La latencia del jugador la fija la física, no el marketing |
| Unidad de coste | **Coste por sesión y por CCU**, con la flota ociosa como línea propia | — | El buffer de servidores Ready es el precio de la latencia de matchmaking: se dimensiona, no se elimina |

## 3. Estructura y convenciones

- **Ciclo de vida de sesión, el patrón canónico** (Agones lo nombra, todos lo implementan):
  el servidor arranca → `Ready` (en el buffer caliente) → el matchmaker/allocator lo marca
  `Allocated` y entrega la IP:puerto a los clientes → la partida transcurre → el servidor
  **se autodeclara terminado y muere**; nunca se reutiliza proceso entre partidas sin motivo
  (estado residual = bugs y ventaja de trampa).
- **La asignación es del allocator, no de un balanceador**: los clientes se conectan directo
  (o vía relay) al servidor asignado. Un L7 LB delante de UDP de partida es un anti-patrón.
- **Escalado protege sesiones**: el autoscaler mantiene un buffer de `Ready` (tamaño = tasa de
  inicio de partidas × tiempo de arranque, con margen para el pico diario) y **solo** recoge
  servidores vacíos. Drenaje = dejar de asignar + esperar fin de partida (horas, no segundos);
  los upgrades de nodo/imagen se hacen por rotación de flotas (verde/azul de flota), no por
  rolling update de pods.
- **El patrón de carga es de picos con huso horario**: pico vespertino por región, picos de
  lanzamiento y de evento 10-100× la media. Scale-to-zero para entornos de prueba y juegos
  pequeños; capacidad reservada + spot **solo para el buffer, jamás para sesiones vivas** (una
  interrupción de spot echa a los jugadores).
- **Sesión rastreable**: cada partida con ID, servidor, versión de build, región y jugadores —
  es la unidad de observabilidad, de coste y de soporte.

## 4. Calidad y testing

Una línea (se omite como sección plena): la calidad de esta capa se prueba con **partidas
sintéticas** — bots que llenan sesiones reales contra la flota de staging — midiendo tiempo de
matchmaking, tiempo de arranque de servidor, y que el autoscaler y el drenaje no matan
partidas; el test de carga del lanzamiento simula el pico de día 1, no la media. El resto →
`testing-qa-standards` y `game-development-standards` (netcode).

## 5. Seguridad del stack

- **DDoS sobre UDP — postura defensiva**: el tráfico de juego es UDP con IP:puerto del servidor
  expuestos a cada cliente, y el flood es el ataque barato estándar (incluido el jugador que
  tira el servidor de su rival). Defensa en capas: protección del proveedor (GameLift/PlayFab
  la traen; en propio, scrubbing del cloud o de un tercero), **rate limit y validación de
  paquete en el primer salto** (paquete no conforme al protocolo se descarta sin procesar,
  con token de sesión emitido en la asignación para filtrar tráfico no autenticado), y
  **relays/IP efímeras por sesión** para no exponer la flota de forma estable. Nada de
  recetario ofensivo: diseño de mitigación, no de ataque.
- **El servidor de partida corre código del juego con entrada hostil**: proceso sin privilegios,
  sin credenciales de plano de control en el pod/instancia (el SDK sidecar de Agones existe
  exactamente para eso), y egress acotado — un game server comprometido no debe poder tocar la
  base de datos de cuentas.
- **Voz y chat — cumplimiento, no solo feature**: moderación y canal de denuncia obligatorios
  si hay menores (DSA en la UE, COPPA en EE. UU.); retención mínima y base legal del audio
  (grabar voz es dato personal, y biométrico si se analiza) → `privacy-engineering-standards`.
  Comprar (Vivox, EOS Voice, Discord SDK…) antes que construir; verificar términos y regiones
  del proveedor (§8).
- Los secretos de plataforma (claves de tienda, backend) **nunca** en la imagen del servidor
  distribuida; la imagen del server dedicado que se entrega a la comunidad (self-hosting) se
  trata como publicada.

## 6. Rendimiento y operabilidad

Una línea (se omite como sección plena): los SLI del dominio son **tiempo de matchmaking (p95)**,
**tiempo de sesión asignada→jugable**, **partidas muertas por causa de infraestructura** (el
SLI sagrado: objetivo ≈0), RTT por región y **coste por sesión/CCU con la ociosidad como línea
propia**; el marco de SLO/guardia es de `sre-practice-standards` y la plataforma de métricas de
`observability-standards`.

## 7. Cuándo NO / Prohibiciones

**Cuándo NO usar esta skill entera**: si el juego no tiene servidor dedicado (P2P/relay simple,
un cooperativo con host jugador), la respuesta correcta suele ser un backend social (Nakama/EOS)
y ningún orquestador — no montes flota para un juego que no la necesita.

- ❌ Tratar un game server como microservicio: balanceo por petición, rolling updates que matan
  pods `Allocated`, drenaje en segundos, health check que reinicia una partida "colgada" con
  jugadores dentro.
- ❌ Sesiones de jugadores sobre **instancias spot/preemptibles**.
- ❌ Experimentos de caos (`chaos-engineering-standards`) sobre servidores `Allocated`. La
  disciplina es legítima y útil aquí, pero **el blast radius se acota a los `Ready` y a la ruta
  de reposición**: lo que se refuta es "si pierdo capacidad libre, ¿el autoescalado repone antes
  de que falte?", no "¿qué pasa si echo a mil jugadores?".
- ❌ Recomendar **Unity Multiplay** (deprecado abr-2026) o adoptar **Open Match** para diseño
  nuevo sin evaluación fresca de su mantenimiento (§2, §8).
- ❌ Kubernetes a pelo (Deployments/StatefulSets) reinventando el ciclo Ready/Allocated que
  Agones ya resuelve.
- ❌ Flota propia global "para ahorrar" sin contabilizar guardia 24/7, parcheo y DDoS: el
  gestionado se descarta con números, no con instinto.
- ❌ Proveedor único sin plan de salida: la muerte de Multiplay con ~3 meses de aviso es el
  precedente. La imagen del servidor se mantiene portable (contenedor estándar, SDK de
  orquestador aislado tras una interfaz propia).
- ❌ Exponer la flota con IP:puerto estables y sin validación de primer paquete; procesar
  paquetes sin token de sesión.
- ❌ Reutilizar proceso de servidor entre partidas sin limpieza justificada.
- ❌ Voz/chat sin moderación ni denuncia en un juego accesible a menores, o grabando audio sin
  base legal declarada.
- ❌ Presupuestar con comparativas de coste anteriores a 2026 (el ancho de banda gratis de
  GameLift desde jun-2026 invalida las tablas previas).
- ❌ Construir matchmaker propio sin requisito de matching que ningún servicio cubra, escrito
  en ADR.

## 8. Verificación web obligatoria

1. **Agones**: última versión y Kubernetes soportados en `agones.dev` y
   `api.github.com/repos/agones-dev/agones/releases` (v1.58.0, may-2026; K8s 1.33-1.35);
   estado CNCF (Sandbox desde 2025-12-21 — ¿ha subido a incubating?).
2. **Open Match**: estado real de `googleforgames/open-match` (verificado ago-2026:
   `archived: false`, push 2026-07-12, Apache-2.0, pero última release para K8s 1.24/1.25) y
   de `open-match2` — decidir con la actividad del mes, no con este documento.
3. **GameLift Servers**: precios y novedades en `aws.amazon.com/gamelift` (ancho de banda
   gratis gen 6+ desde 2026-06-15; scale-to-zero ene-2026; fin de Realtime scripts Node.js 10
   el 2026-09-30).
4. **PlayFab MPS**: `learn.microsoft.com` y `playfab.com/pricing` — sin retirada anunciada a
   ago-2026; confirmar antes de comprometerse.
5. **Unity Multiplay**: estado de la deprecación (2026-04-01) y de "Multiplay by Rocket
   Science" en los avisos oficiales de Unity.
6. **Nakama**: `LICENSE` en crudo del repo (`heroiclabs/nakama`, Apache-2.0) y qué exige la
   edición Enterprise/Heroic Cloud; **EOS**: términos y catálogo vigente en
   `dev.epicgames.com`.
7. **Proveedor de voz** elegido: términos, regiones, retención y herramientas de moderación en
   su documentación oficial.
8. **Regulación de chat/voz con menores**: estado de DSA aplicado, COPPA y guías del regulador
   local — dato en movimiento.
9. **Huecos declarados** (no verificados — no rellenar de memoria): precios concretos de
   Edgegap, Heroic Cloud y PlayFab MPS por unidad; estado de Multiplay by Rocket Science como
   producto; paridad real de features entre open-match2 y Open Match 1.x; SLA de los
   proveedores de voz.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
