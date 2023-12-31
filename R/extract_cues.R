#' Extract multiple sub-samples of data
#'
#' This function is used to extract multiple sub-samples of data from a vector or matrix.
#' @param x is a vector or matrix of measurements. If x is a matrix, each column is treated as a separate measurement vector.
#' @param sampling_rate is the sampling rate in Hz of the data in x.
#' @param cues defines the start time in seconds of the intervals to be extracted from x.
#' @param len is the length of the interval to extract in seconds. This should be a scalar.
#' @return A list with 2 elements:
#' \itemize{
#' \item{\strong{X: }} A matrix containing sub-samples of x. If x is a vector, X has as many columns as there are cues, i.e., each cue generates a column of X. If x is a pxm matrix, X will be a qxmxn matrix where n is the size of cues and q is the length of the interval requested, i.e., round(sampling_rate*len) samples.
#' \item{\strong{cues: }} The list of cues actually used. cues that require data outside of x are rejected.
#' }
#' @note Output sampling rate is the same as the input sampling rate.
#' @export
#' @examples
#' BW <- beaked_whale # beaked_whale must be in your working directory
#' list <- extract_cues(x = BW$A$data, sampling_rate = BW$A$sampling_rate, cues = c(6, 40), len = 11)
extract_cues <- function(x, sampling_rate, cues, len) {
  if (missing(len)) {
    stop("inputs for all arguments are required")
  }
  if (nrow(x) == 1) {
    x <- t(x)
  }
  kcues <- round(sampling_rate * cues)
  klen <- round(sampling_rate * len[1])
  k <- which((kcues >= 0) & (kcues < nrow(x) - klen))
  kcues <- kcues[k]
  cues <- cues[k]
  if (ncol(x) == 1) {
    X <- matrix(0, klen, length(k))
    for (kk in 1:length(k)) {
      X[, kk] <- x[kcues[kk] + c(1:klen), ]
    }
  } else {
    X <- replicate(length(k), matrix(0, klen, ncol(x)))
    for (kk in 1:length(k)) {
      X[, , kk] <- x[kcues[kk] + c(1:klen), ]
    }
  }
  list <- list(X = X, cues = cues)
  return(list)
}