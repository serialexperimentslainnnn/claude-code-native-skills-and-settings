---
name: grc-compliance-standards
description: Governance, risk and compliance standards. Use when working with ISO 27001/27002/27005/27701, NIST CSF 2.0, CIS Controls v8.1, SOC 2, NIS2, DORA, ENS/CCN-STIC, Statement of Applicability, risk registers, control-to-evidence mapping, OSCAL, audit preparation, vendor questionnaires (SIG, CAIQ), or the regulatory notification clock after a breach — who must be told, within how many hours, and what evidence the filing needs.
---

# Estándares de gobierno, riesgo y cumplimiento (GRC)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, implantar, auditar o revisar:
- **SGSI** ISO/IEC 27001:2022: alcance, cláusulas 4-10, Anexo A, **Declaración de Aplicabilidad (SoA)**.
- **Gestión de riesgos**: metodología, escalas, registro de riesgos, tratamiento, **aceptación formal**
  y excepciones con caducidad.
- **Marcos y regulación**: NIST CSF 2.0, CIS Controls v8.1, SOC 2, ENS (RD 311/2022), NIS2, DORA,
  CRA, ISO 27701/42001 — ámbito, obligaciones y plazos.
- **Evidencia y cumplimiento continuo**: mapeo control→evidencia automatizable, OSCAL, política de
  retención, preparación de auditoría interna y externa.
- **Riesgo de terceros (TPRM)**: tiering de proveedores, SIG/CAIQ/CSA STAR, cláusulas contractuales,
  registro de información DORA.
- **Jerarquía documental**: política, normas, procedimientos, registros; dueños y cadencias.

**No aplica**: ver vulnerability-management-standards (para triaje CVE/CVSS/EPSS/KEV, SLA de
parcheo y VEX — aquí solo la **aceptación formal** del riesgo residual), appsec-standards (para
modelado de amenazas y OWASP/ASVS), sre-practice-standards (para SLO, on-call y postmortems),
identity-access-management-standards (para IAM técnico), cicd-standards, iac-standards,
kubernetes-standards, onprem-standards y las skills de cloud (para los **controles concretos**:
aquí viven el marco, el riesgo y la evidencia, no la implementación). GDPR **de ingeniería** (DPIA
como artefacto técnico, minimización en el esquema, retención implementada como borrado, derechos
del interesado como funcionalidad, transferencias por diseño, PII en telemetría) es de
`privacy-engineering-standards`: aquí solo la parte de **gestión** (ISO 27701 como PIMS, RoPA como
registro, aceptación de riesgo, evidencia de auditoría). Continuidad: el **sistema de gestión**
(ISO 22301, política, alcance, auditoría) es de aquí; el **plan y su ingeniería** (BIA, RTO/RPO,
orden de recuperación, ejercicios de DR) es de `bcdr-standards`. La gestión del incidente y la
investigación técnica son de `incident-management-standards` e
`incident-response-forensics-standards`; el ejercicio ofensivo autorizado, de
`offensive-security-standards`. `enterprise-architecture-standards` (**el marco de control, el registro de riesgo y la
evidencia de auditoría son de aquí**; **el inventario de aplicaciones con su dueño, criticidad y
ciclo de vida es suyo** — y es la fuente que alimenta el alcance de casi todo control. Un control
cuyo alcance no se puede enumerar no es auditable), `opensource-licensing-standards` (la
obligación normativa corporativa y su evidencia son de aquí; **la política de licencias, el gate y
el proceso de excepción son suyos**), `govtech-eidas-standards` (**recíproca, ya declarada desde su lado**: el **régimen eIDAS** —firma
avanzada frente a cualificada, prestador cualificado y listas de confianza, sello de tiempo, AdES
y conservación a largo plazo, expediente electrónico— y las obligaciones del procedimiento
administrativo español son **suyos**; **el ENS como marco de gestión** —Declaración de
Aplicabilidad, categorización, auditoría de certificación, registro de riesgo y relación con el
CCN— es de aquí. Regla: *si la pregunta es qué valor jurídico tiene lo que firmas, es suya; si es
qué control acredita y con qué evidencia, es de aquí*),
`accessibility-standards` (frontera con obligación
legal real: **el marco normativo aplicable, el registro de evidencia y la gestión del
riesgo sancionador son de aquí**; **la declaración de accesibilidad —su contenido, su prueba y
quién la firma— es suya** (§6.1), y este documento solo la exige como evidencia —European Accessibility Act, EN 301 549, Ley 11/2023 y su
desarrollo, ADA Título II—; **el criterio técnico de conformidad** —qué criterio WCAG se cumple,
cómo se prueba y qué lo automatiza— **es suyo**. Aviso que ambas comparten: **una nueva versión de
WCAG o de EN 301 549 no cambia por sí sola la obligación legal**, que va anclada a la norma citada
en la ley).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Situación | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| SGSI certificable | **ISO/IEC 27001:2022** + Anexo A (93 controles: 37 organizacionales, 8 personas, 14 físicos, 34 tecnológicos) con guía de implantación **27002:2022** | La transición desde 27001:2013 cerró el **31-oct-2025**: un certificado 2013 es inválido y exige recertificación completa (Stage 1+2), no transición |
| Lenguaje de gobierno y comunicación con dirección | **NIST CSF 2.0** (CSWP 29, feb-2024): funciones GOVERN/IDENTIFY/PROTECT/DETECT/RESPOND/RECOVER, 106 subcategorías, Perfiles actual/objetivo | Usar los **Tiers 1-4** como escala de madurez (miden gestión del riesgo, no madurez) |
| Baseline técnico priorizado | **CIS Controls v8.1** (jun-2024): 18 controles, 153 salvaguardas, **IG1 = 56** como mínimo innegociable | Empezar por IG3 "porque somos serios"; no existe v9 publicada a ago-2026 |
| Metodología de riesgo | **ISO/IEC 27005:2022** con enfoque **combinado**: basado en eventos (escenarios estratégicos) para el mapa, basado en activos para el detalle | Solo activos (produce inventarios, no decisiones); solo eventos (no aterriza controles) |
| Riesgo en sector público español | **MAGERIT v3** + herramienta **PILAR** del CCN (gratuita para sector público y proveedores) | El catálogo v3 (2012) no nombra cloud/SaaS/contenedores/IA: reinterpretar y documentar la equivalencia |
| Cuantificación para decidir inversión | Cualitativa 5×5 con criterios escritos por defecto; **FAIR** cuando haya que comparar coste de control vs. pérdida esperada | Matrices de colores sin definición de escala (números inventados con apariencia de rigor) |
| Assurance para clientes (mercado US/SaaS) | **SOC 2 Tipo II**, TSP sección 100 (TSC 2017 con *revised points of focus* 2022), Security obligatorio + categorías según compromisos | Tipo I como sustituto de Tipo II; tratar los *points of focus* como requisitos auditables (TSP 100.07: no lo son) |
| Sector público español y sus proveedores | **ENS, RD 311/2022**: categoría BÁSICA/MEDIA/ALTA por análisis de riesgos; **Perfiles de Cumplimiento Específicos** aprobados por el CCN (art. 30) cuando exista uno del sector | Certificar categoría MEDIA/ALTA sin entidad acreditada (básica admite declaración; media/alta exigen certificación) |
| Privacidad como sistema de gestión | **ISO/IEC 27701:2025** (14-oct-2025): PIMS **autónomo**, ya no extensión de 27001; estructura armonizada 4-10; Anexo A unificado (A.1/A.2/A.3) | Certificados 27701:2019: transición hasta **oct-2028** |
| Sistemas de IA | **ISO/IEC 42001** como SGIA; integrar con el SGSI, no duplicarlo | Tratar el riesgo de IA fuera del registro de riesgos corporativo |
| Formato de intercambio de evidencia | **OSCAL** (NIST, línea 1.1.x) cuando el consumidor lo soporte — FedRAMP exige paquetes legibles por máquina desde **30-sep-2026** | Exigir OSCAL a herramientas que solo lo soportan de nombre: probar import/export antes |

**Regulación con fecha (estado ago-2026, verificar §8):**
- **DORA** (Reglamento UE 2022/2554): en aplicación desde **17-ene-2025**. Las ESAs designaron los
  primeros **19 proveedores TIC críticos (CTPP)** el **18-nov-2025** (hyperscalers y grandes SaaS),
  bajo supervisión directa con multas coercitivas de hasta el 1% de la facturación diaria mundial.
  Como reglamento, **aplica directamente**: no depende de transposición.
- **NIS2** (Directiva UE 2022/2555): plazo de transposición vencido el **17-oct-2024**. España
  **sigue sin transponer** a ago-2026: el anteproyecto de *Ley de Coordinación y Gobernanza de la
  Ciberseguridad* (Consejo de Ministros, 14-ene-2025) continúa en tramitación; la Comisión emitió
  dictamen motivado el 7-may-2025 y un segundo requerimiento el **19-may-2026** (INFR(2024)0270).
  El RDL 7/2025 transpuso parcialmente para el sector eléctrico. Art. 23: alerta temprana **24 h**,
  notificación **72 h**, informe final **1 mes**. Art. 34: multas mínimas de **10 M€ o 2%** de
  facturación mundial (esenciales) y **7 M€ o 1,4%** (importantes) — son **suelos**, los Estados
  pueden subirlos. Art. 20: aprobación y formación **obligatoria del órgano de dirección**, con
  responsabilidad personal e inhabilitación temporal posible.
- **CRA** (Reglamento UE 2024/2847): obligaciones de notificación desde el **11-sep-2026** (alerta
  24 h, notificación 72 h, informe final 14 días/1 mes, vía *Single Reporting Platform*); aplicación
  plena el **11-dic-2027**. Alcanza a producto ya en el mercado si sigue disponible tras sep-2026.

## 3. Estructura y convenciones

**Jerarquía documental (4 niveles, sin más):**
`Política de seguridad` (1 documento, aprobado por dirección, el "qué" y el "quién responde") →
`Normas` por dominio (el "qué debe cumplirse", medible) → `Procedimientos` (el "cómo", con dueño
operativo) → `Registros/evidencias` (la prueba). Cada documento: dueño nominal, versión, fecha de
aprobación, aprobador y **fecha de próxima revisión**. Un documento sin dueño está muerto.

**Fuente de verdad = catálogo interno de controles, no los marcos.** Cada control tiene un `ID`
estable propio; los marcos son **vistas** que apuntan a él. Al revés (un fichero por norma) se
duplica el trabajo y se contradicen entre sí. Versionado en git, revisable por PR:

```yaml
# controls/CTRL-014.yaml — un control, N marcos, N evidencias
id: CTRL-014
nombre: Revisión y aprobación de cambios en producción
dueño: jefatura-plataforma          # responsable de que OPERE
frecuencia: continua
implementacion: "PR obligatorio + 1 aprobación distinta del autor + CI verde"
mapeos:                              # una evidencia sirve a varios estándares
  iso27001_2022: [A.8.32]
  nist_csf_2_0:  [PR.PS-06]
  cis_v8_1:      ["4.1"]
  soc2_tsc:      [CC8.1]
  ens_rd311:     [op.exp.5]
evidencia:
  tipo: automatizada                 # automatizada | manual — se mide el %
  fuente: "API del forge: PRs mergeados sin aprobación en el periodo"
  consulta: "scripts/evidence/prs_sin_aprobacion.py"
  periodicidad: mensual
  retencion: 24m
prueba_eficacia: "Muestra del periodo completo; 0 excepciones no justificadas"
```

**Registro de riesgos — campos obligatorios** (si falta uno, el riesgo no está gestionado):
ID · escenario en formato *fuente → evento → consecuencia* (no "hackeo") · proceso/activo afectado ·
**dueño del riesgo** (negocio, nominal, con autoridad para aceptar; distinto del dueño del control) ·
probabilidad e impacto con la escala definida · riesgo **inherente** · controles existentes ·
riesgo **residual** · decisión (mitigar/transferir/evitar/**aceptar**) · plan con responsable y
fecha · fecha de próxima revisión · enlace a la evidencia.

**SoA — el documento que más miran los auditores.** Los 93 controles del Anexo A, cada uno con:
aplicable sí/no, **justificación explícita** de inclusión *y* de exclusión, estado de implantación,
referencia al control interno (`CTRL-xxx`) y a la evidencia. Se actualiza en **cada cambio material**
del alcance o de los riesgos, no una vez al año antes de la auditoría.

**Excepciones y aceptación de riesgo:** formulario único con riesgo asociado, compensatorios,
**fecha de caducidad obligatoria (máx. 12 meses)**, aprobador según el nivel de riesgo (matriz de
autoridad escrita: quién puede aceptar qué) y revisión al vencer. Una excepción sin fecha es una
decisión de arquitectura no documentada.

## 4. Gates de calidad y cumplimiento continuo

En orden de coste creciente; los tres primeros son automáticos y rompen el pipeline:
1. **Policy as code en CI**: OPA/Conftest, Kyverno o equivalente sobre IaC y manifiestos; escaneo de
   IaC e imágenes, SBOM y **secret scanning**. Un hallazgo crítico rompe el build — y **la salida
   firmada y fechada del gate ES la evidencia**, no un pantallazo posterior.
2. **Recolección programada de evidencia**: cada control con `evidencia.tipo: automatizada` genera
   su artefacto en su periodicidad, con timestamp, origen trazable e integridad verificable (hash),
   en almacenamiento con retención y **acceso restringido**.
3. **Panel de cobertura**: controles sin evidencia en su ventana = hallazgo abierto, igual que un
   test roto. Sin panel, "cumplimos" es una opinión.
4. **Auditoría interna** (cláusula 9.3 y programa anual): planificada **por riesgo**, no por
   checklist; hallazgos con causa raíz, plan, dueño y fecha; seguimiento hasta cierre verificado.
5. **Auditoría externa / SOC 2 Tipo II**: exige evidencia **a lo largo de todo el periodo de
   observación** y muestreo del auditor. Una recolección masiva la semana previa es un hallazgo, no
   una preparación.

**Diseño vs. operación**: probar que el control *existe* (design effectiveness) no prueba que
*funciona* (operating effectiveness). Para cada control, define de antemano qué muestra y qué
umbral de desviación se considera fallo.

## 5. Seguridad del programa de cumplimiento

- **La evidencia es dato sensible**: minimiza (redacta secretos, credenciales, PII, IPs internas si
  no aportan), controla el acceso al repositorio de evidencia, cífrala y define retención. Un
  repositorio de evidencia mal protegido es un mapa de la organización para un atacante.
- **Segregación de funciones**: quien opera un control no aprueba su propia evidencia; auditoría
  interna con independencia real respecto de la función auditada.
- **Terceros (TPRM)**: tiering por criticidad y por acceso a datos, con cadencia diferenciada
  (críticos: revisión anual completa + monitorización continua; bajo riesgo: 24-36 meses).
  Cuestionarios **CAIQ** (CSA, alineado con CCM; STAR Nivel 1 autoevaluación, Nivel 2 atestación)
  para SaaS/cloud y **SIG** (Shared Assessments, ~21 dominios; SIG Lite para cribado) para el resto.
  Al recibir un SOC 2 o ISO de un proveedor: **lee el alcance, el periodo y las excepciones** — un
  certificado sin leer el alcance no dice nada. Contrato con derecho de auditoría, notificación de
  incidentes con plazos **alineados a los tuyos** (si te exigen 24 h, tu proveedor no puede darte
  72), subencargados y salida/portabilidad. En financieras, el **registro de información** DORA.
- **Los plazos regulatorios viven en el plan de respuesta a incidentes**, no en un documento de
  cumplimiento: el reloj de 24 h de NIS2/CRA arranca al *tener conocimiento*, y si hay datos
  personales corre en paralelo al de protección de datos.

## 6. Operabilidad del programa

**Métricas que se reportan a dirección** (señal, no vanidad):
% de controles con evidencia automatizada · antigüedad media de la evidencia · hallazgos abiertos
por antigüedad y severidad · **excepciones vigentes y caducadas sin revisar** · riesgos por encima
del apetito declarado · % de proveedores críticos revisados en plazo · tiempo medio de cierre de
hallazgo. La tendencia importa más que el valor absoluto.

**Cadencia mínima**: revisión del registro de riesgos trimestral (críticos) / anual (resto) ·
revisión por la dirección anual con entradas y salidas de la cláusula 9.3 · auditoría interna anual ·
SoA en cada cambio material · **radar regulatorio trimestral** (§8).

**Traducción entre marcos — el ahorro real está aquí.** Una sola evidencia bien definida cubre N
estándares: el registro de aprobación de cambios sirve simultáneamente a ISO A.8.32, SOC 2 CC8.1,
CIS 4.x, ENS op.exp.5 y CSF PR.PS-06. Mantén los mapeos en el catálogo de controles (§3) y usa las
referencias informativas oficiales (NIST **CPRT** para CSF 2.0, mapeos publicados por CIS, Anexo B
de 27002:2022) en vez de inventarlas. Cuando un mapeo sea parcial, **anótalo como parcial**: un
mapeo optimista se descubre en la auditoría, no antes.

## 7. Sostenibilidad y prohibiciones

**Ciclo de vida**: transiciones normativas con fecha en el calendario del año en que se anuncian
(ISO 27001:2013 → 2022 cerró el 31-oct-2025; 27701:2019 → 2025 cierra en oct-2028). Amd 1:2024 de
27001 obliga a **dejar registrada** la determinación sobre cambio climático en el contexto, aunque
la conclusión sea "no relevante": el auditor la pide directamente.

**PROHIBIDO**
- ❌ **Teatro de cumplimiento**: políticas de plantilla sin adaptar, procedimientos que nadie
  ejecuta, controles descritos que no existen. Es fraude documental con formato bonito.
- ❌ SoA con todo marcado "aplicable" o exclusiones sin justificación escrita.
- ❌ Riesgos sin dueño nominal, o con el dueño del control como dueño del riesgo.
- ❌ **Aceptación de riesgo verbal**, por email suelto, o firmada por quien no tiene autoridad según
  la matriz. Sin firma con nombre, fecha y caducidad, el riesgo no está aceptado: está ignorado.
- ❌ Excepciones perpetuas o renovadas automáticamente sin re-evaluar el riesgo.
- ❌ Evidencia fabricada, retroactiva o recolectada solo antes de la auditoría; pantallazo como única
  evidencia de un control que la herramienta puede exportar por API.
- ❌ Certificar un alcance recortado artificialmente para que salga barato y venderlo como cobertura
  total de la organización.
- ❌ Confundir los **Tiers** de CSF 2.0 con niveles de madurez, o los *points of focus* de SOC 2 con
  requisitos obligatorios.
- ❌ Delegar en un proveedor la **responsabilidad de dirección** de NIS2 (art. 20): es indelegable.
- ❌ Asumir que "como España no ha transpuesto NIS2, no hay nada que hacer": DORA y el CRA son
  reglamentos de aplicación directa, los contratos y clientes ya exigen NIS2, y la ley llegará con
  plazos cortos de registro.
- ❌ Enviar cuestionarios a proveedores y no leer las respuestas ni las evidencias adjuntas.
- ❌ Un fichero de control por cada marco (duplicación garantizada y contradicciones al cabo de un año).
- ❌ Cerrar un hallazgo sin verificar la corrección ni registrar la causa raíz.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato concreto, **búscalo — no lo recuerdes**. La normativa europea se
mueve por trimestres:
- **NIS2 en España**: si la *Ley de Coordinación y Gobernanza de la Ciberseguridad* se ha publicado
  en el BOE, sus plazos de registro, el reparto de autoridades competentes y las sanciones finales
  (BOE + estado del expediente INFR(2024)0270).
- **DORA**: RTS/ITS adoptados y en vigor, y la lista actualizada de **CTPP** designados por las ESAs.
- **ENS**: si el RD 311/2022 sigue vigente sin modificar, y el **Perfil de Cumplimiento Específico**
  y las guías **CCN-STIC** aplicables al sector exacto antes de dimensionar medidas.
- **CRA**: guía de la Comisión y estado de la *Single Reporting Platform* antes del 11-sep-2026.
- **ISO**: edición vigente y periodo de transición de 27001/27002/27005/27701/42001, y si hay
  revisión en curso (ISO Online Browsing Platform / web del comité).
- **CIS Controls**: versión vigente (v8.1 a ago-2026; comprobar si ha salido v9) y sus mapeos.
- **NIST**: CSF 2.0, Quick Start Guides y **CPRT** para referencias informativas actualizadas; línea
  vigente de **OSCAL** y su soporte real en las herramientas objetivo.
- **SOC 2**: si la AICPA ha publicado TSC nuevos o borradores de revisión.

Si no puedes verificar, dilo explícitamente en vez de suponer.
Si la web contradice este documento, **manda la web** y señala la discrepancia.
