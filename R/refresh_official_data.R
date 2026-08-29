ATLAS_SIACAM_URL <- paste0(
  "https://www.mecon.gob.ar/dataset/",
  "Cartera-de-Proyectos-Mineros-Metaliferos-y-Litio-del-SIACAM.xlsx"
)

ATLAS_PROVINCES_URL <- paste0(
  "https://raw.githubusercontent.com/",
  "juanmanueltorres-creator/pulso-publico-argentina/main/",
  "public/data/argentina-provinces.geojson"
)

# This is the open-data catalog metadata date, not a guarantee that the
# downloadable workbook itself has no newer observations.
ATLAS_SIACAM_CATALOG_LAST_UPDATE <- "2025-02-19"

refresh_official_atlas_data <- function(
  output_dir,
  siacam_source = ATLAS_SIACAM_URL,
  provinces_source = ATLAS_PROVINCES_URL,
  retrieved_at = Sys.time()
) {
  refresh_atlas_data(
    siacam_source = siacam_source,
    provinces_source = provinces_source,
    output_dir = output_dir,
    retrieved_at = retrieved_at,
    siacam_source_url = ATLAS_SIACAM_URL,
    provinces_source_url = ATLAS_PROVINCES_URL,
    source_last_known_update = ATLAS_SIACAM_CATALOG_LAST_UPDATE
  )
}
