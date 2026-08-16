test_that("weo_get filters correctly with mocked bindings", {
  fake_publication <- list(year = 2024, release = "Spring")

  fake_bulk_data <- data.frame(
    id = c("USA", "GBR", "DEU", "USA"),
    name = c("United States", "United Kingdom", "Germany", "United States"),
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

# Multi-series, multi-entity fixture so that "filtered" is distinguishable
# from "unfiltered". A single-series fixture cannot catch a filter that
# silently returns everything.
multi_series_bulk_data <- data.frame(
  id = c("USA", "USA", "GBR", "GBR", "DEU", "DEU"),
  name = c(
    "United States", "United States",
    "United Kingdom", "United Kingdom",
    "Germany", "Germany"
  ),
  series = c(
    "NGDP_RPCH", "PCPIPCH",
    "NGDP_RPCH", "PCPIPCH",
    "NGDP_RPCH", "PCPIPCH"
  ),
  subject = c(
    "Real GDP Growth", "Inflation",
    "Real GDP Growth", "Inflation",
    "Real GDP Growth", "Inflation"
  ),
  units = "Percent",
  year = 2015,
  value = c(2.5, 1.2, 1.8, 2.1, 1.6, 1.9),
  stringsAsFactors = FALSE
)

test_that("weo_get filters to a single series and excludes others", {
  fake_publication <- list(year = 2024, release = "Spring")

  with_mocked_bindings(
    resolve_publication = function(year, release) fake_publication,
    weo_bulk = function(year, release, quiet) multi_series_bulk_data,
    {
      result <- weo_get(series = "NGDP_RPCH")

      expect_equal(unique(result$series_id), "NGDP_RPCH")
      expect_false("PCPIPCH" %in% result$series_id)
      # 3 entities, one NGDP_RPCH row each
      expect_equal(nrow(result), 3)
    }
  )
})

test_that("weo_get filters to a subset of multiple series", {
  fake_publication <- list(year = 2024, release = "Spring")
  multi <- rbind(
    multi_series_bulk_data,
    data.frame(
      id = "USA", name = "United States", series = "LUR",
      subject = "Unemployment", units = "Percent", year = 2015,
      value = 5.0, stringsAsFactors = FALSE
    )
  )

  with_mocked_bindings(
    resolve_publication = function(year, release) fake_publication,
    weo_bulk = function(year, release, quiet) multi,
    {
      result <- weo_get(series = c("NGDP_RPCH", "PCPIPCH"))

      expect_setequal(unique(result$series_id), c("NGDP_RPCH", "PCPIPCH"))
      expect_false("LUR" %in% result$series_id)
    }
  )
})

test_that("weo_get returns all series when series is NULL", {
  fake_publication <- list(year = 2024, release = "Spring")

  with_mocked_bindings(
    resolve_publication = function(year, release) fake_publication,
    weo_bulk = function(year, release, quiet) multi_series_bulk_data,
    {
      result <- weo_get(series = NULL)

      expect_setequal(unique(result$series_id), c("NGDP_RPCH", "PCPIPCH"))
      expect_equal(nrow(result), nrow(multi_series_bulk_data))
    }
  )
})

test_that("weo_get filters to a single entity and excludes others", {
  fake_publication <- list(year = 2024, release = "Spring")

  with_mocked_bindings(
    resolve_publication = function(year, release) fake_publication,
    weo_bulk = function(year, release, quiet) multi_series_bulk_data,
    {
      result <- weo_get(entities = "USA")

      expect_equal(unique(result$entity_id), "USA")
      expect_false(any(c("GBR", "DEU") %in% result$entity_id))
    }
  )
})

test_that("weo_get defaults end_year to current year + 5", {
  fake_year <- 2024
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  expected_end <- current_year + 5

  fake_publication <- list(year = fake_year, release = "Spring")

  fake_bulk_data <- data.frame(
    id = "USA",
    name = "United States",
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

test_that("weo_get handles empty response", {
  with_mocked_bindings(
    resolve_publication = function(...) NULL,
    weo_bulk = function(...) NULL,
    {
      res <- weo_get()
      expect_equal(res, NULL)
    }
  )
})
