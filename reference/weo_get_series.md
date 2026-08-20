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
#> # A tibble: 145 × 3
#>    series_id series_name                                                   units
#>    <chr>     <chr>                                                         <chr>
#>  1 BCA       Current account balance (credit less debit), US dollar        US d…
#>  2 BCA_NGDPD Current account balance (credit less debit), Percent of GDP   Perc…
#>  3 BF        Financial account balance (assets less liabilities), US doll… US d…
#>  4 BFD       Direct investment, Net (assets minus liabilities), US dollar  US d…
#>  5 BFF       Financial derivatives and employee stock options, Net (asset… US d…
#>  6 BFO       Other investment, Net (assets minus liabilities), US dollar   US d…
#>  7 BFP       Portfolio investment, Net (assets minus liabilities), US dol… US d…
#>  8 BFRA      Change in reserve assets, Net (assets minus liabilities), US… US d…
#>  9 BM        Imports of goods and services, US dollar                      US d…
#> 10 BX        Exports of goods and services, US dollar                      US d…
#> # ℹ 135 more rows
# }
```
