# Atlas Geotech

Enciclopedia interactiva de geología, tecnología geoespacial, minería, agro y ambiente.

## ⛏️ Atlas Minero Argentina — V0 en desarrollo

**Del yacimiento al territorio.**

Primer producto de Atlas Geotech: una aplicación reproducible en R que conecta proyectos mineros públicos con el territorio argentino y conserva fuente, fecha y limitaciones.

### Alcance V0

- proyectos mineros metalíferos y de litio publicados por SIACAM;
- límites provinciales oficiales reutilizados desde Pulso Territorial / IGN;
- normalización y validación reproducible en R;
- filtros por provincia, mineral y etapa;
- fuente y freshness visibles.

### Stack inicial

`R` · `sf` · `dplyr` · `Shiny` · `testthat`

### Regla

> Un dato nunca debe parecer más preciso, reciente o autoritativo que la fuente que lo sostiene.

El desarrollo se mantiene deliberadamente pequeño: primero el contrato de datos y la validación; después la interfaz.
