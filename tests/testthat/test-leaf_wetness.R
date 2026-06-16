test_that("estimate_lwd_rh basic threshold logic works", {
  hourly_rh <- c(80, 85, 90, 91, 84)
  expect_equal(estimate_lwd_rh(hourly_rh, threshold = 85), c(0, 1, 1, 1, 0))
})

test_that("daily_to_hourly_lwd builds full weather matrix correctly", {
  daily_series <- tibble::tibble(
    date = as.Date("2026-06-01") + 0:4,
    lat = rep(-27.3, 5),
    tmin = c(12.0, 13.5, 11.0, 10.5, 14.0),
    tmax = c(22.0, 24.5, 21.0, 19.5, 23.0),
    rh_mean = c(80, 75, 85, 90, 70)
  )

  result <- daily_to_hourly_lwd(daily_series, date, tmin, tmax, rh_mean, lat, rh_threshold = 85)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 120) # 5 days * 24 hours

  # Assert columns matching strict output design
  expected_cols <- c("datetime", "temperature_hourly", "rh_hourly", "leaf_wetness_hourly", "lwd_daily_sum")
  expect_equal(colnames(result), expected_cols)
  expect_s3_class(result$datetime, "POSIXct")

  # Leaf wetness binary constraint check
  expect_true(all(result$leaf_wetness_hourly %in% c(0, 1)))
  expect_true(all(result$lwd_daily_sum >= 0 & result$lwd_daily_sum <= 24))
})

test_that("daily_to_hourly_lwd safely handles NAs down the pipe", {
  bad_series <- tibble::tibble(
    date = as.Date("2026-06-01") + 0:4,
    lat = rep(-27.3, 5),
    tmin = c(12.0, NA, 11.0, 10.5, 14.0),
    tmax = c(22.0, 24.5, 21.0, 19.5, 23.0),
    rh_mean = c(80, 75, 85, 90, 70)
  )

  result <- daily_to_hourly_lwd(bad_series, date, tmin, tmax, rh_mean, lat)

  expect_equal(nrow(result), 120)
  expect_true(all(is.na(result$leaf_wetness_hourly[25:48])))
})
