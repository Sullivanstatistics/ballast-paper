#!/bin/bash
# Jobs 7 and 8 and Figure S4 on the EC2 server, 30 workers, ballast 0.7.3 at 28be8fb10383
# (Robustness/2026-10-25_paper_methods/HANDOFF_null_example.md). Started in a tmux session so it survives the SSH
# connection. Each step stops the run if it fails. Logs: logs/job7_null.log, logs/job8_chance_finding.log,
# logs/figS4_chance_finding.log, logs/run_server.log in the 073 folder.
# SIMS070_ROOT may be set to another folder for a trial run (default: the 073 folder).
# Companion repository: the original absolute server paths are redacted; the paths below follow the repository layout.
cd "$(dirname "$0")/.." || exit 1
export SIMS070_ROOT="${SIMS070_ROOT:-$PWD}" SIMS070_PREVIOUS="$PWD/../sims-070" SIMS070_VALIDATION="$PWD/.."
export SIMS070_CORES=30 SIMS070_PKG_COMMIT=28be8fb10383 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
NTRIAL="${1:-2000}"
L="$SIMS070_ROOT/logs"; mkdir -p "$L" "$SIMS070_ROOT/results" "$SIMS070_ROOT/figures"
log() { echo "[$(date -u '+%F %T') UTC] $*" | tee -a "$L/run_server.log"; }
run() { local job=$1; shift; log "$job starting"; Rscript "$@" > "$L/$job.log" 2>&1; local s=$?
  log "$job finished with status $s ($(grep -o 'elapsed [0-9.]* min' "$L/$job.log" | tail -1))"; [ $s -eq 0 ] || { log "$job FAILED; stopping; see logs/$job.log"; exit 1; }; }
log "server run (Jobs 7, 8, S4) on $(hostname): ballast $(Rscript -e 'cat(as.character(packageVersion("ballast")))') commit $SIMS070_PKG_COMMIT, $(Rscript -e 'cat(R.version.string)'), $SIMS070_CORES workers, $NTRIAL null trials, root $SIMS070_ROOT"
run job7_null scripts/job7_null.R "$NTRIAL" "$SIMS070_CORES"
run job8_chance_finding scripts/job8_chance_finding.R "$SIMS070_CORES"
run figS4_chance_finding figures/figS4_chance_finding.R
log "SERVER RUN DONE (Jobs 7, 8, S4)"
