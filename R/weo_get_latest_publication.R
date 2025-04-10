#' Get Latest WEO Publication from IMF Website
#'
#' Determines the latest available WEO publication based on the current date.
#'
#' @param quiet A logical indicating whether to print download information.
#'  Defaults to TRUE.
#'
#' @return A list with year and release
#'
#' @export
#'
#' @examplesIf curl::has_internet()
#' \donttest{
#' # List all series
#' weo_get_latest_publication(quiet = FALSE)
#' }
weo_get_latest_publication <- function(quiet = TRUE) {
  if (!is.null(.weo_cache$latest_publication)) {
    return(.weo_cache$latest_publication)
  } else {
    if (!quiet) {
      cli::cli_alert_info("Fetching and cacheing latest publication...")
    }

    base_url <- "https://www.imf.org/en/Publications/WEO/weo-database"

    current_year <- get_current_year()
    previous_year <- current_year - 1

    publications <- list(
      list(year = current_year, release = "October", label = "Fall"),
      list(year = current_year, release = "April", label = "Spring"),
      list(year = previous_year, release = "October", label = "Fall")
    )

    for (rel in publications) {
      url <- paste0(base_url, "/", rel$year, "/", rel$release)
      req <- request(url) |>
        req_options(followlocation = TRUE) |>
        req_user_agent(
          "imfweo R package (https://github.com/teal-insights/r-imfweo)"
        )

      resp <- tryCatch(
        req |>
          req_perform(),
        error = function(e) NULL
      )

      if (!is.null(resp)) {
        final_url <- resp$url
        if (!grepl("external/error", final_url)) {
          .weo_cache$latest_publication <- list(
            year = rel$year,
            release = rel$label
          )
          return(.weo_cache$latest_publication)
        }
      }
    }

    cli::cli_abort("No valid WEO publication found.")
  }
}
