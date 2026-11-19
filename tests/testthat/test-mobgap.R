skip_if_no_mobgap = function() {
  testthat::skip_on_cran()
  testthat::skip_if_not(mobgap_check(), "mobgap not available")
}

test_that("example lab dataset reference extraction works", {
  skip_if_no_mobgap()
  ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
  dps = mobgap_datapoints(ds)
  expect_length(dps, 9)
  ref = mobgap_reference(dps[[1]])
  expect_true(all(c("wb_id", "start", "end") %in% names(ref$wb_list)))
  expect_true(all(c("wb_id", "step_id", "ic") %in% names(ref$ic_list)))
  expect_equal(sum(mobgap_steps_per_wb(ref)$n_steps),
               mobgap_total_steps(ref))
  res = mobgap_reference_summary(ds)
  expect_equal(nrow(res$totals), 9)
})

test_that("helpers convert and validate", {
  expect_equal(mobgap:::py_to_r_if_needed(1), 1)
  expect_null(mobgap:::mobgap_df_to_r(NULL))
  expect_true(mobgap:::null_or_string(NULL))
  expect_false(mobgap:::null_or_string(1))
  ref = list(ic_list = data.frame(wb_id = c(0L, 0L, 1L)))
  expect_equal(mobgap_steps_per_wb(ref)$n_steps, c(2L, 1L))
  expect_equal(mobgap_total_steps(ref), 3L)
  expect_equal(nrow(mobgap_steps_per_wb(list(ic_list = NULL))), 0)
  expect_error(mobgap_dataset(type = "lab"))
})

test_that("step times and interval counts (pure R)", {
  ic = data.frame(wb_id = 0L, step_id = 0:3, ic = c(0, 50, 100, 6100))
  out = mobgap:::step_times_from_ic(ic, "2020-12-10T13:57:44.000+01:00", 100)
  expect_equal(as.numeric(diff(out$time), units = "secs"), c(0.5, 0.5, 60))
  by_min = mobgap_steps_by_interval(out, "min")
  expect_equal(by_min$n_steps[by_min$n_steps > 0], c(3L, 1L))
  expect_equal(nrow(mobgap_steps_by_interval(out[0, ])), 0)
  expect_equal(format(mobgap:::parse_iso_time("2020-01-01T00:00:00Z")),
               "2020-01-01")
})

test_that("imu data and step times from example data", {
  skip_if_no_mobgap()
  ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
  dp = mobgap_datapoints(ds)[[1]]
  imu = mobgap_imu_data(dp)
  expect_true(all(c("position", "time", "acc_x") %in% names(imu)))
  expect_equal(attr(imu, "sample_rate"), 100)
  expect_equal(attr(mobgap_sensor_data(dp), "sample_rate"), 100)
  expect_error(mobgap_imu_data(dp, "Nope"), "not available")
  st = mobgap_step_times(dp)
  expect_s3_class(st$time, "POSIXct")
  expect_equal(sum(mobgap_steps_by_interval(dp)$n_steps), nrow(st))
})

test_that("dataset accessors work", {
  skip_if_no_mobgap()
  ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
  idx = mobgap_index(ds)
  expect_equal(nrow(idx), 9)
  dp = mobgap_datapoints(ds)[[1]]
  expect_true("height_m" %in% names(mobgap_participant_metadata(dp)))
  expect_true("time" %in% names(mobgap_sensor_data(dp)))
  expect_true(is.list(mobgap_reference(dp, relative_to_wb = TRUE)))
  expect_error(mobgap_dataset("/no/such/path", type = "free_living"))
  expect_true(is.character(mobgap_version()))
})

test_that("reference summary skips datapoints without reference", {
  skip_if_no_mobgap()
  ds = mobgap_dataset(type = "example_lab")  # no reference system
  suppressWarnings(res <- mobgap_reference_summary(ds))
  expect_null(res$totals)
  expect_error(mobgap_reference_summary(ds, skip_errors = FALSE))
})
