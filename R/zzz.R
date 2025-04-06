#' @importFrom utils packageVersion
.onLoad <- function(libname, pkgname) {
  pkg_env <<- new.env(parent = emptyenv())
  invisible()
}
