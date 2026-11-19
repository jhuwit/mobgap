#' Raw IMU (Accelerometry) Data of a Datapoint
#'
#' Extracts raw sensor data for any sensor position loaded by the dataset
#' (`dp.data` in Python), e.g. a wrist-worn sensor. Which positions are
#' available depends on the dataset and on the `sensor_positions` argument given
#' to [mobgap_dataset()] (the default is `"LowerBack"` only). Request wrist
#' sensors with e.g.
#' `mobgap_dataset(path, sensor_positions = c("LowerBack", "LeftWrist"),
#' missing_sensor_error_type = "skip")`.
#'
#' @section Orientation:
#' Raw axes are the device's axes. Models that read raw `x`/`y`/`z` are not
#' rotation invariant; see [mobgap_gravity_means()] for helpers and caveats. The
#' bundled example data has no wrist sensor.
#'
#' @param datapoint A datapoint from [mobgap_datapoints()].
#' @param position Character vector of sensor positions to return, or `NULL`
#' for all loaded positions.
#'
#' @return A data frame (with a `sample_rate` attribute in Hz, i.e.
#' `attr(data, "sample_rate")`) with `position`, `time` (POSIXct, UTC) and the sensor
#' columns (e.g. `acc_x`, `acc_y`, `acc_z`, `gyr_x`, ...). Accelerometer data
#' are in m/s^2 and gyroscope data in deg/s.
#' @export
#'
#' @examples
#' \dontrun{
#' ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
#' dp = mobgap_datapoints(ds)[[1]]
#' head(mobgap_imu_data(dp))
#' }
mobgap_imu_data = function(datapoint, position = NULL) {
  imu = reticulate::py_get_attr(datapoint, "data")
  positions = reticulate::py_to_r(
    reticulate::import_builtins(convert = FALSE)$list(imu$keys())
  )
  positions = as.character(unlist(positions))
  if (!is.null(position)) {
    assertthat::assert_that(is.character(position))
    missing_pos = setdiff(position, positions)
    if (length(missing_pos) > 0) {
      stop("Sensor position(s) not available: ",
           paste(missing_pos, collapse = ", "),
           ". Available: ", paste(positions, collapse = ", "), call. = FALSE)
    }
    positions = position
  }
  out = lapply(positions, function(pos) {
    df = mobgap_df_to_r(reticulate::py_get_item(imu, pos))
    cbind(position = rep(pos, nrow(df)), df, stringsAsFactors = FALSE)
  })
  out = do.call(rbind, out)
  rownames(out) = NULL
  attr(out, "sample_rate") = mobgap_sample_rate(datapoint)
  out
}

# sampling rate (Hz) of the IMU data of a datapoint
mobgap_sample_rate = function(datapoint) {
  sr = py_to_r_if_needed(datapoint$sampling_rate_hz)
  if (is.null(sr)) NULL else as.numeric(sr)
}

#' Timestamps of Reference Steps
#'
#' Converts the initial contact sample indices (`ic`) of the reference system
#' into clock times using the recording start time and the reference sampling
#' rate.
#'
#' @param datapoint A datapoint from [mobgap_datapoints()].
#' @param reference Optional output of [mobgap_reference()].
#'
#' @return The `ic_list` data frame with an added `time` column (POSIXct).
#' @export
mobgap_step_times = function(datapoint, reference = NULL) {
  if (is.null(reference)) {
    reference = mobgap_reference(datapoint)
  }
  meta = mobgap_metadata(datapoint)
  fs = meta$reference_sampling_rate_hz
  if (is.null(fs)) {
    fs = py_to_r_if_needed(datapoint$reference_sampling_rate_hz_)
  }
  step_times_from_ic(reference$ic_list, meta$start_date_time_iso, fs)
}

step_times_from_ic = function(ic_list, start_iso, fs) {
  assertthat::assert_that(is.data.frame(ic_list), assertthat::is.number(fs))
  start = parse_iso_time(start_iso)
  ic_list$time = start + ic_list$ic / fs
  ic_list
}

parse_iso_time = function(x) {
  x = sub("Z$", "+0000", x)
  x = sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", x)
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OS%z", tz = "UTC")
}

#' Step Counts per Time Interval
#'
#' Aggregates reference steps (initial contacts) into counts per interval, which
#' can be joined with epoch summaries of raw accelerometry (e.g. wrist data from
#' [mobgap_imu_data()]).
#'
#' @param datapoint A datapoint from [mobgap_datapoints()], or a data frame as
#' returned by [mobgap_step_times()].
#' @param unit Interval passed to [base::cut.POSIXt()], e.g. `"min"`,
#' `"hour"`, `"day"`.
#'
#' @return A data frame with `time` (interval start) and `n_steps`.
#' @export
mobgap_steps_by_interval = function(datapoint, unit = "min") {
  assertthat::assert_that(assertthat::is.string(unit))
  steps = if (is.data.frame(datapoint)) datapoint else mobgap_step_times(datapoint)
  if (nrow(steps) == 0) {
    return(data.frame(time = as.POSIXct(character(0), tz = "UTC"),
                      n_steps = integer(0)))
  }
  bins = cut(steps$time, breaks = unit)
  tab = table(bins)
  data.frame(time = as.POSIXct(names(tab), tz = "UTC"),
             n_steps = as.integer(tab),
             row.names = NULL)
}
