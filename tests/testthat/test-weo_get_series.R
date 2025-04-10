test_that("weo_get_series returns expected structure and content", {
  # Create mock data that weo_bulk would return
  mock_data <- tibble::tibble(
    series = c(
      "NGDP_RPCH",
      "NGDP_RPCH",
      "PCPIPCH",
      "PCPIPCH",
      "GGXWDG",
      "GGXWDG"
    ),
    subject = c(
      "Gross domestic product, constant prices",
      "Gross domestic product, constant prices",
      "Inflation, average consumer prices",
      "Inflation, average consumer prices",
      "General government gross debt",
      "General government gross debt"
    ),
    units = c(
      "Percent change",
      "Percent change",
      "Percent change",
      "Percent change",
      "Percent of GDP",
      "Percent of GDP"
    ),
    country = c("USA", "DEU", "USA", "DEU", "USA", "DEU"),
    iso = c("US", "DE", "US", "DE", "US", "DE"),
    year = c(2022, 2022, 2022, 2022, 2022, 2022),
    value = c(2.1, 1.8, 8.0, 7.9, 121.3, 68.3)
  )

  # Expected output after transformation
  expected_output <- tibble::tibble(
    series_id = c("GGXWDG", "NGDP_RPCH", "PCPIPCH"),
    series_name = c(
      "General government gross debt",
      "Gross domestic product, constant prices",
      "Inflation, average consumer prices"
    ),
    units = c("Percent of GDP", "Percent change", "Percent change")
  )

  # Test with default parameters (using latest publication)
  with_mocked_bindings(
    resolve_publication = function(year, release) {
      list(year = 2023, release = "Fall")
    },
    weo_bulk = function(year, release, quiet) {
      expect_equal(year, 2023)
      expect_equal(release, "Fall")
      expect_true(quiet)
      mock_data
    },
    {
      # Call the function
      result <- weo_get_series()

      # Check structure
      expect_s3_class(result, "tbl_df")
      expect_named(result, c("series_id", "series_name", "units"))

      # Check content
      expect_equal(result, expected_output)
    }
  )
})

test_that("weo_get_series handles custom year and release parameters", {
  # Create mock data
  mock_data <- tibble::tibble(
    series = c("NGDP", "PCPI"),
    subject = c(
      "Gross domestic product, current prices",
      "Inflation index"
    ),
    units = c("Billions USD", "Index"),
    country = c("USA", "USA"),
    iso = c("US", "US"),
    year = c(2022, 2022),
    value = c(25035.2, 123.4)
  )

  # Expected output
  expected_output <- tibble::tibble(
    series_id = c("NGDP", "PCPI"),
    series_name = c(
      "Gross domestic product, current prices",
      "Inflation index"
    ),
    units = c("Billions USD", "Index")
  )

  # Test with custom parameters
  with_mocked_bindings(
    resolve_publication = function(year, release) {
      expect_equal(year, 2022)
      expect_equal(release, "Spring")
      list(year = 2022, release = "Spring")
    },
    weo_bulk = function(year, release, quiet) {
      expect_equal(year, 2022)
      expect_equal(release, "Spring")
      expect_false(quiet)
      mock_data
    },
    {
      # Call the function with custom parameters
      result <- weo_get_series(
        year = 2022,
        release = "Spring",
        quiet = FALSE
      )

      # Check output
      expect_equal(result, expected_output)
    }
  )
})

test_that("weo_get_series handles empty dataset gracefully", {
  # Create empty mock data
  empty_data <- tibble::tibble(
    series = character(0),
    subject = character(0),
    units = character(0),
    country = character(0),
    iso = character(0),
    year = integer(0),
    value = numeric(0)
  )

  # Expected empty output
  expected_empty <- tibble::tibble(
    series_id = character(0),
    series_name = character(0),
    units = character(0)
  )

  # Test with empty data
  with_mocked_bindings(
    resolve_publication = function(year, release) {
      list(year = 2023, release = "Fall")
    },
    weo_bulk = function(year, release, quiet) {
      empty_data
    },
    {
      # Call the function
      result <- weo_get_series()

      # Check structure is maintained even when empty
      expect_s3_class(result, "tbl_df")
      expect_named(result, c("series_id", "series_name", "units"))
      expect_equal(nrow(result), 0)
      expect_equal(result, expected_empty)
    }
  )
})

test_that("weo_get_series correctly transforms and sorts output", {
  # Create mock data with duplicates and unsorted values
  mock_data <- tibble::tibble(
    series = c("ZCPI", "NGDP", "ZCPI", "APGR"),
    subject = c(
      "Consumer price index",
      "Gross domestic product",
      "Consumer price index",
      "Population growth"
    ),
    units = c(
      "Index",
      "Billions USD",
      "Index",
      "Percent change"
    ),
    country = c("USA", "USA", "DEU", "USA"),
    iso = c("US", "US", "DE", "US"),
    year = c(2022, 2022, 2022, 2022),
    value = c(123.4, 25035.2, 115.2, 0.4)
  )

  # Expected output should be distinct and sorted by series_id
  expected_output <- tibble::tibble(
    series_id = c("APGR", "NGDP", "ZCPI"),
    series_name = c(
      "Population growth",
      "Gross domestic product",
      "Consumer price index"
    ),
    units = c("Percent change", "Billions USD", "Index")
  )

  # Test transformation and sorting
  with_mocked_bindings(
    resolve_publication = function(year, release) {
      list(year = 2023, release = "Fall")
    },
    weo_bulk = function(year, release, quiet) {
      mock_data
    },
    {
      # Call the function
      result <- weo_get_series()

      # Check sorting and deduplication
      expect_equal(result, expected_output)
      expect_equal(result$series_id, sort(unique(mock_data$series)))
    }
  )
})
