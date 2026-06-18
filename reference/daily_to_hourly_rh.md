# Disaggregate Daily Weather Data to Hourly Relative Humidity

Takes a daily data frame containing temperature extrema and average
relative humidity, reconstructs the hourly temperature internally, and
uses it to generate a 24-hour profile of relative humidity for each day.
Returns a clean time-series data frame with combined datetime.

## Usage

``` r
daily_to_hourly_rh(data, date_col, t_min_col, t_max_col, rh_daily_col, lat_col)
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

## Value

A tibble (data frame) expanded to hourly resolution (24 rows per
original daily row) with three columns: `datetime` (POSIXct),
`temperature_hourly` (°C), and `rh_hourly` (%).

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

daily_to_hourly_rh(daily_series, date, tmin, tmax, rh_mean, lat)
#> # A tibble: 120 × 3
#>    datetime            temperature_hourly rh_hourly
#>    <dttm>                           <dbl>     <dbl>
#>  1 2026-06-01 00:00:00               14.7      92.8
#>  2 2026-06-01 01:00:00               14.2      95.5
#>  3 2026-06-01 02:00:00               13.9      97.9
#>  4 2026-06-01 03:00:00               13.5      99.9
#>  5 2026-06-01 04:00:00               13.3     100  
#>  6 2026-06-01 05:00:00               13.1     100  
#>  7 2026-06-01 06:00:00               12.9     100  
#>  8 2026-06-01 07:00:00               12.7     100  
#>  9 2026-06-01 08:00:00               12.6     100  
#> 10 2026-06-01 09:00:00               13.1     100  
#> # ℹ 110 more rows
```
