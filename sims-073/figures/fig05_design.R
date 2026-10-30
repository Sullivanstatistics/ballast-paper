## Figure 5: power and robustness power against n per arm for the design of Table 4, redrawn from the read-only
## validation/design/design_A.csv (0.6.0 run; the design grid's robustness power is P(significant and robust) and is
## unaffected by the reversal rule). PDF and PNG, 7 in wide.
source(file.path(dirname(sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])), "..", "scripts", "setup.R"))
suppressPackageStartupMessages(library(ggplot2))
t0 <- log_header("fig05_design")
A <- read.csv(file.path(VALIDATION, "design", "design_A.csv"))
cat("columns:", paste(names(A), collapse = " "), "\n")
pw <- grep("^power$|^power_", names(A), value = TRUE)[1]; rp <- grep("robust", names(A), value = TRUE)[1]
long <- rbind(data.frame(n_per_arm = A$n_per_arm, delta = A$delta, what = "Power (significant)", value = A[[pw]]),
              data.frame(n_per_arm = A$n_per_arm, delta = A$delta, what = "Robustness power (significant and robust)", value = A[[rp]]))
long <- long[long$delta > 0, ]
g <- ggplot(long, aes(x = n_per_arm, y = value, colour = what)) + geom_line(linewidth = 0.9) + geom_point(size = 2) +
  scale_colour_manual(values = c("#2a78d6", "#1e3a66"), name = NULL) + scale_y_continuous(limits = c(0, 1), labels = function(v) paste0(round(100 * v), "%")) +
  labs(x = "Participants per arm", y = NULL) + theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.background = element_rect(fill = "white", colour = NA))
for (ext in c("pdf", "png")) ggsave(file.path(FIGURES, paste0("fig05_design.", ext)), g, width = 7, height = 4, dpi = 300, bg = "white")
write.csv(long, file.path(FIGURES, "fig05_design_values.csv"), row.names = FALSE)
log_footer("fig05_design", t0)
