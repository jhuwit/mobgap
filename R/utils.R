mobgap_import = function(module = "mobgap", convert = FALSE) {
  if (!convert) {
    key = sub("^mobgap\\.?", "", module)
    key = if (nzchar(key)) key else "mobgap"
    if (!is.null(py_modules[[key]])) {
      return(py_modules[[key]])
    }
  }
  reticulate::import(module, convert = convert)
}

py_to_r_if_needed = function(x) {
  if (inherits(x, "python.builtin.object")) {
    reticulate::py_to_r(x)
  } else {
    x
  }
}

# Convert a pandas object to an R data.frame, moving the (Multi)Index
# (e.g. `wb_id`, `step_id`) into ordinary columns.
mobgap_df_to_r = function(x) {
  if (is.null(x) || !inherits(x, "python.builtin.object")) {
    return(x)
  }
  if (reticulate::py_has_attr(x, "reset_index")) {
    x = x$reset_index()
  }
  out = py_to_r_if_needed(x)
  if (is.data.frame(out)) {
    rownames(out) = NULL
  }
  out
}

# Convert a python dict / namedtuple to a named R list.
mobgap_dict_to_r = function(x) {
  if (reticulate::py_has_attr(x, "_asdict")) {
    x = x$`_asdict`()
  }
  py_to_r_if_needed(x)
}

null_or_string = function(x) {
  is.null(x) || assertthat::is.string(x)
}

mobgap_py_list = function(x) {
  reticulate::iterate(x, simplify = FALSE)
}
