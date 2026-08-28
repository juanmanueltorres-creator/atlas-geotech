loader_path <- file.path("..", "..", "R", "read_processed_data.R")

if (file.exists(loader_path)) {
  source(loader_path)
}

write_processed_fixture <- function(directory) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)

  projects <- sf::st_as_sf(
    data.frame(
      project_id = c("1", "2"),
      name = c("Proyecto A", "Proyecto B"),
      commodity = c("Cobre", "Litio"),
      stage = c("Exploración", "Producción"),
      source_province = c("San Juan", "Jujuy"),
      spatial_province = c("San Juan", "Jujuy"),
      province_code = c("70", "38"),
      province_match = c(TRUE, TRUE),
      longitude = c(-69.1, -66.2),
      latitude = c(-29.1, -23.5),
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
      source_name = c("SIACAM mining projects", "Argentina provincial boundaries"),
      source_url = c("https://example.test/siacam.xlsx", "https://example.test/provinces.geojson"),
      retrieved_at = c("2026-08-28T21:00:00Z", "2026-08-28T21:00:00Z"),
      stringsAsFactors = FALSE
    ),
    file.path(directory, "metadata.csv")
  )
}

test_that("read_atlas_processed_data is available", {
  expect_true(exists("read_atlas_processed_data", mode = "function"))
})

if (exists("read_atlas_processed_data", mode = "function")) {
  test_that("processed loader returns sf projects and metadata", {
    directory <- tempfile("atlas-processed-")
    on.exit(unlink(directory, recursive = TRUE), add = TRUE)
    write_processed_fixture(directory)

    result <- read_atlas_processed_data(directory)

    expect_named(result, c("projects", "metadata"))
    expect_s3_class(result$projects, "sf")
    expect_equal(nrow(result$projects), 2)
    expect_equal(sf::st_crs(result$projects)$epsg, 4326)
    expect_equal(nrow(result$metadata), 2)
    expect_true(all(c("source_name", "source_url", "retrieved_at") %in% names(result$metadata)))
  })

  test_that("processed loader fails explicitly when required artifacts are missing", {
    directory <- tempfile("atlas-missing-")
    dir.create(directory)
    on.exit(unlink(directory, recursive = TRUE), add = TRUE)

    expect_error(
      read_atlas_processed_data(directory),
      "Missing processed Atlas artifacts"
    )
  })

  test_that("processed loader rejects empty project datasets", {
    directory <- tempfile("atlas-empty-")
    dir.create(directory)
    on.exit(unlink(directory, recursive = TRUE), add = TRUE)

    empty_projects <- sf::st_sf(
      name = character(),
      geometry = sf::st_sfc(crs = 4326)
    )
    sf::st_write(
      empty_projects,
      file.path(directory, "projects.geojson"),
      driver = "GeoJSON",
      quiet = TRUE
    )
    readr::write_csv(
      data.frame(
        source_name = "source",
        source_url = "https://example.test/source",
        retrieved_at = "2026-08-28T21:00:00Z"
      ),
      file.path(directory, "metadata.csv")
    )

    expect_error(
      read_atlas_processed_data(directory),
      "Processed Atlas projects are empty"
    )
  })
}
