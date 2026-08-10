---
name: cloud-security-posture-standards
description: Cloud security posture as a transversal discipline across AWS, Azure and Google Cloud at once — what the per-provider skills cannot answer. Use when deciding what CSPM, CWPP, CIEM and CNAPP actually mean and which problem each one solves, choosing between open tooling (Prowler, ScoutSuite, CloudSploit, Steampipe and Powerpipe mods, Cartography, Cloud Custodian, Checkov, Conftest) and a commercial posture suite, running a CIS Foundations Benchmark assessment across several accounts, subscriptions or projects at once, building a multi-account or multi-tenant baseline and landing-zone guardrails, preferring preventive policy-as-code in the pipeline and in admission over after-the-fact findings, measuring effective permissions versus granted permissions and hunting wildcard or unused entitlements that no vulnerability scanner will ever report, replacing a flat list of findings with attack-path or toxic-combination analysis, inventorying internet-exposed resources, reconciling declared infrastructure against what actually exists (posture drift), replacing static long-lived cloud access keys with workload identity and OIDC federation, scoping the posture tool's own reader role so it cannot read every secret in the estate, or writing the buy-versus-build criterion for posture tooling.
---

# Estándares de postura de seguridad en la nube (CSPM/CNAPP)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **la seguridad de la nube vista desde arriba y a la vez en los tres proveedores**: qué
significa cada sigla del mercado y qué problema resuelve, cómo se establece y se mide una línea
base sobre decenas de cuentas/suscripciones/proyectos, cómo se pone la barrera **antes** (política
como código en el pipeline y en la admisión) en vez de contar hallazgos después, cómo se mide el
**permiso efectivo** frente al concedido, cómo se pasa de una lista de hallazgos a **caminos de
ataque**, cómo se inventaría lo expuesto a Internet, cómo se detecta la deriva entre lo declarado
en IaC y lo real, y con qué criterio se compra o se construye la herramienta.

Triggers: "CSPM", "CWPP", "CIEM", "CNAPP", "KSPM", "DSPM", "postura de seguridad en la nube",
"benchmark CIS de la nube", `prowler`, `prowler aws|azure|gcp|kubernetes`, `scout aws`,
`cloudsploit`, `steampipe query`, `powerpipe benchmark run`, `cartography`, `custodian run`,
`checkov -d`, `conftest test`, "landing zone", "guardrail", "baseline multi-cuenta",
"permisos efectivos", "permisos sin usar", "rol con comodín", `"Action": "*"`, "Owner en la
suscripción", `roles/owner`, "camino de ataque", "combinación tóxica", "recurso expuesto a
Internet", "bucket público", "deriva de configuración", "clave estática de acceso", "federación
OIDC del pipeline", "¿qué CNAPP compramos?".

**Principio rector**: **en la nube el fallo dominante no es el exploit, es la configuración y el
permiso.** El plano de control es una API pública autenticada; quien tiene la credencial o el rol
adecuado no necesita explotar nada. Corolarios que ordenan el documento:

1. **Un rol con `*:*` no es una vulnerabilidad para ningún escáner** — no tiene CVE, no tiene CVSS
   y no aparece en `vulnerability-management`. Es el hallazgo real y hay que buscarlo con otra
   herramienta y otro modelo de datos (§3.3).
2. **Prevenir es más barato que detectar.** Un `deny` en la admisión cuesta una política; el mismo
   fallo detectado en producción cuesta un ticket, una ventana de cambio, un dueño que discute y
   una excepción que sobrevive tres años (§3.2).
3. **Una lista de 12.000 hallazgos no es postura, es un vertedero.** Lo que decide es el camino:
   qué expuesto llega a qué identidad y de ahí a qué dato (§3.4).
4. **El agente que audita es un usuario privilegiado más** (§5). Un rol "de solo lectura" que puede
   leer todos los secretos es un rol de administrador con otro nombre.

**Postura defensiva y autorizada.** Todo lo de aquí se ejecuta sobre entornos propios o con
autorización escrita. Este documento no contiene explotación: describe **clase de riesgo,
evidencia y control**.

**No aplica**: ver `aws-standards`, `azure-standards` y `gcp-standards` (**el servicio concreto y
su configuración segura son suyos, sin excepción**: qué servicio elegir, qué flag activar, qué
producto de hallazgos gestionado usar y qué cuesta. **Aquí lo transversal**: el criterio que no
cambia al cambiar de proveedor —qué sigla resuelve qué, cómo se mide el permiso efectivo, cómo se
prioriza por camino de ataque, qué baseline se exige en las tres— y el problema **multi-nube**,
que ninguna de las tres puede resolver desde dentro. Regla de arbitraje: *si la respuesta cambia
al cambiar de proveedor, es suya; si es la misma en los tres, es de aquí*), `iac-standards` (**el
código que crea el recurso**: módulos, state, backend, y el escáner de IaC como herramienta —
aquí, la deriva entre ese código y la realidad, y por qué la política tiene que existir también
fuera del pipeline), `kubernetes-standards` (**el clúster y su admisión**: Kyverno/Gatekeeper, Pod
Security Standards, manifiestos; el KSPM que venden dentro de un CNAPP es su terreno),
`container-runtime-security-standards` (**el contenedor ya corriendo**: seccomp, escape, Falco —
el "CWPP en runtime" de las suites es suyo), `detection-engineering-standards` (**la regla de
detección sobre el log del plano de control es suya, sin excepción**; aquí solo qué configuración
y qué permiso importan y por qué), `soc-operations-standards` (turno, cola y triaje de lo que
genere la herramienta), `incident-response-forensics-standards` (el compromiso ya confirmado en
la nube y su adquisición), `identity-access-management-standards` (**el diseño de la identidad**:
IdP, SSO, MFA, ciclo joiner-mover-leaver, motores de autorización, SPIFFE; aquí solo la **medición
del derecho efectivo** sobre recursos de nube y la sustitución de la clave estática por
federación), `identity-threat-detection-standards` (**hermana**: el **ataque** contra esa
identidad, su detección y su respuesta — aquí el permiso mal puesto en frío, allí el token robado
en caliente), `vulnerability-management-standards` (**CVE, CVSS/EPSS/KEV y SLA de remediación**:
la carga de trabajo vulnerable se triaja allí; aquí por qué el permiso excesivo nunca entra en ese
embudo), `appsec-standards` (el fallo en el código de la aplicación), `secrets-management-standards`
(custodia y rotación del secreto; aquí solo quién puede leerlo), `cicd-standards` (el pipeline y su
OIDC), `grc-compliance-standards` (**el marco, el SoA y la evidencia de auditoría son suyos**: aquí
el benchmark como control técnico medible, no como informe de cumplimiento),
`finops-standards` (coste de la herramienta y de la ingesta), `privacy-engineering-standards`
(el dato personal dentro del bucket que se declara expuesto), `platform-engineering-standards`
(el camino pavimentado que hace que el guardrail no duela), `datacenter-facilities-standards`
(el mundo físico, que aquí no existe).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

**Licencias leídas verbatim del `LICENSE` del repositorio (agosto 2026)** — no de la web ni de
memoria. Este punto ha producido errores caros en el catálogo:

| Herramienta | Rol | Última vista (ago-2026) | Licencia (verbatim del `LICENSE`) |
|---|---|---|---|
| **Prowler** (`prowler-cloud/prowler`) | Evaluación de benchmarks multi-nube y multi-cuenta | `5.37.1` | **Apache-2.0** |
| **ScoutSuite** (`nccgroup/ScoutSuite`) | Informe de postura por proveedor, salida HTML | `5.14.0` (2024-05-10) | **GPL-2.0** ⚠️ copyleft |
| **CloudSploit** (`aquasecurity/cloudsploit`) | Checks de configuración | ver §8 | **GPL-3.0** ⚠️ copyleft |
| **Steampipe** (`turbot/steampipe`) | Nube como SQL: inventario y consulta ad hoc | `v2.4.4` | **AGPL-3.0** ⚠️ copyleft de red |
| **Powerpipe** (`turbot/powerpipe`) | Benchmarks y dashboards sobre Steampipe | `v1.5.2` | **AGPL-3.0** ⚠️ copyleft de red |
| **Cartography** (`cartography-cncf/cartography`) | Grafo de activos y relaciones en Neo4j | `0.139.1` | **Apache-2.0** |
| **Cloud Custodian** (`cloud-custodian`) | Política + **remediación** como código | ver §8 | **Apache-2.0** |
| **Checkov** (`bridgecrewio/checkov`) | Política sobre IaC antes del `apply` | `3.3.9` | **Apache-2.0** |
| **OPA / Conftest** | Política genérica y gate en CI | ver §8 | **Apache-2.0** |

Notas que cambian decisiones, no adorno:
- **AGPL-3.0 en Steampipe y Powerpipe**: si se ofrece un dashboard de postura **como servicio** a
  terceros, la AGPL activa su cláusula de red. Uso interno no la activa. Decidir con
  `opensource-licensing-standards`, no aquí, pero **no asumir "es open source, da igual"**.
- **GPL-2.0 en ScoutSuite y GPL-3.0 en CloudSploit**: incompatibles con integrarlos dentro de un
  producto propietario. Ejecutarlos como herramienta externa y consumir su salida no es derivar.
- **ScoutSuite lleva sin release desde 2024-05-10** (verificado en la API de releases). No es
  descalificante para un uso puntual, pero **una cobertura de servicios congelada en 2024 miente
  por omisión** sobre todo lo que el proveedor ha publicado después. Verificar actividad del
  repositorio antes de apoyarse en él (§8).

Decisiones por defecto:

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Primer paso en un entorno desconocido | **Prowler** contra las tres nubes con el perfil CIS, en modo lectura | ScoutSuite si se quiere informe navegable de un solo proveedor |
| Inventario y preguntas cruzadas | **Steampipe/Powerpipe** (SQL) o **Cartography** (grafo) | El inventario nativo del proveedor si no hay multi-nube |
| Camino de ataque | **Cartography** + consultas Cypher propias | Suite comercial si el grafo tiene que cubrir identidad + vulnerabilidad + dato |
| Prevención | **Checkov/Conftest en el pipeline** + política nativa del proveedor en el plano de control | Solo pipeline, únicamente si el `apply` es el **único** camino a producción — y casi nunca lo es |
| Remediación automática | **Cloud Custodian** en modo `--dryrun` primero, y solo para clases acotadas | Ninguna: notificar al dueño (por defecto para todo lo que pueda cortar un servicio) |
| Autenticación de la herramienta | **Rol asumible / workload identity con federación OIDC** | Nunca clave estática de larga vida (§5) |

**Criterio de compra (build vs. buy), en una línea por eje**: la herramienta abierta te da
**checks**; la suite comercial te vende **correlación**. Si tu problema es "no sé qué tengo", lo
abierto sobra. Si tu problema es "tengo 40.000 hallazgos y no sé cuál mata", lo que compras es
priorización por camino de ataque, y **eso es exactamente lo que hay que probar en la PoC con tus
datos**, no en la demo del fabricante. Preguntas eliminatorias a un CNAPP: ¿calcula **permiso
efectivo** o solo lista políticas? ¿Sabe si el recurso es **realmente alcanzable** desde Internet o
solo si el grupo de seguridad es `0.0.0.0/0`? ¿Qué permisos exige su rol y **puede leer secretos**
(§5)? ¿Exporta los hallazgos a tu SIEM en un formato que no sea suyo?

**Sobre la taxonomía**: CSPM, CWPP, CIEM, CNAPP, KSPM, DSPM y CDR son **categorías de analista**,
acuñadas por Gartner y adoptadas por el marketing. Describen mercados, no arquitecturas. Su
utilidad es acotar la conversación de compra; su daño es hacer creer que hacen falta siete
productos. Traducción honesta, sin sigla:
- **CSPM** = ¿está bien configurado el plano de control?
- **CWPP** = ¿está sana la carga que corre encima (VM, contenedor, función)?
- **CIEM** = ¿quién puede hacer qué, de verdad?
- **CNAPP** = las anteriores en un producto, con **un grafo** que las correlaciona — y ese grafo es
  lo único que justifica el paquete frente a comprarlas sueltas.

## 3. Estructura y convenciones

### 3.1 Línea base multi-cuenta y landing zone

La unidad de aislamiento es **la cuenta / suscripción / proyecto**, y la línea base se aplica **en
la jerarquía**, no recurso a recurso. Invariantes, iguales en las tres nubes (el mecanismo concreto
lo pone la skill del proveedor):

- **Jerarquía organizativa antes que cualquier control**: sin unidad organizativa / grupo de
  administración / carpeta no hay dónde colgar la política, y se acaba copiándola N veces.
- **Barrera preventiva heredada** en la raíz (SCP / Azure Policy `Deny` / política de organización),
  que **ningún administrador de la cuenta hija puede desactivar**. Ese es el punto: una guardrail
  que el dueño del recurso puede quitar no es una guardrail.
- **Registro de auditoría centralizado, en cuenta distinta, con escritura pero no borrado** desde
  las cuentas productoras. Si el atacante que compromete la cuenta puede borrar su rastro, no hay
  investigación posible (frontera con `incident-response-forensics-standards`).
- **Cuenta nueva = línea base aplicada el día 0**, por vending automatizado. Una cuenta creada a
  mano es un agujero permanente porque nunca aparece en el alcance del escaneo.
- **El escaneo cubre el 100 % de las cuentas o no significa nada.** La métrica que importa no es
  "hallazgos resueltos", es **cobertura**: cuántas cuentas/suscripciones/proyectos existen y en
  cuántas se ejecuta la evaluación. Lo demás se mide sobre un denominador falso.

Benchmarks: **CIS Foundations Benchmark** por proveedor como línea base mínima y auditable. Las
versiones se mueven cada año y **no son comparables entre sí** (un control renumerado no es un
control nuevo). Verificado en agosto de 2026: **CIS Microsoft Azure Foundations Benchmark v6.0.0**
y **CIS Google Cloud Platform Foundation Benchmark v5.0.0** figuran como vigentes en el NCP del
NIST; **la versión vigente del de AWS no se pudo confirmar contra fuente primaria** — verificar en
`cisecurity.org` antes de citarla (§8). Aviso operativo: **el benchmark es piso, no techo**. Cumplir
CIS al 100 % y tener un rol con `*:*` es perfectamente posible.

### 3.2 Guardrail preventivo frente a hallazgo posterior

Tres capas, en orden de coste creciente por fallo detectado:

1. **Código (IaC)**: `checkov`/`conftest` en el PR. Coste del fallo: un comentario.
2. **Admisión / plano de control**: política nativa del proveedor que **rechaza** la creación, y
   admisión en el clúster (esa parte es de `kubernetes-standards`). Coste: un error en el `apply`.
3. **Postura (detección)**: el escaneo periódico que encuentra lo que se coló. Coste: ticket,
   dueño, ventana, discusión y excepción.

**La capa 3 no sustituye a la 1 y la 2, y la 1 no sustituye a la 2**: hay más caminos a producción
que el pipeline (consola, CLI, un operador, un servicio que crea recursos por su cuenta). Una
política que solo vive en el repositorio de IaC protege exactamente al equipo que ya hacía las
cosas bien. Regla: **toda regla de postura que se repite debería convertirse en una barrera
preventiva o desaparecer**; si un hallazgo aparece 200 veces al mes, el problema no es el hallazgo,
es que no hay `deny`.

Contrapartida honesta: la barrera preventiva rompe cosas y genera excepciones. Por eso se despliega
en **modo auditoría primero**, con métrica de cuántas veces habría bloqueado y a quién, y se
promueve a `deny` con esa evidencia. Una excepción **lleva dueño y caducidad**; sin caducidad es una
derogación.

### 3.3 El permiso excesivo: derecho efectivo frente a derecho concedido

Este es el hallazgo que nadie reporta y el que decide el alcance de un compromiso.

- **Derecho concedido** = lo que dicen las políticas adjuntas. **Derecho efectivo** = lo que la
  identidad puede hacer de verdad, tras resolver **herencia de la jerarquía, políticas de límite,
  denegaciones explícitas, condiciones, políticas basadas en recurso, cadenas de asunción de rol y
  suplantación de cuenta de servicio**. Casi nunca coinciden, y la diferencia va en los dos
  sentidos: hay roles que parecen amplios y están acotados por una condición, y roles que parecen
  acotados y pueden escalar a administrador **encadenando un permiso de `iam:PassRole`,
  suplantación o edición de la propia política**.
- **El permiso de escalada es el que hay que buscar primero**: quien puede modificar políticas,
  crear credenciales de otra identidad, adjuntarse un rol o desplegar código en un contexto
  privilegiado **ya es administrador**, diga lo que diga su nombre.
- **El comodín es el síntoma barato**: `*:*`, `Owner` sobre la suscripción, `roles/owner`,
  `roles/editor` a nivel de proyecto. Búsqueda obligatoria y de resultado inmediato, pero
  insuficiente.
- **Permiso concedido y no usado**: casi todas las nubes exponen la última vez que se usó un
  servicio o permiso por identidad. **Es la única fuente objetiva para reducir sin romper**: se
  recorta a lo usado en una ventana representativa (cuidado con lo trimestral y lo anual: cierres,
  auditorías y DR usan permisos once al año).
- **Camino de reducción sin drama**: registrar → proponer política mínima derivada del uso →
  aplicar **en modo auditoría** → medir denegaciones que habrían ocurrido → aplicar. Recortar a
  ciegas es la forma más rápida de que el equipo de seguridad pierda el permiso de tocar IAM.
- **Identidades no humanas > humanas** en número, en permisos y en olvido. La cuenta de servicio de
  un proyecto muerto sigue teniendo `editor`. El inventario de identidades **no humanas** con su
  dueño es un entregable, no una nota.

### 3.4 Camino de ataque frente a lista de hallazgos

Lo que hace útil o inútil a una herramienta de postura: **si te da hallazgos independientes, el
trabajo de correlación te lo quedas tú**. Lo que importa es la combinación:

> Máquina alcanzable desde Internet → con una vulnerabilidad explotable → cuyo rol de instancia
> puede leer un almacén con dato regulado → y además puede asumir un rol en otra cuenta.

Ninguno de esos cuatro hechos es crítico por separado; juntos son el incidente. Consecuencias
prácticas:
- **La severidad de un hallazgo aislado es casi siempre falsa** (alta o baja). El contexto la fija:
  exposición real, sensibilidad del dato alcanzable y privilegio de la identidad implicada.
- **"Expuesto a Internet" hay que calcularlo, no declararlo**: grupo de seguridad abierto + IP
  pública + ruta + lista de control de acceso de red + política del recurso + balanceador delante.
  Un bucket "público" detrás de una política que deniega todo no lo está; una máquina "privada"
  detrás de un balanceador público sí.
- **Sin inventario no hay camino**: el grafo (Cartography o equivalente) es prerrequisito. La
  frontera con `cmdb-inventory-standards` es que allí vive el registro del activo y aquí las
  relaciones de seguridad entre ellos.
- Métrica útil: **número de caminos desde Internet hasta un dato clasificado**, y su evolución. Es
  un número pequeño, entendible por dirección y que baja al arreglar cosas de verdad.

### 3.5 Deriva entre lo declarado y lo real

- La postura se evalúa **contra el entorno vivo**, no contra el repositorio. El escaneo de IaC dice
  lo que se pretendía; la nube dice lo que hay.
- **Toda diferencia es una señal**, y hay tres causas: cambio manual (arreglar y prevenir), recurso
  creado fuera de IaC (adoptar o borrar), o el propio proveedor cambiando defaults (leer las notas).
- **Recurso sin dueño identificable = incidente de gobierno**, no un hallazgo menor: no se puede
  arreglar lo que no tiene a quién pedírselo. Etiqueta de dueño obligatoria y **verificada en la
  admisión**, no en una hoja de cálculo (la política de etiquetas la fija `finops-standards`; aquí
  solo la exigencia de que exista).

## 4. Calidad y testing

- **La política es código y se prueba como código**: cada regla de `conftest`/`checkov` custom lleva
  un caso que **debe** fallar y otro que **debe** pasar. Una política sin test negativo no está
  probada: pasa siempre.
- **Gates de CI, en orden de coste creciente**: (1) lint y test unitario de las políticas;
  (2) `checkov`/`conftest` sobre el plan/plantilla, rompiendo el build en severidad alta;
  (3) evaluación de postura sobre entorno efímero o cuenta de pruebas; (4) escaneo completo
  programado del estate, que no rompe build sino que abre trabajo.
- **Validar la barrera, no solo escribirla**: desplegar un recurso deliberadamente no conforme en un
  entorno de pruebas y comprobar que el `deny` dispara. Una política mal ámbito-limitada que no
  aplica a nada es indistinguible de una que funciona, salvo por este test.
- **Falsos negativos antes que falsos positivos**: la pregunta a la herramienta no es "¿cuántos
  hallazgos da?" sino "¿qué NO ve?". Servicios sin cobertura, regiones no escaneadas, cuentas
  ausentes y tipos de recurso desconocidos son huecos silenciosos. Exigir el **inventario de
  cobertura** por servicio y región.
- **Regresión de excepciones**: cada excepción con caducidad tiene un test que la reabre al vencer.
- **Nada de gate sobre la nota agregada**: "puntuación de postura 87 %" es una métrica de vendedor.
  Sube limpiando cuentas vacías. Se mide por cobertura, por número de caminos de ataque y por
  tiempo hasta corregir lo alcanzable desde Internet.

## 5. Seguridad del stack

**La herramienta de postura es el activo más privilegiado que vas a desplegar.** Lee todo el
estate, en todas las cuentas, de forma continua. Tratarla como una utilidad más es el error
recurrente.

- **"Solo lectura" no significa inofensivo.** Los roles de lectura amplios que ofrecen los
  proveedores **incluyen leer el contenido de secretos, de parámetros y de configuración
  sensible** en varios servicios. Un rol de auditoría que puede leer el gestor de secretos es un
  rol de administrador diferido: quien comprometa el escáner tiene las credenciales de todo lo
  demás. **Verificar permiso a permiso qué implica el rol de lectura que pide el fabricante, y
  denegar explícitamente la lectura de material secreto** salvo justificación concreta.
- **Federación OIDC, nunca clave estática.** El SaaS de postura que pide un par de claves de larga
  vida está pidiendo la llave maestra sin caducidad. Rol asumible con condición sobre el
  identificador externo del tenant (o su equivalente), y **verificar que ese identificador es único
  por cliente**: si es adivinable, cualquier otro cliente del mismo SaaS puede asumir tu rol —
  problema del *confused deputy*, real y documentado en este tipo de integración.
- **Modelo de despliegue**: agente en tu cuenta > SaaS que asume rol en tu cuenta > SaaS con copia
  de tu inventario. Cada salto hacia la derecha añade un tercero que guarda el mapa completo de tu
  superficie de ataque. Si se elige SaaS, esa decisión es de riesgo de terceros y va a
  `grc-compliance-standards` con nombre y apellidos.
- **Sin permisos de escritura por defecto.** La remediación automática exige permisos de cambio, y
  con ellos el escáner pasa a poder **borrar** producción. Si se activa: alcance mínimo, clases de
  acción explícitas en lista blanca, `dry-run` obligatorio antes, registro de cada acción y
  posibilidad de deshacer.
- **Los hallazgos son inteligencia sobre tu propia debilidad**: el informe de postura describe
  exactamente dónde atacar. Se trata con el mismo control de acceso que el resultado de un pentest.
- **La deriva del propio permiso del escáner** se vigila: si alguien amplía el rol de auditoría,
  eso es una alerta, no un cambio administrativo.
- **Credenciales estáticas de larga vida en general**: son el hallazgo con mejor relación
  esfuerzo/valor de todo el catálogo. Inventariar, medir antigüedad y último uso, sustituir por
  identidad de carga de trabajo y **prohibirlas por política preventiva**, no por recordatorio.

## 6. Rendimiento y operabilidad

- **Límites de API del proveedor**: un escaneo completo de un estate grande consume cuota del plano
  de control y puede degradar el resto. Escalonar por cuenta y región, respetar el *backoff* y
  medir. Un escaneo que provoca `429` a la aplicación es un incidente causado por seguridad.
- **Cadencia por clase, no una sola**: cambios de identidad y de exposición a Internet, en continuo
  (por eventos del plano de control); benchmark completo, diario o semanal; grafo de caminos, con la
  cadencia que soporte el coste.
- **Coste**: la ingesta de eventos del plano de control y el almacenamiento del inventario son la
  factura real de un CSPM, no la licencia. Se dimensiona antes (`finops-standards`).
- **Ruido**: un producto que entrega miles de hallazgos el primer día no ha encontrado miles de
  problemas; ha encontrado un entorno sin línea base. Se establece una **línea de corte inicial**
  (todo lo anterior a la fecha X entra como deuda con plan) y a partir de ahí se trabaja el flujo
  nuevo. Sin ese corte, el equipo se rinde en dos semanas.
- **Dueño por hallazgo o no hay proceso**: enrutado automático por etiqueta de dueño/cuenta al
  equipo responsable. Un panel central que nadie mira es el estado final por defecto.
- **Salida abierta**: exigir exportación (SARIF, OCSF, JSON documentado) para no depender del panel
  del fabricante y poder correlacionar en el SIEM.

## 7. Sostenibilidad a largo plazo

- Las nubes publican servicios y cambian *defaults* continuamente: **la cobertura de la herramienta
  caduca sola**. Revisión trimestral de qué servicios nuevos hay en uso y si están cubiertos.
- Versión del benchmark **fijada explícitamente** en la configuración y actualizada como cambio
  consciente, con nota de qué controles se han añadido o renumerado. Saltar de versión sin leer el
  diff produce un pico de hallazgos que parece una regresión y no lo es.
- Las excepciones se revisan en cada ciclo; **caducadas se reabren solas**.

**PROHIBIDO**:
- ❌ Duplicar aquí el criterio de `aws`/`azure`/`gcp` sobre cómo se configura un servicio concreto.
- ❌ Dar por buena una licencia de herramienta **sin leer el `LICENSE` del repositorio**. Las
  suposiciones falsas ya han costado dieciséis correcciones en este catálogo.
- ❌ Claves de acceso estáticas de larga vida para humanos, para pipelines o para el propio escáner.
- ❌ Conceder al escáner permisos de escritura "por si acaso", o aceptar sin revisar el rol de
  lectura que pide el fabricante.
- ❌ Presentar una **puntuación de postura** como métrica de dirección, o "0 hallazgos críticos"
  sobre un alcance que no cubre todas las cuentas.
- ❌ Tratar el permiso excesivo como un hallazgo de gestión de vulnerabilidades: **no tiene CVE y no
  entra en ese embudo**; si se mete allí, se pierde.
- ❌ Remediación automática sobre clases no acotadas, sin `dry-run` previo y sin registro.
- ❌ Excepciones sin dueño y sin fecha de caducidad.
- ❌ Citar **"el 99 % de los fallos de seguridad en la nube serán culpa del cliente"** como si fuera
  una medición. Es una **predicción** de Gartner (descendiente directa de otra anterior de "al menos
  el 95 % hasta 2022"), con horizonte 2025, repetida por cientos de fuentes que la han convertido en
  hecho consumado, le han cambiado la fecha y han sustituido "responsabilidad del cliente bajo el
  modelo de responsabilidad compartida" por "error del usuario". **La tesis de fondo —el fallo
  dominante está en la configuración y el permiso, no en el hipervisor del proveedor— se sostiene sin
  necesidad de ese número.** Si hay que citar una cifra, que venga con metodología; si no la tiene,
  se dice el argumento y se omite el porcentaje.
- ❌ Comprar un CNAPP sin PoC con datos propios sobre las dos preguntas que deciden: permiso
  efectivo y alcanzabilidad real desde Internet.
- ❌ Ejecutar cualquier evaluación sobre entornos de terceros sin autorización escrita.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:
1. **Versión vigente de cada CIS Foundations Benchmark** (AWS, Azure, GCP) en `cisecurity.org`.
   **Hueco declarado**: en agosto de 2026 se confirmaron por fuente secundaria (NCP del NIST)
   Azure v6.0.0 y GCP v5.0.0; **la versión vigente del de AWS no se pudo verificar contra fuente
   primaria y no se escribe aquí**.
2. **Última versión y actividad** de Prowler, ScoutSuite, CloudSploit, Steampipe, Powerpipe,
   Cartography, Cloud Custodian y Checkov. Vistas en agosto de 2026 vía la API de releases:
   Prowler `5.37.1`, ScoutSuite `5.14.0` (2024-05-10, **sin release desde entonces**), Checkov
   `3.3.9`, Cartography `0.139.1`, Steampipe `v2.4.4`, Powerpipe `v1.5.2`.
3. **Licencia, releyendo el `LICENSE` del repositorio** — no la web ni la ficha de un agregador.
   Verificadas verbatim en agosto de 2026: Prowler Apache-2.0, ScoutSuite GPL-2.0, CloudSploit
   GPL-3.0, Steampipe AGPL-3.0, Powerpipe AGPL-3.0, Cartography Apache-2.0, Cloud Custodian
   Apache-2.0, Checkov Apache-2.0, OPA/Conftest Apache-2.0. **Comprobar además si el proyecto ha
   relicenciado o ha separado componentes de pago desde entonces.**
4. **Cambios de *default* del proveedor** que invaliden un control (bloqueo de acceso público,
   cifrado por defecto, versiones mínimas de TLS): la skill de la nube manda.
5. **Permisos exactos del rol de auditoría** que pide cada herramienta, y si el rol de lectura del
   proveedor incluye leer secretos. Cambia entre versiones.
6. **Cualquier cifra** antes de citarla: fuente primaria, metodología y denominador. Las de este
   documento se han citado solo cuando existen las tres.
7. Estado de **Cartography en CNCF** (el repositorio vive ya bajo la organización `cartography-cncf`)
   y su nivel de madurez, si eso pesa en la decisión de adopción.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
