loader_path <- file.path("..", "..", "R", "load_sources.R")
if (file.exists(loader_path)) {
  source(loader_path)
}

fixture_path <- file.path("..", "fixtures", "provinces.geojson")

test_that("read_argentina_provinces is available", {
  expect_true(exists("read_argentina_provinces", mode = "function"))
})

if (exists("read_argentina_provinces", mode = "function")) {
  test_that("read_argentina_provinces returns an sf layer in WGS84", {
    provinces <- read_argentina_provinces(fixture_path)

    expect_s3_class(provinces, "sf")
    expect_equal(nrow(provinces), 2)
    expect_true("nombre" %in% names(provinces))
    expect_true("id" %in% names(provinces))
    expect_identical(sf::st_crs(provinces)$epsg, 4326L)
    expect_true(all(as.character(sf::st_geometry_type(provinces)) %in% c("POLYGON", "MULTIPOLYGON")))
  })

  test_that("read_argentina_provinces fails explicitly when geometry cannot be read", {
    missing_file <- file.path(tempdir(), "argentina-provinces-does-not-exist.geojson")

    expect_error(
      read_argentina_provinces(missing_file),
      regexp = "Argentina provinces GeoJSON"
    )
  })
}
