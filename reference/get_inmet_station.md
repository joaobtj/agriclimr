# Download and Process INMET Weather Station Data

Downloads historical weather data from the Brazilian National Institute
of Meteorology (INMET), extracts data for a specific station, and
applies data cleaning and formatting.

## Usage

``` r
get_inmet_station(cache_dir = NULL, station_code, years, full_columns = FALSE)
```

## Arguments

- cache_dir:

  A character string specifying the directory to save or look for
  downloaded files. If `NULL`, a temporary directory is used.

- station_code:

  A character string with the INMET station code (e.g., "A001").

- years:

  A numeric vector of years to download (e.g., 2001:2005).

- full_columns:

  A logical value. If `FALSE` (default), returns a selected subset of
  representative hourly variables. If `TRUE`, returns all processed
  meteorological columns including minima and maxima.

## Value

A `tibble` containing the processed hourly weather data.

## Examples

``` r
if (FALSE) { # \dontrun{
df_summary <- get_inmet_station(station_code = "A001", years = 2001)
head(df_summary)
} # }
```
