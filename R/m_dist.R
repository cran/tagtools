#' Calculate Mahalanobis distance 
#' 
#' This function is used to calculate the Mahalanobis distance for a multivariate time series.
#' @param data A data frame or matrix with one row for each time point. Note that the Mahalanobis distance calculation should be carried out on continuous data only, so if your data contain logical, factor or character data, proceed at your own risk...errors (or at least meaningless results) will probably ensue.
#' @param sampling_rate The sampling rate in Hz (data should be regularly sampled). If not specified it will be assumed to be 1 Hz.
#' @param smoothDur The length, in minutes, of the window to use for calculation of "comparison" values. If not specified or zero, there will be no smoothing (a distance will be calculated for each data observation).
#' @param overlap The amount of overlap, in minutes, between consecutive "comparison" windows. smooth_dur - overlap will give the time resolution of the  resulting distance time series. If not specified or zero, there will be no overlap.  Overlap will also be set to zero if smoothDur is unspecified or zero.
#' @param consec Logical. If consec = TRUE, then the calculated distances are between consecutive windows of duration smoothDur, sliding forward over the data set by a time step of (smoothDur-overlap) minutes. If TRUE, baselineStart and baselineEnd inputs will be used to define the period used to calculate the data covariance matrix. Default is consec = FALSE.  
#' @param cumSum Logical.  If cum_sum = TRUE, then output will be the cumulative sum of the calculated distances, rather than the distances themselves. Default is cum_sum = FALSE.
#' @param expStart Start times (in seconds since start of the data set) of the experimental exposure period(s). 
#' @param expEnd End times (in seconds since start of the data set) of the experimental exposure period(s). If either or both of exp_start and exp_end are missing, the distance will be calculated over whole dataset and full dataset will be assumed to be baseline.
#' @param baselineStart Start time (in seconds since start of the data set) of the baseline period (the mean data values for this period will be used as the 'control' to which all "comparison" data points (or windows) will be compared. if not specified, it will be assumed to be 0 (start of record).
#' @param baselineEnd End time (in seconds since start of the data set) of the baseline period. If not specified, the entire data set will be used (baseline_end will be the last sampled time-point in the data set).
#' @param BL_COV Logical.  If BL_COV=  TRUE, then a covariance matrix using all data in baseline period will be used for calculating the Mahalanobis distance. Default is BL_COV = FALSE.
#' @return Data frame containing results: variable seconds is times in seconds since start of dataset, at which Mahalanobis distances are reported. If a smoothDur was applied, then the reported times will be the start times of each "comparison" window. Variable dist is the Mahalanobis distances between the specified baseline period and the specified "comparison" periods.
#' @export
#' @examples BW <- beaked_whale
#' m_dist_result <- m_dist(BW$A$data, BW$A$sampling_rate)
#' 


m_dist <- function(data, sampling_rate, smoothDur, overlap, consec, cumSum, expStart, expEnd, baselineStart, baselineEnd, BL_COV) {
  # Input checking---------------------------------------
  if (missing(sampling_rate)) {
    sampling_rate <- 1
  }
  if (missing(smoothDur)) {
    smoothDur <- 0
  }
  if (missing(overlap) | smoothDur == 0) {
    overlap <- 0
  }
  if (missing(consec)) {
    consec = FALSE
  }
  if (missing(cumSum)) {
    cumSum = FALSE
  }
  if (missing(expStart) | missing(expEnd)) {
    expStart <- NA
    expEnd <- NA
  }
  if (missing(baselineStart)) {
    baselineStart <- 0
  }
  if (missing(baselineEnd)) {
    baselineEnd <- floor(nrow(data)/sampling_rate)
  }
  if (missing(BL_COV)) {
    BL_COV = FALSE
  }
  # preliminaries - conversion, preallocate space, etc.
  es <- floor(sampling_rate * expStart) + 1                              # start of experimental period in samples
  ee <- ceiling(sampling_rate * expEnd)                                  # end of experimental period in samples
  bs <- floor(sampling_rate * baselineStart) + 1                         # start of baseline period in samples
  be <- min(ceiling(sampling_rate * baselineEnd), nrow(data))            # end of baseline period in samples
  W <- max(1, smoothDur * sampling_rate * 60)                            # window length in samples
  O <- overlap * sampling_rate * 60                                      # overlap between subsequent window, in samples
  N <- ceiling(nrow(data) / (W - O))                          # number of start points at which to position the window -- start points are W-O samples apart
  k <- matrix(c(1:N), ncol = 1)                               # index vector
  ss <- (k - 1) * (W - O) + 1                                 # start times of comparison windows, in samples
  ps <- ((k - 1) * (W - O) + 1) + smoothDur * sampling_rate * 60 / 2     # mid points of comparison windows, in samples (times at which distances will be reported)
  mid_t <- ps / sampling_rate                                                # mid-point times in seconds
  ctr <- colMeans(data[bs:be,], na.rm = TRUE)                    # mean values during baseline period
  if (BL_COV) {
    bcov <- stats::cov(data[bs:be,], use = "complete.obs")           # covariance matrix using all data in baseline period
  } else {
    bcov <- stats::cov(data, use = "complete.obs")
  }
  
  #Calculate distances!--------------------------------------
  Ma <- function(d,Sx) { # to use later...alternate way of calc Mdist
    # d is a row vector of pairwise differences between the things you're comparing
    # Sx is the inverse of the cov matrix
    sum((d %*% Sx) %*% d)
  }
  ------------------------------------------------------------
    
  if (consec == FALSE) {
    # doing the following with apply type commands means it could be executed in parallel if needed...
    comps <- zoo::rollapply(data, width = W, mean, by = W - O, by.column = TRUE, align = "left", fill = NULL, partial = TRUE, na.rm = TRUE) # rolling means, potentially with overlap
    d2 <- apply(comps, MARGIN = 1, FUN = stats::mahalanobis, cov = bcov, center = ctr, inverted = FALSE)
  } else {
    i_bcov <- solve(bcov) # inverse of the baseline cov matrix
    ctls <- zoo::rollapply(data, width = W, mean, by = W-O, by.column = TRUE, align = "left", fill = NULL, partial = TRUE, na.rm = TRUE) # rolling means, potentially with overlap
    comps <- rbind( ctls[2:nrow(ctls),] , NA * vector(mode = "numeric",length = ncol(data)) ) # compare a given control window with the following comparison window.
    pair_difsampling_rate <- as.matrix(ctls - comps)
    d2 <- apply(pair_difsampling_rate, MARGIN = 1, FUN = Ma, Sx = i_bcov)
    d2 <- c(NA, d2[1:(length(d2) - 1)]) # first dist should be at midpoint of first comp window
  }
  # functions return squared Mahalanobis dist so take sqrt
  dist <- sqrt(d2)
  dist[mid_t > (nrow(data) / sampling_rate - smoothDur * 60)] <- NA
  # Calculate cumsum of distances if requested
  if(cumSum == TRUE) {
    dist <- cumsum(dist)
  }
  D <- data.frame(seconds = mid_t, dist)
  return(D)
}
