---
name: objective-c-standards
description: Objective-C and Objective-C++ engineering standards for legacy maintenance and Swift interoperability. Trigger on .m/.mm/.h files with @interface/@implementation/@property, ARC and __weak/__strong/__unsafe_unretained/__bridge, NS_ASSUME_NONNULL_BEGIN and nullable/nonnull annotations, lightweight generics, NS_SWIFT_NAME/NS_REFINED_FOR_SWIFT/NS_SWIFT_SENDABLE, bridging headers and module.modulemap, objc_msgSend, method swizzling, categories, KVO/KVC, NSError** out-parameters, GCD dispatch_queue/dispatch_sync, NSSecureCoding and NSKeyedUnarchiver, Podfile/Podfile.lock, Cartfile, xcodebuild on Objective-C targets, or XCTest suites written in Objective-C.
---

# Objective-C standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the Objective-C and Objective-C++ **language**: `.m`/`.mm` files and headers with `@interface`/`@property`, ARC and property qualifiers, nullability annotations, lightweight generics, the dynamic runtime (`objc_msgSend`, categories, swizzling, KVO/KVC), designing headers **for consumption from Swift**, GCD from Objective-C, tooling (`xcodebuild`, the `clang` analyzer, `clang-format`, sanitizers) and the target's dependency management.

**The real case is maintenance and interoperability, not new code.** For new code on Apple platforms the answer is **Swift**; writing a new module in Objective-C requires written justification (§7). This skill exists for two concrete reasons: (a) there is an enormous amount of Objective-C in production that has to be touched without breaking it, and (b) **the Swift↔Objective-C boundary is where things break** — badly annotated nullability, `id` without generics, retain cycles Swift cannot see, `NSError**` that Swift translates into `throws`, and the dynamic runtime the Swift compiler cannot verify. The axis of this document is: **make the existing Objective-C safe to consume from Swift and safe to delete little by little**.

**Not applicable**: see `mobile-standards` (**the app is theirs**: architecture, navigation, app lifecycle, permissions and `Info.plist`, signing, App Store/TestFlight distribution, accessibility, secure storage as policy, MASVS, crash reporting; and **Swift is theirs** — here only interoperability **from the Objective-C side**: how the header is annotated and designed so Swift can consume it without exploding), `c-standards` and `cpp-standards` (Objective-C is a superset of C and `.mm` mixes in C++: **the C and C++ inside a `.m`/`.mm` remain subject to their skills** — manual memory management, undefined behaviour, integers, warning flags, sanitizers, RAII and the STL; **what is specific to the Objective-C runtime, ARC and the bridge to Swift belongs here**), `assembly-standards` (a `.mm` can contain inline `asm`: the criteria for when and how assembly is written are theirs), `cryptography-pki-standards` (algorithm choice, mode and key lifecycle; here only their use through the platform APIs), `identity-access-management-standards` (OAuth/OIDC flows on the IdP side), `appsec-standards` (threat modelling and process), `cicd-standards` (pipeline design; here only which tool is run), `secrets-management-standards` and `vulnerability-management-standards` (patching SLAs and triage of dependency CVEs), `smalltalk-standards` (**a direct lineage**: Objective-C's message runtime comes from there; living Smalltalk — Pharo, Squeak, GemStone/S, VAST — is theirs).

## 2. Default decisions and toolchain

> **Verify the latest version on the web before pinning it in a real project** (§8). What follows is the status verified as of **August 2026**.

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| Language for new code | **Swift** | Objective-C only if the module must be consumed from existing C/C++, if the dynamic runtime is a genuine requirement, or if the team maintains a public ObjC framework with a stable contract | Verified: Apple **publishes no language changes** to Objective-C; what changes is the module system and the build (e.g. *Explicitly Built Modules* in Xcode 16 for C/ObjC). **No deprecation announced**, but no evolution either: it is a **stable and static** language |
| Toolchain | **Xcode 26.x** (current line; 26.6 RC with Swift 6.3 as of Aug 2026) | The minimum version App Store Connect demands | Verified: since **28 Apr 2026** every upload to App Store Connect requires a build with the iOS 26 SDK or later (Xcode 26+), **with no grace period** |
| ARC | **Mandatory** (`-fobjc-arc`) in every file | MRR (`-fno-objc-arc`) **only** per file and with a written reason (interoperability with very old Core Foundation, generated code) | Manual MRR is a source of leaks and over-releases that no tool compensates for |
| Dependencies | **Swift Package Manager** | A vendored XCFramework with a checksum when the vendor does not publish to SPM | Verified: **the CocoaPods trunk goes read-only on 2 Dec 2026** — *"no new versions or pods will be added to trunk"*, though *"this will keep all existing builds working"* as long as GitHub and jsDelivr exist. That is: current builds keep working, **but there will be no updates and no security patches through trunk**. Migrating is planned work, not a same-day emergency |
| Carthage | **Do not adopt** | Keep existing usage until migrated | Verified through the Atom feed: latest release **0.40.0 (2024-09-09)**. No releases since: not a base for a new project |
| Mixing Swift/ObjC in SPM | **Separate targets** (`FooObjC` clang + `Foo` swift) | Binary target / XCFramework | Verified: **SE-0403 (mixed language targets) is "Returned for Revision"**, not accepted. In SPM **a target is either Swift or C-based, not both**. In an Xcode target they do coexist (bridging header + generated header) |
| Tests | **XCTest** for Objective-C code | **Swift Testing** for new tests written in Swift | Verified: **Swift Testing supports Swift only**; XCTest remains the only path for tests written in Objective-C, UI automation (XCUITest) and performance tests (XCTMetric). XCTest **is not deprecated**. A single test target accepts both worlds, but **each test lives in exactly one** |
| Formatting | `clang-format` with a versioned `.clang-format` | — | `clang-format` understands Objective-C; without a versioned file the style gets re-argued in every PR |

Toolchain rules:
- The project declares its **minimum deployment version** and **compiles with `-Werror` in CI**. The C warning set applies in full (see `c-standards`), plus the Objective-C-specific ones: `-Wobjc-missing-property-synthesis`, `-Wdirect-ivar-access`, `-Wnullable-to-nonnull-conversion`, `-Wstrict-selector-match`, `-Wundeclared-selector`, `-Wdeprecated-implementations`, `-Wobjc-interface-ivars`.
- **`-Wnullable-to-nonnull-conversion` is non-negotiable**: it is the warning that stops Swift receiving a `nil` in a `let x: String` and aborting with a crash that has no useful trace.
- A reproducible build through `xcodebuild` from CI with explicit `-scheme`/`-destination`; no "it builds in my Xcode". Configuration in versioned `.xcconfig` files, not in the project UI.

## 3. The language: lifecycle, the Swift boundary and the runtime

### ARC and lifecycle
- Qualifiers: `strong` (the default for objects), `weak` for back references and delegates, `copy` **mandatory** for `NSString`/`NSArray`/`NSDictionary`/blocks in public properties (the caller can pass the mutable subclass and mutate it behind your back), `assign` only for scalars. **`unsafe_unretained` is vetoed** except for interoperability with an API that requires it, and with a comment: it is not nilled out on release, so it produces a *use-after-free* instead of `nil`.
- **Retain cycles in blocks**: a block captures `self` as `strong`. The mandatory pattern when the block is retained by the object itself (or by something it owns):

```objc
__weak __typeof(self) weakSelf = self;
self.completion = ^{
    __strong __typeof(weakSelf) strongSelf = weakSelf;   // once only, on entry
    if (!strongSelf) { return; }                          // mandatory early exit
    [strongSelf doWork];
};
```
  Without the `strongSelf`, every access to `weakSelf` can become `nil` halfway through the block and the behaviour turns non-deterministic. **Check for `nil` and return**, do not carry on "just in case".
- `delegate` is **always `weak`** (or a documented `unsafe_unretained` if the protocol is not object-based). A `strong` delegate is a guaranteed cycle.
- `@autoreleasepool` is **mandatory** inside loops that create temporary objects in volume (parsing, images, conversions): without it the memory peak grows until the end of the run-loop cycle and the system kills the process.
- Core Foundation: **explicit** ownership transfer with `__bridge`/`__bridge_transfer`/`__bridge_retained` or the `CFBridgingRetain`/`CFBridgingRelease` macros. A bare `__bridge` where `__bridge_transfer` was needed is a leak the analyzer **does** detect: it is not silenced.
- `dealloc`: deregistration only (KVO/`NSNotificationCenter` observers if the lifecycle requires it) and timer invalidation. **No business logic and no calls to overridable methods**; the object is already half destroyed.

### `nil` as a valid receiver — the structural trap
Sending a message to `nil` is legal and returns zero/`nil`/a zeroed struct. Consequence: **an initialisation bug does not fail, it propagates silently** to a distant point where the symptom bears no relation to the cause.
- Do not use a method's return value as proof that the receiver existed. If a `nil` at that point is a programming error, there are `NSParameterAssert`/`NSAssert` (which **disappear with `NS_BLOCK_ASSERTIONS`**, so they are no good for validating external input) or an explicit check.
- Be careful with non-object return types: for a `nil` receiver, returned floating-point values and structs are defined as zero **in Apple's current ABIs**, but depending on that is fragile; check first.

### Properties and `atomic`
- `nonatomic` by default. **`atomic` does not give thread safety**: it guarantees that an individual `get`/`set` does not return a half-written value, nothing more. An `array.count` followed by an indexed access is still a race. Real synchronisation is designed (a serial queue, a lock, immutability), not obtained by writing `atomic`.
- Accessing ivars: **through the property**, not directly (`-Wdirect-ivar-access`), except in `init` and `dealloc`, where direct access is the correct thing (setters can have effects and the object is not in a valid state).
- Every public property has explicitly declared semantics (`nonatomic, copy, readonly`…). No `@property NSString *name;` without qualifiers.

### Nullability and lightweight generics — a requirement for consumption from Swift
This is **not cosmetic**: it decides whether Swift sees `String` or `String!`. An unannotated `id` arrives in Swift as `Any!`, and an implicitly-unwrapped optional that turns out to be `nil` **aborts the process**.
- **Every public header is wrapped** in `NS_ASSUME_NONNULL_BEGIN` / `NS_ASSUME_NONNULL_END`, explicitly marking what can be `nil` with `nullable` (and `null_resettable` where applicable). An unannotated header is debt paid by the consumer.
- **Lightweight generics are mandatory** on exposed collections: `NSArray<NSString *> *`, `NSDictionary<NSString *, NSNumber *> *`. Without them Swift receives `[Any]` and all the typing on the Swift side degrades into casts.
- `instancetype` in constructors, never `id`. `NS_DESIGNATED_INITIALIZER` on the designated initialiser and `NS_UNAVAILABLE` on those that must not be used: without that, Swift inherits initialisers that leave the object invalid.
- Enumerations with `NS_ENUM`/`NS_OPTIONS`, typed strings with `NS_STRING_ENUM`/`NS_TYPED_ENUM`. Never a bare C `enum` in a public API.
- **The annotation is a promise the compiler only partially verifies**: keep `-Wnullable-to-nonnull-conversion` on, and at boundaries receiving external data (JSON, disk, network) **check at runtime** before returning anything declared `nonnull`.

### Designing the header with the Swift consumer in mind
- `NS_SWIFT_NAME` to give the idiomatic Swift name when the automatic translation produces something unreadable.
- `NS_REFINED_FOR_SWIFT` when the Objective-C API cannot be idiomatic (out-params, pointers, boxed `NSNumber`): the symbol is imported with a `__` prefix and wrapped in a Swift extension. **That is the correct route**, not changing the ObjC API to please Swift.
- `NS_NOESCAPE` on non-escaping blocks, `NS_SWIFT_SENDABLE` on types safe to cross isolation and `NS_SWIFT_UI_ACTOR` / `NS_SWIFT_NONISOLATED` where isolation matters — **verify availability and exact semantics in the SDK of the version being used** (§8): these annotations arrived across versions and their effect depends on the target's Swift concurrency mode.
- `NS_ERROR_ENUM` for error domains, so Swift imports them as a typed `Error`.
- `NS_SWIFT_UNAVAILABLE` for what must not cross; `API_AVAILABLE`/`API_DEPRECATED` on every API with a version condition.
- **The module is exposed through `module.modulemap`**, not a bridging header, when it is a consumable framework. The bridging header is for the app's code, and it **does not** exist in the other direction: Swift is seen from ObjC through the generated header (`<Product>-Swift.h`), and **only what is marked `@objc`/`@objcMembers` and inherits from `NSObject`**.

### Categories
- They exist to **add** methods to a class you do not control. Every category method on someone else's class carries a **project prefix** (`px_doThing`): the runtime has no namespaces and two categories declaring the same selector collide silently, with the last loaded winning — an order that is **non-deterministic** between libraries.
- **FORBIDDEN to override an existing method from a category.** The behaviour is undefined and it breaks the base class, other categories and the subclasses. If behaviour needs changing: subclass, composition or delegation.
- Categories with properties: they require *associated objects* (`objc_setAssociatedObject`), which are hidden state with no `dealloc` of their own. Use them sparingly and document them.
- Class extensions (`@interface Foo ()` in the `.m`) are the correct mechanism for private members, including redeclaring a public `readonly` property as `readwrite`.

### Dynamic runtime
- `objc_msgSend` is the dispatch mechanism: **every send is dynamic**, there is no devirtualisation. Practical implication: the compiler can warn you about almost nothing regarding the receiver, so the static typing of the headers is your only net.
- **FORBIDDEN: *method swizzling* in application code** except in a justified, documented case (typically third-party instrumentation, and even then an alternative is preferred). It is a classic source of irreproducible failures: it depends on load order, breaks with every SDK update, and two libraries swizzling the same selector corrupt each other. If it is done anyway: only in `+load` or with `dispatch_once`, on your own selectors, always invoking the original `IMP`, and with a written owner and review date.
- `respondsToSelector:` / `performSelector:` are *escape hatches*, not design. `performSelector:` with more than two arguments or a non-object return is incorrect (ARC does not know the signature and `-Warc-performSelector-leaks` says so). **Default replacement: a typed block or a protocol with `@optional`.**
- `NSInvocation` and hand-written `objc_msgSend`: only in infrastructure code with its own tests; on `arm64` they require casting `objc_msgSend` to the exact signature or the result is garbage.
- **KVO/KVC are fragile**: keys as strings with no compile-time checking, `observeValueForKeyPath:` untyped, and **removing the observer at exactly the right moment** (an observer alive after the observed object's `dealloc` is a guaranteed crash). Criterion: use the token-based API (`-addObserverForKeyPath:…`, which returns `NSKeyValueObservation` in Swift, or store the context and deregister in `dealloc`), prefer notifications or explicit callbacks, and **never KVO on objects whose lifecycle you do not control**. `valueForKey:` with a constructed string is, additionally, attack surface.

### Errors
- Canonical pattern: `- (BOOL)doThing:(NSError **)error` or an object return with `nil` on failure. **The failure indicator is the return value, not `error`**: check the return first and only then read `*error`. Writing to `*error` without checking the pointer is not `NULL` is a crash.
- Swift translates this pattern into `throws` **only if the signature follows the convention** (last parameter `NSError **`, `NS_SWIFT_NOTHROW` to exclude it). Changing the signature breaks the Swift side even though the ObjC compiles.
- **Objective-C exceptions are not control flow**: they represent programming errors (index out of range, unrecognised selector) and **are not safe with ARC** — unwinding the stack with ARC leaks memory except with `-fobjc-arc-exceptions`, which has a cost. `@try/@catch` only to wrap system APIs documented as throwing (some of `NSFileHandle`, KVC) and at the C++ boundary in a `.mm`. **FORBIDDEN**: `@throw` for expected errors.

### Concurrency (GCD from Objective-C)
- Default model: **one serial queue per unit of mutable state**. A serial queue is a lock that also orders; it is cheaper to reason about than `NSLock` scattered around.
- Concurrent queues only with an explicit reader/writer pattern (`dispatch_barrier_async` for writes) and a concurrency test under TSan.
- **FORBIDDEN: `dispatch_sync` onto the main queue from the main queue**: an immediate deadlock. By extension, `dispatch_sync` onto any queue from that same queue. Operational rule: `dispatch_sync` only towards a queue you know for certain is not you, and never while holding another lock.
- All UI work on the main queue; all I/O off it. `dispatch_after` is not a synchronisation mechanism.
- Interop with Swift's `async/await`: an ObjC API with a completion block as the **last** parameter is imported as `async` — the signature is a contract. The block must be called **exactly once** on every path, including the error and cancellation ones: zero calls hang the Swift task forever and two calls are a runtime failure.
- `volatile` does not synchronise (see `c-standards`). For counters, C11 `atomic_*` or `os_unfair_lock`; **`OSSpinLock` is deprecated** because of priority inversion.

### Objective-C++ (`.mm`)
- Used **only** to bridge to an existing C++ library, and it is isolated: the C++ does not leak into public Objective-C headers (a header with `std::` forces every consumer to be `.mm`). Pattern: a clean ObjC header, a `.mm` implementation with a hidden C++ implementation `struct` (pImpl).
- ARC and C++ coexist: an ObjC object as a member of a C++ class needs an explicit `__strong`/`__weak` and the class stops being trivially copyable. `id` inside a `union` or in POD types requires care.
- Exceptions: a C++ exception crossing into an Objective-C frame with ARC leaks resources; catch it at the bridge's edge.
- **The C++ in a `.mm` is subject to `cpp-standards`** (RAII, the STL, UB, flags). Verified: there is a known interaction between C++ standard modules and Objective-C++ depending on the C++ language mode — check the release notes of the specific Xcode version before enabling C++ modules in a `.mm` target (§8).

## 4. Quality: analysis, tests and CI gates

- **Clang Static Analyzer** (`xcodebuild analyze` or *Analyze* in Xcode) is the main gate and it is specifically good at Objective-C: ARC/CF leaks, over-release, `nil` receivers, use of uninitialised values. **Zero findings** in your own tree; a suppression requires a `// NOLINT`-equivalent with a reason, not deleting the warning.
- `clang-tidy` over `compile_commands.json` for the C/C++ inside the `.m`/`.mm` (`bugprone-*`, `cert-*`).
- `clang-format --dry-run --Werror` in CI, with a versioned `.clang-format`. Mass reformatting in a separate commit, recorded in `.git-blame-ignore-revs`.
- Tests: XCTest for the Objective-C code; **the boundary test is mandatory** — for every public API consumed from Swift, a test **written in Swift** that exercises it. It is the only way to check that nullability, generics and the `NSError**` translation are what you think they are.
- Edge coverage: `nil` in every parameter annotated `nullable`, an empty collection, an empty string, boundary values, the completion block invoked on every path, and the error path of every `NSError**`.
- **Sanitizers in Xcode**, in separate schemes: Address Sanitizer (+ *Detect use of stack after return*), Thread Sanitizer and Undefined Behavior Sanitizer. ASan and TSan **are not combined**. Also *Zombie Objects* and *Malloc Scribble* to diagnose over-release in inherited MRR code. Never enabled in a distribution build.
- Instruments: **Leaks** and **Allocations** over the critical flow before releasing a change that touches lifecycle; a retain cycle does not show up in unit tests.
- Minimum CI gate (everything breaks the build): formatting → build with `-Werror` (the warnings in §2) → `xcodebuild analyze` with no findings → ObjC unit tests + Swift boundary tests → tests under ASan+UBSan → dependency SCA/SBOM.

## 5. Stack security

- **`NSKeyedUnarchiver` without an allowed class list is code execution.** **FORBIDDEN: `+unarchiveObjectWithData:`** and the whole unsafe family: deserialising an arbitrary archive instantiates whichever classes the attacker names. The only replacement: `NSSecureCoding` with `+unarchivedObjectOfClass:fromData:error:` / `+unarchivedObjectOfClasses:fromData:error:`, with `requiresSecureCoding = YES` and the **allowed class list as narrow as possible**. Every serialisable class implements `NSSecureCoding` (not just `NSCoding`) and its `+supportsSecureCoding` genuinely returns `YES`, not by copy-paste.
- The same criterion applies to any deserialisation: `NSJSONSerialization` with type validation of every field before use (an `NSDictionary` arriving with an `NSNull` where you expected an `NSString` is an `unrecognized selector` in production). **Never** trust the shape of the JSON.
- **Format strings**: `-Wformat=2 -Werror=format-security` on. **FORBIDDEN** to pass user input as a format string to `+stringWithFormat:`, `NSLog`, `-appendFormat:` or predicates. It is arbitrary memory read/write. The same goes for `NSPredicate predicateWithFormat:` built by concatenation: direct injection; use substitution with `%@`/`%K`.
- On-device storage: **Keychain** for credentials, tokens and keys, with the most restrictive protection class the case allows (`…ThisDeviceOnly` when it must not sync) and with biometric `SecAccessControl` where applicable. **`NSUserDefaults` is not secure storage**: it is a plist in the clear, it is read from a backup and in some scenarios it survives uninstallation. Files with `NSFileProtectionComplete` and `isExcludedFromBackup` where appropriate. The policy of what is stored and with what classification belongs to `mobile-standards`; here, the correct API.
- **A client binary does not keep secrets.** Every embedded string — API keys, tokens, OAuth client secrets, internal URLs, signing credentials — is in the user's hands: `strings` over the `.app` finds it in seconds. Obfuscation is not protection. If an operation requires a secret, it runs on the server. What is protected is what the device **generates** (a key pair in the Secure Enclave, an ephemeral token in the Keychain).
- Crypto: platform APIs (CryptoKit from Swift, `SecKey`/`CommonCrypto` from ObjC). **FORBIDDEN to implement your own cryptography**; compare secrets in constant time, never `memcmp` or `isEqualToString:`.
- Logging: `os_log` with a format string and **redaction of dynamic values by default** (`%{private}@` for everything not explicitly public). `NSLog` with domain objects in a release build is a PII leak into the device's log system.
- Dependencies: exact pinning (version + checksum in `Package.resolved`, a mandatory checksum on `binaryTarget`), an SBOM of the artifact and SCA. **Any pod that stops receiving updates after Dec 2026 becomes security debt with a date**, not a stable dependency.

## 6. Performance and operability

- Dynamic dispatch has a cost, but **it is almost never the bottleneck**: measure with Instruments (Time Profiler) before touching anything. Optimising messages by hand (a cached `IMP`) requires a measured number and a test.
- Memory peaks: `@autoreleasepool` in loops (§3) and `NSCache` instead of `NSMutableDictionary` for caches (it responds to memory pressure). System memory warnings are acted upon.
- Crashes: dSYM archived per build with its UUID; a crash without symbols is wasted time. Unrecognised selectors, `NSInvalidArgumentException` from `nil`, and retain cycles are the three dominant families in Objective-C codebases — they get instrumented and counted.
- Start-up: `+load` runs before `main` and **delays the whole app's launch**; prefer `+initialize` (lazy) or explicit initialisation. A `+load` in a third-party library is a legitimate reason to question the dependency.

## 7. Sustainability and prohibitions

**Strategy, not just style.** The Objective-C in a living codebase is treated as **debt with an amortisation plan**: it gets annotated (nullability and generics) before being touched, covered with tests from Swift, and replaced by Swift **from the inside out** — the internal implementation first, keeping the ObjC header as a facade — so consumers do not break. Migrating a class without a boundary test is trading a known bug for an unknown one.

**Cadence**: move up Xcode at least with every major line and **before** App Store Connect demands it (verified: the Apr 2026 cut-off had no grace period). Every SDK bump is tested in CI against the previous one: framework behaviour changes, not language changes, are what break things.

**Dependency migration**: CocoaPods' exit has a known date (2 Dec 2026 for trunk). Plan the migration to SPM/XCFramework **before** that date, not after; whatever remains in pods after it stops receiving new versions through trunk.

**Conscious debt**: every shortcut leaves `// TODO(user): reason — issue #N`. Every warning or analyzer suppression carries a reason and a review date.

**FORBIDDEN** (an exception requires written justification and approval):
- ❌ Writing a **new module** in Objective-C when Swift is viable.
- ❌ **Method swizzling** in application code; swizzling other people's selectors, UIKit/Foundation methods, or doing it without invoking the original `IMP`.
- ❌ **Overriding an existing method from a category**; category methods on other people's classes **without a project prefix**.
- ❌ A public header **without `NS_ASSUME_NONNULL_BEGIN`/`END`**, without lightweight generics on collections, or with `id` where a type would fit.
- ❌ `unsafe_unretained` without justification; a `delegate` declared `strong`; an object property with no explicit semantics; a public `NSString`/collection without `copy`.
- ❌ A block capturing `self` as `strong` while retained by `self`; `weakSelf` used without promoting to `strongSelf` and without a `nil` check.
- ❌ A loop creating temporary objects in volume **without `@autoreleasepool`**.
- ❌ `atomic` presented as synchronisation; shared mutable state with no serial queue and no lock.
- ❌ **`dispatch_sync` onto the current queue** (deadlock); UI work off the main queue; network or disk I/O on the main queue.
- ❌ A completion block that is **not** invoked exactly once on every path.
- ❌ `@throw`/`@try` as control flow; ObjC exceptions for expected errors; writing to `*error` without checking the pointer; reading `*error` without checking the return value first.
- ❌ **`+unarchiveObjectWithData:`** and any unarchiving without `NSSecureCoding` and a class list; `NSCoding` without `NSSecureCoding` in new types.
- ❌ User input as a **format string** (`stringWithFormat:`, `NSLog`, concatenated `predicateWithFormat:`).
- ❌ **Secrets in the binary** (API keys, tokens, client secrets); obfuscation presented as protection; credentials in `NSUserDefaults`.
- ❌ Home-grown cryptography; comparing secrets with `isEqualToString:`/`memcmp`.
- ❌ `os_log`/`NSLog` with domain data and no `%{private}`.
- ❌ `performSelector:` with a non-trivial signature when a typed block or a protocol would do; KVO on objects whose lifecycle you do not control.
- ❌ MRR (`-fno-objc-arc`) in new code; `OSSpinLock`.
- ❌ C++ (`std::`) leaking into public Objective-C headers.
- ❌ `+load` for initialisation that could be lazy.
- ❌ Adopting **Carthage** in a new project; adding new dependencies **only** through CocoaPods in full knowledge of the trunk cut-off.
- ❌ Mass reformatting alongside functional changes.

## 8. Mandatory web verification

Before pinning versions or dates, or asserting the state of the ecosystem, **verify on the web** (never from memory):
1. **The state of Objective-C in the toolchain**: the release notes for the specific Xcode and Clang version (https://developer.apple.com/documentation/xcode-release-notes). Verified as of Aug 2026: **no language evolution, no deprecation announced**; what changes is build/modules. If Apple announces something, the announcement wins.
2. **CocoaPods**: https://blog.cocoapods.org/CocoaPods-Specs-Repo/ — verified: trunk read-only on **2 Dec 2026**, existing builds keep working. Confirm the date has not moved and which vendors have already stopped publishing there.
3. **Carthage**: `https://github.com/Carthage/Carthage/releases.atom` — verified: latest **0.40.0 (2024-09-09)**.
4. **SPM and mixed targets**: the status of **SE-0403** at https://github.com/swiftlang/swift-evolution (verified: *Returned for Revision*). If it were accepted, the package structure criterion in §2 changes.
5. **Swift Testing versus XCTest**: https://developer.apple.com/documentation/testing and the `swiftlang/swift-testing` repository — verified: Swift only; XCTest remains for ObjC, UI and performance, and **is not deprecated**.
6. **Interoperability annotations** (`NS_SWIFT_SENDABLE`, `NS_SWIFT_UI_ACTOR`, `NS_REFINED_FOR_SWIFT`, `NS_SWIFT_NOTHROW`): availability and exact semantics in the SDK of the version used — they arrived across versions.
7. **App Store Connect requirements** (minimum SDK and Xcode, cut-off dates): https://developer.apple.com/news/ — the **28 Apr 2026** cut-off was verified (iOS 26 SDK, no grace period); these dates recur every year.
8. **Deprecated Foundation/Security APIs** before citing them as a default: Apple's documentation marks the deprecation by OS version.

**Declared gaps (unverified as of Aug 2026, verify before using as a rule)**:
- The verbatim text of the `+unarchiveObjectWithData:` deprecation in Apple's documentation: **not verified** (the page returned no body). The criterion — `NSSecureCoding` with a class list — stands on its own, but the exact deprecation version is not confirmed here.
- The exact Xcode version published as stable as of Aug 2026 and its Swift mapping: **partially verified** (26.6 RC with Swift 6.3, and the 26.5/Swift 6.3.2 line in May 2026, per secondary sources; **not checked against developer.apple.com**). Secondary sources disagree on the Xcode↔Swift mapping: confirm at https://developer.apple.com/xcode/system-requirements.
- The exact interaction between C++ standard modules and Objective-C++ per Xcode version and `-std=c++` mode: **not verified per version**.
- The defined return behaviour of methods with a `nil` receiver for struct and floating-point types in Apple's current ABIs: **not verified against the specification**; the criterion (do not depend on it) does not change.
- Verbatim licences of the tools cited (`swift-testing`, `clang-format`): **not verified verbatim**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
