## Figure S1: the two broken-trial swarms (one participant at +10 residual SD; the effect carried by one of eight sites),
## displays only. Reads results/broken_trials_results.rds (Job 4). PDF and PNG, 7 in wide.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages(library(ggplot2))
t0 <- log_header("figS1_broken_trials")
res <- readRDS(file.path(RESULTS, "broken_trials_results.rds"))
g <- plot_swarm(res, xlab = "Treatment difference at visit 4 (filed estimate and 95% interval as the axis)")
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("figS1_broken_trials.", ext)), g, width = 7, height = 5.5, dpi = 300, bg = "white")
writeLines(attr(g, "caption"), file.path(FIGURES, "figS1_broken_trials_caption.txt")); cat(attr(g, "caption"), sep = "\n")
log_footer("figS1_broken_trials", t0)
