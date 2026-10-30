## Job 5: Study 2 at 400 trials per cell (copied from validation/simulation/sim_verdicts2.R, the 0.6.0 script, and pointed
## at this folder). Same design (100 per arm, 8 visits, AR(1) 0.6, about 19% cumulative dropout), same five settings (base2,
## heavy tails, heteroscedastic, MNAR dropout, effect modification), same light family set (covariance us/ar1h/cs, three
## inference settings, covariates, weighting, leave-one-subject-out), planned power 0.8 and 0.95 only: the null cells are
## dropped (Study 1 and Study 3 carry the null behaviour). 400 trials per cell, 4,000 in all.
## Seeds: the 0.6.0 scheme, seed = 50000 + 1000 * s + i with s the row of the original 15-cell grid (power 0, 0.8, 0.95 by
## design) and i the trial, so trials 1 to 50 of every cell reproduce the 0.6.0 run exactly and trials 51 to 400 extend the
## sequence; i < 1000, so no seed is shared between cells.
## Per trial: the verdict under the interval rule (the 0.7.x default) with crossed, outside_ci and reversed as separate
## columns, as Job 1 did; frag_k = 1 when one deletion loses significance (read off the leave-one-out rows).
## Before anything is reported the first 50 trials of each cell are checked against the reclassified 0.6.0 rows
## (SIMS070_PREVIOUS/results/study2_reclass.csv): the same estimate, SE, p and label, or the script stops.
## Output: results/study2_400_rows.csv, results/study2_400_summary.csv (with the Monte Carlo standard error of each
## conditional rate, sqrt(p (1 - p) / n_sig)), results/study2_400_check50.csv. Each cell is saved as it finishes in
## results/study2_400_chunks/ and skipped on a rerun, so an interrupted run resumes.
## Run: Rscript scripts/job5_study2.R [n_trials] [cores]
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
args <- commandArgs(trailingOnly = TRUE)
NTRIAL <- if (length(args) >= 1) as.integer(args[1]) else 400L
if (length(args) >= 2) CORES <- as.integer(args[2])
t0 <- log_header("job5_study2")
N_ARM <- 100; NV <- 8; SIGMA <- 10; RHO <- 0.6; DROP <- 0.03   # ~0.03 per visit over 7 transitions ~ 19% by the last visit
n_eff <- N_ARM * (1 - DROP)^(NV - 1); r2 <- 25 / 125
delta_for <- function(pw) if (pw == 0) 0 else (qnorm(0.975) + qnorm(pw)) * SIGMA * sqrt(2 / n_eff) * sqrt(1 - r2)
SCEN <- expand.grid(power = c(0, 0.8, 0.95), design = c("base2", "heavy", "hetero", "mnar", "interact"), stringsAsFactors = FALSE)   # the 0.6.0 grid, kept for the seeds
SCEN$delta <- vapply(SCEN$power, delta_for, 0); SCEN$s <- seq_len(nrow(SCEN))
RUN <- SCEN[SCEN$power > 0, ]   # the cells run here
settings <- list(base2 = list(), heavy = list(errors = "t", t_df = 3), hetero = list(hetero = 2), mnar = list(mnar = 1), interact = list(interaction = 0.5))
cat("cells:", nrow(RUN), "of", nrow(SCEN), "(null cells dropped) x", NTRIAL, "trials =", nrow(RUN) * NTRIAL, "trials on", CORES, "workers\n")
one <- function(job) {
  st <- settings[[job$design]]
  d <- do.call(simulate_trial, c(list(n_per_arm = N_ARM, delta = job$delta, n_visits = NV, sigma = SIGMA, rho = RHO, dropout = DROP, seed = job$seed), st))
  spec <- stress_spec(d, "y", "id", "visit", "arm", "REF", covariates = ~ base, contrast_visit = sprintf("V%d", NV), covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
  base <- stress_fit(spec); if (!base$converged) return(NULL)
  rows <- list(stress_covariance(spec, c("us", "ar1h", "cs")), stress_inference(spec, default_inference()[c("Satterthwaite", "Kenward-Roger (linear)", "Sandwich, between-within")]),
               stress_covariates(spec), stress_weights(spec), stress_loo(spec))
  cen <- do.call(stress_census, c(list(spec = spec), rows, list(base = base))); v <- stress_verdict(cen)
  loo <- as.data.frame(cen)[cen$family == "leave-one-out: subject" & cen$counted, ]; k1 <- any((loo$p < 0.05) != (base$p < 0.05), na.rm = TRUE)
  data.frame(design = job$design, power = job$power, delta = job$delta, seed = job$seed, trial = job$i, n_subj = base$n_subj, base_est = base$estimate, base_se = base$stderr, base_p = base$p,
             significant = base$p < 0.05, stability = v$stability, marginal = v$marginal, rule = v$rule, crossed = v$n_crossed, outside_ci = v$n_outside_ci, reversed = v$n_reversed,
             max_shift_se = v$max_shift_se, frag_k = if (k1) 1L else NA_integer_, n_failed = v$n_failed, stringsAsFactors = FALSE)
}
chunks <- file.path(RESULTS, "study2_400_chunks"); dir.create(chunks, showWarnings = FALSE, recursive = TRUE)
cl <- parallel::makeCluster(CORES); invisible(parallel::clusterEvalQ(cl, { suppressPackageStartupMessages(library(ballast)); NULL }))
parallel::clusterExport(cl, c("one", "settings", "N_ARM", "NV", "SIGMA", "RHO", "DROP"))
res <- list()
for (r in seq_len(nrow(RUN))) {
  cell <- RUN[r, ]; f <- file.path(chunks, sprintf("%s_%s.csv", cell$design, cell$power))
  if (file.exists(f)) { res[[r]] <- read.csv(f, stringsAsFactors = FALSE); cat(sprintf("%s power %s: %d rows already saved, skipped\n", cell$design, cell$power, nrow(res[[r]]))); next }
  jobs <- lapply(seq_len(NTRIAL), function(i) list(design = cell$design, power = cell$power, delta = cell$delta, seed = 50000 + 1000 * cell$s + i, i = i))
  t1 <- Sys.time()
  out <- parallel::parLapplyLB(cl, jobs, function(j) tryCatch(one(j), error = function(e) NULL))
  out <- do.call(rbind, out[!vapply(out, is.null, TRUE)]); write.csv(out, f, row.names = FALSE); res[[r]] <- out
  cat(sprintf("%s power %s: %d of %d trials, %.1f min\n", cell$design, cell$power, nrow(out), NTRIAL, as.numeric(difftime(Sys.time(), t1, units = "mins"))))
}
parallel::stopCluster(cl)
res <- do.call(rbind, res); res$ballast <- as.character(packageVersion("ballast")); res$commit <- ballast_commit()
# ---- the first 50 trials of each cell must reproduce the 0.6.0 run (as reclassified under the interval rule) -------------
prev <- read.csv(file.path(PREVIOUS, "results", "study2_reclass.csv"), stringsAsFactors = FALSE)
# In study2_reclass.csv the column `stability` is the original 0.6.0 label (interval_or_direction rule) and `stability_071` is the
# same trial relabelled under the interval rule, which is what stress_verdict() applies here. The first server attempt compared
# with `stability` and stopped on the 16 non-significant trials that reversed inside the interval (logs/job5_study2_server_attempt1.log).
prev$stability <- prev$stability_071
m <- merge(res[res$trial <= 50, ], prev, by = c("design", "power", "seed"), suffixes = c("", "_prev"))
chk <- data.frame(cell = paste(m$design, m$power), seed = m$seed,
                  est_ok = abs(m$base_est - m$base_est_prev) < 1e-6, se_ok = abs(m$base_se - m$base_se_prev) < 1e-6, p_ok = abs(m$base_p - m$base_p_prev) < 1e-6,
                  label_ok = m$stability == m$stability_prev, shift_ok = abs(m$max_shift_se - m$max_shift_se_prev) < 1e-6)
write.csv(chk, file.path(RESULTS, "study2_400_check50.csv"), row.names = FALSE)
expected <- min(NTRIAL, 50L) * nrow(RUN)
cat(sprintf("\ncheck of the first 50 trials per cell against study2_reclass.csv: %d rows matched by seed (expected %d); estimate %d ok, SE %d ok, p %d ok, label %d ok, largest shift %d ok\n",
            nrow(chk), expected, sum(chk$est_ok), sum(chk$se_ok), sum(chk$p_ok), sum(chk$label_ok), sum(chk$shift_ok)))
if (nrow(chk) != expected || !all(chk$est_ok & chk$se_ok & chk$p_ok & chk$label_ok)) stop("the first 50 trials of a cell do not reproduce the 0.6.0 run; stopping before any summary is written (see results/study2_400_check50.csv)")
write.csv(res, file.path(RESULTS, "study2_400_rows.csv"), row.names = FALSE)
# ---- summary with Monte Carlo standard errors -------------------------------------------------------------------------------
mcse <- function(p, n) if (n > 0) sqrt(p * (1 - p) / n) else NA_real_
summ <- do.call(rbind, lapply(split(res, list(res$design, res$power), drop = TRUE), function(g) { sg <- g[g$significant, ]; ns <- nrow(sg)
  ps <- if (ns) mean(sg$stability == "sensitive") else NA; pf <- if (ns) mean(sg$stability == "fragile") else NA; pk <- if (ns) mean(!is.na(sg$frag_k)) else NA   # frag_k is 1 when a single deletion loses significance, else NA (as frag_reached_given_sig in the 0.6.0 script)
  data.frame(design = g$design[1], power_target = g$power[1], delta = g$delta[1], trials = nrow(g), power_observed = mean(g$significant), n_significant = ns, marginal = mean(g$marginal),
             robust = mean(g$stability == "robust"), sensitive = mean(g$stability == "sensitive"), fragile = mean(g$stability == "fragile"),
             sensitive_given_sig = ps, sensitive_given_sig_mcse = mcse(ps, ns), fragile_given_sig = pf, fragile_given_sig_mcse = mcse(pf, ns),
             frag_k1_given_sig = pk, frag_k1_given_sig_mcse = mcse(pk, ns), median_max_shift_se = median(g$max_shift_se),
             outside_ci_any = mean(g$outside_ci > 0), reversed_any = mean(g$reversed > 0), failed = mean(g$n_failed > 0), stringsAsFactors = FALSE) }))
summ <- summ[order(summ$design, summ$power_target), ]; rownames(summ) <- NULL
write.csv(summ, file.path(RESULTS, "study2_400_summary.csv"), row.names = FALSE)
print(summ, digits = 3, row.names = FALSE)
log_footer("job5_study2", t0)
