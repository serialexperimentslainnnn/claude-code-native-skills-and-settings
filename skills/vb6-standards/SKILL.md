---
name: vb6-standards
description: Visual Basic 6.0 legacy applications - freeze, isolate or rewrite. Use when working with .vbp/.vbg/.frm/.frx/.bas/.cls/.ctl/.dsr project and form files, the VB6 IDE (VB6.EXE) or its command-line compiler, msvbvm60.dll and the VB6 runtime redistributable, MSCOMCTL.OCX/COMCTL32.OCX/MSCOMM32.OCX/MSWINSCK.OCX/RICHTX32.OCX and other OCX or ActiveX controls, regsvr32 component registration, binary compatibility and interface GUID churn, Declare Function Lib for Win32 API P/Invoke, ADO/DAO/RDO data access, Err.Number and On Error GoTo, 32-bit-only processes under WOW64, VB6 apps on Windows Server 2019/2022/2025, and when evaluating VB6-to-.NET converters, application virtualization or containerized Windows isolation for a frozen VB6 build.
---

# Estándares Visual Basic 6.0 (legacy)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplicaciones **VB6 nativas** (sin CLR) todavía en producción: mantenimiento, congelación,
aislamiento y salida. Triggers: `.vbp`, `.vbg`, `.frm`, `.frx`, `.bas`, `.cls`, `.ctl`,
`msvbvm60.dll`, `VB6.EXE`, `regsvr32`, `.ocx`, compatibilidad binaria, `Declare Function Lib`,
ADO/DAO/RDO, `On Error GoTo`.

**El malentendido central es "funciona, luego está soportado".** No. Están soportadas dos cosas
distintas y hay que separarlas quirúrgicamente. Microsoft (*Support Statement for Visual Basic
6.0*, rev. 18-dic-2024), **verbatim**:

> "Microsoft's goal is "It Just Works" compatibility for pre-existing Visual Basic 6.0 applications
> on supported Windows versions. **The Visual Basic 6.0 runtime will be supported for the support
> lifetime of Windows versions.** The support bar is limited to serious regressions and critical
> security issues for existing applications."

Y el otro lado, el que decide:

> "VB6 development is no longer supported. This support statement does not change the support
> policy for the Visual Basic IDE. **The Visual Basic 6.0 IDE and Visual Studio 6.0 IDE are no
> longer supported as of April 8, 2008.** Because there is no supported method to create or maintain
> Visual Basic 6 applications, **Microsoft strongly recommends that you replace your applications
> with modern technology.**"

Traducido a criterio: **el binario que ya existe se ejecuta con soporte; el acto de modificarlo no
está soportado por nadie.** No hay parches del compilador ni del IDE desde 2008. Cada cambio de
código en una app VB6 se hace con una herramienta sin soporte, en una máquina que probablemente no
se puede reinstalar limpiamente. **Ese es el riesgo real: el entorno de compilación, no el
lenguaje.**

La tabla oficial de sistemas operativos confirma el patrón en todas las filas —Windows 11, 10, 8.1
SP1, 7 SP1, Server 2025, 2022, 2019, 2016, 2012 R2, 2012, 2008 R2— con **"Supported"** en *VB6
Runtime Files in OS* y *VB6 Runtime Extended Files*, y **"Not Supported"** en *VB6 IDE*, sin una
sola excepción. Dos notas que se ignoran a menudo, verbatim: *"For Windows Server, only 64-bit
editions are supported. Server Core is not supported."*

**No aplica**: `vbnet-standards` (**VB.NET es otro lenguaje sobre el CLR**; la similitud sintáctica
es la trampa más cara de este dominio — un `.vb` no es un `.bas`),
`dotnet-framework-legacy-standards` (.NET Framework 4.x, WebForms, WCF: el destino habitual de una
reescritura *dentro* del mundo Microsoft, y el dueño del criterio de interop COM desde .NET),
`dotnet-standards` (**.NET moderno: si la reescritura acaba ahí, el código resultante se rige por
su criterio, no por el de aquí**), `classic-asp-standards` (VBScript en servidor — la propia
declaración de soporte de VB6 dice **verbatim**: *"VBScript is unrelated to Visual Basic 6.0 and
this support statement"*).
`legacy-modernization-standards`: decisión de cartera invertir/migrar/
retirar —aquí el criterio técnico—, con `enterprise-architecture-standards`,
`project-management-standards`, `tech-leadership-standards`, `refactoring-tech-debt-standards`
(*strangler fig*) y `testing-qa-standards`. Infra y encierro: `vmware-standards`/`hyper-v-standards`
(**el host que sostiene la VM congelada — la pieza operativa clave de este dominio**),
`windows-server-ad-standards`, `powershell-standards`, `backup-recovery-standards` (la imagen de la
máquina de build **es** un activo a respaldar), `sqlserver-dba-standards` y `sql-standards`.
Seguridad: `appsec-standards`, `vulnerability-management-standards`, `firewall-policy-standards`
(el aislamiento de red que §5 exige), `grc-compliance-standards`.

## 2. Qué está soportado y qué no — decisiones por defecto

> Verificar por web antes de fijarlo (§8): la declaración se actualiza al salir versiones de Windows.

| Pieza | Estado oficial | Criterio |
|---|---|---|
| Runtime en el SO (`msvbvm60.dll` y lista de redist) | Soportado mientras dure el Windows anfitrión | El reloj es el **EOL del Windows**, no el de VB6 |
| *Runtime extended files* (OCX de la lista, incl. `MSCOMCTL.OCX`, `COMCTL32.OCX`, `MSWINSCK.OCX`, `RICHTX32.OCX`) | Soportados, **pero los distribuye la aplicación**, no el SO | Versionar el redist junto al instalador; no confiar en lo que haya en la máquina |
| Controles de la lista *unsupported* (`threed32.ocx`, `grid32.ocx`, `mschart.ocx`, `msoutl32.ocx`…) | **No soportados** | Sustituir o encapsular; son un bloqueo duro para certificar el SO |
| IDE VB6 / VS6 | **No soportado desde 8-abr-2008**, en ningún Windows de la tabla | Ningún plan puede depender de "recompilamos si hace falta" sin resolver §3 |
| Controles de terceros | Fuera de soporte de Microsoft | *"Microsoft is unable to provide support for third party components, such as OCX/ActiveX controls."* |
| 64 bits | *"supported only in the WOW emulation environment"* | La app es **32 bits para siempre**: sin acceso a >4 GB, sin drivers ni ODBC de 64 bits |
| Server Core / ediciones 32-bit de Server | **No soportado** | Descarta hardening por minimización del SO |
| VBA que hospeda el runtime VB6 | Soportado solo si SO, Office **y** el fichero concreto lo están, a la vez | Tres relojes distintos: el más corto manda |

**Corrección de una suposición frecuente**: `MSCOMCTL.OCX` **no está muerto** — figura en la lista
oficial de *"Supported runtime files to distribute with your application"*. Lo que sí está muerto es
media docena de controles antiguos de VB4/VB5 y **todo lo de terceros**. Antes de declarar un
control inviable, comprobarlo contra la tabla real de la declaración de soporte, no de memoria.

## 3. El problema del entorno de compilación (el riesgo de verdad)

Una aplicación VB6 en producción no falla porque el lenguaje sea viejo: falla el día que hay que
tocarla y nadie puede reconstruir la máquina que la compila. Reglas duras:

- **La máquina de build es un activo de producción.** Debe existir **al menos** como imagen de VM
  versionada, con respaldo probado (`backup-recovery-standards`) y capacidad de arrancar en el
  hipervisor actual (`vmware-standards`/`hyper-v-standards`). Una máquina física única bajo una mesa
  es un incidente esperando fecha.
- **Documentar el entorno como inventario, no como recuerdo**: versión exacta del IDE y service pack,
  cada OCX de terceros con su versión y su origen, las claves de registro que su registro crea, el
  orden de instalación, y las licencias de diseño de los controles comerciales (muchos exigen una
  clave que solo vive en el registro de esa máquina). Ese documento es lo que separa "podemos
  parchear" de "no podemos".
- **El resultado de la compilación debe ser comparable**: guardar el binario compilado de cada
  versión entregada junto al código, para poder verificar que una recompilación futura produce algo
  equivalente. Sin eso, no hay forma de saber si la máquina se ha degradado.
- El código fuente va en **Git** igual que cualquier otro (`git-workflow-standards`): `.frx` y demás
  son binarios, tratarlos como tales; nada de carpetas con sufijos de fecha.

**Compatibilidad binaria y GUID**: el proyecto debe estar en **compatibilidad binaria** (*binary
compatibility*) contra el último binario entregado, no en "compatibilidad de proyecto" ni "sin
compatibilidad". Si no, cada recompilación genera **GUID de interfaz nuevos**, y todo cliente COM
registrado contra la versión anterior deja de encontrar el componente. Es la avería clásica de este
dominio: se recompila "sin cambios", se despliega y el sistema deja de hablar consigo mismo. El
binario de referencia se versiona y se guarda como parte del artefacto.

**Registro de componentes**: registrar OCX/DLL con `regsvr32` es estado global de la máquina.
Cualquier despliegue debe ser **idempotente y reversible**, y estar escrito (instalador o script
`powershell-standards`), nunca en la cabeza de nadie. El *DLL hell* de versiones distintas del mismo
OCX en máquinas distintas es la causa dominante de "en mi máquina funciona".

## 4. Calidad y testing

No hay toolchain moderna aquí (linter, analizador, formateador: no existen para VB6 en estado
soportado), así que **esta sección se reduce a lo único que sí aplica**: antes de tocar una línea,
**caracterizar el comportamiento observable** con pruebas de extremo a extremo sobre la aplicación
tal cual está (entradas → salidas, ficheros, estado en base de datos). La estrategia la fija
`testing-qa-standards`. Sin esa red, ni un cambio menor es defendible: no hay compilador estricto ni
suite que avise, y `On Error Resume Next` repartido por el código oculta los fallos que provoques.

## 5. Seguridad del stack

**Regla dura: una aplicación VB6 no debe atender tráfico de internet.** Ni directamente ni detrás de
un proxy que "ya filtra". Es código compilado con herramientas sin parches desde 2008, sin
mitigaciones modernas garantizadas (ASLR/DEP/CFG dependen de flags que ese enlazador no pone), con
manejo de cadenas propenso a desbordamiento en las llamadas `Declare Function Lib` a la API Win32, y
sin nadie que vaya a publicar un parche si aparece un fallo del compilador.

- **Aislamiento por defecto**: red segmentada, alcanzable solo desde clientes internos identificados,
  regla *default-deny* de entrada **y de salida** (`firewall-policy-standards`). Si necesita
  publicarse, se publica **un servicio moderno delante** que hable con ella, no ella.
- **`MSWINSCK.OCX` (Winsock) escuchando en un puerto** es exactamente el escenario prohibido: parser
  de protocolo escrito en VB6 expuesto a red.
- **SQL por concatenación** es el patrón dominante en este código. Corrección real: `ADODB.Command`
  con `CreateParameter`/`Parameters.Append` tipado; nunca `"... WHERE id=" & Text1.Text`. Ver
  `sql-standards`.
- **Credenciales** incrustadas en el `.bas` o en un `.ini` junto al ejecutable son lo normal aquí. Un
  binario VB6 se descompila con facilidad: todo lo que esté ahí está publicado. Sacarlas
  (`secrets-management-standards`) y **rotarlas**, asumiendo que ya se conocen.
- **Privilegios**: suelen exigir escribir en `Program Files` o `HKLM`, y "se arreglan" dándoles
  administrador. PROHIBIDO. Redirigir a rutas de usuario o aislar en su propia VM/sesión.
- **Dependencias sin escáner**: los OCX de terceros no aparecen en ningún SCA. Entran a mano en el
  inventario de `vulnerability-management-standards`; un control cuyo fabricante ya no existe es un
  riesgo aceptado explícitamente, no un olvido.

## 6. Operación

- **Congelar y aislar** es legítimo y a menudo lo correcto (§7): VM dedicada, *snapshot* antes de
  cualquier cambio, imagen respaldada con restauración probada, sin actualizaciones automáticas que
  rompan un OCX, y el **EOL del Windows anfitrión** como única fecha del registro de riesgos.
- 32 bits sobre Windows de 64: WOW64. A planificar: el ODBC de 32 bits se configura con
  `%SystemRoot%\SysWOW64\odbcad32.exe`, el registro va a `HKLM\SOFTWARE\WOW6432Node`, y **no se puede
  cargar ningún componente de 64 bits en ese proceso** — drivers de base de datos modernos incluidos.
- Contenedorización de Windows y virtualización de aplicaciones **empaquetan y aíslan** el binario,
  no lo modernizan: hacen el despliegue reproducible y lo desacoplan del SO anfitrión. Verificar
  antes que los OCX se registran en el contenedor y que la app no necesita escritorio interactivo.

## 7. Salida, prohibiciones y cuándo congelar en vez de migrar

**No existe una ruta mecánica buena, y decirlo pronto ahorra un año.** Los conversores VB6→.NET
producen código que compila y que **hay que reescribir igualmente**: las formas quedan como
formularios generados incomprensibles, `On Error` se traduce a `try/catch` inútiles, la lógica sigue
en los manejadores de eventos y el modelo COM se arrastra. El asistente de actualización de las
primeras versiones de Visual Studio ya se retiró. Presupuestar una conversión automática como si
fuera la migración es el error clásico.

Opciones reales, en orden de coste creciente: **(a) congelar y aislar**; **(b) empaquetar/virtualizar
o contenerizar** el binario para desacoplarlo del SO; **(c) *strangler fig*** — poner un servicio
moderno delante y mover funcionalidad módulo a módulo, dejando la app VB6 como motor menguante;
**(d) reescritura** completa, con la app viva y contrastando comportamiento contra ella.

**Congelar y aislar** es la respuesta correcta cuando: la aplicación es estable y sin roadmap; el
Windows anfitrión sigue soportado y con fecha lejana; se puede aislar de red por completo; y existe
—o se puede reconstruir— el entorno de compilación por si aparece un parche urgente. **Migrar** es
obligatorio cuando hay evolución funcional pendiente, exposición de red que no se puede eliminar,
dependencia de controles no soportados o de terceros muertos, o el Windows entra en cuenta atrás.

- ❌ PROHIBIDO exponer una aplicación VB6 a internet, directamente o vía *port forwarding*.
- ❌ PROHIBIDO desarrollo **nuevo** en VB6. Se mantiene lo que hay; lo nuevo se escribe fuera.
- ❌ PROHIBIDO recompilar sin **compatibilidad binaria** contra el último binario entregado.
- ❌ PROHIBIDO que exista una única máquina de build sin imagen versionada y restauración probada.
- ❌ PROHIBIDO SQL por concatenación; parámetros ADO tipados.
- ❌ PROHIBIDO ejecutar la aplicación como administrador para evitar arreglar sus rutas/permisos.
- ❌ PROHIBIDO credenciales incrustadas en el código o en `.ini` junto al ejecutable.
- ❌ PROHIBIDO `On Error Resume Next` en código nuevo o modificado.
- ❌ PROHIBIDO presentar la salida de un conversor VB6→.NET como una migración terminada.
- ❌ PROHIBIDO decir "VB6 está soportado" sin la distinción runtime/IDE de §1: es media verdad y
  lleva a planificar mal.
- ❌ PROHIBIDO tocar el código sin caracterización previa del comportamiento (§4).

## 8. Verificación web obligatoria

Comprobar siempre: la **declaración de soporte de VB6** vigente (se actualiza al salir nuevas
versiones de Windows — verificar si la tabla ya incluye el SO del parque y si sigue diciendo *"Not
Supported"* para el IDE); la **fecha de fin de soporte del Windows anfitrión**, que es el único reloj
real; qué ficheros siguen en la lista de *runtime extended files* soportados frente a la de *no
soportados*; el estado del fabricante de cada OCX de terceros; CVEs de los componentes COM del
inventario.

**Huecos declarados (sin dato verificado, NO rellenar de memoria)**: no verificado a ago-2026 si
existe declaración alguna de Microsoft sobre soporte del runtime VB6 en versiones de Windows
posteriores a las listadas en la tabla —**la ausencia de una fila no es una promesa ni una
negación**, se consulta la declaración actualizada—; estado de mantenimiento y calidad real de
salida de los conversores VB6→.NET comerciales; viabilidad concreta de contenedorizar una aplicación
VB6 con OCX registrados (depende de cada control: probar, no suponer); número de aplicaciones VB6 en
producción o cuota de mercado — no hay cifra pública fiable, no citar ninguna.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
