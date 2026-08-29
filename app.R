source("R/filter_projects.R", local = TRUE)
source("R/read_processed_data.R", local = TRUE)
source("R/extract_project_companies.R", local = TRUE)
source("R/build_atlas_app.R", local = TRUE)
source("R/run_atlas_app.R", local = TRUE)

atlas_data_dir <- Sys.getenv(
  "ATLAS_DATA_DIR",
  unset = file.path("data", "processed")
)

app <- build_atlas_app_from_processed(atlas_data_dir)
app
