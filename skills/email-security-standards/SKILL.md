---
name: email-security-standards
description: Email as an attack surface and the DNS records that defend it. Use when publishing or auditing SPF (v=spf1, the 10 DNS-lookup limit, +all, chained include, ~all vs -all), DKIM selectors, key length and rotation (selector._domainkey, rsa-sha256, ed25519-sha256), DMARC (_dmarc TXT, p=none/quarantine/reject, sp, np, t, adkim/aspf alignment, rua/ruf, the DMARCbis tree walk and the removal of pct), aggregate and failure report parsing, ARC and mailing-list or forwarding breakage, Authentication-Results headers, MTA-STS (_mta-sts TXT and .well-known/mta-sts.txt), TLS-RPT (_smtp._tls), DANE TLSA for SMTP with DNSSEC, BIMI (default._bimi, VMC/CMC, Mark Verifying Authority), third-party sending providers and the inventory of who sends on your behalf, Gmail/Yahoo/Outlook bulk-sender requirements and one-click unsubscribe (List-Unsubscribe-Post), inbound filtering, attachment and URL isolation, business email compromise and out-of-band payment verification, phishing simulations, or the reported-phish mailbox.
---

# Estándares de seguridad del correo electrónico

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **defender el canal de correo**: autenticación del remitente (SPF, DKIM, DMARC) y su
despliegue completo hasta política de rechazo; inventario de **quién envía en tu nombre**;
seguridad del transporte (MTA-STS, TLS-RPT, DANE); indicadores de marca (BIMI); política de
subdominios y de proveedores de envío; interpretación de informes agregados y de fallo;
supervivencia del correo a listas y reenvíos (ARC); defensa de entrada (filtrado, aislamiento
de adjuntos y de enlaces, cuarentena, *banners* de origen externo); fraude por compromiso de
correo corporativo (BEC) y su control de proceso; formación y simulacros; y el buzón de
denuncia como fuente de señal.

Triggers: `v=spf1`, `_dmarc`, `v=DMARC1`, `p=none`/`p=quarantine`/`p=reject`, `sp=`, `np=`,
`t=y`, `rua=`/`ruf=`, `adkim`/`aspf`, `pct=`, `selector._domainkey`, `v=DKIM1; k=rsa; p=`,
`v=ARC1`, `Authentication-Results:`, `ARC-Seal`, `_mta-sts`, `.well-known/mta-sts.txt`,
`_smtp._tls`, `v=TLSRPTv1`, `_25._tcp` TLSA, `default._bimi`, `v=BIMI1`, VMC/CMC,
`List-Unsubscribe-Post: List-Unsubscribe=One-Click`, `550 5.7.26`, `dmarcian`/`parsedmarc`,
`opendkim`/`opendmarc`, `swaks`, "informe agregado", "alineación", "suplantación de dominio",
"phishing", "BEC", "fraude del CEO", "cambio de cuenta bancaria", "simulacro de phishing".

**Principio rector**: el correo es el canal de entrada más usado contra las personas de una
organización, y **es el único cuya defensa base depende de tres registros DNS que casi nadie
revisa**. Aquí el criterio es concreto y verificable: o el registro está publicado y
alineado, o no lo está — se comprueba en 30 segundos con `dig`. Corolario: **DMARC no es un
proyecto de DNS, es un proyecto de inventario**. El 90 % del trabajo real de llegar a
`p=reject` es descubrir quién envía en tu nombre (facturación, RR. HH., el CRM, la imprenta,
aquel plugin) y **la parte que falla no es la técnica, es que nadie tenía esa lista**.

**No aplica**: la **regla de detección y su contenido analítico** (incluido convertir un
correo denunciado en detección) son de `detection-engineering-standards`, el **incidente
confirmado, la contención que preserva evidencia y el forense del buzón** son de
`incident-response-forensics-standards`, y el **proceso del incidente** —severidad, mando,
comunicación, postmortem— es de `incident-management-standards`; aquí termina en el momento
en que hay compromiso confirmado. La **operación de la zona DNS** (delegación, DNSSEC, TTL,
gestión del registro) es de `dns-standards` —aquí se fija **qué debe contener el registro y
por qué**—, la **identidad y el acceso al buzón** (MFA, acceso condicional, tokens OAuth,
revocación de sesión, reglas de reenvío como IoC de cuenta comprometida) son de
`identity-access-management-standards`, la **criptografía y la PKI** (tamaño de clave, TLS,
cadenas de certificación, S/MIME) de `cryptography-pki-standards`, el **triaje de CVE** del
producto de correo de `vulnerability-management-standards`, la **cola, el turno y la métrica
del SOC** de `soc-operations-standards`, y **el indicador, su caducidad y la inteligencia
sobre suplantación de marca** de `threat-intelligence-standards`.
Además: `mail-servers-standards` (**el servidor que implementa estos controles**: Postfix,
Exim, Dovecot, Rspamd, colas, almacenamiento y reputación de la IP de salida — **aquí la
política y el contenido del registro, allí el demonio que los aplica**),
`offensive-security-standards` (**cualquier campaña simulada exige alcance y
autorización por escrito**; esta skill es **defensiva**), `privacy-engineering-standards`
(el buzón y sus cabeceras son dato personal: base legal, minimización y retención de los
simulacros y del archivado), `grc-compliance-standards` (obligación regulatoria de
notificación y evidencia de auditoría), `networking-standards` y `firewall-policy-standards`
(salida SMTP, egress y reputación de IP), `observability-standards` (plataforma de
telemetría), `itsm-itil-standards` (el ticket y el SLA), `macos-fleet-standards` y
`endpoint-security-standards` (**Ola 7, planificada**: el cliente de correo y lo que pasa
tras el clic), `ai-governance-standards` y `mlsecops-standards` (si el filtro decide con un
modelo: gobierno, sesgo y evaluación).

## 2. Decisiones por defecto

> Verificar por web el estado de cada RFC y borrador antes de fijarlo en un proyecto (§8).

| Control | Norma verificada | Decisión por defecto |
|---|---|---|
| SPF | **RFC 7208**, Proposed Standard (obsoleta RFC 4408; actualizada por 7372, 8553, 8616) | Un único registro `v=spf1`, terminado en `-all`. `~all` solo durante el despliegue |
| DKIM | **RFC 6376**, Internet Standard (actualizada por 8301, 8463, 8553, 8616) | Firmar siempre. `rsa-sha256` con **≥2048 bits**; `ed25519-sha256` (RFC 8463) en doble firma, nunca solo |
| DMARC | **RFC 9989** (núcleo) + **RFC 9990** (informe agregado) + **RFC 9991** (informe de fallo), Proposed Standard, may-2026 — **obsoletan RFC 7489 y RFC 9091** | Destino `p=reject` con `rua` activo. `sp` y `np` explícitos |
| ARC | **RFC 8617**, **Experimental** | Sellar en los intermediarios propios (listas, gateways); **no** confiar en el ARC ajeno sin lista de confianza |
| Auth-Results | **RFC 8601**, Proposed Standard (obsoleta 7601) | El MTA de borde escribe la cabecera y **borra las falsificadas** que llegan de fuera |
| MTA-STS | **RFC 8461**, Proposed Standard | `mode: enforce`, `max_age` alto (máximo permitido 31 557 600 s). `testing` solo como paso previo con TLS-RPT activo |
| TLS-RPT | **RFC 8460**, Proposed Standard | Siempre, y **antes** que MTA-STS/DANE: es la única forma de ver qué rompes |
| DANE SMTP | **RFC 7672** (TLSA: RFC 6698, act. por 7218, 7671, 8749), Proposed Standard | Solo si **la zona y la de los MX están firmadas con DNSSEC**; si no, MTA-STS |
| BIMI | **NO es RFC**: `draft-brand-indicators-for-message-identification-14` (may-2026), *Individual Submission*, estado IESG "I-D Exists" | Opcional y **último**. Exige DMARC en `quarantine`/`reject`, logo SVG y **VMC/CMC de pago** emitido por una MVA |
| Baja de listas | **RFC 8058**, Proposed Standard | `List-Unsubscribe` + `List-Unsubscribe-Post` en todo correo comercial o suscrito |

**Lo que cambió con DMARCbis y hay que reescribir** (RFC 9989, verificado en el registro IANA
del propio documento): `pct`, `rf` y `ri` pasan a **histórico**; se añaden `np` (política para
subdominios **inexistentes**), `psd` (el dominio es un sufijo público) y **`t` (modo de
prueba)**. La lista de sufijos públicos (PSL) se sustituye por el **DNS Tree Walk**: hasta
**8 consultas** ascendiendo por el árbol (si el nombre tiene ≥8 etiquetas, salta a las 7 de la
derecha). Y el dato que corrige la creencia habitual: **DMARC ya no es Informational del flujo
independiente — ahora es Proposed Standard del flujo IETF.**

## 3. Estructura y convenciones

```dns
; --- SPF: uno solo, ≤10 términos con consulta DNS, terminado en -all
example.com.               IN TXT "v=spf1 include:_spf.proveedor.example -all"
; --- DKIM: un selector por emisor y por rotación; k=rsa p=<clave ≥2048b>
2026q3._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; t=s; p=MIIBIjAN..."
; --- DMARC: destino final; np=reject se publica desde el día 1
_dmarc.example.com.        IN TXT "v=DMARC1; p=reject; sp=reject; np=reject; adkim=s; aspf=s; rua=mailto:dmarc@example.com"
; --- Autorización del destino externo de informes (RFC 9990 §4)
example.com._report._dmarc.proveedor.example. IN TXT "v=DMARC1"
; --- Transporte
_mta-sts.example.com.      IN TXT "v=STSv1; id=20260805T120000Z;"   ; política en https://mta-sts.example.com/.well-known/mta-sts.txt
_smtp._tls.example.com.    IN TXT "v=TLSRPTv1; rua=mailto:tlsrpt@example.com"
_25._tcp.mx1.example.com.  IN TLSA 3 1 1 <hash>                      ; solo con DNSSEC
; --- Subdominio que NO envía: SPF vacío y DMARC de rechazo
_dmarc.static.example.com. IN TXT "v=DMARC1; p=reject;"
static.example.com.        IN TXT "v=spf1 -all"
```

- **Un subdominio por caso de uso de envío** (`mkt.`, `facturas.`, `notif.`), cada uno con su
  SPF y su DKIM. Aísla el fallo de un proveedor y permite `sp` distinto del dominio raíz.
- **Todo dominio y subdominio que no envía correo publica `v=spf1 -all` y DMARC de rechazo**,
  incluidos los dominios *parked*, los de campañas viejas y los defensivos.
- **Alineación estricta (`adkim=s; aspf=s`) es el objetivo**, no el punto de partida: la
  relajada acepta el subdominio organizacional y es lo que permite que un proveedor
  comprometido firme por ti. Endurecer **después** de cerrar el inventario.
- **`np=reject` desde el primer día**: ningún correo legítimo sale de un subdominio que no
  existe. Coste cero, cubre la suplantación por subdominio inventado.
- **Selector por emisor y por rotación** (`2026q3._domainkey`), nunca un selector compartido:
  rotar sin selector nuevo implica una ventana en la que se rompen las firmas en tránsito.

## 4. Verificación y gates

- **El inventario es el entregable, no el registro DNS.** Se construye con `rua` en `p=none`
  hasta que **todo remitente del informe agregado esté identificado y clasificado** (legítimo
  autenticado / legítimo sin autenticar / desconocido / suplantador). Sin esa tabla cerrada,
  subir a `quarantine` corta correo real.
- **La rampa con DMARCbis ya no es por porcentaje** (`pct` es histórico): se sube publicando
  `p=quarantine` con **`t=y`** —el receptor no aplica la política pero sí informa— y luego
  `t=n`. Ojo: `t` **no tiene efecto** cuando la política es `none`.
- **Gates automáticos** (rompen el build o abren ticket, en orden de coste): (1) `dig` +
  validador de sintaxis de SPF/DKIM/DMARC/MTA-STS sobre **todos** los dominios del inventario,
  a diario; (2) **contador de consultas DNS de SPF** — la norma obliga a `permerror` al pasar
  de **10 términos que consultan** (`include`, `a`, `mx`, `ptr`, `exists`, `redirect`), y
  recomienda un máximo de **2 *void lookups***, así que el umbral de alarma es 8, no 10;
  (3) longitud de clave DKIM y algoritmo; (4) caducidad del certificado de la política
  MTA-STS y del VMC; (5) *diff* del registro DNS contra el esperado (detección de deriva).
- **Parsear los informes agregados con herramienta, no con la vista**: son XML comprimido, uno
  por receptor y día (RFC 9990: realimentación **diaria o más frecuente**). Sin agregador no
  hay despliegue.
- **Probar el camino de fallo, no solo el feliz**: enviar desde un origen no autorizado y
  comprobar que el receptor lo rechaza; romper a propósito la política MTA-STS en `testing` y
  comprobar que llega el informe TLS-RPT.
- **Auditar el `ruf`** antes de publicarlo: el informe de fallo lleva contenido del mensaje y
  es **dato personal**; muchos receptores no lo envían y publicarlo sin base legal y sin
  minimización es un problema de privacidad, no una mejora de seguridad.

## 5. Defensa de entrada, BEC y personas

- **El phishing moderno rara vez trae adjunto malicioso.** Lleva un enlace a una página de
  recolección de credenciales o a un flujo de consentimiento OAuth, o simplemente **texto**
  pidiendo una acción. Un programa que solo mide adjuntos bloqueados está midiendo la parte
  fácil. Los controles que sí importan: reescritura y **detonación de URL en el momento del
  clic** (no solo en la entrega), aislamiento del adjunto, bloqueo por **tipo real** de
  fichero y no por extensión, y **cabecera visible de origen externo** en el cliente.
- **Suplantación por parecido**: DMARC protege **tu** dominio, no protege de `exarnple.com`.
  Hace falta vigilancia de dominios similares y regla de cuarentena por *display name* que
  imita a un directivo interno cuando el `From` es externo.
- **BEC: ningún control técnico lo detiene solo.** El fraude no lleva malware ni enlace, y con
  frecuencia sale de un buzón **legítimo y comprometido**, así que pasa SPF, DKIM y DMARC. El
  único control que funciona es de proceso: **verificación fuera de banda obligatoria** —
  llamada a un número del maestro de proveedores, nunca al del correo— para todo alta o
  **cambio de cuenta bancaria** y para todo pago por encima de un umbral, con **doble
  aprobación** y sin excepción por urgencia o jerarquía. La excepción "lo pide el CEO y es
  urgente" **es** el ataque.
- **Magnitud, con fuente primaria y su sesgo declarado**: el *Internet Crime Report 2025* del
  IC3 del FBI registra **24 768 denuncias de BEC y 3 046 598 558 USD** en pérdidas
  declaradas, segundo por importe tras el fraude de inversión, frente a **32 320 105 USD** en
  *ransomware*. Metodología y límites, textuales del informe: son **denuncias
  voluntarias**, mayoritariamente de EE. UU., con posibles duplicados, y la cifra de
  *ransomware* **"no incluye estimaciones de negocio, tiempo, salarios, ficheros o equipos
  perdidos"** — por eso no se pueden comparar como si fueran el mismo tipo de dato. Lo que sí
  sostiene el dato: **el BEC mueve dinero por transferencia directa** (el propio informe cifra
  en el 86 % la transferencia bancaria/ACH como vía del BEC) y por eso su pérdida directa es
  desproporcionada frente a su volumen de casos.
- **Formación y simulacros**: un simulacro mide **la tasa de denuncia**, que es la métrica
  accionable; la tasa de clic solo mide qué señuelo usaste. Reglas: nunca cebos con salario,
  despido, bonus o salud; **cero consecuencias individuales** por caer; resultados agregados,
  nunca *ranking* nominal; y el objetivo declarado es **reducir el tiempo hasta la primera
  denuncia**. Un programa que castiga produce el peor resultado posible: gente que cae y
  no lo cuenta.
- **El buzón de denuncia es una fuente de detección de primer orden** —botón "denunciar" en el
  cliente, con acuse y respuesta— porque un usuario que denuncia detecta campañas que el
  filtro dejó pasar. Aquí se define el canal y el compromiso de respuesta; **la regla que se
  escribe con esa señal es de `detection-engineering-standards`** y la búsqueda y purga
  retroactiva del mismo mensaje en todos los buzones es contención de incidente.

## 6. Salida, terceros y operabilidad

- **Inventario vivo de remitentes autorizados**, con dueño de negocio, subdominio asignado,
  método de autenticación y fecha de revisión. **Alta de proveedor = entrada en el inventario
  + subdominio + DKIM propio**; si no cabe en el SPF, cabe en un subdominio delegado.
- **El SPF encadenado se rompe solo**: cada `include:` de un SaaS arrastra los suyos y el
  presupuesto de 10 consultas se agota sin avisar. Ante el límite: aplanar **no** (rompe
  cuando el proveedor cambia de IP), delegar por subdominio **sí**, y priorizar **DKIM**, que
  no consume presupuesto DNS y sobrevive al reenvío.
- **Requisitos de los grandes buzones** (verificado en la fuente de Google): desde el
  **1-feb-2024**, todo remitente a Gmail necesita **SPF o DKIM**, DNS directo e inverso (PTR)
  válidos, conexión **TLS**, formato RFC 5322 y **tasa de spam <0,3 %** en Postmaster Tools;
  quien envía **>5000 mensajes/día** necesita **SPF y DKIM**, **DMARC** (la política puede ser
  `p=none`), **alineación** del `From` con SPF o DKIM y **baja en un clic** más enlace visible.
  Guía adicional de Google: mantenerse **por debajo del 0,10 %** y no llegar nunca al 0,30 %.
- **Listas y reenvíos rompen SPF siempre y DKIM cuando el intermediario modifica el mensaje**
  (asunto con prefijo, pie añadido). Mitigación por orden: no modificar el cuerpo, reescribir
  el `From` a un dominio de la lista (`From` rewriting), y **ARC** para que el receptor final
  pueda evaluar la autenticación previa — recordando que ARC es **Experimental** y solo sirve
  si el receptor confía en ese sellador.
- **Operabilidad**: alertar por **caída del volumen de informes agregados** (indica registro
  roto o zona mal publicada), por aparición de un remitente desconocido con volumen, por
  cambio de la política MTA-STS y por fallo de validación TLS en TLS-RPT. Ensayar la rotación
  de clave DKIM antes de necesitarla.

## 7. Sostenibilidad y prohibiciones

Revisión trimestral del inventario de remitentes y del registro DNS; rotación de claves DKIM
al menos anual con selector nuevo; revisión del estado de los borradores (BIMI, DKIM2) en cada
ciclo. Todo cambio de registro, versionado en el repositorio de la zona.

- ❌ **Dejar DMARC en `p=none` indefinidamente.** `p=none` no protege de nada: es solo el
  instrumento de medida. Sin fecha de salida acordada, el proyecto está muerto y publicado.
- ❌ **`+all` en SPF** — autoriza a todo internet a enviar en tu nombre. Igual de vetados
  `?all` en producción y un segundo registro `v=spf1` en el mismo nombre (`permerror`).
- ❌ Publicar **DKIM con clave <2048 bits**. RFC 8301 obliga a ≥1024 y **prohíbe** a los
  verificadores dar por válida una firma con menos; 1024 es el mínimo legal, no el criterio.
- ❌ **`rsa-sha1`**: RFC 8301 lo prohíbe explícitamente para firmar y para verificar.
- ❌ **Añadir un proveedor de envío sin inventariarlo.** Es la causa número uno de que un
  despliegue de DMARC corte correo legítimo meses después.
- ❌ **Aplanar el SPF** expandiendo las IP de un tercero para esquivar el límite de 10.
  Rompe silenciosamente el día que el proveedor cambia de rango.
- ❌ Medir la formación por **tasa de clic** y nada más, publicar *rankings* nominales o
  aplicar consecuencias disciplinarias por caer en un simulacro.
- ❌ Usar cebos de **salario, despido, bonus, salud o emergencia familiar** en un simulacro.
- ❌ Autorizar un **pago o cambio de cuenta bancaria** con verificación por el mismo hilo de
  correo, o con el teléfono que aparece en ese correo.
- ❌ Publicar `ruf` con destino externo **sin base legal, sin minimización y sin autorización
  `_report._dmarc`** del dominio receptor.
- ❌ **DANE sin DNSSEC** en tu zona y en la de los MX: sin firma la validación no aporta nada.
- ❌ Poner **MTA-STS en `enforce` sin haber pasado por `testing` con TLS-RPT activo**, o
  publicar `max_age` de horas "por si acaso" — anula la protección contra el ataque de
  degradación.
- ❌ Tratar **BIMI como control de seguridad**: es marca. Y comprar un VMC antes de estar en
  `p=reject` es dinero adelantado sobre trabajo no hecho.
- ❌ Confiar en cabeceras `Authentication-Results` o sellos **ARC de origen externo** sin lista
  explícita de intermediarios de confianza: son texto que cualquiera puede escribir.
- ❌ Lanzar una **campaña simulada de phishing sin alcance y autorización por escrito**
  (ver `offensive-security-standards`) o sin avisar al SOC (*deconfliction*).

## 8. Verificación web obligatoria

1. **Cada RFC, uno a uno, en `rfc-editor.org`**, comprobando `obsoleted-by` y no solo el
   número: SPF **7208**, DKIM **6376** (+8301, +8463), DMARC **9989/9990/9991** (que
   **obsoletan 7489 y 9091** — casi toda la literatura sigue citando 7489), ARC **8617**,
   MTA-STS **8461**, TLS-RPT **8460**, DANE-SMTP **7672** (TLSA **6698**), Auth-Results
   **8601**, baja en un clic **8058**.
2. **Estado de BIMI**: sigue siendo *Internet-Draft* individual, no RFC. Comprobar revisión y
   caducidad en `datatracker.ietf.org` antes de citarlo como norma.
3. **Discrepancia declarada**: el borrador BIMI rev. 14 (may-2026) referencia normativamente
   **RFC 7489 y el tag `pct`**, que **RFC 9989 (may-2026) declara histórico**. Hasta que se
   actualice, la condición "quarantine con `pct=100`" no tiene equivalente literal en DMARCbis;
   interpretarla como "quarantine sin modo de prueba (`t=n`)" y **confirmar con el receptor**.
4. **Trabajo de DKIM2 en el IETF** (grupo `dkim`, borradores `draft-ietf-dkim-dkim2-*`): es
   trabajo en curso, **no hay RFC**. No diseñar contra él todavía.
5. **Requisitos de los grandes buzones**, que cambian sin previo aviso: Google (verificado),
   Yahoo y Microsoft. **Hueco declarado**: no se ha podido confirmar contra fuente primaria
   accesible el umbral y la fecha exacta de aplicación de los requisitos de Microsoft para
   remitentes de alto volumen a dominios de consumo (la página de Microsoft no sirve contenido
   sin JavaScript). **Verificar antes de citarla**; no dar por buena la cifra de un blog.
6. **Cifras descartadas por falta de metodología pública**: "el 90 % de los ciberataques
   empieza por correo", "el 95 % de las brechas son error humano", el coste medio de una
   brecha y las tasas de detección de cualquier fabricante de correo seguro. Si la fuente es
   un proveedor que vende el control que la cifra justifica y no publica método ni muestra,
   **no se usa**. Fuentes con metodología declarada: IC3/FBI (denuncias voluntarias, sesgo
   EE. UU.), ENISA, CISA, y los informes de los operadores de buzón sobre su propio tráfico.
7. Estado de los validadores y agregadores que se recomienden (licencia y mantenimiento) antes
   de fijar herramienta.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
