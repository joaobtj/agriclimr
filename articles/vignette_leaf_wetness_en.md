# Leaf Wetness Duration Modeling from Daily Data

## Introduction

Leaf Wetness Duration (LWD) represents the daily period during which
free water is present on the canopy surface. It is a fundamental
agrometeorological variable for predicting infection risks caused by
phytopathogenic fungi, such as downy mildew and powdery mildew.

Although epidemiological models operate mostly at an hourly scale,
historical records and climate change projections for the 21st century
often provide meteorological data only at daily resolution. The
`agriclimr` package implements a robust methodological framework to
overcome this limitation, enabling the reconstruction of hourly
temperature and relative humidity profiles from daily extremes to
estimate daily LWD.

The methodology described herein is based on the work of **Zito et
al. (2020)** (*Optimization of a leaf wetness duration model*,
Agricultural and Forest Meteorology).

------------------------------------------------------------------------

## Model Flow Structure

The simulation process is divided into three fundamental steps
integrated into the package:

1.  **Hourly Temperature Reconstruction:** Computed via the
    sine-exponential model by Wann et al. (1985).
2.  **Hourly Relative Humidity Estimation:** Derived based on the
    assumption of a constant actual vapor pressure throughout the day.
3.  **Hourly and Daily Leaf Wetness Determination:** Applied using an
    empirical relative humidity threshold (Sentelhas et al., 2008).

------------------------------------------------------------------------

## Mathematical Foundation

### Step 1: Sine-Exponential Temperature Model

The daily temperature cycle is reconstructed in two phases (diurnal and
nocturnal) using equations based on astronomical parameters (daylength,
sunrise, and sunset times):

**A. Diurnal Phase:** Between the time of minimum temperature ($`t_n`$,
shortly after sunrise) and sunset ($`t_s`$):

``` math
T(t) = T_{min} + (T_{max} - T_{min}) \cdot \sin\left[\frac{\pi \cdot (t - t_n)}{dl - \beta + \alpha}\right]
```

Where:

- $`T_{min}`$ and $`T_{max}`$: Minimum and maximum temperature of the
  current day.
- $`dl`$: Daylength (photoperiod in hours), calculated from latitude and
  solar declination.
- $`\alpha`$: Time lag between solar noon and the time of maximum
  temperature (default: $`2.75`$ h).
- $`\beta`$: Time lag between sunrise and the time of minimum
  temperature (default: $`1.40`$ h).

**B. Nocturnal Phase:** Between sunset ($`t_s`$) and sunrise of the next
day ($`t_n'`$):

``` math
T(t) = T_{min\_next} + (T_{sunset} - T_{min\_next}) \cdot \exp\left[\frac{-\gamma \cdot (t - t_s)}{24 - dl + \beta}\right]
```

Where:

- $`T_{min\_next}`$: Minimum temperature of the next day.
- $`T_{sunset}`$: Calculated temperature at sunset ($`t_s`$).
- $`\gamma`$: Night cooling coefficient (default: $`2.75`$).

### Step 2: Hourly Relative Humidity Reconstruction

It is assumed that the actual water vapor pressure ($`e_a`$) remains
constant over the 24-hour period ($`e_{ah} = e_{ad}`$). The hourly
variation in Relative Humidity ($`UR_h`$ or $`RH_h`$) stems purely from
the oscillation of the saturation vapor pressure ($`e^o_{(T)}`$), which
is a direct function of the hourly temperature calculated in the
previous step (Tetens’ Equation):

``` math
e^o_{(T)} = 0.6108 \cdot \exp\left(\frac{17.27 \cdot T}{T + 237.3}\right)
```

Thus, the conversion is given by:

``` math
RH_h = 100 \cdot \frac{RH_d \cdot e^o_{(T_d)}}{e^o_{(T_h)}}
```

Where $`RH_d`$ is the daily mean relative humidity and $`T_d`$ is the
daily mean temperature.

### Step 3: Leaf Wetness Estimation

Hourly Leaf Wetness Duration is treated as a binary variable (0 = dry, 1
= wet). Wetness is computed whenever $`RH_h`$ reaches or exceeds a
structured critical threshold ($`RH_{lim}`$):

``` math
MF_h = \begin{cases} 1, & \text{if } RH_h \ge RH_{lim} \\ 0, & \text{if } RH_h < RH_{lim} \end{cases}
```

The summation results in the total daily value of LWD (0 to 24 hours):

``` math
LWD_{daily} = \sum_{h=0}^{23} MF_h
```

------------------------------------------------------------------------

## Practical Implementation with `agriclimr`

The package offers modular functions as well as high-level functions for
direct data processing of tabular datasets (`data.frame` or `tibble`).

### Base Example: Single Vector Execution

To understand the internal mechanics, we can test the basic hourly
estimation functions for a single day:

``` r

library(agriclimr)

# Defining meteorological variables for a hypothetical day
t_min <- 12.0
t_max <- 25.0
t_min_next <- 13.0
lat <- -27.3
doy <- 150 # Day of the year (June)

# 1. Reconstruct 24 hours of temperature
temperaturas_h <- estimate_hourly_temp(
  t_min = t_min,
  t_max = t_max,
  t_min_next = t_min_next,
  lat = lat,
  doy = doy
)
temperaturas_h
#>  [1] 15.48827 14.90347 14.41671 14.01155 13.67432 13.39362 13.15999 12.96552
#>  [9] 12.80365 13.39782 15.10608 16.75904 18.32727 19.78285 21.09987 22.25487
#> [17] 23.22730 23.99984 22.62528 21.01162 19.66849 18.55053 17.61999 16.84546

# 2. Reconstruct hourly Relative Humidity (with daily mean RH = 80%)
ur_h <- estimate_hourly_rh(
  rh_daily = 80,
  t_daily = (t_min + t_max) / 2,
  t_hourly = temperaturas_h
)
ur_h
#>  [1]  96.82462 100.00000 100.00000 100.00000 100.00000 100.00000 100.00000
#>  [8] 100.00000 100.00000 100.00000  99.23086  89.28305  80.87074  73.85334
#> [15]  68.09016  63.45034  59.81901  57.10071  62.03861  68.46008  74.37916
#> [22]  79.74727  84.54910  88.79467

# 3. Determine the binary leaf wetness vector (Threshold = 85%)
molhamento_h <- estimate_lwd_rh(ur_h, threshold = 85)
molhamento_h
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 1

# Sum of daily leaf wetness
sum(molhamento_h)
#> [1] 13
```

### Processing Daily Time Series

In operational routines, you will use the main function
[`daily_to_hourly_lwd()`](https://joaobtj.github.io/agriclimr/reference/daily_to_hourly_lwd.md),
which manages the entire internal disaggregation workflow and returns a
structured output.

``` r

library(agriclimr)

# Creating an example daily data series (5 continuous days)
dados_diarios <- tibble::tibble(
  data     = as.Date("2026-06-01") + 0:4,
  lat      = rep(-27.3, 5),
  tmin     = c(12.0, 13.5, 11.0, 10.5, 14.0),
  tmax     = c(22.0, 24.5, 21.0, 19.5, 23.0),
  ur_media = c(80, 75, 85, 90, 70)
)

# Applying the automated package function
resultado_horario <- daily_to_hourly_lwd(
  data = dados_diarios,
  date_col = data,
  t_min_col = tmin,
  t_max_col = tmax,
  rh_daily_col = ur_media,
  lat_col = lat,
  rh_threshold = 85 
)

# Viewing the first structured records
head(resultado_horario, 12)
#> # A tibble: 12 × 5
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
#> 11 2026-06-01 10:00:00               14.4      94.6                   1
#> 12 2026-06-01 11:00:00               15.7      87.2                   1
#> # ℹ 1 more variable: lwd_daily_sum <dbl>
```

## References

- **Zito, S., Castel, T., Richard, Y., Rega, M., & Bois, B. (2020).**
  Optimization of a leaf wetness duration model. *Agricultural and
  Forest Meteorology*, 291, 108087.
- **Wann, M., Yen, D., & Gold, H. J. (1985).** Evaluation and
  calibration of three models for daily cycle of air temperature.
  *Agricultural and Forest Meteorology*, 34(2), 121-128.
- **Sentelhas, P. C., Dalla Marta, A., Orlandini, S., Santos, E. A.,
  Gillespie, T. J., & Gleason, M. L. (2008).** Suitability of relative
  humidity as an estimator of leaf wetness duration. *Agricultural and
  Forest Meteorology*, 148(3), 392-400.
