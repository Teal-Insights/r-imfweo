# Get Available WEO Series

Returns a data frame with available series in the WEO database.

## Usage

``` r
weo_get_series(year = NULL, release = NULL, quiet = TRUE)
```

## Arguments

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

- series_id:

  The WEO series ID (e.g., "NGDP_RPCH")

- series_name:

  Full name of the series (e.g., "Gross domestic product, constant
  prices")

- units:

  Units of measurement

## Examples

``` r
# \donttest{
# List all series
weo_get_series()
#> # A tibble: 150 × 3
#>    series_id series_name                   units         
#>    <chr>     <chr>                         <chr>         
#>  1 BCA       Current account balance       U.S. dollars  
#>  2 BCA_NGDPD Current account balance       Percent of GDP
#>  3 BF        Financial account balance     U.S. dollars  
#>  4 BFD       Direct investment, net        U.S. dollars  
#>  5 BFF       Financial derivatives, net    U.S. dollars  
#>  6 BFO       Other investment, net         U.S. dollars  
#>  7 BFP       Portfolio investment, net     U.S. dollars  
#>  8 BFRA      Change in reserves            U.S. dollars  
#>  9 BM        Imports of goods and services U.S. dollars  
#> 10 BX        Exports of goods and services U.S. dollars  
#> # ℹ 140 more rows
# }
```
