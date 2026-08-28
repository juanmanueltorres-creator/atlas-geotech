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

  test_that("read_argentina_provinces normalizes official IGN nam/in1 properties", {
    path <- tempfile(fileext = ".geojson")
    on.exit(unlink(path), add = TRUE)

    ring <- matrix(
      c(
        -70, -30,
        -68, -30,
        -68, -28,
        -70, -28,
        -70, -30
      ),
      ncol = 2,
      byrow = TRUE
    )

    ign_province <- sf::st_sf(
      nam = "San Juan",
      in1 = "70",
      sag = "IGN",
      geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = 4326)
    )

    sf::st_write(ign_province, path, driver = "GeoJSON", quiet = TRUE)

    provinces <- read_argentina_provinces(path)

    expect_equal(provinces$nombre, "San Juan")
    expect_equal(provinces$id, "70")
    expect_equal(provinces$nam, "San Juan")
    expect_equal(provinces$in1, "70")
  })

  test_that("read_argentina_provinces prefers official IGN in1 over GeoJSON feature id", {
    path <- tempfile(fileext = ".geojson")
    on.exit(unlink(path), add = TRUE)

    geojson <- paste0(
      '{"type":"FeatureCollection","features":[',
      '{"type":"Feature","id":"provincia.56",',
      '"properties":{"nam":"Santa Fe","in1":"82","sag":"IGN"},',
      '"geometry":{"type":"Polygon","coordinates":[[[',
      '-62,-34],[-60,-34],[-60,-32],[-62,-32],[-62,-34',
      ']]]}}]}'
    )
    writeLines(geojson, path, useBytes = TRUE)

    provinces <- read_argentina_provinces(path)

    expect_equal(provinces$nombre, "Santa Fe")
    expect_equal(provinces$id, "82")
    expect_equal(provinces$in1, "82")
  })

  test_that("read_argentina_provinces repairs invalid polygon topology before spatial use", {
    path <- tempfile(fileext = ".geojson")
    on.exit(unlink(path), add = TRUE)

    invalid_geojson <- paste0(
      '{"type":"FeatureCollection","features":[',
      '{"type":"Feature","properties":{"nombre":"Provincia Test","id":"99"},',
      '"geometry":{"type":"Polygon","coordinates":[[[',
      '-70,-30],[-68,-28],[-70,-28],[-68,-30],[-70,-30',
      ']]]}}]}'
    )
    writeLines(invalid_geojson, path, useBytes = TRUE)

    provinces <- read_argentina_provinces(path)

    expect_equal(nrow(provinces), 1)
    expect_identical(sf::st_crs(provinces)$epsg, 4326L)
    expect_true(all(sf::st_is_valid(provinces)))
    expect_true(all(as.character(sf::st_geometry_type(provinces)) %in% c("POLYGON", "MULTIPOLYGON")))

    probe <- sf::st_sfc(sf::st_point(c(-69, -29)), crs = 4326)
    expect_no_error(sf::st_within(probe, provinces))
  })

  test_that("read_argentina_provinces fails explicitly when geometry cannot be read", {
    missing_file <- file.path(tempdir(), "argentina-provinces-does-not-exist.geojson")

    expect_error(
      read_argentina_provinces(missing_file),
      regexp = "Argentina provinces GeoJSON"
    )
  })
}
