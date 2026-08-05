---
name: usuario-maxima-paralelizacion
description: El usuario quiere máxima paralelización y continuidad sin pedir permiso; el coste de tokens no es criterio
metadata: 
  node_type: memory
  type: feedback
  originSessionId: eee8c4df-ddc8-4b90-a384-7e95178ea6bc
  modified: 2026-08-03T17:37:13.311Z
---

En trabajo largo el usuario quiere que **siga sin pedir confirmación entre fases** y con la máxima
paralelización posible. Dicho por él: *"no te preocupes por el token usage"*, *"a saco"*, y ante un
análisis de coste de índice del catálogo (~29k tokens por turno a 267 skills): **"me la suda el
coste"** — decisión tomada y **cerrada, no volver a plantearla**.

**Why:** tiene suscripción Max x20 y su `CLAUDE.md` ya fija "máxima potencia, sin optimizar uso de
tokens ni de contexto". Preguntar por coste o por permiso entre olas es fricción que él no quiere;
lo que sí valora es el rigor de verificación, no el ahorro.

**How to apply:** encadenar fases y lanzar subagentes en paralelo por defecto; reservar las
preguntas para decisiones que **cambien el resultado** (orden de trabajo, alcance), no para pedir
permiso de continuar. Aun así, **sí conviene avisar** de lo que tiene coste permanente y no de
sesión —como el índice que se inyecta en cada turno— y luego respetar su decisión. Su registro es
informal y con humor; el trabajo, exigente. Ver [[skills-catalog-roadmap]].
