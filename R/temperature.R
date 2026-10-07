#' @title Reconstruct Hourly Temperatures from Daily Extrema
#' @description Reconstructs a 24-hour hourly temperature profile from daily minimum,
#' maximum, and the next day's minimum temperatures using a sine-exponential model.
#'
#' @param t_min Single numeric value of the current day's minimum temperature (°C).
#' @param t_max Single numeric value of the current day's maximum temperature (°C).
#' @param t_min_next Single numeric value of the next day's minimum temperature (°C).
#' @param lat Latitude of the location in decimal degrees.
#' @param doy Day of the year (Julian day, 1 to 365/366).
#' @param lon Optional. Longitude of the location in decimal degrees (negative for West).
#'   Default is \code{NULL} (assumes local solar time where noon is 12:00).
#' @param tz Optional. Time zone offset from UTC in hours (e.g., -3 for UTC-3).
#'   Default is \code{NULL}.
#' @param alpha Parameters for the time lag between solar noon and maximum
#' temperature (hours). Default is 2.75.
#' @param beta Parameters for the time lag between minimum temperature and sunrise (hours). Default is 1.40.
#' @param gamma Parameter representing the temperature characteristics decay rate at night. Default is 2.75.
#'
#' @importFrom purrr map_dbl map_lgl
#' @importFrom rlang abort
#'
#' @return A numeric vector of length 24 containing the reconstructed hourly temperatures (°C) from 00:00 to 23:00.
#' @export
#'
#' @examples
#' # Using default local solar time
#' estimate_hourly_temp(t_min = 12, t_max = 25, t_min_next = 13, lat = -27.28, doy = 150)
#'
#' # Accounting for civil time with longitude and time zone offset
#' estimate_hourly_temp(
#'   t_min = 12, t_max = 25, t_min_next = 13,
#'   lat = -27.28, doy = 150, lon = -50.58, tz = -3
#' )
estimate_hourly_temp <- function(t_min, t_max, t_min_next, lat, doy,
                                 lon = NULL, tz = NULL,
                                 alpha = 2.75, beta = 1.40, gamma = 2.75) {
  inputs <- list(t_min, t_max, t_min_next, lat, doy, alpha, beta, gamma)
  if (any(purrr::map_lgl(inputs, ~ !is.numeric(.x) || length(.x) != 1))) {
    rlang::abort("All inputs must be single numeric values.")
  }
  if (!is.null(lon) && (!is.numeric(lon) || length(lon) != 1)) {
    rlang::abort("'lon' must be a single numeric value when provided.")
  }
  if (!is.null(tz) && (!is.numeric(tz) || length(tz) != 1)) {
    rlang::abort("'tz' must be a single numeric value when provided.")
  }

  solar_noon <- estimate_solar_noon(doy = doy, lon = lon, tz = tz)
  sunrise    <- estimate_sunrise(lat = lat, doy = doy, solar_noon = solar_noon)
  sunset     <- estimate_sunset(lat = lat, doy = doy, solar_noon = solar_noon)
  day_length         <- sunset - sunrise # ou: estimate_daylength(lat = lat, doy = doy)

  t_n <- sunrise + beta
  t_x <- solar_noon + alpha

  hours <- 0:23
  t_hourly <- purrr::map_dbl(hours, function(t) {
    if (t >= t_n && t <= sunset) {
      term <- (t - t_n) / (day_length - beta + alpha)
      temp <- t_min + (t_max - t_min) * sin((pi / 2) * term)
      return(temp)
    }
    if (t < t_n) {
      t_adj <- t + 24
      t_s_prev <- sunset
      term_s <- (sunset - t_n) / (day_length - beta + alpha)
      t_sunset <- t_min + (t_max - t_min) * sin((pi / 2) * term_s)
      temp <- t_min + (t_sunset - t_min) * exp(-gamma * (t_adj - t_s_prev) / (24 - day_length + beta))
      return(temp)
    }
    if (t > sunset) {
      term_s <- (sunset - t_n) / (day_length - beta + alpha)
      t_sunset <- t_min + (t_max - t_min) * sin((pi / 2) * term_s)
      temp <- t_min_next + (t_sunset - t_min_next) * exp(-gamma * (t - sunset) / (24 - day_length + beta))
      return(temp)
    }
  })

  return(t_hourly)
}

#' @title Expand Daily Temperature Data Frame to Hourly Scale
#' @description Takes a data frame containing daily records (minimum and maximum
#' temperatures) and expands it into an hourly data frame (24 rows per day)
#' using a sine-exponential reconstruction model. Returns a clean time-series
#' data frame with combined datetime.
#'
#' @param data A data frame containing the daily weather records.
#' @param date_col Unquoted name of the column containing the Date object.
#' @param t_min_col Unquoted name of the column containing the current day's minimum temperature (°C).
#' @param t_max_col Unquoted name of the column containing the current day's maximum temperature (°C).
#' @param lat_col Unquoted name of the column containing the latitude (decimal degrees).
#' @param lon_col Optional unquoted name of the column containing the longitude (decimal degrees). Default is \code{NULL}.
#' @param tz Optional numeric value indicating the time zone offset from UTC in hours (e.g., -3). Default is \code{NULL}.
#'
#' @importFrom rlang abort ensym enquo quo_is_null .data
#' @importFrom dplyr mutate lead coalesce select
#' @importFrom purrr pmap map
#' @importFrom tidyr unnest
#'
#' @return A tibble (data frame) expanded to hourly resolution (24 rows per original daily row)
#' with two columns: \code{datetime} (POSIXct) and \code{temperature_hourly} (°C).
#' @export
#'
#' @examples
#' # Sample daily dataset representing 5 continuous days
#' daily_series <- tibble::tibble(
#'   date = as.Date("2026-06-01") + 0:4,
#'   lat = rep(-27.3, 5),
#'   lon = rep(-50.6, 5),
#'   tmin = c(12.0, 13.5, 11.0, 10.5, 14.0),
#'   tmax = c(22.0, 24.5, 21.0, 19.5, 23.0)
#' )
#'
#' # Standard usage (solar time)
#' daily_to_hourly_temp(daily_series, date, tmin, tmax, lat)
#'
#' # With longitude, time zone, and custom alpha parameter via ...
#' daily_to_hourly_temp(
#'   daily_series, date, tmin, tmax, lat,
#'   lon_col = lon, tz = -3
#' )
daily_to_hourly_temp <- function(data, date_col, t_min_col, t_max_col, lat_col,
                                 lon_col = NULL, tz = NULL) {
  if (!is.data.frame(data)) {
    rlang::abort("Input 'data' must be a data frame.")
  }

  date_sym  <- rlang::ensym(date_col)
  t_min_sym <- rlang::ensym(t_min_col)
  t_max_sym <- rlang::ensym(t_max_col)
  lat_sym   <- rlang::ensym(lat_col)

  lon_quo <- rlang::enquo(lon_col)
  has_lon <- !rlang::quo_is_null(lon_quo)

  cols_to_check <- c(
    as.character(date_sym), as.character(t_min_sym),
    as.character(t_max_sym), as.character(lat_sym)
    )

  if (has_lon) {
    lon_sym <- rlang::ensym(lon_col)
    cols_to_check <- c(cols_to_check, as.character(lon_sym))
  }

  if (!all(cols_to_check %in% colnames(data))) {
    rlang::abort("One or more specified columns do not exist in the provided data frame.")
  }

  expanded_data <- data |>
    dplyr::mutate(doy_internal = as.numeric(format(!!date_sym, "%j"))) |>
    dplyr::mutate(t_min_next_temp_internal = dplyr::lead(!!t_min_sym)) |>
    dplyr::mutate(t_min_next_temp_internal = dplyr::coalesce(.data$t_min_next_temp_internal, !!t_min_sym))

  if (has_lon) {
    expanded_data <- expanded_data |>
      dplyr::mutate(lon_internal = !!lon_sym)
  } else {
    expanded_data <- expanded_data |>
      dplyr::mutate(lon_internal = list(NULL))
  }

  expanded_data <- expanded_data |>
    dplyr::mutate(temperature_hourly = purrr::pmap(
      list(
        !!t_min_sym,
        !!t_max_sym,
        .data$t_min_next_temp_internal,
        !!lat_sym,
        .data$doy_internal,
        .data$lon_internal
        ),
      function(t_min, t_max, t_min_next, lat, doy, lon) {
        if (is.na(t_min) || is.na(t_max) || is.na(lat) || is.na(doy) || (!is.null(lon) && is.na(lon))) {
          return(rep(NA_real_, 24))
        }
        estimate_hourly_temp(
          t_min = t_min,
          t_max = t_max,
          t_min_next = t_min_next,
          lat = lat,
          doy = doy,
          lon = lon,
          tz = tz
        )
              }
    )) |>
    dplyr::select(-"t_min_next_temp_internal", -"doy_internal", -"lon_internal") |>
    dplyr::mutate(hour = purrr::map(.data$temperature_hourly, ~ 0:23)) |>
    tidyr::unnest(cols = c("temperature_hourly", "hour")) |>
    dplyr::mutate(
      datetime = as.POSIXct(
        paste0(format(!!date_sym, "%Y-%m-%d"), " ", sprintf("%02d:00:00", .data$hour)),
        tz = "UTC"
      )
    ) |>
    dplyr::select("datetime", "temperature_hourly")

  return(expanded_data)
}
