source(file.path("..", "..", "R", "industry_catalog.R"))
source(file.path("..", "..", "R", "build_atlas_app.R"))

test_that("industry reference tables are traceable and separated", {
  companies <- atlas_reference_companies()
  sources <- atlas_reference_sources()
  expect_gte(nrow(companies), 7L)
  expect_gte(nrow(sources), 6L)
  expect_true(all(grepl("^https://", companies$source_url)))
  expect_true(all(grepl("^https://", sources$source_url)))
  expect_true(all(companies$sector == "Petróleo y gas"))
  expect_setequal(unique(companies$subcategory), c("Operadoras", "Proveedores B2B"))
  expect_equal(nrow(atlas_catalog_filter(companies, "Petróleo y gas", "Operadoras")), 3L)
  expect_equal(nrow(atlas_catalog_filter(companies, "Petróleo y gas", "Proveedores B2B")), 4L)
  expect_equal(nrow(atlas_catalog_filter(companies, "Minería")), 0L)
  expect_gt(nrow(atlas_catalog_filter(sources, "Minería", "Proveedores B2B")), 0L)
})

test_that("oil industry category has separate navigation and provenance links", {
  html <- as.character(atlas_oil_ui())
  expect_match(html, "Petróleo y gas", fixed = TRUE)
  expect_match(html, "Operadoras", fixed = TRUE)
  expect_match(html, "Proveedores B2B", fixed = TRUE)
  expect_match(html, "Datos y fuentes", fixed = TRUE)
  expect_match(html, "San Antonio Internacional", fixed = TRUE)
  expect_match(html, "YPF", fixed = TRUE)
  expect_match(html, "No se han importado mediciones por pozo", fixed = TRUE)
  expect_match(html, 'rel="noopener noreferrer"', fixed = TRUE)
})

test_that("mining supplier subcategory does not invent validated vendors", {
  html <- as.character(atlas_mining_providers_ui())
  expect_match(html, "Registro Federal de Proveedores Mineros", fixed = TRUE)
  expect_match(html, "autodeclarada", fixed = TRUE)
  expect_match(html, "No se han importado", fixed = TRUE)
})

test_that("reference files fail with explicit invalid or missing provenance", {
  temp <- tempfile("atlas-ref-")
  dir.create(temp)
  on.exit(unlink(temp, recursive = TRUE), add = TRUE)
  readr::write_csv(
    data.frame(sector = "Petróleo y gas", source_url = "http://insecure.test"),
    file.path(temp, "industry_companies.csv")
  )
  expect_error(atlas_reference_companies(temp), "Missing reference fields")
  expect_error(atlas_reference_csv("not-found.csv", c("source_url"), temp), "Missing reference")
  expect_error(atlas_reference_csv("industry_companies.csv", c("sector", "source_url"), temp), "HTTPS")
})

test_that("Atlas retains mining map and capital while adding oil navigation", {
  input <- data.frame(
    project_id = "sample-1", name = "Proyecto de prueba", commodity = "Cobre",
    stage = "Exploración", source_province = "San Juan", spatial_province = "San Juan",
    province_match = TRUE, longitude = -69.1, latitude = -29.1
  )
  projects <- sf::st_as_sf(input, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)
  metadata <- data.frame(source_name = "SIACAM mining projects", retrieved_at = "2026-08-28T23:00:00Z")
  html <- as.character(build_atlas_ui(projects, metadata))
  expect_match(html, 'id="sector_view"', fixed = TRUE)
  expect_match(html, 'id="atlas_view"', fixed = TRUE)
  expect_match(html, 'id="oil_subview"', fixed = TRUE)
  expect_match(html, 'id="map"', fixed = TRUE)
  expect_match(html, 'id="capital_table"', fixed = TRUE)
  expect_false(grepl("331 proyectos", html, fixed = TRUE)) # no static count invented
})
