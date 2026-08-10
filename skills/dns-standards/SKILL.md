---
name: dns-standards
description: DNS service architecture, zone design and DNS security. Use when editing zone files or named.conf, unbound.conf, knot.conf, kresd config, nsd.conf, pdns.conf, dnsmasq.conf or pihole.toml, designing SOA timers, TTL, delegation and glue, CNAME-at-apex with ALIAS/ANAME, CAA, HTTPS/SVCB, SSHFP, TLSA/DANE, PTR records, DNSSEC signing and KSK/ZSK rollover, NSEC3 parameters, RRL, TSIG-protected AXFR/IXFR, split-horizon views, anycast authoritatives, .internal or home.arpa naming, zone-as-code with dnscontrol or octodns, named-checkzone, kdig, dig +trace, DoT/DoH/DoQ resolver transport, dangling subdomain takeover, DNS tunneling exfiltration or registrar/NS hijack.
---

# Estándares de DNS — servicio crítico y superficie de ataque

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, desplegar, revisar o auditar **el servicio DNS y sus datos**: separación
autoritativo/recursivo, redundancia y anycast, elección de software por rol, diseño de zona
(SOA, TTL, delegación, glue, ápice), tipos de registro modernos, autenticación de correo en
DNS, DNSSEC y su ciclo de vida, transporte cifrado (DoT/DoH/DoQ), espacio de nombres interno,
zona como código, validación y monitorización, y la seguridad del nombre como activo
(registrador, NS, subdominios colgantes, tunneling, amplificación, transferencias).

Triggers: ficheros de zona (`db.*`, `*.zone`, `$ORIGIN`, `$TTL`), `named.conf`,
`named-checkconf`/`named-checkzone`, `unbound.conf`, `unbound-checkconf`, `knot.conf`,
`kresd`/`kresctl`, `nsd.conf`, `pdns.conf`, `recursor.conf`, `dnsdist.conf`, `dnsmasq.conf`,
`pihole.toml`, `Corefile` *fuera* de Kubernetes, `dnscontrol`/`dnsconfig.js`, `octodns`
(`config/*.yaml`), `dig`/`kdig`/`delv`/`drill`, `dnsviz`, `zonemaster`, `keymgr`/`dnssec-signzone`,
`rndc`, `TSIG`, "TTL", "SOA", "glue", "CNAME en el ápice", "DMARC", "SPF", "DKIM", "MTA-STS",
"CAA", "DANE", "DNSSEC caducado", "NXDOMAIN", "subdominio colgante", "takeover".

**Principio rector** (hereda el de `networking-standards`: *la red es default-deny y documentada
como código; lo que no está en el SoT no existe*): **la zona es código y el nombre es un activo
de identidad**. Todo registro existe porque alguien lo justificó y quedó en el repo; todo nombre
que ya no sirve se borra el día que deja de servir. Quien controla tu delegación controla tu
correo, tus certificados y tu identidad: el DNS no es "infraestructura de apoyo", es la raíz de
confianza operativa de casi todo lo demás.

**No aplica**: ver `networking-standards` (**madre**: diseño de red, direccionamiento e IPAM,
VLAN, routing/BGP y RPKI, MTU/MSS, proxies y balanceadores, overlays, colocación del resolver en
la topología y bloqueo de DNS saliente en el borde como *decisión de red* — aquí el **servidor
DNS, su zona y sus datos**), `firewall-policy-standards` (la política que permite `53/853/443`
hacia el resolver y que filtra el egress DNS: **tú defines qué resolver es legítimo y qué
telemetría produce; ellos escriben y gobiernan la regla**), `linux-hardening-standards` (baseline
CIS del host que sirve DNS, incluido su firewall de host, `systemd` sandboxing del demonio y
`resolv.conf` como control del baseline), `cryptography-pki-standards` (**elección de algoritmos
DNSSEC y gestión/custodia de claves**, TLS de DoT/DoH, emisión ACME y `CAA` como control de
emisión visto desde la PKI — aquí sólo el **registro publicado** y su operación),
`detection-engineering-standards` (**reglas de detección sobre los logs de consulta**: tunneling,
DGA, NXDOMAIN anómalo, C2 — la telemetría y su calidad son de esta skill, la analítica es suya),
`observability-standards` (métricas, dashboards y alertas del servicio), `onprem-standards`
(paraguas de plataforma y plano OOB), `homelab-standards` (Pi-hole/AdGuard y DNS doméstico: la
frontera es el rigor exigido, no el tamaño), `kubernetes-standards` (**CoreDNS dentro del
clúster**, `dnsPolicy`, `ndots`, Gateway API), `aws-standards`/`azure-standards`/`gcp-standards`
(Route 53, Azure DNS y Cloud DNS como servicio gestionado del proveedor, incluidas sus zonas
privadas), `secrets-management-standards` (custodia de las **credenciales de API del proveedor
DNS** que usan los retos ACME DNS-01), `identity-access-management-standards` (MFA y cuentas
del registrador como identidad privilegiada), `incident-response-forensics-standards` (el log
DNS como evidencia y su cadena de custodia durante un compromiso), `data-platform-standards`
(retención y coste del almacén de logs de consulta), `grc-compliance-standards` (DNS como
control ante ENS/ISO/NIS2), `bcdr-standards` (RTO/RPO del servicio de nombres),
`iac-standards`/`cicd-standards` (el repo y el pipeline que despliegan la zona).

Además:
`vpn-standards` (resolución dentro del túnel, DNS *split* del cliente VPN y fuga de DNS fuera
del túnel), `network-troubleshooting-standards` (**diagnóstico**: tú fijas cuál es la respuesta
correcta y quién debe darla; él averigua por qué el paquete o la respuesta no llegan — cuando
el síntoma es "no resuelve", el diseño de zona y de resolver es de aquí, la captura y el
seguimiento por capas es suyo), `linux-administration-standards` (`resolv.conf`, `resolvectl`,
`systemd-resolved`, `nsswitch.conf` y la resolución **desde el host**),
`ha-clustering-standards`, `proxmox-ve-standards`.

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión y el estado de mantenimiento por web antes de fijarla en un
> proyecto real (§8). **2026 es un año anómalo**: el análisis con LLM ha disparado el volumen de
> CVE en BIND, Unbound y dnsmasq, y las ramas publican parches de seguridad casi mensuales.
> Versión fijada hoy = deuda mañana; lo que se fija es la **rama**, no el punto.

| Rol | Por defecto | Alternativa justificable | Vetado |
|---|---|---|---|
| Autoritativo | **Knot DNS 3.5.x** (3.5.6 la más reciente etiquetada) por firmado automático y rendimiento | **BIND 9.20.x** (9.20.26, 22-jul-2026) si necesitas su ecosistema; **NSD 4.15.0** (07-jul-2026) como secundario minimalista; **PowerDNS Authoritative 5.1.x** con backend SQL/LMDB si la zona vive en base de datos | **BIND 9.18 (EOL jun-2026)**; ramas de desarrollo (9.21/9.23) en producción; el mismo proceso sirviendo autoritativo y recursivo |
| Recursivo/validador | **Unbound 1.25.x** (1.25.2, 22-jul-2026, release de seguridad) o **Knot Resolver 6.4.x** (6.4.0, 17-jun-2026) | BIND 9.20.x como recursivo si ya es el estándar de la casa | `dnsmasq` y `systemd-resolved` como **validadores DNSSEC** de referencia; resolver abierto a Internet |
| Balanceo/proxy DNS y protección | **dnsdist 2.0.x/2.1.x** delante de recursivos y autoritativos (rate limiting, DoH/DoT/DoQ terminación, políticas) | Anycast + ECMP sin proxy en autoritativos puros | Publicar el recursivo directo a Internet "para pruebas" |
| DNS de clúster | **CoreDNS 1.14.6** (10-jul-2026) — **su configuración dentro de Kubernetes la fija `kubernetes-standards`** | CoreDNS como recursivo de propósito general sólo en escenarios muy acotados | CoreDNS como autoritativo público de zonas de negocio |
| Reenviador ligero / DHCP-DNS pequeño | `dnsmasq` **2.93** (fija ≥2.93: cierra el lote de 6 CVE coordinados de may-2026, incl. desbordamiento de heap CVE-2026-2291) | Reenviador del router sólo en lab | Cualquier `dnsmasq` < 2.92rel2 expuesto |
| Filtrado DNS lab/hogar | **Pi-hole FTL 6.7** (06-jul-2026, embebe dnsmasq 2.93) o **AdGuard Home 0.107.78** (13-jul-2026) | — | Filtrado doméstico como único resolver corporativo o sin redundancia |
| Zona como código | **dnscontrol 4.45.0** (01-ago-2026) para multi-proveedor con `preview`/`push`; **octoDNS 1.21.1** (01-ago-2026) si prefieres YAML declarativo y Python | Terraform con el provider del proveedor DNS cuando la zona ya vive en IaC del mismo cloud | Editar zonas en la consola web del registrador o del proveedor |
| DNS público autoritativo | **Dos operadores independientes** (p. ej. propio + gestionado), cada uno anycast | Un único proveedor **sólo** con SLA, anycast multi-región y plan de salida escrito | Todos los NS en el mismo AS, el mismo datacenter o el mismo proveedor |
| Transporte del stub al resolver | **DoT (853)** hacia el resolver corporativo, o `53` en red de confianza con egress bloqueado | **DoQ (RFC 9250, may-2022)** donde el software lo soporte y el operador lo controle | DoH de aplicación hacia un tercero, sin política |
| Diagnóstico | `kdig`, `dig +trace`, `delv`, `dnsviz`, `zonemaster` | `drill` | `nslookup` como herramienta de diagnóstico (oculta el detalle que necesitas) |

**Criterio de elección, no de gusto**: autoritativo → Knot/NSD si quieres mínimo y rápido, BIND si
quieres el ecosistema, PowerDNS si el dato vive en SQL. Recursivo → Unbound/Knot Resolver.
Cualquier candidato se descarta si no tiene **release de seguridad en los últimos 12 meses** o su
rama está EOL: eso es el filtro previo a toda discusión técnica.

## 3. Estructura y convenciones

### 3.1 Arquitectura

- **Autoritativo y recursivo NUNCA en el mismo servidor ni en el mismo proceso.** Son dos
  servicios con dos modelos de amenaza opuestos: el autoritativo es público y no debe cachear
  nada de terceros; el recursivo es interno, cachea todo y no debe responder a nadie de fuera.
  Mezclarlos habilita envenenamiento de caché con datos "autoritativos" y convierte un fallo de
  uno en caída del otro. Si el software ofrece ambos roles, se despliegan por separado igualmente.
- **Mínimo de autoritativos: dos, y con diversidad real** — distinto software o al menos distinto
  proceso y versión, distinta red/AS, distinta ubicación, idealmente distinto proveedor.
  Dos NS en el mismo hipervisor son un NS con dos nombres. Regla práctica: 2 proveedores × anycast.
- **Anycast para autoritativos públicos**: misma IP anunciada desde varias ubicaciones, con
  health check que **retira el anuncio BGP** cuando el demonio deja de responder (el diseño BGP,
  en `networking-standards`). Sin retirada automática, anycast agrava el fallo en vez de mitigarlo.
- **Recursivos**: al menos dos por sitio, en dominios de fallo distintos, con la misma política y
  el mismo contenido de RPZ/filtrado. Un resolver único es un SPOF que tumba todo el sitio.
- **Modelo oculto (`hidden primary`)**: el primario que firma no está publicado en el NS RRset;
  sólo los secundarios lo están. Reduce superficie y separa "quien edita" de "quien responde".
- **Split-horizon con criterio**: sólo cuando el mismo nombre debe resolver a algo distinto dentro
  y fuera, y asumiendo su coste (dos verdades que divergen). Prefiere **nombres distintos** o
  subdominio interno delegado. Si usas vistas, la vista interna es un superconjunto explícito y
  documentado, y ambas se generan del **mismo** SoT.

### 3.2 Zona: TTL, SOA, delegación

- **TTL con criterio, no un número copiado**: registros estables (NS, MX, SPF/DKIM/DMARC)
  horas; registros de servicio en producción 300-3600 s; registros de failover y health-based,
  30-60 s asumiendo el coste en consultas. Un TTL alto es resiliencia ante caída del autoritativo;
  uno bajo es agilidad. Elige a sabiendas.
- **Bajar el TTL ANTES de migrar** — el error clásico y el más caro. Secuencia: bajar TTL a 60 s
  → **esperar al menos el TTL anterior completo** (si estaba a 86400, esperas un día) → migrar →
  verificar desde varios resolvers públicos y regiones → restaurar el TTL. Bajarlo el mismo día
  del corte no sirve de nada: los resolvers siguen sirviendo el valor viejo.
- **SOA**: `refresh` y `retry` son irrelevantes si usas **NOTIFY + IXFR** (que es lo que debes
  usar); lo que importa de verdad es **`expire`** (cuánto sirve un secundario sin poder hablar
  con el primario — no lo pongas corto: es tu colchón ante una partición) y **`minimum`**, que
  hoy significa **TTL del NXDOMAIN negativo** (RFC 2308), no un TTL por defecto. Serial:
  `YYYYMMDDnn` o entero incremental generado por la herramienta, **nunca a mano**.
- **Delegación y glue**: los `NS` del hijo deben coincidir exactamente con los del padre; el
  **glue** (registro A/AAAA en el padre) es obligatorio y sólo obligatorio cuando el NS está
  *dentro* de la zona delegada. Glue obsoleto tras cambiar la IP de un NS es una de las averías
  más difíciles de ver desde dentro: se diagnostica **desde fuera**, con `dig +trace` y consulta
  directa a los servidores del TLD.
- **Consistencia entre padre e hijo**: NS RRset, `DS` y glue se verifican como gate (§4).
  Cualquier divergencia es un hallazgo, no una curiosidad.
- **`CNAME` en el ápice está prohibido por el protocolo** (el ápice tiene SOA y NS, y CNAME no
  puede coexistir). Alternativas, en orden: (1) `ALIAS`/`ANAME` del proveedor —resolución en el
  lado servidor, no estándar IETF, comportamiento y geolocalización dependen del proveedor;
  (2) registro **`HTTPS`** en el ápice con `AliasMode` (RFC 9460) —lo correcto a futuro, pero
  el cliente que no lo soporte necesita igualmente A/AAAA; (3) A/AAAA fijos actualizados por
  automatización. Nunca "apuntar el ápice a un CNAME y esperar que el resolver lo perdone".
- **Registros modernos que sí se fijan**:
  - **`CAA` (RFC 8659) obligatorio en toda zona**: restringe qué CA puede emitir para el dominio,
    con `issue`, `issuewild` (ponlo a `;` si no usas wildcards) e `iodef` para notificación.
    Es barato, se comprueba en el momento de la emisión y corta la mis-emisión.
  - **`HTTPS`/`SVCB` (RFC 9460, nov-2023)**: consultados de serie por Firefox, Safari y Chrome;
    habilitan HTTP/3 sin *upgrade dance*, upgrade a https y **ECH**. Publica al menos
    `alpn="h3,h2"` en los servicios web. RFC 9461 (mapeo DoH, `dohpath`) y RFC 9462 (DDR)
    dependen de ellos para descubrir resolvers cifrados. Los clientes antiguos los ignoran: no
    hay riesgo de compatibilidad, sí de olvidar mantenerlos coherentes con A/AAAA.
  - **`SSHFP`**: útil sólo si el cliente valida y la zona está firmada; sin DNSSEC no aporta
    seguridad, sólo comodidad.
  - **`TLSA`/DANE**: **honestidad** — la adopción real es residual. En un escaneo de 5,5 M de
    dominios (feb-2026) unos **30** publicaban TLSA frente a ~16.000 con MTA-STS. M365 valida
    ambos; Google Workspace y Yahoo soportan MTA-STS y **no** DANE. Postfix y Exim traen DANE
    nativo (MTA-STS requiere complemento tipo `postfix-tlspol`). **Criterio**: publica TLSA sólo
    si tu zona está firmada, tienes rotación de certificado y TLSA **acoplada y probada**, y tu
    ecosistema (correo `.nl`/`.de`, requisitos internet.nl, sector público europeo) lo pide.
    Fuera de ahí, **MTA-STS primero**; DANE mal operado es una interrupción de correo garantizada.
- **PTR**: mantén el inverso de lo que envía correo o participa en TLS mutuo; FCrDNS (A→PTR→A
  coherente) es requisito práctico de entregabilidad. Delegación inversa IPv6 (`ip6.arpa`) por
  automatización o no existirá.
- **Wildcards (`*`)**: prohibidos salvo caso justificado y acotado. Ocultan errores tipográficos,
  rompen NXDOMAIN como señal y convierten cualquier subdominio inventado en superficie válida.

### 3.3 Correo: autenticación en DNS

- **SPF**: un único registro TXT por dominio, terminado en **`-all`** (fail) una vez validado con
  datos reales; `~all` sólo como fase temporal con fecha de salida escrita. **Límite duro de 10
  lookups DNS** (`include`, `a`, `mx`, `ptr`, `exists`, `redirect`): superarlo produce
  `PermError` y **el SPF deja de valer**, silenciosamente. Se mide en CI, no se estima.
  `ptr` está deprecado: no se usa. Dominios que no envían correo: `v=spf1 -all` + `MX .` + DMARC
  `p=reject` (los dominios "parked" son el vector de suplantación más olvidado).
- **DKIM**: claves **RSA-2048 o Ed25519** (los algoritmos y su custodia, en
  `cryptography-pki-standards`), un selector por sistema emisor, rotación programada con
  solapamiento (publicar nuevo selector → migrar firmantes → retirar el viejo). Selectores de
  proveedores que ya no usas: se borran.
- **DMARC**: el objetivo es **`p=reject`**. `p=none` es una **fase de observación con fecha de
  fin**, no un estado permanente; un `p=none` de más de un trimestre es una decisión de no
  proteger el dominio, tomada por omisión. Ruta: `p=none` + `rua` → analizar informes → alinear
  emisores → `p=quarantine` con `pct` creciente → `p=reject`, incluyendo subdominios (`sp=`).
  Base normativa actualizada: **DMARCbis — RFC 9989** (Standards Track, may-2026, obsoleta
  RFC 7489 y 9091) y **RFC 9990** (informes agregados).
- **Requisitos vigentes de los grandes proveedores** (verificado ago-2026): Google y Yahoo exigen
  SPF+DKIM+DMARC alineado a remitentes de **≥5.000 mensajes/día** desde feb-2024, y Gmail pasó de
  aplazamiento `421` a **rechazo permanente `550` en nov-2025**; **Microsoft** aplica desde el
  **5-may-2025** rechazo directo (`550 5.7.515`) para outlook.com/hotmail.com/live.com, sin fase
  de aviso; La Poste se sumó en sep-2025. Todos exigen además desuscripción en un clic
  (`List-Unsubscribe` + `List-Unsubscribe-Post`, RFC 8058) y tasa de queja por debajo del 0,3%
  (opera por debajo del 0,1%). La tendencia declarada es endurecer hacia políticas estrictas:
  **asume que `p=none` dejará de ser suficiente y adelántate**.
- **MTA-STS (RFC 8461) y TLS-RPT (RFC 8460)**: publica ambos. MTA-STS requiere el TXT en
  `_mta-sts.<dominio>` **y** la política servida por HTTPS en `mta-sts.<dominio>/.well-known/`
  con certificado válido — dos sistemas que deben caducar juntos y no lo hacen solos: es la causa
  habitual de que ~30% de los despliegues medidos estén mal configurados. Empieza en
  `mode: testing`, pasa a `enforce` cuando TLS-RPT esté limpio. El `id` de la política cambia con
  cada modificación o los remitentes servirán la cacheada.

### 3.4 Espacio de nombres interno

- **Usa un subdominio de un dominio que poseas** (`corp.example.com`, `internal.example.com`):
  es la única opción que permite DNSSEC, certificados públicos y coexistencia con split-horizon
  sin colisiones.
- Alternativas reservadas y legítimas: **`.internal`** (reservado por ICANN el 29-jul-2024 para
  uso privado, nunca se delegará en la raíz) y **`home.arpa`** (RFC 8375, red doméstica).
  Ambas son **inseguras por definición**: no hay cadena DNSSEC ni certificado público posible.
- **PROHIBIDO inventarse TLD** (`.local` —que además es mDNS, RFC 6762—, `.lan`, `.corp`, `.home`,
  `.dev` como interno, `.intranet`): colisión con delegaciones reales, fuga de consultas a la raíz,
  y cuando el TLD acaba delegado de verdad, un tercero recibe tu tráfico interno con tus
  credenciales dentro. El caso `.dev` ya ocurrió.
- **Integración DHCP/directorio**: actualización dinámica del DNS desde el servidor DHCP (Kea) con
  **TSIG** y ámbito acotado a la zona dinámica, nunca con clave compartida global. En entornos
  con Active Directory, DNS integrado en el directorio con actualizaciones **seguras únicamente**
  (el detalle de AD, en `windows-server-ad-standards`), y delegación explícita entre la zona AD
  y la zona corporativa: dos autoridades sobre el mismo nombre es un incidente esperando fecha.
- **Búsqueda (`search`) mínima**: listas largas multiplican consultas y crean resoluciones
  accidentales. Nombres cualificados (FQDN) en configuración de servicios, siempre.

### 3.5 Zona como código

- El **SoT es el repo**, no el panel del proveedor. `dnscontrol` u `octoDNS` generan y empujan;
  el acceso humano al panel queda para emergencias, con MFA y auditoría.
- El pipeline: PR → validación de sintaxis y de política → `preview`/`plan` con **diff explícito**
  → revisión humana obligatoria para NS, DS, MX y registros de autenticación de correo → `push`.
- **Detección de deriva** periódica: diff entre lo publicado y el repo. Una diferencia es un
  hallazgo con dueño (o un cambio manual que alguien hizo bajo presión y no documentó).
- Credenciales de API del proveedor DNS: en gestor de secretos, con permisos limitados a las zonas
  necesarias (`secrets-management-standards`). Ese token permite emitir certificados por DNS-01
  para **todo** tu dominio: trátalo como clave de identidad, no como config.

## 4. Gates de calidad obligatorios

En orden de coste creciente. Los cuatro primeros rompen el build.

1. **Sintaxis y carga**: `named-checkconf` + `named-checkzone` (o `knotc zone-check`,
   `unbound-checkconf`, `pdnsutil check-all-zones`, `kresctl validate`) sobre cada zona y cada
   config. Una zona que no carga es un corte total, no un aviso.
2. **Política de zona en CI**:
   - SPF: **contar los lookups DNS** y fallar por encima de 10; un único registro `v=spf1`.
   - DMARC presente; **fallar si `p=none` supera la fecha límite** registrada en el repo.
   - `CAA` presente en el ápice y coherente con la CA que realmente emite.
   - Ningún `CNAME` en el ápice; ningún `CNAME` coexistiendo con otros tipos.
   - TTL dentro de rangos acordados por clase de registro.
   - Serial creciente respecto al publicado.
3. **Coherencia padre-hijo y delegación**: NS del padre == NS del hijo, glue correcto, `DS`
   coincidente con la DNSKEY publicada. `dig +trace`, `dnsviz` o `zonemaster` en el pipeline.
4. **Prueba negativa**: verifica que el **recursivo interno no responde desde fuera**, que el
   **autoritativo no recursa** (`RD` ignorado, no hay respuesta para nombres ajenos), y que
   `AXFR` está denegado a quien no tiene TSIG. Un DNS probado sólo por el camino feliz no está
   probado.
5. **Resolución desde fuera, continua**: sondas desde varias regiones y varios resolvers públicos
   —no sólo desde tu red, donde la caché te miente— comprobando respuesta correcta, coherencia
   entre todos los NS, y latencia. Añade la verificación de **validación DNSSEC** extremo a extremo.
6. **Vigilancia de caducidades, con alerta anticipada y dueño**:
   - **Firmas RRSIG** (alerta al 50% de la vida restante; una firma caducada es una caída total
     y autoinfligida, y el recursivo validante te deja fuera de Internet).
   - **Registro de dominio** (multi-año + auto-renovación **y** alerta independiente del
     registrador: si la alerta la manda quien te va a cortar, no es una alerta).
   - Certificado de la política **MTA-STS** y del endpoint DoH/DoT.
   - Selectores DKIM y ventana de rotación.
7. **Ensayo de rollover y de restauración**: la primera rotación de KSK no se hace en producción
   sin haberla hecho en un entorno igual. Restaura la zona desde el repo en un servidor limpio al
   menos una vez por semestre.
8. **Prueba de failover**: apaga un autoritativo y un recursivo (en ventana) y comprueba que
   nadie se entera. Un secundario nunca ejercitado no cuenta como redundancia.

## 5. Seguridad

### 5.1 DNSSEC

- **Valida siempre en el recursivo** (coste cero de operación, beneficio inmediato). La validación
  global ronda el **35-36%** de usuarios (APNIC) y ~49% en la UE: estás en el lado correcto de esa
  estadística, no en el marginal. Referencia normativa: **RFC 9364 (BCP 237)**.
- **Firmar la zona propia: cuándo compensa.** Sí, si el nombre soporta correo, certificados,
  identidad federada o servicios financieros, o si necesitas DANE/SSHFP con valor real. No —o no
  todavía— si no puedes automatizar el firmado y la rotación, porque el modo de fallo es
  **caída total del nombre**, no degradación. Datos honestos: las delegaciones firmadas rondan el
  **7%**, `.com` ~4,3% y `.net` ~5,3%; y aunque ~8% de las consultas van a dominios firmados,
  sólo ~0,5-0,6% se validan extremo a extremo (Cloudflare Radar, 2026, en crecimiento sostenido).
  Firmar es correcto; creer que te protege de un atacante ya presente en el resolver del cliente,
  no.
- **Automatizado o no se hace**: firmado en línea y gestión de claves del propio servidor
  (Knot `keymgr`/DNSSEC automático, BIND `dnssec-policy`, PowerDNS `pdnsutil`). Rotación de ZSK
  automática; **KSK con CDS/CDNSKEY (RFC 7344/8078)** para que el padre se actualice solo donde
  el registrador lo soporte. **Firmar a mano con cron y `dnssec-signzone` está vetado**: el 100%
  de las caídas por DNSSEC que verás son firmas caducadas o un DS que no se actualizó.
- **NSEC3 sólo si necesitas evitar el enumerado**, y con los parámetros de **RFC 9276 (BCP 236)**:
  **0 iteraciones y salt vacío**. Iteraciones altas son coste para ti y amplificación para el
  atacante, no seguridad. Si la enumeración de la zona no es un problema, **NSEC plano** es más
  simple y más barato.
- **Monitoriza la cadena completa** (DS en el padre ↔ DNSKEY ↔ RRSIG ↔ expiración) desde un
  validador externo, no desde tu propio servidor.
- Algoritmos, longitudes y custodia de claves: `cryptography-pki-standards`.

### 5.2 Disponibilidad y abuso

- **Nunca un resolver abierto**: el recursivo responde sólo a redes propias (`access-control` /
  `allow-query`). Un recursivo abierto es un amplificador para terceros y un canal de
  envenenamiento para ti.
- **Amplificación en autoritativos**: **RRL (Response Rate Limiting)** activado con `slip` para
  no castigar a clientes legítimos, **minimal-any (RFC 8482)** para no responder ANY completo, y
  respuestas mínimas. Complementa con limitación en dnsdist y anti-DDoS aguas arriba.
- **Cache poisoning**: las mitigaciones actuales (puerto de origen aleatorio, 0x20, cookies DNS
  RFC 7873, DNSSEC, QNAME minimisation RFC 9156) **bastan pero no sobran**: siguen apareciendo
  variantes (p. ej. NS promiscuos, CVE-2025-11411 en Unbound, envenenamiento entre zonas
  CVE-2026-13321 en BIND en jul-2026). **Traducción operativa: parchea rápido**; la defensa
  estructural existe, pero cada trimestre alguien encuentra una grieta en la implementación.
- **Higiene del recursivo**: QNAME minimisation activo, `harden-below-nxdomain`, NXDOMAIN cut
  (RFC 8020), rechazo de respuestas fuera de bailiwick, y **no** reescribir NXDOMAIN a una IP
  propia (rompe la señal, el correo y la detección).

### 5.3 El nombre como activo: secuestro y abandono

- **Secuestro de dominio: la vía de compromiso total más barata que existe.** Con control del
  registrador o de los NS, un atacante emite certificados válidos (DNS-01/HTTP-01), redirige el
  correo, pasa cualquier reset de contraseña y suplanta la marca — sin tocar un solo servidor
  tuyo. Controles **no negociables**:
  - **Registrar lock / transfer lock** activo y, en los TLD que lo ofrezcan, **registry lock**
    (bloqueo en el registro, con desbloqueo fuera de banda) para los dominios de negocio.
  - **MFA resistente a phishing** en la cuenta del registrador y del proveedor DNS; cuentas
    nominales, sin correo de contacto en el propio dominio que gestionas (dependencia circular).
  - **Auto-renovación multi-año** y alerta de expiración independiente del registrador.
  - **Vigilancia del NS RRset y del DS**: alerta ante cualquier cambio no originado en el repo.
    Un cambio de NS que no venga de un PR es un incidente hasta que se demuestre lo contrario.
  - `CAA` con `iodef` y **monitorización de Certificate Transparency** para detectar emisión
    no autorizada para tus nombres.
- **Subdominios colgantes (*dangling*) y takeover**: un `CNAME` o A/AAAA que apunta a un recurso
  liberado (bucket, PaaS, CDN, IP elástica devuelta) permite que un tercero reclame ese destino y
  sirva contenido bajo tu nombre —con cookies, SSO y confianza de marca incluidos.
  - **Indicador**: registros que resuelven a un destino que devuelve error de "recurso no
    reclamado", o cuya IP ya no pertenece a ninguno de tus rangos ni cuentas.
  - **Mitigación**: el borrado del registro DNS forma parte de la **misma** operación que la baja
    del recurso (`iac-standards`: destruir el recurso y su registro en el mismo `apply`);
    inventario cruzado periódico entre zona y recursos activos como gate recurrente; TTL bajo
    en registros de vida corta. Reserva especial de atención a los subdominios de campañas y
    entornos temporales, que nadie recuerda dar de baja.
- **Ciclo de vida**: cada registro tiene dueño y motivo en el repo. Registro sin dueño = registro
  a borrar, con período de gracia y observación de tráfico previa.

### 5.4 DNS como canal y como control

- **Registra el 100% de las consultas del resolver** con cliente, nombre, tipo y respuesta.
  Es la telemetría de seguridad de mayor relación valor/coste que existe. Tú garantizas su
  **calidad, cobertura y retención**; la analítica y las reglas son de
  `detection-engineering-standards`.
- **Exfiltración y C2 por DNS**: clase de riesgo real y de bajo coste para el atacante.
  **Indicadores** (para el operador, no procedimiento): volumen anómalo de consultas a un mismo
  dominio de segundo nivel, etiquetas largas y de alta entropía, número inusual de subdominios
  únicos, predominio de TXT/NULL/CNAME, y tasa alta de NXDOMAIN por cliente.
  **Mitigación**: resolución forzada por el resolver corporativo, límite de tasa por cliente,
  bloqueo de dominios recién registrados y de categorías de riesgo (RPZ), y respaldo con EDR
  —porque el DoH dentro de HTTPS no se cierra sólo con red.
- **Transferencias de zona**: `AXFR`/`IXFR` **sólo con TSIG (RFC 8945, STD 93)** y ACL por IP,
  claves distintas por par de servidores y rotadas. `AXFR` abierto entrega el mapa completo de tu
  infraestructura a cualquiera. Verifica que está denegado como prueba negativa (§4).
- **Privacidad y transporte cifrado — lo que implica para el operador**: DoT (853) es
  distinguible y por tanto **gobernable**; DoH (443) es indistinguible del tráfico web y
  **anula el filtrado y la visibilidad DNS** si lo activa la aplicación. Criterio: ofrece **tu
  propio** DoT/DoH/DoQ (mejor privacidad en el último salto sin perder control), impón política
  de navegador (`DnsOverHttpsMode` en Chrome/Edge, `network.trr.mode` en Firefox) y coordina con
  `firewall-policy-standards` el bloqueo de `53`/`853` salientes y de los resolvers DoH públicos
  conocidos. Y asume lo que cambia en el cable: con **ECH** (vía registros `HTTPS`) el SNI deja de
  ser visible — la inspección basada en SNI es una capacidad en extinción, no una estrategia.
- Cifrar el transporte **no** anonimiza frente al operador del resolver: mueve la confianza, no la
  elimina. Elegir un resolver público "por privacidad" es cambiar de observador.

## 6. Rendimiento y operabilidad

- **Señales que se vigilan siempre**: QPS y su distribución por tipo, latencia de respuesta
  (p50/p95/p99), tasa de SERVFAIL y de NXDOMAIN, ratio de acierto de caché, fallos de validación
  DNSSEC, consultas rechazadas por ACL/RRL, retraso de transferencia entre primario y secundarios
  (serial divergente), y tiempo hasta expiración de RRSIG y de dominio. Umbrales y alertas, en
  `observability-standards`.
- **SERVFAIL es la señal más importante y la peor entendida**: puede ser fallo de validación,
  autoritativo caído o timeout. Distinguir los tres casos exige log del recursivo, no del cliente.
- **Capacidad**: dimensiona por percentil real de QPS con margen para picos de NXDOMAIN (malware y
  aplicaciones rotas los generan a miles). La caché es lo que sostiene el servicio: vigila su
  tasa de acierto antes que la CPU.
- **Coste del TTL bajo**: cada reducción multiplica consultas a tus autoritativos. Un TTL de 30 s
  en un registro muy consultado es una decisión de capacidad, no sólo de agilidad.
- **Runbooks con dueño**: firma DNSSEC caducada, DS incorrecto tras rollover, secundario que no
  transfiere, resolver caído, dominio cerca de expirar, sospecha de secuestro de NS, subdominio
  reclamado por un tercero, resolver bajo amplificación. Cada uno con su comprobación desde fuera.
- **Recuperación**: el estado que hay que poder restaurar es el **repo de zonas + las claves
  DNSSEC** (custodia y respaldo cifrado en `cryptography-pki-standards` y `bcdr-standards`).
  Perder la KSK sin respaldo obliga a un rollover de emergencia con ventana de indisponibilidad.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisión de versión y CVE de todo el stack DNS **mensual** durante 2026 (BIND,
  Unbound y dnsmasq están publicando parches de seguridad casi cada mes por el aluvión de
  hallazgos asistidos por LLM); ninguna rama EOL en producción sin plan de salida fechado.
- **Revisión semestral del contenido de la zona**: registros sin dueño, apuntando a recursos
  inexistentes, selectores DKIM huérfanos, `include` de SPF de proveedores que ya no usas.
- **Deprecación real**: retirar un servicio incluye borrar su registro DNS, su selector DKIM, su
  entrada en SPF y su regla de firewall el mismo día.

**PROHIBIDO**
- ❌ Servir autoritativo y recursivo desde el mismo servidor o proceso.
- ❌ Resolver recursivo abierto a Internet; autoritativo que recursa.
- ❌ Un único servidor autoritativo, o varios sin diversidad de red/proveedor/ubicación.
- ❌ Migrar sin haber bajado el TTL con la antelación de al menos un TTL completo.
- ❌ `CNAME` en el ápice, o `CNAME` coexistiendo con otros tipos.
- ❌ Zona firmada con firmado o rotación **manual**; DNSSEC sin monitorización de expiración.
- ❌ NSEC3 con iteraciones > 0 o con salt (contra RFC 9276).
- ❌ `AXFR` sin TSIG y sin ACL; clave TSIG única compartida por toda la infraestructura.
- ❌ TLD inventados (`.local`, `.lan`, `.corp`, `.home`) para nombres internos.
- ❌ SPF con más de 10 lookups, múltiples registros `v=spf1`, o mecanismo `ptr`.
- ❌ DMARC en `p=none` indefinido; dominio sin correo sin `v=spf1 -all` + `p=reject` + `MX .`.
- ❌ Zona sin `CAA`, o `CAA` que no coincide con la CA que realmente emite.
- ❌ Publicar `TLSA`/DANE sin zona firmada o sin rotación acoplada al certificado.
- ❌ Editar zonas en el panel del proveedor en lugar del repo; ignorar la deriva detectada.
- ❌ Dominio sin registrar-lock, sin MFA en el registrador o sin alerta de expiración
  independiente del propio registrador.
- ❌ Contacto administrativo del dominio en una dirección del propio dominio gestionado.
- ❌ Borrar un recurso sin borrar su registro DNS (subdominio colgante).
- ❌ Reescribir NXDOMAIN a una IP propia ("search hijacking").
- ❌ Wildcards en el ápice o en zonas de producción sin justificación acotada.
- ❌ Resolver sin logging de consultas, o con retención por debajo de la ventana de investigación.
- ❌ Permitir DoH de aplicación hacia terceros sin política de navegador.
- ❌ `dnsmasq` < 2.93, BIND 9.18 o cualquier rama EOL expuesta.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, RFC, cifra de adopción o requisito de proveedor,
**búscalo — no lo recuerdes**. Verificado ago-2026:

- **Software** (rama y última publicada): BIND **9.20.26** (22-jul-2026; 9.18 **EOL jun-2026**;
  9.20 con soporte hasta ~Q1-2028; **9.22 retrasada al menos a Q4-2026**), Unbound **1.25.2**
  (22-jul-2026), NSD **4.15.0** (07-jul-2026), Knot DNS **3.5.6** (última etiqueta), Knot Resolver
  **6.4.x** (6.4.0, 17-jun-2026), PowerDNS Recursor **5.4.4**, PowerDNS Authoritative rama
  **5.1.x**, dnsdist **2.0.7/2.1.0**, CoreDNS **1.14.6** (10-jul-2026), dnsmasq **2.93**,
  Pi-hole FTL **6.7** (06-jul-2026), AdGuard Home **0.107.78** (13-jul-2026),
  dnscontrol **4.45.0** y octoDNS **1.21.1** (ambos 01-ago-2026). Todos con mantenimiento activo.
- **CVE**: CVE-2026-13321 (BIND, envenenamiento entre zonas, CVSS 8.6, corregido en 9.20.26 el
  22-jul-2026, junto a otras 8); CVE-2025-11411 (Unbound, NS promiscuos, 1.24.1/1.24.2);
  lote coordinado de 6 CVE en dnsmasq (11-may-2026) con CVE-2026-2291 corregido en 2.93/2.92rel2.
  **Re-verifica el mes en curso**: la cadencia de 2026 es mensual.
- **Correo**: Google/Yahoo desde feb-2024 (≥5.000/día); Gmail de `421` a rechazo `550` en
  nov-2025; Microsoft desde 05-may-2025 con `550 5.7.515` sin fase de aviso; La Poste sep-2025.
  DMARCbis publicado en **RFC 9989** (Standards Track, may-2026, obsoleta 7489 y 9091) y
  **RFC 9990** (informes agregados).
- **Adopción**: DNSSEC — validación ~35-36% global / ~49% UE (APNIC, 2025-2026), delegaciones
  firmadas ~7%, `.com` ~4,3% y `.net` ~5,3%; validación extremo a extremo ~0,47% (Q1-2026) →
  ~0,596% (may-2026) sobre ~8% de consultas a dominios firmados (Cloudflare Radar). DANE — ~30
  dominios con TLSA frente a ~16.000 con MTA-STS sobre 5,5 M escaneados (feb-2026); MTA-STS por
  debajo del 1% del top 1 M y ~30% mal configurado (IMC'25).
- **RFC verificados**: 9460 (SVCB/HTTPS, nov-2023), 9461/9462 (DoH mapping y DDR), 8659 (CAA,
  obsoleta 6844), 8461 (MTA-STS), 8460 (TLS-RPT), 8945 (TSIG, **STD 93**), 8482 (ANY mínimo),
  9250 (DoQ, may-2022), 9276 (NSEC3, **BCP 236**), 9364 (DNSSEC, **BCP 237**), 8375 (`home.arpa`).

**Huecos declarados — NO rellenar de memoria, verificar antes de usar**:
1. **PowerDNS Authoritative**: las fechas de blog encontradas para 5.1.0 (03-jun-2026) y 5.1.3
   (30-may-2026) son **incoherentes entre sí**; el punto exacto vigente de la rama 5.1.x y el
   estado de soporte de 5.0.x/4.9.x **no están confirmados**. Verificar en
   `doc.powerdns.com/authoritative/changelog/` antes de fijar versión.
2. **RFC 9991** (informes de fallo de DMARCbis): citado por fuentes secundarias, **no verificado**
   contra rfc-editor. Comprobar número y estado antes de referenciarlo.
3. **`.internal`**: reservado por ICANN (29-jul-2024), pero **no consta RFC del IETF publicado**;
   sólo un Internet-Draft. Verificar en datatracker si necesitas base normativa.
4. **Fechas exactas de release de Knot DNS 3.5.6 y de la rama LTS de Knot**: obtenidas de
   etiquetas de repositorio, sin fecha confirmada ni política de soporte verificada.
5. **RFC 2308 (TTL negativo), 7873 (cookies DNS), 9156 (QNAME minimisation), 7344/8078 (CDS/CDNSKEY),
   8058 (one-click unsubscribe), 6762 (mDNS/`.local`), 8020 (NXDOMAIN cut)**: números citados de
   memoria y **no verificados** en esta pasada. Contrastar antes de citarlos como autoridad.
6. **Requisitos de Apple** como proveedor de correo: se anticipa alineamiento con Google/Microsoft
   pero **no hay política formal confirmada**. No lo afirmes como requisito.
7. **Estado de mantenimiento de `zonemaster` y `dnsviz`**: no verificado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
