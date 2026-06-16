test_that("estimate_lwd_rh correctly identifies wet and dry periods", {
  rh_sample <- c(80, 90, 95, 89)

  # Default threshold (90)
  expect_equal(estimate_lwd_rh(rh_sample), c(0, 1, 1, 0))

  # Custom threshold (85)
  expect_equal(estimate_lwd_rh(rh_sample, threshold = 85), c(0, 1, 1, 1))
})

test_that("estimate_lwd_rh handles missing values safely", {
  rh_na <- c(92, NA, 85)
  expect_equal(estimate_lwd_rh(rh_na), c(1, NA, 0))
})

test_that("estimate_lwd_rh errors on invalid inputs", {
  expect_error(estimate_lwd_rh("90"))
  expect_error(estimate_lwd_rh(c(80, 90), threshold = "ninety"))
})
