.weo_cache <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .weo_cache$year <- NULL
  .weo_cache$release <- NULL
  .weo_cache$bulk <- NULL
  invisible(TRUE)
}

#' Reset the Cache
#'
#' @return No return value, called for side effects.
#'
#' @export
weo_cache_reset <- function() {
  .weo_cache$year <- NULL
  .weo_cache$release <- NULL
  .weo_cache$bulk <- NULL
  invisible(TRUE)
}
