#' List Available WEO Series (Indicators)
#'
#' @description
#' Returns a tibble of available series (economic indicators) in the WEO database.
#'
#' @param pattern Optional character string to filter series by name or code
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{series_code}{The WEO subject code (e.g., "NGDP_RPCH")}
#'   \item{series_name}{Full name of the series (e.g., "Gross domestic product, constant prices")}
#'   \item{units}{Units of measurement}
#' }
#' @export
#'
#' @examples
#' # List all series
#' weo_list_series()
#'
#' # Search for GDP-related series
#' weo_list_series("gdp")
#'
weo_list_series <- function(pattern = NULL) {
  # Get or create cached data
  series_info <- get_series_info()

  # Filter if pattern provided
  if (!is.null(pattern)) {
    pattern <- tolower(pattern)
    series_info <- series_info |>
      dplyr::filter(
        grepl(pattern, tolower(.data$series_code)) |
          grepl(pattern, tolower(.data$series_name))
      )
  }

  series_info
}

#' Get or Create Series Information
#' @noRd
get_series_info <- function() {
  # If we have cached data in environment, use it
  if (exists("weo_series_cache", envir = pkg_env)) {
    return(get("weo_series_cache", envir = pkg_env))
  }

  # Otherwise, get latest release and extract series info
  latest <- get_latest_release()

  # Download data
  data <- weo_bulk(latest$year, latest$release, quiet = TRUE)

  # Extract unique series info
  series_info <- data |>
    dplyr::distinct(
      series_code = .data$series,
      series_name = .data$subject,
      units = .data$units
    ) |>
    dplyr::arrange(.data$series_code)

  # Cache the result
  assign("weo_series_cache", series_info, envir = pkg_env)

  series_info
}

# Create package environment for caching
pkg_env <- new.env(parent = emptyenv())
