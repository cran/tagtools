% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/depth2pressure.R
\name{depth2pressure}
\alias{depth2pressure}
\title{Convert depth to pressure}
\usage{
depth2pressure(d, latitude)
}
\arguments{
\item{d}{The depth in meters}

\item{latitude}{The latitude in degrees}
}
\value{
The pressure in Pa
}
\description{
This function is used to convert the depth (in meters) to the pressure in Pascals.
}
\note{
Based on the Leroy and Parthiot (1998) formula. See: http://resource.npl.co.uk/acoustics/techguides/soundseawater/content.html#UNESCO
}
\examples{
depth2pressure(1000, 27)
}
