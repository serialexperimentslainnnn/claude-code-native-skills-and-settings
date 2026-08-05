---
name: incident-response-forensics-standards
description: Use for the technical response to a security compromise and its investigation — NIST SP 800-61r3 and SANS PICERL phases, containment that preserves evidence, RFC 3227 order of volatility, memory and disk imaging, hashing and chain of custody, cloud snapshot and control-plane log acquisition, container and ephemeral artifacts, super-timeline with plaso/log2timeline and Timesketch, Velociraptor, GRR, KAPE, Volatility 3, Autopsy/Sleuth Kit, YARA-X, CyberChef, IOC and ATT&CK mapping, eradication and rebuild from trusted source, mass credential and token rotation, ransomware, identity-compromise, supply-chain and insider playbooks, breach notification timelines under GDPR, NIS2 and DORA.
---

# Estándares de respuesta a incidentes de seguridad y análisis forense

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a la **respuesta técnica ante un compromiso de seguridad y a la investigación que lo explica**:
preparación forense, triaje de indicios, contención sin destruir evidencia, adquisición y preservación
de evidencia (memoria, disco, nube, contenedores, identidad), análisis y construcción de timeline,
determinación de alcance y vector de entrada, erradicación, recuperación verificada, playbooks por
tipo de compromiso, coordinación con la notificación regulatoria y la devolución de aprendizaje al
sistema de detección.

Triggers: "compromiso", "intrusión", "IOC", "malware", "ransomware", "exfiltración", "webshell",
"persistencia", "movimiento lateral", "token robado", "cuenta comprometida", "imagen forense", "dd /
dcfldd / ewfacquire", "volcado de memoria", "LiME", "hash de evidencia", "cadena de custodia",
"orden de volatilidad", "RFC 3227", "PICERL", "NIST 800-61", "super timeline", "plaso",
"log2timeline", "Timesketch", "Velociraptor", "GRR", "KAPE", "Volatility", "Autopsy", "Sleuth Kit",
"YARA", "CyberChef", "snapshot forense", "CloudTrail / Activity Log / Cloud Audit Logs", "auditd",
"$MFT", "prefetch", "shellbags", "erradicación", "reconstrucción", "rotación masiva de credenciales".

**Principio rector**: **el resultado de un incidente se decide antes de que ocurra.** Lo que no esté
instrumentado, retenido y accesible el día 0 no se puede investigar el día 1 — y ninguna herramienta
compensa la ausencia de telemetría. Corolario operativo: **no se restaura lo que no se ha entendido**.
Un servicio devuelto a producción sin saber el vector de entrada es un incidente que se reabre, y la
segunda vez el atacante ya sabe cómo respondes.

**No aplica**:
- `incident-management-standards`: el **proceso de gestión** de cualquier incidente — declaración,
  severidad, IC y roles, comunicación, cadencia, cierre, postmortem, métricas del proceso. **Un
  incidente de seguridad usa las dos**: la gestión lo gobierna (quién manda, quién habla, cómo se
  decide), esta lo investiga (qué pasó, cómo entró, qué tocó, qué se preserva). Si necesitas decidir
  quién comunica o qué severidad asignar, vas a la skill hermana; si necesitas decidir si apagar la
  máquina, estás en el sitio correcto.
- `sre-practice-standards`: fiabilidad como disciplina (SLO, error budget, guardia, DORA). Su regla
  de "mitigar antes que entender" **se suspende parcialmente** cuando hay sospecha de compromiso: ver
  §3.2. La reclasificación de un incidente de fiabilidad a incidente de seguridad se decide con los
  criterios de §3.1.
- `observability-standards`: instrumentación, pipeline de telemetría y su **retención** — el
  prerrequisito de esta skill, no su contenido.
- `vulnerability-management-standards`: el CVE **antes** de que se explote (triaje, CVSS/EPSS/KEV,
  SLA, VEX). Cuando ya se explotó, el caso es de esta skill.
- `appsec-standards`: modelado de amenazas y clases de vulnerabilidad en código propio.
- `grc-compliance-standards`: marco normativo, obligaciones formales y evidencia de auditoría; aquí
  solo la mecánica operativa de preservar y de alimentar la notificación.
- `identity-access-management-standards`: break-glass, revocación de sesiones y tokens, política de
  MFA — el **cómo** se revoca durante el incidente.
- `cryptography-pki-standards`: rotación de claves y certificados comprometidos, revocación y
  reemisión.
- `ctf-lab-standards`: laboratorio aislado donde detonar muestras y practicar; esta skill **no** es
  entorno de entrenamiento.
- `onprem-standards`, `kubernetes-standards`, `networking-standards`, `cicd-standards`,
  `data-platform-standards`, `aws-standards`/`azure-standards`/`gcp-standards`, `homelab-standards`:
  la operación de cada plataforma.
- **Planificadas**: `detection-engineering-standards` (**Ola 1**; frontera **bidireccional y
  declarada**: allí se escribe la detección que **dispara** el incidente, y **cada investigación de
  aquí devuelve reglas nuevas** — la investigación que no deja detección es investigación a medias),
  `offensive-security-standards` (**existe ya en disco**: purple team, deconfliction con el SOC —
  toda actividad ofensiva autorizada se deconflicta antes de tratarla como incidente real, y el
  hallazgo de un **compromiso previo durante un ejercicio** detiene el ejercicio y activa este
  proceso), `secrets-management-standards` (**Ola 1**: rotación masiva tras el compromiso),
  `linux-hardening-standards` (**Ola 1**: `auditd` como fuente de evidencia y baseline que reduce
  superficie), `container-runtime-security-standards` (**Ola 1**: forense de contenedor y de nodo,
  captura en runtime), `privacy-engineering-standards` (**Ola 1**: brecha de datos personales),
  `bcdr-standards` (**Ola 1**: cuando la recuperación excede al servicio y activa continuidad),
  `backup-recovery-standards` (**Ola 2**: restauración verificada y backups inmutables),
  `assembly-standards` (**Ola 5**: fija cuándo se **escribe** ensamblador propio y cómo se
  mantiene; **el análisis de un binario ajeno para responder a un incidente es de aquí** —cadena de
  custodia, orden de volatilidad, triaje del artefacto—), `solidity-standards` (**Ola 5**: el
  contrato y su plan de incidente escrito antes del despliegue son suyos; **la gestión del
  incidente real y el trazado de fondos, de aquí**).

## 2. Decisiones por defecto

> Verificar la última versión y el estado de mantenimiento por web antes de fijarlas (§8). Los datos
> son de agosto 2026 y caducan: este ecosistema se mueve en meses.

| Ámbito | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Marco de referencia | **NIST SP 800-61r3** (abril 2025) para el **gobierno** + **SANS PICERL** para la **ejecución** | Rev. 3 reestructura las recomendaciones sobre las seis funciones del CSF 2.0 y deja de ser un manual de fases; el ciclo operativo (Preparation, Identification, Containment, Eradication, Recovery, Lessons learned) sigue siendo el que se ejecuta. **Citar Rev. 2 (2012) como vigente es un error** |
| Orden de recogida | **RFC 3227** (BCP, aún vigente y no obsoletado) | Su lógica se traslada a nube y contenedores; los procedimientos cambian, el orden no |
| Recolección remota a escala | **Velociraptor** (0.77.1, jun 2026; AGPL, mantenido por Rapid7 tras la adquisición de 2021) | **GRR** (v4.0.0.0, dic 2025) si ya está desplegado; verifica su ritmo de mantenimiento antes de apostar por él |
| Triaje de endpoint Windows | **KAPE** | Gratuito para uso interno/gubernamental/educativo, **licencia de pago para engagements de terceros**; cadencia de publicación opaca desde 2024. Alternativa OSS: artefactos de Velociraptor |
| Memoria | **Volatility 3** (2.28.x, abr 2026; v2 deprecada desde la 2.26 "feature parity") | Windows: símbolos automáticos vía PDB. **Linux: tabla de símbolos generada con `dwarf2json` a partir de un kernel con símbolos de depuración, con banner exacto** — esto se prepara *antes*, no durante |
| Captura de memoria Linux | **LiME** o AVML; en nube, snapshot + captura en vivo del agente | Verifica compatibilidad con el kernel **antes** del incidente |
| Imagen de disco | Formato **E01/EWF** (`ewfacquire`) o raw (`dd`/`dcfldd`) con hash al vuelo | E01 por compresión y metadatos de caso; raw por interoperabilidad |
| Timeline | **plaso/log2timeline** (releases mensuales/trimestrales, activo) → **Timesketch** (Google, activo, releases 2026) | Super-timeline solo cuando el triaje no basta: es caro en tiempo y en ruido |
| Análisis de sistema de ficheros | **Autopsy 4.23.x / Sleuth Kit 4.15.x** (abr-may 2026, activos) | Herramienta comercial si el caso es judicial y se exige validación de terceros |
| Reglas de detección de artefactos | **YARA-X** (1.19.x, jun 2026) | YARA 4.x está en **modo mantenimiento**: reglas nuevas en YARA-X |
| Transformación de datos ad-hoc | **CyberChef** (11.3.0, jul 2026), **autoalojado y offline** | La instancia pública es de terceros: **nunca** pegues datos del caso en ella |
| Taxonomía de adversario | **MITRE ATT&CK**, versión vigente | v19 (abr 2026) es la actual; v18 introdujo Detection Strategies y Analytics en sustitución de Data Sources — el mapeo antiguo no traduce solo |
| Retainer de IR | **Contratado antes**, con SLA de activación y accesos preacordados | Contratar la respuesta con el incendio en marcha cuesta días y multiplica el precio |
| Decisión de pagar rescate | **No es técnica**: legal + dirección + seguros, con evaluación de sanciones | Ver §5 y §8 |

## 3. Ejecución: de la sospecha a la recuperación

### 3.0 Preparación (lo que decide el resultado)

Se audita **antes**, con estas preguntas. Un "no" es un hallazgo, no un matiz:

- **Telemetría**: ¿existen logs de autenticación, ejecución de procesos (`auditd`/Sysmon/EDR), red,
  DNS, plano de control de nube y acceso a datos? ¿Con qué **retención**? La ventana de retención es
  el límite duro de lo que podrás reconstruir: un atacante con 90 días de dwell time y 30 días de
  logs es una investigación que termina en "no se puede determinar".
- **Integridad**: ¿los logs se envían a un destino **fuera del alcance del administrador local y del
  atacante**, con almacenamiento inmutable o WORM? Logs que el atacante puede borrar no son evidencia.
- **Relojes**: ¿NTP sincronizado y zona horaria documentada en toda la flota? **Todo el análisis se
  normaliza a UTC.** Un desfase de reloj arruina una timeline entera.
- **Inventario**: ¿sabes qué activos existen, quién los posee y qué datos contienen? Sin inventario
  no hay alcance, y sin alcance no hay notificación correcta.
- **Accesos de emergencia**: ¿hay break-glass con MFA, auditado, **independiente del IdP corporativo**?
  La pregunta de control: **¿sabrías responder con el dominio / el IdP comprometido?** Si la respuesta
  depende de iniciar sesión con el SSO que investigas, no tienes plan.
- **Herramientas listas**: binarios estáticos y de confianza en medio propio, workstation de análisis
  aislada, almacenamiento de evidencia dimensionado, y **probado** en un simulacro.
- **Playbooks** por tipo de incidente (§5) con la decisión ya tomada en frío, no a las 03:00.
- **Retainer de IR y contactos**: forense externo, aseguradora, legal/DPO, CSIRT de referencia
  (INCIBE-CERT / CCN-CERT / ESPDEF-CERT en España) y fuerzas y cuerpos de seguridad, con números y
  procedimiento fuera del sistema que puede estar caído o comprometido.

### 3.1 Identificación y triaje

- **Criterios de reclasificación** de un incidente operativo a incidente de seguridad: autenticación
  o cambio de permisos inexplicado, proceso o binario desconocido persistente, tráfico saliente a
  destino no previsto, borrado o alteración de logs, cifrado o alteración masiva de ficheros,
  aparición de cuentas o claves nuevas, alerta de detección con contexto coherente. **Ante la duda,
  se trata como compromiso**: el coste de equivocarse hacia arriba es unas horas; hacia abajo, el
  incidente entero.
- **Triaje antes que análisis profundo**: recolección de artefactos clave a escala (Velociraptor/KAPE)
  para responder tres preguntas en horas, no en semanas — **¿está el atacante dentro ahora?**,
  **¿hasta dónde llegó?**, **¿qué datos tocó?**. El análisis profundo (malware, ingeniería inversa)
  se hace después y **solo hasta donde aporte a la respuesta**: entender el binario completo es
  investigación, no respuesta.
- **Hipótesis explícitas y contrastadas**, con lo que las confirmaría y lo que las refutaría. Un
  informe forense sin hipótesis alternativas descartadas es una narración.
- **Marca de confianza** en cada conclusión: confirmado / probable / posible / descartado. Se
  documenta la evidencia que sostiene cada una.

### 3.2 Contención sin destruir evidencia

- **Aislar, no destruir.** Sacar de la red (VLAN de cuarentena, security group deny-all, política de
  red del clúster) mantiene el sistema vivo y con su memoria; borrar, recrear o reinstalar mata la
  investigación.
- **Excepción a "mitigar antes que entender"**: cuando la mitigación es destructiva y hay sospecha de
  compromiso, se **preserva primero**. El IC (ver `incident-management-standards`) registra la
  decisión, quién la toma y a costa de qué. Si el impacto de negocio obliga a restaurar ya, se captura
  al menos memoria y snapshot antes, y se deja constancia de lo que se pierde.
- **Apagar vs. no apagar**, criterio explícito:
  - **No apagar** por defecto: se pierde memoria (procesos, conexiones, claves de cifrado, payloads
    solo residentes, credenciales), que es a menudo la única prueba del vector.
  - **Apagar (o cortar energía)** si el daño en curso supera el valor de la memoria: cifrado activo,
    exfiltración en marcha sin poder cortar la red, riesgo de seguridad física. **Cortar energía** en
    lugar de apagar ordenadamente cuando se teme un script de shutdown manipulado que destruya
    evidencia (RFC 3227 lo advierte explícitamente).
  - **Nunca reiniciar** "a ver si se arregla".
- **Orden de volatilidad (RFC 3227)**: registros y caché → tabla de rutas, caché ARP, tabla de
  procesos, estadísticas de kernel, **memoria** → sistemas de ficheros temporales → **disco** →
  logging remoto y monitorización → configuración física y topología de red → soportes de archivo.
- **No confiar en los binarios del sistema comprometido**: herramientas desde medio propio y de
  confianza. Toda ejecución en el sistema deja huella: se documenta qué se ejecutó, cuándo y por quién.
- **OPSEC de la investigación**: asume que el atacante ve lo que tocas. No investigues desde la cuenta
  comprometida ni desde el sistema afectado; no uses el canal corporativo si puede estar comprometido;
  no bloquees indicadores uno a uno mientras investigas (le enseñas tu progreso y provoca que cambie
  de infraestructura o dispare un destructor). **La contención se planifica y se ejecuta de golpe**,
  cuando el alcance está acotado — salvo daño activo, donde se corta ya.
- **Identidad primero en nube**: revocar sesiones y tokens, desactivar (no borrar) claves, y **hacerlo
  como una acción coordinada**. Ver `identity-access-management-standards`.

### 3.3 Adquisición y cadena de custodia

- **Hash en el momento de la adquisición** (SHA-256; MD5 solo como identificador heredado y **nunca**
  como única garantía) y **reverificación en cada transferencia**. Sin hash de origen, la evidencia
  es un fichero cualquiera.
- **Bloqueo de escritura** en adquisición física; en nube, snapshot y copia a una cuenta/proyecto de
  forense **separado** con almacenamiento inmutable y versionado activado.
- **Cadena de custodia** documentada: qué se adquirió, de qué sistema, cuándo (UTC), con qué
  herramienta y versión, quién, hashes, y cada traspaso posterior. **Importa aunque nunca llegue a un
  juzgado**: es lo que hace que tu conclusión sea reproducible, revisable por un tercero y defendible
  ante una aseguradora, un cliente, un auditor o un regulador. La disciplina de custodia es disciplina
  de método, no formalismo jurídico.
- **Trabaja sobre copias**, nunca sobre el original; el original se preserva intacto.
- **Retención de la evidencia** definida y coordinada con legal (litigation hold si procede) y con la
  minimización de datos personales — dos obligaciones que pueden tirar en direcciones opuestas: lo
  arbitra legal/DPO, no ingeniería.
- **Por plataforma**:
  - **Linux**: memoria (LiME/AVML), disco, `auditd`, `journald`/`syslog`, `/var/log/{auth,secure}`,
    `~/.*history`, unidades systemd y timers, `cron`, claves SSH autorizadas, `/tmp` y `/dev/shm`,
    módulos de kernel, paquetes con integridad alterada.
  - **Windows**: memoria, `$MFT`/`$UsnJrnl`, registro (SYSTEM/SOFTWARE/SAM/NTUSER), Event Logs
    (Security, System, PowerShell Operational, Sysmon si existe), Prefetch, Amcache/Shimcache, tareas
    programadas, servicios, WMI persistente, ShellBags, LNK/Jump Lists.
  - **macOS**: memoria si es viable, Unified Logs, LaunchAgents/LaunchDaemons, TCC, FSEvents,
    quarantine attributes.
  - **Nube**: **plano de control primero** (CloudTrail / Activity Log + Entra ID / Cloud Audit Logs),
    porque es lo que el atacante puede desactivar o rotar; después metadatos de instancia
    (configuración, rol IAM, security groups, user data, tags, interfaces — **cambian al contener y
    no se recuperan**), snapshots de disco, y logs de acceso a datos. Documenta lo que el proveedor
    **no** te da: en SaaS solo hay logs de auditoría; en PaaS no hay sistema operativo.
  - **Contenedores y efímeros**: la evidencia **se evapora por diseño**. Captura antes de que el
    orquestador recree: sistema de ficheros del contenedor (`checkpoint`/`export`), memoria del
    proceso, `/proc` del PID en el nodo, imagen y su digest, manifiesto y variables, logs del runtime
    y del nodo, y eventos de admisión y del API server. Si el pod ya se ha recreado, la evidencia
    está en el **nodo** y en el registro de imágenes, no en el contenedor.
  - **Identidad**: logs de autenticación, tokens y refresh tokens emitidos, dispositivos registrados,
    consentimientos de aplicaciones OAuth, reglas de reenvío de correo, cambios de MFA. En compromiso
    de identidad, **esto es la escena del crimen**, no el servidor.

### 3.4 Análisis

- **Timeline primero**, hipótesis después. Timeline de artefactos clave para acotar; **super-timeline**
  (plaso → Timesketch) cuando hace falta correlación fina entre fuentes. Todo en **UTC**, con la
  fuente de cada evento anotada.
- **Determina y documenta**: vector de entrada (patient zero), primera actividad (no la primera
  alerta), persistencia, escalada, movimiento lateral, credenciales comprometidas, datos accedidos o
  exfiltrados, y **dwell time**. Si no puedes determinar algo, dilo: "no se pudo determinar con la
  telemetría disponible" es una conclusión válida y accionable; inventarlo no.
- **Alcance por iteración**: cada indicador nuevo se busca **en toda la flota**, no solo en el equipo
  afectado. Un compromiso se cierra cuando la búsqueda a escala deja de dar resultados nuevos, no
  cuando se limpia la primera máquina.
- **Mapea a ATT&CK** para comunicar, para comparar y para cerrar huecos de detección — no como
  ejercicio decorativo.
- **Análisis de malware acotado**: extraer IOCs, capacidades, persistencia y C2 es respuesta; la
  ingeniería inversa completa es investigación y se externaliza o se pospone. Detonación **solo** en
  laboratorio aislado (ver `ctf-lab-standards`), nunca en la red corporativa ni en una VM del hipervisor
  de producción.

### 3.5 Erradicación y recuperación

- **No se restaura hasta poder responder**: ¿cuál fue el vector?, ¿está cerrado?, ¿qué persistencia
  había y se ha eliminado toda?, ¿qué credenciales se comprometieron y se han rotado?
- **Reconstrucción desde origen confiable > limpieza.** Limpiar un sistema comprometido casi nunca es
  defendible: no puedes demostrar la ausencia de persistencia en un sistema que el atacante controló,
  y las técnicas modernas (firmware, tareas, WMI, cuentas, claves, imágenes de contenedor) sobreviven
  a la limpieza. Excepciones justificables: sistema donde la reconstrucción no es viable a corto plazo
  y el riesgo se acepta **formalmente por escrito**, con vigilancia reforzada y fecha de sustitución.
- **Restaurar desde backup verificando que el backup no está comprometido**: identifica el momento del
  compromiso inicial (no el de la detección) y restaura desde un punto **anterior**; verifica la
  integridad del backup y **escanéalo antes de reconectarlo**. Un backup posterior al día 0 restaura
  también al atacante. Coordina con `backup-recovery-standards` (Ola 2) y `bcdr-standards` (Ola 1).
- **Rotación masiva de credenciales** con criterio de alcance, no de conveniencia: contraseñas de
  cuentas afectadas y privilegiadas, `krbtgt` (dos veces, con el intervalo de replicación entre ambas)
  si hubo compromiso de dominio, claves de API y tokens, secretos de aplicación, claves SSH, claves
  de firma y certificados (ver `cryptography-pki-standards` y `secrets-management-standards`), sesiones
  y refresh tokens (ver `identity-access-management-standards`). **Rotar la mitad es no rotar.**
- **Vigilancia reforzada** post-recuperación con ventana definida (30-90 días) y detecciones
  específicas del caso: el retorno del mismo atacante es el escenario más frecuente.
- **Corte coordinado**: la erradicación se ejecuta como una acción única y planificada (cerrar vector,
  eliminar persistencia, rotar credenciales, cortar C2). Hacerlo por partes le da al atacante tiempo
  de reaccionar y reestablecerse.

## 4. Calidad de la investigación (los gates)

1. **Reproducibilidad**: otro analista, con la misma evidencia y las notas del caso, llega a la misma
   conclusión. Notas de caso con marca temporal, comandos ejecutados y versiones de herramienta. Sin
   esto, no hay investigación: hay opinión.
2. **Integridad de la evidencia**: hashes de origen registrados y **reverificados** al cierre; cadena
   de custodia completa y sin huecos.
3. **Hipótesis contrastadas**: cada conclusión con la evidencia que la sostiene, las alternativas
   consideradas y por qué se descartaron. Distinción explícita entre **hecho observado** e
   **inferencia**.
4. **Marca de confianza** en cada afirmación (confirmado / probable / posible) y declaración explícita
   de las **limitaciones**: qué no se pudo determinar y por qué (retención insuficiente, logs
   borrados, ausencia de telemetría). Es de las partes más útiles del informe: alimenta el backlog.
5. **Revisión por pares** obligatoria antes de emitir el informe o de comunicar a dirección, cliente o
   regulador — especialmente si de él se derivan obligaciones legales o contractuales.
6. **Cierre de alcance verificable**: la búsqueda de indicadores a escala se ha ejecutado sobre el
   **inventario completo** y la última iteración no produjo resultados nuevos.
7. **Verificación de la erradicación** antes de restaurar: vector cerrado (probado), persistencia
   eliminada (buscada específicamente), credenciales rotadas (listadas), detecciones nuevas activas.
8. **Lecciones al detector**: **todo incidente produce reglas de detección nuevas** y requisitos de
   telemetría nuevos, con dueño y fecha, entregados a `detection-engineering-standards` (Ola 1) y a
   `observability-standards`. Una investigación que no deja detección deja el mismo agujero abierto.
9. **Ejercicio de la capacidad**: simulacro forense periódico — adquirir memoria y disco de un sistema
   real, con las herramientas reales y las personas reales, cronometrado. Descubre que LiME no compila
   contra el kernel actual en el simulacro, no durante el incidente.

## 5. Casos especiales y encuadre legal

### Ransomware

- **Contener el cifrado primero** (aislar en masa, cortar propagación, deshabilitar cuentas de
  servicio abusadas); preservar memoria de un equipo aún encendido puede contener la clave.
- **Asume exfiltración previa al cifrado**: la doble extorsión es el patrón dominante. El incidente es
  una **brecha de datos** hasta que se demuestre lo contrario, con las obligaciones que eso dispara.
- **Verifica los backups antes de confiar en ellos**: el borrado o cifrado de backups es parte del
  playbook del atacante. Backups **inmutables y offline** son el control que decide el desenlace.
- **La decisión de pagar no es técnica**: la toman dirección, legal y la aseguradora. Consideraciones:
  pagar no garantiza descifrado ni el borrado de lo exfiltrado, financia al ecosistema, y **puede
  constituir infracción si el receptor está sancionado**. En el Reino Unido avanza una prohibición
  para sector público y CNI más deber de notificar antes de pagar; en la UE y España no hay
  prohibición general y la vía es transparencia y régimen de sanciones/AML (§8: **verifícalo, cambia
  rápido**). Pagar **no extingue** la obligación de notificar ni detiene la investigación penal.
- Consulta `nomoreransom.org` por si existe descifrador antes de cualquier decisión.

### Compromiso de identidad / token

- La escena es el IdP: sesiones, tokens, dispositivos, consentimientos OAuth, reglas de correo,
  métodos de MFA registrados. **Cambiar la contraseña no invalida los tokens ya emitidos**: hay que
  revocar sesiones y refresh tokens explícitamente.
- Busca persistencia de identidad: aplicaciones con consentimiento, credenciales de cliente añadidas
  a service principals, federación manipulada, claves de firma de tokens comprometidas (el peor caso:
  invalida todo lo emitido y exige reemisión).

### Cadena de suministro

- El alcance no es tu red: es **todo lo que consumió el artefacto comprometido**. Determina versiones
  afectadas por digest, no por etiqueta. Precedente del catálogo: el compromiso de **Trivy en marzo de
  2026** obligó a retirarlo como default.
- Preserva el artefacto malicioso y su procedencia; notifica aguas arriba y aguas abajo. Revisa el
  pipeline como escena (`cicd-standards`): runners, credenciales OIDC, secretos y firmas.

### Insider

- Coordinación **obligatoria** con RRHH y legal **antes** de cualquier acción técnica; la preservación
  se hace sin alertar al sujeto y respetando el marco laboral y de protección de datos aplicable.
- Aquí la cadena de custodia sí acaba con frecuencia en un procedimiento formal: rigor máximo desde el
  primer minuto.

### Notificación regulatoria (encuadre, **no asesoramiento jurídico**)

**Quien decide si hay obligación de notificar es legal/DPO, no ingeniería.** El papel de esta skill es
producir a tiempo la información mínima: qué pasó, cuándo se supo, qué datos y categorías, cuántos
afectados aproximados, qué medidas se han tomado. Plazos vigentes verificados a agosto 2026 —
**verifícalos igualmente (§8)**:

- **RGPD art. 33**: ≤ **72 h** desde el conocimiento, a la autoridad de control (AEPD); comunicación a
  los afectados si hay riesgo alto (art. 34). Notificación **progresiva** admitida: se notifica con lo
  que se sabe y se amplía. Documentar toda brecha aunque no se notifique.
- **NIS2**: **alerta temprana ≤ 24 h**, **notificación ≤ 72 h**, **informe final ≤ 1 mes**. En España
  el CSIRT de referencia es INCIBE-CERT (privado), CCN-CERT (sector público) y ESPDEF-CERT (defensa).
  La transposición española seguía **sin publicarse en el BOE** en agosto de 2026.
- **DORA** (financiero): inicial ≤ **4 h** desde la clasificación como grave y ≤ 24 h desde la
  detección, intermedio ≤ 72 h, final ≤ 1 mes.
- **ENS (RD 311/2022)**: notificación al CCN-CERT vía LUCIA con plazos escalonados por impacto
  (CCN-STIC 817) — **no contrastado contra fuente primaria en esta revisión** (§8).
- **El reloj corre desde el conocimiento, no desde el diagnóstico.** Retener la notificación hasta
  cerrar la forense es el error más caro y más común.
- El detalle técnico que sale hacia fuera se coordina con legal y con el Comms lead
  (`incident-management-standards`): ni se oculta el impacto ni se publica el mapa de tu red.

## 6. Operabilidad de la capacidad de respuesta

- **Retención mínima útil**: 12 meses para autenticación, plano de control de nube y logs de
  seguridad; 90 días como suelo absoluto para el resto. El dwell time típico supera con holgura los
  30 días: retener 30 es garantizar investigaciones incompletas. Coste y valor se deciden **antes**
  (ver `observability-standards`).
- **Inmutabilidad**: destino de logs fuera del alcance de administradores locales; WORM/object lock en
  el almacén de evidencia y de backups.
- **Workstation de análisis** aislada, con su propio almacenamiento, sin acceso a producción y sin
  credenciales corporativas; herramientas verificadas por firma o hash antes de usar. Las muestras se
  manejan cifradas y con contraseña, y solo se detonan en laboratorio (`ctf-lab-standards`).
- **Automatiza la adquisición**: en nube, disparador que hace snapshot y aísla al recibir la alerta.
  La evidencia efímera no espera a que alguien despierte.
- **Dimensiona el almacenamiento de evidencia** por adelantado: un caso mediano son terabytes, y
  descubrirlo a mitad de adquisición te obliga a elegir qué evidencia perder.
- **Verifica las herramientas antes de necesitarlas**: símbolos de Volatility para tus kernels, LiME
  compilado para tus versiones, agente de Velociraptor desplegado y probado. Un agente que hay que
  desplegar durante el incidente es un cambio en la escena y un retraso de horas.
- **Descarga de herramientas solo desde upstream y con verificación**: mirrors y repackagers van
  meses por detrás (caso documentado con YARA-X). Fija por digest y verifica firma/atestación.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: playbooks revisados semestralmente y tras cada incidente que los use; catálogo de
  herramientas revisado semestralmente (mantenimiento, licencia, CVEs propias); matriz de obligaciones
  de notificación revisada anualmente y ante cualquier cambio normativo.
- **Deprecación**: retira de los playbooks toda herramienta sin mantenimiento activo. Herramienta
  forense abandonada = resultados no defendibles y superficie de ataque añadida.
- **La capacidad se entrena o se atrofia**: un simulacro forense anual como mínimo, con adquisición
  real y cronómetro.
- **Documentación viva mínima**: playbook por tipo de incidente, mapa de fuentes de evidencia con su
  retención, procedimiento de adquisición por plataforma, plantilla de cadena de custodia, matriz de
  notificación y lista de contactos fuera de banda.

**PROHIBIDO**
- ❌ Apagar o reiniciar un sistema comprometido sin criterio explícito, destruyendo la memoria.
- ❌ Reinstalar, recrear o "limpiar" antes de preservar; borrar el pod y perder el nodo con él.
- ❌ Investigar con la cuenta comprometida, desde el sistema afectado o con los binarios del propio
  sistema.
- ❌ Bloquear indicadores de uno en uno mientras investigas, avisando al atacante de tu progreso.
- ❌ Coordinar la investigación en el canal corporativo cuando puede estar comprometido.
- ❌ Restaurar sin erradicar, o restaurar desde un backup posterior al compromiso inicial sin verificarlo.
- ❌ Rotación parcial de credenciales tras un compromiso de dominio o de identidad.
- ❌ Trabajar sobre la evidencia original en lugar de sobre una copia verificada por hash.
- ❌ Evidencia sin hash de origen, sin cadena de custodia o sin normalización a UTC.
- ❌ Afirmar un hecho sin distinguirlo de una inferencia, o emitir un informe sin revisión por pares.
- ❌ Declarar "no hubo exfiltración" cuando lo que falta es telemetría: eso es "no se pudo determinar".
- ❌ Detonar muestras fuera de un laboratorio aislado, o subir muestras y artefactos del caso a
  servicios públicos (VirusTotal, CyberChef online, pastebins) sin autorización explícita: es
  exfiltración por tu parte y aviso al atacante.
- ❌ Contratar el retainer de IR cuando ya está ardiendo.
- ❌ Retrasar la notificación regulatoria hasta cerrar la investigación.
- ❌ Decidir el pago de un rescate en el plano técnico, o pagar sin evaluación de sanciones.
- ❌ Cerrar el caso sin reglas de detección nuevas ni requisitos de telemetría con dueño.
- ❌ Herramientas forenses sin mantenimiento, desde mirrors de terceros o sin verificación de firma.
- ❌ Usar YARA 4.x para reglas nuevas, o citar NIST SP 800-61 **Rev. 2** como guía vigente.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, plazo o referencia, **búscalo — no lo recuerdes**:

1. **NIST SP 800-61**: verificado ago-2026 — **Rev. 3, abril 2025**, *Incident Response Recommendations
   and Considerations for Cybersecurity Risk Management: A CSF 2.0 Community Profile*, sustituye a la
   Rev. 2 (2012) y se estructura sobre las seis funciones del CSF 2.0 en lugar del ciclo por fases.
   **Hueco declarado**: no se ha leído el PDF completo para confirmar el tratamiento exacto que da a
   contención/erradicación/recuperación — verifícalo antes de citar su estructura en detalle.
   Complementa con SP 800-86 (integración de forense en la respuesta) si sigue vigente.
2. **Plazos de notificación** (RGPD 72 h, NIS2 24/72 h/1 mes, DORA 4/24/72 h/1 mes, ENS/CCN-STIC 817):
   verifica **cada cifra** y el destinatario antes de usarla, y el estado de la transposición
   española de NIS2 (sin publicar en BOE a ago-2026) y de la revisión de NIS2 propuesta por la
   Comisión en enero de 2026. **Los plazos del ENS por nivel de impacto no se han contrastado contra
   fuente primaria en esta revisión.** El criterio legal es de legal/DPO.
3. **Postura sobre el pago de rescate**: Reino Unido (prohibición para sector público y CNI + deber de
   notificación previa, vía Cyber Security and Resilience Bill — **verifica si ya está en vigor**),
   UE/España (sin prohibición general; transparencia y sanciones). Cambia rápido.
4. **Estado de las herramientas** antes de recomendarlas — verificado ago-2026: Velociraptor 0.77.1
   (jun 2026, AGPL, Rapid7); Volatility 3 2.28.x (abr 2026, v2 deprecada); plaso (releases 2026 con
   cadencia trimestral); Timesketch (releases 2026, mínimo OpenSearch 2.19.5); Autopsy 4.23.x /
   Sleuth Kit 4.15.x (abr-may 2026); YARA-X 1.19.x (jun 2026, YARA 4.x en mantenimiento); CyberChef
   11.3.0 (jul 2026); GRR v4.0.0.0 (dic 2025 — **verifica su ritmo de mantenimiento**); KAPE
   (mantenido por Kroll, **cadencia de publicación opaca desde 2024 y licencia restringida para
   trabajo con terceros**).
5. **Incidentes de cadena de suministro** en cualquier herramienta que vayas a introducir en el
   entorno de respuesta (precedente: Trivy, marzo 2026). Verifica firma y atestación de procedencia.
6. **MITRE ATT&CK**: versión vigente y cambios de modelo — v19 (abr 2026) es la actual; v18 sustituyó
   Data Sources por Detection Strategies/Analytics. Confirma antes de mapear.
7. **Guías de forense en nube del proveedor** (AWS, Azure, GCP): procedimientos de snapshot,
   retención de logs de plano de control y sus límites. Cambian con los servicios.
8. **RFC 3227**: verificado ago-2026 — sigue siendo BCP y no ha sido obsoletado. Confirma que no ha
   aparecido sucesor antes de citarlo como única referencia.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
