trim_or_na <- function(x) {
  value <- stringr::str_trim(as.character(x))
  value[value == ""] <- NA_character_
  value
}

clean_projects <- function(raw_projects) {
  required_columns <- c(
    "N°",
    "NOMBRE",
    "LATITUD",
    "LONGITUD",
    "MINERAL PRINCIPAL",
    "PROVINCIA",
    "ESTADO",
    "CONTROLANTE (1°)",
    "PORCENTAJE (1°)",
    "ORIGEN (1°)",
    "CONTROLANTE (2°)",
    "PORCENTAJE (2°)",
    "ORIGEN (2°)",
    "CONTROLANTE (3°)",
    "PORCENTAJE (3°)",
    "ORIGEN (3°)"
  )

  missing_columns <- setdiff(required_columns, names(raw_projects))

  if (length(missing_columns) > 0) {
    stop(
      sprintf(
        "Missing required SIACAM columns: %s",
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  dplyr::transmute(
    raw_projects,
    project_id = trim_or_na(.data[["N°"]]),
    name = trim_or_na(.data[["NOMBRE"]]),
    latitude = suppressWarnings(as.numeric(.data[["LATITUD"]])),
    longitude = suppressWarnings(as.numeric(.data[["LONGITUD"]])),
    commodity = trim_or_na(.data[["MINERAL PRINCIPAL"]]),
    source_province = trim_or_na(.data[["PROVINCIA"]]),
    stage = trim_or_na(.data[["ESTADO"]]),
    controller_1 = trim_or_na(.data[["CONTROLANTE (1°)"]]),
    share_1 = trim_or_na(.data[["PORCENTAJE (1°)"]]),
    origin_1 = trim_or_na(.data[["ORIGEN (1°)"]]),
    controller_2 = trim_or_na(.data[["CONTROLANTE (2°)"]]),
    share_2 = trim_or_na(.data[["PORCENTAJE (2°)"]]),
    origin_2 = trim_or_na(.data[["ORIGEN (2°)"]]),
    controller_3 = trim_or_na(.data[["CONTROLANTE (3°)"]]),
    share_3 = trim_or_na(.data[["PORCENTAJE (3°)"]]),
    origin_3 = trim_or_na(.data[["ORIGEN (3°)"]])
  )
}
