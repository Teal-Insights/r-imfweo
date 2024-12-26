
<!-- README.md is generated from README.Rmd. Please edit that file -->

# imfweo

<!-- badges: start -->

<!-- badges: end -->

`imfweo` provides easy access to the International Monetary Fund’s World
Economic Outlook (WEO) database in R. This is a minimum viable product
under heavy development.

## Features

- Download and process WEO data releases
- List available countries, indicators, and releases
- Extract specific series for analysis
- Consistent interface and tidy data output

## Installation

You can install the development version of imfweo from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("Teal-Insights/imfweo")
```

## Basic Usage

### Getting WEO Data

You can get WEO data either by downloading specific series for selected
countries (`weo_get()`) or by downloading complete WEO releases
(`weo_bulk()`).

Get specific indicators for selected countries:

``` r
library(imfweo)

# Get GDP growth and inflation for G7 countries
weo_get(
  series = c("NGDP_RPCH", "PCPIPCH"),  # Real GDP growth and inflation
  countries = c("USA", "GBR", "DEU", "FRA", "ITA", "JPN", "CAN"),
  start_year = 2015
)
#> ℹ Available series: NGDP_R, NGDP_RPCH, NGDP, NGDPD, PPPGDP, NGDP_D, NGDPRPC, NGDPRPPPPC, NGDPPC, NGDPDPC, PPPPC, PPPSH, PPPEX, NID_NGDP, NGSD_NGDP, PCPI, PCPIPCH, PCPIE, PCPIEPCH, TM_RPCH, TMG_RPCH, TX_RPCH, TXG_RPCH, LP, GGR, GGR_NGDP, GGX, GGX_NGDP, GGXCNL, GGXCNL_NGDP, GGXONLB, GGXONLB_NGDP, GGXWDG, GGXWDG_NGDP, NGDP_FY, BCA, BCA_NGDPD, LUR, GGXWDN, GGXWDN_NGDP, LE, GGSB, GGSB_NPGDP, NGAP_NPGDP
#> ℹ Requested series: NGDP_RPCH, PCPIPCH
#> ℹ Filtered series: NGDP_RPCH, PCPIPCH
#> # A tibble: 210 × 7
#>    country_name country_code series_name           units series_code  year value
#>    <chr>        <chr>        <chr>                 <chr> <chr>       <int> <dbl>
#>  1 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2015  0.65
#>  2 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2016  1.04
#>  3 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2017  3.03
#>  4 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2018  2.74
#>  5 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2019  1.91
#>  6 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2020 -5.04
#>  7 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2021  5.29
#>  8 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2022  3.82
#>  9 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2023  1.25
#> 10 Canada       CAN          Gross domestic produ… Perc… NGDP_RPCH    2024  1.34
#> # ℹ 200 more rows
```

Download a complete WEO release:

``` r
# Download Spring 2024 WEO
weo_bulk(2024, "Spring")
#> ℹ Downloading WEO data...
#> ℹ Processing data...
#> # A tibble: 322,437 × 7
#>    country     iso   subject                            units series  year value
#>    <chr>       <chr> <chr>                              <chr> <chr>  <int> <dbl>
#>  1 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2002  453.
#>  2 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2003  493.
#>  3 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2004  496.
#>  4 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2005  555.
#>  5 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2006  585.
#>  6 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2007  663.
#>  7 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2008  688.
#>  8 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2009  830.
#>  9 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2010  900.
#> 10 Afghanistan AFG   Gross domestic product, constant … Nati… NGDP_R  2011  958.
#> # ℹ 322,427 more rows
```

### Available Data

List available WEO releases:

``` r
weo_list_releases()
#> # A tibble: 36 × 3
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
#> # ℹ 26 more rows
```

List available countries and regions:

``` r
weo_list_countries()
#> # A tibble: 196 × 2
#>    country_code country_name       
#>    <chr>        <chr>              
#>  1 AFG          Afghanistan        
#>  2 ALB          Albania            
#>  3 DZA          Algeria            
#>  4 AND          Andorra            
#>  5 AGO          Angola             
#>  6 ATG          Antigua and Barbuda
#>  7 ARG          Argentina          
#>  8 ARM          Armenia            
#>  9 ABW          Aruba              
#> 10 AUS          Australia          
#> # ℹ 186 more rows
```

``` r
# Search for specific countries
weo_list_countries("united")
#> # A tibble: 3 × 2
#>   country_code country_name        
#>   <chr>        <chr>               
#> 1 ARE          United Arab Emirates
#> 2 GBR          United Kingdom      
#> 3 USA          United States
```

List available economic indicators:

``` r
weo_list_series()
#> # A tibble: 44 × 3
#>    series_code series_name                                      units           
#>    <chr>       <chr>                                            <chr>           
#>  1 BCA         Current account balance                          U.S. dollars    
#>  2 BCA_NGDPD   Current account balance                          Percent of GDP  
#>  3 GGR         General government revenue                       National curren…
#>  4 GGR_NGDP    General government revenue                       Percent of GDP  
#>  5 GGSB        General government structural balance            National curren…
#>  6 GGSB_NPGDP  General government structural balance            Percent of pote…
#>  7 GGX         General government total expenditure             National curren…
#>  8 GGXCNL      General government net lending/borrowing         National curren…
#>  9 GGXCNL_NGDP General government net lending/borrowing         Percent of GDP  
#> 10 GGXONLB     General government primary net lending/borrowing National curren…
#> # ℹ 34 more rows
```

``` r
# Search for GDP-related indicators
weo_list_series("gdp")
#> # A tibble: 22 × 3
#>    series_code  series_name                                      units          
#>    <chr>        <chr>                                            <chr>          
#>  1 BCA_NGDPD    Current account balance                          Percent of GDP 
#>  2 GGR_NGDP     General government revenue                       Percent of GDP 
#>  3 GGSB_NPGDP   General government structural balance            Percent of pot…
#>  4 GGXCNL_NGDP  General government net lending/borrowing         Percent of GDP 
#>  5 GGXONLB_NGDP General government primary net lending/borrowing Percent of GDP 
#>  6 GGXWDG_NGDP  General government gross debt                    Percent of GDP 
#>  7 GGXWDN_NGDP  General government net debt                      Percent of GDP 
#>  8 GGX_NGDP     General government total expenditure             Percent of GDP 
#>  9 NGAP_NPGDP   Output gap in percent of potential GDP           Percent of pot…
#> 10 NGDP         Gross domestic product, current prices           National curre…
#> # ℹ 12 more rows
```

## Development Status

This package is under active development. Current features are working
but may change. Future releases will add:

- Better data validation
- More convenience functions for common analyses
- Improved documentation and vignettes
- Additional data transformation tools

## Part of the econdataverse

`imfweo` is part of the [econdataverse](https://www.econdataverse.org/),
a universe of open-source packages designed to make working with
economic data seamless and efficient. The goal is simple: spend less
time wrestling with data and more time analyzing it.

Think of econdataverse packages as LEGO® pieces - modular tools designed
to work together perfectly. For example, you might combine World Bank
debt data (using [{wbids}](https://teal-insights.github.io/r-wbids/))
with IMF macroeconomic projections from this package.

### Current Features

- Download WEO data programmatically
- Access specific indicators for selected countries
- Get metadata about available series and countries
- Return data in tidy format ready for analysis

### Roadmap

We’re working on:

- Standardizing country names across econdataverse packages
- Creating consistent column names and data structures
- Building tools for common economic analyses
- Making data combination across sources seamless

Other econdataverse packages:

- [{wbids}](https://teal-insights.github.io/r-wbids/): World Bank
  International Debt Statistics ✅
- [{wbwdi}](https://tidy-intelligence.github.io/r-wbwdi/): World Bank
  World Development Indicators 🚀
- More coming soon!

Our mission is to unclog the data bottleneck in economic analysis. By
making data access and cleaning efficient and consistent, we enable
policymakers and researchers to focus on what matters: using data to
make better decisions in a world of limited resources.
