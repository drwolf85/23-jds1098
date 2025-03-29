library(feather)
library(dplyr)
library(prodlim)

pred_year <- 2021
fls <- dir("../dta/double", "^all.*feather$", full.names = TRUE)

data_prep <- function(da)
  da %>% group_by_all %>% count

sink("../res/homc_accuracy.txt")
cat("County & ")
for (i in seq_len(9)) cat("$p = ", i, "$ & ", sep = "")
cat("Seconds \\\\\n")
for (fn in fls) {
  cat(gsub("(^.*_|.feather$)", "", fn))
  predtime <- system.time({
  dta <- read_feather(fn)
  dta <- lapply(dta, factor, levels = 0:255)
  dta <- as.data.frame(dta)
  names(dta)[ncol(dta) - 1] <- "yobs"
  names(dta)[ncol(dta)] <- "ytest"
  
  smr <- data_prep(dta)
  pred <- factor(rep(0, nrow(smr)), levels = 0:255)
  i <- 1
  why <- i:1
  tmp <- smr[, ncol(dta) + c(-why, 1)]
  pred[seq_along(pred)] <- tmp$yobs[which.max(tmp$n)]
  for (i in seq_len(ncol(dta) - 1)[-1L]) {
    why <- i:1
    tmp <- smr[, ncol(dta) + c(-why, 1)]
    xpr <- tmp %>% group_by_at(.vars = rev(why)) %>% summarize(n = sum(n))
    xpr <- tmp %>% group_by_at(.vars = rev(why[-1L])) %>% summarize(pred = yobs[which.max(n)])
    idp <- row.match(as.data.frame(smr[, ncol(dta) - why[-1L]]), as.data.frame(xpr[, -ncol(xpr)]))
    pred[!is.na(idp)] <- na.omit(xpr$pred[idp])
    cat(sprintf(" & %.2f", 100 * weighted.mean(pred == smr$ytest, smr$n)))
  }})
  cat(sprintf("& %.1f ", predtime[[3L]]))
  cat("\\\\\n")
}
sink()

