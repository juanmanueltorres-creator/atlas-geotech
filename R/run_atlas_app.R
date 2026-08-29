build_atlas_app_from_processed <- function(directory = file.path("data", "processed")) {
  data <- read_atlas_processed_data(directory)
  build_atlas_app(data$projects, data$metadata)
}
