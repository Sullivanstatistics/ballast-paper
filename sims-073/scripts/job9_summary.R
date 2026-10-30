## Job 9 summary: reads every saved cell in results/defect_chunks/ and writes
##  results/defect_trials_rows.csv       one row per trial (everything Job 7 saved plus the planted-row columns)
##  results/defect_trials_census.csv.gz  every census row of every trial (family, label, kind, counted, estimate, p, crossed,
##                                       inside the filed interval, shift in filed SEs, planted or not)
##  results/defect_trials_summary.csv    one row per cell: trials, significant, observed significance rate, and among the
##                                       significant trials the shares fragile, sensitive, robust, marginal, planted row
##                                       outside the interval, planted row crossed alpha, another row outside the interval
##                                       (each with MC SE sqrt(p (1 - p) / n_sig)), the median largest shift in filed SEs,
##                                       the fragile trials split by whether a planted row is among the rows outside the
##                                       interval, and the Study 1 comparison: among Study 1 true-effect significant
##                                       trials (the 0.7.2 run's study1_rows.csv, planned power 0.5 to 0.95) with filed p
##                                       within a factor of two of the cell's median filed p (from half to twice it), the
##                                       number and the fragile share.
## Run: Rscript scripts/job9_summary.R
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
t0 <- log_header("job9_summary")
files <- list.files(file.path(RESULTS, "defect_chunks"), "\\.rds$", full.names = TRUE)
ch <- lapply(files, readRDS); names(ch) <- sub("\\.rds$", "", basename(files))
fill <- function(r) { if (!"delta" %in% names(r)) r$delta <- 0; r }   # cells saved before the B redesign have no delta column (A: the site effect is size; C, D: 0)
rows <- do.call(rbind, lapply(ch, function(x) fill(x$rows))); rownames(rows) <- NULL
rows <- rows[, c(setdiff(names(rows), c("ballast", "commit")), "ballast", "commit")]
long <- do.call(rbind, lapply(ch, `[[`, "long")); rownames(long) <- NULL
failed <- vapply(ch, function(x) length(x$failed_seeds), 0L)
cat(sprintf("%d cells, %d trials, %d failed; every planted row present and counted: %s; smallest B outlier gap ratio: %s\n", length(ch), nrow(rows), sum(failed),
            all(rows$planted_found), if (any(rows$mech == "B")) format(min(rows$planted_gap[rows$mech == "B"]), digits = 3) else "no B cells"))
for (nm in names(ch)) if (length(ch[[nm]]$failed_seeds)) cat("  failed in", nm, ":", paste(ch[[nm]]$failed_seeds, collapse = ", "), "(", paste(unique(ch[[nm]]$failed_reasons), collapse = " | "), ")\n")
write.csv(rows, file.path(RESULTS, "defect_trials_rows.csv"), row.names = FALSE)
gz <- gzfile(file.path(RESULTS, "defect_trials_census.csv.gz"), "w"); write.csv(long, gz, row.names = FALSE); close(gz)
s1 <- read.csv(file.path(PREVIOUS, "results", "study1_rows.csv"), stringsAsFactors = FALSE); s1 <- s1[s1$power > 0 & s1$significant, ]
sh <- function(x, n) { p <- if (n) sum(x) / n else NA_real_; c(p, if (n) sqrt(p * (1 - p) / n) else NA_real_) }
ord <- c("A40", "A80", "A200", "B25k5", "B25k8", "B50x2k8", "C30", "C45", "D06", "D09")
summ <- do.call(rbind, lapply(intersect(ord, unique(rows$cell)), function(cc) {
  g <- rows[rows$cell == cc, ]; s <- g[g$significant, ]; n <- nrow(s)
  out <- data.frame(cell = cc, mech = g$mech[1], size = g$size[1], n_per_arm = g$n_per_arm[1], n_outliers = g$n_outliers[1], delta = g$delta[1],
                    trials = nrow(g) + failed[[cc]], returned = nrow(g), failed = failed[[cc]], significant = n, sig_rate = n / nrow(g),
                    median_p_significant = if (n) median(s$base_p) else NA_real_)
  for (nm in c("fragile", "sensitive", "robust")) { v <- sh(s$stability == nm, n); out[[nm]] <- v[1]; out[[paste0(nm, "_mcse")]] <- v[2] }
  for (nm in c("marginal", "planted_outside", "planted_crossed", "other_outside")) { v <- sh(s[[nm]] %in% TRUE, n); out[[nm]] <- v[1]; out[[paste0(nm, "_mcse")]] <- v[2] }
  out$median_max_shift_se <- if (n) median(s$max_shift_se) else NA_real_
  out$fragile_with_planted <- sum(s$stability == "fragile" & s$planted_outside); out$fragile_without_planted <- sum(s$stability == "fragile" & !s$planted_outside)
  m <- out$median_p_significant; band <- if (is.na(m)) s1[0, ] else s1[s1$base_p >= m / 2 & s1$base_p <= 2 * m, ]
  out$study1_band_lo <- m / 2; out$study1_band_hi <- 2 * m; out$study1_n <- nrow(band)
  out$study1_fragile <- if (nrow(band)) mean(band$stability == "fragile") else NA_real_
  out }))
summ$ballast <- rows$ballast[1]; summ$commit <- rows$commit[1]
write.csv(summ, file.path(RESULTS, "defect_trials_summary.csv"), row.names = FALSE)
print(summ[, c("cell", "trials", "significant", "sig_rate", "median_p_significant", "fragile", "fragile_mcse", "sensitive", "robust", "marginal",
               "planted_outside", "planted_crossed", "other_outside", "median_max_shift_se", "fragile_with_planted", "fragile_without_planted", "study1_n", "study1_fragile")],
      digits = 3, row.names = FALSE)
log_footer("job9_summary", t0)
