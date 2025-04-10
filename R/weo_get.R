#' Get WEO Data
#'
#' @description
#' Retrieve data from the IMF World Economic Outlook (WEO) database for specific
#' series, countries, and years.
#'
#' @param entities An optional character vector of ISO3 country codes.
#'  See \link{weo_get_entities}.
#' @param series A optional character vector of series codes.
#'  See \link{weo_get_series}.
#' @param start_year Minimum year to include. Defaults to 1980.
#' @param end_year Maximum year to include. Defaults to current year + 5 years.
#' @param year The year of a WEO publication (e.g., 2024). Defaults to latest
#'  publication year.
#' @param release The release of a WEO publication ("Spring" or "Fall").
#'  Defaults to latest publication release.
#' @param quiet description
#'
#' @return A data frame with columns:
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
#' @examplesIf curl::has_internet()
#' \donttest{
#' # Get GDP growth for selected countries
#' weo_get(
#'   entities = c("USA", "GBR", "DEU"),
#'   series = "NGDP_RPCH",
#'   start_year = 2015,
#'   end_year = 2020
#' )
#' }
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
