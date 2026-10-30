## Job 6: the specification curve beside the swarm, on the duloxetine data of Job 3 (same data preparation and spec).
## stress_grid() fits the full crossed grid: all seven covariance structures (us, ar1h, ar1, cs, csh, toep, toeph), two
## covariate sets (baseline in, baseline out) and three degrees-of-freedom methods (Satterthwaite, linear Kenward-Roger,
## sandwich with between-within df): 42 specifications, one of which is the pre-specified analysis. The grid rows go into a
## census against the pre-specified fit, so every row carries the crossing, interval and shift measures the swarm uses.
## Output: results/spec_grid.csv (one row per specification: the three settings, estimate, SE, df, p, interval, and the
## census measures), results/spec_grid_census.rds (the census, for the figures), results/spec_grid_summary.csv (the numbers
## Section 5.1 quotes: specifications, crossing 0.05, outside the pre-specified interval, range as a percentage of the
## pre-specified estimate, largest shift in pre-specified SEs). Figures S2 and S3 are drawn by figures/figS2_spec_curve.R
## and figures/figS3_spec_swarm.R from the saved census. Run: Rscript scripts/job6_spec_grid.R [cores]
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
suppressPackageStartupMessages({ library(rbmi) })
args <- commandArgs(trailingOnly = TRUE); if (length(args) >= 1) CORES <- as.integer(args[1])
t0 <- log_header("job6_spec_grid")
# ---- duloxetine, exactly as in job3_public_trials.R -----------------------------------------------------------------------
data("antidepressant_data", package = "rbmi"); dat <- antidepressant_data
dat <- expand_locf(dat, PATIENT = levels(dat$PATIENT), VISIT = levels(dat$VISIT), vars = c("BASVAL", "THERAPY"), group = c("PATIENT"), order = c("PATIENT", "VISIT"))
dat <- as.data.frame(dat); dat$CHANGE <- as.numeric(dat$CHANGE)
spec <- stress_spec(dat, response = "CHANGE", subject = "PATIENT", visit = "VISIT", treatment = "THERAPY", reference = "PLACEBO",
                    covariates = ~ BASVAL, contrast_visit = "7", covariance = "us", method = "Satterthwaite", vcov = "Asymptotic", label = "HAMD-17 change at visit 7")
b <- stress_fit(spec)
chk <- c(abs(b$estimate - (-2.872048)) < 1e-5, abs(b$stderr - 1.102845) < 1e-5, abs(b$p - 0.01011878) < 1e-7, b$n_subj == 172, b$n_obs == 608)
cat("duloxetine filed-analysis check (estimate, SE, p, participants, observations):", chk, "\n")
if (!all(chk)) stop("the duloxetine filed analysis differs from the expected values; stopping")
# ---- the crossed grid ---------------------------------------------------------------------------------------------------
COV <- c("us", "ar1h", "ar1", "cs", "csh", "toep", "toeph")
INF <- default_inference()[c("Satterthwaite", "Kenward-Roger (linear)", "Sandwich, between-within")]
CVS <- list("baseline in" = "BASVAL", "baseline out" = character())
t1 <- Sys.time(); grid <- stress_grid(spec, covariance = COV, inference = INF, covariates = CVS, cores = CORES)
cat(sprintf("stress_grid: %d specifications in %.1f min; %d converged; %d reproduce the pre-specified analysis\n", nrow(grid), as.numeric(difftime(Sys.time(), t1, units = "mins")), sum(grid$converged), sum(grid$is_base)))
cen <- stress_census(spec, grid, base = b); x <- as.data.frame(cen)
parts <- do.call(rbind, strsplit(x$label, " | ", fixed = TRUE))
out <- data.frame(specification = seq_len(nrow(x)), covariance = parts[, 1], inference = parts[, 2], covariates = parts[, 3], pre_specified = x$is_base, converged = x$converged, counted = x$counted,
                  estimate = x$estimate, se = x$stderr, df = x$df, p = x$p, lcl = x$lcl, ucl = x$ucl, n_subj = x$n_subj, n_obs = x$n_obs,
                  pct_of_base = x$pct_of_base, shift_se = x$shift_se, inside_ci = x$inside_ci, same_direction = x$same_direction, significant = x$significant, crossed = x$crossed,
                  ballast = as.character(packageVersion("ballast")), commit = ballast_commit(), stringsAsFactors = FALSE)
write.csv(out, file.path(RESULTS, "spec_grid.csv"), row.names = FALSE); saveRDS(cen, file.path(RESULTS, "spec_grid_census.rds"))
print(out[, c("covariance", "inference", "covariates", "estimate", "se", "p", "shift_se", "inside_ci", "crossed")], digits = 4, row.names = FALSE)
# ---- the numbers for Section 5.1 (over every converged specification, the pre-specified one included in the count) ---------
ok <- out[out$converged, ]; alt <- ok[!ok$pre_specified, ]
summ <- data.frame(specifications = nrow(out), converged = nrow(ok), alternatives = nrow(alt), crossed_alpha = sum(alt$crossed), outside_interval = sum(!alt$inside_ci), reversed = sum(!alt$same_direction),
                   significant = sum(ok$significant), estimate_min = min(ok$estimate), estimate_max = max(ok$estimate), pct_of_base_min = min(ok$pct_of_base), pct_of_base_max = max(ok$pct_of_base),
                   max_shift_se = max(abs(alt$shift_se)), p_min = min(ok$p), p_max = max(ok$p), base_estimate = b$estimate, base_se = b$stderr, base_lcl = b$lcl, base_ucl = b$ucl, base_p = b$p,
                   elapsed_min = as.numeric(difftime(Sys.time(), t1, units = "mins")), ballast = as.character(packageVersion("ballast")), commit = ballast_commit())
write.csv(summ, file.path(RESULTS, "spec_grid_summary.csv"), row.names = FALSE); print(t(summ))
print(stress_verdict(cen))
log_footer("job6_spec_grid", t0)
