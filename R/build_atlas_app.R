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
        shiny::tags$strong("Fuentes"),
        shiny::tags$p("Metadata de procedencia no disponible.")
      )
    )
  }

  source_lines <- paste0(
    as.character(metadata$source_name),
    " · recuperado: ",
    as.character(metadata$retrieved_at)
  )

  shiny::tags$div(
    id = "provenance",
    shiny::tags$strong("Fuentes"),
    shiny::tags$ul(
      lapply(source_lines, shiny::tags$li)
    )
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
    shiny::titlePanel("Atlas Geotech · Minería Argentina"),
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
        atlas_provenance_ui(metadata)
      ),
      shiny::mainPanel(
        leaflet::leafletOutput("map", height = "70vh")
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

    output$map <- leaflet::renderLeaflet({
      data <- filtered_projects()

      map <- leaflet::leaflet(data = data)
      map <- leaflet::addTiles(map)

      if (nrow(data) > 0) {
        map <- leaflet::addCircleMarkers(
          map,
          radius = 6,
          stroke = TRUE,
          weight = 1,
          fillOpacity = 0.8,
          popup = build_project_popup(data)
        )
      }

      map
    })
  }

  shiny::shinyApp(ui = ui, server = server)
}
