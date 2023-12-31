#' Rotate data.
#'
#' Rotate a numeric vector (for rotation_test, this will be a set of event times).  "Rotating" the vector entails advancing all values by a random increment, then subtracting
#' the maximum expected value from all rotated entries that exceed that maximum.
#' This is a utility function used by \code{\link{rotation_test}}, but advanced users may wish to use it directly to carry out non-standard rotation tests.
#'
#' The rotation test was applied in Miller et al. 2004 and detailed in DeRuiter and Solow 2008. This test is a
#' variation on standard randomization or permutation tests that is appropriate for time-series of non-independent events
#' (for example, time series of behavioral events that tend to occur in clusters). This implementation of the rotation test compares a test statistic (some summary of
#' an "experimental" time-period) to its expected value during non-experimental periods. Instead of resampling random subsets of observations from the original dataset,
#' the rotation test samples many contiguous blocks from the original data, each the same duration as the experimental period. The summary statistic,
#' computed for these "rotated" samples, provides a distribution to which the test statistic from the data can be compared.
#'
#' @param event_times A vector of the times of events. Times can be given in any format. If \code{event_times} should not be sorted prior to analysis (for example, if times are given in hours of the day and the times in the dataset span several days), be sure to specify \code{skip_sort=TRUE}.
#' @param full_period A length two vector giving the start and end times of the full period during which events in event_times might have occurred. If missing, default is range(\code{event_times}).
#' @return A vector of numeric values the same length as \code{event_times} generated by rotating the event times by a random amount
#' @export
#' @examples
#' my_events <- 1500 * stats::runif(10) # 10 events at "times" between 0 and 1500
#' my_events
#' rotated_events <- rotate_data(my_events, full_period = c(0, 1500))
#' rotated_events
rotate_data <- function(event_times, full_period) {
  # Input checking
  # ============================================================================
  if (missing(event_times) | missing(full_period)) {
    stop("event_times and full_period are required inputs.")
  }

  if (sum(is.na(full_period)) > 0) {
    stop("start/end times can not contain any missing (NA) values.")
  }

  if (sum(is.na(event_times)) > 0) {
    message("Warning (rotation_test): missing values in event_times will be ignored.")
    event_times <- stats::na.omit(event_times)
  }

  # Do rotation
  # ============================================================================
  event_times <- stats::na.omit(event_times)
  rot_event_times <- event_times + stats::runif(1) * max(full_period)
  rot_event_times <- sort(ifelse(rot_event_times > max(full_period),
    rot_event_times - max(full_period),
    rot_event_times
  ))
  return(rot_event_times)
}
