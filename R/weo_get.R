#' Get WEO Data
#'
#' @description
#' Retrieve data from the IMF World Economic Outlook (WEO) database for specific
#' series, countries, and years.
#'
#' @param entities An optional character vector of ISO3 country codes or country
#'  group identifiers. See \link{weo_get_entities}.
#' @param series A optional character vector of series codes.
#'  See \link{weo_get_series}.
#' @param start_year Minimum year to include. Defaults to 1980.
#' @param end_year Maximum year to include. Defaults to current year + 5 years.
#' @param year The year of a WEO publication (e.g., 2024). Defaults to latest
#'  publication year.
#' @param release The release of a WEO publication ("Spring" or "Fall").
#'  Defaults to latest publication release.
#' @param quiet A logical indicating whether to print download information.
#'  Defaults to TRUE.
#'
#' @return A data frame with columns:
#' \describe{
#'   \item{entity_id}{ISO3 country code or country group ID}
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
  start_year = 1980L,
  end_year = NULL,
  year = NULL,
  release = NULL,
  quiet = TRUE
) {
  validate_year(start_year)

  if (is.null(end_year)) {
    end_year <- get_current_year() + 5
  }

  publication <- resolve_publication(year, release)

  data <- weo_bulk(publication$year, publication$release, quiet = quiet)

  if (is.null(data)) {
    return(invisible(NULL))
  }

  # NULL checks are kept in plain R, outside filter()'s data mask: inside the
  # mask a bare `series`/`entities` resolves to the data column, so both the
  # `is.null()` guard and the match would silently target the column instead of
  # the function arguments.
  if (!is.null(series)) {
    data <- dplyr::filter(data, .data$series %in% .env$series)
  }
  if (!is.null(entities)) {
    data <- dplyr::filter(data, .data$id %in% .env$entities)
  }

  filtered_data <- data |>
    dplyr::filter(
      .data$year >= .env$start_year,
      .data$year <= .env$end_year
    ) |>
    dplyr::rename(
      entity_id = "id",
      entity_name = "name",
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
