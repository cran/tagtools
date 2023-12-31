#' Compute MSA
#'
#' This function is used to compute the Minimum Specific Acceleration (MSA). This is the absolute value of the norm of the acceleration minus 1 g, i.e., the amount that the acceleration differs from the gravity value. This is always equal to or less than the actual specific acceleration if A is correctly calibrated.
#'
#' Possible input combinations: msa(A) if A is a list, msa(A,ref) if A is a matrix.
#' @param A An nx3 acceleration matrix with columns [ax ay az], or a tag sensor data list containing acceleration data. Acceleration can be in any consistent unit, e.g., g or m/s^2. A can be in any frame as the MSA is rotation independent.
#' @param ref The gravitational field strength in the same units as A. This is not needed if A is a sensor structure. If A is a matrix, the default value is 9.81 which assumes that A is in m/s^2. Use ref = 1 if the unit of A is g.
#' @return A column vector of MSA with the same number of rows as A, or a tag sensor data list (output matches input). m has the same units as A.
#' @note  See Simon et al. (2012) Journal of Experimental Biology, 215:3786-3798.
#' @export
#' @seealso \code{\link{odba}}, \code{\link{njerk}}
#' @examples
#' sampleMatrix <- matrix(c(1, -0.5, 0.1, 0.8, -0.2, 0.6, 0.5, -0.9, -0.7),
#'   byrow = TRUE, nrow = 3, ncol = 3
#' )
#' msa(A = sampleMatrix, ref = 1)
msa <- function(A, ref) {
  # input checks-----------------------------------------------------------
  if (missing(ref)) {
    ref <- 9.81
  }
  if (is.list(A)) {
    if (length(A$meta_conv) > 0) {
      ref <- ref * A$meta_conv
    }
    if (utils::hasName(A, "data")) {
      A0 <- A
      A <- A$data
    } else {
      # try to coerce data frame to matrix
      A <- as.matrix(A)
    }
  }

  # catch the case of a single acceleration vector
  if (min(c(nrow(A), ncol(A))) == 1) {
    stop("A must be an acceleration matrix")
  }
  m <- abs(sqrt(rowSums(A^2)) - ref)
  if (exists("A0", inherits = FALSE)) {
    M <- A0
    M$data <- m
    M$creation_date <- Sys.time()
    M$type <- "msa"
    M$full_name <- "minimum specific acceleration"
    M$description <- M$full_name
    M$column_name <- "msa"
    return(M)
  } else {
    return(m)
  }
}
