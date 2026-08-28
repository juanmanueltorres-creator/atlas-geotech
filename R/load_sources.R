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

repair_argentina_province_topology <- function(provinces) {
  validity <- sf::st_is_valid(provinces)
  invalid <- is.na(validity) | !validity

  if (!any(invalid)) {
    return(provinces)
  }

  original_crs <- sf::st_crs(provinces)

  repaired <- tryCatch(
    {
      planar <- sf::st_set_crs(provinces, NA)
      planar <- sf::st_make_valid(planar)
      sf::st_set_crs(planar, original_crs)
    },
    error = function(error) {
      stop(
        sprintf(
          "Unable to repair Argentina provinces GeoJSON topology: %s",
          conditionMessage(error)
        ),
        call. = FALSE
      )
    }
  )

  repaired_validity <- sf::st_is_valid(repaired)
  repaired_invalid <- is.na(repaired_validity) | !repaired_validity

  if (any(repaired_invalid)) {
    stop(
      sprintf(
        "Argentina provinces GeoJSON still contains %d invalid geometries after repair",
        sum(repaired_invalid)
      ),
      call. = FALSE
    )
  }

  repaired
}

read_argentina_provinces <- function(path_or_url) {
  if (!is.character(path_or_url) || length(path_or_url) != 1 || is.na(path_or_url) || path_or_url == "") {
    stop(
      "Argentina provinces GeoJSON source must be a non-empty path or URL",
      call. = FALSE
    )
  }

  source_path <- path_or_url

  if (is_http_source(path_or_url)) {
    source_path <- tempfile(fileext = ".geojson")
    on.exit(unlink(source_path), add = TRUE)

    tryCatch(
      {
        status <- utils::download.file(
          url = path_or_url,
          destfile = source_path,
          mode = "wb",
          quiet = TRUE
        )

        if (!identical(status, 0L) || !file.exists(source_path) || file.size(source_path) == 0) {
          stop("download did not produce a usable file")
        }
      },
      error = function(error) {
        stop(
          sprintf(
            "Unable to download Argentina provinces GeoJSON: %s",
            conditionMessage(error)
          ),
          call. = FALSE
        )
      }
    )
  }

  provinces <- tryCatch(
    sf::st_read(source_path, quiet = TRUE),
    error = function(error) {
      stop(
        sprintf(
          "Unable to read Argentina provinces GeoJSON: %s",
          conditionMessage(error)
        ),
        call. = FALSE
      )
    }
  )

  if (!inherits(provinces, "sf")) {
    stop("Argentina provinces GeoJSON did not produce an sf layer", call. = FALSE)
  }

  if (!("nombre" %in% names(provinces)) && "nam" %in% names(provinces)) {
    provinces$nombre <- as.character(provinces$nam)
  }

  if ("in1" %in% names(provinces)) {
    provinces$id <- as.character(provinces$in1)
  }

  if (!("nombre" %in% names(provinces))) {
    stop("Argentina provinces GeoJSON is missing the 'nombre' field", call. = FALSE)
  }

  source_crs <- sf::st_crs(provinces)
  if (is.na(source_crs)) {
    stop("Argentina provinces GeoJSON has no declared CRS", call. = FALSE)
  }

  if (!identical(source_crs$epsg, 4326L)) {
    provinces <- sf::st_transform(provinces, 4326)
  }

  provinces <- repair_argentina_province_topology(provinces)

  geometry_types <- unique(as.character(sf::st_geometry_type(provinces)))
  invalid_geometry_types <- setdiff(geometry_types, c("POLYGON", "MULTIPOLYGON"))

  if (length(invalid_geometry_types) > 0) {
    stop(
      sprintf(
        "Argentina provinces GeoJSON contains unsupported geometry types: %s",
        paste(invalid_geometry_types, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  provinces
}
