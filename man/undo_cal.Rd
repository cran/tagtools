% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/undo_cal.R
\name{undo_cal}
\alias{undo_cal}
\title{Undo calibrations steps}
\usage{
undo_cal(X, temperature)
}
\arguments{
\item{X}{A sensor list or set of sensor lists in the tag frame, i.e., with calibrations applied.}

\item{temperature}{A vector of temperature measurements with the same number of samples and sampling rate as the data in the input sensor data structure X. The temperature parameter indicates the temperature experienced by the sensor during data collection (not necessarily the ambient temperature experienced by the animal), and may affect calibration because many sensors’ output values change depending on the temperature.}
}
\value{
A sensor list or set of sensor lists reverted to the sensor frame, i.e., without calibrations.
}
\description{
This function is used to undo any calibration steps that have been applied to sensor data. This will reverse any re-mapping, scaling and offset adjustments that have been applied to the data, reverting the sensor data to the state it was when read in from the source (excluding any filtering or decimation steps).
}
\examples{
BW <- beaked_whale
no_cal <- undo_cal(BW)

}
