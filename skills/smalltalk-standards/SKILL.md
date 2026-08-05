---
name: smalltalk-standards
description: Smalltalk and its live image-based development model. Use when working with .st, .cs (change set), .image, .changes or .sources files, Tonel or FileTree package directories with package.st and .class.st, Pharo (Pharo Launcher, Metacello baselines and ConfigurationOf/BaselineOf, Iceberg, Monticello .mcz packages, Spec/Bloc/Morphic UIs, Seaside or Teapot web apps), Squeak, Cuis Smalltalk, the OpenSmalltalk VM, GemStone/S 64 Bit and GemTalk topaz sessions, Cincom VisualWorks or ObjectStudio, Instantiations VAST Platform and ENVY, Dolphin Smalltalk, SUnit TestCase subclasses, smalltalkCI headless CI runs, doesNotUnderstand: and message-based dispatch, become:, thisContext, the class browser and the live debugger with restart/proceed on a running stack, or deciding whether to keep, extend or migrate an image-based system.
---

# Estándares de Smalltalk (desarrollo sobre imagen viva)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Smalltalk no está muerto, pero tampoco es una elección defendible para software nuevo de
terceros.** Los datos, verificados: Pharo tiene desarrollo activo (estable **13.1.0**, jun-2025, con
Pharo 14 anunciado y **retrasado** en 2026); Squeak sigue publicando imágenes; **GemStone/S 64 Bit**
publicó **3.7.5 en marzo de 2026**; **VAST Platform 2026 (v15.0.0) salió el 18-feb-2026**. Hay
proveedores cobrando, hay releases y hay producción. Y aun así:

**Postura honesta, dicha aquí y no escondida en §7:**
- **Para un producto nuevo que vas a entregar a un cliente y que mantendrá otro equipo: casi nunca
  es la elección correcta.** No por el lenguaje —que es excelente— sino por lo que cuesta alrededor:
  contratar es muy difícil, el tooling no encaja con la cadena de entrega estándar (§4) y cada
  decisión operativa exige explicar el modelo de imagen a gente que no lo ha visto nunca.
- **Sí es la elección correcta**, y sin complejos, en: **investigación y prototipado de lenguajes y
  herramientas**, **docencia**, **mantenimiento y evolución de sistemas existentes** (que los hay,
  grandes y rentables, en seguros, banca, logística y manufactura), y **sistemas con GemStone donde
  la persistencia transparente de objetos es el valor central**.
- **El argumento real a favor no es la sintaxis, es el entorno**: navegador de clases y **depurador
  vivo** —parar en la excepción, inspeccionar y **modificar el método, reiniciar el marco de pila y
  continuar** sin relanzar el sistema— siguen siendo, en 2026, una experiencia de depuración que
  casi ningún stack moderno iguala. Si ese es el motivo, defiéndelo con eso.

Cubre: implementaciones libres y comerciales y su coste; **la imagen como artefacto y por qué rompe
la cadena de CI moderna**; control de versiones real (Iceberg/Tonel sobre Git, Monticello como
histórico); convenciones de código y de paquetes; tests con SUnit y CI headless; seguridad de la
imagen; y la decisión de mantener, encapsular o migrar.

**No aplica**: ver `ruby-standards` (**el descendiente directo del modelo de objetos y de los
bloques**; si la pregunta es "cómo escribo esto hoy con estas ideas", suele ser la respuesta —pero
Ruby no tiene imagen, ni depurador vivo, ni `become:`), `clojure-standards` y `lisp-standards`
(**el otro linaje con REPL sobre estado vivo**: la frontera es que allí el fichero es la verdad y la
imagen es un producto del build, aquí la imagen ha sido históricamente **el** artefacto — es la
diferencia que explica §4), `objective-c-standards` (**hereda de Smalltalk el paso de mensajes y su
sintaxis de selectores**; la frontera es el runtime y la plataforma Apple), `python-standards`,
`typescript-standards`, `jvm-spring-standards`, `dotnet-standards`, `go-standards` (**destinos
reales de una migración y alternativa por defecto para lo nuevo**: la calidad del código destino es
suya), `refactoring-tech-debt-standards` (**suyos** *strangler fig*, rama por abstracción y
caracterización de código sin tests), `enterprise-architecture-standards` (inventario, modelo TIME
y las "R"), `legacy-modernization-standards` (**skill paraguas** de una imagen heredada: qué "R" se
elige, si se congela, se encapsula o se reescribe, y la arqueología previa) y
`migration-projects-standards` (**la ejecución del corte** una vez decidido: ensayo, ventana, cuadre
del dato, rollback y apagado del origen), `tech-leadership-standards` y `technical-hiring-standards` (**el problema de contratar
es real y su gestión es suya**; aquí solo se declara como criterio de decisión),
`nosql-standards` y `data-platform-standards` (GemStone como base de datos de objetos se decide con
criterio de aquí, pero la operación de un motor de datos —backup, HA, tuning— es suya),
`opensource-licensing-standards` (análisis de licencias; aquí qué licencia tiene cada implementación,
§2), `cicd-standards` (la pipeline; aquí el problema específico de construir desde una imagen),
`testing-qa-standards` (reparto entre niveles y política de cobertura; aquí SUnit y el runner),
`appsec-standards` y `vulnerability-management-standards` (metodología y triaje),
`mumps-standards`, `ibm-i-rpg-standards`, `vb6-standards` (**no son comparables**: aquellas son
plataformas sin elección; Smalltalk sigue teniendo comunidad, releases y decisión posible).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Elección | Nota verificada (ago-2026) |
|---|---|---|
| Implementación libre por defecto | **Pharo** | Estable **13.1.0** (26-jun-2025). **Pharo 14 está retrasado**: el propio proyecto publicó el 29-jun-2026 que *"our usual April–May release did not happen this year"*. **Planifica sobre 13, no sobre 14** |
| Licencia de Pharo | **MIT con partes bajo Apache** — leída en crudo del `LICENSE` | *"Licensed under the MIT License with parts under the Apache License."* **No es "MIT" a secas**: si vas a redistribuir, revisa las partes Apache (aviso de patentes y `NOTICE`) |
| Squeak | **Investigación, docencia y compatibilidad histórica** | **Discrepancia declarada**: la página de descargas da como *Current Release* **Squeak 6.0** (build 22156, imágenes regeneradas en jun-2026), pero el sitio publica también notas de release de **6.1**. Confirma cuál es la vigente antes de fijarla (§8) |
| Cuis Smalltalk | Alternativa minimalista a Squeak, núcleo pequeño y limpio | Elección razonable para docencia y sistemas embebidos pequeños; ecosistema mucho menor |
| Persistencia de objetos | **GemStone/S 64 Bit** (GemTalk Systems) — **el caso comercial más sólido** | **3.7.5, marzo de 2026**. Base de datos de objetos transaccional y multiusuario con Smalltalk dentro: la persistencia es transparente y ese es el valor. **Licencia**: *Community/Web Edition* gratuita o de bajo coste **que permite uso comercial en producción**, y *Enterprise* perpetua a medida. **Lee el keyfile y los términos: las capacidades dependen de la licencia** |
| Comercial multiplataforma | **Cincom Smalltalk** (VisualWorks + ObjectStudio) | Plataforma comercial viva; documentación pública en torno a la **release 9.5**. **Hueco: no publica tarifas** (§8) |
| Comercial empresarial | **VAST Platform** (Instantiations, ex VA Smalltalk) | **2026 = v15.0.0, publicada el 18-feb-2026**; cadencia anual sostenida (2025 = 14.x, 2024 = 13.x). Usa **ENVY** como repositorio histórico y ha ido mejorando su soporte **Tonel** para trabajar contra Git. **Hueco: no publica tarifas** |
| Dolphin Smalltalk | Solo Windows; **no para proyectos nuevos** | Verificar estado de mantenimiento antes de considerarlo siquiera |
| VM | **OpenSmalltalk VM** para Pharo/Squeak/Cuis | Es la VM común del mundo libre; su release condiciona qué imagen puedes correr |
| Control de versiones | **Git, con Iceberg y formato Tonel** (un fichero por clase, un directorio por paquete) | **Obligatorio.** Es lo que hace revisable el diff y compatible el repositorio con el resto del mundo |
| Monticello (`.mcz`) | **Solo histórico**: leer repositorios antiguos | Es un formato binario por paquete: no da diffs revisables ni integra con Git. **Migrar a Tonel** cualquier repositorio que se siga tocando |
| Gestión de dependencias | **Metacello con `BaselineOf`** (no `ConfigurationOf`, que es el modelo antiguo) | Las dependencias externas se fijan **por commit o tag**, nunca por rama |
| Tests | **SUnit** (subclases de `TestCase`) — el origen de xUnit | Ejecutados **headless** desde CLI, ver §4 |
| CI | **smalltalkCI** | Proyecto **activo** (commits en agosto de 2026; release **v3.0.8**, may-2026). Ejecuta la suite headless en Pharo/Squeak/GemStone desde una pipeline estándar |

## 3. Estructura y convenciones

- **El código fuente vive en Git en formato Tonel, y el repositorio es la verdad. La imagen es un
  producto del build.** Esta inversión es toda la modernización de la plataforma en una frase, y es
  el criterio del que dependen §4 y §7. Un proyecto que sigue distribuyendo `.image` como artefacto
  primario y `.changes` como historia no tiene control de versiones: tiene un backup.
- **Un paquete = una unidad de carga con `BaselineOf`.** Sin dependencias circulares entre paquetes.
  Los tests van en un paquete `-Tests` separado, que no se carga en la imagen de producción.
- **Nombres**: prefijo de proyecto en los nombres de clase (no hay espacios de nombres reales en el
  Smalltalk clásico: `Foo` colisiona globalmente y el segundo `Foo` que se carga **pisa al primero
  en silencio**). Selectores que se lean como una frase; métodos cortos; categorías/protocolos
  mantenidos, porque son la navegación real del sistema.
- **Extensiones de clases del sistema (*monkey patching*): permitidas por diseño, y peligrosas por
  la misma razón.** Regla: solo en un protocolo con **tu prefijo de proyecto** (`*MiProyecto`), para
  que la extensión viaje con tu paquete y no con la clase base; nunca modificando un método
  existente de la clase base; y cero extensiones que cambien comportamiento heredado. Una extensión
  que altera `Object` o `Collection` es un fallo global que aparecerá en otro paquete.
- **`doesNotUnderstand:` para proxies y DSL: con justificación escrita.** Convierte errores de
  compilación en comportamiento en tiempo de ejecución y destruye la navegación de referencias.
- **`become:`, `thisContext` y la reflexión sobre la pila son herramientas de constructor de
  herramientas**, no de código de aplicación. Están vetadas fuera de infraestructura, con motivo.
- **Nada de "código que solo existe en mi imagen".** Todo cambio se guarda en el paquete y se
  commitea; el `.changes` es una red de seguridad ante caída, no un historial.

## 4. Calidad, tests y CI (el problema de la imagen)

**El eje del apartado: la imagen rompe todas las suposiciones de una cadena de entrega moderna**, y
hay que compensarlas explícitamente.

- **La imagen es estado mutable acumulado**: contiene todo lo que pasó por esa sesión —definiciones
  ya borradas de los ficheros, objetos vivos, y **cualquier secreto que se haya leído o tecleado**.
  No es reproducible por construcción, no es diffeable y no es auditable.
- **Regla no negociable**: la imagen de producción se genera **desde una imagen base publicada, en
  un proceso headless, cargando el código desde Git por Metacello, en un paso único y repetible**.
  Nunca a partir de la imagen de trabajo de nadie.
- **Gate de CI mínimo**, en orden de coste creciente: (1) la baseline **carga limpia** en una imagen
  base recién descargada, sin diálogos ni errores; (2) **SUnit headless** con `smalltalkCI` y código
  de salida no nulo al fallar; (3) el árbol Tonel no tiene cambios sin commitear tras la carga
  (detecta código que solo existía en la imagen de alguien); (4) la imagen de producción se
  construye y arranca. Añadir análisis de reglas de calidad del propio entorno donde exista
  (en Pharo, las críticas del *Quality Assistant*/Renraku) como aviso, no como bloqueo inicial.
- **Los diálogos modales son el enemigo de CI**: cualquier carga que pregunte algo (conflicto de
  Iceberg, credencial, actualización) cuelga la pipeline sin mensaje útil. Todo el arranque va con
  configuración explícita y sin interacción.
- **Tests**: comportamiento observable, con cobertura de bordes y errores. Ojo con el vicio local de
  **tests que dependen del estado de la imagen** (variables de clase, singletons, objetos
  registrados): `setUp`/`tearDown` reales y un orden de ejecución que no importe.
- **Cero secretos en el entorno del build**: acabarían dentro del binario de la imagen.

*§6 se omite deliberadamente*: la observabilidad, los límites y la capacidad de un servicio
Smalltalk se rigen por `observability-standards` y por la skill de la plataforma de despliegue; lo
único específico de esta —imagen, arranque headless, GemStone— está en §4 y §5.

## 5. Seguridad del stack

- **La imagen es un artefacto sensible y opaco**: guarda credenciales, tokens y datos que hayan
  pasado por memoria. Trátala como un secreto en reposo (cifrada, con acceso restringido), no como
  un binario cualquiera, y **regenérala**, no la parchees.
- **El "servidor" es la imagen entera**: en Smalltalk, exponer un servicio significa que el proceso
  expuesto contiene el compilador, el navegador y capacidad de reflexión total. Una RCE no es una
  escalada: es acceso completo al sistema desde el primer paso. Consecuencias:
  - **La imagen de producción se despliega sin herramientas de desarrollo cargadas** cuando la
    implementación lo permita, y **sin ninguna consola remota expuesta**.
  - **Cualquier canal de evaluación remota de código (workspace remoto, endpoint que compile o
    evalúe expresiones) está prohibido en producción.** Es el equivalente exacto de dejar swank o
    un `eval` abierto.
  - Servir siempre detrás de un proxy inverso, escuchando en localhost, con TLS terminado fuera.
- **Ejecutar como usuario sin privilegios, con sistema de ficheros de solo lectura salvo el
  directorio de trabajo**: la imagen se reescribe a sí misma si se lo permites (`Smalltalk snapshot`).
- **Dependencias**: Metacello carga **desde repositorios Git de terceros**, y en Smalltalk cargar
  código *es ejecutarlo* (se ejecutan métodos de clase en la carga). **Fija por commit, nunca por
  rama**; revisa lo que cargas; el ecosistema es pequeño y no hay proceso de auditoría ni firmas.
- **GemStone**: la autorización es del servidor de objetos, no de la aplicación. Cuentas nominativas,
  mínimas y auditadas; `topaz` y las sesiones administrativas, restringidas. Backup y **restore
  probado** (ver `backup-recovery-standards`).

## 7. Sostenibilidad, migración y prohibiciones

**Criterio de decisión** (antes de escribir o de reescribir, por escrito):
1. **¿Es mantenimiento o es nuevo?** Mantener y extender un sistema Smalltalk sano es correcto y
   suele ser lo más barato con diferencia. **Reescribirlo "porque es Smalltalk" es la decisión que
   destruye valor** — el sistema encapsula décadas de reglas de negocio no especificadas en ningún
   otro sitio.
2. **¿Puedes cubrir el relevo?** Es la restricción dominante y es honesta de reconocer: el mercado
   es minúsculo. La respuesta viable casi nunca es contratar Smalltalkers: es **formar** a gente
   buena (se aprende rápido: el lenguaje es diminuto) y **documentar** el arranque, el build y el
   despliegue para que no dependan de la memoria de nadie. Presupuéstalo.
3. **¿Qué justifica quedarse?** El depurador vivo, la persistencia de GemStone o el coste de la
   alternativa. Si nada de eso aplica y el sistema es pequeño, migrar es defendible.
4. **Si migras**: **nunca *big bang*, nunca traducción automática**. Encapsula tras una interfaz
   estable (HTTP/gRPC), construye lo nuevo fuera contra ella (*strangler fig*) y sustituye **por
   dominio**. El destino lo manda la skill del lenguaje destino.

**Prohibiciones:**
- ❌ **PROHIBIDO** tratar la `.image` como artefacto primario de código o el `.changes` como
  historia de versiones. El repositorio Git en Tonel es la verdad (§3).
- ❌ **PROHIBIDO** desplegar una imagen que no salga de un build headless reproducible desde Git; o
  construirla desde la imagen de trabajo de un desarrollador.
- ❌ Secretos en el entorno del build o presentes en la imagen entregada.
- ❌ Cualquier canal de evaluación de código remota en producción (§5).
- ❌ Dependencias Metacello fijadas por rama en vez de por commit o tag.
- ❌ Nuevos repositorios en Monticello (`.mcz`); mantener en Monticello algo que se siga tocando.
- ❌ Extensiones de clases del sistema fuera de un protocolo con prefijo propio, o que modifiquen
  comportamiento existente.
- ❌ `become:`, `thisContext` o `doesNotUnderstand:` en código de aplicación sin justificación escrita.
- ❌ Clases nuevas sin prefijo de proyecto (colisión global silenciosa).
- ❌ Cargas de CI que puedan abrir un diálogo modal.
- ❌ Tests que dependan del estado acumulado de la imagen.
- ❌ **Elegir Smalltalk para un producto nuevo que mantendrá un tercero, sin un motivo escrito de los
  de §1 y sin plan de relevo.** Y, simétricamente: **reescribir un sistema Smalltalk sano solo por
  el lenguaje.** Ambas son el mismo error de criterio en direcciones opuestas.
- ❌ Comprometerse con Cincom, VAST o GemStone Enterprise sin coste de licencia **y de renovación**
  por escrito; o asumir que la *Community Edition* de GemStone cubre tu caso sin leer el keyfile.
- ❌ Asumir que Pharo es "MIT": el `LICENSE` dice **MIT con partes Apache** (§2).

## 8. Verificación web obligatoria

1. **Pharo**: versión estable vigente (a ago-2026, **13.1.0** de jun-2025) y **el estado real de
   Pharo 14**, anunciado como retrasado el 29-jun-2026. No planifiques sobre una release no
   publicada. Licencia leída en crudo del `LICENSE`.
2. **Squeak — discrepancia declarada, resuélvela antes de fijar versión**: la página de descargas
   presenta **6.0** (build 22156) como *Current Release*, mientras el sitio publica notas de release
   de **6.1**. Comprueba cuál es la recomendada y qué VM (OpenSmalltalk) exige.
3. **GemStone/S 64 Bit**: versión vigente (a ago-2026, **3.7.5** de marzo de 2026), calendario de
   soporte de la que uses, y **los términos exactos de la licencia que aplicas** (Community/Web
   permite uso comercial en producción con límites; Enterprise es a medida). Léelos, no los supongas.
4. **VAST Platform**: versión vigente (a ago-2026, **15.0.0** del 18-feb-2026) y su cadencia.
   **Cincom Smalltalk**: release vigente (documentación pública en torno a **9.5**).
   **Hueco declarado en ambos: no publican tarifas.** Cualquier cifra de coste tiene que venir de
   una oferta contractual — y el coste de **renovación** es el dato que se olvida.
5. **OpenSmalltalk VM**: release vigente y qué imágenes soporta; es lo que limita a qué versión
   puedes subir.
6. **smalltalkCI**: versión y plataformas soportadas (a ago-2026, **v3.0.8** de may-2026, con
   commits en agosto de 2026).
7. **Iceberg y Tonel**: estado del soporte en tu implementación —especialmente en VAST, donde el
   puente entre ENVY y Tonel es lo que decide si puedes trabajar contra Git de verdad.
8. CVEs y avisos de la VM, del stack HTTP/TLS que embebas y de las librerías Metacello que cargues.
9. **Dolphin Smalltalk**: estado de mantenimiento actual, antes de considerarlo para nada.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
