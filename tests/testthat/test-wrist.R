test_that("wrist positions are matched", {
  pos = c("LowerBack", "RightWrist", "LeftFoot")
  expect_equal(mobgap:::match_wrist_positions(pos), "RightWrist")
  expect_equal(mobgap:::match_wrist_positions(pos, "right"), "RightWrist")
  expect_error(mobgap:::match_wrist_positions(pos, "left"), "left wrist")
  expect_error(mobgap:::match_wrist_positions("LowerBack"), "Available")
})

test_that("wrist function errors informatively without wrist data", {
  testthat::skip_on_cran()
  testthat::skip_if_not(mobgap_check(), "mobgap not available")
  ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
  dp = mobgap_datapoints(ds)[[1]]
  expect_error(mobgap_wrist_steps(dp), "LowerBack")
})
