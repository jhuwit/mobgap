#' Check the `mobgap` Python Module
#'
#' @return `have_mobgap()` and `mobgap_check()` return a logical;
#' `mobgap_version()` returns the installed version string.
#' @export
#' @rdname mobgap_setup
#' @examples
#' \dontrun{
#' if (have_mobgap()) {
#'   mobgap_version()
#' }
#' }
have_mobgap = function() {
  reticulate::py_module_available("mobgap")
}

#' @export
#' @rdname mobgap_setup
mobgap_check = function() {
  v = try(mobgap_version(), silent = TRUE)
  have_mobgap() && !inherits(v, "try-error") && length(v) > 0
}

#' @export
#' @rdname mobgap_setup
mobgap_version = function() {
  if (!have_mobgap()) {
    stop("mobgap is not installed!")
  }
  df = reticulate::py_list_packages()
  df$version[df$package == "mobgap"]
}
