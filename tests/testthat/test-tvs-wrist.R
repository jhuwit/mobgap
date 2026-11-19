# Optional integration test: set MOBGAP_TVS_PATH to a folder containing e.g.
# HA/<participant>/Laboratory/data.mat (see mobgap_tvs_download()).
test_that("wrist data and steps load from TVS data", {
  testthat::skip_on_cran()
  path = Sys.getenv("MOBGAP_TVS_PATH")
  testthat::skip_if(path == "", "MOBGAP_TVS_PATH not set")
  testthat::skip_if_not(mobgap_check(), "mobgap not available")
  ds = mobgap_wrist_dataset(path, type = "lab", side = "left")
  dps = mobgap_datapoints(ds)
  expect_gt(length(dps), 0)
  x = mobgap_wrist_steps(dps[[1]])
  expect_equal(x$sample_rate, 100)
  expect_true(all(x$imu$position == "LeftWrist"))
  expect_equal(sum(x$imu$step), nrow(x$steps))
})
