---
name: file-servers-standards
description: Classic file-sharing servers — the protocol that exposes a directory tree to other machines, and its blast radius. Use when working with Samba (smb.conf, testparm, smbcontrol, smbstatus, smbd/nmbd/winbindd, net ads join, net usershare, "server min protocol", "server smb encrypt", "vfs objects", vfs_shadow_copy2, vfs_full_audit, vfs_worm, vfs_recycle, vfs_acl_xattr, vfs_fruit, idmap config, wbinfo, pdbedit, "valid users", "force group", "veto files", msdfs root and msdfs proxy), ksmbd (ksmbd.conf, ksmbd.mountd, ksmbd.addshare) and whether an in-kernel SMB server belongs in production, NFS exports (/etc/exports, exports.d, exportfs -ra, /var/lib/nfs/etab, rpc.mountd, rpc.gssd, nfsdcltrack, nfs.conf, fsid=0 and the v4 pseudo-root, no_root_squash, all_squash, anonuid/anongid, subtree_check, sec=sys/krb5/krb5i/krb5p, nfsvers=3 vs 4.1 vs 4.2, nconnect, xprtsec=tls and xprtsec=mtls, tlshd and ktls-utils per RFC 9289), POSIX ACLs versus NT ACLs (getfacl/setfacl, acl_xattr, security.NTACL), project or user quotas on a share, DFS namespaces, SMB signing and encryption enforcement, share-level auditing, and containing ransomware that arrives through a mapped drive or an NFS mount.
---

# Estándares de servidores de ficheros (SMB/CIFS y NFS)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **protocolo de compartición de ficheros y a su exposición**: qué se publica, con qué
dialecto, autenticado contra qué, cifrado o no, con qué mapeo de identidad y con qué permisos
efectivos; y cómo se audita, se limita y se contiene cuando el cliente es hostil.

**Principio rector: un servidor de ficheros es un ejecutor remoto de escrituras arbitrarias sobre
un árbol de directorios, con la identidad del cliente.** No es "un disco en la red". El ransomware
que cifra un recurso compartido no explota nada: usa el recurso como fue diseñado.

Disparadores: los del frontmatter. **Si la respuesta se escribe en `smb.conf` o en `/etc/exports`,
es de aquí.**

**No aplica**: ver `linux-storage-standards` (**el bloque y el filesystem POSIX debajo**, y **el
lado cliente de NFS e iSCSI**. **Un `target` iSCSI no es compartición de ficheros: es un disco
crudo con un solo dueño** — si la pregunta lleva `targetcli`, `LUN` o `initiator`, es de allí),
`zfs-standards` (pool, dataset, snapshots y `zfs send`; **el snapshot que alimenta las *Previous
Versions* se crea allí y se publica aquí** vía `shadow_copy2`), `object-storage-standards` (S3:
**si necesitas semántica POSIX es de aquí; si no la necesitas, no montes un recurso compartido**),
`windows-server-ad-standards` (**el directorio y Kerberos/NTLM como protocolos del dominio**; aquí
solo el **miembro de dominio**: `net ads join`, `winbindd`, `idmap` y qué SID acaba siendo qué
UID), `identity-access-management-standards` (federación y ciclo de vida; aquí el mapeo
identidad→permiso efectivo), `backup-recovery-standards` (**la copia** — **una *shadow copy*
publicada por `shadow_copy2` no es un backup**, §5), `bcdr-standards` (RTO/RPO y orden de
recuperación), `cryptography-pki-standards` (CA y custodia de la clave que usa `tlshd`),
`networking-standards`, `firewall-policy-standards` y `dns-standards` (quién llega a 445/2049, y el
`A`/`PTR`/SPN que Kerberos necesita para no caer a NTLM), `linux-hardening-standards` (baseline
CIS), `selinux-standards` (`samba_export_all_rw`, `nfs_export_all_rw` y los booleanos que la gente
desactiva para "que funcione"), `observability-standards` (retención de los eventos que aquí se
generan), `detection-engineering-standards` (la regla que detecta el cifrado masivo; aquí el evento
que la alimenta), `incident-response-forensics-standards` (el caso vivo),
`web-app-servers-standards` (otro servicio expuesto, otro criterio).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada |
|---|---|---|
| Implementación SMB | **Samba en espacio de usuario**, salvo caso medido que lo justifique | Serie estable a ago-2026: **4.24** (4.24.5, 28-jul-2026); **4.23** en mantenimiento (4.23.11, 3-ago-2026); **4.22** solo seguridad; **4.21 EOL desde el 12-sep-2025**. Ciclo declarado: ~6 meses *current* + 6 mantenimiento + 6 solo seguridad |
| Licencia de Samba | **GPLv3** | Leído en crudo: `COPYING` = *"GNU GENERAL PUBLIC LICENSE / Version 3, 29 June 2007"* |
| ksmbd (SMB en el kernel) | **Vetado en cualquier cosa expuesta a clientes no confiables** | Su ventaja es rendimiento; su coste es que **un fallo suyo es un fallo del kernel, no de un proceso**. 2026 acumula CVEs remotos serios (p. ej. **CVE-2026-31704**, desbordamiento en el manejo de DACL con explotación pública reportada; **CVE-2026-23226**, UAF por *lock* ausente). Si se usa: red segmentada, parcheo de kernel disciplinado y 445 cerrado en el borde |
| Dialecto SMB mínimo | **SMB3 (`SMB3_11`)**; SMB2_02 solo si un cliente lo obliga. **SMB1/NT1/CIFS vetado sin excepción** | Samba fija `client min protocol`/`server min protocol = SMB2_02` **por defecto desde 4.11**, con SMB1 "oficialmente *deprecated*". El defecto ya excluye SMB1: **subirlo a SMB3 es tuyo**, y reactivar SMB1 es un cambio explícito de configuración — si alguien lo hizo, es un hallazgo |
| Firma SMB | **Obligatoria** en servidor y cliente | Windows 11 24H2 y Windows Server 2025 la exigen **por defecto** (24H2 Pro/Enterprise/Education entrante y saliente; Server 2025 saliente; Home no). **Consecuencia operativa: rompe el acceso *guest* y los NAS de terceros que no firman** — eso es la señal, no el problema |
| Cifrado SMB | **Exigido** (`server smb encrypt = required`) fuera de la LAN de servidores | La firma protege integridad, **no confidencialidad**. Si el dato es personal o regulado, se exige cifrado aunque la red sea "interna" |
| SMB sobre QUIC | Alternativa real a publicar 445, **no sustituto de una VPN por defecto** | En Windows Server 2025 está en **todas** las ediciones (en 2022 era solo Azure Edition). En Samba, **4.23** introdujo SMB3 sobre QUIC, y en Linux el **servidor requiere un módulo `quic.ko` fuera del árbol** — eso lo descalifica como base de producción hasta que esté en el kernel (§8) |
| Versión NFS | **NFSv4.2**; v4.1 como suelo | v3 solo para clientes que no soportan v4, con fecha de retirada. v3 **no tiene mecanismo de identidad**: `AUTH_SYS` es un UID sin prueba |
| Seguridad NFS | **`sec=krb5p`** cuando hay dato sensible; **`sec=sys` nunca cruza un límite de confianza** | `krb5` autentica, `krb5i` añade integridad, `krb5p` añade confidencialidad. Coste de CPU creciente: mídelo, no lo supongas |
| NFS sobre TLS (RFC 9289) | Opción cuando Kerberos no es viable; **no sustituye la autenticación de usuario** | `xprtsec=tls` / `xprtsec=mtls` en montaje y en `exports(5)`; kTLS en kernel (servidor desde 6.4; cliente necesita `CONFIG_NET_HANDSHAKE=y`) + `tlshd` de **ktls-utils** con `/etc/tlshd.conf` en ambos extremos. **No soporta PSK.** Protege el transporte; con `sec=sys` detrás, la identidad sigue sin probarse |
| `no_root_squash` | ❌ **Veto duro** | Concede root del servidor a root del cliente. Si "hace falta", el diseño está mal: usa `anonuid`/`anongid` o un export dedicado |
| ACL | **NT ACL sobre `acl_xattr`** en recursos SMB de dominio; POSIX ACL en recursos solo-UNIX | No se mezclan en el mismo árbol: el modelo NT tiene herencia y denegaciones que POSIX no representa, y "casi equivalente" produce permisos efectivos que nadie predice |
| Cuotas | **De filesystem/proyecto, siempre** | Un recurso compartido sin cuota es un DoS que se dispara solo |

## 3. Estructura y convenciones

- **Un recurso = un propósito = un grupo.** `valid users = @grupo`, nunca usuarios sueltos ni
  `@Domain Users`. El permiso se administra en el directorio, no en `smb.conf`.
- **La ACL del filesystem manda; la de `smb.conf` es un tope, no el modelo.** Diseña la ACL en el
  árbol y usa los parámetros del recurso solo para *restringir* (`read only`, `valid users`).
  Duplicar el modelo en dos sitios garantiza que divergen.
- **`net usershare`**: permite a usuarios no-root publicar recursos. **Desactivado**
  (`usershare max shares = 0`) salvo caso de uso escrito; es publicación de datos sin revisión.
- **`vfs objects`: el orden importa** y cada módulo cuesta latencia por operación. Conjunto base:
  `acl_xattr` (ACL NT), `shadow_copy2` (versiones anteriores desde snapshots ZFS/LVM),
  `full_audit` (§5), `recycle` solo si el negocio lo pide (**no es papelera de seguridad: el
  ransomware la vacía**), y `fruit`+`streams_xattr` **solo** si hay clientes macOS.
- **`vfs_worm` no es inmutabilidad.** Verificado: **CVE-2026-2340** — el módulo WORM se saltaba
  renombrando un fichero nuevo sobre el protegido. La inmutabilidad real vive en el repositorio de
  copias (Object Lock / *append-only*), no en un módulo VFS.
- **NFSv4: `fsid=0` define la pseudo-raíz** y todo lo demás cuelga de ahí. `nohide` es de v3; v4 se
  comporta siempre como si estuviera activo. **Exporta el punto exacto, no un padre "por comodidad",
  y nunca a `*` como cliente.**
- **`/etc/exports.d/` con un fichero por consumidor**, en control de versiones, aplicado con
  `exportfs -ra`. Verifica el resultado en `/var/lib/nfs/etab`, **no en el fichero fuente**: es
  donde se ve lo que el servidor aplica de verdad.
- **DFS (`msdfs root`)** desacopla la ruta lógica del servidor físico: es lo que permite retirar un
  servidor sin tocar 4.000 unidades de red mapeadas. Se decide **antes** de la primera migración.
- **Mapeo de identidad (`idmap config`)**: rango explícito y **documentado por dominio**, backend
  determinista (`rid`, `ad` o `autorid`) — nunca `tdb` en más de un servidor. Dos servidores que
  mapean el mismo SID a UIDs distintos producen permisos incoherentes que solo se ven al restaurar.

## 4. Calidad, cambios y pruebas

- **Gates antes de recargar**: `testparm -s` sin avisos y `exportfs -ra` sin errores son
  obligatorios, no opcionales; más una prueba de acceso **con una cuenta sin privilegios** desde un
  cliente real — que monte como admin no prueba nada.
- **Prueba de permiso negativo, siempre**: comprobar que quien *no* debe leer, no lee. Casi todas
  las fugas por recurso compartido pasan el test positivo.
- **Configuración versionada y desplegada por IaC** (`iac-standards`): editar `smb.conf` a mano en
  producción no es reversible.
- **Comprobación periódica de deriva**: dialecto negociado real (`smbstatus`), firma y cifrado
  efectivos por sesión, exports vivos vs. declarados, y **recursos huérfanos** sin dueño
  identificable — que se retiran, no se heredan.

## 5. Seguridad del stack

- **Superficie**: 445/TCP (SMB), 2049/TCP (NFS), 139/137/138 (NetBIOS — **apagados**), y el
  *portmapper* 111 en v3. **Ninguno cruza un perímetro sin control adicional.**
- **Autenticación**: Kerberos. NTLM se bloquea o se restringe explícitamente; si todo cae a NTLM,
  la causa casi siempre es DNS/SPN (`dns-standards`), y arreglarla es parte del trabajo.
- **Anónimo/guest: prohibido.** `map to guest = never`. Y ojo: exigir firma **ya deshabilita el
  acceso guest** — si alguien "arregló" una incidencia desactivando la firma, deshizo dos controles.
- **Auditoría de acceso obligatoria** en recursos con dato sensible: `vfs_full_audit` con las
  operaciones que importan (`pwrite`, `rename`, `unlink`, `mkdir`, `set_nt_acl`), enviada **fuera
  del servidor** (`observability-standards`). Sin ella el forense no puede responder "quién borró
  esto" y la detección de cifrado masivo no tiene señal.
- **Contención de ransomware — es un problema de *permisos*, no de antivirus**:
  1. **Escritura mínima**: el recurso "todos escriben en todo" es la condición que convierte un
     puesto comprometido en una parada de la empresa.
  2. **Ningún recurso da acceso al repositorio de copias**: la credencial de backup no vive en el
     cliente y el repositorio no se monta como unidad de red (`backup-recovery-standards`).
  3. **Snapshots del filesystem** como recuperación de primer nivel, con retención propia y **fuera
     del alcance de la credencial del cliente**. `shadow_copy2` los publica en solo lectura;
     publicarlos no los protege.
  4. **Señal de detección**: tasa anómala de `rename`/`pwrite` por sesión y entropía de extensiones
     nuevas. La regla es de `detection-engineering-standards`; el evento se genera aquí.
- **Cifrado en tránsito por defecto**: SMB3 cifrado o NFS con `krb5p`/`xprtsec=tls`. "Es la red
  interna" no es un control.
- **Parcheo**: Samba publica CVEs remotos con regularidad y algunos son **RCE sin autenticar**
  (verificado en 4.23.8: **CVE-2026-4408** en el servidor SAMR con `%u` en el script de
  comprobación de contraseña; **CVE-2026-4480** en el subsistema de impresión con `%J`). Corolario:
  **desactiva lo que no usas** —impresión, WINS, AD DC— porque su superficie te alcanza aunque no
  la uses. SLA de parcheo por `vulnerability-management-standards`.
- **Booleanos de SELinux**: `samba_export_all_rw` / `nfs_export_all_rw` desactivan el confinamiento
  del servicio sobre el árbol entero. Activarlos "para que funcione" es un hallazgo, no una
  solución (`selinux-standards`).

## 6. Rendimiento y operabilidad

- **Mide antes de tocar**: el grueso de los "SMB va lento" son latencia de red, antivirus en el
  cliente o metadatos (directorios con decenas de miles de entradas), no parámetros del servidor.
- `nconnect=` en NFS multiplica conexiones TCP por montaje: ayuda con latencia y **no es gratis**
  en el servidor. Fija un valor medido, no el máximo.
- **Cifrado y `krb5p` cuestan CPU**: no es motivo para quitarlos; es motivo para dimensionar.
- **Vigila**: sesiones y dialecto por sesión, profundidad de cola de `nfsd`, errores de
  autenticación, ocupación y cuota por recurso, latencia por operación de metadatos.
- **Recarga con `smbcontrol`**: reiniciar `smbd` con ficheros abiertos corrompe datos en
  aplicaciones que no reintentan.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: mantente en la serie *current* de Samba o, como mucho, en la de mantenimiento;
  **una serie en "solo seguridad" es un plan de actualización con fecha**, no un estado estable.
- **Todo recurso tiene dueño, propósito y fecha de revisión.** Los servidores de ficheros mueren de
  acumulación: recursos de proyectos cerrados en 2014 con permisos de 2014.

- ❌ **PROHIBIDO habilitar SMB1/NT1/CIFS.** Ni "temporalmente" para un escáner o una máquina
  industrial: se segmenta ese dispositivo, no se degrada el servidor.
- ❌ **PROHIBIDO `no_root_squash`.** Y exportar por NFS a `*` o a una subred sin justificación.
- ❌ Desactivar la firma SMB para "arreglar" un cliente incompatible: se arregla o se aísla.
- ❌ Acceso *guest*/anónimo de escritura. Y de lectura, solo con dato explícitamente público.
- ❌ Publicar 445 o 2049 hacia Internet.
- ❌ Tratar `vfs_recycle`, `vfs_worm` o las *shadow copies* publicadas como copia de seguridad o
  como inmutabilidad (§5, CVE-2026-2340).
- ❌ ksmbd expuesto a clientes no confiables, o con parcheo de kernel no garantizado.
- ❌ Mezclar POSIX ACL y NT ACL en el mismo árbol. ❌ Recursos sin cuota.
- ❌ `net usershare` habilitado sin caso de uso aprobado.
- ❌ Montar el repositorio de copias como recurso compartido accesible desde puestos.
- ❌ Activar `samba_export_all_rw`/`nfs_export_all_rw` como remedio de un problema de permisos.
- ❌ Dar por buena una configuración porque monta desde una cuenta de administrador (§4).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Serie de Samba vigente y su calendario** en `samba.org/samba/history/` y en la wiki de
   *Release Planning* (a ago-2026: 4.24 *current*, 4.23 mantenimiento, 4.22 solo seguridad, 4.21
   EOL desde 12-sep-2025). **La fuente es samba.org, no un feed de GitHub.**
2. **CVEs de Samba desde tu versión** (las notas de release las listan con descripción; hay RCE sin
   autenticar recientes, §5) y **CVEs de ksmbd en tu kernel** si lo usas.
3. **Estado de SMB3 sobre QUIC en Samba**: si el servidor en Linux sigue exigiendo el módulo
   `quic.ko` fuera del árbol, o si ya está en el kernel. **De eso depende que sea usable.**
4. **Defaults exactos de `smb.conf`** (`server min protocol`, `server smb encrypt`, `map to guest`)
   **en el manpage de tu versión**, no de memoria. **Hueco declarado**: no pude citar verbatim el
   valor por defecto de `server min protocol` en 4.24 —el manpage es demasiado grande para
   extraerlo con garantías—, así que aquí solo se afirma el cambio documentado en las notas de
   **4.11** (`SMB2_02`); confírmalo con `testparm -v`, que es la fuente definitiva.
5. **Política de firma y cifrado SMB del lado Windows** (`learn.microsoft.com`, *SMB security
   hardening*): los defaults cambian por edición y versión, y determinan qué clientes rompen.
6. **NFS sobre TLS**: kernel y `ktls-utils`/`tlshd` mínimos en tu distro, y si tu cabina o tu
   cliente lo soportan (hay incompatibilidades documentadas, p. ej. con NFS sobre RDMA). Y
   **`exports(5)`/`nfs(5)` de tu distro** para el comportamiento exacto de `sec=` y `xprtsec=`:
   hay bugs históricos de opciones que se ignoran en silencio.
7. **Licencias leídas en crudo** (`COPYING` de Samba = GPLv3, verificado).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
