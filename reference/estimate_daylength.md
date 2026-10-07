# Estimate Astronomical Day Length (Photoperiod)

Calculates the astronomical day length (photoperiod) in decimal hours.

## Usage

``` r
estimate_daylength(lat, doy)
```

## Arguments

- lat:

  Latitude in decimal degrees (negative for South).

- doy:

  A numeric vector of day of the year (Julian day, 1 to 365/366) or a
  vector of `Date` / `POSIXt` objects.

## Value

A numeric vector of day length values in decimal hours.

## Examples

``` r
estimate_daylength(lat = -27.28, doy = 172) # Winter solstice
#> [1] 10.27785
estimate_daylength(lat = -27.28, doy = 355) # Summer solstice
#> [1] 13.72208
```
