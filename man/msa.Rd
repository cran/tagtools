% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/msa.R
\name{msa}
\alias{msa}
\title{Compute MSA}
\usage{
msa(A, ref)
}
\arguments{
\item{A}{An nx3 acceleration matrix with columns [ax ay az], or a tag sensor data list containing acceleration data. Acceleration can be in any consistent unit, e.g., g or m/s^2. A can be in any frame as the MSA is rotation independent.}

\item{ref}{The gravitational field strength in the same units as A. This is not needed if A is a sensor structure. If A is a matrix, the default value is 9.81 which assumes that A is in m/s^2. Use ref = 1 if the unit of A is g.}
}
\value{
A column vector of MSA with the same number of rows as A, or a tag sensor data list (output matches input). m has the same units as A.
}
\description{
This function is used to compute the Minimum Specific Acceleration (MSA). This is the absolute value of the norm of the acceleration minus 1 g, i.e., the amount that the acceleration differs from the gravity value. This is always equal to or less than the actual specific acceleration if A is correctly calibrated.
}
\details{
Possible input combinations: msa(A) if A is a list, msa(A,ref) if A is a matrix.
}
\note{
See Simon et al. (2012) Journal of Experimental Biology, 215:3786-3798.
}
\examples{
sampleMatrix <- matrix(c(1, -0.5, 0.1, 0.8, -0.2, 0.6, 0.5, -0.9, -0.7),
  byrow = TRUE, nrow = 3, ncol = 3
)
msa(A = sampleMatrix, ref = 1)
}
\seealso{
\code{\link{odba}}, \code{\link{njerk}}
}
