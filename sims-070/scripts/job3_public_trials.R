## Job 3: the two public trials under standard_plan() with ballast 0.7.1.
##  duloxetine (rbmi::antidepressant_data): HAMD-17 change over four post-baseline visits, baseline as covariate, contrast
##    DRUG minus PLACEBO at visit 7, delta grid 0 to 6 on the drug arm (as validation/antidepressant/antidepressant_standard.R).
##    Expected filed analysis, identical in every run since 0.6.0: estimate -2.872048, SE 1.102845, p 0.01011878, 172
##    participants, 608 observations. If it differs the script stops.
##  ddI vs ddC (JM::aids): square-root CD4 change at 2, 6, 12, 18 months, contrast at 12 months, covariates baseline CD4,
##    prior opportunistic infection and prior AZT (as 2026-10-25-methods-paper/realdata/public_trials.R), plus stress_direction().
## For each: run_plan(), stress_report(), stress_tables(), stress_log(); results RDS, census CSV, log JSON; the swarm, p-strip,
## p-CDF and family plots with the 0.7.1 functions; and the summary numbers in results/public_trials_summary.csv.
## Run: Rscript scripts/job3_public_trials.R [cores]
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
suppressPackageStartupMessages({ library(rbmi); library(JM); library(dplyr); library(ggplot2) })
args <- commandArgs(trailingOnly = TRUE); if (length(args) >= 1) CORES <- as.integer(args[1])
t0 <- log_header("job3_public_trials")
SEED <- 20261017
save_fig <- function(g, stem, w = 7, h = 4.5) { for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0(stem, ".", ext)), g, width = w, height = h, dpi = 300, bg = "white") }
summarise_run <- function(name, res, dr = NULL) {
  cen <- res$census; v <- res$verdict; x <- as.data.frame(cen); cnt <- x[x$counted & !is.na(x$estimate), ]
  crossed <- cnt[cnt$crossed %in% TRUE, ]
  tp <- if (!is.null(res$rows$tipping)) tipping_point(res$rows$tipping) else NULL
  fr <- if (!is.null(res$rows$fragility)) attr(res$rows$fragility, "fragility") else NULL
  data.frame(trial = name, estimate = res$base$estimate, se = res$base$stderr, lcl = res$base$lcl, ucl = res$base$ucl, p = res$base$p, n_subj = res$base$n_subj, n_obs = res$base$n_obs,
             counted_alternatives = sum(cnt$kind == "alternative"), counted_deletions = sum(cnt$kind == "deletion"), not_converged = sum(!x$converged),
             crossed = nrow(crossed), crossed_families = paste(unique(crossed$family), collapse = "; "), outside_ci = sum(!cnt$inside_ci), reversed = sum(!cnt$same_direction),
             max_shift_se = v$max_shift_se, tipping_point = if (!is.null(tp) && nrow(tp)) tp$crossing[1] else NA_real_,
             greedy_k_to_lose_significance = if (!is.null(fr) && fr$reached) fr$k else NA_integer_, verdict = v$stability, marginal = v$marginal, rule = v$rule,
             direction_reversed_by = if (is.null(dr)) NA_integer_ else dr$n_reversed, direction_k_rev = if (is.null(dr)) NA_integer_ else dr$k_rev,
             elapsed_min = as.numeric(res$elapsed), ballast = as.character(packageVersion("ballast")), commit = ballast_commit(), stringsAsFactors = FALSE)
}
run_one <- function(name, stem, spec, plan, direction = FALSE) {
  cat(sprintf("\n==== %s ====\n", name)); base <- stress_fit(spec); print(base[, c("estimate", "stderr", "df", "lcl", "ucl", "p", "n_subj", "n_obs")])
  cat(stress_sap(plan, trial = name), sep = "\n\n")
  t1 <- Sys.time(); res <- run_plan(plan, cores = CORES, seed = SEED); cat(sprintf("run_plan: %.1f min\n", as.numeric(difftime(Sys.time(), t1, units = "mins"))))
  print(res$verdict); print(summary(res$census))
  out <- file.path(RESULTS, stem); dir.create(out, showWarnings = FALSE, recursive = TRUE)
  saveRDS(res, file.path(out, paste0(stem, "_results.rds"))); write.csv(as.data.frame(res$census), file.path(out, paste0(stem, "_census.csv")), row.names = FALSE)
  stress_report(res, dir = out, name = stem); stress_tables(res, dir = out, name = stem); stress_log(res, file.path(out, paste0(stem, "_log.json")))
  dr <- NULL
  if (direction) { dr <- stress_direction(spec, res$census, max_k = 40, cores = CORES); print(dr); saveRDS(dr, file.path(out, paste0(stem, "_direction.rds"))) }
  cl <- list(res); names(cl) <- name
  save_fig(plot_swarm(cl), paste0(stem, "_swarm")); save_fig(plot_pstrip(res, label_family = FALSE), paste0(stem, "_pstrip"))
  save_fig(plot_pcdf(res), paste0(stem, "_pcdf"), w = 5, h = 5); save_fig(plot(res$census), paste0(stem, "_family"), h = 6)
  if (any(as.data.frame(res$census)$role == "supplementary")) save_fig(plot_forest(res), paste0(stem, "_forest"))
  summarise_run(name, res, dr)
}
# ---- duloxetine ---------------------------------------------------------------------------------------------------------
data("antidepressant_data", package = "rbmi"); dat <- antidepressant_data
dat <- expand_locf(dat, PATIENT = levels(dat$PATIENT), VISIT = levels(dat$VISIT), vars = c("BASVAL", "THERAPY"), group = c("PATIENT"), order = c("PATIENT", "VISIT"))
dat <- as.data.frame(dat); dat$CHANGE <- as.numeric(dat$CHANGE)
spec_dul <- stress_spec(dat, response = "CHANGE", subject = "PATIENT", visit = "VISIT", treatment = "THERAPY", reference = "PLACEBO",
                        covariates = ~ BASVAL, contrast_visit = "7", covariance = "us", method = "Satterthwaite", vcov = "Asymptotic", label = "HAMD-17 change at visit 7")
b <- stress_fit(spec_dul)
chk <- c(abs(b$estimate - (-2.872048)) < 1e-5, abs(b$stderr - 1.102845) < 1e-5, abs(b$p - 0.01011878) < 1e-7, b$n_subj == 172, b$n_obs == 608)
cat("duloxetine filed-analysis check (estimate, SE, p, participants, observations):", chk, "\n")
if (!all(chk)) stop("the duloxetine filed analysis differs from the expected values; stopping")
plan_dul <- standard_plan(spec_dul, baseline = "BASVAL", deltas = seq(0, 6, by = 1), m = 25, n_perm = 2000, max_k = 5)
s1 <- run_one("Duloxetine vs placebo (HAMD-17 change at visit 7)", "duloxetine", spec_dul, plan_dul)
# ---- ddI vs ddC ---------------------------------------------------------------------------------------------------------
data("aids", package = "JM")
base_cd4 <- aids |> filter(obstime == 0) |> select(patient, cd4_base = CD4)
aids_l <- aids |> filter(obstime > 0) |> inner_join(base_cd4, by = "patient") |>
  mutate(patient = factor(patient), visit = factor(obstime, levels = c(2, 6, 12, 18)), change = CD4 - cd4_base) |> as.data.frame()
spec_aids <- stress_spec(aids_l, "change", "patient", "visit", "drug", "ddC", covariates = ~ cd4_base + prevOI + AZT, contrast_visit = "12",
                         covariance = "us", method = "Satterthwaite", vcov = "Asymptotic", label = "CD4 change (square-root scale) at 12 months")
plan_aids <- standard_plan(spec_aids, baseline = "cd4_base", deltas = seq(0, -2, by = -0.5), m = 25, n_perm = 2000, max_k = 5)
s2 <- run_one("Didanosine vs zalcitabine (CD4 change, square-root scale, at 12 months)", "aids", spec_aids, plan_aids, direction = TRUE)
summ <- rbind(s1, s2); write.csv(summ, file.path(RESULTS, "public_trials_summary.csv"), row.names = FALSE); print(t(summ))
log_footer("job3_public_trials", t0)
