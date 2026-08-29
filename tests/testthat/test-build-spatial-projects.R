loader_path <- file.path("..", "..", "R", "load_sources.R")
source(loader_path)

spatial_path <- file.path("..", "..", "R", "build_spatial_projects.R")
if (file.exists(spatial_path)) {
  source(spatial_path)
}

provinces <- read_argentina_provinces(
  file.path("..", "fixtures", "provinces.geojson")
)

projects <- data.frame(
  project_id = c("1", "2", "3"),
  name = c("Proyecto San Juan", "Proyecto Jujuy", "Proyecto fuera"),
  latitude = c(-29.1, -23.5, -30.0),
  longitude = c(-69.1, -66.2, -60.0),
  commodity = c("Cobre", "Litio", "Oro"),
  source_province = c("San Juan", "Salta", "Córdoba"),
  stage = c("Exploración", "Producción", "Exploración"),
  stringsAsFactors = FALSE
)

test_that("build_spatial_projects is available", {
  expect_true(exists("build_spatial_projects", mode = "function"))
})

if (exists("build_spatial_projects", mode = "function")) {
  spatial_projects <- build_spatial_projects(projects, provinces)

  test_that("build_spatial_projects returns WGS84 point features without losing source coordinates", {
    expect_s3_class(spatial_projects, "sf")
    expect_identical(sf::st_crs(spatial_projects)$epsg, 4326L)
    expect_true(all(as.character(sf::st_geometry_type(spatial_projects)) == "POINT"))
    expect_equal(spatial_projects$latitude, projects$latitude)
    expect_equal(spatial_projects$longitude, projects$longitude)
  })

  test_that("spatial province and official province code are added without overwriting SIACAM province", {
    expect_identical(spatial_projects$source_province, c("San Juan", "Salta", "Córdoba"))
    expect_identical(spatial_projects$spatial_province, c("San Juan", "Jujuy", NA_character_))
    expect_identical(spatial_projects$province_code, c("70", "38", NA_character_))
  })

  test_that("province_match distinguishes agreement, disagreement, and no spatial match", {
    expect_identical(spatial_projects$province_match, c(TRUE, FALSE, NA))
  })

  test_that("province_match accepts a spatial province declared inside a multiprovince SIACAM value", {
    multiprovince_project <- data.frame(
      project_id = "4",
      name = "Proyecto interprovincial",
      latitude = -29.1,
      longitude = -69.1,
      commodity = "Cobre",
      source_province = "Mendoza - San Juan",
      stage = "Exploración",
      stringsAsFactors = FALSE
    )

    result <- build_spatial_projects(multiprovince_project, provinces)

    expect_identical(result$spatial_province, "San Juan")
    expect_identical(result$province_match, TRUE)
    expect_identical(result$source_province, "Mendoza - San Juan")
  })

  test_that("build_spatial_projects refuses unvalidated missing coordinates", {
    invalid_projects <- projects
    invalid_projects$latitude[[1]] <- NA_real_

    expect_error(
      build_spatial_projects(invalid_projects, provinces),
      regexp = "validated coordinates"
    )
  })
}
