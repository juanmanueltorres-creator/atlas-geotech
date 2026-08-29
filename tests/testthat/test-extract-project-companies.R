source_path <- file.path("..", "..", "R", "extract_project_companies.R")
if (file.exists(source_path)) {
  source(source_path)
}

projects <- data.frame(
  project_id = c("1", "2", "3", "4"),
  name = c(
    "Proyecto Uno",
    "Proyecto Dos",
    "Proyecto Tres",
    "Proyecto Cuatro"
  ),
  controller_1 = c("Empresa A", "Empresa C", NA_character_, "Empresa D"),
  share_1 = c("80%", "100%", NA_character_, "-"),
  origin_1 = c("Argentina", NA_character_, NA_character_, "-"),
  controller_2 = c("Empresa B", NA_character_, NA_character_, "-"),
  share_2 = c("20%", NA_character_, NA_character_, "-"),
  origin_2 = c("Canadá", NA_character_, NA_character_, "-"),
  controller_3 = c(NA_character_, NA_character_, NA_character_, "-"),
  share_3 = c(NA_character_, NA_character_, NA_character_, "-"),
  origin_3 = c(NA_character_, NA_character_, NA_character_, "-"),
  stringsAsFactors = FALSE
)

test_that("extract_project_companies is available", {
  expect_true(exists("extract_project_companies", mode = "function"))
})

if (exists("extract_project_companies", mode = "function")) {
  test_that("extract_project_companies returns one row per declared controller", {
    companies <- extract_project_companies(projects)

    expect_equal(nrow(companies), 4)
    expect_identical(
      names(companies),
      c(
        "project_id",
        "project_name",
        "company_rank",
        "company_name",
        "share_text",
        "capital_origin"
      )
    )
  })

  test_that("extract_project_companies preserves controller rank and source values", {
    companies <- extract_project_companies(projects)

    project_one <- companies[companies$project_id == "1", , drop = FALSE]

    expect_identical(project_one$company_rank, c(1L, 2L))
    expect_identical(project_one$company_name, c("Empresa A", "Empresa B"))
    expect_identical(project_one$share_text, c("80%", "20%"))
    expect_identical(project_one$capital_origin, c("Argentina", "Canadá"))
  })

  test_that("extract_project_companies keeps missing share or origin explicit", {
    companies <- extract_project_companies(projects)
    company_c <- companies[companies$company_name == "Empresa C", , drop = FALSE]

    expect_equal(nrow(company_c), 1)
    expect_identical(company_c$share_text, "100%")
    expect_true(is.na(company_c$capital_origin))
  })

  test_that("SIACAM dash placeholders are absent from the derived company relation", {
    companies <- extract_project_companies(projects)
    company_d <- companies[companies$company_name == "Empresa D", , drop = FALSE]

    expect_equal(nrow(company_d), 1)
    expect_true(is.na(company_d$share_text))
    expect_true(is.na(company_d$capital_origin))
    expect_false("-" %in% companies$company_name)
    expect_false("-" %in% stats::na.omit(companies$capital_origin))
  })

  test_that("extract_project_companies does not invent rows without a controller", {
    companies <- extract_project_companies(projects)

    expect_false("3" %in% companies$project_id)
  })

  test_that("extract_project_companies fails clearly when required fields are missing", {
    incomplete <- projects[, setdiff(names(projects), "origin_2"), drop = FALSE]

    expect_error(
      extract_project_companies(incomplete),
      "origin_2",
      fixed = TRUE
    )
  })
}
