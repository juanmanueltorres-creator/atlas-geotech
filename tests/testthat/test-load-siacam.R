loader_path <- file.path("..", "..", "R", "load_sources.R")
if (file.exists(loader_path)) {
  source(loader_path)
}

fixture_path <- file.path("..", "fixtures", "siacam_projects.csv")
fixture_projects <- utils::read.csv(
  fixture_path,
  check.names = FALSE,
  na.strings = c("", "NA"),
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)

test_that("read_siacam_xlsx is available", {
  expect_true(exists("read_siacam_xlsx", mode = "function"))
})

if (exists("read_siacam_xlsx", mode = "function")) {
  test_that("read_siacam_xlsx reads an XLSX without changing the source schema", {
    workbook <- tempfile(fileext = ".xlsx")
    writexl::write_xlsx(list(Cartera = fixture_projects), workbook)

    result <- read_siacam_xlsx(workbook)

    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), nrow(fixture_projects))
    expect_identical(names(result), names(fixture_projects))
    expect_identical(as.character(result[["NOMBRE"]][[1]]), "Proyecto Uno")
  })

  test_that("read_siacam_xlsx fails explicitly when the source cannot be read", {
    missing_file <- file.path(tempdir(), "siacam-does-not-exist.xlsx")

    expect_error(
      read_siacam_xlsx(missing_file),
      regexp = "SIACAM XLSX"
    )
  })
}
