# ballast-paper

This repository holds every script, seed, per-trial row, summary, figure and log behind the numbers and figures in "Stress-testing a pre-specified mixed model for repeated measures: the ballast package" by Adam J. Sullivan and Nathan Hogan, submitted to Statistics in Biopharmaceutical Research in November 2026. Every number the paper quotes from a run under the 0.7.x interval rule comes from ballast 0.7.3 at commit 28be8fb103839ddc214962d0c54800d2c8b610b0, except Study 1 and the reclassification of Studies 2 and 3, which come from ballast 0.7.2 at commit e883efff2773 (the two versions compute the same estimates, p-values, intervals and verdicts; 0.7.3 changes how the complete-case refit is counted and how the swarm legend is drawn). The design grid of Table 4 and the original 50-trial runs of Studies 2 and 3 come from ballast 0.6.0. The package is at https://github.com/Sullivanstatistics/ballast and is archived on Zenodo under the concept DOI 10.5281/zenodo.23427833. ballast 0.7.4 has been on CRAN since 31 October 2026 (https://CRAN.R-project.org/package=ballast, doi:10.32614/CRAN.package.ballast). It differs from 0.7.3 at 28be8fb only in documentation and figure formatting, so it gives the same numbers. A reader who wants the exact build the runs used installs that commit from GitHub, as below; a reader who wants the package installs it from CRAN with `install.packages("ballast")`. No data from the trial that prompted the work are in this repository: every data set here is simulated or comes from the public rbmi and JM packages.

This repository is archived on Zenodo under the concept DOI 10.5281/zenodo.23872111 (https://doi.org/10.5281/zenodo.23872111), which always resolves to the latest version. The submission version, release v1.0-submission, has the version DOI 10.5281/zenodo.23872112.

## Layout

| Folder | What it holds |
|---|---|
| sims-070/ | The ballast 0.7.2 runs: Study 1 (Job 1), the reclassification of the 0.6.0 Studies 2 and 3 under the interval rule (Job 2), and the first runs of Jobs 3 and 4. scripts/, results/, logs/, figures/ and the run README. |
| sims-073/ | The ballast 0.7.3 runs: the public trials (Job 3), the Figure 1 and S1 trials (Job 4), Study 2 at 400 trials per cell (Job 5), the duloxetine specification grid (Job 6), the null-only simulation (Job 7), the chance finding (Job 8) and the trials with planted defects (Job 9), with every figure script and figure. scripts/, results/, logs/, figures/ and the run README. |
| design/ | The design grid of Table 4 and Figure 4 (ballast 0.6.0): design_grid.R and its output design_A.csv. |
| simulation/ | The 0.6.0 runs of Studies 2 and 3 at 50 trials per cell (sim_verdicts2.R, sim_verdicts3.R, their per-trial rows and summaries), which Job 2 reclassifies and Job 5 checks its first 50 trials against. |
| realdata/ | The two earlier preparation scripts for the public trials (antidepressant.R, public_trials.R) and their logs, written on 24 October 2026 before the 0.7.x runs. Their logs do not record the package version. The numbers the paper quotes for the public trials come from sims-073 Job 3, not from these scripts. |
| public-trial-reports/ | A copy of sims-073/results/duloxetine and sims-073/results/aids: for each public trial the results object, census, report, tables and machine-readable log. |
| MANIFEST.csv | Path, size in bytes and MD5 of every other file in the repository. |

Left out on purpose: the per-cell chunk folders of Jobs 5 and 9 (the merged rows files carry the same rows), the log of the stopped laptop attempt at Job 5, and the preserved 0.7.1 server run of the 070 folder (its checksums stay in sims-070/logs/server_outputs.md5). Host names, user names, the server address and absolute paths have been redacted from the copied READMEs, logs and scripts and appear as `<laptop>`, `<server>`, `<redacted>` and `<tmp>`. The platform, R version, worker count and timing lines in each log are kept. The default folder paths in the two setup.R files, in sims-073/scripts/run_all.sh and in the two server run scripts were changed to the repository layout, and comments in design_grid.R and fig05_design.R that named the trial were reworded to refer to Table 4 (design_grid.R was renamed for the same reason); no computation was changed.

## How to reproduce

Install the package at the commit the runs record, plus the packages the scripts load:

```r
install.packages(c("remotes", "mmrm", "rbmi", "JM", "dplyr", "tidyr", "ggplot2", "patchwork", "ragg", "HSAUR3"))
remotes::install_github("Sullivanstatistics/ballast@28be8fb103839ddc214962d0c54800d2c8b610b0")   # for sims-073
# remotes::install_github("Sullivanstatistics/ballast@v0.7.2")                                   # for sims-070
```

The tag v0.7.3 now points at 184cb90, which differs from 28be8fb only in DESCRIPTION, NEWS.md and _pkgdown.yml, so installing at the tag gives the same R code. The runs used R 4.5.3 on a Windows 11 laptop (8 workers, mmrm 0.3.17) and R 4.6.1 on an Ubuntu 26.04.1 server with 32 vCPUs (30 workers, mmrm 0.3.19). Every script sources scripts/setup.R in its folder. setup.R refuses to run unless the installed ballast is the version that folder was run with (0.7.2 for sims-070, 0.7.3 for sims-073), and it prints the package version, the commit, R, the platform and the worker count at the top of every log and the elapsed time at the bottom. Pass the commit through SIMS070_PKG_COMMIT so the log records it; otherwise it reads "unknown" when the package was installed from a tarball. Folder paths default to the repository layout and can be overridden with SIMS070_ROOT, SIMS070_VALIDATION and SIMS070_PREVIOUS.

Run each job from its folder (`cd sims-073` or `cd sims-070`). The last argument is the worker count; the elapsed times are those in the logs.

| Job | Command | Host and workers | Elapsed |
|---|---|---|---|
| 1 Study 1 (0.7.2) | `SIMS070_PKG_COMMIT=e883efff2773 Rscript scripts/job1_study1.R 200 8` | laptop, 8 | 33.8 min |
| 2 Reclassification (0.7.2) | `Rscript scripts/job2_reclass.R` | laptop | seconds |
| 3 Public trials | `SIMS070_PKG_COMMIT=28be8fb10383 Rscript scripts/job3_public_trials.R 8` | laptop, 8 | 2.3 min |
| 4 Figure 1 and S1 trials | `SIMS070_PKG_COMMIT=28be8fb10383 Rscript scripts/job4_trials.R 8` | laptop, 8 | 2.5 min |
| 5 Study 2, 400 per cell | `SIMS070_PKG_COMMIT=28be8fb10383 Rscript scripts/job5_study2.R 400 30` | server, 30 | 132.5 min of cell time (11.0 to 17.2 min per cell) |
| 6 Specification grid | `SIMS070_PKG_COMMIT=28be8fb10383 Rscript scripts/job6_spec_grid.R 8` | laptop, 8 | seconds |
| 7 Null-only simulation | `SIMS070_PKG_COMMIT=28be8fb10383 Rscript scripts/job7_null.R 2000 30` | server, 30 | 18.0 min |
| 8 Chance finding | `SIMS070_PKG_COMMIT=28be8fb10383 Rscript scripts/job8_chance_finding.R 30` | server, 30 | 0.2 min |
| 9 pilots | `Rscript scripts/job9_pilot.R 30` and `Rscript scripts/job9_pilot_B.R 30` | server, 30 | seconds each |
| 9 Defect trials | `SIMS070_PKG_COMMIT=28be8fb10383 Rscript scripts/job9_defect_trials.R all 200 30`, then `Rscript scripts/job9_summary.R` and `Rscript scripts/job9_figure_trials.R 30` | server, 30 | 19.2 min (A, C, D cells) and 4.8 min (B cells) |
| Figures | `Rscript figures/<name>.R` for each figure script | either | seconds each |

sims-073/scripts/run_all.sh runs Jobs 3, 4, 6, the laptop figures, Job 5 and Figure 3 in order; run_job78_server.sh runs Jobs 7 and 8 and Figure S4; run_job9_server.sh runs Job 9 by cell. sims-070/scripts/run_all.sh runs Jobs 1 to 4 and the 0.7.2 figures. Job 3 is the quickest end-to-end check: it stops unless the duloxetine pre-specified analysis gives estimate -2.872048, SE 1.102845, p 0.01011878 with 172 participants and 608 observations, and unless the filed analyses, deletion counts and crossing counts of both trials match the 0.7.2 run in sims-070. Running a job overwrites its files in results/, figures/ and logs/; compare them with the committed copies or with MANIFEST.csv.

The design grid (design/design_grid.R) and the 0.6.0 Study 2 and 3 runs (simulation/) need ballast 0.6.0 and are run from their own folder.

## Where each table and figure comes from

The figure scripts and files keep their working names, which number the figures one higher than the manuscript does.

| Manuscript | Files |
|---|---|
| Table 2, validation gates | The validation vignette of the package (vignettes/validation.Rmd in ballast at 28be8fb); not in this repository |
| Table 3, Study 1 | sims-070/results/study1_summary.csv (per trial: study1_rows.csv; script job1_study1.R) |
| Table 3, Study 2 | sims-073/results/study2_400_summary.csv (per trial: study2_400_rows.csv; check against 0.6.0: study2_400_check50.csv; script job5_study2.R) |
| Table 3, Study 3 | sims-070/results/study3_reclass_summary.csv (per trial: study3_reclass.csv; label changes: reclass_changes.csv; script job2_reclass.R, input simulation/sim3_rows.csv) |
| Table 4 | design/design_A.csv (script design/design_grid.R, ballast 0.6.0) |
| Table 5 | sims-073/results/defect_trials_summary.csv (per trial: defect_trials_rows.csv; every refit of every trial: defect_trials_census.csv.gz; pilots: defect_pilot.csv, defect_pilot_B.csv; scripts job9_*.R) |
| Section 4.2, null paragraph | sims-073/results/null_summary.csv (per trial: null_rows.csv; check against Study 1: null_check200.csv) and sims-073/results/chance_finding/chance_finding_summary.csv |
| Section 5.1, duloxetine | public-trial-reports/duloxetine/, sims-073/results/public_trials_summary.csv, sims-073/results/spec_grid_summary.csv (grid: spec_grid.csv), sims-073/results/complete_case_rows.csv |
| Section 5.2, didanosine versus zalcitabine | public-trial-reports/aids/ (including aids_direction.rds), sims-073/results/public_trials_summary.csv, sims-073/results/complete_case_rows.csv |
| Figure 1 | sims-073/figures/fig02_three_swarms.R, .pdf, .png (trials: sims-073/results/fig02_trials_*) |
| Figure 2 | sims-073/figures/fig03_sim_verdicts.R, .pdf, .png, fig03_sim_verdicts_values.csv |
| Figure 3 | sims-073/figures/fig04_duloxetine.R, .pdf, .png |
| Figure 4 | sims-073/figures/fig05_design.R, .pdf, .png, fig05_design_values.csv |
| Figure S1 | sims-073/figures/figS1_broken_trials.R, .pdf, .png (trials: sims-073/results/broken_trials_*) |
| Figure S2 | sims-073/figures/figS2_spec_curve.R, .pdf, .png |
| Figure S3 | sims-073/figures/figS3_spec_swarm.R, .pdf, .png |
| Figure S4 | sims-073/figures/figS4_chance_finding.R, .pdf, .png |
| Figure S5 | sims-073/figures/figS5_defect_trials.R, .pdf, .png (trials: sims-073/results/defect_figure_trials.*) |
| Figure S6 | sims-073/figures/figS6_defect_pstrips.R, .pdf, .png |

Each figure has its log in logs/ and, where one was written, its caption in figures/*_caption.txt. Figure S4 was redrawn on 1 November 2026 with the facet label removed from inside the panel (one theme line in figS4_chance_finding.R); the data and every other element are unchanged, and its log is from the 29 October run.

## Seeds

Any single trial can be regenerated from its seed with the generator in the script named.

- Study 1 (sims-070/scripts/job1_study1.R): seed 1000 s + i, with s = 1, 2, 3, 4 for planned power 0, 0.5, 0.8, 0.95 and i = 1 to 200, the same scheme as at 0.6.0. The Figure 1 trials are seeds 1005 (power 0), 2006 (0.5) and 4137 (0.95): in each scenario, the trial whose filed p is closest to the median filed p (among significant trials for power 0.5 and 0.95, among all trials for power 0), ties going to the lower seed.
- Study 2 (simulation/sim_verdicts2.R at 0.6.0, sims-073/scripts/job5_study2.R at 0.7.3): seed 50000 + 1000 s + i, with s the row of the original 15-cell grid (power 0, 0.8, 0.95 within design base2, heavy, hetero, mnar, interact) and i the trial. Trials 1 to 50 of every cell reproduce the 0.6.0 run and trials 51 to 400 extend the sequence; i < 1000, so no seed is shared between cells.
- Study 3 (simulation/sim_verdicts3.R, 0.6.0): seed 70000 + 1000 s + i, with s the row of the grid of power 0, 0.8, 0.95 within MNAR 0, 1.
- Null-only simulation (Job 7): seed 1000 + i for i = 1 to 2,000. Trials 1 to 200 are the Study 1 null-cell seeds 1001 to 1200; seeds 2001 to 2200 are also the Study 1 power-0.5 seeds, so those 200 null trials reuse that cell's random draws without the effect.
- Chance finding (Job 8): seed 1510 of Job 7, the significant null trial whose filed p is nearest 0.03.
- Defect trials (Job 9): seed 90000 + 1000 k + i for cell number k (A40 1, A80 2, A200 3, C30 4, C45 5, D06 6, D09 7, B25k5 8, B25k8 9, B50x2k8 10) and trial i = 1 to 200. The reference-based refits use the trial seed. The figure trials are seeds 92166 (A80), 99107 (B25k8), 95151 (C45) and 97048 (D09).
- Broken trials of Figure S1 (Job 4): simulate_rare_trial() seeds searched over 1 to 40 for the filed p closest to 0.03; outlier at +10 residual SD, delta 3, seed 27; effect carried by one site, delta 40, seed 30.
- Stress tests: run_plan() and standard_plan() use seed 20261017 in Jobs 3, 4 and 8.
- Design grid (design/design_grid.R): stress_design() seed 2026 for run A (Table 4) and 3026 for run B.

## Reading the defect study

These two passages are copied from sims-073/README.md.

*Pilot and sizes.* The sizes were chosen on the filed analysis alone, 20 trials per candidate (results/defect_pilot.csv), before any stress test ran.
- **A:** delta 40 (the Job 4 value) gave 10 of 20 significant with median p 0.060. The median p reached 0.005 only at delta 200 (18 of 20, median 0.009); delta 80 gave 13 of 20 and median 0.022. Adam asked for all three to be run and reported; the figure uses delta 80.
- **C:** 30% gave 9 of 20 and 45% gave 17 of 20.
- **D:** b = 0.6 gave 10 of 20 and b = 0.9 gave 18 of 20.
- **B, as the handoff wrote it, could not be run.** The arms were to share one distribution, with one outlier at k = 15 or 25 at 25 per arm: 0 of 20 trials were significant at every k from 10 to 40. With two outliers at 50 per arm, 1 to 4 of 20 were. An outlier inflates its arm's variance as fast as it shifts the mean, so t stays below about k / sqrt(2n + k^2), which is under 1 for one outlier and about 1.4 for two.
- **B as redesigned (Adam's decision, 29 Oct 2026):** the outlier sits on a small real effect at planned power about 0.3 (delta 4.38 at 25 per arm, 3.10 at 50 per arm), so in B the arms do not share one distribution. On that effect an outlier raises t only up to about k = 5 to 8 and lowers it beyond that (results/defect_pilot_B.csv: 6, 9, 12, 11, 9 and 1 of 20 significant at k = 0, 3, 5, 8, 10 and 15 at 25 per arm). B therefore runs at k = 5 and 8 at 25 per arm, and with two outliers at k = 8 at 50 per arm.

*A package point for the paper.* stress_verdict() calls a result fragile when any counted row, deletions included, lies outside the filed interval; that is what makes the A trials fragile. The plain-language rule that stress_sap(), the plan text and the SAP template print (rule_text() in R/census.R) says "any counted alternative". The text and the code disagree. The paper should describe the code, and the package text should be fixed in a later version.

The paper describes the code. The package text was corrected in ballast 0.7.4, which now reads "any counted refit (an alternative analysis or a deletion)".

## License and citation

The scripts and files here are released under the MIT license (LICENSE). Until the paper is published, cite the package and this repository:

Sullivan AJ (2026). ballast: Stress-Test a Pre-Specified Mixed Model for Repeated Measures. R package version 0.7.3. https://doi.org/10.5281/zenodo.23427833. https://github.com/Sullivanstatistics/ballast

Sullivan AJ (2026). ballast-paper: scripts, seeds, per-trial results and logs for the ballast methods paper. Version v1.0-submission. https://doi.org/10.5281/zenodo.23872111. https://github.com/Sullivanstatistics/ballast-paper

When the paper is published its reference will be added here and to CITATION.cff.

## Use of AI tools

The simulation scripts, the run READMEs and this repository were prepared with the help of Claude Code (Anthropic), working under the author's direction. The author is responsible for the content.
