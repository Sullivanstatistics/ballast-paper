## Job 9 pilot for mechanism B as redesigned on 29 Oct 2026 (Adam's decision): a null trial with one or two outliers is
## almost never significant (the outlier inflates the arm's variance as fast as it shifts the mean; scripts/job9_pilot.R,
## results/defect_pilot.csv), so B plants the outlier(s) on top of a small real effect, planned power about 0.3, and the
## summary reports the share of significant trials whose significance rests on the planted patient(s). The true effect:
## delta = (qnorm(0.975) + qnorm(0.3)) x 10.3 x sqrt(2 / n_eff), n_eff = n_per_arm x 0.97^3 (residual SD about 10.3 with
## baseline in the model and the site effect; 3% dropout per visit), 4.38 at 25 per arm and 3.10 at 50 per arm. Outlier
## sizes k from 0 (no outlier) to 15 residual SDs, filed analysis only, 20 trials each, with the filed analysis also
## refitted without the planted patient(s) to show how often significance rests on them. Seeds 850000 + 1000 j + i.
## Run: Rscript scripts/job9_pilot_B.R [cores]      Output: results/defect_pilot_B.csv, logs/job9_pilot_B.log
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "job9_generators.R"))
args <- commandArgs(trailingOnly = TRUE); if (length(args) >= 1) CORES <- as.integer(args[1])
t0 <- log_header("job9_pilot_B")
delta_B <- function(n) (qnorm(0.975) + qnorm(0.3)) * 10.3 * sqrt(2 / (n * 0.97^3))
cand <- rbind(data.frame(n_per_arm = 25L, n_outliers = 1L, size = c(0, 3, 5, 8, 10, 15)),
              data.frame(n_per_arm = 50L, n_outliers = 2L, size = c(0, 3, 5, 8, 10, 15)))
cand$delta <- delta_B(cand$n_per_arm); cand$j <- seq_len(nrow(cand)); NP <- 20L
cat("true effect: 25 per arm", round(delta_B(25), 2), "; 50 per arm", round(delta_B(50), 2), "\n")
jobs <- do.call(c, lapply(cand$j, function(j) lapply(seq_len(NP), function(i) c(as.list(cand[j, ]), seed = 850000L + 1000L * j + i))))
cl <- parallel::makeCluster(CORES); invisible(parallel::clusterEvalQ(cl, { suppressPackageStartupMessages(library(ballast)); NULL }))
parallel::clusterExport(cl, c("planted_rows"))
res <- parallel::parLapplyLB(cl, jobs, function(j) tryCatch({
  d <- simulate_rare_trial(n_per_arm = j$n_per_arm, delta = j$delta, population = "homogeneous", defect = if (j$size > 0) "outlier" else "none",
                           n_outliers = j$n_outliers, outlier_size = max(j$size, 1), seed = j$seed)
  sp <- function(dd) stress_spec(dd, "y", "id", "visit", "arm", "REF", covariates = ~ base, contrast_visit = "V4", covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
  b <- stress_fit(sp(d))
  p_wo <- if (j$size > 0) { who <- planted_rows(d, "B", j$n_outliers)$rows$label; stress_fit(sp(d[!d$id %in% who, ]))$p } else NA_real_
  data.frame(j = j$j, seed = j$seed, est = b$estimate, p = b$p, p_without = p_wo, converged = b$converged)
}, error = function(e) data.frame(j = j$j, seed = j$seed, est = NA, p = NA, p_without = NA, converged = FALSE)))
parallel::stopCluster(cl); res <- do.call(rbind, res)
pil <- do.call(rbind, lapply(split(res, res$j), function(g) data.frame(j = g$j[1], trials = nrow(g), converged = sum(g$converged),
  significant = sum(g$p < 0.05, na.rm = TRUE), sig_rate = mean(g$p < 0.05, na.rm = TRUE), median_p = median(g$p, na.rm = TRUE),
  rests_on_outlier = sum(g$p < 0.05 & g$p_without >= 0.05, na.rm = TRUE))))
pil <- merge(cand, pil, by = "j"); pil <- pil[order(pil$j), ]
write.csv(pil, file.path(RESULTS, "defect_pilot_B.csv"), row.names = FALSE); print(pil, digits = 3, row.names = FALSE)
log_footer("job9_pilot_B", t0)
