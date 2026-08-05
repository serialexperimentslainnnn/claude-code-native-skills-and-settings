---
name: jsp-struts-standards
description: Legacy Java web applications built on JSP and Apache Struts - a security problem before it is a maintenance problem. Use when working with .jsp, .jspf, .jspx and .tag files, scriptlets and expressions (<% %>, <%= %>, <%! %>), page/include/taglib directives, .tld tag libraries and JSTL c:/fmt:/fn: tags, struts-config.xml, struts.xml, validation.xml, tiles-defs.xml and tiles.xml, org.apache.struts Action / ActionForm / DispatchAction / LookupDispatchAction and ActionServlet, Struts 2 ActionSupport, interceptors, result types and OGNL expressions in %{...} or s: tags, the Struts file upload interceptor and Action File Upload, Struts 1 or Struts 2.3/2.5 dependencies in pom.xml or WEB-INF/lib, struts2-core and struts2-rest-plugin jars, web.xml servlet and filter mappings, .war packaging of an old Java web app, javax.servlet.http.HttpServlet and javax.servlet.jsp imports in legacy sources, JSP pages that build SQL or HTML by string concatenation, and when planning to migrate such an application to Spring Boot, to an API with a separate front end, or to rewrite it.
---

# Estándares JSP y Apache Struts (legacy Java web)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplicaciones Java web heredadas construidas con **JSP** y **Struts 1 / Struts 2**: diagnóstico,
contención, parcheo y salida. Triggers: `.jsp`/`.jspf`/`.tag`, `<% %>`/`<%= %>`, `struts-config.xml`,
`struts.xml`, `ActionForm`, `ActionSupport`, OGNL, `.tld`/JSTL, `web.xml`, `.war`, `struts2-core`.

**El eje, y hay que decirlo en la primera reunión: una aplicación JSP/Struts en producción es casi
siempre un problema de seguridad antes que un problema de mantenimiento.** No es una opinión sobre
código feo: es el historial del framework. Datos verificados leyendo el **catálogo KEV de CISA**
(*Known Exploited Vulnerabilities*, fichero JSON descargado en crudo, versión **2026.08.04**, 1.660
entradas): hay **ocho** vulnerabilidades de Struts catalogadas como **explotadas en el mundo real** —
`CVE-2017-5638` (marcada además con uso **conocido en campañas de ransomware**; es la de la brecha de
Equifax), `CVE-2018-11776`, `CVE-2017-9805`, `CVE-2020-17530`, `CVE-2013-2251`, `CVE-2012-0391`, y
dos de **Struts 1**: `CVE-2017-9791` y `CVE-2006-1547`. Una aplicación así, alcanzable desde
internet y sin parchear, no se "detecta" cuando la explotan: se detecta meses después.

**Estado de los frameworks, verificado:**

- **Struts 1 lleva retirado desde 2013.** Del anuncio oficial del proyecto, **verbatim**: *"the Struts
  1.x web framework has reached its end of life and is no longer officially supported"*, con la
  última versión —1.3.10— publicada en **diciembre de 2008**. Y sobre qué pasa si aparece un fallo
  grave, **verbatim**: *"Since the end of support is reached, you will either need to find
  mitigations, patch the existing Struts 1 source code yourself or migrate your project to another
  web framework."* Traducido a decisión: **no existe parche para Struts 1, ni lo va a haber.**
- **Struts 2 sigue vivo, pero ya no se llama "2.x" en la práctica**: las ramas activas son **7.x y
  6.x** (verificado en el feed Atom de releases del repositorio oficial: **Struts 7.3.0** publicada el
  **1-ago-2026** y **6.11.0** el 29-jun-2026 — la página `releases.html` del sitio iba por detrás,
  en 7.2.1, el mismo día). **La rama 2.5.x, que es donde está la mayoría del parque empresarial,
  terminó su vida el 30-abr-2024** tras la 2.5.33; la 2.3 terminó en mayo de 2019. El proyecto **no
  publica calendario de EOL con antelación**: lo anuncia con unos meses de margen, así que "estamos
  soportados" es una afirmación con fecha de caducidad desconocida.
- **JSP no está muerto, está congelado.** Sigue siendo una especificación de **Jakarta EE**
  (*Jakarta Pages* **4.0** en **Jakarta EE 11**, publicada en jun-2025; Tomcat 11 la implementa), en
  modo mantenimiento: sin funcionalidad nueva y **sin fecha oficial de retirada**. Es decir, el
  problema de una aplicación JSP no es que el estándar caduque, es lo que la gente escribió dentro.
- **La barrera técnica real de cualquier migración es el cambio de espacio de nombres `javax` →
  `jakarta`** (Jakarta EE 9 en adelante). No es un *search & replace*: afecta a cada `import`, a cada
  descriptor, a las *tag libs* y **a todas las dependencias transitivas**, incluidas las que ya no se
  mantienen. Verificado en la tabla de versiones de Tomcat: **Tomcat 9.0.x es la última rama `javax`**
  (Servlet 4.0 / JSP 2.3, Java 8+), mientras **10.1.x** (Servlet 6.0 / Pages 3.1, Java 11+) y
  **11.0.x** (Servlet 6.1 / Pages 4.0, Java 17+) ya son `jakarta`. **Ese salto es el proyecto**, no el
  preámbulo del proyecto.

**No aplica**: `web-app-servers-standards` (**ya escrita**) es la dueña del **servidor** —Tomcat,
WildFly, WebLogic, WebSphere, httpd/nginx delante, límites, hilos, TLS, `server.xml`— y aquí solo
aparece el acoplamiento que decide la migración (§2). `jvm-spring-standards` (**ya escrita**) manda
sobre **Java moderno y Spring, que son el destino** de esta migración: la calidad del código
resultante se rige por su criterio, no por éste. `legacy-modernization-standards` (**ya escrita**) es el paraguas y `enterprise-architecture-standards` (**ya escrita**) pone inventario,
modelo TIME y las "R" —aquí qué implica técnicamente cada opción—, con `refactoring-tech-debt-standards`
y `testing-qa-standards` (**ya escritas**: *strangler fig*, caracterización sin tests),
`project-management-standards`, `tech-leadership-standards`, `cicd-standards` y `git-workflow-standards`.
`appsec-standards` y `vulnerability-management-standards` (**ya escritas**) ponen metodología, triaje
y KEV/EPSS —aquí los *sinks* concretos de JSP/Struts—, con `frontend-frameworks-standards` y
`api-design-standards` si el destino es API + front separado, `sql-standards`, `firewall-policy-standards`
y `grc-compliance-standards`. Hermanas de bloque legacy —**comparten la etiqueta "legacy" y poco
más**—: `abap-sap-standards`, `plsql-oracle-forms-standards`, `coldfusion-standards`,
`dotnet-framework-legacy-standards`, `php-standards`, `classic-asp-standards`, `vb6-standards`.

## 2. Decisiones por defecto

> Verificar por web antes de fijarlo (§8): versión de Struts, calendario del servidor y KEV.

| Decisión | Por defecto | Nota |
|---|---|---|
| Struts 1 en producción | **Fuera de plazo. Plan de salida con fecha, ya** | No hay parche posible (§1) |
| Struts 2.3 / 2.5 | **Actualizar a rama soportada (6.x/7.x) o salir** | Cambio mayor, no *bump* de versión |
| Lógica en `.jsp` | **Cero.** El JSP solo pinta | §3 |
| Salida en JSP | **`<c:out>` / `fn:escapeXml`**, jamás `<%= %>` crudo | §5 |
| Acceso a datos desde JSP | **Prohibido** | Ni `DriverManager`, ni consultas en la página |
| Exposición | **Nunca directa a internet** mientras el framework no esté al día | §5 |
| Servidor | El que ya hay, **con su calendario en el inventario** | §2, cuadro de abajo |
| Destino de migración | **Spring Boot sin JSP** o **API + front separado** (§6) | Lo decide el estado del front, no el gusto |

**Calendario del servidor de aplicaciones — es la mitad del proyecto y casi nadie lo mira.** Datos
verificados: **Tomcat** soporta hoy 11.0.x, 10.1.x y 9.0.x; **8.5.x murió el 31-mar-2024**, 10.0.x el
31-oct-2022, 7.0.x el 31-mar-2021 y 8.0.x el 30-jun-2018 (tabla oficial de versiones). **WebLogic**
(PDF *Oracle Lifetime Support Policy — Fusion Middleware*, vigencia 13-abr-2026): **12.2.x Premier
hasta dic-2026 y Extended hasta dic-2027**; 14.1.x hasta dic-2030/dic-2033; 15.x (GA oct-2025) hasta
oct-2030/oct-2033. **JBoss EAP 7**: soporte de mantenimiento terminado el **30-jun-2025**, ahora en
ELS de pago hasta **31-oct-2027** (ELS-2 hasta 2030); **EAP 8 exige Java 17**. **WebSphere** es la
excepción que rompe la suposición: IBM declara que **no hay fecha de fin de soporte planificada para
8.5.5 ni 9.0.5** — no hay cuenta atrás ahí, aunque sí un límite práctico: un *fix pack* solo es
elegible para *iFix* durante dos años desde su publicación (confirmar en fuente primaria, §8).

Conclusión: **el acoplamiento al servidor es lo que convierte "actualizar el framework" en "migrar la
aplicación"**. Una aplicación que depende de JNDI del contenedor, de EJB, de *realms* de seguridad del
servidor, de `jboss-web.xml`/`weblogic.xml` o de bibliotecas puestas en el `lib` del servidor **no se
mueve sola**: eso hay que inventariarlo antes de estimar nada.

## 3. Arquitectura típica y por qué duele

El patrón es siempre el mismo: `ActionServlet` (Struts 1) o el filtro despachador (Struts 2) enruta
según `struts-config.xml`/`struts.xml` hacia una acción; la acción llena un formulario o un objeto de
valor y reenvía a un `.jsp` que pinta. Sobre eso, `Tiles` para plantillas y *tag libs* propias.

**El scriptlet es el problema estructural.** Un `<% %>` con lógica dentro de la página mezcla
presentación, negocio y acceso a datos en un fichero que **no compila hasta que alguien lo visita**,
que **no se puede probar unitariamente**, que no aparece en ningún análisis de dependencias y que el
IDE apenas entiende. Consecuencias reales, no estéticas: la misma regla de negocio acaba copiada en
seis páginas y divergiendo; un cambio de modelo obliga a revisar cientos de JSP a mano; y **la
inyección y el XSS viven ahí**, fuera del alcance de cualquier revisión sistemática. Por eso una
aplicación con lógica en los JSP es, literalmente, **irreparable por partes**: no hay refactor
incremental posible sin sacar primero la lógica de las páginas.

Reglas para el código que sobreviva mientras dure la migración:

- **Cero lógica y cero acceso a datos en `.jsp`**; solo etiquetas y expresiones sobre un modelo ya
  preparado. Todo scriptlet nuevo se rechaza en revisión.
- **JSTL y EL** en lugar de scriptlets, y `<c:out>` para **toda** salida.
- **Ninguna funcionalidad nueva en Struts**: lo nuevo se escribe fuera y se enlaza (§6).
- **Las dependencias se inventarían primero**: `pom.xml`/`WEB-INF/lib` completo, con versión y con
  fecha del último mantenimiento de cada jar. En estas aplicaciones lo normal es encontrar librerías
  abandonadas hace más de una década que ningún escáner reconoce porque están puestas a mano.

## 4. Calidad y testing

Sección **reducida a lo que aporta**: no hay *toolchain* moderna cómoda para JSP —el linter y el
análisis estático ven poco dentro de una página, y los tests unitarios sobre acciones de Struts 1
requieren andamiaje que ya nadie mantiene—. Lo que sí se hace, en este orden: **SCA sobre las
dependencias** (§5) porque es donde está el riesgo real y es barato; **pruebas de caracterización de
extremo a extremo** sobre los flujos críticos antes de tocar nada, que son las que permiten migrar
sin perder reglas de negocio no documentadas (`testing-qa-standards`); y, según se extrae lógica de
los JSP a clases, **tests unitarios sobre esas clases** con el criterio de `jvm-spring-standards`. El
gate de CI mínimo y realista: **build reproducible + SCA que rompe ante vulnerabilidad crítica
conocida explotada + suite E2E de los flujos de dinero y de autenticación**.

## 5. Seguridad — sección principal

**1. Ejecución de expresiones en el servidor (OGNL).** Es la familia que hizo célebre a Struts 2: el
framework evalúa expresiones OGNL sobre parámetros, cabeceras o valores de la petición, y una
expresión manipulada acaba ejecutando código. `CVE-2017-5638` (parser multipart, cabecera
`Content-Type`) y `CVE-2018-11776` (`namespace` no validado en la configuración) están **las dos en
KEV**. Reglas: **nunca** pasar entrada del usuario a nada que se evalúe (`%{...}`, `${...}` en
resultados, nombres de acción/namespace dinámicos), y mantener el framework en rama soportada, que es
lo único que de verdad corta esta familia.

**2. Deserialización y RCE por *plugin*.** `CVE-2017-9805` (plugin REST con XStream sobre XML) está
en KEV: deserializar datos no confiables es ejecución remota, punto. Regla dura: **ningún endpoint
deserializa objetos Java, XML o formatos que instancien clases arbitrarias desde la petición**;
*plugins* que no se usan, **desinstalados del `.war`** —no basta con no enrutarlos—.

**3. Subida de ficheros.** `CVE-2023-50164` y `CVE-2024-53677` son *path traversal* en la lógica de
subida que acaba en RCE, y la segunda es un arreglo incompleto de la primera; la corrección de Apache
**no es compatible hacia atrás** (obliga a `Action File Upload` y a subir de rama), que es
exactamente por qué mucha gente no la aplicó. Reglas: nombre generado por el servidor, ruta canónica
validada, almacenamiento **fuera del árbol servido**, lista blanca por contenido y tamaño máximo.
**Dato exacto y comprobable**: ninguna de esas dos CVE figuraba en el KEV consultado (versión
**2026.08.04**), pese a existir informes públicos de explotación activa — **la ausencia de una CVE en
KEV no significa que no se esté explotando**, y usar KEV como única fuente de priorización es un
error de triaje (`vulnerability-management-standards`).

**4. XSS por salida sin escapar.** `<%= request.getParameter("x") %>` es XSS reflejado directo, y es
el patrón dominante en estas bases de código. Se escapa **en la salida y según el contexto** (HTML,
atributo, JavaScript, URL): `<c:out>`/`fn:escapeXml` cubren HTML, **no** el resto —una variable
inyectada dentro de un `<script>` necesita codificación de JavaScript—. CSP ayuda, no corrige.

**5. Inyección SQL** en JSP y acciones que concatenan cadenas: consultas parametrizadas
(`PreparedStatement`), siempre; `sql-standards` para el detalle.

**6. Dependencias.** El `.war` típico arrastra decenas de jars antiguos: **SCA obligatorio**, con
inventario de lo puesto a mano en `WEB-INF/lib` (que el gestor de dependencias no ve) y de lo que vive
en el `lib` del servidor.

**7. Higiene del descriptor**: nada de páginas de error con traza, `WEB-INF` no servible, cookies de
sesión `HttpOnly`/`Secure`/`SameSite`, listados de directorio desactivados, consolas de administración
del contenedor **fuera de internet y con credenciales rotadas**.

**Por qué un framework sin parches no se compensa con un WAF.** Un WAF filtra patrones sobre la
petición; no ejecuta la lógica de la aplicación. Contra estas familias eso significa: las cargas OGNL
tienen variantes infinitas (codificación, fragmentación, campos alternativos) y **cada CVE de Struts
ha traído su ronda de *bypasses* del día siguiente**; contra la deserialización, el payload es un
objeto legítimo desde el punto de vista sintáctico; y contra un fallo de autorización, la petición
maliciosa es idéntica a la buena. Un WAF **compra tiempo mientras se parchea o se aísla**, y su valor
real es frenar el escaneo masivo automatizado, que no es poco. Declararlo como control compensatorio
permanente ante una auditoría —o como motivo para no actualizar— es insostenible, y es la decisión
que convierte un hallazgo en una brecha.

## 6. Salida

Tres rutas, y la elección la decide **el estado del front-end**, no la preferencia del equipo:

- **A Spring Boot con los JSP eliminados.** Es la ruta natural cuando la lógica de negocio en Java
  tiene valor y la interfaz es formularios de gestión. Se sustituye el despachador y se rehacen las
  vistas con un motor moderno (Thymeleaf u otro); **arrastrar los JSP a Spring Boot es la trampa**:
  técnicamente posible en algunos escenarios, pero conserva el problema estructural (§3) y añade
  fricción de empaquetado. *Strangler fig*: un *reverse proxy* delante y ruta a ruta.
- **API + front separado.** Cuando la interfaz hay que rehacerla de todos modos: se expone la lógica
  como API (`api-design-standards`) y el front se construye aparte (`frontend-frameworks-standards`).
  Más caro, y el único camino si la aplicación debe ser usable en móvil o integrarse con terceros.
- **Reescritura completa.** Justificada cuando la lógica está en los JSP (§3) y no hay nada
  rescatable, o cuando el dominio ha cambiado tanto que migrar sería congelar reglas obsoletas.
  Requiere caracterización previa: **la especificación viva está en el código, no en un documento**.

**Contención mientras dura la migración** (y hay que dimensionarla al empezar, no cuando falle):
sacar la aplicación de internet o ponerla tras autenticación fuerte y red identificada, restringir
la salida de red del servidor —si cae, que no llame a casa—, usuario de base de datos con permisos
mínimos, y monitorización con reglas específicas para estas familias (`detection-engineering-standards`).

## 7. Prohibiciones

- ❌ PROHIBIDO desplegar una aplicación **nueva** sobre JSP o Struts, en cualquier variante.
- ❌ PROHIBIDO exponer a internet una aplicación sobre Struts 1 o sobre una rama de Struts 2 sin
  soporte, sin plan de salida con fecha.
- ❌ PROHIBIDO añadir scriptlets (`<% %>`, `<%! %>`) o lógica de negocio a un `.jsp`.
- ❌ PROHIBIDO acceso a base de datos desde una página JSP.
- ❌ PROHIBIDO `<%= %>` con datos que vengan del usuario o de la base de datos, sin escapar.
- ❌ PROHIBIDO construir SQL por concatenación en acciones o páginas.
- ❌ PROHIBIDO pasar entrada del usuario a expresiones evaluadas en servidor (OGNL, EL dinámica) o a
  nombres de acción, *namespace* o resultado.
- ❌ PROHIBIDO deserializar objetos que vengan de la petición; y *plugins* no usados, fuera del `.war`.
- ❌ PROHIBIDO guardar ficheros subidos dentro del árbol servido o con el nombre que da el cliente.
- ❌ PROHIBIDO dejar jars en `WEB-INF/lib` fuera del gestor de dependencias y del SCA.
- ❌ PROHIBIDO trazas de error y consolas de administración del contenedor accesibles desde fuera.
- ❌ PROHIBIDO declarar un WAF como corrección de una CVE del framework o como motivo para no parchear.
- ❌ PROHIBIDO "migrar" cambiando de servidor de aplicaciones sin resolver `javax` → `jakarta`: es el
  trabajo, no el trámite.
- ❌ PROHIBIDO estimar la migración sin inventariar antes dependencias, acoplamiento al contenedor y
  flujos críticos sin tests.

## 8. Verificación web obligatoria

Comprobar siempre: **rama y versión soportadas de Struts** y sus anuncios de EOL (el sitio del
proyecto va por detrás del repositorio: contrastar con el feed de *releases*), los **avisos de
seguridad de Struts** (S2-xxx) y si alguna CVE aplicable está en el **catálogo KEV de CISA**
—descargable en JSON crudo, con `catalogVersion` y fecha—, la **versión soportada del contenedor**
(tabla oficial de Tomcat con su columna de EOL; PDF de *Lifetime Support Policy* de Oracle para
WebLogic, con su fecha de vigencia en portada; ciclo de vida publicado por IBM y por Red Hat), la
versión vigente de **Jakarta EE** y de **Jakarta Pages**, y el estado de mantenimiento de cada jar
del inventario.

**Huecos declarados (sin dato verificado, NO rellenar de memoria)**: (a) la política de EOL de Struts
**no está documentada formalmente** por el proyecto —la ventana de "unos seis meses de correcciones
de seguridad tras el anuncio" procede de fuentes secundarias, no de una política publicada—: no
planifiques sobre ella; (b) las fechas de **WebSphere** ("sin fecha de fin de soporte planificada"
para 8.5.5 y 9.0.5) y de **JBoss EAP** (ELS-1 hasta 31-oct-2027, ELS-2 hasta 2030) proceden de
resúmenes de buscador sobre páginas de IBM y Red Hat, **no de cita verbatim de la fuente primaria**:
confirmar antes de usarlas en un plan; (c) fecha de **Jakarta EE 12** — las fuentes consultadas se
contradicen (un plan de release apuntaba a **jul-2026** y la página del proyecto a **Q2 2027**):
**discrepancia declarada, no elijas una sin comprobarlo**; (d) no verificado el estado de soporte
comercial de terceros para ramas de Struts sin soporte (existe, pero no se han comprobado condiciones
ni cobertura).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
