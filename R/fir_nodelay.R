#' Delay-free filtering
#'
#' This function is used to gather a delay-free filtering using a linear-phase (symmetric) FIR filter followed by group delay correction. Delay-free filtering is needed when the relative timing between signals is important e.g., when integrating signals that have been sampled at different rates.
#' @param x The signal to be filtered. It can be multi-channel with a signal in each column, e.g., an acceleration matrix. The number of samples (i.e., the number of rows in x) must be larger than the filter length, n.
#' @param n The length of symmetric FIR filter to use in units of input samples (i.e., samples of x). The length should be at least 4/fc. A longer filter gives a steeper cut-off.
#' @param fc The filter cut-off frequency relative to sampling_rate/2=1. If a single number is given, the filter is a low-pass or high-pass. If fc is a vector with two numbers, the filter is a bandpass filter with lower and upper cut-off frequencies given by fc(1) and fc(2). For a bandpass filter, n should be at least 4/fc(1) or 4/diff(fc) whichever is larger.
#' @param qual An optional qualifier determining if the filter is: "low" for low-pass (the default value if fc has a single number), or "high" for high-pass. Default is "low".
#' @param return_coefs Logical. Return filter coefficients instead of filtered signal? If TRUE, the function will return the FIR filter coefficients instead of the filtered signal. Default is FALSE.
#' @export
#' @return If return_coefs is FALSE (the default), \code{fir_nodelay()} returns the filtered signal (same size as x). If return_coefs is TRUE, returns the vector of filter coefficients only.
#' @note The filter is generated by a call to \code{\link[signal]{fir1}}: \code{h <- fir1(n, fc, qual)}.
#' @note h is always an odd length filter even if n is even. This is needed to ensure that the filter is both symmetric and has a group delay which is an integer number of samples.
#' @note The filter has a support of n samples, i.e., it uses n samples from x to compute each sample in y.
#' @note The input samples used are those from n/2 samples before to n/2 samples after the sample number being computed. This means that samples at the start and end of the output vector y need input samples before the start of x and after the end of x. These are faked by reversing the first n/2 samples of x and concatenating them to the start of x. The same trick is used at the end of x. As a result, the first and last n/2 samples in y are untrustworthy. This initial condition problem is true for any filter but the FIR filter used here makes it easy to identify precisely which samples are unreliable.
#' @examples 
#' x <- sin(t(2 * pi * 0.05 * (1:100)) +
#'   t(cos(2 * pi * 0.25 * (1:100))))
#' Y <- fir_nodelay(x = x, n = 30, fc = 0.2, qual = "low")
#' plot(c(1:length(x)), x,
#'   type = "l", col = "grey42",
#'   xlab = "index", ylab = "input x and output y"
#' )
#' lines(c(1:length(Y)), Y, lwd = 2)
#'
fir_nodelay <- function(x, n, fc, qual = "low", return_coefs = FALSE) {
  # input checking
  # ================================================================
  # make sure x is a column vector or matrix
  if (!(sum(class(x) %in% c("matrix", "vector")))) {
    x <- as.matrix(x)
  }
  if (is.vector(x)) x <- as.matrix(x, nrow = length(x))
  
  # in case of multi-channel data, make sure matrix rows are samples and columns are channels
  if (dim(x)[2] > dim(x)[1]) x <- t(x)
  
  # make sure n is even to ensure an integer group delay
  n <- floor(n / 2) * 2
  
  
  # generate fir filter
  # ============================================================
  h <- signal::fir1(n = n, w = fc, type = qual)
  
  if (return_coefs) {
    return(h)
  } else { # carry out filtering
    
    # append fake samples to start and end of x to absorb filter delay
    # (output from these will be removed before returning result to user)
    nofsampling_rate <- floor(n / 2)
    top_pad <- matrix(x[nofsampling_rate:2, ], ncol = ncol(x))
    bot_pad <- matrix(x[(nrow(x) - 1):(nrow(x) - nofsampling_rate), ], ncol = ncol(x))
    x_pad <- rbind(top_pad, x, bot_pad)
    
    # filter the signal
    # ============================================================
    # apply filter to padded signal
    y <- apply(x_pad, MARGIN = 2, FUN = signal::filter, filt = h, nrow = nrow(x_pad))
    
    # account for filter offset (remove padding)
    y <- y[n - 1 + (1:nrow(x)), ]
    
    return(y)
  }
}
