#' Get Available WEO Entities
#'
#' @description
#' Returns a data frame with available entities (countries and country groups)
#' in the WEO database.
#'
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
#'   \item{entity_name}{Full name of the country or country group}
#' }
#'
#' @export
#'
#' @examplesIf curl::has_internet()
#' \donttest{
#' # List all countries and regions
#' weo_get_entities()
#' }
weo_get_entities <- function(year = NULL, release = NULL, quiet = TRUE) {
  publication <- resolve_publication(year, release)

  data <- weo_bulk(publication$year, publication$release, quiet = quiet)

  entities <- data |>
    dplyr::distinct(
      entity_id = .data$id,
      entity_name = .data$name
    ) |>
    dplyr::filter(!is.na(.data$entity_id)) |>
    dplyr::arrange(.data$entity_name)

  entities
}
