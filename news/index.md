# Changelog

## imfweo 0.2.0

CRAN release: 2026-08-24

### Breaking changes

- Removed `weo_get_latest_publication()`. With the move of the WEO
  database to the IMF Data portal, each vintage sits behind an opaque
  per-vintage identifier, so the latest publication can no longer be
  detected from the IMF website. The known releases are now kept in a
  lookup table inside the package, whose newest entry is the default
  publication for
  [`weo_get()`](https://teal-insights.github.io/r-imfweo/reference/weo_get.md),
  [`weo_get_entities()`](https://teal-insights.github.io/r-imfweo/reference/weo_get_entities.md)
  and
  [`weo_get_series()`](https://teal-insights.github.io/r-imfweo/reference/weo_get_series.md).
  New releases become available after a package update — see the
  maintainer note at the top of `R/weo_releases.R` for how to add one.
- Removed the `check_latest` argument of
  [`weo_list_publications()`](https://teal-insights.github.io/r-imfweo/reference/weo_list_publications.md),
  which relied on the online check. The function now returns the known
  releases from the lookup table and no longer depends on the current
  date. Its `end_year` now defaults to the year of the most recent known
  publication.

### New features

- Added support for the 2025 Fall and 2026 Spring publications, which
  are distributed as a single multi-sheet Excel workbook on the IMF Data
  portal instead of the two tab-delimited files used up to 2025 Spring.
  Country group codes of these releases are mapped back to their
  pre-portal codes (e.g. `G001` to `001`) using the crosswalk shipped in
  the workbook, so that entity IDs stay comparable across publications.

### Bug fixes

- Fixed the download of the 2021 to 2023 publications. The IMF retired
  the `.ashx` URLs these vintages were served under; the same files are
  still available as `.xls`.
- A download that answers with an error page under an HTTP 200 status is
  now reported as a failed download instead of being parsed as data.
- Add support for all publications until 2025 Spring in
  [`weo_get()`](https://teal-insights.github.io/r-imfweo/reference/weo_get.md).

## imfweo 0.1.0

CRAN release: 2025-08-22

- Initial CRAN submission with
  [`weo_get()`](https://teal-insights.github.io/r-imfweo/reference/weo_get.md),
  [`weo_get_series()`](https://teal-insights.github.io/r-imfweo/reference/weo_get_series.md),
  `weo_entities()`, `weo_latest_publication()`,
  [`weo_list_publications()`](https://teal-insights.github.io/r-imfweo/reference/weo_list_publications.md)
