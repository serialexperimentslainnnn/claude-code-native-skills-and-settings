---
name: embedded-iot-standards
description: Engineering a physical connected device — microcontroller or embedded Linux — from silicon choice to field update and its EU regulatory deadline. Use when working with prj.conf, west.yml, Kconfig fragments, boards/*_defconfig, devicetree .dts/.dtsi/.overlay files, FreeRTOSConfig.h, a Zephyr/FreeRTOS/NuttX/Eclipse ThreadX application, a superloop versus RTOS decision, NuttX Kconfig, Yocto bitbake recipes (.bb/.bbappend, local.conf, bblayers.conf, meta- layers, kas), Buildroot (make menuconfig, BR2_ options, br2-external, defconfig), a cross toolchain sysroot or arm-none-eabi-gcc, a linker script .ld with FLASH/RAM regions and .bss/.noinit sections, newlib-nano or picolibc, U-Boot bootcmd/bootargs and boot_targets, MCUboot slot0/slot1 and imgtool sign, A/B or dual-bank firmware slots with rollback counters, RAUC or SWUpdate or Mender or Eclipse hawkBit OTA campaigns, watchdog kick and reset-cause registers, low-power modes and coulomb-counter energy budgets, JTAG/SWD debugging with OpenOCD, probe-rs, J-Link or a reset-cause register, semihosting or printf-over-UART cost, static allocation and no-malloc firmware, a secure element or TPM or ARM TrustZone-M key store, per-device identity and provisioning, PSA Certified, ETSI EN 303 645, the EU Cyber Resilience Act (Regulation (EU) 2024/2847), or RED Delegated Regulation (EU) 2022/30 and EN 18031.
---

# Estándares de sistemas empotrados y dispositivo IoT

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **construir un producto físico que ejecuta software propio y, casi siempre, se conecta**:
elegir el silicio (MCU frente a MPU), decidir si hace falta un RTOS o basta un superloop, montar la
toolchain cruzada y hacer el build reproducible, arrancar (bootloader, device tree), **poder
actualizarlo en campo sin que un fallo lo convierta en ladrillo**, vigilarlo (watchdog), medir su
consumo, depurarlo sin puerto abierto en producción, gestionar la memoria sin *heap*, y cumplir el
marco regulatorio europeo que **ya tiene fechas en el calendario**.

Triggers: `prj.conf`, `west.yml`/`west build`, `Kconfig` y fragmentos `*.conf`, `boards/*_defconfig`,
`.dts`/`.dtsi`/`.overlay`/`dtc`, `FreeRTOSConfig.h`, `configTOTAL_HEAP_SIZE`, `xTaskCreateStatic`,
`nuttx/.config`, Eclipse ThreadX / `tx_thread_create`, `arm-none-eabi-gcc`, `--specs=nano.specs`,
picolibc, un `.ld` con `MEMORY { FLASH ... RAM ... }`, `.noinit`, `bitbake`, `local.conf`,
`bblayers.conf`, `meta-*`, `kas`, `BR2_*`, `br2-external`, `u-boot.env`, `bootcmd`, `bootargs`,
`fw_setenv`, MCUboot, `imgtool sign`, slot0/slot1, `RAUC`, `SWUpdate`, `Mender`, `hawkBit`,
`swupdate.cfg`, `system.conf` de RAUC, `IWDG`/`WWDG`/`wdt_feed`, `PWR_CR`, "modo *stop*",
"presupuesto de energía", OpenOCD, `probe-rs`, J-Link, SWD, JTAG, semihosting, ATECC608, SE050,
TPM 2.0 en dispositivo, TrustZone-M / `CMSE`, PSA Certified, ETSI EN 303 645, EN 18031, RED,
Cyber Resilience Act, "clave por dispositivo", "no arranca tras el update".

**Principio rector**: **un dispositivo sin vía de actualización remota probada es un pasivo, no un
producto.** Todo lo demás de esta skill —arranque, particionado, watchdog, identidad, energía— existe
para que esa actualización sea posible durante los diez o quince años que el aparato va a estar
enchufado. La segunda regla de la casa: **el firmware no puede pedir ayuda**. No hay operador, no hay
`ssh`, no hay reinicio manual — si el diseño supone que alguien irá a tocarlo, el diseño está mal.

**No aplica**: ver `ot-ics-security-standards` (**la industria y el proceso son suyos, sin
excepción**: PLC, RTU, DCS, SCADA, SIS, modelo Purdue/ISA-95, zonas y conductos de IEC 62443,
protocolos de campo —Modbus, DNP3, PROFINET, IEC 60870-5-104, OPC UA—, monitorización pasiva y
ventana de parada. **Frontera operativa: si el aparato *actúa sobre un proceso físico industrial* y
su fallo es un problema de seguridad de personas, es suyo; si es un producto conectado de consumo,
edificio, retail, medición o logística, es de aquí.** Un controlador que caiga en ambos lados se
diseña bajo esta skill y **se gobierna bajo la suya**), `edge-computing-standards` (**Ola 7, en
curso** — hermana directa: **suyo el nodo con Linux completo, el cómputo desplazado al borde, la
flota como sistema distribuido, la sincronización y la orquestación remota**; **aquí el dispositivo
como objeto físico**: silicio, arranque, memoria, energía, periféricos, imagen del firmware y su
actualización. Regla de arbitraje: *"¿qué se ejecuta en el borde y cómo se coordina la flota?" es
suyo; "¿qué imagen arranca en esa placa, cómo se firma y cómo se sustituye sin ladrillarla?" es de
aquí*), `c-standards`, `cpp-standards`, `rust-standards`, `ada-standards` y `zig-standards` (**el
lenguaje y su toolchain son suyos**, incluidos `-std=`, MISRA C/CERT C, sanitizers, flags de
hardening del binario, runtime restringido de Ada y `no_std` de Rust — **aquí solo qué restricciones
impone el objetivo**: sin `malloc`, sin excepciones, sin libc completa, tamaño de pila acotado),
`assembly-standards` (arranque en ensamblador, vectores y rutinas críticas), `linux-administration-standards`
(el día a día de systemd en un servidor — **no** en una imagen empotrada de solo lectura),
`linux-hardening-standards` (baseline CIS/STIG de un host completo: no es el modelo de un aparato de
32 MB), `selinux-standards`, `container-runtime-security-standards` (contenedor y su runtime, si el
aparato llega a ejecutarlos), `cryptography-pki-standards` (**elección de algoritmo, curva, tamaño de
clave y toda la PKI de provisión: es suya** — aquí solo dónde vive la clave en el silicio y por qué),
`secrets-management-standards` (custodia y rotación del secreto en el lado servidor),
`performance-engineering-standards` (metodología de perfilado de servidores),
`networking-standards`, `wireless-standards` (radio, espectro, coexistencia),
`opensource-licensing-standards` (obligaciones de distribución: **un aparato que embarca GPL es
distribución, y ahí manda esa skill**), `vulnerability-management-standards` (triaje y SLA de los CVE
del árbol embarcado), `grc-compliance-standards` (marco regulatorio como programa; aquí las fechas
que decidan diseño), `mobile-standards` (la app que lo controla), `homelab-standards` (la placa como
juguete: la frontera es el rigor exigido, no el hardware).

## 2. Decisiones por defecto

> Verificar la última versión, licencia y fecha por web antes de fijar nada en un proyecto real (§8).
> Lo siguiente es el estado **verificado** a agosto de 2026, con la fuente citada.

### 2.1 MCU o MPU — la decisión que condiciona todas las demás

| Elige **MCU** (Cortex-M, RISC-V embebido, ESP32, nRF) si | Elige **MPU + Linux** (Cortex-A, RISC-V con MMU) si |
|---|---|
| El presupuesto de energía se mide en µA medios o el aparato va a pila años | Hay alimentación continua o batería grande y recargable |
| Se exige arranque en milisegundos y determinismo de la respuesta | Se toleran segundos de arranque y latencias de decenas de ms |
| El BOM manda: unidades de euro, RAM en KB, flash en cientos de KB | Hace falta pila de red completa, TLS moderno, sistema de ficheros, actualización de paquetes |
| La función es fija y conocida en el diseño | La función va a cambiar: apps, contenedores, modelos, orquestación remota |
| No hay MMU y no se quiere sistema operativo de propósito general | Se necesita aislamiento de procesos, MMU y usuarios |

Reglas duras: **no se elige MPU "por si acaso"** (multiplica coste, consumo, superficie de ataque y
carga de mantenimiento de un árbol Linux completo durante toda la vida del producto), y **no se
elige MCU cuando ya se sabe que hará falta TLS 1.3, un sistema de ficheros y OTA de imagen
completa** — ese proyecto acaba portando medio Linux a mano. Si la duda es real, **la decide el
presupuesto de energía y el ciclo de vida del software**, no la simpatía por la plataforma.

### 2.2 Superloop o RTOS

**Un superloop no es una decisión de principiante: es la respuesta correcta más veces de lo que se
admite.** Un `while(1)` con máquina de estados no bloqueante y una ISR que solo pone banderas es
determinista, auditable de un vistazo, no tiene *stack overflow* por tarea ni inversión de
prioridad, y cabe en 8 KB de RAM.

| Superloop basta si | Hace falta RTOS si |
|---|---|
| Todo el trabajo es no bloqueante y acotado; ningún camino tarda más que el peor plazo | Hay actividades con plazos muy distintos que no se pueden intercalar a mano |
| Hay 1-2 fuentes de eventos y ningún protocolo con máquinas de estado profundas | Hay pila TCP/IP, BLE, USB o sistema de ficheros: casi todas asumen hilos |
| El equipo puede razonar el peor tiempo de ejecución del bucle completo | Se necesitan primitivas de sincronización, temporizadores y colas ya probadas |
| No se usan bibliotecas de terceros que asuman bloqueo | Se quiere aprovechar drivers y middleware del ecosistema del RTOS |

**Antipatrón principal**: *superloop con un `delay()` bloqueante en medio*. Deja de ser un superloop
y pasa a ser un sistema con plazos indeterminados. Si aparece un `delay()` de más de un puñado de
microsegundos en el bucle, o el diseño se rehace con máquina de estados o toca RTOS.

### 2.3 RTOS — estado, gobernanza y licencia verificados

| RTOS | Versión verificada (ago-2026) | Licencia leída en crudo | Gobernanza | Cuándo es el default |
|---|---|---|---|---|
| **Zephyr** | **4.4.0** (2026-04-14, EOL 2027-04-12); **LTS vigente: 3.7.0** (2024-07-26, mantenido hasta **2029-07-27**) — próximo LTS previsto en 4.6 | **Apache-2.0** (`LICENSE` en `main`, texto íntegro de la Apache License 2.0) | Linux Foundation, con proceso de seguridad y CVE propios | **Default del catálogo** para producto nuevo con conectividad: `west`, Kconfig+devicetree, MCUboot integrado, soporte de placas y política de LTS explícita |
| **FreeRTOS Kernel** | **V11.3.0** | **MIT** (`LICENSE.md` en `main`) | Amazon (AWS) como *steward* desde 2017 | Proyecto que ya lo usa, MCU muy pequeño, o cuando se quiere planificador y nada más — **FreeRTOS es un kernel, no una distribución**: red, TLS, OTA y drivers los pones tú |
| **NuttX** | **13.0.0** | **Apache-2.0** (`LICENSE` en `master`) | **Apache Software Foundation** (proyecto de primer nivel) | Cuando la **compatibilidad POSIX** es el requisito: código que debe compilar igual en Linux y en el aparato, o portabilidad de aplicación existente |
| **Eclipse ThreadX** | v6.4.x, cadencia trimestral sincronizada entre componentes | **MIT** (`LICENSE.txt` en `master`, *"Copyright (c) 2024 - present Microsoft Corporation"*) | **Eclipse Foundation** desde 2023-2024; existe la **ThreadX Alliance** (lanzada 2024-10-08) para sostenibilidad y para licenciar el paquete de documentación de seguridad funcional | Cuando se necesita RTOS **con certificación de seguridad funcional** y el ecosistema del fabricante ya lo trae (STM32, Renesas, Microchip) |

Notas de gobernanza que **se afirman mal constantemente**:
- **"Azure RTOS" ya no existe como producto de Microsoft**: la marca no era transferible; el proyecto
  es **Eclipse ThreadX** bajo Eclipse Foundation, MIT. Escribir "Azure RTOS" en un documento de 2026
  es señal de que el dato viene de memoria.
- El repositorio de documentación `eclipse-threadx/rtos-docs` está **archivado**; la fuente viva es
  `rtos-docs-asciidoc`. La cadencia de versiones se sincroniza entre componentes **aunque el código no
  haya cambiado** — una versión nueva no implica cambio funcional: hay que leer las notas.
- FreeRTOS es MIT desde la v10 (antes, GPL modificada). Si el proyecto arrastra un `FreeRTOS.h` de
  hace una década, **la licencia embarcada no es la que crees**: se lee del árbol que se compila.

### 2.4 Linux embebido — Yocto o Buildroot, con criterio

| Yocto Project | Buildroot |
|---|---|
| **Producto con vida larga y varias variantes de hardware**: capas (`meta-*`) permiten separar BSP del fabricante, distro y producto | **Un producto, un hardware, una imagen**: `defconfig` + `br2-external` y poco más |
| Genera **SDK y paquetes** (`ipk`/`rpm`/`deb`): permite instalar y actualizar por paquete si se decide así | **No hay gestor de paquetes**: la imagen es el artefacto, y eso empuja —correctamente— a OTA de imagen completa |
| **LTS real**: Wrynose 6.0 (abril 2026, soporte hasta **abril 2030**); Scarthgap 5.0 (abril 2024, hasta **abril 2028**) | Ciclo trimestral (2026.05 es la última verificada); **LTS cada dos años con 3 años de soporte** — la línea 2025.02.x es la LTS vigente, la siguiente será 2027.02 |
| Curva de aprendizaje alta, builds largas, `bitbake` opaco cuando falla | Se aprende en un día, build de una hora, `make menuconfig` legible |
| Licencia: **MIT** (OpenEmbedded/poky) | **GPL-2.0-or-later** (`COPYING`: *"Buildroot is distributed under the terms of the GNU General Public License … either version 2 of the License, or (at your option) any later version"*) — con la salvedad explícita de que **los parches empaquetados se rigen por la licencia del software al que se aplican** |

**El criterio de elección real, no el gusto**: se elige **Yocto** cuando hay *más de una variante de
hardware o de producto que comparte base*, cuando el BSP del fabricante ya viene como capa Yocto, o
cuando el ciclo de vida exige una rama LTS con parches de seguridad durante años. Se elige
**Buildroot** cuando hay *un hardware, un equipo pequeño y una imagen*, y se prefiere entender el
build entero a delegarlo. **Quien elige Yocto para un producto único y sencillo paga una complejidad
que no necesitaba; quien elige Buildroot para una familia de seis productos acaba con seis árboles
divergentes.** Ojo con el origen: **Buildroot se desarrolla en GitLab (`gitlab.com/buildroot.org/buildroot`)
y el repositorio de GitHub es un *mirror*** — issues y PR allí no los ve nadie.

### 2.5 Arranque, toolchain y OTA

| Decisión | Default | Motivo / dato verificado |
|---|---|---|
| Bootloader MPU | **U-Boot** (última verificada: 2026.07 en `ftp.denx.de/pub/u-boot/`) | **GPL-2.0**, con excepción explícita para las *standalone applications* que usan la *jump table* (`Licenses/README`) — dato relevante para el cumplimiento de distribución |
| Bootloader MCU | **MCUboot 2.4.0**, **Apache-2.0** (`LICENSE`) | Es el estándar de facto para A/B y verificación de firma en MCU; integrado en Zephyr |
| Descripción de hardware (MPU) | **Device tree** (`.dts`/`.dtsi`/`.overlay`), versionado con el producto | Prohibido parchear el árbol del fabricante *in situ*: se usa `.dtsi` propio y overlays |
| OTA en Linux embebido | **RAUC** (v1.15.x, **LGPL-2.1**) o **SWUpdate** (2026.05.x, **GPL-2.0**) | Ambos hacen A/B con verificación de firma. **La licencia importa**: LGPL frente a GPL cambia lo que se puede enlazar |
| OTA gestionada / campañas | **Eclipse hawkBit** (**EPL-2.0**) como servidor de despliegue; **Mender** (cliente **Apache-2.0**, Northern.tech) si se quiere producto integrado | Verificar **siempre** qué parte del servidor es abierta y cuál es de pago antes de comprometer arquitectura |
| Toolchain | Fijada por versión exacta y **ejecutada dentro de contenedor o `kas`** | Un build que dependa del `gcc` del portátil del desarrollador no es reproducible ni auditable |

**Reproducibilidad del build**: la versión de toolchain, de las capas/paquetes y de las fuentes se
fija (`SRCREV` explícito, nunca ramas móviles; `BR2_DOWNLOAD_...` con hash). El build **produce y
archiva el manifiesto**: qué versión de cada componente entró en esa imagen. Sin ese manifiesto no se
puede responder "¿está mi flota afectada por este CVE?", que es la pregunta que llegará. El SBOM
deja de ser higiene y pasa a ser obligación regulatoria (§5.4).

## 3. Estructura y convenciones

- **Separación estricta**: `app/` (lógica de producto, portable y testeable en host) — `hal/`
  (acceso a periférico, la única capa que conoce el registro) — `board/` (pinout, device tree,
  overlays, `defconfig`). La lógica de producto **no incluye cabeceras del fabricante**: si lo hace,
  no hay tests en host y no hay portabilidad al siguiente silicio.
- **Configuración en Kconfig/`prj.conf`/`defconfig`, versionada**, nunca en `#define` dispersos ni en
  flags de compilación pasados a mano. Un `defconfig` por variante de producto, diffeable.
- **Mapa de memoria explícito en el linker script**: regiones, tamaño de pila por tarea, sección
  `.noinit` para lo que debe sobrevivir al reset (causa del último reset, contador de arranques
  fallidos). El *high-water mark* de cada pila se mide, no se estima.
- **Particionado A/B desde el primer día**, aunque la primera versión no tenga OTA. Añadir A/B
  después obliga a un *update* de particionado en campo, que es exactamente la operación que no se
  puede hacer con seguridad. Layout mínimo: bootloader (inmutable o actualizable por separado y con
  extremo cuidado) + slot A + slot B + datos persistentes + almacén de estado del arranque.
- **La causa del reset se lee y se persiste en cada arranque** (registro de reset del MCU, `bootcount`
  en U-Boot). Un dispositivo que no sabe por qué se reinició no se puede diagnosticar en campo.
- **El reloj es un problema, no un dato**: sin RTC con batería, tras un corte de corriente el
  dispositivo no sabe la fecha — y sin fecha, la validación de certificados TLS falla o, peor, se
  desactiva. Se decide explícitamente: RTC respaldado, NTP/`chrony` con arranque tolerante, o
  validación de certificado sin dependencia de reloj (tiempo mínimo persistido monotónicamente).

## 4. Calidad y testing

En orden de coste creciente; los tres primeros son **gates que rompen el build**:

1. **Compilación limpia con warnings como errores** para todas las variantes de `defconfig` del
   producto, no solo la que usa el desarrollador. Añadir una variante y no meterla en CI es garantía
   de que se romperá en silencio.
2. **Tests unitarios en host** de toda la lógica de producto, con el HAL sustituido por un doble.
   Si el porcentaje de código testeable en host es bajo, el problema es la arquitectura (§3), no el
   test. `twister` en Zephyr para ejecutar la suite en `native_sim` y en emulación.
3. **Análisis estático y disciplina de memoria**: el conjunto concreto de herramientas y flags es de
   `c-standards`/`cpp-standards`/`rust-standards`; **lo que esta skill exige es la comprobación de que
   no hay asignación dinámica donde se prohibió** (ver §7) y que el uso de pila está acotado y medido.
4. **Emulación**: Renode o QEMU para ejecutar el firmware completo en CI sin hardware. Es lo que
   permite tener CI de verdad en un proyecto embebido; sin ella el CI se limita a "compila".
5. **Hardware-in-the-loop** con un banco de placas reales y sonda de depuración, ejecutando la suite
   sobre el binario firmado que se va a distribuir. **Aquí es donde se prueba la actualización.**
6. **Prueba de actualización obligatoria en CI, y no es negociable**: (a) A→B correcto; (b) **corte de
   alimentación en mitad de la escritura**, en varios puntos, y arranque posterior correcto; (c)
   imagen corrupta o con firma inválida → rechazada; (d) imagen válida que arranca y **no confirma**
   → *rollback* automático al slot anterior; (e) actualización **desde la versión más antigua en
   campo**, no solo desde la anterior. Un OTA que solo se ha probado en el camino feliz no está
   probado.
7. **Longevidad**: prueba de 72 h o más con el ciclo real de trabajo, vigilando fragmentación (si hay
   heap), fugas de descriptores, desbordamiento de contadores y deriva del reloj.

## 5. Seguridad del stack

### 5.1 Arranque seguro y cadena de confianza
- **Raíz de confianza inmutable en el silicio** (ROM del fabricante), que verifica el bootloader, que
  verifica la aplicación. La cadena se rompe en el primer eslabón que no verifica al siguiente: un
  bootloader firmado que carga una aplicación sin comprobar firma **no aporta nada**.
- **Los fusibles se queman en producción, no en el banco**: activar arranque seguro es irreversible.
  El proceso de provisión se ensaya completo en unidades de sacrificio antes de tocar la línea.
- **Contador de anti-*rollback*** para impedir que un atacante instale una versión anterior con un
  fallo conocido. Un A/B con firma pero sin anti-rollback es un mecanismo de downgrade asistido.
- Las claves de firma de firmware viven en **HSM o servicio de firma**, no en el CI ni en un portátil.
  La rotación de la clave de firma se diseña **antes** del primer envío: si no se puede rotar, la
  primera filtración obliga a retirar el producto.

### 5.2 Identidad y almacén de claves
- **Una clave única por dispositivo, sin excepciones.** Una clave compartida en toda la flota es el
  fallo de diseño clásico y su consecuencia es conocida: la extracción de un solo aparato de un
  cajón compromete el parque entero, y **no hay rotación posible sin tocar todas las unidades**. Lo
  mismo aplica a contraseñas por defecto idénticas — es literalmente la primera recomendación de
  ETSI EN 303 645 (§5.4).
- **Dónde vive la clave privada, en orden de preferencia**: elemento seguro dedicado (ATECC608, SE050)
  o TPM 2.0 → enclave del propio SoC (TrustZone-M con `CMSE`, TrustZone-A con mundo seguro) → región
  de flash protegida con lectura deshabilitada → *(inaceptable)* fichero en el sistema de ficheros o
  constante en el binario. **El criterio real: la clave privada nunca sale del elemento; se usa allí
  dentro.** Si el diseño la lee a RAM para firmar, no hay almacén seguro, hay un cajón.
- **La identidad se inyecta en fabricación** con un proceso auditado: quién la generó, dónde está el
  registro de qué serie tiene qué certificado, y cómo se revoca una unidad concreta. Si no existe
  procedimiento de revocación por dispositivo, no hay identidad, hay decorado.
- Cifrado y algoritmos: **es decisión de `cryptography-pki-standards`**. Lo que esta skill impone es
  que el MCU **tenga acelerador o presupuesto de ciclos** para lo que se elija, verificado con medida,
  y que el generador de aleatoriedad sea un TRNG del silicio — **no** un `srand(time())`, que en un
  aparato sin RTC produce la misma semilla en toda la flota.

### 5.3 Superficie de depuración en producción
- **JTAG/SWD deshabilitado o bloqueado por fusible en la unidad de producción.** Un puerto de
  depuración abierto es lectura completa de la flash, extracción de claves y modificación del
  firmware con acceso físico de diez minutos.
- **Consola serie**: sin *shell* interactiva, sin `root` sin contraseña, sin `bootdelay` que permita
  interrumpir U-Boot y editar `bootargs` — **interrumpir el arranque y añadir `init=/bin/sh` es el
  ataque de manual**. Si se deja consola para diagnóstico, es de solo lectura y autenticada.
- **La reactivación de la depuración, si es necesaria para RMA, se hace por reto-respuesta firmado**
  contra la identidad del dispositivo, nunca por una contraseña maestra común.
- Trazas y logs: **el firmware no imprime secretos, claves, tokens ni identificadores completos** —
  ni por UART, ni en el fichero de log, ni en el volcado de fallo que se sube a la nube.

### 5.4 Marco regulatorio — el dato que más decide y peor se cita

Verificado a agosto de 2026, de fuente oficial. **Re-verificar siempre: estas fechas se han movido ya
una vez.**

- **Cyber Resilience Act — Reglamento (UE) 2024/2847.** Fuente: `digital-strategy.ec.europa.eu`,
  verbatim: *"The CRA entered into force on 10 December 2024."* y *"The main obligations introduced by
  the Act will apply from 11 December 2027, with reporting obligations to apply as of 11 September
  2026."* Adicionalmente, el capítulo de **notificación de organismos de evaluación de la conformidad
  aplica desde el 11 de junio de 2026**. Consecuencias de diseño, no de papeleo: obligación de
  gestionar vulnerabilidades durante el **periodo de soporte** declarado, **SBOM**, canal de
  divulgación de vulnerabilidades, **actualizaciones de seguridad** — y notificación de vulnerabilidad
  activamente explotada e incidente grave a ENISA y al CSIRT nacional **ya en 2026**. Alcance: todo
  *producto con elementos digitales* puesto en el mercado de la UE, no solo IoT de consumo.
- **RED — Directiva 2014/53/UE, artículo 3.3 (d), (e) y (f)**, activados por el **Reglamento Delegado
  (UE) 2022/30**. La fecha original de aplicación (1 de agosto de 2024) **se pospuso doce meses** por
  el Reglamento Delegado (UE) 2023/2444: **son de aplicación desde el 1 de agosto de 2025**. Cubren
  protección de la red (d), datos personales y privacidad (e) y protección frente al fraude (f).
  Normas armonizadas: **EN 18031-1/-2/-3**, citadas en el DOUE con **restricciones** (Decisión (UE)
  2025/138); donde esas condiciones no se cumplen, **no hay presunción de conformidad** y hace falta
  organismo notificado. Se espera que la RED-DA sea derogada al aplicar plenamente el CRA en 2027 —
  **verificarlo antes de planificar sobre esa suposición**.
- **ETSI EN 303 645** — versión vigente **V3.1.3 (2024-09)**. Es el baseline de ciberseguridad de IoT
  de consumo: sin contraseñas por defecto, política de divulgación de vulnerabilidades, software
  actualizado. **No es una norma armonizada de la RED por sí misma** y no define método de ensayo —
  para eso está **ETSI TS 103 701**. Usarla como *checklist* de diseño es correcto; presentarla como
  prueba de conformidad regulatoria, no.
- **Consecuencia de arquitectura**: el periodo de soporte declarado bajo el CRA fija **cuántos años
  hay que poder emitir firmware nuevo para ese hardware**. Eso decide hoy el tamaño de flash (debe
  caber una imagen mayor dentro de años), la elección de LTS del RTOS o de la distribución, y si el
  silicio elegido seguirá teniendo BSP mantenido. **Es una decisión de ingeniería con fecha legal.**

## 6. Rendimiento y operabilidad

- **Presupuesto de energía escrito antes de escribir código**: corriente por modo (activo, *sleep*,
  *deep sleep*), tiempo en cada modo por ciclo de trabajo, y consumo medio resultante frente a la
  capacidad de la batería. Se **mide** con analizador de corriente o contador de coulombios sobre el
  hardware real — un presupuesto calculado con las cifras de la hoja de datos siempre sale mejor que
  la realidad. Lo que arruina el presupuesto casi nunca es el MCU: es la **radio** y un periférico
  que se quedó alimentado.
- **Watchdog independiente activado siempre en producción**, alimentado desde un único punto que solo
  se alcanza si **todas** las tareas han reportado vida. Un `wdt_feed()` en una ISR periódica no
  vigila nada: sobrevive perfectamente a una aplicación colgada. El watchdog **no se deshabilita
  para depurar** en la imagen de producción, y el número de resets por watchdog es telemetría de
  primer nivel.
- **`printf` por UART cuesta lo que no está escrito**: bloquea, puede alterar el *timing* que se
  intenta depurar (heisenbug), consume flash en formateo y a menudo deja secretos en el cable. En
  camino crítico se usa **trazado con marcas** (`ITM`/SWO, GPIO conmutado y analizador lógico, o log
  binario diferido con desreferencia en el host). El log textual queda para el arranque y los errores.
- **Telemetría mínima que debe subir el dispositivo**: versión de firmware, causa del último reset,
  contador de resets por watchdog, *high-water mark* de pila, resultado del último intento de
  actualización, y estado de la conectividad. Sin eso, la flota es opaca y el primer OTA fallido se
  descubre por el servicio de atención al cliente.
- **Despliegue de OTA por fases obligatorio**: canario (decenas de unidades) → porcentaje creciente →
  flota. **Con criterio de parada automático** ligado a la telemetría anterior: si el ratio de
  arranques confirmados cae, la campaña se detiene sola. Y el aparato **jamás se actualiza con la
  batería por debajo del umbral** ni durante una operación crítica.
- **Degradación con red caída**: el dispositivo tiene que funcionar sin conexión. Reintentos con
  *backoff* y *jitter* — **el jitter no es un detalle**: diez mil aparatos que reintentan al mismo
  segundo tras un corte tumban el backend con un ataque de denegación de servicio propio.

## 7. Sostenibilidad a largo plazo y prohibiciones

- **Cadencia**: seguir la rama **LTS** del RTOS o de la distribución (Zephyr 3.7 LTS hasta 2029;
  Yocto Wrynose 6.0 hasta 2030; Buildroot LTS bienal con 3 años) y **actualizar de LTS a LTS con un
  proyecto planificado**, no de golpe cuando salte un CVE crítico. Quedarse en una rama sin soporte
  es incompatible con el periodo de soporte declarado bajo el CRA.
- **Fin de vida declarado y publicado**: fecha hasta la que habrá firmware de seguridad, qué pasa
  después con el servicio en la nube del que depende el aparato, y si el dispositivo sigue siendo útil
  sin él. Un producto que se convierte en ladrillo el día que se apaga el backend es un problema
  regulatorio y reputacional, no una decisión de negocio limpia.

Prohibiciones explícitas:
- ❌ **Dispositivo sin vía de actualización remota probada.** Es el veto número uno de esta skill.
- ❌ **Clave, contraseña o certificado compartidos por toda la flota**, incluidas las "de fábrica" y
  las "solo para desarrollo" que acaban en producción. PROHIBIDO.
- ❌ **Actualización sin A/B ni rollback automático**, o con rollback que depende de que alguien pulse
  algo. PROHIBIDO escribir sobre la única copia arrancable.
- ❌ **Firmware sin firmar, o firmado con clave que no se puede rotar.** PROHIBIDO validar solo un
  CRC o un hash sin firma: un hash no autentica nada.
- ❌ **JTAG/SWD activo, `bootdelay` interrumpible o shell de U-Boot accesible en unidad de producción.**
- ❌ **`malloc`/`free` en tiempo de ejecución en firmware de MCU.** Toda la memoria se reserva estática
  o en arenas de tamaño fijo en el arranque; sin MMU, la fragmentación no es recuperable y el fallo
  aparece semanas después en campo, sin traza. Si un componente de terceros exige heap, se le asigna
  una arena acotada y se prohíbe que crezca. Excepción justificable y documentada: asignación
  **exclusivamente durante la inicialización**, que después nunca se libera.
- ❌ **Recursividad no acotada, VLA y `alloca` en firmware** — desbordan la pila sin aviso.
- ❌ **Bloquear dentro de una ISR** (esperas activas, `printf`, tomar un mutex que puede dormir).
- ❌ **Watchdog deshabilitado o alimentado desde un temporizador ciego** en la imagen de producción.
- ❌ **Depender de que el usuario final actualice**: la actualización es automática por defecto, con
  campaña gestionada. Un modelo "opt-in" produce una flota mayoritariamente sin parchear.
- ❌ **Ramas móviles en el build** (`master`, `main`, `latest`) para cualquier fuente, capa o
  contenedor de toolchain. PROHIBIDO: mata la reproducibilidad y con ella el análisis de impacto de
  CVE.
- ❌ **Parchear el BSP del fabricante *in situ*** en lugar de mantener capa/overlay propio: bloquea
  toda actualización futura del BSP.
- ❌ **Certificados TLS con validación desactivada** "porque el reloj falla al arrancar". El problema
  es el reloj (§3), y se resuelve ahí.
- ❌ **Telemetría con identificador personal o de localización sin base legal y sin minimización** —
  aquí entra el artículo 3.3(e) de la RED y el RGPD, no solo el buen gusto.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar en la web —**esta lista es corta a propósito: es
lo que cambia y lo que se cita mal**:

1. **Fechas del CRA (Reglamento (UE) 2024/2847)** en `digital-strategy.ec.europa.eu` y en EUR-Lex, y
   si algún acto posterior (paquetes ómnibus, actos de ejecución) ha movido plazos, ampliado
   exenciones o precisado categorías de productos importantes/críticos.
2. **Estado de la RED-DA**: si el Reglamento Delegado (UE) 2022/30 sigue vigente o ya ha sido
   derogado por la aplicación del CRA, y el estado de las **restricciones** a EN 18031-1/-2/-3 en el
   DOUE (Decisión (UE) 2025/138 o su sucesora).
3. **Versión vigente de ETSI EN 303 645** y de ETSI TS 103 701 en `etsi.org` (a ago-2026: V3.1.3
   de 2024-09).
4. **RTOS**: última estable **y LTS vigente** de Zephyr (`docs.zephyrproject.org/latest/releases/`),
   versión de FreeRTOS Kernel, de NuttX (releases de Apache) y cadencia de Eclipse ThreadX. **La
   licencia se lee del fichero en crudo del árbol que se va a compilar** (`LICENSE`, `LICENSE.md`,
   `LICENSE.txt`, `COPYING`), no de la etiqueta que muestra GitHub.
5. **Linux embebido**: rama LTS vigente de Yocto (`wiki.yoctoproject.org/wiki/Releases`) con su fecha
   de fin de soporte, y la LTS vigente de Buildroot (`buildroot.org/lts.html`) — recordando que **el
   desarrollo de Buildroot está en GitLab, no en GitHub**.
6. **Bootloader y OTA**: última de U-Boot en `ftp.denx.de/pub/u-boot/`, de MCUboot, RAUC y SWUpdate, y
   **qué parte del servidor de campañas es abierta y cuál es comercial** antes de comprometer
   arquitectura.
7. **CVE del árbol embarcado** (RTOS, pila TCP/IP, TLS, bootloader) y si la rama que se usa recibe el
   parche o solo lo recibe la siguiente.
8. **Estado del silicio elegido**: si el fabricante mantiene el BSP y hasta cuándo, y si hay aviso de
   fin de producción (PCN/EOL) del propio chip — un producto con periodo de soporte declarado a diez
   años sobre un MCU que se descataloga en dos es una decisión que hay que tomar sabiéndola.

**Huecos declarados**: el texto íntegro de EN 18031-1/-2/-3 y de ETSI TS 103 701 es de pago o de
acceso restringido; sus requisitos concretos **no se han verificado verbatim** en este documento y
deben leerse de la norma comprada antes de afirmar conformidad. Las cifras de consumo, latencia y
tamaño no se dan aquí porque **dependen enteramente del silicio y del ciclo de trabajo**: se miden en
el hardware, no se citan.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
