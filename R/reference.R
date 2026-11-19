#' Reference Gait Parameters of a Datapoint
#'
#' R equivalent of `dp.reference_parameters_`.
#'
#' @param datapoint A datapoint from [mobgap_datapoints()] whose dataset was
#' created with a `reference_system`.
#' @param relative_to_wb Use `reference_parameters_relative_to_wb_` (sample
#' indices relative to the start of each walking bout).
#'
#' @return A list with data frames `wb_list` (walking bouts: `wb_id`, `start`,
#' `end`, `n_strides`, `avg_cadence_spm`, ...), `ic_list` (initial contacts
#' / steps: `wb_id`, `step_id`, `ic`, `lr_label`), `turn_parameters` and
#' `stride_parameters`.
#' @export
#'
#' @examples
#' \dontrun{
#' ds = mobgap_dataset(type = "example_lab", reference_system = "INDIP")
#' dp = mobgap_datapoints(ds)[[1]]
#' ref = mobgap_reference(dp)
#' ref$wb_list
#' }
mobgap_reference = function(datapoint, relative_to_wb = FALSE) {
  attr_name = if (relative_to_wb) {
    "reference_parameters_relative_to_wb_"
  } else {
    "reference_parameters_"
  }
  ref = reticulate::py_get_attr(datapoint, attr_name)
  fields = c("wb_list", "ic_list", "turn_parameters", "stride_parameters")
  out = lapply(fields, function(f) {
    if (!reticulate::py_has_attr(ref, f)) {
      return(NULL)
    }
    mobgap_df_to_r(reticulate::py_get_attr(ref, f))
  })
  names(out) = fields
  out
}

#' Steps Per Walking Bout and Total Steps
#'
#' Steps are the initial contacts (`ic_list`) of the reference system.
#'
#' @param reference Output of [mobgap_reference()], or a datapoint.
#'
#' @return `mobgap_steps_per_wb()` returns a data frame with `wb_id` and
#' `n_steps`; `mobgap_total_steps()` returns an integer.
#' @export
#' @rdname mobgap_steps
mobgap_steps_per_wb = function(reference) {
  reference = as_mobgap_reference(reference)
  ic = reference$ic_list
  if (is.null(ic) || nrow(ic) == 0) {
    return(data.frame(wb_id = integer(0), n_steps = integer(0)))
  }
  tab = table(ic$wb_id)
  data.frame(wb_id = as.integer(names(tab)),
             n_steps = as.integer(tab),
             row.names = NULL)
}

#' @export
#' @rdname mobgap_steps
mobgap_total_steps = function(reference) {
  reference = as_mobgap_reference(reference)
  nrow(reference$ic_list)
}

as_mobgap_reference = function(x) {
  if (inherits(x, "python.builtin.object")) {
    mobgap_reference(x)
  } else {
    x
  }
}

#' Summarise Reference Parameters for a Whole Dataset
#'
#' Iterates over all datapoints (the R version of the loop over `for dp in ds`)
#' and collects walking bouts, steps and totals, each tagged with the
#' datapoint's identifiers (cohort, participant, ...).
#'
#' @param dataset A dataset from [mobgap_dataset()] with a `reference_system`.
#' @param skip_errors If `TRUE`, datapoints without reference data are skipped
#' with a warning instead of raising an error.
#'
#' @return A list with data frames:
#' \describe{
#'   \item{`totals`}{one row per datapoint: identifiers, `n_wb`,
#'   `total_steps`.}
#'   \item{`wb_list`}{all walking bouts, with `n_steps` added.}
#'   \item{`ic_list`}{all initial contacts.}
#'   \item{`steps_per_wb`}{`wb_id` and `n_steps` per datapoint.}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' ds = mobgap_dataset("path/to/tvs", type = "free_living",
#'                     reference_system = "INDIP",
#'                     missing_reference_error_type = "skip")
#' res = mobgap_reference_summary(ds)
#' res$totals
#' }
mobgap_reference_summary = function(dataset, skip_errors = TRUE) {
  dps = mobgap_datapoints(dataset)
  tag = function(df, id) {
    if (is.null(df) || nrow(df) == 0) {
      return(NULL)
    }
    cbind(id[rep(1L, nrow(df)), , drop = FALSE], df, row.names = NULL)
  }
  rows = lapply(dps, function(dp) {
    id = mobgap_group_label(dp)
    ref = tryCatch(mobgap_reference(dp), error = function(e) {
      if (!skip_errors) stop(e)
      warning("Skipping datapoint (", paste(unlist(id), collapse = "/"),
              "): ", conditionMessage(e), call. = FALSE)
      NULL
    })
    if (is.null(ref)) {
      return(NULL)
    }
    spw = mobgap_steps_per_wb(ref)
    wb = ref$wb_list
    if (!is.null(wb) && nrow(wb) > 0) {
      wb$n_steps = spw$n_steps[match(wb$wb_id, spw$wb_id)]
    }
    list(
      totals = cbind(id, n_wb = if (is.null(wb)) 0L else nrow(wb),
                     total_steps = mobgap_total_steps(ref)),
      wb_list = tag(wb, id),
      ic_list = tag(ref$ic_list, id),
      steps_per_wb = tag(spw, id)
    )
  })
  rows = Filter(Negate(is.null), rows)
  bind = function(nm) {
    parts = Filter(Negate(is.null), lapply(rows, `[[`, nm))
    if (length(parts) == 0) NULL else do.call(rbind, parts)
  }
  list(
    totals = bind("totals"),
    wb_list = bind("wb_list"),
    ic_list = bind("ic_list"),
    steps_per_wb = bind("steps_per_wb")
  )
}
