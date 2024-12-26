#' List Available WEO Countries
#'
#' @description
#' Returns a tibble of available countries and regions in the WEO database.
#'
#' @param pattern Optional character string to filter countries by name or ISO code
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{country_code}{ISO 3-letter country code}
#'   \item{country_name}{Full name of the country}
#' }
#' @export
#'
#' @examples
#' # List all countries
#' weo_list_countries()
#'
#' # Search for specific countries
#' weo_list_countries("united")
#'
weo_list_countries <- function(pattern = NULL) {
  # Get or create cached data
  country_info <- get_country_info()

  # Filter if pattern provided
  if (!is.null(pattern)) {
    pattern <- tolower(pattern)
    country_info <- country_info |>
      dplyr::filter(
        grepl(pattern, tolower(.data$country_code)) |
          grepl(pattern, tolower(.data$country_name))
      )
  }

  country_info
}

#' Get or Create Country Information
#' @noRd
get_country_info <- function() {
  # If we have cached data in environment, use it
  if (exists("weo_country_cache", envir = pkg_env)) {
    return(get("weo_country_cache", envir = pkg_env))
  }

  # Otherwise, get latest release and extract country info
  latest <- get_latest_release()

  # Download data
  data <- weo_bulk(latest$year, latest$release, quiet = TRUE)

  # Extract unique country info
  country_info <- data |>
    dplyr::distinct(
      country_code = .data$iso,
      country_name = .data$country
    ) |>
    # Filter out aggregates (which usually don't have ISO codes)
    dplyr::filter(!is.na(.data$country_code)) |>
    dplyr::arrange(.data$country_name)

  # Cache the result
  assign("weo_country_cache", country_info, envir = pkg_env)

  country_info
}
