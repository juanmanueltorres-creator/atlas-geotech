canonicalize_capital_origin <- function(values) {
  values <- as.character(values)

  aliases <- c(
    "Paises Bajos" = "Países Bajos"
  )

  matched <- !is.na(values) & values %in% names(aliases)
  values[matched] <- unname(aliases[values[matched]])
  values
}
