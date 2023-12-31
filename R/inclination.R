#' Estimate the inclination angle
#'
#' This function is used to estimate the local magnetic field vector inclination angle directly from acceleration and magnetic field measurements.
#'
#' @param A The accelerometer data structure or signal matrix, A = [ax,ay,az] in any consistent unit (e.g., in g or m/s2). A can be in any frame.
#' @param M The magnetometer data structure or signal matrix, M = [mx,my,mz] in any consistent unit (e.g., in uT or Gauss). M must be in the same frame as A.
#' @param fc (optional) The cut-off frequency of a low-pass filter to apply to A and M before computing the inclination angle. The filter cut-off frequency is with respect to 1=Nyquist frequency. Filtering adds no group delay. If fc is not specified, no filtering is performed.
#' @return The magnetic field inclination angle in radians.
#' @note Output sampling rate is the same as the input sampling rate.
#' @note Frame: This function assumes a [north,east,up] navigation frame and a [forward,right,up] local frame. In these frames, the magnetic field vector has a positive inclination angle when it points below the horizon. Other frames can be used as long as A and M are in the same frame however the interpretation of incl will differ accordingly.
#' @export
#' @examples 
#' A <- matrix(c(1, -0.5, 0.1, 0.8, -0.2, 0.6, 0.5, -0.9, -0.7),
#'   byrow = TRUE, nrow = 3, ncol = 3
#' )
#' M <- matrix(c(1.3, -0.25, 0.16, 0.78, -0.3, 0.5, 0.5, -0.49, -0.6),
#'   byrow = TRUE, nrow = 3, ncol = 3
#' )
#' incl <- inclination(A, M)
#' 
inclination <- function(A, M, fc = NULL) {
  # input checks-----------------------------------------------------------
  if (is.list(A)) {
    A <- A$data
  }
  if (is.list(M)) {
    M <- M$data
  }
  if (missing(M)) {
    stop("matrices for both A and M must be defined")
  }
  # catch the case of a single acceleration vector
  if (min(c(nrow(A), ncol(A))) == 1) {
    stop("A must be an acceleration matrix")
  }
  # catch the case of a single magnetometer vector
  if (min(c(nrow(M), ncol(M))) == 1) {
    stop("M must be a magnetometer matrix")
  }
  if (nrow(M) != nrow(A)) {
    stop("A and M must have the same number of rows\n")
    incl <- vector(mode = "numeric", length = 0)
  }
  if (!is.null(fc)) {
    A <- fir_nodelay(A, round(8 / fc), fc)
    M <- fir_nodelay(M, round(8 / fc), fc)
  }
  # compute magnetic field intensity
  vm <- sqrt(rowSums(M^2))
  va <- sqrt(rowSums(A^2))
  incl <- -Re(asin(rowSums(A*M) / (va*vm)))
  
  return(incl)
}
