spatial_path <- file.path("..", "..", "R", "build_spatial_projects.R")
filter_path <- file.path("..", "..", "R", "filter_projects.R")
loader_path <- file.path("..", "..", "R", "load_sources.R")

source(loader_path)
source(spatial_path)

if (file.exists(filter_path)) {
  source(filter_path)
}

provinces <- read_argentina_provinces(
  file.path("..", "fixtures", "provinces.geojson")
)

projects <- data.frame(
  project_id = c("1", "2", "3", "4"),
  name = c("SJ Cobre", "SJ Oro", "Jujuy Litio", "Fuera"),
  latitude = c(-29.1, -30.1, -23.5, -30.0),
  longitude = c(-69.1, -68.8, -66.2, -60.0),
  commodity = c("Cobre", "Oro", "Litio", "Oro"),
  source_province = c("San Juan", "San Juan", "Jujuy", "Córdoba"),
  stage = c("Exploración", "Producción", "Exploración", "Exploración"),
  stringsAsFactors = FALSE
)

spatial_projects <- build_spatial_projects(projects, provinces)

test_that("filter_projects is available", {
  expect_true(exists("filter_projects", mode = "function"))
})

if (exists("filter_projects", mode = "function")) {
  test_that("empty filters preserve all projects and sf geometry", {
    result <- filter_projects(spatial_projects)

    expect_s3_class(result, "sf")
    expect_equal(nrow(result), nrow(spatial_projects))
    expect_identical(result$project_id, spatial_projects$project_id)
    expect_identical(sf::st_geometry(result), sf::st_geometry(spatial_projects))
  })

  test_that("province filter uses spatial province rather than overwriting source truth", {
    result <- filter_projects(spatial_projects, province = "San Juan")

    expect_identical(result$project_id, c("1", "2"))
    expect_true(all(result$spatial_province == "San Juan"))
    expect_identical(result$source_province, c("San Juan", "San Juan"))
  })

  test_that("mineral and stage filters combine with province", {
    result <- filter_projects(
      spatial_projects,
      province = "San Juan",
      mineral = "Cobre",
      stage = "Exploración"
    )

    expect_identical(result$project_id, "1")
    expect_identical(result$commodity, "Cobre")
    expect_identical(result$stage, "Exploración")
  })

  test_that("filters are case-insensitive and ignore surrounding whitespace", {
    result <- filter_projects(
      spatial_projects,
      province = "  san juan ",
      mineral = "oro",
      stage = " producción "
    )

    expect_identical(result$project_id, "2")
  })

  test_that("blank filters behave like no filter", {
    result <- filter_projects(
      spatial_projects,
      province = "",
      mineral = "   ",
      stage = NULL
    )

    expect_equal(nrow(result), nrow(spatial_projects))
  })
}
