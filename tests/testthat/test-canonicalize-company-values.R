source_path <- file.path("..", "..", "R", "canonicalize_company_values.R")
if (file.exists(source_path)) {
  source(source_path)
}

test_that("canonicalize_capital_origin is available", {
  expect_true(exists("canonicalize_capital_origin", mode = "function"))
})

if (exists("canonicalize_capital_origin", mode = "function")) {
  test_that("capital origin aliases converge on the canonical SIACAM display value", {
    values <- c("Paises Bajos", "Países Bajos")

    expect_identical(
      canonicalize_capital_origin(values),
      c("Países Bajos", "Países Bajos")
    )
  })

  test_that("unknown capital origins pass through unchanged", {
    values <- c("Argentina", "Canadá", "Reino Unido")

    expect_identical(canonicalize_capital_origin(values), values)
  })

  test_that("missing values remain missing", {
    values <- c(NA_character_, "", "-")

    result <- canonicalize_capital_origin(values)

    expect_true(is.na(result[[1]]))
    expect_identical(result[[2]], "")
    expect_identical(result[[3]], "-")
  })
}
