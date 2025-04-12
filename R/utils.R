#' @keywords internal
#' @noRd
validate_publication <- function(publication) {
  if (is.null(publication$year) || is.null(publication$release)) {
    cli::cli_abort(
      c(
        "!" = "{.arg publication} must have non-null 'year' and 'release'."
      )
    )
  }
}

#' @keywords internal
#' @noRd
validate_year <- function(year) {
  if (!is.numeric(year)) {
    cli::cli_abort(
      c(
        "!" = "{.arg year} must be numeric"
      )
    )
  }
}


#' @keywords internal
#' @noRd
validate_years <- function(start_year, end_year) {
  if (!is.numeric(start_year) || !is.numeric(end_year)) {
    cli::cli_abort(
      c(
        "!" = "{.arg start_year} and {.arg end_year} must be numeric"
      )
    )
  }
  if (start_year > end_year) {
    cli::cli_abort(
      c(
        "!" = "{.arg start_year} must be smaller than {.arg end_year}"
      )
    )
  }
}

#' @keywords internal
#' @noRd
resolve_publication <- function(year = NULL, release = NULL) {
  if (is.null(year) && is.null(release)) {
    publication <- weo_get_latest_publication()
  } else {
    publication <- list(year = year, release = release)
  }

  validate_publication(publication)
  publication
}
