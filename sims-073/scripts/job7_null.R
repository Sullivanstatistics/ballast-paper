## Job 7: null-only simulation at the Study 1 design (Robustness/2026-10-25_paper_methods/HANDOFF_null_example.md).
## Copied from the 070 folder's scripts/job1_study1.R (the Study 1 rerun): same generator, same design (50 per arm, four
## post-baseline visits, MAR dropout), same light family set (covariance us/ar1h/cs, three inference methods, covariate set,
## LS-mean weighting, leave-one-subject-out, greedy fragility search for significance with max 3 removals), planned power 0
## only (delta 0), 2,000 trials. Seeds 1000 + i for trial i, the Study 1 null-cell sequence: trials 1 to 200 use the Study 1
## seeds 1001 to 1200 and must reproduce the power-0 rows of study1_rows.csv in the 0.7.2 run; trials 201 to 2,000 extend
## the sequence to seeds 1201 to 3000. Seeds 2001 to 2200 are also the Study 1 power-0.5 seeds; with delta 0 those trials
## reuse that cell's random draws without the effect, so they are not independent of it (they are independent of each
## other and of every other Job 7 trial).
## Per-trial rows have the Job 1 columns (results/null_rows.csv). The script then checks trials 1 to 200 against
## SIMS070_PREVIOUS/results/study1_rows.csv (numbers within 1e-6 relative, labels and counts exact) and stops before any
## summary if they differ. Summary (results/null_summary.csv): over the significant trials and over all trials, the shares
## labelled robust, sensitive and fragile, flagged marginal, losing significance with one removal and within three (for
## the all-trials row these two are the shares whose significance status flips with one and within three removals), and
## the median largest shift in filed SEs, each share with its Monte Carlo standard error sqrt(p (1 - p) / n).
## Run: Rscript scripts/job7_null.R [n_trials] [cores]      Output: results/null_rows.csv, results/null_check200.csv, results/null_summary.csv
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
args <- commandArgs(trailingOnly = TRUE)
NTRIAL <- if (length(args) >= 1) as.integer(args[1]) else 2000L
if (length(args) >= 2) CORES <- as.integer(args[2])
t0 <- log_header("job7_null")
# the Study 1 design and generator, verbatim from job1_study1.R
N_ARM <- 50; NV <- 4; SIGMA <- 10; RHO <- 0.6; DROP <- 0.08
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
# one trial, verbatim from job1_study1.R
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
jobs <- lapply(seq_len(NTRIAL), function(i) list(power = 0, delta = 0, seed = 1000L + i))
cat(sprintf("%d null trials (planned power 0, delta 0), seeds %d to %d, on %d workers\n", NTRIAL, 1001L, 1000L + NTRIAL, CORES))
cl <- parallel::makeCluster(CORES); parallel::clusterEvalQ(cl, { suppressPackageStartupMessages(library(ballast)); NULL })
parallel::clusterExport(cl, c("sim_trial", "one", "N_ARM", "NV", "SIGMA", "RHO", "DROP"))
res <- parallel::parLapplyLB(cl, jobs, function(j) tryCatch(one(j), error = function(e) NULL)); parallel::stopCluster(cl)
failed_seeds <- vapply(jobs, `[[`, 0, "seed")[vapply(res, is.null, TRUE)]; failed <- length(failed_seeds)
res <- do.call(rbind, res[!vapply(res, is.null, TRUE)])
cat(sprintf("%d trials returned, %d failed (not converged or error)%s\n", nrow(res), failed, if (failed) paste0(": seeds ", paste(failed_seeds, collapse = ", ")) else ""))
res$ballast <- as.character(packageVersion("ballast")); res$commit <- ballast_commit()
write.csv(res, file.path(RESULTS, "null_rows.csv"), row.names = FALSE)
cat(sprintf("rows saved: %s (%.1f min so far)\n", file.path(RESULTS, "null_rows.csv"), as.numeric(difftime(Sys.time(), t0, units = "mins"))))

# ---- trials 1 to 200 against the Study 1 null cell of the 0.7.2 run ---------------------------------------------------
s1 <- read.csv(file.path(PREVIOUS, "results", "study1_rows.csv"), stringsAsFactors = FALSE); s1 <- s1[s1$power == 0, ]
cat(sprintf("Study 1 null cell: %d rows, seeds %d to %d (%s)\n", nrow(s1), min(s1$seed), max(s1$seed), file.path(PREVIOUS, "results", "study1_rows.csv")))
mine <- res[res$seed %in% s1$seed, ]
num <- c("delta", "base_est", "base_se", "base_p", "max_shift_se", "pct_min", "pct_max")
exact <- c("n_subj", "significant", "stability", "marginal", "rule", "crossed", "outside_ci", "reversed", "n_alt", "alt_crossed", "n_del", "del_crossed", "frag_k", "n_failed")
chk <- do.call(rbind, lapply(s1$seed, function(sd) { a <- s1[s1$seed == sd, ]; b <- mine[mine$seed == sd, ]
  if (nrow(b) != 1) return(data.frame(seed = sd, present = FALSE, numbers_match = FALSE, labels_match = FALSE, max_rel_diff = NA_real_, differing = "missing in Job 7"))
  rel <- vapply(num, function(cn) { x <- a[[cn]]; y <- b[[cn]]; if (is.na(x) && is.na(y)) 0 else abs(x - y) / max(1, abs(x)) }, 0)
  ex <- vapply(exact, function(cn) identical(as.character(a[[cn]]), as.character(b[[cn]])), TRUE)
  data.frame(seed = sd, present = TRUE, numbers_match = all(rel < 1e-6), labels_match = all(ex), max_rel_diff = max(rel),
             differing = paste(c(num[rel >= 1e-6], exact[!ex]), collapse = "; ")) }))
write.csv(chk, file.path(RESULTS, "null_check200.csv"), row.names = FALSE)
ok <- all(chk$present & chk$numbers_match & chk$labels_match)
cat(sprintf("check of trials 1 to 200: %d of %d present, %d match in every number (largest relative difference %.2e) and every label and count\n",
            sum(chk$present), nrow(chk), sum(chk$present & chk$numbers_match & chk$labels_match), max(chk$max_rel_diff, na.rm = TRUE)))
if (!ok) { print(chk[!(chk$present & chk$numbers_match & chk$labels_match), ], row.names = FALSE)
  stop("trials 1 to 200 do not reproduce the Study 1 null cell; stopping before any summary (rows kept in results/null_rows.csv, check in results/null_check200.csv)") }

# ---- summary ---------------------------------------------------------------------------------------------------------
share <- function(x, n) { p <- sum(x) / n; c(p, sqrt(p * (1 - p) / n)) }
summ_over <- function(g, over) { n <- nrow(g)
  s <- list(robust = g$stability == "robust", sensitive = g$stability == "sensitive", fragile = g$stability == "fragile", marginal = g$marginal %in% TRUE,
            k1 = g$frag_k %in% 1L, within3 = !is.na(g$frag_k))
  out <- data.frame(over = over, trials = NTRIAL, returned = nrow(res), failed = failed, n = n, significant = sum(g$significant))
  for (nm in names(s)) { v <- share(s[[nm]], n); out[[nm]] <- v[1]; out[[paste0(nm, "_mcse")]] <- v[2] }
  out$median_max_shift_se <- median(g$max_shift_se); out$outside_ci_any <- mean(g$outside_ci > 0); out$reversed_any <- mean(g$reversed > 0)
  out$median_alt_crossed <- median(g$alt_crossed); out$median_del_crossed <- median(g$del_crossed)
  out }
summ <- rbind(summ_over(res[res$significant, ], "significant trials"), summ_over(res, "all trials"))
t1e <- share(res$significant, nrow(res)); summ$type1_error <- t1e[1]; summ$type1_error_mcse <- t1e[2]
summ$ballast <- as.character(packageVersion("ballast")); summ$commit <- ballast_commit()
write.csv(summ, file.path(RESULTS, "null_summary.csv"), row.names = FALSE)
cat(sprintf("\ntype I error of the filed analysis: %d of %d significant, %.4f (MC SE %.4f)\n", sum(res$significant), nrow(res), t1e[1], t1e[2]))
print(t(summ), quote = FALSE)
log_footer("job7_null", t0)
