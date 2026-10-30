## Job 9, the four Figure S5 trials: one per mechanism at the larger defect size (A80, B25k8, C45, D09; A200 is in the
## summary but the figure uses A80, Adam's choice), each the significant trial whose filed p is nearest the cell's median
## filed p among significant trials (ties within 1e-9 to the lower seed). Each is regenerated from its seed and refitted
## under the Job 9 family set (as one() in scripts/job9_defect_trials.R), and its census is checked against the saved
## census rows of that trial (results/defect_chunks/<cell>.rds) before anything is saved.
## Output: results/defect_figure_trials.rds (per mechanism: cell, seed, data, census, verdict, planted rows),
## results/defect_figure_trials.csv (the chosen trials' filed numbers, label and planted-row results).
## Run: Rscript scripts/job9_figure_trials.R [cores]
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "job9_generators.R"))
t0 <- log_header("job9_figure_trials")
FIG_CELLS <- c(A = "A80", B = "B25k8", C = "C45", D = "D09")
out <- list(); tab <- list()
for (mech in names(FIG_CELLS)) {
  cc <- FIG_CELLS[[mech]]; ch <- readRDS(file.path(RESULTS, "defect_chunks", paste0(cc, ".rds"))); r <- ch$rows; s <- r[r$significant, ]
  med <- median(s$base_p); dd <- abs(s$base_p - med); cand <- s[dd <= min(dd) + 1e-9, ]; pick <- cand[which.min(cand$seed), ]
  cat(sprintf("%s (%s): %d significant, median filed p %.4f; chosen seed %d, p %.4f, %s\n", mech, cc, nrow(s), med, pick$seed, pick$base_p, pick$stability))
  delta <- if ("delta" %in% names(pick)) pick$delta else 0
  d <- make_trial(mech, pick$size, pick$seed, pick$n_per_arm, pick$n_outliers, delta); spec <- make_spec(d, mech); base <- stress_fit(spec)
  rows <- list(stress_covariance(spec, c("us", "ar1h", "cs")),
               stress_inference(spec, default_inference()[c("Satterthwaite", "Kenward-Roger (linear)", "Sandwich, between-within")]),
               if (mech == "D") stress_covariates(spec, sets = list("with base" = ~ base)) else stress_covariates(spec),
               stress_weights(spec), stress_loo(spec), stress_loo(spec, by = "site"),
               stress_reference(spec, methods = c("J2R", "CR"), m = 25, seed = pick$seed))
  rows <- rows[!vapply(rows, is.null, TRUE)]
  cen <- do.call(stress_census, c(list(spec = spec), rows, list(base = base))); v <- stress_verdict(cen)
  saved <- ch$long[ch$long$seed == pick$seed, ]; x <- as.data.frame(cen)
  m <- merge(saved, x[, c("family", "label", "estimate", "p")], by = c("family", "label"), suffixes = c("_saved", "_now"))
  ok <- nrow(m) == nrow(saved) && nrow(saved) == nrow(x) && isTRUE(all.equal(m$estimate_saved, m$estimate_now, tolerance = 1e-8)) &&
        isTRUE(all.equal(m$p_saved, m$p_now, tolerance = 1e-8)) && v$stability == pick$stability
  cat(sprintf("   regenerated census matches the saved rows (%d rows) and the label: %s\n", nrow(x), ok))
  if (!ok) stop("the regenerated census of ", cc, " seed ", pick$seed, " differs from the saved rows; stopping")
  pl <- planted_rows(d, mech, pick$n_outliers)$rows
  out[[mech]] <- list(cell = cc, seed = pick$seed, data = d, census = cen, verdict = v, planted = pl)
  tab[[mech]] <- data.frame(mech = mech, cell = cc, seed = pick$seed, cell_median_p = med, estimate = base$estimate, se = base$stderr, lcl = base$lcl, ucl = base$ucl,
                            p = base$p, verdict = v$stability, marginal = v$marginal, max_shift_se = v$max_shift_se, planted = pick$planted,
                            planted_outside = pick$planted_outside, planted_crossed = pick$planted_crossed, other_outside = pick$other_outside,
                            outside_rows = pick$outside_rows, crossed_rows = pick$crossed_rows, stringsAsFactors = FALSE)
}
saveRDS(out, file.path(RESULTS, "defect_figure_trials.rds"))
tab <- do.call(rbind, tab); write.csv(tab, file.path(RESULTS, "defect_figure_trials.csv"), row.names = FALSE); print(t(tab), quote = FALSE)
log_footer("job9_figure_trials", t0)
