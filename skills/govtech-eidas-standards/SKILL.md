---
name: govtech-eidas-standards
description: European e-government engineering — electronic identity, trust services and administrative procedure. Use when working with eIDAS Regulation (EU) No 910/2014 and its amendment Regulation (EU) 2024/1183, the European Digital Identity Wallet (EUDI Wallet) and its Architecture and Reference Framework, eID assurance levels low/substantial/high and the eIDAS node, qualified trust service providers and EU/national trusted lists (TSL, Commission Implementing Decision (EU) 2015/1505, the LOTL), advanced versus qualified electronic signatures (QES) and their legal effect, electronic seals, qualified electronic time stamps, qualified electronic registered delivery, QSCD and remote signing, signature formats XAdES, CAdES, PAdES and ASiC with baseline levels B, T, LT and LTA (Commission Implementing Decision (EU) 2015/1506, ETSI TS 103171/103172/103173/103174), signature validation with DSS or a validation service, long-term preservation and evidence renewal, Spanish e-government infrastructure (Cl@ve and the Cl@ve app, certificado FNMT, DNIe, @firma, AutoFirma, VALIDe, Notific@, Cl@ve Firma, SIA, DIR3), Ley 39/2015 and Ley 40/2015 identification and signature systems, the Esquema Nacional de Seguridad (Real Decreto 311/2022) and its básica/media/alta categories and CCN-STIC guidance, the Esquema Nacional de Interoperabilidad and public sector open data reuse, or a public procurement pliego that constrains the architecture of a public-sector system.
---

# Estándares de administración electrónica europea (eIDAS)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando el software **produce, consume o custodia un acto administrativo o un documento con
valor jurídico**: identificar a un ciudadano ante una administración, firmar electrónicamente,
registrar una solicitud, notificar de forma fehaciente, sellar con tiempo, y **conservar todo eso
durante décadas de forma que siga siendo verificable**.

**Tesis del dominio: firmar es el problema fácil; el problema real es la conservación.** Firmar es
una operación de treinta líneas. Lo difícil es que dentro de **veinte años** alguien pueda demostrar
que ese documento se firmó, con qué certificado, que el certificado era válido **en aquel momento**,
que la CA existía y estaba en la lista de confianza, y que el algoritmo no se ha roto por el camino.
Casi todos los proyectos de administración electrónica se diseñan alrededor del acto de firmar y
descubren el problema de la longevidad cuando el primer certificado caduca (§6). Corolario que
cambia el diseño desde el primer día: **una firma sin sello de tiempo cualificado y sin material de
validación embebido caduca con el certificado**, y con ella la prueba.

**Segunda tesis, y es una restricción de ingeniería aunque no lo parezca: en el sector público, la
arquitectura la fija el pliego.** Lo que no está en el pliego no se hace, no se factura y no se
mantiene. Un requisito no funcional que no aparezca en los criterios de adjudicación —observabilidad,
pruebas, migración de datos, plan de salida— no existe para el proyecto (§7.1).

Cubre: identidad electrónica y niveles de garantía; la cartera europea; servicios de confianza y
listas de confianza; tipos de firma y su valor probatorio; formatos y niveles de longevidad;
conservación a largo plazo; la infraestructura española concreta; y las restricciones de
contratación, accesibilidad e interoperabilidad del sector público.

**No aplica**:
- `identity-access-management-standards` (**frontera principal**): **OAuth 2.1/OIDC, SAML, el IdP
  como producto, passkeys/WebAuthn, SCIM, RBAC/ABAC/ReBAC, sesión y federación técnica son suyos**.
  **De aquí: qué identidad tiene valor jurídico frente a una administración y con qué nivel de
  garantía** —los niveles bajo/sustancial/alto de eIDAS no son una escala de MFA, son una
  calificación normativa de un esquema notificado—, el nodo eIDAS y la cartera europea. Regla de
  arbitraje: *"¿cómo autentico al usuario en mi aplicación?" es suya; "¿este medio de
  identificación sirve para que el acto sea válido y para que otro Estado miembro lo reconozca?" es
  de aquí*.
- `cryptography-pki-standards` (**frontera principal**): **algoritmos, curvas, tamaños de clave,
  TLS, jerarquía de CA, ACME, HSM/KMS y el ciclo de vida del certificado como criptografía son
  suyos**. **De aquí: qué convierte a una PKI en *cualificada* bajo eIDAS y qué obligaciones
  jurídicas trae** —QTSP, QSCD, listas de confianza, valor probatorio—, que no es una propiedad
  criptográfica sino de supervisión. Aviso recíproco: la **migración post-cuántica** de estas firmas
  es de `post-quantum-crypto-standards`, **y afecta directamente a la conservación a largo plazo**
  (§6.3).
- `grc-compliance-standards` (**frontera declarada en ambos lados**): **el ENS como marco de
  gestión, su Declaración de Aplicabilidad, la auditoría de certificación, el registro de riesgo y
  la relación con el CCN son suyos** —ya cita RD 311/2022—. **De aquí: qué obliga el ENS a la
  arquitectura de un servicio electrónico concreto** (§2.5) y su relación con el resto de este
  documento.
- `accessibility-standards`: **todo el criterio técnico de conformidad es suyo** —WCAG 2.x, EN 301
  549, RD 1112/2018, la declaración de accesibilidad, cómo se prueba y quién firma—. **De aquí solo
  el hecho que decide prioridad: en el sector público es obligación legal, no mejora** (§7.2).
- `privacy-engineering-standards` (dato personal, minimización, DPIA, derechos, retención — **y el
  choque real con la obligación de conservación del expediente**, §6.1),
  `api-design-standards` (contratos de servicio), `data-governance-quality-standards` (propiedad y
  calidad del dato), `ai-governance-standards` (AI Act — **una administración que automatiza
  decisiones es desplegador de alto riesgo, y eso es suyo**),
  `appsec-standards` y `vulnerability-management-standards`,
  `web-app-servers-standards` y `frontend-web-platform-standards` (la sede electrónica como
  aplicación web), `bcdr-standards` y `backup-recovery-standards`,
  `enterprise-architecture-standards` y `project-management-standards` (**cartera y gobierno del
  programa**; aquí solo la contratación en lo que restringe la arquitectura),
  `opensource-licensing-standards` (reutilización de software público y su licencia),
  `healthtech-fhir-standards` (**hermana**: la receta electrónica y el resumen de paciente
  transfronterizos son suyos como dato clínico; **la firma, el sello y la identidad con que
  circulan, de aquí**), `offensive-security-standards` (**esta skill es defensiva**).

## 2. Decisiones por defecto

> Verificar por web el texto consolidado y las fechas antes de fijarlas en un proyecto real (§8).

### 2.1 Marco normativo

| Pieza | Qué es | Verificado a ago-2026 |
|---|---|---|
| **Reglamento (UE) n.º 910/2014 (eIDAS)** | Identificación electrónica y servicios de confianza en el mercado interior | En vigor; **modificado por el Reglamento (UE) 2024/1183** |
| **Reglamento (UE) 2024/1183 ("eIDAS 2")** | Introduce el **marco de identidad digital europea** y la **cartera (EUDI Wallet)** | Publicado en el DOUE el **30-04-2024**; entrada en vigor citada como **20-05-2024** — *fuentes secundarias discrepan (una da 30-05-2024)*: **verifícalo en el artículo final del texto oficial** (§8) |
| **Decisión de Ejecución (UE) 2015/1505** | Especificaciones técnicas de las **listas de confianza** (art. 22.5) | Título verificado verbatim (§2.4) |
| **Decisión de Ejecución (UE) 2015/1506** | Formatos de firma y sello avanzados **que los organismos del sector público deben reconocer** | Título y arts. 1-2 verificados verbatim (§2.3) |
| **Ley 39/2015** (procedimiento administrativo común) | Identificación (art. 9) y firma (art. 10) del interesado, registro, notificación | Consolidado en BOE |
| **Ley 40/2015** (régimen jurídico del sector público) | Sede electrónica, sello del órgano, actuación administrativa automatizada, archivo | Consolidado en BOE |
| **Real Decreto 311/2022 (ENS)** | *"Real Decreto 311/2022, de 3 de mayo, por el que se regula el Esquema Nacional de Seguridad"* (título verbatim, BOE) | **Categorías BÁSICA / MEDIA / ALTA** (art. 40 y anexo I). El consolidado del BOE muestra **modificación posterior**: verifícala (§8) |
| **Ley 6/2020** (servicios electrónicos de confianza) | Desarrollo español de eIDAS | Verificar vigencia y modificaciones (§8) |

### 2.2 Firma electrónica: los tres niveles y su valor probatorio

Los tres niveles no son "más o menos seguros": **son categorías jurídicas distintas**.

| Nivel | Qué es | Valor |
|---|---|---|
| **Simple** | Datos en forma electrónica usados por el firmante para firmar (un clic, un nombre al pie) | No se le puede negar efecto jurídico **solo** por ser electrónica |
| **Avanzada (AdES)** | Vinculada únicamente al firmante, permite identificarlo, creada con datos bajo su control exclusivo y detecta cualquier cambio posterior | Es el nivel que las administraciones **exigen** normalmente; su reconocimiento transfronterizo pasa por 2015/1506 (§2.3) |
| **Cualificada (QES)** | Avanzada **+ dispositivo cualificado de creación (QSCD) + certificado cualificado** de un QTSP supervisado | **Equivalencia con la firma manuscrita**, §2.2.1 |

**2.2.1 — El texto que decide, verbatim** (Reglamento (UE) n.º 910/2014, **art. 25**, verificado en
EUR-Lex):

> *"1. An electronic signature shall not be denied legal effect and admissibility as evidence in
> legal proceedings solely on the grounds that it is in an electronic form or that it does not meet
> the requirements for qualified electronic signatures.*
> *2. A qualified electronic signature shall have the equivalent legal effect of a handwritten
> signature.*
> *3. A qualified electronic signature based on a qualified certificate issued in one Member State
> shall be recognised as a qualified electronic signature in all other Member States."*

Lo que esto decide en ingeniería:
- **El art. 25.1 no dice que una firma simple valga lo mismo**: dice que no se le puede negar
  efecto **por el solo hecho** de ser electrónica. Su fuerza probatoria en un litigio hay que
  demostrarla con evidencias — y esas evidencias hay que haberlas guardado (§4.3).
- **El art. 25.3 es el que hace posible el mercado interior**: una QES española vale en Alemania
  **sin acuerdo bilateral**. Lo que lo sostiene técnicamente son las listas de confianza (§2.4).
- **QES no es "firma con certificado"**: exige **QSCD**. Un certificado cualificado en software, en
  un fichero `.p12` en el disco, **no produce QES**. Confundirlo es el error más caro de este
  dominio, y se hereda a los pliegos.
- **Sello electrónico** (organización, no persona) y **sello de tiempo cualificado** tienen sus
  propios artículos con presunciones específicas — **no verificados verbatim aquí: hueco declarado**
  (§8). No los cites de memoria en un informe jurídico.
- **La firma no acredita la voluntad, acredita la integridad y el firmante.** Lo que se firmó, qué
  vio el firmante en pantalla y bajo qué texto legal, es una decisión de diseño del trámite (§3.2).

### 2.3 Formatos y niveles de longevidad — el texto verbatim

**Decisión de Ejecución (UE) 2015/1506**, título verificado: *"Commission Implementing Decision (EU)
2015/1506 of 8 September 2015 laying down specifications relating to formats of advanced electronic
signatures and advanced seals to be recognised by public sector bodies pursuant to Articles 27(5)
and 37(5) of Regulation (EU) No 910/2014"*. **Artículo 1, verbatim:**

> *"Member States requiring an advanced electronic signature or an advanced electronic signature
> based on a qualified certificate as provided for in Article 27(1) and (2) of Regulation (EU) No
> 910/2014, shall recognise XML, CMS or PDF advanced electronic signature at conformance level B, T
> or LT level or using an associated signature container, where those signatures comply with the
> technical specifications listed in the Annex."*

Y las especificaciones del anexo, tal como aparecen: **XAdES → ETSI TS 103171 v.2.1.1**, **CAdES →
ETSI TS 103173 v.2.2.1**, **PAdES → ETSI TS 103172 v.2.2.2**, **ASiC (contenedor) → ETSI TS 103174
v.2.2.1**.

| Formato | Envuelve | Úsalo cuando |
|---|---|---|
| **XAdES** | XML | El documento **es** XML (factura electrónica, asiento registral, intercambio estructurado) |
| **CAdES** | CMS/binario | Cualquier fichero binario; firma separada (*detached*) |
| **PAdES** | PDF | El documento se lee como PDF y la firma debe viajar dentro y ser verificable por un lector estándar |
| **ASiC** | Contenedor (ZIP) | Varios ficheros + sus firmas como una unidad. **La elección por defecto para un expediente** |

**Niveles de longevidad — el eje de todo el documento:**

| Nivel | Qué añade | Consecuencia |
|---|---|---|
| **B** (*baseline*) | La firma y sus atributos mínimos | **Caduca con el certificado.** Sirve para el momento, no para el archivo |
| **T** | **Sello de tiempo** sobre la firma | Prueba **cuándo** se firmó. Sin esto no se puede demostrar que el certificado estaba vigente |
| **LT** | Incrusta el **material de validación** (cadena de certificados, CRL/OCSP del momento) | La firma se valida **sin depender de que la CA siga viva o publicando revocación** |
| **LTA** | Sellos de tiempo de archivo **encadenados y renovables** | Único nivel que sobrevive a la **obsolescencia del algoritmo** (§6.3) |

**Dato que sorprende y hay que decir: la obligación de reconocimiento del art. 1 de 2015/1506
alcanza a los niveles B, T y LT — LTA no aparece en esa enumeración.** Es decir: **el nivel que de
verdad necesitas para conservar no es el que la Decisión obliga a reconocer.** Consecuencia
operativa: **firmas al menos en T para producir, en LT para entregar, y conservas en LTA** (§6), y
no confundas "lo que hay que reconocer" con "lo que hay que archivar".

### 2.4 Listas de confianza (TSL) — el mecanismo que hace que todo esto funcione

**Decisión de Ejecución (UE) 2015/1505**, título y artículos verificados verbatim en EUR-Lex.
**Artículo 1:**

> *"Member States shall establish, publish and maintain trusted lists including information on the
> qualified trust service providers which they supervise, as well as information on the qualified
> trust services provided by them. Those lists shall comply with the technical specifications set
> out in Annex I."*

**Artículo 2:** los Estados miembros *"may include in the trusted lists information on non-qualified
trust service providers"*, y la lista *"shall clearly indicate which trust service providers and the
trust services provided by them are not qualified."*
**Artículo 3:** los Estados miembros *"shall sign or seal electronically the form suitable for
automated processing of their trusted list"*, y la versión legible por humanos, si se publica, *"contains
the same data as the form suitable for automated processing"* y también se firma o sella.

**Por qué esto es el corazón del sistema, y no una nota al pie:**
- **La confianza no es criptográfica, es de supervisión.** Una firma es válida no porque la
  matemática cuadre, sino porque el emisor del certificado estaba **en la lista de confianza del
  Estado que lo supervisa, en el momento de firmar**.
- Sobre las listas nacionales hay una **lista de listas (LOTL)** firmada por la Comisión. Tu
  validador tiene que partir de ahí, no de un almacén de CAs raíz copiado a mano.
- **La lista tiene historia y estados**: un prestador puede estar `granted`, `withdrawn` o haber
  cesado. **Validar "a fecha de hoy" una firma de hace ocho años es un error de validación**: se
  valida contra el estado de la lista **en la fecha del sello de tiempo**.
- **PROHIBIDO** mantener un almacén propio de certificados de confianza para esto (§7.3): en el
  momento en que un prestado se retira de la lista, tu almacén miente.

### 2.5 España — la infraestructura concreta

| Pieza | Qué es | Criterio |
|---|---|---|
| **Cl@ve** | Sistema unificado de identificación de la AGE y de comunidades adheridas | Se ha reorganizado alrededor de la **app Cl@ve** y de **Cl@ve Móvil** (autenticación por QR o confirmación en la app), con **PIN por SMS** como alternativa; conviven **Cl@ve Permanente** y el alta por **videoidentificación**. **Verifica el estado exacto y qué método sigue vivo en `clave.gob.es`: cambia, y aquí solo hay fuentes secundarias — hueco declarado** (§8) |
| **Certificado FNMT** | Certificado de persona física/jurídica de la FNMT-RCM | El más extendido; **software por defecto → no produce QES** salvo en tarjeta/dispositivo cualificado (§2.2) |
| **DNIe** | Certificado en el chip del DNI | Es el caso claro de **dispositivo cualificado**; su fricción real es el lector y los *drivers* |
| **@firma** | Plataforma de validación de firma y certificados de la AGE | **Úsala en vez de escribir tu propio validador** (§4.1) |
| **AutoFirma** | Cliente de escritorio de firma | Es lo que el ciudadano tiene instalado; su fricción (Java, navegador, protocolo `afirma://`) es una causa real de abandono de trámites |
| **VALIDe** | Servicio público de validación y visualización de firmas | Comprobación manual y de soporte |
| **Cartera Digital Europea** | La EUDI Wallet aplicada en España | **No sustituye a Cl@ve/FNMT/DNIe: se suma.** Diseña para coexistencia, no para migración |
| **ENS (RD 311/2022)** | Categorías **BÁSICA / MEDIA / ALTA** según el impacto sobre disponibilidad, autenticidad, integridad, confidencialidad y trazabilidad | **La categoría se determina antes de diseñar**, porque cambia medidas obligatorias. Las guías **CCN-STIC** son el aterrizaje técnico. El marco de gestión y la certificación son de `grc-compliance-standards` |

**La cartera europea (EUDI Wallet) — el dato que más se afirma mal.** Lo verificado: el art. 5a
del Reglamento (UE) 2024/1183 establece que *"each Member State shall provide at least one European
Digital Identity Wallet within 24 months of the date of entry into force of the implementing acts"*,
y que *"By 21 November 2024, the Commission shall, by means of implementing acts, establish a list
of reference standards"*. **De ahí sale el plazo que todo el mundo cita como "finales de 2026" — y
es una fecha derivada, no una fecha escrita en el Reglamento.** No la pongas en una oferta sin
comprobar el texto y la fecha real de entrada en vigor de los actos de ejecución (§8). Lo que sí
puedes fijar hoy: **si construyes un servicio público, tienes que poder aceptar la cartera además
de lo existente**, y eso es una decisión de arquitectura de identidad, no un `if`.

## 3. Estructura de un trámite electrónico

### 3.1 La cadena completa, y dónde se rompe

```
Identificación (nivel de garantía exigido por el trámite)
  → Presentación del contenido a firmar (lo que el ciudadano realmente ve)
    → Firma (nivel exigido: avanzada o cualificada)
      → Sello de tiempo cualificado
        → Registro de entrada (asiento con número, fecha y hora fehacientes)
          → Justificante al ciudadano (con el mismo valor probatorio)
            → Tramitación (con sello de órgano en las actuaciones automatizadas)
              → Notificación fehaciente (con acuse y cómputo de plazos)
                → Archivo electrónico (LTA, con plan de conservación) ← aquí muere casi todo
```

Reglas duras:
1. **El nivel de garantía exigido lo fija el trámite**, no la comodidad del desarrollador, y hay que
   poder justificarlo. Exigir certificado cualificado para consultar el estado de un expediente es
   una barrera de acceso; admitir identificación baja para una renuncia de derechos es un defecto.
2. **El justificante de presentación es el producto**, no un correo de cortesía: es lo que el
   ciudadano usará para demostrar que presentó en plazo. Lleva firma o sello de la administración y
   sello de tiempo.
3. **Los plazos administrativos son lógica de negocio crítica**: días hábiles, festivos estatales,
   autonómicos y locales, y el criterio de cómputo de la notificación. Es la fuente de errores más
   frecuente y la que produce indefensión.
4. **La sede electrónica tiene requisitos propios** (identificación de la sede, sello, publicación
   de servicios, accesibilidad) que no son los de una web corporativa.
5. **Actuación administrativa automatizada**: si el acto lo produce el sistema sin intervención
   humana, hay que haberlo previsto y sellarlo con **sello de órgano**, con el órgano responsable
   definido y publicado. Un proceso automático que emite resoluciones sin esa cobertura produce
   actos anulables.

### 3.2 Qué se firma, exactamente

- **Se firma el documento, no el formulario.** Se genera una representación estable y visualizable
  del contenido (normalmente PDF/A), se muestra, y **eso** es lo que se firma. Firmar un JSON que
  el ciudadano nunca vio no acredita nada útil.
- **WYSIWYS** (*what you see is what you sign*): si el documento contiene elementos dinámicos
  —JavaScript en el PDF, contenido remoto, fuentes no incrustadas— lo que se ve puede no ser lo que
  se firmó. **PDF/A y todo incrustado**, sin excepción.
- **Se conserva lo que se mostró**, junto con la firma y sus evidencias.
- **Firma múltiple**: decidir explícitamente si es **paralela** (varios firman lo mismo,
  independientes) o **en cascada/contrafirma** (cada uno firma la firma anterior). Cambiar de
  criterio a mitad rompe la validación.

### 3.3 Evidencias — qué se guarda además del documento firmado

El documento firmado **no basta** como prueba. Se conserva, junto a él y de forma indisociable:
sello de tiempo cualificado, cadena completa de certificados, respuestas **OCSP o CRL del momento
de la firma**, el estado de la lista de confianza aplicable, la política de firma si se declaró, y
el informe de validación generado en el momento de aceptar. **Esto es exactamente lo que el nivel
LT incorpora dentro de la propia firma** — por eso LT no es un lujo, es lo que evita tener que
reconstruir la prueba a mano dentro de diez años.

## 4. Validación y pruebas

### 4.1 Validar

- **No escribas tu propio validador.** Se usa **DSS** (la biblioteca de referencia de la Comisión),
  el servicio de validación de la administración (**@firma** / **VALIDe** en España) o un servicio
  de validación cualificado. Un validador propio es donde se esconden los falsos "válido".
- **La validación parte de la LOTL**, no de un almacén de raíces propio (§2.4).
- **Se valida contra el instante del sello de tiempo**, no contra "ahora".
- **El resultado de la validación se guarda** con el expediente: en el futuro puede no ser
  reproducible.
- **Un resultado no es booleano.** Distingue `TOTAL-PASSED`, `INDETERMINATE` y `TOTAL-FAILED`, y
  **decide qué hace el trámite con `INDETERMINATE`** (que es lo que devuelve una firma cuyo material
  de revocación no se puede obtener). Tratar indeterminado como válido es el fallo más común.

### 4.2 Pruebas — el catálogo negativo, que aquí es el catálogo principal

Cada uno de estos casos tiene que existir como prueba automatizada:
certificado **caducado**; certificado **revocado antes** de firmar; certificado revocado **después**
de firmar (debe seguir siendo válido si hay sello de tiempo previo); **CA retirada** de la lista de
confianza; documento **modificado un byte** tras firmar; firma con algoritmo obsoleto; **cadena
incompleta**; **OCSP no disponible**; sello de tiempo ausente; **firma extranjera** de otro Estado
miembro (art. 25.3); PDF con contenido dinámico; ASiC con más ficheros de los firmados; y
**renovación de sello de archivo** en un LTA. Sin este catálogo, el sistema "funciona" y no prueba
nada.

### 4.3 Prueba de longevidad

**Ensaya el escenario de dentro de diez años, hoy**: coge un documento firmado, adelanta el reloj
del entorno de prueba más allá de la caducidad del certificado y de la CA, y **valida**. Si falla,
tu archivo electrónico no es un archivo, es una carpeta. Es la prueba que nadie hace y la que
demuestra si el diseño de §6 existe de verdad.

## 5. Seguridad

- **Claves de firma de la administración (sello de órgano, sello de sede, sellado de tiempo) en
  HSM**, nunca en fichero. Su ciclo de vida, custodia y rotación son de
  `cryptography-pki-standards`; **de aquí la exigencia de que la operación de firma esté
  autorizada, registrada y atribuible a un procedimiento concreto**.
- **La firma en servidor (remota) concentra el riesgo**: una API de firma mal autorizada firma
  cualquier cosa en nombre de quien sea. Autorización por transacción, con el contenido a firmar
  ligado a la autorización (no "permiso para firmar", sino "permiso para firmar *esto*").
- **Alta de identidad y videoidentificación**: el punto más atacado del sistema no es la
  criptografía, es el **enrolamiento**. Suplantación con documento falsificado, *deepfake* de
  vídeo y ataques de presentación. El nivel de garantía del esquema depende de esto, no del
  protocolo de autenticación.
- **La sede electrónica es un objetivo**: suplantación de la sede para capturar credenciales y
  firmas es un ataque directo al ciudadano. Certificado de sede, dominio bajo control con DNSSEC
  donde sea posible, HSTS, y **comunicación clara al ciudadano de cuál es la sede legítima**.
- **ENS**: la categoría determina medidas obligatorias; **se decide al principio del diseño**,
  porque afecta a arquitectura (segregación, trazabilidad, cifrado, continuidad) y no se puede
  añadir al final. Las guías **CCN-STIC** son el aterrizaje concreto.
- **Trazabilidad como requisito ENS**: quién accedió a qué expediente y cuándo, con integridad
  protegida y retención definida. Es requisito funcional con sus pruebas, no *logging*.

## 6. Conservación a largo plazo — el problema real

### 6.1 El conflicto que hay que nombrar

El expediente administrativo tiene **obligación legal de conservación** durante plazos largos, y el
derecho de supresión del RGPD **no la anula automáticamente**. Ese conflicto se resuelve por diseño
(qué se conserva, con qué base jurídica, qué se puede disociar), y **la decisión es de
`privacy-engineering-standards` y del DPO**. Lo que exige esta skill: **que el sistema pueda
distinguir "conservado por obligación legal" de "conservado porque nadie lo borró"** y pueda
enumerar dónde vive cada copia.

### 6.2 Cómo se conserva de verdad

1. **Firma en LTA** desde el archivo, con sellos de tiempo de archivo **encadenados**.
2. **Renovación programada** del sello de archivo **antes** de que el algoritmo o el certificado del
   sellador se debiliten. Esto es un **proceso operativo con calendario y responsable**, no una
   propiedad del formato: un LTA que nadie renueva se degrada igual.
3. **Formato de documento estable**: **PDF/A** con todo incrustado; XML con su esquema conservado
   junto al documento (un XML cuyo XSD desapareció es texto).
4. **Contenedor y metadatos de expediente**: ASiC u otro contenedor, con metadatos de archivo
   (identificador, órgano, fecha, tipo documental, política de conservación) según el **Esquema
   Nacional de Interoperabilidad** y sus normas técnicas.
5. **Migración de soporte y de formato planificada**, con la evidencia de que la migración preservó
   la integridad — la migración es en sí un acto que hay que poder demostrar.
6. **Prueba de restauración y validación periódica** del archivo (§4.3). Un archivo que no se ha
   validado no se sabe si existe.

### 6.3 La obsolescencia criptográfica, y el post-cuántico

**Toda firma envejece porque el algoritmo envejece.** El único mecanismo que lo resuelve es
**re-sellar el conjunto (documento + firmas + evidencias) con un algoritmo vigente antes de que el
anterior se rompa** — es exactamente para lo que existe LTA. Y aquí entra el aviso que hay que
poner por escrito hoy: **la transición post-cuántica afecta a los archivos ya firmados, no solo a
los nuevos**. Un documento firmado con RSA/ECDSA y conservado treinta años necesitará un sello de
archivo con algoritmo resistente **antes** de que el anterior deje de valer. **El calendario y la
elección de algoritmo son de `post-quantum-crypto-standards`; la obligación de tener un plan de
re-sellado es de aquí, y hay que presupuestarla ahora.**

## 7. Contexto de sector público y prohibiciones

### 7.1 La contratación pública como restricción de arquitectura

- **Lo que no está en el pliego no se hace.** Si observabilidad, pruebas automatizadas, migración de
  datos, documentación de arquitectura, formación y **plan de salida** no son requisitos con su
  criterio de valoración, no se entregarán. **El sitio donde se decide la calidad de un sistema
  público es el pliego, no el sprint.**
- **El alcance cerrado choca con el desarrollo incremental.** Un contrato de precio y alcance fijos
  a dos años convierte cualquier aprendizaje en modificado contractual. Cuando se puede elegir:
  contratos por servicio y capacidad, con lotes pequeños y entregables verificables.
- **Bloqueo de proveedor (*vendor lock-in*)** — la patología endémica. Antídotos que se escriben en
  el pliego, no después: **propiedad del código fuente y de los datos por la administración**,
  formatos y protocolos abiertos, entrega de la documentación de arquitectura y de despliegue como
  entregable, **entorno reproducible desde el repositorio**, y **prueba de salida ejecutada durante
  el contrato**, no descrita en un anexo.
- **Reutilización**: comprueba antes de construir si ya existe una solución en el catálogo de
  soluciones reutilizables de la administración. Y publica la tuya; su licencia se decide con
  `opensource-licensing-standards`.
- **La continuidad del conocimiento es un requisito**: el equipo del adjudicatario cambia con cada
  licitación. Lo que no esté en el repositorio y en la documentación, se pierde en cada relevo.

### 7.2 Accesibilidad e interoperabilidad

- **La accesibilidad es obligación legal en el sector público, y por tanto requisito funcional con
  criterio de aceptación.** Todo el criterio técnico —qué criterio WCAG, cómo se prueba, la
  declaración de accesibilidad y su revisión— es de **`accessibility-standards`**. **De aquí solo la
  consecuencia de contratación: si no está en el pliego con criterio de valoración, se entregará una
  declaración que no se corresponde con el sitio.** Y el aviso concreto de este dominio: **el paso
  crítico de un trámite —la firma— suele ser el menos accesible** (applets, ventanas emergentes,
  temporizadores, PDF sin etiquetar).
- **Interoperabilidad**: el **ENI** y sus normas técnicas fijan documento y expediente electrónico,
  política de firma, catálogo de estándares y modelo de datos para el intercambio. **Los
  identificadores comunes (DIR3 para unidades orgánicas, SIA para procedimientos) no son burocracia:
  son las claves foráneas del sector público** y sin ellas el intercambio entre administraciones no
  cierra.
- **Datos abiertos y reutilización**: los datos publicados salen en formatos abiertos y
  documentados, con licencia clara y **API estable**; y **la anonimización previa a la publicación
  se analiza en serio** (`privacy-engineering-standards`) — un conjunto público mal anonimizado no
  se puede retirar de internet.

### 7.3 Prohibiciones

- ❌ **PROHIBIDO** llamar QES a una firma con certificado en fichero software: sin **QSCD** no hay
  firma cualificada (§2.2).
- ❌ **PROHIBIDO** mantener un almacén propio de CAs de confianza en lugar de la **LOTL / lista de
  confianza** correspondiente (§2.4).
- ❌ Validar una firma antigua contra el estado de confianza **de hoy** en vez del de la fecha del
  sello de tiempo (§4.1).
- ❌ Tratar un resultado de validación `INDETERMINATE` como válido (§4.1).
- ❌ Escribir un validador de firma propio (§4.1).
- ❌ Firmar en nivel **B** algo que hay que conservar; archivar en algo que no sea **LTA** (§2.3, §6).
- ❌ Un LTA **sin proceso operativo de renovación de sellos**, con responsable y calendario (§6.2).
- ❌ Firmar contenido que el ciudadano no ha visto, o PDF con contenido dinámico o fuentes no
  incrustadas (§3.2).
- ❌ Descartar las evidencias de validación tras aceptar el documento (§3.3).
- ❌ Exigir un nivel de garantía o de firma superior al que el trámite necesita: es una barrera de
  acceso, y en el sector público eso es exclusión.
- ❌ Emitir actos por procedimiento automatizado sin cobertura de **actuación administrativa
  automatizada** y sin sello de órgano (§3.1).
- ❌ Calcular plazos administrativos con días naturales o sin calendario de festivos completo (§3.1).
- ❌ Poner en un pliego, en una oferta o en una nota de prensa **fechas de la cartera europea** sin
  haberlas verificado en el texto oficial y en los actos de ejecución (§2.5, §8).
- ❌ Afirmar que la cartera europea sustituye a Cl@ve, al certificado FNMT o al DNIe (§2.5).
- ❌ Entregar un sistema público sin propiedad del código y de los datos, sin entorno reproducible y
  sin plan de salida probado (§7.1).
- ❌ Tratar la accesibilidad como fase final o como declaración sin prueba (§7.2).
- ❌ Publicar datos abiertos sin análisis de reidentificación (§7.2).
- ❌ Citar de memoria un artículo de eIDAS, de la Ley 39/2015 o del ENS en un documento con efectos
  jurídicos. Se cita del texto consolidado (§8).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Texto consolidado del Reglamento (UE) n.º 910/2014 con las modificaciones del Reglamento (UE)
   2024/1183**, en EUR-Lex. Verificados aquí verbatim: **art. 25** completo (efectos jurídicos de la
   firma) y **art. 8.1 y 8.2** (niveles de garantía bajo, sustancial y alto). **Hueco declarado: los
   artículos sobre efectos jurídicos del sello electrónico y del sello de tiempo cualificado NO se
   han podido extraer verbatim** —EUR-Lex trunca el documento consolidado por tamaño— **así que no
   se citan aquí. Léelos antes de usarlos.**
2. **Fechas de la cartera europea (EUDI Wallet)**: entrada en vigor del Reglamento (UE) 2024/1183
   —**publicado en el DOUE el 30-04-2024; las fuentes secundarias dan 20-05-2024 y alguna 30-05-2024,
   y no se ha resuelto verbatim: hueco declarado**— y, sobre todo, **la fecha real de entrada en
   vigor de los actos de ejecución del art. 5a**, que es la que dispara el plazo de 24 meses. Lo
   verificado del art. 5a: *"within 24 months of the date of entry into force of the implementing
   acts"* y *"By 21 November 2024, the Commission shall, by means of implementing acts, establish a
   list of reference standards"*. **El "finales de 2026" que todo el mundo repite es una fecha
   derivada. Compruébala.** Consulta también el estado del **Architecture and Reference Framework**
   de la cartera y de los pilotos a gran escala.
3. **Decisiones de ejecución 2015/1505 (listas de confianza) y 2015/1506 (formatos)**: verificadas
   verbatim aquí en su versión original. **Comprueba si existe versión consolidada con
   modificaciones** —en particular si las referencias ETSI del anexo de 2015/1506 (TS 103171
   v.2.1.1, TS 103172 v.2.2.2, TS 103173 v.2.2.1, TS 103174 v.2.2.1) se han actualizado a las
   normas **EN 319 122 / 319 132 / 319 142 / 319 162**. **Las EN no se han verificado aquí:
   `etsi.org` devolvió 403 al acceso automático — hueco declarado.**
4. **Lista de listas (LOTL) y lista de confianza de tu país**, y **el prestador concreto** que vas a
   aceptar: su estado (`granted` / `withdrawn`) y los servicios cualificados que presta. Se comprueba
   en la lista, nunca en la web comercial del prestador.
5. **España**: texto consolidado en el **BOE** de la **Ley 39/2015** (arts. 9 y 10, sistemas de
   identificación y de firma admitidos), la **Ley 40/2015**, la **Ley 6/2020** y el **Real Decreto
   311/2022** (*"Real Decreto 311/2022, de 3 de mayo, por el que se regula el Esquema Nacional de
   Seguridad"*, título verificado). **Aviso: el consolidado del ENS muestra modificación posterior a
   su publicación; el detalle de esa modificación NO se ha verificado — hueco declarado.** Y la
   **guía CCN-STIC** aplicable a tu categoría.
6. **Estado de Cl@ve**: qué métodos siguen vivos (app Cl@ve, Cl@ve Móvil, PIN por SMS, Cl@ve
   Permanente, videoidentificación) y su nivel de garantía notificado, **en `clave.gob.es` y en el
   portal de Administración Electrónica**. **Aquí solo hay fuentes secundarias: hueco declarado.**
   Comprueba igualmente el estado de **@firma**, **AutoFirma**, **VALIDe** y sus versiones
   soportadas — **AutoFirma es una dependencia de escritorio del ciudadano y su compatibilidad con
   navegadores y con Java cambia**.
7. **Estado de la biblioteca DSS** y de tu servicio de validación: versión, algoritmos soportados y
   avisos de seguridad.
8. **Post-cuántico**: calendario de migración y algoritmos, con `post-quantum-crypto-standards`, y
   **su impacto sobre el plan de re-sellado del archivo** (§6.3).
9. **CVEs** de la plataforma de firma, del servidor de la sede, del gestor documental y del cliente
   de escritorio, con `vulnerability-management-standards`.
10. **Normas técnicas de interoperabilidad del ENI** vigentes (documento electrónico, expediente
    electrónico, política de firma, catálogo de estándares) y los catálogos **DIR3** y **SIA**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
