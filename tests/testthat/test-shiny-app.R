app_path <- file.path("..", "..", "R", "build_atlas_app.R")

if (file.exists(app_path)) {
  source(app_path)
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
    "2026-08-28T21:00:00Z",
    "2026-08-28T21:00:00Z"
  ),
  stringsAsFactors = FALSE
)

test_that("minimal Atlas Shiny builders are available", {
  expect_true(exists("build_atlas_ui", mode = "function"))
  expect_true(exists("build_atlas_app", mode = "function"))
})

if (
  exists("build_atlas_ui", mode = "function") &&
  exists("build_atlas_app", mode = "function")
) {
  test_that("Atlas UI exposes the V0 filters, map, and provenance", {
    ui <- build_atlas_ui(projects, metadata)
    html <- as.character(ui)

    expect_match(html, "Atlas Geotech", fixed = TRUE)
    expect_match(html, 'id="province"', fixed = TRUE)
    expect_match(html, 'id="mineral"', fixed = TRUE)
    expect_match(html, 'id="stage"', fixed = TRUE)
    expect_match(html, 'id="map"', fixed = TRUE)
    expect_match(html, 'id="provenance"', fixed = TRUE)
    expect_match(html, "SIACAM mining projects", fixed = TRUE)
    expect_match(html, "2026-08-28T21:00:00Z", fixed = TRUE)
  })

  test_that("Atlas builder returns a Shiny application object", {
    app <- build_atlas_app(projects, metadata)

    expect_s3_class(app, "shiny.appobj")
  })
}
