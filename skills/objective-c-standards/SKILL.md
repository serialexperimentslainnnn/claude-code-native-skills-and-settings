---
name: objective-c-standards
description: Objective-C and Objective-C++ engineering standards for legacy maintenance and Swift interoperability. Trigger on .m/.mm/.h files with @interface/@implementation/@property, ARC and __weak/__strong/__unsafe_unretained/__bridge, NS_ASSUME_NONNULL_BEGIN and nullable/nonnull annotations, lightweight generics, NS_SWIFT_NAME/NS_REFINED_FOR_SWIFT/NS_SWIFT_SENDABLE, bridging headers and module.modulemap, objc_msgSend, method swizzling, categories, KVO/KVC, NSError** out-parameters, GCD dispatch_queue/dispatch_sync, NSSecureCoding and NSKeyedUnarchiver, Podfile/Podfile.lock, Cartfile, xcodebuild on Objective-C targets, or XCTest suites written in Objective-C.
---

# Estándares Objective-C

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **lenguaje** Objective-C y Objective-C++: ficheros `.m`/`.mm` y cabeceras con `@interface`/`@property`, ARC y calificadores de propiedad, anotaciones de nulabilidad, generics ligeros, el runtime dinámico (`objc_msgSend`, categorías, swizzling, KVO/KVC), el diseño de cabeceras **para consumo desde Swift**, GCD desde Objective-C, tooling (`xcodebuild`, `clang` analyzer, `clang-format`, sanitizers) y gestión de dependencias del target.

**El caso real es mantenimiento e interoperabilidad, no código nuevo.** Para código nuevo en plataformas Apple la respuesta es **Swift**; escribir un módulo nuevo en Objective-C exige justificación escrita (§7). Esta skill existe por dos motivos concretos: (a) queda muchísimo Objective-C en producción que hay que tocar sin romperlo, y (b) **la frontera Swift↔Objective-C es donde se rompen las cosas** — nulabilidad mal anotada, `id` sin generics, ciclos de retención que Swift no ve, `NSError**` que Swift traduce a `throws`, y el runtime dinámico que el compilador de Swift no puede verificar. El eje del documento es: **que el Objective-C existente sea seguro de consumir desde Swift y seguro de borrar poco a poco**.

**No aplica**: ver `mobile-standards` (**la app es suya**: arquitectura, navegación, ciclo de vida de la app, permisos y `Info.plist`, firma, distribución en App Store/TestFlight, accesibilidad, almacenamiento seguro como política, MASVS, crash reporting; y **Swift es suyo** — aquí solo la interoperabilidad **desde el lado Objective-C**: cómo se anota y se diseña la cabecera para que Swift la consuma sin explotar), `c-standards` y `cpp-standards` (Objective-C es superconjunto de C y `.mm` mezcla C++: **el C y el C++ que contiene un `.m`/`.mm` siguen sujetos a sus skills** — gestión de memoria manual, undefined behavior, enteros, flags de warning, sanitizers, RAII y la STL; **lo específico del runtime de Objective-C, ARC y el puente con Swift es de aquí**), `assembly-standards` (un `.mm` puede contener `asm` en línea: el criterio de cuándo y cómo se escribe ensamblador es suyo), `cryptography-pki-standards` (elección de algoritmo, modo y ciclo de vida de claves; aquí solo su uso desde las APIs de la plataforma), `identity-access-management-standards` (flujos OAuth/OIDC del lado del IdP), `appsec-standards` (modelado de amenazas y proceso), `cicd-standards` (diseño de la pipeline; aquí solo qué herramienta se ejecuta), `secrets-management-standards` y `vulnerability-management-standards` (SLA de parcheo y triaje de CVEs de dependencias).

## 2. Decisiones por defecto y toolchain

> **Verificar la última versión por web antes de fijarla en un proyecto real** (§8). Lo siguiente es el estado verificado a **ago-2026**.

| Decisión | Default | Alternativa justificable | Motivo |
|---|---|---|---|
| Lenguaje para código nuevo | **Swift** | Objective-C solo si el módulo debe consumirse desde C/C++ existente, si el runtime dinámico es requisito real, o si el equipo mantiene un framework ObjC público con contrato estable | Verificado: Apple **no publica cambios de lenguaje** en Objective-C; lo que cambia son sistema de módulos y build (p. ej. *Explicitly Built Modules* en Xcode 16 para C/ObjC). **No hay deprecación anunciada**, pero tampoco evolución: es un lenguaje **estable y estático** |
| Toolchain | **Xcode 26.x** (línea vigente; 26.6 RC con Swift 6.3 a ago-2026) | La versión mínima que exija App Store Connect | Verificado: desde el **28-abr-2026** toda subida a App Store Connect exige build con SDK de iOS 26 o posterior (Xcode 26+), **sin periodo de gracia** |
| ARC | **Obligatorio** (`-fobjc-arc`) en todo fichero | MRR (`-fno-objc-arc`) **solo** por fichero y con motivo escrito (interoperabilidad con Core Foundation muy antigua, código generado) | MRR a mano es una fuente de fugas y sobre-liberaciones que ninguna herramienta compensa |
| Dependencias | **Swift Package Manager** | XCFramework vendorizado con checksum cuando el proveedor no publica en SPM | Verificado: **CocoaPods trunk pasa a solo lectura el 2-dic-2026** — *"no new versions or pods will be added to trunk"*, aunque *"this will keep all existing builds working"* mientras existan GitHub y jsDelivr. Es decir: los builds actuales siguen, **pero no habrá actualizaciones ni parches de seguridad por trunk**. Migrar es trabajo planificado, no urgencia del día |
| Carthage | **No adoptar** | Mantener el existente hasta migrar | Verificado por feed Atom: última release **0.40.0 (2024-09-09)**. Sin releases desde entonces: no es base para un proyecto nuevo |
| Mezcla Swift/ObjC en SPM | **Targets separados** (`FooObjC` clang + `Foo` swift) | Binary target / XCFramework | Verificado: **SE-0403 (mixed language targets) está "Returned for Revision"**, no aceptado. En SPM **un target es Swift o es C-based, no ambos**. En un target de Xcode sí conviven (bridging header + generated header) |
| Tests | **XCTest** para el código Objective-C | **Swift Testing** para los tests nuevos escritos en Swift | Verificado: **Swift Testing solo soporta Swift**; XCTest sigue siendo el único camino para tests escritos en Objective-C, UI automation (XCUITest) y tests de rendimiento (XCTMetric). XCTest **no está deprecado**. Un mismo target de test admite ambos mundos, pero **cada test vive en uno solo** |
| Formato | `clang-format` con `.clang-format` versionado | — | `clang-format` entiende Objective-C; sin fichero versionado el estilo se rediscute en cada PR |

Reglas de toolchain:
- El proyecto declara su **versión mínima de despliegue** y **compila con `-Werror` en CI**. El set de warnings de C aplica íntegro (ver `c-standards`), más los específicos de Objective-C: `-Wobjc-missing-property-synthesis`, `-Wdirect-ivar-access`, `-Wnullable-to-nonnull-conversion`, `-Wstrict-selector-match`, `-Wundeclared-selector`, `-Wdeprecated-implementations`, `-Wobjc-interface-ivars`.
- **`-Wnullable-to-nonnull-conversion` es innegociable**: es el warning que evita que Swift reciba un `nil` en un `let x: String` y aborte con un *crash* sin traza útil.
- Build reproducible por `xcodebuild` desde CI con `-scheme`/`-destination` explícitos; nada de "compila en mi Xcode". Configuración en `.xcconfig` versionados, no en la UI del proyecto.

## 3. El lenguaje: ciclo de vida, frontera con Swift y runtime

### ARC y ciclo de vida
- Calificadores: `strong` (default para objetos), `weak` para referencias hacia atrás y delegados, `copy` **obligatorio** para `NSString`/`NSArray`/`NSDictionary`/bloques en propiedades públicas (el llamante puede pasar la subclase mutable y mutarla a tu espalda), `assign` solo para escalares. **`unsafe_unretained` está vetado** salvo interoperabilidad con API que lo exija y con comentario: no se anula al liberarse, así que produce *use-after-free* en vez de `nil`.
- **Ciclos de retención en bloques**: un bloque captura `self` con `strong`. El patrón obligatorio cuando el bloque lo retiene el propio objeto (o algo que él posee):

```objc
__weak __typeof(self) weakSelf = self;
self.completion = ^{
    __strong __typeof(weakSelf) strongSelf = weakSelf;   // una sola vez, al entrar
    if (!strongSelf) { return; }                          // salida temprana obligatoria
    [strongSelf doWork];
};
```
  Sin el `strongSelf`, cada acceso a `weakSelf` puede pasar a `nil` a mitad del bloque y el comportamiento se vuelve no determinista. **Comprobar `nil` y salir**, no continuar "por si acaso".
- `delegate` es **siempre `weak`** (o `unsafe_unretained` documentado si el protocolo no es de objeto). Un delegado `strong` es un ciclo garantizado.
- `@autoreleasepool` **obligatorio** dentro de bucles que crean objetos temporales en volumen (parsing, imágenes, conversiones): sin él el pico de memoria crece hasta el final del ciclo de run loop y el sistema mata el proceso.
- Core Foundation: transferencia de propiedad **explícita** con `__bridge`/`__bridge_transfer`/`__bridge_retained` o las macros `CFBridgingRetain`/`CFBridgingRelease`. Un `__bridge` a secas donde tocaba `__bridge_transfer` es una fuga que el analizador **sí** detecta: no se silencia.
- `dealloc`: solo desregistro (observers de KVO/`NSNotificationCenter` si el ciclo de vida lo exige) e invalidación de timers. **Nada de lógica de negocio ni llamadas a métodos sobrescribibles**; el objeto ya está medio destruido.

### `nil` como receptor válido — la trampa estructural
Enviar un mensaje a `nil` es legal y devuelve cero/`nil`/struct a cero. Consecuencia: **un bug de inicialización no falla, se propaga en silencio** hasta un punto lejano donde el síntoma no tiene relación con la causa.
- No se usa el retorno de un método como prueba de que el receptor existía. Si un `nil` en ese punto es un fallo de programación, hay `NSParameterAssert`/`NSAssert` (que **desaparecen con `NS_BLOCK_ASSERTIONS`**, así que no valen para validar entrada externa) o comprobación explícita.
- Cuidado con el retorno de tipos no-objeto: para `nil` receptor, los valores de punto flotante y las structs devueltas están definidos como cero **en las ABI actuales de Apple**, pero depender de eso es frágil; comprueba antes.

### Propiedades y `atomic`
- `nonatomic` por defecto. **`atomic` no da seguridad de hilos**: garantiza que un `get`/`set` individual no devuelve un valor a medias, nada más. Un `array.count` seguido de un acceso por índice sigue siendo una carrera. La sincronización real se diseña (cola serie, lock, inmutabilidad), no se obtiene poniendo `atomic`.
- Acceso a ivars: **por la propiedad**, no directo (`-Wdirect-ivar-access`), salvo en `init` y `dealloc`, donde el acceso directo es lo correcto (los setters pueden tener efectos y el objeto no está en estado válido).
- Toda propiedad pública tiene semántica declarada explícita (`nonatomic, copy, readonly`...). Nada de `@property NSString *name;` sin calificar.

### Nulabilidad y generics ligeros — requisito para consumir desde Swift
Esto **no es cosmético**: es lo que decide si Swift ve `String` o `String!`. Un `id` sin anotar llega a Swift como `Any!`, y un implicitly-unwrapped optional que resulta `nil` **aborta el proceso**.
- **Toda cabecera pública va envuelta** en `NS_ASSUME_NONNULL_BEGIN` / `NS_ASSUME_NONNULL_END`, marcando explícitamente lo que sí puede ser `nil` con `nullable` (y `null_resettable` donde aplique). Una cabecera sin anotar es deuda que se paga en el consumidor.
- **Generics ligeros obligatorios** en colecciones expuestas: `NSArray<NSString *> *`, `NSDictionary<NSString *, NSNumber *> *`. Sin ellos Swift recibe `[Any]` y todo el tipado del lado Swift se degrada a *casts*.
- `instancetype` en constructores, nunca `id`. `NS_DESIGNATED_INITIALIZER` en el inicializador designado y `NS_UNAVAILABLE` en los que no deben usarse: sin eso, Swift hereda inicializadores que dejan el objeto inválido.
- Enumeraciones con `NS_ENUM`/`NS_OPTIONS`, cadenas tipadas con `NS_STRING_ENUM`/`NS_TYPED_ENUM`. Nunca `enum` de C desnudo en API pública.
- **La anotación es una promesa que el compilador solo verifica parcialmente**: `-Wnullable-to-nonnull-conversion` activo, y en las fronteras que reciben datos externos (JSON, disco, red) se **comprueba en runtime** antes de devolver algo declarado `nonnull`.

### Diseño de la cabecera pensando en el consumidor Swift
- `NS_SWIFT_NAME` para dar el nombre idiomático en Swift cuando la traducción automática produce algo ilegible.
- `NS_REFINED_FOR_SWIFT` cuando la API Objective-C no puede ser idiomática (out-params, punteros, `NSNumber` boxed): el símbolo se importa con prefijo `__` y se envuelve en una extensión Swift. **Es la vía correcta**, no cambiar la API ObjC para complacer a Swift.
- `NS_NOESCAPE` en bloques no escapantes, `NS_SWIFT_SENDABLE` en tipos seguros de cruzar aislamiento y `NS_SWIFT_UI_ACTOR` / `NS_SWIFT_NONISOLATED` donde el aislamiento importe — **verificar disponibilidad y semántica exacta en el SDK de la versión usada** (§8): estas anotaciones han ido llegando por versiones y su efecto depende del modo de concurrencia de Swift del target.
- `NS_ERROR_ENUM` para dominios de error, de modo que Swift los importe como `Error` tipado.
- `NS_SWIFT_UNAVAILABLE` para lo que no debe cruzar; `API_AVAILABLE`/`API_DEPRECATED` en toda API con condición de versión.
- **El módulo se expone por `module.modulemap`**, no por bridging header, cuando es un framework consumible. El bridging header es para el código de la app, y **no** existe en dirección contraria: Swift se ve desde ObjC por el header generado (`<Producto>-Swift.h`), y **solo lo marcado `@objc`/`@objcMembers` y heredado de `NSObject`**.

### Categorías
- Sirven para **añadir** métodos a una clase que no controlas. Todo método de categoría sobre clase ajena lleva **prefijo de proyecto** (`px_doThing`): el runtime no tiene namespaces y dos categorías que declaren el mismo selector colisionan silenciosamente, ganando la última cargada — orden **no determinista** entre bibliotecas.
- **PROHIBIDO sobrescribir un método existente desde una categoría.** El comportamiento no está definido y rompe a la clase base, a otras categorías y a las subclases. Si hace falta cambiar comportamiento: subclase, composición o delegación.
- Categorías con propiedades: requieren *associated objects* (`objc_setAssociatedObject`), que son estado oculto sin `dealloc` propio. Se usan con parquedad y se documentan.
- Extensiones de clase (`@interface Foo ()` en el `.m`) sí son el mecanismo correcto para lo privado, incluido redeclarar una propiedad `readonly` pública como `readwrite`.

### Runtime dinámico
- `objc_msgSend` es el mecanismo de despacho: **todo envío es dinámico**, no hay devirtualización. Implicación práctica: el compilador no puede avisarte de casi nada sobre el receptor, así que el tipado estático de las cabeceras es tu única red.
- **PROHIBIDO el *method swizzling* en código de aplicación** salvo caso justificado y documentado (típicamente instrumentación de terceros, y aun así se prefiere una alternativa). Es una fuente clásica de fallos irreproducibles: depende del orden de carga, se rompe en cada actualización del SDK, y dos librerías que hagan swizzle del mismo selector se corrompen entre sí. Si se hace pese a todo: solo en `+load` o con `dispatch_once`, sobre selectores propios, con el `IMP` original invocado siempre, y con dueño y fecha de revisión escritos.
- `respondsToSelector:` / `performSelector:` son *escape hatches*, no diseño. `performSelector:` con más de dos argumentos o retorno no-objeto es incorrecto (ARC no conoce la firma y el `-Warc-performSelector-leaks` lo dice). **Sustituto por defecto: un bloque tipado o un protocolo con `@optional`.**
- `NSInvocation` y `objc_msgSend` a mano: solo en código de infraestructura con tests propios; en `arm64` requieren el cast correcto de `objc_msgSend` a la firma exacta o el resultado es basura.
- **KVO/KVC son frágiles**: claves como cadenas sin verificación de compilación, `observeValueForKeyPath:` sin tipado, y **quitar el observer en el momento exacto** (un observer vivo tras el `dealloc` del observado es un *crash* garantizado). Criterio: usar el API basado en token (`-addObserverForKeyPath:...` que devuelve `NSKeyValueObservation` en Swift, o guardar el contexto y desregistrar en `dealloc`), preferir notificaciones o callbacks explícitos, y **nunca KVO sobre objetos ajenos cuyo ciclo de vida no controlas**. `valueForKey:` con cadena construida es, además, superficie de ataque.

### Errores
- Patrón canónico: `- (BOOL)doThing:(NSError **)error` o retorno de objeto con `nil` en fallo. **El indicador de fallo es el retorno, no el `error`**: se comprueba el retorno primero y solo entonces se lee `*error`. Escribir en `*error` sin comprobar que el puntero no es `NULL` es un *crash*.
- Swift traduce este patrón a `throws` **solo si la firma sigue la convención** (último parámetro `NSError **`, `NS_SWIFT_NOTHROW` para excluirlo). Cambiar la firma rompe el lado Swift aunque el ObjC compile.
- **Las excepciones de Objective-C no son control de flujo**: representan errores de programación (índice fuera de rango, selector no reconocido) y **no son seguras con ARC** — desenrollar la pila con ARC filtra memoria salvo con `-fobjc-arc-exceptions`, que tiene coste. `@try/@catch` solo para envolver API de sistema que documenta que lanza (algunas de `NSFileHandle`, KVC) y en frontera con C++ en `.mm`. **PROHIBIDO** `@throw` para errores esperables.

### Concurrencia (GCD desde Objective-C)
- Modelo por defecto: **una cola serie por unidad de estado mutable**. Una cola serie es un lock que además ordena; es más barato de razonar que `NSLock` repartido.
- Colas concurrentes solo con patrón lector/escritor explícito (`dispatch_barrier_async` para escritura) y test de concurrencia bajo TSan.
- **PROHIBIDO `dispatch_sync` sobre la cola principal desde la cola principal**: *deadlock* inmediato. Por extensión, `dispatch_sync` sobre cualquier cola desde esa misma cola. Regla operativa: `dispatch_sync` solo hacia una cola de la que se sabe con certeza que no eres tú, y nunca mientras se sostiene otro lock.
- Todo trabajo de UI en la cola principal; toda I/O fuera de ella. `dispatch_after` no es un mecanismo de sincronización.
- Interop con `async/await` de Swift: una API ObjC con bloque de completado como **último** parámetro se importa como `async` — la firma es contrato. El bloque debe llamarse **exactamente una vez** por todos los caminos, incluidos los de error y cancelación: cero llamadas cuelga la tarea Swift para siempre y dos llamadas es un fallo de runtime.
- `volatile` no sincroniza (ver `c-standards`). Para contadores, `atomic_*` de C11 o `os_unfair_lock`; **`OSSpinLock` está deprecado** por inversión de prioridad.

### Objective-C++ (`.mm`)
- Se usa **solo** para hacer de puente con una biblioteca C++ existente, y se aísla: el C++ no se filtra a las cabeceras Objective-C públicas (una cabecera con `std::` obliga a todo consumidor a ser `.mm`). Patrón: cabecera ObjC limpia, `.mm` de implementación con un `struct` de implementación C++ oculto (pImpl).
- ARC y C++ conviven: un objeto ObjC como miembro de una clase C++ necesita `__strong`/`__weak` explícito y la clase deja de ser trivialmente copiable. Los `id` dentro de `union` o de tipos POD requieren cuidado.
- Excepciones: una excepción C++ que cruza a un frame Objective-C con ARC filtra recursos; se captura en el borde del puente.
- **El C++ de un `.mm` está sujeto a `cpp-standards`** (RAII, la STL, UB, flags). Verificado: hay interacción conocida entre módulos estándar de C++ y Objective-C++ según el modo de lenguaje C++ — comprobar las notas de la versión concreta de Xcode antes de activar módulos C++ en un target `.mm` (§8).

## 4. Calidad: análisis, tests y gates de CI

- **Clang Static Analyzer** (`xcodebuild analyze` o *Analyze* en Xcode) es el gate principal y es específicamente bueno en Objective-C: fugas de ARC/CF, sobre-liberación, `nil` en receptores, uso de valores no inicializados. **Cero hallazgos** en el árbol propio; una supresión exige `// NOLINT`-equivalente con motivo, no borrar el aviso.
- `clang-tidy` sobre `compile_commands.json` para lo que es C/C++ dentro del `.m`/`.mm` (`bugprone-*`, `cert-*`).
- `clang-format --dry-run --Werror` en CI, con `.clang-format` versionado. Reformateo masivo en commit aparte, registrado en `.git-blame-ignore-revs`.
- Tests: XCTest para el código Objective-C; **el test de la frontera es obligatorio** — para cada API pública consumida desde Swift, un test **escrito en Swift** que la ejerza. Es el único modo de comprobar que la nulabilidad, los generics y la traducción de `NSError**` son lo que se cree.
- Cobertura de bordes: `nil` en cada parámetro anotado `nullable`, colección vacía, cadena vacía, valores límite, bloque de completado invocado en todos los caminos, y el camino de error de cada `NSError**`.
- **Sanitizers en Xcode**, en schemes separados: Address Sanitizer (+ *Detect use of stack after return*), Thread Sanitizer y Undefined Behavior Sanitizer. ASan y TSan **no se combinan**. Además, *Zombie Objects* y *Malloc Scribble* para diagnosticar `over-release` en código MRR heredado. Nunca activos en un build de distribución.
- Instruments: **Leaks** y **Allocations** sobre el flujo crítico antes de liberar un cambio que toque ciclo de vida; el ciclo de retención no aparece en los tests unitarios.
- Gate mínimo de CI (todo rompe el build): formato → build con `-Werror` (warnings de §2) → `xcodebuild analyze` sin hallazgos → tests unitarios ObjC + tests Swift de la frontera → tests bajo ASan+UBSan → SCA/SBOM de dependencias.

## 5. Seguridad del stack

- **`NSKeyedUnarchiver` sin clases permitidas es ejecución de código.** **PROHIBIDO `+unarchiveObjectWithData:`** y toda la familia insegura: deserializar un archivo arbitrario instancia las clases que el atacante indique. Sustituto único: `NSSecureCoding` con `+unarchivedObjectOfClass:fromData:error:` / `+unarchivedObjectOfClasses:fromData:error:`, con `requiresSecureCoding = YES` y la **lista de clases permitidas lo más estrecha posible**. Toda clase serializable implementa `NSSecureCoding` (no solo `NSCoding`) y su `+supportsSecureCoding` devuelve `YES` de verdad, no por copiar-pegar.
- El mismo criterio vale para cualquier deserialización: `NSJSONSerialization` con validación de tipo de cada campo antes de usarlo (un `NSDictionary` que llega con un `NSNull` donde esperabas `NSString` es un `unrecognized selector` en producción). **Nunca** se confía en la forma del JSON.
- **Cadenas de formato**: `-Wformat=2 -Werror=format-security` activos. **PROHIBIDO** pasar entrada de usuario como cadena de formato a `+stringWithFormat:`, `NSLog`, `-appendFormat:` o predicados. Es lectura/escritura de memoria arbitraria. Lo mismo con `NSPredicate predicateWithFormat:` construido por concatenación: inyección directa; usar sustitución con `%@`/`%K`.
- Almacenamiento en dispositivo: **Keychain** para credenciales, tokens y claves, con la clase de protección más restrictiva que permita el caso (`...ThisDeviceOnly` cuando no debe sincronizar) y con `SecAccessControl` biométrico donde aplique. **`NSUserDefaults` no es almacenamiento seguro**: es un plist en claro, se lee en un backup y sobrevive a la desinstalación en algunos escenarios. Ficheros con `NSFileProtectionComplete` y `isExcludedFromBackup` donde corresponda. La política de qué se almacena y con qué clasificación es de `mobile-standards`; aquí, la API correcta.
- **Un binario de cliente no guarda secretos.** Toda cadena embebida —claves de API, tokens, secretos de cliente OAuth, URLs internas, credenciales de firma— está en manos del usuario: `strings` sobre el `.app` la encuentra en segundos. Ofuscar no es proteger. Si una operación exige un secreto, se ejecuta en el servidor. Lo que sí se protege es lo que el dispositivo **genera** (par de claves en Secure Enclave, token efímero en Keychain).
- Cripto: APIs de la plataforma (CryptoKit desde Swift, `SecKey`/`CommonCrypto` desde ObjC). **PROHIBIDO implementar criptografía propia**; comparación de secretos en tiempo constante, nunca `memcmp` ni `isEqualToString:`.
- Logging: `os_log` con formato y **redacción por defecto de los dinámicos** (`%{private}@` para todo lo que no sea explícitamente público). `NSLog` con objetos de dominio en un build de release es una fuga de PII al sistema de logs del dispositivo.
- Dependencias: pin exacto (versión + checksum en `Package.resolved`, checksum obligatorio en `binaryTarget`), SBOM del artefacto y SCA. **Todo pod que ya no reciba actualizaciones tras dic-2026 pasa a ser deuda de seguridad con fecha**, no una dependencia estable.

## 6. Rendimiento y operabilidad

- El despacho dinámico tiene coste, pero **casi nunca es el cuello de botella**: se mide con Instruments (Time Profiler) antes de tocar nada. Optimizar mensajes a mano (`IMP` cacheada) exige número medido y test.
- Picos de memoria: `@autoreleasepool` en bucles (§3) y `NSCache` en vez de `NSMutableDictionary` para cachés (responde a presión de memoria). Las advertencias de memoria del sistema se atienden.
- Crashes: dSYM archivado por build con su UUID; un crash sin símbolos es tiempo perdido. Los *unrecognized selector*, los `NSInvalidArgumentException` por `nil` y los ciclos de retención son las tres familias dominantes en bases Objective-C — se instrumentan y se cuentan.
- Arranque: `+load` se ejecuta antes de `main` y **retrasa el arranque de toda la app**; se prefiere `+initialize` (perezoso) o inicialización explícita. Un `+load` por librería de terceros es motivo legítimo para cuestionar la dependencia.

## 7. Sostenibilidad y prohibiciones

**Estrategia, no solo estilo.** El Objective-C de una base viva se trata como **deuda con plan de amortización**: se anota (nulabilidad y generics) antes de tocarlo, se cubre con tests desde Swift, y se sustituye por Swift **de dentro afuera** —primero la implementación interna, manteniendo la cabecera ObjC como fachada— para no romper consumidores. Migrar una clase sin test de frontera es cambiar un bug conocido por uno desconocido.

**Cadencia**: subir de Xcode al menos con cada línea mayor y **antes** de que App Store Connect lo exija (verificado: el corte de abr-2026 no tuvo periodo de gracia). Cada subida de SDK se prueba en CI contra la anterior: los cambios de comportamiento de framework, no del lenguaje, son lo que rompe.

**Migración de dependencias**: la salida de CocoaPods tiene fecha conocida (2-dic-2026 para trunk). Planificar la migración a SPM/XCFramework **antes** de esa fecha, no después; lo que quede en pods tras ella deja de recibir versiones nuevas por trunk.

**Deuda consciente**: todo atajo deja `// TODO(usuario): motivo — issue #N`. Toda supresión de warning o de analizador va con motivo y fecha de revisión.

**PROHIBIDO** (requiere justificación escrita y aprobación para excepcionar):
- ❌ Escribir un **módulo nuevo** en Objective-C cuando Swift es viable.
- ❌ **Method swizzling** en código de aplicación; swizzle de selectores ajenos, de métodos de UIKit/Foundation, o sin invocar el `IMP` original.
- ❌ **Sobrescribir un método existente desde una categoría**; métodos de categoría sobre clases ajenas **sin prefijo de proyecto**.
- ❌ Cabecera pública **sin `NS_ASSUME_NONNULL_BEGIN`/`END`**, sin generics ligeros en colecciones, o con `id` donde cabe un tipo.
- ❌ `unsafe_unretained` sin justificación; `delegate` declarado `strong`; propiedad de objeto sin semántica explícita; `NSString`/colección pública sin `copy`.
- ❌ Bloque que captura `self` con `strong` estando retenido por `self`; `weakSelf` usado sin promover a `strongSelf` y sin comprobar `nil`.
- ❌ Bucle que crea objetos temporales en volumen **sin `@autoreleasepool`**.
- ❌ `atomic` presentado como sincronización; estado mutable compartido sin cola serie ni lock.
- ❌ **`dispatch_sync` sobre la cola actual** (deadlock); trabajo de UI fuera de la cola principal; I/O de red o disco en la cola principal.
- ❌ Bloque de completado que **no** se invoca exactamente una vez en todos los caminos.
- ❌ `@throw`/`@try` como control de flujo; excepciones ObjC para errores esperables; escribir en `*error` sin comprobar el puntero; leer `*error` sin comprobar antes el retorno.
- ❌ **`+unarchiveObjectWithData:`** y cualquier desarchivado sin `NSSecureCoding` y lista de clases; `NSCoding` sin `NSSecureCoding` en tipos nuevos.
- ❌ Entrada de usuario como **cadena de formato** (`stringWithFormat:`, `NSLog`, `predicateWithFormat:` concatenado).
- ❌ **Secretos en el binario** (claves de API, tokens, client secrets); ofuscación presentada como protección; credenciales en `NSUserDefaults`.
- ❌ Criptografía propia; comparación de secretos con `isEqualToString:`/`memcmp`.
- ❌ `os_log`/`NSLog` con datos de dominio sin `%{private}`.
- ❌ `performSelector:` con firma no trivial pudiendo usar un bloque tipado o un protocolo; KVO sobre objetos cuyo ciclo de vida no controlas.
- ❌ MRR (`-fno-objc-arc`) en código nuevo; `OSSpinLock`.
- ❌ C++ (`std::`) filtrado a cabeceras Objective-C públicas.
- ❌ `+load` para inicialización que puede ser perezosa.
- ❌ Adoptar **Carthage** en un proyecto nuevo; añadir dependencias nuevas **solo** por CocoaPods a sabiendas del corte de trunk.
- ❌ Reformatear masivamente junto a cambios funcionales.

## 8. Verificación web obligatoria

Antes de fijar versiones, fechas o afirmar estado del ecosistema, **verificar por web** (nunca de memoria):
1. **Estado de Objective-C en el toolchain**: notas de versión de Xcode y de Clang de la versión concreta (https://developer.apple.com/documentation/xcode-release-notes). Verificado a ago-2026: **sin evolución de lenguaje, sin deprecación anunciada**; lo que cambia es build/módulos. Si Apple anuncia algo, manda el anuncio.
2. **CocoaPods**: https://blog.cocoapods.org/CocoaPods-Specs-Repo/ — verificado: trunk a solo lectura el **2-dic-2026**, builds existentes siguen funcionando. Confirmar que la fecha no se ha movido y qué proveedores ya dejaron de publicar allí.
3. **Carthage**: `https://github.com/Carthage/Carthage/releases.atom` — verificado: última **0.40.0 (2024-09-09)**.
4. **SPM y targets mixtos**: estado de **SE-0403** en https://github.com/swiftlang/swift-evolution (verificado: *Returned for Revision*). Si se aceptara, cambia el criterio de estructura de paquetes de §2.
5. **Swift Testing vs XCTest**: https://developer.apple.com/documentation/testing y el repo `swiftlang/swift-testing` — verificado: solo Swift; XCTest sigue para ObjC, UI y rendimiento, y **no está deprecado**.
6. **Anotaciones de interoperabilidad** (`NS_SWIFT_SENDABLE`, `NS_SWIFT_UI_ACTOR`, `NS_REFINED_FOR_SWIFT`, `NS_SWIFT_NOTHROW`): disponibilidad y semántica exacta en el SDK de la versión usada — han ido llegando por versiones.
7. **Requisitos de App Store Connect** (SDK y Xcode mínimos, fechas de corte): https://developer.apple.com/news/ — verificado el corte de **28-abr-2026** (iOS 26 SDK, sin periodo de gracia); estas fechas se repiten cada año.
8. **APIs deprecadas de Foundation/Security** antes de citarlas como default: la documentación de Apple marca la deprecación por versión de SO.

**Huecos declarados (no verificados a ago-2026, verificar antes de usar como norma)**:
- Texto verbatim de la deprecación de `+unarchiveObjectWithData:` en la documentación de Apple: **no verificado** (la página no devolvió cuerpo). El criterio —`NSSecureCoding` con lista de clases— se mantiene por sí solo, pero la versión exacta de deprecación no está confirmada aquí.
- Versión exacta de Xcode publicada como estable a ago-2026 y su mapeo a Swift: **parcialmente verificado** (26.6 RC con Swift 6.3, y línea 26.5/Swift 6.3.2 en mayo-2026, según fuentes secundarias; **no contrastado contra developer.apple.com**). Discrepancia de fuentes secundarias en el mapeo Xcode↔Swift: confirmar en https://developer.apple.com/xcode/system-requirements.
- Interacción exacta entre módulos estándar de C++ y Objective-C++ por versión de Xcode y modo `-std=c++`: **no verificado por versión**.
- Comportamiento definido del retorno de métodos con receptor `nil` para tipos struct y de coma flotante en las ABI vigentes de Apple: **no verificado contra especificación**; el criterio (no depender de ello) no cambia.
- Licencias verbatim de las herramientas citadas (`swift-testing`, `clang-format`): **no verificadas verbatim**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
