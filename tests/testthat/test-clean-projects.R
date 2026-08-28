if (file.exists("R/clean_projects.R")) {
  source("R/clean_projects.R")
}

fixture_path <- "tests/fixtures/siacam_projects.csv"
raw_projects <- utils::read.csv(
  fixture_path,
  check.names = FALSE,
  na.strings = c("", "NA"),
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)

test_that("clean_projects is available", {
  expect_true(exists("clean_projects", mode = "function"))
})

if (exists("clean_projects", mode = "function")) {
  test_that("clean_projects exposes the V0 normalized schema", {
    projects <- clean_projects(raw_projects)

    expect_identical(
      names(projects),
      c(
        "project_id",
        "name",
        "latitude",
        "longitude",
        "commodity",
        "source_province",
        "stage",
        "controller_1",
        "share_1",
        "origin_1",
        "controller_2",
        "share_2",
        "origin_2",
        "controller_3",
        "share_3",
        "origin_3"
      )
    )
  })

  test_that("clean_projects trims text without inventing missing values", {
    projects <- clean_projects(raw_projects)

    expect_identical(projects$name[[2]], "Proyecto Dos")
    expect_identical(projects$commodity[[2]], "Litio")
    expect_true(is.na(projects$commodity[[3]]))
    expect_true(is.na(projects$controller_1[[3]]))
  })

  test_that("clean_projects preserves SIACAM stage labels and numeric coordinates", {
    projects <- clean_projects(raw_projects)

    expect_type(projects$latitude, "double")
    expect_type(projects$longitude, "double")
    expect_identical(projects$stage[[1]], "Exploración")
    expect_equal(projects$latitude[[1]], -29.1)
    expect_equal(projects$longitude[[1]], -69.1)
  })

  test_that("clean_projects keeps the SIACAM row id as a stable character id", {
    projects <- clean_projects(raw_projects)

    expect_identical(projects$project_id, c("1", "2", "3"))
  })
}
