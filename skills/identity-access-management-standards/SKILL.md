---
name: identity-access-management-standards
description: Identity and access management standards. Use when working with OAuth 2.1/OIDC flows, PKCE, JWT or opaque tokens, SAML, Keycloak, Authentik, Authelia, Zitadel, Okta, passkeys/WebAuthn, MFA policy, SCIM provisioning, RBAC/ABAC/ReBAC engines (OpenFGA, SpiceDB, Cedar), SPIFFE/SPIRE workload identity, PAM/JIT elevation.
---

# Estándares de gestión de identidad y acceso (IAM)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, implementar o revisar: flujos OAuth 2.1/OIDC (`authorization_code`+PKCE,
`client_credentials`, device code, token exchange), diseño y validación de tokens (JWT/opaco,
`aud`, `scope`, TTL, rotación de refresh, revocación), federación SAML, despliegue y
configuración de IdPs (Keycloak, Authentik, Authelia, Zitadel, FreeIPA, Entra ID, Okta,
Ory), passkeys/WebAuthn y política de MFA, SSO y aprovisionamiento SCIM, modelos de
autorización (RBAC/ABAC/ReBAC) y motores de política (OpenFGA, SpiceDB, Cedar, OPA), PAM y
elevación just-in-time, cuentas break-glass, identidad de carga de trabajo (SPIFFE/SPIRE,
federación OIDC hacia cloud), gestión de sesión y single logout, y el ciclo
joiner-mover-leaver con recertificación de accesos.

**No aplica**: ver `aws-standards`/`azure-standards`/`gcp-standards` (IAM del proveedor
concreto: políticas, roles, condiciones, SCPs), `microservices-architecture-standards`
(mTLS/service mesh y propagación de contexto entre servicios), `appsec-standards` (fallos
de autorización dentro del código de la aplicación: IDOR, broken access control),
`secrets-management-standards` (custodia y rotación de secretos estáticos),
`cryptography-pki-standards` (algoritmos de firma, JWKS a nivel criptográfico, emisión de
certificados), `cicd-standards` (configuración del pipeline que consume OIDC),
`windows-server-ad-standards` (el **directorio** y la plataforma Windows: bosque, GPO, Kerberos y
NTLM, Tier 0/PAW, gMSA/dMSA, `krbtgt`, AD CS — aquí la federación e identidad modernas que se
apoyan encima o lo sustituyen), `incident-response-forensics-standards` (revocación masiva de
sesiones y tokens durante un compromiso de identidad), `privacy-engineering-standards` (el dato
personal que contiene el directorio y su ciclo de vida).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Este
> dominio se movió mucho en 2025-2026: no fijes versiones ni estados de spec de memoria.

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Protocolo | **OIDC sobre OAuth 2.1** (perfil actual: PKCE obligatorio, sin implicit, sin ROPC) | SAML 2.0 **solo** contra SaaS que no ofrece OIDC |
| Formato de access token | **JWT** perfilado (RFC 9068) validado localmente por el recurso | Token **opaco** + introspection (RFC 7662) si se exige revocación inmediata |
| Autenticación de cliente confidencial | `private_key_jwt` o mTLS (RFC 8705) | `client_secret_basic` solo en legacy, rotado y en gestor de secretos |
| Vinculación del token | **DPoP** (RFC 9449) o mTLS-bound para tokens de alto valor | Bearer puro solo en tráfico interno con TTL corto |
| Factor de autenticación | **Passkey/WebAuthn** resistente a phishing | TOTP como transición; SMS/voz/email OTP solo recuperación, nunca en cuentas privilegiadas |
| IdP autoalojado | **Keycloak** (madurez, SAML+OIDC, federación) | Authentik/Zitadel (DX, multi-tenant), Authelia (portal/forward-auth ligero), FreeIPA solo como directorio+Kerberos |
| Motor de autorización | **RBAC** en el IdP + **ReBAC** (OpenFGA/SpiceDB) para permisos por objeto | Cedar para políticas embebidas verificables; OPA/Rego para plataforma (admission/IaC), no para authz por objeto de alta cardinalidad |
| Aprovisionamiento | **SCIM 2.0** (RFC 7643/7644) desde el IdP como fuente | Sincronía por directorio/HR-driven (midPoint, Syncope) en organizaciones con IGA formal |
| Identidad de carga | **SPIFFE/SPIRE** (X.509-SVID para mTLS, JWT-SVID para APIs) | Federación OIDC nativa del proveedor (workload identity) — nunca claves estáticas |
| Acceso privilegiado | **JIT con aprobación y grabación** (Teleport, Boundary, PIM del proveedor) | Bastión + certificados SSH de vida corta |

## 3. Estructura y convenciones

### Flujo por tipo de cliente (no hay más opciones)

| Cliente | Flujo | Requisitos no negociables |
|---|---|---|
| Web con backend | `authorization_code` + PKCE | Cliente confidencial autenticado; tokens **solo** en el backend |
| SPA / navegador | `authorization_code` + PKCE con **BFF** | Sesión en cookie `HttpOnly`; tokens fuera del JS |
| Móvil / nativo | `authorization_code` + PKCE (RFC 8252) | Custom Tab / `ASWebAuthenticationSession`; redirect por app link reclamado; **nunca** WebView embebido |
| Servicio→servicio | `client_credentials` con `private_key_jwt`/mTLS | Mejor aún: SPIFFE o federación OIDC sin secreto |
| TV/CLI/IoT | Device authorization grant (RFC 8628) | `user_code` corto, TTL corto, pantalla de confirmación que nombra el recurso |
| Delegación/downscope | Token exchange (RFC 8693) | Scope y `aud` reducidos, nunca ampliados |

**Muertos**: `implicit` (`response_type=token`) y ROPC (`password` grant) — eliminados en
OAuth 2.1 y desaconsejados por el BCP de seguridad (RFC 9700). Si aparecen en un diseño,
son un hallazgo, no una opción.

### Diseño de token

- `aud` obligatorio y **verificado por cada recurso**; un token válido para "todo" es una
  llave maestra. `iss`, `exp`, `nbf`/`iat` validados; `alg` contra allowlist explícita
  (RFC 8725): prohibido aceptar `alg` del token sin lista y prohibido `none`.
- TTL: access **5-15 min**; refresh **rotativo** con detección de reutilización (reusar un
  refresh revoca toda la familia). En clientes públicos la rotación no es opcional.
- Revocación (RFC 7009) + propagación por CAEP/SSF. Asume que revocar un JWT no surte
  efecto hasta `exp`: el TTL **es** tu latencia de revocación, dimensiónalo con eso.
- `scope` de grano fino y nombrado por recurso+acción (`invoices:read`), nunca `admin:all`
  ni comodines. Los permisos por objeto no viven en el token: se consultan al PDP.
- Claims de autorización en el token solo si son estables y de baja cardinalidad; roles
  dinámicos en el token = permisos obsoletos durante todo el TTL.

### Sesión y logout

- Cookie de sesión del BFF: prefijo `__Host-`, `HttpOnly`, `Secure`, `SameSite=Lax`
  (`Strict` si el flujo lo permite), sin `Domain`. Rotación del identificador de sesión al
  autenticar y al elevar privilegios.
- Logout: **RP-Initiated Logout** (trigger de usuario) + **Back-Channel Logout** (efectivo
  servidor a servidor). Las cuatro specs de logout de OIDC son Final Specifications desde
  septiembre de 2022; **Session Management 1.0** (iframe + polling) es inservible con las
  restricciones de cookies de terceros: no lo uses como único mecanismo.
- Timeout de inactividad **y** absoluto definidos por nivel de riesgo; re-autenticación
  (`prompt=login`, `max_age`) antes de operaciones sensibles (pagos, cambio de MFA, alta de
  credenciales).

### Passkeys y política de MFA

- Passkey/WebAuthn por defecto. WebAuthn **Level 3** fue propuesto a W3C Recommendation el
  20-jul-2026 (CR de 26-may-2026); comprueba su estado antes de citar la versión.
- NIST SP 800-63B-4: AAL2 debe **ofrecer** una opción resistente a phishing; AAL3 exige
  autenticador resistente a phishing con clave **no exportable** → una passkey sincronizada
  llega como mucho a AAL2, y los administradores necesitan llave device-bound (FIDO2
  hardware) o autenticación por certificado.
- Atestación: no la exijas en aplicaciones públicas (empuja al usuario a métodos peores,
  como SMS OTP); en flotas corporativas sí es razonable exigir device-bound.
- Portabilidad resuelta: FIDO **CXF** (formato, Proposed Standard) y **CXP** (transporte
  cifrado) ya desplegados en iOS y en Android 14+ con Play Services 26.21+. El bloqueo por
  proveedor ya no es argumento para no adoptar passkeys.

### Autorización

- **RBAC** para el eje organizativo (roles por dominio, no por persona), **ABAC** para
  condiciones (tenant, sensibilidad del dato, hora, red, postura del dispositivo),
  **ReBAC** (modelo Zanzibar: OpenFGA, SpiceDB) cuando la pregunta real es "¿qué relación
  tiene este sujeto con este objeto?" (jerarquías, compartición, herencia).
- PDP centralizado (decisión) + PEP en cada servicio (aplicación). **Deny by default**. El
  frontend oculta opciones; **no autoriza**.
- El modelo de autorización es código versionado con tests (§4) y su decisión es auditable:
  sujeto, acción, objeto, resultado, política y versión de política.
- Multi-tenant: el `tenant` se deriva del token/contexto, **jamás** de un parámetro de la
  petición.

### Identidad de carga de trabajo y federación

- Entre servicios: SVID de SPIFFE/SPIRE (X.509 para mTLS, JWT-SVID para APIs). Cero
  secretos estáticos de larga vida entre servicios.
- Federación OIDC hacia cloud (CI, K8s): condiciones **exactas por claim**. En GitHub
  Actions usa `repository_id`, `job_workflow_ref` y `environment`; un `sub` con comodín
  requiere `StringLike` (con `StringEquals` un `*` se compara literal y nunca casa, lo que
  suele "arreglarse" ampliando permisos).
- GitHub emite **subject claim inmutable** (IDs numéricos con `@`) en repos creados,
  renombrados o transferidos desde el **15-jul-2026**: si `AssumeRoleWithWebIdentity` falla
  tras un rename, se corrige la condición — **nunca** se ensancha el comodín.

```jsonc
// Trust policy: lo mínimo aceptable (ni sub con comodín, ni ausencia de sub)
"Condition": {
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
    "token.actions.githubusercontent.com:repository_id": "123456789",
    "token.actions.githubusercontent.com:environment": "production"
  },
  "StringLike": {
    "token.actions.githubusercontent.com:job_workflow_ref": "org/infra-workflows/.github/workflows/deploy.yml@refs/heads/main"
  }
}
```

### Ciclo joiner-mover-leaver

- Fuente de verdad única (RRHH → IdP). Alta, cambio y **baja** propagados por SCIM el mismo
  día; la desprovisión no espera al ciclo trimestral.
- Recertificación: accesos privilegiados **trimestral**, resto semestral o anual, con
  evidencia y revocación efectiva de lo no confirmado (ISO 27001:2022 A.5.15/A.5.16/A.5.17/
  **A.5.18**; NIST SP 800-53 AC-2/AC-5/AC-6).
- Cuentas de servicio: propietario nombrado, caducidad, rotación y revisión; sin cuentas
  humanas compartidas.
- **Integraciones SaaS/OAuth de terceros**: inventario de connected apps, scopes mínimos,
  revisión periódica y revocación inmediata en incidente. En la campaña UNC6395 contra
  tokens OAuth de Salesloft Drift (8-18 ago 2025, 700+ organizaciones) no hubo malware ni
  bypass de MFA: bastaron tokens válidos y APIs legítimas.

### PAM, JIT y break-glass

- **Cero acceso permanente a producción**: elevación JIT con aprobación, ventana corta,
  motivo registrado y grabación de sesión. Credenciales efímeras (certificados SSH/DB de
  minutos), no contraseñas guardadas.
- Break-glass: **≥2 cuentas**, credenciales en custodia dividida/física, método MFA
  **distinto** del habitual (FIDO2 o cert-based), excluidas de las políticas de acceso
  condicional pero **no** exentas de la MFA obligatoria de plataforma (Entra la impone a
  nivel de aplicación cliente, con independencia de las exclusiones de CA), alerta en cada
  uso y **prueba periódica documentada**. Un break-glass no probado no existe.

## 4. Calidad y testing (gates de CI)

1. **Tests negativos de token** (obligatorios, rompen el build): expirado, `aud` ajena,
   firma inválida, `alg` manipulado y `none`, `iss` distinto, `kid` desconocido, replay del
   `code`, PKCE ausente o `code_verifier` incorrecto, `redirect_uri` no coincidente exacta,
   refresh reutilizado (debe revocar la familia).
2. **Política como código con tests**: OpenFGA/Cedar/OPA traen runner de pruebas. Casos de
   permiso **y** de denegación, incluyendo cross-tenant. Política sin test = política sin
   revisar.
3. **Escaneo de confianza federada**: linter/policy que falle ante `sub` con comodín
   amplio, ausencia de condición `sub`/`aud`, o `StringEquals` con `*` en trust policies.
4. **Secret scanning** de tokens y client secrets en repos y logs (el escáner lo fija
   `secrets-management-standards`, igual que el procedimiento de rotación tras la fuga).
5. **Conformance** al implementar o parametrizar un OP/RP: pasar las suites de OpenID
   Certification antes de exponerlo, no después del incidente.
6. **Prueba de desprovisión**: test de integración que verifique que la baja en la fuente
   de verdad corta el acceso en los sistemas destino.

## 5. Seguridad

- Superficie del flujo: `redirect_uri` con **coincidencia exacta** (sin comodines ni
  sufijos), `state` y `nonce` verificados, parámetro `iss` en la respuesta (RFC 9207) para
  evitar mix-up entre varios IdP, PAR (RFC 9126) y/o JAR (RFC 9101) en perfiles de alto
  riesgo.
- **Consent phishing / device code phishing**: pantalla de consentimiento que nombre
  aplicación y datos, registro de clientes **controlado** (nada de dynamic client
  registration abierto), y alerta ante nuevos consentimientos de alto privilegio.
- **Robo de token**: bearer robado = acceso. Vincula (DPoP/mTLS) lo valioso, TTL corto,
  detección de uso anómalo (geo/UA/volumen) y revocación propagada.
- SAML (solo legacy): valida firma sobre `Response` **y** `Assertion`, `Audience`,
  `Recipient`, `Destination`, `InResponseTo`, `NotOnOrAfter`; rechaza aserciones sin firmar;
  vigila XML Signature Wrapping y canonicalización; metadatos y certificados de firma
  rotados con solapamiento.
- Enumeración de usuarios: respuestas y tiempos uniformes en login, registro y recuperación.
- Recuperación de cuenta: es el eslabón débil de toda la política de MFA — trátala con el
  mismo nivel (no vuelvas a SMS/email OTP para recuperar una cuenta con passkey).
- Contraseñas (cuando existan): hashing y política en `cryptography-pki-standards` y
  `appsec-standards`; aquí solo la regla — sin reglas de composición, sin caducidad
  periódica sin motivo, con comprobación contra listas de comprometidas.

## 6. Operabilidad

- **Eventos de autenticación como telemetría de primer nivel**: login ok/fallido, MFA,
  cambio de método, consentimientos, emisión/refresh/revocación de tokens, uso de
  break-glass y cambios de rol. Logs íntegros y retenidos para forensics; alerta sobre
  patrones (fuerza bruta distribuida, MFA fatigue, uso de break-glass, alta de credencial en
  cuenta privilegiada).
- **JWKS**: caché por `kid` respetando TTL, tolerancia a rotación (publica la clave nueva
  antes de firmar con ella, retira la vieja después), y sin ir al endpoint en cada petición.
  Fallo del JWKS = **fail-closed**.
- **El IdP es SPOF**: HA multi-AZ, capacidad dimensionada para el pico de login, DR
  ensayado y plan de degradación (qué sigue funcionando con el IdP caído y por cuánto).
- **SSF/CAEP** (SSF 1.0, CAEP 1.0 y RISC 1.0 aprobadas como Final Specifications el
  2-sep-2025; perfil de interoperabilidad CAEP en revisión final hasta el 25-sep-2026) para
  propagar revocación y cambios de riesgo en tiempo real entre proveedores.
- Rate limiting y protección anti-automatización en `/token`, `/authorize`, login y
  recuperación.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisa versión y CVEs del IdP al menos trimestralmente; los IdP y sistemas
  IGA autoalojados reciben avisos críticos con frecuencia (p. ej. Apache Syncope publicó en
  julio de 2026 parches para seis vulnerabilidades, incluida la escalada de privilegios
  CVE-2026-62183, sin hotfixes binarios: obligan a actualizar o recompilar).
- Sigue el estado de las specs, no la memoria: OAuth 2.1 **seguía siendo Internet-Draft**
  (`draft-ietf-oauth-v2-1-15`, 2-mar-2026) en agosto de 2026, aunque su contenido ya es
  exigible vía RFC 9700 y los RFCs que consolida.
- Deuda a plazo fijo: cada excepción (cliente legacy con secreto estático, SAML, TOTP en
  admins) lleva fecha y ticket.

**PROHIBIDO**
- ❌ `implicit` y ROPC (`password` grant) en cualquier diseño nuevo.
- ❌ Tokens en `localStorage`/`sessionStorage` o en la URL; tokens en logs.
- ❌ `redirect_uri` con comodín o coincidencia por prefijo/sufijo.
- ❌ Aceptar `alg` del token sin allowlist; `alg: none`; no verificar `aud` o `iss`.
- ❌ Refresh tokens no rotativos en clientes públicos; access tokens de horas o días.
- ❌ Secretos estáticos de larga vida entre servicios o en CI (existe federación OIDC).
- ❌ Trust policies federadas con `sub` comodín (`repo:org/*`, `:*`) o sin condición de `sub`.
- ❌ Cuentas humanas compartidas, admins permanentes, y break-glass sin prueba periódica.
- ❌ SMS/voz/email OTP como factor de cuentas privilegiadas.
- ❌ Autorización decidida en el frontend o duplicada ad-hoc en cada servicio.
- ❌ Dynamic client registration abierta a internet sin control ni revisión.
- ❌ Desprovisión manual o diferida al ciclo de auditoría.
- ❌ Sincronizar contraseñas entre sistemas en vez de federar identidad.

### Checklist de revisión rápida

- [ ] Flujo correcto por tipo de cliente, PKCE presente, `redirect_uri` exacta, `state`/`nonce` verificados.
- [ ] Token con `aud` verificada, `alg` en allowlist, TTL corto, refresh rotativo, revocación con plan.
- [ ] MFA resistente a phishing; passkeys; admins con clave device-bound; recuperación al mismo nivel.
- [ ] Authz centralizada, deny-by-default, tenant derivado del token, decisiones auditadas y con tests.
- [ ] Identidad de carga sin secretos; condiciones federadas por claim exacto.
- [ ] SCIM con desprovisión el mismo día; recertificación con evidencia; connected apps inventariadas.
- [ ] JIT con aprobación y grabación; break-glass ≥2 con MFA independiente, alertado y probado.
- [ ] Eventos de auth en el SIEM; JWKS cacheada y fail-closed; IdP con HA y DR ensayado.

## 8. Verificación web obligatoria

Antes de fijar versión, estado de spec o comportamiento en un entregable:

1. **OAuth 2.1**: estado en el datatracker del IETF (¿sigue Internet-Draft o ya es RFC?) y
   revisión vigente; también el BCP de aplicaciones basadas en navegador
   (`draft-ietf-oauth-browser-based-apps`) y FAPI 2.0 si aplica al perfil.
2. **Versiones y EOL de tu IdP** (Keycloak, Authentik, Authelia, Zitadel, FreeIPA, Ory) y
   sus breaking changes de la última major, más CVEs abiertos del componente.
3. **WebAuthn Level 3**: ¿ya es W3C Recommendation? Estado de CXP/CXF y del soporte real en
   navegadores y plataformas.
4. **SSF/CAEP/IPSIE**: estado del perfil de interoperabilidad y qué soporta de verdad tu
   proveedor (lo publicado ≠ lo implementado).
5. **Motores de autorización**: versión y estado de OpenFGA, SpiceDB, Cedar y OPA (cambios
   de sintaxis/major que rompen políticas existentes) y de SPIRE.
6. **Formato de claims federados** del proveedor (GitHub, GitLab, K8s) antes de escribir
   condiciones: cambian y rompen despliegues.
7. **NIST SP 800-63B-4** y la guía de MFA resistente a phishing vigente, si hay requisito
   de cumplimiento.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
