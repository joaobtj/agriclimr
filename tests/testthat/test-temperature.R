test_that("estimate_hourly_temp outputs correct structure and limits", {
  res <- estimate_hourly_temp(t_min = 10, t_max = 25, t_min_next = 11, lat = -27.3, doy = 152)

  expect_type(res, "double")
  expect_length(res, 24)
  expect_true(all(res >= (10 - 1)))
  expect_true(all(res <= (25 + 1)))
})

test_that("daily_to_hourly_temp expands a 5-day dataset into a clean datetime series", {
  daily_series <- tibble::tibble(
    date = as.Date("2026-06-01") + 0:4,
    lat  = rep(-27.3, 5),
    tmin = c(12.0, 13.5, 11.0, 10.5, 14.0),
    tmax = c(22.0, 24.5, 21.0, 19.5, 23.0)
  )

  result <- daily_to_hourly_temp(daily_series, date, tmin, tmax, lat)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 120) # 5 days * 24 hours = 120 rows

  # Strict column structure check
  expect_equal(colnames(result), c("datetime", "temperature_hourly"))
  expect_s3_class(result$datetime, "POSIXct")
})

test_that("daily_to_hourly_temp handles missing values gracefully in datetime format", {
  bad_series <- tibble::tibble(
    date = as.Date("2026-06-01") + 0:4,
    lat  = rep(-27.3, 5),
    tmin = c(12.0, NA, 11.0, 10.5, 14.0),
    tmax = c(22.0, 24.5, NA, 19.5, 23.0)
  )

  result <- daily_to_hourly_temp(bad_series, date, tmin, tmax, lat)

  expect_equal(nrow(result), 120)
  expect_true(any(is.na(result$temperature_hourly)))
})

test_that("daily_to_hourly_temp enforces data frame types and arguments", {
  expect_error(daily_to_hourly_temp(c(1, 2, 3), date, tmin, tmax, lat))
})
