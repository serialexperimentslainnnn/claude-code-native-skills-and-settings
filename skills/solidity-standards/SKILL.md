---
name: solidity-standards
description: Solidity and EVM smart contract engineering standards. Trigger on .sol files, foundry.toml, remappings.txt, hardhat.config.ts, .solhint.json, forge/cast/anvil/foundryup, solc pragma and evm_version, OpenZeppelin Contracts and openzeppelin-upgrades, ERC-20/721/1155/4626/4337, EIP-712 and EIP-7702, UUPS/Transparent/Beacon proxies, reentrancy, oracle and flash-loan issues, invariant and fuzz tests, Slither, Echidna, Medusa, halmos, kontrol, Certora, SMTChecker, gas optimization, or pre-deployment audit and incident-response gates.
---

# Estándares de Solidity y contratos EVM

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Premisa que gobierna todo lo demás**: el código desplegado es **inmutable, público y maneja valor directamente**. No hay *hotfix*, no hay rollback, no hay "lo arreglamos en el siguiente sprint", y el atacante está **incentivado económicamente en tiempo real** — lee tu bytecode, tu mempool y tu commit antes de que despliegues. Eso reordena el cálculo de coste de todo el catálogo: **un test que falta no es una regresión potencial, es una pérdida irreversible**; una revisión que se salta no retrasa una release, financia a un tercero. Aquí el gasto en verificación previa no se justifica por ROI, se justifica porque **no existe la fase de corrección posterior**.

Corolario operativo: en este dominio el trabajo caro va **antes** del despliegue (invariantes, verificación formal, auditoría, plan de incidente), no después (monitorización, parcheo). Invertir ese orden es el error estructural del dominio.

Aplica a: ficheros `.sol`, `foundry.toml`, `remappings.txt`, `hardhat.config.ts`, `.solhint.json`, `slither.config.json`, scripts de despliegue `forge script`, tests `*.t.sol`, y a toda revisión de contratos sobre **EVM** (Ethereum L1, L2 tipo OP Stack / Arbitrum / zkEVM y cadenas compatibles).

**No aplica**: ver `appsec-standards` (**metodología de AppSec**: STRIDE, abuse cases, triaje de hallazgos, elección y calibrado de SAST/DAST, ASVS — aquí las **clases de vulnerabilidad específicas de contratos** y el criterio de código que las hace imposibles), `cryptography-pki-standards` (**elección de algoritmo y curva, ciclo de vida y custodia de claves** — aquí solo el **uso correcto de las primitivas que ya expone la cadena**: verificación de firma, EIP-712, `ecrecover` y su trampa de maleabilidad), `secrets-management-standards` (**la custodia de la clave privada de despliegue y de la clave de `owner`/`upgrader` es suya** —HSM, multifirma, rotación, aprobaciones—; aquí solo la exigencia dura de que **no sea una única clave caliente**), `typescript-standards` (los scripts de despliegue y los tests en TS/JS de Hardhat con `viem`/`ethers`: **el lenguaje y su tooling son suyos**; el contrato y sus invariantes, de aquí), `rust-standards` (**contratos en cadenas no-EVM** —Solana, CosmWasm, Arbitrum Stylus— y las herramientas escritas en Rust: **esta skill es de Solidity y de la EVM y no reclama nada fuera de ahí**), `cicd-standards` (pipeline, runners, OIDC y firma de artefactos; **aquí el gate específico: no se despliega sin tests invariantes verdes, sin auditoría externa cerrada y sin plan de incidente escrito**), `vulnerability-management-standards` (triaje y SLA de CVEs de dependencias y del tooling), `offensive-security-standards` (**pruebas ofensivas con alcance y autorización por escrito**; esta skill es **defensiva**: describe clases de vulnerabilidad **para prevenirlas** — ver la prohibición de §7), `incident-response-forensics-standards` (gestión del incidente real, trazado de fondos, coordinación con exchanges y fuerzas de seguridad; aquí solo el **plan y los mecanismos en cadena** que deben existir antes), `grc-compliance-standards` (**el marco regulatorio** —MiCA en la UE, obligaciones de prevención de blanqueo, sanciones—; aquí no se emite criterio legal), `observability-standards` (plataforma de telemetría, alertas y SLOs; aquí **qué evento emitir y por qué**), `api-design-standards` (el contrato de una API HTTP/gRPC; **el ABI de un contrato desplegado también es un contrato público — y además inmutable**: romperlo no es un *major bump*, es una migración con coste de red).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Datos de ago-2026: caducan rápido.

| Ámbito | Default | Motivo / alternativa justificable |
|---|---|---|
| Compilador | **solc 0.8.36** (2026-07-09). Repo: **`argotorg/solidity`** (Argot Collective), ya **no** `ethereum/solidity` | El repo se movió de la Ethereum Foundation a Argot Collective; los enlaces viejos redirigen. **Actualizar remotos, CI y docs** |
| `pragma` en contratos desplegables | **`pragma solidity 0.8.36;` — versión exacta, sin `^` ni rangos** | El bytecode desplegado es irrepetible: un `^` hace que el binario dependa de qué solc tuviera la máquina que compiló. Rompe la **verificación reproducible** en Etherscan/Sourcify, cambia el gas y expone a bugs de codegen no auditados. `^` solo en **librerías publicadas** para no fragmentar a los consumidores |
| `evm_version` | **Fijar explícitamente**. Default del compilador desde 0.8.31: **`osaka`**. `amsterdam` soportado desde 0.8.36 pero **no** es default | Un L2 suele ir por detrás del L1: compilar con opcodes que la cadena destino no implementa despliega un contrato **inutilizable e inmutable**. Verificar el hard fork soportado por la cadena destino antes de cada despliegue |
| Framework | **Foundry** (`forge`/`cast`/`anvil`/`chisel`), última tag **v1.7.1**; `master` en 1.8.0 | Tests, *fuzzing* e invariantes en Solidity, sin cambio de lenguaje ni de modelo mental entre contrato y test; ejecución nativa. **Hardhat 3 es alternativa legítima, no un residuo**: v3.12.0 (2026-07-30), runtime EDR en Rust, tests en Solidity de primera clase y simulación multi-cadena. Criterio: **Foundry por defecto**; Hardhat 3 si el proyecto vive de scripting TS, plugins e integraciones (verificación, Ignition) o el equipo ya lo opera. **Convivir con ambos es normal y no es deuda** |
| Pin de Foundry | **Versión exacta en CI** (`foundryup --install v1.7.1`), no el canal `stable` ni `nightly` | Ver discrepancia en §8: la página del tag rodante `stable` mostraba v1.5.1 mientras el listado de tags iba por v1.7.1. `nightly` cambia la salida de `forge fmt` y rompe CI |
| Librería base | **OpenZeppelin Contracts 5.7.0** (2026-07-29), **MIT** (`LICENSE` en crudo: *"The MIT License (MIT) / Copyright (c) 2016-2026 Zeppelin Group Ltd"*) | No se reimplementa ERC-20/721/1155/4626, `AccessControl`, `ReentrancyGuard` ni proxies. Política: **una sola versión menor fijada en `remappings.txt` + lockfile**, subida deliberada leyendo el CHANGELOG (5.7.0 trae *breaking changes* en dominio EIP-712 y en nombres de error de governance) |
| Actualizabilidad | **`openzeppelin-foundry-upgrades` / `openzeppelin-upgrades`** con validación automática de compatibilidad de *storage* | Soportan UUPS, Transparent y Beacon; **no soportan Diamond (EIP-2535)** — elegir Diamond es asumir la validación de *storage* a mano |
| Lint / formato | **`forge fmt`** + **`solhint` 6.2.3** (2026-06-19) | `forge fmt --check` y `solhint` como gates de CI |
| Análisis estático | **Slither 0.11.6** (2026-07-29), **AGPL-3.0** | Activo, con soporte de Hardhat v3 y Sourcify. AGPL: irrelevante para uso interno en CI, **relevante si lo integras en un SaaS** |
| Fuzzing de propiedades | **`forge test` (fuzz + invariant)** como base; **Echidna 2.3.3** (2026-07-27, AGPL-3.0) y **Medusa 1.5.1** (2026-03-11, AGPL-3.0) para campañas largas | Escribir el *harness* de invariantes de forma reutilizable entre motores (patrón Chimera) evita reescribirlo por herramienta |
| Verificación formal | **SMTChecker** (integrado en solc, sin coste de adopción) → **`halmos`** o **`kontrol`** → **Certora Prover** para lo crítico | `kontrol` **BSD-3-Clause**, v1.0.255 (2026-06-24), activo. **Certora Prover open source desde feb-2025, GPL-3.0** (`LICENSE`: *"GNU GENERAL PUBLIC LICENSE / Version 3, 29 June 2007"*), auto-hospedable gratis; la nube es de pago. **`halmos` AGPL-3.0 pero sin release desde v0.3.3 (2025-07-31) y sin commits en `main` desde ago-2025**: verificar su estado antes de meterlo en un gate de CI |
| Análisis simbólico legacy | **Mythril: no como gate** | MIT, pero **último release v0.24.8 en 2024-03-27**. Sin mantenimiento efectivo: usarlo como confirmación puntual, nunca como control |

## 3. Estructura y convenciones

Layout de referencia (Foundry):

```
src/            # contratos de producción. Un contrato por fichero, nombre == fichero
  interfaces/   # IFoo.sol — el ABI es contrato público: se diseña, no se deriva
  libraries/
test/           # *.t.sol unitarios y de integración
  invariant/    # handlers + invariantes (obligatorio, §4)
script/         # forge script de despliegue y de upgrade — versionados y revisados
lib/            # dependencias como submódulos (forge install)
foundry.toml
remappings.txt  # explícito y versionado: nada de resolución implícita
```

- **`remappings.txt` explícito y versionado**. La resolución implícita hace que dos máquinas compilen árboles distintos; con bytecode inmutable eso es inaceptable.
- **Dependencias inmovilizadas a *commit*, no a rama**: submódulos con SHA fijado (o lockfile del gestor de paquetes). Un `lib/` apuntando a `master` es una dependencia que cambia sola bajo un artefacto que no puede cambiar.
- **NatSpec obligatorio** en todo `external`/`public` y en todo evento y error personalizado: `@notice` (qué hace, para el usuario que firma), `@param`, `@return`, `@dev` para invariantes y supuestos. La NatSpec alimenta la firma legible de wallets: **sin ella el usuario firma a ciegas**. `@custom:oz-upgrades-from` donde el plugin de upgrades lo exija.
- **Errores personalizados** (`error Foo(uint256 x);` + `revert`) en lugar de `require` con string: más baratos y **tipados**, lo que hace el fallo distinguible desde el cliente. Cada `revert` debe decir *qué* condición falló.
- **Convenciones**: `CamelCase` para contratos y structs, `mixedCase` para funciones y variables, `SCREAMING_SNAKE` para `constant`/`immutable`, prefijo `_` para internas/privadas. Orden de miembros: tipos, constantes, `immutable`, *storage*, eventos, errores, modificadores, constructor, `external`, `public`, `internal`, `private`.
- **Unidades explícitas en el nombre**: `amountWad`, `feeBps`, `deadlineTs`. Los errores de precisión de §5 empiezan por variables sin unidad.
- **Interfaces sobre implementaciones** en toda integración externa; nunca casts a un contrato ajeno asumiendo su forma.

`foundry.toml` de referencia — **lo que aquí se decide es reproducibilidad y profundidad de las campañas de test**, no comodidad:

```toml
[profile.default]
solc_version = "0.8.36"        # exacta: el binario debe ser reproducible por terceros
evm_version = "prague"         # el de la cadena DESTINO, no el default del compilador
optimizer = true
optimizer_runs = 200           # menos runs = menos código; medir, no copiar
bytecode_hash = "ipfs"         # metadata coherente para verificar en Sourcify/Etherscan
deny_warnings = true           # un warning del compilador en un artefacto inmutable es un bug
fs_permissions = []            # sin acceso a disco por defecto; abrir por ruta y solo lo necesario

[fuzz]
runs = 10_000                  # PR: suficiente para atrapar lo evidente
[invariant]
runs = 256
depth = 500                    # profundidad = nº de llamadas por secuencia; lo que encuentra bugs
fail_on_revert = false         # con handlers acotados, subir a true y arreglar los revert espurios

[profile.ci.fuzz]
runs = 100_000                 # nightly: campaña larga, no en cada PR
```

## 4. Calidad y testing

**Ningún nivel de esta lista es opcional en un contrato que va a custodiar valor.** El orden es de coste creciente; el gate de despliegue exige todos.

### 4.1 Unitarios
`forge test` con cobertura explícita de **camino feliz, bordes y errores**: cada `revert` tiene un test que lo provoca (`vm.expectRevert(Foo.selector)`), cada evento uno que lo verifica (`vm.expectEmit`), cada rama de control de acceso uno por rol y uno por actor no autorizado. Un `require` sin test que lo dispare es una rama no verificada del binario inmutable.

### 4.2 Fuzzing de propiedades y tests invariantes — **práctica esperada, no opcional**
- **Fuzz por función** (`function testFuzz_x(uint256 amount)`) para toda función que acepte cantidades, con `vm.assume`/`bound` en lugar de descartar en masa.
- **Invariantes *stateful***: las propiedades que deben cumplirse **tras cualquier secuencia de llamadas de cualquier actor** — solvencia (`sum(balances) <= totalAssets`), monotonía de índices, conservación de valor, que ninguna operación permitida deje al protocolo insolvente. Se escriben con **handlers acotados** (el *fuzzer* sin guía dispara casi todo a `revert` y la campaña no prueba nada).
- Campañas largas fuera del PR (nightly) con **Echidna** o **Medusa** sobre el mismo *harness*; el corpus de entradas se versiona.
- **Un invariante roto en CI bloquea el merge.** Toda corrección de bug deja además su test de regresión.

### 4.3 Verificación formal
Escalada por criticidad: **SMTChecker** de solc (gratis, empezar por ahí) → **`halmos`** (tests simbólicos con la misma sintaxis que los de Foundry) o **`kontrol`** → **Certora Prover** con especificaciones CVL para el núcleo económico. Qué garantiza: que la propiedad **especificada** se cumple para todas las entradas dentro del modelo. Qué no: que la propiedad especificada sea la correcta, ni nada fuera del modelo (*gas*, interacción con contratos externos no modelados, incentivos económicos). **Un `UNKNOWN` por *timeout* del SMT no es una prueba**: tratarlo como fallo.

### 4.4 *Forking* y simulación
Tests contra estado real de la red (`vm.createSelectFork` a un bloque **fijado**, no "el último": los tests deben ser deterministas) para toda integración con protocolos de terceros, oráculos y tokens reales. Simular el despliegue y **el upgrade** completos en fork antes de ejecutarlos.

### 4.5 Cobertura
`forge coverage` como **señal, no meta**. El 100 % de líneas con cero invariantes es peor que el 80 % con invariantes buenos. Lo que se mide en serio: ramas de error cubiertas y propiedades formuladas.

### 4.6 Auditoría externa — gate previo al despliegue
Obligatoria antes del primer despliegue con valor real y antes de todo upgrade que toque lógica de custodia o contabilidad.
- **Qué garantiza**: que un equipo independiente con incentivo reputacional revisó **un commit concreto**, en **un alcance concreto**, durante **un tiempo concreto**, y no encontró más de lo que reporta.
- **Qué NO garantiza**: que el contrato sea seguro. No cubre lo que quedó fuera de alcance, ni cambios posteriores al commit auditado, ni el diseño económico, ni la gobernanza de las claves, ni las dependencias externas. **"Auditado" no es un atributo del protocolo, es un evento fechado sobre un hash.**
- Requisitos de proceso: alcance y commit fijados por escrito, **el informe se publica** (incluidos los hallazgos no corregidos y el motivo), toda corrección se re-verifica, y el informe se referencia con el hash desplegado. Dos auditorías independientes para lo que custodie valor significativo; un contest público (*audit contest*) **complementa**, no sustituye.

### 4.7 Recompensas por vulnerabilidad y respuesta a incidente
- Programa de *bug bounty* **antes** del despliegue, con alcance, escala de recompensa proporcional al valor en riesgo y *safe harbor* explícito. Un canal de contacto que nadie lee es el motivo por el que un investigador honesto se convierte en otra cosa.
- **Plan de respuesta a incidente en cadena, escrito y ensayado ANTES del despliegue** — es un requisito de despliegue, no documentación posterior. Debe fijar: quién puede **pausar** y con qué mecanismo (y qué queda pausado y qué no); qué protege el **timelock** y cuál es su ventana; el *war room* (quién, cómo se convoca, canal fuera de banda); el contacto preparado con exchanges y con proveedores de seguridad y análisis de cadena; los criterios de comunicación pública; y el procedimiento de recuperación o migración. **Ensayarlo en testnet**: un `pause()` que nadie ha ejecutado nunca no es un control.
- Contradicción a resolver por diseño, no a ignorar: **el mismo `pause` que salva el protocolo es una centralización explotable**. Se documenta quién la tiene y bajo qué gobernanza (§5.3).

### 4.8 Gate de CI (rompe el build, en orden de coste)
```
forge fmt --check
solhint 'src/**/*.sol'
forge build --sizes            # límite de tamaño de código desplegado
forge test -vvv                # unitarios + fuzz
forge test --match-path 'test/invariant/*'
slither . --fail-high --fail-medium
forge coverage --report summary
# nightly: campaña de Echidna/Medusa + verificación formal
```
Además, **gate de despliegue** (no de merge): invariantes verdes + auditoría cerrada + plan de incidente firmado + despliegue reproducible verificado en el explorador (Sourcify/Etherscan) con el mismo solc, `evm_version` y *metadata*.

## 5. Seguridad — el núcleo

### 5.1 Reentrada
- **Checks-Effects-Interactions es la base y sigue siéndolo**: validar, **escribir el estado**, y solo entonces llamar fuera. La mayoría de reentradas son estado escrito después de la llamada externa.
- CEI **más** un guard (`ReentrancyGuard`, o su variante con *transient storage* si la cadena destino soporta EIP-1153 — verificar §2 `evm_version`). Cinturón y tirantes: el guard cubre lo que el refactor futuro rompa.
- Toda llamada externa es **transferencia de control**: `token.transfer` a un contrato, un *callback* ERC-777/ERC-721 `onERC721Received`/ERC-1155, `msg.sender.call{value:}`. Enumerarlas explícitamente en la revisión.
- **Reentrada entre funciones y entre contratos**: el guard por función no protege si dos funciones distintas tocan el mismo estado. El guard va sobre el **estado compartido**, no sobre la función de moda.
- **Reentrada de solo lectura (*read-only reentrancy*)** — la sutil y la menos conocida: durante la llamada externa el estado del protocolo es **temporalmente inconsistente**, y una función `view` (un precio, un `totalSupply`, un ratio) leída **por un tercero** en ese instante devuelve un valor falso. El guard clásico no la cubre porque la función `view` no muta nada. Criterio: **las funciones `view` que otros protocolos consumen como fuente de verdad deben respetar el mismo guard** (o exponer un lector que revierta si el guard está tomado), y **jamás integrar leyendo un `view` de un tercero sin comprobar cómo se comporta a mitad de una llamada**.

### 5.2 Control de acceso e inicialización
- Toda función que muta estado sensible declara su autorización explícitamente. `Ownable` solo para lo trivial; **`AccessControl` con roles separados** (pausador ≠ actualizador ≠ tesorería) por defecto. Menor privilegio también en cadena.
- **`tx.origin` PROHIBIDO para autorización** — sin excepciones. Autoriza al humano, no al contrato que llama, y cualquier contrato intermedio con el que la víctima interactúe hereda sus permisos. (Además, EIP-7702 vuelve la distinción EOA/contrato aún menos fiable: `msg.sender.code.length == 0` ya no significa "es una persona".)
- **Contratos de implementación sin inicializar**: un contrato lógico detrás de un proxy **debe** deshabilitar su inicializador en el constructor (`_disableInitializers()`); si no, cualquiera lo inicializa, se hace `owner` de la implementación y —si la implementación tiene un `delegatecall` o un `selfdestruct` alcanzable— puede dejar el proxy inservible de forma permanente.
- Cambios de propiedad en **dos pasos** (`Ownable2Step`): una transferencia a una dirección equivocada es irreversible.
- **`delegatecall`** ejecuta código ajeno **sobre tu propio *storage*, tu balance y tu identidad**. Solo hacia direcciones inmutables o gobernadas por el mismo modelo de confianza; nunca hacia una dirección parametrizable por el llamante.

### 5.3 Proxies y actualizabilidad
- Elección: **UUPS** por defecto (lógica de upgrade en la implementación, proxy más barato) — **con la trampa asumida**: si un upgrade despliega una implementación sin la lógica de upgrade, la actualizabilidad se pierde **para siempre**. **Transparent** cuando se prefiera separar el admin del flujo de llamada. **Beacon** cuando muchas instancias deben actualizarse atómicamente. **Diamond (EIP-2535)** solo con justificación escrita: los plugins de OZ no validan su *storage*.
- **Colisión de *storage***: el layout es un contrato entre versiones. Nunca reordenar, insertar en medio ni cambiar el tipo de una variable existente; solo **añadir al final**. Usar la validación automática del plugin de upgrades como gate, `__gap` (o *namespaced storage*, ERC-7201) en contratos heredables. **Simular todo upgrade sobre un fork del estado real** antes de ejecutarlo.
- **Un contrato actualizable no elimina el riesgo: lo traslada íntegro a quien tiene la llave.** La gobernanza de esa llave **es parte del modelo de amenazas** y se documenta con el contrato: multifirma con umbral y firmantes independientes (una sola clave caliente es **PROHIBIDO**, ver `secrets-management-standards`), **timelock** con ventana suficiente para que un usuario pueda salir antes de que el cambio surta efecto, y un camino declarado hacia la inmutabilidad o hacia gobernanza descentralizada. **Un protocolo "descentralizado" con un `upgradeTo` tras una clave individual es un custodio que no lo dice.**

### 5.4 Oráculos y manipulación de precio
- **El precio *spot* de un AMM no es un oráculo.** Es el estado instantáneo de una reserva que cualquiera puede mover dentro de la misma transacción. Leerlo para valorar colateral es la vulnerabilidad, no un detalle de implementación.
- **TWAP** eleva el coste del ataque pero no lo elimina: su seguridad depende de la **liquidez** del par y de la ventana; en un mercado poco profundo o en un L2 con secuenciador único es manipulable. Elegir ventana con el coste de manipulación calculado, no por costumbre.
- **Oráculos firmados / push** (feeds de proveedor): validar **frescura** (rechazar dato viejo), **desviación** máxima frente a la lectura anterior, y el **caso de que el feed no responda** — un oráculo caído debe pausar o degradar, nunca devolver el último valor en silencio. Comprobar el número de decimales del feed, que **no** tiene por qué coincidir con el del token.
- Ratios de vaults tokenizados (ERC-4626) y `totalSupply`/`balanceOf` de terceros: **cualquier `view` de otro protocolo es un oráculo si lo usas para decidir**, con todos los riesgos de §5.1.

### 5.5 Préstamos relámpago (*flash loans*)
No son una vulnerabilidad: son un **amplificador de capital que convierte cualquier fallo económico en explotable a escala máxima y sin capital previo**. Criterio de diseño: **asumir que el atacante dispone de capital ilimitado durante una transacción**. Toda lógica que dependa de saldos, votos, precios o proporciones **medidos en el instante** debe usar valores con retardo o *snapshot* de bloque anterior. Bloquear "contratos" o comprobar `msg.sender == tx.origin` **no es una mitigación** (y rompe multifirmas y cuentas inteligentes).

### 5.6 Aritmética y precisión
- 0.8.x revierte en overflow/underflow por defecto: `unchecked` solo con la cota demostrada en comentario y con test de borde.
- **Multiplicar antes de dividir**; toda división trunca. Usar librerías de punto fijo (`mulDiv`) para no perder precisión ni desbordar en el intermedio.
- **Redondear siempre a favor del protocolo** (al alza en lo que el usuario paga o debe, a la baja en lo que recibe). El redondeo "neutro" es el vector de los ataques de erosión por repetición.
- **Ataque de inflación del primer depositante** en vaults: el primer *share* se manipula por donación directa. Mitigar con *dead shares*, offset virtual o un depósito inicial del propio protocolo.
- **Decimales distintos entre tokens** (6 de USDC frente a 18 de la mayoría, y tokens con decimales arbitrarios): normalizar en el borde de entrada, nunca asumir 18. `decimals()` es opcional en ERC-20 y puede mentir.

### 5.7 Aleatoriedad y front-running
- **Aleatoriedad en cadena PROHIBIDA**: `block.timestamp`, `blockhash`, `block.prevrandao`, `block.difficulty`, hashes de estado — todo es conocido, predecible o influenciable por quien construye el bloque, que es exactamente quien tiene el incentivo. En su lugar: **VRF verificable** de un proveedor, o **commit-reveal** con ventana temporal y penalización por no revelar. El validador **puede** revertir la transacción que no le conviene: ningún esquema de una sola transacción es seguro.
- **MEV y *front-running***: la mempool es pública; el orden de las transacciones lo decide un tercero con incentivo económico. Todo intercambio o liquidación expone parámetros de **deslizamiento (`minAmountOut`) y `deadline` obligatorios y decididos por el usuario** — un `minAmountOut = 0` o un `deadline = block.timestamp` son un cheque en blanco. Vetar patrones susceptibles de *sandwich*; usar commit-reveal o envío privado donde el valor lo justifique.
- **Aprobaciones ERC-20**: la carrera clásica de `approve`. Usar `increase/decreaseAllowance` o `permit`; **PROHIBIDO** exigir aprobación infinita cuando basta la cantidad exacta.

### 5.8 Tokens que no cumplen el estándar
El ERC-20 real es un desastre heterogéneo. Asumir por defecto:
- **Retorno ausente o no booleano** (USDT y otros): usar `SafeERC20` siempre; comprobar un `bool` que no existe hace revertir.
- **Comisión en transferencia** y **rebasing**: nunca asumir que recibes lo que enviaste — **medir el balance antes y después**, o rechazar explícitamente esos tokens con una lista permitida.
- **Doble punto de entrada** (dos direcciones que controlan el mismo saldo): rompe cualquier control basado en la dirección del token.
- **Callbacks** (ERC-777, ERC-721/1155 `onReceived`): reentrada por la puerta de atrás.
- Criterio: **lista de tokens permitida y revisada** en protocolos que aceptan colateral. "Cualquier ERC-20" es una superficie de ataque abierta a que el atacante despliegue el token.

### 5.9 Denegación de servicio
- **Bucles no acotados** sobre arrays que un tercero puede hacer crecer: llega el día en que la función supera el gas del bloque y **queda inaccesible para siempre**. Todo array iterable debe tener cota, o iterarse por páginas.
- **Push frente a pull**: nunca enviar fondos en bucle a N destinatarios. Un receptor que revierte (contrato sin `receive`, o malicioso a propósito) bloquea al resto. **Patrón *pull*: el beneficiario retira.**
- Dependencia de una llamada externa que puede revertir dentro de una función crítica (liquidaciones, cierre de posición): aislarla o hacerla tolerante al fallo.
- ***Gas griefing* y la regla 63/64**: un `call` reenvía como máximo 63/64 del gas restante, así que **el llamante puede elegir cuánto gas deja** para que la subllamada falle mientras la transacción externa parece exitosa. En funciones críticas: comprobar el resultado del `call`, no tragarse el fallo, y exigir un mínimo de gas si la subllamada debe completarse. Nunca envolver una llamada externa en `try/catch` y continuar como si nada.

### 5.10 Ciclo de vida del contrato
- **`selfdestruct` está deprecado**: desde EIP-6780 (Dencun, 2024) solo destruye realmente el contrato si se ejecuta **en la misma transacción en que se creó**; en cualquier otro caso se limita a enviar todo el ether al destinatario. Todo diseño que dependa de "borrar el contrato" está roto. **PROHIBIDO** en contratos nuevos.
- **`CREATE2` y direcciones predecibles**: la dirección depende de `(deployer, salt, initcode)`. Dos consecuencias: se puede depositar en una dirección **antes** de que exista contrato (contrafactual), y el cambio de semántica de `selfdestruct` altera las viejas suposiciones sobre re-creación en la misma dirección (contratos metamórficos). Fijar `salt` de forma que no lo controle un tercero, y **nunca** asumir que una dirección sin código lo seguirá estando.
- **`address.code.length == 0` no significa "es una persona"**: es falso durante el constructor y, con EIP-7702, también para EOAs con código delegado. No usarlo como control de acceso.

### 5.11 Firmas
- **EIP-712** para todo dato firmado por un usuario: separador de dominio con **`chainId`, `verifyingContract`, `name` y `version`**. Sin `chainId` la firma es reutilizable en otra cadena (y en cualquier fork); sin `verifyingContract`, en otro contrato.
- **`nonce` por firmante y `deadline` obligatorios**. Sin nonce, *replay* dentro de la misma cadena; sin deadline, una firma vive para siempre.
- **Maleabilidad de `ecrecover`**: acepta el par `(s, n-s)` — dos firmas válidas distintas para el mismo mensaje. Y devuelve `address(0)` en fallo en lugar de revertir: **comparar contra `address(0)` no es opcional**. Usar `ECDSA` de OpenZeppelin (fuerza `s` en el rango bajo y revierte) en lugar de `ecrecover` a pelo. **Nunca usar el hash de la firma como identificador único** — es maleable; el identificador es el nonce.
- **Curvas distintas de secp256k1**: desde Fusaka existe el precompilado **secp256r1 (P-256, EIP-7951)**, que hace viable verificar en cadena firmas de passkeys y de enclaves seguros. Usar el precompilado, **nunca** una implementación en Solidity de la curva. (La elección de curva y el ciclo de vida de esas claves es de `cryptography-pki-standards`.)
- **Cuentas inteligentes**: verificar con **EIP-1271** (`isValidSignature`) además de ECDSA. Con **EIP-7702** en mainnet desde Pectra (2025-05-07), una EOA puede tener código delegado: cualquier lógica que asuma que `msg.sender` sin código es una persona está rota.
- `permit` (EIP-2612): mejora la UX pero introduce una firma más que hay que acotar con deadline y nonce; y **no todos los tokens lo implementan** (comprobar, con camino alternativo).

### 5.12 Puentes entre cadenas (*bridges*)
Categoría con mayores pérdidas históricas acumuladas y **la que peor tolera un error de diseño**: no hay consenso compartido entre las dos cadenas, así que la seguridad recae en un conjunto de firmantes, en una prueba, o en un verificador — y ese componente es el objetivo. Criterio: **no se escribe un puente propio**; si es inevitable, el modelo de confianza se documenta explícitamente (quién puede acuñar en destino y con qué prueba), la verificación de mensajes valida **origen, destino, nonce y unicidad**, y el conjunto de firmantes se somete a las reglas de §5.3. Cifras (§8, verificar antes de citar): DefiLlama sitúa las pérdidas acumuladas por explotación en **más de 16 500 M USD**, de los que ~7 700 M son DeFi; la cifra de puentes aparece como **2 900 M USD** en un informe y como **3 304 M USD** en la propia página de DefiLlama — **discrepancia declarada**, verificar en la fuente antes de usarla. Dos datos que corrigen la intuición del dominio: **el compromiso de claves privadas supera el 25 % de los robos y aparece en cuatro de los diez mayores**, por encima de cualquier clase de bug de contrato; y el mayor incidente registrado (Bybit, feb-2025) **no fue un fallo de Solidity**, sino de firma y de la interfaz que la aprobó. Escribir un contrato perfecto y custodiar mal la clave es el modo de fallo dominante.

## 6. Gas y operabilidad

- **El gas es un requisito funcional, no una optimización**: una función que supera el gas del bloque no es lenta, es **inalcanzable para siempre**. Presupuesto de gas por función crítica, medido (`forge test --gas-report`, *snapshots* en CI que fallan ante regresiones) y **verificado en la cadena destino**, no solo en L1.
- **`storage` es el coste dominante**: leer y escribir en almacenamiento persistente domina cualquier micro-optimización de cálculo. Cachear en `memory` dentro de la función; empaquetar variables que se leen juntas en la misma ranura de 32 bytes (y **no** empaquetar las que no, o se paga la máscara sin beneficio). `immutable`/`constant` para lo que no cambia. *Transient storage* (EIP-1153) para estado que vive dentro de una transacción — verificar soporte en la cadena destino.
- **Los eventos son la telemetría de un contrato**: no hay `stdout`, no hay agente, no hay *sidecar*. **Sin eventos no hay operación posible** — ni monitorización, ni reconstrucción del estado, ni detección de un ataque en curso, ni indexado. Regla: **toda transición de estado relevante emite un evento**, con los campos por los que hay que filtrar como `indexed` (máximo 3), incluyendo actor y cantidad. Emitir **después** de escribir el estado. Y a la inversa: eventos que nadie consume son coste puro — cada uno debe tener un consumidor declarado (indexador, alerta, contabilidad).
- **Alertas mínimas en producción**: cambios de rol y de propiedad, ejecución y encolado en el timelock, `pause`/`unpause`, upgrades, y umbrales económicos (retiradas anómalas, desviación del oráculo, caída de colateralización). Con un destinatario de guardia real.
- **Límite de tamaño de código desplegado**: sigue siendo el de **EIP-170 (24 KiB)**. EIP-7907 (subida del límite y medición del coste de cargar código) **fue retirado de Fusaka** en ACDE #216 y podría reconsiderarse para Glamsterdam: **no diseñar contando con más espacio**. `forge build --sizes` en CI; si se roza, el problema es de diseño (partir en librerías o módulos), no de flags del optimizador.
- **Tope de gas por transacción** (EIP-7825, en Fusaka): una única transacción ya no puede consumir el bloque entero. Toda operación de administración pesada (migración, inicialización masiva, barrido de listas) debe ser **paginable y reanudable** — si no cabe bajo el tope, no existe.
- **Capa 2**: el modelo de coste es distinto (el dato de disponibilidad domina sobre la ejecución), y **el conjunto de opcodes va por detrás del L1** (ver `evm_version`, §2). El secuenciador es normalmente **único**: cambia el modelo de MEV, introduce un punto único de fallo y hace que `block.timestamp` y el orden de transacciones tengan garantías distintas. Verificar por cadena antes de asumir nada.
- **Cambios recientes del protocolo que afectan al criterio de escritura de contratos** (verificar en §8, no citar de memoria):
  - **Pectra** (mainnet 2025-05-07) introdujo **EIP-7702**, con el impacto de §5.10 y §5.11.
  - **Fusaka** (meta **EIP-7607**, estado *Final*), activada en mainnet a finales de 2025. De su lista, lo que cambia el criterio de contratos: **EIP-7951** (precompilado de curva **secp256r1** — habilita verificar firmas de passkeys/Secure Enclave en cadena a coste razonable, ver §5.11), **EIP-7825** (tope de gas por transacción), **EIP-7939** (opcode `CLZ`), **EIP-7823/7883** (cotas y encarecimiento de `MODEXP`: revisar todo lo que haga exponenciación modular), **EIP-7935** (gas por defecto del bloque a 60M). El resto (PeerDAS, `eth/69`, límite RLP de bloque) es de infraestructura. solc fijó `osaka` como EVM por defecto en 0.8.31.
  - **Glamsterdam** (ePBS EIP-7732, listas de acceso a nivel de bloque EIP-7928, represupuesto de gas) **no estaba activada en mainnet a ago-2026** — cualquier criterio que dependa de ella es prematuro.
  - **EOF fue descartado** de Fusaka y solc **eliminó** el backend experimental en 0.8.36: código, artículos o herramientas que asuman EOF están obsoletos.

## 7. Sostenibilidad y prohibiciones

**Cadencia**: revisar solc en cada release menor (el bytecode de lo ya desplegado no cambia, pero lo nuevo debe compilarse con un compilador con los bugfixes conocidos — consultar la lista oficial de bugs por versión). OpenZeppelin: subir de menor leyendo el CHANGELOG completo, nunca automáticamente. Tooling de seguridad, actualizado y con su versión fijada en CI. **Todo contrato desplegado se re-revisa cuando cambia una dependencia externa de la que depende su modelo de seguridad** (un oráculo, un token, un puente): tú no puedes actualizarte, pero ellos sí.

**Cuándo NO usar una cadena de bloques.** La honestidad primero: **si el problema se resuelve con una base de datos y una firma, no necesita un contrato.** Una cadena aporta exactamente una cosa — ejecución verificable sin una parte de confianza compartida — a cambio de coste por operación, latencia, imposibilidad de corregir, exposición pública de datos, y un régimen regulatorio propio (MiCA: el periodo transitorio para proveedores de servicios en la UE **terminó el 1 de julio de 2026**; ver `grc-compliance-standards`). Si hay un operador de confianza, si los datos son personales (el derecho al olvido y un registro inmutable son incompatibles), si hace falta corregir errores, o si la única razón es la narrativa: **la respuesta correcta es no desplegar un contrato**, y decirlo es parte del trabajo.

**PROHIBIDO** (requiere justificación escrita y aprobación explícita para excepcionar):
- ❌ `tx.origin` para autorización.
- ❌ Aleatoriedad derivada de `block.timestamp`, `blockhash`, `block.prevrandao` o cualquier estado en cadena.
- ❌ `pragma` con `^` o rango en contratos desplegables; `evm_version` sin fijar; desplegar sin verificar el código fuente en el explorador.
- ❌ Precio *spot* de un AMM como oráculo; integrar un `view` de un tercero sin analizar su comportamiento bajo reentrada.
- ❌ `call`/`transfer` de valor antes de escribir el estado (violación de checks-effects-interactions); `delegatecall` a dirección controlable por el llamante.
- ❌ Implementación tras proxy sin `_disableInitializers()`; upgrade sin validación de layout de *storage* y sin simulación en fork.
- ❌ Clave de `owner`/`upgrader` en una sola dirección caliente; upgrade sin timelock en un protocolo con valor de terceros.
- ❌ Llamadas ERC-20 sin `SafeERC20`; asumir 18 decimales; asumir que `transfer` mueve exactamente lo enviado.
- ❌ Bucles no acotados sobre datos que un tercero hace crecer; distribución de fondos por *push* en bucle.
- ❌ Intercambios sin `minAmountOut` y `deadline` decididos por el usuario; aprobación infinita por defecto.
- ❌ `ecrecover` a pelo (sin comprobar `address(0)` ni normalizar `s`); datos firmados sin `chainId`, sin nonce y sin deadline.
- ❌ `unchecked` sin cota demostrada; redondeo a favor del usuario en las cuentas del protocolo.
- ❌ Desplegar sin tests invariantes verdes, sin auditoría externa cerrada y sin plan de incidente escrito y ensayado.
- ❌ `selfdestruct` en contratos nuevos, y todo diseño que dependa de destruir o re-crear un contrato en su dirección.
- ❌ `address.code.length == 0` o `msg.sender == tx.origin` como comprobación de "es una persona".
- ❌ Criptografía propia; reimplementar un estándar que OpenZeppelin ya provee auditado.
- ❌ Mythril, o cualquier herramienta sin mantenimiento, como control de seguridad (útil solo como confirmación puntual).
- ❌ **Incluir exploits listos para usar, PoCs armados o recetas de ataque contra protocolos concretos de terceros.** Esta skill es **defensiva**: describe clases de vulnerabilidad **para prevenirlas**. Toda prueba ofensiva va con alcance y autorización por escrito, bajo `offensive-security-standards`.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un proyecto real, **verificar por web** (feeds Atom y ficheros en crudo; `api.github.com` devuelve 403 sin autenticar y el resumidor de páginas inventa fechas):
1. **solc**: `https://github.com/argotorg/solidity/releases.atom` y `Changelog.md` en crudo. Comprobar la versión actual, el **EVM por defecto** y la **lista oficial de bugs conocidos por versión** antes de fijar un `pragma`.
2. **EVM soportado por la cadena destino** (L1 y cada L2 usada): documentación del operador. Es el dato que más caduca y el que rompe un despliegue de forma irreversible.
3. **OpenZeppelin Contracts**: `releases.atom` + `LICENSE` en crudo + CHANGELOG de *breaking changes*. Verificar si existe ya una mayor 6.x.
4. **Foundry y Hardhat**: tags `v1.x` del repo de Foundry (no fiarse del tag rodante `stable`, ver discrepancia abajo) y `releases.atom` de Hardhat.
5. **Herramientas de seguridad, una a una** (estado de mantenimiento **y** licencia, ambas cambian): Slither, Echidna, Medusa (AGPL-3.0), halmos (AGPL-3.0), kontrol (BSD-3-Clause), Certora Prover (GPL-3.0), Mythril (MIT, sin mantenimiento). Un repo con poca actividad **no** implica abandono: contrastar con la fuente oficial del proyecto antes de descartarlo.
6. **Actualizaciones de red de Ethereum**: qué está activado en mainnet y qué EIPs incluye — **leer el meta-EIP del fork** (`eips.ethereum.org`, p. ej. EIP-7607 para Fusaka) y el blog de la Ethereum Foundation, **nunca artículos de terceros**: varias listas de EIPs publicadas siguen incluyendo propuestas que se retiraron del fork antes de activarse (EIP-7907 es el caso claro). A ago-2026: Pectra y Fusaka activadas, **Glamsterdam no**.
7. **EIP-7702 y abstracción de cuenta**: qué está desplegado en mainnet y cómo lo tratan las wallets. Dato caliente.
8. **Cifras de pérdidas**: DefiLlama (`/hacks`, `/hacks/total-value-lost`) u otra fuente que publique **datos**, no titulares. Citar la fecha de consulta.
9. **Estado regulatorio (MiCA y equivalentes)**: fuentes oficiales (ESMA, autoridad nacional). Criterio de ingeniería solo; lo normativo es de `grc-compliance-standards`.

**Discrepancias declaradas (ago-2026)**:
- **Foundry**: la página del tag rodante `stable` mostraba *"Foundry v1.5.1 … bugfix release to support solc 0.8.31"* mientras el listado de tags `v1.*` encabeza con **v1.7.1** y `master` declara `version = "1.8.0"`. Consecuencia práctica: **pinar una versión exacta**, no el canal.
- **Pérdidas por puentes**: **2 900 M USD** (informe de terceros) frente a **3 304 M USD** (página de DefiLlama). La propia DefiLlama advierte de solapamiento entre la etiqueta "bridge" y el protocolo objetivo, y de entradas con importe incompleto.
- **Pérdidas H1-2026**: **1 316 M USD en 344 incidentes** (CertiK) frente a **~972 M USD en 207** (otro informe). Metodologías de recuento distintas: citar fuente y fecha, nunca la cifra sola.
- **Hardhat**: un análisis de terceros de 2026 situaba la versión en v3.9.1 mientras el feed oficial de releases mostraba **v3.12.0** (2026-07-30). Manda el feed.

**Huecos: no verificado a ago-2026** — (a) si existe una mayor **OpenZeppelin Contracts 6.x** en preparación y su calendario; (b) el modelo de precios actual del **Certora Prover en la nube** (Certora no publica lista de precios; solo se confirmó la licencia GPL-3.0 del código); (c) si **`halmos`** sigue mantenido pese a no tener release ni commits en `main` desde ago-2025 — **contrastar con a16z crypto antes de descartarlo o de meterlo en un gate**; (d) la **fecha y epoch exactos de activación de Fusaka** en mainnet — el meta **EIP-7607** está en estado *Final* y su lista de EIPs sí se verificó en `eips.ethereum.org`, pero la fecha solo consta en fuente secundaria (2025-12-03): confirmar en el blog de la Ethereum Foundation antes de citarla; (e) el **default EVM de solc 0.8.36**, inferido como `osaka` porque su changelog no contiene ninguna línea `Set default EVM Version` posterior a 0.8.31 — **confirmar con `solc --help` o la documentación oficial** antes de omitir `evm_version`.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
