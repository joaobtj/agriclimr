# Expand Daily Temperature Data Frame to Hourly Scale

Takes a data frame containing daily records (minimum and maximum
temperatures) and expands it into an hourly data frame (24 rows per day)
using a sine-exponential reconstruction model. Returns a clean
time-series data frame with combined datetime.

## Usage

``` r
daily_to_hourly_temp(data, date_col, t_min_col, t_max_col, lat_col)
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

- lat_col:

  Unquoted name of the column containing the latitude (decimal degrees).

## Value

A tibble (data frame) expanded to hourly resolution (24 rows per
original daily row) with two columns: `datetime` (POSIXct) and
`temperature_hourly` (°C).

## Examples

``` r

# Sample daily dataset representing 5 continuous days
daily_series <- tibble::tibble(
  date = as.Date("2026-06-01") + 0:4,
  lat = rep(-27.3, 5),
  tmin = c(12.0, 13.5, 11.0, 10.5, 14.0),
  tmax = c(22.0, 24.5, 21.0, 19.5, 23.0)
)

daily_to_hourly_temp(daily_series, date, tmin, tmax, lat)
#> # A tibble: 120 × 2
#>    datetime            temperature_hourly
#>    <dttm>                           <dbl>
#>  1 2026-06-01 00:00:00               14.7
#>  2 2026-06-01 01:00:00               14.2
#>  3 2026-06-01 02:00:00               13.9
#>  4 2026-06-01 03:00:00               13.5
#>  5 2026-06-01 04:00:00               13.3
#>  6 2026-06-01 05:00:00               13.1
#>  7 2026-06-01 06:00:00               12.9
#>  8 2026-06-01 07:00:00               12.7
#>  9 2026-06-01 08:00:00               12.6
#> 10 2026-06-01 09:00:00               13.1
#> # ℹ 110 more rows
```
