# Petróleo y gas · Capítulo IV — pipeline de datos reales

**Estado:** integración en rama/PR, pendiente de validación en vivo y publicación del snapshot oficial.  
**Regla:** el repositorio no afirma que se hayan descargado pozos o publicado nuevos datos hasta que se revisen los artefactos de GitHub Actions.

## Fuentes oficiales identificadas

- **Capítulo IV — Pozos (CSV):** [recurso de la Secretaría de Energía](https://datos.gob.ar/dataset/energia-produccion-petroleo-gas-por-pozo-capitulo-iv/archivo/energia_cb5c0f04-7835-45cd-b982-3e25ca7d7751)
- **Producción 2026, mensual por pozo (CSV):** [recurso de la Secretaría de Energía](https://datos.gob.ar/dataset/energia-produccion-petroleo-gas-por-pozo-capitulo-iv/archivo/energia_fb7a47a0-cba9-4667-a004-6f6c1c346c23)
- **Listado de pozos por operadoras:** [recurso de la Secretaría de Energía](https://datos.gob.ar/dataset/energia-produccion-petroleo-gas-por-pozo-capitulo-iv/archivo/energia_cbfa4d79-ffb3-4096-bab5-eb0dde9a8385)

URLs directas de descarga obtenidas a partir del vínculo DESCARGAR del catálogo. Pueden cambiar: error de descarga ≠ CSV vacío ni fuente validada. El esquema del [repositorio de catalogación de Datos Energía](https://github.com/datosenergia/produccion-de-petroleo-y-gas-por-pozo) identifica `idpozo`, `coordenadax` (latitud), `coordenaday` (longitud), `anio`, `mes`, `prod_pet` (m³), `prod_gas` (miles de m³), `empresa`/`idempresa`. **Las columnas reales de los archivos 2026 aún deben cotejarse con el esquema histórico.**

## Qué hace el código

```text
Fuentes oficiales CSV
   ↓ descarga fuera de Shiny
contrato de columnas y unidades
   ↓
IDs de pozo + lat/lon plausibles (x=latitud, y=longitud según fuente)
   ↓
controles de duplicados, campos inválidos y claves ambiguas
   ↓
join por idpozo (no por proximidad)
   ↓
CSV de producción mensual georreferenciada + metadatos de exclusión
   ↓
Shiny, petróleo y gas > pozos y producción
   ↓
filtros empresa / año / mes → mapa de pozos y volúmenes agregados por pozo
```

**No cruza nombres de proveedores con clientes ni supone licencias/concesiones.** Las DDJJ no equivalen a datos en tiempo real; una posición puntual de boca de pozo no representa la trayectoria del pozo. Los valores ausentes no se reemplazan por ceros. Si hay declaraciones repetidas en la misma clave `idpozo/anio/mes`, **se excluyen todas esas claves** hasta resolver rectificaciones. Si una clave de pozo aparece con coordenadas contradictorias, se descarta de la capa espacial. El conteo de descartes queda en metadatos.

El primer contrato se restringe al **2026**. No agrega números de años distintos ni asume que una misma clave basta para inferir propiedad del pozo en fechas históricas. La UI limita a 3000 puntos visibles, lo indica explícitamente y expone el conteo total del filtro.

## Cómo generar y revisar

Desde root:

```bash
Rscript scripts/refresh_oil_wells.R --out=artifacts/processed/oil
```

Para un ensayo reproducible de esquema, se pueden usar CSV locales:

```bash
Rscript scripts/refresh_oil_wells.R --wells=tests/fixtures/wells.csv --production=tests/fixtures/production.csv --out=artifacts/processed/oil
```

La ejecución oficial también existe como workflow `Capítulo IV - official oil snapshot`. Descarga los CSV, genera un artefacto para revisión y compara su metadata. **No realiza merge, commit de datos ni despliegue automáticamente.**

Para habilitar la vista en un despliegue **después de revisar el artefacto**, copiar su contenido validado a `data/processed/oil/oil_production.csv` y `data/processed/oil/oil_metadata.csv`. Un directorio ausente produce una pantalla honesta sin datos; un directorio incompleto detiene la carga.

Los 331 proyectos SIACAM, sus filtros mineros y el análisis de Capital no se alteran.

## Criterios para aprobar la ampliación

- [ ] GitHub R CI: tests de geometría, duplicados, faltantes, procedencia y regresión.
- [ ] Docker smoke.
- [ ] Smoke real en Chrome con captura y Leaflet.
- [ ] Descarga de CSV oficial 2026 finalizada y sin error.
- [ ] Revisar número de filas y pozos, exclusiones, unidades, fechas, porcentaje de georreferenciación.
- [ ] Confirmar si el proveedor permite redistribución de un snapshot derivado; atribuir fuentes.
- [ ] Instalar artefacto revisado en el despliegue y comprobar filtros con producción real.
- [ ] Registrar fecha y hash del archivo de origen antes de un refresh que sustituya datos vigentes.

## Dónde aporta Atlas

Atlas Geotech conserva identidad argentina y trazabilidad: **no es un catálogo genérico ni una plataforma de vigilancia industrial**. Vincula geociencias, GIS, ingeniería de datos y lectura crítica de información pública. **Curaduría e integración técnica: Juan Manuel Torres**. La prioridad personal sigue siendo demostrar trabajo terminado y búsqueda laboral; el módulo no implica iniciar una startup aparte.
