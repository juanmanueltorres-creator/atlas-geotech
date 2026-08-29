clean_path <- file.path("..", "..", "R", "clean_projects.R")
validate_path <- file.path("..", "..", "R", "validate_projects.R")
loader_path <- file.path("..", "..", "R", "load_sources.R")
spatial_path <- file.path("..", "..", "R", "build_spatial_projects.R")
refresh_path <- file.path("..", "..", "scripts", "refresh_data.R")

source(clean_path)
source(validate_path)
source(loader_path)
source(spatial_path)

if (file.exists(refresh_path)) {
  source(refresh_path)
}

make_refresh_fixture <- function() {
  raw <- utils::read.csv(
    file.path("..", "fixtures", "siacam_projects.csv"),
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8"
  )

  path <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(raw, path)
  path
}

test_that("refresh_atlas_data is available", {
  expect_true(exists("refresh_atlas_data", mode = "function"))
})

if (exists("refresh_atlas_data", mode = "function")) {
  test_that("refresh writes validated CSV, GeoJSON, and provenance metadata", {
    siacam_path <- make_refresh_fixture()
    on.exit(unlink(siacam_path), add = TRUE)

    output_dir <- tempfile("atlas-refresh-")
    on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

    result <- refresh_atlas_data(
      siacam_source = siacam_path,
      provinces_source = file.path("..", "fixtures", "provinces.geojson"),
      output_dir = output_dir,
      retrieved_at = as.POSIXct("2026-08-28 21:00:00", tz = "UTC"),
      siacam_source_url = "https://example.test/siacam.xlsx",
      provinces_source_url = "https://example.test/provinces.geojson",
      source_last_known_update = "2025-02-19"
    )

    expected_paths <- file.path(
      output_dir,
      c("projects.csv", "projects.geojson", "metadata.csv")
    )

    expect_true(all(file.exists(expected_paths)))
    expect_identical(unname(result$paths), expected_paths)

    projects_csv <- suppressMessages(readr::read_csv(expected_paths[[1]], show_col_types = FALSE))
    projects_geo <- sf::st_read(expected_paths[[2]], quiet = TRUE)
    metadata <- suppressMessages(readr::read_csv(expected_paths[[3]], show_col_types = FALSE))

    expect_equal(nrow(projects_csv), 3)
    expect_equal(nrow(projects_geo), 3)
    expect_true(all(c("source_province", "spatial_province", "province_code", "province_match") %in% names(projects_csv)))

    required_metadata <- c(
      "source_name",
      "source_url",
      "retrieved_at",
      "source_last_known_update",
      "method",
      "limitations",
      "row_count_raw",
      "row_count_valid",
      "issue_count"
    )

    expect_true(all(required_metadata %in% names(metadata)))
    expect_equal(nrow(metadata), 2)

    siacam_metadata <- metadata[metadata$source_name == "SIACAM mining projects", , drop = FALSE]
    expect_equal(nrow(siacam_metadata), 1)
    expect_equal(siacam_metadata$row_count_raw, 3)
    expect_equal(siacam_metadata$row_count_valid, 3)
    expect_equal(siacam_metadata$issue_count, 1)
    expect_identical(siacam_metadata$source_url, "https://example.test/siacam.xlsx")
  })

  test_that("refresh fails closed before replacing an existing processed dataset", {
    output_dir <- tempfile("atlas-refresh-existing-")
    dir.create(output_dir, recursive = TRUE)
    on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

    existing_projects <- file.path(output_dir, "projects.csv")
    writeLines("known-good-dataset", existing_projects)

    expect_error(
      refresh_atlas_data(
        siacam_source = file.path(output_dir, "missing.xlsx"),
        provinces_source = file.path("..", "fixtures", "provinces.geojson"),
        output_dir = output_dir,
        retrieved_at = as.POSIXct("2026-08-28 21:00:00", tz = "UTC"),
        siacam_source_url = "https://example.test/missing.xlsx",
        provinces_source_url = "https://example.test/provinces.geojson",
        source_last_known_update = "2025-02-19"
      )
    )

    expect_identical(readLines(existing_projects), "known-good-dataset")
    expect_false(file.exists(file.path(output_dir, "projects.geojson")))
    expect_false(file.exists(file.path(output_dir, "metadata.csv")))
  })
}
