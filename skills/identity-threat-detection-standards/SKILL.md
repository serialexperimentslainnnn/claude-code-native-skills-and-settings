---
name: identity-threat-detection-standards
description: ITDR — detecting and responding to attacks against identity itself, which is where the perimeter actually is. Use when investigating or defending against password spraying, adversary-in-the-middle session-cookie theft and token replay that survives MFA, refresh-token and primary-refresh-token abuse, MFA fatigue and push bombing, consent phishing and malicious OAuth application grants, device-code-flow phishing, SIM swapping, forged federation assertions (Golden SAML, stolen token-signing certificate, cross-tenant trust abuse), credentials or certificates silently added to an existing application or service principal, illicit device registration, hybrid identity attack paths through directory synchronization and authentication agents in both directions, deciding which identity telemetry you actually retain and what your licence tier silently drops, writing high-value identity detections and their triage, and identity-specific containment where revoking sessions, refresh tokens and consents matters far more than resetting a password. Also covers emergency access accounts and administrative tiering as they are watched, not as they are designed.
---

# Estándares de detección y respuesta ante amenazas de identidad (ITDR)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **el ataque contra la identidad, su detección y su respuesta**: por qué la identidad es
el vector dominante y con qué evidencia se sostiene eso; las clases de ataque características y
cómo se ven en los registros; qué telemetría hace falta y qué se pierde según licencia; las
detecciones que de verdad valen; y la contención específica de identidad, que **no es cambiar la
contraseña**. Incluye la vigilancia de las cuentas de emergencia y del nivel administrativo, no su
diseño.

Triggers: "cuenta comprometida", "inicio de sesión imposible", "pulverización de contraseñas",
"password spraying", "relleno de credenciales", "AiTM", "adversario en el medio", "robo de cookie
de sesión", "replay de token", "token robado", "refresh token robado", "PRT", "fatiga de MFA",
"bombardeo de notificaciones", "MFA push bombing", "consent phishing", "aplicación OAuth
maliciosa", "concesión de consentimiento", "device code phishing", "flujo de código de
dispositivo", "SIM swapping", "Golden SAML", "certificado de firma de tokens", "confianza entre
tenants", "federación añadida al dominio", "credencial añadida a la aplicación",
"`addPasswordCredential`", "`addKeyCredential`", "service principal con secreto nuevo",
"registro de dispositivo no reconocido", "método de MFA añadido por el atacante", "regla de
reenvío de correo creada", "sincronización de hash", "PTA", "agente de autenticación",
"Entra Connect comprometido", "revocar sesiones", "ITDR".

**Principio rector**: **la identidad es hoy el perímetro, y un atacante que se autentica no está
explotando nada: está usando el sistema como fue diseñado.** De ahí las tres consecuencias que
ordenan el documento:

1. **La MFA no es una frontera, es un peaje**: se paga una vez y lo que sale del otro lado —una
   cookie de sesión, un token de actualización— **es una credencial portátil que ya no vuelve a
   pedir MFA**. Robado el artefacto post-autenticación, la MFA es irrelevante (§3.2).
2. **No hay malware que buscar.** El ataque de identidad deja como única huella un registro de
   inicio de sesión, uno de auditoría y uno de consentimiento. Sin esa telemetría retenida no hay
   investigación posible — y **el nivel de licencia decide cuánta hay** (§3.5).
3. **Restablecer la contraseña no expulsa a nadie.** Una contraseña nueva no invalida una cookie
   robada ni un token de actualización vivo. La respuesta correcta revoca, y en un orden concreto
   (§3.7).

**Postura estrictamente defensiva y autorizada.** Las técnicas se describen como **clase de
riesgo, evidencia observable y control**, nunca como procedimiento reproducible. Aquí no hay
payloads, ni herramientas de ataque parametrizadas, ni pasos de explotación.

**No aplica**: ver `identity-access-management-standards` (**frontera dura y la más importante de
esta skill**: **la arquitectura de identidad es suya, sin excepción** — elección de IdP, flujos
OAuth 2.1/OIDC y su diseño, SAML, passkeys/WebAuthn, **política de MFA y de acceso condicional**,
SCIM y el ciclo joiner-mover-leaver, motores de autorización, PAM/JIT, **diseño** de las cuentas
break-glass, identidad de carga de trabajo. **Aquí**: cómo se ataca todo eso, cómo se ve en los
registros, qué se detecta y qué se hace cuando pasa. Regla de arbitraje en una línea: *si la
pregunta es "cómo lo configuro", es suya; si es "cómo sé que me lo están rompiendo y qué hago", es
de aquí*), `detection-engineering-standards` (**la regla es suya**: autoría en Sigma/KQL, tests,
umbrales, tuning, cobertura ATT&CK, despliegue en el SIEM y normalización del esquema. **Aquí, qué
hipótesis de identidad merece regla y por qué** — la regla nace aquí y se gobierna allí),
`soc-operations-standards` (turno, cola, triaje, escalado y cierre de la alerta que esto genera),
`incident-response-forensics-standards` (**el incidente confirmado y su investigación**: alcance,
adquisición, timeline, erradicación y reconstrucción; **aquí solo la contención específica de
identidad y por qué su orden importa**), `windows-server-ad-standards` (**el dominio en sí**:
bosque, GPO, Kerberos/NTLM, `krbtgt`, AD CS, Tier 0/PAW, delegación, higiene del directorio y
recuperación del bosque. **Aquí solo el puente**: cómo un compromiso en el directorio se convierte
en compromiso del tenant en la nube y al revés), `azure-standards`/`aws-standards`/`gcp-standards`
(**la configuración del tenant y de su IAM de plataforma**: acceso condicional, PIM, gobernanza,
políticas y condiciones. Aquí, su abuso), `cloud-security-posture-standards` (**hermana**:
el permiso excesivo **en frío** —derecho efectivo, comodines, caminos de ataque por permisos—;
**aquí el uso indebido en caliente** de una identidad legítima), `endpoint-security-standards`
(**el puesto y su EDR**: el infostealer que roba la cookie del navegador se detiene y se detecta
allí; **aquí lo que pasa después con esa cookie**), `email-security-standards` (el correo como
canal de entrega del phishing; aquí la consecuencia sobre la identidad),
`threat-intelligence-standards` (el actor, el indicador y su caducidad),
`vulnerability-management-standards` (CVE y SLA de parcheo — **el permiso y el token robado no
tienen CVE**), `secrets-management-standards` (custodia y rotación del secreto de aplicación; aquí
la detección de que alguien le ha **añadido** uno nuevo), `mobile-standards` (el dispositivo),
`grc-compliance-standards` (obligación de notificar y evidencia), `privacy-engineering-standards`
(dato personal dentro de los registros de inicio de sesión: base legal y retención),
`offensive-security-standards` (simulación autorizada de estos ataques, con alcance por escrito).

## 2. Decisiones por defecto

> Verificar la última versión y el nombre exacto de cada capacidad por web antes de fijarla (§8).

| Decisión | Por defecto | Alternativa justificable / matiz |
|---|---|---|
| Fuente primaria de detección | **Registros de inicio de sesión + auditoría del IdP**, exportados a almacenamiento propio desde el día 1 | Ninguna. Sin export, la retención por defecto te deja ciego (§3.5) |
| Retención de telemetría de identidad | **≥ 12 meses en caliente o accesible** | Menos, solo con análisis explícito de qué investigación se renuncia a poder hacer |
| Detección de riesgo del propio IdP | Activada y **enviada al SIEM**, tratada como una fuente más | No como única fuente: es una caja negra propietaria y sin *tuning* real |
| Contención de cuenta comprometida | **Revocar sesiones y tokens de actualización → invalidar consentimientos → rotar credenciales → después la contraseña** | El orden inverso deja al atacante dentro (§3.7) |
| Cuentas de emergencia | **Excluidas de las políticas que pueden bloquearte, y con alerta ante cualquier uso** | Ninguna. Su uso no anunciado es siempre incidente |
| Flujo de código de dispositivo | **Bloqueado por política salvo excepción documentada por aplicación** | Permitido solo donde hay dispositivos sin teclado reales |
| Aplicaciones OAuth de terceros | **Consentimiento de usuario deshabilitado o restringido a editores verificados y permisos de bajo impacto** | Flujo de aprobación por administrador si el negocio lo exige |
| Vinculación del token al dispositivo | **Activar donde exista** (protección de token / vinculación criptográfica) | Piloto primero: la cobertura por cliente y recurso es parcial (§3.7) |
| Identidades de servicio en la nube | **Federación / identidad gestionada**; credencial estática solo con caducidad corta y vigilada | Ninguna otra |

## 3. Estructura y convenciones

### 3.1 La evidencia, y qué es folclore

Sostener "la identidad es el vector dominante" con cifras exige método. Lo verificable a agosto de
2026:

- **Verizon DBIR 2025**: el abuso de credenciales figura como vector de acceso inicial en el
  **22 %** de las brechas, seguido de la explotación de vulnerabilidades (20 %). **El denominador
  no son todas las brechas**: es el subconjunto con vector conocido excluyendo error y uso indebido
  (n=9.891 sobre 12.195 brechas confirmadas). El propio informe advierte de **trasvase entre las
  categorías de credencial y de phishing**, porque a menudo no se puede determinar de dónde salió
  la credencial. Y el DBIR **no es una muestra probabilística**: es la casuística de Verizon más
  contribuciones voluntarias, con lista de contribuidores cambiante entre años y sin intervalos de
  confianza. **Lectura defendible: el abuso de credenciales está consistentemente entre los dos
  primeros vectores.** Lectura indefendible: "el 22 % de las brechas son por credenciales" como
  parámetro poblacional. (Verificar la edición 2026 antes de citar cifras: §8.)
- **Lo que hay que dejar de citar**: **"la MFA bloquea el 99,9 % de los ataques"**. Origen: entrada
  del blog de seguridad de Microsoft de agosto de 2019. El dato subyacente **no era un experimento
  controlado** sino una razón observacional —*más del 99,9 % de las cuentas comprometidas no tenían
  MFA*— tomada cuando la adopción empresarial de MFA rondaba el 11 %: con esa base, casi cualquier
  cuenta comprometida carecería de MFA aunque la MFA no hiciera nada. El propio Microsoft publicó
  después un estudio con estimación más conservadora (**reducción de riesgo del 99,22 %**, y 98,56 %
  en casos de credencial filtrada) y su documentación actual usa **"más del 99,2 % de los ataques de
  compromiso de cuenta"**, no el 99,9 %. Además el enunciado se ha ido ensanchando al citarse: de
  "ataques de compromiso de cuenta" a "ciberataques" en general. **Cita el 99,2 % con su fuente, o
  no cites porcentaje: el argumento —la MFA elimina de golpe el ataque automatizado masivo— no lo
  necesita.**
- **"El 82 % de las brechas implican el factor humano"** y similares: son cifras de informes anuales
  con la misma limitación muestral, y cambian de año y de definición. **No se citan sin edición,
  denominador y definición de "factor humano".** Aquí no se escribe ninguna.
- Regla general de esta skill: **cifra sin metodología publicada = no se escribe**. Desmentirla vale
  más que repetirla.

### 3.2 Por qué la MFA no cierra el caso: el artefacto post-autenticación

Lo que el atacante quiere ya no es la contraseña, es lo que viene después:

- **Cookie de sesión** de la aplicación: la emite y la controla **la aplicación**, no el IdP. El IdP
  no puede revocar una sesión que él no gobierna; solo la aplicación puede invalidarla, cuando
  decide revalidar.
- **Token de actualización** (*refresh token*): la llave maestra. Larga vida —por defecto del orden
  de **90 días** en las plataformas mayoritarias—, permite acuñar tokens de acceso nuevos en
  silencio y **sobrevive a un cambio de contraseña** en varios escenarios.
- **Token de actualización primario (PRT)** en escenarios de dispositivo unido: se invalida con el
  cambio de contraseña **solo si la contraseña se usó para obtenerlo**. Los obtenidos por método sin
  contraseña (aplicación autenticadora, FIDO2) **sobreviven**.
- **Token de acceso**: normalmente ~1 hora de vida y **no revocable** por defecto. Ese es el suelo
  del tiempo de contención salvo que el recurso soporte evaluación continua de acceso.

Consecuencia operativa que hay que tener escrita antes del incidente: **entre el "he restablecido
la contraseña" y "el atacante ha perdido el acceso" puede haber horas, y si solo se restableció la
contraseña, puede no perderlo nunca.**

### 3.3 Catálogo de ataque: qué es, qué deja y qué lo corta

Cada entrada = **mecanismo → evidencia observable → control**. Sin procedimiento.

- **Pulverización de contraseñas** (una contraseña común contra muchas cuentas, por debajo del
  umbral de bloqueo). Evidencia: muchos fallos con **el mismo código de error** repartidos entre
  **muchos usuarios distintos** desde pocos orígenes, a menudo contra puntos finales de
  autenticación heredados que no soportan MFA. Control: eliminar la autenticación heredada,
  bloqueo inteligente, listas de contraseñas prohibidas, y detección **por cuentas distintas
  tocadas por origen**, no por fallos por cuenta.
- **Relleno de credenciales**: mismo patrón, credenciales reales de filtraciones. Evidencia
  adicional: **tasa de éxito no nula** en el mismo lote.
- **AiTM (adversario en el medio)**: proxy inverso que retransmite el inicio de sesión legítimo y se
  queda la cookie post-MFA. **La MFA se completa de verdad** — por eso el registro muestra un inicio
  de sesión correcto con MFA satisfecha. Evidencia: sesión reproducida desde otra IP/ASN/geografía
  poco después, cambio brusco de agente de usuario, y casi siempre **un nuevo método de MFA
  registrado o una regla de reenvío de correo creada** en los minutos siguientes. Control real:
  **credenciales resistentes a phishing (passkeys/FIDO2), cumplimiento de dispositivo y vinculación
  del token al dispositivo** — no "más MFA".
- **Robo de token por infostealer**: sin proxy y sin phishing. El malware extrae cookies y tokens
  cacheados del perfil del navegador. Evidencia: uso de token válido desde un origen nuevo sin
  evento de autenticación interactiva previo. Control: es un problema de puesto
  (`endpoint-security-standards`) con consecuencia de identidad; aquí, detectar el uso anómalo y
  revocar.
- **Fatiga de MFA / bombardeo de notificaciones**: el atacante ya tiene la contraseña y repite el
  intento hasta que la víctima aprueba por agotamiento. Evidencia: ráfaga de peticiones de MFA
  denegadas seguida de una aprobación. Control: **coincidencia de números y contexto en la
  notificación** (deja de ser "aprobar/denegar"), límite de intentos, y **la denegación repetida es
  una alerta por sí misma**.
- **Consent phishing y aplicaciones OAuth maliciosas**: no se roba credencial, se **pide permiso**.
  La víctima consiente y la aplicación obtiene acceso duradero al correo o a los ficheros **sin
  contraseña y sin MFA**; cambiar la contraseña no lo revoca. Evidencia: eventos de concesión de
  consentimiento a aplicaciones no vistas, editor no verificado, permisos amplios de lectura de
  correo o ficheros. Control: restringir el consentimiento de usuario, flujo de aprobación,
  **revisión periódica de aplicaciones consentidas** y alerta ante toda concesión nueva de alto
  impacto.
- **Phishing del flujo de código de dispositivo**: se abusa de un flujo estándar de OAuth pensado
  para dispositivos sin teclado. **La víctima se autentica en la página legítima del proveedor**, así
  que no hay dominio falso que detectar ni proxy que interceptar, y los controles de red no disparan.
  Documentado públicamente en campañas desde 2024–2025 y con oleadas posteriores que encadenan el
  token obtenido con **registro de un dispositivo del atacante** para conseguir un PRT. Control
  principal y casi único: **bloquear el flujo por política** donde no haga falta.
- **SIM swapping**: la MFA por SMS y la recuperación por teléfono se transfieren con el número.
  Control: **eliminar SMS y llamada como factor y como vía de recuperación** para cualquier cuenta
  privilegiada; el resto es mitigación.
- **Ataques a la federación (clase "Golden SAML")**: con la **clave de firma de tokens** del
  proveedor de identidad federado, el atacante **fabrica aserciones válidas para cualquier usuario**,
  con las reclamaciones que quiera —incluida la de haber hecho MFA—. No hay autenticación que
  observar: **el registro del IdP muestra un inicio de sesión perfecto**. Es el caso extremo de "el
  compromiso de la infraestructura de identidad no se detecta en el flujo de inicio de sesión".
  Detección: correlacionar con el lado del origen (uso del certificado, acceso al material de firma,
  emisión sin evento correspondiente en el proveedor federado), vigilar **cambios en la
  configuración de federación del dominio y en las confianzas entre tenants** —añadir un dominio
  federado o una confianza es un evento de auditoría de máxima prioridad— y tratar el servidor de
  federación como **Tier 0** (eso es de `windows-server-ad-standards`).
- **Persistencia por credencial añadida a una aplicación**: el atacante no crea una cuenta nueva
  —eso se ve—; **añade un secreto o un certificado a una aplicación o principal de servicio ya
  existente y legítimo**, y a partir de ahí se autentica como esa aplicación, sin usuario, sin MFA y
  sin acceso condicional que aplique. Es la persistencia más limpia del ecosistema. Evidencia:
  eventos de auditoría de adición de credencial a aplicación/principal de servicio, concesión de
  permisos nuevos a una aplicación existente, asignación de roles a un principal de servicio.
  **Detección obligatoria, sin excepciones.**
- **Registro ilícito de dispositivo** y **adición de método de MFA**: ambos convierten un acceso
  temporal en acceso duradero. Alerta por defecto.
- **Identidad híbrida, el puente en los dos sentidos**: el servidor de sincronización de directorio
  y los agentes de autenticación (sincronización de hash, autenticación de paso, SSO fluido) tienen,
  por diseño, **credenciales o posición privilegiada en ambos lados**. Comprometido el servidor de
  sincronización, se llega al tenant; comprometido el tenant con los privilegios adecuados, se puede
  actuar sobre lo local. **Consecuencia dura: si tienes identidad híbrida, tu Tier 0 incluye el
  tenant de nube, y el alcance de un compromiso de AD incluye la nube — y al revés.** Estos
  servidores no son "servidores de aplicación": son infraestructura de identidad.
- **Abuso de identidades de servicio y de carga de trabajo**: sin MFA posible, sin usuario que note
  nada, a menudo con permisos excesivos heredados. Su vigilancia es **por comportamiento**: origen
  nuevo, horario nuevo, API nunca antes llamada, volumen anómalo.

### 3.4 Detecciones de alto valor (qué merece regla; escribirla es de `detection-engineering`)

Por orden de relación valor/ruido:

1. **Credencial o certificado añadido a una aplicación o principal de servicio**, y concesión de
   permisos de alto impacto a una aplicación.
2. **Cambio en la configuración de federación de un dominio, en el material de firma o en las
   confianzas entre tenants.**
3. **Uso de una cuenta de acceso de emergencia** (cualquier uso, siempre).
4. **Consentimiento concedido a una aplicación nueva** con permisos de correo, ficheros o
   directorio.
5. **Método de MFA añadido / registro de dispositivo nuevo** poco después de un inicio de sesión
   desde origen infrecuente.
6. **Regla de reenvío o de manipulación de bandeja creada** tras un inicio de sesión anómalo (señal
   clásica de compromiso de correo, y de las de mayor precisión).
7. **Sesión usada desde un origen distinto al de la autenticación** (indicador de replay), y token
   usado sin evento de autenticación interactiva previo.
8. **Ráfaga de MFA denegadas seguida de aprobación.**
9. **Pulverización**: N cuentas distintas fallando con el mismo error desde el mismo origen en una
   ventana.
10. **Autenticación heredada / sin MFA** contra cuentas privilegiadas: debería ser cero, y por eso
    cualquier evento es señal.
11. **Asignación de rol privilegiado** fuera del proceso, y elevación fuera de la ventana de
    aprobación.
12. **Identidad de servicio autenticándose desde una infraestructura nueva.**

Antipatrón declarado: **"inicio de sesión imposible" como alerta principal**. Es la detección más
famosa y una de las peores en solitario: la VPN, el móvil y el roaming la disparan constantemente, y
un atacante con un proxy en la misma ciudad no la dispara nunca. Sirve como **enriquecimiento**, no
como caso.

### 3.5 Telemetría, y lo que la licencia se lleva por delante

**Dato que decide la arquitectura y que el fabricante no destaca.** Verificado verbatim en la
documentación de Microsoft (`reference-reports-data-retention`, revisión de enero de 2026):

| Informe | Entra ID Free | Entra ID P1 | Entra ID P2 |
|---|---|---|---|
| Registros de auditoría | **7 días** | 30 días | 30 días |
| Inicios de sesión | **7 días** | 30 días | 30 días |
| Inicios de sesión de riesgo | 7 días | 30 días | **90 días** |

Además, en esa misma referencia: los registros de actividad de Microsoft Graph **solo están
disponibles con P1 y P2** y no se retienen salvo que se archiven; y **el cambio de retención no es
retroactivo** — al subir de nivel solo se conserva lo que aún estaba dentro de la ventana anterior.

Consecuencias, y son las que hay que llevar a la reunión de presupuesto:
- **Una investigación de identidad típica se descubre semanas después del acceso inicial.** Con 7 o
  30 días de retención nativa, la evidencia **ya no existe** cuando llega la pregunta. No es un
  problema de herramienta: es un problema de contrato.
- **La exportación continua a almacenamiento propio (SIEM o almacenamiento barato) no es opcional**,
  y es lo primero que se configura en un tenant nuevo. Cuesta poco y es irrecuperable a posteriori.
- **La capacidad de detección también está por niveles**: las detecciones de riesgo posteriores a la
  autenticación (sesión anómala, token anómalo) viven en los niveles altos. Comprar el nivel bajo y
  esperar detección de robo de token es un error de expectativa, no de configuración.
- Esta tabla es de un proveedor concreto por ser el mejor documentado; **el patrón se repite en los
  demás**: la telemetría fina de identidad se vende aparte. **Verificar en tu proveedor qué registro
  existe, cuánto dura y qué nivel hace falta, antes de diseñar la detección** (§8).

Mínimos de telemetría, con independencia del proveedor: inicios de sesión (interactivos **y no
interactivos** — los no interactivos son donde vive el abuso de token), auditoría del directorio,
**consentimientos y cambios en aplicaciones y principales de servicio**, emisión y actualización de
token, registro de dispositivos y de métodos de autenticación, y cambios de configuración de
federación.

### 3.6 Cuentas de emergencia y nivel administrativo (lo que aquí se vigila)

El **diseño** es de `identity-access-management-standards`; **la vigilancia es de aquí**:
- Al menos **dos cuentas de acceso de emergencia**, en la nube, sin dependencia del directorio local
  ni del servidor de federación, **excluidas de las políticas que podrían dejarte fuera**, con
  credencial resistente a phishing custodiada fuera de banda. **Excluirlas del acceso condicional es
  el motivo por el que su uso debe alertar siempre**: son las únicas identidades sin red de
  seguridad.
- **Prueba periódica documentada** de que funcionan. Una cuenta de emergencia que nadie ha probado
  es un plan de continuidad no ensayado.
- **Separación por niveles**: la cuenta que administra la identidad no navega, no lee correo y no se
  usa desde un puesto de uso general. Aquí se vigila la violación de esa regla —administración desde
  un dispositivo no conforme, elevación fuera de proceso— y **eso es una detección**, no una
  observación de auditoría.

### 3.7 Respuesta específica de identidad

**Un cambio de contraseña no invalida una cookie robada.** Orden de contención, y el orden importa:

1. **Revocar los tokens de actualización y las sesiones** de la identidad (en la plataforma de
   Microsoft, la acción de revocación de sesiones invalida los tokens de actualización y las
   cookies del navegador, moviendo la marca temporal de validez de la sesión). **Primero esto**,
   porque el token de actualización es la llave que reemite todo lo demás.
2. **Revisar y revocar consentimientos de aplicaciones y credenciales añadidas**: si el atacante
   dejó una aplicación consentida o un secreto en un principal de servicio, los pasos 1 y 3 no le
   afectan en absoluto. **Este es el paso que más se olvida y el que deja al atacante dentro.**
3. **Eliminar métodos de MFA y dispositivos registrados por el atacante.**
4. **Cambiar la contraseña** y forzar reinscripción del factor.
5. **Revisar reglas de correo, delegaciones y permisos de buzón** creadas durante la ventana.
6. **Rotar cualquier secreto al que esa identidad tuviera acceso** (frontera con
   `secrets-management-standards`).

Advertencias operativas que hay que conocer **antes** del incidente:
- **La revocación no es instantánea.** Hay propagación de minutos, y **los tokens de acceso ya
  emitidos siguen valiendo hasta caducar** (típicamente ~1 hora) salvo que el recurso soporte
  **evaluación continua de acceso**. Con esa evaluación, la revocación es casi en tiempo real, con
  latencia documentada de **hasta ~15 minutos** por propagación de eventos; **los clientes y
  recursos que no la soportan quedan fuera**, y ahí el suelo vuelve a ser la vida del token.
- **Matiz contraintuitivo**: en sesiones con evaluación continua la vida del token **se alarga**
  (hasta el orden de 28 horas) porque la revocación pasa a depender de eventos, no del reloj. Un
  token largo replicado contra una ruta que no evalúa continuamente es un problema, no una mejora.
- **Las sesiones de aplicación las cierra la aplicación**, no el IdP. Cerrar la sesión del IdP no
  garantiza cerrar todas las de abajo. Hay que enumerarlas.
- **Cuentas federadas y usuarios externos**: la revocación en tu tenant no gobierna su tenant de
  origen. Coordinación explícita.
- **Si hay sospecha de compromiso de la infraestructura de identidad** (servidor de federación,
  servidor de sincronización, material de firma), **la contención por cuenta no sirve**: hay que
  asumir emisión arbitraria de identidad y escalar a la rotación del material de firma y a la
  reconstrucción — territorio de `incident-response-forensics-standards` y
  `windows-server-ad-standards`.
- **No avisar a la cuenta comprometida por el canal comprometido.** Si el atacante está en el
  correo, lee la notificación.

## 4. Calidad y testing

- **Toda detección de identidad se valida con la actividad real que dice detectar**, en un tenant de
  pruebas o con ejercicio autorizado y **deconflictado** con el SOC. Una regla de pulverización que
  nadie ha disparado no está probada.
- **Ensayo de la respuesta**: cronometrar de extremo a extremo "detección → revocación efectiva →
  confirmación de que el token ya no sirve". **Ese número es el SLA real**, y casi siempre sorprende.
- **Prueba de cobertura de revocación**: verificar por aplicación cuáles honran la revocación
  rápidamente y cuáles no. La lista resultante es un entregable de riesgo.
- **Prueba de las cuentas de emergencia** con cadencia fija y registro.
- **Prueba de telemetría**: generar un evento de cada tipo crítico (consentimiento, credencial
  añadida a aplicación, registro de dispositivo) y **comprobar que llega al SIEM con los campos
  necesarios**. Un evento que existe en el portal pero no se exporta no es telemetría.
- **Medición honesta**: precisión por regla, tiempo hasta contener, y **porcentaje de cuentas
  privilegiadas con credencial resistente a phishing** — esta última es la métrica que más mueve el
  riesgo y la más fácil de medir.

## 5. Seguridad del stack

- **Las herramientas de ITDR piden permisos sobre el directorio**, a menudo de lectura amplia y a
  veces de escritura para responder. Ese principal de servicio es un objetivo de primer orden y
  entra en la lista de §3.4.1: **quien pueda añadirle una credencial es administrador de tu
  identidad**. Permisos mínimos, revisión periódica, alerta ante su modificación.
- **El SIEM que recibe los registros de identidad contiene el mapa de quién es quién**: control de
  acceso propio y dato personal dentro (frontera con `privacy-engineering-standards`).
- **Ningún flujo de respuesta automática debe poder deshabilitar cuentas en masa** sin control
  humano: es un vector de denegación de servicio interno de manual.
- **La cuenta que opera ITDR se administra como Tier 0**, no como una cuenta de analista más.

## 6. Rendimiento y operabilidad

- **Volumen**: los inicios de sesión no interactivos son, con diferencia, el registro más voluminoso
  de un tenant grande, y **es justo donde vive el abuso de token**. No se recorta por coste sin
  decisión explícita y escrita.
- **Latencia de la telemetría**: los registros de identidad de las plataformas SaaS tienen retardo
  de minutos hasta decenas de minutos. **El tiempo de detección tiene ese suelo**, y prometer menos
  en un SLA es mentir.
- **Ruido esperable**: viajes, VPN, roaming móvil y despliegues automatizados. Se enriquece con
  contexto de identidad (rol, ventana de cambio, dispositivo conforme) antes de alertar; el turno y
  el triaje son de `soc-operations-standards`.
- **Coste**: la retención larga de identidad es barata comparada con la de red o endpoint y es la
  que más rinde por euro en investigación. Si hay que recortar, se recorta en otro sitio.

## 7. Sostenibilidad a largo plazo

- **Esta superficie cambia por producto, no por versión**: flujos nuevos de autenticación,
  capacidades nuevas de acceso condicional y clases de ataque nuevas aparecen entre trimestres.
  Revisión trimestral del catálogo de §3.3 y de las detecciones de §3.4.
- **Migración a credenciales resistentes a phishing como programa**, no como piloto perpetuo: es el
  único cambio que retira de un golpe familias enteras de esta lista (AiTM, fatiga de MFA,
  pulverización con éxito).
- **Revisión periódica de aplicaciones consentidas y de credenciales de principales de servicio**:
  crecen solas y nadie las retira. Caducidad obligatoria en secretos de aplicación.

**PROHIBIDO**:
- ❌ Cerrar un incidente de identidad **solo con un cambio de contraseña**.
- ❌ Revocar sesiones y **no revisar consentimientos ni credenciales añadidas a aplicaciones**: es
  dejar la puerta de atrás abierta y creer que se ha cerrado.
- ❌ Tratar la MFA como control terminal, o presentar "MFA al 100 %" como si el riesgo de identidad
  estuviera resuelto.
- ❌ SMS o llamada como factor o vía de recuperación en cuentas privilegiadas.
- ❌ Citar **"la MFA bloquea el 99,9 % de los ataques"**, o cualquier porcentaje de informe anual
  sin edición, denominador y metodología (§3.1).
- ❌ Diseñar detección de identidad **antes** de confirmar qué registros existen, cuánto se retienen
  y qué nivel de licencia hacen falta.
- ❌ Depender de la retención nativa del proveedor sin exportación propia.
- ❌ "Inicio de sesión imposible" como detección principal.
- ❌ Cuentas de emergencia sin alerta de uso, sin prueba periódica o con dependencia del directorio
  local o del servidor de federación.
- ❌ Duplicar aquí el diseño de MFA, de acceso condicional o del ciclo de vida de la cuenta: es de
  `identity-access-management-standards`. Ni escribir aquí la regla de SIEM: es de
  `detection-engineering-standards`.
- ❌ Ejecutar simulaciones de estos ataques sin alcance y autorización por escrito, y sin
  deconfliction con el SOC. **Este documento no contiene procedimiento ofensivo y no debe
  ampliarse en esa dirección.**

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:
1. **Retención de registros por nivel de licencia** en tu proveedor de identidad, y qué señales
   requieren nivel superior. La tabla de §3.5 se transcribió verbatim de la documentación de
   Microsoft con revisión de enero de 2026; **cambia sin aviso** y es el dato que más decisiones
   condiciona.
2. **Nombre exacto y disponibilidad actual** de las capacidades citadas sin marca: vinculación de
   token al dispositivo, evaluación continua de acceso y su **cobertura por cliente y recurso**,
   restricción de consentimiento, bloqueo del flujo de código de dispositivo. La cobertura parcial
   es lo que decide si el control sirve.
3. **Vidas de token por defecto** (acceso, actualización, PRT) y **qué las invalida** en tu tenant:
   son las que fijan el suelo del tiempo de contención y han cambiado históricamente.
4. **Campañas y avisos vigentes** sobre phishing de código de dispositivo, robo de token y abuso de
   aplicaciones OAuth: el patrón se mueve rápido. Preferir avisos de los CERT nacionales y del
   fabricante frente a resúmenes de terceros.
5. **DBIR y equivalentes**: edición vigente, cifra exacta, **denominador y n**, antes de citar nada.
   Lo escrito aquí corresponde a la edición 2025.
6. **Hueco declarado**: no se pudo verificar contra fuente primaria una referencia normativa o de
   organismo público sobre la clase "Golden SAML" y el compromiso del material de firma de la
   federación; el mecanismo descrito en §3.3 es criterio de ingeniería consolidado, pero **si se va
   a citar en un informe, buscar el aviso oficial correspondiente**. Tampoco se cita aquí la cifra
   de la edición 2026 del DBIR: se vio mencionada en resúmenes de terceros y **no se verificó contra
   el informe**.
7. **Fin de soporte y sustitución** de los componentes de identidad híbrida citados (agentes de
   sincronización y autenticación): su ciclo de vida cambia y el componente sin soporte en esa
   posición es Tier 0 sin parches.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
