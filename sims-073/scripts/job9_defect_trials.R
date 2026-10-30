## Job 9: trials whose significance rests on a defect (Robustness/2026-10-25_paper_methods/HANDOFF_defect_trials.md).
## Generators in scripts/job9_generators.R; sizes chosen by the pilot (scripts/job9_pilot.R, results/defect_pilot.csv) on
## the filed analysis alone. Per trial: the Study 1 light family set (covariance us/ar1h/cs, three inference methods,
## covariate set, LS-mean weighting, leave-one-subject-out, greedy fragility search for significance with max 3 removals),
## plus leave-one-site-out and the J2R and CR reference-based refits at 25 imputations (seed = the trial seed). The
## covariate family is baseline out for A to C (filed model with baseline) and baseline in for D (filed model without).
## 200 trials per cell, seeds 90000 + 1000 k + i for cell number k and trial i. Each cell is saved to
## results/defect_chunks/<cell>.rds when it finishes, and a rerun skips saved cells, so cells can be added later.
## Run: Rscript scripts/job9_defect_trials.R <cells, comma-separated, or "all"> [n_trials] [cores]
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "job9_generators.R"))
## B cells added 29 Oct 2026 after the redesign (scripts/job9_pilot_B.R, results/defect_pilot_B.csv): a real effect at
## planned power about 0.3 (delta 4.38 at 25 per arm, 3.10 at 50 per arm) with one outlier at k = 5 and 8 residual SDs
## (25 per arm) and two at k = 8 (50 per arm). For A, C and D delta is the planted effect only (A: at site 1; C, D: 0).
delta_B <- function(n) (qnorm(0.975) + qnorm(0.3)) * 10.3 * sqrt(2 / (n * 0.97^3))
CELLS <- data.frame(
  cell = c("A40", "A80", "A200", "C30", "C45", "D06", "D09", "B25k5", "B25k8", "B50x2k8"),
  k    = 1:10,
  mech = c("A", "A", "A", "C", "C", "D", "D", "B", "B", "B"),
  size = c(40, 80, 200, 0.30, 0.45, 0.6, 0.9, 5, 8, 8),
  n_per_arm = c(rep(50L, 7), 25L, 25L, 50L), n_outliers = c(rep(1L, 9), 2L),
  delta = c(rep(0, 7), delta_B(25), delta_B(25), delta_B(50)), stringsAsFactors = FALSE)
args <- commandArgs(trailingOnly = TRUE)
want <- if (length(args) >= 1 && args[1] != "all") strsplit(args[1], ",")[[1]] else CELLS$cell
NTRIAL <- if (length(args) >= 2) as.integer(args[2]) else 200L
if (length(args) >= 3) CORES <- as.integer(args[3])
if (!all(want %in% CELLS$cell)) stop("unknown cell: ", paste(setdiff(want, CELLS$cell), collapse = ", "))
t0 <- log_header("job9_defect_trials")
CHUNKS <- file.path(RESULTS, if (NTRIAL == 200L) "defect_chunks" else sprintf("defect_chunks_n%d", NTRIAL)); dir.create(CHUNKS, showWarnings = FALSE)

one <- function(job) {
  d <- make_trial(job$mech, job$size, job$seed, job$n_per_arm, job$n_outliers, job$delta)
  spec <- make_spec(d, job$mech)
  base <- stress_fit(spec); if (!base$converged) return(NULL)
  rows <- list(stress_covariance(spec, c("us", "ar1h", "cs")),
               stress_inference(spec, default_inference()[c("Satterthwaite", "Kenward-Roger (linear)", "Sandwich, between-within")]),
               if (job$mech == "D") stress_covariates(spec, sets = list("with base" = ~ base)) else stress_covariates(spec),
               stress_weights(spec), stress_loo(spec), stress_loo(spec, by = "site"),
               stress_reference(spec, methods = c("J2R", "CR"), m = 25, seed = job$seed))
  rows <- rows[!vapply(rows, is.null, TRUE)]
  cen <- do.call(stress_census, c(list(spec = spec), rows, list(base = base))); v <- stress_verdict(cen)
  fr <- attr(stress_fragility(spec, "significance", max_k = 3), "fragility")
  x <- as.data.frame(cen); key <- paste(x$family, x$label, sep = ": ")
  pl <- planted_rows(d, job$mech, job$n_outliers); pkey <- paste(pl$rows$family, pl$rows$label, sep = ": ")
  cnt <- x$counted & !is.na(x$estimate); is_pl <- key %in% pkey
  outside <- cnt & !x$inside_ci; crossed <- cnt & x$crossed %in% TRUE
  alt <- x[x$counted & x$kind == "alternative", ]; del <- x[x$counted & x$kind == "deletion", ]
  row <- data.frame(cell = job$cell, mech = job$mech, size = job$size, n_per_arm = job$n_per_arm, n_outliers = job$n_outliers, delta = job$delta,
             seed = job$seed, n_subj = base$n_subj, base_est = base$estimate, base_se = base$stderr, base_p = base$p,
             significant = base$p < 0.05, stability = v$stability, marginal = v$marginal, rule = v$rule,
             crossed = v$n_crossed, outside_ci = v$n_outside_ci, reversed = v$n_reversed,
             n_alt = nrow(alt), alt_crossed = sum(alt$crossed, na.rm = TRUE), n_del = nrow(del), del_crossed = sum(del$crossed, na.rm = TRUE),
             max_shift_se = v$max_shift_se, pct_min = min(x$pct_of_base[x$counted], na.rm = TRUE), pct_max = max(x$pct_of_base[x$counted], na.rm = TRUE),
             frag_k = if (fr$reached) fr$k else NA_integer_, n_failed = sum(!x$converged),
             planted = paste(pkey, collapse = "; "), planted_gap = unname(pl$gap), planted_found = all(pkey %in% key[cnt]),
             planted_outside = any(outside & is_pl), planted_crossed = any(crossed & is_pl), other_outside = any(outside & !is_pl),
             other_crossed = any(crossed & !is_pl), n_outside_planted = sum(outside & is_pl), n_outside_other = sum(outside & !is_pl),
             outside_rows = paste(key[outside], collapse = "; "), crossed_rows = paste(key[crossed], collapse = "; "),
             stringsAsFactors = FALSE)
  long <- data.frame(cell = job$cell, seed = job$seed, family = x$family, label = x$label, kind = x$kind, counted = x$counted, converged = x$converged,
                     estimate = x$estimate, stderr = x$stderr, p = x$p, crossed = x$crossed, inside_ci = x$inside_ci, shift_se = x$shift_se,
                     planted = is_pl, stringsAsFactors = FALSE)
  list(row = row, long = long)
}

for (cc in want) {
  ce <- CELLS[CELLS$cell == cc, ]; out <- file.path(CHUNKS, paste0(cc, ".rds"))
  if (file.exists(out)) { cat(sprintf("cell %s already saved (%s); skipped\n", cc, out)); next }
  t1 <- Sys.time()
  jobs <- lapply(seq_len(NTRIAL), function(i) c(as.list(ce), seed = 90000L + 1000L * ce$k + i))
  cl <- parallel::makeCluster(CORES); invisible(parallel::clusterEvalQ(cl, { suppressPackageStartupMessages(library(ballast)); NULL }))
  parallel::clusterExport(cl, c("one", "make_trial", "make_spec", "plant_mnar", "planted_rows", "BETA_D"))
  res <- parallel::parLapplyLB(cl, jobs, function(j) tryCatch(one(j), error = function(e) structure(list(error = conditionMessage(e)), class = "job_error")))
  parallel::stopCluster(cl)
  bad <- vapply(res, function(r) is.null(r) || inherits(r, "job_error"), TRUE)
  errs <- vapply(res[bad], function(r) if (is.null(r)) "filed analysis did not converge" else r$error, "")
  rows <- do.call(rbind, lapply(res[!bad], `[[`, "row")); long <- do.call(rbind, lapply(res[!bad], `[[`, "long"))
  rows$ballast <- as.character(packageVersion("ballast")); rows$commit <- ballast_commit()
  saveRDS(list(rows = rows, long = long, failed_seeds = vapply(jobs, `[[`, 0, "seed")[bad], failed_reasons = errs), out)
  s <- rows[rows$significant, ]
  cat(sprintf("cell %s (mechanism %s, size %s, %d per arm): %d trials, %d failed%s; %d significant; among them fragile %d, sensitive %d, robust %d; planted row outside %d, crossed %d; other row outside %d; %.1f min\n",
              cc, ce$mech, ce$size, ce$n_per_arm, nrow(rows), sum(bad), if (any(bad)) paste0(" (", paste(unique(errs), collapse = " | "), ")") else "",
              nrow(s), sum(s$stability == "fragile"), sum(s$stability == "sensitive"), sum(s$stability == "robust"),
              sum(s$planted_outside), sum(s$planted_crossed), sum(s$other_outside), as.numeric(difftime(Sys.time(), t1, units = "mins"))))
}
log_footer("job9_defect_trials", t0)
