test_that("estimate_hourly_rh vector conversion behaves properly", {
  t_h_sample <- seq(15, 25, length.out = 24)
  result <- estimate_hourly_rh(rh_daily = 75, t_daily = 20, t_hourly = t_h_sample)

  expect_type(result, "double")
  expect_length(result, 24)
  expect_true(all(result >= 0 & result <= 100))
})

test_that("daily_to_hourly_rh expands daily table to clean datetime series", {
  daily_series <- tibble::tibble(
    date = as.Date("2026-06-01") + 0:4,
    lat = rep(-27.3, 5),
    tmin = c(12.0, 13.5, 11.0, 10.5, 14.0),
    tmax = c(22.0, 24.5, 21.0, 19.5, 23.0),
    rh_mean = c(80, 75, 85, 90, 70)
  )

  result <- daily_to_hourly_rh(
    data = daily_series,
    date_col = date,
    t_min_col = tmin,
    t_max_col = tmax,
    rh_daily_col = rh_mean,
    lat_col = lat
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 120) # 5 days * 24 hours

  # Strict column check for the clean format
  expect_equal(colnames(result), c("datetime", "temperature_hourly", "rh_hourly"))
  expect_s3_class(result$datetime, "POSIXct")
  expect_true(all(result$rh_hourly >= 0 & result$rh_hourly <= 100))
})

test_that("daily_to_hourly_rh maps NAs correctly down the datetime pipeline", {
  bad_series <- tibble::tibble(
    date = as.Date("2026-06-01") + 0:4,
    lat = rep(-27.3, 5),
    tmin = c(12.0, NA, 11.0, 10.5, 14.0),
    tmax = c(22.0, 24.5, 21.0, 19.5, 23.0),
    rh_mean = c(80, 75, 85, 90, 70)
  )

  result <- daily_to_hourly_rh(bad_series, date, tmin, tmax, rh_mean, lat)

  expect_equal(nrow(result), 120)
  expect_true(all(is.na(result$temperature_hourly[25:48])))
  expect_true(all(is.na(result$rh_hourly[25:48])))
})
