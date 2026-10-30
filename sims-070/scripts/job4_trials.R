## Job 4: the Figure 2 trials and the broken-trial swarms.
##  Part 1. From the Study 1 generator and seeds (job1_study1.R), three complete trials, one each at planned power 0, 0.5 and
##    0.95: the trial whose filed p is closest to the median filed p of its scenario among significant trials (for power 0,
##    the median among all trials; ties, which always occur with an even count, go to the lower seed). standard_plan() on each, the three swarms side by side, the data frames saved as RDS.
##  Part 2. Two broken trials from simulate_rare_trial() (mixture population, 50 per arm): one participant at +10 residual SD,
##    and the effect carried by one of eight sites, each at an effect size giving a filed p near 0.03 (chosen by a short seed
##    scan recorded in the log). standard_plan() on each; swarm, p-strip and leave-one-site-out rows. Displays only.
## Needs results/study1_rows.csv (Job 1). Run: Rscript scripts/job4_trials.R [cores]
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "setup.R"))
suppressPackageStartupMessages(library(ggplot2))
args <- commandArgs(trailingOnly = TRUE); if (length(args) >= 1) CORES <- as.integer(args[1])
t0 <- log_header("job4_trials"); SEED <- 20261017
save_fig <- function(g, stem, w = 7, h = 4.5) { for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0(stem, ".", ext)), g, width = w, height = h, dpi = 300, bg = "white") }
# the Study 1 generator, verbatim from job1_study1.R
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
# ---- Part 1: three Study 1 trials ----------------------------------------------------------------------------------------
rows <- read.csv(file.path(RESULTS, "study1_rows.csv"), stringsAsFactors = FALSE)
## With an even number of trials the median is the midpoint of the two central p-values and both are equally close, so the
## tie goes to the lower seed (until 28 Oct 2026 which.min() broke it by floating-point noise, which differs between hosts).
pick <- function(pow) { g <- rows[rows$power == pow, ]; if (pow > 0) g <- g[g$significant, ]; med <- median(g$base_p); d <- abs(g$base_p - med); g <- g[d <= min(d) + 1e-9, ]; g[which.min(g$seed), ] }
chosen <- do.call(rbind, lapply(c(0, 0.5, 0.95), pick)); chosen$label <- c("No effect (planned power 0)", "Mild effect (planned power 0.5)", "Strong effect (planned power 0.95)")
cat("chosen trials (seed, filed p):\n"); print(chosen[, c("power", "seed", "base_p", "stability", "label")], row.names = FALSE)
results1 <- list(); trials1 <- list()
for (i in seq_len(nrow(chosen))) {
  d <- sim_trial(chosen$seed[i], chosen$delta[i]); d <- d[!is.na(d$y), ]; trials1[[chosen$label[i]]] <- d
  spec <- stress_spec(d, "y", "id", "visit", "arm", "PBO", covariates = ~ base, contrast_visit = "V4", covariance = "us", method = "Satterthwaite", vcov = "Asymptotic", label = chosen$label[i])
  res <- run_plan(standard_plan(spec, baseline = "base", deltas = seq(0, -6, by = -2), m = 25, n_perm = 2000, max_k = 5), cores = CORES, seed = SEED)
  cat(sprintf("%s: filed p %.4f, verdict %s, %.1f min\n", chosen$label[i], res$base$p, res$verdict$stability, as.numeric(res$elapsed)))
  results1[[chosen$label[i]]] <- res
}
saveRDS(trials1, file.path(RESULTS, "fig02_trials_data.rds")); saveRDS(results1, file.path(RESULTS, "fig02_trials_results.rds"))
write.csv(chosen, file.path(RESULTS, "fig02_trials_chosen.csv"), row.names = FALSE)
g2 <- plot_swarm(results1); save_fig(g2, "job4_three_swarms", w = 7, h = 7); cat(attr(g2, "caption"), sep = "\n")
# ---- Part 2: two broken trials -------------------------------------------------------------------------------------------
near_003 <- function(defect, deltas, seeds = 1:40) {   # the (delta, seed) whose filed p is closest to 0.03
  best <- NULL
  for (dl in deltas) for (s in seeds) {
    d <- simulate_rare_trial(50, delta = dl, population = "mixture", defect = defect, outlier_size = 10, seed = s)
    sp <- stress_spec(d, "y", "id", "visit", "arm", "REF", covariates = ~ base + fast, method = "Satterthwaite", vcov = "Asymptotic")
    b <- tryCatch(stress_fit(sp), error = function(e) NULL); if (is.null(b) || !isTRUE(b$converged)) next
    if (is.null(best) || abs(b$p - 0.03) < abs(best$p - 0.03)) best <- list(delta = dl, seed = s, p = b$p, data = d)
  }
  best
}
broken <- list(outlier = near_003("outlier", deltas = c(2, 3, 4, 5)), site = near_003("site", deltas = c(20, 30, 40)))
for (nm in names(broken)) cat(sprintf("broken trial %s: delta %s, seed %d, filed p %.4f\n", nm, broken[[nm]]$delta, broken[[nm]]$seed, broken[[nm]]$p))
results2 <- list()
for (nm in names(broken)) {
  d <- broken[[nm]]$data; lab <- if (nm == "outlier") "One participant at +10 residual SD" else "Effect carried by one of eight sites"
  spec <- stress_spec(d, "y", "id", "visit", "arm", "REF", covariates = ~ base + fast, method = "Satterthwaite", vcov = "Asymptotic", label = lab)
  res <- run_plan(standard_plan(spec, site = "site", baseline = "base", deltas = seq(0, -6, by = -2), m = 25, n_perm = 2000, max_k = 5), cores = CORES, seed = SEED)
  cat(sprintf("%s: filed p %.4f, verdict %s, %.1f min\n", lab, res$base$p, res$verdict$stability, as.numeric(res$elapsed))); results2[[lab]] <- res
}
saveRDS(lapply(broken, `[[`, "data"), file.path(RESULTS, "broken_trials_data.rds")); saveRDS(results2, file.path(RESULTS, "broken_trials_results.rds"))
write.csv(data.frame(trial = names(broken), delta = sapply(broken, `[[`, "delta"), seed = sapply(broken, `[[`, "seed"), filed_p = sapply(broken, `[[`, "p")), file.path(RESULTS, "broken_trials_chosen.csv"), row.names = FALSE)
gb <- plot_swarm(results2); save_fig(gb, "job4_broken_swarms", w = 7, h = 5.5); cat(attr(gb, "caption"), sep = "\n")
save_fig(plot_pstrip(results2, label_family = TRUE), "job4_broken_pstrip", h = 5)
site_rows <- do.call(rbind, lapply(names(results2), function(l) { x <- as.data.frame(results2[[l]]$census); x <- x[x$family == "leave-one-out: site", ]; cbind(trial = l, x[, c("label", "estimate", "lcl", "ucl", "p", "crossed", "inside_ci")]) }))
write.csv(site_rows, file.path(RESULTS, "broken_trials_site_rows.csv"), row.names = FALSE); print(site_rows, row.names = FALSE)
log_footer("job4_trials", t0)
