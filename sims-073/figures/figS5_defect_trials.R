## Figure S5: one trial per defect mechanism at the larger defect size (A one site carries the effect, delta 80; B one
## patient at +8 residual SD on a small real effect, 25 per arm; C MNAR dropout of 45% of the active arm; D baseline
## omitted after an allocation imbalance of 0.9 SD), each the significant trial nearest its cell's median filed p
## (scripts/job9_figure_trials.R). Four swarms in a two-by-two layout with the filed estimate and interval as the axis,
## no titles inside the panels, panel labels A to D outside, one legend. The planted rows are drawn as the package draws
## them: the site and subject deletions among the deletion dots, the reference-based and covariate rows among the
## alternatives. Reads results/defect_figure_trials.rds. PDF and PNG, 7 in wide, 300 dpi.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })
t0 <- log_header("figS5_defect_trials")
ft <- readRDS(file.path(RESULTS, "defect_figure_trials.rds"))
panel <- function(m) { cl <- list(ft[[m]]$census); names(cl) <- ft[[m]]$cell
  g <- plot_swarm(cl, xlab = "Treatment difference at visit 4") + theme(strip.text = element_blank(), plot.margin = margin(4, 8, 4, 4))
  list(g = g, caption = attr(g, "caption")) }
p <- lapply(c("A", "B", "C", "D"), panel)
g <- (p[[1]]$g + p[[2]]$g) / (p[[3]]$g + p[[4]]$g) + plot_layout(guides = "collect") + plot_annotation(tag_levels = "A") & theme(legend.position = "bottom")
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("figS5_defect_trials.", ext)), g, width = 7, height = 7, dpi = 300, bg = "white")
cap <- vapply(c("A", "B", "C", "D"), function(m) sprintf("%s. %s (seed %d): %s", m, ft[[m]]$cell, ft[[m]]$seed, p[[match(m, c("A", "B", "C", "D"))]]$caption), "")
writeLines(cap, file.path(FIGURES, "figS5_defect_trials_caption.txt")); cat(cap, sep = "\n")
log_footer("figS5_defect_trials", t0)
