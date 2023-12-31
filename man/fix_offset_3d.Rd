% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fix_offset_3d.R
\name{fix_offset_3d}
\alias{fix_offset_3d}
\title{Estimate the offset in each axis}
\usage{
fix_offset_3d(X)
}
\arguments{
\item{X}{A sensor list or matrix containing measurements from a triaxial field sensor such as an accelerometer of magnetometer. X can be in any units and frame.}
}
\value{
A list with 2 elements:
\itemize{
 \item{\strong{X: }} A sensor list or matrix containing the adjusted triaxial sensor measurements. It is the same size and has the same sampling rate and units as the input data. If the input is a sensor list, the output will also.
 \item{\strong{G: }} A calibration list containing one field: G$poly. The first column of G$poly contains 1 as this function does not adjust the scale factor of X. The second column of G$poly is the offset added to each column of X.
}
}
\description{
This function is used to estimate the offset in each axis of a triaxial field measurement, e.g., from an accelerometer or magnetometer. This is useful for correcting drift or calibration errors in a sensor.
}
\note{
This function is only usable for field sensors. It will not work for gyroscope data.
}
\examples{
s <- fix_offset_3d(harbor_seal$A)

}
