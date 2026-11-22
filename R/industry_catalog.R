# Atlas Geotech — reference registries. Explicitly not a live well/production feed.
atlas_reference_dir <- function() {
  candidate <- Sys.getenv("ATLAS_REFERENCE_DIR", unset = file.path("data", "reference"))
  if (dir.exists(candidate)) return(candidate)
  other <- file.path("..", "..", "data", "reference")
  if (dir.exists(other)) return(other)
  candidate
}

atlas_reference_csv <- function(filename, columns, directory = atlas_reference_dir()) {
  path <- file.path(directory, filename)
  if (!file.exists(path)) {
    stop(sprintf("Missing reference catalogue: %s", filename), call. = FALSE)
  }
  rows <- as.data.frame(readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = "c")))
  absent <- setdiff(columns, names(rows))
  if (length(absent)) stop(sprintf("Missing reference fields: %s", paste(absent, collapse = ", ")), call. = FALSE)
  if (!all(grepl("^https://", rows$source_url))) stop("Source links must use HTTPS", call. = FALSE)
  if (any(is.na(rows$source_url) | !nzchar(trimws(rows$source_url)))) stop("Every row needs a source link", call. = FALSE)
  rows
}

atlas_reference_companies <- function(directory = atlas_reference_dir()) {
  atlas_reference_csv("industry_companies.csv",
    c("sector", "subcategory", "name", "specialty", "evidence", "source_url", "accessed_on", "note"),
    directory)
}

atlas_reference_sources <- function(directory = atlas_reference_dir()) {
  atlas_reference_csv("industry_sources.csv",
    c("sector", "subcategory", "title", "source_name", "source_url", "source_kind", "limitations"),
    directory)
}

atlas_catalog_filter <- function(rows, sector, subcategory = NULL) {
  result <- rows[rows$sector == sector, , drop = FALSE]
  if (!is.null(subcategory)) result <- result[result$subcategory == subcategory, , drop = FALSE]
  result
}

atlas_catalog_link <- function(url, label = "Fuente") {
  shiny::tags$a(label, href = url, target = "_blank", rel = "noopener noreferrer")
}

atlas_catalog_table <- function(rows, columns) {
  if (!nrow(rows)) return(shiny::tags$p("Todavía no hay registros validados en esta categoría."))
  header <- shiny::tags$tr(lapply(unname(columns), shiny::tags$th))
  body <- lapply(seq_len(nrow(rows)), function(i) {
    cells <- lapply(names(columns), function(column) {
      value <- as.character(rows[[column]][[i]])
      if (column == "source_url") {
        shiny::tags$td(atlas_catalog_link(value, "Ver fuente ↗"))
      } else {
        shiny::tags$td(if (is.na(value) || !nzchar(value)) "Sin dato" else value)
      }
    })
    do.call(shiny::tags$tr, cells)
  })
  shiny::tags$div(
    class = "atlas-reference-scroll",
    shiny::tags$table(
      class = "table table-striped atlas-reference-table",
      shiny::tags$thead(header),
      shiny::tags$tbody(body)
    )
  )
}

atlas_oil_ui <- function(oil=NULL) {
  companies <- atlas_reference_companies()
  sources <- atlas_reference_sources()
  shiny::tags$div(
    class = "atlas-industry-panel",
    shiny::tags$h3("Petróleo y gas · Argentina"),
    shiny::tags$p(
      if(is.null(oil)) "Catálogo de empresas y fuentes públicas. Todavía no hay un snapshot validado de pozos y producción para explorar."
      else paste("Snapshot validado de Capítulo IV ·", nrow(oil$records),
                 "registros mensuales ubicados. No representa telemetría en tiempo real.")
    ),
    shiny::tabsetPanel(
      id = "oil_subview",
      shiny::tabPanel(
        "Pozos y producción",
        if(is.null(oil)) shiny::tags$div(
          class="atlas-industry-context",
          shiny::tags$strong("No hay datos petroleros importados en este despliegue"),
          shiny::tags$p("Se necesita un snapshot procesado desde la fuente oficial, validado y publicado por separado. No se muestran puntos de ejemplo como si fueran reales."),
          atlas_catalog_link("https://datos.gob.ar/dataset/energia-produccion-petroleo-gas-por-pozo-capitulo-iv","Abrir catálogo oficial del Capítulo IV ↗")
        ) else shiny::tags$div(
          shiny::tags$p("Producción declarada por empresa y mes, vinculada a geometrías válidas del padrón Capítulo IV. Los casos sin ubicación segura quedan fuera de este mapa."),
          shiny::fluidRow(
            shiny::column(4,shiny::selectInput("oil_operator","Operadora",
              choices=c("Todas",sort(unique(oil$records$empresa))))),
            shiny::column(4,shiny::selectInput("oil_year","Año",
              choices=sort(unique(oil$records$anio)),selected=max(oil$records$anio))),
            shiny::column(4,shiny::selectInput("oil_month","Mes",choices=c("Todos",as.character(1:12))))
          ),
          shiny::textOutput("oil_summary"),
          leaflet::leafletOutput("oil_map",height="68vh"),
          shiny::tags$p(class="atlas-provenance",
            paste("Fuente: Secretaría de Energía - Capítulo IV. Recuperado:",
                  as.character(oil$metadata$retrieved_at[[1]]),
                  "UTC. Volúmenes en m³ de petróleo y miles de m³ de gas. No se imputan datos faltantes.")
          )
        )
      ),
      shiny::tabPanel(
        "Operadoras",
        shiny::tags$h4("Empresas de referencia"),
        shiny::tags$p("La presencia en un directorio no prueba qué áreas opera hoy una empresa. Verificar el registro y cada concesión antes de dibujarla."),
        atlas_catalog_table(
          atlas_catalog_filter(companies, "Petróleo y gas", "Operadoras"),
          c(name = "Empresa", specialty = "Actividad general", evidence = "Evidencia", source_url = "Origen", note = "Límite")
        )
      ),
      shiny::tabPanel(
        "Proveedores B2B",
        shiny::tags$h4("Servicios industriales"),
        shiny::tags$p("Servicios declarados o descriptos en fuentes públicas. No se infiere ninguna relación proveedor–cliente."),
        atlas_catalog_table(
          atlas_catalog_filter(companies, "Petróleo y gas", "Proveedores B2B"),
          c(name = "Empresa", specialty = "Tipo de servicio", evidence = "Evidencia", source_url = "Origen", note = "Límite")
        )
      ),
      shiny::tabPanel(
        "Datos y fuentes",
        shiny::tags$h4("Fuentes para una futura capa geográfica"),
        shiny::tags$p("Separar pozo, operador, área, período y producción. Una fuente pública no representa telemetría en vivo."),
        atlas_catalog_table(
          atlas_catalog_filter(sources, "Petróleo y gas"),
          c(title = "Recurso", source_name = "Organismo", source_kind = "Tipo", source_url = "Abrir", limitations = "Advertencia")
        )
      )
    ),
    shiny::tags$div(
      class = "atlas-industry-context",
      shiny::tags$strong("Método / procedencia"),
      shiny::tags$p("Muestra editorial: consulta 21/11/2026. No es un censo exhaustivo, padrón legal actualizado ni monitor de producción. Cada dato tiene fuente y alcance.")
    )
  )
}

atlas_mining_providers_ui <- function() {
  sources <- atlas_reference_sources()
  shiny::tags$div(
    class = "atlas-industry-panel",
    shiny::tags$h3("Minería · proveedores B2B"),
    shiny::tags$p(
      "La cartera SIACAM representa proyectos mineros, no empresas proveedoras. ",
      "Este es el punto de entrada a una nueva categoría, sin inferir proveedores a partir del capital o de los proyectos."
    ),
    shiny::tags$p(shiny::tags$strong(
      "El Registro Federal de Proveedores Mineros contiene información autodeclarada, no certificada."
    )),
    atlas_catalog_table(
      atlas_catalog_filter(sources, "Minería", "Proveedores B2B"),
      c(title = "Registro", source_name = "Organismo", source_url = "Abrir", limitations = "Límite")
    ),
    shiny::tags$p("No se han importado empresas mineras proveedoras hasta validar el esquema y los campos del registro.")
  )
}

atlas_industry_css <- function() paste(
  ".atlas-industry-panel {padding:20px 8px 26px; color:#e5e7eb; min-height:68vh;}",
  ".atlas-industry-panel h3 {font-size:26px; font-weight:600; margin:8px 0 10px;}",
  ".atlas-industry-panel p {max-width:100ch; line-height:1.6; color:#bdc8d7;}",
  ".atlas-reference-scroll {overflow-x:auto; margin:18px 0;}",
  ".atlas-reference-table {background:#111827; min-width:760px; border:1px solid #334155; color:#e5e7eb;}",
  ".atlas-reference-table th {background:#1c2b3e; color:#dcb46b; border-color:#334155;}",
  ".atlas-reference-table td {border-color:#334155; vertical-align:top; font-size:12px; line-height:1.55;}",
  ".atlas-reference-table a {color:#81d6e3; text-decoration:underline;}",
  ".atlas-industry-context {border:1px solid #364b62; border-radius:7px; padding:15px 18px; margin-top:24px; background:#101e31;}",
  ".atlas-industry-panel .nav-tabs > li > a {color:#d8e5f5; border-color:#334155;}",
  ".atlas-industry-panel .nav-tabs > li.active > a {background:#26374a; color:#f8fafc; border-color:#516379;}",
  sep = "\n"
)
