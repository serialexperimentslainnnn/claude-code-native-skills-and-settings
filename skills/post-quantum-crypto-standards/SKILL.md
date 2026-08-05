---
name: post-quantum-crypto-standards
description: Planning and executing the migration to post-quantum cryptography — the transition, not the PKI. Use when scoping harvest-now-decrypt-later exposure by data lifetime, building a cryptographic inventory or a CBOM (CycloneDX crypto assets), or working with FIPS 203 ML-KEM, FIPS 204 ML-DSA, FIPS 205 SLH-DSA, the pending FIPS 206 FN-DSA and HQC, legacy Kyber/Dilithium/Falcon/SPHINCS+ names, hybrid TLS 1.3 key exchange with X25519MLKEM768 (IANA group 4588 / 0x11EC) or the retired X25519Kyber768Draft00 (0x6399), OpenSSH KexAlgorithms mlkem768x25519-sha256 and sntrup761x25519-sha512@openssh.com, IKEv2 additional key exchanges (RFC 9370, ke1_mlkem768) and RFC 8784 preshared keys, liboqs / oqsprovider / Open Quantum Safe, PQC support in AWS KMS, Google Cloud KMS or Azure Managed HSM, signature and key sizes blowing up a handshake, a firmware image or a certificate chain, crypto-agility as a design requirement, or the migration deadlines in NIST IR 8547, SP 800-131A and NSA CNSA 2.0.
---

# Estándares de migración post-cuántica

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **la transición**: decidir qué migrar, en qué orden, con qué plazo y con qué
evidencia. Cubre: modelo de amenaza *harvest now, decrypt later* (HNDL) y priorización **por
vida útil del dato**, inventario criptográfico y CBOM, elección de algoritmo PQC y de
parámetros, despliegue de **híbridos** en TLS, SSH e IKEv2/IPsec, el problema específico de
las **firmas** (tamaño, cadenas de certificados, firmware, arranque seguro), **agilidad
criptográfica** como requisito de diseño, calendarios normativos (NIST IR 8547, SP 800-131A,
CNSA 2.0) y su traducción a un plan plurianual con presupuesto.

Triggers: `ML-KEM`/`ML-DSA`/`SLH-DSA`/`FN-DSA`/`HQC`, `Kyber`/`Dilithium`/`Falcon`/`SPHINCS+`,
FIPS 203/204/205/206, `X25519MLKEM768`, `0x11EC`, `mlkem768x25519-sha256`,
`sntrup761x25519-sha512@openssh.com`, `ke1_mlkem768`, RFC 9370, RFC 8784, `liboqs`,
`oqsprovider`, `PQCSecretKey`, CBOM, "quantum-safe", "crypto-agility", "Q-day", CNSA 2.0,
NIST IR 8547.

**No aplica**: ver `cryptography-pki-standards` (**madre y frontera dura**: la elección de
algoritmo clásico, modos AEAD, hashing de contraseñas, aleatoriedad, **toda la PKI** —
jerarquía de CA, `nameConstraints`, ACME, ciclo de vida y revocación del certificado—,
custodia de claves en HSM/KMS, mTLS y pinning, y la prohibición de implementar cripto propia.
**Aquí solo la transición**: qué se sustituye, cuándo, en qué orden y cómo se demuestra. Si
la pregunta es "qué CA y con qué claves", es suya; si es "cuándo dejo de poder usar esa
clave y por qué la sustituyo", es de aquí), `secrets-management-standards` (custodia y
rotación del secreto ya generado), `networking-standards` y `load-balancing-standards`
(terminación TLS en el borde y su configuración), `vpn-standards` (**el túnel como
servicio**: `wg0.conf`, `swanctl.conf`, propuestas IKEv2, concentrador y su operación —
**aquí solo qué intercambio de claves PQC exigir y con qué plazo**),
`identity-access-management-standards` (JOSE/JWT, tokens y federación),
`cicd-standards` (firma de artefactos y OIDC del runner dentro del pipeline),
`kubernetes-standards` (cert-manager y verificación en admisión),
`vulnerability-management-standards` (triaje de CVE y SLA de parcheo: **el "riesgo cuántico"
no es un CVE y no entra en su cola**), `grc-compliance-standards` (aceptación formal del
riesgo residual y evidencia de auditoría), `opensource-licensing-standards` (licencia de las
bibliotecas PQC que introduzcas), `solidity-standards` (primitivas de firma de la cadena),
`assembly-standards` (implementación en tiempo constante), `mlsecops-standards` y
`ai-governance-standards` (nada que ver: "quantum" en marketing de IA no es esto).

## 2. Decisiones por defecto

> **Ningún dato de esta tabla se escribe de memoria en un entregable.** Fechas y estados de
> FIPS, IR 8547 y CNSA 2.0 se re-verifican antes de comprometer un plan (§8).

| Necesidad | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| Establecimiento de clave | **ML-KEM-768 en híbrido con X25519** (`X25519MLKEM768`) | ML-KEM-1024 si el requisito es CNSA 2.0 o el dato vive décadas | ML-KEM **solo**, sin componente clásico, en producción hoy |
| Firma de propósito general | **ML-DSA-65** (o -87 si lo exige CNSA 2.0) | SLH-DSA cuando importa más la confianza en la hipótesis (solo hash) que el tamaño | FN-DSA (FIPS 206) antes de que exista el estándar final |
| Firma de firmware / arranque | **LMS o XMSS (SP 800-208)**, con gestión de estado seria | SLH-DSA si no puedes garantizar el estado (es *stateless*) | Reutilizar una clave *stateful* sin control de índice: una firma repetida rompe el esquema |
| KEM alternativo | Esperar a **HQC** como diversificación, no como reemplazo | — | Fijar HQC en un diseño antes de que se publique su FIPS |
| Estrategia de despliegue | **Híbrido** (clásico + PQC) mientras dure la transición | PQC puro cuando el regulador lo exija y el ecosistema lo soporte | "Ya migraremos cuando salga el ordenador cuántico" |
| Orden de trabajo | **Confidencialidad de larga vida primero**, firmas después | Firma primero si tu producto tiene *root of trust* en firmware que no se puede actualizar | Priorizar por sistema ("empecemos por producción") en vez de por dato |
| Prerrequisito | **Inventario criptográfico + CBOM** antes de tocar nada | — | Migrar sin saber qué algoritmos usas: presupuesto quemado y huecos |
| Biblioteca | La del proveedor de tu plataforma con soporte PQC (OpenSSL 3.5+, AWS-LC, BoringSSL, Go `crypto/tls`) | `liboqs`/`oqsprovider` para experimentar y para algoritmos aún no integrados | `liboqs` en producción sin leer su propio aviso de madurez |
| Métrica de avance | **% de conexiones/artefactos con PQC negociado**, medido | — | "Estamos migrando" sin telemetría de qué se negocia realmente |

## 3. HNDL: la urgencia la fija el dato, no el sistema

- **Harvest now, decrypt later**: el adversario captura hoy tráfico cifrado y lo descifra
  cuando exista una máquina capaz. Por eso la fecha límite **no** es "cuando llegue el
  ordenador cuántico": es **hoy menos la vida útil del dato**.
- Regla de Mosca, y es la única aritmética que hace falta: si **X** = años que el dato debe
  seguir siendo secreto, **Y** = años que tardas en migrar y **Z** = años hasta que exista un
  CRQC (*cryptanalytically relevant quantum computer*), **tienes un problema si X + Y > Z**.
  Z no lo sabe nadie; X e Y sí los sabes tú, y son los únicos que puedes cambiar.
- **Prioriza por tipo de dato, no por criticidad del sistema**: historia clínica, datos
  genéticos, identidad, secreto industrial, material clasificado, expedientes legales y
  **claves raíz de PKI y de firmware** tienen vida de décadas. Un carrito de la compra
  cifrado tiene vida de minutos y no urge. Un sistema "crítico" que solo mueve datos
  perecederos urge **menos** que un backup archivado de datos personales.
- Superficies HNDL reales: **VPN e interconexiones** (el tráfico es interceptable y
  archivable), backups y replicación fuera de sitio, mensajería y correo cifrados, tráfico
  hacia proveedores cloud, y cualquier cosa que atraviese una red que no controlas.
- **Las firmas no sufren HNDL.** Una firma solo importa mientras se verifica: falsificarla en
  2035 no ayuda a quien la capturó en 2026. Por eso **el cifrado es más urgente que la
  firma** — con una excepción que sí urge: **la raíz de confianza que no se puede
  actualizar** (firmware, secure boot, dispositivos de campo con vida de 15-20 años). Ahí la
  firma se decide hoy porque no habrá segunda oportunidad.

## 4. Inventario y CBOM: el primer paso real

- **Sin inventario no hay migración, hay presupuesto quemado.** Antes de tocar un solo
  handshake: dónde se usa cripto, con qué algoritmo, con qué tamaño de clave, con qué
  biblioteca y versión, quién es el dueño y cuánto vive el dato que protege.
- Fuentes que hay que cruzar, porque ninguna basta sola:
  1. **Estático**: escaneo de código y dependencias, `grep` de primitivas, análisis del
     binario. Encuentra lo que está escrito, no lo que se ejecuta.
  2. **Dinámico**: qué se negocia de verdad en la red (versión TLS, grupo, suite, algoritmo
     de firma del certificado). Encuentra la realidad, no la intención.
  3. **Inventario de certificados y claves**: CA internas, almacenes, HSM/KMS, claves SSH,
     claves de firma de código y de firmware. Es donde están las sorpresas.
  4. **Terceros**: SaaS, proveedores, dispositivos embebidos y todo lo que no puedes
     recompilar. Aquí la migración es **contractual**, no técnica: metedlo en las cláusulas y
     en la revisión de proveedor ahora, no en 2032.
- **CBOM**: **CycloneDX 1.6** (publicada también como **ECMA-424**) introdujo los activos
  criptográficos; 1.7 los refina. **Verifica la versión vigente y el esquema exacto (§8).**
  Se genera **en CI**, no como export anual: es la lista de trabajo viva de la migración y la
  evidencia que pedirá la auditoría.
- Salida del inventario: cada activo con **clase de dato, vida útil, algoritmo actual, quién
  lo cambia y en qué ventana**. Sin esas cinco columnas no es un inventario, es una lista.

## 5. Cómo se despliega hoy (estado real, verificable)

### Estándares publicados y pendientes

- **Publicados el 13-ago-2024, efectivos el 14-ago-2024** (Federal Register,
  89 FR / anuncio de emisión): **FIPS 203 — Module-Lattice-Based Key-Encapsulation Mechanism
  Standard (ML-KEM**, de CRYSTALS-Kyber), **FIPS 204 — Module-Lattice-Based Digital Signature
  Standard (ML-DSA**, de CRYSTALS-Dilithium) y **FIPS 205 — Stateless Hash-Based Digital
  Signature Standard (SLH-DSA**, de SPHINCS+). El mismo día el CMVP actualizó **SP 800-140C**
  (FIPS 204/205 como métodos de firma aprobados) y **SP 800-140D** (FIPS 203 como KEM
  aprobado) — dato que importa si tienes requisito FIPS 140-3.
- **FIPS 206 (FN-DSA**, de FALCON): **seguía sin ser estándar final a agosto de 2026**. NIST
  remitió el borrador para aprobación el 28-ago-2025 y en la conferencia de estandarización
  PQC de sep-2025 constaba "still under development"; se espera final entre finales de 2026 y
  2027. Motivo del retraso: el muestreo gaussiano en coma flotante de la firma es difícil de
  implementar en tiempo constante. **No lo fijes en un diseño hasta que exista el final.**
- **HQC**: seleccionado el **11-mar-2025** como KEM **de diversificación** (basado en códigos
  correctores, no en retículos), como plan B si los retículos caen. FIPS esperado hacia 2027.
  **No es un reemplazo de ML-KEM ni una razón para esperar.**
- Nombres: **usa siempre los nombres FIPS** (ML-KEM, ML-DSA, SLH-DSA). "Kyber" y "Dilithium"
  designan las versiones **pre-estándar**, incompatibles en el cable con las finales — el
  cambio de punto de código TLS de `0x6399` a `0x11EC` existe exactamente por eso.

### TLS

- El híbrido de facto es **`X25519MLKEM768`**, punto de código IANA **4588 = 0x11EC**
  (`draft-ietf-tls-ecdhe-mlkem`), sobre **TLS 1.3**. Sustituyó a `X25519Kyber768Draft00`
  (`0x6399`), que está **retirado** — si tu inventario lo encuentra, es deuda, no PQC.
- Despliegue real de cliente, verificado: Chrome 124 (abr-2024) habilitó por defecto el
  pre-estándar y **Chrome 131 (nov-2024) cambió a `X25519MLKEM768`**; Edge siguió por
  Chromium; **Firefox 132** por defecto en HTTPS y **135** en QUIC/HTTP-3; Apple lo añadió en
  macOS Tahoe 26 / iOS 26 (otoño 2025). Go retiró `x25519Kyber768Draft00` y usa
  `X25519MLKEM768` por defecto en `crypto/tls`.
- Adopción medida en Cloudflare: **~2 % a principios de 2024 → ~38 % en mar-2025 → >50 % del
  tráfico humano en oct-2025 → >60 % de tráfico de cliente PQ-capaz en feb-2026** (Cloudflare
  Radar); un estudio de 2026 mide **57,4 %** de conexiones iniciadas por navegador con
  *key share* `X25519MLKEM768` — la diferencia es la base de medida, no una contradicción.
  **Cita la fuente y la fecha o no uses la cifra (§8).**
- **El origen va muy por detrás**: ~10 % del lado servidor de origen a principios de 2026,
  tras activarlo Akamai por defecto en ene-2026. Conclusión operativa: **el navegador ya no
  es tu problema; tu origen, tus balanceadores y tus servicios internos sí**.
- Efecto secundario que hay que conocer antes de "arreglarlo": el *key share* de ~1 088-1 216
  bytes ya se usa como **señal de detección de bots**. Un cliente que dice ser un navegador
  moderno y no ofrece `X25519MLKEM768` canta. Si desactivas PQC "por compatibilidad", estás
  cambiando tu huella.

### SSH, IKEv2/IPsec y resto

- **SSH**: OpenSSH negocia híbrido **por defecto desde 10.0** (`mlkem768x25519-sha256`; 9.9 lo
  introdujo; **10.1 avisa cuando el KEX no es post-cuántico**). Fija
  `KexAlgorithms mlkem768x25519-sha256,sntrup761x25519-sha512@openssh.com` donde ambos
  extremos lleguen. **Verifica versiones antes de fijarlas (§8).**
- **IKEv2/IPsec**: **RFC 9370** (intercambios de clave adicionales, `ke1..ke7`) permite añadir
  un KEM PQC sobre el DH clásico — propuesta tipo `ke1_mlkem768` en strongSwan. Interino
  cuando el otro extremo no llega: **RFC 8784** (clave precompartida post-cuántica mezclada
  en la derivación). La operación del túnel y su config son de `vpn-standards`.
- **WireGuard** no negocia: su PSK opcional (`PresharedKey`) da resistencia HNDL simétrica; el
  camino PQC propio son capas externas tipo Rosenpass. Verifica estado antes de prometer.
- **Ficheros y backups**: `age` incorporó destinatarios híbridos `mlkem768x25519` en la serie
  1.1.x — verifica versión y compatibilidad del destinatario antes de cifrar con ellos algo
  que tengas que descifrar dentro de diez años.
- **KMS/HSM**: AWS KMS ofrece ML-DSA en HSM validados (GA desde 2025-06-13), Google Cloud KMS
  llevó a GA ML-DSA, SLH-DSA y ML-KEM, y Azure Key Vault/Managed HSM iba por detrás en 2026.
  **Disponibilidad por región y por nivel de servicio: verifícala antes de diseñar (§8).**

## 6. Firmas: tamaño, cadenas y por qué duele distinto

- El cifrado se migra cambiando un grupo en el handshake; **la firma cambia el formato de todo
  lo firmado**. Un certificado, una cadena, una imagen de firmware y un token crecen a la vez.
- **Tamaños, verbatim de las tablas oficiales** (FIPS 203 Tabla 3, FIPS 204 Tabla 2,
  FIPS 205 Tabla 2), en bytes. Compáralos con los 32 B de una clave X25519 y los 64 B de una
  firma Ed25519:

  | Parámetro | Clave pública | Clave privada | Ciphertext / Firma |
  |---|---|---|---|
  | ML-KEM-512 | 800 | 1 632 | 768 (ct) |
  | **ML-KEM-768** | **1 184** | 2 400 | **1 088** (ct) |
  | ML-KEM-1024 | 1 568 | 3 168 | 1 568 (ct) |
  | ML-DSA-44 | 1 312 | 2 560 | 2 420 (sig) |
  | **ML-DSA-65** | **1 952** | 4 032 | **3 309** (sig) |
  | ML-DSA-87 | 2 592 | 4 896 | 4 627 (sig) |
  | SLH-DSA-128s / 128f | 32 | — | **7 856** / **17 088** (sig) |
  | SLH-DSA-192s / 192f | 48 | — | 16 224 / 35 664 (sig) |
  | SLH-DSA-256s / 256f | 64 | — | 29 792 / **49 856** (sig) |

  Lectura: ML-KEM añade ~1 KB por lado al handshake y es asumible; **ML-DSA multiplica por
  ~30-50× la firma frente a Ed25519**; **SLH-DSA llega a ~50 KB por firma** — clave pública
  minúscula, firma enorme y firmado lento, a cambio de descansar solo en hashes. La variante
  `s` optimiza tamaño y la `f` velocidad: elegir mal duplica el problema.
- Consecuencias concretas que hay que dimensionar **antes** de migrar:
  - **Cadena de certificados**: una cadena PQC puede pasar de ~4 KB a decenas de KB. El
    ClientHello/ServerHello deja de caber en los paquetes iniciales, aparecen *round trips*
    extra y **amplificación** en QUIC. Mide latencia real, no solo bytes.
  - **Firmware y arranque**: dispositivos con flash y RAM contadas, y con una clave pública
    grabada en ROM que no se puede cambiar. Si el *root of trust* no es actualizable, **la
    decisión de firma se toma ahora y para toda la vida del producto** — y por eso este es el
    único frente donde la firma va antes que el cifrado.
  - **Tokens y JOSE/COSE**: una firma ML-DSA en una cookie o cabecera puede reventar límites
    de tamaño de proxies y navegadores. Verifica el límite antes, no en producción.
- **Agilidad criptográfica es el entregable de verdad.** Diseña como si el algoritmo fuera a
  cambiar dos veces más:
  - Identificador de **algoritmo y versión de clave como metadato junto al dato/artefacto**,
    nunca implícito.
  - Toda la cripto **detrás de una interfaz propia**; nada de llamar a la primitiva desde 40
    sitios. La medida de agilidad es: *¿cuántos ficheros toco para cambiar de algoritmo?*
  - **Negociación, no algoritmo fijo en el protocolo**; y capacidad de **desactivar** un
    algoritmo por configuración sin recompilar ni redesplegar.
  - Prueba la agilidad **ejerciéndola**: un simulacro de rotación de algoritmo, igual que un
    simulacro de restore. Una agilidad no ensayada no existe.

## 7. Calendario, sostenibilidad y prohibiciones

- **NIST IR 8547 — "Transition to Post-Quantum Cryptography Standards"**: a agosto de 2026
  seguía en **borrador público inicial (IPD, 12-nov-2024)**, con el periodo de comentarios
  cerrado el 10-ene-2025 y nota de planificación de 21-ene-2025 — **no hay versión final
  confirmada; no lo cites como norma cerrada**. Su calendario propuesto: RSA, ECDSA, ECDH,
  DSA y FFDH **deprecated after 2030** y **disallowed after 2035**, incluidos los tamaños
  altos (RSA-3072, P-384). Lectura correcta: **2030 no es fecha de fin de migración**, es la
  fecha desde la que seguir usándolos exige análisis de riesgo y justificación documentada
  del dueño del dato; 2035 elimina esa opción. **Los modos híbridos no caen bajo la
  prohibición de 2035** — eso es lo que hace viable el enfoque por fases. AES-256, SHA-2 y
  SHA-3 **no** están en ese calendario.
- **SP 800-131A**: la revisión final vigente es la **Rev. 2 (2019)**; la **Rev. 3 está en
  borrador público inicial (oct-2024)**, sube el mínimo de 112 a 128 bits de fuerza y funde
  la transición asimétrica con la post-cuántica. Verifica si ya se finalizó (§8).
- **CNSA 2.0 (NSA, solo para National Security Systems)** — calendario por categoría,
  contrastado en fuentes secundarias coincidentes; **no pude descargar el PDF original de la
  NSA (403 desde `media.defense.gov`): hueco declarado en §8, verifícalo contra el original
  antes de comprometerlo en contrato**:

  | Categoría | *Support and prefer* | *Exclusively use* |
  |---|---|---|
  | Firma de software y firmware | 2025 (empezar de inmediato) | **2030** |
  | Navegadores/servidores web y servicios cloud | 2025 | 2033 |
  | Equipamiento de red tradicional (VPN, routers) | 2026 | **2030** |
  | Sistemas operativos | 2027 | 2033 |
  | Equipamiento de nicho (dispositivos limitados, PKI grandes) | 2030 | 2033 |
  | Aplicaciones a medida y equipo heredado | — | Actualizar o sustituir en 2033 |

  Algoritmos CNSA 2.0: **ML-KEM-1024**, **ML-DSA-87**, AES-256, SHA-384/SHA-512 y **LMS o
  XMSS (SP 800-208)** para firma de software y firmware. La fecha que de verdad muerde no es
  ninguna de la tabla: **desde el 1-ene-2027 se espera que toda adquisición nueva de NSS sea
  conforme a CNSA 2.0**. La FAQ v2.1 (dic-2024) **excluye SLH-DSA de uso en NSS**, prohíbe
  HashML-DSA, excluye HSS y XMSS^MT y descarta FN-DSA — **verifícalo contra el documento
  original: es exactamente el tipo de detalle que se cita mal**. Y ojo: **CNSA 2.0 no aplica a
  quien no opera NSS**; usarlo como excusa para exigir ML-KEM-1024 en una web comercial es
  sobre-ingeniería.
- **CA públicas y CA/Browser Forum — la asimetría que define 2026**: el **intercambio de
  claves** ya es post-cuántico en la mayoría del tráfico, pero **el certificado del servidor
  sigue siendo ECDSA P-256 o RSA-2048**. Estado verificado a agosto de 2026:
  - **S/MIME primero**: el ballot **SMC013** (jul-2025) introdujo ML-DSA y ML-KEM en los
    S/MIME Baseline Requirements, con certificados PQC **no híbridos**, para experimentación.
  - **TLS todavía no**: el Server Certificate WG mantiene un *tracker* de ballots PQC y una
    propuesta "SC0XX: Allow ML-DSA", pero **a mayo de 2026 no había requisito de línea base
    que permita ML-DSA en certificados de confianza pública** (actas del SCWG de 21-may-2026:
    desacuerdo sobre si el X.509 tradicional debe formar parte de la transición, dudas sobre
    los logs de CT, ballot pendiente de reescribir). Microsoft mantiene un **piloto de raíces
    ML-DSA solo para pruebas**; Chrome anunció soporte de anclas ML-DSA para **PKI privada**
    en TLS 1.3 a partir de Chrome 150. **Ninguna raíz ML-DSA pública encadena a los almacenes
    de Mozilla, Apple, Microsoft o Chrome**, y un estudio de jun-2026 sobre 32 011 dominios
    midió **0 % de adopción** de certificados híbridos post-cuánticos.
  - **El camino elegido no es cambiar la firma, es cambiar el formato**: **Merkle Tree
    Certificates (MTC)**. Let's Encrypt publicó su hoja de ruta el **3-jun-2026** (entorno de
    *staging* emisor de MTC a finales de 2026, producción en 2027), Chrome los declaró su vía
    preferida para la web pública y Cloudflare corre un experimento con tráfico real; el
    trabajo está en el WG **PLANTS** del IETF. **Motivo**: un cambio ingenuo de firma llevaría
    el handshake HTTPS por encima de **10 KB**, lo que rompe del orden del **5 %** de las
    conexiones en redes reales. Presión colateral: SC-081 recorta la validez máxima del
    certificado por fases, lo que favorece amortizar una firma PQ entre muchos certificados
    (el calendario de SC-081 lo fija `cryptography-pki-standards`; **verifica la fase vigente**).
  - **Disponible hoy para PKI privada**: ML-DSA en DigiCert Private CA, AWS Private CA (GA
    desde nov-2025) y OpenSSL 3.5 con el proveedor OQS. **Consecuencia de planificación: tu
    PKI interna puede migrar firmas ya; tu cadena pública no depende de ti.**
- **Cadencia**: revisa el plan PQC **semestralmente** mientras dure la transición y regenera
  el CBOM en cada release. Cada excepción (un tercero que no llega, un dispositivo que no se
  actualiza) lleva fecha de salida, dueño y ticket.

**PROHIBIDO**
- ❌ Escribir una fecha de deprecación o de prohibición **de memoria**. Un año mal citado
  desplaza un plan plurianual y un presupuesto.
- ❌ Citar NIST IR 8547 como norma final mientras siga en borrador, o presentar 2030 como
  "fecha límite de migración".
- ❌ Desplegar ML-KEM **sin componente clásico** en producción durante la transición: si
  aparece una debilidad en el retículo, el híbrido te salva y el puro no.
- ❌ Fijar FN-DSA/FIPS 206 o HQC en un diseño antes de que exista el estándar final.
- ❌ Usar `Kyber`/`X25519Kyber768Draft00` (`0x6399`) o cualquier variante pre-estándar en
  producción, o tratarlas como equivalentes a las finales.
- ❌ Implementar tú mismo un algoritmo PQC. Sigue siendo válida la regla de
  `cryptography-pki-standards`: **PROHIBIDO implementar primitivas propias**, y aquí más,
  porque los ataques de canal lateral sobre retículos son un campo activo.
- ❌ Migrar sin inventario ni CBOM, o priorizar por sistema en vez de por vida útil del dato.
- ❌ Claves *stateful* (LMS/XMSS) sin control estricto del índice: reutilizar un índice
  **rompe** el esquema, no lo degrada.
- ❌ Vender "quantum-safe" o "quantum-proof" sin decir qué superficie concreta está migrada y
  medida. Es la afirmación más inflada del sector.
- ❌ Comprar QKD o "cripto cuántica" como sustituto de PQC: son cosas distintas, y varias
  agencias nacionales desaconsejan la QKD para uso general — verifica su postura vigente
  antes de gastar (§8).
- ❌ Exigir parámetros CNSA 2.0 en sistemas que no son National Security Systems "por si
  acaso".

## 8. Verificación web obligatoria

Antes de fijar algoritmo, fecha, cifra o estado en un entregable:

1. **CSRC de NIST**, publicación por publicación: FIPS 203/204/205 (final), **FIPS 206**
   (¿sigue en borrador?), **HQC** (¿ya hay FIPS?), **IR 8547** (¿IPD o final? fechas exactas
   de *deprecated*/*disallowed*), **SP 800-131A** (¿Rev. 2 o Rev. 3 final?) y SP 800-208.
   **Las tablas de transición se citan verbatim.**
2. **CNSA 2.0**: el aviso y la **FAQ vigentes de la NSA**, con su número de versión y fecha.
   Calendario y exclusiones (SLH-DSA, HashML-DSA, HSS/XMSS^MT, FN-DSA) **verbatim**.
3. **Tamaños** de clave, ciphertext y firma (§6): tomados verbatim de FIPS 203 Tabla 3,
   FIPS 204 Tabla 2 y FIPS 205 Tabla 2 en esta revisión; recontrasta si cambia la edición.
4. **Estado del despliegue TLS**: punto de código y nombre exacto del grupo, soporte por
   navegador y por servidor, y **adopción medida con fuente y fecha** (Cloudflare Radar u
   otra). Nunca una cifra sin origen.
5. **Versiones**: OpenSSH (KEX híbrido por defecto y aviso de KEX no-PQ), OpenSSL/AWS-LC/
   BoringSSL, strongSwan, Go, `age`, `liboqs`/`oqsprovider` y sus CVEs abiertos.
6. **PQC en tu KMS/HSM**: algoritmos, regiones y validación FIPS 140-3 del módulo concreto en
   el CMVP, no la nota de prensa.
7. **CA públicas y CA/Browser Forum**: estado del ballot ML-DSA en los TLS Baseline
   Requirements, avance de **Merkle Tree Certificates** (WG PLANTS, Let's Encrypt, Chrome) y
   qué soporta tu CA hoy.
8. **CycloneDX/CBOM**: versión vigente del esquema de activos criptográficos.
9. **Reguladores europeos**: hoja de ruta PQC de la Comisión y de ENISA, y las guías de ANSSI,
   BSI y CCN — imponen plazos propios en contratación pública.

**Huecos declarados en esta versión** (ciérralos antes de usar el documento en un plan real):
- El **PDF original de CNSA 2.0 y su FAQ de la NSA no pudo descargarse** (403 desde
  `media.defense.gov`): el calendario y las exclusiones proceden de fuentes secundarias
  coincidentes, **no de cita verbatim del original**.
- Estado final de **FIPS 206**, de **HQC** y de **SP 800-131A Rev. 3**: verificado como
  pendiente a agosto de 2026 vía fuentes secundarias; confirma contra CSRC.
- Las **versiones de OpenSSH, `age`, AWS/Google/Azure KMS** de §5 vienen heredadas de
  `cryptography-pki-standards` (verificadas allí); reconfírmalas antes de fijarlas.

Ya **cerrado en esta revisión** (no repitas el trabajo): tamaños de FIPS 203/204/205 tomados
verbatim de las tablas oficiales, y estado del CA/Browser Forum y de Merkle Tree Certificates.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
