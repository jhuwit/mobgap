#' Wrist Raw Accelerometry and Reference Steps
#'
#' Convenience wrapper around [mobgap_imu_steps()] that selects the wrist
#' sensor(s) of a datapoint, matching position names containing "wrist"
#' (case-insensitive), e.g. `"RightWrist"`.
#'
#' The bundled example data has **no wrist sensor**. Wrist data are in the
#' full TVS dataset (see [mobgap_tvs_download()]) and are loaded with
#' [mobgap_wrist_dataset()], which sets `raw_data_sensor = "INDIP"` and the
#' wrist position name (`"LeftWrist"` or `"RightWrist"`). See
#' [mobgap_gravity_means()] for orientation caveats before applying
#' step-counting models to the raw axes.
#'
#' @param datapoint A datapoint from [mobgap_datapoints()].
#' @param side `"any"` (default), `"left"` or `"right"`.
#' @inheritParams mobgap_imu_steps
#'
#' @return As [mobgap_imu_steps()], restricted to the wrist position(s). The
#' raw data keep `attr(, "sample_rate")`.
#' @export
#'
#' @examples
#' \dontrun{
#' ds = mobgap_wrist_dataset(path, type = "lab", side = "left")
#' x = mobgap_wrist_steps(mobgap_datapoints(ds)[[1]])
#' x$imu; x$steps
#' }
mobgap_wrist_steps = function(datapoint, side = c("any", "left", "right"),
                              reference = NULL, annotate = TRUE) {
  side = match.arg(side)
  imu = reticulate::py_get_attr(datapoint, "data")
  positions = as.character(unlist(reticulate::py_to_r(
    reticulate::import_builtins(convert = FALSE)$list(imu$keys())
  )))
  wrist = match_wrist_positions(positions, side)
  mobgap_imu_steps(datapoint, position = wrist, reference = reference,
                   annotate = annotate)
}

match_wrist_positions = function(positions, side = "any") {
  wrist = positions[grepl("wrist", positions, ignore.case = TRUE)]
  if (side != "any") {
    wrist = wrist[grepl(side, wrist, ignore.case = TRUE)]
  }
  if (length(wrist) == 0) {
    stop("No ", if (side != "any") paste0(side, " "), "wrist sensor found. ",
         "Available positions: ", paste(positions, collapse = ", "),
         ". Request wrist data with `sensor_positions` in mobgap_dataset().",
         call. = FALSE)
  }
  wrist
}
