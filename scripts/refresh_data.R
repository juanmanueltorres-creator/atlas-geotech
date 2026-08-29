refresh_atlas_data <- function(
  siacam_source,
  provinces_source,
  output_dir,
  retrieved_at = Sys.time(),
  siacam_source_url = siacam_source,
  provinces_source_url = provinces_source,
  source_last_known_update = NA_character_
) {
  raw_projects <- read_siacam_xlsx(siacam_source)
  cleaned_projects <- clean_projects(raw_projects)
  validation <- validate_projects(cleaned_projects)

  provinces <- read_argentina_provinces(provinces_source)
  spatial_projects <- build_spatial_projects(validation$valid, provinces)

  retrieved_at_utc <- format(
    as.POSIXct(retrieved_at, tz = "UTC"),
    "%Y-%m-%dT%H:%M:%SZ",
    tz = "UTC"
  )

  metadata <- data.frame(
    source_name = c(
      "SIACAM mining projects",
      "Argentina provincial boundaries"
    ),
    source_url = c(
      as.character(siacam_source_url),
      as.character(provinces_source_url)
    ),
    retrieved_at = rep(retrieved_at_utc, 2),
    source_last_known_update = c(
      as.character(source_last_known_update),
      NA_character_
    ),
    method = c(
      "XLSX -> normalize -> validate -> point-in-polygon",
      "GeoJSON -> sf -> EPSG:4326"
    ),
    limitations = c(
      "Project attributes and freshness depend on the upstream SIACAM publication; spatial province is derived independently from coordinates.",
      "Administrative boundaries provide territorial context and do not represent mining rights, cadastral parcels, or project footprints."
    ),
    row_count_raw = c(nrow(raw_projects), nrow(provinces)),
    row_count_valid = c(nrow(validation$valid), nrow(provinces)),
    issue_count = c(nrow(validation$issues), 0L),
    stringsAsFactors = FALSE
  )

  staging_dir <- tempfile("atlas-refresh-staging-")
  dir.create(staging_dir, recursive = TRUE)
  on.exit(unlink(staging_dir, recursive = TRUE), add = TRUE)

  staged_paths <- file.path(
    staging_dir,
    c("projects.csv", "projects.geojson", "metadata.csv")
  )

  readr::write_csv(
    sf::st_drop_geometry(spatial_projects),
    staged_paths[[1]],
    na = ""
  )

  sf::st_write(
    spatial_projects,
    staged_paths[[2]],
    driver = "GeoJSON",
    quiet = TRUE
  )

  readr::write_csv(metadata, staged_paths[[3]], na = "")

  staged_ok <- file.exists(staged_paths) & file.info(staged_paths)$size > 0
  if (!all(staged_ok)) {
    stop("Refresh staging did not produce all required artifacts", call. = FALSE)
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  output_paths <- file.path(
    output_dir,
    c("projects.csv", "projects.geojson", "metadata.csv")
  )

  publish_paths <- paste0(output_paths, ".next")
  on.exit(unlink(publish_paths[file.exists(publish_paths)]), add = TRUE)

  copied <- file.copy(staged_paths, publish_paths, overwrite = TRUE)
  if (!all(copied)) {
    stop("Unable to stage processed Atlas artifacts for publication", call. = FALSE)
  }

  publish_ok <- file.exists(publish_paths) & file.info(publish_paths)$size > 0
  if (!all(publish_ok)) {
    stop("Published Atlas artifact staging is incomplete", call. = FALSE)
  }

  for (index in seq_along(output_paths)) {
    if (file.exists(output_paths[[index]]) && !file.remove(output_paths[[index]])) {
      stop(
        sprintf("Unable to replace existing artifact: %s", output_paths[[index]]),
        call. = FALSE
      )
    }

    if (!file.rename(publish_paths[[index]], output_paths[[index]])) {
      stop(
        sprintf("Unable to publish refreshed artifact: %s", output_paths[[index]]),
        call. = FALSE
      )
    }
  }

  list(
    paths = stats::setNames(
      output_paths,
      c("projects_csv", "projects_geojson", "metadata_csv")
    ),
    issues = validation$issues,
    metadata = metadata
  )
}
