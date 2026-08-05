---
name: vbnet-standards
description: Visual Basic .NET as a frozen-but-supported language, and the stay-or-convert-to-C# decision. Use when editing .vb files, a .vbproj project, My.Settings/My.Resources/My.Application code, Option Strict / Option Explicit / Option Infer / Option Compare directives, Microsoft.VisualBasic namespace calls (CInt, CType, IsNothing, Mid, Left, InStr, Format, MsgBox, InputBox, IIf, On Error Resume Next, Err.Number), Handles and WithEvents, Module and Sub Main in VB, ByRef/ByVal parameters, VB WinForms designer files (.Designer.vb, Form1.vb), Microsoft.VisualBasic.FileIO.TextFieldParser, and when choosing VB templates in dotnet new (classlib, console, winforms, wpf) or evaluating a VB-to-C# converter such as ICSharpCode CodeConverter.
---

# Estándares Visual Basic .NET

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Código **VB.NET** (`.vb`, `.vbproj`), corra sobre .NET Framework 4.x o sobre .NET moderno, y la
decisión de mantenerlo o convertirlo. Triggers: `Option Strict`/`Explicit`/`Infer`/`Compare`,
espacio `Microsoft.VisualBasic`, `My.*`, `Handles`/`WithEvents`, `On Error Resume Next`,
`.Designer.vb`, `Module`, `MsgBox`, `TextFieldParser`.

**El eje: VB.NET está soportado, pero congelado.** No es lo mismo que muerto y no es lo mismo que
vivo. Declaración de Microsoft (blog del equipo de Visual Basic, **11-mar-2020**), **verbatim**:

> "One of the major benefits of using Visual Basic is that the language has been stable for a very
> long time. The significant number of programmers using Visual Basic demonstrates that its
> stability and descriptive style is valued. **Going forward, we do not plan to evolve Visual Basic
> as a language.** This supports language stability and maintains compatibility between the .NET
> Core and .NET Framework versions of Visual Basic. Future features of .NET Core that require
> language changes may not be supported in Visual Basic."

Consecuencia práctica, que es la que decide: **el compilador y el runtime sí evolucionan; el
lenguaje no.** Todo lo que llega a la plataforma y necesita sintaxis nueva —records, pattern
matching moderno, tipos de referencia anulables, `Span<T>` idiomático, top-level statements,
generadores de código con sintaxis propia— llega a C# y **no llega aquí**. VB consume lo que
puede desde bibliotecas; lo que exige gramática, no. Esto no es una opinión sobre el lenguaje: es
la restricción de diseño con la que se planifica.

**No aplica**: `dotnet-standards` decide **la plataforma .NET moderna** —SDK, TFM, LTS, NuGet,
ASP.NET Core, EF Core, publicación, testing, CI—, y **es la dueña del destino si se convierte a
C#**: la calidad del C# resultante se rige por su criterio, no por el de aquí. Aquí, solo el
lenguaje VB y la decisión.
`dotnet-framework-legacy-standards` decide la **plataforma 4.x** y el porte a .NET moderno
(WebForms, WCF, `packages.config`, SDK-style): si el problema es "no puedo salir de 4.8", es suyo;
si es "cómo se escribe este `.vb`", es de aquí. Un `.vbproj` sobre `net48` toca las dos: **el
proyecto y su TFM allí, el código aquí.**
Hermanas: `vb6-standards` (VB6 es **otro lenguaje y otro runtime**, sin CLR — la similitud
sintáctica es una trampa) y `classic-asp-standards` (VBScript en servidor, tampoco es esto).
`legacy-modernization-standards`: estrategia de cartera, con
`enterprise-architecture-standards`, `project-management-standards` y `tech-leadership-standards`.
Además `refactoring-tech-debt-standards` (conversión segura), `testing-qa-standards` (la red que la
hace defendible), `sql-standards` y `sqlserver-dba-standards` (el SQL embebido, que aquí suele ser
la mitad del código), `appsec-standards`, `cicd-standards`, `git-workflow-standards`.

## 2. Qué está soportado hoy — decisiones por defecto

> Verificar por web antes de fijarlo en un proyecto real (§8).

**Plantillas de proyecto VB en el SDK moderno.** Tabla oficial de `dotnet new`, columna *Language*,
**verbatim** en lo que importa: `classlib` → `[C#], F#, VB`; `console` → `[C#], F#, VB`;
`winforms` y `winformslib` → `[C#], VB` (*Introduced*: `3.0 (5.0 for VB)`); `wpf`, `wpflib`,
`wpfcustomcontrollib`, `wpfusercontrollib` → `[C#], VB`; `mstest`, `mstest-class`, `nunit`,
`nunit-test`, `xunit` → `[C#], F#, VB`.

**Discrepancia declarada — importante.** El anuncio de 2020 prometía **verbatim** estos tipos de
proyecto para VB en .NET 5: *"Class Library, Console, Windows Forms, WPF, Worker Service, ASP.NET
Core Web API"*. La tabla vigente de plantillas del SDK **no lista VB** ni en `worker` (`[C#]`) ni
en `webapi` (`[C#], F#`). Es decir: **lo prometido en 2020 no está en las plantillas de hoy**. No
significa necesariamente que el compilador lo impida —se puede partir de un `classlib` VB y
referenciar ASP.NET Core a mano—, pero **sin plantilla no hay camino soportado**: cualquier plan que
asuma "web API en VB" hay que verificarlo con `dotnet new list --language VB` en el SDK real antes
de comprometerlo.

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Ámbito de VB.NET **nuevo** | **Ninguno**: no se arranca proyecto nuevo en VB | Módulo dentro de una solución VB existente que un equipo VB mantiene |
| Tipo de app viable | Escritorio **WinForms/WPF**, bibliotecas, consola, tests | Servicio/worker/API: solo tras verificar el SDK; por defecto, C# |
| Plataforma destino si se porta | `net10.0-windows` (WinForms/WPF) o `net10.0` | `netstandard2.0` mientras conviva con 4.x |
| Solución mixta | **Sí**: VB y C# conviven por proyecto | — |
| Conversión a C# | Solo con motivo explícito (§5) | Mantener VB si el equipo lo mantiene bien |

**Interoperabilidad C#/VB.NET**: ambos compilan al mismo IL y una solución puede tener proyectos de
los dos. **La frontera es por proyecto, no por fichero**: un `.vbproj` no admite `.cs` ni al revés.
Criterio: si se convierte, se convierte **proyecto a proyecto**, dejando la solución compilando y
verde en cada paso — nunca fichero a fichero con la solución rota. El código nuevo entra en
proyectos C# nuevos que referencian los VB existentes; eso ya es una migración incremental sin
tocar una línea de VB.

## 3. La línea cero no negociable: `Option Strict On`

`Option Strict Off` y `Option Explicit Off` son el default histórico de VB y **la causa de la mayor
parte de los bugs de este ecosistema**. Con ellos, el compilador acepta conversiones implícitas con
pérdida, enlaza en tiempo de ejecución (*late binding*) y crea variables por escribirlas mal. El
resultado: errores de tipo que aparecen en producción con datos reales en vez de en la compilación.

- **`Option Strict On` y `Option Explicit On` en todos los proyectos**, a nivel de `.vbproj`, no
  fichero a fichero. `Option Infer On` es aceptable y deseable.
- Activarlo en un código base que hoy está en `Off` genera cientos de errores. **No es motivo para
  no hacerlo**: es la medida real de la deuda. Ruta: por proyecto, del de menos dependencias hacia
  arriba, con cada conversión explícita revisada — antes la tomaba el runtime a ciegas.
- **`DirectCast` frente a `CType`**: el primero falla si el tipo no es el esperado, el segundo
  intenta convertir. Por defecto `DirectCast` (o `TryCast` comprobando `Nothing`): que falle pronto.
- ❌ `On Error Resume Next`/`GoTo` → `Try/Catch/Finally`. Un `Resume Next` es un `catch` vacío
  global: traga errores y deja el estado a medias.
- ❌ Comparar cadenas con `=` dependiendo de `Option Compare Text`: fijar `Option Compare Binary` y
  usar `String.Equals(..., StringComparison...)`.
- `Nothing` no es el `null` de C# en todos los contextos (sobre un `Integer` vale `0`): trampa
  clásica en la frontera con C# y en la conversión automática. `Is Nothing`, solo tipos referencia.

**`Microsoft.VisualBasic`**: existe en .NET moderno (`Microsoft.VisualBasic.Core`), pero **no todo
sobrevive**: `ApplicationServices`, `Devices` y `MyServices` —los que sostienen `My.Application`,
`My.Computer` y compañía— tuvieron un hueco en .NET Core 3.x, y su estado por versión hay que
**verificarlo en la página de cambios de ruptura de VB antes de portar** (§8). Criterio: en código
que vaya a portarse, **sustituir las funciones de compatibilidad (`Left`, `Mid`, `InStr`, `Format`,
`IIf`, `MsgBox`) por sus equivalentes de BCL**. No es purismo: `IIf` evalúa las dos ramas y `MsgBox`
ata a Windows. `TextFieldParser` sí sigue disponible y es útil: no reinventarlo.

## 4. Calidad y testing

Aplican los gates de `dotnet-standards` (analizadores Roslyn, `.editorconfig`, SCA, CI). Específico
de aquí, y todo debe **romper el build**:

- `Option Strict On`/`Explicit On` verificados en el `.vbproj`, no solo en el fichero.
- `<TreatWarningsAsErrors>` activo; en VB los avisos de conversión implícita son el hallazgo real.
- **Cobertura antes de convertir**: sin suite de pruebas sobre el comportamiento observable, una
  conversión a C# no es defendible ni verificable. La estrategia la fija `testing-qa-standards`;
  aquí la regla es dura: **primero la red, después la conversión**.
- Los ficheros `.Designer.vb` son generados: no se editan a mano ni se revisan como código.

## 5. Migración a C# — criterio honesto

**Convertir no es modernizar.** Los conversores automáticos (ICSharpCode CodeConverter y similares)
producen C# que **compila pero no es idiomático**: `Nothing` mal traducido, `On Error` convertido en
`try/catch` vacíos, `IIf` en llamadas que evalúan ambas ramas, propiedades y eventos con nombres
de máquina. Sale un código base en C# que nadie escribió y que nadie quiere mantener. Si el
objetivo era "que el equipo pueda contratar gente", ese resultado no lo consigue.

- **Sí** cuando: la aplicación va a seguir evolucionando y necesita features que exigen sintaxis;
  hay que unificar con un código base C# ya mayoritario; o el tipo de proyecto necesario **no tiene
  plantilla VB** (web, worker — §2).
- **No** cuando: es estable, el equipo que la mantiene sabe VB y hace buen trabajo, y no hay
  roadmap. VB.NET está **soportado**; congelado no es un riesgo de seguridad por sí solo. Convertir
  por estética es gastar presupuesto en cero valor.
- Si se convierte: **proyecto a proyecto**, suite verde antes y después de cada paso, y una pasada
  de revisión humana que **reescribe lo que el conversor dejó feo** —presupuestarla explícitamente;
  sin ella el resultado es deuda nueva con sintaxis distinta—. **Nunca** convertir y portar de
  plataforma en el mismo commit: si algo se rompe, no se sabrá cuál de los dos fue.

## 6. Seguridad del stack

No hay superficie de ataque propia del lenguaje: manda `appsec-standards` y, en 4.x,
`dotnet-framework-legacy-standards` (`BinaryFormatter`, `machineKey`, TLS). Específico de VB:
**`Option Strict Off` es un problema de seguridad**, no solo de calidad —el *late binding* permite
que una cadena decida qué miembro se invoca—; **SQL por concatenación** (`"... WHERE id=" &
txt.Text`) es el patrón dominante del código VB heredado y su única corrección es `SqlCommand` con
`Parameters.Add` tipado (`sql-standards`); y `My.Settings` con contraseñas o cadenas de conexión es
configuración en claro dentro del artefacto: fuera, a `secrets-management-standards`.

## 7. Sostenibilidad y prohibiciones

Cadencia: la aplicación se mantiene en el TFM soportado más alto que permita su plataforma;
las dependencias NuGet se actualizan con la misma cadencia que un proyecto C#. **Que el lenguaje
esté congelado no congela el runtime ni las dependencias** — ese es el error de mantenimiento
característico de estas bases de código: se dejan de actualizar "porque VB ya no cambia".

- ❌ PROHIBIDO `Option Strict Off` u `Option Explicit Off` en cualquier proyecto, nuevo o heredado.
- ❌ PROHIBIDO `On Error Resume Next` / `On Error GoTo`.
- ❌ PROHIBIDO *late binding* sobre `Object` para acceder a miembros.
- ❌ PROHIBIDO SQL por concatenación de cadenas.
- ❌ PROHIBIDO arrancar un proyecto **nuevo** en VB.NET fuera de una solución VB existente.
- ❌ PROHIBIDO entregar la salida de un conversor automático sin la pasada de reescritura humana.
- ❌ PROHIBIDO convertir a C# sin suite de pruebas previa sobre el comportamiento observable.
- ❌ PROHIBIDO editar `.Designer.vb` a mano.
- ❌ PROHIBIDO afirmar que VB.NET "no está soportado": lo está (§1); lo que no recibe es lenguaje
  nuevo. Vender una migración con ese argumento la hunde en la primera revisión.

## 8. Verificación web obligatoria

Comprobar: si Microsoft ha publicado **algo posterior a marzo de 2020** que cambie o matice la
declaración de congelación del lenguaje (es el dato que sostiene toda esta skill); qué plantillas VB
lista el SDK instalado (`dotnet new list --language VB`) frente a la tabla oficial, y si la
discrepancia de §2 sobre `worker`/`webapi` se ha resuelto en algún sentido; el estado por versión de
`Microsoft.VisualBasic.ApplicationServices`, `.Devices` y `.MyServices` en la página de cambios de
ruptura de VB; la versión LTS de .NET vigente y su fecha de fin de soporte (la fija
`dotnet-standards`); CVEs de las dependencias NuGet.

**Huecos declarados (sin dato verificado, NO rellenar de memoria)**: no verificado a ago-2026 si
existe una declaración de soporte del **lenguaje VB.NET con fecha de fin** — a día de hoy no consta
ninguna, y la ausencia de fecha **no debe escribirse como si fuera una garantía indefinida**; estado
de mantenimiento y calidad de salida de los conversores VB→C# concretos; disponibilidad real (no de
plantilla) de ASP.NET Core y Worker Service en VB sobre el SDK actual; porcentaje de código base
.NET escrito en VB — no hay cifra pública fiable, no citar ninguna.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
