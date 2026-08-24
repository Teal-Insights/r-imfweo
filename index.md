# imfweo

`imfweo` is an R package to access and analyze the International
Monetary Fund’s [World Economic
Outlook](https://www.imf.org/en/publications/weo) (WEO) publications.
WEO provides comprehensive analysis and forecasts of the global economy
and is published twice a year - typically in April and October.

The package is designed to work seamlessly with World Bank’s
International Debt Statistics (IDS) and World Development Indicators
(WDI) provided through the
[wbids](https://github.com/teal-insights/r-wbids) and
[wbwdi](https://github.com/tidy-intelligence/r-wbwdi) package,
respectively. It follows the principles of the
[EconDataverse](https://www.econdataverse.org/).

This package is a product of Teal Insights and not sponsored by or
affiliated with the IMF in any way, except for the use of the WEO data.

> 💡 This package currently does not use the IMF Data API for several
> reasons: (i) the API’s SDMX format is complex and difficult to parse;
> (ii) leveraging the `rsdmx` package would require releasing `imfweo`
> under the GPL license; and (iii) it’s unclear whether the API provides
> access to historical WEO publications.

## Installation

You can install `imfweo` from
[CRAN](https://CRAN.R-project.org/package=imfweo) via:

``` r

install.packages("imfweo")
```

You can install the development version of `imfweo` from
[GitHub](https://github.com/teal-insights/r-imfweo) with:

``` r

# install.packages("pak")
pak::pak("teal-insights/r-imfweo")
```

## Usage

The main function
[`weo_get()`](https://teal-insights.github.io/r-imfweo/reference/weo_get.md)
provides a simple interface to download data from the latest World
Economic Outlook (WEO) publication:

``` r

library(imfweo)

weo_get()
#> # A tibble: 361,733 × 7
#>    entity_name entity_id series_name                 units series_id  year value
#>    <chr>       <chr>     <chr>                       <chr> <chr>     <int> <dbl>
#>  1 World       001       Current account balance (c… US d… BCA        1980 -56.3
#>  2 World       001       Current account balance (c… US d… BCA        1981 -82.3
#>  3 World       001       Current account balance (c… US d… BCA        1982 -91.9
#>  4 World       001       Current account balance (c… US d… BCA        1983 -76.7
#>  5 World       001       Current account balance (c… US d… BCA        1984 -68.7
#>  6 World       001       Current account balance (c… US d… BCA        1985 -64.3
#>  7 World       001       Current account balance (c… US d… BCA        1986 -67.4
#>  8 World       001       Current account balance (c… US d… BCA        1987 -64.8
#>  9 World       001       Current account balance (c… US d… BCA        1988 -58.7
#> 10 World       001       Current account balance (c… US d… BCA        1989 -84.7
#> # ℹ 361,723 more rows
```

Note: On the first run of each R session, the function may take a few
seconds to execute as the full publication is downloaded. The data is
put into a cache, which is reset whenever your session restarts.

The set of known publications is maintained as a lookup table inside the
package. Since the WEO database moved to the IMF Data portal with the
October 2025 release, each vintage sits behind an opaque per-vintage
identifier that cannot be derived from the year and release, so the
latest publication can no longer be detected online. A new release
becomes available after a package update.

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
#> # A tibble: 18 × 7
#>    entity_name    entity_id series_name            units series_id  year   value
#>    <chr>          <chr>     <chr>                  <chr> <chr>     <int>   <dbl>
#>  1 Germany        DEU       Gross domestic produc… Perc… NGDP_RPCH  2015   1.49 
#>  2 Germany        DEU       Gross domestic produc… Perc… NGDP_RPCH  2016   2.23 
#>  3 Germany        DEU       Gross domestic produc… Perc… NGDP_RPCH  2017   2.68 
#>  4 Germany        DEU       Gross domestic produc… Perc… NGDP_RPCH  2018   0.984
#>  5 Germany        DEU       Gross domestic produc… Perc… NGDP_RPCH  2019   1.05 
#>  6 Germany        DEU       Gross domestic produc… Perc… NGDP_RPCH  2020  -3.69 
#>  7 United Kingdom GBR       Gross domestic produc… Perc… NGDP_RPCH  2015   2.39 
#>  8 United Kingdom GBR       Gross domestic produc… Perc… NGDP_RPCH  2016   2.16 
#>  9 United Kingdom GBR       Gross domestic produc… Perc… NGDP_RPCH  2017   2.44 
#> 10 United Kingdom GBR       Gross domestic produc… Perc… NGDP_RPCH  2018   1.70 
#> 11 United Kingdom GBR       Gross domestic produc… Perc… NGDP_RPCH  2019   1.60 
#> 12 United Kingdom GBR       Gross domestic produc… Perc… NGDP_RPCH  2020 -11.0  
#> 13 United States  USA       Gross domestic produc… Perc… NGDP_RPCH  2015   2.71 
#> 14 United States  USA       Gross domestic produc… Perc… NGDP_RPCH  2016   1.67 
#> 15 United States  USA       Gross domestic produc… Perc… NGDP_RPCH  2017   2.24 
#> 16 United States  USA       Gross domestic produc… Perc… NGDP_RPCH  2018   2.94 
#> 17 United States  USA       Gross domestic produc… Perc… NGDP_RPCH  2019   2.30 
#> 18 United States  USA       Gross domestic produc… Perc… NGDP_RPCH  2020  -2.77
```

Even when filtering, the full dataset for the selected publication must
be downloaded, as the WEO data is distributed in Excel format.

To explore available publications:

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

To list the available entities (countries or country groups) for the
latest publication:

``` r

weo_get_entities()
#> # A tibble: 210 × 2
#>    entity_id entity_name                     
#>    <chr>     <chr>                           
#>  1 510       ASEAN-5                         
#>  2 110       Advanced Economies              
#>  3 AFG       Afghanistan, Islamic Republic of
#>  4 ALB       Albania                         
#>  5 DZA       Algeria                         
#>  6 AND       Andorra, Principality of        
#>  7 AGO       Angola                          
#>  8 ATG       Antigua and Barbuda             
#>  9 ARG       Argentina                       
#> 10 ARM       Armenia, Republic of            
#> # ℹ 200 more rows
```

To list the available data series:

``` r

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
```

## Contributing

Contributions to `imfweo` are welcome! If you’d like to contribute,
please follow these steps:

1.  **Create an issue**: Before making changes, create an issue
    describing the bug or feature you’re addressing.
2.  **Fork the repository**: After receiving supportive feedback from
    the package authors, fork the repository to your GitHub account.
3.  **Create a branch**: Create a branch for your changes with a
    descriptive name.
4.  **Make your changes**: Implement your bug fix or feature.
5.  **Test your changes**: Run tests to ensure your changes don’t break
    existing functionality.
6.  **Submit a pull request**: Push your changes to your fork and submit
    a pull request to the main repository.
