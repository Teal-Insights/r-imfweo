# Get WEO Data

Retrieve data from the IMF World Economic Outlook (WEO) database for
specific series, countries, and years.

## Usage

``` r
weo_get(
  entities = NULL,
  series = NULL,
  start_year = 1980L,
  end_year = NULL,
  year = NULL,
  release = NULL,
  quiet = TRUE
)
```

## Arguments

- entities:

  An optional character vector of ISO3 country codes or country group
  identifiers. See
  [weo_get_entities](https://teal-insights.github.io/r-imfweo/reference/weo_get_entities.md).

- series:

  A optional character vector of series codes. See
  [weo_get_series](https://teal-insights.github.io/r-imfweo/reference/weo_get_series.md).

- start_year:

  Minimum year to include. Defaults to 1980.

- end_year:

  Maximum year to include. Defaults to current year + 5 years.

- year:

  The year of a WEO publication (e.g., 2024). Defaults to latest
  publication year.

- release:

  The release of a WEO publication ("Spring" or "Fall"). Defaults to
  latest publication release.

- quiet:

  A logical indicating whether to print download information. Defaults
  to TRUE.

## Value

A data frame with columns:

- entity_id:

  ISO3 country code or country group ID

- entity_name:

  Entity name

- series_code:

  WEO series code

- series_name:

  Series name

- units:

  Units of measurement

- year:

  Year

- value:

  Value

## Examples

``` r
# \donttest{
# Get GDP growth for selected countries
weo_get(
  entities = c("USA", "GBR", "DEU"),
  series = "NGDP_RPCH",
  start_year = 2015,
  end_year = 2020
)
#> # A tibble: 792 × 7
#>    entity_name    entity_id series_name             units series_id  year  value
#>    <chr>          <chr>     <chr>                   <chr> <chr>     <int>  <dbl>
#>  1 Germany        DEU       Current account balance U.S.… BCA        2015  278. 
#>  2 Germany        DEU       Current account balance U.S.… BCA        2016  315. 
#>  3 Germany        DEU       Current account balance U.S.… BCA        2017  303. 
#>  4 Germany        DEU       Current account balance U.S.… BCA        2018  342. 
#>  5 Germany        DEU       Current account balance U.S.… BCA        2019  312. 
#>  6 Germany        DEU       Current account balance U.S.… BCA        2020  249. 
#>  7 United Kingdom GBR       Current account balance U.S.… BCA        2015 -145. 
#>  8 United Kingdom GBR       Current account balance U.S.… BCA        2016 -147. 
#>  9 United Kingdom GBR       Current account balance U.S.… BCA        2017  -93.7
#> 10 United Kingdom GBR       Current account balance U.S.… BCA        2018 -113. 
#> # ℹ 782 more rows
# }
```
