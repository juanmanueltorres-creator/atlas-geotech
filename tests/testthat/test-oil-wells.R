source(file.path("..","..","R","oil_wells.R"))

wells_fixture <- function(){
 data.frame(
  idpozo=c("101","101","102","103","104","105","105"),
  sigla=c("SJ-1","SJ-1","NQ-2","BAD","BAD","DUP","DUP"),
  coordenadax=c("-31.5","-31.5","-38.9","-80",NA,"-39","-40"),
  coordenaday=c("-68.4","-68.4","-69.5","-70","-69","-70","-70"),
  stringsAsFactors=FALSE
 )
}
production_fixture <- function(){
 data.frame(
  idpozo=c("101","102","103","105","101","101"),
  anio=rep("2026",6),
  mes=c("1","1","1","1","2","2"),
  empresa=c("OPERADORA A","OPERADORA B","OPERADORA C","OPERADORA C",
            "OPERADORA A","OPERADORA A"),
  prod_pet=c("12.5","0","15","3","12","99"),
  prod_gas=c("0","21.5","0","3","0","0"),
  stringsAsFactors=FALSE
 )
}

test_that("catalog coordinates map x as latitude and y as longitude",{
 wells <- atlas_oil_wells(wells_fixture())
 expect_equal(nrow(wells),2L)
 expect_equal(wells$latitude,c(-31.5,-38.9))
 expect_equal(wells$longitude,c(-68.4,-69.5))
 expect_equal(attr(wells,"ambiguous_ids"),1L)
 expect_equal(attr(wells,"invalid_geometry"),2L)
})

test_that("invalid and duplicated production do not inflate totals",{
 p <- atlas_oil_production(production_fixture())
 expect_equal(nrow(p),4L)
 expect_equal(attr(p,"excluded_duplicated_records"),2L)
 expect_equal(p$petroleo_m3[1],12.5)
 expect_equal(p$gas_miles_m3[2],21.5)
 expect_equal(p$empresa[2],"OPERADORA B")
})

test_that("snapshot joins by stable well ID, not location or approximate text",{
 snap <- atlas_oil_build_snapshot(wells_fixture(),production_fixture(),
         retrieved_at=as.POSIXct("2026-11-21 22:00:00",tz="UTC"),
         wells_url="https://example.test/wells.csv",
         production_url="https://example.test/production.csv")
 expect_equal(nrow(snap$records),2L)
 expect_equal(sort(unique(snap$records$idpozo)),c("101","102"))
 expect_equal(snap$metadata$unique_wells,2L)
 expect_equal(snap$metadata$excluded_no_geometry,2L)
 expect_equal(snap$metadata$excluded_duplicate_production,2L)
 expect_match(snap$metadata$retrieved_at,"2026-11-21")
})

test_that("snapshot can be published and read with its provenance",{
 root<-tempfile("atlas-test-snapshot-")
 on.exit(unlink(root,recursive=TRUE),add=TRUE)
 snap<-atlas_oil_build_snapshot(wells_fixture(),production_fixture())
 atlas_oil_publish_snapshot(snap,file.path(root,"oil"))
 loaded<-atlas_oil_read_snapshot(root)
 expect_equal(nrow(loaded$records),2L)
 expect_equal(nrow(loaded$metadata),1L)
 expect_equal(loaded$metadata$record_count,2L)
})

test_that("missing, invalid, and ambiguous sources fail closed",{
 expect_null(atlas_oil_read_snapshot(tempdir()))
 expect_error(atlas_oil_wells(data.frame(idpozo="1")),"missing required")
 w<-data.frame(idpozo="1",coordenadax="foo",coordenaday="-65")
 expect_error(atlas_oil_wells(w),"malformed numeric")
 expect_error(atlas_oil_production(data.frame(idpozo="1")),"missing required")
 expect_error(atlas_oil_csv("https://malicious.test/data.csv"),"official HTTPS")
})

test_that("unknown or absent data is not silently counted as zero",{
 fixture<-production_fixture()
 fixture$prod_gas[1] <- ""
 p<-atlas_oil_production(fixture)
 expect_true(is.na(p$gas_miles_m3[1]))
 fixture$prod_pet[1]<-"not_a_number"
 expect_error(atlas_oil_production(fixture),"malformed numeric")
})

test_that("a dataset with unresolved IDs cannot pretend to have a mapped snapshot",{
 w<-wells_fixture()
 p<-production_fixture()
 p$idpozo<-paste0("X",p$idpozo)
 expect_error(atlas_oil_build_snapshot(w,p),"No production rows have validated")
})
