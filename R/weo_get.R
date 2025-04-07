#' Get WEO Data
#'
#' @description
#' Retrieve data from the IMF World Economic Outlook (WEO) database for specific
#' series, countries, and years.
#'
#' @param series (Optional) character vector of series codes.
#'  See \link{weo_get_series}.
#' @param countries (Optional) character vector of ISO3 country codes.
#'  See \link{weo_get_entities}.
#' @param start_year Numeric: start year (default: 1980)
#' @param end_year Numeric: end year (default: current year + 5)
#' @param release Optional list with components 'year' and 'release' specifying
#'   WEO release to use. If NULL, uses latest available.
#' @param quiet description
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{entity_id}{ISO3 country code}
#'   \item{entity_name}{Entity name}
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
#'   entities = c("USA", "GBR", "DEU"),
#'   series = "NGDP_RPCH",
#'   start_year = 2015,
#'   end_year = 2020
#' )
#'
weo_get <- function(
  entities = NULL,
  series = NULL,
  start_year = 1980,
  end_year = NULL,
  year = NULL,
  release = NULL,
  quiet = TRUE
) {
  validate_year(start_year)

  if (is.null(end_year)) {
    end_year <- as.integer(format(Sys.Date(), "%Y")) + 5
  }

  publication <- resolve_publication(year, release)

  data <- weo_bulk(publication$year, publication$release, quiet = quiet)

  filtered_data <- data |>
    dplyr::filter(
      if (!is.null(series)) .data$series %in% series else TRUE,
      if (!is.null(entities)) .data$iso %in% entities else TRUE,
      .data$year >= start_year,
      .data$year <= end_year
    ) |>
    dplyr::rename(
      entity_id = "iso",
      entity_name = "country",
      series_id = "series",
      series_name = "subject"
    ) |>
    dplyr::arrange(
      .data$series_id,
      .data$entity_id,
      .data$year
    )

  filtered_data
}
