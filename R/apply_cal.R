#' Implement a calibration on tag sensor data
#'
#' Given an appropriate set of calibration constants and information, this function will apply the calibration procedure to a tag sensor data set. Cal fields currently supported are: poly, cross, map, tcomp, tref
#'
#' @param X A tag sensor data list, or a matrix or vector containing tag sensor data
#' @param cal A calibration list for the data in X from, for example, spherical_cal.
#' @param Tempr a tag sensor data list or a vector of temperature measurements for use in temperature compensation.
#' If Tempr is not a sensor data list, it must be the same size and sampling rate as the data in \code{X}.
#' Tempr is only required if there is a tcomp item in the \code{cal} list.
#'
#' @return A tag sensor data structure (or a matrix or vector, if X was a matrix or vector) with the calibration implemented. Data size and sampling rate are the same as for the input data \code{X}, but units may have changed.
#' @export
#' @examples
#' A_cal <- apply_cal(harbor_seal$A,spherical_cal(harbor_seal$A$data))
#' 

apply_cal <- function(X, cal, Tempr = NULL) {
  if (!is.list(cal)) {
    stop("Input argument cal must be a calibration list (for example, from spherical_cal)")
  }

  if (is.list(X)) {
    x <- X$data
    if (!is.matrix(x)) {
      x <- matrix(x, ncol = 1)
    }
    if (length(x) == 0) {
      stop("No data found in input X")
    }
  } else {
    x <- X
  }

  if (is.list(Tempr)) {
    Tempr <- Tempr$data
    if (!is.matrix(Tempr)) {
      Tempr <- matrix(Tempr, ncol = 1)
    }
  }

  if ("poly" %in% names(cal)) {
    p <- cal$poly
    if (nrow(p) != ncol(x)) {
      em <- paste("Calibration polynomial must have",
        ncol(x), " rows to match the number of columns in input data X",
        sep = ""
      )
      stop(em)
    }
    x <- x * matrix(t(p[, 1]), nrow = nrow(x), ncol = nrow(p), byrow = TRUE) +
      matrix(t(p[, 2]), nrow = nrow(x), ncol = nrow(p), byrow = TRUE)
    if (is.list(X)) {
      X$cal_poly <- cal$poly
    }
  } # end of "if poly"

  if (!is.null(Tempr) & "tcomp" %in% names(cal)) {
    if (nrow(Tempr) == nrow(x)) {
      # TODO interp Tempr to match X
      if (!("tref" %in% names(cal))) {
        tref <- 20
      } else {
        tref <- cal$tref
      }
      if (length(cal$tcomp) == ncol(x)) {
        x <- x + (Tempr - tref) * matrix(cal$tcomp, nrow = 1)
      } else {
        if (ncol(x) == 1) {
          M <- stats::poly(Tempr, length(cal$tcomp), raw = TRUE)
          M <- M[, c(ncol(M):1)]
          x <- x + M %*% matrix(cal$tcomp, ncol = 1)
        }
      }
      if (is.list(X)) {
        X$cal_tcomp <- cal$tcomp
        X$cal_tref <- tref
      }
    }
  } # end if Tempr

  if ("cross" %in% names(cal)) {
    x <- x %*% cal$cross
    if (is.list(X)) {
      X$cal_cross <- cal$cross
    }
  }

  if ("map" %in% names(cal)) {
    x <- x %*% cal$map
    if (is.list(X)) {
      X$cal_map <- cal$map
    }
  }

  if (!is.list(X)) {
    X <- x
    return(X)
  }

  X$data <- x
  X$frame <- "tag"

  if ("unit" %in% names(cal)) {
    X$source_unit <- X$unit
    X$source_unit_name <- X$unit_name
    X$source_unit_label <- X$unit_label
    X$unit <- cal$unit
    X$unit_name <- cal$unit_name
    X$unit_label <- cal$unit_label
  }

  if ("name" %in% names(cal)) {
    X$cal_name <- cal$name
  }

  if (!("history" %in% names(X)) | is.null(X$history)) {
    X$history <- "apply_cal"
  } else {
    X$history <- c(X$history, "apply_cal")
  }
  return(X)
}