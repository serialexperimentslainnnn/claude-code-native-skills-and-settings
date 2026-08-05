---
name: cms-jamstack-standards
description: Use when deciding where content lives and who edits it - choosing between Markdown/MDX files in the repo, a git-based CMS (Decap admin/config.yml, TinaCMS), self-hosted open-source headless (Strapi, Directus, Payload, Keystone), paid SaaS headless (Contentful, Sanity, Storyblok, Prismic, Hygraph) or a coupled CMS (WordPress wp-config.php and plugins, Drupal), content modeling with content types, fields, references, localization and schema migration, sanity.config.ts or contentful space migration scripts, content collections and frontmatter schemas, draft and preview modes, publish webhooks and on-demand revalidation or cache purge after publish, stale content after a publish, image CDNs and per-transformation billing (Cloudinary credits, Cloudflare Images, imgix), free-plan API-call quotas and what breaks when you exceed them, editor accounts roles and MFA, plugin supply chain, stored XSS from a rich-text editor, exposing the content API, webhook signature verification, or exporting content out of a CMS before you are locked in.
---

# Estándares de CMS y Jamstack

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Eje**: elegir **dónde vive el contenido y quién lo edita**, con el **coste y el bloqueo explícitos**
desde el primer día. No es una decisión de gusto tecnológico: es un contrato de duración indefinida con
un proveedor, un modelo de datos y un flujo de trabajo humano. **Un CMS del que no sabes salir es un
contrato indefinido**, y el precio de salida se negocia al entrar, no cuando ya duele.

Triggers: `content/**/*.md`/`*.mdx` con frontmatter, `content.config.ts` / colecciones de contenido,
`admin/config.yml` de Decap, `tina/config.ts`, `sanity.config.ts`, `strapi/config/`, `docker-compose.yml`
con Strapi/Directus, `payload.config.ts`, `keystone.ts`, `wp-config.php`, `composer.json` de Drupal,
scripts de migración de espacio de Contentful, endpoints `/graphql` o `/api/content` de un CMS, webhooks
de publicación, `revalidatePath`/`revalidateTag`/purga por tag tras publicar, URLs de un CDN de imágenes
con parámetros de transformación, cuotas de llamadas API en un plan de CMS SaaS.

**No aplica**:
- `frontend-frameworks-standards` — **el framework, el modelo de renderizado (SSG/SSR/ISR/islas) y cómo
  se cargan los datos son suyos**. Aquí **qué evento de contenido dispara qué regeneración** y cuál es el
  contrato de datos que el framework consume. Si `next/image` o `<Image>` de Astro es quien sirve la
  imagen, eso es de allí; **cuánto cuesta cada transformación en el CDN de imágenes es de aquí**.
- `frontend-web-platform-standards` — la plataforma del navegador, el HTML/CSS, el CSP y el peso de la
  página. Aquí solo el contenido que se inyecta en ellos y su saneamiento en origen.
- `design-systems-standards` — **recíproca**: el sistema de diseño aporta los componentes que pintan lo
  que este contenido dice. El modelo de contenido **no** define componentes de UI, y el sistema de diseño
  **no** define tipos de contenido. Si los tipos de contenido se llaman igual que los componentes, tienes
  un CMS acoplado a un rediseño.
- `caching-cdn-standards` — **la caché HTTP, el CDN, `Cache-Control`, las surrogate keys y la purga son
  suyos**. Aquí solo el **evento de publicación** que dispara esa purga y qué claves debe purgar.
- `api-design-standards` — **el contrato de la API de contenido** (REST/GraphQL, paginación, versionado,
  códigos de error) es suyo. Aquí qué campos expone y a quién.
- `php-standards` — **WordPress y Drupal son PHP: el código, los plugins propios, Composer y la calidad
  del código son suyos**. Aquí la **decisión de plataforma y su operación**: si se elige WordPress, cómo
  se actualiza, cómo se protege y cuándo se usa headless.
- `appsec-standards` (metodología y modelado de amenazas; aquí los controles concretos del CMS),
  `identity-access-management-standards` (**la identidad de los editores, SSO y MFA son suyos**; aquí que
  son obligatorios y con qué roles), `secrets-management-standards` (custodia de los tokens de API del
  CMS y de los secretos de webhook), `data-governance-quality-standards` (propiedad del dato y del
  glosario), `privacy-engineering-standards` (datos personales en formularios, consentimiento de
  cookies), `grc-compliance-standards`, `cicd-standards` (la pipeline que construye y despliega),
  `object-storage-standards` (dónde viven los binarios), `kubernetes-standards` (si el CMS autoalojado
  corre ahí), `observability-standards`, `backup-recovery-standards` (**la copia de la base de datos del
  CMS y su restauración probada son suyas**; aquí que el contenido entra en el alcance),
  `search-engines-standards` (buscador del sitio).

## 2. Decisiones por defecto

> Verificar la última versión, la licencia y **el precio vigente** por web antes de fijarlos (§8).
> Versiones y licencias leídas del registro npm y del `LICENSE` en crudo a **ago-2026**; precios de la
> web del proveedor. **Los precios cambian sin aviso y las fuentes secundarias se contradicen.**

### Decisión 0: ¿hace falta un CMS?

**El criterio real es de personas, no de tecnología: si quien edita no es quien despliega, hace falta
CMS.** Todo lo demás es secundario.

| Situación | Respuesta |
|---|---|
| El contenido lo escribe el mismo equipo que hace deploy, y sabe usar Git | **Ficheros en el repo**: Markdown/MDX con frontmatter tipado y un generador estático. Sin base de datos, sin proveedor, sin factura, revisable en PR, con historial y rollback gratis |
| Documentación técnica, blog de ingeniería, changelog, notas de versión | **Ficheros en el repo**, siempre. Meter un CMS aquí es añadir un proveedor para que ingenieros escriban Markdown |
| Marketing, redacción o negocio edita, y no va a abrir un PR | **CMS.** Y la discusión termina ahí: obligar a un editor no técnico a usar Git produce contenido desactualizado y un ingeniero haciendo de secretario |
| Un editor no técnico pero pocos cambios al mes, en un repo | **Git-based CMS** (Decap, Tina): interfaz de edición sobre commits. Sin base de datos y sin bloqueo — el contenido sigue siendo tuyo, en tu repo |
| Varios idiomas, flujos de aprobación, programación de publicación, muchos editores concurrentes | **CMS de verdad** (headless o acoplado). Un git-based CMS no sostiene concurrencia ni workflow |
| Contenido consumido por web **y** app móvil **y** otro canal | **Headless**, por definición |
| "Puede que algún día lo edite marketing" | **No es un argumento.** Migrar de ficheros a CMS es fácil (el contenido está estructurado y es exportable). Salir de un CMS SaaS es lo caro |

### Taxonomía y criterio de elección

| Modelo | Ejemplos | Elígelo cuando | El coste real |
|---|---|---|---|
| **Contenido en el repo** | Markdown/MDX + colecciones tipadas del framework | Escriben técnicos; contenido versionado con el código | Cero editor visual, cero flujo de aprobación, cero concurrencia |
| **Git-based** | Decap, Tina | Un editor no técnico y volumen bajo; quieres cero bloqueo | Cada publicación es un commit → un build. Sin borradores concurrentes ni workflow serio |
| **Headless open source autoalojado** | Strapi, Directus, Payload, Keystone | Control del dato, requisitos de residencia, coste predecible, modelo de contenido a medida | **Tú operas el servicio**: base de datos, backups, parches, escalado, uptime. No es gratis, es "pagado en operación" |
| **Headless SaaS** | Contentful, Sanity, Storyblok, Prismic, Hygraph | Quieres cero operación, disponibilidad y CDN de contenido incluidos | Factura que crece con el tráfico, límites que rompen el sitio al superarse, y bloqueo en un modelo de contenido propietario |
| **Acoplado / tradicional** | WordPress, Drupal | El contenido *es* el producto; editores acostumbrados; ecosistema de plugins ya resuelve el requisito | Superficie de ataque grande y mantenimiento continuo obligatorio (§5) |

**Regla de honestidad**: "open source autoalojado" no significa gratis, significa que **el coste está en
tu equipo de operaciones**, y "SaaS" no significa sin coste de ingeniería, significa que **el coste está
en la factura y en la salida**.

### Estado verificado a ago-2026 — licencias y modelo de precio

| Producto | Versión | Licencia | Modelo de precio y límites |
|---|---|---|---|
| **Strapi** | `@strapi/strapi` **5.51.1** | **Dual, leído del `LICENSE`**: lo que está fuera de `ee/` es **MIT**; todo lo que reside bajo un directorio `ee/` es **Enterprise Edition con licencia propietaria**. "Strapi es MIT" es media verdad | Community self-hosted sin límite de llamadas ni de contenido; las funciones de equipo (Releases, Content History, SSO, audit logs, review workflows) son de pago. Growth citado en **$45/mes con 3 asientos, +$15/asiento**; SSO como add-on aparte. Enterprise a medida. **Verificar en strapi.io** |
| **Directus** | **12.2.0** | ⚠️ **Ya no es open source**: **Monospace Sustainable Core License (MSCL-1.0-GPL)**, copyright 2026 Monospace Inc. Source-available, derivada de la Fair Core License. Prohíbe el *Competing Use*; **cada versión pasa a GPLv3 a los 4 años**. Prohíbe además desactivar o eludir la comprobación de la clave de licencia | Uso comercial gratuito solo bajo la **Open Innovation Grant** (verificado: **<$5M de ingresos anuales y <50 empleados**), o dentro de los límites del *free core tier*; por encima, licencia de pago con clave. **Los SDK siguen siendo MIT.** Este cambio (v12) es el hallazgo más caro de esta tabla: **si tu empresa supera los umbrales, Directus deja de ser gratis** |
| **Payload** | **3.87.0** | **MIT** | Autoalojado gratis. **Cambio de propiedad verificado: Figma adquirió Payload (jun-2025)**; el equipo entró en Figma, la licencia MIT y el repo siguen. **Payload Cloud cerró altas nuevas**: si contabas con su hosting gestionado, no es opción. El riesgo a nombrar es el patrón "adquirido y luego desatendido"; MIT limita el peor caso pero no obliga a nadie a mantenerlo |
| **Keystone** | `@keystone-6/core` **8.0.2** | **MIT** (Thinkmill) | Autoalojado gratis. **Keystone 5 está en modo mantenimiento**; la línea viva es la 6. Proyecto de una sola consultora: nombra esa dependencia antes de elegirlo |
| **Decap CMS** | `decap-cms-app` **3.15.1** | **MIT** | Gratis. Mantenido por la comunidad tras el traspaso desde Netlify (2023): **vivo pero de baja velocidad**. Sin base de datos y sin bloqueo — el contenido son ficheros de tu repo |
| **Tina** | `tinacms` **3.11.0** | **Apache-2.0**, no MIT | Editor sobre Git; el backend gestionado (Tina Cloud) es de pago con plan gratuito. Autoalojable |
| **Contentful** | SDK `contentful` **11.12.7** (MIT) | Servicio propietario | ⚠️ **Verificado en su propio changelog (anunciado 2025-12-09): al alcanzar el límite mensual de ancho de banda de assets o de API, el plan Free hace que Contentful "automatically pause delivery APIs (CDA, CPA, GraphQL)" hasta el mes siguiente o hasta que se pase a plan de pago.** No hay overage: **el sitio deja de servir contenido**. El salto al primer plan de pago es de miles de euros al año |
| **Sanity** | SDK `@sanity/client` **7.26.0** (MIT) | Servicio propietario, con Studio open source | Precio **por uso**: al superar lo incluido **no te corta, te factura**. Es el modelo más benigno para disponibilidad y el más peligroso para el presupuesto. **Alertas de uso obligatorias desde el día uno** |
| **Storyblok** | SDK `@storyblok/js` **6.3.0** (MIT) | Servicio propietario | Factura por **asientos + idiomas + llamadas a la CDN + espacios**. En los planes bajos, superar el límite **estrangula la API**: degradación silenciosa del sitio sin que nadie reciba una factura ni una alerta |
| **Prismic / Hygraph** | — | Servicio propietario | Planes gratuitos con **cuota dura**; al agotarse, el servicio para. El primer escalón de pago es un salto grande. Verificar cifras en su web |
| **WordPress** | **7.0.2** (verificado en `api.wordpress.org`) | GPLv2+ | Núcleo gratis; el coste está en hosting, plugins premium y **mantenimiento continuo** (§5). Ver el apartado propio |
| **Drupal** | **11.4.4**; ramas soportadas **10.6, 11.3, 11.4** | GPLv2+ | Gratis; coste en operación y en actualizaciones de major, que son proyectos, no tareas |

**Los tres comportamientos al superar el límite** — es el criterio de selección que más gente descubre
tarde. Elige sabiendo cuál de los tres puedes tolerar:

| Comportamiento | Quién | Consecuencia |
|---|---|---|
| **Corte duro** | Contentful (Free), Prismic (Free) | El sitio deja de servir contenido. Incidente de producción provocado por una factura |
| **Estrangulamiento silencioso** | Storyblok (planes bajos) | El sitio se degrada y nadie se entera hasta que alguien se queja |
| **Overage facturado** | Sanity, planes de pago de la mayoría | El sitio sigue en pie y la sorpresa llega en la factura |

Sea cual sea: **alerta de uso al 70% de cada cuota**, y el número de llamadas a la API del CMS es una
métrica de producción con umbral, no una curiosidad del panel del proveedor.

### WordPress: tratamiento propio por cuota de mercado

Es la plataforma más usada de la web (~42% de los sitios según W3Techs, mar-2026) y por eso la más atacada.
Decidir sobre WordPress requiere mirar tres cosas que se suelen omitir:

- **Gobernanza — hecho verificable, sin tomar partido.** Desde oct-2024 hay un **conflicto público y un
  litigio abierto entre WP Engine y Automattic/Matt Mullenweg**, todavía activo en 2026 (medida cautelar
  a favor de WP Engine en dic-2025; demanda enmendada en feb-2026; disputas de *discovery* y moción de
  sanciones en jul-2026; conversaciones de acuerdo en curso). Estructuralmente: **wordpress.org no tiene
  órgano de gobierno formal ni consejo de supervisión**, y la marca la tiene la WordPress Foundation con
  licencia comercial exclusiva a Automattic. Un intento de reforma hacia una fundación independiente se
  quedó sin financiación en 2026.
  **Consecuencia de ingeniería, no de opinión**: el ecosistema depende de decisiones de una sola persona
  sin proceso público. Eso es un **riesgo de proveedor** que se escribe en el registro de riesgos junto
  al plan de contingencia (fork, salida a otro CMS, hosting alternativo). No es motivo automático para
  descartar WordPress; **es motivo para no fingir que es un proyecto con gobierno neutral**.
- **Superficie de ataque.** Datos verificados del informe *State of WordPress Security in 2026* de
  Patchstack (publicado feb-2026, sobre datos de 2025): **11.334 vulnerabilidades nuevas en el ecosistema
  (+42% interanual)**, de las cuales **~91% en plugins y ~9% en temas**, con **una cifra mínima en el
  núcleo y de riesgo bajo**. El **70% de las explotadas se explota en los 7 primeros días** y una parte
  significativa en las primeras horas; las defensas del hosting bloquearon una fracción pequeña.
  **Lectura correcta: el núcleo de WordPress no es el problema; tus plugins sí.** Cada plugin es una
  dependencia con permisos de administrador en tu sitio.
- **Disciplina de actualización, no negociable si eliges WordPress**: núcleo con actualizaciones menores
  automáticas activadas; parches de plugins **en menos de 24-48 h** para severidad alta, con ventana de
  emergencia definida; entorno de *staging* con clon de producción; inventario de plugins con dueño y
  justificación; **retirada** (no desactivación) de todo lo que no se use; y suscripción a una fuente de
  advisories del ecosistema. Un sitio WordPress sin alguien responsable de aplicar parches semanalmente
  es un incidente pendiente de fecha.
- **Cuándo usarlo headless**: cuando el equipo editorial ya vive en WordPress y no lo vas a mover, pero
  la capa de presentación necesita ser otra cosa. Aporta: el frontend deja de ejecutar PHP y de exponer
  temas y plugins al visitante. **No aporta**: el backend de administración sigue expuesto, sigue siendo
  el mismo objetivo y sigue necesitando el mismo mantenimiento. **Headless no es una medida de seguridad**;
  es una separación de capas que reduce la superficie *pública*, no la real.

## 3. Estructura y convenciones

### Modelado de contenido: un esquema de contenido es un esquema de datos

Y por tanto **se diseña, se versiona y se migra igual que un esquema de base de datos**. El error caro es
tratarlo como configuración que se toca en una interfaz web sin dejar rastro.

- **Modela por significado, no por aspecto.** Un tipo `Página` con campos `bloque1`, `bloque2`,
  `colorDeFondo`, `columnaIzquierda` es un editor de HTML disfrazado: el contenido queda inservible para
  un segundo canal y muere con el próximo rediseño. Los nombres de campo describen **qué es** el dato
  (`resumen`, `fechaDePublicacion`, `autor`), nunca **dónde se pinta**.
- **Referencias en vez de duplicados.** Autor, categoría o producto son entidades referenciadas. Copiar
  el nombre del autor en cada artículo garantiza que 200 artículos queden mal el día que se casa.
- **Campos obligatorios y validados en el CMS**, no solo en el frontend: longitud de título, texto
  alternativo de imagen obligatorio, formato de fecha. **El texto alternativo es campo requerido**, no una
  sugerencia — es la única forma de que la accesibilidad del contenido no dependa de la buena voluntad
  (el criterio de conformidad es de `accessibility-standards`).
- **El esquema vive en código y en control de versiones** (`sanity.config.ts`, tipos de Strapi/Payload,
  scripts de migración de espacio de Contentful). Un esquema que solo existe en la interfaz web del
  proveedor no se puede revisar, ni diferenciar entre entornos, ni recrear tras un desastre.
- **Migraciones de contenido con script, idempotentes y reversibles**, ejecutadas primero en un entorno de
  preproducción con una copia del contenido real. Renombrar un campo en producción "porque es rápido" es
  cómo se pierde contenido sin que nadie lo note hasta semanas después.
- **Localización decidida al principio**: campo traducible vs. entrada por idioma vs. árbol por región.
  Cambiar de estrategia después es una migración completa. Y ojo: **en varios SaaS los idiomas son un eje
  de facturación**, así que la decisión de modelado es también una decisión de coste.
- El contenido enriquecido se guarda en un formato **estructurado y portable** (AST/Portable Text/bloques),
  no en HTML crudo. HTML almacenado es contenido acoplado a un diseño y una fuente de XSS almacenado (§5).
- Ficheros en el repo: frontmatter con **esquema validado en build** (colecciones tipadas del framework).
  Un campo mal escrito debe romper el build, no aparecer vacío en producción.

### Publicación, generación y el problema real: la invalidación de caché

**Aquí falla la mayoría.** Publicar es fácil; hacer que el cambio aparezca —y solo donde debe— es lo
difícil. El evento de publicación es un evento de sistema distribuido con todos sus problemas.

- Elige la estrategia por tipo de página, no por sitio (el modelo de renderizado es de
  `frontend-frameworks-standards`; aquí **qué lo dispara**):
  - **SSG con rebuild completo**: correcto mientras el build dure minutos, no horas. Con miles de páginas
    deja de serlo y nadie lo revisa hasta que publicar tarda 40 minutos.
  - **Revalidación bajo demanda / purga por tag desde webhook**: el default para un sitio con contenido
    que cambia a lo largo del día. Requiere **mapear cada entrada de contenido a las rutas y claves de
    caché que afecta** — y ese mapeo es la parte que se olvida.
  - **ISR / revalidación por tiempo**: aceptable como red de seguridad **detrás** de la purga, nunca como
    único mecanismo: significa aceptar contenido obsoleto durante la ventana.
- **La página del artículo no es la única afectada**: el índice, la home, el feed RSS, el sitemap, las
  páginas de categoría, los "relacionados" y la navegación. **Purgar solo la URL editada es el bug
  clásico** — el editor ve su cambio y jura que la home está rota.
- **Purga por tag/surrogate key, no por URL** siempre que el CDN lo permita (la mecánica es de
  `caching-cdn-standards`). Por URL no escala y siempre falta una.
- **Un despublicado y un borrado deben purgar igual que una publicación**, y devolver 404/410 —no una
  página cacheada. Es el caso que nadie prueba y el que acaba en incidente legal cuando lo despublicado
  era un precio o una nota de prensa.
- El webhook **falla**: reintentos con backoff, **cola con reintento manual** y una **reconciliación
  periódica** (revalidación programada de todo lo publicado en las últimas N horas). Un sistema de
  publicación cuyo único camino feliz es "el webhook llegó" produce el ticket "publiqué y no sale".
- **Feedback al editor**: la interfaz debe decir si el cambio ya está en producción. Sin eso, el editor
  publica cinco veces, dispara cinco builds y llama a soporte. Es la causa número uno de facturas de
  build infladas.
- Deduplica y agrupa: veinte cambios en un minuto no son veinte rebuilds. Debounce en el receptor del
  webhook.

### Previsualización y borradores

- **La previsualización usa contenido en borrador y datos reales**, en una URL no indexable y **detrás de
  autenticación o de un token firmado y de vida corta**. Una URL de preview adivinable es una filtración
  de embargo — el caso típico es la nota de resultados o el lanzamiento de producto.
- `X-Robots-Tag: noindex` en todo lo que sea preview, y comprobado. Una preview indexada es contenido
  duplicado y a veces contenido confidencial en un buscador.
- La preview **nunca se sirve desde la caché pública** ni comparte clave de caché con la producción: es la
  vía directa a que un borrador aparezca a un usuario anónimo.
- Contenido programado: la publicación futura la ejecuta un trabajo del sistema, y **debe purgar caché al
  activarse**. Contenido "publicado a las 9:00" que aparece a las 11:00 porque nadie invalidó es el mismo
  bug de siempre con otro disfraz.

### Imágenes y activos

- Los binarios no viven en la base de datos del CMS ni en el repo Git (ver `object-storage-standards`).
  En el repo, además, un `.psd` o un vídeo envenenan el historial para siempre.
- **El CDN de imágenes se factura por transformación, por almacenamiento y por entrega, y las tres
  cuentan.** Verificado a ago-2026 (**precios volátiles: confirmar en la web del proveedor, §8**):
  - **Cloudflare Images**: primeras **5.000 transformaciones únicas/mes incluidas**, después **$0,50 por
    1.000**; almacenamiento **$5 por 100.000 imágenes/mes**; entrega **$1 por 100.000/mes**. En plan Free,
    superado el límite se siguen sirviendo las transformaciones ya cacheadas y **las nuevas devuelven
    error 9422** — degradación parcial, sin cargo.
  - **Cloudinary**: sistema de **créditos** fungibles (1 crédito ≈ 1.000 transformaciones **o** 1 GB de
    almacenamiento **o** 1 GB de entrega). Free citado en **25 créditos/mes**. Al ser un único bote, **lo
    que más consumas se come la cuota**, y normalmente es el ancho de banda.
  - **imgix**: migrado a un modelo **de créditos** (antes por *origin images*); overage citado al 120% del
    precio por crédito y posibilidad de bloqueo al alcanzar el límite.
  - Consecuencia de diseño: **el conjunto de variantes es un presupuesto.** Cada tamaño × formato × recorte
    es una transformación facturable. Fija una lista **cerrada** de anchos y formatos, no generes variantes
    desde parámetros de URL abiertos al público, y **cachea agresivamente** — una URL de transformación
    sin caché se paga cada vez.
  - **Nunca aceptes parámetros de transformación desde la URL sin allowlist ni firma**: es a la vez una
    factura abierta a cualquiera y un vector de amplificación.
- Formatos y `srcset` los decide `frontend-web-platform-standards`; los umbrales de peso,
  `web-performance-standards`. Aquí: que el CMS **obligue** a subir un original de calidad suficiente y
  registre dimensiones y texto alternativo.

### Migración y salida: probada, no supuesta

- **Antes de firmar**, comprueba: ¿existe API de exportación completa (contenido, assets, referencias,
  versiones, borradores y traducciones)? ¿está limitada por cuota? ¿el formato es reutilizable o es un
  volcado propietario?
- **Ejecuta la exportación completa en la fase de evaluación**, no cuando quieras irte. Si no puedes
  exportarlo el primer mes, no vas a poder el tercer año.
- **Exportación automatizada y periódica a almacenamiento propio** desde el día uno, con la misma
  disciplina que un backup: verificada y con restauración probada (ver `backup-recovery-standards`). Un
  CMS SaaS **no es tu copia de seguridad** — su SLA cubre su servicio, no tu derecho a llevarte el dato.
- Lo que ata de verdad no es la API: son los **campos propietarios, el formato de texto enriquecido, las
  transformaciones de imagen incrustadas en URLs del proveedor y el modelo de referencias**. Minimiza el
  acoplamiento manteniendo una **capa de mapeo** entre la respuesta del CMS y el modelo que usa tu
  aplicación. Sin esa capa, cambiar de CMS es reescribir el frontend.
- Escribe el **coste y el plazo estimados de salida** en la decisión inicial. Si nadie sabe decirlo, aún
  no has evaluado el proveedor.

## 4. Calidad y gates de CI

En orden de coste creciente; cada uno rompe el build o el despliegue:

1. **Validación del esquema de contenido**: frontmatter/colecciones tipadas, campos obligatorios
   presentes, referencias resolubles. Contenido inválido **rompe el build**, no se degrada en silencio.
2. **Enlaces internos y activos**: un enlace roto o una imagen ausente es un defecto de contenido
   detectable en CI. Enlaces externos, en un job programado aparte (fallan por causas ajenas).
3. **Migraciones de esquema**: se ejecutan contra una copia del contenido de producción en
   preproducción antes de tocar producción, con reversión probada.
4. **Prueba del camino de publicación** —el que nadie prueba y el que siempre falla—: publicar en
   preproducción y verificar automáticamente que (a) la página aparece, (b) **el índice y la home se
   actualizan**, (c) un despublicado deja de servirse y devuelve 404/410, (d) un fallo del webhook se
   recupera por reconciliación.
5. **Preview**: verificar que una URL de preview **no** es accesible sin token y **no** es indexable.
6. **Presupuesto de build**: duración del build y número de builds por publicación medidos. Si publicar
   un typo cuesta 30 minutos de build, la estrategia de generación está mal elegida.
7. **Cuotas del proveedor**: llamadas a la API, ancho de banda y transformaciones de imagen contra el
   límite del plan, con alerta al 70%.

## 5. Seguridad: el CMS es la superficie de ataque más común de un sitio corporativo

Un sitio estático sin CMS tiene una superficie mínima. En cuanto hay CMS, aparece un panel de
administración expuesto a Internet, cuentas humanas, un editor que acepta HTML y un ecosistema de plugins.
Es, con diferencia, el componente por el que entran.

- **Cuentas de editor con MFA obligatorio y SSO** cuando exista la organización que lo permita (la
  identidad es de `identity-access-management-standards`). Los ataques a WordPress y a paneles de CMS son
  masivamente de credenciales: fuerza bruta, reutilización y phishing al equipo de marketing, que no
  recibe la formación de seguridad que recibe el de ingeniería.
- **Roles mínimos y revisados**: el editor edita, no instala plugins ni cambia el esquema ni ve la
  configuración. **Nadie trabaja a diario con la cuenta de administrador.** Revisión trimestral de cuentas
  y **baja inmediata al salir de la empresa o de la agencia** — las cuentas de agencias externas son el
  agujero que sobrevive años a la relación comercial.
- **Panel de administración no expuesto públicamente** cuando sea viable: restricción por IP, VPN o
  autenticación previa en el borde. Si tiene que ser público, entonces MFA, rate limiting y bloqueo de
  fuerza bruta son obligatorios.
- **Plugins y extensiones son cadena de suministro con privilegios de administrador.** Regla: inventario
  con dueño y justificación por plugin, mínimo posible, ninguno sin mantenimiento reciente, ninguno
  "nulled"/pirata jamás, y **eliminados** (no desactivados) los que no se usan — un plugin desactivado
  sigue siendo código en el disco y ha sido vector real de explotación. Datos de §2: **~91% de las
  vulnerabilidades del ecosistema WordPress están en plugins**, y buena parte se explota en horas.
- **XSS almacenado desde el editor de texto enriquecido**: es la vulnerabilidad estructural de todo CMS.
  El editor guarda HTML y alguien lo pinta. Controles: guardar **formato estructurado, no HTML**;
  **sanear en el servidor al guardar y al servir** (nunca solo en el cliente, nunca solo una vez);
  allowlist de etiquetas y atributos, no denylist; y **prohibido incrustar `<script>`, `<iframe>` u
  `onerror` desde el editor** — si de verdad hace falta un embed, es un tipo de campo específico con
  proveedores en allowlist, no HTML libre. Un editor con privilegios no es un usuario de confianza: es
  una cuenta que puede ser robada.
- **Subida de ficheros**: validación por **contenido real**, no por extensión ni por `Content-Type`;
  allowlist de tipos; nombre generado por el sistema; almacenamiento **fuera de la raíz web** o en
  almacenamiento de objetos con **ejecución deshabilitada**; `Content-Disposition: attachment` y
  `X-Content-Type-Options: nosniff` al servir; límite de tamaño; y **SVG tratado como código ejecutable**
  (sanitizado o directamente prohibido). Un directorio de subidas que ejecuta PHP es la vía clásica a RCE.
- **Exposición de la API de contenido**: el token de lectura que va al frontend es público de facto — que
  sea **de solo lectura, solo del contenido publicado y de un único entorno**. **Nunca un token de
  escritura o de gestión en el cliente ni en el bundle.** Y comprueba qué devuelve la API de verdad:
  muchas exponen borradores, campos internos, correos de autores o el esquema completo si se pide bien.
- **Secretos de webhook con firma verificada**, sin excepción: HMAC con secreto compartido, **comparación
  en tiempo constante**, validación de la marca de tiempo para rechazar reenvíos, y **rechazo por defecto**
  si no hay firma válida. Un endpoint de revalidación sin firma es un DoS gratuito contra tu build y tu
  CDN, y a veces algo peor. Los secretos, en `secrets-management-standards`; rotación incluida.
- **Separación de entornos**: el CMS de producción no comparte credenciales ni base de datos con el de
  preproducción, y el contenido de prueba no llega a producción. Copiar producción a preproducción
  arrastra datos personales: anonimiza (`privacy-engineering-standards`).
- **Formularios y comentarios** son entrada no confiable en el sitio público: rate limiting, protección
  anti-spam, validación en servidor y, si recogen datos personales, base legal y retención
  (`privacy-engineering-standards`).
- **Copia de seguridad del contenido y de la base de datos con restauración probada**
  (`backup-recovery-standards`). El escenario realista no es la caída del disco: es un editor que borra
  200 entradas o un compromiso que las modifica.

## 6. Coste operativo, caché y caídas

- **El coste tiene cinco ejes y todos crecen con el éxito**: llamadas a la API del CMS, ancho de banda del
  CDN, transformaciones de imagen, **minutos de build** y **asientos de editor**. Los asientos y los
  idiomas son los que más sorprenden porque crecen por decisiones de negocio, no de tráfico.
- **Modela el coste al doble del tráfico previsto antes de firmar.** Si a 2× el plan se vuelve inasumible,
  ya sabes la fecha de tu migración forzosa.
- **Alertas de uso al 70% de cada cuota**, con dueño. Descubrir el límite porque el sitio dejó de servir
  contenido es un fallo de operación, no del proveedor.
- **La caché es lo que te salva de la factura y de la caída a la vez**: si el frontend consulta la API del
  CMS en cada petición de usuario, estás pagando por cada visita y tu disponibilidad es la del CMS. El
  contenido publicado se sirve **desde HTML generado o desde caché del borde**, no desde el CMS en
  caliente. La política concreta es de `caching-cdn-standards`.
- **Qué se rompe cuando el proveedor cae** — esto se decide de antemano:
  - Sitio **estático generado**: no se rompe nada visible. Solo deja de poder publicarse. **Es el argumento
    de disponibilidad más fuerte a favor de generar**.
  - Sitio con **fetch en tiempo de render**: cae con el proveedor. Mitigación obligatoria: `stale-if-error`
    en el borde, timeouts cortos, y **una copia local del último contenido bueno** para servir degradado.
  - **Imágenes**: si el CDN de imágenes cae y tus URLs apuntan a él, el sitio se ve roto aunque el HTML esté
    servido. Considera dominio propio delante para poder repuntar.
  - **Preview y panel de edición**: caen. Aceptable — no es tráfico de usuario final.
- Un fallo de publicación **no puede tumbar el sitio**: el contenido anterior sigue servido. Si un webhook
  malformado puede vaciar la caché entera, tienes un botón de autodestrucción expuesto.
- Instrumenta: latencia y errores de la API del CMS, tasa de éxito de webhooks, retraso entre publicar y
  aparecer (**el SLI real del sistema editorial**), duración y número de builds, y consumo frente a cuota.

## 7. Sostenibilidad y prohibiciones

- **Revisa el proveedor cada 12 meses**: precio, licencia, propiedad y cambios en el plan. Verificado en
  esta misma ola que en menos de dos años cambiaron **la licencia de Directus** (v12, deja de ser open
  source), **la propiedad de Payload** (Figma) con cierre de altas en su nube, y **la política del plan
  gratuito de Contentful** (pausa de las APIs de entrega).
- Actualizaciones del CMS autoalojado: parches de seguridad **inmediatos**; majors planificados como
  proyecto con migración de esquema y pruebas. Un CMS autoalojado dos majors por detrás es una brecha
  esperando fecha.
- El contenido sobrevive al sitio: **la exportación periódica a formato propio** es el seguro de vida del
  proyecto y se prueba, como un backup.

**PROHIBIDO:**
- ❌ Meter un CMS cuando quien edita es quien despliega. Documentación y blogs técnicos van en el repo.
- ❌ Elegir un CMS SaaS **sin haber leído qué pasa al superar cada cuota** y sin modelar el coste a 2× el
  tráfico. Verificado: Contentful **pausa las APIs de entrega** en el plan Free; Storyblok **estrangula**
  en los planes bajos; Sanity **te factura el exceso**.
- ❌ Afirmar la licencia de un CMS de memoria. Verificado a ago-2026: **Directus ya no es open source**
  (MSCL-1.0-GPL, gratis solo bajo la Open Innovation Grant: <$5M de ingresos y <50 empleados), **Strapi es
  dual** (`ee/` es propietario) y **Tina es Apache-2.0**.
- ❌ Adoptar un CMS sin ejecutar **una exportación completa del contenido** durante la evaluación.
- ❌ Modelar el contenido por su aspecto (`bloque1`, `columnaIzquierda`, `colorDeFondo`) en vez de por su
  significado. Y ❌ duplicar entidades en vez de referenciarlas.
- ❌ Cambiar el esquema de contenido directamente en la interfaz de producción, sin script, sin versionar
  y sin ensayo en preproducción.
- ❌ Purgar solo la URL editada: el índice, la home, el feed, el sitemap y las categorías también cambian.
- ❌ Que el único mecanismo de frescura sea "el webhook llegó". Sin reintentos, cola y reconciliación
  programada, hay contenido obsoleto garantizado.
- ❌ Despublicar o borrar sin purgar caché y sin devolver 404/410.
- ❌ URL de previsualización sin token de vida corta, sin `noindex` o servida desde la caché pública.
- ❌ Token de escritura o de gestión del CMS en el cliente, en el bundle o en el repositorio.
- ❌ Endpoint de revalidación o de webhook **sin verificación de firma** (HMAC, comparación en tiempo
  constante, marca de tiempo). Y ❌ aceptarlo "porque la URL es secreta".
- ❌ Guardar HTML crudo del editor de texto enriquecido y pintarlo sin sanear en el servidor. ❌ Permitir
  `<script>`, `<iframe>` u `on*` desde el editor.
- ❌ Subidas validadas por extensión o por `Content-Type`; directorio de subidas con ejecución habilitada;
  SVG servido sin sanear.
- ❌ Cuentas de editor sin MFA; editores con rol de administrador "porque es más cómodo"; cuentas de
  agencias externas que sobreviven al contrato.
- ❌ Plugin de WordPress/Drupal sin dueño ni justificación, sin mantenimiento reciente, o "nulled".
  ❌ Dejar plugins desactivados en el servidor en vez de eliminarlos.
- ❌ Operar WordPress sin alguien responsable de aplicar parches en 24-48 h. ❌ Vender "headless" como si
  fuera una medida de seguridad del backend.
- ❌ Consultar la API del CMS en cada petición de usuario sin caché: pagas por visita y heredas su
  disponibilidad.
- ❌ Generar variantes de imagen desde parámetros de URL abiertos, sin allowlist ni firma: es una factura
  abierta a cualquiera.
- ❌ Tratar el CMS SaaS como copia de seguridad del contenido.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar online (registro npm y feeds Atom `https://github.com/OWNER/REPO/releases.atom`
— **`api.github.com` da 403 sin autenticar**; **web oficial del proyecto y del proveedor para contrastar**,
porque el feed de GitHub **no es la fuente de verdad**; `LICENSE` en crudo para licencias; **página de
precios del proveedor** para el coste, nunca un agregador):

1. **Licencias, una por una y del `LICENSE` en crudo**: Directus (¿sigue MSCL?, ¿han cambiado los umbrales
   de la Open Innovation Grant?), Strapi (¿qué queda fuera de `ee/`?), Payload, Keystone, Decap, Tina.
   **Este es el dato que más ha cambiado en este dominio.**
2. **Propiedad y estado del proyecto**: Payload bajo Figma (¿sigue mantenido?, ¿reabrió Payload Cloud?),
   Keystone (¿la 6 sigue activa o siguió a la 5 al mantenimiento?), Decap (velocidad real de commits, no
   el badge).
3. **Precio y límites del plan gratuito, y qué pasa al superarlos**, en la web del proveedor: Contentful,
   Sanity, Storyblok, Prismic, Hygraph, Strapi Growth/Cloud, Tina Cloud. Confirmar en particular si
   Contentful mantiene la pausa de CDA/CPA/GraphQL en el plan Free.
4. **Versiones**: WordPress (`https://api.wordpress.org/core/version-check/1.7/` da la vigente y el PHP
   mínimo) y Drupal (`https://updates.drupal.org/release-history/drupal/current` da las ramas soportadas
   y la EOL de la 10).
5. **Estado del litigio y de la gobernanza de WordPress**: fuentes primarias (registro judicial, notas de
   las partes). **Sin tomar partido**: el dato que importa es si el riesgo de proveedor cambió.
6. **Datos de vulnerabilidades del ecosistema**: informe anual de Patchstack/Wordfence del año en curso, y
   advisories de los plugins concretos que tengas instalados.
7. **Precios de CDN de imágenes** (Cloudflare Images, Cloudinary, imgix, ImageKit, bunny.net): cambian de
   modelo, no solo de precio — imgix ya migró de *origin images* a créditos.
8. **CVEs del CMS elegido** (`github.com/advisories`, osv.dev, boletines del proyecto) antes de cada
   despliegue y de forma continua.

**Huecos no verificados a ago-2026** (no rellenar de memoria):
- **Cifras exactas del plan Free de Contentful** (llamadas API/mes, ancho de banda, usuarios): **no
  verificadas** — las fuentes secundarias se contradicen abiertamente (100K vs. 1M llamadas). Lo que **sí**
  está verificado en fuente primaria es el **comportamiento al superarlo** (pausa de CDA/CPA/GraphQL).
- **Precios de Strapi Growth/Enterprise, Sanity, Storyblok, Prismic e Hygraph**: **no verificados en fuente
  primaria**; las cifras citadas en §2 vienen de análisis de terceros y deben confirmarse en la web del
  proveedor antes de presupuestar.
- **Límites exactos del *free core tier* de Directus** (por encima de la Open Innovation Grant): **no
  verificados**. Sí verificados en su `LICENSE` y en su anuncio: la licencia MSCL, la conversión a GPLv3 a
  los 4 años y los umbrales de la Grant (<$5M, <50 empleados).
- **Precio y créditos actuales de Cloudinary e imgix**: **no verificados en fuente primaria** (los de
  **Cloudflare Images sí** provienen de su documentación oficial).
- **Estado de mantenimiento real de Keystone 6 y de Decap**: **no verificado** más allá de la fecha del
  último release. Mira commits, issues cerradas y respuesta a advisories, no descargas.
- Cuota de mercado de WordPress (~42%, W3Techs mar-2026): **cifra de tercero**, no re-verificada.
- Coste real de operar un headless autoalojado (base de datos, backups, HA, guardia): **depende de tu
  organización**; la tabla de §2 no lo estima.

**Discrepancias declaradas**:
- **Núcleo de WordPress en el informe de Patchstack 2026**: unas coberturas citan **seis** vulnerabilidades
  en el núcleo en 2025 y otras **dos**; la propia estadística en vivo de 2026 muestra **0** en núcleo y un
  reparto plugins/temas distinto al del informe anual (~80/20 frente a 91/9). **La conclusión no cambia**
  —el riesgo está en plugins, no en el núcleo— pero **no cites la cifra exacta sin ir al informe**.
- **Versión de WordPress**: múltiples trackers de terceros seguían listando 6.8 o 6.9.x como vigente en
  2026. **`api.wordpress.org` devuelve 7.0.2**: manda la API oficial.
- **Precio de entrada de Contentful tras el plan Free**: las fuentes citan $300/mes y "mínimo $3.600/año"
  como el mismo salto; **no resuelto**. Manda contentful.com/pricing.
- **Directus**: buena parte de la documentación y de los artículos de terceros siguen describiéndolo como
  "open source" o bajo BSL. **El fichero `license` del repositorio dice MSCL-1.0-GPL, copyright 2026
  Monospace Inc.** Manda el fichero.
- **Decap**: hay listicles que lo dan por abandonado; el registro muestra releases en 2026. Esas listas
  suelen ser marketing de un competidor — contrasta con el repositorio.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
