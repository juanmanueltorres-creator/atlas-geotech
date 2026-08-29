summarize_capital_origins <- function(projects, companies) {
  required_project_fields <- c("project_id", "spatial_province", "commodity")
  required_company_fields <- c("project_id", "company_name", "capital_origin")

  missing_project_fields <- setdiff(required_project_fields, names(projects))
  if (length(missing_project_fields) > 0) {
    stop(
      sprintf(
        "Projects are missing fields required for capital summary: %s",
        paste(missing_project_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  missing_company_fields <- setdiff(required_company_fields, names(companies))
  if (length(missing_company_fields) > 0) {
    stop(
      sprintf(
        "Companies are missing fields required for capital summary: %s",
        paste(missing_company_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  empty_summary <- function() {
    data.frame(
      capital_origin = character(),
      project_count = integer(),
      province_count = integer(),
      commodity_count = integer(),
      controller_count = integer(),
      top_controllers = character(),
      stringsAsFactors = FALSE
    )
  }

  project_ids <- trimws(as.character(projects$project_id))
  company_project_ids <- trimws(as.character(companies$project_id))
  origins <- trimws(as.character(companies$capital_origin))

  keep <-
    !is.na(company_project_ids) & nzchar(company_project_ids) &
    company_project_ids %in% project_ids &
    !is.na(origins) & nzchar(origins)

  if (!any(keep)) {
    return(empty_summary())
  }

  companies <- companies[keep, , drop = FALSE]
  companies$project_id <- company_project_ids[keep]
  companies$capital_origin <- origins[keep]

  clean_values <- function(values) {
    values <- trimws(as.character(values))
    unique(values[!is.na(values) & nzchar(values)])
  }

  summarize_origin <- function(origin) {
    origin_companies <- companies[
      companies$capital_origin == origin,
      ,
      drop = FALSE
    ]
    origin_project_ids <- unique(origin_companies$project_id)
    origin_projects <- projects[
      project_ids %in% origin_project_ids,
      ,
      drop = FALSE
    ]

    controller_names <- trimws(as.character(origin_companies$company_name))
    valid_controllers <- !is.na(controller_names) & nzchar(controller_names)
    controller_rows <- origin_companies[valid_controllers, , drop = FALSE]
    controller_rows$company_name <- controller_names[valid_controllers]

    top_controllers <- character()
    if (nrow(controller_rows) > 0) {
      controller_projects <- split(
        controller_rows$project_id,
        controller_rows$company_name
      )
      controller_counts <- vapply(
        controller_projects,
        function(ids) length(unique(ids)),
        integer(1)
      )
      controller_order <- order(-controller_counts, names(controller_counts))
      top_controllers <- names(controller_counts)[controller_order]
      top_controllers <- head(top_controllers, 3)
    }

    data.frame(
      capital_origin = origin,
      project_count = as.integer(length(origin_project_ids)),
      province_count = as.integer(length(clean_values(origin_projects$spatial_province))),
      commodity_count = as.integer(length(clean_values(origin_projects$commodity))),
      controller_count = as.integer(length(unique(controller_rows$company_name))),
      top_controllers = paste(top_controllers, collapse = " · "),
      stringsAsFactors = FALSE
    )
  }

  summaries <- lapply(unique(companies$capital_origin), summarize_origin)
  result <- do.call(rbind, summaries)
  result <- result[
    order(-result$project_count, result$capital_origin),
    ,
    drop = FALSE
  ]
  rownames(result) <- NULL
  result
}
