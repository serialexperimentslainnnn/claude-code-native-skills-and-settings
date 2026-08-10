---
name: classic-asp-standards
description: Classic ASP (ASP 3.0) on IIS - the worst attack surface in the Microsoft legacy catalogue, and the migrate-or-isolate decision. Use when working with .asp and .asa files, global.asa, server-side VBScript or JScript in <% %> blocks, the asp.dll ISAPI extension and the IIS ASP feature, Response.Write / Request.QueryString / Request.Form / Server.MapPath / Server.Execute / Server.Transfer / Session and Application objects, #include file and #include virtual directives, ADODB.Connection / ADODB.Recordset / ADODB.Command with CreateParameter, Scripting.FileSystemObject, Server.CreateObject with registered COM components, ASPError and detailed error pages, and when planning around the VBScript Feature on Demand deprecation or migrating Classic ASP to ASP.NET Core.
---

# Estándares ASP clásico (ASP 3.0)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplicaciones **ASP clásico** (ASP 3.0) servidas por IIS: mantenimiento correctivo, endurecimiento,
aislamiento y salida. Triggers: `.asp`, `.asa`, `global.asa`, bloques `<% %>` con VBScript o JScript
de servidor, `asp.dll`, `Response.Write`, `Request.QueryString`/`Form`, `Server.CreateObject`,
`Server.Execute`, `ADODB.*`, `Scripting.FileSystemObject`, `#include file`/`#include virtual`.

**El eje: sigue funcionando, y por eso sobrevive.** Declaración de Microsoft (*Active Server Pages
(ASP) support in Windows*, KB 2669020; publicada 2020, revisada 13-ago-2025), **verbatim**:

> "The use of ASP pages with Microsoft Internet Information Services (IIS) is currently supported in
> all supported versions of IIS."

> "IIS is included in Windows operating systems. Therefore, both ASP and IIS support lifetimes are
> tied to the support lifecycle of the host operating system."

Es decir: **ASP no tiene fecha de fin de soporte propia**; hereda la del Windows Server anfitrión,
igual que .NET Framework 4.8. Instalar la característica ASP en un IIS de un Windows Server soportado
es una configuración soportada, no una chapuza tolerada. **Y eso es exactamente el problema**: no hay
ninguna fuerza que empuje a salir, mientras el código acumula veinte años de patrones inseguros que
ningún analizador moderno mira. Es la peor superficie de ataque de este catálogo de legacy: **la
única de las cuatro que, por definición, atiende tráfico HTTP no confiable**.

**El reloj real no es ASP: es VBScript.** Fila oficial de *Deprecated features in the Windows
client*, **verbatim**: *"VBScript is deprecated. In future releases of Windows, VBScript will be
available as a feature on demand before its removal from the operating system."* — anuncio de
**octubre de 2023**. Y en *Resources for deprecated features*, **verbatim**: *"VBScript will be
available as a feature on demand before being retired in future Windows releases. Initially, the
VBScript feature on demand will be preinstalled to allow for uninterrupted use while you prepare for
the retirement of VBScript."*

Las tres fases son, por tanto: **(1)** FOD **preinstalada y activa** → **(2)** FOD **ya no activa por
defecto**: hay que habilitarla explícitamente para que la aplicación siga funcionando → **(3)**
**retirada del sistema operativo**, sin vuelta atrás. Criterio de planificación: **una aplicación ASP
clásica escrita en VBScript tiene fecha de caducidad aunque ASP no la tenga**, y la fase 2 es la que
rompe despliegues por sorpresa —el día que se aprovisiona un servidor nuevo y la FOD ya no viene
puesta—. Las fechas concretas de fase 2 y 3 **no se escriben aquí sin verificarlas**: ver §8.

**No aplica**: `web-app-servers-standards` decide **IIS como servidor** —
sitios, *application pools* y su identidad, reciclado, límites, ARR, certificados y TLS del
*listener*, registro de acceso—; aquí, solo lo que decide el código ASP y su `web.config`/metabase
de aplicación. `dotnet-framework-legacy-standards` (ASP.NET **con** `System.Web`: WebForms, MVC5 —
**otra tecnología**, aunque comparta IIS y extensión mental) y `dotnet-standards` (**ASP.NET Core:
el destino de la migración, y el dueño del criterio del código resultante**).
Hermanas: `vb6-standards` (VB6 nativo — la propia declaración de soporte de VB6 dice **verbatim**
*"VBScript is unrelated to Visual Basic 6.0 and this support statement"*) y `vbnet-standards`
(VB.NET sobre el CLR). Tres cosas distintas que se parecen al leerlas.
`legacy-modernization-standards`: cartera y decisión invertir/migrar/
retirar, con `enterprise-architecture-standards`, `project-management-standards`,
`tech-leadership-standards`, `refactoring-tech-debt-standards` y `testing-qa-standards`. Además
`appsec-standards` (**clases de vulnerabilidad y modelado de amenazas**; aquí solo los sinks
concretos de ASP), `vulnerability-management-standards`, `secrets-management-standards`,
`firewall-policy-standards` y `vpn-standards` (el aislamiento que exige §5), `sql-standards` y
`sqlserver-dba-standards`, `windows-server-ad-standards`, `powershell-standards`,
`grc-compliance-standards`.

## 2. Decisiones por defecto

> Verificar por web antes de fijarlo (§8): el calendario de VBScript es lo que cambia.

| Decisión | Por defecto | Nota |
|---|---|---|
| Aplicación ASP **nueva** | **Ninguna.** Prohibido | Sin excepción, ni "una paginita" |
| Exposición | **Nunca directa a internet** | §5; es la regla que domina todo lo demás |
| Motor de script | VBScript (lo que hay) | Contarlo como **deuda con reloj** (§1), no como estable |
| Acceso a datos | ADO con **comandos parametrizados** | `ADODB.Command` + `CreateParameter`; nada más |
| Errores en producción | `<httpErrors>` genérico, `scriptErrorSentToBrowser=false` | Detalle solo al log del servidor |
| Estado de sesión | Evitar `Session` para datos sensibles; nunca para autorización | `Session` en proceso, se pierde al reciclar el *pool* |
| Ruta de salida | **Migrar o aislar** (§7) | No hay tercera opción honesta |

**Inventario primero.** Antes de decidir nada: listar los `.asp`, los `#include`, los componentes COM
que la aplicación registra o instancia (`Server.CreateObject` con el ProgID exacto), su fabricante y
si sigue existiendo, y el motor de datos al que habla. **Un COM registrado sin fabricante vivo es un
bloqueo duro para cualquier plan**, y no aparece en ningún escáner de dependencias.

## 3. Convenciones para el código que sobrevive

Mientras exista, el código que se toca cumple:

- **`Option Explicit` en la primera línea de cada `.asp`.** VBScript sin él crea variables al
  escribirlas mal, en silencio, y ese es el origen de fallos de autorización reales (una variable de
  permiso mal escrita evalúa a vacío y pasa la comprobación).
- **`On Error Resume Next` solo acotado** a la instrucción concreta que lo necesita, con comprobación
  inmediata de `Err.Number` y `On Error GoTo 0` justo después. A nivel de página es un tragador de
  errores global: la aplicación sigue con estado corrupto.
- **Cerrar y liberar**: `Recordset`/`Connection` con `.Close` y `Set x = Nothing` — el *pool* de
  conexiones y los objetos COM no se recogen solos y una fuga tumba el *app pool*.
- **`#include` es textual y en tiempo de compilación de la página**: no admite rutas dinámicas y las
  inclusiones anidadas crean dependencias invisibles. Documentar el grafo; es lo primero que
  sorprende en cualquier migración.
- **Nada de lógica nueva en ASP**: la funcionalidad nueva se escribe fuera (§7) y se enlaza.

## 4. Calidad y testing

Sección **omitida por artificial**: no existe toolchain moderna soportada (linter, análisis estático,
formateador, framework de pruebas) para ASP clásico con VBScript. Lo único aplicable es
caracterizar el comportamiento observable con pruebas de extremo a extremo antes de tocar nada, y eso
lo fija `testing-qa-standards`.

## 5. Seguridad — sección principal

**Es la razón de existir de esta skill.** El código ASP clásico típico se escribió antes de que
existiera OWASP y no ha sido revisado desde entonces. Los patrones dominantes, con su corrección
real:

**1. Inyección SQL por concatenación — el patrón número uno de este código.** El idioma nativo de
ASP es construir la consulta con `&` a partir de `Request.QueryString` o `Request.Form`. Cada una de
esas líneas es una vulnerabilidad crítica explotable sin autenticación. Correcciones falsas que
aparecen constantemente en estas bases de código y que hay que **rechazar**: duplicar comillas
simples, filtrar palabras clave (`SELECT`, `UNION`), limitar la longitud del campo, o validar en
JavaScript de cliente. **La única corrección es la parametrización**: `ADODB.Command` con
`CreateParameter` (nombre, tipo, dirección, tamaño, valor) y `Parameters.Append`, o procedimientos
almacenados invocados con parámetros —**nunca** un procedimiento almacenado que a su vez concatene
dentro—. Los tipos y tamaños se declaran de verdad, no se copian del ejemplo de al lado.

**2. XSS reflejado y almacenado.** `Response.Write Request.QueryString("x")` escribe la entrada tal
cual. Codificar **en la salida y según el contexto** (HTML, atributo, JavaScript, URL); `Server.
HTMLEncode` cubre el caso HTML y **no** el resto. Añadir CSP en las cabeceras es mitigación, no
corrección.

**3. Inclusión y ejecución dinámica.** `Server.Execute` y `Server.Transfer` con una ruta derivada de
la petición permiten ejecutar cualquier `.asp` del servidor; combinados con una subida de ficheros,
son **ejecución remota de código**. Regla: el destino de `Server.Execute` es **siempre** una
constante o un valor de una lista blanca cerrada. Lo mismo para cualquier `Server.MapPath` con
entrada de usuario: *path traversal* directo al sistema de ficheros.

**4. Subida de ficheros.** El fallo mortal es guardar el fichero **bajo un directorio que IIS
ejecuta**: subir un `.asp` disfrazado y pedirlo por HTTP es RCE. Reglas duras: almacenar **fuera del
árbol web** y servir por un manejador que lea el fichero; lista blanca de extensiones y verificación
del contenido, no del nombre ni del `Content-Type`; nombre generado por el servidor; y el directorio
de subidas con **permisos de ejecución de scripts deshabilitados en IIS**, no solo por convención.

**5. Mensajes de error detallados expuestos.** Un error ASP sin controlar imprime la consulta, la
ruta física y a veces la cadena de conexión. Es reconocimiento gratis para el atacante y filtración
de datos por sí mismo. `scriptErrorSentToBrowser=false`, página de error genérica, y el detalle solo
en el log del servidor.

**6. Credenciales en el código.** Cadenas de conexión con usuario y contraseña en `global.asa` o en
un `include` de configuración: es lo normal aquí. Sacarlas (`secrets-management-standards`), rotarlas
asumiendo que ya son conocidas, y comprobar que **ningún fichero de configuración es servible por
HTTP** (un `.inc` o `.txt` incluido se descarga tal cual: renombrar a `.asp` o sacarlo del árbol).

**7. Sesión y autorización.** Comprobar la autorización **en cada página**, no en la de login ni en
un `#include` que alguien puede olvidar. La cookie de sesión de ASP debe ir `HttpOnly` y `Secure`.
Y no confiar en `Session` para nada que el reciclado del *app pool* pueda tirar.

**Por qué un WAF delante no arregla nada de esto.** Un WAF filtra por patrones sobre la petición: no
conoce la consulta que se va a construir, ni qué fichero se va a ejecutar, ni si el que sube el
fichero está autorizado. Contra inyección por concatenación reduce el ruido automatizado y **no
detiene a un atacante que ajuste la carga**; contra un fallo de autorización —el más común y el más
caro— no puede hacer absolutamente nada, porque la petición maliciosa es sintácticamente idéntica a
la legítima. Un WAF es **una capa que compra tiempo mientras se corrige el código o se aísla la
aplicación**; declararlo como control compensatorio permanente ante una auditoría es insostenible, y
tratarlo como corrección es la decisión que convierte un hallazgo en una brecha.

**Privilegios y contención**: *application pool* con identidad propia y mínima, sin permisos de
escritura sobre el árbol web, sin `sysadmin` en el motor de base de datos —usuario con permisos solo
sobre los objetos que usa—, y salida de red restringida (`firewall-policy-standards`): si la
aplicación se compromete, que no pueda llamar a casa.

## 6. Operabilidad

Sección **reducida deliberadamente**: la operación del servidor —*app pools*, reciclado, límites,
TLS, registro— es de `web-app-servers-standards` y no se duplica aquí. Lo específico del
código: `Session` es estado en proceso y **cualquier reciclado la pierde**, así que ni balanceo sin
afinidad ni escalado horizontal sin rediseñar el estado; y las fugas de objetos COM (§3) son la causa
habitual de reinicios en cadena. La telemetría útil se saca del log de IIS, no de instrumentación en
el código: no la hay.

## 7. Salida: migrar o aislar, y prohibiciones

**Solo hay dos recomendaciones honestas, y la elección la decide una pregunta: ¿la aplicación es
alcanzable desde una red no confiable?**

- **Si es pública o alcanzable desde internet: migrar.** No hay configuración que haga aceptable este
  código base frente a tráfico hostil. Ruta: **strangler fig** — poner ASP.NET Core delante como
  *reverse proxy* (YARP) y mover ruta a ruta, empezando por las que tocan datos y autenticación, con
  la aplicación viva. El destino y su calidad se rigen por `dotnet-standards`. Reescribir por partes,
  nunca de golpe: la lógica de negocio de estas aplicaciones no está documentada en ningún otro sitio
  y el *big bang* pierde reglas que nadie sabía que existían.
- **Si es estrictamente interna, estable y sin roadmap: aislar** y congelar, con fecha de revisión.
  Red segmentada y *default-deny* de entrada y salida, acceso solo por VPN o desde una red
  identificada, autenticación fuerte delante, credenciales rotadas, errores silenciados, y las
  inyecciones SQL **corregidas igualmente** (la amenaza interna y el movimiento lateral existen). El
  aislamiento compra tiempo; no absuelve del §5.
- **Migrar el motor de script no es una opción**: reescribir el VBScript en JScript de servidor
  mantiene todos los problemas y añade uno nuevo. El calendario de VBScript (§1) es un motivo para
  salir de ASP, no para cambiar de lenguaje dentro de ASP.

- ❌ PROHIBIDO crear una página ASP clásica **nueva**, en cualquier circunstancia.
- ❌ PROHIBIDO exponer una aplicación ASP clásica directamente a internet.
- ❌ PROHIBIDO construir SQL concatenando entrada del usuario. Sin excepción por "es un id numérico".
- ❌ PROHIBIDO "sanear" duplicando comillas o filtrando palabras clave en vez de parametrizar.
- ❌ PROHIBIDO `Server.Execute`/`Server.Transfer`/`Server.MapPath` con rutas derivadas de la petición.
- ❌ PROHIBIDO guardar ficheros subidos en un directorio con ejecución de scripts habilitada.
- ❌ PROHIBIDO enviar errores detallados al navegador en producción.
- ❌ PROHIBIDO credenciales en `global.asa` o en ficheros servibles por HTTP (`.inc`, `.txt`).
- ❌ PROHIBIDO omitir `Option Explicit`.
- ❌ PROHIBIDO `On Error Resume Next` a nivel de página.
- ❌ PROHIBIDO declarar un WAF como corrección de un hallazgo de inyección o de autorización.
- ❌ PROHIBIDO planificar como si ASP fuera indefinido: ASP no tiene EOL propio, **VBScript sí tiene
  calendario de retirada** (§1), y ese es el que manda.

## 8. Verificación web obligatoria

Comprobar siempre: el **calendario de retirada de VBScript** —fases, y sobre todo **en qué versión de
Windows la FOD deja de venir activada por defecto y cuándo se retira**—, contra la página de
características obsoletas de Windows y el blog de Windows IT Pro; si la declaración de soporte de ASP
(KB 2669020) sigue diciendo *"currently supported in all supported versions of IIS"*; la fecha de fin
de soporte del **Windows Server anfitrión**, que es el reloj de ASP; el estado del fabricante de cada
componente COM del inventario; CVEs de IIS y de esos componentes.

**Huecos declarados (sin dato verificado, NO rellenar de memoria)**: **las fechas concretas de la
fase 2 (VBScript deshabilitado por defecto) y de la fase 3 (retirada) no están verificadas verbatim a
ago-2026** — la documentación oficial de Microsoft consultada describe las fases *"in future Windows
releases"* **sin dar año**, y las cifras que circulan en prensa técnica no coinciden entre sí; **no
escribir una fecha en un plan sin obtenerla de la fuente primaria**. Tampoco verificado: si la
característica ASP de IIS sigue instalable en la última versión de Windows Server publicada (probar,
no suponer); número de sitios ASP clásico en producción o cuota de mercado — no hay cifra pública
fiable, no citar ninguna.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
