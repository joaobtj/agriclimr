# Reconstruct Hourly Temperatures from Daily Extrema

Reconstructs a 24-hour hourly temperature profile from daily minimum,
maximum, and the next day's minimum temperatures using a
sine-exponential model.

## Usage

``` r
estimate_hourly_temp(
  t_min,
  t_max,
  t_min_next,
  lat,
  doy,
  alpha = 2.75,
  beta = 1.4,
  gamma = 2.75
)
```

## Arguments

- t_min:

  Single numeric value of the current day's minimum temperature (°C).

- t_max:

  Single numeric value of the current day's maximum temperature (°C).

- t_min_next:

  Single numeric value of the next day's minimum temperature (°C).

- lat:

  Latitude of the location in decimal degrees.

- doy:

  Day of the year (Julian day, 1 to 365/366).

- alpha:

  Parameters for the time lag between solar noon and maximum temperature
  (hours). Default is 2.75.

- beta:

  Parameters for the time lag between minimum temperature and sunrise
  (hours). Default is 1.40.

- gamma:

  Parameter representing the temperature characteristics decay rate at
  night. Default is 2.75.

## Value

A numeric vector of length 24 containing the reconstructed hourly
temperatures (°C) from 00:00 to 23:00.

## Examples

``` r
estimate_hourly_temp(t_min = 12, t_max = 25, t_min_next = 13, lat = -27.28, doy = 150)
#>  [1] 15.48837 14.90350 14.41670 14.01151 13.67425 13.39355 13.15990 12.96543
#>  [9] 12.80356 13.39885 15.10689 16.75962 18.32764 19.78303 21.09988 22.25476
#> [17] 23.22710 23.99961 22.62654 21.01254 19.66914 18.55098 17.62029 16.84564
```
