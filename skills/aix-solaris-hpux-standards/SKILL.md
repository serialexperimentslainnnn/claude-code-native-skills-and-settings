---
name: aix-solaris-hpux-standards
description: Proprietary Unix operating systems still in production — IBM AIX on Power, Oracle Solaris on SPARC and x86, and HP-UX on Itanium. Use when working with AIX (oslevel -s, Technology Levels and Service Packs, instfix, smit/smitty, lsattr, lsdev, lspv, chdev, mksysb, alt_disk_copy, NIM, Live Update, JFS2, LVM volume groups, rootvg, errpt, lparstat, nmon, topas, WPARs, PowerVM LPARs, VIOS and padmin, HMC, Update Access Key/UAK, SWMA), Solaris (svcs and svcadm SMF services, /etc/svc manifests, pkg and IPS publishers, beadm boot environments, SRU levels, zoneadm/zonecfg native and kernel zones, LDoms/ldm, ZFS on Solaris, dtrace, prstat, zpool, /etc/system, Oracle Lifetime Support tiers), HP-UX (swinstall/swlist/swremove, SD-UX depots, Ignite-UX recovery images, LVM/VxVM and vgdisplay, /etc/lvmtab, ioscan, setboot, Serviceguard packages, nPars and vPars, Integrity rx/rx2800 and Superdome Itanium hardware), illumos distributions (OmniOS, SmartOS, OpenIndiana, Tribblix), ksh88/ksh93 scripting for these platforms, or planning to freeze, extend support for, or migrate off any of them.
---

# Estándares de Unix propietario: AIX, Solaris y HP-UX

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Estos tres sistemas no están en la misma situación y el criterio depende de cuál sea.** Meterlos
en un mismo saco de "Unix legacy" es el error de partida:

- **AIX está vivo.** Release actual **7.3**, con *Technology Level* nuevo cada año (TL4 publicado en
  **dic-2025**), hardware nuevo debajo (Power11, jul-2025) y hoja de ruta. Aquí planificas
  **upgrades**, no salida.
- **Solaris está congelado pero contratado a muy largo plazo.** Oracle detuvo el desarrollo mayor
  en 2018: **no hay Solaris 12**, solo 11.4 con SRUs. Pero el calendario publicado llega a **2037**
  y en 2026 Oracle *bajó* la cadencia de parches (§2). Aquí decides si te apoyas en un contrato de
  mantenimiento de una plataforma sin futuro funcional.
- **HP-UX ha terminado.** El soporte estándar de 11i v3 sobre Integrity **acabó el 31-dic-2025**;
  lo que queda hasta 2028 es soporte *maduro sin ingeniería de sostenimiento* — es decir, **no hay
  parches nuevos**, ni siquiera de seguridad. Y no hay hardware: **Intel dejó de enviar Itanium en
  2021**. Aquí no se planifica upgrade: se planifica **salida o aislamiento**.

Cubre: calendario y versión vigente de cada uno (§2); lo específico de cada plataforma que decide
sobre la operación (§3); inventario y auditoría de lo que realmente corre (§4); parcheo, cuentas y
exposición (§5); contratos de hardware, repuestos y soporte extendido (§6); y el criterio de
congelar, aislar o migrar (§7).

**Por qué siguen vivos** —y hay que decirlo sin cinismo, porque es la razón real y a veces es
correcta—: una **aplicación certificada por el proveedor solo sobre ese sistema**, hardware ya
amortizado con coste marginal casi nulo, y una organización que **no sabe qué hace la máquina** y
por tanto no puede estimar la migración. Los tres motivos son legítimos como diagnóstico y ninguno
lo es como plan indefinido.

**No aplica**:
- `linux-administration-standards`, `rhel-fedora-standards`, `linux-hardening-standards`,
  `linux-storage-standards` y `zfs-standards` (**ya escritas**): **Linux y ZFS son suyos** —
  incluido ZFS como tecnología; aquí solo lo que ZFS significa *dentro de Solaris* (§3.2).
- `onprem-standards` (**paraguas de plataforma, con la tabla de enrutado**),
  `ha-clustering-standards` (clustering genérico; aquí Serviceguard/PowerHA solo como dato de
  plataforma), `backup-recovery-standards` (**suya la mecánica de copia y restauración**; aquí
  `mksysb` e Ignite-UX solo como imagen de sistema), `homelab-standards`, `bcdr-standards`,
  `os-provisioning-standards`, `server-hardware-standards`,
  `identity-access-management-standards`, `secrets-management-standards`,
  `vulnerability-management-standards`, `detection-engineering-standards` (**suyas las reglas de
  detección**), `endpoint-security-standards`, `firewall-policy-standards`, `networking-standards`,
  `iac-standards`, `grc-compliance-standards`, `legacy-modernization-standards` y
  `migration-projects-standards` (**estas dos, suyas la estrategia de cartera y la ejecución del
  proyecto; aquí qué implica técnicamente cada opción**).
- `ibm-i-rpg-standards` (**ya escrita**): **IBM i es otro sistema operativo**, no una variante de
  AIX — comparten Power y HMC/LPAR y nada más. `mainframe-zos-cobol-standards` y `mumps-standards`:
  mismo cajón mental, criterio no extrapolable.
- `bsd-systems-standards` y `macos-fleet-standards`: **el nombre "Unix" las junta y no comparten
  casi nada operativo** — BSD no es Unix propietario (es una familia viva que se elige, no que se
  hereda) y macOS es una flota de puestos, no de servidores.

## 2. Estado verificado de cada plataforma

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Plataforma | Versión vigente | Calendario publicado | Hardware al que está atada |
|---|---|---|---|
| **AIX** | **7.3**, TL4 (`7.3.4`, dic-2025) | IBM publica *End of Fix Support* **por TL**: TL4 → 31-dic-2028, TL3 → 31-dic-2027, TL2 → 30-nov-2026, TL1 venció 31-dic-2025. Política *Enhanced*: mínimo 5 años + extensión de 3 | Power (CHRP) POWER8/9/10/Power11. **Power11 exige HMC V11, que no soporta POWER8** — y la HMC 7063-CR1 *es* POWER8: se sustituye |
| **AIX 7.2** | TL5 aún soportada | **Sin fecha de EOS publicada verificada** (§8, hueco) | POWER8/9/10 |
| **VIOS** | 4.1.1.10 | 4.1.0.40 fin de servicio 30-nov-2026; 3.1.4.60 el 30-abr-2026; 4.1.1.10 hasta 31-dic-2027 | Ligado a la generación Power y al nivel de HMC |
| **Solaris** | **11.4** (GA ago-2018), SRU93 (16-jun-2026) | Premier hasta **nov-2031**, Extended hasta **nov-2037**, Sustaining indefinido. Solaris 10 y 11.3 pasan a Sustaining en **2027** | SPARC (M8/T8 de Oracle, **M12 de Fujitsu**) y **x86** |
| **Solaris — cadencia** | Dos entregas por trimestre desde 11.4.92 | Anuncio del 23-abr-2026: **CPU** trimestral sincronizada con el ciclo de seguridad de Oracle + **SRU** ~6 semanas después. Antes era mensual | — |
| **HP-UX** | **11i v3 (11.31)**, última entrega 2505.11iv3 (may-2025) | *"HPE Integrity: standard support through 31-Dec-2025"* (terminado). Estado actual: *"Mature Software Product Support without Sustaining Engineering through at least 31-Dec-2028"* | **Itanium. Intel dejó de enviar Itanium en 2021**: no hay ni habrá hardware nuevo |
| **illumos** (derivados de Solaris) | **OmniOS r151058** (2026-05-04, fin 2027-05-03); **LTS r151054** hasta 2028-05-01 | LTS cada cuarta entrega, **3 años**; estable, 1 año. Cadencia semestral, sostenida sin saltos desde 2017 | x86 (SPARC no es objetivo práctico) |
| **SmartOS** | Activo (imagen de plataforma may-2026) | Imágenes rodantes, sin releases versionadas. **Propiedad de MNX desde 2022** (comprado a Joyent) | x86; base de Triton DataCenter |

**Licencia de illumos, citada literalmente de su FAQ**: *"The bulk of the illumos source code is
available under the Common Development and Distribution License (CDDL)"*, con *"some components
with other licenses including BSD and MIT"* y software GPL/LGPL incluido. **CDDL es copyleft de
fichero e incompatible con GPLv2**: eso es lo que decide si puedes mezclar código, no la etiqueta
"open source".

**Discrepancias declaradas:**
- **AIX**: agregadores de terceros publican "EOS de AIX 7.3 el 30-sep-2026". **IBM no publica la
  fecha de EOS de un release de AIX hasta que ha pasado**; lo que sí publica es el fin de soporte
  de correcciones *por TL*. No cites ese 2026 como fin de vida de 7.3.
- **HP-UX**: la fecha **31-dic-2028** circula como "soporte extendido". No lo es: es soporte de
  producto maduro **sin ingeniería de sostenimiento**. Tratarlo como cobertura de seguridad es un
  error de riesgo, no de matiz.
- **Solaris**: el calendario 2031/2037 procede del documento *Oracle Lifetime Support Policy* y de
  prensa especializada; **el PDF oficial no fue recuperable de forma automatizada** en esta
  verificación (§8).

## 3. Lo específico de cada plataforma que decide

### 3.1 AIX
- **La unidad de despliegue es la LPAR**, no el servidor: CPU y memoria se mueven en caliente y el
  E/S pasa por **VIOS**. Un VIOS sin pareja es un SPOF que anula la HA de todo lo que hay encima:
  **VIOS en pareja, siempre**, y su actualización es un procedimiento propio y previo al del resto.
- **TL y SP no son lo mismo**: el TL trae función y reinicia el reloj de soporte; el SP corrige.
  La cadencia sana es **un TL al año y el SP vigente**, no "cuando haya un problema" (§5).
- **`mksysb` es la imagen del sistema** y **NIM** lo que la despliega; el que nadie ha restaurado no
  es copia, es un fichero (política en `backup-recovery-standards`). **Live Update** evita el
  reinicio para el kernel, no la ventana ni la prueba: solo validado en tu combinación LPAR/VIOS.
- **UAK (*Update Access Key*) es la trampa operativa nueva**: desde **7.3 TL4** actualizaciones y
  migraciones **fallan** con la clave caducada — **un contrato SWMA vencido bloquea parchear**. Su
  fecha va en el calendario, no en la cabeza de alguien.
- `smit` genera comandos: se automatiza el comando (`chdev`, `lsattr`, `installp`), no la pantalla.
  **Ningún cambio de producción se hace solo por menú y sin registrar.**

### 3.2 Solaris
- **ZFS nació aquí**, y es la razón por la que estas máquinas siguen siendo defendibles: `zpool` con
  suma de verificación, snapshots baratos y, sobre todo, **boot environments (`beadm`)** — se
  actualiza con vuelta atrás garantizada por reinicio. **Cualquier SRU se aplica sobre un BE nuevo**;
  hacerlo de otro modo tira la única ventaja real de la plataforma.
- **Zonas antes que máquinas virtuales**: la zona nativa es consolidación casi sin coste y sigue
  siendo la vía limpia para encapsular una aplicación vieja. **Una zona `solaris10` branded es la
  jugada de contención por excelencia** cuando la aplicación no pasa de Solaris 10 (§7).
- **SMF** convierte los servicios en manifiestos con dependencias: los scripts rc heredados se
  migran, no se envuelven. Un servicio en `maintenance` es un fallo, no un aviso. **DTrace** es lo
  que hace diagnosticable la plataforma, y lo que se echa de menos en el destino de la migración.
- **Actualizar es `pkg update` a un SRU**, no reinstalar. Quedarse en un SRU viejo es quedarse sin
  las CPUs trimestrales de Oracle: el riesgo se acumula silenciosamente.
- **Los derivados de illumos (OmniOS, SmartOS) son una salida real para *almacenamiento y
  virtualización*, no para la aplicación certificada**: conservan ZFS, zonas y DTrace, están
  mantenidos y son gratuitos, pero **ningún proveedor de software comercial los certifica**. Si el
  motivo de quedarse en Solaris es la certificación del proveedor, illumos no resuelve nada.

### 3.3 HP-UX
- Todo lo que se decide aquí es **de salida**: `swlist` para saber qué hay instalado, **Ignite-UX**
  para tener una imagen restaurable *hoy*, y `ioscan` para el inventario de hardware sin repuesto.
- **Serviceguard** puede estar sosteniendo una HA cuya única pieza irremplazable es el hardware.
  Un clúster de dos nodos Itanium sin repuestos no es alta disponibilidad: es dos relojes a la vez.
- **Congelar es una decisión válida (§7); no parchear sin congelar no lo es.**

## 4. Inventario: saber qué corre

> *(Se omite la sección de "calidad y testing" del formato: no hay toolchain propio que fijar.
> Lo que ocupa su lugar aquí es el inventario, porque es el control que falta en todos estos casos.)*

**En estos sistemas nadie sabe qué corre**, y casi siempre es literal: quien lo montó se fue, la
documentación es de otra década y la aplicación "solo funciona". Antes de decidir nada —congelar,
extender soporte o migrar— hay que producir, con fecha y en el repositorio:

1. **Qué procesos escuchan y quién les habla**: puertos y conexiones observadas durante un ciclo
   completo de negocio, cierre anual incluido. **La integración que nadie recuerda aparece en el
   cierre de ejercicio, no en abril.**
2. **Qué software de terceros hay y con qué versión** (`lslpp`/`pkg list`/`swlist`), qué está
   certificado por el proveedor y **contra qué versión exacta del sistema operativo**.
3. **Qué trabajos programados existen** (`cron` de todos los usuarios, planificador corporativo).
4. **Quién tiene acceso y desde dónde**, incluidas cuentas de servicio y confianzas antiguas (§5).
5. **Qué se restaura y en cuánto tiempo**, probado — no el procedimiento, el ensayo.

Sin estos cinco puntos, cualquier estimación de migración es ficción y cualquier decisión de
quedarse es inercia disfrazada de criterio.

## 5. Seguridad y parcheo

- **Cadencia real, escrita y con dueño.** Lo habitual aquí es "se parchea cuando hay parada", que
  significa cada dos años. Fija: AIX → un TL al año y el SP vigente; Solaris → cada CPU trimestral
  sobre BE nuevo; HP-UX → **no hay parches: por eso hay que aislar** (§7).
- **Cuentas históricas.** Usuarios de gente que se fue, cuentas de aplicación con contraseña
  compartida y `sudo`/`root` repartido sin registro. Inventario, dueño nominal por cuenta de
  servicio y baja del resto: **una cuenta sin dueño se deshabilita, no se documenta.** Autenticación
  centralizada contra el proveedor de identidad corporativo donde el sistema lo soporte — el punto
  de contacto con `identity-access-management-standards`.
- **Confianza sin autenticación**: `.rhosts`, `hosts.equiv`, rsh/rlogin/telnet/FTP en claro y NIS
  siguen existiendo en estos parques. Todos fuera; SSH con clave y **sin login directo de `root`**.
  Y **cripto congelada con el sistema**: verifica qué algoritmos negocia de verdad, no qué versión
  dice tener.
- **Auditoría exportada fuera de la máquina** (`errpt`, `audit`, syslog remoto). Si los registros
  solo viven en el host que se quiere proteger, no hay evidencia forense.
- **Cuando no hay parche, el control es la red**: segmentación, acceso solo por bastión y filtrado
  de salida. Es la respuesta correcta para HP-UX y para cualquier sistema fuera de soporte.

## 6. Contratos, repuestos y la trampa del soporte extendido

- **El soporte extendido de pago es una decisión que se renueva sola.** Se firma "un año más" con
  la migración prometida para el siguiente, y a los cinco años el coste acumulado supera al del
  proyecto que se evitaba. Regla: **cada renovación exige la comparación explícita contra el coste
  de salir, por escrito y con fecha de decisión**; si no la hay, no se firma.
- **El riesgo real no suele ser el software: es la pieza** (alimentación, cabina, cinta, disco SAS
  descatalogado, **la propia HMC**). Verifica por contrato cobertura, tiempo de reposición y si el
  repuesto es nuevo o de mercado gris: **soporte de software sobre hardware sin repuestos es
  cobertura ficticia**. Ten además un plan de "murió el hardware hoy" —emulación, máquina en frío o
  servicio gestionado—; sin él, el RTO real es "lo que tarde eBay".
- **Patrón de migración habitual**, por orden de fricción creciente: (1) **Linux sobre el mismo
  Power** si vienes de AIX y la aplicación lo permite —conserva la inversión en hardware—; (2) a
  **x86** (Linux) por reescritura o recompilación, que es donde aparece el trabajo real de
  *endianness*, cadenas de compilación y dependencias del proveedor; (3) a una **plataforma
  gestionada** (incluida Power como servicio en nube) cuando lo que se quiere quitar de encima es
  el hardware, no el sistema operativo. Solaris añade una cuarta vía específica: **x86 con
  Solaris 11.4 o un derivado illumos**, que conserva zonas y ZFS.

## 7. Congelar, aislar o migrar — y prohibiciones

**Congelar y aislar es la decisión correcta cuando** la aplicación es estable y de cambio nulo, la
migración cuesta más que el valor que aporta el sistema, y **puedes reducir su exposición a casi
cero**: sin acceso desde internet, en su propio segmento con filtrado de entrada y **de salida**,
acceso humano solo por bastión con registro, integraciones reducidas a una lista explícita, imagen
restaurable probada y **fecha de revisión en el calendario**. Congelar es una postura de seguridad
activa con dueño, no dejar de tocar la máquina.

**Migrar antes que congelar cuando** el sistema está expuesto a redes no controladas, procesa datos
regulados con obligación de parcheo, o **el hardware ya no tiene repuesto garantizado**. En HP-UX,
por defecto, es esto.

**Prohibiciones:**

- ❌ **PROHIBIDO** dejar un sistema sin soporte accesible desde la red corporativa plana o desde
  internet. Sin parche no hay control técnico: el control es la segmentación.
- ❌ Tratar el soporte de producto maduro de HP-UX (hasta 2028) como si incluyera parches de
  seguridad. **No incluye ingeniería de sostenimiento.**
- ❌ Renovar soporte extendido de pago sin la comparación escrita frente al coste de salida (§6).
- ❌ Firmar soporte de software sobre hardware cuyo repuesto no está cubierto por contrato.
- ❌ Aplicar un SRU de Solaris sin **boot environment** nuevo, o un TL de AIX sin `mksysb` reciente
  y vuelta atrás probada.
- ❌ Dejar caducar el **UAK**/SWMA de AIX: bloquea la propia capacidad de parchear (§3.1).
- ❌ Actualizar a Power11 sin comprobar antes el nivel de HMC y VIOS (§2).
- ❌ VIOS único sin pareja en una LPAR de producción.
- ❌ `rsh`/`rlogin`/`telnet`/FTP en claro, `.rhosts`, `hosts.equiv` o NIS. Cuentas de servicio sin
  dueño nominal.
- ❌ Cambios de producción hechos solo por `smit`/`sam` sin dejar el comando equivalente registrado.
- ❌ Planificar la migración sin haber hecho antes el inventario de §4 — incluido el ciclo de
  cierre anual.
- ❌ Presentar un derivado de illumos como sustituto de Solaris cuando el motivo de quedarse era la
  certificación del proveedor (§3.2).
- ❌ Extrapolar criterio entre estas tres plataformas, o desde IBM i: están en fases distintas.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web —y con **cita literal**, no con resumen
automático:

1. **AIX**: TL y SP vigentes y sus fechas de *End of Fix Support*; nivel mínimo de HMC, VIOS y
   firmware para tu generación Power. **Hueco declarado: la fecha oficial de fin de soporte (EOS)
   de los releases AIX 7.2 y 7.3 no fue verificada a ago-2026** — IBM no la publica hasta que ha
   pasado y `ibm.com` rechaza la recuperación automatizada (HTTP 403). Consúltala en la página de
   ciclo de vida de IBM antes de citarla; **las fechas de agregadores de terceros no sirven**.
2. **Solaris**: fechas de Premier/Extended/Sustaining en el documento *Oracle Lifetime Support
   Policy — Oracle and Sun System Software and Operating Systems*, y SRU vigente. **Verificación
   parcial declarada: el PDF de Oracle no fue recuperable automáticamente**; las fechas de §2
   proceden de búsqueda y prensa especializada. Confírmalas en el PDF antes de apoyar una decisión
   contractual.
3. **Cadencia de SRU de Solaris**: cambió en abr-2026 a dos entregas por trimestre. Verifica si ha
   vuelto a cambiar antes de planificar ventanas de parcheo anuales.
4. **HP-UX**: estado en la matriz de soporte de HPE. Las dos citas de §2 están tomadas literalmente
   de cobertura de prensa del 5-ene-2026; contrasta contra la matriz oficial de HPE.
5. **Hardware**: fechas de fin de vida y de fin de soporte del modelo concreto (no de la familia) y
   **disponibilidad real de repuestos**, incluida la HMC. Fujitsu SPARC M12 y Oracle M8/T8 tienen
   calendarios distintos entre sí.
6. **illumos y derivados**: calendario de OmniOS (verificado literalmente en `omnios.org/schedule`:
   r151058 hasta 2027-05-03, LTS r151054 hasta 2028-05-01) y actividad de SmartOS. **Hueco
   declarado: la licencia exacta de SmartOS/Triton no se verificó leyendo el `LICENSE` en crudo**;
   la afirmación "CDDL o MPL 2.0" procede del anuncio de traspaso a MNX de 2022. **Léelo en crudo
   en el repositorio antes de fijarla — y no des por buena la etiqueta de licencia que muestre
   GitHub.**
7. **Precios**: ni IBM, ni Oracle, ni HPE publican tarifas de soporte extendido. **Ninguna cifra
   económica de §6 debe salir de aquí**: sale de tu oferta.
8. **CVEs** de los componentes portados (OpenSSH, OpenSSL, pilas Java y Python) en su versión
   *empaquetada por el proveedor*, que no coincide con la de aguas arriba.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
