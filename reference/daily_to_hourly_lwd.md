# Disaggregate Daily Weather Data to Hourly Leaf Wetness Duration

Takes a daily data frame containing temperature extrema and average
relative humidity, reconstructs the hourly parameters internally, and
computes the hourly leaf wetness presence along with its daily
operational hour sum.

## Usage

``` r
daily_to_hourly_lwd(
  data,
  date_col,
  t_min_col,
  t_max_col,
  rh_daily_col,
  lat_col,
  rh_threshold = 85
)
```

## Arguments

- data:

  A data frame containing the daily weather records.

- date_col:

  Unquoted name of the column containing the Date object.

- t_min_col:

  Unquoted name of the column containing the current day's minimum
  temperature (°C).

- t_max_col:

  Unquoted name of the column containing the current day's maximum
  temperature (°C).

- rh_daily_col:

  Unquoted name of the column containing the daily average relative
  humidity (%).

- lat_col:

  Unquoted name of the column containing the latitude (decimal degrees).

- rh_threshold:

  A single numeric value indicating the RH percentage above which leaf
  wetness is assumed to occur. Default is 85% based on optimized
  regional validations.

## Value

A tibble (data frame) expanded to hourly resolution (24 rows per
original daily row) with four columns: `datetime` (POSIXct),
`temperature_hourly` (°C), `rh_hourly` (\\ `leaf_wetness_hourly` (binary
0/1), and `lwd_daily_sum` (total wet hours in that day).

## Examples

``` r
# Sample daily dataset matching your exact input structure with 5 continuous days
daily_series <- tibble::tibble(
  date = as.Date("2026-06-01") + 0:4,
  lat = rep(-27.3, 5),
  tmin = c(12.0, 13.5, 11.0, 10.5, 14.0),
  tmax = c(22.0, 24.5, 21.0, 19.5, 23.0),
  rh_mean = c(80, 75, 85, 90, 70)
)

daily_to_hourly_lwd(daily_series, date, tmin, tmax, rh_mean, lat, rh_threshold = 85)
#> # A tibble: 120 × 5
#>    datetime            temperature_hourly rh_hourly leaf_wetness_hourly
#>    <dttm>                           <dbl>     <dbl>               <dbl>
#>  1 2026-06-01 00:00:00               14.7      92.8                   1
#>  2 2026-06-01 01:00:00               14.2      95.5                   1
#>  3 2026-06-01 02:00:00               13.9      97.9                   1
#>  4 2026-06-01 03:00:00               13.5      99.9                   1
#>  5 2026-06-01 04:00:00               13.3     100                     1
#>  6 2026-06-01 05:00:00               13.1     100                     1
#>  7 2026-06-01 06:00:00               12.9     100                     1
#>  8 2026-06-01 07:00:00               12.7     100                     1
#>  9 2026-06-01 08:00:00               12.6     100                     1
#> 10 2026-06-01 09:00:00               13.1     100                     1
#> # ℹ 110 more rows
#> # ℹ 1 more variable: lwd_daily_sum <dbl>
```
