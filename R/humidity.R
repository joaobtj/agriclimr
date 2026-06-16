#' @title Estimate Hourly Relative Humidity from Daily Metrics
#' @description Reconstructs a 24-hour profile of hourly relative humidity values
#' based on daily average relative humidity, daily average temperature, and a
#' vector of hourly temperatures. It assumes that the actual vapor pressure
#' remains constant throughout the day.
#'
#' @param rh_daily A single numeric value representing the daily average relative humidity (\%).
#' @param t_daily A single numeric value representing the daily average temperature (°C).
#' @param t_hourly A numeric vector of length 24 containing the hourly temperatures (°C).
#'
#' @return A numeric vector of length 24 containing estimated hourly relative humidity values (\%).
#' @export
#'
#' @examples
#' daily_rh <- 80
#' daily_t <- 20
#' hourly_t <- c(16, 15, 14, 14, 15, 17, 19, 21, 23, 24, 25, 25,
#'               24, 23, 22, 21, 20, 19, 18, 17, 17, 16, 16, 16)
#'
#' estimate_hourly_rh(rh_daily = daily_rh, t_daily = daily_t, t_hourly = hourly_t)
estimate_hourly_rh <- function(rh_daily, t_daily, t_hourly) {
  if (!is.numeric(rh_daily) || length(rh_daily) != 1) {
    rlang::abort("Input 'rh_daily' must be a single numeric value.")
  }
  if (!is.numeric(t_daily) || length(t_daily) != 1) {
    rlang::abort("Input 't_daily' must be a single numeric value.")
  }
  if (!is.numeric(t_hourly) || length(t_hourly) != 24) {
    rlang::abort("Input 't_hourly' must be a numeric vector of length 24.")
  }

  # Internal function to calculate saturation vapor pressure (e° in kPa) via Tetens
  calc_es <- function(temp) {
    0.6108 * exp((17.27 * temp) / (temp + 237.3))
  }

  es_daily <- calc_es(t_daily)
  es_hourly <- calc_es(t_hourly)

  # Core meteorological conversion assuming constant actual vapor pressure
  rh_hourly <- 100 * ((rh_daily / 100) * es_daily) / es_hourly

  # Bound hourly relative humidity to physical limits (0 to 100%)
  rh_hourly <- purrr::map_dbl(rh_hourly, ~ max(0, min(100, .x)))

  return(rh_hourly)
}
