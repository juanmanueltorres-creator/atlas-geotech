read_atlas_processed_data <- function(directory) {
  projects_path <- file.path(directory, "projects.geojson")
  metadata_path <- file.path(directory, "metadata.csv")

  required_paths <- c(projects_path, metadata_path)
  if (!all(file.exists(required_paths))) {
    stop("Missing processed Atlas artifacts", call. = FALSE)
  }

  projects <- sf::st_read(projects_path, quiet = TRUE)
  metadata <- readr::read_csv(metadata_path, show_col_types = FALSE)

  if (nrow(projects) == 0) {
    stop("Processed Atlas projects are empty", call. = FALSE)
  }

  if (is.na(sf::st_crs(projects))) {
    stop("Processed Atlas projects have no CRS", call. = FALSE)
  }

  if (sf::st_crs(projects)$epsg != 4326) {
    projects <- sf::st_transform(projects, 4326)
  }

  list(
    projects = projects,
    metadata = metadata
  )
}
