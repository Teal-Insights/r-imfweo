#' Get Latest WEO Release
#'
#' Determines the latest available WEO release based on the current date.
#'
#' @return A list with year and release
#' @noRd
get_latest_release <- function() {
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  current_month <- as.integer(format(Sys.Date(), "%m"))

  if (current_month >= 10) {
    list(year = current_year, release = "Fall")
  } else if (current_month >= 4) {
    list(year = current_year, release = "Spring")
  } else {
    list(year = current_year - 1, release = "Fall")
  }
}

#' Create Package Environment
#' @noRd
pkg_env <- new.env(parent = emptyenv())
