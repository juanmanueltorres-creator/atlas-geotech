empty_project_issues <- function() {
  data.frame(
    project_id = character(),
    field = character(),
    code = character(),
    severity = character(),
    stringsAsFactors = FALSE
  )
}

append_project_issues <- function(issues, project_ids, field, code, severity) {
  if (length(project_ids) == 0) {
    return(issues)
  }

  new_issues <- data.frame(
    project_id = as.character(project_ids),
    field = rep(field, length(project_ids)),
    code = rep(code, length(project_ids)),
    severity = rep(severity, length(project_ids)),
    stringsAsFactors = FALSE
  )

  rbind(issues, new_issues)
}

validate_projects <- function(projects) {
  required_columns <- c(
    "project_id",
    "name",
    "latitude",
    "longitude",
    "commodity",
    "stage"
  )

  missing_columns <- setdiff(required_columns, names(projects))
  if (length(missing_columns) > 0) {
    stop(
      sprintf(
        "Missing normalized project columns: %s",
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  issues <- empty_project_issues()

  missing_name <- is.na(projects$name) | trimws(as.character(projects$name)) == ""
  issues <- append_project_issues(
    issues,
    projects$project_id[missing_name],
    "name",
    "missing_name",
    "error"
  )

  missing_latitude <- is.na(projects$latitude)
  issues <- append_project_issues(
    issues,
    projects$project_id[missing_latitude],
    "latitude",
    "missing_latitude",
    "error"
  )

  invalid_latitude <- !is.na(projects$latitude) &
    (projects$latitude < -90 | projects$latitude > 90)
  issues <- append_project_issues(
    issues,
    projects$project_id[invalid_latitude],
    "latitude",
    "invalid_latitude",
    "error"
  )

  missing_longitude <- is.na(projects$longitude)
  issues <- append_project_issues(
    issues,
    projects$project_id[missing_longitude],
    "longitude",
    "missing_longitude",
    "error"
  )

  invalid_longitude <- !is.na(projects$longitude) &
    (projects$longitude < -180 | projects$longitude > 180)
  issues <- append_project_issues(
    issues,
    projects$project_id[invalid_longitude],
    "longitude",
    "invalid_longitude",
    "error"
  )

  missing_commodity <- is.na(projects$commodity) |
    trimws(as.character(projects$commodity)) == ""
  issues <- append_project_issues(
    issues,
    projects$project_id[missing_commodity],
    "commodity",
    "missing_commodity",
    "warning"
  )

  missing_stage <- is.na(projects$stage) |
    trimws(as.character(projects$stage)) == ""
  issues <- append_project_issues(
    issues,
    projects$project_id[missing_stage],
    "stage",
    "missing_stage",
    "warning"
  )

  error_ids <- unique(issues$project_id[issues$severity == "error"])
  valid <- projects[!(projects$project_id %in% error_ids), , drop = FALSE]

  list(
    valid = valid,
    issues = issues
  )
}
