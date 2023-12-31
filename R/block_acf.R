#' Compute autocorrelation function
#'
#' This function allows calculation of an autocorrelation function (ACF) for a dataset with multiple independent units (for example, data from several individuals, data from multiple dives by an individual animal, etc.). The groups (individual, dive, etc.) should be coded in a categorical variable. The function calculates correlation coefficients over all levels of the categorical variable, but respecting divisions between levels (for example, individual animals are kept separate).
#' @param resids The variable for which the ACF is to be computed (often a vector of residuals from a fitted model)
#' @param blocks A categorical variable indicating the groupings (must be the same length as resids. ACF will be computed only for data points within the same block.)
#' @param max_lag ACF will be computed at 0-max_lag lags, ignoring all observations that span blocks. Defaults to the minimum number of observations in any block. The function will allow you to specify a max_lag longer than the shortest block if you so choose.
#' @param make_plot Logical. Should a plot be produced? Defaults to TRUE.
#' @return A data frame with 1 variable containing the values of ACF.
#' @param ... Additional arguments to be passed to plot.acf
#' @export
#' @examples
#' block_acf(
#'   resids = ChickWeight$weight,
#'   blocks = ChickWeight$Chick
#' )
block_acf <- function(resids, blocks, max_lag,
                      make_plot = TRUE, ...) {
  # input checks-----------------------------------------------------------
  blocks <- as.factor(blocks)
  if (length(blocks) != length(resids)) {
    warning("blocks and resids must be the same length.")
  }
  if (missing(max_lag)) {
    max_lag <- min(tapply(blocks, blocks, length))
  }

  # get indices of last element of each block (excluding the last block)
  i1 <- cumsum(as.vector(utils::head(tapply(blocks, blocks, length), -1)))
  block_acf <- matrix(1, nrow = max_lag + 1, ncol = 1)
  r <- resids

  for (k in 1:max_lag) {
    # insert NA before first entry of each new block
    for (b in 1:length(i1)) {
      r <- append(resids, NA, i1[b])
    }
    # adjust for the growing r
    i1 <- i1 + utils::head(c(0:(-1 + nlevels(blocks))), -1)
    this_acf <- stats::acf(r,
      lag.max = max_lag,
      type = "correlation",
      plot = FALSE,
      na.action = stats::na.pass
    )
    block_acf[k + 1] <- this_acf$acf[k + 1, 1, 1]
  }
  if (make_plot) {
    # get an acf object in which the block_acf results will be inserted. Facilitates plotting.
    A <- stats::acf(resids, lag.max = max_lag, plot = FALSE)
    # insert coefficients from block_acf into A
    A$acf[, 1, 1] <- block_acf
    # plot block_acf
    graphics::plot(A, ...)
  }
  block_acf <- data.frame(ACF = block_acf[,1])
  
  # Commented out since it will prints the data frame out to the screen, uncomment the return statment to use this feature. 
#  return(block_acf)
}
