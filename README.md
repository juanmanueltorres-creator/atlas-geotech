# Atlas Geotech

> **Public mining data, territory and capital — explored reproducibly in R.**

Atlas Geotech is an **R + Shiny** application for exploring Argentina's public mining-project data spatially while keeping source provenance and interpretation boundaries visible.

The current atlas connects a validated SIACAM mining-project snapshot with territorial context, interactive Leaflet exploration and derived company/capital views.

**Current checked-in snapshot: 331 mining projects.**

> **Del yacimiento al territorio.**

---

## From learning R to building a mining atlas

Atlas Geotech began as an applied learning project while working through **Bastián Olea Herrera's open [Aprende R](https://bastianolea.github.io/aprende_r/) materials**.

That learning path provided the foundation for working with R, data transformation, visualization and reproducible analysis. Atlas then extended those ideas into an independent domain project built around **Argentine mining data, spatial validation, provenance, automated tests, browser verification and container deployment**.

```text
Aprende R
    ↓
R + data transformation
    ↓
public mining datasets
    ↓
sf / spatial analysis
    ↓
Shiny + Leaflet
    ↓
mining-domain questions
    ↓
validation + provenance
    ↓
tests + CI + Docker
```

This repository is therefore both a working mining-data application and a record of **learning by building something domain-specific**.

---

## What you can explore

The current application supports two complementary views.

### Territorio

Explore mining projects geographically with filters for:

- province;
- main mineral;
- project stage;
- declared capital origin.

Project popups expose the available project context plus derived controller/capital information without mutating the original source snapshot.

### Capital

The Capital view summarizes the filtered SIACAM-derived company context across:

- distinct projects;
- provinces;
- minerals;
- controllers (`controlantes`);
- declared capital origins;
- top controllers by project count.

The same filters drive both the territorial and capital views.

---

## From public data to an interactive atlas

```text
SIACAM mining projects
         ↓
 source-preserving ingest
         ↓
 validation + normalization
         ↓
 spatial context ← IGN
         ↓
 derived Company Lens
         ↓
 Territorio + Capital views
         ↓
     Shiny / Leaflet
```

The application starts from a checked-in processed snapshot, so normal app startup does not depend on a live external API call.

Refresh and validation are separate from presentation: source data is collected, validated and transformed before the Shiny interface consumes it.

---

## Evidence boundaries

Atlas Geotech deliberately separates source fields from derived interpretation.

```text
source value != inferred fact
declared province != spatial relationship
capital origin != corporate domicile
capital origin != current ownership
capital origin != invested USD
missing value != zero
map position != complete project context
```

A central rule of the project is:

> **A value should never look more precise, current or authoritative than the source that supports it.**

For example, the SIACAM capital-origin field is useful for grouping and exploration, but Atlas does not reinterpret that field as a claim about current corporate domicile, ownership structure or investment amount.

Verified display aliases can be canonicalized in derived/UI layers — for example `Paises Bajos` → `Países Bajos` — while the underlying source evidence remains unchanged.

---

## Data sources

### SIACAM

Argentina's public mining information system is the primary source for the mining-project snapshot and declared project attributes used by the atlas.

- SIACAM: https://www.argentina.gob.ar/economia/mineria/siacam
- Public mining-project dataset: https://datos.gob.ar/dataset/produccion-cartera-proyectos-mineros-argentina-siacam

### IGN

Official Argentine territorial data provides the spatial reference used to contextualize projects against administrative geography.

- IGN territorial units: https://datos.gob.ar/dataset/ign-unidades-territoriales

### OpenStreetMap

OpenStreetMap is used as the interactive basemap context. It is a presentation/background layer, not the authority for SIACAM project attributes.

---

## Stack

```text
R
├── dplyr / readr     data transformation
├── sf                spatial data
├── Shiny             application runtime
├── Leaflet           interactive map
└── testthat          contract and regression tests

Docker                reproducible deployment boundary
GitHub Actions         automated R verification
```

The project is packaged for a Render-style container deployment and can start from the checked-in processed data without requiring a database, paid service or runtime secret.

---

## Run locally

The repository is an R/Shiny project. Install the R dependencies used by the application, then launch from the project root:

```r
shiny::runApp()
```

The app entrypoint is `app.R`.

For container execution, the repository also includes the Docker deployment path used by the project.

---

## Verification

Atlas is treated as a small data product rather than only an exploratory script.

Verification has included:

- source and schema validation;
- spatial-relationship regression tests;
- filter and popup contracts;
- Company Lens normalization tests;
- capital-origin canonicalization tests;
- Capital view aggregation tests;
- Docker HTTP smoke tests;
- real-browser Shiny/Leaflet smoke tests against the processed snapshot.

For the latest merged Capital Map milestone, the project recorded:

```text
277 R tests passing
Render Docker smoke: success
real-browser smoke: success
331 initial projects rendered
```

Those are historical verification results from the merged feature work; this README-only change does not claim a new test run.

---

## Project scope

Atlas Geotech currently focuses on **Argentina mining + territorial context**.

It is not yet a general encyclopedia of geology, agriculture and environment, and it does not attempt to infer:

- current corporate ownership from historical/source capital fields;
- investment amounts not present in the source;
- project viability;
- environmental impact conclusions;
- operational mine status beyond what the source explicitly supports.

Future thematic layers should extend the atlas only when their source, provenance and interpretation contract can be made equally explicit.

---

## Learning origin and acknowledgement

The initial R learning path was inspired by and built while studying **Bastián Olea Herrera's [Aprende R](https://bastianolea.github.io/aprende_r/)**, an open Spanish-language resource for learning R through practical data work.

Atlas Geotech is an independent applied project built on top of that learning: its mining-data model, SIACAM/IGN integration, spatial validation, provenance rules, Company/Capital views, tests and deployment workflow are specific to this repository.

Open educational material is valuable precisely because it can become a starting point for new work rather than an endpoint.

## License

MIT.
