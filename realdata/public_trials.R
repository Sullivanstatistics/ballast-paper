# Two more public trials under the margin-of-error definition.
#  BtheB (HSAUR3): Beat the Blues, computerised CBT vs treatment as usual, BDI at 2/3/5/8 months, n = 100 (Proudfoot 2003).
#  aids  (JM):     ddI vs ddC in advanced HIV, CD4 (square-root scale) at 2/6/12/18 months, n = 467 (Abrams 1994; Goldman 1996).
suppressPackageStartupMessages({library(ballast); library(dplyr); library(tidyr)})
CORES <- 8L
assess <- function(name, spec, site = NULL, delta, max_k = 40, max_k_dir = 80) {
  base <- stress_fit(spec); z <- base$estimate / base$stderr; n <- base$n_subj
  cat(sprintf("\n==== %s: estimate %.3f (SE %.3f), 95%% CI %.3f to %.3f, p = %.4f, z = %.2f, n = %d, obs = %d\n", name, base$estimate, base$stderr,
              base$lcl, base$ucl, base$p, z, n, base$n_obs))
  t0 <- Sys.time()
  fams <- list(stress_covariance(spec, c("cs", "ar1h")), stress_covariates(spec), stress_weights(spec), stress_inference(spec),
               stress_loo(spec, cores = CORES))
  if (!is.null(site)) fams <- c(fams, list(stress_loo(spec, by = site)))
  ref <- tryCatch(stress_reference(spec, c("J2R", "CR", "CIR"), m = 10, seed = 1), error = function(e) { cat("reference MI skipped:", conditionMessage(e), "\n"); NULL })
  if (!is.null(ref)) fams <- c(fams, list(ref))
  cen <- do.call(stress_census, c(list(spec = spec), fams, list(base = base)))
  v <- stress_verdict(cen); print(v)
  p_all <- stress_path(spec, path_changes(spec, inference = list(), reference = if (is.null(ref)) character() else c("J2R", "CR", "CIR"),
                                          delta_adjusted = if (is.null(ref)) numeric() else delta, m = 10), max_j = 5, seed = 1, cores = CORES)
  p_pure <- stress_path(spec, path_changes(spec, inference = list(), reference = character(), delta_adjusted = numeric()), max_j = 5, seed = 1, cores = CORES)
  a <- attr(p_all, "path"); b <- attr(p_pure, "path")
  cat(sprintf("path (all families): j = %s, %s, assumption_dependent = %s\npath (pure): j = %s, %s\n", a$j, paste(a$changes, collapse = " + "), a$assumption_dependent, b$j, paste(b$changes, collapse = " + ")))
  bench <- deletion_benchmark(n, z = z); print(bench)
  k <- sapply(c(mutual = "mutual", ci = "ci", significance = "significance"), function(t) attr(stress_fragility(spec, t, max_k = max_k, method = "ranked", cores = CORES), "fragility")$k)
  print(k); cat("removal ratio (mutual / benchmark ci):", k[["mutual"]] / bench[["ci"]], "\n")
  dr <- stress_direction(spec, cen, max_k = max_k_dir, cores = CORES); print(dr)
  cat(sprintf("elapsed %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  list(base = base, census = cen, verdict = v, path_all = p_all, path_pure = p_pure, bench = bench, k = k, direction = dr)
}

# ---- Beat the Blues --------------------------------------------------------------------------------------------------
data("BtheB", package = "HSAUR3")
btb <- BtheB |> mutate(id = factor(row_number())) |>
  pivot_longer(c(bdi.2m, bdi.3m, bdi.5m, bdi.8m), names_to = "visit", values_to = "bdi") |>
  mutate(visit = factor(sub("bdi.", "", visit, fixed = TRUE), levels = c("2m", "3m", "5m", "8m")), change = bdi - bdi.pre) |>
  filter(!is.na(change))
spec_btb <- stress_spec(btb, "change", "id", "visit", "treatment", "TAU", covariates = ~ bdi.pre + drug + length, contrast_visit = "8m",
                        covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
res_btb <- assess("Beat the Blues (BDI change at 8 months, BtheB vs TAU)", spec_btb, delta = 4)

# ---- ddI vs ddC (aids) ----------------------------------------------------------------------------------------------
data("aids", package = "JM")
base_cd4 <- aids |> filter(obstime == 0) |> select(patient, cd4_base = CD4)
aids_l <- aids |> filter(obstime > 0) |> inner_join(base_cd4, by = "patient") |>
  mutate(patient = factor(patient), visit = factor(obstime, levels = c(2, 6, 12, 18)), change = CD4 - cd4_base)
spec_aids <- stress_spec(aids_l, "change", "patient", "visit", "drug", "ddC", covariates = ~ cd4_base + prevOI + AZT, contrast_visit = "12",
                         covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
res_aids <- assess("ddI vs ddC (CD4 change, square-root scale, at 12 months)", spec_aids, delta = 1, max_k = 60, max_k_dir = 120)

saveRDS(list(btb = res_btb, aids = res_aids), "public_trials_results.rds")
cat("\nDONE\n")
