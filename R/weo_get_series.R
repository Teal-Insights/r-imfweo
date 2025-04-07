#' Get Available WEO Series
#'
#' @description
#' Returns a data frame with available series in the WEO database.
#'
#' @param year The year of a WEO publication (e.g., 2024). Defaults to latest
#'  publication year.
#' @param release The release of a WEO publication ("Spring" or "Fall").
#'  Defaults to latest publication release.
#' @param quiet A logical indicating whether to print download information.
#'  Defaults to TRUE.
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{series_id}{The WEO series ID (e.g., "NGDP_RPCH")}
#'   \item{series_name}{Full name of the series (e.g., "Gross domestic product,
#' constant prices")}
#'   \item{units}{Units of measurement}
#' }
#'
#' @export
#'
#' @examplesIf curl::has_internet()
#' \donttest{
#' # List all series
#' weo_get_series()
#' }
weo_get_series <- function(year = NULL, release = NULL, quiet = TRUE) {
  publication <- resolve_publication(year, release)

  data <- weo_bulk(publication$year, publication$release, quiet = quiet)

  series <- data |>
    dplyr::distinct(
      series_id = .data$series,
      series_name = .data$subject,
      units = .data$units
    ) |>
    dplyr::arrange(.data$series_id)

  series
}
