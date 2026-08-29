app_path <- file.path("..", "..", "R", "build_atlas_app.R")
filter_path <- file.path("..", "..", "R", "filter_projects.R")

if (file.exists(app_path)) {
  source(app_path)
}

if (file.exists(filter_path)) {
  source(filter_path)
}

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
    stringsAsFactors = FALSE
  ),
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)

metadata <- data.frame(
  source_name = c("SIACAM mining projects", "Argentina provincial boundaries"),
  source_url = c(
    "https://example.test/siacam.xlsx",
    "https://example.test/provinces.geojson"
  ),
  retrieved_at = c(
    "2026-08-28T23:00:00Z",
    "2026-08-28T23:00:00Z"
  ),
  stringsAsFactors = FALSE
)

test_that("minimal Atlas Shiny builders are available", {
  expect_true(exists("build_atlas_ui", mode = "function"))
  expect_true(exists("build_atlas_app", mode = "function"))
})

test_that("Atlas exposes the approved dark visual system", {
  expect_true(exists("atlas_theme_css", mode = "function"))
  expect_true(exists("atlas_basemap_provider", mode = "function"))

  if (
    exists("atlas_theme_css", mode = "function") &&
    exists("atlas_basemap_provider", mode = "function")
  ) {
    css <- atlas_theme_css()

    expect_match(css, "#0b1220", fixed = TRUE)
    expect_match(css, "#111827", fixed = TRUE)
    expect_match(css, "#c68a2b", fixed = TRUE)
    expect_match(css, ".leaflet-tile-pane", fixed = TRUE)
    expect_match(css, "filter:", fixed = TRUE)
    expect_equal(atlas_basemap_provider(), "OpenStreetMap.Mapnik")
  }
})

if (
  exists("build_atlas_ui", mode = "function") &&
  exists("build_atlas_app", mode = "function")
) {
  test_that("Atlas UI exposes the V0 filters, map, provenance, and project count", {
    ui <- build_atlas_ui(projects, metadata)
    html <- as.character(ui)

    expect_match(html, "Atlas Geotech", fixed = TRUE)
    expect_match(html, 'id="province"', fixed = TRUE)
    expect_match(html, 'id="mineral"', fixed = TRUE)
    expect_match(html, 'id="stage"', fixed = TRUE)
    expect_match(html, 'id="project_count"', fixed = TRUE)
    expect_match(html, 'class="atlas-project-count', fixed = TRUE)
    expect_match(html, 'id="map"', fixed = TRUE)
    expect_match(html, "82vh", fixed = TRUE)
    expect_match(html, 'id="provenance"', fixed = TRUE)
    expect_match(html, 'class="atlas-provenance', fixed = TRUE)
    expect_match(html, "SIACAM mining projects", fixed = TRUE)
    expect_match(html, "Argentina provincial boundaries", fixed = TRUE)
    expect_match(html, "Recuperado 28/08/2026 · 20:00 ART", fixed = TRUE)
    expect_false(grepl("2026-08-28T23:00:00Z", html, fixed = TRUE))
  })

  test_that("Atlas project count reacts to active filters", {
    app <- build_atlas_app(projects, metadata)
    server <- app$serverFuncSource()

    shiny::testServer(server, {
      session$setInputs(
        province = "Todos",
        mineral = "Todos",
        stage = "Todos"
      )
      expect_equal(output$project_count, "2 proyectos")

      session$setInputs(province = "San Juan")
      expect_equal(output$project_count, "1 proyecto")

      session$setInputs(mineral = "Oro")
      expect_equal(output$project_count, "0 proyectos")
    })
  })

  test_that("Atlas builder returns a Shiny application object", {
    app <- build_atlas_app(projects, metadata)

    expect_s3_class(app, "shiny.appobj")
  })
}
