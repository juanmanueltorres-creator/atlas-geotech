repo_root <- normalizePath(file.path("..", ".."), mustWork = TRUE)
app_path <- file.path(repo_root, "app.R")

write_entrypoint_fixture <- function(directory) {
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

test_that("root app.R exists", {
  expect_true(file.exists(app_path))
})

if (file.exists(app_path)) {
  test_that("root app.R builds a Shiny app from ATLAS_DATA_DIR", {
    directory <- tempfile("atlas-entrypoint-")
    on.exit(unlink(directory, recursive = TRUE), add = TRUE)
    write_entrypoint_fixture(directory)

    old_wd <- getwd()
    old_data_dir <- Sys.getenv("ATLAS_DATA_DIR", unset = NA_character_)
    on.exit(setwd(old_wd), add = TRUE)
    on.exit({
      if (is.na(old_data_dir)) {
        Sys.unsetenv("ATLAS_DATA_DIR")
      } else {
        Sys.setenv(ATLAS_DATA_DIR = old_data_dir)
      }
    }, add = TRUE)

    setwd(repo_root)
    Sys.setenv(ATLAS_DATA_DIR = directory)

    env <- new.env(parent = globalenv())
    sys.source("app.R", envir = env)

    expect_true(exists("app", envir = env, inherits = FALSE))
    expect_s3_class(env$app, "shiny.appobj")
  })
}
