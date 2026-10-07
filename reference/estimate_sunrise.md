# Estimate Sunrise Time

Computes sunrise time in decimal hours based on latitude, day of the
year, and solar noon.

## Usage

``` r
estimate_sunrise(lat, doy, solar_noon = 12)
```

## Arguments

- lat:

  Latitude in decimal degrees (negative for South).

- doy:

  A numeric vector of day of the year (Julian day, 1 to 365/366) or a
  vector of `Date` / `POSIXt` objects.

- solar_noon:

  Optional. Numeric vector or scalar indicating solar noon in decimal
  hours. Default is 12.0.

## Value

A numeric vector containing sunrise times in decimal hours.

## Examples

``` r
# Sunrise on summer solstice for southern hemisphere (lat = -27.28)
estimate_sunrise(lat = -27.28, doy = 355)
#> [1] 5.13896
```
