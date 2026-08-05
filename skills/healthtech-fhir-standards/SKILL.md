---
name: healthtech-fhir-standards
description: Clinical interoperability and health software engineering. Use when working with HL7 FHIR (R4 4.0.1, R5 5.0.0, R6 ballot), FHIR resources such as Patient, Encounter, Observation, Condition, MedicationRequest, DiagnosticReport, DocumentReference, Consent, AuditEvent and Provenance, StructureDefinition profiles and extensions, ImplementationGuide packages and the IG Publisher, hl7.fhir.us.core, hl7.fhir.uv.ips, hl7.fhir.uv.smart-app-launch, CapabilityStatement and $validate, Bundle transaction/batch/document, FHIR search parameters, _include, _revinclude, chained search and $everything, Bulk Data $export and NDJSON, FHIR Subscriptions and topic-based subscriptions, SMART on FHIR launch and scopes (patient/*.rs, user/*.rs, system/*.rs), HL7 v2.x pipe-and-hat messages (ADT, ORM, ORU, MSH/PID/OBX segments), MLLP interfaces and integration engines (Mirth/NextGen Connect, Rhapsody, Iguana, InterSystems Ensemble/HealthShare), CDA and C-CDA documents, IHE profiles (XDS.b, PIX/PDQ, ATNA, MHD), DICOM, DICOMweb, PACS, modality worklist and HL7-to-DICOM mapping, terminology servers and CodeSystem/ValueSet/ConceptMap with SNOMED CT, LOINC, ICD-10/ICD-11, CIE-10-ES, RxNorm or ATC, the International Patient Summary and MyHealth@EU, the European Health Data Space Regulation (EU) 2025/327, MDR/IVDR Rule 11 classification of software as a medical device, or clinical access auditing and patient consent as product requirements.
---

# Estándares de software sanitario e interoperabilidad clínica (FHIR)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando el sistema **maneja dato clínico de una persona identificable** y tiene que
intercambiarlo con otro sistema, con otro hospital, con otro país o con el propio paciente.

**Tesis del dominio, y ordena todo el documento: interoperabilidad no es transporte, es
significado.** Mover un JSON de A a B es lo fácil y no resuelve nada. El problema es que un valor
de laboratorio **sin** su código LOINC, su unidad UCUM, su rango de referencia, su método, su
fecha, su estado (`preliminary`/`final`/`corrected`/`entered-in-error`) y su sujeto **no es un
dato clínico: es un número peligroso**. Corolario que cambia decisiones de diseño:

- **Un campo de texto libre no es interoperable.** Si el receptor tiene que leerlo para actuar, no
  se ha interoperado, se ha enviado correo.
- **El estado del documento es parte del dato.** Un resultado corregido que llega sin anular el
  anterior es un error clínico, no un bug de sincronización.
- **La identidad del paciente es el problema difícil, no el fácil.** El *matching* de pacientes
  entre sistemas es donde se producen los daños graves (dato del paciente equivocado). Nunca se
  resuelve con "el nombre y la fecha de nacimiento" (§3.5).

Segunda tesis, incómoda y necesaria: **el software sanitario no es una app con base de datos, es
infraestructura crítica bajo dos regímenes regulatorios simultáneos** — protección de datos
(categoría especial del art. 9 del RGPD, §5.4) y, si tiene finalidad médica, producto sanitario
(MDR/IVDR, §7.1). Ninguno de los dos se resuelve al final del proyecto.

Cubre: elección de versión y perfiles de FHIR; modelado con recursos, perfiles, extensiones y guías
de implementación; REST, búsqueda, `Bundle` y transacciones; terminologías y su licencia; HL7 v2 y
CDA como realidad instalada; DICOM para imagen; SMART on FHIR y consentimiento; auditoría de acceso;
y el eje regulatorio europeo (EHDS, MDR/IVDR) en lo que decide arquitectura.

**No aplica**:
- `mumps-standards` (**frontera recíproca, ya declarada por esa skill**): **el núcleo M/globals, su
  lenguaje, su plataforma (IRIS/Caché, YottaDB/GT.M), VistA, FileMan, Epic Chronicles y la decisión
  de migrar, encapsular o congelar son suyos**. **De aquí, todo el criterio de interoperabilidad
  clínica** —recursos, perfiles, terminologías, conformidad, el detalle de HL7 v2 e IHE—, incluida
  **la fachada FHIR/HL7 v2 que esa skill exige como única vía de salida del dato clínico**. Regla de
  arbitraje: *"¿cómo está guardado y quién lo escribe?" es suyo; "¿con qué contrato sale y qué
  significa lo que sale?" es de aquí*.
- `safety-critical-standards` (**hermana, frontera declarada en ambos lados**): **suyo el proceso de
  seguridad funcional del producto sanitario una vez clasificado** — ciclo de vida **IEC 62304** y
  sus clases A/B/C, gestión de riesgo **ISO 14971**, trazabilidad requisito→código→test, cobertura
  estructural, cualificación de herramientas y evidencia para el organismo notificado. **De aquí:
  si el software *es* producto sanitario** (regla 11 de MDR, §7.1) y el diseño de la información
  clínica que maneja. Regla de arbitraje: *"¿esto es producto sanitario y qué dato clínico
  intercambia?" es de aquí; "¿qué evidencia de proceso hay que producir para certificarlo?" es suya*.
- `privacy-engineering-standards`: **suyo el RGPD como ingeniería** — minimización, base de licitud,
  retención y borrado, derechos del interesado, DPIA/EIPD, seudonimización y anonimización, PII en
  telemetría. **De aquí solo lo específicamente clínico**: por qué el dato de salud es categoría
  especial (§5.4), por qué la seudonimización de una historia clínica es más frágil de lo que
  parece, y la auditoría de acceso como requisito funcional (§5.5).
- `grc-compliance-standards`: marco de gestión, ISO 27001, ENS, NIS2, SoA y evidencia de auditoría.
- `identity-access-management-standards`: **el IdP, OAuth 2.1/OIDC, passkeys, SCIM y los motores de
  autorización son suyos**. De aquí solo **SMART on FHIR** como perfil de OAuth2 específico del
  dominio, con sus *scopes* y su contexto de lanzamiento (§5.1).
- `api-design-standards`: REST general, versionado, RFC 9457, idempotencia, paginación como
  patrones. **De aquí lo que FHIR ya decide y no se renegocia** (§3.3): FHIR **es** un contrato
  publicado, y "mejorarlo" con convenciones propias rompe la interoperabilidad, que es el único
  motivo de usarlo.
- `data-governance-quality-standards`: propiedad del dato, glosario, contratos de datos y calidad
  como programa. De aquí, el **significado clínico codificado**, que es otra cosa.
- `ai-governance-standards`: **AI Act, clasificación de riesgo del sistema de IA, roles
  proveedor/desplegador, supervisión humana y art. 73**. De aquí, la interacción: un software
  sanitario con IA suele acumular **ambos** regímenes (§7.3).
- `accessibility-standards` (portal del paciente: criterio WCAG y su prueba),
  `cryptography-pki-standards` (algoritmos, TLS, claves), `appsec-standards` (modelado de amenazas
  y clases de vulnerabilidad), `data-platform-standards` y `object-storage-standards` (el motor y
  el almacén), `observability-standards`, `bcdr-standards` y `backup-recovery-standards` (un
  hospital no tiene ventana de parada), `legacy-modernization-standards` y
  `migration-projects-standards` (la cartera y el corte), `i18n-standards`,
  `offensive-security-standards` (**esta skill es defensiva**).

## 2. Decisiones por defecto

> Verificar la última versión y su estado por web antes de fijarla en un proyecto real (§8).

| Decisión | Elección | Verificado a ago-2026 |
|---|---|---|
| **Versión de FHIR** | **R4 (4.0.1)** salvo motivo explícito | **Dato que decide y casi nadie comprueba**: la página de historial de `hl7.org/fhir` describe R4 (2018-12-27) como *"First Normative Content + Trial Use Developments"*, y de **R5 (5.0.0, 2023-03-26)** dice verbatim: *"This 5th Major release of the FHIR specification is labeled as 'trial-use'... None of the content in this specification is considered Normative."* **R4 sigue siendo la base normativa y la que soportan los sistemas reales** |
| **R5** | Solo si necesitas un recurso que no existe en R4 y controlas ambos extremos | Trial-use. Adopción real escasa en productos instalados |
| **R6** | **No** en producción | En **ballot**: la build de `build.fhir.org` se identifica como **v6.0.0-ballot4** y declara *"This is the first full normative version of the standard - none of the content in this specification is considered trial-use"*, con la intención de *"move most of the resources in the Foundation, Base and Clinical layers to full Normative status"*. **Es la versión que importa a medio plazo, y aún no está publicada** |
| **R4B (4.3.0)** | Evitar salvo requisito concreto | 2022-05-28, *"Staging release of modifications in specific areas"* |
| **Perfil base** | **La IG nacional/regional aplicable si existe; si no, IPS** | **IPS (International Patient Summary): `hl7.fhir.uv.ips#2.0.1`, sobre FHIR 4.0.1** (HL7 International / Patient Care). Alineada con **ISO 27269** y con el escenario de asistencia transfronteriza no planificada |
| **EE. UU.** | `hl7.fhir.us.core` | **v9.0.0, package `hl7.fhir.us.core#9.0.0`, sobre FHIR 4.0.1, publicada 2026-05-31**; anclada a **USCDI** y a la certificación ONC/ASTP |
| **España** | **Verificar caso por caso: no hay una IG nacional única equivalente a US Core** | Existe IG del Ministerio de Sanidad para dominios concretos (p. ej. **ÚNICAS**, `unicas-fhir.sanidad.gob.es`, v0.0.6, sobre **R5**, alineada con **MyHealth@EU NCPeH** y con IPS). **Hueco declarado (§8): no se ha localizado una guía FHIR general del HCDSNS.** No inventes su existencia en un pliego |
| **Autorización de apps clínicas** | **SMART App Launch** | `hl7.fhir.uv.smart-app-launch#2.2.0`, **STU 2.2, activa desde 2023-03-01**. Patrones *"based on OAuth 2.0"*; **la sintaxis de scopes cambió respecto de SMARTv1** — verbatim de la guía: *"The scope syntax has changed since SMARTv1"* |
| **Mensajería instalada** | **HL7 v2.x sobre MLLP** — no se sustituye, se envuelve | §2.1 |
| **Documentos** | **CDA / C-CDA** donde ya exista; **FHIR Document** en nuevo | El documento clínico firmado sigue siendo un requisito legal en muchos flujos |
| **Imagen** | **DICOM** y **DICOMweb** (WADO-RS/QIDO-RS/STOW-RS) | El estándar DICOM se publica **gratis** en `dicom.nema.org`: úsalo verbatim, no hay excusa |
| **Terminología clínica** | **SNOMED CT** para hallazgos, procedimientos y diagnósticos | Licencia: §2.2 |
| **Laboratorio y observaciones** | **LOINC** (qué se midió) + **UCUM** (unidad) | LOINC es gratuito con registro |
| **Codificación de diagnóstico administrativo** | **ICD-10 / CIE-10-ES** en España; **ICD-11** donde la autoridad ya lo exija | **No son intercambiables con SNOMED CT**: distinto propósito (estadística/facturación vs. registro clínico) |
| **Servidor de terminología** | Servicio dedicado con `$lookup`, `$validate-code`, `$expand`, `$translate` | Una tabla de códigos copiada en tu base de datos **caduca**, y con ella la validez del dato |

### 2.1 HL7 v2 sigue vivo, y esto no es nostalgia

**La mayor parte del tráfico clínico real que circula hoy dentro de un hospital son mensajes HL7
v2.x** —ADT de admisión/alta/traslado, ORM de petición, ORU de resultado— sobre MLLP, movidos por
un motor de integración (Mirth/NextGen Connect, Rhapsody, Iguana, Ensemble/HealthShare). **Ningún
proyecto FHIR serio empieza sin asumirlo**, y quien planifica "migrar todo a FHIR" está planificando
un proyecto que no termina. *(Cuantificación: no se ha localizado una fuente con metodología para
dar un porcentaje. Se afirma la predominancia cualitativamente, no con cifra — §8.)*

Criterio operativo:
- **FHIR es la fachada, v2 es el bus.** El destino de toda integración **nueva** es FHIR; el
  interfaz interno con el HIS/LIS/RIS existente sigue siendo v2 durante años, y eso es correcto.
- **La traducción v2 → FHIR no es mecánica**: v2 tiene semántica dependiente del *site* (los
  segmentos `Z`, las tablas locales, el uso creativo de `OBX`). Cada interfaz v2 es un contrato
  bilateral no documentado. **Presupuesta descubrimiento, no conversión.**
- **`OBX-5` sin `OBX-6` (unidad) o sin `OBX-3` codificado es dato inutilizable**: en la traducción
  se detecta ahí, no en producción.

### 2.2 SNOMED CT y su licencia — el dato que decide y casi nadie verifica

**Verificado verbatim en `snomed.org`:** *"SNOMED International does not charge for use of SNOMED CT
in SNOMED International Member countries or territories."* Y para el resto: *"If you are using
and/or deploying SNOMED CT in a non-Member country/territory, you are required to apply for a
license through the Member Licensing & Distribution Service (MLDS) on an annual basis"*, con
*"Charges may apply for affiliate use of SNOMED CT in non-Member territories"*, calculadas según el
uso y el territorio (clasificación del Banco Mundial).

**España figura en la lista de países miembros de SNOMED International** (verificado en
`snomed.org/members`). Consecuencias que se deciden **antes** de escribir código:

- **La membresía es del territorio, no de tu empresa.** Un SaaS que da servicio desde España a un
  país **no** miembro entra en el régimen de licencia de ese país.
- Quien despliega en un país miembro **se registra en el Centro Nacional de Publicación (NRC)** de
  ese país.
- **La extensión nacional importa**: un concepto de la extensión española no existe en la edición
  internacional. Un `ValueSet` que mezcla ambas sin declarar la versión de la edición es una bomba
  de relojería en cuanto cruzas frontera.
- **Verifica el estado de membresía y las condiciones de tu territorio antes de firmar el
  contrato** (§8): el listado de miembros cambia.

## 3. Modelado y convenciones FHIR

### 3.1 Recurso, perfil, extensión, IG — en ese orden

1. **Usa el recurso estándar tal cual** siempre que quepa. La tentación de crear "nuestro modelo"
   es exactamente lo que FHIR existe para evitar.
2. **Perfila (`StructureDefinition`)** para restringir: cardinalidades, `ValueSet` obligatorios,
   *slicing* de `identifier`. Un perfil **restringe**, nunca amplía la semántica.
3. **Extiende (`Extension`)** solo cuando el dato no cabe en ningún elemento estándar, con URL
   canónica propia, definición publicada y `ValueSet` propio. **Una extensión no publicada es dato
   privado con disfraz de estándar.**
4. **Publica una IG** con el **IG Publisher** y distribúyela como **paquete NPM FHIR**
   (`org.dominio.ig#x.y.z`). Un perfil que vive en un PDF no lo valida nadie.
5. **Antes de crear nada, busca si ya existe**: en el registro de paquetes, en las IG de la
   autoridad y en las internacionales. Reinventar un perfil ya publicado es el error caro típico.

### 3.2 Identificadores — donde se rompen los proyectos

- **`Patient.identifier` es una lista con sistema**, y el `system` es obligatorio y significativo:
  el número de historia del hospital A y el del hospital B **no son el mismo espacio**, aunque
  coincidan los dígitos.
- **`Resource.id` es la clave del servidor, no el identificador del negocio.** Nunca se expone como
  "número de historia" ni se reutiliza al migrar.
- **En España, el identificador que cruza sistemas es el del SNS/CIP autonómico y el DNI/NIE**;
  cuál es la autoridad de identidad de tu integración se decide y se documenta al principio, con su
  `system` canónico.
- **Un `system` inventado sobre la marcha es deuda permanente**: aparece en datos históricos para
  siempre.

### 3.3 REST de FHIR — lo que ya está decidido y no se renegocia

FHIR **ya define** la API: `GET /Patient/{id}`, `PUT` con control de concurrencia por `ETag` e
`If-Match`, historial con `/_history`, `POST` condicional con `If-None-Exist`, `OperationOutcome`
como cuerpo de error. **No se sustituye por convenciones propias** (ni RFC 9457, ni `/api/v2/`, ni
envoltorios `{data: ...}`): la única razón de usar FHIR es que el otro extremo no tenga que aprender
tu API. `api-design-standards` cede aquí explícitamente.

- **Versionado**: se hace por **versión de FHIR + versión de la IG**, no por prefijo de ruta. Un
  cliente negocia por el `CapabilityStatement`, no por documentación.
- **`CapabilityStatement` publicado y real**: es el contrato. Si declara `Observation.search` por
  `code` y no está implementado, el cliente descubre la mentira en producción.
- **Búsqueda**: parámetros estándar; `_include`/`_revinclude` para evitar N+1; **encadenada**
  (`Observation?subject.name=`) con cuidado, porque es cara; `_summary` y `_elements` para reducir
  carga. **Toda búsqueda paginada**, siempre, con los enlaces `next`/`self` del `Bundle`.
- **`Bundle`**: `searchset` para resultados; **`transaction` cuando todo debe aplicarse o nada**
  (atómico, con `fullUrl` y referencias internas resueltas); `batch` cuando cada entrada es
  independiente. **Confundir `batch` con `transaction` produce estados clínicos a medias** — un
  `MedicationRequest` sin su `Condition` es exactamente el tipo de fallo que daña.
- **Referencias**: relativas dentro del servidor (`Patient/123`), absolutas solo cuando el recurso
  vive en otro servidor y ese servidor es resoluble.

### 3.4 Estado, corrección y borrado

- **En clínica no se borra: se anula.** `status = entered-in-error` es el mecanismo; un `DELETE`
  físico destruye la trazabilidad y suele ser ilegal (obligación de conservación de la historia
  clínica). El borrado por derecho de supresión del RGPD se **evalúa** contra esa obligación legal
  de conservación: es de `privacy-engineering-standards` decidirlo, pero **el sistema tiene que
  poder distinguir "anulado" de "borrado"**.
- **`Provenance` y `meta.versionId` no son opcionales** en un sistema del que se derivan decisiones
  clínicas: quién lo escribió, desde qué sistema y cuándo.
- **Una corrección genera un recurso nuevo y anula el anterior**, y el consumidor tiene que
  enterarse (§6.2). Un resultado corregido que no se propaga es el peor fallo de esta capa.

### 3.5 Identificación del paciente

- **Nunca hagas *matching* propio con nombre + fecha de nacimiento.** El error de emparejamiento es
  un daño clínico directo (dato del paciente equivocado), y es la clase de incidente más frecuente
  en integración.
- Se usa el **servicio de identidad de la organización** (MPI, o `PIX/PDQ` de IHE, o
  `$match` de FHIR) **como fuente**, con su umbral y su cola de revisión humana para los dudosos.
- **Un emparejamiento automático sin revisión humana para los casos límite no es aceptable**; y el
  umbral se documenta como decisión clínica, no como parámetro técnico.

## 4. Conformidad, validación y pruebas

1. **Validación contra el perfil en CI**, con el validador oficial de FHIR y el paquete de tu IG.
   **Un recurso que no valida no se publica.** Es el gate más barato y el que más ahorra.
2. **Validación de terminología contra un servidor de terminología real**, no contra una lista
   embebida: `$validate-code` sobre el `ValueSet` con la versión de la edición declarada.
3. **`CapabilityStatement` generado desde el código y comparado con el declarado** — la deriva
   entre ambos es el defecto silencioso clásico.
4. **Pruebas de conformidad con el conjunto público del dominio**: Touchstone (HL7), Inferno (US
   Realm), y la batería de la autoridad si existe. Son lentas y son las que valen ante un tercero.
5. **Pruebas negativas obligatorias, y aquí no son "bordes":** unidad ausente, código desconocido,
   fecha en el futuro, `status` inesperado, referencia rota, paciente sin identificador de la
   autoridad esperada, resultado corregido que llega **antes** que el original (sí, pasa),
   duplicado por reintento. **Cada una de ellas es un daño potencial, no un 500.**
6. **Datos de prueba sintéticos, siempre.** Copiar producción a preproducción con historias clínicas
   reales es una brecha de datos de categoría especial en el momento en que se hace, no si se filtra
   (regla de `privacy-engineering-standards`, aquí sin excepción posible).
7. **Prueba de la traducción v2 ↔ FHIR con mensajes reales anonimizados de cada emisor**, no con el
   ejemplo del estándar: los `Z-segments` y las tablas locales solo aparecen ahí.

## 5. Seguridad y privacidad del dato clínico

### 5.1 SMART on FHIR

- **Apps clínicas y de paciente se autorizan con SMART App Launch** (OAuth 2.0), no con una API key
  ni con sesión compartida. Dos flujos: **EHR launch** (la app se abre desde la historia con
  contexto de paciente y encuentro) y **standalone launch** (el paciente entra directamente).
- **Scopes con el mínimo privilegio real**: `patient/Observation.rs` en vez de `patient/*.rs`, y
  `system/*` solo para *backend services*, que es el que más daño hace si se filtra. **La sintaxis
  de scopes cambió entre SMART v1 y v2** (verbatim en §2): un cliente escrito contra v1 pide
  permisos que el servidor v2 interpreta distinto.
- **El contexto de lanzamiento no es autorización.** Que la app reciba `patient=123` no significa
  que el servidor deba servir cualquier cosa de 123: **la autorización se comprueba en el servidor,
  en cada petición**. Es la variante clínica del IDOR/BOLA de `appsec-standards`, y aquí el objeto
  es la historia de una persona.
- El IdP, la política de MFA, la rotación de refresh y la revocación son de
  `identity-access-management-standards`. **La particularidad de aquí: el profesional que atiende
  una urgencia no puede quedarse fuera por un segundo factor caído** — el acceso de emergencia
  (*break-glass*) existe, es una decisión clínica, y **su uso se audita con revisión posterior
  obligatoria**, no se evita.

### 5.2 Consentimiento

- **El consentimiento es un estado consultable, no una casilla en un formulario.** Se modela
  (`Consent`), tiene vigencia, alcance (qué categorías, qué destinatarios, qué propósito) y
  revocación, y **el motor de acceso lo consulta en cada decisión**.
- **Consentimiento de tratamiento ≠ base de licitud del RGPD ≠ consentimiento para uso
  secundario.** Son tres cosas distintas que el mismo botón suele mezclar. La base de licitud la
  fija el DPO (§5.4); **el sistema tiene que poder representar las tres por separado**.
- La revocación **tiene que propagarse** a las copias, réplicas, índices y terceros. Si no puedes
  enumerarlos, no puedes cumplirla.

### 5.3 Seudonimización — y por qué es más frágil aquí

Una historia clínica es **extraordinariamente reidentificable**: una combinación de diagnóstico
raro, código postal, sexo y fecha de nacimiento identifica a una persona sin necesidad del nombre.
Consecuencias:

- **Quitar el nombre y el DNI no anonimiza nada.** Es seudonimización, y el resultado **sigue
  siendo dato personal de categoría especial** bajo el RGPD.
- Para uso secundario, la técnica y su umbral son de `privacy-engineering-standards`;
  **de aquí la advertencia dura**: cualquier afirmación de "anonimizado" sobre un conjunto clínico
  requiere análisis de riesgo de reidentificación con la cohorte real, no con la teoría.
- **Las notas en texto libre son el peor vector**: contienen nombres, relaciones familiares y
  direcciones que ningún proceso de columnas elimina.

### 5.4 El dato de salud es categoría especial — el texto que lo dice

**RGPD, art. 9.1, verbatim** (verificado): *"Processing of personal data revealing racial or ethnic
origin, political opinions, religious or philosophical beliefs, or trade union membership, and the
processing of genetic data, biometric data for the purpose of uniquely identifying a natural person,
data concerning health or data concerning a natural person's sex life or sexual orientation shall be
prohibited."*

Lo que decide en ingeniería:
- **El tratamiento parte de PROHIBIDO** y solo es lícito si encaja en una de las excepciones del
  art. 9.2 — entre ellas **(h)** fines de medicina preventiva o laboral, diagnóstico médico,
  prestación de asistencia o gestión de sistemas y servicios sanitarios, e **(i)** interés público
  en el ámbito de la salud pública. **Cuál aplica lo decide el DPO/legal, no ingeniería**, pero
  **el diseño tiene que ser compatible con la que se invoque**: el art. 9.2.h exige, además,
  tratamiento por profesional sujeto a secreto o bajo su responsabilidad.
- **El consentimiento explícito (art. 9.2.a) rara vez es la base correcta en asistencia** y usarlo
  por defecto crea la trampa de que su retirada obligaría a borrar lo que legalmente hay que
  conservar (§3.4).
- **HIPAA no aplica en España ni en la UE.** Es legislación de EE. UU. y solo obliga a *covered
  entities* (planes de salud, cámaras de compensación, proveedores que transmiten electrónicamente)
  y a sus *business associates*. **Citarla en un proyecto europeo es señal de que el análisis
  regulatorio no se ha hecho** — y a la inversa: en un producto vendido en EE. UU., el RGPD no la
  sustituye. Si vendes en ambos, cumples ambos, y el diseño se hace contra el más estricto por
  requisito.

### 5.5 Auditoría de acceso — requisito, no *extra*

**El registro de quién ha visto qué historia y cuándo es un requisito funcional del producto**, con
su historia de usuario, sus pruebas y su interfaz de consulta. No es "logging".

- **Se registra el acceso de lectura**, no solo la escritura. El daño típico en sanidad es un
  profesional consultando la historia de un famoso, un vecino o una expareja: sin registro de
  lectura, es indetectable.
- Modelo: **`AuditEvent`** (FHIR) o **IHE ATNA**; con quién (identidad real, no cuenta compartida),
  qué recurso, qué paciente, cuándo, desde dónde y con qué propósito declarado.
- **Retención acorde a la obligación legal, integridad protegida y acceso al registro restringido**
  y a su vez auditado.
- **Se explota, no solo se guarda**: alertas por acceso a paciente sin relación asistencial activa,
  por volumen anómalo, por acceso fuera de turno. Un registro que nadie mira no ha prevenido nada.
- **Cuentas compartidas: PROHIBIDAS**, sin excepción. Rompen todo lo anterior y son endémicas en
  entornos hospitalarios; la respuesta correcta es *single sign-on* con tarjeta o *fast user
  switching*, no tolerar `enfermeria01`.

## 6. Rendimiento y operabilidad

- **Un hospital no tiene ventana de parada.** Las 24×7 son reales: el despliegue es progresivo, con
  compatibilidad hacia atrás en las interfaces y coordinación con operaciones clínicas. Un corte de
  10 minutos en un sistema de prescripción es un evento de seguridad del paciente.
- **Modo degradado documentado**: qué pasa cuando cae el servidor FHIR, el de terminología o el MPI.
  Casi siempre la respuesta correcta es **rechazar con claridad**, no servir dato incompleto: un
  resultado sin unidad es peor que un error visible.
- **Latencia con criterio clínico**: la consulta que un médico hace con el paciente delante tiene un
  presupuesto de segundos; el `$export` masivo no compite con ella (colas separadas).
- **Bulk Data (`$export`, NDJSON)** para uso secundario y analítica: **asíncrono, con
  `Content-Location` y sondeo**, nunca sobre la API interactiva.
- **Notificación de cambios**: `Subscription` (en R4, con las limitaciones conocidas; en R5,
  *topic-based*). Alternativa realista y frecuente: el bus v2 existente. **Lo que no vale es
  *polling* de toda la historia**.
- **Idempotencia en la ingesta**: los motores de integración reintentan. Un `ORU` duplicado que crea
  dos observaciones es un error clínico; se resuelve con `If-None-Exist`, identificador de negocio o
  clave de deduplicación, decidido explícitamente.
- **Reloj y zona horaria**: instantes clínicos siempre con desplazamiento (`instant`/`dateTime` con
  zona). Una hora de administración de medicación sin zona es ambigua, y en un cambio de horario la
  ambigüedad es de una hora entera.
- **Trazabilidad extremo a extremo entre v2 y FHIR**: el identificador de control del mensaje
  (`MSH-10`) debe poder correlacionarse con el recurso resultante. Sin eso, un incidente clínico no
  se puede investigar.

## 7. Régimen regulatorio y prohibiciones

### 7.1 Cuándo tu software es producto sanitario

**No lo decide el marketing ni la arquitectura: lo decide la finalidad prevista que tú declaras.**
Si el software tiene una finalidad médica (diagnóstico, prevención, seguimiento, predicción,
pronóstico, tratamiento o alivio de una enfermedad) es producto sanitario bajo el **Reglamento (UE)
2017/745 (MDR)**; si su finalidad es aportar información a partir de muestras *in vitro*, bajo el
**Reglamento (UE) 2017/746 (IVDR)**.

La **regla 11 del Anexo VIII del MDR** es la regla de clasificación específica de software y **es
la que sorprende a todo el mundo**: en sustancia, el software destinado a proporcionar información
que se use para tomar decisiones con fines diagnósticos o terapéuticos es **clase IIa**, salvo que
esas decisiones puedan causar muerte o deterioro irreversible del estado de salud (**clase III**) o
un deterioro grave o una intervención quirúrgica (**clase IIb**); el software para vigilar procesos
fisiológicos sube de clase si los parámetros vigilados pueden generar peligro inmediato.

- **Consecuencia práctica: la regla 11 saca a casi todo el software clínico de la clase I**, que es
  la única autocertificable. Fuera de clase I hay **organismo notificado**, y eso son plazos de
  meses o años y un presupuesto que no es de ingeniería.
- **Aviso de verificación, y es importante: el texto de la regla 11 NO se ha podido citar verbatim
  aquí** — `health.ec.europa.eu` devolvió **403** y el texto consolidado del MDR en EUR-Lex se
  trunca por tamaño. Lo anterior es **paráfrasis a partir de fuentes secundarias concordantes**.
  **Antes de clasificar nada, lee la regla 11 en EUR-Lex y la guía MDCG 2019-11 en su fuente**
  (§8). En un expediente regulatorio, parafrasear la regla de clasificación es inaceptable.
- **Hay una reforma en discusión** que reescribiría la regla 11 rebajando clases: **no verificada,
  no planifiques contra ella** (§8).
- **Una vez clasificado, todo el proceso —IEC 62304, ISO 14971, evidencia para el organismo
  notificado— es de `safety-critical-standards`.**

### 7.2 EHDS — el eje regulatorio europeo con fechas

**Reglamento (UE) 2025/327 del Parlamento Europeo y del Consejo, de 11 de febrero de 2025, relativo
al Espacio Europeo de Datos Sanitarios** (título verificado en EUR-Lex). Publicado en el DOUE el
**5 de marzo de 2025**. Establece obligaciones sobre **uso primario** (acceso del paciente y
portabilidad, categorías prioritarias como el resumen de paciente y la receta/dispensación
electrónicas), **requisitos para los sistemas de historia clínica electrónica** (con un régimen de
conformidad y autodeclaración propio, distinto del de producto sanitario) y **uso secundario**
(organismos de acceso a datos, permisos, entornos seguros de tratamiento).

**Fechas — hueco parcialmente declarado**: el artículo final de aplicación **no se ha podido
extraer verbatim de EUR-Lex** (el documento se trunca). Las fuentes secundarias concuerdan en:
entrada en vigor **26 de marzo de 2025**, aplicación general **26 de marzo de 2027**, capítulo de
uso secundario y primeras categorías prioritarias **26 de marzo de 2029**, imagen médica, resultados
de pruebas e informes de alta **26 de marzo de 2031**. **Verifícalas en el artículo final del texto
oficial antes de ponerlas en una hoja de ruta** (§8).

**Lo que decide hoy, con independencia de la fecha exacta**: si construyes un sistema de historia
clínica electrónica para el mercado europeo, **su capacidad de exportar en formato de intercambio
europeo y su régimen de conformidad son requisitos de producto**, no una funcionalidad futura. Y
**MyHealth@EU** es la infraestructura por la que ya circulan el resumen de paciente y la receta
electrónica transfronterizos: alinearse con IPS no es opcionalismo estándar, es la vía.

### 7.3 IA en software sanitario — acumulación de regímenes

Un producto sanitario **con IA** acumula: MDR/IVDR (con organismo notificado), el **AI Act** (el
producto sanitario de clase que requiere evaluación por tercero encaja en el alto riesgo del
Anexo I), y el RGPD. **Todo el gobierno del sistema de IA —clasificación, roles proveedor/
desplegador, supervisión humana, documentación técnica, incidentes graves— es de
`ai-governance-standards`**, y **el proceso de seguridad del producto es de
`safety-critical-standards`**. De aquí solo la advertencia arquitectónica: **el dato de
entrenamiento clínico arrastra el art. 9 del RGPD, y el rendimiento de un modelo clínico se degrada
al cambiar de población** — el sitio y la cohorte de validación son parte del contrato clínico.

### 7.4 Prohibiciones

- ❌ **PROHIBIDO** emparejar pacientes con heurística propia (nombre + fecha de nacimiento) en vez
  del servicio de identidad de la organización (§3.5).
- ❌ **PROHIBIDO** exponer dato clínico leyendo la base de datos o una proyección SQL del sistema
  origen en vez de pasar por la interfaz clínica estándar. `mumps-standards` sostiene lo mismo desde
  el otro lado.
- ❌ Datos reales de pacientes en entornos de desarrollo, prueba, demo o formación (§4.6).
- ❌ Cuentas compartidas en un sistema con historia clínica (§5.5).
- ❌ No registrar los accesos de **lectura** a la historia clínica (§5.5).
- ❌ `DELETE` físico de información clínica; se anula con `entered-in-error` (§3.4).
- ❌ Enviar un valor de laboratorio sin código, sin unidad o sin estado (§1).
- ❌ Texto libre como mecanismo de interoperabilidad para algo sobre lo que el receptor debe actuar.
- ❌ Códigos de terminología **copiados y congelados** en tu esquema en vez de resueltos contra un
  servidor de terminología con versión declarada (§2, §4.2).
- ❌ Mezclar edición internacional y extensión nacional de SNOMED CT en un `ValueSet` sin declarar
  versión (§2.2).
- ❌ Usar SNOMED CT en un territorio no miembro sin licencia MLDS vigente (§2.2).
- ❌ Tratar ICD-10/CIE-10 y SNOMED CT como intercambiables.
- ❌ Extensiones FHIR con URL no publicada, o perfiles que **amplían** en vez de restringir (§3.1).
- ❌ Reemplazar el contrato REST de FHIR por convenciones propias (§3.3).
- ❌ Usar `batch` donde el caso exige `transaction` (§3.3).
- ❌ Búsqueda sin paginación sobre un servidor clínico.
- ❌ Citar **HIPAA** como marco de cumplimiento de un proyecto europeo, o el **RGPD** como sustituto
  de HIPAA en EE. UU. (§5.4).
- ❌ Afirmar que un conjunto clínico está "anonimizado" sin análisis de reidentificación (§5.3).
- ❌ Declarar la clase de producto sanitario **de memoria o por analogía con un competidor**, sin
  leer la regla 11 y la MDCG 2019-11 en fuente (§7.1).
- ❌ Anunciar "cumplimos EHDS" con fechas no verificadas en el texto oficial (§7.2).
- ❌ Planificar la sustitución total de HL7 v2 por FHIR como fase de proyecto (§2.1).
- ❌ Poner en producción **R6** o basar un compromiso contractual en él antes de su publicación (§2).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Versión de FHIR y su estado**, en `hl7.org/fhir/history.html` (verificado aquí: **R4 = 4.0.1,
   2018-12-27, contenido normativo; R5 = 5.0.0, 2023-03-26, *trial-use*, "None of the content in
   this specification is considered Normative"**) y el estado de **R6** en `build.fhir.org`
   (verificado: **v6.0.0-ballot4**, primera versión totalmente normativa **cuando se publique**).
   **Comprueba si R6 ya se ha publicado**: es el cambio con más impacto pendiente de este dominio.
2. **Versión exacta de cada IG que vas a usar**, en su página canónica: **IPS
   `hl7.fhir.uv.ips#2.0.1`** (FHIR 4.0.1), **US Core `hl7.fhir.us.core#9.0.0`** (FHIR 4.0.1,
   2026-05-31), **SMART App Launch `hl7.fhir.uv.smart-app-launch#2.2.0`** (STU 2.2, 2023-03-01).
   Todas verificadas a ago-2026 y **todas cambian con cadencia anual o menor**.
3. **Guía nacional española**: **hueco declarado — no se ha localizado una IG FHIR general del
   HCDSNS**. Lo verificado es la existencia de IG sectoriales del Ministerio de Sanidad (ÚNICAS,
   `unicas-fhir.sanidad.gob.es`, v0.0.6, sobre R5, alineada con MyHealth@EU NCPeH e IPS).
   **Consulta al Ministerio de Sanidad, a la comunidad autónoma competente y a HL7 Spain antes de
   comprometer un perfil en un pliego.**
4. **SNOMED CT**: estado de membresía de **tu territorio de despliegue** y el de tus clientes en
   `snomed.org/members` (**España figura como miembro a ago-2026**), condiciones verificadas
   verbatim en `snomed.org/get-snomed`, y la **versión de la edición** (internacional + extensión
   nacional) que vas a fijar. Registro en el NRC correspondiente.
5. **Regla 11 del Anexo VIII del MDR, en EUR-Lex, y la guía MDCG 2019-11 en su fuente oficial.**
   **Hueco declarado**: aquí no se ha podido citar verbatim — `health.ec.europa.eu` devolvió **403**
   y el consolidado del MDR en EUR-Lex se trunca por tamaño. **Y verifica el estado de la reforma
   de la clasificación de software**, que a ago-2026 está en discusión y no publicada.
6. **EHDS — Reglamento (UE) 2025/327**: **hueco parcial declarado**. Título y fecha de adopción
   (11-02-2025) y publicación en DOUE (05-03-2025) verificados; **el artículo final de entrada en
   vigor y aplicación NO se ha extraído verbatim** (EUR-Lex trunca el documento) y las fuentes
   secundarias discrepan entre sí sobre la fecha exacta de entrada en vigor. **Léelo en el texto
   oficial antes de poner una fecha en una hoja de ruta o en una oferta.**
7. **RGPD art. 9**: la enumeración de categorías especiales está **verificada verbatim** aquí
   (§5.4). La **base de licitud concreta** que aplica a tu tratamiento la fija el DPO, y su
   desarrollo nacional (en España, LOPDGDD y la normativa sanitaria de conservación de la historia
   clínica) hay que verificarlo con `privacy-engineering-standards`.
8. **Estado de conformidad del servidor FHIR o del proveedor**: su `CapabilityStatement` real, no
   su folleto; y qué versión de FHIR y qué IG soporta **de verdad**.
9. **CVEs y avisos** del servidor FHIR, del motor de integración (Mirth/NextGen Connect, Rhapsody,
   Iguana), del PACS/DICOM y del servidor de terminología. **El sector sanitario es objetivo
   preferente de ransomware**: coordina con `vulnerability-management-standards` y `bcdr-standards`.
10. **Estado de `mumps-standards` y `safety-critical-standards`** como fronteras recíprocas: la
    primera delega aquí todo el criterio de interoperabilidad clínica; la segunda es la dueña de
    IEC 62304 e ISO 14971 una vez el software está clasificado como producto sanitario.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
