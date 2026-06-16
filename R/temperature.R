#' @title Reconstruct Hourly Temperatures from Daily Extrema
#' @description Reconstructs a 24-hour hourly temperature profile from daily minimum,
#' maximum, and the next day's minimum temperatures using a sine-exponential model.
#'
#' @param t_min Single numeric value of the current day's minimum temperature (°C).
#' @param t_max Single numeric value of the current day's maximum temperature (°C).
#' @param t_min_next Single numeric value of the next day's minimum temperature (°C).
#' @param lat Latitude of the location in decimal degrees.
#' @param doy Day of the year (Julian day, 1 to 365/366).
#' @param alpha Parameters for the time lag between solar noon and maximum
#' temperature (hours). Default is 2.75.
#' @param beta Parameters for the time lag between minimum temperature and sunrise (hours). Default is 1.40.
#' @param gamma Parameter representing the temperature characteristics decay rate at night. Default is 2.75.
#'
#' @return A numeric vector of length 24 containing the reconstructed hourly temperatures (°C) from 00:00 to 23:00.
#' @export
#'
#' @examples
#' estimate_hourly_temp(t_min = 12, t_max = 25, t_min_next = 13, lat = -27.28, doy = 150)
estimate_hourly_temp <- function(t_min, t_max, t_min_next, lat, doy,
                                 alpha = 2.75, beta = 1.40, gamma = 2.75) {
  # Input validation
  inputs <- list(t_min, t_max, t_min_next, lat, doy, alpha, beta, gamma)
  if (any(purrr::map_lgl(inputs, ~ !is.numeric(.x) || length(.x) != 1))) {
    rlang::abort("All inputs must be single numeric values.")
  }

  # 1. Astronomical Calculations (Sunrise and Sunset hours)
  # Declination of the sun (radians)
  dec <- 0.409 * sin((2 * pi * doy / 365) - 1.39)
  lat_rad <- lat * pi / 180

  # Sunset hour angle (radians)
  ws_arg <- -tan(lat_rad) * tan(dec)
  ws_arg <- max(-1, min(1, ws_arg)) # Bound for polar regions
  ws <- acos(ws_arg)

  # Daylength (hours) and standard sunrise/sunset times (solar time approximation)
  dl <- (24 / pi) * ws
  sunrise <- 12 - (dl / 2)
  sunset <- 12 + (dl / 2)

  # Time variables alignment based on model specifications
  t_n <- sunrise + beta   # Time of minimum temperature
  t_x <- 12 + alpha       # Time of maximum temperature

  # Reconstruct hourly values (hours 0 to 23)
  hours <- 0:23
  t_hourly <- purrr::map_dbl(hours, function(t) {

    # Condition A: Between minimum temperature time and sunset (Daytime Sine Model)
    if (t >= t_n && t <= sunset) {
      term <- (t - t_n) / (dl - beta + alpha)
      temp <- t_min + (t_max - t_min) * sin((pi / 2) * term)
      return(temp)
    }

    # Condition B: Nighttime Exponential Decay Model
    # Part 1: Before minimum temperature time (early morning hours belonging to previous night cycle)
    if (t < t_n) {
      # Use an offset of 24 hours to look back at the decay starting from the day before
      t_adj <- t + 24
      t_s_prev <- sunset

      # Calculate temperature at sunset
      term_s <- (sunset - t_n) / (dl - beta + alpha)
      t_sunset <- t_min + (t_max - t_min) * sin((pi / 2) * term_s)

      # Exponential decay using current t_min as the target base minimum
      temp <- t_min + (t_sunset - t_min) * exp(-gamma * (t_adj - t_s_prev) / (24 - dl + beta))
      return(temp)
    }

    # Part 2: After sunset until midnight
    if (t > sunset) {
      term_s <- (sunset - t_n) / (dl - beta + alpha)
      t_sunset <- t_min + (t_max - t_min) * sin((pi / 2) * term_s)

      # Exponential decay targeting next day's minimum temperature
      temp <- t_min_next + (t_sunset - t_min_next) * exp(-gamma * (t - sunset) / (24 - dl + beta))
      return(temp)
    }
  })

  return(t_hourly)
}
