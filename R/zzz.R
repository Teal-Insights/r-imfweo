.weo_cache <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .weo_cache$latest_publication <- NULL
  .weo_cache$bulk <- NULL
  .weo_cache$year <- NULL
  .weo_cache$release <- NULL
  invisible(TRUE)
}

#' Reset the Cache
#' @export
weo_cache_reset <- function() {
  .weo_cache$latest_publication <- NULL
  .weo_cache$year <- NULL
  .weo_cache$release <- NULL
  .weo_cache$bulk <- NULL
  invisible(TRUE)
}
