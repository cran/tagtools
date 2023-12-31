#' Calculate total acceleration
#'
#'  This function calculates the total acceleration due to gravitation and centripetal force at the earth's surface according to the WGS84 international gravity formula.
#'
#' @param latitude The latitude in degrees.
#' @return g given in units of $m/s^2$
#' @note Source: http://solid_earth.ou.edu/notes/potential/igf.htm
#' @export
#' @examples acc_wgs84(50)
acc_wgs84 <- function(latitude) {
  if (missing(latitude)) {
    stop("input for latitude is required")
  }
  latrad <- latitude * pi / 180
  g <- 9.7803267714 * (1 + 0.0019318514 * sin(latrad)^2) / sqrt(1 - 0.00669438 * sin(latrad)^2)
  return(g)
}