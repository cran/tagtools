#' Compute the norm-jerk
#'
#' This function is used to compute the norm-jerk from triaxial acceleration data.
#' @param A A tag sensor data list or a nx3 acceleration matrix with columns [ax ay az]. Acceleration can be in any consistent unit, e.g., g or m/s^2. A can be in any frame as the norm-jerk is rotation independent. A must have at least 2 rows (i.e., n>=2).
#' @param sampling_rate The sampling rate in Hz of the acceleration signals. This is used to estimate the differential by a first-order difference.
#' @return The norm-jerk from triaxial acceleration data in the form of a column vector with the same number of rows as in A, or a tag sensor data structure (if the input A was one). The norm-jerk is ||dA/dt||, where ||x|| is the 2-norm of x, i.e., the square-root of the sum of the squares of each axis. If the unit of A is m/s^2, the norm-jerk has unit m/s^3. If the unit of A is g, the norm-jerk has unit g/s. As j is the norm of the jerk, it is always positive or zero (if the acceleration is constant). The final value in j is always 0 because the last finite difference cannot be calculated.
#' @seealso \code{\link{msa}}, \code{\link{odba}}
#' @examples
#' sampleMatrix <- matrix(c(1, 2, 3, 2, 2, 4, 1, -2, 4, 4, 4, 4), byrow = TRUE, nrow = 4, ncol = 3)
#' norm_jerk <- njerk(A = sampleMatrix, sampling_rate = 5)
#' 
#' @export

njerk <- function(A, sampling_rate) {
  if (is.list(A)) {
    sampling_rate <- A$sampling_rate
    a <- A$data
    j <- A
    j$data <- c(sampling_rate * sqrt(rowSums(diff(a)^2)), 0)
    j$creation_date <- Sys.time()
    j$type <- "njerk"
    j$full_name <- "norm jerk"
    j$description <- j$full_name
    j$unit <- "m/s3"
    j$unit_name <- "meters per seconds cubed"
    j$unit_label <- "m/s^3"
    j$column_name <- "jerk"
  } else {
    a <- A
    j <- c(sampling_rate * sqrt(rowSums(diff(a)^2)), 0)
  }
  return(j)
}
