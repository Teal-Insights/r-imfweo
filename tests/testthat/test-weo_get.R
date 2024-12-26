
test_that("weo_get retrieves specific data correctly", {
  data <- weo_get(
    series = "NGDP_RPCH",
    countries = "USA",
    start_year = 2020
  )

  # Test structure
  expect_s3_class(data, "tbl_df")
  expect_named(data, c("country_name", "country_code", "series_name",
                       "units", "series_code", "year", "value"))

  # Test filtering
  expect_equal(unique(data$series_code), "NGDP_RPCH")
  expect_equal(unique(data$country_code), "USA")
  expect_true(all(data$year >= 2020))
})

test_that("weo_get handles multiple series and countries", {
  data <- weo_get(
    series = c("NGDP_RPCH", "PCPIPCH"),
    countries = c("USA", "GBR", "DEU"),
    start_year = 2020
  )

  # Test filtering
  expect_equal(
    sort(unique(data$series_code)),
    sort(c("NGDP_RPCH", "PCPIPCH"))
  )
  expect_equal(
    sort(unique(data$country_code)),
    sort(c("USA", "GBR", "DEU"))
  )
  expect_true(all(data$year >= 2020))

  # Test completeness
  expected_rows <- length(2020:2029) * 2 * 3  # years * series * countries
  expect_true(nrow(data) >= expected_rows)
})
