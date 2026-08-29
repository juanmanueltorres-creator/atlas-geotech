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
  company_names <- trimws(companies$company_name)
  keep <- !is.na(company_names) & nzchar(company_names)

  companies <- companies[keep, , drop = FALSE]
  rownames(companies) <- NULL
  companies
}
