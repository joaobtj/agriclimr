#' @title Estimate Solar Noon
#'
#' @description
#' Calculates the solar noon time in decimal hours. By default, it returns
#' local solar noon (12.0 h), but it can compute civil standard clock time
#' when longitude and time zone offset are provided.
#'
#' @param doy A numeric vector of day of the year (Julian day, 1 to 365/366) or
#'   a vector of \code{Date} / \code{POSIXt} objects.
#' @param lon Optional. Longitude in decimal degrees (negative for West).
#'   If omitted, local solar noon is returned (12.0).
#' @param tz Optional. Time zone offset from UTC in hours (e.g., -3 for UTC-3).
#'
#' @return A numeric vector representing solar noon in decimal hours (0 to 24).
#' @export
#'
#' @examples
#' # Local solar noon (default)
#' estimate_solar_noon(doy = 180)
#'
#' # Civil clock time for solar noon with longitude and UTC offset
#' estimate_solar_noon(doy = 180, lon = -50.58, tz = -3)
estimate_solar_noon <- function(doy, lon = NULL, tz = NULL) {
  if (inherits(doy, c("Date", "POSIXt"))) {
    doy <- as.numeric(format(doy, "%j"))
  }

  if (is.null(lon) || is.null(tz)) {
    return(rep(12.0, length(doy)))
  }

  # Equation of Time (ET in minutes; Spencer, 1971 / Campbell & Norman, 1998)
  b <- (2 * pi / 365) * (doy - 81)
  et <- 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b)

  # Standard meridian of the time zone
  lon_std <- tz * 15

  # Civil clock time adjustment (decimal hours)
  solar_noon <- 12.0 - (lon - lon_std) / 15.0 - (et / 60.0)

  return(solar_noon)
}


#' @title Estimate Sunrise Time
#'
#' @description
#' Computes sunrise time in decimal hours based on latitude, day of the year,
#' and solar noon.
#'
#' @param lat Latitude in decimal degrees (negative for South).
#' @param doy A numeric vector of day of the year (Julian day, 1 to 365/366) or
#'   a vector of \code{Date} / \code{POSIXt} objects.
#' @param solar_noon Optional. Numeric vector or scalar indicating solar noon
#'   in decimal hours. Default is 12.0.
#'
#' @return A numeric vector containing sunrise times in decimal hours.
#' @export
#'
#' @examples
#' # Sunrise on summer solstice for southern hemisphere (lat = -27.28)
#' estimate_sunrise(lat = -27.28, doy = 355)
estimate_sunrise <- function(lat, doy, solar_noon = 12.0) {
  if (inherits(doy, c("Date", "POSIXt"))) {
    doy <- as.numeric(format(doy, "%j"))
  }

  phi <- lat * pi / 180
  delta <- 0.409 * sin((2 * pi / 365) * doy - 1.39)

  cos_ws <- -tan(phi) * tan(delta)
  cos_ws <- pmin(pmax(cos_ws, -1), 1)
  ws <- acos(cos_ws)

  half_day <- (ws / pi) * 12.0
  sunrise <- solar_noon - half_day

  return(sunrise)
}


#' @title Estimate Sunset Time
#'
#' @description
#' Computes sunset time in decimal hours based on latitude, day of the year,
#' and solar noon.
#'
#' @inheritParams estimate_sunrise
#'
#' @return A numeric vector containing sunset times in decimal hours.
#' @export
#'
#' @examples
#' estimate_sunset(lat = -27.28, doy = 355)
estimate_sunset <- function(lat, doy, solar_noon = 12.0) {
  if (inherits(doy, c("Date", "POSIXt"))) {
    doy <- as.numeric(format(doy, "%j"))
  }

  phi <- lat * pi / 180
  delta <- 0.409 * sin((2 * pi / 365) * doy - 1.39)

  cos_ws <- pmin(pmax(-tan(phi) * tan(delta), -1), 1)
  ws <- acos(cos_ws)

  half_day <- (ws / pi) * 12.0
  sunset <- solar_noon + half_day

  return(sunset)
}


#' @title Estimate Astronomical Day Length (Photoperiod)
#'
#' @description
#' Calculates the astronomical day length (photoperiod) in decimal hours.
#'
#' @inheritParams estimate_sunrise
#'
#' @return A numeric vector of day length values in decimal hours.
#' @export
#'
#' @examples
#' estimate_daylength(lat = -27.28, doy = 172) # Winter solstice
#' estimate_daylength(lat = -27.28, doy = 355) # Summer solstice
estimate_daylength <- function(lat, doy) {
  if (inherits(doy, c("Date", "POSIXt"))) {
    doy <- as.numeric(format(doy, "%j"))
  }

  phi <- lat * pi / 180
  delta <- 0.409 * sin((2 * pi / 365) * doy - 1.39)

  cos_ws <- pmin(pmax(-tan(phi) * tan(delta), -1), 1)
  ws <- acos(cos_ws)

  daylength <- (24 / pi) * ws
  return(daylength)
}
