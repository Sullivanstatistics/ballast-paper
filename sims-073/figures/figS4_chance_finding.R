## Figure S4: one chance finding on the display (Job 8). Two panels stacked: the swarm with the filed estimate and interval
## as the axis, and the leave-one-out p-strip against alpha. The handoff's third panel, the leave-one-site-out rows, is
## dropped: the Study 1 generator has no site variable, so the trial has no site rows to draw.
## Reads results/chance_finding/chance_finding_results.rds. PDF and PNG, 7 in wide, 300 dpi, no titles inside the figure.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })
t0 <- log_header("figS4_chance_finding")
res <- readRDS(file.path(RESULTS, "chance_finding", "chance_finding_results.rds"))
cl <- list(res); names(cl) <- "Chance finding (no effect, filed p near 0.03)"
g1 <- plot_swarm(cl, xlab = "Treatment difference at visit 4 (filed estimate and 95% interval as the axis)")
g2 <- plot_pstrip(list(`One participant removed` = res), label_family = FALSE)
g2$coordinates$clip <- "off"   # plot_pstrip() places the alpha label at the panel edge, where it is clipped in a short panel
# wrap_elements() keeps patchwork from aligning the two plotting areas (the p-strip's row label would push the swarm right);
# no panel tags (they sat on the swarm's title): the caption refers to the top and bottom panels
g <- wrap_elements(full = g1) / wrap_elements(full = g2) + plot_layout(heights = c(3, 1.5))
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("figS4_chance_finding.", ext)), g, width = 7, height = 7.5, dpi = 300, bg = "white")
writeLines(attr(g1, "caption"), file.path(FIGURES, "figS4_chance_finding_caption.txt")); cat(attr(g1, "caption"), sep = "\n")
log_footer("figS4_chance_finding", t0)
