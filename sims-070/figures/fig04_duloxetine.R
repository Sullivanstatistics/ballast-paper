## Figure 4: duloxetine, two panels: the swarm (every refit against the filed interval) and the leave-one-out p-strip.
## Reads results/duloxetine/duloxetine_results.rds (Job 3). PDF and PNG, 7 in wide.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages(library(ggplot2))
t0 <- log_header("fig04_duloxetine")
res <- readRDS(file.path(RESULTS, "duloxetine", "duloxetine_results.rds"))
ga <- plot_swarm(list("Duloxetine vs placebo: HAMD-17 change at visit 7" = res), xlab = "Treatment difference (filed estimate and 95% interval as the axis)") + guides(colour = guide_legend(nrow = 2, override.aes = list(size = 3, alpha = 1)))
gb <- plot_pstrip(list("Duloxetine" = res), label_family = FALSE) + labs(x = "p-value with one participant removed")
if (requireNamespace("patchwork", quietly = TRUE)) {
  g <- patchwork::wrap_plots(ga, gb, ncol = 1, heights = c(1.3, 1)) + patchwork::plot_annotation(tag_levels = "A")
  for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("fig04_duloxetine.", ext)), g, width = 7, height = 7, dpi = 300, bg = "white")
} else {
  for (ext in c("pdf", "png")) { ggsave(file.path(FIGURES, paste0("fig04_duloxetine_A.", ext)), ga, width = 7, height = 4, dpi = 300, bg = "white"); ggsave(file.path(FIGURES, paste0("fig04_duloxetine_B.", ext)), gb, width = 7, height = 3, dpi = 300, bg = "white") }
}
writeLines(attr(ga, "caption"), file.path(FIGURES, "fig04_duloxetine_caption.txt"))
log_footer("fig04_duloxetine", t0)
