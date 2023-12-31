#' Generate a sensor structure from a sensor data vector or matrix.
#'
#' @param data sensor data vector or matrix
#' @param depid string that provides a unique identifier for this tag deployment
#' @param type is a string containing the first few letters of the sensor type,
#'             e.g., acc for acceleration. These will be matched to the list of
#'             sensor names in the sensor_names.csv file. If more than one sensor
#'             matches type, a warning will be given. type can be in upper or lower case.
#' @param times (optional) is the time in seconds of each measurement in data for irregularly sampled data. The time reference (i.e., the 0 time) should be with respect to the start time of the deployment.
#' @param sampling_rate (optional) sensor data sampling rate in Hz
#' @param unit (optional) units in which data are sampled. Default determined by matching \code{type} with defaults in sensor_names.csv
#' @param frame (optional) frame of reference for data axes, for example 'animal' or 'tag'. Default determined by matching \code{type} with defaults in sensor_names.csv.
#' @param name (optional) "full name" to assign to the variable. Default determined by matching \code{type} to defaults in sensor_names.csv/
#' @param start_offset (optional) offset in start time for this sensor relative to start of tag recording. Defaults to 0.
#' @param start_offset_units (optional) units of start_offset. default is 'second'.
#' @param quiet prints to screen if quiet is set to false
#' @return A sensor list with field \code{data} containing the data and with metadata fields pre-populated from the sensor_names.csv file. Change these manually as needed (or specify the relevant inputs to \code{sens_struct}) to the correct values.
#' @export
#' @examples
#' HB <- harbor_seal
#' A <- sens_struct(data=HB$A$data,sampling_rate=3,depid='md13_134a', type='acc', quiet=TRUE)
#'
sens_struct <- function(data, sampling_rate = NULL, times = NULL,
                        depid, type,
                        unit = NULL, frame = NULL, name = NULL,
                        start_offset = 0, start_offset_units = "second", quiet=FALSE) {
  sens_names <- utils::read.csv(system.file("extdata", "sensor_names.csv", package = "tagtools"),
    stringsAsFactors = FALSE
  )
  if (missing(data) | missing(type) | missing(depid)) {
    if (!quiet){
    cat(
      "Not enough inputs to sens_struct. Pre-defined sensor types are:\n",
      as.character(sens_names[, "name"])
    )}
    stop("Please check inputs to sens_struct.")
    X <- NULL
  }

  if (length(sampling_rate) == 1) { # regularly sampled data
    X <- list(
      data = data, sampling = "regular",
      sampling_rate = sampling_rate, sampling_rate_unit = "Hz"
    )
  } else { # irregular data
    if (length(times) != min(nrow(data), length(data))) {
      stop("number of sampling times does not match number of samples.")
    }
    X <- list(data = matrix(0, nrow = length(times), ncol = 1 + max(1, ncol(data))))
    X$data[, 1] <- times
    X$data[, 2:ncol(X$data)] <- data
    X$sampling <- "irregular"
    X$sampling_time <- "column 1"
    X$sampling_time_unit <- "second"
    fs <- NULL
  }

  X$depid <- depid
  X$creation_date <- as.character(Sys.time())
  X$history <- "sens_struct"

  # compare sensor names database against type
  k <- grepl(type, sens_names$name, ignore.case = TRUE)
  if (sum(k) == 0) {
    w_msg <- paste("unknown sensor type ", type, ". Set metadata manually or define more inputs to sens_struct().", sep = "")
    warning(w_msg)
    X$name <- type
    X$type <- type
    if (!missing(unit)) {
      X$unit <- unit
    }
    if (!missing(frame)) {
      X$frame <- frame
    }
    if (!missing(name)) {
      X$name <- name
    }
    if (!missing(start_offset)) {
      X$start_offset <- start_offset
    }
    if (!missing(start_offset_units)) {
      X$start_offset_units <- start_offset_units
    }
    return(X)
  }

  if (sum(k) > 1) {
    e_msg <- paste(
      "More than one sensor type matches ",
      type, ". Retry with a longer type."
    )
    stop(e_msg)
  }

  nc <- sens_names[k, "axes"]
  if (max(1, ncol(data)) != nc) {
    w_msg <- paste("Size of data does not match number of columns (",
      nc, " expected for ", sens_names[k, "name"], ")",
      sep = ""
    )
    warning(w_msg)
  }

  if (is.null(name)) {
    X$name <- sens_names[k, "abbrev"]
  } else {
    X$name <- name
  }

  X$type <- sens_names[k, "abbrev"]
  X$full_name <- sens_names[k, "name"]
  X$description <- sens_names[k, "description"]
  X$unit <- sens_names[k, "def_units"]
  X$unit_name <- sens_names[k, "def_unit_name"]
  X$unit_label <- sens_names[k, "def_label"]
  X$start_offset <- start_offset
  X$start_offset_units <- start_offset_units

  if (!is.na(sens_names[k, "def_cols"])) {
    if (is.null(sampling_rate)) {
      X$column_name <- paste("time, ", sens_names[k, "def_cols"], sep = "")
    } else {
      X$column_name <- sens_names[k, "def_cols"]
    }
  }

  if (!is.na(sens_names[k, "def_frame"])) {
    X$frame <- sens_names[k, "def_frame"]
  }

  if (!is.na(sens_names[k, "def_axes"])) {
    X$axes <- sens_names[k, "def_axes"]
  }
  return(X)
}
