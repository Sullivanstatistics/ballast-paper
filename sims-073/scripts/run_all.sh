#!/bin/bash
# The 0.7.3 runs, in order: Job 3 (public trials), Job 4 (Figure 2 and S1 trials), Job 6 (duloxetine specification grid),
# Figures 2, 4, S1, S2, S3, Figure 5 copied from the 0.7.2 run (it does not depend on the 0.7.3 change), then Job 5
# (Study 2 at 400 trials per cell, the long job) and Figure 3 from its summary. Each step is logged to logs/<job>.log and
# the run stops at the first failure (recorded in logs/run_all.log). Job 5 saves each cell as it finishes and skips saved
# cells on a rerun, so an interrupted run resumes from the last complete cell.
# Environment: SIMS070_ROOT (this folder), SIMS070_VALIDATION, SIMS070_PREVIOUS (the 070 folder), SIMS070_CORES,
# SIMS070_PKG_COMMIT (the tagged commit).
#   cd <this folder>; SIMS070_CORES=8 SIMS070_PKG_COMMIT=<hash> bash scripts/run_all.sh
set -uo pipefail
cd "$(dirname "$0")/.."
export SIMS070_ROOT="${SIMS070_ROOT:-$(pwd)}"
export SIMS070_PREVIOUS="${SIMS070_PREVIOUS:-$(cd .. && pwd)/sims-070}"
export SIMS070_CORES="${SIMS070_CORES:-8}"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
mkdir -p logs figures results
log() { echo "[$(date '+%F %T')] $*" | tee -a logs/run_all.log; }
run() { local job=$1; shift; log "$job starting"; Rscript "$@" > "logs/$job.log" 2>&1; local s=$?; log "$job finished with status $s ($(grep -o 'elapsed [0-9.]* min' "logs/$job.log" | tail -1))"; [ $s -eq 0 ] || { log "$job FAILED; stopping; see logs/$job.log"; exit 1; }; }
log "run_all on $(hostname): ballast $(Rscript -e 'cat(as.character(packageVersion("ballast")))') commit ${SIMS070_PKG_COMMIT:-unset}, $(Rscript -e 'cat(R.version.string)'), $SIMS070_CORES workers; previous run $SIMS070_PREVIOUS"
run job3_public_trials scripts/job3_public_trials.R "$SIMS070_CORES"
run job4_trials scripts/job4_trials.R "$SIMS070_CORES"
run job6_spec_grid scripts/job6_spec_grid.R "$SIMS070_CORES"
for f in fig02_three_swarms fig04_duloxetine figS1_broken_trials figS2_spec_curve figS3_spec_swarm; do run "$f" "figures/$f.R"; done
for ext in pdf png; do cp "$SIMS070_PREVIOUS/figures/fig05_design.$ext" figures/; done
cp "$SIMS070_PREVIOUS/figures/fig05_design_values.csv" "$SIMS070_PREVIOUS/figures/fig05_design.R" figures/; cp "$SIMS070_PREVIOUS/logs/fig05_design.log" logs/
log "fig05_design copied unchanged from the 0.7.2 run (does not depend on the 0.7.3 change)"
run job5_study2 scripts/job5_study2.R 400 "$SIMS070_CORES"
run fig03_sim_verdicts figures/fig03_sim_verdicts.R
log "ALL JOBS DONE"
