# List Available IMF WEO Publications

Returns a data frame of the WEO publications this package knows how to
download. The IMF releases the WEO database twice per year:

- Spring (April)

- Fall (October)

The list is maintained as a lookup table inside the package rather than
detected online, because releases published on the IMF Data portal
(October 2025 onwards) sit behind opaque per-vintage identifiers. A new
release therefore only becomes available after a package update.

## Usage

``` r
weo_list_publications(start_year = 2007, end_year = NULL)
```

## Arguments

- start_year:

  Minimum year to include. Defaults to 2007.

- end_year:

  Maximum year to include. Defaults to the year of the most recent known
  publication.

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
weo_list_publications()
#> # A tibble: 39 × 3
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
#> # ℹ 29 more rows
```
