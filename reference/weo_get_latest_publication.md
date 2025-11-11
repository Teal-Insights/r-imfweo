# Get Latest WEO Publication from IMF Website

Determines the latest available WEO publication based on the current
date.

## Usage

``` r
weo_get_latest_publication(quiet = TRUE)
```

## Arguments

- quiet:

  A logical indicating whether to print download information. Defaults
  to TRUE.

## Value

A list with year and release

## Examples

``` r
# \donttest{
# List all series
weo_get_latest_publication(quiet = FALSE)
#> $year
#> [1] 2025
#> 
#> $release
#> [1] "Spring"
#> 
# }
```
