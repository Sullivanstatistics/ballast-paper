# The antidepressant trial (rbmi::antidepressant_data; Goldstein et al. 2004, duloxetine vs placebo, HAMD-17 change at
# weeks 1-6, visits 4-7; the standard public example of the reference-based imputation literature) under the
# margin-of-error definition. Pre-specified analysis: MMRM, change from baseline, visit x arm, baseline covariate,
# unstructured covariance, Satterthwaite df, contrast at visit 7.
suppressPackageStartupMessages({library(ballast); library(dplyr)})
d <- rbmi::antidepressant_data |> mutate(PATIENT = factor(PATIENT), VISIT = factor(VISIT), THERAPY = factor(THERAPY))
spec <- stress_spec(d, "CHANGE", "PATIENT", "VISIT", "THERAPY", "PLACEBO", covariates = ~ BASVAL, contrast_visit = "7",
                    covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
base <- stress_fit(spec); print(base[, c("estimate","stderr","lcl","ucl","p","n_subj","n_obs")])
z <- base$estimate / base$stderr; n <- base$n_subj
t0 <- Sys.time()
fams <- list(stress_covariance(spec, c("cs", "ar1h")), stress_covariates(spec), stress_weights(spec), stress_inference(spec),
             stress_loo(spec), stress_loo(spec, by = "POOLINV"), stress_reference(spec, c("J2R", "CR", "CIR"), m = 10, seed = 1))
cen <- do.call(stress_census, c(list(spec = spec), fams, list(base = base)))
v <- stress_verdict(cen); print(v)
cat("\n--- analytic path (all families incl. missing-data) ---\n")
ch_all <- path_changes(spec, inference = list(), reference = c("J2R", "CR", "CIR"), delta_adjusted = 4, m = 10)
p_all <- stress_path(spec, ch_all, max_j = 5, seed = 1); print(attr(p_all, "path")[c("j","reached","direction","changes","assumption_dependent")])
cat("\n--- analytic path (pure: no missing-data family) ---\n")
ch_pure <- path_changes(spec, inference = list(), reference = character(), delta_adjusted = numeric())
p_pure <- stress_path(spec, ch_pure, max_j = 5, seed = 1); print(attr(p_pure, "path")[c("j","reached","direction","changes")])
cat("\n--- data axis (ranked removal) ---\n")
bench <- deletion_benchmark(n, z = z); print(bench)
fr_mut <- stress_fragility(spec, "mutual", max_k = 40, method = "ranked"); fr_ci <- stress_fragility(spec, "ci", max_k = 40, method = "ranked")
fr_sig <- stress_fragility(spec, "significance", max_k = 40, method = "ranked"); fr_dir <- stress_fragility(spec, "direction", max_k = 60, method = "ranked")
k <- sapply(list(mutual = fr_mut, ci = fr_ci, significance = fr_sig, direction = fr_dir), function(f) attr(f, "fragility")$k); print(k)
cat("removal ratio (mutual / benchmark ci):", k[["mutual"]] / bench[["ci"]], "\n")
cat("\n--- direction stability ---\n"); print(stress_direction(spec, cen, max_k = 60))
cat(sprintf("\nelapsed %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
saveRDS(list(base = base, census = cen, verdict = v, path_all = p_all, path_pure = p_pure, bench = bench, k = k,
             fr = list(mutual = fr_mut, ci = fr_ci, significance = fr_sig, direction = fr_dir)), "antidepressant_results.rds")
