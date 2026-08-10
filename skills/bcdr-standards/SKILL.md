---
name: bcdr-standards
description: Business continuity and disaster recovery as a program. Use for a business impact analysis (BIA), deriving RTO/RPO/MTPD from business impact rather than from what infrastructure can do today, mapping the dependency graph and the recovery sequence, choosing between backup-restore, pilot light, warm standby and active-active, multi-region or multi-cloud DR posture, who declares a disaster and under which activation criteria, crisis communication and alternate site, DR drills from walkthrough to live failover and failback, ransomware recovery with immutable or offline copies and backup infrastructure isolated from the production domain, building an isolated recovery environment (IRE) or clean room where restored systems are rebuilt and declared trustworthy before reconnection, identity-first recovery sequencing, SaaS and vendor dependency with exit and data-protection responsibility, encryption key escrow held outside the backed-up system, measured versus committed recovery objectives, ISO 22301 and ISO/TS 22317, and the continuity, backup and resilience-testing duties of DORA Articles 11-12 and NIS2 Article 21(2)(c).
---

# Estándares de continuidad de negocio y recuperación ante desastres (BC/DR)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **programa de continuidad y recuperación**: análisis de impacto en el negocio (BIA),
derivación de objetivos de recuperación, estrategias de recuperación y su coste, la cadena de
dependencias y el **orden de recuperación**, el plan como artefacto vivo y sus criterios de
activación, sitio alterno y personas, ejercicios y su cadencia, escenarios de diseño dominantes
(ransomware, pérdida de sitio, caída de un tercero crítico), y la medición honesta de si el plan
funciona.

Triggers: "BIA", "análisis de impacto", "RTO", "RPO", "MTPD", "MTO", "plan de continuidad", "BCP",
"plan de recuperación ante desastres", "DRP", "declarar el desastre", "activar el plan", "sitio
alterno", "DR site", "pilot light", "warm standby", "activo-activo", "multi-región", "multi-nube",
"orden de recuperación", "cadena de dependencias", "failover", "conmutación por error",
"tabletop de DR", "simulacro de recuperación", "recuperación de ransomware", "copia inmutable",
"aislamiento del backup", "recuperación del directorio", "recuperación del bosque", "entorno de
recuperación aislado", "IRE", "clean room", "sala limpia", "entorno limpio de recuperación",
"reconstruir en aislado", "salida de proveedor", "ISO 22301", "DORA art. 11-12",
"NIS2 art. 21(2)(c)".

**Principio rector**: **el RTO y el RPO no los elige quien restaura, los deriva el impacto en el
negocio** — y si no están derivados de un BIA, son deseos con formato de número. Corolario doble y
no negociable: **un plan no ensayado no existe** y **un backup sin restore probado no existe**
(invariante compartido con `onprem-standards` §1.3).

**No aplica**:
- `backup-recovery-standards` — **la colisión más probable de todo el
  catálogo; frontera quirúrgica**: allí vive la **mecánica** del respaldo (elección de herramienta,
  repositorio, topología 3-2-1, cadencia de trabajos, deduplicación, cifrado del repositorio,
  esquemas de retención GFS, verificación de integridad, catálogo, y el procedimiento concreto de
  restauración). Aquí vive el **plan y el porqué**: qué se protege y con qué objetivo derivado del
  negocio (RTO/RPO), en qué **orden** se recupera, quién declara el desastre, con qué ejercicio se
  demuestra y qué se comunica. Regla de arbitraje en una línea: **"¿cómo se hace la copia?" es de
  `backup-recovery`; "¿cuánto podemos perder, en qué orden lo levantamos y quién lo decide?" es de
  esta skill.** Aquí solo el principio (3-2-1, inmutabilidad, restore probado); **la mecánica no
  se desarrolla aquí**, se delega en ella.
- `incident-management-standards`: el proceso de gestión del incidente — declaración, severidad,
  Incident Commander, comunicación, postmortem. **La frontera es de escala y está declarada en ambos
  lados**: mientras el impacto es recuperable dentro del servicio, es un incidente y manda aquella
  skill. Cuando se cruza el umbral de activación del plan de continuidad (§3.4), **el régimen
  cambia**: el IC entrega el mando al director de crisis, el cambio se declara explícitamente y con
  marca temporal en el canal, y a partir de ahí manda este documento. El proceso de incidente no
  desaparece —sigue gobernando comunicación y registro— pero deja de ser el que decide.
- `incident-response-forensics-standards`: la respuesta técnica al compromiso. Frontera crítica en
  ransomware: **la recuperación no empieza hasta que la erradicación está verificada**; restaurar
  desde un punto posterior al compromiso inicial restaura también al atacante. El punto de
  restauración limpio lo determina la investigación, no la prisa por volver. **El forense se hace en
  su entorno de análisis, no en el de recuperación** (§3.6).
- `ctf-lab-standards`: laboratorio de entrenamiento y de detonación de muestras. **El entorno de
  recuperación aislado (§3.6) no es eso**: allí lo malicioso se ejecuta a propósito; aquí la premisa
  de trabajo es que **no hay nada malicioso ejecutándose**.
- `sre-practice-standards`: la fiabilidad **cotidiana** — SLI/SLO, error budget y su política, burn
  rate, guardia, capacidad. **Frontera de régimen**: el error budget gobierna lo cotidiano y admite
  degradación parcial; el **RTO/RPO gobierna el desastre**, donde el servicio no está degradado sino
  ausente. Un servicio puede cumplir su SLO todo el año y no sobrevivir a la pérdida de su sitio:
  son dos preguntas distintas y **dos números distintos**.
- `grc-compliance-standards`: **ISO 22301 como sistema de gestión certificable**, SoA, registro de
  riesgos, evidencia de auditoría, cláusulas contractuales y registro de terceros. Aquí, la
  **ingeniería de la continuidad**: el número, la cadena, el ejercicio y su medición.
- `privacy-engineering-standards`: frontera declarada en ambos lados en el **borrado**.
  La obligación de suprimir y su implementación técnica (incluida la reaplicación de supresiones
  tras un restore) son de aquella skill; **la ventana de retención concreta y la inmutabilidad del
  repositorio son de `backup-recovery-standards`** —esta skill solo fija el RPO del que se
  deriva—. Diseño que resuelve el conflicto: cifrado por sujeto desde el día 1.
- `onprem-standards`: paraguas de plataforma — hierro, hipervisor, redundancia física, topología de
  cluster. Sus invariantes (§1.3) mandan y este documento no los contradice; su §6 marcaba como
  provisional exactamente lo que aquí se desarrolla.
- `ha-clustering-standards`: Pacemaker/Corosync, quórum, fencing, recursos.
  **HA no es DR** (§3.1): la HA absorbe el fallo de un componente dentro del mismo dominio de fallo;
  el DR asume que el dominio entero desaparece.
- `chaos-engineering-standards`: **el experimento de resiliencia continuo y acotado es suyo**
  —hipótesis de estado estable, inyección de fallo, *blast radius*, condiciones de aborto—;
  **el drill de DR completo —failover de sitio, RTO/RPO, declaración— es de aquí**. La línea:
  si se ensaya el plan de continuidad, es de aquí; si se inyecta un fallo para refutar una
  hipótesis en operación normal, es suyo.
- `windows-server-ad-standards`: el procedimiento concreto de recuperación
  del bosque de Active Directory desde copia de estado del sistema, Tier 0, `ntdsutil` y la higiene
  del directorio. Aquí, **su posición en el orden de recuperación** (§3.3), el criterio de que sin
  identidad no se recupera nada y la exigencia de ensayarlo.
- `data-platform-standards`: PITR, replicación y failover del motor de datos.
  `cryptography-pki-standards`: gestión y custodia de las claves. `networking-standards`: DNS,
  rutas, direccionamiento del sitio alterno. `aws-standards`/`azure-standards`/`gcp-standards`:
  primitivas de región, zona y replicación de cada proveedor. `kubernetes-standards`: recuperación
  del estado del clúster. `homelab-standards`: laboratorio personal, donde el criterio es coste y no
  compromiso de RTO.

**Esto no es asesoramiento jurídico**: el encuadre normativo (§5) es criterio de ingeniería para
diseñar sistemas que cumplen; la interpretación de la obligación la fija legal/cumplimiento.

## 2. Decisiones por defecto

> Verificar por web edición de norma, obligación regulatoria y estado de herramientas antes de
> fijarlas en un proyecto real (§8). Datos de agosto de 2026.

| Decisión | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| Punto de partida | **BIA antes que tecnología.** Sin BIA no hay RTO/RPO, hay opiniones | Referencia: **ISO/TS 22301:2019 + Amd 1:2024** (sistema de gestión) e **ISO/TS 22317:2021** (guía de BIA, es *Technical Specification*: no certificable) |
| Quién fija RTO/RPO | **El dueño de negocio del proceso**, con datos de impacto (pérdida por hora, contractual, regulatorio, reputacional, seguridad de personas) | **PROHIBIDO** que los fije el equipo técnico "según lo que podemos hacer": eso es una capacidad, no un objetivo |
| Granularidad | Por **proceso de negocio**, propagado a los servicios que lo soportan. Un servicio hereda el RTO más estricto de los procesos que sirve | RTO por servidor: no significa nada para nadie |
| Niveles | **3-4 tiers** con RTO/RPO por tier y estrategia asociada, no un número por sistema | Cada sistema con su número: ingobernable e imposible de ensayar |
| Estrategia por defecto | **La más simple que cumpla el RTO derivado**, y no más | Activo-activo "porque somos serios": multiplica coste y complejidad y añade modos de fallo nuevos (partición, conflictos de datos) |
| Artefacto crítico | **Orden de recuperación** con la cadena de dependencias completa (§3.3) | Es el artefacto que casi nadie tiene y el que decide si el ejercicio sale o no |
| Declaración del desastre | **Persona nominal con suplente**, criterios escritos, autoridad delegada por dirección | **PROHIBIDO** que la decisión requiera reunión, comité o localizar a quien está de vacaciones |
| Cadencia mínima de ejercicios | **Tabletop semestral** + **simulación parcial anual** + **failover real anual** de los servicios de tier 1 | Anual completo si el tier lo justifica; **nunca** menos de un ejercicio real al año — es lo que DORA exige explícitamente al sector financiero (§5) |
| Escenario de diseño dominante | **Ransomware** (incluye compromiso de la identidad y del propio sistema de respaldo), por encima de la pérdida de CPD | El escenario "se quema el CPD" es más fácil que el real: no lo uses como único ejercicio |
| Copias de respaldo | **Al menos una inmutable u offline**, con la infraestructura de respaldo **aislada del dominio de identidad de producción** | Backup accesible con credenciales de administrador de dominio = backup que el atacante borra primero |
| Dónde se restaura tras un compromiso | **Entorno de recuperación aislado (IRE)** con los tres aislamientos —red, **identidad** y plano de gestión— (§3.6), preaprovisionado en frío y con **tiempo de construcción medido** dentro del RTO | Bajo demanda desde IaC en cuenta separada por defecto; permanente y dedicado solo si el RTO o la norma lo exigen. **PROHIBIDO** reconstruir sobre el dominio comprometido o administrar el IRE con credenciales de producción |
| Custodia de claves | **Fuera del sistema respaldado**, con procedimiento de recuperación probado y separación de funciones | Backup cifrado cuya clave solo vive dentro del sistema perdido = pérdida total con pasos extra |
| Terceros y SaaS | **Tu proveedor caído es tu desastre.** Cada SaaS crítico entra en el BIA con su propio RTO/RPO, su plan de salida y **backup propio de tus datos** | Asumir que el SaaS respalda tus datos por ti: no lo hace (§5) |
| Verificación | **RTO/RPO medidos en ejercicio, con volúmenes reales**, publicados junto a los comprometidos | Números "estimados" en una diapositiva: se descubren falsos el día que importan |

## 3. El programa

### 3.1 Las tres cosas que se confunden constantemente

| | Qué absorbe | Qué **no** absorbe | Métrica |
|---|---|---|---|
| **Alta disponibilidad** | Fallo de un componente dentro del mismo dominio de fallo (nodo, disco, AZ) | Corrupción lógica, borrado, ransomware, pérdida del dominio entero — **la HA replica el error a la velocidad de la red** | Disponibilidad, SLO |
| **Backup** | Corrupción, borrado, cifrado malicioso, error humano | La caída en sí: tener la copia no es tener el servicio | RPO, tiempo de restauración |
| **DR** | Pérdida del dominio de fallo completo (sitio, región, proveedor, identidad) | Nada, si el orden de recuperación no existe o no se ha ensayado | RTO extremo a extremo |

Los tres son necesarios y **ninguno sustituye a otro**. La confusión más cara del dominio es
"tenemos cluster, ya estamos cubiertos": un `DELETE` mal filtrado, un cifrado por ransomware o un
cambio de esquema roto se replican a los tres nodos en milisegundos.

### 3.2 BIA: el número sale del negocio

Para cada proceso, con el dueño de negocio y por escrito:

- **Impacto por unidad de tiempo** (1 h, 4 h, 1 día, 1 semana): económico, contractual (penalizaciones,
  SLA con clientes), regulatorio, reputacional y de **seguridad de las personas**. La curva no es
  lineal: casi siempre hay un codo, y el codo es lo que define el objetivo.
- **MTPD/MTO** (periodo máximo tolerable de interrupción): el punto a partir del cual el daño es
  irreversible. **El RTO se fija por debajo del MTPD, con margen**, nunca igual.
- **RPO**: cuánto trabajo se puede rehacer o perder. Ojo al coste oculto: un RPO de 24 h no es "un
  día de datos", es **un día de reintroducción manual** con su propia tasa de error, y ese trabajo
  también consume el RTO.
- **Estacionalidad y ventanas críticas**: cierre contable, campaña, nómina, periodo de matrícula. El
  mismo proceso puede tener MTPD de una semana en agosto y de dos horas el día 30.
- **Recursos mínimos para operar en modo degradado**: personas, sistemas, datos, proveedores,
  instalaciones. Incluye el **procedimiento manual alternativo** cuando exista: para muchos procesos
  es más rápido operar en papel doce horas que restaurar, y nadie lo tiene escrito.
- **Interdependencias**: qué procesos dependen de este y de cuáles depende. Aquí nace §3.3.

Salida del BIA: **tiers**, RTO/RPO por tier, y la lista de servicios de tier 1 — que es corta si el
ejercicio se ha hecho con honestidad. Si todo es tier 1, no hay BIA: hay una lista de deseos.

### 3.3 La cadena de recuperación: el artefacto que casi nadie tiene

Ninguna aplicación arranca sola. El orden real, casi siempre ignorado hasta el primer ejercicio:

```
0. Personas y comunicación fuera de banda   (si no puedes convocar, nada de lo demás ocurre)
1. Energía, red física, conectividad WAN     (sitio alterno alcanzable)
2. Direccionamiento, DNS y resolución        (todo lo demás depende de resolver nombres)
3. Identidad y directorio                    (sin autenticación no se administra nada)
4. Gestión de secretos y PKI/certificados    (sin secretos ni certificados no arranca el servicio)
5. Time (NTP)                                (relojes: Kerberos, TLS y logs dependen de ello)
6. Almacenamiento y bases de datos           (restauración y validación de integridad)
7. Plataforma de cómputo (hipervisor/clúster/orquestador)
8. Servicios de aplicación por tier, en orden de dependencia
9. Integraciones con terceros y reactivación de flujos entrantes
10. Verificación funcional con negocio y comunicación de restablecimiento
```

Reglas:
- **La cadena se documenta como grafo de dependencias, no como lista de deseos**, y se **valida en
  el ejercicio**: el ejercicio existe precisamente para descubrir que el paso 8 necesitaba algo del
  paso 3 que nadie había anotado.
- **Dependencias circulares**: el caso clásico es el gestor de secretos que se autentica contra el
  IdP que necesita un secreto del gestor. Se detectan dibujando el grafo y se rompen con un camino
  de arranque en frío documentado (credencial break-glass en custodia física o sellada, fuera de
  ambos sistemas).
- **Autorreferencia del propio plan**: el runbook, el inventario, la documentación de red y la lista
  de contactos **no pueden vivir solo en el sistema que se cae**. Copia fuera de banda, accesible sin
  el SSO corporativo, y **probada** — una lista de teléfonos en el wiki caído no existe.
- **El sistema de respaldo también se recupera**: si el servidor de backup formaba parte del sitio
  perdido, restaurar el catálogo es el paso previo a todo lo demás. Ensáyalo.

### 3.4 El plan: activación, mando y personas

- **Criterios de activación escritos y observables**: pérdida de sitio o región; indisponibilidad de
  un servicio de tier 1 con estimación de recuperación **por encima de su MTPD**; compromiso
  confirmado que exige reconstrucción; pérdida del proveedor crítico sin fecha de restablecimiento;
  indisponibilidad del personal clave. Cuando se cumple un criterio, **se activa**: la duda se
  resuelve activando, porque desactivar cuesta una notificación y no activar cuesta el negocio.
- **Quién declara**: rol nominal (típicamente dirección o el responsable de continuidad) **con dos
  suplentes y orden de sucesión escrito**, con autoridad delegada previamente por dirección — la
  delegación se firma en frío, no se improvisa a las 03:00. La declaración es un acto explícito, con
  marca temporal, registrado, y **marca el cambio de régimen** desde el proceso de incidente
  (`incident-management-standards`) a este.
- **Estructura de crisis**: director de crisis (decide y prioriza, no ejecuta), responsables de
  recuperación técnica por capa, responsable de comunicación (interna, clientes, reguladores,
  prensa: **portavoz único**), enlace con negocio (valida que lo recuperado sirve) y registro de
  decisiones. Turnos desde el minuto uno: **un desastre dura días, no horas**, y el agotamiento es
  el que produce las decisiones caras.
- **Comunicación de crisis preparada en frío**: plantillas por audiencia, canal alternativo probado,
  y la matriz de obligaciones de notificación **ya escrita** (coordinada con las skills de
  incidente). Improvisar la comunicación durante la crisis es cómo un incidente técnico se convierte
  en una crisis reputacional.
- **Personas — el supuesto que rompe más planes**: la gente puede estar de baja, de vacaciones, sin
  cobertura, en el sitio afectado o sin querer atender el teléfono a las 4:00 de un domingo. El plan
  exige: **dos personas capaces por tarea crítica** (sin héroe único), datos de contacto fuera del
  sistema corporativo, procedimientos escritos para que ejecute alguien que no es el autor, y
  transporte/alojamiento previstos si el sitio alterno es físico. **La prueba de fuego del runbook:
  ¿lo puede ejecutar quien no lo escribió, a las 03:00, sin llamar a nadie?** Si no, no es un
  runbook.
- **El plan es código, no un PDF**: versionado, con dueño, con fecha de última prueba visible y con
  revisión obligatoria tras cualquier cambio arquitectónico relevante. Un plan que cita servidores
  que ya no existen es peor que no tener plan, porque genera confianza falsa.

### 3.5 Estrategias y su coste real

| Estrategia | RTO típico | RPO típico | Coste | Cuándo |
|---|---|---|---|---|
| **Backup–restore** | Horas a días | Horas | Bajo | Tier 3-4. El RTO real lo domina **restaurar y validar el volumen**, no lanzar el job |
| **Pilot light** | Horas | Minutos | Medio-bajo | Núcleo mínimo (datos replicados, red y plantillas listas) encendido; el resto se levanta al activar |
| **Warm standby** | Decenas de minutos | Segundos a minutos | Medio-alto | Entorno reducido pero **funcionando y ejercitado**; escala al activar |
| **Activo-activo** | Cercano a cero | Cercano a cero | Muy alto | Solo si el MTPD lo exige. Paga: coherencia de datos, resolución de conflictos, latencia y una clase entera de fallos nueva |

- **Multi-región**: opción por defecto para el desastre regional; el coste que la gente olvida es la
  **transferencia de datos y la deriva de configuración entre regiones** — una región secundaria que
  no se despliega desde el mismo código diverge y falla el día que se usa.
- **Multi-proveedor**: se vende como resiliencia y casi siempre compra complejidad. Es defendible
  cuando el riesgo real es **el proveedor entero** (concentración, decisión regulatoria, salida
  contractual), y exige renunciar a servicios gestionados diferenciales o mantener dos
  implementaciones. **Decisión de puerta de un solo sentido: exige ADR con coste operativo y de
  personas cuantificado.** Alternativa más honesta y mucho más barata: **capacidad probada de salir**
  (datos exportables, IaC portable, ensayo de reconstrucción) en vez de correr en dos sitios a la vez.
- **Lo que casi nunca se replica y tumba el ejercicio**: DNS y su delegación, certificados y PKI,
  secretos, colas en vuelo, configuración de firewall y balanceadores, licencias atadas a hardware o
  a MAC, integraciones salientes con IP de origen en lista blanca del tercero, y **la propia
  infraestructura de respaldo y monitorización**.

### 3.6 El entorno de recuperación aislado (IRE / *clean room*)

Cuando el desastre es un **compromiso** y no un incendio, la producción deja de ser un sitio donde
restaurar: no se puede demostrar que esté limpia, y si el directorio está comprometido ni siquiera
hay una identidad con la que administrarla. El **entorno de recuperación aislado** es el lugar donde
se restaura, se limpia, se valida y se **declara apto** un servicio antes de devolverlo a producción.
Su producto no es un servidor encendido: es **confianza reconstruida y firmada**. Con el directorio
comprometido, **es el primer entregable físico del plan** — sin él no hay dónde restaurar nada.

**Qué no es** (o deja de serlo):
- **No es un laboratorio de entrenamiento ni de detonación de muestras** (`ctf-lab-standards`): allí
  la amenaza se ejecuta a propósito y el aislamiento protege al mundo del laboratorio; aquí la
  premisa es que **nada malicioso se está ejecutando** y el aislamiento protege al entorno del mundo.
- **No es el entorno forense** (`incident-response-forensics-standards`): adquisición, *timeline*,
  cadena de custodia y estación de análisis son suyos. El IRE **consume** el resultado de esa
  investigación —punto limpio, IOC, lista de persistencia— y **no lo produce**.
- **No es preproducción, ni entorno de pruebas, ni capacidad de picos.** Un IRE con un segundo uso
  tiene usuarios, credenciales, integraciones y rutas de producción: ya no es un IRE.
- **No es una copia**: es cómputo, red, almacenamiento y plano de gestión. El repositorio inmutable
  es el insumo; el IRE es la máquina que lo convierte en servicio.

**Los tres aislamientos que lo definen** — los tres, o no hay IRE:

1. **De red.** *Default-deny* real: sin ruta a producción ni a la red de gestión, y sin Internet
   salvo salidas **nominales, justificadas, temporales y registradas** (firmas y consola del EDR,
   activación de licencias, descarga verificada de un binario). **DNS y NTP propios dentro del IRE**:
   si resuelve nombres contra producción, no está aislado — y el reloj no es un detalle, porque
   Kerberos, TLS y la correlación de logs dependen de él (§3.3, paso 5). El aislamiento se
   **comprueba desde dentro** (intento explícito de alcanzar y de resolver producción, con resultado
   registrado), no se supone por el diagrama.
2. **De identidad — el que más veces se hace mal.** Directorio, credenciales y MFA **propios del
   IRE**, creados fuera del dominio comprometido, **sin confianzas ni federación** con él. El fallo
   clásico: se monta una red separada impecable y se administra con la cuenta de administrador de
   dominio de siempre — la que el atacante controla —, con lo que el aislamiento dura hasta el primer
   inicio de sesión. Corolario de **origen limpio**: se administra **desde un dispositivo construido
   desde cero de fuente confiable** (estación de administración nueva), no desde el portátil del
   administrador ni desde un salto de producción. Microsoft lo dice literalmente para el compromiso
   sistémico de identidad: *"ensure any actions taken are performed from a trusted device built from
   a clean source"* (verificado ago-2026, §8).
3. **De gestión.** Hipervisor, almacenamiento, consola de respaldo, herramienta de despliegue,
   monitorización y el propio acceso fuera de banda (IPMI/KVM) **fuera del dominio que se recupera**,
   con cuentas locales propias y MFA independiente. **Si el plano de gestión es el mismo, no hay
   aislamiento**, por muchas VLAN que se dibujen: quien controla el hipervisor controla todas las
   máquinas restauradas dentro de él. Es la continuación directa del criterio de §2 (respaldo fuera
   del dominio) y del alcance de Tier 0 de `windows-server-ad-standards`.

DORA convierte parte de esto en obligación para su sector: al restaurar con sistemas propios exige
usar sistemas TIC **"física y lógicamente segregados del sistema TIC de origen"** (art. 12(3);
verificado ago-2026 sobre fuente secundaria — contrástalo con el texto oficial antes de citarlo,
§8).

**De qué medio se restaura y con qué se instala**:
- **Solo desde la copia inmutable u offline.** La copia en línea vive en el mismo plano de identidad
  y de red que el atacante: su integridad no es demostrable, y demostrarla es exactamente lo que se
  necesita. La copia se **monta en solo lectura** y se restaura **hacia** el IRE, nunca al revés; la
  credencial que el IRE usa contra el repositorio **lee y no borra**.
- **Catálogo del respaldo y material de cifrado entran primero.** Sin ellos, el repositorio inmutable
  es ruido caro (§4, gate 8).
- **El binario viene de medio confiable, no del entorno comprometido.** ISO, imágenes base, agentes,
  controladores, paquetes y plantillas de IaC se obtienen del origen del fabricante con **firma o
  hash verificado**, o de medio sellado guardado en frío. **Jamás** del *share* de instaladores, del
  registro de imágenes interno, del servidor de despliegue ni de la plantilla de oro del entorno
  caído: son precisamente los sitios donde una puerta trasera sobrevive al restore.
- **Preferencia estructural**: **reconstruir el sistema desde origen confiable e IaC y restaurar solo
  el dato**, en vez de restaurar la imagen completa — es más rápido y no arrastra la persistencia del
  atacante (coherente con `backup-recovery-standards` §3.8; la elección entre ambas vías se hace
  **explícita** y se ensaya la elegida).

**Orden de reconstrucción dentro del IRE — *identity-first***. Es la cadena de §3.3 comprimida y con
el compromiso como premisa:

```
0. Plano de gestión del IRE + estación de administración construida de origen limpio
1. Red interna del IRE, DNS y NTP propios, verificación del aislamiento
2. Catálogo de respaldo y material de cifrado
3. IDENTIDAD: directorio restaurado del punto que fija la investigación, en aislamiento,
   con eliminación de persistencia y rotaciones  → nada más se restaura hasta cerrar esto
4. Secretos y PKI: lo que vivía en el dominio comprometido se REEMITE, no se restaura
5. Datos y aplicaciones por tier, en orden de dependencia
6. Validación funcional con negocio + barrido de IOC + EDR reportando
```

- **Cada capa se valida antes de apilar la siguiente**: el IRE existe para que el problema aparezca
  ahí y no en producción; apilar sin validar convierte el entorno limpio en una segunda copia del
  desastre.
- El **procedimiento concreto** del directorio (DSRM, limpieza de metadatos, FSMO, RID, doble
  rotación de `krbtgt`) es de `windows-server-ad-standards` §3.9. **Aquí, la exigencia de que ocurra
  dentro del IRE y antes que todo lo demás.**

**Criterio de "limpio": qué hay que poder afirmar antes de reconectar.** No es "pasó el antivirus".
Por escrito, con evidencia y con lo que **no** se pudo determinar declarado explícitamente:
- el punto de restauración es **anterior al compromiso inicial según la investigación**, no según la
  fecha de detección;
- el vector está cerrado y **probado**, y la persistencia se ha buscado específicamente y eliminado
  (gate 7 de `incident-response-forensics-standards`);
- las credenciales del alcance están rotadas, **incluidas las que solo existen dentro de lo
  restaurado** (cuentas de servicio, claves embebidas, tokens de integración, certificados de
  cliente): rotar la mitad es no rotar;
- los IOC del caso se han barrido sobre lo restaurado y el **EDR está instalado y reportando antes**
  de la reconexión, no después;
- lo restaurado **hace lo que tiene que hacer** (prueba funcional validada por negocio), no solo
  arranca;
- la vigilancia reforzada posterior está activa y con ventana definida.

**Quién lo firma**: la aptitud **técnica de seguridad** (erradicación verificada) la firma el
responsable de la investigación; la **funcional**, el enlace con negocio; y la **reconexión a
producción la autoriza el director de crisis** (§3.4), con marca temporal y registro. Son tres
preguntas distintas y **una sola firma no cubre las tres**.

**Cuándo se construye — la trampa.** Un IRE diseñado el día del incidente se diseña sin identidad con
la que autenticarse, sin la documentación (que estaba en el dominio caído) y sin margen para comprar
ni contratar nada. Reparto obligatorio:
- **Preaprovisionado y probado en frío** (no negociable): identidad de emergencia del IRE y su
  credencial *break-glass* en custodia física o sellada; acceso al repositorio inmutable y a las
  claves, con su procedimiento de separación de funciones; runbook, inventario y contactos fuera de
  banda; plano de gestión separado con cuentas locales propias; y la **decisión escrita de dónde se
  levanta**, con capacidad, contratos y licencias comprobados.
- **Improvisable el día D**: dimensionado exacto, número de máquinas, direccionamiento interno y qué
  servicios del tier se levantan primero.
- **Regla de corte**: **lo que exija autenticarse contra el dominio comprometido, o contratar,
  comprar o esperar a un tercero, no es improvisable** — o está resuelto en frío, o no existe.
- **Se ejercita contra él**: la restauración de prueba y la simulación parcial (§3.7) se ejecutan
  **en el IRE**, no en un entorno de test cómodo. Es la única forma de saber que el IRE existe y
  cuánto tarda en existir.

**Coste y proporcionalidad.** Un IRE permanente y dedicado es caro y **no siempre se justifica**;
lo que no es opcional es tener **decidido y probado cómo se obtiene uno**. Escala, de mínimo a
máximo:

| Nivel | Qué es | Cuándo basta |
|---|---|---|
| **Mínimo aceptable** | Los preaprovisionados de arriba + **procedimiento escrito y ensayado** de levantar el IRE bajo demanda, con el **tiempo de construcción medido** y contado dentro del RTO | Es el suelo **para todos**. Si el tiempo de construcción no se ha medido, el RTO de un escenario de compromiso es ficción |
| **Bajo demanda en nube o desde IaC** | Cuenta, suscripción o *tenant* **separado** —otro dominio de fallo administrativo (§5)—, plantillas listas y despliegue probado periódicamente | **Opción por defecto para la mayoría**: coste cercano a cero en reposo y tiempo de construcción acotado y medible |
| **Permanente y dedicado** | Capacidad encendida, sin otro uso, con su plano de gestión y su identidad propios | Solo si el RTO del tier 1 no admite el tiempo de construirlo, o si la norma o el contrato lo exigen |

Los costes que se olvidan y deciden el ejercicio: **licencias y soporte** del software que hay que
levantar allí (más de una está atada a hardware, MAC o a un servidor de activación en Internet que el
IRE no alcanza), y el **tiempo y el coste de recuperación** desde clase de almacenamiento de archivo.
Ambos se comprueban en frío, no el día D.

### 3.7 Ejercicios: la única prueba de que el plan existe

Escala progresiva; ninguna sustituye a la siguiente:

1. **Tabletop** (semestral): mesa, sin sistemas. Se prueban **decisiones, roles, autoridad y
   comunicación**. Barato y descubre siempre algo: normalmente que nadie sabe quién declara.
2. **Simulación parcial** (anual): restauración real de un servicio **al IRE** (§3.6), con datos
   reales y **volumen real**, cronometrada — incluyendo el tiempo de **construir el propio IRE**.
   Descubre que el RTO estimado era optimista por un factor de 3 a 10.
3. **Failover real** (anual para tier 1): se conmuta el servicio de verdad, en ventana acordada, y se
   opera desde el sitio alterno **el tiempo suficiente para que aparezcan los problemas** (horas, no
   diez minutos). Incluye la **vuelta** (*failback*), que es la mitad olvidada y a menudo la más
   difícil.

Reglas del ejercicio:
- **Se cronometra todo** y se compara con el RTO/RPO comprometido. Ese contraste es el entregable.
- **Un ejercicio que no puede fallar es una demostración**, no un ejercicio. Se permite que salga mal;
  eso es exactamente para lo que sirve.
- **Rota los participantes**: si siempre lo ejecuta quien escribió el runbook, estás midiendo a esa
  persona, no al plan.
- **Escenarios que hay que ejercitar** más allá de "se cae el CPD": ransomware con backups atacados,
  compromiso del directorio, caída del proveedor cloud o SaaS crítico, pérdida del personal clave,
  corrupción silenciosa detectada tarde (¿hasta qué fecha tienes copias buenas?), y fallo del propio
  sistema de respaldo.
- **Todo hallazgo sale con dueño nominal y fecha**, y se revisa su cierre. Un ejercicio sin acciones
  cerradas es turismo.

## 4. Gates (rompen el programa, no el build)

1. **Sin restore probado no hay backup.** El indicador es "restauramos y **validamos** X en Y
   minutos", con fecha, no "el job terminó en verde". La **antigüedad del último restore validado**
   por sistema es un SLI de primera clase, con alerta cuando envejece.
2. **Sin ejercicio en los últimos 12 meses no hay plan**: un servicio de tier 1 sin ejercicio pasa a
   estado "sin cobertura declarada" y sube a riesgo aceptado formalmente por su dueño de negocio
   (vía `grc-compliance-standards`). No se disimula.
3. **RTO/RPO medidos y publicados junto a los comprometidos.** Si el medido supera al comprometido, o
   se corrige la arquitectura o **se corrige el compromiso**: mantener el número falso es el fallo de
   gobierno más caro del dominio.
4. **Cobertura**: % de servicios de tier 1 con RTO/RPO derivados de BIA, con orden de recuperación
   documentado y con ejercicio en plazo. Los tres a la vez, o no cuenta.
5. **Prueba de arranque en frío de la cadena crítica**: identidad, DNS, secretos y PKI recuperados
   desde cero, sin depender de sí mismos. Es el gate que más planes suspenden.
6. **Prueba de aislamiento del respaldo**: demostrar que la credencial de administrador de producción
   **no** puede borrar ni alterar las copias, y que la copia inmutable resiste un intento
   deliberado (ejecutado en ejercicio, no supuesto).
7. **Deriva del plan**: comparar el plan con el inventario real. Referencias a sistemas que no
   existen, o sistemas en producción sin entrada en el plan, son hallazgos.
8. **Custodia de claves verificada**: recuperar una copia cifrada usando **solo** el material
   custodiado fuera, con las personas designadas y su procedimiento de separación de funciones.

## 5. Escenarios y encuadre normativo

### Ransomware: el escenario que dicta el diseño

- **El atacante ataca los backups primero.** El respaldo no es una capa de recuperación si comparte
  el dominio de identidad y la red de producción. Exigencias: **infraestructura de respaldo aislada**
  (idealmente **fuera del dominio** — los servidores de backup unidos al dominio son un vector
  documentado), credenciales propias y no reutilizadas, MFA independiente, plano de gestión separado,
  y **al menos una copia inmutable u offline** (object lock, medio extraíble, repositorio con
  retención forzada por el proveedor).
- **La infraestructura de respaldo es software crítico y expuesto**: durante 2026 se publicaron
  múltiples RCE críticas en producto de respaldo líder (**Veeam Backup & Replication**: tanda de
  marzo de 2026 y **CVE-2026-44963**, CVSS v4 9.4, parcheada el 9-jun-2026, explotable por cualquier
  usuario de dominio con poco privilegio en instalaciones **unidas a dominio**), y CISA ha catalogado
  fallos anteriores del mismo producto como explotados activamente por grupos de ransomware. Parchea
  el sistema de respaldo con la misma urgencia que un servicio expuesto, y **sácalo del dominio**.
  Verifica el estado actual antes de citar cualquier CVE (§8).
- **Recuperación de la identidad primero.** Si el directorio está comprometido, el orden de
  recuperación cambia por completo: no se restaura nada sobre una identidad que el atacante controla.
  Restaurar el directorio no es restaurar una copia: es **restaurar la confianza** —copia limpia
  anterior al compromiso, entorno aislado, eliminación de persistencia (cuentas privilegiadas
  ocultas, `AdminSDHolder`, `SidHistory`, GPO manipuladas), validación y solo después reconexión—.
  **Ese entorno aislado es el IRE de §3.6, y se preaprovisiona antes de necesitarlo**; el
  procedimiento concreto para AD es de `windows-server-ad-standards` (§3.9).
- **El punto de restauración limpio lo determina la investigación**, no la prisa: el compromiso
  inicial suele ser muy anterior a la detección, así que la **profundidad de retención** debe cubrir
  el *dwell time* plausible (meses, no días). Coordina con `incident-response-forensics-standards`.
- **Tiempo de recuperación con volúmenes reales, medido**: restaurar decenas de TB no va a la
  velocidad del catálogo comercial. Mide, y si el número no cabe en el RTO, cambia la estrategia o el
  compromiso.
- **Doble extorsión**: recuperar el servicio no cierra el incidente. Sigue habiendo brecha, con sus
  obligaciones (ver `privacy-engineering-standards` e `incident-response-forensics-standards`). La
  decisión de pagar **no es técnica**.

### Terceros y SaaS

- **Tu proveedor caído es tu desastre**, y tu cliente no acepta "es culpa del proveedor". Cada
  tercero crítico entra en el BIA con su RTO/RPO efectivo **contractual** (léelo: el SLA suele
  compensar con crédito, no con recuperación) y con su plan de contingencia: modo degradado,
  alternativa, o procedimiento manual.
- **El SaaS no hace backup de tus datos por ti.** El modelo de responsabilidad compartida deja la
  **protección del dato** del lado del cliente en todos los modelos (IaaS, PaaS y SaaS), y la
  replicación del proveedor **no es backup**: un borrado, una corrupción o un cifrado malicioso se
  replican igual. La papelera nativa tiene retención limitada y un atacante con permisos puede
  vaciarla. Microsoft recomienda expresamente en su acuerdo de servicio respaldar el contenido con
  aplicaciones de terceros; existe además servicio nativo de pago (**Microsoft 365 Backup**, GA
  desde finales de 2024, consumo por GB protegido) con **cobertura parcial de cargas de trabajo** —
  verifica qué cubre hoy antes de darlo por suficiente (§8).
- **Salida de proveedor**: exportabilidad real de los datos (probada, no documentada), formato
  utilizable, plazo de disponibilidad tras la baja y coste de salida. Se prueba una vez al año como
  parte del ejercicio, igual que un restore.
- **Concentración**: si tu producción, tu respaldo y tu plan B están en el mismo proveedor y la misma
  cuenta, tu DR cubre el fallo de una región, no el del proveedor ni el de la cuenta (compromiso,
  cierre administrativo, error de facturación). Al menos una copia debe estar en **otro dominio de
  fallo administrativo**.

### Obligaciones regulatorias (estado ago-2026, **verifica cada punto en §8**)

- **DORA** (Reglamento UE 2022/2554, en aplicación desde el 17-ene-2025, entidades financieras) es
  el marco más prescriptivo en continuidad y el que conviene usar como listón incluso fuera del
  sector: **art. 11** (política de continuidad de TIC y planes de respuesta y recuperación) y **art.
  12** (políticas de copia de seguridad y procedimientos de restauración y recuperación). Exige, entre
  otros: **RTO y RPO por función**, determinados considerando si es función crítica o importante y su
  impacto en la eficiencia del mercado (art. 12(6)); restauración con **sistemas física y lógicamente
  segregados** del origen; **capacidades redundantes** adecuadas (salvo microempresas); **sitio
  secundario suficientemente distante** para tener un perfil de riesgo distinto, capaz de sostener las
  funciones críticas e inmediatamente accesible al personal; **comprobaciones y reconciliaciones
  post-recuperación** para garantizar la integridad del dato; y **prueba de los planes al menos
  anual** y ante cambios sustanciales, **incluyendo escenarios de ciberataque y de conmutación entre
  la infraestructura primaria y la redundante**, con función de gestión de crisis y comunicación
  (art. 14). Las pruebas avanzadas de resiliencia (TLPT) son terreno de
  `offensive-security-standards`.
- **NIS2** (Directiva UE 2022/2555), **art. 21(2)(c)**: "continuidad de la actividad, como la gestión
  de copias de seguridad y la recuperación en caso de catástrofe, y gestión de crisis". El
  **Reglamento de Ejecución (UE) 2024/2690** (17-oct-2024) desarrolla los requisitos técnicos y
  metodológicos: es **vinculante solo para ciertas categorías de entidades digitales** (DNS,
  registros TLD, proveedores de nube, centros de datos, CDN, proveedores de servicios gestionados y
  de seguridad gestionados, mercados en línea, buscadores y plataformas de redes sociales), pero
  ENISA y varias autoridades nacionales lo tratan como **referencia técnica de facto** para el
  conjunto del art. 21. Exige, en lo que aquí importa: contenido mínimo del plan, copias en
  **ubicaciones seguras geográficamente distantes** del sitio primario, inclusión del dato en la
  nube dentro del alcance de la copia, **pruebas de restauración periódicas con resultado
  documentado**, RTO/RPO por proceso crítico y **orden secuenciado de restauración validado en
  ejercicios**. ENISA publicó guía técnica de implementación: úsala como referencia.
- **España y NIS2**: la transposición (**Ley de Coordinación y Gobernanza de la Ciberseguridad**)
  **seguía sin publicarse en el BOE en agosto de 2026**; el anteproyecto se aprobó en Consejo de
  Ministros el 14-ene-2025 y la Comisión emitió un segundo requerimiento formal el **19-may-2026**
  (expediente INFR(2024)0270), con evaluación de progresos prevista para septiembre de 2026. **No lo
  des por publicado ni por indefinidamente pendiente: verifícalo** (§8). Mientras tanto, la
  directiva y los contratos con clientes ya rigen de hecho, y el ENS o ISO 27001 existentes son la
  base más rápida para cubrir el art. 21.
- **ISO 22301:2019 (+ Amd 1:2024, acción climática)** sigue siendo la edición vigente y está **en
  revisión** (borrador de comité, sin fecha de publicación confirmada). **ISO/TS 22317:2021** es la
  guía de BIA vigente, confirmada en 2025, y es *Technical Specification*: **no es certificable**.
  ISO 27031 (preparación TIC para la continuidad) es el complemento natural. El sistema de gestión y
  su certificación son de `grc-compliance-standards`.

## 6. Operabilidad y métricas

- **RTO/RPO medido vs. comprometido**, por servicio y con fecha del ejercicio. Es la métrica de
  cabecera del programa; todo lo demás es apoyo.
- **Antigüedad del último restore validado** y **del último ejercicio**, por servicio de tier 1. Con
  alerta al envejecer, igual que un certificado por caducar.
- **Cobertura**: % de servicios de tier 1 con BIA, orden de recuperación y ejercicio en plazo.
- **Deriva del plan**: nº de discrepancias entre plan e inventario detectadas por revisión
  automatizada.
- **Hallazgos de ejercicio abiertos y su antigüedad**: si no se cierran, el ejercicio es teatro caro.
- **Coste del programa por tier**, explícito y comparado con el impacto que evita. Es la única forma
  de tener la conversación de "¿por qué pagamos una región secundaria?" con datos y no con miedo.
- **Monitorización del propio DR**: replicación con lag vigilado y alertado, capacidad del sitio
  alterno revisada al crecer producción (un secundario dimensionado hace tres años ya no aguanta), y
  telemetría del sistema de respaldo tratada como servicio de producción — incluida la alerta por
  **restore de prueba fallido**, no solo por backup fallido.
- **Capacidad del sitio alterno como decisión explícita**: ¿100 % o modo degradado acordado con
  negocio? Si es degradado, **qué se apaga y en qué orden** se decide en frío y se escribe.

## 7. Sostenibilidad y prohibiciones

**Cadencia**: BIA revisado anualmente y ante cambio material del negocio; plan revisado tras cada
cambio arquitectónico relevante, tras cada ejercicio y tras cada incidente que lo active; matriz de
obligaciones regulatorias revisada anualmente; contactos y orden de sucesión verificados cada seis
meses (la gente cambia de puesto y de teléfono más deprisa que la arquitectura).

**El programa se adopta incrementalmente**: BIA de los tres procesos más críticos → RTO/RPO firmados
por su dueño → orden de recuperación dibujado → un restore probado → un tabletop. Eso ya es más
continuidad real que un manual de 200 páginas sin ensayar.

**PROHIBIDO**
- ❌ RTO/RPO fijados por el equipo técnico según lo que la infraestructura permite hoy.
- ❌ Plan de continuidad sin BIA detrás: son números inventados con apariencia de rigor.
- ❌ Declarar "hecho" un plan sin ejercicio; un plan no ensayado no existe.
- ❌ Backup sin restore probado y cronometrado con volumen real.
- ❌ Confundir HA con DR, o replicación con backup.
- ❌ Copia de respaldo alcanzable con credenciales de administrador de producción; servidor de backup
  unido al dominio de producción; ausencia de copia inmutable u offline.
- ❌ Claves de cifrado del respaldo custodiadas **solo** dentro del sistema respaldado.
- ❌ Restaurar tras un compromiso sin erradicación verificada, o desde un punto posterior al
  compromiso inicial.
- ❌ Reconstruir **sobre el dominio comprometido**, o unir el entorno de recuperación a ese dominio
  "para poder administrarlo".
- ❌ Administrar el IRE con **credenciales de administración de producción**, o desde el equipo
  habitual del administrador en vez de una estación construida desde cero de origen confiable.
- ❌ Conectar el IRE a la red de producción o a la de gestión **"solo un momento"** —copiar un
  fichero, consultar un dato, instalar un agente—: desde ese instante deja de ser un IRE y hay que
  volver a empezar.
- ❌ Plano de gestión (hipervisor, consola de respaldo, despliegue, IPMI) **compartido** con el
  entorno que se recupera: eso no es aislamiento, es una VLAN.
- ❌ Dar por **limpio** lo que solo ha pasado un antivirus: sin barrido de IOC del caso, sin EDR
  reportando antes de reconectar y sin firma de erradicación verificada, no hay reconexión.
- ❌ Restaurar en el IRE desde la copia **en línea**, o instalar binarios, imágenes o plantillas
  procedentes del entorno comprometido.
- ❌ IRE compartido con preproducción, pruebas o capacidad de picos.
- ❌ IRE que solo existe en el papel: **sin ensayo y sin tiempo de construcción medido dentro del
  RTO** no es una capacidad, es una intención.
- ❌ Retención más corta que el *dwell time* plausible de un atacante.
- ❌ Plan que vive únicamente en el sistema que se cae (wiki, SharePoint, gestor de contraseñas).
- ❌ Un solo héroe por tarea crítica; plan que asume que todo el mundo está disponible y localizable.
- ❌ Declaración de desastre que exige comité, reunión o autorización que nadie puede dar de madrugada.
- ❌ Ejercicio guionizado que no puede fallar, o siempre ejecutado por quien escribió el runbook.
- ❌ Ejercicio sin hallazgos con dueño y fecha, o con hallazgos que nadie cierra.
- ❌ Publicar RTO/RPO comprometidos que el ejercicio ha demostrado inalcanzables.
- ❌ Asumir que el SaaS respalda tus datos, o que su SLA equivale a un RTO.
- ❌ Producción, respaldo y plan B en la misma cuenta y el mismo proveedor sin decisión documentada.
- ❌ Multi-nube adoptada por reflejo, sin ADR y sin coste operativo y de personas cuantificado.
- ❌ Sitio secundario que nunca ha servido tráfico real ni se ha desplegado desde el mismo código.
- ❌ Olvidar el *failback* en el diseño y en el ejercicio.
- ❌ Fijar obligaciones regulatorias, artículos o ediciones de norma **de memoria** (§8).

## 8. Verificación web obligatoria

Antes de fijar cualquier cifra, artículo, edición o herramienta, **búscalo — no lo recuerdes**:

1. **DORA**: texto vigente de los **arts. 11, 12 y 14** y de los RTS/ITS aplicables (contenido de la
   política de continuidad, requisitos de segregación de los sistemas de restauración, distancia y
   perfil de riesgo del sitio secundario, cadencia y escenarios de prueba). Verificado a ago-2026 en
   fuentes secundarias: **contrasta contra el texto del Reglamento (UE) 2022/2554 antes de citarlo
   como requisito**. Estado de la designación de proveedores TIC críticos (CTPP) por las ESAs.
2. **NIS2**: **art. 21(2)(c)** y el **Reglamento de Ejecución (UE) 2024/2690** (a quién vincula
   exactamente y qué exige su Anexo en continuidad, copias y pruebas), más la **guía técnica de
   implementación de ENISA** y su versión vigente. **Hueco declarado**: el detalle del Anexo del CIR
   se ha tomado de fuentes secundarias y **no se ha contrastado contra el texto oficial**.
3. **NIS2 en España**: si la *Ley de Coordinación y Gobernanza de la Ciberseguridad* se ha publicado
   ya en el BOE, sus plazos y la autoridad competente. A ago-2026 **no estaba publicada** y el
   expediente INFR(2024)0270 seguía abierto (segundo requerimiento 19-may-2026). **No lo des por
   hecho en ninguna dirección.**
4. **ISO**: edición vigente de **ISO 22301** (a ago-2026, la de 2019 + Amd 1:2024, con revisión en
   fase de borrador de comité y **sin fecha de publicación confirmada**), de **ISO/TS 22317** (2021,
   confirmada en 2025) y de **ISO 27031**. Consulta la ISO Online Browsing Platform, no una web
   comercial.
5. **ENS (RD 311/2022)** y guías **CCN-STIC** aplicables si el sistema es de sector público español o
   de un proveedor suyo: requisitos de continuidad (`op.cont.*`) por categoría. **Hueco declarado**:
   no verificado en esta revisión.
6. **CVEs y estado del software de respaldo y de replicación** que vayas a recomendar. Verificado a
   ago-2026 sobre **Veeam Backup & Replication**: tanda de 7 CVE críticas el 12-mar-2026 (incluida
   CVE-2026-21708, CVSS 9.9) y **CVE-2026-44963** (CVSS v4 9.4, parche 12.3.2.4854 del 9-jun-2026,
   afecta a instalaciones unidas a dominio); CISA ha catalogado fallos previos del producto como
   explotados por ransomware. **Comprueba versiones corregidas y explotación activa antes de actuar**,
   y revisa igualmente cualquier **incidente de cadena de suministro** de la herramienta (precedente
   del catálogo: Trivy retirado como default tras el compromiso de marzo de 2026).
7. **Cobertura de los servicios nativos de respaldo de SaaS** antes de darlos por suficientes:
   **Microsoft 365 Backup** (GA desde finales de 2024, consumo por GB de contenido protegido) **no
   cubría en 2026 varias cargas** (chats de Teams, canales privados, Planner, Whiteboard, Loop,
   Stream, según fuentes secundarias). Verifica el alcance actual, y el equivalente de Google
   Workspace y de cualquier otro SaaS crítico, en la documentación del proveedor.
8. **Primitivas de DR del proveedor cloud** (replicación entre regiones, object lock/immutability,
   límites de cuota en una conmutación masiva, tiempos reales de restauración desde almacenamiento
   frío y sus costes de recuperación) en la documentación oficial. Los límites de cuota en la región
   secundaria son un modo de fallo clásico y silencioso.
9. **Recuperación de identidad**: procedimiento vigente de recuperación del bosque de Active
   Directory / Entra ID en la documentación de Microsoft y el estado de las herramientas de terceros
   antes de apoyarte en ellas. Verificado ago-2026 en fuente primaria (*AD Forest Recovery — Perform
   initial recovery*, Microsoft Learn): el primer DC escribible se restaura **con el cable de red
   desconectado o el adaptador en otra red**, y después los DC recuperados se unen a *"a common
   network that is isolated from the rest of the environment"* para validar salud y replicación
   antes de tocar producción. Verifica que la página sigue diciendo eso antes de citarla.
10. **Entorno de recuperación aislado (§3.6)**:
    - **DORA art. 12(3)** —restauración con sistemas *"physically and logically segregated from the
      source ICT system"*— verificado ago-2026 **sobre fuente secundaria**: **contrástalo contra el
      texto del Reglamento (UE) 2022/2554 en EUR-Lex** antes de citarlo como requisito, y comprueba
      si el RTS aplicable lo desarrolla.
    - **Origen limpio para administrar**: la formulación *"ensure any actions taken are performed
      from a trusted device built from a clean source"* procede de *Recovering from systemic identity
      compromise* (Microsoft Learn, Azure security fundamentals), verificada ago-2026 vía resultado
      de búsqueda; **no se abrió la página completa** — reverifica antes de citarla textualmente.
    - **Hueco declarado — no hay norma pública que especifique el IRE**: el término procede de
      documentación de fabricante (Broadcom/VMware lo define como *"an industry accepted acronym for
      Isolated Recovery Environment, ... a clean and secure network environment used specifically for
      recovery from ransomware attacks"*, verificado ago-2026) y **NIST SP 800-184** (2016, versión
      final vigente) no lo nombra como concepto. Trátalo como **criterio de ingeniería, no como
      requisito citable**, y si necesitas respaldo normativo usa DORA art. 12(3) o el CIR (UE)
      2024/2690 (§2 de esta lista).
    - **Hueco declarado — CISA**: no se pudo recuperar el texto del **#StopRansomware Guide** (la
      web de CISA y los PDF espejo devolvieron HTTP 403 en esta revisión), así que **no se cita**
      ninguna de sus frases sobre VLAN de recuperación limpia ni sobre medio de instalación
      confiable. Recupéralo y contrástalo antes de apoyarte en él.
    - **Producto de IRE de fabricante** (VMware Live Cyber Recovery, Rubrik, Commvault Cloud, Dell
      PowerProtect Cyber Recovery, Veeam y equivalentes): qué aísla realmente, si incluye identidad
      propia y qué queda a tu cargo. **No verificado en esta revisión**; el criterio de §3.6 vale
      con independencia del producto, y así debe usarse.

Si no puedes verificar, **dilo explícitamente en vez de suponer**.
Si la web contradice este documento, **manda la web** y señala la discrepancia.
