library(terra)
library(dplyr)
library(feather)

# Function to prepare data for modeling
data_prep <- function(dta) {
  return(dta %>% group_by_all %>% count)
}

fns <- dir("../dta/rasters/", ".tif$", recursive = TRUE, full.names = TRUE)
fns <- grep("mask", fns, invert = TRUE, value = TRUE)
counties <- unique(substr(fns, 3, 7))
dir.create("../dta/double", showWarnings = FALSE, recursive = TRUE)
for (cnt in counties) {
  # Reading the data
  files <- grep(cnt, fns, value = TRUE)
  dar <- lapply(files, rast)
  dar <- sapply(dar, function (fl) as.integer(values(fl)))
  dar <- as.data.frame(dar)
  dar[is.na(dar)] <- 0L
  names(dar) <- paste0("Y", gsub("(^.*/_|_30m.*$)", "", files))
  # Save the data into a feather dataset (for processing in python)
  write_feather(dar, paste0("../dta/double/alldata_", cnt, ".feather"))
}
