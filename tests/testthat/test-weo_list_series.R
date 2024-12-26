test_that("weo_list_series returns correct series information", {
  series <- weo_list_series()

  # Test structure
  expect_s3_class(series, "tbl_df")
  expect_named(series, c("series_code", "series_name", "units"))

  # Test content
  expect_true(nrow(series) > 0)
  expect_true(all(!is.na(series$series_code)))
  expect_true(all(!is.na(series$series_name)))

  # Test specific series exist
  core_series <- c("NGDP_RPCH", "PCPIPCH", "BCA")
  expect_true(all(core_series %in% series$series_code))

  # Test pattern matching
  gdp_series <- weo_list_series("gdp")
  expect_true(all(grepl("gdp", tolower(gdp_series$series_name)) |
                    grepl("gdp", tolower(gdp_series$series_code))))
})
