#' List Available IMF WEO Releases
#'
#' @description
#' Returns a tibble of available WEO releases from 2007 onwards.
#' The IMF typically releases the WEO database twice per year:
#' - Spring (April)
#' - Fall (October)
#'
#' @param min_year Minimum year to include (default: 2007)
#' @param max_year Maximum year to include (default: current year)
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{year}{The year of the release}
#'   \item{release}{The release name ("Spring" or "Fall")}
#'   \item{month}{The month of release ("April" or "October")}
#' }
#' @export
weo_list_releases <- function(
  min_year = 2007,
  max_year = as.integer(format(Sys.Date(), "%Y"))
) {
  # Validate inputs
  if (!is.numeric(min_year) || !is.numeric(max_year)) {
    cli::cli_abort("Years must be numeric values")
  }

  years <- seq(min_year, max_year)

  # Create combinations of years and releases
  releases <- tidyr::expand_grid(
    year = years,
    release = c("Spring", "Fall")
  ) |>
    dplyr::mutate(
      month = dplyr::if_else(.data$release == "Spring", "April", "October")
    ) |>
    dplyr::arrange(.data$year, .data$month) # Sort by year ascending and month

  # Remove future releases
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  current_month <- as.integer(format(Sys.Date(), "%m"))

  releases |>
    dplyr::filter(
      .data$year < current_year |
        (.data$year == current_year &
          ((.data$month == "April" & current_month >= 4) |
            (.data$month == "October" & current_month >= 10)))
    )
}
