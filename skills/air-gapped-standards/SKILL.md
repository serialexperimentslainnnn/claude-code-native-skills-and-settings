---
name: air-gapped-standards
description: Operating systems with no Internet path — what a real air gap is, how software gets in and what breaks when nothing can phone home. Use when designing or auditing an isolated, disconnected or "offline" environment, a unidirectional gateway or data diode, a sneakernet transfer process with one-time media and chain of custody, an internal mirror of dnf/apt/pip/npm/crates/maven or a container registry (Pulp with pulp export / pulp import and its toc.json, Foreman/Katello, Harbor proxy cache and replication, Sonatype Nexus Repository Community Edition and its usage limits, JFrog Artifactory, reposync, createrepo_c, apt-mirror, devpi, verdaccio), moving images with skopeo copy --dir, docker save, oras pull or a local registry:2 for cephadm/Rook/Kubernetes bootstrap, verifying signatures on the isolated side (rpm --import, gpgcheck, apt Signed-By, cosign verify --key/--trusted-root/--insecure-ignore-tlog, cosign save and --local-image), running a vulnerability scanner without feed access (trivy self-hosted DB, --offline-scan, --skip-version-check, --disable-telemetry, grype db import), patching and CVE triage with no NVD access, GNSS/GPS stratum-1 time and chrony when NTP has no upstream (Kerberos clockskew, expired TLS certificates), an offline root CA with internal CRL distribution and nextUpdate expiry, software licences that require activation or a license server reachable over the Internet, backups and DR inside the isolated enclave, telemetry and observability that cannot leave, or deciding whether the air gap is the right control at all or expensive theatre that makes patching impossible.
---

# Estándares de entornos aislados (air-gapped)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: **el air gap no es un control de seguridad, es una restricción de red que
> desplaza el riesgo.** Lo que elimina —el acceso remoto directo— lo cambia por otros dos que casi
> nadie presupuesta: **un canal de entrada humano y físico** (que es el vector documentado) y
> **la incapacidad estructural de parchear a tiempo**. Un entorno aislado mal operado es menos
> seguro que uno conectado y bien parcheado. La decisión no es "aislar o no", es **si puedes
> pagar el coste operativo de estar aislado**.

## 1. Alcance y triggers

Aplica al **diseño y la operación de un entorno sin ruta a Internet**: qué modelo de aislamiento
se elige y qué garantiza, cómo entra el software y cómo se verifica **dentro**, la transferencia
física y su gobierno, el parcheo y el triaje de vulnerabilidades sin feeds, el tiempo, la PKI
interna, las licencias que llaman a casa, la copia y la recuperación dentro del recinto, la
observabilidad que no puede salir, y el criterio de cuándo el aislamiento es la respuesta correcta.

Disparadores: "air gap", "air-gapped", "entorno aislado", "sin salida a Internet", "red separada",
"offline", "sneakernet", "diodo de datos", "gateway unidireccional", `pulp export`/`pulp import`,
`toc.json`, `reposync`, `createrepo_c`, `apt-mirror`, `debmirror`, `devpi`, `verdaccio`,
`skopeo copy --dir`, `docker save`/`load`, `oras pull`, `registry:2` local, `cosign save`,
`cosign verify --trusted-root`/`--insecure-ignore-tlog`/`--local-image`, `rpm --import`,
`gpgcheck=1`, `Signed-By`, `trivy --offline-scan`/`--skip-version-check`, `grype db import`,
`chronyc sources` sin upstream, GNSS/GPS estrato 1, `clockskew`, CRL `nextUpdate`, servidor de
licencias, "activación", "no puede llamar a casa".

**No aplica**: ver `ot-ics-security-standards` (**la frontera hermana y la más probable**: el
aislamiento **industrial** —modelo Purdue, DMZ de nivel 3.5, zonas y conductos de IEC 62443-3-2,
diodo entre planta y corporativo, EWS, ficheros de proyecto de PLC, activos de 20 años que no se
parchean por seguridad física— es **suyo**. Aquí, el aislamiento **como modo de operación
general**, aplicable también a un enclave de I+D, una bóveda de backup, una CA raíz offline, un
laboratorio de malware o un entorno regulado no industrial. Regla de arbitraje: **si al otro lado
del diodo hay un proceso físico que puede matar a alguien, manda `ot-ics`; si al otro lado hay
datos y servidores, manda esta skill**. Y el orden de prioridades cambia con ella: allí *safety*
por encima de todo; aquí la confidencialidad suele ser lo que motivó el aislamiento),
`ctf-lab-standards` (laboratorio de seguridad desechable y detonación de muestras: **el
aislamiento allí protege al mundo del laboratorio; aquí protege al recinto del mundo** — son dos
direcciones de amenaza distintas y dos diseños distintos), `firewall-policy-standards` (la regla
como artefacto y su ciclo de vida; **aquí se decide si existe camino, allí se escribe la regla**.
Corolario de §2.1: un entorno con reglas de firewall **no está aislado**, está segmentado),
`networking-standards` y `routing-switching-standards` (VLAN, VRF, direccionamiento y switching
del recinto), `vulnerability-management-standards` (**triaje, CVSS/EPSS/KEV, VEX y SLA de
remediación son suyos**; aquí **por qué el calendario cambia** y cómo llegan los datos sin
conexión), `backup-recovery-standards` (mecánica de la copia y restore probado; aquí la
restricción de que el repositorio y sus claves no pueden estar fuera del recinto),
`bcdr-standards` (RTO/RPO y ejercicios: **un plan de DR que asume descargar algo de Internet no
es un plan en este entorno**), `secrets-management-standards` (gestor de secretos, rotación;
aquí que **no puede depender de un KMS de nube**), `cryptography-pki-standards` (algoritmos,
custodia y la **CA raíz offline como práctica** — la raíz offline es un air gap y su dueña es
aquella skill; aquí la PKI *del recinto* y la disponibilidad de sus CRL),
`identity-access-management-standards` (IdP, MFA y federación: **la federación con un IdP de
nube es exactamente el camino de datos que el aislamiento niega**),
`opensource-licensing-standards` (obligaciones de licencia del software espejado; aquí solo el
estado de licencia verificado de las herramientas de §2.3),
`cicd-standards` (pipeline y sus gates; aquí el pipeline **partido en dos** por el corte),
`iac-standards` (Terraform/Ansible y sus proveedores y colecciones, que también hay que espejar),
`kubernetes-standards` (registro, admisión y firma verificada en el clúster),
`ceph-standards` (**Ola 7, hermana**: `cephadm` documenta explícitamente el despliegue en entorno
aislado contra un registro de contenedores local; el registro es de aquí, el cluster es suyo),
`observability-standards` (stack de telemetría; aquí que **no puede exportar**),
`grc-compliance-standards` (marco normativo, evidencia y la eventual acreditación del recinto),
`incident-response-forensics-standards` (respuesta y forense dentro del recinto, incluida la
extracción de evidencia a través del mismo canal físico que todo lo demás),
`detection-engineering-standards` (reglas y su actualización sin feed).

## 2. Decisiones por defecto

> Verificar por web antes de fijar nada en un proyecto real (§8). Licencias y límites de uso de
> las herramientas de espejado cambian, y son la clase de dato que más se escribe de memoria.

### 2.1 Qué es un air gap de verdad

**Definición operativa, no comercial**: un entorno está aislado si **no existe ningún camino de
datos** entre él y una red no confiable. Un camino de datos es cualquier cosa que mueva bytes,
tenga o no dirección IP.

| Lo que se llama air gap | Lo que es | Qué asumir |
|---|---|---|
| VLAN separada con firewall y reglas de salida | **Red segmentada** | Hay camino. Si hay una regla, hay un flujo, y una regla mal puesta lo abre |
| Red separada + jump host / bastión | **Red segmentada con un cuello** | Hay camino, y el cuello es el objetivo |
| Red separada + diodo de datos (salida) | **Aislamiento unidireccional** | Nada entra por red **por diseño físico**; sigue habiendo un camino de entrada humano |
| Red separada, sin enlace, con transferencia por soporte | **Air gap con sneakernet** | El USB **es** el camino, y es el vector documentado |
| Sin enlace y sin transferencia de ningún tipo | Aislamiento total | Existe muy poco: el software hay que meterlo alguna vez |

**Los tres caminos que nadie dibuja en el diagrama**: el **soporte extraíble**, el **portátil del
proveedor o del integrador** que se conecta a hacer una intervención, y la **actualización de
firmware** (BMC, BIOS, cabina, switch) que llega en una imagen descargada por alguien. Si tu
modelo de amenaza no los cubre, no has modelado el air gap: has dibujado una VLAN.

### 2.2 Modelos y cuándo usarlos

| Modelo | Encaja cuando | Coste real |
|---|---|---|
| **Aislado total** | El recinto no necesita datos frescos y su contenido no sale nunca (bóveda de backup, CA raíz offline, archivo legal) | Bajo. Es el único caso donde el air gap sale barato |
| **Unidireccional con diodo de datos** | Necesitas **sacar** telemetría, logs o resultados sin admitir nada de vuelta | Alto: hardware específico, protocolos que toleren no tener ACK, y **cero canal de retorno** — ni siquiera para confirmar que llegó |
| **Sneakernet controlado** | Necesitas **meter** software y datos con regularidad | El más caro en personas y el más peligroso. Es un proceso, no un cable |

**El diodo no resuelve la entrada.** Un diodo garantiza que nada entra por ese enlace; el software
sigue teniendo que entrar por otro sitio, y ese otro sitio es donde vive el riesgo. Diseñar el
diodo y dejar el USB sin gobierno es optimizar la puerta blindada de una casa con la ventana
abierta.

### 2.3 Espejado interno: elección y licencia verificada

| Herramienta | Licencia (verificada en crudo) | Criterio |
|---|---|---|
| **Pulp 3** (`pulpcore`) | **GPLv2** — fichero `LICENSE` de `pulp/pulpcore@main` | **Default para RPM/DEB/PyPI/contenedores** cuando el caso es exactamente "instancia downstream aislada": es el único con un flujo de **export/import** diseñado para ello (§3.1) |
| **Foreman** / **Katello** | Foreman **GPL-3.0**, Katello **GPL-2.0** — ficheros `LICENSE`/`LICENSE.txt` de `theforeman/foreman@develop` y `Katello/katello@master` | Si ya gestionas la flota RHEL/Debian con Foreman; Katello es Pulp con gestión de contenido encima |
| **Harbor** | **Apache-2.0** — fichero `LICENSE` de `goharbor/harbor@main` | **Default para registro de contenedores**: proyecto CNCF, con *proxy cache*, replicación entre instancias, etiquetas inmutables y verificación de firmas cosign en la política del proyecto |
| **Sonatype Nexus Repository Community Edition** | **EPL-1.0** — fichero `LICENSE.txt` de `sonatype/nexus-public@master` | **Trampa de licencia**: el código es EPL, pero la edición gratuita **tiene límites de uso** — la documentación vigente cita **40.000 componentes y 100.000 peticiones/día**, con pausa de ingesta al superarlos (tras un periodo de gracia). **Un espejo completo de una distribución supera 40.000 componentes con facilidad**: si tu caso es un espejo de sistema operativo, esta herramienta te obliga a comprar. Verifica los números vigentes antes de elegirla (§8) |
| **JFrog Artifactory** | **Propietario** | No hay repositorio público de fuentes que leer (`jfrog/artifactory-oss` devuelve 404). Válido si ya está pagado; **no cuentes con un escalón gratuito** sin verificarlo. **Hueco declarado**: no se ha verificado el estado actual de sus ediciones gratuitas |
| `reposync` + `createrepo_c`, `apt-mirror`/`debmirror`, `devpi`, `verdaccio`, `registry:2` | Cada una la suya | **Válido y a menudo suficiente.** Menos gobierno y menos trazabilidad, pero sin límites de uso ni licencia sorpresa. Para un recinto pequeño, un `reposync` en cron y un `rsync` a soporte baten a una plataforma que nadie mantiene |

**Regla previa a la elección**: enumera **todos** los ecosistemas que el recinto consume —RPM/DEB,
PyPI, npm, crates, Maven, Go modules, imágenes OCI, colecciones de Ansible, proveedores de
Terraform, charts de Helm, extensiones del IDE, bases de datos de escáneres— y comprueba cuáles
soporta la herramienta. **El que falte lo va a meter alguien en un USB**, y ese es exactamente el
fallo que querías evitar.

## 3. Estructura y convenciones

### 3.1 Cómo entra el software

Flujo canónico, en tres tramos, con la verificación **repetida en el lado interno**:

1. **Fuera (zona conectada)**: se sincroniza contra el origen upstream con **verificación de firma
   activada** (`gpgcheck=1`/`repo_gpgcheck=1` en `dnf`, `Signed-By` en los `.sources` de `apt`,
   hashes fijados en los *lockfiles* de lenguaje, `cosign verify` de las imágenes). Se produce un
   **artefacto de transferencia** con su manifiesto de hashes.
2. **Cruce**: soporte físico o diodo. El manifiesto viaja **junto** al contenido y, si el modelo
   de amenaza lo pide, **firmado con una clave del recinto interno**, no con la de fuera.
3. **Dentro**: se verifica **otra vez**, con la clave pública que ya vive dentro del recinto y que
   llegó por un canal distinto (ceremonia de instalación, no el mismo USB).

**Regla no negociable**: **una firma que solo se verifica en el lado conectado no protege de
nada.** El atacante que te preocupa está en el trayecto, no en el origen. Si el importador interno
acepta lo que le llega porque "ya se verificó fuera", el air gap solo ha añadido latencia.

**Pulp export/import** es el mecanismo que implementa esto de fábrica: la instancia *upstream*
genera un `.tar` de las versiones de repositorio seleccionadas más un fichero **`-toc.json` con el
hash SHA-256 global y por fichero**, que la instancia *downstream* —descrita en la documentación
como **network-isolated**— usa para verificar e importar. Soporta **exportación incremental**
(`full=False`, con `start_versions=` para fijar el punto de partida) y **troceado** por
`chunk_size` para que quepa en el soporte. Ese es el patrón a replicar aunque no uses Pulp:
**contenido + manifiesto firmado + verificación en destino + incrementalidad**.

**Imágenes de contenedor**: `skopeo copy --dest-dir` o `oras` producen un directorio OCI
transportable; `docker save`/`load` funciona pero pierde firmas y metadatos. Dentro se empujan a
Harbor o a un `registry:2` local. Si el consumidor es `cephadm`, Rook o Kubernetes, **el registro
interno debe existir antes del bootstrap**: la documentación de `cephadm` describe exactamente
este escenario y exige que todas las imágenes (Ceph, Prometheus, node-exporter, Grafana) estén ya
dentro.

**Firma en el lado aislado con cosign**: `cosign verify` puede trabajar sin salir a Internet con
`--key` y un **`--trusted-root` (fichero JSON de raíz de confianza de Sigstore) copiado dentro**,
y con `--local-image` sobre imágenes guardadas con `cosign save`. `--insecure-ignore-tlog` existe
y a veces es inevitable, pero **es una degradación**: renuncia a la prueba de inclusión en el log
de transparencia. Si lo usas, que sea una decisión escrita, no un flag copiado de un blog.

### 3.2 La transferencia física

El USB es el vector documentado. No es teoría:

- **Stuxnet** entró en una instalación de enriquecimiento aislada por soporte extraíble. Es el
  caso canónico y la razón por la que "aislado" dejó de significar "seguro".
- **Agent.BTZ / Operación Buckshot Yankee (2008)**: una memoria USB infectada conectada a un
  portátil de US CENTCOM propagó el gusano a **SIPRNet**, la red clasificada del Departamento de
  Defensa. La limpieza llevó del orden de **14 meses**, provocó la prohibición de soportes
  extraíbles y contribuyó a la creación de US Cyber Command. Un aislamiento de manual, derrotado
  por una unidad extraíble.
- **GoldenJackal** (investigación de ESET, publicada en octubre de 2024): grupo de
  ciberespionaje con **dos juegos de herramientas distintos, diseñados específicamente para saltar
  a sistemas aislados**, usados contra una embajada en Bielorrusia (2019) y contra un organismo
  gubernamental europeo (mayo 2022 – marzo 2024). El patrón: un componente en el USB recolecta del
  equipo aislado y **espera a que el mismo USB vuelva a un equipo conectado** para exfiltrar. No
  hace falta una conexión: hace falta un ciclo.

Controles mínimos, y son de proceso, no de producto:

- **Soporte de un solo sentido y de un solo uso** para la entrada: se etiqueta, se usa una vez, se
  destruye o se reformatea con procedimiento. **Nada de USB que va y viene**: el ciclo de ida y
  vuelta es literalmente el mecanismo de exfiltración de GoldenJackal.
- **Estación de escaneo intermedia** dedicada, con motores distintos de los del recinto, aislada
  ella misma y con imagen reconstruible. Es un equipo sacrificable, no el portátil de nadie.
- **Cadena de custodia**: quién generó el artefacto, quién lo transportó, quién lo importó, con
  qué hash y a qué hora. Es el registro que necesitarás cuando haya que reconstruir un incidente.
- **Autorun deshabilitado y control de dispositivos** en todo el recinto: solo soportes
  registrados, por identificador, y solo en las máquinas designadas.
- **El portátil del proveedor no entra.** Si tiene que intervenir, lo hace desde un equipo del
  recinto, con cuenta nominal y sesión registrada. Es el punto que más se negocia y el que más
  cuesta cuando se cede.

### 3.3 Parcheo y vulnerabilidades sin conexión

**El aislamiento no exime del parcheo: le cambia el calendario y el coste.** Y ese cambio es el
argumento real contra el air gap innecesario — un entorno donde un parche tarda semanas en entrar
es un entorno donde una vulnerabilidad explotada activamente vive semanas.

- **Los datos de vulnerabilidad hay que meterlos como cualquier otro artefacto**: bases de datos
  de escáner, avisos del fabricante, OVAL de la distribución. Trivy documenta explícitamente el
  escenario: sus bases (vulnerabilidades, Java, *checks*, VEX Hub) se empaquetan como **imágenes
  OCI auto-alojables** en tu propio registro; el *bundle* de *checks* va **embebido en el binario**
  como respaldo, con la fecha de la release que uses; `--offline-scan` evita las llamadas a Maven
  Central; y `--skip-version-check --disable-telemetry` —**las dos, una sola no basta**— cortan las
  conexiones a `check.trivy.dev`. Verifica el equivalente de tu escáner antes de asumirlo.
- **El escáner es software que también entra por el canal físico**, y los escáneres son objetivo
  de cadena de suministro: `kubernetes-standards` §2 documenta el compromiso de las *actions* de
  Trivy en marzo de 2026. Fija por digest y verifica firma **también** para las herramientas de
  seguridad.
- **Calendario honesto**: define un SLA de importación (p. ej. ventana semanal de contenido, más
  una vía **de emergencia ensayada** para un KEV crítico) y mídelo. El triaje sigue las reglas de
  `vulnerability-management-standards`; lo que cambia aquí es que **el reloj empieza cuando el dato
  entra, no cuando el CVE se publica**, y esa diferencia hay que medirla y reportarla, no ocultarla.
- **Inventario y SBOM son más importantes aquí, no menos**: sin ellos no puedes responder "¿me
  afecta?" cuando el aviso llega por un canal lento.

### 3.4 Tiempo

Sin fuente externa, **el reloj deriva**, y la deriva rompe cosas que nadie asocia con el reloj:

- **Kerberos**: el desfase máximo tolerado por defecto en MIT krb5 es de **300 segundos (cinco
  minutos)** (`clockskew` en `krb5.conf`). Superado, la autenticación falla en bloque y el síntoma
  es "no puedo entrar en nada", no "el reloj va mal".
- **TLS**: un reloj adelantado invalida certificados vigentes; uno atrasado acepta caducados. Y en
  un recinto aislado **nadie recibe el aviso de caducidad por correo**.
- **Logs y forense**: sin una referencia común, correlacionar dos servidores es imposible.

Diseño: **fuente de estrato 1 dentro del recinto** —receptor GNSS/GPS con antena, u oscilador
disciplinado— y `chrony` como servidor interno, con **al menos dos fuentes** para poder detectar
que una miente. Sin GNSS, el patrón mínimo aceptable es un procedimiento **documentado y
periódico** de ajuste manual contra una referencia fiable, con registro. Vigila la deriva como una
métrica de primer nivel: es de las pocas que degrada en silencio hasta que rompe todo a la vez.

### 3.5 PKI interna

- El recinto necesita **su propia jerarquía**: raíz offline (dentro del propio recinto, o custodia
  aparte), CA emisora en línea, y **puntos de distribución de CRL/OCSP internos y alcanzables**.
- **El fallo clásico**: certificados emitidos por una CA cuyo CRL DP apunta a una URL de Internet.
  Los clientes que validan revocación de forma estricta fallan; los que no, aceptan certificados
  revocados. Ninguna de las dos es la que querías.
- **El CRL caduca**: su `nextUpdate` es una bomba de relojería si nadie republica. Automatiza la
  regeneración y **monitoriza el tiempo restante**, igual que monitorizas la caducidad de los
  certificados.
- Nada de anclas de confianza que dependan de un servicio externo. La cadena entera se resuelve
  dentro.

### 3.6 Licencias y dependencias que llaman a casa

**Es el fallo de diseño que se descubre el día del corte, no antes.** Antes de aislar, inventaria
qué componente necesita hablar con el exterior para **funcionar**, no solo para actualizarse:

- Activación de producto y servidores de licencia (incluidos los que solo comprueban "de vez en
  cuando" y fallan al cabo de N días).
- Comprobaciones de revocación de certificados y de sellado de tiempo (RFC 3161).
- Telemetría obligatoria y comprobaciones de versión.
- Resolución DNS de dominios externos, incluidas las que hace una librería en el arranque.
- Autenticación federada contra un IdP de nube. **Federar con un IdP externo es tener un camino de
  datos**: o el IdP vive dentro, o el recinto no está aislado.
- Modelos, diccionarios y bases de datos que un servicio descarga en el primer arranque.

Exige por contrato, **antes de comprar**, la respuesta a "¿funciona sin salida a Internet y por
cuánto tiempo?" y una vía de licenciamiento offline. Verifícalo **en un entorno realmente cortado**
—no con una regla de firewall que puedas quitar—, porque la respuesta comercial y la técnica
raramente coinciden.

### 3.7 Copia, recuperación y observabilidad

- **La copia vive dentro del recinto** y su clave también: un repositorio cifrado cuyo secreto está
  en un KMS de nube es un backup que no puedes restaurar. Mecánica en `backup-recovery-standards`;
  la restricción es de aquí.
- **El plan de DR no puede asumir descargas.** Todo lo necesario para reconstruir —imágenes ISO,
  paquetes, imágenes de contenedor, binarios de las herramientas de restauración, la propia
  documentación— tiene que estar dentro y **probado desde dentro**. Un runbook que empieza con
  `curl https://…` no es un runbook en este entorno.
- **Telemetría**: métricas, logs y trazas se quedan dentro; el stack de observabilidad se despliega
  completo en el recinto. Si hay que sacar algo (informes, alertas al SOC corporativo), **el diodo
  es el mecanismo correcto** y hay que aceptar que no habrá canal de retorno: nadie podrá "pedir
  más contexto" desde fuera. Diseña lo que sale para ser autosuficiente.
- **El SOC de fuera no ve el recinto.** O hay analistas dentro, o hay un flujo unidireccional bien
  diseñado, o el recinto es un punto ciego de detección — que es exactamente donde un atacante que
  ya entró quiere estar.

## 4. Verificación

El aislamiento se demuestra, no se declara.

1. **Prueba de camino**: desde varios hosts del recinto, intento activo de salida por HTTP(S), DNS,
   NTP, ICMP y protocolos comunes hacia destinos externos controlados. Debe fallar **todo**, y hay
   que revisar también qué se registró en el borde. Repetir tras cada cambio de red.
2. **Inventario de caminos físicos**: puertos USB habilitados, unidades ópticas, BMC y su red de
   gestión, consolas serie, Wi-Fi y Bluetooth en portátiles y servidores, y **cualquier
   interfaz de gestión fuera de banda** que alguien haya conectado a la red corporativa "solo para
   monitorizar". Esta última es la más común y la que rompe el aislamiento entero.
3. **Prueba de la cadena de importación**: mete un artefacto **con la firma manipulada** a
   propósito y comprueba que **el lado interno lo rechaza**. Si pasa, tu verificación es decorativa.
4. **Prueba del reloj**: desvía el reloj de un servidor más allá de `clockskew` y comprueba que la
   detección salta antes de que rompa la autenticación.
5. **Prueba de licencias y arranque en frío**: reinicia el recinto completo sin ninguna
   conectividad y comprueba qué no arranca. Hacerlo la primera vez en un desastre es el escenario
   que se quería evitar.
6. **Ensayo de la vía de emergencia**: cronometra cuánto tarda un parche crítico en estar aplicado
   dentro, de extremo a extremo. Ese número es tu exposición real, y va en el registro de riesgos.

## 5. Seguridad

- **Modelo de amenaza correcto**: el aislamiento elimina el atacante remoto oportunista. **No
  elimina** al insider, al proveedor, a la cadena de suministro del software que importas ni al
  atacante paciente que espera a que un USB haga el ciclo de vuelta. Diseña para esos cuatro.
- **Defensa en profundidad dentro del recinto**: el error más caro es tratar el interior como zona
  de confianza. Sin salida a Internet, un movimiento lateral es igual de fácil y **mucho menos
  visible**. Segmentación interna, mínimo privilegio, MFA, EDR y hardening siguen siendo
  obligatorios (`linux-hardening-standards`, `identity-access-management-standards`).
- **La exfiltración también es física.** Los mismos controles de soporte que aplicas a la entrada
  aplican a la salida, y con más razón si lo que motivó el aislamiento fue la confidencialidad.
- **Vigila lo que sí queda**: intentos de salida a Internet desde el recinto son una señal de
  detección de altísimo valor —o hay una fuga de configuración, o hay algo intentando llamar a
  casa—. Que fallen no significa que no haya que alertar. Al contrario: son la alerta más limpia
  que vas a tener.
- **Criptografía**: el recinto no puede apoyarse en servicios externos de sellado de tiempo,
  transparencia ni gestión de claves. Todo dentro, con custodia y rotación propias.

## 6. Cuándo el air gap es la respuesta correcta

| Situación | Veredicto |
|---|---|
| Bóveda de backup inmutable, CA raíz offline, archivo de largo plazo | **Correcto y barato.** Poco contenido, poca frecuencia, poco coste operativo |
| Sistema cuyo compromiso tiene consecuencias físicas o de seguridad nacional, con vida útil larga y sin capacidad de parcheo rápido | **Correcto**, y el coste está justificado (aquí la doctrina la fija `ot-ics-security-standards`) |
| Datos con clasificación que lo exige por norma | **Correcto por obligación**; el trabajo es hacerlo bien, no discutirlo |
| Laboratorio de análisis de malware o de I+D con material sensible | **Correcto**, con la dirección de amenaza invertida (`ctf-lab-standards`) |
| Aplicación de negocio normal, "por si acaso" | **Teatro caro.** Degrada la seguridad: el parcheo se vuelve lento, la observabilidad ciega, y el equipo acaba abriendo excepciones que nadie audita |
| Sustituir una gestión de accesos y una segmentación que no se quieren hacer | **Incorrecto.** El air gap no es un atajo para no hacer IAM ni política de red; es un control adicional **encima** de ambos |

**Criterio en una línea**: el air gap se justifica cuando **el coste de estar desconectado es menor
que el riesgo de estar conectado**, y ese cálculo hay que escribirlo con números —tiempo de
parcheo, personas dedicadas, coste del espejo— no con adjetivos.

## 7. Sostenibilidad y prohibiciones

- **Coste recurrente, no proyecto**: el espejo, la ventana de importación, la estación de escaneo,
  la fuente de tiempo, la PKI y el ensayo de DR son trabajo **continuo y con dueño nombrado**. Un
  air gap sin presupuesto operativo se degrada a "red vieja sin parchear con reglas de firewall".
- **Revisa la decisión cada año**: ¿sigue habiendo motivo? Un recinto aislado que se mantiene por
  inercia es puro coste, y un recinto donde ya se han abierto tres excepciones "temporales" ya no
  está aislado — está peor que segmentado, porque nadie revisa sus reglas.

Prohibiciones explícitas:

- ❌ Llamar "air gap" a una red con reglas de firewall hacia Internet. **PROHIBIDO** en cualquier
  documento de diseño o de auditoría: la palabra fija expectativas de riesgo que la realidad no
  cumple.
- ❌ Verificar la firma **solo** en el lado conectado.
- ❌ Soportes extraíbles que entran y salen del recinto (el ciclo de ida y vuelta).
- ❌ Soportes personales, y equipos de proveedor conectados a la red del recinto.
- ❌ Autorun habilitado; escritura sin control de dispositivos.
- ❌ "Aquí no hace falta parchear porque está aislado". Es la afirmación que convierte el
  aislamiento en una vulnerabilidad de larga duración.
- ❌ Un recinto sin fuente de tiempo definida y monitorizada.
- ❌ CRL o puntos de distribución que apunten fuera; anclas de confianza que dependan de un
  servicio externo.
- ❌ Excepciones "temporales" al aislamiento sin fecha de caducidad y sin revisión.
- ❌ Federar la identidad del recinto contra un IdP externo.
- ❌ Backups o claves de cifrado del recinto custodiadas fuera y solo fuera.
- ❌ Un plan de DR que en algún paso requiera descargar algo.
- ❌ Aislar sin haber inventariado qué componentes necesitan llamar a casa para funcionar.
- ❌ Elegir una plataforma de espejado por su licencia de código sin comprobar los **límites de uso
  del binario gratuito** (§2.3).
- ❌ Tratar el interior del recinto como zona de confianza plana.

## 8. Verificación web obligatoria

Antes de fijar nada de este documento en un diseño real:

1. **Licencias y límites de las plataformas de espejado**: verificadas en crudo a ago-2026 —
   Pulp **GPLv2** (`pulp/pulpcore@main:LICENSE`), Harbor **Apache-2.0**
   (`goharbor/harbor@main:LICENSE`), Nexus **EPL-1.0** (`sonatype/nexus-public@master:LICENSE.txt`),
   Foreman **GPL-3.0**, Katello **GPL-2.0**. **JFrog Artifactory es propietario** y no tiene
   repositorio de fuentes público. Re-verifica **siempre leyendo el fichero de licencia**, no la
   etiqueta de GitHub ni la web comercial.
2. **Límites de uso de Nexus Repository Community Edition**: la documentación vigente cita
   **40.000 componentes / 100.000 peticiones diarias**; el anuncio original de Sonatype citó cifras
   distintas (100.000 componentes / 200.000 peticiones). **Discrepancia declarada**: comprueba
   `help.sonatype.com` para tu versión antes de dimensionar. **Hueco declarado**: no se ha podido
   leer esa página en crudo (aplicación JS); el dato entró por búsqueda web, no verbatim.
3. **Estado de las ediciones gratuitas de JFrog** (Artifactory OSS, JFrog Container Registry):
   **hueco declarado**, no verificado.
4. **Requisitos de conectividad de tu escáner**: la guía de air-gap de Trivy es la referencia
   verificada aquí (bases como imágenes OCI auto-alojables, *checks* embebidos, `--offline-scan`,
   `--skip-version-check` **y** `--disable-telemetry`). Para Grype, Wazuh, OpenSCAP u otro,
   verifica el equivalente en su documentación — no lo asumas por analogía.
5. **Flags de `cosign verify`** (`--key`, `--trusted-root`, `--local-image`,
   `--insecure-ignore-tlog`): verificados contra `doc/cosign_verify.md` de `sigstore/cosign@main`.
   Cambian entre versiones mayores; comprueba los de tu binario.
6. **`clockskew` de Kerberos**: 300 s por defecto según la documentación de MIT krb5. Active
   Directory tiene su propio parámetro y su propia política — verifícalo aparte si el recinto es
   Windows.
7. **Casos citados**: Stuxnet, Agent.BTZ / Buckshot Yankee (2008, SIPRNet) y GoldenJackal (ESET,
   octubre de 2024). Si necesitas citarlos formalmente, ve a la publicación original de ESET y a
   las fuentes primarias del caso de 2008; los detalles de atribución están disputados y **este
   documento no toma partido en la atribución**, solo usa los casos como prueba de que el vector
   existe.
8. **Normativa aplicable al recinto** (ENS, esquemas de clasificación nacionales, IEC 62443 si es
   industrial): la fija `grc-compliance-standards` u `ot-ics-security-standards`. **Hueco
   declarado**: este documento no cita requisitos de entornos clasificados; las fuentes de defensa
   consultadas históricamente en este catálogo bloquean el acceso automatizado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
