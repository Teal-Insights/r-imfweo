# List Available IMF WEO Publications

Returns a data frame of available WEO publications from 2007 onwards.
The IMF typically releases the WEO database twice per year:

- Spring (April)

- Fall (October)

## Usage

``` r
weo_list_publications(
  start_year = 2007,
  end_year = as.integer(format(Sys.Date(), "%Y")),
  check_latest = FALSE
)
```

## Arguments

- start_year:

  Minimum year to include. Defaults to 2007.

- end_year:

  Maximum year to include. Defaults to current year.

- check_latest:

  Logical indicating whether to check whether the latest publication
  according to current date has been released. Defaults to FALSE.

## Value

A data frame with columns:

- year:

  The year of the release

- release:

  The release name ("Spring" or "Fall")

- month:

  The month of release ("April" or "October")

## Examples

``` r
# \donttest{
weo_list_publications(check_latest = TRUE)
#> # A tibble: 38 × 3
#>     year release month  
#>    <int> <chr>   <chr>  
#>  1  2007 Spring  April  
#>  2  2007 Fall    October
#>  3  2008 Spring  April  
#>  4  2008 Fall    October
#>  5  2009 Spring  April  
#>  6  2009 Fall    October
#>  7  2010 Spring  April  
#>  8  2010 Fall    October
#>  9  2011 Spring  April  
#> 10  2011 Fall    October
#> # ℹ 28 more rows
# }
```
