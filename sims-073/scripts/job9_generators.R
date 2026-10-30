## Job 9 generators and the per-trial stress test, shared by scripts/job9_pilot.R and scripts/job9_defect_trials.R
## (Robustness/2026-10-25_paper_methods/HANDOFF_defect_trials.md). The package is not changed: mechanisms A and B use
## simulate_rare_trial() as it is; C and D post-process its output. Every trial uses the homogeneous population (no
## progression heterogeneity), 8 sites, AR(1) errors with rho 0.6 and SD 10, MAR dropout 0.03 per visit and no treatment
## effect except the planted defect, so the two arms share one outcome distribution apart from it. Arms: REF and ACT.
##  A  one site carries the effect: defect = "site", delta = size at site 1 only, zero at the other seven.
##  B  one or two patients carry the effect: defect = "outlier", n_outliers ACT patients shifted up by size residual SDs
##     at every visit. Redesigned 29 Oct 2026 (Adam's decision, after scripts/job9_pilot.R showed a null trial with one
##     or two outliers is almost never significant): the outliers sit on top of a small real effect delta, planned power
##     about 0.3 (scripts/job9_pilot_B.R), so the arms do not share one distribution in B.
##  C  the missing-data assumption carries the effect: delta 0; afterwards the ACT patients with the lowest mean residual
##     at visits 3 and 4 (y - 0.5 (base - 50), the values about to be lost) lose visits 3 and 4 (they leave after
##     visit 2), size x n_per_arm of them; a random 15% x n_per_arm of REF patients leave after visit 2 as well.
##  D  an omitted covariate carries the effect: delta 0, baseline_beta 0.98 (baseline correlation about 0.7 with the
##     visit-4 outcome); afterwards every ACT patient's baseline is raised by size baseline SDs (10 points) and every
##     outcome by 0.98 x that, as an unlucky allocation would; the filed model omits baseline.
BETA_D <- 0.98
plant_mnar <- function(d, rate, n_per_arm, seed, ref_rate = 0.15, beta = 0.5) {
  arm_of <- tapply(d$arm, d$id, `[`, 1)
  late <- d[d$visit %in% c("V3", "V4"), ]; r <- tapply(late$y - beta * (late$base - 50), late$id, mean)
  act <- names(r)[arm_of[names(r)] == "ACT"]; ref <- names(r)[arm_of[names(r)] == "REF"]
  drop_act <- act[order(r[act])][seq_len(min(length(act), round(rate * n_per_arm)))]
  set.seed(seed + 500000L); drop_ref <- sample(ref, min(length(ref), round(ref_rate * n_per_arm)))
  d <- d[!(d$id %in% c(drop_act, drop_ref) & d$visit %in% c("V3", "V4")), ]; rownames(d) <- NULL
  attr(d, "dropped_act") <- drop_act; attr(d, "dropped_ref") <- drop_ref
  d
}
make_trial <- function(mech, size, seed, n_per_arm = 50L, n_outliers = 1L, delta = 0) {
  sim <- function(...) simulate_rare_trial(n_per_arm = n_per_arm, population = "homogeneous", seed = seed, ...)
  d <- switch(mech,
    A = sim(delta = size, defect = "site"),
    B = sim(delta = delta, defect = "outlier", n_outliers = n_outliers, outlier_size = size),
    C = plant_mnar(sim(delta = 0), size, n_per_arm, seed),
    D = { d <- sim(delta = 0, baseline_beta = BETA_D); a <- d$arm == "ACT"; d$base[a] <- d$base[a] + size * 10; d$y[a] <- d$y[a] + BETA_D * size * 10; d },
    stop("unknown mechanism ", mech))
  d
}
make_spec <- function(d, mech) stress_spec(d, "y", "id", "visit", "arm", "REF", covariates = if (mech == "D") NULL else ~ base,
                                           contrast_visit = "V4", covariance = "us", method = "Satterthwaite", vcov = "Asymptotic")
## The planted rows (family, label) of a trial. For B the outliers are found from the data: the n_outliers ACT patients
## with the largest mean residual y - 0.5 (base - 50); gap is the ratio of the smallest of them to the next largest
## (recorded so that an ambiguous identification would show).
planted_rows <- function(d, mech, n_outliers = 1L) {
  switch(mech,
    A = list(rows = data.frame(family = "leave-one-out: site", label = "site1"), gap = NA_real_),
    B = { r <- sort(tapply(d$y - 0.5 * (d$base - 50), d$id, mean)[unique(d$id[d$arm == "ACT"])], decreasing = TRUE)
          list(rows = data.frame(family = "leave-one-out: subject", label = names(r)[seq_len(n_outliers)]), gap = r[n_outliers] / r[n_outliers + 1]) },
    C = list(rows = data.frame(family = "reference-based multiple imputation", label = c("J2R", "CR")), gap = NA_real_),
    D = list(rows = data.frame(family = "covariate set", label = "with base"), gap = NA_real_))
}
