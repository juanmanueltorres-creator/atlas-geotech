atlas_filter_choices <- function(values) {
  values <- trimws(as.character(values))
  values <- values[!is.na(values) & nzchar(values)]
  sort(unique(values))
}

atlas_filter_value <- function(value) {
  if (is.null(value) || length(value) == 0) {
    return(NULL)
  }

  value <- trimws(as.character(value[[1]]))
  if (is.na(value) || !nzchar(value) || identical(value, "Todos")) {
    return(NULL)
  }

  value
}

atlas_display_value <- function(value) {
  value <- trimws(as.character(value))
  value[is.na(value) | !nzchar(value)] <- "Sin dato"
  value
}

atlas_province_check <- function(value) {
  if (is.na(value)) {
    return("Comparación territorial no disponible")
  }

  if (isTRUE(value)) {
    return("Coinciden")
  }

  "Discrepancia territorial"
}

atlas_basemap_provider <- function() {
  "CartoDB.DarkMatter"
}

atlas_theme_css <- function() {
  paste(
    "html, body { background: #0b1220; color: #f9fafb; }",
    "body { min-height: 100vh; }",
    ".container-fluid { padding-left: 14px; padding-right: 14px; }",
    ".atlas-header { margin: 12px 0 10px; padding: 0 2px 10px; border-bottom: 1px solid #243041; }",
    ".atlas-header h2 { margin: 0; color: #f9fafb; font-weight: 600; letter-spacing: 0.01em; }",
    ".well { background: #111827; color: #f9fafb; border: 1px solid #243041; border-radius: 7px; box-shadow: none; padding: 14px; margin-bottom: 10px; }",
    ".form-group { margin-bottom: 10px; }",
    ".control-label { color: #e5e7eb; font-weight: 600; }",
    ".form-control, .selectize-input, .selectize-control.single .selectize-input { background: #0f172a; color: #f9fafb; border-color: #334155; box-shadow: none; }",
    ".form-control:focus, .selectize-input.focus { border-color: #c68a2b; box-shadow: 0 0 0 1px #c68a2b; }",
    ".selectize-input input { color: #f9fafb; }",
    ".selectize-dropdown, .selectize-dropdown-content { background: #111827; color: #f9fafb; border-color: #334155; }",
    ".selectize-dropdown .active { background: #1f2937; color: #f9fafb; }",
    ".atlas-project-count { color: #c68a2b; font-size: 1.15rem; font-weight: 700; margin: 2px 0 12px; }",
    ".atlas-provenance { color: #9ca3af; font-size: 0.88rem; line-height: 1.35; }",
    ".atlas-provenance strong { color: #e5e7eb; }",
    ".atlas-provenance strong, .atlas-provenance small { display: block; }",
    ".atlas-provenance small { color: #7f8b9b; margin-top: 3px; }",
    "#map { border: 1px solid #243041; border-radius: 7px; overflow: hidden; }",
    ".leaflet-container { background: #0b1220; }",
    ".leaflet-bar a, .leaflet-bar a:hover { background: #111827; color: #f9fafb; border-bottom-color: #243041; }",
    ".leaflet-control-attribution { background: rgba(17, 24, 39, 0.88) !important; color: #9ca3af; }",
    ".leaflet-control-attribution a { color: #d4a24c; }",
    ".leaflet-popup-content-wrapper, .leaflet-popup-tip { background: #111827; color: #f9fafb; }",
    ".leaflet-popup-content-wrapper { border: 1px solid #243041; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.35); }",
    ".leaflet-popup-content b, .leaflet-popup-content strong { color: #d4a24c; }",
    ".leaflet-container a.leaflet-popup-close-button { color: #9ca3af; }",
    sep = "\n"
  )
}

build_project_popup <- function(projects) {
  required_fields <- c(
    "name",
    "commodity",
    "stage",
    "source_province",
    "spatial_province",
    "province_match"
  )
  missing_fields <- setdiff(required_fields, names(projects))

  if (length(missing_fields) > 0) {
    stop(
      sprintf(
        "Projects are missing fields required for popups: %s",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  names <- atlas_display_value(projects$name)
  commodities <- atlas_display_value(projects$commodity)
  stages <- atlas_display_value(projects$stage)
  source_provinces <- atlas_display_value(projects$source_province)
  spatial_provinces <- atlas_display_value(projects$spatial_province)
  province_checks <- vapply(
    projects$province_match,
    atlas_province_check,
    character(1)
  )

  vapply(
    seq_len(nrow(projects)),
    function(index) {
      as.character(
        shiny::tags$div(
          shiny::tags$strong(names[[index]]),
          shiny::tags$br(),
          shiny::tags$b("Mineral: "), commodities[[index]],
          shiny::tags$br(),
          shiny::tags$b("Etapa: "), stages[[index]],
          shiny::tags$br(),
          shiny::tags$b("Provincia declarada: "), source_provinces[[index]],
          shiny::tags$br(),
          shiny::tags$b("Provincia espacial: "), spatial_provinces[[index]],
          shiny::tags$br(),
          shiny::tags$b("Control territorial: "), province_checks[[index]]
        )
      )
    },
    character(1)
  )
}

atlas_format_retrieved_at <- function(values) {
  values <- trimws(as.character(values))
  parsed <- as.POSIXct(
    values,
    format = "%Y-%m-%dT%H:%M:%SZ",
    tz = "UTC"
  )

  formatted <- format(
    parsed,
    tz = "America/Argentina/Cordoba",
    format = "%d/%m/%Y · %H:%M ART"
  )
  formatted[is.na(parsed)] <- values[is.na(parsed)]
  formatted
}

atlas_provenance_ui <- function(metadata) {
  if (
    is.null(metadata) ||
    nrow(metadata) == 0 ||
    !("source_name" %in% names(metadata)) ||
    !("retrieved_at" %in% names(metadata))
  ) {
    return(
      shiny::tags$div(
        id = "provenance",
        class = "atlas-provenance",
        shiny::tags$strong("Fuentes"),
        shiny::tags$div("Metadata de procedencia no disponible.")
      )
    )
  }

  source_names <- trimws(as.character(metadata$source_name))
  source_names <- unique(source_names[!is.na(source_names) & nzchar(source_names)])

  retrieved_at <- trimws(as.character(metadata$retrieved_at))
  retrieved_at <- unique(retrieved_at[!is.na(retrieved_at) & nzchar(retrieved_at)])
  retrieved_display <- atlas_format_retrieved_at(retrieved_at)

  source_text <- if (length(source_names) > 0) {
    paste(source_names, collapse = " · ")
  } else {
    "Fuentes no informadas"
  }

  retrieved_text <- if (length(retrieved_display) == 1) {
    paste0("Recuperado ", retrieved_display[[1]])
  } else if (length(retrieved_display) > 1) {
    paste0("Recuperaciones ", paste(retrieved_display, collapse = " · "))
  } else {
    "Fecha de recuperación no disponible"
  }

  shiny::tags$div(
    id = "provenance",
    class = "atlas-provenance",
    shiny::tags$strong("Fuentes"),
    shiny::tags$div(source_text),
    shiny::tags$small(retrieved_text)
  )
}

build_atlas_ui <- function(projects, metadata) {
  required_fields <- c("spatial_province", "commodity", "stage")
  missing_fields <- setdiff(required_fields, names(projects))

  if (length(missing_fields) > 0) {
    stop(
      sprintf(
        "Projects are missing fields required by the Atlas UI: %s",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  province_choices <- atlas_filter_choices(projects$spatial_province)
  mineral_choices <- atlas_filter_choices(projects$commodity)
  stage_choices <- atlas_filter_choices(projects$stage)

  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$style(shiny::HTML(atlas_theme_css()))
    ),
    shiny::tags$div(
      class = "atlas-header",
      shiny::tags$h2("Atlas Geotech · Minería Argentina")
    ),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::selectInput(
          "province",
          "Provincia",
          choices = c("Todos", province_choices),
          selected = "Todos"
        ),
        shiny::selectInput(
          "mineral",
          "Mineral",
          choices = c("Todos", mineral_choices),
          selected = "Todos"
        ),
        shiny::selectInput(
          "stage",
          "Etapa",
          choices = c("Todos", stage_choices),
          selected = "Todos"
        ),
        shiny::tags$div(
          class = "atlas-project-count",
          shiny::textOutput("project_count", inline = TRUE)
        ),
        atlas_provenance_ui(metadata),
        width = 3
      ),
      shiny::mainPanel(
        leaflet::leafletOutput("map", height = "82vh"),
        width = 9
      )
    )
  )
}

build_atlas_app <- function(projects, metadata) {
  ui <- build_atlas_ui(projects, metadata)

  server <- function(input, output, session) {
    filtered_projects <- shiny::reactive({
      if (!exists("filter_projects", mode = "function", inherits = TRUE)) {
        stop(
          "filter_projects() must be loaded before starting the Atlas app",
          call. = FALSE
        )
      }

      filter_projects(
        projects,
        province = atlas_filter_value(input$province),
        mineral = atlas_filter_value(input$mineral),
        stage = atlas_filter_value(input$stage)
      )
    })

    output$project_count <- shiny::renderText({
      count <- nrow(filtered_projects())
      noun <- if (count == 1) "proyecto" else "proyectos"
      paste(count, noun)
    })

    output$map <- leaflet::renderLeaflet({
      data <- filtered_projects()

      map <- leaflet::leaflet(data = data)
      map <- leaflet::addProviderTiles(
        map,
        provider = atlas_basemap_provider()
      )

      if (nrow(data) > 0) {
        map <- leaflet::addCircleMarkers(
          map,
          radius = 6,
          stroke = TRUE,
          weight = 1,
          color = "#f0bd64",
          fillColor = "#c68a2b",
          fillOpacity = 0.86,
          popup = build_project_popup(data)
        )
      }

      map
    })
  }

  shiny::shinyApp(ui = ui, server = server)
}
