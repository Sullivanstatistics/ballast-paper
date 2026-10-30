# Shared setup for the 2026-10-29-methods-sims-073 runs (the public trials, the Figure 2 and S1 trials and their figures
# under ballast 0.7.3; copied from 2026-10-29-methods-sims-070/scripts/setup.R). Every script sources this file first.
# Paths come from the environment or default to the folder layout relative to this file, so the same scripts run on the
# laptop and on the server. Nothing is hardcoded to a OneDrive path.
#   SIMS070_ROOT        the output folder (default: the parent of scripts/)
#   SIMS070_VALIDATION  the read-only 0.6.0 results folder validation/ (default: the repository root, which holds design/ and simulation/;
#                       in the companion repository this default replaces the original sibling-folder default)
#   SIMS070_PREVIOUS    the 0.7.2 run this one is compared with (default: ../sims-070); Job 4 reads its
#                       results/study1_rows.csv (Study 1 is not rerun) and Job 3 its results/public_trials_summary.csv
#   SIMS070_CORES       worker count (default 8)
#   SIMS070_PKG_COMMIT  the git commit of the installed ballast (recorded in every log; else read from the package git tree if present)
suppressPackageStartupMessages(library(ballast))
this_file <- function() { a <- commandArgs(); f <- sub("^--file=", "", a[grepl("^--file=", a)]); if (length(f)) normalizePath(f[1]) else normalizePath("scripts/setup.R") }
ROOT <- Sys.getenv("SIMS070_ROOT", normalizePath(file.path(dirname(this_file()), ".."), mustWork = FALSE))
VALIDATION <- Sys.getenv("SIMS070_VALIDATION", normalizePath(file.path(ROOT, ".."), mustWork = FALSE))
PREVIOUS <- Sys.getenv("SIMS070_PREVIOUS", normalizePath(file.path(ROOT, "..", "sims-070"), mustWork = FALSE))
CORES <- as.integer(Sys.getenv("SIMS070_CORES", "8"))
RESULTS <- file.path(ROOT, "results"); FIGURES <- file.path(ROOT, "figures"); LOGS <- file.path(ROOT, "logs")
for (d in c(RESULTS, FIGURES, LOGS)) dir.create(d, showWarnings = FALSE, recursive = TRUE)
if (!dir.exists(VALIDATION)) stop("the 0.6.0 validation folder was not found at ", VALIDATION, " (set SIMS070_VALIDATION)")
if (!dir.exists(file.path(PREVIOUS, "results"))) stop("the 0.7.2 run folder was not found at ", PREVIOUS, " (set SIMS070_PREVIOUS)")

# The package commit: from the installed package's description when the tarball recorded it, else from the git tree if present.
ballast_commit <- function() {
  if (nzchar(Sys.getenv("SIMS070_PKG_COMMIT"))) return(Sys.getenv("SIMS070_PKG_COMMIT"))   # the tagged commit, passed by the run command and recorded in README.md
  d <- utils::packageDescription("ballast")
  for (f in c("RemoteSha", "GithubSHA1", "Commit")) if (!is.null(d[[f]])) return(substr(d[[f]], 1, 12))
  g <- tryCatch(system2("git", c("-C", shQuote(Sys.getenv("SIMS070_PKG_GIT", file.path(ROOT, "..", "2026-10-16_pkg_ballast", "ballast"))), "rev-parse", "--short=12", "HEAD"), stdout = TRUE, stderr = FALSE), error = function(e) character())
  if (length(g)) g[1] else "unknown"
}
# Every log starts with the version, the commit, R, the platform and the worker count, and ends with the elapsed time.
log_header <- function(job) {
  cat(sprintf("==== %s: ballast %s (commit %s), %s, %s, %d workers, %s ====\n", job, as.character(utils::packageVersion("ballast")), ballast_commit(),
              R.version.string, paste(R.version$platform, Sys.info()[["sysname"]]), CORES, format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
  invisible(Sys.time())
}
log_footer <- function(job, t0) cat(sprintf("==== %s done: elapsed %.1f min ====\n", job, as.numeric(difftime(Sys.time(), t0, units = "mins"))))
REQUIRED_VERSION <- "0.7.3"
if (as.character(utils::packageVersion("ballast")) != REQUIRED_VERSION) stop("ballast ", REQUIRED_VERSION, " is required; installed: ", utils::packageVersion("ballast"))
