#' @title Download and Process INMET Weather Station Data
#' @description Downloads historical weather data from the Brazilian National Institute of
#' Meteorology (INMET), extracts data for a specific station, and applies data cleaning
#' and formatting.
#'
#' @param cache_dir A character string specifying the directory to save or look for
#' downloaded files. If \code{NULL}, a temporary directory is used.
#' @param station_code A character string with the INMET station code (e.g., "A001").
#' @param years A numeric vector of years to download (e.g., 2001:2005).
#' @param full_columns A logical value. If \code{FALSE} (default), returns a selected subset
#' of representative hourly variables. If \code{TRUE}, returns all processed meteorological
#' columns including minima and maxima.
#'
#' @return A \code{tibble} containing the processed hourly weather data.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' df_summary <- get_inmet_station(station_code = "A001", years = 2001)
#' head(df_summary)
#' }
get_inmet_station <- function(cache_dir = NULL, station_code, years, full_columns = FALSE) {

  if (!is.logical(full_columns) || length(full_columns) != 1) {
    rlang::abort("Argument 'full_columns' must be a single logical value.")
  }

  empty_output <- if (full_columns) {
    tibble::tibble(
      datetime = as.POSIXct(character(0)),
      precip = numeric(0),
      temp = numeric(0), temp_max = numeric(0), temp_min = numeric(0),
      rh = numeric(0), rh_max = numeric(0), rh_min = numeric(0),
      dew_point = numeric(0), dew_max = numeric(0), dew_min = numeric(0),
      press = numeric(0), press_max = numeric(0), press_min = numeric(0),
      solar_rad = numeric(0),
      wind_speed = numeric(0), wind_gust = numeric(0), wind_dir = numeric(0)
    )
  } else {
    tibble::tibble(
      datetime = as.POSIXct(character(0)),
      precip = numeric(0),
      temp = numeric(0),
      rh = numeric(0),
      dew_point = numeric(0),
      press = numeric(0),
      solar_rad = numeric(0),
      wind_speed = numeric(0)
    )
  }

  if (is.null(cache_dir)) {
    download_dir <- file.path(tempdir(), "zips_inmet")
  } else {
    download_dir <- cache_dir
  }

  if (!dir.exists(download_dir)) {
    dir.create(download_dir, recursive = TRUE)
  }

  download_inmet_data <- function(dest_dir, target_years) {
    for (yr in target_years) {
      file_name <- paste0(yr, ".zip")
      local_path <- file.path(dest_dir, file_name)

      if (file.exists(local_path)) {
        next
      }

      url_inmet <- paste0("https://portal.inmet.gov.br/uploads/dadoshistoricos/", yr, ".zip")

      download_success <- tryCatch({
        utils::download.file(
          url = url_inmet,
          destfile = local_path,
          method = "auto",
          cacheOK = FALSE,
          quiet = TRUE,
          mode = "wb"
        )
        TRUE
      }, error = function(e) {
        warning("Failed to download data for year ", yr, ": ", e$message, call. = FALSE)
        FALSE
      })

      if (!download_success && file.exists(local_path)) {
        file.remove(local_path)
      }
    }
  }

  download_inmet_data(dest_dir = download_dir, target_years = years)

  zip_vectors <- file.path(download_dir, paste0(years, ".zip"))
  existing_zips <- zip_vectors[file.exists(zip_vectors)]

  if (length(existing_zips) == 0) {
    warning("None of the requested .zip files are available.", call. = FALSE)
    return(empty_output)
  }

  extraction_dir <- file.path(tempdir(), "station_extraction")
  if (!dir.exists(extraction_dir)) {
    dir.create(extraction_dir, recursive = TRUE)
  }

  all_extracted_files <- character(0)

  for (zip_file in existing_zips) {
    zip_content <- utils::unzip(zipfile = zip_file, list = TRUE)
    target_files <- zip_content$Name[grepl(station_code, zip_content$Name, ignore.case = TRUE)]

    if (length(target_files) > 0) {
      utils::unzip(zipfile = zip_file, files = target_files, exdir = extraction_dir)
      full_paths <- file.path(extraction_dir, target_files)
      all_extracted_files <- c(all_extracted_files, full_paths)
    }
  }

  if (length(all_extracted_files) == 0) {
    unlink(extraction_dir, recursive = TRUE)
    warning("No data found for station '", station_code, "' in the requested period.", call. = FALSE)
    return(empty_output)
  }

  col_names <- c(
    "date_raw", "time_raw", "precip", "press", "press_max", "press_min",
    "solar_rad", "temp", "dew_point", "temp_max", "temp_min", "dew_max", "dew_min",
    "rh_max", "rh_min", "rh", "wind_dir", "wind_gust", "wind_speed", "drop"
  )

  consolidated_data <- all_extracted_files |>
    lapply(data.table::fread,
           skip = 8,
           col.names = col_names,
           encoding = "UTF-8",
           colClasses = list(character = 1)) |>
    data.table::rbindlist() |>
    tibble::as_tibble() |>
    dplyr::select(-"drop")

  unlink(extraction_dir, recursive = TRUE)

  test_cols <- setdiff(names(consolidated_data), c("date_raw", "time_raw", "solar_rad"))

  consolidated_data <- consolidated_data |>
    dplyr::mutate(
      row_failures = rowSums(dplyr::across(dplyr::all_of(test_cols), ~ .x == -9999), na.rm = TRUE),
      solar_rad = dplyr::case_when(
        .data$solar_rad != -9999 ~ .data$solar_rad,
        .data$solar_rad == -9999 & .data$row_failures > 3 ~ as.numeric(NA),
        .data$solar_rad == -9999 & .data$row_failures <= 3 ~ 0,
        TRUE ~ .data$solar_rad
      )
    ) |>
    dplyr::select(-"row_failures") |>
    dplyr::mutate(
      datetime = lubridate::ymd_hm(paste(.data$date_raw, .data$time_raw)),
      .before = 1
    ) |>
    dplyr::select(-"date_raw", -"time_raw") |>
    dplyr::mutate(dplyr::across(tidyselect::where(is.numeric), ~ dplyr::na_if(.x, -9999)))

  if (full_columns) {
    consolidated_data |>
      dplyr::select(
        "datetime",
        "precip",
        "temp", "temp_max", "temp_min",
        "rh", "rh_max", "rh_min",
        "dew_point", "dew_max", "dew_min",
        "press", "press_max", "press_min",
        "solar_rad",
        "wind_speed", "wind_gust", "wind_dir"
      )
  } else {
    consolidated_data |>
      dplyr::select(
        "datetime",
        "precip",
        "temp",
        "rh",
        "dew_point",
        "press",
        "solar_rad",
        "wind_speed"
      )
  }
}
