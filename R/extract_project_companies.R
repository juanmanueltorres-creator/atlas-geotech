extract_project_companies <- function(projects) {
  required_fields <- c(
    "project_id",
    "name",
    "controller_1",
    "share_1",
    "origin_1",
    "controller_2",
    "share_2",
    "origin_2",
    "controller_3",
    "share_3",
    "origin_3"
  )

  missing_fields <- setdiff(required_fields, names(projects))
  if (length(missing_fields) > 0) {
    stop(
      sprintf(
        "Projects are missing fields required for company extraction: %s",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  rows <- lapply(seq_len(3), function(rank) {
    data.frame(
      project_id = as.character(projects$project_id),
      project_name = as.character(projects$name),
      company_rank = rep(as.integer(rank), nrow(projects)),
      company_name = as.character(projects[[paste0("controller_", rank)]]),
      share_text = as.character(projects[[paste0("share_", rank)]]),
      capital_origin = as.character(projects[[paste0("origin_", rank)]]),
      stringsAsFactors = FALSE
    )
  })

  companies <- do.call(rbind, rows)

  normalize_siacam_value <- function(values) {
    values <- trimws(as.character(values))
    values[is.na(values) | !nzchar(values) | values == "-"] <- NA_character_
    values
  }

  companies$company_name <- normalize_siacam_value(companies$company_name)
  companies$share_text <- normalize_siacam_value(companies$share_text)
  companies$capital_origin <- normalize_siacam_value(companies$capital_origin)

  if (exists("canonicalize_capital_origin", mode = "function", inherits = TRUE)) {
    companies$capital_origin <- canonicalize_capital_origin(companies$capital_origin)
  }

  companies <- companies[!is.na(companies$company_name), , drop = FALSE]
  rownames(companies) <- NULL
  companies
}
