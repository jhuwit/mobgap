## Test environments
* local macOS (x86_64), R 4.4, `R CMD check --as-cran`
* GitHub Actions (R-CMD-check workflow)

## R CMD check results
0 errors | 0 warnings | 1 note

* New submission.

Python-dependent tests, examples and vignette code are skipped unless
`NOT_CRAN=true` and the 'mobgap' Python module is available.
