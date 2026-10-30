Release title: ballast 0.7.1
Tag: v0.7.1 (commit e94d6ae8349f, branch dev-0.7.1)


The package's surface now matches the methods paper: a stress test that refits one pre-specified MMRM under families of perturbations and displays every refit against the filed result. Nothing is calibrated and no benchmark is computed.

* Removed `deletion_benchmark()`, `removal_ratio()`, `expected_crossing()` and `expected_exit()`, with their documentation and tests.
* `stress_direction()` is cut down. For a filed result that is not significant it reports how many pre-specified re-analyses reverse the direction of the estimate and which, how many move the estimate outside the filed interval, and the number of participants the deletion search removes before the direction reverses (`method = "ranked"` by default, `"greedy"` on request). The standard-normal benchmark, the ratio and the printed reading paragraph are gone; the print method lists the counts and the rows.
* `stress_fragility()` keeps its three targets (`"significance"`, `"ci"`, `"direction"`) and its two methods; the `"mutual"` target is removed.
* `plot_swarm()` gains a multi-row form: given a list of `stress_result` objects (what `run_plans()` returns) or of censuses, it draws one panel per row with the filed estimate and 95% interval as the axis, every counted alternative analysis as a dot coloured by decision group (statistical or data-handling) and the counted deletions as a strip beneath, a line at zero and an optional labelled reference line. Rows without an estimate (rank tests) are counted in the `caption` attribute. The single-census bubble swarm is unchanged.
* `plot_forest()` is new: a forest of estimate and interval for the filed analysis and the supplementary rows (or any named rows), one panel per endpoint-metric, with several results objects side by side in different colours.
* `plot_pcdf()` accepts `stress_result` objects and lists of them as well as censuses.
* `stress_calibrate()` is unchanged: it simulates trials from a planned design and reports verdict rates; it sets no threshold.

Checks: R CMD check clean on Windows, macOS and Ubuntu (release and devel), GitHub Actions run 40696990462; local --as-cran check 0 errors, 0 warnings.
