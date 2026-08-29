app_path <- file.path("..", "..", "R", "build_atlas_app.R")
filter_path <- file.path("..", "..", "R", "filter_projects.R")
canonicalize_path <- file.path("..", "..", "R", "canonicalize_company_values.R")
companies_path <- file.path("..", "..", "R", "extract_project_companies.R")
summary_path <- file.path("..", "..", "R", "summarize_capital_origins.R")
capital_map_path <- file.path("..", "..", "R", "capital_map.R")

source(canonicalize_path)
source(companies_path)
source(summary_path)
source(filter_path)
source(app_path)
source(capital_map_path)

projects <- sf::st_as_sf(
  data.frame(
    project_id = c("1", "2"),
    name = c("Proyecto Cobre", "Proyecto Oro"),
    latitude = c(-29.1, -23.5),
    longitude = c(-69.1, -66.2),
    commodity = c("Cobre", "Oro"),
    source_province = c("San Juan", "Jujuy"),
    stage = c("Exploración", "Producción"),
    spatial_province = c("San Juan", "Jujuy"),
    province_code = c("70", "38"),
    province_match = c(TRUE, TRUE),
    controller_1 = c("Empresa A", "Empresa C"),
    share_1 = c("80%", "100%"),
    origin_1 = c("Argentina", "Canadá"),
    controller_2 = c("Empresa B", NA_character_),
    share_2 = c("20%", NA_character_),
    origin_2 = c("Canadá", NA_character_),
    controller_3 = c(NA_character_, NA_character_),
    share_3 = c(NA_character_, NA_character_),
    origin_3 = c(NA_character_, NA_character_),
    stringsAsFactors = FALSE
  ),
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)

metadata <- data.frame(
  source_name = "SIACAM mining projects",
  retrieved_at = "2026-08-28T23:00:00Z",
  stringsAsFactors = FALSE
)

test_that("Atlas exposes a capital origin filter when company data is available", {
  ui <- build_atlas_ui(projects, metadata)
  html <- as.character(ui)

  expect_match(html, 'id="capital_origin"', fixed = TRUE)
  expect_match(html, "Origen del capital", fixed = TRUE)
  expect_match(html, "Argentina", fixed = TRUE)
  expect_match(html, "Canadá", fixed = TRUE)
})

test_that("capital origin filter narrows projects without changing existing filters", {
  app <- build_atlas_app(projects, metadata)
  server <- app$serverFuncSource()

  shiny::testServer(server, {
    session$setInputs(
      province = "Todos",
      mineral = "Todos",
      stage = "Todos",
      capital_origin = "Todos"
    )
    expect_equal(output$project_count, "2 proyectos")

    session$setInputs(capital_origin = "Argentina")
    expect_equal(output$project_count, "1 proyecto")

    session$setInputs(capital_origin = "Canadá")
    expect_equal(output$project_count, "2 proyectos")

    session$setInputs(province = "Jujuy", capital_origin = "Argentina")
    expect_equal(output$project_count, "0 proyectos")
  })
})

test_that("capital origin choices expose only the verified canonical alias", {
  alias_projects <- projects
  alias_projects$origin_1 <- c("Paises Bajos", "Países Bajos")
  alias_projects$origin_2 <- c(NA_character_, NA_character_)

  ui <- build_atlas_ui(alias_projects, metadata)
  html <- as.character(ui)

  expect_match(html, "Países Bajos", fixed = TRUE)
  expect_false(grepl("Paises Bajos", html, fixed = TRUE))
})

test_that("canonical capital origin filter matches projects from both source spellings", {
  alias_projects <- projects
  alias_projects$origin_1 <- c("Paises Bajos", "Países Bajos")
  alias_projects$origin_2 <- c(NA_character_, NA_character_)

  app <- build_atlas_app(alias_projects, metadata)
  server <- app$serverFuncSource()

  shiny::testServer(server, {
    session$setInputs(
      province = "Todos",
      mineral = "Todos",
      stage = "Todos",
      capital_origin = "Países Bajos"
    )

    expect_equal(output$project_count, "2 proyectos")
  })
})

test_that("capital summary respects project filters and does not reintroduce mixed origins", {
  expect_true(
    exists("atlas_capital_summary", mode = "function"),
    info = "Capital Map requires a helper that applies project and origin filters to the company relation"
  )

  if (!exists("atlas_capital_summary", mode = "function")) {
    return(invisible())
  }

  companies <- atlas_project_companies(projects)

  all_summary <- atlas_capital_summary(projects, companies, "Todos")
  expect_equal(all_summary$capital_origin, c("Canadá", "Argentina"))
  expect_equal(all_summary$project_count, c(2L, 1L))

  argentina_summary <- atlas_capital_summary(projects, companies, "Argentina")
  expect_equal(argentina_summary$capital_origin, "Argentina")
  expect_equal(argentina_summary$project_count, 1L)

  jujuy_projects <- filter_projects(projects, province = "Jujuy")
  jujuy_summary <- atlas_capital_summary(jujuy_projects, companies, "Todos")
  expect_equal(jujuy_summary$capital_origin, "Canadá")
  expect_equal(jujuy_summary$project_count, 1L)
})
