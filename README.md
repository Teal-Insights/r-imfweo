
<!-- README.md is generated from README.Rmd. Please edit that file -->

# imfweo

<!-- badges: start -->
<!-- [![CRAN
status](https://www.r-pkg.org/badges/version/imfweo)](https://cran.r-project.org/package=imfweo)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/imfweo)](https://cran.r-project.org/package=imfweo) -->

![R CMD
Check](https://github.com/teal-insights/r-imfweo/actions/workflows/R-CMD-check.yaml/badge.svg)
![Lint](https://github.com/teal-insights/r-imfweo/actions/workflows/lint.yaml/badge.svg)
[![Codecov test
coverage](https://codecov.io/gh/teal-insights/r-imfweo/graph/badge.svg)](https://app.codecov.io/gh/teal-insights/r-imfweo)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

`imfweo` is an R package to access and analyze the International
Monetary Fund’s World Economic Outlook (WEO) publications. WEO provides
comprehensive analysis and forecasts of the global economy and is
published twice a year - typically in April and October.

The package is designed to work seamlessly with World Bank’s
International Debt Statistics (IDS) and World Development Indicators
(WDI) provided through the
[wbids](https://github.com/teal-insights/r-wbids) and
[wbwdi](https://github.com/tidy-intelligence/r-wbwdi) package,
respectively. It follows the principles of the
[econdataverse](https://www.econdataverse.org/).

This package is a product of Teal Insights and not sponsored by or
affiliated with the IMF in any way, except for the use of the WEO data.

## Installation

You can install the development version of `imfweo` from
[GitHub](https://github.com/teal-insights/r-imfweo) with:

``` r
# install.packages("pak")
pak::pak("teal-insights/r-imfweo")
```

## Usage

The main function `weo_get()` provides a simple interface to download
data from the latest World Economic Outlook (WEO) publication:

``` r
library(imfweo)

weo_get()
#> # A tibble: 353,544 × 7
#>    entity_name entity_id series_name             units     series_id  year value
#>    <chr>       <chr>     <chr>                   <chr>     <chr>     <int> <dbl>
#>  1 World       001       Current account balance U.S. dol… BCA        1980 -56.3
#>  2 World       001       Current account balance U.S. dol… BCA        1981 -82.2
#>  3 World       001       Current account balance U.S. dol… BCA        1982 -91.8
#>  4 World       001       Current account balance U.S. dol… BCA        1983 -76.0
#>  5 World       001       Current account balance U.S. dol… BCA        1984 -67.9
#>  6 World       001       Current account balance U.S. dol… BCA        1985 -63.5
#>  7 World       001       Current account balance U.S. dol… BCA        1986 -66.4
#>  8 World       001       Current account balance U.S. dol… BCA        1987 -63.5
#>  9 World       001       Current account balance U.S. dol… BCA        1988 -57.3
#> 10 World       001       Current account balance U.S. dol… BCA        1989 -83.4
#> # ℹ 353,534 more rows
```

Note: On the first run of each R session, the function may take a few
seconds to execute as the package checks which WEO publication is
currently the latest. This information is put into a cache, which is
reset whenever your session restarts.

To explicitly retrieve the most recent publication metadata, use:

``` r
weo_get_latest_publication()
#> $year
#> [1] 2025
#> 
#> $release
#> [1] "Spring"
```

To fetch data from a specific publication, or to filter by country,
indicator, or time range, you can use the available parameters:

``` r
weo_get(
  entities = c("USA", "GBR", "DEU"),
  series = "NGDP_RPCH",
  start_year = 2015,
  end_year = 2020,
  year = 2023,
  release = "Spring"
)
#> # A tibble: 792 × 7
#>    entity_name    entity_id series_name             units series_id  year  value
#>    <chr>          <chr>     <chr>                   <chr> <chr>     <int>  <dbl>
#>  1 Germany        DEU       Current account balance U.S.… BCA        2015  288. 
#>  2 Germany        DEU       Current account balance U.S.… BCA        2016  299. 
#>  3 Germany        DEU       Current account balance U.S.… BCA        2017  289. 
#>  4 Germany        DEU       Current account balance U.S.… BCA        2018  316. 
#>  5 Germany        DEU       Current account balance U.S.… BCA        2019  318. 
#>  6 Germany        DEU       Current account balance U.S.… BCA        2020  274. 
#>  7 United Kingdom GBR       Current account balance U.S.… BCA        2015 -149. 
#>  8 United Kingdom GBR       Current account balance U.S.… BCA        2016 -149. 
#>  9 United Kingdom GBR       Current account balance U.S.… BCA        2017  -96.9
#> 10 United Kingdom GBR       Current account balance U.S.… BCA        2018 -117. 
#> # ℹ 782 more rows
```

Even when filtering, the full dataset for the selected publication must
be downloaded, as the WEO data is distributed in Excel format.

To explore available publications:

``` r
weo_list_publications()
#> # A tibble: 37 × 3
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
#> # ℹ 27 more rows
```

To list the available entities (countries or country groups) for the
latest publication:

``` r
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
```

To list the available data series:

``` r
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
```

## Contributing

Contributions to `imfweo` are welcome! If you’d like to contribute,
please follow these steps:

1.  **Create an issue**: Before making changes, create an issue
    describing the bug or feature you’re addressing.
2.  **Fork the repository**: Fork the repository to your GitHub account.
3.  **Create a branch**: Create a branch for your changes with a
    descriptive name.
4.  **Make your changes**: Implement your bug fix or feature.
5.  **Test your changes**: Run tests to ensure your changes don’t break
    existing functionality.
6.  **Submit a pull request**: Push your changes to your fork and submit
    a pull request to the main repository.
