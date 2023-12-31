#' Pitch and roll from acceleration
#'
#' Pitch and roll estimation from triaxial accelerometer data. This is a non-iterative estimator with |pitch| constrained to <= 90 degrees. The pitch and roll estimates give the least-square-norm error between A and the A-vector that would be measured at the estimated pitch and roll. If A is in the animal frame, the resulting pitch and roll define the orientation of the animal with respect to its navigation frame. If A is in the tag frame, the pitch and roll will define the tag orientation with respect to its navigation frame.
#'
#' @param A An nx3 acceleration matrix with columns [ax ay az] or acceleration sensor list (e.g., from readtag.R). Acceleration can be in any consistent unit, e.g., g or m/s^2.
#' @param sampling_rate (optional) The sampling rate of the sensor data in Hz (samples per second). This is only needed if filtering is required. If A is a sensor data list, sampling_rate is obtained from its metadata (A$sampling_rate).
#' @param fc (optional) The cut-off frequency of a low-pass filter to apply to A before computing pitch and roll. The filter cut-off frequency is in Hertz. The filter length is 4*sampling_rate/fc. Filtering adds no group delay. If fc is not specified, no filtering is performed.
#' @seealso \code{\link{m2h}}
#' @export
#' @return A list with 2 elements:
#' \itemize{
#'  \item{\strong{p: }} The pitch estimate in radians
#'  \item{\strong{r: }} The roll estimate in radians
#' }
#' @note Output sampling rate is the same as the input sampling rate.
#' @note Frame: This function assumes a [north,east,up] navigation frame and a [forward,right,up] local frame. In these frames, a positive pitch angle is an anti-clockwise rotation around the y-axis. A positive roll angle is a clockwise rotation around the x-axis. A descending animal will have a negative pitch angle while an animal rolled with its right side up will have a positive roll angle.
#' @export
#' @examples
#' samplematrix <- matrix(c(0.77, -0.6, -0.22, 0.45, -0.32, 0.99, 0.2, -0.56, 0.5),
#'   byrow = TRUE, nrow = 3
#' )
#' list <- a2pr(samplematrix)
#' 

a2pr <- function(A, sampling_rate = NULL, fc = NULL) {
  # input checks-----------------------------------------------------------
  if (is.list(A)) {
    sampling_rate <- A$sampling_rate
    A <- A$data
  }

  # catch the case of a single acceleration vector
  if (min(c(nrow(A), ncol(A))) == 1) {
    A <- matrix(A, nrow = 1)
  }
  if (!is.null(fc)) {
    A <- fir_nodelay(
      A, round(4 / fc),
      fc / (sampling_rate / 2)
    )
  }
  v <- sqrt(rowSums(A^2))
  # compute pitch and roll
  p <- asin(A[, 1] / v)
  r <- Re(atan2(A[, 2], A[, 3]))
  return(list(p = p, r = r))
}
