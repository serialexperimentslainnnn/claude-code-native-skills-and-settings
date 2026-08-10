---
name: streaming-multimedia-standards
description: Video/audio ingest, transcoding, packaging and delivery pipelines. Use when working with HLS playlists (.m3u8, #EXT-X-*), MPEG-DASH manifests (.mpd), CMAF/fMP4 segments, LL-HLS, codec selection H.264/AVC, HEVC, AV1, VVC and their patent pools, ffmpeg/ffprobe transcode commands and ladders, GStreamer pipelines (gst-launch-1.0), DRM with Widevine/FairPlay/PlayReady and CENC/cbcs, SCTE-35 ad markers, subtitle and caption delivery (WebVTT, TTML/IMSC, CEA-608/708, #EXT-X-MEDIA TYPE=SUBTITLES, DASH text AdaptationSet) and audio-description renditions, RTMP/SRT/WHIP (WebRTC) ingest, Media over QUIC (MoQ), media servers (MediaMTX, Ant Media, Wowza, OBS as encoder), or managed services (AWS MediaLive/MediaPackage/IVS, Mux, Cloudflare Stream).
---

# Estándares de streaming multimedia

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **pipeline multimedia**: ingesta (RTMP/SRT/WHIP), transcodificación y escalera de
bitrates, empaquetado (HLS/DASH/CMAF), DRM, latencia (VOD, live estándar, LL-HLS, tiempo real
con WebRTC/MoQ), elección de codec **con su coste de patentes** —el dato caro del dominio— y
elección entre servidor propio y servicio gestionado.

Triggers: `.m3u8`, `#EXT-X-VERSION`/`#EXT-X-PART` y demás etiquetas HLS, `.mpd`, segmentos
fMP4/CMAF, `ffmpeg`/`ffprobe` (transcodificación, `-c:v libx264/libx265/libsvtav1`, filtros,
escaleras ABR), `gst-launch-1.0` y pipelines GStreamer, Widevine/FairPlay/PlayReady,
CENC (`cenc`/`cbcs`), licencias de HEVC/AV1/VVC, SCTE-35, RTMP, SRT, WHIP/WHEP, LL-HLS,
Media over QUIC, MediaMTX, Ant Media, Wowza, OBS, MediaLive/MediaPackage/IVS, Mux,
Cloudflare Stream, "el directo llega con 30 segundos de retraso", "el vídeo no reproduce en
Safari/iPhone".

**No aplica**: ver `caching-cdn-standards` (**la CDN, la caché HTTP, sus cabeceras y su coste de
egreso son suyos** — un segmento HLS es un objeto HTTP cacheable más; aquí se decide cómo se
empaqueta y con qué duración, allí cómo lo sirve el borde), `webgl-webgpu-standards` (render en
navegador: canvas, WebGL/WebGPU, WebCodecs como API gráfica), `frontend-web-platform-standards`
(el elemento `<video>`, Media Source Extensions y EME como plataforma web genérica; aquí qué
manifiesto y qué DRM se le entrega), `edge-computing-standards` (cómputo en el borde como
plataforma; aquí solo si el transcode/repackage vive ahí), `e-commerce-standards` (la tienda que
incrusta el vídeo), `accessibility-standards` (**el criterio de conformidad y su alcance legal son suyos**: WCAG
1.2.2/1.2.4/1.2.5, subtítulos frente a transcripción, audiodescripción, quién firma la
declaración. **Aquí la mecánica de entrega de esas pistas**: producir el WebVTT o el TTML/IMSC,
declararlo en `#EXT-X-MEDIA TYPE=SUBTITLES,FORCED` o en el `AdaptationSet` de texto del `.mpd`,
CEA-608/708 incrustado frente a pista lateral, la pista de audio con descripción como
*rendition* aparte, y validar que el reproductor de cada plataforma la ofrece. **El aviso que
ambas sostienen: una pista de subtítulos que el empaquetador no declara no existe para el
usuario**, y el requisito se da por incumplido aunque el fichero esté en el bucket),
`gaming-infrastructure-standards` (voz y streams de partida en juego),
`object-storage-standards` (el bucket de origen de VOD), `gpu-computing-standards` (la GPU como
recurso de cómputo; aquí solo el criterio de encoder hardware vs software).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión **y el estado de los pools de patentes** por web antes de fijar
> nada en un proyecto real (§8). Estado verificado a ago-2026:

| Decisión | Por defecto | Alternativa justificable | Motivo |
|---|---|---|---|
| Formato de entrega | **HLS con segmentos CMAF (fMP4)** | DASH además, si el negocio exige clientes que no traguen HLS | HLS reproduce en todo (Apple lo exige en iOS/Safari); CMAF permite un solo juego de segmentos para HLS+DASH |
| Codec base | **H.264/AVC** siempre presente en la escalera | — | El único que decodifica todo el parque; sus patentes esenciales están mayoritariamente expiradas o expirando |
| Codec de eficiencia | **AV1** (SVT-AV1) donde el cliente lo soporte, con fallback H.264 | HEVC si el parque objetivo es Apple/TV y se acepta el coste de licencia | AV1 sin royalty declarado por AOMedia; HEVC con doble peaje (dispositivo y ahora también distribución) — ver aviso abajo |
| VVC | **No en producción** | Piloto con hardware que lo soporte | Soporte de decodificación marginal en el parque y pool de patentes en consolidación |
| Transcodificador | **ffmpeg** (9.0, ago-2026; rama 8.1.x mantenida) | GStreamer (1.28.x; 1.30 prevista Q4-2026) cuando el pipeline es de larga vida, con appsink/appsrc o elementos propios | ffmpeg para batch/CLI; GStreamer como framework embebible |
| Encoder en vivo (contribución) | **OBS Studio** (32.2.x, jul-2026, GPL-2.0; WHIP y WebRTC nativos desde 32.1) | Encoder hardware | Estándar de facto de contribución |
| Ingesta | **SRT o WHIP (RFC 9725)** para nuevo diseño; RTMP solo por compatibilidad | — | RTMP es legado sin cifrado nativo ni recuperación de pérdida; WHIP ya lo soportan OBS, IVS, Cloudflare y Mux |
| Servidor propio ligero | **MediaMTX** (v1.20.0, ago-2026, **MIT** — leído del LICENSE): SRT/RTSP/RTMP/WebRTC/LL-HLS/MoQ en un binario Go | Ant Media (CE + Enterprise ~99 USD/mes/instancia) para WebRTC a escala; Wowza (4.9.7, comercial, desde ~195 USD/mes) | Simplicidad, licencia limpia, mantenimiento muy activo |
| Servicio gestionado | **Mux o Cloudflare Stream** para producto; **AWS IVS** para latencia <3 s interactiva; **MediaLive+MediaPackage** cuando se necesita control fino del pipeline | — | Comprar el pipeline es casi siempre más barato que operarlo; comparar por minutos codificados + minutos entregados + almacenamiento |
| Latencia objetivo | VOD y live normal: **HLS estándar (6-30 s)**; "casi directo": **LL-HLS (2-6 s)**; conversacional/subastas: **WebRTC (<500 ms)** | **MoQ**: prometedor (sub-segundo a escala CDN) pero **draft IETF (draft-ietf-moq-transport-17, jul-2026), no RFC** — solo pilotos | Cada peldaño de latencia multiplica coste y complejidad: no pedir tiempo real si el negocio tolera 6 s |
| DRM | **Multi-DRM vía CMAF con cifrado común**: Widevine (Android/Chrome), FairPlay (Apple), PlayReady (TV/Xbox/Edge legacy), servido por un proveedor multi-DRM | Sin DRM + tokens firmados de CDN si solo se necesita control de acceso | Ningún DRM único cubre todo el parque; `cbcs` es el esquema que los tres soportan sobre CMAF — verificar la matriz exacta (§8) |

**Aviso de patentes — el dato caro (ago-2026), verificado por web, no de memoria**:

- **Consolidación de pools**: en dic-2025 **Access Advance adquirió la administración del pool
  HEVC/VVC de Via LA** (renombrado *VCL Advance*). El pool HEVC Advance subió tarifas un 25 % a
  quien firme después del **30-jun-2026** (fecha ya extendida una vez — verificar la vigente).
- **La distribución ya no es gratis**: desde 2025 existen pools que reclaman royalties **al
  servicio de streaming por el contenido distribuido** (Avanci Video y el *Video Distribution
  Patent Pool* de Access Advance, que cubre HEVC, VVC, VP9 **y AV1**), rompiendo la práctica
  anterior de cobrar solo al dispositivo.
- **AV1 "royalty-free" está en litigio**: en mar-2026 Dolby (licenciante de Access Advance)
  demandó a Snap por infracción de patentes **de AV1** y HEVC — primera acción contra una
  implementación AV1. AV1 sigue siendo la mejor apuesta de coste, pero "gratis" es una posición
  de AOMedia, no un hecho jurídico cerrado. **AV2**: spec finalizada (may-2026); sin parque de
  decodificación — no es opción de producción aún.
- **Regla**: la elección de codec es decisión de coste y jurídica, se documenta en ADR con
  asesoría legal si el volumen es serio, y se re-verifica el estado de los pools **antes de
  cada renovación o lanzamiento** (§8).

## 3. Estructura y convenciones

- **Escalera ABR por contenido, no genérica**: resoluciones/bitrates decididos según el
  contenido (deporte ≠ charla), con tope en la resolución que el negocio paga. Cada peldaño se
  valida con métrica perceptual (VMAF/SSIM), no a ojo. La escalera mínima incluye siempre un
  peldaño bajo (~300-500 kbps) para redes malas.
- **Duración de segmento**: 4-6 s en HLS/DASH estándar (equilibrio latencia/eficiencia de
  caché); partes de 0,3-1 s solo en LL-HLS. Segmentos alineados entre renditions (misma
  cadencia de keyframes: `-g` = fps × duración, `keyint_min` igual) o el ABR *switching* rompe.
- **CMAF único**: un solo juego de segmentos fMP4 referenciado por manifiesto HLS y DASH;
  duplicar segmentos por formato duplica almacenamiento y hunde el hit-ratio de la CDN.
- **Nombres de segmento inmutables y versionados** (nunca reescribir un segmento publicado):
  la política de caché correspondiente es de `caching-cdn-standards`.
- **Audio**: AAC-LC universal; Opus donde el cliente lo soporte; loudness normalizado (EBU R 128).
- **El pipeline es código**: comandos ffmpeg/pipelines GStreamer versionados y parametrizados,
  nunca "el comando que funcionó en la terminal de alguien". Presets con nombre y ADR.

## 4. Calidad y testing

- **Validación de manifiestos y streams como gate de CI**: Apple `mediastreamvalidator`/HLS
  report para HLS, DASH-IF conformance para DASH; `ffprobe` sobre la salida (codec, perfil,
  cadencia de keyframes, duración de segmento) tras cada cambio de preset.
- **Calidad perceptual medida**: VMAF por peldaño contra la fuente en un set de clips de
  referencia propio; regresión de VMAF al cambiar encoder o versión de ffmpeg **rompe el build**.
- **Matriz de reproducción real**: Safari/iOS (el cliente más restrictivo: HLS nativo, FairPlay,
  soporte de codec distinto), Chrome/Android, una TV/stick representativa. El emulador no
  detecta los fallos de DRM ni de hardware decode.
- **Bordes obligatorios**: pérdida de ingesta a mitad de directo (¿el manifiesto se recupera o
  queda envenenado?), cambio de calidad bajo red degradada, *seek* a mitad de un directo con
  DVR, expiración de licencia DRM durante la reproducción, discontinuidades SCTE-35.

## 5. Seguridad del stack

- **DRM ≠ control de acceso**: DRM protege el contenido licenciado; para "que no lo vea quien
  no pagó" suele bastar URL firmada/token de CDN con expiración corta. No comprar multi-DRM
  para un problema de tokens.
- **Claves**: las claves de contenido y las credenciales del servidor de licencias jamás en el
  cliente ni en el manifiesto; rotación de claves en directos largos.
- **Ingesta autenticada**: stream keys tratadas como secretos (rotables, revocables); SRT con
  passphrase; WHIP con token corto. Un endpoint RTMP abierto es un canal de publicación anónimo
  en tu dominio.
- **ffmpeg/GStreamer procesan entrada hostil**: un fichero subido por un usuario es un exploit
  potencial contra el demuxer (historial largo de CVEs en ambos). Transcodificación de contenido
  de usuario **en sandbox/worker aislado sin credenciales**, versiones al día, formatos de
  entrada acotados por allowlist.
- Cumplimiento de contenido: DRM y marcas según contrato con el licenciante (el estudio suele
  exigir nivel de seguridad concreto de Widevine/PlayReady por resolución — verificar contrato).

## 6. Rendimiento y operabilidad

- **SLI del dominio**: tiempo de arranque de reproducción, ratio de rebuffering, latencia
  extremo a extremo en directo (medida, no estimada: timestamp incrustado o marca visual),
  errores de licencia DRM, tasa de fallo de ingesta. La telemetría del reproductor (o el dato
  del servicio gestionado tipo Mux Data) es la única visión real.
- **Coste**: el streaming es un negocio de **egreso**; la escalera ABR y la eficiencia de codec
  son decisiones de coste tanto como de calidad (más peldaños = más transcode + más almacenamiento;
  mejor codec = menos GB entregados). Egreso y hit-ratio → `caching-cdn-standards`.
- **Encoder hardware (NVENC/Quick Sync/VCN) para directo a escala; software (x264/SVT-AV1) para
  VOD donde la calidad por bit domina** — el hardware paga densidad con eficiencia de compresión.

## 7. Cuándo NO / Prohibiciones

- ❌ **WebRTC "porque el directo va lento"** cuando el negocio tolera 3-6 s: LL-HLS escala por
  CDN, WebRTC exige infra de SFU por espectador. Cada peldaño de latencia se justifica con un
  requisito, no con un deseo.
- ❌ MoQ en producción a ago-2026 (draft en movimiento) salvo piloto con ruta de fallback.
- ❌ Elegir HEVC (o asumir AV1 gratis) **sin verificar el estado de los pools de patentes en la
  fecha de la decisión** — es la decisión más cara del dominio y cambió dos veces en un año.
- ❌ RTMP como ingesta de diseño nuevo sin justificar compatibilidad.
- ❌ Segmentos distintos por formato pudiendo servir CMAF único; keyframes desalineados entre
  renditions.
- ❌ Transcodificar contenido de usuario en el mismo proceso/host que maneja credenciales.
- ❌ Stream keys en repos, logs o URLs de ejemplo; endpoint de ingesta sin autenticación.
- ❌ Montar y operar servidor de streaming propio cuando un gestionado cubre el caso — el coste
  real es el on-call del pipeline, no la licencia. Propio solo con requisito (dato, coste a
  escala, latencia, soberanía) escrito en ADR.
- ❌ "Se ve bien en mi Chrome" como validación: Safari/iOS es el gate.
- ❌ DRM casero u ofuscación como sustituto de Widevine/FairPlay/PlayReady si el contrato exige
  protección de contenido.

## 8. Verificación web obligatoria

1. **Pools de patentes** — el dato caro: estado de HEVC Advance/VCL Advance (Access Advance),
   Avanci Video y el Video Distribution Patent Pool; tarifas y fecha límite vigente (la de
   jun-2026 ya fue extendida una vez); estado del litigio Dolby vs Snap sobre AV1. Fuentes:
   `accessadvance.com`, notas de prensa primarias, no foros.
2. **ffmpeg**: última release en `ffmpeg.org/download.html` (9.0 a 2026-08-04; ramas 8.1.x y
   7.1.x mantenidas) y CVEs del demuxer.
3. **GStreamer**: `gstreamer.freedesktop.org/releases/` (1.28.6 a ago-2026, rama en
   mantenimiento; 1.30 prevista Q4-2026).
4. **OBS**: `obsproject.com` y releases de GitHub (32.2.1, jul-2026).
5. **MediaMTX**: `api.github.com/repos/bluenviron/mediamtx/releases` (v1.20.0, ago-2026) y su
   `LICENSE` en crudo (MIT).
6. **MoQ**: estado de `draft-ietf-moq-transport` en datatracker.ietf.org (¿sigue en draft o ya
   es RFC?) — a jul-2026, draft-17.
7. **LL-HLS/HLS**: spec de Apple (`developer.apple.com`) y RFC 8216 + extensiones; WHIP =
   **RFC 9725**.
8. **Servicios gestionados**: precios y modelo (por minuto codificado/entregado/almacenado) de
   Mux, Cloudflare Stream, IVS y MediaLive en sus páginas oficiales — cambian con frecuencia.
9. **Matriz DRM/codec por navegador y dispositivo** (qué combinación de `cenc`/`cbcs`, codec y
   robustez soporta cada cliente): verificar en documentación vigente de cada DRM.
10. **Huecos declarados** (no verificados en esta redacción — no rellenar de memoria): tarifas
    concretas por unidad de los pools (solo se verificó su existencia y el +25 %); precios
    exactos de Wowza y Ant Media (proceden de agregadores, no de la página oficial); matriz
    exacta `cbcs` vs `cenc` por plataforma; estado de soporte VVC en hardware de 2026; niveles
    de robustez Widevine/PlayReady exigidos por los estudios hoy.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
