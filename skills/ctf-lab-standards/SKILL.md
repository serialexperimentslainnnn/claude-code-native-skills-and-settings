---
name: ctf-lab-standards
description: Use when building or running an isolated security training lab or playing CTFs — host-only or internal-network VMs with snapshots, Kali, REMnux, FLARE-VM, INetSim, detonating challenge binaries or malware samples in a disposable VM, Hack The Box, TryHackMe, PortSwigger Web Security Academy, pwn.college, OverTheWire, Proving Grounds, CTFtime events, jeopardy vs attack-defense vs king-of-the-hill formats, writeups and platform terms of service, or planning OSCP/CPTS study.
---

# Estándares de laboratorio de seguridad y CTF

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **entrenar seguridad ofensiva en un entorno donde la autorización es intrínseca**:
construcción y aislamiento del laboratorio, ejecución segura de binarios de reto y muestras de
malware, uso de plataformas de entrenamiento dentro de sus términos, competición en CTF,
método de aprendizaje y medición del progreso, ética de la competición y transferencia (o no)
de lo aprendido al trabajo real. Triggers: "laboratorio de seguridad", "VM desechable",
"host-only", "snapshot antes de detonar", "Kali", "REMnux", "FLARE-VM", "INetSim",
"Hack The Box", "HTB", "TryHackMe", "PortSwigger Web Security Academy", "pwn.college",
"OverTheWire", "Proving Grounds", "CTFtime", "jeopardy", "attack-defense", "king of the hill",
"writeup", "flag", "pwn", "reversing", "OSCP", "CPTS".

### Precondición dura — dónde está la autorización aquí

En este dominio la autorización **no se firma, viene dada por el entorno**, y por eso hay que
comprobar que el entorno realmente la da. Solo se practica sobre **una** de estas tres cosas:

1. **Infraestructura propia** en un laboratorio aislado (VMs, targets vulnerables que tú has
   desplegado, tu propio código).
2. **Plataforma de entrenamiento** cuyos **términos de servicio vigentes** autorizan
   explícitamente la actividad, y **solo dentro de su alcance**: sus máquinas objetivo, no su
   infraestructura, no otros usuarios.
3. **CTF o evento** en curso, dentro de sus reglas publicadas y de su ventana.

Cualquier otra cosa —un sistema de un tercero, un servicio "que parece de prueba", el router
del vecino, la web de tu antigua empresa— **no está autorizada** y el marco penal es el mismo
que para un ataque real (ver §1 de `offensive-security-standards`: en España, arts. 197 bis y
197 ter y 264 CP; **el consentimiento del titular es lo que hace lícita la prueba**). Que sea
"para aprender" no es una eximente. **Esto no es asesoramiento jurídico**: ante duda, consulta
legal.

**No aplica**: ver `offensive-security-standards` (ejercicio ofensivo **autorizado contra
sistemas de un tercero o de la organización**: pentest, red team, purple team, bug bounty,
RoE, informe, retest — allí la autorización se firma y hay un cliente asumiendo riesgo;
**aquí no hay cliente ni riesgo de negocio, solo aprendizaje**), `homelab-standards`
(laboratorio personal **de propósito general**: hardware, consumo, coste, self-hosting,
backups de servicios que usas de verdad — **la frontera es el propósito y el aislamiento**:
aquí el laboratorio existe para detonar cosas hostiles y por eso está segmentado y es
desechable; allí para prestar servicio y por eso se le hace backup), `appsec-standards`
(clases de vulnerabilidad y su prevención en código propio),
`vulnerability-management-standards` (CVE, CVSS/EPSS/KEV, SLA de remediación),
`networking-standards` (diseño de red real, VLANs y firewalling de producción),
`kubernetes-standards`, `bash-linux-scripting-standards` (calidad del tooling propio),
`grc-compliance-standards`, `cryptography-pki-standards`,
`identity-access-management-standards`, `air-gapped-standards` (**suyos el registro/espejo
interno y el aislamiento de red como disciplina**; **aquí la dirección de la amenaza es la
inversa**: allí el aislamiento protege al recinto del mundo, aquí protege al mundo del
laboratorio), las skills de nube y de lenguaje. Además:
`incident-response-forensics-standards` (forense e IR reales — aquí solo la
categoría forense de un CTF, que se le parece poco),
`detection-engineering-standards`, `linux-hardening-standards`,
`container-runtime-security-standards`.

## 2. Decisiones por defecto

> Verificar por web versiones, estado de las plataformas y **sus términos de servicio
> vigentes** antes de fijar nada (§8). Los datos son de agosto 2026 y caducan.

| Ámbito | Default | Motivo / alternativa justificable |
|---|---|---|
| Aislamiento de red del lab | **Red `host-only` / interna del hipervisor, sin ruta a LAN doméstica ni a internet** | Es el control primario. Cualquier otra medida es secundaria; si el lab enruta a tu LAN, no es un lab, es un vector |
| Simulación de internet | **INetSim** en la VM Linux del lab respondiendo DNS y servicios | Permite que la muestra "vea internet" sin que la haya. Verificación mínima: desde la VM Windows, resolver un dominio debe dar la IP del servicio local y el tráfico externo debe fallar |
| VM de análisis Windows | **FLARE-VM** sobre Windows en VM dedicada, **nunca el host** | Exige desactivar la protección antivirus del sistema (o la instalación falla), lo que la vuelve inaceptable fuera de una VM aislada y desechable |
| VM de análisis/servicios Linux | **REMnux** (imagen prefabricada o sobre base Ubuntu LTS) | Trae el instrumental de análisis y hace de "internet falso" con INetSim |
| Distribución ofensiva | **Kali Linux** en VM, exclusiva del lab | Nunca como SO del host ni del portátil de trabajo: es un arsenal en el equipo desde el que gestionas tu vida |
| Estado de la VM | **Snapshot limpio antes de cada detonación; revertir siempre después** | La VM se considera comprometida en cuanto se ejecuta algo hostil. No se "limpia": se revierte |
| Credenciales y datos en las VMs del lab | **Ninguna real**: sin cuentas personales, sin tokens, sin claves SSH, sin sesiones de navegador, sin carpetas compartidas con el host | Las carpetas compartidas y el portapapeles del hipervisor son rutas de escape documentadas. Se desactivan |
| Plataforma web (base) | **PortSwigger Web Security Academy** | Gratuita, mantenida por el equipo de investigación de PortSwigger, laboratorios interactivos y rutas de aprendizaje de principiante a experto. Es el mejor punto de partida para web |
| Fundamentos de sistemas y pwn | **pwn.college** (curriculum universitario abierto) y **OverTheWire** para wargames de shell | Progresión estructurada y gratuita; verificar estado actual antes de recomendarlas (§8) |
| Plataforma de máquinas | **Hack The Box** y/o **TryHackMe**, según objetivo | THM guía más y frena menos al principiante; HTB penaliza más y enseña más al intermedio. HTB tiene **AUP estricta** sobre writeups y sobre uso del contenido (§4) |
| Calendario de competición | **CTFtime** | Referencia de eventos, formatos y ranking. Formatos que lista: **Jeopardy**, **Attack-Defence** y mixto/hack-quest — *King of the Hill* no es una etiqueta formal suya |
| Certificación | **Ninguna por defecto**; si hace falta, la que exija el mercado objetivo | **OSCP** sigue siendo la que filtran los reclutadores; **CPTS** (HTB) es mucho más barata y su examen de 10 días se parece más a un encargo real, pero está peor reconocida por ATS y reclutadores. La certificación abre la puerta; el laboratorio es lo que da la competencia |

## 3. Construcción del laboratorio

### Topología mínima

```
[ HOST ]  ── sin puente ──  ( red interna / host-only del hipervisor )
                                        │
                    ┌───────────────────┼───────────────────┐
              [ Analista/atacante ]  [ Servicios ]      [ Víctima ]
              Kali / REMnux          INetSim, DNS,      Windows + FLARE-VM
                                     captura            o target vulnerable
```

Reglas del diseño, en orden de importancia:

1. **Sin puente ni NAT hacia la LAN.** El adaptador de red de cada VM del lab va a una red
   interna del hipervisor. Si necesitas descargar herramientas, se hace **antes**, con la VM
   en NAT, y se conmuta a red interna **antes** de introducir nada hostil.
2. **Verificar el aislamiento, no asumirlo.** Comprobación explícita tras cada cambio de
   topología: desde la VM víctima, ni la puerta de enlace real ni una IP pública deben
   responder; sí debe responder el servicio simulado local. **Un lab cuyo aislamiento no se ha
   comprobado se considera no aislado.**
3. **Firewall del host activo** y, si el hipervisor lo permite, reglas que bloqueen el
   reenvío desde la red del lab. Defensa en profundidad: la red interna es el control, el
   firewall es el respaldo cuando alguien deja un adaptador mal configurado.
4. **Nada compartido con el host**: carpetas compartidas desactivadas, portapapeles
   bidireccional desactivado, arrastrar-y-soltar desactivado, USB no expuesto. Son
   precisamente los canales por los que una muestra escapa de la VM.
5. **Snapshots con nombre y propósito**: `base-limpia`, `herramientas-instaladas`,
   `pre-detonacion`. Revertir es la operación normal, no la excepción.
6. **Segmentación física o lógica adicional** si el host está en una red compartida: VLAN
   dedicada o, mejor, hardware separado. Un laboratorio de malware en el mismo dominio de
   difusión que el portátil de trabajo o los dispositivos domésticos no está aislado.

### Ejecutar binarios de reto y muestras: el riesgo es real

- Un binario de reto de CTF es **código arbitrario de un desconocido**. Que venga de una
  plataforma reputada reduce la probabilidad, no la elimina, y en un CTF con retos subidos por
  participantes tampoco reduce mucho.
- Una muestra de malware **hace exactamente lo que dice el nombre**: cifra, se propaga por la
  red que alcance, roba credenciales del navegador, persiste. Por eso se detona en VM
  desechable, en red interna, sin credenciales, con snapshot previo y con reversión posterior.
  No hay versión "rápida" de esto.
- **La VM no es una frontera de seguridad perfecta**: han existido y existirán fugas de
  hipervisor. Para muestras dirigidas o de origen desconocido, hardware dedicado y aislado
  físicamente, no una VM en el portátil de trabajo.
- **Nunca ejecutar nada de un reto en el host**, ni "solo para ver qué strings tiene". El
  análisis estático también se hace en la VM.
- Sube muestras a servicios públicos de análisis con criterio: **lo que subes se publica**
  para la industria. Una muestra de un incidente real puede contener datos del cliente y su
  subida avisa al atacante de que fue detectado. En CTF da igual; en trabajo real, no.

### Higiene del toolchain
- Las herramientas se instalan **en la VM del lab, jamás en el host**. El host mantiene solo
  el hipervisor.
- Herramientas de repositorios de terceros: se revisan como cualquier binario que ejecutas y
  se ejecutan dentro del lab. En 2026 el patrón de ataque dominante ha sido comprometer
  **tooling de seguridad y CI** (campaña TeamPCP, marzo 2026) — la comunidad de seguridad es
  objetivo prioritario, y un script "de un writeup" es un vector perfecto.
- **Nunca ejecutes a ciegas el comando de un writeup.** Léelo, entiéndelo, y ejecútalo en la
  VM. Ese hábito es además exactamente el que te exigirá un ejercicio autorizado.

## 4. Calidad del aprendizaje

> Esta sección sustituye a los gates de CI de la plantilla: aquí lo que hay que controlar es
> el aprendizaje y la integridad del laboratorio, no un build.

### Categorías y qué entrena cada una

| Categoría | Habilidad real que construye | Transferencia al trabajo |
|---|---|---|
| **Web** | Comprensión del protocolo, de la lógica de autorización y de la cadena de confianza cliente-servidor | **Alta**. Es la que más se parece al trabajo real |
| **Pwn / binary exploitation** | Modelo de memoria, ABI, mitigaciones y cómo se rompen | **Media**: rara vez la aplicarás, pero es lo que te hace entender de verdad qué protege un sistema |
| **Reversing** | Leer lo que hace un binario sin fuente; paciencia estructurada | **Alta** si vas a malware/IR; media si no |
| **Cripto** | Distinguir "usar cripto" de "usarla bien"; por qué el ECB, el nonce reutilizado y el rolling-your-own fallan | **Media-alta** conceptual, baja operativa. Ver `cryptography-pki-standards` |
| **Forense** | Metodología de evidencia, sistemas de ficheros, memoria, timelines | **Media**: los retos son puzles; el IR real es proceso, escala y presión |
| **OSINT** | Correlación de fuentes abiertas | **Alta** en reconocimiento, con un límite legal y ético que el CTF no enseña (§5) |
| **Hardware / ICS** | Protocolos y superficies físicas | Baja/nicha, alta si es tu sector |
| **Cloud** | Confusión de identidad, permisos y metadatos: donde ocurre el compromiso moderno | **Muy alta**. Infrarrepresentada en CTF respecto a su peso real |

### Formatos
- **Jeopardy**: retos independientes por categoría y puntos. El formato de entrada, y el 90 %
  de lo que jugarás.
- **Attack-Defence**: servicios idénticos que defiendes mientras atacas a los demás. Es el que
  más se parece a operar bajo presión, y el único que enseña que **parchear también puntúa**.
  Exigente de infraestructura, casi siempre presencial y con plazas limitadas.
- **King of the Hill**: objetivos compartidos que se toman y se mantienen. Enseña
  persistencia y expulsión del rival; poco frecuente para principiantes.

### Método (lo que separa jugar de aprender)
- **Cuaderno de notas propio, desde el primer día.** Comando, por qué lo lanzaste, qué
  esperabas, qué salió. El valor del CTF está en el registro, no en la flag: la flag se olvida
  en una semana.
- **Writeup propio de todo lo que resuelves**, aunque no lo publiques (y aunque no puedas
  publicarlo, §5). Escribir obliga a reconstruir el razonamiento y detecta dónde tuviste
  suerte en lugar de criterio. Es además el ensayo directo del entregable de un ejercicio real
  (`offensive-security-standards` §6).
- **Cuándo mirar la pista**: cuando llevas ~30-45 min sin ninguna hipótesis nueva que probar —
  no cuando la hipótesis actual falla. Atascarse sin hipótesis no enseña nada; probar y fallar
  con criterio sí.
- **Cómo usar un writeup ajeno**: lee solo el paso siguiente, vuelve al reto, y **rehaz el
  reto entero desde cero después**. Leer un walkthrough completo antes de intentarlo produce
  la ilusión de competencia, que es peor que no saber, porque no te avisa.
- **No quemarse**: el CTF castiga a base de fallo, y el burnout es el modo de fallo más común
  de esta disciplina. Sesiones acotadas, dificultad escalonada, y parar cuando deja de enseñar.
  Cadencia sostenida > maratones.
- **Medir progreso** por señales reales: reducción del tiempo hasta la primera hipótesis
  válida, retos resueltos sin pista, capacidad de explicar la solución a otro, y **rehacer un
  reto viejo sin notas**. El ranking y el número de flags no miden competencia.
- **Especializar después de barrer**: primero una pasada amplia por todas las categorías para
  saber qué existe; luego profundidad en una o dos. Al revés se construye un techo temprano.

### Integridad del laboratorio (los "gates" de aquí)
Antes de cada sesión de detonación, esta comprobación es obligatoria y no negociable:
1. Adaptador de red de todas las VMs implicadas en **red interna/host-only** — verificado, no
   supuesto.
2. Carpetas compartidas, portapapeles y arrastrar-y-soltar **desactivados**.
3. **Snapshot limpio tomado** y con nombre.
4. Sin credenciales, claves ni sesiones reales dentro de la VM.
5. Firewall del host activo.

Tras la sesión: **revertir al snapshot**, siempre. Y periódicamente: reconstruir la VM base
desde cero, porque los snapshots acumulados esconden estado que ya no controlas.

## 5. Ética y límites

- **No atacar la infraestructura de la plataforma**, solo sus objetivos. Las plataformas lo
  prohíben expresamente: HTB, por ejemplo, prohíbe la comunicación directa entre sistemas de
  miembros y el ataque a clientes de otros usuarios, y **prohíbe el DoS sobre cualquier
  máquina, dentro o fuera de su red**, exigiendo notificar de inmediato cualquier DoS
  accidental. Si encuentras un fallo en la plataforma, se reporta por su programa de
  divulgación, no se explota.
- **No compartir flags ni soluciones fuera de lo permitido.** Compartir la flag no ayuda a
  nadie a aprender y suele ser causa de expulsión. En HTB el reparto de soluciones está
  limitado al ámbito cerrado de tu equipo, y publicarlas fuera de su lista aprobada infringe
  los términos, con contenido "retirado" como criterio general para writeups. **TryHackMe es
  en la práctica más permisivo con walkthroughs públicos.** Verifica la política vigente de
  cada plataforma antes de publicar (§8): cambian y son ellas quienes mandan.
- **Reglas del evento por encima de la costumbre**: sin colaboración entre equipos si está
  prohibida, sin múltiples cuentas, sin atacar la scoreboard, sin flag-sharing. En
  attack-defence, sin destruir el servicio del rival más allá de lo que las reglas permitan.
- **Términos de servicio vigentes, no recordados.** Las AUP se actualizan: la de HTB vigente
  desde el **1 abr 2026** añadió, entre otras cosas, la prohibición de usar su contenido para
  entrenar, evaluar o comparar modelos de IA/LLM, la limitación del uso de sus recursos a fines
  formativos, y la prohibición de compartir o distribuir exploits y herramientas de ataque
  destinadas a dañar sistemas fuera de los entornos de entrenamiento designados.
- **El puente hacia el trabajo real**: nada de lo aprendido aquí se aplica contra un sistema
  que no sea tuyo sin autorización escrita. Ese es el dominio de
  `offensive-security-standards`, y su §1 es una precondición dura, no una recomendación. El
  CTF **no** te da permiso para nada fuera del CTF.
- **OSINT tiene límite legal y ético** que el CTF no enseña: el reto premia encontrar a la
  persona; la ley y la decencia limitan qué se recolecta sobre personas reales, y el RGPD
  aplica. Practicar OSINT sobre gente real sin encargo ni consentimiento no es entrenamiento,
  es vigilancia.
- **IA en CTF**: los sistemas autónomos ya resuelven jeopardy de nivel medio en minutos, con
  casos reportados en 2026 de agentes despachando conjuntos completos de retos y superando a
  la mayoría de equipos humanos en plataformas de iniciación. Consecuencias: (a) respeta la
  política del evento sobre uso de IA, que varía y a veces la prohíbe; (b) delegar la
  resolución destruye el propósito — el objetivo es que aprendas tú; (c) el valor diferencial
  humano se desplaza hacia lo que la IA hace peor: contexto, priorización y lógica de negocio.

## 6. Del CTF al trabajo real

Qué transfiere y qué no. Ignorar esto produce profesionales muy buenos resolviendo cosas que
no ocurren.

**Transfiere bien**: método de enumeración, tolerancia a la frustración, lectura de código y
protocolos ajenos, hábito de documentar, agilidad con el instrumental, y la intuición de
"esto huele raro".

**No transfiere**: el sesgo hacia lo exótico. Los CTF premian la cadena ingeniosa y el truco
raro porque tienen que ser divertidos y tener solución única. **El trabajo real es
mayoritariamente autorización rota, configuración por defecto, credenciales donde no deben
estar, parches que faltan y segmentación que no existe** — hallazgos aburridos con impacto
enorme. Un CTF sin flags de "IDOR en el endpoint de facturas" no significa que ese hallazgo no
sea el más común y el más rentable en un encargo real.

**Tampoco transfiere**:
- **Alcance y restricciones**: en un CTF todo vale; en un ejercicio real hay ventana, RoE,
  exclusiones y stop conditions.
- **No-daño**: en CTF puedes romper el reto; en producción, romper es el fracaso del ejercicio.
- **Comunicación**: el trabajo real es informe, severidad justificada, deconfliction y
  retest. La flag no se la entregas a nadie.
- **Escala y ruido**: en un CTF hay 5 servicios; en un cliente, 5000 activos y el problema es
  priorizar, no encontrar.
- **Defensa**: el CTF apenas enseña qué telemetría dejas. El purple team, sí.

**Certificaciones y su papel real**: son un filtro de contratación, no una medida de
competencia. **OSCP** sigue siendo el nombre que filtran los reclutadores; desde nov 2024
convive con **OSCP+**, con validez de tres años renovable, mientras que el OSCP "clásico" es
vitalicio. Su examen sigue con formato de ~24 h más informe, con Active Directory obligatorio,
**sin puntos extra**, lo que sube el listón efectivo. **CPTS** (HTB) es notablemente más barata
y su examen de 10 días se aproxima más a un encargo real, a costa de menos reconocimiento
formal. Señal de 2026 sobre el peso institucional de estos títulos: ISC2 recortó en abril de
2026 su lista de certificaciones que eximen experiencia para CISSP, sacando OSCP de ella.
Elige por el mercado al que apuntas y **verifica precio, formato y política de vigencia en la
fuente oficial** (§8): cambian con frecuencia y los agregadores no coinciden entre sí.

## 7. Sostenibilidad y prohibiciones

### Cadencia
- **Términos de servicio de cada plataforma**: releer antes de publicar cualquier writeup y al
  menos anualmente. Son documentos vivos (la AUP de HTB cambió en abril de 2026).
- **Reglas del evento**: leer completas antes de cada CTF. No se presumen por analogía con
  otro evento.
- **VM base**: reconstruir desde cero periódicamente, no encadenar snapshots indefinidamente.
- **Herramientas del lab**: actualizar dentro del lab y revisar procedencia; comprobar
  incidentes de cadena de suministro de lo que instalas (§8).
- **Aislamiento**: reverificar tras cualquier cambio de hipervisor, de red doméstica o de
  topología del lab. Una actualización del hipervisor puede reactivar carpetas compartidas.

### PROHIBIDO

**De esta skill como documento**:
- ❌ Incluir **payloads listos para usar**, exploits armados o soluciones de retos concretos.
- ❌ Documentar **bypasses concretos** de productos de seguridad o técnicas de evasión de
  detección para uso real.
- ❌ Listar **credenciales por defecto** de terceros.
- ❌ Convertir esto en recetario: método de laboratorio y de aprendizaje, no walkthrough.

**De la práctica**:
- ❌ Practicar contra **cualquier sistema que no sea tuyo, de una plataforma que lo autorice o
  de un CTF en curso**. Sin excepciones, sin "solo mirar", sin "es de una empresa que ya no
  existe".
- ❌ Ejecutar binarios de reto o muestras **en el host**, o en una VM con red puenteada, o con
  carpetas compartidas o portapapeles activos.
- ❌ Detonar sin **snapshot previo**, o seguir usando la VM tras la detonación sin revertir.
- ❌ Guardar credenciales, claves SSH, sesiones o datos personales reales dentro de las VMs
  del lab.
- ❌ Conectar el laboratorio a la LAN doméstica o corporativa, o compartir con ella dominio de
  difusión.
- ❌ Instalar el arsenal ofensivo en el equipo de trabajo o usar Kali como SO del host.
- ❌ **Atacar la infraestructura de la plataforma**, a otros usuarios, o lanzar DoS contra
  cualquier objetivo (prohibido expresamente por las plataformas, dentro y fuera de su red).
- ❌ Compartir flags, o publicar soluciones de contenido activo cuando los términos lo
  prohíben.
- ❌ Ejecutar comandos de un writeup **sin entenderlos**, y menos fuera del lab.
- ❌ Subir a servicios públicos de análisis muestras que puedan contener datos de un cliente
  real o alertar a un atacante activo.
- ❌ Usar OSINT sobre personas reales sin encargo, consentimiento o base legal.
- ❌ Aplicar en producción o en un cliente lo aprendido aquí sin la autorización escrita que
  exige `offensive-security-standards` §1.
- ❌ Confundir ranking, flags o certificación con competencia profesional.
- ❌ Fijar de memoria versiones, estado de plataformas o términos de servicio sin la
  verificación de §8.

## 8. Verificación web obligatoria

Antes de recomendar plataforma, herramienta o versión, o de publicar nada:

1. **Términos de servicio y AUP vigentes** de cada plataforma que vayas a usar, en su fuente
   oficial: qué está permitido atacar, qué se puede publicar y sobre qué contenido. Referencia
   a agosto 2026: la AUP de **HTB** vigente desde el **1 abr 2026**. **Pendiente de
   verificar**: el texto exacto de la **Acceptable Use Policy de TryHackMe** (sus cláusulas
   sobre infraestructura y writeups no se pudieron confirmar en fuente primaria; la lectura de
   "más permisivo con walkthroughs" procede de observación del ecosistema, no del documento).
2. **Estado y modelo actual de las plataformas**: que sigan existiendo y con qué modelo de
   acceso. Verificado a agosto 2026: **PortSwigger Web Security Academy** activa y gratuita.
   **Pendiente de verificar**: estado, modelo y términos actuales de **pwn.college**,
   **OverTheWire** y **OffSec Proving Grounds** — no se confirmaron en fuente primaria.
3. **Reglas del evento** concreto antes de cada CTF, incluida su política sobre uso de IA.
4. **Versiones actuales** de **Kali Linux**, **REMnux** y **FLARE-VM** en kali.org, remnux.org
   y el repositorio oficial de FLARE-VM. **Pendiente de verificar**: no se fijó ninguna versión
   concreta en este documento porque las fuentes localizadas eran secundarias y discrepantes.
5. **Procedencia e incidentes de cadena de suministro** de cualquier herramienta que instales
   — precedente 2026: la campaña **TeamPCP** (marzo 2026) comprometió tooling de seguridad y
   CI ampliamente desplegado. El tooling de seguridad es objetivo prioritario.
6. **Certificaciones**: precio, formato de examen, vigencia y política de renovación en la web
   oficial del emisor. Los datos de §6 (formato OSCP/OSCP+, coste relativo de CPTS, recorte de
   la lista de exenciones de CISSP en abril de 2026) proceden de fuentes secundarias
   coincidentes pero **no contrastadas contra la fuente oficial**: reconfírmalos antes de
   decidir una compra.
7. **Marco legal**: el encuadre penal de §1 es orientativo y puede haber cambiado; **no es
   asesoramiento jurídico**. Ante cualquier duda sobre la licitud de una práctica, consulta
   legal.
8. **Fugas de hipervisor**: antes de detonar algo serio, comprobar si hay vulnerabilidad de
   escape conocida y sin parchear en la versión de tu hipervisor. **Pendiente de verificar**:
   no se revisó el estado de CVEs de escape de hipervisor a agosto 2026.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
