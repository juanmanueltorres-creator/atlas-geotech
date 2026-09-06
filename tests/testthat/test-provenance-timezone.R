app_path <- file.path("..", "..", "R", "build_atlas_app.R")

if (file.exists(app_path)) {
  source(app_path)
}

test_that("provenance formatter handles readr-parsed UTC timestamps", {
  metadata_path <- tempfile(fileext = ".csv")
  writeLines(
    c(
      "retrieved_at",
      "2026-08-28T23:24:37Z"
    ),
    metadata_path
  )

  parsed_metadata <- readr::read_csv(metadata_path, show_col_types = FALSE)

  expect_s3_class(parsed_metadata$retrieved_at, "POSIXct")
  expect_equal(
    atlas_format_retrieved_at(parsed_metadata$retrieved_at),
    "28/08/2026 · 20:24 ART"
  )
})

test_that("provenance formatter still handles raw ISO UTC text", {
  expect_equal(
    atlas_format_retrieved_at("2026-08-28T23:24:37Z"),
    "28/08/2026 · 20:24 ART"
  )
})
