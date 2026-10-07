# Estimate Solar Noon

Calculates the solar noon time in decimal hours. By default, it returns
local solar noon (12.0 h), but it can compute civil standard clock time
when longitude and time zone offset are provided.

## Usage

``` r
estimate_solar_noon(doy, lon = NULL, tz = NULL)
```

## Arguments

- doy:

  A numeric vector of day of the year (Julian day, 1 to 365/366) or a
  vector of `Date` / `POSIXt` objects.

- lon:

  Optional. Longitude in decimal degrees (negative for West). If
  omitted, local solar noon is returned (12.0).

- tz:

  Optional. Time zone offset from UTC in hours (e.g., -3 for UTC-3).

## Value

A numeric vector representing solar noon in decimal hours (0 to 24).

## Examples

``` r
# Local solar noon (default)
estimate_solar_noon(doy = 180)
#> [1] 12

# Civil clock time for solar noon with longitude and UTC offset
estimate_solar_noon(doy = 180, lon = -50.58, tz = -3)
#> [1] 12.42346
```
