# remove uv lock files created while testing (R CMD check detritus NOTE)
uv_snapshot = mobgap::mobgap_uv_snapshot()
withr::defer(mobgap::mobgap_cleanup_uv(uv_snapshot), teardown_env())
