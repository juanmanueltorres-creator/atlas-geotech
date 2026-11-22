build_atlas_app_from_processed <- function(directory = file.path("data", "processed")) {
  data <- read_atlas_processed_data(directory)
  oil <- if(exists("atlas_oil_read_snapshot", mode="function", inherits=TRUE))
    atlas_oil_read_snapshot(directory) else NULL
  build_atlas_app(data$projects, data$metadata, oil=oil)
}
