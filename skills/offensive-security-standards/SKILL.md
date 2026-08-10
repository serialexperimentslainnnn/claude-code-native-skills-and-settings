---
name: offensive-security-standards
description: Use when scoping or running an authorized offensive engagement — Rules of Engagement and scoping documents, penetration test, red team, purple team or adversary emulation with MITRE ATT&CK, Caldera or Atomic Red Team, PTES / OSSTMM / NIST SP 800-115 / OWASP WSTG / MASTG methodology, DORA TLPT and TIBER-EU exercises, PCI DSS 11.4 testing, bug bounty and VDP safe harbor, deconfliction with the SOC, or writing the engagement report, evidence chain, severity rating and retest.
---

# Estándares de seguridad ofensiva (pentest, red team, purple team)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **preparar, gobernar, ejecutar y cerrar un ejercicio ofensivo autorizado** contra
sistemas de la organización o de un tercero que ha contratado la prueba: elección del tipo de
ejercicio, Rules of Engagement y contrato, metodología de referencia, reconocimiento con
criterio, operación segura del equipo ofensivo, deconfliction con defensa, informe con
evidencia, severidad, retest y métricas del programa. Triggers: "Rules of Engagement", "RoE",
"alcance del pentest", "red team", "purple team", "adversary emulation", "TLPT", "TIBER-EU",
"PTES", "NIST SP 800-115", "OWASP WSTG/MASTG", "ATT&CK Navigator", "Caldera", "Atomic Red
Team", "PCI DSS 11.4", "bug bounty", "VDP", "safe harbor", "informe de pentest", "retest",
"deconfliction", "stop condition".

### Precondición dura — no negociable

**Sin autorización escrita del titular del sistema no se procede. No hay excepción técnica,
ni de urgencia, ni de "es obvio que querrían que lo probáramos".** Antes de la primera
petición de red debe existir **una** de estas dos cosas:

1. **Autorización por escrito y firmada** por quien tiene potestad sobre los activos:
   RoE firmadas con alcance explícito, exclusiones, ventana temporal, contactos de emergencia
   24×7, condiciones de parada y cláusula de no-daño (§3). Si el activo lo opera un tercero
   (nube, hosting, SaaS, MSP), la autorización del cliente **no basta**: hace falta también la
   del operador o el cumplimiento de su procedimiento de notificación de pruebas.
2. **Entorno de laboratorio propio, CTF o plataforma de entrenamiento** cuyos términos de
   servicio autoricen expresamente la actividad → eso es el dominio de `ctf-lab-standards`,
   no de esta skill.

Encuadre legal (España/UE, **orientativo, no asesoramiento jurídico**): el acceso no
autorizado a un sistema de información y la interceptación de comunicaciones están
tipificados en el Código Penal español (arts. 197 bis y 197 ter, introducidos por la LO
1/2015 en trasposición de la Directiva 2013/40/UE); los daños informáticos, en el art. 264.
**El consentimiento libre, específico e informado del titular es lo que hace lícita la
prueba** — la buena intención no es una defensa, y la ley no reconoce una figura de "hacking
ético" como eximente autónoma. La técnica empleada por un profesional y por un delincuente es
la misma; la diferencia es el papel firmado. **Toda RoE, y en particular cualquier duda sobre
alcance, jurisdicción o datos personales, se valida con el departamento legal de ambas
partes.** No improvises la interpretación de la norma.

**No aplica**: ver `ctf-lab-standards` (entrenamiento en laboratorio propio o plataforma con
ToS permisivos, donde la autorización es intrínseca al entorno y el objetivo es aprender, no
entregar riesgo a un cliente), `appsec-standards` (metodología **defensiva**: modelado de
amenazas, clases de vulnerabilidad y sus controles — el ofensivo las explota, el defensivo
las previene y las evita en diseño), `vulnerability-management-standards` (ciclo de vida de
CVEs de terceros, CVSS/EPSS/KEV, SSVC, SLA de remediación y VEX — **es el destinatario de tus
hallazgos**, no el productor), `grc-compliance-standards` (marco normativo, aceptación formal
de riesgo, evidencia de auditoría, obligación contractual de testear),
`identity-access-management-standards` (diseño del IdP, flujos OAuth/OIDC, PAM),
`cryptography-pki-standards` (evaluación de algoritmos y TLS), `networking-standards`
(segmentación y firewalling que se pone a prueba), `kubernetes-standards` (hardening de
imágenes y admisión), `bash-linux-scripting-standards` (herramienta propia y automatización),
`homelab-standards` (laboratorio personal general: hardware, coste, self-hosting), las skills
de nube y de lenguaje —entre ellas `powershell-standards`, que **deriva aquí** las técnicas
ofensivas que prohíbe en su §7 (evasión de AMSI y del *ScriptBlock Logging*, ofuscación,
descargadores en memoria) y se queda el criterio defensivo: firma de scripts, JEA, *Constrained
Language Mode*, transcripción y registro—, y `c-standards`/`cpp-standards` (explican categorías
de vulnerabilidad de memoria **para prevenirlas**; la explotación es de aquí), `assembly-standards`
(es una skill **defensiva y de ingeniería** — fija cuándo se justifica escribir
ensamblador y cómo se mantiene, y **declara explícitamente que no incluye recetario de explotación**
—shellcode, gadgets ROP, evasión—: eso es de aquí, con alcance y autorización por escrito),
`solidity-standards` (describe las clases de vulnerabilidad de contratos **para
prevenirlas**; probar un protocolo de terceros exige alcance y permiso explícitos y se rige por
esta skill). Además: `detection-engineering-standards` (reglas de
detección, SIEM y contenido analítico — **frontera compartida en purple team**: aquí se genera
la telemetría de ataque y se documenta la técnica; allí se escribe y valida la detección),
`incident-response-forensics-standards` (gestión del incidente real y forense —
si durante el ejercicio detectas un compromiso preexistente, paras y escalas allí),
`linux-hardening-standards`, `container-runtime-security-standards`.

## 2. Decisiones por defecto

> Verificar por web el estado de cada marco antes de citarlo en una propuesta o contrato (§8).
> Los datos siguientes son de agosto 2026 y caducan.

| Ámbito | Default | Motivo / alternativa justificable |
|---|---|---|
| Metodología base del informe | **NIST SP 800-115** como esqueleto de proceso (planificación → descubrimiento → análisis → explotación → post-testing) | Es la referencia que exigen o aceptan los auditores. **Ojo: sigue siendo la edición de 2008, sin revisión publicada** — cubre mal nube, CI/CD e identidad moderna: complétala, no la uses sola |
| Metodología técnica web | **OWASP WSTG** (estable **v4.2**, dic 2020; **v5.0 en desarrollo** en el repo) | Casos de prueba referenciables por ID (`WSTG-v42-<cat>-<n>`) en el informe. Enlaza siempre a la URL **versionada**, nunca a `latest` o `stable` |
| Metodología técnica móvil | **OWASP MASTG v2.0.0** (2026, primer estable del refactor v2) + **MASVS v2.1.0** (ene 2024, 8 categorías) | Los niveles "L1/L2/R" ya **no** están en MASVS: el riesgo se tiera por **perfiles del MASTG** (MAS-L1/L2/R). Un informe que cite MASVS L2 usa el modelo v1, retirado |
| Marco de procedimiento comercial | **PTES** solo como vocabulario de fases | Sin gobernanza formal activa y con partes técnicas envejecidas (referencias a plataformas ya irrelevantes, cobertura pobre de nube y contenedores). Cítalo por sus 7 fases, no como estándar técnico vigente |
| OSSTMM | **No por defecto** | Sigue en **v3 (2010)**; la v4 lleva años en borrador y el material nuevo está tras membresía de ISECOM. Útil si necesitas su métrica **rav** o su cobertura multicanal (humano, físico, wireless); si no, no aporta |
| Taxonomía de técnicas | **MITRE ATT&CK Enterprise v19.1** (v19 publicada 28 abr 2026) | Idioma común con defensa. Cambio estructural de v19: **la táctica Defense Evasion se parte en Stealth y Defense Impairment** — todo mapeo, informe o heatmap anterior necesita migración |
| Visualización de cobertura | **ATT&CK Navigator** con capas versionadas y guardadas en el repo del ejercicio | Una capa sin versión de ATT&CK anotada es inservible a los 6 meses |
| Emulación automatizada | **Atomic Red Team** (Red Canary) para pruebas atómicas de detección; **MITRE Caldera** para campañas encadenadas | Atomic para purple team continuo (biblioteca amplia y mapeada); Caldera cuando hace falta agente y cadena completa. **Verificar release y salud del proyecto antes de usar** (§8) |
| Emulación de adversario concreto | **Threat intelligence primero, TTPs después** | Emular un actor que no amenaza al cliente es teatro. En TLPT el proveedor de inteligencia es obligatoriamente externo |
| Severidad | **CVSS v4.0 como entrada, nunca como salida**, ajustada por explotabilidad demostrada + exposición + impacto de negocio | Ver `vulnerability-management-standards` para el modelo completo (CVSS-B vs CVSS-BTE, EPSS, KEV, SSVC). Un informe que ordena por CVSS base sin contexto no prioriza: ordena alfabéticamente el pánico |
| Sector financiero UE | **TIBER-EU** (actualizado 11 feb 2025 para alinearse con DORA) como vía para el **TLPT** de DORA arts. 26-27 | El RTS de TLPT se publicó el **18 jun 2025** y aplica desde el **8 jul 2025**. Los plazos los dispara la **carta de notificación de la autoridad** (3 meses para documentos de inicio, 6 para el scope), no una fecha universal. **Purple teaming es obligatorio** en TIBER-EU alineado |
| Pagos | **PCI DSS v4.0.1 req. 11.4** | Interno y externo **anuales y tras cambio significativo**, ambos, no intercambiables; validación de la **segmentación** al menos anual (más frecuente para *service providers*); metodología documentada e industry-accepted; testers con independencia organizativa. Confirmar la letra exacta con el QSA |
| Divulgación sin contrato | **VDP con safe harbor estilo disclose.io**; nunca testeo unilateral | Un programa público de bug bounty **es** la autorización, pero solo dentro de su alcance y sus reglas. Sin programa ni contrato, no hay autorización: se reporta el hallazgo, no se profundiza |

### Qué ejercicio, y cuándo

| Ejercicio | Pregunta que responde | Cuándo elegirlo | Cuándo es un error |
|---|---|---|---|
| **Vulnerability assessment** | ¿Qué debilidades conocidas tengo? | Cobertura amplia, barata, repetible; base de un programa naciente | Venderlo como pentest. No hay explotación ni encadenamiento |
| **Penetration test** | ¿Se puede explotar y hasta dónde llega? | Alcance acotado (app, red, nube, móvil, ICS), profundidad técnica, cumplimiento (PCI 11.4) | Esperar que mida la capacidad de **detección**: no la mide, y el pentester ruidoso no lo intenta |
| **Red team** | ¿Detectan y responden ante un adversario realista con objetivos concretos? | Programa maduro, con SOC operativo y detección ya existente | Con detección inmadura: gastas presupuesto para descubrir lo que un assessment te decía por 1/10 del coste |
| **Purple team** | ¿Qué vemos, qué no vemos, y qué regla falta? | Máximo retorno por euro en madurez de detección; obligatorio en TIBER-EU alineado a DORA | Confundirlo con un red team "con pistas": es colaborativo por diseño y se mide en detecciones creadas |
| **Adversary emulation** | ¿Aguantamos las TTPs del actor que realmente nos amenaza? | Hay inteligencia específica del sector; se emula un actor, no "un hacker" | Sin threat intel: emulas un actor irrelevante y validas nada |
| **TLPT (TIBER-EU / DORA)** | ¿Resiste la entidad financiera un ataque dirigido a funciones críticas? | Entidad significativa notificada por su autoridad | Tratarlo como un red team normal: hay Control Team, inteligencia externa obligatoria, y la autoridad puede rechazar el ejercicio |
| **Bug bounty / VDP** | ¿Qué encuentra la multitud de forma continua? | Complemento continuo tras alcanzar madurez | Como sustituto del pentest: cobertura sesgada a lo que paga y a lo fácil de demostrar |

## 3. Rules of Engagement: el contrato como artefacto de ingeniería

Las RoE no son papeleo previo: son **el documento de control del ejercicio**. Si algo no está
escrito ahí, no está autorizado. Contenido mínimo, todo explícito:

- **Partes y potestad**: quién firma y por qué tiene autoridad sobre esos activos. Firma de
  alguien sin potestad = ausencia de autorización.
- **Alcance positivo**: rangos IP, dominios, aplicaciones, cuentas de nube, identidades, apps
  móviles, ubicaciones físicas, personal en alcance para ingeniería social. **Enumerado**, no
  descrito ("todo lo del dominio" no es un alcance).
- **Exclusiones explícitas**: sistemas frágiles, legacy sin soporte, dispositivos médicos o
  industriales, terceros, ventanas de negocio críticas (cierre contable, campañas).
- **Terceros y proveedores**: qué activos son de un tercero, quién le pide permiso, y qué
  procedimiento de notificación previa exige cada proveedor de nube u hosting. Un activo de
  un tercero **sin su autorización queda fuera de alcance**, aunque el cliente lo use.
- **Ventana temporal**: fechas y **franjas horarias**. Fuera de ventana no se toca nada.
- **Técnicas autorizadas y prohibidas**: ingeniería social sí/no; phishing con qué límites;
  acceso físico; wireless; ataques a credenciales y su límite de bloqueo de cuentas; **DoS y
  pruebas de agotamiento de recursos: prohibidas salvo autorización explícita y aislada**.
- **Testing en producción**: si se prueba en producción (lo normal, porque preproducción no
  representa el riesgo), fijar límites de tasa, prohibición de modificar/borrar datos, y
  procedimiento de reversión de cualquier cambio.
- **Datos personales y datos reales**: qué se hace si se accede a PII, historia clínica,
  datos de pago o secretos. Regla por defecto: **se demuestra el acceso, no se extrae el
  dato**. Captura del mínimo imprescindible, redactada, y notificación inmediata.
- **Stop conditions** — el ejercicio se detiene y se escala de inmediato ante:
  indisponibilidad de un servicio productivo causada o sospechada; corrupción o pérdida de
  datos; evidencia de **compromiso previo por un tercero real**; acceso involuntario a un
  sistema fuera de alcance; hallazgo crítico con explotación trivial y exposición a internet;
  impacto sobre seguridad física o de personas; petición de parada del cliente.
- **Escalado y contactos**: nombres, teléfonos y suplentes 24×7 en ambos lados; canal de
  emergencia **fuera de banda** (no el correo corporativo del cliente, que puede ser
  precisamente lo que estás comprometiendo o lo que el atacante real vigila).
- **Cláusula de no-daño y de mínima intrusión**: la prueba demuestra el riesgo con el menor
  impacto posible; se elige siempre la PoC menos destructiva que evidencia el hallazgo.
- **Deconfliction**: procedimiento y palabra clave para que el SOC distinga tu actividad de
  un ataque real, y a la inversa (§6).
- **Propiedad, custodia y destrucción de datos**: quién es dueño de los hallazgos y evidencias,
  cifrado, retención máxima y **fecha de destrucción certificada**.
- **Confidencialidad y publicación**: NDA, y si se puede publicar un caso anonimizado.
- **Seguro de responsabilidad civil** del proveedor y límites de responsabilidad.

**Regla de oro**: ante cualquier ambigüedad sobre si algo está en alcance, **está fuera**
hasta que se aclare por escrito. La ampliación de alcance se documenta como adenda firmada,
nunca por mensaje de chat ni "de palabra con el técnico".

## 4. Calidad del trabajo ofensivo

Lo que separa un ejercicio profesional de un juego con herramientas.

### Reproducibilidad
- Cada hallazgo se documenta con **pasos exactos, precondiciones, cuenta usada, hora UTC y
  resultado esperado**. Si el defensor no puede reproducirlo, no puede verificar el cierre y
  el hallazgo se disputa.
- **Registro de toda la actividad**: log de comandos con marca temporal e IP de origen. Es lo
  que permite responder "¿fuiste tú a las 03:14?" durante y después del ejercicio, y lo que te
  exonera si algo se rompe por otra causa.
- Herramienta que se ejecuta contra producción, **se entiende primero**: qué peticiones lanza,
  a qué ritmo, qué escribe y qué puede romper. Correr un escáner con perfil agresivo contra un
  sistema frágil sin conocerlo es negligencia, no mala suerte.

### Cadena de custodia de la evidencia
- Evidencia mínima suficiente: captura recortada y **redactada**, hash del artefacto, no el
  volcado completo de una base de datos.
- Almacenamiento **cifrado en reposo**, acceso limitado al equipo del ejercicio, inventario de
  qué se recogió y dónde vive.
- **Destrucción certificada** en la fecha pactada, incluidas copias en portátiles, buckets
  temporales, infraestructura de operación y herramientas SaaS.

### Falsos positivos
- **Nada entra en el informe sin verificación manual.** La salida cruda de un escáner no es un
  hallazgo: es una hipótesis.
- Criterio de descarte: no reproducible en dos intentos, mitigado por un control que sí
  existe, o inaplicable por configuración → se descarta y **se documenta el descarte** (evita
  que reaparezca en el siguiente ejercicio como novedad).
- Cuando no se puede explotar por límite de alcance o de RoE pero la debilidad es real: se
  reporta como **hallazgo no confirmado**, con esa etiqueta y el motivo. Honestidad sobre
  espectáculo.

### Revisión por pares
- **Ningún informe se entrega sin revisión de un segundo operador**: severidad, reproducción,
  redacción, y comprobación de que no queda PII ni credenciales reales en el documento.
- Revisión específica de la **justificación de severidad**: cada crítica y alta debe soportar
  la pregunta "¿por qué no es una media?" con impacto de negocio, no con adjetivos.
- QA de cobertura: qué del alcance **no** se probó y por qué (tiempo, bloqueo, RoE). Un informe
  que no declara lo que no miró está afirmando implícitamente algo falso.

## 5. Seguridad de la operación ofensiva

El equipo ofensivo es, durante el ejercicio, **el mayor riesgo concentrado del cliente**:
tiene accesos, credenciales y datos que nadie más reúne. Se protege en consecuencia.

- **Infraestructura de operación aislada y con ciclo de vida definido**: dedicada por
  ejercicio y por cliente, **nunca compartida entre clientes**, levantada y destruida con IaC,
  con inventario de todo lo desplegado. Endurecida y parcheada: una infraestructura ofensiva
  comprometida convierte el ejercicio en una brecha real.
- **Datos del cliente**: cifrados en tránsito y en reposo, en almacenamiento controlado por el
  proveedor del servicio (nunca en portátiles sin cifrado de disco, nunca en SaaS personal ni
  en un LLM público), con MFA y mínimo privilegio. Retención mínima y borrado certificado.
- **PII hallada**: se para de recolectar, se notifica al contacto acordado y se documenta la
  exposición sin copiar el dato. Si hay indicios de brecha con obligación de notificación
  (GDPR), **es del cliente la obligación de notificar**; tu deber es informarle sin demora.
- **Hallazgo crítico**: se notifica **inmediatamente y fuera de banda**, sin esperar al
  informe final. Un crítico explotable en internet guardado tres semanas "para el entregable"
  es una decisión indefendible.
- **Compromiso previo detectado**: parada inmediata, notificación al contacto de emergencia,
  preservación de la evidencia sin tocar el sistema, y traspaso a respuesta a incidentes
  (`incident-response-forensics-standards`). No investigues tú el incidente ajeno
  salvo que te contraten para eso: contaminas la evidencia.
- **Cadena de suministro de tu propio toolchain**: 2026 ha demostrado que las herramientas de
  seguridad son el objetivo predilecto — la campaña **TeamPCP** (marzo 2026) comprometió por
  envenenamiento de tags y credenciales residuales varias piezas de tooling de CI/seguridad
  ampliamente desplegadas, con robo de secretos, backdoors persistentes y propagación tipo
  gusano. Consecuencia operativa: fija dependencias y acciones **por digest**, verifica firma
  y procedencia, ejecuta el tooling en entorno efímero sin credenciales de larga vida, y
  **comprueba por web si alguna herramienta que vas a usar tiene incidente reciente** (§8).
- **Cuentas y credenciales obtenidas** durante el ejercicio: tratadas como material clasificado
  del cliente. No se reutilizan fuera del ejercicio, no se guardan tras el cierre, y las que
  se crearon (usuarios, claves, tokens) se **inventarían y se retiran** en la fase de limpieza.
- **Higiene del operador**: equipo dedicado o VM del ejercicio, sin mezclar con navegación
  personal ni con datos de otros clientes; VPN y salida de red identificable y acordada con el
  cliente para permitir la atribución.

## 6. Operabilidad del ejercicio

### Planificación
- Kick-off con las **tres partes**: negocio (autoriza y define objetivos), TI/operación (sabe
  qué se rompe), y seguridad/SOC (decide el grado de conocimiento previo). Sin TI en la sala,
  la primera caída de servicio será una crisis contractual.
- **Objetivos en lenguaje de negocio**, no de técnica: "¿puede alguien desde internet llegar a
  los datos de nómina?" en vez de "probar la DMZ". Los objetivos determinan el alcance, no al
  revés.
- Dimensionado honesto: si el tiempo asignado no cubre el alcance, se recorta el alcance o se
  declara la cobertura parcial **antes** de firmar. Vender cobertura imposible es fraude.

### Comunicación durante el ejercicio
- **Canal permanente** con el Control Team / punto de contacto, y cadencia acordada (diaria en
  pentest, hitos en red team).
- **Notificación inmediata** de: crítico explotable, indisponibilidad, cambio hecho en un
  sistema, y cada activación de una stop condition.
- **Registro de decisiones**: toda ampliación, excepción o autorización puntual se refleja por
  escrito en el log del ejercicio y se confirma por la persona que la concede.

### Deconfliction con el SOC
- **Antes de empezar**: entregar al Control Team las **IPs de origen, rangos, dominios y
  agentes** utilizados, más una palabra clave del ejercicio y un procedimiento de consulta
  rápida. En red team esta información la custodia el Control Team, no el SOC, hasta el final.
- **Durante**: cuando el SOC detecta algo, puede preguntar por el canal de deconfliction si es
  actividad del equipo. La respuesta es sí/no en minutos. **Nunca se responde "no" a una
  actividad que sí es tuya**: eso convierte un ejercicio en un incidente falso con coste real.
- **La actividad no atribuible es un hallazgo, no ruido**: si el SOC detecta algo que no eres
  tú, eso es lo más importante que ha producido el ejercicio (ver §5, compromiso previo).
- **Cierre de deconfliction**: al terminar, sesión conjunta de reconstrucción de la línea
  temporal — qué hiciste, qué vieron, qué no vieron y por qué. **Ese cruce es el entregable
  de valor real de un red team**, más que la lista de fallos.

### Purple team y traducción a detección
- Cada técnica ejecutada se registra con: **ID de ATT&CK (con versión de la matriz)**, hora
  UTC, host, cuenta, y la telemetría que *debería* haber generado (fuente de log, campo).
- La salida del ejercicio hacia defensa es una tabla **técnica → ¿prevenida? / ¿detectada? /
  ¿alertada? / ¿respondida?**. Las cuatro columnas son distintas: detectar sin alertar es no
  detectar en la práctica.
- Las brechas de detección se entregan como **requisitos de regla**, no como reglas escritas:
  el contenido de detección lo escribe y valida quien opera el SIEM
  (`detection-engineering-standards`). Escribir tú la regla sin conocer la telemetría
  del cliente genera falsos positivos que se desactivan a la semana.
- Reejecutar la técnica **tras desplegar la detección** para validarla. Un purple team que no
  reejecuta no ha cerrado el bucle.

### Entregable
- **Resumen ejecutivo** en lenguaje de negocio: qué riesgo real existe, en qué escenario y qué
  hay que decidir. Sin jerga, sin CVSS, sin nombres de herramienta. Una página.
- **Narrativa del ataque**: la cadena, no la lista. Cinco medias encadenadas que llevan a
  dominio son una crítica; la lista suelta de cinco medias no comunica nada.
- **Hallazgos**: descripción, evidencia reproducible, **severidad justificada** (CVSS v4.0 +
  explotabilidad demostrada + exposición + impacto de negocio; EPSS/KEV cuando el hallazgo sea
  un CVE conocido), y **recomendación accionable** — causa raíz y remedio concreto, no
  "aplicar buenas prácticas".
- **Cobertura y limitaciones**: qué se probó, qué no y por qué. Explícito.
- **Retest**: incluido en el contrato desde el principio, con ventana definida. Se verifica el
  **cierre real**, no la declaración de cierre. El resultado del retest se anexa al informe
  original; un hallazgo se cierra cuando el retest lo confirma, nunca antes.
- **Limpieza y cierre**: inventario de **todo** lo desplegado (cuentas, tareas programadas,
  claves, ficheros, implantes, reglas, hosts) con su retirada confirmada y firmada por ambas
  partes. Lo que no se pueda retirar se documenta y se entrega al cliente para que lo elimine.
- **Traspaso a gestión de vulnerabilidades**: los hallazgos entran en la cola de
  `vulnerability-management-standards` con dueño y SLA; el informe no es el final del proceso,
  es su entrada.

### Métricas honestas del programa
- Miden **mejora defensiva**, no producción ofensiva: cobertura de técnicas ATT&CK detectadas,
  tiempo hasta detección y hasta contención por ejercicio, detecciones nuevas desplegadas y
  validadas, % de hallazgos cerrados dentro de SLA, y recurrencia de la misma causa raíz entre
  ejercicios.
- **Vetadas**: número de vulnerabilidades encontradas, número de "dominios comprometidos",
  y cualquier métrica que premie ruido o penalice al cliente por dejarte encontrar cosas.
  La recurrencia de causa raíz es la métrica que más duele y más sirve.

## 7. Sostenibilidad y prohibiciones

### Cadencia
- **RoE y plantilla contractual**: revisión anual y tras cualquier incidente durante un
  ejercicio; validación legal cuando cambie la normativa aplicable.
- **Mapeos de ATT&CK**: revisión en cada release mayor de la matriz. La v19 (abr 2026) partió
  Defense Evasion en **Stealth** y **Defense Impairment**: todo heatmap, capa de Navigator o
  informe anterior necesita migración explícita, no reetiquetado automático.
- **Metodologías**: verificar por web al inicio de cada ejercicio la versión vigente de WSTG,
  MASTG/MASVS y ATT&CK que se citará en el informe (§8).
- **Toolchain**: revisión trimestral de salud, licencia y **incidentes de cadena de
  suministro** de cada herramienta del arsenal.
- **Frecuencia de ejercicio**: anual y tras cambio significativo como suelo (exigencia PCI DSS
  11.4); trienal para TLPT bajo DORA; continuo para purple team y bug bounty. La frecuencia la
  fija el ritmo de cambio del sistema, no el calendario de auditoría.

### PROHIBIDO

**De esta skill como documento** (criterio editorial, no nota al pie):
- ❌ Incluir **payloads listos para usar**, cadenas de explotación armadas o código de exploit.
- ❌ Documentar **bypasses concretos** de un producto de seguridad (EDR, WAF, MFA) nombrado.
- ❌ Listar **credenciales por defecto** de terceros o dónde encontrarlas.
- ❌ Recoger **técnicas de evasión de detección** para uso real fuera de un ejercicio
  autorizado y documentado.
- ❌ Convertir esto en recetario. **Metodología y gobernanza**: el "cómo se hace" técnico vive
  en las metodologías citadas y en la formación, bajo autorización.

**De la operación**:
- ❌ Tocar cualquier cosa **sin autorización escrita** o fuera de la ventana o del alcance
  pactados. Sin excepción, sin urgencia que lo justifique.
- ❌ Aceptar una ampliación de alcance verbal, por chat, o de alguien sin potestad.
- ❌ **Ejecutar una herramienta contra producción sin entender qué hace**: qué peticiones
  lanza, a qué ritmo, qué escribe, qué puede romper.
- ❌ DoS, pruebas de agotamiento de recursos o ataques destructivos sin autorización explícita,
  aislada y por escrito.
- ❌ **Exfiltrar datos reales del cliente "como prueba"**. Se demuestra el acceso, no se extrae
  el dato. Nunca volcados masivos, nunca PII completa, nunca a infraestructura propia.
- ❌ Dejar **artefactos, cuentas, tareas, claves o implantes sin retirar y sin documentar**.
  Cada uno es una puerta trasera que dejaste tú.
- ❌ Reutilizar infraestructura de operación o credenciales entre clientes.
- ❌ Guardar datos, evidencias o credenciales del cliente pasada la fecha de destrucción
  pactada, o en almacenamiento personal, portátil sin cifrar o SaaS/LLM público.
- ❌ Ocultar o retrasar un hallazgo crítico, una indisponibilidad causada o un compromiso
  preexistente detectado.
- ❌ Negar ante deconfliction una actividad que sí es tuya.
- ❌ Continuar el ejercicio tras activarse una stop condition.
- ❌ Meter en el informe salida cruda de escáner sin verificación manual, o severidades
  infladas para justificar el precio.
- ❌ Testear activos de terceros (nube, SaaS, proveedor) sin su autorización o sin seguir su
  procedimiento de notificación, aunque el cliente los use y los pague.
- ❌ Usar en un cliente lo aprendido en un CTF sin comprobar que la técnica es aplicable, no
  destructiva y está dentro de las RoE (ver `ctf-lab-standards`).
- ❌ Presentar un vulnerability assessment como pentest, o un pentest como red team.
- ❌ Fijar versiones de matrices, guías o normativas de memoria sin la verificación de §8.

## 8. Verificación web obligatoria

Antes de citar cualquier marco, versión o plazo en una propuesta, RoE o informe:

1. **ATT&CK**: versión vigente de la matriz Enterprise y del Navigator, y changelog de la
   última release mayor (a agosto 2026: **v19.1**, tras v19 del 28 abr 2026 con el split de
   Defense Evasion). Anota siempre la versión usada en el informe.
2. **OWASP**: si **WSTG v5.0** ya salió de desarrollo (estable a agosto 2026: **v4.2**), y
   versiones vigentes de **MASTG** (**v2.0.0**) y **MASVS** (**v2.1.0**).
3. **NIST SP 800-115**: comprobar en csrc.nist.gov si existe revisión o borrador posterior a
   la edición de **2008** — a agosto 2026 no consta ninguna, y ese es un dato que conviene
   reconfirmar antes de apoyar un informe solo en ella.
4. **PTES y OSSTMM**: estado real de mantenimiento. A agosto 2026, PTES sin gobernanza formal
   activa y OSSTMM en **v3 (2010)** con v4 en borrador desde hace años. **Pendiente de
   verificar**: si ISECOM ha publicado OSSTMM 4 (el material nuevo está tras membresía y no se
   pudo confirmar desde fuentes públicas).
5. **DORA / TIBER-EU**: RTS de TLPT aplicable desde el **8 jul 2025**; TIBER-EU alineado desde
   **11 feb 2025**. Verificar qué autoridad nacional aplica al cliente, si ya ha adoptado el
   marco alineado, y los plazos que dispara su carta de notificación. Las fechas de "primer
   ciclo" que circulan en blogs sectoriales (p. ej. antes del 17 ene 2028) **no están
   confirmadas en fuente oficial**: contrástalas con la NCA.
6. **PCI DSS**: versión vigente y letra exacta del req. 11.4 en el documento oficial del PCI
   SSC o vía QSA; los blogs numeran mal las sub-requisitos.
7. **CVSS / EPSS / KEV**: versión y estado vigentes — **el dueño de ese criterio es
   `vulnerability-management-standards`**, que lo mantiene verificado; consúltalo allí en vez
   de duplicarlo aquí, y re-verifica por web si vas a fijar una decisión sobre ello.
8. **Herramientas del arsenal** (incluidos **Caldera** y **Atomic Red Team**): release actual,
   licencia, gobernanza y, **obligatorio**, si hay incidente de cadena de suministro reciente
   — precedente 2026: la campaña **TeamPCP** de marzo de 2026 sobre tooling de seguridad y CI.
   Ninguna herramienta entra en un ejercicio sin esa comprobación. **Pendiente de verificar**:
   la última release de Caldera (la referencia disponible, v5.3.0 de abril 2025, procede de
   fuente secundaria y no se contrastó contra el repositorio).
9. **Frameworks de C2 y herramientas de post-explotación**: **no verificados en este
   documento** y deliberadamente no recomendados por producto — su elección se decide por
   ejercicio, contra fuente primaria, y comprobando licencia, procedencia y actividad de
   soporte del proyecto.
10. **Marco legal**: cualquier afirmación jurídica de §1 se valida con el departamento legal
    de ambas partes y con el texto vigente del Código Penal y de la normativa sectorial. Esta
    skill **no es asesoramiento jurídico** y su encuadre puede haber quedado desactualizado.
11. **Safe harbor / VDP**: términos vigentes del programa concreto antes de tocar nada, y
    estado actual de las referencias de disclose.io y de los términos de la plataforma
    (HackerOne/Bugcrowd). El alcance de un programa cambia sin aviso.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
