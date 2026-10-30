#!/bin/bash
# Job 9 (defect trials) on the EC2 server, 30 workers, ballast 0.7.3 at 28be8fb10383
# (Robustness/2026-10-25_paper_methods/HANDOFF_defect_trials.md). Started in a tmux session. Each cell is saved when it
# finishes and skipped on a rerun. Logs: logs/job9_defect_trials.log (appended per invocation), logs/run_server.log.
#   bash scripts/run_job9_server.sh [cells, comma-separated, default all]
# Companion repository: the original absolute server paths are redacted; the paths below follow the repository layout.
cd "$(dirname "$0")/.." || exit 1
export SIMS070_ROOT="$PWD" SIMS070_PREVIOUS="$PWD/../sims-070" SIMS070_VALIDATION="$PWD/.."
export SIMS070_CORES=30 SIMS070_PKG_COMMIT=28be8fb10383 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
CELLS="${1:-all}"
log() { echo "[$(date -u '+%F %T') UTC] $*" | tee -a logs/run_server.log; }
log "job9_defect_trials starting on $(hostname): cells $CELLS, ballast $(Rscript -e 'cat(as.character(packageVersion("ballast")))') commit $SIMS070_PKG_COMMIT, $SIMS070_CORES workers"
Rscript scripts/job9_defect_trials.R "$CELLS" 200 "$SIMS070_CORES" >> logs/job9_defect_trials.log 2>&1; s=$?
log "job9_defect_trials finished with status $s ($(grep -o 'elapsed [0-9.]* min' logs/job9_defect_trials.log | tail -1))"
