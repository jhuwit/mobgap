# Python modules, loaded lazily on first use (see `reticulate::import(delay_load)`)
py_modules = new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # declare Python requirements for reticulate's managed environment
  reticulate::py_require(c("mobgap", "pandas"), python_version = ">=3.10")
  # delay-load the Python modules used by this package
  py_modules$mobgap = reticulate::import("mobgap", delay_load = TRUE,
                                         convert = FALSE)
  py_modules$data = reticulate::import("mobgap.data", delay_load = TRUE,
                                       convert = FALSE)
  invisible()
}
