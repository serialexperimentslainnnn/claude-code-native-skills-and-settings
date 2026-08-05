---
name: web-app-servers-standards
description: The web server and application server as a host you operate, harden and patch — not as the proxy that decides routing. Use when working with Apache httpd (httpd.conf, apache2.conf, sites-available, a2enmod, .htaccess, AllowOverride, mpm_prefork/mpm_worker/mpm_event, MaxRequestWorkers, ServerLimit, ThreadsPerChild, ServerTokens, mod_ssl, mod_status, mod_security, apachectl configtest), nginx as an origin server (nginx.conf server blocks, worker_processes, worker_connections, worker_rlimit_nofile, client_max_body_size, sendfile, gzip, autoindex, server_tokens, nginx -t), IIS (applicationHost.config, web.config, appcmd, IISAdministration and WebAdministration PowerShell modules, application pools, ApplicationPoolIdentity, recycling and idleTimeout, request filtering, http.sys, ASP.NET Core Module), a Java application server (Tomcat server.xml, context.xml, catalina.sh, CATALINA_OPTS, Manager and Host Manager apps, Jetty jetty.xml and start.d, WildFly standalone.xml and jboss-cli, WebLogic config.xml, WLST, T3/IIOP, WebSphere Liberty server.xml and traditional wsadmin), the javax to jakarta namespace migration and Jakarta EE version targets, PHP-FPM pools (www.conf, pm dynamic/static/ondemand, pm.max_children, listen.owner), WSGI/ASGI servers behind the web server (gunicorn, uvicorn, waitress), sizing the process or thread model, request size limits, timeouts, file descriptor limits, a 502 or 504 that is really a server limit, TLS termination on the origin and automatic certificate renewal, response security headers, static file serving and compression, access log format and rotation, or hardening a server that runs as root, lists directories, leaks its version or exposes an admin console.
---

# Estándares de servidores web y de aplicaciones — la pieza que se opera, no la que reparte

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: el servidor de origen no es "donde se copia el código". Es un proceso con un
> modelo de concurrencia, unos límites y una superficie de ataque propios, y **casi todo el
> incidente que la gente atribuye a la aplicación es un límite mal puesto en esta capa**.

## 1. Alcance y triggers

Aplica a **instalar, dimensionar, endurecer, parchear y operar** el servidor que atiende la
petición: Apache httpd, nginx e IIS como servidores web; Tomcat, Jetty, WildFly/JBoss EAP,
WebLogic y WebSphere como servidores de aplicaciones; PHP-FPM y los servidores WSGI/ASGI como
proceso que ejecuta el código; y sus límites, TLS de origen, cabeceras, ficheros estáticos y
registro.

Disparadores: `httpd.conf`, `apache2.conf`, `.htaccess`, `nginx.conf` (bloque `server`),
`applicationHost.config`, `web.config`, `appcmd`, `server.xml`, `context.xml`, `standalone.xml`,
`jboss-cli`, `config.xml`/WLST, `server.xml` de Liberty, `www.conf` de PHP-FPM, `mpm_event`,
`worker_connections`, `MaxRequestWorkers`, `pm.max_children`, `LimitNOFILE`, "502 Bad Gateway",
"504 Gateway Timeout", "grupo de aplicaciones", "reciclado", `javax` → `jakarta`.

**No aplica** — el reparto ya tiene dueña: **`load-balancing-standards` posee el balanceador y el
proxy inverso, sus comprobaciones de salud, el drenaje y la terminación TLS del borde** (aquí el
**servidor de origen** que atiende detrás y las comprobaciones que *expone*), **`caching-cdn-standards`
la política de caché, el CDN y las cabeceras que la gobiernan**, `networking-standards` y
`firewall-policy-standards` la conectividad y el filtrado, `dns-standards` los registros, y
`cryptography-pki-standards` **la elección de algoritmo, suite y la emisión del certificado** (aquí
solo su instalación, renovación y recarga). El **código que corre encima** es de `php-standards`,
`python-standards`, `jvm-spring-standards` y `dotnet-framework-legacy-standards` —**IIS es la
dependencia del legacy Microsoft, que delega en esta skill** para el servidor—, mientras
`kubernetes-standards` posee el despliegue si el servicio va en contenedor, `cicd-standards` e
`iac-standards` cómo llega la configuración a la máquina, `observability-standards` métricas y
paneles, `sre-practice-standards` el SLO, `vulnerability-management-standards` el triaje del CVE,
`appsec-standards` la vulnerabilidad de la aplicación, `identity-access-management-standards` el
OIDC, `privacy-engineering-standards` el dato personal en el registro y `grc-compliance-standards`
la evidencia. El sistema operativo debajo es de `linux-administration-standards`,
`rhel-fedora-standards`, `linux-hardening-standards` y `windows-server-ad-standards`; el respaldo de
`backup-recovery-standards`, y `onprem-standards` es el paraguas (con `homelab-standards` como banco
de pruebas). Sus hermanas de tanda: `mail-servers-standards` y `file-servers-standards` son **otro
servicio, no otra configuración del mismo**.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Recomendado | Alternativa justificable |
|---|---|---|
| Servidor web genérico | **nginx** rama estable (`1.30.x`; `1.30.0` abrió el 14-abr-2026, `1.30.4` con CVE-2026-42533 y CVE-2026-60005) por consumo por conexión | **Apache httpd 2.4.x** (`2.4.68`, 8-jun-2026) si hace falta `.htaccess` por tenant, módulos de terceros o integración con el paquete de la distro |
| Rama de nginx | **estable** en producción; *mainline* (`1.31.x`, `1.31.3` de 15-jul-2026) solo si necesitas una función concreta | *mainline* en entornos donde el ritmo de parche importa más que la estabilidad de interfaz |
| httpd 2.6 | **No**: no hay GA; el tronco de desarrollo va como 2.5.x | — |
| httpd 2.2 | **PROHIBIDO**: EOL, última publicación `2.2.34` (jul-2017) | — |
| MPM de Apache | **`event`** con PHP-FPM o proxy a la aplicación | `prefork` **solo** si un módulo no es *thread-safe* (`mod_php` clásico) — y esa es la señal de que hay que salir de él |
| Ecosistema nginx tras las bifurcaciones (F5, freenginx, Angie) | **Ya verificado en `load-balancing-standards`**: consúltalo allí, no se duplica | — |
| Servidor en Windows | **IIS 10.0** (la versión que trae Windows Server 2025, soportado hasta 10-oct-2034). **No existe "Windows Server 2026"**: lo que se publica en 2026 son actualizaciones acumulativas | nginx/httpd en Windows solo para desarrollo |
| Contenedor de servlets | **Tomcat 11.0.x** (Jakarta EE 11) para código nuevo; **10.1.x** (EE 10) si la pila aún no llega | **Jetty 12.1** cuando se embebe o se necesita el modelo `EE8/EE9/EE10/EE11` en el mismo binario |
| Tomcat 9.0.x | **Migrar**: soporte hasta **31-mar-2027**. Habrá rama `9.1.x` (hasta **31-dic-2030**) pero **sin conectores APR/nativos** para HTTP, HTTPS y AJP: es prórroga, no destino | — |
| Jetty 9/10/11 | **PROHIBIDO**: desde el **1-ene-2026 ya no se publican a Maven Central**; solo soporte de pago (Webtide, HeroDevs, TuxCare) | — |
| Servidor Jakarta EE completo | **WildFly 41.0.0.Final** (16-jul-2026, EE 11 desde WildFly 40, 21-may-2026) si no hay contrato | **JBoss EAP 8.1** con soporte comercial; **WildFly EE 10** como variante puente si aún no puedes con EE 11 |
| JBoss EAP 7.x | **Migrar a 8.1**: mantenimiento de EAP 7 terminó el **30-jun-2025**; a partir de ahí solo **ELS** (exige estar en 7.4, renovable hasta **oct-2027**) | — |
| WebLogic | **14.1.2 (14c)**, certificado con JDK 17 y 21. **No existe "15c"** | Migrar a WildFly/EAP o a Liberty si el coste de licencia no se justifica |
| WebSphere | **Liberty** (modelo SSCD de flujo único, entrega cada ~4 semanas, **sin fecha de fin de soporte**; `26.0.0.5` añadió Jakarta EE 11 y Spring Boot 4.0) | **WAS traditional 9.0.5**: IBM **no anuncia fecha de fin**, pero la presión real es la vigencia del *fix pack*, del Java y del SO debajo |
| Ejecutar PHP | **PHP-FPM** por *socket* Unix, un *pool* y un usuario por aplicación | FrankenPHP/servidor embebido solo con criterio explícito |
| Ejecutar Python | **WSGI/ASGI detrás del servidor web** (gunicorn+uvicorn workers, o uvicorn/hypercorn) — nunca expuesto directo | — |

**Jakarta EE y el cambio de espacio de nombres**: Jakarta EE 11 se publicó el **26-jun-2025** (Core
dic-2024, Web Profile mar-2025), exige **Java 17+**, elimina *Managed Beans*, las referencias al
`SecurityManager` (JEP 411), SOAP with Attachments y XML Binding, y las especificaciones
opcionales. **Jakarta EE 12 no está publicado** y sus fechas se contradicen entre fuentes (§8).
El salto `javax.*` → `jakarta.*` es **binario y no negociable**: es el corte real entre Tomcat 9 y
10+, y entre EAP 7 y 8. **No es un `sed`**: afecta a dependencias transitivas, ficheros de
descriptor y bytecode de terceros; se planifica con la herramienta de migración del proyecto y se
verifica ejecutando, no compilando.

## 3. El modelo de proceso: por qué el dimensionado por defecto casi siempre está mal

El valor por defecto lo fija quien empaqueta, **sin saber tu memoria ni tu perfil de petición**.
Regla única: **el número de trabajadores lo dicta la memoria residente del peor proceso y la
naturaleza de la espera**, no el número de núcleos.

- **Apache**: `prefork` (un proceso por conexión, memoria cara, seguro con módulos no reentrantes),
  `worker` (híbrido proceso/hilo) y `event` (hilos + gestión asíncrona de conexiones ociosas y
  *keep-alive*). Con `event`, `MaxRequestWorkers` y `ServerLimit` × `ThreadsPerChild` deben ser
  coherentes o el arranque los recorta en silencio. **Con `mod_php` estás atado a `prefork`**: es
  la razón técnica para pasar a PHP-FPM, no una moda.
- **nginx**: `worker_processes auto` (uno por núcleo) y `worker_connections` como **techo por
  trabajador que incluye las conexiones hacia el *upstream***, no solo las del cliente: el límite
  efectivo es aproximadamente la mitad al hacer de proxy. `worker_rlimit_nofile` debe ser mayor que
  `worker_connections`, o el límite real será el de descriptores.
- **IIS**: el grupo de aplicaciones es la **frontera de fallo y de identidad** (`ApplicationPoolIdentity`
  = cuenta virtual por grupo). Un grupo por aplicación, nunca compartido entre inquilinos. El
  **reciclado periódico por reloj y el `idleTimeout` vienen activos por defecto**: en una aplicación
  con arranque caro son latencia sorpresa y pérdida de estado en memoria — desactiva el reciclado por
  hora, deja el reciclado por memoria/peticiones, y usa arranque anticipado (`AlwaysRunning` +
  `preloadEnabled`). El *web garden* (`maxProcesses` > 1) **rompe la sesión en memoria**: no es un
  botón de rendimiento.
- **PHP-FPM**: `pm = dynamic` con `pm.max_children` calculado como *memoria disponible para el
  pool / RSS del peor proceso*, y `pm.max_requests` para acotar fugas. `pm = static` cuando la carga
  es estable y la latencia de arranque importa; `ondemand` solo en multi-inquilino disperso. Un
  `pm.max_children` corto es **la causa número uno de 502 intermitentes** con nginx delante.

## 4. Validación y gates

- **Nada se recarga sin validar**: `apachectl configtest` / `httpd -t`, `nginx -t`,
  `appcmd list config` o el esquema de `web.config`. En CI, la validación se ejecuta contra la
  configuración renderizada, no contra la plantilla.
- **Recarga, no reinicio**: `nginx -s reload`, `apachectl graceful`, reciclado solapado en IIS.
  Un reinicio duro corta peticiones en vuelo; combinado con el drenaje del balanceador
  (`load-balancing-standards`) el despliegue no debe perder ni una.
- **Gates en orden de coste**: (1) validación sintáctica; (2) *linter* de configuración y difs
  contra la referencia; (3) prueba de humo HTTP contra el origen **sin pasar por el balanceador**;
  (4) verificación de TLS y cabeceras (`testssl.sh`, un chequeo de cabeceras) sobre el entorno
  desplegado; (5) prueba de carga que confirme el dimensionado elegido, no el por defecto.
- **La configuración es código**: fuera de `iac-standards` no hay cambios a mano en producción. Un
  `.htaccess` editado en caliente es un cambio no versionado, por definición.

## 5. Seguridad del stack

- **Usuario sin privilegios**: el proceso maestro puede necesitar root para el puerto bajo (o
  `CAP_NET_BIND_SERVICE`/`AmbientCapabilities`), los trabajadores **nunca**. Un servidor de
  aplicaciones Java corriendo como root es un fallo de diseño, no un ajuste pendiente.
- **Listado de directorios desactivado**: `Options -Indexes`, `autoindex off`, examinar directorios
  apagado en IIS. Y la raíz del documento **fuera** del árbol de código y de `.git`.
- **Versión fuera de las cabeceras**: `ServerTokens Prod` + `ServerSignature Off`,
  `server_tokens off`, y en IIS quitar `Server`, `X-Powered-By` y `X-AspNet-Version`. No es
  seguridad real, pero es reconocimiento gratis para el atacante y hallazgo seguro en auditoría.
- **Módulos innecesarios fuera**: cada módulo cargado es superficie y es CVE que te obliga a
  parchear. Revisa `mod_status`, `mod_info`, `mod_userdir`, `mod_autoindex`, WebDAV, CGI y los
  módulos de terceros. En IIS, quita las características de rol que no usas y activa el filtrado de
  peticiones. En Tomcat/WildFly, borra las aplicaciones de ejemplo y documentación.
- **`.htaccess` es superficie**: `AllowOverride None` por defecto. Habilitarlo delega configuración
  a quien pueda escribir en el directorio —incluida una subida de fichero comprometida— y penaliza
  cada petición con búsquedas en el sistema de ficheros. Se activa por directorio y con lista
  explícita de directivas, nunca globalmente.
- **Panel de administración de los comerciales**: Tomcat Manager/Host Manager, consola de WildFly,
  `/console` y **T3/IIOP** de WebLogic, consola administrativa de WebSphere. **Nunca en Internet**:
  escuchan en la red de gestión o en *loopback* detrás de un túnel, con credencial propia y MFA
  donde exista. **T3/IIOP expuesto es un histórico de RCE por deserialización**: si no lo usas,
  desactívalo; si lo usas, fíltralo por red y aplica la lista de clases permitidas.
- **TLS**: TLS 1.2 como mínimo absoluto, 1.3 preferido; SSLv3/TLS 1.0/1.1 desactivados. *Stapling*
  OCSP activo, HSTS solo cuando todo el dominio ya va por HTTPS (y `preload` solo con decisión
  consciente: es difícil de revertir). **La elección de suite y curva es de
  `cryptography-pki-standards`.**
- **Renovación automática de certificado**: ACME con recarga posterior automática, y **vigilancia de
  caducidad independiente del agente que renueva** — el fallo real no es que caduque, es que el
  agente renovó y nadie recargó el servicio.
- **Cabeceras de respuesta que sí son del servidor**: `Strict-Transport-Security`,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Content-Security-Policy` y
  `Permissions-Policy`. La **política** de CSP la define la aplicación (`appsec-standards`); el
  servidor la emite de forma consistente y **no la duplica** —cabecera repetida por servidor y
  aplicación es comportamiento indefinido en la práctica—. `X-XSS-Protection` está obsoleta: no la
  pongas.
- **Ficheros estáticos**: sirviéndolos desde el servidor web, no desde el intérprete. Deniega por
  patrón lo que nunca debe salir (`.git`, `.env`, copias `~`, `.bak`, ficheros de configuración) y
  desactiva la ejecución de intérprete en directorios de subida — **una subida que se sirve como
  código es RCE**, y es el error más repetido del dominio.

## 6. Límites, 502/504 y registro

- **Un 502/504 es, casi siempre, un límite mal puesto aquí, no un fallo de la aplicación.** Antes de
  tocar código, comprueba: agotamiento de trabajadores del *backend* (`pm.max_children`,
  `maxThreads`, cola de aceptación), *timeout* de lectura del *upstream* menor que el tiempo real de
  la petición, tamaño de cabecera o de cuerpo por encima del búfer (`proxy_buffer_size`,
  `client_max_body_size`, `LimitRequestBody`, `maxAllowedContentLength`), y descriptores agotados.
- **Cuatro límites que se fijan siempre, con número justificado**: tamaño máximo de petición y de
  cabecera; *timeouts* de cliente y de *upstream* **coherentes entre capas** (el del balanceador
  debe ser mayor que el del origen, o verás cortes sin traza); descriptores de fichero
  (`LimitNOFILE` en la unidad de systemd, no en un `ulimit` de un *script*); y *backlog* de escucha
  acorde a `somaxconn`.
- **Registro**: acceso y error separados, formato estructurado (JSON) si va a un colector, y
  **rotación por la herramienta del sistema con reapertura de descriptores** —una rotación que solo
  renombra deja el proceso escribiendo en un inodo huérfano y llena el disco sin que nadie lo vea—.
  Reserva espacio: **el disco lleno por logs tumba el servicio**.
- **Qué no se registra**: `Authorization`, `Cookie`, cuerpos de POST, tokens en la cadena de
  consulta y contraseñas en la URL. La **IP es dato personal**: retención acotada y anonimización o
  seudonimización según lo que fije `privacy-engineering-standards`.
- **Compresión y estáticos**: `gzip`/`brotli` solo sobre tipos comprimibles (comprimir un JPEG o un
  ZIP gasta CPU para nada), variantes precomprimidas cuando el contenido es estático, `sendfile` y
  `tcp_nopush` activos. Cuidado con comprimir respuestas que mezclan secreto y entrada del usuario
  sobre TLS (clase BREACH). **La política de caché y el CDN son de `caching-cdn-standards`**; aquí
  solo que el servidor sepa emitir `ETag`/`Last-Modified` y responder `304`.
- **Métricas mínimas**: peticiones por segundo y por código, latencia por percentil, trabajadores
  ocupados frente a límite, conexiones activas, cola de aceptación y errores de *upstream*. Sin
  "trabajadores ocupados / límite" **no puedes distinguir saturación de lentitud**.

## 7. Sostenibilidad y prohibiciones

Cadencia: parche de seguridad del servidor **fuera de ventana** si el CVE es explotable en remoto;
salto de rama menor planificado por trimestre; salto de rama mayor (Tomcat 9→11, EAP 7→8) tratado
como **proyecto con presupuesto**, porque arrastra el cambio de espacio de nombres. Todo servidor
tiene **fecha de fin de soporte anotada en el inventario**: sin ella, la migración siempre llega
tarde.

- ❌ Servir con un servidor o rama fuera de soporte (httpd 2.2, Tomcat 8.5/10.0, Jetty 9/10/11,
  EAP 7 sin ELS) porque "funciona".
- ❌ Ejecutar trabajadores como root, o el servidor de aplicaciones con la cuenta del administrador.
- ❌ Dejar el dimensionado por defecto en producción sin haber calculado memoria por proceso.
- ❌ Exponer a Internet la consola de administración, `mod_status`, `/manager`, `/console` o T3/IIOP.
- ❌ Habilitar `.htaccess` globalmente, o permitir que el usuario de la aplicación escriba en la
  configuración del servidor.
- ❌ Permitir la ejecución de intérprete en directorios donde el usuario sube ficheros.
- ❌ Terminar TLS con versiones o suites obsoletas, o con un certificado renovado a mano.
- ❌ Renovar con ACME sin recarga automática y sin vigilancia de caducidad independiente.
- ❌ Registrar cabeceras de autenticación, cuerpos de POST o tokens en la cadena de consulta.
- ❌ Rotar logs renombrando sin señal de reapertura, o dejar el disco de logs sin cuota ni alerta.
- ❌ Tratar un 502/504 como bug de la aplicación sin revisar antes trabajadores, *timeouts* y búferes.
- ❌ Poner un *timeout* de origen mayor que el del balanceador (o al revés sin saberlo): produce
  cortes sin traza en ninguno de los dos.
- ❌ Cambiar configuración a mano en producción y no devolverla al repositorio.
- ❌ Migrar `javax` → `jakarta` con búsqueda y reemplazo, sin ejecutar las pruebas de integración.
- ❌ Duplicar cabeceras de seguridad entre servidor y aplicación esperando que "gane la más estricta".

## 8. Verificación web obligatoria

1. **Versión estable y CVE abiertos** de httpd, nginx (rama estable frente a *mainline*) e IIS/SO
   base. Comprueba en el aviso del proyecto, no en el paquete de la distro.
2. **Calendario de soporte** de Tomcat (fechas de 9.0.x/9.1.x), Jetty, WildFly, JBoss EAP,
   WebLogic y WebSphere. Cambian y son el dato que decide la migración.
3. **Estado de Jakarta EE 12**: no publicado a ago-2026. **Discrepancia declarada**: InfoQ recogió
   un plan con GA en jul-2026 mientras la página del proyecto en `jakarta.ee` lo marca "Under
   Development" con objetivo de release final en **Q2-2027**. No fijes fecha sin releer la fuente
   del proyecto.
4. **Hueco no verificado — WebLogic**: la fecha exacta de Premier/Extended Support de 14.1.2 vive en
   el documento *Lifetime Support Policy* de Fusion Middleware y en el artículo **KB65053 de My
   Oracle Support**, que **exige login y no es verificable públicamente**. La política pública
   confirma que Fusion Middleware 12c termina Premier en **dic-2026** y Extended en **dic-2027**;
   para 14c **hay que consultar MOS con cuenta**. No se rellena aquí.
5. **Hueco no verificado — JBoss EAP 8.1**: Red Hat publica la política (7 años: 4 de Full Support +
   3 de Maintenance, más ELS opcional) pero las fechas concretas de 8.1 hay que sacarlas de la tabla
   de *Product Life Cycles* del portal en el momento de decidir.
6. **Estado del ecosistema nginx tras las bifurcaciones**: **no se re-verifica aquí**, lo posee
   `load-balancing-standards`; si esa skill está desactualizada, actualízala allí.
7. **Cabeceras de seguridad**: comprueba en MDN cuáles siguen vigentes y cuáles quedaron obsoletas
   antes de copiar una plantilla de hace años.
8. **Versión del SO que fija la del servidor** (IIS ligado a Windows Server; httpd/nginx a la rama
   de la distro) y su fecha de fin de soporte.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
