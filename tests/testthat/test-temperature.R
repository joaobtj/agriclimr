test_that("estimate_hourly_temp outputs correct structure and limits", {
  # Test underlying vector function
  res <- estimate_hourly_temp(t_min = 10, t_max = 25, t_min_next = 11, lat = -27.3, doy = 152)

  expect_type(res, "double")
  expect_length(res, 24)

  # Reconstructed hourly values should respect physical boundaries of inputs
  expect_true(all(res >= (10 - 1)))
  expect_true(all(res <= (25 + 1)))
})

test_that("daily_to_hourly_temp expands a 5-day dataset correctly", {
  # Create a sample daily dataset mimicking the user's input structure
  daily_series <- tibble::tibble(
    date = as.Date("2026-06-01") + 0:4,
    lat  = rep(-27.3, 5),
    tmin = c(12.0, 13.5, 11.0, 10.5, 14.0),
    tmax = c(22.0, 24.5, 21.0, 19.5, 23.0)
  )

  # Run expansion function
  result <- daily_to_hourly_temp(
    data = daily_series,
    date_col = date,
    t_min_col = tmin,
    t_max_col = tmax,
    lat_col = lat
  )

  # Structural assertions
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 120) # 5 days * 24 hours = 120 rows

  # Column check
  expect_true("hour" %in% colnames(result))
  expect_true("temperature_hourly" %in% colnames(result))
  expect_equal(unique(result$hour), 0:23)

  # Metadata preservation check
  expect_equal(unique(result$lat), -27.3)
})

test_that("daily_to_hourly_temp handles missing values gracefully", {
  # Dataset containing NA in temperature records
  bad_series <- tibble::tibble(
    date = as.Date("2026-06-01") + 0:4,
    lat  = rep(-27.3, 5),
    tmin = c(12.0, NA, 11.0, 10.5, 14.0),
    tmax = c(22.0, 24.5, NA, 19.5, 23.0)
  )

  result <- daily_to_hourly_temp(bad_series, date, tmin, tmax, lat)

  expect_equal(nrow(result), 120)
  # Rows belonging to the 2nd day (hours 24 to 47) and 3rd day (hours 48 to 71) should have NAs
  expect_true(any(is.na(result$temperature_hourly)))
})

test_that("daily_to_hourly_temp enforces data frame types and arguments", {
  expect_error(daily_to_hourly_temp(c(1, 2, 3), date, tmin, tmax, lat))

  # Missing column error trigger
  wrong_df <- tibble::tibble(
    date = as.Date("2026-06-01"),
    lat = -27.3,
    wrong_tmin = 12,
    tmax = 22
  )
  expect_error(daily_to_hourly_temp(wrong_df, date, tmin, tmax, lat))
})
