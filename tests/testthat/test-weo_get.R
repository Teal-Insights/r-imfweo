test_that("weo_get filters correctly with mocked bindings", {
  fake_publication <- list(year = 2024, release = "Spring")

  fake_bulk_data <- data.frame(
    iso = c("USA", "GBR", "DEU", "USA"),
    country = c("United States", "United Kingdom", "Germany", "United States"),
    series = c("NGDP_RPCH", "NGDP_RPCH", "NGDP_RPCH", "NGDP_RPCH"),
    subject = c(
      "Real GDP Growth",
      "Real GDP Growth",
      "Real GDP Growth",
      "Real GDP Growth"
    ),
    units = c("Percent", "Percent", "Percent", "Percent"),
    year = c(2015, 2016, 2017, 2018),
    value = c(2.5, 1.8, 1.6, 2.9),
    stringsAsFactors = FALSE
  )

  with_mocked_bindings(
    resolve_publication = function(year, release) fake_publication,
    weo_bulk = function(year, release, quiet) fake_bulk_data,
    {
      result <- weo_get(
        entities = c("USA", "GBR"),
        series = "NGDP_RPCH",
        start_year = 2015,
        end_year = 2016
      )

      expect_s3_class(result, "data.frame")
      expect_equal(unique(result$entity_id), c("GBR", "USA"))
      expect_equal(unique(result$series_id), "NGDP_RPCH")
      expect_true(all(result$year >= 2015 & result$year <= 2016))
    }
  )
})

test_that("weo_get defaults end_year to current year + 5", {
  fake_year <- 2024
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  expected_end <- current_year + 5

  fake_publication <- list(year = fake_year, release = "Spring")

  fake_bulk_data <- data.frame(
    iso = "USA",
    country = "United States",
    series = "NGDP_RPCH",
    subject = "Real GDP Growth",
    units = "Percent",
    year = expected_end,
    value = 2.9,
    stringsAsFactors = FALSE
  )

  with_mocked_bindings(
    resolve_publication = function(year, release) fake_publication,
    weo_bulk = function(year, release, quiet) fake_bulk_data,
    {
      result <- weo_get(
        entities = "USA",
        series = "NGDP_RPCH",
        start_year = expected_end,
        end_year = NULL
      )

      expect_s3_class(result, "data.frame")
      expect_equal(nrow(result), 1)
      expect_equal(result$year, expected_end)
    }
  )
})
