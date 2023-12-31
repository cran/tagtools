#' Make a rotation (or direction cosine) matrix
#'
#' This function is used to make a rotation (or direction cosine) matrix out of sets of Euler angles, pitch, roll, and heading.
#' @param p The pitch angle in radians.
#' @param r The roll angle in radians.
#' @param h The heading or yaw angle in radians.
#' @return One or more 3x3 rotation matrices. If p, r, and h are all scalars, Q is a 3x3 matrix, Q = H %*% P %*% R where H, P and R are the cannonical rotation matrices corresponding to the yaw, pitch and roll rotations, respectively. To rotate a vector or matrix of triaxial measurements, pre-multiply by Q. If p, r or h contain multiple values, Q is a 3-dimensional matrix with size 3x3xn where n is the number of Euler angle triples that are input. To access the k'th rotation matrix in Q use drop(Q[,,k]).
#' @export
#' @examples vec1 <- matrix(c(1:10), nrow = 10)
#' vec2 <- matrix(c(11:20), nrow = 10)
#' vec3 <- matrix(c(21:30), nrow = 10)
#' Q <- euler2rotmat(p = vec1, r = vec2, h = vec3)
euler2rotmat <- function(p, r, h) {
  # input checks-----------------------------------------------------------
  if (nargs() == 1 | nargs() == 2) {
    stop("Your input must be three distinct column vectors (p, r, h).")
  }
  n <- c(length(p), length(r), length(h))
  nn <- max(n)
  if (n[1] < nn) {
    p <- rep(p[1], nn)
  }
  if (n[2] < nn) {
    r <- rep(r[1], nn)
  }
  if (n[3] < nn) {
    h <- rep(h[1], nn)
  }
  cp <- cos(p)
  sp <- sin(p)
  cr <- cos(r)
  sr <- sin(r)
  ch <- cos(h)
  sh <- sin(h)
  Q <- replicate(nn, matrix(0, nrow = 3, ncol = 3))
  for (k in 1:nn) {
    P <- matrix(c(cp[k], 0, -sp[k], 0, 1, 0, sp[k], 0, cp[k]), byrow = TRUE, nrow = 3)
    R <- matrix(c(1, 0, 0, 0, cr[k], -sr[k], 0, sr[k], cr[k]), byrow = TRUE, nrow = 3)
    H <- matrix(c(ch[k], -sh[k], 0, sh[k], ch[k], 0, 0, 0, 1), byrow = TRUE, nrow = 3)
    Q[, , k] <- H %*% P %*% R
  }
  Q <- drop(Q)
  return(Q)
}