# Lookup table of known WEO releases -------------------------------------
#
# MAINTAINER NOTE
#
# The IMF publishes the WEO database twice a year. Until the April 2025
# vintage, every release lived on www.imf.org under a URL that could be
# derived from the year and the release (see `create_weo_url()`). With the
# October 2025 vintage the database moved to the IMF Data portal
# (https://data.imf.org), where each vintage sits behind an opaque per-vintage
# GUID that cannot be derived from anything. There is therefore no reliable
# way to detect the latest publication programmatically, and this table has to
# be extended by hand after every new WEO release.
#
# To add a new release:
#
#  1. Open https://data.imf.org/en/datasets/IMF.RES:WEO and locate the
#     "<Month> <Year> WEO Entire Dataset in Excel" document. Older vintages are
#     listed at https://data.imf.org/en/Datasets/WEO/Dataset-Vintages.
#  2. Copy the link target. It has the shape
#     https://data.imf.org/-/media/iData/External-Storage/Documents/
#       <GUID>/en/WEO<Mon><Year>all.xlsx
#  3. Append a row below with `layout = "portal"` and that URL. Keep the table
#     sorted from oldest to newest: the last row is the default publication.
#  4. Confirm the workbook still has the sheets listed in
#     `weo_portal_sheets()` and that `weo_get(year = ..., release = ...)`
#     returns data.
#  5. Record the new vintage in NEWS.md and bump the package version.

#' Known WEO Releases
#'
#' Hard-coded lookup table of the WEO publications this package can download.
#'
#' Columns:
#' * `year`, `release`, `month`: identify the publication.
#' * `layout`: `"legacy"` for the tab-delimited files on www.imf.org,
#'   `"portal"` for the multi-sheet workbooks on data.imf.org.
#' * `url`: workbook URL for `"portal"` releases; `NA` for `"legacy"`
#'   releases, whose URLs are built by `create_weo_url()`.
#'
#' @keywords internal
#' @noRd
weo_releases <- function() {
  legacy <- tidyr::expand_grid(
    year = 2007:2025,
    release = c("Spring", "Fall")
  ) |>
    dplyr::mutate(layout = "legacy", url = NA_character_) |>
    # The Fall 2025 vintage was the first one published on data.imf.org.
    dplyr::filter(!(.data$year == 2025 & .data$release == "Fall"))

  portal <- tibble::tribble(
    ~year, ~release, ~url,
    2025L, "Fall", paste0(
      "https://data.imf.org/-/media/iData/External-Storage/Documents/",
      "5661B7CB2FCC4A56866765D4281AEF01/en/WEOOct2025all.xlsx"
    ),
    2026L, "Spring", paste0(
      "https://data.imf.org/-/media/iData/External-Storage/Documents/",
      "2F78EE59F79143A7921E5E203D3AAA80/en/WEOApr2026all.xlsx"
    )
  ) |>
    dplyr::mutate(layout = "portal")

  dplyr::bind_rows(legacy, portal) |>
    dplyr::mutate(
      year = as.integer(.data$year),
      month = dplyr::if_else(.data$release == "Spring", "April", "October")
    ) |>
    dplyr::arrange(
      .data$year,
      dplyr::if_else(.data$release == "Spring", 1L, 2L)
    ) |>
    dplyr::select("year", "release", "month", "layout", "url")
}

#' Look Up a Single Release
#'
#' @keywords internal
#' @noRd
weo_lookup_release <- function(year, release) {
  releases <- weo_releases()

  matched <- releases |>
    dplyr::filter(.data$year == !!year, .data$release == !!release)

  if (nrow(matched) == 0) {
    cli::cli_abort(c(
      "No known WEO publication for {.val {year}} {.val {release}}.",
      "i" = "See {.run imfweo::weo_list_publications()} for known releases.",
      "i" = paste(
        "Releases published after {.val {weo_latest_release()$year}}",
        "{.val {weo_latest_release()$release}} require a package update."
      )
    ))
  }

  as.list(matched)
}

#' Latest Known Release
#'
#' @keywords internal
#' @noRd
weo_latest_release <- function() {
  releases <- weo_releases()
  as.list(releases[nrow(releases), ])
}
