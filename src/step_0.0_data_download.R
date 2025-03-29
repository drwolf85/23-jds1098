library(terra)
library(curl)

years <- 2011:2021
  
tmpl_url <- "https://www.nass.usda.gov/Research_and_Science/Cropland/Release/datasets/%d_30m_cdls.zip"
files <- sapply(years, function(y) sprintf(tmpl_url, y))

# Download and unzip the CDL files
for (fn in files) {
  dstf <- substr(fn, 74, 93)
  curl_download(url = fn, destfile = dstf, quiet = FALSE)
  tfn <- grep(".t(i|)f(w|)$", unzip(zipfile = dstf, list = TRUE)$Name, value = TRUE)
  unzip(zipfile = dstf,  files = tfn, exdir = "../dta/cdls/")
  unlink(dstf)
}

# Crop/clip and mask the CDL at the county level
cnt <- dir("../dta/rasters", "_mask.tif$", full.names = TRUE)
for (cc in cnt) {
  fip <- substr(cc, 16, 20)
  msk <- rast(cc)
  for (year in years) {
    cdl <- rast(paste0("../dta/cdls/", year, "_30m_cdls.tif"))
    cdlcol <- coltab(cdl) # Get color table
    lev <- levels(cdl) # Get attribute table
    ccdl <- crop(cdl, msk) * msk
    coltab(ccdl) <- cdlcol # Restore the colors
    levels(ccdl) <- lev # Restore attribute table
    dir.create(sprintf("../dta/rasters/%s", fip), showWarnings = FALSE, recursive = TRUE)
    writeRaster(ccdl, filename = sprintf("../dta/rasters/%s/_%d_30m_cdls_img_%s.tif", 
                                         fip, year, fip), 
                overwrite = TRUE, datatype = "INT1U", 
                gdal=c("COMPRESS=DEFLATE", "TFW=YES"))
  }
}

# Compiling library to use in python or other R scrtips
system("make")
