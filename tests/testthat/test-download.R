test_that("TVS cohort table is complete", {
  x = mobgap_tvs_cohorts()
  expect_equal(x$cohort, c("HA", "MS", "PFF", "PD", "COPD", "CHF"))
  expect_true(all(grepl("^https://zenodo.org/records/15861907/files/", x$url)))
  expect_true(all(nchar(x$md5) == 32))
  expect_true(all(x$size_gb > 5))
})

test_that("download verifies checksums and unzips (local file)", {
  src = withr::local_tempdir()
  writeLines("hello", file.path(src, "a.txt"))
  zipfile = file.path(src, "x.zip")
  withr::with_dir(src, utils::zip(zipfile, "a.txt", flags = "-q"))
  md5 = unname(tools::md5sum(zipfile))
  dest = withr::local_tempdir()
  out = file.path(dest, "x.zip")
  mobgap:::download_verified(paste0("file://", zipfile), out, md5, quiet = TRUE)
  expect_true(file.exists(out))
  # an existing valid file is reused
  expect_message(mobgap:::download_verified("file:///nonexistent", out, md5),
                 "Using existing")
  expect_error(mobgap:::download_verified(paste0("file://", zipfile),
                                          file.path(dest, "y.zip"),
                                          "0123456789abcdef0123456789abcdef",
                                          quiet = TRUE),
               "checksum")
  expect_true(mobgap:::md5_matches(out, paste0("md5:", md5)))
})

test_that("download validates cohorts", {
  expect_error(mobgap_tvs_download(tempdir(), cohorts = "XX"), "Unknown")
})
