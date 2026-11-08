#' @title Extract Point Data from BR-DWGD NetCDF Files
#' @description Extracts a daily time series of specified weather variables for a given
#' coordinate (longitude and latitude) from the Brazilian Daily Weather Gridded Data
#' (BR-DWGD) NetCDF datasets, identifying the closest grid cell to the target location.
#'
#' @param target_longitude Numeric. Longitude of the target location in decimal degrees.
#' @param target_latitude Numeric. Latitude of the target location in decimal degrees.
#' @param weather_variables Character vector. Variables to extract. Allowed values are:
#' \itemize{
#'   \item \code{"pr"}: Precipitation (mm).
#'   \item \code{"Tmin"}: Minimum air temperature (°C).
#'   \item \code{"Tmax"}: Maximum air temperature (°C).
#'   \item \code{"Rs"}: Incident solar radiation (MJ m\eqn{^{-2}} day\eqn{^{-1}}).
#'   \item \code{"RH"}: Relative humidity (percent).
#'   \item \code{"u2"}: Wind speed at 2 m height (m s\eqn{^{-1}}).
#'   \item \code{"ETo"}: Reference evapotranspiration (mm day\eqn{^{-1}}).
#' }
#' Defaults to all.
#' @param date_range Character vector of length 2 (\code{c("YYYY-MM-DD", "YYYY-MM-DD")}) or \code{NULL}.
#' Start and end dates. If \code{NULL} (default), extracts the entire period available in the
#' NetCDF files.
#' @param nc_files_directory Character. Path to the local directory containing the BR-DWGD
#' NetCDF files. Defaults to current directory (\code{"."}).
#'
#' @return A \code{tibble} containing the columns \code{date}, \code{lat}, \code{lon},
#' and each requested weather variable.
#'
#' @references
#' Xavier, A. C., Scanlon, B. R., King, C. W., & Alves, A. I. (2022). New improved
#' Brazilian daily weather gridded data (1961–2020). International Journal of Climatology,
#' 42(16), 8390–8404. \url{https://doi.org/10.1002/joc.7731}
#'
#' @importFrom rlang abort :=
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows distinct filter arrange full_join
#' @importFrom purrr reduce
#' @importFrom ncdf4 nc_open nc_close ncvar_get ncatt_get
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Ensure NetCDF files are present in 'nc_files_directory'
#' df_point <- get_brdwgd_weather(
#'   target_longitude = -50.5995,
#'   target_latitude = -27.2863,
#'   weather_variables = c("pr", "Tmax", "Tmin"),
#'   date_range = c("1983-01-01", "1983-03-31"),
#'   nc_files_directory = "D:/clima_Xavier"
#' )
#' print(df_point)
#' }
get_brdwgd <- function(target_longitude,
                       target_latitude,
                       weather_variables = c("pr", "Tmin", "Tmax", "Rs", "RH", "u2", "ETo"),
                       date_range = NULL,
                       nc_files_directory = ".") {
  # --- Input validation ---
  if (!is.numeric(target_longitude) || length(target_longitude) != 1) {
    rlang::abort("Argument 'target_longitude' must be a single numeric value.")
  }
  if (!is.numeric(target_latitude) || length(target_latitude) != 1) {
    rlang::abort("Argument 'target_latitude' must be a single numeric value.")
  }

  # Check coordinates against approximate geographic limits of Brazil
  if (target_longitude > -34 || target_longitude < -74 || target_latitude > 5.5 || target_latitude < -34) {
    warning("Target coordinates are outside typical bounds of Brazil. Verify if coordinates are correct.", call. = FALSE)
  }

  allowed_vars <- c("pr", "Tmin", "Tmax", "Rs", "RH", "u2", "ETo")
  invalid_vars <- setdiff(weather_variables, allowed_vars)
  if (length(invalid_vars) > 0) {
    rlang::abort(paste0(
      "Invalid weather variable(s): ", paste(invalid_vars, collapse = ", "),
      ". Allowed variables are: ", paste(allowed_vars, collapse = ", ")
    ))
  }

  if (!dir.exists(nc_files_directory)) {
    rlang::abort(paste0("NetCDF directory not found: ", nc_files_directory))
  }

  # --- Date range processing ---
  start_date_requested <- NULL
  end_date_requested <- NULL

  if (!is.null(date_range)) {
    if (length(date_range) != 2) {
      rlang::abort("Argument 'date_range' must be a vector of length 2 (start and end).")
    }
    date_range_processed <- tryCatch(as.Date(date_range), error = function(e) NULL)
    if (is.null(date_range_processed) || any(is.na(date_range_processed))) {
      rlang::abort("Argument 'date_range' could not be converted to Date. Use 'YYYY-MM-DD' format.")
    }
    if (date_range_processed[1] > date_range_processed[2]) {
      rlang::abort("Start date in 'date_range' cannot be after the end date.")
    }
    start_date_requested <- date_range_processed[1]
    end_date_requested <- date_range_processed[2]
  }

  # --- Internal helper function to read a slice from a single NetCDF file ---
  read_single_nc_slice <- function(nc_path, var_name) {
    nc_obj <- tryCatch(ncdf4::nc_open(nc_path), error = function(e) {
      warning("Could not open NetCDF file '", nc_path, "': ", e$message, call. = FALSE)
      NULL
    })
    if (is.null(nc_obj)) {
      return(NULL)
    }

    # Ensure file connection is closed when exiting helper function
    on.exit(ncdf4::nc_close(nc_obj), add = TRUE)

    nc_lats <- tryCatch(ncdf4::ncvar_get(nc_obj, varid = "latitude"), error = function(e) NULL)
    nc_lons <- tryCatch(ncdf4::ncvar_get(nc_obj, varid = "longitude"), error = function(e) NULL)
    nc_time_raw <- tryCatch(ncdf4::ncvar_get(nc_obj, varid = "time"), error = function(e) NULL)

    if (is.null(nc_lats) || is.null(nc_lons) || is.null(nc_time_raw)) {
      warning("Could not read coordinates or time from '", nc_path, "'.", call. = FALSE)
      return(NULL)
    }

    # Identify nearest regular grid indices
    lon_idx <- which.min(abs(nc_lons - target_longitude))
    lat_idx <- which.min(abs(nc_lats - target_latitude))
    actual_lat <- nc_lats[lat_idx]
    actual_lon <- nc_lons[lon_idx]

    # Parse reference origin and time units
    time_units_str <- ncdf4::ncatt_get(nc_obj, "time")$units
    origin_str <- sub("^.*since\\s+", "", time_units_str)
    time_origin <- as.Date(origin_str)

    is_hours <- grepl("^hours", time_units_str, ignore.case = TRUE)
    is_days <- grepl("^days", time_units_str, ignore.case = TRUE)

    if (is_hours) {
      nc_dates <- as.Date(nc_time_raw / 24, origin = time_origin)
    } else if (is_days) {
      nc_dates <- as.Date(nc_time_raw, origin = time_origin)
    } else {
      warning("Unsupported time unit in '", nc_path, "'.", call. = FALSE)
      return(NULL)
    }

    # Locate time indices matching requested date bounds
    if (is.null(start_date_requested)) {
      valid_time_indices <- seq_along(nc_dates)
    } else {
      valid_time_indices <- which(nc_dates >= start_date_requested & nc_dates <= end_date_requested)
    }

    if (length(valid_time_indices) == 0) {
      return(NULL)
    }

    start_t <- min(valid_time_indices)
    count_t <- max(valid_time_indices) - start_t + 1

    # Extract point vector slice across matching time steps
    vals <- tryCatch(
      ncdf4::ncvar_get(
        nc_obj,
        varid = var_name,
        start = c(lon_idx, lat_idx, start_t),
        count = c(1, 1, count_t)
      ),
      error = function(e) {
        warning("Failed reading variable '", var_name, "' from '", nc_path, "': ", e$message, call. = FALSE)
        NULL
      }
    )

    if (is.null(vals) || length(vals) != count_t) {
      return(NULL)
    }

    tibble::tibble(
      date = nc_dates[start_t:(start_t + count_t - 1)],
      lat = actual_lat,
      lon = actual_lon,
      !!var_name := as.numeric(vals)
    )
  }

  # --- File iteration and variable extraction ---
  all_variables_list <- list()

  for (var_name in weather_variables) {
    pattern <- paste0("^", var_name, "_.*\\.nc$")
    var_files <- list.files(path = nc_files_directory, pattern = pattern, full.names = TRUE)

    if (length(var_files) == 0) {
      warning("No NetCDF files found for variable '", var_name, "' in '", nc_files_directory, "'.", call. = FALSE)
      next
    }

    file_results <- lapply(var_files, read_single_nc_slice, var_name = var_name)
    file_results <- file_results[!vapply(file_results, is.null, logical(1))]

    if (length(file_results) > 0) {
      all_variables_list[[var_name]] <- dplyr::bind_rows(file_results) |>
        dplyr::distinct(date, .keep_all = TRUE)
    }
  }

  if (length(all_variables_list) == 0) {
    warning("No data could be extracted for any variable in the specified date range.", call. = FALSE)
    return(tibble::tibble())
  }

  # Merge all variables into a single data frame
  consolidated_df <- purrr::reduce(all_variables_list, dplyr::full_join, by = c("date", "lat", "lon")) |>
    dplyr::arrange(date)

  if (!is.null(start_date_requested)) {
    consolidated_df <- consolidated_df |>
      dplyr::filter(date >= start_date_requested, date <= end_date_requested)
  }

  if (nrow(consolidated_df) == 0) {
    warning("Extracted dataset is empty after applying date filters.", call. = FALSE)
    return(consolidated_df)
  }

  # --- Date coverage validation and user notifications ---
  actual_start <- min(consolidated_df$date, na.rm = TRUE)
  actual_end <- max(consolidated_df$date, na.rm = TRUE)

  if (is.null(date_range)) {
    warning("No 'date_range' specified. Returned complete available period from ",
      actual_start, " to ", actual_end, ".",
      call. = FALSE
    )
  } else {
    if (start_date_requested < actual_start || end_date_requested > actual_end) {
      warning("Requested date range (", start_date_requested, " to ", end_date_requested,
        ") exceeds available records. Actual returned period is ",
        actual_start, " to ", actual_end, ".",
        call. = FALSE
      )
    }
  }

  consolidated_df
}
