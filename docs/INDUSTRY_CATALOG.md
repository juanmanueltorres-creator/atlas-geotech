# Atlas Geotech · Minería, petróleo y cadenas B2B

**Corte editorial:** 2026-11-21. **Estado:** primera muestra curada en PR, no un registro empresarial exhaustivo ni una capa geoespacial de producción.

## Motivación

Atlas nació sobre 331 proyectos mineros SIACAM validados como *snapshot*. Esta ampliación sostiene la identidad **Atlas Geotech · Argentina**, pero permite explorar dos ramas de información industrial:

- **Minería:** Territorio | Capital | **Proveedores B2B**.
- **Petróleo y gas:** **Operadoras** | **Proveedores B2B** | **Datos y fuentes**.

El usuario pidió priorizar petróleo. Por eso la primera muestra incluye **3 ejemplos de operadoras, 4 prestadores industriales y 5 recursos argentinos de hidrocarburos**, siempre con enlace a la evidencia. Minería conserva SIACAM y agrega por ahora la puerta de entrada al Registro Federal de Proveedores Mineros, sin importar nombres no validados.

## Diferencias entre entidades que nunca deben mezclarse

| Término | Pregunta | Precaución |
| --- | --- | --- |
| Pozo | ¿Qué unidad física se registró y cuándo? | El reporte puede no indicar ubicación precisa ni actividad actual. |
| Área / concesión | ¿Qué polígono y derecho está asociado a qué período? | No inferir operación solo por proximidad espacial. |
| Operadora | ¿Quién opera según cuál registro y fecha? | Directorio/membresía ≠ titularidad del área. |
| Proveedor B2B | ¿Qué bien o servicio oferta públicamente? | Oferta/membresía ≠ contrato o cliente confirmado. |
| Producción | ¿Cuál medición declarada, unidad, pozo y fecha? | DDJJ ≠ lectura en vivo ni auditoría de campo. |
| Relación empresa–proyecto | ¿Qué fuente afirma un vínculo concreto? | No inferir vínculos del capital de SIACAM ni del directorio IAPG. |

El campo `accessed_on` es **fecha de consulta de la referencia**, no actualización garantizada del padrón subyacente. El catálogo está deliberadamente separado del dataset minero original. Sin coordenadas verificadas, los proveedores se muestran **en tabla y con enlaces**, no como puntos inventados en el mapa.

## Datos y recursos argentinos

1. **Secretaría de Energía**, producción de petróleo y gas por pozo (Capítulo IV): https://datos.gob.ar/dataset/energia-produccion-petroleo-gas-por-pozo-capitulo-iv . Serie con campos operativos reportados; verificar cobertura, fechas, unidades y claves de pozos antes de procesar.
2. **Secretaría de Energía**, perforación de pozos: https://datos.gob.ar/dataset/energia-perforacion-pozos-petroleo-gas .
3. **Registro de Empresas Upstream**: https://www.argentina.gob.ar/economia/energia/hidrocarburos/registro-de-empresas-upstream . Registro administrativo; no confundir inscripción con concesiones específicas.
4. **IAPG, empresas socias**: https://iapg.org.ar/empresas-socias/ . Directorio amplio de operadoras y servicios; no certifica relaciones comerciales ni clasifica automáticamente sus integrantes.
5. **INTI, petróleo y gas**: https://www.argentina.gob.ar/inti/servicios-inti/petroleo-y-gas . Herramientas de capacitación, certificación, medición y vinculación de proveedores.
6. **Registro Federal de Proveedores Mineros**: https://www.argentina.gob.ar/economia/mineria/registro-federal-de-proveedores-mineros . Información **autodeclarada y no certificada**; nunca presentar como una validación comercial de capacidades.

## Comparaciones internacionales para aprender, no para mezclar datos

- **Noruega / Sokkeldirektoratet FactPages**: https://factpages.sodir.no/ . Modelo de datos y servicios que enlazan pozos, producción, licencias, operadores y fecha de vigencia. Una referencia de estructura interoperable y trazabilidad geográfica.
- **Chile / APRIMIN**: https://aprimin.cl/site/empresas-asociadas/ . Directorio de empresas socias proveedoras; referencia de taxonomía industrial y canal comercial, no un padrón argentino.
- **Chile / Portafolio de Proveedores de Minería de Exportación 2026**: https://redproveedores.corporacionaltaley.cl/portafolio-2026/ . Referencia de segmentación por bien/servicio y cadena de valor.
- **Perú / Guía IIMP Proveedores 2026**: https://iimp.org.pe/brochure/guia/proveedores/IIMP-2026/ . Ejemplo editorial de clasificación industrial.
- **Perú / MINEM Directorio Minero 2026**: https://www.gob.pe/institucion/minem/informes-publicaciones/5424978-directorio-minero-2026 . Registro de titulares y derechos; útil para comparar con directorios de servicios **sin confundirlos**.

## Repositorios de referencia públicos

- https://github.com/Buggy69/argentina-oil-gas : panel sobre datasets públicos de producción con énfasis en proveniencia.
- https://github.com/NicoChandia/vaca-muerta-3d : exploración espacial de pozos argentinos; referencia de experiencia visual, **no evidencia de geometrías aptas para operar**.
- https://github.com/mpodeley/vacamuerta-dashboard : exploración de datos abiertos del capítulo IV.
- https://github.com/oskrgab/petrodb : organización de series temporales y entidades en DuckDB.

**No se copia código, iconografía ni estilos externos sin revisar licencias.** La inspiración es metodológica: contratos de fuente, fechas, entidad, granularidad, calidad, filtros y visualización.

## Modelo actual y límites de implementación

- `data/reference/industry_companies.csv`: 7 entradas de empresas petroleras, etiqueta de rol, actividad amplia, evidencia y limitación.
- `data/reference/industry_sources.csv`: catálogo de recursos de datos, directorios y referencias. Solo cinco recursos argentinos de oil & gas forman el menú petrolero; el resto son minería y referencias mundiales.
- `R/industry_catalog.R`: carga local, contrato de columnas, validación HTTPS, filtrado y presentación de recursos; **no hace scraping ni llamadas web al iniciar la aplicación**.
- `R/build_atlas_app.R`: pestañas principales y subcategorías, sin sustituir los filtros SIACAM existentes.
- `app.R`: integra la nueva fuente documental.
- `tests/testthat/test-industry-catalog.R`: pruebas de consistencia y regresiones.

### Trabajo posterior que requiere validación adicional

1. Descargar y caracterizar datos del Capítulo IV (columnas, identificadores, fechas, tipos de pozo, coordenadas, faltantes, CRSs, magnitudes y unidades).
2. Construir un pipeline versionado de extracción/validación/snapshot en R, con tests de duplicados, geometría, datos faltantes y fechas.
3. Crear una capa de pozos **solo si las coordenadas y procedencia permiten una representación espacial fiable**.
4. Enriquecer empresas y proveedores: localidad, rubro, canal comercial/carreras y vigencia. La relación empresa–área debe surgir de una fuente específica, no de proximidad ni inferencia.
5. Incorporar directorios mineros tras inspeccionar su esquema/condiciones de reutilización. Evitar copiar contactos personales o información no pública.
6. Evaluar la comprensión del visitante y accesibilidad en dispositivos móviles antes de desplegar.

## Identidad y marca personal

**Atlas Geotech — Del recurso al territorio. De los datos a las decisiones.**

Creación, curaduría e integración: **Juan Manuel Torres**, profesional de geociencias, técnico minero y desarrollador de aplicaciones de datos/GIS. La marca personal describe el **trabajo de integración reproducible**, no se atribuye ser autor original de los datos de Secretaría de Energía, SIACAM, IAPG, INTI o entidades internacionales. La prioridad profesional sigue siendo el empleo; este cambio no autoriza un nuevo proyecto paralelo ni un marketplace comercial.

## Calidad

Ejecutar `Rscript tests/testthat.R` más la CI del PR y comprobar que **Territorio y Capital** mantienen su funcionalidad. Separar el estado del código de cualquier publicación Render. Si hay errores, no fusionar.
