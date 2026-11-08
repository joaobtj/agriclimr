# Extract Point Data from BR-DWGD NetCDF Files

Extracts a daily time series of specified weather variables for a given
coordinate (longitude and latitude) from the Brazilian Daily Weather
Gridded Data (BR-DWGD) NetCDF datasets, identifying the closest grid
cell to the target location.

## Usage

``` r
get_brdwgd(
  target_longitude,
  target_latitude,
  weather_variables = c("pr", "Tmin", "Tmax", "Rs", "RH", "u2", "ETo"),
  date_range = NULL,
  nc_files_directory = "."
)
```

## Arguments

- target_longitude:

  Numeric. Longitude of the target location in decimal degrees.

- target_latitude:

  Numeric. Latitude of the target location in decimal degrees.

- weather_variables:

  Character vector. Variables to extract. Allowed values are:

  - `"pr"`: Precipitation (mm).

  - `"Tmin"`: Minimum air temperature (°C).

  - `"Tmax"`: Maximum air temperature (°C).

  - `"Rs"`: Incident solar radiation (MJ m\\^{-2}\\ day\\^{-1}\\).

  - `"RH"`: Relative humidity (percent).

  - `"u2"`: Wind speed at 2 m height (m s\\^{-1}\\).

  - `"ETo"`: Reference evapotranspiration (mm day\\^{-1}\\).

  Defaults to all.

- date_range:

  Character vector of length 2 (`c("YYYY-MM-DD", "YYYY-MM-DD")`) or
  `NULL`. Start and end dates. If `NULL` (default), extracts the entire
  period available in the NetCDF files.

- nc_files_directory:

  Character. Path to the local directory containing the BR-DWGD NetCDF
  files. Defaults to current directory (`"."`).

## Value

A `tibble` containing the columns `date`, `lat`, `lon`, and each
requested weather variable.

## References

Xavier, A. C., Scanlon, B. R., King, C. W., & Alves, A. I. (2022). New
improved Brazilian daily weather gridded data (1961–2020). International
Journal of Climatology, 42(16), 8390–8404.
<https://doi.org/10.1002/joc.7731>

## Examples

``` r
if (FALSE) { # \dontrun{
# Ensure NetCDF files are present in 'nc_files_directory'
df_point <- get_brdwgd_weather(
  target_longitude = -50.5995,
  target_latitude = -27.2863,
  weather_variables = c("pr", "Tmax", "Tmin"),
  date_range = c("1983-01-01", "1983-03-31"),
  nc_files_directory = "D:/clima_Xavier"
)
print(df_point)
} # }
```
