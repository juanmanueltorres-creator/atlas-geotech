loader_path <- file.path("..", "..", "R", "read_processed_data.R")
filter_path <- file.path("..", "..", "R", "filter_projects.R")
app_builder_path <- file.path("..", "..", "R", "build_atlas_app.R")
runner_path <- file.path("..", "..", "R", "run_atlas_app.R")

source(loader_path)
source(filter_path)
source(app_builder_path)

if (file.exists(runner_path)) {
  source(runner_path)
}

write_app_fixture <- function(directory) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)

  projects <- sf::st_as_sf(
    data.frame(
      project_id = "1",
      name = "Proyecto A",
      commodity = "Cobre",
      stage = "Exploración",
      source_province = "San Juan",
      spatial_province = "San Juan",
      province_code = "70",
      province_match = TRUE,
      longitude = -69.1,
      latitude = -29.1,
      stringsAsFactors = FALSE
    ),
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  )

  sf::st_write(
    projects,
    file.path(directory, "projects.geojson"),
    driver = "GeoJSON",
    quiet = TRUE
  )

  readr::write_csv(
    data.frame(
      source_name = "SIACAM mining projects",
      source_url = "https://example.test/siacam.xlsx",
      retrieved_at = "2026-08-28T21:00:00Z",
      stringsAsFactors = FALSE
    ),
    file.path(directory, "metadata.csv")
  )
}

test_that("build_atlas_app_from_processed is available", {
  expect_true(exists("build_atlas_app_from_processed", mode = "function"))
})

if (exists("build_atlas_app_from_processed", mode = "function")) {
  test_that("processed Atlas artifacts build a Shiny app", {
    directory <- tempfile("atlas-app-")
    on.exit(unlink(directory, recursive = TRUE), add = TRUE)
    write_app_fixture(directory)

    app <- build_atlas_app_from_processed(directory)

    expect_s3_class(app, "shiny.appobj")
  })

  test_that("Atlas app runner propagates missing artifact errors", {
    directory <- tempfile("atlas-app-missing-")
    dir.create(directory)
    on.exit(unlink(directory, recursive = TRUE), add = TRUE)

    expect_error(
      build_atlas_app_from_processed(directory),
      "Missing processed Atlas artifacts"
    )
  })
}
