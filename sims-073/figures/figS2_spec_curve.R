## Figure S2: the duloxetine specification grid of Job 6 in the specification-curve layout of Simonsohn, Simmons and Nelson.
## Top panel: the 42 estimates sorted from smallest to largest with their 95% intervals, the pre-specified estimate marked
## (diamond) and a line at zero. Bottom panel: the specification indicators, one row per setting, a dot in the row of each
## setting a specification uses, aligned under its estimate. Reads results/spec_grid.csv. PDF and PNG, 7 in wide, no title.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })
t0 <- log_header("figS2_spec_curve")
x <- read.csv(file.path(RESULTS, "spec_grid.csv"), stringsAsFactors = FALSE); x <- x[x$converged, ]
x <- x[order(x$estimate), ]; x$rank <- seq_len(nrow(x))
x$what <- ifelse(x$pre_specified, "Pre-specified analysis", ifelse(x$crossed, "Crosses 0.05", "Other specification"))
cols <- c("Pre-specified analysis" = "#1e3a66", "Crosses 0.05" = "#e8873a", "Other specification" = "#2a78d6")
top <- ggplot(x, aes(x = rank, y = estimate)) +
  geom_hline(yintercept = 0, colour = "grey20", linewidth = 0.7) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = x$lcl[x$pre_specified][1], ymax = x$ucl[x$pre_specified][1], fill = "#e6eaf3", alpha = 0.7) +
  geom_errorbar(aes(ymin = lcl, ymax = ucl, colour = what), width = 0, linewidth = 0.5, alpha = 0.8) +
  geom_point(aes(colour = what, shape = what), size = 2.2) +
  scale_colour_manual(values = cols, name = NULL) + scale_shape_manual(values = c("Pre-specified analysis" = 18, "Crosses 0.05" = 16, "Other specification" = 16), name = NULL) +
  scale_x_continuous(breaks = NULL, expand = expansion(add = 0.8)) +
  labs(x = NULL, y = "Treatment difference (95% interval)") + theme_minimal(base_size = 10) +
  theme(legend.position = "top", panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(), plot.background = element_rect(fill = "white", colour = NA))
# indicator rows: covariance (7), inference (3), covariates (2)
ind <- rbind(data.frame(rank = x$rank, block = "Covariance", setting = x$covariance), data.frame(rank = x$rank, block = "Degrees of freedom", setting = x$inference),
             data.frame(rank = x$rank, block = "Covariates", setting = x$covariates))
lv <- c("us", "ar1h", "ar1", "cs", "csh", "toep", "toeph", "Satterthwaite", "Kenward-Roger (linear)", "Sandwich, between-within", "baseline in", "baseline out")
ind$setting <- factor(ind$setting, levels = rev(lv)); ind$block <- factor(ind$block, levels = c("Covariance", "Degrees of freedom", "Covariates"))
bottom <- ggplot(ind, aes(x = rank, y = setting)) + geom_point(size = 1.4, colour = "#1e3a66") +
  facet_grid(block ~ ., scales = "free_y", space = "free_y", switch = "y") +
  scale_x_continuous(breaks = NULL, expand = expansion(add = 0.8)) + labs(x = "Specifications, sorted by estimate", y = NULL) + theme_minimal(base_size = 10) +
  theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0, face = "bold", size = 8, hjust = 1), panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        axis.text.y = element_text(size = 7.5), plot.background = element_rect(fill = "white", colour = NA))
g <- top / bottom + plot_layout(heights = c(1.3, 1))
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("figS2_spec_curve.", ext)), g, width = 7, height = 6.5, dpi = 300, bg = "white")
cat(sprintf("%d specifications drawn; %d cross 0.05; pre-specified rank %d of %d\n", nrow(x), sum(x$crossed & !x$pre_specified), x$rank[x$pre_specified], nrow(x)))
log_footer("figS2_spec_curve", t0)
