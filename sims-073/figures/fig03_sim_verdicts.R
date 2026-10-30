## Figure 3 (0.7.3 redraw): sensitive and fragile shares among significant trials against planned power, with Monte Carlo
## error bars (sqrt(p (1 - p) / n_sig)) on the share panel. Study 1 from the 0.7.2 run (SIMS070_PREVIOUS/results/
## study1_summary.csv, 200 trials per power, unchanged) and the Study 2 designs from Job 5 (results/study2_400_summary.csv,
## 400 trials per cell at planned power 0.8 and 0.95) as small multiples; bottom row: the median largest shift in filed SEs.
## PDF and PNG, 7 in wide.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages(library(ggplot2))
t0 <- log_header("fig03_sim_verdicts")
s1 <- read.csv(file.path(PREVIOUS, "results", "study1_summary.csv")); s2 <- read.csv(file.path(RESULTS, "study2_400_summary.csv"))
mcse <- function(p, n) ifelse(n > 0, sqrt(p * (1 - p) / n), NA_real_)
n1 <- round(s1$trials * s1$power_observed)
d1 <- data.frame(design = "Study 1: base, 50 per arm", power = s1$power_target, n_sig = n1, sensitive = s1$sensitive_given_sig, sensitive_mcse = mcse(s1$sensitive_given_sig, n1),
                 fragile = s1$fragile_given_sig, fragile_mcse = mcse(s1$fragile_given_sig, n1), shift = s1$median_max_shift_se)
short <- c(base2 = "Study 2: base", heavy = "Study 2: heavy tails", hetero = "Study 2: unequal variances", mnar = "Study 2: MNAR dropout", interact = "Study 2: effect modification")
d2 <- data.frame(design = unname(short[s2$design]), power = s2$power_target, n_sig = s2$n_significant, sensitive = s2$sensitive_given_sig, sensitive_mcse = s2$sensitive_given_sig_mcse,
                 fragile = s2$fragile_given_sig, fragile_mcse = s2$fragile_given_sig_mcse, shift = s2$median_max_shift_se)
d <- rbind(d1, d2); d$design <- factor(d$design, levels = unique(c(d1$design, unname(short))))
long <- rbind(data.frame(d[, c("design", "power", "n_sig")], panel = "Share of significant results", what = "sensitive", value = d$sensitive, mcse = d$sensitive_mcse),
              data.frame(d[, c("design", "power", "n_sig")], panel = "Share of significant results", what = "fragile", value = d$fragile, mcse = d$fragile_mcse),
              data.frame(d[, c("design", "power", "n_sig")], panel = "Median largest shift (filed SEs)", what = "shift", value = d$shift, mcse = NA_real_))
long <- long[!is.na(long$value), ]; long$panel <- factor(long$panel, levels = c("Share of significant results", "Median largest shift (filed SEs)"))
g <- ggplot(long, aes(x = power, y = value, colour = what, group = what)) +
  geom_errorbar(data = long[!is.na(long$mcse), ], aes(ymin = pmax(0, value - mcse), ymax = pmin(1, value + mcse)), width = 0.04, linewidth = 0.5, alpha = 0.8) +
  geom_line(linewidth = 0.9) + geom_point(size = 2) +
  facet_grid(panel ~ design, scales = "free_y", switch = "y", labeller = label_wrap_gen(16)) +
  scale_colour_manual(values = c(sensitive = "#e8873a", fragile = "#1e3a66", shift = "#2a78d6"), name = NULL, breaks = c("sensitive", "fragile"), labels = c("sensitive (bars: Monte Carlo SE)", "fragile")) +
  scale_x_continuous(breaks = c(0, 0.5, 0.8, 0.95), labels = c("0", ".5", ".8", ".95"), expand = expansion(mult = 0.08)) +
  labs(x = "Planned power of the pre-specified analysis", y = NULL) + theme_minimal(base_size = 10) +
  theme(strip.placement = "outside", strip.text.x = element_text(hjust = 0, face = "bold", size = 7.5), axis.text.x = element_text(size = 7), panel.grid.minor = element_blank(), legend.position = "bottom",
        plot.background = element_rect(fill = "white", colour = NA))
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("fig03_sim_verdicts.", ext)), g, width = 7, height = 4.8, dpi = 300, bg = "white")
write.csv(long, file.path(FIGURES, "fig03_sim_verdicts_values.csv"), row.names = FALSE)
log_footer("fig03_sim_verdicts", t0)
