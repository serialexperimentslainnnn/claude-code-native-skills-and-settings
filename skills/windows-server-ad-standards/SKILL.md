---
name: windows-server-ad-standards
description: Windows Server and Active Directory Domain Services security standards. Use when working with AD DS forests, domains, OUs, sites and replication, Group Policy (GPO, gpresult, SYSVOL), Tier 0/Enterprise Access Model and Privileged Access Workstations, Domain Admins and AdminSDHolder, gMSA/dMSA service accounts, krbtgt rotation, Kerberos vs NTLM and Negotiate, SMB signing and LDAP channel binding, AD CS certificate templates, Protected Users, Windows LAPS, PingCastle, Purple Knight or BloodHound/SharpHound assessments, Microsoft Security Compliance Toolkit baselines, ntdsutil, dcdiag, repadmin, dsquery, Server Core, WSUS or Azure Update Manager patching, or AD forest recovery from system state backup.
---

# Estándares de Windows Server y Active Directory

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, endurecer, operar y recuperar **el directorio y la plataforma Windows Server**:
decisión AD DS on-prem vs Entra ID vs híbrido, diseño de bosque/dominio/OU/sitios, modelo de
administración por niveles y PAW, grupos y delegación privilegiada, cuentas de servicio, AD CS como
vector de compromiso del directorio, autenticación Kerberos/NTLM y su endurecimiento, higiene y
auditoría del directorio, baselines de configuración por GPO o Intune, operación y parcheo del SO,
PowerShell seguro, y **continuidad y recuperación del bosque**.

Triggers: `Active Directory`, `AD DS`, `ntds.dit`, `ntdsutil`, `dcdiag`, `repadmin`, `dsquery`,
`Get-ADUser`/`Get-ADDomain`/módulo `ActiveDirectory`, `gpresult`, `SYSVOL`, `NETLOGON`, `GPO`,
`Domain Admins`, `Enterprise Admins`, `AdminSDHolder`, `adminCount`, `Protected Users`,
`krbtgt`, `SPN`, `gMSA`, `dMSA`, `msDS-ManagedAccountPrecededByLink`, `Kerberos`, `NTLM`,
`Negotiate`, `LmCompatibilityLevel`, `SMB signing`, `LDAP channel binding`, `ldapsigning`,
`AD CS`, `certsrv`, plantillas de certificado, `Windows LAPS`, `LAPSAD`, `PingCastle`,
`Purple Knight`, `BloodHound`, `SharpHound`, `Security Compliance Toolkit`, `LGPO.exe`,
`Server Core`, `WSUS`, `Azure Update Manager`, `pwsh` vs `powershell.exe`, `JEA`, `WinRM`,
"recuperación del bosque", "el DC no replica".

**Principio rector**: **el bosque es el límite de seguridad, no el dominio**, y **el compromiso de
AD es el compromiso de todo**. Un atacante con Domain Admin (o con cualquiera de las docenas de
caminos equivalentes que un directorio real acumula) no ha comprometido un servidor: ha comprometido
la identidad de la organización entera, incluida la de los sistemas que "no son Windows" pero
autentican contra él. Todo lo que sigue se ordena por esa asimetría.

**Postura**: esta skill es **defensiva**. Las técnicas de ataque se describen como **clase de
riesgo, indicador y mitigación**, nunca como procedimiento de explotación. El uso de herramientas de
análisis de rutas de ataque (BloodHound) aquí es **de defensor**: ver lo que ve el atacante para
cortarlo. Lo ofensivo autorizado vive en `offensive-security-standards`.

**No aplica**: ver `identity-access-management-standards` (**la federación moderna es suya**:
OAuth 2.1/OIDC, SAML, passkeys/WebAuthn y política de MFA, SCIM, motores de autorización
RBAC/ABAC/ReBAC, SPIFFE, PAM/JIT genérico y break-glass como patrón, ciclo joiner-mover-leaver.
**Aquí**: el **directorio** —objetos, OU, GPO, delegación, replicación— y **Kerberos/NTLM** como
protocolos del dominio, más la aplicación concreta de tiering y PAW sobre AD); `azure-standards`
(**Entra ID como IdP de plataforma**, Conditional Access, PIM, gobernanza del tenant y AKS — la
decisión "AD DS o Entra" se toma aquí, la operación del tenant es allí); `cryptography-pki-standards`
(**la PKI como diseño es suya**: jerarquía de CA, algoritmos, HSM, ciclo de vida y rotación de claves,
ACME, mTLS. **Aquí solo el abuso del directorio a través de AD CS**: plantillas, permisos de
enrolamiento, ACL de la CA y el mapeo certificado↔cuenta. Si la pregunta es "qué CA y con qué
claves", es de allí; si es "quién puede pedir un certificado que suplante a un admin", es de aquí);
`linux-hardening-standards` (**paralelo Linux del que esta skill es el equivalente Windows**:
baselines CIS/STIG, medición con OpenSCAP/Lynis, auditd — mismo criterio, otro SO);
`onprem-standards` (paraguas de plataforma: hardware, hipervisor, plano OOB, topología de flota —
sus invariantes aplican, y **la virtualización que hospeda un DC es Tier 0 por definición**);
`networking-standards` (segmentación, firewall entre zonas, DNS como servicio de red — aquí el DNS
integrado en AD y los puertos que exige el dominio); `detection-engineering-standards`
(**frontera decidida**: *qué evento de AD importa y por qué* es de esta skill; *el
ciclo de vida de la regla* —cobertura ATT&CK, tuning, umbrales, test, SIEM— es suyo);
`observability-standards` (recogida, retención e integridad de esos eventos);
`incident-response-forensics-standards` (**el proceso forense y la respuesta al compromiso**:
contención, imaging, timeline, erradicación y rotación masiva de credenciales — **aquí solo qué
artefacto del directorio existe y qué exige su recuperación**); `incident-management-standards`
(gobierno del incidente); `bcdr-standards` (RTO/RPO, plan de continuidad y
ejercicios de DR **de la organización** — **la recuperación del bosque en concreto es de aquí**, por
ser un procedimiento propio del directorio y no una restauración de servidor);
`vulnerability-management-standards` (triaje, SLA y seguimiento de EOL);
`secrets-management-standards` (custodia y rotación de secretos de
aplicación); `grc-compliance-standards` (el control exigido por ISO/ENS/NIST y su evidencia);
`dotnet-standards` (el código C# que corre encima); `powershell-standards` (**frontera recíproca y
constante**: aquí se decide **qué** se administra —bosque, OU, GPO, Kerberos, gMSA, Tier 0— y **qué
módulo y cmdlet** lo hace; **cómo se escribe el script** —verbos aprobados, `SupportsShouldProcess`
con `-WhatIf`, `Set-StrictMode`, manejo de errores, `PSScriptAnalyzer`, Pester, JEA y firma— es
suyo. **Prohibido duplicar aquí criterio de lenguaje.**); `iac-standards` (Ansible/Terraform como
herramienta); `cicd-standards`; `offensive-security-standards` y `ctf-lab-standards`
(ejercicio ofensivo con alcance y autorización por escrito, y laboratorio aislado — esta
skill es defensiva); `homelab-standards` (dominio de laboratorio con criterio proporcional);
`container-runtime-security-standards` y `kubernetes-standards` (la otra plataforma cuyo compromiso
es total — mismo criterio de contención por capas, dominio distinto).

## 2. Decisiones por defecto

> Verificar la última versión, fecha de EOL y estado de feature por web antes de fijarla (§8). En
> este dominio la memoria falla especialmente con NTLM, WSUS, LAPS y las fechas de soporte.

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| ¿AD DS on-prem? | **Solo si hay una dependencia real que lo exija** | Justifican dominio propio: aplicaciones que solo hablan Kerberos/LDAP/NTLM, file servers y print, GPO sobre equipos no gestionables por Intune, OT/industrial, requisito de operación sin conectividad. **No lo justifican**: "siempre lo hemos tenido", correo, VPN, SSO web moderno o gestión de portátiles — todo eso vive mejor en `identity-access-management-standards`/`azure-standards` |
| Híbrido | **Es el estado real de casi todos**, y hay que **diseñarlo**, no dejar que ocurra | El riesgo del híbrido es la **fusión de planos**: una cuenta con privilegio en AD que también lo tiene en el tenant convierte un compromiso on-prem en compromiso cloud. Cuentas privilegiadas de nube **solo en la nube** y viceversa; el servidor de sincronización es **Tier 0** |
| Versión de SO | **Windows Server 2025** en despliegues nuevos y en DCs | Verificado ago-2026: GA 1-nov-2024, soporte estándar hasta **13-nov-2029**, extendido hasta **14-nov-2034**. **Server 2016 muere el 12-ene-2027** (migración urgente) y **Server 2022 sale de soporte estándar el 13-oct-2026** (sigue parcheado, sin funcionalidad nueva). Server 2019 en extendido hasta 9-ene-2029 |
| Instalación | **Server Core** para DC y roles de infraestructura | Menos superficie, menos parches, menos "alguien navegó desde el servidor". GUI solo con justificación por dependencia de aplicación |
| Nivel funcional | El más alto que soporten **todos** los DC, y plan para subirlo | Features de seguridad recientes (incluidas las de Kerberos y cuentas de servicio) dependen del nivel funcional, no solo de la versión del DC |
| Modelo de administración | **Enterprise Access Model** (planos *control* / *gestión* / *datos-cargas*) como marco, con el **modelo de niveles AD (Tier 0/1/2) como su implementación on-prem** | Verificado ago-2026: Microsoft **no ha retirado el tier model**; lo reclasificó como *guía legacy* y lo documenta como **componente del EAM**. Si no hay migración a nube, el enfoque por niveles sigue siendo recomendación de alta prioridad. **Las tres reglas no han cambiado**: (1) una credencial de nivel superior nunca se expone en un sistema de nivel inferior; (2) el nivel inferior consume servicios del superior, nunca al revés; (3) **quien puede gestionar un sistema pertenece a su nivel, se quiera o no** — incluidos el hipervisor, el backup y la herramienta de gestión |
| Estación de administración | **PAW** dedicada para Tier 0, sin correo, sin navegación, sin ofimática | Sin PAW, el tiering es un diagrama: la credencial de admin acaba tecleada en el equipo con el que se leen adjuntos |
| Cuentas de servicio | **gMSA** por defecto (contraseña gestionada por el dominio, rotación automática, sin secreto humano) | La cuenta de usuario con SPN y contraseña estática es la vulnerabilidad estructural más rentable del directorio. **dMSA**: ver §3.4 — introducida en Server 2025, con historia de seguridad conocida; adóptala con la mitigación aplicada, no por defecto |
| Contraseña de admin local | **Windows LAPS** (integrado en el SO) | Verificado ago-2026: el **LAPS legacy está deprecado**, su MSI **bloqueado** en Windows 11 23H2+ y sin cambios de código; se soporta solo hasta el EOL del SO donde ya estaba. Windows LAPS añade **respaldo a Entra ID, cifrado de la contraseña en AD, historial y gestión del password de DSRM en los DC** — esto último importa directamente para §3.9 |
| Baseline de configuración | **Microsoft Security Compliance Toolkit** (baseline versionada + `LGPO.exe`), aplicada por **GPO** en servidores de dominio y por **Intune** en lo gestionado modernamente | Verificado ago-2026: SCT sigue siendo la vía soportada (SCM está retirado); baseline vigente de Server 2025 **v2602 (feb-2026)**, con cadencia de revisión acelerada desde v2506. Complementa —no sustituye— al CIS o al STIG si hay requisito formal |
| Parcheo | **Transición planificada fuera de WSUS** | Verificado ago-2026: **WSUS está deprecado desde 20-sep-2024** (sin funcionalidad nueva ni nuevas peticiones de feature) **pero no muerto**: sigue enviándose con Server 2025, publica actualizaciones, sostiene el Software Update Point de ConfigMgr y **no tiene fecha de fin anunciada** (hereda el ciclo de Server 2025, hasta 2034). Reemplazo recomendado por Microsoft, **partido en dos**: **Intune/Windows Autopatch** para clientes y **Azure Update Manager** (vía Arc para no-Azure) para servidores. **No hay sustituto 1:1** |
| PowerShell | **7.6 LTS** para automatización nueva; **Windows PowerShell 5.1 se conserva**, no se desinstala | Verificado ago-2026: **7.6 LTS** (18-mar-2026, sobre .NET 10) soportado hasta **14-nov-2028**; **7.4 LTS y 7.5 mueren ambos el 10-nov-2026** junto a .NET 8 — saltar de 7.4 a 7.5 no compra tiempo. 5.1 no tiene EOL propio: sigue el ciclo del SO |
| Higiene medida | **PingCastle** (puntuación y tendencia) + **Purple Knight** (indicadores de exposición y compromiso) | Ambos gratuitos para autoevaluación. **PingCastle**: adquirido por **Netwrix**, edición Open Source bajo **NPOSL-3.0** (uso interno sí, monetizar o auditar a terceros no, eso exige licencia comercial) y **caduca por versión** — al llegar el fin de soporte de una versión, el binario deja de ejecutarse (el 3.3.0.0 caducó el 31-ene-2026): planifica la actualización como tarea recurrente. **Purple Knight** (Semperis): Community 5.0, 210+ indicadores, mapeo a MITRE ATT&CK y ANSSI, soporte de GCC High desde abr-2026 |
| Rutas de ataque | **BloodHound Community Edition** (Apache-2.0, SpecterOps) en uso **defensivo**, recurrente | Es la herramienta con la que el defensor ve el grafo real de privilegio —lo que ve el atacante— y **corta las aristas**. La medida de éxito no es el informe: es la reducción del número de caminos a Tier 0 entre ejecuciones. BloodHound Enterprise añade cobertura continua de AD, Entra, AWS y Okta |
| Guía externa de referencia | **"Detecting and Mitigating Active Directory Compromises"** (Five Eyes: ASD/ACSC, CISA, NSA, CCCS, NCSC-NZ, NCSC-UK) | Verificado ago-2026: publicada el **26-sep-2024**. 17 técnicas observadas con su mitigación, cubriendo AD DS, AD FS y AD CS. Es la mejor referencia única y gratuita del dominio; úsala como plan de trabajo |

## 3. Diseño, endurecimiento y operación

### 3.1 Diseño del directorio

- **El bosque es el límite de seguridad. El dominio no lo es.** Un dominio adicional "por seguridad"
  no aporta separación: quien es admin en un dominio tiene camino al bosque. Si necesitas separación
  real (entidad legal distinta, requisito regulatorio, red aislada), es **otro bosque**, con
  confianza selectiva, filtrado de SID y una razón escrita.
- **Un dominio, un bosque, por defecto.** Los dominios múltiples heredados casi nunca sobreviven a
  un análisis de coste/beneficio: consolidar reduce superficie, complejidad de replicación y
  caminos de escalada.
- **OU por función administrativa, no por organigrama**: la OU es la unidad de delegación y de
  aplicación de GPO. Un árbol de OU que copia el organigrama produce delegaciones absurdas y GPO
  imposibles de razonar. Separación explícita de OU por **nivel** (Tier 0/1/2) para que el
  privilegio sea visible en la estructura.
- **Sitios y replicación** modelados sobre la topología de red real (subredes registradas, coste de
  enlaces, ventanas). Síntoma clásico: autenticación lenta o errática porque las subredes no están
  asociadas a sitio y los clientes eligen un DC remoto.
- **DNS integrado en AD** con zonas replicadas al bosque o al dominio según alcance; sin
  reenviadores a resolutores no controlados y **con el DNS del DC apuntándose entre sí, nunca a
  sí mismo como único servidor** (bloquea la replicación al arrancar). Delegación de la zona
  `_msdcs` correcta o la localización de DC falla de formas difíciles de diagnosticar.
- **Confianzas**: las mínimas, unidireccionales cuando basta, **selectivas** y con **filtrado de SID
  activo**. Una confianza bidireccional con filtrado desactivado convierte dos bosques en uno solo a
  efectos de compromiso. Inventariadas y revisadas: las confianzas son deuda que nadie recuerda
  haber contraído.
- **Los DC son Tier 0 y solo eso**: sin roles adicionales (nada de IIS, SQL, ficheros, aplicaciones,
  hipervisor, backup ni agentes no aprobados), sin navegación a Internet y sin acceso saliente
  general. **Todo lo que gestiona un DC es Tier 0**: hipervisor, almacenamiento, backup, EDR, PXE,
  herramienta de despliegue y la consola de gestión. Ese inventario suele ser el hallazgo más
  incómodo de una evaluación honesta.

### 3.2 Tiering, PAW y el plano de administración

- **Tier 0** = todo lo que puede controlar el directorio (DC, AD CS, ADFS, servidor de
  sincronización a Entra, gestores de identidad, backup del directorio, virtualización que los
  hospeda). **Tier 1** = servidores y aplicaciones. **Tier 2** = estaciones de usuario.
- **Cuentas administrativas separadas por nivel**, sin buzón, sin navegación, sin uso interactivo
  fuera de su plano. Una persona = varias cuentas; una cuenta = un nivel.
- **PAW** para Tier 0 (y para la administración cloud privilegiada), endurecida con baseline propio,
  arranque seguro, cifrado, sin correo ni navegador general, con acceso solo a los destinos de su
  nivel. Sin PAW no hay tiering.
- **Contención del inicio de sesión**: denegar por GPO el logon interactivo, por servicio y por lote
  de las cuentas de Tier 0 en Tier 1 y Tier 2 (y recíprocamente en lo que aplique). Es el control
  que hace efectiva la regla 1. `Authentication Policy Silos` y **Protected Users** para reforzarlo.
- **Cero acceso permanente**: elevación con aprobación y ventana corta también on-prem. El patrón
  genérico de PAM/JIT es de `identity-access-management-standards`; **aquí su aplicación al
  directorio**.
- **Regla de oro operativa**: si una credencial de Tier 0 se ha usado alguna vez en un sistema de
  nivel inferior, se considera comprometida. No hay término medio ni "es que fue solo un momento".

### 3.3 Grupos, privilegio y delegación

- **`Domain Admins`, `Enterprise Admins` y `Schema Admins` vacíos en operación normal.** La
  pertenencia es un evento de elevación con ticket, ventana y alerta, no un estado. Igual con
  `Administrators` del dominio, `Backup Operators`, `Account Operators`, `Print Operators` y
  `Server Operators`, que son Tier 0 de facto por sus privilegios y casi nunca se necesitan.
- **Delegación granular por OU** en lugar de pertenencia a grupos privilegiados: alta de usuarios,
  reset de contraseñas, unión al dominio, gestión de equipos. Documentada y **auditada** — las ACL
  delegadas acumuladas durante 15 años son el sustrato de la mayoría de los caminos de escalada.
- **`AdminSDHolder` y `adminCount`**: la plantilla que reimpone ACL sobre los grupos protegidos cada
  hora (SDProp). Dos consecuencias prácticas: (1) **modificar `AdminSDHolder` es una vía de
  persistencia** — su ACL se audita y se alerta ante cambios; (2) los objetos con `adminCount=1`
  huérfanos (cuentas que salieron de un grupo protegido y conservan la ACL y la herencia rota) son
  ruido peligroso: se limpian.
- **`SeEnableDelegationPrivilege`, `DCSync` (Replicating Directory Changes All), `WriteDACL`,
  `GenericAll`, `WriteOwner` sobre objetos de nivel superior**: son equivalentes a Domain Admin
  aunque nadie lo llame así. **Se inventarían y se cortan**; es exactamente lo que revela el grafo
  de BloodHound.
- **Protected Users**: pertenencia para todas las cuentas privilegiadas. Fuerza Kerberos (sin NTLM,
  sin delegación, sin cifrados débiles, sin caché de credenciales), a cambio de romper flujos
  legacy — se despliega por anillos y se validan las dependencias. **Ojo**: no aplica a cuentas de
  servicio que necesiten delegación, y no protege la cuenta si el DC no está al día.
- **Cuentas de servicio**: **gMSA** por defecto. Toda cuenta de usuario con SPN y contraseña estática
  es un hallazgo — su contraseña es *offline-crackable* por cualquier usuario del dominio (clase de
  riesgo: solicitud masiva de tickets de servicio). Si por dependencia no puede migrarse: contraseña
  larga y aleatoria (≥25 caracteres), rotación real, privilegio mínimo, **nunca** en grupos
  privilegiados y **nunca** con delegación no restringida.

### 3.4 dMSA: adóptala con la mitigación puesta

- **Qué son**: *delegated Managed Service Accounts*, introducidas en **Windows Server 2025**, que
  extienden gMSA añadiendo la **migración de una cuenta de servicio no gestionada existente** a una
  cuenta gestionada, vinculada a la identidad de una máquina.
- **Riesgo conocido — BadSuccessor** (Akamai, Yuval Gordon): **abuso de la funcionalidad de
  migración**, no un bug de memoria. Clase de riesgo: quien puede **crear objetos en una OU** puede
  crear una dMSA y **vincularla a una cuenta privilegiada** mediante los atributos de migración
  (`msDS-ManagedAccountPrecededByLink`, `msDS-DelegatedMSAState`), obteniendo del KDC tickets con los
  SID de esa cuenta — **sin tocar sus grupos ni su credencial**. Verificado ago-2026: funciona en
  configuración por defecto, y en el **91 %** de los entornos analizados por Akamai había cuentas
  fuera de Domain Admins con los permisos necesarios. **Basta un solo DC de Server 2025 en el
  bosque para estar expuesto.**
- **Mitigación obligatoria antes de introducir el primer DC de Server 2025**:
  1. **Restringir la creación de objetos `msDS-DelegatedManagedServiceAccount`** a un grupo
     administrativo designado, revisando **quién puede crear objetos en cada OU** (que es el permiso
     que casi nadie audita).
  2. **SACL de auditoría sobre la creación de dMSA** (**evento 5137**) y sobre la modificación de sus
     atributos de migración; alerta ante creación por identidad o desde ubicación inesperada.
  3. Considerar el **bloqueo del caso de uso de migración a nivel de esquema del bosque** (método
     publicado por Semperis) si no vas a usar la funcionalidad.
- **Regla**: dMSA **no es el default**. gMSA lo es. dMSA se adopta cuando su migración aporta valor
  real y con los tres controles anteriores verificados.

### 3.5 AD CS: la PKI que compromete el directorio

- **Frontera**: el diseño de la PKI (jerarquía, algoritmos, HSM, ciclo de vida de claves) es de
  `cryptography-pki-standards`. **Aquí, el abuso del directorio a través de AD CS.**
- **Familias de configuración vulnerable** (clase de riesgo y mitigación, sin procedimiento):
  - **Plantilla que permite al solicitante fijar el sujeto** (`Enrollee Supplies Subject`) con EKU de
    autenticación de cliente y enrolamiento abierto a usuarios poco privilegiados → **suplantación de
    cualquier identidad, incluida la de administrador**. *Mitigación*: retirar el flag, o restringir
    enrolamiento y exigir aprobación del gestor de certificados.
  - **Plantilla con EKU "cualquier propósito" o sin EKU** y enrolamiento amplio → certificado
    utilizable para autenticar. *Mitigación*: EKU explícita y mínima por plantilla.
  - **Permisos de escritura o propiedad sobre la plantilla** por parte de grupos no privilegiados →
    el atacante **crea** la configuración vulnerable. *Mitigación*: auditar propietario y ACL de
    **todas** las plantillas, no solo de las publicadas.
  - **Configuración a nivel de CA que permite indicar el sujeto alternativo con independencia de la
    plantilla** → convierte plantillas seguras en explotables. *Mitigación*: desactivarla y auditar
    el flag.
  - **Permisos excesivos sobre la propia CA** (gestión de CA / gestión de certificados) → emisión y
    aprobación arbitrarias. *Mitigación*: separación de funciones entre administración de PKI y de
    AD; la CA es **Tier 0**.
  - **Enrolamiento web y endpoints expuestos sin TLS ni protección de canal** → retransmisión de
    autenticación hacia la CA. *Mitigación*: HTTPS, Extended Protection for Authentication, y
    retirar los endpoints que no se usen.
- **Mapeo fuerte certificado↔cuenta**: verificado ago-2026, el ciclo de **KB5014754** está **cerrado**
  — los DC pasaron a **aplicación completa en febrero de 2025** y en **septiembre de 2025 Microsoft
  eliminó la posibilidad de volver al modo compatibilidad**. Consecuencias: un certificado sin
  extensión de SID **no autentica**; rompen tarjetas inteligentes, 802.1X, VPN y dispositivos
  enrolados por SCEP de terceros que no incluyan el SID. **Requiere todos los DC en Server 2019+.**
  Esto eleva mucho el listón frente a la suplantación por SAN, pero **no sustituye la higiene de
  plantillas**: los otros vectores siguen vivos.
- **Auditoría continua**: inventario de plantillas publicadas con sus flags, EKU, permisos de
  enrolamiento y propietario; alerta ante emisión de certificados de autenticación para cuentas
  privilegiadas. Es de las revisiones con mejor relación esfuerzo/riesgo del dominio.

### 3.6 Autenticación: Kerberos, NTLM y el canal

- **Kerberos es el protocolo; NTLM es deuda.** Verificado ago-2026, con precisión (es el dato que
  más se cita mal de memoria):
  - Microsoft **deprecó NTLM en julio de 2024** (recomendación: `Negotiate` o Kerberos). *Deprecado
    ≠ eliminado*: NTLM sigue funcionando.
  - **NTLMv1 sí fue eliminado** como protocolo en **Windows 11 24H2 y Windows Server 2025**. Quedan
    restos de criptografía NTLMv1 en escenarios concretos (p. ej. MS-CHAPv2 en entorno de dominio);
    **Credential Guard** los cubre y los cambios en curso solo afectan a equipos **sin** Credential
    Guard.
  - Clave `BlockNTLMv1SSO` (`HKLM\SYSTEM\CurrentControlSet\Control\Lsa\msv1_0`): desplegada en modo
    **auditoría** desde las actualizaciones de sep-2025 (evento **4024** cuando se usan credenciales
    derivadas de NTLMv1), y Microsoft **cambia el default a *enforce* en octubre de 2026** salvo que
    la hayas fijado tú. **Acción**: despliégala tú en auditoría, recoge y corrige antes de esa fecha.
  - En camino: **IAKerb** y **Local KDC** (Kerberos para cuentas locales y escenarios de grupo de
    trabajo), previstos para la segunda mitad de 2026, que retiran motivos habituales de caída a
    NTLM.
- **Plan NTLM realista**: auditar (los logs mejorados de 24H2/Server 2025 identifican cuenta,
  proceso, máquina e IP, en cliente y en servidor) → eliminar dependencias → restringir por política
  (`Network security: Restrict NTLM`) por anillos → bloquear. Empezar por los **DC**. Un bloqueo sin
  fase de auditoría es una interrupción garantizada.
- **NTLMv1 y LM: prohibidos** (`LmCompatibilityLevel` en el valor que solo permite NTLMv2 y rechaza
  LM/NTLMv1 en cliente y servidor).
- **Delegación Kerberos**:
  - **No restringida (*unconstrained*): PROHIBIDA**, sin excepciones. Un servidor con delegación no
    restringida almacena TGT de quien se conecta — incluidos los de cuentas privilegiadas y **los de
    los propios DC**. Es una puerta trasera de dominio con nombre de feature.
  - **Restringida** (a servicios concretos) o **RBCD** (control en el recurso, que es el modelo más
    sano) con criterio, inventariadas y revisadas. **Cuidado**: quien puede escribir el atributo de
    delegación del recurso controla quién puede suplantar contra él — ese permiso es privilegio.
  - Cuentas sensibles marcadas como *no delegables* y/o en **Protected Users**.
- **Endurecimiento del canal**, sin negociación:
  - **Firma SMB obligatoria** en cliente y servidor (requisito, no "si el otro lado quiere"), y
    **SMBv1 desinstalado**. La firma es lo que corta la clase de riesgo de retransmisión.
  - **LDAP con firma obligatoria y *channel binding* (EPA)** en los DC; **LDAPS** para lo que aún
    consulte en claro; prohibido el *simple bind* sin TLS.
  - Cifrados Kerberos: **AES**; RC4 y DES retirados por política (verificando antes qué se rompe:
    confianzas antiguas y appliances suelen ser el freno).
- **`krbtgt`**: su clave firma todo ticket del dominio. Clase de riesgo: quien la obtiene puede
  forjar tickets arbitrarios y **sobrevive al reset de todas las contraseñas**. Reglas: **rotación
  doble** (dos cambios, separados por más del tiempo de vida máximo de ticket **y** por al menos un
  ciclo completo de replicación verificado a todos los DC — hacerlas seguidas invalida tickets
  válidos y provoca una caída de autenticación), rotación **programada** (no solo tras incidente) y
  **obligatoria** ante cualquier sospecha de compromiso de DC. **La rotación de `krbtgt` no evicta a
  un atacante que conserve otros mecanismos de persistencia**: es un paso de la erradicación, no la
  erradicación.
- **Contraseñas de máquina**: rotación automática cada 30 días por defecto — **no la desactives**
  (una cuenta de equipo con contraseña congelada es una credencial estática de larga vida). Ojo con
  las restauraciones de VM: un snapshot revertido puede desincronizar la contraseña y romper la
  confianza del equipo.
- **Política de contraseñas moderna**: longitud alta (frase de paso), **sin caducidad periódica
  arbitraria**, **sin reglas de composición**, con **bloqueo por lista de contraseñas comprometidas**
  (Entra Password Protection también on-prem, o equivalente), *fine-grained password policies* para
  cuentas privilegiadas y de servicio, y **MFA** en todo acceso administrativo (mecanismos y política
  en `identity-access-management-standards`). Bloqueo inteligente frente a *password spraying*, que
  es la técnica que realmente se usa.

### 3.7 Higiene medida y auditoría continua

- **La higiene de AD se mide con puntuación y tendencia, no con opiniones.** Cadencia mínima
  trimestral, con la serie histórica visible:
  - **PingCastle**: score de riesgo por categorías; sirve para dirección y para la conversación con
    negocio. Vigilar la caducidad por versión (§2).
  - **Purple Knight**: indicadores de exposición y de compromiso, con mapeo a ATT&CK y ANSSI.
  - **BloodHound CE**: el grafo. La métrica que importa es **cuántos caminos llegan a Tier 0 y desde
    cuántas cuentas de origen**, y que ese número **baje** entre ejecuciones. Un informe que nadie
    convierte en aristas cortadas es teatro.
  - Recolección con SharpHound/AzureHound tratada como operación privilegiada: quién la ejecuta,
    desde dónde y **dónde acaba el fichero** (un volcado del grafo del dominio en un portátil es un
    regalo para el atacante). Se conserva cifrado, con retención acotada.
- **Limpieza estructural recurrente**: cuentas y equipos inactivos, `adminCount` huérfanos, SPN
  innecesarios, delegaciones no usadas, GPO no vinculadas, confianzas olvidadas, miembros de grupos
  privilegiados, permisos "temporales" de hace años. **La superficie de AD crece sola**; si nadie
  poda, el grafo se llena de caminos.
- **Eventos que importan de verdad** (qué vigilar; el ciclo de vida de la regla es de
  `detection-engineering-standards`, su recogida de `observability-standards`):
  cambios en grupos privilegiados y en **`AdminSDHolder`**; creación o modificación de **dMSA** y sus
  atributos de migración (**5137**); cambios en plantillas de certificado y **emisión de certificados
  de autenticación para cuentas privilegiadas**; alta o cambio de **SPN**; modificación de atributos
  de **delegación**; **replicación solicitada desde un origen que no es un DC** (indicador de
  extracción del directorio); autenticación **NTLM** hacia DC y uso de credenciales derivadas de
  **NTLMv1** (**4024**); bloqueos y fallos masivos (*spraying*); inicio de sesión de cuenta de Tier 0
  en un sistema de nivel inferior; cambios de GPO y escrituras en **SYSVOL**; creación de cuentas y
  de confianzas; cambio de `krbtgt`; parada de la auditoría o borrado del log de seguridad.
- **Los logs de los DC salen del DC**: reenvío al SIEM con integridad y retención suficiente para
  investigar meses atrás — los actores sofisticados persisten mucho más que la retención por
  defecto. Un log que solo vive en el DC comprometido no es evidencia.
- **Auditoría avanzada configurada por baseline** (categorías detalladas, no la política heredada),
  incluyendo **línea de comandos en la creación de procesos** y **logging de bloque de script de
  PowerShell**, con el SIEM verificando que los ingiere.

### 3.8 Operación del SO y PowerShell

- **GPO** sigue siendo el mecanismo del dominio para servidores y equipos unidos; **Intune** para
  flota moderna. Convivencia deliberada, no accidental: definir qué manda cada uno y evitar
  configuraciones en ambos sitios (ganar/perder silencioso). Baseline aplicada **y verificada**, no
  solo enlazada (§4).
- **GPO como código**: exportadas, versionadas y revisadas por PR; detección de drift y de GPO
  huérfanas o desvinculadas. **Los permisos de edición de una GPO enlazada a Tier 0 son Tier 0.**
- **SYSVOL** es ejecución de código en toda la flota: su ACL, sus scripts y su integridad se
  auditan. Nunca contraseñas en scripts ni en preferencias de GPO.
- **PowerShell seguro** (los cuatro a la vez, o no cuenta):
  - **Script Block Logging** y **Module Logging** activados por GPO, con transcripción a ubicación
    protegida y reenvío al SIEM.
  - **JEA** (Just Enough Administration) para tareas delegadas: endpoints restringidos con conjunto
    de comandos acotado y ejecución bajo identidad virtual, en lugar de conceder administración
    completa.
  - **Remoting** solo sobre canal autenticado y cifrado, **con CredSSP prohibido** (expone
    credenciales en el destino) y restringido por origen; administración desde PAW.
  - **AppLocker o WDAC** en modo restrictivo donde se pueda, y **Constrained Language Mode** como
    consecuencia útil de una política de control de aplicaciones bien puesta.
  - `pwsh` 7.6 LTS para automatización nueva; **5.1 se conserva** para dependencias documentadas.
    Ninguna política debe borrar 5.1 "para modernizar".
- **Superficie del servidor**: Server Core, roles mínimos, **sin navegación desde servidores**,
  firewall de host activo con reglas explícitas, cuentas locales gestionadas por Windows LAPS,
  **Credential Guard** y **LSA Protection** activados donde el hardware lo permita (son controles de
  primera línea contra el robo de credenciales en memoria), y arranque seguro + BitLocker en DC
  (especialmente en sucursales y en cualquier DC no físicamente controlado).
- **RODC** para emplazamientos sin seguridad física, con política de replicación de contraseñas
  restrictiva — pero sin confundirlo con un control fuerte: es reducción de daño, no aislamiento.

### 3.9 Continuidad: el peor día posible

- **Un backup normal no basta.** La recuperación de un bosque comprometido **no es restaurar
  servidores**: es un procedimiento propio, largo y frágil, que casi nadie ha ejecutado nunca.
  Diferencias que lo hacen distinto:
  - Se restaura **estado del sistema** de un DC por dominio, en **modo restauración de servicios de
    directorio (DSRM)**, **con la red aislada** para impedir que un DC superviviente comprometido
    reinfecte o que la replicación propague el estado malo.
  - Hay que **limpiar metadatos** de todos los DC que no se recuperan, **incautar los roles FSMO**,
    **invalidar el pool de RID**, **rotar `krbtgt` dos veces**, rotar cuentas de confianza y
    credenciales de servicio, y solo entonces reconstruir el resto de DC **desde cero** (nunca
    restaurando el resto de backups: se promocionan limpios y replican del recuperado).
  - **La contraseña de DSRM es parte del plan** y hay que conocerla el día del incidente: gestionada
    por Windows LAPS en los DC (§2) y custodiada fuera del dominio.
  - Todo el material necesario —medios, claves de cifrado del backup, credenciales, documentación,
    contactos— debe estar **fuera del dominio que ha caído**. Un runbook alojado en un file server
    del dominio no existe el día que hace falta.
- **Backups**: estado del sistema de **al menos dos DC por dominio**, en emplazamientos distintos,
  **cifrados**, **inmutables/offline** (frente a ransomware, que hoy busca el backup primero) y
  dentro de la **vida útil de los objetos borrados** (*tombstone lifetime*) — un backup más antiguo
  **no es restaurable**, y ese es el error que se descubre en el peor momento.
- **La Papelera de AD activada** (recuperación de objetos borrados sin restaurar) es un control
  distinto y complementario: cubre el borrado accidental, no el compromiso.
- **Ensayo obligatorio**: recuperación de bosque probada en el **entorno de recuperación aislado
  (IRE)** que especifica `bcdr-standards` §3.6 —no es un "laboratorio": un laboratorio protege al
  mundo de lo que corre dentro, un IRE protege a lo que corre dentro del mundo, y en particular
  del dominio comprometido—, al menos
  anualmente y tras cambios estructurales, con **tiempo medido** y runbook actualizado con lo
  aprendido. El proceso completo se cuenta en días, no en horas: si tu RTO dice otra cosa, el RTO es
  ficción. El marco de continuidad y los RTO/RPO organizativos son de `bcdr-standards`; **este
  procedimiento es de aquí**.
- **Si el compromiso es de dominio, la decisión no es "limpiar o recuperar"**: la guía Five Eyes es
  explícita en que la persistencia en AD resiste la remediación habitual y puede durar meses o años.
  Se planifica **recuperación desde estado bueno conocido**, y la decisión se toma con el proceso de
  `incident-response-forensics-standards` e `incident-management-standards`, no en caliente.

## 4. Gates de calidad

1. **Higiene medida con puntuación y tendencia.** PingCastle y Purple Knight ejecutados al menos
   trimestralmente, con la **serie histórica** publicada y objetivo de mejora. Un score puntual sin
   tendencia no dice nada; una tendencia plana es un hallazgo de gestión.
2. **Grafo de rutas de ataque con métrica de reducción.** Ejecución recurrente de BloodHound CE, con
   número de caminos a Tier 0 y **evidencia de aristas cortadas** entre ejecuciones. Cada camino
   nuevo tiene dueño y fecha.
3. **Recuperación de bosque ensayada** en el IRE (`bcdr-standards` §3.6), con **tiempo real medido**, runbook
   actualizado, contraseña de DSRM verificada y comprobación de que el backup está dentro del
   *tombstone lifetime*. Sin ensayo, se declara explícitamente que **no existe capacidad de
   recuperación**, y eso sube al registro de riesgos.
4. **Baselines aplicadas y verificadas.** No basta con enlazar la GPO: se comprueba el estado
   efectivo en el host (`gpresult`, herramienta de cumplimiento, escaneo) y se reporta la desviación.
   Baseline vigente del SCT para la versión del SO, con excepciones documentadas, con dueño y con
   caducidad.
5. **Gate de tiering**: ninguna cuenta de Tier 0 inicia sesión fuera de su plano, verificado por
   consulta a los logs, no por política escrita. Una sola ocurrencia es incidente y obliga a rotar
   esa credencial.
6. **Inventario privilegiado reconciliado**: miembros de grupos privilegiados, permisos equivalentes
   a DA (DCSync, WriteDACL, delegación), cuentas de servicio con SPN, delegaciones, confianzas y
   plantillas de certificado peligrosas — comparados con lo aprobado. Cualquier diferencia es
   hallazgo.
7. **Cobertura de NTLM medida**: auditoría activa y **número de autenticaciones NTLM hacia DC
   descendiendo**, con fecha objetivo de bloqueo anterior al cambio de default de octubre de 2026
   (§3.6).
8. **Inventario de EOL sin excepciones silenciosas**: ningún SO fuera de soporte en el dominio; los
   que queden, con ESU contratada, aislamiento y fecha de retirada (seguimiento en
   `vulnerability-management-standards`).

## 5. Seguridad: dónde se pierde de verdad un dominio

- **Los tres patrones que causan la mayoría de los compromisos** no son exóticos: (1) credencial
  privilegiada usada en un equipo de usuario; (2) cuenta de servicio con SPN y contraseña débil
  reutilizada con privilegio excesivo; (3) permiso delegado olvidado que da control sobre un objeto
  de nivel superior. Ninguno se arregla comprando producto.
- **AD es el objetivo número uno de un ataque a empresa**, por diseño acumulado: defaults
  permisivos, relaciones complejas, protocolos legacy vivos y poca herramienta nativa para
  diagnosticar su seguridad. Asume que el atacante enumerará el directorio con **credenciales de
  usuario normales** — casi todo es legible por cualquier miembro del dominio.
- **Higiene > producto**: un directorio con Tier 0 vacío, sin delegación no restringida, con gMSA y
  con las plantillas de certificado saneadas resiste más que uno lleno de agentes y con Domain
  Admins de uso diario.
- **La estación del administrador es el eslabón real.** Sin PAW, todo lo demás es papel.
- **El híbrido fusiona planos si no lo impides**: el servidor de sincronización, sus cuentas y los
  roles cloud privilegiados son Tier 0. Separación estricta de identidades on-prem y cloud
  privilegiadas.
- **Asume compromiso al diseñar la detección**: los eventos de §3.7 existen para descubrir a alguien
  que **ya está dentro**. Si el SIEM no los ingiere y nadie los mira, el directorio está
  indefenso aunque el score sea alto.
- **Prioridad de parcheo**: los DC primero, siempre. Un DC sin parchear es todo el dominio sin
  parchear. (Precedente reciente en el ecosistema de gestión: **CVE-2025-59287**, RCE crítica en
  **WSUS**, oct-2025 — un servidor de parcheo comprometido distribuye código a toda la flota; trátalo
  como Tier 0 o migra fuera de él.)

## 6. Operabilidad

- **Monitorización del directorio como servicio**: salud de replicación (`repadmin /replsummary`,
  `dcdiag`), retraso entre sitios, disponibilidad de FSMO, espacio y estado de `ntds.dit`, tiempo
  (la deriva de reloj rompe Kerberos y es una causa de incidente clásica), y latencia de
  autenticación por sitio. Alertas sobre síntomas, no sobre cada evento.
- **Jerarquía de tiempo correcta**: el PDC emulator del dominio raíz como fuente, sincronizado con
  origen externo confiable; el resto por jerarquía de dominio. En DC virtualizados, **desactivar la
  sincronización de tiempo del hipervisor** o se pelea con el dominio.
- **Virtualización de DC**: soporte de `VM-GenerationID` para evitar reversiones peligrosas de USN,
  **nunca restaurar un DC desde snapshot** como método de recuperación, y el hipervisor tratado como
  Tier 0 (incluido su almacenamiento y su consola).
- **Capacidad y colocación**: al menos **dos DC por dominio**, distribuidos, con al menos uno
  físicamente controlado; sitio con DC local donde la latencia lo justifique.
- **Runbooks probados**: incautación de FSMO, limpieza de metadatos, rotación de `krbtgt`,
  recuperación de objeto borrado, promoción y despromoción de DC, y respuesta a "un DC no replica
  desde hace N días" (el silencio de replicación es a la vez avería y posible indicador).
- **Gestión de cambios en el directorio**: cambios de esquema, de nivel funcional, de confianzas y de
  GPO de Tier 0 son irreversibles o casi. Ventana, aprobación, backup previo verificado y plan de
  reversión — el cambio de esquema **no se deshace**.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Higiene medida (PingCastle/Purple Knight/BloodHound): **trimestral**, con tendencia.
- Revisión de privilegio, delegaciones, confianzas, cuentas de servicio y plantillas de certificado:
  **trimestral** para lo privilegiado, semestral el resto.
- Ensayo de recuperación de bosque: **anual** como mínimo y tras cambios estructurales.
- Rotación programada de `krbtgt` (doble, con verificación de replicación entre pasos).
- Baseline del SCT: revisar con cada revisión publicada (cadencia acelerada desde v2506) y con cada
  versión nueva del SO.
- Plan de retirada de EOL con fecha: **Server 2016 → 12-ene-2027** es un hito de calendario, no una
  intención.
- Actualización de PingCastle antes del fin de soporte de la versión en uso (caduca y deja de
  ejecutarse).
- Migración fuera de WSUS planificada con fecha, aunque no haya EOL anunciado.

**PROHIBIDO**
- ❌ **Delegación Kerberos no restringida** (*unconstrained*), en cualquier servidor y por cualquier
  motivo.
- ❌ **Cuentas de servicio con contraseña estática y SPN**: se migran a gMSA. Si no pueden, excepción
  firmada con contraseña larga, rotación real y privilegio mínimo.
- ❌ **Cuentas de administración de dominio usadas a diario**, o iniciando sesión en estaciones de
  trabajo, servidores de aplicación o cualquier sistema fuera de Tier 0.
- ❌ `Domain Admins`/`Enterprise Admins`/`Schema Admins` con miembros permanentes en operación normal.
- ❌ **NTLMv1 y LM** habilitados; SMBv1 instalado; firma SMB opcional; LDAP sin firma ni *channel
  binding*; *simple bind* en claro.
- ❌ **Controladores de dominio con roles adicionales** (IIS, SQL, ficheros, aplicaciones, hipervisor,
  backup) o **navegando a Internet**.
- ❌ **Servidores fuera de soporte en el dominio** sin ESU, aislamiento y fecha de retirada.
- ❌ Plantillas de certificado que permitan al solicitante fijar el sujeto con EKU de autenticación y
  enrolamiento amplio; permisos de escritura sobre plantillas para grupos no privilegiados; CA con
  la configuración que ignora la plantilla al fijar el sujeto alternativo.
- ❌ **dMSA en un bosque con DC de Server 2025 sin la mitigación de BadSuccessor aplicada** (§3.4).
- ❌ **LAPS legacy** en despliegues nuevos; contraseñas de administrador local compartidas o iguales
  entre equipos.
- ❌ Contraseñas en scripts, en SYSVOL, en preferencias de GPO, en tareas programadas o en la
  descripción de objetos de AD.
- ❌ **CredSSP** en remoting; administración de DC desde una estación de uso general.
- ❌ Rotar `krbtgt` **dos veces seguidas sin esperar** replicación y vida máxima de ticket (provoca
  caída de autenticación), o **no rotarla** tras sospecha de compromiso.
- ❌ Desactivar la rotación de contraseñas de cuentas de máquina; restaurar un DC desde snapshot del
  hipervisor.
- ❌ Backup del directorio sin cifrar, sin copia inmutable/offline, o **más antiguo que el
  *tombstone lifetime***.
- ❌ Declarar "tenemos backup de AD" **sin ensayo de recuperación de bosque documentado**.
- ❌ Confianzas bidireccionales con filtrado de SID desactivado, o confianzas sin dueño ni revisión.
- ❌ Ejecutar herramientas de recolección (SharpHound) sin control del destino del volcado.
- ❌ Fijar fechas de EOL, estados de retirada de NTLM, versiones o nombres de feature **de memoria**,
  sin la verificación de §8.

### Checklist de revisión rápida (evaluación de un dominio existente)

- [ ] Tier 0 identificado **completo** (incluye hipervisor, backup, PKI, sincronización a Entra) y aislado.
- [ ] Grupos privilegiados vacíos en operación; elevación con ticket, ventana y alerta; PAW en uso real.
- [ ] Delegaciones, ACL equivalentes a DA y confianzas inventariadas y reconciliadas.
- [ ] Cuentas de servicio en gMSA; ninguna cuenta de usuario con SPN y contraseña estática.
- [ ] Sin delegación no restringida; RBCD/restringida inventariada; Protected Users en privilegiados.
- [ ] Plantillas de AD CS auditadas (flags, EKU, permisos, propietario); CA tratada como Tier 0.
- [ ] Auditoría NTLM activa con tendencia a la baja; NTLMv1/LM bloqueados; firma SMB y LDAP obligatorias.
- [ ] Windows LAPS desplegado, incluido el password de DSRM en los DC.
- [ ] Baseline del SCT aplicada **y verificada** en DC y servidores; Server Core donde sea posible.
- [ ] Script block logging, línea de comandos en creación de procesos y reenvío de logs de DC al SIEM.
- [ ] PingCastle/Purple Knight/BloodHound con serie histórica y caminos a Tier 0 en descenso.
- [ ] Backup de estado del sistema de ≥2 DC, cifrado, inmutable, dentro del *tombstone lifetime*.
- [ ] **Recuperación de bosque ensayada** con tiempo medido y runbook fuera del dominio.
- [ ] Sin SO fuera de soporte; plan con fecha para Server 2016 (12-ene-2027).

## 8. Verificación web obligatoria

Antes de fijar cualquier fecha, versión, estado de retirada o nombre de feature, **búscalo — no lo
recuerdes**. Este dominio es donde más se equivoca la memoria:

1. **Ciclo de vida de Windows Server** (verificado ago-2026: **2025** GA 1-nov-2024, estándar hasta
   13-nov-2029, extendido hasta 14-nov-2034; **2022** fin de soporte estándar 13-oct-2026; **2019**
   extendido hasta 9-ene-2029; **2016** EOL **12-ene-2027**; **23H2** ya EOL desde 24-oct-2025).
   Confírmalo en el ciclo de vida oficial de Microsoft antes de planificar migraciones.
2. **Retirada de NTLM — el dato más citado de memoria y peor recordado.** Verificado ago-2026:
   NTLM **deprecado** en jul-2024 (no eliminado); **NTLMv1 eliminado** en Windows 11 24H2 y Windows
   Server 2025; clave `BlockNTLMv1SSO` en auditoría desde sep-2025 (evento 4024) y **cambio de
   default a *enforce* previsto para octubre de 2026**; **IAKerb** y **Local KDC** anunciados para la
   segunda mitad de 2026. **Huecos declarados**: no se verificó si el cambio de default de octubre de
   2026 se ha adelantado, retrasado o ya aplicado, ni el **estado real de disponibilidad de IAKerb y
   Local KDC** a esta fecha. Léelo en el artículo de soporte de Microsoft para tu build.
3. **dMSA y BadSuccessor** (verificado ago-2026: técnica de Akamai, abuso de la funcionalidad de
   migración, funciona en configuración por defecto, 91 % de entornos analizados expuestos).
   **Hueco declarado**: **no se pudo confirmar si Microsoft ha publicado ya un parche o cambio de
   comportamiento** — las fuentes consultadas indican que en su momento no existía y que la respuesta
   era de configuración y detección. **Verifícalo antes de introducir un DC de Server 2025**; es el
   punto de este documento con mayor probabilidad de haber cambiado.
4. **Windows LAPS frente al legacy** (verificado ago-2026: legacy **deprecado**, MSI bloqueado en
   Windows 11 23H2+, sin cambios de código, soportado solo hasta el EOL del SO donde ya estaba;
   Windows LAPS disponible desde Server 2019 y clientes soportados, con cifrado en AD, historial,
   respaldo a Entra ID y gestión del password de DSRM). **Hueco declarado**: no se verificó si
   Microsoft ha anunciado desde entonces una fecha de retirada concreta del legacy.
5. **WSUS** (verificado ago-2026: **deprecado el 20-sep-2024**, sin funcionalidad nueva, **sin fecha
   de EOL anunciada**, todavía incluido en Server 2025 y soportando el SUP de ConfigMgr; reemplazo
   recomendado partido entre **Intune/Windows Autopatch** para clientes y **Azure Update Manager**
   —con Arc— para servidores; la parada de sincronización de drivers prevista para abr-2025 fue
   pospuesta). **Hueco declarado**: el estado actual de esa sincronización de drivers no se confirmó.
6. **Mapeo fuerte de certificados (KB5014754)** (verificado ago-2026: **aplicación completa desde
   feb-2025** y **eliminación del modo compatibilidad en sep-2025**; exige todos los DC en Server
   2019+). No se encontró ningún hito posterior en 2026; confírmalo si dependes de tarjetas
   inteligentes, 802.1X o SCEP de terceros.
7. **Enterprise Access Model y modelo de niveles** (verificado ago-2026: el tier model está
   **reclasificado como guía legacy pero vigente**, documentado como componente del EAM, con
   repositorio y guía de despliegue publicados por Microsoft). Comprueba el nombre y la URL vigentes
   de la guía antes de citarla en un entregable: Microsoft ha renombrado y reorganizado este material
   varias veces.
8. **Herramientas de higiene**: **PingCastle** (verificado ago-2026: adquirido por **Netwrix**,
   edición Open Source **NPOSL-3.0**, uso interno permitido, auditar a terceros requiere licencia
   comercial, **caducidad por versión** — la 3.3.0.0 dejó de ejecutarse el 31-ene-2026) y
   **Purple Knight** (verificado: Semperis, **Community 5.0**, gratuita, 210+ indicadores, soporte
   GCC High desde 21-abr-2026). **Huecos declarados**: **la versión vigente de PingCastle en ago-2026
   y su próxima fecha de caducidad no se verificaron**.
9. **BloodHound** (verificado ago-2026: **Community Edition** libre bajo **Apache-2.0**, mantenida
   por SpecterOps; **Enterprise** cubre AD, Entra, AWS y Okta; oferta **Scentry** para programas de
   gestión de rutas de ataque; releases recientes incluyen la corrección de **CVE-2026-16221**).
   **Hueco declarado**: **no se verificó el número de versión actual de CE**; consúltalo en su página
   de releases. Aviso útil de la propia SpecterOps (abr-2026): buena parte del material formativo y
   de la documentación de terceros está desactualizado respecto a la plataforma actual.
10. **Microsoft Security Compliance Toolkit y baselines** (verificado ago-2026: **sigue siendo la vía
    soportada**, SCM retirado; baseline de Windows Server 2025 **v2602 de feb-2026**, con cadencia de
    revisión acelerada desde v2506; en Intune las baselines se consumen directamente sin importar,
    derivadas de la baseline de cliente). **Hueco declarado**: no se verificó si hay una revisión
    posterior a v2602 publicada entre feb-2026 y ago-2026.
11. **PowerShell** (verificado ago-2026: **7.6 LTS** desde 18-mar-2026 sobre .NET 10, soportada hasta
    14-nov-2028; **7.4 LTS y 7.5 terminan el 10-nov-2026** con .NET 8; **5.1 sin EOL propio**, sigue
    el ciclo del SO). Verifica la versión de mantenimiento vigente antes de fijarla en un despliegue.
12. **Guía Five Eyes "Detecting and Mitigating Active Directory Compromises"** (verificado ago-2026:
    publicada el **26-sep-2024**, liderada por ASD/ACSC con CISA, NSA, CCCS, NCSC-NZ y NCSC-UK, 17
    técnicas). **Hueco declarado**: **no se localizó ninguna revisión posterior**; comprueba si ha
    salido una actualización antes de usarla como referencia normativa.
13. **CVE del ecosistema de gestión y del directorio**: precedente verificado **CVE-2025-59287**
    (RCE crítica en WSUS, oct-2025). Antes de dar por segura una plataforma, revisa los boletines de
    Microsoft y el catálogo KEV de CISA para AD DS, AD CS, AD FS, WSUS y el agente de gestión que
    uses.
14. **Estado de los benchmarks aplicables** si hay requisito formal (CIS de la versión exacta de
    Windows Server, DISA STIG, CCN-STIC/ENS). **Hueco declarado**: **no se verificaron las versiones
    vigentes de CIS ni de STIG para Windows Server 2025** en ago-2026. Recuerda que el CIS va por
    versión de producto: nunca cites "el CIS de Windows Server" en genérico.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
