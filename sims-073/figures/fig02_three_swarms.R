## Figure 2: the display on three Study 1 trials side by side (no effect, mild effect, strong effect), each a swarm with the
## filed interval as the axis and the deletions beneath. Reads results/fig02_trials_results.rds (Job 4). PDF and PNG, 7 in wide.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages(library(ggplot2))
t0 <- log_header("fig02_three_swarms")
res <- readRDS(file.path(RESULTS, "fig02_trials_results.rds"))
g <- plot_swarm(res, xlab = "Treatment difference at visit 4 (filed estimate and 95% interval as the axis)")
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("fig02_three_swarms.", ext)), g, width = 7, height = 7.5, dpi = 300, bg = "white")
writeLines(attr(g, "caption"), file.path(FIGURES, "fig02_three_swarms_caption.txt")); cat(attr(g, "caption"), sep = "\n")
log_footer("fig02_three_swarms", t0)
