#' Mobilise-D Technical Validation Study Files on Zenodo
#'
#' The TVS dataset (Zenodo record 15861907, version 1.0.2,
#' <https://doi.org/10.5281/zenodo.15861907>) is split into one zip file per
#' cohort. **The files are large (7-11 GB each, about 58 GB in total) and are
#' licensed CC-BY-NC-ND 4.0**; make sure your use complies with the license.
#'
#' @return A data frame with `cohort`, `file`, `size_gb`, `md5` and `url`.
#' @export
#'
#' @examples
#' mobgap_tvs_cohorts()
mobgap_tvs_cohorts = function() {
  base = "https://zenodo.org/records/15861907/files/"
  df = data.frame(
    cohort = c("HA", "MS", "PFF", "PD", "COPD", "CHF"),
    size_bytes = c(11409814307, 10165842873, 9927766100, 9611198624,
                   10109737085, 7131374486),
    md5 = c("6c4b6a4eb7cf90d779344137c364e72c",
            "eb098ce181d4ccadbb92035e51ddbf1a",
            "f015acc7ffca3ff795628ae69b1d1453",
            "3c19f9114a2f172075c92bc7722d9fbe",
            "b86af13bf4f4c065b2e1d1465d7e5096",
            "0d7fa6d65773ca2436e1ebdc95740665"),
    stringsAsFactors = FALSE
  )
  df$file = paste0(df$cohort, ".zip")
  df$size_gb = round(df$size_bytes / 1e9, 1)
  df$url = paste0(base, df$file, "?download=1")
  df[, c("cohort", "file", "size_gb", "md5", "url")]
}

#' Download the Mobilise-D TVS Data
#'
#' Downloads cohort zip files from Zenodo (record 15861907), verifies their MD5
#' checksums, and unzips them into `dest`, giving the folder layout
#' `dest/<cohort>/<participant>/{Laboratory,Free-living}/data.mat` that
#' `mobgap`'s TVS datasets expect. The returned path is what you pass as
#' `path` to [mobgap_dataset()] or [mobgap_wrist_dataset()].
#'
#' Each cohort is 7-11 GB, so start with one (e.g. `"HA"`) and make sure you
#' have the disk space (zip plus unzipped). The data are licensed
#' CC-BY-NC-ND 4.0. An existing, valid zip is reused, so an interrupted
#' download can be restarted by calling the function again.
#'
#' @param dest Folder to put the data in (created if needed).
#' @param cohorts Which cohorts: any of `"HA"`, `"MS"`, `"PFF"`, `"PD"`,
#' `"COPD"`, `"CHF"`.
#' @param unzip Unzip after downloading.
#' @param keep_zip Keep the zip files after unzipping.
#' @param confirm Ask before downloading (only in interactive sessions).
#' @param quiet Suppress progress output.
#'
#' @return Invisibly, the normalized `dest` path.
#' @export
#'
#' @examples
#' \dontrun{
#' path = mobgap_tvs_download("~/mobgap_tvs", cohorts = "HA")
#' ds = mobgap_dataset(path, type = "free_living", reference_system = "INDIP",
#'                     missing_reference_error_type = "skip")
#' }
mobgap_tvs_download = function(dest, cohorts = "HA", unzip = TRUE,
                               keep_zip = FALSE, confirm = TRUE,
                               quiet = FALSE) {
  info = mobgap_tvs_cohorts()
  cohorts = toupper(cohorts)
  bad = setdiff(cohorts, info$cohort)
  if (length(bad) > 0) {
    stop("Unknown cohort(s): ", paste(bad, collapse = ", "),
         ". Choose from: ", paste(info$cohort, collapse = ", "), call. = FALSE)
  }
  info = info[match(cohorts, info$cohort), ]
  if (confirm && interactive()) {
    ok = utils::askYesNo(sprintf(
      "Download %.1f GB (CC-BY-NC-ND 4.0) to %s?", sum(info$size_gb), dest),
      default = FALSE)
    if (!isTRUE(ok)) {
      stop("Download cancelled.", call. = FALSE)
    }
  }
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  dest = normalizePath(dest, winslash = "/")
  for (i in seq_len(nrow(info))) {
    zipfile = file.path(dest, info$file[i])
    download_verified(info$url[i], zipfile, info$md5[i], quiet = quiet)
    if (unzip) {
      if (!quiet) message("Unzipping ", info$file[i], " ...")
      utils::unzip(zipfile, exdir = dest)
      if (!keep_zip) unlink(zipfile)
    }
  }
  invisible(dest)
}

download_verified = function(url, destfile, md5, quiet = FALSE) {
  if (file.exists(destfile) && md5_matches(destfile, md5)) {
    if (!quiet) message("Using existing ", basename(destfile))
    return(invisible(destfile))
  }
  old = options(timeout = max(getOption("timeout"), 7 * 24 * 3600))
  on.exit(options(old), add = TRUE)
  status = utils::download.file(url, destfile, mode = "wb", quiet = quiet,
                                method = "libcurl")
  if (status != 0 || !md5_matches(destfile, md5)) {
    stop("Download of ", basename(destfile), " failed or checksum mismatch.",
         call. = FALSE)
  }
  invisible(destfile)
}

md5_matches = function(file, md5) {
  unname(tools::md5sum(file)) == sub("^md5:", "", md5)
}
