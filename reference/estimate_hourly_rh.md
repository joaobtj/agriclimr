# Estimate Hourly Relative Humidity from Daily Metrics

Reconstructs a 24-hour profile of hourly relative humidity values based
on daily average relative humidity, daily average temperature, and a
vector of hourly temperatures. It assumes that the actual vapor pressure
remains constant throughout the day.

## Usage

``` r
estimate_hourly_rh(rh_daily, t_daily, t_hourly)
```

## Arguments

- rh_daily:

  A single numeric value representing the daily average relative
  humidity (%).

- t_daily:

  A single numeric value representing the daily average temperature
  (°C).

- t_hourly:

  A numeric vector of length 24 containing the hourly temperatures (°C).

## Value

A numeric vector of length 24 containing estimated hourly relative
humidity values (%).

## Examples

``` r
daily_rh <- 80
daily_t <- 20
hourly_t <- c(16, 15, 14, 14, 15, 17, 19, 21, 23, 24, 25, 25,
              24, 23, 22, 21, 20, 19, 18, 17, 17, 16, 16, 16)

estimate_hourly_rh(rh_daily = daily_rh, t_daily = daily_t, t_hourly = hourly_t)
#>  [1] 100.00000 100.00000 100.00000 100.00000 100.00000  96.53696  85.12928
#>  [8]  75.21596  66.58361  62.69024  59.05165  59.05165  62.69024  66.58361
#> [15]  70.75165  75.21596  80.00000  85.12928  90.63153  96.53696  96.53696
#> [22] 100.00000 100.00000 100.00000
```
