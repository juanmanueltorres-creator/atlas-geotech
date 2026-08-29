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

test_that("capital summary is formatted with user-facing Spanish columns", {
  expect_true(
    exists("atlas_capital_table_data", mode = "function"),
    info = "Capital Map requires a table presentation helper"
  )

  if (!exists("atlas_capital_table_data", mode = "function")) {
    return(invisible())
  }

  summary <- data.frame(
    capital_origin = "Canadá",
    project_count = 2L,
    province_count = 2L,
    commodity_count = 2L,
    controller_count = 2L,
    top_controllers = "Empresa B · Empresa C",
    stringsAsFactors = FALSE
  )

  table <- atlas_capital_table_data(summary)

  expect_named(
    table,
    c(
      "Origen",
      "Proyectos",
      "Provincias",
      "Minerales",
      "Controlantes",
      "Controlantes con más proyectos"
    )
  )
  expect_equal(table$Origen, "Canadá")
  expect_equal(table$Proyectos, 2L)
  expect_equal(table[["Controlantes con más proyectos"]], "Empresa B · Empresa C")
})

test_that("Capital Map UI adds Capital without replacing the territorial map", {
  ui <- build_atlas_ui(projects, metadata)
  html <- as.character(ui)

  expect_match(html, "Territorio", fixed = TRUE)
  expect_match(html, "Capital", fixed = TRUE)
  expect_match(html, 'id="map"', fixed = TRUE)
  expect_match(html, 'id="capital_table"', fixed = TRUE)
  expect_match(
    html,
    "Origen de capital según campo informado por SIACAM; no implica domicilio corporativo ni propiedad actual.",
    fixed = TRUE
  )
})

test_that("Capital table reacts to existing project and origin filters", {
  app <- build_atlas_app(projects, metadata)
  server <- app$serverFuncSource()

  shiny::testServer(server, {
    session$setInputs(
      province = "Todos",
      mineral = "Todos",
      stage = "Todos",
      capital_origin = "Todos"
    )

    expect_match(output$capital_table, "Canadá", fixed = TRUE)
    expect_match(output$capital_table, "Argentina", fixed = TRUE)

    session$setInputs(capital_origin = "Argentina")
    expect_match(output$capital_table, "Argentina", fixed = TRUE)
    expect_false(grepl("Canadá", output$capital_table, fixed = TRUE))

    session$setInputs(province = "Jujuy", capital_origin = "Todos")
    expect_match(output$capital_table, "Canadá", fixed = TRUE)
    expect_false(grepl("Argentina", output$capital_table, fixed = TRUE))
  })
})
