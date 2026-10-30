## Compare every data output of the 0.7.2 laptop run (results/) with the preserved 0.7.1 server run (results_071/results/).
## Writes results/compare_071_072.csv. Run from this folder: Rscript scripts/compare_071_072.R
setwd(Sys.getenv("SIMS070_ROOT", "."))
options(width = 200)
drop <- c("ballast", "commit")
csvs <- c("study1_rows.csv", "study1_summary.csv", "study2_reclass.csv", "study2_reclass_summary.csv", "study3_reclass.csv", "study3_reclass_summary.csv", "reclass_changes.csv",
          "public_trials_summary.csv", "fig02_trials_chosen.csv", "broken_trials_chosen.csv", "broken_trials_site_rows.csv", "duloxetine/duloxetine_census.csv", "aids/aids_census.csv")
out <- list()
for (f in csvs) {
  a <- read.csv(file.path("results_071/results", f), stringsAsFactors = FALSE); b <- read.csv(file.path("results", f), stringsAsFactors = FALSE)
  a <- a[, setdiff(names(a), c(drop, "elapsed_min")), drop = FALSE]; b <- b[, setdiff(names(b), c(drop, "elapsed_min")), drop = FALSE]
  same <- isTRUE(all.equal(a, b, tolerance = 1e-12, check.attributes = FALSE))
  same8 <- isTRUE(all.equal(a, b, tolerance = 1e-6, check.attributes = FALSE)); out[[f]] <- data.frame(file = f, rows = nrow(b), identical_to_071 = same, equal_within_1e6 = same8, note = if (same) "" else paste(all.equal(a, b, tolerance = 1e-12, check.attributes = FALSE), collapse = "; "))
}
rds <- c("fig02_trials_results.rds", "broken_trials_results.rds", "duloxetine/duloxetine_results.rds", "aids/aids_results.rds")
key <- function(r) { if (inherits(r, "stress_result")) r <- list(r); lapply(r, function(x) { c <- as.data.frame(x$census); c[, c("family", "label", "estimate", "stderr", "p", "lcl", "ucl")] }) }
for (f in rds) {
  a <- key(readRDS(file.path("results_071/results", f))); b <- key(readRDS(file.path("results", f)))
  same <- isTRUE(all.equal(a, b, tolerance = 1e-12, check.attributes = FALSE))
  same8 <- isTRUE(all.equal(a, b, tolerance = 1e-6, check.attributes = FALSE)); out[[f]] <- data.frame(file = f, rows = sum(sapply(b, nrow)), identical_to_071 = same, equal_within_1e6 = same8, note = if (same) "census rows identical" else if (same8) "census rows equal within 1e-6 (floating-point differences between hosts)" else "DIFFERS beyond 1e-6")
}
res <- do.call(rbind, out); rownames(res) <- NULL; print(res); write.csv(res, "results/compare_071_072.csv", row.names = FALSE)
cat("\nall identical:", all(res$identical_to_071), "\n")
