#' Get WEO Data
#'
#' @description
#' Retrieve data from the IMF World Economic Outlook (WEO) database for specific
#' series, countries, and years.
#'
#' @param series Character vector of series codes (from weo_list_series())
#' @param countries Character vector of ISO country codes (from weo_list_countries())
#' @param start_year Numeric: start year (default: 1980)
#' @param end_year Numeric: end year (default: current year + 5)
#' @param release Optional list with components 'year' and 'release' specifying
#'   WEO release to use. If NULL, uses latest available.
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{country_code}{ISO 3-letter country code}
#'   \item{country_name}{Country name}
#'   \item{series_code}{WEO series code}
#'   \item{series_name}{Series name}
#'   \item{units}{Units of measurement}
#'   \item{year}{Year}
#'   \item{value}{Value}
#' }
#' @export
#'
#' @examples
#' # Get GDP growth for selected countries
#' weo_get(
#'   series = "NGDP_RPCH",
#'   countries = c("USA", "GBR", "DEU"),
#'   start_year = 2015
#' )
weo_get <- function(series,
                    countries,
                    start_year = 1980,
                    end_year = NULL,
                    release = NULL) {

  # Input validation
  validate_inputs(series, countries, start_year, end_year)

  # Set default end_year if not provided
  if (is.null(end_year)) {
    end_year <- as.integer(format(Sys.Date(), "%Y")) + 5
  }

  # Get release info
  if (is.null(release)) {
    release <- get_latest_release()
  }

  # Get full dataset
  data <- weo_bulk(release$year, release$release, quiet = TRUE)

  # Add debugging output
  cli::cli_alert_info(
    "Available series: {toString(unique(data$series))}"
  )
  cli::cli_alert_info(
    "Requested series: {toString(series)}"
  )

  # Filter and clean data
  filtered_data <- data |>
    dplyr::filter(
      .data$series %in% !!series,  # Force evaluation of series
      .data$iso %in% !!countries,  # Force evaluation of countries
      .data$year >= !!start_year,
      .data$year <= !!end_year
    ) |>
    # Rename columns for consistency
    dplyr::rename(
      country_code = "iso",
      country_name = "country",
      series_code = "series",
      series_name = "subject"
    ) |>
    # Arrange data logically
    dplyr::arrange(
      .data$series_code,
      .data$country_code,
      .data$year
    )

  # Add debugging output
  cli::cli_alert_info(
    "Filtered series: {toString(unique(filtered_data$series_code))}"
  )

  filtered_data
}

#' Validate inputs for weo_get
#' @noRd
validate_inputs <- function(series, countries, start_year, end_year) {
  # Check series codes
  valid_series <- get_series_info()$series_code
  invalid_series <- setdiff(series, valid_series)
  if (length(invalid_series) > 0) {
    cli::cli_abort(c(
      "Invalid series code(s):",
      invalid_series,
      "i" = "Use {.code weo_list_series()} to see available series codes."
    ))
  }

  # Check country codes
  valid_countries <- get_country_info()$country_code
  invalid_countries <- setdiff(countries, valid_countries)
  if (length(invalid_countries) > 0) {
    cli::cli_abort(c(
      "Invalid country code(s):",
      invalid_countries,
      "i" = "Use {.code weo_list_countries()} to see available country codes."
    ))
  }

  # Check years
  if (!is.numeric(start_year)) {
    cli::cli_abort("start_year must be numeric")
  }

  if (!is.null(end_year)) {
    if (!is.numeric(end_year)) {
      cli::cli_abort("end_year must be numeric")
    }
    if (start_year > end_year) {
      cli::cli_abort("start_year must be less than or equal to end_year")
    }
  }
}
