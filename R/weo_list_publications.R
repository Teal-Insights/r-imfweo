#' List Available IMF WEO Publications
#'
#' @description
#' Returns a data frame of the WEO publications this package knows how to
#' download. The IMF releases the WEO database twice per year:
#' - Spring (April)
#' - Fall (October)
#'
#' The list is maintained as a lookup table inside the package rather than
#' detected online, because releases published on the IMF Data portal
#' (October 2025 onwards) sit behind opaque per-vintage identifiers. A new
#' release therefore only becomes available after a package update.
#'
#' @param start_year Minimum year to include. Defaults to 2007.
#' @param end_year Maximum year to include. Defaults to the year of the most
#'  recent known publication.
#'
#' @return A data frame with columns:
#' \describe{
#'   \item{year}{The year of the release}
#'   \item{release}{The release name ("Spring" or "Fall")}
#'   \item{month}{The month of release ("April" or "October")}
#' }
#'
#' @examples
#' weo_list_publications()
#'
#' @export
weo_list_publications <- function(
  start_year = 2007,
  end_year = NULL
) {
  releases <- weo_releases()

  if (is.null(end_year)) {
    end_year <- max(releases$year)
  }

  validate_years(start_year, end_year)

  releases |>
    dplyr::filter(
      .data$year >= start_year,
      .data$year <= end_year
    ) |>
    dplyr::select("year", "release", "month")
}

#' @keywords internal
#' @noRd
get_current_year <- function() {
  as.integer(format(Sys.Date(), "%Y"))
}
