# mobgap 0.0.0.9000

* Initial release: reticulate wrapper for the `mobgap` Python module.
* `mobgap_dataset()`, `mobgap_datapoints()`, `mobgap_index()` to load TVS
  free-living, TVS lab and example datasets.
* `mobgap_reference()`, `mobgap_steps_per_wb()`, `mobgap_total_steps()` and
  `mobgap_reference_summary()` to extract reference walking bouts, steps and
  totals as data frames.
* Python modules are declared with `py_require()` and delay-loaded in `.onLoad()`.
* `mobgap_imu_data()` extracts raw accelerometry/gyroscope data for any loaded
  sensor position (e.g. wrist); `mobgap_step_times()` and
  `mobgap_steps_by_interval()` give timestamped step counts.
* `mobgap_imu_data()` and `mobgap_sensor_data()` embed the sampling rate as `attr(data, "sample_rate")`.
* `mobgap_to_acc()` and `mobgap_compare_steps()` convert raw data for tools such
  as `stepcount` and compute step-count agreement (bias, MAE, RMSE, MAPE,
  correlation, Bland-Altman limits). README and vignette compare `stepcount`
  with the reference steps and run it on wrist-worn data.
* `mobgap_cleanup_uv()` / `mobgap_uv_snapshot()` remove `uv` lock files.
* `mobgap_imu_steps()` returns raw IMU data (any sensor position, e.g. wrist)
  together with reference steps and walking bouts, optionally marked on the
  raw samples.
* `mobgap_gravity_means()`, `mobgap_axis_rotations()` and `mobgap_rotate_acc()`
  for sensor-orientation checks; see the vignette for caveats.
