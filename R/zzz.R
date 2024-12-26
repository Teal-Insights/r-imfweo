#' @importFrom utils packageVersion
.onLoad <- function(libname, pkgname) {
  # Create package environment
  pkg_env <<- new.env(parent = emptyenv())
  invisible()
}
