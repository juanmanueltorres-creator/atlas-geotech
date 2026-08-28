build_spatial_projects <- function(projects, provinces) {
  required_project_fields <- c("latitude", "longitude", "source_province")
  missing_project_fields <- setdiff(required_project_fields, names(projects))

  if (length(missing_project_fields) > 0) {
    stop(
      sprintf(
        "Projects are missing required spatial fields: %s",
        paste(missing_project_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  latitude <- suppressWarnings(as.numeric(projects$latitude))
  longitude <- suppressWarnings(as.numeric(projects$longitude))

  valid_coordinates <-
    is.finite(latitude) &
    is.finite(longitude) &
    latitude >= -90 & latitude <= 90 &
    longitude >= -180 & longitude <= 180

  if (any(!valid_coordinates)) {
    stop(
      "build_spatial_projects requires validated coordinates for every project",
      call. = FALSE
    )
  }

  if (!inherits(provinces, "sf")) {
    stop("Provinces must be an sf layer", call. = FALSE)
  }

  if (!("nombre" %in% names(provinces))) {
    stop("Provinces are missing the 'nombre' field", call. = FALSE)
  }

  province_code_field <- intersect(c("id", "codigo", "code"), names(provinces))
  if (length(province_code_field) == 0) {
    stop("Provinces are missing an official province code field", call. = FALSE)
  }
  province_code_field <- province_code_field[[1]]

  if (is.na(sf::st_crs(provinces))) {
    stop("Provinces must have a declared CRS", call. = FALSE)
  }

  provinces_wgs84 <- if (identical(sf::st_crs(provinces)$epsg, 4326L)) {
    provinces
  } else {
    sf::st_transform(provinces, 4326)
  }

  project_points <- sf::st_as_sf(
    projects,
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  )

  province_matches <- sf::st_within(project_points, provinces_wgs84)
  match_counts <- lengths(province_matches)

  if (any(match_counts > 1)) {
    stop(
      "A project matched multiple province polygons; provincial geometry must be non-overlapping",
      call. = FALSE
    )
  }

  matched_index <- vapply(
    province_matches,
    function(index) if (length(index) == 1) index[[1]] else NA_integer_,
    integer(1)
  )

  spatial_province <- rep(NA_character_, nrow(project_points))
  province_code <- rep(NA_character_, nrow(project_points))
  has_spatial_match <- !is.na(matched_index)

  spatial_province[has_spatial_match] <- as.character(
    provinces_wgs84$nombre[matched_index[has_spatial_match]]
  )
  province_code[has_spatial_match] <- as.character(
    provinces_wgs84[[province_code_field]][matched_index[has_spatial_match]]
  )

  source_province <- as.character(project_points$source_province)
  province_match <- rep(NA, nrow(project_points))
  comparable <-
    has_spatial_match &
    !is.na(source_province) &
    nzchar(trimws(source_province))

  province_match[comparable] <-
    tolower(trimws(source_province[comparable])) ==
    tolower(trimws(spatial_province[comparable]))

  project_points$spatial_province <- spatial_province
  project_points$province_code <- province_code
  project_points$province_match <- province_match

  project_points
}
