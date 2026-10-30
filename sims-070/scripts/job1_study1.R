## Job 1: Study 1 rerun under ballast 0.7.1. Copied from validation/simulation/sim_verdicts.R (0.6.0, 16 Oct 2026) with the
## same design, scenarios, families, seeds and trial counts; the per-trial row gains outside_ci and reversed (counts over
## the counted rows, as Study 2 already saved) so the verdict can be audited and recomputed without another run.
## Design: two-arm trial, 50 per arm, four post-baseline visits, baseline covariate; responses MVN with AR(1) rho 0.6 and
## SD 10; the treatment effect grows linearly to delta at visit 4; dropout after each visit depends on the current value
## (MAR); baseline coefficient 0.5. Scenarios: delta for planned power 0, 0.5, 0.8, 0.95 of the pre-specified MMRM.
## Per trial: covariance (us, ar1h, cs), inference (Satterthwaite, linear KR, sandwich BW), covariate set (drop baseline),
## LS-mean weighting, leave-one-subject-out, greedy fragility search for significance (max 3 removals).
## Run: Rscript scripts/job1_study1.R [n_trials_per_scenario] [cores]      Output: results/study1_rows.csv, results/study1_summary.csv
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
args <- commandArgs(trailingOnly = TRUE)
NTRIAL <- if (length(args) >= 1) as.integer(args[1]) else 200L
if (length(args) >= 2) CORES <- as.integer(args[2])
t0 <- log_header("job1_study1")
N_ARM <- 50; NV <- 4; SIGMA <- 10; RHO <- 0.6; DROP <- 0.08
n_eff <- N_ARM * (1 - DROP)^(NV - 1)
delta_for <- function(pow) if (pow == 0) 0 else (qnorm(0.975) + qnorm(pow)) * SIGMA * sqrt(2 / n_eff) * sqrt(0.75)
SCEN <- data.frame(power = c(0, 0.5, 0.8, 0.95)); SCEN$delta <- vapply(SCEN$power, delta_for, 0)
cat("scenarios:\n"); print(SCEN)

sim_trial <- function(seed, delta) {
  set.seed(seed)
  n <- 2 * N_ARM; arm <- rep(c("PBO", "TRT"), each = N_ARM); base <- rnorm(n, 50, 10)
  R <- RHO^abs(outer(1:NV, 1:NV, "-")); L <- chol(R)
  eps <- matrix(rnorm(n * NV), n) %*% L * SIGMA
  mu <- outer(0.5 * (base - 50), rep(1, NV)) + outer(arm == "TRT", delta * (1:NV) / NV)
  Y <- mu + eps
  for (v in 2:NV) { z <- (Y[, v - 1] - mean(Y[, v - 1])) / SIGMA; p <- plogis(qlogis(DROP) - 0.8 * z)
    gone <- is.na(Y[, v - 1]) | runif(n) < p; Y[gone, v:NV] <- NA }
  data.frame(id = rep(sprintf("S%03d", 1:n), each = NV), arm = rep(arm, each = NV), base = rep(base, each = NV),
             visit = rep(sprintf("V%d", 1:NV), n), y = as.vector(t(Y)), stringsAsFactors = FALSE)
}
one <- function(job) {
  d <- sim_trial(job$seed, job$delta); d <- d[!is.na(d$y), ]
  spec <- stress_spec(d, "y", "id", "visit", "arm", "PBO", covariates = ~ base, contrast_visit = "V4", covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
  base <- stress_fit(spec); if (!base$converged) return(NULL)
  rows <- list(stress_covariance(spec, c("us", "ar1h", "cs")),
               stress_inference(spec, default_inference()[c("Satterthwaite", "Kenward-Roger (linear)", "Sandwich, between-within")]),
               stress_covariates(spec), stress_weights(spec), stress_loo(spec))
  cen <- do.call(stress_census, c(list(spec = spec), rows, list(base = base))); v <- stress_verdict(cen)
  fr <- attr(stress_fragility(spec, "significance", max_k = 3), "fragility")
  alt <- cen[cen$counted & cen$kind == "alternative", ]; del <- cen[cen$counted & cen$kind == "deletion", ]
  data.frame(power = job$power, delta = job$delta, seed = job$seed, n_subj = base$n_subj, base_est = base$estimate, base_se = base$stderr, base_p = base$p,
             significant = base$p < 0.05, stability = v$stability, marginal = v$marginal, rule = v$rule,
             crossed = v$n_crossed, outside_ci = v$n_outside_ci, reversed = v$n_reversed,
             n_alt = nrow(alt), alt_crossed = sum(alt$crossed, na.rm = TRUE), n_del = nrow(del), del_crossed = sum(del$crossed, na.rm = TRUE),
             max_shift_se = v$max_shift_se, pct_min = min(cen$pct_of_base[cen$counted], na.rm = TRUE), pct_max = max(cen$pct_of_base[cen$counted], na.rm = TRUE),
             frag_k = if (fr$reached) fr$k else NA_integer_, n_failed = sum(!cen$converged), stringsAsFactors = FALSE)
}
jobs <- do.call(c, lapply(seq_len(nrow(SCEN)), function(s) lapply(seq_len(NTRIAL), function(i) list(power = SCEN$power[s], delta = SCEN$delta[s], seed = 1000 * s + i))))
cat(length(jobs), "trials on", CORES, "workers\n")
cl <- parallel::makeCluster(CORES); parallel::clusterEvalQ(cl, { suppressPackageStartupMessages(library(ballast)); NULL })
parallel::clusterExport(cl, c("sim_trial", "one", "N_ARM", "NV", "SIGMA", "RHO", "DROP"))
res <- parallel::parLapplyLB(cl, jobs, function(j) tryCatch(one(j), error = function(e) NULL)); parallel::stopCluster(cl)
failed <- sum(vapply(res, is.null, TRUE)); res <- do.call(rbind, res[!vapply(res, is.null, TRUE)])
cat(sprintf("%d trials returned, %d failed (not converged or error)\n", nrow(res), failed))
res$ballast <- as.character(packageVersion("ballast")); res$commit <- ballast_commit()
write.csv(res, file.path(RESULTS, "study1_rows.csv"), row.names = FALSE)
summ <- do.call(rbind, lapply(split(res, res$power), function(g) data.frame(
  power_target = g$power[1], delta = round(g$delta[1], 2), trials = nrow(g), power_observed = mean(g$significant), marginal = mean(g$marginal),
  robust = mean(g$stability == "robust"), sensitive = mean(g$stability == "sensitive"), fragile = mean(g$stability == "fragile"),
  robust_given_sig = mean(g$stability[g$significant] == "robust"), sensitive_given_sig = mean(g$stability[g$significant] == "sensitive"),
  fragile_given_sig = mean(g$stability[g$significant] == "fragile"),
  frag_k1_given_sig = mean(g$frag_k[g$significant] == 1, na.rm = TRUE), frag_reached_given_sig = mean(!is.na(g$frag_k[g$significant])),
  median_alt_crossed = median(g$alt_crossed), median_del_crossed = median(g$del_crossed), median_max_shift_se = median(g$max_shift_se),
  outside_ci_any = mean(g$outside_ci > 0), reversed_any = mean(g$reversed > 0), failed = failed)))
write.csv(summ, file.path(RESULTS, "study1_summary.csv"), row.names = FALSE)
print(summ, digits = 3, row.names = FALSE)
log_footer("job1_study1", t0)
