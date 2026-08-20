test_that("weo_releases is a well-formed lookup table", {
  releases <- weo_releases()

  expect_named(releases, c("year", "release", "month", "layout", "url"))
  expect_type(releases$year, "integer")
  expect_setequal(releases$layout, c("legacy", "portal"))
  expect_equal(anyDuplicated(paste(releases$year, releases$release)), 0L)
})

test_that("weo_releases is sorted from oldest to newest", {
  releases <- weo_releases()

  order_key <- releases$year * 2 + ifelse(releases$release == "Spring", 0L, 1L)
  expect_false(is.unsorted(order_key, strictly = TRUE))
})

test_that("legacy releases have no URL and portal releases do", {
  releases <- weo_releases()

  expect_true(all(is.na(releases$url[releases$layout == "legacy"])))
  expect_true(all(
    grepl("^https://data\\.imf\\.org/", releases$url[
      releases$layout == "portal"
    ])
  ))
})

test_that("the portal layout starts with the Fall 2025 release", {
  releases <- weo_releases()
  portal <- releases[releases$layout == "portal", ]

  expect_equal(min(portal$year), 2025L)
  expect_equal(portal$release[portal$year == 2025L], "Fall")
  expect_true(all(
    releases$layout[releases$year <= 2024L] == "legacy"
  ))
})

test_that("weo_latest_release returns the last row of the table", {
  releases <- weo_releases()
  latest <- weo_latest_release()

  expect_equal(latest$year, releases$year[nrow(releases)])
  expect_equal(latest$release, releases$release[nrow(releases)])
})

test_that("weo_lookup_release finds a known release", {
  result <- weo_lookup_release(2024, "Spring")

  expect_equal(result$year, 2024L)
  expect_equal(result$release, "Spring")
  expect_equal(result$layout, "legacy")
})

test_that("weo_lookup_release errors for an unknown release", {
  expect_error(
    weo_lookup_release(1999, "Spring"),
    "No known WEO publication"
  )
  expect_error(
    weo_lookup_release(2025, "Summer"),
    "No known WEO publication"
  )
})
