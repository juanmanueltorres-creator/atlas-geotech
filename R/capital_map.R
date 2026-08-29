atlas_capital_summary <- function(projects, companies, capital_origin = NULL) {
  if (!exists("summarize_capital_origins", mode = "function", inherits = TRUE)) {
    stop(
      "summarize_capital_origins() must be loaded before building the Capital view",
      call. = FALSE
    )
  }

  if (!("project_id" %in% names(projects))) {
    projects <- data.frame(
      project_id = character(),
      spatial_province = character(),
      commodity = character(),
      stringsAsFactors = FALSE
    )
  }

  project_ids <- trimws(as.character(projects$project_id))
  company_project_ids <- trimws(as.character(companies$project_id))

  relevant_companies <- companies[
    !is.na(company_project_ids) & company_project_ids %in% project_ids,
    ,
    drop = FALSE
  ]

  capital_origin <- atlas_filter_value(capital_origin)
  if (!is.null(capital_origin) && nrow(relevant_companies) > 0) {
    origins <- trimws(as.character(relevant_companies$capital_origin))
    relevant_companies <- relevant_companies[
      !is.na(origins) & origins == capital_origin,
      ,
      drop = FALSE
    ]
  }

  summarize_capital_origins(projects, relevant_companies)
}

atlas_capital_table_data <- function(summary) {
  required_fields <- c(
    "capital_origin",
    "project_count",
    "province_count",
    "commodity_count",
    "controller_count",
    "top_controllers"
  )
  missing_fields <- setdiff(required_fields, names(summary))

  if (length(missing_fields) > 0) {
    stop(
      sprintf(
        "Capital summary is missing fields required for table presentation: %s",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  table <- data.frame(
    Origen = as.character(summary$capital_origin),
    Proyectos = as.integer(summary$project_count),
    Provincias = as.integer(summary$province_count),
    Minerales = as.integer(summary$commodity_count),
    Controlantes = as.integer(summary$controller_count),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  table[["Controlantes con más proyectos"]] <- as.character(summary$top_controllers)
  table
}
