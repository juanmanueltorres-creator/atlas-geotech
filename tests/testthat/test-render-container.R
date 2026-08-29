repo_root <- normalizePath(file.path("..", ".."), mustWork = TRUE)
dockerfile_path <- file.path(repo_root, "Dockerfile")

test_that("Render Dockerfile exists", {
  expect_true(file.exists(dockerfile_path))
})

if (file.exists(dockerfile_path)) {
  dockerfile <- paste(readLines(dockerfile_path, warn = FALSE), collapse = "\n")

  test_that("Render container binds Shiny to all interfaces", {
    expect_match(dockerfile, "0\\.0\\.0\\.0")
  })

  test_that("Render container uses the platform PORT with a 10000 fallback", {
    expect_match(dockerfile, "Sys\\.getenv\\(.*PORT")
    expect_match(dockerfile, "10000")
  })

  test_that("Render image installs the app runtime dependencies", {
    for (package in c("dplyr", "leaflet", "readr", "readxl", "sf", "shiny", "stringr", "tidyr")) {
      expect_match(dockerfile, package, fixed = TRUE)
    }
  })

  test_that("Render image starts the repository root Shiny app", {
    expect_match(dockerfile, "shiny::runApp")
    expect_match(dockerfile, "WORKDIR /app", fixed = TRUE)
  })
}
