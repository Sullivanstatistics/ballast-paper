Release title: ballast 0.7.3
Tag: v0.7.3 (commit 28be8fb103839ddc214962d0c54800d2c8b610b0, branch dev-0.7.3)

* standard_plan(): the complete-case refit of the estimator family is now a diagnostic. It is fitted, drawn on the swarm (as a hollow dot) and on the family plot (as a triangle), and listed in the census and the tables with kind = "diagnostic" and counted = FALSE; it does not enter the verdict, the crossing count, the outside-interval count or the reversal count. The plan text, stress_sap() and the installed SAP template say so. stress_estimator() gains `diagnostic`, the names of estimators to treat this way; called directly without it, it still counts every estimator, including complete cases.
* summary() of a census gains a `counted` column and one line per diagnostic family, left out of the closing totals; stress_verdict() reports n_diagnostic and prints it; the family table of stress_tables() and stress_report() shows the counted status.
* plot_swarm() lists every family name the package produces in its decision groups, so "Other family" can appear only for a user-defined family. A test runs the standard plan on mmrm::fev_data and checks the swarm legend and the diagnostic row.

Checks: devtools::test() clean; local R CMD check --as-cran 0 errors, 0 warnings (one network-only note); GitHub Actions on dev-0.7.3: see https://github.com/Sullivanstatistics/ballast/actions
