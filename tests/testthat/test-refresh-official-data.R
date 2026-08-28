source(file.path("..", "..", "R", "load_sources.R"))
source(file.path("..", "..", "R", "clean_projects.R"))
source(file.path("..", "..", "R", "validate_projects.R"))
source(file.path("..", "..", "R", "build_spatial_projects.R"))
source(file.path("..", "..", "scripts", "refresh_data.R"))

official_refresh_path <- file.path("..", "..", "R", "refresh_official_data.R")
if (file.exists(official_refresh_path)) {
  source(official_refresh_path)
}

write_official_refresh_fixtures <- function(directory) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)

  siacam_path <- file.path(directory, "siacam.xlsx")
  provinces_path <- file.path(directory, "provinces.geojson")

  raw_projects <- data.frame(
    `N°` = "1",
    NOMBRE = "Proyecto Oficial Fixture",
    LATITUD = -29.1,
    LONGITUD = -69.1,
    `MINERAL PRINCIPAL` = "Cobre",
    PROVINCIA = "San Juan",
    ESTADO = "Exploración",
    `CONTROLANTE (1°)` = "Controlante A",
    `PORCENTAJE (1°)` = "100%",
    `ORIGEN (1°)` = "Argentina",
    `CONTROLANTE (2°)` = NA_character_,
    `PORCENTAJE (2°)` = NA_character_,
    `ORIGEN (2°)` = NA_character_,
    `CONTROLANTE (3°)` = NA_character_,
    `PORCENTAJE (3°)` = NA_character_,
    `ORIGEN (3°)` = NA_character_,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  writexl::write_xlsx(raw_projects, siacam_path)

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

  provinces <- sf::st_sf(
    nombre = "San Juan",
    id = "70",
    geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = 4326)
  )

  sf::st_write(
    provinces,
    provinces_path,
    driver = "GeoJSON",
    quiet = TRUE
  )

  list(
    siacam = siacam_path,
    provinces = provinces_path
  )
}

test_that("official Atlas source constants are available", {
  expect_true(exists("ATLAS_SIACAM_URL"))
  expect_true(exists("ATLAS_PROVINCES_URL"))
  expect_true(exists("ATLAS_SIACAM_CATALOG_LAST_UPDATE"))
  expect_true(exists("refresh_official_atlas_data", mode = "function"))
})

if (exists("refresh_official_atlas_data", mode = "function")) {
  test_that("official refresh delegates to the fail-closed data spine", {
    fixture_dir <- tempfile("atlas-official-input-")
    output_dir <- tempfile("atlas-official-output-")
    on.exit(unlink(c(fixture_dir, output_dir), recursive = TRUE), add = TRUE)

    sources <- write_official_refresh_fixtures(fixture_dir)

    result <- refresh_official_atlas_data(
      output_dir = output_dir,
      siacam_source = sources$siacam,
      provinces_source = sources$provinces,
      retrieved_at = as.POSIXct("2026-08-28 22:00:00", tz = "UTC")
    )

    expect_true(all(file.exists(unname(result$paths))))
    expect_equal(nrow(result$metadata), 2)

    siacam_metadata <- result$metadata[result$metadata$source_name == "SIACAM mining projects", ]
    provinces_metadata <- result$metadata[result$metadata$source_name == "Argentina provincial boundaries", ]

    expect_equal(siacam_metadata$source_url, ATLAS_SIACAM_URL)
    expect_equal(
      siacam_metadata$source_last_known_update,
      ATLAS_SIACAM_CATALOG_LAST_UPDATE
    )
    expect_equal(provinces_metadata$source_url, ATLAS_PROVINCES_URL)
    expect_equal(siacam_metadata$row_count_valid, 1)
  })
}
