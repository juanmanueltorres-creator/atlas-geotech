source(file.path("..", "..", "R", "clean_projects.R"))

validation_path <- file.path("..", "..", "R", "validate_projects.R")
if (file.exists(validation_path)) {
  source(validation_path)
}

projects <- data.frame(
  project_id = c("1", "2", "3", "4", "5"),
  name = c("Proyecto válido", NA, "Latitud inválida", "Sin mineral", "Sin etapa"),
  latitude = c(-29.1, -24.5, -95, -31, -30),
  longitude = c(-69.1, -66.2, -68, -68, -67),
  commodity = c("Cobre", "Litio", "Oro", NA, "Cobre"),
  source_province = c("San Juan", "Jujuy", "San Juan", "San Juan", "Mendoza"),
  stage = c("Exploración", "Producción", "Exploración", "Exploración", NA),
  controller_1 = NA_character_,
  share_1 = NA_character_,
  origin_1 = NA_character_,
  controller_2 = NA_character_,
  share_2 = NA_character_,
  origin_2 = NA_character_,
  controller_3 = NA_character_,
  share_3 = NA_character_,
  origin_3 = NA_character_,
  stringsAsFactors = FALSE
)

test_that("validate_projects is available", {
  expect_true(exists("validate_projects", mode = "function"))
})

if (exists("validate_projects", mode = "function")) {
  result <- validate_projects(projects)

  test_that("validate_projects returns valid rows and explicit issues", {
    expect_named(result, c("valid", "issues"))
    expect_s3_class(result$valid, "data.frame")
    expect_s3_class(result$issues, "data.frame")
    expect_identical(
      names(result$issues),
      c("project_id", "field", "code", "severity")
    )
  })

  test_that("blocking identity and coordinate errors are excluded from valid rows", {
    expect_identical(result$valid$project_id, c("1", "4", "5"))

    expect_true(any(
      result$issues$project_id == "2" &
        result$issues$field == "name" &
        result$issues$code == "missing_name" &
        result$issues$severity == "error"
    ))

    expect_true(any(
      result$issues$project_id == "3" &
        result$issues$field == "latitude" &
        result$issues$code == "invalid_latitude" &
        result$issues$severity == "error"
    ))
  })

  test_that("missing commodity or stage is reported without dropping the project", {
    expect_true("4" %in% result$valid$project_id)
    expect_true("5" %in% result$valid$project_id)

    expect_true(any(
      result$issues$project_id == "4" &
        result$issues$field == "commodity" &
        result$issues$code == "missing_commodity" &
        result$issues$severity == "warning"
    ))

    expect_true(any(
      result$issues$project_id == "5" &
        result$issues$field == "stage" &
        result$issues$code == "missing_stage" &
        result$issues$severity == "warning"
    ))
  })

  test_that("validation never replaces missing values with zero", {
    expect_true(is.na(result$valid$commodity[result$valid$project_id == "4"]))
    expect_true(is.na(result$valid$stage[result$valid$project_id == "5"]))
  })
}
