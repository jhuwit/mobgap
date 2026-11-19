#' Convert Raw `mobgap` IMU Data for Accelerometer Tools
#'
#' Reshapes the output of [mobgap_imu_data()] (or [mobgap_sensor_data()]) into
#' the `time`, `x`, `y`, `z` format (in units of g) used by tools such as
#' `actipy` and `stepcount`.
#'
#' @param data A data frame with `time`, `acc_x`, `acc_y`, `acc_z` columns.
#' @param sample_rate Sampling rate in Hz. Defaults to
#' `attr(data, "sample_rate")`.
#' @param to_g Convert from m/s^2 to g.
#' @param resample_hz Optional target rate in Hz, using linear interpolation.
#'
#' @return A data frame with `time`, `x`, `y`, `z` and a `sample_rate`
#' attribute.
#' @export
#'
#' @examples
#' df = data.frame(time = as.POSIXct("2020-01-01", tz = "UTC") + (0:4) / 10,
#'                 acc_x = 9.80665, acc_y = 0, acc_z = 0)
#' mobgap_to_acc(df, sample_rate = 10)
mobgap_to_acc = function(data, sample_rate = attr(data, "sample_rate"),
                         to_g = TRUE, resample_hz = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    all(c("time", "acc_x", "acc_y", "acc_z") %in% names(data)),
    assertthat::is.number(sample_rate),
    is.null(resample_hz) || assertthat::is.number(resample_hz)
  )
  scale = if (to_g) 9.80665 else 1
  out = data.frame(time = data$time, x = data$acc_x / scale,
                   y = data$acc_y / scale, z = data$acc_z / scale)
  if (!is.null(resample_hz) && resample_hz != sample_rate) {
    secs = as.numeric(out$time)
    new_secs = seq(secs[1], secs[length(secs)], by = 1 / resample_hz)
    res = data.frame(
      time = as.POSIXct(new_secs, origin = "1970-01-01",
                        tz = attr(out$time, "tzone") %||% "UTC"),
      x = stats::approx(secs, out$x, new_secs)$y,
      y = stats::approx(secs, out$y, new_secs)$y,
      z = stats::approx(secs, out$z, new_secs)$y
    )
    out = res
    sample_rate = resample_hz
  }
  attr(out, "sample_rate") = sample_rate
  out
}

`%||%` = function(x, y) if (is.null(x)) y else x

#' Compare Step Counts from Two Sources
#'
#' Aggregates two step series (e.g. reference steps from
#' [mobgap_steps_by_interval()] and `stepcount` output) into common intervals
#' and computes agreement metrics.
#'
#' @param reference,estimate Data frames with a `time` column and a count
#' column named `n_steps` or `steps`.
#' @param interval Interval length in seconds.
#' @param origin Start of the first interval (a time or seconds since epoch).
#' Use the recording start so intervals line up with, e.g., `stepcount`'s
#' 10-second windows. The default aligns intervals to the clock.
#'
#' @return A list with `data` (per interval: `time`, `reference`, `estimate`,
#' `mean`, `difference`, `pct_error`; the `mean`/`difference` columns are the
#' Bland-Altman coordinates) and `summary` (one-row data frame with totals,
#' `bias`, `mae`, `rmse`, `mape`, `correlation`, and the 95% limits of
#' agreement `loa_lower`/`loa_upper`).
#' @export
#'
#' @examples
#' t0 = as.POSIXct("2020-01-01", tz = "UTC")
#' ref = data.frame(time = t0 + c(0, 60, 120), n_steps = c(10, 20, 30))
#' est = data.frame(time = t0 + c(0, 60, 120), steps = c(12, 18, 33))
#' mobgap_compare_steps(ref, est)$summary
mobgap_compare_steps = function(reference, estimate, interval = 60,
                                origin = 0) {
  assertthat::assert_that(assertthat::is.number(interval), interval > 0)
  origin = as.numeric(origin)
  ref = bin_steps(reference, interval, origin)
  est = bin_steps(estimate, interval, origin)
  all_bins = sort(unique(c(ref$bin, est$bin)))
  if (length(all_bins) == 0) {
    stop("No steps in either series.", call. = FALSE)
  }
  all_bins = seq(min(all_bins), max(all_bins), by = interval)
  r = ref$n[match(all_bins, ref$bin)]
  e = est$n[match(all_bins, est$bin)]
  r[is.na(r)] = 0
  e[is.na(e)] = 0
  diff = e - r
  data = data.frame(
    time = as.POSIXct(all_bins, origin = "1970-01-01", tz = "UTC"),
    reference = r, estimate = e, mean = (r + e) / 2, difference = diff,
    pct_error = ifelse(r > 0, 100 * diff / r, NA_real_)
  )
  sd_diff = stats::sd(diff)
  has_var = length(diff) > 1 && stats::sd(r) > 0 && stats::sd(e) > 0
  summary = data.frame(
    total_reference = sum(r), total_estimate = sum(e),
    bias = mean(diff), mae = mean(abs(diff)), rmse = sqrt(mean(diff^2)),
    mape = if (any(r > 0)) mean(abs(diff[r > 0]) / r[r > 0]) * 100 else NA_real_,
    correlation = if (has_var) stats::cor(r, e) else NA_real_,
    loa_lower = mean(diff) - 1.96 * sd_diff,
    loa_upper = mean(diff) + 1.96 * sd_diff
  )
  list(data = data, summary = summary)
}

bin_steps = function(x, interval, origin = 0) {
  assertthat::assert_that(is.data.frame(x), "time" %in% names(x))
  col = intersect(c("n_steps", "steps"), names(x))[1]
  if (is.na(col)) {
    stop("Need an `n_steps` or `steps` column.", call. = FALSE)
  }
  bin = origin + floor((as.numeric(x$time) - origin) / interval) * interval
  agg = tapply(x[[col]], bin, sum)
  data.frame(bin = as.numeric(names(agg)), n = as.numeric(agg))
}
