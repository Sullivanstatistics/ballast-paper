## Simulation study 3: do the missing-data families earn their place? The study-1 design (n = 50 per arm, 4 visits, SD 10,
## AR(1) 0.6, 8% dropout per visit, baseline covariate) under MAR dropout (mnar = 0) and under dropout that depends on the
## unobserved next value (mnar = 1), at planned power 0, 0.8 and 0.95, 200 trials per cell. Each trial gets the light
## family set (covariance, inference, covariates, weighting, leave-one-subject-out) AND reference-based imputation
## (MAR, J2R, CR, CIR; m = 10) AND a delta-adjusted tipping grid at the contrast visit (shifts 0, 0.5, 1, 1.5, 2 x delta,
## or x sigma under the null; m = 5). Two verdicts per trial: light families only, and all families; plus which family
## produced each crossing, the reference-based range, and the tipping margin.
## Output: sim3_rows.csv, sim3_summary.csv. Run: Rscript sim_verdicts3.R [n_trials] [cores]
args <- commandArgs(trailingOnly = TRUE)
NTRIAL <- if (length(args) >= 1) as.integer(args[1]) else 200L
CORES <- if (length(args) >= 2) as.integer(args[2]) else 8L
here <- getwd()   # run from this folder; the original absolute path is redacted in the companion repository
suppressPackageStartupMessages(library(ballast))
N_ARM <- 50; NV <- 4; SIGMA <- 10; RHO <- 0.6; DROP <- 0.08
n_eff <- N_ARM * (1 - DROP)^(NV - 1); r2 <- 25 / 125
delta_for <- function(pw) if (pw == 0) 0 else (qnorm(0.975) + qnorm(pw)) * SIGMA * sqrt(2 / n_eff) * sqrt(1 - r2)
SCEN <- expand.grid(power = c(0, 0.8, 0.95), mnar = c(0, 1), stringsAsFactors = FALSE); SCEN$delta <- vapply(SCEN$power, delta_for, 0)
cat("scenarios:", nrow(SCEN), "x", NTRIAL, "trials\n")
one <- function(job) {
  d <- simulate_trial(N_ARM, job$delta, NV, SIGMA, RHO, DROP, mnar = job$mnar, seed = job$seed)
  spec <- stress_spec(d, "y", "id", "visit", "arm", "REF", covariates = ~ base, contrast_visit = sprintf("V%d", NV), covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
  base <- stress_fit(spec); if (!base$converged) return(NULL)
  light <- list(stress_covariance(spec, c("us", "ar1h", "cs")), stress_inference(spec, default_inference()[c("Satterthwaite", "Kenward-Roger (linear)", "Sandwich, between-within")]),
                stress_covariates(spec), stress_weights(spec), stress_loo(spec))
  ref <- stress_reference(spec, methods = c("MAR", "J2R", "CR", "CIR"), m = 10, seed = job$seed)
  unit <- if (job$delta != 0) abs(job$delta) else SIGMA
  tip <- stress_tipping(spec, deltas = -seq(0, 2, by = 0.5) * unit, m = 5, seed = job$seed, shift_visits = sprintf("V%d", NV))
  cen_l <- do.call(stress_census, c(list(spec = spec), light, list(base = base))); v_l <- stress_verdict(cen_l)
  cen_a <- do.call(stress_census, c(list(spec = spec), light, list(ref, tip), list(base = base))); v_a <- stress_verdict(cen_a)
  x <- as.data.frame(cen_a); sig <- base$p < 0.05
  cross_by <- function(fam) sum(x$counted & x$crossed & grepl(fam, x$family), na.rm = TRUE)
  tp <- tipping_point(tip, 0.05)
  data.frame(mnar = job$mnar, power = job$power, delta = job$delta, seed = job$seed, n_subj = base$n_subj, base_est = base$estimate, base_se = base$stderr, base_p = base$p,
             significant = sig, marginal = v_a$marginal,
             stability_light = v_l$stability, stability_all = v_a$stability, crossed_light = v_l$n_crossed, crossed_all = v_a$n_crossed,
             crossed_loo = cross_by("leave-one-out"), crossed_model = cross_by("covariance|inference|covariate|weight"), crossed_ref = cross_by("reference"), crossed_delta0 = cross_by("delta"),
             outside_ci_all = v_a$n_outside_ci, reversed_all = v_a$n_reversed, max_shift_light = v_l$max_shift_se, max_shift_all = v_a$max_shift_se,
             ref_min = min(ref$estimate, na.rm = TRUE), ref_max = max(ref$estimate, na.rm = TRUE), j2r_p = ref$p[ref$label == "J2R"][1],
             tipping_margin = if (sig) abs(tp$crossing[1]) / unit else NA_real_, n_failed = v_a$n_failed, stringsAsFactors = FALSE)
}
jobs <- do.call(c, lapply(seq_len(nrow(SCEN)), function(s) lapply(seq_len(NTRIAL), function(i) list(power = SCEN$power[s], mnar = SCEN$mnar[s], delta = SCEN$delta[s], seed = 70000 + 1000 * s + i))))
cat(length(jobs), "trials on", CORES, "workers\n"); t0 <- Sys.time()
cl <- parallel::makeCluster(CORES); parallel::clusterEvalQ(cl, { suppressPackageStartupMessages(library(ballast)); NULL })
parallel::clusterExport(cl, c("one", "N_ARM", "NV", "SIGMA", "RHO", "DROP"))
res <- parallel::parLapplyLB(cl, jobs, function(j) tryCatch(one(j), error = function(e) NULL)); parallel::stopCluster(cl)
res <- do.call(rbind, res[!vapply(res, is.null, TRUE)])
write.csv(res, file.path(here, "sim3_rows.csv"), row.names = FALSE)
summ <- do.call(rbind, lapply(split(res, list(res$mnar, res$power), drop = TRUE), function(g) { s <- g$significant; ns <- sum(s); cond <- function(z) if (ns) mean(z[s], na.rm = TRUE) else NA_real_
  data.frame(mnar = g$mnar[1], power_target = g$power[1], trials = nrow(g), n_sig = ns, power_observed = mean(s),
             sensitive_light_given_sig = cond(g$stability_light == "sensitive"), sensitive_all_given_sig = cond(g$stability_all == "sensitive"),
             fragile_all_given_sig = cond(g$stability_all == "fragile"), marginal_given_sig = cond(g$marginal),
             crossed_by_ref_only_given_sig = cond(g$crossed_ref > 0 & g$crossed_light == 0), crossed_by_ref_given_sig = cond(g$crossed_ref > 0),
             crossed_by_loo_given_sig = cond(g$crossed_loo > 0), crossed_by_model_given_sig = cond(g$crossed_model > 0),
             median_tipping_margin = if (ns) median(g$tipping_margin[s], na.rm = TRUE) else NA_real_, tipping_absorbed_given_sig = cond(is.na(g$tipping_margin)),
             median_ref_spread_se = median((g$ref_max - g$ref_min) / g$base_se), median_max_shift_light = median(g$max_shift_light), median_max_shift_all = median(g$max_shift_all),
             fragile_all = mean(g$stability_all == "fragile"), failed = mean(g$n_failed > 0)) }))
summ <- summ[order(summ$mnar, summ$power_target), ]
write.csv(summ, file.path(here, "sim3_summary.csv"), row.names = FALSE)
print(summ, digits = 3, row.names = FALSE)
cat("elapsed", format(round(difftime(Sys.time(), t0, units = "mins"), 1)), "\n")
