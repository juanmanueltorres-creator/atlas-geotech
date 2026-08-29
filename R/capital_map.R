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
