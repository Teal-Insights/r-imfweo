test_that("weo_list_releases returns correct release information", {
  releases <- weo_list_releases()

  # Test structure
  expect_s3_class(releases, "tbl_df")
  expect_named(releases, c("year", "release", "month"))

  # Test content
  expect_true(all(releases$year >= 2007))
  expect_true(all(releases$release %in% c("Spring", "Fall")))
  expect_true(all(releases$month %in% c("April", "October")))

  # Test ordering
  expect_true(all(diff(releases$year) >= 0))

  # Test data validity
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  expect_true(all(releases$year <= current_year))
})
