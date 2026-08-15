test_that("weo_list_publications returns the known releases", {
  result <- weo_list_publications()

  expect_s3_class(result, "data.frame")
  expect_named(result, c("year", "release", "month"))
  expect_setequal(result$release, c("Spring", "Fall"))
  expect_true(all(result$month %in% c("April", "October")))
})

test_that("weo_list_publications filters on the year range", {
  result <- weo_list_publications(start_year = 2023, end_year = 2024)

  expect_true(all(result$year >= 2023 & result$year <= 2024))
  expect_equal(nrow(result), 4)
})

test_that("weo_list_publications does not depend on the current date", {
  with_mocked_bindings(
    get_current_year = function() 1900,
    {
      expect_equal(nrow(weo_list_publications()), nrow(weo_releases()))
    }
  )
})

test_that("weo_list_publications validates the year range", {
  expect_error(
    weo_list_publications(start_year = 2024, end_year = 2023),
    "`start_year` must be smaller than `end_year`",
    fixed = TRUE
  )
})
