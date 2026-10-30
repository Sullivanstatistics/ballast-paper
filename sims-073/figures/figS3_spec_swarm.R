## Figure S3: the same 42 duloxetine specifications as Figure S2, drawn with plot_swarm() against the pre-specified estimate
## and its 95% interval as the axis, coloured as the swarm colours them (every grid row varies a statistical decision).
## Reads results/spec_grid_census.rds (Job 6). PDF and PNG, 7 in wide, no title.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages(library(ggplot2))
t0 <- log_header("figS3_spec_swarm")
cen <- readRDS(file.path(RESULTS, "spec_grid_census.rds"))
g <- plot_swarm(list("Duloxetine vs placebo: HAMD-17 change at visit 7, 42-specification grid" = cen), style = "dots", xlab = "Treatment difference (pre-specified estimate and 95% interval as the axis)") +
  theme(strip.text = element_blank())
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("figS3_spec_swarm.", ext)), g, width = 7, height = 3.6, dpi = 300, bg = "white")
writeLines(attr(g, "caption"), file.path(FIGURES, "figS3_spec_swarm_caption.txt")); cat(attr(g, "caption"), sep = "\n")
log_footer("figS3_spec_swarm", t0)
