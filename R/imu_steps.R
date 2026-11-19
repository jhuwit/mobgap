#' Raw IMU Data and Reference Steps Together
#'
#' Returns the raw sensor data of a datapoint (e.g. a wrist) together with its
#' reference steps (initial contacts) and walking bouts, and optionally marks
#' the steps and bouts on the raw samples.
#'
#' Reference sample indices (`ic`, `start`, `end`) are counted from the start of
#' the recording at the reference sampling rate; they are converted to IMU
#' samples using the ratio of the two sampling rates.
#'
#' @inheritParams mobgap_imu_data
#' @param reference Optional output of [mobgap_reference()]; computed if `NULL`.
#' @param annotate If `TRUE`, add `step` (1 at the sample of each initial
#' contact, else 0), `step_id` and `wb_id` (`NA` outside walking bouts) columns
#' to the IMU data.
#'
#' @return A list with
#' \describe{
#'   \item{`imu`}{raw data as from [mobgap_imu_data()] (with
#'   `attr(, "sample_rate")`), plus the annotation columns if requested.}
#'   \item{`steps`}{reference steps with `time` (see [mobgap_step_times()]).}
#'   \item{`wb_list`}{reference walking bouts with `start_time`/`end_time`.}
#'   \item{`sample_rate`}{IMU sampling rate in Hz.}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
#' dp = mobgap_datapoints(ds)[[3]]
#' x = mobgap_imu_steps(dp, position = "LowerBack")
#' table(x$imu$step)
#' }
mobgap_imu_steps = function(datapoint, position = NULL, reference = NULL,
                            annotate = TRUE) {
  assertthat::assert_that(assertthat::is.flag(annotate))
  if (is.null(reference)) {
    reference = mobgap_reference(datapoint)
  }
  imu = mobgap_imu_data(datapoint, position = position)
  imu_fs = attr(imu, "sample_rate")
  meta = mobgap_metadata(datapoint)
  ref_fs = meta$reference_sampling_rate_hz
  if (is.null(ref_fs)) {
    ref_fs = py_to_r_if_needed(datapoint$reference_sampling_rate_hz_)
  }
  steps = step_times_from_ic(reference$ic_list, meta$start_date_time_iso,
                             ref_fs)
  wb = reference$wb_list
  start = parse_iso_time(meta$start_date_time_iso)
  if (!is.null(wb) && nrow(wb) > 0) {
    wb$start_time = start + wb$start / ref_fs
    wb$end_time = start + wb$end / ref_fs
  }
  if (annotate) {
    imu = annotate_imu_steps(imu, reference$ic_list, wb, imu_fs, ref_fs)
  }
  attr(imu, "sample_rate") = imu_fs
  list(imu = imu, steps = steps, wb_list = wb, sample_rate = imu_fs)
}

# Pure-R annotation of raw samples (per sensor position) with steps and bouts.
annotate_imu_steps = function(imu, ic_list, wb_list, imu_fs, ref_fs) {
  assertthat::assert_that(is.data.frame(imu), "position" %in% names(imu),
                          assertthat::is.number(imu_fs),
                          assertthat::is.number(ref_fs))
  ratio = imu_fs / ref_fs
  imu$step = 0L
  imu$step_id = NA_integer_
  imu$wb_id = NA_integer_
  for (pos in unique(imu$position)) {
    rows = which(imu$position == pos)
    n = length(rows)
    if (!is.null(ic_list) && nrow(ic_list) > 0) {
      idx = round(ic_list$ic * ratio) + 1
      keep = !is.na(idx) & idx >= 1 & idx <= n
      imu$step[rows[idx[keep]]] = 1L
      imu$step_id[rows[idx[keep]]] = as.integer(ic_list$step_id[keep])
    }
    if (!is.null(wb_list) && nrow(wb_list) > 0) {
      for (i in seq_len(nrow(wb_list))) {
        s = max(1, round(wb_list$start[i] * ratio) + 1)
        e = min(n, round(wb_list$end[i] * ratio) + 1)
        if (s <= e) {
          imu$wb_id[rows[s:e]] = as.integer(wb_list$wb_id[i])
        }
      }
    }
  }
  imu
}
