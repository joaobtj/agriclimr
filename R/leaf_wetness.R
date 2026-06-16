#' @title Estimate Leaf Wetness Duration (LWD)
#' @description Estimates the number of hours of leaf wetness based on a Relative
#' Humidity (RH) threshold.
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

  # Ensure RH values are within logical bounds
  if (any(rh < 0 | rh > 100, na.rm = TRUE)) {
    rlang::warn("Some 'rh' values are outside the expected range of 0 to 100%.")
  }

  # Binary estimation: 1 if RH >= threshold, 0 if RH < threshold
  lwd <- ifelse(rh >= threshold, 1, 0)

  return(lwd)
}
