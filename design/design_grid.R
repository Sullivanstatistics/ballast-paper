## Design-stage illustration for the paper: the design of Table 4, whose effect is a publicly reported primary estimate (effect 4.55 at the last visit, residual SD 10, AR(1) 0.6,
## four visits, 3% dropout per visit, ARH(1) + Satterthwaite as the pre-specified model) over a grid of sample sizes.
## Run A: light families with leave-one-subject-out, 100 trials per cell, delta 0 and 4.55, n 50 .. 200 per arm.
## Run B: tipping grid (m = 5, shifts 0 .. 3 x delta) on n = 50 and 100, delta 4.55, 50 trials, no deletions.
## Rscript design_grid.R [cores]
args <- commandArgs(trailingOnly = TRUE); CORES <- if (length(args)) as.integer(args[1]) else 8L
suppressPackageStartupMessages(library(ballast))
here <- getwd()   # run from this folder; the original absolute path is redacted in the companion repository
t0 <- Sys.time()
A <- stress_design(n_per_arm = c(50, 75, 100, 150, 200), delta = c(0, 4.55), n_trials = 100, n_visits = 4, sigma = 10, rho = 0.6, dropout = 0.03,
                   covariance = "ar1h", method = "Satterthwaite", vcov = "Asymptotic", alternatives = c("us", "ar1h", "cs"), loo = TRUE, cores = CORES, seed = 2026)
print(A); cat("run A elapsed", format(round(difftime(Sys.time(), t0, units = "mins"), 1)), "\n")
saveRDS(A, file.path(here, "design_A.rds")); write.csv(as.data.frame(A), file.path(here, "design_A.csv"), row.names = FALSE)
write.csv(attr(A, "trials"), file.path(here, "design_A_trials.csv"), row.names = FALSE)
if (requireNamespace("ggplot2", quietly = TRUE) && requireNamespace("ragg", quietly = TRUE)) {
  g <- plot(A); ragg::agg_png(file.path(here, "fig_design_A.png"), width = 9, height = 4.2, units = "in", res = 150, background = "white"); print(g); dev.off()
}
t1 <- Sys.time()
B <- stress_design(n_per_arm = c(50, 100), delta = 4.55, n_trials = 50, n_visits = 4, sigma = 10, rho = 0.6, dropout = 0.03,
                   covariance = "ar1h", method = "Satterthwaite", vcov = "Asymptotic", loo = FALSE, tipping = TRUE, shifts = seq(0, 3, by = 0.5), m = 5, cores = CORES, seed = 3026)
print(B); cat("run B elapsed", format(round(difftime(Sys.time(), t1, units = "mins"), 1)), "\n")
saveRDS(B, file.path(here, "design_B.rds")); write.csv(as.data.frame(B), file.path(here, "design_B.csv"), row.names = FALSE)
write.csv(attr(B, "trials"), file.path(here, "design_B_trials.csv"), row.names = FALSE)
cat("total elapsed", format(round(difftime(Sys.time(), t0, units = "mins"), 1)), "\n")
