#' Detect peaks in signal vector data
#'
#' This function detects peaks in time series data that exceed a specified threshold and returns each peak's start time, end time, maximum peak value, time of the maximum peak value, threshold level, and blanking time.
#' @param data A vector (of all positive values) or matrix of data to be used in peak detection. If data is a matrix, you must specify a FUN to be applied to data.
#' @param FUN A function to be applied to data before the data is run through the peak detector. Only specify the function name (i.e. njerk). If left blank, the data input will be immediately passed through the peak detector.
#' @param sr The sampling rate in Hz of the date. This is the same as fs in other tagtools functions. This is used to calculate the bktime in the case that the input for bktime is missing.
#' @param thresh The threshold level above which peaks in signal are detected. Inputs must be in the same units as the signal. If the input for thresh is missing/empty, the default level is the 0.99 quantile
#' @param bktime The specified length of time (seconds) between signal values detected above the threshold value (from the moment the first peak recedes below the threshold level to the moment the second peak surpasses the threshold level) that is required for each value to be considered a separate and unique peak. If the input for bktime is missing/empty the default value for the blanking time is set as the .80 quantile of the vector of time differences for signal values above the specified threshold.
#' @param plot_peaks A conditional input. If the input is TRUE or missing, an interactive plot is generated, allowing the user to manipulate the thresh and bktime values and observe the changes in peak detection. If the input is FALSE, the interactive plot is not generated. Look to the console for help on how to use the plot upon running of this function.
#' @param quiet If quiet is true, do not print to the screen
#' @param ... Additional inputs to be passed to FUN
#' @export
#' @return A data frame containing the start times, end times, peak times, peak maxima, thresh, and bktime. All times are presented as the sampling value.
#' @note As specified above under the description for the input of plot_peaks, an interactive plot can be generated, allowing the user to manipulate the thresh and bktime values and observe the changes in peak detection. The plot output is only given if the input for plot_peaks is specified as true or if the input is left missing/empty.
#' @examples 
#' BW <- beaked_whale
#' detect_peaks(data = BW$A$data, sr = BW$A$sampling_rate, 
#' FUN = njerk, thresh = NULL, bktime = NULL, 
#' plot_peaks = NULL, sampling_rate = BW$A$sampling_rate, quiet=TRUE)
#' 
detect_peaks <- function(data, sr, FUN = NULL, thresh = NULL, bktime = NULL, plot_peaks = NULL, quiet=FALSE, ...) {
  oldpar <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(oldpar))
  
  if (missing(data) | missing(sr)) {
    stop("inputs for data and sr are both required")
  }
  
  # apply function specified in the inputs to data
  if (!is.null(FUN)) {
    dnew <- FUN(data, ...)
  } else {
    dnew <- data
  }
  
  if ("depid" %in% names(data)) {
    dnew <- dnew$data
  }
  
  # set default threshold level
  if (is.null(thresh) == TRUE) {
    thresh <- as.numeric(stats::quantile(dnew, 0.99))
  }
  
  if (is.null(plot_peaks) == TRUE) {
    plot_peaks <- TRUE
  }
  
  if (thresh > max(dnew)) {
    start_time <- NA
    end_time <- NA
    peak_time <- NA
    peak_max <- NA
    thresh <- thresh
    if (is.null(bktime) == TRUE) {
      bktime <- NA
    } else {
      bktime <- bktime
    }
    warning("Threshold level is greater the the maximum of the signal. No peaks are detected.")
  } else {
    # create matrix for time-series and corresponding sampling number
    d1 <- matrix(c(1:length(dnew)), ncol = 1)
    d2 <- matrix(dnew, ncol = 1)
    d <- cbind(d1, d2)
    
    # determine peaks that are above the threshold
    pt <- d[, 2] >= thresh
    pk <- d[pt, ]
    
    # is there more than one peak?
    if (length(pk) == 2) {
      start_time <- pk[1]
      end_time <- pk[1]
      peak_time <- pk[1]
      peak_max <- pk[2]
      thresh <- thresh
      bktime <- as.numeric(bktime)
    } else {
      # set default blanking time
      if (is.null(bktime)) {
        dpk <- diff(pk[, 1])
        bktime <- as.numeric(stats::quantile(dpk, c(.8)))
      } else {
        bktime <- as.numeric(bktime * sr)
      }
      
      # determine start times for each peak
      dt <- diff(pk[, 1])
      pkst <- c(1, (dt >= bktime))
      start_time <- pk[(pkst == 1), 1]
      
      # determine the end times for each peak
      if (sum(pkst) == 1) {
        if (dnew[length(dnew)] > thresh) {
          start_time <- c()
          end_time <- c()
        } else {
          if (dnew[length(dnew)] <= thresh) {
            end_time <- pk[nrow(pk), 1]
          }
        }
      }
      if (sum(pkst) > 1) {
        if (pkst[length(pkst)] == 0) {
          if (dnew[length(dnew)] <= thresh) {
            ending <- which(pkst == 1) - 1
            end_time <- c(pk[ending[2:length(ending)], 1], pk[nrow(pk), 1])
          } else {
            if (dnew[length(dnew)] > thresh) {
              ending <- which(pkst == 1) - 1
              end_time <- c(pk[ending[2:length(ending)], 1], pk[nrow(pk), 1])
              # if the last peak does not end before the end of recording, the peak is removed from analysis
              start_time <- start_time[1:length(start_time - 1)]
              end_time <- end_time[1:length(end_time - 1)]
            }
          }
        } else {
          if (pkst[length(pkst)] == 1) {
            ending <- which(pkst == 1) - 1
            end_time <- c(pk[ending[2:length(ending)], 1], pk[nrow(pk), 1])
          }
        }
      }
      
      # determine the time and maximum of each peak
      peak_time <- matrix(0, length(start_time), 1)
      peak_max <- matrix(0, length(start_time), 1)
      if (is.null(start_time) & is.null(end_time)) {
        peak_time <- c()
        peak_max <- c()
      } else {
        for (a in 1:length(start_time)) {
          td <- dnew[start_time[a]:end_time[a]]
          m <- max(td)
          mindex <- which.max(td)
          peak_time[a] <- mindex + start_time[a] - 1
          peak_max[a] <- m
        }
      }
      
      bktime <- bktime / sr
    }
  }
  
  # create a data.frame of start times, end times, peak times, peak maxima, thresh, and bktime
  peaks <- list(start_time = start_time, 
                      end_time = end_time, peak_time = peak_time, 
                      peak_max = peak_max, thresh = thresh, bktime = bktime)
  
  if (plot_peaks == TRUE) {
    # script for second run of detect_peaks that doesn't change the bktime from seconds to samples
    detect_peaks2 <- function(data, sr, thresh = NULL, bktime = NULL) {
      if (thresh > max(dnew)) {
        start_time <- NA
        end_time <- NA
        peak_time <- NA
        peak_max <- NA
        thresh <- thresh
        warning("Threshold level is greater the the maximum of the signal. No peaks are detected.")
      } else {
        # create matrix for time-series and corresponding sampling number
        d1 <- matrix(c(1:length(dnew)), ncol = 1)
        d2 <- matrix(dnew, ncol = 1)
        d <- cbind(d1, d2)
        
        # determine peaks that are above the threshold
        pt <- d[, 2] >= thresh
        pk <- d[pt, ]
        
        # is there more than one peak?
        if (length(pk) == 2) {
          start_time <- pk[1]
          end_time <- pk[1]
          peak_time <- pk[1]
          peak_max <- pk[2]
          thresh <- thresh
          bktime <- as.numeric(bktime)
        } else {
          # blanking time is already known from interactive
          
          # determine start times for each peak
          dt <- diff(pk[, 1])
          pkst <- c(1, (dt >= bktime))
          start_time <- pk[(pkst == 1), 1]
          
          # determine the end times for each peak
          if (sum(pkst) == 1) {
            if (dnew[length(dnew)] > thresh) {
              start_time <- c()
              end_time <- c()
            } else {
              if (dnew[length(dnew)] <= thresh) {
                end_time <- pk[nrow(pk), 1]
              }
            }
          }
          if (sum(pkst) > 1) {
            if (pkst[length(pkst)] == 0) {
              if (dnew[length(dnew)] <= thresh) {
                ending <- which(pkst == 1) - 1
                end_time <- c(pk[ending[2:length(ending)], 1], pk[nrow(pk), 1])
              } else {
                if (dnew[length(dnew)] > thresh) {
                  ending <- which(pkst == 1) - 1
                  end_time <- c(pk[ending[2:length(ending)], 1], pk[nrow(pk), 1])
                  # if the last peak does not end before the end of recording, the peak is removed from analysis
                  start_time <- start_time[1:length(start_time - 1)]
                  end_time <- end_time[1:length(end_time - 1)]
                }
              }
            } else {
              if (pkst[length(pkst)] == 1) {
                ending <- which(pkst == 1) - 1
                end_time <- c(pk[ending[2:length(ending)], 1], pk[nrow(pk), 1])
              }
            }
          }
          
          # determine the time and maximum of each peak
          peak_time <- matrix(0, length(start_time), 1)
          peak_max <- matrix(0, length(start_time), 1)
          if (is.null(start_time) & is.null(end_time)) {
            peak_time <- c()
            peak_max <- c()
          } else {
            for (a in 1:length(start_time)) {
              td <- dnew[start_time[a]:end_time[a]]
              m <- max(td)
              mindex <- which.max(td)
              peak_time[a] <- mindex + start_time[a] - 1
              peak_max[a] <- m
            }
          }
        }
      }
      
      # create a data frame of start times, end times, peak times, peak maxima, thresh, and bktime
      peaks <- list(start_time = start_time, 
                          end_time = end_time, peak_time = peak_time, 
                          peak_max = peak_max, thresh = thresh, bktime = bktime)
      
      graphics::plot(dnew, type = "l", col = "blue", xlim = c(0, length(dnew)), ylim = c(0, max(dnew)), ylab = "Signal Power", xlab = "Time (1/sampling_rate)")
      x <- peaks$peak_time
      y <- peaks$peak_max
      graphics::par(new = TRUE)
      graphics::plot(x, y, pch = 9, type = "p", col = "orange", xlim = c(0, length(dnew)), ylim = c(0, max(dnew)), cex = .75, ylab = "Signal Power", xlab = "Time (1/sampling_rate)")
      graphics::abline(a = thresh, b = 0, col = "red", lty = 2)
      
      return(peaks)
    }
    
    # create a plot which allows for the thresh and bktime to be manipulated
    graphics::plot(dnew, type = "l", col = "blue", xlim = c(0, length(dnew)), ylim = c(0, max(dnew)), ylab = "Signal Power", xlab = "Time (1/sampling_rate)")
    if (!quiet){
    message("GRAPH HELP:")
    message("For changing only the thresh level, click once within the plot and then push enter")
    message(" to specify the y-value at which your new thresh level will be.")
    message("For changing just the bktime value, click twice within the plot and then push enter")
    message(" to specify the length for which your bktime will be.")
    message("To change both the bktime and the thresh, click three times within the plot:")
    message(" the first click will change the thresh level,")
    message(" the second and third clicks will change the bktime.")
    message("To return your results without changing the thresh and bktime from their default")
    message(" values, simply push enter.")
    }
    x <- peaks$peak_time
    y <- peaks$peak_max
    graphics::par(new = TRUE)
    graphics::plot(x, y, pch = 9, type = "p", col = "orange", xlim = c(0, length(dnew)), ylim = c(0, max(dnew)), cex = .75, ylab = "Signal Power", xlab = "Time (1/sampling_rate)")
    graphics::abline(a = thresh, b = 0, col = "red", lty = 2)
    pts <- graphics::locator(n = 3)
    if (length(pts$x) == 3) {
      thresh <- pts$y[1]
      bktime <- max(pts$x[2:3]) - min(pts$x[2:3])
      peaks <- detect_peaks2(dnew, sr, thresh = thresh, bktime = bktime)
    } else {
      if (length(pts$x) == 1) {
        thresh <- pts$y[1]
        peaks <- detect_peaks2(dnew, sr, thresh = thresh, bktime = bktime)
      } else {
        if (length(pts$x) == 2) {
          bktime <- max(pts$x) - min(pts$x)
          peaks <- detect_peaks2(dnew, sr, thresh = thresh, bktime = bktime)
        } else {
          peaks <- detect_peaks2(dnew, sr, thresh = thresh, bktime = bktime)
        }
      }
    }
  } else {
    graphics::plot(dnew, type = "l", col = "blue", xlim = c(0, length(dnew)), ylim = c(0, max(dnew)), ylab = "Signal Power", xlab = "Time (1/sampling_rate)")
    x <- peaks$peak_time
    y <- peaks$peak_max
    graphics::par(new = TRUE)
    graphics::plot(x, y, pch = 9, type = "p", col = "orange", xlim = c(0, length(dnew)), ylim = c(0, max(dnew)), cex = .75, ylab = "Signal Power", xlab = "Time (1/sampling_rate)")
    graphics::abline(a = thresh, b = 0, col = "red", lty = 2)
  }
  
  peaks <- as.data.frame(peaks, row.names = NULL, check.names = FALSE)
  
  return(peaks)
}

