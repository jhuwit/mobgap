#' Clean Up `uv` Temporary Files
#'
#' `reticulate` uses `uv` to build the managed Python environment, which can
#' leave `uv-*.lock` files in the session temporary directory. R CMD check
#' reports these as detritus. This removes lock files that appeared after a
#' snapshot taken with [mobgap_uv_snapshot()], so files from other running
#' processes are never touched.
#'
#' @param snapshot Output of [mobgap_uv_snapshot()]. If `NULL`, all `uv-*.lock`
#' files in the temporary directories are removed.
#'
#' @return Invisibly, the paths removed.
#' @export
#' @rdname mobgap_cleanup_uv
#' @examples
#' snap = mobgap_uv_snapshot()
#' mobgap_cleanup_uv(snap)
mobgap_cleanup_uv = function(snapshot = NULL) {
  files = mobgap_uv_files()
  if (!is.null(snapshot)) {
    files = setdiff(files, snapshot)
  }
  files = files[file.exists(files)]
  unlink(files, recursive = TRUE, force = TRUE)
  invisible(files)
}

#' @export
#' @rdname mobgap_cleanup_uv
mobgap_uv_snapshot = function() {
  mobgap_uv_files()
}

mobgap_uv_files = function() {
  dirs = unique(c(tempdir(), dirname(tempdir())))
  unlist(lapply(dirs, function(d) {
    list.files(d, pattern = "^uv-.*\\.lock$", full.names = TRUE,
               all.files = TRUE)
  }), use.names = FALSE)
}
