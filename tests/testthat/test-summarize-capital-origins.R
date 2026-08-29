summary_path <- file.path("..", "..", "R", "summarize_capital_origins.R")

if (file.exists(summary_path)) {
  source(summary_path)
}

test_that("capital summary aggregates distinct territorial reach by origin", {
  expect_true(
    exists("summarize_capital_origins", mode = "function"),
    info = "Capital Map requires a pure summarize_capital_origins() helper"
  )

  if (!exists("summarize_capital_origins", mode = "function")) {
    return(invisible())
  }

  projects <- data.frame(
    project_id = c("1", "2", "3", "4"),
    spatial_province = c("San Juan", "San Juan", "Jujuy", "Salta"),
    commodity = c("Cobre", "Oro", "Litio", "Cobre"),
    stringsAsFactors = FALSE
  )

  companies <- data.frame(
    project_id = c("1", "1", "2", "3", "4", "4"),
    company_name = c("Alpha", "Beta", "Alpha", "Gamma", "Delta", "Alpha"),
    capital_origin = c("Canadá", "Argentina", "Canadá", "Argentina", "Canadá", "Canadá"),
    stringsAsFactors = FALSE
  )

  summary <- summarize_capital_origins(projects, companies)

  expect_named(
    summary,
    c(
      "capital_origin",
      "project_count",
      "province_count",
      "commodity_count",
      "controller_count",
      "top_controllers"
    )
  )
  expect_equal(summary$capital_origin, c("Canadá", "Argentina"))
  expect_equal(summary$project_count, c(3L, 2L))
  expect_equal(summary$province_count, c(2L, 2L))
  expect_equal(summary$commodity_count, c(2L, 2L))
  expect_equal(summary$controller_count, c(2L, 2L))
  expect_equal(summary$top_controllers, c("Alpha · Delta", "Beta · Gamma"))
})
