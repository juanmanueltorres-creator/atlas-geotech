source(file.path("..","..","R","oil_wells.R"))
source(file.path("..","..","R","industry_catalog.R"))
source(file.path("..","..","R","build_atlas_app.R"))

test_that("oil category differentiates unavailable snapshot from real validated snapshot",{
 missing<-as.character(atlas_oil_ui())
 expect_match(missing,"No hay datos petroleros importados",fixed=TRUE)
 expect_match(missing,"No se muestran puntos de ejemplo como si fueran reales",fixed=TRUE)
 expect_false(grepl('id="oil_map"',missing,fixed=TRUE))
 oil<-list(
  records=data.frame(idpozo="A01",anio=2026L,mes=1L,
                     empresa="OPERADORA DE PRUEBA",petroleo_m3=2,
                     gas_miles_m3=1,latitude=-38.5,longitude=-68.5),
  metadata=data.frame(retrieved_at="2026-11-21T22:00:00Z")
 )
 html<-as.character(atlas_oil_ui(oil))
 expect_match(html,'id="oil_operator"',fixed=TRUE)
 expect_match(html,'id="oil_year"',fixed=TRUE)
 expect_match(html,'id="oil_month"',fixed=TRUE)
 expect_match(html,'id="oil_map"',fixed=TRUE)
 expect_match(html,"OPERADORA DE PRUEBA",fixed=TRUE)
 expect_match(html,"Producción declarada",fixed=TRUE)
})

test_that("invalid CSVs never become map markers or a declared live feed",{
 wells<-data.frame(idpozo="1",coordenadax="0",coordenaday="0")
 prod<-data.frame(idpozo="1",anio="2026",mes="1",
                  empresa="OPERADORA DE PRUEBA",prod_pet="10",prod_gas="2")
 expect_error(atlas_oil_build_snapshot(wells,prod),"No valid, geolocated")
})
