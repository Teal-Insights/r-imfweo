# Get Available WEO Entities

Returns a data frame with available entities (countries and country
groups) in the WEO database.

## Usage

``` r
weo_get_entities(year = NULL, release = NULL, quiet = TRUE)
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

- entity_id:

  ISO3 country code or country group ID

- entity_name:

  Full name of the country or country group

## Examples

``` r
# \donttest{
# List all countries and regions
weo_get_entities()
#> # A tibble: 209 × 2
#>    entity_id entity_name        
#>    <chr>     <chr>              
#>  1 510       ASEAN-5            
#>  2 110       Advanced economies 
#>  3 AFG       Afghanistan        
#>  4 ALB       Albania            
#>  5 DZA       Algeria            
#>  6 AND       Andorra            
#>  7 AGO       Angola             
#>  8 ATG       Antigua and Barbuda
#>  9 ARG       Argentina          
#> 10 ARM       Armenia            
#> # ℹ 199 more rows
# }
```
