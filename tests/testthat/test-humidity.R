
test_that("estimate_hourly_rh returns correct vector structure and boundaries", {
  t_h_sample <- seq(15, 25, length.out = 24)
  result <- estimate_hourly_rh(rh_daily = 75, t_daily = 20, t_hourly = t_h_sample)

  expect_type(result, "double")
  expect_length(result, 24)
  expect_true(all(result >= 0 & result <= 100))
})

test_that("estimate_hourly_rh outputs expected flat response when inputs align", {
  t_h_flat <- rep(22, 24)
  result <- estimate_hourly_rh(rh_daily = 65, t_daily = 22, t_hourly = t_h_flat)

  expect_equal(result, rep(65, 24))
})

test_that("estimate_hourly_rh handles input constraints strictly", {
  expect_error(estimate_hourly_rh(rh_daily = c(70, 80), t_daily = 20, t_hourly = rep(20, 24)))
  expect_error(estimate_hourly_rh(rh_daily = 70, t_daily = 20, t_hourly = c(20, 21)))
})
