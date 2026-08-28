is_http_source <- function(value) {
  is.character(value) &&
    length(value) == 1 &&
    !is.na(value) &&
    grepl("^https?://", value, ignore.case = TRUE)
}

read_siacam_xlsx <- function(path_or_url, sheet = 1) {
  if (!is.character(path_or_url) || length(path_or_url) != 1 || is.na(path_or_url) || path_or_url == "") {
    stop("SIACAM XLSX source must be a non-empty path or URL", call. = FALSE)
  }

  source_path <- path_or_url

  if (is_http_source(path_or_url)) {
    source_path <- tempfile(fileext = ".xlsx")
    on.exit(unlink(source_path), add = TRUE)

    tryCatch(
      utils::download.file(
        url = path_or_url,
        destfile = source_path,
        mode = "wb",
        quiet = TRUE
      ),
      error = function(error) {
        stop(
          sprintf("Unable to download SIACAM XLSX: %s", conditionMessage(error)),
          call. = FALSE
        )
      }
    )
  }

  tryCatch(
    as.data.frame(
      readxl::read_excel(
        source_path,
        sheet = sheet,
        .name_repair = "minimal"
      ),
      stringsAsFactors = FALSE
    ),
    error = function(error) {
      stop(
        sprintf("Unable to read SIACAM XLSX: %s", conditionMessage(error)),
        call. = FALSE
      )
    }
  )
}
