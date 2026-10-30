#!/bin/bash
# Run Jobs 1 to 5 in order, each logged to logs/<job>.log, stopping at the first failure (recorded in logs/run_all.log).
# Environment: SIMS070_ROOT (this folder), SIMS070_VALIDATION, SIMS070_CORES, SIMS070_PKG_COMMIT (the tagged commit).
#   cd <this folder>; SIMS070_CORES=30 SIMS070_PKG_COMMIT=<hash> bash scripts/run_all.sh
set -uo pipefail
cd "$(dirname "$0")/.."
export SIMS070_ROOT="${SIMS070_ROOT:-$(pwd)}"
export SIMS070_CORES="${SIMS070_CORES:-8}"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
mkdir -p logs
log() { echo "[$(date '+%F %T')] $*" | tee -a logs/run_all.log; }
run() { local job=$1; shift; log "$job starting"; Rscript "$@" > "logs/$job.log" 2>&1; local s=$?; log "$job finished with status $s ($(grep -o 'elapsed [0-9.]* min' "logs/$job.log" | tail -1))"; [ $s -eq 0 ] || { log "$job FAILED; stopping; see logs/$job.log"; exit 1; }; }
log "run_all on $(hostname): ballast $(Rscript -e 'cat(as.character(packageVersion("ballast")))') commit ${SIMS070_PKG_COMMIT:-unset}, $(Rscript -e 'cat(R.version.string)'), $SIMS070_CORES workers"
run job1_study1 scripts/job1_study1.R 200 "$SIMS070_CORES"
run job2_reclass scripts/job2_reclass.R
run job3_public_trials scripts/job3_public_trials.R "$SIMS070_CORES"
run job4_trials scripts/job4_trials.R "$SIMS070_CORES"
for f in fig02_three_swarms fig03_sim_verdicts fig04_duloxetine fig05_design figS1_broken_trials; do run "$f" "figures/$f.R"; done
log "ALL JOBS DONE"
