---
name: mail-servers-standards
description: Running your own mail server — the decision first, the daemons second, because deliverability reputation decides the outcome. Use when working with Postfix (main.cf, master.cf, postconf, postqueue, postfix check, mynetworks, smtpd_relay_restrictions, smtpd_recipient_restrictions, transport and virtual maps, milter_default_action), Exim (exim.conf, exim4.conf.template, exim -bt, routers/transports/ACLs), Dovecot (dovecot.conf, conf.d 10-mail.conf and 10-auth.conf, dovecot_config_version, doveadm, dsync, Maildir, mdbox and sdbox, mail_location, quota plugin, Sieve and managesieve), Rspamd (rspamd.conf, local.d, worker-proxy, greylisting, milter headers) or SpamAssassin, an integrated suite (mailcow-dockerized, Mailu, iRedMail with iRedAdmin-Pro, Stalwart), SMTP and its extensions (RFC 5321, STARTTLS, SMTP AUTH, submission on 587 and implicit TLS on 465, port 25 blocked by the cloud provider), IMAP (RFC 9051) versus POP3 retirement, JMAP, mailbox storage format, quotas and mailbox growth, an open relay or a rate limit, a compromised account turning the server into a spam source, backscatter and a secondary MX that cannot validate recipients, IP and PTR reputation, bulk sender requirements from Gmail, Yahoo and Outlook, choosing between a managed outbound relay and a full self-hosted server, or migrating mailboxes between platforms with imapsync.
---

# Estándares de servidores de correo — la decisión pesa más que la configuración

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **decidir, montar y operar** el correo propio: la elección previa entre relé gestionado y
servidor completo, MTA, MDA/almacén, filtrado, protocolos y puertos, TLS, almacenamiento y cuotas,
alta disponibilidad, reputación de salida y migración de buzones.

Disparadores: `main.cf`, `master.cf`, `postconf`, `postqueue`/`mailq`, `exim.conf`, `dovecot.conf`,
`doveadm`, `dsync`, `rspamd.conf`, `local.d`, `sieve`, `imapsync`, `mailcow`, `Mailu`, `iRedMail`,
`Stalwart`, "relé abierto", "puerto 25 bloqueado", "587", "465", "Maildir", "mdbox", "cuota de
buzón", "cola diferida", "backscatter", "MX secundario", "listado en una lista negra".

**Premisa que manda sobre todo lo demás**: **montar correo propio en 2026 casi nunca sale bien, y
el motivo no es técnico sino de reputación de entrega.** Postfix y Dovecot se configuran en una
tarde; lo que no se resuelve en una tarde es que tu correo entre en la bandeja de entrada ajena.
Las tres piezas del muro, verificadas: (1) **el proveedor de nube te bloquea el puerto 25 de
salida** —Azure lo bloquea salvo en suscripciones Enterprise Agreement/MCA-E y recomienda relé
autenticado por 587; Google Cloud lo bloquea "due to the risk of abuse" y su relé de Workspace solo
admite 465 o 587—, así que tu rango de IP ya nace sospechoso; (2) **los grandes receptores fijaron
requisitos duros a quien envía volumen**: desde el **1-feb-2024** Gmail exige a quien manda más de
**5.000 mensajes/día** DMARC, DNS directo e inverso (PTR) válidos, TLS en el transporte, tasa de
spam **por debajo de 0,30 %** y **un clic para darse de baja** (RFC 8058) en correo de marketing —Yahoo
alineó requisitos casi idénticos y el plazo del un-clic fue el **1-jun-2024**—; Microsoft anunció lo
suyo el **2-abr-2025** y empezó a aplicarlo el **5-may-2025** en Outlook.com/Hotmail/Live para dominios
con más de 5.000 mensajes/día, primero desviando a Correo no deseado; (3) **construir reputación
lleva meses y se destruye en horas**. Con eso sobre la mesa, la pregunta correcta no es "¿qué MTA
uso?" sino "**¿por qué no un relé gestionado?**".

**No aplica** — el reparto del catálogo: **`email-security-standards` (Ola 7) posee SPF, DKIM,
DMARC, MTA-STS, TLS-RPT, BIMI, el filtrado antiphishing, el BEC y la política de correo**; aquí solo
**el servidor que los implementa** (dónde vive la clave, qué firma y qué verifica), y **no se
duplica ni un registro**; **`dns-standards` posee los registros** —MX, PTR, TXT y su operación—,
`cryptography-pki-standards` la elección de algoritmo y el certificado, `identity-access-management-standards`
la cuenta, el MFA y la revocación de sesión, y `firewall-policy-standards` con `networking-standards`
el filtrado y la salida. Hacia la operación: `backup-recovery-standards` posee la copia y la
restauración del buzón, `bcdr-standards` el RTO/RPO, `ha-clustering-standards` el clúster,
`observability-standards` métricas y paneles, `incident-management-standards` e
`incident-response-forensics-standards` el incidente y el forense del buzón comprometido,
`vulnerability-management-standards` el CVE, `privacy-engineering-standards` el dato personal en
registros y buzones, y `grc-compliance-standards` la retención legal. El sistema debajo es de
`linux-administration-standards`, `rhel-fedora-standards` y `linux-hardening-standards`;
`kubernetes-standards` si va en contenedor, `iac-standards`/`cicd-standards` cómo llega la
configuración, y `onprem-standards` es el paraguas (`homelab-standards` para el laboratorio). Sus
hermanas de tanda: **`web-app-servers-standards` posee el webmail y los paneles** (SOGo, Roundcube,
iRedAdmin son aplicaciones web, no correo) y `file-servers-standards` es otro servicio.

## 2. La decisión previa, y solo después las piezas

| Situación | Decisión |
|---|---|
| Correo corporativo general, sin requisito de soberanía | **Buzón gestionado** (Google Workspace, Microsoft 365, proveedor europeo). No es rendirse: es no gastar el presupuesto en reputación |
| Aplicación que envía notificaciones, facturas o avisos | **Relé SMTP gestionado de salida** (autenticado por 587). Tu aplicación no necesita un MTA propio, necesita entregar |
| Requisito legal o contractual de que el dato no salga, o volumen que hace impagable el relé | **Servidor propio completo**, con presupuesto explícito de operación, vigilancia de reputación y guardia |
| Buzones propios pero entrega poco fiable | **Híbrido**: recepción y almacén propios, **salida por relé gestionado**. Es la opción más infravalorada del dominio |
| Laboratorio, aprendizaje, un dominio sin tráfico | Servidor propio, asumiendo que la entrega a los grandes será irregular |

**Criterio honesto**: soberanía del dato, coste a volumen alto y requisito legal justifican el
servidor propio. "Ahorrar", "control" y "no me fío de la nube" **no** justifican por sí solos el
coste real: guardia, parcheo, vigilancia de listas negras y respuesta a una cuenta comprometida.

## 3. Componentes, versiones y licencias

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Recomendado | Datos verificados |
|---|---|---|
| MTA | **Postfix** | `3.11.5` (6-jul-2026); ramas heredadas mantenidas (3.10.x, 3.9.x, 3.8.x) y parches puntuales incluso para 3.5–3.7. **Licencia doble**: `LICENSE` dice literalmente *"dual-licensed under both the Eclipse Public License version 2.0 and the IBM Public License version 1.0"* — **no es GPL ni BSD** |
| MTA alternativo | **Exim** solo si ya lo dominas o lo trae tu distro (Debian) | `4.99.5`, publicación de seguridad. **`LICENCE`** (grafía británica, no `LICENSE`) es GPL-2; el `NOTICE` del tarball declara `SPDX-License-Identifier: GPL-2.0-or-later` con excepción explícita para enlazar con OpenSSL. **El repositorio de GitHub está ARCHIVADO** (último empuje dic-2025): el proyecto vive en `exim.org` y en su Forgejo propio, y numera sus avisos como **GCVE**, no CVE. Un 404 en GitHub no es abandono |
| MDA / almacén | **Dovecot CE 2.4.x** (último tarball publicado: `2.4.4`) | `2.4.0` fue la primera mayor tras ~7 años. **Ciclo de vida oficial, literal**: *"All Dovecot versions before 2.3 are now fully EOL"*, para 2.3 *"we will provide critical security bug fixes"* y *"Dovecot CE 2.4.x is the current main release"*. **No es actualización en caliente**: la configuración 2.3 no vale, `dovecot_config_version` pasa a ser obligatorio y hay conversor oficial en `dovecot.org/upgrader/`. **Licencia mixta**: MIT en `src/lib`, `src/auth` y `src/lib-sql`; **LGPL-2.1 el resto**. La versión comercial **OX Dovecot Pro se numera 3.x** y tiene política de fin de vida propia: no compares números |
| Filtrado antispam | **Rspamd** | `4.1.4` (29-jul-2026), ritmo alto. `LICENSE.md` en crudo: **Apache-2.0** |
| Filtrado alternativo | **SpamAssassin** solo por integración heredada | Apache-2.0, repositorio activo pero **última publicación `4.0.2` de 27-ago-2025**: cadencia lenta frente a Rspamd |
| Suite integrada | **mailcow-dockerized** si quieres una pila montada | **GPL-3.0** (`LICENSE` en crudo); versionado por fecha (`2026-07a`); modelo comercial = **"Stay Awesome License"** de pago opcional (apoyo/soporte), el producto no se recorta |
| Suite integrada | **Mailu** para despliegue mínimo | **MIT** (`LICENSE.md` en crudo); la línea estable sigue llamándose **`2024.06.x`** y se parchea (`2024.06.57`, 26-jul-2026): activo, pero **el nombre de la rama no indica la fecha del parche** |
| Suite integrada | **iRedMail** en instalación sobre SO | **GPLv3** el instalador; modelo comercial = **iRedAdmin-Pro propietario** con licencia anual (ediciones SQL y LDAP) **más** un contrato aparte de actualización — el panel de pago **no incluye soporte del servidor** |
| Servidor todo-en-uno moderno | **Stalwart** solo con criterio: **sigue en `0.x`** (`v0.16.16`, 2-ago-2026) | **Doble licencia**: `LICENSES/AGPL-3.0-only.txt` y `LICENSES/LicenseRef-SEL.txt`; la SELv2 es propietaria y define *Subscription* como *"paid access to the Software… billed on a monthly or annual basis"*. **AGPL + edición Enterprise de pago**: verifica qué función queda en cada lado antes de depender de ella |
| Migración de buzones | **imapsync** (`imapsync-2.314`) | Licencia **"NO LIMIT PUBLIC LICENSE"**, texto propio: *"0 No limits to do anything with this work and this license. 1 GOTO 0"*. **No es GPL**; el autor vende binarios y soporte |

**Separación de responsabilidades**: MTA (recibe, encola, entrega), MDA/almacén (entrega local,
IMAP, cuota, Sieve), filtro (milter/proxy antes de aceptar) y autenticación (base de identidad).
Mantenlos separados aunque corran en la misma máquina: **el filtro nunca decide la entrega final y
el almacén nunca habla con el exterior**.

## 4. Protocolos, puertos y TLS

**RFC verificados uno a uno contra `rfc-editor.org`** (y varias suposiciones habituales son
falsas):

- **SMTP: RFC 5321** — estado **DRAFT STANDARD**, oct-2008, **no obsoleto**, actualizado por
  RFC 7504. Formato de mensaje: **RFC 5322** (Draft Standard, actualizado por RFC 6854).
- **STARTTLS en SMTP: RFC 3207** (Proposed Standard), actualizado por RFC 7817 (verificación de
  identidad del servidor TLS en protocolos de correo).
- **Submission: RFC 6409 es INTERNET STANDARD** —no "solo Proposed"—, actualizado por **RFC 8314**
  (*"Cleartext Considered Obsolete"*), a su vez actualizado por **RFC 8997**, que **deprecia TLS 1.1**
  para envío y acceso.
- **IMAP4rev2: RFC 9051** (Proposed Standard, ago-2021) **obsoleta RFC 3501**.
- **POP3: RFC 1939 es INTERNET STANDARD y NO está obsoleto.** Retirarlo es **decisión de producto,
  no del IETF**: hazlo porque no soporta estado compartido entre dispositivos, porque "descargar y
  borrar" convierte al cliente en el único poseedor del correo y arruina el respaldo, y porque su
  base instalada es la que más sigue anclada a autenticación antigua. **Apágalo por defecto y
  actívalo por excepción documentada.**
- **JMAP: RFC 8620** (núcleo, jul-2019, actualizado por RFC 9404 y RFC 9670) y **RFC 8621** (correo,
  ago-2019). Estado real: implementado por Fastmail, Cyrus, Stalwart y Apache James; **Dovecot no lo
  implementa**; el cliente mayoritario empieza ahora. **Criterio: JMAP no sustituye a IMAP en una
  decisión de infraestructura de 2026**; vigílalo, no apuestes el diseño.

**Puertos**: 25 solo entre MTA (nunca para clientes y **nunca con AUTH en claro**); **587**
submission con STARTTLS obligatorio y **465** submission con TLS implícito —RFC 8314 empuja al
implícito—; 143/993 IMAP; 110/995 POP3 si sigue vivo. **TLS obligatorio en todo**: en submission y
acceso no se negocia; entre MTA es oportunista por diseño de SMTP, y **quien lo endurece es MTA-STS
o DANE, que son de `email-security-standards`**. Verifica que tu servidor **valida** el certificado
cuando lo exige la política, no solo que cifra.

## 5. Seguridad del stack

- **Relé abierto**: el fallo clásico, y hoy son horas hasta la lista negra. Restringe el relé por
  regla explícita, deja `mynetworks` en lo mínimo real, **exige autenticación sobre TLS** para todo
  lo que salga, y **pruébalo desde fuera** después de cada cambio.
- **Firma y verificación**: la clave privada de DKIM es un secreto de servidor (permisos, rotación,
  fuera del repositorio); el servidor **no firma correo que no ha autenticado**. **La política —qué
  publicar, qué alineación exigir, cómo leer los informes— es de `email-security-standards`.**
- **Límites de tasa por cuenta y por IP**: mensajes/hora, destinatarios por mensaje, tamaño máximo y
  conexiones simultáneas. Sin ellos no hay defensa contra el siguiente punto.
- **La cuenta comprometida que convierte tu servidor en emisor de spam** es el incidente típico, no
  el hipotético: se detecta por desviación de volumen y de destinatarios, no por denuncia. Ten
  decidido de antemano el corte automático, la rotación de credencial, **el purgado de la cola** y
  el aviso; y trata el reenvío automático a un buzón externo como indicio (lo posee IAM).
- **Backscatter**: rechaza al destinatario inválido **dentro de la conversación SMTP** (5xx en
  `RCPT TO`). Aceptar y luego rebotar te convierte en fuente de spam hacia direcciones falsificadas
  y acaba en lista negra.
- **Autenticación**: SASL contra la base de identidad, nunca contraseñas en fichero plano; sin
  autenticación básica sobre canal no cifrado. Bloqueo por intentos fallidos y registro de origen.
- **Superficie**: el webmail y el panel son aplicación web (`web-app-servers-standards` +
  `appsec-standards`); el antivirus y el filtro corren con usuario propio; **el MTA no ejecuta
  contenido**, y todo lo que descomprime adjuntos va acotado en tiempo, memoria y profundidad.
- **Cifrado en reposo del almacén y respaldo cifrado**: un buzón es la mayor concentración de dato
  personal de la organización, y el respaldo lo replica entero.

## 6. Almacenamiento, disponibilidad y operación

- **Formato**: **Maildir** (un fichero por mensaje) es robusto y depurable, pero castiga al
  filesystem con millones de ficheros pequeños y hace lentísimos respaldo y recorrido. **mdbox**
  agrupa mensajes y rinde mucho mejor, a cambio de formato propio de Dovecot y mantenimiento
  (`doveadm purge`). **mbox: prohibido** en multiacceso. Elige por perfil de respaldo, no por gusto.
- **Cuotas obligatorias, sin excepción**: el buzón crece hasta llenar el disco, y **el disco lleno
  en un servidor de correo es corte de servicio inmediato**. Cuota por buzón, alerta al 80 % del
  volumen y política de archivado escrita.
- **Alta disponibilidad, con el matiz correcto**: un servidor caído **no pierde correo por sí solo**
  —el emisor encola y reintenta durante días—. Se pierde correo cuando respondes 5xx por una
  configuración a medias, cuando aceptas y no puedes entregar localmente, o cuando el **MX
  secundario acepta para destinatarios que no sabe validar** y luego rebota. Regla: **un MX de
  reserva que no comparte la tabla de destinatarios válidos es peor que no tener ninguno.** Y
  **Dovecot 2.4 eliminó el `replicator`**: si tu diseño de HA dependía de él, ya no existe —verifica
  el camino soportado antes de replicar el diseño viejo.
- **Cola como señal principal**: vigila tamaño, antigüedad del mensaje más viejo y tasa de diferidos.
  Una cola diferida creciendo hacia un solo dominio es un problema de reputación; hacia todos, un
  problema de red o DNS.
- **Reputación como tarea permanente**: PTR que coincide con el HELO y con el nombre público, IP
  dedicada, calentamiento gradual del volumen, alta en las herramientas del receptor (Postmaster
  Tools, SNDS) y bucle de retroalimentación de quejas. **Vigilancia de listas negras con alerta**, no
  consulta manual cuando alguien se queja.
- **Migración entre plataformas**: `imapsync` y equivalentes funcionan, y el coste real **no es la
  herramienta**: es el tiempo por buzón (horas por gigabyte con límites de tasa del origen), las
  carpetas especiales y banderas que no mapean, la ventana de doble entrega, el cambio de MX con su
  TTL (`dns-standards`) y la reconfiguración de cada cliente. Planifica pasadas incrementales y una
  final corta, nunca una única pasada el día del corte.
- **Registro y dato personal**: los logs de correo contienen direcciones, asuntos en algunos
  niveles y patrones de relación. Retención acotada, acceso restringido y nivel de detalle
  justificado (`privacy-engineering-standards`).

## 7. Sostenibilidad y prohibiciones

Cadencia: parche del MTA/MDA **fuera de ventana** ante CVE explotable en remoto (Exim y Dovecot
tienen historial); salto de versión mayor tratado como proyecto —2.3→2.4 de Dovecot **reescribe la
configuración**—; revisión trimestral de licencias y modelo comercial de las suites, que cambian.

- ❌ Exponer un servidor de correo sin **plan de reputación** (PTR, calentamiento, vigilancia de
  listas negras, herramientas del receptor y alguien de guardia).
- ❌ Montar correo propio para "ahorrar" sin contar guardia, parcheo y respuesta a incidentes.
- ❌ Dejar un relé abierto, o no re-probar el relé desde fuera tras cada cambio.
- ❌ Aceptar correo para destinatarios que no puedes validar y rebotar después (backscatter).
- ❌ Poner un MX secundario que no comparte la lista de destinatarios válidos.
- ❌ Permitir AUTH sin TLS, o dejar POP3/IMAP en claro "solo en la red interna".
- ❌ Dejar POP3 activo por defecto sin excepción documentada.
- ❌ Buzones sin cuota, o sin alerta de ocupación del volumen.
- ❌ Usar `mbox` con acceso concurrente.
- ❌ Firmar con DKIM correo que el servidor no ha autenticado.
- ❌ Guardar la clave privada de DKIM en el repositorio o en la imagen del contenedor.
- ❌ Actualizar Dovecot 2.3 → 2.4 sin convertir la configuración y sin probar en un entorno aparte.
- ❌ Confiar en el número de versión de la edición comercial como si fuera el de la comunitaria
  (Dovecot Pro 3.x frente a CE 2.4.x).
- ❌ Dar por abandonado un proyecto porque su repositorio de GitHub esté archivado (caso Exim).
- ❌ Migrar buzones en una sola pasada el día del corte, sin incremental previo.
- ❌ Duplicar aquí la política de SPF/DKIM/DMARC: es de `email-security-standards`.

## 8. Verificación web obligatoria

1. **Versión y avisos de seguridad** de Postfix (`postfix.org/announcements.html`), Exim
   (**`exim.org`, no GitHub**; sus identificadores son **GCVE**), Dovecot CE (`dovecot.org/releases/`)
   y Rspamd, antes de fijar cualquier versión.
2. **Licencia en crudo, siempre**: `LICENSE`/`LICENCE`/`COPYING`/`LICENSE.md`/`LICENSES/` y en la
   rama correcta. En esta tanda: Postfix EPL-2.0 **o** IPL-1.0; Exim `LICENCE` GPL-2.0-or-later con
   excepción OpenSSL; Dovecot MIT+LGPL-2.1 mixto; Rspamd Apache-2.0; mailcow GPL-3.0; Mailu MIT;
   iRedMail GPLv3 + Pro propietario; Stalwart AGPL-3.0-only + SELv2; imapsync licencia propia.
3. **Modelo comercial** de las suites: cambia más rápido que el código y decide si puedes usarlas.
4. **Requisitos de los grandes receptores**: relee la guía de Google, la de Yahoo y la de Microsoft
   antes de prometer entrega. **Hueco declarado**: la entrada de Microsoft sobre remitentes de alto
   volumen **se renderiza por JavaScript y no se pudo leer en crudo**; las fechas de 2-abr-2025 y
   5-may-2025 provienen de búsqueda web que la cita, y **la fecha de paso a rechazo definitivo
   estaba "por anunciar"**: re-verifícala en el blog de Microsoft.
5. **Hueco declarado — endurecimiento de DMARC**: circula que en 2026 los grandes exigirían
   `p=quarantine`/`p=reject`. **No lo he podido confirmar en fuente primaria**: trátalo como rumor
   hasta verlo en la guía del proveedor, y consulta `email-security-standards`.
6. **RFC uno a uno en `rfc-editor.org`** antes de citarlos: comprueba estado y campos
   *obsoleted_by* / *updated_by*. Aquí ya se corrigieron suposiciones frecuentes: 5321 y 5322 son
   **Draft Standard** y **no** están obsoletos, 6409 y 1939 sí son **Internet Standard**, y 3501
   está obsoleta por 9051.
7. **Estado de JMAP**: qué servidores y clientes lo implementan de verdad, y si Dovecot lo ha
   añadido. Es el dato que decide si dejas de ignorarlo.
8. **Camino de HA soportado en Dovecot 2.4** tras la retirada del `replicator`, y el estado del
   conversor de configuración.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
