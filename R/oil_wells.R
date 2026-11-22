# Capítulo IV — ingestión reproducible, sin llamadas externas al iniciar Shiny.
# La documentación del catálogo describe coordenadax=latitud, coordenaday=longitud.
# No inferir contratos ni puntos sin coordenadas confiables.
ATLAS_OIL_WELLS_URL <- paste0(
  "https://datos.energia.gob.ar/dataset/c846e79c-026c-4040-897f-1ad3543b407c/",
  "resource/cb5c0f04-7835-45cd-b982-3e25ca7d7751/download/capitulo-iv-pozos.csv"
)
ATLAS_OIL_PRODUCTION_2026_URL <- paste0(
  "https://datos.energia.gob.ar/dataset/c846e79c-026c-4040-897f-1ad3543b407c/",
  "resource/fb7a47a0-cba9-4667-a004-6f6c1c346c23/download/",
  "produccin-de-pozos-de-gas-y-petrleo-2026.csv"
)

atlas_oil_fetch <- function(source) {
  if (file.exists(source)) return(source)
  if (!grepl("^https://datos\\.energia\\.gob\\.ar/", source)) {
    stop("Oil source must be a local file or official HTTPS resource", call. = FALSE)
  }
  dest <- tempfile(fileext = ".csv")
  tryCatch({
    code <- utils::download.file(source, dest, mode = "wb", quiet = TRUE,
                                 method = "libcurl")
    if (!identical(as.integer(code), 0L) || !file.exists(dest) ||
        file.info(dest)$size <= 0L) stop("empty or failed download")
    dest
  }, error = function(e) {
    unlink(dest)
    stop(paste("Official Capítulo IV download failed:", conditionMessage(e)), call. = FALSE)
  })
}

atlas_oil_csv <- function(source) {
  downloaded <- !file.exists(source)
  path <- atlas_oil_fetch(source)
  if (downloaded) on.exit(unlink(path), add = TRUE)
  as.data.frame(readr::read_csv(path, show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8")), stringsAsFactors = FALSE)
}

atlas_oil_require <- function(rows, keys, label) {
  missing <- setdiff(keys, names(rows))
  if (length(missing)) stop(
    sprintf("%s: missing required columns: %s", label, paste(missing, collapse=", ")),
    call. = FALSE)
  if (!nrow(rows)) stop(paste(label, "has no rows"), call. = FALSE)
}

atlas_oil_number <- function(value) {
  x <- trimws(as.character(value))
  x[is.na(x) | !nzchar(x)] <- NA_character_
  out <- suppressWarnings(as.numeric(x))
  invalid <- !is.na(x) & !is.finite(out)
  if (any(invalid)) stop("Oil source has malformed numeric values", call. = FALSE)
  out
}

atlas_oil_wells <- function(raw) {
  atlas_oil_require(raw, c("idpozo", "coordenadax", "coordenaday"), "Wells")
  # El catálogo oficial especifica X=latitud e Y=longitud para este recurso.
  latitude <- atlas_oil_number(raw$coordenadax)
  longitude <- atlas_oil_number(raw$coordenaday)
  id <- trimws(as.character(raw$idpozo))
  usable <- !is.na(id) & nzchar(id) & is.finite(latitude) & is.finite(longitude) &
    latitude >= -60 & latitude <= -20 & longitude >= -80 & longitude <= -40
  wells <- data.frame(idpozo=id[usable], latitude=latitude[usable],
                      longitude=longitude[usable], stringsAsFactors=FALSE)
  if (!nrow(wells)) stop("No valid, geolocated Argentine wells", call. = FALSE)
  # Una clave con coordenadas inconsistentes es ambigua: NO mapearla.
  key <- paste(wells$idpozo, wells$latitude, wells$longitude, sep="|")
  coordinates_per_id <- tapply(key, wells$idpozo, function(v) length(unique(v)))
  ambiguous <- names(coordinates_per_id)[coordinates_per_id > 1L]
  wells <- wells[!wells$idpozo %in% ambiguous, , drop=FALSE]
  wells <- wells[!duplicated(wells$idpozo), , drop=FALSE]
  rownames(wells) <- NULL
  if (!nrow(wells)) stop("All well coordinates are ambiguous", call. = FALSE)
  attr(wells, "ambiguous_ids") <- length(ambiguous)
  attr(wells, "invalid_geometry") <- sum(!usable)
  wells
}

atlas_oil_production <- function(raw) {
  atlas_oil_require(raw, c("idpozo","anio","mes","prod_pet","prod_gas"), "Production")
  id <- trimws(as.character(raw$idpozo))
  year <- atlas_oil_number(raw$anio)
  month <- atlas_oil_number(raw$mes)
  petroleum <- atlas_oil_number(raw$prod_pet)
  gas <- atlas_oil_number(raw$prod_gas)
  if ("empresa" %in% names(raw)) operator <- raw$empresa
  else if ("idempresa" %in% names(raw)) operator <- raw$idempresa
  else stop("Production: missing operator field empresa/idempresa", call. = FALSE)
  operator <- trimws(as.character(operator))
  valid <- !is.na(id) & nzchar(id) & is.finite(year) & year == floor(year) &
    year >= 2006 & year <= 2026 & is.finite(month) & month %in% 1:12 &
    !is.na(operator) & nzchar(operator) &
    (!is.na(petroleum) | !is.na(gas)) &
    (is.na(petroleum) | petroleum >= 0) & (is.na(gas) | gas >= 0)
  data <- data.frame(idpozo=id[valid], anio=as.integer(year[valid]),
    mes=as.integer(month[valid]), empresa=operator[valid],
    petroleo_m3=petroleum[valid], gas_miles_m3=gas[valid],
    stringsAsFactors=FALSE)
  if (!nrow(data)) stop("Production: no valid production records", call. = FALSE)
  # Distintas DDJJ de un mismo mes pueden duplicar la producción.
  # Conservador: omitir TODAS las claves repetidas hasta revisar rectificaciones.
  key <- paste(data$idpozo, data$anio, data$mes, sep="|")
  repeated <- duplicated(key) | duplicated(key, fromLast=TRUE)
  n_repeated <- sum(repeated)
  data <- data[!repeated, , drop=FALSE]
  if (!nrow(data)) stop("Production: all monthly records are duplicated", call. = FALSE)
  attr(data,"excluded_duplicated_records") <- n_repeated
  attr(data,"excluded_invalid_records") <- sum(!valid)
  data
}

atlas_oil_build_snapshot <- function(raw_wells, raw_production, retrieved_at=Sys.time(),
                                     wells_url=ATLAS_OIL_WELLS_URL,
                                     production_url=ATLAS_OIL_PRODUCTION_2026_URL) {
  wells <- atlas_oil_wells(raw_wells)
  production <- atlas_oil_production(raw_production)
  matching <- match(production$idpozo, wells$idpozo)
  with_geometry <- !is.na(matching)
  records <- production[with_geometry, , drop=FALSE]
  if (!nrow(records)) stop("No production rows have validated well geometry", call.=FALSE)
  records$latitude <- wells$latitude[matching[with_geometry]]
  records$longitude <- wells$longitude[matching[with_geometry]]
  stopifnot(!anyDuplicated(paste(records$idpozo,records$anio,records$mes,sep="|")))
  meta <- data.frame(
    dataset="Argentina Capítulo IV - wells and production 2026",
    wells_source=wells_url, production_source=production_url,
    retrieved_at=format(as.POSIXct(retrieved_at), "%Y-%m-%dT%H:%M:%SZ",tz="UTC"),
    record_count=nrow(records), unique_wells=length(unique(records$idpozo)),
    excluded_no_geometry=sum(!with_geometry),
    excluded_duplicate_production=attr(production,"excluded_duplicated_records"),
    excluded_invalid_production=attr(production,"excluded_invalid_records"),
    excluded_invalid_well_geometry=attr(wells,"invalid_geometry"),
    excluded_ambiguous_well_ids=attr(wells,"ambiguous_ids"),
    note="Only validated coordinate matches; reporting does not imply live telemetry",
    stringsAsFactors=FALSE
  )
  list(records=records, metadata=meta)
}

atlas_oil_publish_snapshot <- function(snapshot, directory) {
  if (!dir.exists(directory)) dir.create(directory,recursive=TRUE)
  stage <- tempfile("oil-staged-")
  dir.create(stage)
  on.exit(unlink(stage,recursive=TRUE),add=TRUE)
  paths <- c(file.path(stage,"oil_production.csv"),file.path(stage,"oil_metadata.csv"))
  readr::write_csv(snapshot$records,paths[[1]],na="")
  readr::write_csv(snapshot$metadata,paths[[2]],na="")
  if (any(file.info(paths)$size<=0)) stop("Empty staging artifact",call.=FALSE)
  dest <- file.path(directory,basename(paths))
  staged <- paste0(dest,".next")
  on.exit(unlink(staged[file.exists(staged)]),add=TRUE)
  if(!all(file.copy(paths,staged,overwrite=TRUE)))stop("Unable to stage oil data",call.=FALSE)
  for(i in seq_along(dest)){
    if(file.exists(dest[[i]]) && !file.remove(dest[[i]]))stop("Cannot replace oil artifact",call.=FALSE)
    if(!file.rename(staged[[i]],dest[[i]]))stop("Cannot publish oil artifact",call.=FALSE)
  }
  invisible(dest)
}

atlas_oil_read_snapshot <- function(directory) {
  dir <- file.path(directory,"oil")
  paths <- file.path(dir,c("oil_production.csv","oil_metadata.csv"))
  if (!any(file.exists(paths))) return(NULL)
  if (!all(file.exists(paths)))stop("Incomplete oil snapshot",call.=FALSE)
  rows <- as.data.frame(readr::read_csv(paths[[1]],show_col_types=FALSE))
  metadata <- as.data.frame(readr::read_csv(paths[[2]],show_col_types=FALSE))
  atlas_oil_require(rows,c("idpozo","anio","mes","empresa","petroleo_m3",
                           "gas_miles_m3","latitude","longitude"),"Oil snapshot")
  atlas_oil_require(metadata,c("dataset","wells_source","production_source",
    "retrieved_at","record_count"),"Oil provenance")
  if(any(!is.finite(rows$latitude)|!is.finite(rows$longitude)))stop("Invalid mapped coordinates",call.=FALSE)
  if(anyDuplicated(paste(rows$idpozo,rows$anio,rows$mes,sep="|")))stop("Duplicate snapshot grain",call.=FALSE)
  list(records=rows,metadata=metadata)
}
