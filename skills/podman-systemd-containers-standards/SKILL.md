---
name: podman-systemd-containers-standards
description: Containers as systemd services on a single host with Podman and Quadlet, without an orchestrator. Use when writing or debugging Quadlet unit files (.container, .pod, .volume, .network, .kube, .build, .image, .artifact) under /etc/containers/systemd or ~/.config/containers/systemd, running quadlet -dryrun or podman quadlet list/install/rm, migrating off the deprecated podman generate systemd, podman auto-update with io.containers.autoupdate=registry and podman-auto-update.timer, netavark and aardvark-dns or pasta rootless networking and default_rootless_network_cmd, containers.conf, storage.conf, registries.conf unqualified-search-registries and policy.json image trust, podman secret versus systemd LoadCredential=, --userns=keep-id, named volumes versus bind mounts, podman.socket with DOCKER_HOST for docker compose, podman-compose, podman system prune housekeeping, or deciding between a single-host Quadlet stack and a real orchestrator.
---

# Estándares de contenedores como servicios de systemd (Podman + Quadlet)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: aquí un contenedor **no es una carga de trabajo programable**: es un
> **servicio de systemd** que resulta estar empaquetado como imagen OCI. Todo lo que sigue se
> deriva de eso. Si necesitas que algo *decida en qué host corre*, no estás en este documento:
> estás en `kubernetes-standards`. Y si la respuesta a esa necesidad es un script propio que
> reparte contenedores entre hosts, has escrito un orquestador peor que los que ya existen.

## 1. Alcance y triggers

Aplica a **ejecutar contenedores en un host, bajo systemd, sin orquestador**: Quadlet como
formato canónico de unidad, modo rootless, red de Podman en el host, volúmenes, política de
imágenes y firma, actualización automatizada, integración real con systemd (notify, health
checks, cgroups, journald, credenciales), compatibilidad con Docker y las dos migraciones que
importan (Compose → Quadlet, Quadlet → orquestador).

Disparadores: `podman`, `podman-remote`, `quadlet`, `/usr/libexec/podman/quadlet -dryrun`,
`podman quadlet list|install|rm|print`, ficheros `*.container`, `*.pod`, `*.volume`,
`*.network`, `*.kube`, `*.build`, `*.image`, `*.artifact`, `/etc/containers/systemd/`,
`~/.config/containers/systemd/`, `/run/containers/systemd/`,
`/usr/share/containers/systemd/`, `containers.conf`, `storage.conf`, `registries.conf`,
`policy.json`, `podman generate systemd`, `podman auto-update`,
`io.containers.autoupdate`, `AutoUpdate=`, `podman-auto-update.timer`, `podman secret`,
`--sdnotify=container`, `Notify=`, `HealthCmd=`, `HealthOnFailure=`, `--userns=keep-id`,
`loginctl enable-linger`, `/etc/subuid`, `netavark`, `aardvark-dns`, `pasta`/`passt`,
`default_rootless_network_cmd`, `podman.socket`, `DOCKER_HOST`, `podman compose`,
`podman-compose`, `podman system prune`, `podlet`, "el contenedor no arranca tras reiniciar",
"la unidad Quadlet no aparece en systemctl".

**Regla de arbitraje interna**: si la respuesta se escribe en un **fichero de unidad
(`*.container` y hermanos) o en un `containers.conf`/`registries.conf` de un host**, es de esta
skill. Si se escribe en un **manifiesto con `apiVersion`/`kind` que un scheduler consume**, es
de `kubernetes-standards`.

**No aplica**: ver `kubernetes-standards` (**frontera pactada**: allí la **construcción de la
imagen** —`Containerfile`/`Dockerfile`, multi-stage, base mínima, pin por digest, SBOM y firma
con cosign—, los **manifiestos** y su admisión, Helm/Kustomize y GitOps; **aquí** cómo esa misma
imagen se ejecuta como servicio de un host sin scheduler. La `.kube` de Quadlet **no convierte
esto en Kubernetes**: es un formato de entrada, no un cluster),
`container-runtime-security-standards` (**la seguridad del contenedor ya en ejecución es suya,
sin excepción**: seccomp, elección y pinning del runtime OCI —`runc`/`crun`/gVisor/Kata—,
`--privileged` y capabilities, rutas de escape, montaje de sockets del runtime, detección en
runtime con Falco/Tetragon, drift y forense con CRIU; **aquí** rootless como **modelo operativo
por defecto del servicio** —linger, `keep-id`, qué se pierde y cómo se compensa—, no como
control de aislamiento), `selinux-standards` (**el MAC es suyo**: `container_t`, MCS, semántica
exacta de `:z`/`:Z`, `udica`; aquí solo la **obligación** de etiquetar el montaje),
`linux-administration-standards` (**systemd genérico**: `Type=`, `Restart=`, dependencias,
journald, cgroups v2, timers, `systemd-analyze security` — **la unidad generada por Quadlet es
una unidad de systemd corriente y su semántica se decide allí**; aquí solo las claves de la
sección `[Container]`/`[Pod]`/… y lo que Quadlet genera),
`rhel-fedora-standards` (que Podman es el default de la familia y Docker la excepción a
justificar; aquí el criterio detallado de cómo se opera), `homelab-standards` (**la frontera es
el rigor exigido, no la herramienta**: allí un lab personal donde Compose upstream sin traducir
es una respuesta legítima; aquí un servicio con dueño, arranque en frío probado y actualización
gobernada), `backup-recovery-standards` (**el respaldo de los volúmenes es suyo**: mecánica,
retención, inmutabilidad y restore probado; aquí solo **qué** hay que respaldar y que el volumen
se para o se cuiesce antes de copiarlo), `secrets-management-standards` (origen, rotación y
custodia del secreto —Vault/OpenBao, SOPS, ESO—; aquí solo **cómo llega** al contenedor:
`podman secret` y `LoadCredential=`), `cryptography-pki-standards` (PKI y claves de firma; aquí
solo que `policy.json` **exige** firma), `networking-standards` y `firewall-policy-standards`
(diseño de red y política de filtrado como artefacto gobernado; aquí solo la red de Podman en el
host y la **trampa** de los puertos publicados frente al firewall), `observability-standards`
(diseño de métricas y alertas; aquí qué exportar), `iac-standards` (Ansible/Terraform que
**despliegan** los ficheros de unidad; aquí qué debe contener la unidad), `cicd-standards` (la
pipeline que construye y firma la imagen), `ha-clustering-standards` (**mención cruzada, sin
solape**: si la pregunta es "cómo sobrevive este contenedor a la caída del **host**", la
respuesta honesta es **casi nunca con Pacemaker** —ver §7—, sino con un orquestador o asumiendo
el downtime; Pacemaker gestionando contenedores en un host es complejidad que no compra nada).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Por defecto (ago-2026) | Motivo |
|---|---|---|
| Motor | **Podman 6.0.2** (línea 6.0, GA 2026-06-24); línea anterior mantenida **5.8.5**. `6.1.0-rc1` publicada 2026-07-31 — **no en prod** | Sin daemon, sin root, unidad de systemd real por contenedor. Es el modelo que encaja con un host |
| **Versión mínima absoluta** | **≥ 5.8.4** o **≥ 6.0.0** | **CVE-2026-57231** (GHSA-4hq8-gpf5-8p68): una imagen maliciosa con entradas `Env` malformadas filtra variables de entorno **del host** al contenedor, con comodín `*` para exfiltrar sin conocer los nombres. Afecta **1.8.1 → 5.8.3**. Cualquier host por debajo de esa línea que ejecute imágenes de terceros está comprometible por diseño |
| Formato de unidad | **Quadlet**, siempre | Es el formato declarativo soportado. `podman generate systemd` no es una alternativa (ver abajo) |
| Runtime OCI | **`crun` 1.28** | Default de la familia RHEL/Fedora, menor huella. La elección y el pinning del runtime como control de seguridad los fija `container-runtime-security-standards` |
| Modo | **Rootless** | Rootful exige **justificación escrita** en el repo (§3.3) |
| Red | **netavark 2.0.0** + **aardvark-dns 2.0.0** | Podman 6 **exige** exactamente estas versiones. CNI **eliminado** en Podman 6 |
| Red rootless | **pasta** (`passt`) | Default upstream desde **Podman 5.0**; en RHEL/Oracle Linux desde **9.5**. En **Podman 6 `slirp4netns` está eliminado**: no es una opción, ni con `default_rootless_network_cmd` |
| Backend de firewall | **nftables** | `iptables` **eliminado** en Podman 6 |
| cgroups | **v2 obligatorio** | Podman 6 **elimina** el soporte de cgroups v1. Un host con cgroups v1 no actualiza |
| Base de datos interna | **SQLite** | BoltDB **eliminado**; Podman 6 intenta migración automática al primer arranque — **hacer copia de `~/.local/share/containers` / `/var/lib/containers` antes** |
| Compose | **`docker compose` v2 contra `podman.socket`** si hay que consumir un Compose upstream; **Quadlet** para todo lo propio | `podman-compose` (v1.6.0, jun-2026) es una reimplementación con huecos conocidos (secretos externos, configs, red) |
| Actualización | `podman auto-update` con política **`registry`** + `podman-auto-update.timer` | Ver §3.5: solo es seguro con `--sdnotify=container` y rollback |
| Herramienta de conversión | `podlet` para el **primer borrador** de una unidad | Su salida se revisa a mano: no genera hardening ni dependencias correctas |

**Piezas acompañantes obligadas con Podman 6.0.x** (lo dice la nota de release, no es
opinable): **Buildah 1.44.0**, **Skopeo 1.23**, **netavark y aardvark-dns 2.0.0**, y ficheros de
configuración de `container-libs` **common/v0.68.0**. Mezclar versiones aquí produce fallos que
parecen de red o de storage y no lo son.

**Cambio de gobernanza a tener en cuenta**: Podman es proyecto **CNCF (Sandbox desde el
2025-01-21)** y el repositorio se ha movido a la organización **`podman-container-tools`**; el
import path pasó a `go.podman.io/podman/v6`. Consecuencia práctica: **cualquier automatización,
pin de acción de CI o URL de descarga que apunte a `github.com/containers/podman` se revisa** —
el redirect funciona hoy, pero un artefacto de suministro no se ancla en un redirect.

### 2.1 Cuándo esto y cuándo un orquestador (el punto de corte honesto)

| Situación | Respuesta |
|---|---|
| **Un host**, pocos servicios, sin necesidad de programación ni de escalado horizontal, downtime del host aceptable | **Quadlet.** Es la respuesta correcta, no la respuesta pobre |
| Varios hosts y hace falta **decidir dónde corre** cada cosa | **Orquestador.** Kubernetes (o k3s/Talos si el tamaño lo pide) |
| Hace falta **escalar réplicas** por carga, o rolling update sin ventana | **Orquestador** |
| Hace falta que un servicio **sobreviva a la caída de su host** de forma automática | **Orquestador.** No Pacemaker, no scripts |
| Dos hosts y "que uno tome el relevo del otro" con contenedores | Casi siempre: **asumir el downtime** o **balanceador delante de dos instancias activas** con estado fuera. Ver §7 |
| Mucho servicio pero todo en un host y sin SLO de disponibilidad | Quadlet, con la nota de que el host **es** el SPOF y eso está aceptado por escrito |

**El antipatrón**: reimplementar un orquestador a mano — scripts que copian unidades entre
hosts, health checks caseros que hacen `ssh` para arrancar el contenedor en el otro nodo, un
"registro de servicios" en un fichero. Eso no es simplicidad, es un orquestador sin comunidad,
sin tests y sin nadie que sepa depurarlo a las 3 de la mañana. **Si necesitas programación,
usa un programador.**

**El antipatrón contrario, igual de caro**: montar Kubernetes para cuatro servicios en un host.
Multiplica piezas, upgrades y modos de fallo sin dar nada a cambio.

## 3. Estructura y convenciones

### 3.1 Quadlet es el formato canónico

Quadlet es un **generador de systemd**: lee ficheros descriptivos y **genera unidades `.service`
en tiempo de arranque y de `daemon-reload`**. Consecuencias operativas que hay que interiorizar:

- La unidad generada **no existe en disco de forma persistente**: no se edita, no se versiona, no
  se copia. Se edita el `.container` y se recarga.
- **Recarga**: `systemctl daemon-reload` (rootful) / `systemctl --user daemon-reload` (rootless).
  No hay `podman quadlet reload` que sustituya a esto.
- **Validación antes de recargar**: ejecutar el generador en seco —
  `/usr/libexec/podman/quadlet -dryrun -user` — y leer la unidad que produce. **Un fichero
  Quadlet con un error de sintaxis no falla ruidosamente: simplemente no genera la unidad**, y
  `systemctl start` responde "unit not found". Es el fallo nº1 del formato.
- El nombre del servicio se deriva del fichero: `web.container` → `web.service`.
- `podman quadlet list|install|rm|print` existe como interfaz de gestión. **En Podman 6 cambió
  el modelo de `podman quadlet install`**: los ficheros asociados pasan a **subdirectorios** en
  lugar del antiguo fichero de seguimiento `.app`. Si automatizabas contra ese comportamiento,
  se revisa antes de subir a 6.

**Tipos de unidad Quadlet vigentes (8, verificados en el manual `podman-systemd.unit(5)`)**:
`.container`, `.pod`, `.volume`, `.network`, `.kube`, `.build`, `.image`, `.artifact`.

| Tipo | Para qué, y criterio |
|---|---|
| `.container` | El caso normal. **Uno por servicio** |
| `.pod` | Varios contenedores que **comparten namespace de red** y ciclo de vida. Úsalo solo si de verdad comparten red; si no, dos `.container` y una `.network` |
| `.volume` | Volumen nombrado declarado. **Preferido a crear volúmenes a mano** |
| `.network` | Red de usuario declarada. Obligatoria para DNS entre contenedores (§3.4) |
| `.image` | Pre-descarga de una imagen como dependencia de otra unidad. Útil para `.container` que no deben tirar del registry en el arranque |
| `.build` | Construye una imagen en el host desde un `Containerfile`. **Vetado en producción**: construir en el host de ejecución rompe la inmutabilidad del artefacto y mezcla toolchain de build con runtime. La imagen se construye en CI (`cicd-standards`) |
| `.kube` | Ejecuta un YAML tipo Kubernetes en el host. Solo como **puente de migración** hacia un cluster real, nunca como destino. Aviso: `podman kube play` tuvo un traversal por symlink (GHSA-wp3j-xq48-xpjw, abr-2026, severidad baja) — no ejecutar YAML no confiable |
| `.artifact` | Artefactos OCI. Nicho; verificar comportamiento antes de depender de él |

**Rutas de búsqueda** (verbatim del manual, en orden de precedencia; `/run` gana sobre `/etc`,
que gana sobre `/usr`):

- Rootful: `/run/containers/systemd/` (temporales/pruebas) → `/etc/containers/systemd/`
  (definidos por el administrador) → `/usr/share/containers/systemd/` (definidos por la
  distribución).
- Rootless: `$XDG_RUNTIME_DIR/containers/systemd/` → `$XDG_CONFIG_HOME/containers/systemd/` (o
  `~/.config/containers/systemd/`) → `/etc/containers/systemd/users/${UID}` →
  `/etc/containers/systemd/users/` → `/usr/share/containers/systemd/users/${UID}` →
  `/usr/share/containers/systemd/users/`.

Criterio: **lo propio va en `/etc/containers/systemd/` (rootful) o
`~/.config/containers/systemd/` (rootless)**. `/run/...` solo para probar. `/usr/share/...` es
territorio del empaquetador — no escribas ahí.

**`podman generate systemd` está DEPRECADO.** Cita textual del manual: *"**podman generate
systemd** is deprecated. We recommend using Quadlet files when running Podman containers or pods
under systemd. There are no plans to remove the command. It will receive urgent bug fixes but no
new features."* Lectura correcta: **no está eliminado, está congelado**. Por tanto:

- ❌ Prohibido en cualquier unidad nueva.
- Las unidades existentes generadas así **funcionan**, pero son deuda: no reciben funcionalidad,
  y su modelo (generar un `.service` a partir de un contenedor ya creado) es imperativo —
  el estado real vive en el contenedor, no en el fichero, y eso es exactamente lo que rompe la
  reconstruibilidad desde cero.
- Migración: `podlet` para el borrador, revisión a mano, y **prueba de arranque en frío** (§4).

### 3.2 Layout del repositorio

```
containers/
├─ quadlet/
│  ├─ system/              # → /etc/containers/systemd/
│  │  ├─ app.network
│  │  ├─ app-data.volume
│  │  └─ app.container
│  └─ users/<svc>/         # → ~<svc>/.config/containers/systemd/
├─ containers.conf.d/      # overrides drop-in, nunca el fichero base
├─ registries.conf.d/
├─ policy.json
└─ README.md               # dueño, propósito, y la justificación de cada rootful
```

- **Todo bajo control de versiones**, desplegado por Ansible/`iac-standards`. Un fichero Quadlet
  editado a mano en el host es un snowflake.
- Overrides de systemd sobre la unidad generada: `/etc/systemd/system/<svc>.service.d/*.conf`
  cuando haga falta algo que Quadlet no expone. Documentar por qué.

### 3.3 Rootless por defecto

- **Requisitos**: rangos en `/etc/subuid` y `/etc/subgid` para el usuario (uno por usuario, sin
  solapes) y **`loginctl enable-linger <usuario>`**. Sin linger, las unidades de usuario **no
  arrancan en el boot y mueren al cerrar sesión** — es la causa nº1 de "funcionaba y tras el
  reinicio no está".
- **Un usuario de servicio por servicio**, sin shell interactiva. No compartir usuario entre
  servicios no relacionados: comparten storage, red y namespace de usuario.
- **Qué se pierde y cómo se resuelve**:

| Limitación rootless | Resolución |
|---|---|
| No puede escuchar en puertos < 1024 | Publicar en puerto alto y **poner delante un reverse proxy**, o bajar `net.ipv4.ip_unprivileged_port_start` por `sysctl.d` (documentado). **Nunca** dar `CAP_NET_BIND_SERVICE` al proceso rootless como atajo |
| Capabilities limitadas | Si el servicio *de verdad* las necesita, es candidato a rootful — con justificación |
| UID dentro ≠ UID fuera en volúmenes | `--userns=keep-id` (o `UserNS=keep-id` en Quadlet) para que el UID del usuario se mapee 1:1. Sin esto, los ficheros del bind mount aparecen como `nobody` |
| Rendimiento de I/O en overlay sin `fuse-overlayfs` nativo | Verificar que el kernel soporta overlay en user namespace (lo normal hoy); si no, medir antes de asumir |
| Algunas herramientas esperan el socket de root | Socket de usuario en `$XDG_RUNTIME_DIR/podman/podman.sock` |

- **Rootful solo con justificación escrita en el repo**, y aun así: `NoNewPrivileges`, sin
  `--privileged`, capabilities mínimas. El detalle de ese hardening es de
  `container-runtime-security-standards`.

### 3.4 Red

- **netavark** es el backend (CNI eliminado en Podman 6); **aardvark-dns** da resolución de
  nombres entre contenedores.
- **El DNS entre contenedores solo funciona en redes de usuario creadas explícitamente.** En la
  red `podman` por defecto **no hay resolución por nombre**. Por tanto: **una `.network` por
  stack**, y los contenedores del stack se hablan por nombre de servicio. Esto no es opcional,
  es la diferencia entre una configuración mantenible y un fichero lleno de IPs.
- **Rootless usa pasta**. Diferencia con el difunto `slirp4netns` que hay que conocer: pasta
  **copia la configuración de red del host** en vez de crear una red NAT aparte, así que **desde
  el contenedor la IP principal del host no es alcanzable por defecto** y `host.containers.internal`
  puede no comportarse como esperas. Si necesitas hablar con el host, `--map-gw` u otra ruta
  explícita — y se documenta.
- **La trampa del firewall**: publicar un puerto (`PublishPort=`) **inserta reglas en el
  ruleset del host** y puede abrir el servicio a toda la red aunque tu política de filtrado diga
  otra cosa. Regla: **`PublishPort=` siempre con IP de escucha explícita** (`127.0.0.1:8080:8080`
  o la IP de la interfaz correcta), **nunca el puerto suelto**. La política del host es de
  `firewall-policy-standards`; la obligación de no saltársela es de aquí.
- IPv6: si el host lo tiene, la red del stack lo declara explícitamente. Una red dual-stack a
  medias produce fallos de conexión intermitentes que se diagnostican fatal.
- Podman 6: *"Network isolation now defaults to enabled"* — comportamiento nuevo respecto a 5.x
  que puede romper stacks que dependían de que contenedores en redes distintas se vieran.
  **Verificar al migrar.**

### 3.5 Almacenamiento

- **Volumen nombrado (`.volume`) por defecto.** Bind mount solo cuando el dato tiene que ser
  visible y manipulable desde el host (config, certificados, un directorio de datos existente).
- **Todo montaje con etiquetado SELinux**: `:z` (compartido entre contenedores) o `:Z`
  (exclusivo). La semántica exacta y sus riesgos —`:Z` sobre un directorio del sistema
  reetiqueta recursivamente y puede romper el host— son de `selinux-standards`. Aquí solo:
  **un bind mount sin `:z`/`:Z` en un host con SELinux en enforcing falla, y "desactivar SELinux"
  no es la solución.**
- Permisos: con rootless, `UserNS=keep-id` para que los UID cuadren. Con volúmenes nombrados,
  Quadlet `.volume` acepta desde Podman 6 las claves **`UID=`, `GID=` y `Options=`**, que evitan
  el clásico `chown` a mano en un `ExecStartPre`.
- **`Mount=` sin origen** crea volúmenes anónimos (soportado desde Podman 6). Evítalo en
  servicios: un volumen anónimo es dato sin nombre, sin respaldo y sin dueño.
- **Respaldo**: el volumen se respalda **parando el contenedor o cuiesciendo la aplicación**; un
  `tar` en caliente de un directorio de base de datos es una copia corrupta con buen aspecto. La
  mecánica, retención y el restore probado son de `backup-recovery-standards`. Lo que fija esta
  skill: **todo `.volume` de un servicio tiene una entrada en el plan de respaldo, o una línea
  explícita diciendo que es descartable.**

### 3.6 Imágenes, registries y actualización

- **`registries.conf`**: `unqualified-search-registries` es un **peligro de seguridad**, no una
  comodidad. Un `podman run nginx` sin cualificar resuelve contra la lista y puede traer la
  imagen equivocada del registry equivocado. **Regla: todas las referencias de imagen en las
  unidades van completamente cualificadas** (`registry.example.com/ns/img:tag`), y la lista de
  búsqueda no cualificada se deja **vacía** en servidores.
- **Mirrors y `blocked`/`insecure`**: `insecure = true` está **prohibido** en producción. Un
  registry interno sin TLS es un registry que cualquiera en la red puede suplantar.
- **`policy.json`**: la política por defecto de muchas distros es `insecureAcceptAnything`.
  **Debe endurecerse** para exigir firma en los registries propios (`signedBy`/sigstore). La
  gestión de las claves de firma es de `cryptography-pki-standards`; la firma en la pipeline, de
  `cicd-standards`. Aquí: **el host verifica; un host que acepta cualquier cosa anula toda la
  cadena de suministro que se construyó aguas arriba.**
- **Digest frente a tag — la tensión real**:
  - **Digest** (`img@sha256:…`) es el contrato: reproducible, auditable. Es lo correcto para un
    servicio crítico y para todo lo que despliegue IaC.
  - **Tag** es lo que necesita `podman auto-update --policy registry`, que compara contra el
    registry: **una referencia fijada por digest no se actualiza sola** (por definición: el
    digest ya es exacto).
  - **Criterio**: servicios críticos → **digest + actualización deliberada por pipeline**.
    Servicios de bajo riesgo con imagen de proveedor de confianza → **tag estable +
    auto-update + rollback**. **Nunca `:latest`.**
- **`podman auto-update`** (verificado en el manual):
  - Dos políticas: **`registry`** (consulta el registry) y **`local`** (compara con la imagen ya
    en el almacenamiento local). Se declaran con la etiqueta `io.containers.autoupdate` o la
    clave `AutoUpdate=` de Quadlet.
  - Lo dispara `podman-auto-update.service`, **activado a diario a medianoche por
    `podman-auto-update.timer`**. Cambiar ese horario a la ventana acordada y **añadir
    `RandomizedDelaySec`** si hay varios hosts: si no, toda la flota golpea el registry a la vez.
  - **Rollback está activo por defecto** ("Default is true"): si la unidad falla al reiniciar con
    la imagen nueva, vuelve a la anterior. **Pero la detección de fallo real exige que el
    contenedor envíe `READY` por SDNOTIFY, creado con `--sdnotify=container`.** Sin eso, "arrancó
    el proceso" cuenta como éxito y el rollback nunca se dispara: tienes actualización automática
    **sin red de seguridad**, que es peor que no tenerla.
  - **Requisito de gobierno**: auto-update **solo** sobre imágenes de un registry cuya firma
    verifica `policy.json`. Auto-update contra un registry público sin verificación es ejecución
    remota de código programada por `cron`.
- **Higiene**: `podman system prune` (y `podman image prune`) periódico en timer propio. Ojo:
  **en Podman 6 `podman volume prune` solo poda volúmenes anónimos no usados** (cambio para
  igualar a Docker); el comportamiento anterior exige `--all`. Un `--all` heredado de un script
  de la era 5.x **borra volúmenes nombrados**: revisar antes de migrar.

### 3.7 Integración de verdad con systemd

Lo que separa "un contenedor que corre" de "un servicio":

- **`Notify=true` / `--sdnotify=container`**: la unidad se declara activa cuando la aplicación
  lo dice, no cuando el proceso existe. Requisito para dependencias fiables y para el rollback de
  auto-update. Si la aplicación no habla sdnotify, `Notify=healthy` (que ata el READY al health
  check) es la alternativa — **verificar disponibilidad en la versión instalada**.
- **Health checks**: `HealthCmd=`, `HealthInterval=`, `HealthRetries=`, `HealthStartPeriod=` y
  **`HealthOnFailure=`** (`kill`/`restart`/`stop`/`none`). Un health check que solo pinta
  "unhealthy" y no actúa es decoración. Criterio: **`HealthOnFailure=kill` + `Restart=on-failure`
  en la unidad**, para que el ciclo lo cierre systemd con su backoff, que es donde debe estar.
- **Dependencias**: `After=`/`Requires=` sobre otras unidades; las `.network` y `.volume` de
  Quadlet generan dependencias implícitas. Para dependencias de red externa,
  `Wants=network-online.target`. **La semántica de dependencias de systemd es de
  `linux-administration-standards`** — no la reinventes aquí.
- **Recursos por cgroup**: `MemoryMax=`, `CPUQuota=`, `IOWeight=` en la sección `[Service]` de la
  unidad Quadlet. **Todo servicio lleva al menos un límite de memoria**: sin él, un contenedor
  con fuga se lleva el host por delante. Podman 6 expone `OOMKilled` en el evento `died` — útil
  para distinguir "lo mató el kernel" de "se cayó solo".
- **Logs**: driver `journald` (default). Los logs del contenedor van al journal del host y de ahí
  al agregador. Retención y límites, en `linux-administration-standards`. **Prohibido** el driver
  `json-file` en un host con systemd: duplica almacenamiento y esquiva la rotación del journal.
- **Secretos**: el orden de preferencia es
  1. **`LoadCredential=`/`systemd-creds`** en la unidad, montando la credencial en un tmpfs solo
     para ese servicio;
  2. **`podman secret`** (`Secret=` en Quadlet) montado como fichero;
  3. — y nada más. **`Environment=` con el secreto en claro está prohibido**: acaba en
     `systemctl show`, en `podman inspect` y en el journal. El origen del secreto y su rotación
     son de `secrets-management-standards`.
- **Sandboxing de la unidad**: la unidad generada admite las directivas de endurecimiento de
  systemd. Aplicar el criterio de `linux-administration-standards` y medir con
  `systemd-analyze security <unit>`.

### 3.8 Docker frente a Podman

- **En un host con systemd, la respuesta por defecto es Podman.** Docker mete un daemon con un
  socket que es equivalente a root, un modelo de arranque paralelo al de systemd, y contenedores
  que no son unidades. Podman produce servicios que se operan con `systemctl`.
- **Compatibilidad de CLI**: alta pero **no total**. Un alias `docker=podman` es cómodo en
  interactivo y **una fuente de sorpresas en scripts**. En automatización se escribe `podman`.
- **`podman.socket`** expone una API compatible con Docker; con `DOCKER_HOST` apuntando ahí,
  `docker compose` v2 funciona para muchos flujos. Límites conocidos:
  - `docker compose build` **envía el contexto entero al socket** — pierdes el modelo sin daemon.
    Construye en CI.
  - Cobertura parcial de la API: funciones de Compose recientes pueden no existir.
  - **Un socket TCP (`podman system service tcp://…`) no tiene autenticación**. Prohibido
    exponerlo; si hace falta remoto, SSH.
  - El socket rootful (`/run/podman/podman.sock`) es **equivalente a root en el host**: los
    permisos de ese socket son un control de seguridad de primer orden.
- **`podman compose`** es un envoltorio que delega en un proveedor externo: **`docker-compose`
  tiene precedencia** si está instalado, si no `podman-compose`. Se fija explícitamente con
  `compose_providers` en `containers.conf` o `PODMAN_COMPOSE_PROVIDER` — **fíjalo**, no dejes que
  dependa de qué paquete esté instalado en cada host.
- **`podman-compose`** (v1.6.0, jun-2026): reimplementación en Python, sin daemon, orientada a
  rootless. Huecos frente a Compose: secretos externos y desde entorno, `configs`, matices de red.
  **Criterio: no es la base de un stack de producción.**

### 3.9 Migraciones

**De `docker-compose` a Quadlet** — un servicio por `.container`, y:

| En Compose | En Quadlet |
|---|---|
| `services:` (cada uno) | Un fichero `.container` |
| `networks:` | Un `.network` (obligatorio para DNS por nombre) |
| `volumes:` | Un `.volume` |
| `depends_on` | `After=`/`Requires=` — y **`depends_on` de Compose no espera a que el servicio esté listo**; `Notify=` sí. La migración es una **mejora**, no una traducción |
| `restart: always` | `Restart=always` en `[Service]` — pero **`on-failure` es mejor default** |
| `healthcheck` | `HealthCmd=` + **`HealthOnFailure=`** |
| `env_file` con secretos | `LoadCredential=`/`Secret=`. **No se traduce tal cual** |
| `ports: "8080:8080"` | `PublishPort=127.0.0.1:8080:8080` — con IP explícita |

Procedimiento: `podlet` genera el borrador → revisión a mano de red, secretos, límites y
etiquetado SELinux → **prueba de arranque en frío** (§4). **No se migra un Compose upstream que
cambia cada release**: ahí se consume el Compose original vía socket, o se acepta la deuda de
traducirlo en cada versión (y se anota quién lo hace).

**De Quadlet a Kubernetes** — cuándo y cómo:
- El disparador es de §2.1 (programación, escalado, supervivencia a la caída del host), **no**
  "hemos crecido".
- `podman kube generate` produce un YAML de partida. **Es un punto de partida, no un manifiesto
  de producción**: le faltan `securityContext`, probes, recursos, políticas de red y todo lo que
  exige `kubernetes-standards`.
- El trabajo real de la migración no son los manifiestos: es **el estado**. Los volúmenes locales
  se convierten en almacenamiento de red o en un servicio gestionado, y eso se decide antes de
  escribir el primer YAML.

## 4. Calidad y gates

En orden de coste creciente. **Los tres primeros rompen el despliegue.**

1. **Lint de la unidad**: `/usr/libexec/podman/quadlet -dryrun` (con `-user` si aplica) produce
   una unidad y **no emite avisos**. Un Quadlet inválido no genera nada y falla en silencio.
2. **Referencias cualificadas y firma**: ninguna imagen sin registry explícito, ninguna con
   `:latest`, `policy.json` no es `insecureAcceptAnything` para los registries propios.
3. **Sin secretos en claro**: `grep` de la unidad contra `Environment=`/`PodmanArgs=` con
   material sensible. Un `gitleaks` sobre el repo de unidades (`secrets-management-standards`).
4. **GATE PRINCIPAL — arranque en frío tras reinicio.** No `systemctl start`: **`reboot`**, y el
   servicio queda activo y sano sin intervención. Es la única prueba que vale, y la que atrapa:
   - falta de `loginctl enable-linger` en unidades de usuario;
   - dependencias de red mal declaradas;
   - montajes que aún no existen al arrancar la unidad;
   - imágenes que ya no están en el almacenamiento local y un registry inalcanzable en el boot;
   - permisos de volumen que solo funcionaban porque alguien hizo `chown` a mano.
5. **Health check que falla y recupera**: se induce el fallo dentro del contenedor (parar el
   proceso, saturar la dependencia) y se comprueba que la unidad pasa a `unhealthy`, que
   `HealthOnFailure=` actúa y que systemd la levanta. Un health check nunca probado en fallo
   **no está probado**.
6. **Actualización automatizada que no rompe**: en un entorno de pruebas, se publica una imagen
   deliberadamente rota con el tag que vigila auto-update y se comprueba que **el rollback
   ocurre** y el servicio queda sirviendo con la versión anterior. Si no ocurre, casi siempre
   falta `--sdnotify=container`.
7. **Restore del volumen**: se restaura una copia en un host limpio y el servicio arranca con
   ella. La mecánica es de `backup-recovery-standards`; **que se haya hecho al menos una vez por
   servicio es gate de aquí**.
8. **Prueba de no-privilegio**: el servicio corre rootless salvo justificación escrita; se
   comprueba con `podman info` / `systemctl --user status` que efectivamente es así.

## 5. Seguridad del stack

- **Versión mínima ≥ 5.8.4 / ≥ 6.0.0** por CVE-2026-57231 (§2). No negociable en hosts que
  ejecuten imágenes de terceros.
- **Cadena de suministro**: imagen cualificada + digest o tag verificado por firma + `policy.json`
  que exige esa firma. Sin el último eslabón, los dos primeros son teatro.
- **`unqualified-search-registries` vacío** en servidores. Es el vector de *typosquatting* de
  imágenes.
- **Socket de Podman**: el rootful equivale a root. No se expone por TCP, no se monta dentro de
  un contenedor (eso es territorio de `container-runtime-security-standards`, y allí está
  prohibido por la misma razón).
- **Rootless como reducción de daño, no como aislamiento**: un escape desde rootless te deja como
  el usuario del servicio, no como root — es mucho, pero **no es una frontera de seguridad
  completa**. El modelo de aislamiento y sus límites reales los fija
  `container-runtime-security-standards`.
- **Podman Desktop**: si está en el parque, **≥ 1.26.2** por CVE-2026-34045 (servidor HTTP no
  autenticado: DoS y filtrado de información). No pinta en servidores, pero suele estar en los
  portátiles del equipo.
- **`podman kube play`** con YAML de origen no confiable: vetado (GHSA-wp3j-xq48-xpjw).
- **Actualizaciones del propio Podman**: cadencia con el resto del SO (`rhel-fedora-standards` /
  `linux-administration-standards`), y triaje de CVE por `vulnerability-management-standards`.
- **Migración a Podman 6**: hacer copia del almacenamiento antes del primer arranque — la
  migración BoltDB → SQLite es automática y **no está diseñada para volver atrás**.

## 6. Rendimiento y operabilidad

- **Métricas**: `podman` expone estadísticas por contenedor; en un host con systemd, la vía
  natural es el `cadvisor`/exportador que ya use la flota más las métricas de cgroup de la unidad.
  El diseño de qué se alerta es de `observability-standards`. **Lo que esta skill exige que se
  vigile**: unidad `active`, estado del health check, reinicios en ventana, OOM kills, edad de la
  imagen en ejecución frente al tag del registry, y **fallos de `podman-auto-update.service`**
  (un auto-update que lleva semanas fallando en silencio es el peor de los dos mundos).
- **Arranque**: `systemd-analyze blame` incluye tus unidades. Un `.container` que tira una imagen
  grande del registry en cada boot es un boot lento y frágil — usa `.image` como dependencia o
  conserva la imagen local.
- **Parada limpia**: `StopTimeout=`/`TimeoutStopSec=` coherentes con lo que tarda la aplicación
  en cerrar. El default corta a lo bruto y corrompe datos en servicios con estado.
- **Capacidad**: límites de cgroup por servicio **y** margen en el host. El almacenamiento de
  imágenes crece sin control sin `prune` en timer.
- **Modo de fallo aceptado por escrito**: el host es el SPOF. Si el servicio no puede tolerarlo,
  la conversación es la de §2.1, no la de afinar la unidad.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Podman sigue el ciclo de la distribución; línea mayor nueva **no entra en producción hasta que
  la empaqueta la distro** y se ha probado en un host de pruebas. Podman 6 es una migración, no
  una actualización: rompe cgroups v1, CNI, iptables, slirp4netns y la base de datos.
- Revisión semestral de: unidades que aún vengan de `podman generate systemd`, imágenes con tag
  móvil, servicios rootful, y volúmenes fuera del plan de respaldo.
- Toda unidad tiene **dueño** en el README del repo. Sin dueño, se apaga.

**PROHIBIDO**
- ❌ `podman generate systemd` en nada nuevo (deprecado y congelado). Migrar lo existente.
- ❌ `:latest` o cualquier tag móvil sin firma verificada en un servicio.
- ❌ `unqualified-search-registries` no vacío en un servidor; referencias de imagen sin registry.
- ❌ `policy.json` en `insecureAcceptAnything` para registries propios; `insecure = true`.
- ❌ Secretos en `Environment=` o en la línea de comando del contenedor.
- ❌ `PublishPort=` sin IP de escucha explícita.
- ❌ Bind mount sin `:z`/`:Z` en host con SELinux; y **jamás** "desactivar SELinux para que
  arranque".
- ❌ Servicio rootful sin justificación escrita; `--privileged` (y su detalle, vetado en
  `container-runtime-security-standards`).
- ❌ Unidad de usuario sin `loginctl enable-linger`.
- ❌ `.build` de Quadlet en producción: la imagen se construye en CI, no en el host que la ejecuta.
- ❌ Auto-update sin `--sdnotify=container` (rollback ciego) o contra un registry sin firma
  verificada.
- ❌ Driver de log `json-file` en un host con journald.
- ❌ Exponer el socket de Podman por TCP, o montarlo dentro de un contenedor.
- ❌ Alias `docker=podman` dentro de scripts y automatización.
- ❌ `podman-compose` como base de un stack de producción.
- ❌ Editar a mano la unidad `.service` generada por Quadlet, o versionarla.
- ❌ Contenedor sin límite de memoria por cgroup.
- ❌ Volúmenes anónimos (`Mount=` sin origen) en un servicio con estado.
- ❌ **Reimplementar un orquestador con scripts** (arranque cruzado por SSH, "failover" casero,
  registro de servicios en un fichero). Si hace falta programación, se usa un programador.
- ❌ **Poner Pacemaker a gestionar contenedores de un host para "darles HA"**: complejidad de
  cluster sin ninguna de sus garantías. Ver `ha-clustering-standards`: la respuesta es un
  orquestador, un balanceador delante de dos instancias con el estado fuera, o aceptar el
  downtime por escrito.
- ❌ Kubernetes para cuatro servicios en un host "porque escalará algún día".

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real:

1. **Versión de Podman** en la distro destino (no la upstream) y su relación con la **mínima de
   seguridad ≥ 5.8.4 / ≥ 6.0.0** (CVE-2026-57231, GHSA-4hq8-gpf5-8p68). Fuente:
   `api.github.com/repositories/109145553/releases` y el advisory, no un resumen.
2. **Versiones acompañantes exigidas** por la línea de Podman instalada (Buildah, Skopeo,
   netavark, aardvark-dns, `container-libs/common`). Cambian con cada mayor.
3. **Lista vigente de tipos de unidad Quadlet** y de **rutas de búsqueda** en
   `podman-systemd.unit(5)` de **la versión instalada**: ambas han crecido y siguen creciendo.
4. **Estado de `podman generate systemd`**: hoy deprecado y congelado, **no eliminado**.
   Comprobar si alguna línea nueva lo retira.
5. **Default de red rootless** en la versión instalada y en la distro: pasta desde Podman 5.0
   upstream y RHEL/OL 9.5; **slirp4netns eliminado en Podman 6**.
6. **Modos y comportamiento de `podman auto-update`** (`registry`/`local`, rollback, timer) en el
   manual de la versión instalada.
7. **CVE abiertos** de `podman`, `crun`, `netavark`, `aardvark-dns`, `passt/pasta`, `buildah` y
   `skopeo`, y de las imágenes base que ejecutes.
8. **Incidentes de cadena de suministro** en el ecosistema de contenedores antes de fijar una
   herramienta nueva o una acción de CI (precedente reciente en el catálogo: el compromiso de
   `trivy-action` de marzo de 2026 documentado en `kubernetes-standards`).
9. **Movimiento a CNCF**: repositorio en `podman-container-tools`, import path
   `go.podman.io/podman/v6`. Revisar URLs fijadas en automatizaciones.

**Huecos declarados — NO rellenar de memoria, verificar antes de usar:**
- **Comportamiento exacto de `podman auto-update` frente a referencias fijadas por digest** (se
  asume aquí que no actualiza, por definición del digest, pero **no se ha leído la frase textual
  del manual**). Verificar antes de diseñar una política mixta digest/tag.
- **Disponibilidad y semántica exacta de `Notify=healthy`** en la versión instalada: se menciona
  como alternativa a sdnotify pero **no se ha verificado por web** en esta revisión.
- **Versión de Podman empaquetada en RHEL 10 / CentOS Stream 10, Debian 13 y Ubuntu 26.04 LTS**:
  no verificada. Determina si la mínima de seguridad se alcanza con el paquete de la distro o
  hace falta un módulo/backport.
- **Estado de mantenimiento real de `podman-compose`** más allá de la fecha de su v1.6.0
  (2026-06-03): no se ha evaluado cadencia ni tamaño del equipo.
- **`Pesto` / `rootless_port_forwarder=pasta`**: aparece en las notas de Podman 6.0.1 como
  herramienta de reenvío de puertos rootless con un bug de limpieza de reglas corregido. **No se
  ha verificado qué es, si es default ni sus implicaciones**. No dependas de ello sin leer el
  manual de tu versión.
- **Soporte y estado del tipo de unidad `.artifact`**: listado en el manual, pero **su madurez no
  se ha verificado**.
- **CVE específicos de `crun` en 2026**: la búsqueda no devolvió ninguno, pero **no se consultó
  el advisory feed del repositorio directamente**. Confirmar antes de fijar la versión mínima del
  runtime.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
