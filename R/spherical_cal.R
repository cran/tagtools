#' Deduce the calibration constants
#'
#' This function is used to deduce the calibration constants for a triaxial field sensor, such as an accelerometer or magnetometer, based on movement data. This can be used to do a 'bench' calibration of a sensor.
#'
#' The function reports the residual and the axial balance of the data.
#' A low residual e.g., <5\% indicates that the data can be calibrated
#' well and there is not much noise.
#' The axial balance indicates whether the movement in X is
#' suitable for data-driven calibration. If the movement covers all
#' directions fairly equally, the axial balance will be high.
#' A balance <20 \% may lead to unreliable calibration.
#' For bench calibrations, a high axial balance is achieved by
#' rotating the sensor through the full 3-dimensions.
#' Sampling rate and frame of Y are the same as the input data so
#' Y has the same size as X. The units of Y are the same as the units
#' used for n. If n is not specified, the units of Y are the same as
#' for the input data. It is a good idea to low-pass filter and/or
#' remove outliers from the sensor data before using this function
#' to reduce errors from specific acceleration and sensor noise.
#' @param X The segment of triaxial sensor data to calibrate. It must be a 3-column matrix. X can come from any triaxial field sensor and can be in any unit and any frame.
#' @param n The target field magnitude e.g., 9.81 for accelerometer data using m/s^2 as the unit.
#' @param method An optional string selecting the type of calibration. The default is to calibrate for offset and scaling only. Other options are: 'gain' adjust gain of axes 2 and 3 relative to 1, or 'cross' adjust gain and remove cross-axis correlations
#' @return A list with 2 elements:
#' \itemize{
#'  \item{\strong{Y: }} The matrix of converted sensor values. These will have the same units as for input argument n. The size of Y is the same as the size of X and it has the same frame and sampling rate.
#'  \item{\strong{G: }} The calibration structure containing fields: G.poly is a matrix of polynomials. The first column of G.poly is the three scale factors applied to the columns of X. The second column is the offset added to each column of X after scaling. G.cross is a 3x3 matrix of cross-factors. If there are no cross-terms, this is the identity matrix. Off-axis terms correct for cross-axis sensitivity.
#' }
#' A message will also be printed to the screen presenting
#' @note This function uses a Simplex search for optimal calibration parameters and so can be slow if the data size is large.
#' For this reason it is most suitable for bench calibrations rather than
#' field data. This function is only usable for field sensors.
#' It will not work for gyroscope data.
#' @export
#' @examples
#' p <- spherical_cal(harbor_seal$A$data)
#'

spherical_cal <- function(X, n = NULL, method = NULL) {
  G <- c()
  Y <- c()
  # remove any rows in X with NaNs
  X <- stats::na.omit(X)
  nv1 <- 3 # number of variables for offset
  nv2 <- 5 # number of variables for gain and offset
  nv3 <- 8 # number of variables for gain, offset and cross

  # start by estimating offsets using linear least squares. This ensures
  # that the iterative search starts fairly close to a solution.
  bsq <- rowSums(X^2)
  XX <- cbind(2 * X, matrix(1, nrow(X), 1))
  R <- t(XX) %*% as.matrix(XX)
  P <- colSums(pracma::repmat(as.matrix(bsq), 1, 4) * XX)
  H <- -solve(R) %*% as.matrix(P)
  offs <- H[1:3]
  X <- X + pracma::repmat(t(offs), nrow(X), 1)
  # now try up to three calibration scenarios using simplex search
  C <- matrix(0, nv3, 3)
  C[1:nv1, 1] <- stats::optim(matrix(0, nv1, 1), (function(c) ccost(as.matrix(c), X)))$par # offset only cal
  if (identical(method, "gain") | identical(method, "cross")) {
    C[1:nv2, 2] <- stats::optim(C[1:nv2, 1], (function(c) ccost(as.matrix(c), X)))$par # offset and gain cal
  }
  if (identical(method, "cross")) {
    C[, 3] <- stats::optim(C[, 2], (function(c) ccost(as.matrix(c), X)))$par # offset, gain and cross cal
  }
  k <- which.min(ccost(C, X)) # pick the best performer
  C <- as.matrix(C[, k])
  listYC <- appcal(X, C) # apply the calibration
  Y <- listYC$Y
  C <- listYC$C
  nn <- norm2(Y)
  G$residual <- sprintf("%2.1f ", 100 * stats::sd(nn) / mean(nn))
  R <- t(Y) %*% Y
  G$axial_balance <- sprintf("%2.1f", 100 / pracma::cond(R))
  if (length(n) != 0) {
    sf <- n / mean(nn)
    Y <- Y * sf
  } else {
    sf <- 1
  }
  G$poly <- cbind((1 + C[, 2]) * sf, ((offs * (1 + C[, 2])) + C[, 1]) * sf)
  G$cross <- 0.5 * rbind(c(2, C[1, 3], C[3, 3]), c(C[1, 3], 2, C[2, 3]), c(C[3, 3], C[2, 3], 2))
  return(list(Y = Y, G = G))
}

ccost <- function(C, X) {
  for (k in 1:ncol(C)) {
    n <- sqrt(rowSums(appcal(X, C[, k])$Y^2))
    p <- stats::sd(n) / mean(n)
  }
  return(p)
}

appcal <- function(X, C) {
  # C is a vector of up to 8 parameters
  # Only the first of these may be provided - the remainder are 0.
  C[length(C) + 1:8] <- 0
  C <- c(C[1:3], 0, C[4:8]) # add the col1 fixed gain of 0
  C <- matrix(C, nrow = 3)
  # 	At this point:
  # 	C(:,1) are the offsets for each column of X
  # 	C(:,2) are the gain adjustments for each column of X (column 1 is always 0)
  # 	C(:,3) are the cross terms
  Y <- X %*% diag(1 + C[, 2]) + pracma::repmat(t(C[, 1]), nrow(X), 1)
  xcm <- 0.5 * rbind(c(2, C[1, 3], C[3, 3]), c(C[1, 3], 2, C[2, 3]), c(C[3, 3], C[2, 3], 2))
  Y <- Y %*% xcm
  return(list(Y = Y, C = C))
}