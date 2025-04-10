#' List Available IMF WEO Publications
#'
#' @description
#' Returns a data frame of available WEO publications from 2007 onwards.
#' The IMF typically releases the WEO database twice per year:
#' - Spring (April)
#' - Fall (October)
#'
#' @param start_year Minimum year to include (default: 2007)
#' @param end_year Maximum year to include (default: current year)
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{year}{The year of the release}
#'   \item{release}{The release name ("Spring" or "Fall")}
#'   \item{month}{The month of release ("April" or "October")}
#' }
#' @export
weo_list_publications <- function(
  start_year = 2007,
  end_year = as.integer(format(Sys.Date(), "%Y")),
  check_latest = FALSE
) {
  validate_years(start_year, end_year)

  years <- seq(start_year, end_year)

  publications <- tidyr::expand_grid(
    year = years,
    release = c("Spring", "Fall")
  ) |>
    dplyr::mutate(
      month = dplyr::if_else(.data$release == "Spring", "April", "October")
    ) |>
    dplyr::arrange(.data$year, .data$month)

  if (check_latest) {
    latest <- weo_get_latest_publication()
    current_year <- as.integer(latest$year)
    current_month <- ifelse(latest$release == "April", 4L, 10L)
  } else {
    current_year <- get_current_year()
    current_month <- get_current_month()
  }

  publications <- publications |>
    dplyr::filter(
      .data$year < current_year |
        (.data$year == current_year &
          ((.data$month == "April" & current_month >= 4) |
            (.data$month == "October" & current_month >= 10)))
    ) |>
    dplyr::arrange(.data$year)

  publications
}

#' @keywords internal
#' @noRd
get_current_year <- function() {
  as.integer(format(Sys.Date(), "%Y"))
}

#' @keywords internal
#' @noRd
get_current_month <- function() {
  as.integer(format(Sys.Date(), "%m"))
}
