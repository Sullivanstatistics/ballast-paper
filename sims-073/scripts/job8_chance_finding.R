## Job 8: one chance finding on the display (Robustness/2026-10-25_paper_methods/HANDOFF_null_example.md).
## From the Job 7 rows (results/null_rows.csv) the significant trial whose filed p is nearest 0.03 (ties, should any occur,
## go to the lower seed, as in Job 4). The trial is regenerated from its seed with the Study 1 generator (delta 0), checked
## against its Job 7 row, and run through standard_plan() with the settings Job 4 uses for the Figure 2 trials (baseline
## "base", deltas 0 to -6 by 2, m 25, n_perm 2000, max_k 5, seed 20261017). The Study 1 generator has no site variable, so
## standard_plan() gets no site argument and there are no leave-one-site-out rows.
## Outputs in results/chance_finding/: the data frame (RDS), the results RDS, the census CSV, the log JSON, and
## chance_finding_summary.csv with the filed estimate, SE, p and label; counted alternatives and deletions; the crossing
## count and the families that crossed; outside-interval and reversal counts; the largest shift in filed SEs; the marginal
## flag; and the greedy count to lose significance.
## Run: Rscript scripts/job8_chance_finding.R [cores]
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
args <- commandArgs(trailingOnly = TRUE); if (length(args) >= 1) CORES <- as.integer(args[1])
t0 <- log_header("job8_chance_finding"); SEED <- 20261017
N_ARM <- 50; NV <- 4; SIGMA <- 10; RHO <- 0.6; DROP <- 0.08
sim_trial <- function(seed, delta) {   # the Study 1 generator, verbatim from job1_study1.R
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
rows <- read.csv(file.path(RESULTS, "null_rows.csv"), stringsAsFactors = FALSE)
sig <- rows[rows$significant, ]; d03 <- abs(sig$base_p - 0.03)
cand <- sig[d03 <= min(d03) + 1e-9, ]; pick <- cand[which.min(cand$seed), ]
cat(sprintf("%d significant of %d null trials; nearest filed p to 0.03: seed %d, p %.6f (%d tied within 1e-9)\n", nrow(sig), nrow(rows), pick$seed, pick$base_p, nrow(cand)))
nxt <- sig[order(d03), ][1:5, c("seed", "base_p", "stability", "marginal", "frag_k")]; cat("the five nearest:\n"); print(nxt, row.names = FALSE)
d <- sim_trial(pick$seed, 0); d <- d[!is.na(d$y), ]
lab <- "Chance finding (no effect, filed p near 0.03)"
spec <- stress_spec(d, "y", "id", "visit", "arm", "PBO", covariates = ~ base, contrast_visit = "V4", covariance = "us", method = "Satterthwaite", vcov = "Asymptotic", label = lab)
b <- stress_fit(spec)
chk <- c(estimate = abs(b$estimate - pick$base_est) < 1e-6 * max(1, abs(pick$base_est)), se = abs(b$stderr - pick$base_se) < 1e-6, p = abs(b$p - pick$base_p) < 1e-6, n_subj = b$n_subj == pick$n_subj)
cat("regenerated trial against its Job 7 row (estimate, SE, p, participants):", chk, "\n")
if (!all(chk)) stop("the regenerated trial does not match its Job 7 row; stopping")
plan <- standard_plan(spec, baseline = "base", deltas = seq(0, -6, by = -2), m = 25, n_perm = 2000, max_k = 5)
cat(stress_sap(plan, trial = lab), sep = "\n\n")
res <- run_plan(plan, cores = CORES, seed = SEED)
print(res$verdict); print(summary(res$census))
out <- file.path(RESULTS, "chance_finding"); dir.create(out, showWarnings = FALSE, recursive = TRUE)
saveRDS(d, file.path(out, "chance_finding_data.rds")); saveRDS(res, file.path(out, "chance_finding_results.rds"))
write.csv(as.data.frame(res$census), file.path(out, "chance_finding_census.csv"), row.names = FALSE)
stress_log(res, file.path(out, "chance_finding_log.json"))
x <- as.data.frame(res$census); cnt <- x[x$counted & !is.na(x$estimate), ]; crossed <- cnt[cnt$crossed %in% TRUE, ]
fr <- if (!is.null(res$rows$fragility)) attr(res$rows$fragility, "fragility") else NULL
v <- res$verdict
summ <- data.frame(seed = pick$seed, estimate = res$base$estimate, se = res$base$stderr, lcl = res$base$lcl, ucl = res$base$ucl, p = res$base$p,
                   n_subj = res$base$n_subj, n_obs = res$base$n_obs, verdict = v$stability, marginal = v$marginal, rule = v$rule,
                   counted_alternatives = sum(cnt$kind == "alternative"), counted_deletions = sum(cnt$kind == "deletion"),
                   diagnostic_rows = sum(x$kind == "diagnostic"), not_converged = sum(!x$converged),
                   crossed = nrow(crossed), crossed_alternatives = sum(crossed$kind == "alternative"), crossed_deletions = sum(crossed$kind == "deletion"),
                   crossed_families = paste(unique(crossed$family), collapse = "; "),
                   outside_ci = sum(!cnt$inside_ci), reversed = sum(!cnt$same_direction), max_shift_se = v$max_shift_se,
                   greedy_k_to_lose_significance = if (!is.null(fr) && fr$reached) fr$k else NA_integer_,
                   job7_stability = pick$stability, job7_marginal = pick$marginal, job7_frag_k = pick$frag_k,
                   elapsed_min = as.numeric(res$elapsed), ballast = as.character(packageVersion("ballast")), commit = ballast_commit(), stringsAsFactors = FALSE)
write.csv(summ, file.path(out, "chance_finding_summary.csv"), row.names = FALSE); print(t(summ), quote = FALSE)
if (nrow(crossed)) { cat("\ncounted rows that crossed alpha:\n"); print(crossed[, c("family", "label", "kind", "estimate", "p", "inside_ci", "shift_se")], row.names = FALSE) }
log_footer("job8_chance_finding", t0)
