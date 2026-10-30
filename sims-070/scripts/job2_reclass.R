## Job 2: Studies 2 and 3 reclassified from the saved 0.6.0 rows (no simulation). Reads validation/simulation/sim2_rows.csv
## and sim3_rows.csv (read only) and recomputes the verdict under the 0.7.1 rule: fragile if outside_ci (outside_ci_all for
## Study 3) is greater than zero; otherwise sensitive if crossed (crossed_all) is greater than zero; otherwise robust.
## Marginal is unchanged. Writes results/study2_reclass.csv and study3_reclass.csv with the 0.6.0 label and the recomputed
## one, summaries by scenario with the 0.6.0 summary columns, and the label changes by direction and significance.
## Run: Rscript scripts/job2_reclass.R
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
t0 <- log_header("job2_reclass")
SIM <- file.path(VALIDATION, "simulation")
relabel <- function(outside, crossed) ifelse(outside > 0, "fragile", ifelse(crossed > 0, "sensitive", "robust"))
changes <- function(x, old, new, label) {
  ch <- x[x[[old]] != x[[new]], ]
  cat(sprintf("\n%s: %d of %d trials change label\n", label, nrow(ch), nrow(x)))
  if (nrow(ch)) print(as.data.frame(table(from = ch[[old]], to = ch[[new]], significant = ch$significant)), row.names = FALSE)
  sig_changed <- sum(x$significant & x[[old]] != x[[new]])
  cat(sprintf("significant trials that change label: %d\n", sig_changed))
  data.frame(study = label, trials = nrow(x), changed = nrow(ch), changed_significant = sig_changed,
             nonsig_reversed_to_robust_or_sensitive = sum(!x$significant & x[[old]] == "fragile" & x[[new]] != "fragile"))
}
# ---- Study 2 ----------------------------------------------------------------------------------------------------------
s2 <- read.csv(file.path(SIM, "sim2_rows.csv"), stringsAsFactors = FALSE)
s2$stability_060 <- s2$stability; s2$stability_071 <- relabel(s2$outside_ci, s2$crossed)
write.csv(s2, file.path(RESULTS, "study2_reclass.csv"), row.names = FALSE)
summ2 <- do.call(rbind, lapply(split(s2, list(s2$design, s2$power), drop = TRUE), function(g) data.frame(
  design = g$design[1], power_target = g$power[1], trials = nrow(g), power_observed = mean(g$significant), marginal = mean(g$marginal),
  robust = mean(g$stability_071 == "robust"), sensitive = mean(g$stability_071 == "sensitive"), fragile = mean(g$stability_071 == "fragile"),
  sensitive_given_sig = if (any(g$significant)) mean(g$stability_071[g$significant] == "sensitive") else NA, fragile_given_sig = if (any(g$significant)) mean(g$stability_071[g$significant] == "fragile") else NA,
  frag_reached_given_sig = if (any(g$significant)) mean(!is.na(g$frag_k[g$significant])) else NA, median_max_shift_se = median(g$max_shift_se), failed = mean(g$n_failed > 0),
  fragile_060 = mean(g$stability_060 == "fragile"), fragile_given_sig_060 = if (any(g$significant)) mean(g$stability_060[g$significant] == "fragile") else NA)))
summ2 <- summ2[order(summ2$design, summ2$power_target), ]
write.csv(summ2, file.path(RESULTS, "study2_reclass_summary.csv"), row.names = FALSE)
c2 <- changes(s2, "stability_060", "stability_071", "Study 2")
# ---- Study 3 ----------------------------------------------------------------------------------------------------------
s3 <- read.csv(file.path(SIM, "sim3_rows.csv"), stringsAsFactors = FALSE)
s3$stability_all_060 <- s3$stability_all; s3$stability_all_071 <- relabel(s3$outside_ci_all, s3$crossed_all)
s3$stability_light_060 <- s3$stability_light
write.csv(s3, file.path(RESULTS, "study3_reclass.csv"), row.names = FALSE)
summ3 <- do.call(rbind, lapply(split(s3, list(s3$mnar, s3$power), drop = TRUE), function(g) { s <- g$significant; ns <- sum(s); cond <- function(z) if (ns) mean(z[s], na.rm = TRUE) else NA_real_
  data.frame(mnar = g$mnar[1], power_target = g$power[1], trials = nrow(g), n_sig = ns, power_observed = mean(s),
             sensitive_light_given_sig = cond(g$stability_light == "sensitive"), sensitive_all_given_sig = cond(g$stability_all_071 == "sensitive"),
             fragile_all_given_sig = cond(g$stability_all_071 == "fragile"), marginal_given_sig = cond(g$marginal),
             crossed_by_ref_only_given_sig = cond(g$crossed_ref > 0 & g$crossed_light == 0), crossed_by_ref_given_sig = cond(g$crossed_ref > 0),
             crossed_by_loo_given_sig = cond(g$crossed_loo > 0), crossed_by_model_given_sig = cond(g$crossed_model > 0),
             median_tipping_margin = median(g$tipping_margin, na.rm = TRUE), tipping_absorbed_given_sig = cond(!is.na(g$tipping_margin) & g$tipping_margin > 0),
             median_ref_spread_se = median((g$ref_max - g$ref_min) / g$base_se, na.rm = TRUE), median_max_shift_light = median(g$max_shift_light), median_max_shift_all = median(g$max_shift_all),
             fragile_all = mean(g$stability_all_071 == "fragile"), failed = mean(g$n_failed > 0),
             fragile_all_060 = mean(g$stability_all_060 == "fragile"), fragile_all_given_sig_060 = cond(g$stability_all_060 == "fragile")) }))
summ3 <- summ3[order(summ3$mnar, summ3$power_target), ]
write.csv(summ3, file.path(RESULTS, "study3_reclass_summary.csv"), row.names = FALSE)
c3 <- changes(s3, "stability_all_060", "stability_all_071", "Study 3 (all families)")
write.csv(rbind(c2, c3), file.path(RESULTS, "reclass_changes.csv"), row.names = FALSE)
cat("\nExpectation: changes confined to non-significant trials whose estimate reversed inside the interval; no significant trial changes.\n")
if (c2$changed_significant + c3$changed_significant > 0) cat("A SIGNIFICANT TRIAL CHANGED LABEL: record this in README.md; do not explain it away.\n")
log_footer("job2_reclass", t0)
