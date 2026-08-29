app_path <- file.path("..", "..", "R", "build_atlas_app.R")

source(app_path)

projects <- data.frame(
  name = c("Proyecto A", "Proyecto <B>"),
  commodity = c("Cobre", NA_character_),
  stage = c("Exploración", NA_character_),
  source_province = c("San Juan", "Salta"),
  spatial_province = c("San Juan", "Jujuy"),
  province_match = c(TRUE, FALSE),
  stringsAsFactors = FALSE
)

test_that("build_project_popup is available", {
  expect_true(exists("build_project_popup", mode = "function"))
})

if (exists("build_project_popup", mode = "function")) {
  test_that("project popups preserve source and spatial province truth", {
    popup <- build_project_popup(projects)

    expect_length(popup, 2)
    expect_match(popup[[1]], "Proyecto A", fixed = TRUE)
    expect_match(popup[[1]], "Cobre", fixed = TRUE)
    expect_match(popup[[1]], "Exploración", fixed = TRUE)
    expect_match(popup[[1]], "Provincia declarada", fixed = TRUE)
    expect_match(popup[[1]], "Provincia espacial", fixed = TRUE)
    expect_match(popup[[1]], "San Juan", fixed = TRUE)
    expect_match(popup[[1]], "Coinciden", fixed = TRUE)
  })

  test_that("missing values are explicit and territorial mismatches are visible", {
    popup <- build_project_popup(projects)

    expect_match(popup[[2]], "Sin dato", fixed = TRUE)
    expect_match(popup[[2]], "Salta", fixed = TRUE)
    expect_match(popup[[2]], "Jujuy", fixed = TRUE)
    expect_match(popup[[2]], "Discrepancia territorial", fixed = TRUE)
  })

  test_that("popup values are HTML escaped", {
    popup <- build_project_popup(projects)

    expect_false(grepl("Proyecto <B>", popup[[2]], fixed = TRUE))
    expect_match(popup[[2]], "Proyecto &lt;B&gt;", fixed = TRUE)
  })
}
