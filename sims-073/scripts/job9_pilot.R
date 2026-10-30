## Job 9 pilot: the filed analysis only, 20 trials per candidate defect size, to choose the two sizes per mechanism
## (HANDOFF_defect_trials.md: significant in at least half the trials at the larger size). The sizes are chosen on the
## filed analysis alone, before any stress test is run, so the choice cannot follow the labels. Pilot seeds are
## 800000 + 1000 j + i for candidate j and trial i, disjoint from the run's seeds.
## Run: Rscript scripts/job9_pilot.R [cores]      Output: results/defect_pilot.csv, logs/job9_pilot.log
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "job9_generators.R"))
args <- commandArgs(trailingOnly = TRUE); if (length(args) >= 1) CORES <- as.integer(args[1])
t0 <- log_header("job9_pilot")
cand <- rbind(
  data.frame(mech = "A", size = c(20, 30, 40, 60, 80, 120, 200), n_per_arm = 50L, n_outliers = 1L),
  data.frame(mech = "B", size = c(5, 10, 15, 25, 40), n_per_arm = 25L, n_outliers = 1L),
  data.frame(mech = "B", size = c(5, 10, 15, 25), n_per_arm = 50L, n_outliers = 2L),
  data.frame(mech = "C", size = c(0.30, 0.45, 0.60), n_per_arm = 50L, n_outliers = 1L),
  data.frame(mech = "D", size = c(0.3, 0.6, 0.9, 1.2), n_per_arm = 50L, n_outliers = 1L))
cand$j <- seq_len(nrow(cand)); NP <- 20L
jobs <- do.call(c, lapply(cand$j, function(j) lapply(seq_len(NP), function(i) c(as.list(cand[j, ]), seed = 800000L + 1000L * j + i))))
cl <- parallel::makeCluster(CORES); parallel::clusterEvalQ(cl, { suppressPackageStartupMessages(library(ballast)); NULL })
parallel::clusterExport(cl, c("make_trial", "make_spec", "plant_mnar", "BETA_D"))
res <- parallel::parLapplyLB(cl, jobs, function(j) tryCatch({
  d <- make_trial(j$mech, j$size, j$seed, j$n_per_arm, j$n_outliers); b <- stress_fit(make_spec(d, j$mech))
  data.frame(j = j$j, seed = j$seed, est = b$estimate, se = b$stderr, p = b$p, converged = b$converged)
}, error = function(e) data.frame(j = j$j, seed = j$seed, est = NA, se = NA, p = NA, converged = FALSE)))
parallel::stopCluster(cl); res <- do.call(rbind, res)
pil <- do.call(rbind, lapply(split(res, res$j), function(g) data.frame(j = g$j[1], trials = nrow(g), converged = sum(g$converged),
  significant = sum(g$p < 0.05, na.rm = TRUE), sig_rate = mean(g$p < 0.05, na.rm = TRUE), median_p = median(g$p, na.rm = TRUE),
  median_est = median(g$est, na.rm = TRUE), median_se = median(g$se, na.rm = TRUE))))
pil <- merge(cand, pil, by = "j"); pil <- pil[order(pil$j), ]
write.csv(pil, file.path(RESULTS, "defect_pilot.csv"), row.names = FALSE)
print(pil, digits = 3, row.names = FALSE)
log_footer("job9_pilot", t0)
