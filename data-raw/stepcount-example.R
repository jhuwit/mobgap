# Builds inst/extdata/stepcount_example.rds (small, used by the README/vignette).
#
# The 'stepcount' Python module (pandas==2.0.*) cannot share a Python
# environment with 'mobgap'/'multigait' (pandas>=2.2), so each step runs in its
# own R process. Run this script with `Rscript data-raw/stepcount-example.R`
# from the package root, with RETICULATE_PYTHON unset for the stepcount steps.
options(digits.secs = 3)
tmp = tempfile(fileext = ".rds")

# 1. mobgap process: lower-back lab recording with INDIP reference steps
run_r = function(code) {
  f = tempfile(fileext = ".R"); writeLines(code, f)
  system2("Rscript", f)
}
run_r(sprintf('
  devtools::load_all(quiet = TRUE)
  ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
  dp = mobgap_datapoints(ds)[[3]]
  imu = mobgap_imu_data(dp, "LowerBack")
  steps = mobgap_step_times(dp)
  saveRDS(list(acc = mobgap_to_acc(imu), steps = steps), "%s")', tmp))
lab = readRDS(tmp)

# 2. wrist data (multigait::wrist_imu) -> plain data frame, no Python needed
run_r(sprintf('w = multigait::wrist_imu
  saveRDS(data.frame(time = w$time, x = w$X, y = w$Y, z = w$Z), "%s")', tmp))
wrist = readRDS(tmp)

# 3. stepcount processes (managed Python environment)
sc = function(d, hz) {
  saveRDS(list(d = d, hz = hz), tmp)
  run_r(sprintf('library(stepcount); options(digits.secs = 3)
    x = readRDS("%s")
    out = stepcount(file = x$d, sample_rate = x$hz)
    saveRDS(out$steps, "%s")', tmp, tmp))
  readRDS(tmp)
}
lab_sc = sc(lab$acc, attr(lab$acc, "sample_rate"))
wrist_sc = sc(wrist, 100)

# stepcount returns naive clock times; re-anchor them to the true recording
# start so they share a time axis with the mobgap reference steps.
anchor = function(x, start) {
  x$time = start + as.numeric(difftime(x$time, x$time[1], units = "secs"))
  x
}
lab_sc = anchor(lab_sc, lab$acc$time[1])

keep = c("time", "steps")
saveRDS(list(
  lab_reference = lab$steps[, c("time", "wb_id", "step_id")],
  lab_stepcount = lab_sc[, keep],
  wrist_stepcount = wrist_sc[, keep]
), "inst/extdata/stepcount_example.rds", compress = "xz")
