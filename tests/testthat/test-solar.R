test_that("solar calculations work as expected", {
  # No equinócio (~doy 80), o nascer do sol em hora solar deve ser aproximadamente 6h
  sr_equinox <- estimate_sunrise(lat = 0, doy = 80)
  expect_equal(round(sr_equinox, 1), 6.0)

  # Meio-dia solar padrão deve ser 12
  expect_equal(estimate_solar_noon(doy = 150), 12.0)

  # Vetorização
  doys <- c(1, 100, 200, 300)
  sr_vector <- estimate_sunrise(lat = -27.28, doy = doys)
  expect_length(sr_vector, 4)
  expect_true(all(sr_vector >= 0 & sr_vector <= 24))
})
