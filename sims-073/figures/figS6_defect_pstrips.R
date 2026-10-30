## Figure S6: the leave-one-out p-strips of the four Figure S5 trials (drawn because in Figure S5 the planted deletion is
## not identifiable among the deletion dots in B, and in A only by its position). One strip per deletion family (sites and
## subjects), the filed p as the diamond and alpha dashed; in A and B the planted deletion is ringed and labelled. In C
## and D the planted rows are alternatives (the reference-based and covariate refits, visible in Figure S5), so their
## strips show only that no deletion carries the result. Reads results/defect_figure_trials.rds. PDF and PNG, 7 in wide.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })
t0 <- log_header("figS6_defect_pstrips")
ft <- readRDS(file.path(RESULTS, "defect_figure_trials.rds"))
panel <- function(m) {
  f <- ft[[m]]; cl <- list(f$census); names(cl) <- f$cell
  g <- plot_pstrip(cl, label_family = TRUE); g$coordinates$clip <- "off"
  # fix the jitter seed so every build (the one below that finds the planted dot, and the one ggsave() makes) places the
  # dots in the same positions; otherwise the ring is drawn where the dot was in a different build
  for (i in seq_along(g$layers)) if (inherits(g$layers[[i]]$position, "PositionJitter")) g$layers[[i]]$position$seed <- 20261029L
  x <- as.data.frame(f$census); pl <- merge(f$planted, x, by = c("family", "label"))
  pl <- pl[pl$kind == "deletion", ]
  if (nrow(pl)) {   # find the drawn position of each planted deletion in the built plot (the strip's jitter is in the build)
    b <- ggplot2::ggplot_build(g); pos <- do.call(rbind, lapply(b$data, function(z) if (all(c("x", "y") %in% names(z))) z[, c("x", "y")] else NULL))
    hit <- do.call(rbind, lapply(pl$p, function(pp) { k <- which(abs(pos$x - pp) < 1e-10); if (length(k)) pos[k[1], ] else NULL }))
    if (is.null(hit) || nrow(hit) != nrow(pl)) stop("panel ", m, ": could not find every planted deletion among the drawn points")
    g <- g + annotate("point", x = hit$x, y = hit$y, shape = 21, size = 4.5, stroke = 1.1, colour = "black", fill = NA) +
      annotate("text", x = hit$x, y = hit$y, label = "planted", vjust = -1.3, size = 3)
    cat(sprintf("%s: planted deletion(s) %s at p %s\n", m, paste(pl$label, collapse = ", "), paste(signif(pl$p, 3), collapse = ", ")))
  }
  g
}
p <- lapply(c("A", "B", "C", "D"), panel)
g <- wrap_elements(full = p[[1]]) / wrap_elements(full = p[[2]]) / wrap_elements(full = p[[3]]) / wrap_elements(full = p[[4]]) +
  plot_layout(heights = c(1.4, 1, 1.4, 1.4)) + plot_annotation(tag_levels = "A")
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("figS6_defect_pstrips.", ext)), g, width = 7, height = 9, dpi = 300, bg = "white")
log_footer("figS6_defect_pstrips", t0)
