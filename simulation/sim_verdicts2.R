## Simulation study 2: a second design and model misspecification.
## Scenarios (each at planned power 0, 0.8 and 0.95 for the pre-specified MMRM, delta sized under the base design):
##   base2    n = 100 per arm, 8 visits, AR(1) 0.6, 20% total dropout (MAR), normal errors
##   heavy    base2 with Student-t(3) errors scaled to the same SD
##   hetero   base2 with the residual SD doubling from first to last visit
##   mnar     base2 with dropout depending on the unobserved next value (mnar = 1)
##   interact base2 with the treatment effect varying with baseline (interaction = 0.5)
## Per trial: the light family set (covariance, inference, covariates, weighting, leave-one-out); the single-subject fragility
## (k = 1) is read off the leave-one-out rows rather than searched, to keep the run to a few hours.
## Output: sim2_rows.csv (one row per trial) and sim2_summary.csv. Run: Rscript sim_verdicts2.R [n_trials] [cores]
args <- commandArgs(trailingOnly = TRUE)
NTRIAL <- if (length(args) >= 1) as.integer(args[1]) else 50L
CORES <- if (length(args) >= 2) as.integer(args[2]) else 8L
here <- getwd()   # run from this folder; the original absolute path is redacted in the companion repository
suppressPackageStartupMessages(library(ballast))
N_ARM <- 100; NV <- 8; SIGMA <- 10; RHO <- 0.6; DROP <- 0.03   # ~0.03 per visit over 7 transitions ~ 19% by the last visit
n_eff <- N_ARM * (1 - DROP)^(NV - 1); r2 <- 25 / 125
delta_for <- function(pw) if (pw == 0) 0 else (qnorm(0.975) + qnorm(pw)) * SIGMA * sqrt(2 / n_eff) * sqrt(1 - r2)
SCEN <- expand.grid(power = c(0, 0.8, 0.95), design = c("base2", "heavy", "hetero", "mnar", "interact"), stringsAsFactors = FALSE)
SCEN$delta <- vapply(SCEN$power, delta_for, 0)
settings <- list(base2 = list(), heavy = list(errors = "t", t_df = 3), hetero = list(hetero = 2), mnar = list(mnar = 1), interact = list(interaction = 0.5))
cat("scenarios:", nrow(SCEN), "x", NTRIAL, "trials\n")
one <- function(job) {
  st <- settings[[job$design]]
  d <- do.call(simulate_trial, c(list(n_per_arm = N_ARM, delta = job$delta, n_visits = NV, sigma = SIGMA, rho = RHO, dropout = DROP, seed = job$seed), st))
  spec <- stress_spec(d, "y", "id", "visit", "arm", "REF", covariates = ~ base, contrast_visit = sprintf("V%d", NV), covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
  base <- stress_fit(spec); if (!base$converged) return(NULL)
  rows <- list(stress_covariance(spec, c("us", "ar1h", "cs")), stress_inference(spec, default_inference()[c("Satterthwaite", "Kenward-Roger (linear)", "Sandwich, between-within")]),
               stress_covariates(spec), stress_weights(spec), stress_loo(spec))
  cen <- do.call(stress_census, c(list(spec = spec), rows, list(base = base))); v <- stress_verdict(cen)
  loo <- as.data.frame(cen)[cen$family == "leave-one-out: subject" & cen$counted, ]; k1 <- any((loo$p < 0.05) != (base$p < 0.05), na.rm = TRUE)
  data.frame(design = job$design, power = job$power, delta = job$delta, seed = job$seed, n_subj = base$n_subj, base_est = base$estimate, base_se = base$stderr, base_p = base$p,
             significant = base$p < 0.05, stability = v$stability, marginal = v$marginal, crossed = v$n_crossed, outside_ci = v$n_outside_ci, reversed = v$n_reversed,
             max_shift_se = v$max_shift_se, frag_k = if (k1) 1L else NA_integer_, n_failed = v$n_failed, stringsAsFactors = FALSE)
}
jobs <- do.call(c, lapply(seq_len(nrow(SCEN)), function(s) lapply(seq_len(NTRIAL), function(i) list(design = SCEN$design[s], power = SCEN$power[s], delta = SCEN$delta[s], seed = 50000 + 1000 * s + i))))
cat(length(jobs), "trials on", CORES, "workers\n"); t0 <- Sys.time()
cl <- parallel::makeCluster(CORES); parallel::clusterEvalQ(cl, { suppressPackageStartupMessages(library(ballast)); NULL })
parallel::clusterExport(cl, c("one", "settings", "N_ARM", "NV", "SIGMA", "RHO", "DROP"))
res <- parallel::parLapplyLB(cl, jobs, function(j) tryCatch(one(j), error = function(e) NULL)); parallel::stopCluster(cl)
res <- do.call(rbind, res[!vapply(res, is.null, TRUE)])
write.csv(res, file.path(here, "sim2_rows.csv"), row.names = FALSE)
summ <- do.call(rbind, lapply(split(res, list(res$design, res$power), drop = TRUE), function(g) data.frame(
  design = g$design[1], power_target = g$power[1], trials = nrow(g), power_observed = mean(g$significant), marginal = mean(g$marginal),
  robust = mean(g$stability == "robust"), sensitive = mean(g$stability == "sensitive"), fragile = mean(g$stability == "fragile"),
  sensitive_given_sig = if (any(g$significant)) mean(g$stability[g$significant] == "sensitive") else NA, fragile_given_sig = if (any(g$significant)) mean(g$stability[g$significant] == "fragile") else NA,
  frag_reached_given_sig = if (any(g$significant)) mean(!is.na(g$frag_k[g$significant])) else NA, median_max_shift_se = median(g$max_shift_se), failed = mean(g$n_failed > 0))))
summ <- summ[order(summ$design, summ$power_target), ]
write.csv(summ, file.path(here, "sim2_summary.csv"), row.names = FALSE)
print(summ, digits = 3, row.names = FALSE)
cat("elapsed", format(round(difftime(Sys.time(), t0, units = "mins"), 1)), "\n")
