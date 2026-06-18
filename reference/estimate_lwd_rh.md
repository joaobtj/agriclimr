# Estimate Leaf Wetness Duration (LWD)

Estimates the number of hours of leaf wetness based on a Relative
Humidity (RH) threshold. This is a standard empirical approach used in
agricultural meteorology to predict plant disease risks.

## Usage

``` r
estimate_lwd_rh(rh, threshold = 90)
```

## Arguments

- rh:

  A numeric vector containing hourly Relative Humidity values (0 to
  100).

- threshold:

  A numeric value indicating the RH percentage above which leaf wetness
  is assumed to occur. Default is 90%.

## Value

A numeric vector of the same length as `rh` containing binary values: 1
(wet) or 0 (dry).

## Examples

``` r
hourly_rh <- c(85, 88, 91, 95, 92, 87, 80)
estimate_lwd_rh(hourly_rh, threshold = 90)
#> [1] 0 0 1 1 1 0 0
```
