#' Sensor Axis Orientation Helpers
#'
#' Step-counting and gait models that read raw `x`/`y`/`z` channels are
#' generally **not** rotation invariant, so the orientation of the sensor
#' relative to the body (device axes, strap rotation, side of the body)
#' matters. These helpers summarise gravity per axis and apply the 24 proper
#' axis rotations (signed axis permutations with determinant +1).
#'
#' @section Orientation in Mobilise-D data:
#' (Findings reported from an analysis of the public INDIP sample release; see
#' `vignette("mobgap")`.) In one right-wrist recording, gravity lay almost
#' entirely on `x` (mean about +1 g), while several step-model training sets
#' have gravity on `y` or spread across axes. A `stepcount`-style model applied
#' as-is undercounted by about 31% (124 vs 180 steps), and one of the 24
#' rotations removed most of that bias. That rotation was chosen using the
#' answers on a single person, so it is *not* evidence of accuracy and should
#' not be reused without validation on independent participants. Prefer
#' rotation-invariant inputs (e.g. vector magnitude) or models trained across
#' rotations. The reference publication (Mazza et al., BMJ Open 2021) defines
#' a device frame for the lower-back unit only and gives no axis definition for
#' the wrist module.
#'
#' @param data A data frame with `acc_x`, `acc_y`, `acc_z` columns (as from
#' [mobgap_imu_data()]) or `x`, `y`, `z` columns (as from [mobgap_to_acc()]).
#' @param rotation A 3 x 3 rotation matrix (`new = R %*% old`), or the index
#' (1-24) of a rotation from `mobgap_axis_rotations()`.
#'
#' @return `mobgap_gravity_means()` returns the mean of each axis (in the input
#' units); `mobgap_axis_rotations()` returns a list of 24 matrices;
#' `mobgap_rotate_acc()` returns `data` with rotated axis columns.
#' @export
#' @rdname mobgap_orientation
#' @examples
#' df = data.frame(x = 1, y = 0.2, z = 0)
#' mobgap_gravity_means(df)
#' # new x = -old z, new y = old x, new z = -old y
#' R = rbind(c(0, 0, -1), c(1, 0, 0), c(0, -1, 0))
#' mobgap_rotate_acc(df, R)
#' length(mobgap_axis_rotations())
mobgap_gravity_means = function(data) {
  cols = acc_columns(data)
  vapply(cols, function(cn) mean(data[[cn]], na.rm = TRUE), numeric(1))
}

#' @export
#' @rdname mobgap_orientation
mobgap_axis_rotations = function() {
  perms = list(c(1, 2, 3), c(1, 3, 2), c(2, 1, 3),
               c(2, 3, 1), c(3, 1, 2), c(3, 2, 1))
  signs = expand.grid(c(1, -1), c(1, -1), c(1, -1))
  out = list()
  for (p in perms) {
    for (i in seq_len(nrow(signs))) {
      m = matrix(0, 3, 3)
      for (r in 1:3) {
        m[r, p[r]] = signs[i, r]
      }
      if (round(det(m)) == 1) {
        out[[length(out) + 1]] = m
      }
    }
  }
  out
}

#' @export
#' @rdname mobgap_orientation
mobgap_rotate_acc = function(data, rotation) {
  cols = acc_columns(data)
  if (is.numeric(rotation) && length(rotation) == 1) {
    rotation = mobgap_axis_rotations()[[rotation]]
  }
  assertthat::assert_that(is.matrix(rotation), all(dim(rotation) == 3),
                          abs(det(rotation) - 1) < 1e-8)
  new = as.matrix(data[, cols]) %*% t(rotation)
  data[, cols] = new
  data
}

acc_columns = function(data) {
  assertthat::assert_that(is.data.frame(data))
  for (cols in list(c("acc_x", "acc_y", "acc_z"), c("x", "y", "z"))) {
    if (all(cols %in% names(data))) {
      return(cols)
    }
  }
  stop("Need `acc_x`/`acc_y`/`acc_z` or `x`/`y`/`z` columns.", call. = FALSE)
}
