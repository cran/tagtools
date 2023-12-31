#' Find time cues for dives
#'
#' This function is used to find the time cues for the start and end of either dives in a depth record or flights in an altitude record.
#' @param p A depth or altitude time series (a sensor data list or  a vector) in meters.
#' @param sampling_rate The sampling rate of the sensor data in Hz (samples per second).
#' @param mindepth The threshold in meters at which to recognize a dive or flight. Dives shallow or flights lower than mindepth will be ignored.
#' @param surface (optional) The threshold in meters at which the animal is presumed to have reached the surface. Default value is 1. A smaller value can be used if the dive/altitude data are very accurate and you need to detect shallow dives/flights.
#' @param findall (optional) When TRUE, forces the algorithm to include incomplete dives at the start and end of the record. Default is FALSE which only recognizes complete dives.
#' @return dives is a data frame with one row for each dive/flight found. The columns of dives are: start (time in seconds of the start of each dive/flight), end (time in seconds of the start of each dive/flight), max (maximum depth/altitude reached in each dive/flight), tmax	(time in seconds at which the animal reaches the max depth/altitude).
#' @export
#' @examples
#' BW <- beaked_whale
#' dives <- find_dives(p = BW$P$data, 
#' sampling_rate = BW$P$sampling_rate, 
#' mindepth = 25, surface = 5, 
#' findall = FALSE)

find_dives <- function(p, mindepth, sampling_rate = NULL, surface = 1, findall = 0) {
  if (nargs() < 2) {
    stop("inputs for p and mindepth are required")
  }
  if (is.list(p)) {
    sampling_rate <- p$sampling_rate
    p <- p$data
    if (is.null(p)) {
      stop("p cannot be an empty vector")
    }
  } else {
    if (nrow(p) == 1) {
      p <- t(p)
    }
    if (is.null(sampling_rate)) {
      stop("sampling_rate is required when p is a vector")
    }
  }

  searchlen <- 20 # how far to look in seconds to find actual surfacing
  dpthresh <- 0.25 # vertical velocity threshold for surfacing
  dp_lp <- 0.25 # low-pass filter frequency for vertical velocity
  # find threshold crossings and surface times
  # hack for case where first depth obs is > mindepth
  if (p[1] > mindepth){p[1] <- mindepth - 0.25}
  
  tth <- which(diff(p > mindepth) > 0)
  tsurf <- which(p < surface)
  ton <- 0 * tth
  toff <- ton
  k <- 0
  empty <- integer(0)
  # sort through threshold crossings to find valid dive start and end points
  for (kth in 1:length(tth)) {
    if (all(tth[kth] > toff)) {
      ks0 <- which(tsurf < tth[kth])
      ks1 <- which(tsurf > tth[kth])
      if (findall || ((!identical(ks0, empty)) & (!identical(ks1, empty)))) {
        k <- k + 1
        if (identical(ks0, empty)) {
          ton[k] <- 1
        } else {
          ton[k] <- max(tsurf[ks0])
        }
        if (identical(ks1, empty)) {
          toff[k] <- length(p)
        } else {
          toff[k] <- min(tsurf[ks1])
        }
      }
    }
  }
  # truncate dive list to only dives with starts and stops in the record
  ton <- ton[1:k]
  toff <- toff[1:k]
  # filter vertical velocity to find actual surfacing moments
  n <- round(4 * sampling_rate / dp_lp)
  dp <- fir_nodelay(
    matrix(c(0, diff(p)), ncol = 1) * sampling_rate,
    n, dp_lp / (sampling_rate / 2)
  )
  # for each ton, look back to find last time whale was at the surface
  # for each toff, look forward to find next time whale is at the surface
  dmax <- matrix(0, length(ton), 2)
  for (k in 1:length(ton)) {
    ind <- ton[k] + (-round(searchlen * sampling_rate):0)
    ind <- ind[which(ind > 0)]
    ki <- max(which(dp[ind] < dpthresh))
    if (length(ki) == 0 | is.infinite(ki)) {
      ki <- 1
    }
    ton[k] <- ind[ki]
    ind <- toff[k] + (0:round(searchlen * sampling_rate))
    ind <- ind[which(ind <= length(p))]
    ki <- min(which(dp[ind] > -dpthresh))
    if (length(ki) == 0 | is.infinite(ki)) {
      ki <- 1
    }
    toff[k] <- ind[ki]
    dm <- max(p[ton[k]:toff[k]])
    km <- which.max(p[ton[k]:toff[k]])
    dmax[k, ] <- c(dm, ((ton[k] + km - 1) / sampling_rate))
  }
  # assemble output
  t0 <- cbind(ton, toff)
  t1 <- t0 / sampling_rate
  t2 <- dmax
  dmat <- cbind(t1, t2)
  dmat <- matrix(dmat[stats::complete.cases(dmat)], byrow = FALSE, ncol = 4)
  dives <- data.frame(
    start = dmat[, 1], end = dmat[, 2],
    max = dmat[, 3], tmax = dmat[, 4]
  )
  return(dives)
}