---
name: edge-computing-standards
description: Computing on nodes you cannot walk up to — fleet operations for edge sites and devices under an intermittent link. Use when deciding whether a workload actually belongs at the edge (latency budget, upstream bandwidth cost, data residency, offline survival) or is just a distributed monolith, designing an A/B dual-partition image update with automatic rollback and a health check gate (rpm-ostree, bootc, greenboot, balenaOS), rolling an update across thousands of nodes in waves with a kill switch, running a lightweight Kubernetes at the edge (k3s, MicroShift, KubeEdge, Akri) or deciding that systemd plus Podman Quadlet units are enough, store-and-forward telemetry, metric downsampling and egress cost per node, eventual reconciliation and conflict resolution after a reconnect, giving each node its own identity instead of one shared fleet credential, UEFI Secure Boot and measured boot on an unattended node, LUKS full-disk encryption where the attacker physically holds the device, zero-touch onboarding and remote attestation, certificate rotation on a node that was offline when the cert expired, or serving inference on an edge box.
---

# Estándares de cómputo en el borde

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **operar cómputo en nodos a los que no puedes ir andando**: decidir si el borde es
necesario, la topología, la gestión de flota y la actualización segura, la operación
desconectada, la observabilidad con enlace intermitente, la seguridad de un nodo que está
físicamente en manos ajenas, y el aprovisionamiento sin intervención humana.

**Principio rector**: **el borde no se define por la distancia, sino por la restricción.** Un
sistema es de borde cuando lo obliga al menos una de estas cuatro cosas, y hay que poder decir
cuál:

1. **Latencia**: existe un presupuesto de milisegundos que el viaje al centro no cumple.
2. **Ancho de banda o coste de subida**: generar el dato es barato, transportarlo no.
3. **Soberanía o regulación**: el dato no puede salir de un país, de un edificio o de una red.
4. **Supervivencia sin conexión**: el sitio debe seguir funcionando con el enlace caído.

**Si no aplica ninguna de las cuatro, no es borde: es un monolito distribuido**, y se ha
comprado toda la dificultad de la gestión de flota sin ninguna de sus ventajas. Esa es la
primera pregunta de cualquier diseño y la que más veces se salta.

**Segunda tesis, que ordena §3.2 en adelante**: **el coste del borde no es el hardware, es la
flota.** Un nodo es fácil. Tres mil nodos con firmware distinto, enlaces malos, relojes
desviados, certificados a punto de caducar y ninguna consola son un problema de operación que
solo se resuelve con automatismos que se prueban antes de necesitarlos.

Triggers: "¿esto va en el borde o en el centro?", "presupuesto de latencia", "no podemos subir
todo ese vídeo", "tiene que funcionar sin línea", flota de dispositivos, actualización A/B,
partición dual, *rollback* automático, `rpm-ostree`, `bootc`, `greenboot`, Mender, RAUC,
SWUpdate, `.swu`, balenaOS, despliegue por oleadas, *kill switch*, k3s, MicroShift, KubeEdge,
Akri, "¿hace falta Kubernetes aquí?", *store-and-forward*, cola local de telemetría,
reconciliación tras reconexión, deriva de reloj, TPM, elemento seguro, Secure Boot, arranque
medido, LUKS, "la misma clave en todos los dispositivos", aprovisionamiento cero-toque,
atestación remota, "el certificado caducó mientras estaba apagado", inferencia en el borde.

**No aplica**: ver `embedded-iot-standards` (**el microcontrolador y el
firmware bare-metal o RTOS** — si no hay un sistema operativo de propósito general con gestor
de paquetes y contenedores, es suyo; aquí desde el SBC/gateway con Linux hacia arriba.
**Corte de la imagen A/B, que las dos podrían reclamar**: el mecanismo se elige por lo que hay
debajo, no por dónde está la caja — **imagen de firmware** (MCUboot, RAUC, SWUpdate, Mender,
hawkBit, ranuras con contador de rollback) es suya; **imagen de SO completo** (rpm-ostree, bootc,
greenboot, balenaOS) es de aquí. Lo que **no** cambia de lado: la **campaña** —olas, *kill
switch*, porcentaje y criterio de parada sobre miles de nodos— es de aquí sea cual sea el
mecanismo, porque es un problema de flota, no de placa),
`ot-ics-security-standards` (**la planta industrial**: PLC, SCADA, protocolos de campo,
modelo Purdue, seguridad funcional — un nodo de borde en una fábrica cae bajo **sus**
restricciones, y ellas mandan sobre las de aquí),
`kubernetes-standards` (**el clúster central y todo Kubernetes como plataforma**: manifiestos,
Helm, GitOps, políticas de admisión, CNI, operadores — aquí solo el criterio de **si** poner
Kubernetes en el borde y qué distribución), `podman-systemd-containers-standards` (**la
alternativa real a Kubernetes en el borde**: unidades Quadlet, contenedores bajo systemd,
`podman auto-update` — el mecanismo es suyo, aquí la decisión de usarlo),
`os-provisioning-standards` (**instalar el SO**: Kickstart, imagen, `bootc install`, PXE — aquí
el matiz de que en el borde no hay nadie delante y la instalación llega por USB o por
aprovisionamiento cero-toque), `rhel-fedora-standards` (**`rpm-ostree`, `bootc` e *image mode*
como ecosistema Red Hat**; aquí como patrón de actualización A/B),
`iac-standards` (Ansible/Terraform y el código que configura; **ojo: el modelo *push* de
Ansible no funciona contra un nodo que está apagado o tras NAT — ver §3.2**),
`local-inference-standards` (**el modelo y su motor**: cuantización, memoria, endpoint — aquí
solo cómo llega y se actualiza en la flota), `gpu-computing-standards` (el acelerador),
`observability-standards` (**OTel, Prometheus, alertas y su diseño**; aquí el matiz del enlace
intermitente y del coste por byte), `networking-standards`, `vpn-standards` (**el túnel de
vuelta a casa**: WireGuard, mallas), `dns-standards`, `firewall-policy-standards`,
`load-balancing-standards`, `caching-cdn-standards` (**el borde del CDN y sus funciones**: si
el problema es servir contenido HTTP más cerca del lector, es suyo, no de aquí),
`gaming-infrastructure-standards` (**servidores de partida cerca del jugador**: la plataforma
de borde genérica es de aquí; la orquestación de sesiones, el matchmaking y la flota de juego
son suyos),
`identity-access-management-standards` (el IdP humano; aquí la identidad **de máquina**),
`cryptography-pki-standards` (**PKI, ACME, custodia y rotación de claves**: la mecánica es
suya, aquí el problema de rotar contra un nodo desconectado),
`secrets-management-standards` (dónde vive el secreto), `endpoint-security-standards` (el
puesto de trabajo gestionado), `macos-fleet-standards` (flota de Apple con MDM),
`linux-hardening-standards` y `selinux-standards` (baseline del SO),
`container-runtime-security-standards` (seccomp, escape, `--privileged`),
`cmdb-inventory-standards` (**el inventario de la flota** como registro),
`bcdr-standards` (RTO/RPO y continuidad), `backup-recovery-standards` (**¿se respalda un nodo
de borde? Casi nunca: se reconstruye — ver §3.5**), `datacenter-facilities-standards` (la
planta central), `finops-standards` (coste), `homelab-standards` (proporcionalidad),
`privacy-engineering-standards` (dato personal capturado en el borde: minimización en origen),
`grc-compliance-standards`, `wireless-standards` (el enlace radio de acceso),
`mobile-standards` (la app del teléfono).

## 2. Decisiones por defecto

> Verificar por web versión, estado del proyecto y **licencia leída en crudo** antes de fijar
> nada (§8).

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| ¿Borde o centro? | **Centro**, salvo que se nombre una de las cuatro restricciones de §1 | El borde multiplica por N el coste de operación de cada decisión. Se paga solo si hay motivo escrito |
| Orquestación en el nodo | **systemd + contenedores (Podman/Quadlet)** | Ver §2.1. Kubernetes en el borde solo cuando su modelo aporta algo que systemd no da |
| Kubernetes ligero, si hace falta | **k3s** | **Apache-2.0** (leído en crudo), proyecto **CNCF en nivel Sandbox** desde 2020, distribución certificada, binario único. Alternativas: **MicroShift** si el sitio ya es Red Hat y se paga la suscripción; **KubeEdge** (**graduado en la CNCF**) si de verdad se necesita su modelo de nube-borde con dispositivos |
| Modelo de actualización | **Imagen completa A/B con *rollback* automático** | Ver §3.2. Actualizar por paquetes en un nodo inalcanzable es cómo se pierde una flota |
| Sistema base | **Sistema de ficheros raíz inmutable y transaccional** (`bootc`/`rpm-ostree`, o imagen A/B con RAUC/SWUpdate/Mender) | El nodo que se puede modificar en caliente diverge, y la divergencia en una flota es indiagnosticable |
| Gate de la actualización | **Comprobación de salud automática que decide confirmar o revertir** (`greenboot` o equivalente propio) | Ver §3.2: sin *health check*, el A/B no es *rollback* automático, es solo dos particiones |
| Identidad del nodo | **Una identidad criptográfica por dispositivo**, anclada en TPM o elemento seguro | Ver §3.6. La credencial compartida es **el** fallo de diseño del dominio |
| Cifrado en reposo | **Sí, con clave sellada al estado de arranque (TPM)** | El atacante tiene el aparato en la mano; el disco sale con un destornillador |
| Telemetría | **Agregada y *store-and-forward* con cola local acotada** | Ver §3.4. Enviar todo en crudo es caro y se pierde igual cuando cae el enlace |
| Conectividad de vuelta | **El nodo inicia la conexión saliente**; nunca puerto entrante expuesto | El nodo está tras NAT, tras CGNAT o tras un firewall ajeno. Además, no expone superficie |
| Aprovisionamiento | **Cero-toque con atestación**: el dispositivo se identifica y recibe su configuración | Nadie con formación técnica va a estar delante |

### 2.1 Kubernetes en el borde: cuándo es sobreingeniería

**Un nodo de borde con cuatro contenedores no necesita un plano de control.** Kubernetes
resuelve **planificación entre nodos**, y en un sitio de borde de un solo nodo no hay nada que
planificar. Lo que aporta —planificador, controladores, API declarativa— cuesta memoria, CPU,
un plano de control que también hay que actualizar y un modo de fallo nuevo (un `etcd`
corrupto en un sitio sin manos es un desplazamiento).

- **systemd + contenedores basta** cuando: un nodo por sitio, conjunto fijo de servicios,
  arranque ordenado con dependencias, reinicio ante fallo, y actualización por imagen del
  sistema completo. `systemd` ya da dependencias, reintentos, *watchdog*, sockets y
  temporizadores; Quadlet le añade contenedores declarativos. **Es menos software que
  mantener, y en el borde eso es la métrica que manda.**
- **Kubernetes en el borde se justifica** cuando: hay varios nodos por sitio con
  reprogramación real entre ellos, el equipo ya opera Kubernetes y el coste marginal de
  aprender otra cosa supera el de meterlo, o se necesita el mismo modelo declarativo
  extremo a extremo con GitOps hasta el borde.
- **Comprobación honesta**: si la respuesta a *"¿qué haría el planificador aquí?"* es *"nada,
  solo hay un nodo"*, la respuesta es systemd.
- **Estado de los proyectos, verificado** (re-verificar, §8): **k3s** Apache-2.0, CNCF Sandbox,
  releases alineadas con las versiones de Kubernetes (v1.36 observada en 2026). **MicroShift**
  Apache-2.0 en el repositorio, pero **la build de Red Hat se consume por suscripción** (Red
  Hat Device Edge / OpenShift) y está **acoplada por matriz de versiones a la de RHEL** — eso
  es una restricción de arquitectura, no un detalle comercial. **KubeEdge** graduado en la
  CNCF. **Akri** (exponer dispositivos de campo —cámaras IP, USB— como recursos de Kubernetes)
  sigue en **CNCF Sandbox** y con actividad reciente, pero es un proyecto pequeño: se evalúa
  su ritmo de mantenimiento antes de depender de él.

## 3. Estructura y convenciones

### 3.1 Topología: cuatro niveles y quién decide qué

- **Dispositivo**: sensor, cámara, PLC, SBC. Recursos mínimos, a veces sin SO general.
- **Borde lejano** (*far edge*): el nodo en la tienda, la subestación, el camión, el quirófano.
  Uno o pocos equipos, enlace propiedad de otro, cero personal técnico. **Es el nivel que
  define este documento.**
- **Borde cercano** (*near edge*): un armario o mini-sala regional con varios nodos, enlace
  decente y quizá acceso físico programable.
- **Región / centro**: donde está el plano de control, el histórico y el modelo entrenado.

**Reglas de reparto que evitan la mayoría de los errores**:

- **El plano de control vive en el centro; el plano de datos, en el borde.** El borde ejecuta;
  no decide políticas globales.
- **Cada nivel debe funcionar si el de arriba desaparece**, con degradación declarada. Si el
  borde deja de funcionar sin el centro, no era una arquitectura de borde.
- **El dato se reduce lo antes posible.** Filtrar, agregar y descartar en el nodo es la palanca
  de coste, de privacidad y de ancho de banda a la vez. Subir el crudo "por si acaso" es la
  decisión más cara que se toma en este dominio.

### 3.2 Actualización: A/B, salud y oleadas

**El requisito de diseño es este: una actualización mala no puede exigir que alguien conduzca
hasta el nodo.** De ahí sale todo lo demás.

Patrón obligatorio:

1. **Dos ranuras (A/B)** o raíz transaccional: se escribe la imagen nueva en la ranura inactiva
   mientras la activa sigue sirviendo. Reinicio al slot nuevo.
2. **Comprobación de salud tras el arranque**, con criterios propios del servicio (¿arrancan
   los servicios? ¿hay red? ¿responde el plano de control? ¿el disco está sano?).
3. **Confirmación o reversión automática**: si la comprobación no pasa dentro de un plazo, el
   gestor de arranque vuelve solo a la ranura anterior. **Sin este paso, A/B no es *rollback*
   automático: son dos particiones y una llamada de teléfono.**
4. **La imagen va firmada y verificada** antes de escribirse. Un canal de actualización sin
   verificación de firma es ejecución remota de código con entrega a domicilio.
5. **Actualización atómica y resistente a corte de corriente**: se corta la luz a mitad de la
   escritura y el nodo tiene que arrancar. Es el caso de prueba, no un imprevisto.

Herramientas, con licencia **leída en crudo** (§8): **bootc** y **rpm-ostree** (Apache-2.0,
modelo de imagen de arranque en contenedor, con `greenboot` como *gate* de salud en la familia
Red Hat), **RAUC** (**LGPL-2.1**, bundles y ranuras, muy usado con Yocto), **SWUpdate**
(**GPL-2.0-only**, con una biblioteca de control LGPL-2.1 y extensiones Lua bajo MIT; formato
`.swu`), **Mender** (cliente y servidor **Apache-2.0** en sus repositorios, con oferta
comercial encima — verificar qué edición se está desplegando), **balenaOS/balena** (SO abierto
con **plataforma balenaCloud comercial**: lo que ata no es la licencia del SO, es el servicio).

Despliegue en flota:

- **Por oleadas, siempre.** Un anillo de canarios (decenas de nodos representativos, no los
  mejores), luego un porcentaje, luego el resto. Entre anillos, **tiempo de observación
  suficiente para que aparezcan los fallos lentos**: fugas de memoria, disco que se llena,
  certificados, reinicio semanal.
- **Interruptor de parada (*kill switch*)** que detiene el despliegue en curso. Y se prueba.
- **La cohorte se define por lo que diferencia a los nodos**: modelo de hardware, versión de
  origen, país, tipo de enlace. Una flota "homogénea" nunca lo es.
- **Ventana de actualización por sitio**: un nodo en un quirófano o en una caja registradora no
  se reinicia a cualquier hora.
- **Nodos que llevan meses apagados**: el sistema debe soportar el salto de varias versiones de
  una vez, o declarar y hacer cumplir una versión mínima con un camino de recuperación. Este
  caso siempre ocurre y casi nunca se prueba.
- **El *push* no vale.** Un modelo tipo Ansible contra nodos apagados, tras NAT o con IP
  cambiante no llega. **El nodo consulta y tira de su estado deseado**; el centro publica.

### 3.3 Operación desconectada y reconciliación

- **Se declara explícitamente qué funciona sin enlace y qué no.** Sin ese documento, el
  comportamiento en corte es el que salga, y saldrá en producción.
- **Autonomía acotada**: cuánto tiempo puede el nodo operar solo (días, semanas), y qué pasa al
  agotarse (¿degrada?, ¿para?, ¿sigue con datos viejos?). Un caché de autorización que caduca a
  la hora convierte un corte de red en una parada de servicio.
- **Reconciliación al volver**: hay que decidir **la regla de resolución de conflictos** —
  último en escribir gana, el centro gana, unión, o resolución manual con cola de excepciones.
  "Ya se sincronizará" no es una regla.
- **Idempotencia y reintentos**: todo lo que el nodo envíe se reintentará; sin claves de
  idempotencia se duplican transacciones al reconectar.
- **El reloj miente.** Sin NTP durante días el nodo deriva; los eventos llegan con marcas
  imposibles, los certificados parecen caducados y las firmas fallan. Se usan relojes
  monótonos para medir intervalos, se marca el evento con la hora local **y** con la de
  recepción, y se ordena por secuencia además de por tiempo.
- **Certificados**: el caso que rompe flotas es el nodo que estaba desconectado cuando tocaba
  rotar. Se diseñan vidas largas para la identidad ancla, rotación temprana y muy anticipada
  para las de servicio, y **un camino de recuperación que no dependa del certificado
  caducado**. Comprobar la caducidad de la CA raíz antes de desplegar, no después.

### 3.4 Observabilidad con enlace intermitente y coste por byte

- **Agente con cola local persistente y acotada** (*store-and-forward*): guarda mientras no hay
  enlace y envía al volver. **Acotada** es la palabra clave: una cola sin límite llena el disco
  y tira el nodo — exactamente en el peor momento. Al llegar al límite se descarta por política
  declarada (lo viejo primero, o lo de menor prioridad).
- **Agregar en el nodo**: percentiles y contadores por intervalo, no eventos crudos. El coste
  de telemetría por nodo se multiplica por el tamaño de la flota; a 5.000 nodos, unos pocos KB
  por segundo de más son una factura.
- **Muestreo y niveles**: log normal muy reducido, con **capacidad de subir el detalle bajo
  demanda para un nodo concreto** durante una investigación. Esa palanca es lo que sustituye a
  la consola que no tienes.
- **Alertar sobre la flota, no sobre el nodo.** Cinco mil nodos generan fallos individuales
  constantemente; la alerta útil es "el 4 % de la cohorte X no reporta desde el despliegue de
  ayer". Un nodo caído es un ticket, no una página.
- **El silencio es una señal, y hay que distinguirla**: nodo apagado, enlace caído, agente
  muerto y nodo robado se parecen desde el centro. Un latido con causa de última desconexión
  cuando vuelve resuelve la mayoría.
- **Detección de "ladrillo" (*bricked*)**: métrica explícita de nodos que no vuelven tras una
  actualización, con umbral que dispara el *kill switch* de §3.2.

### 3.5 Nodo desechable

- **El nodo no se respalda: se reconstruye.** Su estado se divide en tres: **imagen** (viene
  del registro), **configuración** (viene del plano de control), **dato local** (lo único
  irreemplazable, y por eso se sincroniza al centro o se acepta explícitamente su pérdida).
- **Sustituir un nodo debe ser un procedimiento de campo que ejecute alguien sin formación**:
  desconectar, conectar el nuevo, encender. Todo lo demás lo hace el aprovisionamiento
  cero-toque (§3.6). Si sustituirlo exige un ingeniero, la flota no escala.
- **Retirada**: un nodo dado de baja se revoca (identidad y credenciales) **y** se borra o
  destruye su almacenamiento. Un aparato retirado que sigue en la lista de confianza es una
  puerta abierta con las llaves puestas.

### 3.6 Seguridad: el atacante tiene el dispositivo en la mano

Este es el cambio de modelo de amenazas que separa el borde del centro. No hay guardia, no hay
puerta, no hay CCTV. Hay que asumir **acceso físico completo, con tiempo y herramientas**.

- **Una identidad criptográfica por dispositivo, no compartida.** **La credencial única para
  toda la flota es el fallo de diseño clásico del dominio**: comprometer un solo aparato —
  comprado de segunda mano, robado, o simplemente abierto— entrega la flota entera, y **no hay
  revocación posible sin tocar todos los nodos**. Identidad por dispositivo significa que
  comprometer uno cuesta uno, y que revocarlo es una operación normal.
- **Ancla de confianza en hardware**: TPM 2.0 o elemento seguro. La clave privada se genera
  dentro y no sale nunca. Una clave privada en un fichero del disco es una clave pública con
  pasos extra.
- **Arranque seguro y medido**: UEFI Secure Boot con las claves del propietario (no solo las
  del fabricante) para que solo arranque software firmado, y arranque medido en PCR del TPM
  para que el estado de arranque sea comprobable.
- **Cifrado en reposo con la clave sellada al estado de arranque**: LUKS con la clave liberada
  por el TPM solo si las medidas coinciden. Así el disco extraído no se lee y el arranque
  manipulado no abre el volumen. **Sin sellado, el cifrado en un nodo desatendido protege poco:
  la clave está en el mismo aparato.**
- **Atestación remota**: antes de entregar credenciales o configuración, el centro comprueba
  que el nodo es quien dice y está en el estado esperado. Es lo que convierte el
  aprovisionamiento cero-toque en algo distinto de "regalar credenciales a quien las pida".
- **Credenciales efímeras y de mínimo privilegio**: el nodo obtiene tokens de vida corta para
  lo que necesita. Nunca una credencial de escritura amplia contra el sistema central; el nodo
  **empuja su telemetría** y **tira de su configuración**, y ninguna de las dos permisos
  requiere permisos sobre otros nodos.
- **Superficie mínima**: sin servicios de escucha innecesarios, sin acceso remoto permanente
  habilitado por defecto, consola serie y depuración (JTAG/UART) deshabilitadas o protegidas en
  producción.
- **Detección de manipulación**: sensores de apertura, sellos, y **la alerta correspondiente**.
  Y la regla operativa incómoda: **un nodo del que se sospecha manipulación se revoca primero y
  se investiga después.**
- **El canal de actualización es el activo más valioso de la flota.** Quien lo controla ejecuta
  código en todos los nodos. Firma de imágenes con claves custodiadas, verificación en el
  dispositivo, y el proceso de firma tratado como un sistema crítico
  (`cryptography-pki-standards`, `secrets-management-standards`).

### 3.7 Inferencia en el borde

- **Es un caso concreto de las cuatro restricciones de §1**, y casi siempre de dos: latencia
  (no se puede esperar al centro) y ancho de banda (el vídeo no cabe en la subida).
- **El modelo es un artefacto de la flota**, no un fichero suelto: se versiona, se firma, se
  distribuye por el mismo canal que el resto, y **se puede revertir igual que el software**.
  Un cambio de modelo es un despliegue con anillos, no una copia por SSH.
- **Se decide qué sube**: predicción sí, dato crudo casi nunca. Ahí está a la vez el ahorro y
  la minimización que exige `privacy-engineering-standards`.
- **La deriva del modelo en el borde es más difícil de ver** que en el centro, porque las
  etiquetas rara vez vuelven. La monitorización y el reentrenamiento son de
  `mlops-standards`; aquí solo el mecanismo de distribución y reversión.
- El motor, la cuantización y el dimensionado de memoria son de `local-inference-standards`.

## 7. Sostenibilidad a largo plazo y prohibiciones

> §4 (calidad y testing) y §6 (rendimiento y operabilidad) se omiten deliberadamente: en este
> dominio el testing es el de la skill del lenguaje y la operabilidad está repartida entre §2 y
> §3, donde se decide de verdad. Se conserva la numeración canónica del catálogo para que las
> referencias cruzadas a §7 y §8 apunten a lo que dicen.

**El horizonte es largo y ese es el problema.** Un nodo de borde vive años en sitios a los que
nadie vuelve. Consecuencias que se deciden **antes** de comprar:

- **Fin de vida del hardware y del SO fechados desde el día uno**, y una versión mínima
  soportada que se hace cumplir. Una flota con seis generaciones de todo es indesplegable.
- **La caducidad de los certificados y de la CA raíz se planifica a la escala de vida del
  aparato**, no del proyecto.
- **Cadencia de actualización de seguridad definida y demostrada**: si no se puede parchear un
  CVE crítico en toda la flota en un plazo declarado, ese plazo es el riesgo real, no el que
  diga la política.
- **Salida del proveedor**: si la gestión de la flota depende de una nube ajena (balenaCloud,
  suscripción, o un servicio propietario), se documenta **cómo se recupera el control de los
  dispositivos** si desaparece. Sin esa respuesta, la flota es rehén.

Prohibiciones:

- ❌ **Una credencial, clave o certificado compartido por toda la flota.**
- ❌ **Actualizar por gestor de paquetes en caliente** un nodo inalcanzable, sin ranura
  alternativa ni reversión.
- ❌ **A/B sin comprobación de salud automática que revierta.** Es la mitad del mecanismo.
- ❌ **Desplegar a toda la flota a la vez.** Anillos o nada.
- ❌ **Canal de actualización sin firma verificada en el dispositivo.**
- ❌ **Puerto entrante expuesto en el nodo**, o acceso remoto permanente habilitado por defecto.
- ❌ **Cola de telemetría sin límite de tamaño.** Llena el disco y tira el nodo.
- ❌ **Subir el dato crudo por defecto** sin haber calculado el coste de subida ni la
  minimización.
- ❌ **Asumir que el reloj del nodo es correcto**, o ordenar eventos solo por su marca de tiempo.
- ❌ **Cifrado en reposo con la clave en el propio disco** en un equipo desatendido.
- ❌ **Poner Kubernetes en un sitio de un solo nodo** sin poder decir qué planifica.
- ❌ **Dar de baja un nodo sin revocar su identidad** y sin borrar o destruir su almacenamiento.
- ❌ **Llamar "edge" a un despliegue que no cumple ninguna de las cuatro restricciones de §1.**
- ❌ **Afirmar la licencia o el estado de madurez de k3s, MicroShift, KubeEdge, Akri, Mender,
  RAUC, SWUpdate o balenaOS de memoria.** Varios cambian de modelo comercial (§8).

*(Se omiten deliberadamente las secciones separadas de "calidad y testing" y de "rendimiento":
en este dominio la prueba **es** el despliegue por anillos con reversión automática (§3.2) y la
capacidad se mide como coste de telemetría y autonomía sin enlace (§3.3–3.4). Separarlas
duplicaría el contenido sin añadir criterio.)*

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento:

1. **Licencias leídas en crudo — resultado de esta verificación (agosto de 2026)**:
   - **k3s**: `LICENSE` en `master` → **Apache-2.0**.
   - **MicroShift**: `LICENSE` en `main` → **Apache-2.0** en el repositorio; **la build
     soportada de Red Hat requiere suscripción** y está acoplada por matriz de versiones a
     RHEL. Distinguir repositorio de producto.
   - **Akri**: `LICENSE` en `main` → **Apache-2.0**.
   - **bootc**: `LICENSE-APACHE` presente → **Apache-2.0** (verificar si es dual con MIT).
   - **RAUC**: `COPYING` → **LGPL-2.1**.
   - **SWUpdate**: `COPYING` → **GPL-2.0**; el propio README precisa: *"SWUpdate is released
     under GPLv2. A library to control SWUpdate is part of the project and it is released under
     LGPLv2.1"*, con extensiones Lua bajo MIT.
   - **Mender**: `LICENSE` de `mender` y de `mender-server` → **Apache-2.0** (Northern.tech AS);
     existe oferta comercial superpuesta — **verificar la edición concreta**.
   - **balenaOS**: **hueco declarado.** El `LICENSE` de un repositorio de placa
     (`balena-raspberrypi`) es Apache-2.0, pero **no se ha localizado el fichero de licencia de
     `meta-balena`** en las rutas probadas (`master` y `main` devuelven 404). Léelo antes de
     afirmar la licencia del SO, y ten en cuenta que **el atadero real es balenaCloud, que es
     un servicio comercial**, no la licencia.
   - **KubeEdge**: **hueco declarado** — no se ha leído su fichero de licencia en esta pasada.
2. **Estado y madurez**: verificado que **k3s** está en **CNCF Sandbox** (aceptado en 2020, con
   los mantenedores manifestando intención de promocionarlo), **KubeEdge** está **graduado** en
   la CNCF, y **Akri** sigue en **Sandbox** desde 2021 con actividad reciente (*commits* y
   *release* en julio–agosto de 2026). Re-verificar en `cncf.io` y en el *landscape*: los
   niveles cambian y la prensa no siempre lo cubre.
3. **Versiones**: k3s sigue las versiones de Kubernetes (v1.36.x observada); comprobar qué
   versión de Kubernetes soporta y hasta cuándo. bootc, RAUC, Mender y SWUpdate se verifican
   por feed Atom de *releases* del repositorio. **`api.github.com` sin autenticar devuelve 403;
   usar los feeds Atom.**
4. **Matriz de compatibilidad de MicroShift con RHEL**: cambia por versión y es una restricción
   de arquitectura. Consultar la documentación de Red Hat antes de comprometer una versión.
5. **Hardware y arranque seguro**: la disponibilidad de TPM 2.0, de Secure Boot con claves
   propias y de sellado de LUKS **depende de la placa concreta**. Se verifica contra el modelo
   real antes de diseñar sobre ello; en muchos SBC no está o no es utilizable.
6. **CVE del canal de actualización y del plano de control ligero**: triaje con CVSS + EPSS +
   **KEV**. Un CVE en el agente de actualización es el peor caso posible de esta arquitectura.
7. **Cifras**: **ningún número de mercado de "edge computing", de latencia típica o de ahorro
   de ancho de banda se escribe sin fuente y metodología.** El presupuesto de latencia y el
   coste de subida se calculan con los datos del proyecto, no con una estadística de sector.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
