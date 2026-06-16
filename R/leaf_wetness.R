#' @title Estimate Leaf Wetness Duration (LWD)
#' @description Estimates the number of hours of leaf wetness based on a Relative
#' Humidity (RH) threshold. This is a standard empirical approach used in
#' agricultural meteorology to predict plant disease risks.
#'
#' @param rh A numeric vector containing hourly Relative Humidity values (0 to 100).
#' @param threshold A numeric value indicating the RH percentage above which
#' leaf wetness is assumed to occur. Default is 90%.
#'
#' @return A numeric vector of the same length as \code{rh} containing binary
#' values: 1 (wet) or 0 (dry).
#' @export
#'
#' @examples
#' hourly_rh <- c(85, 88, 91, 95, 92, 87, 80)
#' estimate_lwd_rh(hourly_rh, threshold = 90)
estimate_lwd_rh <- function(rh, threshold = 90) {
  if (!is.numeric(rh)) {
    rlang::abort("Input 'rh' must be a numeric vector.")
  }

  if (!is.numeric(threshold) || length(threshold) != 1) {
    rlang::abort("Input 'threshold' must be a single numeric value.")
  }

  if (any(rh < 0 | rh > 100, na.rm = TRUE)) {
    rlang::warn("Some 'rh' values are outside the expected range of 0 to 100%.")
  }

  lwd <- ifelse(rh >= threshold, 1, 0)

  return(lwd)
}

#' @title Disaggregate Daily Weather Data to Hourly Leaf Wetness Duration
#' @description Takes a daily data frame containing temperature extrema and average
#' relative humidity, reconstructs the hourly parameters internally, and computes
#' the hourly leaf wetness presence along with its daily operational hour sum.
#'
#' @param data A data frame containing the daily weather records.
#' @param date_col Unquoted name of the column containing the Date object.
#' @param t_min_col Unquoted name of the column containing the current day's minimum temperature (°C).
#' @param t_max_col Unquoted name of the column containing the current day's maximum temperature (°C).
#' @param rh_daily_col Unquoted name of the column containing the daily average relative humidity (\%).
#' @param lat_col Unquoted name of the column containing the latitude (decimal degrees).
#' @param rh_threshold A single numeric value indicating the RH percentage above which leaf
#' wetness is assumed to occur. Default is 85\% based on optimized regional validations.
#'
#' @return A tibble (data frame) expanded to hourly resolution (24 rows per original daily row)
#' with four columns: \code{datetime} (POSIXct), \code{temperature_hourly} (°C), \code{rh_hourly} (\%),
#' \code{leaf_wetness_hourly} (binary 0/1), and \code{lwd_daily_sum} (total wet hours in that day).
#' @export
#'
#' @examples
#' library(dplyr)
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
#' daily_to_hourly_lwd(daily_series, date, tmin, tmax, rh_mean, lat, rh_threshold = 85)
daily_to_hourly_lwd <- function(data, date_col, t_min_col, t_max_col, rh_daily_col, lat_col, rh_threshold = 85) {
  if (!is.data.frame(data)) {
    rlang::abort("Input 'data' must be a data frame.")
  }

  date_sym     <- rlang::ensym(date_col)
  t_min_sym    <- rlang::ensym(t_min_col)
  t_max_sym    <- rlang::ensym(t_max_col)
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
          return(tibble::tibble(
            temperature_hourly = rep(NA_real_, 24),
            rh_hourly = rep(NA_real_, 24),
            leaf_wetness_hourly = rep(NA_real_, 24)
          ))
        }

        t_h <- estimate_hourly_temp(t_min, t_max, t_min_next, lat, doy)
        rh_h <- estimate_hourly_rh(rh_daily = rh_d, t_daily = t_d, t_hourly = t_h)
        lwd_h <- estimate_lwd_rh(rh = rh_h, threshold = rh_threshold)

        tibble::tibble(temperature_hourly = t_h, rh_hourly = rh_h, leaf_wetness_hourly = lwd_h)
      }
    )) |>
    dplyr::select(-"t_min_next_internal", -"doy_internal", -"t_mean_internal") |>
    dplyr::mutate(hour = purrr::map(.data$weather_hourly, ~ 0:23)) |>
    tidyr::unnest(cols = c("weather_hourly", "hour")) |>
    dplyr::mutate(
      datetime = as.POSIXct(
        paste0(format(!!date_sym, "%Y-%m-%d"), " ", sprintf("%02d:00:00", .data$hour)),
        tz = "UTC"
      )
    ) |>
    # Calculate the daily sum of wet hours grouping back by the original date column
    dplyr::group_by(!!date_sym) |>
    dplyr::mutate(lwd_daily_sum = sum(.data$leaf_wetness_hourly, na.rm = TRUE)) |>
    dplyr::ungroup() |>
    dplyr::select("datetime", "temperature_hourly", "rh_hourly", "leaf_wetness_hourly", "lwd_daily_sum")

  return(expanded_data)
}
