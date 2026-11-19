#' Create a `mobgap` Dataset
#'
#' Creates a Python dataset object from `mobgap.data`. The object is returned
#' unconverted (a Python object); use [mobgap_datapoints()] to iterate over its
#' recordings and [mobgap_reference()] to extract reference parameters.
#'
#' @param path Base path of the dataset. Not needed for `type = "example_lab"`,
#' which downloads (and caches) the small example data shipped with `mobgap`.
#' @param type One of `"free_living"` (`TVSFreeLivingDataset`), `"lab"`
#' (`TVSLabDataset`) or `"example_lab"` (`LabExampleDataset`).
#' @param reference_system Reference system, `"INDIP"` or `"Stereophoto"`.
#' Required to access reference parameters. `NULL` for none.
#' @param missing_reference_error_type What to do when a recording has no
#' reference: `"raise"`, `"warn"`, `"ignore"` or `"skip"`.
#' @param ... Additional arguments passed to the Python dataset constructor,
#' e.g. `raw_data_sensor`, `reference_para_level`, `sensor_positions`,
#' `missing_sensor_error_type`.
#'
#' @return A Python dataset object.
#' @export
#'
#' @examples
#' \dontrun{
#' ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
#' ds = mobgap_dataset("path/to/tvs", type = "free_living",
#'                     reference_system = "INDIP",
#'                     missing_reference_error_type = "skip")
#' }
mobgap_dataset = function(
    path = NULL,
    type = c("free_living", "lab", "example_lab"),
    reference_system = NULL,
    missing_reference_error_type = c("ignore", "raise", "warn", "skip"),
    ...
) {
  type = match.arg(type)
  missing_reference_error_type = match.arg(missing_reference_error_type)
  assertthat::assert_that(null_or_string(reference_system))

  md = mobgap_import("mobgap.data", convert = FALSE)
  kwargs = list(
    reference_system = reference_system,
    missing_reference_error_type = missing_reference_error_type,
    ...
  )
  # Python expects sequences of strings, not a bare string
  for (nm in intersect(c("sensor_positions", "sensor_types"), names(kwargs))) {
    kwargs[[nm]] = reticulate::r_to_py(as.list(kwargs[[nm]]))
  }
  if (type == "example_lab") {
    return(do.call(md$LabExampleDataset, kwargs))
  }
  assertthat::assert_that(assertthat::is.string(path))
  path = normalizePath(path.expand(path), winslash = "/", mustWork = TRUE)
  cls = switch(type,
               free_living = md$TVSFreeLivingDataset,
               lab = md$TVSLabDataset)
  do.call(cls, c(list(path), kwargs))
}

#' List the Datapoints of a `mobgap` Dataset
#'
#' Equivalent to `for dp in ds:` in Python.
#'
#' @param dataset A dataset from [mobgap_dataset()].
#'
#' @return A list of Python datapoint objects.
#' @export
mobgap_datapoints = function(dataset) {
  mobgap_py_list(dataset)
}

#' Dataset Index
#'
#' @param dataset A dataset from [mobgap_dataset()].
#' @return A data frame with one row per datapoint.
#' @export
mobgap_index = function(dataset) {
  mobgap_df_to_r(dataset$index)
}

#' Information About a Datapoint
#'
#' @param datapoint A datapoint from [mobgap_datapoints()].
#' @return `mobgap_group_label()` returns a one-row data frame identifying the
#' datapoint; `mobgap_metadata()` and `mobgap_participant_metadata()` return
#' named lists; `mobgap_sensor_data()` returns a data frame of IMU data
#' (default `data_ss`, the single sensor) with a `time` column.
#' @export
#' @rdname mobgap_datapoint
mobgap_group_label = function(datapoint) {
  lab = mobgap_dict_to_r(datapoint$group_label)
  as.data.frame(lapply(lab, function(x) paste(unlist(x), collapse = "_")),
                stringsAsFactors = FALSE)
}

#' @export
#' @rdname mobgap_datapoint
mobgap_metadata = function(datapoint) {
  py_to_r_if_needed(datapoint$recording_metadata)
}

#' @export
#' @rdname mobgap_datapoint
mobgap_participant_metadata = function(datapoint) {
  py_to_r_if_needed(datapoint$participant_metadata)
}

#' @param which Which sensor data attribute to read, e.g. `"data_ss"`.
#' @export
#' @rdname mobgap_datapoint
mobgap_sensor_data = function(datapoint, which = "data_ss") {
  assertthat::assert_that(assertthat::is.string(which))
  out = mobgap_df_to_r(reticulate::py_get_attr(datapoint, which))
  attr(out, "sample_rate") = mobgap_sample_rate(datapoint)
  out
}
