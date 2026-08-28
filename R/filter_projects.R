filter_projects <- function(
  projects,
  province = NULL,
  mineral = NULL,
  stage = NULL
) {
  normalize_filter <- function(value) {
    if (is.null(value) || length(value) == 0) {
      return(NULL)
    }

    value <- trimws(as.character(value[[1]]))
    if (is.na(value) || !nzchar(value)) {
      return(NULL)
    }

    tolower(value)
  }

  province_filter <- normalize_filter(province)
  mineral_filter <- normalize_filter(mineral)
  stage_filter <- normalize_filter(stage)

  required_fields <- character()
  if (!is.null(province_filter)) required_fields <- c(required_fields, "spatial_province")
  if (!is.null(mineral_filter)) required_fields <- c(required_fields, "commodity")
  if (!is.null(stage_filter)) required_fields <- c(required_fields, "stage")

  missing_fields <- setdiff(required_fields, names(projects))
  if (length(missing_fields) > 0) {
    stop(
      sprintf(
        "Projects are missing fields required for filtering: %s",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  keep <- rep(TRUE, nrow(projects))

  if (!is.null(province_filter)) {
    values <- tolower(trimws(as.character(projects$spatial_province)))
    keep <- keep & !is.na(values) & values == province_filter
  }

  if (!is.null(mineral_filter)) {
    values <- tolower(trimws(as.character(projects$commodity)))
    keep <- keep & !is.na(values) & values == mineral_filter
  }

  if (!is.null(stage_filter)) {
    values <- tolower(trimws(as.character(projects$stage)))
    keep <- keep & !is.na(values) & values == stage_filter
  }

  projects[keep, , drop = FALSE]
}
