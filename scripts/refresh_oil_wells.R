# Ejecutar desde el root:
# Rscript scripts/refresh_oil_wells.R [--wells=local.csv] [--production=local.csv] [--out=artifacts/processed/oil]
# Sin flags de origen: intenta descargar fuentes oficiales; errores detienen el pipeline.
source("R/oil_wells.R")
args <- commandArgs(trailingOnly=TRUE)
get_arg <- function(key, default) {
  found <- grep(paste0("^--", key, "="),args,value=TRUE)
  if (!length(found)) return(default)
  if (length(found)>1) stop(paste("Duplicate flag:",key),call.=FALSE)
  sub(paste0("^--",key,"="),"",found[[1]])
}
wells <- get_arg("wells",ATLAS_OIL_WELLS_URL)
production <- get_arg("production",ATLAS_OIL_PRODUCTION_2026_URL)
out <- get_arg("out",file.path("artifacts","processed","oil"))
cat("Reading Capítulo IV well inventory...\n")
raw_wells <- atlas_oil_csv(wells)
cat("Reading Capítulo IV monthly production...\n")
raw_production <- atlas_oil_csv(production)
snapshot <- atlas_oil_build_snapshot(raw_wells,raw_production,
  wells_url=if(file.exists(wells))"Fixture/local CSV" else wells,
  production_url=if(file.exists(production))"Fixture/local CSV" else production)
atlas_oil_publish_snapshot(snapshot,out)
cat("Capítulo IV snapshot created at",out,"\n")
print(snapshot$metadata)
