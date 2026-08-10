---
name: appsec-standards
description: Application security methodology. Use when threat modeling (STRIDE, abuse cases), reviewing code against OWASP Top 10 or ASVS, triaging IDOR/BOLA, SSRF, XSS, SQLi, SSTI, XXE, CSRF, CSP, deserialization or path traversal findings, or selecting SAST/DAST/SCA tools.
---

# Estándares de seguridad de aplicaciones (AppSec)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, revisar o auditar la seguridad de una aplicación **como disciplina**: modelado de amenazas, requisitos y criterios de aceptación de seguridad, identificación y triaje de clases de vulnerabilidad en diseño y código propios, selección y calibrado de herramientas de análisis (SAST/DAST/IAST/SCA) y el programa que lo sostiene (SDLC seguro, security champions). Triggers: "modelado de amenazas", "STRIDE", "attack tree", "abuse case", "OWASP Top 10", "ASVS", "revisión de seguridad", "IDOR", "BOLA", "SSRF", "XSS", "inyección", "deserialización", "CSP", "CORS", "mass assignment", "falso positivo de SAST", "criterio de aceptación de seguridad".

Principio rector: **la herramienta encuentra lo que sabe buscar; el modelo de amenazas encuentra lo que importa**. Ningún analizador estático detecta autorización rota, abuso de lógica de negocio ni un límite de confianza mal puesto (§4) — por eso el orden es diseño → controles → verificación automática, nunca al revés.

**No aplica**: ver `vulnerability-management-standards` (para el ciclo de vida de vulnerabilidades de terceros: CVE, CVSS/EPSS/KEV, SLAs de remediación, VEX, inventario), `cicd-standards` (para la ejecución de los gates de escaneo en el pipeline, OIDC, firma y SBOM), `onprem-standards` (para ejecutar el parcheo y las ventanas de mantenimiento en servidores), `linux-hardening-standards` (baseline CIS, auditd, OpenSCAP), `kubernetes-standards` (para hardening de imágenes y admisión), `identity-access-management-standards` (para el diseño del proveedor de identidad: flujos OAuth 2.1/OIDC, SAML, passkeys, SCIM, motores de políticas RBAC/ABAC/ReBAC — aquí solo se cubre cómo la aplicación **consume y verifica** esa identidad y cómo se rompe), `microservices-architecture-standards` (para mTLS, propagación de identidad y authz entre servicios), `offensive-security-standards` (el lado ofensivo **autorizado**: RoE, ejecución del pentest/red team, informe y retest — aquí la prevención y el control de esas mismas clases de vulnerabilidad; sus hallazgos entran por §4), `ctf-lab-standards` (entrenamiento en laboratorio aislado), `sre-practice-standards` (para respuesta a incidentes y operación de la telemetría), `iac-standards` y las skills de nube (para controles de infraestructura), `grc-compliance-standards` (aceptación formal de riesgo y marco normativo). La **seguridad específica del stack** (APIs, sinks y flags concretos de cada lenguaje) vive en la §5 de la skill del lenguaje: `python-standards`, `typescript-standards`, `go-standards`, `rust-standards`, `jvm-spring-standards`, `dotnet-standards`, `php-standards`, `mobile-standards`, `c-standards` y `cpp-standards` (memoria, enteros y hardening del binario), `sql-standards` (**cómo se construye una consulta para que la inyección sea imposible**: parametrización, quoting de identificadores dinámicos, SQL generado frente a escrito a mano) , `powershell-standards` (`ConvertTo-SecureString -AsPlainText`, política de ejecución, firma de scripts, JEA) y `solidity-standards` (**clases de vulnerabilidad propias de contratos EVM**: reentrada —incluida la de solo lectura—, manipulación de oráculo, préstamos relámpago, colisión de *storage* en proxies, precisión y redondeo. El cálculo de riesgo es distinto al del resto del catálogo: **el código desplegado es inmutable, público y maneja valor**, así que no hay parche ni rollback). `opensource-licensing-standards` (la selección de SAST/DAST/SCA es de aquí, pero **si la herramienta elegida es libre, de pago o *source-available* lo decide su política** — el precedente que lo justifica es que **Brakeman no es MIT sino licencia propietaria de pago para uso comercial**, pese a ser el escáner por defecto de medio ecosistema Ruby). Esta skill es **metodología y clases de vulnerabilidad**, agnóstica del stack: aquí se decide **cómo se triaja y se prueba** un hallazgo de SQLi; allí, **cómo se escribe el código para que no exista**.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Los datos siguientes son de agosto 2026 y caducan.

| Ámbito | Default | Motivo / alternativa justificable |
|---|---|---|
| Requisitos verificables | **OWASP ASVS 5.0.0** (mayo 2025; siguiente objetivo, patch 5.0.1), **nivel L2** | L2 es la línea base recomendada para aplicaciones de negocio; L1 es suelo, no meta; L3 solo para alto valor o entorno regulado |
| Lista de riesgos de referencia | **OWASP Top 10:2025** (8ª edición; anunciada nov 2025, final ene 2026) | Sustituye a 2021. Toda regla, informe o mapeo que aún cite A10:2021 SSRF está desactualizado (§5) |
| APIs | **OWASP API Security Top 10 2023** | Sigue siendo la edición vigente en 2026; no existe edición 2025/2026 |
| Catálogo de controles | **OWASP Proactive Controls v4 (2024)** | Complemento constructivo al Top 10, que es descriptivo y no prescriptivo |
| Método de modelado | **STRIDE** por elemento sobre DFD + abuse cases; attack trees solo para amenazas concretas de alto valor | Threat Modeling Manifesto: valor sobre ceremonia. PASTA si el driver es riesgo de negocio; LINDDUN si es privacidad |
| Madurez del programa | **OWASP SAMM v2** (Threat Assessment, Security Requirements, Secure Architecture) | Marco de mejora medible, no certificación ni checklist |
| SAST | **Semgrep** (reglas YAML legibles y editables, CLI ligera, integración CI trivial) | **CodeQL** si ya usas GitHub code scanning y quieres data-flow profundo; SonarQube si además necesitas calidad/cobertura — su Community Build **no** incluye taint analysis |
| DAST | **ZAP** (Apache-2.0, sin tiers de pago) | Ojo al nombre: dejó OWASP en 2023 (Linux Foundation / Software Security Project) y desde sep 2024 es *ZAP by Checkmarx*; sigue OSS y gobernado por su core team |
| SCA | **OSV-Scanner** (Google) y/o **Grype**+Syft; Dependency-Track como capa de triaje | Ver §6 sobre el compromiso de cadena de suministro de Trivy (marzo 2026) antes de elegirlo |
| IAST | **No por defecto** | Mercado muy fino, sin opción OSS madura, cobertura limitada a lo que ejerciten los tests y 2-5 % de overhead. Justifícalo o no lo compres |
| Programa humano | **Security champions voluntarios** (OWASP Security Champions Guide) | Asignar el rol por decreto no funciona: requiere interés genuino y tiempo asignado |

## 3. Modelado de amenazas y SDLC seguro

### Cuándo se modela (no "una vez al año")
Obligatorio **antes de escribir código** en: sistema o servicio nuevo, cambio de límite de confianza (nueva integración externa, nuevo tipo de actor, nuevo almacén de datos), cambio en authn/authz, y tratamiento nuevo de datos personales o de pago. Para el resto: **iterativo e incremental** — se modela la funcionalidad añadida, no el sistema entero.

### Las cuatro preguntas (marco mínimo)
1. **¿Qué estamos construyendo?** DFD con procesos, almacenes, flujos y **límites de confianza dibujados explícitamente**. Sin límites de confianza el diagrama es documentación, no modelo.
2. **¿Qué puede ir mal?** STRIDE por elemento: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege. Complementar con **abuse cases** ("como atacante, quiero…") para la lógica de negocio, que es justo lo que STRIDE de manual no cubre.
3. **¿Qué hacemos al respecto?** Cada amenaza cierra con una decisión explícita: **mitigar / trasladar / eliminar / aceptar**. Aceptar es válido y se documenta con dueño y fecha de revisión; "pendiente" no es una decisión.
4. **¿Lo hicimos bien?** Cada mitigación acordada se convierte en requisito verificable y en test. Un modelo cuyas mitigaciones no llegan al backlog no ha servido para nada.

**Attack trees** solo cuando aporten: objetivo del atacante en la raíz, rutas alternativas en las ramas, para razonar sobre defensa en profundidad de un activo concreto ("extraer la base de clientes"). No sustituyen a STRIDE ni se hacen de todo.

### De amenaza a criterio de aceptación
Las historias llevan **criterios de aceptación de seguridad explícitos y verificables**, en el mismo formato que los funcionales y en la misma historia, no en un documento aparte. Cada criterio referencia el requisito ASVS con **prefijo de versión** (`v5.0.0-<capítulo>.<sección>.<requisito>`) y se prueba.

- ❌ Malo: "el endpoint debe ser seguro".
- ✅ Bueno: "un usuario autenticado que solicita `/invoices/{id}` de otro tenant recibe 404 y se registra un evento de authz denegada con `user_id` y `resource_id`" — verificable, testeable, cubre A01.

**Definition of Done de seguridad** (además de la del `CLAUDE.md`): amenazas del cambio revisadas, criterios de seguridad probados con test automático, hallazgos de los gates resueltos o con excepción registrada, y ningún secreto nuevo en código, logs o historial.

### Trazabilidad de requisitos
La numeración de ASVS **no es estable entre versiones**: cita siempre con prefijo. ASVS 5.0 eliminó los mapeos a CWE y NIST 800-63 (alineación futura vía CRE): si necesitas trazabilidad a CWE para auditoría, la construyes y la mantienes tú.

## 4. Verificación: gates, herramientas y triaje

### Orden de coste creciente (qué rompe el build)
1. **Secret scanning** en pre-commit y en CI sobre todo el diff del PR. Un secreto detectado rompe el build **siempre** y dispara rotación: el secreto ya está quemado aunque se reescriba el commit.
2. **SAST incremental** sobre el diff, no sobre el repo entero. Rompe por hallazgos **nuevos** de severidad alta; el stock heredado va a backlog con dueño y fecha, no bloqueando cada PR.
3. **SCA** de dependencias directas y transitivas (el triaje de los CVEs resultantes es de `vulnerability-management-standards`).
4. **DAST** contra un entorno desplegado, en nightly o pre-release: es lento y necesita la aplicación viva; no cabe en cada PR.
5. **Revisión manual de diseño y autorización** para cambios sensibles. Irremplazable, ver abajo.

### Calibrado: qué esperar realmente de las herramientas
Los datos públicos son humillantes y el programa debe diseñarse asumiéndolos: en evaluaciones sobre vulnerabilidades reales las tasas de detección de las herramientas líderes se mueven en el rango del 11-27 % individualmente y en torno al 39 % combinando cuatro, con tasas de falso positivo muy altas en los benchmarks sintéticos. Consecuencias operativas:

- **Ninguna herramienta de patrones detecta authz rota, IDOR/BOLA ni abuso de lógica de negocio.** Esas clases se cubren con diseño (§5) y revisión humana. Si tu programa las delega al SAST, no están cubiertas.
- **Elige por señal/ruido sobre tu propio código**, con una prueba de concepto en tu repo, no por tabla comparativa de features.
- **Un gate ruidoso se desactiva solo**: si el equipo empieza a silenciar hallazgos en masa, el problema es la calibración, no la disciplina. Ajusta reglas antes de subir la severidad de bloqueo.
- Todo silenciado (`nosem`, `# noqa`, supresión en plataforma) lleva **motivo y dueño**; sin justificación escrita no pasa revisión.
- Las **reglas propias** son el activo que diferencia a un programa maduro; las genéricas del proveedor son el punto de partida.

### Tests de seguridad como tests
- Cada **abuse case** relevante se convierte en test automático; los primeros, los de authz negativa por rol y por tenant.
- Todo bug de seguridad corregido deja **test de regresión** — misma regla que cualquier bug (`CLAUDE.md`), sin excepción por ser de seguridad.
- Tests de authz **negativos** sobre la matriz completa: cada rol × cada recurso ajeno debe fallar. Probar solo el camino feliz del rol admin no verifica nada.

## 5. Clases de vulnerabilidad: criterio de control

Orden de referencia, **OWASP Top 10:2025**: A01 Broken Access Control (absorbe SSRF), A02 Security Misconfiguration, A03 Software Supply Chain Failures (nueva), A04 Cryptographic Failures, A05 Injection, A06 Insecure Design, A07 Authentication Failures, A08 Software or Data Integrity Failures, A09 Security Logging and **Alerting** Failures, A10 Mishandling of Exceptional Conditions (nueva).

### Autorización rota (A01) — la clase nº 1, y la que ninguna herramienta ve
- **Deny by default**: la ausencia de regla es denegar. Decisión de autorización **centralizada** en un único punto, invocado por todos los caminos (API, jobs, GraphQL, admin), nunca reimplementada endpoint a endpoint.
- **IDOR / BOLA**: toda referencia a objeto se autoriza **contra el sujeto de la petición y el objeto concreto**, en servidor, en cada acceso. Identificadores no adivinables (UUIDv4/ULID) son defensa en profundidad, **nunca** el control: la ofuscación no es autorización.
- **BFLA** (función o nivel): el menú de la UI no es un control; cada operación privilegiada verifica el rol en servidor. Proteger la ruta `/admin/*` no basta si la operación es alcanzable por otra ruta.
- **Multi-tenant**: el `tenant_id` sale **siempre** del contexto autenticado, jamás de parámetro, cuerpo o cabecera. Aísla en la capa de datos (filtro obligatorio en el repositorio o RLS en la BD), no consulta a consulta.
- **SSRF** (desde 2025 dentro de A01): allowlist de destinos de salida, esquemas no HTTP(S) prohibidos, bloqueo de rangos internos y del endpoint de metadatos de la nube, resolución DNS validada **y revalidada tras cada redirección** (DNS rebinding), salida a través de proxy egress. Nunca validar por regex de la URL.

### Autenticación y sesión (A07)
- MFA; contraseñas con **Argon2id** o bcrypt (nunca MD5/SHA-1/SHA-256 pelado), sin reglas de composición absurdas y contrastadas con listas de contraseñas filtradas.
- **Rotación del identificador de sesión** en cada cambio de privilegio (login, elevación, cambio de contraseña) e invalidación **en servidor** al cerrar sesión o cambiar credenciales: un JWT que no se puede revocar no es una sesión.
- Cookies de sesión: `HttpOnly`, `Secure`, `SameSite=Lax` o `Strict`, prefijo `__Host-`, expiración absoluta además de por inactividad.
- Tokens: verificar `iss`, `aud`, `exp` y algoritmo **contra allowlist explícita** (`alg: none` y confusión HS/RS son los fallos clásicos). Vida corta y refresh rotatorio con detección de reutilización.
- Anti-enumeración: mismas respuestas y tiempos en login, registro y recuperación; rate limiting y bloqueo progresivo por cuenta **y** por origen.

### Inyecciones (A05)
Regla única: **separar código de datos** en cada intérprete. Sanear no es un control; escapar sí, y **depende del contexto de salida**.
- **SQL/NoSQL**: consultas parametrizadas siempre, tampoco concatenación en fragmentos raw del ORM. Los identificadores dinámicos (tabla, columna, `ORDER BY`) van por allowlist, no por parámetro.
- **Command injection**: no invocar shell. API de proceso con array de argumentos, binario por ruta absoluta, entorno controlado. Si hace falta shell, hay un error de diseño.
- **XSS**: escapado **por contexto** (HTML, atributo, JS, URL, CSS) delegado al motor de plantillas con auto-escape; `innerHTML`, `dangerouslySetInnerHTML` o `v-html` solo con HTML saneado por librería mantenida (DOMPurify o equivalente). CSP es defensa en profundidad, no sustituto.
- **SSTI**: nunca construir plantillas con entrada de usuario; la entrada es *dato* que se pasa al render, jamás parte del template. Si el producto acepta plantillas de usuario, motor en sandbox — y auditado, porque los sandboxes de plantillas se escapan.
- **LDAP**: escapado de DN y de filtro (son reglas distintas), bind con cuenta de servicio de mínimo privilegio, nunca bind anónimo con entrada de usuario.
- **XXE**: DTD y entidades externas desactivadas en **todos** los parsers XML — incluye SVG, OOXML (XLSX/DOCX), SOAP y SAML. Preferir formatos sin entidades.

### Deserialización e integridad (A08)
- **Prohibida** la deserialización nativa de datos no confiables (`pickle`, `ObjectInputStream`, `BinaryFormatter`, `unserialize`, `yaml.load` inseguro, `Marshal.load`). Usar formatos de datos (JSON con esquema, protobuf) y mapear a tipos explícitos.
- Si es inevitable: allowlist de tipos y firma/MAC verificada **antes** de deserializar. Verificar después no sirve de nada.
- Integridad de artefactos y actualizaciones: firma verificada antes de ejecutar (ver `cicd-standards`).

### Entrada, ficheros y rutas
- **Validación en el borde y por allowlist** (tipo, formato, rango, longitud) sobre datos **ya decodificados y canonicalizados**; validar antes de normalizar es un bypass conocido.
- **Path traversal**: no construir rutas con entrada de usuario. Resolver a ruta canónica y **comprobar que el prefijo sigue dentro del directorio permitido** después de resolver enlaces simbólicos; el nombre de fichero lo genera el servidor.
- **Subida de ficheros**: allowlist de tipos verificada por contenido (nunca por extensión ni `Content-Type`), tamaño máximo, nombre generado, almacenamiento **fuera del webroot** o en object storage sin ejecución, servido desde origen separado con `Content-Disposition: attachment` y `X-Content-Type-Options: nosniff`. Antivirus cuando el fichero se comparte entre usuarios. SVG y HTML son ejecución de script: trátalos como tal.
- **Mass assignment / over-posting**: DTO de entrada explícito por endpoint con **allowlist de campos**; nunca bindear el cuerpo a la entidad de dominio. Campos como `role`, `is_admin`, `price` o `tenant_id` sencillamente no existen en el DTO de entrada.
- **TOCTOU**: no separar comprobación y uso. En ficheros, operar sobre descriptores ya abiertos (`openat`, `O_NOFOLLOW`) y directorios privados, no sobre rutas re-resueltas. En negocio (saldo, stock, cupones), comprobación y mutación en **una transacción con bloqueo** o mediante operación atómica condicional; la clave de idempotencia evita el doble gasto por reintento.

### Navegador: CSRF, CORS y cabeceras (A02)
- **CSRF**: cookies con `SameSite` más token anti-CSRF sincronizado en toda operación con efecto si la sesión viaja en cookie. Autenticación por cabecera `Authorization` no es vulnerable a CSRF clásico, pero entonces el token no puede vivir en `localStorage` sin asumir el riesgo de XSS.
- **CORS**: allowlist de orígenes **explícita**; `Access-Control-Allow-Origin` jamás reflejado desde `Origin` sin validar y **nunca** `*` junto a `Allow-Credentials: true`. CORS relaja la política del navegador: no es un control de autorización.
- **CSP** estricta basada en **nonce o hash** (`script-src 'nonce-…' 'strict-dynamic'`), con `object-src 'none'`, `base-uri 'none'` y `frame-ancestors 'none'`. Prohibidos `unsafe-inline`, `unsafe-eval` y las allowlists de CDN por dominio (son bypasseables). Desplegar primero en `Report-Only` con endpoint de informes.
- Resto: `Strict-Transport-Security` con `preload`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` restrictiva.

### Condiciones excepcionales (A10, nueva en 2025)
- **Fail closed**: ante error, excepción o timeout del proveedor de authn/authz, la decisión por defecto es **denegar**. Fallar abierto (CWE-636) es la esencia de esta categoría.
- Manejador global de excepciones: al cliente, error genérico con identificador de correlación; al log, el detalle. Nunca stack traces, rutas internas ni errores de base de datos al usuario (CWE-209).
- **Límites en todo**: rate limiting, cuotas, tamaño máximo de petición y respuesta, profundidad y coste de consulta en GraphQL, timeouts en toda llamada saliente. Lo ilimitado acaba en DoS, fuerza bruta o factura de nube.

### Criptografía y datos (A04)
Cripto moderna según `CLAUDE.md` (AES-GCM, ChaCha20-Poly1305, Argon2/bcrypt, TLS 1.2+). Añadidos de AppSec: jamás implementar primitivas propias, comparación de secretos en **tiempo constante**, aleatoriedad de un CSPRNG (nunca `random()` para tokens), claves fuera del código con rotación, y clasificar el dato antes de elegir el control.

### Cadena de suministro (A03, nueva en 2025)
Categoría propia desde 2025. El criterio operativo vive en `cicd-standards` y `vulnerability-management-standards`; desde AppSec lo relevante es que **una dependencia es código tuyo en producción** y entra en el modelo de amenazas como cualquier componente propio.

## 6. Operabilidad del programa

- **A09 — logging *y alerting***: la categoría se renombró en 2025 precisamente porque loguear sin alertar no detecta nada. Eventos mínimos, estructurados y correlacionados: authn fallida y exitosa, **authz denegada**, cambio de privilegios, cambio de credenciales, acceso a datos sensibles, uso de funciones administrativas. Cada uno con actor, recurso, resultado, origen y `trace_id`.
- **Prohibido loguear** contraseñas, tokens, cookies de sesión, PII/PHI innecesaria o datos de tarjeta. El log es un almacén de datos con su clasificación y su retención — y **codifica la salida al log**: la inyección en logs es un vector real contra el SIEM.
- Alertas accionables sobre patrones de abuso (picos de authz denegada por usuario, enumeración, fuerza bruta distribuida) con runbook. Logs íntegros y retenidos para *forensics readiness*.
- **Métricas del programa** (para mejorar, no para vigilar): densidad de hallazgos por severidad, tiempo de remediación por severidad, *escape rate* (lo que llega a producción frente a lo detectado antes), cobertura de modelado de amenazas sobre cambios sensibles y ratio de falsos positivos por regla. La cobertura de escaneo es señal, no meta.
- **Security champions**: uno por equipo, **voluntario**, con tiempo asignado y formación. Funciones típicas: facilitar el modelado de amenazas, primera revisión de seguridad del diseño y del código, y triaje de los hallazgos de su equipo. No sustituyen al equipo de seguridad, escalan su alcance.
- **El escáner es superficie de ataque**: el compromiso de la cadena de suministro de Trivy en marzo de 2026 (tag poisoning de `trivy-action` y `setup-trivy`, binarios e imágenes maliciosos) recuerda que estas herramientas corren en CI con acceso a secretos por diseño. Fija las actions por **SHA de commit inmutable**, las imágenes por **digest**, verifica checksums y firmas, y asume que las credenciales de CI deben poder rotarse en cualquier momento.

## 7. Sostenibilidad

- **Revisión del modelo de amenazas** en cada cambio de límite de confianza y, como mínimo, anual en sistemas críticos. Un modelo desactualizado es peor que ninguno: da falsa confianza.
- **Reglas de SAST versionadas en el repo** y revisadas en PR como código, con su propio changelog.
- **Migración de mapeos al Top 10:2025** como tarea planificada: reglas, informes y evidencias de auditoría que aún traten SSRF como categoría propia (A10:2021) o citen "Logging and Monitoring" están obsoletos.
- Cadencia: revisar esta skill y el tooling cada 6 meses. ASVS y el Top 10 se mueven en ciclos de años; las herramientas, en meses.
- Deuda de seguridad **registrada con dueño y fecha de revisión**, nunca silenciada: excepción explícita > supresión anónima.

### Lista de prohibiciones
- ❌ Confiar la detección de authz rota, IDOR/BOLA o lógica de negocio a herramientas automáticas.
- ❌ Autorización basada en lo que muestra la UI, en identificadores no adivinables o en la ruta del endpoint.
- ❌ `tenant_id`, `user_id`, `role` o `price` tomados de parámetro, cuerpo o cabecera del cliente.
- ❌ Concatenar entrada en SQL, comandos, plantillas, filtros LDAP o rutas de fichero.
- ❌ Sanear como sustituto de parametrizar o de escapar por contexto de salida.
- ❌ Deserialización nativa de datos no confiables, o verificar la firma **después** de deserializar.
- ❌ Parsers XML con DTD o entidades externas habilitadas.
- ❌ `Access-Control-Allow-Origin` reflejado sin validar, o `*` junto a credenciales.
- ❌ CSP con `unsafe-inline`, `unsafe-eval` o allowlist de dominios de CDN.
- ❌ Ficheros subidos servidos desde el mismo origen, con nombre del cliente o desde el webroot.
- ❌ Bindear el cuerpo de la petición directamente a la entidad de dominio (mass assignment).
- ❌ Fail open ante error o timeout del proveedor de authn/authz.
- ❌ Devolver stack traces, rutas internas o errores de base de datos al cliente.
- ❌ Secretos, tokens o PII en logs; salida al log sin codificar.
- ❌ Endpoint sin rate limiting, sin límite de tamaño ni timeout.
- ❌ Criptografía propia, comparación de secretos no constante o `random()` para tokens.
- ❌ Silenciar un hallazgo sin motivo escrito y dueño.
- ❌ Bloquear el merge por el stock heredado de hallazgos en vez de por los nuevos del diff.
- ❌ Historia de usuario "de seguridad" sin criterio de aceptación verificable y testeable.
- ❌ Citar requisitos ASVS sin prefijo de versión: la numeración no es estable entre versiones.
- ❌ Actions o imágenes de herramientas de seguridad referenciadas por tag mutable.

## 8. Verificación web obligatoria

Antes de fijar en un entregable cualquier versión, categoría o recomendación de este documento, **verifica con WebSearch** (los datos son de agosto 2026 y caducan):

1. **OWASP Top 10**: ¿sigue vigente la edición **2025** o hay ya posterior? Nombres exactos de A01-A10 y CWEs mapeados en `owasp.org/Top10/`.
2. **ASVS**: ¿sigue 5.0.0 (mayo 2025) o salió ya 5.0.1 / 5.1? Estructura de capítulos y niveles en el repo `OWASP/ASVS`.
3. **API Security Top 10**: comprobar si sigue siendo la edición 2023 en `owasp.org/API-Security`.
4. **Proactive Controls**: ¿sigue v4 (2024) en `top10proactive.owasp.org`?
5. **Tooling**: estado, licencia, gobernanza e **incidentes de seguridad recientes** de la herramienta que vayas a recomendar (ZAP ya no es proyecto OWASP; Trivy sufrió un compromiso de cadena de suministro en marzo de 2026). Consulta los advisories del propio proveedor antes de meterla en CI.
6. **Cabeceras y CSP**: directivas vigentes y soporte real (MDN) antes de fijar una política; las recomendaciones cambian con los navegadores.
7. Si el proyecto toca IA/LLM, comprobar el estado del **OWASP Top 10 for LLM Applications / Agentic AI**: es un proyecto distinto, con su propio ciclo, y no está cubierto aquí.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
