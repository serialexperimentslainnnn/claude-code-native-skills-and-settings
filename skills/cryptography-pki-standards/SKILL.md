---
name: cryptography-pki-standards
description: Applied cryptography and PKI standards. Use when choosing algorithms or modes (AES-GCM, ChaCha20-Poly1305, Ed25519, RSA-PSS), Argon2id password hashing, TLS 1.3 config, testssl.sh, ACME/Let's Encrypt, step-ca, cert-manager, mTLS, HSM/KMS key rotation, cosign/GPG signing, crypto agility and CBOM inventory.
---

# Estándares de criptografía aplicada y PKI

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al elegir, implementar o revisar: algoritmos y modos (AEAD, cifrado en reposo,
firma), derivación de claves y hashing de contraseñas, generación de aleatoriedad, gestión
de nonces/IV, firmas digitales y formatos JOSE/COSE, configuración TLS y su verificación,
ciclo de vida de certificados y automatización ACME (Let's Encrypt, step-ca, cert-manager,
reto DNS-01), diseño de PKI interna y jerarquía de CA, mTLS y pinning, gestión de claves
con HSM/KMS (envelope encryption, wrapping, rotación, custodia), firma de código y
artefactos, cifrado de backups, e inventario y migración post-cuántica.

**No aplica**: ver `post-quantum-crypto-standards` (**frontera crítica**: la PKI, el ciclo de vida
del certificado y la cripto clásica se deciden **aquí**; **toda la transición post-cuántica es
suya** — estado de FIPS 203/204/205/206 y HQC, calendarios de NIST IR 8547 y CNSA 2.0, híbridos en
TLS/SSH/IPsec y orden de migración por tipo de dato. Si la pregunta lleva fecha de migración o
nombre de algoritmo PQC, manda la otra), `networking-standards` (terminación TLS en el borde,
proxies, WireGuard, DNSSEC), `kubernetes-standards` (despliegue de cert-manager y verificación de
firma en admission), `cicd-standards` (firma de artefactos dentro del pipeline y OIDC del runner),
`identity-access-management-standards` (tokens, sesiones y política de autenticación),
`appsec-standards` (uso inseguro de cripto detectado en revisión de código),
`secrets-management-standards` (almacenamiento y distribución de secretos
ya generados), `assembly-standards` (**frontera crítica**: la elección de algoritmo,
curva, modo, tamaño de clave y todo el ciclo de vida de las claves se decide **aquí**; allí solo la
**implementación** de tiempo constante —sin ramas ni accesos a memoria dependientes del secreto— y
el borrado de secretos que el compilador no puede optimizar. La regla que ambas repiten y que no
admite excepción: **PROHIBIDO implementar criptografía propia**; se usa una biblioteca auditada, y
si alguien está escribiendo ensamblador criptográfico, la pregunta previa es por qué),
`solidity-standards` (el uso de las primitivas que ya expone la cadena —verificación de
firma, EIP-712, `ecrecover` y su maleabilidad— es suyo; la elección y custodia de las claves,
de aquí), `govtech-eidas-standards` (**el régimen eIDAS es suyo**: firma electrónica avanzada
frente a cualificada, prestador cualificado y listas de confianza, sello de tiempo cualificado,
formatos AdES y su conservación a largo plazo, y qué valor probatorio tiene cada uno. **Aquí la
criptografía que hay debajo** —algoritmo, curva, custodia en HSM, cadena y revocación—; la
regla que evita el error caro: **una firma técnicamente válida no es una firma cualificada**,
y eso lo decide su marco, no el algoritmo).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Las
> fechas de migración PQC y de vida máxima de certificado cambiaron en 2025-2026: no las
> fijes de memoria.

| Necesidad | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| Cifrado simétrico autenticado | **AES-256-GCM** (nonce gestionado) o **ChaCha20-Poly1305** (sin AES-NI) | **AES-GCM-SIV** (RFC 8452) o **AES-SIV** (RFC 5297) si el nonce no se puede garantizar único; XChaCha20-Poly1305 con nonce aleatorio | ECB, CBC/CTR sin MAC, DES/3DES, RC4, Blowfish |
| Cifrado con clave de baja entropía (contraseña/PSK) | AEAD **con compromiso de clave** o construcción que ate la clave al ciphertext | KDF fuerte + AEAD estándar, documentando el riesgo | AES-GCM/ChaCha20-Poly1305 "a secas" (no son key-committing) |
| Hashing de contraseñas | **Argon2id** | scrypt; bcrypt en legacy; **PBKDF2-HMAC-SHA-256** si exigen FIPS | MD5, SHA-1, SHA-256 "con sal", hashing propio |
| Hash de propósito general | **SHA-256/SHA-512** o SHA-3/BLAKE2-3 | — | MD5, SHA-1 (ni en "checksums", acaban usándose como seguridad) |
| Firma digital | **Ed25519** (RFC 8032) | ECDSA P-256 (con RFC 6979) si exigen NIST/FIPS; **RSA-PSS** ≥3072 en interoperabilidad legacy | RSA PKCS#1 v1.5 en diseños nuevos, RSA <3072, DSA |
| Transporte | **TLS 1.3**; TLS 1.2 solo con suites AEAD+PFS | mTLS con PKI propia para este-oeste | TLS 1.0/1.1 (RFC 8996), renegociación insegura, suites sin PFS |
| Certificados públicos | **ACME automatizado** (Let's Encrypt u otra CA ACME) | CA comercial cuando lo exija un tercero | Emisión manual, autofirmados en superficies públicas |
| PKI interna | **step-ca** o CA gestionada del proveedor; **cert-manager** en Kubernetes | CA offline propia con HSM para la raíz | Reutilizar la CA interna para TLS público; CA sin plan de revocación |
| Custodia de claves | **KMS/HSM** (FIPS 140-3) con envelope encryption | Fichero cifrado con clave en KMS, si no hay HSM | Claves en repos, imágenes, variables de entorno en claro o en el mismo backup que los datos |
| Firma de artefactos | **Sigstore/cosign keyless** (OIDC del CI, log de transparencia) | minisign/`age` + SSH signing en entornos pequeños; GPG solo por requisito externo | Artefactos sin firmar en el camino a producción |
| Cifrado de ficheros/backups | **age** (o el cifrado nativo de restic/kopia/borg) | GPG solo por interoperabilidad heredada | ZIP "con contraseña", cifrado casero |

## 3. Estructura y convenciones

### AEAD, nonces y límites reales

- **Nunca reutilices un nonce con la misma clave**: en AES-GCM y ChaCha20-Poly1305 la
  repetición no degrada, **rompe** (recuperación del authenticator y del plaintext).
- AES-GCM usa nonce de 96 bits: con nonces **aleatorios**, el límite práctico es del orden
  de **2³² mensajes por clave** (bound de cumpleaños; SP 800-38D y FIPS 140-3 IG C.H
  restringen además cómo se genera el nonce). Con contador determinista y particionado por
  emisor, el techo es mucho mayor — pero exige estado fiable.
- Si no puedes garantizar unicidad: **AES-GCM-SIV / AES-SIV** (resistentes al mal uso del
  nonce) o extensión de nonce (XChaCha20-Poly1305; construcciones tipo XAES-256-GCM o
  DNDK-GCM, aún en draft CFRG — verifica su estado antes de depender de ellas).
- **Compromiso de clave**: los AEAD estándar no son key-committing. Cuando la clave deriva
  de contraseña o PSK de baja entropía, o cuando el receptor prueba varias claves, aparecen
  *partitioning oracles* (USENIX Security '21) que permiten recuperar la clave. Usa un AEAD
  con compromiso o ata explícitamente la clave (hash de la clave en el AAD).
- El AAD no es opcional: mete en él el contexto (tenant, versión de esquema, id de objeto)
  para que un ciphertext no sea reutilizable en otro contexto.

### Hashing de contraseñas (parámetros, no "usa bcrypt")

Mínimos de OWASP (agosto 2026) — **suben con el hardware, re-verifica (§8)**:

| Algoritmo | Parámetros mínimos | Nota |
|---|---|---|
| Argon2id | `m=19 MiB, t=2, p=1` (o equivalentes: `m=12 MiB, t=3`…) | Ajusta **al alza** hasta ~250-500 ms de verificación; RFC 9106 recomienda configuraciones bastante mayores |
| scrypt | `N=2^17, r=8, p=1` | Segunda opción si no hay Argon2id |
| bcrypt | coste ≥ **10**, límite de **72 bytes** | Pre-hash con SHA-256 (+base64) si aceptas contraseñas largas |
| PBKDF2 | ≥ **600 000** iteraciones con HMAC-SHA-256 | Solo por requisito FIPS |

- Sal única por contraseña (la genera la librería). **Pepper** opcional en KMS/HSM, como
  defensa en profundidad, nunca como sustituto.
- Rehash transparente al aumentar parámetros: se detecta en el login y se actualiza.
- Comparación en tiempo constante en todo lo que compare secretos (tokens, HMAC, hashes).

### Aleatoriedad

- Fuente del sistema **siempre**: `getrandom(2)`/`getentropy`, `/dev/urandom`,
  `BCryptGenRandom`, o el wrapper criptográfico del lenguaje (`secrets` en Python,
  `crypto/rand` en Go, `crypto.randomBytes`/`getRandomValues`, `SecureRandom`).
- **PROHIBIDO** para cualquier valor con función de seguridad: `Math.random()`, `rand()`,
  `java.util.Random`, el módulo `random` de Python, PRNG sembrados con la hora o el PID.
- Cuidado con VMs clonadas, contenedores e imágenes doradas: entropía y estado del PRNG se
  duplican; garantiza reseed en el arranque.

### Firmas y JOSE

- Ed25519 por defecto; ECDSA P-256 si el ecosistema lo exige (con firma determinista o RNG
  correcto: un nonce `k` repetido revela la clave privada); RSA-PSS antes que PKCS#1 v1.5.
- JOSE/JWT (RFC 8725): `alg` contra **allowlist del verificador**, nunca el del token;
  prohibido `none`; prohibido aceptar HMAC donde esperas asimétrico (confusión de
  algoritmo); `kid` validado contra el JWKS conocido; `typ` explícito.
- Firma de commits/tags: SSH signing (`gpg.format = ssh`) con `allowed_signers`
  versionado, o GPG si el proceso ya lo exige. La verificación se hace en CI, no "de vista".

### PKI: jerarquía y ciclo de vida

- **Raíz offline** (HSM o material dividido), intermedias **por propósito** (TLS servidor,
  mTLS cliente, firma de código) y hojas de **vida corta**. Una CA que emite de todo es un
  single point of compromise.
- Restringe: `keyUsage`/`extendedKeyUsage` mínimos, `nameConstraints` en las intermedias
  internas, SAN correcta (CN es decorativo), sin wildcards compartidos entre servicios.
- **Automatización o no hay PKI**: ACME (step-ca, cert-manager, `certbot`/`lego`) con
  renovación desatendida y margen ≥ 1/3 de la vida del certificado. DNS-01 para wildcards y
  hosts internos, con credenciales de DNS de **permiso mínimo** (delegar solo
  `_acme-challenge` a una zona propia).
- La vida máxima de los certificados TLS públicos se está **reduciendo por fases** (ballot
  SC-081 del CA/Browser Forum, con hitos hasta 47 días y reducción paralela de la reutilización de
  validación de dominio). **Verifica el calendario y las cifras vigentes (§8)**; la
  consecuencia de diseño no cambia: renovación 100 % automática y sin humano en el camino.
- Revocación: CRL/OCSP tienen entrega y adopción irregulares → la defensa real es **vida
  corta + reemisión rápida**. Pregunta operativa obligatoria: si tu CA revoca en 24 h
  (requisito de los Baseline Requirements en incidentes), ¿puedes reemitir y desplegar toda
  la flota en 24 h? Si no, tienes un incidente latente.
- Monitoriza **Certificate Transparency** para tus dominios: detecta mis-emisión sin los
  riesgos del pinning.

### mTLS y pinning

- Identidad en el SAN (URI SPIFFE o DNS), validación de cadena **completa** contra tu CA
  (no contra el trust store del sistema) y rotación automática de las hojas.
- **HPKP está muerto** (retirado de los navegadores). Si pinas en app nativa: pina **claves
  públicas**, con **pinset y pines de respaldo**, solo endpoints propios, con **kill switch
  remoto** y monitorización de la rotación. Un pin sin plan de rollback es un ladrillo
  programado: el ciclo de revisión de la tienda de apps es más lento que cualquier rotación
  de emergencia.
- Nunca pines endpoints de terceros que no controlas.

### Gestión de claves

- **Envelope encryption**: DEK por objeto/tenant, envuelta por una KEK que vive en KMS/HSM.
  Wrapping con AES-KW (RFC 3394) o AEAD; nunca "cifrar la clave con la misma clave".
- Cripto-periodo explícito por clave y **rotación probada**: identificador de versión de
  clave junto al ciphertext para poder rotar la KEK sin re-cifrar todo el corpus.
- Separación de funciones: quien administra el KMS no descifra datos; toda operación con
  clave raíz es auditada y con doble control.
- Custodia de raíces: Shamir/quorum o custodia física dividida, con procedimiento de
  recuperación **ensayado**.
- Backups: cifrado con clave que **no** viva en el sistema respaldado, copias inmutables
  (Object Lock / repositorio append-only) y restore probado. `age` (v1.1.x incorpora ya
  destinatarios híbridos post-cuánticos `mlkem768x25519` y `age-inspect`) o el cifrado
  nativo de restic (0.18.x, zstd por defecto desde 0.14), kopia o borg.

### Post-cuántico — **cedido a `post-quantum-crypto-standards`**

Toda la transición vive allí: estado real de FIPS 203/204/205/206 y HQC, calendarios de
NIST IR 8547 y CNSA 2.0 con su procedencia, híbridos en TLS/SSH/IPsec con punto de código y
soporte por versión, tamaños de clave y de firma, y el orden de migración por tipo de dato.
**No dupliques aquí ninguna de esas fechas**: caducan y divergen.

Lo que sí sigue siendo de esta skill, porque es cripto aplicada y no transición:

- **Agilidad criptográfica** como requisito de diseño: algoritmo y versión de clave como
  metadato del dato cifrado, capa de cripto aislada tras una interfaz, y **CBOM**
  (CycloneDX 1.6 = ECMA-424 introdujo activos criptográficos; 1.7 los refina) generado en
  CI para saber qué algoritmos usas realmente. Sin inventario no hay migración — y el
  inventario se hace con las herramientas de esta skill, se explota con las de la otra.
- Cifrado de backups con clave que no viva en el sistema respaldado: `age` (v1.1.x ya
  incorpora destinatarios híbridos `mlkem768x25519`) o el cifrado nativo de restic/kopia/borg.

## 4. Calidad y testing (gates de CI)

1. **Linters de cripto**: reglas de `gosec`/`bandit`/`semgrep`/analizadores del lenguaje
   para MD5/SHA-1/DES/ECB, `InsecureSkipVerify`/`verify=False`, claves hardcodeadas y PRNG
   no criptográfico. Rompen el build.
2. **Secret/key scanning** (el escáner concreto y su licencia los fija
   `secrets-management-standards`; verifica antes de fijarlo): clave privada o material de CA en el
   repo = build roto y rotación inmediata, no un TODO.
3. **Vectores conocidos (KAT)** para cualquier código que toque cripto propio, más tests
   negativos: tag corrupto, nonce repetido detectado, certificado expirado, cadena
   incompleta, hostname que no casa, `alg` manipulado.
4. **Escaneo TLS** (`testssl.sh` o `sslyze`) contra staging en cada release y contra
   producción de forma programada: versiones, suites, cadena, OCSP stapling, HSTS.
5. **Monitorización de caducidad** como test operativo: alerta con margen ≥ 3× el ciclo de
   renovación, y falla el pipeline si un certificado gestionado no se renovó a tiempo.
6. **Verificación de firma** en el despliegue: artefacto sin firma válida no se instala
   (detalle del pipeline en `cicd-standards`, del admission en `kubernetes-standards`).

## 5. Seguridad

- **Prohibido implementar primitivas propias.** Usa la librería criptográfica mantenida de
  tu plataforma (libsodium, la stdlib del lenguaje, OpenSSL/AWS-LC vía wrapper de alto
  nivel). "Rodar tu propio cripto" incluye componer AEAD a mano, inventar padding o
  encadenar hashes.
- Canales laterales: comparación en tiempo constante, cuidado con la caché y con mensajes
  de error distinguibles (padding/MAC oracles). Los errores de descifrado son **un solo**
  error genérico.
- No filtres en logs claves, IV/nonces junto al ciphertext sin control, ni fragmentos de
  material sensible; los volcados de excepción son un canal de exfiltración.
- Ficheros de clave privada: permisos `0600`, propietario dedicado, fuera de la imagen del
  contenedor y del backup del sistema que protegen.
- Validación estricta del par certificado/hostname en **todo** cliente (SDKs incluidos);
  desactivar la verificación "temporalmente" es un hallazgo, incluso en desarrollo.
- Dependencias criptográficas: seguir CVEs de la librería TLS/cripto en uso y su ciclo de
  soporte (LTS vs no-LTS) — es el componente con menor tolerancia a versiones sin parches.
- Cumplimiento: FIPS 140-3 sustituye a 140-2; los certificados 140-2 pasan a **Historical
  el 21-sep-2026** (los sistemas siguen funcionando, pero dejan de valer para nuevas
  adquisiciones federales). Si hay requisito, verifica el módulo concreto en el CMVP, no la
  afirmación de marketing del proveedor.

## 6. Operabilidad

- **La renovación es un servicio, no una tarea**: ACME desatendido, recarga del proceso sin
  downtime (`nginx -s reload`, hot-reload del binario), y prueba periódica de que la recarga
  realmente toma el certificado nuevo.
- Rate limits de la CA (Let's Encrypt y equivalentes) contemplados en el diseño: staging
  para pruebas, no emitir por cada despliegue efímero.
- Rendimiento: TLS 1.3 con reanudación de sesión (cuidado con `0-RTT`: solo para peticiones
  idempotentes), OCSP stapling, y aceleración por hardware donde exista. El cifrado por
  software rara vez es el cuello; el **handshake** sí.
- HSM/KMS: latencia y límite de operaciones por segundo son capacidad planificable (y
  coste). Cachea DEKs desenvueltas en memoria con TTL, nunca las persistas en claro.
- Observabilidad: métricas de caducidad de certificados, fallos de handshake por causa,
  versión/suite negociada, errores de KMS y tasa de renovación. Alerta sobre síntomas
  (handshakes fallidos subiendo), no solo sobre el vencimiento.
- Reloj: la validación de certificados depende del tiempo. NTP fiable y monitorizado; una
  deriva de reloj se presenta como "TLS roto sin causa".

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisa parámetros de hashing de contraseñas y configuración TLS al menos
  anualmente (suben con el hardware) y el plan PQC **semestralmente** mientras dure la
  transición. La reducción de vida de certificados obliga a revisar la automatización cada
  vez que cambia una fase.
- Toda excepción (RSA-2048 heredado, TLS 1.2 para un cliente antiguo, GPG por un tercero)
  lleva fecha de salida y ticket.
- Mantén el **CBOM** vivo, no como export anual: es la lista de trabajo de la migración.

**PROHIBIDO**
- ❌ MD5 y SHA-1 con función de seguridad; DES/3DES, RC4, modo ECB.
- ❌ Cifrado sin autenticación (CBC/CTR "a pelo") y MAC-then-encrypt improvisado.
- ❌ Reutilizar nonce/IV con la misma clave; IV predecible o contador global sin partición.
- ❌ Contraseñas con hash rápido (SHA-256/512 con sal), esquemas propios o rondas "a mano".
- ❌ PRNG no criptográfico para claves, tokens, sales, nonces o identificadores.
- ❌ Claves privadas o material de CA en repos, imágenes, artefactos o logs.
- ❌ RSA <3072 en claves nuevas; ECDSA con RNG dudoso; PKCS#1 v1.5 para firmar en diseños nuevos.
- ❌ TLS 1.0/1.1, suites sin PFS, `InsecureSkipVerify`/`verify=False`/`--no-check-certificate`.
- ❌ HPKP; pinning sin pines de respaldo, sin kill switch o sobre endpoints de terceros.
- ❌ Certificados emitidos o renovados a mano en producción; wildcard compartido entre servicios sin relación.
- ❌ CA raíz online, sin restricciones de nombre ni plan de revocación; CA interna usada para superficies públicas.
- ❌ Backups cuya clave vive en el sistema respaldado, o sin restore probado.
- ❌ Implementar primitivas criptográficas propias.

### Checklist de revisión rápida

- [ ] Algoritmo y modo de la tabla §2; nonce con estrategia explícita y límite por clave documentado.
- [ ] Contraseñas con Argon2id (o alternativa justificada) y parámetros verificados este año.
- [ ] Aleatoriedad del sistema en todo secreto; comparaciones en tiempo constante.
- [ ] TLS 1.3 verificado con `testssl.sh`; certificados por ACME con renovación automática y alerta de caducidad.
- [ ] PKI con raíz offline, intermedias por propósito, `nameConstraints` y plan de reemisión en 24 h.
- [ ] Claves en KMS/HSM con envelope encryption, versión de clave junto al dato y rotación probada.
- [ ] Artefactos firmados y verificados en el despliegue; claves privadas fuera de repos e imágenes.
- [ ] CBOM generado en CI y plan PQC con fechas verificadas.

## 8. Verificación web obligatoria

Antes de fijar algoritmo, versión, fecha o parámetro en un entregable:

1. **Estado PQC del NIST**: FIPS 203/204/205 (y FIPS 206 / HQC), y el calendario de
   transición de **NIST IR 8547** (deprecación de RSA/ECC) y de **CNSA 2.0** por categoría.
2. **Vida máxima de certificados TLS públicos**: fase vigente del ballot SC-081 del
   CA/Browser Forum y los plazos de reutilización de validación de dominio.
3. **Parámetros de hashing** en la OWASP Password Storage Cheat Sheet (cambian con el
   hardware) y en la revisión vigente de NIST SP 800-63B.
4. **Versiones y EOL** de OpenSSL (o AWS-LC/BoringSSL), step-ca, cert-manager, `age`,
   restic/kopia/borg, cosign y `testssl.sh`, más sus CVEs abiertos.
5. **Soporte real de híbridos PQC** en TLS (nombre exacto del grupo, navegadores, servidor)
   y en tu KMS/HSM por región, antes de prometer "quantum-safe".
6. **Novedades de tu CA**: perfiles ACME, certificados de vida ultracorta, cambios en
   OCSP/CRL y rate limits.
7. **Validación FIPS 140-3** del módulo concreto en el CMVP si hay requisito de cumplimiento.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
