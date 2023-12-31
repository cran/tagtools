#' Rotate triaxial vector measurements
#'
#' This function is used to rotate triaxial vector measurements from one frame to another.
#' @param V is a tag data structure, a 3-element vector or a 3-column matrix of vector measurements for example V could be from an accelerometer or magnetometer.
#' @param Q is the rotation matrix. If Q is a single 3x3 matrix, the same rotation is applied to all vectors in V. If Q is a 3x3xn matrix where n is the number of rows in V, a different transformation given by Q[,, k] is applied to each row of V.
#' @return The rotated vector or matrix with the same size as the input V.
#' @note Frame: This function makes no assumptions about frame.
#' @export
#' @examples
#' x <- (pi / 180) * matrix(c(25, -60, 33), ncol = 3)
#' Q <- euler2rotmat(x[, 1], x[, 2], x[, 3])
#' V <- rotate_vecs(c(0.77, -0.6, -0.22), Q)
#'
rotate_vecs <- function(V, Q) {
  if (missing(Q)) {
    stop("inputs for all arguments are required")
  }
  if (is.list(V)) {
    list_out <- TRUE
    V0 <- V
    V <- V$data
  } else {
    list_out <- FALSE
  }
  if (is.vector(V)) {
    V <- matrix(V, nrow = 1)
  }
  if (ncol(V) == 1) {
    V <- t(V)
  }
  if (length(dim(Q))) {
    V <- V %*% t(Q)
  } else {
    for (k in 1:nrow(V)) {
      V[k, ] <- V[k, ] %*% t(Q[, , k])
    }
  }
  if (list_out) {
    V0$data <- V
    V <- V0
  }
  return(V)
}
