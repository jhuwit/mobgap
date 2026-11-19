#' Load a TVS Dataset With the Wrist Sensor
#'
#' Creates a TVS laboratory or free-living dataset that loads the wrist IMU (an
#' INDIP unit worn on the left or right wrist) as the single sensor, with INDIP
#' reference steps. Recordings without that wrist sensor or reference are
#' skipped. Each participant wore the unit on one side only, so call this once
#' per `side` and combine the results.
#'
#' Wrist data were added in version 1.0.2 of the TVS dataset (Zenodo record
#' 15861907) for all participants except CHF5084, CHF5086 and CHF5089. See
#' [mobgap_tvs_download()] to get the data. Only accelerometer data are
#' loaded by default (`sensor_types = "acc"`).
#'
#' @param path Folder containing the cohort folders (`HA`, `MS`, ...), as
#' returned by [mobgap_tvs_download()].
#' @param type `"lab"` or `"free_living"`.
#' @param side `"left"` or `"right"`.
#' @param reference_system Reference system for steps, default `"INDIP"`.
#' @param sensor_types Sensor types to load, default accelerometer only.
#' @param ... Passed to [mobgap_dataset()].
#'
#' @return A Python dataset object; use [mobgap_datapoints()] and
#' [mobgap_wrist_steps()].
#' @export
#'
#' @examples
#' \dontrun{
#' path = mobgap_tvs_download("~/mobgap_tvs", cohorts = "HA")
#' ds = mobgap_wrist_dataset(path, type = "lab", side = "left")
#' x = mobgap_wrist_steps(mobgap_datapoints(ds)[[1]])
#' }
mobgap_wrist_dataset = function(path, type = c("lab", "free_living"),
                                side = c("left", "right"),
                                reference_system = "INDIP",
                                sensor_types = "acc", ...) {
  type = match.arg(type)
  side = match.arg(side)
  position = paste0(tools::toTitleCase(side), "Wrist")
  mobgap_dataset(
    path, type = type, reference_system = reference_system,
    missing_reference_error_type = "skip",
    raw_data_sensor = "INDIP",
    sensor_positions = position,
    single_sensor_position = position,
    sensor_types = sensor_types,
    missing_sensor_error_type = "skip",
    ...
  )
}
