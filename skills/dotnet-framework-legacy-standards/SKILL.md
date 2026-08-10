---
name: dotnet-framework-legacy-standards
description: .NET Framework 4.x legacy maintenance and the migration decision to modern .NET. Use when a project targets net45/net461/net462/net472/net48/net481, an old-style non-SDK .csproj/.vbproj with <TargetFrameworkVersion> and AssemblyInfo.cs, packages.config, web.config or app.config with system.web/system.serviceModel/machineKey/bindingRedirect sections, Global.asax, .aspx/.ascx/.asmx/.svc files, ASP.NET WebForms or MVC5 on System.Web, WCF ServiceHost and ServiceContract on the server side, Windows Workflow Foundation, .NET Remoting, AppDomain.CreateDomain, BinaryFormatter, the GAC and gacutil, COM interop with tlbimp/regasm, msbuild.exe with v4.0.30319 or Visual Studio 2019 solutions, and when deciding on .NET Upgrade Assistant, try-convert, SDK-style migration, PackageReference, .NET Standard 2.0 shims or CoreWCF.
---

# Estándares .NET Framework legacy (4.x)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Mantenimiento de aplicaciones sobre **.NET Framework 4.x** y **la decisión de migrar o no** a .NET
moderno. Triggers: TFM `net45`–`net481`, `.csproj`/`.vbproj` no SDK-style con
`<TargetFrameworkVersion>`, `packages.config`, `web.config`/`app.config` con `system.web`,
`system.serviceModel`, `machineKey` o `bindingRedirect`, `Global.asax`, `.aspx`/`.ascx`/`.asmx`/`.svc`,
GAC, `regasm`/`tlbimp`, `BinaryFormatter`, `AppDomain.CreateDomain`.

**El malentendido que hay que corregir primero**: .NET Framework 4.8/4.8.1 **NO está fuera de
soporte** — es un componente del SO y hereda su ciclo de vida (§2). No es un detalle burocrático: es
**la razón económica por la que nadie migra**, y cualquier plan que se venda como "hay que salir
porque muere el año que viene" es falso y se cae en la primera revisión. El argumento real es otro:
rendimiento, contratación, ecosistema de paquetes y que **la plataforma no recibe features nuevas**.

**.NET Framework y .NET moderno no son la misma plataforma en versiones distintas**: difieren en
runtime, despliegue y superficie de API. Migrar es **portar**, no actualizar — trátalo como tal en
el plan, la estimación y la prueba.

**No aplica**: `dotnet-standards` decide **todo .NET moderno** —SDK, TFM `net10.0`, LTS,
ASP.NET Core, EF Core, NuGet, publicación, Native AOT, contenedores— **y, críticamente, es la
dueña del destino de cualquier migración: el código que sale de aquí se rige por su criterio, no
por el de esta skill**. Aquí solo el lado 4.x y la decisión de cruzar.
`legacy-modernization-standards` lleva la estrategia de cartera —
invertir / migrar / retirar / congelar—; aquí el criterio técnico de esta plataforma.
Las hermanas de este bloque: `vbnet-standards` (**el lenguaje VB.NET**, corra sobre 4.x o sobre
.NET moderno), `vb6-standards` (VB6 nativo, sin CLR) y `classic-asp-standards` (ASP con VBScript
en IIS) — comparten ecosistema Microsoft, no plataforma.
Decisión y encuadre: `enterprise-architecture-standards`, `refactoring-tech-debt-standards`
(*strangler fig*), `testing-qa-standards`, `project-management-standards`,
`tech-leadership-standards`. Infra y operación: `web-app-servers-standards` (IIS como servidor —sitios, *app pools*, ARR, TLS del *listener*—; aquí solo lo que
el `web.config` de la app decide), `windows-server-ad-standards`, `powershell-standards`,
`sqlserver-dba-standards` y `sql-standards`, `vmware-standards`/`hyper-v-standards` (el host de la
VM congelada), `cicd-standards`, `git-workflow-standards`. Seguridad y cumplimiento:
`appsec-standards`, `vulnerability-management-standards`, `secrets-management-standards`,
`grc-compliance-standards`, `opensource-licensing-standards`.

## 2. Estado de soporte — el dato caro

> Verificar por web antes de fijarlo en cualquier documento con consecuencias (§8).

Declaración oficial (Microsoft Learn, *Lifecycle FAQ - .NET Framework*), **verbatim**:

> "Beginning with version 4.5.2 and later, .NET Framework is defined as a component of the Windows
> operating system (OS). Components receive the same support as their parent products, therefore,
> .NET Framework 4.5.2 and later follows the lifecycle policy of the underlying Windows OS on which
> it is installed."

> "There is no change to the lifecycle policy for .NET Framework 4.x and its updates which continue
> to be defined as a component of the OS and assume the same lifecycle policy as the Windows
> version on which it is installed."

> "**.NET Framework 4.8:** Support for .NET 4.8 follows the Lifecycle Policy of the parent OS. […]
> We recommend customers upgrade to .NET Framework 4.8 to receive the highest level of performance,
> reliability, and security." — e idéntico para 4.8.1: *"Support for .NET 4.8.1 follows the
> Lifecycle Policy of the parent OS."*

**Consecuencia operativa**: en 4.8/4.8.1 **no hay fecha de fin de soporte propia**; manda la del
Windows de debajo, y ese es el *EOL* que va al registro de riesgos. La página de ciclo de vida deja
la columna *End Date* **vacía** para 4.7, 4.7.1, 4.7.2, 4.8 y 4.8.1.

| Versión | Fin de soporte (Microsoft Lifecycle, ago-2026) |
|---|---|
| 4.8.1 (desde 9-ago-2022), 4.8, 4.7.2, 4.7.1, 4.7 | sin fecha propia — ciclo de vida del Windows anfitrión |
| **4.6.2** | **12-ene-2027** (tabla: `1/13/2027 6:59:59 AM` PT) — *sigue vivo, pero con reloj* |
| 4.6.1, 4.6, 4.5.2 | 26-abr-2022 (retirada por firma SHA-1) |
| 4.5.1, 4.5, 4.0 | 12-ene-2016 |
| 3.5 SP1 | 9-ene-2029 (producto independiente desde Windows 10 1809 / Server 2019) |

**Discrepancia declarada**: la propia página de ciclo de vida da a 4.6.2 una *End Date* del
13/1/2027, mientras el FAQ dice que "Support for .NET 4.6.2 follows the Lifecycle Policy of the
parent OS". No son lo mismo. Ante duda, **la fecha concreta de la tabla es la que se defiende en
una auditoría**, y 4.6.2 se trata como "en cuenta atrás": actualizar in-place a 4.8/4.8.1, que el
propio FAQ declara compatible sin recompilar.

**4.8.1 no está en todos los Windows**: el FAQ lo lista solo desde Windows 10 20H2 / Windows 11 y
Windows Server 2022/2025, y añade **verbatim**: *".NET Framework 4.8.1 is supported on Windows on
Arm starting with Windows 11 only, earlier versions including all versions of Windows 10 are not
supported on Arm."* Fijar 4.8.1 sin comprobar el parque de SO es un fallo de despliegue.

**Línea base**: cualquier app 4.x en mantenimiento se lleva a **4.8** (o 4.8.1 si el parque lo
permite) y ahí se queda. Por debajo de 4.7.2 no se acepta nada nuevo.

## 3. Qué no tiene puerto (y por eso ancla el proyecto)

Documentación oficial (*".NET Framework technologies unavailable on .NET 6+"*), **verbatim** en lo
que decide:

- **App Domains** — *"Creating more app domains isn't supported, and there are no plans to add this
  capability in the future."* Sustituto: procesos separados, contenedores, `AssemblyLoadContext`.
- **.NET Remoting** — *".NET Remoting isn't supported on .NET 6+."* Además, `BeginInvoke()`/
  `EndInvoke()` sobre delegados lanzan `PlatformNotSupportedException`.
- **CAS**, ***security transparency*** (retirados como frontera de seguridad; nunca lo fueron),
  **`System.EnterpriseServices` (COM+)**, ensamblados multi-módulo, bloques `script` de XSLT.
- **Windows Workflow Foundation** — *"Windows Workflow Foundation (WF) is not supported in .NET 6+."*
  Alternativa citada por Microsoft: **CoreWF** (UiPath, MIT verificado en el `LICENSE` en crudo) —
  **es un proyecto de tercero**, no un producto de Microsoft: evaluar como dependencia.

**WCF de servidor**: la nota oficial es "Windows Communication Foundation (WCF) server can be used
in .NET 6+ by using the CoreWCF NuGet packages". **CoreWCF** es el sucesor comunitario bajo la .NET
Foundation, licencia **MIT** (verificada leyendo el `LICENSE` en crudo del repo), release más
reciente **v1.9.1 (16-jun-2026)**, y esa versión es de seguridad. Criterio: CoreWCF sirve para
**mantener el contrato SOAP existente durante el porte**, no como arquitectura de destino; el
cliente WCF (`System.ServiceModel.*`) sí tiene paquetes en .NET moderno.

**WebForms no se migra mecánicamente. No existe conversor de páginas.** `ViewState`, *postback* y
ciclo de vida de página no tienen equivalente: la UI se rehace. Ruta oficial: migración
**incremental con YARP** (*strangler fig*), ASP.NET Core delante enrutando endpoint a endpoint, con
destino Blazor Server o Razor Pages. **Estimar como reescritura de UI.**

**WinForms y WPF sí tienen puerto** y son el caso fácil: TFM `net10.0-windows` con
`<UseWindowsForms>`/`<UseWPF>`. Acotación: son **solo Windows**, y lo que dependía de
`BinaryFormatter` (portapapeles, *drag & drop*, `.resx` de tipos propios) exige cambios explícitos.

## 4. Ruta de migración (por capas, no *big bang*)

1. **Convertir a SDK-style primero, sin cambiar de TFM.** Es el paso barato y reversible: el
   proyecto sigue en `net48` y el diff se revisa. `try-convert` automatiza la mayor parte.
2. **`packages.config` → `PackageReference`.** Elimina `bindingRedirect` manuales y la carpeta
   `packages/`. Se puede hacer ya en 4.x, y desbloquea el escaneo de dependencias (§5).
3. **Bibliotecas antes que ejecutables.** Primero el dominio y el acceso a datos; el ejecutable y
   la UI al final. La capa intermedia es donde se descubre lo que no porta.
4. **`.NET Standard 2.0` solo como puente.** Posición oficial verbatim: *"We recommend you skip
   .NET Standard 2.1 and go straight to .NET 10"* y *"No new versions of .NET Standard will be
   released"*; pero también *"Use `netstandard2.0` to share code between .NET Framework and all
   other implementations of .NET."* → es **exactamente la herramienta correcta mientras conviven las
   dos plataformas**, y se abandona en cuanto el 4.x se apaga. Para código nuevo que no habla con
   4.x, `net10.0`. Multi-target `netstandard2.0;net10.0` antes que quedarse en Standard.
5. **El ejecutable, al final**, y ahí ya manda `dotnet-standards`.

**Herramienta — hallazgo que corrige la suposición habitual**: el **.NET Upgrade Assistant está
oficialmente obsoleto**. Verbatim (doc. rev. 19-mar-2026): *".NET Upgrade Assistant is officially
deprecated. Use the GitHub Copilot modernization chat agent instead, which is included with Visual
Studio 2026 and Visual Studio 2022 17.14.16 or later."* Todo plan anterior a 2026 que se apoye en él
hay que revisarlo. Y con la herramienta que sea, **produce un punto de partida que compila, no una
migración terminada**: la validación la da la suite de pruebas, no el icono verde.

## 5. Seguridad del stack

- **`BinaryFormatter` está retirado**, no desaconsejado. Verbatim: *"Starting with .NET 9, we no
  longer include an implementation of BinaryFormatter in the runtime. The APIs are still present,
  but their implementation always throws a PlatformNotSupportedException, regardless of project
  type."* En **4.x sigue funcionando**, y ahí está el peligro: es CWE-502 ejecutable. Cualquier
  `BinaryFormatter` sobre datos que cruzan una frontera de confianza es **hallazgo crítico hoy**,
  antes de migrar nada. El paquete `System.Runtime.Serialization.Formatters` que lo revive en .NET
  moderno está declarado **"unsupported and not recommended"**: PROHIBIDO usarlo como solución.
- **TLS**: en 4.x el protocolo lo decide el proceso, y `ServicePointManager.SecurityProtocol` fijado
  a mano acaba negociando TLS 1.0. Criterio: **no fijarlo en código**; dejar que el SO decida
  (`SystemDefault`, con `Switch.System.Net.DontEnableSystemDefaultTlsVersions=false`) y endurecer el
  SO (`windows-server-ad-standards`).
- **`machineKey`** en claro en el `web.config` es un secreto en el repositorio y permite falsificar
  `ViewState` y cookies de autenticación: rotar y sacarlo (`secrets-management-standards`).
  `ViewState` sin MAC ni cifrado: prohibido.
- **`customErrors="On"` y `debug="false"`** en producción: `debug="true"` filtra trazas.
- **Dependencias**: `packages.config` no se escanea bien; migrar a `PackageReference` **es también un
  control de seguridad** (habilita `dotnet list package --vulnerable`, Renovate, SBOM). Un proyecto
  4.x sin inventario de dependencias es superficie desconocida.
- Deserialización, XXE (`XmlDocument` sin `XmlResolver=null`) y SQL por concatenación: la clase de
  vulnerabilidad la decide `appsec-standards`.

## 6. Operación y entorno

- **IIS y `web.config`**: la app decide *handlers*, *modules*, autenticación y `system.web`; el sitio,
  el *app pool* y el TLS del *listener* son de `web-app-servers-standards`. No duplicar.
- **GAC y COM**: registrar en el GAC o depender de `regasm` ata el despliegue a la máquina. Queda
  **documentado como dependencia de máquina**, automatizado y versionado; nunca paso manual.
- **Build reproducible**: `msbuild.exe` de una versión fijada de Visual Studio o de los *Build
  Tools*, disponible en el agente de CI. Un legacy que solo compila en el portátil de una persona es
  el riesgo real, no el lenguaje.
- **Configuración**: transformaciones por entorno; los secretos, fuera. La configuración moderna
  (`IConfiguration`) es del destino: no reimplementarla en 4.x.

## 7. Sostenibilidad, prohibiciones y cuándo NO migrar

**Cuándo NO migrar** — decisión legítima, con ADR y revisión anual: aplicación **estable, en
mantenimiento correctivo**, sin roadmap funcional, sobre un Windows soportado y **sin exposición
directa a internet**; equipo que la conoce y sin riesgo de contratación a corto plazo; y fin de vida
del **Windows anfitrión** lejano y presupuestado. **Ese es el reloj**, no el framework. Migrar ahí
no añade valor: el coste es real y el beneficio, hipotético.

**Cuándo sí, sin discusión**: roadmap funcional activo; expone servicios a internet; depende de
componentes muertos sin parches; el Windows anfitrión entra en cuenta atrás; o un requisito de
cumplimiento exige un stack con parches propios.

**La trampa de la reescritura total**: sustituir una aplicación 4.x que funciona por un producto
nuevo desde cero es el modo de fallo más caro y frecuente de este dominio — se subestima la lógica
de negocio no escrita en ningún sitio y se paran dos años de evolución. Por defecto, **migración
incremental con la aplicación viva**. La reescritura se justifica solo si el producto también cambia.

- ❌ PROHIBIDO usar `BinaryFormatter` sobre datos no confiables, y usar el paquete de
  compatibilidad *unsupported* para revivirlo.
- ❌ PROHIBIDO iniciar desarrollo **nuevo** sobre .NET Framework. Se mantiene lo que hay.
- ❌ PROHIBIDO targets por debajo de **4.7.2**; 4.6.2 y anteriores, actualización in-place ya.
- ❌ PROHIBIDO `machineKey`, cadenas de conexión o credenciales en `web.config` versionado.
- ❌ PROHIBIDO `debug="true"` o `customErrors="Off"` en producción.
- ❌ PROHIBIDO fijar `ServicePointManager.SecurityProtocol` a un protocolo concreto en código.
- ❌ PROHIBIDO dejar `packages.config` en un proyecto en mantenimiento activo: bloquea el escaneo.
- ❌ PROHIBIDO justificar una migración con "4.8 se queda sin soporte": es **falso** (§2) y quema
  la credibilidad del plan entero.
- ❌ PROHIBIDO dar por buena la salida de un conversor automático sin pruebas que la respalden.
- ❌ PROHIBIDO planificar sobre .NET Upgrade Assistant sin comprobar antes su estado: está
  **deprecado** (§4).

## 8. Verificación web obligatoria

Antes de fijar nada: **fecha de fin de soporte del Windows anfitrión** (es el dato que manda, no el
del framework) y el estado de la tabla de ciclo de vida de .NET Framework, incluida la fecha de
4.6.2 y la discrepancia declarada en §2; versión y estado de **CoreWCF** y **CoreWF** (releases y
licencia leída en crudo, no en el badge); posición oficial vigente sobre **.NET Standard**; qué
herramienta de migración recomienda Microsoft hoy (Upgrade Assistant está deprecado: comprobar qué
lo sustituye y si eso ha vuelto a cambiar); estado de `BinaryFormatter` y del paquete de
compatibilidad; TLS 1.0/1.1 en el parque de Windows; CVEs de las dependencias NuGet del proyecto.

**Huecos declarados (sin dato verificado, NO rellenar de memoria)**: coste/plazo típico de una
migración 4.x→.NET moderno por tamaño de código base — no hay cifra pública fiable, se estima con
el inventario real del proyecto; cuota de mercado o número de aplicaciones 4.x en producción; fecha
de fin de soporte de cada Windows concreto del parque (se consulta uno a uno en Microsoft
Lifecycle); estado de mantenimiento de `try-convert` a fecha de hoy.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
