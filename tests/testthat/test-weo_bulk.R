test_that("weo_bulk downloads and processes data correctly", {
  # Test standard download
  data <- weo_bulk(2024, "Spring", quiet = TRUE)

  # Test structure
  expect_s3_class(data, "tbl_df")
  expect_named(data, c("country", "iso", "subject", "units", "series", "year", "value"))

  # Test content
  expect_true(all(!is.na(data$iso)))
  expect_true(all(!is.na(data$series)))
  expect_true(all(is.numeric(data$year)))
  expect_true(all(is.numeric(data$value)))

  # Test if we get data for reasonable number of countries
  expect_gt(length(unique(data$iso)), 100)

  # Test if we get reasonable number of series
  expect_gt(length(unique(data$series)), 10)
})

test_that("weo_bulk handles invalid inputs correctly", {
  # Test error for invalid year (too early)
  expect_error(
    weo_bulk(1950, "Spring"),
    regexp = "Failed to download WEO data"
  )

  # Test error for invalid release
  expect_error(
    weo_bulk(2024, "Winter"),
    regexp = "should be one of"
  )
})

test_that("weo_bulk handles file paths correctly", {
  # Test with custom file path
  temp_file <- tempfile(fileext = ".xls")
  data <- weo_bulk(2024, "Spring", file_path = temp_file, quiet = TRUE)

  expect_true(file.exists(temp_file))
  expect_s3_class(data, "tbl_df")

  # Clean up
  unlink(temp_file)
})

test_that("weo_bulk downloads and processes data correctly", {
  # Test standard download
  data <- weo_bulk(2024, "Spring", quiet = TRUE)

  # Test structure
  expect_s3_class(data, "tbl_df")
  expect_named(data, c("country", "iso", "subject", "units", "series", "year", "value"))

  # Test content
  expect_true(all(!is.na(data$iso)))
  expect_true(all(!is.na(data$series)))
  expect_true(all(is.numeric(data$year)))
  expect_true(all(is.numeric(data$value)))

  # Test if we get data for reasonable number of countries
  expect_gt(length(unique(data$iso)), 100)

  # Test if we get reasonable number of series
  expect_gt(length(unique(data$series)), 10)

  # Test specific countries and series exist
  expect_true("USA" %in% unique(data$iso))
  expect_true("NGDP_RPCH" %in% unique(data$series))
})

test_that("weo_bulk handles invalid inputs correctly", {
  # Test error for invalid year (too early)
  expect_error(
    weo_bulk(1950, "Spring"),
    "Failed to download WEO data"  # This should now match exactly
  )

  # Test error for invalid release
  expect_error(
    weo_bulk(2024, "Winter"),
    "should be one of"
  )
})

test_that("weo_bulk handles file paths correctly", {
  # Test with custom file path
  temp_file <- tempfile(fileext = ".xls")
  on.exit(unlink(temp_file))

  data <- weo_bulk(2024, "Spring", file_path = temp_file, quiet = TRUE)

  expect_true(file.exists(temp_file))
  expect_s3_class(data, "tbl_df")
})
