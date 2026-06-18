#' @title Estimate Hourly Relative Humidity from Daily Metrics
#' @description Reconstructs a 24-hour profile of hourly relative humidity values
#' based on daily average relative humidity, daily average temperature, and a
#' vector of hourly temperatures. It assumes that the actual vapor pressure
#' remains constant throughout the day.
#'
#' @param rh_daily A single numeric value representing the daily average relative humidity (%).
#' @param t_daily A single numeric value representing the daily average temperature (°C).
#' @param t_hourly A numeric vector of length 24 containing the hourly temperatures (°C).
#'
#' @return A numeric vector of length 24 containing estimated hourly relative humidity values (%).
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

  calc_es <- function(temp) {
    0.6108 * exp((17.27 * temp) / (temp + 237.3))
  }

  es_daily <- calc_es(t_daily)
  es_hourly <- calc_es(t_hourly)

  rh_hourly <- 100 * ((rh_daily / 100) * es_daily) / es_hourly
  rh_hourly <- purrr::map_dbl(rh_hourly, ~ max(0, min(100, .x)))

  return(rh_hourly)
}

#' @title Disaggregate Daily Weather Data to Hourly Relative Humidity
#' @description Takes a daily data frame containing temperature extrema and average
#' relative humidity, reconstructs the hourly temperature internally, and uses it
#' to generate a 24-hour profile of relative humidity for each day. Returns a clean
#' time-series data frame with combined datetime.
#'
#' @importFrom rlang .data
#'
#' @param data A data frame containing the daily weather records.
#' @param date_col Unquoted name of the column containing the Date object.
#' @param t_min_col Unquoted name of the column containing the current day's minimum temperature (°C).
#' @param t_max_col Unquoted name of the column containing the current day's maximum temperature (°C).
#' @param rh_daily_col Unquoted name of the column containing the daily average relative humidity (%).
#' @param lat_col Unquoted name of the column containing the latitude (decimal degrees).
#'
#' @return A tibble (data frame) expanded to hourly resolution (24 rows per original daily row)
#' with three columns: \code{datetime} (POSIXct), \code{temperature_hourly} (°C), and \code{rh_hourly} (%).
#' @export
#'
#' @examples
#'
#' # Sample daily dataset matching your exact input structure with 5 continuous days
#' daily_series <- tibble::tibble(
#'   date = as.Date("2026-06-01") + 0:4,
#'   lat = rep(-27.3, 5),
#'   tmin = c(12.0, 13.5, 11.0, 10.5, 14.0),
#'   tmax = c(22.0, 24.5, 21.0, 19.5, 23.0),
#'   rh_mean = c(80, 75, 85, 90, 70)
#' )
#'
#' daily_to_hourly_rh(daily_series, date, tmin, tmax, rh_mean, lat)
daily_to_hourly_rh <- function(data, date_col, t_min_col, t_max_col, rh_daily_col, lat_col) {
  if (!is.data.frame(data)) {
    rlang::abort("Input 'data' must be a data frame.")
  }

  date_sym     <- rlang::ensym(date_col)
  t_min_sym     <- rlang::ensym(t_min_col)
  t_max_sym     <- rlang::ensym(t_max_col)
  rh_daily_sym <- rlang::ensym(rh_daily_col)
  lat_sym      <- rlang::ensym(lat_col)

  cols_to_check <- c(as.character(date_sym), as.character(t_min_sym),
                     as.character(t_max_sym), as.character(rh_daily_sym),
                     as.character(lat_sym))
  if (!all(cols_to_check %in% colnames(data))) {
    rlang::abort("One or more specified columns do not exist in the provided data frame.")
  }

  expanded_data <- data |>
    dplyr::mutate(
      doy_internal = as.numeric(format(!!date_sym, "%j")),
      t_mean_internal = (!!t_min_sym + !!t_max_sym) / 2,
      t_min_next_internal = dplyr::lead(!!t_min_sym)
    ) |>
    dplyr::mutate(t_min_next_internal = dplyr::coalesce(.data$t_min_next_internal, !!t_min_sym)) |>
    dplyr::mutate(weather_hourly = purrr::pmap(
      list(!!t_min_sym, !!t_max_sym, .data$t_min_next_internal, !!lat_sym, .data$doy_internal, !!rh_daily_sym, .data$t_mean_internal),
      function(t_min, t_max, t_min_next, lat, doy, rh_d, t_d) {
        if (is.na(t_min) || is.na(t_max) || is.na(lat) || is.na(doy) || is.na(rh_d) || is.na(t_d)) {
          return(tibble::tibble(temperature_hourly = rep(NA_real_, 24), rh_hourly = rep(NA_real_, 24)))
        }

        t_h <- estimate_hourly_temp(t_min, t_max, t_min_next, lat, doy)
        rh_h <- estimate_hourly_rh(rh_daily = rh_d, t_daily = t_d, t_hourly = t_h)

        tibble::tibble(temperature_hourly = t_h, rh_hourly = rh_h)
      }
    )) |>
    dplyr::select(-"t_min_next_internal", -"doy_internal", -"t_mean_internal") |>
    dplyr::mutate(hour = purrr::map(.data$weather_hourly, ~ 0:23)) |>
    tidyr::unnest(cols = c("weather_hourly", "hour")) |>
    # 1. Unify date and hour into a single POSIXct datetime column
    dplyr::mutate(
      datetime = as.POSIXct(
        paste0(format(!!date_sym, "%Y-%m-%d"), " ", sprintf("%02d:00:00", .data$hour)),
        tz = "UTC"
      )
    ) |>
    # 2. Drop all inputs, lat, and original columns, retaining only the requested fields
    dplyr::select("datetime", "temperature_hourly", "rh_hourly")

  return(expanded_data)
}
