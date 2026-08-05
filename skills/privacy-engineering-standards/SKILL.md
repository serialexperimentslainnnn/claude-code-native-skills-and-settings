---
name: privacy-engineering-standards
description: Use when privacy must be built into the system rather than written in a policy — PII discovery in source and columns, minimization and purpose limitation by design, automated deletion that actually deletes everywhere, LINDDUN privacy threat modelling (GO/PRO/MAESTRO), NIST Privacy Framework, DPIA/EIPD triggers, k-anonymity, l-diversity, t-closeness and differential privacy budgets (OpenDP, SmartNoise, Tumult, Google DP), tokenization, masking, synthetic test data, Presidio, crypto-shredding with per-data-subject keys, GDPR data subject rights (access, portability, rectification, erasure) implemented as software across every copy, consent as versioned auditable state, PII leaking into logs, traces and metrics, EU-US Data Privacy Framework and international transfer design, personal data in AI training, model memorization and the AI Act, and personal data breach impact assessment.
---

# Estándares de ingeniería de privacidad

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando la privacidad tiene que existir **dentro del sistema**: esquemas, pipelines, APIs,
telemetría, entornos no productivos y modelos. Cubre el inventario y la clasificación del dato
personal, la minimización y la limitación de propósito traducidas a decisiones de diseño, el
modelado de amenazas de privacidad, las técnicas de desidentificación y su honestidad real, los
derechos del interesado implementados como funcionalidad, el consentimiento como estado, la
telemetría sin PII, el encaje de los sistemas de IA que tratan datos personales y la parte técnica
de una brecha.

Triggers: "PII", "datos personales", "categoría especial", "minimización", "limitación de
propósito", "retención", "borrado", "derecho al olvido", "supresión", "acceso", "portabilidad",
"rectificación", "DSAR", "consentimiento", "banner", "anonimizar", "seudonimizar", "k-anonimato",
"l-diversidad", "privacidad diferencial", "tokenización", "enmascarado", "datos sintéticos",
"datos de prueba", "copiar producción a pre", "crypto-shredding", "clave por sujeto", "LINDDUN",
"DPIA", "EIPD", "transferencia internacional", "SCC", "Data Privacy Framework", "entrenamiento con
datos personales", "brecha de datos personales", "PII en logs".

**Principio rector**: **el único control de privacidad que no falla es el dato que no se recoge.**
Todo lo demás —cifrado, control de acceso, retención, borrado— es mitigación de un riesgo que
elegiste asumir. Corolario: una política de privacidad no protege a nadie; un `DROP` programado,
una clave destruida y un campo que nunca se pidió, sí.

**No aplica**:
- `grc-compliance-standards`: el **marco de gestión** — ISO/IEC 27701:2025 como PIMS certificable,
  SoA, registro de riesgos, registro de actividades de tratamiento (RoPA) como artefacto de
  gobierno, evidencia de auditoría, contratos con encargados y cuestionarios de terceros. Aquí vive
  la **ingeniería y el control técnico verificable**; allí, el sistema de gestión que lo certifica.
  Regla de arbitraje: si la pregunta se responde con un documento firmado, es de `grc`; si se
  responde ejecutando una consulta, un test o un despliegue, es de esta skill.
- `data-platform-standards`: la traducción a **el almacén concreto** — retención por particiones y
  `retention.ms`, TTL de caché, cifrado en reposo del motor, tombstones de Kafka, RLS. Aquí, la
  **obligación, el alcance completo del borrado y su verificación extremo a extremo** (que incluye
  almacenes que esa skill no cubre: índices de búsqueda, colas, data lake, backups y terceros).
- `bcdr-standards` (**Ola 1**): la política de **retención e inmutabilidad del respaldo** y el plan
  de recuperación. Frontera declarada en ambos lados: la obligación de suprimir y su implementación
  técnica son de esta skill; la ventana de retención del backup, su inmutabilidad y el orden de
  recuperación son de `bcdr`. El conflicto entre ambas (§3.5) se resuelve por diseño, no discutiendo.
- `cryptography-pki-standards`: elección de algoritmos, gestión y custodia de claves, KMS/HSM. Aquí
  solo el **patrón** (clave por sujeto) y la exigencia de que la destrucción sea real y auditable.
- `secrets-management-standards` (**Ola 1, planificada**): secretos de aplicación; un dato personal
  no es un secreto y no se gestiona igual.
- `identity-access-management-standards`: autenticación y autorización de quien accede al dato,
  incluida la verificación de identidad del solicitante de un derecho.
- `observability-standards`: pipeline de telemetría, muestreo y retención de logs. Aquí, **qué no
  puede entrar** en él y cómo se comprueba.
- `appsec-standards`: STRIDE y clases de vulnerabilidad. LINDDUN **complementa** a STRIDE, no lo
  sustituye: un sistema puede ser seguro y a la vez abusivo con el dato (§3.2).
- `incident-management-standards` e `incident-response-forensics-standards`: gobierno y respuesta
  técnica del incidente. Aquí, la **evaluación de la brecha desde la óptica del interesado** y lo
  que ingeniería debe poder responder en horas (§5). El criterio de notificar es de legal/DPO.
- `api-design-standards`, las skills de lenguaje y `kubernetes-standards`/`cicd-standards`: el
  contrato, el código y la tubería por los que circula el dato.
- `ai-governance-standards` (**Ola 3, planificada**): gobierno del sistema de IA — riesgo del
  modelo, evaluación, documentación técnica y obligaciones de proveedor bajo el AI Act. Aquí, la
  **privacidad del dato que lo alimenta**: base de licitud del entrenamiento, memorización y
  extracción, y derechos sobre un modelo ya entrenado.
- `technical-hiring-standards` (**Ola 6**): el diseño del proceso de selección, su rúbrica y su
  validez son suyos; **los datos personales de las candidaturas son de aquí** — base de licitud,
  minimización, plazo de conservación y **borrado efectivo en todas las copias, incluida la del
  sistema de seguimiento y la de los correos de los entrevistadores**. Precondición dura que ambas
  sostienen: **un proceso de selección trata datos personales de personas que no son clientes ni
  empleados**, y la mayoría de organizaciones nunca ha fijado su plazo de supresión.

**Esto no es asesoramiento jurídico.** Fija criterio de ingeniería para construir sistemas que
cumplen; la base de licitud, la evaluación de riesgo legal y la decisión de notificar las fija
legal/DPO. Cuando esta skill dice "verifícalo", significa exactamente eso.

## 2. Decisiones por defecto

> Verificar por web cada norma, versión y estado regulatorio antes de fijarlo en un proyecto real
> (§8). **Este es el dominio del catálogo con los datos más volátiles**: los de esta tabla son de
> agosto de 2026 y algunos estaban en movimiento activo al escribirla.

| Decisión | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| Modelado de amenazas de privacidad | **LINDDUN** junto a STRIDE, no en su lugar. Variantes vigentes: **GO** (baraja, análisis ligero), **PRO** (sistemático sobre DFD), **MAESTRO** (dirigido por modelo) | Categorías actuales: **Linking, Identifying, Non-repudiation, Detecting, Data Disclosure, Unawareness, Non-compliance**. Citar el desglose antiguo (*linkability, identifiability, …, disclosure of information*) es un error frecuente: el sitio oficial ya usa el nuevo |
| Marco de riesgo de privacidad | **NIST Privacy Framework** alineado con CSF 2.0 | **Estado a ago-2026: la v1.1 seguía sin publicación final confirmada** (IPD abr-2025; NIST anunció final "en 2026"). Cita la edición que verifiques, no la que recuerdes (§8) |
| Unidad de diseño | **El sujeto de datos**, no la tabla: todo dato personal debe ser localizable, exportable y destruible **por sujeto** en todos los almacenes | Diseños donde el dato de una persona solo se puede encontrar escaneando: es una supresión que no se podrá cumplir |
| Retención | **Borrado automático programado**, con dueño y alerta si no se ejecuta | Retención "documentada" sin job que la aplique = no hay retención |
| Desidentificación por defecto | **Seudonimización** (sigue siendo dato personal) y decirlo así | Llamar "anonimizado" a lo seudonimizado: técnicamente falso y **agravante** ante la AEPD |
| Anonimización real | Solo con **evaluación documentada de reidentificación** (singularización, vinculabilidad, inferencia) y control del contexto de publicación | k-anonimato **como suelo, no como garantía**: cae ante datos de alta dimensionalidad y conocimiento auxiliar; complétalo con l-diversidad/t-cercanía y asume que sigue sin ser una garantía formal |
| Garantía formal | **Privacidad diferencial** cuando se publiquen estadísticas o se entrenen modelos sobre datos personales — es el único marco con garantía demostrable, y **paga en utilidad**: presupuesto ε explícito, contabilizado y publicado | Aplicarla sin contabilidad de presupuesto (cada consulta gasta) o con ε alto "para que salgan los números": es teatro con notación griega |
| Herramientas de DP | **OpenDP Library** (Harvard/OpenDP) y **SmartNoise SDK**; **Tumult Analytics**; **Google DP** (Java/Go/C++) como pila independiente | **`smartnoise-core` está deprecado** y redirige a la librería OpenDP: no lo introduzcas en nada nuevo. Verifica versión y actividad antes de elegir (§8) |
| Borrado a escala en almacenes inmutables | **Crypto-shredding**: clave de cifrado **por sujeto de datos**, destrucción auditada de la clave | Es la única vía práctica en logs append-only, event sourcing, WORM y backups; **no** sustituye al borrado real donde el borrado real es posible |
| Detección de PII | **Presidio** (analyzer/anonymizer/image-redactor/structured) en CI y en el pipeline de datos | **Cambió de dueño**: es proyecto **comunitario bajo *Data Privacy Stack***, imágenes en `ghcr.io/data-privacy-stack/presidio-*`; las de `mcr.microsoft.com` son legacy y **ya no se actualizan**. Detección automática = red, nunca garantía |
| Datos en preproducción | **Sintéticos o generados**; si no es viable, seudonimizados con clave irreversible para quien opera el entorno y **entornos separados** | **PROHIBIDO** copiar producción con datos reales a pre/QA/desarrollo. Es la brecha más común y la más barata de evitar |
| Consentimiento | **Estado versionado, con marca temporal, texto exacto mostrado, versión de política y prueba de la acción**; consultable y revocable por API | Banner que escribe una cookie y nada más; consentimiento como *booleano* sin historia |
| Transferencias fuera del EEE | Diseño **agnóstico de la base de transferencia**: región conocida, dato localizable y **capacidad probada de cambiar de región o proveedor** | Verificar el estado del **EU-US Data Privacy Framework** antes de apoyarse en él (§5 y §8): sigue vigente pero recurrido |
| DPIA/EIPD | **Disparada por criterios técnicos escritos** (§3.6), evaluada como artefacto de ingeniería y **antes** del diseño, no antes del lanzamiento | DPIA redactada tras construir el sistema: es una justificación, no una evaluación |
| PII en telemetría | **Prohibida por defecto**, con redacción en el borde y test que lo verifica | Confiar en que "el equipo tendrá cuidado" al hacer `log.info(user)` |

## 3. Diseño: la privacidad como propiedad construida

### 3.1 Inventario y taxonomía del dato

Sin inventario no hay minimización, ni supresión, ni notificación de brecha correcta. **La fuente de
verdad es el esquema anotado, no una hoja de cálculo**: se versiona en git, se valida en CI y se
genera desde él la documentación, no al revés.

```yaml
# data-catalog/usuarios.yaml — anotación por campo, verificada en CI
tabla: usuarios
sujeto: persona_usuaria           # de quién es el dato (clave de todo lo demás)
campos:
  email:
    clase: pii_directo            # identificador directo
    proposito: [autenticacion, notificacion_transaccional]   # NO "marketing" salvo consentimiento
    base_licitud: contrato        # la fija legal/DPO; aquí se registra y se aplica
    retencion: 30d_tras_baja
    tratamiento: cifrado_por_sujeto
  ip_registro:
    clase: pii_indirecto
    proposito: [antifraude]
    retencion: 90d
  categoria_salud:
    clase: categoria_especial     # art. 9 RGPD: exige justificación reforzada y aislamiento
    proposito: [prestacion_servicio]
    tratamiento: cifrado_por_sujeto + acceso_restringido + auditoria_de_acceso
destinos:                          # a dónde fluye: sin esto, la supresión no es completa
  - postgres.primaria
  - postgres.replica_reporting
  - opensearch.indice_usuarios
  - kafka.topic.usuario_actualizado
  - s3://datalake/bronze/usuarios
  - proveedor_email_transaccional  # encargado: contrato + procedimiento de borrado
```

Reglas duras:
- **Un campo sin `clase`, `proposito` y `retencion` no se mergea.** El gate está en §4.
- **Categorías especiales** (salud, biometría, orientación, ideología, origen…) e identificadores de
  alto impacto (DNI/NIF, datos de menores, geolocalización precisa, datos financieros) viven
  **aislados**: esquema o servicio propio, acceso auditado por defecto, nunca en un `SELECT *`
  compartido, nunca en un evento de dominio genérico.
- **`destinos` es la lista de sitios donde hay que borrar.** Si está incompleta, la supresión miente.

### 3.2 Minimización y limitación de propósito, aplicadas

- **Minimización real es de esquema, no de política**: el campo que no está en la tabla no se filtra,
  no se exporta, no se pierde y no hay que borrarlo. Ante cada campo nuevo: *¿qué decisión concreta
  del producto no se puede tomar sin él?* Si la respuesta es "por si acaso", no se recoge.
- **Precisión mínima suficiente**: fecha de nacimiento → franja de edad; coordenadas → municipio;
  timestamp exacto → hora truncada. La reducción de precisión es la minimización más barata y la que
  nadie hace.
- **Derivar y descartar**: si solo necesitas "mayor de edad", calcula el booleano en el borde y no
  almacenes la fecha. Si solo necesitas "cliente recurrente", no guardes el histórico completo.
- **Limitación de propósito en el pipeline, no en el contrato**: el propósito viaja con el dato
  (columna, cabecera de evento, etiqueta del dataset) y **el consumidor que no declara un propósito
  compatible no recibe el campo**. Un topic o un dataset por propósito es más simple y más
  defendible que una tabla universal con reglas de acceso barrocas.
- **Analítica y producto no comparten almacén**: los datasets derivados llevan claves sustitutas sin
  PII; la tabla de correspondencia vive bajo el control de acceso más estricto del sistema y con
  acceso auditado.
- **LINDDUN sobre el DFD** en todo diseño nuevo o cambio de flujo de datos, en la misma sesión que
  STRIDE: STRIDE pregunta *"¿quién puede romperlo?"*; LINDDUN pregunta *"¿qué hace este sistema con
  la persona aunque funcione perfectamente?"*. Amenazas que STRIDE **no** ve: vinculabilidad entre
  sesiones, identificación por combinación, inferencia, detectabilidad (el hecho de que existas en
  el sistema ya revela algo), falta de transparencia. Empieza por **GO** (barato, en equipo); pasa a
  **PRO/MAESTRO** cuando el sistema sea grande o el dato sensible.

### 3.3 Seudonimización, anonimización y la mentira habitual

- **Seudonimizado sigue siendo dato personal.** Todas las obligaciones aplican. Reduce riesgo, no
  alcance.
- **Anonimización es irreversible y se evalúa contra el contexto**, incluida la información adicional
  de la que dispone quien trata el dato y la que es razonablemente accesible. Casi todo lo que en la
  industria se llama "anonimizado" no lo está: quitar el nombre no anonimiza nada cuando quedan
  código postal + fecha de nacimiento + sexo, o una traza de geolocalización, o un patrón de compra.
- **k-anonimato**: garantiza que cada registro es indistinguible de otros k-1 **en los cuasi
  identificadores que declaraste**. Falla por: alta dimensionalidad (con decenas de atributos, k
  útil es inalcanzable), ataques de homogeneidad (todos los del grupo comparten el atributo
  sensible → **l-diversidad**), asimetría de distribución (**t-cercanía**) y conocimiento auxiliar
  externo, que no puedes acotar. Úsalo como suelo publicable, nunca como prueba de anonimato.
- **Privacidad diferencial** es lo único con garantía formal: acota cuánto puede aprender un
  observador sobre un individuo concreto, **independientemente de lo que ya sepa**. Coste real:
  ruido, y por tanto pérdida de utilidad en consultas de baja frecuencia y colas — asúmelo antes de
  prometer un dashboard. Exige **contabilidad del presupuesto ε** a lo largo de todas las consultas
  y publicaciones sobre el mismo dataset: sin contabilidad, la garantía desaparece a la tercera
  consulta.
- **Criterio de la AEPD que hay que interiorizar**: si lo que llamaste "anonimizado" permite
  reidentificar, el tratamiento es de datos personales con todas sus consecuencias — y haber
  documentado como "anónimo" lo que era seudónimo agrava, porque contradice la responsabilidad
  proactiva. La guía **"Orientaciones y garantías en los procedimientos de anonimización"** exige
  además **separación de entornos y de roles**: quien trabaja con el conjunto anonimizado no accede
  ni a los datos originales ni a las claves de anonimización.

### 3.4 Técnicas: cuándo cada una

| Técnica | Se usa para | Límite que hay que decir en voz alta |
|---|---|---|
| **Tokenización** | Sacar el dato sensible del sistema que lo usa (pagos, DNI) dejando un token sin valor | La bóveda concentra todo el riesgo; su compromiso es el incidente máximo |
| **Cifrado por sujeto de datos** | Habilitar **crypto-shredding** y compartimentar el radio de explosión | Complica consultas y joins: decide **al diseñar** qué campos se cifran y cuáles quedan en claro para consultar |
| **Enmascarado** (estático/dinámico) | Reducir exposición en soporte, BI y accesos operativos | El enmascarado **dinámico** no protege del `pg_dump`; el estático solo sirve si el origen nunca sale |
| **Datos sintéticos** | Preproducción, demos, pruebas de carga y de rendimiento | Un generador entrenado sobre producción **puede memorizar y filtrar**: genera desde el esquema y reglas de negocio, o aplica DP al generador. Y valida que sí ejercita los casos límite |
| **Agregación / reducción de precisión** | Métricas, informes, señales de producto | Agregados sucesivos sobre el mismo dato permiten reconstruir el individuo (ataques diferenciales) |
| **Privacidad diferencial** | Publicación de estadísticas y entrenamiento con garantía | Utilidad reducida; presupuesto que se agota |

### 3.5 Derechos del interesado como funcionalidad

Son **endpoints y jobs con SLA**, no un buzón de correo con una persona buscando a mano. Diseño
mínimo:

- **Acceso y portabilidad**: exportación completa por sujeto, en formato estructurado y de uso común,
  generada **desde el catálogo** (§3.1) — si un almacén no aparece en `destinos`, no se exporta y
  la respuesta es incompleta. Entrega por canal autenticado, con caducidad del enlace, sin adjuntar
  el volcado a un correo.
- **Rectificación**: propagable. Un dato corregido en la BD y no en el índice de búsqueda, la caché,
  el CRM y el proveedor de email es un dato incorrecto que sigue vivo en cuatro sitios.
- **Supresión**: es el derecho que revela si el sistema estaba bien diseñado. Alcance **completo y
  demostrable**:
  1. **Almacén primario**: borrado real. *Soft delete* eterno **no es supresión**.
  2. **Réplicas y standbys**: se propaga solo; verifícalo, no lo supongas.
  3. **Cachés y sesiones**: invalidación explícita, no esperar al TTL.
  4. **Índices de búsqueda** (OpenSearch/Elastic/vectoriales): borrado explícito; los índices
     vectoriales y los embeddings **también** son dato derivado del sujeto.
  5. **Colas y logs de eventos**: tombstone + compactación donde exista; donde no, crypto-shredding.
  6. **Data lake / warehouse**: incluye *time travel*, snapshots y versiones de tabla (Delta,
     Iceberg, BigQuery, Snowflake). Reduce la ventana **antes** de borrar o documenta el residuo.
  7. **Logs y telemetría**: si contienen PII, el problema es anterior (§5); mientras exista, entran
     en el alcance.
  8. **Encargados y terceros**: procedimiento de borrado contractual **con verificación**, no un
     correo pidiéndolo. Registra la fecha y la confirmación.
  9. **Modelos de IA entrenados con el dato**: ver §5.
  10. **Backups**: ver más abajo.
- **La respuesta honesta y defendible sobre los backups.** Borrar un registro concreto dentro de un
  backup íntegro o inmutable es, en general, **imposible sin destruir el backup**, y destruirlo pone
  en riesgo la continuidad — que también es una obligación. Lo defendible es, en este orden:
  1. **Diseñar para no necesitarlo**: cifrado por sujeto desde el principio, de modo que la
     destrucción de la clave alcance también a lo restaurado. Esta es la única solución completa, y
     es una decisión de arquitectura del día 1: retrofit es carísimo.
  2. **Acotar y documentar la ventana**: la retención del backup es finita, conocida, publicada al
     interesado y **realmente aplicada** (la política de retención e inmutabilidad la fija
     `bcdr-standards`). El residuo se extingue solo al vencer la ventana.
  3. **Poner el dato fuera de uso**: el backup no se usa para nada que no sea recuperación ante
     desastre, con acceso restringido y auditado.
  4. **Reaplicar la supresión tras cualquier restauración**: la lista de supresiones pendientes es un
     artefacto operativo (registro de *tombstones* con marca temporal) que se replica **fuera** del
     sistema respaldado, y el runbook de restauración incluye reprocesarla como paso obligatorio y
     verificado. Un restore que resucita datos borrados es una brecha nueva.
  5. **Decirlo**: informar al interesado del plazo real de extinción. Prometer un borrado inmediato
     que no ocurre es peor que explicar la ventana.
  - **Verifica el estado del reconocimiento regulatorio del crypto-shredding** como forma de
    supresión antes de apoyarte solo en él: las fuentes se contradicen (§8). El control técnico es
    sólido; su calificación jurídica la fija legal/DPO.
- **Toda operación de derechos deja evidencia**: quién la pidió, cómo se verificó su identidad, qué
  almacenes se tocaron, qué se ejecutó, cuándo y con qué resultado — **sin volver a crear PII
  innecesaria** en el propio registro de evidencia.

### 3.6 Consentimiento y DPIA

**Consentimiento** = estado versionado y auditable, no un banner:
`sujeto · propósito · granularidad (uno por propósito, sin paquetes) · versión del texto exacto
mostrado · marca temporal · prueba de la acción · canal · estado (otorgado/retirado) · histórico
completo`. Retirar debe ser **tan fácil como dar**, con efecto propagado a todos los consumidores
(no basta con dejar de mostrar el banner). Y la regla que más se incumple: **el sistema no debe
poder tratar el dato para un propósito sin consentimiento vigente** — se comprueba en el código,
no en una reunión.

**DPIA/EIPD como artefacto de ingeniería**, disparada por criterios técnicos escritos y evaluada
**antes** de construir. Disparadores mínimos: tratamiento a gran escala de categorías especiales;
observación sistemática de zonas accesibles al público o de comportamiento; elaboración de perfiles
con efecto jurídico o significativo; decisiones automatizadas; datos de menores o de personas
vulnerables; combinación de conjuntos de datos de orígenes distintos; uso de tecnología nueva
(incluida IA) sobre datos personales; transferencia fuera del EEE de datos sensibles. **Consulta
además la lista de tratamientos que la autoridad de control publica** (§8): en España la AEPD tiene
lista propia. La DPIA se **revisa** cuando cambia el tratamiento — no es un PDF de una sola vez.

## 4. Gates de calidad (rompen el build)

En orden de coste creciente. Los cuatro primeros son automáticos:

1. **Esquema anotado**: ninguna migración que añada o cambie un campo se mergea sin `clase`,
   `proposito` y `retencion` en el catálogo (§3.1). Es un *linter* de 40 líneas y evita el 80 % del
   problema.
2. **Detección de PII en código y en datos**: Presidio (u otro detector) sobre (a) el diff, buscando
   PII literal, datos de prueba reales y volcados; (b) muestras de logs y de eventos en staging; (c)
   columnas nuevas, comparando el contenido real con la clase declarada. Un campo declarado
   `interno` con emails dentro es un hallazgo que rompe el build. **La detección automática es una
   red, no una garantía**: no sustituye a la anotación explícita.
3. **Test de "el borrado borra de verdad"**, en todos los almacenes: crea un sujeto sintético,
   propágalo por el sistema completo (BD, réplica, caché, índice, topic, lake, export a terceros en
   *sandbox*), ejecuta la supresión y **busca el identificador en cada almacén**. Falla si aparece en
   alguno. Es el test que ninguna organización tiene y el único que demuestra el derecho. Extensión
   obligatoria: repetir la búsqueda **después de un restore de prueba** (coordinado con
   `bcdr-standards`) para verificar que se reaplican las supresiones.
4. **Preproducción sin datos reales**: escáner programado sobre entornos no productivos que busca
   patrones de PII y **cualquier identificador que exista en producción**. Un acierto es incidente,
   no aviso. Complementario: prohibición técnica (no solo de proceso) de los caminos que copian
   producción hacia abajo — sin credenciales de lectura de prod en el pipeline de refresco de pre.
5. **Test de retención**: comprobar que el job de borrado por retención se ejecutó y **cuántas filas
   borró**. Un job que corre con éxito y borra 0 filas eternamente es un job roto. Alerta por
   ausencia de ejecución y por antigüedad máxima del registro más viejo por tabla.
6. **Test de propósito**: un consumidor sin propósito declarado compatible no obtiene el campo.
   Contrato verificado en CI, no confianza.
7. **Test de consentimiento**: el tratamiento sujeto a consentimiento falla (cierra, no continúa) si
   no hay consentimiento vigente; la retirada se propaga y se verifica.
8. **Revisión de privacidad en el diseño**: LINDDUN aplicado y sus amenazas con mitigación, aceptación
   documentada o "no aplica" razonado. Sin esto, el PR de un flujo de datos nuevo no se aprueba.

## 5. Frentes específicos

### PII en telemetría y logs — donde más se filtra

Es el punto de fuga número uno, siempre por accidente: `log.debug(request)`, una excepción con el
cuerpo entero, una URL con el email en el *query string*, un `user_id` que es el correo, una etiqueta
de métrica con el identificador (que además revienta la cardinalidad), un *breadcrumb* de APM, una
sesión grabada de front-end.

- **Redacción en el borde, no en el destino**: se filtra antes de salir del proceso; confiar en la
  redacción del backend de logs deja la PII en tránsito y en cualquier réplica intermedia.
- **Lista de permitidos, no de prohibidos**: se registran los campos declarados; lo demás se descarta.
  La lista negra siempre llega tarde al campo nuevo.
- Identificadores **opacos** en logs y trazas (nunca email, teléfono o DNI como clave de correlación).
- **Retención del log = retención del dato que contiene.** Un log con PII a 400 días es un almacén de
  PII a 400 días, y entra en el alcance de la supresión (§3.5).
- Grabación de sesión y mapas de calor: consentimiento previo, enmascarado de campos por defecto y
  exclusión total de formularios sensibles. Detalle del pipeline en `observability-standards`.

### Transferencias internacionales (estado ago-2026, **verifícalo**)

- La **decisión de adecuación del EU-US Data Privacy Framework sigue en vigor**. El Tribunal General
  desestimó el recurso Latombe (T-553/23) el **3-sep-2025**; hay **recurso de casación pendiente
  ante el TJUE (C-703/25 P)**. Además, la sentencia del Tribunal Supremo de EE. UU. en *Trump v.
  Slaughter* (**29-jun-2026**), que eliminó la protección frente a la destitución de los comisarios
  de la FTC, ha reabierto el debate sobre la independencia del supervisor que hace cumplir el marco,
  con petición formal de noyb a la Comisión para retirarlo, y la PCLOB continúa incapacitada para
  las revisiones que el propio EO 14086 exige.
- **Criterio de ingeniería, no jurídico**: el marco ha caído dos veces (Safe Harbor, Privacy Shield)
  y está recurrido por tercera. **Diseña para que su caída sea un cambio de configuración, no un
  rediseño**: región conocida y declarada por dataset, capacidad probada de mover el tratamiento a
  una región del EEE, cifrado con claves bajo control propio (y no accesibles al proveedor), y
  registro de subencargados con su localización. Que un proveedor esté certificado no exime de saber
  **dónde está tu dato y quién puede acceder a él**.
- Lo que decide legal/DPO: la base de transferencia aplicable (adecuación, SCC, BCR, excepciones) y
  la evaluación de impacto de la transferencia. Ingeniería aporta el mapa técnico real.

### Datos personales y sistemas de IA

- **Entrenar con datos personales es un tratamiento** y necesita base de licitud propia; la base del
  servicio original **no se extiende** al entrenamiento por defecto. Estado ago-2026: la propuesta de
  *Digital Omnibus* que introduciría un interés legítimo explícito para el desarrollo de IA (nuevo
  art. 88c) y que estrecharía la definición de dato personal seudonimizado **sigue siendo propuesta,
  no derecho vigente**, con oposición expresa del EDPB y el EDPS (Opinión conjunta 2/2026,
  10-feb-2026). **No diseñes asumiendo que se aprobará.**
- **Un modelo no es anónimo por serlo**: el EDPB (Opinión 28/2024, 17-dic-2024) fija que la anonimia
  de un modelo debe demostrarse caso a caso y que el umbral es alto — la probabilidad de extraer
  datos personales, directamente o mediante consultas, debe ser insignificante para **cada**
  interesado. Consecuencia práctica: la memorización y la extracción son riesgos de privacidad que se
  **prueban** (ataques de inferencia de pertenencia y de extracción antes de publicar el modelo), no
  se asumen resueltos.
- **Supresión y modelos**: reentrenar puede ser desproporcionado, y el *machine unlearning* no es una
  técnica madura. Vías defendibles: entrenar con DP desde el principio, excluir el dato del siguiente
  ciclo de entrenamiento con procedimiento verificable, filtrar en la salida, y **documentar la
  limitación con honestidad**. Prometer un borrado del modelo que no puedes ejecutar es peor que
  explicar el límite.
- **Prompts, RAG y logs de inferencia son almacenes de datos personales**: entran en el catálogo, en
  la retención y en el alcance de la supresión. Un índice vectorial construido sobre documentos con
  PII es un almacén de PII.
- **AI Act — calendario efectivo verificado a ago-2026** (tras el *Digital Omnibus* sobre IA, adoptado
  por el Parlamento el 16-jun-2026 y el Consejo el 29-jun-2026, en vigor en julio de 2026):
  **2-ago-2026** aplican las obligaciones de transparencia del art. 50 (con excepción del art. 50(2)
  para sistemas ya en el mercado en esa fecha); **2-dic-2026**, el art. 50(2) (marcado/marca de agua)
  para los sistemas heredados y las nuevas prácticas prohibidas añadidas; **2-dic-2027**, las
  obligaciones de alto riesgo del Anexo III (autónomos); **2-ago-2028**, las del Anexo I
  (integrados). **El aplazamiento de alto riesgo no cambia el RGPD**: las obligaciones de privacidad
  siguen aplicando hoy, íntegras, con AI Act o sin él. **Hueco declarado**: las fechas de las
  obligaciones ya aplicables antes de 2026 (prohibiciones, alfabetización en IA, GPAI) no se han
  contrastado en esta revisión (§8).

### Brecha de datos personales

El proceso, los roles y los plazos son de `incident-management-standards` e
`incident-response-forensics-standards`; **el criterio de notificar es de legal/DPO**. Lo que esta
skill exige es que ingeniería pueda responder **en horas, no en semanas**:

- **Qué categorías de datos** estaban en el sistema afectado → sale del catálogo (§3.1). Sin
  catálogo, la respuesta es "no lo sabemos", que es la peor de todas.
- **Cuántos interesados aproximadamente**, y de qué colectivos (menores, pacientes, empleados).
- **Si el dato era legible**: cifrado con clave no comprometida cambia radicalmente la evaluación de
  riesgo para el interesado — y por tanto la obligación de comunicar a los afectados. Esto se decide
  el día que se diseña el cifrado, no el día de la brecha.
- **Qué puede hacer un atacante con ello**: la evaluación es de riesgo **para la persona**
  (suplantación, discriminación, daño físico, pérdida financiera), no para la empresa.
- **Documentar toda brecha**, se notifique o no. La AEPD publica guía y herramienta de evaluación:
  úsalas como referencia, verificando su vigencia (§8).

## 6. Operabilidad

- **SLA interno de derechos**: mide el tiempo desde la solicitud hasta la ejecución completa, con
  objetivo **muy por debajo** del plazo legal (que se verifica en §8) — el plazo legal es el límite,
  no el objetivo. Alerta por solicitudes próximas a vencer.
- **Métricas que importan**: nº de campos de datos personales por servicio (**objetivo: que baje**);
  % de campos con retención automatizada y ejecutada; antigüedad del registro más viejo por tabla
  frente a su retención declarada; solicitudes de derechos por tipo y tiempo de servicio; hallazgos
  de PII en logs y en preproducción; accesos a datos sensibles por persona y su revisión; presupuesto
  ε consumido por dataset publicado.
- **Coste como argumento**: cada campo personal cuesta cifrado, retención, borrado, auditoría, riesgo
  de brecha y trabajo de derechos. Minimizar es la optimización más rentable del sistema y el único
  argumento que suele convencer a quien pide "guárdalo por si acaso".
- **Revisión de accesos** a datos sensibles con cadencia y con consecuencia; exportaciones masivas
  con aprobación y traza (control de exfiltración).
- **Purga como operación de primera clase**: el job de retención tiene dueño, runbook, alerta y
  métrica, igual que un backup. Y como cualquier operación destructiva, se prueba en un entorno con
  datos representativos antes de soltarla sobre producción.

## 7. Sostenibilidad y prohibiciones

**Cadencia**: catálogo de datos revisado trimestralmente (campos nuevos, destinos nuevos,
proveedores nuevos); DPIA revisada ante cualquier cambio material del tratamiento; **radar
regulatorio trimestral** —este dominio se mueve por trimestres y la §8 es lo que impide afirmar algo
caducado—; revisión anual de los textos de consentimiento y de la política de privacidad frente a
lo que el sistema hace **de verdad**.

**Deuda de privacidad**: cada excepción (un campo que no se puede borrar, un almacén sin cobertura
de supresión, un tercero sin procedimiento verificado) se registra con dueño, riesgo y **fecha de
caducidad**. Sin fecha, es una decisión de arquitectura no documentada.

**PROHIBIDO**
- ❌ Copiar datos de producción a desarrollo, QA o demo. Sin excepciones "temporales".
- ❌ Llamar "anonimizado" a un conjunto seudonimizado, en el código, en la DPIA o en un contrato.
- ❌ Publicar o compartir datos "anonimizados" sin evaluación documentada de reidentificación.
- ❌ Recoger un campo "por si acaso", o guardar más precisión de la que se necesita.
- ❌ Retención escrita en una política y no implementada como borrado automático verificado.
- ❌ *Soft delete* eterno como respuesta al derecho de supresión.
- ❌ Supresión que no alcanza a réplicas, cachés, índices, colas, lake, logs y encargados.
- ❌ Restaurar un backup sin reaplicar las supresiones pendientes.
- ❌ Prometer al interesado un borrado inmediato que la arquitectura no puede ejecutar.
- ❌ PII en logs, trazas, métricas, mensajes de error, URLs o claves de caché.
- ❌ Identificadores personales (email, teléfono, DNI) como clave de correlación o como `user_id`.
- ❌ Consentimiento como booleano sin versión, sin texto y sin histórico; consentimientos agrupados;
  retirada más difícil que la concesión.
- ❌ Tratar un dato para un propósito distinto del declarado porque "ya lo tenemos".
- ❌ Entrenar modelos con datos personales sin base de licitud propia y sin evaluación de memorización.
- ❌ Asumir que un modelo entrenado con datos personales es anónimo.
- ❌ Categorías especiales en el mismo esquema, evento o índice que el dato ordinario.
- ❌ DPIA escrita después de construir el sistema, o nunca revisada.
- ❌ Apoyar todo el diseño en una decisión de adecuación concreta sin capacidad probada de cambiar de
  región o de proveedor.
- ❌ Aplicar privacidad diferencial sin contabilidad de presupuesto ε.
- ❌ Introducir `smartnoise-core` (deprecado) o imágenes de Presidio desde `mcr.microsoft.com` (ya no
  se actualizan) en nada nuevo.
- ❌ Fiarse solo de un detector automático de PII como control de cumplimiento.
- ❌ Fijar plazos legales, nombres de norma o estado regulatorio **de memoria** (§8).

## 8. Verificación web obligatoria

Antes de fijar cualquier norma, plazo, versión o estado, **búscalo — no lo recuerdes**. Aquí
inventar es el peor error posible:

1. **EU-US Data Privacy Framework**: si la decisión de adecuación sigue en vigor; estado del recurso
   **C-703/25 P** ante el TJUE; consecuencias de *Trump v. Slaughter* (29-jun-2026) sobre la
   independencia de la FTC y sobre la posición de la Comisión y del EDPB; estado de la PCLOB. Es el
   dato que más se cita de memoria y más probable de estar caducado.
2. **AI Act**: calendario efectivo tras el *Digital Omnibus* sobre IA (adoptado jun-2026, en vigor
   jul-2026). Verificado: 2-ago-2026 art. 50; 2-dic-2026 art. 50(2) heredados + nuevas prohibiciones;
   2-dic-2027 alto riesgo Anexo III; 2-ago-2028 Anexo I. **Hueco declarado**: no se han contrastado
   las fechas de las obligaciones anteriores a 2026 (prácticas prohibidas iniciales, alfabetización
   en IA, GPAI).
3. **Digital Omnibus — pista RGPD/ePrivacy**: a ago-2026 seguía en **fase de propuesta** (definición
   de dato personal seudonimizado, art. 88c de interés legítimo para IA, tratamiento de categorías
   especiales para detección de sesgos), con oposición del EDPB/EDPS (Opinión conjunta 2/2026).
   **Verifica si se ha adoptado y en qué términos antes de basar un diseño en ello.**
4. **NIST Privacy Framework**: si la **v1.1** final ya se publicó (a ago-2026 no estaba confirmada;
   IPD abr-2025, sección nueva 1.2.2 sobre IA y privacidad, alineación con CSF 2.0). Cita la edición
   verificada.
5. **LINDDUN**: variantes vigentes (GO/PRO/MAESTRO) y el desglose actual del acrónimo en
   `linddun.org`. **Hueco declarado**: el sitio no publica numeración de versión; hay una revisión
   "Enhanced LINDDUN GO" de las cartas sin fecha localizada.
6. **EDPB**: estado **final** de las *Guidelines 01/2025 on Pseudonymisation* (adoptadas para
   consulta el 16-ene-2025; **no confirmada la versión final** a ago-2026) y de la sentencia del
   TJUE en **C-413/23 P** (*EDPS v SRB*), cuya conclusión sobre datos seudonimizados en manos de un
   tercero puede alterar el criterio. Opinión 28/2024 sobre modelos de IA, y cualquier directriz
   nueva sobre anonimización, *scraping* o borrado.
7. **Crypto-shredding**: **hueco declarado y conflicto de fuentes** — no se ha podido confirmar si el
   EDPB (Directrices 5/2019 sobre el derecho al olvido) reconoce expresamente el borrado
   criptográfico como supresión del art. 17, ni la posición actual de la AEPD. Verifícalo contra
   fuente primaria antes de apoyarte solo en él.
8. **AEPD**: vigencia de la guía *"Orientaciones y garantías en los procedimientos de anonimización"*
   y de la *Guía básica de anonimización*; guía y herramienta de evaluación de **brechas de datos
   personales** y su canal de notificación; **lista de tratamientos que requieren DPIA**; criterio
   sobre datos reales en entornos de prueba. **Hueco declarado**: no se ha verificado si existe
   edición posterior de esas guías ni el plazo exacto de respuesta a derechos vigente — no lo cites
   de memoria.
9. **Plazos**: notificación de brecha (RGPD art. 33/34) y respuesta a derechos — contrástalos con las
   skills de incidente y con la fuente primaria; el criterio legal es de legal/DPO.
10. **Herramientas** antes de recomendarlas: **Presidio** (proyecto comunitario *Data Privacy Stack*,
    2.2.363 de jun-2026, `presidio-analyzer` en PyPI jul-2026, imágenes en
    `ghcr.io/data-privacy-stack`), **OpenDP Library** y **SmartNoise SDK** (`smartnoise-core`
    deprecado), **Tumult Analytics**, **Google DP**. **Hueco declarado**: no se ha confirmado la
    versión actual ni la cadencia de la librería OpenDP — verifícala antes de fijarla. Comprueba
    también licencia y cualquier **incidente de cadena de suministro** reciente (precedente del
    catálogo: Trivy retirado como default tras el compromiso de marzo de 2026).

Si no puedes verificar, **dilo explícitamente en vez de suponer**.
Si la web contradice este documento, **manda la web** y señala la discrepancia.
