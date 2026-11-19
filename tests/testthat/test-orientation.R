test_that("axis rotations are the 24 proper rotations", {
  rots = mobgap_axis_rotations()
  expect_length(rots, 24)
  expect_true(all(vapply(rots, function(m) round(det(m)) == 1, logical(1))))
  expect_length(unique(lapply(rots, c)), 24)
})

test_that("rotating accelerometer data works", {
  df = data.frame(x = 1, y = 0.2, z = 0)
  R = rbind(c(0, 0, -1), c(1, 0, 0), c(0, -1, 0))
  out = mobgap_rotate_acc(df, R)
  expect_equal(unlist(out), c(x = 0, y = 1, z = -0.2))
  expect_equal(mobgap_rotate_acc(df, 1), df)
  expect_equal(mobgap_gravity_means(df), c(x = 1, y = 0.2, z = 0))
  named = data.frame(acc_x = 1, acc_y = 0, acc_z = 0)
  expect_equal(names(mobgap_gravity_means(named)), c("acc_x", "acc_y", "acc_z"))
  expect_error(mobgap_gravity_means(data.frame(a = 1)), "Need")
  expect_error(mobgap_rotate_acc(df, diag(c(1, 1, -1))))
})

test_that("annotate_imu_steps marks steps and bouts", {
  imu = data.frame(position = rep(c("A", "B"), each = 10),
                   acc_x = 0)
  ic = data.frame(wb_id = 0L, step_id = 0:2, ic = c(0, 4, 20))
  wb = data.frame(wb_id = 0L, start = 2, end = 5)
  out = mobgap:::annotate_imu_steps(imu, ic, wb, imu_fs = 100, ref_fs = 100)
  expect_equal(which(out$step == 1), c(1, 5, 11, 15))
  expect_equal(which(!is.na(out$wb_id)), c(3:6, 13:16))
  half = mobgap:::annotate_imu_steps(imu[1:10, ], ic, wb, imu_fs = 50,
                                     ref_fs = 100)
  expect_equal(which(half$step == 1), c(1, 3))
  none = mobgap:::annotate_imu_steps(imu, NULL, NULL, 100, 100)
  expect_true(all(none$step == 0))
})

test_that("mobgap_imu_steps combines raw data and steps", {
  testthat::skip_on_cran()
  testthat::skip_if_not(mobgap_check(), "mobgap not available")
  ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
  dp = mobgap_datapoints(ds)[[3]]
  x = mobgap_imu_steps(dp, position = "LowerBack")
  expect_equal(x$sample_rate, 100)
  expect_equal(attr(x$imu, "sample_rate"), 100)
  expect_equal(sum(x$imu$step), nrow(x$steps))
  expect_true(all(c("start_time", "end_time") %in% names(x$wb_list)))
  plain = mobgap_imu_steps(dp, annotate = FALSE)
  expect_false("step" %in% names(plain$imu))
})
