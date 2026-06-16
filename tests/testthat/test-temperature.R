test_that("estimate_hourly_temp outputs correct structure", {
  res <- estimate_hourly_temp(t_min = 10, t_max = 25, t_min_next = 11, lat = -27, doy = 180)

  expect_type(res, "double")
  expect_length(res, 24)
})

test_that("hourly temperatures respect extreme boundaries", {
  res <- estimate_hourly_temp(t_min = 10, t_max = 25, t_min_next = 12, lat = -27, doy = 180)

  # Reconstructed values should not ridiculously exceed max or fall below absolute min bounds
  expect_true(all(res >= (10 - 1)))
  expect_true(all(res <= (25 + 1)))
})

test_that("invalid arguments trigger errors", {
  expect_error(estimate_hourly_temp(t_min = "10", t_max = 25, t_min_next = 11, lat = -27, doy = 180))
  expect_error(estimate_hourly_temp(t_min = c(10, 11), t_max = 25, t_min_next = 11, lat = -27, doy = 180))
})
